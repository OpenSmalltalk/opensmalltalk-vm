# -*- sh -*-

AC_MSG_CHECKING([for Mac OS X CoreAudio])
AC_TRY_COMPILE([#include <CoreAudio/CoreAudio.h>],[kAudioHardwareNoError;],[
  AC_MSG_RESULT(yes)

],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
