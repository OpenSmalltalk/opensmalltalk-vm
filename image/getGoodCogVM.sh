#!/bin/sh
# Sets the VM env var to the r3602 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.07.3602
REV=3602
LCBINDIR=4.0-3602
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak  \
            Cog.app-$TAG.tgz         VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/$LCBINDIR/squeak  \
        coglinuxht-$TAG.tgz 5067a62fde21ff4f39181619126b8380
    else
        get_vm_from_tar \
        coglinux/lib/squeak/$LCBINDIR/squeak  \
        coglinux-$TAG.tgz 60078d8c3f5d24ea8d8362ffb5bc7b3b
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 5a11b5d0fd2aa32e966cc76d85fd6876 \
            cogwin-$TAG.zip 4a0b12b67164b788aa615089b5e8cb81
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
