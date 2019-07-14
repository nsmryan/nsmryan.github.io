+++
title = "My Vim Plugins"
[taxonomies]
categories = ["Vim"]
+++

I've been using vim/gvim for about 8 or 9 years now, but I stopped improving my
vim experience after I reached a certain level of proficiency.
Recently I've made some huge improvements to my vim workflow that has rekindled my interest
in vim and made my daily life much better.


I have nearly 30 plugins right now, but I thought I would list some of the more important
ones here. My hope is that this helps someone else improve their vim experience.

Plug
====
I tried several plugin managers, and I was using Vundle for a while. However, I found that
it didn't work well on Windows, and instead of messing around with it I started using the
very simple Plug plugin. Now I just list the plugins in want in my .vimrc, and when I need to
update to setup a new system I just run :PlugInstall and watch it download all my plugins.

Nice.


Ctrl-P
======
This plugin gives you a fuzzy file search with the default keybinding ctrl-p. This means that
you can type "ctrl-p cabal", for example, and it will list the files with that name. You can
select a file and press enter to open it in a new buffer. This is much faster for opening new
files if you know the name of the file you want to open.

If you don't know the name, or you want to explore files, there is always NERDTree.


NERDTree
========
I finally installed NerdTree, which is a much better file explorer then the build in
one in vim. I have it mapped to ,n to toggle the left pane with the file explorer.

I also have been using rooter to set the current directory, which makes using NERDTree even nicer
because it always opens in the current directory, or in the root of the current project.


Rooter
======
This one just sets the current directory to the project root. It detects certains files
(which is extendable) to determine where the root directory is. These are things like
source control configuration files, but you can add .cabal or any other file if it makes
sense for your project.


Solarized
=========
I used the colorscheme desert for a long time, but it is not perfect. Some research revealed the
colorscheme Solarized. I recommend it for most tasks.
The color of comments or plain text is a little light for me, so I also have the colorscheme
corporation installed, and I switch between them with ,ec for corporation and ,eo for solarized.
For example, I'm writing this post in corporation because on this monitor the white text is
sharp and visible, while on my work computer it is too bright and I would use solarized.

Both use very rich oranges and some nicely desaturated colors which I find very pleasing to look at.


Tabular
=======
The code I write for work (C/C++ embedded system code for space and aero at NASA) has become must
better formatted since I found tabular. I usually use it to select a couple of lines of code
and align them on "=" or ",".

It may seem like a small thing, but making good formatting easy means that I do it more often, and
its a noticable difference in the code I produce.

Tagbar
======
This is a fantastic plugin that gives you a bar displaying the symbols defined in your code.
This is something I used to miss from eclipse when using vim but no longer!

I have it mapped to ",g" so I can toggle it on and off. Screen space is too precious to keep it
up all the time, but its great to have when you want it.

Others
======
I have also installed Fugitive, sneak, easy-motion, syntastic, ack, vim-textobj-user, and some
Haskell specific plugins like ghc-mod, haskell-vim, and neco-ghc. I haven't looked into these
much, but the whole text-obj concept is worth looking into to understand vim, ack seems like
a huge help in finding things in large projects, syntastic closes the gap for me between vim
and an IDE, and sneak and easy-motion seem nice in principal even though I haven't been using them
much.



That is a selection of the plugins I have found interesting. I have also found some keybindings
and vim tricks recently that I will discuss in another post.
