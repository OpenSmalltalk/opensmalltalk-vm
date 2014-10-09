#!/bin/sh
# Sets the VM env var to the r3095 Newspeak VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.39.3095
REV=3095
LCBINDIR=4.0-3095
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" e84764bad961132c21db23a291b35d6c \
            "Newspeak Virtual Machine.app-$TAG.tgz" 0c8069350a057e03397b02adc85df31a
        VM="Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        nsvmlinuxht/lib/nsvm/$LCBINDIR/nsvm  \
        nsvmlinuxht-$TAG.tgz b242db5776e35ceb34669313c5423eea
    else
        get_vm_from_tar \
        nsvmlinux/lib/nsvm/$LCBINDIR/nsvm  \
        nsvmlinux-$TAG.tgz d39847515fb436bd715e129cf37e79e9
    fi;;
CYGWIN*) get_vm_from_zip \
            nsvmwin/nsvmConsole.exe 05cddd5c752019af301815dd18996164 \
            nsvmwin-$TAG.zip c77545ac931d80fcc917b138c99746fa
    VM=nsvmwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
