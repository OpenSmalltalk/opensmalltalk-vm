#!/bin/sh
#
# Written by Anthony Lee 2007.03
#

printf "Checking bfd library ... "

case $CC in
	*gcc*)
		;;
	*)
		# other compiler, should be checked manually.
		printf "IGNORE\n"
		exit 0
		;;
esac

SRC="
#include <stdlib.h>
#include <bfd.h>
int main(int argc, char **argv)
{
	bfd *abfd = bfd_openr(NULL, NULL);
	return 0;
}
"

PROG="check-bfd"
OBJECT="${BINARY_DIR}${PROG}.o"
TARGET="${BINARY_DIR}${PROG}${SUFFIX}"
ERR_MESSAGE="*** It seems that you don't have bfd library.
*** Run \"make NO_BFD=1\" instead to ignore it."

if ! ( echo "$SRC" | $CC $EXTRA_CFLAGS -o "$OBJECT" -c -x c - > /dev/null 2>&1 ); then
	printf "FAILED\n\n"
	printf "$ERR_MESSAGE\n\n"
	exit 1
fi

if ! ( $CC -o "$TARGET" "$OBJECT" $BFD_LIBS $EXTRA_LIBS > /dev/null 2>&1 ); then
	printf "FAILED\n\n"
	printf "$ERR_MESSAGE\n\n"
	rm -f "$OBJECT"
	exit 1
fi

rm -f "$OBJECT"
rm -f "$TARGET"

printf "OK\n"

exit 0

