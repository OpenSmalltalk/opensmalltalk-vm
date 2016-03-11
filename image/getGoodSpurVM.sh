#!/bin/sh
# Sets the VM env var to the r3643 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.10.3643
REV=3643
LSBINDIR=5.0-3643
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 244323eea6792e2e69bd523c9911b2f8 \
            CogSpur.app-$TAG.tgz 7421e8188932dede31d5182238ee64c2
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 37bc3cec9db46498640b3d9eefeebdfd \
        cogspurlinuxht-$TAG.tgz 02e977113ee4a059637650ab69439bff
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe 2bcad50dcfe458e5737cd843546f47de \
            cogspurwin-$TAG.zip 42112ad448e806790ad112635a596337
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
