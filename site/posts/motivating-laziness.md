---
title: "Intro to FP Through λ-Calc Part 1. - Motivating Laziness"
author: Jonathan Lorimer
date: 31/08/2020
datePretty: Mar 19, 2020
description: "Introduction to Functional Programming Through Lambda Calculus gave a thorough explanation of evaluation in lambda calculus, I found this helped motivate a better understanding of evaluation in haskell!"
tags: [lambda-calculus]
---

# Table of Contents

- [Introduction](#introduction)
    - [Attribution](#attribution)
- [Terminology & Termination](#terminology--termination)
    - [Normal Form](#normal-form)
    - [Intermediate Normal Forms](#intermediate-normal-forms)
    - [Reduction Orders](#reduction-orders)
    - [Section Summary](#section-summary)
    - [Important Definitions](#important-definitions)
- [A Lazy Solution](#a-lazy-solution)
    - [Thunks](#thunks)
    - [Lazy Evaluation](#lazy-evaluation)
- [References](#references)

# Introduction

This is the first  in a series of blog posts I am writing, about a book by Greg Michaelson called _An Introduction to Functional Programming Through Lambda Calculus_ (referred to as 'The Book' throughout). Prior to reading this book, I already had a cursory understanding of the lambda calculus, but I wanted to solidify my understanding as well as find connections to my primary area of interest; coding in Haskell. The format of these posts won't be a review of the book, but rather an exposition of the three observations I found most interesting. This particular post looks at evaluation order. Before reading the book I found evaluation order an impenetrable subject, it reminded me of order of operations from grade school math, and most explanations I came across were crucially missing the _why_. I suppose evaluation order is a low-level, procedural mechanism, and those who study it usually approach it as an application of the theory they already understand. I am coming at this subject from the opposite direction, I am an end-user of Haskell with no computer science background, so evaluation order is the first layer of theory beneath the surface of Haskell’s pleasant high level syntax. I hope that a short overview of evaluation order can help us understand why laziness is such a natural choice for Haskell; a language built on top of the lambda calculus.

> N.B. this post assumes basic familiarity with the syntax of lambda calculus [this is not a bad starting point](https://personal.utdallas.edu/~gupta/courses/apl/lambda.pdf)

## Attribution

The majority of the content that I reference from the book occurs in Chapter 8, between pages 187 and 205 (Michaelson 2011). I will explicitly cite any direct quotations, or references that occur outside of these pages, but pretty much all of the contents of this blogpost comes from Michaelson; to avoid tedious repetition of the citation I am directing you to Chapter 8 now.

# Terminology & Termination

## Normal Form

**Normal form** is the description of a λ-expression which cannot be β-reduced any further. This means that all external and internal function applications are reduced
```haskell

1. (λx.y.z.xy) (λa.a) (λb.c.b) =>
2. (λy.z.(λa.a) y) (λb.c.b) =>
3. λz.(λa.a)(λb.c.b) =>
4. λz.b.c.b

```

lines 1-3, in this first example, represent the reduction of external function applications, while line 4 represents the result of an internal function application, because the reduction occurs inside the function body. The reduction of internal applications is important because some expressions that would reduce to the same normal form appear different when internal applications are not reduced. For example, in the code block below, at line 2 the λ-expression looks different from the λ-expression at line 3 from before, however it is clear at the end of reduction that both λ-expressions are the same.

```haskell

1. (λy.z.b.yb) (λx.c.x) =>
2. λz.b.(λx.c.x)b =>
3. λz.b.c.b

```
This raises an important point, by the Church-Rosser theorem, all normal forms are unique. Different λ-expressions may converge on normal forms. The Church-Rosser theorem says that if λ-expression `A` can be λ-converted (or λ-abstracted) to `B` (i.e. replace a concrete value with a bound variable through λ-abstraction and then apply that function to the concrete value) then both `A` and `B` reduce to normal form `C` (Turner 2004:189). Below is an example of λ-abstraction, given the name “abstraction” because we are abstracting out the variable `c` and thus converting a more normalized expression to one with an additional lambda.

```haskell

1. λa.x.x(λb.b) => λ-abstraction
2. (λc.a.x.xc)(λb.b)

```
A term is said to be **Normalizing** when it has a normal form but has not yet been reduced to normal form. Normal form is important in lambda calculus because it is effectively how computation is carried out, the reduction of a normalizing term shares a parallel with elimination rules in formal logic, or the evaluation of an arithmetic phrase.


## Intermediate Normal Forms

There are two intermediate normal forms. The first is **Weak Head Normal Form** (WHNF), this is a λ-expression whose body contains a other λ-expressions that can be applied further (an unevaluated function application is formally referred to as a **Redex**). Line 1 in the following example is _NOT_ in WHNF because the leftmost outermost λ-expression is itself a **Redex**, but once the last external function application has been applied (line 3) the expression is in WHNF. A good indication that you are at least in WHNF (using the syntax that I have chosen) is that there are no brackets around the leftmost λ-abstraction. This indicates that there are no external **Redexes**, and all that is left to evaluate is the function body, where a function body is defined as such `λ<bound-variable>.<function-body>`. The next reduction (line 4) happens "under the lambda" in the function body, and now we are in our second intermediate normal form: **Head Normal Form** (HNF). The definition of HNF is that there are no remaining external _OR_ internal redexes, in line 4 `y((λz.z)((λa.a)(λb.b)))` is not considered a redex because the bound variable y is preventing β-reduction. We can, however, continue evaluting the argument expression. For reference, line 4 the bound variable `y` is the function expression, and `((λz.z)((λa.a)(λb.b)))` is the argument expression. We evaluate the argument expression in lines 4 through 6, until we reach **Normal Form**(NF), at which point every λ-expression that can be evaluated has been evaluated. As a re-cap: line 1 and 2 is an external redex and therefore not in any intermediate normal form. Line 3 is the only line that is in WHNF but not in HNF, line 4 and 5 are in HNF but not NF, and line 6 is in NF (it is also technically in HNF and WHNF).To put it more succinctly: WHNF is a superset of HNF, which is a superset of NF.

```haskell

1. (λv.x.y.(xy)(xv))((λa.a)(λb.b))(λz.z) =>
2. (λv.x.y.(xy)(x((λa.a))))(λz.z) =>
3. λy.((λz.z)y)((λz.z)((λa.a)(λb.b))) =>
4. λy.y((λz.z)((λa.a)(λb.b))) =>
5. λy.y((λa.a)(λb.b)) =>
6. λy.y(λb.b)

```
## Reduction Orders

From here, things get slightly more complicated, but also more interesting. **Normal Order** (NO) reduction evaluates the leftmost redex by passing the argument _unevaluated_, while **Applicative Order** (AO) evaluates that argument that is being passed. One can already imagine that AO evaluation is more efficient (in the sense of fewer reduction steps); rather than passing around unevaluated lambda terms, why not evaluate them once and then substitute them in a more reduced form? AO evaluation also has a drawback of eagerly reducing a λ-expression, what if this expression is unused? Or worse, what if it never terminates? To summarize the distinction between the two evaluation orders, NO reduction has the benefit of terminating more frequently than AO evaluation, but at the cost of a potentially more expensive reduction process. To clarify, all λ-expressions that terminate upon AO reduction will also terminate upon NO reduction, but not necessarily the other way around. Below are two examples of the differences between AO and NO reduction, the first highlights the inefficiency of NO, while the second illustrates non-termination of AO.

```haskell

-- Inefficiency of Normal Order Reduction

-- Normal Order Reduction
1. (λx.xx)((λa.b.c.c)(λs.s)(λt.t)) =>
2. ((λa.b.c.c)(λs.s)(λt.t))((λa.b.c.c)(λs.s)(λt.t)) =>
3. ((λb.c.c)(λt.t))((λa.b.c.c)(λs.s)(λt.t)) =>
4. (λc.c)((λa.b.c.c)(λs.s)(λt.t)) =>
5. (λc.c)((λb.c.c)(λt.t)) =>
6. (λc.c)(λc.c) =>
7. λc.c
------------------------------------------------------
-- Applicative Order Reduction
1. (λx.xx)((λa.b.c.c)(λs.s)(λt.t)) =>
2. (λx.xx)((λb.c.c)(λt.t)) =>
3. (λx.xx)(λc.c) =>
4. (λc.c)(λc.c) =>
5. λc.c

```

```haskell

-- Non-Termination of Applicative Order Reduction

-- Normal Order Reduction
1. (λf.(λs.f(s s))(λs.f(s s)))(λx.y.y) =>
2. (λs.(λx.y.y)(s s))(λs.(λx.y.y)(s s))) =>
3. (λx.y.y)((λs.(λx.y.y)(s s))(λs.(λx.y.y)(s s))) =>
4. (λy.y)
-----------------------------------------------------
-- Applicative Order Reduction
1. (λf.(λs.f(s s))(λs.f(s s)))(λx.y.y) =>

-- λx.y.y is already in NF, so we procede

2. (λs.(λx.y.y)(s s)) (λs.(λx.y.y)(s s)) =>

-- The argument λs.(λx.y.y)(s s) is in WHNF so we procede

3. (λx.y.y)
    ((λs.(λx.y.y)(s s)) (λs.(λx.y.y)(s s))) =>

-- Ahh! the argument (λs.(λx.y.y)(s s))(λs.(λx.y.y)(s s)) can be reduced

4. (λx.y.y)
    ((λx.y.y)
      ((λs.(λx.y.y)(s s)) (λs.(λx.y.y)(s s)))) =>
5. (λx.y.y)
    ((λx.y.y)
      ((λx.y.y)
        ((λs.(λx.y.y)(s s)) (λs.(λx.y.y)(s s))))) =>
6. (λx.y.y)
    ((λx.y.y)
      ...
        ((λs.(λx.y.y)(s s)) (λs.(λx.y.y)(s s)))))

```

The non-terminating example is a little bit complex, so let's dig in. There are two parts `(λf.(λs.f(s s))(λs.f(s s)))` and `(λx.y.y)`. The first λ-expression is a common combinator known as a fixpoint, it is a higher order function, that represents a general approach to recursion in the simply typed lambda calculus (basic self application `(λs.ss)λs.ss` doesn't typecheck). It is not important to understand the fixpoint combinator now, but what is important is to recognize that this kind of recursion is impossible in applicative order evaluation, because the generative self application is passed as an argument, and therefore evaluated immediately. Immediate evaluation causes us to apply our λ-expression to itself infinitely with no opportunity for the logic to fork to a base case. The second λ-expression (`λx.y.y`) was chosen trivially, because it terminates instantly; I didn't want to have to think too hard about a recursive example that terminates in normal order evaluation. However, this function could have been any function at all, and the applicative order evaluation would never terminate.

Another important feature of NO evaluation (which is delayed relative to AO evaluation) is that it allows for _codata_, otherwise known as infinite data structures. In the next section we will look at how one can achieve the benefits of both evaluation strategies, but first a summary of the terms we have looked at.

## Section Summary

  I mentioned in the introduction that I am interested in making the _why_ of the details (reduction forms and evaluation strategies) of lambda calculus apparent. Lambda calculus is a stunningly simple language, I think that there are 3 syntactic constructs in the whole language (λ-abstraction, application, and variables). Like many ideas in functional programming, lambda calculus is difficult to understand, not because it is complicated, but because it is so simple. The difficulty arises in the nuance and interpretation of the simple constructs. Therefore it is not λ-abstraction, application, or variables that are tricky, but it is how they work together. It is true that λ-expressions converge on a **Normal Form**, but the order in which we reduce λ-terms have divergent properties (**Normal Order** may take more steps to reduce, **Applicative Order** may not terminate where NO evaluation would), so now there is at least 1 important decision to make if we are to automate evaluation. Additionally, there are usually multiple steps in β-reduction, it is unclear at what point we are done each step, is it **Head Normal Form** or **Weak Head Normal Form**?
  In the abstract of _A Call-By-Need Lambda Calculus_ the authors note that: "The mismatch between the operational semantics of the lambda calculus and the actual behavior of implementations is a major obstacle for compiler writers" (Ariola et al 1995:233). A similar sentiment is noted in the introduction for _The Lazy Lambda Calculus_, after citing a "succesful definition" for lambda calculus predicated on **Head Normal Forms** the author identifies an inconsistency in several prominent implementations of lambda calculus as a programming language: "But do these languages as defined and implemented actually evaluate terms to head normal form? To the best of my knowledge, not a single one of them does so. Instead, they evaluate to weak head normal form" (Abramsky 2002:3). The main point that I am trying to demonstrate with these quotations is that the complexity of the lambda calculus lies in moving from the beautiful, simple, pure semantics to a sensible application. Therefore, a nuanced understanding of lambda calculus, and how it can serve as a foundation for a programming language, requires an understanding of evaluation strategies and the different intermediary normal forms.

## Important Definitions

**Normal Form**: A fully evaluated / reduced λ-expression. These are unique, by the Church-Rosser theorem!

**Head Normal Form**: A λ-expression that has all external and internal redexes evaluated, but is not fully evaluated. The only way to achieve a situation like this is to have a bound variable as the leftmost function expression in the body of a λ-expression, whose substitution is delaying evaluation of the entire function body i.e. `λy.y((λx.x)(λz.z))`

**Weak Head Normal Form**: A λ-expression that has been evaluated up to the last λ-abstraction, but whose function body is still unevaluated.

**Redex**: An unevaluated function application

**Normal Order**: Evaluation by substituting the unevaluated λ-expression for all the bound variables that share the same name as the argument

**Applicative Order**: Reduction by evaluating the λ-expression that the function is applied to, and then substituting the normalized form (could be normal form or head normal form) for all the bound variables that share the same name as the argument.

For those of you who are familiar with Haskell, [monoidmusician](https://github.com/monoidmusician) wrote out a tiny DSL and some predicates to help understand the definitions of normal forms and their distinctions:

```haskell

data LC = Abs LC | App LC LC | Var Int

isRedex :: LC -> Bool
isRedex (App (Abs f) a) = True
isRedex _               = False

isNF :: LC -> Bool
isNF t | isRedex t = False
isNF (Abs t)       = isNF t
isNF (App f a)     = isNF f && isNF a
isNF _             = True

isHNF :: LC -> Bool
isHNF t | isRedex t = False
isHNF (Abs t)       = isHNF t -- this is the difference between WHNF and HNF!
isHNF (App f a)     = isHNF f
isHNF _             = True

isWHNF :: LC -> Bool
isWHNF t | isRedex t = False
isWHNF (Abs t)       = True
isWHNF (App f a)     = isWHNF f
isWHNF _             = True

```

# A Lazy Solution

There are two solutions to the problem presented by the asymmetric benefits of the competing evaluation orders. The first is crude, but an existent pattern in most languages that support lambdas, it is a manually delayed evaluation using λ-abstraction; thunks. The second solution is more robust but requires built in language support, it is referred to as lazy evaluation.

## Thunks

A thunk is a method for delaying evaluation by wrapping an expression in an extra layer of λ-abstraction. Thunks require more than just changing the definition, the consumers of those thunked values need to change the way they handle data; the consumer must now explicitly evaluate the expressions. The simplest example of a thunk would be this:

```haskell

1. (λa.a)(λb.b)        -- This would be immediately evaluated
2. λdummy.(λa.a)(λb.b) -- the evaluation of the internal redex is deffered because we are in WHNF now

```

Let's see how this can help us avoid non-termination in the **Applicative Order** evaluation example used in the previous section. We should note two things here
1. I use the name `dummy` to indicate a thunk; basically I don't intend on ever using this variable
2. We are evaluating arguments up to WHNF, otherwise we would still need to evaluate the internal redex and regress into non-termination

```haskell

-- For reference this is the λ-expression before the use of thunks
-- (λf.(λs.f(s s))(λs.f(s s)))(λx.y.y)

1. (λf.(λs.f(λdummy.(s s))(λs.f(λdummy.(s s))))(λx.y.y) =>
2. (λs.(λx.y.y)(λdummy.(s s))(λs.(λx.y.y)(λdummy.(s s)))) =>
3. (λx.y.y)(λdummy.((λs.(λx.y.y)(λdummy.(s s)))(λs.(λx.y.y)(λdummy.(s s))))) =>
4. λy.y

```

Because the `λdummy` lambda abstraction is in the way, the argument to `λx.y.y` is not evaluated any further, and the entire λ-expression terminates. Let's look at a slightly different example to see how the function we pass to the higher-order recursive function `(λs.f(λdummy.(s s))(λs.f(λdummy.(s s))))` must now choose to explicitly evaluate the thunks. In the first example below I substitute `λx.y.y` for `λx.y.x` a λ-expression that does not terminate, even under **Normal Order** evaluation, when the recursive function is applied to it. However, with the extra layer of thunks, we safely reach a **Weak Head Normal Form**. This is because the function `λx.y.x` does not explicitly evaluate the recursive function. Below the dashed line we can see what happens when we use a function that explicitly evaluates the thunk, `λx.y.x <λ-expr>`, which applies the value `<λ-expr>` (a stand in for any λ-term) to the recursive function to keep it recursing.

```haskell

1. (λf.(λs.f(λdummy.(s s)))(λs.f(λdummy.(s s))))(λx.y.x) =>
2. (λs.(λx.y.x)(λdummy.(s s)))(λs.(λx.y.x)(λdummy.(s s))) =>
3. (λx.y.x)(λdummy.((λs.(λx.y.x)(λdummy.(s s)))(λs.(λx.y.x)(λdummy.(s s))))) =>
4. λy.(λdummy.((λs.(λx.y.x)(λdummy.(s s)))(λs.(λx.y.x)(λdummy.(s s))))) =>
-------------------------------------------------------------------------------------------------------

-- Instead of <λ-expr> I will use the identity function λz.z
1. (λf.(λs.f(λdummy.(s s)))(λs.f(λdummy.(s s))))(λx.y.x(λz.z)) =>
2. (λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s))) =>
3. (λx.y.x(λz.z))(λdummy.((λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s))))) =>

-- Now that we have the extra λz.z on the outside, evaluation can continue
4. λy.(λdummy.((λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s)))))(λz.z) =>
5. λy.((λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s)))) =>
6. λy.((λx.y.x(λz.z))(λdummy.((λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s)))))) =>
7. λy.(y.(λdummy.((λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s)))))(λz.z)) =>
8. λy.(y.((λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s))))) =>
...
n. λy.(y.(y.(λdummy.((λs.(λx.y.x(λz.z))(λdummy.(s s)))(λs.(λx.y.x(λz.z))(λdummy.(s s)))))(λz.z)))
...

```

We can see that the thunk style does not prevent non-termination generally, but allows us to evaluate some λ-expressions that would not normally terminate under **Applicative Order** evaluation. Lazy Evaluation accomplishes the same thing, but through and entirely different evaluation strategy.

## Lazy Evaluation

Lazy Evaluation only evaluates a λ-expression when it is in the function position ie. `<function position> <argument position>`. The crux of lazy evaluation is that it requires that we keep a reference to λ-expressions that have been substituted for the same bound variables, and then once one of those expressions is evaluated, that value is substituted for the rest. I will use the notation `1(λx.x)` to index λ-expressions, λ-expressions with the same index have been substituted under the same bound variable and can be replaced by a normal form once any instance has been evaluated.

```haskell

1. (λx.xx)((λa.b.c.c)(λs.s)(λt.t)) =>
2. (1(λa.b.c.c)(λs.s)(λt.t)1(λa.b.c.c)(λs.s)(λt.t)) =>
-- We evalute the λ-expression in function position

3. (1(λb.c.c)(λt.t)1(λa.b.c.c)(λs.s)(λt.t)) =>
4. (1(λc.c)1(λa.b.c.c)(λs.s)(λt.t)) =>
5. (1(λc.c)1(λa.b.c.c)(λs.s)(λt.t)) =>
-- Now that the first λ-expr is fully evaluated we substitute it for all
-- expressions with the same index

6. 1(λc.c)1(λc.c) =>
7. λc.c

```

Lazy evaluation has the benefit of terminating as frequently as **Normal Order** evaluation, but maintaining the efficiency of **Applicative Order** evaluation. I will defer to Ariola et al. for an explanation of how laziness provides the desirable properties of both NO and AO evaluation. "lazy languages only reduce an argument if the value of the corresponding formal parameter is needed for the evaluation of the procedure body"(Ariola et al 1995:233), this delayed evaluation is similar to NO, except that evaluation is delayed even further; rather than evaluating the entire λ-term only the expression in function position is evaluated. "after reducing the argument, the evaluator will remember the resulting value for future references to that formal parameter"(Ariola et al 1995:233) where AO ensures that bound variables are reduced only once by evaluating function arguments as they are substituted for named variables, lazy evaluation ensures that bound variables are only evaluated once by memoizing the result of evaluation and maintaining a reference from each λ-expression to the associated evaluated value. As mentioned in the section summary, the importance of evaluation order and intermediate normal forms is that they are necessary considerations for pragmatic implementations of programming languages predicated on the lambda calculus. The motivation for lazy evaluation follows logically from this consideration, as it is the 'best of both worlds'. However, it is not so straightforward, there is an unfortunate quirk with lazyness, namely that one "cannot use the calculus to reason about sharing in the evaluation of a program"(Ariola et al 1995:233). Ariola et al. provide a solution to this quirk in their paper _A Call-By-Need Lambda Calculus_, however that is beyond the scope of this post. I bring up the difficulty of formalizing laziness within lambda calculus to demonstrate how complicated the operationalization of these calculi can be. However, the foundational building blocks for reasoning about the operational semantics of the lambda calculus are intermediate normal forms, and evaluation strategies.

# References

1. Abramsky, Samson. “The Lazy Lambda Calculus.” Declarative Programming, March 1, 2002.
2. Ariola, Zena M., John Maraist, Martin Odersky, Matthias Felleisen, and Philip Wadler. “A Call-by-Need Lambda Calculus.” In Proceedings of the 22nd ACM SIGPLAN-SIGACT Symposium on Principles of Programming Languages, 233–246. POPL ’95. New York, NY, USA: Association for Computing Machinery, 1995. https://doi.org/10.1145/199448.199507.
3. Michaelson, Greg. An Introduction to Functional Programming Through Lambda Calculus. Courier Corporation, 2011.
4. Turner, David. “Church’s Thesis and Functional Programming.” JOURNAL OF UNIVERSAL COMPUTER SCIENCE 10 (2004): 187–209.

Thank you to Li-yao Xia for providing feedback, and to monoidmusician for discussing the distinction between Weak Head Normal Form and Head Normal Form with me.

If you would like to comment on this post, the comments section is [here](https://github.com/JonathanLorimer/personal-website-builder/issues/2)
