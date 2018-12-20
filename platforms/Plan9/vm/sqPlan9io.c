/*
 * Squeak IO function implementations for Plan9.
 *
 * Author: Alex Franchuk (alex.franchuk@gmail.com)
 */

#include "sq.h"
#include "p9iface.h"

#define _PLAN9_SOURCE

#define EVT_BUFFER_SIZE 256

#include <draw.h>
#include <cursor.h>
#include <stdio.h>
#include <thread.h>
#include <mouse.h>
#include <keyboard.h>

static vlong          start_time;
static Point          mouse_position;
static int            mouse_button_state = 0;
static sqInputEvent   evts[EVT_BUFFER_SIZE];
static QLock 		  evt_buf_lock;
static int 			  evts_start = 0,
					  evts_end = 0;
static int            disp_prev_width,
					  disp_prev_height,
					  disp_prev_x,
					  disp_prev_y;
static int            eventThreadID = -1;
static Mousectl       *mousectl = NULL;
static Keyboardctl    *keyboardctl = NULL;

/**
 * @brief Convert unix time to Squeak time
 *
 * @param unixTime to to convert
 *
 * @return the time according to Squeak!
 */
time_t convertToSqueakTime(time_t unixTime)
{
	//Account for timezone
	unixTime += localtime(unixTime)->tzoff;
	/* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
		and 52 non-leap years later than Squeak. */
	return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
}

int timeInit(void) {
	start_time = nsec();
	return 0;
}

int ioInit(void) {
	mousectl = initmouse(NULL, screen);
	keyboardctl = initkeyboard(NULL);
	ctlkeyboard(keyboardctl, "rawon");
	return 0;
}

void ioDestroy(void) {
	if (eventThreadID != -1) {
		threadkill(eventThreadID);
	}
	closemouse(mousectl);
	closekeyboard(keyboardctl);
}

/* Time */
long ioMSecs(void) {
	vlong now = nsec();
	return (now - start_time)/1000000;
}

long ioMicroMSecs(void) { return ioMSecs(); }

sqInt ioSeconds(void) {
	return (sqInt)convertToSqueakTime(time(NULL));
}

/* Miscellaneous */
sqInt ioBeep(void) {
	printf("beep\n");
	return 0;
}

sqInt ioExit(void) {
	return ioExitWithErrorCode(0);
}

sqInt ioExitWithErrorCode(int code) {
	exit(0);
	return 0;
}

static int lastInterruptCheck = 0;
sqInt setInterruptCheckCounter(sqInt value);

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds) {
	yield();
	int now;
	now = ioMSecs();
	if (now - lastInterruptCheck > (1000/25)) {	/* avoid thrashing intr checks from 1ms loop in idle proc  */
		setInterruptCheckCounter(-1000);	/* ensure timely poll for semaphore activity */
		lastInterruptCheck = now;
	}
	return 0;
}

sqInt ioDisablePowerManager(sqInt disableIfNonZero) {
	return true;
}

/* Display */
sqInt ioForceDisplayUpdate(void) {
	flushimage(display,1);
	return true;
}

sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
		  double hScale, double vScale, sqInt landscapeFlag) {
	return 0;
}

sqInt ioSetFullScreen(sqInt fullScreen) {
	if (fullScreen) {
		ushort w = screen->r.max.x - screen->r.min.x;
		ushort h = screen->r.max.y - screen->r.min.y;
		disp_prev_x = screen->r.min.x;
		disp_prev_y = screen->r.min.y;
		disp_prev_width = w;
		disp_prev_height = h;
	}
	else {
		positionWindow(disp_prev_x, disp_prev_y);
	}
	return ioSetDisplayMode(disp_prev_width, disp_prev_height, screen->depth, fullScreen);
}

sqInt ioScreenSize(void) {
	ushort w = screen->r.max.x - screen->r.min.x;
	ushort h = screen->r.max.y - screen->r.min.y;
	return (w<<16)|h;
}

double ioScreenScaleFactor(void) {
	return 1.0;
}

sqInt ioScreenDepth(void) {
	return 32;
}

sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY) {
	uchar* cursorBits = (uchar*)pointerForOop(cursorBitsIndex);
	int i;
	Cursor c;
	c.offset.x = offsetX;
	c.offset.y = offsetY;
	for (i = 0; i < 16; i++) {
		c.clr[i*2] = 0;
		c.clr[i*2+1] = 0;
		c.set[i*2] = cursorBits[i*4+3];
		c.set[i*2+1] = cursorBits[i*4+2];
	}
	setcursor(mousectl, &c);
	return 0;
}

sqInt ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY) {
	uchar* cursorBits = (uchar*)pointerForOop(cursorBitsIndex);
	uchar* maskBits = (uchar*)pointerForOop(cursorMaskIndex);
	int i;
	Cursor c;
	c.offset.x = offsetX;
	c.offset.y = offsetY;
	for (i = 0; i < 16; i++) {
		c.clr[i*2] = (~cursorBits[i*4+3] & maskBits[i*4+3]);
		c.clr[i*2+1] = (~cursorBits[i*4+2] & maskBits[i*4+2]);
		c.set[i*2] = cursorBits[i*4+3];
		c.set[i*2+1] = cursorBits[i*4+2];
	}
	setcursor(mousectl, &c);
	return 0;
}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY) {
	//Not supported in Plan9
	return 0;
}

static void sqToP9Bits(uchar* sqBits, uchar* p9Bits, int width, int height,
		int left, int right, int top, int bottom) {
	int region_w = right-left;
	for (int y = top; y < bottom; y++)
		for (int x = left; x < right; x++) {
			p9Bits[((y-top)*region_w+(x-left))*3] = sqBits[(y*width+x)*4];
			p9Bits[((y-top)*region_w+(x-left))*3+1] = sqBits[(y*width+x)*4+1];
			p9Bits[((y-top)*region_w+(x-left))*3+2] = sqBits[(y*width+x)*4+2];
		}
}

sqInt ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB) {
	Rectangle r;
	r.min.x = affectedL;
	r.max.x = affectedR;
	r.min.y = affectedT;
	r.max.y = affectedB;
	ulong chan;
	uchar* dispBits = (uchar*)pointerForOop(dispBitsIndex);
	size_t region_w = affectedR-affectedL,
		   region_h = affectedB-affectedT;
	uchar* buf = (uchar*)malloc(region_w*region_h*3);
	if (buf == NULL)
		return 0;

	sqToP9Bits(dispBits, buf, width, height, affectedL, affectedR, affectedT, affectedB);

	switch (depth) {
		case 1:
			chan = GREY1;
			break;
		case 2:
			chan = GREY2;
			break;
		case 4:
			chan = CMAP8;
			break;
		case 8:
			chan = CMAP8;
			break;
		case 16:
			chan = RGB16;
			break;
		case 32:
			chan = RGB24;
			break;
		default:
			return -1;
	}
	Image* s = allocimage(display, r, chan, 0, DNofill);
	if (s == 0) {
		return -1;
	}
	Image* mask = allocimage(display, r, chan, 0, DOpaque);
	if (mask == 0) {
		freeimage(s);
		return -1;
	}

	loadimage(s, r, buf, region_w*region_h*3);

	Point e; e.x = 0; e.y = 0;
	draw(screen, screen->r, s, mask, e);

	freeimage(mask);
	freeimage(s);

	free(buf);

	return 0;
}

sqInt ioHasDisplayDepth(sqInt depth) {
	if (depth == 32)
		return 1;
	else return 0;
}

sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag) {
	if (fullscreenFlag) {
		Rectangle ssize = display->image->r;
		positionWindow(ssize.min.x,ssize.min.y);
		width = ssize.max.x - ssize.min.x - 1;
		height = ssize.max.y - ssize.min.y - 1;
	}
	resizeWindow(width,height);
	return 0;
}

/* Mouse/Keyboard */
sqInt ioGetButtonState(void) {
	int left = mouse_button_state & 1;
	int middle = (mouse_button_state & 2) >> 1;
	int right = (mouse_button_state & 4) >> 2;
	return RedButtonBit*left | YellowButtonBit*middle | BlueButtonBit*right;
}

sqInt ioMousePoint(void) {
	return ((mouse_position.x & 0xFFFF) << 16) | (mouse_position.y & 0xFFFF);
}

sqInt ioGetKeystroke(void) {
	int k = evts_start;
	while (k != evts_end) {
		if (evts[k].type == EventTypeKeyboard) {
			evts_start = (k+1) % EVT_BUFFER_SIZE;
			return ((sqKeyboardEvent)evts[k]).charCode;
		}
		k = (k+1) % EVT_BUFFER_SIZE;
	}
	return 0;
}

sqInt ioPeekKeystroke(void) {
	int k = evts_start;
	while (k != evts_end) {
		if (evts[k].type == EventTypeKeyboard) {
			return ((sqKeyboardEvent)evts[k]).charCode;
		}
		k = (k+1) % EVT_BUFFER_SIZE;
	}
	return 0;
}

/* Return 1 if values were set, or 0 if no charcode could be made */
static int splitRune(int rune, int* charCode, int* modifiers) {
	static int escapeNext = 0;
	*modifiers = 0;

	if (escapeNext) {
		*modifiers |= CommandKeyBit;
		escapeNext = 0;
	}
	//Escape key, next character should be Command-(key)
	else if (rune == 0x1) {
		escapeNext = 1;
		return 0;
	}

	*charCode = rune;
	return 1;
}

/* Retrieve pending events, and return the number of events */
static int getPendingEvents(void) {
	int count = 0;
	while (1) {
		Mouse mouse;
		Rune rune;
		int charCode, modifiers;
		int mouse_event = nbrecv(mousectl->c, (void*)&mouse);
		int resize_event = nbrecv(mousectl->resizec, NULL);
		int kbd_event = nbrecv(keyboardctl->c, (void*)&rune);
		
		if (mouse_event) {
			//Process mouse event
			mouse_position.x = mouse.xy.x - screen->r.min.x;
			mouse_position.y = mouse.xy.y - screen->r.min.y;
			mouse_button_state = mouse.buttons;
			qlock(&evt_buf_lock);
			if ((evts_end+2)%EVT_BUFFER_SIZE != evts_start) {
				sqMouseEvent* evt = (sqMouseEvent*)&evts[evts_end++];
				evts_end %= EVT_BUFFER_SIZE;
				evt->type = EventTypeMouse;
				evt->timeStamp = ioMSecs();
				evt->x = mouse_position.x;
				evt->y = mouse_position.y;
				evt->buttons = ioGetButtonState();
				evt->modifiers = 0;
				evt->reserved1 = evt->windowIndex = 0;
				count++;
			}
			qunlock(&evt_buf_lock);
		}

		if (resize_event) {
			getwindow(display, Refnone);
			fullDisplayUpdate();
		}

		if (kbd_event && splitRune(rune, &charCode, &modifiers)) {
			//Process keyboard event
			qlock(&evt_buf_lock);
			if ((evts_end+2)%EVT_BUFFER_SIZE != evts_start) {
				sqKeyboardEvent* evt = (sqKeyboardEvent*)&evts[evts_end++];
				evts_end %= EVT_BUFFER_SIZE;
				evt->type = EventTypeKeyboard;
				evt->timeStamp = ioMSecs();
				evt->pressCode = EventKeyChar;
				evt->charCode = charCode;
				evt->modifiers = modifiers;
				evt->reserved1 = evt->windowIndex = 0;
				count++;
			}
			qunlock(&evt_buf_lock);
		}
		if (!(resize_event || kbd_event || mouse_event))
			break;
	}
	return count;
}

void eventThread(void* data) {
	int evt_semaphore = (int)data;
	while (1) {
		int count = getPendingEvents();
		while (count--) {
			signalSemaphoreWithIndex(evt_semaphore);
		}
		yield();
	}
}

sqInt ioProcessEvents(void) {
	if (eventThreadID == -1)
		getPendingEvents();

	return 0;
}

sqInt ioSetInputSemaphore(sqInt semaIndex) {
	if (semaIndex == 0) {
		success(0);
	}
	else {
		//Initialize thread and mouse/keyboard
		eventThreadID = threadcreate(eventThread,(void*)semaIndex,2048);
	}
	return true;
}

sqInt ioGetNextEvent(sqInputEvent *evt) {
	qlock(&evt_buf_lock);
	if (evts_start == evts_end) {
		qunlock(&evt_buf_lock);
		ioProcessEvents();
		qlock(&evt_buf_lock);
	}

	if (evts_start != evts_end) {
		memcpy(evt, &evts[evts_start++], sizeof(sqInputEvent));
		evts_start %= EVT_BUFFER_SIZE;
		qunlock(&evt_buf_lock);
		return true;
	}
	qunlock(&evt_buf_lock);
	return false;
}

