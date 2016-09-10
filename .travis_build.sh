#!/bin/bash
set -e

travis_fold() {
  local action=$1
  local name=$2
  local title="${3:-}"

  if [[ "${TRAVIS:-}" = "true" ]]; then
    echo -en "travis_fold:${action}:${name}\r\033[0K"
  fi
  if [[ -n "${title}" ]]; then
    echo -e "\033[34;1m${title}\033[0m"
  fi
}

if [[ "${APPVEYOR}" ]]; then
    ARCH="win32x86"
    TRAVIS_BUILD_DIR="$(pwd)"
    TRAVIS_TAG="${APPVEYOR_REPO_TAG}"
    PLATFORM="Windows"

    # Appveyor's GCC is pretty new, patch the Makefiles and replace the tools to
    # make it work

    echo
    echo "Using gcc $(i686-w64-mingw32-gcc --version)"
    echo
    test -d /usr/i686-w64-mingw32/sys-root/mingw/lib || echo "No lib dir"
    test -d /usr/i686-w64-mingw32/sys-root/mingw/include || echo "No inc dir"

else
    PLATFORM="$(uname -s)"
fi

[[ -z "${ARCH}" ]] && exit 2
[[ -z "${FLAVOR}" ]] && exit 3

if [[ "${ARCH}" == "linux32ARM"* ]]; then
    # we're in  chroot at this point
    export LC_ALL=C
    export LC_CTYPE=C
    export LANG=C
    export LANGUAGE=C
    TRAVIS_BUILD_DIR="$(pwd)"
fi

echo "`cat platforms/Cross/vm/sqSCCSVersion.h | .git_filters/RevDateURL.smudge`" > platforms/Cross/vm/sqSCCSVersion.h
echo "`cat platforms/Cross/plugins/sqPluginsSCCSVersion.h | .git_filters/RevDateURL.smudge`" > platforms/Cross/plugins/sqPluginsSCCSVersion.h

REV=$(grep -m1 "SvnRawRevisionString" platforms/Cross/vm/sqSCCSVersion.h | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')

echo $PATH

output_file="${TRAVIS_BUILD_DIR}/cog_${ARCH}_${FLAVOR}_${REV}"

export COGVREV="$(git describe --tags --always)"
export COGVDATE="$(git show -s --format=%cd HEAD)"
export COGVURL="$(git config --get remote.origin.url)"
export COGVOPTS="-DCOGVREV=\"${COGVREV}\" -DCOGVDATE=\"${COGVDATE// /_}\" -DCOGVURL=\"${COGVURL//\//\\\/}\""

case "$PLATFORM" in
  "Linux")
    build_directory="./build.${ARCH}/${FLAVOR}/build"

    [[ ! -d "${build_directory}" ]] && exit 10

    pushd "${build_directory}"

    travis_fold start build_vm "Building OpenSmalltalk VM..."
    echo n | bash -e ./mvm
    travis_fold end build_vm

    # cat config.log
    popd

    output_file="${output_file}.tar.gz"
    tar czf "${output_file}" "./products"
    ;;
  "Darwin")
    build_directory="./build.${ARCH}/${FLAVOR}"

    [[ ! -d "${build_directory}" ]] && exit 50

    pushd "${build_directory}"

    travis_fold start build_vm "Building OpenSmalltalk VM..."
    bash -e ./mvm -f
    travis_fold end build_vm

    output_file="${output_file}.tar.gz"
    tar czf "${output_file}" ./*.app
    popd
    ;;
  "Windows")
    build_directory="./build.${ARCH}/${FLAVOR}/"
    output_zip="${output_file}.zip"

    [[ ! -d "${build_directory}" ]] && exit 100

    pushd "${build_directory}"
    # remove bochs plugins
    sed -i 's/Bochs.* //g' plugins.ext
    bash -e ./mvm -f || exit 1
    zip -r "${output_zip}" "./builddbg/vm/" "./buildast/vm/" "./build/vm/"
    popd
    ;;
  *)
    echo "Unsupported platform '${os_name}'." 1>&2
    exit 99
    ;;
esac
