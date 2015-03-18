#!/bin/sh
# Build a Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

if [ ! -f trunk46-spur.image -o ! -f trunk46-spur.changes ]; then
	./getlatestspurtrunkimage.sh
fi

./ensureSqueakV41sources.sh

cp -p trunk46-spur.image spurreader.image
cp -p trunk46-spur.changes spurreader.changes

. ./getGoodSpurVM.sh

echo $VM spurreader.image LoadReader.st
$VM spurreader.image LoadReader.st

echo $VM spurreader.image StartReader.st
$VM spurreader.image StartReader.st
