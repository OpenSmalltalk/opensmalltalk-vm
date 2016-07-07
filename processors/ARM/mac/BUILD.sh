#!/bin/bash -e
# This script first builds
#	binutils-2.25/bfd/bfd.h
#	binutils-2.25/libiberty/libiberty.a
# then builds
#	gdb-7.6/opcodes/libopcodes.a
#	gdb-7.6/sim/arm/libsim.a

./BUILDbinutils.sh
./BUILDarmsim.sh
