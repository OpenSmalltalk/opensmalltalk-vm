#!/bin/bash
set -e

readonly BUILD_DIR="${TRAVIS_BUILD_DIR:-$(cygpath ${APPVEYOR_BUILD_FOLDER})}"
readonly PRODUCTS_DIR="${BUILD_DIR}/products"
if [[ ! -d "${PRODUCTS_DIR}" ]]; then
  echo "No products directory found."
  exit 10
fi
readonly REV=$(grep -m1 "SvnRawRevisionString" "${BUILD_DIR}/platforms/Cross/vm/sqSCCSVersion.h" | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
readonly IDENTIFIER="${FLAVOR}_${ARCH}_${REV}"
readonly IDENTIFIER_ITIMER="${FLAVOR}_${ARCH}_itimer_${REV}"
readonly KEY_CHAIN=macos-build.keychain

macos_codesign() {
  local app_dir=$1
  local path_cer=$2
  local path_p12=$3
  local cert_pass=$4
  local sign_identity=$5

  echo "Signing app bundle..."
  # Set up keychain
  security create-keychain -p travis "${KEY_CHAIN}"
  security default-keychain -s "${KEY_CHAIN}"
  security unlock-keychain -p travis "${KEY_CHAIN}"
  security set-keychain-settings -t 3600 -u "${KEY_CHAIN}"
  security import "${path_cer}" -k ~/Library/Keychains/"${KEY_CHAIN}" -T /usr/bin/codesign
  security import "${path_p12}" -k ~/Library/Keychains/"${KEY_CHAIN}" -P "${cert_pass}" -T /usr/bin/codesign
  # Invoke codesign
  if [[ -d "${app_dir}/Contents/MacOS/Plugins" ]]; then # Pharo.app does not (yet) have its plugins in Resources dir
    codesign -s "${sign_identity}" --force --deep "${app_dir}/Contents/MacOS/Plugins/"*
  fi
  codesign -s "${sign_identity}" --force --deep "${app_dir}"
  # Remove sensitive files again
  rm -rf "${path_cer}" "${path_p12}"
  security delete-keychain "${KEY_CHAIN}"
}

pushd "${PRODUCTS_DIR}"
if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
  counter=0
  for dir in */; do
    if [[ "${ARCH}" == *"ARM"* || "${dir}" == *"ht/" ]]; then
      name="${IDENTIFIER}"
    else
      name="${IDENTIFIER_ITIMER}"
    fi
    tar czf "${name}.tar.gz" "${dir}"
    counter=$((counter+1))
    if [[ "${counter}" -gt 2 ]]; then
      echo "No more than two directories expected (threaded and/or itimer)"
      exit 20
    fi
  done
elif [[ "${TRAVIS_OS_NAME}" == "osx" ]]; then
  APP_DIR=$(find "${PRODUCTS_DIR}" -type d -path "*.app" | head -n 1)
  if [[ -z "${APP_DIR}" ]]; then
    echo "Unable to locate app bundle."
    exit 30
  fi
  readonly DEPLOY_DIR="${TRAVIS_BUILD_DIR}/deploy"
  if [[ "${FLAVOR}" == "squeak"* ]]; then
    path_cer="${DEPLOY_DIR}/squeak/sign.cer"
    path_p12="${DEPLOY_DIR}/squeak/sign.p12"
    openssl aes-256-cbc -k "${SQUEAK_SIGN_PASSWORD}" -in "${path_cer}.enc" -out "${path_cer}" -d
    openssl aes-256-cbc -k "${SQUEAK_SIGN_PASSWORD}" -in "${path_p12}.enc" -out "${path_p12}" -d
    macos_codesign "${APP_DIR}" "${path_cer}" "${path_p12}" "${SQUEAK_CERT_PASSWORD}" "${SQUEAK_SIGN_IDENTITY}"
  elif [[ "${FLAVOR}" == "pharo"* ]]; then
    path_cer="${DEPLOY_DIR}/pharo/pharo.cer"
    path_p12="${DEPLOY_DIR}/pharo/pharo.p12"
    openssl aes-256-cbc -k "${PHARO_SIGN_PASSWORD}" -in "${path_cer}.enc" -out "${path_cer}" -d
    openssl aes-256-cbc -k "${PHARO_SIGN_PASSWORD}" -in "${path_p12}.enc" -out "${path_p12}" -d
    macos_codesign "${APP_DIR}" "${path_cer}" "${path_p12}" "${PHARO_CERT_PASSWORD}" "${PHARO_SIGN_IDENTITY}"
  elif [[ "${FLAVOR}" == "newspeak"* ]]; then
    NEW_APP_DIR="${PRODUCTS_DIR}/Newspeak.app"
    mv "${APP_DIR}" "${NEW_APP_DIR}"
    APP_DIR="${NEW_APP_DIR}"
    path_cer="${DEPLOY_DIR}/newspeak/sign.cer"
    path_p12="${DEPLOY_DIR}/newspeak/sign.p12"
    openssl aes-256-cbc -k "${NEWSPEAK_SIGN_PASSWORD}" -in "${path_cer}.enc" -out "${path_cer}" -d
    openssl aes-256-cbc -k "${NEWSPEAK_SIGN_PASSWORD}" -in "${path_p12}.enc" -out "${path_p12}" -d
    macos_codesign "${APP_DIR}" "${path_cer}" "${path_p12}" "${NEWSPEAK_CERT_PASSWORD}" "${NEWSPEAK_SIGN_IDENTITY}"
  fi
  TMP_DMG="temp.dmg"
  hdiutil create -size 64m -volname "${IDENTIFIER}" -srcfolder "${APP_DIR}" \
      -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -nospotlight "${TMP_DMG}"
  DEVICE="$(hdiutil attach -readwrite -noautoopen -nobrowse "${TMP_DMG}" | awk 'NR==1{print$1}')"
  VOLUME="$(mount | grep "$DEVICE" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
  hdiutil detach "$DEVICE"
  hdiutil convert "${TMP_DMG}" -format UDBZ -imagekey bzip2-level=9 -o "${IDENTIFIER}.dmg"
  rm -f "${TMP_DMG}"
elif [[ "${APPVEYOR}" ]]; then
  cd "./vm"
  rm -f *.def *.exp *.lib *.map *.o *.res *Unstripped* # remove temporary build files
  zip -r "${PRODUCTS_DIR}/${IDENTIFIER}.zip" "./"
else
  echo "Unsupported platform '$(uname -s)'." 1>&2
  exit 90
fi
popd
