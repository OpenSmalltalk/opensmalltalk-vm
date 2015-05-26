#!/bin/sh
# Sets the VM env var to the r3354 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.20.3354
REV=3354
LSBINDIR=5.0-3354
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 4858caf533bcac30301b63b4a2b03dee \
            CogSpur.app-$TAG.tgz 69dfd7c4af7c5c1323b57f8df1945759
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak e7ef9060beedb0e3d049de685d269eb1 \
        cogspurlinuxht-$TAG.tgz 7d91b75be4f17ea0ea836eba5237fa10
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe f0cf0edce87d42cf1cc7bd8afc4ed8ca \
            cogspurwin-$TAG.zip 75d735ce6f9b4368662e21b26de1ae11
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
