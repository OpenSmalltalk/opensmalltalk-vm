/*
 *  sqMacV2Time.c
 *  
 *
 *  Created by John M McIntosh on 5/12/08.
 *
 */
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *   Small parts of this code is 
 *   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.

 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
"This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
and its contributors", in the same place and form as other third-party acknowledgments. 
Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
such third-party acknowledgments.
*/
//

#include "sq.h"
#include "sqDummyaio.h"

#include "sqMacV2Time.h"
#include <sys/types.h>
#include <sys/time.h>

static struct timeval	 startUpTime;

#if STACKVM
/* all three methods have their roots in the original unix port from the late 90's */
/*
 * In the Cog VMs time management is in platforms/unix/vm/sqUnixHeartbeat.c.
 */
void SetUpTimers(void)
{
	extern void ioInitTime(void);
	
	/* set up the backwardcompatibility micro/millisecond clock */
    gettimeofday(&startUpTime, 0);
	/* setup the spiffy new 64-bit microsecond clock. */
	ioInitTime();
}
#else /* STACKVM */
void SetUpTimers(void)
{
	/* set up the micro/millisecond clock */
	gettimeofday(&startUpTime, 0);
}

sqLong ioMicroSeconds(void)
{
	//API Documented
	struct timeval now;
	sqLong theTimeIs;
	
	gettimeofday(&now, 0);
	if ((now.tv_usec-= startUpTime.tv_usec) < 0) {
		now.tv_usec+= 1000000;
		now.tv_sec-= 1;
	}
	now.tv_sec-= startUpTime.tv_sec;
	theTimeIs = now.tv_usec;
	theTimeIs = theTimeIs + now.tv_sec * 1000000;
	return theTimeIs;
}

sqInt ioMicroMSecs(void)
{
	//API Documented
	struct timeval now;
	sqInt theTimeIs;
	
	gettimeofday(&now, 0);
	if ((now.tv_usec-= startUpTime.tv_usec) < 0) {
		now.tv_usec+= 1000000;
		now.tv_sec-= 1;
	}
	now.tv_sec-= startUpTime.tv_sec;
	theTimeIs = ((now.tv_usec / 1000 + now.tv_sec * 1000) & MillisecondClockMask);
	return theTimeIs;
}

sqInt ioMSecs(void) {
	//API Documented
	return ioMicroMSecs();
}

sqInt ioSeconds(void) {
	//API Documented
	time_t unixTime;
	sqInt	theSecondsAre; 
	
	unixTime = time(0);
	unixTime += localtime(&unixTime)->tm_gmtoff;
	/* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
	 and 52 non-leap years later than Squeak. */
	theSecondsAre = unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
	return theSecondsAre;
}

sqInt ioUtcWithOffset(sqLong *microSeconds, int *offset)
{
	struct timeval timeval;
	if (gettimeofday(&timeval, NULL) == -1) return -1;
	time_t seconds = timeval.tv_sec;
	suseconds_t usec = timeval.tv_usec;
	*microSeconds = seconds * 1000000 + usec;
	*offset = localtime(&seconds)->tm_gmtoff;
	return 0;
}


sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds) {
	//API Documented
	/* This operation is platform dependent. 	 */
	#pragma unused(microSeconds)

	sqInt	   realTimeToWait,now,next;
	extern sqInt getNextWakeupTick(void);				//This is a VM Callback
	extern sqInt setInterruptCheckCounter(sqInt value);  //This is a VM Callback

	setInterruptCheckCounter(0);
	now = ioMSecs();
	next = getNextWakeupTick();
	
	/*BUG??? what if clock wraps? */
	
	if (next <= now)
		if (next == 0)
				realTimeToWait = 16;
			else {
				return 0;
			}
		else
			realTimeToWait = next - now; 

	aioSleep((int) realTimeToWait*1000);
	return 0;
}
#endif /* STACKVM */

