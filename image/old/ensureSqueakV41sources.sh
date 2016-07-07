#!/bin/bash -e
. ./envvars.sh
test -f SqueakV41.sources && exit 0
if [ -f ../sources/SqueakV41.sources ]; then
	ln ../sources/SqueakV41.sources .
	exit 0
fi
geturl http://ftp.squeak.org/sources_files/SqueakV41.sources.gz
gunzip SqueakV41.sources
