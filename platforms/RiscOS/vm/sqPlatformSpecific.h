/* Acorn sqPlatformSpecific.h -- Platform-specific prototypes and definitions */

/* How to use this file:
   This file is for general platform-specific macros and declarations.
   The goal is to keep most of the other header files generic across platforms.
   To override a definition or macro from sq.h, you must first #undef it, then
   provide the new definition.

*/


#ifdef ACORN

#include "oslib/os.h"
/* acorn memory allocation */
#undef sqAllocateMemory
#define sqAllocateMemory(minHeapSize, desiredHeapSize) platAllocateMemory(desiredHeapSize)

#undef sqFilenameFromString
extern void sqFilenameFromString(char*fileName, int sqString, int sqSize);
#define sqFilenameFromString(dst, src, num) sqFilenameFromString(dst, src, num)

#define squeakFileOffsetType int

/* string copying macro to compensate for bug in Acorn library code */
#define copyNCharsFromTo(num, src, dst)\
if(1) {int sqfni;\
	char cc;\
	for (sqfni = 0; sqfni < num; sqfni++) {\
		dst[sqfni] = cc = *((char *) (src + sqfni));\
		if ( cc == 0) break;\
	}\
	dst[num] = 0;\
}

/* undefine clock macros that are implemented as functions */
#undef ioMicroMSecs
#undef ioMSecs
#define ioMSecs() (10* (int)os_read_monotonic_time())
#undef ioLowResMSecs
#define ioLowResMSecs() (ioMSecs())
#else
#endif /* ACORN */
