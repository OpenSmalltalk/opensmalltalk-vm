//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCEvents.c
// It handles RISC OS event (some not very well, offer advice if you can)
// and passes them up to Squeak
// It makes use of the Celerica !!DeepKeys module
// define this to get lots of debug notifiers
// #define DEBUG

#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osfscontrol.h"
#include "oslib/osmodule.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "sq.h"
#include "sqArguments.h"

wimp_block			wimpPollBlock;
wimp_event_no		wimpPollEvent;
int					wimpPollWord = 0;
int					windowActive = false;
extern int			pointerBuffer[];
extern os_coord		pointerOffset;
extern os_coord		scalingFactor;
extern os_coord		screenSizeP;

/*** Variables -- Event Recording ***/

int					inputSemaphoreIndex = 0;
#define EVENTQ_SIZE 1024
sqInputEvent		eventBuf[EVENTQ_SIZE ]; /* circular buffer */
int					eventBufGet = 0;
int					eventBufPut = 0;

/* to use the Cerilia DeepKey Event extender */
#define wimp_DEEPKEY_LSHIFT		1<<0
#define wimp_DEEPKEY_RSHIFT		1<<1
#define wimp_DEEPKEY_LCTL		1<<2
#define wimp_DEEPKEY_RCTL		1<<3
#define wimp_DEEPKEY_LALT		1<<4
#define wimp_DEEPKEY_RALT		1<<5
#define wimp_DEEPKEY_LLOGO		1<<6
#define wimp_DEEPKEY_RLOGO		1<<7
#define wimp_DEEPKEY_MENU		1<<8
#define wimp_DEEPKEY_FLAGBIT		1<<15
#define wimp_DEEPKEY_KEYNUMSHIFT	16

/* Note that this struct is the same as wimp_key except for the added word
 * .deepkey which contains the above flags and is formatted so -
 *   b0 Left Shift    b1 Right Shift
 *    b2 Left Ctrl     b3 Right Ctrl
 *    b4 Left Alt      b5 Right Alt
 *    b6 Left Logo     b7 Right Logo
 *    b8 Menu key
 *    b9-14 reserved (0)
 *    b15 Always 0
 *    b16-31 Physical key number
 *
 */
typedef struct {
	wimp_w w;
	wimp_i i;
	os_coord pos;
	int height;
	int index;
	wimp_key_no c;
	int deepkey;
	} wimp_deepkey;

int				user_LCTL_KEY, user_RCTL_KEY;


/* older polling stuff still needs supporting */
#define KEYBUF_SIZE 64
int				keyBuf[KEYBUF_SIZE];	/* circular buffer */
int				keyBufGet = 0;		/* index of next item of keyBuf to read */
int				keyBufPut = 0;		/* index of next item of keyBuf to write */
int				keyBufOverflows = 0;	/* number of characters dropped */

int				prevButtonState,
					buttonState = 0,
					modifierState = 0;	/* mouse button and modifier state  */
os_coord		prevSavedMousePositionP,
				savedMousePositionP;	/* mouse position; not modified when window is inactive unless a mouse button is down - ie dragging out of window */
int				mouseButtonDown; /* keep track of curent mouse button state - for drags outside window */

extern int		getInterruptKeycode(void);
extern int		setInterruptPending(int value);
extern int		forceInterruptCheck(void);
extern int		ioIconiseWindow(wimp_message * wblock);

void			(*socketPollFunction)(int delay, int extraFd) = null;
int				soundBufferEmptySemaphoreIndex = 0;
unsigned int *	soundPollWordPtr = 0;


/* Squeak expects to get kbd modifiers as the top 4bits of the 8bit char code,
 * or as the 2r1111000 bits of the buttons word. RiscOS doesnt give me the
 * modifiers with keypresses, so we have to manually collect them. SQ only
 * seems to care about them when doing primMouseButtons anyway.
 *	ST bits:  <command><option><control><shift>
 * Notice how Macish this is!
*/

#define			MacDownCursor	31
#define			MacUpCursor	30
#define			MacLeftCursor	28
#define			MacRightCursor	29
#define			MacHomeKey	1
#define			MacEndKey	4
#define			MacInsertKey	5
#define			MacDeleteKey	8
#define			MacPageUpKey	11
#define			MacPageDownKey	12

unsigned char keymap[0x68] = {
/* 0x00 Esc */ 0x1b ,
/* 0x01 F1 */ /* 0x181 wimp_KEY_F1 */ 0,
/* 0x02 F2 */ /* 0x182 wimp_KEY_F2 */ 0,
/* 0x03 F3 */ /* 0x183 wimp_KEY_F3 */ 0,
/* 0x04 F4 */ /* 0x184 wimp_KEY_F4 */ 0,
/* 0x05 F5 */ /* 0x185 wimp_KEY_F5 */ 0,
/* 0x06 F6 */ /* 0x186 wimp_KEY_F6 */ 0,
/* 0x07 F7 */ /* 0x187 wimp_KEY_F7 */ 0,
/* 0x08 F8 */ /* 0x188 wimp_KEY_F8 */ 0,
/* 0x09 F9 */ /* 0x189 wimp_KEY_F9 */ 0,
/* 0x0a F10 */ /* 0x1ca wimp_KEY_F10 */ 0,
/* 0x0b F11 */ /* 0x1cb wimp_KEY_F11 */ 0,
/* 0x0c F12 */ /* 0x1cc wimp_KEY_F12 */ 0,
/* 0x0d Print/Sysrq */ /* 0x180 wimp_KEY_PRINT */ 0,
/* 0x0e Scrolllock */ 0  ,
/* 0x0f Break (esc) */ /* 0x1b */ 0 ,
/* 0x10 `¬¦ */ 0x60 ,
/* 0x11 1 */ 0x31 ,
/* 0x12 2 */ 0x32 ,
/* 0x13 3 */ 0x33 ,
/* 0x14 4 */ 0x34 ,
/* 0x15 5 */ 0x35 ,
/* 0x16 6 */ 0x36 ,
/* 0x17 7 */ 0x37 ,
/* 0x18 8 */ 0x38 ,
/* 0x19 9 */ 0x39 ,
/* 0x1a 0 */ 0x30 ,
/* 0x1b - */ 0x2d ,
/* 0x1c = */ 0x3d ,
/* 0x1d ?? PRM £ */ 0,
/* 0x1e backspace*/ wimp_KEY_BACKSPACE,
/* 0x1f Insert */ /* 0x1cd wimp_KEY_INSERT */ 0,
/* 0x20 Home */ /* 0x1e wimp_KEY_HOME */ MacHomeKey ,
/* 0x21 PgUp */ /* 0x19f wimp_KEY_PAGE_UP */ MacPageUpKey,
/* 0x22 NumLock */ 0  ,
/* 0x23 k-/ */ /* 0x2f */ 0,
/* 0x24 k-* */ /* 0x2a */ 0,
/* 0x25 k-#?? PRM*/ 0,
/* 0x26 */ /* 18a wimp_KEY_TAB */ 0x09,
/* 0x27 */ 0x71 ,
/* 0x28 */ 0x77 ,
/* 0x29 */ 0x65 ,
/* 0x2a */ 0x72 ,
/* 0x2b */ 0x74 ,
/* 0x2c */ 0x79 ,
/* 0x2d */ 0x75 ,
/* 0x2e */ 0x69 ,
/* 0x2f */ 0x6f ,
/* 0x30 */ 0x70 ,
/* 0x31 */ 0x5b ,
/* 0x32 */ 0x5d ,
/* 0x33 */ 0x23 ,
/* 0x34 */ /* 0x7f */ MacDeleteKey ,
/* 0x35 Copy */ /* 0x18b wimp_KEY_COPY */ MacEndKey,
/* 0x36 PgDn */ /* 19e wimp_KEY_PAGE_DOWN */ MacPageDownKey,
/* 0x37 k-7 */ /* 0x37 */ 0 ,
/* 0x38 k-8 */ /* 0x38 */ 0 ,
/* 0x39 k-9 */ /* 0x39 */ 0 ,
/* 0x3a k-- PRM */ /* 0x2d */ 0 ,
/* 0x3b LCTL */ 0  ,
/* 0x3c A */ 0x61 ,
/* 0x3d S */ 0x73 ,
/* 0x3e D */ 0x64 ,
/* 0x3f F */ 0x66 ,
/* 0x40 G */ 0x67 ,
/* 0x41 H */ 0x68 ,
/* 0x42 J */ 0x6a ,
/* 0x43 K */ 0x6b ,
/* 0x44 L */ 0x6c ,
/* 0x45 ;/: */ 0x3b ,
/* 0x46 '/@ gives " in sq */ 0x27 ,
/* 0x47 Return */ /* 0xd */ 0 ,
/* 0x48 k-4 */ /* 0x34 */ 0 ,
/* 0x49 k-5 */ /* 0x35 */ 0 ,
/* 0x4a k-6 */ /* 0x36 */ 0 ,
/* 0x4b k-+ */  /* 0x2b */ 0 ,
/* 0x4c LSHIFT */ 0  ,
/* 0x4d \/| */ 0x5c ,
/* 0x4e Z */ 0x7a ,
/* 0x4f X */ 0x78 ,
/* 0x50 C */ 0x63 ,
/* 0x51 V */ 0x76 ,
/* 0x52 B */ 0x62 ,
/* 0x53 N */ 0x6e ,
/* 0x54 M */ 0x6d ,
/* 0x55 ,/< */ 0x2c ,
/* 0x56 ./> */ 0x2e ,
/* 0x57 //? */ 0x2f ,
/* 0x58 RSHIFT */ 0  ,
/* 0x59 up */ /* 0x18f wimp_KEY_UP */ MacUpCursor,
/* 0x5a k-1 */ /* 0x31 */ 0 ,
/* 0x5b k-2 */ /* 0x32 */ 0 ,
/* 0x5c k-3 */ /* 0x33 */ 0,
/* 0x5d Capslock */ 0  ,
/* 0x5e LALT */ 0  ,
/* 0x5f Space */ 0x20 ,
/* 0x60 RALT */ 0  ,
/* 0x61 RCTL */ 0  ,
/* 0x62 left */ /* 0x18c wimp_KEY_LEFT */ MacLeftCursor,
/* 0x63 down */ /* 0x18e wimp_KEY_DOWN */ MacDownCursor,
/* 0x64 right */ /* 0x18d wimp_KEY_RIGHT */ MacRightCursor,
/* 0x65 k-0 */ /* 0x30 */ 0 ,
/* 0x66 k-. */ /* 0x2e */ 0 ,
/* 0x67 k-enter */ /* 0x0d */ 0
};


/*** Functions ***/
void			DisplayPixmap(wimp_draw * wblock);
extern void		DisplayModeChanged(void);
void			DoNothing(void);
int				HandleEvents(void);
void			KeyPressed( wimp_key * wblock);
void			KeyBufAppend(int key);
void			UserMessage(wimp_message * wblock);
void			MouseButtons( wimp_pointer * wblock);
void			PointerEnterWindow(wimp_entering *wblock);
void			PointerLeaveWindow(wimp_leaving *wblock);
void			WindowClose(wimp_close * wblock);
void			WindowOpen( wimp_open * wblock);
extern void		claimCaret(wimp_pointer * wblock);
extern void		receivedClaimEntity(wimp_message * wblock);
extern void		receivedDataRequest(wimp_message * wmessage);
extern void		receivedDataSave(wimp_message * wblock);
extern void		receivedDataSaveAck(wimp_message * wblock);
void			EventBufAppendKey( int key, int buttons, int x, int y, int windowIndex);
void			EventBufAppendMouse(int buttons, int modifiers, int x, int y, int windowIndex);
extern void		platReportError( os_error * e);
void			EventBufAppendWindow( int action, int left, int top, int right, int bottom,int windowIndex);

void setSocketPollFunction(int spf ) {
/* called from SocketPlugin init code */
	socketPollFunction = (void(*)(int, int))spf;
	PRINTF(( "\\t socketPoll %0x\n", (int)socketPollFunction));
}

void initialiseSoundPollword(void) {
// create an RMA allocationfor the sound pollword to live in
os_error *e;
	if (!soundPollWordPtr) {
		// we need to allocate some memory in RMA space and 0 it
		if ((e = xosmodule_alloc(4, (void **)&soundPollWordPtr)) != NULL) {
			// damn, failed
			platReportError(e);
			return;
		}
		*soundPollWordPtr = 0;
		PRINTF(("allocated pollword block %08X (%d)\n", (int)soundPollWordPtr, *soundPollWordPtr));
	}
}

void shutdownSoundPollword(void) {
// free the RMA space used for the sound pollword
os_error *e;
	if (soundPollWordPtr) {
		if ((e = xosmodule_free(soundPollWordPtr)) != NULL) {
			platReportError(e);
		};
		soundPollWordPtr = 0;
	}
	return;
}

int setupSoundSignalling(unsigned int ** addr, int * flagBit, int semIndex) {
// set the the sound buffer flagword address from an RMA allocation.
// set the bit in that flaword that the sound system should use (1 will do for now)
// we also have to keep track of the semaphore to signal when the pollword is
// triggered. For now, we'll use this fn to let the sound code tell us
// what it is
	if (addr == NULL) {
		// if the passed in addr is NULL, we're not polling anymore
		soundBufferEmptySemaphoreIndex = 0;
		return true;
	}

	if (!soundPollWordPtr) {
		// we were unabel to make the pollword RMA area, so fail
		return false;
	}
	// pass in the pollword ptr
	*addr = soundPollWordPtr;
	*flagBit = 1;
	soundBufferEmptySemaphoreIndex = semIndex;
	PRINTF(("setupSoundSignalling ptr: %08X sem: %d\n", soundPollWordPtr, soundBufferEmptySemaphoreIndex));
	return true;
}

void setMetaKeyOptions(int swap) {
	if (swap) {
		user_LCTL_KEY = wimp_DEEPKEY_RCTL;
		user_RCTL_KEY = wimp_DEEPKEY_LCTL;
	} else {
		user_LCTL_KEY = wimp_DEEPKEY_LCTL;
		user_RCTL_KEY = wimp_DEEPKEY_RCTL;
	}
}

/**************************/
/* Event handler routines */
/**************************/

void HandleMousePoll(void) {
/* for now we poll the mouse state and make up a mouse event if the
 * pointer has moved or the mouse button state has changed since last
 * time round.
 * This is very unsatisfactory by comparison to a proper mouse event system !
 * NB sets the GLOBAL state of buttonState and modifierState
 */
int kbdstate;
static int draggingWindow = false;
static unsigned int nextMousePollTick = 0;
unsigned int thisTick;
wimp_pointer wblock;
windowDescriptorBlock * thisWindow;
static windowDescriptorBlock * lastWindow = NULL;

	/* Don't mouse poll more than once every 5 milliseconds */
	if ( nextMousePollTick > (thisTick = ioMSecs())) return;
	nextMousePollTick = thisTick + 5;

	if ( mouseButtonDown || windowActive) {

		/* stash previous values */
		prevButtonState = buttonState;
		prevSavedMousePositionP.x = savedMousePositionP.x;
		prevSavedMousePositionP.y = savedMousePositionP.y;



		/* check for current state */
		xwimp_get_pointer_info( &wblock);
				buttonState = ((int)wblock.buttons &
				(wimp_CLICK_SELECT
				| wimp_CLICK_MENU
				| wimp_CLICK_ADJUST));
		/* need the window block with this handle */
		thisWindow = (windowDescriptorBlock *)
						windowBlockFromHandle(wblock.w);
		/* It is possible for thisWindow to be 0 - ie not one of ours.
		 * WTF do we do to work out a meaningful mouse pos?
		 * The plausible scenario is that some dragging (ie a mouse button
		 * down) has gone outside the window. Thus mouseButtonDown is true,
		 * windowActive will be false as soon as the leave event is processed
		 * and thisWindow will be 0. At this point we'd like to know the
		 * window that _was_ active so we can use it instead of thisWindow.
		 * While buttonDown is true we need to maintain the same window.
		 *
		 * It is possible for a MousePoll to hpapen before a leave is processed,
		 * (ie windowActive is improperly true) so we should check and ignore
		 * the mouse pos.
		 */
		if (!thisWindow ) {
			if (mouseButtonDown) {
				thisWindow = lastWindow;
			} else {
				return; // no event
			}
		}
		lastWindow = thisWindow; // save this one for next time round

		/* update mouseButtonDown */
		mouseButtonDown = buttonState>0?true:false;

		/* mouse pos & shift state */
		savedMousePositionP.x = OS2PixX(wblock.pos.x -
					thisWindow->visibleArea.x0);
		savedMousePositionP.y = OS2PixY(thisWindow->visibleArea.y1 -
					wblock.pos.y);
		modifierState = 0;
		xosbyte1(osbyte_SCAN_KEYBOARD , 0x80, 0, &kbdstate);
		if (kbdstate >0 ) modifierState = modifierState | ShiftKeyBit;
		xosbyte1(osbyte_SCAN_KEYBOARD , 0x84, 0, &kbdstate);
		if (kbdstate >0 ) modifierState = modifierState | CtrlKeyBit;
		xosbyte1(osbyte_SCAN_KEYBOARD , 0x87, 0, &kbdstate);
		if (kbdstate >0 ) modifierState = modifierState | CommandKeyBit;

		/* if the ctl or cmd key is held down there is a chance that
		 * we are trying to resize the window
		 */
		if ( (modifierState & (CommandKeyBit | CtrlKeyBit))
			&& (thisWindow)
			&& (wblock.i == (wimp_i)wimp_ICON_WINDOW)
			/* we are in our window and on the main icon */
			&& (prevButtonState == 0)
			&& (buttonState == RedButtonBit)
			/* and the red button is freshly pressed */
			&& (wblock.pos.x > (thisWindow->visibleArea.x1 - 15))
			/* and x@y is within 15 pixels of right@bottom corner */
			&& (wblock.pos.y <(thisWindow->visibleArea.y0 + 15))
			) {
			/* Phew - all those checks just to detect a size
			 *  dragging case.
			 * set windowActive false, draggingWindow true and
			 * start the UI window sizing operation
			 */
				extern void ResizeWindow(windowDescriptorBlock * window);
				mouseButtonDown = windowActive = false;
				draggingWindow = true;
				ResizeWindow(thisWindow);
				return;
		}

		/* compare prev to current */
		if ( (prevButtonState != buttonState)
			|| (prevSavedMousePositionP.x != savedMousePositionP.x)
			|| (prevSavedMousePositionP.y != savedMousePositionP.y)){
			EventBufAppendMouse(buttonState, modifierState,
				savedMousePositionP.x, savedMousePositionP.y, thisWindow->windowIndex);
			PRINTF(("\\tMouse Event %X (%X), %d@%d w: %d\n", buttonState,
				modifierState, savedMousePositionP.x,
				savedMousePositionP.y, thisWindow->windowIndex));
		}
	} else {
		/* see if we are doing a window resizing drag */
		if (draggingWindow ) {
			xwimp_get_pointer_info( &wblock);
			if ((int)wblock.buttons == 0) {
				/* stopped dragging so restore windowActive */
				windowActive = true;
				draggingWindow = false;
			}
		}
	}
}

int HandleSingleEvent(wimp_block *pollBlock, wimp_event_no pollEvent) {
/* handle a single event as defined by wblock
 * return false to stop the looping, true to continue it
 */
	switch ( pollEvent ) {
		case wimp_NULL_REASON_CODE:
			/* null means no more interesting events,
			   so return false*/
			return false ; break;
		case wimp_REDRAW_WINDOW_REQUEST:
			PRINTF(("\\t display\n"));
			DisplayPixmap(&(pollBlock->redraw));
			break;
		case wimp_OPEN_WINDOW_REQUEST:
			WindowOpen(&(pollBlock->open));
			break;
		case wimp_CLOSE_WINDOW_REQUEST:
			WindowClose(&(pollBlock->close));
			break;
		case wimp_POINTER_LEAVING_WINDOW:
			PointerLeaveWindow(&(pollBlock->leaving));
			break;
		case wimp_POINTER_ENTERING_WINDOW:
			PointerEnterWindow(&(pollBlock->entering));
			break;
		case wimp_MOUSE_CLICK:
			MouseButtons(&(pollBlock->pointer));
			break;
		case wimp_USER_DRAG_BOX:
			DoNothing();
			break;
		case wimp_KEY_PRESSED:
			KeyPressed( &(pollBlock->key));
			break;
		case wimp_MENU_SELECTION:
			DoNothing();
			break;
		case wimp_SCROLL_REQUEST:
			DoNothing();
			break;
		case wimp_USER_MESSAGE:
			UserMessage(&(pollBlock->message));
			break;
		case wimp_USER_MESSAGE_RECORDED:
			UserMessage(&(pollBlock->message));
			break;
		case wimp_USER_MESSAGE_ACKNOWLEDGE:
			UserMessage(&(pollBlock->message));
			break;
	}
	return true;
}

int HandleSocketPoll(int microSecondsToDelay) {
/* if the socket polling function has been set, call it to see
 * if any socket work needs doing
 */
	if(socketPollFunction) {
		socketPollFunction(microSecondsToDelay, 0);
	}
}

int HandleSoundPoll(void) {
// if there is a sound semaphore set up and a non-0 sound pollword address and the sound pollword
// has been tickled, 0 out the pollword and signal the semaphore
	if ( soundBufferEmptySemaphoreIndex && (int)soundPollWordPtr) {
		int pollwd;
		pollwd = *soundPollWordPtr;
PRINTF(("HandleSoundPoll: %d\n", pollwd));
		if (pollwd) {
			*soundPollWordPtr = 0;
			signalSemaphoreWithIndex(soundBufferEmptySemaphoreIndex);
			PRINTF(("signal sound semaphore:%d pollword: %d\n", soundBufferEmptySemaphoreIndex, pollwd));
		}
	}
}

#if 0
/* this is pretty much obsolete - we can't do microsecond delays and
 * anything longer just slows Squeak down horribly */
int HandleEventsWithWait(int microSecondsToDelay) {
/* use wimp_poll_delay so that we don't return a null before
 * the end of the delay, thus giving some cpu back to everyone else
 * NB - RISC OS uses centi-Seconds for delays etc.
 */
int pollDelay, nextWakeTick, currentTick;
extern int getNextWakeupTick(void);
	pollDelay = microSecondsToDelay /* * CLOCKS_PER_SEC / 1000000 */
			>> 14 /* will always give small answer, but good enough */;
	if ( microSecondsToDelay ) {
		pollDelay = MAX(pollDelay, 1);
		/* makes sure we get at least one tick of delay
		 * unless there is an alarm waiting  */
	}
	/* This is a touch confusing;
	 * if nWT <= cT then either there is a rollover to consider  or there
	 * is no wakeup set.
	 * if nWT > cT, then try to make sure the delay does not exceed the
	 * time until that wakeup
	 */
	nextWakeTick = getNextWakeupTick();
	currentTick  = (ioMSecs() & 0x1fffffff);
	if (nextWakeTick <= currentTick) {
		if ( nextWakeTick != 0) {
			pollDelay = 0;
		}
	} else {
		pollDelay = (nextWakeTick - currentTick ) / 10 * pollDelay;
	}
	//PRINTF(("\\t HandleEventsWithWait %d\n", pollDelay));
	HandleMousePoll();
	HandleSocketPoll(microSecondsToDelay);
	do { xwimp_poll_idle(wimp_MASK_POLLWORD
		| wimp_MASK_GAIN
		| wimp_MASK_LOSE
		| wimp_SAVE_FP) ,
		&wimpPollBlock,
		(os_t)pollDelay,
		&wimpPollWord,
		(wimp_event_no*)&wimpPollEvent);
	} while(HandleSingleEvent(&wimpPollBlock, wimpPollEvent));
}
#endif

int HandleEvents(void) {
/* track buttons and pos, send event if any change */
	HandleMousePoll();
	HandleSocketPoll(0);
	HandleSoundPoll();
	//PRINTF(("\\t HandleEvents\n"));
	/* One poll to bring them all.
	 * One poll to find them.
	 * One poll to to bring them all
	 * and in the do loop, bind them */
	do {xwimp_poll((wimp_MASK_POLLWORD
		| wimp_MASK_GAIN
		| wimp_MASK_LOSE
		| wimp_SAVE_FP) ,
		&wimpPollBlock,
		&wimpPollWord,
		(wimp_event_no*)&wimpPollEvent);
	} while (HandleSingleEvent(&wimpPollBlock, wimpPollEvent));
}


int HandleEventsNotTooOften(void) {
/* If we are using the older style polling stuff, we typically end up
 * calling HandleEvents an awful lot of times. Since at least 3/4 of
 * those times are redundant, throttle it back a little */
static int nextPollTick = 0;
unsigned int thisTick;
	if ( nextPollTick > (thisTick = ioMSecs())) return false;
	HandleEvents();
	nextPollTick = thisTick +5;
	return true;
}

/****************************************/
/* Routines to handle the actual events */
/****************************************/

void WindowOpen( wimp_open * wblock) {
windowDescriptorBlock * thisWindow;
/* window open events are used to open windows (duh) and when they have
 * been moved, brought to front, de-iconised, screen-redrawn etc.
 * Re-establish the window visible area values. */
	/* need the window block with this handle */
	thisWindow = windowBlockFromHandle(wblock->w);

	wblock->xscroll = 0;
	wblock->yscroll = 0;
	if (thisWindow->visibleArea.x0 != wblock->visible.x0
		|| thisWindow->visibleArea.y0 != wblock->visible.y0
		|| thisWindow->visibleArea.x1 != wblock->visible.x1
		|| thisWindow->visibleArea.y1 != wblock->visible.y1) {
		EventBufAppendWindow( WindowEventMetricChange,
			OS2PixX(wblock->visible.x0),
			screenSizeP.y - OS2PixY(wblock->visible.y1),
			OS2PixX(wblock->visible.x1),
			screenSizeP.y - OS2PixY(wblock->visible.y0),
			thisWindow->windowIndex);
		PRINTF(("\\t WindowOpen - new size: %d@%d ex: %d@%d\n",
			OS2PixX(wblock->visible.x0),
			screenSizeP.y - OS2PixY(wblock->visible.y1),
			OS2PixX(wblock->visible.x1),
			screenSizeP.y - OS2PixY(wblock->visible.y0)));
	}
	/* save the new visible area */
	thisWindow->visibleArea.x0 = wblock->visible.x0;
	thisWindow->visibleArea.y0 = wblock->visible.y0;
	thisWindow->visibleArea.x1 = wblock->visible.x1;
	thisWindow->visibleArea.y1 = wblock->visible.y1;
	xwimp_open_window(wblock);
}

void WindowClose(wimp_close * wblock) {
/* What to do with multiple windows?
 * Do dialogue only on last remaining one?
 */
os_error e;
int windowIndex;
extern char sqTaskName[];
	if ((windowIndex = windowIndexFromHandle(wblock->w)) >1 ) {
		EventBufAppendWindow( WindowEventClose, 0, 0, 0, 0, windowIndex);
		PRINTF(("\\t close window event: %d\n", windowIndex));
		return;
	}
	e.errnum = 0;
	sprintf(e.errmess, "Really quit %s?", sqTaskName);
	if (wimp_report_error( &e, wimp_ERROR_BOX_OK_ICON |
		wimp_ERROR_BOX_CANCEL_ICON |
		 wimp_ERROR_BOX_HIGHLIGHT_CANCEL |
		 wimp_ERROR_BOX_SHORT_TITLE ,
		 sqTaskName) == wimp_ERROR_BOX_SELECTED_OK) {;
			PointerLeaveWindow((wimp_leaving *)wblock);
			xwimp_close_window(wblock->w);
			exit(0);
	}
}

void PointerLeaveWindow(wimp_leaving *wblock) {
/* the pointer has left my area. swap to normal desktop pointer */
	xwimp_set_pointer_shape(1, (byte const *)-1,
		0, 0, 0, 0);
	windowActive = false;
}

void PointerEnterWindow(wimp_entering *wblock) {
/* the pointer has moved into my area. swap to my pointer pixmap */
	xwimp_set_pointer_shape(2, (byte const *)pointerBuffer,
		16, 16, pointerOffset.x, pointerOffset.y);
	windowActive = true;
}

void MouseButtons( wimp_pointer * wblock) {
/* deal with a mouse button change event
 * RiscOS only seems to send me mouse downs, and we have to manually claim
 * input focus with a wimp_BUTTON_CLICK window type
 * Right now we DO NOT use the click info to generate squeak mouse events
 * - we poll in HandleMousePoll()
 */
windowDescriptorBlock * thisWindow;

	if ( wblock->w == wimp_ICON_BAR ) {
		if ((wblock->buttons == wimp_CLICK_SELECT)) {
		/* select-click on iconbar icon means bring window to front
		 * - but what if we have multiple windows?  */
		extern void SetWindowToTop(int windowIndex);
			SetWindowToTop(1);
			return;
		}
		if (wblock->buttons == wimp_CLICK_MENU) {
			/* sometime get the menu stuff to work */
			return;
		}
	}

	/* need the window block with this handle */
	thisWindow = (windowDescriptorBlock *)windowBlockFromHandle(wblock->w);
	if ( thisWindow
		&& (wblock->i == (wimp_i)wimp_ICON_WINDOW)) {
		PRINTF(("\\t buttons %x w: %d\n", wblock->buttons, thisWindow->windowIndex));
		/* claim caret via message_claimentity() iff we
		 *don't already have it */
		claimCaret(wblock);
		/* do we still use wimp_set_caret_position ?  */
		xwimp_set_caret_position(wblock->w,
			(wimp_i)wimp_ICON_WINDOW, 0, 0, (1<<25)|255, 0);
		return;
	}
}

void KeyPressed( wimp_key * wblock) {
/* deal with a keypress. This is complicated by the RiscOS habit of "helpfully"
 * converting keycodes into fully processed key events. We do not even get
 * notification of most alt presses, for example. We also have to convert to
 * Mac numbering in order to satisfy the image code
 */
wimp_deepkey * dblock;
int keystate, dkey, modState, thisWindowIndex;

	dblock = (wimp_deepkey *)wblock;

	/* need the window block with this handle */
	thisWindowIndex = windowIndexFromHandle(wblock->w);
	if (!thisWindowIndex) return;
	/* if not one of our windows, no event. Keypresses keep the window id
	 * of the active/focused window event when the nouse is outside.
	 * Just to add to the confusion. */

	/* initially keystate will be the event's idea of the key pressed */
	keystate = dblock->c;
	if (keystate == getInterruptKeycode()
		|| ( (keystate == wimp_KEY_PRINT)) ) {
		/* The image tends to set the interruptKeycode to suit the Mac
		 * cmd-. nonsense - this is decidedly not Acorn compatible, so
		 * check for printscrn/SysRq as well
		 * interrupt is a meta-event; do not report it as a keypress
		 */
		setInterruptPending(true);
		forceInterruptCheck();
		return;
	}

	/* derive the modifier key state */
	dkey = dblock->deepkey;

	modState = (dkey & (wimp_DEEPKEY_LSHIFT
		| wimp_DEEPKEY_RSHIFT)) ? ShiftKeyBit: 0;
	/* Damn! can't use ALT for the Command key since we don't get
	 * keypress events for most alt-keys. Use previous plan of
	 * left ctl = Control & right ctl = Command unless user has
	 * specified -swapmeta. In which case, swap the meta keys around.
	 */
	if (dkey & (user_LCTL_KEY /* wimp_DEEPKEY_LCTL */))
		modState |= CtrlKeyBit;
	if (dkey & (user_RCTL_KEY /* wimp_DEEPKEY_RCTL */))
		modState |= CommandKeyBit;

	if ( modState > ShiftKeyBit ) {
		/* if a metakey is pressed, try looking up the magic number
		 * and dealing with a metakey situation
		 * if a key maps, replace the keystate with the result
		 */
		unsigned int testkey = (dblock->deepkey)
					>>wimp_DEEPKEY_KEYNUMSHIFT;
		if ((testkey <= 0x67) && (testkey = keymap[testkey]) )
			keystate = testkey;
	} else {
		/* no metakey, so check for special key values. */
		switch(keystate) {
			case wimp_KEY_TAB: keystate = 0x09; break;
			case wimp_KEY_LEFT: keystate = MacLeftCursor; break;
			case wimp_KEY_RIGHT: keystate = MacRightCursor; break;
			case wimp_KEY_DOWN: keystate = MacDownCursor; break;
			case wimp_KEY_UP: keystate = MacUpCursor; break;
			case wimp_KEY_HOME: keystate = MacHomeKey; break;
			case wimp_KEY_COPY: keystate = MacEndKey; break;
			case wimp_KEY_DELETE: keystate = MacDeleteKey; break;
			case wimp_KEY_PAGE_UP: keystate = MacPageUpKey; break;
			case wimp_KEY_PAGE_DOWN: keystate = MacPageDownKey; break;
			default: break;
		}
	}
	if (inputSemaphoreIndex) {
		/* inputSem testing is the way we see if event type input is
		 * expected or not. Stupid way to do it */
		EventBufAppendKey(keystate, modState, savedMousePositionP.x, savedMousePositionP.y, thisWindowIndex);
	} else {
		KeyBufAppend(keystate | ((modState)<<8));
	}
	PRINTF(("\\t KeyPressed .c%c .d%x keystate(%d-%d) w: %d\n",
		 dblock->c,
		 (dblock->deepkey)>>wimp_DEEPKEY_KEYNUMSHIFT,
		 keystate, modState,
		 thisWindowIndex));
}

void UserMessage(wimp_message * wblock) {
/* Deal with user messages */
extern wimp_t Task_Handle;
	if( wblock->sender == Task_Handle) {
		/* it's me - do nothing */
		return;
	}
	switch( wblock->action) {
		case message_QUIT:		ioExit();
								break;
		case message_MODE_CHANGE: DisplayModeChanged();
								break;
		case message_WINDOW_INFO: ioIconiseWindow(wblock);
								break;
		case message_CLAIM_ENTITY: receivedClaimEntity(wblock);
								break;
		/* these are the two messages we respond to in order
		 * to initiate clipboard transactions
		 * DATA_REQUEST is another app asking for our clipboard
		 * and DATA_SAVE_ACK is part of the dance for giving
		 * it to them. Us asking for some outside clipboard
		 * can be found in c.sqRPCClipboard>fetchClipboard()
		 */
		case message_DATA_REQUEST: receivedDataRequest(wblock);
								break;
		case message_DATA_SAVE_ACK: receivedDataSaveAck(wblock);
								break;
		/* We _might_ sometime respond to DATA_LOAD & DATA_SAVE
		 * here in order to allow dropping of text files via the
		 * DropPlugin
		 */
		default: return;
	}
}


void DoNothing(void) {
/* do nothing at all, but make sure to do it quickly.
 * Primarily a breakpoint option */
}

/*****************************************************************************/
/* internal event handling - add to queues etc                               */
/*****************************************************************************/

void SignalInputEvent(void) {
/* Unused currently */
	PRINTF(("\\t SignalInputEvent\n"));
	if(inputSemaphoreIndex > 0)
		signalSemaphoreWithIndex(inputSemaphoreIndex);
}

/* Event buffer functions */
/* code stolen from ikp's unix code. blame him if it doesn't work.
 * compliment me if it does.
 */

#define iebEmptyP()	(eventBufPut == eventBufGet)
#define iebAdvance(P)	(P= ((P + 1) % EVENTQ_SIZE))

sqInputEvent *EventBufAppendEvent(int  type) {
	sqInputEvent *evt= &eventBuf[eventBufPut];
	iebAdvance(eventBufPut);
	if (iebEmptyP()) {
		/* overrun: discard oldest event */
		iebAdvance(eventBufGet);
	}
	evt->type= type;
	evt->timeStamp= ioMSecs() & MillisecondClockMask;
	return evt;
}

void EventBufAppendKey( int keyValue, int modifiers, int x, int y, int windowIndex) {
/* add an event record for a keypress
 * add it three times - once for key down, once for the key pressed
 * and once for key up. Better if we could actually get the real events. */
sqKeyboardEvent *evt;
	evt = (sqKeyboardEvent *)EventBufAppendEvent( EventTypeKeyboard);
	evt->charCode = keyValue;
	evt->pressCode = EventKeyDown;
	evt->modifiers = modifiers;
	evt->utf32Code = keyValue; /* what Unicode ? */
	evt->reserved1 = 0;
	evt->windowIndex = windowIndex;
	evt = (sqKeyboardEvent *)EventBufAppendEvent( EventTypeKeyboard);
	evt->charCode = keyValue;
	evt->pressCode = EventKeyChar;
	evt->modifiers = modifiers;
	evt->utf32Code = keyValue; /* what Unicode ? */
	evt->reserved1 = 0;
	evt->windowIndex = windowIndex;
	evt = (sqKeyboardEvent *)EventBufAppendEvent( EventTypeKeyboard);
	evt->charCode = keyValue;
	evt->pressCode = EventKeyUp;
	evt->modifiers = modifiers;
	evt->utf32Code = keyValue; /* what Unicode ? */
	evt->reserved1 = 0;
	evt->windowIndex = windowIndex;
}

void EventBufAppendMouse( int buttons, int modifiers, int x, int y, int windowIndex) {
/* add an event record for a mouse press */
sqMouseEvent *evt;
/* if the previous event is a mouse event with the same buttons
 * we can overwrite it */
	if ( !iebEmptyP()) {
		int eventBufPrev;
		eventBufPrev = (eventBufPut == 0)?EVENTQ_SIZE-1: eventBufPut-1;
		evt = (sqMouseEvent *)&eventBuf[eventBufPrev];
		if ( (evt->buttons == buttons)
			&& (evt->modifiers == modifiers)) return;
	}
	evt = (sqMouseEvent *)EventBufAppendEvent( EventTypeMouse);
	evt->x = x;
	evt->y = y;
	evt->buttons = buttons;
	evt->modifiers = modifiers;
	evt->reserved1 = 0;
	evt->windowIndex = windowIndex;
}

void EventBufAppendWindow( int action, int left, int top, int right, int bottom,int windowIndex) {
/* add an event record for a keypress */
sqWindowEvent *evt;
	evt = (sqWindowEvent *)EventBufAppendEvent( EventTypeWindow);
	evt->action = action;
	evt->value1 = left;
	evt->value2 = top;
	evt->value3 = right;
	evt->value4 = bottom;
	evt->windowIndex = windowIndex;
}

/* key buffer functions to support older images */
void KeyBufAppend(int keystate) {
	keyBuf[keyBufPut] = keystate;
	keyBufPut = (keyBufPut + 1) % KEYBUF_SIZE;
	if (keyBufGet == keyBufPut) {
		keyBufGet = (keyBufGet + 1) % KEYBUF_SIZE;
		keyBufOverflows++;
	}
}

/*************************/
/* interface to interp.c */
/*************************/

/* retrieve the next input event from the OS */
sqInt ioGetNextEvent(sqInputEvent *evt) {
#ifdef DEBUG
	{static int once = 0;
		if ( once <1 ) {
			PRINTF(("\\t initial getEvent\n"));
			once = 1;
		}
	};
#endif
	if (iebEmptyP()) {
		HandleEvents();
		forceInterruptCheck(); /* handleevents can take a while */
	}
	if (iebEmptyP()) return false;
	*evt = eventBuf[eventBufGet];
	iebAdvance(eventBufGet);
// #ifdef DEBUG
// 	if (evt->type == EventTypeKeyboard) {
// 		PRINTF(("\\t key ev(%d) read %c\n", evt->timeStamp, ((sqKeyboardEvent *)evt)->charCode));
// 	}
// #endif
	return true;
}


/* set an asynchronous input semaphore index for events */
sqInt ioSetInputSemaphore(sqInt semaIndex) {
	PRINTF(("\\t ioSetInputSemaphore\n"));
	if( semaIndex < 1)
		return primitiveFail();
	inputSemaphoreIndex = semaIndex;
	return true;
}

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds) {
/* This operation is platform dependent. On the Mac, it simply calls
 * HandleEvents(), which gives other applications a chance to run.
 * Here, we use microSeconds as the parameter to HandleEvents, so that
 * wimpPollIdle gets a timeout.
 */
	//PRINTF(("\\t relinq %d\n", microSeconds));
	/* HandleEventsWithWait(microSeconds);   */
	HandleEvents();
	forceInterruptCheck();
	return microSeconds;
}


sqInt ioProcessEvents(void) {
/* This is called only from checkForInterrupts as a last resort
 * to make sure that IO polling is done at least occasionally no matter what
 * the image is up to. We don't force an interrupt check here because we're
 * in the middle of one already
 */
	HandleEvents();
	return true;
}

/* older polling state style access - completely unused by images after
 * about 3.6 */

sqInt nextKeyPressOrNil(void) {
/*  return the next keypress in the buffer, or -1 if nothing there */
int keystate;
	if (keyBufGet == keyBufPut) {
		return -1;  /* keystroke buffer is empty */
	} else {
		keystate = keyBuf[keyBufGet];
		keyBufGet = (keyBufGet + 1) % KEYBUF_SIZE;
	}
	return keystate;
}

sqInt peekKeyPressOrNil(void) {
/*  return the next keypress in the buffer, or -1 if nothing there */
int keystate;
	if (keyBufGet == keyBufPut) {
		return -1;  /* keystroke buffer is empty */
	} else {
		keystate = keyBuf[keyBufGet];
	}
	return keystate;
}
sqInt ioGetButtonState(void) {
	HandleEventsNotTooOften();  /* process all pending events */
	return buttonState;
}

sqInt ioGetKeystroke(void) {
	HandleEventsNotTooOften();  /* process all pending events */
	return nextKeyPressOrNil();
}

sqInt ioMousePoint(void) {
/* return the mouse point as 16bits of x | 16bits of y */
	HandleEventsNotTooOften();  /* process all pending events */
	return (savedMousePositionP.x << 16 | savedMousePositionP.y & 0xFFFF);
}

sqInt ioPeekKeystroke(void) {
	HandleEventsNotTooOften();  /* process all pending events */
	return peekKeyPressOrNil();
}


