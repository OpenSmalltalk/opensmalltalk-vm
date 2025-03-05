#!/usr/bin/env bash
set -e
# Build a 32-bit Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

if test -n "$1"; then
	VM="$1"
else
. ./getGoodSpurVM.sh
fi

. ./updatespurimage.sh

./ensureSqueakV50sources.sh

# echo $0 3 $@

READER=spurreader

cp -p ${BASE}.image ${READER}.image
cp -p ${BASE}.changes ${READER}.changes

if [ "$1" = FFI ]; then
	echo $VM ${READER}.image -doit LoadFFI.st
	$VM ${READER}.image -doit LoadFFI.st
fi

echo $VM ${READER}.image -doit LoadReader.st
$VM ${READER}.image -doit LoadReader.st

echo $VM ${READER}.image -doit StartReader.st
$VM ${READER}.image -doit StartReader.st
