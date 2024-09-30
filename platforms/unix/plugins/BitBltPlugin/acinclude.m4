# -*- sh -*-

bitblt_objs="BitBltPlugin.o"
bitblt_flags=""
arm_arch=""


# Detour cpu check on debian-like to account for diverging bit-ness of kernel
# and userland, as seen on certain Raspberry Pis
# see https://forums.raspberrypi.com/viewtopic.php?t=349653&sid=01c84510219f6ac2740035f8f58efa9b
# Also note, autoconf's $host_cpu does not help in this case, because OF COURSE it doesnt
AC_CHECK_PROGS([DPKG_ARCHITECTURE], [dpkg-architecture], [no])
AC_MSG_CHECKING([running ISA])
AS_IF([test "x$DPKG_ARCHITECTURE" != "xno"],
      [target_isa=`$DPKG_ARCHITECTURE --query DEB_TARGET_ARCH`],
      [target_isa=$host_cpu])
AC_MSG_RESULT([$target_isa])

case $target_isa in
  armhf*|armv6*|armv7*)
    case $target_isa in
      armv6*) arm_arch="6" ;;
      armhf*|armv7*) arm_arch="7-A" ;;
    esac
    AC_ARG_ENABLE(fast-bitblt,
        AS_HELP_STRING([--enable-fast-bitblt], [enable ARM-specif fast BitBlt optimizations (default=disabled)]),
        AS_IF([test "x$enableval" = "xyes"],
            [bitblt_objs="BitBltPlugin.o BitBltArm.o BitBltArmLinux.o BitBltArmSimd.o BitBltDispatch.o BitBltGeneric.o BitBltArmSimdAlphaBlend.o BitBltArmSimdBitLogical.o BitBltArmSimdCompare.o BitBltArmSimdPixPaint.o BitBltArmSimdSourceWord.o"
            bitblt_flags="-DENABLE_FAST_BLT"]),
            [])
    ;;
  aarch64|arm64)
    AC_ARG_ENABLE(fast-bitblt,
        AS_HELP_STRING([--enable-fast-bitblt], [enable ARM-specif fast BitBlt optimizations (default=disabled)]),
        AS_IF([test "x$enableval" = "xyes"],
            [bitblt_objs="BitBltPlugin.o BitBltArm64.o BitBltDispatch.o BitBltGeneric.o"
             bitblt_flags="-DENABLE_FAST_BLT"]),
            [])
    ;;
esac

AC_SUBST(BITBLT_OBJS, $bitblt_objs)
AC_SUBST(BITBLT_FLAGS, $bitblt_flags)
AC_SUBST(ARM_ARCH, $arm_arch)
