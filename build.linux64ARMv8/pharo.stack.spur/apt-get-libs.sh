#! /bin/bash

set -e 

#MIRROR=http://archive.raspbian.org/raspbian
#VERSION=jessie
# TOOLS_DIR=$PWD/tools
#ARMCHROOT=/srv/arm
#USER=esteban

sudo apt-get install -yq --no-install-suggests --no-install-recommends --force-yes \
     gcc-arm-linux-gnueabi \
     gcc-arm-linux-gnueabihf \
     qemu-system \
     qemu-system-arm \
     qemu-user \
     qemu-user-static \
     sbuild \
     schroot \
     debootstrap \
     zlib1g \
     libstdc++6 \
     libffi-dev \
     libffi6 \
     libssl1.0.2 \
     libbz2-1.0 \
     libgit2-dev \
     libssh2-1-dev \
     libc6-dev \
     libc6 \
     libexpat1 \
     libtinfo5 \
     binfmt-support \
     build-essential \
     python-dev \
     libffi-dev \
     zlib1g-dev

#     scratchbox2 \
