#!/bin/sh
# Sets the VM env var to the r3284 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=15.12.3284
REV=3284
LSBINDIR=5.0-3284
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

case "$OS" in
Darwin) get_vm_from_tar \
            CogSpur.app/Contents/MacOS/Squeak c54b15ba899696e2efbe8844c8ba50c3 \
            CogSpur.app-$TAG.tgz cb11c0850aa43b0bef658254b1e02bc0
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 2092203ae9f5e6daedc9be0a1a85fa8a \
        cogspurlinuxht-$TAG.tgz 3ee0ff388b993297340a40dd8df6388c
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
            cogspurwin/SqueakConsole.exe c703176603aa14bf83d68ad9fa2749f0 \
            cogspurwin-$TAG.zip 048352452883f843ab28c0a9be821891
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
