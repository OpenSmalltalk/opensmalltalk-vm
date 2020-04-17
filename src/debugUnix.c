#include "pharovm/pharo.h"

#if __linux__

#define __USE_GNU
#define _GNU_SOURCE

#include <ucontext.h>

#endif

#ifdef HAVE_EXECINFO_H
# include <execinfo.h>
#endif

#include <signal.h>

#define BACKTRACE_DEPTH 64


void ifValidWriteBackStackPointersSaveTo(void *theCFP, void *theCSP, char **savedFPP, char **savedSPP);

void printAllStacks();
void printCallStack();
char* GetAttributeString(int idx);
void reportStackState(const char *msg, char *date, int printAll, ucontext_t *uap, FILE* output);

char * getVersionInfo(int verbose);
void getCrashDumpFilenameInto(char *buf);

void doReport(char* fault, ucontext_t *uap){
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdumpFileName[PATH_MAX+1];
	FILE *crashDumpFile;


	ctime_r(&now,ctimebuf);


	//This is awful but replace the stdout to print all the messages in the file.
	getCrashDumpFilenameInto(crashdumpFileName);
	crashDumpFile = fopen(crashdumpFileName, "a+");
	vm_setVMOutputStream(crashDumpFile);

	reportStackState(fault, ctimebuf, 1, uap, crashDumpFile);

	vm_setVMOutputStream(stderr);
	fclose(crashDumpFile);

	reportStackState(fault, ctimebuf, 1, uap, stderr);

}

void sigusr1(int sig, siginfo_t *info, ucontext_t *uap)
{
	int saved_errno = errno;

	doReport("SIGUSR1", uap);

	errno = saved_errno;
}

static int inFault = 0;

void sigsegv(int sig, siginfo_t *info, ucontext_t *uap)
{
	char *fault = sig == SIGSEGV
					? "Segmentation fault"
					: (sig == SIGBUS
						? "Bus error"
						: (sig == SIGILL
							? "Illegal instruction"
							: "Unknown signal"));

	if (!inFault) {
		inFault = 1;
		doReport(fault, uap);
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

void * printRegisterState(ucontext_t *uap, FILE* output)
{
#if __linux__ && __i386__
	greg_t *regs = uap->uc_mcontext.gregs;
	fprintf(output,
			"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs[REG_EAX], regs[REG_EBX], regs[REG_ECX], regs[REG_EDX],
			regs[REG_EDI], regs[REG_EDI], regs[REG_EBP], regs[REG_ESP],
			regs[REG_EIP]);
	return (void *)regs[REG_EIP];
#elif __APPLE__ && __DARWIN_UNIX03 && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->__ss;
	fprintf(output,
			"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->__eax, regs->__ebx, regs->__ecx, regs->__edx,
			regs->__edi, regs->__edi, regs->__ebp, regs->__esp,
			regs->__eip);
	return (void *)(regs->__eip);
#elif __APPLE__ && __i386__
	_STRUCT_X86_THREAD_STATE32 *regs = &uap->uc_mcontext->ss;
	fprintf(output,
			"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->eax, regs->ebx, regs->ecx, regs->edx,
			regs->edi, regs->edi, regs->ebp, regs->esp,
			regs->eip);
	return (void *)(regs->eip);
#elif __APPLE__ && __x86_64__
	_STRUCT_X86_THREAD_STATE64 *regs = &uap->uc_mcontext->__ss;
	fprintf(output,
			"\trax 0x%016llx rbx 0x%016llx rcx 0x%016llx rdx 0x%016llx\n"
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
	fprintf(output,
			"\t r0 0x%08x r1 0x%08x r2 0x%08x r3 0x%08x\n"
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
	fprintf(output,
			"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs->mc_eax, regs->mc_ebx, regs->mc_ecx, regs->mc_edx,
			regs->mc_edi, regs->mc_edi, regs->mc_ebp, regs->mc_esp,
			regs->mc_eip);
	return regs->mc_eip;
#elif __linux__ && __x86_64__
	greg_t *regs = uap->uc_mcontext.gregs;
	fprintf(output,
			"\trax 0x%08x rbx 0x%08x rcx 0x%08x rdx 0x%08x\n"
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
	fprintf(output,
			"\t r0 0x%08x r1 0x%08x r2 0x%08x r3 0x%08x\n"
	        "\t r4 0x%08x r5 0x%08x r6 0x%08x r7 0x%08x\n"
	        "\t r8 0x%08x r9 0x%08x r10 0x%08x fp 0x%08x\n"
	        "\t ip 0x%08x sp 0x%08x lr 0x%08x pc 0x%08x\n",
	        regs->arm_r0,regs->arm_r1,regs->arm_r2,regs->arm_r3,
	        regs->arm_r4,regs->arm_r5,regs->arm_r6,regs->arm_r7,
	        regs->arm_r8,regs->arm_r9,regs->arm_r10,regs->arm_fp,
	        regs->arm_ip, regs->arm_sp, regs->arm_lr, regs->arm_pc);
#else
	fprintf(output,"don't know how to derive register state from a ucontext_t on this platform\n");
	return 0;
#endif
}

void reportStackState(const char *msg, char *date, int printAll, ucontext_t *uap, FILE* output)
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

	fprintf(output,"\n%s%s%s\n\n", msg, date ? " " : "", date ? date : "");
	fprintf(output,"%s\n%s\n\n", GetAttributeString(0), getVersionInfo(1));

#if COGVM
	/* Do not attempt to report the stack until the VM is initialized!! */
	if (!*(char **)stackLimitAddress())
		return;
#endif

#ifdef HAVE_EXECINFO_H
	fprintf(output,"C stack backtrace & registers:\n");
	if (uap) {
		addrs[0] = printRegisterState(uap, output);
		depth = 1 + backtrace(addrs + 1, BACKTRACE_DEPTH);
	}
	else{
		depth = backtrace(addrs, BACKTRACE_DEPTH);
	}

	fputc('*', output); /* indicate where pc is */
	fflush(output); /* backtrace_symbols_fd uses unbuffered i/o */
	backtrace_symbols_fd(addrs, depth + 1, fileno(output));
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
				fprintf(output, "\n\nAll Smalltalk process stacks (active first):\n");
				printAllStacks();
			}
			else {
				fprintf(output,"\n\nSmalltalk stack dump:\n");
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
		fprintf(output,"\nCan't dump Smalltalk stack(s). Not in VM thread\n");
#if STACKVM
	fprintf(output, "\nMost recent primitives\n");
	dumpPrimTraceLog();
# if COGVM
	fprintf(output,"\n");
	reportMinimumUnusedHeadroom();
# endif
#endif
	fprintf(output,"\n\t(%s)\n", msg);
	fflush(output);
}
