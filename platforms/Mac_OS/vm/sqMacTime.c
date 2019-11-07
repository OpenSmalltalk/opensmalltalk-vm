/****************************************************************************
*   PROJECT: Mac time and millisecond clock logic 
*   FILE:    sqMacTime.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacTime.c 1468 2006-04-19 02:39:08Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Feb 27th, 2002, JMM a bit of cleanup for carbon event usage
*  Apr 17th, 2002, JMM Use accessors for VM variables.
*  Apr 25th, 2002, JMM low res clock is broken after 0x7FFFFFF
*  3.9.1b2 Oct 4th, 2005 Jmm add MillisecondClockMask
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support

*****************************************************************************/
#include "sq.h"
#include "sqMacTime.h"
#include "sqMacUIEvents.h"

#include <pthread.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include "sqaio.h"

static struct timeval	 startUpTime;
/*
 * In the Cog VMs time management is in platforms/unix/vm/sqUnixHeartbeat.c.
 */
#if STACKVM
void SetUpTimers(void)
{
extern void ioInitTime(void);

  /* set up the backwardcompatibility micro/millisecond clock */
    gettimeofday(&startUpTime, 0);
  /* setup the spiffy new 64-bit microsecond clock. */
	ioInitTime();
}
#else /* STACKVM */
static TMTask    gTMTask;

#define LOW_RES_TICK_MSECS 16
#define HIGH_RES_TICK_MSECS 2
#define COUNTER_LIMIT LOW_RES_TICK_MSECS/HIGH_RES_TICK_MSECS

static pascal void
MyTimerProc(QElemPtr time)
{
    PrimeTime((QElemPtr)time, LOW_RES_TICK_MSECS);
    return;
}

void
SetUpTimers(void)
{
  /* set up the micro/millisecond clock */
    gettimeofday(&startUpTime, 0);
    
    gTMTask.tmAddr = NewTimerUPP((TimerProcPtr) MyTimerProc);
    gTMTask.tmCount = 0;
    gTMTask.tmWakeUp = 0;
    gTMTask.tmReserved = 0;    
     
    InsXTime((QElemPtr)(&gTMTask.qLink));
    PrimeTime((QElemPtr)&gTMTask.qLink,LOW_RES_TICK_MSECS);
}

int
ioMicroMSecs(void)
{
  struct timeval now;
  gettimeofday(&now, 0);
  if ((now.tv_usec-= startUpTime.tv_usec) < 0) {
    now.tv_usec+= 1000000;
    now.tv_sec-= 1;
  }
  now.tv_sec-= startUpTime.tv_sec;
  return (now.tv_usec / 1000 + now.tv_sec * 1000);
}

int
ioSeconds(void) {
    time_t unixTime;

    unixTime = time(0);
    unixTime += localtime(&unixTime)->tm_gmtoff;
    /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
        and 52 non-leap years later than Squeak. */
    return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
}

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds) {
	/* This operation is platform dependent. 	 */

    usqLong	   realTimeToWait,now;
	extern usqLong getNextWakeupUsecs();

    now = (ioMSecs() & MillisecondClockMask);
    if (getNextWakeupUsecs() <= now) {
        if (getNextWakeupUsecs() == 0)
            realTimeToWait = microSeconds;
        else
            return 0;
    }
    else {
        realTimeToWait = getNextWakeupUsecs() - now; 
		if ( realTimeToWait > microSeconds )
			realTimeToWait = microSeconds;
	}

	aioSleepForUsecs((long)realTimeToWait);

	return 0;
}


#undef ioMSecs
//Issue with unix aio.c sept 2003

long ioMSecs() { return ioMicroMSecs(); }

#define SecondsFrom1901To1970      2177452800ULL
#define MicrosecondsFrom1901To1970 2177452800000000ULL

#define MicrosecondsPerSecond 1000000ULL
#define MillisecondsPerSecond 1000ULL

#define MicrosecondsPerMillisecond 1000ULL
/* Compute the current VM time basis, the number of microseconds from 1901. */

static unsigned long long
currentUTCMicroseconds()
{
	struct timeval utcNow;

	gettimeofday(&utcNow,0);
	return ((utcNow.tv_sec * MicrosecondsPerSecond) + utcNow.tv_usec)
			+ MicrosecondsFrom1901To1970;
}

unsigned long long
ioUTCMicroseconds() { return currentUTCMicroseconds(); }

/* This is an expensive interface for use by profiling code that wants the time
 * now rather than as of the last heartbeat.
 */
unsigned long long
ioUTCMicrosecondsNow() { return currentUTCMicroseconds(); }
#endif /* STACKVM */


/*
 * Convert the supplied Unix (UTC) time to Squeak time.
 *
 * WARNING: On 32 bit platforms time_t is only 32 bits long.
 * Since Squeak has an Epoch of 1901 while Unix uses 1970 the
 * result is that overflow always occurs for times beyond about 1967.
 * The expected result ends up in the image because the value is treated
 * as an unsigned integer when converting to an oop.
 * convertToSqueakTime should be deprecated in favour of
 * convertToLongSqueakTime.
 *
 */
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


/*
 * Convert the supplied Unix (UTC) time to Squeak time.
 *
 * Squeak time has an epoch of 1901 and uses local time
 * i.e. timezone + daylight savings
 *
 * Answer an sqLong which is guaranteed to be 64 bits on all platforms.
 */
sqLong convertToLongSqueakTime(time_t unixTime)
{
sqLong result;

  result = unixTime;
#ifdef HAVE_TM_GMTOFF
  result += localtime(&unixTime)->tm_gmtoff;
#else
# ifdef HAVE_TIMEZONE
  result += ((daylight) * 60*60) - timezone;
# else
#  error: cannot determine timezone correction
# endif
#endif
  /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
     and 52 non-leap years later than Squeak. */
  result += ((52*365UL + 17*366UL) * 24*60*60UL);
  return result;
}

