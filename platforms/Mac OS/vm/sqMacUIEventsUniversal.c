/****************************************************************************
*   PROJECT: Mac event interface.
*   FILE:    sqMacUIEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIEvents.c 1297 2006-02-02 07:59:16Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar 1st, 2002, JMM carbon event logic, mutiple buttons with scroll wheels.
*  Mar 8th,  2002, JMM Add logic to pass in external prim calls that require main thread UI execution
*  Mar 10th, 2002, JMM correct bad char cast, ensure we can get all characters.
*  Mar 14th, 2002, JMM fix text input for encoding keys (textinput versus raw char)
*  Apr 17th, 2002, JMM Use accessors for VM variables.
*  3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x drop usb stuff
*  3.5.1b2 June 6th, 2003 JMM support for aio polling under unix socket support
*  3.5.1b3 June 7th, 2003 JMM fix up full screen pthread issue.
*  3.5.1b5 June 25th, 2003 JMM don't close window on floating full screen, handle issue with keydown and floating window if required.
*  3.6.0b1 Aug 5th, 2003 JMM only invoke event timer loop logic if gTapPowerManager is true (OS supports!)
*  3.6.2b3 Nov 25th, 2003 JMM Tetsuya HAYASHI <tetha@st.rim.or.jp> supplied multiple unicode extraction
*  3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
*  3.7.1b3 Jan 29th, 2004  JMM return unicode for classic version versus virtual keyboard code 
*  3.7.3b2 Apr 10th, 2004 JMM Tetsuya HAYASHI <tetha@st.rim.or.jp>  alteration to unicode key capture
*  3.8.0b1 July 20th, 2004 JMM Multiple window support
*  3.8.5b2 Jan 25th, 2005 JMM reduce qd buffer flushing.
*  3.8.7b1 Mar 13th, 2005 JMM fire keydown/keychar on key repeat to mimic ms windows behavior.
*  3.8.7b2 Mar 19th, 2005 JMM change keydown/up back to virtual keycode, add unicode to keychar
*  3.8.8b9 Aug 15th, 2005 JMM flush quartz buffer if needded
*  3.9.1b2 Oct 4th, 2005 Jmm add MillisecondClockMask
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
 3.8.12b6u Sept 5th, 2006 JMM rework mouse logic for mac
 3.8.13b4u  Oct 16th, 2006 JMM headless
 *	3.8.14b1 Oct	,2006 JMM browser rewrite

notes: IsUserCancelEventRef

*****************************************************************************/
#define MillisecondClockMask 536870911


#include "sq.h"
#include "sqMacUIEvents.h"
#include "sqMacUIMenuBar.h"
#include "sqMacWindow.h"
#include "sqMacHostWindow.h"
#include "sqMacTime.h"

#include <pthread.h>
#include "sqaio.h"

enum { KeyMapSize= 32 };

typedef struct
{
  int keyCode;
  int keyChar;
  int keyRepeated;
} KeyMapping;

pthread_mutex_t gEventQueueLock;

#define EventTypeFullScreenUpdate 98
#define EventTypePostEventProcessing 99
static void doPostMessageHook(EventRef event);
static void postFullScreenUpdate(void);
void signalAnyInterestedParties(void);
static sqKeyboardEvent *enterKeystroke (long type, long cc, long pc, UniChar utf32Char, long m);

static int addToKeyMap(int keyCode, int keyChar);
static int findInKeyMap(int keyCode);
static int removeFromKeyMap(int keyCode);
static int indexInKeyMap(int keyCode);
static int findRepeatInKeyMap(int keyCode);
static void setRepeatInKeyMap(int keyCode);

static void doPendingFlush(void);

/*** Variables -- Event Recording ***/
#define MAX_EVENT_BUFFER 1024

extern int getInterruptKeycode();
extern int setInterruptPending(int value);
extern int setInterruptCheckCounter(int value);
extern int getFullScreenFlag();
extern struct VirtualMachine* interpreterProxy;
extern Boolean gSqueakHeadless;
extern Boolean			gSqueakBrowserSubProcess;

static KeyMapping keyMap[KeyMapSize];
static int keyMapSize=	   0;
static Boolean gQuitNowRightNow=false;

extern MenuHandle editMenu;
extern MenuHandle appleMenu;

static sqInputEvent eventBuffer[MAX_EVENT_BUFFER];
static int eventBufferGet = 0;
static int eventBufferPut = 0;


/* event capture */
sqInputEvent *nextEventPut(void);

#define MAKETHESESTATIC static
 
#define KEYBUF_SIZE 64
/* declaration of the event message hook */
MAKETHESESTATIC eventMessageHook messageHook = NULL;
MAKETHESESTATIC eventMessageHook postMessageHook = NULL;
MAKETHESESTATIC int inputSemaphoreIndex = 0;/* if non-zero the event semaphore index */
 int keyBuf[KEYBUF_SIZE];	/* circular buffer */
 int keyBufGet = 0;			/* index of next item of keyBuf to read */
 int keyBufPut = 0;			/* index of next item of keyBuf to write */
 int keyBufOverflows = 0;	/* number of characters dropped */

 int buttonState = 0;		/* mouse button and modifier state when mouse
							   button went down or 0 if not pressed */
 int cachedButtonState = 0;	/* buffered mouse button and modifier state for
							   last mouse click even if button has since gone up;
							   this cache is kept until the next time ioGetButtonState()
							   is called to avoid missing short clicks */
int gButtonIsDown = 0;
int windowActive = 0;		/* positive indicates the active window */

static Point savedMousePosition;	/* mouse position when window is inactive */

/* This table maps the 5 Macintosh modifier key bits to 4 Squeak modifier
   bits. (The Mac shift and caps lock keys are both mapped to the single
   Squeak shift bit).  This was true for squeak upto 3.0.7. Then in 3.0.8 we 
   decided to not map the cap lock key to shift
   
		Mac bits: <control><option><caps lock><shift><command>
		ST bits:  <command><option><control><shift>
*/
 char modifierMap[256] = {	
 0, 8, 1, 9, 0, 8, 1, 9, 4, 12, 5, 13, 4, 12, 5, 13, //Track left and right shift keys
 2, 10, 3, 11, 2, 10, 3, 11, 6, 14, 7, 15, 6, 14, 7, 
15, 1, 9, 1, 9, 1, 9, 1, 9, 5, 13, 5, 13, 5, 13, 5, 
13, 3, 11, 3, 11, 3, 11, 3, 11, 7, 15, 7, 15, 7, 15,
 7, 15, 4, 12, 5, 13, 4, 12, 5, 13, 4, 12, 5, 13, 4,
12, 5, 13, 6, 14, 7, 15, 6, 14, 7, 15, 6, 14, 7, 15, 
 6, 14, 7, 15, 5, 13, 5, 13, 5, 13, 5, 13, 5, 13, 5,
13, 5, 13, 5, 13, 7, 15, 7, 15, 7, 15, 7, 15, 7, 15, 
 7, 15, 7, 15, 7, 15, 2, 10, 3, 11, 2, 10, 3, 11, 6, 
14, 7, 15, 6, 14, 7, 15, 2, 10, 3, 11, 2, 10, 3, 11, 
 6, 14, 7, 15, 6, 14, 7, 15, 3, 11, 3, 11, 3, 11, 3, 
 11, 7, 15, 7, 15, 7, 15, 7, 15, 3, 11, 3, 11, 3, 11, 
 3, 11, 7, 15, 7, 15, 7, 15, 7, 15, 6, 14, 7, 15, 6, 
 14, 7, 15, 6, 14, 7, 15, 6, 14, 7, 15, 6, 14, 7, 15, 
 6, 14, 7, 15, 6, 14, 7, 15, 6, 14, 7, 15, 7, 15, 7, 
 15, 7, 15, 7, 15, 7, 15, 7, 15, 7, 15, 7, 15, 7, 15, 
 7, 15, 7, 15, 7, 15, 7, 15, 7, 15, 7, 15, 7, 15 };

Boolean IsKeyDown(void);    

int recordDragDropEvent(EventRecord *theEvent, int numberOfItems, int dragType) {
	sqDragDropFilesEvent *evt;
	int theButtonState;
	
        pthread_mutex_lock(&gEventQueueLock);
        evt = (sqDragDropFilesEvent*) nextEventPut();

	/* first the basics */
	theButtonState = MouseModifierState(theEvent);
	evt->type = EventTypeDragDropFiles;
	evt->timeStamp = ioMSecs() & MillisecondClockMask; 
	GlobalToLocal((Point *) &theEvent->where);
	evt->x = theEvent->where.h;
	evt->y = theEvent->where.v;
	evt->numFiles = numberOfItems;
	evt->dragType = dragType;
	
	/* then the modifiers */
	evt->modifiers = theButtonState >> 3;
	evt->windowIndex = windowActive;
        pthread_mutex_unlock(&gEventQueueLock);
        signalAnyInterestedParties();
//	signalSemaphoreWithIndex(inputSemaphoreIndex);
	return 1;
}

int MouseModifierState(EventRecord *theEvent) {
	int stButtons;

	stButtons = 0;
	if ((theEvent->modifiers & btnState) == false) {  /* is false if button is down */
		stButtons = 4;		/* red button by default */
		if ((theEvent->modifiers & optionKey) != 0) {
			stButtons = 2;	/* yellow button if option down */
		}
		if ((theEvent->modifiers & cmdKey) != 0) {
			stButtons = 1;	/* blue button if command down */
		}
	} 

	/* button state: low three bits are mouse buttons; next 8 bits are modifier bits */
	return ((modifierMap[(theEvent->modifiers >> 8)] << 3) |
		(stButtons & 0x7));
}


sqInputEvent *nextEventPut(void) {
	sqInputEvent *evt;
	evt = eventBuffer + eventBufferPut;
	eventBufferPut = (eventBufferPut + 1) % MAX_EVENT_BUFFER;
	if (eventBufferGet == eventBufferPut) {
		/* buffer overflow; drop the last event */
		eventBufferGet = (eventBufferGet + 1) % MAX_EVENT_BUFFER;
	}
	return evt;
}

void ignoreLastEvent() {
    eventBufferPut -= 1;
    if (eventBufferPut < 0) 
        eventBufferPut = MAX_EVENT_BUFFER -1;
}

int ioSetInputSemaphore(int semaIndex) {
	inputSemaphoreIndex = semaIndex;
	return 1;
}

int ioGetNextEvent(sqInputEvent *evt) {
		ioProcessEvents();
		pthread_mutex_lock(&gEventQueueLock);
	if (eventBufferGet == eventBufferPut) {
            pthread_mutex_unlock(&gEventQueueLock);
            return false;
        }
	*evt = eventBuffer[eventBufferGet];
	eventBufferGet = (eventBufferGet+1) % MAX_EVENT_BUFFER;
        pthread_mutex_unlock(&gEventQueueLock);
        if (evt->type == EventTypeFullScreenUpdate) {
            fullDisplayUpdate();	//Note I think it's ok to unlock by now
            return ioGetNextEvent(evt);
        }
        
        if (evt->type == EventTypePostEventProcessing) {
            if (postMessageHook) 
                postMessageHook((EventRecord *) evt->unused1);
            free((void *) evt->unused1);
            return ioGetNextEvent(evt);
        }
	return true;
}

int ioGetButtonState(void) {
	    ioProcessEvents();
	if ((cachedButtonState & 0x7) != 0) {
		int result = cachedButtonState;
		cachedButtonState = 0;  /* clear cached button state */
		return result;
	}
	cachedButtonState = 0;  /* clear cached button state */
	return buttonState;
}

int ioGetKeystroke(void) {
	int keystate;

	    ioProcessEvents();
	if (keyBufGet == keyBufPut) {
		return -1;  /* keystroke buffer is empty */
	} else {
		keystate = keyBuf[keyBufGet];
		keyBufGet = (keyBufGet + 1) % KEYBUF_SIZE;
		/* set modifer bits in buttonState to reflect the last keystroke fetched */
		buttonState = ((keystate >> 5) & 0xF8) | (buttonState & 0x7);
	}
	return keystate;
}
int ioMousePoint(void) {
	Point p;

	    ioProcessEvents();
	if (windowActive) {
		GetMouse(&p);
	} else {
		/* don't report mouse motion if window is not active */
		p = savedMousePosition;
	}
	return (p.h << 16) | (p.v & 0xFFFF);  /* x is high 16 bits; y is low 16 bits */
}

int ioPeekKeystroke(void) {
	int keystate;
	    ioProcessEvents();
	if (keyBufGet == keyBufPut) {
		return -1;  /* keystroke buffer is empty */
	} else {
		keystate = keyBuf[keyBufGet];
		/* set modifer bits in buttonState to reflect the last keystroke peeked at */
		buttonState = ((keystate >> 5) & 0xF8) | (buttonState & 0x7);
	}
	return keystate;
}

void setMessageHook(eventMessageHook theHook) {
    messageHook = theHook;
}

void setPostMessageHook(eventMessageHook theHook) {
    postMessageHook = theHook;
}

Boolean IsKeyDown() {
    interpreterProxy->success(false);
    return null;
}

extern MenuHandle fileMenu, editMenu;

static EventTypeSpec appEventCmdList[] = {{kEventClassCommand, kEventCommandProcess}};

static EventTypeSpec appEventList[] = {{kEventClassApplication, kEventAppActivated},
                                {kEventClassApplication, kEventAppDeactivated}};

static EventTypeSpec windEventList[] = {{kEventClassWindow, kEventWindowDrawContent },
                            { kEventClassWindow, kEventWindowHidden },
                            { kEventClassWindow, kEventWindowActivated},
							{ kEventClassWindow, kEventWindowBoundsChanged},
							{ kEventClassWindow, kEventWindowResizeStarted},
							{ kEventClassWindow, kEventWindowClose},
							{ kEventClassWindow, kEventWindowCollapsed},
                            { kEventClassWindow, kEventWindowDeactivated}};
                            
static EventTypeSpec windEventMouseList[] = {
							{ kEventClassMouse, kEventMouseMoved},
                            { kEventClassMouse, kEventMouseWheelMoved},
                            { kEventClassMouse, kEventMouseDragged},
                            { kEventClassMouse, kEventMouseUp},
							{ kEventClassMouse, kEventMouseDown}
							};
                            
static EventTypeSpec windEventKBList[] = {{ kEventClassKeyboard, kEventRawKeyDown},
                            { kEventClassKeyboard, kEventRawKeyUp},
							{ kEventClassKeyboard, kEventRawKeyRepeat},
                            { kEventClassKeyboard, kEventRawKeyModifiersChanged}};
                            
                            
static EventTypeSpec appleEventEventList[] = {{ kEventClassAppleEvent, kEventAppleEvent}};

static EventTypeSpec textInputEventList[] = {{ kEventClassTextInput, kEventTextInputUnicodeForKeyEvent}};

static pascal OSStatus MyAppEventHandler (EventHandlerCallRef myHandlerChain,
                EventRef event, void* userData);
static pascal OSStatus MyAppEventCmdHandler (EventHandlerCallRef myHandlerChain,
                EventRef event, void* userData);
static pascal OSStatus MyWindowEventHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData);
static pascal OSStatus MyWindowEventMouseHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData);
static pascal OSStatus MyWindowEventKBHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData);
static pascal OSStatus MyAppleEventEventHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData);
static pascal OSStatus MyTextInputEventHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData);
static pascal OSStatus customHandleForUILocks(EventHandlerCallRef myHandler,
            EventRef event, void* userData);
            
static int MouseModifierStateCarbon(EventRef theEvent,UInt32 whatHappened);   
static int ModifierStateCarbon(EventRef theEvent);   
void recordMouseEventCarbon(EventRef event,UInt32 whatHappened);
static void recordKeyboardEventCarbon(EventRef event);
static void recordMenuEventCarbon(MenuRef menu, UInt32 menuItem);
static void recordWindowEventCarbon(int windowType,int left, int top, int right, int bottom,int windowIndex);
static int doPreMessageHook(EventRef event); 
static void fakeMouseWheelKeyboardEvents(EventMouseWheelAxis wheelMouseDirection,long wheelMouseDelta);
            
void SetUpCarbonEvent() {
	
	if (!gSqueakHeadless) AdjustMenus();

/* Installing the application event handler */
	InstallApplicationEventHandler(NewEventHandlerUPP(MyAppEventCmdHandler), GetEventTypeCount(appEventCmdList), appEventCmdList, 0, NULL);
    InstallApplicationEventHandler(NewEventHandlerUPP(MyAppEventHandler), GetEventTypeCount(appEventList), appEventList, 0, NULL);
    
}

void SetUpCarbonEventForWindowIndex(int index) {
/* Installing the window event handler */
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyWindowEventHandler), GetEventTypeCount(windEventList), windEventList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyWindowEventMouseHandler), GetEventTypeCount(windEventMouseList), windEventMouseList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyWindowEventKBHandler), GetEventTypeCount(windEventKBList), windEventKBList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyAppleEventEventHandler), GetEventTypeCount(appleEventEventList), appleEventEventList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyTextInputEventHandler), GetEventTypeCount(textInputEventList), textInputEventList, 0, NULL);
}

static int   doPreMessageHook(EventRef event) {
   /* jmm rethink, breaks not thread safe
    if (messageHook) {
        EventRecord theOldEventType;
        if (!ConvertEventRefToEventRecord(event,&theOldEventType))
            return eventNotHandledErr;
        if (messageHook(&theOldEventType))
            return noErr;
    } */
    return eventNotHandledErr;
}

static void   doPostMessageHook(EventRef event) {
    if (postMessageHook) {
        EventRecord *theOldEventType;
        sqInputEvent *evt;
        
        theOldEventType = malloc(sizeof(EventRecord));
        if (!ConvertEventRefToEventRecord(event,theOldEventType)) {
            free(theOldEventType);
            return;
        }
        pthread_mutex_lock(&gEventQueueLock);
	evt = nextEventPut();
	evt->type = EventTypePostEventProcessing;
	evt->windowIndex = windowActive;
	evt->unused1 = (long) theOldEventType;
        pthread_mutex_unlock(&gEventQueueLock);

        // not quite this postMessageHook(&theOldEventType);
    }
}

static void   postFullScreenUpdate() {
    sqInputEvent *evt;
    
    pthread_mutex_lock(&gEventQueueLock);
    evt = nextEventPut();
    evt->type = EventTypeFullScreenUpdate;
	evt->windowIndex = windowActive;
    pthread_mutex_unlock(&gEventQueueLock);
}

static pascal OSStatus MyAppEventHandler (EventHandlerCallRef myHandlerChain,
    EventRef event, void* userData)
{
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
    extern Boolean gSqueakWindowIsFloating;
    
    if (messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;

    whatHappened = GetEventKind(event);

	//fprintf(stderr,"\nAppEvent %i",whatHappened);
    switch (whatHappened)
    {
        case kEventAppActivated:
            break;
        case kEventAppDeactivated:
            if (gSqueakWindowIsFloating) break;
			InitCursor();
			windowActive = 0;
            break;
        default:
            break;
    }
    if (postMessageHook) 
        doPostMessageHook(event);
    return result;
}

static pascal OSStatus MyAppEventCmdHandler (EventHandlerCallRef myHandlerChain,
EventRef event, void* userData)
{
    UInt32 whatHappened;
    HICommand commandStruct;    
    OSStatus result = eventNotHandledErr; /* report failure by default */

    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;
    whatHappened = GetEventKind(event);
    switch (whatHappened)
    {
        case kEventCommandProcess:
            GetEventParameter (event, kEventParamDirectObject,
                typeHICommand, NULL, sizeof(HICommand),NULL, &commandStruct);

            if (commandStruct.menu.menuRef == fileMenu && commandStruct.menu.menuItemIndex == quitItem) {
                        gQuitNowRightNow = true;
				result = noErr;
			} else if (commandStruct.commandID == kHICommandHide) {
			} else if (commandStruct.commandID == kHICommandHideOthers) {
			} else if (commandStruct.commandID == kHICommandShowAll) {
			} else if (windowActive) {
				recordMenuEventCarbon(commandStruct.menu.menuRef,commandStruct.menu.menuItemIndex);
				result = noErr;
			}
            break;
        default:
            break;
    }
    if (postMessageHook) 
        doPostMessageHook(event);
    return result;
}

static pascal OSStatus MyWindowEventHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData)
{
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
    extern Boolean gSqueakWindowIsFloating;
	Rect globalBounds;
    WindowRef window;
  
    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;
    GetEventParameter(event, kEventParamDirectObject, typeWindowRef, NULL,sizeof(window), NULL, &window);
    whatHappened = GetEventKind(event);
	//fprintf(stderr,"\nWindowEvent %i %i %i",whatHappened,IsWindowActive(window),windowIndexFromHandle((int)window));
	if (windowIndexFromHandle(window) == 0) 
		return result;
    switch (whatHappened)
    {
         case kEventWindowActivated:
          windowActive = windowIndexFromHandle((wHandleType)window);
            postFullScreenUpdate();
			recordWindowEventCarbon(WindowEventActivated,0, 0, 0, 0,windowActive);
             break;
        case kEventWindowDeactivated:
            if (gSqueakWindowIsFloating) break; 
#warning HIView Point
            GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,
                    sizeof(Point), NULL, &savedMousePosition);
			if (windowIndexFromHandle((wHandleType)window)) {
#warning foocheck
				QDGlobalToLocalPoint(GetWindowPort((wHandleType)window),&savedMousePosition);
			}
            windowActive = 0;
             break;
       case kEventWindowDrawContent:
            result = noErr;
            break;
       case kEventWindowResizeStarted:
			{ 
				windowDescriptorBlock *targetWindowBlock;
				targetWindowBlock = windowBlockFromHandle((wHandleType)window);	
				targetWindowBlock->sync = true;
			}
            break;
		case kEventWindowBoundsChanged:
			GetWindowBounds(window,kWindowContentRgn,&globalBounds);
			recordWindowEventCarbon(WindowEventMetricChange,globalBounds.left, globalBounds.top, 
					globalBounds.right, globalBounds.bottom,windowIndexFromHandle((wHandleType)window));
			break;
		case kEventWindowCollapsed:
			recordWindowEventCarbon(WindowEventIconise,0, 0, 0, 0,windowIndexFromHandle((wHandleType)window));
			break;
		case kEventWindowClose:
			recordWindowEventCarbon(WindowEventClose,0, 0, 0, 0,windowIndexFromHandle((wHandleType)window));
			result = noErr;
			break;
        case kEventWindowHidden:
            if (gSqueakWindowIsFloating && windowIndexFromHandle((wHandleType)window)) {
                ShowWindow(windowHandleFromIndex(windowIndexFromHandle((wHandleType)window)));
                result = noErr;
            }
            break;
        default:
        /* If nobody handled the event, it gets propagated to the */
        /* application-level handler. */
        break;
    }
    if (postMessageHook) 
        doPostMessageHook(event);
    return result;
}


static pascal OSStatus MyWindowEventMouseHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData)
{
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
	OSStatus crosscheckForErrors;
 	static Boolean mouseDownActivate=false;
    extern Boolean gSqueakWindowIsFloating,gSqueakFloatingWindowGetsFocus;
    WindowPartCode windowPartCode;
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_3
    Point  mouseLocation;
	static RgnHandle	ioWinRgn=null;
#endif	
    whatHappened	= GetEventKind(event);
	

	//if (whatHappened != 5) 
	//	fprintf(stderr,"\nMouseEvent %i-%i ",whatHappened,windowActive);

	if (!windowActive) {
		if (whatHappened == kEventMouseDown)
			mouseDownActivate = true;
        return result;
	}
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_3
    if (ioWinRgn == null) 
        ioWinRgn = NewRgn();
        
    GetWindowRegion(windowHandleFromIndex(windowActive),kWindowGlobalPortRgn,ioWinRgn);
    GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,sizeof(Point), NULL, &mouseLocation);
    
    if (!PtInRgn(mouseLocation,ioWinRgn)) {
		if (mouseDownActivate && whatHappened == kEventMouseUp) {
			mouseDownActivate = false;
			return result;
		}
		if (!gButtonIsDown) 
			return result;
    }
#else
	crosscheckForErrors = GetEventParameter (event, kEventParamWindowPartCode, typeWindowPartCode,NULL,sizeof(WindowPartCode), NULL, &windowPartCode);
    if (windowPartCode < 3) {
		if (mouseDownActivate && whatHappened == kEventMouseUp) {
			mouseDownActivate = false;
			return result;
		}
		if (!gButtonIsDown) 
			return result;
    }
#endif

    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;
    

    switch (whatHappened)
    {
        case kEventMouseMoved:
        case kEventMouseDragged:
        case kEventMouseWheelMoved:
			if (mouseDownActivate) 
				return result;
            recordMouseEventCarbon(event,whatHappened);
            result = noErr;
            return result; //Return early not an event we deal with for post event logic
        case kEventMouseDown:
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_3
			GetWindowRegion(windowHandleFromIndex(windowActive),kWindowGrowRgn,ioWinRgn);
            if (PtInRgn(mouseLocation,ioWinRgn))
                return result;
#else
            if (windowPartCode != inContent)
                return result;
#endif
			if (mouseDownActivate) 
				return result;
            if (gSqueakFloatingWindowGetsFocus && gSqueakWindowIsFloating) {
                SetUserFocusWindow(kUserFocusAuto);
                SetUserFocusWindow(windowHandleFromIndex(windowActive));
            }
            gButtonIsDown = true;
            recordMouseEventCarbon(event,whatHappened);
            result = noErr;
            break;
        case kEventMouseUp:
			if (mouseDownActivate) {
				mouseDownActivate = false;
				return result;
			}
            gButtonIsDown = false;
            recordMouseEventCarbon(event,whatHappened);
            result = noErr;
            break;
        default:
        /* If nobody handled the event, it gets propagated to the */
        /* application-level handler. */
        break;
    }
    if (postMessageHook) 
        doPostMessageHook(event);
	//fprintf(stderr,"handled %i",result);
    return result;
}

static pascal OSStatus MyWindowEventKBHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData)
{
    UInt32 whatHappened,keyCode;
	SInt32 key;
    OSStatus result = eventNotHandledErr; /* report failure by default */
	 
    if (!windowActive)
        return result;

    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;
		
    whatHappened = GetEventKind(event);
	GetEventParameter (event, kEventParamKeyCode, typeUInt32,NULL, sizeof(typeUInt32), NULL, &keyCode);
    switch (whatHappened)
    {
        case kEventRawKeyDown:
			//fprintf(stdout,"\nrawkey down %i",ioMSecs());
			addToKeyMap(keyCode, 0);	
            result = eventNotHandledErr;
            break;
        case kEventRawKeyRepeat:
			//fprintf(stdout,"\nrawkey repeat %i",ioMSecs());
			setRepeatInKeyMap(keyCode);
            result = eventNotHandledErr;
            break;
        case kEventRawKeyUp:
			//fprintf(stdout,"\nrawkey up %i",ioMSecs());
			key = findInKeyMap(keyCode);
			if (key != -1) {
				enterKeystroke ( EventTypeKeyboard,keyCode, EventKeyUp, 0, ModifierStateCarbon(event));
			}
			removeFromKeyMap(keyCode);
            result = eventNotHandledErr;
            break;
        case kEventRawKeyModifiersChanged: 
            /* ok in this case we fake a mouse event to deal with the modifiers changing */
            if(inputSemaphoreIndex)
                recordMouseEventCarbon(event,kEventMouseMoved);
            result = noErr;
            break;
        default: 
        /* If nobody handled the event, it gets propagated to the */
        /* application-level handler. */
        break;
    }
    if (postMessageHook) 
        doPostMessageHook(event);
    return result;
}
static pascal OSStatus MyAppleEventEventHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData)
{
    return eventNotHandledErr;
}

static pascal OSStatus MyTextInputEventHandler(EventHandlerCallRef myHandler,
            EventRef event, void* userData)
{
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
    
    if (!windowActive)
        return result;
		
    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;

    whatHappened = GetEventKind(event);
    switch (whatHappened)
    {
        case kEventTextInputUnicodeForKeyEvent:
            recordKeyboardEventCarbon(event);
            result = noErr;
        default: 
        /* If nobody handled the event, it gets propagated to the */
        /* application-level handler. */
        break;
    }
    if (postMessageHook) 
        doPostMessageHook(event);
    return result;
}

static void recordMenuEventCarbon(MenuRef menu,UInt32 menuItem) {
	sqMenuEvent *evt;
	pthread_mutex_lock(&gEventQueueLock);
	evt = (sqMenuEvent*) nextEventPut();

	evt->type = EventTypeMenu;
	evt->timeStamp = ioMSecs() & MillisecondClockMask; 
	evt->menu = (int) GetMenuID(menu);
	evt->menuItem = menuItem;
	evt->reserved1 = 0;
	evt->reserved2 = 0;
	evt->reserved3 = 0;
	evt->windowIndex = windowActive;
	pthread_mutex_unlock(&gEventQueueLock);
	signalAnyInterestedParties();
	return;
}

static void recordWindowEventCarbon(int windowType,int left, int top, int right, int bottom, int windowIndex) {
	sqWindowEvent *evt;
	pthread_mutex_lock(&gEventQueueLock);
	evt = (sqWindowEvent*) nextEventPut();

	evt->type = EventTypeWindow;
	evt->timeStamp = ioMSecs() & MillisecondClockMask; 
	evt->action = windowType;
	evt->value1 = left;
	evt->value2 = top;
	evt->value3 = right;
	evt->value4 = bottom;
	evt->windowIndex = windowIndex;
	pthread_mutex_unlock(&gEventQueueLock);
	signalAnyInterestedParties();
	return;
}

void recordMouseEventCarbon(EventRef event,UInt32 whatHappened) {
	sqMouseEvent *evt;
	static sqMouseEvent oldEvent;
	static Point  where;
	EventMouseWheelAxis wheelMouseDirection=0;
	long	wheelMouseDelta=0;
	OSErr		err;
	
	err = GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,
				sizeof(Point), NULL, &where);
                    
 	if (err == noErr)
		QDGlobalToLocalPoint(GetWindowPort(windowHandleFromIndex(windowActive)),&where);
	// on error use last known mouse location. 
	

	buttonState = MouseModifierStateCarbon(event,whatHappened);
 	cachedButtonState = cachedButtonState | buttonState;

	//fprintf(stderr,"VM: recordMouseEventCarbon v %i h %i buttonState %i \n ",where.v,where.h,buttonState);
      
        if (whatHappened == kEventMouseWheelMoved) {
            GetEventParameter( event,
                                kEventParamKeyModifiers,
                                typeMouseWheelAxis,
                                NULL,
                                sizeof(EventMouseWheelAxis),
                                NULL,
                                &wheelMouseDirection); 
            GetEventParameter( event,
                                kEventParamMouseWheelDelta,
                                typeLongInteger,
                                NULL,
                                sizeof(long),
                                NULL,
                                &wheelMouseDelta); 
       }

        pthread_mutex_lock(&gEventQueueLock);
	evt = (sqMouseEvent*) nextEventPut();

	/* first the basics */
	evt->type = EventTypeMouse;
	evt->timeStamp = ioMSecs() & MillisecondClockMask; 
        evt->x = where.h;
	evt->y = where.v;
	/* then the buttons */
	evt->buttons = buttonState & 0x07;
	/* then the modifiers */
	evt->modifiers = buttonState >> 3;
	/* clean up reserved */
	evt->reserved1 = 0;
	evt->windowIndex = windowActive;
	
	if (oldEvent.buttons == evt->buttons && 
	    oldEvent.x == evt->x &&
	    oldEvent.y == evt->y &&
	    oldEvent.modifiers == evt->modifiers &&
            whatHappened != kEventMouseWheelMoved) 
	    ignoreLastEvent();
	    
        oldEvent = *evt;
     	pthread_mutex_unlock(&gEventQueueLock);
        signalAnyInterestedParties();
                
        if (whatHappened == kEventMouseWheelMoved) 
            fakeMouseWheelKeyboardEvents(wheelMouseDirection,wheelMouseDelta);
}

static void fakeMouseWheelKeyboardEvents(EventMouseWheelAxis wheelMouseDirection,long wheelMouseDelta) {
    long 	i,asciiChar;
    sqKeyboardEvent *evt,*extra;
    UInt32	macKeyCode;
    
    pthread_mutex_lock(&gEventQueueLock);
    for(i=0;i<abs(wheelMouseDelta);i++) {
        if (wheelMouseDirection == kEventMouseWheelAxisX) 
            if (wheelMouseDelta > 0) {//up/down
                macKeyCode = 126;
                asciiChar = kUpArrowCharCode;
            } else {
                macKeyCode = 125;
                asciiChar = kDownArrowCharCode;
            }
        else
            if (wheelMouseDelta > 0) {//left/right
                macKeyCode = 124;
                asciiChar = kRightArrowCharCode;
            } else {
                macKeyCode = 123;
                asciiChar = kLeftArrowCharCode;
            }
            
	evt = (sqKeyboardEvent*) nextEventPut();
	/* first the basics */
	evt->type = EventTypeKeyboard;
	evt->timeStamp = ioMSecs() & MillisecondClockMask;
	/* now the key code */
	/* press code must differentiate */
	evt->charCode = macKeyCode;
	evt->pressCode = EventKeyDown;
	evt->modifiers = modifierMap[(controlKey >> 8)];
	evt->windowIndex = windowActive;
	/* generate extra character event */
        extra = (sqKeyboardEvent*)nextEventPut();
        *extra = *evt;
        extra->charCode = asciiChar;
        extra->utf32Code = asciiChar;
        extra->pressCode = EventKeyChar;
        
       if(!inputSemaphoreIndex) {
            int  keystate;
    
            /* keystate: low byte is the ascii character; next 8 bits are modifier bits */
    
            keystate = (evt->modifiers << 8) | asciiChar;
            if (keystate == getInterruptKeycode()) {
                    /* Note: interrupt key is "meta"; it not reported as a keystroke */
                    setInterruptPending(true);
                    setInterruptCheckCounter(0);
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
    }
    if (wheelMouseDelta != 0) {
    	evt = (sqKeyboardEvent*) nextEventPut();
	/* first the basics */
	evt->type = EventTypeKeyboard;
	evt->timeStamp = ioMSecs() & MillisecondClockMask;
	/* now the key code */
	/* press code must differentiate */
	evt->charCode = macKeyCode;
	evt->pressCode = EventKeyUp;
	evt->modifiers = modifierMap[(controlKey >> 8)];
	evt->windowIndex = windowActive;
    }
    pthread_mutex_unlock(&gEventQueueLock);
    signalAnyInterestedParties();                
}

static void recordKeyboardEventCarbon(EventRef event) {
    int				modifierBits, keyIndex, i, ISawRawKeyRepeat;
    UniCharCount	uniCharCount;
    UniChar			modifiedUniChar, *uniCharBufPtr, *uniCharBuf;
    OSErr			err;
    UInt32			actualSize,macKeyCode,textEntryServices; 
    EventRef		actualEvent;
	char		mackeycodeFromCarbon;
    
    //  Tetsuya HAYASHI <tetha@st.rim.or.jp> supplied multiple unicode extraction
    
    /*  kEventTextInputUnicodeForKeyEvent
        Required parameters:
        -->     kEventParamTextInputSendComponentInstance           typeComponentInstance
        -->     kEventParamTextInputSendRefCon                      typeLongInteger
        -->     kEventParamTextInputSendSLRec                       typeIntlWritingCode
        -->     kEventParamTextInputSendText                        typeUnicodeText
        -->     kEventParamTextInputSendKeyboardEvent               typeEventRef
                    (This parameter is the original raw keyboard event that produced the
                     text.  It enables access to kEventParamKeyModifiers and 
                     kEventParamKeyCode parameters.
                     You can also extract from this event either Unicodes or Mac encoding
                     characters as follows:
                            kEventParamKeyUnicodes              typeUnicodeText
                            kEventParamKeyMacCharCodes          typeChar (if available)
                     The kEventParamKeyUnicodes parameter of the raw keyboard event is
                     identical to the TextInput event's kEventParamTextInputSendText
                     parameter.  Note that when contents of TSM's bottom-line input
                     window (i.e. during typing Chinese, Korean, or Japanese) are confirmed,
                     the raw keyboard event's keyCode and modifiers are set to default values.)
    */

    /* Get the actual keyboard event */
    err = GetEventParameter (event, kEventParamTextInputSendKeyboardEvent,
            typeEventRef, NULL, sizeof(EventRef), NULL, &actualEvent);
    /* Get the actual data size */
    err = GetEventParameter (event, kEventParamTextInputSendText,
            typeUnicodeText, NULL, 0, &actualSize, NULL);

    /* Get the actual character data */
    uniCharBuf = uniCharBufPtr = malloc(actualSize);
    err = GetEventParameter (actualEvent, kEventParamKeyUnicodes,
            typeUnicodeText, NULL, actualSize, NULL, uniCharBuf);
                            
    err = GetEventParameter (event, kEventParamTextInputSendComponentInstance,
            typeComponentInstance, NULL, sizeof(UInt32), NULL, &textEntryServices);

	err = GetEventParameter( actualEvent, kEventParamKeyCode, 
			typeUInt32, NULL, sizeof(UInt32), NULL, &macKeyCode); 

	err = GetEventParameter( actualEvent, kEventParamKeyMacCharCodes, 
			typeChar, NULL, sizeof(char), NULL, &mackeycodeFromCarbon);


    modifiedUniChar = *uniCharBufPtr;
    buttonState = modifierBits =ModifierStateCarbon(actualEvent); //Capture option states
    if (((modifierBits >> 3) & 0x9) == 0x9) {  /* command and shift */
            if ((modifiedUniChar >= 97) && (modifiedUniChar <= 122)) {
                    /* convert ascii code of command-shift-letter to upper case */
                    modifiedUniChar = modifiedUniChar - 32;
            }
    }

	modifierBits = modifierBits >> 3;
    pthread_mutex_lock(&gEventQueueLock);
    
    /* Put sqKeyboardEvent in actualSize times */
    uniCharCount = actualSize / sizeof(UniChar);
	keyIndex = indexInKeyMap(macKeyCode);
	ISawRawKeyRepeat = findRepeatInKeyMap(macKeyCode);
	if (keyIndex >= 0)
		keyMap[keyIndex].keyChar = modifiedUniChar;

    for (i=0; i<uniCharCount; i++) {
        CFStringRef theString;
        unsigned char macRomanString[2];
        int macRomanCode;
        
        theString = CFStringCreateWithCharacters (nil, &modifiedUniChar, (CFIndex) 1);
        CFStringGetCString (theString,(char *)&macRomanString,2, kCFStringEncodingMacRoman);
        macRomanCode = macRomanString[0];
        CFRelease(theString);
        
       /* Put the sqKeyboardEvent for KeyDown */
		enterKeystroke ( EventTypeKeyboard, macKeyCode, EventKeyDown, 0, modifierBits);
		
        /* generate extra character event */
		enterKeystroke ( EventTypeKeyboard, macRomanCode, EventKeyChar, modifiedUniChar, modifierBits);
        
    /* Put the sqKeyboardEvent for KeyUp */
		if (!ISawRawKeyRepeat && (uniCharCount> 1 || (keyIndex < 0)))
			enterKeystroke ( EventTypeKeyboard, macKeyCode, EventKeyUp, 0,  modifierBits);
        
        uniCharBufPtr++;
        modifiedUniChar = *uniCharBufPtr;
    }

    free(uniCharBuf);
    pthread_mutex_unlock(&gEventQueueLock);		        
    signalAnyInterestedParties();
}


static int MouseModifierStateCarbon(EventRef event,UInt32 whatHappened) {
/* On a two- or three-button mouse, the left button is normally considered primary and the 
right button secondary, 
but left-handed users can reverse these settings as a matter of preference. 
The middle button on a three-button mouse is always the tertiary button. '

But mapping assumes 1,2,3  red, yellow, blue
*/
	extern long gSqueakMouseMappings[4][4];
	long stButtons = 0,modifier,mappedButton;
	UInt32 keyBoardModifiers=0;
	EventMouseButton mouseButton=0;
	OSErr err;
	static long buttonState[4] = {0,0,0,0};

	err = GetEventParameter( event,
                                kEventParamKeyModifiers,
                                typeUInt32,
                                NULL,
                                sizeof(UInt32),
                                NULL,
                                &keyBoardModifiers); 
								
  	if (whatHappened != kEventMouseMoved && whatHappened != kEventMouseWheelMoved) {
		err = GetEventParameter( event,
                                kEventParamMouseButton,
                                typeMouseButton,
                                NULL,
                                sizeof(EventMouseButton),
                                NULL,
                                &mouseButton); 
							
	//fprintf(stderr,"VM: MouseModifierStateCarbon buttonState %i modifiers %i\n ",mouseButton,keyBoardModifiers);
 
		         if (mouseButton > 0 && mouseButton < 4) {
          /* OLD original carbon code 
			buttonState[mouseButton] = (whatHappened == kEventMouseUp) ? 0 : 1;
            stButtons |= buttonState[1]*4*
                        (!((keyBoardModifiers & optionKey) || (keyBoardModifiers & cmdKey)));
            stButtons |= buttonState[1]*((keyBoardModifiers & optionKey)> 0)*2;
            stButtons |= buttonState[1]*((keyBoardModifiers & cmdKey)> 0)*1;
            stButtons |= buttonState[2]*1;
            stButtons |= buttonState[3]*2; */
			
			modifier = 0;
			if (keyBoardModifiers & cmdKey)
				modifier = 1;
			if (keyBoardModifiers & optionKey)
				modifier = 2;
			if (keyBoardModifiers & controlKey)
				modifier = 3;
				
			mappedButton = gSqueakMouseMappings[modifier][mouseButton];
			buttonState[mappedButton] = (whatHappened == kEventMouseUp) ? 0 : 1;
			stButtons |= mappedButton == 1 ? (buttonState[mappedButton] ? RedButtonBit : 0) : 0;
			stButtons |= mappedButton == 2 ? (buttonState[mappedButton] ? YellowButtonBit : 0) : 0;
			stButtons |= mappedButton == 3 ? (buttonState[mappedButton] ? BlueButtonBit : 0)  : 0;
		}
	}
	
	// button state: low three bits are mouse buttons; next 8 bits are modifier bits
	return ((modifierMap[((keyBoardModifiers & 0xFFFF) >> 8)] << 3) | (stButtons & 0x7));

}

static int ModifierStateCarbon(EventRef event) {
        UInt32 keyBoardModifiers=0;
        OSErr err;
        
	err = GetEventParameter( event,
                                kEventParamKeyModifiers,
                                typeUInt32,
                                NULL,
                                sizeof(UInt32),
                                NULL,
                                &keyBoardModifiers); 
 	/* button state: low three bits are mouse buttons; next 8 bits are modifier bits */
	return ((modifierMap[((keyBoardModifiers & 0xFFFF) >> 8)] << 3));
}


static void doPendingFlush(void) {

	extern  Boolean gSqueakUIFlushUseHighPercisionClock;
	extern	long	gSqueakUIFlushSecondaryCleanupDelayMilliseconds,gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds;
	static int lastTick = 0;
	static int nextPollTick = 0;
	int now = gSqueakUIFlushUseHighPercisionClock ? ioMSecs(): ioLowResMSecs();
	int delta = now - lastTick;
		
	if ((delta >= gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds) || (delta < 0))  {
		windowDescriptorBlock *windowBlock;
		int i;
		
		for(i=1;i<=getCurrentIndexInUse();i++) {
			windowBlock = windowBlockFromIndex(i);
			if ((windowBlock) && (windowBlock->dirty) ) {
				delta = now - windowBlock->rememberTicker;
				if ((delta >= gSqueakUIFlushSecondaryCleanupDelayMilliseconds) || (delta < 0))  {
					CGContextFlush(windowBlock->context);
					windowBlock-> dirty = 0;
					windowBlock->rememberTicker = now =  gSqueakUIFlushUseHighPercisionClock ? ioMSecs(): ioLowResMSecs();
				}
			}
		}
		lastTick = now;
	} 

	if (ioLowResMSecs() != nextPollTick) {
		EventRef event;
		static EventTargetRef target = NULL;
		
		if (target == NULL)
			target = GetEventDispatcherTarget();
	  
		if (ReceiveNextEvent(0, NULL, kEventDurationNoWait, true, &event) == noErr) {
			SendEventToEventTarget (event, target);
			ReleaseEvent(event);
		}
		nextPollTick = ioLowResMSecs();
	}

}

int ioProcessEvents(void) {

	aioPoll(0);		
	doPendingFlush();
    if (gQuitNowRightNow) {
        ioExit();  //This might not return, might call exittoshell
        QuitApplicationEventLoop();
        pthread_exit(null);
    }
	return 0;
}

int getUIToLock(long *data) {
	customHandleForUILocks(NULL,NULL,(void*) data);
	return 0;
}

static pascal OSStatus customHandleForUILocks(EventHandlerCallRef myHandler,
            EventRef event, void* userData)
{
    long *data;
    long numberOfParms;
    OSErr	err;
        
         
	data = userData;
		    
    numberOfParms = data[0];
    
    if (0 == numberOfParms)
        data[2] = ((int (*) (void)) data[1]) ();
    if (1 == numberOfParms)
        data[3] = ((int (*) (long)) data[1]) (data[2]);
    if (2 == numberOfParms)
        data[4] = ((int (*) (long,long)) data[1]) (data[2],data[3]);
    if (3 == numberOfParms)
        data[5] = ((int (*) (long,long,long)) data[1]) (data[2],data[3],data[4]);
    if (4 == numberOfParms)
        data[6] = ((int (*) (long,long,long,long)) data[1]) (data[2],data[3],data[4],data[5]);
    if (5 == numberOfParms)
        data[7] = ((int (*) (long,long,long,long,long)) data[1]) (data[2],data[3],data[4],data[5],data[6]);
    if (6 == numberOfParms)
        data[8] = ((int (*) (long,long,long,long,long,long)) data[1]) (data[2],data[3],data[4],data[5],data[6], data[7]);

    return noErr;
}

void signalAnyInterestedParties() {
    if (inputSemaphoreIndex != 0)
        signalSemaphoreWithIndex(inputSemaphoreIndex);
}

static EventHandlerUPP gEventLoopEventHandlerUPP;   // -> EventLoopEventHandler

static pascal OSStatus EventLoopEventHandler(EventHandlerCallRef inHandlerCallRef,
                                             EventRef inEvent, void *inUserData)
    // This code contains the standard Carbon event dispatch loop,
    // as per "Inside Macintosh: Handling Carbon Events", Listing 3-10,
{
        // Run our event loop until quitNow is set.
	SetUpCarbonEvent();
	interpret(); //Note the application under carbon event mgr starts running here
	return 0;
 }


void RunApplicationEventLoopWithSqueak(void)
    // A reimplementation of RunApplicationEventLoop that supports
    // yielding time to cooperative threads.  It relies on the
    // rest of your application to maintain a global variable,
    // gNumberOfRunningThreads, that reflects the number of threads
    // that are ready to run.
{
    static const EventTypeSpec eventSpec = {'JMM2', 'JMM2' };
    OSStatus        err;
    OSStatus        junk;
    EventHandlerRef installedHandler;
    EventRef        dummyEvent;


    dummyEvent = nil;

    // Create a UPP for EventLoopEventHandler and QuitEventHandler
    // (if we haven't already done so).

    err = noErr;
    if (gEventLoopEventHandlerUPP == nil) {
        gEventLoopEventHandlerUPP = NewEventHandlerUPP(EventLoopEventHandler);
    }
    if (gEventLoopEventHandlerUPP == nil) {
        err = memFullErr;
    }

    // Install EventLoopEventHandler, create a dummy event and post it,
    // and then call RunApplicationEventLoop.  The rationale for this
    // is as follows:  We want to unravel RunApplicationEventLoop so
    // that we can can yield to cooperative threads.  In fact, the
    // core code for RunApplicationEventLoop is pretty easy (you
    // can see it above in EventLoopEventHandler).  However, if you
    // just execute this code you miss out on all the standard event
    // handlers.  These are relatively easy to reproduce (handling
    // the quit event and so on), but doing so is a pain because
    // a) it requires a bunch boilerplate code, and b) if Apple
    // extends the list of standard event handlers, your application
    // wouldn't benefit.  So, we execute our event loop from within
    // a Carbon event handler that we cause to be executed by
    // explicitly posting an event to our event loop.  Thus, the
    // standard event handlers are installed while our event loop runs.

    if (err == noErr) {
        err = InstallEventHandler(GetApplicationEventTarget(), gEventLoopEventHandlerUPP,
                                  1, &eventSpec, nil, &installedHandler);
        if (err == noErr) {
            err = MacCreateEvent(nil, 'JMM2', 'JMM2', GetCurrentEventTime(),
                                  kEventAttributeNone, &dummyEvent);
            if (err == noErr) {
                err = PostEventToQueue(GetMainEventQueue(), dummyEvent,
                                  kEventPriorityHigh);
            }
            if (err == noErr) {
                RunApplicationEventLoop();
            }

            junk = RemoveEventHandler(installedHandler);
        }
    }

    // Clean up.

    if (dummyEvent != nil) {
        ReleaseEvent(dummyEvent);
    }
}

static sqKeyboardEvent *enterKeystroke (long type, long cc, long pc, UniChar utf32Code, long m) {
	sqKeyboardEvent 	*evt;
	evt = (sqKeyboardEvent*) nextEventPut();

	/* first the basics */
	//fprintf(stdout,"\nKeyStroke time %i Type %i Value %i",ioMSecs(),pc,cc);
	evt->type = type;
	evt->timeStamp = ioMSecs() & MillisecondClockMask;
	/* now the key code */
	/* press code must differentiate */
	evt->charCode = cc;
	evt->pressCode = pc;
	evt->modifiers = m;
	evt->windowIndex = windowActive;
	evt->utf32Code = 0;
	if(pc == EventKeyChar) {
		evt->utf32Code = utf32Code;
		if (!inputSemaphoreIndex) {
			int  keystate;

			/* keystate: low byte is the ascii character; next 8 bits are modifier bits */
				keystate = (evt->modifiers << 8) | (unsigned char)  ((char) cc);
			if (keystate == getInterruptKeycode()) {
					/* Note: interrupt key is "meta"; it not reported as a keystroke */
					setInterruptPending(true);
					setInterruptCheckCounter(0);
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
	}
	return evt;
}


static int addToKeyMap(int keyCode, int keyChar)
{
  //fprintf(stdout, "\nAddToKeyMap T %i c %i i %i",ioMSecs(),keyCode,keyMapSize);
  if (keyMapSize > KeyMapSize) { fprintf(stderr, "keymap overflow\n");  return -1; }
  keyMap[keyMapSize++]= (KeyMapping){ keyCode, keyChar, 0};
  return keyChar;
}

static int indexInKeyMap(int keyCode)
{
  int i;
  for (i= 0;  i < keyMapSize;  ++i)
    if (keyMap[i].keyCode == keyCode)
      return i;
  return -1;
}

static int findInKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  return (idx != -1) ? keyMap[idx].keyChar : -1;
}

static int findRepeatInKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  return (idx != -1) ? keyMap[idx].keyRepeated : 0;
}

static void setRepeatInKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  if (idx != -1) keyMap[idx].keyRepeated = 1;
}

static int removeFromKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  int keyChar= -1;
  //fprintf(stdout, "\nremoveFromKeyMap T %i c %i i %i",ioMSecs(),keyCode,keyMapSize-1);
  if (idx == -1) { //fprintf(stderr, "keymap underflow\n");  
		return -1; }
  keyChar= keyMap[idx].keyChar;
  for (; idx < keyMapSize - 1;  ++idx)
    keyMap[idx]= keyMap[idx + 1];
  --keyMapSize;
  return keyChar;
}
