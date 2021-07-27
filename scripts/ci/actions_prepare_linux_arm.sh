set -e

[[ "${ARCH}" != "linux32ARMv6" ]] && exit 0

MIRROR=http://archive.raspbian.org/raspbian
VERSION=buster
# TOOLS_DIR=$PWD/tools
ARMCHROOT=$PWD/armchroot

sudo dpkg --add-architecture i386
sudo apt-add-repository multiverse
sudo apt-add-repository universe
sudo apt-get update -myq || true

sudo apt-get update -y
sudo apt-get install -yq --no-install-suggests --no-install-recommends --allow-unauthenticated \
     gcc-arm-linux-gnueabi \
     gcc-arm-linux-gnueabihf \
     qemu-system \
     qemu-system-arm \
     qemu-user \
     qemu-user-static \
     sbuild \
     schroot \
     debootstrap \
     zlib1g:i386 \
     libstdc++6:i386 \
     libffi-dev:i386 \
     libssl-dev:i386 \
     libbz2-1.0:i386 \
     libc6-dev-i386 \
     libc6:i386 \
     libexpat1:i386 \
     libtinfo5:i386 \
     binfmt-support \
     build-essential \
     python-dev \
     libffi-dev \
     zlib1g-dev \
     libtool \
     automake \
     autoconf

sudo chown $USER /etc/schroot/schroot.conf
echo "
[rpi]
directory=$ARMCHROOT
users=$USER
root-users=$USER
groups=$USER
aliases=default
type=directory
" >>  /etc/schroot/schroot.conf
cat /etc/schroot/schroot.conf
sudo chown root /etc/schroot/schroot.conf

# git clone https://github.com/raspberrypi/tools.git $TOOLS_DIR

# chroot
if [ ! -e "$ARMCHROOT/etc/debian_chroot" ]; then
    mkdir -p $ARMCHROOT
    sudo qemu-debootstrap --no-check-gpg --include=fakeroot,build-essential --arch=armhf ${VERSION} ${ARMCHROOT} ${MIRROR}
    sudo su -c "echo \"deb ${MIRROR} ${VERSION} main contrib rpi\" > ${ARMCHROOT}/etc/apt/sources.list"
    schroot -c rpi -u root -- apt-get update
    schroot -c rpi -u root -- apt-get --allow-unauthenticated install -y \
	    build-essential libcairo2-dev libpango1.0-dev libssl-dev uuid-dev uuid-runtime libasound2-dev \
	    debhelper devscripts libssl-dev libfreetype6-dev libx11-dev libxext-dev libxrender-dev \
	    libx11-dev libsm-dev libice-dev libgl1-mesa-dev libgl1-mesa-glx git \
	    libtool automake autoconf
    #needed for third-party libraries
    schroot -c rpi -u root -- apt-get --allow-unauthenticated install -y cmake curl
fi
schroot -c rpi -- uname -m

sudo mount -o remount,size=100M /tmp || echo "No tmp size increase required"

# Use Scratchbox2 for faster compilation
# pushd $ARMCHROOT
# sb2-init -c `which qemu-arm` rpi $TOOLS_DIR/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-gcc
# sb2-config -d rpi
# popd
