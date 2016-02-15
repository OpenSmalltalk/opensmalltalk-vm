#!/bin/sh
# Sets the VM env var to the r3602 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.07.3602
REV=3602
LCBINDIR=4.0-3602
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 881a82bdab55694933114608c2e083f1 \
            Cog.app-$TAG.tgz e80c18e45b33f23dc17bedc5108385f9
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak  \
        coglinuxht-$TAG.tgz 0122db0348fbf6ee27e0189d8c6101ab
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak  \
        coglinux-$TAG.tgz 3dd2fc07aee66be652b7636bf2337090
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 5a11b5d0fd2aa32e966cc76d85fd6876 \
            cogwin-$TAG.zip 71546e5fde965441ca6da248a2fd003f
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
