#ifndef SQ_WIN32_H
#define SQ_WIN32_H

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

void printLastError(const TCHAR *prefix);
int sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const char* fmt, ...);

void sqWin32PrintLastError(const char *message);

TCHAR *fromSqueak(const char *sqPtr, int sqSize);
TCHAR *fromSqueak2(const char *sqPtr, int sqSize);

extern BOOL fIsConsole;

#endif /*SQ_WIN32_H*/
