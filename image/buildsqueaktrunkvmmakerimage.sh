#!/bin/bash
. ./envvars.sh
./getsqueak45.sh

cp -p $SQUEAK45.image CogVMMaker.image
cp -p $SQUEAK45.changes CogVMMaker.changes

OS=`uname -s`
CPU=`uname -m`

case $OS in
Darwin)		VM="$SQUEAK45APP/Contents/MacOS/Squeak";;
CYGWIN*)	VM="$SQUEAK45APP/SqueakConsole.exe";;
Linux)		if [ "$CPU" = x86_64 ]; then
				CPU=i686
				echo Running 32-bit Squeak on a 64-bit System. Hope the 32-bit runtime libraries are installed ... 
			fi
			VM="$APP/Contents/$OS-$CPU/bin/squeak";;
*)	echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac

exec "$VM" CogVMMaker.image BuildSqueakTrunkImage.st
