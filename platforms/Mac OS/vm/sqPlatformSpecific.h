/* sqPlatformSpecific.h -- Platform-specific prototypes and definitions */

/* How to use this file:
   This file is for general platform-specific macros and declarations.
   Function prototypes that are unlikely to introduce name conflicts on
   other platforms can be added directly. Macro re-definitions or conflicting
   function prototypes can be wrapped in a #ifdefs. Alternatively, a customized
   version of this file can be used on that platform. The goal is to keep all
   the other header files generic across platforms. To override a definition or
   macro from sq.h, you must first #undef it, then provide the new definition.
*/

#ifdef macintoshSqueak

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

// CARBON
#if defined (__APPLE__) && defined(__MACH__)

    #ifdef TARGET_API_MAC_CARBON  
        #undef TARGET_API_MAC_CARBON
        #define TARGET_API_MAC_CARBON 1
    #else
      #define TARGET_API_MAC_CARBON 1
    #endif 
    #undef ioLowResMSecs
    typedef FILE *sqImageFile;
#else
    #define sqFilenameFromStringOpen(dst, src, num) sqFilenameFromString(dst, src, num)
    #if defined(__MWERKS__) & !TARGET_API_MAC_CARBON
        #include <stat.h>
    #endif

    #if !defined(off_t)
    #define off_t long long
    #endif 
    #if !defined(fseeko)
    #define fseeko fseek
    #endif 
    #if !defined(ftello)
    #define ftello ftell
    #endif 
    int ftruncate(short int file,int offset);
	#if TARGET_API_MAC_CARBON
 	#else
 	   #define fileno(n) n->handle
	#endif
    typedef int sqImageFile;

#endif
  
#if TARGET_API_MAC_CARBON
    #undef sqFilenameFromStringOpen
    #undef sqFilenameFromString
    void	makeOSXPath(char * dst, int src, int num,Boolean resolveAlias);
    #define sqFilenameFromStringOpen(dst, src, num) makeOSXPath(dst,src,num,true)
    #define sqFilenameFromString(dst, src, num) makeOSXPath(dst,src,num,false)
#endif

void        sqImageFileClose(sqImageFile f);
sqImageFile sqImageFileOpen(char *fileName, char *mode);
off_t       sqImageFilePosition(sqImageFile f);
size_t      sqImageFileRead(void *ptr, size_t elementSize, size_t count, sqImageFile f);
void        sqImageFileSeek(sqImageFile f, off_t pos);
int         sqImageFileWrite(void *ptr, size_t elementSize, size_t count, sqImageFile f);
off_t       sqImageFileStartLocation(int fileRef, char *filename, off_t imageSize);
void *	    sqAllocateMemory(int minHeapSize, int desiredHeapSize);


/* override reserveExtraCHeapBytes() macro to reduce Squeak object heap size on Mac */
#undef reserveExtraCHeapBytes
#define reserveExtraCHeapBytes(origHeapSize, bytesToReserve) (origHeapSize - bytesToReserve)

/* undefine clock macros that are implemented as functions */
#undef ioMicroMSecs
#undef ioMSecs
#define ioMSecs ioMicroMSecs

/* macro to return from interpret() loop in browser plugin VM */
#define ReturnFromInterpret() return

/* prototypes missing from CW11 headers */
#include <textutils.h>
void CopyPascalStringToC(ConstStr255Param src, char* dst);
void CopyCStringToPascal(const char* src, Str255 dst);

/* undef the memory routines for our logic */
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

int sqGrowMemoryBy(int memoryLimit, int delta);
int sqShrinkMemoryBy(int memoryLimit, int delta);
int sqMemoryExtraBytesLeft(Boolean flag);

#endif /* macintoshSqueak */


