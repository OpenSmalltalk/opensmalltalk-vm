libm_cflags="-O"

if test "$GCC" = yes; then
  case $host_cpu in
  i?86)
    libm_cflags="-O -fomit-frame-pointer -DLSB_FIRST=1"
    ;;
  powerpc|ppc)
    libm_cflags="-O3 -funroll-loops -mcpu=750 -mno-fused-madd -DLSB_FIRST=0"
    ;;
  esac
fi

AC_SUBST(LIBM_CFLAGS, $libm_cflags)
