#!/bin/bash -e
# Update the latest Spur image.
. ./envvars.sh

if [ ! -f SpurVMMaker.image ]; then
	echo no SpurVMMaker.image to update\; $0 bailing out
	exit 0
fi

. ./getGoodSpurVM.sh

echo $VM SpurVMMaker.image UpdateSqueakTrunkImage.st
$VM SpurVMMaker.image UpdateSqueakTrunkImage.st
