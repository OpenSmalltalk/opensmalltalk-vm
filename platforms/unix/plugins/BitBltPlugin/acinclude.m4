case $host_cpu in
arm*)
bitblt_objs="BitBltPlugin$o BitBltArm$o BitBltArmLinux$o BitBltArmOther$o BitBltArmSimd$o BitBltDispatch$o BitBltGeneric$o BitBltArmSimdAlphaBlend$o BitBltArmSimdBitLogical$o BitBltArmSimdPixPaint$o BitBltArmSimdSourceWord$o"
;;
*)
bitblt_objs="BitBltPlugin.o"
esac

AC_SUBST(BITBLT_OBJS, $bitblt_objs)
