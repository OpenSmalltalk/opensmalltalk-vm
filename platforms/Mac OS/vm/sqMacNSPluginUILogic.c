/*
 *  sqMacNSPluginUILogic.c
 *  SqueakVMUNIXPATHS
 *
 *  Created by John M McIntosh on 27/02/06.
 *  Copyright 2006 Corporate Smalltalk Consulting Ltd, licensed under the Squeak-L license
 
 *   AUTHOR:  John Maloney, John McIntosh, and others.

	Feb 27th, 2006 
 *
 */
 
 #define STARTINGsqueakHeapMBytes 20*1024*1024
 #define KEYBUF_SIZE 64


#include <pthread.h>
#include <Movies.h>

#include "sq.h"
#include "sqMacUIEvents.h"
#include "sqMacUnixFileInterface.h"
#include "FilePlugin.h"
#include "sqMacTime.h"
#include "npapi.h"
#include "sqMacUIConstants.h"
#include "sqMacImageIO.h"
#include "sqMacEncoding.h"
#include "sqMacMemory.h"
#include "sqMacWindow.h"
#include "sqMacHostWindow.h"
#include "sqMacUIClipBoard.h"

#define EnableMenuItemCarbon(m1,v1)  EnableMenuItem(m1,v1);
#define DisableMenuItemCarbon(m1,v1)  DisableMenuItem(m1,v1);
	
	//#define PLUGIN_TRACE 1

#if PLUGIN_TRACE
//int printOnOSXPascal(unsigned char *msg);
//#define PLUGINDEBUGSTR(msg) printOnOSXPascal(msg);
#define PLUGINDEBUGSTR(msg)		DebugStr(msg)
#else
#define PLUGINDEBUGSTR
#endif

extern int gButtonIsDown;
extern int getFullScreenFlag();
extern int setInterruptKeycode(int value);
extern int setFullScreenFlag(int value);
extern int setInterruptPending(int value);
extern int getInterruptKeycode();
extern sqInputEvent *nextEventPut(void);

extern TMTask	gTMTask;
extern pthread_mutex_t gEventQueueLock;
extern char	squeakPluginImageName[];
extern struct VirtualMachine* interpreterProxy;
extern int	exitRequested;
extern NPP	thisInstance;
extern unsigned char *memory;
extern char		failureURL[];
extern char		rememberMemoryString[];
extern int		pluginArgCount;
extern char		pluginArgName[];
extern char		pluginArgValue[];
extern int windowActive;
extern int buttonState;
extern char modifierMap[];
extern int cachedButtonState;
extern int keyBuf[];	/* circular buffer */
extern int keyBufGet;			/* index of next item of keyBuf to read */
extern int keyBufPut;			/* index of next item of keyBuf to write */
extern int keyBufOverflows;	/* number of characters dropped */

WindowPtr	gAFullscreenWindow = nil;
Boolean     ignoreFirstEvent=false,gIWasRunning=false,gPendingFullScreen=false;
pthread_mutex_t gEventNSAccept;
int			needsUpdate		= false;
int			squeakHeapMBytes;
NPWindow* 	netscapeWindow	= nil;


/*** From VM ***/
extern int inputSemaphoreIndex;
extern eventMessageHook messageHook ;
extern eventMessageHook postMessageHook;
extern void aioInit(void);
int checkImageVersionFromstartingAt(sqImageFile f, squeakFileOffsetType imageOffset);
int getLongFromFileswap(sqImageFile f, int swapFlag);
int recordMouseEvent(EventRecord *theEvent, int theButtonState);
int MouseModifierState(EventRecord *theEvent);
int recordKeyboardEvent(EventRecord *theEvent, int keyType);
int plugInInit(char *fullImagePath);
int plugInShutdown(void);
void fetchPreferences();

/*** Functions Imported from sqMacWindow ***/

extern PixMapHandle	stPixMap;

static int MacRomanToUnicode[256] = 
{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
 25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,
 47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,
 69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
 91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,
 110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,
 127,196,197,199,201,209,214,220,225,224,226,228,227,229,231,233,232,
 234,235,237,236,238,239,241,243,242,244,246,245,250,249,251,252,8224,
 176,162,163,167,8226,182,223,174,169,8482,180,168,8800,198,216,8734,177,
 8804,8805,165,181,8706,8721,8719,960,8747,170,186,937,230,248,191,161,172,
 8730,402,8776,8710,171,187,8230,160,192,195,213,338,339,8211,8212,8220,8221,
 8216,8217,247,9674,255,376,8260,8364,8249,8250,64257,64258,8225,183,8218,8222,
 8240,194,202,193,203,200,205,206,207,204,211,212,63743,210,218,219,217,305,710,
 732,175,728,729,730,184,733,731,711};

int ioSetFullScreenRestore();
OSErr   createNewThread();
int checkForModifierKeys();

/*** Local Functions ***/
void EndDraw(void);
void waitAFewMilliseconds(void);
void ExitCleanup(void);
int parseMemorySize(int baseSize, char *src);
int plugInNotifyUser(char *msg);
int CaseInsensitiveMatch(char *s1, char *s2);
int  InitFilePaths(void);
void StartDraw(void);
NP_Port	  *getNP_Port(void);

NP_Port * getNP_Port(void) {
    return (NP_Port *) netscapeWindow->window;
}


NPError Mac_NPP_SetWindow(NPP instance, NPWindow* window) {
	NP_Port* port;
	OSErr   err;
	WindowPtr realWindow;
	windowDescriptorBlock *windowBlock;
	
	if (window == NULL || window->window == NULL)
		return NPERR_NO_ERROR;
                
	if (window->width == 0 && window->height == 0) {
		if (gIWasRunning) {
			gIWasRunning = false;
			NPP_Destroy(instance, null);
		}
		return NPERR_NO_ERROR;
	}

            
	netscapeWindow = window;
	port = (NP_Port *) netscapeWindow->window;
	realWindow = GetWindowFromPort(port->port);
	windowBlock = windowBlockFromHandle(windowHandleFromIndex(1));
	if (windowBlock == NULL) {
		windowBlock = AddWindowBlock();
	}
	windowBlock->handle = (wHandleType) realWindow;
	
	needsUpdate	= true;

	fprintf(stderr,"\n realWindowGrafPtr %i port %i x %i y %i windowX %i windowY %i windowW %i windowH %i clipT %i clipL %i clipB %i clipR %i",
		realWindow,
		port,
		port->portx, port->porty,
		netscapeWindow->x, netscapeWindow->y,
		netscapeWindow->width,netscapeWindow->height,
		netscapeWindow->clipRect.top,
		netscapeWindow->clipRect.left,
		netscapeWindow->clipRect.bottom,
		netscapeWindow->clipRect.right
		);
		
	if (gIWasRunning)
            return NPERR_NO_ERROR;
	
	//Start the VM running
	
	gIWasRunning = true;
	ioLoadFunctionFrom(NULL, "DropPlugin");

	err = createNewThread();
	if (err != noErr)
            return err;
	return NPERR_NO_ERROR;
}

// -----------------------

int16 Mac_NPP_HandleEvent(NPP instance, void *rawEvent) {
	EventRecord *eventPtr = (EventRecord*) rawEvent;
	EventRecord	theEvent;
	int				ok;

	pthread_mutex_lock(&gEventNSAccept);
			 
	do {
	
    	if (exitRequested) {
    		exitRequested = false;
    		ExitCleanup();
			pthread_mutex_unlock(&gEventNSAccept);
			return false;
    	}

    	if ((thisInstance == nil) || (eventPtr == NULL)) {
    		/* no instance or no event; do nothing */
			pthread_mutex_unlock(&gEventNSAccept);
    		return false;
    	}

		if (!(eventPtr->what == 0))
			fprintf(stderr,"\n Mac_NPP_HandleEvent %i ",eventPtr->what);
		
		if(!((messageHook) && (messageHook(eventPtr)))) {
	    	switch (eventPtr->what) {
	    		case mouseDown:
	                gButtonIsDown = true;				    
					if(inputSemaphoreIndex) {
			    		StartDraw();
						pthread_mutex_lock(&gEventQueueLock);
						recordMouseEvent(eventPtr,MouseModifierState(eventPtr));
						pthread_mutex_unlock(&gEventQueueLock);
						EndDraw();
						break;
					}
					recordMouseDown(eventPtr);
	    		break;

				case mouseUp:
					gButtonIsDown = false;
					if(inputSemaphoreIndex) {
			    		StartDraw();
						pthread_mutex_lock(&gEventQueueLock);
						recordMouseEvent(eventPtr,MouseModifierState(eventPtr));
						pthread_mutex_unlock(&gEventQueueLock);
			    		EndDraw();
						break;
					}
					recordModifierButtons(eventPtr);
				break;

	    		case keyDown:
	    		case autoKey:
	  				if(inputSemaphoreIndex) {
						pthread_mutex_lock(&gEventQueueLock);
						recordKeyboardEvent(eventPtr,EventKeyDown);
						pthread_mutex_unlock(&gEventQueueLock);
						break;
					}
					recordModifierButtons(eventPtr);
	  			    recordKeystroke(eventPtr);
	    		break;

				case keyUp:
					if(inputSemaphoreIndex) {
						pthread_mutex_lock(&gEventQueueLock);
						recordKeyboardEvent(eventPtr,EventKeyUp);
						pthread_mutex_unlock(&gEventQueueLock);
					}
				break;

	    		case updateEvt:
					fullDisplayUpdate();  /* ask VM to call ioShowDisplay */
	    		break;
	    		case getFocusEvent:
	    		break;
	    		case loseFocusEvent:
	    		break;
	    		case adjustCursorEvent:
	    		break;
	    		
	    	
				case nullEvent :
					{
	    				if(inputSemaphoreIndex) {
	    					eventPtr->modifiers = checkForModifierKeys();
	    		    		StartDraw();
							pthread_mutex_lock(&gEventQueueLock);
	     					recordMouseEvent(eventPtr,MouseModifierState(eventPtr));     
							pthread_mutex_unlock(&gEventQueueLock);
	     					EndDraw();
	    		 		}
					}
	    		break;    		
				case activateEvt:
				{
					/* serious hack to show safari after hiding, 
					issue with safari 1.1.1 not seeing activate when full screen terminates */
			/*		
					ProcessSerialNumber psn = { 0, kCurrentProcess }; 
					OSStatus err;
					if (!IsProcessVisible(&psn)) {
						err = ShowHideProcess (&psn,true);
						SetFrontProcess(&psn);
						} */
				}

					pthread_mutex_unlock(&gEventNSAccept);
					return false;
					break;
			}
		}
    	if (needsUpdate && (netscapeWindow != nil) && (memory)) {
     		needsUpdate = false;
			
    		if (getFullScreenFlag()) {
				fullDisplayUpdate();  /* ask VM to call ioShowDisplay */
				pthread_mutex_unlock(&gEventNSAccept);
				return true;
				}
			else {
 			}
			
	/*		if (!getFullScreenFlag()) {
				ProcessSerialNumber psn = { 0, kCurrentProcess }; 
				OSStatus err;
				err = ShowHideProcess (&psn,true);
				waitAFewMilliseconds();
				pthread_mutex_unlock(&gEventNSAccept);
				return false;
			} */
    	}
		
	if(postMessageHook) postMessageHook(eventPtr);

	if (getFullScreenFlag() ) {
			pthread_mutex_unlock(&gEventNSAccept);
     	    ok = WaitNextEvent(everyEvent, &theEvent,1,null);
			pthread_mutex_lock(&gEventNSAccept);
            eventPtr = &theEvent;
    	}
	} while (getFullScreenFlag());
                    
        
	// waitAFewMilliseconds();
	pthread_mutex_unlock(&gEventNSAccept);
	return true;
}
void EndDraw() {}
void StartDraw(void) {}
void makeMainWindow() {}
void sqShowWindow(int windowIndex){}

/*** Image File Reading ***/

void ReadSqueakImage(void) {
	sqImageFile f;
	char msg[500];
    int swapBytes;
    int dataSize;
    int headerStart;
    int headerSize;
    
	fetchPreferences();
	plugInInit(squeakPluginImageName);
	InitFilePaths();

	/* read the image file and allocate memory for Squeak heap */
	if (CaseInsensitiveMatch(imageName,
		"Problems finding the Internet folder in the Squeak Preference folder or finding the SqueakPlugin.image"))
		f = NULL;
	else
		f = sqImageFileOpen(imageName, "rb");
		
	if (f == NULL) {
		if (failureURL[0] != 0x00) {
			// July 31/2004 added per Michaels request for squeakland camp in chicago
			NPN_GetURL(thisInstance, failureURL, "_self");
		} else {
		strcpy(msg, "Could not open Squeak image file \"");
		strcat(msg, imageName);
		strcat(msg, "\"");
		plugInNotifyUser(msg);
		}
		return;
	}
	
	//Cheat and peek ahead to get the image size so we can calculate the memory required 
	
	swapBytes = checkImageVersionFromstartingAt(f, 0);
	headerStart = (sqImageFilePosition(f)) - 4;
	headerSize = getLongFromFileswap(f, swapBytes);
	dataSize = getLongFromFileswap(f, swapBytes);
	
	//Close then reopen to reset file position
	
	sqImageFileClose(f);  
	f = sqImageFileOpen(imageName, "rb");

	squeakHeapMBytes = parseMemorySize(dataSize, rememberMemoryString);
	if (squeakHeapMBytes == 0) 
	    squeakHeapMBytes = STARTINGsqueakHeapMBytes;
	if (squeakHeapMBytes < sqGetAvailableMemory())
		squeakHeapMBytes = sqGetAvailableMemory();
	    
	readImageFromFileHeapSizeStartingAt(f, squeakHeapMBytes, 0);
	sqImageFileClose(f);
	setInterruptKeycode(515);  /* ctrl-C, since Netscape blocks cmd-. */
	setFullScreenFlag(false); //Note image can be saved with true
	SetUpTimers();
}

/*** Squeak I/O Support and Memory Allocation ***/

int ioExit(void) {
  /* Request that we stop running plugin. */

	ioSetFullScreenRestore();
	exitRequested = true;
	return 0;
}

int ioScreenSize(void) {
	int w = 0, h = 0;
	Rect bounds;
	
	if (netscapeWindow != nil) {
		w = netscapeWindow->width;
		h = netscapeWindow->height;
	}
	    

	if (w == 0 && h == 0) { 
	    GetPortBounds(GetWindowPort(getSTWindow()),&bounds);
		w = bounds.right - bounds.left;
		h = bounds.bottom - bounds.top;
	}
	
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

int ioProcessEvents(void) {
	return doPendingFlush();
}


/* Full Screen logic */

Ptr gRestorableStateForScreen = nil;
NP_Port	  gFullScreenNPPort;
NPWindow  *oldNetscapeWindow,gFullScreenNPWindow;
WindowPtr oldStWindow;


int ioSetFullScreen(int fullScreen) {
	short desiredWidth,desiredHeight;
    GDHandle   dominantGDevice;
	windowDescriptorBlock *	mangleWindowInfo;
	
	if (fullScreen) {
	    if (getFullScreenFlag()) return 0;
	    
		desiredWidth = 0;
		desiredHeight = 0;
		oldNetscapeWindow = netscapeWindow;
		oldStWindow = getSTWindow();
		dominantGDevice = getThatDominateGDevice(oldStWindow);
	
    	ignoreFirstEvent = true;
		setFullScreenFlag(true);  //JMM Moved before to test
		waitAFewMilliseconds();
		waitAFewMilliseconds();
		waitAFewMilliseconds();
		waitAFewMilliseconds();
		waitAFewMilliseconds();
		BeginFullScreen	(&gRestorableStateForScreen,
								dominantGDevice,
								 &desiredWidth,
								 &desiredHeight,
								 &gAFullscreenWindow,
								 nil,
								 fullScreenAllowEvents);
		mangleWindowInfo = windowBlockFromIndex(1);
		mangleWindowInfo->handle = gAFullscreenWindow;

		gFullScreenNPPort.port = GetWindowPort(gAFullscreenWindow);
		gFullScreenNPPort.portx = 0;
		gFullScreenNPPort.porty = 0;
		gFullScreenNPWindow.window =  &gFullScreenNPPort;
		gFullScreenNPWindow.x = 0;
		gFullScreenNPWindow.y = 0;
		gFullScreenNPWindow.width = desiredWidth;
		gFullScreenNPWindow.height = desiredHeight;
		gFullScreenNPWindow.clipRect.top = 0;
		gFullScreenNPWindow.clipRect.left = 0;
		gFullScreenNPWindow.clipRect.bottom = desiredHeight;
		gFullScreenNPWindow.clipRect.right = desiredWidth;
    	
    	netscapeWindow = &gFullScreenNPWindow;

 	} else {
	    if (!getFullScreenFlag()) return 0;
		setFullScreenFlag(false);
        ioSetFullScreenRestore();
	}
	return 0;
}

int  ioSetFullScreenRestore()
{
	ProcessSerialNumber psn = { 0, kCurrentProcess }; 
	OSErr   err;
	windowDescriptorBlock *	mangleWindowInfo;
	
	if (gRestorableStateForScreen != nil) {
		EndFullScreen(gRestorableStateForScreen,nil);
	    if (gAFullscreenWindow == nil) 
		    return 0;
	    gRestorableStateForScreen = nil;
	    netscapeWindow = oldNetscapeWindow;
		mangleWindowInfo = windowBlockFromIndex(1);
		mangleWindowInfo->handle = oldStWindow;
		err = ShowHideProcess (&psn,false);
		waitAFewMilliseconds();
	}
	return 0;
}

/*** File and Access Paths ***/

int InitFilePathsViaDomain(SInt16 domain) {
	char imageInPreferenceFolder[IMAGE_NAME_SIZE+1];
	OSErr err;
	FSRef	theFSRef;
	char path[VMPATH_SIZE+1];

	
	/* clear all path and file names */
	SetShortImageNameViaString(squeakPluginImageName,gCurrentVMEncoding);

#ifdef SOPHIEVM
	/* get the path to the sytem folder preference area*/
	err = FSFindFolder(domain, kApplicationsFolderType, kDontCreateFolder, &theFSRef);
	if (err != noErr) {
		return err;
	}
	
	// Look for folder, if not found abort */
	PathToFileViaFSRef(imageInPreferenceFolder,IMAGE_NAME_SIZE, &theFSRef,kCFStringEncodingUTF8);

	strcat(imageInPreferenceFolder,"Sophie.app/Contents/Resources/");
	strcpy(path,imageInPreferenceFolder);
	strcat(imageInPreferenceFolder,squeakPluginImageName);
	err = getFSRef(imageInPreferenceFolder,&theFSRef,kCFStringEncodingUTF8);	
	if (err != noErr) {
		return err;
	}

#else
	/* get the path to the sytem folder preference area*/
	err = FSFindFolder(domain, kPreferencesFolderType, kDontCreateFolder, &theFSRef);
	if (err != noErr) {
		return err;
	}
	
	// Look for folder, if not found abort */
	PathToFileViaFSRef(imageInPreferenceFolder,IMAGE_NAME_SIZE, &theFSRef,kCFStringEncodingUTF8);

	strcat(imageInPreferenceFolder,"Squeak/Internet/");
	strcpy(path,imageInPreferenceFolder);
	strcat(imageInPreferenceFolder,squeakPluginImageName);
	err = getFSRef(imageInPreferenceFolder,&theFSRef,kCFStringEncodingUTF8);	
	if (err != noErr) {
		/* New Behavior try to find the SqueakLand Folder in the Application's Folder */
		err = FSFindFolder(domain, kApplicationsFolderType, kDontCreateFolder, &theFSRef);
		if (err != noErr) 
			goto error;
		PathToFileViaFSRef(imageInPreferenceFolder,IMAGE_NAME_SIZE, &theFSRef,kCFStringEncodingUTF8);
		strcat(imageInPreferenceFolder,"SqueakLand/Squeak/Internet/");
		strcpy(path,imageInPreferenceFolder);
		strcat(imageInPreferenceFolder,squeakPluginImageName);
		err = getFSRef(imageInPreferenceFolder,&theFSRef,kCFStringEncodingUTF8);	
		if (err != noErr)		
			goto error;
	}	
#endif
	/* set the vmPath */
	CFStringRef strRef = CFStringCreateWithCString(kCFAllocatorDefault, path, kCFStringEncodingUTF8);
	CFMutableStringRef strRefM = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, strRef);
	SetVMPathFromCFString(strRefM);
	CFRelease(strRef);
	CFRelease(strRefM);
	
	getVMPathWithEncoding(path,gCurrentVMEncoding);
	strcat(path, squeakPluginImageName);
	SetImageNameViaString(path,gCurrentVMEncoding);
	return noErr;
	
	error: 
	SetImageNameViaString("Problems finding the Internet folder in the Squeak Preference folder or finding the SqueakPlugin.image",gCurrentVMEncoding);
	return err;
	
}

int InitFilePaths() {
	static const SInt16 domain[] = {kOnSystemDisk,kUserDomain, kLocalDomain, kNetworkDomain, kSystemDomain, 0}; 
	int error;
	SInt32 domainIndex=0;
	
	do {
		error = InitFilePathsViaDomain(domain[domainIndex]);
		if (error == noErr) 
			return noErr;
		domainIndex++;
	} while (domain[domainIndex] != 0); 
        return error;
}

int IsPrefixedBy(char *s, char *prefix) {
  /* Return true if the given string begins with or equals the given prefix. */
	int i;

	for (i = 0; prefix[i] != 0; i++) {
		if (s[i] != prefix[i]) 
			return false;
	}
	return true;
}

sqInt
primitivePluginBrowserReady(void) {
	/* Args: none.
	   Always return true on Macintosh. */
	PLUGINDEBUGSTR("\pPrimitiveCallBrowserReady;g;");
	interpreterProxy->pop(1);
	interpreterProxy->pushBool(1);
	return 0;
}


void ExitCleanup(void) {
  /* Clean up and stop running plugin. */
	int i;

	if (thisInstance == nil) return;
	thisInstance = nil;
	exitRequested = true;

	/* do { This hangs things, not sure what to do about outstanding URL requests...
		Boolean URLFetchInProgress;
		URLFetchInProgress = false;
		for (i = 0; i < URL_REQUEST_COUNT; i++) {
			if (urlRequests[i].status == STATUS_IN_PROGRESS) {
				URLFetchInProgress = true;
				break;
			}
		}
		if (URLFetchInProgress) {
			SystemTask();
			YieldToThread(gSqueakThread);
		}
	} while (URLFetchInProgress); */
	
        if (gTMTask.tmAddr) {
        
            RemoveTimeTask((QElemPtr)gTMTask.qLink);
            DisposeTimerUPP(gTMTask.tmAddr);
            gTMTask.tmAddr = NULL;
        }
        
	plugInShutdown();
	ioSetFullScreenRestore();
	if (pluginArgCount != 0) {
		for(i=0;i<pluginArgCount;i++) {
			NPN_MemFree((void*)&pluginArgName[i]);
			NPN_MemFree((void*)&pluginArgValue[i]);
		}
		pluginArgCount = 0;
	}
	NPP_Initialize();  /* reset local variables */
        ignoreFirstEvent=false;
        gIWasRunning=false;
}

/*** Interpreter Hooks ***/

int plugInNotifyUser(char *msg) {
  /* Notify the user that there was a problem starting Squeak. */
	unsigned char *		notificationMsg = malloc(256);
	NMRec		*notifyRec = malloc(sizeof(NMRec));

	CopyCStringToPascal(msg,notificationMsg); /* copy message, since notification is asynchronous */

	notifyRec->qType = nmType;
	notifyRec->nmMark = false;			/* no mark in applications menu */
	notifyRec->nmIcon = nil;				/* no menu bar icon */
	notifyRec->nmSound = (Handle) -1;	/* -1 means system beep */
	notifyRec->nmStr = notificationMsg;
	notifyRec->nmResp = (NMUPP) -1;		/* -1 means remove notification when user confirms */

	/* add to notification queue */
	NMInstall(notifyRec);
	return 0;
}

void plugInSetStartTime(void) {
}

int plugInTimeToReturn(void) {
    if (exitRequested)
        return true;
    return false;
}

int parseMemorySize(int baseSize, char *src)
{
	char buf[50], *tmp;
	int imageSize = 0, requestedSize;

	while(*src) {
		switch(*src) {
			case ' ': /* white spaces; ignore */
			case '"':
				src++; break;
			case '*': /* multiple of image size */
				tmp = buf; src++;
				while(*src && isdigit(*src)) *(tmp++) = *(src++); /* integer part */
				if(*src == '.') { /* fraction part */
					*(tmp++) = *(src++);
					while(*src && isdigit(*src)) *(tmp++) = *(src++);
				}
				*(tmp++) = 0;
				imageSize += (int) (baseSize * atof(buf));
				break;
			case '+': /* additional space in bytes */
				tmp = buf; src++;
				while(*src && isdigit(*src)) *(tmp++) = *(src++);
				*(tmp++) = 0;
				if (imageSize == 0) 
					imageSize = baseSize;
				requestedSize = atoi(buf);
				imageSize += (requestedSize <= 1000) ? requestedSize*1024*1024 : requestedSize;
				break;
			default: /* absolute size */
				tmp = buf;
				*(tmp++) = *(src++);
				while(*src && isdigit(*src)) *(tmp++) = *(src++);
				*(tmp++) = 0;
				requestedSize = atoi(buf);
				imageSize = (requestedSize <= 1000) ? requestedSize*1024*1024 : requestedSize;
		}
	}
	return imageSize;
}

int AbortIfFileURL(char *url)
{   char lookFor[6];
	int placement=0;
	
	lookFor[5] = 0x00;
	while (true) {
		if (*url == 0x00) break;
		if (*url == ' ') {
			url++;
		} else {
		  lookFor[placement++] = *url++;
		  if (placement == 5) break;
		}
	}
	return !CaseInsensitiveMatch(lookFor,"file:");
}

pthread_mutex_t sleepLock;
pthread_cond_t  sleepLockCondition;
void waitAFewMilliseconds()
{
    static Boolean doInitialization=true;
    const int	   realTimeToWait = 100;
    struct timespec tspec;
    int err;
    
    if (doInitialization) {
        doInitialization = false;
        pthread_mutex_init(&sleepLock, NULL);
        pthread_cond_init(&sleepLockCondition,NULL);
    }

    tspec.tv_sec=  realTimeToWait / 1000;
    tspec.tv_nsec= (realTimeToWait % 1000)*1000000;
    
    err = pthread_mutex_lock(&sleepLock);
    err = pthread_cond_timedwait_relative_np(&sleepLockCondition,&sleepLock,&tspec);	
    err = pthread_mutex_unlock(&sleepLock); 
}


int recordMouseEvent(EventRecord *theEvent, int theButtonState) {
	sqMouseEvent *evt;
	static sqMouseEvent oldEvent;
	
	evt = (sqMouseEvent*) nextEventPut();

	/* first the basics */
	evt->type = EventTypeMouse;
	evt->timeStamp = ioMSecs() & MillisecondClockMask; 
//JMM? 	QD GlobalToLocal Point(getNP_Port()->port,(Point *) &theEvent->where);
	GlobalToLocal( &theEvent->where);
	evt->x = theEvent->where.h;
	evt->y = theEvent->where.v;
	fprintf(stderr,"\n Mouse at x %i y %i ",evt->x,evt->y);

	/* then the buttons */
	evt->buttons = theButtonState & 0x07;
	/* then the modifiers */
	evt->modifiers = theButtonState >> 3;
	evt->windowIndex = windowActive;
	
	if (oldEvent.buttons == evt->buttons && 
	    oldEvent.x == evt->x &&
	    oldEvent.y == evt->y &&
	    oldEvent.modifiers == evt->modifiers) 
	    ignoreLastEvent();
	    
    oldEvent = *evt;

	
//	signalSemaphoreWithIndex(inputSemaphoreIndex);
	return 1;
}

void recordModifierButtons(EventRecord *theEvent) {
	int stButtons = 0;

	if ((theEvent->modifiers & btnState) == false) {
		stButtons = buttonState & 0x7;
	} else {
		stButtons = 0;
	}
	/* button state: low three bits are mouse buttons; next 8 bits are modifier bits */
	buttonState =
		(modifierMap[(theEvent->modifiers >> 8)] << 3) |
		(stButtons & 0x7);
}

void recordMouseDown(EventRecord *theEvent) {

	/* button state: low three bits are mouse buttons; next 4 bits are modifier bits */
	buttonState = MouseModifierState(theEvent);
	cachedButtonState = cachedButtonState | buttonState;
}

int recordKeyboardEvent(EventRecord *theEvent, int keyType) {
	int asciiChar, modifierBits;
	sqKeyboardEvent *evt, *extra;

	evt = (sqKeyboardEvent*) nextEventPut();

	/* keystate: low byte is the ascii character; next 4 bits are modifier bits */
	asciiChar = theEvent->message & charCodeMask;
	modifierBits = MouseModifierState(theEvent); //Capture mouse/option states
	if (((modifierBits >> 3) & 0x9) == 0x9) {  /* command and shift */
		if ((asciiChar >= 97) && (asciiChar <= 122)) {
			/* convert ascii code of command-shift-letter to upper case */
			asciiChar = asciiChar - 32;
		}
	}

	/* first the basics */
	evt->type = EventTypeKeyboard;
	evt->timeStamp = ioMSecs() & MillisecondClockMask;
	/* now the key code */
	/* press code must differentiate */
	// Jan 2004, changed for TWEAK instead of doing virtual keycode return  unicode
	// Unicode generated from CFSTring
	// March 19th 2005, again alter we pass keyCode on keydown/keyup but pass unicode in keychar as extra field
	evt->charCode = (theEvent->message & keyCodeMask) >> 8;
	evt->pressCode = keyType;
	evt->modifiers = modifierBits >> 3;
	evt->windowIndex = windowActive;
	/* clean up reserved */
	evt->reserved1 = 0;
	/* generate extra character event */
	if (keyType == EventKeyDown) {
		extra = (sqKeyboardEvent*)nextEventPut();
		*extra = *evt;
		extra->charCode = asciiChar;
		extra->pressCode = EventKeyChar;
		extra->utf32Code = MacRomanToUnicode[asciiChar];
	}
//	signalSemaphoreWithIndex(inputSemaphoreIndex);
	return 1;
}

void recordKeystroke(EventRecord *theEvent) {
	int asciiChar, modifierBits, keystate;

	/* keystate: low byte is the ascii character; next 8 bits are modifier bits */
	asciiChar = theEvent->message & charCodeMask;
	modifierBits = modifierMap[(theEvent->modifiers >> 8)];
	if ((modifierBits & 0x9) == 0x9) {  /* command and shift */
		if ((asciiChar >= 97) && (asciiChar <= 122)) {
			/* convert ascii code of command-shift-letter to upper case */
			asciiChar = asciiChar - 32;
		}
	}

	keystate = (modifierBits << 8) | asciiChar;
	if (keystate == getInterruptKeycode()) {
		/* Note: interrupt key is "meta"; it not reported as a keystroke */
		setInterruptPending(true);
	} else {
		keyBuf[keyBufPut] = keystate;
		keyBufPut = (keyBufPut + 1) % KEYBUF_SIZE;
		if (keyBufGet == keyBufPut) {
			/* buffer overflow; drop the last character */
			keyBufGet = (keyBufGet + 1) % KEYBUF_SIZE;
			keyBufOverflows++;
		}
	}
}

int checkForModifierKeys() {
	enum {
			/* modifier keys */
		kVirtualCapsLockKey = 0x039,
		kVirtualShiftKey = 0x038,
		kVirtualControlKey = 0x03B,
		kVirtualOptionKey = 0x03A,
		kVirtualRShiftKey = 0x03C,
		kVirtualRControlKey = 0x03E,
		kVirtualROptionKey = 0x03D,
		kVirtualCommandKey = 0x037
	};
	KeyMap theKeys;
	unsigned char *keybytes;
	int result;
	
	GetKeys(theKeys);
	keybytes = (unsigned char *) theKeys;
	result  = gButtonIsDown ?  0 : btnState ;
	result += ((keybytes[kVirtualCapsLockKey>>3] & (1 << (kVirtualCapsLockKey&7))) != 0) ? alphaLock : 0;
	result += ((keybytes[kVirtualShiftKey>>3] & (1 << (kVirtualShiftKey&7))) != 0)       ? shiftKey : 0;
	result += ((keybytes[kVirtualControlKey>>3] & (1 << (kVirtualControlKey&7))) != 0)   ? controlKey : 0;
	result += ((keybytes[kVirtualOptionKey>>3] & (1 << (kVirtualOptionKey&7))) != 0)     ? optionKey : 0;
	result += ((keybytes[kVirtualRShiftKey>>3] & (1 << (kVirtualRShiftKey&7))) != 0)       ? shiftKey : 0;
	result += ((keybytes[kVirtualRControlKey>>3] & (1 << (kVirtualRControlKey&7))) != 0)   ? controlKey : 0;
	result += ((keybytes[kVirtualROptionKey>>3] & (1 << (kVirtualROptionKey&7))) != 0)     ? optionKey : 0;
	result += ((keybytes[kVirtualCommandKey>>3] & (1 << (kVirtualCommandKey&7))) != 0)   ? cmdKey : 0;
	
	return result;
}



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

	SetUpClipboard();
	SetUpPixmap();
	return 0;
}

extern pthread_mutex_t gSleepLock;
extern pthread_cond_t  gSleepLockCondition;

int plugInShutdown(void) {
        int err;
        
	ioShutdownAllModules();
	FreeClipboard();
	FreePixmap();
	if (memory != nil) {
		err = pthread_cancel(gSqueakPThread);
          if (err == 0 )
              pthread_join(gSqueakPThread,NULL);
        pthread_mutex_destroy(&gEventQueueLock);
        pthread_mutex_destroy(&gEventUILock);
		pthread_mutex_destroy(&gEventNSAccept);
        pthread_mutex_destroy(&gSleepLock);
        pthread_cond_destroy(&gEventUILockCondition);
        pthread_cond_destroy(&gSleepLockCondition);
	    sqMacMemoryFree();
	}
	return 0;
}

OSErr createNewThread() {
        OSErr err;
				      
        aioInit();
        pthread_mutex_init(&gEventQueueLock, NULL);
        pthread_mutex_init(&gEventUILock, NULL);
        pthread_mutex_init(&gEventNSAccept, NULL);
        pthread_cond_init(&gEventUILockCondition,NULL);
        err = pthread_create(&gSqueakPThread,null,(void *) interpret, null);
	return 0;
}



