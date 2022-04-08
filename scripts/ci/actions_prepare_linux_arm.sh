#!/bin/bash
set -e

# This script installs all packages required to build the various VM
# flavors in an ARM-compatible environment such as via QEMU or on a
# Raspberry Pi. For simplicity, the packages should cover all possible
# plugins even if those are not compiled in a particular build
# configuration.
#
# Note that "libtool automake autoconf libltdl-dev" are required to
# let the configure script pass.

apt-get update -y
apt-get install -yq --no-install-suggests --no-install-recommends   build-essential git devscripts   uuid-dev libcairo2-dev libpango1.0-dev libgl1-mesa-dev libgl1-mesa-glx libssl-dev libevdev-dev m4 libpulse-dev   libasound2-dev libfreetype6-dev libx11-dev libxrender-dev libxrandr-dev  libtool automake autoconf libltdl-dev

# Other packages found in older build scripts, ignored for now:
#   uuid-runtime libsm-dev libice-dev cmake
