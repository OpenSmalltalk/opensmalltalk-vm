/****************************************************************************
*   PROJECT: Common include
*   FILE:    FilePlugin.h
*   CONTENT: 
*
*   AUTHOR:  
*   ADDRESS: 
*   EMAIL:   
*   RCSID:   $Id$
*
*	2005-03-26 IKP fix unaligned accesses to file member
*	2004-06-10 IKP 64-bit cleanliness
*	01/22/2002 JMM change off_t to squeakOffsetFileType
*/
/* File support definitions */

#include "sqMemoryAccess.h"

/* squeak file record; see sqFilePrims.c for details */
typedef struct {
	int			 sessionID;	/* ikp: must be first */
	void			*file;
	int			 writable;
	squeakFileOffsetType	 fileSize;
	int			 lastOp;	/* 0 = uncommitted, 1 = read, 2 = write */
} SQFile;

/* file i/o */

sqInt   sqFileAtEnd(SQFile *f);
sqInt   sqFileClose(SQFile *f);
sqInt   sqFileDeleteNameSize(char* sqFileNameIndex, sqInt sqFileNameSize);
squeakFileOffsetType sqFileGetPosition(SQFile *f);
sqInt   sqFileInit(void);
sqInt   sqFileShutdown(void);
sqInt   sqFileOpen(SQFile *f, char* sqFileNameIndex, sqInt sqFileNameSize, sqInt writeFlag);
size_t  sqFileReadIntoAt(SQFile *f, size_t count, char* byteArrayIndex, size_t startIndex);
sqInt   sqFileRenameOldSizeNewSize(char* oldNameIndex, sqInt oldNameSize, char* newNameIndex, sqInt newNameSize);
sqInt   sqFileSetPosition(SQFile *f, squeakFileOffsetType position);
squeakFileOffsetType sqFileSize(SQFile *f);
sqInt   sqFileValid(SQFile *f);
size_t  sqFileWriteFromAt(SQFile *f, size_t count, char* byteArrayIndex, size_t startIndex);
sqInt   sqFileFlush(SQFile *f);
sqInt   sqFileTruncate(SQFile *f,squeakFileOffsetType offset);
sqInt   sqFileThisSession(void);

/* directories */

sqInt dir_Create(char *pathString, sqInt pathStringLength);
sqInt dir_Delete(char *pathString, sqInt pathStringLength);
sqInt dir_Delimitor(void);
sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
		/* outputs: */
		char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile);
sqInt dir_PathToWorkingDir(char *pathName, sqInt pathNameMax);
sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator);
sqInt dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator);
