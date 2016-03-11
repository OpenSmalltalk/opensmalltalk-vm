#!/bin/sh
# Sets the VM env var to the r3643 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.10.3643
REV=3643
LSBINDIR=5.0-3643
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" a50b3f51714f1c012ce73a24a3c4fd1c \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" a8c926d31ca71fac7d7f202529b7aab8
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz 7a8810d1f87d044ad3a85866a6509e64
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe d9bb69463c8f9ec8b1436b294593f11e \
            nsvmspurwin-$TAG.zip ec9e07efe9eea8ff6cc4805fbde6de2a
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
