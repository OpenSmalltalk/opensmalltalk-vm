/* Automatically generated from Squeak on #(19 March 2005 10:09:03 am) */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif
#include "SecurityPlugin.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveCanWriteImage(void);
EXPORT(int) primitiveDisableImageWrite(void);
EXPORT(int) primitiveGetSecureUserDirectory(void);
EXPORT(int) primitiveGetUntrustedUserDirectory(void);
EXPORT(int) secCanListenOnPort(int socket, int port);
EXPORT(int) secCanConnectToPort(int addr, int port);
EXPORT(int) secCanCreateSocketOfType(int netType, int socketType);
EXPORT(int) secCanCreatePathOfSize(char * dirName, int dirNameSize);
EXPORT(int) secCanDeleteFileOfSize(char * fileName, int fileNameSize);
EXPORT(int) secCanDeletePathOfSize(char * dirName, int dirNameSize);
EXPORT(int) secCanGetFileTypeOfSize(char * fileName, int fileNameSize);
EXPORT(int) secCanListPathOfSize(char * pathName, int pathNameSize);
EXPORT(int) secCanOpenAsyncFileOfSizeWritable(char * fileName, int fileNameSize, int writeFlag);
EXPORT(int) secCanOpenFileOfSizeWritable(char * fileName, int fileNameSize, int writeFlag);
EXPORT(int) secCanRenameFileOfSize(char * fileName, int fileNameSize);
EXPORT(int) secCanRenameImage(void);
EXPORT(int) secCanSetFileTypeOfSize(char * fileName, int fileNameSize);
EXPORT(int) secCanWriteImage(void);
EXPORT(int) secDisableFileAccess(void);
EXPORT(int) secDisableSocketAccess(void);
EXPORT(int) secHasFileAccess(void);
EXPORT(int) secHasSocketAccess(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SecurityPlugin 19 March 2005 (i)"
#else
	"SecurityPlugin 19 March 2005 (e)"
#endif
;



/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static int halt(void) {
	;
}

EXPORT(int) initialiseModule(void) {
	return ioInitSecurity();
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(int) primitiveCanWriteImage(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushBool(ioCanWriteImage());
}

EXPORT(int) primitiveDisableImageWrite(void) {
	ioDisableImageWrite();
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}


/*	Primitive. Return the secure directory for the current user. */

EXPORT(int) primitiveGetSecureUserDirectory(void) {
    int i;
    char * dirName;
    int dirLen;
    int dirOop;
    char * dirPtr;

	dirName = ioGetSecureUserDirectory();
	if ((dirName == null) || (interpreterProxy->failed())) {
		return interpreterProxy->primitiveFail();
	}
	dirLen = strlen(dirName);
	dirOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), dirLen);
	if (interpreterProxy->failed()) {
		return null;
	}
	dirPtr = interpreterProxy->firstIndexableField(dirOop);
	for (i = 0; i <= (dirLen - 1); i += 1) {
		dirPtr[i] = (dirName[i]);
	}
	interpreterProxy->pop(1);
	interpreterProxy->push(dirOop);
}


/*	Primitive. Return the untrusted user directory name. */

EXPORT(int) primitiveGetUntrustedUserDirectory(void) {
    int i;
    char * dirName;
    int dirLen;
    int dirOop;
    char * dirPtr;

	dirName = ioGetUntrustedUserDirectory();
	if ((dirName == null) || (interpreterProxy->failed())) {
		return interpreterProxy->primitiveFail();
	}
	dirLen = strlen(dirName);
	dirOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), dirLen);
	if (interpreterProxy->failed()) {
		return null;
	}
	dirPtr = interpreterProxy->firstIndexableField(dirOop);
	for (i = 0; i <= (dirLen - 1); i += 1) {
		dirPtr[i] = (dirName[i]);
	}
	interpreterProxy->pop(1);
	interpreterProxy->push(dirOop);
}

EXPORT(int) secCanListenOnPort(int socket, int port) {
	return ioCanListenOnPort(socket, port);
}

EXPORT(int) secCanConnectToPort(int addr, int port) {
	return ioCanConnectToPort(addr, port);
}

EXPORT(int) secCanCreateSocketOfType(int netType, int socketType) {
	return ioCanCreateSocketOfType(netType, socketType);
}

EXPORT(int) secCanCreatePathOfSize(char * dirName, int dirNameSize) {
	return ioCanCreatePathOfSize(dirName, dirNameSize);
}

EXPORT(int) secCanDeleteFileOfSize(char * fileName, int fileNameSize) {
	return ioCanDeleteFileOfSize(fileName, fileNameSize);
}

EXPORT(int) secCanDeletePathOfSize(char * dirName, int dirNameSize) {
	return ioCanDeletePathOfSize(dirName, dirNameSize);
}

EXPORT(int) secCanGetFileTypeOfSize(char * fileName, int fileNameSize) {
	return ioCanGetFileTypeOfSize(fileName, fileNameSize);
}

EXPORT(int) secCanListPathOfSize(char * pathName, int pathNameSize) {
	return ioCanListPathOfSize(pathName, pathNameSize);
}

EXPORT(int) secCanOpenAsyncFileOfSizeWritable(char * fileName, int fileNameSize, int writeFlag) {
	return ioCanOpenAsyncFileOfSizeWritable(fileName, fileNameSize, writeFlag);
}

EXPORT(int) secCanOpenFileOfSizeWritable(char * fileName, int fileNameSize, int writeFlag) {
	return ioCanOpenFileOfSizeWritable(fileName, fileNameSize, writeFlag);
}

EXPORT(int) secCanRenameFileOfSize(char * fileName, int fileNameSize) {
	return ioCanRenameFileOfSize(fileName, fileNameSize);
}

EXPORT(int) secCanRenameImage(void) {
	return ioCanRenameImage();
}

EXPORT(int) secCanSetFileTypeOfSize(char * fileName, int fileNameSize) {
	return ioCanSetFileTypeOfSize(fileName, fileNameSize);
}

EXPORT(int) secCanWriteImage(void) {
	return ioCanWriteImage();
}

EXPORT(int) secDisableFileAccess(void) {
	return ioDisableFileAccess();
}

EXPORT(int) secDisableSocketAccess(void) {
	return ioDisableSocketAccess();
}

EXPORT(int) secHasFileAccess(void) {
	return ioHasFileAccess();
}

EXPORT(int) secHasSocketAccess(void) {
	return ioHasSocketAccess();
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter) {
    int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* SecurityPlugin_exports[][3] = {
	{"SecurityPlugin", "secCanSetFileTypeOfSize", (void*)secCanSetFileTypeOfSize},
	{"SecurityPlugin", "secCanCreateSocketOfType", (void*)secCanCreateSocketOfType},
	{"SecurityPlugin", "secHasSocketAccess", (void*)secHasSocketAccess},
	{"SecurityPlugin", "secCanWriteImage", (void*)secCanWriteImage},
	{"SecurityPlugin", "secCanGetFileTypeOfSize", (void*)secCanGetFileTypeOfSize},
	{"SecurityPlugin", "initialiseModule", (void*)initialiseModule},
	{"SecurityPlugin", "secCanListPathOfSize", (void*)secCanListPathOfSize},
	{"SecurityPlugin", "getModuleName", (void*)getModuleName},
	{"SecurityPlugin", "secCanRenameFileOfSize", (void*)secCanRenameFileOfSize},
	{"SecurityPlugin", "setInterpreter", (void*)setInterpreter},
	{"SecurityPlugin", "secCanListenOnPort", (void*)secCanListenOnPort},
	{"SecurityPlugin", "secCanRenameImage", (void*)secCanRenameImage},
	{"SecurityPlugin", "secHasFileAccess", (void*)secHasFileAccess},
	{"SecurityPlugin", "secCanConnectToPort", (void*)secCanConnectToPort},
	{"SecurityPlugin", "primitiveDisableImageWrite", (void*)primitiveDisableImageWrite},
	{"SecurityPlugin", "secCanCreatePathOfSize", (void*)secCanCreatePathOfSize},
	{"SecurityPlugin", "secDisableFileAccess", (void*)secDisableFileAccess},
	{"SecurityPlugin", "secDisableSocketAccess", (void*)secDisableSocketAccess},
	{"SecurityPlugin", "secCanOpenFileOfSizeWritable", (void*)secCanOpenFileOfSizeWritable},
	{"SecurityPlugin", "primitiveCanWriteImage", (void*)primitiveCanWriteImage},
	{"SecurityPlugin", "primitiveGetUntrustedUserDirectory", (void*)primitiveGetUntrustedUserDirectory},
	{"SecurityPlugin", "primitiveGetSecureUserDirectory", (void*)primitiveGetSecureUserDirectory},
	{"SecurityPlugin", "secCanDeletePathOfSize", (void*)secCanDeletePathOfSize},
	{"SecurityPlugin", "secCanDeleteFileOfSize", (void*)secCanDeleteFileOfSize},
	{"SecurityPlugin", "secCanOpenAsyncFileOfSizeWritable", (void*)secCanOpenAsyncFileOfSizeWritable},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

