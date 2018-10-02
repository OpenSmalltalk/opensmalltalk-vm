/*
 * faCommon.c
 *
 * Provides a number of platform independent functions for FileAttributesPlugin.
 */

#include "sq.h"
#include "faCommon.h"

extern struct VirtualMachine * interpreterProxy;


sqInt faSetStDirOop(fapath *aFaPath, sqInt pathNameOop)
{
int		len;
char	*pathName;


	len = interpreterProxy->stSizeOf(pathNameOop);
	pathName = interpreterProxy->arrayValueOf(pathNameOop);
	return faSetStDir(aFaPath, pathName, len);
}



sqInt faSetStPathOop(fapath *aFaPath, sqInt pathNameOop)
{
int		len;
char	*pathName;


	len = interpreterProxy->stSizeOf(pathNameOop);
	pathName = interpreterProxy->arrayValueOf(pathNameOop);
	return faSetStPath(aFaPath, pathName, len);
}



/*
 * faCharToByteArray
 *
 * Copy the supplied C string to a newly allocated ByteArray
 */
sqInt faCharToByteArray(const char *cBuf, sqInt *byteArrayOop)
{
unsigned char *byteArrayPtr;
sqInt len;
sqInt newByteArray;


	/* We never return strings longer than PATH_MAX */
	len = strlen(cBuf);
	if (len >= FA_PATH_MAX) {
		return -1 /* stringTooLong */;
	}
	newByteArray = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), len);
	if (!(newByteArray)) {
		return interpreterProxy->primitiveFailFor(PrimErrNoMemory);
	}
	byteArrayPtr = interpreterProxy->arrayValueOf(newByteArray);
	memcpy(byteArrayPtr, cBuf, len);
	byteArrayOop[0] = newByteArray;
	return 0;
}



