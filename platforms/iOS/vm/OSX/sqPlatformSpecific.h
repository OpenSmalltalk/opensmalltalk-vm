/****************************************************************************
*   PROJECT: Platform-specific prototypes and definitions for the iPhone
*   FILE:    sqPlatformSpecific.h
*   CONTENT: 
*
*   AUTHOR:  John McIntosh
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   
 
   How to use this file:
   This file is for general platform-specific macros and declarations.
   Function prototypes that are unlikely to introduce name conflicts on
   other platforms can be added directly. Macro re-definitions or conflicting
   function prototypes can be wrapped in a #ifdefs. Alternatively, a customized
   version of this file can be used on that platform. The goal is to keep all
   the other header files generic across platforms. To override a definition or
   macro from sq.h, you must first #undef it, then provide the new definition.
   
   Define plugin for Netscape Plugin building, needed for CodeWarrior
*/
/*
 Copyright (c) 2000-2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */
//

#ifdef macintoshSqueak
//#define SQUEAK_BUILTIN_PLUGIN
#define ENABLE_URL_FETCH
/* replace the image file manipulation macros with functions */


#undef sqAllocateMemory

//64bit function pointers undef
#undef dispatchFunctionPointer
#undef dispatchFunctionPointerOnin

#undef squeakFileOffsetType
#define squeakFileOffsetType off_t
#include <unistd.h>

#undef sqFTruncate
#define sqFTruncate(f,o) ftruncate(fileno(f), o)
#define ftell ftello
#define fseek fseeko
//int	 ftruncate(int, off_t);

#undef sqFilenameFromStringOpen
#undef sqFilenameFromString
void		sqFilenameFromStringOpen(char *buffer,sqInt fileIndex, long fileLength);
void		sqFilenameFromString(char *buffer,sqInt fileIndex, long fileLength);
#undef allocateMemoryMinimumImageFileHeaderSize
#undef sqImageFileReadEntireImage
#if SPURVM
extern usqInt sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize);
# define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
sqAllocateMemory(minimumMemory, heapSize)
# define sqMacMemoryFree() 
#else
usqInt sqAllocateMemoryMac(usqInt desiredHeapSize,sqInt minHeapSize, FILE * f,usqInt headersize);
#define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
sqAllocateMemoryMac(heapSize, minimumMemory, fileStream, headerSize)
#endif

#ifdef BUILD_FOR_OSX
size_t sqImageFileReadEntireImage(void *ptr, size_t elementSize, size_t count, FILE * f);
#define sqImageFileReadEntireImage(memoryAddress, elementSize,  length, fileStream) \
sqImageFileReadEntireImage(memoryAddress, elementSize, length, fileStream)
#else
#include <dlfcn.h>
#define sqImageFileReadEntireImage(memoryAddress, elementSize,  length, fileStream) length 
#endif

#undef ioMSecs
#define ioUtcWithOffset ioUtcWithOffset

/* macro to return from interpret() loop in browser plugin VM */
#define ReturnFromInterpret() return 0

/* undef the memory routines for our logic */
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

sqInt sqGrowMemoryBy(sqInt memoryLimit, sqInt delta);
sqInt sqShrinkMemoryBy(sqInt memoryLimit, sqInt delta);
sqInt sqMemoryExtraBytesLeft(sqInt includingSwap);

    #undef insufficientMemorySpecifiedError
    #undef insufficientMemoryAvailableError
    #undef unableToReadImageError
int plugInNotifyUser(char *msg);
    #define insufficientMemorySpecifiedError() plugInNotifyUser("The amount of memory specified by the Setting Slider is not enough for the installed Squeak image file.")
    #define insufficientMemoryAvailableError() plugInNotifyUser("There is not enough memory to give Squeak the amount specified by the Setting Slider")
    #define unableToReadImageError() plugInNotifyUser("Read failed or premature end of image file")
	#undef browserPluginReturnIfNeeded
	int plugInTimeToReturn(void);
	#define browserPluginReturnIfNeeded() if (plugInTimeToReturn()) {ReturnFromInterpret();}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);

#if COGVM
extern void sqMakeMemoryExecutableFromTo(unsigned long, unsigned long);
extern void sqMakeMemoryNotExecutableFromTo(unsigned long, unsigned long);

extern int isCFramePointerInUse(void);
extern int osCogStackPageHeadroom(void);
extern void reportMinimumUnusedHeadroom(void);
#endif

/* Thread support for thread-safe signalSemaphoreWithIndex and/or the COGMTVM */
#if STACKVM
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
#endif /* STACKVM */

/* warnPrintf is provided (and needed) on the win32 platform.
 * But it may be mentioned elsewhere, so provide a suitable def.
 */
#define warnPrintf printf

// From Joshua Gargus, for XCode 3.1
#ifdef __GNUC__
# undef EXPORT
# define EXPORT(returnType) __attribute__((visibility("default"))) returnType
//# define VM_LABEL(foo) asmXXX("\n.globl L" #foo "\nL" #foo ":")
# define VM_LABEL(foo)  
#endif

#if !defined(VM_LABEL) || COGVM
# undef VM_LABEL
# define VM_LABEL(foo) 0
#endif

#endif /* macintoshSqueak */


