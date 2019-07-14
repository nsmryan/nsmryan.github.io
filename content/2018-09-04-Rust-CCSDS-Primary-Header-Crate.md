+++
title = "Rust CCSDS Primary Header Crate"
[taxonomies]
categories = ["Rust"]
+++
I published my first crate! Its called ccsds\_primary\_header and it contains an 
implementation of the CCSDS header defined in the Space Packet Protocol document.


This header is used in a lot of space systems, including the Interational Space
Station, satellites, and many (but not all) cubesat applications. Its very simple,
but has a lot of extensions that are not standardized and depend on the application.
The ISS has a whole series of secondary headers used for different packets, and the
CCSDS standards themselves have a whole document on the format of time fields in
secondary headers.


I only implemented the very basics, with the idea that it could be extended with
extra information for specific projects. This post is about what I ended up with,
and what the experience was like.


# Finishing Up The Crate
I talked in a previous post about writes and re-writes that I ended up attempting
while writing this crate. I tried the bitfields crate, and found that I didn't
know how to enforce a bigendian format on the packets, so I ended up just
implementing functions for getters and setters for each field in the packet using
byteorder.


This interface is somewhat awkward because you have to type something like
```rust
pri_header.control.apid()
```
To get the APID of a packet- you need to drill down to the word where your data
is contained and then get the field as a function.


I decided to not implement the functions at the PrimaryHeader struct level, despite
the extra typing, because I think they make more sense where they are.


My favorite thing about the representation I ended up with is that the PrimaryHeader
struct is laid out in memory according to the standard-- there is no serialize or
deserialize step. This is more like how one would likely do this in C, and I like
this for manipulating packets without a lot of ceremony.

# Similar Crates
To my surprise, I stumbled on [this repo](https://github.com/Stefan-Korner/space_rust_library)
while publishing my crate. It seems to be another implementation of CCSDS, along with
some secondary header functions for checksums and time. It uses more abstraction,
with its own bit field macros. Interesting to see this- some one else seems to be
going down a similar route as me, although with wider goals. I was just trying to
publish a crate with a trivial definition in it, and I don't support all the
extra fields and secondary header stuff, or a way to include the CCSDS header into
another structure the way space\_rust\_library (or the pnet crate) do.


# Publishing a Crate
Rust has been very friendly for me in a lot of ways so far. There is good information
on publishing a crate, and the process is very straightforward. Having the whole
thing built into cargo, including documentation, is just great. I know other
languages do things like this, but its still worth noting especially as I'm not
sure how they compare.


Its nice to see my documentation up there in the nice format that docs.rs puts them in,
even if the documentation itself is pretty minimal.


# Conclusion
I published my first crate! My goal was to be a contributor and give something,
no matter how small, to the community. I hope someone (perhaps myself)
uses this crate one day, but even if they don't, it feels good to share it.


Now I have to figure out what I want to do next. I would love
to be able to continue using Rust- its been a lot of fun! There are 
definitely projects I would like to work on, and having the control and knowledge
of memory layout combined with a certain amount of functional programming
sounds good to me!

