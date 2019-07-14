+++
title = "Rustic Flight Software Concept"
[taxonomies]
categories = ["Rust", "Flight Software"]
+++
I have had a vision of a flight software system written in Rust that I wanted to write down.
The concept is a little rough, so this post is also a way to feel out the design and how it
fits into flight software design in general.


This is coming from a lot of thought into what makes a good flight software system, and from
working on and reading code from multiple systems, including CFS (a flight software system
developed by NASA). The result is something that combines ideas from several systems,
and from experience building and testing these systems, but with a re-imagining
in Rust.


# Modules vs Layers
One of the main things I see in the architecture of flight software systems, and generally
in embedded systems, is that the system is a series of modules which communicate through
function calls or messages. Function calls give sychronious communication when necessary,
and messages (say, CCSDS packets) give asynchronous communication.


## Types of modules
There are several types of modules in these systems, which I will attempt to enumerate:


  * Hardware abstraction modules- these can be drivers, generic libaries wrapping hardware,
    or may have project-specific logic for talking to a particular piece of hardware over
    a particular link
  * Infrastructure modules- these provide services to other modules. This can be things like
    message routing, configuration, time, software/event messages, logging, memory block allocation/deallocation,
    and can include many other things. These modules tend to be directly depended on, and in a sense they
    fix the architecture in place- while other modules can be added and removed between projects, the
    architectural modules are usually deeply embedded in the dependancies and logic of other modules.
  * Project modules- these are specific to a project, and are not intended to be portable or abstract.
    They implement specific science objectives or project requirements. They may be tightly coupled
    to each other to accomplish highly coordinated and precise tasks.
  * Library modules- these provide algorithms or interfaces, but have no tasks. They are often, but
    not always, very portable and testable.

## CFE/CFS Approach
CFS factors the abstraction into the OSAL (Operating System Abstraction Layer) and PSP (Platform Support
Package) code, and builds the rest of the system on top of these. The next layer up is the CFE (Core
Flight Executive) which factors all of the infrastructure modules into a single tightly coupled group,
essentially removing coupling from the rest of the system. This feels like a kind of quotient group,
if you have some abstract algebra.

The nice thing about this is that while all modules rely on dependance to CFE, many things that are otherwise
services become independant by working through CFE's services- task schedule is done through the software bus,
and so is telemetry monitoring, health and status generation, and many other features.


This is not a bad architecture, but I think there is value in modularity over laying, and I think there are alternative
architectures which have some very nice properties along those lines.

## Purely Modular Approach
In a purely modular approach to this problem, each module would expose an API that other modules could depend on.
Rather then layering the system, each module could receive an implementation of each interface it uses, perhaps
at runtime in a dependancy injection style. This lack of laying creates a web of modules rather then a heirarchy,
which should assist in swapping out modules and implementations.


### Potential Advantages
The advantage to this is that modules would be exchangable even in the core infrastructure, and no module would be
treated specially. The other advantage would be testing- each module could provide a kind of mock implementation
as well as a real one, and each module that uses an interface could test without the other module's code running by
using this mocked implemnatation.


Modularity here is not a purely acedemic goal. For example, CFS has a single monolithic abstraction layer, which helps
make the task of porting straightforward (it is clear what you need to implement to create a new implementation), but
it means that it is very hard to extend without modifying all other implementations. It also means you take around
all components provided, even though I know many systems which do not use them all.


The other advantage I could see is potentially huge- composability of modules. This would either take the form
of interfaces implemented in terms of other interfaces, or interfaces composed together to provide the final
implmementation. One place where this could be helpful is to create an implementation that logged function
calls in some way before passing the data around- none of the flight software would have to change, but you
could get instrumentation that visualized or at least recorded interactions between components with very
little effort. An example of composing interfaces might just be that a configuration manager interface might
be implemented in terms of a file system interface, or an interface that both forwards data to the intended
target and records it to a log file for later downlink.


### Loose Coupling and Types
Interestingly, it seems that this kind of design involve systems that talk, but are developed without knowledge of
each other types. Configuration management won't know about the configuration structures it provides, a software
bus would not nescessarily know about the message types it routes, etc. Currently this is often done in C through pointer
casting. I'm not sure what this would look like in Rust- either through generics, type ids or Any types, or perhaps
some unsafe code if all else fails.



# Rustic Flight Software
Here is the idea- each module takes a series of interfaces at startup and uses them for all outside communication.
This acts as a kind of software abstraction layer- I imagine hardware could be abstracted in a HAL (Hardware Abstraction
Layer) approach as is currently being used in the Rust ecosystem, so I'm talking only about software abstraction here.



The software abstraction might take the form of types implementing a particular interface, or could perhaps
be a Trait object.  Either way, it would contain a way to register and discover services provided elsewhere in
the system.


To support this concept, I think the system would use a registry of interfaces, where each module provides a way to
supply implementations of one or more interfaces, and modules can request an implementation of one or more interfaces.
I would imagine that the system requires that all modules get each interface they require, and that no interface is
provided more then once.


For hardware there is an advantage to multiple implementations of the same interface in
case the system has multiple components that use the same hardware abstraction but are different under the hood,
but for software I feel that having multiple implementations is too likely to be a source of bugs and should be avoided
in flight software.


## Interface Registry
My current thinking is that the interface registry is a map from type ids to Trait objects. Each module might expose
a function that takes a mutable reference to this registry and inserts its own implementation of its interfaces.
If an implementation already exists, this is an error at startup.


Then each module provides a function that takes an immutable reference to this registry and pull out a reference
to each interface it needs to use. A module might request access to the software message interface to report
its progress and errors, the configuration interface to get access to its configuration table, the software bus
interface to send and receive packets, and the time interface to generate timestamps in the system's time reference.


One nice thing that comes out of this registery is that a system needs to only implement interfaces it uses-
the selection of modules for a new system is very fine grain and matches only what the system needs without
taking in a group of required modules. Ideally the dependacy information between modules would be easily
discoverable or reportable in this system, as they would form a web of dependancy which the user would have to
be aware of.


### Startup
Ideally each module could be statically linked, creating a single executable from the whole system, or could be loaded
as a shared object.


If loaded as a shared object, the module's functions to provide interfaces and request interface could
be called- all module's functions to provide interfaces would be called first, and then all module's functions to request
interface, and then finally perhaps a function to initialize the modules.


If loaded as a static object, the modules might just be provided their implementations directly.
I imagine that in a flight software system this registry might also be filled out manually in a top level function
so there is no ambiguity about what it contains- sometimes flexibility is more dangerous then its worth.


# Testing
One of the advantages to this system is testability. Each module is self contained- it requires linking against
an interface definition, but not an implementation, so it can be mocked out and tested independantly.


This would allow testing that is currently very difficult. In CFS there is an extensive testing system which
does someting similar, but I think the design in this post allows a much lower effort way to do this kind
of module testing.


Ideally each module could be tested on the development system, with as much unit testing as possible. The
tests could also be run on the target system, followed by system level tests of the combined system.


One thing that would be a huge gain that I haven't seen done is that a group of modules could be started,
each depending on each other, but with some modules mocked out, and then the group could be tested together.
This could lead a huge amount of flexibility in testing where whole sections of the system could be started and
stopped for a single test of their interfaces.


I find that it is commonly true that interfaces betweeen components are a source of bugs, so this kind of
isolated interface testing could be a huge gain for a Rustic Flight Software.


# Implementation
I've done some experiements implementing this kind of archtitecture in C, and I found that while it is possible,
it is certainly not what I'm used to doing in flight software. There is a certain amount of indirection- in my
implementation abstracted function calls take a pointer to a struct containing function pointers (basically
a Trait object). 


This does work, but I haven't been able to think of a path in which this effort goes anywhere- I would have to
re-invent an entire flight software system for this to work. While it would be cool to do this, and maybe run
it on some hobby electronics system, if I'm going to put this concept into practice
I would rather do it in Rust and see if a Rustic Flight Software system is doable.


I currently have no plans to start serious work on this concept- I hope to play around with it and see where it goes,
perhaps building tiny systems to see where it works and where it doesn't. However, I have so many other
projects with more immediate gains to be had, while this one is more an idle concept for now. That is one
of the reasons I wanted to write this post and get the idea down while it incubates in my subconcious.


## Prototype
A minimum prototype of this concept might have the following pieces:

  * A crate implementating the interface registry concept.
  * A group of crates with interface traits and types, as well as the testing implementation
    of the interface.
  * A group of crates with implementations of those interfaces. This would be limited to some
    basic interface for the prototype.
  * A crate that combines these pieces into a single project, depending on interface and implementation
    crates, and loading (dynamically or statically) a system made out of these parts.


The components I would probably start with would be a software message/event message component (because
it should be simple), a software bus (because it is a fairly central service), and perhaps a time
interface (because it is different from the other two). 


The final system would ideally run in Window and Linux, and do some kind of communication between components.
If it was integrated with COSMOS and could be commanded and provided telemetry it would go a long way
to feeling like a legitimate system.


The goals for the prototype would be to see the loose coupling of the module system in work, see how Rust's
type system helps or impedes modularity in this design, and get some evidence to suggest how Rust fits
into this kind of software. I would be interested in things like command/telemetry generation, inspection
of types, re-use between ground and flight software, testing, safety in memory use and concurrency,
and what difference show up when flight software concepts are implemented in Rust.


# Conclusion
Hopefully this post presents a useful flight software system design and the start of how a Rust flight software
system might have advantages over what is currently available.


I would very much like to make progress on this, and I will try to keep this blog updated with new posts
if I do.
