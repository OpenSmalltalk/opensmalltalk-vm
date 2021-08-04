#!/bin/bash
set -e

# This script locates and executes the platform and flavor-specific
# build scripts, which are typically Makefile-based, to compile and
# link the configured VM flavor. It then copies the build artifacts to
# to the ./products directory for subsequent steps such as signing and
# packing and deploying.
#
# This script uses/requires to following variables:
# - ARCH (e.g., "macos64x64")
# - ARCH_ARM (only set for ARM builds in docker container)
# - FLAVOR (e.g., "squeak.cog.spur")
# - RUNNER_OS (i.e., "Linux", "macOS", "Windows")
# - HEARTBEAT (i.e., "threaded" or "itimer"; !! Linux only !!)
#
# This script provides variables for subsequent steps:
# - ASSET_REVISION (e.g., "202107261048")
# - ASSET_NAME (e.g., "squeak.cog.spur_macos64x64")
# - PRODUCTS_PATH (e.g., "products")
# - APP_NAME (e.g., "vm" or "sqcogspur64linuxht" or "Squeak.app")



if [[ "${RUNNER_OS}" == "Windows" ]]; then
    source ./scripts/ci/actions_prepare_msys.sh
fi

echo "$(cat platforms/Cross/vm/sqSCCSVersion.h | .git_filters/RevDateURL.smudge)" > platforms/Cross/vm/sqSCCSVersion.h
echo "$(cat platforms/Cross/plugins/sqPluginsSCCSVersion.h | .git_filters/RevDateURL.smudge)" > platforms/Cross/plugins/sqPluginsSCCSVersion.h

[[ -z "${ARCH}" ]] && exit 2
[[ -z "${FLAVOR}" ]] && exit 3

readonly ASSET_REVISION=$(grep -m1 "SvnRawRevisionString" "platforms/Cross/vm/sqSCCSVersion.h" | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')

ASSET_NAME="${FLAVOR}_${ARCH}"
BUILD_PATH="$(pwd)/build.${ARCH}/${FLAVOR}"

PRODUCTS_PATH="$(pwd)/products"
mkdir "${PRODUCTS_PATH}" || true # ensure PRODUCTS_PATH exists

check_buildPath() {
    if [[ ! -d "${BUILD_PATH}" ]]; then
        echo "Build path does not exist: ${BUILD_PATH}"
        exit 11
    fi 
}

skip_BochsPlugins() {
    echo "Skipping Bochs plugins..."
    sed -i 's/Bochs.* //g' plugins.ext
    sed -i 's/Bochs.* //g' plugins.int
}

export_variable() {
    local var_name=$1
    local var_value=$2
    if [[ ! -z "${ARCH_ARM}" ]]; then
        # We are in a docker container. See https://github.com/uraimo/run-on-arch-action
        echo "::set-output name=${var_name}::${var_value}"
    else
        echo "${var_name}=${var_value}" >> $GITHUB_ENV
    fi
}

# export COGVREV="$(git describe --tags --always)"
# export COGVDATE="$(git show -s --format=%cd HEAD)"
# export COGVURL="$(git config --get remote.origin.url)"
# export COGVOPTS="-DCOGVREV=\"${COGVREV}\" -DCOGVDATE=\"${COGVDATE// /_}\" -DCOGVURL=\"${COGVURL//\//\\\/}\""

build_Linux() {
    echo '::group::Running "make configure" in platforms/unix/config ...'
    (cd platforms/unix/config/ && make configure)
    echo '::endgroup::'

    BUILD_PATH="${BUILD_PATH}/build"
    if [[ "${MODE}" == "debug" ]]; then
        BUILD_PATH="${BUILD_PATH}.debug"
        PRODUCTS_PATH="${PRODUCTS_PATH}/debug"
    elif [[ "${MODE}" == "assert" ]]; then
        BUILD_PATH="${BUILD_PATH}.assert"
        PRODUCTS_PATH="${PRODUCTS_PATH}/assert"
    fi

    if [[ ! -z "$HEARTBEAT" ]] && [[ "${HEARTBEAT}" != "threaded" ]]; then
        BUILD_PATH="${BUILD_PATH}.itimerheartbeat"
        ASSET_NAME="${ASSET_NAME}_itimer"
    fi

    pushd "${BUILD_PATH}"

    echo "::group::Building ${BUILD_PATH}..."
    echo n | bash -e ./mvm || exit 1
    echo "::endgroup::"

    cd "${PRODUCTS_PATH}"
    readonly APP_NAME=$(find * -type d | head -n 1)

    popd
}

build_macOS() {
    check_buildPath

    pushd "${BUILD_PATH}"

    echo "::group::Building ${BUILD_PATH}..."
    if [[ "${MODE}" == "debug" ]]; then
        bash -e ./mvm -d || exit 1
    elif [[ "${MODE}" == "assert" ]]; then
        bash -e ./mvm -a || exit 1
    else
        bash -e ./mvm -f || exit 1
    fi
    echo "::endgroup::"

    echo "::group::Moving build artifacts to ${PRODUCTS_PATH}..."
    if [[ "${FLAVOR}" == "newspeak"* ]]; then
        # TODO: Why does the Newspeak flavor have to wrong name? Should be set in its build scripts (or Makefile ...)
        mv ./*.app "${PRODUCTS_PATH}/Newspeak.app"
    else
        mv ./*.app "${PRODUCTS_PATH}/"
    fi
    echo "::endgroup::"

    cd "${PRODUCTS_PATH}"
    readonly APP_NAME=$(find * -type d -path "*.app" | head -n 1)

    popd
}

build_Windows() {
    check_buildPath
    pushd "${BUILD_PATH}"

    echo "::group::Building ${BUILD_PATH}..."
    skip_BochsPlugins
    if [[ "${MODE}" == "debug" ]]; then
        bash -e ./mvm -d || exit 1
    elif [[ "${MODE}" == "assert" ]]; then
        bash -e ./mvm -a || exit 1
    else
        bash -e ./mvm -f || exit 1
    fi
    echo "::endgroup::"

    echo "::group::Moving build artifacts to ${PRODUCTS_PATH}..."
    if [[ "${MODE}" == "debug" ]]; then
        mv "./builddbg/vm" "${PRODUCTS_PATH}/"
    elif [[ "${MODE}" == "assert" ]]; then
        mv "./buildast/vm" "${PRODUCTS_PATH}/"
    else
        mv "./build/vm" "${PRODUCTS_PATH}/"
    fi
    echo "::endgroup::"

    readonly APP_NAME="vm"

    popd
}

if [[ ! $(type -t build_$RUNNER_OS) ]]; then
    echo "Unsupported runner OS ${RUNNER_OS}."
    exit 99
fi

build_$RUNNER_OS

if [[ "${MODE}" == "debug" ]]; then
    ASSET_NAME="${ASSET_NAME}_debug"
elif [[ "${MODE}" == "assert" ]]; then
    ASSET_NAME="${ASSET_NAME}_assert"
fi

export_variable "ASSET_REVISION" "${ASSET_REVISION}"
export_variable "ASSET_NAME" "${ASSET_NAME}"

[[ ! -d "${PRODUCTS_PATH}" ]] && exit 13
export_variable "PRODUCTS_PATH" "${PRODUCTS_PATH}"
[[ ! -d "${PRODUCTS_PATH}/${APP_NAME}" ]] && exit 14
export_variable "APP_NAME" "${APP_NAME}"
