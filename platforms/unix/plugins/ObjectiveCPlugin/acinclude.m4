# -*- sh -*-

AC_MSG_CHECKING([for Objective C support])

case $host_os in
  darwin-DSIABLED*)
    AC_MSG_RESULT(yes)
    ;;
  *)
    AC_MSG_RESULT(no)
    AC_PLUGIN_DISABLE
    ;;
esac
