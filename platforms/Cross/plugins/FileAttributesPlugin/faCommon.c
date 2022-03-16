/*
 * faCommon.c
 *
 * Provides a number of platform independent functions for FileAttributesPlugin.
 */

#include "sq.h"
#include "faCommon.h"

extern struct VirtualMachine * interpreterProxy;
int	vmSessionId = 0;
sqInt nilOop, falseOop, trueOop;


/*
 * faInitialiseModule
 *
 * Initialise global data for the FileAttributesPlugin.
 *
 * This function must be called only once each each time the VM is run.
 */
sqInt faInitialiseModule()
{
#if 0
	if (vmSessionId == 0)
		return 0;
#endif
	vmSessionId = interpreterProxy->getThisSessionID();
	/* Since these three never move it's cheaper to cache them */
	nilOop = interpreterProxy->nilObject();
	falseOop = interpreterProxy->falseObject();
	trueOop = interpreterProxy->trueObject();
	return 1;
}



/*
 * faInitSessionId
 *
 * Initialise the supplied session.
 */
sqInt faInitSessionId(int *sessionId)
{
	*sessionId = vmSessionId;
	return FA_SUCCESS;
}



/*
 * faValidateSessionId
 *
 * Check that the supplied faPath structure looks valid.
 *
 * Currently this is just checking that the sessionId is correct.
 */
sqInt faValidateSessionId(int sessionId)
{
	return sessionId == vmSessionId;
}



/*
 * faInvalidateSessionId
 *
 * Mark the supplied faPath structure as invalid.
 */
sqInt faInvalidateSessionId(int *sessionId)
{
	*sessionId = 0;
	return FA_SUCCESS;
}



sqInt faSetStDirOop(fapath *aFaPath, sqInt pathNameOop)
{
int	len;
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



