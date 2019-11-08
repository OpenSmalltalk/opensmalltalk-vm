/****************************************************************************
*   PROJECT: Mac event interface.
*   FILE:    sqMacUIEventsUniversal.c
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
 3.8.14b4 Nov 17th, 2006 JMM fix issue with mouse location and pre 3.0 (input semaphore driven) squeak images
 3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
 3.8.15b5	Mar 10th, 2007 JMM check on menu item quit
 3.8.17b5	May 1st, 2007 JMM set tracking on bounds changed, not resize complete (which doesn't see the use of maximum button)

 notes: IsUserCancelEventRef

*****************************************************************************/


#include "sq.h"
#include "sqMacUIEvents.h"
#include "sqMacUIMenuBar.h"
#include "sqMacWindow.h"
#include "sqMacHostWindow.h"
#include "sqMacTime.h"
#include "sqMacNSPluginUILogic2.h"
#include "nsPoolManagement.h"

#include <pthread.h>
#include "sqaio.h"

#if TARGET_API_MAC_CARBON
#include <Carbon/Carbon.h>
#else
#include <Quickdraw.h>
#endif

#include <unistd.h>

enum { KeyMapSize= 32 };

typedef struct {
  int keyCode;
  long keyChar;
  int keyRepeated;
} KeyMapping;

extern int gSqueakDebug;
pthread_mutex_t gEventQueueLock;

# define DPRINTF(ARGS) if (gSqueakDebug) fprintf ARGS

#define EventTypeFullScreenUpdate 98
#define EventTypePostEventProcessing 99
static void doPostMessageHook(EventRef event);
void postFullScreenUpdate(void);
void signalAnyInterestedParties(void);
static sqKeyboardEvent *enterKeystroke (long type, long cc, long pc, UniChar utf32Char, long m);

static int addToKeyMap(int keyCode, UniChar keyChar);
static UniChar findInKeyMap(int keyCode);
static int removeFromKeyMap(int keyCode);
static int indexInKeyMap(int keyCode);
static int findRepeatInKeyMap(int keyCode);
static void setRepeatInKeyMap(int keyCode);

static void doPendingFlush(void);
void ignoreLastEvent(void);
void sqRevealWindowAndHandleQuit () ;

/*** Variables -- Event Recording ***/
#define MAX_EVENT_BUFFER 1024

extern int getInterruptKeycode();
extern int setInterruptPending(int value);
extern int getFullScreenFlag();
extern struct VirtualMachine* interpreterProxy;
extern Boolean gSqueakHeadless;
extern void SetCursorBackToSomething(void);


static KeyMapping keyMap[KeyMapSize];
static int keyMapSize=	   0;
Boolean gQuitNowRightNow=false;
Boolean NeedToSetCursorBackOnApplicationActivate = false;

extern MenuHandle editMenu;
extern MenuHandle appleMenu;

static sqInputEvent eventBuffer[MAX_EVENT_BUFFER];
static int eventBufferGet = 0;
static int eventBufferPut = 0;
static Boolean NeedToSetCursorBack=false;


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
static Point carbonMousePosition;	/* mouse position when carbon is running for squeak 2.8 images */

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

int
recordDragDropEvent(EventRecord *theEvent, int numberOfItems, int dragType)
{
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
	return 1;
}

int
MouseModifierState(EventRecord *theEvent)
{
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


sqInputEvent *
nextEventPut(void)
{
	sqInputEvent *evt = eventBuffer + eventBufferPut;
	eventBufferPut = (eventBufferPut + 1) % MAX_EVENT_BUFFER;
	if (eventBufferGet == eventBufferPut)
		/* buffer overflow; drop the last event */
		eventBufferGet = (eventBufferGet + 1) % MAX_EVENT_BUFFER;
	return evt;
}

void
ignoreLastEvent()
{
    eventBufferPut -= 1;
    if (eventBufferPut < 0)
        eventBufferPut = MAX_EVENT_BUFFER -1;
}

sqInt
ioSetInputSemaphore(sqInt semaIndex)
{
	inputSemaphoreIndex = semaIndex;
	return 1;
}

sqInt
ioGetNextEvent(sqInputEvent *evt)
{
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
        evt->unused1 = NULL;
		return ioGetNextEvent(evt);
	}
	return true;
}

sqInt
ioGetButtonState(void)
{
	ioProcessEvents();
	if ((cachedButtonState & 0x7) != 0) {
		int result = cachedButtonState;
		cachedButtonState = 0;  /* clear cached button state */
		return result;
	}
	cachedButtonState = 0;  /* clear cached button state */
	return buttonState;
}

sqInt
ioGetKeystroke(void)
{
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

sqInt
ioMousePoint(void)
{
	Point p;

	    ioProcessEvents();
	if (windowActive) {
		p = carbonMousePosition;
	} else {
		/* don't report mouse motion if window is not active */
		p = savedMousePosition;
	}
	return (p.h << 16) | (p.v & 0xFFFF);  /* x is high 16 bits; y is low 16 bits */
}

sqInt
ioPeekKeystroke(void)
{
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

void
setMessageHook(eventMessageHook theHook) { messageHook = theHook; }

void
setPostMessageHook(eventMessageHook theHook) { postMessageHook = theHook; }

Boolean
IsKeyDown() { interpreterProxy->success(false); return null; }

extern MenuHandle fileMenu, editMenu;

static EventTypeSpec appEventCmdList[] = {
					{kEventClassCommand, kEventCommandProcess}
};

static EventTypeSpec appEventList[] = {
					{kEventClassApplication, kEventAppActivated},
					{kEventClassApplication, kEventAppDeactivated}
};

static EventTypeSpec windEventList[] = {
#if !_LP64
					{ kEventClassWindow, kEventWindowDrawContent },
#endif
					{ kEventClassWindow, kEventWindowHidden },
					{ kEventClassWindow, kEventWindowActivated},
					{ kEventClassWindow, kEventWindowBoundsChanged},
					{ kEventClassWindow, kEventWindowResizeStarted},
					{ kEventClassWindow, kEventWindowResizeCompleted},
					{ kEventClassWindow, kEventWindowClose},
					{ kEventClassWindow, kEventWindowCollapsed},
					{ kEventClassWindow, kEventWindowDeactivated}
};

static EventTypeSpec windEventMouseList[] = {
					{ kEventClassMouse, kEventMouseMoved},
					{ kEventClassMouse, kEventMouseWheelMoved},
					{ kEventClassMouse, kEventMouseDragged},
					{ kEventClassMouse, kEventMouseUp},
					{ kEventClassMouse, kEventMouseDown},
					{ kEventClassMouse, kEventMouseEntered },
					{ kEventClassMouse, kEventMouseExited }
};

static EventTypeSpec windEventKBList[] = {
					{ kEventClassKeyboard, kEventRawKeyDown},
					{ kEventClassKeyboard, kEventRawKeyUp},
					{ kEventClassKeyboard, kEventRawKeyRepeat},
					{ kEventClassKeyboard, kEventRawKeyModifiersChanged}
};


static EventTypeSpec appleEventEventList[] = {
					{ kEventClassAppleEvent, kEventAppleEvent}
};

static EventTypeSpec textInputEventList[] = {
					{ kEventClassTextInput, kEventTextInputUnicodeForKeyEvent}
};

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
void recordMouseEventCarbon(EventRef event,UInt32 whatHappened,Boolean noPointConversion);
static void recordKeyboardEventCarbon(EventRef event);
static void recordMenuEventCarbon(MenuRef menu, UInt32 menuItem);
static void recordWindowEventCarbon(int windowType,int left, int top, int right, int bottom,int windowIndex);
static int doPreMessageHook(EventRef event);
static void fakeMouseWheelKeyboardEvents(EventMouseWheelAxis wheelMouseDirection,long wheelMouseDelta);

void
SetUpCarbonEvent()
{
	if (!gSqueakHeadless) AdjustMenus();

/* Installing the application event handler */
	InstallApplicationEventHandler(NewEventHandlerUPP(MyAppEventCmdHandler), GetEventTypeCount(appEventCmdList), appEventCmdList, 0, NULL);
    InstallApplicationEventHandler(NewEventHandlerUPP(MyAppEventHandler), GetEventTypeCount(appEventList), appEventList, 0, NULL);

}

void
SetUpCarbonEventForWindowIndex(sqInt index)
{
/* Installing the window event handler */
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyWindowEventHandler), GetEventTypeCount(windEventList), windEventList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyWindowEventMouseHandler), GetEventTypeCount(windEventMouseList), windEventMouseList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyWindowEventKBHandler), GetEventTypeCount(windEventKBList), windEventKBList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyAppleEventEventHandler), GetEventTypeCount(appleEventEventList), appleEventEventList, 0, NULL);
    InstallWindowEventHandler(windowHandleFromIndex(index), NewEventHandlerUPP(MyTextInputEventHandler), GetEventTypeCount(textInputEventList), textInputEventList, 0, NULL);
	setWindowTrackingRgn(index);
}

static int
doPreMessageHook(EventRef event)
{
#pragma unused(event)
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

static void
doPostMessageHook(EventRef event)
{
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

void
postFullScreenUpdate()
{
    sqInputEvent *evt;

    pthread_mutex_lock(&gEventQueueLock);
    evt = nextEventPut();
    evt->type = EventTypeFullScreenUpdate;
	evt->windowIndex = windowActive;
    pthread_mutex_unlock(&gEventQueueLock);
}

static pascal OSStatus
MyAppEventHandler (EventHandlerCallRef myHandlerChain,
					EventRef event, void* userData)
{
#pragma unused(myHandlerChain,userData)
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
    extern Boolean gSqueakWindowIsFloating;
	extern Boolean gSqueakHasCursor;

    if (messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;

    whatHappened = GetEventKind(event);

	//fprintf(stderr,"\nAppEvent %i",whatHappened); fflush(stdout);
    switch (whatHappened)
    {
        case kEventAppActivated: {
			if ((!gSqueakHeadless || browserActiveAndDrawingContextOkAndInFullScreenMode()) && NeedToSetCursorBack) {
				NeedToSetCursorBackOnApplicationActivate = true;
				NeedToSetCursorBack = false;
				gSqueakHasCursor = true;
			}
			}
             break;
        case kEventAppDeactivated: {
            if (gSqueakWindowIsFloating) break;
			InitCursor();
			if ((!gSqueakHeadless || browserActiveAndDrawingContextOkAndInFullScreenMode()) && gSqueakHasCursor) {
				gSqueakHasCursor = false;
				NeedToSetCursorBack = true;
			}
			windowActive = 0;
			}
            break;
        default:
            break;
    }
    if (postMessageHook)
        doPostMessageHook(event);
    return result;
}

static pascal OSStatus
MyAppEventCmdHandler (EventHandlerCallRef myHandlerChain,
						EventRef event, void* userData)
{
#pragma unused(myHandlerChain,userData)
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
				Str255  itemString;
				char	cString[256];
				GetMenuItemText(commandStruct.menu.menuRef,commandStruct.menu.menuItemIndex,itemString);
				CopyPascalStringToC((unsigned char *)itemString,cString);
				if (strcmp(cString, "Quit Without Saving") == 0)
					gQuitNowRightNow = true;
				else {
					sqRevealWindowAndHandleQuit ();
				}
				result = noErr;
			} else if (commandStruct.commandID == kHICommandHide) {
			} else if (commandStruct.commandID == kHICommandQuit) {
				sqRevealWindowAndHandleQuit ();
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

static pascal OSStatus
MyWindowEventHandler(EventHandlerCallRef myHandler,
						EventRef event, void* userData)
{
#pragma unused(myHandler,userData)
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
    extern Boolean gSqueakWindowIsFloating;
	Rect globalBounds;
    WindowRef window;

    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;
    GetEventParameter(event, kEventParamDirectObject, typeWindowRef, NULL,sizeof(window), NULL, &window);
    whatHappened = GetEventKind(event);
	//fprintf(stderr,"\nWindowEvent %i %i %i",whatHappened,IsWindowActive(window),windowIndexFromHandle((int)window)); fflush(stdout);
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
				QDGlobalToLocalPoint(GetWindowPort((wHandleType)window),&savedMousePosition);
			}
            windowActive = 0;
             break;
#if !_LP64
       case kEventWindowDrawContent:
            result = noErr;
            break;
#endif
       case kEventWindowResizeStarted:
			{
				windowDescriptorBlock *targetWindowBlock;
				targetWindowBlock = windowBlockFromHandle((wHandleType)window);
				targetWindowBlock->sync = true;
			}
            break;
       case kEventWindowResizeCompleted:
            break;
		case kEventWindowBoundsChanged: {
			setWindowTrackingRgn(windowIndexFromHandle((wHandleType)window));
			GetWindowBounds(window,kWindowContentRgn,&globalBounds);
			recordWindowEventCarbon(WindowEventMetricChange,globalBounds.left, globalBounds.top,
					globalBounds.right, globalBounds.bottom,windowIndexFromHandle((wHandleType)window));
			}
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

int amIOSX102X(void);

int amIOSX102X() {
	static int amI102=-1;
	if (amI102 == -1) {
		long version;
		Gestalt(gestaltSystemVersion, &version);
		if (version < 0x1030)
			amI102 = 1;
		else
			amI102 = 0;
	}
	return amI102;
}

static pascal OSStatus
MyWindowEventMouseHandler(EventHandlerCallRef myHandler,
							EventRef event, void* userData)
{
#pragma unused(myHandler,userData)
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
	OSStatus crosscheckForErrors;
 	static Boolean mouseDownActivate=false;
    extern Boolean gSqueakWindowIsFloating,gSqueakFloatingWindowGetsFocus;
    WindowPartCode windowPartCode;
    Point  mouseLocation;
	static RgnHandle	ioWinRgn=null;
    whatHappened	= GetEventKind(event);


//	if (whatHappened != 5)
//		fprintf(stderr,"\nMouseEvent %i-%i ",whatHappened,windowActive); fflush(stdout);

	if (!windowActive) {
		if (whatHappened == kEventMouseDown)
			mouseDownActivate = true;
        return result;
	}

    switch (whatHappened)
    {
			case kEventMouseEntered: {
				extern Boolean gSqueakHasCursor;
				if ((!gSqueakHeadless  || browserActiveAndDrawingContextOkAndInFullScreenMode()) && gSqueakHasCursor && NeedToSetCursorBack) {
					SetCursorBackToSomething();
					NeedToSetCursorBack = false;
				}
			}
			break;
		case kEventMouseExited: {
				extern Boolean gSqueakHasCursor;
				if ((!gSqueakHeadless  || browserActiveAndDrawingContextOkAndInFullScreenMode()) && gSqueakHasCursor) {
					InitCursor();
					NeedToSetCursorBack = true;
				}
				}
			break;
        default:
        /* If nobody handled the event */
        break;
    }

	if (amIOSX102X()) {
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
	} else {
		crosscheckForErrors = GetEventParameter (event, kEventParamWindowPartCode, typeWindowPartCode,NULL,sizeof(WindowPartCode), NULL, &windowPartCode);
		if (windowPartCode < 3) {
			if (mouseDownActivate && whatHappened == kEventMouseUp) {
				mouseDownActivate = false;
				return result;
			}
			if (!gButtonIsDown)
				return result;
		}
	}

    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;

    switch (whatHappened)
    {
        case kEventMouseMoved:
        case kEventMouseDragged:
        case kEventMouseWheelMoved:
			if (mouseDownActivate)
				return result;
            recordMouseEventCarbon(event,whatHappened,false);
            result = noErr;
            return result; //Return early not an event we deal with for post event logic
        case kEventMouseDown:
			if (amIOSX102X()) {
				GetWindowRegion(windowHandleFromIndex(windowActive),kWindowGrowRgn,ioWinRgn);
				if (PtInRgn(mouseLocation,ioWinRgn))
					return result;
			} else {
				if (windowPartCode != inContent)
					return result;
			}
			if (mouseDownActivate)
				return result;
            if (gSqueakFloatingWindowGetsFocus && gSqueakWindowIsFloating) {
                SetUserFocusWindow(kUserFocusAuto);
                SetUserFocusWindow(windowHandleFromIndex(windowActive));
            }
            gButtonIsDown = true;
            recordMouseEventCarbon(event,whatHappened,false);
            result = noErr;
            break;
        case kEventMouseUp:
			if (mouseDownActivate) {
				mouseDownActivate = false;
				return result;
			}
            gButtonIsDown = false;
            recordMouseEventCarbon(event,whatHappened,false);
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


static TISInputSourceRef currentKeyboard = (TISInputSourceRef)-1;
static UCKeyboardLayout *currentKeyboardLayout;

static UCKeyboardLayout *
getKeyboardLayout()
{
	TISInputSourceRef kbdNow = TISCopyCurrentKeyboardInputSource();

	if (currentKeyboard != kbdNow) {
		KeyboardLayoutRef keyLayout;
		SInt32  keyLayoutKind;
		CFDataRef uchr = (CFDataRef)TISGetInputSourceProperty
										(kbdNow,
										 kTISPropertyUnicodeKeyLayoutData);
		currentKeyboard = kbdNow;
		currentKeyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(uchr);
		KLGetCurrentKeyboardLayout(&keyLayout);
		KLGetKeyboardLayoutProperty(keyLayout, kKLKind, (const void **)&keyLayoutKind);
		//printf("\nKbd: %ld kind: %ld kKLKCHRKind %ld",
		//		kbdNow, keyLayoutKind, kKLKCHRKind); fflush(stdout);
	}
	return currentKeyboardLayout;
}

static UniChar
shiftedUnicodeForEvent(EventRef event, UInt32 keyCode)
{
#define MaxStringLength 4
	UInt32 deadKeyState = 0;
	UInt32 keyboardType;
	UniCharCount actualStringLength = 0;
	UniChar unicodeString[MaxStringLength];
    OSStatus result;

	GetEventParameter(event, kEventParamKeyboardType, typeUInt32, NULL,
					  sizeof(keyboardType), NULL, &keyboardType);
	result = UCKeyTranslate(getKeyboardLayout(),
							keyCode, kUCKeyActionDown,
							/* Only interested in the shift state, and
							 * UCKeyTranslate uses old-style Carbon modifiers. */
							ModifierStateCarbon(event) & 8
								? 1 << (shiftKeyBit - 8)
								: 0,
							keyboardType, 0,
							&deadKeyState,
							MaxStringLength,
							&actualStringLength, unicodeString);
	return result == noErr ? unicodeString[0] : 0;
}
#undef MaxStringLength

static pascal OSStatus
MyWindowEventKBHandler(EventHandlerCallRef myHandler,
						EventRef event, void* userData)
{
#pragma unused(myHandler,userData)
    UInt32 whatHappened,keyCode,keyChar;
    OSStatus result = eventNotHandledErr; /* report failure by default */

    if (!windowActive)
        return result;

    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;

    whatHappened = GetEventKind(event);
	GetEventParameter (event, kEventParamKeyCode, typeUInt32,NULL, sizeof(typeUInt32), NULL, &keyCode);
	/* See UCKeyTranslate in https://developer.apple.com/library/mac/#documentation/Carbon/reference/Unicode_Utilities_Ref/Reference/reference.html
	 * for how to convert an event to one or more Unicode characters. e.g.
	 * http://inquisitivecocoa.com/2009/04/05/key-code-translator/
	 */
    switch (whatHappened) {
        case kEventRawKeyDown: {
			//printf("\nrawkey down %i ",ioMSecs()); fflush(stdout);
			//This will work, but this appears unused. */
			//addToKeyMap(keyCode, shiftedUnicodeForEvent(event,keyCode));
			addToKeyMap(keyCode, 0);
            result = eventNotHandledErr;
            break;
		}
        case kEventRawKeyRepeat:
			//fprintf(stdout,"\nrawkey repeat %i",ioMSecs()); fflush(stdout);
			setRepeatInKeyMap(keyCode);
            result = eventNotHandledErr;
            break;
        case kEventRawKeyUp: {
			UniChar key;
			//fprintf(stdout,"\nrawkey up %i",ioMSecs()); fflush(stdout);
			if ((key = findInKeyMap(keyCode)) != (UniChar)-1)
				enterKeystroke(EventTypeKeyboard, keyCode, EventKeyUp,
								key, ModifierStateCarbon(event));
			removeFromKeyMap(keyCode);
            result = eventNotHandledErr;
            break;
		}
        case kEventRawKeyModifiersChanged:
            /* ok in this case we fake a mouse event to deal with the modifiers changing */
            if(inputSemaphoreIndex)
                recordMouseEventCarbon(event,kEventMouseMoved,false);
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

static pascal OSStatus
MyAppleEventEventHandler(EventHandlerCallRef myHandler,
							EventRef event, void* userData)
{
#pragma unused(myHandler,userData,event)
    return eventNotHandledErr;
}

static pascal OSStatus
MyTextInputEventHandler(EventHandlerCallRef myHandler,
						EventRef event, void* userData)
{
#pragma unused(myHandler,userData)
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

static void
recordMenuEventCarbon(MenuRef menu,UInt32 menuItem)
{
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

static void
recordWindowEventCarbon(int windowType,int left, int top, int right, int bottom, int windowIndex)
{
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

void
recordMouseEventCarbon(EventRef event,UInt32 whatHappened,Boolean noPointConversion)
{
	sqMouseEvent *evt;
	static sqMouseEvent oldEvent;
	static Point  where;
	EventMouseWheelAxis wheelMouseDirection=0;
	long	wheelMouseDelta=0;
	OSErr		err;

	err = GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,
				sizeof(Point), NULL, &where);

 	if (err == noErr && !noPointConversion && windowHandleFromIndex(windowActive))
		QDGlobalToLocalPoint(GetWindowPort(windowHandleFromIndex(windowActive)),&where);
	// on error use last known mouse location.
	carbonMousePosition = where;

	buttonState = MouseModifierStateCarbon(event,whatHappened);
 	cachedButtonState = cachedButtonState | buttonState;


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
                                typeSInt32,
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

	if ((whatHappened == kEventMouseDown) || (whatHappened == kEventMouseUp))
        {
	       evt->nrClicks = 1;
               // Mac provides nrClicks directly
               GetEventParameter(
                       event,
                       kEventParamClickCount,
                       typeSInt32,
                       NULL,
                       sizeof(typeUInt32),
                       NULL,
                       &evt->nrClicks
               );
        } else {
                evt->nrClicks = 0;
        }

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

static void
fakeMouseWheelKeyboardEvents(EventMouseWheelAxis wheelMouseDirection,long wheelMouseDelta)
{
    long 	i,asciiChar;
    sqKeyboardEvent *evt,*extra;
    UInt32	macKeyCode=0;

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
	evt->utf32Code = 0;
#ifdef PharoVM
	evt->modifiers = modifierMap[((controlKey | optionKey | cmdKey | shiftKey) >> 8)];
#else
	evt->modifiers = modifierMap[(controlKey >> 8)];
#endif
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
	evt->utf32Code = 0;
	evt->modifiers = modifierMap[(controlKey >> 8)];
	evt->windowIndex = windowActive;
    }
    pthread_mutex_unlock(&gEventQueueLock);
    signalAnyInterestedParties();
}

static void
recordKeyboardEventCarbon(EventRef event)
{
    int				modifierBits, keyIndex,ISawRawKeyRepeat;
    UniCharCount	uniCharCount,i;
    UniChar			modifiedUniChar, *uniCharBufPtr, *uniCharBuf;
    OSErr			err;
    UInt32			actualSize,macKeyCode,textEntryServices;
    EventRef		actualEvent;
	char		mackeycodeFromCarbon;

    //  Tetsuya HAYASHI <tetha@st.rim.or.jp> supplied multiple unicode extraction

    /*  kEventTextInputUnicodeForKeyEvent
        Required parameters:
        -->     kEventParamTextInputSendComponentInstance           typeComponentInstance
        -->     kEventParamTextInputSendRefCon                      typeSInt32
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
		else { /* map potential punctuation character to shifted key. */
			if (!(modifiedUniChar = shiftedUnicodeForEvent(actualEvent,macKeyCode)))
				modifiedUniChar = *uniCharBufPtr; /* undo on error */
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


static int
MouseModifierStateCarbon(EventRef event,UInt32 whatHappened)
{
/* On a two- or three-button mouse, the left button is normally considered primary and the
right button secondary,
but left-handed users can reverse these settings as a matter of preference.
The middle button on a three-button mouse is always the tertiary button. '

But mapping assumes 1,2,3  red, yellow, blue
*/
	extern long gSqueakMouseMappings[4][4];
	extern long gSqueakBrowserMouseMappings[4][4];
	long stButtons,modifier,mappedButton;
	UInt32 keyBoardModifiers=0;
	EventMouseButton mouseButton=0;
	OSErr err;
	static long buttonStateBits[4] = {0,0,0,0};
	stButtons = buttonState;

	err = GetEventParameter( event,
                                kEventParamKeyModifiers,
                                typeUInt32,
                                NULL,
                                sizeof(UInt32),
                                NULL,
                                &keyBoardModifiers);

  	if (whatHappened != kEventMouseMoved && whatHappened != kEventMouseWheelMoved) {
		stButtons = 0;
		err = GetEventParameter( event,
                                kEventParamMouseButton,
                                typeMouseButton,
                                NULL,
                                sizeof(EventMouseButton),
                                NULL,
                                &mouseButton);

	DPRINTF((stderr,"VM: MouseModifierStateCarbon buttonStateBits %i modifiers %ui\n ",mouseButton,(unsigned int) keyBoardModifiers));

		         if (mouseButton > 0 && mouseButton < 4) {
          /* OLD original carbon code
			buttonStateBits[mouseButton] = (whatHappened == kEventMouseUp) ? 0 : 1;
            stButtons |= buttonStateBits[1]*4*
                        (!((keyBoardModifiers & optionKey) || (keyBoardModifiers & cmdKey)));
            stButtons |= buttonStateBits[1]*((keyBoardModifiers & optionKey)> 0)*2;
            stButtons |= buttonStateBits[1]*((keyBoardModifiers & cmdKey)> 0)*1;
            stButtons |= buttonStateBits[2]*1;
            stButtons |= buttonStateBits[3]*2; */

			modifier = 0;
			if (keyBoardModifiers & cmdKey)
				modifier = 1;
			if (keyBoardModifiers & optionKey)
				modifier = 2;
			if (keyBoardModifiers & controlKey)
				modifier = 3;

			if (browserActiveAndDrawingContextOkAndNOTInFullScreenMode())
					mappedButton = gSqueakBrowserMouseMappings[modifier][mouseButton];
				else
					mappedButton = gSqueakMouseMappings[modifier][mouseButton];
			buttonStateBits[mappedButton] = (whatHappened == kEventMouseUp) ? 0 : 1;
			stButtons |= mappedButton == 1 ? (buttonStateBits[mappedButton] ? RedButtonBit : 0) : 0;
			stButtons |= mappedButton == 2 ? (buttonStateBits[mappedButton] ? YellowButtonBit : 0) : 0;
			stButtons |= mappedButton == 3 ? (buttonStateBits[mappedButton] ? BlueButtonBit : 0)  : 0;
		}
	}

	// button state: low three bits are mouse buttons; next 8 bits are modifier bits
	return ((modifierMap[((keyBoardModifiers & 0xFFFF) >> 8)] << 3) | (stButtons & 0x7));

}

static int
ModifierStateCarbon(EventRef event)
{
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

static void
checkBrowserForHeartBeat(void)
{
	static int counter=0;
	if (counter++ > 200) {
		counter = 0;
		if (getppid() == 1)
			gQuitNowRightNow = 1;

	}

}

static void
doPendingFlush(void)
{
	extern  Boolean gSqueakBrowserSubProcess;
	extern	long	gSqueakUIFlushSecondaryCleanupDelayMilliseconds,gSqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds;
	static long lastTick = 0;
	static long nextPollTick = 0;
	long now = ioMSecs();
	long delta = now - lastTick;

	if (browserActiveAndDrawingContextOkAndInFullScreenMode() || (!gSqueakHeadless && !gSqueakBrowserSubProcess)) {
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
						windowBlock->rememberTicker = now = ioMSecs();
					}
				}
			}
			lastTick = now;
		}
	}

	if (ioMSecs() != nextPollTick) {
		EventRef event;
		static EventTargetRef target = NULL;

		if (target == NULL)
			target = GetEventDispatcherTarget();

		if (ReceiveNextEvent(0, NULL, kEventDurationNoWait, true, &event) == noErr) {
			SendEventToEventTarget (event, target);
			ReleaseEvent(event);
		}
		if (browserActiveAndDrawingContextOk())
			checkBrowserForHeartBeat();

		if (NeedToSetCursorBackOnApplicationActivate) {  // special case of setting large cursor on app activate
			NeedToSetCursorBackOnApplicationActivate = false;
			SetCursorBackToSomething();
		}

		nextPollTick = ioMSecs();
	}

}

sqInt
ioProcessEvents(void)
{
	extern sqInt inIOProcessEvents;

	/* inIOProcessEvents controls ioProcessEvents.  If negative then
	 * ioProcessEvents is disabled.  If >= 0 inIOProcessEvents is incremented
	 * to avoid reentrancy (i.e. for native GUIs).
	 */
	if (inIOProcessEvents) return 0;
	inIOProcessEvents += 1;

	aioPoll(0);
	doPendingFlush();

	if (inIOProcessEvents > 0)
		inIOProcessEvents -= 1;

    if (gQuitNowRightNow) {
        ioExit();  //This might not return, might call exittoshell
        QuitApplicationEventLoop();
        pthread_exit(null);
    } else {
		sqCycleMainAutoreleasePool();
	}
	return 0;
}

int
getUIToLock(sqInt *data)
{
	customHandleForUILocks(NULL,NULL,(void*) data);
	return 0;
}

static pascal OSStatus
customHandleForUILocks(EventHandlerCallRef myHandler,
						EventRef event, void* userData)
{
#pragma unused(myHandler,event)
    sqInt *data;
    long numberOfParms;


	data = userData;

    numberOfParms = data[0];

    if (0 == numberOfParms)
        data[2] = ((sqInt (*) (void)) data[1]) ();
    if (1 == numberOfParms)
        data[3] = ((sqInt (*) (sqInt)) data[1]) (data[2]);
    if (2 == numberOfParms)
        data[4] = ((sqInt (*) (sqInt,sqInt)) data[1]) (data[2],data[3]);
    if (3 == numberOfParms)
        data[5] = ((sqInt (*) (sqInt,sqInt,sqInt)) data[1]) (data[2],data[3],data[4]);
    if (4 == numberOfParms)
        data[6] = ((sqInt (*) (sqInt,sqInt,sqInt,sqInt)) data[1]) (data[2],data[3],data[4],data[5]);
    if (5 == numberOfParms)
        data[7] = ((sqInt (*) (sqInt,sqInt,sqInt,sqInt,sqInt)) data[1]) (data[2],data[3],data[4],data[5],data[6]);
    if (6 == numberOfParms)
        data[8] = ((sqInt (*) (sqInt,sqInt,sqInt,sqInt,sqInt,sqInt)) data[1]) (data[2],data[3],data[4],data[5],data[6], data[7]);

    return noErr;
}

void
signalAnyInterestedParties()
{
    if (inputSemaphoreIndex != 0)
        signalSemaphoreWithIndex(inputSemaphoreIndex);
}

static EventHandlerUPP gEventLoopEventHandlerUPP;   // -> EventLoopEventHandler

static pascal OSStatus
EventLoopEventHandler(EventHandlerCallRef inHandlerCallRef,
						EventRef inEvent, void *inUserData)
    // This code contains the standard Carbon event dispatch loop,
    // as per "Inside Macintosh: Handling Carbon Events", Listing 3-10,
{
        // Run our event loop until quitNow is set.
#pragma unused(inHandlerCallRef,inEvent,inUserData)
	extern void printPhaseTime(int);
	SetUpCarbonEvent();
	printPhaseTime(2);
	interpret(); //Note the application under carbon event mgr starts running here
	return 0;
 }


void
RunApplicationEventLoopWithSqueak(void)
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

static sqKeyboardEvent *
enterKeystroke(long type, long cc, long pc, UniChar utf32Code, long m)
{
	sqKeyboardEvent *evt = (sqKeyboardEvent*)nextEventPut();

	/* first the basics */
	//fprintf(stdout,"\nKeyStroke time %i Type %i Value %i",ioMSecs(),pc,cc); fflush(stdout);
	evt->type = type;
	evt->timeStamp = ioMSecs() & MillisecondClockMask;
	/* now the key code */
	/* press code must differentiate */
	evt->charCode = cc;
	evt->pressCode = pc;
	evt->modifiers = m;
	evt->windowIndex = windowActive;
	evt->utf32Code = 0;
	if (pc == EventKeyChar) {
		evt->utf32Code = utf32Code;
		if (!inputSemaphoreIndex) {
			int  keystate;

			/* keystate: low byte is the ascii character; next 8 bits are modifier bits */
				keystate = (evt->modifiers << 8) | (unsigned char)  ((char) cc);
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
	}
	return evt;
}


static int
addToKeyMap(int keyCode, UniChar keyChar)
{
  //fprintf(stdout, "\nAddToKeyMap T %i code %i char %i(%x,%c) i %i",ioMSecs(),keyCode,keyChar,keyChar,keyChar,keyMapSize); fflush(stdout);
  if (keyMapSize > KeyMapSize) { fprintf(stderr, "keymap overflow\n");  return -1; }
  keyMap[keyMapSize++]= (KeyMapping){ keyCode, keyChar, 0};
  return keyChar;
}

static int
indexInKeyMap(int keyCode)
{
  int i;
  for (i= 0;  i < keyMapSize;  ++i)
    if (keyMap[i].keyCode == keyCode)
      return i;
  return -1;
}

static UniChar
findInKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  return (idx != -1) ? keyMap[idx].keyChar : -1;
}

static int
findRepeatInKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  return (idx != -1) ? keyMap[idx].keyRepeated : 0;
}

static void
setRepeatInKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  if (idx != -1) keyMap[idx].keyRepeated = 1;
}

static int
removeFromKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  int keyChar= -1;
  //fprintf(stdout, "\nremoveFromKeyMap T %i c %i i %i",ioMSecs(),keyCode,keyMapSize-1); fflush(stdout);
  if (idx == -1) { //fprintf(stderr, "keymap underflow\n");
		return -1; }
  keyChar= keyMap[idx].keyChar;
  for (; idx < keyMapSize - 1;  ++idx)
    keyMap[idx]= keyMap[idx + 1];
  --keyMapSize;
  return keyChar;
}

void
sqRevealWindowAndHandleQuit ()
{
	/*  When we receive a Quit command, since the image may or may not want input,
		we have to activate (uncollapse) the main window, just in case, so the user
		can see the (possible) confirmation dialog.
		We reat Quit the same as main-window close, for parity with the Windows VM */


	WindowRef win = windowHandleFromIndex(1);
	if (win) {
		windowBlockFromIndex(1)->isInvisible  = false;
		SelectWindow(win);
		ShowWindow( win );
	}

	recordWindowEventCarbon(WindowEventClose,0, 0, 0, 0, 1 /* main ST window index */ );

}

#if NewspeakVM
/* For now this is only here to make the linker happy;
   the function really does something interesting only on Windows.
 */
void
ioDrainEventQueue() {}
#endif /* NewspeakVM */
