#!/bin/sh
# Sets the VM env var to the r3104 Newspeak VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.41.3104
REV=3104
LCBINDIR=4.0-3104
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            "Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" de5d9665b2e4a49d36059626238cefa4 \
            "Newspeak Virtual Machine.app-$TAG.tgz" f786ce8a9103c5d73457dd21d3af80cd
        VM="Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        nsvmlinuxht/lib/nsvm/$LCBINDIR/nsvm  \
        nsvmlinuxht-$TAG.tgz bde6c4aa584cfd25ec6c425ff8d7c476
    else
        get_vm_from_tar \
        nsvmlinux/lib/nsvm/$LCBINDIR/nsvm  \
        nsvmlinux-$TAG.tgz 2df70aec5d0b54577675d07c58211f06
    fi;;
CYGWIN*) get_vm_from_zip \
            nsvmwin/nsvmConsole.exe 71cd4966a2f9b76cd8b2d2fd4b942930 \
            nsvmwin-$TAG.zip 26e033b51244f444c1cc9b3a30c6ce6f
    VM=nsvmwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
