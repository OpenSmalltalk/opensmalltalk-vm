#!/bin/sh
# Sets the VM env var to the r3268 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.10.3268
REV=3268
LCBINDIR=4.0-3268
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 18b8c3dc580175d8868fc344a7a95906 \
            Cog.app-$TAG.tgz 02e5a264b75d8acefe18f41b968281ec
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak 389b8f9f2ad00e11ddcd44afeb53a39d \
        coglinuxht-$TAG.tgz c7559e6ac6771d746139c83f06245072
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak 8287d559a685cd126b6f77695c25b220 \
        coglinux-$TAG.tgz 41d1f31a723ed131232312b544430f36
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 76821340c77c1e8b43840872eb92f89f \
            cogwin-$TAG.zip 93c057fb51fc3db82e7cbf39a19496f4
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
