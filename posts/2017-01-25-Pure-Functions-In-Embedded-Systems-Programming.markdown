---
title: Pure Functions in Embedded Systems Programming
author: Noah Ryan
---

I've had some experiences recently where I've seen code written in C/C++ for embedded systems
that benefited from my experiences with Haskell. In short, I've found that pure functions make code more robust, easier to test,
easier to document, easier to reason about, and easier to extend to new situations (porting between systems, and wrapping in simulators/ground systems)
and changing requirements.  The only thing I've regretted using this technique is that I don't do enough of it.

This post describes some of my experiences factoring out portions of
my code into pure functions on Class B and Class B Safety Critical software. There are other applications of functional programming and type theory
to embedded systems programming, but this is a big one.


Some examples from my experience are fault detection systems (Fault Detection, Isolation, and Recovery or FDIR), core algorithms like
orbit propagation (as well as boundary determination in a geofencing system, predicting vehicle dynamics and other such algorithms), input
accepting systems for communication like state machines, validation functions for data, converting data (including packetizing it, converting
between time formats, and parsing configuation), and applying filters to data or packets. Some of these applications are described in more detail below.


Pure Functions
=============
Briely, a pure function should will always produce the same result for the same input, regardless of when or how many times it is run.
This prevents IO, global state, network traffic etc- anything that might modify how a function runs or make it non-deterministic.
This is a situation where restricting what you make use of is a hugely powerful technique, and having the discipline to
enfore purity (even in a language which does nothing to help you do that) yields huge benefits that pay for the time invested many times over.


In embedded systems, software is written as a series of modules, each with a particular task or roles within the system. Look at
Core Flight Software (CFS) for an example of this kind of architecture. Within this architecture, there tend to be several types of modules. Some examples are
modules that that perform software tasks (ie routing messages, packaging data, monitoring telemetry), modules that provide utility functions,
modules that run a particular algorithm, and modules that interface with hardware.


All of these modules can benefit from pure functions. Code that does not need to interface with hardware (utilities and algorithms) is especially good for this
kind of design, but even modules that interface with hardware can section off parts of their processing into pure functions and get the benefits.


FDIR
====
A concrete example is a fault detection system that takes a series of structures defining what to monitor, and recieves a packet to inspect at a given rate.
This kind of system benefits from factoring all the monitoring code out into pure functions which apply single monitors. With that design, test cases can produce
a variety of things to monitor throughout a packet, and feed both the packet and what to look for within that packet, into a single function. The result can be
automatically inspected, and the resulting test cases left as a regression test for future maintenance. This isn't the only oppertunity here- if the whole monitoring
algorithm is pure then it can be tested in the same way, leading to a larger percentage of easily testable code.

Consider what happens if these functions are not pure- what if you have to reconfigure the system between test cases, or if you can only test at a system level
because the code *requires* interaction with other modules to run? In my experience the unit testing is less rigorous, and the system level testing is very complex
and time consuming. There is no good way to do random testing, and its essentially impossible to test every function in isolation- the testing ends up being at a higher
level. 


In other words, the core enabling aspect of the design that allows it to be testable is to ensure that as much as possible is written in a way that can be
reasoned about in isolation. Pure functions are the best way that I know to accomplish this.

Core Algorithm - Case 1
==============
Another example I've seen is the core algorithms of a system. These algorithms may be defined by domain experts, and require validation effort to ensure that the
implementation matches the intention. These algorithms are a lot of work, and must be specified carefully and tested rigorously.


Even when these algorithms end up effecting the system's state, it is worth while designing them to take in all of their required input (not relying on other state or
interaction with the rest of the system) and to produce a structure describing their result instead of acting on it while the algorithm runs.


I have seen situations where an algorithm is only partially pure- parts are factored out into pure functions and part is not. The parts that were pure were easier
to re-use as the project matured, while the parts that were not couldn't be repurposed without a major rewrite late on in the project. Had the whole algorithm been
kept pure, it could have been run by request of the user and reported its results instead of acting on them. This would have given more insight into the system that
is not available if the algorithm has its actions built in.


This left the system less useable then it might have been. The system was a high assurance piece of software, and we couldn't afford to re-write it,
so it was left as is.  This is where my mistake was only making part of the code pure. The C language does not help you write pure code, and it doesn't make
factoring code out terribly easy as well with its limited abilities for abstraction, but its worth the effort if you can do it.


The lesson for me here was that keeping as much code pure as possible would have enabled it to be tested in isolation and reasoned about locally, allowing
it to be moved or re-used without having to ensure that it operated the same in the new configuration. That additional effort it a hidden cost to side-effecting
code that can make it completely unmaintainable in a large enough scale (I have seen this first hand as well).

Core Algorithm - Case 2
===============
Another example from that project was an algorithm that integrates an equation of motion for the vehicle it is on to predict its future positions. This algorithm was written
as a library with all pure functions from the beginning- I was not going to repeat my mistake from the previous example. 


The result was something that could be tested as a whole and in parts in the units tests, both with fixed inputs and random inputs. It was ported to a laptop
visualization with nearly no effort to explore and understand the results it would give in different situations. All of this left me very confident in its
definition, and confident that it would continue to work in operation- no latent dependance on the system's state is possible if you don't depend on state
at all.

Serial Communications
=====================
One last example is code that recieves data on a serial port (or over TCP) and validates it before sending it on. This kind of code can be implemented as a state machine
which transitions states as it receives different parts of a packet- first a sync word, then a header with a length, then the data, then a checksum or CRC.


This is an interesting example for several reasons- one is that it involves hardware, which one might think as difficult to handle with pure functions, and that it uses a 
state machine, meaning it relies on state. However, if the code to receive data is decoupled from this state machine then the state machine can be implemented as a pure function
that takes in the current state (and usually some description of the processing so far), and produces a new state and a new description.


This design, as in the above cases, allows a large portion of the code to be easily tested- all state transitions can be tested in different situations. Good data can be injected
during a test, such as from a file, and random data can be created to test edge cases.


Usually this kind of data is injected into the interface itself, which would work. However, if the system doesn't work then you have to ask whether its the code or the interface.
If the code can be tested seperately you can have more confidence in it from the start, and you can add test cases to the code as you find them, rather then relying on someone
injecting all the test cases using a simulator every time they run the code.

Conclusion
==========
This is just the tip of the iceburg on this subject in terms of the application so of purity in embedded systems, and in applying lessons from functional programming to
embedded systems programming. I've been looking at other examples on a new project where I've found that my designs differ depending on whether I'm wearing my
flight software systems hat or my functional programming hat, and the latter designs seem to have all the advantages I've described above.

