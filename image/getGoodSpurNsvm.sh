#!/bin/sh
# Sets the VM env var to the r3632 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.08.3632
REV=3632
LSBINDIR=5.0-3632
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" aaf0792cc1494e43e01349565c52772e \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" 7405599f94a2c4eb9000e5bbcbb11713
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz 2ad8a1d108801697e4d35ea48be0a459
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe c1fa61e4a5fb1991d33d630e46d5fa69 \
            nsvmspurwin-$TAG.zip b3c03d6c310ec32226352b4a56cac940
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
