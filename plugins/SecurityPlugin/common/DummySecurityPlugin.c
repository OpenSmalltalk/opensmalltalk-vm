#include "config.h"

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
#include "sqConfig.h"			/* Configuration options */
#include "sqVirtualMachine.h"	/*  The virtual machine proxy definition */
#include "sqPlatformSpecific.h"	/* Platform specific definitions */

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
# undef EXPORT
# define EXPORT(returnType) static returnType
#endif

#include "sqMemoryAccess.h"


/*** Function Prototypes ***/
EXPORT(const char*) getModuleName(void);
EXPORT(sqInt) initialiseModule(void);
EXPORT(sqInt) primitiveCanWriteImage(void);
EXPORT(sqInt) primitiveDisableImageWrite(void);
EXPORT(sqInt) primitiveGetSecureUserDirectory(void);
EXPORT(sqInt) primitiveGetUntrustedUserDirectory(void);
EXPORT(sqInt) secCanConnectToPort(sqInt addr, sqInt port);
EXPORT(sqInt) secCanCreatePathOfSize(char *dirName, sqInt dirNameSize);
EXPORT(sqInt) secCanCreateSocketOfType(sqInt netType, sqInt socketType);
EXPORT(sqInt) secCanDeleteFileOfSize(char *fileName, sqInt fileNameSize);
EXPORT(sqInt) secCanDeletePathOfSize(char *dirName, sqInt dirNameSize);
EXPORT(sqInt) secCanGetFileTypeOfSize(char *fileName, sqInt fileNameSize);
EXPORT(sqInt) secCanListPathOfSize(char *pathName, sqInt pathNameSize);
EXPORT(sqInt) secCanOpenAsyncFileOfSizeWritable(char *fileName, sqInt fileNameSize, sqInt writeFlag);
EXPORT(sqInt) secCanOpenFileOfSizeWritable(char *fileName, sqInt fileNameSize, sqInt writeFlag);
EXPORT(sqInt) secCanRenameFileOfSize(char *fileName, sqInt fileNameSize);
EXPORT(sqInt) secCanRenameImage(void);
EXPORT(sqInt) secCanSetFileTypeOfSize(char *fileName, sqInt fileNameSize);
EXPORT(sqInt) secCanWriteImage(void);
EXPORT(sqInt) secCanListenOnPort(sqInt socket, sqInt port);
EXPORT(sqInt) secDisableFileAccess(void);
EXPORT(sqInt) secDisableSocketAccess(void);
EXPORT(sqInt) secHasEnvironmentAccess(void);
EXPORT(sqInt) secHasFileAccess(void);
EXPORT(sqInt) secHasSocketAccess(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine *anInterpreter);


/*** Variables ***/

#if !defined(SQUEAK_BUILTIN_PLUGIN)
static sqInt (*classString)(void);
static sqInt (*failed)(void);
static void * (*firstIndexableField)(sqInt oop);
static sqInt (*instantiateClassindexableSize)(sqInt classPointer, sqInt size);
static sqInt (*pop)(sqInt nItems);
static sqInt (*popthenPush)(sqInt nItems, sqInt oop);
static sqInt (*primitiveFail)(void);
static sqInt (*pushBool)(sqInt trueOrFalse);
#else /* !defined(SQUEAK_BUILTIN_PLUGIN) */
extern sqInt classString(void);
extern sqInt failed(void);
extern void * firstIndexableField(sqInt oop);
extern sqInt instantiateClassindexableSize(sqInt classPointer, sqInt size);
extern sqInt pop(sqInt nItems);
extern sqInt popthenPush(sqInt nItems, sqInt oop);
extern sqInt primitiveFail(void);
extern sqInt pushBool(sqInt trueOrFalse);
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SecurityPlugin DUMMY (i)"
#else
	"SecurityPlugin DUMMY (e)"
#endif
;


EXPORT(const char*)
getModuleName(void){
	return moduleName;
}

EXPORT(sqInt) initialiseModule(void){ return 0;}

EXPORT(sqInt) primitiveCanWriteImage(void){
	pop(1);
	pushBool(1);
	return 0;
}

EXPORT(sqInt) primitiveDisableImageWrite(void){ return 0;}
EXPORT(sqInt) primitiveGetSecureUserDirectory(void){ return primitiveFail();}
EXPORT(sqInt) primitiveGetUntrustedUserDirectory(void){ return primitiveFail();}

EXPORT(sqInt) secCanConnectToPort(sqInt addr, sqInt port){
	return 1;
}

EXPORT(sqInt) secCanCreatePathOfSize(char *dirName, sqInt dirNameSize){
	return 1;
}

EXPORT(sqInt) secCanCreateSocketOfType(sqInt netType, sqInt socketType){
	return 1;
}

EXPORT(sqInt)
secCanDeleteFileOfSize(char *fileName, sqInt fileNameSize){
	return 1;
}

EXPORT(sqInt)
secCanDeletePathOfSize(char *dirName, sqInt dirNameSize){
	return 1;
}

EXPORT(sqInt)
secCanGetFileTypeOfSize(char *fileName, sqInt fileNameSize){
	return 1;
}

EXPORT(sqInt)
secCanListPathOfSize(char *pathName, sqInt pathNameSize){
	return 1;
}

EXPORT(sqInt)
secCanOpenAsyncFileOfSizeWritable(char *fileName, sqInt fileNameSize, sqInt writeFlag){
	return 1;
}

EXPORT(sqInt)
secCanOpenFileOfSizeWritable(char *fileName, sqInt fileNameSize, sqInt writeFlag){
	return 1;
}

EXPORT(sqInt)
secCanRenameFileOfSize(char *fileName, sqInt fileNameSize){
	return 1;
}

EXPORT(sqInt)
secCanRenameImage(void){
	return 1;
}

EXPORT(sqInt)
secCanSetFileTypeOfSize(char *fileName, sqInt fileNameSize){
	return 1;
}

EXPORT(sqInt)
secCanWriteImage(void){
	return 1;
}

EXPORT(sqInt)
secCanListenOnPort(sqInt socket, sqInt port){
	return 1;
}

EXPORT(sqInt)
secDisableFileAccess(void){
	return 1;
}

EXPORT(sqInt)
secDisableSocketAccess(void){
	return 1;
}

EXPORT(sqInt)
secHasEnvironmentAccess(void){
	return 1;
}

EXPORT(sqInt)
secHasFileAccess(void){
	return 1;
}

EXPORT(sqInt)
secHasSocketAccess(void){
	return 1;
}


EXPORT(sqInt)
setInterpreter(struct VirtualMachine *anInterpreter)
{
    sqInt ok;

	interpreterProxy = anInterpreter;
	ok = ((interpreterProxy->majorVersion()) == (VM_PROXY_MAJOR))
	 && ((interpreterProxy->minorVersion()) >= (VM_PROXY_MINOR));
	if (ok) {

#if !defined(SQUEAK_BUILTIN_PLUGIN)
		classString = interpreterProxy->classString;
		failed = interpreterProxy->failed;
		firstIndexableField = interpreterProxy->firstIndexableField;
		instantiateClassindexableSize = interpreterProxy->instantiateClassindexableSize;
		pop = interpreterProxy->pop;
		popthenPush = interpreterProxy->popthenPush;
		primitiveFail = interpreterProxy->primitiveFail;
		pushBool = interpreterProxy->pushBool;
#endif /* !defined(SQUEAK_BUILTIN_PLUGIN) */
	}
	return ok;
}


#ifdef SQUEAK_BUILTIN_PLUGIN

static char _m[] = "SecurityPlugin";
void* SecurityPlugin_exports[][3] = {
	{(void*)_m, "getModuleName", (void*)getModuleName},
	{(void*)_m, "initialiseModule", (void*)initialiseModule},
	{(void*)_m, "primitiveCanWriteImage\000\377", (void*)primitiveCanWriteImage},
	{(void*)_m, "primitiveDisableImageWrite\000\377", (void*)primitiveDisableImageWrite},
	{(void*)_m, "primitiveGetSecureUserDirectory\000\377", (void*)primitiveGetSecureUserDirectory},
	{(void*)_m, "primitiveGetUntrustedUserDirectory\000\377", (void*)primitiveGetUntrustedUserDirectory},
	{(void*)_m, "secCanConnectToPort", (void*)secCanConnectToPort},
	{(void*)_m, "secCanCreatePathOfSize", (void*)secCanCreatePathOfSize},
	{(void*)_m, "secCanCreateSocketOfType", (void*)secCanCreateSocketOfType},
	{(void*)_m, "secCanDeleteFileOfSize", (void*)secCanDeleteFileOfSize},
	{(void*)_m, "secCanDeletePathOfSize", (void*)secCanDeletePathOfSize},
	{(void*)_m, "secCanGetFileTypeOfSize", (void*)secCanGetFileTypeOfSize},
	{(void*)_m, "secCanListPathOfSize", (void*)secCanListPathOfSize},
	{(void*)_m, "secCanOpenAsyncFileOfSizeWritable", (void*)secCanOpenAsyncFileOfSizeWritable},
	{(void*)_m, "secCanOpenFileOfSizeWritable", (void*)secCanOpenFileOfSizeWritable},
	{(void*)_m, "secCanRenameFileOfSize", (void*)secCanRenameFileOfSize},
	{(void*)_m, "secCanRenameImage\000\377", (void*)secCanRenameImage},
	{(void*)_m, "secCanSetFileTypeOfSize", (void*)secCanSetFileTypeOfSize},
	{(void*)_m, "secCanWriteImage\000\377", (void*)secCanWriteImage},
	{(void*)_m, "secCanListenOnPort", (void*)secCanListenOnPort},
	{(void*)_m, "secDisableFileAccess\000\377", (void*)secDisableFileAccess},
	{(void*)_m, "secDisableSocketAccess\000\377", (void*)secDisableSocketAccess},
	{(void*)_m, "secHasEnvironmentAccess\000\377", (void*)secHasEnvironmentAccess},
	{(void*)_m, "secHasFileAccess\000\377", (void*)secHasFileAccess},
	{(void*)_m, "secHasSocketAccess\000\377", (void*)secHasSocketAccess},
	{(void*)_m, "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};

#else /* ifdef SQ_BUILTIN_PLUGIN */


#endif /* ifdef SQ_BUILTIN_PLUGIN */
