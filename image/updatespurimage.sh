#!/usr/bin/env bash
set -e
# Update the latest Spur image, or fetch the latest available and update that.
. ./envvars.sh

. ./getGoodSpurVM.sh

if test \! -f SqueakV50.sources ; then
	if test -f ../sources/SqueakV50.sources; then
		ln ../sources/SqueakV50.sources .
	else
		if test \! -f SqueakV50.sources.gz; then
			echo downloading source file...
			geturl http://files.squeak.org/sources_files/SqueakV50.sources.gz
		fi
		gunzip SqueakV50.sources.gz
	fi
fi

if [ ! -f $BASE.image ]; then
	. ./getlatesttrunkimage.sh
	echo $VM $BASE.image NukePreferenceWizardMorph.st
	$VM $BASE.image NukePreferenceWizardMorph.st
fi

echo $VM $BASE.image UpdateSqueakTrunkImage.st
$VM $BASE.image UpdateSqueakTrunkImage.st
