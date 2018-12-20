# -*- sh -*-

AC_MSG_CHECKING([for Network Audio System])
AC_TRY_COMPILE([#include <audio/audio.h>],[AuElementNotifyKindLowWater;],[
  AC_MSG_RESULT(yes)
],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
