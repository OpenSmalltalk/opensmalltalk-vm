/*
 *  sqSqueakMainApp.m
 *  
 *
 *  Created by John M McIntosh on 5/15/08.
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

#import "sqSqueakAppDelegate.h"

#import "sq.h"
#import "sqSqueakMainApp.h"
#import "sqMacV2Memory.h"
#import <limits.h>

#warning what about these guyes?
/*** Variables -- globals for access from pluggable primitives ***/
int		argCnt= 0;
char	**argVec= 0;
char	**envVec= 0;

extern sqSqueakAppDelegate *gDelegateApp;

BOOL			gQuitNowRightNow=false,gSqueakHeadless=false;
int				gSqueakUseFileMappedMMAP=0;
char            gSqueakUntrustedDirectoryName[PATH_MAX];
char            gSqueakTrustedDirectoryName[PATH_MAX];

sqInt printAllStacks(void);

void sigsegv(int ignore)
{
#pragma unused(ignore)

	/* error("Segmentation fault"); */
	static int printingStack= 0;

	printf("\nSegmentation fault\n\n");
	if (!printingStack)
		{
			printingStack= 1;
			printAllStacks();
		}
	abort();
}

sqInt ioExit(void) {
	//API Documented
 	[gDelegateApp.squeakApplication ioExit];
 	return 0;
}

sqInt ioDisablePowerManager(sqInt disableIfNonZero) {
	//API Documented
	return 0;
}	