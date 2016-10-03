# Which type-checked language should you use?

I sometimes have a conversation that goes like this:

colleague
:We're thinking of using Language X for this project. What do you think?

me
:Language X has some nice features. But I think there are missed opportunities
in the language - particularly in its type system. There are other languages
that I prefer to use.

colleague
:Ok; which better language do you recommend?

me
:Well...

It is hard to give one recommendation for the best language to use in a project.
Every language comes with some caveats.
I would like to take a look at the merits of a few different languages as a way
to continue the above conversation.
For this post I will focus on how the type systems of statically type-checked
languages can aid development.
In my opinion a good type system can be a great asset,
and I view it as one of the most important considerations when choosing
a programming language.

A compiler with good type-checking is like a colleague sitting next to you
writing tests for you, pointing out potential bugs, and giving you a subtle nod
when you fix all the problems.
A compiler with mediocre type-checking is like a less-experienced colleague who
is distracted by something.

Another perspective comes from [type-driven development][].
Type-driven development is not so unlike test-driven development.
In test-driven development tests serve as an executable specification of what
the program should do.
The programmer writes tests, and then writes code that makes those tests pass.
In type-driven development the program specification is given in the form of
types of data structures and of functions that act on those data structures.
The programmer writes types, and then writes implementations that satisfy those
types.
Types-as-specification has some advantages:
there is no need to provide fake input data; all branches of code are always
checked; and type annotations are better-suited than tests for serving
double-duty as documentation.
(I don't mean to say that the two approaches are not compatible!)
But if a program specification takes the form of types,
then amount of detail that the specification can express is limited by the
expressiveness of the type system.
It takes an expressive type system to make type-driven development useful.



Static type-checking can reduce your test burden,
and type annotations provide self-documentation that is always up-to-date.
Types can improve productivity through [type-driven development][].
A good type system magnifies these advantages.
A mediocre type system might feel like more of a chore than a help.
In the best case a mediocre type system requires more programmer discipline and
experience to get its full benefits.
My top choices of languages with good type systems are Rust and Haskell.
If either of those seems like a good fit for your project,
then I think that you are in for a pleasant development experience.
But whether Rust, Haskell, or another language is right for your project
depends on a variety of factors.

But what makes one type system more powerful than another?
Here is a breakdown of some features that I think are useful to have.
(Explanations of each feature follow.)
Each of these features helps to make a type system more expressive.

|--------------------------+------+---------+-------+------+----+------+-------|
|                          | Rust | Haskell | Scala | Java | Go | Flow | Idris |
|--------------------------|:----:|:-------:|:-----:|:----:|---:|:----:|:-----:|
| parametric polymorphism  | ✓    | ✓       | ✓     | ✓    |    | ✓    | ✓     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| constrained types        | ✓    | ✓       | ✓     |      |    |      | ✓     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| algebraic data types     | ✓    | ✓       | ✓     |      |    |      | ✓     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| no `null`                | ✓    | ✓       |       |      |    | ✓    | ✓     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| no subtyping             | ✓    | ✓       |       |      | ✓  |      | ✓     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| structural types         |      |         | ✓     |      | ✓  | ✓    | ?     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| Hindley-Milner inference | ✓    | ✓       |       |      |    |      |       |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| higher-order types       |      | ✓       | ✓     |      |    |      | ✓     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| rank-n types / GADTs     |      | ✓       | ?     |      |    |      | ✓     |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|:-----:|
| dependent types          | ?    |         |       |      |    |      | ✓     |
|--------------------------+------+---------+-------+------+----+------+-------|

Of course a language is more than the sum of its parts, and a feature checklist
cannot do a language justice.
However, these features are, IMO, important building blocks.

# Type system features

Each of the features listed above is a deep topic.
What follows is a whirlwind summary of each feature
with links for further reading.


## parametric polymorphism

Parametric polymorphism is also known as *generics*.
This feature permits polymorphic functions and data structures,
while allowing the compiler to keep track of the types flowing into and out of
those functions and data structures.

For example, a function that returns the first element in a list can specify
that the type of the return value is the same as the types of values in the
input list
(this is a Scala function type signature):

```scala
def first[T](xs: List[T]): T
```

Type parameter annotations act as specifications for type-driven development -
this provides a language for describing specific details of program behavior.
Without parametric polymorphism, it would be necessary to type-cast the result
of `first` into the appropriate type on every invocation,
which would be a source of potential errors.
Type casts shift the burden of checking program correctness from the compiler
to the programmer -
and therefore reduce the usefulness of the compiler.

Furthermore, without the ability to use the type variable `T` in the signature
of `first`,
the type-signature-as-specification for `first` would lack a crucial detail
about how `first` is expected to behave.

That is an important way in which parametric polymorphism makes a type system
expressive.
Type variables let types express concepts like "this thing is always the same
type as that thing".
Writing types without type variables is like speaking without pronouns.

An example that is a bit more sophisticated is `fold`:

```scala
def fold[T, R](f: (T, R) => R, zero: R, xs: List[T]): R
```

`fold` has [tremendous expressive power (PDF link)][fold].
There are many abstractions that can be built using `fold` as a building block.
Code that is concise-but-abstract can become confusing -
a particular advantage of type-checking is that it helps to keep the programmer
on the right track when working with such code.
Any language that does not have the expressive power to describe the type of the
`fold` function will lack the capability to express entire classes of
boilerplate-reducing abstractions at the type level,
and will lack crucial type-safety at the value level.

TODO: ^ reword that to make more sense

[fold]: https://docs.google.com/viewer?url=http%3A%2F%2Fwww.cs.nott.ac.uk%2F%7Egmh%2Ffold.pdf

The input data structure to `fold` does not have to be a `List`.
Any type that can represent multiple values is a candidate for a folding.
Instead of reimplementing `fold` for `List`, `Set`, `Tree`, etc., it should be
possible to write one type that represents the common abstraction over all of
those types.
That can be done my combining parametric polymorphism with higher-order types.
More on that in the next section.


## higher-order types

Here I am referring to the concept that is often called *higher-kinded types*.

Some types are actually *type constructors*:
they are not do not represent possible values by themselves,
but when applied to argument types they produce usable, concrete types.
An example is `List`.
There is no value has the type `List`.
(Or at least there shouldn't be.)
But there are values with types like `List[Int]` or `List[String]`.

This is a lot like how functions are values that take values as arguments to
produce new values.
Type constructors are types that take types as arguments to produce new types.
We could say that a function is a value constructor;
or we could say that a type constructor is a type-level function.

In the latter view, `List[Int]` is a type-level expression that applies `List`
to `Int` to produce a type that does not have its own name,
but that is usable and useful.

Higher-order types are expressions that let us refer to a type constructor
(e.g. `List`) without having to specify what its type argument(s) will be.
In other words, higher-order types let us abstract over type constructor
arguments.
This is useful for capturing abstractions that are common to many types.
In the last section I pointed out that while `List` values can be folded,
the concept of folding is not limited to `List`s -
lots of other types are "foldable".
Here is a Scala type signature for a more-generalized version of `fold`:

```scala
def fold[F[_], T, R](f: (T, R) => R, zero: R, xs: F[T]): R
```

In this signature, `F[_]` declares a type variable `F`,
which may be any type that takes one type parameter.
(I.e., `F` can be any single-argument type constructor.)
`F` could be `List`, `Tree`, `Promise`, some user-defined type, or one of many
other types.
This finally gives as a signature that accurately represents the universality
of `fold`.

To actually implement such an abstract signature requires language support for
some form of *ad-hoc polymorphism*.
That could be interfaces,
or *constrained types*, which we will get to in the next section.

TODO: higher-order types vs object-oriented interfaces

You may have heard about [monads][], applicatives, and functors.
Those concepts are tremendously useful, even if they are not easy to explain.
Each of those concepts requires higher-order types to unlock its full
expressive power.


[monads]: http://james-iry.blogspot.com/2007/09/monads-are-elephants-part-1.html



## constrained types

"Constrained types" refers to the feature that Haskell and Scala call "[type classes][]",
and that Rust calls "[traits][]".
Traits in Rust are not at all like traits in Scala or Smalltalk.
And type classes have little to do with the concept of classes in
object-oriented languages.
In fact type classes / traits are a lot more like interfaces in Go,
Java, or Scala - but with some advantages:

- Type classes can express that multiple arguments to a method have the same type.
- Type class methods may select an implementation based on the expected return
  type of a method invocation, or on the type of an arbitrary argument position.
  (Interface methods are selected based on the type of the receiver)
- Interfaces can lead to name conflicts if a type implements two interfaces
  with methods that have the same name.
  Type class functions are namespaced by module, not by implementing type;
  so a type can implement type class functions with the same name, as long as
  those functions are qualified if more than one of them is imported in the
  same module.
- One can add new behavior to an existing type by defining a trait (even if the
  type was defined in another module or another library).
- Rust developers (who care a lot about performance) point out that
  [methods on traits are dispatched statically][static dispatch].
  Static dispatch is faster than dynamic, since dynamic dispatch requires extra
  lookup steps.

[type classes]: http://learnyouahaskell.com/types-and-typeclasses#typeclasses-101
[traits]: https://doc.rust-lang.org/book/traits.html
[static dispatch]: https://blog.rust-lang.org/2015/05/11/traits.html

Constrained types work in concert with parametric polymorphism to add another
level of expressiveness.
Consider the problem of writing a function that checks whether all elements in
a list are equal.
Here is a possible implementation of that function (this is Haskell code):

```haskell
allEqual xs = let firstElem = head xs
              in all (== firstElem) xs
```

What should the type of this function be?
It takes a list of values that can be compared for equality;
but there are lots of types that can be compared with `(==)`.
Ideally this function would accept any of those types in the input list.
A tempting answer is to indicate that the function is fully polymorphic on the
type of values in the input list:

```haskell
allEqual :: [a] -> Bool
```

(In Haskell a lowercase letter in a type expression is a type variable.
This line indicates that the type of `allEqual` is a function that takes a list
of values of any type `a` as an argument,
and returns a boolean value.)

This will not work!
The compiler will rightly point out that the unqualified type variable `a`
implies that `allEqual` will accept a values of _any_ type in the input list,
but that there are lots of types that cannot be compared with the `(==)` operator.
What we need is a way to indicate that only types that satisfy some
*constraint* are allowed.
In Haskell that looks like this:

```haskell
allEqual :: Eq a => [a] -> Bool
```

This version expresses that `a` may be any type that implements the `Eq` type
class.
It happens that `(==)` is defined as part of the `Eq` type class:

```haskell
class Eq a where
  (==) :: a -> a -> Bool
  (/=) :: a -> a -> Bool

  -- default implementations
  x == y = not (x /= y)
  x /= y = not (x == y)
```

That means that any type `a` qualifies as an instance of `Eq` if it provides
an implementation of ether the equality `(==)` or inequality `(/=)` operator.
(Only one must be implemented, because each has a default implementation that calls the other.)
Conversely, any type that is an instance of `Eq` can be safely used with both
operators.

Again, this is similar to interfaces in other languages.
Go and Java do not have special interfaces for types that can be compared for equality -
but if the did the signature of the `allEqual` function in Go might look like this:

```go
// Hypothetical interface for types that be compared for equality
type Eq interface {
    eq(other Eq) bool
    ne(other Eq) bool
}

func allEqual(xs ...Eq) bool
```

Constrained types have some particular advantages over interfaces:

- Type classes can express that multiple arguments have the same type.
- The implementation of an interface method is selected based on the type of
  the receiver - but the implementation of a type class function can be selected
  based on the type of the second argument, the third argument, the types of two
  arguments together, or even the return type.
- Interfaces can lead to name conflicts if a type implements two interfaces
  with methods that have the same name.
  Type class functions are namespaced by module, not by implementing type;
  so a type can implement type class functions with the same name, as long as
  those functions are qualified if more than one of them is imported in the
  same module.

Rust traits have all of the same advantages.

In the hypothetical Go `Eq` interface,
note that there is no guarantee in the type signature that the receiver and
argument of `eq` are of the same type.
Both types must implement `Eq`; but that interface allows `eq` to be called
with, e.g., a `string` value and an `int64` value.
It is obvious to programmers that the both operands should be of the same type -
but that is lost on the compiler.
This is a lack of expressiveness in the type system.
The results are that it is not possible to write specifications-as-types that
express concepts like "these types should match",
and implementations of `eq` need to have runtime checks to make sure that their
operands are really the same type.

In the Haskell implementation of `Eq` the variable `a` is bound in the first line (`Eq a`);
so it is implied that the `a` in the type of each function is an instance of `Eq`.
And since the same variable, `a`, appears twice in each type signature,
both arguments must have the same type.


```haskell
data User = User { userName :: String, userAge :: Int }

instance Eq User where
  x == y = userName x == userName y && userAge x == userAge y
```

Haskell has a convenient shorthand:

```haskell
data User = User { userName :: String, userAge :: Int }
  deriving Eq
```

## algebraic data types (ADTs)

The biggest obstacle to type-safety is *partial* functions.
By "partial" I mean functions that can throw exceptions or panic in some
circumstance.
A common partial function is one that returns an element from a given index in
a list, but that throws an exception if that index is out-of-bounds.

A more delicate class of partial partial functions are those that operate on
a type that might take on different "shapes" depending on runtime conditions.
Algebraic data types are a means of defining such types in a safer way -
ADTs encourage the programmer to make sure that every function is *total*
(the opposite of partial).
More importantly,
ADTs provide a vocabulary for accurate type-level descriptions of whatever
shapes values may take.

A simple case where ADTs shine is the [option pattern][TODO].
Rust has a built-in type that looks like this:


```rust
enum Result<T,E> {
  Ok(T),
  Err(E),
}
```

`Result` is most often used as a return type in functions might need to return
an error.
`Ok` and `Err` are *value constructors* -
One can create a value of type `Result` using these constructors.
For example,

```rust
let: Result<&str,Error> = Ok("hello there")
```

A `Result` value can be inspected at runtime to determine whether it was
constructed using `Ok` (in which case it represents a success value) or was
constructed with `Err` (in which case it represents an error).
This example uses [pattern matching][TODO]:

```rust
// Function to show message-of-the-day
fn show_MOTD() {
  let motd_result = fetch_MOTD(); // Might fail due to, e.g., network error
  match motd_result {
    Ok(msg) => println!(msg)
    Err(_)  => println!("Sorry, the message-of-the-day is not available today.")
  }
}
```

So `Result` values have two possible shapes (`Ok` or `Err`).
And the two shapes have no overlap:
they represent opposite outcomes;
they each come with a wrapped value,
but the wrapped value in each shape has a different type.

Other approaches to error cases might be to:

- return `null` on failure
- throw an exception
- return multiple values (one for success, another for failure)

Returning a `Result` value has three advantages over those other approaches:

The type signature for functions that may fail can use `Result` as a return
type,
which makes those types an accurate specification for possible failure cases.
Type signatures in many languages do not express that a function might return
null or might throw an exception.

To use a successful result, a caller must unwrap a `Result` value somehow.
(The example above uses pattern matching for that purpose.)
This makes it possible for the compiler to apply static analysis to ensure that
every error case is handled somehow -
even if that is just passing the error up the call stack.
This means that runtime exceptions due to unhandled error cases are rare in
Rust and Haskell.
(Haskell also provides a built-in option-pattern type.)
This means that the compiler can verify that the type-level specification of
a program matches the implementation -
if a function type does not indicate a possible errors, then it must do
something about errors that might be returned by functions that it calls.
Any case where the compiler can verify that types accurately describe
implementation is an asset to type-driven development.

Languages that use exception handling typically do not check at compile time to
make sure that errors are caught.
(A notable exception is Java; but Java lacks the third advantage.)
Languages that return multiple values to indicate errors (e.g. Go)
also tend not to have compile-time checking to ensure that errors are handled.

Finally, `Result` is a first-class value that abstracts over success and
failure.
This makes it possible to apply abstractions to reduce boilerplate when dealing
with multiple possible errors.
Rust has a very helpful [`and_then`][TODO] method that uses a callback to
operate on a success value,
but returns error results as-is:

```rust
fn show_personalized_MOTD() {
  let user_result = fetch_current_user(); // Might fail
  let motd_result = user_result.and_then(|user| {
    fetch_MOTD_for_user(&user) // Might fail
  });
  match motd_result {
    Ok(msg) => println!(msg)
    Err(_)  => println!("Sorry, the message-of-the-day is not available today.")
  }
}
```

This time when we get to the `Err(_)` pattern match we might have gotten there
because `fetch_current_user()` failed,
or because `fetch_MOTD_for_user` failed.

This kind of abstraction does not work with multiple return values or with
caught exceptions because in those cases there is no single, first-class value
that abstracts over both success and error results.

Haskell further generalizes the `and_then` pattern:
Haskell's option type, `Maybe`, is a [monad][Maybe Monad]

TODO: example of domain-specific ADT


## no `null`

`null` is the [billion-dollar mistake][].
In most languages that include a `null` value it is an instance of a bottom
type -
meaning that `null` may be given in expressions where nearly any type is
expected.
This bypasses the type system,
making type-level specifications weaker.
In every type signature in languages with `null` there is ambiguity over
whether arguments or return values might be `null`.
Languages such as Java, Go, and Scala do not have the type-level vocabulary to
specify that a given value will not be `null`.
This is a case where removing a feature (removing the `null` bottom type)
makes the language _more_ expressive.

[billion-dollar mistake]: https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare

Many languages restrict `null` (or `nil`) values to non-primitive types, or to
pointer types.
That reduces the scope of the problem - but not by enough.

In the feature table above Flow has a "no `null`" check mark -
even though it is just a type checker for Javascript,
which does have both `null` and `undefined` values.
This is because Flow does not treat `null` as a bottom type.
Flow interprets `null` as the sole value of a `null` type,
which is not a subtype of any other type.
Flow treats `undefined` the same way:
as a distinct type with only one possible value.
This makes Flow's versions of `null` and `undefined` behave like the `Unit`
type in Haskell, Rust, and Scala.

In Flow type signatures,
values may only be `null` if the type a value is a type union that includes the
`null` type.
E.g. `ResultType | void` or `?ResultType`.
This makes Flow's type system sufficiently expressive to indicate where `null`
values may or may not appear,
and allows Flow to check to verify at type-checking time that possible `null`
values are accounted for.
TODO: citation needed


## no subtyping

Subtypes - and in particular subclasses - can lead to unnecessary ambiguity.
In my opinion type classes are a better way to achieve ad-hoc polymorphism -
at least with respect to type-driven development.

TODO: expand on how type classes are better for TDD

references:
http://languagengine.co/blog/making-sense-of-subtypes/
http://okmij.org/ftp/Computation/Subtyping/

TODO: move following paragraph to section on constrained types?

In Haskell the `Int` type is an instance of the `Num` type class.
This means that `Int` can be used in any context where instances of `Num` are
expected.
What distinguishes this from subtyping in other languages is that `Num` is _not_
a type.
In the sense of a type as a set of possible values,
it is arguable that `Num` is a type -
but Haskell does not permit `Num` to be used as a type.
Instead `Num` is a set (or class) of possible types that have common behavior.
`Num`, and other type classes, are used as *constraints* on type variables.


## Hindley-Milner Type Inference

Before talking about HM inference, let's first talk about lenses.
Idiomatic functional code uses immutable data structures,
which are valuable for making code easy to reason about.
But updating nested immutable data structures can be painful without a specialized library
(e.g. `lens`),
since a new data value has to be created at each level of nesting.
Consider this Haskell code written without lenses:

```haskell
data Group  = Group  { _groupName  :: String, _groupMembers :: Map PersonID Person }
data Person = Person { _personName :: String, _personTags   :: Set Tag }

type PersonID = Int
type Tag      = String

addTagToMember :: Tag -> PersonID -> Group -> Group
addTagToMember tag id group =
  let members = Map.adjust (addTagToPerson tag) id (_groupMembers group)
  in group { _groupMembers = members }

addTagToPerson :: Tag -> Person -> Person
addTagToPerson tag person = person { _personTags = Set.insert tag (_personTags person) }
```

The same functions can be written much more clearly and concisely with lenses
(for details on lenses see the [tutorial][lens]):

[lens]: https://hackage.haskell.org/package/lens-tutorial-1.0.1/docs/Control-Lens-Tutorial.html

```haskell
makeLenses ''Group
makeLenses ''Person

addTagToMember' :: Tag -> PersonID -> Group -> Group
addTagToMember' tag id = groupMembers . ix id . personTags %~ Set.insert tag
```

The version with lenses is shorter (essentially just an access path and a reference to the set insert function), and eliminates a helper function.


TODO: HM helps dispatch based on expected return type at call site
TODO: lenses are hard without HM



### Rust

Rust has a simple, but powerful, type system.
Like Haskell and Go, Rust eschews subtyping.
Rust provides polymorphism via *constrained types*.
Rust calls this feature [traits][Traits];
Haskell and Scala have a very similar feature, but they call it "type classes".

Rust provides good support for [*algebraic data types*][ADTs in Rust].
Rust's [Enums][]


Rust is not garbage collected; which results in some limitations on the programmer.
For example, code idioms that take advantage of closure scope
(which I use generously in e.g. Haskell and Javascript)
can be much trickier to implement in Rust.
If you do not need a fast systems language,
Rust might not be your best option.
(But maybe try it anyway. Rust is a fantastic language.)

[Enums]: https://doc.rust-lang.org/book/enums.html
[ADTs in Rust]: http://datamelon.io/blog/2015/understanding-and-using-adts-in-rust.html


### Haskell

Haskell is my go-to for a high-level, type-checked language.
But Haskell has its own learning curve:
if you do not have experience in functional programming,
learning Haskell will require unlearning a lot of what you know.
That tends to scare people away.
If I tell someone to "use Haskell", odds are that they will dismiss that as
weird advice from an eccentric academic.
(I wish that this were not true. You really should [Learn Haskell][].)
Even if you are excited about using Haskell on a project,
it is probably not the right choice if the other members of your team are not
excited about learning Haskell.


### Scala

The next-best choice that comes to my mind is Scala.
Scala has many of the type-level features that I find so appealing in Rust and
Scala, including [algebraic data types][] and [type classes][].
(Rust calls type classes "traits".)
Of course there are downsides to Scala too.

Rust and Haskell use Hindley-Milner type inference.
That means that the compilers are really good at figuring out what the type of
a term is.
You end up needing fewer type annotations; and you can ask the compiler to fill
in types for you.
Because Scala has to support subtyping, it must use local flow-based type
inference instead.  TODO: is that still accurate?
That means that the compiler needs more hand-holding in the form of more type
annotations.

TODO: why you don't need subtyping


### Go

Many people are excited about Go.
It makes me happy that people are getting excited about a type-checked language.
Some of the benefits of Go include:

- static type-checking
- fast performance
- great concurrency support
- good support for, e.g., networking

Focusing on the first point:
I think that static type-checking is valuable.
But in my opinion Go missed some opportunities that would have made its
type-checking in particular much more valuable.
([This article][Why Go Is Not Good] sums up my feelings accurately.)
But I find it hard to come up with a simple recommendation for a language that
is better.



[Why Go Is Not Good]: http://yager.io/programming/go.html
[type-driven development]:
[Learn Haskell]:
[algebraic data types]:
[type classes]:
[rank-n types]: https://ocharles.org.uk/blog/guest-posts/2014-12-18-rank-n-types.html


TODO: link to book on type-driven development
