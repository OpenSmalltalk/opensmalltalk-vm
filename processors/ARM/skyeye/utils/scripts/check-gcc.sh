#!/bin/sh
#
# Written by Anthony Lee 2007.03
#

printf "Checking gcc ... "

case $CC in
	*gcc*)
		;;
	*)
		printf "IGNORE\n"
		exit 0
		;;
esac

if ( $CC -dumpversion > /dev/null 2>&1 ); then
	GCC_VERSION=`$CC -dumpversion`
elif ( $CC --version > /dev/null 2>&1 ); then
	GCC_VERSION=`$CC --version`
else
	GCC_VERSION=unknown
fi

case $GCC_VERSION in
	unknown|2.*)
		printf "FAILED\n\n"
		printf "*** You are using $CC, version $GCC_VERSION .\n"
		printf "*** To perform the compilation, we need gcc >= 3.x.x !!!\n"
		printf "*** Run \"make NO_GCC_CHECK=1\" instead to ignore it.\n\n"
		exit 1
		;;
	*)
		printf "OK ( `basename $CC` version: $GCC_VERSION )\n"
		exit 0
		;;
esac

