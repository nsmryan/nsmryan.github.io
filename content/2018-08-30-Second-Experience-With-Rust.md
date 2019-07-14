+++
title = "Second Experience with Rust"
[taxonomies]
categories = ["Rust"]
+++
After my first pleasant but failed attempt to use Rust, I decided to try to
contribute a crate to the ecosystem. There are a lot of crates out there,
depsite the relative youth of the language, so I wanted to find something
that was not done and that I knew I could do. It had to be small- I don't have 
a lot of time for working on things, and I wanted to be able to see it through
from start to finish. I wanted to see this crate have documentation, tests, and
an example like a good crate should.


People sometimes suggest definitions and a parser for a file format or network packet
that hasn't been done before as a small project, so I decided to try to go through
route with CCSDS.  This is a progress report on a half finished library that provides
the primary header defined in the [CCSDS Space Packet Protocol document](https://public.ccsds.org/Pubs/133x0b1c2.pdf).


# CCSDS 
The CCSDS Space Packet Protocol defines a very simple header called the primary
header, as well as a flag indicating whether another header follows.


This protocol is used in a lot of space systems, including the International Space
Station and many satellites. The header is really very simple, containing only:


* A version number, currently always 0
* A flag indicating whether a second header follows. In my experience there is always
a secondary header, which usually provides a timestamp.
* A flag indicating whether the packet is a command or a data (telemetry) packet. This is
an important distinction in space systems, which have an asymmetric communication path
and treat commands very differently from telemetry.
* A number called an Application Identifier (APID, usually pronouced App-Id, or A-pid). This
is a project-specific number that identifies the packet, and in some projects identifies
the source, destination, and the packet type all in one number.
* An enum identifying the interpretation of the sequence count. This can be used to split
large packets into several smaller ones. Usually packets are "unsegmented" and the sequence
count is just a counter, but it can be used to indicate a kind of block number is a series
of packets.
* A sequence count (14-bits) whose intepretation is based on the sequence flag field above.
* A packet length, giving the number of bytes after the primary header, not including the first
byte of data. This is a slightly strange choice- the length is not the length of the data section-
its the length of the data section minus 1. This is because CCSDS packets cannot have an
empty data section, so they must have at least 1 byte. The packet length is defined as the number
of bytes beyond the minimum required data section size. This often leads to increments and
decrements in code dealing with packet length to add in and take out this extra byte.


# The Crate, Take One
My first attempt to write this crate went well- I found the parsing library
[nom](https://docs.rs/nom/4.0.0/nom/) and assumed this was what I needed. In hindsight,
it was like using Haskell's [Parsec](http://hackage.haskell.org/package/parsec)
instead of [Binary](http://hackage.haskell.org/package/binary)
or [Cereal](http://hackage.haskell.org/package/cereal).


I wrote a simple primary header struct, with enums for the sequence flags, the secondary
header flag, and the command/data flag. This is essentially what I would have done in C,
except for the automatic deriving of a debug format, equality, and partial equality. I also
derived Copy and Clone because I think I'm supposed to, but I'm not sure- in C you would not
have to think about these things. In the Haskell approach you want to
derive a bunch of typeclasses to tie your data into the ecosystem and language a bit,
but I'm not sure what the right Traits to tie into are for Rust.


I wrote a Nom parser that could read off the primary header and put it into this struct.
I was able to get the Nom version working after some experimenting and looking at other crates.
I was used to the Haskell style where parser combinators are a data structure and we just
combine them with combinators and a Monad instance. The macro style felt unfamiliar and made
we worried that I didn't understand what the code was doing since it defines a language
within Rust for defining these parsers, but I found it easy enough to use and for my
needs it was a simple task to get working.


Then I realized that I wanted to both read and write packets, and Nom was only for parsing.


Oh well, time for take two.


# The Crate, Take Two
I looked around for how people do serializtion and deserialization in Rust. There are usually
two types of libraries for this task- ones that use a format like CBOR or a language-specific
format like EDN for Clojure where you want to serialize and deserialize data in your language,
and libraries that provide ways to lay out memory explicitly where you are going to 
transfer it over the network or interact with hardware. I'm usually in the second camp, where
the format I want isn't one of the popular formats, and I have to lay out data explicitly in
memory. I've used Haskell's binary for this, and of course done it in C many many times without
a library.


Looking for this kind of thing in Rust, I started to look at [serde](https://serde.rs/).
However, it seems to only support these serialization formats, and not the explicit memory
use style. There are a number of different formats supported, and I like the idea that you
can break the language down into a small(ish) number of cases (like Haskell's GHC Generics or
Generics SOP). The Rust equivalent seems to have a good number of cases (29 or something), but
still, I like that it is possible.


Ultimately I was able to search around crates.io until I found the
[bytes](https://carllerche.github.io/bytes/bytes/index.html) crate. This seems to be what
networking libraries are using in Rust, and the documentation is great. I'm used to the idea
of looking around at the data structures and what traits they implement from Haskell and its
typeclasses, so I was eventually able to piece together the story of how I would use bytes
to do CCSDS packets.


I wrote up this implementation and had the following experience:


* Implementing the traits for quickcheck was easy enough, and I could test roundtripping
serialization/deserialization. This found a couple bit shifting bugs in my implementation! Nice.
* The Rust idiom of writing a From trait and getting a To trait works pretty well. In C, I would
have just cast enums and integers with no extra code, but I don't mind writing more code
for more safety. In Haskell, I believe I would have been able to derive the Enum typeclass
and avoided some of this work, but its not too much trouble.
* Testing is very easy in Rust. I don't know why I find it easier then Haskell exactly,
except that the integration with cargo just seems simplier then "stack test".
* The bit shifting/masking code seems very similar to C. I know there is a bitfield and a 
bitflag crate, but at the time I wanted to try out just doing this stuff by hard as I would
in C.


Overall, I was happy with the implementation. I don't plan on publishing it though, as I realize
that I was forcing the user to deserialize their headers into a data structure with no
way to act on the raw bits as you would in C. I feel like in a large system I would want to
be able to pass packets around and not always have them in a deserialized form depending
on the use-case.


Oh well, time for take three.

# The Crate, Take Three
Providing bit-level access to the header seems like it will require either a getter/setter
pair for each field ("packet_type" and "get_packet_type"), or the use of the bitfields
crate. I have not yet completed this iteration, but I am going to work on providing
both the deserialized form of a primary header as a struct, and a bitfields version which
deals with the header on the bit level.


# Conclusion
As part of my desire to contribute to the Rust community, I'm trying to write up my experience


Haskell in this regard because of Haskell [language-c][http://hackage.haskell.org/package/language-c]
library, which provides a nice way to parse C. I know you can use the Rust clang, but
I'm worried that with something as complex as a C AST I will get overwhelmed with
complexity if I don't use Haskell.

