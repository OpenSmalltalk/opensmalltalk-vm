#!/bin/bash
set -e

readonly REV_NEWSPEAK="afebb7f0a5774e8aed06369be8aa2012d6a0cc07"
readonly REV_NSBOOT="41f3615f4d79cb0e0d1e7aecc865fedca21e8a15"
readonly GH_BASE="https://github.com/newspeaklanguage"
readonly TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'newspeak')

source ./scripts/ci/travis_helpers.sh

case "$(uname -s)" in
  "Linux")
    BINARY_PATH="*/bin/nsvm"
    ;;
  "Darwin")
    BINARY_PATH="*/Contents/MacOS/Newspeak Virtual Machine"
    ;;
  *)
    echo "Skipping Newspeak bootstrapping process..."
    exit
    ;;
esac

travis_fold start ns_bootstrap "Starting Newspeak bootstrapping process.."

pushd "${TMP_DIR}" > /dev/null

curl -f -s -L --retry 3 -o "newspeak.zip" "${GH_BASE}/newspeak/archive/${REV_NEWSPEAK}.zip"
curl -f -s -L --retry 3 -o "nsboot.zip" "${GH_BASE}/nsboot/archive/${REV_NSBOOT}.zip"

unzip -q "newspeak.zip"
unzip -q "nsboot.zip"

mv "newspeak-${REV_NEWSPEAK}" "newspeak"
mv "nsboot-${REV_NSBOOT}" "nsboot"

cd "nsboot"

if [[ "${ARCH}" = *"64x64" ]]; then
  BUILD_SCRIPT="./build64.sh"
else
  BUILD_SCRIPT="./build32.sh"
fi

NSVM=$(find "${TRAVIS_BUILD_DIR}/products" -type f -path "${BINARY_PATH}" | head -n 1)

if [[ ! -f "${NSVM}" ]]; then
  echo "Could not locate Newspeak VM."
  exit 1
fi

"${BUILD_SCRIPT}" -t -u -v "${NSVM}"

popd > /dev/null

travis_fold end ns_bootstrap

