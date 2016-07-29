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
#include <windows.h>
#include <math.h>
#include "sq.h"

/*****************************************************************************
  String conversions: Unicode / Ansi / Squeak
  NOTES: 
    1) The length of strings in inline functions MUST NOT exceed MAX_PATH.
    2) fromSqueak() and fromSqueak2() are inline conversions
       but operate on two different buffers.
    3) toUnicode() and fromUnicode() are inline conversions
       with for at most MAX_PATH sized strings. If the VM
       is not compiled with UNICODE defined they just return
       the input strings. Also, toUnicode operates on the
       same buffer as fromSqueak()
    4) toUnicodeNew and fromUnicodeNew malloc() new strings.
       It is up to the caller to free these!
*****************************************************************************/


#define MAX_BUFFER MAX_PATH
static TCHAR w_buffer1[MAX_BUFFER]; /* wide buffer 1 */
static TCHAR w_buffer2[MAX_BUFFER]; /* wide buffer 2 */
static char  a_buffer1[MAX_BUFFER]; /* ansi buffer 1 */

static TCHAR *fromSqueakInto(const char *sqPtr, int sqSize, TCHAR* buffer)
{
  int i;
  if(sqSize >= MAX_BUFFER) sqSize = MAX_BUFFER-1;
  for(i=0;i<sqSize;i++)
    buffer[i] = (unsigned char) (sqPtr[i]); /* will be extended with zeros */
  buffer[sqSize] = 0;
  return buffer;
}

TCHAR *fromSqueak(const char *sqPtr, int sqSize)
{
  return fromSqueakInto(sqPtr, sqSize, w_buffer1);
}

TCHAR *fromSqueak2(const char *sqPtr, int sqSize)
{
  return fromSqueakInto(sqPtr, sqSize, w_buffer2);
}

TCHAR *toUnicode(const char *ptr)
{
#ifdef UNICODE
  return fromSqueak(ptr, strlen(ptr));
#else
  return (char*) ptr;
#endif
}

char *fromUnicode(const TCHAR *ptr)
{
#ifdef UNICODE
  int i, size;
  size = lstrlen(ptr);
  if(size >= MAX_BUFFER) size = MAX_BUFFER - 1;
  for(i=0;i<size;i++)
    a_buffer1[i] = (unsigned char) ptr[i];
  a_buffer1[size] = 0;
  return a_buffer1;
#else
  return (char*) ptr;
#endif
}

TCHAR *toUnicodeNew(const char *ptr)
{ TCHAR *result;
  int i,size;

  size = strlen(ptr)+1;
  result = (TCHAR*) calloc(size,sizeof(TCHAR));
  for(i=0;i<size;i++)
    result[i] = (unsigned char) ptr[i];
  return result;
}

char *fromUnicodeNew(const TCHAR *ptr)
{ char *result;
  int i,size;

  size = lstrlen(ptr)+1;
  result = (char*) calloc(size,sizeof(char));
  for(i=0;i<size;i++)
    result[i] = (unsigned char) ptr[i];
  return result;
}

TCHAR *lstrrchr(TCHAR *source, TCHAR c)
{ TCHAR *tmp;

  /* point to the last char */
  tmp = source + lstrlen(source)-1;
  while(tmp >= source)
    if(*tmp == c) return tmp;
    else tmp--;
  return NULL;
}


/****************************************************************************/
/* Helper to pop up a message box with a message formatted from the         */
/*   printf() format string and arguments                                   */
/****************************************************************************/
#ifndef sqMessageBox
int __cdecl sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const char* fmt, ...)
{ TCHAR *ptr, *buf;
	va_list args;
  DWORD result;

  ptr = toUnicodeNew(fmt);
  buf = (TCHAR*) calloc(sizeof(TCHAR), 4096);
	va_start(args, fmt);
	wvsprintf(buf, ptr, args);
	va_end(args);

	result = MessageBox(stWindow,buf,titleString,dwFlags|MB_SETFOREGROUND);
  free(ptr);
  free(buf);
  return result;
}
#endif

/****************************************************************************/
/* Print out a message and abort execution                                  */
/****************************************************************************/
#ifndef abortMessage
int __cdecl abortMessage(const TCHAR* fmt, ...)
{ TCHAR *buf;
	va_list args;

  buf = (TCHAR*) calloc(sizeof(TCHAR), 4096);
	va_start(args, fmt);
	wvsprintf(buf, fmt, args);
	va_end(args);

	MessageBox(NULL,buf,TEXT(VM_NAME) TEXT("!"),MB_OK | MB_TASKMODAL | MB_SETFOREGROUND);
  free(buf);
  exit(-1);
}
#endif

/****************************************************************************/
/* Print out a warning message                                              */
/****************************************************************************/
#ifndef warnPrintf
int __cdecl warnPrintf(const TCHAR *fmt, ...)
{ TCHAR *buf;
	va_list args;

  buf = (TCHAR*) calloc(sizeof(TCHAR), 4096);
	va_start(args, fmt);
	wvsprintf(buf, fmt, args);
	va_end(args);
  MessageBox(stWindow, buf, TEXT(VM_NAME) TEXT(" Warning!"), MB_OK | MB_ICONSTOP | MB_SETFOREGROUND);
  free(buf);
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
  warnPrintf(TEXT("%s (%ld) -- %s\n"), prefix, lastError, lpMsgBuf);
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
  warnPrintf(TEXT("%s (%ld: %s)\n"), buf, lastError, lpMsgBuf);
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
