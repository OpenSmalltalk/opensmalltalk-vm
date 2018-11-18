/*
 * faCommon.h
 *
 * Declerations for FileAttributes platform independent functions.
 */

#include "faConstants.h"
#include "faSupport.h"


sqInt faSetStDirOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faSetStPathOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faCharToByteArray(const char *cBuf, sqInt *byteArrayOop);

