# -*- sh -*-

AC_MSG_CHECKING([for SunOS/Solaris audio])
AC_TRY_COMPILE([#include <sys/audioio.h>],[AUDIO_SUNVTS;],[
  AC_MSG_RESULT(yes)
  AC_DEFINE_UNQUOTED(HAVE_SYS_AUDIOIO_H,1, [SunOS/Solaris audio])
],[
  AC_TRY_COMPILE([#include <sun/audioio.h>],[AUDIO_SUNVTS;],[
    AC_MSG_RESULT(yes)
    AC_DEFINE_UNQUOTED(HAVE_SUN_AUDIOIO_H,1, [Sun audioio])
  ],[
    AC_MSG_RESULT(no)
    AC_PLUGIN_DISABLE
  ])
])
