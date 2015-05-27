#!/bin/sh
. ./envvars.sh

./updatespurimage.sh

cp -p trunk46-spur.image SpurVMMaker.image
cp -p trunk46-spur.changes SpurVMMaker.changes

echo $VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
$VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
