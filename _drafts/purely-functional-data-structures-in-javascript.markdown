---
layout: post
title: "Purely functional data structures in JavaScript"
---

I have a long-standing desire for a JavaScript library that with a good
implementation of some functional data structures.  Recently I found
[Mori][], and I think that it may be just the library that I have been
looking for.  Mori packages data structures from the [Clojure][]
standard library for use in JavaScript code.

A functional data structure (also called a persistent data structure)
has two important qualities: it is immutable and it can be updated by
creating a copy with modifications.  Creating copies should be nearly as
cheap as modifying a comparable mutable data structure in place.  This
is usually achieved with structural sharing: pointers to unchanged
portions of a structure are shared between copies so that memory only
has to be allocated for the changed portions of the data structure.

A simple example is a linked list.  A linked list is an object,
specifically a list node, with a value and a pointer to the next list
node, which points to the next list node.  Eventually you get to the end
of the list where there is a node that points to the empty list.
Prepending an element to the front of such a list is a constant-time
operation: you just create a new list element with a pointer to the
start of the existing list.  When lists are immutable there is no need
to actually copy the original list.  Removing an element from the front
of a list is also a constant-time operation: you just return a pointer
to the second element of the list.

Lists are just one example.  There are functional implementations for
a number of familiar data structures.

Rich Hickey, the creator Clojure, describes functional data structures
as [decoupling state and time][values and change].  (Also available in
[video form][Are We There Yet].)  The idea is that code that uses
functional data structures is easier to reason about and to verify than
code that uses mutable data structures.

[values and change]: http://clojure.org/state
[Are We There Yet]: http://www.infoq.com/presentations/Are-We-There-Yet-Rich-Hickey

[Clojure][] is a functional language that compiles to JVM bytecode.  It
is a Lisp dialect.  In addition to the traditional Lisp data structures,
like the linked list, Clojure introduces some of its own data
structures, like PersistentVector, which supports efficient random
random-access operations.

[ClojureScript][] is an alternative Clojure compiler that produces
JavaScript code instead of JVM bytecode.  From what I understand it does
some bootstrapping so that the Clojure standard library can generally be
compiled straight to JavaScript.

[Mori]: http://swannodette.github.io/mori/
[Clojure]: http://clojure.org/
[ClojureScript]: https://github.com/clojure/clojurescript

[Mori][] incorporates the ClojureScript build tool and pulls out just
the standard library data structures.  It builds a JavaScript file that
can be used as a standalone library.  Mori adds some API customizations
to make the Clojure data structures easier to use in JavaScript - mostly
that involves conversion between JavaScript arrays and Clojure
structures.  Mori also includes a few helpers to make functional
programming easier, like identity, constant, and sum functions.  These
are the data structures provided in the latest version of Mori, v0.2.3:

- [`list`][list] (linked list)
- [`vector`][vector]
- [`array_map`][array_map]
- [`hash_map`][hash_map]
- [`sorted_map`][sorted_map]
- [`sorted_map_by`][sorted_map_by]
- [`range`][range]
- [`set`][set]
- [`sorted_set`][sorted_set]
- [`sorted_set_by`][sorted_set_by]

[list]: http://clojure.org/data_structures#toc13
[vector]: http://clojure.org/data_structures#toc15
[range]: http://clojuredocs.org/clojure_core/clojure.core/range
[hash_map]: http://clojure.org/data_structures#toc17
[sorted_map]: http://clojure.org/data_structures#toc17
[sorted_map_by]: http://clojure.org/data_structures#toc17
[array_map]: http://clojure.org/data_structures#toc21
[set]: http://clojure.org/data_structures#toc22
[sorted_set]: http://clojure.org/data_structures#toc22
[sorted_set_by]: http://clojure.org/data_structures#toc22

All of these data structures are immutable and can be efficiently
updated via copying.

The documentation for Mori is pretty good.  But it does neglect to
mention some of the available structures and methods; and there is an
innacuracy or two.  Since most of the stuff provided by Mori comes from
Clojure, if you cannot find information that you need in the Mori docs
you can also look at the Clojure docs.  I provided links to the Clojure
documentation for each data structure where more detailed descriptions
are available.


## Hashes and equality

`mori.hash(obj)`, see what happens



## Laziness

Mori data structures are lazy.
TODO: certain structures are lazy; it looks like sets are eager

    var s  = mori.sorted_set(1, 2, 3, 4, 5, 6, 7, 8, 9);
    var s_ = mori.map(function(e) {
        console.log('processed:', e);
        return e;
    }, s);

    // No output yet.

    mori.take(2, s_);  //> (1 2)

    // Outputs:
    // > processed: 1
    // > processed: 2

The results of a lazy evaluation are cached.  If we ask for the same two
values again the map function will not evaluate a second time:

    mori.take(2, s_);  //> (1 2)

    // No console output.

    mori.take(4, s_);  //> (1 2 3 4)

    // Outputs:
    // > processed: 3
    // > processed: 4

How about a structure that is mapped more than once?

    var s_1 = mori.map(function(e) {
        console.log('first pass:', e);
        return e;
    }, s);
    var s_2 = mori.map(function(e) {
        console.log('first pass:', e);
        return e;
    }, s_1);

    mori.take(2, s_2);  //> (1 2)

    // Outputs:
    // > first pass: 1
    // > second pass: 1
    // > first pass: 2
    // > second pass: 2

If applying `map` to a collection twice resulted in two iterations we
would expect to see:

    // > first pass: 1
    // > first pass: 2
    // > second pass: 1
    // > second pass: 2

The fact that the first pass and second pass are interleaved suggests
that Mori collects transformations and applies all transformations to
a value at once.


## Examples

Let's take a look at the particular advantages of some of these
structures.

### hash_map

All JavaScript objects are maps.  But those can only use strings as
keys.  The `hash_map` provided by Mori can use any values as keys.

    var mori = require('mori');

    var a = { foo: 1 };
    var b = { foo: 2 };

    var map = mori.hash_map(a, 'first', b, 'second');
    assert(mori.get(map, b) === 'second');

If you use plain JavaScript objects as keys they will be compared by
reference identity.  If you use Mori data structures as keys they will
be compared by value such that two different objects are equal if they
have equal contents.

It does look like ECMAScript 6 will add [a Map implementation][ES6 Map]
and a [WeakMap][] to the language spec, both of which will take
arbitrary objects as keys.  But those will not be immutable!

[ES6 Map]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map
[WeakMap]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap

Mori maps are immutable; so there is never a need to create defensive
copies.  An update operation produces a new map.

    var empty = mori.hash_map();
    var m1 = mori.assoc(empty, 'foo', 1);
    var m2 = mori.assoc(m1, 'bar', 2, 'nao', 3);
    var m3 = mori.dissoc(m2, 'foo');

    assert(mori.get(m2, 'foo') === 1);
    assert(mori.get(m2, 'bar') === 2);
    assert(mori.get(m3, 'foo') === null);

There is a common pattern in JavaScript of passing options objects to
constructors to avoid having functions that take zillions of arguments.
It is also common to have a set of default values for certain options.
So code like this is pretty typical:

    var opts = jQuery.extend({}, options, defaults);

I usually put in an empty object as the first argument to
`jQuery.extend` so that I get a new object instead of modifying the
given options object in place.  Modifying the options object could cause
problems if it is reused somewhere outside of my constructor.  An
alternative to the defensive copy could be to use immutable Mori maps:

    function MyFeature(options) {
        var opts = mori.into(MyFeature.defaults, mori.js_to_clj(options));

        this.getPosition = function() {
            return mori.get(opts, 'position');
        };

        this.getDestroyOnClose = function() {
            return mori.get(opts, 'destroyOnClose');
        };
    }

    MyFeature.defaults = mori.into(mori.hash_map(), mori.js_to_clj({
        destroyOnClose: true,
        position: 'below'
        // etc...
    }));

    var feat = new MyFeature({ position: 'above' });
    assert(feat.getPosition() === 'above');

The function `mori.into(coll, from)` adds all of the members of `from`
into a copy of `coll`.  Both `from` and `coll` can by any Mori
collection.

The gain from using Mori in this situation is not huge, since you end up
creating a new object with Mori or with the standard defensive copy
approach.  Mori is able to create copies faster using less memory - which
matters when working with large maps but probably won't make any
difference with options objects.  I find this idea appealing anyway.

### set

JavaScript does not have its own set implementation.  (Though it looks
like [one will be introduced][ES6 Set] in ECMAScript 6.)  Sets are
a feature that I often miss.

[ES6 Set]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set

As with maps, most objects are compared by reference identity except for
Mori data structures which are compared by value.  Primitives are also
compared by value.


### sorted_set_by

A sorted set is a heavenly blend of a sequence and a set.  Any duplicate
values that are added are ignored, and there is a specific ordering of
elements.  Unlike a list or a vector, ordering is not based on
insertion, but is determined by comparisons between elements.

One possible use for a sorted set is to implement a priority queue.
Consider an example of a calendar application.  `sorted_set_by` takes
a comparison function that is used to to maintain an ordering of added
values.  With the appropriate comparison appointments are added and are
automatically sorted by date:

    function Calendar(appts) {
        appts = appts || mori.sorted_set_by(compare_appts);
        var cal = {};

        cal.add = function(appt) {
            var with_appt = mori.conj(appts, appt);
            return Calendar(with_appt);
        };

        cal.upcoming = function(n) {
            return mori.take(n, appts);
        };

        return cal;
    }

    // Returns a number that is:
    // * positive, if a is larger
    // *     zero, if a and b are equal
    // * negative, if b is larger
    function compare_appts(a, b) {
        return a.date - b.date;
    }

Like the underlying set, this calendar implementation is immutable.
When an appointment is added you get a new calendar value.

Appointments can be added to a calendar and queried in date order:

    var my_cal = Calendar().add({
        title: "Portland JavaScript Admirers' Monthly Meeting",
        date:  Date.parse("2013-09-25T19:00-0700")
    }).add({
        title: "Code 'n' Splode Monthly Meeting",
        date:  Date.parse("2013-09-24T19:00-0700")
    }).add({
        title: "WhereCampPDX 6",
        date:  Date.parse("2013-09-28T09:00-0700")
    }).add({
        title: "Synesthesia Bike Tour",
        date:  Date.parse("2013-09-22T15:00-0700")
    });

    var next_appts = my_cal.upcoming(2);
    mori.map(function(a) { return a.title; }, next_appts);
    // ("Synesthesia Bike Tour" "Code 'n' Splode Monthly Meeting")

Looks good!  Now let's add an undo feature.  In case the user changes
her mind about the last appoinment that was added, the undo feature
should recreate the previous state without that appointment.  The
implementation of `Calendar` is the same as before except that the
constructor takes an additional optional argument, the `add` method
passes a reference from one calendar value to the next, and there is
a new `undo` method:

    function Calendar(appts, prev_cal) {
        // ...

        cal.add = function(appt) {
            var with_appt = mori.conj(appts, appt);
            return Calendar(with_appt, cal);
        };

        cal.undo = function() {
            return prev_cal || Calendar();
        };

        // ...
    }

Assuming the same set of appointments, we can use the undo method to
step back to a state before the fourth appointment was added:

    var my_prev_cal = my_cal.undo();

    var next_appts_ = my_prev_cal.upcoming(2);
    mori.map(function(a) { return a.title; }, next_appts_);
    // ("Code 'n' Splode Monthly Meeting" "Portland JavaScript Admirers' Monthly Meeting")

Immutability comes in handy in this scenario.  It is trivial to step
back in time.

Actually because `Calendar` is immutable, you don't necessarily need a special
method to get undo behavior:

    function makeCalendar() {
        var cal_0 = Calendar();
        var cal_1 = cal_0.add({
            title: "Portland JavaScript Admirers' Monthly Meeting",
            date:  Date.parse("2013-09-25T19:00-0700")
        });
        var cal_2 = cal_1.add({
            title: "Code 'n' Splode Monthly Meeting",
            date:  Date.parse("2013-09-24T19:00-0700")
        });
        var cal_3 = cal_2.add({
            title: "WhereCampPDX 6",
            date:  Date.parse("2013-09-28T09:00-0700")
        });
        var cal_4 = cal_3.add({
            title: "Synesthesia Bike Tour",
            date:  Date.parse("2013-09-22T15:00-0700")
        });

        var toReturn = cal_4;

        // No wait! Undo!!
        toReturn = cal_3;

        // That was close...
        return toReturn;
    }

Not that I have anything against the Synesthesia Bike Tour!  It's just
that when demonstrating an undo feature, something has to take one for
the team.


## List versus Vector

Linked lists become less appealing when it becomes desirable to access
elements at arbitrary positions in a sequence, to append elements to the
end of a sequence, or to update elements at arbitrary indexes.  The
running time for all of these operations on lists is linear, and the
append and update operations require creating a full copy of the list up
to the changed position.

Clojure's PersistentVector is a sequence, like a list.  But
under-the-hood it is implemented as a tree with 32-way branching.  That
means that any vector index can be looked up in O(log_32 n) time.
Appending and updating arbitrary elements also takes place in
logarithmic time.  For more details read [Understanding Clojure's
PersistentVector implementation][PersistentVector].

[PersistentVector]: http://web.archive.org/web/20130119231848/http://blog.higher-order.net/2009/02/01/understanding-clojures-persistentvector-implementation/

Sequences that are implemented as mutable arrays of contiguous memory
support constant-time lookups and modification (not including array
resizing when array length grows).  If O(log_32 n) does not seem
appealing in comparison, consider that if you are using 32-bit integers
as keys:

    var max_int = Math.pow(2, 32);
    var log_32  = function(n) { return Math.log(n) / Math.log(32); };
    assert( log_32(max_int) < 7 );

Which means that your keyspace will run out before your vector's tree
becomes more than 7 layers deep.  Up to that point operations will be
O(7) or faster.

If your keys are JavaScript numbers, which are 64-bit floating point
values, the largest integer that you can count up to without skipping
>> 2^53

The `hash_map` and `set` implementations in Mori are also implemented as
trees with 32-way branching.  I'm guessing that the sorted map and set
structures are implemented as binary trees.

