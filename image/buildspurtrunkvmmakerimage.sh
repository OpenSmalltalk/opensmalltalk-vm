#!/bin/bash -e
. ./envvars.sh

./updatespurimage.sh

cp -p trunk50.image SpurVMMaker.image
cp -p trunk50.changes SpurVMMaker.changes

. ./getGoodSpurVM.sh

echo $VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
$VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
