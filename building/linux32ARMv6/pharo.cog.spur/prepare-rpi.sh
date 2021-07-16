#! /bin/bash

set -e 

MIRROR=http://archive.raspbian.org/raspbian
VERSION=jessie
# TOOLS_DIR=$PWD/tools
ARMCHROOT=/srv/arm
USER=esteban

sudo apt-get install -yq --no-install-suggests --no-install-recommends --force-yes \
     gcc-arm-linux-gnueabi \
     gcc-arm-linux-gnueabihf \
     qemu-system \
     qemu-system-arm \
     qemu-user \
     qemu-user-static \
     sbuild \
     schroot \
     scratchbox2 \
     debootstrap \
     zlib1g:i386 \
     libstdc++6:i386 \
     libffi-dev:i386 \
     libffi6:i386 \
     libssl1.0.0:i386 \
     libbz2-1.0:i386 \
     libc6-dev-i386 \
     libc6:i386 \
     libexpat1:i386 \
     libtinfo5:i386 \
     binfmt-support \
     build-essential \
     python-dev \
     libffi-dev \
     zlib1g-dev

# add chroot
sudo echo "
[rpi]
directory=$ARMCHROOT
users=$USER
root-users=$USER
groups=$USER
aliases=default
type=directory
" >>  /etc/schroot/schroot.conf

# chroot
if [ ! -e "$ARMCHROOT/etc/debian_chroot" ]; then
	mkdir -p $ARMCHROOT
	sudo qemu-debootstrap --no-check-gpg --include=fakeroot,build-essential --arch=armhf ${VERSION} ${ARMCHROOT} ${MIRROR}
	sudo su -c "echo \"deb ${MIRROR} jessie main contrib rpi\" > ${ARMCHROOT}/etc/apt/sources.list"
	schroot -c rpi -u root -- apt-get update
	schroot -c rpi -u root -- apt-get --allow-unauthenticated install -y \
		build-essential libcairo2-dev libpango1.0-dev libssl-dev uuid-dev uuid-runtime libasound2-dev \
		debhelper devscripts libssl-dev libfreetype6-dev libx11-dev libxext-dev \
		libx11-dev libsm-dev libice-dev libgl1-mesa-dev libgl1-mesa-glx git libtool automake autoconf
    #needed for third-party libraries
    schroot -c rpi -u root -- apt-get --allow-unauthenticated install -y cmake curl
fi
schroot -c rpi -- uname -m

#sudo mount -o remount,size=100M /tmp || echo "No tmp size increase required"

