#!/bin/sh
# Sets the VM env var to the r3427 Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.33.3427
REV=3427
LSBINDIR=5.0-3427
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" 912f3274c7fd81fc681239939a549001 \
            "Newspeak Spur Virtual Machine.app-$TAG.tgz" d2c8cb923a62c054aa45f776b977dd24
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \
        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm  \
        nsvmspurlinuxht-$TAG.tgz 46769daa78a05070f175bfd980749a83
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \
            nsvmspurwin/nsvmConsole.exe 76e5468ad604396f35f93fd7a435a117 \
            nsvmspurwin-$TAG.zip ef126eca43771c61db2819832b853062
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
