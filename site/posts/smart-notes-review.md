---
title: "Book Review: How to Take Smart Notes by Sönke Ahrens"
author: Jonathan Lorimer
date: 19/03/2020
datePretty: Mar 19, 2020
description: "A review of How to Take Smart Notes by Sönke Ahrens. The verdict on the book was largely negative. Aside from the review I give an overview of the zettelkasten structure and workflow, and discuss why the process seems so opaque at first."
tags: [productivity, book-review]
---

# Table of Contents

- [Introduction](#introduction)
- [My Experience with Note Taking Systems](#my-experience-with-note-taking-systems)
- [Structure and Workflow of a Zettelkasten](#structure-and-workflow-of-a-zettelkasten)
- [Discussion of the Book](#discussion-of-the-book)
- [Conclusion](#conclusion)

# Introduction

  In this review I am going to discuss 3 topics. The first is what I wanted to get out of this text and why I was interested in reading the book in the first place. The second is the actual structure and workflow of a zettelkasten as recommended by the book. The last topic looks at the concepts that I found interesting, and the ones that I struggled with.

# My Experience with Note Taking Systems

  In University I studied philosophy, and I remember reviewing the department wide rubric for grading papers. I recall being a bit miffed about the criterion for an A grade. I don't recollect the exact wording, but it was something to the tune of "all A papers must contain original thought". How does one, an undergraduate nonetheless, come up with original thought in a discipline that is over 2 millennia old? The solution I came up with, though my A papers were few and far between, was concept synthesis. I could just take the ideas of two or more other philosophers, smash them together (compare and contrast, etc.), et voilà an original thought. The combination of a strategy that relied heavily on the work of others, and a professor who was particularly litigious when it came to academic integrity, forced me to establish a meticulous set of literature notes and the corresponding citations. This was my first taste of a note taking system.

  I have to say, with this primitive note taking system, I realised a lot of the benefits espoused by the zettelkasten crowd; papers seemingly wrote themselves, bibliographies (which were previously a pain) had finished themselves by the end of the paper, and I could effectively separate the note taking, thinking, and writing steps. My papers and grades benefited immediately.

  The note taking system consisted of several directories separated by course and topic. Additionally, I took lecutre notes and reading notes separately. All of this was done within One Note. There were several shortcomings: global search by word was a slow workflow as words are often reused (with vastly different meanings) in different areas of philosophy, searching by topics that spanned multiple courses (e.g. ethics) was very difficult and tagging notes in One Note was clumsy, if I had a specific note in mind it was very difficult to find it across all of my literature notes. After University I largely gave up on my note taking system. Recently, I happened across a discussion about the zettelkasten system in the functional programming [Zulip chat](https://funprog.srid.ca/general/zettelkasten.html). An explanation of the reasoning behind the zettelkasten demonstrated why the literature notes I was previously taking were partially effective, but also why I had felt so many pain points. Someone in the chat forum I mentioned _How to Take Smart Notes_ and I ordered it.

  When reading this book I wanted to firmly understand the structure of the zettelkasten system and how to use it. For some reason I found this methodology difficult to grasp even after reading a dozen or so articles. I wanted to more accurately understand the benefits of the system, and make sure that my understanding was so thorough that I could tailor a zettelkasten implementation to suit my own needs.

# Structure and Workflow of a Zettelkasten

  The zettelkasten takes a minimalist approach to creating what some call an [external brain](https://gettingthingsdone.com/2018/07/are-you-out-of-your-mind/). There are several key structures that are critical to implementing a zettelkasten. Additionally, I think there are several concepts that go along with these structures that make the whole system much easier to understand. We will start with the structures. Here is a folder layout that reflects the conceptual structure of the zettelkasten.

```
zettelkasten/
├── slip-box/
│   ├── index
│   ├── note-1
│   ├── note-2
│   └── ...
└── literature-notes/
    ├── ahrens_how-to-take-smart-notes/
    │   ├── note-1
    │   ├── note-2
    │   └── ...
    └── ...
```

  The first key structural distinction is between the `slip-box` and the `literature-notes`. The slip box is meant to be a contiguous chain of notes that are roughly sorted by topic. The sorting occurs as one adds notes to the slip-box. Slip-box notes are created to signify a meaningful idea that relates to the areas of study that you are interested in. Notes are added behind other related notes such that the system stratifies into distinct geographic areas within one conceptual landscape. In contrast, the literature notes act as a reference management system, and keep track of important information in a single text (the notes should contain a page number or some other identifier). Now the literature notes are supposed to help us derive slip box notes; once we are finished reading a resource we should try and generate notes for the slip-box. For a more thorough explanation of the basic zettelkasten structure see this [article](https://writingcooperative.com/zettelkasten-how-one-german-scholar-was-so-freakishly-productive-997e4e0ca125).

  The second key structural piece is the `index` and what I will call `entrypoints`. I had trouble wrapping my head around the index / entrypoint, and I think it's because of how flexible the entrypoint concept is. The index is like a table of contents that link out to other notes of interest, this allows for easier navigation of the slip box. A heuristic you might use to understand the index is that it contains one link per topic in the zettelkasten, although this is in no way a material constraint. Entrypoints are just notes, but act as a summary of a topic by linking to other pertinent notes. Therefore it would be a common pattern for the index to link to an entrypoint, and then the rest of the topic can be navigated from there, through straightforward note to note links. The beauty of the entrypoint being 'just another note' is that it can be easily replaced, or extended. This allows topics to expand, contract, and change directions naturally. When creating notes, they should be discoverable from the index; either directly or indirectly through a chain of notes.

  The third key structural component is implicit, it is the `concept graph`. The graph is implied because it is not evident from looking at the folder structure, but becomes clear when traversing the notes by walking the links that connect one note with another. In mathematical terms the graph would be a [directed graph](https://en.wikipedia.org/wiki/Directed_graph), because all the connections have a direction. I have heard people refer to a zettelkasten as a directed acyclic graph, which prohibits moving backwards to a previous note by traversing the connections, however it is possible to add cycles in a zettelkasten (or at least I haven't read anything prohibiting it).

> This concept graph reminded me of a school of thought from epistemology called `coherentism`. This theory of knowledge suggests that facts are held aloft by an endless network of supporting facts. This contrasts with foundationalism which theorizes that facts are supported by a foundation of primitive truths.

The workflow for a zettelkasten proceeds as follows:
  - take literature notes while reading
  - when finished (either reading the resource or reading for the day) turn the most important ideas from your literature notes into permanent notes for the slip box
  - add permanent notes to the slip box in the correct location and link to other notes
  - finally, make sure that the permanent notes you added can be discovered by walking the graph forward from the index.

# Discussion of The Book

  I honestly don't feel like I got that much out of the book, although I had done quite a bit of prior research on the zettelkasten system. One of my major concerns is that the book was very obviously a product of the system it was describing. The author did a great job citing his references, and making connections. However, the connections felt tangential and really irrelevant to anything I cared about. My concern is that the resultant written artefact does not feel like it is designed for the reader, because the zettelkasten optimizes for connections to ideas that are relevant to the authors interest. For example I expected this book to be about the zettelkasten system, how to implement it, and use it effectively. The majority of the word budget in this book was spent making connections to psychology, and trying to convince me that the zettelkasten is an effective system. For me, this observation may have been worth the price of the book; to make sure that I keep the readers interests in mind when synthesizing a work from my zettelkasten notes. Another problem was that the author seemed to be hard selling the system. Perhaps it is just me, but I went into this book willing to believe that the zettelkasten is effective. I think that perhaps a chapter dedicated to advocation would have sufficed, but it felt like everything after chapter 2 (certainly after chapter 4) was just evangelism. In spite of all this I have collected three insights that I found particularly enlightening, and several claims that I was extremely skeptical of. I will explain them in the following paragraph to give a taste of the book.

  The first insight identified that the zettelkasten was a strong conveyor of ideas because it packages them uniformly. This helps us to accommodate different frames of reference, and aggregate ideas across different topics more expeditiously. The analogy that the author uses is that of the shipping container. It was difficult to see how putting goods into a fixed-size container would improve supply chain flow; there would be inefficiencies where goods did not fit correctly. What this analysis fails to take into account is the system as a whole, by making the smallest unit of transportation constant it allows every party to conform to a single design. Hence it was a trucker who invented the shipping container, rather than a shipping magnate (as one might expect). Following this analogy, creating bespoke packaging (topics and subtopics) for our ideas neglects the system as a whole, which should be oriented towards generating written artefacts of knowledge. These artefacts require us to be flexible in the way that we combine units of information. This insight helped me understand why the `entrypoint` notes are just regular notes. Uniformity allows us to deprecate entrypoints gracefully, in favour of new ones, or create two entrypoints that cover the same topic with a slightly different slant.

  The second and third interesting points were less insightful than the first, but relevant my particular situation. They are: 'don't be a planner be an expert', and 'the length of notes should match the complexity of the text'. I always structure my personal learning schedule in terms of a curriculum with a concrete end goal. The obvious problem with this is that as one moves through the curriculum and gains greater expertise end goal usually changes. Rather than planning a curriculum as a beginner, it makes more sense to take on the next learning material based on the questions that naturally arise from the previous. This unstructured exploration of the problem space, ostensibly, leads to expertise wherever the learner chooses to go deep. As for matching the complexity of notes to the complexity of the text, this seems obvious. However, I always find myself trying to create notes of uniform length. This feels similar to my compulsion to finish a book even if I am getting nothing out of it. I think that by packaging information into a consistent sturcture, the zettelkasten allows us to vary the complexity of the content and still maintain a manageable system. For example, in a topic / subtopic delimited note system I notice myself trying to keep bullet points roughly the same length. I think that I try to do this because within a file, the length of the bullet points visually make up the structure of the note. The problem here is that I am constraining the content of the bullet point in deference to a consistent structure, which I find easier to navigate. The zettelkasten separates out the content from the structure allowing the complexity of the content to vary from note to note while still maintaining uniformity.

 Being an author is an incredibly difficult job, and I am not really in a position to criticize, so take the rest of this paragraph as opinion. The author made claims that the zettelkasten served to defuse latent biases in the note taker (zettelkastor?). The two forms of bias that stood out to me were confirmation bias and survivorship bias. The zettelkasten, acting as an interlocutor, is supposed to elucidate 'the other side of the argument'. Seeing how the zettelkasten is generated by the note taker I don't see how their biases couldn't creep into their note taking system. The zettelkasten is also supposed to eliminate survivorship bias because it contains successful as well as unsuccessful ideas, again I don't buy that the reader will necessarily heed the unsuccessful ideas simply because they are contained within a zettelkasten. Finally, the writer suggests that the structure and constraints of the zettelkasten will serve to mobilize creativity, this argument seems to fly in the face of an earlier argument that the author makes which is that the zettelkasten is superior to topic/subtopic delimited notes precisely because it enforces less strict structure and constraints. All of these arguments were well supported by citations, but seemed to depend crucially on the assumption that the zettelkasten is not liable to the same fallacious reasoning that the author was.

# Conclusion

I would recommend reading a collection of articles on how to construct a functional zettelkasten and note taking practice, rather than this book. However, if you are unconvinced about the effectiveness of the zettelkasten methodology, then this book might prove more interesting for you than it did for me.


If you would like to comment on this post, the comments section is [here](https://github.com/JonathanLorimer/personal-website-builder/issues/1)
