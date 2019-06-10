#!/bin/bash
set -e

readonly STON_CONFIG="${TRAVIS_BUILD_DIR}/tests/smalltalk.ston"

if [[ "${TESTIMAGE}" = "" ]]; then
  echo "Error: TESTIMAGE is not defined!"
  exit 1
fi

case "${FLAVOR}" in
  "squeak"*)
    LINUX_BINARY="squeak"
    MACOS_BINARY="Squeak"
    ;;
  "Xpharo"*) # disabled until pharo-vm is merged
    LINUX_BINARY="pharo"
    MACOS_BINARY="Pharo"
    ;;
  *)
    echo "Skipping SUnit testing for unknown flavor ${FLAVOR}..."
    exit 0
    ;;
esac

case "$(uname -s)" in
  "Linux")
    BINARY_PATH="*/bin/${LINUX_BINARY}"
    ;;
  "Darwin")
    BINARY_PATH="*/Contents/MacOS/${MACOS_BINARY}"
    ;;
esac

VM=$(find "${TRAVIS_BUILD_DIR}/products" -type f -path "${BINARY_PATH}" | head -n 1)

if [[ ! -f "${VM}" ]]; then
  echo "Could not locate VM."
  exit 1
fi

echo "Starting SUnit testing..."

wget -q -O "smalltalkCI.zip" "https://github.com/hpi-swa/smalltalkCI/archive/master.zip"

unzip -q -o smalltalkCI.zip

pushd smalltalkCI-* > /dev/null

"./run.sh" -s "${TESTIMAGE}" --vm "${VM}"  "${STON_CONFIG}"

popd > /dev/null
