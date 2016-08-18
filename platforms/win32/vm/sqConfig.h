/*win32  sqConfig.h -- platform identification and configuration */

#if defined(WIN32) || defined(_WIN32) || defined(Win32)
  /* Some compilers use different win32 definitions.
     Define WIN32 so we have only to check for one symbol. */
# if !defined(WIN32)
#  define WIN32 1
# endif
#endif


#if defined(WIN32)
# if defined(SQ_CONFIG_DONE)
#   error configuration conflict
# endif
# if defined(_M_IX86) || defined(X86) || defined(_M_I386) || defined(_X86_) \
  || defined(i386) || defined(i486) || defined(i586) || defined(i686) \
  || defined(__i386__) || defined(__386__) || defined(I386) \
    \
  || defined(_M_X64) || defined(__amd64__) || defined(__amd64) \
  || defined(x86_64) || defined(__x86_64__) || defined(__x86_64) \
  || defined(x64) \
    \
  || defined(_WIN32_WCE)
#  include "sqWin32.h"
#  define SQ_CONFIG_DONE
# else
#  error unsupported win32 processor type (alpha?!)
# endif
#endif

#if !defined(SQ_CONFIG_DONE)
# error test for, and describe, your architecture here.
#endif

#define VMBIGENDIAN 0

#if defined(__GNUC__) && (__GNUC__ == 3 || (!defined(__MINGW32__) && !defined(__MINGW64__)))
/* Define the "don't generate functions with register parameters" attribute
 * for x86 and similar.  Do so for debugging; gdb typically can't call static
 * functions that have been optimized to use register arguments.
 */
# if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(i486) || defined(i586) || defined(i686) || defined(__i386__) || defined(__386__) || defined(X86) || defined(I386)
#	define PlatformNoDbgRegParms __attribute__ ((regparm (0)))
# endif
# define PlatformNoDbgRegParms __attribute__ ((regparm (0)))
# define NeverInline __attribute__ ((noinline))
#endif

#if defined( __clang__)
# define NeverInline __attribute__ ((noinline))
#endif
