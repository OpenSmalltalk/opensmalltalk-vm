#!/bin/sh
# Sets the VM env var to the r3060 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.31.3060
REV=3060
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            Cog.app/Contents/MacOS/Squeak b9d79576423fe79f9f77383f676d37d6 \
            Cog.app-$TAG.tgz 2d93340bed9902bd8913067f372c7371
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr $OSREL \> 2.6.12; then
        get_vm_from_tar \
        coglinuxht/lib/squeak/4.0-$REV/squeak 35c003d9bd2c614850ca5b99c86155e9 \
        coglinuxht-$TAG.tgz a9e34f56f4923fff1ab4fc82f6ec93a0
    else
        get_vm_from_tar \
        coglinux/lib/squeak/4.0-$REV/squeak 8327eef0d7dda150f3fcf809df940bf5 \
        coglinux-$TAG.tgz 81466c4732d2fa5d8aec991938e714c8
    fi;;
CYGWIN*) get_vm_from_zip \
            cogwin/SqueakConsole.exe 6655d9ea5c7f0919f61a9cf5ad58b202 \
            cogwin-$TAG.zip 8fa6ba2df26e72342889b0279f17bb6d
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
