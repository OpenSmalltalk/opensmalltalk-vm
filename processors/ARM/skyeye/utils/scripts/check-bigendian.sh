#!/bin/sh
#
# Written by Anthony Lee 2007.03
#

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
static unsigned int data[] = {0x42696745, 0x6e646961, 0x6e537973};

int main(int argc, char **argv)
{
	unsigned int v = 0x12345678;
	unsigned char *s = (unsigned char*)&v;

	exit((s[0] == 0x12 && s[1] == 0x34 && s[2] == 0x56 && s[3] == 0x78) ? 0 : 1);
}"

PROG="check-bigendian"
OBJECT="${BINARY_DIR}${PROG}.o"
TARGET="${BINARY_DIR}${PROG}${SUFFIX}"

if ! ( echo "$SRC" | $CC -o "$OBJECT" -c -x c - > /dev/null 2>&1 ); then
	printf "FAILED (compiling object)"
	exit 1
fi

if test "x$CROSS_COMPILE" = "x"; then
	if ! ( $CC -o "$TARGET" "$OBJECT" > /dev/null 2>&1 ); then
		rm -f "$OBJECT"
		printf "FAILED (compiling program)"
		exit 1
	fi

	if ! ( "$TARGET" > /dev/null 2>&1 ); then
		rm -f "$OBJECT"
		rm -f "$TARGET"
		printf "no\n"
		exit 1
	fi
elif ! ( grep "BigEndianSys" "$OBJECT" > /dev/null 2>&1 ); then
	rm -f "$OBJECT"
	rm -f "$TARGET"
	printf "no\n"
	exit 1
fi

rm -f "$OBJECT"
rm -f "$TARGET"

printf "yes\n"

exit 0

