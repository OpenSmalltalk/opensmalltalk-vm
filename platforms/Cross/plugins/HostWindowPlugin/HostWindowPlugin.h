/* Host windows plugin header file
 * tim@sumeru.stanford.edu
 * All sizes are in pixels; convert from OS abstract units as needed
 * windowHandles etc are expected to be SmallInteger valid values
 * windowHandle 1 is the traditional main window */

/* closeWindow: arg is sqInt windowIndex. Fail (return 0) if anything goes wrong
 * - typically the windowIndex invalid or similar */
extern sqInt closeWindow(sqInt index);

/* createWindow: takes sqInt width, height and origin x/y plus a char* list of
 * as yet undefined attributes. Returns an sqInt window index or 0 for failure
 * Failure may occur because of an inability to add the window, too many
 * windows already extant (platform dependant), the specified size being
 * unreasonable etc. */
extern sqInt createWindowWidthheightoriginXyattrlength(sqInt w, sqInt h, sqInt x, sqInt y,
char * list, sqInt attributeListLength);

/* ioShowDisplayOnWindow: similar to ioShowDisplay but adds the sqInt windowIndex
 * Return true if ok, false if not, but not currently checked */
extern sqInt ioShowDisplayOnWindow( unsigned char * dispBitsIndex, sqInt width, sqInt
height, sqInt depth, sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB,
sqInt windowIndex);

/* ioSizeOfWindow: arg is sqInt windowIndex. Return the size of the specified
 * window in (width<<16 || height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowIndex
 * -1 is chosen since itwould correspond to a window size of 64k@64k which
 * I hope is unlikely for some time to come */
extern sqInt ioSizeOfWindow(sqInt windowIndex);

/* ioSizeOfWindowSetxy: args are sqInt windowIndex, sqInt w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 || height) format or -1 for failure as above. */
extern sqInt ioSizeOfWindowSetxy(sqInt windowIndex, sqInt w, sqInt h);

/* ioPositionOfWindow: arg is sqInt windowIndex. Return the pos of the specified
 * window in (left<<16 || top) format like ioScreenSize.
 * Return -1 (as above) for failure - tpyically invalid windowIndex */
extern sqInt ioPositionOfWindow(sqInt windowIndex);

/* ioPositionOfWindowSetxy: args are sqInt windowIndex, sqInt x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 || top) format or -1 for failure, as above */
extern sqInt ioPositionOfWindowSetxy(sqInt windowIndex, sqInt x, sqInt y);

/* ioSetTitleOfWindow: args are sqInt windowIndex, char* newTitle and
 * sqInt size of new title. Fail with -1 if windowIndex is invalid, string is too
long for platform etc. Leave previous title in place on failure */
sqInt ioSetTitleOfWindow(sqInt windowIndex, char * newTitle, sqInt sizeOfTitle);

/* ioCloseAllWindows: sqIntended for VM shutdown.
 * Close all the windows that appear to be open.
 * No useful return value since we're getting out of Dodge anyway.
 */
extern sqInt ioCloseAllWindows(void);
