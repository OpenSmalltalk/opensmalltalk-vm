/****************************************************************************
*   PROJECT: Platform-specific prototypes and definitions for the mac
*   FILE:    sqPlatformSpecific.h
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
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
#include <Types.h>
//#define SQUEAK_BUILTIN_PLUGIN
#define ENABLE_URL_FETCH
/* replace the image file manipulation macros with functions */
#undef sqImageFile
#undef sqImageFileClose
#undef sqImageFileOpen
#undef sqImageFilePosition
#undef sqImageFileRead
#undef sqImageFileSeek
#undef sqImageFileWrite
#undef sqImageFileStartLocation

#undef sqAllocateMemory

//64bit function pointers undef
#undef dispatchFunctionPointer
#undef dispatchFunctionPointerOnin

#undef squeakFileOffsetType
#define squeakFileOffsetType off_t

#undef sqFTruncate
#define sqFTruncate(f,o) ftruncate(fileno(f), o)

// CARBON

    #ifdef TARGET_API_MAC_CARBON  
        #undef TARGET_API_MAC_CARBON
        #define TARGET_API_MAC_CARBON 1
    #else
      #define TARGET_API_MAC_CARBON 1
    #endif 
    #define ftell ftello
    #define fseek fseeko
	int	 ftruncate(int, off_t);
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
squeakFileOffsetType       sqImageFileStartLocation(sqInt fileRef, char *filename,squeakFileOffsetType imageSize);

usqInt	    sqAllocateMemoryMac(sqInt desiredHeapSize , sqInt minHeapSize, FILE * f,usqInt headersize);
#undef allocateMemoryMinimumImageFileHeaderSize
#define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
	sqAllocateMemoryMac(heapSize, minimumMemory, fileStream, headerSize)
#undef sqImageFileReadEntireImage
size_t      sqImageFileReadEntireImage(void *ptr,  size_t elementSize, size_t count, sqImageFile f);
#define sqImageFileReadEntireImage(memoryAddress, elementSize,  length, fileStream) \
	sqImageFileReadEntireImage(memoryAddress, elementSize, length, fileStream)

/* override reserveExtraCHeapBytes() macro to reduce Squeak object heap size on Mac */
#undef reserveExtraCHeapBytes
#define reserveExtraCHeapBytes(origHeapSize, bytesToReserve) (origHeapSize - bytesToReserve)

/* undefine clock macros that are implemented as functions */
#undef ioLowResMSecs
#undef ioMicroMSecs
#undef ioMSecs
#define ioMSecs ioMicroMSecs
#undef ioMicroSecondClock
#define ioMicroSecondClock ioMicroSeconds
#define ioUtcWithOffset ioUtcWithOffset

/* macro to return from interpret() loop in browser plugin VM */
#define ReturnFromInterpret() return

/* prototypes missing from CW11 headers */
#include <TextUtils.h>
void CopyPascalStringToC(ConstStr255Param src, char* dst);
void CopyCStringToPascal(const char* src, Str255 dst);

/* undef the memory routines for our logic */
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

sqInt sqGrowMemoryBy(sqInt memoryLimit, sqInt delta);
sqInt sqShrinkMemoryBy(sqInt memoryLimit, sqInt delta);
sqInt sqMemoryExtraBytesLeft(Boolean flag);

    #undef insufficientMemorySpecifiedError
    #undef insufficientMemoryAvailableError
    #undef unableToReadImageError
    #undef browserPluginReturnIfNeeded
    #undef browserPluginInitialiseIfNeeded
    #define insufficientMemorySpecifiedError() plugInNotifyUser("The amount of memory specified by the 'memory' EMBED tag is not enough for the installed Squeak image file.")
    #define insufficientMemoryAvailableError() plugInNotifyUser("There is not enough memory to give Squeak the amount specified by the 'memory' EMBED tag.")
    #define unableToReadImageError() plugInNotifyUser("Read failed or premature end of image file")
    #define browserPluginReturnIfNeeded() if (plugInTimeToReturn()) {ReturnFromInterpret();}
    #define browserPluginInitialiseIfNeeded()

//exupery
#define addressOf(x) &x

#endif /* macintoshSqueak */


