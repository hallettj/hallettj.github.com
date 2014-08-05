---
layout: post
title: "Javascript generators and functional reactive programming"
date: 2014-08-02
comments: true
---

tl;dr: ECMAScript 6 introduces a language feature called [generators][], which
are really great for working with asynchronous code that uses promises.  But
they do not work well for [functional reactive programming][].

ES6 generators allow asynchronous code to be written in a way that looks
synchronous.  This example uses a hypothetical library called Do (implementation
below) that makes [promises][] work with generators:

{% highlight js %}
var postWithAuthor = Do(function*(id) {
    var post   = yield getJSON('/posts/'+id)
    var author = yield getJSON('/users/'+post.authorId)
    return _.assign(post, { author: author })
})

Do(function*() {
    var post = yield postWithAuthor(3)
    console.log('Post written by', post.author.name)
})()
{% endhighlight %}

It is possible to use generators now in Node.js version 0.11 by using the
`--harmony` flag.  Or you can use [Traceur][] to transpile ES6 code with
generators into code that can be run in any ES5-compatible web browser.

<!-- more -->

I recently saw an informative talk from [Jacob Rothstein][] on [Co][] and
[Koa][].  Those are libraries that make full use of generators to make writing
asynchronous code pleasant.  The implementation of the above example in Co is
almost identical.

Co operates on promises and thunks, allowing them to be expanded with
the `yield` keyword.  It has nice options for pulling nested
asynchronous values out of arrays and objects, running asynchronous
operations in parallel, and so forth.  One can even use `try` / `catch`
to catch errors thrown in asynchronous code!

Co is specialized for asynchronous code.  But when I look at it I see something
that is really close to being a monad comprehension - very much like the [do
notation][] feature in Haskell.  With just a little tweaking, the use of
generators that Co has pioneered can almost be generalized to work with any
kind of monad.

For example, libraries like [RxJs][] and [Bacon.js][] implement event streams,
which are a lot like promises, except that callbacks on event streams can run
more than once.  This example uses Bacon to manage a typeahead search feature in
a web interface:

{% highlight js %}
var searchQueries = Do(function*(searchInput) {
    var inputs = $(searchInput).asEventStream('keyup change')
    var singleInputEvent = yield inputs
    var query = singleInputEvent.target.value
    if (query.length > 2) {
        // passes the query through
        return Bacon.once(query)
    }
    else {
        // excludes this query from the searchQueries stream
        return Bacon.never()
    }
})

var resultView = Do(function*(searchInput, resultsElement) {
    var query = yield searchQueries(searchInput)
    var results = yield Bacon.fromPromise(getJSON('/search/'+ query))
    $(resultsElement).empty().append(
        results.map(function(r) { return $('<li>').text(r) }
    )
})

resultView('#search', '#results')
{% endhighlight %}

The idea is that when the user enters more than two characters of text into
a search box, a background request is dispatched and search results appear on
the page automatically.  This example requires a library that is a little more
general than Co, that is able to operate on Bacon event streams in addition to
promises and thunks.  Here is a basic implementation of that library:

{% highlight js %}
function Do(mkGen) {
    return function(/* arguments */) {
        var gen = mkGen.apply(null, arguments)
        return next();

        function next(v) {
            var res = gen.next(v)
            return handleResult(res)
        }

        function handleError(e) {
            var res = gen.throw(e)
            if (typeof res !== undefined) {
                return handleResult(res)
            }
            else {
                return e
            }

        }

        function handleResult(res) {
            return res.done ? res.value : flatMap(res.value, next, handleError)
        }
    }
}

function flatMap(m, f, e) {
    if (typeof m.then === 'function') {
        return m.then(f, e)  // handles promises
    }
    else if (typeof m.flatMap === 'function') {
        return m.flatMap(f).onError(e)  // handles Bacon event streams (or properties)
    }
    else {
        throw new TypeError("No implementation of flatMap for this type of argument.")
    }
}
{% endhighlight %}

This is the function that makes the example at the top of this post work.  It is
a simplified version of what Co does - the difference being that Do delegates to
a `flatMap` function to handle yielding.  We just need an implementation of
`flatMap` that can operate on some different monad types.  The one above works
with promises or with Bacon event streams.  An implementation that is easier to
extend would be nice; but I will leave that problem for another time.

Unfortunately, the Bacon example does not work.  Streams - unlike promises - get
many values.  That means that the code in each generator has to run many times
(once for each stream value).  But ES6 generators are not reentrant: after
resuming a generator from the point of a given `yield` expression, it is not
possible to jump back to that entry point again (assuming the generator does not
contain a loop).  With the Bacon example, after the first `keyup` or `change`
event the search result list will just stop updating.

Getting synchronous-style functional reactive programming to work well would
require stateless, reentrant generators.  ES6 generators are stateful: every
invocation of a generator changes the way that it will behave on the next
invocation:

{% highlight js %}
var gen = function*() {
    yield 1
        yield 2
        return 3
}

g = gen()  // initialize the generator

    assert(g.next().value === 1)
    assert(g.next().value === 1)
    assert(g.next().value === 3)
assert(g.next().value === undefined)
{% endhighlight %}

A stateless implementation would return a new object with a function for the
next generator entry point, instead of modifying the original generator:

{% highlight js %}
    var g  = gen()
    var g1 = g.next()
    assert(g1.value === 1)
    var g2 = g1.next()
    assert(g2.value === 2)
    var g3 = g2.next()
assert(g3.value === 3)

    // We can go back to previous entry points.
    assert(g1.next().value === 2)
assert(g.next().value === 1)
{% endhighlight %}

A stateless generator could be implemented with some simple syntactic
transforms.  The basic case:

{% highlight js %}
function*(args...) {
    preceding_statements
        var y = yield x
        following_statements
}
{% endhighlight %}

would transform to:

{% highlight js %}
function(args...) {
    preceding_statements
        return {
value: x,
           next: function(y) {
               following_statements
           }
        }
}
{% endhighlight %}

There would just need to be a few cases to handle appearances of `yield` in
a `return` statement, a `try`-`catch` block, or as its own statement.  With that
kind of stateless design, the Bacon example would work fine.  But as far as
I know, there is no plan for stateless, reentrant generators in ECMAScript.

It is possible to make functional reactive programming work with non-reentrant
generators by using loops in the generators.  This approach is not as general or
as composable.  Asynchronous pieces would have to be declared specially at the
top of the function, for example.

{% highlight js %}
var searchQueries = function(searchInput) {
    var inputs = $(searchInput).asEventStream('keyup change') 
        frp(inputs, function*(inputs_) {
                var singleInputEvent
                while (true) {
                singleInputEvent = yield inputs_
                query = singleInputEvent.target.value
                if (query.length > 2) {
                // passes the query through
                yield Bacon.once(query)
                }
                else {
                // excludes this query from the searchQueries stream
                yield Bacon.never()
                }
                }
                })
}
{% endhighlight %}

Notice that `yield` is overloaded to accept asynchronous values and to return
results - which requires some awkward logic to inspect generator values.
I do not know how to implement `resultView` as a loop, since it requires
combining two event streams: search queries and JSON responses.  I do not see
any advantage of loops in generators over asynchronous-style callbacks.  But
maybe someone more imaginative than me can come up with a more elegant solution.

[generators]: http://tobyho.com/2013/06/16/what-are-generators/
[promises]: http://sitr.us/2012/07/31/promise-pipelines-in-javascript.html
[functional reactive programming]: http://sitr.us/2013/05/22/functional-reactive-programming-in-javascript.html
[Traceur]: https://github.com/google/traceur-compiler
[Jacob Rothstein]: http://jbr.me/
[Co]: https://github.com/visionmedia/co
[Koa]: https://github.com/koajs/koa
[do notation]: http://learnyouahaskell.com/a-fistful-of-monads#do-notation
[RxJS]: http://reactive-extensions.github.io/RxJS/
[Bacon.js]: https://github.com/baconjs/bacon.js/
