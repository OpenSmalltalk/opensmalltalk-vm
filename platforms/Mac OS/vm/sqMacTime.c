/****************************************************************************
*   PROJECT: Mac time and millisecond clock logic 
*   FILE:    sqMacTime.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacTime.c,v 1.16 2004/08/03 02:41:48 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Feb 27th, 2002, JMM a bit of cleanup for carbon event usage
*  Apr 17th, 2002, JMM Use accessors for VM variables.
*  Apr 25th, 2002, JMM low res clock is broken after 0x7FFFFFF

*****************************************************************************/
#include "sq.h"
#include "sqMacTime.h"
#include "sqMacUIEvents.h"


extern Boolean  gThreadManager;
extern int getNextWakeupTick();
extern int setInterruptCheckCounter(int value);
extern int setInterruptPending(int value);

#if defined ( __APPLE__ ) && defined ( __MACH__ )

    #include <pthread.h>
    #include <sys/types.h>
    #include <sys/time.h>
    #include <unistd.h>
    #include "aio.h"

    TMTask    gTMTask,gTMTask1000;
    struct timeval	 startUpTime;
    unsigned int	lowResMSecs= 0;
    int	    gCounter=0;
    #define LOW_RES_TICK_MSECS 16
    #define HIGH_RES_TICK_MSECS 2
    #define COUNTER_LIMIT LOW_RES_TICK_MSECS/HIGH_RES_TICK_MSECS



static pascal void MyTimerProc(QElemPtr time)
{
    lowResMSecs = ioMicroMSecs();
    PrimeTime((QElemPtr)time, LOW_RES_TICK_MSECS);
    return;
}

/*static pascal void MyTimerProc1000(QElemPtr time)
{
    if (getNextWakeupTick() != 0)
    	interruptCheckCounter = 0;
    gCounter++;
    if(gCounter > COUNTER_LIMIT) {
        lowResMSecs = ioMicroMSecs();
        gCounter = 0;
    }
    PrimeTime((QElemPtr)time, HIGH_RES_TICK_MSECS);
    return;
}*/

void SetUpTimers(void)
{
  /* set up the micro/millisecond clock */
    gettimeofday(&startUpTime, 0);
    
    gTMTask.tmAddr = NewTimerUPP((TimerProcPtr) MyTimerProc);
    gTMTask.tmCount = 0;
    gTMTask.tmWakeUp = 0;
    gTMTask.tmReserved = 0;    
     
    InsXTime((QElemPtr)(&gTMTask));
    PrimeTime((QElemPtr)&gTMTask,LOW_RES_TICK_MSECS);

    /*gTMTask1000.tmAddr = NewTimerUPP((TimerProcPtr) MyTimerProc1000);
    gTMTask1000.tmCount = 0;
    gTMTask1000.tmWakeUp = 0;
    gTMTask1000.tmReserved = 0;    
     
    InsXTime((QElemPtr)&gTMTask1000);
    PrimeTime((QElemPtr)&gTMTask1000,HIGH_RES_TICK_MSECS);*/
}

int ioLowResMSecs(void)
{
  return lowResMSecs;
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

/*TMTask    gWakeUpTimerProc;
static Boolean gWakeUpTimerProcNeedsInit=true;

static pascal void MyWakeUTimerProc(QElemPtr time) {
    interruptCheckCounter = 0;
    return;
}

int ioMakeAnExernalTimerCall(int ticksInFuture) {
    int ticks;
    
    if (gWakeUpTimerProcNeedsInit) {
        gWakeUpTimerProcNeedsInit = false;
        gWakeUpTimerProc.tmAddr = NewTimerUPP((TimerProcPtr) MyWakeUTimerProc);
        gWakeUpTimerProc.tmCount = 0;
        gWakeUpTimerProc.tmWakeUp = 0;
        gWakeUpTimerProc.tmReserved = 0;    
     
        InsXTime((QElemPtr)&gWakeUpTimerProc);
    }
    
    ticks = ticksInFuture-(ioMSecs()& 536870911);
    if (ticks < 0)
        return;
    PrimeTime((QElemPtr)&gWakeUpTimerProc,ticks);
}*/

#else
#if !TARGET_API_MAC_CARBON
    #include <OpenTransport.h>
#endif

OTTimeStamp     timeStart;
int ioMicroMSecsExpensive(void);

int ioMicroMSecsExpensive(void) {
	UnsignedWide microTicks;
	Microseconds(&microTicks);
	return (microTicks.lo / 1000) + (microTicks.hi * 4294967);
}

void SetUpTimers(void)
{
#if !defined(MINIMALVM)
	if((Ptr)OTGetTimeStamp!=(Ptr)kUnresolvedCFragSymbolAddress)
 	    OTGetTimeStamp(&timeStart);
#endif 
}

#if !defined(MINIMALVM)
int ioMicroMSecs(void) {
	/* Note: This function and ioMSecs() both return a time in milliseconds. The difference
	   is that ioMicroMSecs() is called only when precise millisecond resolution is essential,
	   and thus it can use a more expensive timer than ioMSecs, which is called frequently.
	   However, later VM optimizations reduced the frequency of calls to ioMSecs to the point
	   where clock performance became less critical, and we also started to want millisecond-
	   resolution timers for real time applications such as music. */
	
	register long check;
	
	if((Ptr)OTElapsedMilliseconds!=(Ptr)kUnresolvedCFragSymbolAddress){
    	check = OTElapsedMilliseconds(&timeStart);
    	if (check != -1) 
    	    return check;
    	OTGetTimeStamp(&timeStart);
	    return ioMicroMSecs();
	}else {
	    return ioMicroMSecsExpensive();
	}
}
#else
int ioMicroMSecs(void) {
    return ioMicroMSecsExpensive();
}
#endif

int ioLowResMSecs(void)
{
  double convert;
  long long temp;
  int final;
  
  convert = (unsigned int) TickCount();
  temp = convert*1000.0/60.0;
  temp = temp & 0x7FFFFFFF;
  final = temp;
  return final;
}

#endif

int ioSeconds(void) {
#if defined ( __APPLE__ ) && defined ( __MACH__ )
    time_t unixTime;
    
    unixTime = time(0);
    unixTime += localtime(&unixTime)->tm_gmtoff;
    /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
        and 52 non-leap years later than Squeak. */
    return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);

#else
	struct tm timeRec;
	time_t time1904, timeNow;

	/* start of ANSI epoch is midnight of Jan 1, 1904 */
	timeRec.tm_sec   = 0;
	timeRec.tm_min   = 0;
	timeRec.tm_hour  = 0;
	timeRec.tm_mday  = 1;
	timeRec.tm_mon   = 0;
	timeRec.tm_year  = 4;
	timeRec.tm_wday  = 0;
	timeRec.tm_yday  = 0;
	timeRec.tm_isdst = 0;
	time1904 = mktime(&timeRec);

	timeNow = time(NULL);

	/* Squeak epoch is Jan 1, 1901, 3 non-leap years earlier than ANSI one */
	return (timeNow - time1904) + (3 * 365 * 24 * 60 * 60);
#endif
}


#if defined ( __APPLE__ ) && defined ( __MACH__ )
pthread_mutex_t gSleepLock;
pthread_cond_t  gSleepLockCondition;
#endif

int ioRelinquishProcessorForMicroseconds(int microSeconds) {
	/* This operation is platform dependent. 	 */
    
#if defined ( __APPLE__ ) && defined ( __MACH__ )
    static Boolean doInitialization=true;
    int	   realTimeToWait,now;
    
    if (doInitialization) {
        doInitialization = false;
        pthread_mutex_init(&gSleepLock, NULL);
        pthread_cond_init(&gSleepLockCondition,NULL);
    }
    
    setInterruptCheckCounter(0);
    now = (ioMSecs() & 536870911);
    if (getNextWakeupTick() <= now)
        if (getNextWakeupTick() == 0)
            realTimeToWait = 16;
        else {
            return 0;
    }
    else
        realTimeToWait = getNextWakeupTick() - now; 
            
    aioPoll(realTimeToWait*1000);
    
    /* tspec.tv_sec=  realTimeToWait / 1000;
    tspec.tv_nsec= (realTimeToWait % 1000)*1000000;
    
    err = pthread_mutex_lock(&gSleepLock);
    err = pthread_cond_timedwait_relative_np(&gSleepLockCondition,&gSleepLock,&tspec);	
    err = pthread_mutex_unlock(&gSleepLock); */
    

#else
#if !I_AM_CARBON_EVENT
    microSeconds;
	if (gThreadManager)
            SqueakYieldToAnyThread();
	else
	    ioProcessEvents();
    if ((getNextWakeupTick() <= (ioMSecs() & 536870911)) && (getNextWakeupTick() != 0)) {
        setInterruptCheckCounter(0);
        return 0;
    }
#endif
#endif	
	return 0;
}
#undef ioMSecs
//Issue with unix aio.c sept 2003

int ioMSecs() {
    return ioMicroMSecs();
}

/*void sqHeartBeatActions(int now) {
    static int past=0;
    
    if ((now-past) > 10) {
        aioPoll(0);
    }
    past = now;
} */