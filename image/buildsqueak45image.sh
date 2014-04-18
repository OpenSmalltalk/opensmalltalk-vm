#!/bin/bash
SQUEAK45APP=Squeak-4.5-All-in-One.app
SQUEAK45RESOURCES=$SQUEAK45APP/Contents/Resources
SQUEAK45=$SQUEAK45RESOURCES/Squeak4.5-13680

if [ "`md5 -q \"$SQUEAK45\".image`" != 1d0d4320224b741da1f56c6871963702 ]; then
	ZIP=Squeak-4.5-All-in-One.zip
	if [ "`md5 -q $ZIP`" != b90e0303ab61e928a5d997b22d18b468 ]
	then
		wget --help >/dev/null || (echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2; exit 1)
		wget -c http://ftp.squeak.org/4.5/$ZIP
	fi
	unzip --help >/dev/null || (echo 'could not find unzip.  you can find instructions on how to install it on google.' 1>&2; exit 1)
	unzip $ZIP
fi
test -f SqueakV41.sources || ln $SQUEAK45RESOURCES/SqueakV41.sources .
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

exec "$VM" CogVMMaker.image BuildSqueak45Image.st
