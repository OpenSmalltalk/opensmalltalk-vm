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

for productPath in "${PHARO_PRODUCTS_DIR}"/*.zip; do
	productName="$(basename "${productPath}")"
	echo "Uploading $productName to files.pharo.org/$destDir"
	scp $productPath files.pharo.org:$destDir/$productName
	if [[ "$HEARTBEAT" = "threaded" ]]; then 
		SUFFIX="-threaded"
	fi
	echo "Uploading $productName to files.pharo.org/$destDir/latest$SUFFIX.zip"
	scp $productPath files.pharo.org:$destDir/latest$SUFFIX.zip
done
