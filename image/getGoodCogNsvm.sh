#!/bin/sh
# Sets the VM env var to the r3072 Newspeak VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.36.3072
REV=3072
LCBINDIR=4.0-3072
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" a6673fe5075d4edce0aabb7e66e50b51 \
            "Newspeak Virtual Machine.app-$TAG.tgz" dd51e7ffc8f583bf5c66af8b8fb3e4c4
        VM="Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        nsvmlinuxht/lib/nsvm/$LCBINDIR/nsvm  \
        nsvmlinuxht-$TAG.tgz 903c1829609725047e744de720a3bf3d
    else
        get_vm_from_tar \
        nsvmlinux/lib/nsvm/$LCBINDIR/nsvm  \
        nsvmlinux-$TAG.tgz a9d057816e404ce80bb76bb9717830b2
    fi;;
CYGWIN*) get_vm_from_zip \
            nsvmwin/nsvmConsole.exe 688e2dcf54507a8793d31c0f75904550 \
            nsvmwin-$TAG.zip 4a88663723d6c00541359d5764fda030
    VM=nsvmwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
