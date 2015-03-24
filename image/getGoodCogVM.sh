#!/bin/sh
# Sets the VM env var to the r3284 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.12.3284
REV=3284
LCBINDIR=4.0-3284
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak 51f69399642245df1978b81b529ed7a0 \
            Cog.app-$TAG.tgz 34828c5b563e5e64ede280429ca1a745
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak b8c8ccdb36d1fd893a9b15778e2bf500 \
        coglinuxht-$TAG.tgz 2035d84a2a4f2dc27d40b988348c21f8
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak 4c9add7b905d9b80ccca522926df16d4 \
        coglinux-$TAG.tgz af87e9a96be77318cce91a9fd07396ad
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 60f116a058a6d6ed55b3eda594b9e267 \
            cogwin-$TAG.zip 0c4d4eab877bbdc884fb691176640aea
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
