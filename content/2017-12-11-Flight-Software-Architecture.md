+++
title = "Flight Software Architecture"
[taxonomies]
categories = ["NASA", "Flight Software"]
+++
I've found over the last 6 years that flight software is its own programming domain with its own techniques, concerns, tools,
and mentality. I thought it would be good to go over some things I've learned and share my experiences with this kind of software and
its design. Its a world in its own, and I've seen only a small slice of this world, but its still hard earned experience worth sharing.


This could go on for many posts after post, so this one will just introduce some ideas.


What is "Flight"
===
The distinction of "flight" software versus other software is that it either goes on an airplane or in space. This software is often
high assurance- it is built to more rigorous standards, with a more intensive process, than other software.
Note however that being "flight" does not by itself make it high assurance software- there are classes that indicate how critical the software is. Class A include
software on vehicles with human beings, and critical functionality that humans depend on. Class B is for secondary systems, and for
larger robotic systems. The other classes can be smaller missions, and systems that are not used for critical functions
and have no ability to impact critical systems. These classes are also used for ground software, but thats not the subject of this post.


CFS
===
The best example that I can provide of flight software is [CFS](https://github.com/nasa/cFE). Its well used, well documented, and comes with a unit test
suite for each module. The link is to CFE, the core set of modules for the CFS system,
and there are other modules you can get [here](https://github.com/nasa). This system implements core functionality for flight software systems in a set of
modules called CFE, and then provides a set of modules uses these core systems. The user then configures the core modules and any additional modules they need,
and adds their own modules- either for generic functionality not provided by CFS or for mission-specific code like the control of a subsytem or a hardware interface
to a spacecraft bus.


I have worked with other flight software, and only recently gotten into using CFS. I like CFS, even when I disagree with parts of its design, and I have been
impressed with it in practice- I was able to get a fairly complete flight software system set up and start writing my mission code fairly quickly as a one-man
team on one of my projects. I haven't had to change almost anything within CFS itself- in the core CFE modules or the application modules- so in practice they
truely are generic and truely are modular.  It is not a perfect system, and I would like to work towards some improvements, but its very good, well tested and
has heritage in other missions, which does weigh in its favor.


Flight Software Concepts
===
There are a series of concepts that seem common in flight software systems. Each one can be handled in a variety of ways, but in general flight software
tends to have many of the following systems:

* Telemetry Collection
* Command Handling/Routing
* Fault Detection, Isolation, and Recovery (FDIR)
* Software Messages / Event Messages
* Hardware interfaces
* Mode Control
* Table Management (Configuration)
* Command Sequences (relative time and absolute time)
* File Transfer
* Data Storage
* Task Scheduling
* Time Management


There are also some utilities that are common to see:

* Fixed size allocation for packets and other structures
* Time stamp generation
* Packet creation/modification/inspection (usually CCSDS), and packet routing
* Logging
* Critical error reporting

We also need operating system functionality like:

* Threads
* Queues
* Binary semaphores
* Mutexes
* Counting semaphores
* Ring buffers

Other concepts may be used if available, or built if needed, but this is a basic list of functionality you will need in a flight
software system. Some of this is overkill for smaller systems, but scales to larger ones.


Each of these deserves a post of its own. There are a lot of details here.


Flight Software Implementation
===
The flight software I've seen is either in C/C++ or plain C. CFS/CFE is an example of plain C, and I would like to do a future post on why I think
C is the right language to have choosen for this work.


The code is broken up into modules called either modules, apps (in CFS), or CSC (computer software components). Each module implements one task
or chunk of functionality- each of the concepts listed above can have its own module. Modules boundaries are controlled- memory is usually not shared,
and communication is mostly through message passing. Function calls also occur for some functions, like getting a timestamp or unblocking a task on a
schedule.


A module may implement a hardware interface, a mission specific requirement like the managment of science data, or the management of a particular algorithm.
They tend to have acronyms for their names, like TBL for table management, SC for stored command management, or SB for a software bus.


Each module is a sigificant amount of work requiring design and implementation, review, documention, and testing. The testing can be on a unit level, and a
system level when possible.


Commands and Telemetry
===
Flight systems have a asymmetric communication model with the ground system. The distinction
between packets received by your system, commands, and packets produced by your system,
telemetry, appears to be universal in these designs, and influences a lot of design.


Commands
---
Going from the ground system or another flight system to your flight system are commands-
packets, often small, that contain information about what actions to take. There is almost
always one hardware interface that accepts commands.
Commands can contain data blocks in some cases, but they are often very short containing
not much more then more opcode indicting which action to take, followed by zero or more
arguments to control how the action is taken. The cases where a command contains a data
block might be to upload some configuration to the system, or to provide a small file.


Commands are also sometimes called telecommands in analogy with telemetry. Some examples of
what actions would be commands are:

* Reset the system
* Capture an image
* Create a report
* Run a pre-loaded command sequence
* Turn on or off power to a system
* Change mode
* Clear storage

Telemetry
---
Telemetry packets can larger, and each contain a particular report about the state of a system,
sometimes called housekeeping or health and status, or a block of data the system needs to
downlink, like a block of file data or a science measurement.


Unlike commands, there can be many interfaces that provide telemetry. This depends on the
architecture of your system, but you may have a health and status interface as well as a higher
speed science downlink interface to get your data into a storage system.


Some examples of telemetry packets would be:

* Health and Status with the state of your system's CSCs
* Science measurements packets with the contents of a sensors measurement
* Data downlink packets, either containing the data in a file, or a report generated about
the status of your software.
* Event message packets containing one or more message generated by your software
* Subsystem telemetry generated by another system and received by your software. I recommend
wrapping this kind of data in a new header generated by your system, even if you used the
same protocol as the subsystem.


Event Messages / Software Messages
===
One mechanism that is hugely useful in flight software is the capability to generate small
messages from anywhere in your software. These are either called event messages or software messages.


In some systems they contain text, and in others they contain binary data. For smaller systems,
text is nice because the human operator will want to look over these messages, and it gives you
a simple way to allow your software to communicate information to you in a quick and easy
way.


For larger projects, binary data can be preferable to text. You can have a ground system
monitor for binary data more easily then it can parse text, and you can store and retrieve
binary data parameters in a database more easily then text. The tradeoff is that if you
want human readable output, you have to contruct it in your ground system.


One recommendation I have when designing event message systems is to provide a timestamp along
with every message, and to provide microsecond accuracy. This makes event messages a way
to timestamp your softwares actions, giving you insight into its operation that is otherwise
lost.

Examples of software messages might be:

* System initialized successfully
* Memory corruption found, along with data on where the corruption was found
* Science data collected, along with the time and parameters for the data collection
* Command rejected, along with some data on why it was rejected
* Temperature out of safe range, along with which temperature and its current value


Use software messages liberally, reporting most things that your software does. However, be
careful to not to allow your software to report messages constantly, or they will drown
out rarer but important messages.


Label your messages with which software component generated them, with a number indicating
which message was generated, and with a severity indicating how important the message is.
Examples of severities are warning, error, critical error, information, or routine.


Moding
===
These system have distinct modes that they can occupy. These should be designed early on
as they influence a lot of parts of the system, and you need to decided what parts of the
system can be used in each mode, and how to limit your system to only act appropriately for
its mode.


Designing the system's state machine
is a tricky thing- you have to be careful about limiting how many modes you have and what
transitions are possible. Each mode should have the system in a well defined state, and if
the system does not reach that state then you have to decide how to report that and what
"mode" you are in for those cases.


System states can be things like the power status of your subsystems. Ensuring this status
can also be tricky- you don't want your system to be too smart in trying to reach a particular
state if you can help it.


Examples of modes might be Safe mode, Standby mode, Operation Mode, Science Mode, Idle Mode,
or Configuration Mode. Each one would be named to reflect the way the system is operated while
it occupies that mode. Note that while systems and subsystems have modes, there may be
operational modes that are not part of the system, but are ways of using the system
that are for the human operators.


Complex Algorithms
===
Its common that flight software contains algorithms that are developed by an expert in some field. This can be something like predicting the geometry of a system
throughout its orbit, the sequence of actions for the system's main task like collecting science data, or other algorithms. Each of these is a challenge in software-
the algorithm is best understood by someone who is rarely a software engineer, and the implemention must be verified by a combination of software testing and 
algorithm testing. The boundary between what is the responsiblity of the software engineer and the domain expert can be difficult.


I've had good experience with algorithm designers that are willing to go through software processes, will provide test cases for me to run against my implementation,
and will go over the implementation with me.


One lesson I've learned is to always set up your algorithm so it can be run off the flight system- it should be able to run on a laptop by anyone who needs to.
This allows us to experiment with the algorithm, do debugging in case of problems, and allow people to do their own analysis without flight software support.


Software Tools
===
One lesson that I have taken to heart in the last year or so is that flight software teams need to produce tools. You need tools for decoding your telemetry, even if you
also have a ground system. You need tools to monitor for warnings and errors so they don't go unnoticed. You need tools for building your configuration tables, for
visualizing your system's operation, for simulating your subsystems.


Having tools for these things is a huge productivity boost. It also gives you the ability to review your processes- if you look over telemetry reports by hand and miss something,
you might miss it again, but if your tool misses something, you just change your tool and it will never miss that particular thing again. Your tools can be reviewed, you can
report what they do, and you can provide them to people in your project- it gives you a way to encode your expertise with your software into something other people can use.


I have been writing a new tool every month or so for a while now, and I find that I'm a must bigger asset to my projects when I put in the time and effort to produce
these programs. In my case, they are usually either LabWindows GUI programs, simple command line C programs, or personal tools in Haskell or Lua that I use for one-off
tasks or for visualizations that I have limited use for.


Software Updating
===
The ability to update software in operation is vital. Its own of the reason to prefer doing things in software when possible- software is softer then firmware and hardware,
as you might expect. This is a delicate process as a mistake here can render a system unbootable and end your mission. Test this as much as possible and always do it in the
same way.


Its preferable to build your software into a single image when possible. This image can be stored in a persistant memory device like flash, and can be stored redundantly
and with CRCs or other checks. My experience has been to prefer triple redundancy whenever possible, and to store a CRC32 with the data so you can check integrity without
having to compare the images. One other detail is if you have no valid images, nominate one to boot anyway- its a last ditch effort but if all your images are corrupt its
worth trying to boot so you can fix the problem with a running system just hope your corruption is in an non-vital area.


There will usually also be more then one version of the software on a system. My experience is that it is much better to keep a golden image that is never updated and a
main image that is used for operations then to allow multiple images that can each be updated. Keep this simple and avoid the possibility of confusion- when confusion is
possible it will occur.

Flight Software Reviews
===
I've come to realize that software reviews are a vital part of creating high quality software. They do not ensure that software is high quality, but not holding reviews ensures
that it is not. Reviews don't just increase your software quality, they help with sharing knowledge about design and interfaces, they increase consistancy, and they
make you think about your systems from other people's perspectives.


For flight software reviews, my experience is that your reviewers should look over the code or documentation under review before hand and come with issues. Some reviews
and go over the material during the review, but this is less effective, and its easier to miss things.


Review issues must be tracked and closed one way or another. They can be deffered if necessary, or tracked by other systems, but they must not be dropped until there is some
kind of resolution. This doesn't mean you have to fix every issues, but you at least have to document what you did and why.


Reviews should be harsh- you should nitpick and argument over everything. If you are going in with a design, be ready to defend it. I've found that vigorous debate in reviews
keeps your software at its best, and lax reviews are much less helpful. Its possible to get bogged down in nitpicking, or to bike-shed, but if you have a good moderator who
keeps the review on track then you can get a huge amount from each review.


Look for everything you can in your review- is the documentation accurate and useful?, is the software as simple as it can be?, does it have edge case or can it be used
incorrectly?, does it check every error condition?, does it present issues with future maintanance or changes?, does it meet its requirements?, does it correctly use its interfaces
with other software components?, does it present a useable interface out to other components?, does it perform well (when that is important)?, does it report its status or is there
more information you might want in case of a problem?, does it fail cleanly? There is a lot to think about, and reviews can take a considerable amount of each persons time for each 
review they participate in.


One word of caution however- reviews are not a silver bullet. The result of a review is usually better software, but it often feels like a hill-climbing this to me. If the
software is badly designed, or doesn't meet its requirements, a review may not be able to fix that. Consider holding design meetings beforehand to vet each software component's
design, and consider holding re-reviews if too much needs to be changed. If possible, review early and often so you don't go too far down a path with your software before learning
that someone has a serious issue with its design or implementation.


Flight Software Mentaliity
===
There is a lot to say here, but I just want to say that I've learned to prefer flight software that is simple, uses as few concepts and syntax as possible, is as consistant
in any way possible (variable and function names, checking, messaging, testing, debugging, comment- every you can), does not have too much extra functionality that can
lead to errors while having nicities that your operators will thank you for, checks all possible error conditions, provides insight into its operation and is loud about
all errors, contains as little state as possible, and as a rule is simple above almost anything else. It must be reviewable both by your coworkers, and by you in a year
when you have forgotten how it works.


Flight software is much, much more risk adverse then other software. This shows up in all places, and can lead to designs that would be hard to understand in other software.
We have a great deal of flexibility in software with how to do things, but in flight software we have to be more restricted and careful with our designs. It is better to
limit how the system works whenever possible so that only correct behavior is possible. We have to be very pessimistic: expect errors, expect hardware failures, expect
software failures (even in our own software), expect anything you can think of.


Flight Software's Role
===
Again, there is too much to say, but I will try. This is something I am always learning about and trying to improve, but these are my current thoughts.
The software discipline needs to get people thinking about their conops and how they want to operate a system. We need to let them know
what software can do and what the options are taking into account cost, complexity, and the effect of each feature on the software as a whole. We need to keep people up to date
on progress and implemention- people have a hard time understanding software, and we need to communicate what we are doing and why. We need to be transparent- our software repositories
are a resource to the project and not just our own. Our documentation is important for operators. Our design decisions effect people just like the decisions of any other disicpline, and
we need to communicate those decisions and why we made them to the project, documenting our reasoning for the day that our implementation effects other peoples jobs.


Software needs to be part of a project early on to get its needs and requirement in the mix, and to inform people about the cost and ability of software systems. People over and under
estimate software in many areas and need a software domain expert to answer these questions. On the other hard, software often has little work early on, in the mission concept planning.
In that stage I think we can provide engineering insight and just help when possible, knowing that the actual role software itself is a long way off.


Software needs to follow best practices and be ready to answer questions about your approach to requirements, design, development, testing, reviews, and releases. You need to track
problems with software, to track issues from reviews, and to track and document what testing has been done with what versions of software.

