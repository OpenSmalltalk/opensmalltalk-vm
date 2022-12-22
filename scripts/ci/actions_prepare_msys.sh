#!/bin/bash
#
#   Extend $PATH since MSYS is installed but not conveniently accessible
#   in a GitHub-Actions Windows environment.

[[ -z "${MSYS_SYS}" ]] && exit 2

# Add MinGW tools for build scripts
PATH=$PATH:/c/msys64/${MSYS_SYS}/bin

# Add other GNU tools (e.g., wget) for third-party build scripts
PATH=$PATH:/c/msys64/usr/bin
