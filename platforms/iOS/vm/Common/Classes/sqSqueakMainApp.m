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
#import "include_ucontext.h"
#import "sqPlatformSpecific.h"

#if STACKVM || COGVM
# import "sqSCCSVersion.h"
#else
# import "sqMacV2Memory.h"
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

extern BOOL NSApplicationLoad(void);

static void reportStackState(FILE *,const char *, char *, int, ucontext_t *);
static void block();
static void *printRegisterState(FILE *,ucontext_t *);

/* Print an error message, possibly a stack trace, and exit. */
/* Disable Intel compiler inlining of error which is used for breakpoints */
#pragma auto_inline(off)
#if COGVM || STACKVM
void
error(const char *msg)
{
	reportStackState(stderr,msg,0,0,0);
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
reportStackState(FILE *file, const char *msg, char *date, int printAll, ucontext_t *uap)
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

	fprintf(file,"\n%s%s%s\n\n", msg, date ? " " : "", date ? date : "");
# if STACKVM
    fprintf(file,"%s\n\n", sourceVersionString('\n'));

#	if COGVM
	/* Do not attempt to report the stack until the VM is initialized!! */
	if (!*(char **)stackLimitAddress())
		return;
#	endif
# endif

# if !defined(NOEXECINFO)
	fprintf(file,"C stack backtrace & registers:\n");
	if (uap) {
		addrs[0] = printRegisterState(file,uap);
		depth = 1 + backtrace(addrs + 1, BACKTRACE_DEPTH);
	}
	else
		depth = backtrace(addrs, BACKTRACE_DEPTH);
	fflush(file); /* backtrace_symbols_fd uses unbuffered i/o */
	backtrace_symbols_fd(addrs, depth, fileno(file));
# endif

	if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		if (!printingStack) {
# if COGVM
		/* If in generated machine code then the stack dump machinery can
		 * only give an accurate report if stackPointer & framePointer are
		 * set to the native stack & frame pointers.
		 */
			extern void ifValidWriteBackStackPointersSaveTo(void*,void*,char**,char**);
			void *fp = (void *)(uap ? uap->_FP_IN_UCONTEXT : 0);
			void *sp = (void *)(uap ? uap->_SP_IN_UCONTEXT : 0);
			char *savedSP, *savedFP;

			ifValidWriteBackStackPointersSaveTo(fp,sp,&savedFP,&savedSP);
# endif /* COGVM */

			printingStack = true;
			if (printAll) {
				fprintf(file,"\n\nAll Smalltalk process stacks (active first):\n");
				printAllStacksOn(file);
			}
			else {
				fprintf(file,"\n\nSmalltalk stack dump:\n");
				printCallStackOn(file);
			}
			printingStack = false;
# if COGVM
			/* Now restore framePointer and stackPointer via same function */
			ifValidWriteBackStackPointersSaveTo(savedFP,savedSP,0,0);
# endif
		}
	}
	else
		fprintf(file,"\nCan't dump Smalltalk stack(s). Not in VM thread\n");
# if STACKVM
	fprintf(file,"\nMost recent primitives\n");
	dumpPrimTraceLogOn(file);
#	if COGVM
	fprintf(file,"\n");
	reportMinimumUnusedHeadroomOn(file);
#	endif
# endif
	fprintf(file,"\n\t(%s)\n", msg);
	fflush(file);
}

/* Attempt to dump the registers to stdout.  Only do so if we know how. 
 * Answer the pc (or 0).
 */
static void *
printRegisterState(FILE *file,ucontext_t *uap)
{
#define v(v) ((void *)(v))
#if __DARWIN_UNIX03 && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->__ss;
	fprintf(file,
			"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->__eax, regs->__ebx, regs->__ecx, regs->__edx,
			regs->__edi, regs->__edi, regs->__ebp, regs->__esp,
			regs->__eip);
	return v(regs->__eip);
#elif __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->ss;
	fprintf(file,
			"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->eax, regs->ebx, regs->ecx, regs->edx,
			regs->edi, regs->edi, regs->ebp, regs->esp,
			regs->eip);
	return v(regs->eip);
#elif __x86_64__
	_STRUCT_X86_THREAD_STATE64 *regs = &uap->uc_mcontext->__ss;
	fprintf(file,
			"    rax %14p rbx %14p rcx %14p rdx %14p\n"
			"    rdi %14p rsi %14p rbp %14p rsp %14p\n"
			"    r8  %14p r9  %14p r10 %14p r11 %14p\n"
			"    r12 %14p r13 %14p r14 %14p r15 %14p\n"
			"    rip %14p\n",
			v(regs->__rax), v(regs->__rbx), v(regs->__rcx), v(regs->__rdx),
			v(regs->__rdi), v(regs->__rsi), v(regs->__rbp), v(regs->__rsp),
			v(regs->__r8 ), v(regs->__r9 ), v(regs->__r10), v(regs->__r11),
			v(regs->__r12), v(regs->__r13), v(regs->__r14), v(regs->__r15),
			v(regs->__rip));
	return v(regs->__rip);
# elif defined(__arm64__) || defined(__aarch64__)
	_STRUCT_ARM_THREAD_STATE64 *regs = &uap->uc_mcontext->__ss;
#   define vr(r) v(regs->r)
	fprintf(file,
			"     x0 %14p  x1 %14p  x2 %14p  x3 %14p\n"
			"     x4 %14p  x5 %14p  x6 %14p  x7 %14p\n"
			"     x8 %14p  x9 %14p x10 %14p x11 %14p\n"
			"    x12 %14p x13 %14p x14 %14p x15 %14p\n"
			"    x16 %14p x17 %14p x18 %14p x19 %14p\n"
			"    x20 %14p x21 %14p x22 %14p x23 %14p\n"
			"    x24 %14p x25 %14p x26 %14p x27 %14p\n"
			"    x29 %14p  fp %14p  lr %14p  sp %14p\n",
			"    cpsr 0x%08x\n",
			vr( __x[0]), vr( __x[1]), vr( __x[2]), vr( __x[3]),
			vr( __x[4]), vr( __x[5]), vr( __x[6]), vr( __x[7]),
			vr( __x[8]), vr( __x[9]), vr(__x[10]), vr(__x[11]),
			vr(__x[12]), vr(__x[13]), vr(__x[14]), vr(__x[15]),
			vr(__x[16]), vr(__x[17]), vr(__x[18]), vr(__x[19]),
			vr(__x[20]), vr(__x[21]), vr(__x[22]), vr(__x[23]),
			vr(__x[24]), vr(__x[25]), vr(__x[26]), vr(__x[27]),
			vr(__x[28]), vr(__fp),    vr(__lr),    vr(__sp),
			vr(__pc), regs->__cpsr);
	return vr(__pc);
#elif defined(__arm__) || defined(__arm32__)
	_STRUCT_ARM_THREAD_STATE *regs = &uap->uc_mcontext->ss;
	fprintf(file,
	        "\t r0 0x%08x r1 0x%08x r2 0x%08x r3 0x%08x\n"
	        "\t r4 0x%08x r5 0x%08x r6 0x%08x r7 0x%08x\n"
	        "\t r8 0x%08x r9 0x%08x r10 0x%08x fp 0x%08x\n"
	        "\t ip 0x%08x sp 0x%08x lr 0x%08x pc 0x%08x\n"
			"\tcpsr 0x%08x\n",
	        regs->r[0],regs->r[1],regs->r[2],regs->r[3],
	        regs->r[4],regs->r[5],regs->r[6],regs->r[7],
	        regs->r[8],regs->r[9],regs->r[10],regs->r[11],
	        regs->r[12], regs->sp, regs->lr, regs->pc, regs->cpsr);
	return v(regs->pc);
#else
	fprintf(file,"don't know how to derive register state from a ucontext_t on this platform\n");
	return v(0);
#endif
}

static FILE *
crashDumpFile()
{
	char namebuf[PATH_MAX+1];
#if defined(PREFERENCES_RELATIVE_LOG_LOCATION)
	FSRef fsRef;
	if (!FSFindFolder(kUserDomain, kPreferencesFolderType, 1, &fsRef)
	 && !FSRefMakePath(&fsRef, (unsigned char *)namebuf, PATH_MAX)) {
		strncat(namebuf,"/" PREFERENCES_RELATIVE_LOG_LOCATION "/crash.dmp",PATH_MAX+1);
		return fopen(namebuf,"a+");
	}
#endif
    strcpy(namebuf,imageName);
    char *slash = strrchr(namebuf,'/');
    strcpy(slash ? slash + 1 : namebuf, "crash.dmp");
	return fopen(namebuf,"a+");
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

	if (!ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		pthread_kill(getVMOSThread(),sig);
		errno = saved_errno;
		return;
	}

	FILE *crashdump = crashDumpFile();
	ctime_r(&now,ctimebuf);
	reportStackState(crashdump,"SIGUSR1", ctimebuf, 1, uap);
	reportStackState(stdout,"SIGUSR1", ctimebuf, 1, uap);
	fclose(crashdump);

	errno = saved_errno;
}

static int inFault = 0;

sqInt
ioCanCatchFFIExceptions() { return 1; }

extern sqInt wait_for_debugger_to_attach_on_ffi_exception;
sqInt wait_for_debugger_to_attach_on_ffi_exception = 0;

void
sigsegv(int sig, siginfo_t *info, void *uap)
{
	time_t now = time(NULL);
	char ctimebuf[32];
	const char *fault = sig == SIGSEGV
						? "Segmentation fault"
						: (sig == SIGBUS
							? "Bus error"
							: (sig == SIGILL
								? "Illegal instruction"
								: "Unknown signal"));

	if (!inFault) {
		extern sqInt primitiveFailForFFIExceptionat(usqLong exceptionCode, usqInt pc);
		while (wait_for_debugger_to_attach_on_ffi_exception)
			usleep(100000);  // sleep for 0.1 seconds
		primitiveFailForFFIExceptionat(sig, ((ucontext_t *)uap)->_PC_IN_UCONTEXT);
		inFault = 1;
		FILE *crashdump = crashDumpFile();
		ctime_r(&now,ctimebuf);
		reportStackState(crashdump,fault, ctimebuf, 0, uap);
		reportStackState(stderr,fault, ctimebuf, 0, uap);
		fclose(crashdump);
	}
	if (blockOnError) block();
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

#if STACKVM
void
attachToSignals()
{
	struct sigaction sigusr1_handler_action, sigsegv_handler_action;

	if (gNoSignalHandlers) return;

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
}
#endif // STACKVM

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
 * b) answer the amount of stack room to ensure in a Cog stack page, including
 *    the size of the redzone, if any.
 */

int
isCFramePointerInUse(usqIntptr_t *cFrmPtrPtr, usqIntptr_t *cStkPtrPtr)
{
	extern void (*ceCaptureCStackPointers)(void);
	usqIntptr_t currentCSP = *cStkPtrPtr;

	ceCaptureCStackPointers();
	assert(*cStkPtrPtr < currentCSP);
	return *cFrmPtrPtr >= *cStkPtrPtr && *cFrmPtrPtr <= currentCSP;
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
	return (char *)min(&old,&handler_action) - p;
}

static int stackPageHeadroom;

/* Answer the redzone size plus space for any signal handlers to run in.
 * N.B. Space for signal handers may include space for the dynamic linker to
 * run in since signal handlers may reference other functions, and linking may
 * be lazy.  The reportheadroom switch can be used to check empirically that
 * there is sufficient headroom.  At least on Mac OS X we see no large stack
 * usage that would indicate e.g. dynamic linking in signal handlers.
 * So answer only the redzone size and likely get small pages (2048 byte on 32
 * bit, 4096 bytes on 64-bits).
 *
 * eem, february/march 2022: recent experience with Virtend shows that more
 * headroom is needed on current versions of MacOS. So 8k pages on 64-bits.
 */
int
osCogStackPageHeadroom()
{
	if (!stackPageHeadroom)
#if SQ_HOST64 // was __ARM_ARCH_ISA_A64 || __aarch64__ || __arm64__
		stackPageHeadroom = getRedzoneSize() + 1024;
#else
		stackPageHeadroom = getRedzoneSize();
#endif
	return stackPageHeadroom;
}

#endif /* COGVM */

/* Andreas' stubs */
char* ioGetLogDirectory(void) { return ""; };
sqInt ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz){ return 1; }
