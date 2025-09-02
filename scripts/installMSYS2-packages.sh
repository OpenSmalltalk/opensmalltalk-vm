#!/bin/bash
set -e

# ----------------------------------------------------------------------------
# Download, install, and update MSYS2 packages (e.g. compilers, linkers)
# ----------------------------------------------------------------------------

# Common GNU dev tools (e.g., git, sed, grep)
PACKAGES="git base"

if [[ "${MSYSTEM}" == "MSYS" ]]; then
    # We require make, because we do not use NMAKE from the MSVC toolchain.
    PACKAGES="${PACKAGES} make"
else
    # The toolchain groups include compiler, linker, DLL wrappers, etc.
    PACKAGES="${PACKAGES} ${MINGW_PACKAGE_PREFIX}-toolchain"

    if [[ "${MSYSTEM}" == "MINGW32" ]] || [[ "${MSYSTEM}" == "MINGW64" ]]; then
        # The architecture is GCC-based. Install Clang.
        PACKAGES="${PACKAGES} \
            ${MINGW_PACKAGE_PREFIX}-clang \
            ${MINGW_PACKAGE_PREFIX}-clang-libs \
            ${MINGW_PACKAGE_PREFIX}-clang-tools-extra \
            ${MINGW_PACKAGE_PREFIX}-clang-analyzer"
    elif [[ "${MSYSTEM}" == "CLANG64" ]] || [[ "${MSYSTEM}" == "CLANGARM64" ]]; then
        # LLVM/Clang is already installed via *-toolchain group
        PACKAGES="${PACKAGES}"
    else
        echo "Unsupported MSYS2 environment ${MSYSTEM}."
        exit 99
    fi
fi

# Upgrade the system, then install the packages. See above.
pacman -Suqy --noconfirm
pacman -Sq --noconfirm ${PACKAGES}
