---
title: VxWorks
author: Noah Ryan
---

I had never heard of VxWorks before coming to NASA, but now I have been using it for 
over 5 years. I thought I would write down some things I've learned- some tricks and
commands, concepts it uses, and larger scale considerations for programs written
for it.


In some ways, using VxWorks is simpler than, say, Linux. Once you spawn your tasks in
usrAppInit they just run- there is no file system assumed, very few other tasks, and very
few concepts to learn. A particular BSP (board support package) may have its own complexity,
but VxWorks itself is surprisingly simple. Code written for it will have only a couple 
of special types and a couple of libraries like msgQLib, semLib, taskLib, and for the
most part the operating system will just get out of your way. This
does have downsides when you wish certain features, primitives, programs, etc were
available. The situation seems to be getting better and better with new versions, but
you are sometimes at the mercy of your BSP.


Note that I've used VxWorks 6.7 for most of the development I've done, and only recently
started to use VxWorks 7.0. I haven't used the new command line features much, the new
configuration system, or many of the new libraries. It seems much more complex, but
some of the libraries provide standard was to access hardware that are much better then
using system specific libraries for each project.

I also haven't used the RTP features even in 6.7- we build a single kernel module which
runs in a single memory space.  This is simple, but less safe then the alternative.


-----

Command Line
============
First off, the VxWorks command line is indespensible. I have used VxWorks 6.7 for almost
the whole time I've been at NASA, and I haven't gotten accustomed to the new VxWorks 7.0
extended command line, so these commands are for the default one that the system boots up
into in 6.7 and 7.0

  - **i** The information command **i** lists the current status of all VxWorks tasks.
    I mostly use this for task status in case a task is suspended, making sure a task is present, 
    getting the task id to use with another command, or for checking for errnos in tasks.
  
  - **ti** The task information command takes either the task name or the task id number and prints
    a detailed description of the task and its current status. I usually need this when a task
    crashes and I want to look at the exception, the program counter, the stack pointer, and
    the memory location that cause the crash for a memory access exception.
  
  - **tt** The task trace command shows the current stack trace of a task. This is useful for
    quickly finding the code that caused a trask to crash even without the debugger provided
    by Workbench. Note that this command attempts to build a stack trace by inspection of the state
    of the tasks stack- if there is memory corruption then it can be wrong.
  
  - **l** The list command takes a memory location and produces a disassembly of the memory at that
    location. It can also take a count of how many instructions to print.

    If you don't mind reading assembly, this can be a huge help. I've used it to understand stack
    corruption problems, and to debug a very tricky problem that turned out to be caused by
    loading a floating point number from a misaligned address on a PowerPC processor.

  - **d** The dump command displays the contents of memory at a given location. It takes the
    address to display from, the number of items to display, and the size of the items
    (1, 2, 4, or 8).
    This is one of my most used commands. If you need to inspect memory to understand how
    a structure is layed out, find corruption, or inspect a stack then this command is the
    fastest option. Against, you may be able to use the debugger, but more often I just
    want to look around in memory, and this is the best way to do that.

  - **spy** The spy command is a quick way to profile processor use. You provide it a period
    and the number of samples per second, and it will print out a report at the end of the
    period with processor usage information.

    The profiling that it does is based on frequently sampling which task is running, and counting
    how many times each task is observed to be running.

    This is a command I've only recently discovered, and it immediately uncovered an issue with
    log files on my current project. A single task was taking 30% to 40% of the total processor
    time, which is a problem that could have gone unnoticed for a long time and only come up
    monthes or years down the road.
    
    Note that you can enable this command the kernel configuration if it is not available to you.

  - **lkup** The lookup command is another one I use frequently. It takes a string argument and
    searches for occurrances of that string in all defined symbols. This is a great way to
    find function names that you can't rememeber, or to inspect a system that you don't have
    code for to find useful information and functionality.

    One other use is if your program's symbols get any C++ name mangling.

  - **period** The period command, gives you a way to spawn a process that you want to run 
    on a period basis. You can use this to monitor or log information periodly and see how
    things change over time.

  - **sp** The spawn command lets you spawn any function as a task. One thing I use this for
    is to run a long running function at a lower priority then the command line task. There are
    two reasons to do this- one is that you can still use the command line while the other
    task runs, and the other is that we always have watchdogs in our systems, and if the command
    line task runs too long the task petting the watchdog can be starved, resetting the system.
  
    The defaults that *sp** provides are usually fine, but if you want you can specify
    task priorities, stack sizes, etc with the taskSpawn command.

  - The last thing I use the command line for is running my own functions. Any function that
    is not declared static can be run from the command line.
    This is a way to test functions and inspect the system at runtime. I write a lot of
    utility functions, especially early on in a project, as well as units tests to run on
    the command line.
    
    Note that the command line doesn't accept floats or doubles, so you have to be
    a little tricker there.



Tasks
=====
Tasks are allocated a single block of memory that contains both their TCB (task control block)
and their stack. Note that in a kernel module all tasks run in the same flat memory space, allowing
them to corrupt each other's memory.

Task priorities are ordered to that lower numbers mean higher priorities. Priorities greater then
10 are open for use by user code, with priorities lower than 10 reserved for VxWorks tasks.


If you need more control over task scheduling then priorities give you, such as maintaining
a global processing cycle with time slices allocated to different tasks, or a way to easily
schedule a task at a given rate, or just to monitor running tasks, consider writing a task
scheduler task. This task can use semaphores to release tasks, monitor that the tasks complete,
and could even keep statistics on tasks if you wanted. This sort of thing isn't built into
VxWorks, but it makes a system much easier to reason about as compared to separate tasks all
scheduling themselves.

Since VxWorks is a real time operating system, the task with the highest priority that is ready
to run will have as much time as it needs. Lower priority tasks will be starved forever if
tasks do not release control by pending or delaying with taskDelay.

Task scheduling occurs after iterrupts, and in every system call. This is how a msgQSend or
semGive or any other call causes a rescheduling- a piece of VxWorks code is run to determine
if a new task with higher priority can now run.

If two tasks have the same priority then a round-robin scheduler is used. I've never used
this functionality, but it could be useful for tasks that can trade off control between
each other when they block.

One thing that always come up when talking about task priorities is (re)inversion of control.
If a low priority task task a resource, but is interrupted by a higher priority task, then it
will of course lose control. If the higher priority task then pends on the resource it will block
until the lower priority task releases it. This is called inversion of control because the lower
priority task now controls the higher priority one. The problem here is that the lower priority
task may not run if a medium priority task is ready, which blocks the high priority task, perhaps
indefinitely.

VxWorks deals with this by re-inversion of control- the task priority of a task that takes a
resource is the highest priority of any task pending on that resource.This means that a low
priority task with a resource will run until it gives up that resource to prevent it from blocking
out a higher priority task that is pending on the same resource.


Message Queues
==============
The main communication we use between tasks are message queues. Message queues
in VxWorks are great, but they do have some limitations- you can't empty a queue without just reading out
all of its messages, and they allocate space for the largest message you can receive. This means
that if you have a queue that needs to receive a lot of types of messages, and needs to be large,
you either waste a lot of space or you need a series of queues of different sizes.

This comes up when writing logging tasks that store data from the rest of the system. These
tasks usually have low priorities and huge queues- you don't want to lose data, but logging can 
happen at any time.

If you split the messages into several queues just be aware that you can't
simply pend on the first message from any queue- you have to poll, release a semphore when
queuing, use a counting semaphore, or have a "message description" queue. The last option is
where you have a separate queue where you queue an indicator of which of the other queues to
read from- if you receive a small message, you put it on the smallest queue and write
SMALL_MESSAGE_QUEUED (for exampled) to the message description queue. You can then pend on this
queue, and it will tell you which of the other queues to read from.


Interrupts
==========
The main thing to know about interrupts in VxWorks is that you are allowed to release semaphores
and write to queues with NO_WAIT, but not to take semaphores or to receive messages.


If you need to print from an ISR (for debugging) you have to use logMsg from logLib- this will
log the message you want to print to a queue which is when printed when the log task runs.

Another thing to know about ISRs- when they perform system calls like message queue sends or
semaphore gives, the action they request is not actually performed. It is merely logged to a
global queue, and then run when the ISR exits. This prevents inconsistent views of the VxWorks
operating system state.

When an ISR exits, the system does not simply return to the last running task. There is a piece
of VxWorks operation system code that performs the ISR's actions and reschedules tasks if
necessary.

Also note that ISR (interrupt service routines) run in a special interrupt stack (as far as I
know). I believe in older VxWorks versions they use the current task's stack, but that was changed.

It goes without saying, but I will say it anyway- keep your ISRs short. This is true in any
system- interrupt latency is a global issue. Any time you spend in an interrupt will create
jitter in measurements and hold off other interrupts. Some ISRs have do a lot of work,
especially when trying to figure out who caused a hardware interrupt.
If you interact with the hardware in your own interrupts, just be aware that things like 
transactions with hardware, say across a PCI or cPCI bus, are expensive.

Watchdogs
=========
VxWorks provides a software watchdog mechanism. You register a function to run after a certain
number of system clock ticks, and VxWorks will call your function is its own system clock tick
interrupt. This means that precautions related to writing ISRs apply to watchdog functions.

I've used these for keeping track of system time, incrementing a counter when the watchdog goes
off, and for ensuring that certain events occur. The second use is more like what a hardware
watchdog would do- if you don't keep rescheduling your software watchdog it goes off and
either resets the system, or reports a problem.

This is especially important in hard real time system where exceeding a time limit is a
catastropic problem and there needs to be a fail-safe executed if that occurs.


Ring Buffers
============
VxWorks does have ring buffers. Read rngLib documenation for details, but these ring buffers
do not perform locking and unlocking- they are intended to be used in a single reader, single
writer context between tasks without requiring synchronization. If you need mutual exclusion
because you have multiple readers or writers, you need to ensure that yourself with a mutex.

These ring buffers are byte based- you can read and write a whole buffer into the ring buffer
in one function call, but the buffer itself only knows about bytes. This means you either
have to have fixed size messages, a message header, or some other way to know how to decode
the data on the ring buffer.


Semaphores
==========
VxWorks provides a couple of different semaphore types. Like with message queues, VxWorks doens't
provide every nice feature, it just provides simple features with solid implementations.

The semaphores that it provides are binary semaphores (mostly for signalling), counting semaphores
(mostly for resource control), and mutexes (for mutual exclusion of a resource). There is
also a shared memory semaphore which I have never used, but is perhaps useful in shared memory
systems.

These concurrency primitives are common, so I won't go into detail on them in this post.
There are certainly other primitives one might want (like MVars or concurrent ring buffers),
so just note that you might have to implement them yourselve using the primitives VxWorks provides.


Errno
=====
VxWorks keeps a task-local errno for each task. You can access this with the variable errno, which
is just a macro that expands out to an access to the errno field of the current task's TCB.

The way to use errno is to check the return of all system calls, and if it is not OK then to
look at the errno. You can clear the errno with errnoSet if you know a call will set the errno
and you don't want it to be left set.

The main thing that triggers errnos for me is timeouts on semaphore or queues, and sometimes
invalid handles to queues or semaphores. Other conditions are definitely possible though.


The one time I actually cleared an errno was to detect when a task overran its allocated time.
It was important that the task not start itself in the middle of its time slice, but if it overran
its time limit and attempted to pend for its scheduling semaphore (released by another task)
then it would immediately see that the sempahore had been given and start in the middle of the
time slice.

What I ended up doing was attempting to take the semahpore with NO_WAIT as soon as the task
was complete, and if this succeeded then the task must have overran its time limit enough
that it had been scheduled again. In this case I would wait for the next time slice by
taking the semaphore (after reporting the problem of course). If the semaphore had not been given, 
then the task would just take the semaphore again with a longer wait time.


Time
====
Time is a very complex topic, so I will just mention sysLib and timerLib. Note that your system
may has a primary and an auxiliary clock with different rates, and that you may need to set
the system clock rate with sysClkRateSet during initialization.


Scheduling wait times and delays usually use sysClkRateGet, and you can connect a callback
to the system clock with sysClkConnect.

Make sure you understand time in your system, and if timestamps are important make sure
you look at drift with respect to a trusted time source (like a pulse generator) so you
can correct for drift in software, hardware, and due to thermal effects on the oscillator
used for the system clock.

-----

The documentation I use the most when programming in VxWorks is [here](http://www.vxdev.com/docs/vx55man/vxworks/ref/libIndex.htm).

VxWorks 7.0 is different in some ways from 6.7, and its worth looking over the documentation of the version
you are using to make sure you get the right information.

There is a lot more to say about using VxWorks, but I think this is all I can handle for now.
