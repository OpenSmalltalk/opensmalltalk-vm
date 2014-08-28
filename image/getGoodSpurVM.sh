#!/bin/sh
# Sets the VM env var to the r3063 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=14.32.3063
REV=3063
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 80a55ecfb5abeabf3890c87898ee5914 \
            CogSpur.app-$TAG.tgz 741a5355c22f20cda33db969bb5e3d7a
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 22e8dfc3409a79155f79b2943c834572 \
        cogspurlinuxht-$TAG.tgz af8988545c1042a9813e3166390af6cb
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe a7bc32115050dab7e9060e8391025c4e \
            cogspurwin-$TAG.zip 6945ef0ff89bc5c1da00f6076868f3e6
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
