#!/bin/bash
set -e

readonly PRODUCTS_DIR="./products"
if [[ ! -d "${PRODUCTS_DIR}" ]]; then
  echo "No products directory found."
  exit 10
fi
readonly REV=$(grep -m1 "SvnRawRevisionString" platforms/Cross/vm/sqSCCSVersion.h | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
readonly IDENTIFIER="cog_${ARCH}_${FLAVOR}_${REV}"

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
  TMP_DMG="temp.dmg"
  hdiutil create -size 8m -volname "${IDENTIFIER}" -srcfolder "${PRODUCTS_DIR}"/*.app \
      -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -nospotlight "${TMP_DMG}"
  DEVICE="$(hdiutil attach -readwrite -noautoopen -nobrowse "${TMP_DMG}" | awk 'NR==1{print$1}')"
  VOLUME="$(mount | grep "$DEVICE" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
  hdiutil detach "$DEVICE"
  hdiutil convert "${TMP_DMG}" -format UDBZ -imagekey bzip2-level=9 -o "${IDENTIFIER}.dmg"
  rm "${TMP_DMG}"
elif [[ "${APPVEYOR}" ]]; then
  rm -f *.def *.exp *.map *.o *Unstripped* # remove temporary build files
  zip -r "${IDENTIFIER}.zip" "./"
else
  echo "Unsupported platform '$(uname -s)'." 1>&2
  exit 30
fi
popd
