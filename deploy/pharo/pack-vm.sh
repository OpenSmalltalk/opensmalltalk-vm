#!/usr/bin/env bash

set -ex

# This are defined elsewhere (usually in travis):
# 
# ARCH			- macos32x86, linux64x64, win32x86, etc.
# HEARTBEAT		- in case of linux vms (threaded, itimer)

# ROOT_DIR this file is in "./deploy/pharo, I need to reach root. I could use env vars of travos and 
# appvetor, but that would mean deal with Windows paths :)"
ROOT_DIR="`pwd`/../.."
# revision date
BUILD_DATE="`grep -m1 "SvnRawRevisionString" ${ROOT_DIR}/platforms/Cross/vm/sqSCCSVersion.h | sed 's/[^0-9.]*\([0-9.]*\).*/\1/'`"
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
	local zipFileName=
	
	if [ -z "${productDir}" ]; then
		echo "Error: Product not found!"
		exit 1
	fi
		
	zipFileName="${ROOT_DIR}/pharo-${os}-${productArch}${suffix}-${BUILD_DATE}-${BUILD_ID}.zip"
	pushd .
	cd ${productDir}
	zip -y -r ${zipFileName} ${pattern}
	popd
}

case "${ARCH}" in
	macos32x86) 
		do_pack_vm "mac" "i386" "${ROOT_DIR}/build.${ARCH}/pharo.cog.spur" "*.app"
		;;
	macos64x64) 
		do_pack_vm "mac" "x86_64" "${ROOT_DIR}/build.${ARCH}/pharo.cog.spur" "*.app"
		;;
	linux32x86) 
		do_pack_vm "linux" "i386" "`ls -d ${ROOT_DIR}/products/*`" "*" "${HEARTBEAT}"
		;;
	linux64x64) 
		do_pack_vm "linux" "x86_64" "`ls -d ${ROOT_DIR}/products/*`" "*" "${HEARTBEAT}"
		;;
	linux32ARMv6) 
		do_pack_vm "linux" "ARMv6" "`ls -d ${ROOT_DIR}/products/*`" "*"
		;;
	win32x86) 
		do_pack_vm "win" "i386" "${ROOT_DIR}/build.${ARCH}/pharo.cog.spur/build/vm" "Pharo.exe PharoConsole.exe *.dll"
		;;
	win64x64)
		do_pack_vm "win" "x86_64" "${ROOT_DIR}/build.${ARCH}/pharo.cog.spur/build/vm" "Pharo.exe PharoConsole.exe *.dll" "stack"
		;;
	*) 
		echo "Undefined platform!"
		exit 1
esac