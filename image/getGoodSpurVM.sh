#!/bin/sh
# Sets the VM env var to the r3060 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.31.3060
REV=3060
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
            CogSpur.app/Contents/MacOS/Squeak d71657f3596108f1ee26ddde98d2a6e1 \
            CogSpur.app-$TAG.tgz 775fc34a65293eb7c6b1fe585b29343c
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/4.0-$REV/squeak c0df39147de2ac7d76aee7d7aa073f36 \
        cogspurlinuxht-$TAG.tgz 70421b720be1f5f843c96b48fbe8d07e
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe 83454062da3b7855b81e3fb5a8c6d360 \
            cogspurwin-$TAG.zip 463d2fe92c95f4c7083ac37cd9baf84f
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
