---
title: "The Nix Thesis"
author: Jonathan Lorimer
date: 2023/05/26
description: "I read and summarised The Purely Functional Software Deployment Model by Eelco Dolstra"
tags: [nix]
---

# Table of Contents

- [Introduction](#introduction)
- [Correct Software Deployment](#correct-software-deployment)
    - [Correctness](#correctness)
    - [Software Deployment](#software-deployment)
    - [Bonus: Manageability & Usability](#bonus--manageability--usability)
- [Problems With Existing Solutions](#problems-with-existing-solutions)
- [The Benefits of Nix](#the-benefits-of-nix)
- [Implementation Details](#implementation-details)
    - [The Nix Store](#nix-store)
    - [Filesystem As Memory](#filesystem-as-memory)
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
that are named as inputs to a particular component of interest. The circle on
the right represents the set of dependencies that are actually required to
build the software component of interest. An arrow from left to right means
that the named component on the left has been identified as corresponding to the
dependency requirement on the right.

> Terminology: In the thesis Dolstra refers to discrete units of software as
> components. These can be software that we are building, or software that has
> already been built. These can be composed together through dependency
> relations. Put another way components can be inputs of other components.

The diagram below represents the a situation where the deployment admits no
interference; there are no "named components" on the left that could be
accidentally mixed up when provided to the build. In other words there is a 1:1
correspondence between the components we have identified and the ones that we
actually want. Non-interference is not enough, however. You probably noticed
that there is a required dependency on the right that is unfulfilled. This is
where completeness comes in; it entails that all required dependencies on the
right are provided and accounted for on the left.
![Example of a relation that is injective but not surjective](/images/Injective.svg){.md-image}

The next diagram represents the case where we have a complete deployment. Every
required dependency on the right is provided by at least one component on the
left. However, the catch here is that there is ambiguity, there are two
components that have both been identified as fulfilling a dependency
requirement, but by some notion of equality they are different (i.e. perhaps
they are the same software by name, at the same version, but one is compiled with a
threaded runtime and the other with a synchronous runtime). This is an example
of interference, there is no way to tell that we will get the input that we
_really_ mean.

To make the example more concrete: perhaps the purple dot on the left is
`openssl-3.0.8` and the orange dot is `openssl-1.1`, and the blue dot on the
right is just a requirement for `openssl`, and the arrows from the purple and
orange dot are a lookup on `$PATH` for `/usr/bin/openssl`. Well, since both
versions of `openssl` can live at that location, we aren't sure which we will
get, and therefore we might get a different component than the one that we
actually mean, the way that we identify components is too coarse grained.
![Example of a relation that is surjective but not injective](/images/Surjective.svg){.md-image}

This diagram demonstrates what is meant by correct deployment. There is exactly
one software component corresponding to every dependency requirement.
![Example of a relation that bijective](/images/Bijective.svg){.md-image}

> If you are familiar with functions from discrete mathematics, you probably
> noticed that I hand-waved away the existence of named inputs on the left that
> are not required dependencies on the right. If you are unsatisfied you can
> imagine a pruning function that eliminates superflous inputs from the
> environment that can be pre-composed with this function.

To re-iterate, `correctness = completeness + no intereference`:

- To ensure **completeness** we must guarantee that _at least one_ component is
  identified for every required dependency
- To ensure **non-interference** we must guarantee that there is _at most one_
  component identified for every required dependency, and that the component
  identified is the one that we really _mean_

## Software Deployment

Software deployment is the distribution of software; the acquisition,
installation, upgrading, and uninstallation process.[^3] There are two broad
classes of problems with software deployment: manageing the environment and
correctness as discussed in the previous section, and manageability / usability
as discussed in the next section.

While the previous section broke down the fundamental requirements for
correctness, it didn't really explain how correctness problems arise in
user environments. Here are some examples compiled from the thesis[^4]:

- Dependency identification, compatibility of the software provided with
  dependency requirements, and location on the system (finding the dependency)
- Implicit environment state: configuration files, an initialized database, system architectures.
- Distinguishing between buildtime and runtime dependencies.

These problems can be classed into two broader buckets: identification and
realization.[^5] I think that identification is more closely related to
correctness, in the sense that correctness starts from a correct plan for
deploying a software component. However, correct identification is inert
without realization, and correctness must be preserved throughout the
realization process.

## Bonus: Manageability & Usability

The reason that I consider this section a "bonus" is that, by the end of the
thesis, manageability isn't really mentioned. There are some nice aspects of
nix that aid user experience though. Manageability and usability are concerned
with the operations associated with software deployment. This effectively
amounts to software deployment experience. Here are some desiderata mentioned
in the thesis[^6]:

- Is uninstallation complete and sound: does it remove every artefact of the
  initial installation while not breaking other software deployments on the
  system?
- Upgrades should preserve correctness of the system (see DLL hell)
- Upgrade granularity (i.e. upgrade all machines in a network, only upgrade vim
  on my machine.
- Rolling back upgrades is desirable (requires some form of immutability)
- In order to effectively stay up to date with security upgrades one needs: to
  know what software is in use, whether updates are available, whether the
  update should be performed.
- Availability of source distribution vs binary distribution.
- Exposing software variability as configuration options to end users.

# Problems With Existing Solutions

In the thesis Dolstra does an analysis of several existing package management /
software deployment systems; low level tools like RPM, Source Deployment Models
like FreeBSD Ports and Gentoo, monolithic deployment models like Windows /
MacOS. Here is a compiled list of problems[^7]:

- Non-atomic upgrades / inability to rollback.
- Applications must be monolithic and statically contain all dependencies (leads to large bundle sizes, and inflexibility).
- Component composition is manual.
- Adapting components is difficult (i.e. slightly altering configurations like compiling with a different flag).
- The nominal dependency problem; referencing components by name or name and version only.[^8]
- Polluted environments lead to interference.[^9]
- Incomplete deployment.[^10]

All of these issues appear in the most widely used operating systems today.
When you enumerate the list its pretty surprising the we put up with these
difficulties. In fact Dolstra comments that the system that comes closest to
correct deployment is not actually a classical deployment system but "developer side" Software
Configuration Management tools which are basically version control software (like git)
with build management integrated.[^11]

# The Benefits of Nix

I have often said, when asked to describe Nix, that the single greatest insight
the Nix approach has is that it gets the "naming" of software right. The thesis
offers a much more nuanced perspective on this framing.

The core principles of the Nix deployment approach are to[^12]:
1. Isolate components from each other, in a central store.
2. Choose a naming schema (cryptographic hash) that summarizes the semantics of what we mean when we name a component.
3. The semantics of the naming schema need to prevent undeclared dependencies and allow for multiple variants of software to co-exist.

I will try and break these three principles down, but they are heavily related,
so it can be difficult to disambiguate them.

The central store is critical for the "realization" of components (as mentioned
in the [Software Deployment](#software-deployment) section), basically it gives
us a single place to look to find dependencies. The isolation of components
mitigates against the potential downside of a single store, namely
interference.

The naming schema is critical for the "identification" of components.
Cryptographic hashes mean that we have a massive collision free namespace to
work with, and those hashes can concisely summarize information that we wish to
encode in the name.

The semantics of the naming schema ensures correctness. Since the
cryptographic hash is generated from all the inputs (think dependencies)
required to build the software, we have a robust notion of equality with which
to distinguish components. Additionally, we Nix uses this knowledge of all the
inputs to ensure that there are no undeclared dependencies at build time.

An important aside here is that we have mostly been talking about Nix's notion
of equality to distinguish components. But it is desirable that we share as
many components as possible, and don't need to rebuild components that are
equal. So this notion of equality prevents intereference, but it can also be
used to optimize builds by sharing dependencies across components. In the
thesis this is referred to as maximal sharing.[^13]

In addition to the core principles, Nix uses a purely functional model where
all software in the central store is immutable. This means that it cannot be
modified in a breaking way. It also prevents side effects in the build process
which means that software components are built deterministically. This is
important for ensuring that the name directly corresponds to the component.

This approach yields these benefits[^14]:

- Complete deployment and non-intereference (i.e. correct software deployment)
- Atomic upgrades
- O(2) rollbacks
- Transparent source / binary distribution.[^15]
- Inefficiencies due to purely functional / immutable model are ammortized
  through optimizations like caching and sharing.
- Nix component language (the language used for expressing software components)
  makes composition trivial and supports it first class.
- Distributed multi-platfform builds; remote build is indistinguishable from a local build.

These benefits totally solve the most common problems with software deployments
and managing environments. A great illustration of this is how Nix shines when
used for managing CI environments, which are notoriously inconsistent and
highlight how Nix gets things right.[^16]

# Implementation Details

We had to briefly get into the low level details of Nix's approach to software
deployment in order to anchor the benefits it provides in the previous section.
This section will expand on those details. [The Nix Store](#the-nix-store)
section really focuses on the "identification" aspect of the software
deployment problem, and the [Filesystem As Memory](#filesystem-as-memory)
really focuses on the details of how "realization" works on actual filesystems.

## The Nix Store

How does the nix store actually work under the hood? It stores software
components as directories (named using the hashing schema mentioned before) in
a root directory (usually `/nix/store`). Its worth mentioning that nix has an
extremely weak notion of what constitutes a component; it could be a static
configuration file, a compiled binary, source code, a single javascript file
that can be interpreted and run. As long as it can be stored in a filesystem it
is a viable candidate for being a software component. As mentioned before, this
naming convention prevents intereference and guarantees completeness. We will
look at how that works.

### Preventing intereference

The cryptographic hash for a component is computed based on its inputs.
Therefore if components differ in any way at all it will be reflected in the
hash. This means that installation or uninstallation will not effect any other
components. Since inputs themselves have hashes, and if these hashes change
then the hash of the component that depends on the input changes, this means
that hashes are effectively computed recursively. Therefore changes to inputs
"propagate" through a dependency graph, another way to put it is that changes
to transitive dependencies will be reflected in the upstream component.[^17]

### Completeness

Nix guarantees that all dependencies are identified. In other systems
dependencies are usually declared nominally (like RPM) and can be forgotten, or
they are passed in dynamically like linking a C module. Since nix stores
components in isolation, there is no way to leverage global namespaces to
implicitly provide an input. This means that if you are depending on the
presence of a dependency implicitly (i.e. globally) then the build will just
_fail_.[^18]

> I think this is one of the reasons that nix gets a bad wrap, because it
> forces you to do things in a principled way and fails early it can seem like
> it causes friction at first. What seems frustrating at first is really nix
> giving you feedback that the current approach being taken may fail silently
> in the future, or just not work in a different environment.

The key to this is that if a dependency is not explicitly declared then the
component will fail deterministically.[^19]

The cryptographic hash takes care of all buildtime dependencies, but you might
be wondering about runtime dependencies. Runtime dependencies will be hard
coded into the component with a reference to a nix store path, along with the
distinctive cryptographic hash. Nix can scan for these distinctive strings and
keep track of required runtime dependencies. This means that _all_ dependencies
for a component are tracked.[^20]

The final concept nix concept that allows it to facilitate complete deployments
is called a _closure_. The closure refers to the entire graph of transitive
dependencies tracked for a component. This "closure" is what needs to be
provided in order to ensure safe, correct deployment.[^21] Nix provides a method for
computing these closures and handling them in an ergonomic way.

## Filesystem As Memory

The "Filesystem as memory" analogy was really impactful on me while reading the
nix thesis. It is a bit unfortunate that going over it will re-state a lot of
what we have already covered. However, I think it is worthwhile to examine it
to drive home the points about correctness. Additionally it will motivate a
concept that is core to nix, and critical for making the purely functional
model viable, which is conservative garbage collection.

| Filesystem | Memory |
|------------|--------|
| Filepath | Memory Address |
| String repersenting a path | Pointer |
| Accessing a file through a path | Pointer dereference |
| Software components | Objects (values) |
| Reference to absent component | Dangling pointer |

This table represents the meat of the analogy. The major upshot of this is that
component interference due to file overwriting can be viewed as address
collision. Component incompleteness, or by way of the analogy "the inability to
dereference a pointer" because a file doesn't exist is the deployment
equivalent of a dangling pointer.[^22]

Understanding how pointers can be dereferenced is critical to preventing
dangling pointers, so we will enumerate them below. The examples are in
typescript and adapted from the original Java versions in the thesis, the class
in the example is called `Buildtime` to denote that construction of the class
represents buildtime, and there is a method called `runtime` to denote that the
execution of that method represents runtime.[^23]

### Obtained and dereferenced at runtime

```{.typescript}
class BuildTime {
    constructor(){}

    runtime(y: Bar){
        return y.exec()
    }
}
```

The filesystem corollary of the above code is similar to acquiring and using a
component from the `$PATH` search path, or as a program argument (maybe passed
in via CLI).

### Obtained and dereferenced at buildtime

```{.typescript}
class BuildTime {
    x: number

    constructor(y: Bar){
        this.x = y.exec()
    }

    runtime(){
        return this.x
    }
}
```

This example cannot cause a dangling pointer: similar to static libraries, a
compiler, or other things that are not usually retained in the build result.

### Obtained at buildtime, dereferenced at runtime

```{.typescript}
class BuildTime {
    x: Bar

    constructor(y: Bar){
        this.x = y
    }

    runtime(){
        return this.x.exec()
    }
}
```

This represents Unix style dynamically linked libraries, for example storing
the full path of a program in the RPATH of an application binary.

These three examples serve to demonstrate how hard it is to ensure that there
are no dangling pointers. Pointers may exist at runtime (i.e. in the source)
similar to the first example. Pointers may be passed in at build time similar
to the second example, but in this case we want to make sure we don't
distribute them with the component, since they have already done their job.
However, we need to be careful, since some pointers passed in at build time are
still required at runtime, like dynamically linked libraries (as shown in the
third example). A final consideration is that particularly deranged users can
use pointer arithmetic to get new pointers, the filesystem analogy would be to
use string manipulation to find a filepath.[^24]

Closures (as mentioned before) are the solution to dangling pointers, by
definition they do not contain any. But there is another issue, and that is
keeping our closures from growing unnecessarily large.

The solution in this case is _conservative garbage collection_. We have to scan
components for potential runtime dereferences, and anything that looks like a
valid pointer will be kept. There may be false positives, but that is an
acceptable tradeoff. It is unacceptable for correctness to have a dangling
pointer. Nix imposes a _pointer discipline_ through its hash-based naming
schema which allows pointers to be recognizable within components, and the
pointers are isolated from one another within the nix store.[^25]

## Pure Functions

"An important point here is that upgrading only happens by rebuilding the
component in question and all components that depend on it. We never perform a
destructive upgrade. Components never change after they have been built—they
are marked as read-only in the file system. Assuming that the build process for
a component is deterministic, this means that the hash identifies the contents
of the components at all times, not only just after it has been built.
Conversely, the build-time inputs determine the contents of the component.
Therefore we call this a purely functional model. In purely functional
programming languages such as Haskell [135], as in mathematics, the result of a
function call depends exclusively on the definition of the function and on the
arguments. In Nix, the contents of a component depend exclusively on the build
inputs. The advantage of a purely functional model is that we obtain strong
guarantees about components, such as non-interference." pg 21

"Also, we go to some lengths to ensure that component builders are pure, that
is, not influenced by outside factors. For example, the builder is called with
an empty set of environment variables (such as the PATH environment variable,
which is used by Unix shells to locate programs) to prevent user settings such
as search paths from reaching tools invoked by the builder. Similarly, at
runtime on Linux systems, we use a patched dynamic linker that does not search
in any default locations—so if a dynamic library is not explicitly declared
with its full path in an executable, the dynamic linker will not find it." pg 23

# Nix Principles

# Topics Not Covered

There were many topics that were interesting in the thesis, but were too
technical to write about. I will list them here for the interested reader:

### Intensional vs extensional model

The extensional model is the Nix that we are used to today, but there is active
work on making the intensional model happen. The main difference is the notion
of equality. For the extensional model the name (including the hashes) of the
inputs are all we care about, but you can have an even more granular
definition, where the actual content of the inputs is hashed. This provides
greater security guarantees, or optimizing redundant builds, but makes some
other things harder. The intensional model is called `content-addressed
derivations` these days and you can [track its progress
today](https://discourse.nixos.org/t/content-addressed-nix-call-for-testers/12881)

### Binary patching

Binary patching is extremely interesting, it offers a solution for reducing the
computational overhead of rebuilding large portions of a components dependency
graph. It does so, as the name suggest, by applying a patch to the binary of an
existing component on disk rather than rebuilding from scratch. The relevant
section in the thesis is 7.5.

### A language for builders

This is mentioned in future work, and it is definitely something that I find
painful today about nix. Bash scripts are not exactly the paragon of
correctness. There are however, [attempts provide alternative ways to construct
builders](https://determinate.systems/posts/nuenv) by way of altering something
called the "standard environment" (which just provides conveniences for making
builders and derivations).

### A type system for the nix expression language

This is also brought up in the future work, and there has been lots of
interest from the community for this. As far as I can tell there are a couple
attempts at this. The first is [nickel](https://nickel-lang.org/) which seems
to be marketing itself as a general purpose configuration language for more
than just nix. The second is [purenix](https://github.com/purenix-org/purenix)
which uses the Purescript frontend language, and provides a backend that
compiles to nix. While I would love to see either of these succeed, neither has
reached critical adoption.

# Footnotes
[^1]: Dolstra, E. "The Purely Functional Software Deployment Model," 2006. https://books.google.ca/books?id=gP2kAAAACAAJ.
[^2]: Dolstra, "The Purely Functional Software Deployment Model," 245.

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
    actions."
[^3]: Dolstra, "The Purely Functional Software Deployment Model," 3.
[^4]: Dolstra, "The Purely Functional Software Deployment Model," 4.
[^5]: Dolstra, "The Purely Functional Software Deployment Model," 5.
[^6]: Dolstra, "The Purely Functional Software Deployment Model," 5.
[^7]: Dolstra, "The Purely Functional Software Deployment Model," 6-15.
[^8]: Dolstra, "The Purely Functional Software Deployment Model," 9.

    "However, such version specifications involve a high degree of wishful
    thinking, since we can never in general rely on the fact that any version in an
    open range works. For instance, there is no way to know whether future release
    1.3.1 of hello will be backwards compatible. Even "exact" dependencies such as
    `Require hello = 1.0` are unsafe, because this is still a nominal dependency:
    we can conceive of any number of component instances with name hello and
    version number 1.0 that behave completely differently. In fact, this is a real
    problem: Linux distributions from different vendors can easily have components
    with equal names (e.g. glibc-2.3.5) that actually have vendor-specific patches
    applied, have been built with specific options, compilers, or ABI options, and
    so on."
[^9]: Dolstra, "The Purely Functional Software Deployment Model," 10.

    "This is the case because the new version typically lives in the same paths
    in the file system. e.g., hello-2.0 will still install into
    `/usr/bin/hello` and `/etc/hello.conf`. Apart from the resulting inability
    to have multiple versions installed at the same time. This gives rise to a
    temporary inconsistency in the system: there is a time window in which we
    have some of the files of the old version, and some of the new version."
[^10]: Dolstra, "The Purely Functional Software Deployment Model," 8.

    "[because there is no mandatory record of dependencies] Thus, it is
    intrinsically hard to validate dependency specifications. (It is also hard
    to prevent unnecessary dependencies, but that does not harm correctness,
    just efficiency.) An analysis of the actual number of dependency errors in
    the large RPM-based Linux distribution is described in [87]. The number of
    dependency errors turned out to be quite low, but this is likely to be at
    least in part due to the substantial effort invested in specifying complete
    dependencies. Missing dependencies lead to incomplete deployment; correct
    deployment on the other hand requires complete deployment."
[^11]: Dolstra, "The Purely Functional Software Deployment Model," 200.

    "All systems have a fairly strict separation between source and binary
    deployment, if both are supported at all. Interestingly, in terms of
    supporting correct deployment, the tools that come nearest to the ideal are
    not classical deployment systems (e.g. package managers) but "developer
    side" SCM systems such as Vesta..."
[^12]: Dolstra, "The Purely Functional Software Deployment Model," 14.

    "The main idea of the Nix approach is to store software components in
    isolation from each other in a central component store, under path names
    that contain cryptographic hashes of all inputs involved in building the
    component, such as /nix/store/rwmfbhb2znwp...-firefox-1.0.4. As I show in
    this thesis, this prevents undeclared dependencies and enables support for
    side-by-side existence of component versions and variants."
[^13]: Dolstra, "The Purely Functional Software Deployment Model," 60.

    "The notion of maximal sharing is also applicable to deployment. We define
    two components to be equal if and only if the inputs to their builds are
    equal. The inputs of a build include any file system addresses passed to
    it, and aspects like the processor and operating system on which it is
    performed. We can then use a cryptographic hash of these inputs as the
    recognizable part of the file name of a component. Cryptographic hashes are
    used because they have good collision resistance, making the chance of a
    collision negligible.... In summary, this approach solves the problem of
    component interference at local sites and between sites by imposing a
    single global address space on components."
[^14]: Dolstra, "The Purely Functional Software Deployment Model," 14-16.
[^15]: This is one of the most underrated aspects of Nix. This means that
    binary deployment is merely an automatic optimization on top of source
    deployment, and this optimization doesn't require the user to be aware of
    it at all. You get the best of both worlds: the variability, control, and
    security of source deployments with the speed of binary deployments.
[^16]: Dolstra, "The Purely Functional Software Deployment Model," 211.

    "Of course, Nix nails this problem [the CI problem]: since Nix expressions
    describe not just how to build a single component but also how to build all
    its dependencies, Nix expressions are an excellent way to describe build
    jobs. Also, the problem of dealing with variability in the environment
    (such as conflicting dependencies), are automatically resolved due to Nix's
    hashing scheme: different dependencies end up in different paths, and Nix
    takes care of calling builders with the appropriate paths to dependencies.
    Finally, Nix's support for distributed and multi-platform builds (through
    the build hook mechanism) addresses the scalability problem: as we will see
    below, a configuration change needs to be made only once (to the Nix
    expression), and Nix through the build hook will take care of rebuilding
    the new configuration on all platforms."
[^17]: Dolstra, "The Purely Functional Software Deployment Model," 21.
[^18]: Dolstra, "The Purely Functional Software Deployment Model," 23.
[^19]: Dolstra, "The Purely Functional Software Deployment Model," 23.

    "Thus, when the developer or deployer fails to specify a dependency explicitly
    (in the Nix expression formalism, discussed below), the component will fail
    deterministically. That is, it will not succeed if the dependency already
    happens to be available in the Nix store, without having been specified as an
    input."
[^20]: Dolstra, "The Purely Functional Software Deployment Model," 24.

    "The hashing scheme comes to the rescue once more. The hash part of component
    paths is highly distinctive, e.g., 6jq6jgkamxjj.... Therefore we can discover
    retained dependencies generically, independent of specific file formats, by
    scanning for occurrences of hash parts. For instance, the executable image in
    Figure 3.4 contains the highlighted string 5jq6jgkamxjj..., which is evidence
    that an execution of the svn program might need that particular OpenSSL
    instance. Likewise, we can see that it has a retained dependency on some Glibc
    instance (/nix/store/73by2iw5wd8i.... Thus, we automatically add these as
    runtime dependencies of the Subversion component."
[^21]: Dolstra, "The Purely Functional Software Deployment Model," 24.

    "The hash scanning approach gives us all runtime dependencies of a
    component, while hashes themselves prevent undeclared build-time
    dependencies. Furthermore, these dependencies are exact, not nominal (see
    page 9). Thus, Nix knows the entire dependency graph, both at build time
    and runtime. With full knowledge of the dependency graph, Nix can compute
    closures of components. Figure 3.2 shows the closure of the Subversion
    2.1.4 instance in the Nix store, found by transitively following all
    dependency arrows."
[^22]: Dolstra, "The Purely Functional Software Deployment Model," 53.
[^23]: Dolstra, "The Purely Functional Software Deployment Model," 53-54.
[^24]: Dolstra, "The Purely Functional Software Deployment Model," 54.
[^25]: Dolstra, "The Purely Functional Software Deployment Model," 57-58.
