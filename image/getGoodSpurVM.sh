#!/bin/sh
# Sets the VM env var to the r3029 Cog Spur VM for the current platform.
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
            CogSpur.app/Contents/MacOS/Squeak 19a64f72acb1e2d3d6f2d47410e6e26a \
            CogSpur.app-$TAG.tgz bbf5edcee366fd4e0f0340ff9fbcfcb3
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/4.0-$REV/squeak eb322de8e2bd4ce388573733f8f01405 \
        cogspurlinuxht-$TAG.tgz ae8abc7d0d4c7d7c4290a93d173179f3
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe 4bc6353fa35fa60e7bd2dfc3ec2fa4a8 \
            cogspurwin-$TAG.zip b3d0fd96e0d17fdb79f9c9d31f816fde
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
