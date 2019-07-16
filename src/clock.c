#include "pharo.h"
#include "sqMemoryFence.h"

#ifndef WIN32
#include <sys/time.h>
#endif

#define SecondsFrom1901To1970      2177452800LL
#define MicrosecondsFrom1901To1970 2177452800000000LL

#define MicrosecondsPerSecond 1000000LL
#define MillisecondsPerSecond 1000LL
#define MicrosecondsPerMillisecond 1000LL

#define microToMilliseconds(usecs) ((((usecs) - utcStartMicroseconds) \
									/ MicrosecondsPerMillisecond) \
									& MillisecondClockMask);

static long long vmGMTOffset = 0;
static unsigned long long utcStartMicroseconds; /* for the ioMSecs clock. */

/* Compute the current VM time basis, the number of microseconds from 1901. */

static unsigned long long currentUTCMicroseconds(){
	struct timeval utcNow;

	gettimeofday(&utcNow,0);
	return ((utcNow.tv_sec * MicrosecondsPerSecond) + utcNow.tv_usec) + MicrosecondsFrom1901To1970;
}


EXPORT(long long) getVMGMTOffset(){
	ioUpdateVMTimezone();
	return vmGMTOffset;
}


void ioInitTime(void){
	ioUpdateVMTimezone();
	utcStartMicroseconds = currentUTCMicroseconds();
}

void ioSetHeartbeatMilliseconds(int ms){}

void ioInitHeartbeat() {}

unsigned volatile long long ioUTCMicrosecondsNow() { return currentUTCMicroseconds(); }
unsigned volatile long long ioUTCMicroseconds() { return ioUTCMicrosecondsNow(); }
unsigned long long ioUTCStartMicroseconds() { return utcStartMicroseconds; }

unsigned volatile long long ioLocalMicrosecondsNow() { return currentUTCMicroseconds() + vmGMTOffset; }

long ioMSecs() { return microToMilliseconds(currentUTCMicroseconds()); }
long ioMicroMSecs(void) { return microToMilliseconds(currentUTCMicroseconds());}

sqInt ioSecondsNow(void) { return ioLocalMicrosecondsNow() / MicrosecondsPerSecond; }
sqInt ioSeconds(void) { return ioSecondsNow(); }

sqInt ioUTCSecondsNow(void) { return currentUTCMicroseconds() / MicrosecondsPerSecond; }
sqInt ioUTCSeconds(void) { return ioUTCSecondsNow(); }

unsigned volatile long long ioLocalMicroseconds() { ioLocalMicrosecondsNow(); }
sqInt ioLocalSecondsOffset() { return vmGMTOffset / MicrosecondsPerSecond; }

#ifdef WIN32
void ioUpdateVMTimezone()
{
	__int64 utcNow, localNow;
	const __int64 TocksPerMicrosecond = 10;


	GetSystemTimeAsFileTime((FILETIME *)&utcNow);
	FileTimeToLocalFileTime((FILETIME *)&utcNow,(FILETIME *)&localNow);
	vmGMTOffset = (localNow - utcNow) / TocksPerMicrosecond;
}
#else
void ioUpdateVMTimezone() {
	time_t utctt;
	utctt = (currentUTCMicroseconds() - MicrosecondsFrom1901To1970)
				/ MicrosecondsPerSecond;
	vmGMTOffset = localtime(&utctt)->tm_gmtoff * MicrosecondsPerSecond;
}
#endif

sqLong
ioHighResClock(void)
{
  /* return the value of the high performance counter */
  sqLong value = 0;
#if defined(__GNUC__) && (defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(x86_64) || defined(__x86_64) || defined (__x86_64__))
    __asm__ __volatile__ ("rdtsc" : "=A"(value));
#elif defined(__arm__) && (defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_7A__))
	/* tpr - do nothing for now; needs input from eliot to decide further */
#else
//# error "no high res clock defined"
#endif
  return value;
}

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

void ioGetClockLogSizeUsecsIdxMsecsIdx(sqInt *runInNOutp, void **usecsp, sqInt *uip, void **msecsp, sqInt *mip){
	logClock = *runInNOutp;
	sqLowLevelMFence();
	*runInNOutp = LOGSIZE;
	*usecsp = useclog;
	*uip = ulogidx % LOGSIZE;
	*msecsp = mseclog;
	*mip = mlogidx % LOGSIZE;
}

unsigned long ioHeartbeatFrequency(int resetStats){
	return 0;
}

int ioHeartbeatMilliseconds() { return 0; }

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds){
    aioSleepForUsecs(microSeconds);

    ceCheckForInterrupts();
    return 0;
}

