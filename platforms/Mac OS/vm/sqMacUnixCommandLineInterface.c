/*
 *  sqMacUnixCommandLineInterface.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on 3/19/05.
 *
 *   
 *   This file was part of Unix Squeak.
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
 * Much of this code comes from the unix port
 * Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * 3.8.13b4  Oct 16th, 2006 JMM headless
 */

#include "sq.h"
#include "sqMacUnixCommandLineInterface.h"
#include "sqMacEncoding.h"
#include "sqMacUnixFileInterface.h"
#include "sqMacUIConstants.h"
#include "sqMacUnixFileInterface.h"

# define VMOPTION(arg) "-"arg

extern CFStringEncoding gCurrentVMEncoding;
extern Boolean gSqueakHeadless;
static int    vmArgCnt=		0;	/* for getAttributeIntoLength() */
static char **vmArgVec=		0;
static int    squeakArgCnt=	0;
static char **squeakArgVec=	0;
extern       int    argCnt;	/* global copies for access from plugins */
extern       char **argVec;
extern       char **envVec;
extern usqLong gMaxHeapSize;

static void outOfMemory(void);
static void parseArguments(int argc, char **argv);
static int parseArgument(int argc, char **argv);
static void usage(void);
static void parseEnvironment(void);
static long strtobkm(const char *str);
static usqLong strtolbkm(const char *str);
static void printUsage(void);
static void printUsageNotes(void);
void resolveWhatTheImageNameIs(char *guess);

char *unixArgcInterfaceGetParm(int n) {
	int actual;

	if (n < 0) {
		actual = -n;
		return actual < vmArgCnt ? vmArgVec[actual] : nil;
	}
	else {
		actual = n - 2;
		return actual < squeakArgCnt ? squeakArgVec[actual] : nil;
	}
}

void unixArgcInterface(int argc, char **argv, char **envp) {
#pragma unused(envp)
  if ((vmArgVec= calloc(argc + 1, sizeof(char *))) == 0)
    outOfMemory();

  if ((squeakArgVec= calloc(argc + 1, sizeof(char *))) == 0)
    outOfMemory();

  parseEnvironment();
  parseArguments(argc, argv);
}


static void parseArguments(int argc, char **argv)
{
# define skipArg()	(--argc, argv++)
# define saveArg()	(vmArgVec[vmArgCnt++]= *skipArg())

  saveArg();	/* vm name */

  while ((argc > 0) && (**argv == '-'))	/* more options to parse */
    {
      int n= 0;

	  if (!strcmp(*argv, "--"))	
		break; /* escape from option processing */
	  else
		 n= parseArgument(argc, argv);

	  if (n == 0)			/* option not recognised */ {
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
  else					/* image name default to normal mac expectations */
	resolveWhatTheImageNameIs(saveArg());
  /* save remaining arguments as Squeak arguments */
  while (argc > 0)
    squeakArgVec[squeakArgCnt++]= *skipArg();

# undef saveArg
# undef skipArg
}

void resolveWhatTheImageNameIs(char *guess)  
{
	char possibleImageName[DOCUMENT_NAME_SIZE+1],  fullPath [DOCUMENT_NAME_SIZE+1],  lastPath [SHORTIMAGE_NAME_SIZE+1];
	FSRef		theFSRef;
	OSErr		err;

	strncpy(possibleImageName, guess,DOCUMENT_NAME_SIZE);
	err = getFSRef(possibleImageName,&theFSRef,kCFStringEncodingUTF8);
	if (err) {
		SetImageNameViaString("",gCurrentVMEncoding);
		SetShortImageNameViaString("",gCurrentVMEncoding);
		return;
	}
	PathToFileViaFSRef(fullPath,DOCUMENT_NAME_SIZE, &theFSRef,gCurrentVMEncoding);
	getLastPathComponentInCurrentEncoding(fullPath,lastPath,gCurrentVMEncoding);
	SetImageNameViaString(fullPath,gCurrentVMEncoding);
	SetShortImageNameViaString(lastPath,gCurrentVMEncoding);
}


static int parseArgument(int argc, char **argv)
{
   /* vm arguments */

  if      (!strcmp(argv[0], VMOPTION("help")))		{ 
	usage();
	exit(0); }
  else if (!strcmp(argv[0], VMOPTION("version"))) {
	extern char *getVersionInfo(int verbose);
	printf("%s\n", getVersionInfo(0));
	exit(0);
  }
  else if (!strncmp(argv[0], "-psn_", 5)) { return 1; }
  else if (!strcmp(argv[0], VMOPTION("headless"))) { gSqueakHeadless = true; return 1; }
  else if (!strcmp(argv[0], VMOPTION("headfull"))) { gSqueakHeadless = false; return 1; }
  else if (!strcmp(argv[0], VMOPTION("blockonerror"))) {
	extern int blockOnError;
	blockOnError = true;
	return 1; }
  else if (!strcmp(argv[0], VMOPTION("exitonwarn"))) {
	extern sqInt erroronwarn;
	erroronwarn = true;
	return 1; }
  else if (!strcmp(argv[0], VMOPTION("blockonwarn"))) {
	extern int blockOnError;
	extern sqInt erroronwarn;
	erroronwarn = blockOnError = true;
	return 1; }
  else if (!strcmp(argv[0], VMOPTION("timephases"))) {
	extern void printPhaseTime(int);
	printPhaseTime(1);
	return 1; }
#if (STACKVM || NewspeakVM) && !COGVM
  else if (!strcmp(argv[0], VMOPTION("sendtrace"))) { extern sqInt sendTrace; sendTrace = 1; return 1; }
#endif
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("memory")))	{ 
	gMaxHeapSize = strtolbkm(argv[1]);	 
	return 2; }
#if STACKVM || NewspeakVM
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("breaksel"))) { 
	extern void setBreakSelector(char *);
	setBreakSelector(argv[1]);
	return 2; }
#endif
#if STACKVM
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("breakmnu"))) { 
	extern void setBreakMNUSelector(char *);
	setBreakMNUSelector(argv[1]);
	return 2; }
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("eden"))) { 
	extern sqInt desiredEdenBytes;
	desiredEdenBytes = strtobkm(argv[1]);	 
	return 2; }
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("leakcheck"))) { 
	extern sqInt checkForLeaks;
	checkForLeaks = atoi(argv[1]);	 
	return 2; }
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("stackpages"))) { 
	extern sqInt desiredNumStackPages;
	desiredNumStackPages = atoi(argv[1]);	 
	return 2; }
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("numextsems"))) { 
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
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("pollpip"))) { 
	extern sqInt pollpip;
	pollpip = atoi(argv[1]);	 
	return 2; }
#endif /* STACKVM */
#if COGVM
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("codesize"))) { 
	extern sqInt desiredCogCodeSize;
	desiredCogCodeSize = strtobkm(argv[1]);	 
	return 2; }
# define TLSLEN (sizeof(VMOPTION("trace"))-1)
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
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("dpcso"))) { 
	extern unsigned long debugPrimCallStackOffset;
	debugPrimCallStackOffset = (unsigned long)strtobkm(argv[1]);	 
	return 2; }
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("cogmaxlits"))) { 
	extern sqInt maxLiteralCountForCompile;
	maxLiteralCountForCompile = strtobkm(argv[1]);	 
	return 2; }
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("cogminjumps"))) { 
	extern sqInt minBackwardJumpCountForCompile;
	minBackwardJumpCountForCompile = strtobkm(argv[1]);	 
	return 2; }
  else if (!strcmp(argv[0], VMOPTION("reportheadroom"))
		|| !strcmp(argv[0], VMOPTION("rh"))) { 
	extern sqInt reportStackHeadroom;
	reportStackHeadroom = 1;
	return 1; }
#endif /* COGVM */
#if SPURVM
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("maxoldspace"))) { 
	extern unsigned long maxOldSpaceSize;
	maxOldSpaceSize = (unsigned long)strtobkm(argv[1]);	 
	return 2; }
#endif
  else if (argc > 1 && !strcmp(argv[0], VMOPTION("pathenc"))) { 
	setEncodingType(argv[1]);
	return 2; }
  else if (argc > 2 && !strcmp(argv[0], VMOPTION("browserPipes"))) {
	extern int		 gSqueakBrowserPipes[]; /* read/write fd for browser communication */
	extern Boolean gSqueakBrowserSubProcess;

	sscanf(argv[1], "%i", &gSqueakBrowserPipes[0]);
	sscanf(argv[2], "%i", &gSqueakBrowserPipes[1]);
	gSqueakBrowserSubProcess = true;
	return 3;
  }
  return 0;	/* option not recognised */
}

static void usage(void)
{
  printf("Usage: %s [<option>...] [<imageName> [<argument>...]]\n", argVec[0]);
  printf("       %s [<option>...] -- [<argument>...]\n", argVec[0]);
  printUsage();
  printf("\nNotes:\n");
  printf("  <imageName> defaults to `" DEFAULT_IMAGE_NAME "'.\n");
  printUsageNotes();
  exit(1);
}

static void printUsage(void)
{
  printf("\nCommon <option>s:\n");
  printf("  "VMOPTION("help")"                 print this help message, then exit\n");
  printf("  "VMOPTION("memory")" <size>[mk]    use fixed heap size (added to image size)\n");
  printf("  "VMOPTION("timephases")"           print start load and run times\n");
#if STACKVM || NewspeakVM
  printf("  "VMOPTION("breaksel")" selector    set breakpoint on send of selector\n");
#endif
#if STACKVM
  printf("  "VMOPTION("breakmnu")" selector    set breakpoint on MNU of selector\n");
  printf("  "VMOPTION("eden")" <size>[mk]      set eden memory to bytes\n");
  printf("  "VMOPTION("leakcheck")" num        check for leaks in the heap\n");
  printf("  "VMOPTION("stackpages")" num       use n stack pages\n");
  printf("  "VMOPTION("numextsems")" num       make the external semaphore table num in size\n");
  printf("  "VMOPTION("noheartbeat")"          disable the heartbeat for VM debugging. disables input\n");
  printf("  "VMOPTION("pollpip")"              output . on each poll for input\n");
  printf("  "VMOPTION("checkpluginwrites")"    check for writes past end of object in plugins\n");
#endif
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
  printf("  "VMOPTION("cogmaxlits")" <n>       set max number of literals for methods to be compiled to machine code\n");
  printf("  "VMOPTION("cogminjumps")" <n>      set min number of backward jumps for interpreted methods to be considered for compilation to machine code\n");
  printf("  "VMOPTION("reportheadroom")"       report unused stack headroom on exit\n");
#endif
#if SPURVM
  printf("  "VMOPTION("maxoldspace")" <size>[mk]      set max size of old space memory to bytes\n");
#endif
  printf("  "VMOPTION("pathenc")" <enc>        set encoding for pathnames (default: %s)\n",
		getEncodingType(gCurrentVMEncoding));

  printf("  "VMOPTION("headless")"             run in headless (no window) mode (default: false)\n");
  printf("  "VMOPTION("headfull")"             run in headful (window) mode (default: true)\n");
  printf("  "VMOPTION("version")"              print version information, then exit\n");

  printf("  "VMOPTION("blockonerror")"         on error or segv block, not exit.  useful for attaching gdb\n");
  printf("  "VMOPTION("blockonwarn")"          on warning block, don't warn.  useful for attaching gdb\n");
  printf("  "VMOPTION("exitonwarn")"           treat warnings as errors, exiting on warn\n");
}

static void printUsageNotes(void)
{
#if SPURVM
	printf("  If `"VMOPTION("memory")"' or '"VMOPTION("maxoldspace")"' are not specified then the heap will grow dynamically.\n");
#else
	printf("  If `"VMOPTION("memory")"' is not specified then the heap will grow dynamically.\n");
#endif
  printf("  <argument>s are ignored, but are processed by the " IMAGE_DIALECT_NAME " image.\n");
  printf("  The first <argument> normally names a " IMAGE_DIALECT_NAME " `script' to execute.\n");
  printf("  Precede <arguments> by `--' to use default image.\n");
}

static void outOfMemory(void)
{
  fprintf(stderr, "out of memory\n");
  exit(1);
}

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

static usqLong
strtolbkm(const char *str)
{
  char *suffix;
  usqLong value= strtol(str, &suffix, 10);
  switch (*suffix)
    {
    case 'k': case 'K':
      value*= 1024ULL;
      break;
    case 'm': case 'M':
      value*= 1024ULL*1024ULL;
      break;
    }
  return value;
}

static void parseEnvironment(void)
{
	char *ev;

	if ((ev= getenv(IMAGE_ENV_NAME)))		
		resolveWhatTheImageNameIs(ev);
	if ((ev= getenv("SQUEAK_MEMORY")))
		gMaxHeapSize= strtolbkm(ev);
	if ((ev= getenv("SQUEAK_PATHENC")))
		setEncodingType(ev);
}
