#!/bin/sh
# Sets the VM env var to the r3029 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.26.3029
REV=3029
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

if wget --help >/dev/null ; then
    true
else
    echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2
     exit 1
fi

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak a8836be2d6d62bd5711dbfdd043757b4 \
            Cog.app-$TAG.tgz d7a301c471515ea90c69f62225a93555
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/4.0-$REV/squeak 9d0f27d9b71f1dacc31b8beafa4c3b6d \
        coglinuxht-$TAG.tgz 2300e4d895b26bfcc6a652841781ac90
    else
        get_vm_from_tar \
        coglinux/lib/squeak/4.0-$REV/squeak eff9d1c4b5c64c23109dff0f0d634ae9 \
        coglinux-$TAG.tgz 655db6462a9d804983dffd3eda4d0531
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe e6ebcb8a8c3f585cad66c7a54e47206f \
            cogwin-$TAG.zip cea244b795ac9cebc7b47ac94af6a5a2
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
