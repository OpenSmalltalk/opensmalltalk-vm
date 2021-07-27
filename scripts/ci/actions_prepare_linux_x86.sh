set -e

if [[ "${ARCH}" = "linux64x64" ]]; then
    sudo apt-get update -y
    sudo apt-get install -yq --no-install-suggests --no-install-recommends --allow-unauthenticated \
            debhelper \
            devscripts \
            libasound2-dev \
            libc6-dev \
            libssl-dev \
            libfreetype6-dev \
            libx11-dev \
            libxext-dev \
            libxrender-dev \
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
    sudo dpkg --add-architecture i386
    sudo apt-get update -y
    sudo apt-get remove -q -y gvfs-daemons
    sudo apt-get install -yq --no-install-suggests --no-install-recommends --allow-unauthenticated \
            devscripts \
            libc6-dev:i386 \
            libasound2:i386 \
            libasound2-dev:i386 \
            libssl-dev:i386 \
            libpng-dev:i386 \
            libfreetype6-dev:i386 \
            libx11-dev:i386 \
            libsm-dev:i386 \
            libice-dev:i386 \
            libgl1-mesa-glx:i386 \
            libgl1-mesa-dev:i386 \
            libxext-dev:i386 \
            libxrender-dev:i386 \
            libglapi-mesa:i386 \
            libcairo2-dev:i386 \
            libpango1.0-dev:i386 \
              libglib2.0-dev:i386 \
              libxft-dev:i386 \
              gir1.2-pango-1.0:i386 \
              gir1.2-freedesktop:i386 \
              gir1.2-glib-2.0:i386 \
              libgirepository-1.0-1:i386 \
            libpulse-dev:i386 \
            libaudio-dev:i386 \
            libsndio-dev:i386 \
            gcc-multilib \
            uuid-dev:i386 \
            libcurl4-openssl-dev:i386 \
            libssh2-1-dev:i386
fi
