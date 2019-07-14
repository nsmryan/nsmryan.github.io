+++
title = " Rust In Space- Integrating CFS And Rust"
[taxonomies]
categories = ["Rust", "NASA", "Flight Software"]
+++

This post is about the [cfs-sys](https://github.com/nsmryan/cfs-sys) Rust crate which generates the
bindings required to write CFS Apps in Rust. This include all public include files from CFE,
OSAL, and the PSP.

The idea is that this is a step in the direction
of getting Rust into space by allowing it to interoperate with NASA's open source flight software
architecture CFS. Its not likely that this will be the first way Rust gets into space (see
the work that Kubos is doing), but the
more Rust in space the better in my opinion. If you are already using CFS, and want to integrate some
Rust into your codebase, this crate can help you make that happen.


A very brief description of CFS- CFS is a combination of projects (OSAL, CFE,
CFS) which provide a core set of functionality commonly seen in space and drone system. It was 
developed and released by NASA and is used by many projects across many NASA centers.
The functionality it provides includes
configuration tables, time management, module communication, logging, event messages, memory
pools, and much more. This is all on top of an abstraction layer to assist with portability across
operating systems (OSAL) and across different boards (PSP).
In addition, there is a way to add new modules, and a library of existing modules that can be plugged in
called Apps. The existing apps provide task scheduling, stored commands, data storage, file
transfer, limit monitoring, housekeeping, and a number of other capabilities.


# cfs-sys
The cfs-sys crate is intended to be used in a situation where you have a build of CFS that you are
using, and you want to write an App in Rust. This App will integrate with the rest of the CFS system
just like any other App- I didn't have to make any changes to the rest of CFS to get this working.


The bindings are generated using BindGen in the build.rs file. This turned out to be fairly straightforward-
I just used the environmental variables provided by CFS to point bindgen to the right files. BindGen is
amazingly easy to use, so this was not nearly as painful as I expected.

There is an [example App](https://github.com/nsmryan/cfs_app_rs),
which is in the apps/rust/ directory in that project, which builds an .so which can be loaded by
CFS. This module is loaded by adding it to the build/cpu1/cfe\_es\_startup.scr
script which is used by CFS to determine which modules to load at runtime.


Luckily the CFS build system does not build Apps directly- it just calls make files in each App's
directory. This way we can build a Rust project and just make sure that the resulting files end up in
the right place, with the rest of CFS none the wiser about how the module was built.



# Building
The cfs-sys crate it integrates into the CFS build through environment
variables defined in the setvars.sh script that you run before building CFS. The cfs\_app\_rs repo 
shows how to integrate your Rust app by adding it to the build/cpu1/Makefile just like any other app,
and then using the apps/rust/fsw/for\_build/Makefile to set up your Rust App and build it using cargo.


The bindings are generated with BindGen and appear to work as expected. I have not wrapped them in a Rustic
interface, so they are used raw with all the \*mut that this implies.



# Usage
The cfs-sys crate is on crates.io, so you can depend on it in Cargo.toml with:
```
cfs-sys="0.1"
```

Adding cfs-sys to a Rust file is as easy as:
```rust
extern crate cfs_sys;
use cfs_sys::*;
```

I haven't split out the bindings into separate modules to allow more fine grain control, opting for simplicity
for now. 


Once the bindings are imported, you proceed like any other CFS App- call CFE\_ES\_RegisterApp, call CFE\_ES\_GetAppID to
get your APID, register events with CFE\_EVS\_Register, set up messages with CFE\_SB\_InitMsg/CFE\_SB\_CreatePipe/CFE\_SB\_Subscribe.
Then just wait for CFE\_ES\_WaitForStartupSync, and loop blocking for CFE\_SB\_RcvMsg. You can check for system shutdown with CFE\_ES\_RunLoop,
and mark sections of you code with CFE\_ES\_PerfLogEnter and CFE\_ES\_PerfLogExit as normal, although I did have to wrap the perf log
functions up as they are macros in CFS and don't seem to get turned into Rust functions.


The example app shows how you can do this and get your App talking to CFS. It could use some work, but it runs
and proves that Rust is useable with CFS. It is even configured in the SCH App to receive its wakeup message every second, although
the message is build with hardcoded values rather then putting those in headers and then generating Rust bindings for them.



# Limitations
The cfs-sys bindings are only for OSAL/CFE/PSP includes- if you need to bind against a particular CFS App's headers, that would either have to be
done separately or the cfs-sys would need flags to build bindings for a particular set of Apps. I could easily see a set of crates like
cfe-hk-sys, cfe-sch-sys, etc which provide bindings to each App.


I have not wrapped the bindings in a Rustic interface (hence the -sys in the name), which makes them awkward to use. Nearly all code
must be unsafe in a Rust App right now. In addition, macros in CFS do not result in bindings in cfs-sys for some reason. I thought 
generate\_inline\_functions was supposed to do this, but I haven't been able to get it to work.


The integration of the build process for a Rust App and the rest of CFS does work, but does not include unit testing or documentation generation.
I also haven't looked at how the CFS cmake system might integrate with Rust as I do not currently use it.


The build currently forces the target for cargo to be 'i686-unknown-linux-gnu', which could be made configurable. I don't have a good
test system to work on generalizing this, but it shouldn't be hard.


I also hardcoded the choice _LINUX_OS_ required for network_includes.h in CFE. This is in the build.rs for cfe-sys.


A CFS App is expected to have a series of header files for message IDs, configuration parameters, etc. These are usually internal,
but certain tools expect them to be there, and if you have to, say, add a message to the SCH App's schedule for a particular App,
you need to include these files. A Rust App should really create these files like a C App would, and then generate bindings for
Rust. This way the App fits into the ecosystem without requiring special cases for Rust Apps. The example App does not do this,
so when it is integrated with SCH, I'm using a hardcoded number instead of including a header file.


# Future Work
From the list of limitations, it should be clear that this is a prototype and a work in progress.


While I am using CFS for software that will one day make its way to space, I may or may not be able to integrate Rust into that codebase.
This means that this project will continue to be a proof of concept unless someone can help make it more professional and better integrated
into CFS, ideally by using it in practice.


I would like to keep working on it, especially the example App since it is an important starting point for people. If I do end up
using Rust at work, I will certainly post about it, so stay tuned if this interests you. I expect the fires of production use would
forge this project into a full solution for Rust/CFS integration.


Otherwise, I hope this is interesting for someone, and Rust on!

