AC_DEFUN([AC_LANGINFO_CODESET], [
  AC_CACHE_CHECK([for nl_langinfo and CODESET], ac_cv_langinfo_codeset,
    [AC_TRY_LINK([#include <langinfo.h>], [char *cs= nl_langinfo(CODESET);],
      ac_cv_langinfo_codeset=yes,
      ac_cv_langinfo_codeset=no)
    ])
  if test $ac_cv_langinfo_codeset = yes; then
    AC_DEFINE(HAVE_LANGINFO_CODESET, 1,
      [Define if you have <langinfo.h> and nl_langinfo(CODESET).])
  fi
  AC_SUBST(HAVE_LANGINFO_CODESET)
])

AC_LANGINFO_CODESET

case $host_os in
  darwin*) LIBS="$LIBS -framework CoreFoundation -framework CoreServices";;
  *)       
    AC_ARG_ENABLE(iconv,
      AC_HELP_STRING([--disable-iconv] [disable iconv support (default=enabled)]),
      [with_iconv="$enableval"],
      [with_iconv="yes"])
    if test "$with_iconv" = "yes"; then
      AC_CHECK_HEADERS([iconv.h])
      AC_SEARCH_LIBS([iconv_open], [iconv], [], [
        AC_SEARCH_LIBS([libiconv_open], [iconv])])
    else
      AC_MSG_RESULT([******** disabling iconv])
    fi
    ;;
esac

