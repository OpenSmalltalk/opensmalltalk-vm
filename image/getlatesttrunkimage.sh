#!/bin/bash
. ./envvars.sh
# curl flags -s silent -L follow redirects -o output
URL=http://files.squeak.org/current_stable
LATEST=`curl -s -L $URL | tr "=" "\\012" | grep 'Squeak.*-32bit' | tail -1 | sed 's/"\(.*\)\/">.*$/\1/'`
echo curl -L -o $LATEST.zip $URL/$LATEST/$LATEST.zip
curl -L -o $LATEST.zip $URL/$LATEST/$LATEST.zip
unzip $LATEST.zip
mv $LATEST.image $BASE.image
mv $LATEST.changes $BASE.changes
