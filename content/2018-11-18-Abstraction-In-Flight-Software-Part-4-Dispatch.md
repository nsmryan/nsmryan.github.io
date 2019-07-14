+++
title = "Abstraction in Flight Software 4- Handles"
[taxonomies]
categories = ["NASA", "Flight Software"]
+++
This post is the fourth in a series talking about abstraction mechanisms that I have seen in flight software systems.


The topic of this post is a mechanism called a handle. This is the same use of that word as in a file handle, where
the effect of a function called on that handle depends on what the handle refers to. We will see that while handles
are used to allow one module to control resources for other modules, it also allows a kind of dispatch based on
how the handle was initialized that has other uses.


The idea is to have a module make direct use of an interface such as a hardware driver, but to fill in that interface
at runtime. The interface can be called directly, but the result of a call depends on a piece of data provided with every
function in the interface which is used in some way to determine the effect of the call. A great example of this is
the VxWorks [iosLib](https://www.ee.ryerson.ca/~courses/ee8205/Data-Sheets/Tornado-VxWorks/vxworks/ref/iosLib.html)
library. You register a set of functions which provide the
implementation of the create/open/close/read/write/ioctl/delete functions. Then, when you open a device, the handle
that is returned from open can be passed to other functions like read or write, and the correct function will be called
for the particular device.


Another example, this time in Haskell, can be found [here](https://jaspervdj.be/posts/2018-03-08-handle-pattern.html)
with discussion of pros and cons in the context of a much more abstract language.


This post will discuss how this works, and a more general application of this kind of design that I have been using
recently with some success.


Handles
===
A handle mechanism consists of a series of functions defining an interface, as well as a way to re-purpose those
functions depending on the runtime context. There is a bundle of information provided by one module to another whose
intepretation is only known the the module that produces it. This information is passed back into the providing module
which then inteprets it to determine what functions to call. The module that receives this information does not inspect it
or use it in any way expect to pass it back to the providing module.


This can be used to create a kind of dependancy injection situation where the result of using an interface depends on information
provided to the module, allowing you to provide different handles to get different results.


All of this (hidden state, dispatch based on runtime information) will make this abstraction sound like a lot of other abstractions
(especially vtables, traits/typeclasses in certain situations, and forms of dynamic dispatch), and I hope to cover these similarities in this
post. In the code that uses a handle it will certainly look like an OOP object, where the handle takes the place of a 'self' argument, however,
this similarity seems skin deep to me, and we will see that they do not have the same properties as objects.


To name the two modules involved in this, we could say that the module providing and using the handle is a driver, and
the functions that can be used with the handle are its interface.  The module that uses the handle will just be called the user.
An example would be a serial interface, where the driver might be a module that knows how to configure and use the hardware while the
user might be a module that knows about a particular device's communication and operation and uses the driver to talk to the device.


# VxWorks Example
The main example that I've worked with is the VxWorks driver system where the functions (open/close/read/write/etc) take
an integer handle which is used to call the correct function for a particular driver. This system is very convienent for
certain types of devices, and it is not particularly complex to use.


The VxWorks functions like open take a handle, look up a struct of function pointers, and then call the corresponding
struct's 'open' function. In other words, the open function dispatches based on the handle.


It does have some limitations, however, such as the
need to use ioctl as an 'escape hatch' when the calls exposed by this mechanism don't cover certain functionality. Not
all devices are as simple as reading and writing data- if you want to program a 1553B interface, simple reading and writing is
just too limiting to describe what needs to happen.


Whenever
a driver needs additional functionality that is not one of the functions defined in the iosLib, they provide an identifier
and an argument to ioctl, which then has to dispatch off of that information. The argument can of course be a pointer to
a struct, allowing effectively multiple arguments. The problem here is that each new function needs an enum value and potentially
a struct, and adding functions goes through a switch statement instead of just being a new function. In other words, the 
system isn't directly extensible for individual drivers. We will see how to improve the situation in this post.


Certainly file handles in, say, Linux also may be references to different software systems in the "all things are files" (or "many things are files")
philosophy. I don't know much about the details of this mechanism, but I imagine its very similar, although likely much more complex.



# What's in a Handle?
There are multiple ways for a handle to be implemented.


A handle is an opaque object that
the application has to treat essentially as a symbol- their only property is that they are unique and are only equal to themselves.
Handles are always small- integers or pointers- so they can be passed around, stored in arrays, and generally used without
worrying about performance.


Their internal structure is known by the module that manages them. I know of two ways for this module to interpret a handle.


### Handles as a Reference to a Hidden Resource
With this strategy, the handle is usually an integer used internally as the index into an array of structures. These structures
have the information required by the driver to carry out function calls for the interface.


This is a common way to deal with handles, and has some advantages. The module providing handles can hide details about allocation and
deallocation, and details on exactly how a function call translates into an action using the handle. However, it does put some 
complexity on the module providing the handles- you expect to be able to allocate and deallocate handles and to have that module
capable of providing as many handles as needed, and to track allocation perhaps reuse handles that have been deallocated.


Handles are usually of type 'int' in C, where negative numbers indicate an error. In a language with algebraic data types we could use
unsigned integers. Keeping the handle itself small allows it to be passed around the program, stored in other structures, and printed
to the screen.


### Handles as a Structure of Functions
Another way to implement handles, which is method I have been using, is to use a pointer to a structure containing functions. This keeps the
handle small just as in the previous case, but does not require the centralized resource management. The handle is itself the resource
that we would be looking up with the 'handle as int' strategy.


This strategy makes the handle a
usable thing by itself, without needing interpretation by another module. This has its own drawbacks- users of the
handle have to track their own resources, and there is no central registery of handles that can be used to record usage information or
track statistics. This is not so bad, however, as it means lower complexity in drivers.


One reason that I have been using this design is that I intend there to be many different types of handles, each with their own interface.
If each type of handle had to implement resource tracking it would add complexity linearly with the number of handle types. Even if there
was a single implementation of resource tracking, perhaps dealing with "void\*" types, the user would have to think about whether there was
a global registery, or many local registeries, and they may even have to track which registery a particular handle comes from. There might be
multithreading issues that come up as well. Keeping the handles separate means that they are self contained and can be treated in isolation, which
seems desirable when there are many types of handles, each implementing one of many types of interfaces.


# Building a Handle
There are many abstraction mechanisms that provide different types of dispatch, where each one could be used to provide a similar
result to a handle system. If C had traits/typeclasses, I might even prefer them to handles, and use static resolution of dispatch
rather then dynamic.


The main distinctions between classes/traits/mixins/etc seems to be how they are built and what operations can be performed on them.
Handles are build by defining a struct with an interface of function pointers and possibly other data. This struct is then filled in
at runtime with the functions to call. There is no direct notion of inheritance or composition, although you could perform these
operations explicitly with enough code.


Composition in particular is interesting for handles- I can imagine composing handles that perform transformations or processing of
data as it is passed down a chain of handles, especially for debugging.


The particular implementation I've been using will have to wait to another post, but it makes use of forward declaration and function
pointers to define a series of functions that take a pointer to a struct, where each function simply extracts a function pointer within
that struct and calls it, passing the struct pointer and any required arguments. The drivers define their own struct whose first
element is this struct full of function pointers, and fill in that struct with their own implementations. Each driver provides
its own 'init' function which initializes a new handle. Once initialized, the handle can be passed to any user of the interface.


# Architectural Implications
Its interesting to see the implications of each of these mechanisms on the large scale design of a software system. I have not seen handles
used in a pervasive way in flight software, but I think they have the potential to have at least as large an effect as a message bus. 


There is a distinction here for the level at which a handle operates vs the level a message bus operates- the message bus is a large
scale mechanism that facilitates a certain kind of information transfer. Its an asynchronous mechanism, best for multicasting data,
and passing packets of data that do have have strict time dependances or complex protocols involved in their transfer.


A bus does not help you abstract away function calls or general interfaces
like hardware devices or operating system functions. They can replace direct function calls, but when you must make function calls the message
bus does not provide a means of abstraction.


A handle, on the other hand, abstracts direct function calls and the direct use of a module's interface. This means that it can help when abstracting
something like performance sensitive code (although it does have a small cost) or code that makes direct calls to an operating system, hardware driver,
or a module where we want to abstract the details of which module or which function is being called.  In some sense this means that message
bus' provide abstraction for higher level data flow, while handles provide abstraction for more direct, low level data flow. However,
handles could be used to subsume message bus', but not the other way around.


Note that handles can be used to abstraction data flow similar to a message bus- you could have an interface with a function like "receive\_packet",
and have implementations that write that packet to multiple queues. This would be a kind of point-to-point or multicast mechanism. You could also
imagine that this receive\_packet function checks the packet's APID and provides it to a set of subscribers, implementing a pub/sub system using
handles.


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
could be written in such a way that each of these effectful function calls are abstracted out, so that we could feed in test data, simulated data, or
real data as desired. I didn't want this abstraction to result in complex or unusual code- it would be easier to adopt if it looked like normal code but 
somehow had this magical property that we could place it in a test harness and inject data, and then run the exact same code without modification in flight.


This lead me to design a kind of handle system in which code like operating system interface, and the interfaces of other modules, are abstracted into an interface
of functions that take a handle, where the handle is used to determine what happened at runtime when these functions are called. This way, the algorithm binds
directly to the interface (it needs to bind to something) but it doesn't require the other modules to be up an running, or the operating system to be the one
it was designed for, as long as we can provide an implementation that satisfies the needs of the algorithm.


I believe this could allow a whole series of amazing opportunities for this algorithm:

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
  * Handles allow abstraction of interfaces such that multiple implementations can exist at once within a single system. This is unlike
      the advantages of header files, where only a single implementation can exist at once.

  * Handles can be constructed at runtime- the particular functions involved may be arranged at runtime to serve a particular need. I don't see
    that I would use this all that much, except perhaps in debugging code where I could replace a function call with a logging call, or swap
    out a single function from an interface to test it.

  * Handles are composable. It is possible to write a handle that takes another handle as an input, and extends its functionality. This would
    work like decorators in python. You could have a handle that logs inputs and outputs, redirects them to another interface, or tees them off
    and combines the results between two handles.

  * Handles can be written for specific interfaces. A message bus is usually a single abstraction passing any kind of data around, while a handle
    interface can be a collection of functions and types specific to the interface. This allows more complex interfaces to be described, such as a 
    1553B interface, while remaining abstract.

  * Handle function calls look like normal functions. This is as opposed to tring to build in an object system in C, or constructing a complex
    macro system to abstract calls. A handle function call is just a function call.

  * Handles bind only against an interface. This is as opposed to abstracting using header files, which does provide a level of abstraction in the
    code, but eventually binds directly against something. This is a somewhat subtle situation, but the point is that a module build using a
    handle mechanism has shallow static dependancies.

### Cons
  * The implementation of a handle system is more complex then direct function calls. It makes use of function pointers and requires struct
    for each interface to hold these pointers. Each function must be written to redirect based on the handle, resulting in potentially a
    large number of similar functions.

  * Handle functions can't be traced to the executing code directly- there is runtime information used for function dispatch which adds
    complexity to static reasoning.

  * The handle systems I've been writing involve some redundancy. The code could be generated automatically, but so far I've been writing it
    by hand each time.

  * For a module with many dependancies, if each dependancy requires a handle then the module may need to keep track of a large number of
    handles. If the same module made direct function calls, it would not need to store and retrieve all of these handles.

  * There is a runtime cost to dynamic dispatch. I doubt it is very large, but its certainly larger then a direct function call. I'm sure
    its less then a message bus system, however.

# Conclusion
Hopefully this post gives some idea of what a handle system is and how to use one. I think they are an underutilitized form of abstraction,
and offer some potentially amazing advantages to embedded system's in particular.


I hope to write more on the details of implementing a system like this. I've been doing some 'real-world' testing of these ideas, and 
successfully ported a complex algorithm using a series of handle systems, which gives me confidence that its advantages do in fact work
out in practice.


I think the details on implementing handle system, as well as some useful handle system's I've started to write, will have to wait to another
post. This one is long enough as it is.


