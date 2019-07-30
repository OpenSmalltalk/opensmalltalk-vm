#include <pharo.h>
#include <Windows.h>

void pushOutputFile(FILE* aFile);
void popOutputFile();

//Previous Top Level Filter
static LPTOP_LEVEL_EXCEPTION_FILTER TopLevelFilter = NULL;
LONG CALLBACK customExceptionHandler(LPEXCEPTION_POINTERS exp);

void printCrashDebugInformation(LPEXCEPTION_POINTERS exp);
void reportStackState(LPEXCEPTION_POINTERS exp, char* date, FILE* output);
void printRegisterState(LPEXCEPTION_POINTERS exp, FILE* output);

#if COGVM
	usqInt stackLimitAddress(void);
#endif


EXPORT(void) installErrorHandlers(){
	TopLevelFilter = SetUnhandledExceptionFilter(customExceptionHandler);
}


LONG CALLBACK customExceptionHandler(LPEXCEPTION_POINTERS exp){
    printCrashDebugInformation(exp);

    if(TopLevelFilter)
    	return TopLevelFilter(exp);
    else
    	return EXCEPTION_CONTINUE_SEARCH;
}

void printCrashDebugInformation(LPEXCEPTION_POINTERS exp){
	char date[50];
	char crashdumpFileName[PATH_MAX+1];
	FILE *crashDumpFile;
	SYSTEMTIME localTime;

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
	pushOutputFile(crashDumpFile);

	reportStackState(exp, date, crashDumpFile);

	popOutputFile();
	fclose(crashDumpFile);

	reportStackState(exp, date, stderr);

}

char* getExceptionMessage(LPEXCEPTION_POINTERS exp){
	switch(exp->ExceptionRecord->ExceptionCode){
		case EXCEPTION_ACCESS_VIOLATION: return "EXCEPTION_ACCESS_VIOLATION";
		case EXCEPTION_ARRAY_BOUNDS_EXCEEDED: return "EXCEPTION_ARRAY_BOUNDS_EXCEEDED";
		case EXCEPTION_BREAKPOINT: return "EXCEPTION_BREAKPOINT";
		case EXCEPTION_DATATYPE_MISALIGNMENT: return "EXCEPTION_DATATYPE_MISALIGNMENT";
		case EXCEPTION_FLT_DENORMAL_OPERAND: return "EXCEPTION_FLT_DENORMAL_OPERAND";
		case EXCEPTION_FLT_DIVIDE_BY_ZERO: return "EXCEPTION_FLT_DIVIDE_BY_ZERO";
		case EXCEPTION_FLT_INEXACT_RESULT: return "EXCEPTION_FLT_INEXACT_RESULT";
		case EXCEPTION_FLT_INVALID_OPERATION: return "EXCEPTION_FLT_INVALID_OPERATION";
		case EXCEPTION_FLT_OVERFLOW: return "EXCEPTION_FLT_OVERFLOW";
		case EXCEPTION_FLT_STACK_CHECK: return "EXCEPTION_FLT_STACK_CHECK";
		case EXCEPTION_FLT_UNDERFLOW: return "EXCEPTION_FLT_UNDERFLOW";
		case EXCEPTION_ILLEGAL_INSTRUCTION: return "EXCEPTION_ILLEGAL_INSTRUCTION";
		case EXCEPTION_IN_PAGE_ERROR: return "EXCEPTION_IN_PAGE_ERROR";
		case EXCEPTION_INT_DIVIDE_BY_ZERO: return "EXCEPTION_INT_DIVIDE_BY_ZERO";
		case EXCEPTION_INT_OVERFLOW: return "EXCEPTION_INT_OVERFLOW";
		case EXCEPTION_INVALID_DISPOSITION: return "EXCEPTION_INVALID_DISPOSITION";
		case EXCEPTION_NONCONTINUABLE_EXCEPTION: return "EXCEPTION_NONCONTINUABLE_EXCEPTION";
		case EXCEPTION_PRIV_INSTRUCTION: return "EXCEPTION_PRIV_INSTRUCTION";
		case EXCEPTION_SINGLE_STEP: return "EXCEPTION_SINGLE_STEP";
		case EXCEPTION_STACK_OVERFLOW: return "EXCEPTION_STACK_OVERFLOW";
		default:
			return "Unknown Exception";
	}
}

void reportStackState(LPEXCEPTION_POINTERS exp, char* date, FILE* output){

	fprintf(output,"\n%s(%d) at 0x%016llx - %s\n\n", getExceptionMessage(exp), exp->ExceptionRecord->ExceptionCode, exp->ExceptionRecord->ExceptionAddress, date);
	fprintf(output,"%s\n%s\n\n", GetAttributeString(0), getVersionInfo(1));

#if COGVM
	/* Do not attempt to report the stack until the VM is initialized!! */
	if (!*(char **)stackLimitAddress()){
		fprintf(output,"The VM is not initialized, cannot print the stack trace");
		return;
	}
#endif

	fprintf(output,"C stack backtrace & registers:\n");

	printRegisterState(exp, output);
}

void printRegisterState(LPEXCEPTION_POINTERS exp, FILE* output){
	#ifdef	defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
	#error Sorry Only X86 64bits windows!
	#endif

	LPCONTEXT regs = exp->ContextRecord;

	fprintf(output,
			"\trax 0x%016llx rbx 0x%016llx rcx 0x%016llx rdx 0x%016llx\n"
			"\trdi 0x%016llx rsi 0x%016llx rbp 0x%016llx rsp 0x%016llx\n"
			"\tr8  0x%016llx r9  0x%016llx r10 0x%016llx r11 0x%016llx\n"
			"\tr12 0x%016llx r13 0x%016llx r14 0x%016llx r15 0x%016llx\n"
			"\trip 0x%016llx\n",
			regs->Rax, regs->Rbx, regs->Rcx, regs->Rdx,
			regs->Rdi, regs->Rdi, regs->Rbp, regs->Rsp,
			regs->R8 , regs->R9 , regs->R10, regs->R11,
			regs->R12, regs->R13, regs->R14, regs->R15,
			regs->Rip);
}
