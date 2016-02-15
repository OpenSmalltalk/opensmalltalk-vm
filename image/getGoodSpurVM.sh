#!/bin/sh
# Sets the VM env var to the r3602 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.07.3602
REV=3602
LSBINDIR=5.0-3602
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak 3c4491f496e2d8cc4d46b65c6c26808a \
            CogSpur.app-$TAG.tgz 5a29a80a4492ac2a2cc7106e2a3157e1
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 072645c861b7cf692373c6e0a7170e06 \
        cogspurlinuxht-$TAG.tgz c79a7e43dfa19a04ebb3a1d197f998dc
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe e802302bab1d7264eef1d5f7e99d938b \
            cogspurwin-$TAG.zip bc9a7078ef93bb357c5265d69ef66dae
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
