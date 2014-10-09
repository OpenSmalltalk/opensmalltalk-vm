#!/bin/sh
# Sets the VM env var to the r3095 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.39.3095
REV=3095
LCBINDIR=4.0-3095
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 4333a73cfdc82b98d5af6bc4214637cf \
            Cog.app-$TAG.tgz 876826f15ce25e120838459c6ae28c77
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak c60d17a17c01a6e3540e2d44ff85b3fa \
        coglinuxht-$TAG.tgz 0e373fb98a13c39451cc7a10117a3b9e
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak 0a1c7a1038202dc0fd2b9cd296e2e2ea \
        coglinux-$TAG.tgz 2d7acdf79117c107d62ffd587e8bfd19
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe c20ccbda88943dad5921c5cc3ca396d6 \
            cogwin-$TAG.zip 84b1167a6766d637b70d358a21ce895f
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
