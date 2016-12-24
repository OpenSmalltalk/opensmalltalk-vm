#!/bin/sh
VARIANT_FOLDER="$1"
VARIANT_NAME="$2"
OS_NAME="`uname -o`"
GENERATOR_NAME="Unix Makefiles"

rm -rf "./$VARIANT_FOLDER"
mkdir "./$VARIANT_FOLDER"
cd "./$VARIANT_FOLDER"

if [ "$OS_NAME" = "Msys" ]; then
    GENERATOR_NAME="MSYS Makefiles"
fi

if [ "$OS_NAME" = "Cygwin" ]; then
    export CC="x86_64-w64-mingw32-gcc"
    export CXX="x86_64-w64-mingw32-g++"
fi
