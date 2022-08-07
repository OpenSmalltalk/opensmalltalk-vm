# Porting to a new CPU, the RISCV RV64G Experience

This file describes the overall "nuts and bolts" of porting
the opensmalltalk-vm to RISCV 64.
We hope these notes are helpful in porting the Smalltalk Virtual Machine 
to any new CPU architecture.

Please read the README.md and CONTRIBUTING.md files for basic orientation.

As the opensmalltalk-vm build process uses
scripts and templates to generate a working VM, let's start with strategy.

The VMMaker Smalltalk tools include cross compiling Smalltalk VM code
into C files which are combined in a framework with plugins and compiled to
build a working VM which works with a keyboard, display, and mouse.

To get a working VM, one needs to
[A] know the processor ABI
(register and stack conventions, how to call C code),
[B] write the VMMaker Smalltalk classes which get translated into C,
and [C] write some C glue code for required VM primitive operations.

It is good to have some basic understanding of the directory framework
to look for Smalltalk and C code which is close to what is needed.
The basic strategy is to "copy and change" or to subclass what exists.

In this case, the ARMv8 (aarch64/arm64) RISC architecture is
fairly close in design to riscv64.
The spur stack vm (no JIT) is the simplest to start with.

## VMMaker Image

The first thing to do is create a VMMaker image.

You will want to make a directory in which to work and create a VMMaker image.
For riscv64, this directory was `opensmalltalk-vm-rv64`.
```
git clone https://github.com/OpenSmalltalk/opensmalltalk-vm opensmalltalk-vm-rv64
cd opensmalltalk-vm-rv64/image
```

The `image` directory contains a number of scripts and Smalltalk files.  In this case
```
./buildspurtrunkvmmaker64image.sh
```
Should download a Squeak trunk image and then run
	buildspurtrunkreaderimage.sh trunk6-64.image

Note that this sometimes breaks.
In my case, my desktop computer is a Raspberry Pi 4 running Linux.
Instead of `sqcogspur64linuxht/squeak`, the
downloaded VM is `sqcogspur64ARMv8linuxht/squeak`.

As the recent trunk image is proper, I just run
```
sqcogspur64ARMv8linuxht/squeak trunk6-64.image
```
then open a File List and load `Buildspurtrunkvmmaker64image.st`.
This should load the proper code and quit the image.  If a problem here,
just save the image as VMMaker.image.

### VMMaker Changes

We want to genetrate a file `src/plugins/SqueakFFIPrims/RiscV64FFIPlugin.c`.

So we need to add code to category `VMMaker-Plugins-FFI`
as a subclass of `ThreadedFFIPlugin`.

The purpose of life for this plugin is to be able to
call C plugins and library functions.
Basically, the float and integer registers are set up, values pushed on the stack,
and values transliterated between Smalltalk and C.

For RiscV64, like ARMv8, floats are generally in float registers, integers in
integer registers, small structs in integer registers, larger structs are caller
allocated and pointer to this in an integer register gets filled in.  Many details on
ABI rules for this.

A basic understanding of how bytecodes work and how
objects are represented, how values are found and
translated should get you through this.
For details see
 * http://www.mirandabanda.org/cogblog/on-line-papers-and-presentations/

Most of the value translation mechanics (e.g.
a float represented in Smalltalk vs a machine float,
getting a value from an instance variable, strings,.. ) is already
done for you.

You should not need to make changes, but the primitive access functions
are defined in `src/plugins/IA32ABI/ia32abi.c`.

The bulk of the detail work has to do with register and stack usage for passing
arguments and results.  

Looking at ThreadedARM64FFIPlugin, I saw that most code would be identical, so just
subclassed for ThreadedRiscV64FFIPlugin.  I was also fortunate to be able to subclass
ThreadedFFICalloutStateForARM64 as ThreadedFFICalloutStateForRiscV64.

If you have built the VMMaker image as above, a browse of
```Smalltalk
  ThreadedRiscV64FFIPlugin class>>calloutStateClass
```
should show `^ThreadedFFICalloutStateForRiscV64`.

The basic strategy is to set up a ThreadedFFICalloutState with register values.
See `>>ffiCalloutTo:SpecOnStack:in:`, `>>ffiCall:ArgArrayOrNil:NumArgs:` for details.

The class method `#moduleName` is `^'RiscV64FFIPlugin'`, so the generated file
is `src/plugins/SqueakFFIPrims/RiscV64FFIPlugin.c`.

Note also `ThreadedRiscV64FFIPlugin class>>identifyingPredefinedMacros`, which
is explained a bit below on configuration.

In addition, the `ThreadedFFIPlugin class>>preambleCCode` defines C macros for getting and
setting the stack pointer.

When all is set up, one can use the VMMaker tool or
a simple Workspace to generate the C files.  In a workspace:
```Smalltalk
 plugins := #(ThreadedRiscV64FFIPlugin SqueakFFIPrims FFIPlugin).
 plugins do: [:pluginName| (Smalltalk classNamed: pluginName) touch].
 (VMMaker
	makerFor: StackInterpreter
	and: nil with: #()
	to: VMMaker sourceTree, '/src'
	platformDir: VMMaker sourceTree, '/platforms'
	including: plugins) generateExternalPlugins.
```
If you hit a speed bump in generating the VMMaker image, you
might get an error complaining about missing definitions.
This can be fixed by initializing the CoInterpreter and
doing the above again.
```Smalltalk
CoInterpreter initializeWithOptions: Dictionary new. 
```

## makefiles, configure

The build script for linux, `mvm`, runs `configure` and generates
directories and make files for selected plugins.

For Unix/Linux, the `configure` script in `platforms/unix/configure/` needs
to know about your processor's compiler flags.

You can ask `gcc` what it knows about this.
```
gcc -dumpmachine
touch empty.c
gcc -dM -E empty.c |less
```
For `configure.ac` and `configure` there is a place
to specify gcc compile flags for your CPU architecture.
```
case $build_arch in
  ... ...
	riscv64) TARGET_ARCH="-march=rv64gcv -mabi=lp64d"
 	CFLAGS="-g -O2 -D__riscv64__"
 	;;

	*)
  ... ...
 ```
The selected CPU compiler flag(s) should be the same as those
returned from `ThreadedRiscV64FFIPlugin class>>identifyingPredefinedMacros`

For the stack vm on Linux, we need `building/linux64riscv/squeak.stack.spur`
with three sub directories for build, build.debug and build.assert.
Also, the spec files for which internal and external plugins are to be built.

Each of the build directories will have a build script named `mvm` which you can copy
from a similar sibling directory with zero or more minor changes.

## C Code needed

We need to mate some C code primitive support with the code generated by VMMaker.

Most of this is in ` platforms/Cross/plugins/IA32ABI/`.  Yes the name is historical.

`ia32abi.h` defines `thunkEntryType` (more on this below)
and the integer and floating point register signatures.

`xabicc.c` need to conditionally include our new file, `riscv64abicc.c`

`riscv64abicc.c` supports callouts and callbacks (see Alien, below) and
defines the basic call mechanics.  One thing to note here is `VMCallbackContext`,
which is part of the mechanics of calling C which calls Smalltalk which may call
C which may again call Smalltalk which ... (Again, note Alien section, below).

An interesting directory for Linux is `platforms/unix/vm/`.

Most SOCs these days have a hardware clock available, typically
supported by a standard ABI (Application Binary Interface).
The `*HeartBeat*.c` files support this.

The `include_ucontext.h` file specifies how to access register values
from a Unix/Linux signal context. `sqUnixMain.c` has code which uses
this to dump register information on faults.

Once all these bits are working, you should be able to run an image!

Next to get up is the FFI.

## FFI, the Foreign Function Interface

There is a file which you don't need to change, but is good to know about
`platforms/Cross/plugins/SqueakFFIPrims/sqFFITestFuncs.c`.
These functions exercise the generated YourCPUFFIPlugin.c
(src/plugins/SqueakFFIPrims/RiscV64FFIPlugin.c).

If you use Cuis Smalltalk, you can open a workspace and
```Smalltalk
Feature require: 'Tests-FFI'.
```
Then open the SUnit Test Runner and run FFIPluginTests.
If you started Cuis in a terminal, there will be some disgnostic output.
If you need more, you can add to `sqFFITestFuncs.c`.

This should let you update the VMMaker code to get the right results with value passing on calls.

### Alien

Once FFI calling works well, one would like to be able to call C and recusively call back into Smalltalk.

The base exercise requires the Alien-Core package to be loaded into a Squeak image.
For this we use the Monticello Browser on HTTP Repository `www.squeaksource.com/Alien`,
open it and select and load the latest Alien-Core-eem.<whatever>.  You may have to use the
VM downloaded for the VMMaker build on the Squeak image to get a proper SSL connection.

You should be able browse the Alien-Core category and look at class `CallBack`.
You will need to subclass this.  For RV64 we have `CallbackForRiscV64` which has
class methods to return the ABI string ('RiscV64') and test method `isForCurrentPlatform`
which checks that the image is running on your CPU.
There are a couple of simple instance side helper methods here.

The interesting bit of business to get done here is to define a machine code trampoline,
in our case, `FFICallbackThunk>>initializeRiscV64` and
updating `FFICallbackThunk class>>initializerForPlatform` to know about it.

The job of the initializer is to create an Alien bytecode array with the hand assembled machine code
which sets up the registers, calls thunkEntry(), cleans up, and returns.

The `Alien class>>exampleCqsort` gives a good example to get working.

## Sharing your work with the opensmalltalk-vm commuity.

By now, you will certainly be subscribed to the vm-dev email list for questions.

You will have a github repository which is a clone of opensmalltalk-vm.
For this code, open a new `pull request`.

For the VMMaker and Alien-Core updates, save to their inboxes in monticello:
```
http://source.squeak.org/VMMakerInbox
http://www.squeaksource.com/AlienInbox
```
and possibly
```
http://source.squeak.org/FFIinbox
```

## In Closing

Each port has a specific context and set of special challanges, but we hope that recap of
this particular port gives an introduction and hints as to the bits and bobs which need
to be taken care of to assemble a working VM.

The good news here is that this code has been ported many times, people have commented the code,
and it is quite worthwhile to be able to save an image running on one CPU and OS and open it on
another CPU architecture using a different OS and generally have the same windows appear in the same locations
pixel-for-pixel.  The very definition of portability!

Also, being a part of a community means you don't have to do everything yourself.

`http://lists.squeakfoundation.org/mailman/listinfo/vm-dev`


### Files

'*' -> changed; else new

#### VMMaker
```
 CallbackForRiscV64
 ThreadedFFICalloutStateForRiscV64
 ThreadedRiscV64FFIPlugin
* ThreadedFFIPluginClass-preambleCCode
```
#### opensmalltalk-vm
```
 platforms/unix/config/
	* configure.ac
	* configure
 platforms/unix/vm
	* include_ucontext.h
	* sqUnixMain.c
	* sqUnixITimerHeartbeat.c
	* sqUnixHeartbeat.c
	* sqUnixITimerTickerHeartbeat.c
 platforms/Cross/vm
	* sqCogStackAlignment.h
 platforms/Cross/plugins/IA32ABI/
	riscv64abicc.c
	* ia32abi.h
	* xabicc.c
 src/plugins/SqueakFFIPrims
	RiscV64FFIPlugin.c [VMMaker generated]
	* SqueakFFIPrims.c [VMMaker generated]
* build/linux64riscv/squeak.stack.spur
	plugins.ext [copy, without 'B3DAcceleratorPlugin']
	plugins.int [copy]
	build{,.debug,.assert}/mvm
```
#### Alien
```
Alien-Core
	CallbackForRiscV64
	* FFICallbackThunk class>>initializerForPlatform
	FFICallbackThunk>>initializeRiscV64st
```	
#
