---
layout: post
title: Flow Cookbook
author: Jesse Hallett
date: 2016-12-10
comments: true
---

Type-checking can be a useful asset in a Javascript project.
A type checker can catch problems that are introduced when adding features or
refactoring, which can reduce the amount of time spent debugging and testing.
Type annotations provide a form of always-up-to-date documentation that makes
it easier for developers to understand an unfamiliar code base.
But it is important to use type-checking effectively to get its full benefit.

The Javascript community is fortunate to have a choice of two great type
checkers.
These posts focus on [Flow][], and introduce patterns for using Flow effectively.

[Flow]: https://flowtype.org/

<!-- more -->

## Recipes

These are primers on practical patterns for Flow.
I recommend using these patterns in any project that uses Flow.

[Flow types are duck types][]

[Uses for union types][] introduces a pattern for managing data that comes in
different shapes.
Union types are helpful for describing Redux actions,
for unpacking incoming JSON data,
and for passing messages over a channel.
If you have been tempted to use subclasses,
take a look at union types to see if they might be a better fit. 

[Redux][] -
Flow and Redux could have been made for each other.
This recipe demonstrates several patterns that are useful for building Redux
action creators and reducers.

[React][] -
This post demonstrates how to use Flow effectively when creating React
components.
Including type parameters in [functional and class components][] provides an
alternative to `propTypes` that can provide better safety and modularity.
This is a companion to the post on [Redux][].

[functional and class components]: https://facebook.github.io/react/docs/components-and-props.html#functional-and-class-components


[Overloaded functions][]

[Publishing types with your library][]

[Types for third-party libraries with flow-typed][]


## Extras

Extras are not about practical patterns.
In these posts we explore ideas just because they are interesting.
Read these if you want to dig deeper into type theory,
or to learn about Flow's lesser-known capabilities.

[What are types?][]
The short answer is, types are sets of possible values.
This post gets into what that means,
and shows that Flow takes more of a purist approach to types compared to most
object-oriented languages.

[The "algebra" in "algebraic data types"][] -
In the recipe [Uses for union types][] I mentioned that union types are also
called "sum types" or "algebraic data types".
This post gives a brief background on type algebra so that you can understand
where those terms come from.

[Advanced algebraic data types][] -
Union types are great, but not perfect.
This post introduces an alternative formulation for sum types that allows Flow
to check for missing pattern matches.
It also shows that GADTs are _almost_ possible in Flow.
