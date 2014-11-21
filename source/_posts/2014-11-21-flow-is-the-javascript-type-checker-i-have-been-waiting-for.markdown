---
layout: post
title: "Flow is the JavaScript type checker I have been waiting for"
date: 2014-11-21
comments: true
---

I am very excited about [Flow][], a new JavaScript type checker from Facebook.
I have put some thought into what a type checker for JavaScript should do -
and in my opinion Facebook gets it right.
The designers of Flow took great effort to make it work well with JavaScript
idioms,
and with off-the-shelf JavaScript code.
The key features that make that possible are type inference
and [path-sensitive][] [analysis][].
I think that Flow has the potential to enable sweeping improvements to the code
quality of countless web apps and Node apps.

From the [announcement post][]:

> ...underlying the design of Flow is the assumption that most JavaScript code
> is implicitly statically typed; even though types may not appear anywhere in
> the code, they are in the developer’s mind as a way to reason about the
> correctness of the code. Flow infers those types automatically wherever
> possible, which means that it can find type errors without needing any changes
> to the code at all.

> This makes Flow fundamentally different than existing JavaScript type systems
> (such as TypeScript), which make the weaker assumption that most JavaScript
> code is dynamically typed, and that it is up to the developer to express which
> code may be amenable to static typing.

[Flow]: http://flowtype.org/
[announcement post]: https://code.facebook.com/posts/1505962329687926/flow-a-new-static-type-checker-for-javascript/
[path-sensitive]: http://flowtype.org/docs/nullable-types.html#type-annotating-null
[analysis]: http://flowtype.org/docs/dynamic-type-tests.html#_

Path-sensitive analysis means that Flow reads control flow to narrow types where
appropriate.
This example comes from the announcement post:

{% highlight js %}
function length(x) {
  return x.length;
}

var total = length('Hello') + length(null);
// Type error: x might be null
{% endhighlight %}

The presence of a use of `length` with a `null` argument informs Flow that there
should be a null check in that function.
This version does type-check:

{% highlight js %}
function length(x) {
  if (x) {
    return x.length;
  } else {
    return 0;
  }
}

var total = length('Hello') + length(null);
{% endhighlight %}

Flow is able to infer that `x` cannot be `null` inside the `if` body.

An alternate fix would be to get rid of any invocations of `length` where the
argument might be `null`.
That would cause Flow to infer a non-nullable type for `x`.

This capability goes further - here is an example from the Flow documentation:

{% highlight js %}
var o = null;
if (o == null) {
  o = 'hello';
}
print(o.length);
{% endhighlight %}

The type of `o` is initially `null`.
But Flow is able to determine that the type of `o` changes when `o` is
reassigned,
and that its type is definitely `string` on the last line.

In addition to null checks,
Flow also narrows types when it sees dynamic type checks.
This example (which passes the type checker) comes from the documentation:

{% highlight js %}
function foo(b) { if (b) { return 21; } else { return ''; } }
function bar(b) {
  var x = foo(b);
  var y = foo(b);
  if (typeof x == 'number' && typeof y == 'number') { return x + y; }
  return 0;
}
var n = bar(1) * bar(2);
{% endhighlight %}

The inferred return type of `foo` is `string | number`.
That is a type union,
meaning that values returned by `foo` might be of type `string` or of type
`number`.
The type checks in `bar` narrow the possible types of `x` and `y` in the `if`
body to just `number`.
That means that it is safe to multiply values returned by `bar` -
The type checker knows that `bar` will always return a number.

A coworker told me that what he would like is support for type-checked structs.
That would let him add or remove properties from an object in one part of
a program,
and be assured that the rest of the program is using the new object format
correctly.
Struct types work using structural types and type aliases:

{% highlight js %}
type Point = { x: number; y: number }

function mkPoint(x, y): Point {
  return { x: x, y: y }
}

var p = mkPoint('2', '3')
// Type error: string is incompatible with number

var q = mkPoint(2, 3)
q.z = 4
// Type error: property `z` not found in object type

var r: Point = { x: 5 }
// Type error: property y not found in object literal
{% endhighlight %}

Notice the `type` keyword and type annotation on `mkPoint` -
Facebook's literature is a little misleading,
in that Flow is really a new language that compiles to JavaScript.
But the only differences between Flow and regular JavaScript are the added
syntax for type aliases and type annotations,
and the type-checking step.
Flow can be applied to regular JavaScript code without type annotations.  

How well that works will depend on how that code is written.
If the JavaScript is cleanly written,
you might get a lot of help from Flow without ever needing type annotations.
But there are some valid JavaScript idioms that will not type-check
(at least not at this time.)
For example, optional arguments are not allowed unless you use either
[Flow's syntax][optional] or [ECMAScript 6's default parameter syntax][default].

[optional]: http://flowtype.org/docs/functions.html#too-few-arguments
[default]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Default_parameters

These are early days for Flow.
I am optimistic that over time it will only get better at operating on code that
was not written with Flow in mind.

There is a side benefit to using the Flow language:
it supports [ECMAScript 6][],
but [compiling Flow programs][] produces ECMAScript 5 code that can run in most
browsers.

[ECMAScript 6]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/New_in_JavaScript/ECMAScript_6_support_in_Mozilla
[compiling Flow programs]: http://flowtype.org/docs/running.html#_

One of my favorite features of Flow is that `null` and `undefined` are *not*
treated as bottom types.
A value is only allowed to be `null` if it has a nullable type.
This makes Flow better at catching null pointer exceptions than almost any other
object-oriented language.

For example:

{% highlight js %}
var n: Object = null;
// Type error: null is incompatible with object type

var m: ?Object = null;
// this is ok

var o = null;
// this is ok too - Flow infers that o has a nullable type
{% endhighlight %}

A type expression `?T` behaves pretty much like `T | null | undefined`.
(From what I can tell, `null` and `undefined` are distinct types in Flow -
but it does not seem to be possible to use them in type annotations at this
time.
`void` is allowed, which seems to be an alias for `undefined`.)

In the past I have talked to one or two people who said that they would only be
interested in type-checked JavaScript if it supported [algebraic types][].
(These are the kind of people I work with :)).
That is possible too - here is an example that I wrote:

[algebraic types]: https://en.wikipedia.org/wiki/Algebraic_data_type

{% highlight js %}
type Tree<T> = Node<T> | EmptyTree

class Node<T> {
  value: T;
  left:  Tree<T>;
  right: Tree<T>;
  constructor(value, left, right) {
    this.value = value
    this.left  = left
    this.right = right
  };
}
class EmptyTree {}

function find<T>(predicate: (v: T) => boolean, tree: Tree<T>): T | void {
  var leftResult

  if (tree instanceof Node) {
    leftResult = find(predicate, tree.left)
    if (typeof leftResult !== 'undefined') {
      return leftResult
    }
    else if (predicate(tree.value)) {
      return tree.value
    }
    else {
      return find(predicate, tree.right)
    }
  }

  else if (tree instanceof EmptyTree) {
    return undefined;
  }
}
{% endhighlight %}

Thanks to type narrowing, accessing `tree.value` passes type-checking in the
`if` body where `tree instanceof Node` is true.
Without that check, the type checker would not allow accessing properties that
do not exist on both `Node` and `EmptyTree`.

Some points to note in this example:

- The `class` syntax is from ECMAScript 6 -
  but it is extended by Flow to support type annotations for properties.
- `Tree` is a type alias.  It has no runtime representation. And unlike
  a superclass, it is _sealed_, meaning that it is not possible to add more
  subtypes to `Tree` elsewhere in the codebase.
- Flow supports parameterized types
  (a.k.a. generics, a.k.a. parametric polymorphism).
- You can specify the exact type of function values (in this case, the type of `predicate`).
- `find` might return a value from a tree, or it might return `undefined`. So
  the return type is `T | void` (where `void` is the type of `undefined`).

I have not been sold on prior JavaScript type checkers.
They did not seem to "get" JavaScript.
Flow is a type checker that I actually plan to use.
