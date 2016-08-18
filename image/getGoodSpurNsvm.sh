#!/bin/bash -e
# Sets the VM env var to the r3692 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.18.3692
REV=3692
LSBINDIR=5.0-3692
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" 45319b241d7b0a2c00d2dd770a495abf \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" 7504c3a462103df69fc64fa82351c6ee
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz d47de73d6c8ef8a8338a6932ebf4c842
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe bb82d0fc34ee0ea3a63f0f49ccb93e9b \
            nsvmspurwin-$TAG.zip fb9665b61770bc54cf41b2e52c62b47f
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
