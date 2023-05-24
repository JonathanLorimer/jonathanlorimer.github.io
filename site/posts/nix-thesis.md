---
title: "The Nix Thesis"
author: Jonathan Lorimer
date: 2023/05/23
description: "I decided to read and summarise The Purely Functional Software Deployment Model by Eelco Dolstra"
tags: [nix]
---

# Table of Contents

- [Introduction](#introduction)
- [Correct Software Deployment](#correct-software-deployment)
    - [Correctness](#correctness)
    - [Software Deployment](#software-deployment)
    - [Bonus: Manageability & Usability](#bonus--manageability--usability)
- [Problems With Existing Solutions](#problems-with-existing-solutions)
- [Implementation Details](#implementation-details)
    - [Filesystem As Memory](#filesystem-as-memory)
    - [The Nix Store](#nix-store)
    - [Pure Functions](#nix-store)
- [Nix Principles](#nix-principles)
- [Topics Not Covered](#topics-not-covered)
- [Footnotes](#footnotes)

# Introduction

_The Purely Functional Software Deployment Model_[^1] by Eelco Dolstra (herein
referred to as "the thesis") is often pointed to as a great resource for
learning about nix, albeit technical and formal. A reasonable response to this
would be: Is a 20 year old, ~250 page thesis really the best way to understand
a software management tool? I set out to discover the answer to this question
myself and found that the thesis was very accessible, remarkably relevant given
its age, and that a significant portion of the content was philosophical rather
than technical. Therefore, my aspiration for this blog post is to crystalize
some of the insights from the thesis into short form content; it will either
satiate the reader's appetite for the topic, or inspire them to go on and
consume the full text.

# Correct Software Deployment

I'm going to start at the end of the thesis. Dolstra, summarizes in the
conclusion, that the purpose of the project was to achieve a system for correct
software deployment. He then goes on to explain that correctness is achieved
through two main vehicles. A precise naming scheme that leverages cryptographic
hashes to concisely summarize the software identified by said name. This naming
schema helps us achieve a much richer notion of equality than conventional
naming schema's (i.e. `openssl-3.0.8`). A "purely functional model" of software
deployment. What exactly is meant by "purely functional model" is slightly
unclear, but my understanding is that it boils down to immutable build
artefacts, pure build processes (depend only on their inputs) that admit no
side-effects, compositionality of software components.[^2] I think the purely
functional bit is particulary confusing because the nix expression language is
itself purely functional, but the real critical piece is the functional
principles applied to build and deployment strategies.

One ambiguity that might arise as a point of confusion is that there is a
distinction between the philosophical aspects of the thesis (i.e. an ontology
of software deployment, and what constitutes correct software deployment), and
the techniques / implementations that are guided by the theory. The
[Implementation Details](#implementation-details) will try to explain how
constructs (like the cryptographic naming scheme, and purely functional
deployment model) connect to the theory, albeit with less formality than the
original thesis. This section will look at the philosophy, and therefore will
focus on:

- What is meant by correctness?
- What does software deployment entail?
- What are some desirable qualities of a correct system?

I have separated out the "state of the art" section from the thesis, and mainly
drawn out the points of how existing solutions fall short, in the [Problems
With Existing Solutions](problems-with-existing-solutions) section. It seemed
logically distinct to me, but Dolstra does use it to explain what software
deployment is, and what some of the relevant problems in the space are.

## Correctness

The simplest way to describe correctness as laid out in the thesis (as it
pertains to software deployments) is through this formula `correctness =
complete + no interference`. Completeness refers to the presence of all
dependencies. The discussion around dependencies gets quite nuanced (i.e.
runtime vs buildtime dependencies, distinguishing dependencies across system
architectures or that are built slightly differently), but at its core this is
the completeness criteria. Interference refers to case where two different
deployments occupy the same namespace, and are therefore indistinguishable to
the software that depends on one of them.

> Note: The notion of equailty mentioned earlier is creeping back in. When we
> say "two different" we mean that there is some equivalence relation that does
> not hold, but the fact that they occupy the same namespace means there is
> _some_ nominal equivalence relationship that _does_ hold

There are plenty of examples of bipartite definitions of correctness that rhyme
with this one (soundness and completeness in logic), but I am going to steal
the imagery from a classic example in discrete mathematics; bijectivity. For
these images the circle on the left represents the set of software _components_
available to us, that other software deployments may depend on. The circle on
the right represents a software deployment, and the dots within the circle
represent dependency requirements. An arrow from left to right means that the
component on the left has been identified as corresponding to the dependency
requirement on the right.

> Terminology: In the thesis Dolstra refers to discrete units of software as
> components. These can be software that we are building, or software that has
> already been built, and these can be composed together through dependency
> relations

The diagram below represents the
![Example of a relation that is injective but not surjective](/images/Injective.svg){.md-image}
![Example of a relation that is surjective but not injective](/images/Surjective.svg){.md-image}
![Example of a relation that bijective](/images/Bijective.svg){.md-image}

## Software Deployment

## Bonus: Manageability & Usability

# Problems With Existing Solutions

# Implementation Details

## Filesystem As Memory

## Nix Store

## Pure Functions

# Nix Principles

# Topics Not Covered

# Footnotes
[^1]: Dolstra, E. “The Purely Functional Software Deployment Model,” 2006. https://books.google.ca/books?id=gP2kAAAACAAJ.
[^2]:
    "The main objective of the research described in this thesis was to develop a
    system for correct software deployment that ensures that the deployment is
    complete and does not cause interference. This objective was successfully met
    in the Nix deployment system, as the experience with Nixpkgs described...

    The objective of improving deployment correctness is reached through the two
    main ideas described in this thesis. The first is the use of cryptographic
    hashes in Nix store paths. It gives us isolation, automatic support for
    variability, and the ability to determine runtime dependencies. This however
    can be considered an (important) implementation detail—maybe even a "trick".
    However, it address the deployment problem at the most fundamental level: the
    storage of components in the file system.

    The second and more fundamental idea is the purely functional model, which
    means that components never change after they have been built and that their
    build processes only depend on their declared inputs. In conjunction with the
    hashing scheme, the purely functional model prevents interference between
    deployment actions, provides easy component and composition identification, and
    enables reproducibility of configurations both in source and binary form—in
    other words, it gives predictable, deterministic semantics to deployment
    actions." pg. 245
