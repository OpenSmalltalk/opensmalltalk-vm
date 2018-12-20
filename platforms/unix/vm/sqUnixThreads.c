/****************************************************************************
*   PROJECT: Unix (pthreads) thread support code for Stack & Cog VM
*   FILE:    sqUnixThreads.c
*   CONTENT: 
*
*   AUTHOR:  Eliot Miranda
*   ADDRESS: 
*   EMAIL:   eliot@teleplace.com
*   RCSID:   $Id$
*
*   NOTES: See the comment of CogThreadManager in the VMMaker package for
*          overall design documentation.
*
*****************************************************************************/

#define ForCOGMTVMImplementation 1

#include "sq.h"

#if COGMTVM

#include <unistd.h>			/* for ioNumProcesors */
#include <sys/types.h>		/* for ioNumProcesors */
#include <sys/sysctl.h>		/* for ioNumProcesors */
#include <errno.h>
#include <pthread.h>

int
ioNewOSThread(void (*func)(void *), void *arg)
{
	pthread_t newThread;
	int err;

	if ((err = pthread_create(
				&newThread,				/* pthread_t *new_thread_ID */ 
				0,						/* const pthread_attr_t *attr */
				(void *(*)(void *))func,/* void * (*thread_execp)(void *) */
				(void *)arg				/* void *arg */))) {
		perror("pthread_create");
		return err;
	}
	return 0;
}

void
ioExitOSThread(pthread_t thread)
{
	if (thread == pthread_self())
		pthread_exit(0);
	error("not yet implemented");
}

int
ioNewOSSemaphore(sqOSSemaphore *sem)
{
	int err;

	sem->count = 0;
	return (err = pthread_cond_init(&sem->cond,0))
		|| (err = pthread_mutex_init(&sem->mutex,0))
		? err
		: 0;
}

#define DEBUG 1
#if DEBUG
# include "sqAtomicOps.h"
int thrlogidx = 0;
char *thrlog[THRLOGSZ];

void
dumpThreadLog()
{
	int f = thrlogidx,				/* first used entry if non-null */
		l = (f-1) & (THRLOGSZ-1),	/* last used entry */
		s = thrlog[f] ? f : 0;		/* start */

	if (!thrlog[s])
		return;

	do {
		printf(thrlog[s]);
		if (s == l) break;
		s = (s + 1) & (THRLOGSZ-1);
	}
	while (1);
}

extern pthread_key_t tltiIndex;
#endif
void
ioSignalOSSemaphore(sqOSSemaphore *sem)
{
#if DEBUG
	int tid = ioGetThreadLocalThreadIndex();
	int err;

	if ((err = pthread_mutex_lock(&sem->mutex)))
		THRLOG("%d !! SIGN pthread_mutex_lock 0x%p => %d\n", tid, sem, err);
	if (++sem->count <= 0) {
		THRLOG("%d pthread_cond_signal 0x%x\n", tid, sem);
		err = pthread_cond_signal(&sem->cond);
		THRLOG("%d pthread_cond_signal 0x%x => %d\n", tid, sem, err);
	}
	else
		THRLOG("%d ioSig 0x%x ++count = %d\n", tid, sem, sem->count);
	if ((err = pthread_mutex_unlock(&sem->mutex)))
		THRLOG("%d !!pthread_mutex_unlock 0x%p => %d\n", tid, sem, err);
#else
	(void)pthread_mutex_lock(&sem->mutex);
	if (++sem->count <= 0)
		(void)pthread_cond_signal(&sem->cond);
	(void)pthread_mutex_unlock(&sem->mutex);
#endif
}

void
ioWaitOnOSSemaphore(sqOSSemaphore *sem)
{
#if DEBUG
	int tid = ioGetThreadLocalThreadIndex();
	int err;

	if ((err = pthread_mutex_lock(&sem->mutex)))
		THRLOG("%d !! WAIT pthread_mutex_lock 0x%p => %d\n", tid, sem, err);
	if (--sem->count < 0) {
		THRLOG("%d pthread_cond_wait 0x%x\n", tid, sem);
		err = pthread_cond_wait(&sem->cond, &sem->mutex);
		THRLOG("%d proceeding 0x%x (pcw err %d)\n", tid, sem, err);
	}
	else
		THRLOG("%d ioWait 0x%x --count = %d\n", tid, sem, sem->count);
	if ((err = pthread_mutex_unlock(&sem->mutex)))
		THRLOG("%d !! WAIT pthread_mutex_unlock 0x%p => %d\n", tid, sem, err);
#else
	(void)pthread_mutex_lock(&sem->mutex);
	if (--sem->count < 0)
		(void)pthread_cond_wait(&sem->cond, &sem->mutex);
	(void)pthread_mutex_unlock(&sem->mutex);
#endif
}


pthread_key_t tltiIndex; /* clients see this as a const read-only export */

static void
initThreadLocalThreadIndices(void)
{
	int err = pthread_key_create(&tltiIndex,0);
	if (err)
		error("pthread_key_create");
}

/*
 * ioGetThreadLocalThreadIndex & ioSetThreadLocalThreadIndex are defined in
 * sqPlatformSpecific.h.
 */

/* ioOSThreadIsAlive is defined in sqPlatformSpecific.h.
 */

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
	extern void warning(char *);
	warning("could not determine number of processors; assuming 1");
	return 1;
# endif
}
#else /* COGMTVM */
/* This is for sqVirtualMachine.h's default ownVM implementation. */
sqInt
amInVMThread() { return ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread()); }
#endif /* COGMTVM */

void
ioInitThreads()
{
	extern void ioInitExternalSemaphores(void);
#if !COGMTVM
	/* Set the current VM thread.  If the main thread isn't the VM thread then
	 * when that thread is spawned it can reassign ioVMThread.
	 */
	ioVMThread = ioCurrentOSThread();
#endif
#if COGMTVM
	initThreadLocalThreadIndices();
#endif
	ioInitExternalSemaphores();
}

/* this for testing crash dumps */
static sqInt
indirect(long p)
{
	if ((p & 2))
		error("crashInThisOrAnotherThread");
	return p > 99
		? indirect(p - 100), indirect(p - 50) /* evade tail recursion opt */
		: *(sqInt *)p;
}

/* bit 0 = thread to crash in; 1 => this thread
 * bit 1 = crash method; 0 => indirect through null pointer; 1 => call exit
 */
sqInt
crashInThisOrAnotherThread(sqInt flags)
{
	if ((flags & 1)) {
		if (!(flags & 2))
			return indirect(flags & ~1);
		error("crashInThisOrAnotherThread");
		return 0;
	}
	else {
		pthread_t newThread;

		(void)pthread_create(
				&newThread,					/* pthread_t *new_thread_ID */ 
				0,							/* const pthread_attr_t *attr */
				(void *(*)(void *))indirect,/* void * (*thread_execp)(void *) */
				(void *)300					/* void *arg */);
		sleep(1);
	}
	return 0;
}
