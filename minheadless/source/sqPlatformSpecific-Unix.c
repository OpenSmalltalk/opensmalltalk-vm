#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/param.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>

#include "sq.h"
#include "sqMemoryAccess.h"
#include "config.h"
#include "debug.h"

#include "sqUnixMemory.c"
#include "sqUnixSpurMemory.c"
#include "sqPlatformSpecific-NullWindow.c"

#if !defined(min)
# define min(x,y) (((x)>(y))?(y):(x))
#endif

time_t convertToSqueakTime(time_t unixTime)
{
#ifdef HAVE_TM_GMTOFF
  unixTime+= localtime(&unixTime)->tm_gmtoff;
#else
# ifdef HAVE_TIMEZONE
  unixTime+= ((daylight) * 60*60) - timezone;
# else
#  error: cannot determine timezone correction
# endif
#endif
  /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
     and 52 non-leap years later than Squeak. */
  return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
}

#if COGVM
/*
 * Support code for Cog.
 * a) Answer whether the C frame pointer is in use, for capture of the C stack
 *    pointers.
 * b) answer the amount of stack room to ensure in a Cog stack page, including
 *    the size of the redzone, if any.
 */

/*
 * Cog has already captured CStackPointer  before calling this routine.  Record
 * the original value, capture the pointers again and determine if CFramePointer
 * lies between the two stack pointers and hence is likely in use.  This is
 * necessary since optimizing C compilers for x86 may use %ebp as a general-
 * purpose register, in which case it must not be captured.
 */
int
isCFramePointerInUse()
{
	extern unsigned long CStackPointer, CFramePointer;
	extern void (*ceCaptureCStackPointers)(void);
	unsigned long currentCSP = CStackPointer;

	currentCSP = CStackPointer;
	ceCaptureCStackPointers();
	assert(CStackPointer < currentCSP);
	return CFramePointer >= CStackPointer && CFramePointer <= currentCSP;
}

/* Answer an approximation of the size of the redzone (if any).  Do so by
 * sending a signal to the process and computing the difference between the
 * stack pointer in the signal handler and that in the caller. Assumes stacks
 * descend.
 */

static char * volatile p = 0;

static void
sighandler(int sig, siginfo_t *info, void *uap) { p = (char *)&sig; }

static int
getRedzoneSize()
{
	struct sigaction handler_action, old;
	handler_action.sa_sigaction = sighandler;
	handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
	sigemptyset(&handler_action.sa_mask);
	(void)sigaction(SIGPROF, &handler_action, &old);

	do kill(getpid(),SIGPROF); while (!p);
	(void)sigaction(SIGPROF, &old, 0);
	return (char *)min(&old,&handler_action) - sizeof(struct sigaction) - p;
}

sqInt reportStackHeadroom;
static int stackPageHeadroom;

/* Answer the redzone size plus space for any signal handlers to run in.
 * N.B. Space for signal handers may include space for the dynamic linker to
 * run in since signal handlers may reference other functions, and linking may
 * be lazy.  The reportheadroom switch can be used to check empirically that
 * there is sufficient headroom.
 */
int
osCogStackPageHeadroom()
{
	if (!stackPageHeadroom)
		stackPageHeadroom = getRedzoneSize() + 1024;
	return stackPageHeadroom;
}
#endif /* COGVM */

sqInt amInVMThread(void)
{
    return false;
}

/* Time */
void ioInitTime(void)
{
}

long ioMSecs(void)
{
    return 0;
}

long ioMicroMSecs(void)
{
    return 0;
}

unsigned volatile long long  ioUTCMicrosecondsNow()
{
    return 0;
}

unsigned volatile long long  ioUTCMicroseconds()
{
    return 0;
}

unsigned volatile long long  ioLocalMicrosecondsNow()
{
    return 0;
}

unsigned volatile long long  ioLocalMicroseconds()
{
    return 0;
}

unsigned          long long  ioUTCStartMicroseconds()
{
    return 0;
}

sqInt	ioLocalSecondsOffset()
{
    return 0;
}

void	ioUpdateVMTimezone()
{
}

# if ITIMER_HEARTBEAT		/* Hack; allow heartbeat to avoid */
int numAsyncTickees; /* prodHighPriorityThread unless necessary */
# endif						/* see platforms/unix/vm/sqUnixHeartbeat.c */

void	ioGetClockLogSizeUsecsIdxMsecsIdx(sqInt *runInNOutp, void **usecsp, sqInt *uip, void **msecsp, sqInt *mip)
{
}

/* this function should return the value of the high performance
   counter if there is such a thing on this platform (otherwise return 0) */
sqLong ioHighResClock(void)
{
    return 0;
}

/* New filename converting function; used by the interpreterProxy function
  ioFilenamefromStringofLengthresolveAliases. Most platforms can ignore the
  resolveAlias boolean - it seems to only be of use by OSX but is crucial there.
*/
sqInt sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean)
{
    return 0;
}

sqInt ioBeep(void)
{
    return 0;
}

sqInt ioExit(void)
{
    exit(0);
}

sqInt ioExitWithErrorCode(int errorCode)
{
    exit(errorCode);
}

sqInt crashInThisOrAnotherThread(sqInt flags)
{
    abort();
}

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
    return 0;
}

double ioScreenScaleFactor(void)
{
    return 4.0/3.0;
}

sqInt ioScreenSize(void)
{
    return 0;
}

sqInt ioScreenDepth(void)
{
    return 0;
}

sqInt ioSeconds(void)
{
    return 0;
}

sqInt ioSecondsNow(void)
{
    return time(NULL);
}

void  ioInitHeartbeat(void)
{
}

int   ioHeartbeatMilliseconds(void)
{
    return 0;
}

void  ioSetHeartbeatMilliseconds(int milliseconds)
{
}

unsigned long ioHeartbeatFrequency(int frequency)
{
    return 0;
}

void  ioProfileStatus(sqInt *running, void **exestartpc, void **exelimitpc,
					  void **vmhst, long *nvmhbin, void **eahst, long *neahbin)
{
}

void  ioControlProfile(int on, void **vhp, long *nvb, void **ehp, long *neb)
{
}

long  ioControlNewProfile(int on, unsigned long buffer_size)
{
    return 0;
}

void  ioNewProfileStatus(sqInt *running, long *buffersize)
{
}

long  ioNewProfileSamplesInto(void *sampleBuffer)
{
    return 0;
}

void  ioClearProfile(void)
{
}

sqInt ioDisablePowerManager(sqInt disableIfNonZero)
{
    return true;
}

/* Clipboard */
sqInt clipboardSize(void)
{
    return 0;
}

sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return 0;
}

sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return 0;
}

/* Threads*/
void ioInitThreads(void)
{
}

/* Asychronous IO */
void aioInit(void)
{
}

/* OS Exports */
void *os_exports[][3]=
{
    { 0, 0, 0 }
};
