/****************************************************************************
*   sqWin32Time.c
*   Time functions for non-heartbeat (non STACK) VMs, extracted from
*	trunk sqWin32Window.c
*****************************************************************************/

#include <Windows.h>

#include "sq.h"

#if !STACKVM
/*
 * Win32 FILETIMEs are 10th's of microseconds since 1601.  Smalltalk times
 * are seconds from 1901.  Let's call a 10th of a microsecond a "tock".
 */

#if _MSC_VER
# define SecondsFrom1601To1901 9467020800i64 /*See PRINT_TIME_CONSTANTS below*/
# define MicrosecondsFrom1601To1901 9467020800000000i64

# define MicrosecondsPerSecond 1000000i64
# define MillisecondsPerSecond 1000i64

# define MicrosecondsPerMillisecond 1000000i64

# define TocksPerSecond      10000000i64
# define TocksPerMillisecond 10000i64
# define TocksPerMicrosecond 10i64
# define LLFMT "I64d"
#else
# define SecondsFrom1601To1901 9467020800LL /*See PRINT_TIME_CONSTANTS below*/
# define MicrosecondsFrom1601To1901 9467020800000000LL

# define MicrosecondsPerSecond 1000000LL
# define MillisecondsPerSecond 1000LL

# define MicrosecondsPerMillisecond 1000LL

# define TocksPerSecond      10000000LL
# define TocksPerMillisecond 10000LL
# define TocksPerMicrosecond 10LL
# define LLFMT "lld"
#endif

/* returns the local wall clock time */
int ioSeconds(void)
{ SYSTEMTIME sysTime;
  GetLocalTime(&sysTime);
  return convertToSqueakTime(sysTime);
}

int ioMSecs()
{
  /* Make sure the value fits into Squeak SmallIntegers */
  return timeGetTime() & MillisecondClockMask;
}

/* Note: ioMicroMSecs returns *milli*seconds */
int ioMicroMSecs(void)
{
  /* Make sure the value fits into Squeak SmallIntegers */
  return timeGetTime() & MillisecondClockMask;
}

/* Compute the current VM time basis, the number of microseconds from 1901.
 *
 * Alas Windows' system time functions GetSystemTime et al have low resolution;
 * 15 ms.  So we use timeGetTime for higher resolution and use it as an offset to
 * the system time, resetting when timeGetTime wraps.  Since timeGetTime wraps we
 * need some basis information which is passed in as pointers to provide us with
 * both the heartbeat clock and an instantaneous clock for the VM thread.
 * This is still insufficient since timeGetTime driefts relative to wall time.
 * We should apply some periodic adjustment but for now just drift aimlessly.
 */

/* The bases that relate timeGetTime's 32-bit wrapping millisecond clock to the
 * non-wrapping 64-bit microsecond clocks.
 */
static unsigned __int64 utcTickBaseMicroseconds;
static DWORD lastTick = (DWORD)-1;
static DWORD baseTick;

static unsigned __int64
currentUTCMicroseconds(unsigned __int64 *utcTickBaseUsecsp, DWORD *lastTickp, DWORD *baseTickp)
{
	FILETIME utcNow;
	DWORD currentTick = timeGetTime();
	DWORD prevTick = *lastTickp;

	*lastTickp = currentTick;

	/* If the timeGetTime millisecond clock wraps (as it will every 49.71 days)
	 * resync to the system time.  
	 */
	if (currentTick < prevTick) {
		unsigned __int64 now;
		*baseTickp = currentTick;
		GetSystemTimeAsFileTime(&utcNow);
		now = ((unsigned __int64) utcNow.dwHighDateTime) << 32 | utcNow.dwLowDateTime;
		*utcTickBaseUsecsp = now
							/ TocksPerMicrosecond
							- MicrosecondsFrom1601To1901;
		return *utcTickBaseUsecsp;
	}
	return *utcTickBaseUsecsp
		  + (currentTick - *baseTickp) * MicrosecondsPerMillisecond;
}

unsigned long long
ioUTCMicroseconds() { return currentUTCMicroseconds(&utcTickBaseMicroseconds, &lastTick, &baseTick); }

/* This is an expensive interface for use by profiling code that wants the time
 * now rather than as of the last heartbeat.
 */
unsigned long long
ioUTCMicrosecondsNow() { return currentUTCMicroseconds(&utcTickBaseMicroseconds, &lastTick, &baseTick); }

static DWORD dwTimerPeriod;

void
ioInitTime()
{
	TIMECAPS tCaps;

	dwTimerPeriod = 0;
	if(timeGetDevCaps(&tCaps,sizeof(tCaps)) != 0)
		return;
	dwTimerPeriod = tCaps.wPeriodMin;
	if (timeBeginPeriod(dwTimerPeriod) != 0)
		return;
}

void
ioReleaseTime(void)
{
	if (dwTimerPeriod)
		timeEndPeriod(dwTimerPeriod);
}
#endif /* STACKVM */
