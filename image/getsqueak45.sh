#!/bin/bash
. ./envvars.sh

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
