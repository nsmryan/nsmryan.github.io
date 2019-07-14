+++
title = "Handles for Abstraction"
+++
# Introduction
I've been thinking about the use of the handle concept as a means of abstraction in C, and I wanted
to give some details to one way to implement and use this idea. Its essentially taking the most basic
means of changing an implementation in C, headers and implementation files, and introducing a single
level of indirection such that the particular implementation can be selected at runtime. This introduces
a number of oppertunities which can be used to get some nice things that we usually don't have in C.


The particular implementation
is very different from the one I've typically seen. It is the simplest implementation I can think of,
not requiring any kind of allocation, tables, or resource tracking. This whole thing is done with structs,
typedefs, functions, and function pointers. There are no macros to hide complexity- everything is done
explicitly with as low complexity as I can manage. The core concept is that we usually bind a function
prototype to a particular implementation. In this case that implementation simply redirects to another function
through a function pointer (dispatching based on runtime information).


# Abstraction
There are many ways to add abstraction
in C, both in the form of libraries, macros, or entire languages started by extensions to C. Certainly
we have C++, Objective C, C#, etc by adding to the language itself. However, we don't always have
this option, especially in embedded systems or legacy systems. Looking for pure C ways to control complexity is
certainly worth looking into, and handles give a good amount of flexibility for the relatively low additional
complexity in my experience.


Abstraction in C be done in many ways- some programs add object systems like GObject, abstraction
like publish/subscribe systems (SB App in cFS), or other infrastructure. Everything comes with tradeoffs, and certainly we have to consider
these tradeoffs, especially in flight software where the cost of complexity is high. This is where
the lower complexity can come in handy.


There are also more transformative changes like using fat pointers to add all sorts of capabilities 
(see [Cello](libcello.org)), or an object system like [COS](https://github.com/CObjectSystem/COS). These add a
great complexity to programs from the start, and I imagine that this pays off more in very large systems or when
one is very familiar with the language. I don't think I would want to introduce these in flight software, although
I know COS was intended for large scientific computing programs. What I would consider, however, is a concept or
library that provides some means of abstraction without being quite so disruptive to the programs that use them. I'm
also not looking to add an object system or reinvent the world within a system- I would rather just have some means
to abstract when and where I need it.


In the case of handles, we take a particular API and produce an abstract implementation that can be redirected to concrete
implementations, allowing multiple implementations to exist at a time. We can have testing implementations, real ones,
and mixed implementations which combine testing and real work. We have even have some interesting higher level implementations
which transform implementations. In principal we could also compile with a concrete implementation at some point, using the
indirection of the handle only during development. However, this indirection can be useful in production systems as it allows
multiple implementations of a single interface to exist within a single system at the same time.


One nice thing here is that the API's can be small and self contained. These are not monolithic hardware abstraction layers,
operation system abstraction layers, or do they require you to shoehorn all use of a device through the same API (like treating
everything as a file). Instead you get APIs specific to each concept (logging, mutexes, files, networking, etc) which can be
used independantly, and which take very little code to deine. You can redifine the interface for each operating system,
or have multiple implementations for different hardware devices, or have something like ML functors which transform interfaces.


With that introduction, lets go through a case study by defining a logging interface, implemenent the abstract implmentation,
and then look at a concrete implementation.

# Logging
For our case study of a logging system, we will start by defining an interface and proceed to an implementation which
simply prints text to the screen using printf. A full implemenatation would open files and place text, but this one
might be used for debugging, or in addition to an implementation which logs to a file.

## Interface
Each interface is written individually- each is a simple application of the concept, and each is pretty easy to write.
We only need a small number of functions
to log raw text, log entries of text, and to close a log. Other functions could be added, but for this post we will focus on
these three.


Lets start with a simple header file defining the Log struct that we will use as a handle to a log:
```C
#ifndef __HANDLE_LOGGING__
#define __HANDLE_LOGGING__

/* Handle implementation for logging */
typedef enum LogLevel
{
  LOG_LEVEL_INFORMATIONAL,
  LOG_LEVEL_WARNING,
  LOG_LEVEL_ERROR,
  LOG_LEVEL_DEBUG,
  LOG_LEVEL_TRACE,
} LogLevel;

typedef struct Log;

typedef int LogTextFunc(struct Log *log, const char *log_text);
typedef int LogEntryFunc(struct Log *log, LogLevel level, const char *log_text);
typedef int LogCloseFunc(struct Log *log);

typedef struct Log {
  LogTextFunc *log;
  LogEntryFunc *entry;
  LogCloseFunc *close;
} Log;

int LogText(Log *log, const char *log_text);
int LogEntry(Log *log, LogLevel level, const char *log_text);
int LogClose(Log *log);

#endif /* def __HANDLE_LOGGING__ */
```

We start with include guards, and we need an enum for the particular interface we are defining called
LogLevel, which indicates the severity of a log entry


The next part is important- we need a forward declaration of our Log structure with the:
```C
typedef struct Log;
```
This is the best way I've found to do this. We need the structure name to exist to define function pointer typedefs which use it, but the
struct Log will contain functions pointers using those typedefs, so we need a forward declaration to break the cycle.


The lines are typedefs which define LogTextFunc, LogEntryFunc, and LogCloseFunc.
Each function takes a pointer to a struct as a first argument, and then as many arguments as required for the function.


The next thing to do is to define our struct. We need a field for each function in our interface, and fields for any data that is used by all interfaces.
This is done so that when we have one of these structures, we have a concrete implmentation of each of these functions which together are an implementation of the interface.


Now that we have our struct, we define each of the functions that define our interface. This is a place where there is some duplication- the function definitions
need to be the same as the typedefs for function pointers before. I don't know of a way to avoid this, buts its not too be of a deal. Certainly we could
imagine generating all of this code from a specification, as it is very formulaic. However, I have preferred to write it out to make things explicit.


At this point the interface is finished. We have a struct type to use as a handle (using pointers to the struct to keep the handles small and consistently sized),
and function prototypes for each function we will be exposing to the user. In this case the functions are able to log raw text (Logtext), logging an entry with
a timestamp and log level (LogEntry), and to close a log (LogClose). We don't have a LogCreate or LogOpen in this design- creating logs is left to the 
particular implementations as it may be different for each one.


## Implementation
The C file is so small I'll just show it without further ado:
```C
#include "log.h"

int LogText(Log *log, const char *log_text) {
  log->log(log, log_text);
}

int LogEntry(Log *log, LogLevel level, const char *log_text) {
  log->entry(log, level, log_text);
}

int LogClose(Log *log) {
  log->close(log);
}
```

There is almost nothing to the implementation file for these interfaces. For each function in our interface, we just write a 
function which uses the given struct pointer to call the corresponding function within the struct. The LogText function
calls the 'log' function, LogEntry calls the 'entry' function, and LogClose calls 'close'.


The reason for this is that the functions we are 
exposing in our header file will be implemented multiple times, and we need a way to call the right set of function for a particular implementation.
We do this by placing pointers to those functions in a Log struct, and then calling one of these functions. The functions will then dispatch directly to
the function provided by the interface.

This is another place where we have some duplication- any functions we define must pass their parameters to the particular function implementation.


Note the trick here- usually this file would do the actual logging. Instead, the functions in the header file are linked against an implementation that
calls a function pointer provided at runtime, allowing the function to do anything we want even though our code calls a particular function. This means
that the graph of dependancies will be very simple- we have moved dependencies to run time so we don't necessarily have to link against a particular
implementation when compiling. This could allow us, for example, to run the same object file in a test harness and then on a target system without
recompiling. Pretty neat.

# Printf Logging
Now lets go through an implementation of this interface that prints to the screen. This would be used for debugging, or could be combined with
an implementation that tees log data to this implementation as well as one that actually writes to a file.

We will provide implementaions for each of the necessary functions, and then an additional function for initialing a Log struct to use this interface.

## Interface
```C
#ifndef __HANDLE_LOGGING_PRINT__
#define __HANDLE_LOGGING_PRINT__

#include "log.h"

/* Concrete implementation for logging */
typedef struct LogPrint {
  Log interface;
} LogPrint;

void LogPrintInit(LogPrint *log_print);
int LogTextPrint(Log *log, const char *log_text);
int LogEntryPrint(Log *log, LogLevel level, const char *log_text);
int LogClosePrint(Log *log);

#endif /* def __HANDLE_LOGGING_PRINT__ */
```
We have to define a new struct which will hold our interface (the Log struct of function pointers) and any additional data. In this case we don't need
anything additional so the struct has only one field.


We then define function prototypes for our implementation of our interface's functions. Again, duplication is required which could be automated if desired,
but otherwise must be made to match up manually (this is C afterall).


## Implementation
For the implementation of the printf version of logging, we will start with an instance of the Log struct, and then
define each of our functions. The global variable gv\_log\_print\_interface is not entirely necessary- its just used to copy
in the function pointers we will use for this implementation. The 'gv\_' is a convention for 'global variable' if you haven't seen
that before.
```C
#include "stdio.h"

#include "logprint.h"

// The Log interface must be filled out with the function pointers defined for this implementation. 
Log gv_log_print_interface 
  = { LogTextPrint,
      LogEntryPrint,
    };

// Implementations have custom init functions which provide
// whatever parameters are necessary for their particular
// use case.
void LogPrintInit(LogPrint *log_print) {
  log_print->interface = gv_log_print_interface;
}

int LogTextPrint(Log *log, const char *log_text) {
  printf("Logged: %s\n", log_text);

  return 0;
}

int LogEntryPrint(Log *log, LogLevel level, const char *log_text) {
  int result = 0;

  switch (level) {
    case LOG_LEVEL_INFORMATIONAL:
      printf("Info: %s\n", log_text);
      break;

    case LOG_LEVEL_WARNING:
      printf("Warning: %s\n", log_text);
      break;

    case LOG_LEVEL_ERROR:
      printf("Error: %s\n", log_text);
      break;

    case LOG_LEVEL_DEBUG:
      printf("Debug: %s\n", log_text);
      break;

    case LOG_LEVEL_TRACE:
      printf("Trace: %s\n", log_text);
      break;

    default:
      result = -1;
      break;
  }

  return result;
}

// There is nothing required to close this log, as it only prints to std out.
int LogClosePrint(Log \*log) {
}
```

To initialize a printf log, we just copy the function pointers from our implementations into the Log struct we are given.
In this case that is all we need, but in general this function could do whatever is required to set up our log. Note that the
initialization function was left to the interface. This is because initializing may require any number of arguments so it is easier
to let the implementation decide how it is initialized, even though every implementation will have to at least fill out a struct
with its function pointers.


To implement a function, we take in a Log pointer. This is our handle, and it must be to a LogPrint struct. We accept a Log pointer to
satisfy our interface, but then cast it to the particular type of struct for our implementation (like subtyping of some kind).


In this case we simply take our arguments and print them. In the case of LogEntryPrint we also print out the log level.
Note that these functions would not be called directly- the user calls LogText or LogEntry, which then call a function pointer which pointers
to LogTextPrint or LogTextEntry.


# Discussion
So far we have defined an interface, which has to be done for each interface we want to defined (logging, serial, files, ethernet, etc) with a similar
header and implemenation file. Each one has the forward declaration of a struct, function pointer typedefs, a struct full of function pointer fields, and
function prototypes. 

The implementation file (.c file) contains implemenations that simple call the structs function pointers. This is done so that we can always call the interface's
functions, like LogEntry, regardless of the implementation. When we call that function, the result will be the function we placed in our struct when we initialized it.


Then, each time we want to define an implementation of this interface, we need a header file and C file which provides its own struct and functions. These can do
whatever we want. There are some implementations that could apply to any interface, like one that always succeeds (for testing) or always fails, or one that
takes two or more handles (pointers to struct with function pointers) as inputs and calls these, perhaps combining the results. This could be used to, for example,
tee off data from a serial interface to both the interface and a log. We could also define interfaces that act as proxies, which might for example modify data
before passing it on to another implementation, or might simply count how many times a function was called.

# Usage
Now that we have an interface defined, and an implementation of that interface, lets make use of it. We will set up our implementaion, and then
call our interface. The result will be that the behavior of the code depends on the choice of implementation, and the code using the interface would
not have to change. If this were a large codebase which required logging we could use an implementation that logs to a file, test by logging to
the screen, and perhaps calling out to a logging framework for production use.

```C
#include "log.h"
#include "logprint.h"


/* Main function using the logging handle */
int main(int argc, char *argv[]) {
  // Create our LogPrint struct
  LogPrint log_print;

  // Initialize it with a function specific to the LogFile implementation
  LogPrintInit(&log_print);

  // Log things, passing our LogFile structure.
  LogEntry((Log*)&log_print, LOG_LEVEL_TRACE, "Logging started");

  LogText((Log*)&log_print, "Hello, Handles!");

  LogEntry((Log*)&log_print, LOG_LEVEL_DEBUG, "Debugging info");

  LogEntry((Log*)&log_print, LOG_LEVEL_TRACE, "Main finished");
}
```

# Conclusion
In this post we have shown how to create a simple interface to a logging system, and produced a sample implementation which simply prints the the screen
for debugging. This concept could be applied to a wide range of iterfaces- operation system ones, drivers, hardware interfaces, or interfaces within 
a codebase. Once an interface has been defined we can produce as many interfaces as we want, and use them in whatever combination we want. The code
using the interface does not need to change- it would just take a pointer to the implementation struct (perhaps many struct if we have many interfaces).
We could spend some time constructing these interfaces, especially if we have to create higher order interfaces which transform other interfaces to add
features.


I believe that this concept could be useful. It provides some interesting directions for abstraction and extension of interfaces, and could be used to write
code that can be run on different operating systems, with different hardware, within a test framework, or against a simulator. This is important for complex
algorithms which must be run on a target system, but where testing and development could take place on a laptop.


Perhaps the most exciting possibilities are transforming interfaces to add tracing, logging, or other capabilties. This can be used to add cross cutting concerns,
adding and removing them without changing your code. I realize that this is like a Python decorator, and in fact it is like many things in many languages, but 
it is not what we are used to in C.


The real use case that motivated me to think about this was to abstract all effects (in the Haskell sense) from an algorithm with operating system dependancies,
and which occurs over time. The idea was to see if algorithms which are not pure mappings from input to output could be abstracted and run without the rest of
the codebase. I've found that this is indeed possible if all its interfaces to other code are made into these handle abstractions. I can run the algorithm outside
of the target computer, faster than real time, and add things like tracing, testing, and all sorts of capabilities to it.


Hopefully this is useful to someone. I hope to continue to talk about this concept in the future, as I think it is underutilzed yet provides a good tradeoff in 
complexity verse the advantages we get out of it.


