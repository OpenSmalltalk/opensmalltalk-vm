#include <stdio.h>
#include <stdarg.h>
#include "sq.h"
#include "sqConfig.h"

#ifdef error
#undef error

void error(char *errorMessage)
{
    sqError(errorMessage);
}
#endif

void sqError(char *errorMessage)
{
    fprintf(stderr, "%s\n", errorMessage);
    abort();
}


#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define PRINTF_BUFFER_SIZE 4096

void sqMessagePrintf(const char *format, ...)
{
    va_list args;
    char *buffer;
  
    va_start (args, format);
    if (!GetConsoleCP())
    {
        buffer = (char*)calloc(PRINTF_BUFFER_SIZE, sizeof(char));
        vsnprintf(buffer, sizeof(buffer), format, args);
        OutputDebugStringA(buffer);
        free(buffer);
    }
    else
    {
        vfprintf(stdout, format, args);
    }
    va_end (args);
}

void sqWarnPrintf(const char *format, ...)
{
    va_list args;
    char *buffer;
  
    va_start (args, format);
    if (!GetConsoleCP())
    {
        buffer = (char*)calloc(PRINTF_BUFFER_SIZE, sizeof(char));
        vsnprintf(buffer, sizeof(buffer), format, args);
        OutputDebugStringA(buffer);
        free(buffer);
    }
    else
    {
        vfprintf(stdout, format, args);
    }
    va_end (args);
}

void sqErrorPrintf(const char *format, ...)
{
    va_list args;
    char *buffer;
  
    va_start (args, format);
    if (!GetConsoleCP())
    {
        buffer = (char*)calloc(PRINTF_BUFFER_SIZE, sizeof(char));
        vsnprintf(buffer, sizeof(buffer), format, args);
        OutputDebugStringA(buffer);
        free(buffer);
    }
    else
    {
        vfprintf(stderr, format, args);
    }
    va_end (args);
}

extern int sqAskSecurityYesNoQuestion(const char *question)
{
    if (!GetConsoleCP())
    {
        /* TODO: Support UTF-8. */
        return MessageBoxA(NULL, question, "Squeak Security Alert", MB_YESNO | MB_ICONSTOP) == IDYES;
    }
    else
    {
        return 0;
    }
}

#ifndef printLastError
void printLastError(const TCHAR *prefix)
{ LPVOID lpMsgBuf;
  DWORD lastError;

  lastError = GetLastError();
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |  FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                (LPTSTR) &lpMsgBuf, 0, NULL );
  wprintf(TEXT("%s (%ld) -- %s\n"), prefix, lastError, (unsigned short*)lpMsgBuf);
  LocalFree( lpMsgBuf );
}
#endif
#ifndef vprintLastError
void vprintLastError(TCHAR *fmt, ...)
{ LPVOID lpMsgBuf;
  DWORD lastError;
  TCHAR *buf;
  va_list args;

  buf = (TCHAR*) calloc(4096, sizeof(TCHAR));
  va_start(args, fmt);
  wvsprintf(buf, fmt, args);
  va_end(args);

  lastError = GetLastError();
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |  FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                (LPTSTR) &lpMsgBuf, 0, NULL );
  wprintf(TEXT("%s (%ld: %s)\n"), buf, lastError, (unsigned short*)lpMsgBuf);
  LocalFree( lpMsgBuf );
  free(buf);
}
#endif

#ifndef sqMessageBox
int sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const char* fmt, ...)
{
    TCHAR *ptr, *buf;
    va_list args;
    DWORD result;

    ptr = sqUTF8toUTF16New(fmt);
    buf = (TCHAR*)calloc(sizeof(TCHAR), 4096);
    va_start(args, fmt);
    wvsprintf(buf, ptr, args);
    va_end(args);

    result = MessageBox(NULL, buf, titleString, dwFlags | MB_SETFOREGROUND);
    free(ptr);
    free(buf);
    return result;
}
#endif

#ifndef abortMessage
int abortMessage(const TCHAR* fmt, ...)
{
    TCHAR *buf;
    va_list args;

    buf = (TCHAR*)calloc(sizeof(TCHAR), 4096);
    va_start(args, fmt);
    wvsprintf(buf, fmt, args);
    va_end(args);

    MessageBox(NULL, buf, TEXT(VM_NAME) TEXT("!"), MB_OK | MB_TASKMODAL | MB_SETFOREGROUND);
    free(buf);
    exit(-1);
}
#endif

#else
void sqMessagePrintf(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);
}

void sqWarnPrintf(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);
}

void sqErrorPrintf(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
}

extern int sqAskSecurityYesNoQuestion(const char *question)
{
    return 0;
}

#endif
