+++
title = "Abstraction in Flight Software 1- Direct Coupling"
[taxonomies]
categories = ["NASA", "Flight Software"]
+++
This is the first in what I hope is a series of posts on the use of abstraction in that I have seen in 
flight software systems. I plan to go over each mechanism that I have seen in a post, ending
with a method that I have been using recently that I have not seen in other flight software systems.


The flight software that I have worked with includes Core Flight Software (CFS), CALIPSO, SAGE3, and SafeGuard.
I will try to use CFS for most examples as it is open source and available for anyone to use. It also has examples
of all the techniques I want to talk about.


I will be talking mostly in terms of C, and a limited subset of C++ without classes and objects. I think the ideas
here can be translated into the abstractions of other languages, but I want to avoid encoding the abstractions in terms
of a languages mechanisms- classes, traits, typeclasses, higher-order functions, protocols, etc- for several reasons: 
1) CFS and other many other flight software systems are written in C, or if they are in C++ they often to not include
much in the way of OOP of other abstractions like templates, 2) abstraction has a cost in complexity, and in flight software
complexity comes at a premium, 3) I want to start with C where we have very few means of abstraction, and then see what happens
when we move into other languages.


Each abstraction mechanism has different implications in the high level design, and its worth considering
this when designing flight software. These concepts aren't specific to flight software, but I want to talk about them
in terms of flight software because that domain a unique set of concerns and challenges that are worth exploring and sharing.
Flight software systems have a certain style that I have not see in other software, although it shares many aspects with other
embedded system software, and even when a technique is well known or commonly used, it is still interesting to talk about
it in terms of a specific domain and how it plays out there.


One of the reasons that I have been thinking about this stuff is that the coupling between parts of software have some
lasting affect on the large scale structure of the software, and the coupling influences its design and the design of
new components. These components have explicit and implicit coupling to other components, and to the overall architecture,
in ways that can prevent them from being updated with new requirements, ported to a new operating system, or ported to
a new board without a significant amount of effort. It can also make them hard to test because they aren't designed to be
run in isolation- they depend so much on each other that most tests end up being system-level tests because a very limited
subset of functionality makes senes by itself. 


The Basics
===
There are some basic ideas that need to be laid down before we begin. The main one is that the design of
flight software systems is invariably a series of modules that communicate through 
function calls, shared resources (such as shared memory), and structures or packets of data. This communication can be through synchronization
mechanism such as sempahore or message queues, or directly without synchronization.

Each component implements some aspect of the system- either a library (such as a complex algorithm), a service provided
to other modules (such as a configuration manager that distributes configuration data to other components), a hardware
interface (such as an external interface or an onboard device), or some logic specific to the system (such as a component
for controlling the system's mode). A module can be multiple of these, like a library
that wraps up a hardware device, but generally these seem to be the kinds of modules that you see.


Many of these components have fairly complex designs- many modules will tie into multiple mechanisms provided by other modules. For example,
if a module controls a serial interface to a subsystem, that module might also send software messages, request tables, provide telemetry,
receive and execute commands and provide subsystem information to other modules. In other words, a module isn't just a collection of functionality,
but rather a fairly complex actor whose exact shape and role depend on a global concept of how components fit into the system. There
are some exceptions, like a component that truely is a library and doesn't tie into any other components. Even libraries can sometimes
tie into a software message system for reporting errors- software messages provide a great way to record local information about an error
as soon as it occurs, and if you want to avoid tieing a library to a software message mechanism it may have to propagate a lot of
error information to get a similar level of reporting.


There are many considerations to take into account for these modules. They may be custom software designed for a particular mission or
a unique piece of hardware, or they may be generic and reuseable. They may tie into the operating system and board that they live in,
or they may abstract these out in some way. They may also be tied into the rest of the software- for many modules, they are designed to 
run in a system with a selection of other modules, which themselves may depend on yet other modules. These kind of dependancies are one
of the main things I wanted to talk about in this post.



Direct Coupling
===
The first technique is the most obvious- direct use of one modules definitions from another module. A module will have a series of
header files, some of which are intended to be included by by other modules, and the symbols exported by these headers will be given
a namedspace in some way- either by prefixing them with the name of the module (TBM for Table Manager, for example) by using a namespace in C++,
or by defining a class. These definitions are the interface that other modules
can depend on. This is how the core components of CFS are used- the CFE modules are coupled directly to all other modules. This is also
true of OSAL and the PSP within CFS.


One consideration here is the direction of data flow, which can be push or pull (one module provides data to
the other, or a module requests data from the other).  Two modules may be closely coupled to coordinate their actions, so that
one module can communicate directly to another through direct function calls. A module may provide a service that other modules use
such as software messages aka event messages. A module may also be a libray which is layered upon by other modules, coupling directly to 
the lower layer module.


## Push vs Pull
When a module provides a service to other modules, then the difference between pushing data and pulling it is very important. 
I want to go over this distinction a bit as it becomes important with other abstraction mechanisms.


Imagine a
telemetry module that requires an update to telemetry from every other component in a system. If the components push data to it, they
call a function it provides. This means that all other modules are directly coupled to the telemetry module. If the telemetry module
pulls data, it will have to call a function in each other module. This second design implies that while the other modules are not
coupled explicitly in the sense of using a symbol in another module, they are designed with a function that is needed by another module,
which is an implicit coupling.


The pulling design has the advantage of being synchronous- the other modules must provide data when the telemetry module wants it.
This means that module may have to protect access to their telemetry through a semaphore, or to construct their telemetry when it is
requested. However, this means that there is some place in the telemetry module that calls a function from all other modules, and this
code must be updated to account for any module added or removed. This by itself is not too bad- its very repetitive code, and at least
its clear what the depedancy is and how the data is being transferred between modules. The main problem I have with this kind of thing
is that when there are many places in a project where modules can depend on others, and it is not clear how to determine how changes to a
module affect all places in other modules that have this kind of dependancy.


The push design has the advantage of being asynchronous- the other modules can provide updates when they are ready and they know that their
data is valid. This can add some complexity to the telemetry module, however, which must handle the possibilty of zero, one, or multiple
updates from a components telemetry between each time that it uses the telemetry updates. For example, it may only keep the most recent
update, but signal a problem if zero updates are received, or if more then one update is receives.

## Tradeoffs

There are several tradeoffs being made here. 

### Pros
  * This is the simplest way for one module to depend on another- there is no abstraction or indirection.
  * The data path is explicit. This means that you can trace the transfer of data through a system. If data, such as a telemetry
  packet from a subsystem, passes through multiple modules, you can trace how it moves through the system statically. This helps
  with reviewing software, reasoning about it, and in debugging it.
  * The dependancies between modules are easy to find. If a module includes another modules header, then it depends on that module.
  The nice thing about this is that there are can subtlies to how an interface must operate, and being able to trace that interface
  directly to its implementation reduces the mental overhead in understanding their interaction.
  * When one module changes, such a change to a function signature, the other modules must be changed to conform. If the change
  prevents other modules from compiling, then this points you to every place you need to change in other to propagate the change. If
  not, at least you can search for a modules functions and change each place that they occur.
  * Local reasoning is possible at the use site- it is easy to reason about the use of data in the code that uses it, as you can trace
  exactly what will happen. This is similar to other pros, but I want to make the distinction that a certain kind of local reasoning is
  possible here, as different mechanisms make different kinds of reasoning easy or hard.

### Cons
  * The obvious con here is that with no indirection, changes to one module affect the other. 
  * The close copuling means that a component written to call directly into another component cannot be used without that component.
  If a module is to be ported to another system, you either need to port the other module, or remove or modify it everywhere it depends
  on the other module.
  * In some cases the dependance of one module is on every other module in the system. For example, a telemetry module that receives 
  a telemetry update from all other modules has a large number of dependancies. 
  * While local reasoning is possible where data is used, it is not easy in other cases. For example, in our telemetry module example, any
  new module that is written must either provide a telemetry update, or a way to provide telemetry. This means that when thinking about one module,
  you have to be aware of the design of another, and potentially many other modules. When there are many dependancies like this in a system it can be
  difficult to know how a change in one module needs to affect other modules as that logic is spread throughout the codebase. 
  * While a module's design can be re-used between projects, the modules themselves will likely need modification. The changes in project-specific
  modules and project-specific requirements will likely require changes to most or all modules. This make software re-use difficult and means that
  simple changes can propagate into large changes to a system.
  * Similar to the above, small changes can propagate to large architectural changes. Changing the path of data through a system will require
  changes to all modules that touch that data. This can be good, as flight software is usually higher assurance then other software and if a
  change must be made then its affect on the whole system needs to be considered, but it makes software development slow and costly.


## Means of Abstraction
Even when modules are directly coupled with each other, there is still a potential for a kind of abstraction through header files. The header file/
implementation file mechanism in principal always allows you to switch out an implementation for another. Generally I've found that this is
only done when the code is written with the intend of switching the implementation, and it is rare that you need to switch out an implementation
if you didn't design with that in mind. Thats not to say I have seen it done, just that if the software is not written with this in mind, then the
interface can be so specific that it doesn't usually make sense to switch it.


With that said, code can certainly be designed with the intent that the implementation will be swapped out. This is exactly the means of abstraction
used in the CFS Operating System Abstraction Layer (OSAL). Other modules in the software depend directly on OSAL symbols (functions, type, etc), and the OSAL itself
depends directly on operating system symbols, and yet it provides an abstraction. In effect it provides a level of indirection for operating system symbols
which can be bound at compile time to the symbols of different operating systems. In practice, it does more then that but using operating system mechanisms
to implement its functionality (there is more to it then simply renaming) partially because it provides a consistent interface between operating
system with different behaviors.


I have also seen this kind of abstraction used to decouple components so that one module is shielded from changes to requirements- a module may provide
a header file that is implemented by different components at different times in a project due to changes in hardware. One of the nice things about this
design is that if you don't have to update a module, you don't have to re-review it, so this kind of decoupling reduces the work required for certain
kinds of software updates.


This kind of abstraction has some advantages- the binding is still static, and yet provides a way to re-use code between systems. My experience has been that
this does work- I was able to port CFS to a new system with very little effort because there was an implementation of the OSAL interface for POSIX that
worked on that board. There are some issues that come up with providing an interface to distinct systems, where the result can be subtly different, or must
provide a pared down interface that only provides feature shared by all systems, but this is a more general problem then the choice of abstraction.


One issue that comes up here that will be important later is that it provides only one implementation for each interface- you can only compile in one
implementation at a time. This is stil useful even within a project, such as compiling again a test harness, but means that it can't include certain
hardware or software interfaces that may have multiple implementations at runtime. This would be the case with operating system driver, for example,
which might provide the same interface to multiple devices which have different implementations.


# Conclusion
This post lays some groundwork in how flight software is structured and what kinds of concerns I have generally seen in its design. Now that we have talked
a bit about the most tightly coupled way to design software, we can move on to what indirections we can introduce, and look at what tradeoffs they provide
compared to a tightly coupled system.


