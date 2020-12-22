#ifndef SIGJMP_SUPPORT_H
#define SIGJMP_SUPPORT_H

/*
* This file defines the helper functions sigsetjmp and siglongjmp, depending on the platform
*/

#include <setjmp.h>

/*
 * Define sigsetjmp and siglongjmp to be the most minimal setjmp/longjmp available on the platform.
 * Note: on windows 64 via mingw-w64, the 2nd argument NULL to _setjmp prevents stack unwinding
 */
#undef setjmp
#undef sigsetjmp
#undef siglongjmp
#if _MSC_VER && !__clang__
// MSVC versions of setjmp and longjmp use the exception mechanism and do unwind the stack
// However, unwinding the stack does not work in the precense of native code generated dynamically by the JIT
// Use instead two definitions of setjmp and longjmp defined by ourselves for the current platform
// See utils/setjmp-Windows-wrapper-$PLATFORM.asm for details
extern int __setjmp_wrapper(jmp_buf);
extern int __longjmp_wrapper(jmp_buf, int);
# define setjmp(jb) __setjmp_wrapper(jb)
# define sigsetjmp(jb,ssmf) __setjmp_wrapper(jb)
# define siglongjmp(jb,v) __longjmp_wrapper(jb,v)
#elif _WIN64 && __GNUC__
# define sigsetjmp(jb,ssmf) _setjmp(jb,NULL)
# define siglongjmp(jb,v) longjmp(jb,v)
#elif _WIN32
# define sigsetjmp(jb,ssmf) setjmp(jb)
# define siglongjmp(jb,v) longjmp(jb,v)
#else
# define sigsetjmp(jb,ssmf) _setjmp(jb)
# define siglongjmp(jb,v) _longjmp(jb,v)
#endif

#endif // SIGJMP_SUPPORT_H