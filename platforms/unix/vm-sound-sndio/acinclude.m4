# -*- sh -*-

AC_MSG_CHECKING([for OpenBSD sndio Sound System])
AC_CHECK_HEADERS([sndio.h],,AC_PLUGIN_DISABLE)
AC_PLUGIN_SEARCH_LIBS([sio_open],[sndio])
