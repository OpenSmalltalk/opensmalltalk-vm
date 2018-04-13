#!/usr/bin/env bash
set -e
. ./envvars.sh

./updatespurimage.sh "$@"

cp -p $BASE.image SpurVMMaker.image
cp -p $BASE.changes SpurVMMaker.changes

. ./getGoodSpurVM.sh

echo $VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
$VM SpurVMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
