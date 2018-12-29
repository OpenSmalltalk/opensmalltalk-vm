/*
 * faCommon.h
 *
 * Declerations for FileAttributes platform independent functions.
 */

#include "faConstants.h"
#include "faSupport.h"

/*
 * fapathptr
 *
 * fapathptr is used to pass a pointer to the faPath between the VM and image.
 * It holds the current VM session ID to prevent stale pointers being used 
 * across VM restarts.
 */
typedef struct fapathptrstruct {
	int	sessionId;
	fapath	*faPath;
	} fapathptr;


sqInt faInitialiseModule();
sqInt faInitSessionId(int *sessionId);
sqInt faValidateSessionId(int sessionId);
sqInt faInvalidateSessionId(int *sessionId);
sqInt faSetStDirOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faSetStPathOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faCharToByteArray(const char *cBuf, sqInt *byteArrayOop);

