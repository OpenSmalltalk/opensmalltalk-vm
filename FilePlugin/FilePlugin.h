/* File support definitions */

/* squeak file record; see sqFilePrims.c for details */
typedef struct {
	FILE	*file;
	int		sessionID;
	int		writable;
	off_t		fileSize;
	int		lastOp;  /* 0 = uncommitted, 1 = read, 2 = write */
} SQFile;

/* file i/o */
int sqFileAtEnd(SQFile *f);
int sqFileClose(SQFile *f);
int sqFileDeleteNameSize(int sqFileNameIndex, int sqFileNameSize);
off_t sqFileGetPosition(SQFile *f);
int sqFileInit(void);
int sqFileShutdown(void);
int sqFileOpen(SQFile *f, int sqFileNameIndex, int sqFileNameSize, int writeFlag);
size_t sqFileReadIntoAt(SQFile *f, size_t count, int byteArrayIndex, size_t startIndex);
int sqFileRenameOldSizeNewSize(int oldNameIndex, int oldNameSize, int newNameIndex, int newNameSize);
int sqFileSetPosition(SQFile *f, off_t position);
off_t sqFileSize(SQFile *f);
int sqFileValid(SQFile *f);
size_t sqFileWriteFromAt(SQFile *f, size_t count, int byteArrayIndex, size_t startIndex);
int sqFileFlush(SQFile *f);
int sqFileTruncate(SQFile *f,off_t offset);
int sqFileThisSession(void);

/* directories */
int dir_Create(char *pathString, int pathStringLength);
int dir_Delete(char *pathString, int pathStringLength);
int dir_Delimitor(void);
int dir_Lookup(char *pathString, int pathStringLength, int index,
	/* outputs: */
	char *name, int *nameLength, int *creationDate, int *modificationDate,
	int *isDirectory, off_t *sizeIfFile);
int dir_PathToWorkingDir(char *pathName, int pathNameMax);
int dir_SetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator);
int dir_GetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator);

/*** security traps ***/

/* directory access */
int ioCanCreatePathOfSize(char* dirNameIndex, int dirNameSize);
int ioCanListPathOfSize(char* dirNameIndex, int dirNameSize);
int ioCanDeletePathOfSize(char* dirNameIndex, int dirNameSize);

/* file access */
int ioCanOpenFileOfSizeWritable(char* fileNameIndex, int fileNameSize, int writeFlag);
int ioCanDeleteFileOfSize(char* fileNameIndex, int fileNameSize);
int ioCanRenameFileOfSize(char* fileNameIndex, int fileNameSize);

int ioCanGetFileTypeOfSize(char* fileNameIndex, int fileNameSize);
int ioCanSetFileTypeOfSize(char* fileNameIndex, int fileNameSize);

/* top level functions */
int ioDisableFileAccess(void);
int ioHasFileAccess(void);

#ifdef DISABLE_SECURITY
#define ioCanCreatePathOfSize(name, size) 1
#define ioCanListPathOfSize(name, size) 1
#define ioCanDeletePathOfSize(name, size) 1
#define ioCanOpenFileOfSizeWritable(name, size, writeFlag) 1
#define ioCanDeleteFileOfSize(name, size) 1
#define ioCanRenameFileOfSize(name, size) 1
#define ioCanGetFileTypeOfSize(name, size) 1
#define ioCanSetFileTypeOfSize(name, size) 1
#define ioDisableFileAccess() 1
#define ioHasFileAccess() 1
#endif /* DISABLE_SECURITY */

