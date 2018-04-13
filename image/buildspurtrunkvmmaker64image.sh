#!/usr/bin/env bash
set -e
. ./envvars.sh

./updatespur64image.sh "$@"

cp -p $BASE64.image Spur64VMMaker.image
cp -p $BASE64.changes Spur64VMMaker.changes

. ./getGoodSpur64VM.sh

echo $VM Spur64VMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
$VM Spur64VMMaker.image BuildSqueakSpurTrunkVMMakerImage.st
