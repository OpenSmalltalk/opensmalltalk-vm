AC_HAVE_HEADERS(util.h libutil.h pty.h stropts.h)

AC_SEARCH_LIBS(openpty, util,
  AC_DEFINE(HAVE_OPENPTY, 1),[
  if test -r /dev/ptmx; then
    AC_CHECK_FUNC(grantpt, AC_DEFINE(HAVE_UNIX98_PTYS, 1))
  fi])
