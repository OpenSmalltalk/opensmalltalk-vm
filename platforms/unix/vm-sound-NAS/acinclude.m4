# -*- sh -*-

AC_MSG_CHECKING([for Network Audio System])
AC_CHECK_HEADERS([audio/audiolib.h],,AC_PLUGIN_DISABLE)
AC_PLUGIN_SEARCH_LIBS([AuOpenServer],[audio])
