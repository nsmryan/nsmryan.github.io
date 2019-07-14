---
title: How to Make Better Flight Software
author: Noah Ryan
---
This post is a series of thoughts I have had over the years about making better
software, and in particular the sort of aerospace software I write at work.


This is not a list of things that one should do to improve their software, its
a question- how do we improve our software?


# Tools
One of the main, and perhaps most fun, way to improve software is to use better tools.

We have some good tools availible to us- VxWorks is a very stable, relatively simple, and
safe operating system to build high assurance software. There are static analyzers available,
some even for free like CPPCheck.  Even C and C++, despite their dangers and limitations, have advantages.


However, I could see some improvement though a consistent use of multiple static analyzers, even for
people paying for a more advanced one like CodeSonar. I would want to see these tools built
into the development environment in some way in order to avoid the situation where they are run
rarely or their results are not looked over in detail.


# Design
There are definitely considerations to keep in mind while designing software that can improve its
eventual quality. Many of these should be considered early on, ideally from the beginning.


## Pure Code
I've learned over the years to write as much of my code as possible in the form of pure functions.
This usually means functions that take more inputs then strictly necessary, and factor operations
into smaller sections that strictly necessary. I have seen places where this increases the overall
complexity of the code, but places code into blocks that can be considered separately.


In general it is better to be able to reason about code locally- both in space (within the
file the code is in) and in time (when the code operates, how long are its effects felt?). Pure code
tends to be more local then impure code- even if you have to construct more interface to get inputs
and outputs for pure code sometimes (especially in C), you end up with code that is self-contained,
and does not modify data that might have long term effects, like global variables.


One trick I heard from Dan Noland is to keep as many decisions in pure code as possible- decisions
introduce complexity, and ideally should all be tested. Therefore it is better to have impure code
as straightforward as possible and factor desicions into pure code. This code can then be tested
and all paths simulated without having to do this at a system level where it can be difficult
or impossible to create all code paths.


## Models
I've had some philosophical thoughts recently about models and software, with programs as logics,
and as models of other logics, and as specifications of yet other models. This concept in some
sense subsumes the idea of pure code- pure code is useful because it is more direclty a model
of an algorithm then impure code.


There may be benefits to keeping multiple models around for your code- either formal structures like
state machines or graphs, or just simpler implementations, and testing against these models. I would like
to do something like create test cases from a model, and lower test cases from the implementation into the model.
Going both ways like that could lead to directed random tested (in the first direction), and to a check of
unit tests (in the other direction).


I don't have anything specific to say here- this is a whole area of research which I am not too well informed about
but which seems promising.

## Testing
Testing is something that should be considered from the start of any project. There are certain properties that are
very had to add to a software system once its built, and testability is one of them. Code should be written to test,
modules written to provide clear inputs and outputs, and infrastructure should be built around the software for
automated testing.


This is a place where I've been using Unity (the test framework, not the game engine) for unit level tests, and 
COSMOS for automated system tests. I would love to see more of this- its been a hugely helpful combination
and pays for the extra effort again and again with greater confidence in code and with fewer bugs.

## Telemetry
Another important consideration for software is observability. If you can't observe what your system is doing, it may
very well be doing some very strange things and you might never know. If you do know, you might see strange, periodic
problems whose underlying cause it not being adequately monitored- I've been there and seen the problems that can
arise from unexpected interrupts or hardware communication, which can impact a whole other section of the system in
subtle ways.


Telemetry is one way to address this issue- keeping track of system state and providing it at a certain rate. Keep
counters for processes, packets, and just about anything else. Keep state information about data transfers, provide
error flags if they are available, and provide indications on which path through your code the system went.


This kind of thing is not the only data you might want to gather, but it is a good start and is relatively easy to provide.
Another source of information might be OS task context switches, interrupts, bytes received or processed on an interface,
memory use, process/task/hardware liveness, etc.


## Portability
Code portability is a big topic, but one thing to keep in mind for flight software is how a system changes between projects.
One of the main thing is abstracting operating system and hardware devices to avoid being tied to the system you happen to
develop on. This is not to say that all such ties need to be abstracted- abstraction has a cost, even if its just in 
mental overhead, which should not be paid lightly. Instead, abstract common functions.
and 


# Process
There are some basic things that can make a huge impact on code quality. If nothing else, code reviews are absolutely
vital to quality software. They fix bugs, enforce consistency, spread knowledge, force you to package code up and make it
ready for others to view (by itself a great motivation), and allow your team to enforce conventions by ensuring people 
are actually looking at the code.


Another process might be automated testing- as much testing as possible should be automated, and it should be run frequently.


Issue tracking is a huge help for a team- its very easy to lose track of problems or conversations, and a tool for tracking
these is an easy thing to set up. Even just GitHub has enough to track issues, and I've been using it for that for myself,
although I know others using it to track a small project's software development.


# Documentation
Documentation is a difficult one to pin down- on one hand some documentation is never used by anyone, but on the other
hand some documentation is invaluable. Even documentation that is not read provides another view of code, a place to articular
desicisions, and a way to spend time with code that often catches issues by itself.


I've been trying to push for automated documentation on project's that I work on. This has worked well for reducing the
repetitive documentation that we would otherwise have to write by hand, but does have some limitations. Certainly some
information does not get into the automated documentation, so it is placed in manual documentation, and it can be difficult
to get the automated documentation to look reasonably good and professional. We are currently trying to work out how to
use Doxygen for this, and how to get the best looking results.
