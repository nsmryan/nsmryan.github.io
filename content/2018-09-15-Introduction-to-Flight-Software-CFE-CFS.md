+++
title = "Brief Introduction Flight Software - CFE/CFS"
[taxonomies]
categories = ["NASA", "Flight Software"]
+++
One of my goals with this blog is to talk about flight software- what it looks
like, how it is developed, and what it is like to be in the aerospace domain. I
think it would be nice to see more discussion of this kind of programming,
especially as space becomes available to more people through small satellites.

To do my part, I will discuss some of my thoughts on the Core Flight Executive
and Core Flight Software system developed by NASA, along with the Operating
system abstraction layer (OSAL) used by this project. This post will just be a
brief introduction to lay the groundwork for a more in depth look at the system.


I want to be clear in that I only see a particular slice of the aerospace world-
I don't work on planes or rockets or human rated systems . I have worked on a
safety critical piece of software for UAV applications, and the science payload
SAGE III, and I'm currently working on a small satellite science mission called
ARCSTONE that will use CFE/CFS for its flight software. I say this to give some
context in my background and where I'm coming from in this post.


# CFE/CFS
There are a number of resources on [CFE/CFS](https://cfs.gsfc.nasa.gov/) out
there, including its [github](https://github.com/nasa/cFE) page, [community
site](http://coreflightsystem.org/), [sourceforge
site](https://sourceforge.net/projects/coreflightexec/), and the CFS
applications on the [NASA github](https://github.com/nasa).


In addition, the project has a significant amount of documentation available
for each module, both as PDF files and Doxygen pages included in the source
distribution.


A brief overview is that CFE consists of a set of software components that
provide the main services used by flight software, whether that software is for
space, UAVs, or other embedded applications. It turns out that when writing
flight software there are some system one seems to need on every project, and
CFE is an attempt to package these systems up for reuse across many projects,
while providing additional modules that are not used in all projects but are
still common. This is done in an operating system agnostic way, assisting
portability.


These core components provide mechanisms for managing tables, sending packets
between software components, logging system events, creating small messages to
communicate the system's state to a user, allocating blocks of memory from a
pool, performing performance monitoring, managing files, managing time and
timestamping, and more.


In addition to these core modules, there are additional modules called apps that
are part of the larger CFS system, where you can add whichever Apps you want to
your project to get additional capabilities that are common but not neccesarily
in every project. Some examples of these additional modules are limit
monitoring, stored command execution, telemtry packet creation (HouseKeeping),
file management, data storage, and task scheduling.


All of these software modules do things like spawn tasks, create and use message
queues, semaphores, files, etc. When they need to do these things, they do not
call operating system functions directly, as that would tie the code to a
particular system. Instead they call functions defined in the header files of
the [OSAL](https://github.com/nasa/osal) project. The OSAL software provides an
interface which is then implemented in a set of C files for a specific operating
system. The operating systems available on github are Posix (which has worked
for me on both desktop and embedded Linux), VxWorks 6.7, and RTEMS. I've only
had experience running the Posix implementation of OSAL on Linux systems.


There seems to be a common confusing about the OSAL layer and CFS in general-
if you write software as a CFS application there is absolutely nothing hiding
the operating system or hardware from you. It is more accurate to say that you
can choose to use the OSAL (and PSP) functions to make your software more
portable, but if you need low level access to hardware you do so just as you
might in other software.



# Running CFE/CFS
The CFE/CFS project has an extensive makefile system which builds the core
components including OSAL, CFE, and the PSP (the platform specific code that is not
part of OSAL), and can be extended to call makefiles in subfolders of the apps
directory in order to build additional modules.


Once CFS is built, you end up with a single executable file, a series of
object files, and a
[cfe\_es\_startup.scr](https://github.com/nasa/cFE/blob/master/build/cpu1/exe/cfe_es_startup.scr).
When the executable is run (core-linux.bin for the POSIX build), it starts
up the CFE components, and reads the cfe\_es\_startup.scr file. This file
lists the additional modules to load, and the executable will load each
one in turn and call an initialization function listed in the
cfe\_es\_startup.scr file.


At this point you have a series of operating system threads running,
message queues created, semaphores, and files open. The CFS flight
software is running, logging, updating time, perhaps executing a schedule
of task executions using the [SCH](https://github.com/nasa/SCH/)
application, creating telemetry packets which might be stored in a file by
the [DS](https://github.com/nasa/DS/) app, and so on.


You have to provide input and output to this system somehow, often with a
project specific module which know about your hardware's interfaces and perhaps
the ground system you are talking to. There are some modules called Command
Ingest and Telemetry Output, each of which has a "lab" version for development
which forward commands over UDP to send to the Software Bus, and receive
telemetry packets from the Software Bus to send out over UDP.


# Conclusion
Hopefully this provides some references and a vague idea of what CFE/CFS is. I
hope to keep posting about this software, and get more into the architecture and
tradeoffs it makes in future posts.

