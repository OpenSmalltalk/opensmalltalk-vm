/* config.h
 *
 *   Copyright (C) 1996-2014 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *
 *   This file is part of Plan9 Squeak.
 *
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 *
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 *
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 *
 *   3. This notice must not be removed or altered in any source distribution.
 *
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 */

/* Author: Ian.Piumarta@squeakland.org
 * Author: alex.franchuk@gmail.com
 *
 * Last edited: 2014-09-28 by afranchuk
 */

#ifndef __sq_config_h
#define __sq_config_h

/* header files */

#undef	HAVE_UNISTD_H

#undef	HAVE_DIRENT_H

#undef	HAVE_ICONV_H

#undef	HAVE_SYS_TIME_H
#undef	TIME_WITH_SYS_TIME

#undef	HAVE_SYS_FILIO_H

#undef HAVE_PTY_H

/* system calls/library functions */

#define	AT_EXIT atexit

#undef	HAVE_TZSET

#undef	HAVE_OPENPTY

#define	HAVE_SNPRINTF 1

#undef	HAVE_MMAP

#undef	HAVE_DYLD

#undef	HAVE_LANGINFO_CODESET

#undef	HAVE_ALLOCA
#undef	HAVE_ALLOCA_H

#undef	HAVE_UNSETENV

/* widths of primitive types */

#define	SIZEOF_INT 4
#define	SIZEOF_LONG 4
#define	SIZEOF_LONG_LONG 8
#define	SIZEOF_VOID_P 4

/* structures */

#undef	HAVE_TM_GMTOFF
#undef	HAVE_TIMEZONE

/* typedefs */

#define	squeakInt64 long long

/* architecture */

#define	OS_TYPE "plan9"

/* #undef	VM_HOST_VENDOR */
#define	VM_HOST_OS "plan9"

#if defined(__BIG_ENDIAN__)
#define	WORDS_BIGENDIAN 1
#define VMENDIANNESS 1
#define	VM_HOST "plan9"
#define	VM_HOST_CPU "powerpc"
#else
#undef	WORDS_BIGENDIAN 
#define VMENDIANNESS 0
#define	VM_HOST "plan9"
#define	VM_HOST_CPU "intel"
#define	DOUBLE_WORD_ORDER 1
#define LSB_FIRST 1
#endif

#undef HAVE_LIBDL
/* #undef	DOUBLE_WORD_ORDER */

/* other configured variables */

#define VM_LIBDIR ""
#define VM_MODULE_PREFIX ""
#define VM_BUILD_STRING "Plan9 built on "__DATE__" "__TIME__
/* #undef VM_DLSYM_PREFIX */

/* avoid dependencies on glibc2.3 */

/* #undef HAVE_FEATURES_H */

#endif /* __sq_config_h */
