/*
 * Linux thread validation.
 *
 * Main thread simulates VM running for 10 seconds incrementing a 64-bit
 * counter, measuring time against the heartbeat's clock, and running any
 * synchronous tickers that are installed.  If the heartbeat gets locked out
 * its clock will not advance, and the system will lock up.
 *
 * High-performance thread spins blocking on some long sleep.  heartbeat uses
 * pthread_kill to deliver a signal to the high-performance thread whose handler
 * runs the ticker.  The heartbeat also install a synchronous ticker that causes
 * the VM to yield somehow, but installs it only for the duration of the high-
 * performance thread's tick.  i.e. the high-performance thread uninstalls the
 * ticker when done with each tick.
 * The yield can be implemented in different ways and we will experiment there-
 * with.  For example, block briefly in a short sleep, call shed_yield, do
 * a pthreasd_cond_timedwait with a short timeout.
 *
 * The high-performance thread's ticker loops for a few milliseconds increment-
 * ing its own 64-bit counter, simulating work, and then returns.  It also
 * measures time against the heartbeat's clock, and again if the heartbeat gets
 * locked out its clock will not advance and the system will lockup.
 *
 * Main difference this has from current Mac/Win32 codee is that on those
 * systems the ticker shuts out the clock.  Here the heartbeat will simply
 * leave the thread alone if the ticker is already running (via the inProgress
 * flag).  So this could be better.
 */

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <errno.h>
#include <pthread.h>

#include <unistd.h>			/* for ioNumProcesors */
#include <sys/types.h>		/* for ioNumProcesors */
#include <sys/sysctl.h>		/* for ioNumProcesors */

#include "sq.h"
#include "sqAtomicOps.h"
#include "sqMemoryFence.h"

#define SECS 5 /* run for 5 seconds */
#define CHECK_COUNT (unsigned long long)(100 * 1000 * 1000)

pthread_t ioVMThread;

static unsigned long long vmcount, hpcount;
static volatile int checkForEvents, yield;
static int hptickperiodms = 20;
static int yield_count = 0, not_blocked_count = 0, unblock_count = 0;
static long long hptickusecs = 5 * 1000;

static long yieldusecs = 1; /* default */

char *method = "none";

void
printAndQuit()
{
	double idealRatio = (double)hptickusecs / (double)(hptickperiodms * 1000);

	printf("hp/vm %1.3f ideal %1.3f cpus %d yield method %s (usecs %ld)\n",
			(double)hpcount / (double)vmcount,
			ioNumProcessors() == 1
				? idealRatio
				: idealRatio / (1.0 + idealRatio),
			ioNumProcessors(),
			method, yieldusecs);
	printf("vm %10lld hp %9lld hp+vm %10lld yields %d (%d,%d,%d) clk hz %ld\n",
			vmcount, hpcount, vmcount + hpcount,
			yield_count, SECS * 1000 / hptickperiodms,
			unblock_count, not_blocked_count,
			ioHeartbeatFrequency(0));
	exit(0);
}

void
lockedup(int arg)
{
	fprintf(stderr,"system locked %s, time not advancing (yield method %s)\n",
			arg == SIGINT ? "" : (char *)arg, method);
	printf("vm %10lld hp %9lld hp+vm %10lld yields %d (%d,%d,%d) clk hz %ld\n",
			vmcount, hpcount, vmcount + hpcount,
			yield_count, SECS * 1000 / hptickperiodms,
			unblock_count, not_blocked_count,
			ioHeartbeatFrequency(0));
	exit(4);
}

static pthread_mutex_t yield_mutex = PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP;
static pthread_cond_t yield_cond = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t yield_sync = PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP;

enum {	no_yield,
		yield_via_sched_yield,
		yield_via_pthread_yield,
		yield_via_nanosleep,
		yield_via_cond_timedwait,
		yield_via_wait_signal
	} yieldMethod;

#if !YIELD_IN_TICKER
void
maybeYield()
{
	sqLowLevelMFence();
	if (!yield)
		return;
	yield_count += 1;
	switch (yieldMethod) {

		case no_yield:	break;

		case yield_via_sched_yield:
			sched_yield();
			break;

		case yield_via_pthread_yield:
			pthread_yield();
			break;

		case yield_via_nanosleep: {
			struct timespec yieldtime;

			yieldtime.tv_sec = 0;
			yieldtime.tv_nsec = 10 * 1000;

			break;
		}

		case yield_via_cond_timedwait: {
			struct timespec yieldtime;

			yieldtime.tv_sec = 0;
			yieldtime.tv_nsec = 10 * 1000;

			pthread_cond_timedwait(&yield_cond, &yield_mutex, &yieldtime);
			break;
		}

		case yield_via_wait_signal: { int err;
			if ((err = pthread_mutex_lock(&yield_mutex))) {
				if (err != EDEADLK)
					fprintf(stderr,"pthread_mutex_lock yield_mutex %s\n", strerror(err));
			}
			else if ((err = pthread_mutex_lock(&yield_sync))) {
				if (err != EDEADLK)
					fprintf(stderr,"pthread_mutex_lock yield_sync %s\n", strerror(err));
			}
			else {
				sqLowLevelMFence();
				if (yield
				 && (err = pthread_cond_wait(&yield_cond, &yield_mutex)))
					fprintf(stderr,"pthread_cond_wait %s\n", strerror(err));
			}
			break;
		}

		default:
			fprintf(stderr,"unrecognized yield method\n");
			exit(5);
	}
}
#endif /* !YIELD_IN_TICKER */

void
hptick(void)
{
	unsigned long long start = ioUTCMicroseconds();

	yield = 1;
	sqLowLevelMFence();
	while (ioUTCMicroseconds() - start < hptickusecs)
		if ((hpcount += 1ULL) % CHECK_COUNT == 0
		 && ioHeartbeatFrequency(0) == 0)
			lockedup("in hptick");
	yield = 0;
	sqLowLevelMFence();
	if (yieldMethod == yield_via_wait_signal) {
		if (pthread_mutex_trylock(&yield_sync) == 0) {/* success */
			pthread_mutex_unlock(&yield_sync);
			not_blocked_count += 1;
		}
		else {
			pthread_cond_signal(&yield_cond);
			unblock_count += 1;
		}
	}
}

void
forceInterruptCheckFromHeartbeat() { checkForEvents = 1; }

void
fakevm()
{
	while (1) {
		(void)ioUTCMicroseconds();
		if ((vmcount += 1ULL) % CHECK_COUNT == 0
		 && ioHeartbeatFrequency(0) == 0)
			lockedup("in vm");
		if (checkForEvents) {
			checkForEvents = 0;
			ioSynchronousCheckForEvents();
		}
	}
}

int
main(int argc, char *argv[])
{
	int err;

	signal(SIGINT, lockedup);
	ioVMThread = pthread_self();
	ioInitTime();
	ioInitHeartbeat();
	addSynchronousTickee(printAndQuit, SECS * 1000, 0);
	if (argc > 1) {
		method = argv[1];
		if (!strcmp(argv[1],"none"))
			yieldMethod = no_yield;
		else if (!strcmp(argv[1],"sched_yield"))
			yieldMethod = yield_via_sched_yield;
		else if (!strcmp(argv[1],"pthread_yield"))
			yieldMethod = yield_via_pthread_yield;
		else if (!strcmp(argv[1],"nanosleep"))
			yieldMethod = yield_via_nanosleep;
		else if (!strcmp(argv[1],"cond_timedwait")) {
			if ((err = pthread_mutex_lock(&yield_mutex)))
				return 2;
			yieldMethod = yield_via_cond_timedwait;
		}
		else if (!strcmp(argv[1],"wait_signal"))
			yieldMethod = yield_via_wait_signal;
		else {
			fprintf(stderr,
					"usage: %s [none] [sched_yield] [nanosleep] [cond_timedwait] [wait_signal] [yield usecs]\n",
					argv[0]);
			return 3;
		}
		if (argc > 2)
			yieldusecs = atoi(argv[2]);

#if !YIELD_IN_TICKER
		addSynchronousTickee(maybeYield, 2, 0);
#endif /* !YIELD_IN_TICKER */
	}
	addHighPriorityTickee(hptick, hptickperiodms);
	fakevm();
	/* should exit through printAndQuit */
	return 1;
}

int
ioNumProcessors(void)
{
# if defined(CTL_HW) && defined(HW_AVAILCPU)
	int count;
	size_t size = sizeof(count);
	int hw_availproc[2];

	hw_availproc[0] = CTL_HW;
	hw_availproc[1] = HW_AVAILCPU;

	return sysctl(hw_availproc, 2, &count, &size, 0, 0)
			? 1
			: count;
# elif defined(_SC_NPROCESSORS_ONLN)
	int count;

	return (count = sysconf(_SC_NPROCESSORS_ONLN)) == -1
			? 1
			: count;
# else
	printf("could not determine number of processors; assuming 1\n");
	return 1;
# endif
}

void
warning(char *msg) { fprintf(stderr,"%s\n", msg); }
