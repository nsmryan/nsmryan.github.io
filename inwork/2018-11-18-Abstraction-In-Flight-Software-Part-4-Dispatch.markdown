---
title: Abstraction in Flight Software 4- Handles
author: Noah Ryan
---
This post is the fourth in a series talking about abstraction mechanisms that I have seen in flight software systems.


The topic of this post is a mechanism called a handle. This is the same use of that word as in a file handle, where
the effect of a function called on that handle depends on what the handle refers to. We will see that while handles
are used to allow one module to control resources for other modules, it also allows a kind of dispatch based on
how the handle was initialized that has other uses.


The idea is to have a module make direct use of an interface such as a hardware driver, but to fill in that interface
at runtime. The interface can be called directly, but the result of a call depends on a piece of data provided with every
function in the interface which is used in some way to determine the effect of the call. A great example of this is
the VxWorks iosLib library. You register a set of functions which provide the
implementation of the create/open/close/read/write/ioctl/delete functions. Then, when you open a device, the handle
that is returned from open can be passed to other functions like read or write, and the correct function will be called
for the particular device.


This post will discuss how this works, and a more general application of this kind of design that I have been using
recently with some success.


Handles
===
A handle mechanism consists of a series of functions defining an interface, as well as a way to re-purpose those
functions depending on the runtime context. There is a bundle of information provided by one module to another,
usually through a kind of token whose interpretation is known only to the providing module, and which is
passed back to the providing module through its interface. The bundle of information is hidden from outside modules and
is only available for manipulation through its interface.


It can be used to create a kind of dependancy injection situation where the result of using an interface depends on information
provided to the module, allowing you to provide different handles to get different results.
All of this (hidden state, dispatch based on runtime information) will make this abstraction sound like a lot of other abstractions
(especially vtables, traits/typeclasses in certain situations, and forms of dynamic dispatch), and I hope to cover these similarities in this
post. In the code that uses a handle it will certainly look like an OOP object, where the handle takes the place of a 'self' argument, however,
this similarity seems skin deep, and we will see that they do not have the same properties as objects in the large.


To name the two modules involved in this, we could say that the module providing and using the handle is a driver, and
the functions that can be used with the handle are its interface.  The module that uses the handle will just be called the user.


The handle itself is a token provided by the driver to the user module which can be passed back to the driver through an interface
for the driver to perform a particular action using the information referenced by the handle. In a sense, the handle bundles
up state which is hidden from everyone except the driver.


# VxWorks Example
The main example that I've worked with is the VxWorks driver system where the functions (open/close/read/write/etc) take
an integer handle which is used to call the correct function for a particular driver. This system is very convienent for
certain types of devices, and it is not particularly complex to use. It does have some limitations, however, such as the
need to use ioctl as an 'escape hatch' when the calls exposed by this mechanism don't cover certain functionality. Whenever
a driver needs additional functionality that is not one of the functions defined in the iosLib, they provide an identifier
and an argument to ioctl, which then has to dispatch off of that information. The argument can of course be a pointer to
a struct, allowing effectively multiple arguments. The problem here is that each new function needs an enum value and potentially
a struct, and adding functions goes through a switch statement instead of just being a new function. In other words, the 
system isn't extensible for individual drivers.


Certainly file handles in, say, Linux also may be references to different systems in the "all things are files" (or "many things are files")
philosophy. I don't know much about the details of this mechanism, but I imagine its very similar, although likely much more complex.



# What's in a Handle?
There are multiple ways for a handle to be implemented. A handle is an opaque object that
the application has to treat essentially as a symbol- their only property is that they are unique and are only equal to themselves.
However, their internal structure is known by the module that manages them. I know of two ways for this module to interpret a handle.


### Handles as a Reference to a Hidden Resource
This is a common way to deal with handles, and has some advantages. The module providing handles can hide details about allocation and
deallocation, and details on exactly how a function call translates into an action using the handle. However, it does put some 
complexity on the module providing the handles- you expect to be able to allocate and deallocate handles and to have that module
capable of providing as many handles as needed, and to track allocation perhaps reuse handles that have been deallocated.


Handles are usually of type 'int' in C, where negative numbers indicate an error. In a language with algebraic data types we could use
unsigned integers. Keeping the handle itself small allows it to be passed around the program, stored in other structures, and printed out
without.



### Handles as a Structure of Functions
Another way to implement handles, which is method I have been using, is to use a pointer to a structure containing functions. This keeps the
handle small just as in the previous case, but does not require the centralized resource management. This strategy makes the handle a
usable thing by itself, without needing interpretation by another module. This has its own drawbacks- users of the
handle have to track their own resources, and there is no central registery of handles that can be used to record usage information or
track statistics, or anything like that.


One reason that I have been using this design is that I intend there to be many different types of handles, each with their own interface.
If each type of handle had to implement resource tracking, it would add complexity linearly with the number of handle types. Even if there
was a single implementation of resource tracking, perhaps dealing with "void\*" types, the user would have to think about whether there was
a global registery, or many local registeries, and they may even have to track which registery a particular handle comes from. There might be
multithreading issues that come up as well.

# Architectural Implications
Its interesting to see the implications of each of these mechanisms on the large scale design of a software system. I have not seen handles
used in a pervasive way in flight software, but I think they have the potential to have at least as large an effect as a message bus. 


There is an interesting distinction here for the level at which a handle operates vs the level a message bus operates- the message bus is a large
scale mechanism that facilitates a certain kind of information transfer, bus does not help you abstract away function calls or general interfaces
like hardware devices or operating system interfaces. Message bus' also don't help you abstract the interface of a module that provides a service
unless that interface becomes a protocol for how you talk to the module, which is a fairly complex way to implement a module.


A handle, on the other hand, abstracts direct function calls and the direct use of a module's interface. This means that it can help when abstracting
something like performance sensitive code (although it does have a small cost) or code that makes direct calls to an operating system, hardware driver,
or a module where we want to abstract the details of which module or which function is being called. 


# Inspiration
The thing that led me to thinking about handles and what use they might have in flight software was working on the SafeGuard project, a UAV geo-fencing 
system which is designed for high assurance. I won't go into too much detail, but the code makes use of a dynamics algorithm for predicting the trajectory
of the vehicle, and it makes use of an algorithm for determining whether a point is within a distance from a polygon (for testing whether the vehicle has
left a boundary). These two algorithms are used in a large algorithm that collect and calculates the inputs to these algorithm, and then
decides what actions to take based on their results.


The dynamics and polygon algorithms are libraries that that inputs and provide outputs, and have no side effects. This makes them easy to test, predictable,
and reliable. The higher level algorithm, however, has to deal with incoming sensor data that may be stale, invalid, or nonsensical. It has to ensure that it
runs when it is supposed to run, and that it doesn't take too long to come up with an answer. It has to produce telemetry describing the inputs and outputs
of all the calculations, as well as its own state. It also has to take action if it determines that there is a problem with the vehicles current state, 
calling another modules interface to report problems it detected.


All of this means that the algorithm is not a pure mapping of input to output. I have tried over time to factor the algorithm into a pure and impure part, and
every place in the code where I have been able to do this has been easier to test, better factored, and easier to adapt to changing requirements.

However, there is a level at which the algorithm is simply not a pure function, and we have to deal with its dependancies on other modules, its use of
tasks/semaphores/message queues and other operating system functionality, and its telemetry. Thinking about this lead me to realize that the algorithm
could be written in such a way that each of these effectful function calls was abstracted out, so that we could feed in test data, simulated data, or
real data as desired. I didn't want this abstraction to result in complex or unusual code- it would be easier to adopt if it looked like normal code but 
somehow had this magical property that we could place it in a test harness and inject data, and then run the exact same code without modification in flight.


This lead me to design a kind of handle system in which code like operating system interface, and the interfaces of other modules, are abstracted into an interface
of functions that take a handle, where the handle is used to determine what happened at runtime when these functions are called. This way, the algorithm binds
directly to the interface (it needs to bind to something) but it doesn't require the other modules to be up an running, or the operating system to be the one
it was designed for, as long as we can provide an implementation that satisfies the needs of the algorithm.


I believe this could allow a whole series of amazing oppertunities for this algorithm:

* We could run it outside of the target system, allowing us to test and study it on a laptop instead of an embedded system. We could even create a visualization
that we could tweak to get a better understanding of what happens under the hood. I've done this stuff before with other algorithms, but this one has been difficult before
at first look it relies on VxWorks and the rest of the flight software to operate.

* It would allow us to write unit tests independant of the rest of the system. We could test out properties about detecting errors, overstepping its time bounds, 
or injecting invalid data in a reproducable way. These tests could be run at any time, not just with the hardware available, and would be amenable to CI.

* It would allow us to run the whole algorithm faster then real time. This is something we have talked about, and we have some hardware-in-the-loop simulation, 
but this is all done in real time as it uses the real hardware.

* It should make the algorithm much more portable. We have talked about whether the algorithm could be made into a module that could be moved between systems,
and I believe that this is possible if its dependancies were replaced by handle mechanisms. The handles would be provided at initialization, and would hide
the operating system and external interfaces. They could even be constructed with callbacks, allowing the user code to essentially drive the algorithm and collect its
data.


## Tradeoffs

As with any design, there are tradeoffs to be considered.

### Pros
  * 

### Cons
  * 

# Conclusion

