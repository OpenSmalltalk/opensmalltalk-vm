/* Automatically generated from Squeak on #(19 March 2005 10:08:55 am) */

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

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/
#define DirBadPath 2
#define DirNoMoreEntries 1

/*** Function Prototypes ***/
static int asciiDirectoryDelimiter(void);
#pragma export on
EXPORT(int) fileOpenNamesizewritesecure(char * nameIndex, int nameSize, int writeFlag, int secureFlag);
#pragma export off
int fileRecordSize(void);
SQFile * fileValueOf(int objectPointer);
#pragma export on
EXPORT(const char*) getModuleName(void);
EXPORT(int) getThisSession(void);
#pragma export off
static int halt(void);
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int makeDirEntryNamesizecreateDatemodDateisDirfileSize(char *entryName, int entryNameSize, int createDate, int modifiedDate, int dirFlag, squeakFileOffsetType fileSize);
#pragma export on
EXPORT(int) moduleUnloaded(char * aModuleName);
#pragma export off
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveDirectoryCreate(void);
EXPORT(int) primitiveDirectoryDelete(void);
EXPORT(int) primitiveDirectoryDelimitor(void);
EXPORT(int) primitiveDirectoryGetMacTypeAndCreator(void);
EXPORT(int) primitiveDirectoryLookup(void);
EXPORT(int) primitiveDirectorySetMacTypeAndCreator(void);
EXPORT(int) primitiveDisableFileAccess(void);
EXPORT(int) primitiveFileAtEnd(void);
EXPORT(int) primitiveFileClose(void);
EXPORT(int) primitiveFileDelete(void);
EXPORT(int) primitiveFileFlush(void);
EXPORT(int) primitiveFileGetPosition(void);
EXPORT(int) primitiveFileOpen(void);
EXPORT(int) primitiveFileRead(void);
EXPORT(int) primitiveFileRename(void);
EXPORT(int) primitiveFileSetPosition(void);
EXPORT(int) primitiveFileSize(void);
EXPORT(int) primitiveFileTruncate(void);
EXPORT(int) primitiveFileWrite(void);
EXPORT(int) primitiveHasFileAccess(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) setMacFileTypeAndCreator(char * fileName, char * typeString, char * creatorString);
EXPORT(int) shutdownModule(void);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"FilePlugin 19 March 2005 (i)"
#else
	"FilePlugin 19 March 2005 (e)"
#endif
;
static int sCCPfn;
static int sCDFfn;
static int sCDPfn;
static int sCGFTfn;
static int sCLPfn;
static int sCOFfn;
static int sCRFfn;
static int sCSFTfn;
static int sDFAfn;
static int sHFAfn;


static int asciiDirectoryDelimiter(void) {
	return dir_Delimitor();
}


/*	Open the named file, possibly checking security. Answer the file oop. */

EXPORT(int) fileOpenNamesizewritesecure(char * nameIndex, int nameSize, int writeFlag, int secureFlag) {
    int fileOop;
    int okToOpen;
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
				okToOpen = ((int (*) (char *, int, int)) sCOFfn)(nameIndex, nameSize, writeFlag);
				if (!(okToOpen)) {
					interpreterProxy->primitiveFail();
				}
			}
		}
	}
	if (!(interpreterProxy->failed())) {
		sqFileOpen(file, (int)nameIndex, nameSize, writeFlag);
	}
	return fileOop;
}


/*	Return the size of a Smalltalk file record in bytes. */

int fileRecordSize(void) {
	return sizeof(SQFile);
}


/*	Return a pointer to the first byte of of the file record within the given Smalltalk object, or nil if objectPointer is not a file record. */

SQFile * fileValueOf(int objectPointer) {
	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		interpreterProxy->primitiveFail();
		return null;
	}
	return interpreterProxy->firstIndexableField(objectPointer);
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}


/*	Exported entry point for the VM. */

EXPORT(int) getThisSession(void) {
	return sqFileThisSession();
}

static int halt(void) {
	;
}

EXPORT(int) initialiseModule(void) {
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

static int makeDirEntryNamesizecreateDatemodDateisDirfileSize(char *entryName, int entryNameSize, int createDate, int modifiedDate, int dirFlag, squeakFileOffsetType fileSize) {
    int i;
    int modDateOop;
    int createDateOop;
    char *stringPtr;
    int nameString;
    int fileSizeOop;
    int results;

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

EXPORT(int) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SecurityPlugin")) == 0) {
		sCCPfn = sCDPfn = sCGFTfn = sCLPfn = sCSFTfn = sDFAfn = sCDFfn = sCOFfn = sCRFfn = sHFAfn = 0;
	}
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(int) primitiveDirectoryCreate(void) {
    int dirName;
    char * dirNameIndex;
    int okToCreate;
    int dirNameSize;

	dirName = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(dirName))) {
		return interpreterProxy->primitiveFail();
	}
	dirNameIndex = interpreterProxy->firstIndexableField(dirName);

	/* If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok */

	dirNameSize = interpreterProxy->byteSizeOf(dirName);
	if (sCCPfn != 0) {
		okToCreate =  ((int (*) (char *, int)) sCCPfn)(dirNameIndex, dirNameSize);
		if (!(okToCreate)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_Create((char *) dirNameIndex, dirNameSize))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(1);
}

EXPORT(int) primitiveDirectoryDelete(void) {
    int okToDelete;
    int dirName;
    char * dirNameIndex;
    int dirNameSize;

	dirName = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(dirName))) {
		return interpreterProxy->primitiveFail();
	}
	dirNameIndex = interpreterProxy->firstIndexableField(dirName);

	/* If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok */

	dirNameSize = interpreterProxy->byteSizeOf(dirName);
	if (sCDPfn != 0) {
		okToDelete =  ((int (*) (char *, int)) sCDPfn)(dirNameIndex, dirNameSize);
		if (!(okToDelete)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_Delete((char *) dirNameIndex, dirNameSize))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(1);
}

EXPORT(int) primitiveDirectoryDelimitor(void) {
    int ascii;

	ascii = asciiDirectoryDelimiter();
	if (!((ascii >= 0) && (ascii <= 255))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(1);
	interpreterProxy->push(interpreterProxy->fetchPointerofObject(ascii, interpreterProxy->characterTable()));
}

EXPORT(int) primitiveDirectoryGetMacTypeAndCreator(void) {
    char * creatorStringIndex;
    char * typeStringIndex;
    int fileNameSize;
    int okToGet;
    char * fileNameIndex;
    int fileName;
    int typeString;
    int creatorString;

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
	If 
	not, assume it's ok */

	fileNameSize = interpreterProxy->byteSizeOf(fileName);
	if (sCGFTfn != 0) {
		okToGet =  ((int (*) (char *, int)) sCGFTfn)(fileNameIndex, fileNameSize);
		if (!(okToGet)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_GetMacFileTypeAndCreator(
			(char *) fileNameIndex, fileNameSize,
			(char *) typeStringIndex, (char *) creatorStringIndex))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(3);
}

EXPORT(int) primitiveDirectoryLookup(void) {
    int dirFlag;
    int index;
    int status;
    int pathName;
    int entryNameSize;
    int pathNameSize;
    int okToList;
    char * pathNameIndex;
    int modifiedDate;
    char entryName[256];
    squeakFileOffsetType fileSize;
    int createDate;

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
		okToList =  ((int (*) (char *, int)) sCLPfn)(pathNameIndex, pathNameSize);
	} else {
		okToList = 1;
	}
	if (okToList) {
		status = dir_Lookup(
				(char *) pathNameIndex, pathNameSize, index,
				entryName, &entryNameSize, &createDate, &modifiedDate,
				&dirFlag, &fileSize);
	} else {
		status = DirNoMoreEntries;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	if (status == DirNoMoreEntries) {
		interpreterProxy->pop(3);
		interpreterProxy->push(interpreterProxy->nilObject());
		return null;
	}
	if (status == DirBadPath) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(3);
	interpreterProxy->push(makeDirEntryNamesizecreateDatemodDateisDirfileSize(entryName, entryNameSize, createDate, modifiedDate, dirFlag, fileSize));
}

EXPORT(int) primitiveDirectorySetMacTypeAndCreator(void) {
    char * creatorStringIndex;
    char * typeStringIndex;
    int fileNameSize;
    int okToSet;
    char * fileNameIndex;
    int fileName;
    int typeString;
    int creatorString;

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
	If 
	not, assume it's ok */

	fileNameSize = interpreterProxy->byteSizeOf(fileName);
	if (sCSFTfn != 0) {
		okToSet =  ((int (*) (char *, int)) sCSFTfn)(fileNameIndex, fileNameSize);
		if (!(okToSet)) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(dir_SetMacFileTypeAndCreator(
			(char *) fileNameIndex, fileNameSize,
			(char *) typeStringIndex, (char *) creatorStringIndex))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(3);
}

EXPORT(int) primitiveDisableFileAccess(void) {
	if (sDFAfn != 0) {
		 ((int (*) (void)) sDFAfn)();
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}

EXPORT(int) primitiveFileAtEnd(void) {
    int atEnd;
    SQFile * file;
    int objectPointer;

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

EXPORT(int) primitiveFileClose(void) {
    SQFile * file;
    int objectPointer;

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

EXPORT(int) primitiveFileDelete(void) {
    int nameSize;
    int okToDelete;
    int namePointer;
    char * nameIndex;

	namePointer = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(namePointer))) {
		return interpreterProxy->primitiveFail();
	}
	nameIndex = interpreterProxy->firstIndexableField(namePointer);

	/* If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok */

	nameSize = interpreterProxy->byteSizeOf(namePointer);
	if (sCDFfn != 0) {
		okToDelete =  ((int (*) (char *, int)) sCDFfn)(nameIndex, nameSize);
		if (!(okToDelete)) {
			return interpreterProxy->primitiveFail();
		}
	}
	sqFileDeleteNameSize(((int) nameIndex), nameSize);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}

EXPORT(int) primitiveFileFlush(void) {
    SQFile * file;
    int objectPointer;

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

EXPORT(int) primitiveFileGetPosition(void) {
    squeakFileOffsetType position;
    SQFile * file;
    int objectPointer;

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
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->positive64BitIntegerFor(position));
	}
}

EXPORT(int) primitiveFileOpen(void) {
    int nameSize;
    int filePointer;
    int namePointer;
    char * nameIndex;
    int writeFlag;

	writeFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	namePointer = interpreterProxy->stackValue(1);
	if (!(interpreterProxy->isBytes(namePointer))) {
		return interpreterProxy->primitiveFail();
	}
	nameIndex = interpreterProxy->firstIndexableField(namePointer);
	nameSize = interpreterProxy->byteSizeOf(namePointer);
	filePointer = fileOpenNamesizewritesecure(nameIndex, nameSize, writeFlag, 1);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(3);
		interpreterProxy->push(filePointer);
	}
}

EXPORT(int) primitiveFileRead(void) {
    int bytesRead;
    size_t count;
    int array;
    size_t byteSize;
    char * arrayIndex;
    size_t startIndex;
    SQFile * file;
    int objectPointer;

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
	bytesRead = sqFileReadIntoAt(file, count * byteSize, ((int) arrayIndex), (startIndex - 1) * byteSize);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(5);
		interpreterProxy->pushInteger(bytesRead / byteSize);
	}
}

EXPORT(int) primitiveFileRename(void) {
    int newNameSize;
    char * newNameIndex;
    int okToRename;
    int oldNamePointer;
    char * oldNameIndex;
    int oldNameSize;
    int newNamePointer;

	newNamePointer = interpreterProxy->stackValue(0);
	oldNamePointer = interpreterProxy->stackValue(1);
	if (!((interpreterProxy->isBytes(newNamePointer)) && (interpreterProxy->isBytes(oldNamePointer)))) {
		return interpreterProxy->primitiveFail();
	}
	newNameIndex = interpreterProxy->firstIndexableField(newNamePointer);
	newNameSize = interpreterProxy->byteSizeOf(newNamePointer);
	oldNameIndex = interpreterProxy->firstIndexableField(oldNamePointer);

	/* If the security plugin can be loaded, use it to check for rename 
	permission.
	If not, assume it's ok */

	oldNameSize = interpreterProxy->byteSizeOf(oldNamePointer);
	if (sCRFfn != 0) {
		okToRename =  ((int (*) (char *, int)) sCRFfn)(oldNameIndex, oldNameSize);
		if (!(okToRename)) {
			return interpreterProxy->primitiveFail();
		}
	}
	sqFileRenameOldSizeNewSize(((int) oldNameIndex), oldNameSize, ((int) newNameIndex), newNameSize);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(2);
	}
}

EXPORT(int) primitiveFileSetPosition(void) {
    int sz;
    squeakFileOffsetType newPosition;
    SQFile * file;
    int objectPointer;

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

EXPORT(int) primitiveFileSize(void) {
    squeakFileOffsetType size;
    SQFile * file;
    int objectPointer;

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
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->positive64BitIntegerFor(size));
	}
}

EXPORT(int) primitiveFileTruncate(void) {
    SQFile * file;
    int sz;
    squeakFileOffsetType truncatePosition;
    int objectPointer;

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

EXPORT(int) primitiveFileWrite(void) {
    int bytesWritten;
    size_t count;
    int array;
    size_t byteSize;
    char * arrayIndex;
    size_t startIndex;
    SQFile * file;
    int objectPointer;

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
		bytesWritten = sqFileWriteFromAt(file, count * byteSize, ((int) arrayIndex), (startIndex - 1) * byteSize);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(5);
		interpreterProxy->pushInteger(bytesWritten / byteSize);
	}
}

EXPORT(int) primitiveHasFileAccess(void) {
    int hasAccess;

	if (sHFAfn != 0) {
		hasAccess =  ((int (*) (void)) sHFAfn)();
	} else {
		hasAccess = 1;
	}
	interpreterProxy->pop(1);
	interpreterProxy->pushBool(hasAccess);
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


/*	Exported entry point for the VM. Needed for image saving only and no-op on anything but Macs. */

EXPORT(int) setMacFileTypeAndCreator(char * fileName, char * typeString, char * creatorString) {
	return dir_SetMacFileTypeAndCreator(fileName, strlen(fileName), typeString, creatorString);
}

EXPORT(int) shutdownModule(void) {
	return sqFileShutdown();
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* FilePlugin_exports[][3] = {
	{"FilePlugin", "primitiveHasFileAccess", (void*)primitiveHasFileAccess},
	{"FilePlugin", "primitiveFileFlush", (void*)primitiveFileFlush},
	{"FilePlugin", "primitiveFileTruncate", (void*)primitiveFileTruncate},
	{"FilePlugin", "initialiseModule", (void*)initialiseModule},
	{"FilePlugin", "primitiveFileGetPosition", (void*)primitiveFileGetPosition},
	{"FilePlugin", "primitiveDirectoryCreate", (void*)primitiveDirectoryCreate},
	{"FilePlugin", "fileOpenNamesizewritesecure", (void*)fileOpenNamesizewritesecure},
	{"FilePlugin", "primitiveDirectoryDelimitor", (void*)primitiveDirectoryDelimitor},
	{"FilePlugin", "primitiveDisableFileAccess", (void*)primitiveDisableFileAccess},
	{"FilePlugin", "getModuleName", (void*)getModuleName},
	{"FilePlugin", "primitiveFileDelete", (void*)primitiveFileDelete},
	{"FilePlugin", "primitiveDirectoryDelete", (void*)primitiveDirectoryDelete},
	{"FilePlugin", "primitiveFileSetPosition", (void*)primitiveFileSetPosition},
	{"FilePlugin", "setInterpreter", (void*)setInterpreter},
	{"FilePlugin", "primitiveDirectoryLookup", (void*)primitiveDirectoryLookup},
	{"FilePlugin", "primitiveFileAtEnd", (void*)primitiveFileAtEnd},
	{"FilePlugin", "primitiveDirectorySetMacTypeAndCreator", (void*)primitiveDirectorySetMacTypeAndCreator},
	{"FilePlugin", "primitiveFileClose", (void*)primitiveFileClose},
	{"FilePlugin", "primitiveFileSize", (void*)primitiveFileSize},
	{"FilePlugin", "primitiveFileRename", (void*)primitiveFileRename},
	{"FilePlugin", "shutdownModule", (void*)shutdownModule},
	{"FilePlugin", "primitiveFileOpen", (void*)primitiveFileOpen},
	{"FilePlugin", "setMacFileTypeAndCreator", (void*)setMacFileTypeAndCreator},
	{"FilePlugin", "moduleUnloaded", (void*)moduleUnloaded},
	{"FilePlugin", "primitiveDirectoryGetMacTypeAndCreator", (void*)primitiveDirectoryGetMacTypeAndCreator},
	{"FilePlugin", "getThisSession", (void*)getThisSession},
	{"FilePlugin", "primitiveFileWrite", (void*)primitiveFileWrite},
	{"FilePlugin", "primitiveFileRead", (void*)primitiveFileRead},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

