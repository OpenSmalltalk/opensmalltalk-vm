# -*- sh -*-

AC_MSG_CHECKING([for PulseAudio])
AC_CHECK_HEADERS(pulse/simple.h,,AC_PLUGIN_DISABLE)
AC_PLUGIN_SEARCH_LIBS([pa_simple_new],[pulse-simple pulse])
