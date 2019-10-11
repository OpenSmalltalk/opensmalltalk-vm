/****************************************************************************
*   PROJECT: Mac initialization, misc utility routines
*   FILE:    sqMacMain.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMain.c 1916 2008-09-04 13:07:15Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar  8th, 2002, JMM UI locking for applescript under os-x
*  Mar  17th, 2002, JMM look into sleep wakeup issues under os-9 on some computers.
*  Apr  17th, 2002, JMM Use accessors for VM variables, add os-9 check, plus changes by Alain Fischer <alain.fischer@bluewin.ch> to look for image and fetch VM version under os-x
*  Apr  3rd, 2003, JMM use BROWSERPLUGIN
*  Jun 25th, 2003, JMM optional window title. globals for various user preferences
****************************************************************************/

// These are the comments from the orginal sqMacWindow.c before it was divided into 10 files
//Aug 7th 2000,JMM Added logic for interrupt driven dispatching
//Sept 1st 2000, JMM fix problem with modifier information being passed back incorrectly.
//Sept 1st 2000, JMM use floating point for time versus 64bit math (faster!)
//Sept 1st 2000, JMM watch mouse movement foreground only, ignore when squeak in background.
//Sept 18th 2000, JMM fix to cmpSize 
//Sept 19th 2000, JMM Sept 1st fix to keyboard modifier info broke cmd shift
//Sept 27 2000, JMM fix to documentPath
//Nov 13 2000, JMM logic to read/write image from VM. 
//Nov 22 2000, JMM Bob Arning found a bug with the duplicate mouse event logic (we were altering the event then recording the altered value)
//Nov 30 2000, JMM Use Open Transport clock versus upTime, solves some issues for jitter and it's faster
//Dec 5th 2000, JMM poll 60 times a second... do event polling via checkForInterrupts and drive semaphore
//Dec 6th 2000, JMM added logic to interface with power manger (1997 was there but dropped..., back again for ibooks)
//Jan 14th 2001, KG Did some carbon porting.
//Feb 2nd 2001, JMM V3.0 added zoom window support, full path support
//Feb 2nd 2001, JMM V3.04 do an open window dialog at startup time if no image file
//Feb 14th 2001, JMM V3.06 don't cache image read/writes
//Feb 17th 2001, JMM V3.07 fix OS bug in 7.5.5 on activate event
//Feb 22nd 2001, JMM v3.08 no caps lock
//Mar 9th  2001, JMM v3.10 broken full screen update redaw on cmd-tab via ignoring activate events 3.0.7.
//Mar 15th 2001, JMM v3.10 added minimal vm logic, fix mouse down reporting.
//Mar 23rd 2001, JMM v3.10 start interpreter suspended for plugin to fix race at startup with netscape 4.x
//Apr 4th 2001, JMM  V3.11 fix for carbon get keyboard data eventrecord is broken for nullevents. 
//                         Rework event duplication logic, New menubar show logic, fix position bug on window move restore after full screen 
//Apr 30th 2001, JMM V3.14 pass interpreter version back for get attribute 1004, delay if idle, set mouse down flag only on mouse down in content, and restrict window movement/sizing if in full screen mode
//May 24th 2001, JMM V3.17 add logic to sleep/wait in carbon on excessive idle time, plus change data return on attribute gets
//June 18th 2001, JMM V3.18 fix for cast of version info for CW 6.1
//June 18th 2001, JMM V3.19 fix for saveAsEmbeddedImage. Broken in 3.0 Also added fix for powerpc only cfrg, and rework of security interface for VMMaker via Tim
//Oct 1,2001, JMM V3.1.2  open document support and fix scrap issues, add ext keyboard unlock shift key logic. 
//Dec 19,2001, JMM V3.1.2B6 fix USB on no-usb machines.
//Feb 11th 2002, JMM V3.0.21 fix for UpdateWindow to make printing work!
/*	12/19/2001 JMM Fix for USB on non-usb devices, and fix for ext keyboard use volatile
*	12/27/2001 JMM Added support to load os-x Bundles versus CFM, have broken CFM code too.
*	1/2/2002   JMM Use unix io for image, much faster, cleanup window display and ioshow logic.
*	1/18/2002  JMM Fix os-x memory mapping, new type for squeak file offsets
*	1/27/2002  JMM added logic to get framework bundles 
*	2/04/2002  JMM Rework timer logic, fall back to old style timer, which is pthread based.
*	2/14/2002  JMM fixes for updatewindow logic and drag/drop image with no file type
*	2/25/2002  JMM additions for carbon event managment.
*   3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
*  3.5.1b3 June 7th, 2003 JMM fix up full screen pthread issue.
*  3.6.x  Sept 1st, 2003 JMM per note from Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>  changed 1003 parm to lowercase. 
*  3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
*  3.8.0bx Jul 20th, 2004 JMM multiple window support
*  3.8.7b2 March 19th, 2005 JMM add command line unix interface
*  3.8.9b2 Sept 22nd, 2005 JMM add logic to override Squeak.image name 
*  3.8.10b1 Jan 31st, 2006 JMM convert to unix file names.
*  3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
*  3.8.13b4 Oct 16th, 2006 JMM headless
*  3.8.14b1 Oct  2006, JMM browser rewrite
 3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
 3.8.15b5  Mar 7th, 2007 JMM Add SqueakDebug, SqueakQuitOnQuitAppleEvent 
 3.8.16b3  Mar 21th, 2007 JMM trusted/untrusted directory cleanup, warning msg cleanup
 3.8.17b2  April 26th, 2007 JMM large cursors
*/


#include <objc/objc-runtime.h>

#include "sq.h"
#include "sqAssert.h"
#include "sqMacUIConstants.h"
#include "sqMacMain.h"
#include "sqMacUIMenuBar.h"
#include "sqMacWindow.h"
#include "sqMacTime.h"
#include "sqMacUIAppleEvents.h"
#include "sqMacImageIO.h"
#include "sqMacUIClipBoard.h"
#include "sqMacUnixFileInterface.h"
#include "sqMacUIEvents.h"
#include "sqMacMemory.h"
#include "sqMacEncoding.h"
#include "sqMacUnixCommandLineInterface.h"
#include "sqMacUnixFileInterface.h"
#include "sqaio.h"
#include "sqMacNSPluginUILogic2.h"
#include "sqUnixCharConv.h"
#include "sqSCCSVersion.h"

#include <unistd.h>
#include <pthread.h>
#include <Processes.h>

#if !defined(PATH_MAX)
# include <sys/syslimits.h>
#endif
#if !defined(NOEXECINFO) && defined(HAVE_EXECINFO_H)
# include <execinfo.h>
# define BACKTRACE_DEPTH 64
#endif
#include <signal.h>
#include <sys/ucontext.h>

extern pthread_mutex_t gEventQueueLock,gSleepLock;
extern pthread_cond_t  gSleepLockCondition;

OSErr			gSqueakFileLastError; 
Boolean			gSqueakWindowIsFloating,gSqueakWindowHasTitle=true,
				gSqueakHasQuitWithoutSaving = true,
				gSqueakFloatingWindowGetsFocus=false,
				gSqueakPluginsBuiltInOrLocalOnly=false,
				gSqueakHeadless=false,
				gSqueakQuitOnQuitAppleEvent=false,
				gSqueakExplicitWindowOpenNeeded=false,
				gSqueakVMPathAnswersResources=false;
long			gSqueakMouseMappings[4][4] = {{0},{0}};
long			gSqueakBrowserMouseMappings[4][4] = {{0},{0}};
usqLong         gMaxHeapSize=512*1024*1024;
UInt32			gSqueakWindowType=zoomDocProc,gSqueakWindowAttributes=0;
long			gSqueakUIFlushPrimaryDeferNMilliseconds=20,
				gSqueakUIFlushSecondaryCleanupDelayMilliseconds=20,
				gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds=16,
				gSqueakDebug=0;
char            gSqueakImageName[PATH_MAX] = DEFAULT_IMAGE_NAME;
char            gSqueakUntrustedDirectoryName[PATH_MAX] = "/foobar/tooBar/forSqueak/bogus/";
char            gSqueakTrustedDirectoryName[PATH_MAX] = "/foobar/tooBar/forSqueak/bogus/";
CFStringRef		gSqueakImageNameStringRef;
int				gSqueakBrowserPipes[]= {-1, -1}; 
Boolean			gSqueakBrowserSubProcess = false,
				gSqueakBrowserWasHeadlessButMadeFullScreen=false,
				gSqueakBrowserExitRequested = false;

void cocoInterfaceForTilda(CFStringRef aStringRef, char *buffer,int max_size);
/*** Main ***/

/*** Variables -- globals for access from pluggable primitives ***/
int    argCnt= 0;
char **argVec= 0;
char **envVec= 0;

void printAllStacks(void);
void printCallStack(void);
extern void dumpPrimTraceLog(void);
extern BOOL NSApplicationLoad(void);
char *getVersionInfo(int verbose);


/*** errors ***/

/* Print an error message, possibly a stack trace, do /not/ exit.
 * Allows e.g. writing to a log file and stderr.
 */
static void *printRegisterState(ucontext_t *uap);

static void
reportStackState(char *msg, char *date, int printAll, ucontext_t *uap)
{
#if !defined(NOEXECINFO) && defined(HAVE_EXECINFO_H)
	void *addrs[BACKTRACE_DEPTH+1];
	int depth;
#endif
	/* flag prevents recursive error when trying to print a broken stack */
	static sqInt printingStack = false;

	printf("\n%s%s%s\n\n", msg, date ? " " : "", date ? date : "");
	printf("%s\n%s\n\n", GetAttributeString(0), getVersionInfo(1));

#if !defined(NOEXECINFO) && defined(HAVE_EXECINFO_H)
	printf("C stack backtrace & registers:\n");
	if (uap) {
		addrs[0] = printRegisterState(uap);
		depth = 1 + backtrace(addrs + 1, BACKTRACE_DEPTH);
	}
	else
		depth = backtrace(addrs, BACKTRACE_DEPTH);
# if 0 /* Mac OS's backtrace_symbols_fd prints NULL byte droppings each line */
	fflush(stdout); /* backtrace_symbols_fd uses unbuffered i/o */
	backtrace_symbols_fd(addrs, depth, fileno(stdout));
# else
	{ int i; char **strings;
	  strings = backtrace_symbols(addrs, depth);
	  printf("(%s)\n", strings[0]);
	  for (i = 1; i < depth; i++)
		printf("%s\n", strings[i]);
	}
# endif
#endif

	if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		if (!printingStack) {
#if COGVM
			/* If we're in generated machine code then the only way the stack
			 * dump machinery has of giving us an accurate report is if we set
			 * stackPointer & framePointer to the native stack & frame pointers.
			 */
# if __APPLE__ && __MACH__ && __i386__
	/* see sys/ucontext.h; two different namings */
#	if __GNUC__ && !__INTEL_COMPILER /* icc pretends to be gcc */
			void *fp = (void *)(uap ? uap->uc_mcontext->__ss.__ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->__ss.__esp: 0);
#	else
			void *fp = (void *)(uap ? uap->uc_mcontext->ss.ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->ss.esp: 0);
#	endif
# elif __linux__ && __i386__
			void *fp = (void *)(uap ? uap->uc_mcontext.gregs[REG_EBP]: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext.gregs[REG_ESP]: 0);
# else
#	error need to implement extracting pc from a ucontext_t on this system
# endif
			char *savedSP, *savedFP;

			ifValidWriteBackStackPointersSaveTo(fp,sp,&savedFP,&savedSP);
#endif

			printingStack = true;
			if (printAll) {
				printf("\n\nAll Smalltalk process stacks (active first):\n");
				printAllStacks();
			}
			else {
				printf("\n\nSmalltalk stack dump:\n");
				printCallStack();
			}
			printingStack = false;
#if COGVM
			/* Now restore framePointer and stackPointer via same function */
			ifValidWriteBackStackPointersSaveTo(savedFP,savedSP,0,0);
#endif
		}
	}
	else
		printf("\nCan't dump Smalltalk stack(s). Not in VM thread\n");
#if STACKVM
	printf("\nMost recent primitives\n");
	dumpPrimTraceLog();
# if COGVM
	printf("\n");
	reportMinimumUnusedHeadroom();
# endif
#endif
	printf("\n\t(%s)\n", msg);
	fflush(stdout);
}

/* Attempt to dump the registers to stdout.  Only do so if we know how. */
static void *
printRegisterState(ucontext_t *uap)
{
#if __DARWIN_UNIX03 && __APPLE__ && __MACH__ && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->__ss;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->__eax, regs->__ebx, regs->__ecx, regs->__edx,
			regs->__edi, regs->__edi, regs->__ebp, regs->__esp,
			regs->__eip);
	return (void *)(regs->__eip);
#elif __APPLE__ && __MACH__ && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->ss;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->eax, regs->ebx, regs->ecx, regs->edx,
			regs->edi, regs->edi, regs->ebp, regs->esp,
			regs->eip);
	return (void *)(regs->eip);
#else
	printf("don't know how to derive register state from a ucontext_t on this platform\n");
	return 0;
#endif
}

int blockOnError = 0; /* to allow attaching gdb on fatal error */

static void
block()
{ struct timespec while_away_the_hours;
  char pwd[PATH_MAX+1];

	printf("blocking e.g. to allow attaching debugger\n");
	printf("pid: %d pwd: %s vm:%s\n",
			(int)getpid(), getcwd(pwd,PATH_MAX+1), argVec[0]);
	while (1) {
		while_away_the_hours.tv_sec = 3600;
		nanosleep(&while_away_the_hours, 0);
	}
}

/* Print an error message, possibly a stack trace, and exit. */
/* Disable Intel compiler inlining of error which is used for breakpoints */
#pragma auto_inline(off)
void
error(char *msg)
{
	reportStackState(msg,0,0,0);
	if (blockOnError) block();
	abort();
}
#pragma auto_inline(on)

static char vmLogDirA[PATH_MAX+1];

static void
getCrashDumpFilenameInto(char *buf)
{
	if (vmLogDirA[0]) {
		strcpy(buf,vmLogDirA);
		strcat(buf, "/");
	}
	strcat(buf, "crash.dmp");
}

static void
sigusr1(int sig, siginfo_t *info, void *uap)
{
	int saved_errno = errno;
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[IMAGE_NAME_SIZE+1];

	if (!ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		pthread_kill(getVMOSThread(),sig);
		errno = saved_errno;
		return;
	}

	getCrashDumpFilenameInto(crashdump);
	ctime_r(&now,ctimebuf);
	pushOutputFile(crashdump);
	reportStackState("SIGUSR1", ctimebuf, 1, uap);
	popOutputFile();
	reportStackState("SIGUSR1", ctimebuf, 1, uap);

	errno = saved_errno;
}

static int inFault = 0;

static void
sigsegv(int sig, siginfo_t *info, void *uap)
{
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[IMAGE_NAME_SIZE+1];
	char *fault = sig == SIGSEGV
					? "Segmentation fault"
					: (sig == SIGBUS
						? "Bus error"
						: (sig == SIGILL
							? "Illegal instruction"
							: "Unknown signal"));

	if (!inFault) {
		inFault = 1;
		getCrashDumpFilenameInto(crashdump);
		ctime_r(&now,ctimebuf);
		pushOutputFile(crashdump);
		reportStackState(fault, ctimebuf, 0, uap);
		popOutputFile();
		reportStackState(fault, ctimebuf, 0, uap);
	}
	if (blockOnError) block();
	abort();
}

int main(int argc, char **argv, char **envp);

#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(i486) || defined(__i486) || defined (__i486__) \
			|| defined(intel) || defined(x86) || defined(i86pc) )
  static void fldcw(unsigned int cw)
  {
    __asm__("fldcw %0" :: "m"(cw));
  }
#else
# define fldcw(cw)
#endif

#if defined(__GNUC__) && ( defined(ppc) || defined(__ppc) || defined(__ppc__)  \
			|| defined(POWERPC) || defined(__POWERPC) || defined (__POWERPC__) )
void mtfsfi(unsigned long long fpscr);
void mtfsfi(unsigned long long fpscr)
  {
    __asm__("lfd   f0, %0" :: "m"(fpscr));
    __asm__("mtfsf 0xff, f0");
  }
#else
# define mtfsfi(fpscr)
#endif

int
main(int argc, char **argv, char **envp)
{
	EventRecord theEvent;
	sqImageFile f;
	OSErr err;
	char shortImageName[SHORTIMAGE_NAME_SIZE+1];

	struct sigaction sigusr1_handler_action, sigsegv_handler_action;

#if 0 /* Useful debugging stub?  Dump args to file ~/argvPID. */
  {	char fname[PATH_MAX];
	FILE *f;
	int i;

	sprintf(fname,"%s/argv%d",getenv("HOME"), getpid());
	f = fopen(fname,"w");
	for (i = 0; i < argc; i++)
		fprintf(f,"argv[%d]: %s\n", i, argv[i]);
	fclose(f);
  }
#endif

	/* check the interpreter's size assumptions for basic data types */
	if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
	if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
	if (sizeof(sqLong) != 8) error("This C compiler's long longs are not 64 bits.");
#if 0
	if (sizeof(time_t) != 4) error("This C compiler's time_t's are not 32 bits.");
#endif

	/* Make parameters global for access from pluggable primitives */
	argCnt= argc;
	argVec= argv;
	envVec= envp;

	sigsegv_handler_action.sa_sigaction = sigsegv;
	sigsegv_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
	sigemptyset(&sigsegv_handler_action.sa_mask);
    (void)sigaction(SIGBUS, &sigsegv_handler_action, 0);
    (void)sigaction(SIGILL, &sigsegv_handler_action, 0);
    (void)sigaction(SIGSEGV, &sigsegv_handler_action, 0);

	sigusr1_handler_action.sa_sigaction = sigusr1;
	sigusr1_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
	sigemptyset(&sigusr1_handler_action.sa_mask);
    (void)sigaction(SIGUSR1, &sigusr1_handler_action, 0);

	fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
	mtfsfi(0);		/* disable signals, IEEE mode, round to nearest */

	LoadScrap();
	SetUpClipboard();
	fetchPreferences();

	SetVMPathFromApplicationDirectory();

#if 1
	unixArgcInterface(argCnt,argVec,envVec);

	if (!gSqueakHeadless) {
		/* install apple event handlers and wait for open event */
		InstallAppleEventHandlers();
		while (ShortImageNameIsEmpty()) {
			GetNextEvent(everyEvent, &theEvent);
			if (theEvent.what == kHighLevelEvent) {
				AEProcessAppleEvent(&theEvent);
			}
		}
	}
#else
	/* install apple event handlers and wait for open event */
	InstallAppleEventHandlers();
	while (ShortImageNameIsEmpty()) {
		GetNextEvent(everyEvent, &theEvent);
		if (theEvent.what == kHighLevelEvent) {
			AEProcessAppleEvent(&theEvent);
		}
	}

	unixArgcInterface(argCnt,argVec,envVec);
#endif

	if (!gSqueakHeadless) {
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		ProcessInfoRec info;
		info.processName = NULL;
#if _LP64
		info.processAppRef = NULL;
#else
		info.processAppSpec = NULL;
#endif
		info.processInfoLength = sizeof(ProcessInfoRec);
		GetProcessInformation(&psn,&info);
		if ((info.processMode & modeOnlyBackground) && TransformProcessType != NULL) {
			OSStatus returnCode = TransformProcessType(& psn, kProcessTransformToForegroundApplication);
#pragma unused(returnCode)
			SetFrontProcess(&psn);
		}
//		InitCursor();	large cursor support
	}

	getShortImageNameWithEncoding(shortImageName,gCurrentVMEncoding);
    if (gSqueakHeadless && ImageNameIsEmpty()) 
		exit(-42);

	if (ImageNameIsEmpty()) {
            CFBundleRef mainBundle;
            CFURLRef imageURL;

            mainBundle = CFBundleGetMainBundle();            
            imageURL = CFBundleCopyResourceURL (mainBundle, gSqueakImageNameStringRef, NULL, NULL);
            if (imageURL != NULL) {
				CFStringRef imagePath;

                imagePath = CFURLCopyFileSystemPath (imageURL, kCFURLPOSIXPathStyle);

				SetImageNameViaCFString(imagePath);
                CFRelease(imageURL);
                CFRelease(imagePath);
            } else {
				extern void resolveWhatTheImageNameIs(char *string);
				char	afterCheckForTilda[PATH_MAX];

				cocoInterfaceForTilda(gSqueakImageNameStringRef, afterCheckForTilda,PATH_MAX);
				resolveWhatTheImageNameIs(afterCheckForTilda);
			}
	}

	/* Set the directory into which to write the crash.dmp file. */
	/* By default this is the image file's directory (strange but true). */
#if CRASH_DUMP_IN_CWD
	getcwd(vmLogDirA,PATH_MAX);
#else
	strcpy(vmLogDirA,getImageName());
	if (strrchr(vmLogDirA,'/'))
		*strrchr(vmLogDirA,'/') = 0;
	else
		getcwd(vmLogDirA,PATH_MAX);
#endif

    SetUpTimers();

	/* read the image file and allocate memory for Squeak heap */
	f = sqImageFileOpen(getImageName(), "rb");
    if (gSqueakHeadless && f == NULL) 
			exit(-43);
	while (f == NULL) {
	    //Failure attempt to ask the user to find the image file
		char pathName[DOCUMENT_NAME_SIZE+1];
		err = squeakFindImage(pathName);
		if (err) 
			ioExit();
		getLastPathComponentInCurrentEncoding(pathName,shortImageName,gCurrentVMEncoding);
		SetShortImageNameViaString(shortImageName,gCurrentVMEncoding);
		SetImageNameViaString(pathName,gCurrentVMEncoding);
		f = sqImageFileOpen(getImageName(), "rb");
 	}

#if SPURVM
	readImageFromFileHeapSizeStartingAt(f, 0, 0);
#else
	readImageFromFileHeapSizeStartingAt(f, sqGetAvailableMemory(), 0);
#endif
	sqImageFileClose(f);

	if (!gSqueakHeadless) {
		SetUpMenus();
	}
	if (!gSqueakHeadless || (gSqueakHeadless && gSqueakBrowserSubProcess)) {
		SetUpPixmap();
	}

    aioInit();
	ioInitThreads();
    pthread_mutex_init(&gEventQueueLock, NULL);
	if (gSqueakBrowserSubProcess) {
		extern CGContextRef SharedBrowserBitMapContextRef;
		setupPipes();
		while (SharedBrowserBitMapContextRef == NULL)
			aioSleepForUsecs(100*1000);
	}
	NSApplicationLoad();	//	Needed for Carbon based applications which call into Cocoa
	RunApplicationEventLoopWithSqueak();
    return 0;
}

sqInt ioExit(void) { return ioExitWithErrorCode(0); }

sqInt
ioExitWithErrorCode(int ec)
{
	extern void printPhaseTime(int);
#if COGVM
extern sqInt reportStackHeadroom;
	if (reportStackHeadroom)
		reportMinimumUnusedHeadroom();
#endif
	printPhaseTime(3);
    UnloadScrap();
    ioShutdownAllModules();
	if (!gSqueakHeadless || gSqueakBrowserWasHeadlessButMadeFullScreen) 
		MenuBarRestore();
#if !__MACH__
	sqMacMemoryFree();  // needed on old Mac OS but not on unices
#endif
    exit(ec);
	return ec;
}

sqInt
ioDisablePowerManager(sqInt disableIfNonZero) {
	#pragma unused(disableIfNonZero)
	return 0;
}

/*** I/O Primitives ***/

sqInt
ioBeep(void) {
	SysBeep(1000);
	return 0;
}

void SqueakTerminate() {
	UnloadScrap();
	ioShutdownAllModules();
	sqMacMemoryFree();
}

sqInt
ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth, double hScale, double vScale, sqInt landscapeFlag) {
	/* experimental: print a form with the given bitmap, width, height, and depth at
	   the given horizontal and vertical scales in the given orientation
           However John Mcintosh has introduced a printjob class and plugin to replace this primitive */
#pragma unused( bitsAddr,  width,  height,  depth,  hScale,  vScale,  landscapeFlag)
	return true;
}

/*** System Attributes ***/

/* Andreas' stubs */
char* ioGetLogDirectory(void) { return ""; };

sqInt
ioSetLogDirectoryOfSize(void *lblIndex, sqInt sz)
{
	if (sz >= PATH_MAX)
		return 0;
	strncpy(vmLogDirA, lblIndex, sz);
	vmLogDirA[sz] = 0;
	return 1;
}


char * GetAttributeString(int id) {
	/* This is a hook for getting various status strings back from
	   the OS. In particular, it allows Squeak to be passed arguments
	   such as the name of a file to be processed. Command line options
	   are reported this way as well, on platforms that support them.
	*/

	// id #0 should return the full name of VM
	if (id == 0) {
		static char pathToGiveToSqueak[PATH_MAX];
			ux2sqPath(argVec[0], strlen(argVec[0]), pathToGiveToSqueak, VMPATH_SIZE,1);	
            return pathToGiveToSqueak;
        }
	/* Note: 1.3x images will try to read the image as a document because they
	   expect attribute #1 to be the document name. A 1.3x image can be patched
	   using a VM of 2.6 or earlier. */
	if (id == 1) {
            static char path[IMAGE_NAME_SIZE + 1];
            getImageNameWithEncoding(path,gCurrentVMEncoding);
            return path;
        }

	if (id == 1001) return "Mac OS";
	if (id == 1002) {
		long myattr;
		static char data[32];

		Gestalt(gestaltSystemVersion, &myattr);
		sprintf(data,"%X",(unsigned int) myattr);
		return data;
	}
	if (id == 1003) {
		long myattr;

		Gestalt(gestaltSysArchitecture, &myattr);
		if (myattr == gestalt68k) 
			return "68K";
		if (myattr == gestaltPowerPC) 
			return "powerpc";
		if (myattr == gestaltIntel) 
			return "intel";
	}

   if (id == 1004) {
            CFBundleRef mainBundle;
            CFStringRef versionString;
            static char data[255];
            mainBundle = CFBundleGetMainBundle ();
            versionString = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleShortVersionString"));
            bzero(data,255);
            strcat(data,interpreterVersion);
			if (versionString) {
				strcat(data," ");
				CFStringGetCString (versionString, data+strlen(data), 255-strlen(data), gCurrentVMEncoding);
			}
            return data;            
        }

   if (id == 1005)
		return "Aqua";

	/* vm build string */

    if (id == 1006) {
		extern char vmBuildString[];
		return vmBuildString;
    }
#if STACKVM
	if (id == 1007) { /* interpreter build info */
		extern char *__interpBuildInfo;
		return __interpBuildInfo;
	}
# if COGVM
	if (id == 1008) { /* cogit build info */
		extern char *__cogitBuildInfo;
		return __cogitBuildInfo;
	}
# endif
#endif

	  if (id == 1009) /* source tree version info */
		return sourceVersionString(' ');

// 		return "Mac Carbon 3.8.18b4 29-May-08 >02DA4BFD-4050-4372-8DBB-9582DA7D0218<";
// 		return "Mac Carbon 3.8.18b3 10-Apr-08 >DC0EAF5D-C46C-479D-B2A3-DBD4A2DF95A8<";
//		return "Mac Carbon 3.8.18b2 17-Aug-07 >F439DEFF-4327-403D-969B-78695EE835DB<";
// 		return "Mac Carbon 3.8.18b1 9-Jun-07 >4C61BDDD-B2AA-4C71-B20D-5758597201EF<";
// 		return "Mac Carbon 3.8.17b5 16-May-07 >BBAC71BE-EF68-4994-8E57-D641A936733F<";
// 		return "Mac Carbon 3.8.17b5 1-May-07 >B389476B-E7F3-4E6A-A8B6-EAE7B39B0EEA<";
// 		return "Mac Carbon 3.8.17b4 27-Apr-07 >3636308B-25D4-4CBB-A515-F3ECC3CEEA5E<";
// 		return "Mac Carbon 3.8.17b3 26-Apr-07 >BBB5CDFC-E9BA-48AC-881E-464EE9718935<";
// 		return "Mac Carbon 3.8.17b2 26-Apr-07 >C4425002-5C1A-4801-A7EC-EBB15025290E<";
// 		return "Mac Carbon 3.8.17b1 25-Apr-07 >9FEB946B-22B5-478C-82DD-776FD6D4E3D6<";
//		return "Mac Carbon 3.8.16b6 17-Apr-07 >D12C988F-2395-413F-9BA2-FC4F27858E06<";
// 		return "Mac Carbon 3.8.16b5 29-Mar-07 >4ACC5390-27F6-40D4-A85A-886C7DF0A591<";
// 		return "Mac Carbon 3.8.16b4 22-Mar-07 >A74B40BA-9CB2-4E3E-A9DA-FB0002315FE6<";
// 		return "Mac Carbon 3.8.16b3 20-Mar-07 >3ABB8EA0-DA9D-47FD-BD1B-6B0A2CB05EE6<";
//		return "Mac Carbon 3.8.16b2 19-Mar-07 >3F52787C-BDE4-42E2-B72D-3CC68F8EE9C1<";
// 		return "Mac Carbon 3.8.16b1 16-Mar-07 >B7FBAF59-7235-44A3-9E3E-173C619EE214<";
// 		return "Mac Carbon 3.8.15b8 13-Mar-07 >6C3CEECE-17C9-488F-B9A0-8CCF48A19352<";
// 		return "Mac Carbon 3.8.15b7 13-Mar-07 >3E759905-E8C5-41EA-95B0-8A3B71C80C97<";
// 		return "Mac Carbon 3.8.15b6 11-Mar-07 >E02C430E-69FD-4AC5-8740-70D3A365A5CC<";
// 		return "Mac Carbon 3.8.15b5 10-Mar-07 >9E3E99A8-A5BD-4360-B425-43380C6057C9<";
// 		return "Mac Carbon 3.8.15b4 26-Feb-07 >639DEC8A-D541-4AF1-8DFF-40D02C177C51<";
//		return "Mac Carbon 3.8.15b3 19-Feb-07 >15CEBDA8-05ED-4CCD-86C4-E737B2E33A64<";
 //		return "Mac Carbon 3.8.15b2X 09-Feb-07 >D0AA85C3-05E7-4709-B8F4-174DB6F1ACDB<";
 //		return "Mac Carbon 3.8.15b2 27-Jan-07 >02EF6EF4-41CE-46DF-8ADF-E4D2EBBD542C<";
 //		return "Mac Carbon 3.8.15b1 22-Jan-07 >4AE66794-B628-44CF-BAA3-1BF3E916054D<";

 	if (id == 1201) return "255";

	if (id == 1202) {
		static char data[32];

		sprintf(data,"%i",gSqueakFileLastError);
		return data;
	}

	if (id < 0 || (id >= 2 && id <= 1000))  {
		char *results;
		results = unixArgcInterfaceGetParm(id);
		if (results) 
			return results;
	}

	/* attribute undefined by this platform */
	success(false);
	return "";
}

sqInt
attributeSize(sqInt id) { return strlen(GetAttributeString(id)); }

sqInt
getAttributeIntoLength(sqInt id, sqInt byteArrayIndex, sqInt length) {
	char *srcPtr, *dstPtr, *end;
	int charsToMove;

	srcPtr = GetAttributeString(id);
	charsToMove = strlen(srcPtr);
	if (charsToMove > length) {
		charsToMove = length;
	}

	dstPtr = (char *) byteArrayIndex;
	end = srcPtr + charsToMove;
	while (srcPtr < end) {
		*dstPtr++ = *srcPtr++;
	}
	return charsToMove;
}


void
fetchPreferences() {
    CFBundleRef  myBundle;
    CFDictionaryRef myDictionary;
    CFNumberRef SqueakWindowType,
				SqueakMaxHeapSizeType,
				SqueakUIFlushPrimaryDeferNMilliseconds,
				SqueakUIFlushSecondaryCleanupDelayMilliseconds,
				SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds,
				SqueakDebug;
    CFBooleanRef SqueakWindowHasTitleType,
				SqueakFloatingWindowGetsFocusType,
				SqueakPluginsBuiltInOrLocalOnly,
				SqueakQuitOnQuitAppleEvent,
				SqueakExplicitWindowOpenNeeded,
				SqueakVMPathAnswersResources;
    CFBooleanRef SqueakHasQuitWithoutSaving;
	CFNumberRef SqueakMouseMappings[4][4] = {{0},{0}};
	CFNumberRef SqueakBrowserMouseMappings[4][4] = {{0},{0}};
    CFDataRef 	SqueakWindowAttributeType;    
    CFStringRef	SqueakVMEncodingType,
				SqueakUnTrustedDirectoryTypeRef,
				SqueakTrustedDirectoryTypeRef;

    char        encoding[256];
    long		i,j;

    myBundle = CFBundleGetMainBundle();
    myDictionary = CFBundleGetInfoDictionary(myBundle);

    SqueakWindowType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowType"));
    SqueakDebug = CFDictionaryGetValue(myDictionary, CFSTR("SqueakDebug"));
    SqueakQuitOnQuitAppleEvent = CFDictionaryGetValue(myDictionary, CFSTR("SqueakQuitOnQuitAppleEvent"));
    SqueakWindowAttributeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowAttribute"));
    SqueakWindowHasTitleType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowHasTitle"));
    SqueakFloatingWindowGetsFocusType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakFloatingWindowGetsFocus"));
    SqueakVMPathAnswersResources = CFDictionaryGetValue(myDictionary, CFSTR("SqueakVMPathAnswersResources"));
    SqueakMaxHeapSizeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMaxHeapSize"));
    SqueakVMEncodingType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakEncodingType"));
    SqueakUnTrustedDirectoryTypeRef  = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUnTrustedDirectory"));
    SqueakTrustedDirectoryTypeRef  = CFDictionaryGetValue(myDictionary, CFSTR("SqueakTrustedDirectory"));
	SqueakPluginsBuiltInOrLocalOnly = CFDictionaryGetValue(myDictionary, CFSTR("SqueakPluginsBuiltInOrLocalOnly"));
	SqueakExplicitWindowOpenNeeded = CFDictionaryGetValue(myDictionary, CFSTR("SqueakExplicitWindowOpenNeeded"));
    gSqueakImageNameStringRef = CFDictionaryGetValue(myDictionary, CFSTR("SqueakImageName"));
    SqueakUIFlushPrimaryDeferNMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushPrimaryDeferNMilliseconds"));
    SqueakUIFlushSecondaryCleanupDelayMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushSecondaryCleanupDelayMilliseconds"));
    SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds"));

    SqueakHasQuitWithoutSaving = CFDictionaryGetValue(myDictionary, CFSTR("SqueakHasQuitWithoutSaving"));

    SqueakMouseMappings[0][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseNoneButton1"));
    SqueakMouseMappings[0][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseNoneButton2"));
    SqueakMouseMappings[0][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseNoneButton3"));
    SqueakMouseMappings[1][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseCmdButton1"));
    SqueakMouseMappings[1][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseCmdButton2"));
    SqueakMouseMappings[1][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseCmdButton3"));
    SqueakMouseMappings[2][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseOptionButton1"));
    SqueakMouseMappings[2][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseOptionButton2"));
    SqueakMouseMappings[2][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseOptionButton3"));
    SqueakMouseMappings[3][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseControlButton1"));
    SqueakMouseMappings[3][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseControlButton2"));
    SqueakMouseMappings[3][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseControlButton3"));
    SqueakBrowserMouseMappings[0][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseNoneButton1"));
    SqueakBrowserMouseMappings[0][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseNoneButton2"));
    SqueakBrowserMouseMappings[0][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseNoneButton3"));
    SqueakBrowserMouseMappings[1][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseCmdButton1"));
    SqueakBrowserMouseMappings[1][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseCmdButton2"));
    SqueakBrowserMouseMappings[1][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseCmdButton3"));
    SqueakBrowserMouseMappings[2][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseOptionButton1"));
    SqueakBrowserMouseMappings[2][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseOptionButton2"));
    SqueakBrowserMouseMappings[2][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseOptionButton3"));
    SqueakBrowserMouseMappings[3][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseControlButton1"));
    SqueakBrowserMouseMappings[3][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseControlButton2"));
    SqueakBrowserMouseMappings[3][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseControlButton3"));
#if STACKVM
  { CFNumberRef nStackPagesPref;
    nStackPagesPref = CFDictionaryGetValue(myDictionary, CFSTR("SqueakNumStackPages"));
    if (nStackPagesPref) {
		extern sqInt desiredNumStackPages;
        CFNumberGetValue(nStackPagesPref,kCFNumberLongType,(sqInt *)&desiredNumStackPages);
	}
  }
  { CFNumberRef nEdenBytesPref;
    nEdenBytesPref = CFDictionaryGetValue(myDictionary, CFSTR("SqueakEdenBytes"));
    if (nEdenBytesPref) {
		extern sqInt desiredEdenBytes;
        CFNumberGetValue(nEdenBytesPref,kCFNumberLongType,(sqInt *)&desiredEdenBytes);
	}
  }
#endif /* STACKVM */

    if (SqueakVMEncodingType) 
        CFStringGetCString (SqueakVMEncodingType, encoding, 256, kCFStringEncodingMacRoman);
    else
        *encoding = 0x00;

    setEncodingType(encoding);

    if (SqueakHasQuitWithoutSaving)
        gSqueakHasQuitWithoutSaving = CFBooleanGetValue(SqueakHasQuitWithoutSaving);

    if (gSqueakImageNameStringRef) 
        CFStringGetCString (gSqueakImageNameStringRef, gSqueakImageName, IMAGE_NAME_SIZE+1, kCFStringEncodingMacRoman);

	if (SqueakUnTrustedDirectoryTypeRef) {

		cocoInterfaceForTilda(SqueakUnTrustedDirectoryTypeRef, gSqueakUntrustedDirectoryName,PATH_MAX);
	}

	if (SqueakTrustedDirectoryTypeRef) {

		cocoInterfaceForTilda(SqueakTrustedDirectoryTypeRef, gSqueakTrustedDirectoryName,PATH_MAX);
	}

    if (SqueakWindowType) 
        CFNumberGetValue(SqueakWindowType,kCFNumberLongType,&gSqueakWindowType);
    else
        gSqueakWindowType = kDocumentWindowClass;

    gSqueakWindowIsFloating = gSqueakWindowType == kUtilityWindowClass;

    if (SqueakWindowAttributeType && CFDataGetLength(SqueakWindowAttributeType) == 4) {
            const UInt8 *where;
            where = CFDataGetBytePtr(SqueakWindowAttributeType);
            memmove(&gSqueakWindowAttributes,where,4);
			gSqueakWindowAttributes = CFSwapInt32BigToHost(gSqueakWindowAttributes);
    } else {
        gSqueakWindowAttributes = kWindowStandardDocumentAttributes
            +kWindowStandardHandlerAttribute
            +kWindowNoConstrainAttribute;
    }

    if (SqueakPluginsBuiltInOrLocalOnly) 
        gSqueakPluginsBuiltInOrLocalOnly = CFBooleanGetValue(SqueakPluginsBuiltInOrLocalOnly);
    else 
        gSqueakPluginsBuiltInOrLocalOnly = false;

    if (SqueakExplicitWindowOpenNeeded) 
        gSqueakExplicitWindowOpenNeeded = CFBooleanGetValue(SqueakExplicitWindowOpenNeeded);
    else 
        gSqueakExplicitWindowOpenNeeded = false;

    if (SqueakFloatingWindowGetsFocusType) 
        gSqueakFloatingWindowGetsFocus = CFBooleanGetValue(SqueakFloatingWindowGetsFocusType);
    else
        gSqueakFloatingWindowGetsFocus = false;

    if (SqueakVMPathAnswersResources) 
        gSqueakVMPathAnswersResources = CFBooleanGetValue(SqueakVMPathAnswersResources);
    else
        gSqueakVMPathAnswersResources = false;

    if (SqueakWindowHasTitleType) 
        gSqueakWindowHasTitle = CFBooleanGetValue(SqueakWindowHasTitleType);
    else 
        gSqueakWindowHasTitle = true;

    for(i=0;i<4;i++)
		for(j=1;j<4;j++)
			if (SqueakMouseMappings[i][j]) {
				CFNumberGetValue(SqueakMouseMappings[i][j],kCFNumberLongType,(long *) &gSqueakMouseMappings[i][j]);
				if (gSqueakMouseMappings[i][j] < 0 || gSqueakMouseMappings[i][j] > 3)
					gSqueakMouseMappings[i][j] = 0;
				}

    for(i=0;i<4;i++)
		for(j=1;j<4;j++)
			if (SqueakBrowserMouseMappings[i][j]) {
				CFNumberGetValue(SqueakBrowserMouseMappings[i][j],kCFNumberLongType,(long *) &gSqueakBrowserMouseMappings[i][j]);
				if (gSqueakBrowserMouseMappings[i][j] < 0 || gSqueakBrowserMouseMappings[i][j] > 3)
					gSqueakBrowserMouseMappings[i][j] = 0;
				}
    if (SqueakMaxHeapSizeType)
        CFNumberGetValue(SqueakMaxHeapSizeType,kCFNumberLongLongType,(sqInt *) &gMaxHeapSize);

	if (SqueakUIFlushPrimaryDeferNMilliseconds)
        CFNumberGetValue(SqueakUIFlushPrimaryDeferNMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushPrimaryDeferNMilliseconds);

	if (SqueakUIFlushSecondaryCleanupDelayMilliseconds)
        CFNumberGetValue(SqueakUIFlushSecondaryCleanupDelayMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushSecondaryCleanupDelayMilliseconds);

	if (SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds)
        CFNumberGetValue(SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds);

	if (SqueakDebug) 
        CFNumberGetValue(SqueakDebug,kCFNumberLongType,&gSqueakDebug);

	if (SqueakQuitOnQuitAppleEvent) 
        gSqueakQuitOnQuitAppleEvent = CFBooleanGetValue(SqueakQuitOnQuitAppleEvent);
    else
        gSqueakQuitOnQuitAppleEvent = false;
}

void cocoInterfaceForTilda(CFStringRef aStringRef, char *buffer,int max_size) {
   extern SEL NSSelectorFromString(CFStringRef thing);
   id  autopoolClass = objc_getClass("NSAutoreleasePool");
   id  autopool;

	CFStringRef checkFortilda, selectorRef = CFSTR("stringByExpandingTildeInPath"), 
		releaseRef = CFSTR("release"),
		allocRef = CFSTR("alloc"), 
		initRef = CFSTR("init");
	SEL selector		=  NSSelectorFromString(selectorRef);
	SEL selectorRelease =  NSSelectorFromString(releaseRef);
	SEL selectoralloc	=  NSSelectorFromString(allocRef);
	SEL selectorInit	=  NSSelectorFromString(initRef);

	autopool = objc_msgSend(autopoolClass, selectoralloc);
	autopool = objc_msgSend(autopool, selectorInit);
	checkFortilda=(CFStringRef)objc_msgSend((id)aStringRef,selector);
	CFStringGetCString (checkFortilda, buffer, max_size, gCurrentVMEncoding);
	autopool = objc_msgSend(autopool, selectorRelease);

}

char *
getVersionInfo(int verbose)
{
#if STACKVM
  extern char *__interpBuildInfo;
# define INTERP_BUILD __interpBuildInfo
# if COGVM
  extern char *__cogitBuildInfo;
# endif
#else
# define INTERP_BUILD interpreterVersion
#endif
  extern char vmBuildString[];
  CFStringRef versionString;
  char *info= (char *)malloc(4096);
  info[0]= '\0';

#if SPURVM
# if BytesPerOop == 8
#	define ObjectMemory " Spur 64-bit"
# else
#	define ObjectMemory " Spur"
# endif
#else
# define ObjectMemory
#endif
#if defined(NDEBUG)
# define BuildVariant "Production" ObjectMemory
#elif DEBUGVM
# define BuildVariant "Debug" ObjectMemory
# else
# define BuildVariant "Assert" ObjectMemory
#endif

  if (verbose)
    sprintf(info+strlen(info), IMAGE_DIALECT_NAME " VM version: ");
  sprintf(info+strlen(info), "%s ", VM_VERSION);
  if ((versionString = CFBundleGetValueForInfoDictionaryKey(
						CFBundleGetMainBundle(),
						CFSTR("CFBundleVersion"))))
    CFStringGetCString(versionString, info+strlen(info), 4095-strlen(info), gCurrentVMEncoding);
  sprintf(info+strlen(info), " %s [" BuildVariant " VM]\n", vmBuildString);
  if (verbose)
    sprintf(info+strlen(info), "Built from: ");
  sprintf(info+strlen(info), "%s\n", INTERP_BUILD);
#if COGVM
  if (verbose)
    sprintf(info+strlen(info), "With: ");
  sprintf(info+strlen(info), "%s\n", GetAttributeString(1008)); /* __cogitBuildInfo */
#endif
  if (verbose)
    sprintf(info+strlen(info), "Revision: ");
  sprintf(info+strlen(info), "%s\n", sourceVersionString('\n'));
  return info;
}
#if COGVM
/*
 * Support code for Cog.
 * a) Answer whether the C frame pointer is in use, for capture of the C stack
 *    pointers.
 * b) answer the amount of stack room to ensure in a Cog stack page, including
 *    the size of the redzone, if any.
 */
# if defined(i386) || defined(__i386) || defined(__i386__)
int
isCFramePointerInUse(usqIntptr_t *cFrmPtrPtr, usqIntptr_t *cStkPtrPtr)
{
	extern void (*ceCaptureCStackPointers)(void);
	usqIntptr_t currentCSP = *cStkPtrPtr;

	ceCaptureCStackPointers();
	assert(*cStkPtrPtr < currentCSP);
	return *cFrmPtrPtr >= *cStkPtrPtr && *cFrmPtrPtr <= currentCSP;
}
# else
#	error please provide a deifnition of isCFramePointerInUse for this platform
# endif /* defined(i386) et al */

/* Answer an approximation of the size of the redzone (if any).  Do so by
 * sending a signal to the process and computing the difference between the
 * stack pointer in the signal handler and that in the caller. Assumes stacks
 * descend.
 */

#if !defined(min)
# define min(x,y) (((x)>(y))?(y):(x))
#endif
static char * volatile p = 0;

static void
sighandler(int sig) { p = (char *)&sig; }

static int
getRedzoneSize()
{
	struct sigaction handler_action, old;
	handler_action.sa_sigaction = sighandler;
	handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
	sigemptyset(&handler_action.sa_mask);
	(void)sigaction(SIGPROF, &handler_action, &old);

	do kill(getpid(),SIGPROF); while (!p);
	(void)sigaction(SIGPROF, &old, 0);
	return (char *)min(&old,&handler_action) - sizeof(struct sigaction) - p;
}

sqInt reportStackHeadroom;
static int stackPageHeadroom;

/* Answer the redzone size plus space for any signal handlers to run in.
 * N.B. Space for signal handers may include space for the dynamic linker to
 * run in since signal handlers may reference other functions, and linking may
 * be lazy.  The reportheadroom switch can be used to check empirically that
 * there is sufficient headroom.  At least on Mac OS X we see no large stack
 * usage that would indicate e.g. dynamic linking in signal handlers.
 * So answer only the redzone size and likely get small (2048 byte) pages.
 */
int
osCogStackPageHeadroom()
{
	if (!stackPageHeadroom)
		stackPageHeadroom = getRedzoneSize();
	return stackPageHeadroom;
}
#endif /* COGVM */
