#!/usr/bin/env bash
set -e
# Build a 64-bit Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

if test -n "$1"; then
	VM="$1"
else
. ./getGoodSpurVM.sh
fi

. ./updatespur64image.sh

./ensureSqueakV50sources.sh

# echo $0 3 $@

cp -p ${BASE64}.image spurreader-64.image
cp -p ${BASE64}.changes spurreader-64.changes

if [ "$1" = FFI ]; then
	echo $VM spurreader-64.image LoadFFI.st
	$VM spurreader-64.image LoadFFI.st
fi

echo $VM spurreader-64.image LoadReader.st
$VM spurreader-64.image LoadReader.st

echo $VM spurreader-64.image StartReader.st
$VM spurreader-64.image StartReader.st
