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
elif false; then
	# New way; download the latest trunk from squeak.org/downloads
	geturl http://files.squeak.org/base/Squeak-trunk/versions.txt
	source versions.txt
	geturl http://files.squeak.org/base/Squeak-trunk/base.zip
	unzip -ou base.zip
	mv "Squeak${VERSION_BASE_ZIP}.changes" trunk50.changes
	mv "Squeak${VERSION_BASE_ZIP}.image" trunk50.image
else
	# New new way; download from http://files.squeak.org/6.0alpha/Squeak6.0alpha-16548-32bit/
	geturl http://files.squeak.org/6.0alpha/Squeak6.0alpha-16548-32bit/Squeak6.0alpha-16548-32bit.zip
	unzip -ou Squeak6.0alpha-16548-32bit.zip
	mv Squeak6.0alpha-16548-32bit.changes trunk50.changes
	mv Squeak6.0alpha-16548-32bit.image trunk50.image
fi

if test \! -f SqueakV50.sources ; then
	if test -f ../sources/SqueakV50.sources; then
		ln ../sources/SqueakV50.sources .
	else
		if test \! -f SqueakV50.sources.gz; then
			geturl http://files.squeak.org/sources_files/SqueakV50.sources.gz
		fi
		gunzip SqueakV50.sources.gz
	fi
fi

. ./getGoodSpurVM.sh

echo $VM trunk50.image UpdateSqueakTrunkImage.st
$VM trunk50.image UpdateSqueakTrunkImage.st
