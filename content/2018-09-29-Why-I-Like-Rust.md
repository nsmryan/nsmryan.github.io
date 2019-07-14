+++
title = "Why I Like Rust"
[taxonomies]
categories = ["Rust"]
+++
I've been very much into Rust recently. I try to write some Rust every day, and I've
released two crates to crates.io (an implementation of the CCSDS Primary Header, and 
Rustic bindings to the C library jsmn).


When asked why I like Rust, I have only been able to give partial answers. I hope this
post can give a more complete answer. The take-aways are that Rust fulfills a set of
required criteria for use in my work, it provides nice things built in to the language
and ecosystem, ways of thinkings that
make software development fun, and it provides a set of tradeoffs that fit the needs
that I personally have in the programs that I write.


## Criteria
In aerospace software work, there are some fairly strict criteria on what languages are
even potential candidates for us to use. Rust manages to fulfill the criteria that I personally
have, which is so rare that the only other languages I can think of that do this are C, C++,
and perhaps Ada (although I've never used Ada). I'm not saying there are no other options, just
none that I'm familiar with.


### No Garbage Collection
One example is that a garbage collected language is
a complete non-starter for us- the complexity and lack of control over latency is a real issue. As
I've noted in other posts, we don't release memory, much less allow it to be collected- you
ask for as much as you need and you stay within those bounds. We also are usually more
concerned about latency then about throughput- we often have fast enough processors to do the
work, but we need to get certain things done in tight time constraints.


### Memory Layout
Another criteria is control over memory layout- we often deal with packets and other structures
where every bit and every byte must be placed correctly in memory. C provides this control, although
for bit layout it is either messy or non-portable, but you can do it. If a language does not
provide this control, or requires marshalling and unmarshalling into its internal structures, it is
not a non-starter, but its a big impediance mismatch that effects a great deal of code.


### Maturity
Immature languages can be a non-starter. Rust fall into this to a certain extent, but the
difference is that it looks like it is going to be around for a long time, while many other
languages that have promised to be safer systems language seem to have faded out or never
made it beyond the original group developing them. 


### Integration with C/C++
Integration with C, and ideally C++, is a must-have. There is just too much code written
in C/C++ out there that we depend on to ignore this. Rust's FFI is the best that I've personally used,
and I've found that bindgen allows very easy binding generation. I would imagine that Rust could
get into aerospace in small pieces, replacing a module here and there, and interoperation with C/C++
is what would allow that to happen.


### Simplicity
Ideally, any language we used would be very simple- the more concepts that you introduce into your
programs the more interactions between those concepts are possible, and the more ways you can make
mistakes. With C++ we deal with that the way I think everyone does- we use a certain subset of the
language. I could see something like this with Rust- restrict how we use abstraction, probably
forbid macros, perhaps limit use of Traits, things like that. This would have to be developed out
of experience developing high-assurance Rust, which I certainly don't have.


### Safety and Restrictions
The last criteria that I can see would be restrictions- I want a language that is more restrictive in
what it allows me to do. There are a lot of ways to make mistakes in programming, and I am more concerned about
preventing mistakes then about moving quickly. I want as large a class of mistakes as possible to be caught
automatically and every time I compile so I can focus on the more complex issues and system level problems rather
then the low level memory use problems.
In this area, I may actually want Rust to be more restrictive then it is, but I don't have enough experience to say.

## Rust
Not only does Rust seem to deliver on all of my requirements, it just feel productive, and it provides so many nice things that make software
development a better experience. I was used to an integrated build tool and easy dependancies from Haskell, and 
a mess of different tools and difficult dependancies from C/C++. With Rust, cargo has been easier for me to learn
and less error prone then stack (in my own experience), and I have had remarkably few issues with building and
dependancies. 


Rust feels to me like a mixture of Haskell and C, with good parts of both and very few compromises on each.
I like thinking and modeling problems in terms of algebraic data types, and I like knowing how my memory is
arranged, and knowing when my code is doing what. As much as I like Haskell, it was hard for me to give up
that kind of control, even though I understand the composability advantages of lazyness and the advantages of
immutability, I wanted more control, and perhaps I also just wanted more of what I was used to in other languages.


In C I feel like I can never go beyond a certain level of abstraction- the language is just too primitive
to think very abstract thoughts. Very often I don't want abstraction, but when I do it is not available.
On the other hand, Haskell is very abstract and we can think thoughts that I would find almost unimaginable
in C. Rust is a middle ground- there is enough abstraction that I haven't felt confined, but not so much
that I don't have control over what is happening. This did cause me some trouble in Haskell, where the barrier
between Haskell and system was always hard for me to cross and feel like I understand exactly what was happening.


I like the fact that data is immutable by default in Rust, and I am so very, very glad that Rust uses a 
type-class-like mechanism instead of being Object Oriented. I don't think I would have ever started writing
Rust if it supported, or even just encouraged, object oriented programming. The Trait system has worked out
well for me so far, although the syntax can be a bit complex when handling type variables. However, I am willing
to put up with small things like that for a safer system's language. The automatic deriving mechanism is similar
to Haskell, where you tie your data types into the language and ecosystem in a very lightweight way. I haven't
tried to do my own automatic deriving, but at least it is possible.


There is not as much advanced type theory as Haskell, but since I don't program in Haskell enough to effectively
use much of its abstractions, they were always more of a distraction. In Rust, I just do what works using tools
that are more familiar, and it doesn't both me if there is duplication or things aren't perfect the way it would
in Haskell. This is mostly my own fault, but Haskell programming never felt as productive as I feel in Rust.


Speaking of productivity, I like that Rust is fast. I write a lot of C, and I kind of expect performance, so its
nice to know that I can generally expect high performance on normal tasks in Rust. I know that for many tasks,
performance isn't really that critical, but its nice to know you can get it when you need it, and its just nicer
when things are fast.


The memory safety of Rust is another huge advantage for me. Its not exactly that we have a lot of memory corruption
issues at work, but when they do happen they are hard to track down, and can cause very bad things to happen. I
don't like knowing that there could be hidden issues buried somewhere in our code base that could cause a crash
some time in the future- there is just no way to be completely sure we did everything right everywhere even with
static analysis, reviews, and multiple levels of testing. If we could use a more restricted language, even if only
for certain modules, it would reduce the error surface of the code and give me more confidence in its correctness, which
is a big deal. Its especially a big deal because it is not a separate tool, or a proof in a formal methods system, it is
built in and run every time you compile- its likely not as complete as a more expensive formal methods approach, say, but
it is fast and automatic.


Rust also just has nice features, like integrated tests in code modules that reduce the barrier to testing. I can
just put in a couple quick sanity checks and run them at a moments notice, or every time I save, with no
extra infrastructure or work on my part. I haven't used the built in benchmarked, but I hope it is as easy
as testing. That is not to say that I'm doing testing the best way in Rust, but the lower barrier to entry
just makes it so easy to get started.


One features that makes a big difference to me is error handling. The Option/Maybe type and Result/Either type
are not new to me, but being able to use them in embedded code is a big deal. My C code spends much more time
checking for errors then actually doing work, and propagating errors within a code base takes a great deal of
effort. I've seen places where C's error handling leads to very inconsistent mechanisms even within related code,
and it is a lot of work to try to ensure all errors are checked, handled correctly, and propagated throughout the
code correctly. I like the idea of the '?' operator, and I could imagine it replacing my current strategy of
surrounding all code blocks in a check for whether any errors have occurred.  In VxWorks this looks like
```C
STATUS result = OK;

result = XX_SomeFunction();

if (result == OK)
{
  result = XX_NextFunction();
}

if (result == OK)
{
  result = XX_AnotherFunction();
}
```
which would become
```Rust
XX_SomeFunction()?;
XX_NextFunction()?;
XX_AnotherFunction()?;
```

I've also just found that when I wanted something, Rust has had an answer that fits well in my use-case. When I wanted
to generate bindings to a C library, there was bindgen, when I wanted control over my memory layout, there was repr(C),
when I wanted to allow a choice of compile directives when compiling jsmn in the jsmn-rs crate, there was features,
when I wanted to decode binary data, there was bytes. One of the first things I did with Rust was try to cross compile
it for an ARM board I had, just to see if it would work, and I was amazed by how much easier rustup is to use compared
to cross compiling in C. 


## Some Negatives, to Balance out the Post
Of course, there are some areas of Rust that are not ideal. I'm will to accept a lot of issues to get all the nice
things Rust provides, and I don't expect perfection, so these are not deal-breakers, but they are there.


One is that I find the use of macros in Rust a little concerning. I don't like looking at a library, and realizing that
it is some kind of DSL, the rules of which I have to determine from examples or documentation. They can be very easy to use at
times, but as soon as you want to go off the beaten path, or you need to know exactly how they work, there is a lot of work
involved in decoding them. This is partially my lack of familiarity with Rust macros, but it just makes me wonder what is lacking
in the language that the best way to express something is a DSL. I'm a fan of DSLs in general, but it just feels wrong to me
to use them for basic tasks. This is something I need to think more deeply about to understand the core reason they are used
so much in Rust.


Another issue is language immaturity- it would be a hard sell to try to get a newer language used on a large project at work.
Maybe on a smaller project I could get it in, but there is a lot of trust in experience in aerospace.


The Trait system, while I like it in many ways, can lead to situations where it is hard to figure out how to accomplish a particular
task. There is enough abstraction that the available functions you can call on a type can be a hunt around documenation. Its not
been too bad for me, and I'm used to this from Haskell, but at times I rely on documentation to provide examples, and have trouble
figuring out how to accomplish something due to the amount of type resolution one needs to do in one's head. Again, this hasn't
been a big problem, but the complexity is there, and its very visible in the docs section on Traits for certain types.


One aspect of Rust development I have had a problem with occasionally is compile times. They aren't as bad as I had in Haskell,
but they don't seem nearly as fast as C. Luckily we have 'cargo check', which helps a great deal, and I think the compile time
issue has seen a lot of work and is being taken seriously, but its worth mentioning.


When trying out Rust integration with CFS, I have found that the large object files it produces are a problem. If I needed to
uplink a 3 MB binary file just to update a single module, then it is a problem. I know that there are ways to reduce object
file size, but so far my attempts still result in orders of magnitude larger files then I get from C.

## Conclusion
So far I'm very happy with what I've found in Rust. I feel productive, and I feel like low level programming isn't so much work
and pain. I feel like I have the level of control that I want, along with enough abstraction to go beyond the confines of C.


Thats all I can think of for now. Rust on.

