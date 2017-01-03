---
layout: post
title: "Flow Cookbook: Flow & React"
author: Jesse Hallett
date: 2017-01-03
comments: true
---

_This recipe is part of the [Flow Cookbook][] series._

[Flow Cookbook]: /2016/12/20/flow-cookbook.html

Flow and React are both Facebook projects;
so as you might imagine, they work quite well together.
React components can take type parameters to specify types for props, default
props, and state.
Type-checking works well with both [functional and class components][].

Flow type annotations provide an alternative to `propTypes` runtime checks.
The Flow way has some advantages:

- Problems are reported immediately - it is not necessary to run tests that
evaluate every component to identify `props` mismatches.
- Flow types can be more precise and concise than `propTypes`.
- Flow can also check `state` as well as `props`.
- In addition to checking that a component gets the correct `props`,
Flow checks that `props` and `states` are used correctly within the component's
`render` method,
and in other component methods.

<!-- more -->


## How it works

The form for type parameters on a component class is:

```js
class MyComponent extends React.Component<DefaultProps, Props, State> {
  state: State

  /* ... */
}
```

Where `DefaultProps`, `Props`, and `State` can be whatever object types you
want.
For any parameter that you don't want to use,
give the type `void` instead.
For example, a component that has no internal state gets `void` for its state
type parameter.

If you use `defaultProps`, the props type should include types for *all* props -
even those that have default values.
The type for default props should only provide types for props that have
default values.

Note that the state type needs to be given twice (unless it is `void`) -
once as the third type parameter, and again as the type of the `state` instance
variable.

The form for stateless, functional components is:

```js
function MyComponent(props: Props): React.Element<*> {
  /* ... */
}
```

Once again, `Props` can be any object type that you want,
and should include types for all props, even those that have default values.
Notice also the return type, `React.Element<*>`.
Flow uses a type parameter for `Element` to track internal details,
such as the class and props that produced an element.
You will probably never want to specify that parameter by hand;
so we use `*`
(Flow's [existential type][])
to leave it to Flow to infer the type of that parameter.

[Type definitions for React][react lib] are built into Flow.
It is useful to look at those definitions to see exactly what Flow expects.
A lot of what I know about using Flow came from examining that file,
and others in the same directory.


## A Hacker News client

Let's build on the code from the [Unpacking JSON API data][] recipe,
and build a simple Hacker News client.
The client will fetch lists of stories from the Hacker News API to display.
When the user selects a story,
the client will fetch and display comments.

One of the simplest components displays a story as a single line,
and accepts a callback to do something if the user selects that story.
Let's start be defining a type for the props that this component will accept.

```js
import type { Story } from 'hacker-news-example'

type StoryListItemProps = {
  story: Story,
  onSelect: () => void,
}
```

We import the `Story` type from `'hacker-news-example'`,
which is the example code from the [Unpacking JSON API data][] recipe.
That `Story` type is a ready-made type that describes everything we will want
to display in the new client.
Take a look at [the source file][Story] to see what `Story` looks like.
(The `import type` syntax is [Flow syntax][import syntax] -
it is not part of Javascript.)

The `StoryListItemProps` type lists the props that will be given to our
component.
The props are a `story`,
and a callback called `onSelect`.
The type indicates that `onSelect` must be a function that takes zero arguments,
and that returns `undefined`.
It is not necessary to require that the return type be `undefined` -
you could use `mixed` if you do not want to put any constraint on the
callback's return type.
My opinion is that using `void` is a clear indication to the caller that the
component will not do anything with a return value.

And here is the `StoryListItem` component itself:

```js
function StoryListItem(props: StoryListItemProps): React.Element<*> {
  const { by, title } = props.story
  return <p>
    <a href="#" onClick={event => selectStory(props, event)}>
      {title}
    </a> posted by {by}
  </p>
}

function selectStory(props: StoryListItemProps, event: Event) {
  event.preventDefault()
  props.onSelect()
}
```

The type annotation, `props: StoryListItemProps`,
does two things for us:
when `StoryListItem` is rendered, Flow will check that it is given the required
props of the appropriate types;
and Flow will also check uses of `props` in the component definition for
consistency with the `StoryListItemProps` definition.

In general if a component does not have internal state,
and does not use lifecycle callbacks such as `componentDidMount`,
then I prefer to use a functional component.
That means that the component cannot have methods that refer to `this.props`;
so I made the `selectStory` event handler a top-level function that accepts
a reference to the component's props as an argument.
Reusing the `StoryListItemProps` type in the signatures for the component and
for the event handler means that we can easily keep track of available props in
both functions.

`selectStory` also takes an `event` argument.
The `Event` type is built into Flow,
and Flow knows about the `preventDefault` method.
Flow's take on the `Event` type is defined in Flow's
[DOM type definitions file][].

To populate instances of the `StoryListItem` component,
we will need to make API requests and update some state.
Here is a type for that state,
and the parameters for the top-level component, which will manage that state:

```js
type AppState = {
  selectedStory?: ?Story,
  stories?: Story[],
  error?: Error,
}

class App extends Component<void,void,AppState> {
  // Must declare `state` type in two places
  state: AppState

  constructor(props: void) {
    super(props)
    this.state = {}
  }

  /* ... */
}
```

The definition of `AppState` shows that the state will hold an array of `stories`,
which will not be defined while stories are loading;
a `selectedStory`,
which will be defined when the user is viewing comments on a story;
and an `error`,
in case something goes wrong while loading stories.

Because every property in `AppState` is optional,
`state` can be initialized as an empty object.
(The question mark at the end of a property name indicates that property might
not be set.)
`selectedStory` is optional, and its type is nullable,
so there are two question marks on that line.
That is because `selectedStory` is initially not defined,
and after a user views a story and then backs out to the story list
`selectedStory` is set to `null`.

Note that `App` does not take any props.
We can see that because it's second type parameter is `void`.
Everything is handled by internal state.
Note also that since this component has a `constructor`,
we specify the props type both in a class type parameter,
and again in the type of the `props` argument to `constructor`.

`App` will fetch stories when it is mounted.
So we extend its definition with a `componentDidMount` callback.

```js
import { fetchTopStories } from 'hacker-news-example'

class App extends Component<void,void,AppState> {
  /* ... same as before */

  componentDidMount() {
    fetchTopStories(15 /* number of stories to fetch */)
      .then(stories => {
        // On success, update component state with an array of stories
        this.setState({ stories })
      })
      .catch(error => {
        // On error, update state to capture the error for display
        this.setState({ error })
      })
  }

  /* ... */
}
```

`fetchTopStories` takes an argument that specifies the number of stories to
fetch,
and it returns a promise.

Once stories are loaded, we can display them via a `render` method.
But the component will display before those requests are complete -
so we will have to check whether stories have loaded,
and display a loading indicator if they are not ready.

```js
class App extends Component<void,void,AppState> {
  /* ... */

  render() {
    const { error, selectedStory, stories } = this.state

    let content
    if (error) {
      // an error occurred fetching stories
      content = <p className="error">{error.message}</p>
    }
    else if (selectedStory) {
      // the user is looking at comments on a story
      content = <StoryView
        story={selectedStory}
        onNavigateBack={() => this.deselectStory()}
      />
    }
    else if (stories) {
      // stories are loaded, so display a line item for each story
      content = stories.map(story => (
        <StoryListItem
          story={story}
          onSelect={() => this.selectStory(story)}
          key={story.id}
        />
      ))
    }
    else {
      // no error and no stories means that stories are still loading
      content = <p className="loading">loading...</p>
    }

    return (
      <div className="App">
        <div className="App-header">
          <h1>Flow Cookbook: React Example</h1>
        </div>
        <div>
          {content}
        </div>
      </div>
  }

  /* ... */
}
```

The import piece of the JSX that is finally returned from `render` is `content`,
which is assigned a different value depending on whether an error occurred
while fetching stories,
a specific story has been selected,
or there is an array of stories available, and none has been selected.
If none of those cases applies,
then it means that stories are still loading.
When displaying a list of stories, `content` is populated by a list of
instances of `StoryListItem`,
which we defined earlier.

Flow can track changes to the type of a variable over a series of statements.
Flow infers that when `content` is first defined its type is `void`,
and that no matter which code path gets executed,
the type changes to either `React.Element<*>` or `React.Element<*>[]` by the
time we get to the `return` statement.

The event handling methods `selectStory` and `deselectStory` just make simple
state updates:

```js
class App extends Component<void,void,AppState> {
  /* ... */

  selectStory(story: Story) {
    this.setState({ selectedStory: story })
  }

  deselectStory() {
    this.setState({ selectedStory: null })
  }
}
```

At this point
we have made references to `App`'s state in `componentDidMount`, `render`,
`selectStory`, and `deselectStory`.
Flow checks all of those uses against the definition of `AppState`.
For example, if we made a mistaken assumption that `selectedStory` holds an ID,
as opposed to a value of type `Story`,
and tried to write something like `this.setState({ selectedStory: story.id })`,
Flow would report an error, and point out the mismatch.

I have not given the implementation of `StoryView`,
which is responsible for displaying comments on a story.
It happens that `StoryView` is quite similar to `App` -
except that `StoryView` loads comments where `App` loads stories.
The interested reader can see the full details of `StoryView` in the
[accompanying code][StoryView].

Complete working code is available at
[https://github.com/hallettj/flow-cookbook-react](https://github.com/hallettj/flow-cookbook-react).
Your next assignment is to clone that code and to add some features.
Some ideas to try are to add links to original stories,
or to display profile pages for posters and commenters.

The example code here uses React's own state features to manage app state.
That helps to keep this recipe self-contained.
But in my opinion the best practice is to combine React with a state-management
framework, such as [react-redux][].
For details on using Flow with react-redux,
take a look at the next recipe, [Flow & Redux][].


[functional and class components]: https://facebook.github.io/react/docs/components-and-props.html#functional-and-class-components
[Unpacking JSON API data]: /2016/12/20/flow-cookbook-unpacking-json.html
[react lib]: https://github.com/facebook/flow/blob/master/lib/react.js
[existential type]: /2015/05/31/advanced-features-in-flow.html#existential-types
[Story]: https://github.com/hallettj/hacker-news-example/blob/master/index.js.flow#L9
[import syntax]: https://flowtype.org/docs/syntax.html#importing-and-exporting-types
[DOM type definitions file]: https://github.com/facebook/flow/blob/master/lib/dom.js#L182
[StoryView]: https://github.com/hallettj/flow-cookbook-react/blob/master/src/StoryView.js
[react-redux]: http://redux.js.org/docs/basics/UsageWithReact.html
[Flow & Redux]: /todo.html
