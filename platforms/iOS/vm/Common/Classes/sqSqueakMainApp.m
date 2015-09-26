/*
 *  sqSqueakMainApp.m
 *  
 *
 *  Created by John M McIntosh on 5/15/08.
 *
 */
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *   Small parts of this code is 
 *   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
"This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
and its contributors", in the same place and form as other third-party acknowledgments. 
Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
such third-party acknowledgments.
*/
//

#import "sqSqueakAppDelegate.h"
#import "sq.h"
#import "sqSqueakMainApp.h"
#import <limits.h>
#import "sqPlatformSpecific.h"

#if COGVM
#import "sqSCCSVersion.h"
#else
#import "sqMacV2Memory.h"
#endif

#if !defined(NOEXECINFO)
# include <execinfo.h>
# define BACKTRACE_DEPTH 64
#endif


#warning what about these guyes?
/*** Variables -- globals for access from pluggable primitives ***/
EXPORT(int)		argCnt= 0;
EXPORT(char**)	argVec= 0;
EXPORT(char**)	envVec= 0;

extern sqSqueakAppDelegate *gDelegateApp;

BOOL			gQuitNowRightNow=NO;
BOOL            gSqueakHeadless=NO;
int				gSqueakUseFileMappedMMAP=0;
char            gSqueakUntrustedDirectoryName[PATH_MAX];
char            gSqueakTrustedDirectoryName[PATH_MAX];

extern sqInt printAllStacks(void);
extern sqInt printCallStack(void);
extern void dumpPrimTraceLog(void);
extern BOOL NSApplicationLoad(void);

/* Print an error message, possibly a stack trace, and exit. */
/* Disable Intel compiler inlining of error which is used for breakpoints */
#pragma auto_inline off
#if COGVM || STACKVM
void
error(char *msg)
{
	/* flag prevents recursive error when trying to print a broken stack */
	static sqInt printingStack = false;
	
	printf("\n%s\n\n", msg);
	
	if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		if (!printingStack) {
			printingStack = true;
			printf("\n\nSmalltalk stack dump:\n");
			printCallStack();
		}
	}
	else
		printf("\nCan't dump Smalltalk stack. Not in VM thread\n");
	printf("\nMost recent primitives\n");
#if COGVM
    dumpPrimTraceLog();
#endif
	abort();
}
#pragma auto_inline on

/*
 * Signal handlers
 *
 */

/* Print an error message, possibly a stack trace, do /not/ exit.
 * Allows e.g. writing to a log file and stderr.
 */
static void
reportStackState(char *msg, char *date, int printAll, ucontext_t *uap)
{
#if !defined(NOEXECINFO)
	void *addrs[BACKTRACE_DEPTH];
	int depth;
#endif
	/* flag prevents recursive error when trying to print a broken stack */
	static sqInt printingStack = false;
    
	printf("\n%s%s%s\n\n", msg, date ? " " : "", date ? date : "");
#if COGVM
    printf("%s\n\n", sourceVersionString('\n'));
#endif
    
#if !defined(NOEXECINFO)
	printf("C stack backtrace:\n");
	fflush(stdout); /* backtrace_symbols_fd uses unbuffered i/o */
	depth = backtrace(addrs, BACKTRACE_DEPTH);
	backtrace_symbols_fd(addrs, depth, fileno(stdout));
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
#endif
	printf("\n\t(%s)\n", msg);
	fflush(stdout);
}

static void
getCrashDumpFilenameInto(char *buf)
{
    char *slash;
    
    strcpy(buf,imageName);
    slash = strrchr(buf,'/');
    strcpy(slash ? slash + 1 : buf, "crash.dmp");
}

void
sigusr1(int sig, siginfo_t *info, void *uap)
{
	int saved_errno = errno;
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[imageNameSize()+1];
	unsigned long pc;
    
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

void
sigsegv(int sig, siginfo_t *info, void *uap)
{
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[imageNameSize()+1];
    
	getCrashDumpFilenameInto(crashdump);
	ctime_r(&now,ctimebuf);
	pushOutputFile(crashdump);
	reportStackState("Segmentation fault", ctimebuf, 0, uap);
	popOutputFile();
	reportStackState("Segmentation fault", ctimebuf, 0, uap);
	abort();
}
#else

void sigsegv(int sig, siginfo_t *info, void *uap)
{
    
    /* error("Segmentation fault"); */
    static int printingStack= 0;
    
    printf("\nSegmentation fault\n\ns");
    if (!printingStack)
    {
        printingStack= 1;
        printAllStacks();
    }
    abort();
}
#endif

/*
 * End of signal handlers
 *
 */

void attachToSignals() {
#if COGVM
	struct sigaction sigusr1_handler_action, sigsegv_handler_action;
        
    sigsegv_handler_action.sa_sigaction = sigsegv;
    sigsegv_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&sigsegv_handler_action.sa_mask);
    (void)sigaction(SIGSEGV, &sigsegv_handler_action, 0);
        
    sigusr1_handler_action.sa_sigaction = sigusr1;
    sigusr1_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&sigusr1_handler_action.sa_mask);
    (void)sigaction(SIGUSR1, &sigusr1_handler_action, 0);
#endif
}

sqInt ioExit(void) {
	//API Documented
 	[gDelegateApp.squeakApplication ioExit];
 	return 0;
}

sqInt ioExitWithErrorCode(int ec) {
	//API Documented
 	[gDelegateApp.squeakApplication ioExitWithErrorCode: ec];
 	return 0;
}

sqInt ioDisablePowerManager(sqInt disableIfNonZero) {
	//API Documented
	return 0;
}	

#if COGVM
/*
 * Support code for Cog.
 * a) Answer whether the C frame pointer is in use, for capture of the C stack
 *    pointers.
 */
# if defined(i386) || defined(__i386) || defined(__i386__)
/*
 * Cog has already captured CStackPointer  before calling this routine.  Record
 * the original value, capture the pointers again and determine if CFramePointer
 * lies between the two stack pointers and hence is likely in use.  This is
 * necessary since optimizing C compilers for x86 may use %ebp as a general-
 * purpose register, in which case it must not be captured.
 */
int
isCFramePointerInUse()
{
	extern unsigned long CStackPointer, CFramePointer;
	extern void (*ceCaptureCStackPointers)(void);
	unsigned long currentCSP = CStackPointer;
	
	currentCSP = CStackPointer;
	ceCaptureCStackPointers();
	assert(CStackPointer < currentCSP);
	return CFramePointer >= CStackPointer && CFramePointer <= currentCSP;
}
# endif /* defined(i386) || defined(__i386) || defined(__i386__) */


/* Answer an approximation of the size of the redzone (if any).  Do so by
 * sending a signal to the process and computing the difference between the
 * stack pointer in the signal handler and that in the caller. Assumes stacks
 * descend.
 */

#if !defined(min)
# define min(x,y) (((x)>(y))?(y):(x))
#endif
static char *p = 0;

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

/* Andreas' stubs */
char* ioGetLogDirectory(void) { return ""; };
sqInt ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz){ return 1; }
