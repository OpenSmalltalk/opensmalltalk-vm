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
#endif 

/* undefine clock macros that are implemented as functions */
#undef ioMSecs
#undef ioLowResMSecs
#undef ioMicroMSecs

#if 0 /* no longer used - phase this out */
/* Declare GetTickCount() in case <windows.h> is not included */
#if !defined(_WINDOWS_) && !defined(_WIN32_WCE) && !defined(_WINDOWS_H)
__declspec(dllimport) unsigned long __stdcall GetTickCount(void);
#endif
#endif

#define ioLowResMSecs() _lowResMSecs
#else error!
#endif /* WIN32 */

