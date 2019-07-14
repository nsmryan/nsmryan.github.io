+++
title = "Purely Functional Genetic Algorithms"
[taxonomies]
categories = ["Functional", "Genetic Algorithms"]
+++

This post is about what a Genetic Algorithm would look like if seen through the lense of functional programming.
This means we will look at functional programming techniques and see if they have anything interesting to say about
Genetic Algorithms (and perhaps evolutionary algorithms in general). This post will focus on data structure choice more
then architecture or design, but I think there are interesting things to say about these types of topics as well.


You do see functional programming in Genetic Programming sometimes, but this post is specifically about
Genetic Algorithms.


Why is this Interesting?
========================
I believe that by making use of some unconventional thinking in the implementation of a Genetic Algorithm we can get some
performance improvements that you would not normally see. It seems like the GA literature generally considers
performance a secondary concern with these algorthms- the conventional wisdom is that fitness evaluation for your particular
problem is *so expensive* that the GA performance doesn't make much or any impact. This is predicated on an unstated premise,
which is that the GA itself is independant of fitness evaluation, and can't effect its performance.


I believe that this is not true, and that the use of a couple of fairly simple changes to a GA can actually speed up not just
evolution, but also your fitness evaluation. This is a pretty strange claim, and unfortunately I don't have the benchmarks to
show for it. I have had this idea for a while, but I don't have the time to put in the work to prove it, so I wanted to get
this concept out there in case I never have a chance to show it empirically.


To avoid keeping you waiting- it looks like you can reduce the algorithm complexity of a GA from its usual, imperative,
implementation while also using structural sharing to reduce the size of the population, which should result in better cache
use when performing fitness evalution. It may be that this does not have enough effect in practice to counter the branching
data structures we will use, which is why it needs to be evaluated in practice.


There is another aspect to this that I think is of independant interest, which is whether the functional programming community
has something to add to the machine learning discussion. There are other [examples](http://colah.github.io/posts/2015-09-NN-Types-FP) of this ,
but I haven't seen the equivalent for Genetic Algorithms. I think GAs are an interesting thing to point this FP light on because their
usual implementation is very dense and mutation heavy, which is very different from the tree structures and immutable structures we see
in some functional programming languages.

This post is not quite at the conceptual level as the neural network posts, but currently the only example of a GA paper from the FP community is
a simple implementation
[A genetic algorithm framework using Haskell](https://www.researchgate.net/profile/A_Garmendia-Doval/publication/2411892_A_genetic_algorithm_framework_using_Haskell/links/53d6c7840cf220632f3ddb04/A-genetic-algorithm-framework-using-Haskell.pdf),
and a number of very good an interesting, but fairly traditional libraries.
I may be wrong about this, but this is what I have been able to find.


Lets Look at Genetic Operations
===============================

Mutation
--------
*Speeding Up Mutation*


Lets start with mutation. Nearly every GA library I've ever seen (and I've checked dozens) implements mutation as a loop which
checks whether to mutate each index of each individual. I've seen some libraries that technically cheat and just mutate a fixed
number of locations: 1 / pm locations, where pm is the mutation rate.


I've found that this is a particularly slow operation- if you are evolving an individual of bits, you have to inspect every single
bit and generate a random number even though most bits will not be mutated. Instead, we could just sample from a geometric distribution
which tells us how many locations to skip before the next mutation. Sampling a geometric distribution tells you how many times a 
biased coin would land on tails before the first head. This means that a sample tells us how many times we would have passed over
a location before we mutated one without actually checking each one individually!


This technique is not actually specific to FP (although we will see some implications later to this choice), but I've never seen it
done in the wild.


Note that this idea works best for low mutation rates- as your mutation rate goes up this will actually become slower. For a mutation
rate of 0.01 (1% of locations mutated) we can skip an expected 100 locations per jump as the expected value of a geometric distribution
is just one over the probability of success. If our mutation rate is 0.001 then we will skip an expected 1000 locations! However, if our
probability is 0.5, we are doing a more complex computation to get our random value then we would from a bernoulli distribution. This is
a tradeoff, and perhaps the library could switch when it estimates that the payoff is no longer worth it to avoid this slowdown.


*Mutation in a Purely Functional Language*
If we are going to make this purely functional, we certainly won't be mutating data while doing a literal mutatation operation. We also
don't want to do the naive method of copying all of our data and changing only the places we mutate- this would work, but it will put us
behind the imperative approach on our first operator!


Instead, lets use a data structure that allows us to traverse it quickly by splitting it, changing individual locations, and then concatenating
the results. As we will see later, a (finger tree)[http://hackage.haskell.org/package/containers] is a good choice for this kind of operation, taking
log time (its actually better then log time, but for simplicity I will refer to it as a log time operation).


To do this, we would sample from our geometric distribution, split our individual at the location we get (a log time operation), mutate the
head of the resulting list (a constant time operation), and continue.


Note that even this is not as fast as it would be if we directly modified data. We have turned the usually random access to the individual into
a log time operation to get to the data we want to change, and a log time operation to put it back together. Technically, the log is not of the 
individual size, but of the expected number of locations we skip to get to the next mutation, making it p\*n\*log(1/pm), which is still a 
p\*n complexity with a weird constant.
However, we will see later that this data structure choice will result in a lower algorithmic complexity for the GA overall, so bear with me.


*Complexity*
For those of you keeping score, the complexity of mutation is usually the size of the population times the length of the individuals- p\*n lets say.
The geometric distribution does not technically lower the complexity from being linear in the length of the individuals, but the constants should be
more like p\*n\*pm where we multiple the amount of work my the mutation rate. Due to our functional data structure's log time features, we end up with
p\*n\*\*pm\*log(n) as we have to do a log time operation as many as n\*pm times.

Okay, so far we are slightly worst then the imperative implementation, but keep reading.


Crossover
---------
In a typical implementation of a GA, crossover involves copying or swapping data between individuals, resulting in an operation that is linear in the
length of the individuals, and linear in the number of individuals.

This is where our choice of finger tree starts to pay off- splitting and concatenating finger trees is only logorithmic! This leaves us with a complexity
that is p\*log(n), which is better then the p\*n we get in the imperative setting.


Selection
---------
Selection is a population-level operator- the selection operators (examples being roulette wheel, stochastic universal sampling, tournament
selection, etc) don't make use of the particular representation of individuals. So far we have not nailed down what structure to use for our
population itself.

Morally, a population is usually a multiset, except for a cellular genetic algorithm where you introduce some kind of topology.  However,
for simplicity and speed we can just use an (array/vector type)[http://hackage.haskell.org/package/vector]. At first this seems like we are not
gaining anything on the imperative implementation, but in fact our choice of an immutable data structure has started to pay off. When we select
an individual more then once, we don't have to copy them at all! Our vector simply points to the same individual multiple times, safe in the knowledge
that it won't change. This moves us from an p\*n operation (at worst the whole population has to be moved during selection) to an p time operator, depending
only on the size of the population. This does not take into account any processing we need to do for a particular selection algorithm which should not
change from the usual implementation.


While this reduction in complexity is great by itself, there is a more subtle effect here- after the first generation, some individuals will start
sharing the same data (structural sharing). Even after mutation and crossover, much of the data will continue to be shared. The amount of shared
data seems like it is related closely to the diversity of the population, so as the population converges and diversity falls, the amount of memory
that your population takes falls with it.


I would expect that this could have an effect on both the performance of the genetic algorithm, and of the fitness function. The fitness function is working on a
potentially much smaller data set then it would other be working on. There is a tradeoff however- the tree structures may be splayed out all over memory at this point
and we may actually lose all the gains we got from our smaller data set. There is some possibility of "compacting" the population at some point, organizing it
to avoid some of the problems here, but I don't know right now how we would do this or if it would mitigate this problem.


Conclusion
==========
The resulting algorithm should go from a p\*n + p\*n + p\*n algorithm to p\*n\*log(1/pm)\*pm + p\*log(n) + p time algorithm. The complexity class has not
changed, and mutation will be slower (by a log factor, which isn't so bad) compared to the imperative algorithm (if it implements the geometric
distribution trick). However, crossover and selection seem like they should be much, much faster, and there is potentially gains in cache
usage as our population diversity decreases.


As mentioned, I would love to see some fair benchmarks that show whether this works in practice. I'm truely not sure whether data set size or predicatble organization
matters more on a modern processor.


Also as mentioned, this post did not mention the application of functional programming techniques to the concept of Genetic Algorithms, their architecture, or to the
implementation of their operations beyond data struture choice. I have thoughts on this as well, but the use of finger trees was the concept I wanted to get out their
first.


Thank you for reading!
