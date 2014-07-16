# -*- sh -*-

AC_MSG_CHECKING([for PangoCairo libraries])
AC_TRY_COMPILE([#include <pango/pangocairo.h>],[{}],[
  AC_MSG_RESULT(yes)
],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
