#!/bin/bash -e
. ./envvars.sh

IMAGEHASH=e6be0ea204a8409dc0976a792502ab65
ZIPHASH=2f17e1d8eb9bec2b7554d3405652b122

if [ "`quietmd5 \"$SQUEAK50\".image`" != $IMAGEHASH ]; then
	ZIP=Squeak-5.0-All-in-One.zip
	if [ "`quietmd5 $ZIP`" != $ZIPHASH ]
	then
		geturl http://files.squeak.org/5.0/$ZIP
	fi
	if unzip --help >/dev/null; then
		true
	else
		echo 'could not find unzip.  you can find instructions on how to install it on google.' 1>&2
		exit 1
	fi
	rm -rf __MACOSX
	unzip $ZIP
	rm -rf __MACOSX
fi
test -f SqueakV50.sources || ln $SQUEAK50RESOURCES/SqueakV50.sources .
