#!/bin/sh
# Sets the VM env var to the r3354 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.20.3354
REV=3354
LCBINDIR=4.0-3354
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak a6f0ece7775772220e8bfe1e48524959 \
            Cog.app-$TAG.tgz 269ba0ef5e63aeaa52287834b6242966
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak 7ed115ceb484859c182ced6541137ce8 \
        coglinuxht-$TAG.tgz 9f50e0fa254d763fae635eeb98ecdeb0
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak 43804a192631dabba11f4051611475b0 \
        coglinux-$TAG.tgz 16b277420542af403be016dde6769c18
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe f55a39e14e6d0228c718f7b868e70bbc \
            cogwin-$TAG.zip b5253c1675b9e0d3887d50bd050fd75d
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
