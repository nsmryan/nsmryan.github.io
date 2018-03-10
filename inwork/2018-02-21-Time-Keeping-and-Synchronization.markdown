---
title: Time Keeping and Synchronization
author: Noah Ryan
---
Time keeping is a complex thing. I have had some small experience with time in embedded systems and I wanted to share some few
things I've learned
There are a number of techniques for different situations and systems and I will cover only a couple of them.


Schedules
===
Most systems run some kind of schedule, usually over 1 second, consisting of a series of slots in which one or more events may occur.
This is used to produce deterministic behavior in the system by sequencing events, and allows repeated tasks to be given a time to run.


There can be multiple schedules within a system. The system may have its own internal schedule, but may also be part of other systems schedule
by sending or receiving messages according to a schedule. In this case, the system can either manage the schedule, or it may be managed by 
another system and require other systems to fit within in.


This schedule is run off of some kind of hardware timer. This can be used to produce interrupts which are used to trigger some kind of behavior.
This interrupt can be used to unblock tasks by giving one or more semaphores. The task that runs can then be used to give other semaphores, or, in
the case of CFS (Core Flight Software), to put messages in a message queue.

This schedule could also be used to increment a system timer, marking the passage of time. Each tick will be a course increment- usually
in the range of milliseconds. A finer system timer will interrupt too often, and a course one (tens of milliseconds) will provide very 
few schedule slots. Some systems only need a small number of schedule slots, and we will get into other things that these systems can do
to provide time.


Its good practice to leave the first and last slots of a schedule empty. Its often harder to keep the first slots empty, as you sometimes
want to do something to start out a schedule, but any time you can free up leaves you with some slack.

This extra space can be used when slewing a schedule to keep it aligned with another systems schedule. It can be shrunk or streched because
it consists of empty slots.


Time Propagation
===
There appear to be two types of times: a time within a reference frame like GPS which is important for knowledge of absolute time, and
a free running time which is important for knowledge of relative time.


## Absolute vs Relative Time
Absolute time is important to correlate data, such as determining when an event occurred to match it with other data within the same or
other systems. Relative time is important to know the separation between events. Interestingly, relative time can be combined with absolute
time to produce a propagated absolute time by determining the relative time from a certain moment to the last time an absolute time was provided.


## Receiving Time
The best way to receive time that I know of is to receive a timestamp as a message, and then a signal for when the given time is the current time.
This is called a time-at-tone, as it tells you the time and then marks it. In this case the "tone" may be another message, but ideally it would be
a discrete signal that can be tied into an interrupt. 


This approach allows the receiver to very quickly apply the time- if the time has to be received without a tone then variations in message timing and
processing can introduce variation in the way the received time is used. If the time is provided with a tone we can mark it quickly- in an interrupt
if we are doing it in software, and in an FPGA if we want more control then software can provide. We can even make the time a smaller 
message- it only needs to contain seconds if the tone tells you when the second started.


Time Drift
===
All clocks run at different rates, and these rates are not necessary consistent over time. This means that if two systems maintain separate schedules,
and they do not synchronize then they will drift with respect with each other. This can produce problems as the two schedules move and you experience
all events within the schedules before and after each other- if there is any sequence that produces a problem then it will be seen at some point.


Time drift can be caused by hardware, and will vary with temperature. Certain oscillators are better at this then other, but I'm no expert in this area.
I know that there are oven-based oscillators kept at a stable temperature to reduce this effect.

Time drift can also be caused by software. Be careful to note how your system clock rate divides into your oscillator frequency. If there is a significant
remainder then this will show up as drift in the system as it is loses or gain small increments of time each time the system clock ticks. Note that even
small remainders can accumulate over time and cause significant drift.


One thing you can do to combat drift is to keep your system sychronized with the system that provides its time. This creates closer to deterministic
behavior- if you allow them to drift with respect to each other then you will see all alignments and interleavings of their schedule at some point in time.
If you sync them, then you will only see a limited subset of these. You might stil end up drifting across the other schedule in certain scenarios,
such as on startup when the systems are synched yet, or after one has been allow to drift.


Knowing that your system has some drift allows you to compensate for it if you need to. A system can detect its own drift if it has an accurate time
source providing it time updates, although if its source is very accurate you maynot really need to account for drift. You can just take the time source's
times and add your system time offset since the time arrived. This still allows the systems to drift, but only between time updates. This effect is very
small, and you might want to worry about other things like jitter in time stamping before you worry about drift between time updates, but you can try
to estimate the drift by inspecting your system clock when you get a time update (to see how much you drifted from your time source), by keeping a table
providing drift rates at different temperatures (temperature has a pretty large effect on drift), or even just providing a way to apply a fixed drift compensation
to your time.


Time Slewing
===
One mechanism for sychronizing two systems is time slewing. This is a way to move a system's account of time closer to a target time without moving too
fast and jumping time. This keeps the system more stable, especially if its schedule is tied to its timekeeping and jumping time would require moving
the system schedule.


Time slewing can be down by small increments in time over a period. Its better to only start slewing when there is a certain amount of time error-
you don't want the system to slew all the time. These slews can be problematic in a dataset as time can appear to jump forward or backwards. Anything
that is timed at the same level as the slews are made (microseconds or milliseconds, say) will appear to jump a significant amount.


Slewing is something that can be disabled during critical times, allowing time to drift. Keeping a consistent time by avoiding slews makes it easier to 
account for time in post processing, even if the system ends up drifting significantly during these periods.


Time Jitter
===
There will always be a certain amount of variation in when an event occurs within a system. This can be caused by variation in timing in communication,
or because of an interrupt that was in progress when another event should have occurred.


This jitter is usually a very small effect in time accuracy, but it can introduce other problems. The worst I've seen is that when two systems schedules
are not synchronized, and they drift past each other, then during periods in which the schedules are nearly aligned then the jitter can start to create
strange effects. Events in the two schedules can start to interleave in any order as they drift past each other, but while they are close enough in time
that each one's jitter determines which occurs first. This can occur for a period of time, depending on the amount of jitter and the speed that the
systems drift past each other.


The worst part of this is that any interleaving that causes problems will show up in these cases. This can even cause events that usually occur in order,
ABAB, can occur as ABBA, BAAB, or BABA, and can switch between them as the systems drift. The ABBA and BAAB situations can be things like a sampling of
data after it is received, in which case we might receive two samples before we read one, or read the same sample twice before we receive the next one.


There are ways to deal with these problems, such as queueing data, signaling when data has been looked at, blocking for samples instead of polling for them,
or polling at a rate that is at least twice the required rate.


Time Stamping
===
Time stamps are important for a lot of parts of a system. Recording the time a packet was created, the time an event occurred, or the time that a sample
was taken. One of the first questions that gets asked when doing analysis or anomaly resolution is when events occurred or how they were sequences, so
its important to timestamp as many things as possible.


The best way that I've seen to provide timestamps is in CFS. This software expects to receive a time-at-tone, and to mark its current timer's value
(the system time) when the tone is received. This means we have the high resolution system time along with the current time in the reference frame of
the time provider. We can then produce timestamps by taking the current system time, and using it as an offset from the system time that the last
time was received. This uses the system's fine time to offset the received time.

There are some variations in this mechanism that could be used to improve timestamping, although I've never had a chance to do this. 


ANother way to keep time is to mark off increments in system time whenever the system clock ticks. This can have a number of issues, but does have some
advantages. It is less sensitive to error in your time source (as the system marks its own time).

## Timers
Hardware timers are surprisingly simple- they are just counters. They start with a number and count upwards by one at a certain rate. The counter has a certain
number of bits, and will eventually overflow. The overflow bit is tied to an interrupt, which allows you to run code at after a certain amount of time.


You can set the timers to any number you want, so if you want to trigger the interrupt after a certain number of clock ticks just set the timer to the maximum
number it can hold minus that number of clock ticks (being careful with off-by-one errors). The timer will then increment, overflow, and trigger an interrupt.


A system may have multiple timers, and timers will have some circuitry around them to change their behavior. One of these settings is a subdivider, which essentially
slows the clock down by a certain amount, allowing the system time to tick multiple times before the timer increments by one. This can be used to time longer events
where the timer would usually overflow too soon.


Another important setting is whether the timer will reset itself, or whether it needs to be reset by the user. If you have to reset it, just realize that the code
that is doing the reseting is taking system clock ticks, and you will end up drifting in time if you don't account for the time taken to run your code.


If possible, use the finest resolution timer for your system clock, and use it to drive your timestamps. This timer can be sampled for timestamps, and to
determine where we are within a systems schedule.

## Collecting Time

## Timestamp Protection
Sampling the current system time may require some extra protection. The time can be changed by an interrupt, and it may need to be protected again
task switching or multiple access in case a time system updates it periodically.


The more subtle aspect of this is that if you store time in a data structure, and a timer interrupt updates this time, then realize that your time may change
between any two machine instructions. You can disable interrupts, or you can try to detect and account for rollovers that occur while you are reading your
system timestamp.


## Time References

Time References
===
One of the things that makes time complex is that every system has its own time frame. Every systems time is slightly different from every other- it
is offset from any other time, it drifts at a different rate, and its drift changes over time.

In addition to a system's own time reference, there are time references that are treated as absolute time references, like GPS, UTC, or TAI. If you can
get a GPS time directly, or get it along with a time-at-tone, then this seems to be about as good a time as one can get.


Whn using these time references, just realize that even though a time is in the GPS reference, it is not always a GPS time. It comes from a system that
reports time since the GPS epoch, but its account of time will be off of the actual GPS time by some amount.

Frame Synchronization
===

## Phase Locked Loops
One mechanism to keep schedules in line is to implement a phase locked loop in hardware. This 

## Collecting Error
Another technique, whose name I cannot remember, is to determine how much error you are making in your schedule by noting the difference in time between when your
frame starts and when it is suppose to start (such as when a discrete is pulsed indicating the start of a period). By accumulating this error you can start to reduce
it by modifying your schedule in a restricted way to make up time, or wait for another system's epoch to catch up with yours.


There are multiple ways to do this, depending on what you can control within your system. If you can set the start of your system's epoch freely, you can always 
change it to account for error in your schedule. If you can only control it by changing which schedule slot you are one (but not when those slots occur) you
can wait for your schedule to drift across the other systems schedule and modify your schedule to match the other systems.
