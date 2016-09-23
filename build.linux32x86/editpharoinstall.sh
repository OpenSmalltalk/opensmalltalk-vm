#!/bin/bash -e
# Edit the installed directory tree to rename squeak to pharo and install source
INSTALLDIR="$1"

shift
cd $INSTALLDIR

if [ "$1" = -source ]; then
	SourceFile="$2"
	shift; shift
else
	SourceFile="PharoV50"
fi
SOURCE=../../sources/$SourceFile.sources
test -f $SOURCE || SOURCE=../../../sources/$SourceFile.sources
if [ -f squeak ]; then
	mv squeak pharo
	sed -i.bak 's/squeak/pharo/g' pharo
fi
if [ -f bin/squeak ]; then
	mv bin/squeak bin/pharo
	sed -i.bak 's/squeak/pharo/g' bin/pharo
fi
rm -rf man doc
LIBDIR="`echo lib/squeak/[0-9.-]*`"
test -f $LIBDIR/squeak && mv $LIBDIR/squeak $LIBDIR/pharo
test -d lib/squeak && mv lib/squeak lib/pharo
LIBDIR="`echo lib/pharo/[0-9.-]*`"
if [ "$1" = -copysource ]; then
	cp $SOURCE $LIBDIR
elif [ -h $SOURCE ]; then
	ln "`readlink $SOURCE`" $LIBDIR
elif [ -f $SOURCE ]; then
	ln $SOURCE $LIBDIR
else
	echo "can't find `basename $SOURCE`" 1>&2
fi
