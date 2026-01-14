## QNX Env ##
export QNX_PLATFORM=aarch64le
export QNX_SDP_VERSION=qnx800
export QNX_BASE=$HOME/$QNX_SDP_VERSION
export QNX_HOST=$QNX_BASE/host/linux/x86_64
export QNX_TARGET=$QNX_BASE/target/qnx/aarch64le
export SWCENTER_INSTALL_PATH=$HOME/qnx/qnxsoftwarecenter
export QSC_CLT_PATH=$SWCENTER_INSTALL_PATH/qnxsoftwarecenter_cltw
export QNX_PROJECTS=/home/kend/qnx/qnxprojects
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

## PATH with QNX tools ##
export PATH=$HOME/bin:$QNX_HOST/usr/bin:$QNX_CONFIGURATION/bin:$QNX_BASE/jre/bin:$QNX_BASE/host/common/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/snap/emacs/3163/usr/bin

## Make ##
export 	CC="$QNX_CC" 
export 	CFLAGS="$QNX_CFLAGS" 
export 	LDFLAGS="$QNX_LDFLAGS" 
export 	LIBS="$QNX_LIBS" 
export 	VM_WORD_SIZE="64" 
export 	VM_CFLAGS="-DNDEBUG -DDEBUGVM=0"
export	INSTALLDIR="raspi4qnx"
