#!/bin/bash -e
. ./envvars.sh

IMAGEHASH=1d0d4320224b741da1f56c6871963702
ZIPHASH=b90e0303ab61e928a5d997b22d18b468

if [ "`quietmd5 \"$SQUEAK45\".image`" != $IMAGEHASH ]; then
	ZIP=Squeak-4.5-All-in-One.zip
	if [ "`quietmd5 $ZIP`" != $ZIPHASH ]
	then
		geturl http://ftp.squeak.org/4.5/$ZIP
	fi
	if unzip --help >/dev/null; then
		true
	else
		echo 'could not find unzip.  you can find instructions on how to install it on google.' 1>&2
		exit 1
	fi
	unzip $ZIP
fi
test -f SqueakV41.sources || ln $SQUEAK45RESOURCES/SqueakV41.sources .
