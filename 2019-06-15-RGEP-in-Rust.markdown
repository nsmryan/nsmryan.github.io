---
title: RGEP in Rust
author: Noah Ryan
---
# RGEP
I recently reimplemented [Robust Gene Expression Programming (RGEP)](https://github.com/nsmryan/rgep) in Rust.
This algorithm was the subject of my Master's thesis, and at the time I was very much into learning Haskell,
so I used it for that work. This post isn't really an introduction to RGEP- maybe I'll write it up again some time,
but this is more about rewritting it in Rust and seeing how it went.


The RGEP algorithm is a variation on a very interesting algorithm called Gene Expression Programming (GEP). This is a
style of Genetic Algorithm (GA), and is related to Genetic Programming (GP). Generally, GP algorithms create
trees as their genotype, while GEP algorithms create sequences of symbols (like a GA). It could be seen as a kind 
of Linear Genetic Programming (LGP) algorithm, although it would be a more declarative one then what I've seen in LGP papers.


Quick note- a lot of this post has become a list of reasons I am enjoying Rust comparied to writing this kind of thing in Haskell, and I
wanted to say that I love Haskell, and it taught me many important things. I'm moving away from it because it doesn't seem to
match the types of problems I want to solve, but we are still friends and I still use it for thinking and reasoning, and I still
feel the desire to model concepts in Haskell first.


# RGEP Library
This RGEP library has its history in several versions that I've written and rewritten, but was never satisfied with it.
Part of that was that I don't find that I am very productive in Haskell- I am always thinking about abstraction and whether something
is to "right" way to do something. Its clearly not the way to use Haskell, but it was a trap I was always falling into.


I thought about GA's in terms of algebraic structures, categories, pipes, all sorts of things, but never came to a real conclusion.
Maybe someone with deeper mathematical training and understanding could come up with something interesting, but in the end I just
wanted to get things done and didn't profit from so much planning.


In Rust, I don't feel that need. I just get things working and don't worry about making them fit into some conceptual
framework. I get more done this way. In fact, I've rewritten RGEP in Rust, done some benchmarking, and set up a couple of problems 
for it to solve!


## Determinism
I very much like the determinism of Rust, and the feeling of transparency. In Haskell, I didn't have a good sense of how memory
way laid out (which I am now used to thinking about in C/C++), or how it would perform. It was particularly hard to reason about performance,
at least for me, and it was hard to know exactly what my algorithm was doing past a certain level of thought. I believed it was
functionally correct, but what it did at runtime was very hard for me to understand or observe.


With Rust, I know the general layout of memory, and I can control how the algorithm manipulates the data more directly.
This has helped me optimize and test, even though I don't have the pervasive purity that I would get in Haskell. I also miss the more
advanced Haskell concepts- I occassionally run into the limits of Rust's type system, and run into places where it is much more
verbose and messy then Haskell. However, I am very happy with the move to Rust and don't imagine that I will look back.


I would say that I have to do more work in Rust then in Haskell- its harder to build up simple tree structures when you have to
explicitly box children or when the type system did not make it obvious how to express certain conditions.


## Type System
The particular type system issue I ran into was that I wanted to express the concept that a type implemented the Add trait, 
and that the result of an addition also implemented Add. Ideally I would also express that the output of Add for that type
was the type itself. I had to add that a type parameter 'A: Add<Output=A>' meaning that it implements Add such that the
associated type Output was equal to A. It was very difficult for me to find good references on associated types
that showed things like putting constraints on types.


Another issue, which I ended up not needing, was trying to say that the type parameter A's associated type Output for Add
must also implement Add, not just that it was equal to A. To say this, I eventually found that I needed to introduce 
another parameter B, express that 'A: Add<Output=B>', and then give separate contraints for B. I did not have an easy
time figuring this out.


The full function is: 

```Rust
pub fn plus_sym<A, B>() -> Sym<A, B> 
    where A: Add<Output=A> + Display + Copy + 'static, B:'static {
    make_binary("+", Rc::new(|a, b| a + b))
}
```

while in Haskell it might be:

```Haskell
plus_sym :: Monoid A, Show A => Sym A B
plus_sym = make_binary("+", \a b -> a + b)
```


Much simplier, without Copy, 'static, Display, the use of Rc, or the syntax around associated types. I'm willing to work through this,
though, for the tradeoffs described above.

# Testing
In a certain sense, Haskell is easy to test. Most functions are pure (or at least I try to program that way) and therefore
mostly easy to test. However, I always found that I didn't really know what my functions did, and when I had edge cases I had
a hard time debugging them.


I don't have a good debugging story put toghether for Rust at the moment. I've never connected it to GDB or anything- I just use
println and test cases. Strangely, the lack of a repl means that instead of playing around with a function, any testing I do
ends up in a regression test that I can rerun later, instead of trying to remember what I did last time.

# The Future
I see this library as my test bed for Genetic Algorithm and RGEP ideas. I occasionally have an idea around these
subjects that I would like to play around with, and I want my own implementation that I know intimately, and does not
rely on expressing operators as traits (which practically all libraries do, but I consider very limiting).


In particular, there is a very nice paper Creation of Numeric Constants in Robust Gene Expression Programming, which
tackles both the problem of creating constants and the problem of reducing the disruption caused by small mutations.
They have some great ideas that should one day make their way into this library.


I also often want to break out some core data manipulation framework, implement the genetic operators with it, and then
expose it as a basis for future operators. The idea would be a series of composable, optimized, memory access patterns that
could be used to build fast genetic operators.


One other direction that would be interesting would be to parallelism the library. It looks like other GA libraries in Rust
use Rayon, and that might be the easy way to add parrallelism. The library should already be fairly fast, but it would be
fun to benchmark it against other GA libraries in Rust and see what happens.

# Thoughts on Rust
I love the determinism of Rust, the easy testing, the easy benchmarking, the use of traits instead of OOP, the use of
algebraic data types, and the error handling. The extra work for convincing Rust to compile my code is totally worth it,
even thought I'm not usually that concerned about memory use. 


Its not a perfect language, and may not be the right one for this type of application. However, it has some nice features for this
kind of program- enough abstraction to express what I wanted to express, speed, and nice features for testing and benchmarking, 
so its certainly not the worst choice.

