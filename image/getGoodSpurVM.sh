#!/bin/bash -e

set +v

. ./envvars.sh

if [ "$1" = -vm -a -n "$2" -a -x "`which "$2"`" ]; then
	VM="$2"
else
	echo checking for latest VM on bintray...
	case $OS in
	Darwin) 
		LATESTVM="`curl -s -L "https://dl.bintray.com/opensmalltalk/vm/" | grep cog_macos32x86_squeak.cog.spur_ | tail -n 1 | sed 's/^.*">\(.*\)<.a><.pre>/\1/'`"
		# echo $LATESTVM
		TAG="`echo $LATESTVM | sed 's/.*_\(.*\).tar.gz/\1/'`"
		# echo $TAG
		VM=Squeak.$TAG.app
		if [ ! -d $VM ]; then
			echo Downloading $LATESTVM from bintray
			curl -L "https://dl.bintray.com/opensmalltalk/vm/$LATESTVM" -o "$LATESTVM"
			tar xzf "$LATESTVM"
			mv Squeak.app $VM
			rm -f "$LATESTVM"
		fi
		VM=$VM/Contents/MacOS/Squeak;;
	Linux) # This needs to be split by $CPU to work on RPi also
		LATESTVM="`curl -s -L "https://dl.bintray.com/opensmalltalk/vm/" | grep -v itimer | grep cog_linux32x86_squeak.cog.spur_ | tail -n 1 | sed 's/^.*">\(.*\)<.a><.pre>/\1/'`"
		#echo $LATESTVM
		TAG="`echo $LATESTVM | sed 's/.*_\(.*\).tar.gz/\1/'`"
		#echo $TAG
		VM=sqlinux.$TAG
		if [ ! -d $VM ]; then
			echo Downloading $LATESTVM from bintray
			curl -L "https://dl.bintray.com/opensmalltalk/vm/$LATESTVM" -o "$LATESTVM"
			tar xzf "$LATESTVM"
			mv sqcogspurlinuxht $VM
			rm -f "$LATESTVM"
		fi
		VM=$VM/squeak;;
	*)	echo do not know how to download a VM for your system 1>&2; exit 1
	esac
fi
echo latest VM is $VM
