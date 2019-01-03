#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "sq.h"

BOOL fIsConsole = 0;
BOOL fLowRights = 0;

#define MAX_BUFFER MAX_PATH
static TCHAR w_buffer1[MAX_BUFFER]; /* wide buffer 1 */
static TCHAR w_buffer2[MAX_BUFFER]; /* wide buffer 2 */
static char  a_buffer1[MAX_BUFFER]; /* ansi buffer 1 */

/* Stub for SecurityPlugin */
WCHAR squeakIniNameW[MAX_PATH + 1];

static TCHAR *
fromSqueakInto(const char *sqPtr, int sqSize, TCHAR* buffer)
{
    sqUTF8ToUTF16Copy(buffer, sqSize, sqPtr);
    return buffer;
}

TCHAR *
fromSqueak(const char *sqPtr, int sqSize)
{
    return fromSqueakInto(sqPtr, sqSize, w_buffer1);
}

TCHAR *
fromSqueak2(const char *sqPtr, int sqSize)
{
    return fromSqueakInto(sqPtr, sqSize, w_buffer2);
}

void
sqWin32PrintLastError(const char *message)
{
    char buffer[256];
    DWORD errorCode;

    errorCode = GetLastError();
    FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, errorCode, MAKELANGID(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT), buffer, sizeof(buffer), 0);
    sqWarnPrintf("%s: %s\n", message, buffer);
}
