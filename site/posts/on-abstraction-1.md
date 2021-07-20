---
title: "On Abstraction: What is Abstraction?"
author: Jonathan Lorimer
date: 18/07/2021
datePretty: Jul 18, 2021
description: "What is abstraction?"
tags: [abstraction]
---

# Table of Contents

## Introduction

This blog series started out as a simple question "What are the tradeoffs
between GADTs and Typeclasses?". Specifically I was interested in an
implementation of an API client, the goal was to connect the request type and
the response type. The existing implementation used a typeclass with an
associated type so that each instance would declare the correct types, and then
those were used throughout in the method signatures. I wondered what the merits of
a GADT representation would be, I figured that the request type could be
associated with a constructor and the response type could be "discovered" by
pattern matching on the constructor and using the implicit equality constraint.
My intuition was that the tradeoff between the typeclass and GADT encoding was
related to the expression problem, and this was partially true. It quickly
became apparent that the fundamental distinction was actually data and codata,
and perhaps deeper than that was the more conceptual distinction of concrete
implementations and abstract encodings. So my initial investigation broke down
into three related subjects, in the order that I came across them:

1. What are the tradeoffs between data and codata?
2. How does one encode data and codata in Haskell?
3. What is abstraction?

Arranging these three areas of consideration into a coherent blog post was
incredibly challenging. These questions are extremely slippery due to the fact
that we can mechanically convert between data and codata; one can represent a
type constructed out of data using codata and vice versa. Another confounding
factor is that each question seems to depend on the other two. By now you might
have noticed that the third question seems to be separate from the other two.
This is a fair observation, the third question depends on the assumption that
there is a fundamental connection between codata and abstraction and data and
concrete implementation. Therefore, the third question can be restated as:
Assuming a deep connection between codata and abstraction, what is abstraction
in contrast to data and a concrete implementation? What is abstraction is bit
more terse. Given the difficulty of arranging these posts I have decided to
order them in an opinionated way:

1. What is abstraction?
2. What are the tradeoffs between data and codata?
3. How does one encode data and codata in Haskell?

The thought process behind this ordering is that abstraction is fundamental to
understanding codata, which I found rather tricky to pin down. Then
understanding when to use data and codata motivates the implementation. The rest
of this blog post will deal with the first question.

## How does one define abstraction?

```
"The purpose of abstraction is not to be vague but to create a new semantic level
in which one can be absolutely precise." - Edsgar Dijkstra
```

Okay, thanks eddy, we can all go home now. All kidding aside, this is obviously
an insightful quotation and much smarter people than I frequently point to it.
Unfortunately I have always found it rather unsatisfying. Perhaps because it is
itself, abstract and vague. What doesn't sit well with me is that it seems to
provide a teleological definition (its purpose) of abstraction rather than an
ontological one (what it is in relation to other things). I will try and provide
several different definitions of abstraction that might help you triangulate
what exactly it means.

### Rationalist perspective: mathematics

Abstraction is information hiding, OOP abstracts the wrong thing (mutation
and sharing) - Bartosz Milewksi Category Theory 1.1 8:15
We want to get rid of unnecessary details - Bartosz Milewksi Category Theory 1.2 2:00
Abstraction provides new equalities - Bartosz Milewksi Category Theory 1.2 3:00

### Empiricists perspective: examples in everyday programming

### A type theorists perspective: existentials




