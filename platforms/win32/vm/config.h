#ifdef _MSC_VER
#include <limits.h>
#endif

#if LP32 || ILP32
#  define SIZEOF_VOID_P 4
#elif LP64 || ILP64 || LLP64
#  define SIZEOF_VOID_P 8
#elif defined(__SIZEOF_POINTER__)
#  define SIZEOF_VOID_P __SIZEOF_POINTER__
#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
#  define SIZEOF_VOID_P 8
#elif defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__) || defined(__arm32__)
#  define SIZEOF_VOID_P 4
#else
#  error Unknown architecture. Please fix inference rule for determining size of pointer
#endif

#if LP32 || ILP32 || LLP64
#  define SIZEOF_LONG 4
#elif LP64 || ILP64
#  define SIZEOF_LONG 8
#elif defined(__SIZEOF_LONG__)
#  define SIZEOF_LONG __SIZEOF_LONG__
#elif defined(__LONG_MAX__)
#  if __LONG_MAX__ > 0xFFFFFFFFUL
#    define SIZEOF_LONG 8
#  else
#    define SIZEOF_LONG 4
#  endif
#elif defined(ULONG_MAX)
#  if ULONG_MAX > 0xFFFFFFFFUL
#    define SIZEOF_LONG 8
#  else
#    define SIZEOF_LONG 4
#  endif
#else
#  error Unknown architecture. Please fix inference rule for determining size of long
#endif

#define SIZEOF_LONG_LONG 8
