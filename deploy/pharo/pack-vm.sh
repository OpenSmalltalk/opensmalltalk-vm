#!/usr/bin/env bash

set -e

# This are defined elsewhere (usually in travis):
# 
# ARCH			- macos32x86, linux64x64, win32x86, etc.
# HEARTBEAT		- in case of linux vms (threaded, itimer)

readonly BUILD_DIR="${TRAVIS_BUILD_DIR:-$(cygpath ${APPVEYOR_BUILD_FOLDER})}"
readonly PRODUCTS_DIR="${BUILD_DIR}/products"
readonly PHARO_PRODUCTS_DIR="${BUILD_DIR}/productsPharo"
mkdir "${PHARO_PRODUCTS_DIR}" || true # ensure directory exists

# Adding sista- prefix to sista VMs
if [[ "${FLAVOR}" = "pharo.sista.spur" ]]; then
	SISTA_PREFIX="sista-"
else
	SISTA_PREFIX=""
fi

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
		
	filename="${SISTA_PREFIX}pharo-${os}-${productArch}${suffix}-${BUILD_DATE}-${BUILD_ID}.zip"
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
		
	filename="${SISTA_PREFIX}pharo-mac-${productArch}-${BUILD_DATE}-${BUILD_ID}.dmg"
	cp "${PRODUCTS_DIR}/"*.dmg "${PHARO_PRODUCTS_DIR}/${filename}"
}

case "${ARCH}" in
	macos32x86)
		do_pack_vm "mac" "i386" "${PRODUCTS_DIR}" "*.app"
		do_copy_dmg "i386"
		;;
	macos64x64)
		do_pack_vm "mac" "x86_64" "${PRODUCTS_DIR}" "*.app"
		do_copy_dmg "x86_64"
		;;
	linux*)
		archName="unknown"
		case "${ARCH}" in
			linux32x86)
				archName="i386"
				;;
			linux64x64)
				archName="x86_64"
				;;
			linux32ARMv6)
				archName="ARMv6"
				;;
		esac
		VM_SUBDIR="$(find "${PRODUCTS_DIR}" -type d -mindepth 1 -maxdepth 1 | head -n 1)"
		do_pack_vm "linux" "${archName}" "${VM_SUBDIR}" "*" "${HEARTBEAT}"
		;;
	win32x86)
		do_pack_vm "win" "i386" "${PRODUCTS_DIR}/vm" "Pharo.exe PharoConsole.exe *.dll"
		;;
	win64x64)
		do_pack_vm "win" "x86_64" "${PRODUCTS_DIR}/vm" "Pharo.exe PharoConsole.exe *.dll"
		;;
	*) 
		echo "Undefined platform!"
		exit 1
esac
