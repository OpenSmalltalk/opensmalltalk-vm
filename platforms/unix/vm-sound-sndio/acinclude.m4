# -*- sh -*-

AC_MSG_CHECKING([for sndio sound support])

AC_ARG_WITH(sndio-sound,
[  --with-sndio-sound     enable sndio sound support [default=disabled]],
  [have_snd_sndio="$withval"],
  [have_snd_sndio="no"])

if test "$have_snd_sndio" = "yes"; then
  # check for libraries, headers, etc., here...
  AC_MSG_CHECKING([for OpenBSD sndio Sound System])
  sio_h_found="no"
  AC_CHECK_HEADERS([sndio.h],[sndio_h_found="yes"; break])
  if test "$sndio_h_found" = "no"; then
    AC_PLUGIN_DISABLE
  else
    AC_CHECK_LIB([sndio],[sio_open],[AC_PLUGIN_USE_LIB([sndio])])
  fi
else
  AC_MSG_RESULT([no])
  AC_PLUGIN_DISABLE
fi
