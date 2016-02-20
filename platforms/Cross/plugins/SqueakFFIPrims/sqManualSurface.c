#include "sqFFI.h"
#include "sq.h"

#include "sqVirtualMachine.h"
extern struct VirtualMachine* interpreterProxy;

/* Need separate cases for GNU C and MSVC. */
#ifdef DEBUG 
#warning "DEBUG printing enabled"
#define DPRINTF(x) warnPrintf x
#elif defined(_DEBUG)
#pragma message ( "DEBUG printing enabled" )
#define DPRINTF(x) warnPrintf x
#else
#define DPRINTF(x)
#endif

#ifndef NULL
#define NULL 0
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

/* Don't want to mess with EXPORT status of functions in SurfacePlugin.c,
   we use function-pointers here. */
static fn_ioRegisterSurface registerSurface = NULL;
static fn_ioUnregisterSurface unregisterSurface = NULL;
static fn_ioFindSurface findSurface = NULL;
void initSurfacePluginFunctionPointers()
{
	registerSurface = (fn_ioRegisterSurface) interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
	unregisterSurface = (fn_ioUnregisterSurface) interpreterProxy->ioLoadFunctionFrom("ioUnregisterSurface","SurfacePlugin");
	findSurface = (fn_ioFindSurface) interpreterProxy->ioLoadFunctionFrom("ioFindSurface","SurfacePlugin");
}

/* This is the structure that represents a "manual surface".  These are 
   created/destroyed by new primitives in this plugin.  During its life-time,
   it may be touched directly from Squeak code to set/clear "ptr", and also
   treated as a generic surface via BitBlt's use of the SurfacePlugin. */
typedef struct {
	int width;
	int height;
	int rowPitch;
	int depth;
	int isMSB;
	void* ptr;
	int isLocked;
} ManualSurface;

/* Create the dispatch-table that SurfacePlugin will use to interact with
   instances of "struct ManualSurface" */
static long manualSurfaceGetFormat(ManualSurface* surface, long* width, long* height, long* depth, long* isMSB);
static void* manualSurfaceLock(ManualSurface* surface, long *pitch, long x, long y, long w, long h);
static long manualSurfaceUnlock(ManualSurface* surface, long x, long y, long w, long h);
static long manualSurfaceShow(ManualSurface* surface, long x, long y, long w, long h);
static sqSurfaceDispatch manualSurfaceDispatch = {
  1,
  0,
  (fn_getSurfaceFormat) manualSurfaceGetFormat,
  (fn_lockSurface) manualSurfaceLock,
  (fn_unlockSurface) manualSurfaceUnlock,
  (fn_showSurface) manualSurfaceShow
};

/* sqSurfaceDispatch functions *****************************************************************************/

long manualSurfaceGetFormat(ManualSurface* surface, long* width, long* height, long* depth, long* isMSB) {
	*width = surface->width;
	*height = surface->height;
	*depth = surface->depth;
	*isMSB = surface->isMSB;
	DPRINTF(("Getting Surface Format: %lx %ld %ld %ld %ld\n", (long) surface, *width, *height, *depth, *isMSB));
	return 1;
}

void* manualSurfaceLock(ManualSurface* surface, long *pitch, long x, long y, long w, long h) {
	/* Ideally, would be atomic.  But it doens't matter for the forseeable future,
	   since it is only called via BitBlt primitives. */
	int wasLocked = surface->isLocked;
	surface->isLocked = 1; 
	
	/* Can't lock if it was already locked. */
	if (wasLocked) return NULL;
	
	/* If there is no pointer, the lock-attempt fails. */
	if (!surface->ptr) {
		surface->isLocked = 0;
		return NULL;
	}
	
	/* Success!  Return the pointer. */
	*pitch = surface->rowPitch;
	DPRINTF(("Locked Surface: %lx Input Rect: %ld %ld %ld %ld  Row Pitch: %ld\n", (long) surface, x, y, w, h, *pitch));
	return surface->ptr;
}

long manualSurfaceUnlock(ManualSurface* surface, long x, long y, long w, long h) {
    surface->isLocked = 0;
	DPRINTF(("Unlocked Surface: %lx Rect: %ld %ld %ld %ld\n", (long) surface, x, y, w, h));
	return 1;	
}

long manualSurfaceShow(ManualSurface* surface, long x, long y, long w, long h) {
	/* Unsupported */
	return 0;
}

/* primitive interface functions (i.e. called from Squeak) *********************************************/

/* Answer non-negative surfaceID if successful, and -1 for failure. */
long createManualSurface(long width, long height, long rowPitch, long depth, long isMSB) {
	ManualSurface* newSurface;
	long surfaceID, result;
	
	if (width < 0) return -1;
	if (height < 0) return -1;
	if (rowPitch < (width*depth)/8) return -1;
	if (depth < 1 || depth > 32) return -1;
	if (!registerSurface) return -1; /* failure... couldn't init function-pointer */
	
	newSurface = (ManualSurface*)malloc(sizeof(ManualSurface));
	if (!newSurface) return -1;
	newSurface->width = width;
	newSurface->height = height;
	newSurface->rowPitch = rowPitch;
	newSurface->depth = depth;
	newSurface->isMSB = isMSB;
	newSurface->ptr = NULL;
	newSurface->isLocked = FALSE;
	
	result = registerSurface((long)newSurface, &manualSurfaceDispatch, &surfaceID);
	if (!result) {
		/* Failed to register surface. */
		free(newSurface);
		return -1;
	}
	return surfaceID;
}

long destroyManualSurface(long surfaceID) {
	if (!unregisterSurface) return 0; /* failure... couldn't init function-pointer */
	else return unregisterSurface(surfaceID);
}

long setManualSurfacePointer(long surfaceID, void* ptr) {
	long surfaceHandle;
	ManualSurface *surface;
	long result;
	if (!findSurface) return FALSE; /* failure... couldn't init function-pointer */
	result = findSurface(surfaceID, NULL, &surfaceHandle);
	if (!result) return FALSE; /* failed to find surface */
	surface = (ManualSurface*)surfaceHandle;	
	if (surface->isLocked) return FALSE; /* can't set pointer while surface is locked */
	surface->ptr = ptr;
	DPRINTF(("Set Surface: %lx Polonger: %lx\n", surfaceID, (long)ptr));
	return TRUE;
}
