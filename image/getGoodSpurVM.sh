#!/bin/sh
# Sets the VM env var to the r3268 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.10.3268
REV=3268
LSBINDIR=5.0-3268
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 208143bb3195626fb1894f22848e9139 \
            CogSpur.app-$TAG.tgz 4b7d0968102a9bf2d60d4b2c85a54243
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 544bec4d35b0e3d11df7f1452c79d5f5 \
        cogspurlinuxht-$TAG.tgz 0b0e8451025d7bd00c33645ce3d1b6d1
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe 7f8658b9aebb9edeaaa0eab1c8cf5b3b \
            cogspurwin-$TAG.zip a6fac7266bce08f91953433e51e2b94c
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
