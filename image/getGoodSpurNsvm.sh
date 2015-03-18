#!/bin/sh
# Sets the VM env var to the r3268 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.10.3268
REV=3268
LSBINDIR=5.0-3268
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" ea1cfd302b5ae8605bab46398ad28f7e \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" c58a21bc7ffb3438579ec44f38694140
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz 9aeb16c69e87f6dd1b648bf666ed2042
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe 9dfd02a8ea55465d449cb82aa73a4f1d \
            nsvmspurwin-$TAG.zip b399741939f826e95f987278840b846d
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
