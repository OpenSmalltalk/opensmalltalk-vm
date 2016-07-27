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
*        It can be used instead of the standard sqFilePrims.c file on systems
*        not having standard io libraries (e.g. WinCE)
*     2) For using this you'll need to define WIN32_FILE_SUPPORT globally
*        (e.g., in your compiler's project settings)
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
#include <windows.h>
#include <malloc.h>
#include "sq.h"
#include "FilePlugin.h"

#include "sqWin32File.h"

extern struct VirtualMachine *interpreterProxy;

#ifdef WIN32_FILE_SUPPORT

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
	  squeakFileOffsetType	 fileSize;	(* 64-bits we hope. *)
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


sqInt sqFileThisSession(void) {
  return thisSession;
}

sqInt sqFileAtEnd(SQFile *f) {
  win32FileOffset ofs;
  /* Return true if the file's read/write head is at the end of the file. */
  if (!sqFileValid(f))
    FAIL();
  /* If a stdio handle then assume not at end. */
  if (f->isStdioStream)
    return 0;
  ofs.offset = 0;
  ofs.dwLow = SetFilePointer(FILE_HANDLE(f), 0, &ofs.dwHigh, FILE_CURRENT);
  return ofs.offset >= sqFileSize(f);
}

sqInt sqFileClose(SQFile *f) {
  /* Close the given file. */

  if (!sqFileValid(f))
    FAIL();
  if(!CloseHandle(FILE_HANDLE(f)))
    FAIL();
  RemoveHandleFromTable(win32Files, FILE_HANDLE(f));
  f->file = NULL;
  f->sessionID = 0;
  f->writable = false;
  return 1;
}

sqInt sqFileDeleteNameSize(char* fileNameIndex, sqInt fileNameSize) {
  WCHAR *win32Path = NULL;

  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, fileNameIndex, fileNameSize);

  if(hasCaseSensitiveDuplicate(win32Path))
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

  if(!DeleteFileW(win32Path))
    FAIL();
  
  return 1;
}

squeakFileOffsetType sqFileGetPosition(SQFile *f) {
  win32FileOffset ofs;
  /* Return the current position of the file's read/write head. */
  if (!sqFileValid(f))
    FAIL();
  ofs.offset = 0;
  ofs.dwLow = SetFilePointer(FILE_HANDLE(f), 0, &ofs.dwHigh, FILE_CURRENT);
  return ofs.offset;
}

sqInt sqFileInit(void) {
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

sqInt sqFileShutdown(void) {
  return 1;
}

sqInt sqFileOpen(SQFile *f, char* fileNameIndex, sqInt fileNameSize, sqInt writeFlag) {
  /* Opens the given file using the supplied sqFile structure
     to record its state. Fails with no side effects if f is
     already open. Files are always opened in binary mode;
     Squeak must take care of any line-end character mapping.
  */
  HANDLE h;
  WCHAR *win32Path = NULL;

  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, fileNameIndex, fileNameSize);

  if(hasCaseSensitiveDuplicate(win32Path)) {
    f->sessionID = 0;
    FAIL();
  }
  h = CreateFileW(win32Path,
		  writeFlag ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ,
		  writeFlag ? FILE_SHARE_READ : (FILE_SHARE_READ | FILE_SHARE_WRITE),
		  NULL, /* No security descriptor */
		  writeFlag ? OPEN_ALWAYS : OPEN_EXISTING,
		  FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,
		  NULL /* No template */);
  if(h == INVALID_HANDLE_VALUE) {
    f->sessionID = 0;
    FAIL();
  } else {
    win32FileOffset ofs;
    f->sessionID = thisSession;
    f->file = (HANDLE)h;
    AddHandleToTable(win32Files, h);
    /* compute and cache file size */
    ofs.offset = 0;
    ofs.dwLow = SetFilePointer(h, 0, &ofs.dwHigh, FILE_END);
    SetFilePointer(h, 0, NULL, FILE_BEGIN);
    f->writable = writeFlag ? true : false;
  }
  return 1;
}

/*
 * Fill-in files with handles for stdin, stdout and seterr as available and
 * answer a bit-mask of the availability, 1 corresponding to stdin, 2 to stdout
 * and 4 to stderr, with 0 on error or unavailablity.
 */
sqInt
sqFileStdioHandlesInto(SQFile files[3])
{
	DWORD mode;

	files[0].sessionID = thisSession;
	files[0].file = GetStdHandle(STD_INPUT_HANDLE);
	files[0].fileSize = 0;
	files[0].writable = false;
	files[0].lastOp = 0; /* unused on win32 */
	files[0].isStdioStream = GetConsoleMode(files[0].file, &mode) != 0;
	AddHandleToTable(win32Files, files[0].file);

	files[1].sessionID = thisSession;
	files[1].file = GetStdHandle(STD_OUTPUT_HANDLE);
	files[1].fileSize = 0;
	files[1].writable = true;
	files[1].lastOp = 0; /* unused on win32 */
	files[1].isStdioStream = GetConsoleMode(files[1].file, &mode) != 0;
	AddHandleToTable(win32Files, files[1].file);

	files[2].sessionID = thisSession;
	files[2].file = GetStdHandle(STD_ERROR_HANDLE);
	files[2].fileSize = 0;
	files[2].writable = true;
	files[2].lastOp = 0; /* unused on win32 */
	files[2].isStdioStream = GetConsoleMode(files[2].file, &mode) != 0;
	AddHandleToTable(win32Files, files[2].file);

	return 7;
}

size_t sqFileReadIntoAt(SQFile *f, size_t count, char* byteArrayIndex, size_t startIndex) {
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
  return (int)dwReallyRead;
}

sqInt sqFileRenameOldSizeNewSize(char* oldNameIndex, sqInt oldNameSize, char* newNameIndex, sqInt newNameSize)
{
  WCHAR *oldPath = NULL;
  WCHAR *newPath = NULL;

  /* convert the file names into a null-terminated C string */
  ALLOC_WIN32_PATH(oldPath, oldNameIndex, oldNameSize);
  ALLOC_WIN32_PATH(newPath, newNameIndex, newNameSize);

  if(hasCaseSensitiveDuplicate(oldPath))
    FAIL();
  if(!MoveFileW(oldPath, newPath))
    FAIL();
  
  return 1;
}

sqInt sqFileSetPosition(SQFile *f, squeakFileOffsetType position)
{
  win32FileOffset ofs;
  ofs.offset = position;
  /* Set the file's read/write head to the given position. */
  if (!sqFileValid(f))
    FAIL();
  SetFilePointer(FILE_HANDLE(f), ofs.dwLow, &ofs.dwHigh, FILE_BEGIN);
  return 1;
}

squeakFileOffsetType sqFileSize(SQFile *f) {
  /* Return the length of the given file. */
  win32FileOffset ofs;
  if (!sqFileValid(f))
    FAIL();
  ofs.offset = 0;
  ofs.dwLow = GetFileSize(FILE_HANDLE(f), &ofs.dwHigh);
  return ofs.offset;
}

sqInt sqFileFlush(SQFile *f) {
  if (!sqFileValid(f))
    FAIL();
  /* note: ignores the return value in case of read-only access */
  FlushFileBuffers(FILE_HANDLE(f));
  return 1;
}

sqInt sqFileSync(SQFile *f) {
  /*
   * sqFileFlush uses FlushFileBuffers which is equivalent to fsync on windows
   * as long as WriteFile is used directly and no other buffering is done.
   */
  return sqFileFlush(f);
}

sqInt sqFileTruncate(SQFile *f, squeakFileOffsetType offset) {
  win32FileOffset ofs;
  ofs.offset = offset;
  if (!sqFileValid(f))
    FAIL();
  SetFilePointer(FILE_HANDLE(f), ofs.dwLow, &ofs.dwHigh, FILE_BEGIN);
  if(!SetEndOfFile(FILE_HANDLE(f))) return 0;
  return 1;
}

sqInt sqFileValid(SQFile *f) {
  if(NULL == f) return false;
  if(f->sessionID != thisSession) return false;
  if(!IsHandleInTable(win32Files, FILE_HANDLE(f))) {
    printf("WARNING: Manufactured file handle detected!\n");
    return false;
  }
  return true;
}

size_t sqFileWriteFromAt(SQFile *f, size_t count, char* byteArrayIndex, size_t startIndex) {
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
  
  if ((int)dwReallyWritten != count)
    FAIL();
  return (int) dwReallyWritten;
}

/***************************************************************************/
/* Image file functions                                                    */
/***************************************************************************/
sqInt sqImageFileClose(sqImageFile h)
{
  SetEndOfFile((HANDLE)(h-1));
  return CloseHandle((HANDLE)(h-1));
}

sqImageFile sqImageFileOpen(char *fileName, char *mode)
{ char *modePtr;
  int writeFlag = 0;
  WCHAR *win32Path = NULL;
  HANDLE h;

  if(!mode) return 0;
  modePtr = mode;
  while(*modePtr)
    {
      if(*modePtr == 'w') writeFlag = 1;
	  /* Note: We cannot append here */
	  if(*modePtr == 'a') return 0;
      modePtr++;
    }
  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, fileName, -1);

  if(hasCaseSensitiveDuplicate(win32Path))
    return 0;
  
  h = CreateFileW(win32Path,
		  writeFlag ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ,
		  writeFlag ? FILE_SHARE_READ : (FILE_SHARE_READ | FILE_SHARE_WRITE),
		  NULL, /* No security descriptor */
		  writeFlag ? CREATE_ALWAYS : OPEN_EXISTING,
		  FILE_ATTRIBUTE_NORMAL,
		  NULL /* No template */);

  if(h == INVALID_HANDLE_VALUE)
    return 0;
 
  return (usqIntptr_t)h+1;
}

squeakFileOffsetType sqImageFilePosition(sqImageFile h)
{
  win32FileOffset ofs;
  ofs.offset = 0;
  ofs.dwLow = SetFilePointer((HANDLE)(h-1), 0, &ofs.dwHigh, FILE_CURRENT);
  return ofs.offset;
}

size_t sqImageFileRead(void *ptr, size_t sz, size_t count, sqImageFile h)
{
  DWORD dwReallyRead;
  int position;
	
  position = sqImageFilePosition(h);
  ReadFile((HANDLE)(h-1), (LPVOID) ptr, count*sz, &dwReallyRead, NULL);
  while(dwReallyRead != (DWORD)(count*sz)) {
    DWORD err = GetLastError();
    if(sqMessageBox(MB_ABORTRETRYIGNORE, TEXT("Squeak Warning"),"Image file read problem (%d out of %d bytes read)", dwReallyRead, count*sz)
       == IDABORT) return (dwReallyRead / sz);
    sqImageFileSeek(h, position);
    ReadFile((HANDLE)(h-1), (LPVOID) ptr, count*sz, &dwReallyRead, NULL);
  }
  return (int)(dwReallyRead / sz);
}

squeakFileOffsetType sqImageFileSeek(sqImageFile h, squeakFileOffsetType pos)
{
  win32FileOffset ofs;
  ofs.offset = pos;
  ofs.dwLow = SetFilePointer((HANDLE)(h-1), ofs.dwLow, &ofs.dwHigh, FILE_BEGIN);
  return ofs.offset;
}

size_t sqImageFileWrite(void *ptr, size_t sz, size_t count, sqImageFile h)
{
  DWORD dwReallyWritten;
  WriteFile((HANDLE)(h-1), (LPVOID) ptr, count*sz, &dwReallyWritten, NULL);
  return (size_t) (dwReallyWritten / sz);
}

squeakFileOffsetType sqImageFileSize(sqImageFile h)
{
  win32FileOffset ofs;
  ofs.offset = 0;
  ofs.dwLow = GetFileSize((HANDLE)(h-1), &ofs.dwHigh);
  return ofs.offset;
}

#endif /* WIN32_FILE_SUPPORT */
