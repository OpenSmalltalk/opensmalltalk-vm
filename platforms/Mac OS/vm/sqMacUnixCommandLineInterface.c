/*
 *  sqMacUnixCommandLineInterface.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on 3/19/05.
 *
 *   
 *   This file was part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 
 * Much of this code comes from the unix port
 * Ian Piumarta <ian.piumarta@inria.fr>
 
 
 * 3.8.13b4  Oct 16th, 2006 JMM headless
 */

#include "sq.h"
#include "sqMacUnixCommandLineInterface.h"
#include "sqMacEncoding.h"
#include "sqMacFileLogic.h"
#include "sqMacUIConstants.h"
#include "sqMacUnixFileInterface.h"


extern CFStringEncoding gCurrentVMEncoding;
extern Boolean gSqueakHeadless;
static int    vmArgCnt=		0;	/* for getAttributeIntoLength() */
static char **vmArgVec=		0;
static int    squeakArgCnt=	0;
static char **squeakArgVec=	0;
extern       int    argCnt;	/* global copies for access from plugins */
extern       char **argVec;
extern       char **envVec;
extern UInt32 gMaxHeapSize;

static void outOfMemory(void);
static void parseArguments(int argc, char **argv);
static int parseArgument(int argc, char **argv);
static void usage(void);
static void parseEnvironment(void);
static int strtobkm(const char *str);
static void printUsage(void);
static void printUsageNotes(void);
void resolveWhatTheImageNameIs(char *guess);

char *unixArgcInterfaceGetParm(int n) {
	int actual;
	
	if (n < 0) 
		actual = -n;
	else
		actual = n - 2;
		
	if (actual < squeakArgCnt) 
		return squeakArgVec[actual];
	return nil;
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
	// fprintf(stderr,"\nresolveWhatTheImageNameIs %s",guess);
	err = getFSRef(possibleImageName,&theFSRef,kCFStringEncodingUTF8);
	if (err && (!(guess[0] == '.' || guess[0] == '/'))) {
		getVMPathWithEncoding(possibleImageName,kCFStringEncodingUTF8);
		strncat(possibleImageName, guess, DOCUMENT_NAME_SIZE - strlen(possibleImageName));
		err = getFSRef(possibleImageName,&theFSRef,kCFStringEncodingUTF8);
		// fprintf(stderr,"\nresolveWhatTheImageNameIs 2ndTry %s",possibleImageName);
	}
	if (err) {
		SetImageNameViaString("",gCurrentVMEncoding);
		SetShortImageNameViaString("",gCurrentVMEncoding);
		//	fprintf(stderr,"\nresolveWhatTheImageNameIs Failure to find file");
		return;
	}
	PathToFileViaFSRef(fullPath,DOCUMENT_NAME_SIZE, &theFSRef,gCurrentVMEncoding);
	// fprintf(stderr,"\nresolveWhatTheImageNameIs fullPath %s",fullPath);
	getLastPathComponentInCurrentEncoding(fullPath,lastPath,gCurrentVMEncoding);
	SetImageNameViaString(fullPath,gCurrentVMEncoding);
	SetShortImageNameViaString(lastPath,gCurrentVMEncoding);
}


static int parseArgument(int argc, char **argv)
{
   /* vm arguments */
  
  if      (!strcmp(argv[0], "-help"))		{ 
	usage();
	return 1; }
  else if (!strncmp(argv[0], "-psn_", 5)) { 
	return 1; }
  else if (!strcmp(argv[0], "-headless")) { 
	gSqueakHeadless = true; return 1; }
  else if (!strcmp(argv[0], "-headfull")) { 
	gSqueakHeadless = false; return 1; }
  else if (argc > 1) {
	  if (!strcmp(argv[0], "-memory"))	{ 
		gMaxHeapSize = strtobkm(argv[1]);	 
		return 2; }
      else if (!strcmp(argv[0], "-pathenc")) { 
		setEncodingType(argv[1]); 
		return 2; }
      else if (!strcmp(argv[0], "-browserPipes")) {
		extern int		 gSqueakBrowserPipes[]; /* read/write fd for browser communication */
		extern Boolean gSqueakBrowserSubProcess;
		
		if (!argv[2]) return 0;
		sscanf(argv[1], "%i", &gSqueakBrowserPipes[0]);
		sscanf(argv[2], "%i", &gSqueakBrowserPipes[1]);
		gSqueakBrowserSubProcess = true;
		return 3;
	}
  }
  return 0;	/* option not recognised */
}

static void usage(void)
{
  printf("Usage: %s [<option>...] [<imageName> [<argument>...]]\n", argVec[0]);
  printf("       %s [<option>...] -- [<argument>...]\n", argVec[0]);
  printUsage();
  printf("\nNotes:\n");
  printf("  <imageName> defaults to `Squeak.image'.\n");
  printUsageNotes();
  exit(1);
}

static void printUsage(void)
{
  printf("\nCommon <option>s:\n");
  printf("  -help                 print this help message, then exit\n");
  printf("  -memory <size>[mk]    use fixed heap size (added to image size)\n");
  printf("  -pathenc <enc>        set encoding for pathnames (default: macintosh)\n");
  printf("  -headless             run in headless (no window) mode (default: false)\n");
}

static void printUsageNotes(void)
{
  printf("  If `-memory' is not specified then the heap will grow dynamically.\n");
  printf("  <argument>s are ignored, but are processed by the Squeak image.\n");
  printf("  The first <argument> normally names a Squeak `script' to execute.\n");
  printf("  Precede <arguments> by `--' to use default image.\n");
}

static void outOfMemory(void)
{
  fprintf(stderr, "out of memory\n");
  exit(1);
}

static int strtobkm(const char *str)
{
  char *suffix;
  int value= strtol(str, &suffix, 10);
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

static void parseEnvironment(void)
{
  char *ev= 0;

  if ((ev= getenv("SQUEAK_IMAGE")))		
	resolveWhatTheImageNameIs(ev);
  if ((ev= getenv("SQUEAK_MEMORY")))	gMaxHeapSize= strtobkm(ev);
  if ((ev= getenv("SQUEAK_PATHENC")))	setEncodingType(ev);
}
