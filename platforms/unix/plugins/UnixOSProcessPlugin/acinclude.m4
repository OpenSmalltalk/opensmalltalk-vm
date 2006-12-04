AC_CHECK_FUNC(unsetenv, AC_DEFINE(HAVE_UNSETENV, 1))
AC_PLUGIN_CHECK_LIB(pthread, pthread_kill)
