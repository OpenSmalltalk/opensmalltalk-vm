#include <pharo.h>
#include <stdarg.h>
#include <sys/ucontext.h>

#if defined(DEBUG) && DEBUG
static int max_error_level = 4;
#else
static int max_error_level = 1;
#endif
/*
 * This function set the logLevel to use in the VM
 *
 * LOG_NONE 		0
 * LOG_ERROR 		1
 * LOG_WARN 		2
 * LOG_INFO 		3
 * LOG_DEBUG		4
 *
 */
EXPORT(void) logLevel(int value){
	max_error_level = value;
}

void error(char *errorMessage){
    logError(errorMessage);
    abort();
}

static char* severityName[4] = {"ERROR", "WARN", "INFO", "DEBUG"};

EXPORT(void) logAssert(const char* fileName, const char* functionName, int line, char* msg){
	logMessage(LOG_WARN, fileName, functionName, line, msg);
}

EXPORT(void) logMessage(int level, const char* fileName, const char* functionName, int line, ...){
	char * format;
	char timestamp[20];

	if(level > max_error_level){
		return;
	}

	time_t now = time(NULL);
	strftime(timestamp, 20, "%Y-%m-%d %H:%M:%S", localtime(&now));

	//Printing the header.
	// Ex: [DEBUG] 2017-11-14 21:57:53,661 functionName (filename:line) - This is a debug log message.
	printf("[%-5s] %s %s (%s:%d):", severityName[level - 1], timestamp, functionName, fileName, line);

	//Printint the message from the var_args.
	va_list list;
	va_start(list, line);

	format = va_arg(list, char*);
	vprintf(format, list);

	va_end(list);

	int formatLength = strlen(format);

	if(formatLength == 0 || format[formatLength - 1] != '\n'){
		printf("\n");
	}

	fflush(stdout);
}
#include <signal.h>
#include <execinfo.h>

#define BACKTRACE_DEPTH 64

void ifValidWriteBackStackPointersSaveTo(void *theCFP, void *theCSP, char **savedFPP, char **savedSPP);

void printAllStacks();
void printCallStack();
char* GetAttributeString(int idx);
void reportStackState(const char *msg, char *date, int printAll, ucontext_t *uap);
void pushOutputFile(char*);
void popOutputFile();
char * getVersionInfo(int verbose);

void getCrashDumpFilenameInto(char *buf)
{
	strcat(buf, "crash.dmp");
}

void sigusr1(int sig, siginfo_t *info, ucontext_t *uap)
{
	int saved_errno = errno;
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[PATH_MAX+1];

	getCrashDumpFilenameInto(crashdump);
	ctime_r(&now,ctimebuf);

	pushOutputFile(crashdump);

	reportStackState("SIGUSR1", ctimebuf, 1, uap);

	popOutputFile();

	reportStackState("SIGUSR1", ctimebuf, 1, uap);

	errno = saved_errno;
}

static int inFault = 0;

void sigsegv(int sig, siginfo_t *info, ucontext_t *uap)
{
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[PATH_MAX+1];
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
	abort();
}


EXPORT(void) installErrorHandlers(){
	struct sigaction sigusr1_handler_action, sigsegv_handler_action;

	sigsegv_handler_action.sa_sigaction = (void (*)(int, struct __siginfo *, void *))sigsegv;
	sigsegv_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
	sigemptyset(&sigsegv_handler_action.sa_mask);
    (void)sigaction(SIGBUS, &sigsegv_handler_action, 0);
    (void)sigaction(SIGILL, &sigsegv_handler_action, 0);
    (void)sigaction(SIGSEGV, &sigsegv_handler_action, 0);

	sigusr1_handler_action.sa_sigaction = (void (*)(int, struct __siginfo *, void *))sigusr1;
	sigusr1_handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
	sigemptyset(&sigusr1_handler_action.sa_mask);
    (void)sigaction(SIGUSR1, &sigusr1_handler_action, 0);
}

void * printRegisterState(ucontext_t *uap)
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
			regs->__rdi, regs->__rdi, regs->__rbp, regs->__rsp,
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
			regs[REG_RDI], regs[REG_RDI], regs[REG_RBP], regs[REG_RSP],
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

void reportStackState(const char *msg, char *date, int printAll, ucontext_t *uap)
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

char *getVersionInfo(int verbose)
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
  extern char *revisionAsString();
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

#if ITIMER_HEARTBEAT
# define HBID " ITHB"
#else
# define HBID
#endif

  if (verbose)
    sprintf(info+strlen(info), IMAGE_DIALECT_NAME " VM version: ");
  sprintf(info+strlen(info), "%s-%s ", VM_VERSION, VM_BUILD_STRING);
#if defined(USE_XSHM)
  sprintf(info+strlen(info), " XShm");
#endif
  sprintf(info+strlen(info), " %s [" BuildVariant HBID " VM]\n", COMPILER_VERSION);
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
  sprintf(info+strlen(info), "%s\n", VM_BUILD_SOURCE_STRING);
  if (verbose)
    sprintf(info+strlen(info), "Build host: ");
  return info;
}
