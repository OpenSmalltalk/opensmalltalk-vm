## QNX Env ##
export QNX_PLATFORM=aarch64le
export QNX_SDP_VERSION=qnx800
export QNX_BASE=$HOME/$QNX_SDP_VERSION
export QNX_HOST=$QNX_BASE/host/linux/x86_64
export QNX_TARGET=$QNX_BASE/target/qnx/aarch64le
export SWCENTER_INSTALL_PATH=$HOME/qnx/qnxsoftwarecenter
export QSC_CLT_PATH=$SWCENTER_INSTALL_PATH/qnxsoftwarecenter_cltw
export QNX_PROJECTS=$HOME/qnx/qnxprojects
export QNX_CONFIGURATION_EXCLUSIVE=$HOME/.qnx
export QNX_CONFIGURATION=$QNX_CONFIGURATION_EXCLUSIVE
export QNX_CC="qcc -Vgcc_ntoaarch64le"
export QNX_CCFLAGS="-DNOEXECINFO=1 -I$QNX_BASE/target/qnx/usr/include"
export QNX_CFLAGS=$QNX_CCFLAGS
export QNX_MAKEFLAGS=$QNX_CCFLAGS
export QNX_LDFLAGS="-L$QNX_TARGET/lib -L$QNX_TARGET/usr/lib"
export QNX_LIBS="-lsocket -linputevents -liconv -lffi"
export QNX_CPU=aarch64
export QNX_TARGET_OS=qnx
export QNX_TARGET_ARCH=-Vgcc_ntoaarch64le
