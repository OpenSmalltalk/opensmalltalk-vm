#!/bin/sh
# Sets the VM env var to the r2987 Cog Spur VM for the current platform.
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
	VM=CogSpur.app/Contents/MacOS/Squeak
	VMHASH=8d2bbd946a70e3992cca0fbc125d2f19
	if [ ! -d CogSpur.app -o "`/sbin/md5 -q $VM`" != $VMHASH ]; then
		VMARC=CogSpur.app-14.23.2987.tgz
		ARCHASH=16fef44f099f1f89e6fcd1d53ea58b02
		if [ ! -f "$VMARC" -o "`/sbin/md5 -q "$VMARC"`" != $ARCHASH ]; then
			wget -c "$URL/$VMARC"
			if [ ! -f "$VMARC" -o "`/sbin/md5 -q "$VMARC"`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		tar xzf "$VMARC"
		if [ ! -d CogSpur.app -o "`/sbin/md5 -q $VM`" != $VMHASH ]; then
			echo failed to correctly extract CogSpur.app from $VMARC 1>&2
			exit 3
		fi
	fi;;
Linux)
	VM=cogspurlinuxht/lib/squeak/4.0-2987/squeak
	VMHASH=c2787117cf634c4561c7f7a22d748221
	VMARC=cogspurlinuxht-14.23.2987.tgz
	ARCHASH=40b943c9ab0dcc472b952167579b994f
	if [ ! -d "`dirname $VM`" -o \
		"`/usr/bin/md5sum "$VM" | sed 's/ .*$//'`" != $VMHASH ]; then
		if [ ! -f "$VMARC" \
			-o "`/usr/bin/md5sum "$VMARC" | sed 's/ .*$//'`" != $ARCHASH ]; then
			wget -c "$URL/$VMARC"
			if [ ! -f "$VMARC" \
				-o "`/usr/bin/md5sum "$VMARC" | sed 's/ .*$//'`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		tar xzf "$VMARC"
		if [ ! -d "`dirname $VM`" \
			-o "`/usr/bin/md5sum $VM | sed 's/ .*$//'`" != $VMHASH ]; then
			echo failed to correctly extract "`dirname $VM`" from $VMARC 1>&2
			exit 3
		fi
	fi
	VM="cogspurlinuxht/squeak";;
CYGWIN*)
	VM=cogwin/SqueakConsole.exe
	VMHASH=a68a3eab7db6713bed9f1560759f73ae
	VMARC=cogwin-14.23.2987.tgz
	ARCHASH=acd8291859bfe10a52d6ecb28271a673
	if [ ! -d "`dirname $VM`" \
			-o "`/usr/bin/md5sum "$VM" | sed 's/ .*$//'`" != $VMHASH ]; then
		if [ ! -f "$VMARC" \
			-o "`/usr/bin/md5sum "$VMARC" | sed 's/ .*$//'`" != $ARCHASH ]; then
			wget -c "$URL/$VMARC"
			if [ ! -f "$VMARC" \
				-o "`/usr/bin/md5sum "$VMARC" | sed 's/ .*$//'`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		unzip -q "$VMARC"
		if [ ! -d "`dirname $VM`" \
			-o "`/usr/bin/md5sum $VM | sed 's/ .*$//'`" != $VMHASH ]; then
			echo failed to correctly extract "`dirname $VM`" from $VMARC 1>&2
			exit 3
		fi
	fi;;
*)	echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
