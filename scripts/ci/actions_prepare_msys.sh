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

ln -f -s /c/msys64/${MSYS_SYS}/bin/clang /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-clang
ln -f -s /c/msys64/${MSYS_SYS}/bin/clang++ /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-clang++
ln -f -s /c/msys64/${MSYS_SYS}/bin/ar /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-ar
ln -f -s /c/msys64/${MSYS_SYS}/bin/dlltool /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-dlltool
ln -f -s /c/msys64/${MSYS_SYS}/bin/as /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-as
ln -f -s /c/msys64/${MSYS_SYS}/bin/windres /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-windres
ln -f -s /c/msys64/${MSYS_SYS}/bin/nm /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-nm
ln -f -s /c/msys64/${MSYS_SYS}/bin/dllwrap /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-dllwrap
ln -f -s /c/msys64/${MSYS_SYS}/bin/strip /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-strip
ln -f -s /c/msys64/${MSYS_SYS}/bin/objcopy /c/msys64/${MSYS_SYS}/bin/${MSYS_ENV}-w64-mingw32-objcopy

# Add MinGW tools for build scripts
PATH=$PATH:/c/msys64/${MSYS_SYS}/bin

# Add other GNU tools (e.g., wget) for third-party build scripts
PATH=$PATH:/c/msys64/usr/bin
