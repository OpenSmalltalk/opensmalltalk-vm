#!/bin/bash
. ./envvars.sh

geturl http://www.mirandabanda.org/files/Cog/SpurImages/trunk46-spur.image
geturl http://www.mirandabanda.org/files/Cog/SpurImages/trunk46-spur.changes
geturl http://www.mirandabanda.org/files/Cog/SpurImages/trunk46-spur.sum

cksum trunk46-spur.changes trunk46-spur.image | diff - trunk46-spur.sum >/dev/null && ls -l trunk46-spur.image trunk46-spur.changes || echo image and/or changes have wrong checksum 1>&2
