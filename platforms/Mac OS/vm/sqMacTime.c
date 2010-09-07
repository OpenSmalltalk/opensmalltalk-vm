/****************************************************************************
*   PROJECT: Mac time and millisecond clock logic 
*   FILE:    sqMacTime.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Feb 27th, 2002, JMM a bit of cleanup for carbon event usage
*  Apr 17th, 2002, JMM Use accessors for VM variables.
*  Apr 25th, 2002, JMM low res clock is broken after 0x7FFFFFF
*  3.9.1b2 Oct 4th, 2005 Jmm add MillisecondClockMask
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
*	3.8.14b1 Oct	,2006 JMM browser rewrite

*****************************************************************************/
#include "sq.h"
#include "sqMacTime.h"
#include "sqMacUIEvents.h"
#define MillisecondClockMask 536870911

#include <pthread.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include "sqaio.h"

static TMTask    gTMTask;
static struct timeval	 startUpTime;
static unsigned int	lowResMSecs= 0;


#define LOW_RES_TICK_MSECS 16
#define HIGH_RES_TICK_MSECS 2
#define COUNTER_LIMIT LOW_RES_TICK_MSECS/HIGH_RES_TICK_MSECS



static pascal void MyTimerProc(QElemPtr time)
{
    lowResMSecs = ioMicroMSecs();
    PrimeTime((QElemPtr)time, LOW_RES_TICK_MSECS);
    return;
}

void SetUpTimers(void)
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

int ioLowResMSecs(void)
{
  return lowResMSecs;
}

sqLong ioMicroSeconds(void)
{
	//API Documented
	struct timeval now;
	sqLong theTimeIs;
	
	gettimeofday(&now, 0);
	if ((now.tv_usec-= startUpTime.tv_usec) < 0) {
		now.tv_usec+= 1000000;
		now.tv_sec-= 1;
	}
	now.tv_sec-= startUpTime.tv_sec;
	theTimeIs = now.tv_usec;
	theTimeIs = theTimeIs + now.tv_sec * 1000000;
	return theTimeIs;
}

int ioMicroMSecs(void)
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

sqInt ioUtcWithOffset(sqLong *microSeconds, int *offset)
{
	struct timeval timeval;
	if (gettimeofday(&timeval, NULL) == -1) return -1;
	time_t seconds = timeval.tv_sec;
	suseconds_t usec = timeval.tv_usec;
	*microSeconds = seconds * 1000000 + usec;
	*offset = localtime(&seconds)->tm_gmtoff;
	return 0;
}


int ioSeconds(void) {
    time_t unixTime;
    
    unixTime = time(0);
    unixTime += localtime(&unixTime)->tm_gmtoff;
    /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
        and 52 non-leap years later than Squeak. */
    return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
}

pthread_mutex_t gSleepLock;
pthread_cond_t  gSleepLockCondition;

int ioRelinquishProcessorForMicroseconds(int microSeconds) {
	/* This operation is platform dependent. 	 */
	#pragma unused(microSeconds)

    static Boolean doInitialization=true;
    int	   realTimeToWait,now;
	extern int getNextWakeupTick();
	extern int setInterruptCheckCounter(int value);
    
    if (doInitialization) {
        doInitialization = false;
        pthread_mutex_init(&gSleepLock, NULL);
        pthread_cond_init(&gSleepLockCondition,NULL);
    }
    
    setInterruptCheckCounter(0);
    now = (ioMSecs() & MillisecondClockMask);
    if (getNextWakeupTick() <= now)
        if (getNextWakeupTick() == 0)
            realTimeToWait = 16;
        else {
            return 0;
    }
    else
        realTimeToWait = getNextWakeupTick() - now; 
            
	aioSleep(realTimeToWait*1000);
	    
		
 /* tspec.tv_sec=  realTimeToWait / 1000;
    tspec.tv_nsec= (realTimeToWait % 1000)*1000000;
    
    err = pthread_mutex_lock(&gSleepLock);
    err = pthread_cond_timedwait_relative_np(&gSleepLockCondition,&gSleepLock,&tspec);	
    err = pthread_mutex_unlock(&gSleepLock); */
    
	return 0;
}
#undef ioMSecs
//Issue with unix aio.c sept 2003

int ioMSecs() {
    return ioMicroMSecs();
}

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
