# -*- sh -*-

AC_MSG_CHECKING([for custom display support])

AC_ARG_WITH(custom-display,
[  --with-custom-display   enable custom window support [default=disabled]],
  [have_dpy_custom="$withval"],
  [have_dpy_custom="no"])

if test "$have_dpy_custom" = "yes"; then
  # check for libraries, headers, etc., here...
  AC_MSG_RESULT([yes])
else
  AC_MSG_RESULT([no])
  AC_PLUGIN_DISABLE
fi
