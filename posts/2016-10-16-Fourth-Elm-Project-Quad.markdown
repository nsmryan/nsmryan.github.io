---
title: Fourth Elm Project- Quad
author: Noah Ryan
---

Yet another little Elm experiment!

This time I wanted to visualize quad trees. By far the hardest part of this whole experience
was figuring out how to draw them. The mouse positions are received with the positive y direction
going downwards from the top of the screen, the Graphics.Collage routines expect x and y
to be centered in the middle of the screen (with y positive going up), and I structured the
trees to expect the origin to be the bottom left (y positive going up)!

You can play with it  [here](http://itscomputersciencetime.com/elm/quad.html)

The code is on my github repository in the Elm directory as
[quad.elm](https://github.com/nsmryan/itscomputersciencetime.com/blob/master/elm/quad.elm)

