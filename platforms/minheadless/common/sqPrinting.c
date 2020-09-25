/* sqPrinting.c -- printing and logging functions
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Minimalistic Headless Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Author: roniesalg@gmail.com
 */
#include <stdio.h>
#include <stdarg.h>
#include "sq.h"
#include "sqConfig.h"

#ifdef error
#undef error

void
error(const char *errorMessage)
{
    sqError(errorMessage);
}
#endif

void
sqError(const char *errorMessage)
{
    fprintf(stderr, "%s\n", errorMessage);
    abort();
}


#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define PRINTF_BUFFER_SIZE 4096

void
sqMessagePrintf(const char *format, ...)
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

void
sqWarnPrintf(const char *format, ...)
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

void
sqErrorPrintf(const char *format, ...)
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

void
sqFatalErrorPrintf(const char *format, ...)
{
    va_list args;
    char *buffer;

    va_start (args, format);
    if (!GetConsoleCP())
    {
        /*TODO: Display a message box in this case.*/
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
    abort();
}

void
sqFatalErrorPrintfNoExit(const char *format, ...)
{
    va_list args;
    char *buffer;

    va_start (args, format);
    if (!GetConsoleCP())
    {
        /*TODO: Display a message box in this case.*/
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

int
sqAskSecurityYesNoQuestion(const char *question)
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
void
printLastError(const TCHAR *prefix)
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
void
vprintLastError(TCHAR *fmt, ...)
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
int
sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const char* fmt, ...)
{
    TCHAR *ptr, *buf;
    va_list args;
    DWORD result;

    ptr = sqUTF8ToUTF16New(fmt);
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
int
abortMessage(const TCHAR* fmt, ...)
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
void
sqMessagePrintf(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);
}

void
sqWarnPrintf(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);
}

void
sqErrorPrintf(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
}

void
sqFatalErrorPrintf(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    abort();
}

void
sqFatalErrorPrintfNoExit(const char *format, ...)
{
    va_list args;

    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
}

int
sqAskSecurityYesNoQuestion(const char *question)
{
    return 0;
}

#endif
