+++
title = "CFE/CFS Architecture"
[taxonomies]
categories = ["NASA", "Flight Software"]
+++
This post is a followup to the previous post introducing CFE/CFS.
In this post I want to start talking about the design of CFE/CFS and
what implications its design decisions have when using this software.


I will go over some possible architectures one could use for flight software,
and then go a little bit into CFE/CFS's architecture in terms of static and
dynamics dependancies between software components. Part of the point here is
to provide more detail on how CFE/CFS is organized beyond saying that it is
a publish-subscribe system with a software bus- the reality is more complex then
that.


# Possible Flight Software Architectures
When developing a flight software system, there are a large number of
possible designs and tradeoffs that can be made. In this way it is just like
any other type of software even though it has its own unique set of
challenges and pressures. Architectures seem to have evolved over the years,
each with its own advantages and disadvantages.


Lets go over some possible architectures and their tradeoffs. There could very well
be other architectures out there, but these are the basic designs that I can
think of.


## Monolithic
In this architecture, we write one monolithic system which controls the entire
system. All features are tightly coupled, and the system is likely the least
portable between projects, operating systems, or hardware.


In this architecture, we might have a single task/thread/process which recieves commands,
produces telemetry, and does all the hardware control in one place. This provides
the greatest degree of control, potentially the least overhead, and the fewest
mental overhead as it has no mechanisms to learn or decoupling to reason about.


This architecture would be the quickest to get up and running if starting from
scratch and creating a system with a limit set of functionality as it does not
require developing additional infrastructure beyond the needs of the specific
application.


Of course, there are some significant disadvantages as a project gets bigger, as it
is ported between projects and has to be largely rewritten, and as its architecture
requires large changes to accomidate new requirements or functionality. It is the least
flexible and provides no abstractions to use when reasoning about the codebase.


## Modules
All embedded software systems that I've ever seen split off functionality into
modules.  A module contains internal state, and communicates with other modules
through shared memory, message queues and other synchronization primitives, and
function called- whatever is appropriate for the specific need.


Each hardware interface will get a module, each complex algorithm, each piece
of identifiable functionality like task scheduling or health monitoring. The
decomposition of the system into modules is usually done early in the project
to organize and schedule software development.  Having an architecture like
this assists in reasoning about the software, understanding execution and
dependancies between its pieces, helps scheduling which functionality should be
developed at what time, and manages complexity by sectioning off software into
islands which can be developed, reviewed and understood mostly in isolation.


Modules can vary in size enormously There is no limit to how complex a module can be, 
but the ones I see are usually between 1K and 10K lines of code. In the systems I have 
worked in there have been ~20 modules, and somewhere between 20K to 40K lines of code in total
(logical lines of code counted by cloc).


Some modules provide a library of functions to use by other modules, some provide core services
used throughout the system, and some provide project-specific functionality. The libraries and core modules
can often be re-used between projects, providing a consistent architecture and set of functionality
that can be delivered for each system.


## Software Bus
The Software Bus architecture is a module system as discussed above, but one which has a module
which performs communication between other modules. In a way, the task of communicating between modules
is factored out into a single module rather then spread through the systems as a cross-cutting concern.


A software bus is usually (as in the case of CFE) a publish-subscribe system. Modules can indicate to the
software bus module that they will produce a certain kind of data (perhaps indicated by a unique ID),
and other modules can request that they be provided each packet with that ID.


With this design, the sender of a packet does not necessarily know where it will be sent, and the receiver
does not know where the packet originated. This has a number of advantages, and of course it has a number 
of disadvantages.


The advantages are that we can add new components more easily- the decoupling between
modules means that a new component does not usually require changes in any other component. Sometimes you
can develop a new module and plug it into the system, and when that happens you are realizing the 
benefits of this module.


The disadvantages come from places in the code where you benefit from tight coupling- since you no
longer know the source and destination of every packet, it can be difficult to tell exactly what the
system is doing. You need knowledge of every packet published and every place where a subscription
occurs in order to understand the control flow of the system. In a way this is okay- the
software bus module can report all links between all modules. However, if you need control over
communication, or you need communication that occurs in a particular way, you may want to bypass
the software bus.


Bypassing the software bus leads to the next part of this post- CFE/CFS.


# CFE/CFS
The CFE/CFS system is a set of modules with a software bus in from the ground up. It is an architecture
that combines the decoupling that is available in a publish-subscribe system when possible, but makes
use of tight coupling when appropriate. When I say tight coupling here, I am referring to making
function calls to a modules exposed functions, and when I say loose coupling I am referring to communicating
through the software bus.


In particular, CFE is a series of very tightly coupled modules, and CFS Apps may be tightly coupled to CFE
apps. In addition, CFE and CFS modules are tightly coupled to the OSAL- they will make direct function calls
to OSAL functions. The intend of this design is to factor out the portion of the system that benefits most from
tight coupling into a small set of modules, called CFE, allowing other modules to be more loosely coupled.


This means that the CFE/CFS architecture is designed as an abstraction layer over the operating system with
multiple implementats, a series of tightly coupled modules providing core features, a series of modules
called CFS Apps are tightly coupled to CFE and OSAL but not to each other, and a series of project-specific
applications which are tightly coupled to OSAL and CFE, to their platform/operating system/or 
hardware, and perhaps to each other, but not to other CFS Apps.


Note that there are several places were tight coupling is used here- any module may depend directly on OSAL,
all CFE modules depend directly on each other, all CFS Apps depend on OSAL and CFE, and project specific apps
depend on OSAL, CFE, their platform, and each other if appropriate. This means that CFS is not a fully decoupled
system- rather it is a system that allows decoupling in user code when appropriate and allows tight coupling
when required.


This is an important aspect to the design in several ways. Sometimes we want something to happen *right now*,
and not just when a packet arrives at a module. Sometimes we want to pass data directly rather then packing it
up in a packet and sending it off. Sometimes we want to send large pieces of data, and while CFE provides a 
Zero Copy message passing option, sometimes we want to control memory more directly.


# Applications of De-coupling in CFE/CFS
Now that we have an idea of where the dependancies are between modules in CFE/CFS, I wanted to point out some
places where the loose coupling provided by a software bus is used in CFE/CFS.


One places is the Scheduler App. This application runs a schedule consisting of slots, each of which is associated
with a slice of time within the schedule. For example, you might have 100 slots of each 10 ms each, and you might
run these slots once per second. Within each slot there are some actions you want to take, such as producing telemetry,
polling hardware, checking the system's health, or running an algorithm.


The Scheduler App make use of loose coupling by sending a series of pre-defined commands to the software bus in each
schedule slot. In other words, it schedules by sending packets at a particular time with the assumption that the receiver
is waiting for new packets in some thread, and that the receiver will take a particular action when it receives the
Scheduler's packet. This is as opposed to a more direct approach such as releasing a binary semaphore to unblock a task.


Another example is the Data Storage App. This module recieves packets from the software bus, defined in a set of tables
(configuration files) which tell it which packet ID to ask for from the software bus. When it recieves a packet, it stores
it in log file according to rules defined in another table. This design does not rely on the source of the data, and the
senders of each packet do not know whether Data Storage is out there receiving the data or not.


# Static Coupling vs Dynamic Coupling
A quick final point I want to make here is that the design of CFE/CFS provides loose coupling at runtime, not necessarily
at compile time. In other words, when you write a CFS App, it is a CFS App and not a generic module that could be used 
within another software system. It will rely on the OSAL and CFE, at the very least, and can't be used without those
static dependancies. One thing I find interesting is architecture where we make use of loose coupling at compile time
to create modules that are not tied to a specific architecture, but that is a topic in itself.

Notice that with CFE just as most tight coupling was deliberatly factored out into a small set of modules, with OSAL
the static coupling to the operating system was factored out into a set of header files which can be given multiple 
implementation. In other words, the CFE/CFS/OSAL combination is designed to manage static coupling in a particular
way which effects what coupling you will see in your own CFS Apps. This is a monolithic form of static coupling in the
sense that if you depend on any part of OSAL, you depend on all of it. It is not a set of modules for each part of
the operating system, it is a monolithic interface and if you use it you are tied to the whole thing. This is not usually
a problem, but it is worth noticing.

# Conclusion
There is a lot more to say about CFE/CFS as a software system, but hopefully we have started to see its design at a high
level and how it manages coupling at compile time (statically) and at run time (dynamically) and what options you
have and don't have when you write CFS apps.

