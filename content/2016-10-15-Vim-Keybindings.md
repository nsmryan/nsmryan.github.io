+++
title = "Vim Keybinding and Options"
[taxonomies]
categories = ["Vim"]
+++

If you are interested in improving your productivty with Vim, its worth checking out
other people's .vimrc files. There are many github repositories with personal dot files,
including my own [config files](https://github.com/nsmryan/ConfigFiles).


One that has helped me a lot is begriff's
[haskell-vim-now](https://github.com/begriffs/haskell-vim-now/blob/master/.vimrc)
and blaenk's [dot files](https://github.com/blaenk/dots). Incidentally, their blogs
[begriffs](https://begriffs.com/) and [blaenkdenum](http://www.blaenkdenum.com/about/)
are worth checking out.


I thought I would go over some of my configuration, covering both old and new features
that I find useful.

------

Comma as Leader
===============
**nnoremap ,, ,**
**let mapleader=","**

I used *\* as the leader key for several years before moving to **,**. I find that **,** is
easier to type because it is closer to the home row. This is a minor change, but making
custom key bindings behind leader easier to type makes you use them more, so its important
to find a key that works well for you.


Relative Line Numbers
=====================
**set invrelativenumber**

First of all, **set number** puts line numbers on the left side of a window. I thought this
was what I wanted, but it turns out that absolute line numbers are less useful than relative
line number: **set invrelativenumber**.

This took some getting used to, and I almost went back to absolute numbers. However, after a
while something clicked for me and I almost never use absolute line numbers anymore.
Relative line numbers are much better for navigation- vim motion commands that take line
numbers often need relative numbers. Now I can look at a line and see the number I need to
type to get there with **j** or **k**. This is also useful in line selection mode.


I did map ,er to toggle relative line numbers for when I do care about absolute line numbers,
like during a code review.
 
Highlight Search
=================
**set hlsearch**

The option **set hlsearch** highlights the current search term. This is useful for finding
occurrances of a pattern, like highlighting tabs with **/\t** or uses of a variable name that
is under the cursor with __*__. You can remove the highlighting of the last search with **:noh**,
or map it to something like **,h**.


Leave Insert Mode
=================
**inoremap jj <ESC>**

I found a nice trick for quickly leaving insert mode without typing **ctrl-esc**. I've been
using **ctrl-[** for almost as long as I've been using vim to avoid having to move up to
the esc key, but recently I've also added **jj** as an option. This key combination almost
never comes up, and it is easy to type. This cuts down on using my pinky fingers which reduces
the strain on my hands.


Saving Current File
===================
**nmap <Leader>m :w<CR>**


Typing **:w<esc>** is another key combination that can strain my hands, especially since I'm a
compulsive saver. I have conciously reduced the number of times I save, but I've also added
the key binding **,m** as a quick and easy alternate to **:w**. This works well with the previous
binding **jj** so I can type **jj,m** to leave insert mode and save my changes.


Select Last Paste
=================
**nmap <Leader>v V`]**

I find that I frequently need to edit text that I've just pasted- either to realign it or
reformat in some way. There is already **V`]** for this, but I find it easier to remember **,v**.


Buffers
=======
**set hidden**
**map <C-j> :bnext<CR>**
**map <C-k> :bprev<CR>**
**nmap <Tab> :b#<CR>**
**nmap <Leader>et :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>**

I used tabs for years before understanding the advantages of buffers. If you still use tabs,
or use neither, I highly recommend trying out buffers for a while. This has been one of the
biggest changes in my workflow- I can't stress it enough. My workflow with tabs was clunky
and didn't scale well. With buffers, once you are used to moving between them, you can have
a huge number of open files and still navigate. The speedup using buffers in vim compared to
tabs in vim or in an IDE (I use eclipse at work) is huge.

To facilitate using buffers, I recommend the **set hidden** option to allow buffers to be
open with unsaved changes. Without this, buffers would be a huge pain to use.
I also recommend addding key bindings to cycle through buffers. You will usually use **:b** and
either the buffer number (use **:ls** to get a list of buffers and their numbers) or part of the
file name to switch better buffers. However, if you have two files open, or you need to look
through all open files, its nice to have a quick cycling keybinding.

I use **ctrl-j** and **ctrl-k** for cycling, and **tab** for switching with the 
last buffer viewed. I also have a map I found online for **,et** to toggle between .h and .cpp
files since I use C++ at work. This finds the file with the same name but the opposite extension
and switches to that buffer, if it is already open.


Don't Redraw
=========
**set lazyredraw**

This option prevents redrawing the screen while vim is executing macros. I often use macros to 
reformat huge text files (often datasets) at work, and I've found that redrawing the screen 
slows these down a huge amount. I used to just minimize the vim window, but this option makes 
this easier by preventing the redraws in the first place.

If this is a problem for you, I also recommend using the **:g** command and **:s** when possible-
they are much faster even on files with millions of lines.

Don't Show "Hit Enter" Prompts
==============================
**set shortmess=a**

If you find the "Hit Enter" prompt that comes up when there are messages to confirm, then set 
this option. It will supress these prompts. You can always use **:messages** if you want to
review the messages anyway.

Hex Editor
==========
**nnoremap <C-H> :call ToggleHex()<CR>**

You can find a definition for a function ToggleHex on the [vim wiki](http://vim.wikia.com/wiki/Improved_Hex_editing)

This keybinding toggles between viewing a file as hex and viewing it as text. I've been using
this for years, and although its not the best hex editor in the world, I do like having the
power of vim when viewing and editing hex.

This binding is mostly useful if you deal with binary formats frequently- I do embedded systems
programming at work so this comes up all the time. These are better editors out these, including
some quite expensive ones, but this one command gives me most of what I want without a separate
program.

-----
Thats some of the bindings and options I use often. There are many others, some much more
sophisticated then mine. A .vimrc file accumulates features over the years, and every so often
its worth looking them over and deciding what you need to automate to write better code, what
you spend the most time doing, and what small tweaks make your editing experience better.

