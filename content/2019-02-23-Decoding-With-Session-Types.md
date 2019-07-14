+++
title = "Decoding with Session Types"
[taxonomies]
categories = ["Embedded"]
+++
This post is a thought I had a while back about data decoding, but which I will likely not pursue. I just wanted to 
record it somewhere in the open. I'm no expert in type theory, so the concept of session types might be 1) wrong, 
or 2) trivial, but might none-the-less be interesting.


The idea is around decoding data, especially binary formats. I deal with a lot of different binary formats of varying
complexity, and they generally fall within a certain set of features:

* Structures containing a series of named fields
* Subcom data (sum types) whose intrepretation is indicated by some other field within the packet
* Primitive types- signed and unsigned integers, single and double precision floating point numbers, sometimes
  buffers or fixed or variable length, and sometimes buffers terminated by a particular symbol like a NULL terminated
  string. Some systems will use bit fields, and some will have exotic encodings like 48 bit floats.
* Data integrity checks like a CRC or checksum. These must be computed from the data, and may require custom code (its
  hard to cover all possible cases).
* Overlayed data, where the same data have multiple intepretations.
* Calculated data, sometimes called a derived parameter, which must be computed from one or more parameters and is not
  an explicit field of the binary data.


I attempted to come up with some algebraic structure for these things, where structures are a kind of multiplication (sequecing),
subcomming and overlayed data are kinds of sums, primitives are the primitives of the algebra. Fixed size buffers are multiples
of a primitive, while variable length buffers are perhaps a certain kind of infinite sum or something.


What this lead me to was this view of decoding data as an interaction between the decoding program and the binary data.
The idea is that decoding a primitive is like requesting a value of a particular type. Then decoding a structure
is like requesting several types of data in turn, and decoding an overlay of data is like requesting two types at once.


The more interesting case is subcommed types. In this case, the decoder provides several possible response to the binary
data, which can respond with the one that corresponds to the current packet. In other words, instead of telling the packet
what data we want next, we ask it which type of data it wants to provide. This seems very much like the connectors
of a system of session types.


Calculated data can simply be done on the decoder's side- I don't think it needs to be part of the decoding process.


Thats all there is to this idea- its just a recognition of a similarity between how session types can request a value,
or provide a choice, to someone, and how that matches with decoding binary data where we sometimes know what we want next
and sometimes we depend on the data to tell use what happens next.

