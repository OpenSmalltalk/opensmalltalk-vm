/****************************************************************************
*   PROJECT: Mac initialization, misc utility routines
*   FILE:    sqMacMain.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMain.c,v 1.7 2002/03/25 07:04:31 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar  8th, 2002, JMM UI locking for applescript under os-x
*  Mar  17th, 2002, JMM look into sleep wakeup issues under os-9 on some computers.
****************************************************************************/

//#define PLUGIN to compile code for Netscape or IE Plug-in
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

#ifdef __MPW__
QDGlobals 		qd;
#endif

#if I_AM_CARBON_EVENT
    #include <pthread.h>
    extern pthread_mutex_t gEventQueueLock,gEventUILock;
    extern pthread_cond_t  gEventUILockCondition;
#endif
 
extern char shortImageName[];
extern char documentName[];
extern char vmPath[];
extern int  fullScreenFlag;
extern unsigned char *memory;
extern squeakFileOffsetType calculateStartLocationForImage();
Boolean         gTapPowerManager=false;
Boolean         gDisablePowerManager=false;
Boolean         gThreadManager=false;
ThreadID        gSqueakThread = kNoThreadID;
ThreadEntryUPP  gSqueakThreadUPP;

#ifdef PLUGIN
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
  
/*** Main ***/

#ifndef PLUGIN
int main(void) {
	EventRecord theEvent;
	sqImageFile f;
	OSErr err;
    long threadGestaltInfo;
    FSSpec	workingDirectory;
        
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

 	InitMacintosh();
	PowerMgrCheck();
	
	SetUpMenus();
	SetUpClipboard();
	SetUpWindow();
        SetUpTimers();
#ifndef I_AM_CARBON_EVENT
	SetEventMask(everyEvent); // also get key up events
#endif
	/* install apple event handlers and wait for open event */
	imageName[0] = shortImageName[0] = documentName[0] = vmPath[0] = 0;
	InstallAppleEventHandlers();
	while (shortImageName[0] == 0) {
		GetNextEvent(everyEvent, &theEvent);
		if (theEvent.what == kHighLevelEvent) {
			AEProcessAppleEvent(&theEvent);
		}
	}
                
	if (imageName[0] == 0) {
		err = GetApplicationDirectory(&workingDirectory);
		if (err != noErr) 
                    error("Could not obtain default directory");
                CopyCStringToPascal("squeak.image",workingDirectory.name);
		PathToFile(imageName, IMAGE_NAME_SIZE, &workingDirectory);
	}

	/* uncomment the following when using the C transcript window for debugging: */
	//printf("Move this window, then hit CR\n"); getchar();

	/* read the image file and allocate memory for Squeak heap */
	f = sqImageFileOpen(imageName, "rb");
	while (f == NULL) {
	    //Failure attempt to ask the user to find the image file
	    
	    FSSpec vmfsSpec,imageFsSpec;
	    WDPBRec wdPB;
	    
	    err =  makeFSSpec(vmPath,vmPathSize(),&vmfsSpec);
	    if (err) 
	        ioExit();
            err = squeakFindImage(&vmfsSpec,&imageFsSpec);
	    if (err) 
	        ioExit();
	    CopyPascalStringToC(imageFsSpec.name,shortImageName);
            PathToFile(imageName, IMAGE_NAME_SIZE, &imageFsSpec);

			/* make the image or document directory the working directory */
    	wdPB.ioNamePtr = NULL;
    	wdPB.ioVRefNum = imageFsSpec.vRefNum;
    	wdPB.ioWDDirID = imageFsSpec.parID;
    	PBHSetVolSync(&wdPB);
    	f = sqImageFileOpen(imageName, "rb");
 	}
	
	readImageFromFileHeapSizeStartingAt(f, sqGetAvailableMemory(), calculateStartLocationForImage());
	sqImageFileClose(f);
        
#ifndef MINIMALVM
	 ioLoadFunctionFrom(NULL, "DropPlugin");
#endif
    
#ifndef IHAVENOHEAD
	SetWindowTitle(shortImageName);
	ioSetFullScreen(fullScreenFlag);
#endif

#if (!(defined JITTER) && defined(__MPW__))
	atexit(SqueakTerminate);
#endif

#if I_AM_CARBON_EVENT && defined ( __APPLE__ ) && defined ( __MACH__ )
    {
    pthread_t thread;
    
    gThreadManager = false;
    pthread_mutex_init(&gEventQueueLock, NULL);
    pthread_mutex_init(&gEventUILock, NULL);
    pthread_cond_init(&gEventUILockCondition,NULL);
    err = pthread_create(&thread,null,interpret, null);
    if (err == 0) {
        SetUpCarbonEvent();
        RunApplicationEventLoop(); //Note the application under carbon event mgr starts running here
        }
    }
    return; //Note the return, need to refactor this ugly code
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
            return;
        }
    }
#endif
    gThreadManager = false;
    /* run Squeak */
    squeakThread(0);
}
#endif


OSErr createNewThread() {
    gSqueakThreadUPP = NewThreadEntryUPP(squeakThread); //We should dispose of someday
 
#ifndef PLUGIN
	return NewThread( kCooperativeThread, gSqueakThreadUPP, nil, 80*1024, kCreateIfNeeded, 0L, &gSqueakThread);
#else
	return NewThread( kCooperativeThread, gSqueakThreadUPP, nil, 80*1024, kCreateIfNeeded+kNewSuspend, 0L, &gSqueakThread);
#endif
}

static pascal void* squeakThread(void *threadParm) {
	/* run Squeak */
#	ifdef JITTER
	j_interpret();
#	else
	interpret();
#	endif
}

pascal short SqueakYieldToAnyThread(void) {
#ifndef I_AM_CARBON_EVENT
    YieldToAnyThread();
#endif
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
}

Boolean RunningOnCarbonX(void)
{
    UInt32 response;
    
    return (Gestalt(gestaltSystemVersion, 
                    (SInt32 *) &response) == noErr)
                && (response >= 0x01000);
}

/*** I/O Primitives ***/

int ioBeep(void) {
	SysBeep(1000);
}

#ifndef PLUGIN
int ioExit(void) {
    UnloadScrap();
    ioShutdownAllModules();
    MenuBarRestore();
	sqMacMemoryFree();
    ExitToShell();
}
#endif

void SqueakTerminate() {
#ifdef PLUGIN
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
	if (id == 0) return vmPath;
	/* Note: 1.3x images will try to read the image as a document because they
	   expect attribute #1 to be the document name. A 1.3x image can be patched
	   using a VM of 2.6 or earlier. */
	if (id == 1) return imageName;
	if (id == 2) return documentName;

#ifdef PLUGIN
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
		else
			return "PowerPC";
	}
	if (id == 1004) return (char *) interpreterVersion;
#if TARGET_API_MAC_CARBON
	if (id == 1201) return (isVmPathVolumeHFSPlus() ? "255" : "31");  //name size on hfs plus volumes
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

#ifdef PLUGIN

/*** Plugin Support ***/

int plugInInit(char *fullImagePath) {

	fullImagePath;
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

	/* clear all path and file names */
	imageName[0] = shortImageName[0] = documentName[0] = vmPath[0] = 0;

        SetUpTimers();
	PowerMgrCheck();
	SetUpClipboard();
	SetUpPixmap();
}

int plugInShutdown(void) {
	ioShutdownAllModules();
	FreeClipboard();
	FreePixmap();
	if (memory != nil) {
        if (gThreadManager)
	        DisposeThread(gSqueakThread,null,true);
	    sqMacMemoryFree();
	}
}

#endif

/*** Profiling Stubs ***/

int clearProfile(void){}														
int dumpProfile(void){}														
int startProfiling(void){}													
int stopProfiling(void)	{}													
