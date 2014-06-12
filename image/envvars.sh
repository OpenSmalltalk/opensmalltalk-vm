#!/bin/bash
SQUEAK45APP=Squeak-4.5-All-in-One.app
SQUEAK45RESOURCES=$SQUEAK45APP/Contents/Resources
SQUEAK45=$SQUEAK45RESOURCES/Squeak4.5-13680

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
