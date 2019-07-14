+++
title = "Awesome C Libraries"
[taxonomies]
categories = ["C"]
+++
This post goes over some very cool C libraries, each of which is awesome in one way or another.  They
are generally fairly small and clean, and solve an interesting problem.


I tend to find C libraries that are particularly clean, or which implement a complex concept not usually
seen in C, to be very interesting. The very best examples are well engineered or solve a problem in an
clean way that fits into the C language.


Unfortunately I've never used most of these libraries, but I think they are very cool and I would like to fit
some of them into a project some day.


# The List

  * [Theft](https://github.com/silentbicycle/theft), a library for property based testing in C. This is a good example of
  a concept that I would usually consider too advanced for C and left it more in the domain of Haskell. This library is
  certainly not as easy to use as QuickCheck, but I don't think that it can be given the limitations of C.

  * [jsmn](https://zserge.com/jsmn.html) is a library for parsing JSON. Its interface is truly simple and manages to
  avoid building an explicit tree of nodes or requiring memory allocation. This means I would be able to use it in 
  an embedded system (if I had to parse JSON for some reason?). I have been using it to parse configuration files in
  some LabWindows programs in permissive mode. I liked this library so much I wrapped it in a Rust interface as
  [jsmn-rs](https://docs.rs/jsmn-rs/0.2.0/jsmn_rs/).

  * [heatshrink](https://github.com/atomicobject/heatshrinkP) is a compression library in C. I like this one because it
  does not allocate memory and allows tuning performance and streaming. This makes it nice for embedded systems use.
  I'm not usually doing resource constrained programming, even when programming embedded systems, but if I did I would
  keep this library in mind.

  * [Cello](http://libcello.org/), a library that embeds a great deal of advanced features into C. The list
  is pretty extensive, but includes polymorphism, garbage collection, reflection, and generic data structures. This
  is all achieved with fat pointers. I think this library is more of an experiement than a method for writing 
  production C code, but it is at least interesting to look over and understand.

  * [Cedux](https://github.com/JSchaenzle/cedux) is an implementation of a React-like system in C. The idea
  is to have an application state that is not modified directly, but only through messages which contain information
  used to modify the state through a set of registered functions. Its another example of a place where we have a concept
  not usually seen in C. I don't know how it would place out in practice, but I could imagine certain situations where it
  could be useful.

  * [COS](https://github.com/CObjectSystem/COS), the C Object System. This is another library for adding features to
  C that seem out of its reach, like polymorphism and an OOP system like CLOS (from Common Lisp). This one is actually
  intended to be used for real programming, and in particular it was developed for some style of scientific computing.

  * [fann](https://github.com/libfann/fann) for neural networks in C. The library seems well engineered, and well used.
  As with many of these, I've never had reason to use it, but if I needed some neural networks in C, I would go here.

  * [flann](http://www.cs.ubc.ca/research/flann/) for nearest neighbor calculations. This just seems like a nice clean implementation
  of an algorithm with some nice features. 

  * [imgui](https://github.com/ocornut/imgui) is an immediate mode GUI library, and the only C++ library in this list. I like
  the look of this GUI, and it easy enough to set up and use in many languages. I would like to get something in Rust as a tool
  for work one day.
  An example of an imgui system in pure C is [nukclear](https://github.com/vurtun/nuklear), which also looks good. I've never tried it
  myself, however.

  * [cchan](http://repo.hu/projects/cchan/) provides a channel mechanism with unbounded queueing.

  * [TinyCThread](https://tinycthread.github.io/) provides the C11 threading API. Its an idiomatic C API and adds mutexes, condition
  variables, and threads, along with thread specific storage.

  * [mqtt](http://mqtt.org/) and the implementation [mosquitto](https://mosquitto.org/). This is a pub/sub messaging system with a broker.
  I was able to set it up pretty easily and get messages from Python into a C program in a couple hours. I like the simplicity and
  the flexibility of the topic system. I would consider using it if I needed distributed messaging between languages or programs, especially
  if the source of the data was an embedded system.

  * [Unity](http://www.throwtheswitch.org/unity) is a testing framework that I've been using to test code in LabWindows programs. I looked
  over some testing frameworks to see what would work for testing embedded systems, and this one seems to fit nicely- its simple enough to
  add to a program, provides the usual testing features, and has room for more advanced usage. This is one that I have used for real code and
  it has served me well.

  * [Talloc](https://ccodearchive.net/info/talloc.html) provides a tree of memory allocations where freeing memory takes care of freeing
  children in the tree. It also has a way to register destructor callbacks to call when an allocation is freed.

# Conclusion
I hope some of these are interesting to someone. I know there is overlap with [Awesome C](https://notabug.org/koz.ross/awesome-c)
and there are some other good libraries at [ccan](http://ccodearchive.net/), but these are ones I'm particularly drawn to.
