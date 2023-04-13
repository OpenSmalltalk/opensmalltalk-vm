#!/bin/bash
# -*- mode: sh; sh-basic-offset: 4 -*-
set -e

# This script installs all packages required to build the various VM
# flavors in an x86-compatible environment. It supports both 32-bit
# and #64-bit architectures, which means that the host Linux platform
# has to support the older i386 packages to make 32-bit compile.

DEV_PKGS=(
    libc6-dev
    libasound2-dev
    libssl-dev
    libfreetype6-dev
    libevdev-dev
    libx11-dev
    libxext-dev
    libxrender-dev
    libxrandr-dev
    libpango1.0-dev
    libpulse-dev
    libaudio-dev
    libsndio-dev
    uuid-dev
    libglu1-mesa-dev
    libpcre2-8-0
)

# Per default, let apt decide
ARCHCODE=""
if [[ "${ARCH}" = "linux32x86" ]]; then
    sudo dpkg --add-architecture i386
    sudo add-apt-repository ppa:ondrej/php
    ARCHCODE=":i386"
fi

sudo apt-get update -y
sudo apt-get install -yq --no-install-suggests --no-install-recommends --allow-unauthenticated \
     debhelper \
     devscripts \
     gcc-multilib \
     automake \
     autoconf \
     libtool \
     curl \
     cmake \
     "${DEV_PKGS[@]/%/$ARCHCODE}"
