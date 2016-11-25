#include "sq.h"

BOOL fIsConsole = 0;
BOOL fLowRights = 0;

#define MAX_BUFFER MAX_PATH
static TCHAR w_buffer1[MAX_BUFFER]; /* wide buffer 1 */
static TCHAR w_buffer2[MAX_BUFFER]; /* wide buffer 2 */
static char  a_buffer1[MAX_BUFFER]; /* ansi buffer 1 */
TCHAR squeakIniName[MAX_PATH + 1];;

static TCHAR *fromSqueakInto(const char *sqPtr, int sqSize, TCHAR* buffer)
{
    sqUTF8ToUTF16Copy(buffer, sqSize, sqPtr);
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

/* NOTE: Why do we need this? When running multi-threaded code such as in
the networking code and in midi primitives
we will signal the interpreter several semaphores.
(Predates the internal synchronization of signalSemaphoreWithIndex ()) */

int synchronizedSignalSemaphoreWithIndex(int semaIndex)
{
    int result;

    /* Do our job - this is now synchronized in signalSemaphoreWithIndex */
    result = signalSemaphoreWithIndex(semaIndex);
    /* wake up interpret() if sleeping */
    /* SetEvent(vmWakeUpEvent); */
    return result;
}
