/* Host windows plugin header file
 * tim@sumeru.stanford.edu
 * All sizes are in pixels; convert from OS abstract units as needed
 * windowHandles etc are expected to be SmallInteger valid values
 * windowHandle 1 is the traditional main window */

#define packedXY(x,y) (((x) << 16) | ((y)&0xFFFF))

/* closeWindow: arg is sqIntptr_t windowIndex. Fail (return 0) if anything
 * goes wrong - typically the windowIndex invalid or similar */
extern sqInt closeWindow(sqIntptr_t index);

/* createWindow: takes sqInt width, height and origin x/y plus a char* list of
 * as yet undefined attributes. Returns an sqInt window index or 0 for failure
 * Failure may occur because of an inability to add the window, too many
 * windows already extant (platform dependant), the specified size being
 * unreasonable etc. */
extern sqInt createWindowWidthheightoriginXyattrlength(sqInt w, sqInt h, sqInt x, sqInt y,
char *list, sqInt attributeListLength);

/* ioShowDisplayOnWindow: similar to ioShowDisplay but adds the sqIntptr_t windowIndex
 * Return true if ok, false if not, but not currently checked */
extern sqInt ioShowDisplayOnWindow(unsigned char *dispBitsIndex, sqInt width, sqInt
height, sqInt depth, sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB,
sqIntptr_t windowIndex);

/* ioSizeOfWindow: arg is sqIntptr_t. Return the size of the specified
 * window in (width<<16 || height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowIndex
 * -1 is chosen since itwould correspond to a window size of 64k@64k which
 * I hope is unlikely for some time to come */
extern sqInt ioSizeOfWindow(sqIntptr_t windowIndex);

/* ioSizeOfNativeWindow: arg is void* windowHandle, defined as usqIntptr_t
 * for convenience. Return the size of the specified native window in
 * (width<<16 || height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowHandle
 * -1 is chosen since it would correspond to a window size of +/-32k@+/-32k
 * which it is hoped is unlikely for some time to come */
extern sqInt ioSizeOfNativeWindow(usqIntptr_t windowHandle);

/* as per ioSizeOfNativeWindow, but answers the size of the drawing
 * surface (the inside) of the window.
 */
extern sqInt ioSizeOfNativeDisplay(usqIntptr_t windowHandle);

/* ioSizeOfWindowSetxy: args are sqIntptr_t windowIndex, sqInt w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 || height) format or -1 for failure as above. */
extern sqInt ioSizeOfWindowSetxy(sqIntptr_t windowIndex, sqInt w, sqInt h);

/* ioPositionOfWindow: arg is sqIntptr_t windowIndex. Return the pos of the
 * specified window in (left<<16 || top) format like ioScreenSize.
 * Return -1 (as above) for failure - typically invalid windowIndex */
extern sqInt ioPositionOfWindow(sqIntptr_t windowIndex);

/* ioPositionOfNativeWindow: arg is void* windowHandle, defined as usqIntptr_t
 * for convenience. Return the pos of the specified native window in
 * (left<<16 || top) format like ioScreenSize.
 * Return -1 (as above) for failure - typically invalid windowHandle */
extern sqInt ioPositionOfNativeWindow(usqIntptr_t windowHandle);

/* as per ioPositionOfNativeWindow, but answers the position of the drawing
 * surface (the inside) of the window.
 */
extern sqInt ioPositionOfNativeDisplay(usqIntptr_t windowHandle);

/* ioPositionOfWindowSetxy: args are sqIntptr_t windowIndex, sqInt x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 || top) format or -1 for failure, as above */
extern sqInt ioPositionOfWindowSetxy(sqIntptr_t windowIndex, sqInt x, sqInt y);

/* ioSetTitleOfWindow: args are sqIntptr_t windowIndex, char* newTitle and
 * sqInt size of new title. Fail with -1 if windowIndex is invalid, string is too
long for platform etc. Leave previous title in place on failure */
sqInt ioSetTitleOfWindow(sqIntptr_t windowIndex, char *newTitle, sqInt sizeOfTitle);

/* ioSetIconOfWindow: args are int windowIndex windowIndex, char* iconPath and
 * int size of new logo path. If one of the function is failing, the logo is not set.
 */
extern sqInt ioSetIconOfWindow(sqIntptr_t windowIndex, char *iconPath, sqInt sizeOfPath);

/* ioCloseAllWindows: intended for VM shutdown.
 * Close all the windows that appear to be open.
 * No useful return value since we're getting out of Dodge anyway.
 */
extern sqInt ioCloseAllWindows(void);

/* ioGetWindowHandle: returns the VM window handle.
 */
extern void *ioGetWindowHandle(void);

/* ioPositionOfScreenWorkArea: returns the encoded position of a window.
 */
extern sqInt ioPositionOfScreenWorkArea(sqIntptr_t windowIndex);

/* ioSizeOfScreenWorkArea: returns the encoded size of a window.
 */
extern sqInt ioSizeOfScreenWorkArea(sqIntptr_t windowIndex);

/* ioSetCursorPositionXY: moves manually the position of the cursor.
 */
extern sqInt ioSetCursorPositionXY(long x, long y);
