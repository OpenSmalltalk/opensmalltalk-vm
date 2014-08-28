#!/bin/sh
. ./envvars.sh

if [ ! -f trunk46-spur.image -o ! -f trunk46-spur.changes ]; then
	./buildspurtrunkimage.sh
fi
cp -p trunk46-spur.image SpurVMMaker.image
cp -p trunk46-spur.changes SpurVMMaker.changes

. ./getGoodSpurVM.sh

echo $VM SpurVMMaker.image BuildSqueak45VMMakerImage.st
$VM SpurVMMaker.image BuildSqueak45VMMakerImage.st
