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
  AC_CHECK_LIB(iconv, iconv_open, ac_cv_iconv=yes, [
    AC_CHECK_LIB(iconv, libiconv_open, ac_cv_iconv=yes, ac_cv_iconv=no)
  ])
  if test $ac_cv_iconv = yes; then
    LIBS="$LIBS -liconv"
  fi
])

AC_CHECK_HEADERS(iconv.h)
AC_ICONV
AC_LANGINFO_CODESET

case $host_os in
  darwin*) LIBS="$LIBS -framework CoreFoundation";;
  *)       ;;
esac
