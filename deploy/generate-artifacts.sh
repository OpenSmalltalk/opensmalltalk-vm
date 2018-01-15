#!/bin/bash
set -e

readonly PRODUCTS_DIR="./products"
if [[ ! -d "${PRODUCTS_DIR}" ]]; then
  echo "No products directory found."
  exit 10
fi
readonly IDENTIFIER="cog_${ARCH}_${FLAVOR}_${REV}"
readonly OUTPUT_PREFIX="${PRODUCTS_DIR}/${IDENTIFIER}"

pushd "${PRODUCTS_DIR}"
if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
  if [[ -d "threaded" ]]; then
    tar czf "${OUTPUT_PREFIX}.tar.gz" "./threaded"
  fi
  if [[ -d "itimer" ]]; then
    tar czf "${OUTPUT_PREFIX}_itimer.tar.gz" "./itimer"
  fi
elif [[ "${TRAVIS_OS_NAME}" == "osx" ]]; then
  TMP_DMG="temp.dmg"
  hdiutil create -size 8m -volname "${IDENTIFIER}" -srcfolder "${PRODUCTS_DIR}"/*.app \
      -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -nospotlight "${TMP_DMG}"
  DEVICE="$(hdiutil attach -readwrite -noautoopen -nobrowse "${TMP_DMG}" | awk 'NR==1{print$1}')"
  VOLUME="$(mount | grep "$DEVICE" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
  hdiutil detach "$DEVICE"
  hdiutil convert "${TMP_DMG}" -format UDBZ -imagekey bzip2-level=9 -o "${OUTPUT_PREFIX}.dmg"
  rm "${TMP_DMG}"
elif [[ "${APPVEYOR}" ]]; then
  rm -f *.def *.exp *.map *.o *Unstripped* # remove temporary build files
  zip -r "${OUTPUT_PREFIX}.zip" "./"
else
  echo "Unsupported platform '$(uname -s)'." 1>&2
  exit 20
fi
popd
