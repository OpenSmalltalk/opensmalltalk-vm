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
#include "pharovm/semaphores/platformSemaphore.h"

#if !COGMTVM
sqOSThread ioVMThread; /* initialized in the various <plat>/vm/sqFooMain.c */
#endif
extern void forceInterruptCheck(void);
extern sqInt doSignalSemaphoreWithIndex(sqInt semaIndex);

typedef struct {
	int requests;
	int responses;
} SignalRequest;

/* We would like to use something like the following for the tides
	typedef int semidx_t;
 * but apparently
	#define MaxTide ((unsigned semidx_t)-1 >> 1)
 * is not legal; at least clang complains of mismatched parentheses.
 */
static SignalRequest *signalRequests = 0;
static int numSignalRequests = 0;
static volatile sqInt checkSignalRequests;

Semaphore* requestMutex;

/* The tide marks define the minimum range of indices into signalRequests that
 * the VM needs to scan.  With potentially thousands of indices to scan this can
 * save significant lengths of time.  Every time the VM responds to requests in
 * doSignalExternalSemaphores it switches tides by resetting the tides not in
 * use to an empty interval, toggling useTideA, and reading the tides in use
 * prior to the toggle.  Hence initialize the tides to an empty interval.
 */
#define MaxTide ((unsigned int)-1 >> 1)
#define MinTide -1
static volatile char useTideA = 1;
static volatile int lowTideA = MaxTide, highTideA = MinTide;
static volatile int lowTideB = MaxTide, highTideB = MinTide;

#define max(a,b) (a > b ? a : b)
#define min(a,b) (a < b ? a : b)

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
	requestMutex = platform_semaphore_new(1);
}

// This is defined here as there is no common interface for unix AIO and windows AIO
void aioInterruptPoll();


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

	requestMutex->wait(requestMutex);

	sqLowLevelMFence();
	signalRequests[i].requests += 1;

	if (useTideA) {
		if(lowTideA > i) lowTideA = i;
		if (highTideA < i) highTideA = i;
	} else {
		if (lowTideB > i) lowTideB = i;
		if (highTideB < i) highTideB = i;
	}

	checkSignalRequests = 1;
	forceInterruptCheck();

	requestMutex->signal(requestMutex);

	aioInterruptPoll();


	return 1;
}

int isPendingSemaphores(){
	return checkSignalRequests;
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
doSignalExternalSemaphores(sqInt externalSemaphoreTableSize)
{
	volatile int i, lowTide, highTide;
	char switched, signalled = 0;

	requestMutex->wait(requestMutex);

	sqLowLevelMFence();
	if (!checkSignalRequests){
		requestMutex->signal(requestMutex);
		return 0;
	}

	switched = 0;
	checkSignalRequests = 0;

	sqLowLevelMFence();
	if (useTideA) {
		lowTideB = MaxTide;
		highTideB = MinTide;
		useTideA = 0;
		sqLowLevelMFence();
		lowTide = lowTideA;
		highTide = highTideA;
	}
	else {
		lowTideA = MaxTide;
		highTideA = MinTide;
		useTideA = 1;
		sqLowLevelMFence();
		lowTide = lowTideB;
		highTide = highTideB;
	}
	sqLowLevelMFence();

	/* doing this here saves a bounds check in doSignalSemaphoreWithIndex */
	if (highTide >= externalSemaphoreTableSize)
		highTide = externalSemaphoreTableSize - 1;
	for (i = lowTide; i <= highTide; i++)
		while (signalRequests[i].responses != signalRequests[i].requests) {
			if (doSignalSemaphoreWithIndex(i+1))
				switched = 1;
			++signalRequests[i].responses;
			signalled = 1;
		}

	requestMutex->signal(requestMutex);

	return switched;
}
