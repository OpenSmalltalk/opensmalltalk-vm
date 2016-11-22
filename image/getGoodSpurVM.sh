#!/bin/bash -e
# Sets the VM env var to the r3692 Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=16.18.3692
REV=3692
LSBINDIR=5.0-3692
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r$REV/

. ./envvars.sh

if [ "$1" = -vm -a -n "$2" -a -x "`which $2`" ]; then
	VM="$2"
else
	case "$OS" in
	Darwin) get_vm_from_tar \
				CogSpur.app/Contents/MacOS/Squeak 97460b152803235de4b0c11333f0cf74 \
				CogSpur.app-$TAG.tgz 38c190e78fff34760292d6a9da3a61b8
			VM=CogSpur.app/Contents/MacOS/Squeak;;
	Linux) get_vm_from_tar \
			cogspurlinuxht/lib/squeak/$LSBINDIR/squeak 64cda56486bf7351de7a40f0389edfba \
			cogspurlinuxht-$TAG.tgz 02948787583829d450d807afa910b178
		VM=cogspurlinuxht/squeak;;
	CYGWIN*) get_vm_from_zip \
				cogspurwin/SqueakConsole.exe 247e1e7a6acbb71f350f838ddc88b361 \
				cogspurwin-$TAG.zip 6a58964e6f69a6a379a5dcd73796207b
		VM=cogspurwin/SqueakConsole.exe;;
	*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
	esac
fi
