/*
 *  sqDummyaio.c
 *  SqueakNoOGLIPhone
 *
 *  Created by John M McIntosh on 5/29/08.
 */
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 *  Copyright 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *
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


#include "sq.h"
#include "sqDummyaio.h"


int aioPoll(int microSeconds) {
	return 0;
}

void aioInit(void) {

}

sqInt aioSleepForUsecs(sqInt microSeconds)
{
#if defined(HAVE_NANOSLEEP)
    if (microSeconds < (1000000/60))	/* < 1 timeslice? */
    {
        struct timespec rqtp= { 0, microSeconds * 1000 };
        struct timespec rmtp;
        nanosleep(&rqtp, &rmtp);
        microSeconds= 0;			/* poll but don't block */
    }
#endif
    return 0;
}


/* sleep for microSeconds*/

sqInt aioSleep(sqInt microSeconds)
{
#if defined(HAVE_NANOSLEEP)
	if (microSeconds < (1000000/60))	/* < 1 timeslice? */
	{
		struct timespec rqtp= { 0, microSeconds * 1000 };
		struct timespec rmtp;
		nanosleep(&rqtp, &rmtp);
	}
#endif
	return 0;
}

void aioEnable(int fd, void *clientData, int flags) {}
void aioDisable(int fd) {}
void aioHandle(int fd, void *handler, int mask) {};
void aioFini(void) {};

