#!/bin/sh
. ./envvars.sh

./buildspurtrunkvmmakerimage.sh

. ./getGoodSpurVM.sh

echo $VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
$VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st

echo $VM SpurVMMaker.image BuildSpurTrunk64Image.st
$VM SpurVMMaker.image BuildSpurTrunk64Image.st
