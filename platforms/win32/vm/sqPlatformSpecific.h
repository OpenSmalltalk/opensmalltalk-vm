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

#define squeakFileOffsetType int;
#define size_t int

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
int sqImageFilePosition(sqImageFile h);
int sqImageFileRead(void *ptr, int sz, int count, sqImageFile h);
int sqImageFileSeek(sqImageFile h, int pos);
int sqImageFileWrite(void *ptr, int sz, int count, sqImageFile h);

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

/* Declare GetTickCount() in case <windows.h> is not included */
#if !defined(_WINDOWS_) && !defined(_WIN32_WCE) && !defined(_WINDOWS_H)
__declspec(dllimport) unsigned long __stdcall GetTickCount(void);
#endif

#define ioLowResMSecs() GetTickCount()
#else error!
#endif /* WIN32 */

