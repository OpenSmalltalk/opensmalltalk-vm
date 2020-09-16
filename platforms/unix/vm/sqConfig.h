/* Unix sqConfig.h -- platform identification and configuration */

#ifdef HAVE_CONFIG_H
/* Use automatically generated config values (viz. autoconf) */
#include "config.h"
#endif

#ifndef UNIX
# define UNIX
#endif

#if !defined(LSB_FIRST)
#error  "LSB_FIRST is undefined. Used for setting platform endianesness!"
#endif


#if LSB_FIRST
# define VMBIGENDIAN 0
#else
# define VMBIGENDIAN 1
#endif

#if defined(__GNUC__)
/* Define the "don't generate functions with register parameters" attribute
 * for x86 and similar.  Do so for debugging; gdb typically can't call static
 * functions that have been optimized to use register arguments.
 */
# if defined(_M_I386) || defined(_X86_) || defined(i386) || defined(i486) || defined(i586) || defined(i686) || defined(__i386__) || defined(__386__) || defined(X86) || defined(I386)
/*#	define PlatformNoDbgRegParms __attribute__ ((regparm (0)))*/
# endif
# define NeverInline __attribute__ ((noinline))
#endif

#if defined( __clang__)
# define NeverInline __attribute__ ((noinline))
#endif

/* Make the gcc/clang asm keyword available, even when running
 * in standard C mode.
 */
#if __GNUC__ >= 9
# define asm __asm
#else
# define asm __asm__
#endif
