/* sqExternalSemaphores.c
 *	Cross-platform thread-safe external semaphore signalling.
 *
 *	Authors: Eliot Miranda & Brad Fowlow
 *
 *	Copyright (c) 2013 3D Immersive Collaboration Consulting, LLC.
 *
 *	All rights reserved.
 *   
 *   This file is part of Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

#include "sq.h"
#include "sqAssert.h"
#include "sqAtomicOps.h"
#include "sqMemoryFence.h"

/* This implements "lock-free" signalling of external semaphores where there is
 * no lock between the signal responder (the VM) and signal requestors, but
 * there may be spin-locking between signal requestors, depending on the implem-
 * entation of atomicAddConst.
 *
 * Freedom from locks is very helpful in making the QAudioPlugin function on
 * linux, where the absence of thread priorities for non-setuid programs means
 * we cannot run the QAudioPlugin's ticker in a separate thread and must instead
 * derive it from the interval-timer based signal-driven (software interrupt)
 * heartbeat.  If the external semaphore state is locked while the VM is
 * responding to external semaphore signal requests and the heartbeat interrupts
 * causing a locking request for an external semaphore signal request then the
 * system will deadlock, since the interrupt occurs in the VM thread.
 *
 * Lock freedom is achieved by having an array of request counters, and an array
 * of response counters, one per external semaphore index.  To request a signal
 * the requests are locked and the relevant request is incremented.  To respond
 * to a request the VM increments the corresponding response until it matches
 * the request, signalling the associated semaphore on each increment.
 */

#if !COGMTVM
sqOSThread ioVMThread; /* initialized in the various <plat>/vm/sqFooMain.c */
#endif
extern void forceInterruptCheck(void);
extern sqInt doSignalSemaphoreWithIndex(sqInt semaIndex);

/* Use 16-bit counters if possible, otherwise 32-bit */
typedef struct {
# if ATOMICADD16
		short requests;
		short responses;
# else
		int requests;
		int responses;
# endif
	} SignalRequest;

static SignalRequest *signalRequests = 0;
static int numSignalRequests = 0;
static volatile sqInt checkSignalRequests;

/* The tides define the minimum range of indices into signalRequests that the
 * VM needs to scan.  With potentially thousands of indices to scan this can
 * save significant lengths of time.
 */
static volatile int tideLock = 0;
static volatile int useTideA = 1;
static volatile sqInt lowTideA = (usqInt)-1 >> 1, highTideA = -1;
static volatile sqInt lowTideB = (usqInt)-1 >> 1, highTideB = -1;

int
ioGetMaxExtSemTableSize(void) { return numSignalRequests; }

/* Setting this at any time other than start-up can potentially lose requests.
 * i.e. during the realloc new storage is allocated, the old contents are copied
 * and then pointersd are switched.  Requests occurring during copying won't
 * be seen if they occur to indices already copied.
 * We could make this safer in the linux case by disabling interrupts, but
 * there is little point.  The intended use is to set the table to some adequate
 * maximum at start-up and avoid locking altogether.
 */
void
ioSetMaxExtSemTableSize(int n)
{
#if COGMTVM
  /* initialization is a little different in MT. Hack around assert for now */
  if (getVMOSThread())
#endif
	if (numSignalRequests)
		assert(ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread()));
	if (numSignalRequests < n) {
		extern sqInt highBit(sqInt);
		int sz = 1 << highBit(n-1);
		assert(sz >= n);
		signalRequests = realloc(signalRequests, sz * sizeof(SignalRequest));
		memset(signalRequests + numSignalRequests,
				0,
				(sz - numSignalRequests) * sizeof(SignalRequest));
		numSignalRequests = sz;
	}
}

void
ioInitExternalSemaphores(void)
{
	ioSetMaxExtSemTableSize(INITIAL_EXT_SEM_TABLE_SIZE);
}

/* Signal the external semaphore with the given index.  Answer non-zero on
 * success, zero otherwise.  This function is (should be) thread-safe;
 * multiple threads may attempt to signal the same semaphore without error.
 * An index of zero should be and is silently ignored.
 */
sqInt
signalSemaphoreWithIndex(sqInt index)
{
	int i = index - 1;
	int v;

	/* An index of zero should be and is silently ignored. */
	assert(index >= 0 && index <= numSignalRequests);

	if ((unsigned)i >= numSignalRequests)
		return 0;

	sqLowLevelMFence();
	sqAtomicAddConst(signalRequests[i].requests,1);
	if (useTideA) {
		/* atomic if (lowTideA > i) lowTideA = i; */
		while ((v = lowTideA) > i) {
			sqLowLevelMFence();
			sqCompareAndSwap(lowTideA, v, i);
		}
		/* atomic if (highTideA < i) highTideA = i; */
		while ((v = highTideA) < i) {
			sqLowLevelMFence();
			sqCompareAndSwap(highTideA, v, i);
		}
	}
	else {
		/* atomic if (lowTideB > i) lowTideB = i; */
		while ((v = lowTideB) > i) {
			sqLowLevelMFence();
			sqCompareAndSwap(lowTideB, v, i);
		}
		/* atomic if (highTideB < i) highTideB = i; */
		while ((v = highTideB) < i) {
			sqLowLevelMFence();
			sqCompareAndSwap(highTideB, v, i);
		}
	}

	checkSignalRequests = 1;

	forceInterruptCheck();
	return 1;
}

/* Signal any external semaphores for which signal requests exist.
 * Answer whether a context switch occurred.
 * Note we no longer ensure the lock table has at least minTableSize elements.
 * Instead its size is settable at startup from a value in the image header via
 * ioSetMaxExtSemTableSize.  This avoids locks on the table while it grows
 * (although a lock-free implementation is possible, if tricky).  So for the
 * moment externalSemaphoreTableSize is not used.
 */
sqInt
doSignalExternalSemaphores(int externalSemaphoreTableSize)
{
	int i, switched;

	if (!checkSignalRequests)
		return 0;

	switched = 0;
	checkSignalRequests = 0;

	if (useTideA) {
		useTideA = 0;
		sqLowLevelMFence();
		/* doing this here saves a bounds check in doSignalSemaphoreWithIndex */
		if (highTideA >= externalSemaphoreTableSize)
			highTideA = externalSemaphoreTableSize - 1;
		for (i = lowTideA; i <= highTideA; i++)
			while (signalRequests[i].responses != signalRequests[i].requests) {
				if (doSignalSemaphoreWithIndex(i+1))
					switched = 1;
				++signalRequests[i].responses;
			}
		lowTideA = (unsigned long)-1 >> 1, highTideA = -1;
	}
	else {
		useTideA = 1;
		sqLowLevelMFence();
		/* doing this here saves a bounds check in doSignalSemaphoreWithIndex */
		if (highTideB >= externalSemaphoreTableSize)
			highTideB = externalSemaphoreTableSize - 1;
		for (i = lowTideB; i <= highTideB; i++)
			while (signalRequests[i].responses != signalRequests[i].requests) {
				if (doSignalSemaphoreWithIndex(i+1))
					switched = 1;
				++signalRequests[i].responses;
			}
		lowTideB = (unsigned long)-1 >> 1, highTideB = -1;
	}

	/* If a signal came in while processing, check for signals again soon.
	 */
	sqLowLevelMFence();
	if (checkSignalRequests)
		forceInterruptCheck();

	return switched;
}

#if FOR_SQUEAK_VM_TESTS
/* see e.g. tests/sqExternalSemaphores/unixmain.c */
int
allRequestsAreAnswered(int externalSemaphoreTableSize)
{
	long i;
	for (i = 1; i < externalSemaphoreTableSize; i++)
		if (signalRequests[i].responses != signalRequests[i].requests) {
			printf("signalRequests[%ld] requests %d responses %d\n",
					i, signalRequests[i].requests, signalRequests[i].responses);
			return 0;
		}
	return 1;
}
#endif /* FOR_SQUEAK_VM_TESTS */
