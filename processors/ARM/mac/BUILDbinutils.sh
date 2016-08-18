#!/bin/bash -e
# This script builds
#	binutils-2.25/bfd/bfd.h
#	binutils-2.25/libiberty/libiberty.a

test -d binutils-2.25 || tar xzvf ../binutils-2.25.tar.gz
(cd binutils-2.25;
./configure --build=i386-apple-darwin9 CFLAGS="-arch i386 -g -O2" \
	--disable-nls --without-zlib
make configure-bfd
cd ./bfd
make
cd ..
make configure-libiberty
cd ./libiberty
make)
ls -l binutils-2.25/libiberty/libiberty.a binutils-2.25/bfd/bfd.h
test -f binutils-2.25/libiberty/libiberty.a && test -f binutils-2.25/bfd/bfd.h || echo "failed to build binutils" 1>&2
