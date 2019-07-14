+++
title = "Flight Software Components - Events"
[taxonomies]
categories = ["Flight Software"]
+++
This is the first in a series of posts on different software components that I've seen in flight software systems.
This continues the theme of this blog as a place to talk about what flight software is like for me at NASA Langley,
where I work on science instruments for space, and some drone work on the ground.


It seems like programs in a particular programming domain there are certain software components that are in just about every production program. I
see this in games where there is always some kind rendering engine, often a physics engine, perhaps logging, events, user input
handling, configuration management, and all sorts of things. Its the same in flight software- most large flight software systems
seem to have certain components, and it is useful to understand what they are and what they look like.


I will go over as many of these systems as I can, and give some experience with uses and problems involves, different design choices,
and anything else I can think of. The discussion will be colored by my experience in class C and class B software for science applications,
which I know is different from human spaceflight, different from purely research code, and different from how many are doing things in industry.
In other words, understand what I say here in context- I have 7 years of experience in flight software at NASA, but that doesn't make me an expert
on space or even NASA software.


The discussion will focus on Langley software p have worked on, as well as of course the NASA flight software system [cFE/CFS](https://github.com/nasa/cFE).


# Events
Flight software systems always produce periodic packets of status information, called Health and Status or Housekeeping. These
messages are good for periodic information, sampled data like temperatures or currents, or counts of occurrances within the system. Its
not good for rare events, high rate information, or a large number of rarely used structures. Sometimes we want to report an error to the user,
a sequence of quick events, or produce a stream of events to give some insight into whats happening onboard. With periodic data we might need
flags to indicate events, and we would need space for everything that could possibly happen. The other option is to provide some kind of
asynchronous way to produce data to send to the ground.


Events, sometimes called software messages, provide a means to record this kind of data. Any important event, error situation, or the start, stop,
and progress of a long running process can be marked by an event. Usually these are very easy to add, and you end up with many (hundreds in my experience)
of individuals events that your system can produce. Examples would be the start of a file transfer, an error on a hardware bus, the receipt of an incorrectly
formatted command, or a limit exceedance. These may come with additional data, like which limit was exceeded, which file was transferred, what the
error was.


These events can come in many forms, and can be used in a variety of ways, which I hope to get into below.

## Whats in an Event?
Events are marked by calling a function that records the information for the event, and some meta information. This usually consists of an ID for the
software component that produced the event, and an identifier for the event that uniquely identifies it to the user. It may contain a text string for a
human operator to read, as in cFE, or it may be a series of fixed size integers, or a structure of data whose interpretation is dependant on the event ID.


One thing to consider is that the component ID and message ID can be very useful for filtering messages. You can even use events for fault detection- if an event
indicates a particular problem it can be tied to a fault isolation or recovery system.


## Timestamping
One consideration that I've learned is to make sure that each and every event is timestamped to at least microsecond accuracy. It is extremely useful
to be able to trace what happens in your system with that level of resolution. One way to do this is to queue the information provided in the event function,
along with the timestamp, and then to have a task that retrieves from this queue and turns events in packets.


This might be useful if an error occurs and you want to correlate it with other data, or there is a sequence of events that need precise timing and you want
to record the actual times, or different parts of the system are performing coordinated actions, and the timestamps show the true sequence that occurred.


## Severity
One additional feature we can add here is to mark each event with a severity. These are very much like log levels, and indicate how to show or process the event.
Examples are Informational, Warning, and Error. Other severities are possible, like Critical error for errors that may prevent the system from continueing to operate.


One consideration when deciding on severities is that they must be used consistently throughout the system. The severities are provided with the event data by the code
that generated the event, and chaning them will likely require a software update. It should be possible to tie events to a table of severities if you really wanted them
to be updatable, but I've never gone down that route.


Its very important to have a consistent idea of the meaning of the severities when considering the reaction of the ground system. The limits in the ground system 
may or may not match the severities given by the flight software, and it can be messy when two systems disagree like this. If the ground system is the only place
where the severity is used, consider checking the event IDs in the ground system and not in the flight system for flexibility and consistency.


Another thing to consider is whether a particular event can have multiple severities or not. It can happen that the same situation is sometimes good and sometimes
bad, so it may come with different severities. There is an option to make a new event in this case just to keep severity consistent and tie it to the event identifier.

## Event Contents
The cFE style of events as text strings has some advantages- it makes it very easy to read a log of events and understand what your system is doing. There is
no extra effort required when an event is added to the software to display it- it comes with its own text representation. This is very convienent for some systems,
but certainly has its drawbacks. The main problem is that text is not easy for computers to process, and if you want to look through the data associated with an
event over time programmatically, text strings makes it very difficult to get this. 


The other possibility is to provide binary data. This does make it hard to display to a user- you need to register each message somehow, and possibly provide a
way to turn its contents into a string. I've done this with an AWK script before which produces the code to at least name each event, although in my experience
its too much work to truely decode each event, and we don't end up with good reporting on events.


Whether your events are going to be binary or strings you have to consider the problem of multiple arguments. There are several variations here- for strings you
might want to implement printf style formatting system so that your text strings can contain parameters relevant to the event, or for binary data you might want
to provide a variable number of integer arguments. You could also just provide a pointer to a buffer contain the event data for event systems with binary data,
but its much easy to just provide a couple parameters then to create a struct when calling the function to create an event. If you are using C++ the binary event
data case becomes simplier because you can provide default arguments of 0.


If at all possible, use __LINE__ when producing events to get the exact location in the code that the event occurred. In principal __FILE__ could be used, 
perhaps by mapping files to integers, or just by transferring the whole file name in the event message, but in my experience the line number and module ID
is enough to find the exact location within the codebase that generated a particular event.


## Generic Messages
There are many situations within a system that merit an event that are common across modules, like a full queue, an errno from the operating system, or
a command that contains out of limit parameters. In this case it is possible to define either- a separate event ID for each situtation for each module,
or a generic event ID used by all modules. In the latter case, the module ID is used to uniquely determine the source of the event, so there is no 
confusion despite the shared event ID. There are advantages to both designs, either resulting in perfectly unique events which can mean slightly different
things in each module, or shared events which reduce the number of events, make it easier to filter and process events, but which might result in slightly
different uses across different modules.


## Whitelisting/Blacklisting
One final consideration is whether you want to protect against situations in which a module starts to send out messages continuously. Usually its better
to avoid event messages when something occurs often (which would flood the list of events making it hard to find useful information). However, sometimes
an error can cause a code path to occur more frequently then expected and an event may start to flood the system. In this case, it may be worth while
tracking the number of messages received over a time period (say, 1 second) and then rejecting new messages after a certain limit. This can be done with
a table of module ID, counting the messages from that system, or could be done on a per-event ID basis. When a module or event is blocked, it is
added to the 'blacklist' meaning its events are rejected until a command is sent to accept them again.


The nice thing about a mechanism like this is that in the event of a problem that causes a flood of messages, there may be messages from other modules that
explain what happened that would get rejected if the module in error is filling the queues for events. Its also nice because you can avoid having your system
spend a lot of time recording events, and filling your storage if you store them. 


If you add this feature, consider having a way to 'whitelist' the module, allowing all of its messages ot get through. This is important in cases where you
do actually want all the messages, or a module is so vital that you want any data it produces even if it drowns out messages from other systems.

# Events in Ground Systems
Most of this post has been about events in the flight software, but there needs to be work on the ground side as well. Events are like a log, 
and are very useful simply as a list in chronological order. In addition, special processing is often useful for certain events, as they might
provide information like the start and end times of data capture that can be visualized separately and give insight into what the system has 
been doing.


Another consideration is limits for events- events are not like temperatures which can be limited with persistence, but are rather discrete things.
If an event indicates an error, it can be shown as an out of limit condition, or even shown as a separate kind of limit indicating a state of the
system. When an event occurs that indicates a warning or error its very important to understand why- even a warning could indicate a larger problem
if not fully understood. I've seen cases where a warning indicated a failure of a major part of a system, where the first manifestation was a queue
filling up and resulting in a periodic message.

# Conclusion
This was a fairly short post, but events are not exactly the most complex thing. They are just a way to add logging to a system that does not work well with
text logging, where we are more likely to produce binary packets then lines of text.


If you are creating an embedded system, definitely consider adding an event system. It is a huge help for reporting information, tracking what your system is
doing, getting to the bottom of anamolies, and generally getting insight into the operation of your system.


Thanks for reading!

