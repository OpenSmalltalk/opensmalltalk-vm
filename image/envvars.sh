#!/usr/bin/env bash
set -e

BASE=trunk6
BASE64=trunk6-64

# N.B. uname -r (OSREL) is not to be trusted on Mac OS X;

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
