#!/bin/bash
# -*- mode: sh; sh-basic-offset: 4 -*-
set -ex

# This script installs all packages required to build the various VM
# flavors in an x86-compatible environment. It supports both 32-bit
# and #64-bit architectures, which means that the host Linux platform
# has to support the older i386 packages to make 32-bit compile.

if [[ "${ARCH}" = "linux64x64" ]]; then
    sudo apt-get update -y
    sudo apt-get install -yq --no-install-suggests --no-install-recommends --allow-unauthenticated \
            debhelper \
            devscripts \
            libasound2-dev \
            libc6-dev \
            libssl-dev \
            libfreetype6-dev \
            libevdev-dev \
            libx11-dev \
            libxext-dev \
            libxrender-dev \
            libxrandr-dev \
            libpango1.0-dev \
            libpulse-dev \
            libaudio-dev \
            libsndio-dev \
            gcc-multilib \
            uuid-dev \
            libglu1-mesa-dev \
            automake \
            autoconf \
            libtool \
            curl \
            cmake
elif [[ "${ARCH}" = "linux32x86" ]]; then
    PKGS=(
        libasound2-dev
        libssl-dev
        libpng-dev
        libfreetype6-dev
        libevdev-dev
        libx11-dev
        libsm-dev
        libice-dev
        libgl1-mesa-glx
        libgl1-mesa-dev
        libxext-dev
        libxrender-dev
        libxrandr-dev
        libglapi-mesa
        libcairo2-dev
        libpango1.0-dev
            libglib2.0-dev
            libxft-dev
        libpulse-dev
        libaudio-dev
        libsndio-dev
        uuid-dev
        libcurl4-openssl-dev
        libssh2-1-dev
    )
    dpkg --get-selections
    sudo dpkg --add-architecture i386
    sudo apt-get update -y
    # make sure no conflicting x86_64 packages remain
    sudo apt-get purge "${PKGS[@]}" "${PKGS[@]/-dev/}"
    # install i386-version of packages
    sudo apt-get install -yq --no-install-suggests --no-install-recommends --allow-unauthenticated \
            devscripts \
            gcc-multilib \
            libc6-dev:i386 \
            "${PKGS[@]/%/:i386}"
fi
