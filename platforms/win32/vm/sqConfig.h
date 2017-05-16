/* win32/win64  sqConfig.h -- platform identification and configuration */

/* Some compilers use different win32/64 definitions.  According to Microsoft
 * _WIN32 & _WIN64 are the official defines.
 */

#if (_WIN32 || WIN32 || Win32) && !_WIN32
#	undef _WIN32
#	define _WIN32 1
#endif
#if (_WIN64 || WIN64 || Win64) && !_WIN64
#	undef _WIN64
#	define _WIN64 1
#endif


#if _WIN32 || _WIN64
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
#  error unsupported win32/win64 processor type (alpha?!)
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

#if defined(__clang__)
# define NeverInline __attribute__ ((noinline))
#endif
