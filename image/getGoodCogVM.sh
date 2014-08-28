#!/bin/sh
# Sets the VM env var to the r3063 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.32.3063
REV=3063
LCBINDIR=4.0-3063
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak efd6128a2e0ca36035bbe5ace4fd8e80 \
            Cog.app-$TAG.tgz 658e5e3a5085529959a744c11b78f7d9
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak badd6e33775c1176e478b2262cffe177 \
        coglinuxht-$TAG.tgz 1b58e26c4c6c92ca8b141e94c04b0ed9
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak 817f87fa0cf4b7d90ef9599d7b762fe5 \
        coglinux-$TAG.tgz 1394d1bfd1749b711a2266621dc8ff5b
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 8edd0cc2355232726330ecbc967c7ce0 \
            cogwin-$TAG.zip 888ca7a978e34176763c8be34fa13860
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
