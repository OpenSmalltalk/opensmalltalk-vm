#ifndef SQ_WIN32_H
#define SQ_WIN32_H

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

/* Note: a character can require up to 4 bytes in UTF8 encoding
   But the expansion from UTF16 -> UTF8 is never more than 3 bytes for 1 short
   U+ 0000-U+  007F - 1byte in utf8, 1 short in utf16.
   U+ 0080-U+  07FF - 2byte in utf8, 1 short in utf16.
   U+ 0800-U+  FFFF - 3byte in utf8, 1 short in utf16.
   U+10000-U+10FFFF - 4byte in utf8, 2 short in utf16.
*/
#define MAX_PATH_UTF8 (MAX_PATH*3)

/* required for compilation of SecurityPlugin */
extern char  squeakIniNameA[];   /* full path to ini file - UTF8 */
extern WCHAR squeakIniNameW[];   /* full path to ini file - UTF16 */
#ifdef UNICODE
#define squeakIniName squeakIniNameW
#else
#define squeakIniName squeakIniNameA
#endif

void printLastError(const TCHAR *prefix);
int sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const char* fmt, ...);

void sqWin32PrintLastError(const char *message);

extern BOOL fIsConsole;

#endif /*SQ_WIN32_H*/
