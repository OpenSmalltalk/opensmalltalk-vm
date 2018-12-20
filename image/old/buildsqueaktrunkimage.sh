#!/bin/sh -e
. ./envvars.sh
./getsqueak45.sh
. ./getGoodCogVM.sh

cp -p $SQUEAK45.image trunk46forspur.image
cp -p $SQUEAK45.changes trunk46forspur.changes

echo $VM trunk46forspur.image UpdateSqueakTrunkImage.st
$VM trunk46forspur.image UpdateSqueakTrunkImage.st

./resizesqueakwindow.sh trunk46forspur.image 800 600
