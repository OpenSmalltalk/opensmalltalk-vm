/* Automatically generated from Squeak on #(18 March 2005 7:42:49 pm) */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif
#include <sys/types.h>
/* D T Lewis 2003 - UnixOSProcessPlugin.c translated from class
   UnixOSProcessPluginNoThisSessionAvailable of OSProcessPlugin version 3.3 */
#include <sys/time.h>
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#define FILEHANDLETYPE FILE *
#include "aio.h"
#include "FilePlugin.h"
#include "SocketPlugin.h"
#define SESSIONIDENTIFIERTYPE int

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/

/*** Function Prototypes ***/
static void aioForwardwithDataandFlags(int fd, void * data, int flags);
static char * cStringFromString(int aString);
static void * callocWrappersize(int count, int objectSize);
static int copyBytesFromtolength(unsigned char * charArray1, unsigned char * charArray2, int len);
static int createPipeForReaderwriter(FILEHANDLETYPE * readerIOStreamPtr, FILEHANDLETYPE * writerIOStreamPtr);
static int descriptorTableSize(void);
static void dupToStdErr(int anSQFileDataStructure);
static void dupToStdIn(int anSQFileDataStructure);
static void dupToStdOut(int anSQFileDataStructure);
static int fileDescriptorFrom(int aFileHandle);
static int fileRecordSize(void);
static SQFile * fileValueOf(int anSQFileRecord);
static int fixPointersInArrayOfStringswithOffsetscount(char *flattenedArrayOfStrings, int *offsetArray, int count);
static int forkAndExecInDirectory(int useSignalHandler);
#pragma export on
EXPORT(int) forkSqueak(int useSignalHandler);
#pragma export off
static void * forwardSignaltoSemaphoreAt(int sigNum, int semaphoreIndex);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int getThisSessionIdentifier(void);
static int halt(void);
static void handleSignal(int sigNum);
static void * handleSignalFunctionAddress(void);
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int isSQFileObject(int objectPointer);
static int makePipeForReaderwriter(FILEHANDLETYPE * readerIOStreamPtr, FILEHANDLETYPE * writerIOStreamPtr);
static void * mallocWrapper(int size);
static int msg(char *s);
static int newSQFileByteArray(void);
static int newSQSocketByteArray(void);
static void ** originalSignalHandlers(void);
static void * pointerFrom(int aByteArray);
static int primFixPointersInArrayOfStringswithOffsetscount(int cStringArray, int offsetArray, int count);
#pragma export on
EXPORT(int) primitiveAioDisable(void);
EXPORT(int) primitiveAioEnable(void);
EXPORT(int) primitiveAioHandle(void);
EXPORT(int) primitiveAioSuspend(void);
EXPORT(int) primitiveArgumentAt(void);
EXPORT(int) primitiveCanReceiveSignals(int anIntegerPid);
EXPORT(int) primitiveChdir(void);
EXPORT(int) primitiveCreatePipe(void);
EXPORT(int) primitiveCreatePipeWithSessionIdentifier(void);
EXPORT(int) primitiveEnvironmentAt(void);
EXPORT(int) primitiveEnvironmentAtSymbol(void);
EXPORT(int) primitiveErrorMessageAt(void);
EXPORT(int) primitiveFileProtectionMask(void);
EXPORT(int) primitiveFileStat(void);
EXPORT(int) primitiveFixPointersInArrayOfStrings(void);
EXPORT(int) primitiveForkAndExecInDirectory(void);
EXPORT(int) primitiveForkExec(void);
EXPORT(int) primitiveForkSqueak(void);
EXPORT(int) primitiveForkSqueakWithoutSigHandler(void);
EXPORT(int) primitiveForwardSignalToSemaphore(void);
EXPORT(int) primitiveGetCurrentWorkingDirectory(void);
EXPORT(int) primitiveGetEGid(void);
EXPORT(int) primitiveGetEUid(void);
EXPORT(int) primitiveGetGid(void);
EXPORT(int) primitiveGetPPid(void);
EXPORT(int) primitiveGetPid(void);
EXPORT(int) primitiveGetSession(void);
EXPORT(int) primitiveGetStdErrHandle(void);
EXPORT(int) primitiveGetStdErrHandleWithSessionIdentifier(void);
EXPORT(int) primitiveGetStdInHandle(void);
EXPORT(int) primitiveGetStdInHandleWithSessionIdentifier(void);
EXPORT(int) primitiveGetStdOutHandle(void);
EXPORT(int) primitiveGetStdOutHandleWithSessionIdentifier(void);
EXPORT(int) primitiveGetUid(void);
EXPORT(int) primitiveIsAtEndOfFile(void);
EXPORT(int) primitiveLockFileRegion(void);
EXPORT(int) primitiveMakePipe(void);
EXPORT(int) primitiveMakePipeWithSessionIdentifier(void);
EXPORT(int) primitiveModuleName(void);
EXPORT(int) primitivePutEnv(void);
EXPORT(int) primitiveRealpath(void);
EXPORT(int) primitiveReapChildProcess(void);
EXPORT(int) primitiveSQFileFlush(void);
EXPORT(int) primitiveSQFileFlushWithSessionIdentifier(void);
EXPORT(int) primitiveSQFileSetBlocking(void);
EXPORT(int) primitiveSQFileSetBlockingWithSessionIdentifier(void);
EXPORT(int) primitiveSQFileSetNonBlocking(void);
EXPORT(int) primitiveSQFileSetNonBlockingWithSessionIdentifier(void);
EXPORT(int) primitiveSQFileSetUnbuffered(void);
EXPORT(int) primitiveSQFileSetUnbufferedWithSessionIdentifier(void);
EXPORT(int) primitiveSemaIndexFor(void);
EXPORT(int) primitiveSendSigabrtTo(int anIntegerPid);
EXPORT(int) primitiveSendSigalrmTo(int anIntegerPid);
EXPORT(int) primitiveSendSigchldTo(int anIntegerPid);
EXPORT(int) primitiveSendSigcontTo(int anIntegerPid);
EXPORT(int) primitiveSendSighupTo(int anIntegerPid);
EXPORT(int) primitiveSendSigintTo(int anIntegerPid);
EXPORT(int) primitiveSendSigkillTo(int anIntegerPid);
EXPORT(int) primitiveSendSigpipeTo(int anIntegerPid);
EXPORT(int) primitiveSendSigquitTo(int anIntegerPid);
EXPORT(int) primitiveSendSigstopTo(int anIntegerPid);
EXPORT(int) primitiveSendSigtermTo(int anIntegerPid);
EXPORT(int) primitiveSendSigusr1To(int anIntegerPid);
EXPORT(int) primitiveSendSigusr2To(int anIntegerPid);
EXPORT(int) primitiveSetSemaIndex(void);
EXPORT(int) primitiveSigChldNumber(void);
EXPORT(int) primitiveSigHupNumber(void);
EXPORT(int) primitiveSigIntNumber(void);
EXPORT(int) primitiveSigKillNumber(void);
EXPORT(int) primitiveSigPipeNumber(void);
EXPORT(int) primitiveSigQuitNumber(void);
EXPORT(int) primitiveSigTermNumber(void);
EXPORT(int) primitiveSizeOfInt(void);
EXPORT(int) primitiveSizeOfPointer(void);
EXPORT(int) primitiveTestLockableFileRegion(void);
EXPORT(int) primitiveUnixFileClose(int anIntegerFileNumber);
EXPORT(int) primitiveUnixFileNumber(void);
EXPORT(int) primitiveUnlockFileRegion(void);
EXPORT(int) primitiveUnsetEnv(void);
EXPORT(int) primitiveVersionString(void);
#pragma export off
static void reapChildProcess(int sigNum);
static void restoreDefaultSignalHandlers(void);
static int sandboxSecurity(void);
static int securityHeurisitic(void);
static unsigned char * semaphoreIndices(void);
static SESSIONIDENTIFIERTYPE sessionIdentifierFrom(int aByteArray);
#pragma export on
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static void setSigChldDefaultHandler(void);
static void setSigChldHandler(void);
static void setSigIntDefaultHandler(void);
static void setSigIntIgnore(void);
static void setSigPipeDefaultHandler(void);
static int setSigPipeHandler(void);
static void setSigPipeIgnore(void);
static void * setSignalNumberhandler(int anInteger, void * signalHandlerAddress);
#pragma export on
EXPORT(int) shutdownModule(void);
#pragma export off
static int sigChldNumber(void);
static void * sigDefaultNumber(void);
static void * sigErrorNumber(void);
static int sigHupNumber(void);
static void * sigIgnoreNumber(void);
static int sigIntNumber(void);
static int sigKillNumber(void);
static int sigPipeNumber(void);
static int sigQuitNumber(void);
static int sigTermNumber(void);
static int signalArraySize(void);
static void ** signalHandlers(void);
static int sizeOfInt(void);
static int sizeOfPointer(void);
static int sizeOfSession(void);
static int socketRecordSize(void);
static SQSocket * socketValueOf(int anSQSocketRecord);
static int stringFromCString(char *aCString);
static char * transientCStringFromString(int aString);
static char * versionString(void);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"UnixOSProcessPlugin 18 March 2005 (i)"
#else
	"UnixOSProcessPlugin 18 March 2005 (e)"
#endif
;
static void *originalSigHandlers[NSIG];
static int osprocessSandboxSecurity;
static unsigned char semaIndices[NSIG];
static int sigChldSemaIndex;
static void *sigHandlers[NSIG];
static int smallIntegerMaxVal= 1073741823;
static int vmThread;



/*	This function is called to signal a Smalltalk Semaphore when an asynchronous event is
	detected. When translated to C, the name of this method is aioForwardwithDataandFlags.
	The event handler is set up by #primitiveAioHandle. */

static void aioForwardwithDataandFlags(int fd, void * data, int flags) {
    int *pfd;
    int semaIndex;

	pfd = data;
	semaIndex = *pfd;
	interpreterProxy->signalSemaphoreWithIndex(semaIndex);
}


/*	Answer a new null-terminated C string copied from aString. The C string
	is allocated from the C runtime heap. See transientCStringFromString for
	a version which allocates from object memory.
	Caution: This may invoke the garbage collector. */

static char * cStringFromString(int aString) {
    int len;
    char *sPtr;
    char *cString;

	sPtr = interpreterProxy->arrayValueOf(aString);
	len = interpreterProxy->sizeOfSTArrayFromCPrimitive(sPtr);

	/* Space for a null terminated C string. */

	cString = callocWrappersize(len + 1, 1);
	(char *) strncpy (cString, sPtr, len);
	return cString;
}


/*	Using malloc() and calloc() is something I would like to avoid, since it is
	likely to cause problems some time in the future if somebody redesigns
	object memory allocation. This wrapper just makes it easy to find senders
	of calloc() in my code. -dtl */

static void * callocWrappersize(int count, int objectSize) {
	return calloc(count, objectSize);
}


/*	| chars |
	chars _ 'abcd'.
	self new copyBytesFrom: 'wxyz' to: chars length: 4.
	chars */

static int copyBytesFromtolength(unsigned char * charArray1, unsigned char * charArray2, int len) {
    unsigned char *p1;
    int idx;
    unsigned char *p2;

	p1 = charArray1;
	p2 = charArray2;
	idx = 0;
	while (idx < len) {
		*p2 = *p1;
		p1 += 1;
		p2 += 1;
		idx += 1;
	}
}


/*	Create a pipe and populate the readerIOStream and writerIOStream variables.
	The SIGPIPE handler must have been set before creating the pipe. Answer true for
	success, else false. */

static int createPipeForReaderwriter(FILEHANDLETYPE * readerIOStreamPtr, FILEHANDLETYPE * writerIOStreamPtr) {
    int filedes[2];

	if ((pipe(filedes)) == -1) {
		return 0;
	} else {
		*writerIOStreamPtr= (FILE *) fdopen (filedes[1], "a");
		*readerIOStreamPtr= (FILE *) fdopen (filedes[0], "r");
		return 1;
	}
}


/*	Answer the size of the file descriptor table for a process. I am not sure of the most portable
	way to do this. If this implementation does not work on your Unix platform, try changing
	it to answer the value of FOPEN_MAX, which will hopefully be defined in stdio.h. If
	all else fails, just hard code it to answer 20, which would be safe for any Unix. */

static int descriptorTableSize(void) {
	return getdtablesize();
}


/*	Dup a file descriptor to allow it to be attached as the standard error when we
	exec() a new executable. This is Unix specific, in that it assumes that file descriptor
	0 is stdin, 1 is stdout, and 2 is stderr. The dup2() call is used to copy the open file
	descriptors into file descriptors 0, 1 and 2 so that the image which we execute will
	use them as stdin, stdout, and stderr. */

static void dupToStdErr(int anSQFileDataStructure) {
    int filenoToDup;

	filenoToDup = fileDescriptorFrom(anSQFileDataStructure);
	if (!(filenoToDup < 0)) {
		if (!(filenoToDup == 2)) {
			fflush(stderr);
			dup2(filenoToDup, 2);
		}
	}
}


/*	Dup a file descriptor to allow it to be attached as the standard input when we
	exec() a new executable. This is Unix specific, in that it assumes that file descriptor
	0 is stdin, 1 is stdout, and 2 is stderr. The dup2() call is used to copy the open file
	descriptors into file descriptors 0, 1 and 2 so that the image which we execute will
	use them as stdin, stdout, and stderr. */

static void dupToStdIn(int anSQFileDataStructure) {
    int filenoToDup;

	filenoToDup = fileDescriptorFrom(anSQFileDataStructure);
	if (!(filenoToDup < 0)) {
		if (!(filenoToDup == 0)) {
			fflush(stdin);
			dup2(filenoToDup, 0);
			rewind(stdin);
		}
	}
}


/*	Dup a file descriptor to allow it to be attached as the standard output when we
	exec() a new executable. This is Unix specific, in that it assumes that file descriptor
	0 is stdin, 1 is stdout, and 2 is stderr. The dup2() call is used to copy the open file
	descriptors into file descriptors 0, 1 and 2 so that the image which we execute will
	use them as stdin, stdout, and stderr. */

static void dupToStdOut(int anSQFileDataStructure) {
    int filenoToDup;

	filenoToDup = fileDescriptorFrom(anSQFileDataStructure);
	if (!(filenoToDup < 0)) {
		if (!(filenoToDup == 1)) {
			fflush(stdout);
			dup2(filenoToDup, 1);
		}
	}
}


/*	Answer the OS file descriptor, an integer value, from a SQFile data structure,
	or answer -1 if unable to obtain the file descriptor (probably due to receiving
	an incorrect type of object as aFileHandle). This method may be called from a
	primitive, and is not intended to be called from Smalltalk. */

static int fileDescriptorFrom(int aFileHandle) {
    SQFile * sqFile;
    FILE *osFileStream;

	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(aFileHandle)) && ((interpreterProxy->byteSizeOf(aFileHandle)) == (fileRecordSize()))) {
		sqFile = interpreterProxy->arrayValueOf(aFileHandle);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		sqFile = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	if (sqFile == 0) {
		return -1;
	} else {
		osFileStream = sqFile->file;
		if (osFileStream == 0) {
			return -1;
		}
		return fileno(osFileStream);
	}
}


/*	Answer the size of a SQFile data structure in bytes. */

static int fileRecordSize(void) {
	return sizeof(SQFile);
}


/*	Return a pointer to the first byte of of the SQFile data structure file record within
	anSQFileRecord, which is expected to be a ByteArray of size self>>fileRecordSize. */

static SQFile * fileValueOf(int anSQFileRecord) {
	if ((interpreterProxy->isBytes(anSQFileRecord)) && ((interpreterProxy->byteSizeOf(anSQFileRecord)) == (fileRecordSize()))) {
		return interpreterProxy->arrayValueOf(anSQFileRecord);
	} else {
		interpreterProxy->primitiveFail();
		return null;
	}
}


/*	Use the address offsets in offsetArray to fix up the pointers in cStringArray.
	The result is a C array of pointers to char, used for argv and env vectors. */

static int fixPointersInArrayOfStringswithOffsetscount(char *flattenedArrayOfStrings, int *offsetArray, int count) {
    char **ptr;
    int idx;

	ptr = ((char **) flattenedArrayOfStrings);
	idx = 0;
	while (idx < count) {
		ptr[idx] = (flattenedArrayOfStrings + (((offsetArray[idx]) >> 1)));
		idx += 1;
	}
}


/*	Fork a child OS process, and do an exec in the child. The parent continues on in
	Smalltalk, and this method answers the pid of the child which was created. If
	useSignalHandler is true, set the signal handler for SIGCHLD. Otherwise, assume
	that death of child events are handled through some other mechanism.

	In this implementation, memory for the argument and environment arrays is allocated
	in the image prior to calling this primitive. This allows us to avoid invoking the
	garbage collector in this primitive (thereby moving the locations of environment
	and argument memory), but comes at the cost of twiddling C pointers here in the
	primitive. An alternative to this whole mess is just to malloc the environment and
	argument vectors, but I think it is a good idea to avoid malloc as much as possible
	so as not to limit future ObjectMemory implementations.

	This primitive replaces #primitiveForkAndExec from earlier versions of the plugin.
	The new name permits backward compatibility for an image running on a VM
	which does not yet have the updated plugin. This implementation uses a different
	argument format on the stack, and differs functionally in that the child now closes
	all file descriptors (including sockets) not required (that is, everything except stdin,
	stdout, and stderr on descriptors 0, 1 and 2). This eliminates some flakey behavior
	in child processes connected to Squeak by pipes, which failed to exit at expected times
	due to the old file descriptors remaining open. This is also cleaner in that garbage
	descriptors are not left hanging around the the child.

	On entry, the stack contains:
		0: workingDir, a null terminated string specifying the working directory to use, or nil.
		1: envOffsets, an array of integers for calculating environment string address offsets.
		2: envVecBuffer, a String buffer containing environment strings arranged to look like char **.
		3: argOffsets, an array of integers for calculating argument string address offsets.
		4: argVecBuffer, a String buffer containing argument strings arranged to look like char **.
		5: stdErr, a ByteArray handle.
		6: stdOut, a ByteArray handle.
		7: stdIn, a ByteArray handle.
		8: executableFile, a null terminated string with the name of the file to execute.
		9: the sender */

static int forkAndExecInDirectory(int useSignalHandler) {
    extern char **envVec;
    char *pwdPtr;
    int pid;
    int argVecBuffer;
    int *handlesToClosePtr;
    int *envOffsetPtr;
    struct itimerval saveIntervalTimer;
    int envCount;
    int idx;
    struct itimerval intervalTimer;
    int stdOut;
    char *progNamePtr;
    char **args;
    int envOffsets;
    int envVecBuffer;
    int stdErr;
    int workingDir;
    int pwd;
    char *envPtr;
    char *argsPtr;
    int *argOffsetPtr;
    int handleCount;
    int argCount;
    char **env;
    int argOffsets;
    int stdIn;
    int executableFile;
    int sigNum;

	if (useSignalHandler) {
		setSigChldHandler();
	}
	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(10);
		interpreterProxy->pushInteger(-1);
	} else {
		intervalTimer.it_interval.tv_sec = 0;
		intervalTimer.it_interval.tv_usec = 0;
		intervalTimer.it_value.tv_sec = 0;
		intervalTimer.it_value.tv_usec = 0;
		setitimer (ITIMER_REAL, &intervalTimer, &saveIntervalTimer);
		if ((pid = vfork()) == 0) {
			workingDir = interpreterProxy->stackObjectValue(0);
			envOffsets = interpreterProxy->stackObjectValue(1);
			envVecBuffer = interpreterProxy->stackObjectValue(2);
			argOffsets = interpreterProxy->stackObjectValue(3);
			argVecBuffer = interpreterProxy->stackObjectValue(4);
			stdErr = interpreterProxy->stackObjectValue(5);
			stdOut = interpreterProxy->stackObjectValue(6);
			stdIn = interpreterProxy->stackObjectValue(7);

			/* If a new working directory has been specified, try to chdir() to it. */

			executableFile = interpreterProxy->stackObjectValue(8);
			if (workingDir != (interpreterProxy->nilObject())) {
				pwdPtr = interpreterProxy->firstIndexableField(workingDir);
				if (pwdPtr == 0) {
					fprintf(stderr, "bad workingDir parameter\n");
					_exit(-1);
				} else {
					pwd = chdir(pwdPtr);
					if (pwd != 0) {
						perror("chdir");
						_exit(-1);
					}
				}
			}

			/* Dup the file handles to attach the new child process to the right streams
			on descriptors 0, 1 and 2. */

			progNamePtr = interpreterProxy->arrayValueOf(executableFile);
			if (!(stdErr == (interpreterProxy->nilObject()))) {
				dupToStdErr(stdErr);
			}
			if (!(stdOut == (interpreterProxy->nilObject()))) {
				dupToStdOut(stdOut);
			}
			if (!(stdIn == (interpreterProxy->nilObject()))) {
				dupToStdIn(stdIn);
			}

			/* First Unix file descriptor after stdin, stdout, stderr. */

			idx = 3;
			handleCount = descriptorTableSize();
			while (idx < handleCount) {
				close(idx);
				idx += 1;
			}
			if (envVecBuffer == (interpreterProxy->nilObject())) {
				env = envVec;
			} else {
				envCount = interpreterProxy->stSizeOf(envOffsets);
				envPtr = interpreterProxy->arrayValueOf(envVecBuffer);
				envOffsetPtr = interpreterProxy->firstIndexableField(envOffsets);
				fixPointersInArrayOfStringswithOffsetscount(envPtr, envOffsetPtr, envCount);
				env = ((char **) envPtr);
			}
			argCount = interpreterProxy->stSizeOf(argOffsets);
			argsPtr = interpreterProxy->arrayValueOf(argVecBuffer);
			argOffsetPtr = interpreterProxy->firstIndexableField(argOffsets);
			fixPointersInArrayOfStringswithOffsetscount(argsPtr, argOffsetPtr, argCount);

			/* Clean things up before clobbering the running image. */
			/* Note: If any file descriptors, signal handlers, or other references to external
			resources need to be cleaned up, do it here. */

			args = ((char **) argsPtr);
			/* begin restoreDefaultSignalHandlers */
			sigNum = 1;
			while (sigNum <= (signalArraySize())) {
				if ((semaIndices[sigNum]) > 0) {
					setSignalNumberhandler(sigNum, originalSigHandlers[sigNum]);
				}
				sigNum += 1;
			}
			if ((execve(progNamePtr, args, env)) == -1) {
				perror(progNamePtr);
				_exit(-1);
			} else {
				/* Can't get here from there */;
			}
		} else {
			setitimer (ITIMER_REAL, &saveIntervalTimer, 0L);
			interpreterProxy->pop(10);
			interpreterProxy->pushInteger(pid);
		}
	}
}


/*	Fork a child process, and continue running squeak in the child process. If displayFlag
	is true, open a new X display for the child, otherwise the child is a headless Squeak.
	Answer the result of the fork() call, either the child pid or zero.

	After calling fork(), two OS processes exist, one of which is the child of the other. On
	systems which implement copy-on-write memory management, and which support the
	fork() system call, both processes will be running Smalltalk images, and will be sharing
	the same memory space. In the original OS process, the resulting value of pid is the
	process id of the child process (a non-zero integer). In the child process, the value of
	pid is zero.

	The child recreates sufficient external resources to continue running. This is done by
	attaching to a new X session. The child is otherwise a copy of the parent process, and
	will continue executing the Smalltalk image at the same point as its parent. The return
	value of this primitive may be used by the two running Smalltalk images to determine
	which is the parent and which is the child.

	The child should not depend on using existing connections to external resources. For
	example, the child may lose its connections to stdin, stdout, and stderr after its parent
	exits.

	The new child image does not start itself from the image in the file system; rather it is
	a clone of the parent image as it existed at the time of primitiveForkSqueak. For this
	reason, the parent and child should agree in advance as to whom is allowed to save the
	image to the file system, otherwise one Smalltalk may overwrite the image of the other.

	This is a simple call to fork(), rather than the more common idiom of vfork() followed
	by exec(). The vfork() call cannot be used here because it is designed to be followed by
	an exec(), and its semantics require the parent process to wait for the child to exit. See
	the BSD programmers documentation for details. */

EXPORT(int) forkSqueak(int useSignalHandler) {
    int pid;
    struct itimerval saveIntervalTimer;
    struct itimerval intervalTimer;

	intervalTimer.it_interval.tv_sec = 0;
	intervalTimer.it_interval.tv_usec = 0;
	intervalTimer.it_value.tv_sec = 0;
	intervalTimer.it_value.tv_usec = 0;
	setitimer (ITIMER_REAL, &intervalTimer, &saveIntervalTimer);
	if (useSignalHandler) {
		setSigChldHandler();
	}

	/* Enable the timer again before resuming Smalltalk. */

	pid = fork();
	setitimer (ITIMER_REAL, &saveIntervalTimer, 0L);
	return pid;
}


/*	Set a signal handler in the VM which will signal a Smalltalk semaphore at
	semaphoreIndex whenever an external signal sigNum is received. Answer the
	prior value of the signal handler. If semaphoreIndex is zero, the handler is
	unregistered, and the VM returns to its default behavior for handling that
	signal. A handler must be unregistered before it can be registered again.

	The Smalltalk semaphore is expected to be kept at the same index location
	indefinitely during the lifetime of a Squeak session. If that is not the case, the
	handler must be unregistered prior to unregistering the Smalltalk semaphore. */

static void * forwardSignaltoSemaphoreAt(int sigNum, int semaphoreIndex) {
    void * oldHandler;

	if (semaphoreIndex == 0) {
		if ((semaIndices[sigNum]) > 0) {
			oldHandler = originalSigHandlers[sigNum];
			setSignalNumberhandler(sigNum, oldHandler);
			semaIndices[sigNum] = 0;
			return oldHandler;
		} else {
			return sigErrorNumber();
		}
	}
	if ((semaIndices[sigNum]) > 0) {
		return sigErrorNumber();
	}
	oldHandler = setSignalNumberhandler(sigNum, handleSignalFunctionAddress());
	if (oldHandler != (sigErrorNumber())) {
		originalSigHandlers[sigNum] = oldHandler;
		semaIndices[sigNum] = semaphoreIndex;
	}
	return oldHandler;
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static int getThisSessionIdentifier(void) {
	return null;
}

static int halt(void) {
	;
}


/*	This is a signal handler function which runs when a signal is received from the
	operating system. When the signal is received, a Smalltalk Semaphore is signaled.
	This effectively passes the external signal to Squeak to allow it to be handled in
	Smalltalk.

	Note the this handler runs the VM in the context of a Unix signal handler in order
	to signal the Smalltalk Semaphore. In a single threaded Squeak VM, this works fine,
	however it may not work as expected if pthreads are used for the VM or for any
	plugins linked internally with the VM. On GCC systems, compiling with -D_REENTRANT
	seems to produce the intended behavior. */

static void handleSignal(int sigNum) {
    int semaIndex;

	semaIndex = semaIndices[sigNum];
	forwardSignaltoSemaphoreAt(sigNum, semaIndex);
	if (semaIndex > 0) {
		interpreterProxy->signalSemaphoreWithIndex(semaIndex);
	}
}

static void * handleSignalFunctionAddress(void) {
	return handleSignal;
}

EXPORT(int) initialiseModule(void) {
	osprocessSandboxSecurity = -1;
}


/*	Answer true if objectPointer appears to be a valid SQFile ByteArray. This check
	is appropriate if objectPointer has been passed as a parameter to a primitive, and
	is expected to represent a valid file reference. */

static int isSQFileObject(int objectPointer) {
    unsigned char *sqFileBytes;
    int idx;

	if (!((interpreterProxy->isBytes(objectPointer)) && ((interpreterProxy->byteSizeOf(objectPointer)) == (fileRecordSize())))) {
		return 0;
	}
	sqFileBytes = interpreterProxy->arrayValueOf(objectPointer);
	idx = 0;
	while (idx < (fileRecordSize())) {
		if ((sqFileBytes[idx]) != 0) {
			return 1;
		}
		idx += 1;
	}
	return 0;
}


/*	Create a pipe and populate the readerIOStream and writerIOStream variables.
	Make sure the SIGPIPE handler is set before creating the pipe. Answer true for
	success, else false */

static int makePipeForReaderwriter(FILEHANDLETYPE * readerIOStreamPtr, FILEHANDLETYPE * writerIOStreamPtr) {
    int filedes[2];

	/* begin setSigPipeHandler */
	/* begin setSigPipeIgnore */
	setSignalNumberhandler(sigPipeNumber(), sigIgnoreNumber());
	if ((pipe(filedes)) == -1) {
		return 0;
	} else {
		*writerIOStreamPtr= (FILE *) fdopen (filedes[1], "a");
		*readerIOStreamPtr= (FILE *) fdopen (filedes[0], "r");
		return 1;
	}
}


/*	Using malloc() and calloc() is something I would like to avoid, since it is
	likely to cause problems some time in the future if somebody redesigns
	object memory allocation. This wrapper just makes it easy to find senders
	of calloc() in my code. -dtl */

static void * mallocWrapper(int size) {
	return malloc(size);
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Answer a new ByteArray sized to contain a SQFile data structure. */

static int newSQFileByteArray(void) {
	return interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
}


/*	Answer a new ByteArray sized to contain a SQSocket data structure. */

static int newSQSocketByteArray(void) {
	return interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), socketRecordSize());
}


/*	An array of signal handler function addresses, one for each signal type. The
	value at each entry is the address of the original signal handler function prior
	to having set a handler. */

static void ** originalSignalHandlers(void) {
	return originalSigHandlers;
}


/*	Answer the pointer represented by aByteArray. */

static void * pointerFrom(int aByteArray) {
    unsigned char *ptr;
    int idx;
    union {void *address; unsigned char bytes[sizeof(void *)];} pointerUnion;

	if (!((interpreterProxy->isBytes(aByteArray)) && ((interpreterProxy->stSizeOf(aByteArray)) == (sizeOfPointer())))) {
		return null;
	}
	ptr = interpreterProxy->arrayValueOf(aByteArray);
	idx = 0;
	while (idx < (sizeOfPointer())) {
		pointerUnion.bytes[idx] = ptr[idx];
		idx += 1;
	}
	return pointerUnion.address;
}


/*	This primitive call exists only for purposes of testing the
	fixPointersInArrayOfStrings:withOffsets:count: method. I believe it to be
	reasonably machine and compiler independent, but have no way of verifying
	this on a variety of machines, so I'll leave this test method here in case
	someone runs into problems on other hardware or compilers. -dtl */
/*	| a |
	a _ OSProcess thisOSProcess envAsFlatArrayAndOffsets: UnixProcess env.
	UnixOSProcessPlugin new
		primFixPointersInArrayOfStrings: (a at: 1)
		withOffsets: (a at: 2)
		count: (a at: 2) size */

static int primFixPointersInArrayOfStringswithOffsetscount(int cStringArray, int offsetArray, int count) {
	return null;
}


/*	Definitively disable asynchronous event notification for a descriptor. The
	parameter is a sqFile ByteArray representing the ioHandle for a file. */

EXPORT(int) primitiveAioDisable(void) {
    int sqFile;
    int fd;

	sqFile = interpreterProxy->stackObjectValue(0);
	fd = fileDescriptorFrom(sqFile);
	if (fd < 0) {
		return interpreterProxy->primitiveFail();
	}
	aioDisable(fd);
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(fd);
}


/*	Enable asynchronous notification for a descriptor. The first parameter is a sqFile
	ByteArray representing the ioHandle for a file, the second parameter is the index
	of a Semaphore to be notified, and the third parameter is a flag indicating that
	sqFile represents an external object and should not be closed on termination of
	aio handling. Answer the semaphore index. */

EXPORT(int) primitiveAioEnable(void) {
    int sqFile;
    int semaIndex;
    int externalObject;
    int fd;
    int flags;
    static int eventSemaphoreIndices[FD_SETSIZE];

	sqFile = interpreterProxy->stackObjectValue(2);
	if (!((interpreterProxy->isBytes(sqFile)) && ((interpreterProxy->stSizeOf(sqFile)) == (fileRecordSize())))) {
		return interpreterProxy->primitiveFail();
	}
	fd = fileDescriptorFrom(sqFile);
	if (fd < 0) {
		return interpreterProxy->primitiveFail();
	}
	semaIndex = interpreterProxy->stackIntegerValue(1);
	eventSemaphoreIndices[semaIndex] = semaIndex;
	externalObject = interpreterProxy->stackObjectValue(0);
	if (externalObject == (interpreterProxy->trueObject())) {
		flags = AIO_EXT;
	} else {
		flags = 0;
	}
	aioEnable(fd, &(eventSemaphoreIndices[semaIndex]), flags);
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(semaIndex);
}


/*	Handle asynchronous event notification for a descriptor. The first parameter is
	a sqFile ByteArray representing the ioHandle for a file, and the remaining three
	parameters are Boolean flags representing the types of events for which notification
	is being requested: handle exceptions, handle for read, and handle for write.
	Flags are defined in the aio.h source as:
		AIO_X	(1<<0)	handle for exceptions
		AIO_R	(1<<1)	handle for read
		AIO_W	(1<<2)	handle for write */

EXPORT(int) primitiveAioHandle(void) {
    int exceptionWatch;
    int readWatch;
    int sqFile;
    int fd;
    int flags;
    int writeWatch;

	sqFile = interpreterProxy->stackObjectValue(3);
	if (!((interpreterProxy->isBytes(sqFile)) && ((interpreterProxy->stSizeOf(sqFile)) == (fileRecordSize())))) {
		return interpreterProxy->primitiveFail();
	}
	fd = fileDescriptorFrom(sqFile);
	if (fd < 0) {
		return interpreterProxy->primitiveFail();
	}
	exceptionWatch = interpreterProxy->stackObjectValue(2);
	readWatch = interpreterProxy->stackObjectValue(1);
	writeWatch = interpreterProxy->stackObjectValue(0);
	flags = 0;
	if (exceptionWatch == (interpreterProxy->trueObject())) {
		flags = flags | (AIO_X);
	}
	if (readWatch == (interpreterProxy->trueObject())) {
		flags = flags | (AIO_R);
	}
	if (writeWatch == (interpreterProxy->trueObject())) {
		flags = flags | (AIO_W);
	}
	aioHandle(fd, aioForwardwithDataandFlags, flags);
	interpreterProxy->pop(5);
	interpreterProxy->pushInteger(flags);
}


/*	Temporarily suspend asynchronous event notification for a descriptor. The first
	parameter is a sqFile ByteArray representing the ioHandle for a file, and the
	remaining three parameters are Boolean flags representing the types of events
	for which notification is being requested: handle exceptions, handle for read,
	and handle for write.
	Flags are defined in the aio.h source as:
		AIO_X	(1<<0)	handle for exceptions
		AIO_R	(1<<1)	handle for read
		AIO_W	(1<<2)	handle for write */

EXPORT(int) primitiveAioSuspend(void) {
    int exceptionWatch;
    int readWatch;
    int sqFile;
    int fd;
    int flags;
    int writeWatch;

	sqFile = interpreterProxy->stackObjectValue(3);
	if (!((interpreterProxy->isBytes(sqFile)) && ((interpreterProxy->stSizeOf(sqFile)) == (fileRecordSize())))) {
		return interpreterProxy->primitiveFail();
	}
	fd = fileDescriptorFrom(sqFile);
	if (fd < 0) {
		return interpreterProxy->primitiveFail();
	}
	exceptionWatch = interpreterProxy->stackObjectValue(2);
	readWatch = interpreterProxy->stackObjectValue(1);
	writeWatch = interpreterProxy->stackObjectValue(0);
	flags = 0;
	if (exceptionWatch == (interpreterProxy->trueObject())) {
		flags = flags | (AIO_X);
	}
	if (readWatch == (interpreterProxy->trueObject())) {
		flags = flags | (AIO_R);
	}
	if (writeWatch == (interpreterProxy->trueObject())) {
		flags = flags | (AIO_W);
	}
	aioSuspend(fd, flags);
	interpreterProxy->pop(5);
	interpreterProxy->pushInteger(flags);
}


/*	Answer a string containing the OS process argument at index (an Integer) in the
	argument list. */

EXPORT(int) primitiveArgumentAt(void) {
    extern char **argVec;
    int s;
    int index;
    char *sPtr;
    extern int argCnt;

	index = interpreterProxy->stackIntegerValue(0);
	if ((index > argCnt) || (index < 1)) {
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->nilObject());
	} else {
		sPtr = argVec[index - 1];
		s = stringFromCString(sPtr);
		interpreterProxy->pop(2);
		interpreterProxy->push(s);
	}
}


/*	Send a null signal to the OS process identified by anIntegerPid. Answer false for
	a bad parameter on the stack (the common case is for anIntegerPid equal to nil,
	for which case we should answer false). Answer true if the process exists and can
	receive signals from this process, otherwise false. This test is useful for determining
	if a child process still exists following a Squeak image restart. */

EXPORT(int) primitiveCanReceiveSignals(int anIntegerPid) {
    int pidToSignal;
    int result;

	if (((interpreterProxy->stackValue(0)) & 1)) {
		pidToSignal = interpreterProxy->stackIntegerValue(0);
		result = kill(pidToSignal, 0);
		interpreterProxy->pop(2);
		if (result == 0) {
			interpreterProxy->push(interpreterProxy->trueObject());
		} else {
			interpreterProxy->push(interpreterProxy->falseObject());
		}
	} else {
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->falseObject());
	}
}


/*	Call chdir(2) to change current working directory to the specified path string. Answer
	nil for success, or errno on failure. */

EXPORT(int) primitiveChdir(void) {
    extern int errno;
    char *path;

	path = transientCStringFromString(interpreterProxy->stackObjectValue(0));
	if ((chdir(path)) == 0) {
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->nilObject());
	} else {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(errno);
	}
}


/*	Create a pipe, and answer an array of two file handles for the pipe writer and reader.
	The readerIOStream and writerIOStream variables represent the low level pipe streams,
	which will be of type (FILE *) or HANDLE, depending on what the FilePlugin support
	code is using to represent file streams. FILEHANDLETYPE is defined in my subclasses
	in the #declareCVarsIn: class method. */

EXPORT(int) primitiveCreatePipe(void) {
    int thisSession;
    int writer;
    FILEHANDLETYPE writerIOStream;
    SQFile * writerPtr;
    FILEHANDLETYPE *writerIOStreamPtr;
    SQFile * readerPtr;
    int arrayResult;
    int reader;
    FILEHANDLETYPE readerIOStream;
    FILEHANDLETYPE *readerIOStreamPtr;


	/* Create the anonymous OS pipe */

	thisSession = null;
	readerIOStreamPtr = &readerIOStream;
	writerIOStreamPtr = &writerIOStream;
	if (!(createPipeForReaderwriter(readerIOStreamPtr, writerIOStreamPtr))) {
		return interpreterProxy->primitiveFail();
	}
	writer = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(writer)) && ((interpreterProxy->byteSizeOf(writer)) == (fileRecordSize()))) {
		writerPtr = interpreterProxy->arrayValueOf(writer);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		writerPtr = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	writerPtr->file = writerIOStream;
	writerPtr->sessionID = thisSession;
	writerPtr->writable = 1;
	writerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(writer);
	reader = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(reader)) && ((interpreterProxy->byteSizeOf(reader)) == (fileRecordSize()))) {
		readerPtr = interpreterProxy->arrayValueOf(reader);
		goto l2;
	} else {
		interpreterProxy->primitiveFail();
		readerPtr = null;
		goto l2;
	}
l2:	/* end fileValueOf: */;
	readerPtr->file = readerIOStream;
	readerPtr->sessionID = thisSession;
	readerPtr->writable = 0;
	readerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(reader);
	arrayResult = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	interpreterProxy->stObjectatput(arrayResult, 1, interpreterProxy->popRemappableOop());
	interpreterProxy->stObjectatput(arrayResult, 2, interpreterProxy->popRemappableOop());
	interpreterProxy->pop(1);
	interpreterProxy->push(arrayResult);
}


/*	Create a pipe, and answer an array of two file handles for the pipe writer and reader.
	The session identifier is passed as the parameter to this primitive. Use this variant
	if the session identifier is not available directly in the VM (as may be the case if
	it is not possible to link from this plugin to a variable elsewhere in the VM).
	The readerIOStream and writerIOStream variables represent the low level pipe streams,
	which will be of type (FILE *) or HANDLE, depending on what the FilePlugin support
	code is using to represent file streams. FILEHANDLETYPE is defined in my subclasses
	in the #declareCVarsIn: class method. */

EXPORT(int) primitiveCreatePipeWithSessionIdentifier(void) {
    int thisSession;
    int writer;
    FILEHANDLETYPE writerIOStream;
    SQFile * writerPtr;
    FILEHANDLETYPE *writerIOStreamPtr;
    SQFile * readerPtr;
    int arrayResult;
    int reader;
    FILEHANDLETYPE readerIOStream;
    FILEHANDLETYPE *readerIOStreamPtr;


	/* Create the anonymous OS pipe */

	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	readerIOStreamPtr = &readerIOStream;
	writerIOStreamPtr = &writerIOStream;
	if (!(createPipeForReaderwriter(readerIOStreamPtr, writerIOStreamPtr))) {
		return interpreterProxy->primitiveFail();
	}
	writer = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(writer)) && ((interpreterProxy->byteSizeOf(writer)) == (fileRecordSize()))) {
		writerPtr = interpreterProxy->arrayValueOf(writer);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		writerPtr = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	writerPtr->file = writerIOStream;
	writerPtr->sessionID = thisSession;
	writerPtr->writable = 1;
	writerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(writer);
	reader = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(reader)) && ((interpreterProxy->byteSizeOf(reader)) == (fileRecordSize()))) {
		readerPtr = interpreterProxy->arrayValueOf(reader);
		goto l2;
	} else {
		interpreterProxy->primitiveFail();
		readerPtr = null;
		goto l2;
	}
l2:	/* end fileValueOf: */;
	readerPtr->file = readerIOStream;
	readerPtr->sessionID = thisSession;
	readerPtr->writable = 0;
	readerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(reader);
	arrayResult = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	interpreterProxy->stObjectatput(arrayResult, 1, interpreterProxy->popRemappableOop());
	interpreterProxy->stObjectatput(arrayResult, 2, interpreterProxy->popRemappableOop());
	interpreterProxy->pop(2);
	interpreterProxy->push(arrayResult);
}


/*	Answer a string containing the OS process environment string at index (an Integer)
	in the environment list. */

EXPORT(int) primitiveEnvironmentAt(void) {
    extern char **envVec;
    char **p;
    int envCnt;
    int s;
    int index;
    char *sPtr;

	p = envVec;
	envCnt = 0;
	while (*p++) envCnt++;
	index = interpreterProxy->stackIntegerValue(0);
	if ((index > envCnt) || (index < 1)) {
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->nilObject());
	} else {
		sPtr = envVec[index - 1];
		s = stringFromCString(sPtr);
		interpreterProxy->pop(2);
		interpreterProxy->push(s);
	}
}


/*	Answer the value of an environment variable keyed by a Symbol. */

EXPORT(int) primitiveEnvironmentAtSymbol(void) {
    char * getenvResult;
    char *keyCStringPtr;
    int s;

	keyCStringPtr = transientCStringFromString(interpreterProxy->stackObjectValue(0));
	getenvResult = getenv(keyCStringPtr);
	if (getenvResult == 0) {
		return interpreterProxy->primitiveFail();
	} else {
		s = stringFromCString(getenvResult);
		interpreterProxy->pop(2);
		interpreterProxy->push(s);
	}
}


/*	Answer a string describing an error message */

EXPORT(int) primitiveErrorMessageAt(void) {
    char *p;
    int errMessage;
    int index;

	index = interpreterProxy->stackIntegerValue(0);
	p = ((char *) (strerror(index)));
	errMessage = stringFromCString(p);
	interpreterProxy->pop(2);
	interpreterProxy->push(errMessage);
}


/*	Call stat(2) to obtain the file protection mask for a file. Answer an Array of
	four integers representing the protection mask, or answer errno on failure. The
	protection mask is four Integers, each of which may be considered an octal digit
	(0-7), with bit values 4, 2, and 1. The first digit selects the set user ID (4) and set
	group ID (2) and save text image (1) attributes. The second digit selects permissions
	for the user who owns the file: read (4), write (2), and execute (1); the third
	selects permissions for other users in the file's group, with the same values; and
	the fourth for other users not in the file's group, with the same values. */

EXPORT(int) primitiveFileProtectionMask(void) {
    extern int errno;
    char *path;
    struct stat *statBuf;
    int mode;
    int result;
    int buffer;

	buffer = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeof(struct stat));
	statBuf = interpreterProxy->arrayValueOf(buffer);
	path = transientCStringFromString(interpreterProxy->stackObjectValue(0));
	mode = stat(path, statBuf);
	if (mode == 0) {
		mode = statBuf->st_mode;
		result = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 4);
		interpreterProxy->stObjectatput(result, 4, (((mode & 07) << 1) | 1));
		interpreterProxy->stObjectatput(result, 3, ((((mode & 070) >> 3) << 1) | 1));
		interpreterProxy->stObjectatput(result, 2, ((((mode & 0700) >> 6) << 1) | 1));
		interpreterProxy->stObjectatput(result, 1, ((((mode & 07000) >> 9) << 1) | 1));
		interpreterProxy->pop(2);
		interpreterProxy->push(result);
	} else {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(errno);
	}
}


/*	Call stat(2) to obtain the file protection mask for a file. Answer errno on failure,
	or on success answer an array with: UID with: GID with: protectionMask. The	
	protectionMask is an Array of four integers representing the protection mask, or
	answer errno on failure. The protection mask is four Integers, each of which may
	be considered an octal digit (0-7), with bit values 4, 2, and 1. The first digit selects
	the set user ID (4) and set group ID (2) and save text image (1) attributes. The second
	digit selects permissions for the user who owns the file: read (4), write (2), and
	execute (1); the third selects permissions for other users in the file's group, with
	the same values; and the fourth for other users not in the file's group, with the
	same values. */

EXPORT(int) primitiveFileStat(void) {
    int uid;
    int gid;
    extern int errno;
    char *path;
    struct stat *statBuf;
    int mode;
    int result;
    int mask;
    int buffer;

	result = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 3);
	uid = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeof(uid_t));
	gid = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeof(gid_t));
	mask = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 4);
	buffer = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeof(struct stat));
	statBuf = interpreterProxy->arrayValueOf(buffer);
	path = transientCStringFromString(interpreterProxy->stackObjectValue(0));
	mode = stat(path, statBuf);
	if (mode == 0) {
		mode = statBuf->st_mode;
		interpreterProxy->stObjectatput(mask, 4, (((mode & 07) << 1) | 1));
		interpreterProxy->stObjectatput(mask, 3, ((((mode & 070) >> 3) << 1) | 1));
		interpreterProxy->stObjectatput(mask, 2, ((((mode & 0700) >> 6) << 1) | 1));
		interpreterProxy->stObjectatput(mask, 1, ((((mode & 07000) >> 9) << 1) | 1));
		interpreterProxy->stObjectatput(result, 3, mask);
		interpreterProxy->stObjectatput(result, 2, (((statBuf->st_gid) << 1) | 1));
		interpreterProxy->stObjectatput(result, 1, (((statBuf->st_uid) << 1) | 1));
		interpreterProxy->pop(2);
		interpreterProxy->push(result);
	} else {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(errno);
	}
}


/*	This primitive exists only for purposes of testing the
	fixPointersInArrayOfStrings:withOffsets:count: method. I believe it to be
	reasonably machine and compiler independent, but have no way of verifying
	this on a variety of machines, so I'll leave this test method here in case
	someone runs into problems on other hardware or compilers. -dtl */

EXPORT(int) primitiveFixPointersInArrayOfStrings(void) {
    int offsetArray;
    int count;
    int cStringArray;
    char *flattenedArrayOfStrings;
    int *offsets;

	count = interpreterProxy->stackIntegerValue(0);
	offsetArray = interpreterProxy->stackObjectValue(1);
	cStringArray = interpreterProxy->stackObjectValue(2);
	offsets = interpreterProxy->firstIndexableField(offsetArray);
	flattenedArrayOfStrings = interpreterProxy->arrayValueOf(cStringArray);
	fixPointersInArrayOfStringswithOffsetscount(flattenedArrayOfStrings, offsets, count);
	interpreterProxy->pop(4);
	interpreterProxy->push(cStringArray);
}


/*	Fork a child OS process, and do an exec in the child. The parent continues on in
	Smalltalk, and this method answers the pid of the child which was created.

	On entry, the stack contains:
		0: workingDir, a null terminated string specifying the working directory to use, or nil.
		1: envOffsets, an array of integers for calculating environment string address offsets.
		2: envVecBuffer, a String buffer containing environment strings arranged to look like char **.
		3: argOffsets, an array of integers for calculating argument string address offsets.
		4: argVecBuffer, a String buffer containing argument strings arranged to look like char **.
		5: stdErr, a ByteArray handle.
		6: stdOut, a ByteArray handle.
		7: stdIn, a ByteArray handle.
		8: executableFile, a null terminated string with the name of the file to execute.
		9: the sender */

EXPORT(int) primitiveForkAndExecInDirectory(void) {
	return forkAndExecInDirectory(1);
}


/*	Fork a child OS process, and do an exec in the child. The parent continues on in
	Smalltalk, and this method answers the pid of the child which was created.

	On entry, the stack contains:
		0: workingDir, a null terminated string specifying the working directory to use, or nil.
		1: envOffsets, an array of integers for calculating environment string address offsets.
		2: envVecBuffer, a String buffer containing environment strings arranged to look like char **.
		3: argOffsets, an array of integers for calculating argument string address offsets.
		4: argVecBuffer, a String buffer containing argument strings arranged to look like char **.
		5: stdErr, a ByteArray handle.
		6: stdOut, a ByteArray handle.
		7: stdIn, a ByteArray handle.
		8: executableFile, a null terminated string with the name of the file to execute.
		9: the sender */

EXPORT(int) primitiveForkExec(void) {
	return forkAndExecInDirectory(0);
}


/*	Fork a child process, and continue running squeak in the child process. Leave the
	X session connected to the parent process, but close its file descriptor for the child
	process. Open a new X session for the child.

	The child should not depend on using existing connections to external resources. For
	example, the child may lose its connections to stdin, stdout, and stderr after its parent
	exits. */

EXPORT(int) primitiveForkSqueak(void) {
    int pid;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(1);
		interpreterProxy->pushInteger(-1);
	} else {
		pid = forkSqueak(1);
		interpreterProxy->pop(1);
		interpreterProxy->pushInteger(pid);
	}
}


/*	Fork a child process, and continue running squeak in the child process. Leave the
	X session connected to the parent process, but close its file descriptor for the child
	process. Open a new X session for the child.

	The child should not depend on using existing connections to external resources. For
	example, the child may lose its connections to stdin, stdout, and stderr after its parent
	exits. */

EXPORT(int) primitiveForkSqueakWithoutSigHandler(void) {
    int pid;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(1);
		interpreterProxy->pushInteger(-1);
	} else {
		pid = forkSqueak(0);
		interpreterProxy->pop(1);
		interpreterProxy->pushInteger(pid);
	}
}


/*	Set a signal handler in the VM which will signal a Smalltalk semaphore at
	semaphoreIndex whenever an external signal sigNum is received. Answer the
	prior value of the signal handler. If semaphoreIndex is zero or nil, the handler
	is unregistered, and the VM returns to its default behavior for handling that
	signal.

	The Smalltalk semaphore is expected to be kept at the same index location
	indefinitely during the lifetime of a Squeak session. If that is not the case, the
	handler must be unregistered prior to unregistering the Smalltalk semaphore. */

EXPORT(int) primitiveForwardSignalToSemaphore(void) {
    int sigNum;
    void *handler;
    int semaphoreIndex;
    char *hPtr;
    int idx;
    int index;
    union {void *handler; unsigned char bytes[sizeof(void *)];} priorHandler;
    int priorHandlerObject;

	index = interpreterProxy->stackValue(0);
	if (index == (interpreterProxy->nilObject())) {
		semaphoreIndex = 0;
	} else {
		if ((index & 1)) {
			semaphoreIndex = interpreterProxy->stackIntegerValue(0);
		} else {
			return interpreterProxy->primitiveFail();
		}
	}
	sigNum = interpreterProxy->stackIntegerValue(1);
	handler = forwardSignaltoSemaphoreAt(sigNum, semaphoreIndex);
	if (handler == (sigErrorNumber())) {
		return interpreterProxy->primitiveFail();
	}
	priorHandlerObject = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeOfPointer());
	hPtr = interpreterProxy->arrayValueOf(priorHandlerObject);
	priorHandler.handler = handler;
	idx = 0;
	while (idx < (sizeOfPointer())) {
		hPtr[idx] = priorHandler.bytes[idx];
		idx += 1;
	}
	interpreterProxy->popthenPush(3, priorHandlerObject);
}


/*	Answer a string containing the current working directory. */

EXPORT(int) primitiveGetCurrentWorkingDirectory(void) {
    int maxSize;
    int cwdString;
    int incrementBy;
    char *cwd;
    int bufferSize;
    char *buffer;

	bufferSize = 100;
	incrementBy = 100;
	maxSize = 5000;
	while (1) {
		cwdString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), bufferSize);
		buffer = interpreterProxy->arrayValueOf(cwdString);
		cwd = getcwd(buffer, bufferSize);
		if (!((cwd == 0) && (bufferSize < maxSize))) break;
		bufferSize += incrementBy;
	}
	if (cwd == 0) {
		return interpreterProxy->primitiveFail();
	} else {
		cwdString = stringFromCString(cwd);
		interpreterProxy->pop(1);
		interpreterProxy->push(cwdString);
	}
}


/*	Answer the effective group ID of my OS process */

EXPORT(int) primitiveGetEGid(void) {
    int eGid;

	eGid = getegid();
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(eGid);
}


/*	Answer the effective user ID of my OS process */

EXPORT(int) primitiveGetEUid(void) {
    int eUid;

	eUid = geteuid();
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(eUid);
}


/*	Answer the group ID of my OS process */

EXPORT(int) primitiveGetGid(void) {
    int gid;

	gid = getgid();
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(gid);
}


/*	Answer the process ID of the parent process of my OS process */

EXPORT(int) primitiveGetPPid(void) {
    int ppid;

	ppid = getppid();
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(ppid);
}


/*	Answer the process ID of my OS process */

EXPORT(int) primitiveGetPid(void) {
    int pid;

	pid = getpid();
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(pid);
}


/*	Answer the unique session identifier for this Smalltalk instance running in this
	OS process. The C integer value is coerced into a Smalltalk ByteArray to preserve
	the full range of possible values. */

EXPORT(int) primitiveGetSession(void) {
    int sessionOop;
    unsigned char *sessionByteArrayPointer;
    int thisSessionID;

	sessionOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeOfInt());
	sessionByteArrayPointer = interpreterProxy->arrayValueOf(sessionOop);
	thisSessionID = null;
	if (thisSessionID == null) {
		return interpreterProxy->primitiveFail();
	}
	copyBytesFromtolength((unsigned char *)&thisSessionID, sessionByteArrayPointer, sizeOfInt());
	interpreterProxy->pop(1);
	interpreterProxy->push(sessionOop);
}


/*	Answer the file handle for standard error of my OS process */

EXPORT(int) primitiveGetStdErrHandle(void) {
    int thisSession;
    SQFile * file;
    int fileOop;

	fileOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(fileOop)) && ((interpreterProxy->byteSizeOf(fileOop)) == (fileRecordSize()))) {
		file = interpreterProxy->arrayValueOf(fileOop);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	thisSession = null;
	file->file = stderr;
	file->sessionID = thisSession;
	file->writable = 1;
	file->lastOp = 0;
	interpreterProxy->pop(1);
	interpreterProxy->push(fileOop);
}


/*	Answer the file handle for standard error of my OS process. The session
	identifier is passed as the parameter to this primitive. Use this variant if
	the session identifier is not available directly in the VM (as may be the
	case if it is not possible to link from this plugin to a variable elsewhere
	in the VM). */

EXPORT(int) primitiveGetStdErrHandleWithSessionIdentifier(void) {
    int thisSession;
    SQFile * file;
    int fileOop;

	fileOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(fileOop)) && ((interpreterProxy->byteSizeOf(fileOop)) == (fileRecordSize()))) {
		file = interpreterProxy->arrayValueOf(fileOop);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	file->file = stderr;
	file->sessionID = thisSession;
	file->writable = 1;
	file->lastOp = 0;
	interpreterProxy->pop(2);
	interpreterProxy->push(fileOop);
}


/*	Answer the file handle for standard input of my OS process */

EXPORT(int) primitiveGetStdInHandle(void) {
    int thisSession;
    SQFile * file;
    int fileOop;

	fileOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(fileOop)) && ((interpreterProxy->byteSizeOf(fileOop)) == (fileRecordSize()))) {
		file = interpreterProxy->arrayValueOf(fileOop);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	thisSession = null;
	file->file = stdin;
	file->sessionID = thisSession;
	file->writable = 0;
	file->lastOp = 0;
	interpreterProxy->pop(1);
	interpreterProxy->push(fileOop);
}


/*	Answer the file handle for standard input of my OS process. The session
	identifier is passed as the parameter to this primitive. Use this variant if
	the session identifier is not available directly in the VM (as may be the
	case if it is not possible to link from this plugin to a variable elsewhere
	in the VM). */

EXPORT(int) primitiveGetStdInHandleWithSessionIdentifier(void) {
    int thisSession;
    SQFile * file;
    int fileOop;

	fileOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(fileOop)) && ((interpreterProxy->byteSizeOf(fileOop)) == (fileRecordSize()))) {
		file = interpreterProxy->arrayValueOf(fileOop);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	file->file = stdin;
	file->sessionID = thisSession;
	file->writable = 0;
	file->lastOp = 0;
	interpreterProxy->pop(2);
	interpreterProxy->push(fileOop);
}


/*	Answer the file handle for standard output of my OS process */

EXPORT(int) primitiveGetStdOutHandle(void) {
    int thisSession;
    SQFile * file;
    int fileOop;

	fileOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(fileOop)) && ((interpreterProxy->byteSizeOf(fileOop)) == (fileRecordSize()))) {
		file = interpreterProxy->arrayValueOf(fileOop);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	thisSession = null;
	file->file = stdout;
	file->sessionID = thisSession;
	file->writable = 1;
	file->lastOp = 0;
	interpreterProxy->pop(1);
	interpreterProxy->push(fileOop);
}


/*	Answer the file handle for standard output of my OS process. The session
	identifier is passed as the parameter to this primitive. Use this variant if
	the session identifier is not available directly in the VM (as may be the
	case if it is not possible to link from this plugin to a variable elsewhere
	in the VM). */

EXPORT(int) primitiveGetStdOutHandleWithSessionIdentifier(void) {
    int thisSession;
    SQFile * file;
    int fileOop;

	fileOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(fileOop)) && ((interpreterProxy->byteSizeOf(fileOop)) == (fileRecordSize()))) {
		file = interpreterProxy->arrayValueOf(fileOop);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		file = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	file->file = stdout;
	file->sessionID = thisSession;
	file->writable = 1;
	file->lastOp = 0;
	interpreterProxy->pop(2);
	interpreterProxy->push(fileOop);
}


/*	Answer the user ID of my OS process */

EXPORT(int) primitiveGetUid(void) {
    int uid;

	uid = getuid();
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(uid);
}


/*	Take a struct SQFile from the stack, and call feof(3) to determine if the file has
	reached end of file. */

EXPORT(int) primitiveIsAtEndOfFile(void) {
    SQFile *sqFile;
    int result;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(0);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}
	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	if ((feof(sqFile->file)) == 0) {
		result = interpreterProxy->falseObject();
	} else {
		result = interpreterProxy->trueObject();
	}
	interpreterProxy->pop(2);
	interpreterProxy->push(result);
}


/*	Take a struct SQFile from the stack, and request a lock on the specified region.
	If the exclusive flag is true, then request an exclusive (F_WRLCK) lock on the
     file. Otherwise, request a shared (F_RDLCK) lock. Any number of Unix processes
     may hold  a read lock (shared lock) on a file region, but only one process may
     hold a write lock (exclusive lock). Answer the result of the call to fcntl().

	If length is zero, then the entire file will be locked, including region extents that
	have not yet been allocated for the file. */

EXPORT(int) primitiveLockFileRegion(void) {
    int sqFileOop;
    int thisSession;
    int exclusive;
    int start;
    SQFile *sqFile;
    int result;
    int len;
    int fileNo;
    struct flock lockStruct;

	exclusive = (interpreterProxy->stackValue(0)) == (interpreterProxy->trueObject());
	len = interpreterProxy->stackIntegerValue(1);
	start = interpreterProxy->stackIntegerValue(2);
	sqFileOop = interpreterProxy->stackValue(3);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}

	/* If the session identifier can be obtained, use it as an additional consistency check */

	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = null;
	if (thisSession == null) {
		null;
	} else {
		if (!(sqFile->sessionID)) {
			return interpreterProxy->primitiveFail();
		}
	}

	/* Set up the flock structure parameter for fcntl() */

	fileNo = fileno(sqFile->file);
	if (exclusive) {
		lockStruct.l_type = F_WRLCK;
	} else {
		lockStruct.l_type = F_RDLCK;
	}
	lockStruct.l_whence = SEEK_SET;
	lockStruct.l_start = start;
	lockStruct.l_len = len;
	lockStruct.l_pid = 0;
	result = fcntl(fileNo, F_SETLK, &lockStruct);
	interpreterProxy->pop(5);
	interpreterProxy->pushInteger(result);
}


/*	Create a pipe, and answer an array of two file handles for the pipe writer and reader.
	The readerIOStream and writerIOStream variables represent the low level pipe streams,
	which will be of type (FILE *) or HANDLE, depending on what the FilePlugin support
	code is using to represent file streams. FILEHANDLETYPE is defined in my subclasses
	in the #declareCVarsIn: class method. */

EXPORT(int) primitiveMakePipe(void) {
    int thisSession;
    int writer;
    FILEHANDLETYPE writerIOStream;
    SQFile * writerPtr;
    FILEHANDLETYPE *writerIOStreamPtr;
    SQFile * readerPtr;
    int arrayResult;
    int reader;
    FILEHANDLETYPE readerIOStream;
    FILEHANDLETYPE *readerIOStreamPtr;


	/* Create the anonymous OS pipe */

	thisSession = null;
	readerIOStreamPtr = &readerIOStream;
	writerIOStreamPtr = &writerIOStream;
	if (!(makePipeForReaderwriter(readerIOStreamPtr, writerIOStreamPtr))) {
		return interpreterProxy->primitiveFail();
	}
	writer = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(writer)) && ((interpreterProxy->byteSizeOf(writer)) == (fileRecordSize()))) {
		writerPtr = interpreterProxy->arrayValueOf(writer);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		writerPtr = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	writerPtr->file = writerIOStream;
	writerPtr->sessionID = thisSession;
	writerPtr->writable = 1;
	writerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(writer);
	reader = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(reader)) && ((interpreterProxy->byteSizeOf(reader)) == (fileRecordSize()))) {
		readerPtr = interpreterProxy->arrayValueOf(reader);
		goto l2;
	} else {
		interpreterProxy->primitiveFail();
		readerPtr = null;
		goto l2;
	}
l2:	/* end fileValueOf: */;
	readerPtr->file = readerIOStream;
	readerPtr->sessionID = thisSession;
	readerPtr->writable = 0;
	readerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(reader);
	arrayResult = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	interpreterProxy->stObjectatput(arrayResult, 1, interpreterProxy->popRemappableOop());
	interpreterProxy->stObjectatput(arrayResult, 2, interpreterProxy->popRemappableOop());
	interpreterProxy->pop(1);
	interpreterProxy->push(arrayResult);
}


/*	Create a pipe, and answer an array of two file handles for the pipe writer and reader.
	The session identifier is passed as the parameter to this primitive. Use this variant
	if the session identifier is not available directly in the VM (as may be the case if
	it is not possible to link from this plugin to a variable elsewhere in the VM).
	The readerIOStream and writerIOStream variables represent the low level pipe streams,
	which will be of type (FILE *) or HANDLE, depending on what the FilePlugin support
	code is using to represent file streams. FILEHANDLETYPE is defined in my subclasses
	in the #declareCVarsIn: class method. */

EXPORT(int) primitiveMakePipeWithSessionIdentifier(void) {
    int thisSession;
    int writer;
    FILEHANDLETYPE writerIOStream;
    SQFile * writerPtr;
    FILEHANDLETYPE *writerIOStreamPtr;
    SQFile * readerPtr;
    int arrayResult;
    int reader;
    FILEHANDLETYPE readerIOStream;
    FILEHANDLETYPE *readerIOStreamPtr;


	/* Create the anonymous OS pipe */

	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	readerIOStreamPtr = &readerIOStream;
	writerIOStreamPtr = &writerIOStream;
	if (!(makePipeForReaderwriter(readerIOStreamPtr, writerIOStreamPtr))) {
		return interpreterProxy->primitiveFail();
	}
	writer = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(writer)) && ((interpreterProxy->byteSizeOf(writer)) == (fileRecordSize()))) {
		writerPtr = interpreterProxy->arrayValueOf(writer);
		goto l1;
	} else {
		interpreterProxy->primitiveFail();
		writerPtr = null;
		goto l1;
	}
l1:	/* end fileValueOf: */;
	writerPtr->file = writerIOStream;
	writerPtr->sessionID = thisSession;
	writerPtr->writable = 1;
	writerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(writer);
	reader = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
	/* begin fileValueOf: */
	if ((interpreterProxy->isBytes(reader)) && ((interpreterProxy->byteSizeOf(reader)) == (fileRecordSize()))) {
		readerPtr = interpreterProxy->arrayValueOf(reader);
		goto l2;
	} else {
		interpreterProxy->primitiveFail();
		readerPtr = null;
		goto l2;
	}
l2:	/* end fileValueOf: */;
	readerPtr->file = readerIOStream;
	readerPtr->sessionID = thisSession;
	readerPtr->writable = 0;
	readerPtr->lastOp = 0;
	interpreterProxy->pushRemappableOop(reader);
	arrayResult = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	interpreterProxy->stObjectatput(arrayResult, 1, interpreterProxy->popRemappableOop());
	interpreterProxy->stObjectatput(arrayResult, 2, interpreterProxy->popRemappableOop());
	interpreterProxy->pop(2);
	interpreterProxy->push(arrayResult);
}


/*	Answer a string containing the module name string for this plugin. */

EXPORT(int) primitiveModuleName(void) {
    char *s;

	s= (char *)moduleName;
	interpreterProxy->pop(1);
	interpreterProxy->push(stringFromCString(s));
}


/*	Set an environment variable using a string of the form 'KEY=value'. This
	implementation allocates a C string using malloc to allocate from the C heap
	(using cStringFromString rather than transientCStringFromString). This
	is necessary because the C runtime library does not make a copy of the
	string into separately allocated environment memory. */

EXPORT(int) primitivePutEnv(void) {
    char *cStringPtr;
    int keyValueString;

	keyValueString = interpreterProxy->stackObjectValue(0);
	cStringPtr = cStringFromString(keyValueString);
	if ((putenv(cStringPtr)) == 0) {
		interpreterProxy->pop(2);
		interpreterProxy->push(keyValueString);
	} else {
		return interpreterProxy->primitiveFail();
	}
}


/*	Answer the real path for a path string as determined by realpath(). */

EXPORT(int) primitiveRealpath(void) {
    int newPathString;
    char *pathString;
    int s;
    char * realpathResult;
    int bufferSize;
    char *buffer;

	bufferSize = 1024;
	newPathString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), bufferSize);
	interpreterProxy->pushRemappableOop(newPathString);
	pathString = transientCStringFromString(interpreterProxy->stackObjectValue(0));
	newPathString = interpreterProxy->popRemappableOop();
	buffer = interpreterProxy->arrayValueOf(newPathString);
	realpathResult = realpath(pathString, buffer);
	if (realpathResult == 0) {
		return interpreterProxy->primitiveFail();
	} else {
		if ((strlen(realpathResult)) >= 1024) {
			perror("warning: statically allocated array exceeded in UnixOSProcessPlugin>>primitiveRealPath, object memory may have been corrupted");
			return interpreterProxy->primitiveFail();
		}
		s = stringFromCString(realpathResult);
		interpreterProxy->pop(2);
		interpreterProxy->push(s);
	}
}


/*	Clean up after the death of a child, and answer an array with the pid and
	the exit status of the child process. Answer nil if the pidToHandle does not exist. */

EXPORT(int) primitiveReapChildProcess(void) {
    int pidResult;
    int resultArray;
    int *arrayPtr;
    int exitStatus;
    int pidToHandle;


	/* Force C code translator to declare the variable */

	exitStatus = 0;
	pidToHandle = interpreterProxy->stackIntegerValue(0);
	pidResult = waitpid ( pidToHandle, &exitStatus, WNOHANG );
	if (pidResult <= 0) {
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->nilObject());
	} else {
		resultArray = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
		arrayPtr = interpreterProxy->firstIndexableField(resultArray);
		arrayPtr[0] = integerObjectOf(pidResult);
		arrayPtr[1] = integerObjectOf(exitStatus);
		interpreterProxy->pop(2);
		interpreterProxy->push(resultArray);
	}
}


/*	Take a struct SQFile from the stack, and call fflush() to flush the OS stream. This flushes the
	file stream in the C library, not the stream in Smalltalk. For output streams, consider setting
	the OS stream (C library) to unbuffered output, and letting Smalltalk do all the buffering. */

EXPORT(int) primitiveSQFileFlush(void) {
    int thisSession;
    SQFile *sqFile;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(0);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}

	/* If the session identifier can be obtained, use it as an additional consistency check */

	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = null;
	if (thisSession == null) {
		null;
	} else {
		if (!(sqFile->sessionID)) {
			return interpreterProxy->primitiveFail();
		}
	}
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(fflush(sqFile->file));
}


/*	Take a struct SQFile from the stack, and call fflush() to flush the OS stream. This flushes the
	file stream in the C library, not the stream in Smalltalk. For output streams, consider setting
	the OS stream (C library) to unbuffered output, and letting Smalltalk do all the buffering.
	The session identifier is passed as the parameter to this primitive. Use this variant if the session
	identifier is not available directly in the VM (as may be the case if it is not possible to link from
	this plugin to a variable elsewhere in the VM). */

EXPORT(int) primitiveSQFileFlushWithSessionIdentifier(void) {
    int thisSession;
    SQFile *sqFile;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(1);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}
	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	if (thisSession == (sqFile->sessionID)) {
		interpreterProxy->pop(3);
		interpreterProxy->pushInteger(fflush(sqFile->file));
	} else {
		return interpreterProxy->primitiveFail();
	}
}


/*	Take a struct SQFile from the stack, and call fcntl() to set the file for blocking I/O. */

EXPORT(int) primitiveSQFileSetBlocking(void) {
    int descriptor;
    int thisSession;
    SQFile *sqFile;
    int flags;
    int retVal;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(0);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}

	/* If the session identifier can be obtained, use it as an additional consistency check */

	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = null;
	if (thisSession == null) {
		null;
	} else {
		if (!(sqFile->sessionID)) {
			return interpreterProxy->primitiveFail();
		}
	}
	descriptor = fileDescriptorFrom(sqFileOop);
	if (descriptor < 0) {
		return interpreterProxy->primitiveFail();
	}
	flags = fcntl(descriptor, F_GETFL);
	retVal = fcntl(descriptor, F_SETFL, flags & ~O_NONBLOCK);
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(retVal);
}


/*	Take a struct SQFile from the stack, and call fcntl() to set the file for blocking I/O.
	Use this variant if the session identifier is not available directly in the VM (as may be
	the case if it is not possible to link from this plugin to a variable elsewhere in the VM). */

EXPORT(int) primitiveSQFileSetBlockingWithSessionIdentifier(void) {
    int descriptor;
    int thisSession;
    SQFile *sqFile;
    int flags;
    int retVal;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(1);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}
	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	if (thisSession == (sqFile->sessionID)) {
		descriptor = fileDescriptorFrom(sqFileOop);
		if (descriptor < 0) {
			return interpreterProxy->primitiveFail();
		}
		flags = fcntl(descriptor, F_GETFL);
		retVal = fcntl(descriptor, F_SETFL, flags & ~O_NONBLOCK);
		interpreterProxy->pop(3);
		interpreterProxy->pushInteger(retVal);
	} else {
		return interpreterProxy->primitiveFail();
	}
}


/*	Take a struct SQFile from the stack, and call fcntl() to set the file non-blocking I/O. */

EXPORT(int) primitiveSQFileSetNonBlocking(void) {
    int descriptor;
    int thisSession;
    SQFile *sqFile;
    int flags;
    int retVal;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(0);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}

	/* If the session identifier can be obtained, use it as an additional consistency check */

	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = null;
	if (thisSession == null) {
		null;
	} else {
		if (!(sqFile->sessionID)) {
			return interpreterProxy->primitiveFail();
		}
	}
	descriptor = fileDescriptorFrom(sqFileOop);
	if (descriptor < 0) {
		return interpreterProxy->primitiveFail();
	}
	flags = fcntl(descriptor, F_GETFL);
	retVal = fcntl(descriptor, F_SETFL, flags | O_NONBLOCK);
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(retVal);
}


/*	Take a struct SQFile from the stack, and call fcntl() to set the file non-blocking I/O.
	Use this variant if the session identifier is not available directly in the VM (as may be
	the case if it is not possible to link from this plugin to a variable elsewhere in the VM). */

EXPORT(int) primitiveSQFileSetNonBlockingWithSessionIdentifier(void) {
    int descriptor;
    int thisSession;
    SQFile *sqFile;
    int flags;
    int retVal;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(1);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}
	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	if (thisSession == (sqFile->sessionID)) {
		descriptor = fileDescriptorFrom(sqFileOop);
		if (descriptor < 0) {
			return interpreterProxy->primitiveFail();
		}
		flags = fcntl(descriptor, F_GETFL);
		retVal = fcntl(descriptor, F_SETFL, flags | O_NONBLOCK);
		interpreterProxy->pop(3);
		interpreterProxy->pushInteger(retVal);
	} else {
		return interpreterProxy->primitiveFail();
	}
}


/*	Take a struct SQFile from the stack, and call setbuf() to set the OS file stream
	(implemented in the C library) for unbuffered I/O. Answers the result of a fflush()
	call, not the result of the setbuf() call (which is type void). This is nearly useless,
	but may at least provide an indicator that we are operating on a valid file stream. */

EXPORT(int) primitiveSQFileSetUnbuffered(void) {
    int thisSession;
    SQFile *sqFile;
    int retVal;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(0);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}

	/* If the session identifier can be obtained, use it as an additional consistency check */

	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = null;
	if (thisSession == null) {
		null;
	} else {
		if (!(sqFile->sessionID)) {
			return interpreterProxy->primitiveFail();
		}
	}
	retVal = fflush(sqFile->file);
	setbuf(sqFile->file, NULL);
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(retVal);
}


/*	Take a struct SQFile from the stack, and call setbuf() to set the OS file stream (implemented in
	the C library) for unbuffered I/O. Answers the result of a fflush() call, not the result of the
	setbuf() call (which is type void). This is nearly useless, but may at least provide an indicator
	that we are operating on a valid file stream. Use this variant if the session identifier is not
	available directly in the VM (as may be the case if it is not possible to link from this plugin
	to a variable elsewhere in the VM). */

EXPORT(int) primitiveSQFileSetUnbufferedWithSessionIdentifier(void) {
    int thisSession;
    SQFile *sqFile;
    int retVal;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(1);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}
	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = sessionIdentifierFrom(interpreterProxy->stackObjectValue(0));
	if (thisSession == (sqFile->sessionID)) {
		retVal = fflush(sqFile->file);
		setbuf(sqFile->file, NULL);
		interpreterProxy->pop(3);
		interpreterProxy->pushInteger(retVal);
	} else {
		return interpreterProxy->primitiveFail();
	}
}


/*	Answer the registration index of the semaphore currently associated with the
	signal handler for sigNum. */

EXPORT(int) primitiveSemaIndexFor(void) {
    int sigNum;
    int index;

	sigNum = interpreterProxy->stackIntegerValue(0);
	index = semaIndices[sigNum];
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(index);
}


/*	Send SIGABRT (abort) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigabrtTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGABRT);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGALRM (alarm clock) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigalrmTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGALRM);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGCHLD (child status has changed, usually death of child) to the OS process
	identified by anIntegerPid. Use an explicit check for isIntegerObject so we can
	return -1 on error (the stackIntegerValue: method answers 1 on error, and 1 is a
	valid pid number). */

EXPORT(int) primitiveSendSigchldTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGCHLD);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGCONT (continue) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigcontTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGCONT);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGHUP (hangup) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSighupTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGHUP);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGINT (interrupt) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigintTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGINT);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGKILL (kill, unblockable) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigkillTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGKILL);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGPIPE (broken pipe) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigpipeTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGPIPE);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGQUIT (quit) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigquitTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGQUIT);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGSTOP (stop, unblockable) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigstopTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGSTOP);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGTERM (termination) to the OS process identified by anIntegerPid. Use an explicit
	check for isIntegerObject so we can return -1 on error (the stackIntegerValue: method
	answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigtermTo(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGTERM);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGUSR1 (User-defined signal 1) to the OS process identified by anIntegerPid. Use
	an explicit check for isIntegerObject so we can return -1 on error (the stackIntegerValue:
	method answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigusr1To(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGUSR1);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Send SIGUSR2 (User-defined signal 2) to the OS process identified by anIntegerPid. Use
	an explicit check for isIntegerObject so we can return -1 on error (the stackIntegerValue:
	method answers 1 on error, and 1 is a valid pid number). */

EXPORT(int) primitiveSendSigusr2To(int anIntegerPid) {
    int pidToSignal;
    int result;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		if (((interpreterProxy->stackValue(0)) & 1)) {
			pidToSignal = interpreterProxy->stackIntegerValue(0);
			result = kill(pidToSignal, SIGUSR2);
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(result);
		} else {
			interpreterProxy->pop(2);
			interpreterProxy->pushInteger(-1);
		}
	}
}


/*	Set the index of the semaphore used by the OSProcess with which I collaborate. My
	OSProcess should set this value so that I can use it when handling SIGCHLD signals
	(death of child). In the C translation this is a static int which would be shared by all
	instances of UnixOSProcessPlugin, which is expected to be a singleton. Answer the
	value of the semaphore index. */

EXPORT(int) primitiveSetSemaIndex(void) {
	sigChldSemaIndex = interpreterProxy->stackIntegerValue(0);
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(sigChldSemaIndex);
}


/*	Integer value corresponding to SIGCHLD */

EXPORT(int) primitiveSigChldNumber(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sigChldNumber());
}


/*	Integer value corresponding to SIGHUP */

EXPORT(int) primitiveSigHupNumber(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sigHupNumber());
}


/*	Integer value corresponding to SIGINT */

EXPORT(int) primitiveSigIntNumber(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sigIntNumber());
}


/*	Integer value corresponding to SIGKILL */

EXPORT(int) primitiveSigKillNumber(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sigKillNumber());
}


/*	Integer value corresponding to SIGPIPE */

EXPORT(int) primitiveSigPipeNumber(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sigPipeNumber());
}


/*	Integer value corresponding to SIGQUIT */

EXPORT(int) primitiveSigQuitNumber(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sigQuitNumber());
}


/*	Integer value corresponding to SIGTERM */

EXPORT(int) primitiveSigTermNumber(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sigTermNumber());
}


/*	Size in bytes of an integer, for this C compiler on this machine. */

EXPORT(int) primitiveSizeOfInt(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sizeOfInt());
}


/*	Size in bytes of a void pointer, for this C compiler on this machine. */

EXPORT(int) primitiveSizeOfPointer(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(sizeOfPointer());
}


/*	Take a struct SQFile from the stack, and check for ability to lock the specified region.
	If the exclusive flag is true, then specify an exclusive (F_WRLCK) lock on the
     file. Otherwise, specify a shared (F_RDLCK) lock. Any number of Unix processes
     may hold  a read lock (shared lock) on a file region, but only one process may
     hold a write lock (exclusive lock).

	If length is zero, then the request is for the entire file to be locked, including
	region extents that have not yet been allocated for the file.

	If the fcntl() call fails, answer -1 (the result of the failed call). Otherwise,
	answer an array with the following six fields:
		lockable (true or false)
		l_pid (pid of the process preventing this lock request, or nil)
		l_type (request type F_WRLCK or F_RDLOCK of the process preventing this lock request)
		l_whence (the SEEK_SET, SEEK_CUR, or SEEK_END value of the lock preventing this lock request).
		l_start (offset of the region lock preventing this lock request)
		l_len (length of the region lock preventing this lock request) */

EXPORT(int) primitiveTestLockableFileRegion(void) {
    int sqFileOop;
    int thisSession;
    int exclusive;
    int start;
    int resultArray;
    SQFile *sqFile;
    int result;
    int len;
    int fileNo;
    int canObtainLock;
    struct flock lockStruct;

	exclusive = (interpreterProxy->stackValue(0)) == (interpreterProxy->trueObject());
	len = interpreterProxy->stackIntegerValue(1);
	start = interpreterProxy->stackIntegerValue(2);
	sqFileOop = interpreterProxy->stackValue(3);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}

	/* If the session identifier can be obtained, use it as an additional consistency check */

	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = null;
	if (thisSession == null) {
		null;
	} else {
		if (!(sqFile->sessionID)) {
			return interpreterProxy->primitiveFail();
		}
	}

	/* Set up the flock structure parameter for fcntl() */

	fileNo = fileno(sqFile->file);
	if (exclusive) {
		lockStruct.l_type = F_WRLCK;
	} else {
		lockStruct.l_type = F_RDLCK;
	}
	lockStruct.l_whence = SEEK_SET;
	lockStruct.l_start = start;
	lockStruct.l_len = len;
	lockStruct.l_pid = 0;
	result = fcntl(fileNo, F_GETLK, &lockStruct);
	if (result == -1) {
		interpreterProxy->pop(5);
		interpreterProxy->pushInteger(result);
	} else {
		if (lockStruct.l_type == F_UNLCK) {
			canObtainLock = interpreterProxy->trueObject();
		} else {
			canObtainLock = interpreterProxy->falseObject();
		}
		resultArray = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 6);
		interpreterProxy->stObjectatput(resultArray, 1, canObtainLock);
		interpreterProxy->stObjectatput(resultArray, 2, (((lockStruct.l_pid) << 1) | 1));
		interpreterProxy->stObjectatput(resultArray, 3, (((lockStruct.l_type) << 1) | 1));
		interpreterProxy->stObjectatput(resultArray, 4, (((lockStruct.l_whence) << 1) | 1));
		interpreterProxy->stObjectatput(resultArray, 5, (((lockStruct.l_start) << 1) | 1));
		interpreterProxy->stObjectatput(resultArray, 6, (((lockStruct.l_len) << 1) | 1));
		interpreterProxy->popthenPush(5, resultArray);
	}
}


/*	Close a file handle at the close(2) level, using a handle returned by
	#primitiveUnixFileNumber. */

EXPORT(int) primitiveUnixFileClose(int anIntegerFileNumber) {
    int result;
    int handle;

	handle = interpreterProxy->stackIntegerValue(0);
	result = close(handle);
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(result);
}


/*	Take a struct SQFile from the stack, and answer the value of its Unix file number.
	The Unix file number is not directly useful to Squeak, but may be interesting for
	debugging problems involving failure to close unused file handles. */

EXPORT(int) primitiveUnixFileNumber(void) {
    SQFile *sqFile;
    int fileNo;
    int sqFileOop;

	sqFileOop = interpreterProxy->stackValue(0);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}
	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	fileNo = fileno(sqFile->file);
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(fileNo);
}


/*	Take a struct SQFile from the stack, and unlock the specified region.
	Answer the result of the call to fcntl(). If the region is in the file lock cache,
	remove it, but otherwise ignore the cache. The cache supports Win32 semantics
	within a single Squeak image, but not across separate images, therefore the
	unlock should be attempted regardless of whether this image thinks that the
	region has previously been locked. Answer the result of the call to fcntl(). */

EXPORT(int) primitiveUnlockFileRegion(void) {
    int sqFileOop;
    int thisSession;
    int start;
    SQFile *sqFile;
    int result;
    int len;
    int fileNo;
    struct flock lockStruct;

	len = interpreterProxy->stackIntegerValue(0);
	start = interpreterProxy->stackIntegerValue(1);
	sqFileOop = interpreterProxy->stackValue(2);
	if (!(isSQFileObject(sqFileOop))) {
		return interpreterProxy->primitiveFail();
	}

	/* If the session identifier can be obtained, use it as an additional consistency check */

	sqFile = interpreterProxy->arrayValueOf(sqFileOop);
	thisSession = null;
	if (thisSession == null) {
		null;
	} else {
		if (!(sqFile->sessionID)) {
			return interpreterProxy->primitiveFail();
		}
	}

	/* Set up the flock structure parameter for fcntl() */

	fileNo = fileno(sqFile->file);
	lockStruct.l_type = F_UNLCK;
	lockStruct.l_whence = SEEK_SET;
	lockStruct.l_start = start;
	lockStruct.l_len = len;
	lockStruct.l_pid = 0;
	result = fcntl(fileNo, F_SETLK, &lockStruct);
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(result);
}


/*	Unset an environment variable. */
/*	FIXME: unsetenv() is not portable. For Solaris or any other system which does not
	support unsetenv(), just comment it out in this method and rebuild the plugin. */

EXPORT(int) primitiveUnsetEnv(void) {
    int keyString;
    char *cStringPtr;

	keyString = interpreterProxy->stackObjectValue(0);

	/* For Solaris, comment out the following line */

	cStringPtr = transientCStringFromString(keyString);
	unsetenv(cStringPtr);
	interpreterProxy->pop(1);
}


/*	Answer a string containing the version string for this plugin. */

EXPORT(int) primitiveVersionString(void) {
	interpreterProxy->pop(1);
	interpreterProxy->push(stringFromCString(versionString()));
}


/*	This is a signal handler for SIGCHLD. It is not meant to be called from Smalltalk,
	and should only be called indirectly as a result of a death of child signal from
	the operating system.

	Child processes must be cleaned up by the parent, otherwise they continue
	to exist as zombies until the parent exits. This handler resets the signal handler
	to catch the next SIGCHLD signal, then sets a semaphore to notify the system
	that a child process needs to be cleaned up. The actual clean up is done by a
	Smalltalk process which waits on the semaphore, then calls primitiveReapChildProcess.

	Note: If child processes die faster than we can clean them up, signals will be lost
	and child processes will remain as zombies. */

static void reapChildProcess(int sigNum) {
	setSigChldHandler();
	if (sigChldSemaIndex > 0) {
		interpreterProxy->signalSemaphoreWithIndex(sigChldSemaIndex);
	}
}


/*	Restore signal handlers to their original behaviors. */

static void restoreDefaultSignalHandlers(void) {
    int sigNum;

	sigNum = 1;
	while (sigNum <= (signalArraySize())) {
		if ((semaIndices[sigNum]) > 0) {
			setSignalNumberhandler(sigNum, originalSigHandlers[sigNum]);
		}
		sigNum += 1;
	}
}


/*	Answer 1 if running in secure mode, else 0. The osprocessSandboxSecurity
	variable is initialized to -1. On the first call to this method, set its value to
	either 0 (user has full access to the plugin) or 1 (user is not permitted to do
	dangerous things). */

static int sandboxSecurity(void) {
	if (osprocessSandboxSecurity < 0) {
		osprocessSandboxSecurity = securityHeurisitic();
	}
	return osprocessSandboxSecurity;
}


/*	Answer 0 to permit full access to OSProcess functions, or 1 if access should be
	restricted for dangerous functions. The rules are:
		- If the security plugin is not present, grant full access
		- If the security plugin can be loaded, restrict access unless user has all
		  of secCanWriteImage, secHasFileAccess and secHasSocketAccess */
/*	FIXME: This function has not been tested. -dtl */
/*	If the security plugin can be loaded, use it to check. If not, assume it's ok */

static int securityHeurisitic(void) {
    int hasSocketAccess;
    int sHSAfn;
    int canWriteImage;
    int sCWIfn;
    int sHFAfn;
    int hasFileAccess;

	sCWIfn = interpreterProxy->ioLoadFunctionFrom("secCanWriteImage", "SecurityPlugin");
	if (sCWIfn == 0) {
		return 0;
	}
	canWriteImage =  ((int (*) (void)) sCWIfn)();
	sHFAfn = interpreterProxy->ioLoadFunctionFrom("secHasFileAccess", "SecurityPlugin");
	if (sHFAfn == 0) {
		return 0;
	}
	hasFileAccess =  ((int (*) (void)) sHFAfn)();
	sHSAfn = interpreterProxy->ioLoadFunctionFrom("secHasSocketAccess", "SecurityPlugin");
	if (sHSAfn == 0) {
		return 0;
	}
	hasSocketAccess =  ((int (*) (void)) sHSAfn)();
	if ((canWriteImage && (hasFileAccess)) && (hasSocketAccess)) {
		return 0;
	} else {
		return 1;
	}
}


/*	An array of Smalltalk Semaphore indices, one for each signal type for which
	a handler has been set. If an entry is zero, then no handler is active. */

static unsigned char * semaphoreIndices(void) {
	return semaIndices;
}


/*	Answer a session ID represented by aByteArray. The session ID is used in
	the SQFile structure. If that data structure changes, we should see compiler
	warnings about type mismatch with SESSIONIDENTIFIERTYPE. */

static SESSIONIDENTIFIERTYPE sessionIdentifierFrom(int aByteArray) {
    unsigned char *session;
    union {SESSIONIDENTIFIERTYPE session; unsigned char bytes[sizeof(SESSIONIDENTIFIERTYPE)];} sessionUnion;
    int idx;

	if (!((interpreterProxy->isBytes(aByteArray)) && ((interpreterProxy->stSizeOf(aByteArray)) == (sizeOfSession())))) {
		return null;
	}
	session = interpreterProxy->arrayValueOf(aByteArray);
	idx = 0;
	while (idx < (sizeOfSession())) {
		sessionUnion.bytes[idx] = session[idx];
		idx += 1;
	}
	return sessionUnion.session;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter) {
    int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}

static void setSigChldDefaultHandler(void) {
	setSignalNumberhandler(sigChldNumber(), sigDefaultNumber());
}


/*	Set the SIGCHLD signal handler in the virtual machine. */

static void setSigChldHandler(void) {
	if ((signal(SIGCHLD, reapChildProcess)) == (sigErrorNumber())) {
		perror("signal");
	}
}

static void setSigIntDefaultHandler(void) {
	setSignalNumberhandler(sigIntNumber(), sigDefaultNumber());
}


/*	Set the SIGINT signal handler in the virtual machine to ignore interrupts. */

static void setSigIntIgnore(void) {
	setSignalNumberhandler(sigIntNumber(), sigIgnoreNumber());
}

static void setSigPipeDefaultHandler(void) {
	setSignalNumberhandler(sigPipeNumber(), sigDefaultNumber());
}


/*	Set the SIGPIPE signal handler in the virtual machine to ignore pipe error signals.
	If a pipe is opened to a child process, and the child exits, then subsequent writes to
	the pipe generate a SIGPIPE signal. If this signal is not handled, the VM will exit
	without warning. */

static int setSigPipeHandler(void) {
	/* begin setSigPipeIgnore */
	setSignalNumberhandler(sigPipeNumber(), sigIgnoreNumber());
}


/*	Set the SIGPIPE signal handler in the virtual machine to ignore pipe error signals. */

static void setSigPipeIgnore(void) {
	setSignalNumberhandler(sigPipeNumber(), sigIgnoreNumber());
}


/*	Set a signal handler. The C code translator will convert #sig:nal: into 'signal(parm1, parm2)' */

static void * setSignalNumberhandler(int anInteger, void * signalHandlerAddress) {
	return signal(anInteger, signalHandlerAddress);
}

EXPORT(int) shutdownModule(void) {
    int sigNum;

	/* begin restoreDefaultSignalHandlers */
	sigNum = 1;
	while (sigNum <= (signalArraySize())) {
		if ((semaIndices[sigNum]) > 0) {
			setSignalNumberhandler(sigNum, originalSigHandlers[sigNum]);
		}
		sigNum += 1;
	}
}


/*	Child status has changed (POSIX). */

static int sigChldNumber(void) {
	return SIGCHLD;
}


/*	Default action for a signal */

static void * sigDefaultNumber(void) {
	return SIG_DFL;
}


/*	Error return from signal() */

static void * sigErrorNumber(void) {
	return SIG_ERR;
}


/*	Hangup detected on controlling terminal or death of controlling process */

static int sigHupNumber(void) {
	return SIGHUP;
}


/*	Ignore action for a signal */

static void * sigIgnoreNumber(void) {
	return SIG_IGN;
}


/*	Interrupt (ANSI). */

static int sigIntNumber(void) {
	return SIGINT;
}


/*	Kill signal */

static int sigKillNumber(void) {
	return SIGKILL;
}


/*	Broken pipe (POSIX). */

static int sigPipeNumber(void) {
	return SIGPIPE;
}


/*	Quit from keyboard */

static int sigQuitNumber(void) {
	return SIGQUIT;
}


/*	Termination signal. This is the default signal sent by the unix kill(1) command. */

static int sigTermNumber(void) {
	return SIGTERM;
}


/*	Number of possible signals for this OS plus one. The signal handler arrays
	declared in #declareCVarsIn: are this size. */

static int signalArraySize(void) {
	return NSIG;
}


/*	An array of signal handler function addresses, with each entry corresponding
	to a signal type. */

static void ** signalHandlers(void) {
	return sigHandlers;
}


/*	Size in bytes of an integer, for this C compiler on this machine. */

static int sizeOfInt(void) {
	return sizeof(int);
}


/*	Size in bytes of a void pointer, for this C compiler on this machine. */

static int sizeOfPointer(void) {
	return sizeof(void *);
}


/*	Size of a SESSIONIDENTIFIERTYPE. Should match usage in the SQFile data structure,
	otherwise we should get compiler warnings. */

static int sizeOfSession(void) {
	return sizeof(SESSIONIDENTIFIERTYPE);
}


/*	Answer the size of a SQSocket data structure in bytes. */

static int socketRecordSize(void) {
	return sizeof(SQSocket);
}


/*	Return a pointer to the first byte of of the SQsocket data structure socket record within
	anSQSocketRecord, which is expected to be a ByteArray of size self>>socketRecordSize. */

static SQSocket * socketValueOf(int anSQSocketRecord) {
	if ((interpreterProxy->isBytes(anSQSocketRecord)) && ((interpreterProxy->byteSizeOf(anSQSocketRecord)) == (socketRecordSize()))) {
		return interpreterProxy->arrayValueOf(anSQSocketRecord);
	} else {
		return null;
	}
}


/*	Answer a new String copied from a null-terminated C string.
	Caution: This may invoke the garbage collector. */

static int stringFromCString(char *aCString) {
    int len;
    char *stringPtr;
    int newString;

	len = strlen(aCString);
	newString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), len);
	stringPtr = interpreterProxy->arrayValueOf(newString);
	(char *)strncpy(stringPtr, aCString, len);
	return newString;
}


/*	Answer a new null-terminated C string copied from aString.
	The string is allocated in object memory, and will be moved
	without warning by the garbage collector. Any C pointer
	reference the the result is valid only until the garbage
	collector next runs. Therefore, this method should only be used
	within a single primitive in a section of code in which the
	garbage collector is guaranteed not to run. Note also that
	this method may itself invoke the garbage collector prior
	to allocating the new C string.

	Warning: The result of this method will be invalidated by the
	next garbage collection, including a GC triggered by creation
	of a new object within a primitive. Do not call this method
	twice to obtain two string pointers. */

static char * transientCStringFromString(int aString) {
    char *stringPtr;
    int len;
    char *cString;
    int newString;


	/* Allocate space for a null terminated C string. */

	len = interpreterProxy->sizeOfSTArrayFromCPrimitive(interpreterProxy->arrayValueOf(aString));
	interpreterProxy->pushRemappableOop(aString);
	newString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), len + 1);
	stringPtr = interpreterProxy->arrayValueOf(interpreterProxy->popRemappableOop());

	/* Point to the actual C string. */

	cString = interpreterProxy->arrayValueOf(newString);
	(char *)strncpy(cString, stringPtr, len);
	cString[len] = 0;
	return cString;
}


/*	Answer a string containing the version string for this plugin. Handle MNU
	errors, which can occur if class InterpreterPlugin has been removed from
	the system.

	Important: When this method is changed, the class side method must also be
	changed to match. */

static char * versionString(void) {
    static char version[]= "3.3";

	return version;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* UnixOSProcessPlugin_exports[][3] = {
	{"UnixOSProcessPlugin", "primitiveSigKillNumber", (void*)primitiveSigKillNumber},
	{"UnixOSProcessPlugin", "primitiveGetStdInHandle", (void*)primitiveGetStdInHandle},
	{"UnixOSProcessPlugin", "primitiveForkSqueak", (void*)primitiveForkSqueak},
	{"UnixOSProcessPlugin", "primitiveSQFileSetNonBlockingWithSessionIdentifier", (void*)primitiveSQFileSetNonBlockingWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveForkAndExecInDirectory", (void*)primitiveForkAndExecInDirectory},
	{"UnixOSProcessPlugin", "primitiveSigHupNumber", (void*)primitiveSigHupNumber},
	{"UnixOSProcessPlugin", "primitiveModuleName", (void*)primitiveModuleName},
	{"UnixOSProcessPlugin", "primitiveSigQuitNumber", (void*)primitiveSigQuitNumber},
	{"UnixOSProcessPlugin", "primitiveIsAtEndOfFile", (void*)primitiveIsAtEndOfFile},
	{"UnixOSProcessPlugin", "primitiveSendSigcontTo", (void*)primitiveSendSigcontTo},
	{"UnixOSProcessPlugin", "primitiveForkExec", (void*)primitiveForkExec},
	{"UnixOSProcessPlugin", "primitiveSendSigstopTo", (void*)primitiveSendSigstopTo},
	{"UnixOSProcessPlugin", "primitiveSendSigintTo", (void*)primitiveSendSigintTo},
	{"UnixOSProcessPlugin", "primitiveSendSigalrmTo", (void*)primitiveSendSigalrmTo},
	{"UnixOSProcessPlugin", "primitiveSendSigpipeTo", (void*)primitiveSendSigpipeTo},
	{"UnixOSProcessPlugin", "primitiveSendSigquitTo", (void*)primitiveSendSigquitTo},
	{"UnixOSProcessPlugin", "primitiveAioHandle", (void*)primitiveAioHandle},
	{"UnixOSProcessPlugin", "primitiveSizeOfInt", (void*)primitiveSizeOfInt},
	{"UnixOSProcessPlugin", "primitiveTestLockableFileRegion", (void*)primitiveTestLockableFileRegion},
	{"UnixOSProcessPlugin", "primitiveReapChildProcess", (void*)primitiveReapChildProcess},
	{"UnixOSProcessPlugin", "primitiveSigIntNumber", (void*)primitiveSigIntNumber},
	{"UnixOSProcessPlugin", "primitiveCreatePipeWithSessionIdentifier", (void*)primitiveCreatePipeWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveGetStdOutHandleWithSessionIdentifier", (void*)primitiveGetStdOutHandleWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveSigPipeNumber", (void*)primitiveSigPipeNumber},
	{"UnixOSProcessPlugin", "primitiveArgumentAt", (void*)primitiveArgumentAt},
	{"UnixOSProcessPlugin", "primitiveEnvironmentAtSymbol", (void*)primitiveEnvironmentAtSymbol},
	{"UnixOSProcessPlugin", "initialiseModule", (void*)initialiseModule},
	{"UnixOSProcessPlugin", "primitiveGetStdOutHandle", (void*)primitiveGetStdOutHandle},
	{"UnixOSProcessPlugin", "getModuleName", (void*)getModuleName},
	{"UnixOSProcessPlugin", "primitiveAioDisable", (void*)primitiveAioDisable},
	{"UnixOSProcessPlugin", "primitiveGetUid", (void*)primitiveGetUid},
	{"UnixOSProcessPlugin", "primitiveCreatePipe", (void*)primitiveCreatePipe},
	{"UnixOSProcessPlugin", "primitiveFileStat", (void*)primitiveFileStat},
	{"UnixOSProcessPlugin", "primitiveSQFileSetUnbufferedWithSessionIdentifier", (void*)primitiveSQFileSetUnbufferedWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveSendSigtermTo", (void*)primitiveSendSigtermTo},
	{"UnixOSProcessPlugin", "primitiveGetEUid", (void*)primitiveGetEUid},
	{"UnixOSProcessPlugin", "primitiveSendSigusr1To", (void*)primitiveSendSigusr1To},
	{"UnixOSProcessPlugin", "primitiveVersionString", (void*)primitiveVersionString},
	{"UnixOSProcessPlugin", "primitiveGetStdErrHandleWithSessionIdentifier", (void*)primitiveGetStdErrHandleWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveChdir", (void*)primitiveChdir},
	{"UnixOSProcessPlugin", "forkSqueak", (void*)forkSqueak},
	{"UnixOSProcessPlugin", "primitiveAioSuspend", (void*)primitiveAioSuspend},
	{"UnixOSProcessPlugin", "primitiveFixPointersInArrayOfStrings", (void*)primitiveFixPointersInArrayOfStrings},
	{"UnixOSProcessPlugin", "primitiveLockFileRegion", (void*)primitiveLockFileRegion},
	{"UnixOSProcessPlugin", "primitiveForwardSignalToSemaphore", (void*)primitiveForwardSignalToSemaphore},
	{"UnixOSProcessPlugin", "primitiveSQFileSetBlocking", (void*)primitiveSQFileSetBlocking},
	{"UnixOSProcessPlugin", "primitiveGetPPid", (void*)primitiveGetPPid},
	{"UnixOSProcessPlugin", "primitiveSendSigusr2To", (void*)primitiveSendSigusr2To},
	{"UnixOSProcessPlugin", "primitiveSetSemaIndex", (void*)primitiveSetSemaIndex},
	{"UnixOSProcessPlugin", "primitiveRealpath", (void*)primitiveRealpath},
	{"UnixOSProcessPlugin", "primitiveSendSighupTo", (void*)primitiveSendSighupTo},
	{"UnixOSProcessPlugin", "primitiveUnixFileClose", (void*)primitiveUnixFileClose},
	{"UnixOSProcessPlugin", "primitiveGetEGid", (void*)primitiveGetEGid},
	{"UnixOSProcessPlugin", "primitiveFileProtectionMask", (void*)primitiveFileProtectionMask},
	{"UnixOSProcessPlugin", "primitiveMakePipeWithSessionIdentifier", (void*)primitiveMakePipeWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveGetStdInHandleWithSessionIdentifier", (void*)primitiveGetStdInHandleWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveSizeOfPointer", (void*)primitiveSizeOfPointer},
	{"UnixOSProcessPlugin", "primitiveSendSigchldTo", (void*)primitiveSendSigchldTo},
	{"UnixOSProcessPlugin", "primitiveEnvironmentAt", (void*)primitiveEnvironmentAt},
	{"UnixOSProcessPlugin", "primitiveForkSqueakWithoutSigHandler", (void*)primitiveForkSqueakWithoutSigHandler},
	{"UnixOSProcessPlugin", "primitivePutEnv", (void*)primitivePutEnv},
	{"UnixOSProcessPlugin", "primitiveUnsetEnv", (void*)primitiveUnsetEnv},
	{"UnixOSProcessPlugin", "primitiveSigTermNumber", (void*)primitiveSigTermNumber},
	{"UnixOSProcessPlugin", "primitiveGetStdErrHandle", (void*)primitiveGetStdErrHandle},
	{"UnixOSProcessPlugin", "primitiveSQFileFlushWithSessionIdentifier", (void*)primitiveSQFileFlushWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveGetCurrentWorkingDirectory", (void*)primitiveGetCurrentWorkingDirectory},
	{"UnixOSProcessPlugin", "primitiveMakePipe", (void*)primitiveMakePipe},
	{"UnixOSProcessPlugin", "primitiveSendSigabrtTo", (void*)primitiveSendSigabrtTo},
	{"UnixOSProcessPlugin", "primitiveErrorMessageAt", (void*)primitiveErrorMessageAt},
	{"UnixOSProcessPlugin", "primitiveGetPid", (void*)primitiveGetPid},
	{"UnixOSProcessPlugin", "primitiveSigChldNumber", (void*)primitiveSigChldNumber},
	{"UnixOSProcessPlugin", "primitiveCanReceiveSignals", (void*)primitiveCanReceiveSignals},
	{"UnixOSProcessPlugin", "primitiveGetGid", (void*)primitiveGetGid},
	{"UnixOSProcessPlugin", "setInterpreter", (void*)setInterpreter},
	{"UnixOSProcessPlugin", "primitiveSendSigkillTo", (void*)primitiveSendSigkillTo},
	{"UnixOSProcessPlugin", "primitiveSQFileSetUnbuffered", (void*)primitiveSQFileSetUnbuffered},
	{"UnixOSProcessPlugin", "primitiveAioEnable", (void*)primitiveAioEnable},
	{"UnixOSProcessPlugin", "primitiveGetSession", (void*)primitiveGetSession},
	{"UnixOSProcessPlugin", "primitiveUnlockFileRegion", (void*)primitiveUnlockFileRegion},
	{"UnixOSProcessPlugin", "shutdownModule", (void*)shutdownModule},
	{"UnixOSProcessPlugin", "primitiveUnixFileNumber", (void*)primitiveUnixFileNumber},
	{"UnixOSProcessPlugin", "primitiveSQFileSetBlockingWithSessionIdentifier", (void*)primitiveSQFileSetBlockingWithSessionIdentifier},
	{"UnixOSProcessPlugin", "primitiveSQFileFlush", (void*)primitiveSQFileFlush},
	{"UnixOSProcessPlugin", "primitiveSQFileSetNonBlocking", (void*)primitiveSQFileSetNonBlocking},
	{"UnixOSProcessPlugin", "primitiveSemaIndexFor", (void*)primitiveSemaIndexFor},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

