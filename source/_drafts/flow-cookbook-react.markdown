---
layout: post
title: "Flow Cookbook: React"
author: Jesse Hallett
date: 2017-01-02
comments: true
---

_This recipe is part of the [Flow Cookbook][] series._

[Flow Cookbook]: /2016/12/20/flow-cookbook.html

Flow and React are both Facebook projects -
so as you might imagine, they work quite well together.
React component classes can type type parameters to specify types for props,
default props, and state.
Type-checking also works quite well with [functional components].

Flow type annotations provide an alternative to `propTypes` runtime checks.
The Flow way has some advantages:

- Problems are reported immediately - it is not necessary to run tests that
evaluate every component to identify `props` mismatches.
- Flow types can be more precise and concise than `propTypes`.
- Flow can also check `state` as well as `props`.
- In addition to checking that a component gets the correct `props`,
Flow checks that `props` and `states` are used correctly within the component.


## The basics

The form for type parameters on a component class is:

```js
class MyComponent extends React.Component<DefaultProps, Props, State> {
  state: State

  /* ... */
}
```

Where `DefaultProps`, `Props`, and `State` can be whatever object types you
want.
If you don't want to use any of those parameters,
use the type `void` instead.

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
so we use `*`,
which is Flow's [existential type][],
to leave it to Flow to infer the type of that parameter.

[Type definitions for React][] are built into Flow.
It is useful to look at those definitions to see exactly what Flow expects.
A lot of what I know about Flow came from examining that file,
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

We import the `Story` type from [`'hacker-news-example'`][API client],
which is the example code from the [Unpacking JSON API data][] recipe.
That `Story` type is a ready-made type that describes everything we will want
to display in the new client.
(The `import type` syntax is [Flow syntax][import syntax] -
it is not part of the Javascript language.)





Complete working code is available at
[https://github.com/hallettj/flow-cookbook-react](https://github.com/hallettj/flow-cookbook-react).
Your next assignment is to clone that code and to add some features.
Some ideas to try are to add links to original stories,
or to display information about posters and commenters.

The example code here uses React's own state features to manage app state.
That helps to keep this recipe self-contained.
But in my opinion the best practice is to combine React with a state-management
framework, such as [react-redux][].
For details on using Flow with react-redux,
take a look at the [Redux recipe][].


[functional components]: https://facebook.github.io/react/docs/components-and-props.html#functional-and-class-components
[Unpacking JSON API data]: /2016/12/20/flow-cookbook-unpacking-json.html
[react lib]: https://github.com/facebook/flow/blob/master/lib/react.js
[existential type]: http://sitr.us/2015/05/31/advanced-features-in-flow.html#existential-types
[API client]: https://github.com/hallettj/hacker-news-example
[impport syntax]: TODO
[react-redux]: TODO
[Redux recipe]: http://sitr.us/todo.html
