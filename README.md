The Cog VM source tree
---------------------
This is the README for the Cog Git source tree:
	https://github.com/OpenSmalltalk/opensmalltalk-vm

[![Download stable](https://img.shields.io/badge/download-stable-green.svg)](https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/latest)
[![Download bleedingEdge](https://img.shields.io/badge/download-bleeding%20edge-blue.svg)](https://bintray.com/opensmalltalk/vm/cog/_latestVersion#files)
[![Unix Build Status](https://travis-ci.org/OpenSmalltalk/opensmalltalk-vm.svg?branch=Cog)](https://travis-ci.org/OpenSmalltalk/opensmalltalk-vm)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/ecrpcrqt844n8lkm/branch/Cog?svg=true)](https://ci.appveyor.com/project/OpenSmalltalk/vm/branch/Cog)

Builds are tested automatically on each commit on Travis and Appveyor, for
Windows 32, Mac OS X 32 and 64, and on Linux 32, 64, and ARM. Squeak, Pharo, and
Newspeak VMs are built with and without JIT, with and without Spur, and with and
without Sista, as available per platform. All build artifacts are uploaded to
Bintray.

### Important notice for Developers:
We rely on source file substitutions in the src tree, specifically,
any sq*SCCSVersion.h files anywhere in the tree are processed to replace
`$Rev$`, `$Date$`, and `$URL$` with the current revision (defined as the
timestamp %Y%m%d%H%M of the latest commit), the human readable date of that
commit, and the url of the origin repository these sources were cloned from.

The first time you clone this repository, you *must* therefore run this command:
```bash
./scripts/updateSCCSVersions
```
This will install filters, post-commit, and post-merge hooks to update the
sq*SCCSVersion.h files anytime you commit or merge.

For easier use, we include the scripts/gitci and scripts/gitciplugins scripts to
commit changes to this branch and changes to the Cross and win32 plugins (which
are shared with the old Squeak interpreter trunk). If you decide not to use
these scripts for checking in sources, you should also run the
`updateSCCSVersions` script anytime you decide to use `git-reset` or
`git-checkout` to make sure the stamps are updated correctly. Failing to do so
will result in incorrect version stamps in your compiled VMs.


### Contents:
 - Overview
 - VM source directories
 - Platform build directories
 - Other directories


Overview
--------
Cog is an evolution of the Squeak Back-to-the-future Smalltalk virtual machine
that provides a number of different Smalltalk virtual machines.  The VMs are
developed in Smalltalk, using all the dynamic and reflective facilities of the
Squeak/Pharo Smalltalk system.  As such, developing in Cog is a delight.  The
Smalltalk framework comprising the various Cog VMs is translated into C by its
Slang component to produce VM source that is combined with platform-specific
support sources and compiled via a C compiler to obtain a fast production VM.
This directory tree includes the output of Slang for various configurations of
"Cog VM" and the associated platform support code, plus build directories that
can be used to produce production VMs.

This directory tree also includes an instance of the Smalltalk Cog development
system, suitable for developing the VM in Smalltalk, and for generating new
VM sources.

The "Cog VM" comes in a bewildering variety of forms.  The first distinction
is between Squeak/Croquet VMs that run Squeak, Pharo, Cuis, Croquet images
and their ilk, and between Newspeak VMs that run Newspeak.

Another distinction is between Stack, Cog and Sista VMs.  Stack VMs are those
with context-to-stack mapping that optimise message sending by keeping method
activations on a stack instead of in contexts.  These are pure interpreters but
are significantly faster than the standard context-based Interpreter VM.  Cog
VMs add a JIT to the mix, compiling methods used more than once to machine code
on the fly.  Sista VMs, as yet unrealised and in development, add support for
adaptive optimization that does speculative inlining at the bytecode-to-bytecode
level.  These are under development and targeted for release in 2015.

Another distinction is between "v3" VMs and Spur VMs.  "v3" is the original
object representation for Squeak as described in the back-to-the-future paper.
Spur, as described on the www.mirandabanda.org blog, is a faster object
representation which uses generation scavenging, lazy forwarding for fast
become, a single object header format common to 32 and 64 bit versions, and a
segmented heap that can grow and shrink, releasing memory back to the host OS.
Newspeak, Squeak 5.0 and Pharo 5 use Spur.

Another distinction is between normal single-threaded VMs that schedule "green"
Smalltalk light-weight processes above a single-threaded VM, and multi-threaded
VMs that share the VM between any number of native threads such that only one
native thread owns the VM at any one time, switching between threads on FFI
calls and callbacks or on Smalltalk process switches when Smalltalk processes
are owned by threads.  This architecture offers non-blocking FFI calls and
interoperability with multiple native threads, but does /not/ provide true
concurrency.  This multi-threaded support is as yet experimental.


VM source directories
---------------------
The Slang output of the various VMs are kept in "vm source" directories.  These
C sources define the core VM (the Smalltalk execution engine and the memory
manager), and a substantial set of "plugins" that provide interfaces to various
external facilities via Smalltalk primitive methods.  Each vm source directory
is specific to a particular VM, be it Squeak Cog Spur, or Newspeak Stack, etc.
The plugins can be shared between VMs, choosing the set of plugins to include
in a VM at build time.

The VM source are in directories such as
```
	nscogsrc/vm			- Newspeak Cog V3
	nsspursrc/vm		- Newspeak Cog Spur
	nsspurstacksrc/vm	- Newspeak Stack Spur
	nsstacksrc/vm		- Newspeak Stack V3
	sistasrc/vm			- Smalltalk Sista V3
	spursistasrc/vm		- Smalltalk Sista Spur
	spursrc/vm			- Smalltalk Cog Spur
	spur64src/vm		- Smalltalk Cog Spur 64-bit
	spurstacksrc/vm		- Smalltalk Stack Spur
	spurstack64src/vm	- Smalltalk Stack Spur 64-bit
	src/vm				- Smalltalk Cog V3
	stacksrc/vm			- Smalltalk Stack V3
```

All plugins are in the directory
```
	src/plugins
```

These contain many, but not all, of the plugins available for the VM.  Others
can be found in Cog, or in various Monticello packages in various repositories.

Each vm source directory contains several files, a subset of the following:
```
	cogit.c				- the JIT; a Cogit cooperates with a CoInterpreter.
                          This simply includes a processor-specific JIT file
	cogitIA32.c et al   - relevant processor-specific JIT, selected by cogit.c
	cogit.h				- the Cogit's API, as used by the CoInterpreter
	cogmethod.h			- the structure of a CogMethod, the output of the Cogit
	cointerp.c			- the CoInterpreter's source file
	cointerp.h			- the API of the CoInterpreter, as used by the Cogit
	cointerpmt.c		- the multi-threaded CoInterpreterMT's source file
	cointerpmt.h		- the API of the CoInterpreterMT, as used by the Cogit
	gcc3x-cointerp.c	- cointerp.c massaged to interpret faster if using gcc
	gcc3x-cointerpmt.c	- ditto for cointerpmt.c
	gcc3x-interp.c		- ditto for interp.c
	interp.c			- the StackInterpreter's source file
	interp.h			- defines for the VM configuration, word size, etc
	vmCallback.h		- the structure of the VM's VMCallbackContext
```

Platform build directories
--------------------------
The current "official" build directories are of the form
build.OS_WordSize_Processor, and include
```
	build.linux32x86	- uses autoconf, gcc and make
	build.macos32x86	- 32-bit Mac OS X using clang and gmake
	build.macos64x64	- 64-bit Mac OS X using clang and gmake
	build.win32x86		- uses cygwin, gcc and gmake
```
More can be added as required.  In each there is a HowToBuild that describes
the necessary steps to compile a VM.

Within each build.OS_WordSize_Processor directory are a set of build directories
for specific configurations of Cog, and for support code and makefiles.  For
example, there exist
```
	build.macos32x86/squeak.cog.spur   - A Cog JIT VM with Squeak branding,
                                         using the Spur memory manager.
	build.macos32x86/squeak.stack.spur - A Stack interpreter VM with Squeak
                                         branding, and the Spur memory manager.
	build.macos32x86/squeak.cog.v3     - A Cog JIT VM with Squeak branding,
                                         using the old Squeak memory manager.
	build.macos32x86/pharo.cog.spur    - A Cog JIT VM with Pharo branding and
                                         plugins (not yet implemented) using the
                                         Spur memory manager.
```
    etc.

There exist
```
    build.macos32x86/bochsx86 - Support libraries for the BochsIA32Plugin which
                                is used to develop Cog itself.
    build.macos32x86/bochsx64 - Support libraries for the BochsX64Plugin which
                                is used to develop Cog itself.
    build.macos32x86/gdbarm32 - Support libraries for the GdbARMPlugin which
                                is used to develop Cog itself.
```
and the intention is to add such directories to contain e.g. support code for
the Pharo Cairo and Freetype plugins, and anything else needed.  By placing
support directories in each build directory they can be shared between various
branded VM builds, avoiding duplication.

There exist
```
	build.macos32x86/common - Gnu Makefiles for building the various branded VMs
	build.macos64x64/common - Gnu Makefiles for building the various branded VMs
	build.win32x86/common   - Gnu Makefiles for building the various branded VMs
```
And the intention is to add build.linuxNN????/common as soon as possible to
use Gnu Makefiles to build all VMs on all platfrms.

The scripts directory contains various scripts for validating and checking-in
generated sources, packaging builds into installable artifacts (tar, msi, zip),
and so on.  The linux builds and the packaging scripts produce outputs in the
products directory tree.  The packaging scripts may choose to include Smalltalk
source files included in the sources directory.


Other directories
-----------------
The platforms directory contains the associated platform-specific files that
combine with the Slang-generated source to produce complete VMs.  The structure
is
```
	platforms/Cross/vm
	platforms/Cross/plugins
	platforms/iOS/vm
	platforms/iOS/plugins
	platforms/Mac OS/vm
	platforms/Mac OS/plugins
	platforms/unix/vm*
	platforms/unix/plugins
	platforms/win32/vm
	platforms/win32/plugins
```
Each vm directory contains support for the core VM.  Each plugin directory
contains run-time and build-time support for various plugins.  The following
directories are subtrees that are shared with the old Squeak interpreter source:

 - platforms/Cross/plugins
   - https://github.com/OpenSmalltalk/vm/tree/platform/Cross/plugins
 - platforms/win32/plugins
   - https://github.com/OpenSmalltalk/vm/tree/platform/win32/plugins

Being subtrees, their history is actually merged into the branch, but can be
pushed separately as well. If you're not familiar with subtrees or git, the
easiest is to use the scripts/gitciplugins script to check in any changes to
the subtrees and push them to their respective branches.

The processors directory contains the source for various processor simulators.
The JIT is developed in Smalltalk by using one of these processor simulators
to execute the code the JIT produces.  Currently only the Bochs x86/x86-64
simulator and the gdbarm simulator are in use, for x86 and ARMv5 respectively.

Finally the image directory contains scripts that will build a "VMMaker" image,
a Squeak Smalltalk image containing all the packages that comprise the Cog
system, suitable for developing the VM and for generating (or updating) the
sources in the vm source directories. There is also a script for generating a
64-bit Spur image from a 32-bit Spur image.

Eliot Miranda
June 2016
