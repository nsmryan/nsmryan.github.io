+++
title = "The Many Layers of Movement in Vim"
[taxonomies]
categories = ["Vim"]
+++
I have been teaching my twin brother Vim recently, which has lead to an insight- the
kind of insight you get when you are forced to articulate something that you only know implicitly.


The insight is that when I use Vim, I make use of as many as 4 separate "levels" of movement, each of which makes larger
jumps but is less accurate then the next level. Each level requires a separate set of commands, and mastering each set
makes programming as a whole much, much faster. I use Vim partially for speed, so this is very important for me.


This kind of movement is a very important part of text editing- a project can have thousands, tens of thousands,
perhaps millions of lines of text, and many millions of individual characters, and you need to get the cursor to
the exact character you need in order to start editing. This is greatly assisted by movements going from
very course to increasingly fine until you get where you want to go.


This is a process I have improved over the years, but certainly there are places I could improve
(especially through integration with plugins). Even so, with a couple plugins and a lot of bulit in Vim commands,
there is a lot of sublety in movement in Vim, multiple sets of commands, and optimization of the common case.


# Move Between Source Locations in 4 Easy Steps
Vim, like many well-used tools, provides a series of differerent levels of precision depending on the task at handle.
To prevent unnecessary suspense, I will just list the levels of movement as I see them:
  * Movement between files/buffers
  * Movement within a file
  * Movement within the screen
  * Movement within a line of text.


Not all levels are necessarily used- more that the levels exist and are useful in different situations. Its also worth
stating that you don't necessarily have to move to an exact character to do a particular edit- deleting a line or
series of lines, for example, can be done by moving to the right line, regardless of the particular character.


## Stage 1- The File
This stage gets you to the file you need to edit. If you are already there, skip to the next stage. 
Note that am not talking about moving between projects (which would come before moving between files)
- I don't have a good session manangement or project management solution for myself anyway.


### Buffers
For files, the main way I move to a file is using buffers. I used tabs for a good bit of time, but like many
people once I got used to buffers I never looked back. To move to a file that is in an open buffer, say a file
named "main.rs", I might type:
```
:b main<CR>
```
The '<CR>' means pressing enter, as in Vim key-bindings..


This is very fast, as long as you know what file you want, you know a part of the file name that is not ambiguous, and 
the file is open in a buffer. One can also use the 'edit' command:
```
:e main.rs
```
If the file is not open, as long as you don't mind typing the full path. I do this very rarely, as I use NerdTree for this
situation.


As with other levels, as we will see, there are commands to optimize the common case. There are commands to
go forward in the buffer list, backwards in the buffer list, and best of all to switch to the last file used. Even
these commands, optimized for the common case, are themselves optimized by providing short versions, like using
':bn' for ":bnext"- command prefixes will be expanded automatically if they are unambiguous.



Something to notice about swapping buffesr is that the choice of the tab key is very quick, which makes it a great mapping
for switch buffers. Its especially good to have this mapping take only a single character, as I often want to flip
back and forth between files (even when using splits I sometimes toggle files in some situations).


### NerdTree (File Explorer)
If a file is not in a buffer, I don't know which one I want, or if I have to look around within directories, I open NerdTree
(mapped to ',n' for me). This is fast, and I can toggle it back within another ',n'. There is not much else to say- its a great plugin for looking over your project, opening files in several ways, and probably lots of things I don't know about.


### Ctrl-P (Fuzzy Search)
The last method I use for getting to a file is a fuzzy search tool called Ctrl-P. I just type "<CTRL>P" and type some piece
of the file name I want to open, and Ctrl-P will find files that seem like what I wanted. This is especially good for very complex,
nested projects where I don't want to hunt around in 4 levels of hierarchy for a file whose name I already know all or part of.


This tool is amazing and I highly recommand it- I feel like my brief description doesn't get across how important it can be for
productivity in larger projects.


## Stage 2- The Screen
The next stage is getting the text you want to edit within the current screen. I currently have 75 lines viewable, and over 220
columns, so splits are very nice in providing different views witihin files. How fast you get to the right lines within a buffer
can depend on your knowledge of the code, and whether you have edited that section recently.

### Searching
To get a section of text within your current pane, the main thing I do is simply search. Either a '/' or a '?' can usually get
you where you need to go quickly. There are some settings having to do with searching, like highlighting search results with:
```
set hlsearch
```
or making it easy to clear the highlighting with
```
nmap <Leader>h :noh<CR>
```
I'm no expert on all the other settings- see my vimrc for my personal configuration.

### Jumps
Another common type of movement is to just move the screen a certain amount up or down within the file. Again, there are several commands-
  

  * '<CTRL>e' to move one line down (to the *e*nd of the file)
  * '<CTRL>y' to move one line up
  * '<CTRL>f' to move *f*orward a screen
  * '<CTRL>b' to move *b*ack a screen
  * 'gg' to move to the top of a file
  * 'G' to move to the bottom of a file.

You can also just use the normal movement keys 'j' or 'k' if the cursor is at the bottom or top of the screen. If you like the simple 'j' 'k'
movements, use 'H' or 'L' to get to the top and bottom quickly without having to wait or type a line number.


Note that there are again course movements as well as fine movements- Vim provides a gradient of refinements that each provide a smoother
experience in a small way, adding up to a unique editing system (can you tell that I like Vim? I do like it, for all its arcane warts, weirdness,
and weaknesses).

### Marks
Another method that I use on occasion is marks- you can mark a location within a file and return to it at any time. You mark a location
by giving a letter, allowing 26 separate marks to be made within a file (I use between 1 and 3 for the most part). You can move to
the line a mark is on with "'" (single tick) and the exact cursor position with '\`' (back-tick).


A mark labeled with the
letter 'a' is made by:
```
ma
```
You return to the cursor position marked with the letter 'a' by:
```
`a
```
Which is a backtick (tilde key) followed by the character used when making the mark. Again, using "'a" would return to the line the mark is on,
which I actually learned while writing this article, after using Vim for around 10 years.

There are several markers that set themselves in certain situations.
  * My favorite is '\`\`' which is two back-ticks, which returns to the location
before the last jump. This allows you to edit text, jump to a location you set, and then immediately jump back to where you where. This is very confusing
for anyone that is watching you. The next best mark is the '\`.' mark (back-tick and then dot) which moves to the last place that you edited text.


This is a huge help in certain macros, where you need to mark locations that you move to and return to them, perhaps changing the text and remarking
for the next iteration of the macro. It provides a way for macros to communicate locations, which would have to be a whole other post.


## Stage 3- The Line
The next stage of our journey is to the line of text we want to edit.

### Absolute and Relative Line Numbers
There is always a way to get to the exact line of text you want to see, as long as you have line numbers enabled (":set number") or relative line numbers
("set relativenumber"). If you are on line 10, and you want to go to line number 55, either type:


  * ':55<CR>' which jumps to the absolute line number 55.
  * '55G' which does the same thing- jumps to the absolute line number 55. I tend to use the command mode method, but I may retrain myself as the 'G' method
  is fewer keystrokes.


To move a relative number, like down 40 lines, simply type '40j'. This repeats the movement 'j' 40 times, and works with other movements and commands as well.


### Course Jumps
There are keys to move to certain regions of the screen:
  * 'H' moves to the *H*igh part of the screen (the top).
  * 'M' moves to the *M*iddle of the screen.
  * 'L' moves to the *L*ow part of the screen (the bottom line).

 This won't get you to the line you want, but it might be close enough for a few 'j's or 'k's to get you there. It can also narrow the distance for other
 movements like a search to make it more likely that you will get to where you want to go quickly.


### Search
As with finding text in a file, searching can be used to move to text on the screen. This is especially helpful there is something unique on that line that you 
can search for and get to quickly without having to move between search results or type a long search string.


### Simple Movement
Of course, you can always just 'j' and 'k' around if you are not up for fancy commands. I will often guess how many lines I need to move and type something like
'15k' or '15j', and see how well I did.


## Stage 4- The Character Within a Line
This stage moves the cursor within a line, and like all the previous stage has its own set of commands. In a certain sense I distinguish between moving within 
a block of characters and moving within blocks- this comes up within source code fairly often. There are commands that treat punction different that facilitate
these two types of movement.


### Ends of Line
  * '0' to move to the beginning of the line.
  * '^' to move to the first non-space character of the line.
  * '$' to move to the end of the line.

### Within a Line
The following commands move within a line. Note that many can be repeated by prefixing them with a number.


  * 'W' to move a *W*ord forward.
  * 'B' to move a word 'B'ackward.
  * 'f' to move 'f'orward to a character, such as typing 'f(' to move the cursor to the next open parenthesis.
  * 'F' to move 'F' backwards to a character, such as typing 'F(' to move the cursor to the previous open parenthesis.
  * 't' to move 't'oward a character, such as typing 't(' to move the cursor to just before the next open parenthesis.
  * 'T' to move 'T' backwards to a character, such as typing 'T(' to move the cursor to just before the previous open parenthesis.
  * 'h' to move one character to the left.
  * 'l' to move one character to the right.


There is also a plugin ['vim-sneak'](https://github.com/justinmk/vim-sneak) that I never got used to but seems like a good augmentation to Vim for this kind of movement.


# What to do When You Find The Character You Were Looking For
Okay, so we have managed, through a long complex process requiring many separate decisions, to move a cursor to a character within a file. Congradulations!
Maybe its time to take a break, or drink a cup of tea.


To be serious, it seems like the complexity might be overwhelming for someone new to Vim, but its something that can be learned slowly over time,
and Vim will be productive the whole time you are learning after the initial learning curve.


What commands we have access to to actually edit text once we are where we want to go is outside the scope of this article- maybe another day.


Thank you for reading!

