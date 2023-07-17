/*
 *  macintoshosxextra.c
 *  SqueakPureObjc
 *
 *  Created by John M McIntosh on 09-11-14.
 *  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *
 */

#include "sq.h"

#include <sys/syslimits.h>


sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth, double hScale, double vScale, sqInt landscapeFlag) {
	/* experimental: print a form with the given bitmap, width, height, and depth at
	 the given horizontal and vertical scales in the given orientation
	 However John Mcintosh has introduced a printjob class and plugin to replace this primitive */
#pragma unused( bitsAddr,  width,  height,  depth,  hScale,  vScale,  landscapeFlag)
	return true;
}

sqInt ioSetDisplayMode( sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag) {return 0;}

int plugInNotifyUser(char *msg) { return 0; }
