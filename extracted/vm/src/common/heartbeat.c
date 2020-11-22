/****************************************************************************
*   PROJECT: Unix (pthread) heartbeat logic for Stack/Cog VM
*   FILE:    sqUnixHeartbeat.c
*   CONTENT: 
*
*   AUTHOR:  Eliot Miranda
*   ADDRESS: 
*   EMAIL:   eliot.miranda@gmail.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb   1st, 2012, EEM refactored into three separate files.
*  July 31st, 2008, EEM added heart-beat thread.
*  Aug  20th, 2009, EEM added 64-bit microsecond clock support code
*
*****************************************************************************/


#include "sq.h"
#include "sqAssert.h"
#include "sqMemoryFence.h"
//#include "sqSCCSVersion.h"
#include <errno.h>

#if defined(_WIN32)
#include <windows.h>
#else
#include <pthread.h>
#include <sys/time.h>
#endif

#include <sys/types.h>

#include "sqaio.h"

#include "pharovm/debug.h"

#define SecondsFrom1901To1970      2177452800LL
#define MicrosecondsFrom1901To1970 2177452800000000LL

#define MicrosecondsPerSecond 1000000LL
#define MillisecondsPerSecond 1000LL

#define MicrosecondsPerMillisecond 1000LL

static unsigned volatile long long utcMicrosecondClock;
static unsigned volatile long long localMicrosecondClock;
static unsigned volatile long millisecondClock; /* for the ioMSecs clock. */
static unsigned long long utcStartMicroseconds; /* for the ioMSecs clock. */
static long long vmGMTOffset = 0;
static unsigned long long frequencyMeasureStart = 0;
static unsigned long heartbeats;

#define microToMilliseconds(usecs) ((((usecs) - utcStartMicroseconds) \
									/ MicrosecondsPerMillisecond) \
									& MillisecondClockMask)

#define LOG_CLOCK 1

#if LOG_CLOCK
# define LOGSIZE 1024
static unsigned long long useclog[LOGSIZE];
static unsigned long mseclog[LOGSIZE];
static int logClock = 0;
static unsigned int ulogidx = (unsigned int)-1;
static unsigned int mlogidx = (unsigned int)-1;
# define logusecs(usecs) do { sqLowLevelMFence(); \
							if (logClock) useclog[++ulogidx % LOGSIZE] = (usecs); \
						} while (0)
# define logmsecs(msecs) do { sqLowLevelMFence(); \
							if (logClock) mseclog[++mlogidx % LOGSIZE] = (msecs); \
						} while (0)


void heartbeat_wait_if_polling();

/*
 * These semaphores are used to stop the heartbeat if we are in a poll
 */

Semaphore* heartbeatStopMutex;
Semaphore* heartbeatSemaphore;
static int polling = 0;
static int stoppedHeartbeat = 0;


void
ioGetClockLogSizeUsecsIdxMsecsIdx(sqInt *runInNOutp, void **usecsp, sqInt *uip, void **msecsp, sqInt *mip)
{
	logClock = *runInNOutp;
	sqLowLevelMFence();
	*runInNOutp = LOGSIZE;
	*usecsp = useclog;
	*uip = ulogidx % LOGSIZE;
	*msecsp = mseclog;
	*mip = mlogidx % LOGSIZE;
}
#else /* LOG_CLOCK */
# define logusecs(usecs) 0
# define logmsecs(msecs) 0
void
ioGetClockLogSizeUsecsIdxMsecsIdx(sqInt *np, void **usecsp, sqInt *uip, void **msecsp, sqInt *mip)
{
	*np = *uip = *mip = 0;
	*usecsp = *msecsp = 0;
}
#endif /* LOG_CLOCK */


/* Compute the current VM time basis, the number of microseconds from 1901. */

static unsigned long long
currentUTCMicroseconds()
{
#if defined(_WIN32)
	FILETIME ft;
	SYSTEMTIME st;
	ULARGE_INTEGER l;

	GetSystemTime(&st);              // Gets the current system time
	SystemTimeToFileTime(&st, &ft);  // Converts the current system time to file time format
	
	// Copy the file time structure to a large integer structure
	l.LowPart  = ft.dwLowDateTime;
	l.HighPart = ft.dwHighDateTime;

	//The number of 100-nanosecond intervals since January 1, 1601
	//Transform it to microseconds
	//TODO: Convert to january 1901 relative
	return l.QuadPart / 10;
#else
	struct timeval utcNow;
	gettimeofday(&utcNow,0);
	return ((utcNow.tv_sec * MicrosecondsPerSecond) + utcNow.tv_usec)
		+ MicrosecondsFrom1901To1970;
#endif
}

/*
 * Update the utc and local microsecond clocks, and the millisecond clock.
 * Since this is invoked from interupt code, and since the clocks are 64-bit values
 * that are read concurrently by the VM, care must be taken to access these values
 * atomically on 32-bit systems.  If they are not accessed atomically there is a
 * possibility of fetching the two halves of the clock from different ticks which
 * would cause a jump in the clock of 2^32 microseconds (1 hr, 11 mins, 34 secs).
 *
 * Since an interrupt could occur between any two instructions the clock must be
 * read atomically as well as written atomically.  If possible this can be
 * implemented without locks using atomic 64-bit reads and writes.
 */

#include "sqAtomicOps.h"

static void
updateMicrosecondClock()
{
	unsigned long long newUtcMicrosecondClock;
	unsigned long long newLocalMicrosecondClock;

	newUtcMicrosecondClock = currentUTCMicroseconds();

	/* The native clock may go backwards, e.g. due to NTP adjustments, although
	 * why it can't avoid small backward steps itself, I don't know.  Simply
	 * ignore backward steps and wait until the clock catches up again.  Of
	 * course this will cause problems if the clock is manually adjusted.  To
	 * which the doctor says, "don't do that".
	 */
	if (!asserta(newUtcMicrosecondClock >= utcMicrosecondClock)) {
		logusecs(0); /* if logging log a backward step as 0 */
		return;
	}
	newLocalMicrosecondClock = newUtcMicrosecondClock + vmGMTOffset;

	set64(utcMicrosecondClock,newUtcMicrosecondClock);
	set64(localMicrosecondClock,newLocalMicrosecondClock);
	millisecondClock = microToMilliseconds(newUtcMicrosecondClock);

	logusecs(newUtcMicrosecondClock);
	logmsecs(millisecondClock);
}

void
ioUpdateVMTimezone()
{
	updateMicrosecondClock();
#ifdef HAVE_TM_GMTOFF
	time_t utctt;
	utctt = (get64(utcMicrosecondClock) - MicrosecondsFrom1901To1970)
				/ MicrosecondsPerSecond;
	vmGMTOffset = localtime(&utctt)->tm_gmtoff * MicrosecondsPerSecond;
#else
# ifdef HAVE_TIMEZONE
  extern time_t timezone, altzone;
  extern int daylight;
  vmGMTOffset = -1 * (daylight ? altzone : timezone) * MicrosecondsPerSecond;
# endif
#endif

#ifdef WIN64
  TIME_ZONE_INFORMATION timeZoneInformation;
  if(GetTimeZoneInformation(&timeZoneInformation) == TIME_ZONE_ID_INVALID){
	  logError("Unable to get timezone information");
	  vmGMTOffset = 0;
	  return;
  }
  //The Bias is in minutes
  vmGMTOffset = timeZoneInformation.Bias * 60 * MicrosecondsPerSecond;
#endif

}

sqLong
ioHighResClock(void)
{
  /* return the value of the high performance counter */
  sqLong value = 0;

#if defined(__GNUC__) && (defined(i386) || defined(__i386) || defined(__i386__))
    __asm__ __volatile__ ("rdtsc" : "=A"(value));
#elif defined(__GNUC__) && (defined(x86_64) || defined(__x86_64) || defined (__x86_64__))
    __asm__ __volatile__ ("rdtsc\n\t"			// Returns the time in EDX:EAX.
						"shl $32, %%rdx\n\t"	// Shift the upper bits left.
						"or %%rdx, %0"			// 'Or' in the lower bits.
						: "=a" (value)
						: 
						: "rdx");
#elif (defined(__arm__) && (defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_7A__))) || defined(__aarch64__) || defined(_M_ARM64)
	/* tpr - do nothing for now; needs input from eliot to decide further */
	/* Tim, not sure I have input beyond:
		Is there a 64-bit clock on ARM?  If so, access it here :-)
		see
		https://stackoverflow.com/questions/40454157/is-there-an-equivalent-instruction-to-rdtsc-in-arm/40455065
		https://developer.arm.com/documentation/ddi0460/c/Events-and-Performance-Monitor/Performance-monitoring-registers/c9--User-Enable-Register
		https://developer.arm.com/documentation/ddi0460/c/Events-and-Performance-Monitor/Performance-monitoring-registers/c9--Count-Enable-Set-Register
		https://github.com/google/benchmark/blob/v1.1.0/src/cycleclock.h#L116
	 */
#elif defined(_WIN32)
	value = __rdtsc();
#else
# error "no high res clock defined"
#endif
  return value;
}

unsigned volatile long long
ioUTCMicroseconds() { return get64(utcMicrosecondClock); }

unsigned volatile long long
ioLocalMicroseconds() { return get64(localMicrosecondClock); }

sqInt
ioLocalSecondsOffset() { return vmGMTOffset / MicrosecondsPerSecond; }

/* This is an expensive interface for use by Smalltalk or vm profiling code that
 * wants the time now rather than as of the last heartbeat.
 */
unsigned volatile long long
ioUTCMicrosecondsNow() { return currentUTCMicroseconds(); }

unsigned long long
ioUTCStartMicroseconds() { return utcStartMicroseconds; }

unsigned volatile long long
ioLocalMicrosecondsNow() { return currentUTCMicroseconds() + vmGMTOffset; };

/* ioMSecs answers the millisecondClock as of the last tick. */
long
ioMSecs() { return millisecondClock; }

/* ioMicroMSecs answers the millisecondClock right now */
sqInt ioMicroMSecs(void) { return microToMilliseconds(currentUTCMicroseconds());}

/* returns the local wall clock time */
sqInt
ioSeconds(void) { return get64(localMicrosecondClock) / MicrosecondsPerSecond; }

sqInt
ioSecondsNow(void) { return ioLocalMicrosecondsNow() / MicrosecondsPerSecond; }

sqInt
ioUTCSeconds(void) { return get64(utcMicrosecondClock) / MicrosecondsPerSecond; }

sqInt
ioUTCSecondsNow(void) { return currentUTCMicroseconds() / MicrosecondsPerSecond; }

sqInt
ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
    long	realTimeToWait;
	extern usqLong getNextWakeupUsecs();
	usqLong nextWakeupUsecs = getNextWakeupUsecs();
	usqLong utcNow = get64(utcMicrosecondClock);

    if (nextWakeupUsecs <= utcNow) {
		/* if nextWakeupUsecs is non-zero the next wakeup time has already
		 * passed and we should not wait.
		 */
        if (nextWakeupUsecs != 0)
			return 0;
		realTimeToWait = microSeconds;
    }
    else {
        realTimeToWait = nextWakeupUsecs - utcNow;
		if (realTimeToWait > microSeconds)
			realTimeToWait = microSeconds;
	}

    aioPoll(realTimeToWait);

	return 0;
}

void
ioInitTime(void)
{
	ioUpdateVMTimezone(); /* does updateMicrosecondClock as a side-effect */
	updateMicrosecondClock(); /* this can now compute localUTCMicroseconds */
	utcStartMicroseconds = utcMicrosecondClock;
}

static void
heartbeat()
{
	int saved_errno = errno;

	updateMicrosecondClock();
	if (get64(frequencyMeasureStart) == 0) {
		set64(frequencyMeasureStart,utcMicrosecondClock);
		heartbeats = 0;
	}
	else
		heartbeats += 1;
	checkHighPriorityTickees(utcMicrosecondClock);
	forceInterruptCheckFromHeartbeat();

	errno = saved_errno;
}

typedef enum { dead, condemned, nascent, quiescent, active } machine_state;

#if !defined(_WIN32)
#define UNDEFINED 0xBADF00D

static int					stateMachinePolicy = UNDEFINED;
static struct sched_param	stateMachinePriority;
#endif

static volatile machine_state beatState = nascent;

#if !defined(DEFAULT_BEAT_MS)
# define DEFAULT_BEAT_MS 2
#endif
static int beatMilliseconds = DEFAULT_BEAT_MS;
static struct timespec beatperiod = { 0, DEFAULT_BEAT_MS * 1000 * 1000 };

#if defined(_WIN32)
DWORD WINAPI
beatStateMachine(LPVOID careLess)
#else
static void *
beatStateMachine(void *careLess)
#endif
{
#if !defined(_WIN32) // Change heartbeat priority
    int er;
	if ((er = pthread_setschedparam(pthread_self(),
									stateMachinePolicy,
									&stateMachinePriority))) {
		/* Linux pthreads as of 2009 does not support setting the priority of
		 * threads other than with real-time scheduling policies.  But such
		 * policies are only available to processes with superuser privileges.
		 * Linux kernels >= 2.6.13 support different thread priorities, but
		 * require a suitable /etc/security/limits.d/VMNAME.conf.
		 */
		extern char *revisionAsString();
		errno = er;
		logWarnFromErrno("pthread_setschedparam failed");
	}
#endif

	beatState = active;
	while (beatState != condemned) {
# define MINSLEEPNS 2000 /* don't bother sleeping for short times */
		struct timespec naptime = beatperiod;

#if defined(_WIN32)
		Sleep(2);
#else
		while (nanosleep(&naptime, &naptime) == -1
			&& naptime.tv_sec >= 0 /* oversleeps can return tv_sec < 0 */
			&& (naptime.tv_sec > 0 || naptime.tv_nsec > MINSLEEPNS)) /*repeat*/
			if (errno != EINTR) {
				logErrorFromErrno("nanosleep");
				exit(1);
			}
#endif
		heartbeat_wait_if_polling();
		heartbeat();
	}
	beatState = dead;
	return 0;
}

void
ioInitHeartbeat()
{
	struct timespec halfAMo;
#if defined(_WIN32)
	HANDLE careLess;
#else
	int er;
	pthread_t careLess;
#endif

	heartbeatStopMutex = platform_semaphore_new(1);
	heartbeatSemaphore = platform_semaphore_new(0);
	polling = 0;

#if !defined(_WIN32)  // Change heartbeat priority
	/* First time through choose a policy and priority for the heartbeat thread,
	 * and install ioInitHeartbeat via pthread_atfork to be run again in a forked
	 * child, restarting the heartbeat in a forked child.
	 */
	if (stateMachinePolicy == UNDEFINED) {
		if ((er = pthread_getschedparam(pthread_self(),
										&stateMachinePolicy,
										&stateMachinePriority))) {
			errno = er;
			logErrorFromErrno("pthread_getschedparam failed");
			exit(errno);
		}
		assert(stateMachinePolicy != UNDEFINED);
		++stateMachinePriority.sched_priority;
		/* If the priority isn't appropriate for the policy (typically
		 * SCHED_OTHER) then change policy.
		 */
		if (sched_get_priority_max(stateMachinePolicy) < stateMachinePriority.sched_priority)
			stateMachinePolicy = SCHED_FIFO;
		pthread_atfork(0, /*prepare*/ 0, /*parent*/ ioInitHeartbeat /*child*/);
	}
	else {
		/* subsequently (in the child) init beatState before creating thread */
		beatState = nascent;
	}
#endif  // Change heartbeat priority

	halfAMo.tv_sec  = 0;
	halfAMo.tv_nsec = 1000 * 100;

#if defined(_WIN32)
	careLess = CreateThread(
		NULL,                   // default security attributes
		0,                      // use default stack size  
		beatStateMachine,       // thread function name
		NULL,			            // argument to thread function
		0,                      // use default creation flags: 0 is run immediately
		NULL);   // returns the thread identifier 
#else
	if ((er= pthread_create(&careLess,
							(const pthread_attr_t *)0,
							beatStateMachine,
							0))) {
		errno = er;
		logErrorFromErrno("beat thread creation failed");
		exit(errno);
	}
#endif	
	
	while (beatState == nascent) {
#if defined(_WIN32)
		//Nothing for now?
#else
		nanosleep(&halfAMo, 0);
#endif
	}
}

void
ioSetHeartbeatMilliseconds(int ms)
{
	beatMilliseconds = ms;
	beatperiod.tv_sec = beatMilliseconds / 1000;
	beatperiod.tv_nsec = (beatMilliseconds % 1000) * 1000 * 1000;
}

int
ioHeartbeatMilliseconds() { return beatMilliseconds; }


/* Answer the average heartbeats per second since the stats were last reset.
 */
unsigned long
ioHeartbeatFrequency(int resetStats)
{
	unsigned long duration = (ioUTCMicroseconds() - get64(frequencyMeasureStart))
						/ MicrosecondsPerSecond;
	unsigned long frequency = duration ? heartbeats / duration : 0;

	if (resetStats) {
		unsigned long long zero = 0;
		set64(frequencyMeasureStart,zero);
	}
	return frequency;
}


EXPORT(long long) getVMGMTOffset(){
	return vmGMTOffset;
}

/**
 * The heartbeat should not run if we are in a poll
 */


void
heartbeat_wait_if_polling(){
	heartbeatStopMutex->wait(heartbeatStopMutex);
	if(polling == 0){
		heartbeatStopMutex->signal(heartbeatStopMutex);
		return;
	}

	stoppedHeartbeat = 1;

	heartbeatStopMutex->signal(heartbeatStopMutex);
	heartbeatSemaphore->wait(heartbeatSemaphore);
}

void
heartbeat_poll_enter(long microSeconds){
	//I only care if waited time is bigger than a millisecond
	if(microSeconds <= 1000)
		return;

	heartbeatStopMutex->wait(heartbeatStopMutex);
	polling = 1;
	heartbeatStopMutex->signal(heartbeatStopMutex);
}

void
heartbeat_poll_exit(long microSeconds){
	//I only care if waited time is bigger than a millisecond
	if(microSeconds <= 1000 && polling == 0)
		return;

	heartbeatStopMutex->wait(heartbeatStopMutex);
	polling = 0;

	if(stoppedHeartbeat)
		heartbeatSemaphore->signal(heartbeatSemaphore);

	heartbeatStopMutex->signal(heartbeatStopMutex);
}

