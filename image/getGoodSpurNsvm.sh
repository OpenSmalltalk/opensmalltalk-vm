#!/bin/sh
# Sets the VM env var to the r3072 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.36.3072
REV=3072
LSBINDIR=5.0-3072
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" 1bb3e6f5788eae66f22b779499d00647 \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" 4fd139327fe841fdde9c6b5de39f18c1
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz a8f7b00b9cf6a7adce2c1d21db0488c8
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe 7d8b3b848c792de45dd6af95111abdb1 \
            nsvmspurwin-$TAG.zip 6ea38c0f8e1a65809134d391341aa3b2
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
