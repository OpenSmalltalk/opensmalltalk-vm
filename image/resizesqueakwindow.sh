#!/bin/bash -e
if [ $# -ne 3 ]; then
	echo "Usage: `basename $0` <image> <width> <height>"
	exit 1
fi
echo -ne \\x$(printf "%02X" $[$3%256])\\x$(printf "%02X" $[$3/256])\\x$(printf "%02X" $[$2%256])\\x$(printf "%02X" $[$2/256]) \
| dd of="$1" obs=1 seek=24 conv=block,notrunc cbs=4
