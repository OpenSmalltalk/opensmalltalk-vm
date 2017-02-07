# Local autoconf macros for configuring Unix Squeak		-*- sh -*-
# 
#   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
#                              listed elsewhere in this file.
#   All rights reserved.
#   
#   This file is part of Unix Squeak.
# 
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
# 
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
# 
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.
# 
# Author: Ian.Piumarta@squeakland.org
# 
# Last edited: Tue Jan 26 11:07:40 PST 2010 by eliot

AC_DEFUN([AC_CHECK_VMM_DIR],[
  AC_MSG_CHECKING([sanity of generated src directory])
  vmmcheck () {
    if test ! ${2} ${3}; then
      AC_MSG_RESULT(bad)
      echo "missing ${1}: ${3}"
      exit 1
    fi
  }
  vmmcheck dir  -d ${vmmcfg}
  vmmcheck file -f ${vmmcfg}/plugins.int
  vmmcheck file -f ${vmmcfg}/plugins.ext
  vmmcheck dir  -d ${vmmdir}
  vmmcheck dir  -d ${vmpdir}
  vmmcheck dir  -d ${vmmdir}/vm
  vmmcheck file -f ${vmmdir}/vm/interp.h
  vmmcheck file -f ${vmmdir}/vm/vmCallback.h
  if test "$cogit" = yes ; then
	  vmmcheck file -f ${vmmdir}/vm/cogit.c
	  vmmcheck file -f ${vmmdir}/vm/cogit.h
	  vmmcheck file -f ${vmmdir}/vm/cogmethod.h
	  vmmcheck file -f ${vmmdir}/vm/cointerp.c
	  vmmcheck file -f ${vmmdir}/vm/cointerp.h
	  vmmcheck file -f ${vmmdir}/vm/gcc3x-cointerp.c
  else
	  vmmcheck file -f ${vmmdir}/vm/interp.c
	  vmmcheck file -f ${vmmdir}/vm/gcc3x-interp.c
  fi
  AC_MSG_RESULT(okay)])


AC_DEFUN([AC_VM_VERSION],[
# VM_MAJOR=$1
# VM_MINOR=$2
# VM_RELEASE=$3
# SQ_MAJOR=$4
# SQ_MINOR=$5
# SQ_UPDATE=$6
])



AC_DEFUN([AC_CHECK_VERSION],[
  gendir="${vmmdir}/vm"
  version=`${cfgdir}/version ${gendir}/cointerp.c`
  SQ_MAJOR=`echo ${version} | cut -d ' ' -f 1`
  SQ_MINOR=`echo ${version} | cut -d ' ' -f 2`
  SQ_UPDATE=`echo ${version} | cut -d ' ' -f 3`
])

AC_SUBST(NM)
AC_SUBST(LD)

AC_DEFUN([AC_REQUIRE_SIZEOF],[
  AC_MSG_CHECKING("size of $1")
  AC_TRY_RUN([#include <sys/types.h>
	      int main(){return(sizeof($1) == $2)?0:1;}],
    AC_MSG_RESULT("okay"),
    AC_MSG_RESULT("bad")
    AC_MSG_ERROR("one or more basic data types has an incompatible size: giving up"))])

# Try to find a 64-bit integer data type.
# NOTE: `long long' is 64 bits in ANSI C99 [ISO/IEC 9899:1999 (E)].

AC_DEFUN([AC_CHECK_INT64_T],[
  AC_CACHE_CHECK([for 64-bit integer type],ac_cv_int64_t,
    AC_TRY_RUN([int main(){return(sizeof(long) == 8)?0:1;}],
      ac_cv_int64_t="long",
      AC_TRY_RUN([int main(){return(sizeof(long long) == 8)?0:1;}],
        ac_cv_int64_t="long long",
        ac_cv_int64_t="no")))
  if test "$ac_cv_int64_t" = ""; then
    AC_MSG_ERROR([could not find a 64-bit integer type])
  fi
  SQUEAK_INT64_T="$ac_cv_int64_t"
  AC_DEFINE_UNQUOTED(squeakInt64, $ac_cv_int64_t, [64bit signed integer])])
  

AC_DEFUN([AC_NEED_SUNOS_H],
[case "$host" in
  *-sunos*)	AC_DEFINE(NEED_SUNOS_H, 1, [building on SunOS])
esac])


AC_DEFUN([AC_PROG_CC_WALL],
[AC_PROG_CC
test "$GCC" = yes && WFLAGS="-Wall -Wno-unknown-pragmas"
AC_SUBST(WFLAGS)])

AC_DEFUN([AC_GNU_OPT],
[AC_MSG_CHECKING([for $host_cpu optimisation flags])
ac_optflags="no"
if test "$GCC" = yes; then
  case $host_cpu in
# Leave this to the configure command
# i?86)
#   ac_optflags="-fomit-frame-pointer"
#   ;;
  powerpc|ppc)
    ac_optflags="-O3 -funroll-loops -mcpu=750 -mno-fused-madd"
    ;;
  esac
  AC_DEFINE(VM_BUILD_STRING, ["Unix built on "__DATE__ " "__TIME__" Compiler: "__VERSION__], [build string])
else
  ac_optflags="-O"
  ac_vm_build_date="`date`"
  AC_DEFINE(VM_BUILD_STRING, ["Unix built on ${ac_vm_build_date}"], [build string])
fi
if test "$ac_optflags" = "no"; then
  AC_MSG_RESULT([(none)])
else
  CFLAGS="$CFLAGS $ac_optflags"
  AC_MSG_RESULT("$ac_optflags")
fi])

AC_DEFUN([AC_GNU_INTERP],
[if test -z "$INTERP" ; then if test "$cogit" = yes ; then INTERP="cointerp"; else INTERP="interp"; fi; fi
AC_SUBST(INTERP)
AC_PROG_AWK
AC_MSG_CHECKING(whether we can compile gcc3x-$INTERP)
if test "$GCC" = "yes"; then
  INTERP="gcc3x-$INTERP"; AC_MSG_RESULT(yes)
else
  AC_MSG_RESULT(no)
fi])

AC_DEFUN([AC_PROG_AS_GNU],
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

AC_DEFUN([AC_CHECK_ATEXIT],
[AC_CACHE_CHECK([for atexit or on_exit], ac_cv_atexit,
  AC_TRY_COMPILE([#include <stdlib.h>],[atexit(0);], ac_cv_atexit="atexit",
  AC_TRY_COMPILE([#include <stdlib.h>],[on_exit(0);], ac_cv_atexit="on_exit",
  ac_cv_atexit="no")))
if test "$ac_cv_atexit" != "no"; then
  AC_DEFINE_UNQUOTED([AT_EXIT], [$ac_cv_atexit], [Is atexit present])
fi])

AC_DEFUN([AC_CHECK_SOCKLEN_T],
[AC_CACHE_CHECK([for socklen_t in sys/socket.h], ac_cv_socklen_t,
  AC_TRY_COMPILE([#include <sys/socket.h>],[sizeof(socklen_t);],
    ac_cv_socklen_t="yes", ac_cv_socklen_t="no"))
test "$ac_cv_socklen_t" != "yes" && AC_DEFINE(socklen_t, int, [socklen size])])

AC_DEFUN([AC_CHECK_TZSET],
[AC_CACHE_CHECK([for tzset], ac_cv_tzset,
  AC_TRY_COMPILE([#include <time.h>],[tzet();],
    ac_cv_tzset="yes", ac_cv_tzset="no"))
test "$ac_cv_tzset" != "no" && AC_DEFINE(HAVE_TZSET, [], [tzset available])])

AC_DEFUN([AC_CHECK_GMTOFF],
[AC_CACHE_CHECK([for gmtoff in struct tm], ac_cv_tm_gmtoff,
  AC_TRY_COMPILE([#include <time.h>],[struct tm tm; tm.tm_gmtoff;],
    ac_cv_tm_gmtoff="yes", ac_cv_tm_gmtoff="no"))
test "$ac_cv_tm_gmtoff" != "no" && AC_DEFINE(HAVE_TM_GMTOFF, [], [tm_gmtoff present])])

AC_DEFUN([AC_CHECK_TIMEZONE],
[AC_CACHE_CHECK([for timezone and daylight variables], ac_cv_timezone,
  AC_TRY_COMPILE([extern long timezone; extern int daylight;],[timezone;daylight;],
    ac_cv_timezone="yes", ac_cv_timezone="no"))
test "$ac_cv_timezone" != "no" && AC_DEFINE(HAVE_TIMEZONE, [], [timezone present])])

AC_DEFUN([AC_CHECK_GETHOSTNAME],
[AC_CACHE_CHECK([for gethostname in unistd.h], ac_cv_gethostname_p,
  AC_TRY_COMPILE([#include <unistd.h>],[return (int)gethostname;],
    ac_cv_gethostname_p="yes", ac_cv_gethostname_p="no"))
test "$ac_cv_gethostname_p" = "no" && AC_DEFINE(NEED_GETHOSTNAME_P, [], [gethostname_p])])


if test -x /bin/test; then
  test=/bin/test
else
  if test -x /usr/bin/test; then
    test=/usr/bin/test
  else
    test=test
  fi
fi


AC_DEFUN([AC_C_BYTEORDER],
[AC_C_BIGENDIAN
if test $ac_cv_c_bigendian != yes
then CFLAGS="$CFLAGS -DLSB_FIRST=1"
fi])


AC_DEFUN([AC_C_DOUBLE_ALIGNMENT],
[AC_CACHE_CHECK([whether unaligned access to doubles is ok], ac_cv_double_align,
  AC_TRY_RUN([f(int i){*(double *)i=*(double *)(i+4);}
              int main(){char b[[12]];f(b);return 0;}],
    ac_cv_double_align="yes", ac_cv_double_align="no"))
test "$ac_cv_double_align" = "no" && AC_DEFINE(DOUBLE_WORD_ALIGNMENT, [], [Unaligned double access])])

# this assumes that libtool has already been configured and built --
# if not then err on the side of conservatism.
AC_DEFUN([AC_MODULE_LIB_PREFIX],
[AC_CACHE_CHECK([for prefix to use for loadable modules], ac_cv_module_prefix,
if test -x ./libtool &&
   test "`./libtool --config | fgrep need_lib_prefix`" = "need_lib_prefix=no"
then ac_cv_module_prefix="(none)";
else ac_cv_module_prefix="lib"
fi)
AC_DEFINE_UNQUOTED(VM_MODULE_PREFIX,"$mkfrags_lib_prefix", [VM module prefix])
test "$ac_cv_module_prefix" = lib && mkfrags_lib_prefix=lib])

AC_DEFUN([AC_64BIT_ARCH],
[AC_MSG_CHECKING(for compiler flags to force 32-bit addresses)
case $host in
  alpha*)
    CFLAGS_32="-taso"
    test "$GCC" = "yes" && CC="\$(utldir)/decgcc"
    ;;
esac
AC_MSG_RESULT($CFLAGS_32)])


### plugin support


# AC_PLUGIN_SUBST(varname,value)

AC_DEFUN([AC_PLUGIN_DISABLE_PLUGIN],[
  AC_MSG_RESULT([******** disabling $1])
  disabled_plugins="${disabled_plugins} $1"])
  
AC_DEFUN([AC_PLUGIN_DISABLE],[
  AC_PLUGIN_DISABLE_PLUGIN(${plugin})])
  
AC_DEFUN([AC_PLUGIN_USE_LIB],[
  plibs="${plibs} $1"])

AC_DEFUN([AC_PLUGIN_DEFINE_UNQUOTED],[
  echo 's%[\['$1'\]]%'$2'%g' >> ${plugin}.sub])

# AC_PLUGIN_SEARCH_LIBS(function,libs...)

AC_DEFUN([AC_PLUGIN_SEARCH_LIBS],[
  AC_SEARCH_LIBS($1,$2,,
    AC_MSG_RESULT([******** disabling ${plugin} due to missing libraries])
    disabled_plugins="${disabled_plugins} ${plugin}")])

# AC_PLUGIN_CHECK_LIB(lib,func,ok,bad)

AC_DEFUN([AC_PLUGIN_CHECK_LIB],[
  AC_CHECK_LIB($1,$2,
    plibs="${plibs} $1",
    AC_MSG_RESULT([******** disabling ${plugin} due to missing libraries])
    disabled_plugins="${disabled_plugins} ${plugin}")])

# Recent Unix stuff
m4_include([ax_have_epoll.m4])
