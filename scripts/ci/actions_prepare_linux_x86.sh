#!/bin/bash
# -*- mode: sh; sh-basic-offset: 4 -*-
set -ex

# This script installs all packages required to build the various VM
# flavors in an x86-compatible environment. It supports both 32-bit
# and #64-bit architectures, which means that the host Linux platform
# has to support the older i386 packages to make 32-bit compile.

DEV_PKGS=(
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
)

if [[ "${ARCH}" = "linux64x64" ]]; then
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
            libc6-dev \
            "${DEV_PKGS[@]}"

elif [[ "${ARCH}" = "linux32x86" ]]; then
    # These Packages must go in amd64, because we cannot install the
    # :i386 package otherwise.
    POISON_PKGS=(
        "${DEV_PKGS[@]}"
        libcairo2
        libcairo-gobject2
        libglib2.0-0
        libmount-dev
        libselinux1-dev
        gir1.2-pango
        libharfbuzz-dev
        libpango-1.0-0
        libpangocairo-1.0-0
        libpangoft2-1.0-0
        libpangoxft-1.0-0
    )
    sudo dpkg --add-architecture i386
    sudo add-apt-repository ppa:ondrej/php
    sudo apt-get update -y
    # apt-mark showhold
    # head -n100 /etc/apt/sources.list /etc/apt/sources.list.d/* /etc/apt/apt.conf.d/*
    apt-cache policy libc6 libc6:i386 libc6-dev libc6-dev:amd64 libc6-dev:i386
    echo ======
    apt-cache policy libpcre2-8-0:amd64  libpcre2-8-0:i386 
    
    # make sure no conflicting x86_64 packages remain
    # sudo apt-get purge "${POISON_PKGS[@]/%/:amd64}"
    # install i386-version of packages
    sudo apt-get install   -o Debug::pkgProblemResolver=yes --ignore-hold -o Dpkg::Options='--force-confdef --force-confold --force-overwrite' -y --no-install-suggests --no-install-recommends --allow-unauthenticated \
         libpcre2-8-0:amd64  libpcre2-8-0:i386 \
            devscripts \
            gcc-multilib \
            libc6-dev:i386 \
            "${DEV_PKGS[@]/%/:i386}"
fi
