#!/bin/bash
# Generate a set of defines from plugins.int that defines each plugin name
# as its index in the sequence of internal plugins.  The plugins.int used
# should be the one and only argument.
if [ $# != 1 -o ! -f "$1" ]; then
	echo usage $0 plugins.int \>internalPluginIndices.h 1>&2
	exit 1
fi
echo "/* Automatically generated on "`date`" */"
i=0
for p in `grep -v '^#' "$1" | sed 's/[EI][A-Z]*TERNAL_PLUGINS = //' | sed 's/ *\\\\//'`
do
	if [ -n "$p" ]; then
		i=$(($i + 1))
		echo "#define $p " $i
	fi
done
echo
case $1 in
*plugins.int) echo "#define NumberOfInternalPlugins " $i;;
*plugins.ext) echo "#define NumberOfExternalPlugins " $i
esac
