#!/bin/sh
. ./envvars.sh
./getsqueak50.sh
. ./getGoodSpurVM.sh

echo $VM -blockonerror trunk50.image LoadSpurPackages.st
$VM -blockonerror trunk50.image LoadSpurPackages.st

./resizesqueakwindow.sh trunk50.image 800 600
