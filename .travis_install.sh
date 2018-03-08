set -e

if [[ "${ARCH}" = "linux64x64" ]]; then
    sudo apt-get install -yq --no-install-suggests --no-install-recommends --force-yes \
            debhelper \
            devscripts \
            libasound2-dev \
            libc6-dev \
            libssl-dev \
            libfreetype6-dev \
            libx11-dev \
            libxext-dev \
            libpango1.0-dev \
            libpulse-dev \
            libaudio-dev \
            gcc-multilib \
            uuid-dev
elif [[ "${ARCH}" = "linux32x86" ]]; then
    sudo apt-get remove -q -y gvfs-daemons
    sudo apt-get install -yq --no-install-suggests --no-install-recommends --force-yes \
            devscripts \
            gcc-multilib \
            uuid-dev:i386 \
            libcurl3-dev:i386 \
            libx11-dev:i386 \
            libsm-dev:i386 \
            libice-dev:i386 \
            libgl1-mesa-glx:i386 \
            libgl1-mesa-dev:i386 \
            libxext-dev:i386 \
            libglapi-mesa:i386 \
            libaudio-dev:i386 \
            libasound2:i386 \
            libasound2-dev:i386 \
            gir1.2-freedesktop:i386 \
            gir1.2-glib-2.0:i386 \
            gir1.2-pango-1.0:i386 \
            libatomic1:i386 \
            libblkid1:i386 \
            libc6-dev:i386 \
            libcairo-gobject2:i386 \
            libcairo-script-interpreter2:i386 \
            libcairo2:i386 \
            libcairo2-dev:i386 \
            libdatrie1:i386 \
            libexpat1-dev:i386 \
            libfontconfig1:i386 \
            libfontconfig1-dev:i386 \
            libfreetype6-dev:i386 \
            libgirepository-1.0-1:i386 \
            libglib2.0-0:i386 \
            libglib2.0-dev:i386 \
            libgomp1:i386 \
            libgraphite2-3:i386 \
            libgraphite2-dev:i386 \
            libharfbuzz-dev:i386 \
            libharfbuzz-gobject0:i386 \
            libharfbuzz-icu0:i386 \
            libharfbuzz0b:i386 \
            libicu-dev:i386 \
            libitm1:i386 \
            liblzo2-2:i386 \
            libmount1:i386 \
            libpango-1.0-0:i386 \
            libpangocairo-1.0-0:i386 \
            libpangoft2-1.0-0:i386 \
            libpangoxft-1.0-0:i386 \
            libpulse-dev:i386 \
            libpcre3:i386 \
            libpcre3-dev:i386 \
            libpixman-1-0:i386 \
            libpixman-1-dev:i386 \
            libpng-dev:i386 \
            libquadmath0:i386 \
            libselinux1:i386 \
            libthai0:i386 \
            libxcb-shm0:i386 \
            libxcb-shm0-dev:i386 \
            libxft-dev:i386 \
            libxft2:i386 \
            libxrender-dev:i386 \
            linux-libc-dev:i386 \
            libssl-dev:i386 \
            libssl0.9.8:i386 \
            zlib1g-dev:i386
fi

[[ "${ARCH}" != "linux32ARMv6" ]] && exit 0

MIRROR=http://archive.raspbian.org/raspbian
VERSION=jessie
# TOOLS_DIR=$PWD/tools
ARMCHROOT=$PWD/armchroot

sudo dpkg --add-architecture i386
sudo apt-add-repository multiverse
sudo apt-add-repository universe
sudo apt-get update -myq || true

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
    sudo su -c "echo \"deb ${MIRROR} jessie main contrib rpi\" > ${ARMCHROOT}/etc/apt/sources.list"
    schroot -c rpi -u root -- apt-get update
    schroot -c rpi -u root -- apt-get --allow-unauthenticated install -y \
	    build-essential libcairo2-dev libpango1.0-dev libssl-dev uuid-dev uuid-runtime libasound2-dev \
	    debhelper devscripts libssl-dev libfreetype6-dev libx11-dev libxext-dev \
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
