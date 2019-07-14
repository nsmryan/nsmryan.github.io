+++
title = "Lua Tables"
[taxonomies]
categories = ["Lua"]
+++

This is a post about Lua's tables. Its not an introduction (its gotten too long as it is) but rather some thoughts on their uses, how they fit into the context of structures
in other languages, and some of the trade-offs that they make.


Lua tables are odd structures, mixing an array, a key-value map, a namespace, or an object depending on how you use it. It can be other things too, if
you play around with meta-tables. It can even mix and match between these, which creates hybrid use-cases.


Core Data Structures
===================
A language with a core data structure is not unusual, and comes with some trade-offs. I have been finding that the Lua table takes an unusual place in the scheme of core data structures,
being more flexible and powerful then the core structure of other languages. I do wish for static types, and I'm not a fan of re-using a single structure for everything, but this situation is
at least an interesting point in that design space.


There are many languages that have a single data structure that is core to their mentality, or at least implementation. They are "core" in different ways, and play different roles- the
thing that ties them together is just that using the language means understanding the relationship between the structure and the language.

This can be in the everything-is-an-X (or almost-everything-is-an-X), like how in python (and other languages) everything is an object (I'm ignoring some technicalities to make the point here).
It can also be that a language has a core data structure, even when it has other primitive structures, like cons cells and Lisp.
For Forth, everything is a cell (not the same as a cons cell) even though the core unit of organization is a word (like a function, not a machine word). 
In C everthing is an integer- function pointers, pointers to anything, return codes, enumerations- everything ends up being an integer.

Tradeoffs
=========
Re-using a structure is not necessarily the best approach, for a number of reasons. One is that building a universe of structures out of a single structure means that 1) the core structure
will fit some situations well, and some less well, 2) if the core structure is complex, the result will be complex (like in the case of objects), but if the core structure is simple then
the result will consist of a complex arrangement of simple things, which leads into 3) which is that programs will usually rely on a convention or concept of what the larger structure is
supposed to look like (invariants) without any way of enforcing it. This last one is especially bad in dynamic languages where you have to understand the complex structure though reading code and 
documentation, and trying to imagine how its supposed to look. This requires dynamic information which is not immediately available and requires a lot of mental evaluation, making it difficult
to reason locally about code and data.


Lua Tables
=========
In the case of Lua Tables, the core structure is somewhat complex, and contains some unusual features (metatables in particular). It is essentially a mapping. If you give it integers
as indices, then it is like an array, if you give it strings as keys it acts as a namespace, and if you give it arbitrary values it is just a key-value map. It happens that integers
are treated specially so that you can get the length of the table as an array (for items with integer keys). If you give consequtive integers then it is an array, and non-consequtive integers
map a sparse array.

If you use strings, then they can be used with dot notation as fields of an object. Whats weird is that if you do both integers and strings, you get an object with access to an array. I'm
not sure that this is a good idea, but it does package your meta information with the array data itself.

The other dimension here is metatables. These expand the abilies of Lua tables in a couple of ways- you can specify the behavior in certain situations, like handling the situation where
a key is not found in a table (either to look up in a parent table, or return a calculated value, or anything else), intercepting indexing into the table, or to do operator overloading.
You can even use this to create your own object system if that is your thing. I'm no object oriented programmer, but I'm using the middleclass system in Lua and finding it not bad for
my toy games.


Some Experience
==============
When making the simple games with the Love framework, I've found these tables to be quite useful. You can have an entity that contains a grid of cells, and keep information about how many
cells are used within the same strucuture. You can create your own grid data structure which store your grid sparsely by using the index metamethod. You use the same structure for keeping
your entities in a structure as the entities themselves, and all your other data, so that you always know what structure to reach for.


Type Systems
===========
For my plug for good type systems, its worth mentioning that in some languages (Haskell) the type system makes many more distinctions between structures, allowing more structure to be described.
This means that the complex structures are made of a set of simple basic structures, composed in a set of simple ways. This leads to structures that can be understood and checked statically.
I won't go too much into this- its been described enough elsewhere.

