---
title: Programming Domains
author: Noah Ryan
---

One thing I've noticed a lot of in programming is that techinques that make sense in one type of
application do not fit another. There seem to be different domains of programming that fit along
ome number of axis, and people who spend time in a particular domain learn to optimize for that domain.

Then, they share their techniques with the wider programming community, and people close enough to their
domain find their results useful, while many others argue that they are solving the wrong problems, or
making strange trade-offs. Some ideas do seem to work in multiple areas, and there is certainly room
for novel thought in programming, but there is a lot of talking past one-another.


I'm sure this is something people have outlined before, but I wanted to try to work out what axis different
domains might fall along.  My own work has been in flight software at NASA, which seems to be unusual compared
to what I see and hear about other people's experiences as programmers. Part of what I want to accomplish with
this blog is to share my experience with flight software, to add an experience to the wider discussion that
does not get a large share (it is a fairly specialized and uncommon job).


Some people seem to have experienced a wide variety of domains of programming, and they are probably more
qualified to talk about this then I am. Take all of this with a grain of salt.


Some domains I can think of are game programming, application programming, web programming, systems
programming (operating systems, driver, etc), compiler programming, flight software, consumer embedded programming,
automotive software, trading software, 


One axis seems to be how the use of the software effects its development. Games and flight software share a
development cycle with a very important "release" period at the end. Certainly games can be developed in different
models, but the cycle of a lot of upfront work followed by a kind of "production" release seems to effect the
way games are made. With flight software, you test and test, and at some point the software is out there in
flight (say, in space) and it has to work the first time. You often can't really test in the true production
environment at all before you get there.


Performance
===
Another axis is the importance of performance. This is something that is really a collection of other, more
fundemental concerns, but it sums up a part of how the software is viewed. Is computer time or developer time
more important? It seems to be true that for a lot of software, performance isn't critical (although it
can have some interesting consequences when it is), and software needs to be developed quickly.


On the other hand, for something like games, trading software, or some scientific computing, perhaps 
performance has to be taken into account in all decisions. I've heard web browsers are extremely careful
about performance, and include performing monitoring in their development practices.


For flight software, performance is less important then correctness. We do error checking in production
that other software domains would disable (say, using asserts during development). Catching errors 
is very important, and those errors have to be propagated and handled at all levels. A significant percentage
of the code is concerned with error handling- nearly every line that performs an action is followed by at least
5 lines of error checking and handlings, and often much more.


Development Cycle
===
Some software is deployed frequently, daily or even more often, while other software is updated in a 
much more conservative and infrequent schedule. Concepts like continuous integration seem especially
useful when doing more frequent deployments, although this is a technique that appears to cross mutiple
domains for its utilty for a team of developers.


Flight software, in my experience, is only used on the ground or in flight after a significant amount of work
in developments, reviews, testing, requirement verification, signoffs, documention including a version
description document describing how and where the software can be used, and sometimes a length update process
like when updating the SAGE III software on orbit. During development this
took certainly weeks, and in operation this process takes months.


From listening to Jonathan Blow (who I definitely recommend) it seems like his experience with game development
also includes a lengthy development process, often taking years. He is developing a monolithic type of software
and his process and techniques seem to reflect this.


Criticality
===
The extent to which people depend on the software certainly effects it on many levels. One level is the 
mentality of developers- in my experience with flight software we have avoided a lot of idioms common in 
C/C++, almost all of the more advanced features of our languages, or advanced data structures or algorithms.
We don't allow multiple return statements, gotos, complex macros, or even incrementing variables within a statement
(like someArray[i++]). We don't use C++ templates, or inheritance (or classes very much), or even dynamic
memory allocation.


I often see other programmers discuss when these things are useful and how to deal with their
complexity, but we simply don't use them at all. In a way we are enforcing correctness through review and
through convention (and static analysis tools) because our languages do not have ways to enforce these constraints.
However, the advantage to this discipline that, for example, or don't worry about memory leaks because we don't
allocate memory startup- no 'malloc', no 'calloc', nor 'new' or 'free'.

Just as an example, here is how I would write a simple code Kata from CodeWars to find the smallest element of
an array (in a module called UTIL):

````
int32_t UTIL_ElementLessThanZero(int32_t elements, uint32_t numElements)
{
  int32_t elementIndex = 0;
  int32_t found = FALSE;

  if (elements != NULL)
  {
    for (elementIndex = 0; (elementIndex < numElements) && (!found); elementIndex++)
    {
      if (elements[elementIndex] < 0)
      {
        found = TRUE;
      }
    }
  }
  else
  {
    // some error handling here...
  }

  return found;
}
````

Note how verbose it is, how all variables are declared at the top of the function, how loop variables are
given long names, how explicit sizes are used, even for the loop index variable.


Interaction With Users
===
There is a lot of variety in how a program and its user's interact. People certainly put a lot of thought into
how to make GUIs, or games, or other interfaces. For flight software, the user is an operator with a procedure.
They are usually engineers, and use specific sequences and command sets that have been designed for the system.
This is very different from software that must survive all possible inputs from every user, where any sequence
of actions can happen. On the other hand, in off-nominal scenarios, sometimes the command sets are new or
use less well-trodden parts of the code, and there is some possibility that an unexpected behavior will occur.


Another difference between flight software and, say, games or GUIs is that it doesn't really have to be fast.
If a command takes seconds, or even minutes, to run, the operator will wait. That doesn't mean that performance
doesn't come up (usually when it comes to hardware interaction), but when it comes to user-facing code,
we are willing to accept a certain amount of delay.


Another weird thing about flight software is its interface- there is an assymetrical interface with command packets
(usually small) going to the system, and telemetry packets (often larger and more varied) going down. There can
be multiple telemetry interfaces, but usually only a single command interface. This means that the system
has a very limited, well defined way to accept input which can be validated and documented relatively easily.
Compare this with a GUI, where is would be very hard to document every button press and input on every element
throughout the program.


Unit Testing
===
This isn't realy an axis itself, but the attitude towards unit testing definitely differs depending on the type
of code. For some software, I do not test at all- developer tools in particular. For some tools, the testing is
in the use. However, for libraries testing seems worth it- it pays to make sure the library is correct to ensure
that all the programs that use it are correct.

For flight software, I believe in automated unit testing for all components. It is software that tends to be
around for a long time, and its correctness matter to a lot of people. It operates in a somewhat hostile environment,
and should be tested. It is not always easy software to test, but I've found it can usually be factored in such
a ways to allow testing of most code.
