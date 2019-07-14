+++
title = "Abstraction in Flight Software 3- Message Bus"
[taxonomies]
categories = ["NASA", "Flight Software"]
+++
This post is the third in a series talking about abstraction mechanisms that I have seen in flight software systems.
The topic of this post is the message bus. This is a mechanism through which messages are passed
between modules through an arbiter. This allows the sender and receiver to be completely decoupled- the sender does not
know who receives their messages, or even how many modules receive them, and the receiver does not know the source of the messages.
Both sender and receive couple directly to the software bus mechanism, becoming directly dependent on it. In this way, they
trade direct dependance on other modules to direct dependance on an intermediate module. This leads to an architecture where
the software bus is a central component that all components connect too. This reduces the overall number of direct connections
in a large system, which can provide benefits in the complexity of the architecture.


The main example I've seen of this kind of system is the CFS Software Bus (SB) module. This module provides a publish/subscribe
message bus which seems commonly, but is not the only kind of bus that is possible. The SB module is a core component of CFS, part of the
CFE modules. Not all communication between CFS modules uses this mechanism, and is instead part of tight coupling
between modules, but there are a number of mechanisms that rely on it.


The Message Bus
===
A message bus is a way to transfer data between components such that the sender and receiver are decoupled from each other.
The message bus itself is not necessarily a specific data structure or even a task- its a mechanism that forwards data between modules
based on runtime information. The CFS SB module is a publish/subscribe system, other styles like a point-to-point transfer could be
useful in some situations.


For a message bus to be publish/subscribe means that a component can register a message identifier (for CFS, an APID), indicating
that it will send messages with that ID. Then, other components can register to receive a particular message ID. When a message of that
ID is provided by a component, the message bus will send it to all other components that have requested to receive it.


In the case of CFS, a component requests a "pipe" (a message queue) and registers message Ids that it will receive on that queue. The
message bus keeps track of what pipes are registered with each message Id, and when a message is received it is copied onto each queue
in turn.


Note that the bus has a certain packet header it relies on to pass messages. It acts as a kind of router, and all components must agree
on the protocol to use. For CFS, this is CCSDS, which is a pretty lightweight protocol with only 6 bytes of header required. Most
systems will include additional header, but that is system specific.



There are definitely situations where this style of transfer does not seem to work out, at least not how I've seen it implementated. Something
like moving an update of a table between modules would require a request and response, which is even more complexity and overhead to deal with,
or would require a way to broadcast messages. Both of these have issues- a request/response needs a (simple) state machine and some way to 
recover from errors like a response that never comes, and a broadcast means all modules have to know to ignore certain messages. 
Instead, transfer like this go through direct coupling in CFS, which is probably the better design.


## Examples
An interesting use in CFS is task scheduling- the task scheduler does not release semaphores or run callbacks, but rather sends
messages to other components. These components will block waiting for new messages, and will run when the arrive. 
The messages "wake up" the module, allowing it to perform some periodic task like provide telemetry, run commands, or check for changes.


Another example in CFS is data storage- the logging module does not need to know what module produces messages, and it can be re-used without
modification when new modules are added with new messages to log. To be clear, the code can be reused- there are usually changes to configuration
that have to happen to get this to work.


One other example I've seen where this works out well is external interfaces. A component that communicates with an external interface can
receive a subset of messages from the bus and forward them out, and can forward incoming messages to the bus, all without have to involve
the sending or receiving components.

## Tradeoffs

As with any design, there are tradeoffs to be considered.

### Pros
  * Modules can listen to existing messages without modification to other modules. This is useful in several situations- if a new module
  needs access to some data (such as sensor data), if a new modules makes general use of data (like a logging module), or if the new module
  replaces an old module and is being swapped out by taking over the receipt of a message previously handled bythe old module.

  * New messages, even with no subscribers, can be added without modification to other modules. They will be dropped until a subscriber is
  added, but they can be send as soon as they are defined.

  * Generic modules like the scheduler or data logger can be written in terms of packets, and then re-used. They are each coupled to the
  message bus system, and other core modules in the case of CFE, but a certain subset of modules will require no other coupling.

  * Requiring a packet header means that transfers through the message bus have an id, where a direct transfer does not. This means
  that communication between components is a bit more formal, which can aid in documentation and reasoning.

### Cons
  * The distributed nature of the message passing can make it difficult to trace the path or cause of messages through a system.

  * If the system is based on message queues, then it can't be used for certain kinds of communication- the message will be processed
  at some time in the future, and if it needs to be handled immediately then direct coupling may be more appropriate.

  * There is a certain overhead involved in a message bus. Data is copied into queues, and data that does not require a header must be
  wrapped in one before being sent. I don't expect the overhead to be too high, and if you need low latency transfer, you don't have to
  use the message bus, but overhead is still a consideration.

  * There is a certain mental overhead required to create a new transfer- instead of calling a function, the code has to contain a message ID,
  a packet, and the data itself. If we are receiving data, we might also need a new pipe, at least in the CFS design.
  The tradeoff being made here is that the complexity of individual transfers is increased with the hope that the the overall system complex is decreased
  by avoiding a web of direct couplings that would otherwise result from many local decisions on what modules to connect.

  * Large buffers of data are more difficult to transfer. CFS has a zero-copy transfer mechanism to handle these situations, but in general
  there has to be some way to avoid copying large buffers on transfer.

  * Sending data to the message bus can take an unknown amount of time- if the packets are copied directly to the receiving queues then the
  number of copies is determined by how many modules regsitered to receive the message. This means that this mechanism shouldn't be used
  in certain situations like interrupts or drivers that need to get data out quickly. In these cases, we might want a separate task that
  pends on a queue, and forwards data from the queue to the message bus rather then sending it directly from the hardware.


# Conclusion
The message bus can have a significant affect on a system's architecture. While not all transfers will use the bus, it is a central part
of the system if it is included and can grow to handling a significant amount of traffic. My experience has been that it does assist
in software reuse- certain modules lend themselves to the use of a bus. For these modules, I have been able to re-use code without
modification, which I have not been able to do in more directly coupled systems.


I have also experienced some of the drawbacks of the message bus- its a lot of work to set up when adding a little data transfer, and
the decoupling does make it hard to feel like I understand what is happening in the system. Its very easy to miss messages when a central
module must receive all or a large subset of messages, or
fail to account for them in all modules that need to be updated to receive a message. This is partially because for the project
that I'm using CFS, I'm the only programmer, but in general a message bus is certainly more mental overhead then a function call.


I've found that the architectural influence of this system is fairly large- when people draw the CFS architecture, they show SB at the center
and show modules connecting to it. This is mostly true at runtime- there are certainly direct connections, but a good deal of CFS message
passing is through SB. However, the static aspect of the CFS architure is more complex- there is direct coupling to the CFE modules, PSP,
OSAL, and then through OSAL to the operating system.

