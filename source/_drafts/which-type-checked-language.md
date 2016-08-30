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

|--------------------------+------+---------+-------+------+----+------|
|                          | Rust | Haskell | Scala | Java | Go | Flow |
|--------------------------|:----:|:-------:|:-----:|:----:|---:|:----:|
| parametric polymorphism  | ✓    | ✓       | ✓     | ✓    |    | ✓    |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| constrained types        | ✓    | ✓       | ✓     |      |    |      |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| algebraic data types     | ✓    | ✓       | ✓     |      |    |      |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| no `null`                | ✓    | ✓       |       |      |    | ✓    |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| no subtyping             | ✓    | ✓       |       |      | ✓  |      |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| structural types         |      |         | ✓     |      | ✓  | ✓    |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| Hindley-Milner inference | ✓    | ✓       |       |      |    |      |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| higher-order types       |      | ✓       | ✓     |      |    |      |
|--------------------------|:----:|:-------:|:-----:|:----:|:--:|:----:|
| rank-n types / GADTs     |      | ✓       | ?     |      |    |      |
|--------------------------+------+---------+-------+------+----+------|


## algebraic data types (ADTs)


## parametric polymorphism

Parametric polymorphism is also known as *generics*.

Some types are actually *type constructors*, which take types as arguments to
produce new types.
This is a lot like how functions are values that take values as arguments to
produce new new values.
We could say that a function is a value constructor,
or we could say that a type constructor is a type-level function.

For example (this is Scala code):

```scala
val xs: List[Int] = List(1, 2, 3)
```

There is a type `List` -
but there are no values of type `List` because `List` is a type constructor.
A list must be a list _of_ something - like a list of integers (`List[Int]`) or
a list of strings (`List[String]`).

One can use type variables in places where a specific type is not known ahead
of time.
A function that returns the length of a list is not concerned with what is in
the list;
so it should be able to operate on any list type.
A length function could have a type like this:

```scala
def length[T](xs: List[T]): Int
```

Type variables allow one to specify relationships between types of arguments
and return values.
The type of an argument might not be known;
but it might be known that two arguments must always have the same type,
or that the return type of a function must match the type of an argument.
A function that returns the first element of a list can take any type of list
as an argument -
but the type of the returned value is always the same as the type parameter of
the list:

```scala
def first[T](xs: List[T]): T
```

That is an important way in which parametric polymorphism makes a type system
expressive.
Type variables let types express concepts like "this thing is always the same
type as that thing".
Writing types without type variables is like speaking without pronouns.

Furthermore,
parametric polymorphism allows the compiler to keep track of types as values
flow into and out of functions,
and into and out of data structures.
If the compiler is not able to do that then you either lose type information
(and lose out on opportunities for the compiler to spot bugs)
or the compiler requires the programmer to fill in details with type casts.
Type casts shift the burden of checking program correctness from the compiler
to the programmer -
and therefore reduce the usefulness of the compiler.


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

Rust, Haskell, (TODO: and Go?) use Hindley-Milner type inference.
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
