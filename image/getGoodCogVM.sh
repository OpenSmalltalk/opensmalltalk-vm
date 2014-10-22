#!/bin/sh
# Sets the VM env var to the r3104 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.41.3104
REV=3104
LCBINDIR=4.0-3104
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 87bccfaa11dafb2c8c16850cbd021fb2 \
            Cog.app-$TAG.tgz 3e75109726f0970a4e0e61869d1be212
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak 706c5ffb7023bd0a9a43d7b6c847df73 \
        coglinuxht-$TAG.tgz 9d09d5420139535a07af343418ee9985
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak 1c7188ef81af887abd84b159af52bdaf \
        coglinux-$TAG.tgz d67b929fbbd20542abb62aaf8cc8cbca
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe a68530a6d08d2d043eb16ecb932b7383 \
            cogwin-$TAG.zip a66ba06907bdfdde191b1bf45a495cd2
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
