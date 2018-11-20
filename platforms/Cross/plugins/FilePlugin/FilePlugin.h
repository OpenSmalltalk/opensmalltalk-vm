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
*	2018-03-06 AKG Rename sqFileFileOpen() & sqFileFdOpen() to 
*	               sqConnectToFile() and sqConnectToFileDescriptor()
*	2018-03-01 AKG add sqFileFileOpen() & sqFileFdOpen()
*	2009-05-15 EEM add stdio flag; reorder SQFile to make it more compact
*	2005-03-26 IKP fix unaligned accesses to file member
*	2004-06-10 IKP 64-bit cleanliness
*	01/22/2002 JMM change off_t to squeakOffsetFileType
*/
/* File support definitions */

#include <sys/types.h>

#ifdef _MSC_VER
typedef int mode_t;
#endif

#include "sqMemoryAccess.h"

/* squeak file record; see sqFilePrims.c for details */
typedef struct {
  int			 sessionID;	/* ikp: must be first */
  void			*file;
#if defined(ACORN)
// ACORN has to have 'lastOp' as at least a 32 bit field in order to work
  int lastOp; // actually used to save file position
  char writable;
  char lastChar;
  char isStdioStream;
#else
  char			 writable;
  char			 lastOp; /* 0 = uncommitted, 1 = read, 2 = write */
  char			 lastChar;
  char			 isStdioStream;
#endif
} SQFile;

/* file i/o */

sqInt   sqFileAtEnd(SQFile *f);
sqInt   sqFileClose(SQFile *f);
sqInt   sqFileDeleteNameSize(char *sqFileName, sqInt sqFileNameSize);
squeakFileOffsetType sqFileGetPosition(SQFile *f);
sqInt   sqFileInit(void);
sqInt   sqFileShutdown(void);
sqInt   sqFileOpen(SQFile *f, char *sqFileName, sqInt sqFileNameSize, sqInt writeFlag);
sqInt   sqFileOpenNew(SQFile *f, char *sqFileName, sqInt sqFileNameSize, sqInt *exists);
sqInt   sqConnectToFileDescriptor(SQFile *f, int fd, sqInt writeFlag);
sqInt   sqConnectToFile(SQFile *f, void *file, sqInt writeFlag);
size_t  sqFileReadIntoAt(SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex);
sqInt   sqFileRenameOldSizeNewSize(char *sqOldName, sqInt sqOldNameSize, char *sqNewName, sqInt sqNewNameSize);
sqInt   sqFileSetPosition(SQFile *f, squeakFileOffsetType position);
squeakFileOffsetType sqFileSize(SQFile *f);
sqInt   sqFileValid(SQFile *f);
size_t  sqFileWriteFromAt(SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex);
sqInt   sqFileFlush(SQFile *f);
sqInt   sqFileSync(SQFile *f);
sqInt   sqFileTruncate(SQFile *f,squeakFileOffsetType offset);
sqInt   sqFileThisSession(void);
sqInt   sqFileStdioHandlesInto(SQFile files[3]);
sqInt   sqFileDescriptorType(int fdNum);

/* directories */

sqInt dir_Create(char *pathString, sqInt pathStringLength);
sqInt dir_Delete(char *pathString, sqInt pathStringLength);
sqInt dir_Delimitor(void);
sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
		/* outputs: */
		char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink);
sqInt dir_EntryLookup(char *pathString, sqInt pathStringLength, char *nameString, sqInt nameStringLength,
		/* outputs: */
		char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink);
sqInt dir_PathToWorkingDir(char *pathName, sqInt pathNameMax);
sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator);
sqInt dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator);
