/* sqPlatformSpecific-Win32.c -- Platform specific interface implementation for Windows
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

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <float.h>

#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <fcntl.h> /* _O_BINARY */
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "sqWin32Backtrace.h"
#include "config.h"

# define fopen_for_append(filename) fopen(filename,"a+t")

/* default fpu control word and mask:
   _MCW_RC: Rounding control
       _RC_NEAR: round to nearest
   _MCW_PC: Precision control
       _PC_53:  double precision arithmetic (instead of extended)
   _MCW_EM: Interupt exception mask
       _EM_XXX: silent operations (no signals please)
   https://docs.microsoft.com/en-us/previous-versions/e9b52ceh%28v%3dvs.140%29
*/

#if !defined(_MCW_PC)
// x64 does not support _MCW_PC
// The x64 CPU hardware default is 64-bit precision mode (80-bit long double);
// Microsoft expects software to set 53-bit mode before any user mode x87 instructions
// are reached. Microsoft made a change in responsibility for initializing precision mode
// in the X64 OS. The X64 OS sets 53-bit mode prior to starting your .exe, where the 32-bit OS
// expected the program to make that initialization.
# define _MCW_PC 0
#endif

/* default fpu control word:
   _RC_NEAR: round to nearest
   _PC_53 :  double precision arithmetic (instead of extended)
   _EM_XXX: silent operations (no signals please)
   NOTE:  precision control and infinity control are not defined on ARM or X64 (SSE oblige), only X86
*/
#if defined(_M_IX86) || defined(X86) || defined(_M_I386) || defined(_X86_) \
	|| defined(i386) || defined(i486) || defined(i586) || defined(i686) \
	|| defined(__i386__) || defined(__386__) || defined(I386)
#define FPU_MASK (_MCW_EM | _MCW_RC | _MCW_PC | _MCW_IC)
#define FPU_DEFAULT (_RC_NEAR + _PC_53 + _EM_INVALID + _EM_ZERODIVIDE + _EM_OVERFLOW + _EM_UNDERFLOW + _EM_INEXACT + _EM_DENORMAL)
#else
#define FPU_DEFAULT (_RC_NEAR + _EM_INVALID + _EM_ZERODIVIDE + _EM_OVERFLOW + _EM_UNDERFLOW + _EM_INEXACT + _EM_DENORMAL)
#define FPU_MASK    (_MCW_EM | _MCW_RC)
#endif

#define MAXFRAMES 64

/****************************************************************************/
/*                     Exception handling                                   */
/****************************************************************************/
/* The following installs us a global exception filter for *all* exceptions */
/* in Squeak. This is necessary since the C support of Mingw32 for SEH is   */
/* not as sophisticated as MSVC's support. However, with this new handling  */
/* scheme the entire thing becomes actually a lot simpler...                */
/****************************************************************************/
static LPTOP_LEVEL_EXCEPTION_FILTER TopLevelFilter = NULL;

/* forwarded declaration */
static void printCrashDebugInformation(LPEXCEPTION_POINTERS exp);

#ifndef PROCESS_SYSTEM_DPI_AWARE
#define PROCESS_SYSTEM_DPI_AWARE 1
#endif

#ifndef PROCESS_PER_MONITOR_DPI_AWARE
#define PROCESS_PER_MONITOR_DPI_AWARE 2
#endif

typedef HRESULT (WINAPI *SetProcessDpiAwarenessFunctionPointer) (int awareness);

extern int ioIsHeadless(void);
extern const char *getVersionInfo(int verbose);
extern LONG CALLBACK sqExceptionFilter(LPEXCEPTION_POINTERS exp);

HANDLE vmWakeUpEvent = 0;

static void
enableHighDPIAwareness()
{
    SetProcessDpiAwarenessFunctionPointer setProcessDpiAwareness;
    HMODULE shcore;

    /* Load the library with the DPI awareness library */
    shcore = LoadLibraryA("Shcore.dll");
    if(!shcore)
        return;

    /* Get a function pointer to the set DPI awareness function. */
    setProcessDpiAwareness = (SetProcessDpiAwarenessFunctionPointer)GetProcAddress(shcore, "SetProcessDpiAwareness");
    if(!setProcessDpiAwareness)
    {
        FreeLibrary(shcore);
        return;
    }

    /* Set the DPI awareness. */
    if(setProcessDpiAwareness(PROCESS_PER_MONITOR_DPI_AWARE) != S_OK)
        setProcessDpiAwareness(PROCESS_SYSTEM_DPI_AWARE);

    FreeLibrary(shcore);
}

void
ioInitPlatformSpecific(void)
{
    /* Setup the FPU */
    _controlfp(FPU_DEFAULT, FPU_MASK);

    /* Create the wake up event. */
    vmWakeUpEvent = CreateEvent(NULL, 1, 0, NULL);

    /* Use UTF-8 for the console. */
    if (GetConsoleCP())
    {
        SetConsoleCP(CP_UTF8);
        SetConsoleOutputCP(CP_UTF8);
    }

    enableHighDPIAwareness();
}

void
aioInit(void)
{
}

long
aioPoll(long microSeconds)
{
    return 0;
}

/* New filename converting function; used by the interpreterProxy function
ioFilenamefromStringofLengthresolveAliases. Most platforms can ignore the
resolveAlias boolean - it seems to only be of use by OSX but is crucial there.
*/
sqInt
sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean)
{
    memcpy(aCharBuffer, aFilenameString, filenameLength);
    aCharBuffer[filenameLength] = 0;
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
    /* wake us up if something happens */
    ResetEvent(vmWakeUpEvent);
    MsgWaitForMultipleObjects(1, &vmWakeUpEvent, FALSE,
  			    microSeconds / 1000, QS_ALLINPUT);
    ioProcessEvents(); /* keep up with mouse moves etc. */
    return microSeconds;
}

/* NOTE: Why do we need this? When running multi-threaded code such as in
the networking code and in midi primitives
we will signal the interpreter several semaphores.
(Predates the internal synchronization of signalSemaphoreWithIndex ()) */

int
synchronizedSignalSemaphoreWithIndex(int semaIndex)
{
    int result;

    /* Do our job - this is now synchronized in signalSemaphoreWithIndex */
    result = signalSemaphoreWithIndex(semaIndex);
    /* wake up interpret() if sleeping */
    SetEvent(vmWakeUpEvent);
    return result;
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

void
findExecutablePath(const char *localVmName, char *dest, size_t destSize)
{
    const char *lastSeparator = strrchr(localVmName, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(localVmName, '\\');
    if (!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif

    if (!sqIsAbsolutePath(localVmName))
    {
        /* TODO: Get the current working directory*/
        strcpy(dest, "./");
    }
	else
	{
		*dest = 0;
	}

    if (lastSeparator)
        strncat(dest, localVmName, lastSeparator - localVmName + 1);
}

#if COGVM
#include <signal.h>

// Support code for Cog.
// a) Answer whether the C frame pointer is in use, for capture of the C stack
//    pointers.
// b) answer the amount of headroom to ensure in a Cog stack page, including
//    the size of the redzone, if any. This allows signal/interrupt delivery
//    while executing jitted Smalltalk code.

int
isCFramePointerInUse(usqIntptr_t *cFrmPtrPtr, usqIntptr_t *cStkPtrPtr)
{
	extern void (*ceCaptureCStackPointers)(void);
	usqIntptr_t currentCSP = *cStkPtrPtr;

	ceCaptureCStackPointers();
	assert(*cStkPtrPtr < currentCSP);
	return *cFrmPtrPtr >= *cStkPtrPtr && *cFrmPtrPtr <= currentCSP;
}

// Answer an approximation of the size of the redzone (if any).  Do so by
// sending a signal to the process and computing the difference between the
// stack pointer in the signal handler and that in the caller. Assumes stacks
// descend.

#if !defined(min)
# define min(x,y) (((x)>(y))?(y):(x))
#endif
static char * volatile p = 0;

static void
sighandler(int sig) { p = (char *)&sig; }

static int
getRedzoneSize()
{
#if defined(SIGPROF) /* cygwin */
    struct sigaction handler_action, old;
    handler_action.sa_sigaction = sighandler;
    handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&handler_action.sa_mask);
    (void)sigaction(SIGPROF, &handler_action, &old);

    do kill(getpid(), SIGPROF); while (!p);
    (void)sigaction(SIGPROF, &old, 0);
    return (char *)min(&old, &handler_action) - p;
#else /* cygwin */
    void(*old)(int) = signal(SIGBREAK, sighandler);

    do raise(SIGBREAK); while (!p);
    return (char *)&old - p;
#endif /* cygwin */
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
#endif // COGVM

#error "the new exception handling code from platforms/win32/vm/sqWin32Main.c needs to be integrated here. eem 2021/9/28"

static LONG CALLBACK squeakExceptionHandler(LPEXCEPTION_POINTERS exp)
{
    DWORD result;

    /* #1: Try to handle exception in the regular (memory access)
     exception filter if virtual memory support is enabled */
#ifndef NO_VIRTUAL_MEMORY
    result = sqExceptionFilter(exp);
#else
    result = EXCEPTION_CONTINUE_SEARCH;
#endif

    /* #2: If that didn't work, try to handle any FP problems */
    if(result != EXCEPTION_CONTINUE_EXECUTION)
    {
        DWORD code = exp->ExceptionRecord->ExceptionCode;
        if((code >= EXCEPTION_FLT_DENORMAL_OPERAND) && (code <= EXCEPTION_FLT_UNDERFLOW))
        {
              /* in case FFI callout to foreign code changed FP mode              */
              /* restore our default masking of exceptions in the FPU and proceed */
              _controlfp(FPU_DEFAULT, FPU_MASK);
              result = EXCEPTION_CONTINUE_EXECUTION;
        }
    }

    /* #3: If that didn't work either try passing it on to the old
     top-level filter */
    if(result != EXCEPTION_CONTINUE_EXECUTION)
    {
        if(TopLevelFilter)
            result = TopLevelFilter(exp);
    }

    /* #4: If that didn't work either give up and print a crash debug information */
#if defined(NDEBUG) || defined(__MINGW32__)
    if(result != EXCEPTION_CONTINUE_EXECUTION)
    {
        printCrashDebugInformation(exp);
        result = EXCEPTION_EXECUTE_HANDLER;
    }
#endif

    return result;
}

void
InstallExceptionHandler(void)
{
    TopLevelFilter = SetUnhandledExceptionFilter(squeakExceptionHandler);
}

void
UninstallExceptionHandler(void)
{
    SetUnhandledExceptionFilter(TopLevelFilter);
    TopLevelFilter = NULL;
}

int
sqExecuteFunctionWithCrashExceptionCatching(sqFunctionThatCouldCrash function, void *userdata)
{
    int result = 0;

#if !NO_FIRST_LEVEL_EXCEPTION_HANDLER
#   ifndef _MSC_VER
    /* Install our top-level exception handler */
    InstallExceptionHandler();
#   else
    __try
    {
#   endif
#endif /* !NO_FIRST_LEVEL_EXCEPTION_HANDLER */

        result = function(userdata);

#if !NO_FIRST_LEVEL_EXCEPTION_HANDLER
#   ifdef _MSC_VER
    } __except(squeakExceptionHandler(GetExceptionInformation())) {
        /* Do nothing */
    }
#   else
    /* remove the top-level exception handler */
    UninstallExceptionHandler();
#   endif
#endif /* !NO_FIRST_LEVEL_EXCEPTION_HANDLER */

    return result;
}

static void
dumpStackIfInMainThread(FILE *optionalFile)
{
	if (!optionalFile) {
		dumpStackIfInMainThread(stdout);
		return;
	}
	if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
		fprintf(optionalFile, "\n\nSmalltalk stack dump:\n");
		printCallStackOn(optionalFile);
		fprintf(optionalFile,"\n");
	}
	else
		fprintf(optionalFile,"\nCan't dump Smalltalk stack. Not in VM thread\n");
}

#if COGVM
static void
dumpPrimTrace(FILE *optionalFile)
{
	if (!optionalFile) {
		dumpPrimTrace(stdout);
		return;
	}
	fprintf(optionalFile,"\nPrimitive trace:\n");
	dumpPrimTraceLogOn(optionalFile);
	fprintf(optionalFile,"\n");
}
#else
# define dumpPrimTrace(f) 0
#endif


void
printCommonCrashDumpInfo(FILE *f) {

    /*fprintf(f,"\n\n%s", hwInfoString);
    fprintf(f,"\n%s", osInfoString);
    fprintf(f,"\n%s", gdInfoString);
    */

    /* print VM version information */
    fprintf(f,"%s\n", getVersionInfo(1));
    fflush(f);
    fprintf(f,"\n"
	    "Current byte code: %d\n"
	    "Primitive index: %" PRIdSQINT "\n",
	    getCurrentBytecode(),
	    methodPrimitiveIndex());
    fflush(f);
    /* print loaded plugins */
    fprintf(f,"\nLoaded plugins:\n");
    {
      int index = 1;
      char *pluginName;
      while( (pluginName = ioListLoadedModule(index)) != NULL) {
	fprintf(f,"\t%s\n", pluginName);
	fflush(f);
	index++;
      }
    }

    printModuleInfo(f);
	fflush(f);
}

static void
printCrashDebugInformation(LPEXCEPTION_POINTERS exp)
{
  void *callstack[MAXFRAMES];
  symbolic_pc symbolic_pcs[MAXFRAMES];
  int nframes, inVMThread;
  char crashInfo[1024];
  FILE *f;
  int byteCode = -2;

  UninstallExceptionHandler();

  if ((inVMThread = ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())))
    /* Retrieve current byte code.
     If this fails the IP is probably wrong */
    TRY {
      byteCode = getCurrentBytecode();
    } EXCEPT(EXCEPTION_EXECUTE_HANDLER) {
      byteCode = -1;
    }

    TRY {
#if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
        if (inVMThread)
            ifValidWriteBackStackPointersSaveTo((void *)exp->ContextRecord->Ebp,
            									(void *)exp->ContextRecord->Esp,
            									0,
            									0);
        callstack[0] = (void *)exp->ContextRecord->Eip;
        nframes = backtrace_from_fp((void*)exp->ContextRecord->Ebp,
        						callstack+1,
        						MAXFRAMES-1);
#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
        if (inVMThread)
            ifValidWriteBackStackPointersSaveTo((void *)exp->ContextRecord->Rbp,
            									(void *)exp->ContextRecord->Rsp,
            									0,
            									0);
        callstack[0] = (void *)exp->ContextRecord->Rip;
        nframes = backtrace_from_fp((void*)exp->ContextRecord->Rbp,
        						callstack+1,
        						MAXFRAMES-1);
#else
#   error "unknown architecture, cannot dump stack"
#endif
        symbolic_backtrace(++nframes, callstack, symbolic_pcs);
        sqFatalErrorPrintfNoExit(
"Sorry but the VM has crashed.\n\n\
Exception code: %08X\n\
Exception address: %08X\n\
Current byte code: %d\n\
Primitive index: %d\n\n\
Crashed in %s thread\n\n\
This information will be stored in the file\n\
%s\\%s\n\
with a complete stack dump",
             exp->ExceptionRecord->ExceptionCode,
             exp->ExceptionRecord->ExceptionAddress,
             byteCode,
             methodPrimitiveIndex(),
             inVMThread ? L"the VM" : L"some other",
             "."/*vmLogDirA*/,
             "crash.dmp");

         /* TODO: prepend the log directory to the crash.dmp file. */
        f = fopen_for_append("crash.dmp");
        printf("File for crash.dmp: %p\n", f);
        if(f)
        {
            time_t crashTime = time(NULL);
            fprintf(f,"---------------------------------------------------------------------\n");
            fprintf(f,"%s\n", ctime(&crashTime));
            /* Print the exception code */
            fprintf(f,"Exception code: %08lX\nException addr: %0*" PRIXSQPTR "\n",
                exp->ExceptionRecord->ExceptionCode,
            	(int) sizeof(exp->ExceptionRecord->ExceptionAddress)*2,
                (usqIntptr_t) exp->ExceptionRecord->ExceptionAddress);
            if(exp->ExceptionRecord->ExceptionCode == EXCEPTION_ACCESS_VIOLATION) {
                /* For access violations print what actually happened */
                fprintf(f,"Access violation (%s) at %0*" PRIXSQPTR "\n",
                	(exp->ExceptionRecord->ExceptionInformation[0] ? "write access" : "read access"),
                	(int) sizeof(exp->ExceptionRecord->ExceptionInformation[1])*2,
                	exp->ExceptionRecord->ExceptionInformation[1]);
            }
#if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
            fprintf(f,"EAX:%08lX\tEBX:%08lX\tECX:%08lX\tEDX:%08lX\n",
                exp->ContextRecord->Eax,
                exp->ContextRecord->Ebx,
                exp->ContextRecord->Ecx,
                exp->ContextRecord->Edx);
            fprintf(f,"ESI:%08lX\tEDI:%08lX\tEBP:%08lX\tESP:%08lX\n",
                exp->ContextRecord->Esi,
                exp->ContextRecord->Edi,
                exp->ContextRecord->Ebp,
                exp->ContextRecord->Esp);
            fprintf(f,"EIP:%08lX\tEFL:%08lX\n",
                exp->ContextRecord->Eip,
                exp->ContextRecord->EFlags);
            fprintf(f,"FP Control: %08lX\nFP Status:  %08lX\nFP Tag:     %08lX\n",
                exp->ContextRecord->FloatSave.ControlWord,
                exp->ContextRecord->FloatSave.StatusWord,
                exp->ContextRecord->FloatSave.TagWord);
#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
            fprintf(f,"RAX:%016" PRIxSQPTR "\tRBX:%016" PRIxSQPTR "\tRCX:%016" PRIxSQPTR "\tRDX:%016" PRIxSQPTR "\n",
                exp->ContextRecord->Rax,
                exp->ContextRecord->Rbx,
                exp->ContextRecord->Rcx,
                exp->ContextRecord->Rdx);
            fprintf(f,"RSI:%016" PRIxSQPTR "\tRDI:%016" PRIxSQPTR "\tRBP:%016" PRIxSQPTR "\tRSP:%016" PRIxSQPTR "\n",
                exp->ContextRecord->Rsi,
                exp->ContextRecord->Rdi,
                exp->ContextRecord->Rbp,
                exp->ContextRecord->Rsp);
            fprintf(f,"R8 :%016" PRIxSQPTR "\tR9 :%016" PRIxSQPTR "\tR10:%016" PRIxSQPTR "\tR11:%016" PRIxSQPTR "\n",
                exp->ContextRecord->R8,
                exp->ContextRecord->R9,
                exp->ContextRecord->R10,
                exp->ContextRecord->R11);
            fprintf(f,"R12:%016" PRIxSQPTR "\tR13:%016" PRIxSQPTR "\tR14:%016" PRIxSQPTR "\tR15:%016" PRIxSQPTR "\n",
                exp->ContextRecord->R12,
                exp->ContextRecord->R13,
                exp->ContextRecord->R14,
                exp->ContextRecord->R15);
            fprintf(f,"RIP:%016" PRIxSQPTR "\tEFL:%08lx\n",
                exp->ContextRecord->Rip,
                exp->ContextRecord->EFlags);
            fprintf(f,"FP Control: %08x\nFP Status:  %08x\nFP Tag:     %08x\n",
                exp->ContextRecord->FltSave.ControlWord,
                exp->ContextRecord->FltSave.StatusWord,
                exp->ContextRecord->FltSave.TagWord);
#else
#error "unknown architecture, cannot pick dump registers"
#endif

            fprintf(f, "\n\nCrashed in %s thread\n\n",
            		inVMThread ? "the VM" : "some other");

            printCommonCrashDumpInfo(f);
            dumpPrimTrace(f);
            print_backtrace(f, nframes, MAXFRAMES, callstack, symbolic_pcs);
            dumpStackIfInMainThread(f);
            fclose(f);
        }

        /* print recently called prims to stdout */
        dumpPrimTrace(0);
        /* print C stack to stdout */
        print_backtrace(stdout, nframes, MAXFRAMES, callstack, symbolic_pcs);
        /* print the caller's stack to stdout */
        dumpStackIfInMainThread(0);
#if COGVM
        reportMinimumUnusedHeadroom();
#endif
    } EXCEPT(EXCEPTION_EXECUTE_HANDLER) {
        sqFatalErrorPrintf("The VM has crashed. Sorry");
    }
}

/************************************************************************************************************/
/* few addtional definitions for those having older include files especially #include <fileextd.h>          */
/************************************************************************************************************/
#if (WINVER < 0x0600)
	 /*Copied from winbase.h*/
	 typedef struct _FILE_NAME_INFO {
		 DWORD FileNameLength;
		 WCHAR FileName[1];
	 } FILE_NAME_INFO, *PFILE_NAME_INFO;
	 typedef enum _FILE_INFO_BY_HANDLE_CLASS {
		 FileBasicInfo = 0,
		 FileStandardInfo = 1,
		 FileNameInfo = 2,
		 FileRenameInfo = 3,
		 FileDispositionInfo = 4,
		 FileAllocationInfo = 5,
		 FileEndOfFileInfo = 6,
		 FileStreamInfo = 7,
		 FileCompressionInfo = 8,
		 FileAttributeTagInfo = 9,
		 FileIdBothDirectoryInfo = 10, // 0xA
		 FileIdBothDirectoryRestartInfo = 11, // 0xB
		 FileIoPriorityHintInfo = 12, // 0xC
		 FileRemoteProtocolInfo = 13, // 0xD
		 FileFullDirectoryInfo = 14, // 0xE
		 FileFullDirectoryRestartInfo = 15, // 0xF
		 FileStorageInfo = 16, // 0x10
		 FileAlignmentInfo = 17, // 0x11
		 FileIdInfo = 18, // 0x12
		 FileIdExtdDirectoryInfo = 19, // 0x13
		 FileIdExtdDirectoryRestartInfo = 20, // 0x14
		 MaximumFileInfoByHandlesClass
	 } FILE_INFO_BY_HANDLE_CLASS, *PFILE_INFO_BY_HANDLE_CLASS;
#endif //(WINVER < 0x0600)

/*
* Allow to test if the standard input/output files are from a console or not
* Inspired of: https://fossies.org/linux/misc/vim-8.0.tar.bz2/vim80/src/iscygpty.c?m=t
* Return values:
* -1 - Error
* 0 - no console (windows only)
* 1 - normal terminal (unix terminal / windows console)
* 2 - pipe
* 3 - file
* 4 - cygwin terminal (windows only)
*/
sqInt
fileHandleType(HANDLE fdHandle) {
   if (fdHandle == INVALID_HANDLE_VALUE) {
       return -1;
   }

   /* In case of Windows Shell case */
   DWORD fileType = GetFileType(fdHandle);
   if (fileType == FILE_TYPE_CHAR)
       /* The specified file is a character file, typically an LPT device or a console. */
       /* https://msdn.microsoft.com/en-us/library/windows/desktop/aa364960(v=vs.85).aspx */
       return 1;

   /* In case of Unix emulator, we need to parse the name of the pipe */

   /* Cygwin/msys's pty is a pipe. */
   if (fileType != FILE_TYPE_PIPE) {
       if (fileType == FILE_TYPE_DISK)
           return 3; //We have a file here
       if (fileType == FILE_TYPE_UNKNOWN && GetLastError() == ERROR_INVALID_HANDLE)
           return  0; //No stdio allocated
       return  -1;
   }

   int size = sizeof(FILE_NAME_INFO) + sizeof(WCHAR) * MAX_PATH;
   FILE_NAME_INFO *nameinfo;
   WCHAR *p = NULL;

   typedef BOOL(WINAPI *pfnGetFileInformationByHandleEx)(
       HANDLE                    hFile,
       FILE_INFO_BY_HANDLE_CLASS FileInformationClass,
       LPVOID                    lpFileInformation,
       DWORD                     dwBufferSize
       );
   static pfnGetFileInformationByHandleEx pGetFileInformationByHandleEx = NULL;
   if (!pGetFileInformationByHandleEx) {
       pGetFileInformationByHandleEx = (pfnGetFileInformationByHandleEx)
           GetProcAddress(GetModuleHandle(TEXT("kernel32.dll")), "GetFileInformationByHandleEx");
       if (!pGetFileInformationByHandleEx)
           return -1;
   }

   nameinfo = malloc(size);
   if (nameinfo == NULL) {
       return -1;
   }
   /* Check the name of the pipe: '\{cygwin,msys}-XXXXXXXXXXXXXXXX-ptyN-{from,to}-master' */
   if (pGetFileInformationByHandleEx(fdHandle, FileNameInfo, nameinfo, size)) {
       nameinfo->FileName[nameinfo->FileNameLength / sizeof(WCHAR)] = L'\0';
       p = nameinfo->FileName;
       //Check that the pipe name contains msys or cygwin
       if ((((wcsstr(p, L"msys-") || wcsstr(p, L"cygwin-"))) &&
           (wcsstr(p, L"-pty") && wcsstr(p, L"-master")))) {
           //The openned pipe is a msys xor cygwin pipe to pty
           free(nameinfo);
           return 4;
       }
       else
           free(nameinfo);
           return 2; //else it is just a standard pipe
   }
   free(nameinfo);
   return -1;
}

/*
* Allow to test whether the file handle is from a console or not
* 1 if one of the stdio is redirected to a console pipe, else 0 (and in this case, a file should be created)
*/
sqInt
isFileHandleATTY(HANDLE fdHandle) {
   sqInt res = fileHandleType(fdHandle) ;
   return res == 1 || res == 4;
}

void *os_exports[][3] =
{
    { 0, 0, 0 }
};
