#!/usr/bin/env bash
set -e
# Build a Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

. ./updatespurimage.sh

./ensureSqueakV50sources.sh

echo $0 3 $@

cp -p ${BASE}.image spurreader.image
cp -p ${BASE}.changes spurreader.changes

if [ "$1" = FFI ]; then
	echo $VM spurreader.image -- LoadFFI.st
	$VM spurreader.image -- LoadFFI.st
fi

echo $VM spurreader.image -- LoadReader.st
$VM spurreader.image -- LoadReader.st

echo $VM spurreader.image -- StartReader.st
$VM spurreader.image -- StartReader.st
