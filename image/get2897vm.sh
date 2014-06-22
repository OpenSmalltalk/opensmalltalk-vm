#!/bin/sh
# Sets the VM env var to the r2987 Cog VM for the current platform.
# will download and install the VM in this directory if necessary.
#set -v
. ./envvars.sh

if wget --help >/dev/null ; then
	true
else
	echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2
	 exit 1
fi

URL=http://www.mirandabanda.org/files/Cog/VM/VM.r2987/

case "$OS" in
Darwin)
	VM=Cog.app/Contents/MacOS/Squeak
	VMHASH=ec2962db9518aaea4fee1bc92007e635
	if [ ! -d Cog.app -o "`quientmd5 $VM`" != $VMHASH ]; then
		VMARC=Cog.app-14.23.2987.tgz
		ARCHASH=0f84cf23e98ea03ee7e87ccc8ba756ec
		if [ ! -f "$VMARC" -o "`quietmd5 $VMARC`" != $ARCHASH ]; then
			wget -c "$URL/$VMARC"
			if [ ! -f "$VMARC" -o "`quietmd5 $VMARC`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		tar xzf "$VMARC"
		if [ ! -d Cog.app -o "`quietmd5 $VM`" != $VMHASH ]; then
			echo failed to correctly extract Cog.app from $VMARC 1>&2
			exit 3
		fi
	fi;;
Linux)
	if expr $OSREL \> 2.6.12; then
		VM=coglinuxht/lib/squeak/4.0-2987/squeak
		VMHASH=6dc8912ed01875df67331d6cf592ac4b
		VMARC=coglinuxht-14.23.2987.tgz
		ARCHASH=e580c191aecce7c56fbe1900a5df2984
	else
		VM=coglinux/lib/squeak/4.0-2987/squeak
		VMHASH=8afd4020caca229b8bba4bd6a79d6d83
		VMARC=coglinux-14.23.2987.tgz
		ARCHASH=19d9c28860758db4e2f25642837de3c3
	fi
	if [ ! -d "`dirname $VM`" -o "`quietmd5 $VM`" != $VMHASH ]; then
		if [ ! -f "$VMARC" -o "`quietmd5 $VMARC`" != $ARCHASH ]; then
			wget -c "$URL/$VMARC"
			if [ ! -f "$VMARC" -o "`quietmd5 $VMARC`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		tar xzf "$VMARC"
		if [ ! -d "`dirname $VM`" -o "`quietmd5 $VM`" != $VMHASH ]; then
			echo failed to correctly extract "`dirname $VM`" from $VMARC 1>&2
			exit 3
		fi
	fi
	if expr $OSREL \> 2.6.12; then
		VM="coglinuxht/squeak"
	else
		VM="coglinux/squeak"
	fi;;
CYGWIN*)
	VM=cogwin/SqueakConsole.exe
	VMHASH=a68a3eab7db6713bed9f1560759f73ae
	VMARC=cogwin-14.23.2987.zip
	ARCHASH=acd8291859bfe10a52d6ecb28271a673
	if [ ! -d "`dirname $VM`" -o "`quietmd5 $VM`" != $VMHASH ]; then
		if [ ! -f "$VMARC" -o "`quietmd5 $VMARC`" != $ARCHASH ]; then
			wget -c "$URL/$VMARC"
			if [ ! -f "$VMARC" -o "`quietmd5 $VMARC`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		unzip -q "$VMARC"
		if [ ! -d "`dirname $VM`" -o "`quietmd5 $VM`" != $VMHASH ]; then
			echo failed to correctly extract "`dirname $VM`" from $VMARC 1>&2
			exit 3
		fi
	fi;;
*)	echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
