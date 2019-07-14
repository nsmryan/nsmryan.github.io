---
title: Limitations of Rust so Far
author: Noah Ryan
---
This post is an update on my recent adventures in Rust. A lot of my posts are about what I have
enjoyed about Rust, but this post is about limitations I have run into at times.


I believe that these are true limitations, but there may be a way around them. The main take-away
is that I haven't been able to express certain concepts that might be possible while using Rust.


# Free Arithmatic Expressions
Recently there was an algorithm that I wanted to study, written in C. The algorithm makes use
of only arithmatic, looping, and conditional statements, so it was easy enough to port to Rust.


Once I had a Rust port, I started to play around with performance and with the number of floating
point operations performed. What I wanted to do was to reify the expressions into a tree structure,
so each variable would hold a tree indicating how it was built. I could then traverse the tree
to see how many operations had been performed to produce a value, and potentially find duplicate
work being done and optimize it away.


The problem I ran into is that I wanted to overload the arithmatic operators, like Add, such that
they took an expression and produced an expression. However, my expression type needed to be heap
allocated, so it was not a Copy type. This meant that I either needed to put ".clone()" in dozens
or hundreds of locations, making the code extremely difficult to read, or I needed to calculate the
answer directly instead of building a tree first.


In the end, I came up with a type that was a struct of counters, one per type of operation- addition
subtraction, multiplication, and division. I then implemented the arithmatic traits for this type, 
which was simple and implemented Copy. 


This solution did get me the main thing I wanted, which was the number of operations performed by the
algorithm, but it would have been nice to have a full syntax tree, and I might have been able to get a
better result that way.


If there is some way to implement this, I would be interested to know. I could not reason my way out of the
conflict between needing to own a piece of data, allocate that data on the heap, and return things from a function
that are allocated on the stack. I kept running into one problem or another and could not escape.

I did consider something like a large buffer and creating, say, a postfix or prefix representation, and then
translating that into a tree later. This had similar problems, but might be workable.


# Endianness
I had a mostly positive experience writing my first crate (ccsds\_primary\_header), but I did run into some problems.


One problem was working out configurable endianness for the fields- the standard enforces big endian data for the header,
but I've seen an implementation that does not, so I wanted to support that use-case. I ended up parameterizing the
header type with either BigEndian or LittleEndian. I then could introduce a trait like Endian, implemented by
BigEndian and LittleEndian, essentially a type level enum, and write functions that take any type implementing Endian.


However, at some point I wanted a function that swapped from little endian to big endian. This function should have been
trivial, as the data did not need to change at all. However, I found that I could not express this concept- I wanted a
BitReader<E> such that E: Endian, in order to read in one endianness and then write in another. I could not get the two
endianness to work out. Unforunately I can't remember the details anymore, but writing a BitReader with the correct endianness
and swapping the endiannes did not work out as I wanted it to.


In the end I implemented the conversion I needed (little -> big) manually by creating a new PrimaryHeader and swapping the bytes.
This works fine, but in general might have been a lot of work that needs to be done manually.


# Closures
I have spent a good bit of time reading about and writing Haskell, so a lot of techniques and ways of programming that I might
reach for involve higher order functions. The support for this kind of thing in Rust is limited by the somewhat complex interaction
between ownership/memory allocation vs higher order functions. I have often found that I am not sure what the correct way to handle
such functions is, and that I run into problems trying to use them.


Often an 'impl Fn' solution can work, or a Boxed closure, but it does bother me that these functions all have different types, even if
they take the same input types and produce the same output type. Composing functions, especially when there are multiple options, is 
somewhat confusing, and while I tend to understand what I'm doing while I'm writing code, I soon after forget why I used a particular
type of closure.


I expect that this is partially lack of experience, and Rust certainly provides a lot of control, but also falls into this realm of
'if you *can* reason about a part of your program design, you *have* to reason about it' where I have to think a lot about memory
when I want to do something abstract. I'm generally happy to make this tradeoff, but sometimes I just want a fully boxed world
like Haskell where you are so free to forget about implementation details.


# Conclusion
Hopefully this post is not too lame. I don't have good documentation on the problems I ran into, only that I struggled with problems
that seem relevant to Rust related to memory, onwership, and a type system that is advanced for a system's language but not as advanced
as Haskell's.


My personal take-away from this is that I'm willing to put up with this kind of problem occasionally because Rust has been 
so nice to work with and so much better than what I was doing before.
