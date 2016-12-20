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

#if STACKVM || COGVM
#import "sqSCCSVersion.h"
#else
#import "sqMacV2Memory.h"
#endif

#if !defined(NOEXECINFO)
# include <execinfo.h>
# define BACKTRACE_DEPTH 64
#endif


#ifdef BUILD_FOR_OSX
/*** Variables -- globals for access from pluggable primitives ***/
EXPORT(int)		argCnt= 0;
EXPORT(char**)	argVec= 0;
EXPORT(char**)	envVec= 0;
#endif

extern sqSqueakAppDelegate *gDelegateApp;

BOOL			gQuitNowRightNow=NO;
BOOL            gSqueakHeadless=NO;
BOOL            gNoSignalHandlers=NO;
int				gSqueakUseFileMappedMMAP=0;
char            gSqueakUntrustedDirectoryName[PATH_MAX];
char            gSqueakTrustedDirectoryName[PATH_MAX];
int				blockOnError=0;

extern void printAllStacks(void);
extern void printCallStack(void);
extern void dumpPrimTraceLog(void);
extern BOOL NSApplicationLoad(void);
extern void pushOutputFile(char *);
extern void popOutputFile(void);

static void reportStackState(char *, char *, int, ucontext_t *);
static void block();
static void *printRegisterState(ucontext_t *);

/* Print an error message, possibly a stack trace, and exit. */
/* Disable Intel compiler inlining of error which is used for breakpoints */
#pragma auto_inline(off)
#if COGVM || STACKVM
void
error(char *msg)
{
	reportStackState(msg,0,0,0);
	if (blockOnError) block();
	abort();
}
#pragma auto_inline(on)

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

/* Print an error message, possibly a stack trace, do /not/ exit.
 * Allows e.g. writing to a log file and stderr.
 */
static void
reportStackState(char *msg, char *date, int printAll, ucontext_t *uap)
{
# if !defined(NOEXECINFO)
	void *addrs[BACKTRACE_DEPTH];
	int depth;
# endif
	/* flag prevents recursive error when trying to print a broken stack */
	static sqInt printingStack = false;

# if STACKVM
	/* Testing stackLimit tells us whether the VM is initialized. */
	extern usqInt stackLimitAddress(void);
# endif

	printf("\n%s%s%s\n\n", msg, date ? " " : "", date ? date : "");
# if STACKVM
    printf("%s\n\n", sourceVersionString('\n'));

#	if COGVM
	/* Do not attempt to report the stack until the VM is initialized!! */
	if (!*(char **)stackLimitAddress())
		return;
#	endif
# endif

# if !defined(NOEXECINFO)
	printf("C stack backtrace & registers:\n");
	if (uap) {
		addrs[0] = printRegisterState(uap);
		depth = 1 + backtrace(addrs + 1, BACKTRACE_DEPTH);
	}
	else
		depth = backtrace(addrs, BACKTRACE_DEPTH);
#	if 1 /* Mac OS's backtrace_symbols_fd prints NULL byte droppings each line */
	fflush(stdout); /* backtrace_symbols_fd uses unbuffered i/o */
	backtrace_symbols_fd(addrs, depth, fileno(stdout));
#	else
	{ int i; char **strings;
	  strings = backtrace_symbols(addrs, depth);
	  printf("(%s)\n", strings[0]);
	  for (i = 1; i < depth; i++)
		printf("%s\n", strings[i]);
	}
#	endif
# endif

	if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		if (!printingStack) {
# if COGVM
		/* If in generated machine code then the stack dump machinery can
		 * only give an accurate report if stackPointer & framePointer are
		 * set to the native stack & frame pointers.
		 */
			extern void ifValidWriteBackStackPointersSaveTo(void*,void*,char**,char**);
#	if __i386__
	/* see sys/ucontext.h; two different namings */
#	  if __GNUC__ && !__INTEL_COMPILER /* icc pretends to be gcc */
			void *fp = (void *)(uap ? uap->uc_mcontext->__ss.__ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->__ss.__esp: 0);
#	  else
			void *fp = (void *)(uap ? uap->uc_mcontext->ss.ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->ss.esp: 0);
#	  endif
#	elif __x86_64__
			void *fp = (void *)(uap ? uap->uc_mcontext->__ss.__rbp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->__ss.__rsp: 0);
#	elif __linux__ && __i386__
			void *fp = (void *)(uap ? uap->uc_mcontext.gregs[REG_EBP]: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext.gregs[REG_ESP]: 0);
#	else
#	  error need to implement extracting pc from a ucontext_t on this system
#	endif
			char *savedSP, *savedFP;

			ifValidWriteBackStackPointersSaveTo(fp,sp,&savedFP,&savedSP);
# endif /* COGVM */

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
# if COGVM
			/* Now restore framePointer and stackPointer via same function */
			ifValidWriteBackStackPointersSaveTo(savedFP,savedSP,0,0);
# endif
		}
	}
	else
		printf("\nCan't dump Smalltalk stack(s). Not in VM thread\n");
# if STACKVM
	printf("\nMost recent primitives\n");
	dumpPrimTraceLog();
#	if COGVM
	printf("\n");
	reportMinimumUnusedHeadroom();
#	endif
# endif
	printf("\n\t(%s)\n", msg);
	fflush(stdout);
}

/* Attempt to dump the registers to stdout.  Only do so if we know how. */
static void *
printRegisterState(ucontext_t *uap)
{
#if __DARWIN_UNIX03 && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->__ss;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->__eax, regs->__ebx, regs->__ecx, regs->__edx,
			regs->__edi, regs->__edi, regs->__ebp, regs->__esp,
			regs->__eip);
	return (void *)(regs->__eip);
#elif __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->ss;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->eax, regs->ebx, regs->ecx, regs->edx,
			regs->edi, regs->edi, regs->ebp, regs->esp,
			regs->eip);
	return (void *)(regs->eip);
#elif __x86_64__
	_STRUCT_X86_THREAD_STATE64 *regs = &uap->uc_mcontext->__ss;
	printf(	"\trax 0x%016lx rbx 0x%016lx rcx 0x%016lx rdx 0x%016lx\n"
			"\trdi 0x%016lx rsi 0x%016lx rbp 0x%016lx rsp 0x%016lx\n"
			"\tr8  0x%016lx r9  0x%016lx r10 0x%016lx r11 0x%016lx\n"
			"\tr12 0x%016lx r13 0x%016lx r14 0x%016lx r15 0x%016lx\n"
			"\trip 0x%016lx\n",
			regs->__rax, regs->__rbx, regs->__rcx, regs->__rdx,
			regs->__rdi, regs->__rdi, regs->__rbp, regs->__rsp,
			regs->__r8 , regs->__r9 , regs->__r10, regs->__r11,
			regs->__r12, regs->__r13, regs->__r14, regs->__r15,
			regs->__rip);
	return (void *)(regs->__rip);
# elif defined(__arm__) || defined(__arm32__)
	_STRUCT_ARM_THREAD_STATE *regs = &uap->uc_mcontext->ss;
	printf(	"\t r0 0x%08x r1 0x%08x r2 0x%08x r3 0x%08x\n"
	        "\t r4 0x%08x r5 0x%08x r6 0x%08x r7 0x%08x\n"
	        "\t r8 0x%08x r9 0x%08x r10 0x%08x fp 0x%08x\n"
	        "\t ip 0x%08x sp 0x%08x lr 0x%08x pc 0x%08x\n"
			"\tcpsr 0x%08x\n",
	        regs->r[0],regs->r[1],regs->r[2],regs->r[3],
	        regs->r[4],regs->r[5],regs->r[6],regs->r[7],
	        regs->r[8],regs->r[9],regs->r[10],regs->r[11],
	        regs->r[12], regs->sp, regs->lr, regs->pc, regs->cpsr);
	return (void *)(regs->pc);
#else
	printf("don't know how to derive register state from a ucontext_t on this platform\n");
	return 0;
#endif
}
static void
getCrashDumpFilenameInto(char *buf)
{
    char *slash;

    strcpy(buf,imageName);
    slash = strrchr(buf,'/');
    strcpy(slash ? slash + 1 : buf, "crash.dmp");
}

/*
 * Signal handlers
 *
 */

void
sigusr1(int sig, siginfo_t *info, void *uap)
{
	int saved_errno = errno;
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[imageNameSize()+1];

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
#else /* COGVM || STACKVM */
void
sigsegv(int sig, siginfo_t *info, void *uap)
{

    /* error("Segmentation fault"); */
    static int printingStack= 0;

    printf("\nSegmentation fault\n\ns");
    if (!printingStack) {
        printingStack= 1;
        printAllStacks();
    }
    abort();
}
#endif /* COGVM || STACKVM */

/*
 * End of signal handlers
 *
 */

void
attachToSignals() {
#if STACKVM
	struct sigaction sigusr1_handler_action, sigsegv_handler_action;

	if (gNoSignalHandlers) return;

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

sqInt
ioExit(void) {
	//API Documented
 	[gDelegateApp.squeakApplication ioExit];
 	return 0;
}

sqInt
ioExitWithErrorCode(int ec) {
	//API Documented
 	[gDelegateApp.squeakApplication ioExitWithErrorCode: ec];
 	return 0;
}

sqInt
ioDisablePowerManager(sqInt disableIfNonZero) {
	//API Documented
	return 0;
}	

#if STACKVM
sqInt reportStackHeadroom;
#endif

#if COGVM
/*
 * Support code for Cog.
 * a) Answer whether the C frame pointer is in use, for capture of the C stack
 *    pointers.
 */

/*
 * Cog has already captured CStackPointer before calling this routine.  Record
 * the original value, capture the pointers again and see if CFramePointer
 * lies between the two stack pointers and hence is likely in use.  This is
 * necessary since optimizing C compilers for x86, x64 et al may use the frame
 * pointer register (%ebp, %rbp et al) as a general-purpose register, in which
 * case it must not be captured.  Assumes stacks descend.
 */
int
isCFramePointerInUse()
{
	extern unsigned long CStackPointer, CFramePointer;
	extern void (*ceCaptureCStackPointers)(void);
	unsigned long currentCSP = CStackPointer;

	ceCaptureCStackPointers();
	assert(CStackPointer < currentCSP);
	return CFramePointer >= CStackPointer && CFramePointer <= currentCSP;
}


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
sighandler(int sig, siginfo_t *info, void *uap) { p = (char *)&sig; }

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
