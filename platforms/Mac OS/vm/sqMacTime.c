/****************************************************************************
*   PROJECT: Mac time and millisecond clock logic 
*   FILE:    sqMacTime.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacTime.c,v 1.1 2002/02/23 10:47:46 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*****************************************************************************/
#include "sqMacTime.h"
#include "sq.h"

#if defined ( __APPLE__ ) && defined ( __MACH__ )

    #include <sys/types.h>
    #include <sys/time.h>
    #include <unistd.h>
    TMTask    gTMTask;
    struct timeval	 startUpTime;
    unsigned int	lowResMSecs= 0;
    #define LOW_RES_TICK_MSECS 16

extern Boolean  gThreadManager;

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
     
    InsXTime((QElemPtr)&gTMTask);
    PrimeTime((QElemPtr)&gTMTask,LOW_RES_TICK_MSECS);
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

#else
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
#endif

int ioSeconds(void) {
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
}


int ioRelinquishProcessorForMicroseconds(int microSeconds) {
	/* This operation is platform dependent. 	 */
    microSeconds;
    
#if defined ( __APPLE__ ) && defined ( __MACH__ )
    usleep(microSeconds);
     /* This is unix code, but seems to be problem under osx
      {
      struct timeval tv;
      tv.tv_sec=  microSeconds / 1000000;
      tv.tv_usec= microSeconds % 1000000;
      select(0, 0, 0, 0, &tv); 
      }*/
#endif	

	if (gThreadManager)
		YieldToAnyThread();
	else
	    ioProcessEvents();
}
