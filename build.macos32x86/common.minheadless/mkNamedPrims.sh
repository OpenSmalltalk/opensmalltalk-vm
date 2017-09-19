#!/bin/bash
# Generate a sqNamedPrims.h file from plugins.int.  The plugins.int used should
# be the one and only argument.
if [ $# != 1 -o ! -f "$1" ]; then
	echo usage $0 plugins.int \>sqNamedPrims.h 1>&2
	exit 1
fi
echo "/* Automatically generated on "`date`" */"
echo "extern sqExport vm_exports[];";
echo "extern sqExport os_exports[];";
for p in `grep -v '^#' "$1" | sed 's/INTERNAL_PLUGINS = //' | sed 's/ *\\\\//'`
do
	test -n "$p" && echo "extern sqExport "$p"_exports[];"
done
echo
echo "sqExport *pluginExports[] = {"
echo "	vm_exports,"
echo "	os_exports,"
for p in `grep -v '^#' "$1" | sed 's/INTERNAL_PLUGINS = //' | sed 's/ *\\\\//'`
do
	echo "	"$p"_exports,"
done
echo "	NULL"
echo "};"
