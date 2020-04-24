#include <stdlib.h>
#include <time.h>
#include "sq.h"
#include "sqMemoryAccess.h"
#include "config.h"

void
ioInitPlatformSpecific(void)
{
}

void
ioInitTime(void)
{
}

void
ioInitThreads(void)
{
}

void
aioInit(void)
{
}

sqInt
amInVMThread(void)
{
    return false;
}

int
isCFramePointerInUse(usqIntptr_t *cFrmPtrPtr, usqIntptr_t *cStkPtrPtr)
{
    return true;
}

int
osCogStackPageHeadroom(void)
{
    return 1024;
}

long
ioMSecs(void)
{
    return 0;
}

long
ioMicroMSecs(void)
{
    return 0;
}

unsigned long long
ioUTCMicrosecondsNow()
{
    return 0;
}

unsigned long long
ioUTCMicroseconds()
{
    return 0;
}

unsigned long long
ioLocalMicrosecondsNow()
{
    return 0;
}

unsigned long long
ioLocalMicroseconds()
{
    return 0;
}

unsigned long long
ioUTCStartMicroseconds()
{
    return 0;
}

sqInt
ioLocalSecondsOffset()
{
    return 0;
}

void
ioUpdateVMTimezone()
{
}

# if ITIMER_HEARTBEAT		/* Hack; allow heartbeat to avoid */
int numAsyncTickees; /* prodHighPriorityThread unless necessary */
# endif						/* see platforms/unix/vm/sqUnixHeartbeat.c */

void
ioGetClockLogSizeUsecsIdxMsecsIdx(sqInt *runInNOutp, void **usecsp, sqInt *uip, void **msecsp, sqInt *mip)
{
}

/* this function should return the value of the high performance
   counter if there is such a thing on this platform (otherwise return 0) */
sqLong
ioHighResClock(void)
{
    return 0;
}

/* New filename converting function; used by the interpreterProxy function
  ioFilenamefromStringofLengthresolveAliases. Most platforms can ignore the
  resolveAlias boolean - it seems to only be of use by OSX but is crucial there.
*/
sqInt
sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean)
{
    memcpy(aCharBuffer, aFilenameString, filenameLength);
    aCharBuffer[filenameLength] = 0;
    return 0;
}

sqInt
ioBeep(void)
{
    return 0;
}

sqInt
ioExit(void)
{
    exit(0);
}

sqInt
ioExitWithErrorCode(int errorCode)
{
    exit(errorCode);
}

sqInt
crashInThisOrAnotherThread(sqInt flags)
{
    abort();
}

sqInt
ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
    return 0;
}

sqInt
ioSeconds(void)
{
    return 0;
}

sqInt
ioSecondsNow(void)
{
    return time(NULL);
}

void
ioInitHeartbeat(void)
{
}

int
ioHeartbeatMilliseconds(void)
{
    return 0;
}

void
ioSetHeartbeatMilliseconds(int milliseconds)
{
}

unsigned long
ioHeartbeatFrequency(int frequency)
{
    return 0;
}

void
ioProfileStatus(sqInt *running, void **exestartpc, void **exelimitpc,
					  void **vmhst, long *nvmhbin, void **eahst, long *neahbin)
{
}

void
ioControlProfile(int on, void **vhp, long *nvb, void **ehp, long *neb)
{
}

long
ioControlNewProfile(int on, unsigned long buffer_size)
{
    return 0;
}

void
ioNewProfileStatus(sqInt *running, long *buffersize)
{
}

long
ioNewProfileSamplesInto(void *sampleBuffer)
{
    return 0;
}

void
ioClearProfile(void)
{
}

sqInt
ioDisablePowerManager(sqInt disableIfNonZero)
{
    return true;
}

static int
isAbsolutePath(const char *path)
{
#ifdef _WIN32
    return *path == '\\' || (path[0] != 0 && path[1] == ':');
#else
    /* Assume UNIX style path. */
    return *path == '/';
#endif
}

void
findExecutablePath(const char *localVmName, char *dest, size_t destSize)
{
    const char *lastSeparator = strrchr(localVmName, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(localVmName, '\\');
    if(!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif

    if(!isAbsolutePath(localVmName))
    {
        /* TODO: Get the current working directory*/
        strcpy(dest, "./");
    }

    if(lastSeparator)
        strncat(dest, localVmName, lastSeparator - localVmName + 1);
}

int
sqExecuteFunctionWithCrashExceptionCatching(sqFunctionThatCouldCrash function, void *userdata)
{
    return function(userdata);
}

void *os_exports[][3]=
{
    { 0, 0, 0 }
};
