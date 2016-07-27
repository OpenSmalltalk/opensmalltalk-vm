/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Threads.c
*   CONTENT: Win32 thread support code for Cog & Stack VMs
*
*   AUTHOR:  Eliot Miranda
*
*   NOTES: See the comment of CogThreadManager in the VMMaker package for
*          overall design documentation.
*
*****************************************************************************/

#include <stdlib.h>
#include <stdarg.h>
#include <limits.h>
#include <windows.h>

#define ForCOGMTVMImplementation 1

#include "sq.h"
#include "sqAssert.h"
#include "sqWin32.h" /* for printLastError */

/*
 * A note on thread handles and Ids.  The only globally shared and globally
 * unique handle/id Win32 provides for threads is the value answered by the
 * last argument of CreateThread and GetCurrentThreadId, but this is not a
 * handle.  GetCurrentThread answers a constant that means "this thread".
 * The handle returned by CreateThread is not directly accessible to the
 * thread that has been created, and does not seem to work reliably when
 * used as the argument of GetExitCodeThread.
 *
 * Therefore we need to create a process-wide handle.  We do so via
 * DuplicateHandle because OpenThread seems to answer a handle that again
 * isn't reliable with GetExitCodeThread.  But DuplicateHandle must be used
 * with the pseudo-handle returned by GetCurrentThread, and hence we need a
 * wrapper around the thread creation function that duplicates the handle
 * before calling the thread start function.  (Sigh...)
 */

DWORD tlthIndex = (DWORD)-1; /* process-wide thread handle thread-local key */
DWORD tltiIndex = (DWORD)-1; /* thread index thread-local key */

static void
initThreadLocalThreadIndices(void)
{
	if (tlthIndex == (DWORD)-1) {
		tlthIndex = TlsAlloc();
		tltiIndex = TlsAlloc();
		if (tlthIndex == TLS_OUT_OF_INDEXES
		 || tltiIndex == TLS_OUT_OF_INDEXES) { /* illiterate swine! */
			printLastError(TEXT("ThreadLocalThreadIndices TlsAlloc failed"));
			exit(1);
		}
	}
}

/*
 * ioGetThreadLocalThreadIndex & ioSetThreadLocalThreadIndex are defined in
 * sqPlatformSpecific.h.
 */

static DWORD
duplicateAndSetThreadHandleForCurrentThread(void)
{
	HANDLE threadHandle;
	DWORD lastError;

	if (DuplicateHandle(GetCurrentProcess(), // source process handle
						GetCurrentThread(),  // source handle (N.B. pseudo)
						GetCurrentProcess(), // target process handle
						&threadHandle,		 // out param
						0,// desired access, ignored if DUPLICATE_SAME_ACCESS
						TRUE,				 // handle is inheritable
						DUPLICATE_SAME_ACCESS)) { // options
		assert(threadHandle);
		TlsSetValue(tlthIndex,threadHandle);
		return 0;
	}
	lastError = GetLastError();
	printLastError("DuplicateHandle");
	return lastError;
}

/*
 * Re TlsGetValue.  From msdn:
 * "The data stored in a TLS slot can have a value of 0 because it still has its
 *  initial value or because the thread called the TlsSetValue function with 0.
 *  Therefore, if the return value is 0, you must check whether GetLastError
 *  returns ERROR_SUCCESS before determining that the function has failed.
 *  If GetLastError returns ERROR_SUCCESS, then the function has succeeded and
 *  the data stored in the TLS slot is 0. Otherwise, the function has failed."
 *
 * But since we never store a null thread handle we can omit this check.
 */
HANDLE
ioCurrentOSThread()
{
	HANDLE threadHandle = TlsGetValue(tlthIndex);

	if (!threadHandle)
		(void)duplicateAndSetThreadHandleForCurrentThread();

	assert(TlsGetValue(tlthIndex));
	return TlsGetValue(tlthIndex);
}

#if COGMTVM
typedef struct {
			void (*func)(void *);
			void *arg;
		} InitTuple;

static void *
angel(void *arg)
{
	InitTuple it = *(InitTuple *)arg;
	DWORD err = duplicateAndSetThreadHandleForCurrentThread();

	free(arg);
	if (err)
		ExitThread(err);
	it.func(it.arg);
	return 0;
}

int
ioNewOSThread(void (*func)(void *), void *arg)
{
	HANDLE newThread;
	InitTuple *it = malloc(sizeof(InitTuple));

	if (!it)
		return ERROR_OUTOFMEMORY;

	it->func = func;
	it->arg = arg;
	newThread = CreateThread(0, /* no security */
							 0, /* default stack size */
							 (LPTHREAD_START_ROUTINE)angel,
							 (void *)it,
							 STACK_SIZE_PARAM_IS_A_RESERVATION, /* creation flags 0 => run immediately */
							 0  /* thread id; we don't use it */);

	if (!newThread) {
		int err = GetLastError();
		return err == 0 ? -1 : err;
	}
	/* we need to close this handle so that closing the duplicated handle will
	 * actually release resources.  Keeping this handle open will prevent that.
	 */
	(void)CloseHandle(newThread);
	return 0;
}

int
ioOSThreadIsAlive(HANDLE thread)
{
	DWORD result;

    return GetExitCodeThread(thread, &result)
		? FALSE
    	: GetLastError() == STILL_ACTIVE;
}

void
ioExitOSThread(HANDLE thread)
{
	if (thread == ioCurrentOSThread()) {
		ioReleaseOSThreadState(thread);
		ExitThread(0);
		/*NOTREACHED*/
	}
	TerminateThread(thread, 0);
	ioReleaseOSThreadState(thread);
}

void
ioReleaseOSThreadState(HANDLE thread)
{
	(void)CloseHandle(thread);
}

int
ioNumProcessors(void)
{
	char *nprocs = getenv("NUMBER_OF_PROCESSORS");

	return nprocs ? atoi(nprocs) : 1;
}

int
ioNewOSSemaphore(sqOSSemaphore *sem)
{
	*sem = CreateSemaphore(	0, /* don't need no stinkin' security */
							0, /* initial signal count */
							LONG_MAX, /* sky's the limit */
							0 /* don't need no stinkin' name */);
	if (!*sem)
		printLastError("ioNewOSSemaphore CreateSemaphore");
	return *sem ? 0 : GetLastError();
}

void
ioDestroyOSSemaphore(sqOSSemaphore *sem) { CloseHandle(*sem); }

void
ioSignalOSSemaphore(sqOSSemaphore *sem)
{
	if (!ReleaseSemaphore(*sem, 1, 0))
		abortMessage(TEXT("Fatal: ReleaseMutex(*sem) %ld"),
					 GetLastError());
}

void
ioWaitOnOSSemaphore(sqOSSemaphore *sem)
{
	if (WaitForSingleObject(*sem, INFINITE) == WAIT_FAILED)
		abortMessage(TEXT("Fatal: WaitForSingleObject(*sem) %ld"),
					 GetLastError());
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
	initThreadLocalThreadIndices();
#if !COGMTVM
	ioVMThread = ioCurrentOSThread();
#endif
	ioInitExternalSemaphores();
}

/* this for testing crash dumps */
static sqInt
indirect(sqIntptr_t p)
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
		CreateThread(0, /* no security */
					 0, /* default stack size */
					 (LPTHREAD_START_ROUTINE)indirect,
					 (void *)300,
					 STACK_SIZE_PARAM_IS_A_RESERVATION, /* creation flags 0 => run immediately */
					 0  /* thread id; we don't use it */);
		Sleep(1000);
	}
	return 0;
}
