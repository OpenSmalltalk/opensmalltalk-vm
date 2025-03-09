#!/usr/bin/env bash
set -e
# Update the latest Spur image.
. ./envvars.sh

if [ ! -f Spur64VMMaker.image ]; then
	echo no Spur64VMMaker.image to update\; $0 bailing out
	exit 0
fi

. ./getGoodSpur64VM.sh

echo $VM Spur64VMMaker.image UpdateSqueakTrunkImage.st
$VM Spur64VMMaker.image UpdateSqueakTrunkImage.st

echo $VM Spur64VMMaker.image UpdateVMMakerImage.st
$VM Spur64VMMaker.image UpdateVMMakerImage.st
