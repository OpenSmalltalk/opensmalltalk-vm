#!/usr/bin/env bash
set -e
# Build a Spur image that starts up in a simple REPL, which is
# really useful for VMMaker simulation testing.
. ./envvars.sh

. ./updatespur64SistaV1image.sh

cp -p $BASESISTA64.image trunksista64reader.image
cp -p $BASESISTA64.changes trunksista64reader.changes

echo $VM trunksista64reader.image LoadFFI.st
$VM trunksista64reader.image LoadFFI.st

echo $VM trunksista64reader.image LoadReader.st
$VM trunksista64reader.image LoadReader.st

echo $VM trunksista64reader.image StartReader.st
$VM trunksista64reader.image StartReader.st
