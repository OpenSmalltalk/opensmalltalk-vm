/* Automatically generated from Squeak on an Array(10 November 2008 3:51:23 pm)
by VMMaker 3.8b6
 */

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
#include "FilePlugin.h"

#include "sqMemoryAccess.h"


/*** Constants ***/
#define DirBadPath 2
#define DirNoMoreEntries 1

/*** Function Prototypes ***/
static sqInt asciiDirectoryDelimiter(void);
#pragma export on
EXPORT(sqInt) fileOpenNamesizewritesecure(char * nameIndex, sqInt nameSize, sqInt writeFlag, sqInt secureFlag);
#pragma export off
sqInt fileRecordSize(void);
SQFile * fileValueOf(sqInt objectPointer);
static VirtualMachine * getInterpreter(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
EXPORT(sqInt) getThisSession(void);
#pragma export off
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) initialiseModule(void);
#pragma export off
static sqInt makeDirEntryNamesizecreateDatemodDateisDirfileSize(char * entryName, sqInt entryNameSize, sqInt createDate, sqInt modifiedDate, sqInt dirFlag, squeakFileOffsetType  fileSize);
#pragma export on
EXPORT(sqInt) moduleUnloaded(char * aModuleName);
#pragma export off
static sqInt msg(char * s);
#pragma export on
EXPORT(sqInt) primitiveDirectoryCreate(void);
EXPORT(sqInt) primitiveDirectoryDelete(void);
EXPORT(sqInt) primitiveDirectoryDelimitor(void);
EXPORT(sqInt) primitiveDirectoryGetMacTypeAndCreator(void);
EXPORT(sqInt) primitiveDirectoryLookup(void);
EXPORT(sqInt) primitiveDirectorySetMacTypeAndCreator(void);
EXPORT(sqInt) primitiveDisableFileAccess(void);
EXPORT(sqInt) primitiveFileAtEnd(void);
EXPORT(sqInt) primitiveFileClose(void);
EXPORT(sqInt) primitiveFileDelete(void);
EXPORT(sqInt) primitiveFileFlush(void);
EXPORT(sqInt) primitiveFileGetPosition(void);
EXPORT(sqInt) primitiveFileOpen(void);
EXPORT(sqInt) primitiveFileRead(void);
EXPORT(sqInt) primitiveFileRename(void);
EXPORT(sqInt) primitiveFileSetPosition(void);
EXPORT(sqInt) primitiveFileSize(void);
EXPORT(sqInt) primitiveFileTruncate(void);
EXPORT(sqInt) primitiveFileWrite(void);
EXPORT(sqInt) primitiveHasFileAccess(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(sqInt) setMacFileTypeAndCreator(char * fileName, char * typeString, char * creatorString);
EXPORT(sqInt) shutdownModule(void);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"FilePlugin 10 November 2008 (i)"
#else
	"FilePlugin 10 November 2008 (e)"
#endif
;
static void * sCCPfn;
static void * sCDFfn;
static void * sCDPfn;
static void * sCGFTfn;
static void * sCLPfn;
static void * sCOFfn;
static void * sCRFfn;
static void * sCSFTfn;
static void * sDFAfn;
static void * sHFAfn;


static sqInt asciiDirectoryDelimiter(void) {
	return dir_Delimitor();
}


/*	Open the named file, possibly checking security. Answer the file oop. */

EXPORT(sqInt) fileOpenNamesizewritesecure(char * nameIndex, sqInt nameSize, sqInt writeFlag, sqInt secureFlag) {
    sqInt fileOop;
    sqInt okToOpen;
    SQFile * file;

	fileOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if (!((interpreterProxy->isBytes(fileOop)) && ((interpreterProxy->byteSizeOf(fileOop)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(fileOop);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		if (secureFlag) {
			if (sCOFfn != 0) {
				okToOpen = ((sqInt (*) (char *, sqInt, sqInt)) sCOFfn)(nameIndex, nameSize, writeFlag);
				if (!(okToOpen)) {
					interpreterProxy->primitiveFail();
				}
			}
		}
	}
	if (!(interpreterProxy->failed())) {
		sqFileOpen(file, nameIndex, nameSize, writeFlag);
	}
	return fileOop;
}


/*	Return the size of a Smalltalk file record in bytes. */

sqInt fileRecordSize(void) {
	return sizeof(SQFile);
}


/*	Return a pointer to the first byte of of the file record within the given Smalltalk object, or nil if objectPointer is not a file record. */

SQFile * fileValueOf(sqInt objectPointer) {
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		return null;
	}
	return interpreterProxy->firstIndexableField(objectPointer);
}


/*	Note: This is coded so that plugins can be run from Squeak. */

static VirtualMachine * getInterpreter(void) {
	return interpreterProxy;
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}


/*	Exported entry point for the VM. Only used by AsynchFilePlugin and needs to be reowrked now we have a VM global session Id capability */

EXPORT(sqInt) getThisSession(void) {
	return sqFileThisSession();
}

static sqInt halt(void) {
	;
}

EXPORT(sqInt) initialiseModule(void) {
	sCCPfn = interpreterProxy->ioLoadFunctionFrom("secCanCreatePathOfSize", "SecurityPlugin");
	sCDPfn = interpreterProxy->ioLoadFunctionFrom("secCanDeletePathOfSize", "SecurityPlugin");
	sCGFTfn = interpreterProxy->ioLoadFunctionFrom("secCanGetFileTypeOfSize", "SecurityPlugin");
	sCLPfn = interpreterProxy->ioLoadFunctionFrom("secCanListPathOfSize", "SecurityPlugin");
	sCSFTfn = interpreterProxy->ioLoadFunctionFrom("secCanSetFileTypeOfSize", "SecurityPlugin");
	sDFAfn = interpreterProxy->ioLoadFunctionFrom("secDisableFileAccess", "SecurityPlugin");
	sCDFfn = interpreterProxy->ioLoadFunctionFrom("secCanDeleteFileOfSize", "SecurityPlugin");
	sCOFfn = interpreterProxy->ioLoadFunctionFrom("secCanOpenFileOfSizeWritable", "SecurityPlugin");
	sCRFfn = interpreterProxy->ioLoadFunctionFrom("secCanRenameFileOfSize", "SecurityPlugin");
	sHFAfn = interpreterProxy->ioLoadFunctionFrom("secHasFileAccess", "SecurityPlugin");
	return sqFileInit();
}

static sqInt makeDirEntryNamesizecreateDatemodDateisDirfileSize(char * entryName, sqInt entryNameSize, sqInt createDate, sqInt modifiedDate, sqInt dirFlag, squeakFileOffsetType  fileSize) {
    sqInt i;
    sqInt modDateOop;
    sqInt createDateOop;
    char * stringPtr;
    sqInt nameString;
    sqInt fileSizeOop;
    sqInt results;

	interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 5));
	interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), entryNameSize));
	interpreterProxy->pushRemappableOop(interpreterProxy->positive32BitIntegerFor(createDate));
	interpreterProxy->pushRemappableOop(interpreterProxy->positive32BitIntegerFor(modifiedDate));
	interpreterProxy->pushRemappableOop(interpreterProxy->positive64BitIntegerFor(fileSize));
	fileSizeOop = interpreterProxy->popRemappableOop();
	modDateOop = interpreterProxy->popRemappableOop();
	createDateOop = interpreterProxy->popRemappableOop();
	nameString = interpreterProxy->popRemappableOop();

	/* copy name into Smalltalk string */

	results = interpreterProxy->popRemappableOop();
	stringPtr = interpreterProxy->firstIndexableField(nameString);
	for (i = 0; i <= (entryNameSize - 1); i += 1) {
		stringPtr[i] = (entryName[i]);
	}
	interpreterProxy->storePointerofObjectwithValue(0, results, nameString);
	interpreterProxy->storePointerofObjectwithValue(1, results, createDateOop);
	interpreterProxy->storePointerofObjectwithValue(2, results, modDateOop);
	if (dirFlag) {
		interpreterProxy->storePointerofObjectwithValue(3, results, interpreterProxy->trueObject());
	} else {
		interpreterProxy->storePointerofObjectwithValue(3, results, interpreterProxy->falseObject());
	}
	interpreterProxy->storePointerofObjectwithValue(4, results, fileSizeOop);
	return results;
}


/*	The module with the given name was just unloaded.
	Make sure we have no dangling references. */

EXPORT(sqInt) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SecurityPlugin")) == 0) {
		sCCPfn = sCDPfn = sCGFTfn = sCLPfn = sCSFTfn = sDFAfn = sCDFfn = sCOFfn = sCRFfn = sHFAfn = 0;
	}
}

static sqInt msg(char * s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(sqInt) primitiveDirectoryCreate(void) {
    sqInt dirName;
    char * dirNameIndex;
    sqInt okToCreate;
    sqInt dirNameSize;

	dirName = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(dirName))) {
		return interpreterProxy->primitiveFail();
	}
	dirNameIndex = interpreterProxy->firstIndexableField(dirName);

	/* If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok */

	dirNameSize = interpreterProxy->byteSizeOf(dirName);
	if (sCCPfn != 0) {
		okToCreate =  ((sqInt (*)(char *, sqInt))sCCPfn)(dirNameIndex, dirNameSize);
		if (!(okToCreate)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_Create(dirNameIndex, dirNameSize))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(1);
}

EXPORT(sqInt) primitiveDirectoryDelete(void) {
    sqInt okToDelete;
    sqInt dirName;
    char * dirNameIndex;
    sqInt dirNameSize;

	dirName = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(dirName))) {
		return interpreterProxy->primitiveFail();
	}
	dirNameIndex = interpreterProxy->firstIndexableField(dirName);

	/* If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok */

	dirNameSize = interpreterProxy->byteSizeOf(dirName);
	if (sCDPfn != 0) {
		okToDelete =  ((sqInt (*)(char *, sqInt))sCDPfn)(dirNameIndex, dirNameSize);
		if (!(okToDelete)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_Delete(dirNameIndex, dirNameSize))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(1);
}

EXPORT(sqInt) primitiveDirectoryDelimitor(void) {
    sqInt ascii;

	ascii = asciiDirectoryDelimiter();
	if (!((ascii >= 0) && (ascii <= 255))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(1);
	interpreterProxy->push(interpreterProxy->fetchPointerofObject(ascii, interpreterProxy->characterTable()));
}

EXPORT(sqInt) primitiveDirectoryGetMacTypeAndCreator(void) {
    char * creatorStringIndex;
    char * typeStringIndex;
    sqInt fileNameSize;
    sqInt okToGet;
    char * fileNameIndex;
    sqInt fileName;
    sqInt typeString;
    sqInt creatorString;

	creatorString = interpreterProxy->stackValue(0);
	typeString = interpreterProxy->stackValue(1);
	fileName = interpreterProxy->stackValue(2);
	if (!((interpreterProxy->isBytes(creatorString)) && ((interpreterProxy->byteSizeOf(creatorString)) == 4))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->isBytes(typeString)) && ((interpreterProxy->byteSizeOf(typeString)) == 4))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(fileName))) {
		return interpreterProxy->primitiveFail();
	}
	creatorStringIndex = interpreterProxy->firstIndexableField(creatorString);
	typeStringIndex = interpreterProxy->firstIndexableField(typeString);
	fileNameIndex = interpreterProxy->firstIndexableField(fileName);

	/* If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok */

	fileNameSize = interpreterProxy->byteSizeOf(fileName);
	if (sCGFTfn != 0) {
		okToGet =  ((sqInt (*)(char *, sqInt))sCGFTfn)(fileNameIndex, fileNameSize);
		if (!(okToGet)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_GetMacFileTypeAndCreator(fileNameIndex, fileNameSize, typeStringIndex, creatorStringIndex))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(3);
}

EXPORT(sqInt) primitiveDirectoryLookup(void) {
    sqInt dirFlag;
    sqInt index;
    sqInt status;
    sqInt pathName;
    sqInt entryNameSize;
    sqInt pathNameSize;
    sqInt okToList;
    char * pathNameIndex;
    sqInt modifiedDate;
    char entryName[256];
    squeakFileOffsetType fileSize;
    sqInt createDate;

	index = interpreterProxy->stackIntegerValue(0);
	pathName = interpreterProxy->stackValue(1);
	if (!(interpreterProxy->isBytes(pathName))) {
		return interpreterProxy->primitiveFail();
	}
	pathNameIndex = interpreterProxy->firstIndexableField(pathName);

	/* If the security plugin can be loaded, use it to check for permission. 
	If not, assume it's ok */

	pathNameSize = interpreterProxy->byteSizeOf(pathName);
	if (sCLPfn != 0) {
		okToList = ((sqInt (*)(char *, sqInt))sCLPfn)(pathNameIndex, pathNameSize);
	} else {
		okToList = 1;
	}
	if (okToList) {
		status = dir_Lookup(pathNameIndex, pathNameSize, index,
												entryName, &entryNameSize, &createDate,
												&modifiedDate, &dirFlag, &fileSize);
	} else {
		status = DirNoMoreEntries;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	if (status == DirNoMoreEntries) {
		interpreterProxy->popthenPush(3, interpreterProxy->nilObject());
		return null;
	}
	if (status == DirBadPath) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->popthenPush(3, makeDirEntryNamesizecreateDatemodDateisDirfileSize(entryName, entryNameSize, createDate, modifiedDate, dirFlag, fileSize));
}

EXPORT(sqInt) primitiveDirectorySetMacTypeAndCreator(void) {
    char * creatorStringIndex;
    char * typeStringIndex;
    sqInt fileNameSize;
    sqInt okToSet;
    char * fileNameIndex;
    sqInt fileName;
    sqInt typeString;
    sqInt creatorString;

	creatorString = interpreterProxy->stackValue(0);
	typeString = interpreterProxy->stackValue(1);
	fileName = interpreterProxy->stackValue(2);
	if (!((interpreterProxy->isBytes(creatorString)) && ((interpreterProxy->byteSizeOf(creatorString)) == 4))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->isBytes(typeString)) && ((interpreterProxy->byteSizeOf(typeString)) == 4))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(fileName))) {
		return interpreterProxy->primitiveFail();
	}
	creatorStringIndex = interpreterProxy->firstIndexableField(creatorString);
	typeStringIndex = interpreterProxy->firstIndexableField(typeString);
	fileNameIndex = interpreterProxy->firstIndexableField(fileName);

	/* If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok */

	fileNameSize = interpreterProxy->byteSizeOf(fileName);
	if (sCSFTfn != 0) {
		okToSet =  ((sqInt (*)(char *, sqInt))sCSFTfn)(fileNameIndex, fileNameSize);
		if (!(okToSet)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_SetMacFileTypeAndCreator(fileNameIndex, fileNameSize,typeStringIndex, creatorStringIndex))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(3);
}

EXPORT(sqInt) primitiveDisableFileAccess(void) {
	if (sDFAfn != 0) {
		 ((sqInt (*)(void))sDFAfn)();
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}

EXPORT(sqInt) primitiveFileAtEnd(void) {
    sqInt atEnd;
    SQFile * file;
    sqInt objectPointer;

	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(0);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		atEnd = sqFileAtEnd(file);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(2);
		interpreterProxy->pushBool(atEnd);
	}
}

EXPORT(sqInt) primitiveFileClose(void) {
    SQFile * file;
    sqInt objectPointer;

	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(0);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		sqFileClose(file);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}

EXPORT(sqInt) primitiveFileDelete(void) {
    sqInt nameSize;
    sqInt okToDelete;
    sqInt namePointer;
    char * nameIndex;

	namePointer = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(namePointer))) {
		return interpreterProxy->primitiveFail();
	}
	nameIndex = interpreterProxy->firstIndexableField(namePointer);

	/* If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok */

	nameSize = interpreterProxy->byteSizeOf(namePointer);
	if (sCDFfn != 0) {
		okToDelete =  ((sqInt (*)(char *, sqInt))sCDFfn)(nameIndex, nameSize);
		if (!(okToDelete)) {
			return interpreterProxy->primitiveFail();
		}
	}
	sqFileDeleteNameSize(nameIndex, nameSize);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}

EXPORT(sqInt) primitiveFileFlush(void) {
    SQFile * file;
    sqInt objectPointer;

	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(0);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		sqFileFlush(file);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}

EXPORT(sqInt) primitiveFileGetPosition(void) {
    squeakFileOffsetType position;
    SQFile * file;
    sqInt objectPointer;

	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(0);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		position = sqFileGetPosition(file);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->popthenPush(2, interpreterProxy->positive64BitIntegerFor(position));
	}
}

EXPORT(sqInt) primitiveFileOpen(void) {
    sqInt nameSize;
    sqInt filePointer;
    sqInt namePointer;
    char * nameIndex;
    sqInt writeFlag;

	writeFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	namePointer = interpreterProxy->stackValue(1);
	if (!(interpreterProxy->isBytes(namePointer))) {
		return interpreterProxy->primitiveFail();
	}
	nameIndex = interpreterProxy->firstIndexableField(namePointer);
	nameSize = interpreterProxy->byteSizeOf(namePointer);
	filePointer = fileOpenNamesizewritesecure(nameIndex, nameSize, writeFlag, 1);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->popthenPush(3, filePointer);
	}
}

EXPORT(sqInt) primitiveFileRead(void) {
    sqInt bytesRead;
    size_t count;
    sqInt array;
    size_t byteSize;
    char * arrayIndex;
    size_t startIndex;
    SQFile * file;
    sqInt objectPointer;

	count = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(0));
	startIndex = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(1));
	array = interpreterProxy->stackValue(2);
	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(3);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->isWordsOrBytes(array))) {
		return interpreterProxy->primitiveFail();
	}
	if (interpreterProxy->isWords(array)) {
		byteSize = 4;
	} else {
		byteSize = 1;
	}
	if (!((startIndex >= 1) && (((startIndex + count) - 1) <= (interpreterProxy->slotSizeOf(array))))) {
		return interpreterProxy->primitiveFail();
	}

	/* Note: adjust startIndex for zero-origin indexing */

	arrayIndex = interpreterProxy->firstIndexableField(array);
	bytesRead = sqFileReadIntoAt(file, count * byteSize, arrayIndex, (startIndex - 1) * byteSize);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->popthenPush(5, (((bytesRead / byteSize) << 1) | 1));
	}
}

EXPORT(sqInt) primitiveFileRename(void) {
    sqInt newNameSize;
    char * newNameIndex;
    sqInt okToRename;
    sqInt oldNamePointer;
    char * oldNameIndex;
    sqInt oldNameSize;
    sqInt newNamePointer;

	newNamePointer = interpreterProxy->stackValue(0);
	oldNamePointer = interpreterProxy->stackValue(1);
	if (!((interpreterProxy->isBytes(newNamePointer)) && (interpreterProxy->isBytes(oldNamePointer)))) {
		return interpreterProxy->primitiveFail();
	}
	newNameIndex = interpreterProxy->firstIndexableField(newNamePointer);
	newNameSize = interpreterProxy->byteSizeOf(newNamePointer);
	oldNameIndex = interpreterProxy->firstIndexableField(oldNamePointer);

	/* If the security plugin can be loaded, use it to check for rename permission.
	If not, assume it's ok */

	oldNameSize = interpreterProxy->byteSizeOf(oldNamePointer);
	if (sCRFfn != 0) {
		okToRename =  ((sqInt (*)(char *, sqInt))sCRFfn)(oldNameIndex, oldNameSize);
		if (!(okToRename)) {
			return interpreterProxy->primitiveFail();
		}
	}
	sqFileRenameOldSizeNewSize(oldNameIndex, oldNameSize, newNameIndex, newNameSize);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(2);
	}
}

EXPORT(sqInt) primitiveFileSetPosition(void) {
    sqInt sz;
    squeakFileOffsetType newPosition;
    SQFile * file;
    sqInt objectPointer;

	if (!(((interpreterProxy->stackValue(0)) & 1))) {
		sz = sizeof(squeakFileOffsetType);
		if ((interpreterProxy->byteSizeOf(interpreterProxy->stackValue(0))) > sz) {
			return interpreterProxy->primitiveFail();
		}
	}
	newPosition = interpreterProxy->positive64BitValueOf(interpreterProxy->stackValue(0));
	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(1);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		sqFileSetPosition(file, newPosition);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(2);
	}
}

EXPORT(sqInt) primitiveFileSize(void) {
    squeakFileOffsetType size;
    SQFile * file;
    sqInt objectPointer;

	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(0);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		size = sqFileSize(file);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->popthenPush(2, interpreterProxy->positive64BitIntegerFor(size));
	}
}


/*	ftruncate is not an ansi function so we have a macro to point to a suitable platform implementation */

EXPORT(sqInt) primitiveFileTruncate(void) {
    SQFile * file;
    sqInt sz;
    squeakFileOffsetType truncatePosition;
    sqInt objectPointer;

	if (!(((interpreterProxy->stackValue(0)) & 1))) {
		sz = sizeof(squeakFileOffsetType);
		if ((interpreterProxy->byteSizeOf(interpreterProxy->stackValue(0))) > sz) {
			return interpreterProxy->primitiveFail();
		}
	}
	truncatePosition = interpreterProxy->positive64BitValueOf(interpreterProxy->stackValue(0));
	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(1);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->failed())) {
		sqFileTruncate(file, truncatePosition);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(2);
	}
}

EXPORT(sqInt) primitiveFileWrite(void) {
    sqInt bytesWritten;
    size_t count;
    sqInt array;
    size_t byteSize;
    char * arrayIndex;
    size_t startIndex;
    SQFile * file;
    sqInt objectPointer;

	count = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(0));
	startIndex = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(1));
	array = interpreterProxy->stackValue(2);
	/* begin fileValueOf: */
	objectPointer = interpreterProxy->stackValue(3);
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
	file = interpreterProxy->firstIndexableField(objectPointer);
l1:	/* end fileValueOf: */;
	if (!(interpreterProxy->isWordsOrBytes(array))) {
		return interpreterProxy->primitiveFail();
	}
	if (interpreterProxy->isWords(array)) {
		byteSize = 4;
	} else {
		byteSize = 1;
	}
	if (!((startIndex >= 1) && (((startIndex + count) - 1) <= (interpreterProxy->slotSizeOf(array))))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->failed())) {

		/* Note: adjust startIndex for zero-origin indexing */

		arrayIndex = interpreterProxy->firstIndexableField(array);
		bytesWritten = sqFileWriteFromAt(file, count * byteSize, arrayIndex, (startIndex - 1) * byteSize);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->popthenPush(5, (((bytesWritten / byteSize) << 1) | 1));
	}
}

EXPORT(sqInt) primitiveHasFileAccess(void) {
    sqInt hasAccess;

	if (sHFAfn != 0) {
		hasAccess =  ((sqInt (*)(void))sHFAfn)();
	} else {
		hasAccess = 1;
	}
	interpreterProxy->pop(1);
	interpreterProxy->pushBool(hasAccess);
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter) {
    sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}


/*	Exported entry point for the VM. Needed for image saving only and no-op on anything but Macs. */

EXPORT(sqInt) setMacFileTypeAndCreator(char * fileName, char * typeString, char * creatorString) {
	return dir_SetMacFileTypeAndCreator(fileName, strlen(fileName), typeString, creatorString);
}

EXPORT(sqInt) shutdownModule(void) {
	return sqFileShutdown();
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* FilePlugin_exports[][3] = {
	{"FilePlugin", "primitiveFileClose", (void*)primitiveFileClose},
	{"FilePlugin", "primitiveDirectoryGetMacTypeAndCreator", (void*)primitiveDirectoryGetMacTypeAndCreator},
	{"FilePlugin", "shutdownModule", (void*)shutdownModule},
	{"FilePlugin", "primitiveHasFileAccess", (void*)primitiveHasFileAccess},
	{"FilePlugin", "primitiveFileTruncate", (void*)primitiveFileTruncate},
	{"FilePlugin", "primitiveDirectoryDelete", (void*)primitiveDirectoryDelete},
	{"FilePlugin", "setInterpreter", (void*)setInterpreter},
	{"FilePlugin", "primitiveFileRead", (void*)primitiveFileRead},
	{"FilePlugin", "fileOpenNamesizewritesecure", (void*)fileOpenNamesizewritesecure},
	{"FilePlugin", "primitiveFileGetPosition", (void*)primitiveFileGetPosition},
	{"FilePlugin", "getModuleName", (void*)getModuleName},
	{"FilePlugin", "primitiveFileDelete", (void*)primitiveFileDelete},
	{"FilePlugin", "primitiveFileFlush", (void*)primitiveFileFlush},
	{"FilePlugin", "primitiveDisableFileAccess", (void*)primitiveDisableFileAccess},
	{"FilePlugin", "primitiveFileOpen", (void*)primitiveFileOpen},
	{"FilePlugin", "primitiveDirectoryDelimitor", (void*)primitiveDirectoryDelimitor},
	{"FilePlugin", "primitiveDirectorySetMacTypeAndCreator", (void*)primitiveDirectorySetMacTypeAndCreator},
	{"FilePlugin", "primitiveFileWrite", (void*)primitiveFileWrite},
	{"FilePlugin", "moduleUnloaded", (void*)moduleUnloaded},
	{"FilePlugin", "primitiveFileSize", (void*)primitiveFileSize},
	{"FilePlugin", "primitiveFileAtEnd", (void*)primitiveFileAtEnd},
	{"FilePlugin", "initialiseModule", (void*)initialiseModule},
	{"FilePlugin", "primitiveFileRename", (void*)primitiveFileRename},
	{"FilePlugin", "primitiveFileSetPosition", (void*)primitiveFileSetPosition},
	{"FilePlugin", "getThisSession", (void*)getThisSession},
	{"FilePlugin", "setMacFileTypeAndCreator", (void*)setMacFileTypeAndCreator},
	{"FilePlugin", "primitiveDirectoryCreate", (void*)primitiveDirectoryCreate},
	{"FilePlugin", "primitiveDirectoryLookup", (void*)primitiveDirectoryLookup},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

