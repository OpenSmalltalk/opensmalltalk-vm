# Local autoconf macros for configuring Unix Squeak		-*- sh -*-
# 
#   Copyright (C) 1996-2002 Ian Piumarta and other authors/contributors
#     as listed elsewhere in this file.
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
#   2. This notice must not be removed or altered in any source distribution.
# 
#   Using (or modifying this file for use) in any context other than Squeak
#   changes these copyright conditions.  Read the file `COPYING' in the
#   directory `platforms/unix/doc' before proceeding with any such use.
# 
#   You are not allowed to distribute a modified version of this file
#   under its original name without explicit permission to do so.  If
#   you change it, rename it.
# 
# Author: Ian.Piumarta@INRIA.Fr
# 
# Last edited: 2003-02-09 02:40:58 by piumarta on emilia.inria.fr

AC_DEFUN(AC_CHECK_VMM_DIR,[
  AC_MSG_CHECKING([sanity of VMMaker src directory])
  vmmcheck () {
    if test ! ${2} ${3}; then
      AC_MSG_RESULT(bad)
      echo "missing ${1}: ${3}"
      exit 1
    fi
  }
  vmmcheck dir  -d ${vmmdir}
  vmmcheck file -f ${vmmdir}/plugins.int
  vmmcheck file -f ${vmmdir}/plugins.ext
  vmmcheck dir  -d ${vmmdir}/plugins
  vmmcheck dir  -d ${vmmdir}/vm
  vmmcheck file -f ${vmmdir}/vm/interp.c
  vmmcheck file -f ${vmmdir}/vm/sqNamedPrims.h
  vmmcheck dir  -d ${vmmdir}/plugins
  AC_MSG_RESULT(okay)])


AC_DEFUN(AC_VM_VERSION,[
  VM_MAJOR=$1
  VM_MINOR=$2
  VM_RELEASE=$3
  SQ_MAJOR=$4
  SQ_MINOR=$5
  SQ_UPDATE=$6
])



AC_DEFUN(AC_CHECK_VERSION,[
  gendir="${vmmdir}/vm"
  version=`${cfgdir}/version ${gendir}/interp.c`
  SQ_MAJOR=`echo ${version} | cut -d ' ' -f 1`
  SQ_MINOR=`echo ${version} | cut -d ' ' -f 2`
  SQ_UPDATE=`echo ${version} | cut -d ' ' -f 3`
])

AC_SUBST(NM)
AC_SUBST(LD)

AC_DEFUN(AC_REQUIRE_SIZEOF,[
  AC_MSG_CHECKING("size of $1")
  AC_TRY_RUN([#include <sys/types.h>
	      int main(){return(sizeof($1) == $2)?0:1;}],
    AC_MSG_RESULT("okay"),
    AC_MSG_RESULT("bad")
    AC_MSG_ERROR("one or more basic data types has an incompatible size: giving up"))])

# Try to find a 64-bit integer data type.
# NOTE: `long long' is 64 bits in ANSI C99 [ISO/IEC 9899:1999 (E)].

AC_DEFUN(AC_CHECK_INT64_T,[
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
  AC_DEFINE_UNQUOTED(squeakInt64, $ac_cv_int64_t)])
  

AC_DEFUN(AC_NEED_SUNOS_H,
[case "$host" in
  *-sunos*)	AC_DEFINE(NEED_SUNOS_H, 1)
esac])


AC_DEFUN(AC_PROG_CC_WALL,
[AC_PROG_CC
test "$GCC" = yes && WFLAGS="-Wall"
AC_SUBST(WFLAGS)])

AC_DEFUN(AC_GNU_OPT,
[AC_MSG_CHECKING("for optimization flags")
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
  case "$GAWK" in
  no) ;;
  yes)  AWK=awk; GAWK=yes ;;
  gawk) AWK=gawk; GAWK=yes ;;
  *) if test -x /usr/bin/gawk; then
       GAWK=yes
       AWK=gawk
     else
       if $AWK --version /dev/null </dev/null 2>&1 | fgrep -i gnu >/dev/null
       then GAWK=yes
       else GAWK=no
       fi
     fi ;;
  esac
  if test "$GAWK" = "yes"
  then INTERP="gnu-$INTERP"; AC_MSG_RESULT(yes)
  else AC_MSG_RESULT(no)
  fi
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


if test -x /bin/test; then
  test=/bin/test
else
  if test -x /usr/bin/test; then
    test=/usr/bin/test
  else
    test=test
  fi
fi


AC_DEFUN(AC_HAVE_NAS,[AC_MSG_CHECKING([for Network Audio System])
  AC_TRY_COMPILE([#include <audio/audio.h>],[AuElementNotifyKindLowWater;],
    ac_cv_nas="yes", ac_cv_nas="no")
  AC_MSG_RESULT($ac_cv_nas)])

AC_DEFUN(AC_HAVE_OSS,[AC_MSG_CHECKING([for Open Sound System])
  AC_TRY_COMPILE([#include <sys/soundcard.h>],[OPEN_SOUND_SYSTEM;],
    ac_cv_oss="yes", ac_cv_oss="no")
  AC_MSG_RESULT($ac_cv_oss)])

AC_DEFUN(AC_HAVE_SUN,[AC_MSG_CHECKING([for SunOS/Solaris audio])
 AC_TRY_COMPILE([#include <sys/audioio.h>],[AUDIO_SUNVTS;],
   ac_cv_sun="yes"
   AC_DEFINE_UNQUOTED(HAVE_SYS_AUDIOIO_H,1),
   AC_TRY_COMPILE([#include <sun/audioio.h>],[AUDIO_SUNVTS;],
     ac_cv_sun="yes"
     AC_DEFINE_UNQUOTED(HAVE_SUN_AUDIOIO_H,1),
       ac_cv_sun="no"))
 AC_MSG_RESULT($ac_cv_sun)])


AC_DEFUN(AC_CHECK_SOUND,[
  use_audio=""
  AC_MSG_CHECKING([for audio support])
  AC_MSG_RESULT($with_audio)
  if test "$with_audio" = "auto" -o "$with_audio" = "oss"; then
    AC_HAVE_OSS
    if test "$ac_cv_oss" = "yes"; then use_audio=oss; with_audio=oss; fi
  fi
  if test "$with_audio" = "auto" -o "$with_audio" = "sun"; then
    AC_HAVE_SUN
    if test "$ac_cv_sun" = "yes"; then use_audio=sun; with_audio=sun; fi
  fi
  if test "$with_audio" = "auto" -o "$with_audio" = "nas"; then
    AC_HAVE_NAS
    if test "$ac_cv_nas" = "yes"; then use_audio=nas; with_audio=nas; fi
  fi
  if test "$with_audio" = "none"; then use_audio=none; fi
  if test "$use_audio" = ""; then  
    AC_MSG_RESULT([******** AUDIO DISABLED (no support found for: $with_audio)])
    use_audio=none
  fi
  case $use_audio in
    nas)  AC_DEFINE(USE_AUDIO_NAS,1)
	  LIBS="$LIBS -laudio -lXt" ;;
    oss)  AC_DEFINE(USE_AUDIO_OSS,1) ;;
    sun)  AC_DEFINE(USE_AUDIO_SUN,1)
	  AC_HAVE_HEADERS(sys/audioio.h) ;;
    none) AC_DEFINE(USE_AUDIO_NONE,1) ;;
    *)    echo; echo "this cannot happen"; echo; exit 1 ;;
  esac
])


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
AC_DEFINE_UNQUOTED(VM_MODULE_PREFIX,"$mkfrags_lib_prefix")
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


### plugin support


# AC_PLUGIN_SUBST(varname,value)

AC_DEFUN(AC_PLUGIN_DISABLE_PLUGIN,[
  AC_MSG_RESULT([******** disabling $1])
  disabled_plugins="${disabled_plugins} $1"])
  
AC_DEFUN(AC_PLUGIN_DISABLE,[
  AC_PLUGIN_DISABLE_PLUGIN(${plugin})])
  
AC_DEFUN(AC_PLUGIN_USE_LIB,[
  plibs="${plibs} $1"])

AC_DEFUN(AC_PLUGIN_DEFINE_UNQUOTED,[
  echo 's%[\['$1'\]]%'$2'%g' >> ${plugin}.sub])

# AC_PLUGIN_SEARCH_LIBS(function,libs...)

AC_DEFUN(AC_PLUGIN_SEARCH_LIBS,[
  AC_SEARCH_LIBS($1,$2,,
    AC_MSG_RESULT([******** disabling ${plugin} due to missing libraries])
    disabled_plugins="${disabled_plugins} ${plugin}")])

# AC_PLUGIN_CHECK_LIB(lib,func,ok,bad)

AC_DEFUN(AC_PLUGIN_CHECK_LIB,[
  AC_CHECK_LIB($1,$2,
    plibs="${plibs} $1",
    AC_MSG_RESULT([******** disabling ${plugin} due to missing libraries])
    disabled_plugins="${disabled_plugins} ${plugin}")])
