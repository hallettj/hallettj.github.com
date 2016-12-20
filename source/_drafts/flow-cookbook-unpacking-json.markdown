---
layout: post
title: "Flow Cookbook: Unpacking JSON API data"
author: Jesse Hallett
date: 2016-12-20
comments: true
---

_This recipe is part of the [Flow Cookbook][] series._

[Flow Cookbook]: /2016/12/20/flow-cookbook.html

Hacker News provides [a public API][HN API].
One of the endpoints of that API accepts an ID and responds with an item:

```js
fetch(`https://hacker-news.firebaseio.com/v0/item/${id}.json`)
```

An "item" might be a story, a comment, a question, a job posting, a poll, or
a voting option in a poll.
If you don't have context for the ID,
the only way to know what you have fetched is to check the `type` property of
the response at runtime.
To add type safety to a call to this API,
it is necessary to describe a type that encompasses all of the possible shapes
that the returned data might take.
That is going to be a [union type][], which will look something like this:

```js
type Item =
  | { type: 'story',   /* story properties */ }
  | { type: 'ask',     /* ask properties */ }
  | { type: 'job',     /* job properties */ }
  | { type: 'poll',    /* poll properties */ }
  | { type: 'pollopt', /* pollopt properties */ }
  | { type: 'comment', /* comment properties */ }
```

There are not a huge number of properties in the API responses -
but if we list out all of the properties in every branch the result will be too
big and dense for light reading.
So let's start by factoring out common properties into helper types.

All of the different item types have `by`, `id`, and `time` properties.
So we can put those all into one type:

```js
// Properties common to all item types
type ItemCommon = {
  by:   Username,
  id:   ID,
  time: number,
}
```

Those `Username` and `ID` types are just aliases that I defined for primitive
types:

```js
// These type aliases just help to illustrate the purpose of certain properties
type Username = string
type ID = number
type URL = string
```

I think that using aliases like these helps to provide clarity on the purpose
of each property.
If we had a property with the type `by: string` it would not be obvious whether
the value of that property is an ID that happens to be a string,
or a human-readable value.
Using the `Username` type alias makes it obvious that the property will contain
a value that might be suitable for display to users.
Otherwise the types `string` and `Username` are interchangeable.

There is more common structure in Hacker News item types:
the story, ask, job, and poll response types all represent top-level submissions,
which have several properties in common:

```js
// Properties common to top-level item types
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

An [intersection type][] like
`{ type: 'story', kids: ID[], url: URL } & ItemCommon & TopLevel`
is essentially a shorthand for an object type with a `type` property that is
always equal to `'story'`, combined with all of the properties listed in the
`ItemCommon` and `TopLevel` types.
Each branch of the union type contains a type intersection that combines common
properties with the properties that are particular to each item
type.[^top-level union]

[^top-level union]: It would have been more concise to write
`type Item = ItemCommon & (/* union type */)`.
That would put the union type inside of the intersection type.
But due to a quirk in Flow as of version 0.36 the union type must be the
outermost layer of of composition for type narrowing to work.

We don't have to do anything special to parse incoming data into that type.
[Flow types are duck types][] -
`Item` is just an alias for plain Javascript objects with a certain structure.
We just need to declare that API responses have the `Item` type.
That is done with with the return type in this function signature:

```js
function fetchItem(id: ID): Promise<Item> {
  return fetch(`https://hacker-news.firebaseio.com/v0/item/${id}.json`)
    .then(res => res.json())
}
```

You might have noticed something a little strange about the types of the `type`
properties in `Item`.
We used string literals where there should have been type expressions!
For example, we gave `'story'` as a type in the first branch of the union type.
In fact string literals *are* types.
In a type expression, the literal `'story'` is a type with exactly one possible
value: the string `'story'`.
(`'story'` is a subtype of the more general type, `string`.)
This is useful because it signals to Flow which branch of the union type is
applicable inside the body of a `case` or `if` statement.

Consider this function, which does not type-check:

```js
function getTitle(item: Item): string {
  // Fails because not every branch of the union type has a `title` property.
  return item.title
}
```

Flow can narrow the type of a variable in certain contexts.
A runtime comparison with a static string literal does the trick:

```js
function getTitle(item: Item): ?string {
  if (item.type === 'story') {
    // This works because this line is only reachable if the type of
    // `item.type` is `'story'`, which means that `item` can be expected to
    // have a `title` property.
    return item.title
  }
}
```

Hacker News does provide endpoints for fetching recent submissions of
a specific item type (e.g., the latest stories).
But to demonstrate the flexibility of the `Item` type,
let's write some code that fetches and displays the latest items of any type.
We will need to switch on the `type` property of each item to display it
properly:

```js
function formatItem(item: Item): string {
  switch (item.type) {
    case 'story':
      return `${item.title} submitted by ${item.by}`
    case 'ask':
      return `${item.by} asked: ${item.title}`
    case 'job':
      return `job posting: ${item.title}`
    case 'poll':
      return `poll: ${item.title} - choose one of ${item.kids.length} options`
    case 'pollopt':
      return `poll option: ${item.text}`
    case 'comment':
      return `${item.by} commented: ${item.text.slice(0,60)}...`
    default:
      throw new Error(`unknown item type: ${item.type}`)
  }
}
```

Flow is able to infer which item type is given in each `case` body.
This is just like how type-narrowing worked in the `if` body in the `getTitle`
function.

Flow's checking has an added bonus:
if you have a `case` body with no `return` or `break` statement,
execution falls through into the next `case` body.
When switching on `item.type`, a fall-through would result in a situation
where a `case` body might be executed with any of several different item types.
For example:

```js
function getTitleCowboyStyle(item: Item): ?string {
  switch (item.type) {
    case 'story':
    case 'ask':
    case 'job':
    case 'poll':
      return item.title
  }
}
```

Flow allows this, because all of the types listed in that example have
a `title` property.
But if a `case` body did something not compatible with all of the different
item types that could fall-through into it, then Flow would report an error.

Next up are functions to determine which items to fetch, and to make the
necessary requests:

```js
// Fetches the largest ID, which should be the ID of the most recently-created
// item.
function fetchMaxItemId(): Promise<ID> {
  return nodeFetch(`https://hacker-news.firebaseio.com/v0/maxitem.json`)
    .then(res => res.json())
}

async function fetchLatestItems(n: number): Promise<Item[]> {
  const maxId = await fetchMaxItemId()
  const fetches = []
  for (let i = 0; i < n; i++) {
    fetches.push(fetchItem(maxId - i))
  }
  return Promise.all(fetches)
}
```

And finally, some code to set everything running:

```js
(async function main() {
  const latestItems = await fetchLatestItems(15)
  latestItems.forEach(item => console.log(formatItem(item)))
}())
```

The code from this article is available at
https://github.com/hallettj/hacker-news-example.
I encourage you to check out the code to tinker with it.
Try building more functionality,
and see how type-checking affects the way you write code.

[HN API]: https://github.com/HackerNews/API
[union type]: https://flowtype.org/docs/union-intersection-types.html
[intersection type]: https://flowtype.org/docs/union-intersection-types.html
[Flow types are duck types]: TODO
