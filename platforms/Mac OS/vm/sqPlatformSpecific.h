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

#ifdef macintosh

// CARBON
#if defined (__APPLE__) && defined(__MACH__)

    #ifdef TARGET_API_MAC_CARBON  
        #undef TARGET_API_MAC_CARBON
        #define TARGET_API_MAC_CARBON 1
    #else
      #define TARGET_API_MAC_CARBON 1
    #endif 
#endif
/*
    #ifdef TARGET_API_MAC_CARBON  
        #undef TARGET_API_MAC_CARBON
        #define TARGET_API_MAC_CARBON 1
    #else
      #define TARGET_API_MAC_CARBON 1
    #endif 
*/

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

typedef int sqImageFile;
void        sqImageFileClose(sqImageFile f);
sqImageFile sqImageFileOpen(char *fileName, char *mode);
int         sqImageFilePosition(sqImageFile f);
int         sqImageFileRead(void *ptr, int elementSize, int count, sqImageFile f);
void        sqImageFileSeek(sqImageFile f, int pos);
int         sqImageFileWrite(void *ptr, int elementSize, int count, sqImageFile f);
int         sqImageFileStartLocation(int fileRef, char *filename, int imageSize);
void *						sqAllocateMemory(int minHeapSize, int desiredHeapSize);

/* override reserveExtraCHeapBytes() macro to reduce Squeak object heap size on Mac */
#undef reserveExtraCHeapBytes
#define reserveExtraCHeapBytes(origHeapSize, bytesToReserve) (origHeapSize - bytesToReserve)

/* undefine clock macros that are implemented as functions */
#undef ioMSecs
#undef ioMicroMSecs

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
int ftruncate(FILE	*file,int offset);

#endif /* macintosh */


