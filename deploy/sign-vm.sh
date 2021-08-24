#!/bin/bash
# Uses:
# - PRODUCTS_PATH
# - APP_NAME
# - *_SIGN_PASSWORD (secret)
# - *_CERT_PASSWORD (secret)
# - *_SIGN_IDENTITY (secret)
set -e

[[ ! -d "${PRODUCTS_PATH}/${APP_NAME}" ]] && exit 30

readonly APP_PATH="${PRODUCTS_PATH}/${APP_NAME}"
readonly KEY_CHAIN=macos-build.keychain

sign_Linux() {
  echo "Not implemented."
  exit 999
}

sign_macOS() {
  local -r cert_path="deploy"
  
  if [[ "${FLAVOR}" == "squeak"* ]]; then
    cert_filepath_cer="${cert_path}/squeak/sign.cer"
    cert_filepath_p12="${cert_path}/squeak/sign.p12"
    sign_password="${SQUEAK_SIGN_PASSWORD}"
    cert_password="${SQUEAK_CERT_PASSWORD}"
    sign_identity="${SQUEAK_SIGN_IDENTITY}"
  elif [[ "${FLAVOR}" == "pharo"* ]]; then
    cert_filepath_cer="${cert_path}/pharo/pharo.cer"
    cert_filepath_p12="${cert_path}/pharo/pharo.p12"
    sign_password="${PHARO_SIGN_PASSWORD}"
    cert_password="${PHARO_CERT_PASSWORD}"
    sign_identity="${PHARO_SIGN_IDENTITY}"
  elif [[ "${FLAVOR}" == "newspeak"* ]]; then
    cert_filepath_cer="${cert_path}/newspeak/sign.cer"
    cert_filepath_p12="${cert_path}/newspeak/sign.p12"
    sign_password="${NEWSPEAK_SIGN_PASSWORD}"
    cert_password="${NEWSPEAK_CERT_PASSWORD}"
    sign_identity="${NEWSPEAK_SIGN_IDENTITY}"
  else
    echo "Unsupported VM flavor ${FLAVOR}."
    exit 35
  fi

  if [[ -z "${sign_password}" ]]; then
    echo "[Error] No password given to decrypt certificates for ${FLAVOR}. Cannot sign."
    exit 234
  fi
  
  echo "::group::Decrypt certificate files..."
  openssl aes-256-cbc \
    -k "${sign_password}" \
    -in "${cert_filepath_cer}.enc" \
    -out "${cert_filepath_cer}" \
    -d
  openssl aes-256-cbc \
    -k "${sign_password}" \
    -in "${cert_filepath_p12}.enc" \
    -out "${cert_filepath_p12}" \
    -d
  echo "::endgroup::"

  echo "::group::Signing app bundle..."
  # Set up keychain
  security create-keychain -p travis "${KEY_CHAIN}"
  security default-keychain -s "${KEY_CHAIN}"
  security unlock-keychain -p travis "${KEY_CHAIN}"
  security set-keychain-settings -t 3600 -u "${KEY_CHAIN}"
  security import "${cert_filepath_cer}" -k ~/Library/Keychains/"${KEY_CHAIN}" -T /usr/bin/codesign
  security import "${cert_filepath_p12}" -k ~/Library/Keychains/"${KEY_CHAIN}" -P "${cert_password}" -T /usr/bin/codesign
  security set-key-partition-list -S apple-tool:,apple: -s -k travis "${KEY_CHAIN}"
  # Invoke codesign
  if [[ -d "${APP_PATH}/Contents/MacOS/Plugins" ]]; then
    # Pharo.app does not (yet) have its plugins in Resources dir
    codesign -s "${sign_identity}" --force --deep "${APP_PATH}/Contents/MacOS/Plugins/"*
  fi
  codesign -s "${sign_identity}" --force --deep "${APP_PATH}"
  # Remove sensitive files again
  rm -rf "${cert_filepath_cer}" "${cert_filepath_p12}"
  security delete-keychain "${KEY_CHAIN}"
  echo "::endgroup::"
}

sign_Windows() {
  echo "Not implemented."
  exit 999
}

if [[ ! -d "${PRODUCTS_PATH}" ]]; then
  echo "No products directory found."
  exit 10
fi

if [[ ! $(type -t sign_$RUNNER_OS) ]]; then
  echo "Unsupported runner OS ${RUNNER_OS}."
  exit 99
fi

sign_$RUNNER_OS
