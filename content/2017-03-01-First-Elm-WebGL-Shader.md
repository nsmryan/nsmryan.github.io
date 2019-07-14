+++
title = "First Elm WebGL Shader"
[taxonomies]
categories = ["Elm"]
+++

Next up in the Elm experiments is a little animation using WebGL (elm-community/webgl).

The result is created using a single quad (a square) with no interesting attributes, along with a fragment
shader that creates the entire effect. The fragment shader constructs a circle using a signed distance field,
where the X/Y position is moved randomly. The space inside the shape is a visualzation of a noise function.

You can see it [here](http://itscomputersciencetime.com/elm/shader-fun.html)

The code is in the elm directory of the github repository for
[this site](https://github.com/nsmryan/itscomputersciencetime.com/tree/master/elm)


