#!/bin/sh
# Update the latest Spur image.
. ./envvars.sh

if [ ! -f trunk46-spur.image -o ! -f trunk46-spur.changes ]; then
	./getlatestspurtrunkimage.sh
fi

./ensureSqueakV41sources.sh

. ./getGoodSpurVM.sh

echo $VM trunk46-spur.image UpdateSqueakTrunkImage.st
$VM trunk46-spur.image UpdateSqueakTrunkImage.st
