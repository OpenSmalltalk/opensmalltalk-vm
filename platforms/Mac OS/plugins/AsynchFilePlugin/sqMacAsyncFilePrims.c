#include "sq.h"
#include "AsynchFilePlugin.h"
#include "sqMacUnixFileInterface.h"
#if TARGET_API_MAC_CARBON
#include <Carbon/Carbon.h>
#else
	#include <devices.h>
	#include <string.h>
	#include <Errors.h>
	#include <Files.h>
	#include <Strings.h>
#endif

extern struct VirtualMachine* interpreterProxy;
#define success(bool) (interpreterProxy->success(bool))

#if !TARGET_API_MAC_CARBON
#define DisposeIOCompletionUPP(userUPP) DisposeRoutineDescriptor(userUPP)
#else
IOCompletionUPP NewIOCompletionUPP(IOCompletionProcPtr userRoutine);
void DisposeIOCompletionUPP(IOCompletionUPP userUPP);
#endif

/* initialize/shutdown */
int asyncFileInit() { return true; }
int asyncFileShutdown() {return true;} 

/* End of adjustments for pluginized VM */

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
  their buffer size if they are started less than a buffer's size from the end
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


/* Async file handle (defined in header file):
*/

typedef struct {
	ParamBlockRec pb;  /* must be first */
	long	refNum;
	int		writable;
	int		semaIndex;
	int		status;
	int		bytesTransferred;
	int		bufferSize;
	char 	*bufferPtr;
} AsyncFileState;

/*** Status Values ***/
#define IDLE			0
#define LAST_OP_FAILED	1
#define BUSY			2


/*** Local Vaiables ***/
IOCompletionUPP asyncFileCompletionProc = nil;

/*** Exported Functions ***/
int asyncFileClose(AsyncFile *f);
int asyncFileOpen(AsyncFile *f, char *fileNamePtr, int fileNameSize, int writeFlag, int semaIndex);
int asyncFileRecordSize();
int asyncFileReadResult(AsyncFile *f, void *bufferPtr, int bufferSize);
int asyncFileReadStart(AsyncFile *f, int fPosition, int count);
int asyncFileWriteResult(AsyncFile *f);
int asyncFileWriteStart(AsyncFile *f, int fPosition, void *bufferPtr, int bufferSize);

/*** Local Functions ***/
void asyncFileAllocateBuffer(AsyncFileState *state, int byteCount);
pascal void asyncFileCompletionRoutine(AsyncFileState *state);
void asyncFileInitPB(AsyncFileState *state, int fPosition);
int asyncFileValid(AsyncFile *f);

void asyncFileAllocateBuffer(AsyncFileState *state, int byteCount) {
  /* Allocate a new buffer of the given size if necessary. If the current buffer
	 is already allocated and of the desired size, do nothing. */

	if ((state->bufferPtr != nil) && (state->bufferSize == byteCount)) {
		return;  /* buffer is already allocated and of the desired size */
	}

	/* free old buffer, if any */
	if (state->bufferPtr != nil) {
		DisposePtr(state->bufferPtr);
		state->bufferSize = 0;
		state->bufferPtr = nil;
	}

	/* allocate new buffer */
	state->bufferPtr = NewPtr(byteCount);
	if (state->bufferPtr == nil) {
		state->bufferSize = 0;
		success(false);  /* could not allocate a buffer of size count */
		return;
	}
	state->bufferSize = byteCount;
}

pascal void asyncFileCompletionRoutine(AsyncFileState *state) {
  /* Called when an I/O request completes. Decides what to do based on the given state.
	 Note that the first part of the state record is the I/O parameter block. */

	OSErr err;

	err = state->pb.ioParam.ioResult;
	if ((err != noErr) && (err != eofErr)) {
		/* Note: eofErr indicates that fewer than the count bytes were transfered when
		   reading because the end-of-file was encountered first; it isn't a real error. */
		state->status = LAST_OP_FAILED;
		state->bytesTransferred = 0;
		interpreterProxy->signalSemaphoreWithIndex(state->semaIndex);
		return;
	}
	state->bytesTransferred = state->pb.ioParam.ioActCount;
	state->status = IDLE;
	interpreterProxy->signalSemaphoreWithIndex(state->semaIndex);
}

void asyncFileInitPB(AsyncFileState *state, int fPosition) {
	memset(&state->pb, 0, sizeof(ParamBlockRec));
	state->pb.ioParam.ioCompletion = asyncFileCompletionProc;
	state->pb.ioParam.ioRefNum = state->refNum;
	state->pb.ioParam.ioBuffer = state->bufferPtr;
	state->pb.ioParam.ioReqCount = state->bufferSize;
	state->pb.ioParam.ioPosMode = fsFromStart;
	state->pb.ioParam.ioPosOffset = (fPosition < 0) ? 0 : fPosition;
	state->status = BUSY;
	state->bytesTransferred = 0;
}

int asyncFileValid(AsyncFile *f) {
	return f
		&& f->sessionID == interpreterProxy->getThisSessionID()
		&& f->state
		&& ((AsyncFileState *)f->state)->refNum;
}

/*** Exported Functions ***/

int asyncFileClose(AsyncFile *f) {
  /* Close the given asynchronous file. */

	AsyncFileState *state;
	short int volRefNum;
	OSErr err;

	if (!asyncFileValid(f)) return 0;  /* already closed */
	state = f->state;

	err = GetVRefNum(state->refNum, &volRefNum);
	success(err == noErr);

	err = FSClose(state->refNum);
	success(err == noErr);

	if (!interpreterProxy->failed()) err = FlushVol(NULL, volRefNum);
	success(err == noErr);

    if (asyncFileCompletionProc != nil)
        DisposeIOCompletionUPP(asyncFileCompletionProc);
  
	asyncFileCompletionProc = nil;
	if (state->bufferPtr != nil) DisposePtr(state->bufferPtr);
	DisposePtr((void *) f->state);
	f->state = nil;
	f->sessionID = 0;
	return 0;
}

int asyncFileOpen(AsyncFile *f, char *fileNamePtr, int fileNameSize, int writeFlag, int semaIndex) {
  /* Opens the given file using the supplied AsyncFile structure to record
	 its state. Fails with no side effects if f is already open. Files are
	 always opened in binary mode. */

	short int fileRefNum;
	AsyncFileState *state;
	OSErr err;
	void * ithisSessionfn;
	int thisSession;
        FSSpec	theSpec; 

	/* don't open an already open file */
	if (asyncFileValid(f)) return success(false);

	/* build complete routine descriptor, if necessary */
	if (asyncFileCompletionProc == nil) {
#if TARGET_API_MAC_CARBON
		asyncFileCompletionProc = NewIOCompletionUPP((pascal void (*) (union ParamBlockRec *) )asyncFileCompletionRoutine);
#else
		asyncFileCompletionProc = NewIOCompletionProc((pascal void (*) (union ParamBlockRec *) )asyncFileCompletionRoutine);
#endif
	}

	/* copy the file name into a null-terminated C string */
	if (fileNameSize > 1000) return success(false);
	
	makeFSSpec((char*) fileNamePtr, fileNameSize,&theSpec);
        
	f->sessionID = 0;
	if (writeFlag) {
		/* first try to open an existing file read/write: */
		err = FSpOpenDF(&theSpec,fsRdWrPerm, &fileRefNum); 
		if (err != noErr) {
			/* file does not exist; must create it. */
			err = FSpCreate(&theSpec,'R*ch','TEXT',smSystemScript); 
			if (err != noErr) return success(false);
			err = FSpOpenDF(&theSpec,fsRdWrPerm, &fileRefNum); 
			if (err != noErr) return success(false);
		}
	} else {
		/* open the file read-only  */
		err = FSpOpenDF(&theSpec,fsRdPerm, &fileRefNum); 
		if (err != noErr) return success(false);
	}
	f->state = (AsyncFileState *) NewPtr(sizeof(AsyncFileState));	/* allocate state record */
	if (f->state == nil) {
		FSClose(fileRefNum);
		return success(false);
	}
	ithisSessionfn = interpreterProxy->ioLoadFunctionFrom("getThisSession", "FilePlugin");
	if (ithisSessionfn != 0)
		thisSession =  ((int (*) (void)) ithisSessionfn)();
	else 
		thisSession = 0;
	f->sessionID = thisSession;
	state = (AsyncFileState *) f->state;
	state->refNum = fileRefNum;
	state->writable = writeFlag;
	state->semaIndex = semaIndex;
	state->status = IDLE;
	state->bytesTransferred = 0;
	state->bufferSize = 0;
	state->bufferPtr = nil;
	return 0;
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

	AsyncFileState *state;
	int bytesRead;

	if (!asyncFileValid(f)) return success(false);
	state = f->state;
	if (state->status == BUSY) return -1;
	if (state->status == LAST_OP_FAILED) return -2;

	/* copy the file buffer into the squeak buffer */
	bytesRead = (bufferSize < state->bytesTransferred) ? bufferSize : state->bytesTransferred;
	memcpy(bufferPtr, state->bufferPtr, bytesRead);
	return bytesRead;
}

int asyncFileReadStart(AsyncFile *f, int fPosition, int count) {
  /* Start an asynchronous operation to read count bytes from the given file
	 starting at the given file position. The file's semaphore will be signalled when
	 the operation is complete. The client may then use asyncFileReadResult() to
	 find out if the operation succeeded and to get the data that was read. */

	AsyncFileState *state;
	OSErr err;

	if (!asyncFileValid(f)) return success(false);
	state = f->state;
	if (state->status == BUSY) return success(false);  /* operation in progress */

	/* allocate a new buffer if necessary */
	asyncFileAllocateBuffer(state, count);
	if (state->bufferPtr == nil) return success(false);  /* could not allocate buffer */

	asyncFileInitPB(state, fPosition);
	err = PBReadAsync(&state->pb);
	if (err != noErr) {
		state->status = IDLE;
		success(false);
		return 0;
	}
	return 0;
}

int asyncFileRecordSize() {
	return sizeof(AsyncFile);
}

int asyncFileWriteResult(AsyncFile *f) {
  /* Return the number of bytes copied by the last write operation.
	 Negative values indicate:
		-1    -- busy; the last operation has not finished yet
		-2    -- error; the last operation failed */

	AsyncFileState *state;

	if (!asyncFileValid(f)) return success(false);
	state = f->state;
	if (state->status == BUSY) return -1;
	if (state->status == LAST_OP_FAILED) return -2;
	return state->bytesTransferred;
}

int asyncFileWriteStart(AsyncFile *f, int fPosition, void *bufferPtr, int bufferSize) {
  /* Start an asynchronous operation to write bufferSize bytes to the given file
	 starting at the given file position. The file's semaphore will be signalled when
	 the operation is complete. The client may then use asyncFileWriteResult() to
	 find out if the operation succeeded and how many bytes were actually written. */

	AsyncFileState *state;
	OSErr err;

	if (!asyncFileValid(f)) return success(false);
	state = f->state;
	if (state->status == BUSY) return success(false);  /* operation in progress */
	if (!state->writable) return success(false);

	/* allocate a new buffer if necessary */
	asyncFileAllocateBuffer(state, bufferSize);
	if (state->bufferPtr == nil) return success(false);  /* could not allocate buffer */

	/* copy the squeak buffer into the file buffer */
	memcpy(state->bufferPtr, bufferPtr, bufferSize);

	asyncFileInitPB(state, fPosition);
	err = PBWriteAsync(&state->pb);
	if (err != noErr) {
		state->status = IDLE;
		return success(false);
	}
	return 0;
}
