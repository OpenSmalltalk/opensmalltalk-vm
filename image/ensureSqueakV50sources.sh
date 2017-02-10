#!/bin/bash -e
. ./envvars.sh
test -f SqueakV50.sources && exit 0
if [ -f ../sources/SqueakV50.sources ]; then
	ln ../sources/SqueakV50.sources .
	exit 0
fi
geturl http://files.squeak.org/sources_files/SqueakV50.sources.gz
gunzip SqueakV50.sources
