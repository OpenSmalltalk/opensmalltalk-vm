/* The basic prim code for file operations. See also the platform specific
* files typically named 'sq{blah}Directory.c' for details of the directory
* handling code. Note that the win32 platform #defines NO_STD_FILE_SUPPORT
* and thus bypasses this file
*/
                                                      
#include "sq.h"
#ifndef NO_STD_FILE_SUPPORT
#include "FilePlugin.h"
#include <unistd.h>
/***
	The state of a file is kept in the following structure,
	which is stored directly in a Squeak bytes object.
	NOTE: The Squeak side is responsible for creating an
	object with enough room to store sizeof(SQFile) bytes.

	The session ID is used to detect stale file objects--
	files that were still open when an image was written.
	The file pointer of such files is meaningless.

	Files are always opened in binary mode; Smalltalk code
	does (or someday will do) line-end conversion if needed.

	Writeable files are opened read/write. The stdio spec
	requires that a positioning operation be done when
	switching between reading and writing of a read/write
	filestream. The lastOp field records whether the last
	operation was a read or write operation, allowing this
	positioning operation to be done automatically if needed.

	typedef struct {
		File	*file;
		int		sessionID;
		int		writable;
		off_t		fileSize;  //JMM Nov 8th 2001 64bits we hope
		int		lastOp;  // 0 = uncommitted, 1 = read, 2 = write //
	} SQFile;

***/

/*** Constants ***/
#define UNCOMMITTED	0
#define READ_OP		1
#define WRITE_OP	2

#ifndef SEEK_SET
#define SEEK_SET	0
#define SEEK_CUR	1
#define SEEK_END	2
#endif

/*** Variables ***/
int thisSession = 0;
extern struct VirtualMachine * interpreterProxy;


int sqFileAtEnd(SQFile *f) {
	/* Return true if the file's read/write head is at the end of the file. */

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	return ftello(f->file) == f->fileSize;
}

int sqFileClose(SQFile *f) {
	/* Close the given file. */

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	fclose(f->file);
	f->file = NULL;
	f->sessionID = 0;
	f->writable = false;
	f->fileSize = 0;
	f->lastOp = UNCOMMITTED;
}

int sqFileDeleteNameSize(int sqFileNameIndex, int sqFileNameSize) {
	char cFileName[1000];
	int err;

	if (sqFileNameSize >= 1000) {
		return interpreterProxy->success(false);
	}

	/* copy the file name into a null-terminated C string */
	sqFilenameFromString(cFileName, sqFileNameIndex, sqFileNameSize);

	err = remove(cFileName);
	if (err) {
		return interpreterProxy->success(false);
	}
}

off_t sqFileGetPosition(SQFile *f) {
	/* Return the current position of the file's read/write head. */

	off_t position;

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	position = ftello(f->file);
	if (position < 0) return interpreterProxy->success(false);
	return position;
}

int sqFileInit(void) {
	/* Create a session ID that is unlikely to be repeated.
	   Zero is never used for a valid session number.
	   Should be called once at startup time.
	*/

	thisSession = ioLowResMSecs() + time(NULL);
	if (thisSession == 0) thisSession = 1;	/* don't use 0 */
	return 1;
}

int sqFileShutdown(void) {
	return 1;
}

int sqFileOpen(SQFile *f, int sqFileNameIndex, int sqFileNameSize, int writeFlag) {
	/* Opens the given file using the supplied sqFile structure
	   to record its state. Fails with no side effects if f is
	   already open. Files are always opened in binary mode;
	   Squeak must take care of any line-end character mapping.
	*/

	char cFileName[1001];

	/* don't open an already open file */
	if (sqFileValid(f)) return interpreterProxy->success(false);

	/* copy the file name into a null-terminated C string */
	if (sqFileNameSize > 1000) {
		return interpreterProxy->success(false);
	}
        sqFilenameFromStringOpen(cFileName, sqFileNameIndex, sqFileNameSize);

	if (writeFlag) {
		/* First try to open an existing file read/write: */
		f->file = fopen(cFileName, "r+b");
		if (f->file == NULL) {
			/* Previous call fails if file does not exist. In that case,
			   try opening it in write mode to create a new, empty file.
			*/
			f->file = fopen(cFileName, "w+b");
			if (f->file != NULL) {
			    char type[4],creator[4];
				dir_GetMacFileTypeAndCreator((char *)sqFileNameIndex, sqFileNameSize, type, creator);
				if (strncmp(type,"BINA",4) == 0 || strncmp(type,"????",4) == 0 || *(long *)type == 0 ) 
				    dir_SetMacFileTypeAndCreator((char *)sqFileNameIndex, sqFileNameSize,"TEXT","R*ch");	
			}
		}
		f->writable = true;
	} else {
		f->file = fopen(cFileName, "rb");
		f->writable = false;
	}

	if (f->file == NULL) {
		f->sessionID = 0;
		f->fileSize = 0;
		return interpreterProxy->success(false);
	} else {
		f->sessionID = thisSession;
		/* compute and cache file size */
		fseeko(f->file, 0, SEEK_END);
		f->fileSize = ftello(f->file);
		fseeko(f->file, 0, SEEK_SET);
	}
	f->lastOp = UNCOMMITTED;
}

size_t sqFileReadIntoAt(SQFile *f, size_t count, int byteArrayIndex, size_t startIndex) {
	/* Read count bytes from the given file into byteArray starting at
	   startIndex. byteArray is the address of the first byte of a
	   Squeak bytes object (e.g. String or ByteArray). startIndex
	   is a zero-based index; that is a startIndex of 0 starts writing
	   at the first byte of byteArray.
	*/

	char *dst;
	size_t bytesRead;

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	if (f->writable && (f->lastOp == WRITE_OP)) fseeko(f->file, 0, SEEK_CUR);  /* seek between writing and reading */
	dst = (char *) (byteArrayIndex + startIndex);
	bytesRead = fread(dst, 1, count, f->file);
	f->lastOp = READ_OP;
	return bytesRead;
}

int sqFileRenameOldSizeNewSize(int oldNameIndex, int oldNameSize, int newNameIndex, int newNameSize) {
	char cOldName[1000], cNewName[1000];
	int err;

	if ((oldNameSize >= 1000) || (newNameSize >= 1000)) {
		return interpreterProxy->success(false);
	}

	/* copy the file names into null-terminated C strings */
	sqFilenameFromString(cOldName, oldNameIndex, oldNameSize);

	sqFilenameFromString(cNewName, newNameIndex, newNameSize);

	err = rename(cOldName, cNewName);
	if (err) {
		return interpreterProxy->success(false);
	}
}

int sqFileSetPosition(SQFile *f, off_t position) {
	/* Set the file's read/write head to the given position. */

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	fseeko(f->file, position, SEEK_SET);
	f->lastOp = UNCOMMITTED;
}

off_t sqFileSize(SQFile *f) {
	/* Return the length of the given file. */

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	return f->fileSize;
}

int sqFileFlush(SQFile *f) {
	/* Return the length of the given file. */

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	fflush(f->file);
	return 1;
}

int sqFileTruncate(SQFile *f,off_t offset) {
	/* Truncate the file*/

	if (!sqFileValid(f)) return interpreterProxy->success(false);
	if (ftruncate(fileno(f->file),offset)) {
            return interpreterProxy->success(false);
        }
	f->fileSize = ftello(f->file);
	return 1;
}


int sqFileValid(SQFile *f) {
	return (
		(f != NULL) &&
		(f->file != NULL) &&
		(f->sessionID == thisSession));
}

size_t sqFileWriteFromAt(SQFile *f, size_t count, int byteArrayIndex, size_t startIndex) {
	/* Write count bytes to the given writable file starting at startIndex
	   in the given byteArray. (See comment in sqFileReadIntoAt for interpretation
	   of byteArray and startIndex).
	*/

	char *src;
	size_t bytesWritten;
	off_t position;

	if (!(sqFileValid(f) && f->writable)) return interpreterProxy->success(false);
	if (f->lastOp == READ_OP) fseeko(f->file, 0, SEEK_CUR);  /* seek between reading and writing */
	src = (char *) (byteArrayIndex + startIndex);
	bytesWritten = fwrite(src, 1, count, f->file);

	position = ftello(f->file);
	if (position > f->fileSize) {
		f->fileSize = position;  /* update file size */
	}

	if (bytesWritten != count) {
		interpreterProxy->success(false);
	}
	f->lastOp = WRITE_OP;
	return bytesWritten;
}

int sqFileThisSession() {
	return thisSession;
}

#endif /* NO_STD_FILE_SUPPORT */

