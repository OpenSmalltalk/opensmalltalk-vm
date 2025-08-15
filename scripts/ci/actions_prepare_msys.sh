#!/bin/bash
#
#   Prepare MSYS environment so that all build tools have the $(TOOLPREFIX) as
#   expected in Makefile.tools:
#      - win64x64\common\Makefile.tools
#      - win32x86\common\Makefile.tools
#   Also, extend $PATH since MSYS is installed but not conveniently accessible
#   Extend $PATH since MSYS is installed but not conveniently accessible
#   in a GitHub-Actions Windows environment.

[[ -z "${MSYS_SYS}" ]] && exit 2
[[ -z "${MSYS_ENV}" ]] && exit 2

if [ -z "${MSYS_PATH}" ]; then MSYS_PATH="/c/msys64"; fi

ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/clang ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-clang
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/clang++ ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-clang++
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/ar ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-ar
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/dlltool ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-dlltool
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/as ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-as
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/windres ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-windres
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/nm ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-nm
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/strip ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-strip
ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/objcopy ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-objcopy

# We now use "gcc -shared" instead of "dllwrap". See Makefile.tools.
#ln -f -s ${MSYS_PATH}/${MSYS_SYS}/bin/dllwrap ${MSYS_PATH}/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-dllwrap

# Add MinGW tools for build scripts
PATH=$PATH:${MSYS_PATH}/${MSYS_SYS}/bin

# Add other GNU tools (e.g., wget) for third-party build scripts
PATH=$PATH:${MSYS_PATH}/usr/bin
