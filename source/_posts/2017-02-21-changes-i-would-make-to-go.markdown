---
layout: post
title: Changes I would make to Go
author: Jesse Hallett
date: 2017-02-20
comments: true
---

I have been programming primarily in Go for about six months.
I find it frustrating.
There are two reasons for this:

First, functional programming is particularly difficult in Go.
In fact the language [discourages functional programming][1].
This frustrates me because the imperative code that I write requires a lot of
boilerplate,
and I think it is more error-prone than it could be if I could use functional
abstractions.

[1]: https://en.wikipedia.org/wiki/Go_(programming_language)#Conventions_and_code_style

Second, I see Go as a missed opportunity.
There is exciting innovation in programming languages -
especially in areas of type checking and type inference to make code safer,
faster, and more ergonomic.
I wish Google had chosen to put their weight behind some of those ideas.

I am not the first person to look at Go this way.
Here are other posts that echo my feelings:

- [Why Go Is Not Good](http://yager.io/programming/go.html)
- [Everyday hassles in Go](http://crufter.com/@crufter/everyday-hassles-in-go)

I will add to those with some of my own opinions.
To highlight exactly how I think Go could have been better,
I want to make comparisons to Rust.

<!-- more -->

Work on Go and Rust began at close to the same time:
Go was first announced to the world in 2009,
Rust in 2010.
There is a lot of overlap in their philosophies;
both languages:

- aim for a simple core language
- compile to fast, native binaries
- eschew inheritance in favor of composition
- support imperative programming
- omit exception-catching in favor of explicitly passing error results
- emphasize concurrency
- come with static type-checking
- come with a modern packaging system that promotes modularity

Both languages may have been intended to replace C++:
[Go's designers have said][2] that a primary motivation for Go was their
dislike of the complexity of C++.
One of Mozilla's prominent applications for Rust is [Servo][], a potential
replacement for the Gecko HTML rendering engine, which is written in C++.

[2]: https://en.wikipedia.org/wiki/Go_(programming_language)#History
[Servo]: https://servo.org/

As I see it the key difference is that
Rust aims for [soundness][], and powerful abstractions;
Go aims to be accessible to people who are familiar with imperative programming.

[soundness]: http://logan.tw/posts/2014/11/12/soundness-and-completeness-of-the-type-system/

That said, Rust is not necessarily a replacement for Go,
and I do not mean to say that everyone using Go should switch to Rust.
Rust supports real-time operation,
can operate in stack-only mode if necessary,
and has a sophisticated type system that can, for example,
detect problems due to concurrent access to shared data at compile time.
Those requirements add to the complexity of Rust programs.
The [borrow-checker][] in particular has a reputation for its learning curve.

My purpose for making comparisons to Rust is to provide context for specific
ways in which I think Go could be better.
There are some good ideas in Rust that are not tied to borrow-checking,
and I think that Go could be a better language if it adopted some of those ideas.

[borrow-checker]: https://doc.rust-lang.org/book/ownership.html

You can grab the [code examples][] from this post.
The examples come with executable tests to encourage experimentation.

[code examples]: https://github.com/hallettj/comparing-go-and-rust

So, here is my view of how Go compares:


## The Good

I think that Go's use of interfaces to promote composition is great.

I like the separation of behavior and data:
structs store data, methods manipulate data in structs -
it is clean separation of state (structs), and behavior (methods).
I think that distinction can become unfortunately blurry in languages that use
inheritance.

Rust has a similar system,
where data is described by structs or enums.
Behavior is separate, in the form of trait methods and standalone functions.

Go is easy to learn.
Go repurposes object-oriented concepts to make something new in a way that
makes it approachable to programmers who are familiar with other
object-oriented languages.
This is somewhat similar to what Rust does;
but interfaces in Go match behaviors of object-oriented interfaces more closely
than Rust's traits do.

There is often a pretty clear "Go way" to solve a problem.
This is also an oft-touted virtue of, for example, Python.
Encouraging consistent idioms via the languages makes it likely that any Go
programmer will be able to understand code written by any other Go programmer.
This is not so much the case in Rust.

There are lots of Go APIs that have clearly had a lot of thought put into them.
This is one of my favorites:

```go
5 * time.Seconds
```

Goroutines are cheap,
so programs can be structured in the way that makes most sense algorithmically,
even if that involves spawning large numbers of goroutines.
(But this is not unique to Go.
Erlang and Scala also implement lightweight actors.
Rust and other languages have their own solutions for lightweight concurrent
and parallel programming.)

I could go on - there are plenty of nice features in Go.
But there are also:


## The Bad

These are features of Go that I find especially frustrating.

### `nil`

I am disappointed by the decision to include null pointers in a new language
when safer solutions have been in use for decades.
Or to be more precise: I think it is a bad idea for a language to use `nil` as
a bottom type,
where `nil` can be used in place of any pointer type.
Some newer languages have a `null`, but treat it as a distinct type
(e.g., [Fantom][], [Flow][]).
In those languages values are non-nullable by default.
Without that feature, uses of `nil` are contradictions of what is stated in
your types,
and every type comes with the implied ambiguity, "or it might be `nil`".
Checking for `nil` or `null` at compile time can prevent a lot of problems!

[Fantom]: http://fantom.org/
[Flow]: https://flowtype.org/

The problem with `nil` in Go is exacerbated by the fact that `nil` checks
sometimes fail.
If an interface value has a type but its value is `nil`,
[a `nil` check will not return `true`][3].

[3]: http://devs.cloudimmunity.com/gotchas-and-common-mistakes-in-go-golang/index.html#nil_in_nil_in_vals

Rust does not have a `null` or `nil` value.
Rust uses enums, which are types whose values come in multiple variants,
where each variant is effectively a distinct struct.
If you want to represent an absence of a value you use an enum variant that
holds no data.
The generalized form of this pattern is known as the "Option Pattern".
The definition of the `Option` type from Rust's standard library looks
approximately like this:

```rust
pub enum Option<T> {
    None,    // Holds no data
    Some(T), // Holds a value of the given type
}
```

`None` and `Some` are constructors:
essentially they are each a function that returns a value of type `Option<T>`.
`Some` takes one argument, `None` takes zero arguments.
Given an `Option<T>` value, you can use pattern matching to determine which
constructor was used to create the value;
and pattern matching is also how you read back any constructor arguments.
(In the case of a value created by calling `Some(x)`,
pattern matching lets you get access to that `x` value.)

Here is the Option pattern in action
([source](http://rustbyexample.com/std/option.html)):

```rust
fn checked_division(dividend: i32, divisor: i32) -> Option<i32> {
    if divisor == 0 {
        // Failure is represented as the `None` variant
        None
    } else {
        // Result is wrapped in a `Some` variant
        Some(dividend / divisor)
    }
}

#[test]
fn divides_a_number() {
    let result = checked_division(12, 4);
    match result {
        Some(num) => assert_eq!(3, num), // Pattern on the left binds the variable `num`
        None      => assert!(false, "Expected `Some` but got `None`")
    };
}
```

I once advocated for use of the Option pattern at a Java company -
but at least one of my coworkers was put off by the idea of allocating an extra
object on the heap just to distinguish between a value and an absence of
a value.
Rust is built with the Option pattern in mind,
and prioritizes zero-cost abstractions:
If the type parameter for `Option<T>` is a reference type,
then the `None` case can be safely represented at runtime as a null pointer.
So the `Some` or `None` wrapper often disappears at compile time.
In those cases the code is just as efficient as it would have been if the
language used unsafe `null` values.

In the example above since neither `Option<i32>` nor the `i32` parameter are
reference types, the compiler allocates contiguous space on the stack for the
numeric result, and for a tag to distinguish between `Some` and `None`.
There is no extra heap allocation, and no added pointer indirection.

The Rust Book has [a lot more detail][error handling].

[error handling]: https://doc.rust-lang.org/book/error-handling.html

It is possible to implement the Option pattern in Go with similar efficiency;
and one could even get a compile-time check that errors are handled by
implementing a `match` method that uses the visitor pattern ([example][go-option]).
But without generics there would be no type safety for values wrapped in an
`Option` type.

[go-option]: https://github.com/hallettj/comparing-go-and-rust/tree/master/go/option


### Error-handling boilerplate & lack of compile-time checks for error handling

Error handling in Go has two related problems:
there is a lot of boilerplate required;
and if the programmer neglects to check for an error,
or makes a small mistake such as checking the wrong error variable,
the compiler will not report the problem.

Rust has a type, `Result<T,E>`,
that is quite similar to `Option<T>`.
The difference is that the failure variant of the `Result<T,E>` enum is not empty -
it contains an error value (of type `E`).
A returned value of type `Result<T,E>` may be either
`Ok(value)` (on success) or
`Err(err)` (on error).

```rust
pub enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

A common complaint about the Option / Result Pattern is that unwrapping
success values is a pain.
But a language with support for pattern matching makes unwrapping painless,
and first-class result values permit combinators that can handle a series of
potential failures more cleanly and safely than explicit error checks.

Consider this Go function:

```go
func fetchAllBySameAuthor(postID string) ([]Post, error) {
	post, err := fetchPost(postID)
	if err != nil {
		return nil, err
	}

	author, err := fetchUser(post.AuthorID)
	if err != nil {
		return nil, err
	}

	return fetchPosts(author.Posts)
}
```

There are a few ways the `fetchAllBySameAuthor` function this could be
implemented in Rust.
The pattern matching approach is probably the most accessible to people who do
not have prior experience with the Option or Result Pattern:

```rust
fn fetch_all_by_same_author(post_id: &str) -> Result<Vec<Post>, io::Error> {
    let post = match fetch_post(post_id) {
        Ok(p)    => p,
        Err(err) => return Err(err),
    };

    let author = match fetch_user(&post.author_id) {
        Ok(a)    => a,
        Err(err) => return Err(err),
    };

    fetch_posts(&author.posts)
}
```

That is no less verbose than the Go version -
but it demonstrates that unwrapping `Result<T,E>` or `Option<T>` values does
not have to be any more onerous than `nil` checks;
and if we had left out a failure check in the Rust version Rust would have
emitted an error at compile time.

Rust has a macro, `try!`, that abstracts the pattern matches and early returns
that we see above.
So this is an equivalent function:

```rust
fn fetch_all_by_same_author(post_id: &str) -> Result<Vec<Post>, io::Error> {
    let post   = try!(fetch_post(post_id));
    let author = try!(fetch_user(&post.author_id));
    fetch_posts(&author.posts)
}
```

But Go does not support macros.
Thankfully, the Result pattern does not require macros to be concise.
For the more functionally-inclined,
here is another equivalent implementation that uses combinator methods:

```rust
fn fetch_all_by_same_author(post_id: &str) -> Result<Vec<Post>, io::Error> {
    let post   = fetch_post(post_id);
    let author = post.and_then(|p| fetch_user(&p.author_id));
    author.and_then(|a| fetch_posts(&a.posts))
}
```

`and_then` is a method on `Result<T,E>` values.
If the value is a successful result, it runs the given callback,
which should return a new `Result<U,E>` value.
Or if the value is an error result, `and_then` short-circuits,
and passes the error result through.
`and_then` is a lot like the `then` method on Javascript promises.

But wait - what if you want to wrap error results to add context?
There is a combinator for that to:
`map_err` permits arbitrary transformations to error results.

```rust
let post = fetch_post(post_id)
    .map_err(|e| io::Error::new(io::ErrorKind::NotFound, e));
```

The idea is that failure checks are almost always the same:
check for an error, return the error if it exists, otherwise continue.
It is more [DRY][] to abstract that into a helper method or a macro.
And again,
a common theme in all of these Rust implementations is that there is
a compile-time guarantee that every error handled.
That could be with some recovery code,
or by passing the error up the call stack.

[DRY]: http://deviq.com/don-t-repeat-yourself/

`Result<T,E>` does not get the same disappear-at-compile-time optimization that
`Option<T>` does because both enum variants hold data.
But its efficiency compares favorably with Go's multiple return values.
Go allocates enough space for every value in a multiple return.
Rust allocates enough space to hold either `T` or `E`
(i.e., enough space to hold the largest possible value),
plus a tag to distinguish between an `Ok(value)` value and an `Err(err)` value.

A nice thing about the generality of Rust enums is that if `Result<T,E>` did
not exist,
it would be easy to implement it as a library.
So what about using the Result or Option pattern in Go?
Well, we can't put methods on Go tuples (a.k.a, multiple return values),
because they are not first-class values.
We could implement a custom struct type -
but without generics it would not be very useful.


### List manipulation cannot be abstracted

There is a special slap-in-the-face for functional programmers built into Go:
A value of type `[]interface{}` cannot be easily coerced to another slice type -
e.g. `[]string` or `[]MyStructType`.
The only way to do that conversion is to create a new slice,
and copy values one-at-a-time in a `for` loop.
But any polymorphic function that acts on lists *must* operate on the
`interface{}` top type because Go does not provide type variables.

I can implement `Map` (or potentially `ParallelMap`) in Go without too much
trouble:

```go
func Map(f func(x interface{}) interface{}, xs []interface{}) []interface{} {
	ys := make([]interface{}, len(xs))
	for i, x := range xs {
		ys[i] = f(x)
	}
	return ys
}
```

But then I end up with some bad choices:

- I can precede and follow every invocation of `Map` with custom `for` loops to
fix up types;
- or instead of one polymorphic implementation I can write a custom `Map` for
every pair of types that I want to map from and to;
- or I can give up on type safety and write programs using mostly `interface{}`
values.

The same problem applies to other list manipulation functions:
`Filter`, `Take`, `Reduce`, etc.

You might have noticed a pattern here:
Go does not support generics, and that leads to problems.

Dynamic languages like Javascript, Python, and Ruby do not support generics
either -
at least not in the sense of compile-time checking.
But functional idioms work just fine in those languages.
For example,
in Javascript can pass any list to a generic list manipulation function,
and it just works.
Go occupies an awkward middle ground where it checks types at compile time,
but does not provide tools to describe what to check for.

Generics - and type variables in particular -
are a means to "talk" about types.
They let you use function signatures to make statements like,
"This function takes a slice of values of some type, and returns a slice of
values of the same type."
Working in a programming language with no type variables is as frustrating to
me as talking in a spoken language without the word "the".

So Go code must re-implement list abstractions everywhere.
Consider this Go function:

```go
// Take the titles of the first `count` docs that are not archived
func LatestTitles(docs []Document, count int) []string {
	var latest []string
	for _, doc := range docs {
		if len(latest) >= count {
			return latest
		}
		if !doc.IsArchived {
			latest = append(latest, doc.Title)
		}
	}
	return latest
}
```

That function iterates over an input collection, skips over some values, does
something with the values that are not skipped, and returns a collection with
the results.
In other words, this is a `filter`, `map`, `take` operation.
Here is an equivalent Rust implementation:

```rust
fn latest_titles(docs: &[Document], count: usize) -> Vec<&str> {
    docs.iter()
        .filter(|ref doc| !doc.is_archived)
        .map(|ref doc| doc.title.as_str())
        .take(count)
        .collect()
}
```

The Rust version lets me say what I mean.
In other words, the Rust function is "declarative".
And the difference becomes more pronounced if I want to process values
concurrently -
for example to make network requests in parallel.
More on that in a bit.

I once complained to a coworker about a lack of abstractions in Go.
My coworker replied, "Well, maybe you shouldn't be doing that."
So I want to emphasize that functional abstractions do not necessarily make
code less efficient.
Rust typically does "list" manipulation using lazily-evaluated iterators.
(This is also how the standard data structures in Clojure work.)
So you can chain `filter`, `map`, `take`, without intermediate collection
allocations,
and without wasting cycles on computing values beyond those that the caller
requests.
The function above does not run those `filter` and `map` callbacks on every
element in the input collection -
it stops processing elements as soon as it has enough results to satisfy the
`take(count)` step.
On top of that,
`iter`, `filter`, `map`, `take`, and `collect` are polymorphic methods,
but they are dispatched statically thanks to a compile-time monomorphization
step.
And the compiler will probably inline the `filter` and `map` callbacks.
There are some notes in the Rust Book on
[performance of functional abstractions on iterators][perf].

[perf]: https://rust-lang.github.io/book/ch13-04-performance.html

It is possible that my coworker was more concerned with cognitive burden
than with performance.
I think that complaints of cognitive burden may be partly a result of looking
at unfamiliar idioms.
To an experienced functional programmer,
a call to, e.g., `map` states a clear intention:
"The input collection will be transformed according to this mapping function."
With some practice declarative code is fast to read and understand.
And type checkers are more effective at checking declarative code than at
checking custom `for` loops.

Let's get into the parallel-fetch problem that I mentioned.
Here is a Go function that I wrote recently to fetch a set of documents in
parallel:

``` go
func (client docClient) FetchDocuments(ids []int64) ([]models.Document, error) {
	docs := make([]models.Document, len(ids))
	var err error

	var wg sync.WaitGroup
	wg.Add(len(ids))

	for i, id := range ids {
		go func(i int, id int64) {
			doc, e := client.FetchDocument(id)
			if e != nil {
				err = e
			} else {
				docs[i] = *doc
			}
			wg.Done()
		}(i, id)
	}

	wg.Wait()

	return docs, err
}
```

The use of a `WaitGroup`, the allocation of a new slice, copying result values,
and explicit error checks are all low-level details that I should not have to
reimplement every time I want to do things concurrently.

Now that I am looking at this again,
I realize there might be a problem here with concurrent access to the
`docs` slice.
Maybe it would be a good idea to use a mutex around updates to `docs`,
or to send results from goroutines back to the main thread via a channel.
But if I use a channel I will need to implement a custom struct or use two channels,
because I want to capture errors,
and I cannot send the type `(models.Document, error)` over a channel,
because Go tuples are not first-class values...

Rust gives a compile-time error if a mutable reference to a thread-unsafe data
structure is passed to a function that could run in another thread.
So I don't have to worry as much about what is or is not thread-safe when
writing Rust code.
But that is almost made moot by the fact that Rust can hide hairy concurrency
details in library functions.

Compare the Go code to an equivalent Rust function that uses the [futures][]
library:

[futures]: https://aturon.github.io/blog/2016/08/11/futures/

```rust
fn fetch_documents(ids: &[i64]) -> Result<Vec<Document>, io::Error> {
    let results = ids.iter()
        .map(|&id| fetch_document_future(id));
    future::join_all(results).wait()
}
```

The Rust function works the same way that the Go function does:
if all fetches are successful,
you get a collection of data from responses.
But if any fetches fail, you get the first failure as an error value.
The difference is that in the Rust version the concurrency, mapping, and
error-checking details are handled by a general-purpose library.
(Another difference is that the Rust version returns as soon as any fetch fails,
but the Go version always waits for all fetches to finish.)

This example shows that the `map` abstraction is so powerful that concurrent
versus sequential execution is an implementation detail.
(I will talk more about more about functional parallel processing in a later
section.)

The Rust implementation assumes that `fetch_document` returns a `Future`.
The function `future::join_all` also returns a `Future`.
(Futures work very similarly to promises in Javascript:
they represent an eventual result or error.)
It would be more idiomatic to return that last future directly instead of using
`wait` to block on the result.
But blocking gives us a function that is logically equivalent to the Go version,
and shows that using futures in Rust does not lock you into using
callback-driven code everywhere.

Using futures, and the related `Stream` type,
makes some kinds of network server implementations much simpler than with
blocking IO.
In particular, streaming requests and responses are easy if code is implemented
in terms of `Stream` values.


### Third-party libraries are second-class citizens

Go has a magical function called `make` that seems to do whatever the standard
library authors need for a given type.
It takes a type as an argument, which is unlike other Go functions.
For custom types `make` just returns an empty value, or `nil` for pointer types.
But in some cases `make` can take additional arguments to initialize a value.
For example, when creating a slice you can provide a capacity:

```go
mySlice := make([]int, 32)
```

Without the second argument `make` returns `nil` as usual -
but with that argument `make` has a very different behavior where it allocates
a backing array to hold the specified number of values.

When creating a channel, you can specify the channel's buffer size with
a second argument to `make`.
As far as I know, this is the only way to set a channel's buffer size.

It seems that standard libraries have a special privilege to overload `make`
to delegate to custom constructor code when initializing their types.
Third-party libraries do not get to do this.

We see something like this with the `range` operator also.
`range` is one of the few constructs that changes its behavior depending on the
number of arguments that are assigned from its output:

```go
for idx, value := range values { /* ... */ }  // `range` returns indexes and values
for idx := range values { /* ... */ }  // this time it just returns indexes
```

But more importantly:
only standard library types get to be range-able.
There is no way to make a third-party data type iterable.
Library authors can implement adapters to output a view of their data structure
as a slice, or to spit out values over a channel.
But that puts extra complexity on code that uses third-party data structures;
and requires programmers to use non-standard idioms.

Yet another privilege is that only standard types can be compared using `==`,
`>`, etc.

The biggest problem is that only standard libraries are allowed to define
generic types.
This is severely limiting to the library ecosystem around Go.
It means that, for example,
a third-party functional data structures library,
or a third-party futures library
will never be as usable as the standard library collection types.

Rust supports generics for third-party code.
And Rust implements iteration, equality, and comparison via traits that any
third-party type can implement.
Third-party Rust types are nearly indistinguishable from standard library
types,
which promotes innovation in Rust's library ecosystem.

Incidentally,
`make` and `range` are ad-hoc examples of a pattern that has generalized
support in Rust:
functions that are polymorphic in their return type.
Rust traits are more flexible than typical object-oriented interfaces:
the choice of implementation of an interface method is determined solely by the
receiver of the method.
But a trait method implementation can be selected based on
the type of the receiver,
the type of any argument position,
the types of multiple argument positions (e.g., for an equality trait),
or by the expected return type.
An implementation of `make` in Rust might look like this:

```rust
use std::sync::mpsc::{Receiver, Sender, channel};

// A `trait` declares some common behavior
trait Make {
    fn make() -> Self;
    fn make_with_capacity(capacity: usize) -> Self;
}

// An `impl` provides implementations for trait methods for given concrete types.
// Note that we can implement `Make` for the standard `Vec<T>` type right here.
// It is not necessary to change the implementation of `Vec<T>`.
impl <T> Make for Vec<T> {
    fn make() -> Vec<T> {
        Vec::new()
    }

    fn make_with_capacity(capacity: usize) -> Vec<T> {
        Vec::with_capacity(capacity)
    }
}

// `Sender` and `Receiver` are Rust's standard channel types.
// This trait implementation constructs a connected sender/receiver pair.
impl <T> Make for (Sender<T>, Receiver<T>) {
    // Rust channels do not have a fixed buffer size - a channel is either
    // non-blocking (with an unlimited buffer), or is blocking. But a non-blocking
    // channel has a different type; so that will require a different trait impl.
    fn make() -> (Sender<T>, Receiver<T>) {
        channel()
    }

    fn make_with_capacity(_: usize) -> (Sender<T>, Receiver<T>) {
        Make::make()
    }
}

#[test]
fn makes_a_vec() {
    // We specify a type for the variable to instruct the compiler with
    // implementation of `make` to use.
    let mut v: Vec<&str> = Make::make();
    v.push("some string");
    assert_eq!("some string", v[0]);
}

#[test]
fn makes_a_sized_vec() {
    let v: Vec<isize> = Make::make_with_capacity(4);
    assert_eq!(4, v.capacity());
}

#[test]
fn makes_a_channel() {
    // Or we can just let the compiler infer the type that we expect.
    let (sender, receiver) = Make::make();
    let msg    = "hello";
    let _      = sender.send(msg);
    let result = receiver.recv().expect("a successfully received value");
    assert_eq!(msg, result);
}
```

Any type can implement any trait.
The only rule is that the code for an implementation must be in the same crate
as either the type or the trait.
(A "crate" is a distributable Rust package.)
So if Rust itself or a Rust library implemented `make`,
then any third-party library could define their own custom implementations.


## The Ugly

These are some features of Go that I dislike on what I think are more
subjective grounds than the "bad parts",
or that could be worked around if some of the bad parts were fixed.


### No tagged unions, limited pattern matching

Some older languages that make heavy use of channels
(e.g. Erlang and Scala)
support tagged-union types in combination with pattern matching.
These features make great companions for channels:
a tagged union describes a fixed set of message types that a channel can accept
or produce.

Rust supports tagged-union types in the form of enums:

```rust
use std::sync::mpsc::{Receiver, Sender, channel};
use std::thread;

// This is a description of all of the messages that may be sent to a counter.
// Sending a value that is not produced by one of these enum constructors is a
// compile-time error.
#[derive(Clone, Copy, Debug)]
pub enum CounterInstruction {
    Increment(isize),
    Reset,
    Terminate,
}

pub type CounterResponse = isize;

use self::CounterInstruction::*;

pub fn new_counter() -> (Sender<CounterInstruction>, Receiver<CounterResponse>) {
    let (instr_tx, instr_rx) = channel::<CounterInstruction>();
    let (resp_tx,  resp_rx)  = channel::<CounterResponse>();

    thread::spawn(move || {
        let mut count: isize = 0;

        // If the channel has closed then `recv()` will produce an `Err` value
        // instead of `Ok`, and the loop will terminate.
        while let Ok(instr) = instr_rx.recv() {

            // We match on messages to pull out the possible distinct values and
            // types from channel messages. Because each `enum` type is sealed,
            // it is a compile-time error to omit any valid patterns.
            // This avoids potential run-time failures if we add message types
            // later, but forget to update the match here.
            match instr {
                Increment(amount) => count += amount,
                Reset             => count = 0,
                Terminate         => return
            }

            // `send` returns a `Result` because sending might fail in some
            // circumstances. But for this example we assign the result to `_`
            // to ignore it.
            let _ = resp_tx.send(count);
        };

    });

    (instr_tx, resp_rx)
}

#[test]
fn runs_a_counter() {
    let (tx, rx) = new_counter();
    let _ = tx.send(Increment(1));
    let _ = tx.send(Increment(1));
    let _ = tx.send(Terminate);

    let mut latest_count = 0;
    while let Ok(resp) = rx.recv() {
        latest_count = resp
    }

    assert_eq!(2, latest_count);
}
```

Go has type switches, which are similar to pattern matching.
Comparable Go matching code could look like this:

```go
switch instr := <-instrChan.(type) {
	case Increment:
		count += Increment.Amount
	case Reset:
		count = 0
	case Terminate:
		return
	default:
		panic("received an unexpected message!")
}
```

The difference is in compile-time type-safety:
A tagged union describes a *fixed* set of possible messages.
When sending a value to a channel in Rust,
the compiler is able to check that the value has a type that the channel
consumer knows how to handle.
And what is especially valuable is checking that all pieces of code that send
or receive on a channel are consistent in the types of values that the they
produce or consume.
If we make a change to the set of possible messages,
but forget to update some critical code to accommodate the change,
the type checker will report an error at compile time.

Because Go does not support tagged unions,
messages over polymorphic channels are dynamically typed.
You can use an interface as the type parameter for a channel,
which does limit the types of messages that are sent over the channel.
But a Go interface is not sealed;
when a new type is created that implements the given interface,
there is no compile-time check to ensure that all consumers of the channel are
updated to handle the new type.
If you use a type switch to unpack channel messages
(as opposed to using exclusively interface methods)
then you may end up introducing bugs that a different type system would have
caught.


### Dynamic typing

Go uses a mixture of static and dynamic type checking.
Any use of `interface{}`, any type assertion or type switch,
is dynamic typing.
This leads to reduced compile-time type safety.


### Dynamic dispatch, stuck in an old object-oriented mindset

In general Rust resolves every value to a concrete type at compile time.[^trait-objects]
That means that Rust can use static dispatch when invoking trait methods.
Compile-time resolution also means that there is no top type
(like `interface{}`)
that has to be refined at runtime.

[^trait-objects]: The exception is [trait objects][]. My understanding is that idiomatic Rust code uses these sparingly. Most uses of traits in Rust use the trait as a type bound on a type variable, which permits static resolution to a concrete type. For details see the Rust book sections on [traits][] and [trait objects][].

[traits]: https://doc.rust-lang.org/book/traits.html
[trait objects]: https://doc.rust-lang.org/book/trait-objects.html

In Go every invocation of an interface method uses dynamic dispatch.
Dynamic dispatch, and runtime reflection relating to type assertions
add some runtime overhead.

The technique of resolving concrete types at compile-time is not new to Rust,
and it has nothing to do with borrow-checking.
Haskell was doing the same thing at least ten years before work began on Go.
(Rust traits are an adaptation of Haskell [type classes][].)

[type classes]: http://learnyouahaskell.com/types-and-typeclasses

The designers of Go wanted a model for polymorphism that is simpler and more
flexible than what other object-oriented languages provide.
In particular they wanted composition over inheritance,
and an ability to implement interfaces after-the-fact
(so that new interfaces can be applied to pre-existing types).
This is *exactly* what traits and type classes do.
The solution that Go introduced feels to me like a less-capable reinvented wheel.


### No first-class tuple

Go supports multiple return values.
Other languages (including Rust) support multiple return values via first-class
data types called "tuples".
First-class values can have methods,
can be stored in data structures,
and can be passed over channels.
Multiple-values in Go cannot do any of those things.

We already saw a tuple return value in the implementation of the `Make` trait.
Here is a smaller example:

```rust
// Returns a tuple
fn min_and_max(xs: &[isize]) -> (isize, isize) {
    let init = (xs[0], xs[0]);
    xs.iter()
        .fold(init, |(min, max), &x| (cmp::min(min, x), cmp::max(max, x)))
}

fn consume_tuple() {
    let xs = vec![1, 2, 3, 4, 5];
    let (min, max) = min_and_max(&xs); // unpack tuple with destructuring assignment
    assert_eq!(1, min);
    assert_eq!(5, max);
}
```

A consequence of the lack of first-classness in Go is that there is no obvious
way to communicate potential failures over a channel.
It seems like this should work, but it does not:

```go
// Nope
results := make(chan (*models.Document, error))
```

As far as I know the best options for doing this are to define a custom
`struct` type,
to make type assertions on values from channels,
or to send success values and errors over separate channels.

Another consequence is that there is no good way to define methods on multiple
return values,
or to define a function that accepts multiple return values with a callback.
This makes it impractical to define an analog of Rust's `and_then` combinator
for Go return values.


### Shortage of high-level parallelism and concurrency features

The post [Channels Are Not Enough][] makes a detailed argument about problems
with Go's lack of concurrency abstractions.
In the section "List manipulation cannot be abstracted" I pointed out that Go
does not provide an easy way to run a set of computations in parallel.
@kachayev points out that the problem is more general than that.
Really this is another symptom of lack of generics.

[Channels Are Not Enough]: https://gist.github.com/kachayev/21e7fe149bc5ae0bd878

In the parallel fetch example I showed a Rust solution that uses futures,
which are great for concurrent IO.
The [futures][] library relates to a larger async IO library called [Tokio][],
which seems to be popular.
But async IO is not intended to provide parallelism.
The excellent book [Parallel and Concurrent Programming in Haskell][] has this
to say about the distinction between parallel and concurrent code:

> A parallel program is one that uses a multiplicity of computational hardware
(e.g., several processor cores) to perform a computation more quickly. The aim
is to arrive at the answer earlier, by delegating different parts of the
computation to different processors that execute at the same time.
>
> By contrast, concurrency is a program-structuring technique in which there
are multiple threads of control. Conceptually, the threads of control execute
“at the same time”; that is, the user sees their effects interleaved. Whether
they actually execute at the same time or not is an implementation detail;
a concurrent program can execute on a single processor through interleaved
execution or on multiple physical processors.

[Parallel and Concurrent Programming in Haskell]: http://chimera.labs.oreilly.com/books/1230000000929
[Tokio]: https://tokio.rs/

Go uses goroutines for both parallel and concurrent programming.
Rust libraries offer a selection of tools whose strengths make them especially
useful for different kinds of problems.

When you want true multi-core parallel processing,
the Map-Reduce pattern offers a powerful solution.
This is another application of list abstractions.
You can apply Map-Reduce in Rust using parallel iterators from the [Rayon][]
library:

[Rayon]: https://github.com/nikomatsakis/rayon


```rust
// This import brings the `par_iter` method into scope.
// `par_iter` is a method on a Rayon trait, and Rayon provides an implementation
// of that trait for standard slice types.
use rayon::prelude::*;

pub fn average_response_time(logs: &[LogEntry]) -> usize {
    let total = logs.par_iter()
        .map(|ref entry| entry.end_time - entry.start_time)
        .sum();
    total / logs.len()
}
```

Parallel iterators implement a variation of the `map` method that divides work
among a set of job queues that feed into a worker pool,
so that invocations of the `map` callback run in parallel.
As with goroutines,
this is lightweight parallelism that scales to a large number of parallel tasks.
But parallel iterators are a high-level abstraction that take care of some
complicated details for you.
For example, Rayon transparently splits work into batches,
which provides better performance than queueing up every invocation of the
`map` callback separately.
(The default batch size is 5000 items, but that value is tunable.)
The `sum` method (which is the Reduce step in this example) is also part of Rayon,
which means that it is optimized for consuming batches of results from worker
threads.

It might seem strange to have to use two different libraries for concurrent vs
parallel code.
But those are separate concerns, with different underlying assumptions.
Usually you do not actually want both at the same time.


## Conclusion

How do I think Go could be better?
Generics.
Nearly all of my complaints boil down to lack of support for generics.
But I think that Rust-style traits, and getting rid of `nil` would also be
useful changes.

In its current form, I prefer not to use Go.
It is not that Go is bad - it is just that there are lots of languages
available that I find more enjoyable.
When I work with Go I cannot help thinking about how I could be doing things
differently in another language.

If you are willing to put in the time to understand lifetimes and borrow checking,
Rust makes a fantastic language that does everything that Go does,
but has none of the "bad parts" that I called out.

Javascript is (like Go) easy to learn,
and has wonderful support for concurrency (if not parallelism).
When paired with Flow or Typescript you get (in my opinion) more robust
type safety than Go provides.
Javascript with Flow in particular has none of the "bad parts" from this post.

Erlang and Scala both support lightweight concurrency in the same style that Go
does,
and they are both great for functional programming.

Clojure is not type-safe - but it does fantastic things!
My favorite functional data structure implementations are the ones in Clojure.

Haskell has amazing type safety,
some of the best concurrency and parallelism features that I have seen in any
language,
and is well-suited to network server code.
Haskell is another language that avoids the "bad parts" from this post.

We have better tools than ever for getting work done.
Even Go - whether I like it or not - is clearly useful for building cool things.
But if you take anything away from this post,
I hope it is an interest in taking a look beyond the imperative
/ object-oriented world.
I encourage you to pick one of the languages above,
and take some time to learn about it and to get a good feel for its strengths.
I think you will be glad that you did.
