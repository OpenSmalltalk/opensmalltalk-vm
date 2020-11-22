/* win32 sqPlatformSpecific.h -- Platform-specific prototypes and definitions */

/* How to use this file:
   This file is for general platform-specific macros and declarations.
   The goal is to keep most of the other header files generic across platforms.
   To override a definition or macro from sq.h, you must first #undef it, then
   provide the new definition.

*/

#include "pharovm/exportDefinition.h"

#if _WIN32 || _WIN64
/* Override necessary definitions */
# undef putchar
# include "sqWin32Alloc.h"
#include "sqMemoryAccess.h"


# include <windows.h>

# define ioCurrentOSThread() pthread_self()

/* missing functions */
#ifdef _MSC_VER
/* see on msdn the list of functions available
 *  CRT Alphabetical Function Reference
 *  https://msdn.microsoft.com/en-US/library/634ca0c2.aspx */
#  include <malloc.h>
#  include <float.h>
#  ifndef alloca
#    define alloca _alloca
#  endif
#  if _MSC_VER < 1800 /* not available before MSVC 2013 */
#    define atoll(x)              _atoi64(x)
#    define strtoll(beg,end,base) _strtoi64(beg,end,base)
     double round(double);
#  endif
#  if _MSC_VER < 1900 /* not available before MSVC 2015 */
#    define snprintf _snprintf
#    ifndef isnan
#      define isnan _isnan
#    endif
#  endif
#  if _MSC_VER < 1300 /* maybe not available before MSVC 7.0 2003 ??? */
#    define fabsf(x)    ((float)fabs((double)(x)))
#  endif
#  define bzero(pointer,size) ZeroMemory(pointer,size)
#endif

#ifdef __GNUC__
#  if __GNUC__ < 3
#    define fabsf(x)    ((float)fabs((double)(x))) /* not sure if really necessary, but was in original file */
#  endif
#endif

#else
error "Not Win32 or Win64!"
#endif /* _WIN32 || _WIN64 */

#ifdef _WIN32
int ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);
#else
sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);
#endif

/* poll and profile thread priorities.  The stack vm uses a thread to cause the
 * VM to poll for I/O, check for delay expiry et al at regular intervals.  Both
 * VMs use a thread to sample the pc for VM profiling.  The poll thread needs
 * to have a priority higher than the main VM thread and the poll thread needs
 * to have a priority higher than the poll thread to be able to profile it.
 * We would like POLL_THREAD_PRIORITY to be THREAD_PRIORITY_TIME_CRITICAL - 1
 * but SetThreadPriority fails with this value on Windows XP.
 *
 * N.B. THREAD_PRIORITY_TIME_CRITICAL a.k.a. THREAD_BASE_PRIORITY_LOWRT
 *      THREAD_PRIORITY_MAX a.k.a. THREAD_BASE_PRIORITY_MAX
 * See WinBase.h & WinNT.h.
 */
#if STACKVM
# define POLL_THREAD_PRIORITY THREAD_PRIORITY_HIGHEST
#endif /* STACKVM */
#define PROF_THREAD_PRIORITY THREAD_PRIORITY_TIME_CRITICAL

#if COGVM
extern void sqMakeMemoryExecutableFromTo(usqIntptr_t, usqIntptr_t);
extern void sqMakeMemoryNotExecutableFromTo(usqIntptr_t, usqIntptr_t);

extern int isCFramePointerInUse(void);
extern int osCogStackPageHeadroom(void);
extern void reportMinimumUnusedHeadroom(void);
#endif

/* Thread support for thread-safe signalSemaphoreWithIndex and/or the COGMTVM */
#if STACKVM || NewspeakVM
# define sqLowLevelYield() Sleep(0)
/* these are used both in the STACKVM & the COGMTVM */
# define sqOSThread DWORD
# define ioOSThreadsEqual(a,b) ((a) == (b))
# if COGMTVM
/* Please read the comment for CogThreadManager in the VMMaker package for
 * documentation of this API.
 */
#  define sqOSSemaphore void *
#  if !ForCOGMTVMImplementation /* this is a read-only export */
extern const unsigned long tltiIndex;
#  endif
#  define ioGetThreadLocalThreadIndex() ((long)TlsGetValue(tltiIndex))
#  define ioSetThreadLocalThreadIndex(v) (TlsSetValue(tltiIndex,(void*)(v)))
#  define ioTransferTimeslice() Sleep(0)
#  define ioMilliSleep(ms) Sleep(ms)
# endif /* COGMTVM */
#endif /* STACKVM || NewspeakVM */

#if defined(__GNUC__)
# if !defined(VM_LABEL)
#	define VM_LABEL(foo) asm("\n.globl L" #foo "\nL" #foo ":")
# endif
#endif
#if !defined(VM_LABEL) || COGVM
# undef VM_LABEL
# define VM_LABEL(foo) ((void)0)
#endif

/* Define the fields in a struct _CONTEXT as returned by GetThreadContext that
 * represent the program counter and frame pointer on the current architecture.
 */
#if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
#	define CONTEXT_PC Eip
#	define CONTEXT_FP Ebp
#	define CONTEXT_SP Esp
#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
#	define CONTEXT_PC Rip
#	define CONTEXT_FP Rbp
#	define CONTEXT_SP Rsp
#elif defined(_M_ARM64)
#	define CONTEXT_PC Rip
#	define CONTEXT_FP Rbp
#	define CONTEXT_SP Rsp
#else
# error "unknown architecture, program counter field undefined"
#endif
