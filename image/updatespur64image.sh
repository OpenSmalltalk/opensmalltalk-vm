#!/usr/bin/env bash
set -e
# Update the latest 64-bit Spur image, or fetch the latest available and update that.
. ./envvars.sh

. ./getGoodSpur64VM.sh

if test \! -f SqueakV60.sources ; then
	if test -f ../sources/SqueakV60.sources; then
		ln ../sources/SqueakV60.sources .
	else
		if test \! -f SqueakV60.sources.gz; then
			echo downloading source file...
			geturl http://files.squeak.org/sources_files/SqueakV60.sources.gz
		fi
		gunzip SqueakV60.sources.gz
	fi
fi

if [ ! -f $BASE64.image ]; then
	. ./getlatesttrunk64image.sh
	echo $VM $BASE64.image NukePreferenceWizardMorph.st
	$VM $BASE64.image NukePreferenceWizardMorph.st
fi

echo $VM $BASE64.image UpdateSqueakTrunkImage.st
$VM $BASE64.image UpdateSqueakTrunkImage.st
