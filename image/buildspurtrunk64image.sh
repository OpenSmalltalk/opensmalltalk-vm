#!/bin/sh
. ./envvars.sh

test -f SpurVMMaker.image || ./buildspurtrunkvmmakerimage.sh

. ./getGoodSpurVM.sh

echo $VM SpurVMMaker.image BuildSpurTrunk64Image.st
$VM SpurVMMaker.image BuildSpurTrunk64Image.st
