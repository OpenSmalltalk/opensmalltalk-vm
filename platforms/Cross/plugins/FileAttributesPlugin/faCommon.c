/*
 * faCommon.c
 *
 * Provides a number of platform independent functions.
 */

#include "sq.h"
#include "faSupport.h"

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

