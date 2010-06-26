#!/bin/sh
#
# Written by Anthony Lee 2007.03
#

printf "Checking whether the compiler supports x86 asm ... "

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
int main(int argc, char **argv)
{
	int i = 1;
	__asm__ (\" \
		pushl %%eax\n \
		movl %0, %%eax\n \
		subl \$1, %%eax\n \
		movl %%eax, %0\n \
		popl %%eax\" \
		: \
		: \"g\" (i)
	);
	return i;
}"

PROG="check-x86-asm"
OBJECT="${BINARY_DIR}${PROG}.o"
TARGET="${BINARY_DIR}${PROG}${SUFFIX}"
ERR_MESSAGE="*** It seems that the compiler don't support inline x86 AT&T ASM codes.
*** Run \"make NO_DBCT=1\" instead to ignore it."

if ! ( echo "$SRC" | $CC $EXTRA_CFLAGS -o "$OBJECT" -c -x c - > /dev/null 2>&1 ); then
	printf "FAILED\n\n"
	printf "$ERR_MESSAGE\n\n"
	exit 1
fi

if ! ( $CC -o "$TARGET" "$OBJECT" $EXTRA_LIBS > /dev/null 2>&1 ); then
	printf "FAILED\n\n"
	printf "$ERR_MESSAGE\n\n"
	rm -f "$OBJECT"
	exit 1
fi

rm -f "$OBJECT"
rm -f "$TARGET"

printf "OK\n"

exit 0

