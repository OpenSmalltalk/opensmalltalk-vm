#!/usr/bin/env bash
set -e
# Update the latest Spur image, or fetch the latest available and update that.
. ./envvars.sh

. ./getGoodSpur64VM.sh

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

if [ ! -f $BASESISTA64.image ]; then
	. ./getlatesttrunk64image.sh
	cp -p $BASE64.image $BASESISTA64.image
	cp -p $BASE64.changes $BASESISTA64.changes
	echo $VM $BASESISTA64.image NukePreferenceWizardMorph.st
	$VM $BASESISTA64.image NukePreferenceWizardMorph.st
	echo $VM $BASESISTA64.image SaveAsSista.st
	$VM $BASESISTA64.image SaveAsSista.st
# Needed a second time cuz ReleaseBuilder (used in SaveAsSista) sets it up
	echo $VM $BASESISTA64.image NukePreferenceWizardMorph.st
	$VM $BASESISTA64.image NukePreferenceWizardMorph.st
fi

echo $VM $BASESISTA64.image UpdateSqueakTrunkImage.st
$VM $BASESISTA64.image UpdateSqueakTrunkImage.st
