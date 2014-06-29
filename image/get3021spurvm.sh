#!/bin/sh
# Sets the VM env var to the r3021 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.
#set -v
. ./envvars.sh

if wget --help >/dev/null; then
	true
else
	echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2
	 exit 1
fi

URL=http://www.mirandabanda.org/files/Cog/VM/VM.r3021/

case "$OS" in
Darwin) get_vm_from_tar \
			CogSpur.app/Contents/MacOS/Squeak fb003318b8fbb7a50dc9f6d9dd82b454 \
			CogSpur.app-14.25.3021.tgz 6767d878f8331a0728ca3fb19cfd754e
	VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \
	cogspurlinuxht/lib/squeak/4.0-3021/squeak e826b2307e1618ee3492de7fae0ae594 \
	cogspurlinuxht-14.25.3021.tgz ad01f54ae5d3c2c3b4d8e8f1d640fedd
	VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \
			cogspurwin/SqueakConsole.exe 8d8a644ef1bf7e201862e49ce9358e11 \
			cogspurwin-14.25.3021.zip 407da5d8f34482be96eaa299907c51eb
	VM=cogwin/SqueakConsole.exe;;
*)	echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
