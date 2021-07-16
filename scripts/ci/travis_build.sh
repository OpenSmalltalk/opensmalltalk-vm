#!/bin/bash
set -e

source ./scripts/ci/travis_helpers.sh

if [[ "${APPVEYOR}" ]]; then
    TRAVIS_BUILD_DIR="$(pwd)"
    TRAVIS_TAG="${APPVEYOR_REPO_TAG}"
    PLATFORM="windows"

    # Appveyor's GCC is pretty new, patch the Makefiles and replace the tools to
    # make it work

    echo
    echo "Using gcc $(i686-w64-mingw32-gcc --version)"
    echo "Using 64-bit gcc $(x86_64-w64-mingw32-gcc --version)"
    echo
    test -d /usr/i686-w64-mingw32/sys-root/mingw/lib || echo "No lib dir"
    test -d /usr/i686-w64-mingw32/sys-root/mingw/include || echo "No inc dir"
else
    PLATFORM="${TRAVIS_OS_NAME}"
fi

[[ -z "${ARCH}" ]] && exit 2
[[ -z "${FLAVOR}" ]] && exit 3

if [[ "${ARCH}" == "linux32ARM"* ]]; then
    # we're in chroot at this point
    export LC_ALL=C
    export LC_CTYPE=C
    export LANG=C
    export LANGUAGE=C
    TRAVIS_BUILD_DIR="$(pwd)"
fi

echo "$(cat platforms/Cross/vm/sqSCCSVersion.h | .git_filters/RevDateURL.smudge)" > platforms/Cross/vm/sqSCCSVersion.h
echo "$(cat platforms/Cross/plugins/sqPluginsSCCSVersion.h | .git_filters/RevDateURL.smudge)" > platforms/Cross/plugins/sqPluginsSCCSVersion.h

# echo $PATH
if [[ "${BUILD_WITH_CMAKE}" == "yes" ]]; then
    [[ -z "${CPU_ARCH}" ]] && exit 2
    PLATFORM="minheadless_with_cmake"
    BUILD_DIRECTORY="$(pwd)/building/minheadless.cmake/${CPU_ARCH}/${FLAVOR}";
else
    BUILD_DIRECTORY="$(pwd)/building/${ARCH}/${FLAVOR}";
fi
readonly BUILD_DIRECTORY
readonly PRODUCTS_DIR="$(pwd)/products"
mkdir "${PRODUCTS_DIR}" || true # ensure PRODUCTS_DIR exists

export COGVREV="$(git describe --tags --always)"
export COGVDATE="$(git show -s --format=%cd HEAD)"
export COGVURL="$(git config --get remote.origin.url)"
export COGVOPTS="-DCOGVREV=\"${COGVREV}\" -DCOGVDATE=\"${COGVDATE// /_}\" -DCOGVURL=\"${COGVURL//\//\\\/}\""

build_linux_in() {
    local build_dir=$1
    local fold_name=$2

    [[ ! -d "${build_dir}" ]] && exit 10

    pushd "${build_dir}"
    travis_fold start "${fold_name}" "Building OpenSmalltalk VM in ${build_dir}..."
    echo n | bash -e ./mvm
    travis_fold end "${fold_name}"
    # cat config.log
    popd
}

build_linux() {
    travis_fold start 'unix_configure' 'Running "make config" in platforms/unix/config ...'
    (cd platforms/unix/config/ && make configure)
    travis_fold end 'unix_configure'

	# build will include both, threaded and itimer version unless
	# HEARTBEAT variable is set, in which case just one of both
	# will be built.
	# HEARTBEAT can be "threaded" or "itimer"

	if [ -z "$HEARTBEAT" ] || [ "$HEARTBEAT" = "threaded" ]; then
    	build_linux_in "${BUILD_DIRECTORY}/build" "build_vm"
	fi

    # Also build VM with itimerheartbeat if available
    if [[ ! -d "${BUILD_DIRECTORY}/build.itimerheartbeat" ]]; then
    	return
    fi

    if [ -z "$HEARTBEAT" ] || [ "$HEARTBEAT" = "itimer" ]; then
        build_linux_in "${BUILD_DIRECTORY}/build.itimerheartbeat" "build_itimer_vm"
    fi
}

build_osx() {
    [[ ! -d "${BUILD_DIRECTORY}" ]] && exit 50

    pushd "${BUILD_DIRECTORY}"

    travis_fold start build_vm "Building OpenSmalltalk VM..."
    bash -e ./mvm -f
    travis_fold end build_vm

    mv ./*.app "${PRODUCTS_DIR}/" # Move app to PRODUCTS_DIR
    popd
}

build_windows() {
    [[ ! -d "${BUILD_DIRECTORY}" ]] && exit 100

    pushd "${BUILD_DIRECTORY}"
    echo "Removing bochs plugins..."
    sed -i 's/Bochs.* //g' plugins.ext

    echo "Building OpenSmalltalk VM for Windows..."
    # We cannot zip dbg and ast if we pass -f to just to the full thing...
    # Once this builds, let's pass -A instead of -f and put the full zip (but we should do several zips in the future)
    bash -e ./mvm -f || exit 1
    # zip -r "${output_file}.zip" "./builddbg/vm/" "./buildast/vm/" "./build/vm/"
    mv "./build/vm" "${PRODUCTS_DIR}/" # Move result to PRODUCTS_DIR
    popd
}

build_minheadless_with_cmake() {
    [[ ! -d "${BUILD_DIRECTORY}" ]] && exit 150

    local vm_variant_name="${FLAVOR}_minheadless-cmake_${ARCH}"

    pushd "${BUILD_DIRECTORY}"
    travis_fold start build_vm "Building OpenSmalltalk VM..."
    bash -e ./mvm -f || exit 1
    mv ./release/install-dist/* "${PRODUCTS_DIR}/"
    travis_fold end build_vm
    popd

}

if [[ ! $(type -t build_$PLATFORM) ]]; then
    echo "Unsupported platform '$(uname -s)'." 1>&2
    exit 99
fi

build_$PLATFORM
