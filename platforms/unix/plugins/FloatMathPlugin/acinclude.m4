libm_cflags="-O"

if test "$GCC" = yes; then
  case $host_cpu in
  i?86)
    libm_cflags="-O -fomit-frame-pointer"
    ;;
  powerpc|ppc)
    libm_cflags="-O3 -funroll-loops -mcpu=750 -mno-fused-madd"
    ;;
  esac
fi

AC_SUBST(LIBM_CFLAGS, $libm_cflags)
