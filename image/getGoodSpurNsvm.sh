#!/bin/sh
# Sets the VM env var to the r3284 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.12.3284
REV=3284
LSBINDIR=5.0-3284
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" a500026c07eabcb7a558b05ef95943de \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" acd42baf3133d8831cb45d07fcd7de5a
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz 45151f84dd435d3c030d21d000aca031
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe 20041ae1b5a31b0092f93323bfcf2cfe \
            nsvmspurwin-$TAG.zip fdbbfd894fea949871652bcd3138bda1
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
