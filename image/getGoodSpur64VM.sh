#!/usr/bin/env bash
set -e

set +v

. ./envvars.sh

if [ "$1" = -vm -a -n "$2" -a -x "`which "$2"`" ]; then
	VM="$2"
else
	echo checking for latest 64-bit VM on bintray...
	LATESTRELEASE=`curl -s -L "https://bintray.com/opensmalltalk/notifications" | grep 'has released version' | head -1 | sed 's/^.*[0-9]">\([0-9][0-9]*\).*$/\1/'`
	if [ -z "$LATESTRELEASE" ]; then
		echo "cannot find latest release on https://bintray.com/opensmalltalk/notifications" 1>&2
		exit 1
	fi
	case $OS in
	Darwin) 
		VOLUME="squeak.cog.spur_macos64x64_$LATESTRELEASE"
		LATESTVM="$VOLUME.dmg"
		VM=Squeak64.$LATESTRELEASE.app
		if [ ! -d $VM ]; then
			URL="https://dl.bintray.com/opensmalltalk/vm/$LATESTVM"
			echo Downloading $LATESTVM from $URL
			if [ "$1" = -test ]; then
				echo curl -L "$URL" -o "$LATESTVM"
				exit
			fi
			curl -L "$URL" -o "$LATESTVM"
			open $LATESTVM
			while [ ! -d "/Volumes/$VOLUME/Squeak.app" ]; do sleep 1; done
			rm -rf $VM
			cp -Rp "/Volumes/$VOLUME/Squeak.app" $VM
			eject "/Volumes/$VOLUME"
		fi
		VM=$VM/Contents/MacOS/Squeak;;
	Linux) # This needs to be split by $CPU to work on RPi also
		case $CPU in
		x86_64)	LATESTVM="squeak.cog.spur_linux64x64_$LATESTRELEASE.tar.gz";;
		*)		echo "Don't know what kind of 64-bit linux machine you're running.  I have $CPU"
				exit 1
		esac
		VM=sqlinux.$LATESTRELEASE
		if [ ! -d $VM ]; then
			echo Downloading $LATESTVM from bintray
			URL="https://dl.bintray.com/opensmalltalk/vm/$LATESTVM"
			if [ "$1" = -test ]; then
				echo curl -L "$URL" -o "$LATESTVM"
				exit
			fi
			curl -L "$URL" -o "$LATESTVM"
			tar xzf "$LATESTVM"
			mv sqcogspur64linuxht $VM
			rm -f "$LATESTVM"
		fi
		VM=$VM/squeak;;
	*)	echo do not know how to download a VM for your system 1>&2; exit 1
	esac
fi
echo latest 64-bit VM on $OS is $VM
