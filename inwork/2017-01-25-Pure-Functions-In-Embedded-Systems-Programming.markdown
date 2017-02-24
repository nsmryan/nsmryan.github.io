-G-
title: Pure Functions in Embedded Systems Programming
author: Noah Ryan
---

I've had some experiences recently where I've seen code written in C/C++ for an embedded system
that benefited from my experiences with Haskell. In short, I've found that pure functions make code more robust, easier to test,
easier to document, and easier to extent to new situations and changing requirements.
The only thing I've regretted using this technique is that I don't enough of it.

This post describes some of my experiences factoring out portions of
my code into pure functions on Class B and Class B Safety Critical software.


Briely, a pure should will always produce the same result for the same input, regardless of when or how many times it is run.
This prevents IO, global state, etc- anything that might modify how a function runs or make it non-deterministic.
This is a situation where restricting what abilities you make use of is a hugely powerful technique, and having the decipline to
enfore purity (in a language which does nothing to help you do that) yeilds huge benefits that pay for the time invested many times over.


---


In embedded systems, software is written as a series of modules, each with a particular task or roles within the system. Look at
Core Flight Software (CFS) for an example of this kind of architecture. There tend to be several types of modules. Some examples are
modules that that perform software tasks (ie routing messages, packaging data, monitoring telemetry), modules that provide utility functions,
modules that run a particular algorithm, and modules that interface with hardware.


All of these modules can benefit from pure functions. Code that does not need to interface with hardware is especially ripe for this
kind of design, but even modules that interface with hardware can section off parts of their processing into pure functions and get the benefits.


--- Fault Detection, Isolation, and Recovery
--- Vehicle Monitoring


