#!/bin/bash
# Pack the VM into platform-specific container. All packing functions are 
# evaluated in the ${PRODUCTS_PATH}. All binaries are expected to be there,
# already signed if required.
#
# Uses:
# - APP_NAME
# - PRODUCTS_PATH
# - ASSET_NAME
#
# Provides:
# - ASSET_EXTENSION (e.g., "tar.gz", "dmg", "zip")

set -e

[[ ! -d "${PRODUCTS_PATH}/${APP_NAME}" ]] && exit 31
[[ -z "${ASSET_NAME}" ]] && exit 32

# Pack the Linux build as .tar.gz archive
pack_Linux() {
  readonly ASSET_EXTENSION="tar.gz"
  tar czf "${PRODUCTS_PATH}/${ASSET_NAME}.${ASSET_EXTENSION}" "${APP_NAME}"
}

# Pack the macOS .app as .dmg container
pack_macOS() {
  readonly ASSET_EXTENSION="dmg"
  readonly APP_PATH="${PRODUCTS_PATH}/${APP_NAME}"
  TMP_DMG="temp.${ASSET_EXTENSION}"
  hdiutil create -size 64m -volname "${ASSET_NAME}" -srcfolder "${APP_PATH}" \
      -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -nospotlight "${TMP_DMG}"
  DEVICE="$(hdiutil attach -readwrite -noautoopen -nobrowse "${TMP_DMG}" | awk 'NR==1{print$1}')"
  VOLUME="$(mount | grep "$DEVICE" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
  hdiutil detach "$DEVICE"
  hdiutil convert "${TMP_DMG}" -format UDBZ -imagekey bzip2-level=9 -o "${ASSET_NAME}.${ASSET_EXTENSION}"
  rm -f "${TMP_DMG}"
}

# Pack the Windows build as .zip archive
pack_Windows() {
  readonly ASSET_EXTENSION="zip"
  cd "${APP_NAME}"
  rm -f *.def *.exp *.lib *.map *.o *.res *Unstripped* *.ignore # remove temporary build files
  7z a -tzip -r "${PRODUCTS_PATH}/${ASSET_NAME}.${ASSET_EXTENSION}" "./"
}

if [[ ! -d "${PRODUCTS_PATH}" ]]; then
  echo "No products directory found."
  exit 10
fi

if [[ ! $(type -t pack_$RUNNER_OS) ]]; then
  echo "Unsupported runner OS ${RUNNER_OS}."
  exit 99
fi

pushd "${PRODUCTS_PATH}"
pack_$RUNNER_OS
popd

[[ -z "${ASSET_EXTENSION}" ]] && exit 95
echo "ASSET_EXTENSION=${ASSET_EXTENSION}" >> $GITHUB_ENV
