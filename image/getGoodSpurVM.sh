#!/bin/sh
# Sets the VM env var to the r3105 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.41.3105
REV=3105
LSBINDIR=5.0-3105
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 13b57f63961b57045300785c8e116a56 \
            CogSpur.app-$TAG.tgz dae4205b5790577d0190c0c05f9548d0
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 795aee1bd9a3d21eb1d02ecabf23b53a \
        cogspurlinuxht-$TAG.tgz fa3c82f64d6b9ea38618a1a60df8bb50
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe 7e33a679a9125743460894498308a612 \
            cogspurwin-$TAG.zip 015eb95c8850d2aade5d731e3cd617d8
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
