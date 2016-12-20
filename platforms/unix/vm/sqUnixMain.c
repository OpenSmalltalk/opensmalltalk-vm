/* sqUnixMain.c -- support for Unix.
 * 
 *   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
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
 */

/* Author: Ian Piumarta <ian.piumarta@squeakland.org>
 * Merged with
 *	http://squeakvm.org/svn/squeak/trunk/platforms/unix/vm/sqUnixMain.c
 *	Revision: 2148
 *	Last Changed Rev: 2132
 * by eliot Wed Jan 20 10:57:26 PST 2010
 */

#include "sq.h"
#include "sqAssert.h"
#include "sqMemoryAccess.h"
#include "sqaio.h"
#include "sqUnixCharConv.h"
#include "sqSCCSVersion.h"
#include "sqUnixMain.h"
#include "debug.h"

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
# if __sun__
  # include <sys/ucontext.h>
  # include <limits.h>
# endif

#if defined(__alpha__) && defined(__osf__)
# include <sys/sysinfo.h>
# include <sys/proc.h>
#endif

#undef	DEBUG_MODULES

#undef	IMAGE_DUMP				/* define to enable SIGHUP and SIGQUIT handling */

#define IMAGE_NAME_SIZE MAXPATHLEN

#define DefaultHeapSize		  20	     	/* megabytes BEYOND actual image size */
#define DefaultMmapSize		1024     	/* megabytes of virtual memory */

       char  *documentName= 0;			/* name if launced from document */
       char   shortImageName[MAXPATHLEN+1];	/* image name */
       char   imageName[MAXPATHLEN+1];		/* full path to image */
static char   vmName[MAXPATHLEN+1];		/* full path to vm */
       char   vmPath[MAXPATHLEN+1];		/* full path to image directory */
static char   vmLogDirA[PATH_MAX+1];	/* where to write crash.dmp */

       char  *exeName;					/* short vm name, e.g. "squeak" */

       int    argCnt=		0;	/* global copies for access from plugins */
       char **argVec=		0;
       char **envVec=		0;

static int    vmArgCnt=		0;	/* for getAttributeIntoLength() */
static char **vmArgVec=		0;
static int    squeakArgCnt=	0;
static char **squeakArgVec=	0;

static long   extraMemory=	0;
       int    useMmap=		DefaultMmapSize * 1024 * 1024;

static int    useItimer=	1;	/* 0 to disable itimer-based clock */
static int    installHandlers=	1;	/* 0 to disable sigusr1 & sigsegv handlers */
       int    noEvents=		0;	/* 1 to disable new event handling */
       int    noSoundMixer=	0;	/* 1 to disable writing sound mixer levels */
       char  *squeakPlugins=	0;	/* plugin path */
       int    runAsSingleInstance=0;
#if !STACKVM && !COGVM
       int    useJit=		0;	/* use default */
       int    jitProcs=		0;	/* use default */
       int    jitMaxPIC=	0;	/* use default */
#else
# define useJit 0
#endif
       int    withSpy=		0;

       int    uxDropFileCount=	0;	/* number of dropped items	*/
       char **uxDropFileNames=	0;	/* dropped filenames		*/

       int    textEncodingUTF8= 1;	/* 1 if copy from external selection uses UTF8 */

#if defined(IMAGE_DUMP)
static int    dumpImageFile=	0;	/* 1 after SIGHUP received */
#endif

#if defined(DARWIN)
int inModalLoop= 0;
#endif

int sqIgnorePluginErrors	= 0;
int runInterpreter		= 1;

#include "SqDisplay.h"
#include "SqSound.h"

struct SqDisplay *dpy= 0;
struct SqSound   *snd= 0;

extern void dumpPrimTraceLog(void);
extern void printPhaseTime(int);
char *getVersionInfo(int verbose);

#ifdef PharoVM
void ioProcessEventsDefault(void);
void (*ioProcessEventsHandler) (void) = ioProcessEventsDefault;
#endif

/*
 * In the Cog VMs time management is in platforms/unix/vm/sqUnixHeartbeat.c.
 */
#if !STACKVM
/*** timer support ***/

#define	LOW_RES_TICK_MSECS	20	/* 1/50 second resolution */

static unsigned int   lowResMSecs= 0;
static struct timeval startUpTime;

static void sigalrm(int signum)
{
  lowResMSecs+= LOW_RES_TICK_MSECS;
  forceInterruptCheck();
}

void
ioInitTime(void)
{
  /* set up the micro/millisecond clock */
  gettimeofday(&startUpTime, 0);
  if (useItimer)
    {
      /* set up the low-res (50th second) millisecond clock */
      /* WARNING: all system calls must check for EINTR!!! */
      {
	struct sigaction sa;
	sigset_t ss1, ss2;
	sigemptyset(&ss1);
	sigprocmask(SIG_BLOCK, &ss1, &ss2);
	sa.sa_handler= sigalrm;
	sa.sa_mask= ss2;
#      ifdef SA_RESTART	/* we're probably on Linux */
	sa.sa_flags= SA_RESTART;
#      else
	sa.sa_flags= 0;	/* assume we already have BSD behaviour */
#      endif
#      if defined(__linux__) && !defined(__ia64) && !defined(__alpha__)
	sa.sa_restorer= 0;
#      endif
	sigaction(SIGALRM, &sa, 0);
      }
      {
	struct itimerval iv;
	iv.it_interval.tv_sec= 0;
	iv.it_interval.tv_usec= LOW_RES_TICK_MSECS * 1000;
	iv.it_value= iv.it_interval;
	setitimer(ITIMER_REAL, &iv, 0);
      }
    }
}


long ioMSecs(void)
{
  struct timeval now;
  gettimeofday(&now, 0);
  if ((now.tv_usec-= startUpTime.tv_usec) < 0)
    {
      now.tv_usec+= 1000000;
      now.tv_sec-= 1;
    }
  now.tv_sec-= startUpTime.tv_sec;
  return lowResMSecs= (now.tv_usec / 1000 + now.tv_sec * 1000);
}

long ioMicroMSecs(void)
{
  /* return the highest available resolution of the millisecond clock */
  return ioMSecs();	/* this already to the nearest millisecond */
}

time_t convertToSqueakTime(time_t unixTime);

/* returns the local wall clock time */
sqInt ioSeconds(void)
{
  return convertToSqueakTime(time(0));
}

#define SecondsFrom1901To1970      2177452800ULL
#define MicrosecondsFrom1901To1970 2177452800000000ULL

#define MicrosecondsPerSecond 1000000ULL
#define MillisecondsPerSecond 1000ULL

#define MicrosecondsPerMillisecond 1000ULL
/* Compute the current VM time basis, the number of microseconds from 1901. */

static unsigned long long
currentUTCMicroseconds()
{
	struct timeval utcNow;

	gettimeofday(&utcNow,0);
	return ((utcNow.tv_sec * MicrosecondsPerSecond) + utcNow.tv_usec)
			+ MicrosecondsFrom1901To1970;
}

usqLong
ioUTCMicroseconds() { return currentUTCMicroseconds(); }

/* This is an expensive interface for use by profiling code that wants the time
 * now rather than as of the last heartbeat.
 */
usqLong
ioUTCMicrosecondsNow() { return currentUTCMicroseconds(); }
#endif /* STACKVM */

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


/*** VM & Image File Naming ***/


/* copy src filename to target, if src is not an absolute filename,
 * prepend the cwd to make target absolute
  */
static void pathCopyAbs(char *target, const char *src, size_t targetSize)
{
  if (src[0] == '/')
    strcpy(target, src);
  else
    {
      0 == getcwd(target, targetSize);
      strcat(target, "/");
      strcat(target, src);
    }
}


static void
recordPathsForVMName(const char *localVmName)
{
#if defined(__linux__)
  char	 name[MAXPATHLEN+1];
  int    len;
#endif

	exeName = strrchr(localVmName,'/')
				? strrchr(localVmName,'/') + 1
				: (char *)localVmName;

#if defined(__linux__)
  if ((len= readlink("/proc/self/exe", name, sizeof(name))) > 0)
    {
      struct stat st;
      name[len]= '\0';
      if (!stat(name, &st))
	localVmName= name;
    }
#endif

  /* get canonical path to vm */
  if (realpath(localVmName, vmPath) == 0)
    pathCopyAbs(vmPath, localVmName, sizeof(vmPath));

  /* truncate vmPath to dirname */
  {
    int i= 0;
    for (i= strlen(vmPath); i >= 0; i--)
      if ('/' == vmPath[i])
	{
	  vmPath[i+1]= '\0';
	  break;
	}
  }
}

static void
recordFullPathForImageName(const char *localImageName)
{
	struct stat s;
	/* get canonical path to image */
	if ((stat(localImageName, &s) == -1)
	 || (realpath(localImageName, imageName) == 0))
		pathCopyAbs(imageName, localImageName, sizeof(imageName));

	/* Set the directory into which to write the crash.dmp file. */
	/* By default this is the image file's directory (strange but true). */
#if CRASH_DUMP_IN_CWD
	getcwd(vmLogDirA,PATH_MAX);
#else
	strcpy(vmLogDirA,imageName);
	if (strrchr(vmLogDirA,'/'))
		*strrchr(vmLogDirA,'/') = 0;
	else
		getcwd(vmLogDirA,PATH_MAX);
#endif
}

/* vm access */

sqInt imageNameSize(void) { return strlen(imageName); }

sqInt imageNameGetLength(sqInt sqImageNameIndex, sqInt length)
{
  char *sqImageName= pointerForOop(sqImageNameIndex);
  int count, i;

  count= strlen(imageName);
  count= (length < count) ? length : count;

  /* copy the file name into the Squeak string */
  for (i= 0; i < count; i++)
    sqImageName[i]= imageName[i];

  return count;
}


sqInt imageNamePutLength(sqInt sqImageNameIndex, sqInt length)
{
  char *sqImageName= pointerForOop(sqImageNameIndex);
  int count, i;

  count= (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

  /* copy the file name into a null-terminated C string */
  for (i= 0; i < count; i++)
    imageName[i]= sqImageName[i];
  imageName[count]= 0;

  dpy->winSetName(imageName);

  return count;
}


char *getImageName(void) { return imageName; }


/*** VM Home Directory Path ***/

sqInt vmPathSize(void) { return strlen(vmPath); }

sqInt vmPathGetLength(sqInt sqVMPathIndex, sqInt length)
{
  char *stVMPath= pointerForOop(sqVMPathIndex);
  int count, i;

  count= strlen(vmPath);
  count= (length < count) ? length : count;

  /* copy the file name into the Squeak string */
  for (i= 0; i < count; i++)
    stVMPath[i]= vmPath[i];

  return count;
}

char* ioGetLogDirectory(void) { return ""; };
sqInt ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz){ return 1; }


/*** power management ***/


sqInt ioDisablePowerManager(sqInt disableIfNonZero)
{
  return true;
}


/*** Access to system attributes and command-line arguments ***/


/* OS_TYPE may be set in configure.in and passed via the Makefile */

#ifndef OS_TYPE
# ifdef UNIX
#   define OS_TYPE "unix"
# else
#  define OS_TYPE "unknown"
# endif
#endif

char *
GetAttributeString(sqInt id)
{
  if (id < 0)	/* VM argument */
    {
      if (-id  < vmArgCnt)
	return vmArgVec[-id];
    }
  else
    switch (id)
      {
      case 0:
	return vmName[0] ? vmName : vmArgVec[0];
      case 1:
	return imageName;
      case 1001:
	/* OS type: "unix", "win32", "mac", ... */
	return OS_TYPE;
      case 1002:
	/* OS name: e.g. "solaris2.5" on unix, "win95" on win32, ... */
	return VM_TARGET_OS;
      case 1003:
	/* processor architecture: e.g. "68k", "x86", "PowerPC", ...  */
	return VM_TARGET_CPU;
      case 1004:
	/* Interpreter version string */
	return  (char *)interpreterVersion;
      case 1005:
	/* window system name */
	return  dpy->winSystemName();
      case 1006:
	/* vm build string */
	return VM_BUILD_STRING;
#if STACKVM
      case 1007: { /* interpreter build info */
	extern char *__interpBuildInfo;
	return __interpBuildInfo;
      }
# if COGVM
      case 1008: { /* cogit build info */
	extern char *__cogitBuildInfo;
	return __cogitBuildInfo;
      }
# endif
#endif

	  case 1009: /* source tree version info */
		return sourceVersionString(' ');

      default:
	if ((id - 2) < squeakArgCnt)
	  return squeakArgVec[id - 2];
      }
  success(false);
  return "";
}

sqInt attributeSize(sqInt id)
{
  return strlen(GetAttributeString(id));
}

sqInt getAttributeIntoLength(sqInt id, sqInt byteArrayIndex, sqInt length)
{
  if (length > 0)
    strncpy(pointerForOop(byteArrayIndex), GetAttributeString(id), length);
  return 0;
}


/*** event handling ***/


sqInt inputEventSemaIndex= 0;


/* set asynchronous input event semaphore  */

sqInt ioSetInputSemaphore(sqInt semaIndex)
{
  if ((semaIndex == 0) || (noEvents == 1))
    success(false);
  else
    inputEventSemaIndex= semaIndex;
  return true;
}


/*** display functions ***/

sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth, double hScale, double vScale, sqInt landscapeFlag)
{
  return dpy->ioFormPrint(bitsAddr, width, height, depth, hScale, vScale, landscapeFlag);
}

#if STACKVM
sqInt ioRelinquishProcessorForMicroseconds(sqInt us)
{
# if ITIMER_HEARTBEAT
  extern void checkHeartStillBeats();

  checkHeartStillBeats();
# endif
  dpy->ioRelinquishProcessorForMicroseconds(us);
  return 0;
}
#else /* STACKVM */
static int lastInterruptCheck= 0;

sqInt ioRelinquishProcessorForMicroseconds(sqInt us)
{
  int now;
  dpy->ioRelinquishProcessorForMicroseconds(us);
  now= ioLowResMSecs();
  if (now - lastInterruptCheck > (1000/25))	/* avoid thrashing intr checks from 1ms loop in idle proc  */
    {
      forceInterruptCheck();	/* ensure timely poll for semaphore activity */
      lastInterruptCheck= now;
    }
  return 0;
}
#endif /* STACKVM */

sqInt ioBeep(void)				 { return dpy->ioBeep(); }

#if defined(IMAGE_DUMP)

static void emergencyDump(int quit)
{
  extern sqInt preSnapshot(void);
  extern sqInt postSnapshot(void);
  extern void writeImageFile(sqInt);
  char savedName[MAXPATHLEN];
  char baseName[MAXPATHLEN];
  char *term;
  int  dataSize, i;
  strncpy(savedName, imageName, MAXPATHLEN);
  strncpy(baseName, imageName, MAXPATHLEN);
  if ((term= strrchr(baseName, '.')))
    *term= '\0';
  for (i= 0; ++i;)
    {
      struct stat sb;
      snprintf(imageName, sizeof(imageName), "%s-emergency-dump-%d.image",
        baseName, i);
      if (stat(imageName, &sb))
	break;
    }
  dataSize= preSnapshot();
  writeImageFile(dataSize);

#if STACKVM
  printf("\nMost recent primitives\n");
  dumpPrimTraceLog();
#endif
  fprintf(stderr, "\n");
  printCallStack();
  fprintf(stderr, "\nTo recover valuable content from this image:\n");
  fprintf(stderr, "    %s %s\n", exeName, imageName);
  fprintf(stderr, "and then evaluate\n");
  fprintf(stderr, "    Smalltalk processStartUpList: true\n");
  fprintf(stderr, "in a workspace.  DESTROY the dumped image after recovering content!");

  if (quit) abort();
  strncpy(imageName, savedName, sizeof(imageName));
}

#endif

#ifdef PharoVM

void ioProcessEventsDefault(void)
{
	sqInt result;
	extern sqInt inIOProcessEvents;

#if defined(IMAGE_DUMP)
	if (dumpImageFile) {
		emergencyDump(0);
		dumpImageFile= 0;
	}
#endif
	/* inIOProcessEvents controls ioProcessEvents.  If negative then
	 * ioProcessEvents is disabled.  If >= 0 inIOProcessEvents is incremented
	 * to avoid reentrancy (i.e. for native GUIs).
	 */
	if (inIOProcessEvents) return;
	inIOProcessEvents += 1;

	result = dpy->ioProcessEvents();

	if (inIOProcessEvents > 0)
		inIOProcessEvents -= 1;
}

extern void setIoProcessEventsHandler(void * handler) {
    ioProcessEventsHandler = (void(*)()) handler;
}

sqInt ioProcessEvents(void) {
    aioPoll(0);
    if(ioProcessEventsHandler)
        ioProcessEventsHandler();
    return 0;
}

#else

sqInt ioProcessEvents(void)
{
	sqInt result;
	extern sqInt inIOProcessEvents;

#if defined(IMAGE_DUMP)
	if (dumpImageFile) {
		emergencyDump(0);
		dumpImageFile= 0;
	}
#endif
	/* inIOProcessEvents controls ioProcessEvents.  If negative then
	 * ioProcessEvents is disabled.  If >= 0 inIOProcessEvents is incremented
	 * to avoid reentrancy (i.e. for native GUIs).
	 */
	if (inIOProcessEvents) return 0;
	inIOProcessEvents += 1;

	result = dpy->ioProcessEvents();

	if (inIOProcessEvents > 0)
		inIOProcessEvents -= 1;

	return result;
}

#endif

void	ioDrainEventQueue() {}

double ioScreenScaleFactor(void)	 { return dpy->ioScreenScaleFactor(); }
sqInt ioScreenDepth(void)		 { return dpy->ioScreenDepth(); }
sqInt ioScreenSize(void)		 { return dpy->ioScreenSize(); }

sqInt ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
  return dpy->ioSetCursorWithMask(cursorBitsIndex, cursorMaskIndex, offsetX, offsetY);
}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
  return dpy->ioSetCursorARGB(cursorBitsIndex, extentX, extentY, offsetX, offsetY);
}

sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY)
{
  return ioSetCursorWithMask(cursorBitsIndex, 0, offsetX, offsetY);
}

sqInt ioSetFullScreen(sqInt fullScreen)	{ return dpy->ioSetFullScreen(fullScreen); }
sqInt ioForceDisplayUpdate(void)	{ return dpy->ioForceDisplayUpdate(); }

sqInt ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth, sqInt l, sqInt r, sqInt t, sqInt b)
{
  return dpy->ioShowDisplay(dispBitsIndex, width, height, depth, l, r, t, b);
}

sqInt ioHasDisplayDepth(sqInt i) { return dpy->ioHasDisplayDepth(i); }

sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
  return dpy->ioSetDisplayMode(width, height, depth, fullscreenFlag);
}

sqInt clipboardSize(void)
{
  return dpy->clipboardSize();
}

sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  return dpy->clipboardWriteFromAt(count, byteArrayIndex, startIndex);
}

sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  return dpy->clipboardReadIntoAt(count, byteArrayIndex, startIndex);
}

char **clipboardGetTypeNames(void)
{
  return dpy->clipboardGetTypeNames();
}

sqInt clipboardSizeWithType(char *typeName, int ntypeName)
{
  return dpy->clipboardSizeWithType(typeName, ntypeName);
}

void clipboardWriteWithType(char *data, size_t nData, char *typeName, size_t nTypeNames, int isDnd, int isClaiming)
{
  dpy->clipboardWriteWithType(data, nData, typeName, nTypeNames, isDnd, isClaiming);
}

sqInt ioGetButtonState(void)		{ return dpy->ioGetButtonState(); }
sqInt ioPeekKeystroke(void)		{ return dpy->ioPeekKeystroke(); }
sqInt ioGetKeystroke(void)		{ return dpy->ioGetKeystroke(); }
sqInt ioGetNextEvent(sqInputEvent *evt)	{ return dpy->ioGetNextEvent(evt); }
sqInt ioMousePoint(void)		{ return dpy->ioMousePoint(); }

/*** Window labeling ***/
char* ioGetWindowLabel(void) {return "";}

sqInt ioSetWindowLabelOfSize(void* lbl, sqInt size)
{ return dpy->hostWindowSetTitle((long)dpy->ioGetWindowHandle(), lbl, size); }

sqInt ioIsWindowObscured(void) {return false;}

/** Misplaced Window-Size stubs, so the VM will link. **/
sqInt ioGetWindowWidth()
{ int wh = dpy->hostWindowGetSize((long)dpy->ioGetWindowHandle());
  return wh >> 16; } 

sqInt ioGetWindowHeight()
{ int wh = dpy->hostWindowGetSize((long)dpy->ioGetWindowHandle());
  return (short)wh; } 

void* ioGetWindowHandle(void) { return dpy->ioGetWindowHandle(); }

sqInt ioSetWindowWidthHeight(sqInt w, sqInt h)
{ return dpy->hostWindowSetSize((long)dpy->ioGetWindowHandle(),w,h); }

/*** Drag and Drop ***/

sqInt dndOutStart(char *types, int ntypes)	{ return dpy->dndOutStart(types, ntypes); }
sqInt dndOutAcceptedType(char *type, int ntype)	{ return dpy->dndOutAcceptedType(type, ntype); }
void  dndOutSend(char *bytes, int nbytes)	{        dpy->dndOutSend(bytes, nbytes); }
void  dndReceived(char *fileName)			{        dpy->dndReceived(fileName); }

/*** OpenGL ***/

int verboseLevel= 1;

struct SqDisplay *ioGetDisplayModule(void)	{ return dpy; }

void *ioGetDisplay(void)			{ return dpy->ioGetDisplay(); }
void *ioGetWindow(void)				{ return dpy->ioGetWindow(); }
sqInt ioGLinitialise(void)			{ return dpy->ioGLinitialise(); }

sqInt  ioGLcreateRenderer(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags)
{
  return dpy->ioGLcreateRenderer(r, x, y, w, h, flags);
}

sqInt ioGLmakeCurrentRenderer(glRenderer *r)	{ return dpy->ioGLmakeCurrentRenderer(r); }
void  ioGLdestroyRenderer(glRenderer *r)	{	 dpy->ioGLdestroyRenderer(r); }
void  ioGLswapBuffers(glRenderer *r)		{	 dpy->ioGLswapBuffers(r); }

void  ioGLsetBufferRect(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h)
{
  dpy->ioGLsetBufferRect(r, x, y, w, h);
}


sqInt  primitivePluginBrowserReady(void)	{ return dpy->primitivePluginBrowserReady(); }
sqInt  primitivePluginRequestURLStream(void)	{ return dpy->primitivePluginRequestURLStream(); }
sqInt  primitivePluginRequestURL(void)		{ return dpy->primitivePluginRequestURL(); }
sqInt  primitivePluginPostURL(void)		{ return dpy->primitivePluginPostURL(); }
sqInt  primitivePluginRequestFileHandle(void)	{ return dpy->primitivePluginRequestFileHandle(); }
sqInt  primitivePluginDestroyRequest(void)	{ return dpy->primitivePluginDestroyRequest(); }
sqInt  primitivePluginRequestState(void)	{ return dpy->primitivePluginRequestState(); }


/*** errors ***/

static void outOfMemory(void)
{
  /* pushing stderr outputs the error report on stderr instead of stdout */
  pushOutputFile((char *)STDERR_FILENO);
  error("out of memory\n");
}

/* Print an error message, possibly a stack trace, do /not/ exit.
 * Allows e.g. writing to a log file and stderr.
 */
static void *printRegisterState(ucontext_t *uap);

static void
reportStackState(char *msg, char *date, int printAll, ucontext_t *uap)
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
			void *fp = (void *)(uap ? uap->uc_mcontext->ss.ebp: 0);
			void *sp = (void *)(uap ? uap->uc_mcontext->ss.esp: 0);
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
	gregset_t *regs = &uap->uc_mcontext.gregs;
	printf(	"\teax 0x%08x ebx 0x%08x ecx 0x%08x edx 0x%08x\n"
			"\tedi 0x%08x esi 0x%08x ebp 0x%08x esp 0x%08x\n"
			"\teip 0x%08x\n",
			regs[REG_EAX], regs[REG_EBX], regs[REG_ECX], regs[REG_EDX],
			regs[REG_EDI], regs[REG_EDI], regs[REG_EBP], regs[REG_ESP],
			regs[REG_EIP]);
	return regs[REG_EIP];
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
	gregset_t *regs = &uap->uc_mcontext.gregs;
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

int blockOnError = 0; /* to allow attaching gdb on fatal error */
extern sqInt erroronwarn;

static void
block()
{ struct timespec while_away_the_hours;
  char pwd[MAXPATHLEN+1];

	printf("blocking e.g. to allow attaching debugger\n");
	printf("pid: %d pwd: %s vm:%s\n",
			(int)getpid(), getcwd(pwd,MAXPATHLEN+1), argVec[0]);
	while (1) {
		while_away_the_hours.tv_sec = 3600;
		nanosleep(&while_away_the_hours, 0);
	}
}

/* Print an error message, possibly a stack trace, and exit. */
/* Disable Intel compiler inlining of error which is used for breakpoints */
#pragma auto_inline(off)
void
error(char *msg)
{
	reportStackState(msg,0,0,0);
	if (blockOnError) block();
	abort();
}
#pragma auto_inline(on)

static void
getCrashDumpFilenameInto(char *buf)
{
	strcpy(buf,vmLogDirA);
	vmLogDirA[0] && strcat(buf, "/");
	strcat(buf, "crash.dmp");
}

static void
sigusr1(int sig, siginfo_t *info, void *uap)
{
	int saved_errno = errno;
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[IMAGE_NAME_SIZE+1];
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

static int inFault = 0;

static void
sigsegv(int sig, siginfo_t *info, void *uap)
{
	time_t now = time(NULL);
	char ctimebuf[32];
	char crashdump[IMAGE_NAME_SIZE+1];
	char *fault = sig == SIGSEGV
					? "Segmentation fault"
					: (sig == SIGBUS
						? "Bus error"
						: (sig == SIGILL
							? "Illegal instruction"
							: "Unknown signal"));

	if (!inFault) {
		getCrashDumpFilenameInto(crashdump);
		ctime_r(&now,ctimebuf);
		pushOutputFile(crashdump);
		reportStackState(fault, ctimebuf, 0, uap);
		popOutputFile();
		reportStackState(fault, ctimebuf, 0, uap);
	}
	if (blockOnError) block();
	abort();
}



#if defined(IMAGE_DUMP)
static void
sighup(int ignore) { dumpImageFile= 1; }

static void
sigquit(int ignore) { emergencyDump(1); }
#endif


/*** modules ***/


#include "SqModule.h"

struct SqModule *displayModule=	0;
struct SqModule *soundModule=	0;
struct SqModule *modules= 0;

#define modulesDo(M)	for (M= modules;  M;  M= M->next)

struct moduleDescription
{
  struct SqModule **addr;
  char		   *type;
  char		   *name;
};

static struct moduleDescription moduleDescriptions[]=
{
  { &displayModule, "display", "X11"    },	/*** NO DEFAULT ***/
  { &displayModule, "display", "fbdev"  },	/*** NO DEFAULT ***/
  { &displayModule, "display", "null"   },	/*** NO DEFAULT ***/
  { &displayModule, "display", "custom" },	/*** NO DEFAULT ***/
  { &soundModule,   "sound",   "NAS"    },	/*** NO DEFAULT ***/
  { &soundModule,   "sound",   "custom" },	/*** NO DEFAULT ***/
  /* when adding an entry above be sure to change the defaultModules offset below */
  { &displayModule, "display", "Quartz" },	/* defaults... */
  { &soundModule,   "sound",   "OSS"    },
  { &soundModule,   "sound",   "MacOSX" },
  { &soundModule,   "sound",   "Sun"    },
  { &soundModule,   "sound",   "pulse"  },
  { &soundModule,   "sound",   "ALSA"   },
  { &soundModule,   "sound",   "null"   },
  { 0,              0,         0	}
};

static struct moduleDescription *defaultModules= moduleDescriptions + 6;


struct SqModule *queryLoadModule(char *type, char *name, int query)
{
  char modName[MAXPATHLEN], itfName[32];
  struct SqModule *module= 0;
  void *itf= 0;
  snprintf(modName, sizeof(modName), "vm-%s-%s", type, name);
#ifdef DEBUG_MODULES
  printf("looking for module %s\n", modName);
#endif
  modulesDo (module)
    if (!strcmp(module->name, modName))
      return module;
  snprintf(itfName, sizeof(itfName), "%s_%s", type, name);
  itf= ioFindExternalFunctionIn(itfName, ioLoadModule(0));
  if (!itf)
    {
      void *handle= ioLoadModule(modName);
      if (handle)
	itf= ioFindExternalFunctionIn(itfName, handle);
      else
	if (!query)
	  {
	    fprintf(stderr, "could not find module %s\n", modName);
	    return 0;
	  }
    }
  if (itf)
    {
      module= (struct SqModule *)itf;
      if (SqModuleVersion != module->version)
	{
	  fprintf(stderr, "module %s version %x does not have required version %x\n",
		  modName, module->version, SqModuleVersion);
	  abort();
	}
      module->next= modules;
      modules= module;
      module->name= strdup(modName);
      module->parseEnvironment();
      return module;
    }
  if (!query)
    fprintf(stderr, "could not find interface %s in module %s\n", itfName, modName);
  return 0;
}


struct SqModule *queryModule(char *type, char *name)
{
  return queryLoadModule(type, name, 1);
}

struct SqModule *loadModule(char *type, char *name)
{
  return queryLoadModule(type, name, 0);
}

struct SqModule *requireModule(char *type, char *name)
{
  struct SqModule *m= loadModule(type, name);
  if (!m) abort();
  return m;
}


static char *canonicalModuleName(char *name)
{
  struct moduleDescription *md;

  for (md= moduleDescriptions;  md->addr;  ++md)
    if (!strcasecmp(name, md->name))
      return md->name;
  if (!strcasecmp(name, "none"))
    return "null";
  return name;
}


static void requireModuleNamed(char *type)	/*** NOTE: MODIFIES THE ARGUMENT! ***/
{
  if      (!strncmp(type,  "vm-", 3)) type+= 3;
  else if (!strncmp(type, "-vm-", 4)) type+= 4;
  /* we would like to use strsep() here, but neither OSF1 nor Solaris have it */
  {
    char *name= type;

    while (*name && ('-' != *name) && ('=' != *name))
      ++name;
    if (*name) *name++= '\0';

#  if defined(DEBUG_MODULES)
    printf("type %s name %s\n", type, name);
#  endif
    {
      struct SqModule **addr= 0, *module= 0;

      if      (!strcmp(type, "display")) addr= &displayModule;
      else if (!strcmp(type, "sound"))   addr= &soundModule;
      /* let unknown types through to the following to generate a more informative diagnostic */
      name= canonicalModuleName(name);
      module= requireModule(type, name);
      if (!addr)
	{
	  fprintf(stderr, "this cannot happen\n");
	  abort();
	}
      *addr= module;
    }
  }
}

static void requireModulesNamed(char *specs)
{
  char *vec= strdup(specs);
  char *pos= vec;

  while (*pos)
    {
      char *end= pos;
      while (*end && (' ' <= *end) && (',' != *end))
	++end;
      if (*end) *end++= '\0';
      requireModuleNamed(pos);
      pos= end;
    }
  free(vec);
}


static void checkModuleVersion(struct SqModule *module, int required, int actual)
{
  if (required != actual)
    {
      fprintf(stderr, "module %s interface version %x does not have required version %x\n",
	      module->name, actual, required);
      abort();
    }
}


static void loadImplicit(struct SqModule **addr, char *evar, char *type, char *name)
{
  if ((!*addr) && getenv(evar) && !(*addr= queryModule(type, name)))
    {
      fprintf(stderr, "could not find %s driver vm-%s-%s; either:\n", type, type, name);
      fprintf(stderr, "  - check that %s/vm-%s-%s.so exists, or\n", vmPath, type, name);
      fprintf(stderr, "  - use the '-plugins <path>' option to tell me where it is, or\n");
      fprintf(stderr, "  - remove %s from your environment.\n", evar);
      abort();
    }
}

static void loadModules(void)
{
  loadImplicit(&displayModule, "DISPLAY",     "display", "X11");
  loadImplicit(&soundModule,   "AUDIOSERVER", "sound",   "NAS");
  {
    struct moduleDescription *md;

    for (md= defaultModules;  md->addr;  ++md)
      if (!*md->addr)
	if ((*md->addr= queryModule(md->type, md->name)))
#	 if defined(DEBUG_MODULES)
	  fprintf(stderr, "%s: %s driver defaulting to vm-%s-%s\n", exeName, md->type, md->type, md->name)
#	 endif
	    ;
  }

  if (!displayModule)
    {
      fprintf(stderr, "%s: could not find any display driver\n", exeName);
      abort();
    }
  if (!soundModule)
    {
      fprintf(stderr, "%s: could not find any sound driver\n", exeName);
      abort();
    }

  dpy= (struct SqDisplay *)displayModule->makeInterface();
  snd= (struct SqSound   *)soundModule  ->makeInterface();

  checkModuleVersion(displayModule, SqDisplayVersion, dpy->version);
  checkModuleVersion(soundModule,   SqSoundVersion,   snd->version);
}

/* built-in main vm module */


static long
strtobkm(const char *str)
{
  char *suffix;
  long value= strtol(str, &suffix, 10);
  switch (*suffix)
    {
    case 'k': case 'K':
      value*= 1024;
      break;
    case 'm': case 'M':
      value*= 1024*1024;
      break;
    }
  return value;
}

#if !STACKVM && !COGVM
static int jitArgs(char *str)
{
  char *endptr= str;
  int  args= 3;				/* default JIT mode = fast compiler */
  
  if (*str == '\0') return args;
  if (*str != ',')
    args= strtol(str, &endptr, 10);	/* mode */
  while (*endptr == ',')		/* [,debugFlag]* */
    args|= (1 << (strtol(endptr + 1, &endptr, 10) + 8));
  return args;
}
#endif /* !STACKVM && !COGVM */


# include <locale.h>
static void vm_parseEnvironment(void)
{
  char *ev= setlocale(LC_CTYPE, "");
  if (ev)
    setLocaleEncoding(ev);
  else
    fprintf(stderr, "setlocale() failed (check values of LC_CTYPE, LANG and LC_ALL)\n");

  if (documentName)
    strcpy(shortImageName, documentName);
  else if ((ev= getenv(IMAGE_ENV_NAME)))
    strcpy(shortImageName, ev);
  else
    strcpy(shortImageName, DEFAULT_IMAGE_NAME);

  if ((ev= getenv("SQUEAK_MEMORY")))	extraMemory= strtobkm(ev);
  if ((ev= getenv("SQUEAK_MMAP")))	useMmap= strtobkm(ev);
  if ((ev= getenv("SQUEAK_PLUGINS")))	squeakPlugins= strdup(ev);
  if ((ev= getenv("SQUEAK_NOEVENTS")))	noEvents= 1;
  if ((ev= getenv("SQUEAK_NOTIMER")))	useItimer= 0;
#if !STACKVM && !COGVM
  if ((ev= getenv("SQUEAK_JIT")))	useJit= jitArgs(ev);
  if ((ev= getenv("SQUEAK_PROCS")))	jitProcs= atoi(ev);
  if ((ev= getenv("SQUEAK_MAXPIC")))	jitMaxPIC= atoi(ev);
#endif /* !STACKVM && !COGVM */
  if ((ev= getenv("SQUEAK_ENCODING")))	setEncoding(&sqTextEncoding, ev);
  if ((ev= getenv("SQUEAK_PATHENC")))	setEncoding(&uxPathEncoding, ev);
  if ((ev= getenv("SQUEAK_TEXTENC")))	setEncoding(&uxTextEncoding, ev);

  if ((ev= getenv("SQUEAK_VM")))	requireModulesNamed(ev);
}


static void usage(void);
static void versionInfo(void);


static int parseModuleArgument(int argc, char **argv, struct SqModule **addr, char *type, char *name)
{
  if (*addr)
    {
      fprintf(stderr, "option '%s' conflicts with previously-loaded module '%s'\n", *argv, (*addr)->name);
      exit(1);
    }
  *addr= requireModule(type, name);
  return (*addr)->parseArgument(argc, argv);
}


static int vm_parseArgument(int argc, char **argv)
{
  /* deal with arguments that implicitly load modules */

  if (!strncmp(argv[0], "-psn_", 5))
    {
      displayModule= requireModule("display", "Quartz");
      return displayModule->parseArgument(argc, argv);
    }

  if ((!strcmp(argv[0], "-vm")) && (argc > 1))
    {
      requireModulesNamed(argv[1]);
      return 2;
    }

  if (!strncmp(argv[0], "-vm-", 4))
    {
      requireModulesNamed(argv[0] + 4);
      return 1;
    }

  /* legacy compatibility */		/*** XXX to be removed at some time ***/

#ifdef PharoVM
# define VMOPTION(arg) "--"arg
#else
# define VMOPTION(arg) "-"arg
#endif

# define moduleArg(arg, type, name)						\
    if (!strcmp(argv[0], VMOPTION(arg)))							\
      return parseModuleArgument(argc, argv, &type##Module, #type, name);

  moduleArg("nodisplay",		display, "null");
  moduleArg("browserWindow",		display, "X11");
  moduleArg("browserPipes",		display, "X11");
  moduleArg("closequit",		display, "X11");
  moduleArg("cmdmod",			display, "X11");
  moduleArg("compositioninput",	display, "X11");
  moduleArg("display",			display, "X11");
  moduleArg("fullscreen",		display, "X11");
  moduleArg("fullscreenDirect",	display, "X11");
#if (USE_X11_GLX)
  moduleArg("glxdebug",		display, "X11");
#endif
  moduleArg("headless",		display, "X11");
  moduleArg("iconic",			display, "X11");
  moduleArg("lazy",			display, "X11");
  moduleArg("mapdelbs",		display, "X11");
  moduleArg("nointl",			display, "X11");
  moduleArg("notitle",			display, "X11");
  moduleArg("noxdnd",			display, "X11");
  moduleArg("optmod",			display, "X11");
#if defined(SUGAR)
  moduleArg("sugarBundleId",		display, "X11");
  moduleArg("sugarActivityId",		display, "X11");
#endif
  moduleArg("swapbtn",			display, "X11");
  moduleArg("xasync",			display, "X11");
#if defined(USE_XICFONT_OPTION)
  moduleArg("xicfont",			display, "X11");
#endif
  moduleArg("xshm",			display, "X11");
  moduleArg("quartz",			display, "Quartz");
  moduleArg("nosound",			sound,   "null");

# undef moduleArg

  /* vm arguments */

  if      (!strcmp(argv[0], VMOPTION("help")))		{ usage();		return 1; }
  else if (!strcmp(argv[0], VMOPTION("noevents")))	{ noEvents	= 1;	return 1; }
  else if (!strcmp(argv[0], VMOPTION("nomixer")))	{ noSoundMixer	= 1;	return 1; }
  else if (!strcmp(argv[0], VMOPTION("notimer")))	{ useItimer	= 0;	return 1; }
  else if (!strcmp(argv[0], VMOPTION("nohandlers")))	{ installHandlers= 0;	return 1; }
  else if (!strcmp(argv[0], VMOPTION("blockonerror"))) 	{ blockOnError = 1; return 1; }
  else if (!strcmp(argv[0], VMOPTION("blockonwarn"))) 	{ erroronwarn = blockOnError = 1; return 1; }
  else if (!strcmp(argv[0], VMOPTION("exitonwarn"))) 	{ erroronwarn = 1; return 1; }
  else if (!strcmp(argv[0], VMOPTION("timephases"))) 	{ printPhaseTime(1); return 1; }
#if !STACKVM && !COGVM
  else if (!strncmp(argv[0],VMOPTION("jit"), 4))	{ useJit	= jitArgs(argv[0]+4);	return 1; }
  else if (!strcmp(argv[0], VMOPTION("nojit")))		{ useJit	= 0;	return 1; }
  else if (!strcmp(argv[0], VMOPTION("spy")))		{ withSpy	= 1;	return 1; }
#endif /* !STACKVM && !COGVM */
  else if (!strcmp(argv[0], VMOPTION("version")))	{ versionInfo();	return 1; }
  else if (!strcmp(argv[0], VMOPTION("single")))	{ runAsSingleInstance=1; return 1; }
  /* option requires an argument */
  else if (argc > 1)
    {
      if (!strcmp(argv[0], VMOPTION("memory")))		{ extraMemory=	 strtobkm(argv[1]);	 return 2; }
#if !STACKVM && !COGVM
      else if (!strcmp(argv[0], VMOPTION("procs")))	{ jitProcs=	 atoi(argv[1]);		 return 2; }
      else if (!strcmp(argv[0], VMOPTION("maxpic")))	{ jitMaxPIC=	 atoi(argv[1]);		 return 2; }
#endif /* !STACKVM && !COGVM */
      else if (!strcmp(argv[0], VMOPTION("mmap")))	{ useMmap=	 strtobkm(argv[1]);	 return 2; }
      else if (!strcmp(argv[0], VMOPTION("plugins")))	{ squeakPlugins= strdup(argv[1]);	 return 2; }
      else if (!strcmp(argv[0], VMOPTION("encoding")))	{ setEncoding(&sqTextEncoding, argv[1]); return 2; }
      else if (!strcmp(argv[0], VMOPTION("pathenc")))	{ setEncoding(&uxPathEncoding, argv[1]); return 2; }
#if (STACKVM || NewspeakVM) && !COGVM
	  else if (!strcmp(argv[0], VMOPTION("sendtrace"))) { extern sqInt sendTrace; sendTrace = 1; return 1; }
#endif
#if STACKVM || NewspeakVM
      else if (!strcmp(argv[0], VMOPTION("breaksel"))) { 
		extern void setBreakSelector(char *);
		setBreakSelector(argv[1]);
		return 2; }
#endif
#if STACKVM
      else if (!strcmp(argv[0], VMOPTION("breakmnu"))) { 
		extern void setBreakMNUSelector(char *);
		setBreakMNUSelector(argv[1]);
		return 2; }
      else if (!strcmp(argv[0], VMOPTION("eden"))) {
		extern sqInt desiredEdenBytes;
		desiredEdenBytes = strtobkm(argv[1]);
		return 2; }
      else if (!strcmp(argv[0], VMOPTION("leakcheck"))) { 
		extern sqInt checkForLeaks;
		checkForLeaks = atoi(argv[1]);	 
		return 2; }
      else if (!strcmp(argv[0], VMOPTION("stackpages"))) {
		extern sqInt desiredNumStackPages;
		desiredNumStackPages = atoi(argv[1]);
		return 2; }
      else if (!strcmp(argv[0], VMOPTION("numextsems"))) { 
		ioSetMaxExtSemTableSize(atoi(argv[1]));
		return 2; }
      else if (!strcmp(argv[0], VMOPTION("checkpluginwrites"))) { 
		extern sqInt checkAllocFiller;
		checkAllocFiller = 1;
		return 1; }
      else if (!strcmp(argv[0], VMOPTION("noheartbeat"))) { 
		extern sqInt suppressHeartbeatFlag;
		suppressHeartbeatFlag = 1;
		return 1; }
      else if (!strcmp(argv[0], VMOPTION("warnpid"))) { 
		extern sqInt warnpid;
		warnpid = getpid();
		return 1; }
      else if (!strcmp(argv[0], VMOPTION("pollpip"))) { 
		extern sqInt pollpip;
		pollpip = atoi(argv[1]);	 
		return 2; }
#endif /* STACKVM */
#if COGVM
      else if (!strcmp(argv[0], VMOPTION("codesize"))) { 
		extern sqInt desiredCogCodeSize;
		desiredCogCodeSize = strtobkm(argv[1]);	 
		return 2; }
# define TLSLEN (sizeof("-trace")-1)
      else if (!strncmp(argv[0], VMOPTION("trace"), TLSLEN)) { 
		extern int traceFlags;
		char *equalsPos = strchr(argv[0],'=');

		if (!equalsPos) {
			traceFlags = 1;
			return 1;
		}
		if (equalsPos - argv[0] != TLSLEN
		  || (equalsPos[1] != '-' && !isdigit(equalsPos[1])))
			return 0;

		traceFlags = atoi(equalsPos + 1);
		return 1; }
      else if (!strcmp(argv[0], VMOPTION("tracestores"))) { 
		extern sqInt traceStores;
		traceStores = 1;
		return 1; }
      else if (!strcmp(argv[0], VMOPTION("cogmaxlits"))) { 
		extern sqInt maxLiteralCountForCompile;
		maxLiteralCountForCompile = strtobkm(argv[1]);	 
		return 2; }
      else if (!strcmp(argv[0], VMOPTION("cogminjumps"))) { 
		extern sqInt minBackwardJumpCountForCompile;
		minBackwardJumpCountForCompile = strtobkm(argv[1]);	 
		return 2; }
      else if (!strcmp(argv[0], VMOPTION("reportheadroom"))
			|| !strcmp(argv[0], "-rh")) { 
		extern sqInt reportStackHeadroom;
		reportStackHeadroom = 1;
		return 1; }
#endif /* COGVM */
#if SPURVM
      else if (!strcmp(argv[0], VMOPTION("maxoldspace"))) { 
		extern unsigned long maxOldSpaceSize;
		maxOldSpaceSize = (unsigned long)strtobkm(argv[1]);	 
		return 2; }
#endif
      else if (!strcmp(argv[0], VMOPTION("textenc"))) {
		int i, len = strlen(argv[1]);
		char *buf = (char *)alloca(len + 1);
		for (i = 0;  i < len;  ++i)
			buf[i] = toupper(argv[1][i]);
		if ((!strcmp(buf, "UTF8")) || (!strcmp(buf, "UTF-8")))
			textEncodingUTF8 = 1;
		else {
			textEncodingUTF8 = 0;
			setEncoding(&uxTextEncoding, buf);
		}
		return 2;
	  }
    }
  return 0;	/* option not recognised */
}


static void vm_printUsage(void)
{
  printf("\nCommon <option>s:\n");
  printf("  "VMOPTION("encoding")" <enc>       set the internal character encoding (default: MacRoman)\n");
  printf("  "VMOPTION("help")"                 print this help message, then exit\n");
  printf("  "VMOPTION("memory")" <size>[mk]    use fixed heap size (added to image size)\n");
  printf("  "VMOPTION("mmap")" <size>[mk]      limit dynamic heap size (default: %dm)\n", DefaultMmapSize);
  printf("  "VMOPTION("timephases")"           print start load and run times\n");
#if STACKVM || NewspeakVM
  printf("  "VMOPTION("breaksel")" selector    set breakpoint on send of selector\n");
#endif
#if STACKVM
  printf("  "VMOPTION("breakmnu")" selector    set breakpoint on MNU of selector\n");
  printf("  "VMOPTION("eden")" <size>[mk]      use given eden size\n");
  printf("  "VMOPTION("leakcheck")" num        check for leaks in the heap\n");
  printf("  "VMOPTION("stackpages")" <num>     use given number of stack pages\n");
#endif
  printf("  "VMOPTION("noevents")"             disable event-driven input support\n");
  printf("  "VMOPTION("nohandlers")"           disable sigsegv & sigusr1 handlers\n");
  printf("  "VMOPTION("pollpip")"              output . on each poll for input\n");
  printf("  "VMOPTION("checkpluginwrites")"    check for writes past end of object in plugins\n");
  printf("  "VMOPTION("pathenc")" <enc>        set encoding for pathnames (default: UTF-8)\n");
  printf("  "VMOPTION("plugins")" <path>       specify alternative plugin location (see manpage)\n");
  printf("  "VMOPTION("textenc")" <enc>        set encoding for external text (default: UTF-8)\n");
  printf("  "VMOPTION("version")"              print version information, then exit\n");
  printf("  -vm-<sys>-<dev>       use the <dev> driver for <sys> (see below)\n");
#if STACKVM || NewspeakVM
# if COGVM
  printf("  "VMOPTION("trace")"[=num]          enable tracing (optionally to a specific value)\n");
# else
  printf("  "VMOPTION("sendtrace")"            enable send tracing\n");
# endif
  printf("  "VMOPTION("warnpid")"              print pid in warnings\n");
#endif
#if COGVM
  printf("  "VMOPTION("codesize")" <size>[mk]  set machine code memory to bytes\n");
  printf("  "VMOPTION("tracestores")"          enable store tracing (assert check stores)\n");
  printf("  "VMOPTION("cogmaxlits")" <n>       set max number of literals for methods compiled to machine code\n");
  printf("  "VMOPTION("cogminjumps")" <n>      set min number of backward jumps for interpreted methods to be considered for compilation to machine code\n");
  printf("  "VMOPTION("reportheadroom")"       report unused stack headroom on exit\n");
#endif
#if SPURVM
  printf("  "VMOPTION("maxoldspace")" <size>[mk]    set max size of old space memory to bytes\n");
#endif
  printf("  "VMOPTION("blockonerror")"         on error or segv block, not exit.  useful for attaching gdb\n");
  printf("  "VMOPTION("blockonwarn")"          on warning block, don't warn.  useful for attaching gdb\n");
  printf("  "VMOPTION("exitonwarn")"           treat warnings as errors, exiting on warn\n");
#if 1
  printf("Deprecated:\n");
# if !STACKVM
  printf("  "VMOPTION("jit")"                  enable the dynamic compiler (if available)\n");
# endif
  printf("  "VMOPTION("notimer")"              disable interval timer for low-res clock\n");
  printf("  "VMOPTION("display")" <dpy>        equivalent to '-vm-display-X11 "VMOPTION("display")" <dpy>'\n");
  printf("  "VMOPTION("headless")"             equivalent to '-vm-display-X11 "VMOPTION("headless")"'\n");
  printf("  "VMOPTION("nodisplay")"            equivalent to '-vm-display-null'\n");
  printf("  "VMOPTION("nomixer")"              disable modification of mixer settings\n");
  printf("  "VMOPTION("nosound")"              equivalent to '-vm-sound-null'\n");
  printf("  "VMOPTION("quartz")"               equivalent to '-vm-display-Quartz'\n");
#endif
}


static void vm_printUsageNotes(void)
{
#if SPURVM
	printf("  If '"VMOPTION("memory")"' or '"VMOPTION("maxoldspace")"' are not specified then the heap will grow dynamically.\n");
#else
	printf("  If '"VMOPTION("memory")"' is not specified then the heap will grow dynamically.\n");
#endif
  printf("  <argument>s are ignored, but are processed by the " IMAGE_DIALECT_NAME " image.\n");
  printf("  The first <argument> normally names a " IMAGE_DIALECT_NAME " `script' to execute.\n");
  printf("  Precede <arguments> by `--' to use default image.\n");
}


static void *vm_makeInterface(void)
{
  fprintf(stderr, "this cannot happen\n");
  abort();
}


SqModuleDefine(vm, Module);


/*** options processing ***/


static void usage(void)
{
  struct SqModule *m= 0;
  printf("Usage: %s [<option>...] [<imageName> [<argument>...]]\n", argVec[0]);
  printf("       %s [<option>...] -- [<argument>...]\n", argVec[0]);
  sqIgnorePluginErrors= 1;
  {
    struct moduleDescription *md;
    for (md= moduleDescriptions;  md->addr;  ++md)
      queryModule(md->type, md->name);
  }
  modulesDo(m)
    m->printUsage();
  if (useJit)
    {
      printf("\njit <option>s:\n");
      printf("  "VMOPTION("align")" <n>            align functions at <n>-byte boundaries\n");
      printf("  "VMOPTION("jit")"<o>[,<d>...]      set optimisation [and debug] levels\n");
      printf("  "VMOPTION("maxpic")" <n>           set maximum PIC size to <n> entries\n");
      printf("  "VMOPTION("procs")" <n>            allow <n> concurrent volatile processes\n");
      printf("  "VMOPTION("spy")"                  enable the system spy\n");
    }
  printf("\nNotes:\n");
  printf("  <imageName> defaults to `" DEFAULT_IMAGE_NAME "'.\n");
  modulesDo(m)
    m->printUsageNotes();
  printf("\nAvailable drivers:\n");
  for (m= modules;  m->next;  m= m->next)
    printf("  %s\n", m->name);
  exit(1);
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
  extern char *vm_date, *cc_version, *ux_version;
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
  sprintf(info+strlen(info), "%s-%s ", VM_VERSION, revisionAsString());
#if defined(USE_XSHM)
  sprintf(info+strlen(info), " XShm");
#endif
  sprintf(info+strlen(info), " %s %s [" BuildVariant HBID " VM]\n", vm_date, cc_version);
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
  sprintf(info+strlen(info), "%s\n", sourceVersionString('\n'));
  if (verbose)
    sprintf(info+strlen(info), "Build host: ");
  sprintf(info+strlen(info), "%s\n", ux_version);
  sprintf(info+strlen(info), "plugin path: %s [default: %s]\n", squeakPlugins, vmPath);
  return info;
}


static void versionInfo(void)
{
  printf("%s", getVersionInfo(0));
  exit(0);
}


static void parseArguments(int argc, char **argv)
{
# define skipArg()	(--argc, argv++)
# define saveArg()	(vmArgVec[vmArgCnt++]= *skipArg())

  saveArg();	/* vm name */

  while ((argc > 0) && (**argv == '-'))	/* more options to parse */
    {
      struct SqModule *m= 0;
      int n= 0;
      if (!strcmp(*argv, "--"))		/* escape from option processing */
	break;
      modulesDo (m)
	if ((n= m->parseArgument(argc, argv)))
	  break;
#    ifdef DEBUG_IMAGE
      printf("parseArgument n = %d\n", n);
#    endif
      if (n == 0)			/* option not recognised */
	{
	  fprintf(stderr, "unknown option: %s\n", argv[0]);
	  usage();
	}
      while (n--)
	saveArg();
    }
  if (!argc)
    return;
  if (!strcmp(*argv, "--"))
    skipArg();
  else					/* image name */
    {
      if (!documentName)
	strcpy(shortImageName, saveArg());
      if (!strstr(shortImageName, ".image"))
	strcat(shortImageName, ".image");
    }
  /* save remaining arguments as Squeak arguments */
  while (argc > 0)
    squeakArgVec[squeakArgCnt++]= *skipArg();

# undef saveArg
# undef skipArg
}


/*** main ***/


static void
imageNotFound(char *imageName)
{
  /* image file is not found */
  fprintf(stderr,
	  "Could not open the " IMAGE_DIALECT_NAME " image file `%s'.\n"
	  "\n"
	  "There are three ways to open a " IMAGE_DIALECT_NAME " image file.  You can:\n"
	  "  1. Put copies of the default image and changes files in this directory.\n"
	  "  2. Put the name of the image file on the command line when you\n"
	  "     run %s (use the `-help' option for more information).\n"
	  "  3. Set the environment variable " IMAGE_ENV_NAME " to the name of the image\n"
	  "     that you want to use by default.\n"
	  "\n"
	  "For more information, type: `man %s' (without the quote characters).\n",
	  imageName, exeName, exeName);
  exit(1);
}


void imgInit(void)
{
  /* read the image file and allocate memory for Squeak heap */
  for (;;)
    {
      FILE *f= 0;
      struct stat sb;
      char imageName[MAXPATHLEN];
      sq2uxPath(shortImageName, strlen(shortImageName), imageName, 1000, 1);
      if ((  (-1 == stat(imageName, &sb)))
	  || ( 0 == (f= fopen(imageName, "r"))))
	{
	  if (dpy->winImageFind(shortImageName, sizeof(shortImageName)))
	    continue;
	  dpy->winImageNotFound();
	  imageNotFound(shortImageName);
	}
      {
	int fd= open(imageName, O_RDONLY);
	if (fd < 0) abort();
#      ifdef DEBUG_IMAGE
	printf("fstat(%d) => %d\n", fd, fstat(fd, &sb));
#      endif
      }
      recordFullPathForImageName(shortImageName); /* full image path */
      if (extraMemory)
	useMmap= 0;
      else
	extraMemory= DefaultHeapSize * 1024 * 1024;
#    ifdef DEBUG_IMAGE
      printf("image size %ld + heap size %ld (useMmap = %d)\n", (long)sb.st_size, extraMemory, useMmap);
#    endif
#if SPURVM
	  readImageFromFileHeapSizeStartingAt(f, 0, 0);
#else
      extraMemory += (long)sb.st_size;
      readImageFromFileHeapSizeStartingAt(f, extraMemory, 0);
#endif
      sqImageFileClose(f);
      break;
    }
}

#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(i486) || defined(__i486) || defined (__i486__) \
			|| defined(intel) || defined(x86) || defined(i86pc) )
  static void fldcw(unsigned int cw)
  {
    __asm__("fldcw %0" :: "m"(cw));
  }
#else
# define fldcw(cw)
#endif

#if defined(__GNUC__) && ( defined(ppc) || defined(__ppc) || defined(__ppc__)  \
			|| defined(POWERPC) || defined(__POWERPC) || defined (__POWERPC__) )
  void mtfsfi(unsigned long long fpscr)
  {
    __asm__("lfd   f0, %0" :: "m"(fpscr));
    __asm__("mtfsf 0xff, f0");
  }
#else
# define mtfsfi(fpscr)
#endif

extern void initGlobalStructure(void); // this is effectively null if a global register is not being used

int
main(int argc, char **argv, char **envp)
{
  /* check the interpreter's size assumptions for basic data types */
  if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
  if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
  if (sizeof(sqLong) != 8) error("This C compiler's long longs are not 64 bits.");
#if 0
  if (sizeof(time_t) != 4) error("This C compiler's time_t's are not 32 bits.");
#endif

  fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
  mtfsfi(0);		/* disable signals, IEEE mode, round to nearest */

  /* Make parameters global for access from plugins */

  argCnt= argc;
  argVec= argv;
  envVec= envp;

#ifdef DEBUG_IMAGE
  {
    int i= argc;
    char **p= argv;
    while (i--)
      printf("arg: %s\n", *p++);
  }
#endif

	initGlobalStructure();
 
 /* Allocate arrays to store copies of pointers to command line
     arguments.  Used by getAttributeIntoLength(). */

  if ((vmArgVec= calloc(argc + 1, sizeof(char *))) == 0)
    outOfMemory();

  if ((squeakArgVec= calloc(argc + 1, sizeof(char *))) == 0)
    outOfMemory();

#if defined(__alpha__) && defined(__osf__)
  /* disable printing of unaligned access exceptions */
  {
    int buf[2]= { SSIN_UACPROC, UAC_NOPRINT };
    if (setsysinfo(SSI_NVPAIRS, buf, 1, 0, 0, 0) < 0)
      {
	perror("setsysinfo(UAC_NOPRINT)");
      }
  }
#endif

#if defined(HAVE_TZSET)
  tzset();	/* should _not_ be necessary! */
#endif

  recordPathsForVMName(argv[0]); /* full vm path */
  squeakPlugins= vmPath;		/* default plugin location is VM directory */

#if !DEBUG
  sqIgnorePluginErrors= 1;
#endif
  if (!modules)
    modules= &vm_Module;
  vm_Module.parseEnvironment();
  parseArguments(argc, argv);
  if ((!dpy) || (!snd))
    loadModules();
#if !DEBUG
  sqIgnorePluginErrors= 0;
#endif

#if defined(DEBUG_MODULES)
  printf("displayModule %p %s\n", displayModule, displayModule->name);
  if (soundModule)
    printf("soundModule   %p %s\n", soundModule,   soundModule->name);
#endif

  if (!realpath(argv[0], vmName))
    vmName[0]= 0; /* full VM name */

#ifdef DEBUG_IMAGE
  printf("vmName: %s -> %s\n", argv[0], vmName);
  printf("viName: %s\n", shortImageName);
  printf("documentName: %s\n", documentName);
#endif

  ioInitTime();
  ioInitThreads();
  aioInit();
  dpy->winInit();
  imgInit();
  /* If running as a single instance and there are arguments after the image
   * and any are files then try and drop these on the existing instance.
   */
  dpy->winOpen(runAsSingleInstance ? squeakArgCnt : 0, squeakArgVec);

#if defined(HAVE_LIBDL) && !STACKVM
  if (useJit)
    {
      /* first try to find an internal dynamic compiler... */
      void *handle= ioLoadModule(0);
      void *comp= ioFindExternalFunctionIn("j_interpret", handle);
      /* ...and if that fails... */
      if (comp == 0)
	{
	  /* ...try to find an external one */
	  handle= ioLoadModule("SqueakCompiler");
	  if (handle != 0)
	    comp= ioFindExternalFunctionIn("j_interpret", handle);
	}
      if (comp)
	{
	  ((void (*)(void))comp)();
	  fprintf(stderr, "handing control back to interpret() -- have a nice day\n");
	}
      else
	printf("could not find j_interpret\n");
      exit(1);
    }
#endif /* defined(HAVE_LIBDL) && !STACKVM */

  if (installHandlers) {
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

  /* run Squeak */
  if (runInterpreter) {
	printPhaseTime(2);
    interpret();
  }

  /* we need these, even if not referenced from main executable */
  (void)sq2uxPath;
  (void)ux2sqPath;
  sqDebugAnchor();
  
  return 0;
}

sqInt ioExit(void) { return ioExitWithErrorCode(0); }

sqInt
ioExitWithErrorCode(int ec)
{
#if COGVM
extern sqInt reportStackHeadroom;
	if (reportStackHeadroom)
		reportMinimumUnusedHeadroom();
#endif
  printPhaseTime(3);
  dpy->winExit();
  exit(ec);
  return ec;
}

#if defined(DARWIN)
# include "mac-alias.c"
#endif


/* Copy aFilenameString to aCharBuffer and optionally resolveAlias (or
   symbolic link) to the real path of the target.  Answer 0 if
   successful of -1 to indicate an error.  Assume aCharBuffer is at
   least PATH_MAX bytes long.  Note that MAXSYMLINKS is a lower bound
   on the (potentially unlimited) number of symlinks allowed in a
   path, but calling sysconf() seems like overkill. */

sqInt sqGetFilenameFromString(char *aCharBuffer, char *aFilenameString, sqInt filenameLength, sqInt resolveAlias)
{
  int numLinks= 0;
  struct stat st;

  memcpy(aCharBuffer, aFilenameString, filenameLength);
  aCharBuffer[filenameLength]= 0;

  if (resolveAlias)
    for (;;)	/* aCharBuffer might refer to link or alias */
      {
	if (!lstat(aCharBuffer, &st) && S_ISLNK(st.st_mode))	/* symlink */
	  { char linkbuf[PATH_MAX+1];
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

  return 0;
}


sqInt ioGatherEntropy(char *buffer, sqInt bufSize)
{
  int fd, count= 0;

  if ((fd= open("/dev/urandom", O_RDONLY)) < 0)
    return 0;

  while (count < bufSize)
    {
      int n;
      if ((n= read(fd, buffer + count, bufSize)) < 1)
	break;
      count += n;
    }

  close(fd);

  return count == bufSize;
}


#if COGVM
/*
 * Support code for Cog.
 * a) Answer whether the C frame pointer is in use, for capture of the C stack
 *    pointers.
 * b) answer the amount of stack room to ensure in a Cog stack page, including
 *    the size of the redzone, if any.
 */

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
