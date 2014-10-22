#!/bin/sh
# Sets the VM env var to the r3105 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.41.3105
REV=3105
LSBINDIR=5.0-3105
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" b9b6885517bb1ddcc33f1f042b66fc2f \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" 516e07fcdd4987ceaa9ce2a1452dc6ce
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz 6e8cb761b039cc754887fa88a78cf5f7
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe f89c87da16fe250063d3b3623b868e33 \
            nsvmspurwin-$TAG.zip 763b6c882f65a573c7615eb53f2b3aa7
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
