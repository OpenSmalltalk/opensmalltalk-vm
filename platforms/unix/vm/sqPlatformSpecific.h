/* Unix sqPlatformSpecific.h -- Platform-specific prototypes and definitions */

/* How to use this file:
   This file is for general platform-specific macros and declarations.
   The goal is to keep most of the other header files generic across platforms.
   To override a definition or macro from sq.h, you must first #undef it, then
   provide the new definition.

*/



#ifdef UNIX
#include <string.h>
#include <stdio.h>


/* off_t should be available (XXX though really, we should
   autoconf-check this, and substitute whatever fseeko is using) */
typedef off_t squeakFileOffsetType;



/* unix-specific prototypes and definitions */
void aioPollForIO(int microSeconds, int extraFd);  /* XXX should no longer be needed -lex */
#define SQ_FORM_FILENAME        "squeak-form.ppm"
#define sqFilenameFromStringOpen(dst, src, num) sqFilenameFromString(dst, src, num)

/* undefine clock macros that are implemented as functions */
#undef ioMSecs
#undef ioMicroMSecs
#undef ioLowResMSecs




/* use non-default heap-allocation functions; see sqUnixMemory.c */
#undef sqAllocateMemory
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

void * sqAllocateMemory(int minHeapSize, int desiredHeapSize);
int sqGrowMemoryBy(int oldLimit, int delta);
int sqShrinkMemoryBy(int oldLimit, int delta);
int sqMemoryExtraBytesLeft(int includingSwap);
  




#ifdef sqImageFileOpen  /* this is horrible, but is necessary because
                           plugins don't include sq.h; so, we should
                           redefine these macros only when all of sq.h
                           is being used */

/* use non-default image IO functions; see sqUnixImage.c */
#undef sqImageFileOpen
#undef sqImageFileStartLocation

sqImageFile sqImageFileOpen(const char *fileName, const char *mode);
int sqImageFileStartLocation(sqImageFile file, const char *fileName, int size);
#endif


#else

#error This sqPlatformSpecific.h file is for Unix; you either have the wrong source code, or you forgot to -DUNIX

#endif /* UNIX */

