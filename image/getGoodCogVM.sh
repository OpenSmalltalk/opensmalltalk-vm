#!/bin/bash -e
# Sets the VM env var to the r3692 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.18.3692
REV=3692
LCBINDIR=4.0-3692
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 738b30c9c50e489fe4068e4998e53d44 \
            Cog.app-$TAG.tgz 17f05311cf1e2f8042c8781e14a3e985
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak  \
        coglinuxht-$TAG.tgz 3f2022dfb4d804a265c77aa770e34606
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak  \
        coglinux-$TAG.tgz 4ef3daa36509f8e6d0644ac954d9c70f
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 41ca7c10b9f08d97739477439ebfaaf2 \
            cogwin-$TAG.zip 7667b6c84c53376699aa80a183dc33f7
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
