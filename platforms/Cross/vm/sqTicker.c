/* sqTicker.c
 *	Core cross-platform tickers.  tick.er (n): one who ticks a tickee 
 *
 *	Authors: Eliot Miranda & Josh Gargus
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

#if !VM_TICKER
/* stubs for (unsupported) high-priority ticker support */
# include "sq.h"

void
addSynchronousTickee(void (*tickee)(void), unsigned periodms, unsigned roundms)
{ error("ticker unsupported in this VM"); }

void
addHighPriorityTickee(void (*tickee)(void), unsigned periodms)
{ error("ticker unsupported in this VM"); }

void
checkHighPriorityTickees(usqLong utcMicrosecondClock) {}

void
ioSynchronousCheckForEvents() {}

usqInt ioVMTickerCount() { return 0; }

usqInt ioVMTickeeCallCount() { return 0; }

sqLong ioVMTickerStartUSecs() { return 0; }
#else /* VM_TICKER */
/* High-priority and synchronous tickee function support.
 *
 * Tickers provide the ability to register a tickee function that will be
 * called at a regular interval.  There are two sets of tickers.  The high-
 * priority ticker is asynchronous and if possible, runs in a high-priority
 * thread or if not, from an interrupt.  Running from an interrupt is undesir-
 * able because it is much easier to create deadlock, for example by interrupt-
 * ing the VM when it has acquired some lock, and a tickee tries to acquire
 * the same lock.   But the use of an interrupt is forced on linux because as
 * of 2006 and the 2.6.x kernel there is no way for a non-root process to
 * create threads of different priorities.
 *
 * The synchronous ticker runs in the VM thread at the earliest opportunity once
 * the tick has occurred.  The VM calls the ticker from its event check.
 *
 * This file implements the cross-platform components, registering tickers and
 * calling tickers if deadlines have been reached.  The platform-specific heart-
 * beats implement the threads or interrupts and the clocks.
 *
 * For the moment the number of asynchronous and synchronous tickees is
 * hard-wired, but they could easily be defined by a command-line argument etc.
 */

#include "sq.h"
#include "sqAssert.h"
#include "sqAtomicOps.h"
#include "sqMemoryFence.h"


#define NUM_ASYNCHRONOUS_TICKEES 4
#define NUM_SYNCHRONOUS_TICKEES 4
#define MicrosecondsPerMillisecond 1000

typedef struct {
	void (*tickee)(void);
	usqLong tickeeDeadlineUsecs;
	usqLong tickeePeriodUsecs;
} Tickee;

static int numSyncTickees = 0;
static Tickee synch[NUM_SYNCHRONOUS_TICKEES];

#if ITIMER_HEARTBEAT
/* See platforms/unix/vm/sqUnixHeartbeat.c */
static volatile int shouldYieldToHighPriorityTickerThread;
#endif

/* Add or remove a synchronous tickee.  If periodms is non zero add the tickee
 * calling it every periodms, aligned to roundms, if non-zero.  If periodms is
 * zero, remove tickee.
 */
void
addSynchronousTickee(void (*tickee)(void), unsigned periodms, unsigned roundms)
{
	int i;

	if (!periodms) {
		for (i = 0; i < numSyncTickees; i++)
			if (synch[i].tickee == tickee) {
				--numSyncTickees;
				if (i < numSyncTickees)
					memmove(synch + i,
							synch + i + 1,
							sizeof(synch[i]) * (numSyncTickees - i));
				return;
			}
		return;
	}
	for (i = 0; i < NUM_SYNCHRONOUS_TICKEES; i++)
		if (i >= numSyncTickees
		 || !synch[i].tickee
		 || synch[i].tickee == tickee) {
			synch[i].tickee = tickee;
			synch[i].tickeePeriodUsecs = periodms * MicrosecondsPerMillisecond;
			synch[i].tickeeDeadlineUsecs = synch[i].tickeePeriodUsecs
										+ ioUTCMicroseconds();
			if (roundms) {
				synch[i].tickeeDeadlineUsecs -= synch[i].tickeeDeadlineUsecs
										% (roundms * MicrosecondsPerMillisecond);
				if (synch[i].tickeeDeadlineUsecs < ioUTCMicroseconds())
					synch[i].tickeeDeadlineUsecs += synch[i].tickeePeriodUsecs;
			}
			if (i >= numSyncTickees)
				++numSyncTickees;
			return;
		}
	error("ran out of synchronous tickee slots");
}

void
ioSynchronousCheckForEvents()
{
	int i;

#if ITIMER_HEARTBEAT
	extern void yieldToHighPriorityTickerThread(void);
	sqLowLevelMFence();
	if (shouldYieldToHighPriorityTickerThread)
		yieldToHighPriorityTickerThread();
#endif
	for (i = 0; i < numSyncTickees; i++)
		if (synch[i].tickee
		 && ioUTCMicroseconds() >= synch[i].tickeeDeadlineUsecs) {
			synch[i].tickeeDeadlineUsecs += synch[i].tickeePeriodUsecs;
			synch[i].tickee();
		}
}

#if !ITIMER_HEARTBEAT	/* Hack; allow heartbeat to avoid */
static					/* prodHighPriorityThread unless necessary */
# endif					/* see platforms/unix/vm/sqUnixHeartbeat.c */
int numAsyncTickees = 0;
static Tickee async[NUM_ASYNCHRONOUS_TICKEES];
static usqInt vmTickerCount = 0;
static usqInt vmTickerTickeeCalls = 0;
static usqLong vmTickerStartUSecs = 0;

usqInt ioVMTickerCount() { return vmTickerCount; }

usqInt ioVMTickeeCallCount() { return vmTickerTickeeCalls; }

usqLong ioVMTickerStartUSecs() { return vmTickerStartUSecs; }


/* Add or remove an asynchronous tickee.  If periodms is non zero add the
 * tickee, calling it every periodms.
 *
 * N.B. addHighPriorityTickee is called from the VM thread, whereas
 * checkHighPriorityTickees is called from the high-priority heartbeat thread
 * (or an interrupt).  The above 64-bit variables must therefore be read and
 * written atomically to avoid either thread reading or writing a modified
 * half of the variable while the other half has yet to be updated.
 */
void
addHighPriorityTickee(void (*tickee)(void), unsigned periodms)
{
	int i;

	if (!periodms) {
		for (i = 0; i < numAsyncTickees; i++)
			/* We cannot safely copy the data to keep used tickees contiguous
			 * because checkHighPriorityTickees could be called during the move.
			 * This implies first checking for an existing tickee below before
			 * using an empty slot because an empty slot can be created before
			 * a used (and subsequently modified) tickee.
			 */
			if (async[i].tickee == tickee) {
				async[i].tickee = 0;
				sqLowLevelMFence();
				return;
			}
		return;
	}
	for (i = 0; i < numAsyncTickees; i++)
		if (async[i].tickee == tickee)
			break;
	if (i >= numAsyncTickees)
		for (i = 0; i < NUM_ASYNCHRONOUS_TICKEES; i++)
			if (i >= numAsyncTickees
			 || !async[i].tickee)
				break;
	if (i >= NUM_ASYNCHRONOUS_TICKEES)
		error("ran out of asyncronous tickee slots");

	if (!vmTickerStartUSecs)
		vmTickerStartUSecs = ioUTCMicrosecondsNow();

	/* first disable the tickee while updating the entry. */
	async[i].tickee = 0;
	sqLowLevelMFence();
	async[i].tickeePeriodUsecs = periodms * MicrosecondsPerMillisecond;
	async[i].tickeeDeadlineUsecs = async[i].tickeePeriodUsecs
								+ ioUTCMicroseconds();
	async[i].tickee = tickee;
	if (i >= numAsyncTickees)
		++numAsyncTickees;
	sqLowLevelMFence();
}

/* If the heartbeat fails to invoke checkHighPriorityTickees in a timely manner
 * for whatever reason (e.g. the user has put the machine to sleep) we need to
 * readjust the deadline, moving it forward to a delta from the current time.
 * If we don't then the heartbeat will spin calling checkHighPriorityTickees as
 * it inches forward at tickeePeriodUsecs.  But if we always base the deadline
 * on the current time and for whatever reason there is a slight hiccup then all
 * subsequent deadlines will be pushed into the future.  The HiccupThreshold of
 * 10 seconds distinguishes between the two cases; longer than 10 seconds and we
 * assume the system has slept.
 */
#define HiccupThreshold 10000000ULL /* 10 seconds */

/* Avoid any reentrancy problems with checkHighPriorityTickees */
static	char checkingHighPriorityTickees = 0;

void
checkHighPriorityTickees(usqLong utcMicrosecondClock)
{
	int i;

#if ITIMER_HEARTBEAT
	extern void unblockVMThreadAfterYieldToHighPriorityTickerThread(void);
	shouldYieldToHighPriorityTickerThread = 1;
#endif
	/* Since this runs either in a high-priority thread or in an interrupt, only
	 * one fence is needed.  Since the VM thread will not disturb any non-zero
	 * entry (except for changing the period) we can read the entry without
	 * locking.
	 */
	sqLowLevelMFence();
	if (!vmTickerStartUSecs || checkingHighPriorityTickees)
		return;
	checkingHighPriorityTickees = 1;
	sqLowLevelMFence();
	++vmTickerCount;
	for (i = 0; i < numAsyncTickees; i++)
		if (async[i].tickee) {
			if (utcMicrosecondClock >= async[i].tickeeDeadlineUsecs) {
				if (async[i].tickeeDeadlineUsecs + HiccupThreshold
					< utcMicrosecondClock)
					async[i].tickeeDeadlineUsecs
						= utcMicrosecondClock + async[i].tickeePeriodUsecs;
				else
					async[i].tickeeDeadlineUsecs += async[i].tickeePeriodUsecs;
				++vmTickerTickeeCalls;
				async[i].tickee();
			}
		}
#if ITIMER_HEARTBEAT
	shouldYieldToHighPriorityTickerThread = 0;
	sqLowLevelMFence();
	unblockVMThreadAfterYieldToHighPriorityTickerThread();
#endif
	checkingHighPriorityTickees = 0;
	sqLowLevelMFence();
}
#endif /* VM_TICKER */
