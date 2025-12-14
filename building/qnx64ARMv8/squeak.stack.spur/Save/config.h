/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* config.h.in -- template for config.h			-*- C -*-
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


/* Define if building universal (internal helper macro) */
/* #undef AC_APPLE_UNIVERSAL_BUILD */

/* Is atexit present */
#define AT_EXIT atexit

/* Define to one of `_getb67', `GETB67', `getb67' for Cray-2 and Cray-YMP
   systems. This function is required for `alloca.c' support on those systems.
   */
/* #undef CRAY_STACKSEG_END */

/* Define to 1 if using `alloca.c'. */
/* #undef C_ALLOCA */

/* Defined when building on Darwin */
/* #undef DARWIN */

/* Define to 1 if you have `alloca', as a function or macro. */
#define HAVE_ALLOCA 1

/* Define to 1 if you have <alloca.h> and it should be used (not on Ultrix).
   */
#define HAVE_ALLOCA_H 1

/* Define to 1 if you have the <alsa/asoundlib.h> header file. */
/* #undef HAVE_ALSA_ASOUNDLIB_H */

/* Define to 1 if you have the <audio/audiolib.h> header file. */
/* #undef HAVE_AUDIO_AUDIOLIB_H */

/* Define to 1 if you have the declaration of `cygwin_conv_path', and to 0 if
   you don't. */
/* #undef HAVE_DECL_CYGWIN_CONV_PATH */

/* Define to 1 if you have the declaration of `tzname', and to 0 if you don't.
   */
/* #undef HAVE_DECL_TZNAME */

/* Define to 1 if you have the <dirent.h> header file, and it defines `DIR'.
   */
#define HAVE_DIRENT_H 1

/* Define if you have the GNU dld library. */
/* #undef HAVE_DLD */

/* Define to 1 if you have the `dlerror' function. */
#define HAVE_DLERROR 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define if you have the _dyld_func_lookup function. */
/* #undef HAVE_DYLD */

/* epoll(7) is supported */
/*@@KenD@@ define HAVE_EPOLL 1 */

/* epoll_pwait(7) is supported */
/*@@KenD@@ #define HAVE_EPOLL_PWAIT 1 */

/* Define to 1 if you have the <execinfo.h> header file. */
/*@@KenD@@ define HAVE_EXECINFO_H 1 */

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the <features.h> header file. */
#define HAVE_FEATURES_H 1

/* Define to 1 if you have the <gl/gl.h> header file. */
#define HAVE_GL_GL_H 1

/* Define to 1 if you have the <gl.h> header file. */
/* #undef HAVE_GL_H */

/* Define to 1 if you have the <iconv.h> header file. */
#define HAVE_ICONV_H 1

/* Define to 1 if you have the <ifaddrs.h> header file. */
#define HAVE_IFADDRS_H 1

/* Interpreter header file present */
#define HAVE_INTERP_H 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define if you have <langinfo.h> and nl_langinfo(CODESET). */
#define HAVE_LANGINFO_CODESET 1

/* Define if you have the libdl library or equivalent. */
#define HAVE_LIBDL 1

/* Define if libdlloader will be built on this platform */
#define HAVE_LIBDLLOADER 1

/* Define to 1 if you have the <libevdev-1.0/libevdev/libevdev.h> header file.
   */
/*@@KenD@@ define HAVE_LIBEVDEV_1_0_LIBEVDEV_LIBEVDEV_H 1 */

/* Define to 1 if you have the <libutil.h> header file. */
/* #undef HAVE_LIBUTIL_H */

/* Have Xext library */
/*@@KenD@@ define HAVE_LIBXEXT 1 */

/* Have Xrender library */
/*@@KenD@@ define HAVE_LIBXRENDER 1 */

/* Define to 1 if you have `z' library (-lz) */
#define HAVE_LIBZ 1

/* Define to 1 if you have the <linux/fb.h> header file. */
/*@@KenD@@ define HAVE_LINUX_FB_H 1 */

/* linux/input.h */
/*@@KenD@@  ??? @REVISIT@*/
/*@@KenD@@ define HAVE_LINUX_INPUT_H 1 */

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `mmap' function. */
#define HAVE_MMAP 1

/* Define to 1 if you have the `nanosleep' function. */
#define HAVE_NANOSLEEP 1

/* Define to 1 if you have the <ndir.h> header file, and it defines `DIR'. */
/* #undef HAVE_NDIR_H */

/* Define to 1 if you have the <OpenGL/gl.h> header file. */
/* #undef HAVE_OPENGL_GL_H */

/* Have openpty */
/*@@KenD@@ define HAVE_OPENPTY 1 */

/* Define to 1 if you have the <openssl/ssl.h> header file. */
#define HAVE_OPENSSL_SSL_H 1

/* Have PTHREAD_PRIO_INHERIT. */

#define HAVE_PTHREAD_PRIO_INHERIT 1

/* Define to 1 if you have the <pty.h> header file. */
/*@@KenD@@ define HAVE_PTY_H 1 */

/* Define to 1 if you have the <pulse/simple.h> header file. */
/*@@KenD@@ define HAVE_PULSE_SIMPLE_H 1 */

/* Define if you have the shl_load function. */
/* #undef HAVE_SHL_LOAD */

/* Define to 1 if you have the <sndio.h> header file. */
/* #undef HAVE_SNDIO_H */

/* Define to 1 if you have the `snprintf' function. */
#define HAVE_SNPRINTF 1

/* Define to 1 if you have the <soundcard.h> header file. */
/* #undef HAVE_SOUNDCARD_H */

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the <stropts.h> header file. */
/* #undef HAVE_STROPTS_H */

/* Define to 1 if `st_blksize' is a member of `struct stat'. */
#define HAVE_STRUCT_STAT_ST_BLKSIZE 1

/* Define to 1 if `tm_zone' is a member of `struct tm'. */
/*@@KenD@@ @@Check & REVISIT@@ */
#define HAVE_STRUCT_TM_TM_ZONE 1

/* Define to 1 if your `struct stat' has `st_blksize'. Deprecated, use
   `HAVE_STRUCT_STAT_ST_BLKSIZE' instead. */
#define HAVE_ST_BLKSIZE 1

/* Sun audioio */
/* #undef HAVE_SUN_AUDIOIO_H */

/* SunOS/Solaris audio */
/* #undef HAVE_SYS_AUDIOIO_H */

/* Define to 1 if you have the <sys/dir.h> header file, and it defines `DIR'.
   */
/* #undef HAVE_SYS_DIR_H */

/* Define to 1 if you have the <sys/file.h> header file. */
#define HAVE_SYS_FILE_H 1

/* Define to 1 if you have the <sys/filio.h> header file. */
/* #undef HAVE_SYS_FILIO_H */

/* Define to 1 if you have the <sys/ndir.h> header file, and it defines `DIR'.
   */
/* #undef HAVE_SYS_NDIR_H */

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/select.h> header file. */
#define HAVE_SYS_SELECT_H 1

/* Define to 1 if you have the <sys/soundcard.h> header file. */
/*@@KenD@@ define HAVE_SYS_SOUNDCARD_H 1 */

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* sys/uuid.h */
/* #undef HAVE_SYS_UUID_H */

/* timezone present */
#define HAVE_TIMEZONE /**/

/* Define to 1 if you have the <tls.h> header file. */
/* #undef HAVE_TLS_H */

/* tm_gmtoff present */
#define HAVE_TM_GMTOFF /**/

/* Define to 1 if your `struct tm' has `tm_zone'. Deprecated, use
   `HAVE_STRUCT_TM_TM_ZONE' instead. */
/*@@KenD@@ define HAVE_TM_ZONE 1 */

/* Define to 1 if you don't have `tm_zone' but do have the external array
   `tzname'. */
/* #undef HAVE_TZNAME */

/* tzset available */
#define HAVE_TZSET /**/

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Have grantpt */
 /*@@KenD@@ */
#define HAVE_GRANTPT 1
/* #undef HAVE_UNIX98_PTYS */

/* Have unsetenv */
#define HAVE_UNSETENV 1

/* Define to 1 if you have the <util.h> header file. */
/* #undef HAVE_UTIL_H */

/* uuidgen */
/* #undef HAVE_UUIDGEN */

/* uuid_generate */
/*@@KenD@@ define HAVE_UUID_GENERATE 1 */

/* uuid.h */
/* #undef HAVE_UUID_H */

/* uuid/uuid.h */
/*@@KenD@@ define HAVE_UUID_UUID_H 1 */

/* Define to 1 if you have the `__snprintf' function. */
/*@@KenD@@ */
#define HAVE__SNPRINTF 1
/* #undef HAVE___SNPRINTF */

/* Define to the sub-directory where libtool stores uninstalled libraries. */
#define LT_OBJDIR ".libs/"

/* gethostname_p */
/* #undef NEED_GETHOSTNAME_P */

/* building on SunOS */
/* #undef NEED_SUNOS_H */

/* OS type */ /*@@KenD@@*/
#define OS_TYPE "qnx"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "vm-dev@lists.squeakfoundation.org"

/* Define to the full name of this package. */
#define PACKAGE_NAME "OpenSmalltalk VM"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "OpenSmalltalk VM devel"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "opensmalltalk-vm"

/* Define to the home page for this package. */
#define PACKAGE_URL "http://opensmalltalk.org/"

/* Define to the version of this package. */
#define PACKAGE_VERSION "devel"

/* Define to necessary symbol if this constant uses a non-standard name on
   your system. */
/* #undef PTHREAD_CREATE_JOINABLE */

/* The size of `int', as computed by sizeof. */
#define SIZEOF_INT 4

/* The size of `long', as computed by sizeof. */
#define SIZEOF_LONG 8

/* The size of `long long', as computed by sizeof. */
#define SIZEOF_LONG_LONG 8

/* The size of `void *', as computed by sizeof. */
#define SIZEOF_VOID_P 8

/* Linked OpenSSL */
/* #undef SQSSL_OPENSSL_LINKED */

/* Squeak libdir */
#define SQ_LIBDIR "/usr/local/lib/squeak/.-"

/* Squeak version */
#define SQ_VERSION ".-"

/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at runtime.
	STACK_DIRECTION > 0 => grows toward higher addresses
	STACK_DIRECTION < 0 => grows toward lower addresses
	STACK_DIRECTION = 0 => direction of growth unknown */
/* #undef STACK_DIRECTION */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define to 1 if you can safely include both <sys/time.h> and <time.h>. */
#define TIME_WITH_SYS_TIME 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/*@@KenD@@ def'ed in time.hn not sys/time.h */
/* #undef TM_IN_SYS_TIME */

/* Use MIDI ALSA */
/* #undef USE_MIDI_ALSA */

/* Use Quartz */
/* #undef USE_QUARTZ */

/* Use Quartz CGL */
/* #undef USE_QUARTZ_CGL */

/* Use RFB */
/* #undef USE_RFB */

/* Enable extensions on AIX 3, Interix.  */
#ifndef _ALL_SOURCE
# define _ALL_SOURCE 1
#endif
/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
/* Enable threading extensions on Solaris.  */
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
/* Enable extensions on HP NonStop.  */
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
/* Enable general extensions on Solaris.  */
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif


/* Use X11 */
/*@@KenD@@*/
#undef USE_X11 

/* Use X11 GLX */
/*@@KenD@@*/
#undef USE_X11_GLX

/* build string */
#define VM_BUILD_STRING "Qnx build on "__DATE__ " "__TIME__" Compiler: "__VERSION__

/* Once used to specify mangled names on Mac OS, left for documentation
   purposes */
/* #undef VM_DLSYM_PREFIX */

/* @@KenD@@ "host" & "target" are aarch64 "build" is x86_64 */
/* host */
#define VM_HOST "aarch64-rpi4-qnx-gnu"

/* host cpu */
#define VM_HOST_CPU "aarch64"

/* host os */
#define VM_HOST_OS "qnx-gnu"

/* host vendor */
#define VM_HOST_VERNDOR "rpi4"

/* VM module prefix */
#define VM_MODULE_PREFIX ""

/* target */
#define VM_TARGET "aarch64le-qnx-rpi4-gnu"

/* target cpu */
#define VM_TARGET_CPU "aarch64"

/* target os */
#define VM_TARGET_OS "qnx-gnu"

/* target vendor */
#define VM_TARGET_VENDOR "qnx.com/getqnx"

/* X11 libraries */
/*@@KenD@@ define VM_X11DIR "" */

/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */
#if defined AC_APPLE_UNIVERSAL_BUILD
# if defined __BIG_ENDIAN__
#  define WORDS_BIGENDIAN 1
# endif
#else
# ifndef WORDS_BIGENDIAN
/* #  undef WORDS_BIGENDIAN */
# endif
#endif

/* Define to 1 if the X Window System is missing or not being used. */
/*@@KenD@@ undef X_DISPLAY_MISSING */
#define X_DISPLAY_MISSING 1

/* Enable large inode numbers on Mac OS X 10.5.  */
#ifndef _DARWIN_USE_64_BIT_INODE
# define _DARWIN_USE_64_BIT_INODE 1
#endif

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */

/* Define to 1 if on MINIX. */
/* #undef _MINIX */

/* Define to 2 if the system does not provide POSIX.1 features except with
   this defined. */
/* #undef _POSIX_1_SOURCE */

/* Define to 1 if you need to in order for `stat' and other things to work. */
/* #undef _POSIX_SOURCE */

/* Define to `unsigned int' if <sys/types.h> does not define. */
/* #undef size_t */

/* socklen size */
/* #undef socklen_t */

#endif /* __sq_config_h */
