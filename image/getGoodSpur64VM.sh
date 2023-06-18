#!/usr/bin/env bash
set -e
set +v

. ./envvars.sh

RELEASES_URL="https://github.com/OpenSmalltalk/opensmalltalk-vm/releases"
LATEST_RELEASE_URL="$RELEASES_URL/latest"

for foo in once; do # allow break to jump to end of script

if [ "$1" = -vm -a -n "$2" -a -x "`which "$2"`" ]; then
	VM="$2"
	shift;shift
else
	LATESTFILE=.LATEST.$OS.$CPU # holds release number of latest downloaded release
	case $OS in
	Darwin) 
		case $CPU in
		arm64) VOLUME="squeak.cog.spur_macos64ARMv8";;
		x86_64) VOLUME="squeak.cog.spur_macos64x64";;
		*)		echo "Don't know what kind of macos machine you're running.  I have $CPU" 1>&2
				echo "If you've built your own VM you can substitute that using the -vm myvm argument to this script." 1>&2
				exit 1
		esac
		LATESTVM="$VOLUME.dmg"
		VMDIR=Squeak.app
		VM=$VMDIR/Contents/MacOS/Squeak;;
	Linux)
		case $CPU in
		x86_64)	LATESTVM="squeak.cog.spur_linux64x64.tar.gz";;
		aarch64)	LATESTVM="squeak.cog.spur_linux64ARMv8.tar.gz";;
		*)		echo "Don't know what kind of 64-bit linux machine you're running.  I have $CPU" 1>&2
				echo "If you've built your own VM you can substitute that using the -vm myvm argument to this script." 1>&2
				exit 1
		esac
		VMDIR=sqcogspur64linuxht
		VM=$VMDIR/squeak;;
	*)	echo do not know how to download a VM for your system 1>&2
		echo "If you've built your own VM you can substitute that using the -vm myvm argument to this script." 1>&2
		exit 1
	esac
	echo checking for latest 64-bit VM on $LATEST_RELEASE_URL
	curl -s -L "$LATEST_RELEASE_URL" >.LATEST.html
	RELEASE="`grep '<title>Release [0-9][0-9]* .*</title' .LATEST.html | sed 's/^.*Release \([0-9][0-9]*\) .*$/\1/'`"
	if [ -z "$RELEASE" ]; then
		echo "cannot find latest release on $LATEST_RELEASE_URL" 1>&2
		echo "If you've built your own VM you can substitute that using the -vm myvm argument to this script." 1>&2
		exit 1
	fi
	if [ -f $LATESTFILE -a "`cat $LATESTFILE`" = $RELEASE -a -x $VM ]; then
		echo latest 64-bit VM on $OS for $CPU is $VM
		test "$1" = "-verbose" && $VM -version
		break
	fi
	DOWNLOAD_URL="$RELEASES_URL/download/${RELEASE}/${LATESTVM}"
	echo $DOWNLOAD_URL
	echo Downloading $LATESTVM from $DOWNLOAD_URL
	if [ "$1" = -test ]; then
		test -n "$VOLUME" && echo "VOLUME=$VOLUME"
		echo "VMDIR=$VMDIR"
		echo "VM=$VM"
		echo "LATESTVM=$LATESTVM"
		echo "DOWNLOAD_URL=$DOWNLOAD_URL"
		echo curl -L "$DOWNLOAD_URL" -o "$LATESTVM"
		exit
	fi
	curl -L "$DOWNLOAD_URL" -o "$LATESTVM"
	case $OS in
	Darwin) 
		if open $LATESTVM; then
			while [ ! -d "/Volumes/$VOLUME/$VMDIR" ]; do sleep 1; done
			rm -rf $VMDIR
			cp -Rp "/Volumes/$VOLUME/$VMDIR" $VMDIR
			diskutil eject "/Volumes/$VOLUME"
		fi;;
	Linux)
		if [[ $(file "$LATESTVM" | grep 'gzip compressed data') ]]; then 
		  tar xzf "$LATESTVM"
		else
		  echo No gzip data at "$DOWNLOAD_URL"
		  exit 1
		fi;;
	esac
fi
echo latest 64-bit VM on $OS for $CPU is $VM
test "$1" = "-verbose" && $VM -version
echo $RELEASE >$LATESTFILE
if [ "$1" = -vmargs ]; then
	VM="$VM $2"
	shift;shift
fi
done
