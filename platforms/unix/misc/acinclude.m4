# Local autoconf macros for configuring Unix Squeak		-*- sh -*-
# 
#   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
#      authors/contributors listed elsewhere in this file.
#   All rights reserved.
#   
#   This file is part of Unix Squeak.
# 
#   This file is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.
#   
#   You may use and/or distribute this file ONLY as part of Squeak, under
#   the terms of the Squeak License as described in `LICENSE' in the base of
#   this distribution, subject to the following restrictions:
# 
#   1. The origin of this software must not be misrepresented; you must not
#      claim that you wrote the original software.  If you use this software
#      in a product, an acknowledgment to the original author(s) (and any
#      other contributors mentioned herein) in the product documentation
#      would be appreciated but is not required.
# 
#   2. This notice may not be removed or altered in any source distribution.
# 
#   Using or modifying this file for use in any context other than Squeak
#   changes these copyright conditions.  Read the file `COPYING' in the base
#   of the distribution before proceeding with any such use.
# 
#   You are STRONGLY DISCOURAGED from distributing a modified version of
#   this file under its original name without permission.  If you must
#   change it, rename it first.
# 
# Author: Ian.Piumarta@INRIA.Fr
# 
# Last edited: 2001-02-12 13:59:05 by piumarta on rnd10-51.rd.wdi.disney.com

AC_SUBST(NM)
AC_SUBST(LD)

AC_DEFUN(AC_NEED_SUNOS_H,
[case "$host" in
  *-sunos*)	AC_DEFINE(NEED_SUNOS_H, 1)
esac])

AC_DEFUN(AC_PROG_CC_WALL,
[AC_PROG_CC
test "$GCC" = yes && WFLAGS="-Wall"
AC_SUBST(WFLAGS)])

AC_DEFUN(AC_GNU_OPT,
[AC_MSG_CHECKING([for optimization flags])
ac_optflags="no"
if test "$GCC" = yes; then
  case $host in
  i?86-*)
    ac_optflags="-fomit-frame-pointer"
    ;;
  esac
fi
if test "$ac_optflags" = "no"; then
  AC_MSG_RESULT([(none)])
else
  CFLAGS="$CFLAGS $ac_optflags"
  AC_MSG_RESULT("$ac_optflags")
fi])

AC_DEFUN(AC_GNU_INTERP,
[INTERP="interp"
AC_SUBST(INTERP)
AC_PROG_AWK
AC_MSG_CHECKING(whether we can gnuify interp.c)
if test "$GCC" = "yes"; then
  INTERP="gnu-$INTERP"; AC_MSG_RESULT(yes)
else
  AC_MSG_RESULT(no)
fi])

AC_DEFUN(AC_PROG_AS_GNU,
[AC_CHECK_PROG(AS,as,as)
AC_MSG_CHECKING(for GNU as)
case "$GAS" in
yes|no) ;;
*) if test "$AS" = "as" && as -v /dev/null </dev/null 2>&1 | fgrep -i gnu >/dev/null
   then GAS=yes
   else GAS=no
   fi ;;
esac
AC_MSG_RESULT($GAS)])

AC_DEFUN(AC_CHECK_ATEXIT,
[AC_CACHE_CHECK([for atexit or on_exit], ac_cv_atexit,
  AC_TRY_COMPILE([#include <stdlib.h>],[atexit(0);], ac_cv_atexit="atexit",
  AC_TRY_COMPILE([#include <stdlib.h>],[on_exit(0);], ac_cv_atexit="on_exit",
  ac_cv_atexit="no")))
if test "$ac_cv_atexit" != "no"; then
  AC_DEFINE_UNQUOTED(AT_EXIT, $ac_cv_atexit)
fi])

AC_DEFUN(AC_CHECK_SOCKLEN_T,
[AC_CACHE_CHECK([for socklen_t in sys/socket.h], ac_cv_socklen_t,
  AC_TRY_COMPILE([#include <sys/socket.h>],[sizeof(socklen_t);],
    ac_cv_socklen_t="yes", ac_cv_socklen_t="no"))
test "$ac_cv_socklen_t" != "yes" && AC_DEFINE(socklen_t, int)])

AC_DEFUN(AC_CHECK_TZSET,
[AC_CACHE_CHECK([for tzset], ac_cv_tzset,
  AC_TRY_COMPILE([#include <time.h>],[tzet();],
    ac_cv_tzset="yes", ac_cv_tzset="no"))
test "$ac_cv_tzset" != "no" && AC_DEFINE(HAVE_TZSET)])

AC_DEFUN(AC_CHECK_GMTOFF,
[AC_CACHE_CHECK([for gmtoff in struct tm], ac_cv_tm_gmtoff,
  AC_TRY_COMPILE([#include <time.h>],[struct tm tm; tm.tm_gmtoff;],
    ac_cv_tm_gmtoff="yes", ac_cv_tm_gmtoff="no"))
test "$ac_cv_tm_gmtoff" != "no" && AC_DEFINE(HAVE_TM_GMTOFF)])

AC_DEFUN(AC_CHECK_TIMEZONE,
[AC_CACHE_CHECK([for timezone and daylight variables], ac_cv_timezone,
  AC_TRY_COMPILE([extern long timezone; extern int daylight;],[timezone;daylight;],
    ac_cv_timezone="yes", ac_cv_timezone="no"))
test "$ac_cv_timezone" != "no" && AC_DEFINE(HAVE_TIMEZONE)])

AC_DEFUN(AC_CHECK_GETHOSTNAME,
[AC_CACHE_CHECK([for gethostname in unistd.h], ac_cv_gethostname_p,
  AC_TRY_COMPILE([#include <unistd.h>],[return (int)gethostname;],
    ac_cv_gethostname_p="yes", ac_cv_gethostname_p="no"))
test "$ac_cv_gethostname_p" = "no" && AC_DEFINE(NEED_GETHOSTNAME_P)])

# XXX this used to be used in just one place: the HAVE_OSS macro.  But
# why?!  I observed a wierd bug using the variable and bash 2.05a.0(1),
# so I'm changing to just using raw "test"  -Lex
if test -x /bin/test; then
  test=/bin/test
else
  if test -x /usr/bin/test; then
    test=/usr/bin/test
  else
    test=test
  fi
fi

AC_DEFUN(AC_HAVE_OSS,
[AC_CACHE_CHECK([for Open Sound System], ac_cv_oss,
  AC_TRY_COMPILE([#include <sys/soundcard.h>],[OPEN_SOUND_SYSTEM;],
    ac_cv_oss="yes", ac_cv_oss="no"))
if test "$ac_cv_oss" = "yes" -a -e /dev/dsp; then
  AC_DEFINE(HAVE_OSS,1)
fi])

AC_DEFUN(AC_FIND_OSS_DEVICE,
[OSS_DEVICE=notfound
AC_CHECK_FILE([/dev/dsp], [OSS_DEVICE=/dev/dsp])
if test $OSS_DEVICE = notfound
then
  AC_MSG_ERROR(No OSS device found!  Select another audio interface.)
fi
AC_MSG_NOTICE([using OSS_DEVICE: $OSS_DEVICE])
AC_DEFINE_UNQUOTED(OSS_DEVICE, "$OSS_DEVICE")])

AC_DEFUN(AC_HAVE_NAS,
[AC_CACHE_CHECK([for Network Audio System], ac_cv_nas,
  AC_TRY_COMPILE([#include <audio/audio.h>],[AuElementNotifyKindLowWater;],
    ac_cv_nas="yes", ac_cv_nas="no"))
if test "$ac_cv_nas" = "yes"; then
  AC_DEFINE(HAVE_NAS,1)
  NAS_LIBS="-laudio -lXt"
fi])

AC_DEFUN(AC_C_BYTEORDER,
[AC_C_BIGENDIAN
if test $ac_cv_c_bigendian != yes
then CFLAGS="$CFLAGS -DLSB_FIRST=1"
fi])

AC_DEFUN(AC_C_DOUBLE_ALIGNMENT,
[AC_CACHE_CHECK([whether misaligned access to doubles is ok], ac_cv_double_align,
  AC_TRY_RUN([f(int i){*(double *)i=*(double *)(i+4);}
              int main(){char b[[12]];f(b);return 0;}],
    ac_cv_double_align="yes", ac_cv_double_align="no"))
test "$ac_cv_double_align" = "no" && AC_DEFINE(DOUBLE_WORD_ALIGNMENT)])

AC_DEFUN(AC_C_DOUBLE_ORDER,
[AC_CACHE_CHECK([whether doubles are stored in Squeak order], ac_cv_double_order,
  AC_TRY_RUN([main(){ double d= 1.0; return *(int *)&d == 0;}],
    ac_cv_double_order="yes", ac_cv_double_order="no"))
test "$ac_cv_double_order" = "no" && AC_DEFINE(DOUBLE_WORD_ORDER)])

# this assumes that libtool has already been configured and built --
# if not then err on the side of conservatism.
AC_DEFUN(AC_MODULE_LIB_PREFIX,
[AC_CACHE_CHECK([for prefix to use for loadable modules], ac_cv_module_prefix,
if test -x ./libtool &&
   test "`./libtool --config | fgrep need_lib_prefix`" = "need_lib_prefix=no"
then ac_cv_module_prefix="(none)";
else ac_cv_module_prefix="lib"
fi)
AC_DEFINE_UNQUOTED(SQ_MODULE_PREFIX,"$mkfrags_lib_prefix")
test "$ac_cv_module_prefix" = lib && mkfrags_lib_prefix=lib])

AC_DEFUN(AC_64BIT_ARCH,
[AC_MSG_CHECKING(for compiler flags to force 32-bit addresses)
case $host in
  alpha*)
    CFLAGS_32="-taso"
    test "$GCC" = "yes" && CC="\$(utldir)/decgcc"
    ;;
esac
AC_MSG_RESULT($CFLAGS_32)])

