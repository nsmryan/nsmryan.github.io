---
title: Computation Exponents Yoneda
author: Noah Ryan
---
This post is to record some thoughts on computation, logic, and algebraic structures. 
There is nothing new here, just some thoughts.


With algebraic data types, we give a meaning to an equation, like 'axb' or '2xT^2 + 5'
in terms of data structures. The first is a pair of a element of some type 'a' and
an element of some type 'b', while the second equation is a boolean, and a function
from booleans to some type T, or it is an element of an enumaration with 5 elements.


When doing arithmatic, exponents have this strange property of moving between
sums and products- the product of two terms with the same base is the sum
of their exponents. Similarly, logs move between subtraction and division,
as the inverse of exponentiation. This has an interpretation when seen
as data structures as well- a pair of functions with the same target type
is the same as a function that takes either the source of the first function
or the source of the other. One way to see this is to consider enums 
(types wih a finite number of elements), and to enumerate the elements
of these two data structures.


The next step here is to look at a how data can be converted to functions,
and back. For example, a value of type 'a' is isomorphic to the type
of functions 'forall b. (a -> b) -> b)'. A function of this type must
be capable of taking a function from 'a' to any type 'b' and producing
a 'b'. This means it must "contain" a value of type 'a' that it will
apply to the function- it cannot use the type of 'b' to do this
because 'b' is polymorphic and we must define the function knowing
none of its properies.

Of course, given a function of this type, we can get back 'a' again
by applying the function 'forall b. b -> b' (the identity function).


The next part is the concept of a lense, where we define functions of
the type 'forall f. (a -> f b) -> (s -> f t)'.  This type is harder to
understand, but 


Prism have the opposite property. A Prism is a function of the form



