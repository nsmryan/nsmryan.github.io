---
title: Lua Tables
author: Noah Ryan
---

This is a post about Lua's tables. Its not an introduction (its gotten too long as it is) but rather some thoughts on their uses, how they fit into the context of structures
in other languages, and some of the trade-offs that they make.


Lua tables are odd structures, mixing an array, a key-value map, or a namespace, or an object depending on how you use it. It can be other things too, if
you play around with meta-tables. It can even mix and match between these, which creates hybrid use-cases.
A language with a core data structure is not unusual, and comes with some trade-offs. I have been finding that the Lua table takes an unusual place in the scheme of core data structures,
being more flexible and powerful then the core structure of other languages.


There are many languages that have a single data structure that is core to their mentality, or at least implementation. They are "core" in different ways, and play different roles- the
thing that ties them together is just that using the language means understanding the relationship between the structure and the language.

This can be in the everything-is-an-X (or almost-everything-is-an-X), like how in python (and other languages) everything is an object.
It can also be that a language has a core data structure, even when it has other primitive structures, like linked-lists and Lisp.
For Forth, everything is a cell even though the core unit of organization is a word (like a function, not a machine word). 
In C everthing is an integer- function pointers, pointers to anything, return codes, enumerations- everything ends up being an integer.


This is not necessarily the best approach, for a number of reasons. One is that building a universe of structures out of a single structure means that 1) the core structure
will fit some situations well, and some less well, 2) if the core structure is complex, the result will be complex (like in the case of objects), but if the core structure is simple then
the result will consist of a complex arrangement of simple things, which leads into 3) which is that programs will usually rely on a convention or concept of what the larger structure is
supposed to look like without any way of inforcing it. This last one is especially bad in dynamic languages where you have to understand the complex structure though reading code and 
documentation, and trying to imagine how its supposed to look. 

In the case of Lua Tables, the core structure is somewhat complex in that it can be used in a number of ways, and contains some unusual features (metatables in particular).
However, it covers so many common situations where you need to organize data that you end up using basic tables for almost everything.
For example, they cover the case TODO



For my plug for good type systems, its worth mentioning that in some languages (Haskell) the type system makes many more distinctions between structures, allowing more structure to be described.
This means that the complex structures are made of a set of simple basic structures, composed in a set of simple ways. This leads to structures that can be understood and checked statically.
I won't go too much into this- its been described enough elsewhere.

