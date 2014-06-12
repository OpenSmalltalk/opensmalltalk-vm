#!/bin/sh
. ./envvars.sh
./getsqueak45.sh
. ./get2897vm.sh

./getsqueak45.sh
. ./get2897vm.sh

cp -p $SQUEAK45.image trunk46forspur.image
cp -p $SQUEAK45.changes trunk46forspur.changes

rm -f temp-spur-repository/* temp-v3-repository/*
$VM trunk46forspur.image BuildSqueakTrunkImage.st
$VM trunk46forspur.image ChangeUpdateStreamToSpur.st
$VM trunk46forspur.image WriteSpurPackagesToTempDir.st

# Now choose a suitable VMMaker image (Spur preferred) and get it to convert
# trunk46forspur to Spur.
IMAGE=""
GOTIMAGE=""
while true; do
	for f in *VMMaker*spur.image; do
		if test -f "$f"; then
			IMAGE="$f"
.			./get2897spurvm.sh
			break 2
		fi
	done
	if [ -z "$IMAGE" ]; then
		for f in *VMMaker*.image; do
			if test -f "$f"; then
				IMAGE="$f"
.				./get2897vm.sh
				break 2
			fi
		done
	fi
	if [ -n "$GOTIMAGE" ]; then
		echo hmmm, failed to build a VMMaker image.  Bailing out
		exit 1
	fi
	if [ -z "$IMAGE" ]; then
		buildsqueaktrunkvmmakerimage.sh
		GOTIMAGE=1
	fi
done
$VM $IMAGE BuildSpurTrunkImage.st
mv trunk46forspur-spur.image trunk46-spur.image
mv trunk46forspur-spur.changes trunk46-spur.changes

# Now load the modified packages
. ./get2897spurvm.sh
$VM trunk46-spur.image LoadSpurPackagesFromTempDir.st
