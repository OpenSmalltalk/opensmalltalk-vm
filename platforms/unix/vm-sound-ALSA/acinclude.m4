# -*- sh -*-

AC_MSG_CHECKING([for Advanced Linux Sound Architecture])
AC_TRY_COMPILE([#include <alsa/asoundlib.h>],[(void)snd_pcm_open;],[
  AC_MSG_RESULT(yes)
],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
