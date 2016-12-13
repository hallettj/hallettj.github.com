---
layout: post
title: "Flow Cookbook: Uses for union types"
author: Jesse Hallett
date: 2016-12-12
comments: true
---

A lot of languages do not have [union types][].
But Javascript is not like a lot of languages.
Flow's mission is to describe Javascript in its natural, fluid form.
Union types are an important tool toward that end.

TODO: footnote linking to [What are types?][]

A union type is a combination of two or more underlying types,
such that a value that is a member of any of the underlying types is also
a member of the union type.

For example, the string method `match` accepts a pattern to match against that
may be either a regular expression, or a string.
So the type of that argument is `string | RegExp'`.
Here is the type definition that Flow uses for `match`:

```js
match(pattern: string | RegExp): ?Array<string>
```

## Nullable types

A very common use of union types is the nullable type.
In Flow if a variable is given a type like `number` then the value must not be
`null` or `undefined`.
If the variable might be `null`, then its type must be prefixed with
a question mark - e.g. `?number`.
The question mark prefix is actually a shorthand for a union type that combines
the underlying type with the types for the `null` and `undefined` values.
So `?number` is equivalent to `number | null | void`.
(`void` is the type for the value `undefined`.)

TODO: footnote:
For a closer look at `null` and `undefined` see [The unit types][].


## Heterogeneous data


## Messages over a serialized channel


## Custom data structures

```js
type Tree<T> =
  | { type: "Node", value: T, left: Tree<T>, right: Tree<T> }
  | { type: "EmptyTree" }
```


```js
function find<T>(predicate: (value: T) => boolean, tree: Tree<T>): ?T {
  if (tree.type === "Node") {
    const fromLeftSubtree = find(predicate, tree.left)

    if (typeof fromLeftSubtree !== 'undefined') {
      return fromLeftSubtree
    }
    else if (predicate(tree.value)) {
      return tree.value
    }
    else {
      return find(predicate, tree.right)
    }
  }

  else if (tree.type === "EmptyTree") {
    // We would get an error here if we tried to reference `t.value`, `t.left`,
    // or `t.right`, because the "EmptyTree" shape does not have those things.
    return undefined
  }
}
```

[union types]: https://flowtype.org/docs/union-intersection-types.html
[What are types?]: TODO
