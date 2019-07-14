+++
title = "Abstraction in Flight Software 2- Registration"
[taxonomies]
categories = ["NASA", "Flight Software"]
+++
This post is the second in a series talking about abstraction mechanisms that I have seen in flight software systems.
The topic of this post is the first type of abstraction- while the first post was about direct coupling between
modules with no indirection, this post is about a way to reduce coupling between modules.


I don't know of a name for this kind of mechanism, so I'm calling it registration. It can come in the form of a callback,
a data structure, or a concurrency mechanism that is provided by one module to another. An example would be a callback provided
to a driver that performs some user defined processing of data when it arrives on a hardware interface.


In CFS this mechanism is used to validate tables, where one module is responsible for the definition of a table, and for
providing a function that checks whether a particular table is valid and can be used. The event message system also requires
modules to register an array of descriptions of the event messages they will send.


Another example I have seen is registering command callbacks to a module that determine what to do with commands received
by a system, or functions registered with a task management component to be spawned as tasks.


Registration
===
A registration mechanism consists of a function exposed by a module that allows other modules to provide it data or function pointers (in C/C++).
The data flow is from other components into the component that exposes this function, which means that any module that registers with the component
depends on it.



Here is a piece of imagined sample code, where the module ABC registers some callbacks with other modules. I put in some error checking
just to make it more like real code. The module CMD handles providing commands to appropriate modules, SWMSG handles a software message
mechanism where messages are simple strings, and TLM provides a way to update a section of telemetry given its size.


```c
int ABC_Initialize(int moduleId)
{
  int result = 0;

  gvABC_moduleId = moduleId;

  result = CMD_RegisterCommandCallback(ABC_ReceiveCommand, NULL);
  if (result < 0)
  {
    SWMSG_SendMessage(gvABC_moduleId, "ABC Register Command Callback Failed");
  }

  result = TLM_RegisterTelemetry(gvABC_moduleId, sizeof(ABC_Telemetry));
  if (result < 0)
  {
    SWMSG_SendMessage(gvABC_moduleId, "AB Register Telemetry Failed");
  }

  return result;
}
```


The registered data can be used to configure a module, to provide a processing function, a task, a semaphore to synchronize with, a message queue
to place data on- anything that a module does could be provided by a registration. This can be a single module registering with one other module,
such as if a module's behavior might be abstracted to be re-used where it behavior is determined by different modules in different projects. This can
also be used when many module interact with a single one, such as when all modules provide function pointers to be spawned as tasks.


Its interesting to look at the tradeoffs between registering function pointers and registering data. When there is a particular type of transfer, like
a command packet, it can make sense to provide a message queue and to simply place the packet on the queue. In general, however, we might not want
to dictate how a module receives or provides data, so we can hide that information in a function. In this case we are essentially replacing data
with computation, where the computation may simply place the data on a queue anywhere, but is allowed to do other things like record that the data
was received, or avoid a queue and process the data immediately. This provides extra flexibility, although C function pointers are not as easy to
work with as functions in, say, Haskell, and this can lead to some duplication where multiple modules define identical callbacks. This can be mitigated
by allowing a single argument to the callback function that provides configuration specific to the module, like which message queue to use, which can
allow a single function definition to be used by any module that needs default behavior, allowing modules to define their own function and data if the
want to handle data differently.


The registration mechanism is a push style of transfer- data is pushed from a module into the one providing the registration. However, the 
use of that data may be push or pull- a module may provide a callback that can be used to push data to it, or it may provide a callback that can be
used to pull data from it. In the first case, the callback might take a pointer to some data as an input argument, and in the second it might take
a pointer to data as an output which it is expected to fill out for the calling module to make use of.


The decoupling here allows a module to provide a service to other modules without depending on those modules, it allows modules to be added or
removed without changing the provider, and it allows some flexibility in how a module behaves without changing it source code. However it can lead
to some sublities, such as if a callback function is used in an interrupt, and the providing module must be careful to respect the requirements of the
module it provides data to. I've seen this cause problems when long running computations are performed in a callback- when writing and reviewing this
kind of code you have to look at its use of data, synchronization, and its execution time to know if a function is okay to use as a callback in a particular
situation.



Registrations mechanisms can also lead to situations where resources are exhausted if too many modules register, or if a module registers too many
times. Very often the registration is done at initialization so
if this happens you fix it during development and it never occurs in flight.


## Tradeoffs

As with any design, there are tradeoffs to be considered.

### Pros
  * This mechanism helps isolate module-specific logic within that module. An example is the table validity checking, where a module
  that is responsible for a table also contains the function used to check table's validity.
  * This is a way for a module to provide a service to an unknown number of other modules, and to add modules without necessarily updating
  the module that provides the service. If the service is general enough, like a software message service, then it may be portable between
  projects without modification.
  * The module providing registration is not directly coupled to other modules, allowing other modules to change their relationship with the providing
  module without updating that modules. This also means that the providing module can be moved to another system without considering modules
  that use it.

### Cons
  * This mechanism can make reasoning about certain module more difficult. A module that has many callbacks registered with it can be difficult
  to understand- to know what it is doing at a particular time you may need to know not just how the module works, but every callback registered
  with it an how they work. This means that local reasoning about the module's runtime behavior may require global knowledge about the project.

  * Modules written to register in this way depend on the component they register with. If modules depend on multiple regstrations with mulitple
  other modules then they are tightly coupled to the particular architecture. This can be alleviated somewhat by allowing this kind of tight
  coupling to a subset of core modules, such as in the design of CFS where the CFS modules are used directly, but other modules are usually not.

  * It can be difficult to know how a module is configured. This is related to the above, but specifically it is difficult to know exactly what
  registrations occurred and what data they contain. This can be alleviated by providing a report about how a module is configured, although
  this is additional complexity in the flight software to provide this report, in the ground software to interpret it, and in operations to retrieve
  it an understand it.

  * Change to a registration mechansim can have an affect on many, potentially all, other modules. It can also be a problem if a module providing
  registration is used on mulitple projects, but needs to be extended or modified for the needs of one project. This can lead to a situation where
  other modules are slightly different to account for this difference in registration, which makes re-use and porting difficult.


# Conclusion
The registration mechanism is a very flexible way to introduce abstraction into a system. It is fairly easy to implement and can have a good
tradeoff in complexity vs the additional flexibility. I've seen it provide software re-use where a service provider can be moved
between projects without modification, providing a lot of value when getting together a new system.
There can be issue with this where the needs of a specific system may require changes to the service,
which may propagate to all users, but in general this is pretty hard to avoid regardless of design.

 
