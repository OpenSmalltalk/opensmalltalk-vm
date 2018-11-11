#!/bin/bash

# Script for building metal shaders offline. This approach is used by SDL2,
# and we copy it because of incompatibility problems with the CI infrastructure.

cd `dirname $0`
cd ..

generate_shader()
{
    SOURCE="$1"
    ARRAY_NAME="$2"
    BETTER_ARRAY_NAME="$3"

    xcrun -sdk macosx metal -c -Wall -O3 -o "$SOURCE.air" $SOURCE || exit $?
    xcrun -sdk macosx metallib -o "$SOURCE.metallib" "$SOURCE.air" || exit $?
    xxd -i "$SOURCE.metallib" | sed "s/unsigned/const unsigned/g; s/$ARRAY_NAME/$BETTER_ARRAY_NAME/g" > "$SOURCE.inc"
    rm "$SOURCE.air" "$SOURCE.metallib"
}

generate_shader platforms/iOS/vm/OSX/SqueakMainShaders.metal platforms_iOS_vm_OSX_SqueakMainShaders_metal_metallib SqueakMainShaders_metallib
