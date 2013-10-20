




#error Hi, you are building an obsolete version of the macintosh VM. 
#error Instead use the xCode projects found in the iOS folder 
#error Remove these error defines if you really need to build this obsolete 4.x VM





/****************************************************************************
*   PROJECT: Mac initialization, misc utility routines
*   FILE:    sqMacMain.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar  8th, 2002, JMM UI locking for applescript under os-x
*  Mar  17th, 2002, JMM look into sleep wakeup issues under os-9 on some computers.
*  Apr  17th, 2002, JMM Use accessors for VM variables, add os-9 check, plus changes by Alain Fischer <alain.fischer@bluewin.ch> to look for image and fetch VM version under os-x
*  Apr  3rd, 2003, JMM use BROWSERPLUGIN
*  Jun 25th, 2003, JMM optional window title. globals for various user preferences
****************************************************************************/

// These are the comments from the orginal sqMacWindow.c before it was divided into 10 files
//Aug 7th 2000,JMM Added logic for interrupt driven dispatching
//Sept 1st 2000, JMM fix problem with modifier information being passed back incorrectly.
//Sept 1st 2000, JMM use floating point for time versus 64bit math (faster!)
//Sept 1st 2000, JMM watch mouse movement foreground only, ignore when squeak in background.
//Sept 18th 2000, JMM fix to cmpSize 
//Sept 19th 2000, JMM Sept 1st fix to keyboard modifier info broke cmd shift
//Sept 27 2000, JMM fix to documentPath
//Nov 13 2000, JMM logic to read/write image from VM. 
//Nov 22 2000, JMM Bob Arning found a bug with the duplicate mouse event logic (we were altering the event then recording the altered value)
//Nov 30 2000, JMM Use Open Transport clock versus upTime, solves some issues for jitter and it's faster
//Dec 5th 2000, JMM poll 60 times a second... do event polling via checkForInterrupts and drive semaphore
//Dec 6th 2000, JMM added logic to interface with power manger (1997 was there but dropped..., back again for ibooks)
//Jan 14th 2001, KG Did some carbon porting.
//Feb 2nd 2001, JMM V3.0 added zoom window support, full path support
//Feb 2nd 2001, JMM V3.04 do an open window dialog at startup time if no image file
//Feb 14th 2001, JMM V3.06 don't cache image read/writes
//Feb 17th 2001, JMM V3.07 fix OS bug in 7.5.5 on activate event
//Feb 22nd 2001, JMM v3.08 no caps lock
//Mar 9th  2001, JMM v3.10 broken full screen update redaw on cmd-tab via ignoring activate events 3.0.7.
//Mar 15th 2001, JMM v3.10 added minimal vm logic, fix mouse down reporting.
//Mar 23rd 2001, JMM v3.10 start interpreter suspended for plugin to fix race at startup with netscape 4.x
//Apr 4th 2001, JMM  V3.11 fix for carbon get keyboard data eventrecord is broken for nullevents. 
//                         Rework event duplication logic, New menubar show logic, fix position bug on window move restore after full screen 
//Apr 30th 2001, JMM V3.14 pass interpreter version back for get attribute 1004, delay if idle, set mouse down flag only on mouse down in content, and restrict window movement/sizing if in full screen mode
//May 24th 2001, JMM V3.17 add logic to sleep/wait in carbon on excessive idle time, plus change data return on attribute gets
//June 18th 2001, JMM V3.18 fix for cast of version info for CW 6.1
//June 18th 2001, JMM V3.19 fix for saveAsEmbeddedImage. Broken in 3.0 Also added fix for powerpc only cfrg, and rework of security interface for VMMaker via Tim
//Oct 1,2001, JMM V3.1.2  open document support and fix scrap issues, add ext keyboard unlock shift key logic. 
//Dec 19,2001, JMM V3.1.2B6 fix USB on no-usb machines.
//Feb 11th 2002, JMM V3.0.21 fix for UpdateWindow to make printing work!
/*	12/19/2001 JMM Fix for USB on non-usb devices, and fix for ext keyboard use volatile
*	12/27/2001 JMM Added support to load os-x Bundles versus CFM, have broken CFM code too.
*	1/2/2002   JMM Use unix io for image, much faster, cleanup window display and ioshow logic.
*	1/18/2002  JMM Fix os-x memory mapping, new type for squeak file offsets
*	1/27/2002  JMM added logic to get framework bundles 
*	2/04/2002  JMM Rework timer logic, fall back to old style timer, which is pthread based.
*	2/14/2002  JMM fixes for updatewindow logic and drag/drop image with no file type
*	2/25/2002  JMM additions for carbon event managment.
*   3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
*  3.5.1b3 June 7th, 2003 JMM fix up full screen pthread issue.
*  3.6.x  Sept 1st, 2003 JMM per note from Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>  changed 1003 parm to lowercase. 
*  3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
*  3.8.0bx Jul 20th, 2004 JMM multiple window support
*  3.8.7b2 March 19th, 2005 JMM add command line unix interface
*  3.8.9b2 Sept 22nd, 2005 JMM add logic to override Squeak.image name 
*  3.8.10b1 Jan 31st, 2006 JMM convert to unix file names.
*  3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
*  3.8.13b4 Oct 16th, 2006 JMM headless
*  3.8.14b1 Oct  2006, JMM browser rewrite
 3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
 3.8.15b5  Mar 7th, 2007 JMM Add SqueakDebug, SqueakQuitOnQuitAppleEvent 
 3.8.16b3  Mar 21th, 2007 JMM trusted/untrusted directory cleanup, warning msg cleanup
 3.8.17b2  April 26th, 2007 JMM large cursors
 3.8.21b1	Jan 14th, 2009 JMM fix issue with mmap allocation, only allow explicitly to avoid mmap problems on nfs
 4.0.1b1	Apr 9th, 2009 JMM add logic for etoys on a stick
 4.2.1b1	Aug 19th, 2009 JMM add gSqueakResourceDirectoryName

 -------   Oct 19th, 2013 dtl add ioExitWithErrorCode(int ec)
*/


#include <objc/objc-runtime.h>

#include "sq.h"
#include "sqMacUIConstants.h"
#include "sqMacMain.h"
#include "sqMacUIMenuBar.h"
#include "sqMacWindow.h"
#include "sqMacTime.h"
#include "sqMacUIAppleEvents.h"
#include "sqMacImageIO.h"
#include "sqMacUIClipBoard.h"
#include "sqMacFileLogic.h"
#include "sqMacUIEvents.h"
#include "sqMacMemory.h"
#include "sqMacEncoding.h"
#include "sqMacUnixCommandLineInterface.h"
#include "sqMacUnixFileInterface.h"
#include "sqaio.h"
#include "sqMacNSPluginUILogic2.h"
#include "sqUnixCharConv.h"

#include <unistd.h>
#include <pthread.h>
#include <Processes.h>

extern pthread_mutex_t gEventQueueLock,gSleepLock;
extern pthread_cond_t  gSleepLockCondition;

OSErr			gSqueakFileLastError; 
Boolean			gSqueakWindowIsFloating,gSqueakWindowHasTitle=true,gSqueakFloatingWindowGetsFocus=false,gSqueakUIFlushUseHighPercisionClock=false,gSqueakPluginsBuiltInOrLocalOnly=false,gSqueakHeadless=false,gSqueakQuitOnQuitAppleEvent=false,gSqueakExplicitWindowOpenNeeded=false;
long			gSqueakMouseMappings[4][4] = {{0},{0}};
long			gSqueakBrowserMouseMappings[4][4] = {{0},{0}};
usqInt          gMaxHeapSize=512*1024*1024;
UInt32			gSqueakWindowType=zoomDocProc,gSqueakWindowAttributes=0;
long			gSqueakUIFlushPrimaryDeferNMilliseconds=20,gSqueakUIFlushSecondaryCleanupDelayMilliseconds=20,gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds=16,gSqueakDebug=0;
char            gSqueakImageName[PATH_MAX] = "Squeak.image";
char            gSqueakUntrustedDirectoryName[PATH_MAX] = "/foobar/tooBar/forSqueak/bogus/";
char			gSqueakResourceDirectoryName[PATH_MAX] =  "/foobar/tooBar/forSqueak/bogus/";
char            gSqueakTrustedDirectoryName[PATH_MAX] = "/foobar/tooBar/forSqueak/bogus/";
CFStringRef		gSqueakImageNameStringRef;
int				gSqueakBrowserPipes[]= {-1, -1}; 
Boolean			gSqueakBrowserSubProcess = false,gSqueakBrowserWasHeadlessButMadeFullScreen=false;
Boolean			gSqueakBrowserExitRequested = false, gSqueakUseFileMappedMMAP = false;

void cocoInterfaceForTilda(CFStringRef aStringRef, char *buffer,int max_size,int etoysonaStick);
CFStringRef fixupNonAbsolutePath(CFStringRef partialPathString);
/*** Main ***/

/*** Variables -- globals for access from pluggable primitives ***/
int    argCnt= 0;
char **argVec= 0;
char **envVec= 0;

sqInt printAllStacks(void);
extern BOOL NSApplicationLoad(void);

static void sigsegv(int ignore)
{
#pragma unused(ignore)

  /* error("Segmentation fault"); */
  static int printingStack= 0;

  printf("\nSegmentation fault\n\n");
  if (!printingStack)
    {
      printingStack= 1;
      printAllStacks();
    }
  abort();
}


int main(int argc, char **argv, char **envp);

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
void mtfsfi(unsigned long long fpscr);
void mtfsfi(unsigned long long fpscr)
  {
    __asm__("lfd   f0, %0" :: "m"(fpscr));
    __asm__("mtfsf 0xff, f0");
  }
#else
# define mtfsfi(fpscr)
#endif

int main(int argc, char **argv, char **envp) {
	EventRecord theEvent;
	sqImageFile f;
	OSErr err;
	char shortImageName[SHORTIMAGE_NAME_SIZE+1];
        
	/* check the interpreter's size assumptions for basic data types */
	if (sizeof(int) != 4) {
		error("This C compiler's integers are not 32 bits.");
	}
	if (sizeof(double) != 8) {
		error("This C compiler's floats are not 64 bits.");
	}
	if (sizeof(time_t) != 4) {
		error("This C compiler's time_t's are not 32 bits.");
	}

  /* Make parameters global for access from pluggable primitives */
  argCnt= argc;
  argVec= argv;
  envVec= envp;
  
  signal(SIGSEGV, sigsegv);

  fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
  mtfsfi(0);		/* disable signals, IEEE mode, round to nearest */

	LoadScrap();
	SetUpClipboard();
	fetchPrefrences();

	SetVMPathFromApplicationDirectory();

/*	LETS NOT DO THIS, SEE what happens for people wanting to do  ./Squeak.app foobar.image  zingger.st
	
	{
		// Change working directory, this works under os-x, previous logic worked pre os-x 10.4
		
		char target[4097],temp[4097];
		getVMPathWithEncoding(target,gCurrentVMEncoding);
		sqFilenameFromStringOpen(temp,(sqInt) target, strlen(target));
		chdir(temp);
	} */

	/* install apple event handlers and wait for open event */
	InstallAppleEventHandlers();
	while (ShortImageNameIsEmpty()) {
		GetNextEvent(everyEvent, &theEvent);
		if (theEvent.what == kHighLevelEvent) {
			AEProcessAppleEvent(&theEvent);
		}
	}

	unixArgcInterface(argCnt,argVec,envVec);
	
	if (!gSqueakHeadless) {
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		ProcessInfoRec info;
		info.processName = NULL;
		info.processAppSpec = NULL;
		info.processInfoLength = sizeof(ProcessInfoRec);
		GetProcessInformation(&psn,&info);
		if ((info.processMode & modeOnlyBackground) && TransformProcessType != NULL) {
			OSStatus returnCode = TransformProcessType(& psn, kProcessTransformToForegroundApplication);
#pragma unused(returnCode)
			SetFrontProcess(&psn);
		}
//		InitCursor();	large cursor support
	}
	
	getShortImageNameWithEncoding(shortImageName,gCurrentVMEncoding);
    if (gSqueakHeadless && ImageNameIsEmpty()) 
		exit(-42);
		
	if (ImageNameIsEmpty()) {
            CFBundleRef mainBundle;
            CFURLRef imageURL;

            mainBundle = CFBundleGetMainBundle();            
            imageURL = CFBundleCopyResourceURL (mainBundle, gSqueakImageNameStringRef, NULL, NULL);
            if (imageURL != NULL) {
				CFStringRef imagePath;
				
                imagePath = CFURLCopyFileSystemPath (imageURL, kCFURLPOSIXPathStyle);

				SetImageNameViaCFString(imagePath);
                CFRelease(imageURL);
                CFRelease(imagePath);
            } else {
				extern void resolveWhatTheImageNameIs(char *string);
				char	afterCheckForTilda[PATH_MAX];

				cocoInterfaceForTilda(gSqueakImageNameStringRef, afterCheckForTilda,PATH_MAX,0);
				resolveWhatTheImageNameIs(afterCheckForTilda);
			}
	}

	/* read the image file and allocate memory for Squeak heap */
	f = sqImageFileOpen(getImageName(), "rb");
    if (gSqueakHeadless && f == NULL) 
			exit(-43);
	while (f == NULL) {
	    //Failure attempt to ask the user to find the image file
		char pathName[DOCUMENT_NAME_SIZE+1];
		err = squeakFindImage(pathName);
		if (err) 
			ioExit();
		getLastPathComponentInCurrentEncoding(pathName,shortImageName,gCurrentVMEncoding);
		SetShortImageNameViaString(shortImageName,gCurrentVMEncoding);
		SetImageNameViaString(pathName,gCurrentVMEncoding);
		f = sqImageFileOpen(getImageName(), "rb");
 	}

	readImageFromFileHeapSizeStartingAt(f, sqGetAvailableMemory(), 0);
	sqImageFileClose(f);
        
	if (!gSqueakHeadless) {
		SetUpMenus();
	}
	if (!gSqueakHeadless || (gSqueakHeadless && gSqueakBrowserSubProcess)) {
		SetUpPixmap();
	}
		
    SetUpTimers();

    aioInit();
    pthread_mutex_init(&gEventQueueLock, NULL);
	if (gSqueakBrowserSubProcess) {
		extern CGContextRef SharedBrowserBitMapContextRef;
		setupPipes();
		while (SharedBrowserBitMapContextRef == NULL)
			aioSleep(100*1000);
	}
	NSApplicationLoad();	//	Needed for Carbon based applications which call into Cocoa
	RunApplicationEventLoopWithSqueak();
    return 0;
}

sqInt ioExit(void)
{
    return ioExitWithErrorCode(0);
}

sqInt ioExitWithErrorCode(int ec)
{
    UnloadScrap();
    ioShutdownAllModules();
	if (!gSqueakHeadless || gSqueakBrowserWasHeadlessButMadeFullScreen) 
		MenuBarRestore();
	sqMacMemoryFree();
    ExitToShell();
	return 0;
}

int ioDisablePowerManager(int disableIfNonZero) {
	#pragma unused(disableIfNonZero)
	return 0;
}

/*** I/O Primitives ***/

int ioBeep(void) {
	SysBeep(1000);
	return 0;
}

int ioFormPrint(int bitsAddr, int width, int height, int depth, double hScale, double vScale, int landscapeFlag) {
	/* experimental: print a form with the given bitmap, width, height, and depth at
	   the given horizontal and vertical scales in the given orientation
           However John Mcintosh has introduced a printjob class and plugin to replace this primitive */
#pragma unused( bitsAddr,  width,  height,  depth,  hScale,  vScale,  landscapeFlag)
	return true;
}

/*** System Attributes ***/

char * GetAttributeString(int id) {
	/* This is a hook for getting various status strings back from
	   the OS. In particular, it allows Squeak to be passed arguments
	   such as the name of a file to be processed. Command line options
	   are reported this way as well, on platforms that support them.
	*/

	// id #0 should return the full name of VM
	if (id == 0) {
		static char pathToGiveToSqueak[PATH_MAX];
			ux2sqPath(argVec[0], strlen(argVec[0]), pathToGiveToSqueak, VMPATH_SIZE,1);	
            return pathToGiveToSqueak;
        }
	/* Note: 1.3x images will try to read the image as a document because they
	   expect attribute #1 to be the document name. A 1.3x image can be patched
	   using a VM of 2.6 or earlier. */
	if (id == 1) {
            static char path[IMAGE_NAME_SIZE + 1];
            getImageNameWithEncoding(path,gCurrentVMEncoding);
            return path;
        }

	if (id == 1001) return "Mac OS";
	if (id == 1002) {
		long myattr;
		static char data[32];
		
		Gestalt(gestaltSystemVersion, &myattr);
		sprintf(data,"%X",(unsigned int) myattr);
		return data;
	}
	if (id == 1003) {
		long myattr;
		
		Gestalt(gestaltSysArchitecture, &myattr);
		if (myattr == gestalt68k) 
			return "68K";
		if (myattr == gestaltPowerPC) 
			return "powerpc";
		if (myattr == gestaltIntel) 
			return "intel";
	}

   if (id == 1004) {
            CFBundleRef mainBundle;
            CFStringRef versionString;
            static char data[255];
            mainBundle = CFBundleGetMainBundle ();
            versionString = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleShortVersionString"));
            bzero(data,255);
            strcat(data,interpreterVersion);
            strcat(data," ");
            CFStringGetCString (versionString, data+strlen(data), 255-strlen(data), gCurrentVMEncoding);
            return data;            
        }

	/* vm build string */

    if (id == 1006) {
 		return "Mac Carbon 4.2.5b1 15-Jun-10 >85D9C693-2A2A-4C33-B05C-C20B2A63B166<";
//		return "Mac Carbon 4.2.4b1 28-Mar-10 >45CAAEAC-5A1E-4327-9702-7973E3473FDE<";		
// 		return "Mac Carbon 4.2.3b1 13-Mar-10 >551DCCD5-0515-4A91-9316-73DCCB7E7C66<";
// 		return "Mac Carbon 4.2.2b1 17-Sep-09 >6F0202CF-180C-420A-9CE8-411B696D3467<";
// 		return "Mac Carbon 4.2.1b1 19-Aug-09 >4897EDBA-66BA-413A-9117-AC98701639F8<";
// 		return "Mac Carbon 4.1.1b2 7-May-09 >028D94A1-439E-4D2D-9894-AF0DE7F057E8<";
// 		return "Mac Carbon 4.1.1b1 1-May-09 >56D42F58-DC56-4B75-9C58-6CF5D03605CC<";
// 		return "Mac Carbon 4.1.0b1 21-Apr-09 >6A843063-B019-4516-8EBE-67566B766023<";
// 		return "Mac Carbon 4.0.1b1 9-Apr-09 >4403D574-7352-44D7-BEE9-B23B39405A23<";
// 		return "Mac Carbon 4.0.0b1 2-Mar-09 >A1665FE0-5DB6-454C-A1A1-DA7A112BE5C8<";
// 		return "Mac Carbon 3.8.21b1 14-Jan-09 >C116A3FB-EF44-40B3-B957-1A49BF9E2489<";
// 		return "Mac Carbon 3.8.19b2 11-Nov-08 >59849109-3D90-4803-A514-C93849B8FD40<";
// 		return "Mac Carbon 3.8.19b1 28-Oct-08 >36B0938E-7E39-4C53-9E09-F06EAEB9B458<";
// 		return "Mac Carbon 3.8.18b5 05-Sep-08 >0DEC4F6F-198B-47DC-A52F-85B43B5514C0<";
// 		return "Mac Carbon 3.8.18b4 29-May-08 >02DA4BFD-4050-4372-8DBB-9582DA7D0218<";
// 		return "Mac Carbon 3.8.18b3 10-Apr-08 >DC0EAF5D-C46C-479D-B2A3-DBD4A2DF95A8<";
//		return "Mac Carbon 3.8.18b2 17-Aug-07 >F439DEFF-4327-403D-969B-78695EE835DB<";
// 		return "Mac Carbon 3.8.18b1 9-Jun-07 >4C61BDDD-B2AA-4C71-B20D-5758597201EF<";
// 		return "Mac Carbon 3.8.17b5 16-May-07 >BBAC71BE-EF68-4994-8E57-D641A936733F<";
// 		return "Mac Carbon 3.8.17b5 1-May-07 >B389476B-E7F3-4E6A-A8B6-EAE7B39B0EEA<";
// 		return "Mac Carbon 3.8.17b4 27-Apr-07 >3636308B-25D4-4CBB-A515-F3ECC3CEEA5E<";
// 		return "Mac Carbon 3.8.17b3 26-Apr-07 >BBB5CDFC-E9BA-48AC-881E-464EE9718935<";
// 		return "Mac Carbon 3.8.17b2 26-Apr-07 >C4425002-5C1A-4801-A7EC-EBB15025290E<";
// 		return "Mac Carbon 3.8.17b1 25-Apr-07 >9FEB946B-22B5-478C-82DD-776FD6D4E3D6<";
//		return "Mac Carbon 3.8.16b6 17-Apr-07 >D12C988F-2395-413F-9BA2-FC4F27858E06<";
// 		return "Mac Carbon 3.8.16b5 29-Mar-07 >4ACC5390-27F6-40D4-A85A-886C7DF0A591<";
// 		return "Mac Carbon 3.8.16b4 22-Mar-07 >A74B40BA-9CB2-4E3E-A9DA-FB0002315FE6<";
// 		return "Mac Carbon 3.8.16b3 20-Mar-07 >3ABB8EA0-DA9D-47FD-BD1B-6B0A2CB05EE6<";
//		return "Mac Carbon 3.8.16b2 19-Mar-07 >3F52787C-BDE4-42E2-B72D-3CC68F8EE9C1<";
// 		return "Mac Carbon 3.8.16b1 16-Mar-07 >B7FBAF59-7235-44A3-9E3E-173C619EE214<";
// 		return "Mac Carbon 3.8.15b8 13-Mar-07 >6C3CEECE-17C9-488F-B9A0-8CCF48A19352<";
// 		return "Mac Carbon 3.8.15b7 13-Mar-07 >3E759905-E8C5-41EA-95B0-8A3B71C80C97<";
// 		return "Mac Carbon 3.8.15b6 11-Mar-07 >E02C430E-69FD-4AC5-8740-70D3A365A5CC<";
// 		return "Mac Carbon 3.8.15b5 10-Mar-07 >9E3E99A8-A5BD-4360-B425-43380C6057C9<";
// 		return "Mac Carbon 3.8.15b4 26-Feb-07 >639DEC8A-D541-4AF1-8DFF-40D02C177C51<";
//		return "Mac Carbon 3.8.15b3 19-Feb-07 >15CEBDA8-05ED-4CCD-86C4-E737B2E33A64<";
 //		return "Mac Carbon 3.8.15b2X 09-Feb-07 >D0AA85C3-05E7-4709-B8F4-174DB6F1ACDB<";
 //		return "Mac Carbon 3.8.15b2 27-Jan-07 >02EF6EF4-41CE-46DF-8ADF-E4D2EBBD542C<";
 //		return "Mac Carbon 3.8.15b1 22-Jan-07 >4AE66794-B628-44CF-BAA3-1BF3E916054D<";
	}
			
 	if (id == 1201) return "255";
 
	if (id == 1202) {
		static char data[32];

		sprintf(data,"%i",gSqueakFileLastError);
		return data;
	}
	
	if (id < 0 || (id >= 2 && id <= 1000))  {
		char *results;
		results = unixArgcInterfaceGetParm(id);
		if (results) 
			return results;
	}

	/* attribute undefined by this platform */
	success(false);
	return "";
}

int attributeSize(int id) {
	return strlen(GetAttributeString(id));
}

int getAttributeIntoLength(int id, int byteArrayIndex, int length) {
	char *srcPtr, *dstPtr, *end;
	int charsToMove;

	srcPtr = GetAttributeString(id);
	charsToMove = strlen(srcPtr);
	if (charsToMove > length) {
		charsToMove = length;
	}

	dstPtr = (char *) byteArrayIndex;
	end = srcPtr + charsToMove;
	while (srcPtr < end) {
		*dstPtr++ = *srcPtr++;
	}
	return charsToMove;
}


void fetchPrefrences() {
    CFBundleRef  myBundle;
    CFDictionaryRef myDictionary;
    CFNumberRef SqueakWindowType,SqueakMaxHeapSizeType,SqueakUIFlushPrimaryDeferNMilliseconds,SqueakUIFlushSecondaryCleanupDelayMilliseconds,SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds,SqueakDebug;
    CFBooleanRef SqueakWindowHasTitleType,SqueakUseFileMappedMMAP,SqueakFloatingWindowGetsFocusType,SqueakUIFlushUseHighPercisionClock,SqueakPluginsBuiltInOrLocalOnly,SqueakQuitOnQuitAppleEvent,SqueakExplicitWindowOpenNeeded;
	CFNumberRef SqueakMouseMappings[4][4] = {{0},{0}};
	CFNumberRef SqueakBrowserMouseMappings[4][4] = {{0},{0}};
    CFDataRef 	SqueakWindowAttributeType;    
    CFStringRef    SqueakVMEncodingType, SqueakUnTrustedDirectoryTypeRef, SqueakTrustedDirectoryTypeRef, SqueakResourceDirectoryTypeRef;

    char        encoding[256];
    long		i,j;
	
    myBundle = CFBundleGetMainBundle();
    myDictionary = CFBundleGetInfoDictionary(myBundle);
	
    SqueakWindowType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowType"));
    SqueakDebug = CFDictionaryGetValue(myDictionary, CFSTR("SqueakDebug"));
    SqueakQuitOnQuitAppleEvent = CFDictionaryGetValue(myDictionary, CFSTR("SqueakQuitOnQuitAppleEvent"));
    SqueakWindowAttributeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowAttribute"));
    SqueakWindowHasTitleType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowHasTitle"));
	SqueakUseFileMappedMMAP = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUseFileMappedMMAP"));
    SqueakFloatingWindowGetsFocusType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakFloatingWindowGetsFocus"));
    SqueakMaxHeapSizeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMaxHeapSize"));
    SqueakVMEncodingType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakEncodingType"));
    SqueakUnTrustedDirectoryTypeRef  = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUnTrustedDirectory"));
	SqueakResourceDirectoryTypeRef  = CFDictionaryGetValue(myDictionary, CFSTR("SqueakResourceDirectory"));
	SqueakTrustedDirectoryTypeRef  = CFDictionaryGetValue(myDictionary, CFSTR("SqueakTrustedDirectory"));
	SqueakPluginsBuiltInOrLocalOnly = CFDictionaryGetValue(myDictionary, CFSTR("SqueakPluginsBuiltInOrLocalOnly"));
	SqueakExplicitWindowOpenNeeded = CFDictionaryGetValue(myDictionary, CFSTR("SqueakExplicitWindowOpenNeeded"));
    gSqueakImageNameStringRef = CFDictionaryGetValue(myDictionary, CFSTR("SqueakImageName"));
    SqueakUIFlushUseHighPercisionClock = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushUseHighPercisionClock"));
    SqueakUIFlushPrimaryDeferNMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushPrimaryDeferNMilliseconds"));
    SqueakUIFlushSecondaryCleanupDelayMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushSecondaryCleanupDelayMilliseconds"));
    SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds"));
    SqueakMouseMappings[0][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseNoneButton1"));
    SqueakMouseMappings[0][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseNoneButton2"));
    SqueakMouseMappings[0][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseNoneButton3"));
    SqueakMouseMappings[1][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseCmdButton1"));
    SqueakMouseMappings[1][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseCmdButton2"));
    SqueakMouseMappings[1][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseCmdButton3"));
    SqueakMouseMappings[2][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseOptionButton1"));
    SqueakMouseMappings[2][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseOptionButton2"));
    SqueakMouseMappings[2][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseOptionButton3"));
    SqueakMouseMappings[3][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseControlButton1"));
    SqueakMouseMappings[3][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseControlButton2"));
    SqueakMouseMappings[3][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMouseControlButton3"));
    SqueakBrowserMouseMappings[0][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseNoneButton1"));
    SqueakBrowserMouseMappings[0][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseNoneButton2"));
    SqueakBrowserMouseMappings[0][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseNoneButton3"));
    SqueakBrowserMouseMappings[1][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseCmdButton1"));
    SqueakBrowserMouseMappings[1][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseCmdButton2"));
    SqueakBrowserMouseMappings[1][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseCmdButton3"));
    SqueakBrowserMouseMappings[2][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseOptionButton1"));
    SqueakBrowserMouseMappings[2][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseOptionButton2"));
    SqueakBrowserMouseMappings[2][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseOptionButton3"));
    SqueakBrowserMouseMappings[3][1] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseControlButton1"));
    SqueakBrowserMouseMappings[3][2] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseControlButton2"));
    SqueakBrowserMouseMappings[3][3] = CFDictionaryGetValue(myDictionary, CFSTR("SqueakBrowserMouseControlButton3"));
	
    if (SqueakVMEncodingType) 
        CFStringGetCString (SqueakVMEncodingType, encoding, 256, kCFStringEncodingMacRoman);
    else
        *encoding = 0x00;

    setEncodingType(encoding);
    
    if (gSqueakImageNameStringRef) 
        CFStringGetCString (gSqueakImageNameStringRef, gSqueakImageName, IMAGE_NAME_SIZE+1, kCFStringEncodingMacRoman);
	
	if (SqueakUnTrustedDirectoryTypeRef) {
		cocoInterfaceForTilda(SqueakUnTrustedDirectoryTypeRef, gSqueakUntrustedDirectoryName,PATH_MAX,1);
	}
	
	if (SqueakTrustedDirectoryTypeRef) {
		cocoInterfaceForTilda(SqueakTrustedDirectoryTypeRef, gSqueakTrustedDirectoryName,PATH_MAX,1);
	}
	
	if (SqueakResourceDirectoryTypeRef) {
		cocoInterfaceForTilda(SqueakResourceDirectoryTypeRef, gSqueakResourceDirectoryName,PATH_MAX,1);
	}
	
    if (SqueakWindowType) 
        CFNumberGetValue(SqueakWindowType,kCFNumberLongType,&gSqueakWindowType);
    else
        gSqueakWindowType = kDocumentWindowClass;
        
    gSqueakWindowIsFloating = gSqueakWindowType == kUtilityWindowClass;
        
    if (SqueakWindowAttributeType && CFDataGetLength(SqueakWindowAttributeType) == 4) {
            const UInt8 *where;
            where = CFDataGetBytePtr(SqueakWindowAttributeType);
            memmove(&gSqueakWindowAttributes,where,4);
			gSqueakWindowAttributes = CFSwapInt32BigToHost(gSqueakWindowAttributes);
    } else {
        gSqueakWindowAttributes = kWindowStandardDocumentAttributes
            +kWindowStandardHandlerAttribute
            +kWindowNoConstrainAttribute
            -kWindowCloseBoxAttribute;
    }
    
    if (SqueakPluginsBuiltInOrLocalOnly) 
        gSqueakPluginsBuiltInOrLocalOnly = CFBooleanGetValue(SqueakPluginsBuiltInOrLocalOnly);
    else 
        gSqueakPluginsBuiltInOrLocalOnly = false;
        
    if (SqueakExplicitWindowOpenNeeded) 
        gSqueakExplicitWindowOpenNeeded = CFBooleanGetValue(SqueakExplicitWindowOpenNeeded);
    else 
        gSqueakExplicitWindowOpenNeeded = false;
        
    if (SqueakFloatingWindowGetsFocusType) 
        gSqueakFloatingWindowGetsFocus = CFBooleanGetValue(SqueakFloatingWindowGetsFocusType);
    else
        gSqueakFloatingWindowGetsFocus = false;

    if (SqueakWindowHasTitleType) 
        gSqueakWindowHasTitle = CFBooleanGetValue(SqueakWindowHasTitleType);
    else 
        gSqueakWindowHasTitle = true;

	if (SqueakUseFileMappedMMAP) 
        gSqueakUseFileMappedMMAP = CFBooleanGetValue(SqueakUseFileMappedMMAP);
    else 
        gSqueakUseFileMappedMMAP = false;
	
	
    for(i=0;i<4;i++)
		for(j=1;j<4;j++)
			if (SqueakMouseMappings[i][j]) {
				CFNumberGetValue(SqueakMouseMappings[i][j],kCFNumberLongType,(long *) &gSqueakMouseMappings[i][j]);
				if (gSqueakMouseMappings[i][j] < 0 || gSqueakMouseMappings[i][j] > 3)
					gSqueakMouseMappings[i][j] = 0;
				}
		
    for(i=0;i<4;i++)
		for(j=1;j<4;j++)
			if (SqueakBrowserMouseMappings[i][j]) {
				CFNumberGetValue(SqueakBrowserMouseMappings[i][j],kCFNumberLongType,(long *) &gSqueakBrowserMouseMappings[i][j]);
				if (gSqueakBrowserMouseMappings[i][j] < 0 || gSqueakBrowserMouseMappings[i][j] > 3)
					gSqueakBrowserMouseMappings[i][j] = 0;
				}
    if (SqueakMaxHeapSizeType) {
#if SQ_IMAGE64
        CFNumberGetValue(SqueakMaxHeapSizeType,kCFNumberLongLongType,(sqInt *) &gMaxHeapSize);
#else
        CFNumberGetValue(SqueakMaxHeapSizeType,kCFNumberLongType,(sqInt *) &gMaxHeapSize);
#endif
		}
		
	if (SqueakUIFlushUseHighPercisionClock)
        gSqueakUIFlushUseHighPercisionClock = CFBooleanGetValue(SqueakUIFlushUseHighPercisionClock);
    
	if (SqueakUIFlushPrimaryDeferNMilliseconds)
        CFNumberGetValue(SqueakUIFlushPrimaryDeferNMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushPrimaryDeferNMilliseconds);
    
	if (SqueakUIFlushSecondaryCleanupDelayMilliseconds)
        CFNumberGetValue(SqueakUIFlushSecondaryCleanupDelayMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushSecondaryCleanupDelayMilliseconds);

	if (SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds)
        CFNumberGetValue(SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds);
    
	if (SqueakDebug) 
        CFNumberGetValue(SqueakDebug,kCFNumberLongType,&gSqueakDebug);
		
	if (SqueakQuitOnQuitAppleEvent) 
        gSqueakQuitOnQuitAppleEvent = CFBooleanGetValue(SqueakQuitOnQuitAppleEvent);
    else
        gSqueakQuitOnQuitAppleEvent = false;


}

void cocoInterfaceForTilda(CFStringRef aStringRef, char *buffer,int max_size,int isetoysonastick) {
   extern SEL NSSelectorFromString(CFStringRef thing);
   id  autopoolClass = objc_getClass("NSAutoreleasePool");
   id  autopool;
   
	CFStringRef checkFortilda, standardizedString, selectorRef = CFSTR("stringByExpandingTildeInPath"), 
		releaseRef = CFSTR("release"),
		allocRef = CFSTR("alloc"), 
		initRef = CFSTR("init"),
		isAbsolutePathRef = CFSTR("isAbsolutePath"),
		stringByStandardizingPathRef = CFSTR("stringByStandardizingPath");
	SEL selector		=  NSSelectorFromString(selectorRef);
	SEL selectorRelease =  NSSelectorFromString(releaseRef);
	SEL selectoralloc	=  NSSelectorFromString(allocRef);
	SEL selectorInit	=  NSSelectorFromString(initRef);
	SEL stringByStandardizingPath	=  NSSelectorFromString(stringByStandardizingPathRef);
	SEL isAbsolutePath	=  NSSelectorFromString(isAbsolutePathRef);

	autopool = objc_msgSend(autopoolClass, selectoralloc);
	autopool = objc_msgSend(autopool, selectorInit);
	checkFortilda=(CFStringRef)objc_msgSend((id)aStringRef,selector);
	if (isetoysonastick) {
		int isAbsoluteURL = (int)objc_msgSend((id)checkFortilda,isAbsolutePath);
		if (!isAbsoluteURL) {
			CFStringRef	filePath = fixupNonAbsolutePath(checkFortilda);
			standardizedString = (CFStringRef)objc_msgSend((id)filePath,stringByStandardizingPath);
			CFStringGetCString (standardizedString, buffer, max_size, gCurrentVMEncoding);
			CFRelease(filePath);
		} else {
			standardizedString = (CFStringRef)objc_msgSend((id)checkFortilda,stringByStandardizingPath);
			CFStringGetCString (standardizedString, buffer, max_size, gCurrentVMEncoding);
		}
	} else {
		CFStringGetCString (checkFortilda, buffer, max_size, gCurrentVMEncoding);
	}
	autopool = objc_msgSend(autopool, selectorRelease);

}

CFStringRef fixupNonAbsolutePath(CFStringRef partialPathString) {
	CFBundleRef mainBundle;
	CFURLRef	bundleURL,bundleURL2,bundleURL3,resourceURL;
	CFStringRef filePath,resourcePathString;
	
	mainBundle = CFBundleGetMainBundle();   
	bundleURL = CFBundleCopyBundleURL(mainBundle);
	resourceURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
	resourcePathString = CFURLCopyPath(resourceURL);
	CFRelease(resourceURL);
		
	bundleURL2 = CFURLCreateCopyAppendingPathComponent( kCFAllocatorSystemDefault, bundleURL, resourcePathString, false );
	CFRelease(bundleURL);
	CFRelease(resourcePathString);
	bundleURL3 = CFURLCreateCopyAppendingPathComponent( kCFAllocatorSystemDefault, bundleURL2, partialPathString, false );
	CFRelease(bundleURL2);
	filePath = CFURLCopyFileSystemPath (bundleURL3, kCFURLPOSIXPathStyle);
	CFRelease(bundleURL3);
	return filePath;
}


/*** Profiling Stubs ***/

int clearProfile(void){return 0;}														
int dumpProfile(void){return 0;}														
int startProfiling(void){return 0;}													
int stopProfiling(void)	{return 0;}													
