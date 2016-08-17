#!/bin/bash -e
# Update the latest Spur image.
. ./envvars.sh

if false; then
	# old way; get Squeak 5.0 and update
. ./getsqueak50.sh

	if [ ! -f trunk50.image -o ! -f trunk50.changes ]; then
		cp -p "$SQUEAK50".changes trunk50.changes
		cp -p "$SQUEAK50".image trunk50.image
	fi
else
	# New way; download the latest trunk from squeak.org/downloads
	geturl http://build.squeak.org/job/Trunk/default/lastSuccessfulBuild/artifact/target/TrunkImage.zip
	unzip -ou TrunkImage.zip
	mv SpurTrunkImage.changes trunk50.changes
	mv SpurTrunkImage.image trunk50.image
	if test \! -f SqueakV50.sources ; then
		if test -f ../sources/SqueakV50.sources; then
			ln ../sources/SqueakV50.sources .
		else
			if test \! -f SqueakV50.sources.zip; then
				geturl http://ftp.squeak.org/5.0/SqueakV50.sources.zip
			fi
			unzip SqueakV50.sources.zip
		fi
	fi
fi

. ./getGoodSpurVM.sh

echo $VM trunk50.image UpdateSqueakTrunkImage.st
$VM trunk50.image UpdateSqueakTrunkImage.st
