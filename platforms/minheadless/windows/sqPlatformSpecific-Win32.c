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

#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "config.h"

#ifndef PROCESS_SYSTEM_DPI_AWARE
#define PROCESS_SYSTEM_DPI_AWARE 1
#endif

#ifndef PROCESS_PER_MONITOR_DPI_AWARE
#define PROCESS_PER_MONITOR_DPI_AWARE 2
#endif

typedef HRESULT WINAPI (*SetProcessDpiAwarenessFunctionPointer) (int awareness);

HANDLE vmWakeUpEvent = 0;

static void enableHighDPIAwareness()
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

void ioInitPlatformSpecific(void)
{
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

void aioInit(void)
{
}

long aioPoll(long microSeconds)
{
    return 0;
}

/* New filename converting function; used by the interpreterProxy function
ioFilenamefromStringofLengthresolveAliases. Most platforms can ignore the
resolveAlias boolean - it seems to only be of use by OSX but is crucial there.
*/
sqInt sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean)
{
    memcpy(aCharBuffer, aFilenameString, filenameLength);
    aCharBuffer[filenameLength] = 0;
    return 0;
}

sqInt ioBeep(void)
{
    return 0;
}

sqInt ioExit(void)
{
    exit(0);
}

sqInt ioExitWithErrorCode(int errorCode)
{
    exit(errorCode);
}

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
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

int synchronizedSignalSemaphoreWithIndex(int semaIndex)
{
    int result;

    /* Do our job - this is now synchronized in signalSemaphoreWithIndex */
    result = signalSemaphoreWithIndex(semaIndex);
    /* wake up interpret() if sleeping */
    SetEvent(vmWakeUpEvent);
    return result;
}

void  ioProfileStatus(sqInt *running, void **exestartpc, void **exelimitpc,
    void **vmhst, long *nvmhbin, void **eahst, long *neahbin)
{
}

void  ioControlProfile(int on, void **vhp, long *nvb, void **ehp, long *neb)
{
}

long  ioControlNewProfile(int on, unsigned long buffer_size)
{
    return 0;
}

void  ioNewProfileStatus(sqInt *running, long *buffersize)
{
}

long  ioNewProfileSamplesInto(void *sampleBuffer)
{
    return 0;
}

void  ioClearProfile(void)
{
}

sqInt ioDisablePowerManager(sqInt disableIfNonZero)
{
    return true;
}

void findExecutablePath(const char *localVmName, char *dest, size_t destSize)
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

    if (lastSeparator)
        strncat(dest, localVmName, lastSeparator - localVmName + 1);
}

#if COGVM
#include <signal.h>

/*
* Support code for Cog.
* a) Answer whether the C frame pointer is in use, for capture of the C stack
*    pointers.
* b) answer the amount of stack room to ensure in a Cog stack page, including
*    the size of the redzone, if any.
*/
# if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__) \
	|| defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
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
    extern usqIntptr_t CStackPointer, CFramePointer;
    extern void(*ceCaptureCStackPointers)(void);
    usqIntptr_t currentCSP = CStackPointer;

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
    return (char *)min(&old, &handler_action) - sizeof(struct sigaction) - p;
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
#endif /* COGVM */

void *os_exports[][3] =
{
    { 0, 0, 0 }
};
