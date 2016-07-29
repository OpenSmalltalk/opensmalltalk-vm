#!/bin/bash -e
# Edit the installed directory tree to rename squeak to nsvm and install source
INSTALLDIR="$1"
shift
cd $INSTALLDIR

if [ "$1" = -source ]; then
	SourceFile="$2"
	shift; shift
else
	SourceFile=SqueakV50
fi
SOURCE=../../sources/$SourceFile.sources
test -f $SOURCE || SOURCE=../../../sources/$SourceFile.sources
if [ -f squeak ]; then
	mv squeak nsvm
	sed -i.bak 's/squeak/nsvm/g' nsvm
fi
if [ -f bin/squeak ]; then
	mv bin/squeak bin/nsvm
	sed -i.bak 's/squeak/nsvm/g' bin/nsvm
fi
rm -rf man doc
LIBDIR="`echo lib/squeak/[0-9.-]*`"
test -f $LIBDIR/squeak && mv $LIBDIR/squeak $LIBDIR/nsvm
test -d lib/squeak && mv lib/squeak lib/nsvm
LIBDIR="`echo lib/nsvm/[0-9.-]*`"
if [ "$1" = -copysource ]; then
	cp $SOURCE $LIBDIR
elif [ -h $SOURCE ]; then
	ln "`readlink $SOURCE`" $LIBDIR
elif [ -f $SOURCE ]; then
	ln $SOURCE $LIBDIR
else
	echo "can't find `basename $SOURCE`" 1>&2
fi
