/* win32 sqPlatformSpecific.h -- Platform-specific prototypes and definitions */

/* How to use this file:
   This file is for general platform-specific macros and declarations.
   The goal is to keep most of the other header files generic across platforms.
   To override a definition or macro from sq.h, you must first #undef it, then
   provide the new definition.

*/



#ifdef WIN32
/* Override necessary definitions */
#undef putchar
#include "sqWin32Alloc.h"

#ifdef _MSC_VER
#define squeakFileOffsetType __int64
#else
#define squeakFileOffsetType unsigned long long
#endif

#ifdef WIN32_FILE_SUPPORT

#undef sqImageFile
#undef sqImageFileClose
#undef sqImageFileOpen
#undef sqImageFilePosition
#undef sqImageFileRead
#undef sqImageFileSeek
#undef sqImageFileWrite

#define sqImageFile unsigned long
int sqImageFileClose(sqImageFile h);
sqImageFile sqImageFileOpen(char *fileName, char *mode);
squeakFileOffsetType sqImageFilePosition(sqImageFile h);
size_t sqImageFileRead(void *ptr, size_t sz, size_t count, sqImageFile h);
squeakFileOffsetType sqImageFileSeek(sqImageFile h, squeakFileOffsetType pos);
size_t sqImageFileWrite(void *ptr, size_t sz, size_t count, sqImageFile h);

#endif /* WIN32_FILE_SUPPORT */

/* pluggable primitive support */
#if defined(_MSC_VER) || defined(__MINGW32__)
#  undef EXPORT
#  define EXPORT(returnType) __declspec( dllexport ) returnType
#  undef VM_EXPORT
#  define VM_EXPORT __declspec( dllexport ) 
#endif 

#if defined(_MSC_VER) || defined(__MINGW32__)
# define fabsf(x)    ((float)fabs((double)(x)))
#endif

/* undefine clock macros that are implemented as functions */
#undef ioMSecs
#undef ioLowResMSecs
#undef ioMicroMSecs

#else 
error "Not Win32!"
#endif /* WIN32 */

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
extern void sqMakeMemoryExecutableFromTo(unsigned long, unsigned long);
extern void sqMakeMemoryNotExecutableFromTo(unsigned long, unsigned long);

extern int isCFramePointerInUse(void);
extern int osCogStackPageHeadroom(void);
extern void reportMinimumUnusedHeadroom(void);
#endif

/* Thread support for thread-safe signalSemaphoreWithIndex and/or the COGMTVM */
#if STACKVM || NewspeakVM
# define sqLowLevelYield() Sleep(0)
/* these are used both in the STACKVM & the COGMTVM */
# define sqOSThread void *
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
# define VM_LABEL(foo) 0
#endif
