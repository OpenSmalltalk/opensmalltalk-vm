/****************************************************************************
*   PROJECT: Common include for BackToTheFuture/Squeak/Cog/OpenSmalltalk VM
*   FILE:    sq.h
*
*			See comments associated with STACKVM, COGVM, SPURVM, COGMTVM,
*			below for an overview of various VM flavours & features.
*/

#ifndef _SQ_H
#define _SQ_H


#ifdef HAVE_CONFIG_H
/* If HAVE_CONFIG_H is given (most presumably on the command line)
 * it is safe to include the (#define-only) config.h.
 * On prominent platforms, these defines must precede any inlcudes.
 * To quote feature_test_macros(7) on Linux:
 *   NOTE:  In  order to be effective, a feature test macro must be defined before including any header files.
 *
 * config.h provides these macros, either manually specified or
 * through means of configuration (eg. autoconf/configure).
 *
 * Having these defines early does not hurt platforms not using this
 * system but is vital on platforms using it. Hence it comes early
 */
#include "config.h"
#endif


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <limits.h>

#include "sqConfig.h"

#include <math.h>
#include "sqMathShim.h"

#include "sqMemoryAccess.h"
#include "sqVirtualMachine.h"

#if !defined(IMAGE_DIALECT_NAME)
# if NewspeakVM
#	define IMAGE_DIALECT_NAME "Newspeak"
#	define DEFAULT_IMAGE_NAME "newspeak.image"
#	define IMAGE_ENV_NAME "NEWSPEAK_IMAGE"
# elif CuisVM
#	define IMAGE_DIALECT_NAME "CuisVM"
#	define DEFAULT_IMAGE_NAME "CuisVM.image"
#	define IMAGE_ENV_NAME "CUIS_IMAGE"
# elif PharoVM
#	define IMAGE_DIALECT_NAME "Pharo"
#	define DEFAULT_IMAGE_NAME "Pharo.image"
#	define IMAGE_ENV_NAME "PHARO_IMAGE"
# else
#	define IMAGE_DIALECT_NAME "Squeak"
#	define DEFAULT_IMAGE_NAME "squeak.image"
#	define IMAGE_ENV_NAME "SQUEAK_IMAGE"
# endif
#endif

/* Platform-dependent millisecond clock macros. */

/* Note: The Squeak VM uses two different clock functions for timing, and
   the Cog VMs provide a third.

   The primary one, ioMSecs(), is used to implement Delay and Time
   millisecondClockValue. The resolution of this clock
   determines the resolution of these basic timing functions. For
   doing real-time control of music and MIDI, a clock with resolution
   down to one millisecond is preferred, but a coarser clock (say,
   1/60th second) can be used in a pinch.

   The function ioMicroMSecs() is used only to collect timing statistics
   for the garbage collector and other VM facilities. (The function
   name is meant to suggest that the function is based on a clock
   with microsecond accuracy, even though the times it returns are
   in units of milliseconds.) This clock must have enough precision to
   provide accurate timings, and normally isn't called frequently
   enough to slow down the VM. Thus, it can use a more expensive clock
   than ioMSecs(). This function is listed in the sqVirtualMachine plugin
   support mechanism and thus needs to be a real function, even if a macro is
   use to point to it.

   There was a third form that used to be used for quickly timing primitives in
   order to try to keep millisecond delays up to date. That is no longer used.

   The wall clock is answered by ioSeconds, which answers the number of seconds
   since the start of the 20th century (12pm Dec 31, 1900).

   The Cog VMs depend on a heartbeat to cause the VM to check for interrupts at
   regular intervals (of the order of ever millisecond).  The heartbeat on these
   VMs is responsible for updating a 64-bit microsecond clock with the number
   of microseconds since the start of the 20th century (12pm Dec 31, 1900)
   available via ioUTCMicroseconds and ioLocalMicroseconds.  When exact time is
   required we provide ioUTCMicrosecondsNow & ioLocalMicrosecondsNow that update
   the clock to return the time right now, rather than of the last heartbeat.
*/

unsigned int ioMSecs(void);
unsigned int ioMicroMSecs(void);

/* duplicate the generated definition in the interpreter.  If they differ the
 * compiler will complain and catch it for us.  We use 0x1FFFFFFF instead of
 * 0x3FFFFFFF so that twice the maximum clock value remains in the positive
 * SmallInteger range.  This assumes 31 bit SmallIntegers; 0x3FFFFFFF is
 * SmallInteger maxVal.
 */
#define MillisecondClockMask 0x1FFFFFFF

#if STACKVM
/* STACKVM is a replacement for the original BttF Interpreter VM which
 * interpreted code using Context objects as described in Smalltalk-80: the
 * Language and its Implementation.  STACKVM retains the image-level "illusion"
 * of Contexts but maps the most recently active Contexts to stack frames. This
 * provides both faster interpretation and enables the COGVM Cogit.  The scheme
 * is similar to that described in Deutsch & Schiffman's classic Efficient
 * Implementation of the Smalltalk-80 Language, but is a third generation
 * implementation, providing (and indeed depending on) pure closures, and using
 * a LISP-style indirection vector for modifyable closed-over variables to break
 * dependencies between stack frames.
 * See e.g. www.mirandabanda.org/cogblog/2008/06/07/closures-part-i/
 *
 * Since all OpenSmalltalk VMs are at least STACKVMs, STACKVM is synonymous
 * with OpenSmalltalk-VM and Cog VM.
 */
/* Time API, Cog uses 64-bit microseconds fron 1901 as much as possible */
void forceInterruptCheckFromHeartbeat(void);
void ioInitTime(void);
unsigned long long ioUTCMicrosecondsNow(void);
unsigned long long ioUTCMicroseconds(void);
unsigned long long ioLocalMicrosecondsNow(void);
unsigned long long ioLocalMicroseconds(void);
unsigned long long ioUTCStartMicroseconds(void);
sqInt	ioLocalSecondsOffset(void);
void	ioUpdateVMTimezone(void);
void	ioSynchronousCheckForEvents(void);
void	checkHighPriorityTickees(usqLong);
# if ITIMER_HEARTBEAT		/* Hack; allow heartbeat to avoid */
extern int numAsyncTickees; /* prodHighPriorityThread unless necessary */
# endif						/* see platforms/unix/vm/sqUnixHeartbeat.c */
void	ioGetClockLogSizeUsecsIdxMsecsIdx(sqInt*,void**,sqInt*,void**,sqInt*);
void	addIdleUsecs(sqInt);

# if COGVM
/* Cog has already captured CStackPointer before calling this routine.  Record
 * the original value, capture the pointers again and determine if CFramePointer
 * lies between the two stack pointers and hence is likely in use.  This is
 * necessary since optimizing C compilers may allocate the frame pointer as a
 * purpose register, in which case it need not and should not be captured.
 */
extern int isCFramePointerInUse(usqIntptr_t *cFpPtr, usqIntptr_t *cSpPtr);
/* For writing back the machine frame and stack pointer to the interpreter's
 * variables, which may allow for a stack backtrace to be generated on an
 * exception.
 */
extern void reportMinimumUnusedHeadroom();
extern void reportMinimumUnusedHeadroomOn(FILE *);
# endif
extern void ifValidWriteBackStackPointersSaveTo(void *,void *,char **,char **);
extern void dumpPrimTraceLog();
extern void dumpPrimTraceLogOn(FILE *);
#endif /* STACKVM */
extern void printCallStack(void);
extern void printCallStackOn(FILE *);
extern void printAllStacks(void);
extern void printAllStacksOn(FILE *);

/* this function should return the value of the high performance
   counter if there is such a thing on this platform (otherwise return 0) */
sqLong ioHighResClock(void);

/* New filename converting function; used by the interpreterProxy function 
  ioFilenamefromStringofLengthresolveAliases. Most platforms can ignore the
  resolveAlias boolean - it seems to only be of use by OSX but is crucial there.
*/
sqInt sqGetFilenameFromString(char *aCharBuffer, char *aFilenameString, sqInt filenameLength, sqInt aBoolean);

/* Macros to support Mac browser plugin without ugly code in Interpreter. */

#define insufficientMemorySpecifiedError()	error("Insufficient memory for this image")
#define insufficientMemoryAvailableError()	error("Failed to allocate memory for the heap")
#define unableToReadImageError()		error("Read failed or premature end of image file")
#define browserPluginReturnIfNeeded()
#define browserPluginInitialiseIfNeeded()

/* VM_TICKER enables facilities providing periodic invocation of functions
 * on a high-priority thread in the VM, preempting Smalltalk execution.
 */
#if VM_TICKER
extern usqInt ioVMTickerCount(void);
extern usqInt ioVMTickeeCallCount(void);
extern usqLong ioVMTickerStartUSecs(void);
#endif

/* Platform-specific header file may redefine earlier definitions and macros. */

#include "sqPlatformSpecific.h"

/* Interpreter entry points. */

sqInt checkedByteAt(sqInt byteAddress);
sqInt checkedByteAtput(sqInt byteAddress, sqInt byte);
sqInt checkedLongAt(sqInt byteAddress);
sqInt checkedLongAtput(sqInt byteAddress, sqInt a32BitInteger);
sqInt interpret(void);
sqInt primitiveFail(void);
sqInt signalSemaphoreWithIndex(sqInt semaIndex);
sqInt doSignalExternalSemaphores(sqInt);
sqInt success(sqInt);

/* Display, mouse, keyboard, time. */

extern VM_EXPORT void *displayBits;
extern VM_EXPORT int displayWidth, displayHeight, displayDepth;
extern VM_EXPORT sqInt sendWheelEvents;

sqInt ioBeep(void);
sqInt ioExit(void);
sqInt ioExitWithErrorCode(int);
sqInt crashInThisOrAnotherThread(sqInt flags);
sqInt fullDisplayUpdate(void);
void  ioNoteDisplayChangedwidthheightdepth(void *bitsOrHandle, int w, int h, int d);
sqInt ioForceDisplayUpdate(void);
sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
		  double hScale, double vScale, sqInt landscapeFlag);
sqInt ioSetFullScreen(sqInt fullScreen);
double ioScreenScaleFactor(void);
sqInt ioScreenSize(void);
sqInt ioScreenDepth(void);
sqInt ioSeconds(void);
sqInt ioSecondsNow(void);
sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY);
sqInt ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY);
sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);
sqInt ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB);
sqInt ioHasDisplayDepth(sqInt depth);
sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag);
char* ioGetLogDirectory(void);
sqInt ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz);
char* ioGetWindowLabel(void);
sqInt ioSetWindowLabelOfSize(void *lblIndex, sqInt sz);
sqInt ioGetWindowWidth(void);
sqInt ioGetWindowHeight(void);
sqInt ioSetWindowWidthHeight(sqInt w, sqInt h);
sqInt ioIsWindowObscured(void);

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds);
#if STACKVM || NewspeakVM
/* thread subsystem support for e.g. sqExternalSemaphores.c */
void ioInitThreads(void);

/* Management of the external semaphore table (max size set at startup) */
#if !defined(INITIAL_EXT_SEM_TABLE_SIZE)
# define INITIAL_EXT_SEM_TABLE_SIZE 256
#endif
int   ioGetMaxExtSemTableSize(void);
void  ioSetMaxExtSemTableSize(int);

/* these are used both in the STACKVM & the COGMTVM */
# if !defined(ioCurrentOSThread)
sqOSThread ioCurrentOSThread(void);
# endif
# if !defined(ioOSThreadsEqual)
int  ioOSThreadsEqual(sqOSThread,sqOSThread);
# endif
# if !COGMTVM
extern sqOSThread ioVMThread;
# define getVMOSThread() ioVMThread
# endif
#endif /* STACKVM || NewspeakVM */

#if STACKVM
/* Event polling via periodic heartbeat thread. */
void  ioInitHeartbeat(void);
int   ioHeartbeatMilliseconds(void);
void  ioSetHeartbeatMilliseconds(int);
unsigned long ioHeartbeatFrequency(int);
#endif /* STACKVM */

#if COGMTVM
/* COGMTVM is a yet-to-be-released "multi-threaded" VM in the style of Python,
 * where any thread can own the VM, but only one thread can be running the VM
 * at any one time.  Unlike Python's Global Interpreter Lock, this VM uses a
 * lock-free algorithm, based on David Simmons' design as realised in the AOS
 * and S# VMs.  Thread switches occur on FFI calls that take long enough for
 * the VM to notice (and may take place at other times, but FFI calls are the
 * key points).  Hence any call any be potentially non-blocking, and thread-
 * switch is cheap, simple and efficient. The heartbeat defined above is
 * extended to spot blocking FFI calls. See CoInterpreterMT in VMMaker.oscog.
 */
#define THRLOGSZ 256
extern int thrlogidx;
extern char *thrlog[];

/* Debug logging that defers printing.  Use like printf, e.g.
 * TLOG("tryLockVMToIndex vmOwner = %d\n", vmOwner);
 * Requires #include "sqAtomicOps.h"
 * N.B. The following still isn't safe.  If enough log entries are made by other
 * threads after myindex is obtained but before asprintf completes we can get
 * two threads using the same entry.  But this is good enough for now.
 */
#define THRLOG(...) do { int myidx, nextidx; \
	do { myidx = thrlogidx; \
		 nextidx = (myidx+1)&(THRLOGSZ-1); \
	} while (!sqCompareAndSwap(thrlogidx,myidx,nextidx)); \
	if (thrlog[myidx]) free(thrlog[myidx]); \
	asprintf(thrlog + myidx, __VA_ARGS__); \
} while (0)

extern sqOSThread getVMOSThread(void);
/* Please read the comment for CogThreadManager in the VMMaker package for
 * documentation of this API.  N.B. code is included from sqPlatformSpecific.h
 * before the code here.  e.g.
 * # include <pthread.h>
 * # define sqOSThread pthread_t
 * # define sqOSSemaphore pthread_cond_t
 * # define ioOSThreadsEqual(a,b) pthread_equal(a,b)
 */
# if !defined(ioGetThreadLocalThreadIndex)
long ioGetThreadLocalThreadIndex(void);
# endif
# if !defined(ioSetThreadLocalThreadIndex)
void ioSetThreadLocalThreadIndex(long);
# endif

# if !defined(ioNewOSThread)
int  ioNewOSThread(void (*func)(void *), void *);
# endif
# if !defined(ioExitOSThread)
void ioExitOSThread(sqOSThread thread);
# endif
# if !defined(ioReleaseOSThreadState)
void ioReleaseOSThreadState(sqOSThread thread);
# endif
# if !defined(ioOSThreadIsAlive)
int  ioOSThreadIsAlive(sqOSThread);
# endif
int  ioNewOSSemaphore(sqOSSemaphore *);
# if !defined(ioDestroyOSSemaphore)
void ioDestroyOSSemaphore(sqOSSemaphore *);
# endif
void ioSignalOSSemaphore(sqOSSemaphore *);
void ioWaitOnOSSemaphore(sqOSSemaphore *);
int  ioNumProcessors(void);
# if !defined(ioTransferTimeslice)
void ioTransferTimeslice(void);
# endif
#endif /* COGMTVM */

/* Profiling. */
void  ioControlProfile(int on, void **vhp, long *nvb, void **ehp, long *neb);
long  ioControlNewProfile(int on, unsigned long buffer_size);
void  ioNewProfileStatus(sqInt *running, long *buffersize);
long  ioNewProfileSamplesInto(void *sampleBuffer);
void  ioClearProfile(void);

/* Power management. */

sqInt ioDisablePowerManager(sqInt disableIfNonZero);

/* User input recording I:
   In general, either set of input function can be supported,
   depending on the platform. This (first) set is state based
   and should be supported even on platforms that make use
   of the newer event driven API to support older images 
   without event support.
*/

/* Note: In an event driven architecture, ioProcessEvents is obsolete.
   It can be implemented as a no-op since the image will check for
   events at regular intervals.
   eem 2021/3/5 not sure this is true; isn't it calls of ioProcessEvents
   that allows signals of the inputSDemaphore to be generated?
 */
sqInt ioProcessEvents(void);


/* User input recording II:
   The following functions and definition can be used on
   platform supporting events directly.
*/

/* Event types. */
#define EventTypeNone		0
#define EventTypeMouse		1
#define EventTypeKeyboard	2
#define EventTypeDragDropFiles	3
#define EventTypeMenu		4
#define EventTypeWindow		5
#define EventTypeComplex	6 /* For iPhone apps */
#define EventTypeMouseWheel	7 /* optional; see sendWheelEvents & vm param 48 */
#define EventTypePlugin		8 /* Terf: events from ActiveX Controls */


/* Keypress state for keyboard events. */
#define EventKeyChar	0
#define EventKeyDown	1
#define EventKeyUp		2

/* Button definitions. */
#define BlueButtonBit		 1
#define YellowButtonBit		 2
#define RedButtonBit		 4
#define MoveRightButtonBit	 8
#define MoveLeftButtonBit	16

/* Modifier definitions. */
#define ShiftKeyBit		1
#define CtrlKeyBit		2
#define OptionKeyBit	4
#define CommandKeyBit	8

/* generic input event */
typedef struct sqInputEvent {
  sqIntptr_t type;			/* type of event; either one of EventTypeXXX */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the event type */
  sqIntptr_t unused1;
  sqIntptr_t unused2;
  sqIntptr_t unused3;
  sqIntptr_t unused4;
  sqIntptr_t unused5;
  sqIntptr_t windowIndex;	/* SmallInteger used in image to identify a host window structure */
} sqInputEvent;

/* mouse input event */
typedef struct sqMouseEvent {
  sqIntptr_t type;			/* EventTypeMouse */
  usqIntptr_t timeStamp;	/* time stamp */
  sqIntptr_t x;				/* mouse position x */
  sqIntptr_t y;				/* mouse position y */
  sqIntptr_t buttons;		/* combination of xxxButtonBit */
  sqIntptr_t modifiers;		/* combination of xxxKeyBit */
  sqIntptr_t nrClicks;		/* number of clicks in button downs - was reserved1 */
  sqIntptr_t windowIndex;	/* host window structure */
} sqMouseEvent;

/* keyboard input event */
typedef struct sqKeyboardEvent {
  sqIntptr_t type;			/* EventTypeKeyboard */
  usqIntptr_t timeStamp;	/* time stamp */
  sqIntptr_t charCode;		/* character code in Mac Roman encoding */
  sqIntptr_t pressCode;		/* press code; any of EventKeyXXX */
  sqIntptr_t modifiers;		/* combination of xxxKeyBit */
  sqIntptr_t utf32Code;		/* UTF-32 unicode value */
  sqIntptr_t reserved1;		/* reserved for future use */
  sqIntptr_t windowIndex;	/* host window structure */
} sqKeyboardEvent;

/* drop files event */
typedef struct sqDragDropFilesEvent {
  sqIntptr_t type;			/* EventTypeDropFiles */
  usqIntptr_t timeStamp;	/* time stamp */
  sqIntptr_t dragType;		/* one of DragXXX (see below) */
  sqIntptr_t x;				/* mouse position x */
  sqIntptr_t y;				/* mouse position y */
  sqIntptr_t modifiers;		/* combination of xxxKeyBit */
  sqIntptr_t numFiles;		/* number of files in transaction */
  sqIntptr_t windowIndex;	/* host window structure */
} sqDragDropFilesEvent;

#define SQDragEnter		1 /* OS drag operation entered Squeak window	 */
#define SQDragMove		2 /* OS drag operation moved within Squeak window */
#define SQDragLeave		3 /* OS drag operation left Squeak window	 */
#define SQDragDrop		4 /* OS drag operation dropped contents onto Squeak. */
#define SQDragRequest	5 /* data request from other app. */

/* menu event */
typedef struct sqMenuEvent {
  sqIntptr_t type;			/* type of event; EventTypeMenu */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the event type */
  sqIntptr_t menu;			/* platform-dependent to indicate which menu was picked */
  sqIntptr_t menuItem;		/* given a menu having 1 to N items this maps to the menu item number */
  sqIntptr_t reserved1;		/* reserved for future use */
  sqIntptr_t reserved2;		/* reserved for future use */
  sqIntptr_t reserved3;		/* reserved for future use */
  sqIntptr_t windowIndex;	/* host window structure */
} sqMenuEvent;

/* window action event */
typedef struct sqWindowEvent {
  sqIntptr_t type;			/* type of event;  EventTypeWindow */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the event type */
  sqIntptr_t action;		/* one of WindowEventXXX (see below) */
  sqIntptr_t value1;		/* used for rectangle edges (left) */
  sqIntptr_t value2;		/* used for rectangle edges (top) */
  sqIntptr_t value3;		/* used for rectangle edges (right) */
  sqIntptr_t value4;		/* used for rectangle edges (bottom) */
  sqIntptr_t windowIndex;	/* host window structure */
} sqWindowEvent;

#define WindowEventMetricChange	1	/* size or position of window changed
									 * value1-4 are left/top/right/bottom
									 */
#define WindowEventClose		2	/* window close icon pressed */
#define WindowEventIconise		3	/* window iconised or hidden etc */
#define WindowEventActivated	4	/* window made active - some platforms only
									 * do not rely upon this */
#define WindowEventPaint		5	/* window area (in value1-4) needs updating.
									 * Some platforms do not need to send this,
									 * do not rely on it in image */
#define WindowEventChangeScreen	6	/* window moved to new screen.
									 * rect args are dimensions of new screen */
#define WindowEventDeactivated	7	/* window made inactive - the opposite of 
									 * WindowEventActivated */

typedef struct sqComplexEvent {
  sqIntptr_t type;			/* type of event;  EventTypeComplex */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the event type */
  sqIntptr_t action;		/* one of ComplexEventXXX (see below) */
  sqIntptr_t objectPointer;	/* used to point to object */
  sqIntptr_t unused1;
  sqIntptr_t unused2;
  sqIntptr_t unused3;
  sqIntptr_t windowIndex;	/* host window structure */
} sqComplexEvent;

#define ComplexEventTypeTouchsDown			1
#define ComplexEventTypeTouchsUp			2
#define ComplexEventTypeTouchsMoved			3
#define ComplexEventTypeTouchsStationary	4
#define ComplexEventTypeTouchsCancelled		5
#define ComplexEventTypeAccelerationData	6
#define ComplexEventTypeLocationData		7
#define ComplexEventTypeApplicationData		8


/* Set an asynchronous input semaphore index for events. */
sqInt ioSetInputSemaphore(sqInt semaIndex);
/* Retrieve the next input event from the OS. */
sqInt ioGetNextEvent(sqInputEvent *evt);

/* Log the event procesing chain. */
#if defined(DEBUG_EVENT_CHAIN)
# define LogEventChain(parms) fprintf parms
# define dbgEvtChF stderr
#else
# define LogEventChain(parms) 0
#endif

/* Image file and VM path names. */
extern char imageName[];
VM_EXPORT char *getImageName(void);
sqInt imageNameGetLength(sqInt sqImageNameIndex, sqInt length);
sqInt imageNamePutLength(sqInt sqImageNameIndex, sqInt length);
sqInt imageNameSize(void);
sqInt vmPathSize(void);
sqInt vmPathGetLength(sqInt sqVMPathIndex, sqInt length);

/* The following was not exported by sq.h but we need it
   since if we don't have CURRENT_VERSION around anymore
   and we may want to check for the image version we need it */
sqInt readableFormat(sqInt imageVersion);

/* Image security traps. */
sqInt ioCanRenameImage(void);
sqInt ioCanWriteImage(void);
sqInt ioDisableImageWrite(void);

/* Clipboard (cut/copy/paste). */
sqInt clipboardSize(void);
sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex);
sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex);


/* System attributes. */
const char *getAttributeString(sqInt indexNumber);

/*** Pluggable primitive support. ***/

/* NOTE: The following functions are those implemented by sqNamedPrims.c */
void *ioLoadExternalFunctionOfLengthFromModuleOfLength
		(sqInt functionNameIndex, sqInt functionNameLength,
		 sqInt moduleNameIndex, sqInt moduleNameLength);
#if SPURVM
void *ioLoadExternalFunctionOfLengthFromModuleOfLengthMetadataInto
	(sqInt functionNameIndex, sqInt functionNameLength,
	 sqInt moduleNameIndex,   sqInt moduleNameLength, sqInt *metadataPtr);
#endif
sqInt  ioUnloadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength);
void  *ioLoadFunctionFrom(char *functionName, char *pluginName);
sqInt  ioShutdownAllModules(void);
sqInt  ioUnloadModule(char *moduleName);
sqInt  ioUnloadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength);
char  *ioListBuiltinModule(sqInt moduleIndex);
char  *ioListLoadedModule(sqInt moduleIndex);
/* The next three for the FFI, also implemented in sqNamedPrims.c. */
void  *ioLoadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength);
void  *ioLoadSymbolOfLengthFromModule(sqInt functionNameIndex, sqInt functionNameLength, void *moduleHandle);
sqInt ioCanCatchFFIExceptions();

/* The next three functions must be implemented by sqXYZExternalPrims.c */
/* ioLoadModule:
	Load a module from disk.
	WARNING: this always loads a *new* module. Don't even attempt to find
	a loaded one.
	WARNING: never primitiveFail() within, just return 0
*/
void *ioLoadModule(char *pluginName);

/* ioFindExternalFunctionIn[MetadataInto]:
	Find the function with the given name in the moduleHandle.
	WARNING: never primitiveFail() within, just return 0.
	Note in Spur takes an extra parameter which is defaulted to 0.
*/
#if SPURVM
void *ioFindExternalFunctionInMetadataInto(char *lookupName, void *moduleHandle, sqInt *metadataPtr);
# define ioFindExternalFunctionIn(ln,mh) ioFindExternalFunctionInMetadataInto(ln,mh,0)
# define NullSpurMetadata -256 // -1 << 8, but shifting -ve values is undefined
# define SpurPrimitiveMetadataType signed short
# define validSpurPrimitiveMetadata(m) ((((m) >> 8) >= -1) && (((m) >> 8) <= 5))
#else
void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle);
#endif

/* ioFreeModule:
	Free the module with the associated handle.
	WARNING: never primitiveFail() within, just return 0.
*/
sqInt ioFreeModule(void *moduleHandle);

/* The Squeak version from which this interpreter was generated. */
extern const char *interpreterVersion;

#endif /* _SQ_H */
