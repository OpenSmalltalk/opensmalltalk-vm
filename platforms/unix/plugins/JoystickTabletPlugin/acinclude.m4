# -*- sh -*-

# Currently, the plugin is Linux-specific.
AC_CHECK_HEADER([linux/input.h],[
    AC_DEFINE([HAVE_LINUX_INPUT_H],[1], [linux/input.h])
],[
    AC_PLUGIN_DISABLE
])
