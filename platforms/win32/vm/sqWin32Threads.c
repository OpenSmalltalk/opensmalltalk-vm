/****************************************************************************
*   PROJECT: Win32 thread support code for Cog & Stack VMs
*   FILE:    sqWin32Threads.c
*   CONTENT: 
*
*   AUTHOR:  Eliot Miranda
*   ADDRESS: 
*   EMAIL:   eliot@teleplace.com
*   RCSID:   $Id$
*
*****************************************************************************/

#include <stdlib.h>
#include <stdarg.h>
#ifdef __MINGW32__
# define _STRUCT_NAME(foo) foo
# include <basetyps.h>
#endif
#include <windef.h>
#include <wincon.h> /* damn right */
#include <winbase.h> /* damn right 2 */

#include "sq.h"
#include "sqAssert.h"

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

void
ioInitThreads()
{
	extern void ioInitExternalSemaphores(void);
	initThreadLocalThreadIndices();
	ioVMThread = ioCurrentOSThread();
	ioInitExternalSemaphores();
}

/* this for testing crash dumps */
static sqInt
indirect(long p)
{
	return p > 99
		? indirect(p - 100), indirect(p - 50) /* evade tail recursion opt */
		: *(sqInt *)p;
}


sqInt
crashInThisOrAnotherThread(sqInt inThisThread)
{
	if (inThisThread)
		return indirect(0);
	else {
		CreateThread(0, /* no security */
					 0, /* default stack size */
					 (LPTHREAD_START_ROUTINE)indirect,
					 (void *)300,
					 0, /* creation flags 0 => run immediately */
					 0  /* thread id; we don't use it */);
		Sleep(1000);
	}
	return 0;
}
