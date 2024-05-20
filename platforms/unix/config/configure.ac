# configure.in (version 4) for Unix Squeak			-*- sh -*-
# 
# Process this file with autoconf to produce a configure script

#   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
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
# Author: Ian.Piumarta@SqueakLand.org
# 
# Last edited: Mon Aug 30 21:50:00 EST 2021 by phil

AC_PREREQ([2.69])

AC_INIT([OpenSmalltalk VM],[devel],
        [vm-dev@lists.squeakfoundation.org],
        [],
        [http://opensmalltalk.org/])


AC_CONFIG_SRCDIR([config.h.in])
AC_USE_SYSTEM_EXTENSIONS
LT_INIT([dlopen disable-static])
AC_SUBST([LIBTOOL_DEPS])


SVNREV=`grep '\$Rev: ' ${srcdir}/../../../platforms/Cross/vm/sqSCCSVersion.h \
	        | sed 's/.*$Rev: \([0-9][0-9]*\).*";/\1/' \
	        | head -n 1`
AC_ARG_WITH(vmversion,
	AS_HELP_STRING([ --with-vmversion=M.N], [vm version number (default=5.0)]),
	[vmversion="${with_vmversion}"],
	[vmversion="5.0"])
vmmajor=`echo ${vmversion} | sed 's/\..*//'`
vmminor=`echo ${vmversion} | sed 's/^.*\.//'`
AC_ARG_WITH(sqversion,
	AS_HELP_STRING([ --with-sqversion=M.N], [squeak version number (default=5.0)]),
	[sqversion="${with_sqversion}"],
	[sqversion="5.0"])
sqmajor=`echo ${sqversion} | sed 's/\..*//'`
sqminor=`echo ${sqversion} | sed 's/^.*\.//'`

AC_VM_VERSION(${vmmajor},${vmminor},${SVNREV},${sqmajor},${sqminor},0)

topdir=`cd ${srcdir}/../../..; pwd`
cfgdir=`cd ${srcdir}; pwd`

AC_ARG_WITH(src,
	AS_HELP_STRING([ --with-src=dir], [generated src directory (default=src)]),
	[vmmsrc="${with_src}"],
	[vmmsrc="src"])

vmmdir="${topdir}/${vmmsrc}"

AC_ARG_WITH(plugins,
	AS_HELP_STRING([ --with-plugins=dir], [generated plugins directory (default=${topdir}/src/plugins)]),
	[vmpsrc="${topdir}/${with_plugins}"],
	[vmpsrc="${topdir}/src/plugins"])

vmpdir="${vmpsrc}"

if test ! -d "${topdir}/${vmmsrc}"; then
  if test -d "${topdir}/platforms/unix/${vmmsrc}"; then
    vmmdir="${topdir}/platforms/unix/${vmmsrc}"
    AC_MSG_RESULT([using built-in src directory])
  fi
fi

if test ! -d "${topdir}/${vmpsrc}"; then
  if test -d "${topdir}/platforms/unix/${vmpsrc}"; then
    vmpdir="${topdir}/platforms/unix/${vmpsrc}"
    AC_MSG_RESULT([using built-in plugins directory])
  fi
fi

AC_MSG_RESULT(${vmmdir})
AC_MSG_RESULT(${vmpdir})

blddir=`pwd`

AC_ARG_WITH(vmmcfg,
	AS_HELP_STRING([ --with-vmmcfg=dir], [vm configuration directory containing plugins.int and plugins.ext (default=.)]),
	[vmmcfg="${with-vmmcfg}"],
	[vmmcfg="${blddir}"])

AC_ARG_WITH(scriptname,
	AS_HELP_STRING([ --with-scriptname=SCRIPT], [run script name installed in SCRIPT (default=squeak)]),
	[scriptname="${with_scriptname}"],
	[scriptname="squeak"])

# Compiling a Cogit VM or not?  If so, need a cogit$o, cointerp, etc.

AC_ARG_ENABLE(cogit,
	AS_HELP_STRING([--disable-cogit], [compile a cogit VM (default=enabled)]),
	[cogit="$enableval"],
	[cogit="yes"])
AC_SUBST(cogit)

# Check the generated src dir looks sane

AC_CHECK_VMM_DIR

AC_SUBST(topdir)
AC_SUBST(cfgdir)
AC_SUBST(vmmdir)
AC_SUBST(vmpdir)
AC_SUBST(vmmcfg)
AC_SUBST(blddir)
AC_SUBST(scriptname)

SQ_VERSION=${SQ_MAJOR}.${SQ_MINOR}-${SQ_UPDATE}

AC_DEFINE_UNQUOTED(SQ_VERSION, "${SQ_VERSION}", [Squeak version])

AC_SUBST(SQ_MAJOR)
AC_SUBST(SQ_MINOR)
AC_SUBST(SQ_UPDATE)
AC_SUBST(SQ_VERSION)

#VM_VERSION=${VM_MAJOR}.${VM_MINOR}-${VM_RELEASE}

#AC_DEFINE_UNQUOTED(VM_VERSION, "${VM_VERSION}", [VM version])

#AC_SUBST(VM_MAJOR)
#AC_SUBST(VM_MINOR)
#AC_SUBST(VM_RELEASE)
#AC_SUBST(VM_VERSION)

# libdir contains ${exec_prefix}, so we have to default and expand early
test "x$prefix" = xNONE && prefix=$ac_default_prefix
test "x$exec_prefix" = xNONE && exec_prefix='${prefix}'
imgdir=`eval echo ${libdir}/squeak`
expanded_relative_imgdir=`eval echo lib/squeak/${VM_VERSION}`
plgdir='${imgdir}/`${blddir}/getversion VERSION_TAG`'

AC_SUBST(imgdir)
AC_SUBST(expanded_relative_imgdir)
AC_SUBST(plgdir)

AC_DEFINE(OS_TYPE, "unix", [OS type])

AC_CANONICAL_HOST

host_cpu=`echo $host | sed 's,-.*,,'`
host=`echo $host | sed 's,-unknown,,'`

AC_SUBST(host)
AC_SUBST(host_cpu)
AC_SUBST(host_vendor)
AC_SUBST(host_os)

AC_DEFINE_UNQUOTED(VM_HOST, "$host", [host])
AC_DEFINE_UNQUOTED(VM_HOST_OS, "$host_os", [host os])
AC_DEFINE_UNQUOTED(VM_HOST_VERNDOR, "$host_vendor", [host vendor])
AC_DEFINE_UNQUOTED(VM_HOST_CPU, "$host_cpu", [host cpu])

AC_CANONICAL_TARGET

target_cpu=`echo $target | sed 's,-.*,,'`
target=`echo $target | sed 's,-unknown,,'`

AC_SUBST(target)
AC_SUBST(target_cpu)
AC_SUBST(target_vendor)
AC_SUBST(target_os)

AC_DEFINE_UNQUOTED(VM_TARGET, "$target", [target])
AC_DEFINE_UNQUOTED(VM_TARGET_OS, "$target_os", [target os])
AC_DEFINE_UNQUOTED(VM_TARGET_VENDOR, "target_vendor", [target vendor])
AC_DEFINE_UNQUOTED(VM_TARGET_CPU, "$target_cpu", [target cpu])

echo
echo "Configuring Squeak ${VM_VERSION} (${SQ_VERSION}) for ${host}"
echo

# Checks for programs.

AC_ARG_WITH(gnu-awk,
	AS_HELP_STRING([ --with-gnu-awk], [assume that awk is GNU gawk (default=no)]),
	[GAWK="$withval"],
	[case $host_os in
	  darwin*)	GAWK="yes";;
	  *)		GAWK="unknown";;
	esac])

AC_ARG_WITH(gnu-as,
	AS_HELP_STRING([ --with-gnu-as], [assume that as is the GNU assembler (default=no)]),
	[GAS="$withval"],
	[GAS="unknown"])

########################

# This section is used by the 'generic' linux32 & linux64 mvm configs which in turn are used for Debian package building on 'other' platforms which can only support stack VMs
AC_MSG_CHECKING([TARGET_ARCH & CFLAGS])
if [[ "$VM_CFLAGS" != "" ]]
then
	AC_MSG_RESULT([autoconfigure])
	# dpkg-architecture when available on Debian (and derivatives) with fallback to uname
	# using DEB_HOST_GNU_CPU rather than DEB_HOST_ARCH_CPU for consistency with uname
	AC_CHECK_PROG(getbuildarch,
		[dpkg-architecture],
		[dpkg-architecture --query DEB_HOST_GNU_CPU],
		[uname -m])
	AC_MSG_CHECKING([autoconfigure arch])
	build_arch=`$getbuildarch`
	AC_MSG_RESULT([$build_arch])
	case $build_arch in
		i686) TARGET_ARCH="-m32"
			CFLAGS="-g -O2 -msse2"
		;;

		x86_64) TARGET_ARCH="-m64"
			CFLAGS="-g -O1 -msse2"
		;;

	        # Omitting -DNO_VM_PROFILE=1 for now
		armhf) TARGET_ARCH="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
			CFLAGS="-g -O3"
		;;

		# Omitting -DMUSL -DUSEEVDEV for now
		aarch64) TARGET_ARCH="-march=armv8-a"
			CFLAGS="-g -O2 -D__ARM_ARCH_ISA_A64 -DARM64 -D__arm__ -D__arm64__ -D__aarch64__"
		;;

		riscv64) TARGET_ARCH="-march=rv64gcv -mabi=lp64d"
			CFLAGS="-g -O2 -D__riscv64__"
		;;

		*)
			if [[ "$VM_WORD_SIZE" == "32" ]]
			then
				TARGET_ARCH="-m32"
			else
				TARGET_ARCH="-m64"
			fi
			CFLAGS="-g -O2"
		;;
	esac
	AC_SUBST([TARGET_ARCH])
	AC_SUBST([CFLAGS])
	AC_MSG_NOTICE([TARGET_ARCH=$TARGET_ARCH])
	AC_MSG_NOTICE([CFLAGS=$CFLAGS])
else
	AC_MSG_RESULT([mvm])
fi

########################

case $target in
	i686*) # workaround for 32-bit x86 builds on Ubuntu/Debian
		PKG_CONFIG=/usr/bin/i686-linux-gnu-pkg-config
		;;
	*)
		PKG_CONFIG=/usr/bin/pkg-config
		;;
esac

########################

TARGET_ARCH="$TARGET_ARCH"

# tpr - try to keep msse out of it for Pi CFLAGS="$CFLAGS_32 $CFLAGS -msse"
CFLAGS="$CFLAGS_32 $CFLAGS"

CPPFLAGS="$CPPFLAGS $TARGET_ARCH"
LDFLAGS="$TARGET_ARCH $LDFLAGS"

AC_LANG([C])

AX_COMPILER_VENDOR

AC_PROG_MAKE_SET
AC_PROG_CC([clang icc gcc cc])
AC_PROG_CC_C99
AX_CFLAGS_WARN_ALL
AC_PROG_AS_GNU
AC_PROG_INSTALL
AC_PROG_NM


if test "$GCC" = "yes"; then
  # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=53119
  CPPFLAGS="$CPPFLAGS -Wno-missing-braces"
  #sigh 
  CPPFLAGS="$CPPFLAGS -Wno-unknown-pragmas -Wno-unused-value -Wno-unused-label -Wno-unused-function -Wno-unused-variable"
  if $CC -E -xc -Werror -Wno-unused-but-set-variable - </dev/null 2>&1 >/dev/null; then
    CPPFLAGS="$CPPFLAGS -Wno-unused-but-set-variable"
  fi
fi
AC_SUBST(WFLAGS)


AC_CHECK_PROG([LN], [ln], [ln])

# Check size assumptions of basic data types

AC_REQUIRE_SIZEOF(int,    4)
AC_REQUIRE_SIZEOF(double, 8)

AC_CHECK_SIZEOF(int)
AC_CHECK_SIZEOF(long)
AC_CHECK_SIZEOF(long long)
AC_CHECK_SIZEOF(void *)

# libtool configuration

AC_DISABLE_STATIC
AC_PROG_LIBTOOL

# Configured headers (pretty much everybody needs blddir and vm)

INCLUDES="-I${blddir} -I${vmmcfg} -I${topdir}/platforms/unix/vm -I${topdir}/platforms/Cross/vm -I${vmmdir}"

# these are not always added
case $host_os in
  cygwin*|freebsd*)
    : #noop
    ;;
  *)
    INCLUDES="$INCLUDES -I/usr/local/include"
    LDFLAGS="$LDFLAGS -L/usr/local/lib"
    ;;
esac

AC_SUBST(INCLUDES)

# Linker specialities
case $host_os in
  cygwin*|darwin*)
    : #noop
    ;;
  openbsd*)
    LDFLAGS="$LDFLAGS -Wl,-z,wxneeded -Wl,-z,now"
    ;;
  *)
    LDFLAGS="$LDFLAGS -Wl,-z,now"
    ;;
esac

# Checks for header files.

AC_NEED_SUNOS_H

AC_HEADER_STDC
AC_CHECK_HEADERS_ONCE([unistd.h string.h fcntl.h sys/file.h sys/param.h])
AC_CHECK_HEADERS_ONCE([sys/time.h sys/filio.h sys/select.h])
AC_CHECK_HEADERS_ONCE([features.h])
AC_CHECK_HEADERS_ONCE([ifaddrs.h]) # sqUnixSocket.c
AC_CHECK_HEADERS_ONCE([alloca.h]) # SunOS5
AC_HEADER_TIME
AC_HEADER_DIRENT

if test -f "${vmmdir}/interp.h"; then
  AC_DEFINE([HAVE_INTERP_H], [1], [Interpreter header file present])
fi
AC_SUBST(HAVE_INTERP_H)

AC_STRUCT_TIMEZONE
AC_STRUCT_ST_BLKSIZE

AC_CHECK_SOCKLEN_T
AC_CHECK_ATEXIT
AC_CHECK_TZSET
AC_CHECK_GMTOFF
AC_CHECK_TIMEZONE
AC_CHECK_GETHOSTNAME

# Display options.

AC_ARG_WITH(rfb,
	AS_HELP_STRING([ --without-rfb], [disable Remote FrameBuffer support (default=enabled)]),
	[have_rfb="$withval"],
	[have_rfb="no"])

test $have_rfb = "yes" && AC_DEFINE(USE_RFB,[1], [Use RFB])

# Checks for libraries.

AC_SEARCH_LIBS([gethostbyname], [nsl])
AC_SEARCH_LIBS([socket], [socket])
AC_SEARCH_LIBS([sin], [m])

AC_CHECK_HEADERS_ONCE([execinfo.h])
AC_SEARCH_LIBS([backtrace],[execinfo])


AX_PTHREAD([
  LIBS="$PTHREAD_LIBS $LIBS"
  CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
  CC="$PTHREAD_CC"
])


AC_SYS_LARGEFILE

AC_CHECK_FUNC(_dyld_image_count, [AC_DEFINE(HAVE_DYLD,[1], [dyld linker present])])
AC_CHECK_HEADERS([dlfcn.h])
LT_LIB_DLLOAD

AC_CHECK_FUNCS([snprintf __snprintf],[break])
AC_CHECK_FUNCS_ONCE([mmap nanosleep])
AC_FUNC_ALLOCA

AC_ARG_ENABLE(epoll,
	AS_HELP_STRING([--disable-epoll], [Do not use epoll even if supported (default: try to use)]),
	[try_epoll="$enableval"],
	[try_epoll="yes"])
if test "$try_epoll" = yes; then
  AX_HAVE_EPOLL([AC_DEFINE(HAVE_EPOLL, [1], [epoll(7) is supported])])
  AX_HAVE_EPOLL_PWAIT([AC_DEFINE(HAVE_EPOLL_PWAIT, [1], [epoll_pwait(7) is supported])])
fi

AX_CHECK_ZLIB([], AC_MSG_NOTICE([No zlib found]))

# Checks for platform characteristics.

AC_GNU_OPT
AC_GNU_INTERP
AC_MODULE_LIB_PREFIX
AC_64BIT_ARCH

AC_C_BYTEORDER

case $host_os in
  darwin*)
    AC_DEFINE([DARWIN],[1], [Defined when building on Darwin])
#    CFLAGS="-no-cpp-precomp $CFLAGS"
    with_npsqueak=no
    VM_APP_ICONS="${imgdir}/SqueakVM.icns"
    ;;
  *)
    VM_APP_ICONS=""
    ;;
esac

AC_SUBST(VM_APP_ICONS)

# Checks for browser support

AC_SUBST(npsqueak)
AC_SUBST(install_nps)
AC_SUBST(uninstall_nps)

AC_ARG_WITH(npsqueak,
	AS_HELP_STRING([ --without-npsqueak], [     disable browser plugin support (default=enabled)]),
	  [with_npsqueak="$withval"],
	  [with_npsqueak="yes"])

if test "$with_npsqueak" = "no"; then
  npsqueak=""
  install_nps=""
  uninstall_nps=""
else
  npsqueak=npsqueak
  install_nps=install-npsqueak
  uninstall_nps=uninstall-npsqueak
fi

# Install locations

if test "x${prefix}" = xNONE; then
  SQ_LIBDIR=${ac_default_prefix}/lib/squeak/${SQ_VERSION}
else
  SQ_LIBDIR=${prefix}/lib/squeak/${SQ_VERSION}
fi

AC_SUBST(SQ_LIBDIR)
AC_DEFINE_UNQUOTED(SQ_LIBDIR,["${SQ_LIBDIR}"], [Squeak libdir])

# Configure files

make_cfg=${blddir}/make.cfg
make_int=${blddir}/make.int
make_ext=${blddir}/make.ext
make_prg=${blddir}/make.prg

AC_SUBST_FILE(make_cfg)
AC_SUBST_FILE(make_int)
AC_SUBST_FILE(make_ext)
AC_SUBST_FILE(make_prg)

Makefile_install=${cfgdir}/Makefile.install
Makefile_dist=${topdir}/util/Makefile.dist
Makefile_rpm=${topdir}/util/Makefile.rpm
Makefile_deb=${topdir}/util/Makefile.deb

AC_SUBST_FILE(Makefile_install)
AC_SUBST_FILE(Makefile_dist)
AC_SUBST_FILE(Makefile_rpm)
AC_SUBST_FILE(Makefile_deb)

# Configure VM modules xxx MAKE INTERNAL WORK

int_modules="vm"
ext_modules="`cd ${topdir}/platforms/unix; echo vm-*`"

AC_SUBST(int_modules)
AC_SUBST(ext_modules)

# Configure plugins

disabled_plugins=""
rm -f plugins.exc
sinclude(acplugins.m4)

# Plugins not generated by VMM must be listed here...
int_plugins=""
ext_plugins=""
AC_SUBST(int_plugins)
AC_SUBST(ext_plugins)

if test "${disabled_plugins}" != ""; then
  echo ${disabled_plugins} | tr ' ' '\012' | sort -u > plugins.exc
fi

# for some reason configure leaves an empty a.out lying around
test -f a.out && rm a.out

# Create the build environment

AH_TOP([/* config.h.in -- template for config.h			-*- C -*-
 *
 *   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *
 *   This file is part of Unix Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

/* Author: Ian.Piumarta@squeakland.org
 *
 * Last edited: 2006-04-23 12:34:41 by piumarta on emilia.local
 */

#ifndef __sq_config_h
#define __sq_config_h

#ifdef _FEATURES_H
#error This file was included too late. Please make sure it is included earlier
#endif
])

AH_TEMPLATE([VM_DLSYM_PREFIX],[Once used to specify mangled names on Mac OS, left for documentation purposes])


AH_BOTTOM([#endif /* __sq_config_h */])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([mkconfig make.cfg make.int make.ext make.prg inisqueak Makefile])
AC_CONFIG_COMMANDS([default],[
  chmod +x mkconfig inisqueak
  ${SHELL} -ec "./mkconfig; ${cfgdir}/mktargets; ${cfgdir}/mkmf"],[
  cfgdir=${cfgdir}
])

AC_OUTPUT
