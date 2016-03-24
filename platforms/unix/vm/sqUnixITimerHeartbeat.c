/****************************************************************************
*   PROJECT: Unix (setitimer) heartbeat logic for Stack/Cog VM *without* ticker
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
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/time.h>

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
	struct timeval utcNow;

	gettimeofday(&utcNow,0);
	return ((utcNow.tv_sec * MicrosecondsPerSecond) + utcNow.tv_usec)
			+ MicrosecondsFrom1901To1970;
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
# else
#  error: cannot determine timezone correction
# endif
#endif
}

sqLong
ioHighResClock(void)
{
  /* return the value of the high performance counter */
  sqLong value = 0;
#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(i486) || defined(__i486) || defined (__i486__) \
			|| defined(intel) || defined(x86) || defined(i86pc) \
			|| defined(x86_64) || defined(__x86_64) || defined (__x86_64__))
    __asm__ __volatile__ ("rdtsc" : "=A"(value));
#elif defined(__arm__) && (defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_7A__))
	/* tpr - do nothing for now; needs input from eliot to decide further */
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
long ioMicroMSecs(void) { return microToMilliseconds(currentUTCMicroseconds());}

/* returns the local wall clock time */
sqInt
ioSeconds(void) { return get64(localMicrosecondClock) / MicrosecondsPerSecond; }

sqInt
ioSecondsNow(void) { return ioLocalMicrosecondsNow() / MicrosecondsPerSecond; }

sqInt
ioUTCSeconds(void) { return get64(utcMicrosecondClock) / MicrosecondsPerSecond; }

sqInt
ioUTCSecondsNow(void) { return currentUTCMicroseconds() / MicrosecondsPerSecond; }

/*
 * On Mac OS X use the following.
 * On Unix use dpy->ioRelinquishProcessorForMicroseconds
 */
#if macintoshSqueak
sqInt
ioRelinquishProcessorForMicroseconds(int microSeconds)
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

	aioSleepForUsecs(realTimeToWait);

	return 0;
}
#endif /* !macintoshSqueak */

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
	forceInterruptCheckFromHeartbeat();

	errno = saved_errno;
}

#if !defined(DEFAULT_BEAT_MS)
# define DEFAULT_BEAT_MS 2
#endif
static int beatMilliseconds = DEFAULT_BEAT_MS;

/* Use ITIMER_REAL/SIGALRM because the VM can enter a sleep in the OS via
 * e.g. ioRelinquishProcessorForMicroseconds in which the OS will assume the
 * process is not running and not deliver the signals.
 */
#if 0
# define THE_ITIMER ITIMER_PROF
# define ITIMER_SIGNAL SIGPROF
#elif 0
# define THE_ITIMER ITIMER_VIRTUAL
# define ITIMER_SIGNAL SIGVTALRM
#else
# define THE_ITIMER ITIMER_REAL
# define ITIMER_SIGNAL SIGALRM
#endif

#if !defined(SA_NODEFER)
static int handling_heartbeat = 0;
#endif

static void
heartbeat_handler(int sig, struct siginfo *sig_info, void *context)
{
#if !defined(SA_NODEFER)
	/* if the CAS fails, the heartbeat is already being handled. */
    if (!sqCompareAndSwap(handling_heartbeat,0,1))
		return;

	handling_heartbeat = 1;
#endif

	heartbeat();

#if 0
	if (heartbeats % 250 == 0) {
		printf(".");
		fflush(stdout);
	}
#endif
#if !defined(SA_NODEFER)
	handling_heartbeat = 0;
#endif
}

/* Especially useful on linux when LD_BIND_NOW is not in effect and the
 * dynamic linker happens to run in a signal handler.
 */
#define NEED_SIGALTSTACK 1
#if NEED_SIGALTSTACK
/* If the ticker is run from the heartbeat signal handler one needs to use an
 * alternative stack to avoid overflowing the VM's stack pages.  Keep
 * the structure around for reference during debugging.
 */
# define SIGNAL_STACK_SIZE (1024 * sizeof(void *) * 16)
static stack_t signal_stack;
#endif /* NEED_SIGALTSTACK */

static void
setIntervalTimer(long milliseconds)
{
	struct itimerval pulse;

	pulse.it_interval.tv_sec = milliseconds / 1000;
	pulse.it_interval.tv_usec = (milliseconds % 1000) * 1000;
	pulse.it_value = pulse.it_interval;
	if (setitimer(THE_ITIMER, &pulse, &pulse)) {
		perror("ioInitHeartbeat setitimer");
		exit(1);
	}
}

void
ioInitHeartbeat()
{
extern sqInt suppressHeartbeatFlag;
	int er;
	struct sigaction heartbeat_handler_action;
	sigset_t ss;

	if (suppressHeartbeatFlag) return;

#if NEED_SIGALTSTACK
# define max(x,y) (((x)>(y))?(x):(y))
	if (!signal_stack.ss_size) {
		signal_stack.ss_flags = 0;
		signal_stack.ss_size = max(SIGNAL_STACK_SIZE,MINSIGSTKSZ);
		if (!(signal_stack.ss_sp = malloc(signal_stack.ss_size))) {
			perror("ioInitHeartbeat malloc");
			exit(1);
		}
		if (sigaltstack(&signal_stack, 0) < 0) {
			perror("ioInitHeartbeat sigaltstack");
			exit(1);
		}
	}
#endif /* NEED_SIGALTSTACK */

	heartbeat_handler_action.sa_sigaction = heartbeat_handler;
	/* N.B. We _do not_ include SA_NODEFER to specifically prevent reentrancy
	 * during the heartbeat.  We *must* include SA_RESTART to avoid breaking
	 * lots of external code (e.g. the mysql odbc connect).
	 */
#if NEED_SIGALTSTACK
	heartbeat_handler_action.sa_flags = SA_RESTART | SA_ONSTACK;
#else
	heartbeat_handler_action.sa_flags = SA_RESTART;
#endif
	sigemptyset(&heartbeat_handler_action.sa_mask);
	if (sigaction(ITIMER_SIGNAL, &heartbeat_handler_action, 0)) {
		perror("ioInitHeartbeat sigaction");
		exit(1);
	}

	/* Make sure SIGALRM is unblocked. */
	sigemptyset(&ss);
	sigaddset(&ss, ITIMER_SIGNAL);
	sigprocmask(SIG_UNBLOCK, &ss, NULL);

	setIntervalTimer(beatMilliseconds);
}

void
ioDisableHeartbeat() /* for debugging */
{
	setIntervalTimer(0);
}

/* Occasionally bizarre interactions cause the heartbeat's interval timer to
 * disable.  On CentOS linux when using PAM to authenticate, a failing authen-
 * tication sequence disables the interval timer, for reasons unknown (setting
 * a breakpoint in setitimer doesn't show an actual call).  So a work around is
 * to check the timer as a side-effect of ioRelinquishProcessorForMicroseconds.
 */
void
checkHeartStillBeats()
{
	struct itimerval hb_itimer;

	if (getitimer(THE_ITIMER, &hb_itimer) < 0)
		perror("getitimer");
	else if (!hb_itimer.it_interval.tv_sec
		  && !hb_itimer.it_interval.tv_usec)
		setIntervalTimer(beatMilliseconds);
}

void
printHeartbeatTimer()
{
	struct itimerval hb_itimer;
	struct sigaction hb_handler_action;

	if (getitimer(THE_ITIMER, &hb_itimer) < 0)
		perror("getitimer");
	else
		printf("heartbeat timer interval s %ld us %ld value s %ld us %ld\n",
				hb_itimer.it_interval.tv_sec, hb_itimer.it_interval.tv_usec,
				hb_itimer.it_value.tv_sec, hb_itimer.it_value.tv_usec);

	if (sigaction(ITIMER_SIGNAL, 0, &hb_handler_action) < 0)
		perror("sigaction");
	else
		printf("heartbeat signal handler %p (%s)\n",
				hb_handler_action.sa_sigaction,
				hb_handler_action.sa_sigaction == heartbeat_handler
					? "heartbeat_handler"
					: "????");
}

void
ioSetHeartbeatMilliseconds(int ms)
{
	beatMilliseconds = ms;
	ioInitHeartbeat();
}

int
ioHeartbeatMilliseconds() { return beatMilliseconds; }


/* Answer the average heartbeats per second since the stats were last reset.
 */
unsigned long
ioHeartbeatFrequency(int resetStats)
{
	unsigned duration = (ioUTCMicroseconds() - get64(frequencyMeasureStart))
						/ MicrosecondsPerSecond;
	unsigned frequency = duration ? heartbeats / duration : 0;

	if (resetStats) {
		unsigned long long zero = 0;
		set64(frequencyMeasureStart,zero);
	}
	return frequency;
}
