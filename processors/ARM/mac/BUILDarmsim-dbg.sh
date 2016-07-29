#!/bin/bash -e
# This script builds debug versions of
#	gdb-7.6/opcodes/libopcodes.a
#	gdb-7.6/sim/arm/libsim.a

test -d gdb-7.6 || svn export ../gdb-7.6

ln -s ../../binutils-2.25/bfd/bfd.h gdb-7.6/bfd/bfd.h
ln -s ../../binutils-2.25/bfd/config.h gdb-7.6/bfd/config.h
libtool -V >gdb-7.6/bfd/libtool-soversion
(cd gdb-7.6/opcodes # i.e. processors/ARM/gdb-7.6/opcodes
./configure --target=arm-linux --build=i386-apple-darwin9 CFLAGS="-arch i386 -g -O0" LDFLAGS="-arch i386"
make

cd ../sim/common # i.e. processors/ARM/gdb-7.6/sim/common
./configure --target=arm-linux --build=i386-apple-darwin9 CFLAGS="-arch i386 -g -O0" LDFLAGS="-arch i386"
cd ../arm # i.e. processors/ARM/gdb-7.6/sim/arm
./configure --target=arm-linux --build=i386-apple-darwin9 CFLAGS="-arch i386 -g -O0" LDFLAGS="-arch i386"
make)
