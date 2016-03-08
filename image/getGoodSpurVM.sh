#!/bin/sh
# Sets the VM env var to the r3632 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.08.3632
REV=3632
LSBINDIR=5.0-3632
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak a74172e86eaab82870d5705e853d0a05 \
            CogSpur.app-$TAG.tgz 7d24f3b04df720c44aec7c17ae6e1fc2
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 109b49166f318e099302dd9b7af66bd1 \
        cogspurlinuxht-$TAG.tgz a04d9883f1477ac4715c953f066c426e
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe ebe86e40295e9e437c5e4883a02e0998 \
            cogspurwin-$TAG.zip 01fa8395a2ab6f52191979de7e79f48a
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
