# -*- sh -*-

AC_MSG_CHECKING([for PulseAudio])
AC_TRY_COMPILE([#include <pulse/simple.h>],[(void)pa_simple_new;],[
  AC_MSG_RESULT(yes)
],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
