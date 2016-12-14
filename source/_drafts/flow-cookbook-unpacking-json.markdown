---
layout: post
title: "Flow Cookbook: Unpacking JSON API data"
author: Jesse Hallett
date: 2016-12-13
comments: true
---

Hacker News provides [a public API][HN API].
One of the endpoints of that API accepts an ID and responds with an item:

```js
fetch(`https://hacker-news.firebaseio.com/v0/item/${id}.json`)
```

An "item" might be a story, a comment, a question, a job posting, a poll, or
a voting option in a poll.
If you don't have context for the ID,
the only way to know what you get is to fetch the data and inspect it at
runtime.
To add type safety to a call to this API,
it is necessary to describe a type that encompasses all of the possible shapes
that the returned data might take.
That is going to be a [union type][], which will look something like this:

```js
type Item =
  | { type: 'story',   /* story fields */ }
  | { type: 'ask',     /* ask fields */ }
  | { type: 'job',     /* job fields */ }
  | { type: 'poll',    /* poll fields */ }
  | { type: 'pollopt', /* pollopt fields */ }
  | { type: 'comment', /* comment fields */ }
```

There are not a huge number of fields in the API responses.
But if we list out all of the fields in every branch,
the result will be too big and dense for light reading.
So let's start by factoring out common fields into helper types.

All of the different item types have `by`, `id`, and `time` fields.
So we can put those all into one type:

```js
// Fields common to all item types
type ItemCommon = {
  by:   Username,
  id:   ID,
  time: number,
}
```

Those `Username` and `ID` types are just aliases that I defined for primitive
types:

```js
// These type aliases just help to illustrate the purpose of certain fields
type Username = string
type ID = number
type URL = string
```

I think that using aliases like these helps to provide clarity on the purpose
of each field.
If we had a field with the type `by: string` it would not be obvious whether
the value of that field is an ID that happens to be a string,
or a human-readable value.
Using the `Username` type alias makes it obvious that the field will contain
a value that might be suitable for display to users.
Otherwise the types `string` and `Username` are interchangeable.

There is more common structure in Hacker News item types:
the story, ask, job, and poll responses all represent top-level submissions,
which have several fields in common:

```js
// Fields common to top-level item types
type TopLevel = {
  descendents: number,
  score: number,
  title: string,
}
```

With those helper types in place,
we can produce a type that describes all possible items:

```js
type Item =
  | { type: 'story', kids: ID[], url: URL }                 & ItemCommon & TopLevel
  | { type: 'ask',  kids: ID[], text: string, url: URL }    & ItemCommon & TopLevel
  | { type: 'job', text: string, url: URL }                 & ItemCommon & TopLevel
  | { type: 'poll', kids: ID[], parts: ID[], text: string } & ItemCommon & TopLevel
  | { type: 'pollopt', parent: ID, score: number, text: string } & ItemCommon
  | { type: 'comment', kids: ID[], parent: ID, text: string }    & ItemCommon
```

We use [intersection types][] in each branch of the union to combine common
fields with the fields that are particular to each item type.

TODO: footnote: It would have been more concise to write
`type Item = ItemCommon & (/* union type */)`.
But due to a quirk in the current behavior of Flow, if the intersection is on
the outside of the union, then type narrowing will not work when matching on
`item.type`.

We don't have to do anything special to parse incoming data into that type.
[Flow types are duck types][] -
`Item` is just an alias for plain Javascript objects with a certain structure.
We just need to declare that API responses have the `Item` type.
That is done with with the return type of this function:

```js
function fetchItem(id: ID): Promise<Item> {
  return fetch(`https://hacker-news.firebaseio.com/v0/item/${id}.json`)
    .then(res => res.json())
}
```

You might have noticed something a little weird about the types of the `type`
fields in `Item`.
We used string literals where there should have been type expressions!
For example, we gave `'story'` as a type in the first branch of the union type.
In fact string literals *are* types.
In a type expression, the literal `'story'` is a type with exactly one possible
value: the string `'story'`.
`'story'` is a subtype of the more general type, `string`.
This is useful because it signals to Flow which branch of the union type is
applicable inside the body of a `case` or `if` statement.

Consider this function, which does not type-check:

```js
function getTitle(item: Item): string {
  // Fails because not every branch of the union type has a `title` field.
  return item.title
}
```

Flow can narrow the type of a variable in certain contexts.
A runtime comparison with a static string literal does the trick:

```js
function getTitle(item: Item): ?string {
  if (item.type === 'story') {
    // This works because this line is only reachable if `item` has the `story`
    // type, which means that it does have a `title` field.
    return item.title
  }
}
```

TODO: `formatItem`






TODO: footnote: Fun fact: do you know about how the `switch` statement has
a gotcha where if you forget to end every `case` block with either a `return`
or a `break` statement evaluation will fall through to the next case?
Flow allows fall-through, but is smart enough to catch any type errors that
might arise.


[HN API]: https://github.com/HackerNews/API
[union type]: https://flowtype.org/docs/union-intersection-types.html
[intersection types]: https://flowtype.org/docs/union-intersection-types.html
[Flow types are duck types]: TODO
