/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32VMProfile.c
*   CONTENT: Win32 (CreateThread/WaitSingleObject/SetThreadAffinityMask)
*			 profiling logic for statistical profiling of the VM
*
*   AUTHOR:  Eliot Miranda
*
*   NOTES: 
*  August 15th, 2008, EEM wrote pc sampling code
*
*****************************************************************************/
 
#include <windows.h>
/* MSVC v6 == 1200 */
#if defined(_MSC_VER) && _MSC_VER > 0 && _MSC_VER < 1300
typedef DWORD *DWORD_PTR; /* ULONGLONG on 64-bit systems */
#endif
#include "sq.h"

#define HISTOGRAM 1
#define PCBUFFER 2

#define SCHEME PCBUFFER

/*
 * There are two schemes here.  HISTOGRAM is a pair of histograms, one for
 * the VM and one for the entire address space.  The EAS histogram necessarily
 * has poor resolution. PCBUFFER, the other scheme is an event buffer into which
 * are written pcs.  The image then builds up the histogram from the samples.
 * 8 meg of buffer is 23 minutes of 32-bit pc samples at 1.5KHz, so one gets
 * much better resolution throughout the adress space using less memory with
 * the buffer technique.
 */

typedef unsigned long pctype;

typedef enum { dead, nascent, quiescent, active } machine_state;
machine_state profileState = nascent;

static HANDLE    profileSemaphore;
static HANDLE    profileThread;
static HANDLE    VMThread;
static DWORD     profileMilliseconds = 1;
static DWORD_PTR defaultAffinity;

#if SCHEME == HISTOGRAM
/*
 * In this scheme we have to determine the range of the VM so we can have a
 * high-resolution histogram for the VM and a low presolution one for the
 * entire address space.
 */

extern  void *btext(void);
extern  void *etext(void);

void
ioProfileTextRange(void **startpc, void **endpc)
{
	*startpc = btext;
	*endpc   = etext;
}

/*
 * We can get 16k resolution of the entire address space for 1Meg of profile.
 * Each bin is 4 bytes on 32-bit machines, so
 *	(2 raisedTo: 32 - (16384 log: 2) asInteger) * 4 1048576
 */
#define EAS_SCALE 14 /* (16384 log: 2) asInteger */
#define EAS_BYTES (sizeof(*eas_bins) * (1 << (32 - EAS_SCALE)))
static unsigned long *eas_bins; /* eas = entire address space */
static unsigned long *vm_bins;
static unsigned long first_vm_pc;
static unsigned long limit_vm_pc;
#define VM_BYTES(firstpc,limitpc) (sizeof(*vm_bins) * ((limitpc) - (firstpc)))

/*
 * This is the profiling loop.  It spins waiting for a short delay and then
 * sampling the pc of the main thread.  We can assume that GetThreadContext
 * will work if the profile thread is a higher priority than the profiled
 * thread and they are running on the same processor.  We use (thanks Andreas!)
 * SetThreadAffinityMask to force the two threads to share a processor. Other-
 * -wise we would have to use SuspendThread/resumeThread on machines with more
 * than one hyper-thread/core/processor.  (See initProfile & ioControlProfile)
 */
static DWORD WINAPI
profileStateMachine(void *ignored)
{
	profileState = quiescent;
	while (profileState != dead) {
		DWORD res = WaitForSingleObject(profileSemaphore,
										profileState == active
											? profileMilliseconds
											: INFINITE);
		if (res == WAIT_TIMEOUT
		 && profileState == active) {
			CONTEXT VMContext;
			unsigned long pc;
			VMContext.ContextFlags = CONTEXT_CONTROL | THREAD_GET_CONTEXT;
			GetThreadContext(VMThread, &VMContext);
			pc = VMContext.Eip;
			if (pc >= first_vm_pc && pc < limit_vm_pc)
				++vm_bins[pc - first_vm_pc];
			else
				++eas_bins[pc >> EAS_SCALE];
		}
		else if ((long)res < 0)
			abortMessage(TEXT("WaitForSingleObject(profileSemaphore... error %ld"), GetLastError());
	}
	return 0;
}

static void
initProfile(void)
{
	DWORD uselessThreadId;
	DWORD_PTR uselessSystemAffinity;

	ioProfileTextRange((void **)&first_vm_pc, (void **)&limit_vm_pc);
	vm_bins = malloc(VM_BYTES(first_vm_pc,limit_vm_pc));
	eas_bins = malloc(EAS_BYTES);

	if (!GetProcessAffinityMask(GetCurrentProcess(),
								&defaultAffinity,
								&uselessSystemAffinity))
		abortMessage(TEXT("Fatal: GetProcessAffinityMask %ld"), GetLastError());

    DuplicateHandle(GetCurrentProcess(),
                    GetCurrentThread(),
                    GetCurrentProcess(),
                    &VMThread,
                    0,
                    TRUE,
                    DUPLICATE_SAME_ACCESS);
	profileSemaphore = CreateSemaphore(	NULL,	/*no security*/
										0,		/*no initial signals*/
										65535,  /*no limit on num signals*/
										NULL	/*anonymous*/);
	profileThread = CreateThread(0,   /* default security attributes (none) */
								2048, /* thread stack bytes */
								profileStateMachine,
								0,	/* profileStateMachine argument */
								0 | STACK_SIZE_PARAM_IS_A_RESERVATION,	/* creation flags, 0 => run immediately, SSPIAR implies don't commit memory to stack */
								&uselessThreadId);
	if (!profileThread
	 || !SetThreadPriority(profileThread, PROF_THREAD_PRIORITY))
		abortMessage(TEXT("Fatal: profile thread init failure %ld"), GetLastError());

	while (profileState == nascent)
		WaitForSingleObject(&profileSemaphore, 1);
}

void
ioControlProfile(int on,
					void **vmHistogramPtr, long *vmHistogramBins,
					void **easHistogramPtr, long *easHistogramBins)
{
	machine_state desiredState = on ? active : quiescent;
	DWORD_PTR     desiredAffinity = on ? 1 : defaultAffinity;

	ioProfileStatus(0, 0, 0,
					vmHistogramPtr, vmHistogramBins,
					easHistogramPtr, easHistogramBins);

	if (profileState == desiredState)
		return;
	if (!SetThreadAffinityMask(profileThread, desiredAffinity)
	 || !SetThreadAffinityMask(GetCurrentThread(), desiredAffinity))
		abortMessage(TEXT("Fatal: SetThreadAffinityMask %ld"), GetLastError());
    profileState = desiredState;
	if (!ReleaseSemaphore(profileSemaphore,1 /* 1 signal */,NULL))
		abortMessage(TEXT("ReleaseSemaphore(profileSemaphore... error"));
}

void 
ioProfileStatus(sqInt *running, void **exestartpc, void **exelimitpc,
				void **vmHistogramPtr, long *vmHistogramBins,
				void **easHistogramPtr, long *easHistogramBins)
{
	if (!vm_bins)
		initProfile();
	if (running)
		*running = profileState == active;
	if (exestartpc)
		*exestartpc = first_vm_pc;
	if (exelimitpc)
		*exelimitpc = limit_vm_pc;
	if (vmHistogramBins)
		*vmHistogramBins = VM_BYTES(first_vm_pc,limit_vm_pc) / sizeof(*vm_bins);
	if (vmHistogramPtr)
		*vmHistogramPtr = vm_bins;
	if (easHistogramBins)
		*easHistogramBins = EAS_BYTES / sizeof(*eas_bins);
	if (easHistogramPtr)
		*easHistogramPtr = eas_bins;
}

void
ioClearProfile(void)
{
	if (vm_bins) {
		memset(vm_bins, 0, VM_BYTES(first_vm_pc,limit_vm_pc));
		memset(eas_bins, 0, EAS_BYTES);
	}
}
#elif SCHEME == PCBUFFER

/*
 * Example of 2meg buffer (512k samples) gives nearly 6 minutes of profile.
 *
 * 2 * 1024 * 1024  = 512 * 1024 pcs (each pc 4 bytes)
 * Sampling frequency is 1000000 usecs / 666 usecs = 1501 Hz (1501 pcs / sec)
 * 512 * 1024 / 1501 = 349 seconds = 5.8 minutes
 */

static pctype *pc_buffer;
static long pc_buffer_index;
static long pc_buffer_size;
static long pc_buffer_wrapped;

/*
 * This is the profiling loop.  It spins waiting for a short delay and then
 * sampling the pc of the main thread.  We can assume that GetThreadContext
 * will work if the profile thread is a higher priority than the profiled
 * thread and they are running on the same processor.  We use (thanks Andreas!)
 * SetThreadAffinityMask to force the two threads to share a processor. Other-
 * -wise we would have to use SuspendThread/resumeThread on machines with more
 * than one hyper-thread/core/processor.  (See initProfile & ioControlProfile)
 */
static DWORD WINAPI
profileStateMachine(void *ignored)
{
	profileState = quiescent;
	while (profileState != dead) {
		DWORD res = WaitForSingleObject(profileSemaphore,
										profileState == active
											? profileMilliseconds
											: INFINITE);
		if (res == WAIT_TIMEOUT
		 && profileState == active) {
			CONTEXT VMContext;
			pctype pc;
			VMContext.ContextFlags = CONTEXT_CONTROL | THREAD_GET_CONTEXT;
			GetThreadContext(VMThread, &VMContext);
#if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
			pc = VMContext.Eip;
#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
			pc = VMContext.Rip;
#else
#error "unknown architecture, cannot pick program counter"
#endif
			pc_buffer[pc_buffer_index] = pc;
			if (++pc_buffer_index >= pc_buffer_size) {
				pc_buffer_index = 0;
				pc_buffer_wrapped = 1;
			}
		}
		else if ((long)res < 0)
			abortMessage(TEXT("WaitForSingleObject(profileSemaphore... error %ld"), GetLastError());
	}
	return 0;
}


static void
initProfileThread()
{
	DWORD uselessThreadId;
	DWORD_PTR uselessSystemAffinity;

	if (!GetProcessAffinityMask(GetCurrentProcess(),
								&defaultAffinity,
								&uselessSystemAffinity))
		abortMessage(TEXT("Fatal: GetProcessAffinityMask %ld"), GetLastError());

    DuplicateHandle(GetCurrentProcess(),
                    GetCurrentThread(),
                    GetCurrentProcess(),
                    &VMThread,
                    0,
                    TRUE,
                    DUPLICATE_SAME_ACCESS);
	profileSemaphore = CreateSemaphore(	NULL,	/*no security*/
										0,		/*no initial signals*/
										65535,  /*no limit on num signals*/
										NULL	/*anonymous*/);
	profileThread = CreateThread(0,   /* default security attributes (none) */
								2048, /* thread stack bytes */
								profileStateMachine,
								0,	/* profileStateMachine argument */
								0 | STACK_SIZE_PARAM_IS_A_RESERVATION,	/* creation flags, 0 => run immediately, SSPIAR implies don't commit memory to stack */
								&uselessThreadId);
	if (!profileThread
	 || !SetThreadPriority(profileThread, PROF_THREAD_PRIORITY))
		abortMessage(TEXT("Fatal: profile thread init failure %ld"), GetLastError());

	while (profileState == nascent)
		WaitForSingleObject(&profileSemaphore, 1);
}

static void
setState(machine_state desiredState)
{
    profileState = desiredState;
	if (!ReleaseSemaphore(profileSemaphore,1 /* 1 signal */,NULL))
		abortMessage(TEXT("ReleaseSemaphore(profileSemaphore... error"));
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
	if (profileState == nascent)
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
#endif /* SCHEME == HISTOGRAM elif SCHEME == PCBUFFER */
