---
title: Sampling Discrete Distributions
author: Noah Ryan
---

I just wanted to point out a fantastic article on [sampling discrete probability distributions](http://www.keithschwarz.com/darts-dice-coins/).
I came across it when thinking about genetic algorithms, but it is a general description of sampling algorithms ending in a constant time sampling method
with linear setup and memory use, which is quite cool.


There are other related algorithms, like [reservoir sampling](https://en.wikipedia.org/wiki/Reservoir_sampling) and
[weighted reservoir sampling](https://blog.plover.com/prog/weighted-reservoir-sampling.html).


There are also condensed probability tables, which produce O(1) sampling from a set of weighted items, implemented
[here](https://hackage.haskell.org/package/mwc-random-0.13.6.0/docs/System-Random-MWC-CondensedTable.html).


The last thing I wanted to mention is an algorithm that I have forgotten the name of, but lets you turn a Bernoulli distribution with p != 0.5
into one where p = 0.5, which can be used to generate uniform random integers in a computer. Here is what you do- look through the stream of
bits for a transition from 0 to 1 or 1 to 0, dropping any sequences of identical bits. When you see a transition, emit a 1 for a 0 to 1, and a
0 for a 1 to 0 transition. Each transition occurs with probability p * (1 - p), or (1 - p) * p, which is the same.


