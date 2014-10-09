#!/bin/sh
# Sets the VM env var to the r3095 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.39.3095
REV=3095
LSBINDIR=5.0-3095
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" e29b2cec39511ceb654976fb6663a119 \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" 252be83f5480eb853148b1189f826916
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz 6c9d6f70d345a0ff19003a55781a50e2
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe d0c3c8bee789d2bb40f08bf09c5e0818 \
            nsvmspurwin-$TAG.zip 6b61b05a26022f1d0cbfb4f189efb8bf
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
