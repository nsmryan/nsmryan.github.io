---
title: Thoughts on Embedded Programming
author: Noah Ryan
---
This post is just some thoughts on programming embedded systems.


These thoughts come from working on software that runs on a relatively powerful processor board-
this is not the resource starved embedded programming. I'm particularly thinking of using VxWorks.


Split Out Pieces That are Conceptually Separate
===
I've noticed recently that there are subtle distinctions that can be made in program design that
are not required, but can be very helpful.


For example, a module may have some data that is very critical, and other data that is just for informational
purposes. Even if these are recorded or presented in the same information stream, but it may be worth while
splitting them into separate structures.


Events, Triggers, and Signal Propagation
===
The world of embedded programming consists of threads of control, interrupts, queues, semaphores of various types, 
global and local memory, and other control structures.
There is hardware that produces data and consumes data, but it is invisible from the software perspective- it is 
a separate actor that takes actions while the software runs and may need to be synchronized.


