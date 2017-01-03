
<!DOCTYPE html>
<!--[if IEMobile 7 ]><html class="no-js iem7"><![endif]-->
<!--[if lt IE 9]><html class="no-js lte-ie8"><![endif]-->
<!--[if (gt IE 8)|(gt IEMobile 7)|!(IEMobile)|!(IE)]><!--><html class="no-js" lang="en"><!--<![endif]-->
<head>
  <meta charset="utf-8">
  <title>Category Theory proofs in Idris - sitr.us</title>
  <meta name="author" content="Jesse Hallett">

  
  <meta name="description" content="[Idris][] is a programming language with dependent types.
It is similar to [Agda][], but hews more closely to [Haskell][].
The goal of Idris is to &hellip;">
  

  <!-- http://t.co/dKP3o1e -->
  <meta name="HandheldFriendly" content="True">
  <meta name="MobileOptimized" content="320">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <!-- OpenID delegation -->
  <link rel="openid.delegate" href="http://sitr.us/" />
  <link rel="openid.server" href="https://indieauth.com/openid" />

  
  <link rel="canonical" href="http://sitr.us/Cat.lidr">
  <link href="/favicon.ico" rel="icon">
  <link href="/stylesheets/screen.css" media="screen, projection" rel="stylesheet" type="text/css">
  <link href="http://feeds.feedburner.com/hallettj" rel="alternate" title="sitr.us" type="application/atom+xml">
  <script src="/javascripts/modernizr-2.0.js"></script>
  <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
  <script>!window.jQuery && document.write(unescape('%3Cscript src="./javascripts/libs/jquery.min.js"%3E%3C/script%3E'))</script>
  <script src="/javascripts/octopress.js" type="text/javascript"></script>
  <!--Fonts from Google"s Web font directory at http://google.com/webfonts -->
<link href="http://fonts.googleapis.com/css?family=PT+Serif:regular,italic,bold,bolditalic" rel="stylesheet" type="text/css">
<link href="http://fonts.googleapis.com/css?family=PT+Sans:regular,italic,bold,bolditalic" rel="stylesheet" type="text/css">
<link href="http://fonts.googleapis.com/css?family=Ubuntu+Mono:regular,italic,bold,bolditalic" rel="stylesheet" type="text/css">

  
  <script type="text/javascript">
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-327628-1']);
    _gaq.push(['_trackPageview']);

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
  </script>


</head>

<body   >
  <header role="banner"><hgroup>
  <h1><a href="/">sitr.us</a></h1>
  
    <h2>posts by Jesse Hallett</h2>
  
</hgroup>

</header>
  <nav role="navigation"><ul class="subscription" data-subscription="rss">
  <li><a href="http://feeds.feedburner.com/hallettj" rel="subscribe-rss" title="subscribe via RSS">RSS</a></li>
  
</ul>
  
<form action="https://www.google.com/search" method="get">
  <fieldset role="search">
    <input type="hidden" name="q" value="site:sitr.us" />
    <input class="search" type="text" name="q" results="0" placeholder="Search"/>
  </fieldset>
</form>
  
<ul class="main-navigation">
  <li><a href="/">Blog</a></li>
  <li><a href="/blog/archives">Archives</a></li>
</ul>

</nav>
  <div id="main">
    <div id="content">
      <div>
<article class="hentry" role="article">
  
  <header>
    
      <h1 class="entry-title">Category Theory proofs in Idris</h1>
    
    
      <p class="meta">
        








  


<time datetime="2014-05-04T00:00:00-07:00" pubdate data-updated="true">2014-05-04</time>
        
      </p>
    
  </header>


<div class="entry-content">[Idris][] is a programming language with dependent types.
It is similar to [Agda][], but hews more closely to [Haskell][].
The goal of Idris is to bring dependent types to general-purpose programming.
It supports multiple compilation targets, including C and Javascript.

[Idris]: http://www.idris-lang.org/
[Agda]: http://wiki.portal.chalmers.se/agda/pmwiki.php
[Haskell]: http://www.haskell.org/haskellwiki/Haskell

Dependent types provide an unprecedented level of type safety.
A quick example is a [type-safe printf implementation (video)][printf].
They are also useful for theorem proving.
According to the [Curry-Howard correspondence][],
mathematical propositions can be represented in a program as types.
An implementation that satisfies a given type
serves as a proof of the corresponding proposition.
In other words, inhabited types represent true propositions.

[printf]: https://www.youtube.com/watch?v=fVBck2Zngjo
[Curry-Howard correspondence]: http://en.wikipedia.org/wiki/Curry–Howard_correspondence

The Curry-Howard correspondence applies to every language with type checking.
But the type systems in most languages are not expressive enough
to build very interesting propositions.
On the other hand,
dependent types can express quantification
(i.e., the mathematical concepts of universal quantification (∀) and existential quantification (∃)).
This makes it possible to translate a lot of interesting math into machine-verified code.

This post is written in literate Idris.
The [original markup][] can be compiled and type-checked.
Code blocks that are prefixed with greater-than symbols (>) in the markup are evaluated.
Blocks that are marked off with three backticks
are given for illustrative purposes and are not evaluated.

[original markup]: /Cat.lidr

> module Cat
>
> import Control.Isomorphism
> import Data.Morphisms

In Idris, partial functions are allowed by default.
A totality requirement can be specified per-function.
This line enforces totality checking by default for functions in this module.

> %default total

A function that is *total* is guaranteed to terminate
and to return a well-typed output for every possible input.[^totality]
A function that does not terminate,
or that throws a runtime error for some inputs,
is said to be *partial*.

[^totality]: The [Halting Problem][] states that there are programs that cannot be proven to terminate.  That does not mean that it is impossible to prove that any program terminates.  Idris and other languages with totality checking put some restrictions on the forms that functions are allowed to take so that totality checking is possible.

[Halting Problem]: http://en.wikipedia.org/wiki/Halting_problem

A partial function can introduce a logical contradiction,
which would make proofs unreliable.
So totality checking is useful for theorem proving.

## Theorem proving

Consider the definition of the natural number type in the Idris standard library:

``` idris
data Nat = Z | S Nat
```

This defines a type, `Nat`,
with two constructors for producing values:
a number may be zero (`Z`),
or it may be one greater than another number (`S Nat`).

A type can be *indexed* by another type.
That describes a type produced by a type constructor
that takes one or more values as parameters.
Here is a constructor for indexed types from the Idris standard library:

``` idris
data LTE  : (n, m : Nat) -> Type where
  lteZero : LTE Z    right
  lteSucc : LTE left right -> LTE (S left) (S right)
```

This declares that `LTE` is a constructor that takes two `Nat` _values_ as parameters,
and produces a concrete `Type`.
The types that `LTE` constructs also happen to be propositions which state that
one natural number is less than or equal to another.
It should be read,
"the natural number n is less than or equal to the natural number m".

Two value constructors are given.
They are written so that a value that satisfies a given `LTE` type be written
if and only if the `n` in that type is less than or equal to the `m`.
In this way, a value that satisfies a type of the form `LTE n m`
is a proof that `n` really is less than or equal to `m`.

`lteZero` is a singleton value - it is a constructor that takes no arguments.
But its type contains a variable; so it is polymorphic.
`lteZero` can satisfy any type of the form, `LTE Z n`.
`lteZero` is effectively an axiom, stating a fundamental property of natural numbers.

Given the definition of `LTE` it is possible to write a proposition,
such as,
"zero is less than or equal to every natural number".

> nonNegative : (n : Nat) -> LTE Z n

The proposition is written as a function that takes a number as input.
The _value_ that is given is assigned to the variable `n`,
which is used to specify the return type.
Thus the return type of `nonNegative` *depends* on the input value.
Wherever you see `(a : A)` it can be read as,
"Some value of type `A` will be given here,
and that value will be assigned to the variable `a`."

To write an implementation for `nonNegative`,
it is necessary to produce a value of the appropriate `LTE` type
without any information about what input might be given -
other than the fact that it will be a natural number.
Totality checking is enabled,
so any implementation must be applicable to every possible input.
Thus a type of the form,
`(x : A) -> P x` describes universal quantification over the type `A`.

`nonNegative` happens to be a restatement of the axiom, `lteZero`.
So an implementation / proof is trivial:

> nonNegative n = lteZero

On the other hand, `lteSucc` maps a given proof to a proof of a related proposition.
It is used in proofs-by-induction.
For example, a proof that every number is less than or equal to itself:

> lteReflexive : (n : Nat) -> LTE n n
> lteReflexive Z     = lteZero
> lteReflexive (S n) = lteSucc (lteReflexive n)

The proof that zero is equal to itself is given by the axiom.
For every other number, the proof is given as an inductive step
using a proof for the next-smallest number.

Because the type of `lteSucc` is that of a function,
it can be read as a proposition involving logical implication:
"n <= m implies that n + 1 <= m + 1."
In general, types of the form
`P x -> Q y`
can be read as logical implication.

We have seen that the input value to a function can be labelled and referenced
in the output type.
That is a special property of functions.
For example, it is not permissible to label the value in the first position of
a tuple type to reference it in the second position.
But there is a special construction, the dependent pair, which does allow this.
Dependent pairs are used to represent existential quantification.

A dependent pair type of the form
`(x : A ** P x)`
is read as existential quantification over the type `A`.

A proof of a proposition with existential quantification can be given as
a pair of an arbitrary value and a proof that the proposition holds for that value.
For example, here is a proof of the Archimedean Property of natural numbers,
"For every natural number, n, there exists a natural number, m, where m > n":

> archimedean : (n : Nat) -> (m : Nat ** LTE (S n) m)
> archimedean n = (S n ** lteReflexive (S n))

The quantified proposition uses `(S n)` instead of just `n`
to indicate that `m` must be strictly greater than `n` -
greater-than-or-equal-to is not sufficient.
The proof supplies `S n` as a *witness* -
a specific value that is used to prove that the quantified proposition holds.
Remember that `S n` is just another way of writing `n + 1`.
The second component of the dependent pair value must be a proof that the witness
is greater than or equal to `S n` - as is required by the type.
Since `S n` and `S n` are equal, `lteReflexive` suffices.


## Definition of Category

I have been studying Category Theory;
so I decided to use that as a topic for exercises when learning about Idris.
If you are wondering what Category Theory is all about,
take a look at [Why Category Theory Matters][].

[Why Category Theory Matters]: http://rs.io/2014/04/30/why-category-theory-matters.html

There is [a much more complete description][copumpkin]
of Category Theory concepts written in Agda.
The definition below was an exercise for me in learning about
Category Theory concepts myself.

[copumpkin]: https://github.com/copumpkin/categories

A category is a set of objects
combined with a set of arrows that encode relations between objects.
When talking about all possible categories,
the concepts of "object" and "arrow" are very abstract.
They could be pretty much anything.
Descriptions of specific categories make specific statements
about what objects are and what arrows are.

Let's implement a type class to capture this definition.

> class Category obj (arr : obj -> obj -> Type) where

Arrows are indexed by objects.
That is, the type of an arrow carries its domain
(the object that an arrow originates from)
and its codomain
(the object that an arrow points to).
Note that `obj` is given as an unqualified variable.
In some categories objects will be types - as in the Set category.
In others they will be plain values.

The methods of this type class will define the category laws.
For starters, there must be an id arrow for every object.
This line specifies that an instance of this type class must provide
a `cId` implementation with the given type:

>   cId   : (a : obj) -> arr a a

As was shown above,
a function type serves as a proposition with universal quantification.
So the type of `cId` states that every object must be both the domain
and codomain of at least one arrow.
The implementation will also provide a means to identify that arrow.

Arrows must be composable.
If one arrow points from objects `a` to `b`,
and another arrow points from 'b' to 'c',
then it must be possible to combine them
to produce an arrow from 'a' to 'c'.

>   cComp : {a, b, c : obj} -> arr b c -> arr a b -> arr a c

Arguments in curly braces are implicit parameters.
In most cases the compiler will infer those values.
So they are generally not given as explicit arguments when invoking the function.
However, it is possible to provide implicit parameters explicitly when needed.

`cId` and `cComp` are the only required functions that actually produce arrows.
But it is necessary to provide more specific rules about how they should behave.

``` idris
  cIdLeft  : {a, b : obj} -> (f : arr a b) -> cId b `cComp` f     = f
  cIdRight : {a, b : obj} -> (f : arr a b) ->     f `cComp` cId a = f
```

These propositions state that id arrows must not only have the same
object as domain and codomain -
they must also be identities under composition.
Implementations of `cIdLeft` and `cIdRight` will never be used at runtime -
they are just proofs that `cId` and `cComp` obey the category laws.

Here `(=)` is a type constructor, very much like `LTE`.
Its definition looks like this:

``` idris
data (=) : a -> b -> Type where
  refl : x = x
```

The parameters to `(=)` can be any expressions -
including plain values or types.
`refl` is another axiom, stating that equality is reflexive.
Basically, to prove that two expressions are equivalent
it is necessary to demonstrate to the type checker that
they have the same normal form.

This implies that there might be multiple arrows pointing between the same two objects;
and that those arrows are not necessarily equivalent.
When talking about all possible categories,
it is not possible to say what it is that makes arrows different or the same.
Rather, any specific category must have its own definition of equality of arrows.
Some categories will have many arrows between each pair of objects;
some will have at most one.

One more proof is required to complete the `Category` type class.
Arrow composition must be associative.

``` idris
  cCompAssociative : (f : arr a b) -> (g : arr b c) -> (h : arr c d) ->
                     h `cComp` (g `cComp` f) = (h `cComp` g) `cComp` f
```

I have cheated slightly.
In the types for `cIdLeft`, `cIdRight`, and `cCompAssociative`
I left the implicit arguments to `cComp` implicit.
But I was not able to get those definitions to type-check.
I actually had to list out the implicit parameters
when applying `cComp` in a type expression.
The working definitions are a bit more difficult to read:

>   cIdLeft  : {a, b : obj} -> (f : arr a b) -> cComp {a=a} {b=b} {c=b} (cId b) f = f
>   cIdRight : {a, b : obj} -> (f : arr a b) -> cComp {a=a} {b=a} {c=b} f (cId a) = f
>
>   cCompAssociative : (f : arr a b) -> (g : arr b c) -> (h : arr c d) ->
>                      cComp {a=a} {b=c} {c=d} h (cComp {a=a} {b=b} {c=c} g f) =
>                        cComp {a=a} {b=b} {c=d} (cComp {a=b} {b=c} {c=d} h g) f

It has been pointed out to me that the compiler is not able to determine
which implementation of `cidLeft`, `cIdRight`, or `cCompAssociative` should be invoked,
unless the implicit parameters are listed.
If Category were implemented as a record type instead of as a type class
this would probably not be necessary.


## A partial ordering category

With the definition of Category in place,
it is possible to describe specific categories -
and to prove that they obey the category laws.

The `LTE` type constructor can be used to
describe a category where arrows are `LTE` relations,
and objects are natural numbers.
In this category,
there are arrows that point from each number
to every other number that is larger,
and also back to the number itself.

> instance Category Nat LTE where
>   cId Z     = lteZero
>   cId (S n) = lteSucc (cId n)

An id arrow in this category is a proof that a number is less than or equal to itself.
This is the same thing that was proved by `lteReflexive`;
so the implementation is the same.

Arrow composition is a proof that the less-than-or-equal-to relation is transitive.
For reference, here is the type for `cComp` specialized for `LTE`:

``` idris
  cComp : {a, b, c : Nat} -> LTE b c -> LTE a b -> LTE a c
```

And the proof construction:

>   cComp _ lteZero = lteZero
>   cComp (lteSucc f) (lteSucc g) = lteSucc (cComp f g)

In the first equation, the second input is `lteZero`;
which implies that `a` is zero.
`a` is also the domain in the `LTE` result that we want to prove;
so the proof is trivial.
The second equation takes advantage of the fact that the `lteSucc`
constructors of input arrows can be recursively unwrapped,
until reaching the base case, where the second input is `lteZero`.

There is no pattern for a case where the first input is `lteZero`
where the second is not.
It is not required, because that case is not allowed by the type of `cComp` -
and the type checker is able to confirm that.
If it were necessary to make explicit that this case is not possible,
that could be stated with a third equation:

``` idris
  cComp lteZero (lteSucc g) impossible
```

The keyword `impossible` is one tool available for proofs of falsehood.

Now to prove the remaining category laws.

>   cIdLeft lteZero     = refl
>   cIdLeft (lteSucc f) = cong (cIdLeft f)
>
>   cIdRight lteZero     = refl
>   cIdRight (lteSucc f) = cong (cIdRight f)

Demonstrating identity under composition of proofs is a little strange.
What we need to show is that composing an identity arrow with any other arrow
does not introduce new information.

In the base case of `cIdLeft`, if the given arrow, `f`, is `lteZero`
then its domain must be zero.
Therefore the identity arrow it is composed with must also be `lteZero`.
Those are the same normal form,
so the proof invokes `refl` - the axiom of reflexivity of equality.

The inductive step applies `cong`,
which is a proof of congruence of equal expressions.
It is defined in the standard library:

``` idris
cong : {f : t -> u} -> (a = b) -> f a = f b
cong refl = refl
```

In this case the `f` that `cong` infers as its implicit parameter is `lteSucc`.

`cong` is an example of a proof constructor:
it takes a proof as input and returns a proof of a related proposition.
Functions like `cong` are the building blocks of multi-step proofs.

You may notice that `cong` takes `refl` as an argument and returns it.
`cong` has equality proofs as its input and output.
By definition, the only possible value of an equality type is `refl`.

The base case of `cIdRight` is not as trivial as the base case of `cIdLeft`.
the codomain of `lteZero` is not necessarily zero;
so the identity arrow involved could be some `lteSucc` value.
However the compiler is able to do some normalization automatically.
That means that it is not necessary to spell out every step.

>   cCompAssociative lteZero _ _ = refl
>   cCompAssociative (lteSucc f') (lteSucc g') (lteSucc h') =
>     cong $ cCompAssociative f' g' h'

The proof of associativity follows a similar pattern.


## A monoid as a category

The natural numbers form a [monoid][] under addition.
In particular:

* Two numbers can be combined by addition to produce a third number.
* There is an additive identity (0).
* Addition is associative.

[monoid]: http://en.wikipedia.org/wiki/Monoid

The monoid also forms a category with just one object,
(which will be arbitrarily represented with `()`)
where the arrows are integers,
and arrows are composed by addition.
Since there are an unbounded number of natural numbers,
in this category
there are an unbounded number of arrows pointing from `()` back to `()`.

This category is made a bit complicated by the requirement that
arrows are indexed by domain and codomain.
Those indexes will not be meaningful in a category with just one object.
But for the sake of generality,
a trivial higher-kinded wrapper around `Nat` is needed.

> data NatArrow : () -> () -> Type where
>   getNat : Nat -> NatArrow () ()

In Idris, as in Haskell,
`()` is a type with exactly one value,
which is also called `()`.

To make it clear that a `NatArrow` is really just a `Nat`,
we can prove that the two types are isomorphic.

> isoNatNatArrow : Iso Nat (NatArrow () ())
> isoNatNatArrow = MkIso to from toFrom fromTo where
>   to : Nat -> NatArrow () ()
>   to = getNat
>
>   from : NatArrow () () -> Nat
>   from (getNat n) = n
>
>   toFrom : (y : NatArrow () ()) -> to (from y) = y
>   toFrom (getNat y) = refl
>
>   fromTo : (x : Nat) -> from (to x) = x
>   fromTo x = refl

An isomorphism is a bidirectional mapping that preserves information in both directions.
`to` and `from` specify the mapping;
`toFrom` and `fromTo` prove that information is preserved.

Now the definition of the Nat category:

> instance Category () NatArrow where
>   cId () = getNat 0
>   cComp (getNat f) (getNat g) = getNat (f + g)
>
>   cIdLeft  (getNat f) = cong (plusZeroLeftNeutral  f)
>   cIdRight (getNat f) = cong (plusZeroRightNeutral f)
>   cCompAssociative (getNat f) (getNat g) (getNat h) =
>     cong (plusAssociative h g f)

This implementation uses `(+)` for arrow composition.
It reuses proofs of identity and associativity for `(+)`.
It is only necessary to apply `cong` to the predefined proofs
to show that applying the `getNat` constructor to both sides of an equality
does not change anything.

For another look at monoids in Idris,
see [Verifying the monoid laws using Idris (video)][monoid laws].

[monoid laws]: https://www.youtube.com/watch?v=P82dqVrS8ik


## Category of sets

In the Set category, objects are sets and arrows are functions.
The implementation here will use `Type` as the type of objects.
In Idris, the type of every *small type* is `Type`.
For example, the type of `Nat` is `Type`.
The type of `String` is also `Type`.
The type of `Type` is `Type 1` -
meaning that `Type` is not a small type itself.

The definition of `Category` requires proofs of equivalence for arrows.
But there is no predefined comparison operator for functions in Idris.
All that you can really do with a function is to give it some inputs,
and check what its outputs are.

To produce a viable category, it is necessary to introduce
the axiom of *function extensionality*:

> funext : (f, g : a -> b) -> ((x : a) -> f x = g x) -> f = g

If two functions produce the same output for all possible inputs,
then they are equivalent.

`funext` takes as input two functions
and a proof that those functions produce the same output for all inputs.
Note the parentheses in that type:
As function types serve as universal quantifiers,
higher-order functions provide a means to nest quantification
inside of larger propositions.

I am told that it is not possible to prove `funext` in Idris -
and that that limitation is not unique to Idris.
Therefore, function extensionality must be given as an axiom:

> funext f g = believe_me

`believe_me` is a "proof" to use sparingly.

Implementations for an identity function and for composition of functions
are provided in the standard library.
In fact, Idris includes a `Control.Category` module
with a predefined `Category` type class.
But that definition does not include all of the category laws.
What remains to be defined are proofs of identity and associativity.

> leftIdPoint : (f : a -> b) -> (x : a) -> id (f x) = f x
> leftIdPoint f x = refl
>
> rightIdPoint : (f : a -> b) -> (x : a) -> f (id x) = f x
> rightIdPoint f x = refl

Proving that `id (f x)` and `f (id x)` reduce to `f x`
is sufficiently easy that the compiler can do most of the work on its own.
To make the next step to `f x = f x -> f = f`
is just a matter of applying `funext`.

> leftId : (f : a -> b) -> id . f = f
> leftId f = funext (id . f) f $ leftIdPoint f
>
> rightId : (f : a -> b) -> f . id = f
> rightId f = funext (f . id) f $ rightIdPoint f

In order to prove associativity, it is helpful to have a helper proof
that could be described as, "pointful composition".

> compPoint : (f : b -> c) -> (g : a -> b) -> (x : a) -> f (g x) = (f . g) x
> compPoint f g x = refl

The proof of associativity is a bit complicated.
So it is broken into steps here,
with proven intermediate propositions given for each step.

> compAssociative : (f : a -> b) -> (g : b -> c) -> (h : c -> d) ->
>                   h . (g . f) = (h . g) . f
> compAssociative f g h = qed where
>   step_1   : (x : _) -> h ((g . f) x) = (h . (g . f)) x
>   step_1   = compPoint h (g . f)
>
>   step_2   : (x : _) -> (h . (g . f)) x = h ((g . f) x)
>   step_2 x = sym (step_1 x)
>
>   step_3   : (x : _) -> (h . g) (f x) = ((h . g) . f) x
>   step_3   = compPoint (h . g) f
>
>   step_4   : (x : _) -> (h . (g . f)) x = ((h . g) . f) x
>   step_4 x = trans (step_2 x) (step_3 x)
>
>   qed      : h . (g . f) = (h . g) . f
>   qed      = funext (h . (g . f)) ((h . g) . f) step_4

There are two standard library functions used here that have not been introduced yet.
They are:

``` idris
sym : {l:a} -> {r:a} -> l = r -> r = l
sym refl = refl

trans : {a:x} -> {b:y} -> {c:z} -> a = b -> b = c -> a = c
trans refl refl = refl
```

When a free, lowercase variable appears in a type expression,
Idris inserts an additional implicit parameter at the beginning of the expression.
It is up to the compiler to infer the types of the free variables.
After carrying out that expansion, the type of `trans` looks like this:

``` idris
trans : {x, y, z : _} -> {a:x} -> {b:y} -> {c:z} -> a = b -> b = c -> a = c
```

There may be more steps listed in `compAssociative` than are really required.
Hopefully including them helps to clarify the proof.

In Haskell, `(->)` is an ordinary type constructor that could be used
as the arrow type in a type class like `Category`.
It seems that is not the case in Idris.
To work around that, the standard library includes a type, `Morphism`,
that is isomorphic to the function type.

``` idris
data Morphism : Type -> Type -> Type where
  Mor : (a -> b) -> Morphism a b
```

The proofs above provide everything that is required to prove the validity of
a category of Types and functions.
But the definition here uses Morphism for arrows;
so a little extra translating is necessary.

> mComp : (b ~> c) -> (a ~> b) -> (a ~> c)
> mComp (Mor f) (Mor g) = Mor (f . g)

The operator `(~>)` is an infix alias for `Morphism`.

> instance Category Type Morphism where
>   cId = Mor id
>   cComp = mComp
>
>   cIdLeft (Mor f) = qed where
>     step_1 : id . f = f
>     step_1 = leftId f
>
>     qed : Mor (id . f) = Mor f
>     qed = cong step_1
>
>   cIdRight (Mor f) = cong (rightId f)
>   cCompAssociative (Mor f) (Mor g) (Mor h) = cong $ compAssociative f g h

As with `Nat` and `NatArrow`,
the correspondence between `(->)` and `Morphism` is made official
with a proof of isomorphism.

> isoMorphismFunction : Iso (Morphism a b) (a -> b)
> isoMorphismFunction = MkIso to from toFrom fromTo where
>   to : (a ~> b) -> (a -> b)
>   to (Mor f) = f
>
>   from : (a -> b) -> (a ~> b)
>   from = Mor
>
>   toFrom : (y : a -> b) -> to (from y) = y
>   toFrom y = refl
>
>   fromTo : (x : a ~> b) -> from (to x) = x
>   fromTo (Mor x) = refl

It is my hope that I can use these definitions to work out exercises
as I continue to explore Category theory.
</div>


  <footer>
    <p class="meta">
      
  

<span class="byline author vcard">Posted by <span class="fn">Jesse Hallett</span></span>

      








  


<time datetime="2014-05-04T00:00:00-07:00" pubdate data-updated="true">2014-05-04</time>
      


    </p>
    
      <div class="sharing">
  
  
  
</div>

    
    <p class="meta">
      
      
    </p>
  </footer>
</article>

  <section>
    <h1>Comments</h1>
    <div id="disqus_thread" aria-live="polite"><noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
</div>
  </section>

</div>

<aside class="sidebar">
  
    <section>
  <h1>Recent Posts</h1>
  <ul id="recent_posts">
    
      <li class="post">
        <a href="/2017/01/03/flow-cookbook-react.html">Flow Cookbook: Flow & React</a>
      </li>
    
      <li class="post">
        <a href="/2016/12/20/flow-cookbook-unpacking-json.html">Flow Cookbook: Unpacking JSON API data</a>
      </li>
    
      <li class="post">
        <a href="/2016/12/20/flow-cookbook.html">Flow Cookbook</a>
      </li>
    
      <li class="post">
        <a href="/2015/05/31/type-checking-react-with-flow.html">Type checking React with Flow v0.11</a>
      </li>
    
      <li class="post">
        <a href="/2015/05/31/advanced-features-in-flow.html">Advanced features in Flow</a>
      </li>
    
  </ul>
</section>
<section>
  <h1>Talks</h1>
  <ul id="talks">
    <li><a href="http://opensourcebridge.org/sessions/1067">Mod your Android</a></li>
    <li><a href="talks/intro-to-javascript/">Introduction to JavaScript</a></li>
    <li><a href="http://lanyrd.com/2012/nodepdx/smyqm/">Object-oriented patterns in JavaScript</a></li>
    <li><a href="talks/cookies/">Cookies are bad for you</a></li>
    <li><a href="talks/professional-javascript/">Professional JavaScript</a></li>
    <li><a href="http://opensourcebridge.org/2009/wiki/Clustering_Data_--_How_to_Have_Fun_in_n-Dimensions">Cluster Analysis: How to Have Fun in n Dimensions</a></li>
    <li><a href="https://docs.google.com/presentation/d/1hx9Pzo07aAnZ2skMH4JPjH7a6IXx64uC0zRliS3qpkk/edit?usp=sharing">How to build blazing fast web apps with Ruby on Rails</a></li>
  </ul>
</section>
<section>
  <h1>Open Source Projects</h1>
  <ul id="projects">
    <li><a href="http://github.com/jivesoftware/tAMD">tAMD:</a> Tiny, extensible implementation of the Asynchronous Module Definition (AMD) specification from CommonJS</li>
  </ul>
</section>
<section>
  <div class="contact" style="float:left; margin:0.5em;">
    <p>
      Jesse Hallett<br/>
      <a href="mailto:jesse@sitr.us">jesse@sitr.us</a>
    </p>
  </div>
  <div class="contact" style="float:left; margin:0.5em;">
    <p>
      <a rel="me" href="https://github.com/hallettj/">github.com/hallettj</a><br />
      <a rel="me" href="https://twitter.com/hallettj/">twitter.com/hallettj</a>
    </p>
  </div>
</section>

  
</aside>


    </div>
  </div>
  <footer role="contentinfo"><p>
  Copyright &copy; 2017 - Jesse Hallett -
  <span class="credit">Powered by <a href="http://octopress.org">Octopress</a></span>
</p>

</footer>
  

<script type="text/javascript">
      var disqus_shortname = 'hallettj';
      
        
        // var disqus_developer = 1;
        var disqus_identifier = 'http://sitr.us/Cat.lidr';
        var disqus_url = 'http://sitr.us/Cat.lidr';
        var disqus_script = 'embed.js';
      
    (function () {
      var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
      dsq.src = '//' + disqus_shortname + '.disqus.com/' + disqus_script;
      (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
    }());
</script>











</body>
</html>
