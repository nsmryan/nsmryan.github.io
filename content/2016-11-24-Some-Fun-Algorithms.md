+++
title = "Some Fun Algorithms"
[taxonomies]
categories = ["Algorithms"]
+++

There are many interesting algorithms and data structures out there, but here are just some that I like.

  * Hyperloglog- This is a algorithm for getting an approximate count for a large number of items in very little space.
    It requires only a single pass through the data, which is useful for when not all elements can be held in memory at one time.


    The paper is available [here](http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf) for a complete description,
    and [here](http://blog.demofox.org/2015/03/09/hyperloglog-estimate-unique-value-counts-like-the-pros/). is a blog post
    describing the algorithm.

    There is also a [Haskell implementation](https://hackage.haskell.org/package/hyperloglog).

  * Jump Flooding Algorithm- This is an algorithm for creating a discrete voronoi diagram on the GPU in log(n) time where n is the larger of the
    width and height of the grid. This also works just as well in 3D, its just easier to talk about a grid then a 3D space.

    The main idea is to propogate information about the nearest neighbor of a cell around the grid by having each cell look not at its
    immediate neighbors, but at the cells n/2 cells away, then n/4, then n/8, etc. This halving is what gives this algorithm its log time complexity.


    The original [paper](http://www.comp.nus.edu.sg/~tants/jfa/i3d06.pdf) is good, as well as some useful [variations](http://www.comp.nus.edu.sg/~tants/jfa/JFA-Variants.pdf].

    I have also used it to produce a signed distance transform of an image in Unity, based on this [blog post](http://blog.demofox.org/2016/02/29/fast-voronoi-diagrams-and-distance-dield-textures-on-the-gpu-with-the-jump-flooding-algorithm/).


  * Hash Array Mapped Tree- This data structure provides some really nice asymptotics for a sequence data structure. The complexity of some operations is 
    constant because the tree has a maximum depth, so it can only require so many operations to walk down in the worst case.
    A [paper](https://infoscience.epfl.ch/record/64398/files/idealhashtrees.pdf)


    There are other interesting sequence structures like Finger Trees and Relaxed Radix Balanced Trees.

  * Discrimination- Sorting in linear time, as well as other operations involving grouping objects.
    The idea here is that you can perform these operations, sorting in particular, on generic data structures. I haven't looked into much more
    then the talk (by Edward Kmett), but he talks about applying radix sort and American flag sort to generic data, as well as a whole
    diversion into a vocabulary of contravariant functors and other fun things.


    The page of the [author](http://www.diku.dk/hjemmesider/ansatte/henglein/), the [Haskell implementation](https://hackage.haskell.org/package/discrimination),
    and a [talk](https://www.youtube.com/watch?v=cB8DapKQz-I) about the Haskell implementation.

* Genetic Algorithms- I should mention these, since I have been interested in them since Grad school. I won't go into detail here- they are
  discussed in thousands of places. I just want to mention some of the interesting variations like Gene Expression Programming, Genetic Programming,
  Population Based Incremental Learning, Grammatical Evolution, and Developmental Evolution. Every part of Genetic Algorithms has been investigated,
  so there are a huge number of variations in operators, population structure, individual structure, etc.


* Learning Classifier Systems- These are a very cool variation of Genetic Algorithms. They describe a system that takes input (say, from
  a sensor), and determines an output by matching a series of templates against the input. The templates that match include an action to take,
  as well as extra data depending on the variation of this algorithm such as the expected payoff of the action.


    These systems are interesting because the templates are created by a Genetic Algorithm which is evolving an entire population that collectively
    determines the system's behavior. The contents of the matching templates, as well as the actions and some of the extra data, are the subject
    of evolution.


    The fun thing about this algorithm, which is really a whole family of algorithms), is that it takes Genetic Algorithms from an optimization
    algorithm to something that reacts to an environment. I find this a fascinating transformation.

* Condensed Probability Tables- This is a case where a technique that was not feasible when it was invented (due to memory constraints) is now
  easily useable and very fast. It essentially precomputes a table used to sample from a certain discrete probability distribution.
  You just give a series of elements and a weigh or probability, and you can get a constant time sampling from that distribution.

  For an example, here is a [Haskell implementation](https://hackage.haskell.org/package/mwc-random-0.13.4.0/docs/System-Random-MWC-CondensedTable.html).




