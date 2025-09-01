#!/bin/bash
set -e

# ----------------------------------------------------------------------------
# Download, install, and update MSYS2 packages (e.g. compilers, linkers)
# ----------------------------------------------------------------------------
# binutils ... dlltool.exe for x86_64, GCC-based, generic MSYS2 environment
# mingw-w64-i686-binutils ... dlltool.exe for i686, GCC-based
#    -> via mingw-w64-i686-toolchain
# mingw-w64-x86_64-binutils ... dlltool.exe for x86_64, GCC-based
#    -> via mingw-w64-x86_64-toolchain
# mingw-w64-clang-x86_64-llvm-tools ... dlltool.exe for x86_64, Clang-based
#    -> via mingw-w64-clang-x86_64-toolchain
# mingw-w64-clang-aarch64-llvm-tools ... dlltool.exe for ARM64, Clang-based
#    -> via mingw-w64-clang-aarch64-toolchain
# ----------------------------------------------------------------------------


# Common GNU dev tools (e.g., git, make ... GNU coreutils and GNU binutils)
PACKAGES="git base-devel"

if [[ "${MSYSTEM}" == "MSYS" ]]; then
    # We require dlltool, even when using the MSVC toolchain.
    PACKAGES="$(PACKAGES) \
        mingw-w64-i686-binutils \
        mingw-w64-x86_64-binutils \
        mingw-w64-clang-x86_64-llvm-tools \
        mingw-w64-clang-aarch64-llvm-tools"
else
    # The toolchain groups include compiler, linker, DLL wrappers, etc.
    PACKAGES="$(PACKAGES) $(MINGW_PACKAGE_PREFIX)-toolchain"

    if [[ "${MSYSTEM}" == "MINGW32" ]] || [[ "${MSYSTEM}" == "MINGW64" ]]; then
        # The architecture is GCC-based. Install Clang.
        PACKAGES="$(PACKAGES) \
            $(MINGW_PACKAGE_PREFIX)-clang \
            $(MINGW_PACKAGE_PREFIX)-clang-libs \
            $(MINGW_PACKAGE_PREFIX)-clang-tools-extra \
            $(MINGW_PACKAGE_PREFIX)-clang-analyzer"
    elif [[ "${MSYSTEM}" == "CLANG64" ]] || [[ "${MSYSTEM}" == "CLANGARM64" ]]; then
        # LLVM/Clang is already installed via *-toolchain group
        PACKAGES="$(PACKAGES)"
    else
        echo "Unsupported MSYS2 environment ${MSYSTEM}."
        exit 99
    fi
fi

# Upgrade the system, then install the packages. See above.
pacman -Suqy --noconfirm
pacman -Sq --noconfirm "$(PACKAGES)"
