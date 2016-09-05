#!/bin/bash -e
# Build a Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

./updatespurimage.sh

./ensureSqueakV50sources.sh

cp -p trunk50.image sistareader.image
cp -p trunk50.changes sistareader.changes

if test -n "$1"; then
	VM="$1"
else
. ./getGoodSpurVM.sh
fi

echo $VM sistareader.image LoadSistaSupport.st
$VM sistareader.image LoadSistaSupport.st

echo $VM sistareader.image LoadReader.st
$VM sistareader.image LoadReader.st

echo $VM sistareader.image StartReader.st
$VM sistareader.image StartReader.st
