+++
title = "My Current Toolset"
[taxonomies]
categories = ["Vim"]
+++

I've accumulated a certain set of tools over the years for various aspects of programming and for various programming tasks.
I like to look at other peoples tools and configurations, so I figured I should talk about my own.

Vim
===
As mentioned on this blog, I use vim for text editing. I have become much more proficient in the last year, using a number of plugins 
and new techinques (new to me) like using only buffers and forgoing tabs.


I use vim for several reasons- it is fast, configurable, and has a lot of useful built-in command and great plugins. It may not be the
best possible text editor in all ways, and I may move on one day (perhaps just to neovim) but it has served me well these many years.
I can edit text faster, ensure more consistent style, perform transformations on data, view and edit raw binary data, and many other 
tasks far faster then I would be able to. Its a huge win in so many ways, and I do not regret in the slightest the modest investment of 
effort required to become proficient in it.


C/C++
=====
For embedded systems work, I use C and a limit amount of C++. The C++ I have seen in these system is a tiny corner of the full language-
don't expect lambdas, templates, or even inherence to come up.


I find C a sharp scalpal to use for this kind of work- its easy to do a lot of tasks that are tedious in other languages when dealing with
hardware and externally defined data, but the techniques and means of expression are very limited for many tasks. I don't see an alternative
right now, even with some contenders that seem to be getting some use like Simulink.


I also use C for certain other tasks, like ground tools that interact directly with binary data produced by an embedded system or deal with hardware
that only has a C API. For these tasks it can be surprisingly straightfoward to use with the right environmnent (see LabWindows below).


LabWindows
=========
LabWindows is a development enviroment for C that comes with a visual GUI builder and a lot of libraries and utilities. The development environment
has a very nice debugger, which is missing a lot of the time on the systems I use. The GUI has a lot of controls and the utilities have been adaquate
for my needs in building simulators, configuration tools, ground systems, and algorithm visualizations.
I can get a GUI program set up and running in an afternoon which can easily interact with an embedded system, which is a niche that I am quite
happy to have filled.


Being pure C has advantages-
it is simple, it is compatable with a lot of hardware, and its easier to share code between an embedded system and LabWindows as long as you ensure
that your embedded systems code or headers files are pure C even in a C++ project. I'm sure it could be made more typesafe and concise, but
simplicity is nice in this niche- the cognitive overhead is not too much and I can concentrate on the task at hand for the most part.


Note that LabWindows is not free- its a tool that I learned about at work and is paid for by NASA. I don't use it outside of work and I don't think
I ever will, which is a shame to say about a tool you invest time in learning.

R
===
I have picked up R as a way to do statistics, plotting (the plot command and ggplot2), data analysis and exploration.
There are a lot of libraries, and the user experience is very good.  I've had very few problems installing libraries and getting them to work.
The documentation has been adaquate, although sometimes lacking in some key examples.  

One great thing about R is the ability to get your data processing and plotting into a script. In excel, the results of your efforts are encoded into the contents
of the spreadsheet. Even using formulas isn't enough- you lose the thread of execution that gets you from your input to your output in a maze of columns and references.
With R, the logic is in a program, the data is in an easy enough form to use (usually dataframes, although I'm sure I'm missing out by not using more advanced libraries).


One of my major complaints with R is that it can be difficult to tell what a function will do at times. It seems to be a do-as-I-mean language, where functions
will often attempt to do the right thing with the input they are given, which can make it hard to determine exactly what it is they did do. This is fine when
things work, but when they do not, you have to track down exactly which path will be taken. This comes up especially often when I have something returned
by a library function and I'm passing it to another library function- what will this function do with the type of object returned by this other function?


Excel
=====
I felt that Excel deserves a mention here. I don't particularly like using it, and I will use R when possible. Excel may not be the best, it may not be
able to operate on very much data without slowing down, it might not have all the formulas I need, or the ability (to the best of my knowledge) to
create repeated graphs or act on a series of separate data sets conviently, but it still has a use.


The main thing Excel does is allow you to explore your data quickly- even in R I have to write an expression to dsecribe what I want to see, but in Excel
I can plot, jump to cells, and quickly get a series of different views on a certain amount of data. 


One other advantage is that while R lets you encode your processing in a program, if you do too much exploration from the command line then your progress is
somewhat lost unless you take the time to put it into a script. In contrast, in Excel your actions are recorded in cells and you leave a trail as you go. As I said
above, its not the best trail to follow, but at least the data is all there, visible, and persisting the calculations I did when exploring a data set with no
extra effort on my part.

Haskell
======
Haskell is my hobby language, and every so often my language for tools that need to do parsing, complex algorithms, or small data handling tasks.
For work tasks, its great for parsing (I've used attoparsec for large, custom log files from COTS hardware), parsing custom binary data for statistics
and reporting, and streaming data (I use pipes, but I'm sure conduit would also work). I find that the types guide me to correct implementations,
find my mistakes, and teach me about my problem domain.


For hobby projects, its great for encoding ideas, teaching my about type theory, category theory, and other amazing things.


I know I can be productive in Haskell, my programs will be far more stable and robust then with my other options, and I will encode the problem
I am solving more concisely and with more clarity with the help of its type system then I would be able to in other languages.


In an engineering capacity I have to use the tool best suited for the job, so as much as I would use Haskell in every project, I often work in other languages.


My main complaint with Haskell is the occasional lack of a library which, say, Python or R might have.
I would like to say I've contributed a library when it was missing and helped the ecosystem, but to my shame I have not.


Python
=====
Python has occasionally filled a niche left by the other languages in my list. Its got a lot of packages available, including bindings to C libraries.
Its an easier sell than Haskell for a tool that other people will use. I have not used it much, but increasingly there is a gap between the high level Haskell tools
I write for small, specialized tasks, and the low level C programs which Python fills.


My biggest complaint with Python is the type system- its like I have my hands typed behind my back compared to Haskell. I can't reason locally about my code- I have
to understand the whole program and its inputs and outputs to understand what happens within a function. The reasoning is about the dynamic behavior of the program
and not its specification, and the larger the program the worse this becomes. Its the right choice for me for some programs, but I do wish it could do more to help
me with my programs.


Tmux
====
I've been using tmux recently, just to make my development environment in Cygwin (at work) and in Linux (at home) a little nicer. I don't have much else to say- its very good
and easier and the vim interoperation has been enough for my needs.



Conclusion
=========
This is not a list of all languages or programs that I use- its just my toolbox for common tasks, and the tools are what I reach for most often.



