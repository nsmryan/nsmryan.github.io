+++
title = "More Fun Algorithms"
[taxonomies]
categories = ["Algorithms"]
+++

This post is another gruop of fun algorithms (and data structures). These particular techniques are fun because they
are a core concept that can be applied to many different situations by simply changing some structure that the algorithm
is parameterized by. I won't go into much detail here, but rather provide links to articles with more depth.


Guass-Jordan-Floyd-Warshall-McNaughton-Yamada
===
The first one is the [Guass-Jordan-Floyd-Warshall-McNaughton-Yamada](http://r7.ca/blog/20110808T035622Z.html) algorithm. This algorithm
solves a variety of problems, including finding shortest (max capcacity, most reliable, etc) pathes in a graph, finding an automata for a
regular expression, and solving linear equations. I like the linked article because it takes some bits of abstract algebra and frames these problems
in a general way, and then shows how you can see each problem as a special case of a single concept (asteration of a matrix). It also shows
how these positive ring structures appear to be common in computer science. They also appear in systems of algebraic data structures, so 
naturally I wonder if these algorithm can be used to solve any problems in that realm.


Finger Trees
===
The next algorithm is the [fingertree](http://www.staff.city.ac.uk/~ross/papers/FingerTree.html), which is parameterized by a monoid.
One introduction can be found [here](https://apfelmus.nfshost.com/articles/monoid-fingertree.html).
This data structure has good [asymptotics for a range of operations](https://abhiroop.github.io/Finger-Trees/), and can be used for a wide range of applications.
The implementation and uses are also described [here](http://andrew.gibiansky.com/blog/haskell/finger-trees/). The thing I have used this structure for is simply as a
sequence structure that supports log(n) update to an index, and log(n) splitting and concatenation, but there is more to it then just that.


The core ability that this structure gives you is that it takes a computation that you would like to do over a data set, and performs your calculation incrementally.
This can be the calculation of indices, as when you use it as a sequence, but can also be for [statistics](http://blog.sigfpe.com/2010/11/statistical-fingertrees.html)
on data that is updated over time, without recalculating over the whole data set. It can be used to get constant time access and log time update to properties of your
tree, like its size, depth, the value of a predicate over its leaves, the greatest or least element (as in a priority queue), 
[incremental regular expression matching](http://blog.sigfpe.com/2009/01/fast-incremental-regular-expression.html)


A couple other notes- there is a Haskell implementation [here](https://hackage.haskell.org/package/fingertree) for the general structure, and the specific use as a
random-access sequence [here](https://hackage.haskell.org/package/fingertree-0.1.3.1/docs/Data-FingerTree.html). There is also a Haskell package implementing a
tree that accumulates both upwards (from the leaves) and downwards (from the root) found [here](https://hackage.haskell.org/package/dual-tree).



Lenses
===
The concept of a lens is a fascinating exploration into structure and computation, but there are plenty of resources on lenses, and I won't be able to do it justice
here. The implementation [here](https://hackage.haskell.org/package/lens) is the main one to look at, although there 
[are](https://hackage.haskell.org/package/lens-simple) 
[a](https://hackage.haskell.org/package/data-lens-light)
[number](https://hackage.haskell.org/package/lenz)
[of](https://hackage.haskell.org/package/microlens)
[others](https://hackage.haskell.org/package/mezzolens), usually much simplier then the lens package. There are also implementations in other languages of course,
I'm just more familiar with Haskell. One particularly good introduction starts [here](https://artyom.me/lens-over-tea-1).


To tie this into the common thread in this post, the properties of a lens depends on the choice of constraints on the type- in the type 
`Lens s t a b = forall f. (Functor f) => (a -> f b) -> s -> f t` the type constructor "f" must be a functor, and this gives you a lens. If you constrain this type
with Applicative, you get a traversal, and so on.


You can even take this further and go up to the Optic type of this library, `Optic p f s t a b = p a (f b) -> p s (f t)`, and look at what structure you get with
a different profunctor. This can give you back lens when p is the function arrow, or Prisms with it is constrained by Choice, for example.
This can lead you to different universes of lens- I once used this to create lens that could pass data between each other, although I admit I abandended that approach as too complex.
This might be easier with profunctor lenses, I'm not sure.


I find this interesting because it seems like all of these universes of structures have their place, you just have to discover them.


Monads From Types
===
This deserves its own post, but this is another situation where you can get a lot of different systems out of a single concept. In this case, you can take many simple types,
and determine how they can form a monad, and it gets you a variety of forms of computation. For example, sum types give you the Either monad for computations that can fail,
the product type gives you the writer monad (requiring a monoid for one of the types), and the function arrow gives you the Reader monad. Any type (of kind * ) also gives you
the Identity Monad, trivially. One thing that is really cool here is to explore the duality between types, and then the duality between the forms of computation that they 
give rise to (sum vs product, monad vs comonad) creating a web of different concepts that also deserves its own post. Look at the Env comonad vs the Writer monad, the
traced comonad vs the Reader monad. For some reason there doesn't appear to be a comonad for sum types. It seems like you need a constraint on the type argument in order
to implement extract, perhaps excluding them from normal use.


I like this because it shows one way in which data and computation are related- the building block of data structures each give a form of computation. This is common in Haskell
programming, where complex structures and algorithms come out of simple data types, set up just right. This reveals interesting subtlies in these definitions, where small variations
can have consequences in use, performance, or generality. One such example is shown [here](https://www.schoolofhaskell.com/user/edwardk/moore/for-less).


Interestingly, combinations of these can give you different forms of computation that are not the same as composing the resulting monads. Products and arrow gives you the state
monad, or the Store comonad, depending on the order you compose them. See [here](http://comonad.com/reader/2018/the-state-comonad/) for more variations on this concept. This also
shows how sometimes contraints are necessary to get the correct structure, as in the Monoid constraint in the Writer monad, or the .

Conclusion
===
I think that is enough for now. These algorithms/structures show how sometimes a choice of type or algebraic structure can either formulate a problem in a generic way, or
can give rise to a landscape of interesting objects, each with its own personality. I always enjoy seeing these different landscapes- there is something enjoyable about
learning that there are whole alternate universes of thought based on a different fundemental choice, each with different uses that bend ones mind to new worlds.
