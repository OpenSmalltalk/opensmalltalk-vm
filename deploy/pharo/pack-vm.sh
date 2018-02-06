#!/usr/bin/env bash

set -e

# This are defined elsewhere (usually in travis):
# 
# ARCH			- macos32x86, linux64x64, win32x86, etc.
# HEARTBEAT		- in case of linux vms (threaded, itimer)

readonly BUILD_DIR="${TRAVIS_BUILD_DIR:-${APPVEYOR_BUILD_FOLDER}}"
readonly PRODUCTS_DIR="${BUILD_DIR}/products"
readonly PHARO_PRODUCTS_DIR="${BUILD_DIR}/productsPharo"
mkdir "${PHARO_PRODUCTS_DIR}" || true # ensure directory exists

# revision date
BUILD_DATE="`grep -m1 "SvnRawRevisionString" ${BUILD_DIR}/platforms/Cross/vm/sqSCCSVersion.h | sed 's/[^0-9.]*\([0-9.]*\).*/\1/'`"
if [ -z "${BUILD_DATE}" ]; then 
	BUILD_DATE="NODATE"
fi
# revision id
if [[ "${APPVEYOR}" ]]; then
	COMMIT_SHA="${APPVEYOR_REPO_COMMIT}"
else
	COMMIT_SHA="${TRAVIS_COMMIT}"
fi
BUILD_ID="`echo ${COMMIT_SHA} | cut -b 1-7`"
if [ -z "${BUILD_ID}" ]; then 
	BUILD_ID="NOSHA" 
fi

# append a cog or stack suffix for WIN64 build
SUFFIX="`cat ${FLAVOR} | sed 's/^pharo\.//' | sed 's/\.spur$//'`"

do_pack_vm() {
	# function arguments 
	local os=$1
	local productArch=$2
	local productDir=$3
	local pattern=$4
	local suffix=$5
	# variables
	local filename=
	
	if [ ! -d "${PRODUCTS_DIR}${subdir}" ]; then
		echo "Error: ${PRODUCTS_DIR}${subdir} does not exist."
		exit 1
	fi
		
	filename="pharo-${os}-${productArch}${suffix}-${BUILD_DATE}-${BUILD_ID}.zip"
	pushd "${productDir}"
	zip -y -r "${PHARO_PRODUCTS_DIR}/${filename}" ${pattern}
	popd
}

do_copy_dmg() {
	# function arguments
	local productArch=$1
	# variables
	local filename=
	
	if [ ! -d "${PRODUCTS_DIR}" ]; then
		echo "Error: ${PRODUCTS_DIR} does not exist."
		exit 1
	fi
		
	filename="pharo-mac-${productArch}-${BUILD_DATE}-${BUILD_ID}.dmg"
	cp "${PRODUCTS_DIR}/"*.dmg "${PHARO_PRODUCTS_DIR}/${filename}"
}

case "${ARCH}" in
	macos32x86)
		do_pack_vm "mac" "i386" "${BUILD_DIR}/build.${ARCH}/pharo.cog.spur" "*.app"
		do_copy_dmg "i386"
		;;
	macos64x64)
		do_pack_vm "mac" "x86_64" "${BUILD_DIR}/build.${ARCH}/pharo.cog.spur" "*.app"
		do_copy_dmg "x86_64"
		;;
	linux32x86)
		do_pack_vm "linux" "i386" ""`ls -d ${BUILD_DIR}/products/*`"" "*" "${HEARTBEAT}"
		;;
	linux64x64)
		do_pack_vm "linux" "x86_64"  ""`ls -d ${BUILD_DIR}/products/*`"" "*" "${HEARTBEAT}"
		;;
	linux32ARMv6)
		do_pack_vm "linux" "ARMv6" "`ls -d ${BUILD_DIR}/products/*`" "*"
		;;
	win32x86)
		do_pack_vm "win" "i386" "${BUILD_DIR}/build.${ARCH}/${FLAVOR}/build/vm" "Pharo.exe PharoConsole.exe *.dll"
		;;
	win64x64)
		do_pack_vm "win" "x86_64" "${SUFFIX}" "${BUILD_DIR}/build.${ARCH}/${FLAVOR}/build/vm" "Pharo.exe PharoConsole.exe *.dll"
		;;
	*) 
		echo "Undefined platform!"
		exit 1
esac
