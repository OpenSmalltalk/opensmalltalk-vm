# -*- sh -*-


AC_MSG_CHECKING([for Advanced Linux Sound Architecture])
AC_CHECK_HEADERS(alsa/asoundlib.h,,AC_PLUGIN_DISABLE)
AC_PLUGIN_SEARCH_LIBS([snd_pcm_open],[asound])
