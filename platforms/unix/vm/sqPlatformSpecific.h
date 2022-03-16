/* sqPlatformSpecific.h -- platform-specific modifications to sq.h
 * 
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 * 
 * Author: ian.piumarta@squeakland.org
 * 
 */

#ifndef _SQ_PLATFORM_SPECIFIC_H
#define _SQ_PLATFORM_SPECIFIC_H

#include <stdio.h>
#include "sqMemoryAccess.h"

#undef sqAllocateMemory
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

#if defined(__sqMemoryAccess_h) // Only define support API if we have sqInt etc
extern usqInt sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize);
#define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
sqAllocateMemory(minimumMemory, heapSize)
extern sqInt sqGrowMemoryBy(sqInt oldLimit, sqInt delta);
extern sqInt sqShrinkMemoryBy(sqInt oldLimit, sqInt delta);
extern sqInt sqMemoryExtraBytesLeft(sqInt includingSwap);
#if COGVM
extern int osCogStackPageHeadroom(void);
extern void reportMinimumUnusedHeadroom(void);
#endif

/* warnPrintf is provided (and needed) on the win32 platform.
 * But it may be mentioned elsewhere, so provide a suitable def.
 */
#define warnPrintf printf

/* Thread support for thread-safe signalSemaphoreWithIndex and/or the COGMTVM */
#if STACKVM || NewspeakVM
# define sqLowLevelYield() sched_yield()
# include <pthread.h>
# define sqOSThread pthread_t
/* these are used both in the STACKVM & the COGMTVM */
# define ioOSThreadsEqual(a,b) pthread_equal(a,b)
# define ioCurrentOSThread() pthread_self()
# if COGMTVM
/* Please read the comment for CogThreadManager in the VMMaker package for
 * documentation of this API.
 */
typedef struct {
		pthread_cond_t	cond;
		pthread_mutex_t mutex;
		int				count;
	} sqOSSemaphore;
#  define ioDestroyOSSemaphore(ptr) 0
#  if !ForCOGMTVMImplementation /* this is a read-only export */
extern const pthread_key_t tltiIndex;
#  endif
#  define ioGetThreadLocalThreadIndex() ((long)pthread_getspecific(tltiIndex))
#  define ioSetThreadLocalThreadIndex(v) (pthread_setspecific(tltiIndex,(void*)(v)))
#  define ioOSThreadIsAlive(thread) (pthread_kill(thread,0) == 0)
#  define ioTransferTimeslice() sched_yield()
#  define ioMilliSleep(ms) usleep((ms) * 1000)
# endif /* COGMTVM */
#endif /* STACKVM || NewspeakVM */

#include <sys/types.h>

typedef off_t squeakFileOffsetType;

#undef	sqFilenameFromString
#undef	sqFilenameFromStringOpen
#define sqFilenameFromStringOpen sqFilenameFromString

extern void sqFilenameFromString(char *uxName, sqInt stNameIndex, int sqNameLength);
#endif // defined(__sqMemoryAccess_h)

#undef dispatchFunctionPointer
#undef dispatchFunctionPointerOnin
/* we'd like to untypedef fptr too, but such is life */

#include <unistd.h> /* for declaration of ftruncate */

#undef	sqFTruncate
/* sqFTruncate should return 0 on success, ftruncate does also */
#define	sqFTruncate(f,o) ftruncate(fileno(f), o)

#if defined(__GNUC__)
# if !defined(VM_LABEL)
#	define VM_LABEL(foo) asm("\n.globl L" #foo "\nL" #foo ":")
# endif
#else
# if HAVE_ALLOCA_H
#   include <alloca.h>
# else
#   ifdef _AIX
#     pragma alloca
#   else
#     ifndef alloca /* predefined by HP cc +Olibcalls */
        char *alloca();
#     endif
#   endif
# endif
#endif

#if !defined(VM_LABEL) || COGVM || STACKVM
# undef VM_LABEL
# define VM_LABEL(foo) ((void)0)
#endif

/*
 * platforms/Cross/vm/sq.h defines getReturnAddress if not defined
 *
 * following code posted by Eliot Miranda
 * http://forum.world.st/builtin-extract-return-addr-td5122085.html
 *
 */

# if COGVM && defined(__SUNPRO_C)
# if defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__)
#   define getReturnAddress() ({ register usqIntptr_t retpc; asm volatile ("movl 4(%%ebp),%0" : "=r"(retpc) : ); retpc; })
# elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
#   define getReturnAddress() ({ register usqIntptr_t retpc; asm volatile ("movq 8(%%rbp),%0" : "=r"(retpc) : ); retpc; })
# else
#       error "Cog requires getReturnAddress defining for the current platform."
# endif /* defined(i386) */
# endif /* COGVM && defined(__SUNPRO_C) */

#endif /* _SQ_PLATFORM_SPECIFIC_H */
