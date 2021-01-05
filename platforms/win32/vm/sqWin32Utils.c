/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Utils.c
*   CONTENT: Utilities
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*****************************************************************************/
#include <Windows.h>
#include <tchar.h>
#include <math.h>
#include "sq.h"


/****************************************************************************/
/* Helper to pop up a message box with a message formatted from the         */
/*   printf() format string and arguments                                   */
/****************************************************************************/
#ifndef sqMessageBox
int __cdecl
sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const TCHAR *fmt, ...)
{	TCHAR *buf;
	va_list args;
	DWORD result;

	buf = (TCHAR*) calloc(sizeof(TCHAR), 4096);
	va_start(args, fmt);
#if _UNICODE
	_vsnwprintf(buf, 4096-1, fmt, args);
#else
	_vsntprintf(buf, 4096-1, fmt, args);
#endif
	va_end(args);

	result = MessageBox(stWindow,buf,titleString,dwFlags|MB_SETFOREGROUND);
	free(buf);
	return result;
}
#endif

/****************************************************************************/
/* Print out a message and abort execution                                  */
/****************************************************************************/
#ifndef abortMessage
int __cdecl
abortMessage(TCHAR *fmt, ...)
{ TCHAR *buf;
	va_list args;

	va_start(args, fmt);
	if (fIsConsole) {
#if _UNICODE
		vfwprintf(stderr, fmt, args);
#else
		vfprintf(stderr, fmt, args);
#endif
		exit(-1);
	}
	buf = (TCHAR*) calloc(sizeof(TCHAR), 4096);
	if (fmt[_tcslen(fmt)-1] == '\n')
		fmt[_tcslen(fmt)-1] = 0;
#if _UNICODE
	wvsprintf(buf, fmt, args);
#else
	vsprintf(buf, fmt, args);
#endif
	va_end(args);

	MessageBox(NULL,buf,TEXT(VM_NAME) TEXT("!"),MB_OK | MB_TASKMODAL | MB_SETFOREGROUND);
	free(buf);
	exit(-1);
	return 0;
}
#endif

/****************************************************************************/
/* Print out a warning message                                              */
/****************************************************************************/
#ifndef warnPrintf
int __cdecl
warnPrintf(char *fmt, ...)
{ char *buf;
  va_list args;
  
  va_start(args, fmt);
  if (fIsConsole)
    vfprintf(stderr, fmt, args);
  
  buf = (char*) calloc(sizeof(char), 4096);
  if (fmt[strlen(fmt)-1] == '\n')
    fmt[strlen(fmt)-1] = 0;
  vsprintf(buf, fmt, args);
  va_end(args);
  MessageBoxA(stWindow, buf, VM_NAME " Warning!", MB_OK | MB_ICONSTOP | MB_SETFOREGROUND);
  free(buf);
  return 0;
}
#endif

#ifndef warnPrintfW
int __cdecl
warnPrintfW(WCHAR *fmt, ...)
{
 WCHAR *buf;
 va_list args;
 
 va_start(args, fmt);
 if (fIsConsole)
   vfwprintf(stderr, fmt, args);
 
 buf = (WCHAR*)calloc(sizeof(WCHAR), 4096);
 if (fmt[wcslen(fmt) - 1] == '\n')
   fmt[wcslen(fmt) - 1] = 0;
 _vswprintf(buf, fmt, args);
 va_end(args);
 MessageBoxW(stWindow, buf, _UNICODE_TEXT(VM_NAME) L" Warning!", MB_OK | MB_ICONSTOP | MB_SETFOREGROUND);
 free(buf);
 return 0;
}
#endif

/****************************************************************************/
/*                      Printing of GetLastError's                          */
/****************************************************************************/
#ifndef printLastError
void printLastError(TCHAR *prefix)
{ LPVOID lpMsgBuf;
  DWORD lastError;

  lastError = GetLastError();
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |  FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                (LPTSTR) &lpMsgBuf, 0, NULL );
  warnPrintfT(TEXT("%s (%ld) -- %s\n"), prefix, lastError, (LPTSTR)lpMsgBuf);
  LocalFree( lpMsgBuf );
}
#endif
#ifndef vprintLastError
void vprintLastError(TCHAR *fmt, ...)
{ LPVOID lpMsgBuf;
  DWORD lastError;
  TCHAR *buf;
  va_list args;

  buf = (TCHAR*) calloc(sizeof(TCHAR), 4096);
  va_start(args, fmt);
  wvsprintf(buf, fmt, args);
  va_end(args);

  lastError = GetLastError();
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |  FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                (LPTSTR) &lpMsgBuf, 0, NULL );
  warnPrintfT(TEXT("%s (%ld: %s)\n"), buf, lastError, (LPTSTR)lpMsgBuf);
  LocalFree( lpMsgBuf );
  free(buf);
}
#endif


/************************************************************************************/
/* missing round function in MSVC before 2013                                       */
/* http://stackoverflow.com/questions/485525/round-for-float-in-c/11074691#11074691 */
/************************************************************************************/
#if defined(_MSC_VER) && (_MSC_VER < 1800)
double round(double x)
{
    double truncated,roundedFraction;
    double fraction= modf(x, &truncated);
    modf(2.0*fraction, &roundedFraction);
    return truncated + roundedFraction;
}
#endif
