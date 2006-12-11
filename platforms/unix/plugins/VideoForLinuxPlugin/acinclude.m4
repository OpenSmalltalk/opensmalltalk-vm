AC_MSG_CHECKING([for VideoForLinux support])
AC_TRY_COMPILE([
  #include <stdlib.h>
  #include <linux/videodev.h>
],[;],[
  AC_MSG_RESULT(yes)
],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
