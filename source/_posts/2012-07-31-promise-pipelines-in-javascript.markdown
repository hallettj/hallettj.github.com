---
layout: post
title: "Promise Pipelines in JavaScript"
---

<aside class="translations">This page has been translated into <a
href="http://www.webhostinghub.com/support/es/misc/las-bases-de">Spanish</a>
language by Maria Ramos  from <a
href="http://www.webhostinghub.com/">Webhostinghub.com</a>.</aside>

Promises, also know as deferreds or futures, are a wonderful abstraction
for manipulating asynchronous actions.  Dojo has had [Deferreds][Dojo Deferreds]
for some time.  jQuery introduced [its own Deferreds][jQuery Deferreds]
in version 1.5 based on the CommonJS [Promises/A][] specification.  I'm
going to show you some recipes for working with jQuery Deferreds.  Use
these techniques to turn callback-based spaghetti code into elegant
declarative code.

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

{% highlight js %}
function fooPromise() {
    var deferred = $.Deferred();

    setTimeout(function() {
        deferred.resolve("foo");
    }, 1000);

    return deferred.promise();
}
{% endhighlight %}

Callbacks can be added to a deferred or a promise using the `.then()`
method.  The first callback is called on success, the second on failure:

{% highlight js %}
fooPromise().then(
    function(value) {
        // prints "foo" after 1 second
        console.log(value);
    },
    function() { console.log("something went wrong"); }
);
{% endhighlight %}

For more information see the
[jQuery Deferred documentation][jQuery Deferreds].

Note that if you are using a version of jQuery prior to 1.8 you will
have to use `.pipe()` instead of `.then()`.  That goes for all
references to `.then()` in this article.


## Sequential operations

Actions, such as HTTP requests, need to be sequential if input to one
action depends on the output of another; or if you just want to make
sure that actions are performed in a particular order.

Consider a scenario where you have a post id and you want to display
information about the author of that post.  Your web services don't
support embedding author information in a post resource.  So you will
have to download data on the post, get the author id, and then make
another request to get data for the author.  To start with you will want
functions for downloading a post and a user:

{% highlight js %}
function getPost(id) {
    return $.getJSON('/posts/'+ id).then(function(data, status, xhr) {
        return data;
    });
}

function getUser(id) {
    return $.getJSON('/users/'+ id).then(function(data, status, xhr) {
        return data;
    });
}
{% endhighlight %}

In jQuery 1.5 and later all ajax methods return a promise that, on
a successful request, resolves with the data in the response, the
response status, and the XHR object representing the request.

The `.then()` method produces a new promise that transforms the resolved
value of its input.  I used `.then()` here just because using `$.when()`
is simpler if each promise resolves to a single value.  We will get back
to that in parallel operations.  Since only one argument is provided to
`.then()` in these cases the new promises will have the same error
values as the originals if an error occurs.

The result is that `getUser()` returns a promise that should resolve to
data representing the user profile for a given id.  And `getPost()`
works the same way for posts and post ids.

Now, to fetch that author information:

{% highlight js %}
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
{% endhighlight %}

When `authorForPost()` is called it returns a new promise that resolves
with author information after both the post and author requests complete
successfully.  This is a straightforward way to get the job done.
Though it does not implement error handling; and it could be more
[DRY][].  More on that in a bit.

[DRY]: https://en.wikipedia.org/wiki/Don't_repeat_yourself


## Parallel operations

Let's say that you want to fetch two user profiles to display
side-by-side.  Using the `getUser()` function from the previous section:

{% highlight js %}
function getTwoUsers(idA, idB) {
    var userPromiseA = getUser(idA),
        userPromiseB = getUser(idB);

    return $.when(userPromiseA, userPromiseB);
}
{% endhighlight %}

The requests for userA and userB's profiles will be made in parallel so
that you can get the results back as quickly as possible.  This function
uses `$.when()` to synchronize the promises for each profile so that
`getTwoUsers()` returns one promise that resolves with the data for both
profiles when both responses come back.  If either request fails, the
promise that `getTwoUsers()` returns will fail with information about
the first failed request.

You might use `getTwoUsers()` like this:

{% highlight js %}
getTwoUsers(1002, 1008).then(function(userA, userB) {
    $(render(userA)).appendTo('#users');
    $(render(userB)).appendTo('#users');
});
{% endhighlight %}

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

{% highlight js %}
function getPosts(ids) {
    var postPromises = ids.map(getPost);

    return $.when.apply($, postPromises).then(function(/* posts... */) {
        return $.makeArray(arguments);
    });
}
{% endhighlight %}

This code fetches any number of posts in parallel.  I used `apply` to
pass the post promises to `$.when()` as though they are each a separate
argument.  The resulting promise resolves with a separate value for each
post.  It would be nicer if it resolved with an array of posts as one
value.  The use of `.then()` here takes those post values and transforms
them into an array.


## Combining sequential and parallel operations

Let's take the previous examples to their logical conclusion by creating
a function that, given two post ids, will download information about the
authors of each post to display them side-by-side.  No problem!

{% highlight js %}
function getAuthorsForTwoPosts(idA, idB) {
    return $.when(authorForPost(idA), authorForPost(idB));
}
{% endhighlight %}

From the perspective of a function that calls `authorForPost()`, it does
not matter that two sequential requests are made.  Because
`authorForPost()` returns a promise that represents the eventual result
of both requests, that detail is encapsulated.


## Generalizing sequential operations

There are a couple of problems with the implementation of
`authorForPost()` as presented above.  We had to create a deferred by
hand, which should not be necessary.  And the promise that is returned
does not fail if any of the requests involved fail.

These issues are not present in the parallel examples because `$.when()`
does a nice job of generalizing synchronizing multiple promises.  What
we need is a function that does a similar job of generalizing flattening
nested promises.  Meet flatMap:

{% highlight js %}
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
{% endhighlight %}

This function takes a promise and a callback that returns another
promise.  When the first promise resolves, `$.flatMap()` invokes the
callback with the resolved values as arguments, which produces a new
promise.  When that new promise resolves, the promise that `$.flatMap()`
returns also resolves with the same values.  On top of that,
`$.flatMap()` forwards errors to the promise that it returns.  If either
the input promise or the promise returned by the callback fails then the
promise that `$.flatMap()` returns will fail with the same values.

Using `$.flatMap()` it is possible to write a function like
`authorForPost()` a bit more succinctly:

{% highlight js %}
function authorForPost(id) {
    return $.flatMap(getPost(id), function(post) {
        return getUser(post.authorId);
    });
}
{% endhighlight %}

By using `$.flatMap()` you also get error handling for free.  If the
request to fetch a post fails or the request to fetch the post's author
fails the promise that this version of `authorForPost()` returns will
also fail with the appropriate failure values.

Another potential problem is that `authorForPost()` does not give you
access to any of the information on the posts that it downloads.  You
can combine `$.flatMap()` and `.then()` to create a slightly different
function that exposes both the post and the author:

{% highlight js %}
function postWithAuthor(id) {
    return $.flatMap(getPost(id), function(post) {
        return getUser(post.authorId).then(function(author) {
            return $.extend(post, { author: author });
        });
    });
}
{% endhighlight %}

The promise that `postWithAuthor()` returns resolves to a post object
with an added author property containing author information.

It turns out that `.then()` leads a double life.  If the return value of
its callback is a promise, `.then()` behaves exactly like `$.flatMap()`!
This is the sort of thing that only a dynamic language like JavaScript
can do.  So if you want to skip the custom function, you could write
`postWithAuthor()` like this:

{% highlight js %}
function postWithAuthor(id) {
    return getPost(id).then(function(post) {
        return getUser(post.authorId).then(function(author) {
            return $.extend(post, { author: author });
        });
    });
}
{% endhighlight %}


## Other uses for promises

The examples above focus on HTTP requests.  But promises can be used in
any kind of asynchronous code.  They even come in handy in synchronous
code from time to time.

Here is an example of a promise used to represent the outcome of
a series of user interactions:

{% highlight js %}
function getRegistrationDetails() {
    var detailsPromise = openModal($.get('/registrations'));

    detailsPromise.then(function(details) {
        $.post('/registrations', details);
    });
}

function openModal(markupPromise) {
    var deferred = $.Deferred(),
        modal = $('<div></div>').addClass('modalWindow'),
        loadingSpinner = $('<span></span>').addClass('spinner');

    modal.append(loadingSpinner);

    // Use .always() to add a callback to a promise that runs on success
    // or failure.
    markupPromise.always(function() {
        loadingSpinner.remove();
    });

    markupPromise.then(function(markup) {
        modal.html(markup);
    });

    modal.one('submit', 'form', function(event) {
        event.preventDefault();
        var data = $(this).serialize();
        modal.remove();
        deferred.resolve(data);
    });

    modal.appendTo('body');

    return deferred.promise();
}

$(document).ready(function() {
    $('#registerButton').click(function(event) {
        event.preventDefault();
        getRegistrationDetails();
    });
});
{% endhighlight %}

I suggest considering using promises anywhere you would otherwise pass
a callback as an argument.


## Conclusion

The promise transformations `.then()`, `$.when()`, and `$.flatMap()`
work together to build promise pipelines.  Using these functions you can
define arbitrary parallel and sequential operations with nice
declarative code.  Furthermore, small promise pipelines can be
encapsulated in helper functions which can be composed to form longer
pipelines.  This promotes reusability and maintainability in your code.

Use `.then()` to transform  individual promises.

Use `$.when()` to synchronize parallel operations.

Use `$.flatMap()` or `.then()` to create chains of sequential
operations.

Mix and match as desired.

I would like to thank [Ryan Munro][] for coming up with the "pipeline" analogy.

[Ryan Munro]: https://github.com/munro

*Update 2012-08-01:* `.pipe()` was added in jQuery 1.6.  And it turns
out that it behaves like `$.flatMap()` when its callback returns
a promise.  In jQuery 1.8 `.then()` will be updated to behave exactly
like `.pipe()`, and `.pipe()` will be deprecated.  So there is actually
no need to add a custom method - you can just use `.pipe()` or `.then()`
instead of `$.flatMap()`.

*Update 2013-01-30:* jQuery 1.8 has been released, so I replaced
references to `.pipe()` with `.then()`.  I also included a more
prominent explanation that `.then()` can do the same thing that
`$.flatMap()` does.

## Promises and Category theory

Good news!  If you are able to follow the examples in this post then you
have a working understanding of Monads.  Specifically, `$.flatMap()` is
a [monad][] transformation, `.then()` with one argument is a [functor][]
transformation, and `$.when()` is almost a [monoid][] transformation.

Monads, monoids, and functors are concepts from [category theory][] that
can be applied to functional programming.  Really they are just
generalizations of this idea of creating pipelines to transform values.

[monad]: http://en.wikipedia.org/wiki/Monad_(functional_programming)
[functor]: http://en.wikipedia.org/wiki/Functor
[monoid]: http://en.wikipedia.org/wiki/Monoid
[category theory]: http://en.wikipedia.org/wiki/Category_theory

I bring this up because category theory can be useful, but is difficult
to explain.  My hope is that seeing examples of category theory in
action will help programmers to get a feel for the patterns involved.

For more information on category theory in programming I recommend
a series of blog posts titled [Monads are Elephants][].  If you have
read that and want to go further, I found the the book [Learn You
a Haskell for Great Good!][LYAH] to be very informative.  And as a bonus
it teaches you Haskell.

[Monads are Elephants]: http://james-iry.blogspot.com/2007/09/monads-are-elephants-part-1.html
[LYAH]: http://learnyouahaskell.com/

Those who are already into category theory will note that `$.flatMap()`
could also be defined in terms of `.then()` and a `$.join()` function:

{% highlight js %}
$.flatMap = function(promise, f) {
    return $.join(promise.then(f));
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
{% endhighlight %}

Except that this won't actually work because `.then()` will join the
inner and outer promises before the result is passed to `$.join()`.
