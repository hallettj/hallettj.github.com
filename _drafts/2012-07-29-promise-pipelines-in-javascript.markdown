---
layout: post
title: "Promise Pipelines in JavaScript"
---

Promises, also know as deferreds or futures, are a wonderful abstraction
for manipulating asynchronous actions.  Dojo has had [Deferreds][Dojo Deferreds]
for some time.  jQuery introduced [its own Deferreds][jQuery Deferreds]
in version 1.5 based on the CommonJS [Promises/A][] specification.  I'm
going to show you some recipes for working with jQuery Deferreds.

[Dojo Deferreds]: http://dojotoolkit.org/reference-guide/1.7/dojo/Deferred.html
[jQuery Deferreds]: http://api.jquery.com/category/deferred-object/
[Promises/A]: http://wiki.commonjs.org/wiki/Promises/A


## The basics of jQuery Deferreds

A Deferred is an object that represents some future outcome.  Eventually
it will either resolve with one or more values if that outcome was
successful; or it will fail with one or more values if the outcome was
not successful.  You can get at those resolved or failed values by
adding callbacks to the Deferred.

In jQuery's terms a promise is a read-only view of a deferred.

Here is a simple example of creating and then resolving a promise:

    function fooPromise() {
        var deferred = $.Deferred();

        setTimeout(function() {
            deferred.resolve("foo");
        }, 1000);

        return deferred.promise();
    }

Callbacks can be added to a deferred or a promise using the `then()`
method.  The first callback is called on success, the second on failure:

    fooPromise().then(
        function(value) { console.log(value); },  // prints "foo" after 1 second
        function() { console.log("something went wrong"); }
    );

For more information see the
[jQuery Deferred documentation][jQuery Deferreds].


## Sequential operations

Actions, such as HTTP requests, need to be sequential if input to one
action depends on the output of another; or if you just want to make
sure that actions are performed in a particular order.

Consider a scenario where you have a post id and you want to display
information about the author of that post.  Your web services don't
support embedding author information in a post resource; so you will
have to download data on the post, get the author id, and then make
another request to get data for the author.  To start with you will want
functions for downloading a post and a user:

    function getPost(id) {
        return $.getJSON('/posts/'+ id).pipe(function(data, status, xhr) {
            return data;
        });
    }

    function getUser(id) {
        return $.getJSON('/users/'+ id).pipe(function(data, status, xhr) {
            return data;
        });
    }

In jQuery 1.5 and later all ajax methods return a promise that, on
a successful request, resolves with the data in the response, the
response status, and the XHR object representing the request.

The `pipe()` method produces a new promise that transforms the resolved
value of its input.  I used `pipe()` here just because using `$.when()`
is simpler if each promise resolves to a single value.  We will get back
to that in parallel operations.  Since only one argument is provided to
`pipe()` in these cases the new promises will have the same error values
as the originals if an error occurs.

The result is that `getUser()` returns a promise that should resolve to
data representing the user profile for a given id.  And `getPost()`
works the same way for posts and post ids.

Now, to fetch that author information:

    function authorForPost(id) {
        var postPromise = getPost(id),
            deferred = $.Deferred();

        postPromise.then(function(post) {
            var authorPromise = getUser(post.authorId);

            authorPromise.then(function(author) {
                deferred.resolve(author);
            });
        });

        return deferred.promise();
    }

This is a good straightforward way to get the job done.  Though it does
not implement error handling.  We'll get into that in a couple of
sections.


## Parallel operations

Let's say that you want to fetch two user profiles to display
side-by-side.  Using the `getUser()` function from the previous section:

    function getTwoUsers(idA, idB) {
        var userPromiseA = getUser(idA),
            userPromiseB = getUser(idB);

        return $.when(userPromiseA, userPromiseB);
    }

The requests for userA and userB's profiles will be made in parallel so
that you can get the results back as quickly as possible.  This function
uses `$.when()` to synchronize the promises for each profile so that
`getTwoUsers()` returns one promise that resolves with the data for both
profiles when both responses come back.  If either request fails, the
promise that `getTwoUsers()` returns will fail with information about
the first failed request.

You might use `getTwoUsers()` like this:

    getTwoUsers(1002, 1008).then(function(userA, userB) {
        $(render(userA)).appendTo('#users');
        $(render(userB)).appendTo('#users');
    });

The `getTwoUsers()` promise resolves with two values, one for each
profile.

We now have several well-defined functions that operate on asynchronous
actions.  Isn't this nicer than the big mess of nested callbacks one
might otherwise see?

I mentioned above that using `$.when()` is simpler when each of its
input promises resolves to a single value.  That is because if an input
promise resolves to multiple values then the corresponding value in the
new promise that `$.when()` creates will be an array instead of a single
value.

Performing an arbitrary number of actions in parallel is similar:

    function getPosts(ids) {
        var postPromises = ids.map(getPost);

        return $.when.apply($, postPromises).pipe(function(/* posts... */) {
            return $.makeArray(arguments);
        });
    }

This code fetches any number of posts in parallel.  I used `apply` to
pass the post promises to `$.when()` as though they are each a separate
argument.  The resulting promise resolves with a separate value for each
post.  It would be nicer if it resolved with an array of posts as one
value.  The use of `pipe()` here takes those post values and transforms
them into an array.


## Combining sequential and parallel operations

Let's take the previous examples to their logical conclusion by creating
a function that, given two post ids, will download information about the
authors of each post to display them side-by-side.  No problem!

    function getAuthorsForTwoPosts(idA, idB) {
        return $.when(authorForPost(idA), authorForPost(idB));
    }


## Generalizing sequential operations

There are a couple of problems with the implementation of
`getAuthorForPost()` as presented above.  We had to create a deferred by
hand, which should not be necessary.  And the promise that it produces
does not fail if any of the requests involved fail.

These issues are not present in the parallel examples because `$.when()`
does a nice job of generalizing synchronizing multiple promises.  What
we need is a function that does a similar job of generalizing flattening
nested promises.  Meet flatMap:

    $.flatMap = function(promise, f) {
        var deferred = $.Deferred();

        function reject(/* arguments */) {
            // The reject() method puts a deferred into its failure
            // state.
            deferred.reject.apply(deferred, arguments);
        }

        promise.then(function(/* values... */) {
            var newPromise = f.apply(null, arguments);

            newPromise.then(function(/* newValues... */) {
                deferred.resolve.apply(deferred, arguments);
            }, reject);

        }, reject);

        return deferred.promise();
    };

If you include `$.flatMap()` in your project you can write
`authorForPost()` a bit more succinctly:

    function authorForPost(id) {
        return $.flatMap(getPost(id), function(post) {
            return getUser(post.authorId);
        });
    }

By using `$.flatMap()` you also get error handling for free.  If the
request to fetch a post fails or the request to fetch the post's author
fails the promise that this version of `authorForPost()` returns will
also fail with the appropriate values.

Another potential problem is that `authorForPost()` does not give you
access to any of the information on the posts that it downloads.  You
can combine `$.flatMap()` and `pipe()` to create a slightly different
function that exposes both the post and the author:

    function postWithAuthor(id) {
        return $.flatMap(getPost(id), function(post) {
            return getUser(post.authorId).pipe(function(author) {
                return $.extend(post, { author: author });
            });
        });
    }

The promise that `postWithAuthor()` returns resolves to a post object
with an added author property containing author information.


## Other uses for promises


## Conclusion

ops act as pipeline


## Promises and Category theory

Good news!  If you are able to follow the examples in this post then you
understand Monads.  Specifically, `$.flatMap()` is a [monad][]
transformation, `pipe()` with one argument is a [functor][]
transformation, and `$.when()` is almost a [monoid][] transformation.

Monads, monoids, and functors are concepts from [category theory][] that
can be applied to functional programming.  Really they are just
generalizations of this idea of creating pipelines to transform values.
Credit goes to [Ryan Munro][] for coming up with the "pipeline" analogy.

[monad]: http://en.wikipedia.org/wiki/Monad_(functional_programming)
[functor]: http://en.wikipedia.org/wiki/Functor
[monoid]: http://en.wikipedia.org/wiki/Monoid
[category theory]: http://en.wikipedia.org/wiki/Category_theory

[Ryan Munro]: https://github.com/munro

Those who are into category theory will note that `$.flatMap()` could
also be defined in terms of `pipe()` and a `$.join()` function:

    $.flatMap = function(promise, f) {
        return $.join(promise.pipe(f));
    };

    $.join = function(promise) {
        var deferred = $.Deferred();

        function reject(/* arguments */) {
            deferred.reject.apply(deferred, arguments);
        }

        promise.then(function(nestedPromise) {

            nestedPromise.then(function(/* values... */) {
                deferred.resolve.apply(deferred, arguments);
            }, reject);

        }, reject);

        return deferred.promise();
    };

For more information on category theory in programming I recommend
a series of blog posts titled [Monads are Elephants][]

[Monads are Elephants]: http://james-iry.blogspot.com/2007/09/monads-are-elephants-part-1.html
