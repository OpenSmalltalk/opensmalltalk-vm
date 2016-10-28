/****************************************************************************
*   PROJECT: Unix (pthread/nanosleep/sigaction/SIGPROF) profiling logic for
*			 statistical profiling of the VM
*   FILE:    sqUnixVMProfile.c
*   CONTENT: 
*
*   AUTHOR:  Eliot Miranda
*   ADDRESS: 
*   EMAIL:   eliot@qwaq.com
*   RCSID:   $Id$
*
*   NOTES: 
*  August 5th, 2008, EEM wrote pc sampling code
*
*****************************************************************************/
 
#if NO_VM_PROFILE
#include "sq.h"

void 
ioNewProfileStatus(sqInt *running, long *buffersize)
{
	if (running)
		*running = 0;
	if (buffersize)
		*buffersize = 0;
}

long
ioNewProfileSamplesInto(void *sampleBuffer)
{
	return 0;
}

long
ioControlNewProfile(int on, unsigned long buffer_size)
{
	return 0;
}

void
ioClearProfile(void)
{
}
#else /* NO_VM_PROFILE */
#include <pthread.h>
#if __linux__
# if !defined(__USE_GNU)
#	define UNDEF__USE_GNU 1
#	define __USE_GNU /* to get register defines in sys/ucontext.h */
# endif
#endif
#ifdef __OpenBSD__
#include <sys/signal.h>
#else
#include <sys/ucontext.h>
#endif
#if  __linux__ && UNDEF__USE_GNU
# undef __USE_GNU
#endif
#include <signal.h>
#include <sys/time.h>
#if __APPLE__ && __MACH__ /* Mac OS X */
# include <mach-o/getsect.h>
extern unsigned long _start;
#elif defined(__linux__)
extern unsigned long _start;
extern unsigned long _etext;
#endif

#include <errno.h>

#include "sq.h"

/*
 * The pc collection scheme is an event buffer into which are written pcs.  The
 * image then builds up the histogram from the samples.  8 meg of buffer is 23
 * minutes of 32-bit pc samples at 1.5KHz, plenty for practical profiling.
 */

#if LLP64
typedef unsigned long long pctype;
#else
typedef unsigned long pctype;
#endif

static void
bail_out(int err, char *err_string)
{
	errno = err;
	perror(err_string);
	exit(1);
}

typedef enum { dead, nascent, quiescent, active } machine_state;
machine_state profileState = dead,
			  nextState = dead;

#define PROFILE_USECS 666 /* chosen to be out of phase with the delay resolution of 1000 */
static volatile struct timespec proftime = { 0, PROFILE_USECS * 1000};

static int					profThreadPolicy;
static struct sched_param	profThreadPriority;
static pthread_t mainThread;

static void *
profileStateMachine(void *ignored)
{
	int er;
	if ((er = pthread_setschedparam(pthread_self(),
									profThreadPolicy,
									&profThreadPriority)))
		bail_out(er,"pthread_setschedparam failed");

	profileState = quiescent;
	while (profileState != dead) {
		struct timespec naptime;
		naptime = proftime;
		while (nanosleep(&naptime, &naptime) == -1) /* repeat */;
		if (profileState == active)
			pthread_kill(mainThread, SIGPROF);
		profileState = nextState;
	}
	return 0;
}

static void
setState(machine_state desiredState)
{
	struct timespec halfAMo;

	if (profileState == desiredState)
		return;
	nextState = desiredState;
	halfAMo.tv_sec  = 0;
	halfAMo.tv_nsec = 1000 * 100;
	while (profileState != desiredState)
		nanosleep(&halfAMo, 0);
}

/*
 * Example of 2meg buffer (512k samples) gives nearly 6 minutes of profile
 * (nearly 3 minutes in 64-bits).
 *
 * 2 * 1024 * 1024  = 512 * 1024 pcs (each pc 4 bytes)
 * Sampling frequency is 1000000 usecs / 666 usecs = 1501 Hz (1501 pcs / sec)
 * 512 * 1024 / 1501 = 349 seconds = 5.8 minutes
 */

static pctype *pc_buffer;
static long pc_buffer_index;
static long pc_buffer_size;
static long pc_buffer_wrapped;

static void
pcbufferSIGPROFhandler(int sig, siginfo_t *info, ucontext_t *uap)
{
#if __DARWIN_UNIX03 && __APPLE__ && __MACH__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext->__ss.__eip
#elif __APPLE__ && __MACH__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext->ss.eip
#elif __APPLE__ && __MACH__ && __ppc__
# define _PC_IN_UCONTEXT uc_mcontext->ss.srr0
#elif __DARWIN_UNIX03 && __APPLE__ && __MACH__ && __x86_64__
# define _PC_IN_UCONTEXT uc_mcontext->__ss.__rip
#elif __APPLE__ && __MACH__ && __x86_64__
# define _PC_IN_UCONTEXT uc_mcontext->ss.rip
#elif __linux__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_EIP]
#elif __linux__ && __x86_64__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_RIP]
#elif __linux__ && __arm__
# define _PC_IN_UCONTEXT uc_mcontext.arm_pc
#elif __FreeBSD__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.mc_eip
#elif __OpenBSD__
# define _PC_IN_UCONTEXT sc_rip
#else
# error need to implement extracting pc from a ucontext_t on this system
#endif

	pc_buffer[pc_buffer_index] = uap->_PC_IN_UCONTEXT;
	if (++pc_buffer_index >= pc_buffer_size) {
		pc_buffer_index = 0;
		pc_buffer_wrapped = 1;
	}
}


static void
initProfileThread()
{
	int er;
	struct sigaction sigprof_handler_action;
	pthread_t careLess;

	sigprof_handler_action.sa_sigaction = pcbufferSIGPROFhandler;
	sigprof_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
	sigemptyset(&sigprof_handler_action.sa_mask);
	(void)sigaction(SIGPROF, &sigprof_handler_action, 0);

	mainThread = pthread_self();
	if ((er = pthread_getschedparam(pthread_self(),
									&profThreadPolicy,
									&profThreadPriority)))
		bail_out(er,"pthread_getschedparam failed");
	/* add 2 to priority to be above poll heartbeat thread, which we
	 * want to profile.
	 */
	profThreadPriority.sched_priority += 2;
	/* If the priority isn't appropriate for the policy (typically SCHED_OTHER)
	 * then change policy.
	 */
	if (sched_get_priority_max(profThreadPolicy) < profThreadPriority.sched_priority)
		profThreadPolicy = SCHED_FIFO;
	profileState = nascent;
	if ((er= pthread_create(&careLess,
							(const pthread_attr_t *)0,
							profileStateMachine,
							(void *)0)))
		bail_out(er,"profile thread creation failed");
	setState(quiescent);
}

long
ioControlNewProfile(int on, unsigned long buffer_size)
{
	if (buffer_size
	 && pc_buffer_size < buffer_size) {
		if (profileState == active)
			setState(quiescent);
		if (pc_buffer)
			free(pc_buffer);
		pc_buffer = malloc(buffer_size * sizeof(pctype));
		pc_buffer_index = 0;
		pc_buffer_size = buffer_size;
		pc_buffer_wrapped = 0;
	}
	if (profileState == dead)
		initProfileThread();
   	setState(on ? active : quiescent);
	return pc_buffer_wrapped ? pc_buffer_size : pc_buffer_index;
}

void 
ioNewProfileStatus(sqInt *running, long *buffersize)
{
	if (running)
		*running = profileState == active;
	if (buffersize)
		*buffersize = pc_buffer_size;
}

long
ioNewProfileSamplesInto(void *sampleBuffer)
{
	if (!pc_buffer_wrapped) {
		memcpy(sampleBuffer,pc_buffer,pc_buffer_index * sizeof(pctype));
		return pc_buffer_index;
	}
	memcpy(sampleBuffer,
		   pc_buffer + pc_buffer_index,
		   (pc_buffer_size - pc_buffer_index) * sizeof(pctype));
	memcpy((pctype *)sampleBuffer + (pc_buffer_size - pc_buffer_index),
		   pc_buffer,
		   pc_buffer_index * sizeof(pctype));
	return pc_buffer_size;
}

void
ioClearProfile(void)
{
	pc_buffer_index = pc_buffer_wrapped = 0;
}
#endif /* NO_VM_PROFILE */
