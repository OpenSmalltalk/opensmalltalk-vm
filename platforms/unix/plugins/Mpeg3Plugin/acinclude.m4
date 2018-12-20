# Add `--enable-mpg-[mmx,pthreads]' switches

AC_ARG_ENABLE(mpg-mmx,
[  --enable-mpg-mmx        enable MMX support in Mpeg3Plugin [default=no]],
  XDEFS="-DUSE_MMX",
  XDEFS="")

AC_ARG_ENABLE(mpg-pthreads,
[  --enable-mpg-pthreads   enable pthread support in Mpeg3Plugin [default=no]],
  ,
  XDEFS="$XDEFS -DNOPTHREADS")

# Define `[xdefs]' in Makefile.in

AC_PLUGIN_DEFINE_UNQUOTED([xdefs], $XDEFS)
