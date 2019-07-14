+++
title = "First Experiences with Rust"
[taxonomies]
categories = ["Rust"]
+++

I've seen Rust mentioned here and there, but until recently I put off the investment
needed to learn it. Part of that was that I found the syntax a bit off-putting- 
some code seems perfectly reasonable, and other code is pretty intimidating
to a new-comer.


However, I have been thinking about safer embedded systems code, so of course Rust
entered the picture again. I wanted to write up my first experiences learning the
language, and hopefully continue to write about my journey.


## Getting Started
As someone who uses C/C++ for work, and who is interested in Haskell, I felt like
I should be able to learn Rust. So far, it does have some of the feeling of both
C and Haskell to me- more on that later.


I started with the [Rust website](https://www.rust-lang.org/en-US/index.html), of course,
and the [documentation](https://www.rust-lang.org/en-US/documentation.html). I found
that I could learn each concept with the example they give, and overall it was easy to
look through the major features of the language and get an idea of how to read a program.

## Cargo
It can be interesting to look over a languages package system (if it has one) to see what
the major libraries are and what topics the community has handled. There is a sense with
Rust of having some really great libraries, a lot of libaries in general, and a lot of
libraries with very good and consistent documentation. There is also a sense of
incompleteness, experimental libraries and libraries that are establishing themselves
in the ecosystem.


Many of the libraries I looked at either had very good documentation, or they were clear
that they were experimental and were not ready for widespread adoption.


As a Haskeller, I was interested in the Rust view of some major Haskell packages, like
quickcheck and parsec/attoparsec. It looks like there is a quickcheck crate (which turns
out of be easy to use) as well as other implementations of the quickcheck concept,
and there are several ways to do parsing depending on your use-case, but Nom seems to
be the major parser combinator library. Some things, such as lens, do not appear to
be as established.


## Tooling
I was very impressed with how easy it is to set up a Rust environment, start a project,
add dependancies, and get something working. I found it very easy to add tests as part
of my development process, which is very nice to see.


I also very much liked being able to get a particular toolchain with rustup. I was able
to compile with the msvc toolchain and the gnu toolchain on Windows, and I had a very easy time
up installing the armv7-unknown-linux-gnueabihf and getting a Rust program to cross compile
for an ARM system I had in the lab at work. I have had some much trouble with this kind of thing
in the past with C programs, especially on Windows, that this was pretty significant for me.

## My First Program
I had wanted to do some simple profiling of a telemetry processing tool I wrote in C using the
LabWindows development environment. All I wanted was to instrument some places in my code and
get a sense of how long each stage of the program was taking, but I couldn't find a tool that
was quite simple enough for me. I wanted to be able to instrument code on different operating
systems (VxWorks, Windows and Linux), and I really wanted something simple if possible.


Not finding anything to my liking, I thought it might be a fun thing to write up myself. I
tried to get the CFS/CFE performancing monitoring work, in case I could use it as a baseline or
as a possible target for my library, but I ran into a number of issues with that path and
abandoned it.


I called the library Demark (like to demarcate something) and, inspired by C libraries like
jsmn, I gave it the minimal number of functions possible. You could start a log,
add an entry, and write out to a file. I ended up with some additional features to make
the resulting log more useful, but it was still a pretty small library.


I struggled for some time with certain things that are easy in C (perhaps to easy?) like
casting a pointer to a buffer to a pointer to a struct. The repr(C) directive works
as expected, and I found the mem::transmute to do the casting. I did fight with
borrowing/ownership for a while, but I expected that at first. I'm still not completely
clear on how to manage that stuff, but better then at first.


In the end, I liked the Rust version of this library. It has the feeling of some of the
safety of Haskell, the pattern matching, the nice types, and immutable data. It also
has some of the feeling of C- I more-or-less know what my data looks like in memory,
when I'm allocating memory, using pointers, and feeling like you understand the cost
of your actions (again, more-or-less- I don't have a deep understanding of the assembly
or anything). At first I was concerned that I wouldn't always know when allocation
was occurring (this is very important to me) but I believe I will be able to control
allocation fairly easily and tell whether code allocates or not. I still have some
learning to do there. There is a great cheatsheet
[here](https://web.stanford.edu/class/cs140e/notes/lec3/cheat-sheet.pdf) which
I found a huge help. 


I did have a strange feeling the first time I put a print statement in my code- it feels
enough like Haskell that I expected to have to control my side effects more.


## The Problems
I did run into a number of problems integrating my library with some existing C code. In the
end, the 32 bit toolchain didn't work because of some linking issue, and the 64 bit one didn't 
work for reasons I can no longer remember. I also tried the msvc toolchain, but that ended up
creating a DLL that required a large number of dependancies that I didn't want to fulfill
in a LabWindows program.


In the end, I just wanted something that worked, so I rewrote the code in C and ended up with
a simple profiling library and viewer. This helped me find some slow points in the code, and
I would use it in the future if I wanted to improve that telemtry processor again.


## Conclusion
I would like to try Rust again- I am willing to put up with some rough edges and some initial
failures. I see a lot of potential, and I would love to be able to integrate Rust into my
everyday work. I could see trying to create some very fast tool, or experimenting with a small
software modules in Rust.


The interoperation with C is a huge selling point for me, and is perhaps the single enabling
feature of Rust for me to use it at work. I write a lot of C, and barriers to working with
C would make Rust a non-starter. Happily, I was pleased with the experiment even though it failed,
and I hope to contribute to Rust in the future.


I really like the emphasis on friendliness in the community- it is very important to me
to feel like a community will be friendly before I would consider contributing.


Thanks for reading!


