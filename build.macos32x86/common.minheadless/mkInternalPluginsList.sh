#!/bin/bash
# Generate a sqInternalPlugins.inc file from plugins.int.  The plugins.int used should
# be the one and only argument.
if [ $# != 1 -o ! -f "$1" ]; then
	echo usage $0 plugins.int \>sqNamedPrims.h 1>&2
	exit 1
fi
for p in `grep -v '^#' "$1" | sed 's/INTERNAL_PLUGINS = //' | sed 's/ *\\\\//'`
do
	test -n "$p" && echo "INTERNAL_PLUGIN("$p")"
done
