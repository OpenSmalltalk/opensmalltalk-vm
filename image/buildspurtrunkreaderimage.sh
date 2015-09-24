#!/bin/sh
# Build a Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

if [ ! -f trunk50.image -o ! -f trunk50.changes ]; then
	./updatespurimage.sh
fi

./ensureSqueakV50sources.sh

cp -p trunk50.image spurreader.image
cp -p trunk50.changes spurreader.changes

. ./getGoodSpurVM.sh

echo $VM spurreader.image LoadReader.st
$VM spurreader.image LoadReader.st

echo $VM spurreader.image StartReader.st
$VM spurreader.image StartReader.st
