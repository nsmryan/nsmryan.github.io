---
title: Some Thoughts on Abstraction
author: Noah Ryan
---
I've been doing some updates to a program at work which required some architectural changes. It was a good case study in program design,
and got me to thinking about the role of abstraction in programming. 


One of the main problems I had with this program is that at every turn, the design introduced an abstraction. The problem with this is that
each abstraction introduced cognitive overhead in understand what was really going on, and at the scale of the program (a few thousand lines)
the overhead of understanding each abstraction was greater than the reduction in complexity gained by making parts of the program regular enough
to fit into a single concept.


The other problem was that there was a great deal of interconnection between components through use of member variables. Many objects received
a parent object as a reference, and would walk down the graph of the program to get a reference to, say, a queue somewhere.  This meant that
it was very difficult to tell how parts of the program where intertwined, and what dependancies there where except that there were a lot.


The other problem was that the abstractions seemed to have special cases throughout the codebase. This means that the program enforced a
kind of boundary that defined how it was supposed to operate, but then had to have special cases in multiple locations to account for all
the ways in which the actual operation of the program did not match the abstraction. This is related to the disadvantages of abstraction in 
its tendancy to create rigidity in a program's structure, and speaks of the need for abstractions to be chosen carefully to describe something
true or inherent about the program.


# Abstraction
The role of abstraction here is rather interesting. On one hand a more abstract solution does not help solve a particular problem, but rather 
makes a solution apply to a greater range of problems. In this ways of thinking, the abstraction is about ignoring details- restricting the assumptions
we make and promising to make use of fewer properties.


Abstraction has a cost which will outway any potential advantage up to a certain scale of program complexity. With this in mind, abstraction
should be avoided whenever possible, preferring to instead implement straight-line code.  There are layers of abstraction, and its possible that
a program is implemented entirely in terms of an abstraction, like a more abstract programming language, in which there is not exactly semantic
overhead if the programming thinks in terms of the abstraction. There is still a loss of information about what exactly the program is doing
behind the scenes, but I'm not sure how to resolve this with the cost of mental overhead.


I think in this case the use of functions to organize code is a crucial concept. They are a means of abstraction in themselves, but at a very low
cost and without imposing the same architectural limitations as, say, an inheritence hierarchy.


On the other hand, it is possible for abstraction to improve program readability. If the abstraction introduces a vocabulary of thoughts and 
techniques which can be combined in different ways to produce a program, then this can reduce the complexity of understanding the code. 
This seems to come from the fact that in programming, we can do almost anything we want at any time, and almost everything we do is wrong.
We have much more power then needed to solve most problems, and only a few ways to indicate how much power we want to use. The way that comes to mind
is to have a file with only a few or no imports, indicating that the files contents are not tied into other complex systems but stand on their own.
Other ways exist, such as a pure function in Haskell which restricts the possible range of actions a function can take, or parametric polymorphism which
indicates exactly what features of our data we will make use of (where constraints indicate the list of features we can assume).


I often see abstractions build to match the particular form of a program, with no particular basis for why the abstraction is designed that way except
to capture or enforce a commonality throughout a program. There is nothing inherently wrong about this, but it does have some weaknesses. The first is that
if the concept that it captures is not truely inherent to the program, then the abstraction can make the program more difficult to maintain by requiring
architectural changes when the requirements of the program change such that they so longer match the concept we captured.


The second problem is when the bounds of the abstraction are not clear. I have seen many abstractions where I can't reason about when and how they apply
because they are not described in a formal way. Without some formal (mathematical) underpinning, we have very little way to understand what the limitations
our abstraction has and in what conditions it will fail, or to reason about it in any other way. The reason that a formal description is helpful in this
situation is that math is the best means we have for describing systems, and if we can explain our thought with the language of math we have tools for
exploring it, sometimes understanding it in entirely new ways.


That is not to say that formal descriptions are always helpful either. The real world is a messy place, and rigid formalisms can trap us into designs
that do not account for the complexities we encounter in real systems. Math is useful for removing complexity and getting to core concepts, but can't
accomidate all the complexity of the world.


I have this picture of formal abstraction as a set of shapes or hyperplanes which we use to cover the manifold of our program's problem domain. For
highly regular domains such as math, this works well. If the tools available don't cover your problem domain well, you might need to construct a
very complex description within the language of concepts you use, leading to greater complexity then if you used more primitive tools which allowed
finer constructions. This also brings in this image of architecture as a kind of debt or weight- if the architecture has to change then we might have
to rewrite much of our program.

It seems like some of the most successful and lasting abstractions are the ones that provide a layer on which other concepts can be built- programming
languages and operating systems fit into this class. These provide a logic which is reasoned within, and which maps to some model (an executable program)
with enough freedom to get the behaviors we want even though not all executable programs can be created with a language. Within such a system, we then
build further logics, and futher mappings, each one providing either a change in vocabulary or a more restricted environment with which to describe a
thought. This has its advantages- more restrictions allow us to say things more clearly, without as many options to get things wrong.


This clarifies for me the reason for much of the debate on programming techniques- if a particular language of concepts fits your application domain,
then it will seem like a great idea. If you spend your time thinking about programs in that domain, then it is easy to believe that all programs should
be done in the same way, and that a particular set of tools (languages, libraries) are the ultimate way of doing things. The reality is always more
complex, and different situations have different demands, and even multiple sets of demains for different parts of a single program. In high performance
computing, small gains in performance can be worth the time of programmers, while in some domains small gains in performance are not as important as
developing new features. Sometimes correctness concerns override normal software developement practices, and it is worth development effort to add
tests and simulate the operating environment, while for some programs testing through use it good enough. 


Where does this leave us? Abstraction is useful sometimes, but not other times. Formalism is useful sometimes but not other times. Plain old
code is preferrable sometimes, but sometimes hides our true meaning in formulatic code that could be better described with a different vocabulary.


This is not a complete wash. We can judge a situation based on several factors such as program size- a small program usually seems to suffer from abstractions, while a
very large our may require abstraction to be useable and maintainble. We should also consider the developement cycle- some programs are maintained and modified for
many years, some are built and stay largely the same throughout their lifetimes (flight software is generally like this, and I imagine video games are as well), while others 
must be modified constantly with new features. If a program is of a very large complexity and is being changed over time, we might put a lot of weight into anything
that reduces complexity (even if that is just lines of code) in order to manage the constantly growing complexity over time. On the other hand, a program that does not
change much over time might put very low weight into these things, especially if it is not large enough to require many abstractions- flight software does not
tolerate much abstraction partially because there are other concerns that outweight the need to manage complexity through formality.
