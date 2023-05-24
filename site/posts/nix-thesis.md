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

# Introduction

_The Purely Functional Software Deployment Model_ by Eelco Dolstra (herein
referred to as "the thesis) is often pointed to as a great resource for
learning about nix, albeit technical and formal. A reasonable response to this
would be: Is a 20 year old, ~250 page thesis really the best way to understand
a software management tool? I set out to discover the answer to this question
myself and found that the thesis was very accessible, remarkably relevant given
its age, and that a significant portion of the content was philosophical rather
than technical. Therefore, my aspiration for this blog post is to crystalize
some of the insights from the thesis into short form content; it will either
satiate the reader's appetite for the topic, or inspire them to go on and
consume the full text[^1].

# Correct Software Deployment

## Correctness

## Software Deployment

## Bonus: Manageability & Usability

# Problems With Existing Solutions

# Implementation Details

## Filesystem As Memory

## Nix Store

## Pure Functions

# Nix Principles

# Topics Not Covered

[^1]: A footnote
