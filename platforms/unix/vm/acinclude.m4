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

AC_DEFUN([AC_ICONV], [
  AC_CHECK_FUNC(_dyld_present,[],[
    AC_CHECK_LIB(iconv, iconv_open, ac_cv_iconv=yes, [
      AC_CHECK_LIB(iconv, libiconv_open, ac_cv_iconv=yes, ac_cv_iconv=no)
    ])
    if test $ac_cv_iconv = yes; then
      LIBS="$LIBS -liconv"
    fi
  ])
])

AC_ARG_ENABLE(iconv,
[  --disable-iconv         disable iconv support [default=enabled]],
  [with_iconv="$withval"],
  [with_iconv="yes"])


case $host_os in
  darwin*) LIBS="$LIBS -framework CoreFoundation -framework CoreServices";;
  *)       ;;
esac

if test "$with_iconv" = "yes"; then
  AC_CHECK_HEADERS(iconv.h)
  AC_ICONV
  AC_LANGINFO_CODESET
else
  AC_MSG_RESULT([******** disabling iconv])
fi

AC_CHECK_FUNC(nanosleep, [
  AC_DEFINE(HAVE_NANOSLEEP, 1, [Is nanosleep available])
  AC_SUBST(HAVE_NANOSLEEP)
])
