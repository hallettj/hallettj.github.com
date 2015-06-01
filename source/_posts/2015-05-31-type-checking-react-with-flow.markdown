---
layout: post
title: "Type checking React with Flow v0.11"
date: 2015-05-31
comments: true
---

Flow v0.11 was [released][changelog] recently.
The latest set of changes really improve type checking in React apps.
But there are some guidelines to follow to get the full benefits.

[changelog]: https://github.com/facebook/flow/blob/master/Changelog.md

<!-- more -->

### Use ES6 classes

React added support in version 0.13 for implementing components as native Javascript classes
([more information on that here][classes]).
The latest version of the React type definitions take full advantage of class-based type checking features.

[classes]: https://facebook.github.io/react/blog/2015/01/27/react-v0.13.0-beta-1.html

### `React.Component` takes type parameters

When creating a component, be sure to provide type parameters in your class
declaration to describe the types of your props, default props, and state.
Here is a modified example from the React blog:

{% highlight js %}
import React from 'react'

type Props = { initialCount: number }
type DefaultProps = { initialCount: number }
type State = { count: number }

export class Counter extends React.Component<DefaultProps,Props,State> {
  constructor(props: Props, context: any) {
    super(props, context)
    this.state = {count: props.initialCount}
  }
  tick() {
    this.setState({count: this.state.count + 1})
  }
  render(): React.Element {
    return (
      <div onClick={this.tick.bind(this)}>
        Clicks: {this.state.count}
      </div>
    )
  }
}
Counter.propTypes = { initialCount: React.PropTypes.number }
Counter.defaultProps = { initialCount: 0 }
{% endhighlight %}

The parameter signature is `React.Component<DefaultProps,Props,State>`.
This is not exactly documented;
but you can see types of React features in
[Flow's type declarations for React][react-types].
All of the type declarations in that folder are automatically loaded whenever Flow runs,
unless you use the `--no-flowlib` option.

If you define a constructor for your component,
it is a good idea to annotate the `props` argument too.
Unfortunately Flow does not make the connection that the constructor argument
has the same type as `this.props`.

Note that I included type annotations on `render()` and `context`.
This is just because Flow generally requires type annotations for class method
arguments and return values.

[react-types]: https://github.com/facebook/flow/blob/master/lib/react.js

When those type parameters are given,
here are some of the things that Flow can check:

- when instantiating your component, the required props are given with correctly typed values.
- props that are not required have default values (checked only if `defaultProps` is defined)
- references to `this.props` or `this.state` are checked to make sure that the properties accessed exist, and have a compatible type
- properties set with `this.setState()` are declared in your state type and have the correct types

### Use JSX

I mentioned above that Flow will check that components are given required props.
In my testing, there were some cases where this worked when I used JSX syntax,
but did not work with the plain Javascript `React.createElement` option.
(The case I had trouble with was with a conditionally-rendered child in
a `render` method -
my uses of of `React.createElement` worked fine with both syntaxes.)
I suspect that engineers at Facebook tend to prefer JSX,
and, and maybe test code written with JSX syntax more heavily.

## General-purpose features

What is nice is that most of the features that Flow uses to support React are general-purpose.
As far as I can tell, the only feature in Flow that is React-specific is support for JSX syntax.
But some of the features that make Flow work so well are not yet documented.
For details,
see my post on [Advanced features in Flow][]

[Advanced features in Flow]: /2015/05/31/advanced-features-in-flow.html
