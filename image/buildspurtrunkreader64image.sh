#!/usr/bin/env bash
set -e
# Build a 64-bit Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

. ./getGoodSpur64VM.sh

. ./updatespur64image.sh

./ensureSqueakV50sources.sh

# echo $0 3 $@

READER=spurreader-64

cp -p ${BASE64}.image ${READER}.image
cp -p ${BASE64}.changes ${READER}.changes

if [ "$1" = FFI ]; then
	shift
	echo $VM ${READER}.image LoadFFI.st
	$VM ${READER}.image LoadFFI.st
fi

if [ "$1" = VMProfiler ]; then
	shift
	echo $VM ${READER}.image LoadVMProfiler.st
	$VM ${READER}.image LoadVMProfiler.st
fi

echo $VM ${READER}.image LoadReader.st
$VM ${READER}.image LoadReader.st

echo $VM ${READER}.image StartReader.st
$VM ${READER}.image StartReader.st
