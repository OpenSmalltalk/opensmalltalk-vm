#!/bin/bash -e
# Build a Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

./updatespurimage.sh

./ensureSqueakV50sources.sh

cp -p trunk50.image spurreader.image
cp -p trunk50.changes spurreader.changes

. ./getGoodSpurVM.sh

echo $VM spurreader.image LoadReader.st
$VM spurreader.image LoadReader.st

echo $VM spurreader.image StartReader.st
$VM spurreader.image StartReader.st
