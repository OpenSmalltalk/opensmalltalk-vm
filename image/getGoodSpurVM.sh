#!/bin/sh
# Sets the VM env var to the r3427 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.33.3427
REV=3427
LSBINDIR=5.0-3427
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 2a6014096316edd4ad40d123300513b4 \
            CogSpur.app-$TAG.tgz be907df0efa93bf6be1a2b42a71a9f8c
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak f41f0912d83dc51b772eb01e96fa4f86 \
        cogspurlinuxht-$TAG.tgz 3a5007971e3e4f24b4f8404e09a2a5c0
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe 91e6d35064ad7153011d36c9e9a81fe6 \
            cogspurwin-$TAG.zip 8aa98b6261cfe36258d1e09c54143a32
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
