/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32FilePrims.c
*   CONTENT: File functions
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32FilePrims.c,v 1.3 2002/01/28 13:56:59 slosher Exp $
*
*   NOTES:
*     1) This is a bare windows implementation *not* using any stdio stuff.
*        It can be used instead of the standard sqFilePrims.c file on systems
*        not having standard io libraries (e.g. WinCE)
*     2) For using this you'll need to define WIN32_FILE_SUPPORT globally
*        (e.g., in your compiler's project settings)
*
*****************************************************************************/
#include <windows.h>
#include "sq.h"
#include "FilePlugin.h"

#ifdef WIN32_FILE_SUPPORT

#define true  1
#define false 0

#define FILE_HANDLE(f) ((HANDLE) (f)->file)

/***
    The state of a file is kept in the following structure,
    which is stored directly in a Squeak bytes object.
    NOTE: The Squeak side is responsible for creating an
    object with enough room to store sizeof(SQFile) bytes.
    
    The session ID is used to detect stale file objects--
    files that were still open when an image was written.
    The file pointer of such files is meaningless.
    
    typedef struct {
      File	*file;
      int		sessionID;
      int		writable;
      int		fileSize;
    } SQFile;

***/

/*** Variables ***/
int thisSession = 0;
extern unsigned char *memory;

int sqFileAtEnd(SQFile *f) {
  /* Return true if the file's read/write head is at the end of the file. */
  if (!sqFileValid(f)) return success(false);
  return 
    SetFilePointer(FILE_HANDLE(f), 0, NULL, FILE_CURRENT) == (DWORD) f->fileSize;
}

int sqFileClose(SQFile *f) {
  /* Close the given file. */

  if (!sqFileValid(f)) return success(false);
  if(!CloseHandle(FILE_HANDLE(f))) return success(false);
  f->file = NULL;
  f->sessionID = 0;
  f->writable = false;
  f->fileSize = 0;
  return 1;
}

int sqFileDeleteNameSize(int sqFileNameIndex, int sqFileNameSize) {

  TCHAR *win32Path;
  if (sqFileNameSize >= MAX_PATH) {
    return success(false);
  }
  /* copy the file name into a null-terminated C string */
  win32Path = fromSqueak((char*)sqFileNameIndex, sqFileNameSize);
  if(!DeleteFile(win32Path))
    return success(false);
  return 1;
}

int sqFileGetPosition(SQFile *f) {
  /* Return the current position of the file's read/write head. */

  DWORD position;

  if (!sqFileValid(f)) return success(false);
  position = SetFilePointer(FILE_HANDLE(f), 0, NULL, FILE_CURRENT);
  return (int) position;
}

int sqFileInit(void) {
  /* Create a session ID that is unlikely to be repeated.
     Zero is never used for a valid session number.
     Should be called once at startup time.
  */

  thisSession = GetTickCount();
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
  HANDLE h;
  TCHAR *win32Path = fromSqueak((char*)sqFileNameIndex, sqFileNameSize);

  h = CreateFile(win32Path,
                 writeFlag ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ,
                 writeFlag ? FILE_SHARE_READ : (FILE_SHARE_READ | FILE_SHARE_WRITE),
                 NULL, /* No security descriptor */
                 writeFlag ? OPEN_ALWAYS : OPEN_EXISTING,
                 FILE_ATTRIBUTE_NORMAL,
                 NULL /* No template */);
  if(h == INVALID_HANDLE_VALUE) {
    f->sessionID = 0;
    f->fileSize = 0;
    return success(false);
  } else {
    f->sessionID = thisSession;
    FILE_HANDLE(f) = h;
    /* compute and cache file size */
    f->fileSize = SetFilePointer(h, 0, NULL, FILE_END);
    SetFilePointer(h, 0, NULL, FILE_BEGIN);
    f->writable = writeFlag ? true : false;
  }
  return 1;
}

int sqFileReadIntoAt(SQFile *f, int count, int byteArrayIndex, int startIndex) {
  /* Read count bytes from the given file into byteArray starting at
     startIndex. byteArray is the address of the first byte of a
     Squeak bytes object (e.g. String or ByteArray). startIndex
     is a zero-based index; that is a startIndex of 0 starts writing
     at the first byte of byteArray.
  */
  DWORD dwReallyRead;

  if (!sqFileValid(f)) return success(false);
  ReadFile(FILE_HANDLE(f), (LPVOID) (byteArrayIndex+startIndex), count, &dwReallyRead, NULL);
  return (int)dwReallyRead;
}

int sqFileRenameOldSizeNewSize(int oldNameIndex, int oldNameSize, int newNameIndex, int newNameSize)
{
  TCHAR *oldPath = fromSqueak((char*)oldNameIndex, oldNameSize);
  TCHAR *newPath = fromSqueak2((char*)newNameIndex,newNameSize);

  if(!MoveFile(oldPath, newPath))
    return success(false);
  return 1;
}

int sqFileSetPosition(SQFile *f, int position)
{
  /* Set the file's read/write head to the given position. */
  if (!sqFileValid(f)) return success(false);
  SetFilePointer(FILE_HANDLE(f), position, NULL, FILE_BEGIN);
  return 1;
}

int sqFileSize(SQFile *f) {
  /* Return the length of the given file. */
  
  if (!sqFileValid(f)) return success(false);
  return f->fileSize;
}

int sqFileFlush(SQFile *f) {
  if (!sqFileValid(f)) return success(false);
  /* note: ignores the return value in case of read-only access */
  FlushFileBuffers(FILE_HANDLE(f));
  return 1;
}

int sqFileTruncate(SQFile *f, int offset) {
  if (!sqFileValid(f)) return success(false);
  SetFilePointer(FILE_HANDLE(f), offset, NULL, FILE_BEGIN);
  if(!SetEndOfFile(FILE_HANDLE(f))) return 0;
  return 1;
}

int sqFileValid(SQFile *f) {
  return (
	  (f != NULL) &&
	  (f->file != INVALID_HANDLE_VALUE) &&
	  (f->sessionID == thisSession));
}

int sqFileWriteFromAt(SQFile *f, int count, int byteArrayIndex, int startIndex) {
  /* Write count bytes to the given writable file starting at startIndex
     in the given byteArray. (See comment in sqFileReadIntoAt for interpretation
     of byteArray and startIndex).
  */
  DWORD dwReallyWritten;
  if (!(sqFileValid(f) && f->writable)) return success(false);

  WriteFile(FILE_HANDLE(f), (LPVOID) (byteArrayIndex + startIndex), count, &dwReallyWritten, NULL);
  /* update file size */
  f->fileSize = GetFileSize(FILE_HANDLE(f), NULL);
  
  if ((int)dwReallyWritten != count) {
    success(false);
  }
  return (int) dwReallyWritten;
}

int sqFileThisSession() {
	return thisSession;
}

/***************************************************************************/
/* Image file functions                                                    */
/***************************************************************************/
int sqImageFileClose(sqImageFile h)
{
  SetEndOfFile((HANDLE)(h-1));
  return CloseHandle((HANDLE)(h-1));
}

sqImageFile sqImageFileOpen(char *fileName, char *mode)
{ char *modePtr;
  int writeFlag = 0;
  TCHAR *win32Path;
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
  win32Path = fromSqueak(fileName, strlen(fileName));
  h = CreateFile(win32Path,
                 writeFlag ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ,
                 writeFlag ? FILE_SHARE_READ : (FILE_SHARE_READ | FILE_SHARE_WRITE),
                 NULL, /* No security descriptor */
                 writeFlag ? CREATE_ALWAYS : OPEN_EXISTING,
                 FILE_ATTRIBUTE_NORMAL,
                 NULL /* No template */);
  if(h == INVALID_HANDLE_VALUE) return 0;
  return (DWORD)h+1;
}

int sqImageFilePosition(sqImageFile h)
{
  return (int)SetFilePointer((HANDLE)(h-1), 0, NULL, FILE_CURRENT);
}

int sqImageFileRead(void *ptr, int sz, int count, sqImageFile h)
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

int sqImageFileSeek(sqImageFile h, int pos)
{
  return (int) SetFilePointer((HANDLE)(h-1), pos, NULL, FILE_BEGIN);
}

int sqImageFileWrite(void *ptr, int sz, int count, sqImageFile h)
{
  DWORD dwReallyWritten;
  WriteFile((HANDLE)(h-1), (LPVOID) ptr, count*sz, &dwReallyWritten, NULL);
  return (int) (dwReallyWritten / sz);
}

int sqImageFileSize(sqImageFile h)
{
  return GetFileSize((HANDLE)(h-1), NULL);
}

#endif /* WIN32_FILE_SUPPORT */
