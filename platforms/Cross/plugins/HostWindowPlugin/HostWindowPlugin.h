/* Host windows plugin header file
 * tim@sumeru.stanford.edu
 * All sizes are in pixels; convert from OS abstract units as needed
 * windowHandles etc are expected to be SmallInteger valid values
 * windowHandle 1 is the traditional main window */

/* closeWindow: arg is int windowIndex. Fail (return 0) if anything goes wrong
 * - typically the windowIndex invalid or similar */
extern int closeWindow(int index);

/* createWindow: takes int width, height and origin x/y plus a char* list of
 * as yet undefined attributes. Returns an int window index or 0 for failure
 * Failure may occur because of an inability to add the window, too many
 * windows already extant (platform dependant), the specified size being
 * unreasonable etc. */
extern int createWindowWidthheightoriginXyattrlength(int w, int h, int x, int y,
char * list, int attributeListLength);

/* ioShowDisplayOnWindow: similar to ioShowDisplay but adds the int windowIndex
 * Return true if ok, false if not, but not currently checked */
extern int ioShowDisplayOnWindow( unsigned* dispBitsIndex, int width, int
height, int depth, int affectedL, int affectedR, int affectedT, int affectedB,
int windowIndex);

/* ioSizeOfWindow: arg is int windowIndex. Return the size of the specified
 * window in (width<<16 || height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowIndex
 * -1 is chosen since itwould correspond to a window size of 64k@64k which
 * I hope is unlikely for some time to come */
extern int ioSizeOfWindow(int windowIndex);

/* ioSizeOfWindowSetxy: args are int windowIndex, int w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 || height) format or -1 for failure as above. */
extern int ioSizeOfWindowSetxy(int windowIndex, int w, int h);

/* ioPositionOfWindow: arg is int windowIndex. Return the pos of the specified
 * window in (left<<16 || top) format like ioScreenSize.
 * Return -1 (as above) for failure - typically invalid windowIndex */
extern int ioPositionOfWindow(int windowIndex);

/* ioPositionOfWindowSetxy: args are int windowIndex, int x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 || top) format or -1 for failure, as above */
extern int ioPositionOfWindowSetxy(int windowIndex, int x, int y);

/* ioSetTitleOfWindow: args are int windowIndex, char* newTitle and
 * int size of new title. Fail with -1 if windowIndex is invalid, string is too
 * long for platform etc. Leave previous title in place on failure */
extern int ioSetTitleOfWindow(int windowIndex, char * newTitle, int sizeOfTitle);

/* ioCloseAllWindows: intended for VM shutdown.
 * Close all the windows that appear to be open.
 * No useful return value since we're getting out of Dodge anyway. */
extern int ioCloseAllWindows(void);
