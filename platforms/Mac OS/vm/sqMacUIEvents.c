/****************************************************************************
*   PROJECT: Mac event interface.
*   FILE:    sqMacUIEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIEvents.c,v 1.19 2003/12/02 04:48:24 johnmci Exp $
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

notes: see incontent, I think it's a bug, click to bring to foreground signls mousedown. bad...
IsUserCancelEventRef

*****************************************************************************/
#if !TARGET_API_MAC_CARBON 
#include <Power.h>
#include <USB.h>
#include <DeskBus.h>
#endif

#include "sq.h"
#include "sqMacUIEvents.h"
#include "sqMacUIMenuBar.h"

#if I_AM_CARBON_EVENT
    #include <pthread.h>
    #include "aio.h"
    
    pthread_mutex_t gEventQueueLock,gEventUILock;
    pthread_cond_t  gEventUILockCondition;
    extern pthread_mutex_t gSleepLock;
    extern pthread_cond_t  gSleepLockCondition;
    #define EventTypeFullScreenUpdate 98
    #define EventTypePostEventProcessing 99
    void doPostMessageHook(EventRef event);
    void postFullScreenUpdate(void);
    void signalAnyInterestedParties(void);
    Boolean gQuitNowRightNow=false;
#endif

/*** Variables -- Event Recording ***/
#ifdef MINIMALVM
#define MAX_EVENT_BUFFER 128
#else
#define MAX_EVENT_BUFFER 1024
#endif

extern int getInterruptKeycode();
extern int setInterruptPending(int value);
extern int setInterruptCheckCounter(int value);
extern int getFullScreenFlag();
extern struct VirtualMachine* interpreterProxy;

extern MenuHandle editMenu;
extern MenuHandle appleMenu;
extern Boolean gThreadManager;
extern Boolean gTapPowerManager;
extern Boolean gDisablePowerManager;

int inputSemaphoreIndex = 0;/* if non-zero the event semaphore index */

sqInputEvent eventBuffer[MAX_EVENT_BUFFER];
int eventBufferGet = 0;
int eventBufferPut = 0;

/* declaration of the event message hook */
eventMessageHook messageHook = NULL;
eventMessageHook postMessageHook = NULL;

/* event capture */
sqInputEvent *nextEventPut(void);

#define KEYBUF_SIZE 64
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

Point savedMousePosition;	/* mouse position when window is inactive */
int windowActive = true;	/* true if the Squeak window is the active window */

/* This table maps the 5 Macintosh modifier key bits to 4 Squeak modifier
   bits. (The Mac shift and caps lock keys are both mapped to the single
   Squeak shift bit).  This was true for squeak upto 3.0.7. Then in 3.0.8 we 
   decided to not map the cap lock key to shift
   
		Mac bits: <control><option><caps lock><shift><command>
		ST bits:  <command><option><control><shift>
*/
char modifierMap[256] = {
//	0,  8, 1,  9, 1,  9, 1,  9, 4, 12, 5, 13, 5, 13, 5, 13, caps lock
//	2, 10, 3, 11, 3, 11, 3, 11, 6, 14, 7, 15, 7, 15, 7, 15
//    0,  8, 1,  9, 0,  8, 1,  9, 4, 12, 5, 13, 4, 12, 5, 13, //no caps lock
//    2, 10, 3, 11, 2, 10, 3, 11, 6, 14, 7, 15, 6, 14, 7, 15
	
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
 
 
void ADBIOCompletionPPC(Byte *dataBufPtr, Byte *opDataPtr, long command);
Boolean IsKeyDown(void);    

#if !defined(I_AM_CARBON_EVENT) || defined(BROWSERPLUGIN)
int  HandleEvents(void);
void HandleMenu(int mSelect);
void HandleMouseDown(EventRecord *theEvent);
int ioProcessEvents(void) {
	/* This is a noop when running as a plugin; the browser handles events. */
	static unsigned long   nextPollTick = 0, nextPowerCheck=0, disableIdleTickLimit=0;
	unsigned long   clockTime;

#ifndef BROWSERPLUGIN
    clockTime = ioLowResMSecs();
	if (abs(nextPollTick - clockTime) >= 16) {
		/* time to process events! */
		while (HandleEvents()) {
			/* process all pending events */
		}

        clockTime = ioLowResMSecs();        
		nextPollTick = clockTime;
		
        if (gDisablePowerManager && gTapPowerManager) {
            if (abs(disableIdleTickLimit - clockTime) >= 6000) {
                IdleUpdate();
                disableIdleTickLimit = clockTime;
            }
                
#if !defined(MINIMALVM)
            if (abs(nextPowerCheck - clockTime) >= 500) {
                 UpdateSystemActivity(UsrActivity);
                 nextPowerCheck = clockTime;
            }
#endif
        }        
	}
#endif
}

int HandleEvents(void) {
	EventRecord		theEvent;
	int				ok;

	ok = WaitNextEvent(everyEvent, &theEvent,0,null);
	if((messageHook) && (messageHook(&theEvent))) {
        return ok;
    }
	if (ok) {
		switch (theEvent.what) {
			case mouseDown:
				HandleMouseDown(&theEvent);
				if(postMessageHook) postMessageHook(&theEvent);
				return false;
			break;

			case mouseUp:
			    gButtonIsDown = false;
				if(inputSemaphoreIndex) {
					recordMouseEvent(&theEvent,MouseModifierState(&theEvent));
    				if(postMessageHook) postMessageHook(&theEvent);
					return false;
				}
				recordModifierButtons(&theEvent);
				if(postMessageHook) postMessageHook(&theEvent);
				return false;
			break;

			case keyDown:
			case autoKey:
                if ((theEvent.modifiers & cmdKey) != 0) {
					AdjustMenus();
					HandleMenu(MenuKey(theEvent.message & charCodeMask));
				}
				if(inputSemaphoreIndex) {
					recordKeyboardEvent(&theEvent,EventKeyDown);
					break;
				}
				recordModifierButtons(&theEvent);
				recordKeystroke(&theEvent);
			break;
			
			case keyUp:
				if(inputSemaphoreIndex) {
					recordKeyboardEvent(&theEvent,EventKeyUp);
				}
			break;

#ifndef IHAVENOHEAD
			case updateEvt:

				BeginUpdate((WindowPtr) theEvent.message);
				fullDisplayUpdate();  /* this makes VM call ioShowDisplay */
				EndUpdate((WindowPtr) theEvent.message);

			break;

			case activateEvt:
				if (theEvent.modifiers & activeFlag) {
					windowActive = true;
				} else {
					GetMouse(&savedMousePosition);
					windowActive = false;
				}
				fullDisplayUpdate();  /* Fix for full screen menu bar tabbing*/
			break;
#endif

			case kHighLevelEvent:
				AEProcessAppleEvent(&theEvent);
			break;
			
			case osEvt: 
				if (((theEvent.message>>24)& 0xFF) == suspendResumeMessage) {
				
					//JMM July 4th 2000
					//Fix for menu bar tabbing, thanks to Javier Diaz-Reinoso for pointing this out
					//
					if ((theEvent.message & resumeFlag) == 0) {
						GetMouse(&savedMousePosition);
						windowActive = false;
						if (getFullScreenFlag())
							MenuBarRestore();
					} else {
						windowActive = true;
 						if (getFullScreenFlag()) {
							MenuBarHide();
            				fullDisplayUpdate();  /* Fix for full screen menu bar tabbing*/
						}
					}
				}
				break;
		}
	}
	else {
		if(inputSemaphoreIndex && windowActive ) {
    		theEvent.modifiers = checkForModifierKeys();
 			recordMouseEvent(&theEvent,MouseModifierState(&theEvent));
 		}
 	}
	if(postMessageHook) postMessageHook(&theEvent); 
	return ok;
}

void HandleMenu(int mSelect) {
	int			menuID, menuItem;
	Str255		name;
	GrafPtr		savePort;

	menuID = HiWord(mSelect);
	menuItem = LoWord(mSelect);
	switch (menuID) {
		case appleID:
			GetPort(&savePort);
			GetMenuItemText(appleMenu, menuItem, name);
#if !TARGET_API_MAC_CARBON
			OpenDeskAcc(name);
#endif 
			SetPort(savePort);
		break;

		case fileID:
			if (menuItem == quitItem) {
				ioExit();
			}
		break;

		case editID:
#if !TARGET_API_MAC_CARBON
			if (!SystemEdit(menuItem - 1)) {
				SysBeep(5);
			}
#endif
		break;
	}
}

void HandleMouseDown(EventRecord *theEvent) {
	WindowPtr	theWindow;
	static Rect		growLimits = { 20, 20, 10000, 10000 };
	Rect        dragBounds;
	int			windowCode, newSize;

	windowCode = FindWindow(theEvent->where, &theWindow);
	switch (windowCode) {
		case inSysWindow:
#if !TARGET_API_MAC_CARBON
			SystemClick(theEvent, theWindow);
#endif
		break;

		case inMenuBar:
			AdjustMenus();
			HandleMenu(MenuSelect(theEvent->where));
		break;

#ifndef IHAVENOHEAD
		case inDrag:

			if (getFullScreenFlag()) 	
				break;
				
			GetRegionBounds(GetGrayRgn(), &dragBounds);
			if (theWindow == getSTWindow()) {
				DragWindow(getSTWindow(), theEvent->where, &dragBounds);
			}
		break;

		case inGrow:
			if (theWindow == getSTWindow()) {
				if (getFullScreenFlag()) 	
					break;
				newSize = GrowWindow(getSTWindow(), theEvent->where, &growLimits);
				if (newSize != 0) {
					SizeWindow(getSTWindow(), LoWord(newSize), HiWord(newSize), true);
				}
			}
		break;

		case inZoomIn:
		case inZoomOut:
			if (theWindow == getSTWindow()) {
				if (getFullScreenFlag()) 	
					break;
					DoZoomWindow(theEvent,getSTWindow(), windowCode,10000, 10000);
				}

		break;

		case inContent:
			gButtonIsDown = true;
			if (theWindow == getSTWindow()) {
				if (theWindow != FrontWindow()) {
					SelectWindow(getSTWindow());
				}
				if(inputSemaphoreIndex) {
					recordMouseEvent(theEvent,MouseModifierState(theEvent));
					break;
				}
				recordMouseDown(theEvent);
			}
		break;

		case inGoAway:
			if ((theWindow == getSTWindow()) &&
				(TrackGoAway(getSTWindow(), theEvent->where))) {
					/* HideWindow(stWindow); noop for now */
			}
		break;
#endif
	}
}

/*** Event Recording Functions ***/

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

void recordMouseDown(EventRecord *theEvent) {

	/* button state: low three bits are mouse buttons; next 4 bits are modifier bits */
	buttonState = MouseModifierState(theEvent);
	cachedButtonState = cachedButtonState | buttonState;
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

int recordMouseEvent(EventRecord *theEvent, int theButtonState) {
	sqMouseEvent *evt;
	static sqMouseEvent oldEvent;
	
	evt = (sqMouseEvent*) nextEventPut();

	/* first the basics */
	evt->type = EventTypeMouse;
	evt->timeStamp = ioMSecs() & 536870911; 
	GlobalToLocal((Point *) &theEvent->where);
	evt->x = theEvent->where.h;
	evt->y = theEvent->where.v;
	/* then the buttons */
	evt->buttons = theButtonState & 0x07;
	/* then the modifiers */
	evt->modifiers = theButtonState >> 3;
	/* clean up reserved */
	evt->reserved1 = 0;
	evt->reserved2 = 0;
	
	if (oldEvent.buttons == evt->buttons && 
	    oldEvent.x == evt->x &&
	    oldEvent.y == evt->y &&
	    oldEvent.modifiers == evt->modifiers) 
	    ignoreLastEvent();
	    
    oldEvent = *evt;

	
//	signalSemaphoreWithIndex(inputSemaphoreIndex);
	return 1;
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
	evt->timeStamp = ioMSecs() & 536870911;
	/* now the key code */
	/* press code must differentiate */
	evt->charCode = (theEvent->message & keyCodeMask) >> 8;
	evt->pressCode = keyType;
	evt->modifiers = modifierBits >> 3;
	/* clean up reserved */
	evt->reserved1 = 0;
	evt->reserved2 = 0;
	/* generate extra character event */
	if (keyType == EventKeyDown) {
		extra = (sqKeyboardEvent*)nextEventPut();
		*extra = *evt;
		extra->charCode = asciiChar;
		extra->pressCode = EventKeyChar;
	}
//	signalSemaphoreWithIndex(inputSemaphoreIndex);
	return 1;
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

#endif

int recordDragDropEvent(EventRecord *theEvent, int numberOfItems, int dragType) {
	sqDragDropFilesEvent *evt;
	int theButtonState;
	
#if I_AM_CARBON_EVENT
        pthread_mutex_lock(&gEventQueueLock);
#endif
        evt = (sqDragDropFilesEvent*) nextEventPut();

	/* first the basics */
	theButtonState = MouseModifierState(theEvent);
	evt->type = EventTypeDragDropFiles;
	evt->timeStamp = ioMSecs() & 536870911; 
	GlobalToLocal((Point *) &theEvent->where);
	evt->x = theEvent->where.h;
	evt->y = theEvent->where.v;
	evt->numFiles = numberOfItems;
	evt->dragType = dragType;
	
	/* then the modifiers */
	evt->modifiers = theButtonState >> 3;
	/* clean up reserved */
	evt->reserved1 = 0;
#if I_AM_CARBON_EVENT
        pthread_mutex_unlock(&gEventQueueLock);
        signalAnyInterestedParties();
#endif
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
#if I_AM_CARBON_EVENT
        aioPoll(0);
        pthread_mutex_lock(&gEventQueueLock);
#else
    if (eventBufferGet == eventBufferPut) {
        if (gThreadManager)
            SqueakYieldToAnyThread();
        else
            ioProcessEvents();
    }
#endif
	if (eventBufferGet == eventBufferPut) {
#if I_AM_CARBON_EVENT
            pthread_mutex_unlock(&gEventQueueLock);
#endif
            return false;
        }
	*evt = eventBuffer[eventBufferGet];
	eventBufferGet = (eventBufferGet+1) % MAX_EVENT_BUFFER;
#if I_AM_CARBON_EVENT
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
#endif
	return true;
}

int ioGetButtonState(void) {
	if (gThreadManager)
		SqueakYieldToAnyThread();
	else
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

	if (gThreadManager)
		SqueakYieldToAnyThread();
	else
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

	if (gThreadManager)
		SqueakYieldToAnyThread();
	else
	    ioProcessEvents();
	if (windowActive) {
                GrafPtr savePort;
                GetPort(&savePort);
                SetPortWindowPort(getSTWindow());
		GetMouse(&p);
                SetPort(savePort);
	} else {
		/* don't report mouse motion if window is not active */
		p = savedMousePosition;
	}
	return (p.h << 16) | (p.v & 0xFFFF);  /* x is high 16 bits; y is low 16 bits */
}

int ioPeekKeystroke(void) {
	int keystate;

	if (gThreadManager)
		SqueakYieldToAnyThread();
	else
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

#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__) && JMMFoo
  
Boolean USBKeyboardCheckKey(int macKeyCode);
#define kNumberOfKeyboardDispatch 10
static USBHIDModuleDispatchTable *keyboardDispatch[kNumberOfKeyboardDispatch] = { NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};

Boolean IsKeyDown()
 {
   KeyMap theKeys;
   int    keyToCheck,result;
   Boolean  checkValue;
   
    keyToCheck = interpreterProxy->stackIntegerValue(0);
    if (interpreterProxy->failed()) {
		return null;
    }
    if (keyboardDispatch[0] == NULL ) {
        GetKeys(theKeys);
        checkValue = ((unsigned char *)(theKeys))[keyToCheck/ 8] & 1 << ((keyToCheck) % 8);
    } else {
        checkValue = USBKeyboardCheckKey(keyToCheck);
    }
    
    result = checkValue ? interpreterProxy->trueObject(): interpreterProxy->falseObject();
	
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, result);
	return null;
 }

void USBKeyboardInit(void);

#if !TARGET_API_MAC_CARBON
void ADBIOCompletionPPC(Byte *dataBufPtr, Byte *opDataPtr, long command) {
	*opDataPtr = true;
}
  
 

void SetupKeyboard(void) {
 	ADBAddress     currentDev;
 	ADBDataBlock   info;
 	volatile short data = 0;
 	short       number;
 	Byte        buffer[3], ADBReg;
 	short       talk, listen,i;
 	OSErr       myErr;
    ADBCompletionUPP  compProcPtr=NULL;      // PPC completion routine 
    ADBDataBlock    adbData;
        
    USBKeyboardInit();

    number = CountADBs();
    compProcPtr = NewADBCompletionProc(ADBIOCompletionPPC);
    
    for(i=1;i<=number;i++) {
        currentDev = GetIndADB(&info, i);
        if (currentDev < 0)
           return;
           
        myErr = GetADBInfo(&adbData, currentDev);
        if (!((adbData.origADBAddr == 2) && (adbData.devType == 2) ))
          continue;
                        
        buffer[0] = 2;             // length byte
        buffer[1] = 0;
        buffer[2] = 0;
        ADBReg = 3;                // get register 3
     
        talk = (currentDev << 4) + 0x0C + ADBReg;    
     
        data = 0;
        myErr = ADBOp((Ptr)&data, (ADBCompletionUPP)compProcPtr, (Ptr)buffer, talk);
        if (myErr != noErr) 
           goto done;
     
        while(!data); 
        
        buffer[2] = 3; // change from 2 to 3 so we can differentiate between left and right shift keys
        listen = (currentDev << 4) + 0x08 + ADBReg; 
     
    	data = 0;
        myErr = ADBOp((Ptr)&data, (ADBCompletionUPP)compProcPtr, (Ptr)buffer, listen);
        while(!data); 
    }
done:  
    if (compProcPtr)
        DisposeRoutineDescriptor(compProcPtr);
}
#endif



// index represents USB keyboard usage value, content is Mac virtual keycode
static UInt8	USBKMAPReverse[256],USBKMAP[256] = {  
	0xFF, 	/* 00 no event */		
	0xFF,	/* 01 ErrorRollOver */	
	0xFF,	/* 02 POSTFail */	
	0xFF,	/* 03 ErrorUndefined */	
	0x00,	/* 04 A */
	0x0B,	/* 05 B */
	0x08,	/* 06 C */
	0x02,	/* 07 D */
	0x0E,	/* 08 E */
	0x03,	/* 09 F */
	0x05,	/* 0A G */
	0x04,	/* 0B H */
	0x22,	/* 0C I */
	0x26,	/* 0D J */
	0x28,	/* 0E K */
	0x25,	/* 0F L */

	0x2E, 	/* 10 M */		
	0x2D,	/* 11 N */	
	0x1F,	/* 12 O */	
	0x23,	/* 13 P */	
	0x0C,	/* 14 Q */
	0x0F,	/* 15 R */
	0x01,	/* 16 S */
	0x11,	/* 17 T */
	0x20,	/* 18 U */
	0x09,	/* 19 V */
	0x0D,	/* 1A W */
	0x07,	/* 1B X */
	0x10,	/* 1C Y */
	0x06,	/* 1D Z */
	0x12,	/* 1E 1/! */
	0x13,	/* 1F 2/@ */

	0x14, 	/* 20 3 # */		
	0x15,	/* 21 4 $ */	
	0x17,	/* 22 5 % */	
	0x16,	/* 23 6 ^ */	
	0x1A,	/* 24 7 & */
	0x1C,	/* 25 8 * */
	0x19,	/* 26 9 ( */
	0x1D,	/* 27 0 ) */
	0x24,	/* 28 Return (Enter) */
	0x35,	/* 29 ESC */
	0x33,	/* 2A Delete (Backspace) */
	0x30,	/* 2B Tab */
	0x31,	/* 2C Spacebar */
	0x1B,	/* 2D - _ */
	0x18,	/* 2E = + */
	0x21,	/* 2F [ { */

	0x1E, 	/* 30 ] } */		
	0x2A,	/* 31 \ | */	
	0xFF,	/* 32 Non-US # and ~ (what?!!!) */	
	0x29,	/* 33 ; : */	
	0x27,	/* 34 ' " */
	0x32,	/* 35 ` ~ */
	0x2B,	/* 36 , < */
	0x2F,	/* 37 . > */
	0x2C,	/* 38 / ? */
	0x39,	/* 39 Caps Lock */
	0x7A,	/* 3A F1 */
	0x78,	/* 3B F2 */
	0x63,	/* 3C F3 */
	0x76,	/* 3D F4 */
	0x60,	/* 3E F5 */
	0x61,	/* 3F F6 */

	0x62, 	/* 40 F7 */		
	0x64,	/* 41 F8 */	
	0x65,	/* 42 F9 */	
	0x6D,	/* 43 F10 */	
	0x67,	/* 44 F11 */
	0x6F,	/* 45 F12 */
	0x69,	/* 46 F13/PrintScreen */
	0x6B,	/* 47 F14/ScrollLock */
	0x71,	/* 48 F15/Pause */				
	0x72,	/* 49 Insert */
	0x73,	/* 4A Home */
	0x74,	/* 4B PageUp */
	0x75,	/* 4C Delete Forward */
	0x77,	/* 4D End */
	0x79,	/* 4E PageDown */
	0x7C,	/* 4F RightArrow */

	0x7B, 	/* 50 LeftArrow */		
	0x7D,	/* 51 DownArrow */	
	0x7E,	/* 52 UpArrow */	
	0x47,	/* 53 NumLock/Clear */	
	0x4B,	/* 54 Keypad / */
	0x43,	/* 55 Keypad * */
	0x4E,	/* 56 Keypad - */
	0x45,	/* 57 Keypad + */
	0x4C,	/* 58 Keypad Enter */
	0x53,	/* 59 Keypad 1 */
	0x54,	/* 5A Keypad 2 */
	0x55,	/* 5B Keypad 3 */
	0x56,	/* 5C Keypad 4 */
	0x57,	/* 5D Keypad 5 */
	0x58,	/* 5E Keypad 6 */
	0x59,	/* 5F Keypad 7 */

	0x5B, 	/* 60 Keypad 8 */		
	0x5C,	/* 61 Keypad 9 */	
	0x52,	/* 62 Keypad 0 */	
	0x41,	/* 63 Keypad . */	
	0xFF,	/* 64 Non-US \ and  | (what ??!!) */
	0x6E,	/* 65 ApplicationKey (not on a mac!)*/
	0x7F,	/* 66 PowerKey  */
	0x51,	/* 67 Keypad = */
	0x69,	/* 68 F13 */
	0x6B,	/* 69 F14 */
	0x71,	/* 6A F15 */
	0xFF,	/* 6B F16 */
	0xFF,	/* 6C F17 */
	0xFF,	/* 6D F18 */
	0xFF,	/* 6E F19 */
	0xFF,	/* 6F F20 */

	0x5B, 	/* 70 F21 */		
	0x5C,	/* 71 F22 */	
	0x52,	/* 72 F23 */	
	0x41,	/* 73 F24 */	
	0xFF,	/* 74 Execute */
	0xFF,	/* 75 Help */
	0x7F,	/* 76 Menu */
	0x4C,	/* 77 Select */
	0x69,	/* 78 Stop */
	0x6B,	/* 79 Again */
	0x71,	/* 7A Undo */
	0xFF,	/* 7B Cut */
	0xFF,	/* 7C Copy */
	0xFF,	/* 7D Paste */
	0xFF,	/* 7E Find */
	0xFF,	/* 7F Mute */
	
	0xFF, 	/* 80 no event */		
	0xFF,	/* 81 no event */	
	0xFF,	/* 82 no event */	
	0xFF,	/* 83 no event */	
	0xFF,	/* 84 no event */
	0xFF,	/* 85 no event */
	0xFF,	/* 86 no event */
	0xFF,	/* 87 no event */
	0xFF,	/* 88 no event */
	0xFF,	/* 89 no event */
	0xFF,	/* 8A no event */
	0xFF,	/* 8B no event */
	0xFF,	/* 8C no event */
	0xFF,	/* 8D no event */
	0xFF,	/* 8E no event */
	0xFF,	/* 8F no event */

	0xFF, 	/* 90 no event */		
	0xFF,	/* 91 no event */	
	0xFF,	/* 92 no event */	
	0xFF,	/* 93 no event */	
	0xFF,	/* 94 no event */
	0xFF,	/* 95 no event */
	0xFF,	/* 96 no event */
	0xFF,	/* 97 no event */
	0xFF,	/* 98 no event */
	0xFF,	/* 99 no event */
	0xFF,	/* 9A no event */
	0xFF,	/* 9B no event */
	0xFF,	/* 9C no event */
	0xFF,	/* 9D no event */
	0xFF,	/* 9E no event */
	0xFF,	/* 9F no event */

	0xFF, 	/* A0 no event */		
	0xFF,	/* A1 no event */	
	0xFF,	/* A2 no event */	
	0xFF,	/* A3 no event */	
	0xFF,	/* A4 no event */
	0xFF,	/* A5 no event */
	0xFF,	/* A6 no event */
	0xFF,	/* A7 no event */
	0xFF,	/* A8 no event */
	0xFF,	/* A9 no event */
	0xFF,	/* AA no event */
	0xFF,	/* AB no event */
	0xFF,	/* AC no event */
	0xFF,	/* AD no event */
	0xFF,	/* AE no event */
	0xFF,	/* AF no event */

	0xFF, 	/* B0 no event */		
	0xFF,	/* B1 no event */	
	0xFF,	/* B2 no event */	
	0xFF,	/* B3 no event */	
	0xFF,	/* B4 no event */
	0xFF,	/* B5 no event */
	0xFF,	/* B6 no event */
	0xFF,	/* B7 no event */
	0xFF,	/* B8 no event */
	0xFF,	/* B9 no event */
	0xFF,	/* BA no event */
	0xFF,	/* BB no event */
	0xFF,	/* BC no event */
	0xFF,	/* BD no event */
	0xFF,	/* BE no event */
	0xFF,	/* BF no event */

	0xFF, 	/* C0 no event */		
	0xFF,	/* C1 no event */	
	0xFF,	/* C2 no event */	
	0xFF,	/* C3 no event */	
	0xFF,	/* C4 no event */
	0xFF,	/* C5 no event */
	0xFF,	/* C6 no event */
	0xFF,	/* C7 no event */
	0xFF,	/* C8 no event */
	0xFF,	/* C9 no event */
	0xFF,	/* CA no event */
	0xFF,	/* CB no event */
	0xFF,	/* CC no event */
	0xFF,	/* CD no event */
	0xFF,	/* CE no event */
	0xFF,	/* CF no event */

	0xFF, 	/* D0 no event */		
	0xFF,	/* D1 no event */	
	0xFF,	/* D2 no event */	
	0xFF,	/* D3 no event */	
	0xFF,	/* D4 no event */
	0xFF,	/* D5 no event */
	0xFF,	/* D6 no event */
	0xFF,	/* D7 no event */
	0xFF,	/* D8 no event */
	0xFF,	/* D9 no event */
	0xFF,	/* DA no event */
	0xFF,	/* DB no event */
	0xFF,	/* DC no event */
	0xFF,	/* DD no event */
	0xFF,	/* DE no event */
	0xFF,	/* DF no event */

	0x3B, 	/* E0 left control key */		
	0x38,	/* E1 left shift key key */	
	0x3A,	/* E2 left alt/option key */	
	0x37,	/* E3 left GUI (windows/cmd) key */	
	
	0x3E,	/* E4 right control key */ 
	0x3C,	/* E5 right shift key key */ 
	0x3D,	/* E6 right alt/option key */ 
	0x37,	/* E7 right GUI (windows/cmd) key */
	0xFF,	/* E8 no event */
	0xFF,	/* E9 no event */
	0xFF,	/* EA no event */
	0xFF,	/* EB no event */
	0xFF,	/* EC no event */
	0xFF,	/* ED no event */
	0xFF,	/* EE no event */
	0xFF,	/* EF no event */
	
	0xFF, 	/* F0 no event */		
	0xFF,	/* F1 no event */	
	0xFF,	/* F2 no event */	
	0xFF,	/* F3 no event */	
	0xFF,	/* F4 no event */
	0xFF,	/* F5 no event */
	0xFF,	/* F6 no event */
	0xFF,	/* F7 no event */
	0xFF,	/* F8 no event */
	0xFF,	/* F9 no event */
	0xFF,	/* FA no event */
	0xFF,	/* FB no event */
	0xFF,	/* FC no event */
	0xFF,	/* FD no event */
	0xFF,	/* FE no event */
	0xFF,	/* FF no event */
};


/* USBKeyboardInit - find a USB keyboard driver, and get its dispatch 
table.
 */
void USBKeyboardInit(void){
    int i;
    OSErr          errCode;
    USBDeviceRef      deviceRef;
    CFragConnectionID connID;
    CFragSymbolClass  symClass;
    THz curzone;
    
    for(i=0;i<256;i++) {
        USBKMAPReverse[USBKMAP[i]] = i;
    }
    
    if((Ptr)USBGetNextDeviceByClass == (Ptr)kUnresolvedCFragSymbolAddress)
    	return;
    	
#if CALL_NOT_IN_CARBON
    deviceRef = kNoDeviceRef;
    for (i=0;i< kNumberOfKeyboardDispatch; i++ ) {
          errCode = USBGetNextDeviceByClass(&deviceRef, &connID, kUSBHIDInterfaceClass, kUSBAnySubClass, kUSBKeyboardInterfaceProtocol);
          if (errCode == fnfErr) 
            return;
            
          curzone = GetZone();
          SetZone(SystemZone());
          errCode =  FindSymbol(connID,"\pTheHIDModuleDispatchTable", (Ptr*) &keyboardDispatch[i], &symClass);
          SetZone(curzone); 
    } 
#endif
}


Boolean USBKeyboardCheckKey(int macKeyCode) {
    USBHIDData  data;
    SInt16 i,j;
    for(i=0;i<kNumberOfKeyboardDispatch;i++) {
        if(NULL != keyboardDispatch[i] && NULL != keyboardDispatch[i]->pUSBHIDGetDeviceInfo) {
          if(noErr == (*keyboardDispatch[i]->pUSBHIDGetDeviceInfo)(kHIDGetCurrentKeys, &data)) {
                for(j = 0;j < data.kbd.keycount;j++){
                    if (USBKMAPReverse[macKeyCode] ==  data.kbd.usbkeycode[i])
                        return true;
             }
          }
        }
    }
    return false;
} 
#else
Boolean IsKeyDown() {
    interpreterProxy->success(false);
    return null;
}
#endif

#ifdef I_AM_CARBON_EVENT

extern MenuHandle fileMenu, editMenu;
EventLoopTimerRef  gPowerManagerDefeatTimer;

EventTypeSpec appEventCmdList[] = {{kEventClassCommand, kEventCommandProcess}};

EventTypeSpec appEventList[] = {{kEventClassApplication, kEventAppActivated},
                                {kEventClassApplication, kEventAppDeactivated}};

EventTypeSpec windEventList[] = {{kEventClassWindow, kEventWindowDrawContent },
                            { kEventClassWindow, kEventWindowHidden },
                            { kEventClassWindow, kEventWindowActivated},
                            { kEventClassWindow, kEventWindowDeactivated}};
                            
EventTypeSpec windEventMouseList[] = {{ kEventClassMouse, kEventMouseMoved},
                            { kEventClassMouse, kEventMouseWheelMoved},
                            { kEventClassMouse, kEventMouseDragged},
                            { kEventClassMouse, kEventMouseUp},
                            { kEventClassMouse, kEventMouseDown}};
                            
EventTypeSpec windEventKBList[] = {/*{ kEventClassKeyboard, kEventRawKeyDown},
                            { kEventClassKeyboard, kEventRawKeyUp},
                            { kEventClassKeyboard, kEventRawKeyRepeat},*/
                            { kEventClassKeyboard, kEventRawKeyModifiersChanged}};
                            
EventTypeSpec appleEventEventList[] = {{ kEventClassAppleEvent, kEventAppleEvent}};

EventTypeSpec textInputEventList[] = {{ kEventClassTextInput, kEventTextInputUnicodeForKeyEvent}};

EventTypeSpec customEventEventList[] = {{ 'JMM1', 'JMM1'}};

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
static pascal void PowerManagerDefeatTimer (EventLoopTimerRef theTimer,void* userData);
            
int MouseModifierStateCarbon(EventRef theEvent,UInt32 whatHappened);   
int ModifierStateCarbon(EventRef theEvent,UInt32 whatHappened);   
void recordMouseEventCarbon(EventRef event,UInt32 whatHappened);
void recordKeyboardEventCarbon(EventRef event);
int doPreMessageHook(EventRef event); 
void fakeMouseWheelKeyboardEvents(EventMouseWheelAxis wheelMouseDirection,long wheelMouseDelta);
            
void SetUpCarbonEvent() {
    AdjustMenus();

/* Installing the application event handler */
    InstallApplicationEventHandler(NewEventHandlerUPP(MyAppEventCmdHandler), 1, appEventCmdList, 0, NULL);
    InstallApplicationEventHandler(NewEventHandlerUPP(MyAppEventHandler), 2, appEventList, 0, NULL);

/* Installing the window event handler */
    InstallWindowEventHandler(getSTWindow(), NewEventHandlerUPP(MyWindowEventHandler), 3, windEventList, 0, NULL);
    InstallWindowEventHandler(getSTWindow(), NewEventHandlerUPP(MyWindowEventMouseHandler), 5, windEventMouseList, 0, NULL);
    InstallWindowEventHandler(getSTWindow(), NewEventHandlerUPP(MyWindowEventKBHandler), 1, windEventKBList, 0, NULL);
    InstallWindowEventHandler(getSTWindow(), NewEventHandlerUPP(MyAppleEventEventHandler), 1, appleEventEventList, 0, NULL);
    InstallWindowEventHandler(getSTWindow(), NewEventHandlerUPP(MyTextInputEventHandler), 1, textInputEventList, 0, NULL);
    InstallApplicationEventHandler (NewEventHandlerUPP(customHandleForUILocks), 1, customEventEventList, 0, NULL);
    
/* timmer loops */
    if (gTapPowerManager) 
    InstallEventLoopTimer (GetMainEventLoop(),
                       6*kEventDurationSecond,
                       kEventDurationSecond,
                       NewEventLoopTimerUPP(PowerManagerDefeatTimer),
                       NULL,&gPowerManagerDefeatTimer);
}

int   doPreMessageHook(EventRef event) {
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

void   doPostMessageHook(EventRef event) {
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
	evt->unused1 = (long) theOldEventType;
        pthread_mutex_unlock(&gEventQueueLock);

        // not quite this postMessageHook(&theOldEventType);
    }
}

void   postFullScreenUpdate() {
    sqInputEvent *evt;
    
    pthread_mutex_lock(&gEventQueueLock);
    evt = nextEventPut();
    evt->type = EventTypeFullScreenUpdate;
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
    switch (whatHappened)
    {
        case kEventAppActivated:
            windowActive = true;
            if (getFullScreenFlag()) {
                MenuBarHide();
            }
            break;
        case kEventAppDeactivated:
            if (gSqueakWindowIsFloating) break;
              GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,
                    sizeof(Point), NULL, &savedMousePosition);
            SetPortWindowPort(getSTWindow());
            GlobalToLocal(&savedMousePosition);
            windowActive = false;
            if (getFullScreenFlag())
                MenuBarRestore();
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
            AdjustMenus();
            if (commandStruct.menu.menuRef == fileMenu) {
                switch (commandStruct.menu.menuItemIndex)
                {
                    case quitItem :
                        result = noErr;
                        gQuitNowRightNow = true;
                    default:
                        break;
                }
            }
             if (commandStruct.menu.menuRef == editMenu) {
                switch (commandStruct.commandID)
                {
                     default:
                        if (windowActive)
                            result = noErr;
                        break;
                }
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
    WindowRef window;
    UInt32 whatHappened;
    OSStatus result = eventNotHandledErr; /* report failure by default */
    extern Boolean gSqueakWindowIsFloating;
  
    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;
    GetEventParameter(event, kEventParamDirectObject, typeWindowRef, NULL,
                sizeof(window), NULL, &window);
    whatHappened = GetEventKind(event);
    switch (whatHappened)
    {
         case kEventWindowActivated:
            windowActive = true;
            postFullScreenUpdate();
             break;
        case kEventWindowDeactivated:
            if (gSqueakWindowIsFloating) break;
            GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,
                    sizeof(Point), NULL, &savedMousePosition);
            SetPortWindowPort(getSTWindow());
            GlobalToLocal(&savedMousePosition);
            windowActive = false;
             break;
       case kEventWindowDrawContent:
            result = noErr;
            break;
        case kEventWindowHidden:
            if (gSqueakWindowIsFloating) {
                ShowWindow(getSTWindow());
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
    Point  mouseLocation;
    OSStatus result = eventNotHandledErr; /* report failure by default */
    static RgnHandle	ioWinRgn=null;
    WindowPtr	theWindow;
    extern Boolean gSqueakWindowIsFloating,gSqueakFloatingWindowGetsFocus;
    
    if (!windowActive)
        return result;

    if (ioWinRgn == null) 
        ioWinRgn = NewRgn();
        
    GetWindowRegion(getSTWindow(),kWindowGlobalPortRgn,ioWinRgn);
    GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,sizeof(Point), NULL, &mouseLocation);
    
    if (!PtInRgn(mouseLocation,ioWinRgn)) {
        return result;
    }
    
   /* if (gSqueakFloatingWindowGetsFocus && gSqueakWindowIsFloating && 
            GetUserFocusWindow() != getSTWindow()) {
        SetUserFocusWindow(kUserFocusAuto);
        SetUserFocusWindow(getSTWindow());
    }*/
    if(messageHook && ((result = doPreMessageHook(event)) != eventNotHandledErr))
        return result;
    
    whatHappened = GetEventKind(event);
    switch (whatHappened)
    {
        case kEventMouseMoved:
        case kEventMouseDragged:
        case kEventMouseWheelMoved:
            recordMouseEventCarbon(event,whatHappened);
            result = noErr;
            return result; //Return early not an event we deal with for post event logic
        case kEventMouseDown:
            GetWindowRegion(getSTWindow(),kWindowGrowRgn,ioWinRgn);
            if (PtInRgn(mouseLocation,ioWinRgn))
                return result;
            if (gSqueakFloatingWindowGetsFocus && gSqueakWindowIsFloating) {
                SetUserFocusWindow(kUserFocusAuto);
                SetUserFocusWindow(getSTWindow());
            }
            gButtonIsDown = true;
            recordMouseEventCarbon(event,whatHappened);
            result = noErr;
            break;
        case kEventMouseUp:
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
    return result;
}

static pascal OSStatus MyWindowEventKBHandler(EventHandlerCallRef myHandler,
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
        /*case kEventRawKeyDown:
        case kEventRawKeyRepeat:
            recordKeyboardEventCarbon(event,EventKeyDown);
            result = noErr;
            break;
        case kEventRawKeyUp:
            recordKeyboardEventCarbon(event,EventKeyUp);
            result = noErr;
            break;*/
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


void recordMouseEventCarbon(EventRef event,UInt32 whatHappened) {
	sqMouseEvent *evt;
	static sqMouseEvent oldEvent;
	Point  where;
        EventMouseWheelAxis wheelMouseDirection=0;
        long	wheelMouseDelta=0;
        OSErr		err;
        
        err = GetEventParameter (event, kEventParamMouseLocation, typeQDPoint,NULL,
                    sizeof(Point), NULL, &where);
                    
        SetPortWindowPort(getSTWindow());
	if (err != noErr)
            GetMouse(&where); //fake mouse event
        else
            GlobalToLocal((Point *) &where);
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
	evt->timeStamp = ioMSecs() & 536870911; 
        evt->x = where.h;
	evt->y = where.v;
	/* then the buttons */
	evt->buttons = buttonState & 0x07;
	/* then the modifiers */
	evt->modifiers = buttonState >> 3;
	/* clean up reserved */
	evt->reserved1 = wheelMouseDirection;
	evt->reserved2 = wheelMouseDelta;
	
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

void fakeMouseWheelKeyboardEvents(EventMouseWheelAxis wheelMouseDirection,long wheelMouseDelta) {
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
	evt->timeStamp = ioMSecs() & 536870911;
	/* now the key code */
	/* press code must differentiate */
	evt->charCode = macKeyCode;
	evt->pressCode = EventKeyDown;
	evt->modifiers = modifierMap[(controlKey >> 8)];
	/* clean up reserved */
	evt->reserved1 = 0;
	evt->reserved2 = 0;
	/* generate extra character event */
        extra = (sqKeyboardEvent*)nextEventPut();
        *extra = *evt;
        extra->charCode = asciiChar;
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
	evt->timeStamp = ioMSecs() & 536870911;
	/* now the key code */
	/* press code must differentiate */
	evt->charCode = macKeyCode;
	evt->pressCode = EventKeyUp;
	evt->modifiers = modifierMap[(controlKey >> 8)];
	/* clean up reserved */
	evt->reserved1 = 0;
	evt->reserved2 = 0;

    }
    pthread_mutex_unlock(&gEventQueueLock);
    signalAnyInterestedParties();                
}

void recordKeyboardEventCarbon(EventRef event) {
    int 		modifierBits, i;
    char 		macCharCode;
    UniCharCount	uniCharCount;
    UniChar		uniChar, modifiedUniChar, *uniCharBufPtr, *uniCharBuf;
    sqKeyboardEvent 	*evt, *extra;
    OSErr	err;
    UniChar  	text;
    UInt32      actualSize; 
    EventRef	actualEvent;
    
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
                            
    uniChar = modifiedUniChar = *uniCharBufPtr;
    buttonState = modifierBits =ModifierStateCarbon(actualEvent,0); //Capture option states
    if (((modifierBits >> 3) & 0x9) == 0x9) {  /* command and shift */
            if ((modifiedUniChar >= 97) && (modifiedUniChar <= 122)) {
                    /* convert ascii code of command-shift-letter to upper case */
                    modifiedUniChar = modifiedUniChar - 32;
            }
    }

    pthread_mutex_lock(&gEventQueueLock);
    evt = (sqKeyboardEvent*) nextEventPut();

    /* first the basics */
    evt->type = EventTypeKeyboard;
    evt->timeStamp = ioMSecs() & 536870911;
    /* now the key code */
    /* press code must differentiate */
    evt->charCode = uniChar;
    evt->pressCode = EventKeyDown;
    evt->modifiers = modifierBits >> 3;
    /* clean up reserved */
    evt->reserved1 = 0;
    evt->reserved2 = 0;
    
    /* Put sqKeyboardEvent in actualSize times */
    uniCharCount = actualSize / sizeof(UniChar);
    for (i=0; i<uniCharCount; i++) {
        /* generate extra character event */
        extra = (sqKeyboardEvent*)nextEventPut();
            extra->type = EventTypeKeyboard;
            extra->timeStamp = ioMSecs() & 536870911;
            extra->charCode = modifiedUniChar;
        extra->pressCode = EventKeyChar;
            extra->modifiers = modifierBits >> 3;
        
        if(!inputSemaphoreIndex) {
            int  keystate;
    
            /* keystate: low byte is the ascii character; next 8 bits are modifier bits */
                keystate = (evt->modifiers << 8) | (unsigned char) uniChar;
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
        uniCharBufPtr++;
        modifiedUniChar = *uniCharBufPtr;
    }

    /* Put the sqKeyboardEvent for KeyUp */
    evt = (sqKeyboardEvent*) nextEventPut();
    /* first the basics */
    evt->type = EventTypeKeyboard;
    evt->timeStamp = ioMSecs() & 536870911;
    /* now the key code */
    /* press code must differentiate */
    evt->charCode = uniChar;
    evt->pressCode = EventKeyUp;
    evt->modifiers = modifierBits >> 3;
    /* clean up reserved */
    evt->reserved1 = 0;
    evt->reserved2 = 0;
    
    free(uniCharBuf);
    pthread_mutex_unlock(&gEventQueueLock);		        
    signalAnyInterestedParties();
}


int MouseModifierStateCarbon(EventRef event,UInt32 whatHappened) {
	long stButtons = 0;
        UInt32 keyBoardModifiers=0;
        EventMouseButton mouseButton=0;
        static long buttonState[4] = {0,0,0,0};
        OSErr err;
        
	err = GetEventParameter( event,
                                kEventParamKeyModifiers,
                                typeUInt32,
                                NULL,
                                sizeof(UInt32),
                                NULL,
                                &keyBoardModifiers); 
  	if (whatHappened != kEventMouseMoved && whatHappened != kEventMouseWheelMoved)
            err = GetEventParameter( event,
                                kEventParamMouseButton,
                                typeMouseButton,
                                NULL,
                                sizeof(EventMouseButton),
                                NULL,
                                &mouseButton); 
                                
        if (mouseButton > 0 && mouseButton < 4) {
            buttonState[mouseButton] = (whatHappened == kEventMouseUp) ? 0 : 1;
            stButtons |= buttonState[1]*4*
                        (!((keyBoardModifiers & optionKey) || (keyBoardModifiers & cmdKey)));
            stButtons |= buttonState[1]*((keyBoardModifiers & optionKey)> 0)*2;
            stButtons |= buttonState[1]*((keyBoardModifiers & cmdKey)> 0)*1;
            stButtons |= buttonState[2]*1;
            stButtons |= buttonState[3]*2;
       }
            
	/* button state: low three bits are mouse buttons; next 8 bits are modifier bits */
	return ((modifierMap[((keyBoardModifiers & 0xFFFF) >> 8)] << 3) |
		(stButtons & 0x7));
}

int ModifierStateCarbon(EventRef event,UInt32 whatHappened) {
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

static pascal void PowerManagerDefeatTimer (EventLoopTimerRef theTimer,void* userData) {
#ifndef BROWSERPLUGIN
    if (gDisablePowerManager && gTapPowerManager) {
        IdleUpdate();
#if !defined(MINIMALVM)
        UpdateSystemActivity(UsrActivity);
#endif
    }
#endif
}

#ifndef BROWSERPLUGIN
int ioProcessEvents(void) {
    if (gQuitNowRightNow) {
        ioExit();  //This might not return, might call exittoshell
        QuitApplicationEventLoop();
        pthread_exit(null);
    }
}
#endif 

int getUIToLock(long *data) {
    OSStatus err;
    EventRef dummyEvent;
    
    err = MacCreateEvent(null,'JMM1','JMM1', 0, kEventAttributeUserEvent, &dummyEvent);
    if (err == noErr) {
        err = SetEventParameter(dummyEvent,1,1,sizeof(long *),&data);
        pthread_mutex_lock(&gEventUILock);
        err = PostEventToQueue(GetMainEventQueue(), dummyEvent,kEventPriorityHigh);
        pthread_cond_wait(&gEventUILockCondition,&gEventUILock);	
        pthread_mutex_unlock(&gEventUILock);
    }
}

static pascal OSStatus customHandleForUILocks(EventHandlerCallRef myHandler,
            EventRef event, void* userData)
{
    long *data;
    long numberOfParms;
    OSErr	err;
        
    pthread_mutex_lock(&gEventUILock);
        
    err = GetEventParameter(event, 1, 1, NULL, sizeof(long *), NULL, &data);
    if (err != noErr) {
        pthread_cond_signal(&gEventUILockCondition);	
        pthread_mutex_unlock(&gEventUILock);
    }
    
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

    pthread_cond_signal(&gEventUILockCondition);	
    pthread_mutex_unlock(&gEventUILock);
    return noErr;
}

void signalAnyInterestedParties() {
    if (inputSemaphoreIndex != 0)
        signalSemaphoreWithIndex(inputSemaphoreIndex);
    /* I'm not sure this buys anything, usually we are waiting for mophic to step so 
    waking up early doesn't do much except drive CPU up
    pthread_mutex_lock(&gSleepLock);
    pthread_cond_signal(&gSleepLockCondition);	
    pthread_mutex_unlock(&gSleepLock);*/
}

#endif