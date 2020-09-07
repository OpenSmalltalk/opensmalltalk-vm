#!/usr/bin/env bash
set -e
# Edit the installed directory tree to rename squeak to pharo and install source
OSVMROOTDIR=$(cd ../../..; pwd)

INSTALLDIR="$1"
shift
cd $INSTALLDIR

if [ -f squeak ]; then
	mv squeak pharo
	sed -i 's/squeak/pharo/g' pharo
fi
if [ -f bin/squeak ]; then
	mv bin/squeak bin/pharo
	sed -i 's/squeak/pharo/g' bin/pharo
fi
rm -rf man doc
LIBDIR="`echo lib/squeak/[0-9.-]*`"
test -f $LIBDIR/squeak && mv $LIBDIR/squeak $LIBDIR/pharo
test -d lib/squeak && mv lib/squeak lib/pharo

