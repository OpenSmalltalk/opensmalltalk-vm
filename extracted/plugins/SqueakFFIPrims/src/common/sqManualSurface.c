#include "sqFFI.h"
#include "sq.h"

#include "sqVirtualMachine.h"
extern struct VirtualMachine* interpreterProxy;

#ifndef NULL
#define NULL 0
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

#include "pharovm/debug.h"

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
static int manualSurfaceGetFormat(sqIntptr_t, int*, int*, int*, int*);
static sqIntptr_t manualSurfaceLock(sqIntptr_t, int *, int, int, int, int);
static int manualSurfaceUnlock(sqIntptr_t, int, int, int, int);
static int manualSurfaceShow(sqIntptr_t, int, int, int, int);
static sqSurfaceDispatch manualSurfaceDispatch = {
  1,
  0,
  manualSurfaceGetFormat,
  manualSurfaceLock,
  manualSurfaceUnlock,
  manualSurfaceShow
};

/* sqSurfaceDispatch functions *****************************************************************************/

int manualSurfaceGetFormat(sqIntptr_t surfaceArg, int* width, int* height, int* depth, int* isMSB) {
	ManualSurface* surface = (ManualSurface *)surfaceArg;
	*width = surface->width;
	*height = surface->height;
	*depth = surface->depth;
	*isMSB = surface->isMSB;
	logTrace("Getting Surface Format: %" PRIxSQPTR " %ld %ld %ld %ld\n", (sqIntptr_t) surface, *width, *height, *depth, *isMSB);
	return 1;
}

sqIntptr_t manualSurfaceLock(sqIntptr_t surfaceArg, int *pitch, int x, int y, int w, int h) {
	ManualSurface* surface = (ManualSurface *)surfaceArg;
	/* Ideally, would be atomic.  But it doens't matter for the forseeable future,
	   since it is only called via BitBlt primitives. */
	int wasLocked = surface->isLocked;
	surface->isLocked = 1; 
	
	/* Can't lock if it was already locked. */
	if (wasLocked) return 0;
	
	/* If there is no pointer, the lock-attempt fails. */
	if (!surface->ptr) {
		surface->isLocked = 0;
		return 0;
	}
	
	/* Success!  Return the pointer. */
	*pitch = surface->rowPitch;
	logTrace("Locked Surface: %" PRIxSQPTR " Input Rect: %ld %ld %ld %ld  Row Pitch: %ld\n", (sqIntptr_t) surface, x, y, w, h, *pitch);
	return (sqIntptr_t)(surface->ptr);
}

int manualSurfaceUnlock(sqIntptr_t surfaceArg, int x, int y, int w, int h) {
	ManualSurface* surface = (ManualSurface *)surfaceArg;
    surface->isLocked = 0;
    logTrace("Unlocked Surface: %" PRIxSQPTR " Rect: %ld %ld %ld %ld\n", (sqIntptr_t) surface, x, y, w, h);
	return 1;	
}

int manualSurfaceShow(sqIntptr_t surfaceArg, int x, int y, int w, int h) {
	/* Unsupported */
	return 0;
}

/* primitive interface functions (i.e. called from Squeak) *********************************************/

/* Answer non-negative surfaceID if successful, and -1 for failure. */
int createManualSurface(int width, int height, int rowPitch, int depth, int isMSB) {
	ManualSurface* newSurface;
	int surfaceID, result;
	
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
	
	result = registerSurface((sqIntptr_t)newSurface, &manualSurfaceDispatch, &surfaceID);
	if (!result) {
		/* Failed to register surface. */
		free(newSurface);
		return -1;
	}
	return surfaceID;
}

int destroyManualSurface(int surfaceID) {
	if (!unregisterSurface) return 0; /* failure... couldn't init function-pointer */
	return unregisterSurface(surfaceID);
}

int setManualSurfacePointer(int surfaceID, void* ptr) {
	sqIntptr_t surfaceHandle;
	ManualSurface *surface;
	int result;
	if (!findSurface) return FALSE; /* failure... couldn't init function-pointer */
	result = findSurface(surfaceID, NULL, &surfaceHandle);
	if (!result) return FALSE; /* failed to find surface */
	surface = (ManualSurface*)surfaceHandle;	
	if (surface->isLocked) return FALSE; /* can't set pointer while surface is locked */
	surface->ptr = ptr;
	logTrace("Set Surface: %lx Pointer: %" PRIxSQPTR "\n", surfaceID, (sqIntptr_t)ptr);
	return TRUE;
}
