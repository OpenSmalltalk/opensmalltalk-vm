/*
 *  macintoshextra.c
 *  Squeak iPhone
 *
 *  Created by John M McIntosh on 2/23/08.
 *  Copyright 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *
 */



#include "macintoshextra.h"
#include <sys/syslimits.h>


int ioFormPrint(int bitsAddr, int width, int height, int depth, double hScale, double vScale, int landscapeFlag) {
	/* experimental: print a form with the given bitmap, width, height, and depth at
	   the given horizontal and vertical scales in the given orientation
           However John Mcintosh has introduced a printjob class and plugin to replace this primitive */
#pragma unused( bitsAddr,  width,  height,  depth,  hScale,  vScale,  landscapeFlag)
	return true;
}

void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle) {return 0;}
void *ioLoadModule(char *pluginName) {return 0;}
sqInt ioFreeModule(void *moduleHandle){return 0;}

sqInt ioGetButtonState() {return 0;}
sqInt ioGetKeystroke() {return -1;}
sqInt ioMousePoint() {return 0;}
sqInt ioPeekKeystroke() {return 0;}

sqInt ioSetCursor( sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY) {return 0;}
sqInt ioSetCursorWithMask( sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY) {return 0;}
sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);
sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY) {return 0;}	
/* Retrieve the next input event from the OS. */

sqInt ioSetDisplayMode( sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag) {return 0;}

//int plugInTimeToReturn(void) {
//    return false;
//}

int clearProfile(void){return 0;}														
int dumpProfile(void){return 0;}														
int startProfiling(void){return 0;}													
int stopProfiling(void)	{return 0;}			

int plugInNotifyUser(char *msg);
int plugInNotifyUser(char *msg) { return 0; }

