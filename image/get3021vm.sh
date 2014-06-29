#!/bin/sh
# Sets the VM env var to the r3021 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.
#set -v
. ./envvars.sh

if wget --help >/dev/null ; then
	true
else
	echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2
	 exit 1
fi

URL=http://www.mirandabanda.org/files/Cog/VM/VM.r3021/

case "$OS" in
Darwin) get_vm_from_tar \
			Cog.app/Contents/MacOS/Squeak 8f6f98f8bc7e79ceb19734286d0dbe1b \
			Cog.app-14.25.3021.tgz ac6a54d861cf6fb46d7b926f6d8baf50
		VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
	if expr $OSREL \> 2.6.12; then
		get_vm_from_tar \
		coglinuxht/lib/squeak/4.0-3021/squeak de88791228cbb74925de35cb126f317b \
		coglinuxht-14.25.3021.tgz 3486b358193430d46094ea3abfe9a093
		VM=coglinuxht/lib/squeak/4.0-3021/squeak
	else
		get_vm_from_tar \
		coglinux/lib/squeak/4.0-3021/squeak 77b02e13a80bbea045fafc59a6f963ec \
		coglinux-14.25.3021.tgz 9c87dc67d7505be3b4c74497fa09f61c
		VM=coglinux/lib/squeak/4.0-3021/squeak
	fi;;
CYGWIN*) get_vm_from_zip \
			cogwin/SqueakConsole.exe c72e3239aa011374896361d08d184afc \
			cogwin-14.25.3021.zip e0189adc34a8c8f6f015ae621245c475
	VM=cogwin/SqueakConsole.exe;;
*)	echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
