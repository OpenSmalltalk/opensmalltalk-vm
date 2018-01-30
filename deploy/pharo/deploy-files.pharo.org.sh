#! /bin/bash
set -e 

baseDir="/homez.141/pharoorgde/files/vm"
case "${ARCH}" in
	macos32x86)
		destDir="$baseDir/pharo-spur32/mac" 
		;;
	macos64x64) 
		destDir="$baseDir/pharo-spur64/mac" 
		;;
	linux32x86) 
		destDir="$baseDir/pharo-spur32/linux" 
		;;
	linux64x64) 
		destDir="$baseDir/pharo-spur64/linux" 
		;;
	linux32ARMv6) 
		destDir="$baseDir/pharo-spur32/linux/armv6"
		;;
	win32x86) 
		destDir="$baseDir/pharo-spur32/win"
		;;
	win64x64) 
		destDir="$baseDir/pharo-spur64/win"
		;;
	*) 
		echo "Undefined platform!"
		exit 1
esac

readonly BUILD_DIR="${TRAVIS_BUILD_DIR:-${APPVEYOR_BUILD_FOLDER}}"
readonly PHARO_PRODUCTS_DIR="${BUILD_DIR}/productsPharo"

do_upload() {
	# function arguments
	local extension=$1
	for productName in "${PHARO_PRODUCTS_DIR}"/*.${extension}; do
		echo "Uploading $productName to files.pharo.org/$destDir"
		scp $productName files.pharo.org:$destDir/$productName
		if [[ "$HEARTBEAT" = "threaded" ]]; then 
			SUFFIX="-threaded"
		fi
		echo "Uploading $productName to files.pharo.org/$destDir/latest$SUFFIX.${extension}"
		scp $productName files.pharo.org:$destDir/latest$SUFFIX.${extension}
	done
}

do_upload "zip"
do_upload "dmg"