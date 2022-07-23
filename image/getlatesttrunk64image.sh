#!/bin/bash
. ./envvars.sh
# curl flags -s silent -L follow redirects -o output
URL=http://files.squeak.org/trunk
LATEST=`curl -s -L $URL | tr "=" "\\012" | grep 'Squeak.*-64bit' | tail -1 | sed 's/"\(.*\)\/">.*$/\1/'`
echo curl -L -o $LATEST.zip $URL/$LATEST/$LATEST.zip
curl -L -o $LATEST.zip $URL/$LATEST/$LATEST.zip
unzip -n $LATEST.zip # i.e. don't overwrite SqueakV60.sources if included
mv $LATEST.image $BASE64.image
mv $LATEST.changes $BASE64.changes
