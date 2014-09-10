#!/bin/sh
# Sets the VM env var to the r3072 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.36.3072
REV=3072
LCBINDIR=4.0-3072
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 49373a45b8a27e38408747aa8955efc9 \
            Cog.app-$TAG.tgz 590e1081ba88e6eb2b3f56a9729505c9
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak 4e9d39e3ef6f3d82de2054574634cbed \
        coglinuxht-$TAG.tgz 3082f937dbe4ea923be05d87fcd6fba9
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak cca96956321b47e6b3db889308afd2a2 \
        coglinux-$TAG.tgz 7d6f7ea426c313fdf78edec9c71728ef
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 698c354779a358504fb7aaeee36c231d \
            cogwin-$TAG.zip 2df97ca6d48bbcf1b1fd271379bc40cf
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
