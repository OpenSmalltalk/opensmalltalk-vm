#!/bin/bash
set -e

readonly REV_NEWSPEAK="7fed4bc928ac3fa85fa28493ca1e26c359f875ac"
readonly REV_NSBOOT="afc5b23866b518d926e300bca9efdf41b6e62fe0"
readonly GH_BASE="https://github.com/newspeaklanguage"
readonly TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'newspeak')

source ./.travis_helpers.sh

case "$(uname -s)" in
  "Linux"|"Darwin")
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

case "$(uname -s)" in
  "Linux")
    NSVM=$(find "${TRAVIS_BUILD_DIR}/products" -type f -path "*/bin/nsvm" | head -n 1)
    ;;
  "Darwin")
    VM_BUILD_DIR="${TRAVIS_BUILD_DIR}/build.${ARCH}/${FLAVOR}"
    NSVM="${VM_BUILD_DIR}/CocoaFast.app/Contents/MacOS/Newspeak Virtual Machine"
    ;;
esac

if [[ ! -f "${NSVM}" ]]; then
  echo "Could not locate VM."
  exit 1
fi

"${BUILD_SCRIPT}" -t -u -v "${NSVM}"

popd > /dev/null

travis_fold end ns_bootstrap

