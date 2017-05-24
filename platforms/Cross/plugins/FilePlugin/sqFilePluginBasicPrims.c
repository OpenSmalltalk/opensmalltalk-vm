/****************************************************************************
*   PROJECT: File Interface
*   FILE:    sqFilePluginBasicPrims.c
*   CONTENT: 
*
*   AUTHOR:  
*   ADDRESS: 
*   EMAIL:   ]
*   RCSID:   $Id$
*
*   NOTES: See change log below.
*	2005-03-26 IKP fix unaligned accesses to file[Size] members
* 	2004-06-10 IKP 64-bit cleanliness
* 	1/28/02    Tim remove non-ansi stuff
*				unistd.h
				ftello
				fseeko
				ftruncate & fileno
				macro-ise use of sqFTruncate to avoid non-ansi
*	1/22/2002  JMM Use squeakFileOffsetType versus off_t
*
*****************************************************************************/

/* The basic prim code for file operations. See also the platform specific
* files typically named 'sq{blah}Directory.c' for details of the directory
* handling code. Note that the win32 platform #defines NO_STD_FILE_SUPPORT
* and thus bypasses this file
*/


#include <errno.h>

#include "sq.h"

#ifndef NO_STD_FILE_SUPPORT

#include <sys/stat.h>
#include <sys/types.h>

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>

#include "sqMemoryAccess.h"
#include "FilePlugin.h" /* must be included after sq.h */

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
		int		sessionID;
		File	*file;
		squeakFileOffsetType		fileSize;  //JMM Nov 8th 2001 64bits we hope
		char	writable;
		char	lastOp;  		// 0 = uncommitted, 1 = read, 2 = write //
		char	lastChar;		// one character peek for stdin //
		char	isStdioStream;
	} SQFile;

***/

/*** Constants ***/
#define UNCOMMITTED	0
#define READ_OP		1
#define WRITE_OP	2

#ifndef SEEK_SET
# define SEEK_SET	0
# define SEEK_CUR	1
# define SEEK_END	2
#endif

/*** Variables ***/
int thisSession = 0;
extern struct VirtualMachine * interpreterProxy;

/* Since SQFile instances are held on the heap in 32-bit-aligned byte arrays we
 * may need to use memcpy to avoid alignment faults.
 */
#if OBJECTS_32BIT_ALIGNED
static FILE *getFile(SQFile *f)
{
  FILE *file;
  void *in= (void *)&f->file;
  void *out= (void *)&file;
  memcpy(out, in, sizeof(FILE *));
  return file;
}
static void setFile(SQFile *f, FILE *file)
{
  void *in= (void *)&file;
  void *out= (void *)&f->file;
  memcpy(out, in, sizeof(FILE *));
}
static squeakFileOffsetType getSize(SQFile *f)
{
  squeakFileOffsetType size;
  void *in= (void *)&f->fileSize;
  void *out= (void *)&size;
  memcpy(out, in, sizeof(squeakFileOffsetType));
  return size;
}
static void setSize(SQFile *f, squeakFileOffsetType size)
{
  void *in= (void *)&size;
  void *out= (void *)&f->fileSize;
  memcpy(out, in, sizeof(squeakFileOffsetType));
}
#else /* OBJECTS_32BIT_ALIGNED */
# define getFile(f) ((FILE *)((f)->file))
# define setFile(f,fileptr) ((f)->file = (fileptr))
# define getSize(f) ((f)->fileSize)
# define setSize(f,size) ((f)->fileSize = (size))
#endif /* OBJECTS_32BIT_ALIGNED */

#if 0
# define pentry(func) do { int fn = fileno(getFile(f)); if (f->isStdioStream) printf("\n"#func "(%s) %lld %d\n", fn == 0 ? "in" : fn == 1 ? "out" : "err", (long long)ftell(getFile(f)), f->lastChar); } while (0)
# define pexit(expr) (f->isStdioStream && printf("\n\t^"#expr " %lld %d\n", (long long)(sqFileValid(f) ? ftell(getFile(f)) : -1), f->lastChar)), expr
# define pfail() printf("\tFAIL\n");
#else
# define pentry(func) 0
# define pexit(expr) expr
# define pfail() 0
#endif

sqInt
sqFileAtEnd(SQFile *f) {
	/* Return true if the file's read/write head is at the end of the file. */

	if (!sqFileValid(f))
		return interpreterProxy->success(false);
	pentry(sqFileAtEnd);
	if (f->isStdioStream)
		return pexit(feof(getFile(f)));
	return ftell(getFile(f)) >= getSize(f);
}

sqInt
sqFileClose(SQFile *f) {
	/* Close the given file. */

	int result;

	if (!sqFileValid(f))
		return interpreterProxy->success(false);

	result = fclose(getFile(f));
	setFile(f, NULL);
	f->sessionID = 0;
	f->writable = false;
	setSize(f, 0);
	f->lastOp = UNCOMMITTED;

	/*
	 * fclose() can fail for the same reasons fflush() or write() can so
	 * errors must be checked, but it must NEVER be retried
	 */
	if (result != 0)
		return interpreterProxy->success(false);

	return 1;
}

sqInt
sqFileDeleteNameSize(char *sqFileName, sqInt sqFileNameSize) {
	char cFileName[PATH_MAX];
	int err;

	if (sqFileNameSize >= sizeof(cFileName))
		return interpreterProxy->success(false);

	/* copy the file name into a null-terminated C string */
	interpreterProxy->ioFilenamefromStringofLengthresolveAliases(cFileName, sqFileName, sqFileNameSize, false);

	err = remove(cFileName);
	if (err)
		return interpreterProxy->success(false);

	return 1;
}

squeakFileOffsetType
sqFileGetPosition(SQFile *f) {
	/* Return the current position of the file's read/write head. */

	squeakFileOffsetType position;

	if (!sqFileValid(f))
		return interpreterProxy->success(false);
	pentry(sqFileGetPosition);
	if (f->isStdioStream
		&& !f->writable)
		return pexit(f->lastChar == EOF ? 0 : 1);
	position = ftell(getFile(f));
	if (position == -1)
		return interpreterProxy->success(false);
	return position;
}

sqInt
sqFileInit(void) {
	/* Create a session ID that is unlikely to be repeated.
	   Zero is never used for a valid session number.
	   Should be called once at startup time.
	*/
	thisSession = interpreterProxy->getThisSessionID();
	return 1;
}

sqInt
sqFileShutdown(void) { return 1; }

/* These functions use the open() sys call directly, retrying on EINTR, and
   return a file descriptor on success and a negative integer on failure.
   They're needed because fopen() doesn't give enough control over file
   creation and truncation, for example to only create a file if it doesn't
   already exist or to open a file for just writing but not truncation.
*/
static int openFileWithFlags(const char *path, int flags)
{
	int fd;

	do {
		fd = open(path, flags);
	} while (fd < 0 && errno == EINTR);

	return fd;
}
static int openFileWithFlagsInMode(const char *path, int flags, mode_t mode)
{
	int fd;

	do {
		fd = open(path, flags, mode);
	} while (fd < 0 && errno == EINTR);

	return fd;
}

static FILE *openFileDescriptor(int fd, const char *mode)
{
	/* This must be implemented separately from openFileWithFlags()
	   and openFileWithFlagsInMode() so error checking can be done
	   by the caller for both open() and fdopen() failure conditions.
	 */
	FILE *file;

	do {
		file = fdopen(fd, mode);
	} while (file == NULL && errno == EINTR);

	return file;
}

static void setNewFileMacTypeAndCreator(char *sqFileName, sqInt sqFileNameSize)
{
	char type[4], creator[4];

	dir_GetMacFileTypeAndCreator(sqFileName, sqFileNameSize, type, creator);
	if (strncmp(type, "BINA", 4) == 0
		|| strncmp(type, "????", 4) == 0
		|| strncmp(type, "", 1) == 0)
		dir_SetMacFileTypeAndCreator(sqFileName, sqFileNameSize, "TEXT", "R*ch");
}

sqInt
sqFileOpen(SQFile *f, char *sqFileName, sqInt sqFileNameSize, sqInt writeFlag) {
	/* Opens the given file using the supplied sqFile structure
	   to record its state. Fails with no side effects if f is
	   already open. Files are always opened in binary mode;
	   Squeak must take care of any line-end character mapping.
	*/

	char cFileName[PATH_MAX];
	int fd;
	const char *mode;

	/* don't open an already open file */
	if (sqFileValid(f))
		return interpreterProxy->success(false);

	/* copy the file name into a null-terminated C string */
	if (sqFileNameSize >= sizeof(cFileName))
		return interpreterProxy->success(false);
	/* can fail when alias resolution is enabled */
	if (interpreterProxy->ioFilenamefromStringofLengthresolveAliases(cFileName, sqFileName, sqFileNameSize, true) != 0)
		return interpreterProxy->success(false);

	if (writeFlag) {
		int retried = 0;
		do {
			mode = "r+b";
			fd = openFileWithFlags(cFileName, O_RDWR);
			/* could have failed if we lack read permission or it didn't exist */
			if (fd < 0) {
				if (errno == EACCES) {
					/* this does no truncation, unlike the
					   equivalent with fopen()
					 */
					mode = "wb";
					fd = openFileWithFlags(cFileName, O_WRONLY);
				} else if (errno == ENOENT) {
					mode = "r+b";
					fd = openFileWithFlagsInMode(
						cFileName,
						O_CREAT|O_EXCL|O_RDWR,
						/* the mode fopen() uses when creating files;
						   will likely be rw-r--r-- after being modified
						   by the process's umask
						 */
						S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);

					/* could have failed if we lack read permission
					   or it already exists
					 */
					if (fd < 0 && errno == EACCES) {
						mode = "wb";
						fd = openFileWithFlagsInMode(
							cFileName,
							O_CREAT|O_EXCL|O_WRONLY,
							/* write-only version of the above mode;
							   will likely be -w------- after being
							   modified by the process's umask
							 */
							S_IWUSR|S_IWGRP|S_IWOTH);
					}

					if (fd >= 0)
						setNewFileMacTypeAndCreator(sqFileName, sqFileNameSize);
				}
			}
		/* We retry this only once if it failed because we attempted to create
		   a new file that already existed (EEXIST when O_EXCL is used).
		   This should only occur if the file was created after we tried to
		   read an existing file but before we could create it.
		 */
		} while (fd < 0 && errno == EEXIST && ++retried <= 1);
	} else {
		mode = "rb";
		fd = openFileWithFlags(cFileName, O_RDONLY);
	}

	if (fd >= 0) {
		FILE *file = openFileDescriptor(fd, mode);
		if (file != NULL) {
			f->sessionID = thisSession;
			setFile(f, file);

			/* compute and cache file size */
			fseek(file, 0, SEEK_END);
			setSize(f, ftell(file));
			fseek(file, 0, SEEK_SET);

			f->writable = writeFlag ? true : false;
			f->lastOp = UNCOMMITTED;
			return 1;
		}

		/* close() the bad fd to avoid leaking file descriptors;
		   NEVER reattempt close() if it fails, even on EINTR
		 */
		close(fd);
	}

	f->sessionID = 0;
	setSize(f, 0);
	f->writable = false;
	return interpreterProxy->success(false);
}

sqInt
sqFileOpenNew(SQFile *f, char *sqFileName, sqInt sqFileNameSize) {
	/* Opens the given file for writing and if possible reading
	   if it does not already exist using the supplied sqFile
	   structure to record its state.
	   Fails with no side effects if f is already open. Files are
	   always opened in binary mode; Squeak must take care of any
	   line-end character mapping.
	*/

	char cFileName[PATH_MAX];
	int fd;
	const char *mode;

	/* don't open an already open file */
	if (sqFileValid(f))
		return interpreterProxy->success(false);

	/* copy the file name into a null-terminated C string */
	if (sqFileNameSize >= sizeof(cFileName))
		return interpreterProxy->success(false);
	/* can fail when alias resolution is enabled */
	if (interpreterProxy->ioFilenamefromStringofLengthresolveAliases(cFileName, sqFileName, sqFileNameSize, true) != 0)
		return interpreterProxy->success(false);

	mode = "r+b";
	fd = openFileWithFlagsInMode(
		cFileName,
		O_CREAT|O_EXCL|O_RDWR,
		/* the mode fopen() uses when creating files; will likely
		   be rw-r--r-- after being modified by the process's umask
		 */
		S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
	/* could have failed if we lack read permission or it already exists */
	if (fd < 0 && errno == EACCES) {
		mode = "wb";
		fd = openFileWithFlagsInMode(
			cFileName,
			O_CREAT|O_EXCL|O_WRONLY,
			/* write-only version of the above mode; will likely
			   be -w------- after being modified by the process's umask
			 */
			S_IWUSR|S_IWGRP|S_IWOTH);
	}

	if (fd >= 0) {
		FILE *file;

		setNewFileMacTypeAndCreator(sqFileName, sqFileNameSize);
		file = openFileDescriptor(fd, mode);
		if (file != NULL) {
			f->sessionID = thisSession;
			setFile(f, file);
			setSize(f, 0);
			f->writable = true;
			f->lastOp = UNCOMMITTED;
			return 1;
		}

		/* close() the bad fd to avoid leaking file descriptors;
		   NEVER reattempt close() if it fails, even on EINTR
		 */
		close(fd);
	}

	f->sessionID = 0;
	setSize(f, 0);
	f->writable = false;
	return interpreterProxy->success(false);
}

/*
 * Fill-in files with 3 handles for stdin, stdout and stderr as available and
 * answer a bit-mask of the availability, 1 corresponding to stdin, 2 to stdout
 * and 4 to stderr, with 0 on error or unavailablity.
 */
sqInt
sqFileStdioHandlesInto(SQFile files[])
{
	/* streams connected to a terminal are supposed to be line-buffered anyway.
	 * And for some reason this has no effect on e.g. Mac OS X.  So use
	 * fgets instead of fread when reading from these streams.
	 */
#if defined(_IOLBF) && 0
	if (isatty(fileno(stdin)))
		setvbuf(stdin,0,_IOLBF,0);
#endif
	files[0].sessionID = thisSession;
	files[0].file = stdin;
	files[0].fileSize = 0;
	files[0].writable = false;
	files[0].lastOp = READ_OP;
	files[0].isStdioStream = isatty(fileno(stdin));
	files[0].lastChar = EOF;

	files[1].sessionID = thisSession;
	files[1].file = stdout;
	files[1].fileSize = 0;
	files[1].writable = true;
	files[1].isStdioStream = true;
	files[1].lastChar = EOF;
	files[1].lastOp = WRITE_OP;

	files[2].sessionID = thisSession;
	files[2].file = stderr;
	files[2].fileSize = 0;
	files[2].writable = true;
	files[2].isStdioStream = true;
	files[2].lastChar = EOF;
	files[2].lastOp = WRITE_OP;

	return 7;
}

size_t
sqFileReadIntoAt(SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex) {
	/* Read count bytes from the given file into byteArray starting at
	   startIndex. byteArray is the address of the first byte of a
	   Squeak bytes object (e.g. String or ByteArray). startIndex
	   is a zero-based index; that is a startIndex of 0 starts writing
	   at the first byte of byteArray.
	*/

	char *dst;
	size_t bytesRead;
	FILE *file;
#if COGMTVM
	sqInt myThreadIndex;
#endif
#if COGMTVM && SPURVM
	int wasPinned;
	sqInt bufferOop = (sqInt)byteArrayIndex - BaseHeaderSize;
#endif

	if (!sqFileValid(f))
		return interpreterProxy->success(false);
	pentry(sqFileReadIntoAt);
	file = getFile(f);
	if (f->writable) {
		if (f->isStdioStream)
			return interpreterProxy->success(false);
		if (f->lastOp == WRITE_OP)
			fseek(file, 0, SEEK_CUR);  /* seek between writing and reading */
	}
	dst = byteArrayIndex + startIndex;
	if (f->isStdioStream) {
#if COGMTVM
# if SPURVM
		if (!(wasPinned = interpreterProxy->isPinned(bufferOop))) {
			if (!(bufferOop = interpreterProxy->pinObject(bufferOop)))
				return 0;
			dst = bufferOop + BaseHeaderSize + startIndex;
		}
# else
		if (interpreterProxy->isInMemory((sqInt)f)
		 && interpreterProxy->isYoung((sqInt)f)
		 || interpreterProxy->isInMemory((sqInt)dst)
		 && interpreterProxy->isYoung((sqInt)dst)) {
			interpreterProxy->primitiveFailFor(PrimErrObjectMayMove);
			return 0;
		}
# endif
		myThreadIndex = interpreterProxy->disownVM(DisownVMLockOutFullGC);
#endif /* COGMTVM */
		/* Line buffering in fread can't be relied upon, at least on Mac OS X
		 * and mingw win32.  So do it the hard way.
		 */
		bytesRead = 0;
		do {
			clearerr(file);
			if (fread(dst, 1, 1, file) == 1) {
				bytesRead += 1;
				if (dst[bytesRead-1] == '\n'
				 || dst[bytesRead-1] == '\r')
					break;
			}
		}
		while (bytesRead <= 0 && ferror(file) && errno == EINTR);
#if COGMTVM
		interpreterProxy->ownVM(myThreadIndex);
# if SPURVM
		if (!wasPinned)
			interpreterProxy->unpinObject(bufferOop);
# endif
#endif /* COGMTVM */
	}
	else
		do {
			clearerr(file);
			bytesRead = fread(dst, 1, count, file);
		}
		while (bytesRead <= 0 && ferror(file) && errno == EINTR);
	/* support for skipping back 1 character for stdio streams */
	if (f->isStdioStream)
		if (bytesRead > 0)
			f->lastChar = dst[bytesRead-1];
	f->lastOp = READ_OP;
	return pexit(bytesRead);
}

sqInt
sqFileRenameOldSizeNewSize(char *sqOldName, sqInt sqOldNameSize, char *sqNewName, sqInt sqNewNameSize) {
	char cOldName[PATH_MAX], cNewName[PATH_MAX];
	int err;

	if ((sqOldNameSize >= sizeof(cOldName)) || (sqNewNameSize >= sizeof(cNewName)))
		return interpreterProxy->success(false);

	/* copy the file names into null-terminated C strings */
	interpreterProxy->ioFilenamefromStringofLengthresolveAliases(cOldName, sqOldName, sqOldNameSize, false);
	interpreterProxy->ioFilenamefromStringofLengthresolveAliases(cNewName, sqNewName, sqNewNameSize, false);

	err = rename(cOldName, cNewName);
	if (err)
		return interpreterProxy->success(false);

	return 1;
}

sqInt
sqFileSetPosition(SQFile *f, squeakFileOffsetType position) {
	/* Set the file's read/write head to the given position. */

	if (!sqFileValid(f))
		return interpreterProxy->success(false);
	if (f->isStdioStream) {
		pentry(sqFileSetPosition);
		/* support one character of pushback for stdio streams. */
		if (!f->writable
		 && f->lastChar != EOF) {
			squeakFileOffsetType currentPos = f->lastChar == EOF ? 0 : 1;
			if (currentPos == position)
				return pexit(1);
			if (currentPos - 1 == position) {
				ungetc(f->lastChar, getFile(f));
				f->lastChar = EOF;
				return pexit(1);
			}
		}
		pfail();
		return interpreterProxy->success(false);
	}
	fseek(getFile(f), position, SEEK_SET);
	f->lastOp = UNCOMMITTED;
	return 1;
}

squeakFileOffsetType
sqFileSize(SQFile *f) {
	/* Return the length of the given file. */

	if (!sqFileValid(f))
		return interpreterProxy->success(false);
	if (f->isStdioStream)
		return interpreterProxy->success(false);
	return getSize(f);
}

sqInt
sqFileFlush(SQFile *f) {
	/* Flush stdio buffers of file */

	if (!sqFileValid(f))
		return interpreterProxy->success(false);
	pentry(sqFileFlush);

	/*
	 * fflush() can fail for the same reasons write() can so errors must be checked but
	 * sqFileFlush() must support being called on readonly files for historical reasons
	 * so EBADF is ignored
	 */
	if (fflush(getFile(f)) != 0 && errno != EBADF)
		return interpreterProxy->success(false);

	return 1;
}

sqInt
sqFileSync(SQFile *f) {
	/* Flush kernel-level buffers of any written/flushed data to disk */

	if (!sqFileValid(f))
		return interpreterProxy->success(false);
	pentry(sqFileSync);
	if (fsync(fileno(getFile(f))) != 0)
		return interpreterProxy->success(false);
	return 1;
}

sqInt
sqFileTruncate(SQFile *f, squeakFileOffsetType offset) {
	if (!sqFileValid(f))
		return interpreterProxy->success(false);
 	if (sqFTruncate(getFile(f), offset))
		return interpreterProxy->success(false);
	setSize(f, ftell(getFile(f)));
	return 1;
}

sqInt
sqFileValid(SQFile *f) {
	return (
		(f != NULL) &&
		(getFile(f) != NULL) &&
		(f->sessionID == thisSession));
}

size_t
sqFileWriteFromAt(SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex) {
	/* Write count bytes to the given writable file starting at startIndex
	   in the given byteArray. (See comment in sqFileReadIntoAt for interpretation
	   of byteArray and startIndex).
	*/

	char *src;
	size_t bytesWritten;
	squeakFileOffsetType position;
	FILE *file;

	if (!(sqFileValid(f) && f->writable))
		return interpreterProxy->success(false);
	pentry(sqFileWriteFromAt);
	file = getFile(f);
	if (f->lastOp == READ_OP) fseek(file, 0, SEEK_CUR);  /* seek between reading and writing */
	src = byteArrayIndex + startIndex;
	bytesWritten = fwrite(src, 1, count, file);

	position = ftell(file);
	if (position > getSize(f)) {
		setSize(f, position);  /* update file size */
	}

	if (bytesWritten != count) {
		interpreterProxy->success(false);
	}
	f->lastOp = WRITE_OP;
	return pexit(bytesWritten);
}

sqInt
sqFileThisSession() {
	return thisSession;
}
#endif /* NO_STD_FILE_SUPPORT */
