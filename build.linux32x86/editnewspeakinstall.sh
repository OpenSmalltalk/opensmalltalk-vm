#!/bin/bash
# Edit the installed directory tree to rename squeak to nsvm and install source
INSTALLDIR="$1"
cd $INSTALLDIR
SOURCE=../../sources/SqueakV41.sources
test -f $SOURCE || SOURCE=../../../sources/SqueakV41.sources
if [ -f squeak ]; then
	mv squeak nsvm
	ex -u NONE "+g/squeak/s/squeak/nsvm/g" +w +q nsvm
fi
if [ -f bin/squeak ]; then
	mv bin/squeak bin/nsvm
	ex -u NONE "+g/squeak/s/squeak/nsvm/g" "+/nsvm vm-dev/s//squeak vm-dev/" +w +q bin/nsvm
fi
rm -rf man doc
LIBDIR="`echo lib/squeak/[0-9.-]*`"
test -f $LIBDIR/squeak && mv $LIBDIR/squeak $LIBDIR/nsvm
test -d lib/squeak && mv lib/squeak lib/nsvm
LIBDIR="`echo lib/nsvm/[0-9.-]*`"
if [ "$2" = -copysource ]; then
	cp $SOURCE $LIBDIR
elif [ -h $SOURCE ]; then
	ln "`readlink $SOURCE`" $LIBDIR
elif [ -f $SOURCE ]; then
	ln $SOURCE $LIBDIR
else
	echo "can't find `basename $SOURCE`" 1>&2
fi
