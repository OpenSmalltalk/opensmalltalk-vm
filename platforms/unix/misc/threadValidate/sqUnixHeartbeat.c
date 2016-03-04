/****************************************************************************
*   PROJECT: Unix (pthread or setitimer) heartbeat logic for Stack VM
*   FILE:    sqUnixHeartbeat.c
*   CONTENT: 
*
*   AUTHOR:  Eliot Miranda
*   ADDRESS: 
*   EMAIL:   eliot@qwaq.com
*   RCSID:   $Id$
*
*   NOTES: 
*  July 31st, 2008, EEM added heart-beat thread.
*  Aug  20th, 2009, EEM added 64-bit microsecond clock support code
*
*****************************************************************************/

#include "sq.h"
#include <errno.h>
#if ITIMER_HEARTBEAT
# include <signal.h>
#else
# include <pthread.h>
#endif
#include <sys/types.h>
#include <sys/time.h>

#define SecondsFrom1901To1970      2177452800ULL
#define MicrosecondsFrom1901To1970 2177452800000000ULL

#define MicrosecondsPerSecond 1000000ULL
#define MillisecondsPerSecond 1000ULL

#define MicrosecondsPerMillisecond 1000ULL

static unsigned volatile long long utcMicrosecondClock;
static unsigned volatile long long localMicrosecondClock;
static unsigned long long utcStartMicroseconds; /* for the ioMSecs clock. */
static long long vmGMTOffset = 0;
static unsigned long long frequencyMeasureStart = 0;
static unsigned long heartbeats;

/*
 * Update the utc and local microsecond clocks.  Since this is invoked from
 * interupt code, and since the clocks are 64-bit values that are read
 * concurrently by the VM, care must be taken to access these values atomically
 * on 32-bit systems.  If they are not access atomically there is a possibility
 * of fetching the two halves of the clock from different ticks which would
 * cause a jump in the clock of 2^32 microseconds (1 hr, 11mins, 34 secs).
 *
 * Since an interrupt could occur between any two instructions the clock must be
 * read atomically as well as written atomically.  If possible this can be
 * implemented without locks using atomic 64-bit reads and writes.
 */

#include "sqAtomicOps.h"

static void
updateMicrosecondClock()
{
	struct timeval utcNow;
	unsigned long long newUtcMicrosecondClock;
	unsigned long long newLocalMicrosecondClock;

	gettimeofday(&utcNow,0);
	newUtcMicrosecondClock = ((utcNow.tv_sec * MicrosecondsPerSecond)
								+ utcNow.tv_usec)
							+ MicrosecondsFrom1901To1970;
	newLocalMicrosecondClock = newUtcMicrosecondClock + vmGMTOffset;

	set64(utcMicrosecondClock,newUtcMicrosecondClock);
	set64(localMicrosecondClock,newLocalMicrosecondClock);
}

void
ioUpdateVMTimezone()
{
	time_t utctt;
	updateMicrosecondClock();
	utctt = (get64(utcMicrosecondClock) - MicrosecondsFrom1901To1970)
				/ MicrosecondsPerSecond;
	vmGMTOffset = localtime(&utctt)->tm_gmtoff * MicrosecondsPerSecond;
}

int
ioMSecs()
{
	return ((get64(utcMicrosecondClock) - utcStartMicroseconds)
			/ MicrosecondsPerMillisecond)
			& 0x3FFFFFFF;
}

sqLong
ioHighResClock(void)
{
  /* return the value of the high performance counter */
  sqLong value = 0;
#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(i486) || defined(__i486) || defined (__i486__) \
			|| defined(intel) || defined(x86) || defined(i86pc) )
    __asm__ __volatile__ ("rdtsc" : "=A"(value));
#else
# error "no high res clock defined"
#endif
  return value;
}

/* Note: ioMicroMSecs returns *milli*seconds */
int ioMicroMSecs(void)
{
	updateMicrosecondClock();
	return ioMSecs();
}

/* returns the local wall clock time */
int
ioSeconds(void)
{
	return get64(localMicrosecondClock) / MicrosecondsPerSecond;
}

/* This is an expensive interface for use by profiling code that wants the time
 * now rather than as of the last heartbeat.
 */
usqLong
ioUTCMicrosecondsNow()
{
	updateMicrosecondClock();
	return get64(utcMicrosecondClock);
}

usqLong
ioUTCMicroseconds() { return get64(utcMicrosecondClock); }

usqLong
ioLocalMicroseconds() { return get64(localMicrosecondClock); }

int
ioUTCSeconds(void)
{
	return get64(utcMicrosecondClock) / MicrosecondsPerSecond;
}

/*
 * On Mac OS X use the following.
 * On Unix use dpy->ioRelinquishProcessorForMicroseconds
 */
#if macintoshSqueak
int
ioRelinquishProcessorForMicroseconds(int microSeconds)
{
    long	realTimeToWait;
	extern usqLong getNextWakeupUsecs();
	usqLong nextWakeupUsecs = getNextWakeupUsecs();
	usqLong utcNow = get64(utcMicrosecondClock);

    if (nextWakeupUsecs <= utcNow) {
		/* if nextWakeupUsecs is non-zero the next wakeup time has already
		 * passed and we shopuld not wait.
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
	updateMicrosecondClock();
	if (get64(frequencyMeasureStart) == 0) {
		set64(frequencyMeasureStart,utcMicrosecondClock);
		heartbeats = 0;
	}
	else
		heartbeats += 1;
#if ITIMER_HEARTBEAT
	{ void prodHighPriorityThread(void); prodHighPriorityThread(); }
#else
	checkHighPriorityTickees(utcMicrosecondClock);
#endif
	forceInterruptCheckFromHeartbeat();
}

#if ITIMER_HEARTBEAT
	/* Hack for linux server to avoid the thread priority issue, i.e. that
	 * linux doesn't provide priorities for SCHED_OTHER and won't let a non-
	 * superuser process set the scheduling policy to anything else).
	 *
	 * Solution is to drive heartbeat from an interval timer instead of a high-
	 * priority thread blocking in a sleep.  We use ITIMER_REAL/SIGALRM (see
	 * below).  setitimer(2) claims max itimer resolution on 2.6.13 is 4
	 * milliseconds, but on 2.6.18-128.el5 one can see periods of 1.2ms.
	 *
	 * The high-priority tickees cannot be run from the interrupt-driven heart-
	 * beat and must be run from a separate thread to avoid numerous sources
	 * of deadlock (e.g. the lock in malloc).  But since the thread has the
	 * same priority as the VM thread we arrange that the VM yields to the
	 * high-priority ticker when it is running.  This is co-ordinated in
	 * sqTicker.c by ioSynchronousCheckForEvents (the synchronous ticker)
	 * yielding if requested by checkHighPriorityTickees.  To perform the yield,
	 * these functions use yieldToHighPriorityTickerThread and
	 * unblockVMThreadAfterYieldToHighPriorityTickerThread to do the dirty work.
	 *
	 * The itimer signal handler ensures it is running on the VM thread and
	 * then invokes a signal handler on the high-priority thread (see
	 * prodHighPriorityThread).  This signal breaks the high-priority thread
	 * out of its nanosleep and it calls checkHighPriorityTickees.
	 */
#define TICKER_SIGNAL SIGUSR2 /* SIGURSR1 dumps the stack */
static pthread_t tickerThread;

void
prodHighPriorityThread()
{
	/* invoke the tickerThread's signal handler */
	pthread_kill(tickerThread, TICKER_SIGNAL);
}

static void
high_performance_tick_handler(int sig, struct siginfo *sig_info, void *context)
{
static int tickCheckInProgress;

	if (tickCheckInProgress) return;

	tickCheckInProgress = 1;
	checkHighPriorityTickees(ioUTCMicroseconds());
	tickCheckInProgress = 0;
}

static void
tickerSleepCycle(void *ignored)
{
	struct timespec naptime;

	naptime.tv_sec = 3600;
	naptime.tv_nsec = 0;

	while (1)
		(void)nanosleep(&naptime, 0);
}

/* N.B. This is laziness.  If needed on other than linux one would have to
 * initializea mutexattr with PTHREAD_ERRORCHECK_MUTEX type.  We require
 * the errr check because we're lazy in preventing multiple attempts at
 * locking yield_mutex in yieldToHighPriorityTickerThread.
 */
static pthread_mutex_t yield_sync = PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP;
static pthread_mutex_t yield_mutex = PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP;
static pthread_cond_t yield_cond = PTHREAD_COND_INITIALIZER;

/* Private to sqTicker.c ioSynchronousCheckForEvents */
void
yieldToHighPriorityTickerThread()
{
	int err;

	if ((err = pthread_mutex_lock(&yield_mutex))) {
		if (err != EDEADLK)
			fprintf(stderr,"pthread_mutex_lock yield_mutex %s\n", strerror(err));
	}
	/* If lock fails then unblockVMThreadAfterYieldToHighPriorityTickerThread
	 * has locked and we should not block.
	 */
	if ((err = pthread_mutex_lock(&yield_sync))) {
		if (err != EDEADLK)
			fprintf(stderr,"pthread_mutex_lock yield_sync %s\n", strerror(err));
	}
	else if ((err = pthread_cond_wait(&yield_cond, &yield_mutex)))
		fprintf(stderr,"pthread_cond_wait %s\n", strerror(err));
}

/* Private to sqTicker.c checkHighPriorityTickees */
void
unblockVMThreadAfterYieldToHighPriorityTickerThread()
{
	/* If yield_sync is already locked the VM thread is very likely blocking in
	 * yieldToHighPriorityTickerThread and so yield_cond should be signalled.
	 */
	if (pthread_mutex_trylock(&yield_sync) == 0) /* success */
		pthread_mutex_unlock(&yield_sync);
	else
		pthread_cond_signal(&yield_cond);
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

/* With ticker support it may be that a ticker function invoked heartbeat takes
 * so long that another timer interrupt occurs before heartbeat has finished.
 * The absence of SA_NODEFER in heartbeat_handler_action.sa_flags prevents
 * reentrancy, if available.
 *
 * With lots of threads it may be that the kernel delivers the signal on some
 * other thread.
 */
#if !defined(SA_NODEFER)
static int handling_heartbeat = 0;
#endif

static void
heartbeat_handler(int sig, struct siginfo *sig_info, void *context)
{
	if (!ioOSThreadsEqual(ioCurrentOSThread(),getVMThread())) {
		pthread_kill(getVMThread(),sig);
		return;
	}

#if !defined(SA_NODEFER)
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

#define NEED_SIGALTSTACK 1 /* for safety; some time need to turn off and test */
#if NEED_SIGALTSTACK
/* If the ticker is run from the heartbeat signal handler one needs to use an
 * alternative stack to avoid overflowing the VM's stack pages.  Keep
 * the structure around for reference during debugging.
 */
#define SIGNAL_STACK_SIZE (1024 * sizeof(void *) * 16)
static stack_t signal_stack;
#endif /* NEED_SIGALTSTACK */

void
ioInitHeartbeat()
{
	int er;
	struct timespec halfAMo;
	struct sigaction heartbeat_handler_action, ticker_handler_action;
	struct itimerval pulse;

#if NEED_SIGALTSTACK
	signal_stack.ss_flags = 0;
	signal_stack.ss_size = SIGNAL_STACK_SIZE;
	if (!(signal_stack.ss_sp = malloc(signal_stack.ss_size))) {
		perror("ioInitHeartbeat malloc");
		exit(1);
	}
	if (sigaltstack(&signal_stack, 0) < 0) {
		perror("ioInitHeartbeat sigaltstack");
		exit(1);
	}
#endif /* NEED_SIGALTSTACK */

	halfAMo.tv_sec  = 0;
	halfAMo.tv_nsec = 1000 * 100;
	if ((er= pthread_create(&tickerThread,
							(const pthread_attr_t *)0,
							tickerSleepCycle,
							0))) {
		errno = er;
		perror("beat thread creation failed");
		exit(errno);
	}

	ticker_handler_action.sa_sigaction = high_performance_tick_handler;
	/* N.B. We _do not_ include SA_NODEFER to specifically prevent reentrancy
	 * during the heartbeat. We /must/ include SA_RESTART to avoid issues with
     * e.g. ODBC connections.
	 */
	ticker_handler_action.sa_flags = SA_RESTART | SA_ONSTACK;
	sigemptyset(&ticker_handler_action.sa_mask);
	if (sigaction(TICKER_SIGNAL, &ticker_handler_action, 0)) {
		perror("ioInitHeartbeat sigaction");
		exit(1);
	}

	heartbeat_handler_action.sa_sigaction = heartbeat_handler;
	/* N.B. We _do not_ include SA_NODEFER to specifically prevent reentrancy
	 * during the heartbeat.
	 */
#if 0
	heartbeat_handler_action.sa_flags = SA_RESTART | SA_ONSTACK;
#else
	/* restarting increases the chance of deadlock? */
	heartbeat_handler_action.sa_flags = SA_ONSTACK;
#endif
	sigemptyset(&heartbeat_handler_action.sa_mask);
	if (sigaction(ITIMER_SIGNAL, &heartbeat_handler_action, 0)) {
		perror("ioInitHeartbeat sigaction");
		exit(1);
	}

	pulse.it_interval.tv_sec = beatMilliseconds / 1000;
	pulse.it_interval.tv_usec = (beatMilliseconds % 1000) * 1000;
	pulse.it_value = pulse.it_interval;
	if (setitimer(THE_ITIMER, &pulse, &pulse)) {
		perror("ioInitHeartbeat setitimer");
		exit(1);
	}
}

void
ioSetHeartbeatMilliseconds(int ms)
{
	beatMilliseconds = ms;
	ioInitHeartbeat();
}
#else /* ITIMER_HEARTBEAT */
typedef enum { dead, condemned, nascent, quiescent, active } machine_state;

static int					stateMachinePolicy;
static struct sched_param	stateMachinePriority;

static machine_state beatState = nascent;

#if !defined(DEFAULT_BEAT_MS)
# define DEFAULT_BEAT_MS 2
#endif
static int beatMilliseconds = DEFAULT_BEAT_MS;
static struct timespec beatperiod = { 0, DEFAULT_BEAT_MS * 1000 * 1000 };

static void *
beatStateMachine(void *careLess)
{
	int er;
#if !ONLY_ONE_THREAD_PRIORITY
	if ((er = pthread_setschedparam(pthread_self(),
									stateMachinePolicy,
									&stateMachinePriority))) {
		/* linux pthreads as of 2009 does not support setting the priority of
		 * threads other than with real-time scheduling policies.  But such
		 * policies are only available to processes with superuser privileges.
		 */
		errno = er;
		perror("pthread_setschedparam failed");
		exit(errno);
	}
#endif /* !ONLY_ONE_THREAD_PRIORITY */
	beatState = active;
	while (beatState != condemned) {
# define MINSLEEPNS 2000 /* don't bother sleeping for short times */
		struct timespec naptime = beatperiod;

		while (nanosleep(&naptime, &naptime) == -1
			&& (naptime.tv_sec > 0 || naptime.tv_nsec > MINSLEEPNS)) /*repeat*/
			if (errno != EINTR) {
				perror("nanosleep");
				exit(1);
			}
		heartbeat();
	}
	beatState = dead;
	return 0;
}

void
ioInitHeartbeat()
{
	int er;
	struct timespec halfAMo;
	pthread_t careLess;

	if ((er = pthread_getschedparam(pthread_self(),
									&stateMachinePolicy,
									&stateMachinePriority))) {
		errno = er;
		perror("pthread_getschedparam failed");
		exit(errno);
	}
	++stateMachinePriority.sched_priority;
	halfAMo.tv_sec  = 0;
	halfAMo.tv_nsec = 1000 * 100;
	if ((er= pthread_create(&careLess,
							(const pthread_attr_t *)0,
							beatStateMachine,
							0))) {
		errno = er;
		perror("beat thread creation failed");
		exit(errno);
	}
	while (beatState == nascent)
		nanosleep(&halfAMo, 0);
}

void
ioSetHeartbeatMilliseconds(int ms)
{
	beatMilliseconds = ms;
	beatperiod.tv_sec = beatMilliseconds / 1000;
	beatperiod.tv_nsec = (beatMilliseconds % 1000) * 1000 * 1000;
}
#endif /* ITIMER_HEARTBEAT */

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
