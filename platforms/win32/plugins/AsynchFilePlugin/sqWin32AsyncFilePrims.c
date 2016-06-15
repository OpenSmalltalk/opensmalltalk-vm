/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32AsyncFilePrims.c
*   CONTENT: Asynchronous File functions
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:
*     1) Instead of the async io functions (e.g., ReadFileEx/WriteFileEx)
*        provided with Win32 threads are used because Win95 does not support
*        async io on disk files.
*
*****************************************************************************/
/*
  Experimental support for asynchronous file reading and writing.

  When a read or write operation is initiated, control is returned to Squeak
  immediately. A semaphore is signaled when the operation completes, at which
  time the client can find out how many bytes were actually read or written
  and copy the results of the read operation from the file buffer into a Squeak
  buffer. Only one operation may be in progress on a given file at a given time,
  but operations on different files may be done in parallel.

  The semaphore is signalled once for each transfer operation that is successfully
  started, even if that operation later fails. Write operations always write
  their entire buffer if they succeed, but read operations may transfer less than
  their buffer size if they are started less than a buffer''s size from the end
  of the file.
  
  The state of a file is kept in the following structure, which is stored directly
  in a Squeak ByteArray object:

    typedef struct {
	  int				sessionID;
	  AsyncFileState	*state;
    } AsyncFile;

  The session ID is used to detect stale files--files that were open
  when the image was saved. The state pointer of such files is meaningless.
  Async file handles use the same session ID as ordinary file handles.

  Note: These primitives are experimental! They need not be implemented on
  every platform, and they may be withdrawn or replaced in a future release.
*/
#include <windows.h>
#include "sq.h"
#include "AsynchFilePlugin.h"

#ifndef NO_ASYNC_FILES

/* Async file handle (defined in header file):
*/

#ifndef STACK_SIZE_PARAM_IS_A_RESERVATION
# define STACK_SIZE_PARAM_IS_A_RESERVATION 0x00010000
#endif

typedef struct {
  /* Win stuff */
  HANDLE hFile;		/* The file handle we're operating on */
  HANDLE hThread;		/* The thread running async IO */
  HANDLE hEvent;		/* Event for communicating with the thread */
  DWORD  dwPosition;	/* File position to start reading */
  DWORD  dwSize;		/* Number of bytes to transfer */
  BOOL   rFlag;		/* Do we read or write?! */

  /* Squeak stuff */
  int    writable;	 /* Was the file opened for write? */
  int    semaIndex;	 /* The semaphore to signal upon completion */
  int    status;	 /* State of affairs */
  DWORD  bytesTransferred; /* The number of bytes actually transferred */
  int    bufferSize; /* the size of the buffer */
  char 	*bufferPtr;	 /* the data buffer */
} AsyncFileState;

/*** Status Values ***/
#define IDLE			0
#define LAST_OP_FAILED	1
#define BUSY			2

/*** Imported Variables ***/
extern int successFlag;
extern int thisSession;

/*** Exported Functions ***/
int asyncFileClose(AsyncFile *f);
int asyncFileOpen(AsyncFile *f, char *fileNamePtr, int fileNameSize, int writeFlag, int semaIndex);
int asyncFileRecordSize();
int asyncFileReadResult(AsyncFile *f, void *bufferPtr, int bufferSize);
int asyncFileReadStart(AsyncFile *f, int fPosition, int count);
int asyncFileWriteResult(AsyncFile *f);
int asyncFileWriteStart(AsyncFile *f, int fPosition, void *bufferPtr, int bufferSize);


/*****************************************************************************
  Threads for async read/write
*****************************************************************************/
DWORD WINAPI sqAsyncFileThread(AsyncFileState *state)
{
  BOOL ok;

  while(state->hFile != INVALID_HANDLE_VALUE) {
    WaitForSingleObject(state->hEvent, INFINITE);
    if(state->hFile == INVALID_HANDLE_VALUE) break;
    if(!state->bufferPtr) {
      state->status = LAST_OP_FAILED;
      continue;
    }
    /* Seek to r/w position */
    if(SetFilePointer(state->hFile, state->dwPosition, NULL, FILE_BEGIN) == (DWORD)-1) {
      state->status = LAST_OP_FAILED;
      continue;
    }
    if(state->rFlag) {
      ok = ReadFile(state->hFile, state->bufferPtr, state->dwSize, &state->bytesTransferred, NULL);
    } else {
      ok = WriteFile(state->hFile, state->bufferPtr, state->dwSize, &state->bytesTransferred, NULL);
    }
    if(ok)
      state->status = IDLE;
    else
      state->status = LAST_OP_FAILED;
    synchronizedSignalSemaphoreWithIndex(state->semaIndex);
  }
  state->hThread = NULL;
  ExitThread(0);
  return 1;
}


/*****************************************************************************
  Local Functions
*****************************************************************************/

void *asyncAlloc(DWORD size) {
  return GlobalLock(GlobalAlloc(GMEM_MOVEABLE, size));
}

void asyncFree(void *ptr) {
  GlobalFree(GlobalHandle(ptr));
}

int asyncFileAllocateBuffer(AsyncFileState *state, int byteCount) {
  /* Allocate a new buffer of the given size if necessary. If the current buffer
     is already allocated and of the desired size, do nothing. */

  if ((state->bufferPtr != NULL) && (state->bufferSize >= byteCount)) {
    return 0;  /* buffer is already allocated and of (at least) the desired size */
  }

  /* free old buffer, if any */
  if (state->bufferPtr != NULL) {
    asyncFree(state->bufferPtr);
    state->bufferSize = 0;
    state->bufferPtr = NULL;
  }
  /* allocate new buffer */
  state->bufferPtr = asyncAlloc(byteCount);
  if (state->bufferPtr == NULL) {
    state->bufferSize = 0;
    return success(false);  /* could not allocate a buffer of size count */
  }
  state->bufferSize = byteCount;
  return 1;
}

int asyncFileValid(AsyncFile *f) {
  return (
	  (f != NULL) &&
	  (f->sessionID == thisSession) &&
	  (f->state != NULL) &&
	  (((AsyncFileState *) f->state)->hFile != INVALID_HANDLE_VALUE));
}

/*****************************************************************************
  Exported Functions
*****************************************************************************/

int asyncFileClose(AsyncFile *f) {
  /* Close the given asynchronous file. */

  AsyncFileState *state;

  if (!asyncFileValid(f)) return 0;  /* already closed */
  state = (AsyncFileState*) f->state;
  if(!CloseHandle(state->hFile)) {
    printLastError(TEXT("AsyncFileClose failed"));
    success(false);
  }
  state->hFile = INVALID_HANDLE_VALUE;
  SetEvent(state->hEvent);
  WaitForSingleObject(state->hThread, 5000);
  if(state->hThread) {
    warnPrintf(TEXT("Terminating async thread"));
    TerminateThread(state->hThread,0);
  }
  CloseHandle(state->hEvent);
  if (state->bufferPtr != NULL) asyncFree(state->bufferPtr);
  free((void *) f->state);
  f->state = NULL;
  f->sessionID = 0;
  return 1;
}

int asyncFileOpen(AsyncFile *f, char *fileNamePtr, int fileNameSize, 
		  int writeFlag, int semaIndex) {
  /* Opens the given file using the supplied AsyncFile structure to record
     its state. Fails with no side effects if f is already open. Files are
     always opened in binary mode. */

  int i;
  char  cFileName[256];
  WCHAR wFileName[256];
  AsyncFileState *state;
  HANDLE hFile;
  DWORD id;

  /* don''t open an already open file */
  if (asyncFileValid(f)) return success(false);

  /* copy the file name into a null-terminated C string */
  if (fileNameSize > 255) return success(false);
  for (i = 0; i < fileNameSize; i++) {
    cFileName[i] = *(fileNamePtr + i);
  }
  cFileName[fileNameSize] = 0;

  /* Convert to Unicode */
  MultiByteToWideChar(CP_UTF8, 0, cFileName, -1, wFileName, 255);

  f->sessionID = 0;
  hFile = CreateFileW(wFileName,
	    writeFlag ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ,
	    writeFlag ? FILE_SHARE_READ : (FILE_SHARE_READ | FILE_SHARE_WRITE),
	    NULL, /* No security descriptor */
	    writeFlag ? OPEN_ALWAYS : OPEN_EXISTING,
	    FILE_ATTRIBUTE_NORMAL,
	    NULL /* No template */);
  if(hFile == INVALID_HANDLE_VALUE)
    return success(false);
  f->state = (AsyncFileState *) 
    calloc(1,sizeof(AsyncFileState));	/* allocate state record */
  if (f->state == NULL) {
    CloseHandle(hFile);
    return success(false);
  }
  f->sessionID = thisSession;
  state = (AsyncFileState *) f->state;
  state->hFile = hFile;
  state->writable = writeFlag;
  state->semaIndex = semaIndex;
  state->status = IDLE;
  state->bytesTransferred = 0;
  state->bufferSize = 0;
  state->bufferPtr = NULL;
  state->hEvent = CreateEvent(NULL, 0, 0, NULL);
  state->hThread =
    CreateThread(NULL,                    /* No security descriptor */
		 128*1024,                /* max stack size     */
		 (LPTHREAD_START_ROUTINE) &sqAsyncFileThread, /* what to do */
		 (LPVOID) state,       /* parameter for thread   */
		 CREATE_SUSPENDED | STACK_SIZE_PARAM_IS_A_RESERVATION,
		 &id);                    /* return value for thread id */
  if(!state->hThread) {
    printLastError(TEXT("CreateThread() failed"));
    return success(false);
  }
  /* file operations run with high priority */
  if(!SetThreadPriority(state->hThread, THREAD_PRIORITY_HIGHEST))
    printLastError(TEXT("SetThreadPriority() failed"));
  if(!ResumeThread(state->hThread)) {
    printLastError(TEXT("ResumeThread() failed"));
    return success(false);
  }
  return 1;
}

int asyncFileReadResult(AsyncFile *f, void *bufferPtr, int bufferSize) {
  /* Copy up to bufferSize bytes from the buffer of the last read operation
     into the given Squeak buffer, and return the number of bytes copied.
     Negative values indicate:
     -1    -- busy; the last operation has not finished yet
     -2    -- error; the last operation failed
     Note that a read operation may read fewer bytes than requested if, for
     example, there are fewer than the requested number of bytes between the
     starting file position of the read operation and the end-of-file. */

  AsyncFileState *state = (AsyncFileState *) f->state;
  int bytesRead;

  if (!asyncFileValid(f)) return success(false);
  if (state->status == BUSY) return -1;
  if (state->status == LAST_OP_FAILED) return -2;
  
  /* copy the file buffer into the squeak buffer */
  bytesRead = (bufferSize < state->bytesTransferred) ? bufferSize : state->bytesTransferred;
  MoveMemory(bufferPtr, (void *)state->bufferPtr, bytesRead);
  return bytesRead;
}

int asyncFileReadStart(AsyncFile *f, int fPosition, int count) {
  /* Start an asynchronous operation to read count bytes from the given file
     starting at the given file position. The file''s semaphore will be signalled when
     the operation is complete. The client may then use asyncFileReadResult() to
     find out if the operation succeeded and to get the data that was read. */
  AsyncFileState *state = (AsyncFileState *) f->state;
  
  if (!asyncFileValid(f)) return success(false);
  if (state->status == BUSY) return success(false);  /* operation in progress */
  
  /* allocate a new buffer if necessary */
  asyncFileAllocateBuffer(state, count);
  if (state->bufferPtr == NULL) return success(false);  /* could not allocate buffer */

  state->dwPosition = fPosition;
  state->dwSize = count;
  state->status = BUSY;
  state->rFlag = TRUE;
  SetEvent(state->hEvent);
  return 1;
}

int asyncFileRecordSize() {
  return sizeof(AsyncFile);
}

int asyncFileWriteResult(AsyncFile *f) {
  /* Return the number of bytes copied by the last write operation.
     Negative values indicate:
     -1    -- busy; the last operation has not finished yet
     -2    -- error; the last operation failed */

  AsyncFileState *state = (AsyncFileState *) f->state;
  
  if (!asyncFileValid(f)) return success(false);
  if (state->status == BUSY) return -1;
  if (state->status == LAST_OP_FAILED) return -2;
  return state->bytesTransferred;
}

int asyncFileWriteStart(AsyncFile *f, int fPosition, void *bufferPtr, int bufferSize) {
  /* Start an asynchronous operation to write bufferSize bytes to the given file
     starting at the given file position. The file''s semaphore will be signalled when
     the operation is complete. The client may then use asyncFileWriteResult() to
     find out if the operation succeeded and how many bytes were actually written. */
  AsyncFileState *state = (AsyncFileState *) f->state;

  if (!asyncFileValid(f)) return success(false);
  if (state->status == BUSY) return success(false);  /* operation in progress */
  if (!state->writable) return success(false);

  /* allocate a new buffer if necessary */
  asyncFileAllocateBuffer(state, bufferSize);
  if (state->bufferPtr == NULL) return success(false);  /* could not allocate buffer */

  /* copy the squeak buffer into the file buffer */
  MoveMemory((void*)state->bufferPtr, bufferPtr, bufferSize);

  state->dwPosition = fPosition;
  state->dwSize = bufferSize;
  state->status = BUSY;
  state->rFlag = FALSE;
  SetEvent(state->hEvent);
  return 1;
}


int asyncFileInit(void)
{
  return 1;
}

int asyncFileShutdown(void)
{
  return 1;
}

#endif /* NO_ASYNC_FILES */
