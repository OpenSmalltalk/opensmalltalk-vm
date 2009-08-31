Building Unix Squeak from SVN (Subversion) Sources using CMake
==============================================================

Executive summary
-----------------

  svn co http://squeakvm.org/squeak/trunk squeak
  cd squeak
  mkdir bld
  cd bld
  ../platforms/unix/cmake/configure
  make

Detailed instructions
---------------------

1 Checkout the sources.
 
    svn co http://squeakvm.org/squeak/trunk squeak
 
  This will create a directory called 'squeak'.  Descend into it with
  'cd squeak'.

2 You can use the supplied interpreter sources in 'platforms/unix/src'
  or you can generate your own.  If you generate your own then I
  recommend you place then in a directory next to 'platofrms/unix/src'
  and call them something else, 'platforms/unix/vmm' for example.

3 Create a build directory.  This can be anywhere you want.  In this
  README we will 'mkdir bld' to create the build directory in
  'squeak', next to the 'platforms' directory.

  Building directly in the source tree (starting in platforms/unix)
  should work but is UNTESTED and UNSUPPORTED and discrouraged by
  CMake people too.

4 Descend into your build directory.  'cd bld'.

5 Configure your build: '../platforms/unix/cmake/configure'.  (You can
  pass arguments to this script; run 'cmake/configure --help' to
  see a list of them.)

6 Build it: just type 'make', sit back, and enjoy the pretty colours
  (assuming your terminal supports them).  This should leave you with
  an executable called 'squeak' in your build directory.

7 You can test the binary in-place by running 'squeak' with a path to
  an image file as argument; e.g: ./squeak ../../squeak.image

8 If it works, install it by typing 'make install' in your build
  directory.

9 If you modify the sources you can safely type 'make' in the build
  directory and everything affected will be rebuilt.  If you want to
  reconfigure and rebuild only affected files, type 'cmake .' and then
  'make'.  If you want to rebuild everything type 'make clean' and
  then 'make'.  If you want to reconfigure everything and then rebuild
  everything just delete your build directory and start again from
  step 3.

----
Last edited: 2009-08-30 23:56:00 by piumarta on ubuntu.piumarta.com
