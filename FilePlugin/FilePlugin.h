/****************************************************************************
*   PROJECT: Common include
*   FILE:    FilePlugin.h
*   CONTENT: 
*
*   AUTHOR:  
*   ADDRESS: 
*   EMAIL:   
*   RCSID:   $Id: FilePlugin.h,v 1.4 2002/01/29 05:18:38 rowledge Exp $
*
*	01/22/2002 JMM change off_t to squeakOffsetFileType
*/
/* File support definitions */

/* squeak file record; see sqFilePrims.c for details */
typedef struct {
	FILE	*file;
	int		sessionID;
	int		writable;
	squeakFileOffsetType		fileSize;
	int		lastOp;  /* 0 = uncommitted, 1 = read, 2 = write */
} SQFile;

/* file i/o */
int sqFileAtEnd(SQFile *f);
int sqFileClose(SQFile *f);
int sqFileDeleteNameSize(int sqFileNameIndex, int sqFileNameSize);
squeakFileOffsetType sqFileGetPosition(SQFile *f);
int sqFileInit(void);
int sqFileShutdown(void);
int sqFileOpen(SQFile *f, int sqFileNameIndex, int sqFileNameSize, int writeFlag);
size_t sqFileReadIntoAt(SQFile *f, size_t count, int byteArrayIndex, size_t startIndex);
int sqFileRenameOldSizeNewSize(int oldNameIndex, int oldNameSize, int newNameIndex, int newNameSize);
int sqFileSetPosition(SQFile *f, squeakFileOffsetType position);
squeakFileOffsetType sqFileSize(SQFile *f);
int sqFileValid(SQFile *f);
size_t sqFileWriteFromAt(SQFile *f, size_t count, int byteArrayIndex, size_t startIndex);
int sqFileFlush(SQFile *f);
int sqFileTruncate(SQFile *f,squeakFileOffsetType offset);
int sqFileThisSession(void);

/* directories */
int dir_Create(char *pathString, int pathStringLength);
int dir_Delete(char *pathString, int pathStringLength);
int dir_Delimitor(void);
int dir_Lookup(char *pathString, int pathStringLength, int index,
	/* outputs: */
	char *name, int *nameLength, int *creationDate, int *modificationDate,
	int *isDirectory, squeakFileOffsetType *sizeIfFile);
int dir_PathToWorkingDir(char *pathName, int pathNameMax);
int dir_SetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator);
int dir_GetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator);
