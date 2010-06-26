#/bin/sh
cd "$1"
skyeye_path="$2"

if test "x$OSTYPE" == "xmsys" || test "x$TERM" == "xcygwin"; then
	SKYEYE="${skyeye_path}/skyeye.exe"
else
	SKYEYE="${skyeye_path}/skyeye"
fi

test -e linux && "$SKYEYE" -e linux -c skyeye.conf
test -e vmlinux && "$SKYEYE" -e vmlinux -c skyeye.conf
test -e vmlinux.large && "$SKYEYE" -e  vmlinux.large -c skyeye.conf 
test -e vmlinux-8-332 && "$SKYEYE" -e  vmlinux-8-332 -c skyeye.conf

