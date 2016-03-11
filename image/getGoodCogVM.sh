#!/bin/sh
# Sets the VM env var to the r3643 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.10.3643
REV=3643
LCBINDIR=4.0-3643
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 6495fcad0dfc1302a7abeb40860b228e \
            Cog.app-$TAG.tgz c024c56458e4cb9c58002a25f93bd59a
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak  \
        coglinuxht-$TAG.tgz b425f59475f1357fbe0c25b445f69717
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak  \
        coglinux-$TAG.tgz df1101e6ed629198f0806b75d9c12532
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 21c42946fec449edba92f5ca863e390a \
            cogwin-$TAG.zip b38822661e97686813ac0512c825428b
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
