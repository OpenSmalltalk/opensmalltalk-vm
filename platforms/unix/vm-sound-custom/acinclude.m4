# -*- sh -*-

AC_MSG_CHECKING([for custom sound support])

AC_ARG_WITH(custom-sound,
[  --with-custom-sound     enable custom sound support [default=disabled]],
  [have_snd_custom="$withval"],
  [have_snd_custom="no"])

if test "$have_snd_custom" = "yes"; then
  # check for libraries, headers, etc., here...
  AC_MSG_RESULT([yes])
else
  AC_MSG_RESULT([no])
  AC_PLUGIN_DISABLE
fi
