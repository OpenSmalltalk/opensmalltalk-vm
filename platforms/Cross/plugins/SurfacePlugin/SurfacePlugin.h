#ifndef __SQ_DRAW_SURFACE_H
#define __SQ_DRAW_SURFACE_H
/* v1.0 */
#define SQ_SURFACE_MAJOR 1
#define SQ_SURFACE_MINOR 0

/* Plugins creating their own surfaces must register these using
   the following set of functions. The typedefs are for easier casts. */
typedef long (*fn_getSurfaceFormat)(void * surfaceHandle, long* width, long* height, long* depth, long* isMSB);
typedef long (*fn_lockSurface)(void * surfaceHandle, long *pitch, long x, long y, long w, long h);
typedef long (*fn_unlockSurface)(void * surfaceHandle, long x, long y, long w, long h);
typedef long (*fn_showSurface)(void * surfaceHandle, long x, long y, long w, long h);

typedef struct sqSurfaceDispatch {
	/* Version information. Must be provided by the client
	   so the surface manager can check if certain operations
	   are supported. */
	long majorVersion;
	long minorVersion;

	/* Version 1.0 */
	fn_getSurfaceFormat getSurfaceFormat;
	fn_lockSurface lockSurface;
	fn_unlockSurface unlockSurface;
	fn_showSurface showSurface;
} sqSurfaceDispatch;

/* The functions for sqSurfaceDispatch are:

	long getSurfaceFormat(long handle, long* width, long* height, long* depth, long* isMSB);
		Return general information about the OS drawing surface.
		Return true if successful, false otherwise.

		The returned values describe the basic properties such as
		width, height, depth and LSB vs. MSB pixels.

	long lockSurface(long handle, long *pitch, long x, long y, long w, long h);
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

	long unlockSurface(long handle, long x, long y, long w, long h);
		Unlock the bits of a (possibly modified) surface after BitBlt completed.
		The return value is ignored.

		The arguments provided specify the dirty region of the surface. If the
		surface is unmodified all arguments are set to zero.

	long showSurface(long handle, long x, long y, long w, long h);
		Display the contents of the surface on the actual screen.

		If ioShowSurface() is called the surface in question represents
		a Squeak DisplayScreen.

	FXBlt uses a variant of the above functions which are exported from
	the surface plugin:

	long ioGetSurfaceFormat(long surfaceID, long* width, long* height, long* depth, long* isMSB);
	long ioLockSurface(long surfaceID, long *pitch, long x, long y, long w, long h);
	long ioUnlockSurface(long surfaceID, long x, long y, long w, long h);

	These functions are looked up in the registered surfaces and invoked
	as appropriate. The meaning of all values is exactly the same as for
	the functions specified in sqSurfaceDispatch with the exception that
	the surfaceID represents the 'bits' handle of the Form that is used
	within FXBlt.

	Interpreter itself uses a separate entry point for updating the display

	long ioShowSurface(long surfaceID, long x, long y, long w, long h);

	since the management of deferred updates is currently an intrinsic
	property of the VM (which is bad - deferred updates should be a
	property of the DisplayScreen in question and not of the VM but
	that's the way it is...).

*/

/* The following are the entry points for the surface manager:

	long ioRegisterSurface(long surfaceHandle, sqSurfaceDispatch *fn, long *surfaceID);
		Register a new surface with the given handle and
		the set of surface functions. The new ID is returned
		in surfaceID. Returns true if successful, false 
		otherwise.

	long ioUnregisterSurface(long surfaceID);
		Unregister the surface with the given handle.
		Returns true if successful, false otherwise.

	long ioFindSurface(long surfaceID, sqSurfaceDispatch *fn, long *surfaceHandle);
		Find the surface with the given ID, and, optionally,
		the given set of surface functions. The registered handle
		is returned in surfaceHandle. Return true if successful
		(e.g., the surface has been found), false otherwise.

	The above entry points can be looked up through the interpreter, e.g., using
		interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
	The typedefs below are for easier casts.
*/
typedef long (*fn_ioRegisterSurface)(long surfaceHandle, sqSurfaceDispatch *fn, long *surfaceID);
typedef long (*fn_ioUnregisterSurface)(long surfaceID);
typedef long (*fn_ioFindSurface)(long surfaceID, sqSurfaceDispatch *fn, long *surfaceHandle);

#endif /* __SQ_DRAW_SURFACE_H */
