/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32FilePrims.c
*   CONTENT: File functions
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:
*     1) This is a bare windows implementation *not* using any stdio stuff.
*        It is now considered the standard implememtation. This is to avoid
*        the buffered i/o overhead implciit in the stdio implementation.
*
*   UPDATES:
*     1) Support for long path names added by using UNC prefix in that case
*        (Marcel Taeumel, Hasso Plattner Institute, Postdam, Germany)
*     2) Try to remove the read-only attribute from a file before calling
*        DeleteFile. DeleteFile cannot delete read-only files (see comment
*        in sqFileDeleteNameSize).
*        (Max Leske)
*
*****************************************************************************/

#include <Windows.h>
#include <malloc.h>
#include "sq.h"
#include "FilePlugin.h"

#include "sqWin32File.h"
#include "sqImageFileAccess.h"

extern struct VirtualMachine *interpreterProxy;

/* Import from sqWin32Main.c */
sqInt isFileHandleATTY(HANDLE fdHandle);
sqInt fileHandleType(HANDLE fdHandle);

#include <io.h> // for _get_osfhandle


#define true  1
#define false 0

#define FILE_HANDLE(f) ((HANDLE) (f)->file)
#define FAIL() { return interpreterProxy->primitiveFail(); }

/***
    The state of a file is kept in the following structure,
    which is stored directly in a Squeak bytes object.
    NOTE: The Squeak side is responsible for creating an
    object with enough room to store sizeof(SQFile) bytes.
    
    The session ID is used to detect stale file objects--
    files that were still open when an image was written.
    The file pointer of such files is meaningless.
    
    typedef struct {
	  int			 sessionID;	(* ikp: must be first *)
	  void			*file;
	  char			 writable;
	  char			 lastOp; (* 0 = uncommitted, 1 = read, 2 = write *)
	  char			 lastChar;
	  char			 isStdioStream;
    } SQFile;

***/


/**********************************************************************/
#include "sqWin32HandleTable.h"
static HandleTable *win32Files = NULL;
/**********************************************************************/

/*** Variables ***/
int thisSession = 0;

/* answers if the file name in question has a case-sensitive duplicate */
int hasCaseSensitiveDuplicate(WCHAR *path);

typedef union {
  struct {
    DWORD dwLow;
    DWORD dwHigh;
  };
  squeakFileOffsetType offset;
} win32FileOffset;


sqInt
sqFileThisSession(void) { return thisSession; }

sqInt
sqFileAtEnd(SQFile *f)
{
  win32FileOffset ofs;
  /* Return true if the file's read/write head is at the end of the file. */
  if (!sqFileValid(f))
    FAIL();
  /* If a stdio handle then assume not at end. */
  if (f->isStdioStream)
    return 0;
  ofs.offset = 0;
  ofs.dwLow = SetFilePointer(FILE_HANDLE(f), 0, (PLONG)&ofs.dwHigh, FILE_CURRENT);
  return ofs.offset >= sqFileSize(f);
}

sqInt
sqFileClose(SQFile *f)
{
  /* Close the given file. */

  if (!sqFileValid(f))
    FAIL();
  if (!CloseHandle(FILE_HANDLE(f)))
	return interpreterProxy->primitiveFailForOSError(GetLastError());
  RemoveHandleFromTable(win32Files, FILE_HANDLE(f));
  f->file = NULL;
  f->sessionID = 0;
  f->writable = false;
  return 1;
}

sqInt
sqFileDeleteNameSize(char *fileNameIndex, sqInt fileNameSize)
{
  WCHAR *win32Path = NULL;

  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, fileNameIndex, fileNameSize);

  if (hasCaseSensitiveDuplicate(win32Path))
    FAIL();

  /* DeleteFile will not delete a file with the read-only attribute set
  (e.g. -r--r--r--, see https://msdn.microsoft.com/en-us/library/windows/desktop/aa363915(v=vs.85).aspx).
  To ensure that this works the same way as on *nix platforms we need to
  remove the read-only attribute (which might fail if the current user
  doesn't own the file).
    Also note that DeleteFile cannot *effectively* delete a file as long as
  there are other processes that hold open handles to that file. The function
  will still report success since the file is *marked* for deletion (no new
  handles can be opened. See the URL mentioned above for reference).
  This will lead to problems during a recursive delete operation since now
  the parent directory wont be empty. */
  SetFileAttributesW(win32Path, FILE_ATTRIBUTE_NORMAL);

  if (!DeleteFileW(win32Path))
    FAIL();
  
  return 1;
}

squeakFileOffsetType
sqFileGetPosition(SQFile *f)
{
  win32FileOffset ofs;
  /* Return the current position of the file's read/write head. */
  if (!sqFileValid(f))
    FAIL();
  ofs.offset = 0;
  ofs.dwLow = SetFilePointer(FILE_HANDLE(f), 0, (PLONG)&ofs.dwHigh, FILE_CURRENT);
  return ofs.offset;
}

sqInt
sqFileInit(void)
{
  /* Create a session ID that is unlikely to be repeated.
     Zero is never used for a valid session number.
     Should be called once at startup time.
  */

#if VM_PROXY_MINOR > 6
  thisSession = interpreterProxy->getThisSessionID();
#else
  thisSession = GetTickCount();
  if (thisSession == 0) thisSession = 1;	/* don't use 0 */
#endif
  win32Files = (HandleTable*) calloc(1, sizeof(HandleTable));
  return 1;
}

sqInt sqFileShutdown(void) { return 1; }

sqInt
sqFileOpen(SQFile *f, char *fileNameIndex, sqInt fileNameSize, sqInt writeFlag)
{
  /* Opens the given file using the supplied sqFile structure
     to record its state. Fails with no side effects if f is
     already open. Files are always opened in binary mode;
     Squeak must take care of any line-end character mapping.
  */
  HANDLE h;
  WCHAR *win32Path = NULL;
  win32FileOffset ofs;

  f->sessionID = 0;
  f->file = 0;

  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, fileNameIndex, fileNameSize);

  if (hasCaseSensitiveDuplicate(win32Path))
    FAIL();

  h = CreateFileW(win32Path,
		  writeFlag ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ,
		  writeFlag ? FILE_SHARE_READ : (FILE_SHARE_READ | FILE_SHARE_WRITE),
		  NULL, /* No security descriptor */
		  writeFlag ? OPEN_ALWAYS : OPEN_EXISTING,
		  FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,
		  NULL /* No template */);
  if (h == INVALID_HANDLE_VALUE)
    FAIL();

  f->sessionID = thisSession;
  f->file = (HANDLE)h;
  AddHandleToTable(win32Files, h);
  /* compute and cache file size */
  ofs.offset = 0;
  ofs.dwLow = SetFilePointer(h, 0, (PLONG)&ofs.dwHigh, FILE_END);
  SetFilePointer(h, 0, NULL, FILE_BEGIN);
  f->writable = writeFlag ? true : false;
  return 1;
}

sqInt
sqFileOpenNew(SQFile *f, char *fileNameIndex, sqInt fileNameSize, sqInt *exists)
{
  HANDLE h;
  WCHAR *win32Path = NULL;

  *exists = false;
  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, fileNameIndex, fileNameSize);

  /* test for case duplicates using hasCaseSensitiveDuplicate(), even though
     CreateFileW() with CREATE_NEW should fail if any exist, so if
     hasCaseSensitiveDuplicate() treats some paths as duplicates that
     CreateFileW() doesn't, sqFileOpenNew() will fail like sqFileOpen() would
   */
  if (hasCaseSensitiveDuplicate(win32Path)) {
    f->sessionID = 0;
    FAIL();
  }
  h = CreateFileW(win32Path,
		  (GENERIC_READ | GENERIC_WRITE),
		  FILE_SHARE_READ,
		  NULL, /* No security descriptor */
		  CREATE_NEW, /* Only create and open if it doesn't exist */
		  FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,
		  NULL /* No template */);
  if (h == INVALID_HANDLE_VALUE) {
    f->sessionID = 0;
    if (GetLastError() == ERROR_FILE_EXISTS)
      *exists = true;
    FAIL();
  }
  else {
    f->sessionID = thisSession;
    f->file = (HANDLE)h;
    f->writable = true;
    AddHandleToTable(win32Files, h);
  }
  return 1;
}

sqInt
sqConnectToFileDescriptor(SQFile *sqFile, int fd, sqInt writeFlag)
{
	/*
	 * Open the file with the supplied file descriptor in binary mode.
	 *
	 * writeFlag determines whether the file is read-only or writable
	 * and must be compatible with the existing access.
	 * sqFile is populated with the file information.
	 * Smalltalk is reponsible for handling character encoding and 
	 * line ends.
	 */
	HANDLE file = _fdopen(fd, writeFlag ? "wb" : "rb");
	if (!file)
		return interpreterProxy->success(false);
	return sqConnectToFile(sqFile, file, writeFlag);
}

sqInt
sqConnectToFile(SQFile *sqFile, void *file, sqInt writeFlag)
{
	/*
	 * Populate the supplied SQFile structure with the supplied FILE.
	 *
	 * writeFlag indicates whether the file is read-only or writable
	 * and must be compatible with the existing access.
	 */
	sqFile->file = (HANDLE)file;
	AddHandleToTable(win32Files, file);
	/* setSize(sqFile, 0); */
	sqFile->sessionID = thisSession;
	sqFile->lastOp = 0; /* Unused on Win32 */
	sqFile->writable = writeFlag;
	return 1;
}

void
sqFileStdioHandlesIntoFile_WithHandle_IsWritable(SQFile * file, HANDLE handle, int isWritable)
{
	file->sessionID = thisSession;
	file->file = handle;
	file->writable = isWritable;
	file->lastOp = 0; /* unused on win32 */
	file->isStdioStream = isFileHandleATTY(handle);
	AddHandleToTable(win32Files, handle);
}

/*
 * Fill-in files with handles for stdin, stdout and seterr as available and
 * answer a bit-mask of the availability:
 *
 * <0 - Error.  The value will be returned to the image using primitiveFailForOSError().
 * 0  - no stdio available
 * 1  - stdin available
 * 2  - stdout available
 * 4  - stderr available
 */
sqInt
sqFileStdioHandlesInto(SQFile files[3])
{
HANDLE	handle;
int	status = 0;

	handle = GetStdHandle(STD_INPUT_HANDLE);
	if (handle != 0) {
		sqFileStdioHandlesIntoFile_WithHandle_IsWritable(&files[0], handle, false);
		status += 1; }
	handle = GetStdHandle(STD_OUTPUT_HANDLE);
	if (handle != 0) {
		sqFileStdioHandlesIntoFile_WithHandle_IsWritable(&files[1], handle, true);
		status += 2; }
	handle = GetStdHandle(STD_ERROR_HANDLE);
	if (handle != 0) {
		sqFileStdioHandlesIntoFile_WithHandle_IsWritable(&files[2], handle, true);
		status += 4; }
	return status;
}


/*
* Allow to test if the standard input/output files are from a console or not
* Return values:
* -1 - Error
* 0 - no console (windows only)
* 1 - normal terminal (unix terminal / windows console)
* 2 - pipe
* 3 - file
* 4 - cygwin terminal (windows only)
*/
sqInt
sqFileDescriptorType(int fdNum)
{
	return fileHandleType((HANDLE)_get_osfhandle(fdNum));
}

size_t
sqFileReadIntoAt(SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex)
{
  /* Read count bytes from the given file into byteArray starting at
     startIndex. byteArray is the address of the first byte of a
     Squeak bytes object (e.g. String or ByteArray). startIndex
     is a zero-based index; that is a startIndex of 0 starts writing
     at the first byte of byteArray.
  */
  DWORD dwReallyRead;

  if (!sqFileValid(f))
    FAIL();
  if (f->isStdioStream)
    ReadConsole(FILE_HANDLE(f), (LPVOID) (byteArrayIndex+startIndex), count,
                &dwReallyRead, NULL);
  else
    ReadFile(FILE_HANDLE(f), (LPVOID) (byteArrayIndex+startIndex), count,
             &dwReallyRead, NULL);
  return dwReallyRead;
}

sqInt
sqFileRenameOldSizeNewSize(char *oldNameIndex, sqInt oldNameSize, char *newNameIndex, sqInt newNameSize)
{
  WCHAR *oldPath = NULL;
  WCHAR *newPath = NULL;

  /* convert the file names into a null-terminated C string */
  ALLOC_WIN32_PATH(oldPath, oldNameIndex, oldNameSize);
  ALLOC_WIN32_PATH(newPath, newNameIndex, newNameSize);

  if (hasCaseSensitiveDuplicate(oldPath))
    FAIL();
  if (!MoveFileW(oldPath, newPath))
    FAIL();
  
  return 1;
}

sqInt
sqFileSetPosition(SQFile *f, squeakFileOffsetType position)
{
  win32FileOffset ofs;
  ofs.offset = position;
  /* Set the file's read/write head to the given position. */
  if (!sqFileValid(f))
    FAIL();
  SetFilePointer(FILE_HANDLE(f), ofs.dwLow, (PLONG)&ofs.dwHigh, FILE_BEGIN);
  return 1;
}

squeakFileOffsetType
sqFileSize(SQFile *f)
{
  /* Return the length of the given file. */
  win32FileOffset ofs;
  if (!sqFileValid(f))
    FAIL();
  ofs.offset = 0;
  ofs.dwLow = GetFileSize(FILE_HANDLE(f), &ofs.dwHigh);
  return ofs.offset;
}

sqInt
sqFileFlush(SQFile *f)
{
  if (!sqFileValid(f))
    FAIL();
  /* note: ignores the return value in case of read-only access */
  FlushFileBuffers(FILE_HANDLE(f));
  return 1;
}

sqInt
sqFileSync(SQFile *f)
{
  /*
   * sqFileFlush uses FlushFileBuffers which is equivalent to fsync on windows
   * as long as WriteFile is used directly and no other buffering is done.
   */
  return sqFileFlush(f);
}

sqInt
sqFileTruncate(SQFile *f, squeakFileOffsetType offset)
{
  win32FileOffset ofs;
  ofs.offset = offset;
  if (!sqFileValid(f))
    FAIL();
  SetFilePointer(FILE_HANDLE(f), ofs.dwLow, (PLONG)&ofs.dwHigh, FILE_BEGIN);
  return SetEndOfFile(FILE_HANDLE(f));
}

sqInt
sqFileValid(SQFile *f)
{
  if (!f || f->sessionID != thisSession)
	return false;
  if (!IsHandleInTable(win32Files, FILE_HANDLE(f))) {
    printf("WARNING: Manufactured file handle detected!\n");
    return false;
  }
  return true;
}

size_t
sqFileWriteFromAt(SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex)
{
  /* Write count bytes to the given writable file starting at startIndex
     in the given byteArray. (See comment in sqFileReadIntoAt for interpretation
     of byteArray and startIndex).
  */
  DWORD dwReallyWritten;
  win32FileOffset ofs;
  if (!(sqFileValid(f) && f->writable))
    FAIL();

  if (f->isStdioStream)
    WriteConsole(FILE_HANDLE(f), (LPVOID) (byteArrayIndex + startIndex), count, &dwReallyWritten, NULL);
  else
    WriteFile(FILE_HANDLE(f), (LPVOID) (byteArrayIndex + startIndex), count, &dwReallyWritten, NULL);
  
  if (dwReallyWritten != count)
    FAIL();
  return dwReallyWritten;
}

/***************************************************************************/
/* Image file functions                                                    */
/***************************************************************************/

// Support for image embedded as a resource
static char *imageResourceData = NULL;
static DWORD imageResourceSize = 0;
static DWORD irReadPosition = 0;
#if HAVE_LIBZ
static z_stream irzs = { 0, }; // compressed image resource zlib stream
#endif

int
sqImageFileClose(sqImageFile h)
{
  if (h == ImageIsAResource)
	return true;
#if HAVE_LIBZ
  if (h == ImageIsACompressedResource) {
	(void)inflateEnd(&irzs);
	return true;
  }
#endif

  SetEndOfFile((HANDLE)(h-1));
  return CloseHandle((HANDLE)(h-1));
}

sqImageFile
sqImageFileOpen(const char *fileName, const char *mode)
{ const char *modePtr;
  int writeFlag = 0;
  WCHAR *win32Path = NULL;
  HANDLE h;

  if (!mode)
	return 0;
  modePtr = mode;
  while (*modePtr) {
      if (*modePtr == 'w') writeFlag = 1;
	  /* Note: We cannot append here */
	  if (*modePtr == 'a') return 0;
      modePtr++;
  }
  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, fileName, -1);

  if (hasCaseSensitiveDuplicate(win32Path))
    return 0;
  
  h = CreateFileW(win32Path,
		  writeFlag ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ,
		  writeFlag ? FILE_SHARE_READ : (FILE_SHARE_READ | FILE_SHARE_WRITE),
		  NULL, /* No security descriptor */
		  writeFlag ? CREATE_ALWAYS : OPEN_EXISTING,
		  FILE_ATTRIBUTE_NORMAL,
		  NULL /* No template */);

  if (h == INVALID_HANDLE_VALUE)
    return 0;
 
  return (usqIntptr_t)h+1;
}

squeakFileOffsetType
sqImageFilePosition(sqImageFile h)
{
  win32FileOffset ofs;

  if (h == ImageIsAResource
   || h == ImageIsACompressedResource)
	return irReadPosition;

  ofs.offset = 0;
  ofs.dwLow = SetFilePointer((HANDLE)(h-1), 0, (PLONG)&ofs.dwHigh, FILE_CURRENT);
  return ofs.offset;
}

static size_t
sqImageResourceRead(void *ptr, size_t sz, size_t count)
{
	if (irReadPosition + (sz * count) > imageResourceSize)
      abortMessage(TEXT("Attempting to read beyond end of image resource"));

	memcpy(ptr,imageResourceData + irReadPosition, sz * count);
	irReadPosition += sz * count;
	return count;
}

#if HAVE_LIBZ
static inline size_t
sqCompressedImageRead(void *ptr, size_t sz, size_t count)
{
	size_t nread = 0, ntoread = sz * count;
	unsigned long nreadSoFar = irzs.total_out;
	int ret;

	if (!irzs.next_in) {
		irzs.avail_in = imageResourceSize;
		irzs.next_in = imageResourceData;
		ret = inflateInit2(&irzs,MAX_WBITS+16);
		if (ret != Z_OK) {
			abortMessage(TEXT("inflateInit failed on reading compressed image resource"));
			return 0;
		}
	}

#if 0	// Currently there is no convenient way of determining the size of the
		// uncompressed image, so we don't implement this check, which isn't a
		// problem in practice.
	if (irReadPosition + ntoread > imageResourceSize) {
		abortMessage(TEXT("Attempting to read beyond end of image resource"));
		return 0;
	}
#endif
	// N.B. seeking backwards is as yet unimplemented (cuz all platforms,
	// and hence all images, are little endian as of 2024). One way to
	// implement this is to go back to the beginning and advance forward.
	// This should be a fine strategy since seeking backwards is only done
	// if the initial image magic number looks wrong, and the initial
	// magic number is the first word in the image file.
	assert(irReadPosition >= nreadSoFar);
	// to seek forward simply discard that much data
	if (irReadPosition > nreadSoFar) {
		assert(irReadPosition - nreadSoFar <= sz * count);
		irzs.avail_out = irReadPosition - nreadSoFar;
		irzs.next_out = ptr;

		// Decompress to fill ptr with irReadPosition - nreadSoFar's worth
		ret = inflate(&irzs, Z_NO_FLUSH);
		switch (ret) {
		case Z_NEED_DICT:
		case Z_DATA_ERROR:
		case Z_MEM_ERROR:
			(void)inflateEnd(&irzs);
			return nread;
		}
		nreadSoFar = irReadPosition;
	}
	irzs.avail_out = ntoread;
	irzs.next_out = ptr;

	// Decompress to fill ptr with count's worth
	ret = inflate(&irzs, Z_NO_FLUSH);
	switch (ret) {
	case Z_NEED_DICT:
	case Z_DATA_ERROR:
	case Z_MEM_ERROR:
		(void)inflateEnd(&irzs);
		return nread;
	}
	assert(irzs.total_out - nreadSoFar == sz * count);
	irReadPosition += ntoread;
	return count;
}
#endif // HAVE_LIBZ
size_t
sqImageFileRead(void *ptr, size_t sz, size_t count, sqImageFile h)
{
  DWORD dwReallyRead;
  size_t reallyRead = 0;
  size_t totalToRead = count * sz;
  squeakFileOffsetType position;

  if (h == ImageIsAResource)
	return sqImageResourceRead(ptr,sz,count);
  if (h == ImageIsACompressedResource)
#if HAVE_LIBZ
	return sqCompressedImageRead(ptr,sz,count);
#else
	abortMessage(TEXT("Image resource is compressed but libz is missing!"));
#endif

  position = sqImageFilePosition(h);
  while (reallyRead != totalToRead) {
    DWORD toRead = (totalToRead - reallyRead) > (size_t)MAXDWORD  ? MAXDWORD  : totalToRead - reallyRead;
    BOOL ret = ReadFile((HANDLE)(h - 1), (LPVOID)((sqInt)ptr + (sqInt)reallyRead), toRead, &dwReallyRead, NULL);
    reallyRead += dwReallyRead;

    if (!ret || dwReallyRead != toRead) {
      DWORD err = GetLastError();
      if (sqMessageBox(MB_ABORTRETRYIGNORE, TEXT("VM Warning"), TEXT("Image file read problem (%d out of %d bytes read)"), dwReallyRead, toRead)
        == IDABORT)
		return reallyRead / sz;
      sqImageFileSeek(h, position);
      reallyRead = 0;
    }
  }
  return reallyRead / sz;
}

squeakFileOffsetType
sqImageFileSeek(sqImageFile h, squeakFileOffsetType pos)
{
  win32FileOffset ofs;

  if (h == ImageIsAResource
   || h == ImageIsACompressedResource)
	return irReadPosition = pos;

  ofs.offset = pos;
  ofs.dwLow = SetFilePointer((HANDLE)(h-1), ofs.dwLow, (PLONG)&ofs.dwHigh, FILE_BEGIN);
  return ofs.offset;
}

size_t
sqImageFileWrite(const void *ptr, size_t sz, size_t count, sqImageFile h)
{
  size_t reallyWritten = 0;
  DWORD dwReallyWritten;
  size_t totalToWrite = count * sz;
  squeakFileOffsetType position;

  position = sqImageFilePosition(h);
  while (reallyWritten != totalToWrite) {
    DWORD toWrite = (totalToWrite - reallyWritten) > (size_t) MAXDWORD  ? MAXDWORD  : totalToWrite - reallyWritten;
    BOOL ret = WriteFile((HANDLE)(h - 1), (LPVOID)((sqInt)ptr + (sqInt) reallyWritten), toWrite, &dwReallyWritten, NULL);
    reallyWritten += dwReallyWritten;

    if (!ret || dwReallyWritten != toWrite) {
      DWORD err = GetLastError();
      if (sqMessageBox(MB_ABORTRETRYIGNORE, TEXT("VM Warning"), TEXT("Image file read problem (%d out of %d bytes read)"), dwReallyWritten, toWrite)
        == IDABORT)
		return reallyWritten / sz;
      sqImageFileSeek(h, position);
      reallyWritten = 0;
    }
  }
  return reallyWritten / sz;
}

squeakFileOffsetType
sqImageFileSize(sqImageFile h)
{
  win32FileOffset ofs;
  ofs.offset = 0;
  ofs.dwLow = GetFileSize((HANDLE)(h-1), &ofs.dwHigh);
  return ofs.offset;
}


void
sqFilePluginNoteImageResourceData(void *data, DWORD size)
{
	imageResourceData = (char *)data;
	imageResourceSize = size;
}
