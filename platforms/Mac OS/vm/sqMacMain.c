/****************************************************************************
*   PROJECT: Mac initialization, misc utility routines
*   FILE:    sqMacMain.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMain.c,v 1.22 2004/09/22 18:52:05 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar  8th, 2002, JMM UI locking for applescript under os-x
*  Mar  17th, 2002, JMM look into sleep wakeup issues under os-9 on some computers.
*  Apr  17th, 2002, JMM Use accessors for VM variables, add os-9 check, plus changes by Alain Fischer <alain.fischer@bluewin.ch> to look for image and fetch VM version under os-x
*  Apr  3rd, 2003, JMM use BROWSERPLUGIN
*  Jun 25th, 2003, JMM optional window title. globals for various user preferences
****************************************************************************/

//#define BROWSERPLUGIN to compile code for Netscape or IE Plug-in
//#define IHAVENOHEAD for no head
//#define MINIMALVM to make small small vm

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
*/


#if !TARGET_API_MAC_CARBON 
#include <Power.h>
#endif

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

#ifdef __MPW__
QDGlobals 		qd;
#endif

#if I_AM_CARBON_EVENT
    #include <pthread.h>
    extern pthread_mutex_t gEventQueueLock,gEventUILock,gEventDrawLock,gEventNSAccept,gSleepLock;
    extern pthread_cond_t  gEventUILockCondition,gSleepLockCondition;

    pthread_t gSqueakPThread;
#endif

#if defined ( __APPLE__ ) && defined ( __MACH__ )
    #include "aio.h"
#endif 

extern int  getFullScreenFlag();
extern unsigned char *memory;
extern squeakFileOffsetType calculateStartLocationForImage();
Boolean         gTapPowerManager=false;
Boolean         gDisablePowerManager=false;
Boolean         gThreadManager=false;
ThreadID        gSqueakThread = kNoThreadID;
ThreadEntryUPP  gSqueakThreadUPP;
OSErr			gSqueakFileLastError; 
Boolean		gSqueakWindowIsFloating,gSqueakWindowHasTitle=true,gSqueakFloatingWindowGetsFocus=false;
UInt32          gMaxHeapSize=512*1024*1024,gSqueakWindowType,gSqueakWindowAttributes;

#ifdef BROWSERPLUGIN
/*** Variables -- Imported from Browser Plugin Module ***/
extern int pluginArgCount;
extern char *pluginArgName[100];
extern char *pluginArgValue[100];
#endif

void InitMacintosh(void);
char * GetAttributeString(int id);
void SqueakTerminate();
void ExitCleanup();
void PowerMgrCheck(void);
OSErr   createNewThread();
static pascal void* squeakThread(void *threadParm);
void SetUpCarbonEvent();
void fetchPrefrences();
  
/*** Main ***/

#ifndef BROWSERPLUGIN
#if defined ( __APPLE__ ) && defined ( __MACH__ )
/*** Variables -- globals for access from pluggable primitives ***/
int    argCnt= 0;
char **argVec= 0;
char **envVec= 0;

int main(int argc, char **argv, char **envp) {
#else
int main(void) {
#endif
	EventRecord theEvent;
	sqImageFile f;
	OSErr err;
	char shortImageName[256];
#if !defined(MINIMALVM)  && !defined ( __APPLE__ ) && !defined ( __MACH__ )
        long threadGestaltInfo;
#endif
        
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

#if defined ( __APPLE__ ) && defined ( __MACH__ )
  /* Make parameters global for access from pluggable primitives */
  argCnt= argc;
  argVec= argv;
  envVec= envp;
#endif

 	InitMacintosh();
	PowerMgrCheck();
	
	SetUpMenus();
	SetUpClipboard();
        fetchPrefrences();

#ifndef I_AM_CARBON_EVENT
	SetEventMask(everyEvent); // also get key up events
#endif
	/* install apple event handlers and wait for open event */
	InstallAppleEventHandlers();
	while (ShortImageNameIsEmpty()) {
		GetNextEvent(everyEvent, &theEvent);
		if (theEvent.what == kHighLevelEvent) {
			AEProcessAppleEvent(&theEvent);
		}
	}
                
        getShortImageNameWithEncoding(shortImageName,gCurrentVMEncoding);
         
	if (ImageNameIsEmpty()) {
            FSSpec	workingDirectory;
#if TARGET_API_MAC_CARBON && !defined(__MWERKS__)
            CFBundleRef mainBundle;
            CFURLRef imageURL;
            CFStringRef imagePath;

            mainBundle = CFBundleGetMainBundle();            
            imageURL = CFBundleCopyResourceURL (mainBundle, CFSTR("Squeak"), CFSTR("image"), NULL);
            if (imageURL != NULL) {
                imagePath = CFURLCopyFileSystemPath (imageURL, kCFURLHFSPathStyle);
                SetImageNameViaCFString(imagePath);
                CFRelease(imageURL);
                CFRelease(imagePath);
            } else {
#endif

		err = GetApplicationDirectory(&workingDirectory);
		if (err != noErr) 
                    error("Could not obtain default directory");
                CopyCStringToPascal("Squeak.image",workingDirectory.name);
		SetImageName(&workingDirectory);
#if TARGET_API_MAC_CARBON && !defined(__MWERKS__)
            }
#endif
	}

	/* uncomment the following when using the C transcript window for debugging: */
	//printf("Move this window, then hit CR\n"); getchar();

	/* read the image file and allocate memory for Squeak heap */
	f = sqImageFileOpen(getImageName(), "rb");
	while (f == NULL) {
	    //Failure attempt to ask the user to find the image file
	    
	    FSSpec vmfsSpec,imageFsSpec;
	    WDPBRec wdPB;
            char path[VMPATH_SIZE + 1];
            
            getVMPathWithEncoding(path,gCurrentVMEncoding);

	    err =  makeFSSpec(path,strlen(path),&vmfsSpec);
	    if (err) 
	        ioExit();
            err = squeakFindImage(&vmfsSpec,&imageFsSpec);
	    if (err) 
	        ioExit();
	    CopyPascalStringToC(imageFsSpec.name,shortImageName);
            SetShortImageNameViaString(shortImageName,gCurrentVMEncoding);
            SetImageName(&imageFsSpec);

			/* make the image or document directory the working directory */
    	wdPB.ioNamePtr = NULL;
    	wdPB.ioVRefNum = imageFsSpec.vRefNum;
    	wdPB.ioWDDirID = imageFsSpec.parID;
    	PBHSetVolSync(&wdPB);
    	f = sqImageFileOpen(getImageName(), "rb");
 	}
	
	readImageFromFileHeapSizeStartingAt(f, sqGetAvailableMemory(), calculateStartLocationForImage());
	sqImageFileClose(f);
	SetUpWindow();
        
#ifndef MINIMALVM
	 ioLoadFunctionFrom(NULL, "DropPlugin");
#endif
    
#ifndef IHAVENOHEAD
        if (gSqueakWindowHasTitle) 
	SetWindowTitle(shortImageName);
#if I_AM_CARBON_EVENT	
        ioSetFullScreenActual(getFullScreenFlag());
#else
	ioSetFullScreen(getFullScreenFlag());
#endif
#endif

#if (!(defined JITTER) && defined(__MPW__))
	atexit(SqueakTerminate);
#endif

    SetUpTimers();

#if I_AM_CARBON_EVENT && defined ( __APPLE__ ) && defined ( __MACH__ )
    {
    
    aioInit();
    gThreadManager = false;
    pthread_mutex_init(&gEventQueueLock, NULL);
    pthread_mutex_init(&gEventUILock, NULL);
    pthread_cond_init(&gEventUILockCondition,NULL);
    err = pthread_create(&gSqueakPThread,null,(void *) interpret, null);
    if (err == 0) {
        SetUpCarbonEvent();
        RunApplicationEventLoop(); //Note the application under carbon event mgr starts running here
        }
    }
    return 0; //Note the return, need to refactor this ugly code
#endif

#if !defined(MINIMALVM)  && !defined ( __APPLE__ ) && !defined ( __MACH__ )
    if( Gestalt( gestaltThreadMgrAttr, &threadGestaltInfo) == noErr &&
        threadGestaltInfo & (1<<gestaltThreadMgrPresent) &&
        ((Ptr) NewThread != (Ptr)kUnresolvedCFragSymbolAddress)) {
        gThreadManager = true;
        err = createNewThread();
        if (err == noErr) {
            while(true)  {
                ioProcessEvents();
        		SqueakYieldToAnyThread();
            }
            return 0;
        }
    }
#endif
    gThreadManager = false;
    /* run Squeak */
    squeakThread(0);
    return 0;
}
#endif

#ifdef BROWSERPLUGIN
OSErr createNewThread() {
#if I_AM_CARBON_EVENT && defined ( __APPLE__ ) && defined ( __MACH__ )
    {
        OSErr err;
        
        aioInit();
        gThreadManager = false;
        pthread_mutex_init(&gEventQueueLock, NULL);
        pthread_mutex_init(&gEventUILock, NULL);
        pthread_mutex_init(&gEventDrawLock, NULL);
        pthread_mutex_init(&gEventNSAccept, NULL);
        pthread_cond_init(&gEventUILockCondition,NULL);
        err = pthread_create(&gSqueakPThread,null,(void *) interpret, null);
    }
    #else
        gSqueakThreadUPP = NewThreadEntryUPP(squeakThread); //We should dispose of someday
	return NewThread( kCooperativeThread, gSqueakThreadUPP, nil, 80*1024, kCreateIfNeeded+kNewSuspend, 0L, &gSqueakThread);
    #endif
	return 0;
}

#else
OSErr createNewThread() {
    gSqueakThreadUPP = NewThreadEntryUPP(squeakThread); //We should dispose of someday
    return NewThread( kCooperativeThread, gSqueakThreadUPP, nil, 80*1024, kCreateIfNeeded, 0L, &gSqueakThread);
}

#endif
pascal short SqueakYieldToAnyThread(void) {
#if !defined( I_AM_CARBON_EVENT) && !defined ( __APPLE__ ) && !defined ( __MACH__ )
    YieldToAnyThread();
    #endif
	return 0;
}

static pascal void* squeakThread(void *threadParm) {
	/* run Squeak */
#pragma unused(threadParm)
#	ifdef JITTER
	j_interpret();
#	else
	interpret();
#	endif
	return 0;
}

#if TARGET_API_MAC_CARBON
void InitMacintosh(void) {
#ifndef I_AM_CARBON_EVENT
	FlushEvents(everyEvent, 0);
#endif
	LoadScrap();
	InitCursor();
}
#else
void InitMacintosh(void) {
    MaxApplZone();
    InitGraf(&qd.thePort);
    InitFonts();
    FlushEvents(everyEvent, 0);
    InitWindows();
    InitMenus();
    TEInit();
    InitDialogs(NULL);
    InitCursor();
    LoadScrap();
    //JMM causes sleep wakeup issues. SetupKeyboard();	
}
#endif

void PowerMgrCheck(void) {
	long pmgrAttributes;
	
	gTapPowerManager = false;
	gDisablePowerManager = false;
#ifndef MINIMALVM
	if (! Gestalt(gestaltPowerMgrAttr, &pmgrAttributes))
		if ((pmgrAttributes & (1<<gestaltPMgrExists)) 
		    && (pmgrAttributes & (1<<gestaltPMgrDispatchExists))
		    && (PMSelectorCount() >= 0x24)) {
		    gTapPowerManager = true;
		}
#endif
}

int ioDisablePowerManager(int disableIfNonZero) {
    gDisablePowerManager = disableIfNonZero;
	return 0;
}

Boolean RunningOnCarbonX(void)
{
    UInt32 response;
    
    return (Gestalt(gestaltSystemVersion, 
                    (SInt32 *) &response) == noErr)
                && (response >= 0x01000);
}

Boolean isSystem9_0_or_better(void)
{
    UInt32	response;
    OSErr	error;
    
    error = Gestalt(gestaltSystemVersion, 
                    (SInt32 *) &response);
    return ((error == noErr)
                && (response >= 0x0900));
}

/*** I/O Primitives ***/

int ioBeep(void) {
	SysBeep(1000);
	return 0;
}

#ifndef BROWSERPLUGIN
int ioExit(void) {
    UnloadScrap();
    ioShutdownAllModules();
    MenuBarRestore();
	sqMacMemoryFree();
    ExitToShell();
	return 0;
}
#endif

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
		unsigned int myattr;
		static char data[32];
		
		Gestalt(gestaltSystemVersion, (long *) &myattr);
		sprintf(data,"%X",myattr);
		return data;
	}
	if (id == 1003) {
		long myattr;
		
		Gestalt(gestaltSysArchitecture, &myattr);
		if (myattr == gestalt68k) 
			return "68K";
		else
			return "powerpc";
	}

#if TARGET_API_MAC_CARBON && !defined(__MWERKS__)
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
#endif

#if defined(__MWERKS__)
	if (id == 1004) return (char *) interpreterVersion;
#endif

#if TARGET_API_MAC_CARBON
	if (id == 1201) return (isVmPathVolumeHFSPlus() ? "255" : "31");  //name size on hfs plus volumes
#endif
	if (id == 1202) {
		static char data[32];

		sprintf(data,"%i",gSqueakFileLastError);
		return data;
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

#ifdef BROWSERPLUGIN

/*** Plugin Support ***/

int plugInInit(char *fullImagePath) {

	#pragma unused(fullImagePath)
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

	PowerMgrCheck();
	SetUpClipboard();
	SetUpPixmap();
	return 0;
}

int plugInShutdown(void) {
        int err;
        
	ioShutdownAllModules();
	FreeClipboard();
	FreePixmap();
	if (memory != nil) {
        if (gThreadManager)
	        DisposeThread(gSqueakThread,null,true);
#if I_AM_CARBON_EVENT && defined ( __APPLE__ ) && defined ( __MACH__ )
        err = pthread_cancel(gSqueakPThread);
        if (err == 0 )
        pthread_join(gSqueakPThread,NULL);
        pthread_mutex_destroy(&gEventQueueLock);
        pthread_mutex_destroy(&gEventUILock);
        pthread_mutex_destroy(&gEventDrawLock);
		pthread_mutex_destroy(&gEventNSAccept);
        pthread_mutex_destroy(&gSleepLock);
        pthread_cond_destroy(&gEventUILockCondition);
        pthread_cond_destroy(&gSleepLockCondition);
#endif        
	    sqMacMemoryFree();
	}
	return 0;
}

#endif

#if TARGET_API_MAC_CARBON
void fetchPrefrences() {
    CFBundleRef  myBundle;
    CFDictionaryRef myDictionary;
    CFNumberRef SqueakWindowType,SqueakMaxHeapSizeType;
    CFBooleanRef SqueakWindowHasTitleType,SqueakFloatingWindowGetsFocusType;
    CFDataRef 	SqueakWindowAttributeType;    
    CFStringRef    SqueakVMEncodingType;
    char        encoding[256];
    
    myBundle = CFBundleGetMainBundle();
    myDictionary = CFBundleGetInfoDictionary(myBundle);
    SqueakWindowType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowType"));
    SqueakWindowAttributeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowAttribute"));
    SqueakWindowHasTitleType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowHasTitle"));
    SqueakFloatingWindowGetsFocusType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakFloatingWindowGetsFocus"));
    SqueakMaxHeapSizeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMaxHeapSize"));
    SqueakVMEncodingType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakEncodingType"));
    
    
    if (SqueakVMEncodingType) 
        CFStringGetCString (SqueakVMEncodingType, encoding, 255, kCFStringEncodingMacRoman);
    else
        *encoding = 0x00;

    setEncodingType(encoding);
    
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
    
    if (SqueakWindowHasTitleType) 
        gSqueakWindowHasTitle = CFBooleanGetValue(SqueakWindowHasTitleType);
    else 
        gSqueakWindowHasTitle = true;
        
    if (SqueakFloatingWindowGetsFocusType) 
        gSqueakFloatingWindowGetsFocus = CFBooleanGetValue(SqueakFloatingWindowGetsFocusType);
    else
        gSqueakFloatingWindowGetsFocus = false;

    if (SqueakMaxHeapSizeType) 
        CFNumberGetValue(SqueakMaxHeapSizeType,kCFNumberLongType,(long *) &gMaxHeapSize);
    
}
#else
void fetchPrefrences() {}
#endif 


/*** Profiling Stubs ***/

int clearProfile(void){return 0;}														
int dumpProfile(void){return 0;}														
int startProfiling(void){return 0;}													
int stopProfiling(void)	{return 0;}													

#if TARGET_API_MAC_CARBON && defined(__MWERKS__)
int printOnOSX(char * string);
int printOnOSXNumber(int number);
int printOnOSXPascal(unsigned char * string);
int printOnOSXFormat(char * string,char *format);
OSStatus LoadFrameworkBundle(CFStringRef framework, CFBundleRef
*bundlePtr);

OSStatus LoadFrameworkBundle(CFStringRef framework, CFBundleRef
*bundlePtr)
{
    OSStatus    err;
    FSRef       frameworksFolderRef;
    CFURLRef    baseURL;
    CFURLRef    bundleURL;

    if ( bundlePtr == nil ) return( -1 );

    *bundlePtr = nil;
 
    baseURL = nil;
    bundleURL = nil;
 
    err = FSFindFolder(kOnAppropriateDisk, kFrameworksFolderType, true,
&frameworksFolderRef);
    if (err == noErr) {
        baseURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault,
&frameworksFolderRef);
        if (baseURL == nil) {
            err = coreFoundationUnknownErr;
        }
    }
    if (err == noErr) {
        bundleURL =
CFURLCreateCopyAppendingPathComponent(kCFAllocatorSystemDefault, baseURL,
framework, false);
        if (bundleURL == nil) {
            err = coreFoundationUnknownErr;
        }
    }
    if (err == noErr) {
        *bundlePtr = CFBundleCreate(kCFAllocatorSystemDefault, bundleURL);
        if (*bundlePtr == nil) {
            err = coreFoundationUnknownErr;
        }
    }
    if (err == noErr) {
        if ( ! CFBundleLoadExecutable( *bundlePtr ) ) {
            err = coreFoundationUnknownErr;
        }
    }

    // Clean up.
    if (err != noErr && *bundlePtr != nil) {
        CFRelease(*bundlePtr);
        *bundlePtr = nil;
    }
    if (bundleURL != nil) {
        CFRelease(bundleURL);
    }

    if (baseURL != nil) {
        CFRelease(baseURL);
    }

    return err;
}

int printOnOSXFormat(char * string,char *format) {
	CFBundleRef bundle;
	int(*fprintf_ptr)(FILE *stream, const char *format, ...) = NULL;
	void* fcn_ptr = NULL;
	OSErr	err;
	FILE* stderr_ptr = NULL;
	void* __sf_ptr = NULL;
	
	err = LoadFrameworkBundle( CFSTR("System.framework"), &bundle );

	fcn_ptr = CFBundleGetFunctionPointerForName(bundle, CFSTR("fprintf"));
	__sf_ptr = CFBundleGetDataPointerForName(bundle, CFSTR("__sF"));
	
	if(fcn_ptr) {
	   /* cast it */
	   fprintf_ptr = ( int(*)(FILE *stream, const char *format, ...) ) fcn_ptr;
	} else {
	   /* it failed, handle that somehow */
	   return;
	}

	if(__sf_ptr) {
	   stderr_ptr = (FILE*) ( ((char*)__sf_ptr) + 176);
	   /* 176 = 88*2, where 88=sizeof(FILE) under BSD */
	} else {
	   /* it failed */
	   return;
	}

	fprintf_ptr(stderr_ptr, format,string);
}

int printOnOSX(char * string) {
	return printOnOSXFormat(string,"\n+-+%s");
}

int printOnOSXNumber(int number) {
	return printOnOSXFormat((char *) number,"\n+-+%d");
}

int printOnOSXPascal(unsigned char *string) {
	CopyPascalStringToC((ConstStr255Param) string,(char*) string);
	printOnOSX((char*) string);
	CopyCStringToPascal((char*)string,(void *) string);
}

#endif