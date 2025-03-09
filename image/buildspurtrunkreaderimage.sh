#!/usr/bin/env bash
set -e
# Build a 32-bit Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

. ./getGoodSpurVM.sh

. ./updatespurimage.sh

./ensureSqueakV50sources.sh

# echo $0 3 $@

READER=spurreader

cp -p ${BASE}.image ${READER}.image
cp -p ${BASE}.changes ${READER}.changes

if [ "$1" = FFI ]; then
	echo $VM ${READER}.image LoadFFI.st
	$VM ${READER}.image LoadFFI.st
fi

echo $VM ${READER}.image LoadReader.st
$VM ${READER}.image LoadReader.st

echo $VM ${READER}.image StartReader.st
$VM ${READER}.image StartReader.st
