# configure.in (v3.2) for Unix Squeak				-*- sh -*-
# 
# Process this file with autoconf to produce a configure script

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
# Last edited: 2001-07-08 22:29:16 PDT by piumarta on emilia.inria.fr

# Hacked by Tim Rowledge (tim@sumeru.stanford.edu) to suport VMMaker system

# Hacked further by Lex Spoon (lex@cc.gatech.edu) for various things.
# Along the way, it has been updated to a newer autoconf version.

AC_INIT(squeak, 3.2-4743)
AC_CONFIG_SRCDIR(inisqueak.in)

VERSION=$PACKAGE_VERSION
MAJOR=`echo $VERSION | cut -d. -f 1`
MINOR=`echo $VERSION | cut -d. -f 2`

AC_SUBST(MAJOR)
AC_SUBST(MINOR)
AC_SUBST(VERSION)

AC_DEFINE_UNQUOTED(SQ_VERSION, "$VERSION")

AC_DEFINE(OS_TYPE, "unix")
AC_CANONICAL_HOST
host=$host_alias
host_cpu=`echo $host | sed 's,-.*,,'`
AC_SUBST(host)
AC_SUBST(host_cpu)
AC_SUBST(host_vendor)
AC_SUBST(host_os)
AC_DEFINE_UNQUOTED(VM_HOST, "$host")
AC_DEFINE_UNQUOTED(VM_HOST_OS, "$host_os")
AC_DEFINE_UNQUOTED(VM_HOST_CPU, "$host_cpu")

# Checks for programs.

AC_ARG_WITH(gnu-as,
[  --with-gnu-as           assume that as is the GNU assembler [default=no]],
GAS="$withval", GAS="unknown")

AC_PROG_MAKE_SET
AC_PROG_CC_WALL
AC_PROG_CXX
AC_PROG_AS_GNU
AC_PROG_RANLIB
AC_PROG_INSTALL
AC_PROG_NM

AC_CHECK_PROG(LN, ln, ln)

AC_DISABLE_STATIC
AC_PROG_LIBTOOL

# Checks for X11

AC_PATH_XTRA

LIBS="$X_LIBS $LIBS"
CFLAGS="$X_CFLAGS $CFLAGS"

# Checks for header files.

AC_NEED_SUNOS_H

AC_STDC_HEADERS
AC_HAVE_HEADERS(unistd.h string.h fcntl.h sys/file.h sys/param.h)
AC_HAVE_HEADERS(sys/time.h sys/filio.h sys/select.h dlfcn.h)
AC_HEADER_TIME
AC_HEADER_DIRENT

AC_STRUCT_TIMEZONE

AC_CHECK_SOCKLEN_T
AC_CHECK_ATEXIT
AC_CHECK_TZSET
AC_CHECK_GMTOFF
AC_CHECK_TIMEZONE
AC_CHECK_GETHOSTNAME

# Checks for libraries.

AC_CHECK_LIB(nsl, yp_bind)
AC_CHECK_LIB(socket, socket)
AC_CHECK_FUNC(dlopen, AC_DEFINE(HAVE_LIBDL,1),
  AC_CHECK_LIB(dl, dlopen))
AC_CHECK_LIB(m,	sin)
AC_CHECK_LIB(X11, XOpenDisplay)
AC_CHECK_LIB(Xext, XShmAttach)

AC_ARG_ENABLE(jit,
[  --enable-jit            enable J3 support [default=no]],
JIT="yes", JIT="no")

test $JIT = "yes" && J_CFLAGS="-DJ_ENABLED"
AC_SUBST(J_CFLAGS)


## Memory
AC_ARG_ENABLE(memory-mmap,
[  --enable-memory-mmap    use experimantal mmap-based memory allocater [default=no]])

if test "$enable_memory_mmap" = yes
then
AC_MSG_NOTICE([using mmap-based memory manager])
AC_DEFINE(USE_MEMORY_MMAP)
else
AC_MSG_NOTICE([using malloc-based memory manager])
fi

## Sound 

# let the user specify explicitly
AC_ARG_WITH(audio,
[[  --with-audio=choice    choose an audio device [default=auto]
    available audio devices: (auto no oss sun nas)]],
[[]],
[[with_audio=auto]])

# if unspecified, try different drivers until one is found
if test $with_audio = auto
then
  AC_HAVE_NAS
  if test $ac_cv_nas = "yes"
  then
    with_audio=nas
  fi
fi

if test $with_audio = auto
then
  AC_HAVE_OSS
  if test $ac_cv_oss = "yes"
  then
    with_audio=oss
  fi
fi

#XXX need an autoconf test for SunOS

# if no driver was found, choose the null driver
if test $with_audio = auto
then
  with_audio=no
fi

AC_MSG_NOTICE([using audio interface: $with_audio])
AC_DEFINE_UNQUOTED(AUDIO_INTERFACE, "$with_audio")


AUDIO_CDEFINE=`echo USE_AUDIO_$with_audio | tr '[[:lower:]]' '[[:upper:]]'`
AC_DEFINE_UNQUOTED($AUDIO_CDEFINE)


# do extra tests and/or setup depending on the device selected
if test $with_audio = "oss"
then
    AC_FIND_OSS_DEVICE
fi
if test $with_audio = "sun" 
then
    AC_HAVE_HEADERS(sys/audioio.h)
fi

if test $with_audio = "nas"
then
  LIBS="$LIBS -laudio -lXt"
fi



# Checks for platform characteristics.

AC_GNU_OPT
AC_GNU_INTERP
AC_MODULE_LIB_PREFIX
AC_64BIT_ARCH


CFLAGS="$CFLAGS_32 $CFLAGS"

AC_C_BYTEORDER
AC_C_DOUBLE_ALIGNMENT
AC_C_DOUBLE_ORDER


# Configure files.

AC_CONFIG_HEADER(sqUnixConfig.h)
$srcdir/util/mkMake $srcdir/../../.. > make_auto
AC_SUBST_FILE(make_auto)
make_auto=make_auto
AC_OUTPUT(Makefile inisqueak)
