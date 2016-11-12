#ifndef __SQ_DRAW_SURFACE_H
#define __SQ_DRAW_SURFACE_H

#include "sqMemoryAccess.h"
/* v1.0 */
#define SQ_SURFACE_MAJOR 1
#define SQ_SURFACE_MINOR 0

/* Plugins creating their own surfaces must register these using
   the following set of functions. The typedefs are for easier casts. */
typedef int (*fn_getSurfaceFormat)(sqIntptr_t surfaceHandle, int* width, int* height, int* depth, int* isMSB);
typedef sqIntptr_t (*fn_lockSurface)(sqIntptr_t surfaceHandle, int *pitch, int x, int y, int w, int h);
typedef int (*fn_unlockSurface)(sqIntptr_t surfaceHandle, int x, int y, int w, int h);
typedef int (*fn_showSurface)(sqIntptr_t surfaceHandle, int x, int y, int w, int h);

typedef struct sqSurfaceDispatch {
	/* Version information. Must be provided by the client
	   so the surface manager can check if certain operations
	   are supported. */
	int majorVersion;
	int minorVersion;

	/* Version 1.0 */
	fn_getSurfaceFormat getSurfaceFormat;
	fn_lockSurface lockSurface;
	fn_unlockSurface unlockSurface;
	fn_showSurface showSurface;
} sqSurfaceDispatch;

/* The functions for sqSurfaceDispatch are:

	int getSurfaceFormat(sqIntptr_t handle, int* width, int* height, int* depth, int* isMSB);
		Return general information about the OS drawing surface.
		Return true if successful, false otherwise.

		The returned values describe the basic properties such as
		width, height, depth and LSB vs. MSB pixels.

	sqIntptr_t lockSurface(sqIntptr_t handle, int *pitch, int x, int y, int w, int h);
		Lock the bits of the surface.
		Return a pointer to the actual surface bits, or NULL on failure.
		If successful, store the pitch of the surface (e.g., the bytes
		per scan line).

		For equal source/dest handles only one locking operation is performed.
		This is to prevent locking of overlapping areas which does not work with
		certain APIs (e.g., DirectDraw prevents locking of overlapping areas). 
		A special case for non-overlapping but equal source/dest handle would 
		be possible but we would have to transfer this information over to 
		unlockSurfaces somehow (currently, only one unlock operation is 
		performed for equal source and dest handles). Also, this would require
		a change in the notion of ioLockSurface() which is right now interpreted
		as a hint and not as a requirement to lock only the specific portion of
		the surface.

		The arguments in ioLockSurface() provide the implementation with
		an explicit hint what area is affected. It can be very useful to
		know the max. affected area beforehand if getting the bits requires expensive
		copy operations (e.g., like a roundtrip to the X server or a glReadPixel op).
		However, the returned pointer *MUST* point to the virtual origin of the surface
		and not to the beginning of the rectangle. The promise made by BitBlt
		is to never access data outside the given rectangle (aligned to 4byte boundaries!)
		so it is okay to return a pointer to the virtual origin that is actually outside
		the valid memory area.

		The area provided in ioLockSurface() is already clipped (e.g., it will always
		be inside the source and dest boundingBox) but it is not aligned to word boundaries
		yet. It is up to the support code to compute accurate alignment if necessary.

	int unlockSurface(sqIntptr_t handle, int x, int y, int w, int h);
		Unlock the bits of a (possibly modified) surface after BitBlt completed.
		The return value is ignored.

		The arguments provided specify the dirty region of the surface. If the
		surface is unmodified all arguments are set to zero.

	int showSurface(sqIntptr_t handle, int x, int y, int w, int h);
		Display the contents of the surface on the actual screen.

		If ioShowSurface() is called the surface in question represents
		a Squeak DisplayScreen.

	FXBlt uses a variant of the above functions which are exported from
	the surface plugin:

	int ioGetSurfaceFormat(int surfaceID, int* width, int* height, int* depth, int* isMSB);
	sqIntptr_t ioLockSurface(int surfaceID, int *pitch, int x, int y, int w, int h);
	int ioUnlockSurface(int surfaceID, int x, int y, int w, int h);

	These functions are looked up in the registered surfaces and invoked
	as appropriate. The meaning of all values is exactly the same as for
	the functions specified in sqSurfaceDispatch with the exception that
	the surfaceID represents the 'bits' handle of the Form that is used
	within FXBlt.

	Interpreter itself uses a separate entry point for updating the display

	int ioShowSurface(int surfaceID, int x, int y, int w, int h);

	since the management of deferred updates is currently an intrinsic
	property of the VM (which is bad - deferred updates should be a
	property of the DisplayScreen in question and not of the VM but
	that's the way it is...).

*/

/* The following are the entry points for the surface manager:

	int ioRegisterSurface(sqIntptr_t surfaceHandle, sqSurfaceDispatch *fn, int *surfaceID);
		Register a new surface with the given handle and
		the set of surface functions. The new ID is returned
		in surfaceID. Returns true if successful, false 
		otherwise.

	int ioUnregisterSurface(int surfaceID);
		Unregister the surface with the given ID.
		Returns true if successful, false otherwise.

	int ioFindSurface(int surfaceID, sqSurfaceDispatch *fn, sqIntptr_t *surfaceHandle);
		Find the surface with the given ID, and, optionally,
		the given set of surface functions. The registered handle
		is returned in surfaceHandle. Return true if successful
		(e.g., the surface has been found), false otherwise.

	The above entry points can be looked up through the interpreter, e.g., using
		interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
	The typedefs below are for easier casts.
*/
typedef int (*fn_ioRegisterSurface)(sqIntptr_t surfaceHandle, sqSurfaceDispatch *fn, int *surfaceID);
typedef int (*fn_ioUnregisterSurface)(int surfaceID);
typedef int (*fn_ioFindSurface)(int surfaceID, sqSurfaceDispatch *fn, sqIntptr_t *surfaceHandle);

#endif /* __SQ_DRAW_SURFACE_H */
