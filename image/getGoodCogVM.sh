#!/bin/sh
# Sets the VM env var to the r3632 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.08.3632
REV=3632
LCBINDIR=4.0-3632
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak cc870c04f3445c1a5e5de849db58d8d8 \
            Cog.app-$TAG.tgz cee17b54ab41396f9fd82e4eb10b17c6
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak  \
        coglinuxht-$TAG.tgz b9096e5c8e377891ed1238a757f21ee9
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak  \
        coglinux-$TAG.tgz f9a9e2bd413cc69df871d9d7f7d2dbc8
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 04c056a037e8492e64d7e21133fc7788 \
            cogwin-$TAG.zip 6af572be45074f11f99d8a090bc5fe1d
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
