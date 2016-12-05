#!/bin/bash
set -e

readonly STON_CONFIG="${TRAVIS_BUILD_DIR}/tests/smalltalk.ston"

if [[ "${ARCH}" = *"64x64" ]]; then
  echo "Skipping SUnit testing on ${ARCH}..."
  exit 0
fi

case "${FLAVOR}" in
  "squeak"*)
    if [[ "${FLAVOR}" = *".spur" ]]; then
      SMALLTALK_VERSION="Squeak-5.1"
    else
      SMALLTALK_VERSION="Squeak-4.6"
    fi
    LINUX_BINARY="squeak"
    MACOS_BUNDLE="CocoaFast"
    MACOS_BINARY="Squeak"
    ;;
  "Xpharo"*) # disabled until pharo-vm is merged
    if [[ "${FLAVOR}" = *".spur" ]]; then
      SMALLTALK_VERSION="Pharo-5.0"
    else
      SMALLTALK_VERSION="Pharo-5.0"
    fi
    LINUX_BINARY="pharo"
    MACOS_BUNDLE="Pharo"
    MACOS_BINARY="Pharo"
    ;;
  *)
    echo "Skipping SUnit testing for ${FLAVOR}..."
    exit 0
    ;;
esac

case "$(uname -s)" in
  "Linux")
    VM=$(find "${TRAVIS_BUILD_DIR}/products" -type f -name "${LINUX_BINARY}" | head -n 1)
    ;;
  "Darwin")
    VM_BUILD_DIR="${TRAVIS_BUILD_DIR}/build.${ARCH}/${FLAVOR}"
    VM="${VM_BUILD_DIR}/${MACOS_BUNDLE}.app/Contents/MacOS/${MACOS_BINARY}"
    ;;
esac

if [[ ! -f "${VM}" ]]; then
  echo "Could not locate VM."
  exit 1
fi

echo "Starting SUnit testing..."

wget -q -O "smalltalkCI.zip" "https://github.com/hpi-swa/smalltalkCI/archive/master.zip"

unzip -q -o smalltalkCI.zip

pushd smalltalkCI-* > /dev/null

"./run.sh" -s "${SMALLTALK_VERSION}" --vm "${VM}" "${STON_CONFIG}"

popd > /dev/null
