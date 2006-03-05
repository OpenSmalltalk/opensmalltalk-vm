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
#include <unistd.h>
#include <pthread.h>

extern pthread_mutex_t gEventQueueLock,gEventUILock,gSleepLock;
extern pthread_cond_t  gEventUILockCondition,gSleepLockCondition;

    pthread_t gSqueakPThread;

OSErr			gSqueakFileLastError; 
Boolean			gSqueakWindowIsFloating,gSqueakWindowHasTitle=true,gSqueakFloatingWindowGetsFocus=false,gSqueakUIFlushUseHighPercisionClock=false,gSqueakPluginsBuiltInOrLocalOnly=false;
UInt32          gMaxHeapSize=512*1024*1024,gSqueakWindowType=zoomDocProc,gSqueakWindowAttributes=0;
long			gSqueakUIFlushPrimaryDeferNMilliseconds=20,gSqueakUIFlushSecondaryCleanupDelayMilliseconds=20,gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds=16;
char            gSqueakImageName[2048] = "Squeak.image";
CFStringRef		gSqueakImageNameStringRef;

#ifdef BROWSERPLUGIN
/*** Variables -- Imported from Browser Plugin Module ***/
extern int pluginArgCount;
extern char *pluginArgName[100];
extern char *pluginArgValue[100];
#endif


/*** Main ***/

#ifndef BROWSERPLUGIN
/*** Variables -- globals for access from pluggable primitives ***/
int    argCnt= 0;
char **argVec= 0;
char **envVec= 0;

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

	LoadScrap();
	InitCursor();
	
	SetUpMenus();
	SetUpClipboard();
	fetchPrefrences();
	SetUpPixmap();

	SetVMPathFromApplicationDirectory();

	{
		// Change working directory, this works under os-x, previous logic worked pre os-x 10.4
		
		char target[4097],temp[4097];
		getVMPathWithEncoding(target,gCurrentVMEncoding);
		sqFilenameFromStringOpen(temp,(long) target, strlen(target));
		chdir(temp);
	}

	/* install apple event handlers and wait for open event */
	InstallAppleEventHandlers();
	while (ShortImageNameIsEmpty()) {
		GetNextEvent(everyEvent, &theEvent);
		if (theEvent.what == kHighLevelEvent) {
			AEProcessAppleEvent(&theEvent);
		}
	}

	unixArgcInterface(argCnt,argVec,envVec);
	getShortImageNameWithEncoding(shortImageName,gCurrentVMEncoding);
         
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
				extern SEL NSSelectorFromString(CFStringRef thing);
				CFStringRef checkFortilda;
				char	afterCheckForTilda[2048];
				
				checkFortilda=(CFStringRef)objc_msgSend((id)gSqueakImageNameStringRef, NSSelectorFromString((CFStringRef)CFSTR("stringByExpandingTildeInPath")));
				CFStringGetCString (checkFortilda, afterCheckForTilda, 2048, gCurrentVMEncoding);

				resolveWhatTheImageNameIs(afterCheckForTilda);
				CFRelease(checkFortilda);
			}
	}

	/* read the image file and allocate memory for Squeak heap */
	f = sqImageFileOpen(getImageName(), "rb");
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
        
    SetUpTimers();

    aioInit();
    pthread_mutex_init(&gEventQueueLock, NULL);
    pthread_mutex_init(&gEventUILock, NULL);
    pthread_cond_init(&gEventUILockCondition,NULL);
    err = pthread_create(&gSqueakPThread,null,(void *) interpret, null);
    if (err == 0) {
        SetUpCarbonEvent();
        RunApplicationEventLoop(); //Note the application under carbon event mgr starts running here
	}
    return 0;
}

int ioExit(void) {
    UnloadScrap();
    ioShutdownAllModules();
    MenuBarRestore();
	sqMacMemoryFree();
    ExitToShell();
	return 0;
}

#endif

int ioDisablePowerManager(int disableIfNonZero) {
	#pragma unused(disableIfNonZero)
	return 0;
}

/*** I/O Primitives ***/

int ioBeep(void) {
	SysBeep(1000);
	return 0;
}

void SqueakTerminate() {
#ifdef BROWSERPLUGIN
	ExitCleanup();
#else
	UnloadScrap();
	ioShutdownAllModules();
	sqMacMemoryFree();
#endif
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

	// id #0 should return the full name of VM; for now it just returns its path
	if (id == 0) {
            static char path[VMPATH_SIZE + 1];
            getVMPathWithEncoding(path,gCurrentVMEncoding);
            return path;
        }
	/* Note: 1.3x images will try to read the image as a document because they
	   expect attribute #1 to be the document name. A 1.3x image can be patched
	   using a VM of 2.6 or earlier. */
	if (id == 1) {
            static char path[IMAGE_NAME_SIZE + 1];
            getImageNameWithEncoding(path,gCurrentVMEncoding);
            return path;
        }

	if (id == 2) {
            static char path[DOCUMENT_NAME_SIZE + 1];
            getDocumentNameWithEncoding(path,gCurrentVMEncoding);
            return path;
        }

#ifdef BROWSERPLUGIN
	/* When running in browser, return the EMBED tag info */
	if ((id > 2) && (id <= (2 + (2 * pluginArgCount)))) {
		int i = id - 3;
		if ((i & 1) == 0) {  /* i is even */
			return pluginArgName[i/2];
		} else {
			return pluginArgValue[i/2];
		}
	}
#endif

	if (id == 1001) return "Mac OS";
	if (id == 1002) {
		long myattr;
		static char data[32];
		
		Gestalt(gestaltSystemVersion, &myattr);
		sprintf(data,"%X",myattr);
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
#if BROWSERPLUGIN
	#if SOPHIEVM
	CFStringRef		bundleID= CFStringCreateWithCString(null,"org.squeak.SophiePlugin",kCFStringEncodingMacRoman);
	#else
	CFStringRef		bundleID= CFStringCreateWithCString(null,"org.squeak.SqueakPlugin",kCFStringEncodingMacRoman);
	#endif
    mainBundle = CFBundleGetBundleWithIdentifier(bundleID);
	CFRelease(bundleID);
#else
            mainBundle = CFBundleGetMainBundle ();
#endif
            versionString = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleShortVersionString"));
            bzero(data,255);
            strcat(data,interpreterVersion);
            strcat(data," ");
            CFStringGetCString (versionString, data+strlen(data), 255-strlen(data), gCurrentVMEncoding);
            return data;            
        }

 	if (id == 1201) return "255";
 
	if (id == 1202) {
		static char data[32];

		sprintf(data,"%i",gSqueakFileLastError);
		return data;
	}
	
#ifndef BROWSERPLUGIN
	if (id < 0 || (id > 2 && id <= 1000))  {
		char *results;
		results = unixArgcInterfaceGetParm(id);
		if (results) 
			return results;
	}
#endif

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
    CFNumberRef SqueakWindowType,SqueakMaxHeapSizeType,SqueakUIFlushPrimaryDeferNMilliseconds,SqueakUIFlushSecondaryCleanupDelayMilliseconds,SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds;
    CFBooleanRef SqueakWindowHasTitleType,SqueakFloatingWindowGetsFocusType,SqueakUIFlushUseHighPercisionClock,SqueakPluginsBuiltInOrLocalOnly;
    CFDataRef 	SqueakWindowAttributeType;    
    CFStringRef    SqueakVMEncodingType;

    char        encoding[256];
    
#if BROWSERPLUGIN
	#if SOPHIEVM
	CFStringRef		bundleID= CFStringCreateWithCString(null,"org.squeak.SophiePlugin",kCFStringEncodingMacRoman);
	#else
	CFStringRef		bundleID= CFStringCreateWithCString(null,"org.squeak.SqueakPlugin",kCFStringEncodingMacRoman);
	#endif
	myBundle = CFBundleGetBundleWithIdentifier(bundleID);
	CFRelease(bundleID);
#else
    myBundle = CFBundleGetMainBundle();
#endif
    myDictionary = CFBundleGetInfoDictionary(myBundle);
	
    SqueakWindowType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowType"));
    SqueakWindowAttributeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowAttribute"));
    SqueakWindowHasTitleType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowHasTitle"));
    SqueakFloatingWindowGetsFocusType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakFloatingWindowGetsFocus"));
    SqueakMaxHeapSizeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMaxHeapSize"));
    SqueakVMEncodingType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakEncodingType"));
    SqueakPluginsBuiltInOrLocalOnly = CFDictionaryGetValue(myDictionary, CFSTR("SqueakPluginsBuiltInOrLocalOnly"));
    gSqueakImageNameStringRef = CFDictionaryGetValue(myDictionary, CFSTR("SqueakImageName"));
    SqueakUIFlushUseHighPercisionClock = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushUseHighPercisionClock"));
    SqueakUIFlushPrimaryDeferNMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushPrimaryDeferNMilliseconds"));
    SqueakUIFlushSecondaryCleanupDelayMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushSecondaryCleanupDelayMilliseconds"));
    SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds = CFDictionaryGetValue(myDictionary, CFSTR("SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds"));

    if (SqueakVMEncodingType) 
        CFStringGetCString (SqueakVMEncodingType, encoding, 256, kCFStringEncodingMacRoman);
    else
        *encoding = 0x00;

    setEncodingType(encoding);
    
    if (gSqueakImageNameStringRef) 
        CFStringGetCString (gSqueakImageNameStringRef, gSqueakImageName, IMAGE_NAME_SIZE+1, kCFStringEncodingMacRoman);
	
    if (SqueakWindowType) 
        CFNumberGetValue(SqueakWindowType,kCFNumberLongType,&gSqueakWindowType);
    else
        gSqueakWindowType = kDocumentWindowClass;
        
    gSqueakWindowIsFloating = gSqueakWindowType == kUtilityWindowClass;
        
    if (SqueakWindowAttributeType && CFDataGetLength(SqueakWindowAttributeType) == 4) {
            const UInt8 *where;
            where = CFDataGetBytePtr(SqueakWindowAttributeType);
            memmove(&gSqueakWindowAttributes,where,4);
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
        
    if (SqueakFloatingWindowGetsFocusType) 
        gSqueakFloatingWindowGetsFocus = CFBooleanGetValue(SqueakFloatingWindowGetsFocusType);
    else
        gSqueakFloatingWindowGetsFocus = false;

    if (SqueakWindowHasTitleType) 
        gSqueakWindowHasTitle = CFBooleanGetValue(SqueakWindowHasTitleType);
    else 
        gSqueakWindowHasTitle = true;
        
    if (SqueakMaxHeapSizeType) 
        CFNumberGetValue(SqueakMaxHeapSizeType,kCFNumberLongType,(long *) &gMaxHeapSize);
		
	if (SqueakUIFlushUseHighPercisionClock)
        gSqueakUIFlushUseHighPercisionClock = CFBooleanGetValue(SqueakUIFlushUseHighPercisionClock);
    
	if (SqueakUIFlushPrimaryDeferNMilliseconds)
        CFNumberGetValue(SqueakUIFlushPrimaryDeferNMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushPrimaryDeferNMilliseconds);
    
	if (SqueakUIFlushSecondaryCleanupDelayMilliseconds)
        CFNumberGetValue(SqueakUIFlushSecondaryCleanupDelayMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushSecondaryCleanupDelayMilliseconds);

	if (SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds)
        CFNumberGetValue(SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds,kCFNumberLongType,(long *) &gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds);
    
    
}

/*** Profiling Stubs ***/

int clearProfile(void){return 0;}														
int dumpProfile(void){return 0;}														
int startProfiling(void){return 0;}													
int stopProfiling(void)	{return 0;}													