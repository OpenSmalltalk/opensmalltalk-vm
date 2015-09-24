#!/bin/sh
# Update the latest Spur image.
. ./envvars.sh
. ./getsqueak50.sh

if [ ! -f trunk50.image -o ! -f trunk50.changes ]; then
	cp -p "$SQUEAK50".changes trunk50.changes
	cp -p "$SQUEAK50".image trunk50.image
fi

. ./getGoodSpurVM.sh

echo $VM trunk50.image UpdateSqueakTrunkImage.st
$VM trunk50.image UpdateSqueakTrunkImage.st
