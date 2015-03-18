#!/bin/sh
. ./envvars.sh

if [ ! -f trunk46-spur.image -o ! -f trunk46-spur.changes ]; then
	./getlatestspurtrunkimage.sh
fi

./ensureSqueakV41sources.sh

cp -p trunk46-spur.image SpurVMMaker.image
cp -p trunk46-spur.changes SpurVMMaker.changes

. ./getGoodSpurVM.sh

echo $VM SpurVMMaker.image UpdateSqueakTrunkImage.st
$VM SpurVMMaker.image UpdateSqueakTrunkImage.st

echo $VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
$VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
