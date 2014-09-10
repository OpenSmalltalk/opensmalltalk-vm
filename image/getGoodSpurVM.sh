#!/bin/sh
# Sets the VM env var to the r3072 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.36.3072
REV=3072
LSBINDIR=5.0-3072
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak a982553a2058308d1c495432d8796b41 \
            CogSpur.app-$TAG.tgz b91e4783d82e945955cc7bf4bfd25571
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak eb02c5b6fe38196e653401890d8aa423 \
        cogspurlinuxht-$TAG.tgz cfb2d3e8b372d62cc1ed36c99cbfc4ed
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe df420a030174c17ab2e2726c113ef81a \
            cogspurwin-$TAG.zip 2c2a5b1e498578e6a95424e388731fa2
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
