#!/bin/bash
set -e

readonly PRODUCTS_DIR="$(pwd)/products"
if [[ ! -d "${PRODUCTS_DIR}" ]]; then
  echo "No products directory found."
  exit 10
fi
readonly REV=$(grep -m1 "SvnRawRevisionString" platforms/Cross/vm/sqSCCSVersion.h | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
readonly IDENTIFIER="cog_${ARCH}_${FLAVOR}_${REV}"
readonly KEY_CHAIN=macos-build.keychain

macos_codesign() {
  local cert_path=$1
  local cert_pass=$2
  local sign_identity=$3

  travis_fold start macos_signing "Signing app bundle..."
  # Set up keychain
  security create-keychain -p travis "${KEY_CHAIN}"
  security default-keychain -s "${KEY_CHAIN}"
  security unlock-keychain -p travis "${KEY_CHAIN}"
  security set-keychain-settings -t 3600 -u "${KEY_CHAIN}"
  security import "${cert_path}" -k ~/Library/Keychains/"${KEY_CHAIN}" -P "${cert_pass}" -T /usr/bin/codesign
  # Invoke codesign
  codesign -s "${sign_identity}" --force --deep ./*.app
  # Remove sensitive files again
  rm -rf "${cert_path}"
  security delete-keychain "${KEY_CHAIN}"
  travis_fold end macos_signing
}

pushd "${PRODUCTS_DIR}"
if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
  counter=0
  for dir in */; do
    if [[ "${dir}" == *"ht/" ]]; then
      name="${IDENTIFIER}"
    else
      name="${IDENTIFIER}_itimer"
    fi
    tar czf "${name}.tar.gz" "${dir}"
    counter=$((counter+1))
    if [[ "${counter}" -gt 2 ]]; then
      echo "No more than two directories expected (threaded and/or itimer)"
      exit 20
    fi
  done
elif [[ "${TRAVIS_OS_NAME}" == "osx" ]]; then
  readonly DEPLOY_DIR="${TRAVIS_BUILD_DIR}/deploy"
  if [[ "${FLAVOR}" == "squeak"* ]]; then
    openssl aes-256-cbc -k "${SQUEAK_SIGN_PASSWORD}" -in "${DEPLOY_DIR}/squeak/sign.enc" -out "${DEPLOY_DIR}/squeak/sign.p12" -d
    macos_codesign "${DEPLOY_DIR}/squeak/sign.p12" "${SQUEAK_CERT_PASSWORD}" "${SQUEAK_SIGN_IDENTITY}"
  elif [[ "${FLAVOR}" == "pharo"* ]]; then
    # TODO: decrypt Pharo signing certificate and invoke macos_codesign to sign app bundle
    # macos_codesign "${DEPLOY_DIR}/pharo/sign.p12" "${PHARO_CERT_PASSWORD}" "${PHARO_SIGN_IDENTITY}"
    true
  fi
  TMP_DMG="temp.dmg"
  hdiutil create -size 8m -volname "${IDENTIFIER}" -srcfolder "./"*.app \
      -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -nospotlight "${TMP_DMG}"
  DEVICE="$(hdiutil attach -readwrite -noautoopen -nobrowse "${TMP_DMG}" | awk 'NR==1{print$1}')"
  VOLUME="$(mount | grep "$DEVICE" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
  hdiutil detach "$DEVICE"
  hdiutil convert "${TMP_DMG}" -format UDBZ -imagekey bzip2-level=9 -o "${IDENTIFIER}.dmg"
  rm -f "${TMP_DMG}"
elif [[ "${APPVEYOR}" ]]; then
  rm -f *.def *.exp *.lib *.map *.o *.res *Unstripped* # remove temporary build files
  zip -r "${IDENTIFIER}.zip" "./"
else
  echo "Unsupported platform '$(uname -s)'." 1>&2
  exit 30
fi
popd
