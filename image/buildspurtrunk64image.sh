#!/bin/bash -e
. ./envvars.sh

test -f SpurVMMaker.image || ./buildspurtrunkvmmakerimage.sh

. ./getGoodSpurVM.sh

./updatevmmakerimage.sh

echo $VM SpurVMMaker.image BuildSpurTrunk64Image.st
$VM SpurVMMaker.image BuildSpurTrunk64Image.st
