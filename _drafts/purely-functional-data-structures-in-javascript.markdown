---
layout: post
title: "Purely functional data structures in JavaScript"
---

I have a long-standing desire for a JavaScript library that with good
implementations of some functional data structures.  Recently I found
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
node, which points to the next list node.  (Eventually you get to the end
of the list where there is a node that points to the empty list.)
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
JavaScript code instead of JVM bytecode.  The team behind ClojureScript
has ported Clojure collections to ClojureScript implementations - which
are therefore within reach of JavaScript code.

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
are the data structures provided in the latest version of Mori, v0.2.4:

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
inaccuracy or two.  Since most of the stuff provided by Mori comes from
Clojure, if you cannot find information that you need in the Mori docs
you can also look at the Clojure docs.  I provided links to the Clojure
documentation for each data structure where more detailed descriptions
are available.


## Hashes and equality

`mori.hash(obj)`, see what happens



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

        cal.upcoming = function(start, n) {
            var futureAppts = return mori.filter(function(a) {
                return a.date >= start;
            }, appts);
            return mori.take(n, futureAppts);
        };

        return cal;
    }

    // Returns a number that is:
    // * positive, if a is larger
    // *     zero, if a and b are equal
    // * negative, if b is larger
    function compare_appts(a, b) {
        if (a.date !== b.date) {
            return a.date - b.date;
        }
        else {
            return (a.title) .localeCompare (b.title);
        }
    }

Like the underlying set, this calendar implementation is immutable.
When an appointment is added you get a new calendar value.

The comparison function for comparing appointments sorts appointments by
date, and uses title as a secondary sort in case there are appointments
with the same date and time.  The sorted set uses this function to
determine equality as well as ordering; so if it made comparisons using
only the date field then the calendar would not accept multiple
appointments with the same date and time.

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

    var now = new Date();
    var next_appts = my_cal.upcoming(now, 2);
    mori.map(function(a) { return a.title; }, next_appts);
    // ("Synesthesia Bike Tour" "Code 'n' Splode Monthly Meeting")

Looks good!  Now let's add an undo feature.  In case the user changes
her mind about the last appointment that was added, the undo feature
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

    var next_appts_ = my_prev_cal.upcoming(now, 2);
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

TODO: footnote on evidence of binary implementation


## Laziness

Many of the functions provided by Mori return what is called a lazy
sequence.  Being a sequence this is like a list and can be transformed
using functions like `map`, `filter`, and `reduce`.  What makes a
sequence lazy is that it is not actually computed right away.
Evaluation is deferred until some non-lazy function accesses one or more
elements of the transformed sequence.  At that point Mori computes and
memoizes transformations.

    // Sets, maps, vectors, and lists are actually not lazy.  But ranges
    // are.
    var s = mori.sorted_set_by(function(a, b) {
        console.log('comparing', a, b);
        return a - b;
    }, 5, 4, 3, 2, 1);

    // Outputs about n * ln_2(n) lines:
    // > comparing 4 5
    // > comparing 3 5
    // > comparing 3 4
    // > comparing 2 4
    // > comparing 2 3
    // > comparing 1 4
    // > comparing 1 3
    // > comparing 1 2

    // `map` returns a lazy sequence of transformed values.
    var seq = mori.map(function(e) {
        console.log('processed:', e);
        return 0 - e;
    }, s);

    // No output yet.

    // Getting the string representation of a collection or applying a
    // non-lazy function like `reduce` forces evaluation.
    console.log(seq);

    // Outputs:
    // > processed: 1
    // > processed: 2
    // > processed: 3
    // > processed: 4
    // > processed: 5
    // > (-1 -2 -3 -4 -5)

The results of a lazy evaluation are cached.  If the same sequence is
forced again the map function will not be called a second time:

    console.log(seq);

    // Outputs:
    // > (-1 -2 -3 -4 -5)

Mori runs just enough deferred computation to get whatever result is
needed.  It is often not necessary to compute an entire lazy sequence:

    var seq_ = mori.map(function(e) {
        console.log('processed:', e);
        return e * 2;
    }, s);

    // `take` returns a lazy sequence of the first n members of a
    // collection.
    var seq__ = mori.take(2, seq_);

    console.log(seq__);

    // Outputs:
    // > processed: 1
    // > processed: 2
    // > (2 4)

In the above case there is an intermediate lazy sequence that
theoretically contains five values, the results of doubling values in
the original set.  But only the first two values in that sequence are
needed.  The other three are never computed.

Laziness means that it is possible to create infinite sequences without
needing unlimited memory or time:

    // With no arguments, `range` returns a lazy sequence of all whole
    // numbers from zero up.
    var non_neg_ints = mori.range();

    // Dropping the first element, zero, results in a sequence of all of
    // the natural numbers.
    var nats = mori.drop(1, non_neg_ints);

    // Let's take just the powers of 2.
    var log_2    = function(n) { return Math.log(n) / Math.LN2; };
    var is_pow_2 = function(n) { return log_2(n) % 1 === 0; };
    var pows_2   = mori.filter(is_pow_2, nats);

    // What are the first 10 powers of 2?
    console.log(
        mori.take(10, pows_2)
    );

    // Outputs:
    // > (1 2 4 8 16 32 64 128 256 512)

    // What is the 20th power of 2?
    console.log(
        mori.nth(pows_2, 20)
    );

    // Outputs:
    // > 1048576

If you try this out in a REPL be aware that when an expression is
entered a JavaScript REPL will usually try to print the value of that
expression, which has the effect of forcing evaluation of lazy
sequences.  If you enter a lazy sequence you will end up in an infinite
loop:

    non_neg_ints = mori.range();

    // Loops for a long time, then runs out of memory.

The solution to this is to be careful to assign infinite sequences in
`var` statements.  That prevents the REPL from trying to print the
sequence:

    var non_neg_ints = mori.range();

    // Prints 'undefined', all is well.

TODO: change example to Fibonacci sequence

A lazy sequence might also contain lines from a large file or chunks of
data flowing into a network server.  At the time of this writing I was
not able to write a program that traversed a long sequence in constant
space.  But I have verified that this is possible in JavaScript.  I hope
to find a solution and to post an update later.


### Efficiency

In procedural code running a sequence through multiple operations that
apply to every element would result in multiple iterations of the entire
sequence.  Because Mori operates lazily it can potentially collect
transformations for each element and apply them in a single pass:

    var seq_1 = mori.map(function(e) {
        console.log('first pass:', e);
        return e;
    }, s);
    var seq_2 = mori.map(function(e) {
        console.log('second pass:', e);
        return e;
    }, seq_1);

    console.log(
        mori.take(2, seq_2);
    );

    // Outputs:
    // > first pass: 1
    // > second pass: 1
    // > first pass: 2
    // > second pass: 2
    // > (1 2)

If applying `map` to a collection twice resulted in two iterations we
would expect to see:

    // > first pass: 1
    // > first pass: 2
    // > second pass: 1
    // > second pass: 2

The fact that the first pass and second pass are interleaved suggests
that Mori collects transformations and applies all transformations to
a value at once.  This is the advantage of lazy evaluation: it
encourages writing code in a way that makes most logical sense rather
than thinking about performance.  You can write what are logically many
iterations over a collection and the library will rearrange computations
to minimize the actual work that is done.

### Apples to apples

The transformations that are available in Mori - `map`, `filter`, etc. - return
lazy sequences no matter what the type of the input collection is.  This
is advantageous because the other collection implementations are not
lazy.  But what if you want to do something like create a new set based
on an existing set?  The answer is that you feed a lazy sequence into
a new empty collection using the appropriate constructor or the `into`
function:

    var s_1 = mori.set([5, 4, 3, 2, 1]);
    var seq = mori.map(function(e) { return Math.pow(e, 2); }, s_1);

    var s_2 = mori.set(seq);
    console.log(s_2);

    // Outputs:
    // > #{25 16 9 4 1}

    var empty_s = mori.sorted_set_by(function(a, b) { return a - b; });
    var s_3     = mori.into(empty_s, seq);
    console.log(s_3);

    // Outputs:
    // > #{1 4 9 16 25}

Applying `map` to the first set is lazy, but building the second set
with `into` is not.  So a good practice is to avoid building non-lazy
collection until the last possible moment.

### Don't hold onto your head

If you try to use the infinite sequence above to compute a large power
of 2 you will see that your JavaScript process runs out of memory and
crashes.  The program computes all of the sequence elements up to
the number that you want and holds them in memory.  But it is possible
to use an infinite sequence to compute a large value using constant
memory: what you have to do is to avoid keeping a reference to the
beginning of the sequence so that elements that have already been
traversed can be garbage-collected while later elements are being
computed.

    function get_nats() {
        return mori.drop(1, mori.range());
    }

    function get_pows_2() {
        return mori.filter(is_pow_2, get_nats());
    }

    function zip_with_index(seq) {
        return mori.map(function(e, idx) {
            return mori.vector(e, idx);
        }, seq, mori.range());
    }

    // function headless_nth(seq, n) {
    //     var i = n;
    //     //seq = zip_with_index(seq);
    //     while (i > 0) {
    //         seq = mori.rest(seq);
    //     }
    //     return mori.first(seq);
    // }

    function headless_nth_async(seq, n, fn) {
        if (n === 0) {
            fn(mori.first(seq));
        }
        else {
            setTimeout(
                headless_nth_async.bind(null, mori.rest(seq), n - 1, fn),
                0
            );
        }
    }

    headless_nth_async(get_pows_2, 100, function(result) {
        console.log(result);
    }
