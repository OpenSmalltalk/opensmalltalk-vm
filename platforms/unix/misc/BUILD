Building the Squeak/Unix VM from SourceForge
============================================

This file gives instructions for building the Squeak VM.


The overall directory layout is a standard VMMaker layout,
as follows:

    src          --  automatically generated code, including interp.c
    platforms
        unix     --  unix-specific files
        Cross    --  cross-platform files that are hand-editted
    build        -- typical location of a build directory


To create this layout, files from two locations are combined:

   1. A CVS checkout will give you the "platforms" subdirectory,
      including both Unix-specific and generic hand-editted files.

   2. Running VMMaker in Squeak will give you the "src" subdirectory.
      Some distributions will include this subdirectory already, but
      the CVS repository does not.
   


To build Squeak:

   1. Create the "build" directory (or use another name than
      "build", e.g. "build-linux")
   2. cd to the "build" directory.
   3. Run "../platforms/unix/misc/configure" using any options you
      like.
   4. Type "make".
   5. Type "make install".



The configure script (step 3) can be run with options to customize the
compilation of Squeak.  It accepts many generic autoconf options such
as --help and --prefix, and these are described in the file AUTOCONF.
It also accepts many Unix-specific options, which are described below.


Option "--enable-memory-mmap":
By default, Squeak's heap is allocated with malloc() and is of
a fixed size.  If this flag is turned on, then an alternative
allocation scheme is used where the heap can be resized as
necessary.  The alternative is not known to be safe, but it
is certainly convenient.


Option "--with-audio=choice":
This selects the audio interface to use.  Possible values
for "choice" are:

no: No audio.  Squeak will be silent.

oss: Open Sound System (http://www.opensound.com/).  This is almost
     always available on Linux machines.

nas: Network Audio System (http://www.radscan.com/nas.html).  NAS is
     the audio analog to XWindows.  It can be installed on almost all
     computers, and is superior most ways to accessing /dev/audio
     directly.

sun: SunOS's /dev/audio interface, which is also available on Solaris.

auto: Choose an interface automatically.  This is the default.
