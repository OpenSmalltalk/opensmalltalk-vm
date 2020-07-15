/****************************************************************************
*   PROJECT: Common include
*   FILE:    sq.h
*   CONTENT:
*
*   AUTHOR:
*   ADDRESS:
*   EMAIL:
*   RCSID:   $Id: sq.h 1283 2005-12-31 00:51:12Z rowledge $
*
*/

#ifndef _SQ_H
#define _SQ_H

#include "sqConfig.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <limits.h>

#include "sqMemoryAccess.h"
#include "sqVirtualMachine.h"


#define true	1
#define false	0
#define null	0  /* using "null" because nil is predefined in Think C */

#ifndef EXPORT
#define EXPORT(returnType) returnType
#endif

#include "pharovm/semaphores/platformSemaphore.h"


#if !defined(IMAGE_DIALECT_NAME)
# if NewspeakVM
#	define IMAGE_DIALECT_NAME "Newspeak"
#	define DEFAULT_IMAGE_NAME "newspeak.image"
#	define IMAGE_ENV_NAME "NEWSPEAK_IMAGE"
# elif PharoVM
#	define IMAGE_DIALECT_NAME "Pharo"
#	if !defined(DEFAULT_IMAGE_NAME)
#		define DEFAULT_IMAGE_NAME "Pharo.image"
#	endif
#	define IMAGE_ENV_NAME "PHARO_IMAGE"
# else
#	define IMAGE_DIALECT_NAME "Squeak"
#	define DEFAULT_IMAGE_NAME "squeak.image"
#	define IMAGE_ENV_NAME "SQUEAK_IMAGE"
# endif
#endif

/* Pluggable primitives macros. */

/* Note: All pluggable primitives are defined as
	EXPORT(int) somePrimitive(void)
   All non-static variables in the VM and plugins are declared as
	VM_EXPORT type var
   If the platform requires special declaration modifiers, the EXPORT and
   VM_EXPORT macros can be redefined.
*/
#define VM_EXPORT
#define VM_FUNCTION_EXPORT(returnType) returnType

/* Platform-dependent macros for handling object memory. */

#if SPURVM
/* Allocate a region of memory of al least sz bytes, at or above minAddr.
 * If the attempt fails, answer null.  If the attempt succeeds, answer the
 * start of the region and assign its size through asp.
 */
extern void *sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(sqInt sz, void *minAddr, sqInt *asp);
extern void sqDeallocateMemorySegmentAtOfSize(void *addr, sqInt sz);
#endif /* SPURVM */
/* Platform-dependent memory size adjustment macro. */

/* Note: This macro can be redefined to allows platforms with a
   fixed application memory partition (notably, the Macintosh)
   to reserve extra C heap memory for special applications that need
   it (e.g., for a 3D graphics library). Since most platforms can
   extend their application memory partition at run time if needed,
   this macro is defined as a noop here and redefined if necessary
   in sqPlatformSpecific.h.
*/

#define reserveExtraCHeapBytes(origHeapSize, bytesToReserve) origHeapSize

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

long ioMSecs(void);
sqInt ioMicroMSecs(void);

/* duplicate the generated definition in the interpreter.  If they differ the
 * compiler will complain and catch it for us.  We use 0x1FFFFFFF instead of
 * 0x3FFFFFFF so that twice the maximum clock value remains in the positive
 * SmallInteger range.  This assumes 31 bit SmallIntegers; 0x3FFFFFFF is
 * SmallInteger maxVal.
 */
#define MillisecondClockMask 0x1FFFFFFF

#if STACKVM
extern void forceInterruptCheckFromHeartbeat(void);
unsigned volatile long long  ioUTCMicrosecondsNow();
unsigned volatile long long  ioUTCMicroseconds();
unsigned volatile long long  ioLocalMicrosecondsNow();
unsigned volatile long long  ioLocalMicroseconds();
unsigned          long long  ioUTCStartMicroseconds();
sqInt	ioLocalSecondsOffset();
void	ioUpdateVMTimezone();
void	ioSynchronousCheckForEvents();
void	checkHighPriorityTickees(usqLong);
# if ITIMER_HEARTBEAT		/* Hack; allow heartbeat to avoid */
extern int numAsyncTickees; /* prodHighPriorityThread unless necessary */
# endif						/* see platforms/unix/vm/sqUnixHeartbeat.c */
void	ioGetClockLogSizeUsecsIdxMsecsIdx(sqInt*,void**,sqInt*,void**,sqInt*);
void	addIdleUsecs(sqInt);
#endif

/* this function should return the value of the high performance
   counter if there is such a thing on this platform (otherwise return 0) */
sqLong ioHighResClock(void);

/* New filename converting function; used by the interpreterProxy function
  ioFilenamefromStringofLengthresolveAliases. Most platforms can ignore the
  resolveAlias boolean - it seems to only be of use by OSX but is crucial there.
*/
sqInt sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean);

/* Macro to provide default null behaviour for ftruncate - a non-ansi call
   used in FilePlugin.
   Override in sqPlatformSpecific.h for each platform that implements a
   file truncate, or consider replacing the
   ../Cross/plugins/FilePlugin/sqFilePluginBasicPrims.c
   file with a platform specific version as Win32 and RISC OS do.
*/
#define sqFTruncate(filenum, fileoffset) true

/* Macros to support Mac browser plugin without ugly code in Interpreter. */

#define insufficientMemorySpecifiedError()	error("Insufficient memory for this image")
#define insufficientMemoryAvailableError()	error("Failed to allocate memory for the heap")
#define unableToReadImageError()		error("Read failed or premature end of image file")
#define browserPluginReturnIfNeeded()
#define browserPluginInitialiseIfNeeded()

/* Platform-specific header file may redefine earlier definitions and macros. */

#include "sqPlatformSpecific.h"

/* Interpreter entry points. */

/* Disable Intel compiler inlining of error which is used for breakpoints */
#ifdef __INTEL_COMPILER
#   pragma auto_inline(off)
#endif
extern void error(char *s);
#ifdef __INTEL_COMPILER
#   pragma auto_inline(on)
#endif
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
void ioInitThreads();

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

extern sqOSThread getVMOSThread();
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
void  ioProfileStatus(sqInt *running, void **exestartpc, void **exelimitpc,
					  void **vmhst, long *nvmhbin, void **eahst, long *neahbin);
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

sqInt ioGetButtonState(void);
sqInt ioGetKeystroke(void);
sqInt ioMousePoint(void);
sqInt ioPeekKeystroke(void);
/* Note: In an event driven architecture, ioProcessEvents is obsolete.
   It can be implemented as a no-op since the image will check for
   events in regular intervals. */
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
#define EventKeyUp	2

/* Button definitions. */
#define RedButtonBit	4
#define YellowButtonBit	2
#define BlueButtonBit	1

/* Modifier definitions. */
#define ShiftKeyBit	1
#define CtrlKeyBit	2
#define OptionKeyBit	4
#define CommandKeyBit	8

/* generic input event */
typedef struct sqInputEvent
{
  sqIntptr_t type;				/* type of event; either one of EventTypeXXX */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the type of the event */
  sqIntptr_t unused1;
  sqIntptr_t unused2;
  sqIntptr_t unused3;
  sqIntptr_t unused4;
  sqIntptr_t unused5;
  sqIntptr_t windowIndex;		/* SmallInteger used in image to identify a host window structure */
} sqInputEvent;

/* mouse input event */
typedef struct sqMouseEvent
{
  sqIntptr_t type;				/* EventTypeMouse */
  usqIntptr_t timeStamp;	/* time stamp */
  sqIntptr_t x;					/* mouse position x */
  sqIntptr_t y;					/* mouse position y */
  sqIntptr_t buttons;				/* combination of xxxButtonBit */
  sqIntptr_t modifiers;			/* combination of xxxKeyBit */
  sqIntptr_t nrClicks;			/* number of clicks in button downs - was reserved1 */
  sqIntptr_t windowIndex;			/* host window structure */
} sqMouseEvent;

/* keyboard input event */
typedef struct sqKeyboardEvent
{
  sqIntptr_t type;				/* EventTypeKeyboard */
  usqIntptr_t timeStamp;	/* time stamp */
  sqIntptr_t charCode;			/* character code in Mac Roman encoding */
  sqIntptr_t pressCode;			/* press code; any of EventKeyXXX */
  sqIntptr_t modifiers;			/* combination of xxxKeyBit */
  sqIntptr_t utf32Code;			/* UTF-32 unicode value */
  sqIntptr_t reserved1;			/* reserved for future use */
  sqIntptr_t windowIndex;			/* host window structure */
} sqKeyboardEvent;

/* drop files event */
typedef struct sqDragDropFilesEvent
{
  sqIntptr_t type;				/* EventTypeDropFiles */
  usqIntptr_t timeStamp;	/* time stamp */
  sqIntptr_t dragType;			/* one of DragXXX (see below) */
  sqIntptr_t x;					/* mouse position x */
  sqIntptr_t y;					/* mouse position y */
  sqIntptr_t modifiers;			/* combination of xxxKeyBit */
  sqIntptr_t numFiles;			/* number of files in transaction */
  sqIntptr_t windowIndex;			/* host window structure */
} sqDragDropFilesEvent;

#define SQDragEnter	1 /* drag operation from OS entered Squeak window	 */
#define SQDragMove	2 /* drag operation from OS moved within Squeak window */
#define SQDragLeave	3 /* drag operation from OS left Squeak window	 */
#define SQDragDrop	4 /* drag operation dropped contents onto Squeak.      */
#define SQDragRequest	5 /* data request from other app. */

/* menu event */
typedef struct sqMenuEvent
{
  sqIntptr_t type;				/* type of event; EventTypeMenu */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the type  of the event */
  sqIntptr_t menu;				/* platform-dependent to indicate which menu was picked */
  sqIntptr_t menuItem;			/* given a menu having 1 to N items this maps to the menu item number */
  sqIntptr_t reserved1;			/* reserved for future use */
  sqIntptr_t reserved2;			/* reserved for future use */
  sqIntptr_t reserved3;			/* reserved for future use */
  sqIntptr_t windowIndex;			/* host window structure */
} sqMenuEvent;

/* window action event */
typedef struct sqWindowEvent
{
  sqIntptr_t type;				/* type of event;  EventTypeWindow */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the type  of the event */
  sqIntptr_t action;				/* one of WindowEventXXX (see below) */
  sqIntptr_t value1;				/* used for rectangle edges */
  sqIntptr_t value2;				/* used for rectangle edges */
  sqIntptr_t value3;				/* used for rectangle edges */
  sqIntptr_t value4;				/* used for rectangle edges */
  sqIntptr_t windowIndex;			/* host window structure */
} sqWindowEvent;

#define WindowEventMetricChange	1 /* size or position of window changed - value1-4 are left/top/right/bottom values */
#define WindowEventClose	2 /* window close icon pressed */
#define WindowEventIconise	3 /* window iconised or hidden etc */
#define WindowEventActivated	4 /* window made active - some platforms only - do not rely upon this */
#define WindowEventPaint	5 /* window area (in value1-4) needs updating. Some platforms do not need to send this, do not rely on it in image */
#define WindowEventStinks	6 /* this window stinks (just to see if people read this stuff) */

typedef struct sqComplexEvent
{
  sqIntptr_t type;				/* type of event;  EventTypeComplex */
  usqIntptr_t timeStamp;	/* time stamp */
  /* the interpretation of the following fields depend on the type  of the event */
  sqIntptr_t action;		        /* one of ComplexEventXXX (see below) */
  sqIntptr_t objectPointer;		/* used to point to object */
  sqIntptr_t unused1;
  sqIntptr_t unused2;
  sqIntptr_t unused3;
  sqIntptr_t windowIndex;			/* host window structure */
} sqComplexEvent;

#define ComplexEventTypeTouchsDown	1
#define ComplexEventTypeTouchsUp	2
#define ComplexEventTypeTouchsMoved	3
#define ComplexEventTypeTouchsStationary 4
#define ComplexEventTypeTouchsCancelled	5
#define ComplexEventTypeAccelerationData	6
#define ComplexEventTypeLocationData	7
#define ComplexEventTypeApplicationData	8


/* Set an asynchronous input semaphore index for events. */
sqInt ioSetInputSemaphore(sqInt semaIndex);
/* Retrieve the next input event from the OS. */
sqInt ioGetNextEvent(sqInputEvent *evt);

/* Image file and VM path names. */
extern char imageName[];
char *getImageName(void);
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

#include "pharovm/imageAccess.h"

size_t readImageFromFileHeapSizeStartingAt(sqImageFile f, usqInt desiredHeapSize, size_t imageOffset);

/* Clipboard (cut/copy/paste). */
sqInt clipboardSize(void);
sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex);
sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex);


/* Interpreter entry points needed by compiled primitives. */
void *arrayValueOf(sqInt arrayOop);
sqInt checkedIntegerValueOf(sqInt intOop);
void *fetchArrayofObject(sqInt fieldIndex, sqInt objectPointer);
double fetchFloatofObject(sqInt fieldIndex, sqInt objectPointer);
sqInt fetchIntegerofObject(sqInt fieldIndex, sqInt objectPointer);
double floatValueOf(sqInt floatOop);
sqInt pop(sqInt nItems);
sqInt pushInteger(sqInt integerValue);
sqInt sizeOfSTArrayFromCPrimitive(void *cPtr);
sqInt storeIntegerofObjectwithValue(sqInt fieldIndex, sqInt objectPointer, sqInt integerValue);

/* System attributes. */
sqInt attributeSize(sqInt indexNumber);
sqInt getAttributeIntoLength(sqInt indexNumber, sqInt byteArrayIndex, sqInt length);

/*** Pluggable primitive support. ***/

/* NOTE: The following functions are those implemented by sqNamedPrims.c */
void *ioLoadExternalFunctionOfLengthFromModuleOfLength
		(sqInt functionNameIndex, sqInt functionNameLength,
		 sqInt moduleNameIndex, sqInt moduleNameLength);
#if SPURVM
void *ioLoadExternalFunctionOfLengthFromModuleOfLengthAccessorDepthInto
	(sqInt functionNameIndex, sqInt functionNameLength,
	 sqInt moduleNameIndex,   sqInt moduleNameLength, sqInt *accessorDepthPtr);
#endif
sqInt  ioUnloadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength);
void  *ioLoadFunctionFrom(char *functionName, char *pluginName);
sqInt  ioShutdownAllModules(void);
sqInt  ioUnloadModule(char *moduleName);
sqInt  ioUnloadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength);
char  *ioListBuiltinModule(sqInt moduleIndex);
char  *ioListLoadedModule(sqInt moduleIndex);
/* The next two for the FFI, also implemented in sqNamedPrims.c. */
void  *ioLoadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength);
void  *ioLoadSymbolOfLengthFromModule(sqInt functionNameIndex, sqInt functionNameLength, void *moduleHandle);

/* The next three functions must be implemented by sqXYZExternalPrims.c */
/* ioLoadModule:
	Load a module from disk.
	WARNING: this always loads a *new* module. Don't even attempt to find
	a loaded one.
	WARNING: never primitiveFail() within, just return 0
*/
void *ioLoadModule(char *pluginName);

/* ioFindExternalFunctionIn[AccessorDepthInto]:
	Find the function with the given name in the moduleHandle.
	WARNING: never primitiveFail() within, just return 0.
	Note in Spur takes an extra parameter which is defaulted to 0.
*/
#if SPURVM
void *ioFindExternalFunctionInAccessorDepthInto(char *lookupName, void *moduleHandle, sqInt *accessorDepthPtr);
# define ioFindExternalFunctionIn(ln,mh) ioFindExternalFunctionInAccessorDepthInto(ln,mh,0)
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
