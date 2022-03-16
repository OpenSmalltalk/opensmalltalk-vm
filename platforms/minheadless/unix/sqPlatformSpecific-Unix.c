/* sqPlatformSpecific-Win32.c -- Platform specific interface implementation for Unix
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Minimalistic Headless Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Author: roniesalg@gmail.com
 */
/**
 * Note: The code present in this file is a result of refactoring the code present
 * in the old Squeak Win32 ports. For purpose of copyright, each one of the functions
 * present in this file may have an actual author that is different to the author
 * of this file.
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/param.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>

#if !defined(NOEXECINFO)
# include <execinfo.h>
# define BACKTRACE_DEPTH 64
#endif
#if __OpenBSD__
# include <sys/signal.h>
#endif
#if __FreeBSD__
# include <sys/ucontext.h>
#endif
#if __sun__
# include <sys/ucontext.h>
# include <limits.h>
#endif

#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "config.h"
#include "debug.h"

#ifdef __APPLE__
#include "mac-alias.inc"
#endif

#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(i486) || defined(__i486) || defined (__i486__) \
			|| defined(intel) || defined(x86) || defined(i86pc) )
static void fldcw(unsigned int cw)
{
    __asm__("fldcw %0" :: "m"(cw));
}
#else
#   define fldcw(cw)
#endif

#if defined(__GNUC__) && ( defined(ppc) || defined(__ppc) || defined(__ppc__)  \
			|| defined(POWERPC) || defined(__POWERPC) || defined (__POWERPC__) )
void mtfsfi(unsigned long long fpscr)
{
    __asm__("lfd   f0, %0" :: "m"(fpscr));
    __asm__("mtfsf 0xff, f0");
}
#else
#   define mtfsfi(fpscr)
#endif

#if !defined(min)
# define min(x,y) (((x)>(y))?(y):(x))
#endif

extern int sqVMOptionInstallExceptionHandlers;
extern int sqVMOptionBlockOnError;
extern int sqVMOptionBlockOnWarn;
extern char **argVec;

static int inFault = 0;
static char crashdump[FILENAME_MAX+1];

extern char *GetAttributeString(sqInt id);
extern const char *getVersionInfo(int verbose);
extern void getCrashDumpFilenameInto(char *buf);

extern void dumpPrimTraceLog(void);
extern void pushOutputFile(char *);
extern void popOutputFile(void);
extern void ifValidWriteBackStackPointersSaveTo(void*,void*,char**,char**);

static void
block()
{
    struct timespec while_away_the_hours;
    char pwd[MAXPATHLEN+1];

    printf("blocking e.g. to allow attaching debugger\n");
    printf("pid: %d pwd: %s vm:%s\n",
    		(int)getpid(), getcwd(pwd,MAXPATHLEN+1), argVec[0]);
    while (1)
    {
    	while_away_the_hours.tv_sec = 3600;
    	nanosleep(&while_away_the_hours, 0);
    }
}


void ioInitPlatformSpecific(void)
{
    fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
    mtfsfi(0);		/* disable signals, IEEE mode, round to nearest */
}

time_t convertToSqueakTime(time_t unixTime)
{
#ifdef HAVE_TM_GMTOFF
  unixTime+= localtime(&unixTime)->tm_gmtoff;
#else
# ifdef HAVE_TIMEZONE
  unixTime+= ((daylight) * 60*60) - timezone;
# else
#  error: cannot determine timezone correction
# endif
#endif
  /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
     and 52 non-leap years later than Squeak. */
  return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
}

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

static char * volatile p = 0;

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

sqInt reportStackHeadroom;
static int stackPageHeadroom;

/* Answer the redzone size plus space for any signal handlers to run in.
 * N.B. Space for signal handers may include space for the dynamic linker to
 * run in since signal handlers may reference other functions, and linking may
 * be lazy.  The reportheadroom switch can be used to check empirically that
 * there is sufficient headroom.
 */
int
osCogStackPageHeadroom()
{
	if (!stackPageHeadroom)
		stackPageHeadroom = getRedzoneSize() + 1024;
	return stackPageHeadroom;
}
#endif /* COGVM */

/* New filename converting function; used by the interpreterProxy function
  ioFilenamefromStringofLengthresolveAliases. Most platforms can ignore the
  resolveAlias boolean - it seems to only be of use by OSX but is crucial there.
*/
sqInt
sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt resolveAlias)
{
    int numLinks= 0;
    struct stat st;

    memcpy(aCharBuffer, aFilenameString, filenameLength);
    aCharBuffer[filenameLength]= 0;

    if (resolveAlias)
    {
        for (;;)	/* aCharBuffer might refer to link or alias */
        {
            if (!lstat(aCharBuffer, &st) && S_ISLNK(st.st_mode))	/* symlink */
            {
                char linkbuf[PATH_MAX+1];
                if (++numLinks > MAXSYMLINKS)
                    return -1;	/* too many levels of indirection */

	            filenameLength= readlink(aCharBuffer, linkbuf, PATH_MAX);
	            if ((filenameLength < 0) || (filenameLength >= PATH_MAX))
                    return -1;	/* link unavailable or path too long */

	            linkbuf[filenameLength]= 0;

	            if (filenameLength > 0 && *linkbuf == '/') /* absolute */
	               strcpy(aCharBuffer, linkbuf);
	            else {
                    char *lastSeparator = strrchr(aCharBuffer,'/');
                    char *append = lastSeparator ? lastSeparator + 1 : aCharBuffer;
                    if (append - aCharBuffer + strlen(linkbuf) > PATH_MAX)
                        return -1; /* path too long */
                    strcpy(append,linkbuf);
	            }
                continue;
            }

#    if defined(DARWIN)
            if (isMacAlias(aCharBuffer))
            {
                if ((++numLinks > MAXSYMLINKS) || !resolveMacAlias(aCharBuffer, aCharBuffer, PATH_MAX))
                    return -1;		/* too many levels or bad alias */
                continue;
            }
#    endif

	        break;			/* target is no longer a symlink or alias */
        }
    }

    return 0;
}

sqInt
ioBeep(void)
{
    return 0;
}

sqInt
ioExit(void)
{
    exit(0);
}

sqInt
ioExitWithErrorCode(int errorCode)
{
    exit(errorCode);
}

sqInt
ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
    aioSleepForUsecs(microSeconds);
    return 0;
}

void
ioControlProfile(int on, void **vhp, long *nvb, void **ehp, long *neb)
{
}

long
ioControlNewProfile(int on, unsigned long buffer_size)
{
    return 0;
}

void
ioNewProfileStatus(sqInt *running, long *buffersize)
{
}

long
ioNewProfileSamplesInto(void *sampleBuffer)
{
    return 0;
}

void
ioClearProfile(void)
{
}

sqInt
ioDisablePowerManager(sqInt disableIfNonZero)
{
    return true;
}

/* Executable path. */
void
findExecutablePath(const char *localVmName, char *dest, size_t destSize)
{
#if defined(__linux__)
    static char	 name[MAXPATHLEN+1];
    int    len;
#endif

#if defined(__linux__)
    if ((len = readlink("/proc/self/exe", name, sizeof(name))) > 0)
    {
        struct stat st;
        name[len]= '\0';
        if (!stat(name, &st))
            localVmName= name;
    }
#endif

    /* get canonical path to vm */
    if (realpath(localVmName, dest) == 0)
        sqPathMakeAbsolute(dest, destSize, localVmName);

    /* truncate vmPath to dirname */
    {
        int i= 0;
        for (i = strlen(dest); i >= 0; i--)
        {
            if ('/' == dest[i])
            {
                dest[i+1]= '\0';
                break;
            }
        }
    }
}


/* Print an error message, possibly a stack trace, do /not/ exit.
 * Allows e.g. writing to a log file and stderr.
 */
static void *printRegisterState(ucontext_t *uap);

#error "the new exception handling code from platforms/unix/vm/sqUnixMain.c needs to be integrated here. eem 2021/9/28"

static void
reportStackState(const char *msg, char *date, int printAll, ucontext_t *uap)
{
#if !defined(NOEXECINFO)
	void *addrs[BACKTRACE_DEPTH];
	void *pc;
	int depth;
#endif
	/* flag prevents recursive error when trying to print a broken stack */
	static sqInt printingStack = false;

#if COGVM
	/* Testing stackLimit tells us whether the VM is initialized. */
	extern usqInt stackLimitAddress(void);
#endif

	printf("\n%s%s%s\n\n", msg, date ? " " : "", date ? date : "");
	printf("%s\n%s\n\n", GetAttributeString(0), getVersionInfo(1));

#if COGVM
	/* Do not attempt to report the stack until the VM is initialized!! */
	if (!*(char **)stackLimitAddress())
		return;
#endif

#if !defined(NOEXECINFO)
	printf("C stack backtrace & registers:\n");
	if (uap) {
		addrs[0] = printRegisterState(uap);
		depth = 1 + backtrace(addrs + 1, BACKTRACE_DEPTH);
	}
	else
		depth = backtrace(addrs, BACKTRACE_DEPTH);
	putchar('*'); /* indicate where pc is */
	fflush(stdout); /* backtrace_symbols_fd uses unbuffered i/o */
	backtrace_symbols_fd(addrs, depth + 1, fileno(stdout));
#endif

	if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		if (!printingStack) {
#if COGVM
			/* If we're in generated machine code then the only way the stack
			 * dump machinery has of giving us an accurate report is if we set
			 * stackPointer & framePointer to the native stack & frame pointers.
			 */
# if __APPLE__ && __MACH__ && __i386__
#	  if __GNUC__ && !__INTEL_COMPILER /* icc pretends to be gcc */
			void *fp = (void *)(uap ? uap->uc_mcontext->__ss.__ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->__ss.__esp: 0);
#	  else
			void *fp = (void *)(uap ? uap->uc_mcontext->ss.ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->ss.esp: 0);
#	  endif
# elif __APPLE__ && __MACH__ && __x86_64__
			void *fp = (void *)(uap ? uap->uc_mcontext->__ss.__rbp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->__ss.__rsp: 0);
# elif __linux__ && __i386__
			void *fp = (void *)(uap ? uap->uc_mcontext.gregs[REG_EBP]: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext.gregs[REG_ESP]: 0);
#	elif __linux__ && __x86_64__
			void *fp = (void *)(uap ? uap->uc_mcontext.gregs[REG_RBP]: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext.gregs[REG_RSP]: 0);
# elif __FreeBSD__ && __i386__
			void *fp = (void *)(uap ? uap->uc_mcontext.mc_ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext.mc_esp: 0);
# elif __OpenBSD__
			void *fp = (void *)(uap ? uap->sc_rbp: 0);
			void *sp = (void *)(uap ? uap->sc_rsp: 0);
# elif __sun__ && __i386__
      void *fp = (void *)(uap ? uap->uc_mcontext.gregs[REG_FP]: 0);
      void *sp = (void *)(uap ? uap->uc_mcontext.gregs[REG_SP]: 0);
# elif defined(__arm__) || defined(__arm32__) || defined(ARM32)
			void *fp = (void *)(uap ? uap->uc_mcontext.arm_fp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext.arm_sp: 0);
# else
#	error need to implement extracting pc from a ucontext_t on this system
# endif
			char *savedSP, *savedFP;

			ifValidWriteBackStackPointersSaveTo(fp,sp,&savedFP,&savedSP);
#endif /* COGVM */

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
#if __linux__ && __i386__
	greg_t *regs = uap->uc_mcontext.gregs;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs[REG_EAX], regs[REG_EBX], regs[REG_ECX], regs[REG_EDX],
			regs[REG_EDI], regs[REG_EDI], regs[REG_EBP], regs[REG_ESP],
			regs[REG_EIP]);
	return (void *)regs[REG_EIP];
#elif __APPLE__ && __DARWIN_UNIX03 && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->__ss;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->__eax, regs->__ebx, regs->__ecx, regs->__edx,
			regs->__edi, regs->__edi, regs->__ebp, regs->__esp,
			regs->__eip);
	return (void *)(regs->__eip);
#elif __APPLE__ && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->ss;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->eax, regs->ebx, regs->ecx, regs->edx,
			regs->edi, regs->edi, regs->ebp, regs->esp,
			regs->eip);
	return (void *)(regs->eip);
#elif __APPLE__ && __x86_64__
	_STRUCT_X86_THREAD_STATE64 *regs = &uap->uc_mcontext->__ss;
	printf(	"\trax 0x%016llx rbx 0x%016llx rcx 0x%016llx rdx 0x%016llx\n"
			"\trdi 0x%016llx rsi 0x%016llx rbp 0x%016llx rsp 0x%016llx\n"
			"\tr8  0x%016llx r9  0x%016llx r10 0x%016llx r11 0x%016llx\n"
			"\tr12 0x%016llx r13 0x%016llx r14 0x%016llx r15 0x%016llx\n"
			"\trip 0x%016llx\n",
			regs->__rax, regs->__rbx, regs->__rcx, regs->__rdx,
			regs->__rdi, regs->__rsi, regs->__rbp, regs->__rsp,
			regs->__r8 , regs->__r9 , regs->__r10, regs->__r11,
			regs->__r12, regs->__r13, regs->__r14, regs->__r15,
			regs->__rip);
	return (void *)(regs->__rip);
# elif __APPLE__ && (defined(__arm__) || defined(__arm32__))
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
#elif __FreeBSD__ && __i386__
	struct mcontext *regs = &uap->uc_mcontext;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->mc_eax, regs->mc_ebx, regs->mc_ecx, regs->mc_edx,
			regs->mc_edi, regs->mc_edi, regs->mc_ebp, regs->mc_esp,
			regs->mc_eip);
	return regs->mc_eip;
#elif __linux__ && __x86_64__
	greg_t *regs = uap->uc_mcontext.gregs;
	printf(	"\trax 0x%08x rbx 0x%08x rcx 0x%08x rdx 0x%08x\n"
			"\trdi 0x%08x rsi 0x%08x rbp 0x%08x rsp 0x%08x\n"
			"\tr8  0x%08x r9  0x%08x r10 0x%08x r11 0x%08x\n"
			"\tr12 0x%08x r13 0x%08x r14 0x%08x r15 0x%08x\n"
			"\trip 0x%08x\n",
			regs[REG_RAX], regs[REG_RBX], regs[REG_RCX], regs[REG_RDX],
			regs[REG_RDI], regs[REG_RSI], regs[REG_RBP], regs[REG_RSP],
			regs[REG_R8 ], regs[REG_R9 ], regs[REG_R10], regs[REG_R11],
			regs[REG_R12], regs[REG_R13], regs[REG_R14], regs[REG_R15],
			regs[REG_RIP]);
	return regs[REG_RIP];
# elif __linux__ && (defined(__arm__) || defined(__arm32__) || defined(ARM32))
	struct sigcontext *regs = &uap->uc_mcontext;
	printf(	"\t r0 0x%08x r1 0x%08x r2 0x%08x r3 0x%08x\n"
	        "\t r4 0x%08x r5 0x%08x r6 0x%08x r7 0x%08x\n"
	        "\t r8 0x%08x r9 0x%08x r10 0x%08x fp 0x%08x\n"
	        "\t ip 0x%08x sp 0x%08x lr 0x%08x pc 0x%08x\n",
	        regs->arm_r0,regs->arm_r1,regs->arm_r2,regs->arm_r3,
	        regs->arm_r4,regs->arm_r5,regs->arm_r6,regs->arm_r7,
	        regs->arm_r8,regs->arm_r9,regs->arm_r10,regs->arm_fp,
	        regs->arm_ip, regs->arm_sp, regs->arm_lr, regs->arm_pc);
#else
	printf("don't know how to derive register state from a ucontext_t on this platform\n");
	return 0;
#endif
}

static void
sigusr1(int sig, siginfo_t *info, void *uap)
{
	int saved_errno = errno;
	time_t now = time(NULL);
	char ctimebuf[32];
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

static void
sigsegv(int sig, siginfo_t *info, void *uap)
{
	time_t now = time(NULL);
	char ctimebuf[32];
    const char *fault;
    switch(sig)
    {
    case SIGSEGV:
        fault = "Segmentation fault";
        break;
    case SIGBUS:
        fault = "Bus error";
        break;
    case SIGILL:
        fault = "Illegal instruction";
        break;
    default:
        fault = "Unknown signal";
        break;
    }

	if (!inFault) {
		getCrashDumpFilenameInto(crashdump);
		ctime_r(&now,ctimebuf);
		pushOutputFile(crashdump);
		reportStackState(fault, ctimebuf, 0, uap);
		popOutputFile();
		reportStackState(fault, ctimebuf, 0, uap);
	}
	if (sqVMOptionBlockOnError) block();
	abort();
}

#if defined(IMAGE_DUMP)
static void
sighup(int ignore) { dumpImageFile= 1; }

static void
sigquit(int ignore) { emergencyDump(1); }
#endif

int sqExecuteFunctionWithCrashExceptionCatching(sqFunctionThatCouldCrash function, void *userdata)
{
    if (sqVMOptionInstallExceptionHandlers)
    {
        struct sigaction sigusr1_handler_action, sigsegv_handler_action;

        sigsegv_handler_action.sa_sigaction = sigsegv;
        sigsegv_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
        sigemptyset(&sigsegv_handler_action.sa_mask);
        (void)sigaction(SIGSEGV, &sigsegv_handler_action, 0);
        (void)sigaction(SIGBUS, &sigsegv_handler_action, 0);
        (void)sigaction(SIGILL, &sigsegv_handler_action, 0);

        sigusr1_handler_action.sa_sigaction = sigusr1;
        sigusr1_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
        sigemptyset(&sigusr1_handler_action.sa_mask);
        (void)sigaction(SIGUSR1, &sigusr1_handler_action, 0);
    }

#if defined(IMAGE_DUMP)
    signal(SIGHUP,  sighup);
    signal(SIGQUIT, sigquit);
#endif

    return function(userdata);
}

/* OS Exports */
void *os_exports[][3]=
{
    { 0, 0, 0 }
};
