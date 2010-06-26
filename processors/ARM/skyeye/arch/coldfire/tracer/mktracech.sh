#!/bin/sh
# Arg 1: Directory to start search in
#  We always output to current directory

outfile="generated.channels.h"

echo "/* We define TRACER_DECLARE(ch) so we can use this list more than once */" > $outfile

find $1 -name \*.c -exec cat {} \; \
	| grep TRACER_DEFAULT_CHANNEL\
	| sed -e "s/TRACER_DEFAULT_CHANNEL/TRACER_DECLARE/"\
	| sed -e "s/;.*$//" | sort | uniq >> $outfile
