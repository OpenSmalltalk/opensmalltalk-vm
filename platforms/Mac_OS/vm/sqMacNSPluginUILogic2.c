/*
 *  sqMacNSPluginUILogic2.c
 *  SqueakVMUNIXPATHS
 *
 *  Created by John M McIntosh on 19/10/06.
 *  Copyright 2006 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *  Distributed under the Squeak-L
 *  Feb 4, 2007. JMM Licence changed to MIT
 *
 */

#if TARGET_API_MAC_CARBON
#include <Carbon/Carbon.h>
#else
#include <Debugging.h>
#endif

#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/mman.h>

#include "sq.h"
#include "sqMacNSPluginUILogic2.h"
#include "sqMacHostWindow.h"
#include "sqaio.h"
#include "sqVirtualMachine.h"
#include "sqUnixCharConv.h"
#include "sqMacWindow.h"
#include "sqVirtualMachine.h"

static void browserReceiveData();
static void browserSend(const void *buf, size_t count);
static void browserReceive(void *buf, size_t count);
static void browserReceiveData(void);
static void npHandler(int fd, void *data, int flags);
static void handle_CMD_SHARED_MEMORY(void);
static void handle_CMD_EVENT(void);void browserSendInt(int value);
extern int gSqueakDebug;


# define DPRINTF(ARGS) if (gSqueakDebug) fprintf ARGS


extern int	gSqueakBrowserPipes[];

#define MAX_REQUESTS 128

#define SQUEAK_READ 0
#define SQUEAK_WRITE 1

#define CMD_GET_URL        2
#define CMD_POST_URL       3
#define CMD_RECEIVE_DATA   4
#define CMD_SHARED_MEMORY  5
#define CMD_DRAW_CLIP	   6
#define CMD_EVENT		   7
#define CMD_SET_CURSOR	   8

typedef struct sqStreamRequest {
  char *localName;
  int semaIndex;
  int state;
} sqStreamRequest;

static sqStreamRequest *requests[MAX_REQUESTS];
SqueakSharedMemoryBlock *SharedMemoryBlock = NULL;
static int SharedMemoryfd;
volatile CGContextRef SharedBrowserBitMapContextRef=NULL;
int SharedBrowserBitMapLength = 0;
extern Boolean gSqueakBrowserSubProcess;
static int rowBytes=0, width=0,  height=0;
	

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;


/*** Proxy Functions ***/
#define stackValue(i) (interpreterProxy->stackValue(i))
#define stackIntegerValue(i) (interpreterProxy->stackIntegerValue(i))
#define successFlag (!interpreterProxy->failed())
#define success(bool) (interpreterProxy->success(bool))
#define arrayValueOf(oop) (interpreterProxy->arrayValueOf(oop))
#define checkedIntegerValueOf(oop) (interpreterProxy->checkedIntegerValueOf(oop))
#define fetchArrayofObject(idx,oop) (interpreterProxy->fetchArrayofObject(idx,oop))
#define fetchFloatofObject(idx,oop) (interpreterProxy->fetchFloatofObject(idx,oop))
#define fetchIntegerofObject(idx,oop) (interpreterProxy->fetchIntegerofObject(idx,oop))
#define floatValueOf(oop) (interpreterProxy->floatValueOf(oop))
#define pop(n) (interpreterProxy->pop(n))
#define pushInteger(n) (interpreterProxy->pushInteger(n))
#define sizeOfSTArrayFromCPrimitive(cPtr) (interpreterProxy->sizeOfSTArrayFromCPrimitive(cPtr))
#define storeIntegerofObjectwithValue(idx,oop,value) (interpreterProxy->storeIntegerofObjectwithValue(idx,oop,value))
#define primitiveFail() interpreterProxy->primitiveFail()
#define pushBool(n) (interpreterProxy->pushBool(n))
#define failed() (interpreterProxy->failed())
#define isBytes(n) (interpreterProxy->isBytes(n))
#define byteSizeOf(n) (interpreterProxy->byteSizeOf(n))
#define stackObjectValue(n) (interpreterProxy->stackObjectValue(n))
#define firstIndexableField(n) (interpreterProxy->firstIndexableField(n))
#define push(n) (interpreterProxy->push(n))
#define positive32BitIntegerFor(n) (interpreterProxy->positive32BitIntegerFor(n))
#define methodArgumentCount(n) (interpreterProxy->methodArgumentCount(n))
#define nilObject(n) (interpreterProxy->nilObject(n))


sqInt
primitivePluginBrowserReady(void) {
   if (gSqueakBrowserSubProcess)
     {
      pop(1);
      pushBool(1);
    }
  else
    primitiveFail();
  return 1;
}


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


int plugInTimeToReturn(void) {
	extern Boolean			gSqueakBrowserExitRequested;

    if (gSqueakBrowserSubProcess && gSqueakBrowserExitRequested)
        return true;
    return false;
}

Boolean inline_and_export browserActiveAndDrawingContextOk() {
	return gSqueakBrowserSubProcess && SharedBrowserBitMapContextRef;
}

Boolean inline_and_export browserActiveAndDrawingContextOkAndInFullScreenMode() {
	extern Boolean gSqueakBrowserWasHeadlessButMadeFullScreen;
	extern sqInt getFullScreenFlag(void);
	return browserActiveAndDrawingContextOk() && gSqueakBrowserWasHeadlessButMadeFullScreen && getFullScreenFlag();
}

Boolean inline_and_export browserActiveAndDrawingContextOkAndNOTInFullScreenMode() {
	extern sqInt getFullScreenFlag(void);
	return browserActiveAndDrawingContextOk() && !getFullScreenFlag();
}

void setupPipes() { 
	DPRINTF((stderr,"VM: setupPipes()\n"));
	aioEnable(gSqueakBrowserPipes[SQUEAK_READ], 0, AIO_EXT); 
	aioHandle(gSqueakBrowserPipes[SQUEAK_READ], npHandler, AIO_RX);
}


/*
  browserProcessCommand:
  Handle commands sent by the plugin.
*/
void browserProcessCommand(void)
{
  static Boolean firstTime= true;
  int cmd, n;
  
  if (firstTime)
    {
      firstTime= false;
      /* enable non-blocking reads */
      fcntl(gSqueakBrowserPipes[SQUEAK_READ], F_SETFL, O_NONBLOCK);
    }
 
  n = read(gSqueakBrowserPipes[SQUEAK_READ], &cmd, 4);
  if (0 == n || (-1 == n && EAGAIN == errno))
    return;

 if (n == -1)
	DPRINTF((stderr,"VM: browserProcessCommand() error on read %i\n",errno));

 if (!(cmd == CMD_EVENT))
	DPRINTF((stderr,"VM: browserProcessCommand() %i\n",cmd));

  switch (cmd)
    {
    case CMD_RECEIVE_DATA:
      /* Data is coming in */
      browserReceiveData();
      break;
	case CMD_SHARED_MEMORY:
		handle_CMD_SHARED_MEMORY();		
		break;
	case CMD_EVENT:
		handle_CMD_EVENT();
		break;
    default:
      DPRINTF((stderr, "VM: Unknown command from Plugin: %i\n", cmd));
    }
}

static void handle_CMD_SHARED_MEMORY() {

	int tempRowBytes,tempWidth,tempHeight;
	
	CGColorSpaceRef colorspace;
	CGContextRef TempSharedBrowserBitMapContextRef;
	
	browserReceive(&SharedMemoryfd, 4);
	browserReceive(&tempWidth, 4);
	browserReceive(&tempHeight, 4);
	browserReceive(&tempRowBytes, 4);
	if (rowBytes == tempRowBytes &&
		width == tempWidth &&
		height == tempHeight) 
			return;
			
	rowBytes = tempRowBytes;
	width = tempWidth;
	height = tempHeight;
	
	if (SharedMemoryBlock) {
		DPRINTF((stderr,"VM: munmap %i \n",(int) SharedMemoryBlock));
		munmap(SharedMemoryBlock,SharedBrowserBitMapLength);
	}
			
	SharedBrowserBitMapLength = rowBytes*height+20;
	SharedMemoryBlock= mmap(0, SharedBrowserBitMapLength, PROT_READ | PROT_WRITE, MAP_SHARED, SharedMemoryfd,0);
	if (SharedMemoryBlock == MAP_FAILED)	{ 
		perror("mmap returns error");
		DPRINTF((stderr,"VM: handle_CMD_SHARED_MEMORY failed mmap length was %i fd was %i \n",SharedBrowserBitMapLength,SharedMemoryfd));
		return;
	}
	SharedMemoryBlock->written = 0;
	
	DPRINTF((stderr,"VM: browserProcessCommand(width %i height %i rowbytes %i SharedMemoryBlock %i at %i)\n", width, height, rowBytes,SharedMemoryfd,(int) SharedMemoryBlock));

	if ((TempSharedBrowserBitMapContextRef = SharedBrowserBitMapContextRef)) {
		SharedBrowserBitMapContextRef = NULL;
		DPRINTF((stderr,"VM: free bitmap context %i \n",(int) TempSharedBrowserBitMapContextRef));
		CFRelease(TempSharedBrowserBitMapContextRef);
	}
	
	  {
			// Get the Systems Profile for the main display
		CMProfileRef sysprof = NULL;
		if (CMGetSystemProfile(&sysprof) == noErr) {
			// Create a colorspace with the systems profile
			colorspace = CGColorSpaceCreateWithPlatformColorSpace(sysprof);
			CMCloseProfile(sysprof);
		} else 
			colorspace = CGColorSpaceCreateDeviceRGB();
	  }
	{ 
		extern int makeMainWindow(void);
		if (getSTWindow() == NULL) {
			makeMainWindow();
		}
		  SizeWindow(getSTWindow(), width, height, true);
		DPRINTF((stderr,"VM: Size Window to %i @ %i \n",width,height));
	}
	SharedBrowserBitMapContextRef = CGBitmapContextCreate (SharedMemoryBlock->screenBits,width,height,8,rowBytes,colorspace,kCGImageAlphaNoneSkipFirst);
	CFRelease(colorspace);
	DPRINTF((stderr,"VM: made bitmap context ref %i\n", (int) SharedBrowserBitMapContextRef));
}

static void handle_CMD_EVENT() {
	EventRecord	theEvent;
	EventRecord *eventPtr = &theEvent;
	extern int gButtonIsDown;
	
#define getFocusEvent	    (osEvt + 16)
#define loseFocusEvent	    (osEvt + 17)
#define adjustCursorEvent   (osEvt + 18)

	browserReceive(&theEvent, sizeof(EventRecord));
	if (browserActiveAndDrawingContextOkAndInFullScreenMode())
			return;
			
	switch (eventPtr->what) {
				case mouseUp:
					gButtonIsDown = false;
					recordMouseEvent(eventPtr);
					break;
					
				case mouseDown:
					gButtonIsDown = true;
					recordMouseEvent(eventPtr);
					break;

				case nullEvent :
					eventPtr->what = kEventMouseMoved;
					recordMouseEvent(eventPtr);
					break;    		
					
	    		case keyDown:
	    		case autoKey:
						recordKeyboardEvent(eventPtr,EventKeyDown);
	    		break;

				case keyUp:
						recordKeyboardEvent(eventPtr,EventKeyUp);
				break;

	    		case updateEvt:
					if (browserActiveAndDrawingContextOk())
						fullDisplayUpdate();  /* ask VM to call ioShowDisplay */
	    		break;
	    		case getFocusEvent:
	    		break;
	    		case loseFocusEvent:
	    		break;
	    		case adjustCursorEvent:
	    		break;
	    		
				default:
					break;
			}

}

static void npHandler(int fd, void *data, int flags)
{
#pragma unused(fd,data,flags)
  browserProcessCommand();
  aioHandle(gSqueakBrowserPipes[0], npHandler, AIO_RX);
}
	


/*
  browserReceiveData:
  Called in response to a CMD_RECEIVE_DATA message.
  Retrieves the data file name and signals the semaphore.
*/
static void browserReceiveData(void)
{
  char *localName= NULL;
  int id, ok;
  char  unixName[4096];
  char pathToGiveToSqueak[2048];
  
  browserReceive(&id, 4);
  browserReceive(&ok, 4);

  DPRINTF((stderr,"VM:  receiving data id: %i state %i\n", id, ok));

  if (ok == 1) {
    int length= 0;
    browserReceive(&length, 4);
    if (length) {
      browserReceive(unixName, length);
      unixName[length]= 0;
      DPRINTF((stderr,"VM:   got filename %s\n", unixName));
	  ux2sqPath(unixName,length, pathToGiveToSqueak, 2048,1);	
      localName = malloc(strlen(pathToGiveToSqueak)+1);
	  strcpy(localName,pathToGiveToSqueak);
      DPRINTF((stderr,"VM:   becomes squeak filename for %s\n", localName));
    }
  }
  if (id >= 0 && id < MAX_REQUESTS) {
    sqStreamRequest *req= requests[id];
    if (req) {
      req->localName= localName;
      req->state= ok;
      DPRINTF((stderr,"VM:  signaling semaphore, state=%i\n", ok));
      signalSemaphoreWithIndex(req->semaIndex);
    }
  }
}


/*
  browserGetURLRequest:
  Notify plugin to get the specified url into target
*/
static void browserGetURLRequest(int id, char* url, int urlSize, 
				char* target, int targetSize)
{

  if (!gSqueakBrowserSubProcess) {
    DPRINTF((stderr, "Cannot submit URL request -- "
	    "there is no connection to a browser\n"));
    return;
  }

  browserSendInt(CMD_GET_URL);
  browserSendInt(id);

  browserSendInt(urlSize);
  if (urlSize > 0)
    browserSend(url, urlSize);

  browserSendInt(targetSize);
  if (targetSize > 0)
    browserSend(target, targetSize);
}


/*
  browserPostURLRequest:
  Notify plugin to post data to the specified url and get result into target
*/

static void browserPostURLRequest(int id, char* url, int urlSize, 
				 char* target, int targetSize, 
				 char* postData, int postDataSize)
{
  
  if (!gSqueakBrowserSubProcess) {
    DPRINTF((stderr, "Cannot submit URL post request -- "
	    "there is no connection to a browser\n"));
    return;
  }

  browserSendInt(CMD_POST_URL);
  browserSendInt(id);

  browserSendInt(urlSize);
  if (urlSize > 0)
    browserSend(url, urlSize);

  browserSendInt(targetSize);
  if (targetSize > 0)
    browserSend(target, targetSize);

  browserSendInt(postDataSize);
  if (postDataSize > 0)
    browserSend(postData, postDataSize);
}

void browserSetCursor(Cursor *macCursor) {
	browserSendInt(CMD_SET_CURSOR);
    browserSend(macCursor, sizeof(Cursor));

}

/* helper functions */

static void browserReceive(void *buf, size_t count)
{
  ssize_t n;
  do {
    n= read(gSqueakBrowserPipes[SQUEAK_READ], buf, count);
  } while (n == -1 && (errno == EINTR || errno == EAGAIN));

  if (count == 44444) 
	DPRINTF((stderr, "VM: Read 4 bytes %i\n",*(int*)buf));

  if (n == -1)
    perror("Squeak read failed:");
  if (n < (ssize_t) count)
    DPRINTF((stderr, "Squeak read too few data from pipe\n"));
}


static void browserSend(const void *buf, size_t count)
{
  ssize_t n;
  do {
	n= write(gSqueakBrowserPipes[SQUEAK_WRITE], buf, count);
    } while (n == -1 && (errno == EINTR  || errno == EAGAIN));

  if (count == 44444) 
	DPRINTF((stderr, "VM: Send 4 bytes %i\n",*(int*)buf));

  if (n == -1)
    perror("Squeak plugin write failed:");
  if (n < (ssize_t) count)
    DPRINTF((stderr, "Squeak wrote too few data to pipe\n"));
}

void browserSendInt(int value)
{
  browserSend(&value, 4);
}
extern int windowActive;

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


void recordMouseEvent(EventRecord *theEvent)  {
	UInt32  carbonModifiers;
	EventRef tmpEvent;
	EventMouseButton mouseButton=0;
	windowActive = 1;
	
	mouseButton = MouseModifierStateFromBrowser(theEvent);
	carbonModifiers = theEvent->modifiers;

	if (!(theEvent->what == 5))
		DPRINTF((stderr,"VM: recordMouseEvent() carbonModifers %i mouseButton %i v %i h %i\n",(int) carbonModifiers,mouseButton,theEvent->where.v,theEvent->where.h));
	if (theEvent->what == kEventMouseMoved && mouseButton) 
		theEvent->what = kEventMouseDragged;
	if (theEvent->what == kEventMouseDown)
		DPRINTF((stderr,"VM: recordMouseEvent() cmd %i option %i control %i shift %i\n",(int) carbonModifiers & cmdKey,
		(int) carbonModifiers & optionKey,
		(int) carbonModifiers & controlKey,
		(int) carbonModifiers & shiftKey));
	
	MacCreateEvent(kCFAllocatorDefault, kEventClassMouse, theEvent->what, 0, kEventAttributeUserEvent, &tmpEvent);
	SetEventParameter(tmpEvent,kEventParamMouseLocation,typeQDPoint,sizeof(Point),&theEvent->where);
	SetEventParameter(tmpEvent,kEventParamKeyModifiers,typeUInt32,sizeof(UInt32),&carbonModifiers);
	SetEventParameter(tmpEvent,kEventParamMouseButton,typeMouseButton,sizeof(EventMouseButton),&mouseButton);
	recordMouseEventCarbon(tmpEvent,theEvent->what,true);
	ReleaseEvent(tmpEvent);
}

int MouseModifierStateFromBrowser(EventRecord *theEvent) {
	int stButtons;

	stButtons = 0;
	if ((theEvent->modifiers & btnState) == false) {  /* is false if button is down */
		stButtons = 1;		/* red button by default */
		if ((theEvent->modifiers & optionKey) != 0) {
			stButtons = 3;	/* yellow button if option down */
		}
		if ((theEvent->modifiers & cmdKey) != 0) {
			stButtons = 2;	/* blue button if command down */
		}
	} 

	return stButtons;
}

int recordKeyboardEvent(EventRecord *theEvent, int keyType) {
	int asciiChar, modifierBits;
	sqKeyboardEvent *evt, *extra;
	extern pthread_mutex_t gEventQueueLock;
	extern sqInputEvent *nextEventPut(void);
	extern int MouseModifierState(EventRecord *theEvent);
	
	pthread_mutex_lock(&gEventQueueLock);
	evt = (sqKeyboardEvent*) nextEventPut();

	/* keystate: low byte is the ascii character; next 4 bits are modifier bits */
	asciiChar = theEvent->message & charCodeMask;
	//modifierBits = MouseModifierStateFromBrowser(theEvent); //Capture mouse/option states
	//modifierBits = (modifierMap[(theEvent->modifiers >> 8)] << 3) | (modifierBits  & 0x7);
	modifierBits = MouseModifierState(theEvent);
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
	evt->utf32Code = 0;
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
	pthread_mutex_unlock(&gEventQueueLock);
	signalAnyInterestedParties();    
	return 1;
}


/*
  primitivePluginRequestUrlStream: url with: semaIndex
  Request a URL from the browser. Signal semaIndex
  when the result of the request can be queried.
  Returns a handle used in subsequent calls to plugin
  stream functions.
  Note: A request id is the index into requests[].
*/
sqInt
primitivePluginRequestURLStream()
{
  sqStreamRequest *req;
  int id, length, semaIndex;
  sqInt url;

  if (!gSqueakBrowserSubProcess) return primitiveFail();

  DPRINTF((stderr,"VM: primitivePluginRequestURLStream()\n"));

  for (id=0; id<MAX_REQUESTS; id++) {
    if (!requests[id]) break;
  }
  if (id >= MAX_REQUESTS) return primitiveFail();

  semaIndex= stackIntegerValue(0);
  url= stackObjectValue(1);
  if (failed()) return 0;

  if (!isBytes(url)) return primitiveFail();

  req= calloc(1, sizeof(sqStreamRequest));
  if (!req) return primitiveFail();
  req->localName= NULL;
  req->semaIndex= semaIndex;
  req->state= -1;
  requests[id]= req;

  length= byteSizeOf(url);
  browserGetURLRequest(id, (char *) firstIndexableField(url), length, NULL, 0);
  pop(3);
  push(positive32BitIntegerFor(id));
  DPRINTF((stderr,"VM:   request id: %i\n", id));
  return 1;
}


/*
  primitivePluginRequestURL: url target: target semaIndex: semaIndex
  Request a URL into the given target.
*/
sqInt
primitivePluginRequestURL()
{
  sqStreamRequest *req;
  int urlLength;
  int targetLength;
  sqInt target,url;
  int id, semaIndex;

  if (!gSqueakBrowserSubProcess) return primitiveFail();
  DPRINTF((stderr,"VM: primitivePluginRequestURL()\n"));

  for (id=0; id<MAX_REQUESTS; id++) {
    if (!requests[id]) break;
  }

  if (id >= MAX_REQUESTS) return primitiveFail();

  semaIndex= stackIntegerValue(0);
  target= stackObjectValue(1);
  url= stackObjectValue(2);

  if (failed()) return 0;
  if (!isBytes(url) || !isBytes(target)) return primitiveFail();

  urlLength= byteSizeOf(url);
  targetLength= byteSizeOf(target);

  req= calloc(1, sizeof(sqStreamRequest));
  if(!req) return primitiveFail();
  req->localName= NULL;
  req->semaIndex= semaIndex;
  req->state= -1;
  requests[id]= req;

  browserGetURLRequest(id,  (char *)  firstIndexableField(url), urlLength, (char *)  firstIndexableField(target), targetLength);
  pop(4);
  push(positive32BitIntegerFor(id));
  return 1;
}

static int isFileURL(int urlOop) {
  int urlLen;
  char *urlPtr;
  urlLen = byteSizeOf(urlOop);
  urlPtr =  (char *) firstIndexableField(urlOop);
  while(*urlPtr == ' ' && urlLen) {
    urlPtr++;
    urlLen--;
  }
  if(urlLen < 5) return 0;
  return strncmp("file:", urlPtr, 5) == 0;
}

/*
  primitivePluginPostURL
*/
/*
  primitivePluginPostURL: url target: target data: data semaIndex: semaIndex
  Post data to a URL.
*/
EXPORT(sqInt)
primitivePluginPostURL(void)
{
  sqStreamRequest *req;
  int urlLength;
  int dataLength;
  sqInt data,target,url,targetLength;
  int id, semaIndex;

  if (!gSqueakBrowserSubProcess) return primitiveFail();
  if(methodArgumentCount() != 4) return primitiveFail();
  for(id=0; id<MAX_REQUESTS;id++) {
    if(!requests[id]) break;
  }

  if(id >= MAX_REQUESTS) return primitiveFail();

  semaIndex = stackIntegerValue(0);
  data = stackObjectValue(1);
  target = stackObjectValue(2);
  url = stackObjectValue(3);

  if(failed()) return 0;
  if(!isBytes(url) || !isBytes(data)) return primitiveFail();
  if(isFileURL(url)) return primitiveFail();

  if(target == nilObject()) {
    target = 0;
    targetLength = 0;
  } else {
    if(!isBytes(target)) return primitiveFail();
    targetLength = byteSizeOf(target);
  }

  urlLength = byteSizeOf(url);
  dataLength = byteSizeOf(data);

  req = calloc(1, sizeof(sqStreamRequest));
  if(!req) return primitiveFail();
  req->localName = NULL;
  req->semaIndex = semaIndex;
  req->state = -1;
  requests[id] = req;

  browserPostURLRequest(id, 
		 (char *) firstIndexableField(url), urlLength, 
		target ? ( (char *) firstIndexableField(target)) : NULL, targetLength,
		 (char *) firstIndexableField(data), dataLength); 
  pop(4);
  push(positive32BitIntegerFor(id));
  return 1;
}

/* 
  primitivePluginRequestFileHandle: id
  After a URL file request has been successfully
  completed, return a file handle for the received
  data. Note: The file handle must be read-only for
  security reasons.
*/
sqInt
primitivePluginRequestFileHandle()
{
  sqStreamRequest *req;
  int id, fileOop;
  void *openFn;

  DPRINTF((stderr,"VM: primitivePluginRequestFileHandle()\n"));
  id= stackIntegerValue(0);
  if (failed()) return 0;
  if (id < 0 || id >= MAX_REQUESTS) return primitiveFail();

  req= requests[id];
  if (!req || !req->localName) return primitiveFail();

  fileOop= nilObject();

  if (req->localName)
    {
      DPRINTF((stderr,"VM: Creating file handle for %s\n", req->localName));
 
      openFn= ioLoadFunctionFrom("fileOpenNamesizewritesecure", "FilePlugin");
      if (!openFn)
      {
	DPRINTF((stderr,"VM:   Couldn't load fileOpenName:size:write:secure: from FilePlugin!\n"));
	return primitiveFail();
      }
  
      fileOop= ((sqInt (*)(char *, sqInt, sqInt, sqInt))openFn)
	(req->localName, strlen(req->localName), 0 /* readonly */, 0 /* insecure */);
 
      /* if file ends in a $, it was a temp link created by the plugin */
      if ('$' == req->localName[strlen(req->localName) - 1])
      {
	DPRINTF((stderr,"VM:   unlink %s\n", req->localName));
	if (-1 == unlink(req->localName))
	  DPRINTF((stderr,"VM:   unlink failed: %s\n", strerror(errno)));
      }

      if (failed()) 
	{
	  DPRINTF((stderr,"VM:   file open failed\n"));
	  return 0;
	}
    }
  pop(2);
  push(fileOop);
  return 1;
}


/*
  primitivePluginDestroyRequest: id
  Destroy a request that has been issued before.
*/
sqInt
primitivePluginDestroyRequest()
{
  sqStreamRequest *req;
  int id;

  DPRINTF((stderr,"VM: primitivePluginDestroyRequest()\n"));
  id= stackIntegerValue(0);
  if (id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req= requests[id];
  if (req) {
    if (req->localName) free(req->localName);
    free(req);
  }
  requests[id]= NULL;
  pop(1);
  return 1;
}


/*
  primitivePluginRequestState: id
  Return true if the operation was successfully completed.
  Return false if the operation was aborted.
  Return nil if the operation is still in progress.
*/
sqInt
primitivePluginRequestState()
{
  sqStreamRequest *req;
  int id;

  DPRINTF((stderr,"VM: primitivePluginRequestState()\n"));
  id= stackIntegerValue(0);
  if (id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req= requests[id];
  if (!req) return primitiveFail();
  pop(2);
  if (req->state == -1) push(nilObject());
  else pushBool(req->state);
  return 1;
}

int browserGetWindowSize() {
	return (width << 16) | (height & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

