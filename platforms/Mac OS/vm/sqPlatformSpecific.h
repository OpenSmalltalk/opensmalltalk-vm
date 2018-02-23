/****************************************************************************
*   PROJECT: Platform-specific prototypes and definitions for the mac
*   FILE:    sqPlatformSpecific.h
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqPlatformSpecific.h 1708 2007-06-10 00:40:04Z johnmci $
*
*   Jan 22nd 2002, JMM type for squeak file offset
*   May 5th, 2002, JMM added define for plugin for CW
*   May 12th, 2002, JMM added SQUEAK_BUILTIN_PLUGIN for CW Pro
*   3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
*   3.5.1  May 28th, 2003 JMM SQUEAK_BUILTIN_PLUGIN in PB defs
*	3.8.8b2 May 23rd, 2005 JMM Undef 64bit procedure function ptrs
*	3.8.14b1 Oct	,2006 JMM browser rewrite
*
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

#ifdef macintoshSqueak
#if defined(TARGET_API_MAC_CARBON)
# include <Types.h>
#endif
#define ENABLE_URL_FETCH
/* replace the image file manipulation macros with functions */
#undef sqImageFile
#undef sqImageFileClose
#undef sqImageFileOpen
#undef sqImageFilePosition
#undef sqImageFileRead
#undef sqImageFileSeek
#undef sqImageFileWrite

#undef sqAllocateMemory

//64bit function pointers undef
#undef dispatchFunctionPointer
#undef dispatchFunctionPointerOnin

#undef squeakFileOffsetType
#define squeakFileOffsetType off_t

#include <unistd.h> /* for declaration of ftruncate */

#undef sqFTruncate
/* sqFTruncate should return 0 on success, ftruncate does also */
#define sqFTruncate(f,o) ftruncate(fileno(f), o)
#define ftell ftello
#define fseek fseeko

typedef FILE *sqImageFile;

#undef sqFilenameFromStringOpen
#undef sqFilenameFromString
void		sqFilenameFromStringOpen(char *buffer,sqInt fileIndex, long fileLength);
void		sqFilenameFromString(char *buffer,sqInt fileIndex, long fileLength);
void        sqImageFileClose(sqImageFile f);
sqImageFile sqImageFileOpen(char *fileName, char *mode);
squeakFileOffsetType       sqImageFilePosition(sqImageFile f);
size_t      sqImageFileRead(void *ptr, size_t elementSize, size_t count, sqImageFile f);
void        sqImageFileSeek(sqImageFile f, squeakFileOffsetType pos);
sqInt       sqImageFileWrite(void *ptr, size_t elementSize, size_t count, sqImageFile f);

#if SPURVM
extern usqInt sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize);
# define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
	sqAllocateMemory(minimumMemory, heapSize)
# define sqMacMemoryFree() 0
#else
extern usqInt sqAllocateMemoryMac(usqInt desiredHeapSize, usqInt minHeapSize);
# define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
	sqAllocateMemoryMac(heapSize, minimumMemory)

# define sqAllocateMemory(x,y) sqAllocateMemoryMac(&y,x)
#endif

/* override reserveExtraCHeapBytes() macro to reduce Squeak object heap size on Mac */
#undef reserveExtraCHeapBytes
#define reserveExtraCHeapBytes(origHeapSize, bytesToReserve) (origHeapSize - bytesToReserve)

/* undefine clock macros that are implemented as functions */
#undef ioMicroMSecs
#undef ioMSecs
#if STACKVM /* In the Cog VMs time management is in sqUnixHeartbeat.c */
#else
#define ioMSecs ioMicroMSecs
#endif

/* macro to return from interpret() loop in browser plugin VM */
#define ReturnFromInterpret() return 0

// CARBON

#ifdef TARGET_API_MAC_CARBON  
# undef TARGET_API_MAC_CARBON
# define TARGET_API_MAC_CARBON 1
#endif 

#if defined(TARGET_API_MAC_CARBON)
/* prototypes missing from CW11 headers */
#include <TextUtils.h>
void CopyPascalStringToC(ConstStr255Param src, char* dst);
void CopyCStringToPascal(const char* src, Str255 dst);
#endif


/* C99 vs C89 restrict or not */
#if __STDC_VERSION__ < 199901L
# if __GNUC__
#	define restrict __restrict
# else
#	define restrict /*nada*/
# endif
#endif


/* Macro for inlined functions.
	As of 1.7, clang elides the original, even though global.
	gcc & icc don't elide the original
*/
#if defined(__clang__)
# define inline_and_export /* nada */
#else
# define inline_and_export inline
#endif

/* undef the memory routines for our logic */
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

sqInt sqGrowMemoryBy(sqInt memoryLimit, sqInt delta);
sqInt sqShrinkMemoryBy(sqInt memoryLimit, sqInt delta);
sqInt sqMemoryExtraBytesLeft(int flag);
#if COGVM
extern void sqMakeMemoryExecutableFromTo(unsigned long, unsigned long);
extern void sqMakeMemoryNotExecutableFromTo(unsigned long, unsigned long);

extern int isCFramePointerInUse(void);
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

#ifdef BROWSERPLUGIN
# undef insufficientMemorySpecifiedError
# undef insufficientMemoryAvailableError
# undef unableToReadImageError
# undef browserPluginReturnIfNeeded
# undef browserPluginInitialiseIfNeeded
# define insufficientMemorySpecifiedError() plugInNotifyUser("The amount of memory specified by the 'memory' EMBED tag is not enough for the installed Squeak image file.")
# define insufficientMemoryAvailableError() plugInNotifyUser("There is not enough memory to give Squeak the amount specified by the 'memory' EMBED tag.")
# define unableToReadImageError() plugInNotifyUser("Read failed or premature end of image file")
# define browserPluginReturnIfNeeded() if (plugInTimeToReturn()) {ReturnFromInterpret();}
# define browserPluginInitialiseIfNeeded()
#endif

//exupery
#define addressOf(x) &x

// From Joshua Gargus, for XCode 3.1
#ifdef __GNUC__
# undef EXPORT
# define EXPORT(returnType) __attribute__((visibility("default"))) returnType
# if !defined(VM_LABEL)
#	define VM_LABEL(foo) asm("\n.globl L" #foo "\nL" #foo ":")
# endif
#endif

#if !defined(VM_LABEL) || COGVM
# undef VM_LABEL
# define VM_LABEL(foo) 0
#endif
#endif /* macintoshSqueak */
