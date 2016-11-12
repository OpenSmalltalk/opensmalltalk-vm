/*
 *  sqMacQuicktimeInteface.c
 *  SqueakQuicktime
 *
 *  Created by John M McIntosh on 17/01/06.
 *  Copyright 2006 Corporate Smalltalk Consulting ltd.  All rights reserved, published under the Squeak-L licence
 *
 */

#include <Movies.h>
#include "sqMacQuicktimeInteface.h"
#include "SurfacePlugin.h"
#include "sqMemoryAccess.h"
#include "sqVirtualMachine.h"

typedef struct QuickTimeBitMapForSqueak {
   int width, height, depth;    /* width, height, and depth */
   int rowBytes;   /* how many bytes per scan line? */
   MovieDrawingCompleteUPP	myDrawCompleteProc;
   Movie	movie;
   int	semaIndex;
   void *bits;  /* where are those bits? */
   
} QuickTimeBitMapForSqueak;

static fn_ioRegisterSurface registerSurface = 0;
static fn_ioUnregisterSurface unregisterSurface = 0;
static fn_ioFindSurface findSurface = 0;

int QuicktimeGetSurfaceFormat(sqIntptr_t handle, int* width, int* height, int* depth, int* isMSB);
sqIntptr_t QuicktimeLockSurface(sqIntptr_t handle, int *pitch, int x, int y, int w, int h);
int QuicktimeUnlockSurface(sqIntptr_t handle, int x, int y, int w, int h);
int QuicktimeShowSurface(sqIntptr_t handle, int x, int y, int w, int h);

struct VirtualMachine *interpreterProxy;

static sqSurfaceDispatch QuicktimeTargetDispatch = {
  1,
  0,
  (fn_getSurfaceFormat) QuicktimeGetSurfaceFormat,
  (fn_lockSurface) QuicktimeLockSurface,
  (fn_unlockSurface) QuicktimeUnlockSurface,
  (fn_showSurface) QuicktimeShowSurface
};

static OSErr DrawCompleteProc(Movie theMovie, long refCon) {
	interpreterProxy->signalSemaphoreWithIndex(refCon);
	return noErr;
}

void SetupSurface() {
    registerSurface = (fn_ioRegisterSurface) interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
    unregisterSurface = (fn_ioUnregisterSurface) interpreterProxy->ioLoadFunctionFrom("ioUnregisterSurface","SurfacePlugin");
	findSurface = (fn_ioFindSurface) interpreterProxy->ioLoadFunctionFrom("ioFindSurface","SurfacePlugin");
}

sqInt sqQuicktimeInitialize()
{
	SetupSurface();
	return true;
}

sqInt sqQuicktimeShutdown() {
	return true;
}

int stQuicktimeSetSurfacewidthheightrowBytesdepthmovie(char * buffer, int width, int height, int rowBytes, int depth, void *movie)
{
	QuickTimeBitMapForSqueak *bitMap;
	int sqHandle;
	
	bitMap = calloc(1, sizeof(QuickTimeBitMapForSqueak));
	bitMap->width = width;
	bitMap->height = height;
	bitMap->depth = depth;
	bitMap->rowBytes = rowBytes;
	bitMap->bits = buffer;
	bitMap->movie = movie;
    (*registerSurface)((sqIntptr_t) bitMap, &QuicktimeTargetDispatch, &sqHandle);
	
	return sqHandle;
}

int stQuicktimeSetToExistingSurfacegworldwidthheightrowBytesdepthmovie
	(int sqHandle, char * buffer, int width, int height, int rowBytes, int depth, void *movie)
{
	QuickTimeBitMapForSqueak *bitMap;
	
	/* see if the handle really describes a MyBitmap surface */
	if( ! (*findSurface)(sqHandle, &QuicktimeTargetDispatch, (sqIntptr_t*) (&bitMap)) ) {
		/* i don't know what it is but certainly not MyBitmap */
		return interpreterProxy->primitiveFail();
	}
	
	bitMap->width = width;
	bitMap->height = height;
	bitMap->depth = depth;
	bitMap->rowBytes = rowBytes;
	bitMap->bits = buffer;
	bitMap->movie = movie;
    (*registerSurface)((sqIntptr_t) bitMap, &QuicktimeTargetDispatch, &sqHandle);
	
	return sqHandle;
}

int stQuicktimeDestroySurface(int sqHandle) {
	QuickTimeBitMapForSqueak *myBM;

	/* see if the handle really describes a MyBitmap surface */
	if( ! (*findSurface)(sqHandle, &QuicktimeTargetDispatch, (sqIntptr_t*) (&myBM)) ) {
		/* i don't know what it is but certainly not MyBitmap */
		return interpreterProxy->primitiveFail();
	}
	/* unregister and destroy */
	(*unregisterSurface)(sqHandle);
	free(myBM);
}

int stQuicktimeDestroy(int sqHandle) {
	QuickTimeBitMapForSqueak *myBM;

	/* see if the handle really describes a MyBitmap surface */
	if( ! (*findSurface)(sqHandle, &QuicktimeTargetDispatch, (sqIntptr_t*) (&myBM)) ) {
		/* i don't know what it is but certainly not MyBitmap */
		return interpreterProxy->primitiveFail();
	}
	/* unregister and destroy */
	(*unregisterSurface)(sqHandle);
	if (myBM->semaIndex && !((myBM->movie == nil) || (*myBM->movie == 0xFFFFFFFFU))) {
		DisposeMovieDrawingCompleteUPP(myBM->myDrawCompleteProc);
 		SetMovieDrawingCompleteProc (myBM->movie,0,0,0);
	}
	myBM->semaIndex = 0;
	free(myBM);
	return 1;
}


int stQuicktimeSetSemaphorefor(int index, int sqHandle) {
//		interpreterProxy->signalSemaphoreWithIndex(state->semaIndex);
	QuickTimeBitMapForSqueak *myBM;
	if( ! (*findSurface)(sqHandle, &QuicktimeTargetDispatch, (sqIntptr_t*) (&myBM)) ) {
		/* i don't know what it is but certainly not MyBitmap */
		return interpreterProxy->primitiveFail();
	}
	if	((myBM->movie == nil) || (*myBM->movie == 0xFFFFFFFFU))	
		return interpreterProxy->primitiveFail();
	myBM->myDrawCompleteProc = NewMovieDrawingCompleteUPP(DrawCompleteProc);
	SetMovieDrawingCompleteProc (myBM->movie,movieDrawingCallWhenChanged,myBM->myDrawCompleteProc,(long) index);
	myBM->semaIndex = index;
	return 0;
}

int stQuicktimeClearSemaphore(int sqHandle) {
	QuickTimeBitMapForSqueak *myBM;
	if( ! (*findSurface)(sqHandle, &QuicktimeTargetDispatch, (sqIntptr_t*) (&myBM)) ) {
		/* i don't know what it is but certainly not MyBitmap */
		return interpreterProxy->primitiveFail();
	}
	if	((myBM->movie == nil) || (*myBM->movie == 0xFFFFFFFFU))	
		return interpreterProxy->primitiveFail();
	if (myBM->semaIndex) {
		SetMovieDrawingCompleteProc (myBM->movie,0,0,0);
	}
	myBM->semaIndex = 0;
	return 1;
}

int QuicktimeGetSurfaceFormat(sqIntptr_t handle, int *width, int *height, int *depth, int *isMSB) {
	/* fill in status information */
	QuickTimeBitMapForSqueak *myBM=(QuickTimeBitMapForSqueak) handle;
	*width = myBM->width;
	*height = myBM->height;
	*depth = myBM->depth;
	*isMSB = 1; /* or zero depending on platform or choice */
#warning Endeness
	return 1; /* success - otherwise return zero */
}

sqIntptr_t QuicktimeLockSurface(sqIntptr_t handle, int *pitch, int x, int y, int w, int h)
{
	/* lock the region x,y - (x+w),(y+h)
	   the area actually used is provided so that expensive
	   operations (like a round trip to the X-Server) can
	   be avoided. See SurfacePlugin.h */
	/* for our simple example, only fill in the pitch. No locking is
required. */
	QuickTimeBitMapForSqueak *myBM=(QuickTimeBitMapForSqueak) handle;
	*pitch = myBM->rowBytes;
	return (sqIntptr_t) myBM->bits; /* success */
}

int QuicktimeUnlockSurface(sqIntptr_t handle, int x, int y, int w, int h) {
	/* Unlock a previously locked portion of myBM.
	   The area describes the 'dirty region' which might
	   need to be written back/flushed whatever. */
	/* for the simple example do nothing */
	return 1;
}

int QuicktimeShowSurface(sqIntptr_t handle, int x, int y, int w, int h) {
	/* the surface represents Display - update the portion
	   described in x,y,w,h */
	/* for our simple example we just ignore this */
	return 0; /* e.g., fail */
}
