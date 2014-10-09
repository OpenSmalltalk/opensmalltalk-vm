#!/bin/sh
# Sets the VM env var to the r3095 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.39.3095
REV=3095
LSBINDIR=5.0-3095
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 2b1088c7b33310ea3a3a71b0e7c2bf76 \
            CogSpur.app-$TAG.tgz 27bb41ea96cebe32f619cd694cb4f779
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak b549e5341e7c6cfd7902692055eaa5b8 \
        cogspurlinuxht-$TAG.tgz 621891e9bf782256a3e4e0c89d6e5929
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe ccd0f3ed63df616574c7f62ca03e6be0 \
            cogspurwin-$TAG.zip edc82d0157520b10e37f11438f687e33
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
