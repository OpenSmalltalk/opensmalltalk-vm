#!/bin/bash -e

. ./envvars.sh

if [ "$1" = -vm -a -n "$2" -a -x "`which "$2"`" ]; then
	VM="$2"
else
	echo not yet implemented\; fetch VMs from bintray
cat <<END
For the moment, cd to the build directory for your platform (e.g.
../build.macos32x86/squeak.cog.spur) and build a squeak.cog.spur vm
there, using one of the provided scripts (see the HowToBuild in the
build directory).  In build.macosXXX/squeak.cog.spur use
	./mvm -A
to build the VMs.  Then repeat this command using
	$0 -vm theVMYouHaveJustBuilt
For the Mac that would be
	$0 -vm ../build.macos32x86/squeak.cog.spur/CocoaFast.app/Contents/MacOS/Squeak
END
	exit 1
fi
