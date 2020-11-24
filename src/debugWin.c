#include "pharovm/pharo.h"
#include <Windows.h>
#include <DbgHelp.h>

#ifndef PATH_MAX
#define PATH_MAX MAX_PATH
#endif
EXPORT(void) registerCurrentThreadToHandle();

void ifValidWriteBackStackPointersSaveTo(void *theCFP, void *theCSP, char **savedFPP, char **savedSPP);

void printAllStacks();
void printCallStack();

char* GetAttributeString(int idx);
char * getVersionInfo(int verbose);
void getCrashDumpFilenameInto(char *buf);

EXPORT(void) printCrashDebugInformation(LPEXCEPTION_POINTERS exp);
void reportStackState(LPEXCEPTION_POINTERS exp, char* date, FILE* output);
EXPORT(void) printRegisterState(PCONTEXT exp, FILE* output);
EXPORT(void) printMachineCallStack(PCONTEXT ctx , FILE* output);

#if COGVM
	usqInt stackLimitAddress(void);
	void printCogMethodFor(void* address);
#endif

#define MAX_THREADID_TO_REGISTER 50
DWORD threadIDs[MAX_THREADID_TO_REGISTER];
int threadIDCount = 0;

EXPORT(void) registerCurrentThreadToHandleExceptions(){

	if(threadIDCount == MAX_THREADID_TO_REGISTER){
		logWarn("Maximum registered ThreadID count");
		return;
	}

	threadIDs[threadIDCount] = GetCurrentThreadId();
	threadIDCount ++;
}

static int
isExceptionAReasonForCrashing(LPEXCEPTION_POINTERS exp) {

	int found = 0;
	DWORD currentThread;

	currentThread = GetCurrentThreadId();

	for(int i = 0; i < threadIDCount; i++){
		if(threadIDs[i] == currentThread){
			found = 1;
			break;
		}
	}

	if(getLogLevel() < LOG_WARN){
		return 0;
	}

	if(!found)
		return 0;

	switch(exp->ExceptionRecord->ExceptionCode){
		case EXCEPTION_ACCESS_VIOLATION:
		case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:
		case EXCEPTION_BREAKPOINT:
		case EXCEPTION_DATATYPE_MISALIGNMENT:
		case EXCEPTION_FLT_DENORMAL_OPERAND:
		case EXCEPTION_FLT_DIVIDE_BY_ZERO:
		case EXCEPTION_FLT_INEXACT_RESULT:
		case EXCEPTION_FLT_INVALID_OPERATION:
		case EXCEPTION_FLT_OVERFLOW:
		case EXCEPTION_FLT_STACK_CHECK:
		case EXCEPTION_FLT_UNDERFLOW:
		case EXCEPTION_ILLEGAL_INSTRUCTION:
		case EXCEPTION_IN_PAGE_ERROR:
		case EXCEPTION_INT_DIVIDE_BY_ZERO:
		case EXCEPTION_INT_OVERFLOW:
		case EXCEPTION_INVALID_DISPOSITION:
		case EXCEPTION_NONCONTINUABLE_EXCEPTION:
		case EXCEPTION_PRIV_INSTRUCTION:
		case EXCEPTION_SINGLE_STEP:
		case EXCEPTION_STACK_OVERFLOW:
			return 1;
		default:
			return 0;
	}
}

EXPORT(LONG) CALLBACK customExceptionHandler(LPEXCEPTION_POINTERS exp){
	if(!isExceptionAReasonForCrashing(exp))
		return EXCEPTION_CONTINUE_SEARCH;

	printCrashDebugInformation(exp);

	return EXCEPTION_CONTINUE_SEARCH;
}

void installErrorHandlers(){
	AddVectoredExceptionHandler(0 /*CALL_LAST*/,customExceptionHandler);
}


EXPORT(void) printCrashDebugInformation(LPEXCEPTION_POINTERS exp){
	char date[50];
	char crashdumpFileName[PATH_MAX+1];
	FILE *crashDumpFile;
	SYSTEMTIME localTime;

	crashdumpFileName[0] = 0;

	GetLocalTime(&localTime);

	snprintf(date, 50, "%d-%02d-%02d %02d:%02d:%02d.%03d",
			localTime.wYear,
			localTime.wMonth,
			localTime.wDay,
			localTime.wHour,
			localTime.wMinute,
			localTime.wSecond,
			localTime.wMilliseconds );


	//This is awful but replace the stdout to print all the messages in the file.
	getCrashDumpFilenameInto(crashdumpFileName);
	crashDumpFile = fopen(crashdumpFileName, "a+");
	vm_setVMOutputStream(crashDumpFile);

	reportStackState(exp, date, crashDumpFile);

	vm_setVMOutputStream(stderr);
	fclose(crashDumpFile);

	reportStackState(exp, date, stderr);
	fflush(stdout);
}

char* getExceptionMessage(LPEXCEPTION_POINTERS exp){
	switch(exp->ExceptionRecord->ExceptionCode){
		case EXCEPTION_ACCESS_VIOLATION: return (char*)"EXCEPTION_ACCESS_VIOLATION";
		case EXCEPTION_ARRAY_BOUNDS_EXCEEDED: return (char*)"EXCEPTION_ARRAY_BOUNDS_EXCEEDED";
		case EXCEPTION_BREAKPOINT: return (char*)"EXCEPTION_BREAKPOINT";
		case EXCEPTION_DATATYPE_MISALIGNMENT: return (char*)"EXCEPTION_DATATYPE_MISALIGNMENT";
		case EXCEPTION_FLT_DENORMAL_OPERAND: return (char*)"EXCEPTION_FLT_DENORMAL_OPERAND";
		case EXCEPTION_FLT_DIVIDE_BY_ZERO: return (char*)"EXCEPTION_FLT_DIVIDE_BY_ZERO";
		case EXCEPTION_FLT_INEXACT_RESULT: return (char*)"EXCEPTION_FLT_INEXACT_RESULT";
		case EXCEPTION_FLT_INVALID_OPERATION: return (char*)"EXCEPTION_FLT_INVALID_OPERATION";
		case EXCEPTION_FLT_OVERFLOW: return (char*)"EXCEPTION_FLT_OVERFLOW";
		case EXCEPTION_FLT_STACK_CHECK: return (char*)"EXCEPTION_FLT_STACK_CHECK";
		case EXCEPTION_FLT_UNDERFLOW: return (char*)"EXCEPTION_FLT_UNDERFLOW";
		case EXCEPTION_ILLEGAL_INSTRUCTION: return (char*)"EXCEPTION_ILLEGAL_INSTRUCTION";
		case EXCEPTION_IN_PAGE_ERROR: return (char*)"EXCEPTION_IN_PAGE_ERROR";
		case EXCEPTION_INT_DIVIDE_BY_ZERO: return (char*)"EXCEPTION_INT_DIVIDE_BY_ZERO";
		case EXCEPTION_INT_OVERFLOW: return (char*)"EXCEPTION_INT_OVERFLOW";
		case EXCEPTION_INVALID_DISPOSITION: return (char*)"EXCEPTION_INVALID_DISPOSITION";
		case EXCEPTION_NONCONTINUABLE_EXCEPTION: return (char*)"EXCEPTION_NONCONTINUABLE_EXCEPTION";
		case EXCEPTION_PRIV_INSTRUCTION: return (char*)"EXCEPTION_PRIV_INSTRUCTION";
		case EXCEPTION_SINGLE_STEP: return (char*)"EXCEPTION_SINGLE_STEP";
		case EXCEPTION_STACK_OVERFLOW: return (char*)"EXCEPTION_STACK_OVERFLOW";
		default:
			return (char*)"Unknown Exception";
	}
}

void reportStackState(LPEXCEPTION_POINTERS exp, char* date, FILE* output){

	fprintf(output,"\n%s(%ld) at 0x%016llx - %s\n\n", getExceptionMessage(exp), exp->ExceptionRecord->ExceptionCode, (unsigned long long)exp->ExceptionRecord->ExceptionAddress, date);
	fprintf(output,"%s\n%s\n\n", GetAttributeString(0), getVersionInfo(1));


	fprintf(output,"C stack backtrace & registers:\n");

	CONTEXT ctx;

	RtlCaptureContext(&ctx);

	printRegisterState(&ctx, output);

	printMachineCallStack(&ctx, output);

}

int stackCaptureInitialized = 0;

int ensureInitialized(){

	if(stackCaptureInitialized)
		return stackCaptureInitialized;

	stackCaptureInitialized = SymInitialize(GetCurrentProcess(), NULL, TRUE) == TRUE;

	return stackCaptureInitialized;
}

void captureStack(PCONTEXT context, STACKFRAME64* frames, int framePointersSize, int frameSkip){

	ensureInitialized();

	STACKFRAME64 frame;

	ZeroMemory(&frame, sizeof(frame));
	frame.AddrPC.Mode = AddrModeFlat;
	frame.AddrFrame.Mode = AddrModeFlat;
	frame.AddrStack.Mode = AddrModeFlat;
#if defined(_M_ARM64)
	frame.AddrPC.Offset = context->Pc;
	frame.AddrFrame.Offset = context->Fp;
	frame.AddrStack.Offset = context->Sp;
#elif defined(_WIN64)
	frame.AddrPC.Offset = context->Rip;
	frame.AddrFrame.Offset = context->Rbp;
	frame.AddrStack.Offset = context->Rsp;
#else
	frame.AddrPC.Offset = context->Eip;
	frame.AddrFrame.Offset = context->Ebp;
	frame.AddrStack.Offset = context->Esp;
#endif
	size_t i;
	for (i = 0; i < framePointersSize + frameSkip; i++){
		if (StackWalk64(IMAGE_FILE_MACHINE_AMD64,
				GetCurrentProcess(),
				GetCurrentThread(),
				&frame,
				context,
				NULL,
				SymFunctionTableAccess64,
				SymGetModuleBase64,
				NULL)){

			if (i >= frameSkip){
				memcpy(&(frames[i - frameSkip]), &frame, sizeof(STACKFRAME64));
			}
		} else {
			break;
		}
	}

}

#define NUMBER_OF_STACKS 32

void printSymbolInfo(STACKFRAME64 *frame, FILE* output){

	DWORD64 displacement64;
	DWORD displacement;

	//The SYMBOL_INFO has additional space after for the name of the Symbol
	char symbol_buffer[sizeof(SYMBOL_INFO) + 256];
	SYMBOL_INFO* symbol = (SYMBOL_INFO*)symbol_buffer;

	symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
	symbol->MaxNameLen = 255;

	IMAGEHLP_LINE64 line;
	line.SizeOfStruct = sizeof(IMAGEHLP_LINE64);

	fprintf(output, "[0x%016llX] ", frame->AddrPC.Offset);

	//If I find the function name I print it.
	if (SymFromAddr(GetCurrentProcess(), frame->AddrPC.Offset, &displacement64, symbol)) {
		fprintf(output, "%s", symbol->Name);

		if (SymGetLineFromAddr64(GetCurrentProcess(), frame->AddrPC.Offset, &displacement, &line)) {
			fprintf(output, " (%s:%ld)", line.FileName, line.LineNumber);
		}
		fprintf(output, "\n");
	}else{
#if COGVM
		printCogMethodFor(frame->AddrPC.Offset);
#else
		fprintf(output, "Cannot identify frame method");
#endif
	}

}

EXPORT(void) printMachineCallStack(PCONTEXT ctx, FILE* output){

	STACKFRAME64 frames[NUMBER_OF_STACKS];
	ZeroMemory(frames, sizeof(STACKFRAME64) * NUMBER_OF_STACKS);

	captureStack(ctx, frames, NUMBER_OF_STACKS, 6);

	fprintf(output,"\n\nC Callstack:\n\n");

	int i;
	for(i = 0; i< NUMBER_OF_STACKS; i++){

		if(frames[i].AddrPC.Offset == 0)
			break;

		printSymbolInfo(&(frames[i]), output);
	}

#if COGVM

	//	/* Do not attempt to report the stack until the VM is initialized!! */
	//	if (!*(char **)stackLimitAddress()){
	//		fprintf(output,"The VM is not initialized, cannot print the stack trace");
	//		return;
	//	}


	void *fp = (void *)(frames[0].AddrFrame.Offset); //RBP
	void *sp = (void *)(frames[0].AddrStack.Offset); //RSP

	char *savedSP, *savedFP;

	ifValidWriteBackStackPointersSaveTo(fp,sp,&savedFP,&savedSP);
#endif /* COGVM */

	fprintf(output, "\n\nAll Smalltalk process stacks (active first):\n");
	fflush(output);

	printAllStacks();

#if COGVM
	/* Now restore framePointer and stackPointer via same function */
	ifValidWriteBackStackPointersSaveTo(savedFP,savedSP,0,0);
#endif


	fflush(output);
}

EXPORT(void) printRegisterState(PCONTEXT regs, FILE* output){

	fprintf(output,"\n\nRegisters:\n");

#if _M_IX86
	fprintf(output,
		"ContextFlags: 0x%016lx\n"
		"\teax 0x%016lx ebx 0x%016lx ecx 0x%016lx edx 0x%016lx\n"
		"\tedi 0x%016lx esi 0x%016lx ebp 0x%016lx esp 0x%016lx\n"
		"\trip 0x%016lx\n",
		regs->ContextFlags,
		regs->Eax, regs->Ebx, regs->Ecx, regs->Edx,
		regs->Edi, regs->Esi, regs->Ebp, regs->Esp,
		regs->Eip);
#elif _M_ARM64
	fprintf(output,
		"ContextFlags: 0x%016lx\n"
		"\tX0 0x%016lx X1 0x%016lx X2 0x%016lx X3 0x%016lx\n"
		"\tX4 0x%016lx X5 0x%016lx X6 0x%016lx X7 0x%016lx\n"
		"\tX8 0x%016lx X9 0x%016lx X10 0x%016lx X11 0x%016lx\n"
		"\tX12 0x%016lx X13 0x%016lx X14 0x%016lx X15 0x%016lx\n"
		"\tX16 0x%016lx X17 0x%016lx X16 0x%016lx X17 0x%016lx\n"
		"\tX20 0x%016lx X21 0x%016lx X22 0x%016lx X23 0x%016lx\n"
		"\tX24 0x%016lx X25 0x%016lx X26 0x%016lx X27 0x%016lx\n"
		"\tX28 0x%016lx FP 0x%016lx LR 0x%016lx SP 0x%016lx\n"
		"\tPC 0x%016lx\n",
		regs->ContextFlags,
		regs->X0, regs->X1, regs->X2, regs->X3,
		regs->X4, regs->X5, regs->X6, regs->X7,
		regs->X8, regs->X9, regs->X10, regs->X11,
		regs->X12, regs->X13, regs->X14, regs->X15,
		regs->X16, regs->X17, regs->X18, regs->X19,
		regs->X20, regs->X21, regs->X22, regs->X23,
		regs->X24, regs->X25, regs->X26, regs->X27,
		regs->X28, regs->Fp, regs->Lr, regs->Sp,
		regs->Pc);
#else
	fprintf(output,
			"ContextFlags: 0x%016llx\n"
			"\trax 0x%016llx rbx 0x%016llx rcx 0x%016llx rdx 0x%016llx\n"
			"\trdi 0x%016llx rsi 0x%016llx rbp 0x%016llx rsp 0x%016llx\n"
			"\tr8  0x%016llx r9  0x%016llx r10 0x%016llx r11 0x%016llx\n"
			"\tr12 0x%016llx r13 0x%016llx r14 0x%016llx r15 0x%016llx\n"
			"\trip 0x%016llx\n",
			regs->ContextFlags,
			regs->Rax, regs->Rbx, regs->Rcx, regs->Rdx,
			regs->Rdi, regs->Rsi, regs->Rbp, regs->Rsp,
			regs->R8 , regs->R9 , regs->R10, regs->R11,
			regs->R12, regs->R13, regs->R14, regs->R15,
			regs->Rip);
#endif
}
