#!/bin/bash -e
SQUEAK45APP=Squeak-4.5-All-in-One.app
SQUEAK45RESOURCES=$SQUEAK45APP/Contents/Resources
SQUEAK45=$SQUEAK45RESOURCES/Squeak4.5-13680

SQUEAK50APP=Squeak-5.0-All-in-One/Squeak-5.0-All-in-One.app
SQUEAK50RESOURCES=$SQUEAK50APP/Contents/Resources
SQUEAK50=$SQUEAK50RESOURCES/Squeak5.0-15113

# N.B. uname -r (OSREL) is not to be trusted on Mac OS X;
# my 10.6.8 system reports its version as 10.8.0.  eem, june '14

if test -x /usr/bin/uname; then
	OS=`/usr/bin/uname -s`
	OSREL=`/usr/bin/uname -r | sed 's/\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*$/\1.\2.\3/'`
elif test -x /bin/uname; then
	OS=`/bin/uname -s`
	CPU=`/bin/uname -m`
	OSREL=`/bin/uname -r | sed 's/\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*$/\1.\2.\3/'`
else
	OS=`uname -s`
	CPU=`uname -m`
	OSREL=`uname -r | sed 's/\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*$/\1.\2.\3/'`
fi

test "$OS" = Darwin && function quietmd5 { /sbin/md5 -q "$1" 2>/dev/null; }
test "$OS" = Darwin || function quietmd5 { /usr/bin/md5sum "$1" | sed 's/ .*$//' 2>/dev/null; }

test "$OS" = Darwin && function geturl { FILE=`basename "$1"`; curl -C - "`echo $1 | sed 's/ /%20/g'`" -o "$FILE"; }
test "$OS" = Darwin || function geturl { wget -c "$1"; }

if [ "$OS" != Darwin -a ! -x "`which wget`" ]; then
	echo "cannot find wget. wget for Windows is available from http://gnuwin32.sourceforge.net/packages/wget.htm, probably as http://downloads.sourceforge.net/gnuwin32/wget-1.11.4-1-setup.exe" 1>&2
	exit
fi

if unzip --help >/dev/null; then
	true
else
	echo 'could not find unzip.  you can find instructions on how to install it on google.' 1>&2;
	exit 1
fi

function get_vm_from_tar # VM VMHASH VMARC VMARCHASH
{	VM="$1"
	VMDIR=`echo $VM | sed 's/\/.*//'`
	VMHASH="$2"
	if [ ! -d "$VMDIR" -o "`quietmd5 "$VM"`" != $VMHASH ]; then
		VMARC="$3"
		ARCHASH="$4"
		if [ ! -f "$VMARC" -o "`quietmd5 "$VMARC"`" != $ARCHASH ]; then
			geturl "$URL/$VMARC"
			if [ ! -f "$VMARC" -o "`quietmd5 "$VMARC"`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		rm -rf "$VMDIR"
		tar xzf "$VMARC"
		if [ ! -d "$VMDIR" -o "`quietmd5 "$VM"`" != $VMHASH ]; then
			echo failed to correctly extract $VMDIR from $VMARC 1>&2
			exit 3
		fi
	fi
}

function get_vm_from_zip # VM VMHASH VMARC VMARCHASH
{	VM="$1"
	VMDIR=`echo $VM | sed 's/\/.*//'`
	VMHASH="$2"
	VMARC="$3"
	ARCHASH="$4"
	if [ ! -d "$VMDIR" -o "`quietmd5 "$VM"`" != $VMHASH ]; then
		if [ ! -f "$VMARC" -o "`quietmd5 "$VMARC"`" != $ARCHASH ]; then
			geturl "$URL/$VMARC"
			if [ ! -f "$VMARC" -o "`quietmd5 "$VMARC"`" != $ARCHASH ]; then
				echo failed to get $VMARC \; file corrupted\? 1>&2
				exit 2
			fi
		fi
		rm -rf "$VMDIR"
		unzip -q "$VMARC"
		if [ ! -d "$VMDIR" -o "`quietmd5 "$VM"`" != $VMHASH ]; then
			echo failed to correctly extract "`dirname $VM`" from $VMARC 1>&2
			exit 3
		fi
	fi
}
