#!/bin/bash
for i in `find ./ -name "*.c"` 
do
	sed '/TRACE/d' $i > temp
	cp temp $i
done
