bitblt_objs="BitBltPlugin.o"
bitblt_flags=""
arm_arch=""

case $host_cpu in
arm*)
case $host_cpu in
  armv6*) arm_arch="6" ;;
  armv7*) arm_arch="7-A" ;;
esac
AC_ARG_ENABLE(fast-bitblt,
 [  --enable-fast-bitblt enable fast BitBlt optimizations (default=no)],
 [ if   test "x$enableval" = "xyes" ; then
      bitblt_objs="BitBltPlugin.o BitBltArm.o BitBltArmLinux.o BitBltArmSimd.o BitBltDispatch.o BitBltGeneric.o BitBltArmSimdAlphaBlend.o BitBltArmSimdBitLogical.o BitBltArmSimdCompare.o BitBltArmSimdPixPaint.o BitBltArmSimdSourceWord.o"
      bitblt_flags="-DENABLE_FAST_BLT"
   fi
 ],
 [])
;;
esac

AC_SUBST(BITBLT_OBJS, $bitblt_objs)
AC_SUBST(BITBLT_FLAGS, $bitblt_flags)
AC_SUBST(ARM_ARCH, $arm_arch)
