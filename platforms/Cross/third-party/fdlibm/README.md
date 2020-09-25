# fdlibm
fdlibm from www.netlib.org/fdlibm/

The goal of this fork is to perform minimal changes to fdlibm so that it can be compiled on modern C/C++ compiler

The main problem of legacy fdlibm is that it uses pointer aliasing for accessing the bits of floating point representation. In modern C compilers, this is undefined behavior. One possible work around is to use `-fno-strict-aliasing`compiler flag, but a better fix is to not use pointer aliasing at all.

Another minor problem is that intel 64 bit architectures are not recognized as little endian as they should. Some header must be fixed.
