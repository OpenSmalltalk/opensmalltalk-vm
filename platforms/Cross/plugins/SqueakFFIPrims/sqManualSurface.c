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
	sqInt width;
	sqInt height;
	sqInt rowPitch;
	sqInt depth;
	sqInt isMSB;
	void *ptr;
	sqInt isLocked;
} ManualSurface;

/* Create the dispatch-table that SurfacePlugin will use to interact with
   instances of "struct ManualSurface" */
static int manualSurfaceGetFormat(sqIntptr_t, sqInt *, sqInt *, sqInt *, sqInt *);
static sqIntptr_t manualSurfaceLock(sqIntptr_t, sqInt *, sqInt, sqInt, sqInt, sqInt);
static int manualSurfaceUnlock(sqIntptr_t, sqInt, sqInt, sqInt, sqInt);
static int manualSurfaceShow(sqIntptr_t, sqInt, sqInt, sqInt, sqInt);
static sqSurfaceDispatch manualSurfaceDispatch = {
  1,
  0,
  manualSurfaceGetFormat,
  manualSurfaceLock,
  manualSurfaceUnlock,
  manualSurfaceShow
};

/* sqSurfaceDispatch functions *****************************************************************************/

int
manualSurfaceGetFormat(sqIntptr_t surfaceArg, sqInt *width, sqInt *height, sqInt *depth, sqInt *isMSB)
{
	ManualSurface* surface = (ManualSurface *)surfaceArg;
	*width = surface->width;
	*height = surface->height;
	*depth = surface->depth;
	*isMSB = surface->isMSB;
	DPRINTF(("Getting Surface Format: %" PRIxSQPTR " %ld %ld %ld %ld\n", (sqIntptr_t) surface, *width, *height, *depth, *isMSB));
	return 1;
}

sqIntptr_t
manualSurfaceLock(sqIntptr_t surfaceArg, sqInt *pitch, sqInt x, sqInt y, sqInt w, sqInt h)
{
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
	DPRINTF(("Locked Surface: %" PRIxSQPTR " Input Rect: %ld %ld %ld %ld  Row Pitch: %ld\n", (sqIntptr_t) surface, x, y, w, h, *pitch));
	return (sqIntptr_t)(surface->ptr);
}

int
manualSurfaceUnlock(sqIntptr_t surfaceArg, sqInt x, sqInt y, sqInt w, sqInt h)
{
	ManualSurface* surface = (ManualSurface *)surfaceArg;
    surface->isLocked = 0;
	DPRINTF(("Unlocked Surface: %" PRIxSQPTR " Rect: %ld %ld %ld %ld\n", (sqIntptr_t) surface, x, y, w, h));
	return 1;	
}

int
manualSurfaceShow(sqIntptr_t surfaceArg, sqInt x, sqInt y, sqInt w, sqInt h) { /* Unsupported */ return 0; }

/* primitive interface functions (i.e. called from Squeak) *********************************************/

/* Answer non-negative surfaceID if successful, and -1 for failure. */
int
createManualSurface(sqInt width, sqInt height, sqInt rowPitch, sqInt depth, sqInt isMSB)
{
	ManualSurface* newSurface;
	int surfaceID, result;
	
	if (width < 0
	 || height < 0
	 || rowPitch < (width * depth)
	 || depth < 1
	 || depth > 32
	 || !registerSurface)
		return -1;
	
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

int
destroyManualSurface(int surfaceID)
{
	if (!unregisterSurface) return 0; /* failure... couldn't init function-pointer */
	return unregisterSurface(surfaceID);
}

int
setManualSurfacePointer(int surfaceID, void* ptr)
{
	ManualSurface *surface;
	if (!findSurface)
		return FALSE; /* failure... couldn't init function-pointer */
	if (!findSurface(surfaceID, NULL, (sqIntptr_t *)&surface))
		return FALSE; /* failed to find surface */
	if (surface->isLocked)
		return FALSE; /* can't set pointer while surface is locked */
	surface->ptr = ptr;
	DPRINTF(("Set Surface: %lx Pointer: %" PRIxSQPTR "\n", surfaceID, (sqIntptr_t)ptr));
	return TRUE;
}
