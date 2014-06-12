#!/bin/bash
. ./envvars.sh
./getsqueak45.sh
. ./get2897vm.sh

cp -p $SQUEAK45.image CogVMMaker.image
cp -p $SQUEAK45.changes CogVMMaker.changes

if [ "$OS" = Linux -a "$CPU" = x86_64 ]; then
	echo Running 32-bit Squeak on a 64-bit System. Hope the 32-bit runtime libraries are installed ... 
fi

exec "$VM" CogVMMaker.image BuildSqueakTrunkVMMakerImage.st
