#!/bin/bash
export LSB_FIRST=1
export TARGET_ARCH="-march=armv8-a" 
export CFLAGS=" -D__ARM_ARCH_ISA_A64 -DARM64 -D__arm__ -D__arm64__ -D__aarch64__"
export INCLUDES="-I/home/kend/OpenSmalltalk/kens-vm/src/vm -I/home/kend/OpenSmalltalk/kens-vm/platforms/Cross/vm -I/home/kend/OpenSmalltalk/kens-vm/platforms/unix/vm -I/home/kend/OpenSmalltalk/kens-vm/build.linux64ARMv8/squeak.stack.spur/build "
gcc -o evtest $TARGET_ARCH $CFLAGS $INCLUDES sqEVTest.c
echo "[Hopefully] compiled evtest"
