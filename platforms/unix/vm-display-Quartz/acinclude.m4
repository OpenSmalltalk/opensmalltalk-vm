# -*- sh -*-

AC_ARG_WITH(quartz,
[  --without-quartz        disable MacOSX Window System support [default=enabled]],
  [have_quartz="$withval"],
  [have_quartz="yes"])

case $host_os in
  darwin*) ;;
  *)       have_quartz="no";;
esac

if test "$have_quartz" = "yes"; then
  AC_DEFINE(USE_QUARTZ, [1], [Use Quartz])
  if test "$have_gl" = ""; then have_gl="no"; fi
  if test "$have_gl" = "yes"; then
	AC_CHECK_HEADERS(OpenGL/gl.h, [
      have_gl=yes
      AC_DEFINE(USE_QUARTZ_CGL, [1], [Use Quartz CGL])
	])
  else
    AC_DEFINE(USE_QUARTZ_CGL, 0, [Use Quartz CGL])
  fi
else
  AC_PLUGIN_DISABLE
fi
