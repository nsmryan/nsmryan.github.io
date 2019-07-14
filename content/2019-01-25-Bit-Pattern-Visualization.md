+++
title = "Bit Pattern Visualization "
[taxonomies]
categories = ["Art"]
+++
I did a simple little project recently that creates a gif visualizing the bit patterns within a file.

The [program](https://github.com/nsmryan/Bit-Patterns) takes as input a file name, and outputs a gif consisting
of colored cells whose brightness is based on how frequently the corresponding bit pattern occurrs. The bit pattern for
a cell is just that the top left cell is all 0s, the next is 01, then 10, 11, 100, etc.

The gif moves from showing 2-bit patterns, then 4, then 6, 8, 10, 12, 14, 16. Of course, powers of 2 are the most interesting
because the data is laid out that way.


One interesting thing is that the brightness is actually the log of the frequency- small numbers, especially 0, occur so
often that just using the occurances directly leads to a white pixel for 0, and dark pixels for the rest of the image.


Anyway, I just wanted to do a simple visual of bit data. Also, now I know how to create gifs with Rust, which is cool.


There are some examples in the repo from [text data](https://github.com/nsmryan/Bit-Patterns/blob/master/results/main.rs.gif),
which bunches up in the visual ascii range, and an [exe](https://github.com/nsmryan/Bit-Patterns/blob/master/results/git_pattern.gif)
which is more uniform. I also found that data files, like recorded CCSDS packets, produce nicer images then a corpus of english text, for example.
