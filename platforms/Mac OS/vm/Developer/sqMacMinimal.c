/* sqMacMinimal.c

	This file includes the minimal support code to build a Squeak virtual machine for
	the Mac. Most primitives are "stubbed-out", meaning that if they are invoked from
	the image they will return a "primitive failed" error. Among the stubbed out
	primitives are those that support sound input and output, serial and MIDI ports,
	networking, ,file directory operations, etc. The basic file read/write operations
	are NOT stubbed out, although they could be as long as the image loading mechanism
	still works.

	The purpose of this file is to provide an implementation roadmap when bootstrapping
	Squeak on a new platform. Once all the non-stubbed-out functions in this file have
	been ported, you will have a working, usable Squeak virtual machine!

*** Implementation Notes ***

  I/O Functions
	The following are essential for display and user interaction:
		ioScreenSize()
		ioShowDisplay()
		ioGetButtonState()
		ioGetKeystroke()
		ioMousePoint()
		ioPeekKeystroke()

	The following can be made no-ops:
		ioProcessEvents() 	-- poll for input events on some platforms
		ioSetCursor()		-- install a 16x16 black and white hardware cursor
		ioSetCursorWithMask() -- install a masked black and white hardware cursor
		ioBeep()			-- sound a short beep through the speaker
		ioExit()			-- exit the VM: quit the application, reboot, power down, or
							-- similar behavior appropriate to this platform (if this
							-- is a noop you simply won't be able to quit from Squeak)

  File Naming

	The virtual machine keeps track of the full path name of the Squeak image
	file and the path to the directory containing the virtual machine. In this
	minimal implementation, the VM path is the empty string and the image name is
	hardwired to "squeak.image". It is assumed that the image file, the changes
	file, the Squeak application, and the system sources file are all in the
	the same directory, and that this directory is the default working directory
	for any file operations.

  Time Functions

		ioMSecs(), ioMicroMSecs()
							-- both return a millisecond clock value, but historically
							-- ioMicroMSecs() used a higher resolution timer; the
							-- ideal implementation is an inexpensive clock with 1
							-- millisecond accuracy, but both functions can use a
							-- clock with much coarser accuracy (e.g., 50-100 mSecs)
							-- if necessary
		ioSeconds()			-- returns the number of seconds since Jan 1, 1901.
	   						-- optional: may be implemented to always return 0, but then
	   						-- the current date and time will be wrong

*** Linking ***

	To build a Macintosh VM using this file, link together:

		interp.c		-- automatically generated interpreter file
		sqMiscPrims.c	-- automatically generated primitives
		sqMacMinimal.c	-- this file

	plus the appropriate C libraries (e.g. math, strings, standard I/O).
	
	The interpreter code depends on the following functions from libraries:

	    math: exp(), log(), atan(), sin(), sqrt(), ldexp(), frexp(), modf()
	    standard i/o: getchar(), putchar(), printf()
	    other: memcpy(), strlen(), clock()

	The standard i/o functions could be stubbed out; they are only used to report
	fatal VM errors.
*/

#include <Devices.h>
#include <Fonts.h>
#include <Strings.h>
#include <Timer.h>
#include <ToolUtils.h>

#include "sq.h"
#include "FilePlugin.h"

/*** Mac Toolbox Function that is Missing from Standard Header Files ***/
void ExitToShell(void);

/*** Stub Definitions ***/
#define STUBBED_OUT { success(false); }
#define DO_NOTHING { }

/*** Enumerations ***/
enum { appleID = 1, fileID };
enum { quitItem = 1 };

/*** Variables -- Imported from Virtual Machine ***/
extern int interruptCheckCounter;
extern int interruptKeycode;
extern int interruptPending;  /* set to true by RecordKeystroke if interrupt key is pressed */

/*** Variables -- image and path names ***/
#define IMAGE_NAME_SIZE 300
char imageName[IMAGE_NAME_SIZE + 1];  /* full path to image */

#define SHORTIMAGE_NAME_SIZE 100
char shortImageName[SHORTIMAGE_NAME_SIZE + 1];  /* just the image file name */

#define VMPATH_SIZE 300
char vmPath[VMPATH_SIZE + 1];  /* full path to interpreter's directory */

/*** Variables -- Mac Related ***/
MenuHandle		appleMenu = nil;
MenuHandle		fileMenu = nil;
CTabHandle		stColorTable = nil;
PixMapHandle	stPixMap = nil;
WindowPtr		stWindow = nil;

/*** Variables -- Event Recording ***/
#define KEYBUF_SIZE 64
int keyBuf[KEYBUF_SIZE];	/* circular buffer */
int keyBufGet = 0;			/* index of next item of keyBuf to read */
int keyBufPut = 0;			/* index of next item of keyBuf to write */
int keyBufOverflows = 0;	/* number of characters dropped */

int buttonState = 0;		/* mouse button and modifier state when mouse
							   button went down or 0 if not pressed */

/* This table maps the 5 Macintosh modifier key bits to 4 Squeak modifier
   bits. (The Mac shift and caps lock keys are both mapped to the single
   Squeak shift bit).
		Mac bits: <control><option><caps lock><shift><command>
		ST bits:  <command><option><control><shift>
*/
char modifierMap[32] = {
	0,  8, 1,  9, 1,  9, 1,  9, 4, 12, 5, 13, 5, 13, 5, 13,
	2, 10, 3, 11, 3, 11, 3, 11, 6, 14, 7, 15, 7, 15, 7, 15
};

/*** Functions ***/
char * GetAttributeString(int id);
int  HandleEvents(void);
void HandleMenu(int mSelect);
void HandleMouseDown(EventRecord *theEvent);
void InitMacintosh(void);
int RecordKeystroke(EventRecord *theEvent);
int RecordModifierButtons(EventRecord *theEvent);
int RecordMouseDown(EventRecord *theEvent);
void SetColorEntry(int index, int red, int green, int blue);
void SetUpMenus(void);
void SetUpPixmap(void);
void SetUpWindow(void);

/*** Mac-specific Functions (these would be replaced on another platform) ***/

int HandleEvents(void) {
	EventRecord		theEvent;
	int				ok;

	SystemTask();
	ok = GetNextEvent(everyEvent, &theEvent);
	if (ok) {
		switch (theEvent.what) {
			case mouseDown:
				HandleMouseDown(&theEvent);
				return false;
			break;

			case mouseUp:
				RecordModifierButtons(&theEvent);
				return false;
			break;

			case keyDown:
			case autoKey:
				RecordModifierButtons(&theEvent);
				RecordKeystroke(&theEvent);
			break;

			case updateEvt:
				BeginUpdate(stWindow);
				fullDisplayUpdate();  /* this makes VM call ioShowDisplay */
				EndUpdate(stWindow);
			break;

			case activateEvt:
				InvalRect(&stWindow->portRect);
			break;
		}
	}
	return ok;
}

void HandleMenu(int mSelect) {
	if ((HiWord(mSelect) == fileID) &&
		(LoWord(mSelect) == quitItem)) {
		ioExit();
	}
}

void HandleMouseDown(EventRecord *theEvent) {
	WindowPtr	theWindow;
	Rect		growLimits = { 20, 20, 4000, 4000 };
	Rect		dragBounds;
	int			windowCode, newSize;

	windowCode = FindWindow(theEvent->where, &theWindow);
	switch (windowCode) {
		case inSysWindow:
			SystemClick(theEvent, theWindow);
		break;

		case inMenuBar:
			HandleMenu(MenuSelect(theEvent->where));
		break;

		case inDrag:
			dragBounds = qd.screenBits.bounds;
			if (theWindow == stWindow) {
				DragWindow(stWindow, theEvent->where, &dragBounds);
			}
		break;

		case inGrow:
			if (theWindow == stWindow) {
				newSize = GrowWindow(stWindow, theEvent->where, &growLimits);
				if (newSize != 0) {
					SizeWindow(stWindow, LoWord(newSize), HiWord(newSize), true);
				}
			}
		break;

		case inContent:
			if (theWindow == stWindow) {
				if (theWindow != FrontWindow()) {
					SelectWindow(stWindow);
				}
				RecordMouseDown(theEvent);
			}
		break;
	}
}

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
	SetUpMenus();
	SetUpWindow();
	SetUpPixmap();
}

void SetUpMenus(void) {
	InsertMenu(appleMenu = NewMenu(appleID, "\p\024"), 0);
	InsertMenu(fileMenu  = NewMenu(fileID,  "\pFile"), 0);
	DrawMenuBar();
	AppendResMenu(appleMenu, 'DRVR');
	AppendMenu(fileMenu, "\pQuit");
}

void SetColorEntry(int index, int red, int green, int blue) {
	(*stColorTable)->ctTable[index].value = index;
	(*stColorTable)->ctTable[index].rgb.red = red;
	(*stColorTable)->ctTable[index].rgb.green = green;
	(*stColorTable)->ctTable[index].rgb.blue = blue;
}

void SetUpPixmap(void) {
	int i, r, g, b;

	stColorTable = (CTabHandle) NewHandle(sizeof(ColorTable) + (256 * sizeof(ColorSpec)));
	(*stColorTable)->ctSeed = GetCTSeed();
	(*stColorTable)->ctFlags = 0;
	(*stColorTable)->ctSize = 255;

	/* 1-bit colors (monochrome) */
	SetColorEntry(0, 65535, 65535, 65535);	/* white or transparent */
	SetColorEntry(1,     0,     0,     0);	/* black */

	/* additional colors for 2-bit color */
	SetColorEntry(2, 65535, 65535, 65535);	/* opaque white */
	SetColorEntry(3, 32768, 32768, 32768);	/* 1/2 gray */

	/* additional colors for 4-bit color */
	SetColorEntry( 4, 65535,     0,     0);	/* red */
	SetColorEntry( 5,     0, 65535,     0);	/* green */
	SetColorEntry( 6,     0,     0, 65535);	/* blue */
	SetColorEntry( 7,     0, 65535, 65535);	/* cyan */
	SetColorEntry( 8, 65535, 65535,     0);	/* yellow */
	SetColorEntry( 9, 65535,     0, 65535);	/* magenta */
	SetColorEntry(10,  8192,  8192,  8192);	/* 1/8 gray */
	SetColorEntry(11, 16384, 16384, 16384);	/* 2/8 gray */
	SetColorEntry(12, 24576, 24576, 24576);	/* 3/8 gray */
	SetColorEntry(13, 40959, 40959, 40959);	/* 5/8 gray */
	SetColorEntry(14, 49151, 49151, 49151);	/* 6/8 gray */
	SetColorEntry(15, 57343, 57343, 57343);	/* 7/8 gray */

	/* additional colors for 8-bit color */
	/* 24 more shades of gray (does not repeat 1/8th increments) */
	SetColorEntry(16,  2048,  2048,  2048);	/*  1/32 gray */
	SetColorEntry(17,  4096,  4096,  4096);	/*  2/32 gray */
	SetColorEntry(18,  6144,  6144,  6144);	/*  3/32 gray */
	SetColorEntry(19, 10240, 10240, 10240);	/*  5/32 gray */
	SetColorEntry(20, 12288, 12288, 12288);	/*  6/32 gray */
	SetColorEntry(21, 14336, 14336, 14336);	/*  7/32 gray */
	SetColorEntry(22, 18432, 18432, 18432);	/*  9/32 gray */
	SetColorEntry(23, 20480, 20480, 20480);	/* 10/32 gray */
	SetColorEntry(24, 22528, 22528, 22528);	/* 11/32 gray */
	SetColorEntry(25, 26624, 26624, 26624);	/* 13/32 gray */
	SetColorEntry(26, 28672, 28672, 28672);	/* 14/32 gray */
	SetColorEntry(27, 30720, 30720, 30720);	/* 15/32 gray */
	SetColorEntry(28, 34815, 34815, 34815);	/* 17/32 gray */
	SetColorEntry(29, 36863, 36863, 36863);	/* 18/32 gray */
	SetColorEntry(30, 38911, 38911, 38911);	/* 19/32 gray */
	SetColorEntry(31, 43007, 43007, 43007);	/* 21/32 gray */
	SetColorEntry(32, 45055, 45055, 45055);	/* 22/32 gray */
	SetColorEntry(33, 47103, 47103, 47103);	/* 23/32 gray */
	SetColorEntry(34, 51199, 51199, 51199);	/* 25/32 gray */
	SetColorEntry(35, 53247, 53247, 53247);	/* 26/32 gray */
	SetColorEntry(36, 55295, 55295, 55295);	/* 27/32 gray */
	SetColorEntry(37, 59391, 59391, 59391);	/* 29/32 gray */
	SetColorEntry(38, 61439, 61439, 61439);	/* 30/32 gray */
	SetColorEntry(39, 63487, 63487, 63487);	/* 31/32 gray */

	/* The remainder of color table defines a color cube with six steps
	   for each primary color. Note that the corners of this cube repeat
	   previous colors, but simplifies the mapping between RGB colors and
	   color map indices. This color cube spans indices 40 through 255.
	*/
	for (r = 0; r < 6; r++) {
		for (g = 0; g < 6; g++) {
			for (b = 0; b < 6; b++) {
				i = 40 + ((36 * r) + (6 * b) + g);
				if (i > 255) error("index out of range in color table compuation");
				SetColorEntry(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
			}
		}
	}

	stPixMap = NewPixMap();
	(*stPixMap)->pixelType = 0; /* chunky */
	(*stPixMap)->cmpCount = 1;
	(*stPixMap)->pmTable = stColorTable;
}

void SetUpWindow(void) {
	Rect windowBounds = {44, 8, 460, 640};

	stWindow = NewCWindow(
		0L, &windowBounds, "\p Squeak! ",
		true, documentProc, (WindowPtr) -1L, true, 0);
}

/*** Event Recording Functions ***/

int RecordKeystroke(EventRecord *theEvent) {
	/* record a keystroke in the keyboard buffer. */
	int keystate;

	/* keystate: low byte is the ascii character; next 4 bits are modifier bits */
	keystate =
		(modifierMap[(theEvent->modifiers >> 8) & 0x1F] << 8) |
		(theEvent->message & 0xFF);
	if (keystate == interruptKeycode) {
		/* Note: interrupt key is "meta"; it not reported as a keystroke */
		interruptPending = true;
		interruptCheckCounter = 0;
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

int RecordMouseDown(EventRecord *theEvent) {
	/* record that the mouse button has been pressed. */
	int stButtons;

	stButtons = 4;		/* red button by default */
	if ((theEvent->modifiers & optionKey) != 0) {
		stButtons = 2;	/* yellow button if option down */
	}
	if ((theEvent->modifiers & cmdKey) != 0) {
		stButtons = 1;	/* blue button if command down */
	}
	/* button state: low three bits are mouse buttons; next 4 bits are modifier bits */
	buttonState =
		(modifierMap[(theEvent->modifiers >> 8) & 0x1F] << 3) |
		(stButtons & 0x7);
}

int RecordModifierButtons(EventRecord *theEvent) {
	/* record the state of the mouse buttons and modifier keys. */
	int stButtons = 0;

	if (Button()) {
		stButtons = buttonState & 0x7;
	} else {
		stButtons = 0;
	}
	/* button state: low three bits are mouse buttons; next 4 bits are modifier bits */
	buttonState =
		(modifierMap[(theEvent->modifiers >> 8) & 0x1F] << 3) |
		(stButtons & 0x7);
}

/*** I/O Primitives ***/

int ioBeep(void) {
	/* optional; could be noop. play a beep through the speaker. */
	SysBeep(1000);
}

int ioExit(void) {
	/* optional; could be noop. exit from the Squeak application. */
	ExitToShell();
}

int ioForceDisplayUpdate(void) {
	/* does nothing on a Mac */
}

int ioGetButtonState(void) {
	/* return the state of the mouse and modifier buttons */
	ioProcessEvents();  /* process all pending events */
	return buttonState;
}

int ioGetKeystroke(void) {
	/* return the next keystroke from the buffer or -1 if the buffer is empty */
	int keystate;

	ioProcessEvents();  /* process all pending events */
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

int ioMicroMSecs(void) {
	/* millisecond clock based on microsecond timer (about 60 times slower than clock()!!) */
	/* Note: This function and ioMSecs() both return a time in milliseconds. The difference
	   is that ioMicroMSecs() is called only when precise millisecond resolution is essential,
	   and thus it can use a more expensive timer than ioMSecs, which is called frequently.
	   However, later VM optimizations reduced the frequency of calls to ioMSecs to the point
	   where clock performance became less critical, and we also started to want millisecond-
	   resolution timers for real time applications such as music. Thus, on the Mac, we've
	   opted to use the microsecond clock for both ioMSecs() and ioMicroMSecs(). */
	UnsignedWide microTicks;

	Microseconds(&microTicks);
	return (microTicks.lo / 1000) + (microTicks.hi * 4294967);
}

sqInt ioMSecs(void) {
	/* return a time in milliseconds for use in Delays and Time millisecondClockValue */
	/* Note: This was once a macro based on clock(); it now uses the microsecond clock for
	   greater resolution. See the comment in ioMicroMSecs(). */
	UnsignedWide microTicks;

	Microseconds(&microTicks);
	return (microTicks.lo / 1000) + (microTicks.hi * 4294967);
}

int ioMousePoint(void) {
	/* return the mouse point two 16-bit positive integers packed into a 32-bit integer */
	Point p;

	ioProcessEvents();  /* process all pending events */
	GetMouse(&p);
	return (p.h << 16) | (p.v & 0xFFFF);  /* x is high 16 bits; y is low 16 bits */
}

int ioPeekKeystroke(void) {
	/* return the next keystroke from the buffer or -1 if the buffer is empty; leave
	   the keystrok in the buffer. */
	int keystate;

	ioProcessEvents();  /* process all pending events */
	if (keyBufGet == keyBufPut) {
		return -1;  /* keystroke buffer is empty */
	} else {
		keystate = keyBuf[keyBufGet];
		/* set modifer bits in buttonState to reflect the last keystroke peeked at */
		buttonState = ((keystate >> 5) & 0xF8) | (buttonState & 0x7);
	}
	return keystate;
}

int ioProcessEvents(void) {
	/* process Macintosh events, checking for the interrupt key. Return
	   true if the interrupt key was pressed. This might simply do nothing
	   on some other platform.*/
	int maxPollsPerSec = 30;
	static clock_t nextPollTick = 0;

	if (clock() > nextPollTick) {
		/* time to process events! */
		while (HandleEvents()) {
			/* process all pending events */
		}

		/* wait a while before trying again */
		nextPollTick = clock() + (CLOCKS_PER_SEC / maxPollsPerSec);
	}
	return interruptPending;
}

double ioScreenScaleFactor(void) {
	return 1.0;
}

int ioScreenSize(void) {
	/* return the screen size as two positive 16-bit integers packed into a 32-bit integer */
	int w = 10, h = 10;

	if (stWindow != nil) {
		w = stWindow->portRect.right - stWindow->portRect.left;
		h = stWindow->portRect.bottom - stWindow->portRect.top;
	}
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

int ioSeconds(void) {
	/* return the time in seconds since midnight of Jan 1, 1901.  */
	/* optional: could simply return 0.  */

	struct tm timeRec;
	time_t time1904, timeNow;

	/* start of ANSI epoch is midnight of Jan 1, 1904 */
	timeRec.tm_sec   = 0;
	timeRec.tm_min   = 0;
	timeRec.tm_hour  = 0;
	timeRec.tm_mday  = 1;
	timeRec.tm_mon   = 0;
	timeRec.tm_year  = 4;
	timeRec.tm_wday  = 0;
	timeRec.tm_yday  = 0;
	timeRec.tm_isdst = 0;
	time1904 = mktime(&timeRec);

	timeNow = time(NULL);

	/* Squeak epoch is Jan 1, 1901, 3 non-leap years earlier than ANSI one */
	return (timeNow - time1904) + (3 * 365 * 24 * 60 * 60);
}

int ioSetCursor(int cursorBitsIndex, int offsetX, int offsetY) {
	/* old version; just call the new version. */
	ioSetCursorWithMask(cursorBitsIndex, nil, offsetX, offsetY);
}

int ioSetCursorWithMask(int cursorBitsIndex, int cursorMaskIndex, int offsetX, int offsetY) {
	/* Optional primitive; this could be defined to do nothing. */
	/* Set the 16x16 cursor bitmap. If cursorMaskIndex is nil, then make the mask the same as
	   the cursor bitmap. If not, then mask and cursor bits combined determine how cursor is
	   displayed:
			mask	cursor	effect
			 0		  0		transparent (underlying pixel shows through)
			 1		  1		opaque black
			 1		  0		opaque white
			 0		  1		invert the underlying pixel
	*/
	Cursor macCursor;
	int i;

	if (cursorMaskIndex == nil) {
		for (i = 0; i < 16; i++) {
			macCursor.data[i] = (checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFFFF;
			macCursor.mask[i] = (checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFFFF;
		}
	} else {
		for (i = 0; i < 16; i++) {
			macCursor.data[i] = (checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFFFF;
			macCursor.mask[i] = (checkedLongAt(cursorMaskIndex + (4 * i)) >> 16) & 0xFFFF;
		}
	}

	/* Squeak hotspot offsets are negative; Mac's are positive */
	macCursor.hotSpot.h = -offsetX;
	macCursor.hotSpot.v = -offsetY;
	SetCursor(&macCursor);
}

int ioShowDisplay(
	/* copy the given rectangular display region to the hardware display buffer. */
	int dispBitsIndex, int width, int height, int depth,
	int affectedL, int affectedR, int affectedT, int affectedB) {

	Rect		dstRect = { 0, 0, 0, 0 };
	Rect		srcRect = { 0, 0, 0, 0 };
	RgnHandle	maskRect = nil;

	if (stWindow == nil) {
		return;
	}

	dstRect.left	= 0;
	dstRect.top		= 0;
	dstRect.right	= width;
	dstRect.bottom	= height;

	srcRect.left	= 0;
	srcRect.top		= 0;
	srcRect.right	= width;
	srcRect.bottom	= height;

	(*stPixMap)->baseAddr = (void *) dispBitsIndex;
	/* Note: top three bits of rowBytes indicate this is a PixMap, not a BitMap */
	(*stPixMap)->rowBytes = (((((width * depth) + 31) / 32) * 4) & 0x1FFF) | 0x8000;
	(*stPixMap)->bounds = srcRect;
	(*stPixMap)->pixelSize = depth;
	(*stPixMap)->cmpSize = depth;

	/* create a mask region so that only the affected rectangle is copied */
	maskRect = NewRgn();
	SetRectRgn(maskRect, affectedL, affectedT, affectedR, affectedB);

	SetPort(stWindow);
	CopyBits((BitMap *) *stPixMap, &stWindow->portBits, &srcRect, &dstRect, srcCopy, maskRect);
	DisposeRgn(maskRect);
}

/*** VM Home Directory Path ***/

int vmPathSize(void) {
	/* return the length of the path string for the directory containing the VM. */
	return strlen(vmPath);
}

int vmPathGetLength(int sqVMPathIndex, int length) {
	/* copy the path string for the directory containing the VM into the given Squeak string. */
	char *stVMPath = (char *) sqVMPathIndex;
	int count, i;

	count = strlen(vmPath);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	for (i = 0; i < count; i++) {
		stVMPath[i] = vmPath[i];
	}
	return count;
}

/*** Image File Name ***/

int imageNameSize(void) {
	/* return the length of the Squeak image name. */
	return strlen(imageName);
}

int imageNameGetLength(int sqImageNameIndex, int length) {
	/* copy the Squeak image name into the given Squeak string. */
	char *sqImageName = (char *) sqImageNameIndex;
	int count, i;

	count = strlen(imageName);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	for (i = 0; i < count; i++) {
		sqImageName[i] = imageName[i];
	}
	return count;
}

int imageNamePutLength(int sqImageNameIndex, int length) {
	/* copy from the given Squeak string into the imageName variable. */
	char *sqImageName = (char *) sqImageNameIndex;
	int count, i, ch, j;
	int lastColonIndex = -1;

	count = (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

	/* copy the file name into a null-terminated C string */
	for (i = 0; i < count; i++) {
		ch = imageName[i] = sqImageName[i];
		if (ch == ':') {
			lastColonIndex = i;
		}
	}
	imageName[count] = 0;

	/* copy short image name into a null-terminated C string */
	for (i = lastColonIndex + 1, j = 0; i < count; i++, j++) {
		shortImageName[j] = imageName[i];
	}
	shortImageName[j] = 0;

	return count;
}

/*** Clipboard Support ***/

int clipboardReadIntoAt(int count, int byteArrayIndex, int startIndex) {
	/* return number of bytes read from clipboard; stubbed out. */
	return 0;
}

int clipboardSize(void) {
	/* return the number of bytes of data the clipboard; stubbed out. */
	return 0;
}

int clipboardWriteFromAt(int count, int byteArrayIndex, int startIndex) {
	/* write count bytes to the clipboard; stubbed out. */
	return 0;
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
	// id #1 should return imageName, but returns empty string in this release to
	// ease the transition (1.3x images otherwise try to read image as a document)
	if (id == 1) return "";  /* will be imageName */
	if (id == 2) return "";

	/* the following attributes describe the underlying platform: */
	if (id == 1001) return "Mac OS";
	if (id == 1002) return "System 7 or Later";
	if (id == 1003) return "PowerPC or 680xx";

	/* attribute undefined by this platform */
	success(false);
	return "";
}

int attributeSize(int id) {
	/* return the length of the given attribute string. */
	return strlen(GetAttributeString(id));
}

int getAttributeIntoLength(int id, int byteArrayIndex, int length) {
	/* copy the attribute with the given id into a Squeak string. */
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

/*** Image File Read/Write ***/

void * sqAllocateMemory(int minHeapSize, int desiredHeapSize) {
	/* allocate memory for Squeak object heap. */
	MaxBlock();
	return NewPtr(desiredHeapSize);
}

void sqImageFileClose(sqImageFile f) {
	FSClose(f);
}

sqImageFile sqImageFileOpen(char *fileName, char *mode) {
	short int err, err2, fRefNum;
	unsigned char *pascalFileName;

	pascalFileName = c2pstr(fileName);
	err = FSOpen(pascalFileName, 0, &fRefNum);
	if ((err != 0) && (strchr(mode, 'w') != null)) {
		/* creating a new file for "save as" */
		err2 = Create(pascalFileName, 0, 'FAST', 'STim');
		if (err2 == 0) {
			err = FSOpen(pascalFileName, 0, &fRefNum);
		}
	}
	p2cstr(pascalFileName);
	if (err != 0) return null;

	if (strchr(mode, 'w') != null) {
		/* truncate file if opening in write mode */
		err = SetEOF(fRefNum, 0);
		if (err != 0) {
			FSClose(fRefNum);
			return null;
		}
	}
	return (sqImageFile) fRefNum;
}

int sqImageFilePosition(sqImageFile f) {
	long int currentPosition = 0;

	GetFPos(f, &currentPosition);
	return currentPosition;
}

int sqImageFileRead(void *ptr, int elementSize, int count, sqImageFile f) {
	long int byteCount = elementSize * count;
	short int err;

	err = FSRead(f, &byteCount, ptr);
	if (err != 0) return 0;
	return byteCount / elementSize;
}

void sqImageFileSeek(sqImageFile f, int pos) {
	SetFPos(f, fsFromStart, pos);
}

int sqImageFileWrite(void *ptr, int elementSize, int count, sqImageFile f) {
	long int byteCount = elementSize * count;
	short int err;

	err = FSWrite(f, &byteCount, ptr);
	if (err != 0) return 0;
	return byteCount / elementSize;
}

/*** I/O Stubs ***/

int ioFormPrint(int bitsAddr, int width, int height,
	int depth, double hScale, double vScale, int landscapeFlag)				STUBBED_OUT
int ioHasDisplayDepth(int depth) 											STUBBED_OUT
int ioRelinquishProcessorForMicroseconds(int microSeconds)					DO_NOTHING
int ioSetDisplayMode(int width, int height, int depth, int fullscreenFlag)	DO_NOTHING
int ioSetFullScreen(int fullScreen) 										DO_NOTHING

/*** File I/0 Stubs ***/

sqInt sqFileAtEnd(SQFile *f)												STUBBED_OUT
sqInt sqFileClose(SQFile *f)												STUBBED_OUT
sqInt sqFileDeleteNameSize(char *sqFileName, sqInt sqFileNameSize)			STUBBED_OUT
squeakFileOffsetType sqFileGetPosition(SQFile *f)							STUBBED_OUT
sqInt sqFileInit(void)														{ return true; }
sqInt sqFileOpen(
  SQFile *f, char *sqFileName, sqInt sqFileNameSize, sqInt writeFlag)		STUBBED_OUT
size_t sqFileReadIntoAt(
  SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex)			STUBBED_OUT
sqInt sqFileRenameOldSizeNewSize(
  char *sqOldName, sqInt sqOldNameSize, char *sqNewName, sqInt sqNewNameSize)		STUBBED_OUT
sqInt sqFileSetPosition(SQFile *f, squeakFileOffsetType position)			STUBBED_OUT
squeakFileOffsetType sqFileSize(SQFile *f) { return 0; }
sqInt sqFileShutdown(void)													{ return 0; }
sqInt sqFileValid(SQFile *f)												STUBBED_OUT
size_t sqFileWriteFromAt(
  SQFile *f, size_t count, char *byteArrayIndex, size_t startIndex)			STUBBED_OUT

/*** Directory Stubs ***/

sqInt dir_Create(char *pathString, sqInt pathStringLength)					STUBBED_OUT
sqInt dir_Delimitor(void)														{ return ':'; }
sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
  sqInt *isDirectory, sqInt *sizeIfFile)									STUBBED_OUT
sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize,
  char *fType, char *fCreator)												DO_NOTHING
sqInt dir_Delete(char *pathString, sqInt pathStringLength)					STUBBED_OUT

/*** External Primitive Support (No-ops) ***/

int ioLoadModule(char *pluginName) { return 0; }
int ioFindExternalFunctionIn(char *lookupName, int moduleHandle) { return 0; }
int ioFreeModule(int moduleHandle) { return 0; }

/*** Main ***/

void main(void) {
	sqImageFile f;
	int availableMemory;

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
	sqFileInit();

	imageName[0] = shortImageName[0] = vmPath[0] = 0;
	strcpy(imageName, "squeak.image");
	strcpy(shortImageName, "squeak.image");

	/* compute the desired memory allocation */
	availableMemory = MaxBlock() - 50000;
	/******
	  Note: This is platform-specific. On the Mac, the user specifies the desired
	    memory partition for each application using the Finder's Get Info command.
	    MaxBlock() returns the amount of memory in that partition minus space for
	    the code segment and other resources. On other platforms, the desired heap
	    size would be specified in other ways (e.g, via a command line argument).
	    The maximum size of the object heap is fixed at at startup. If you run low
	    on space, you must save the image and restart with more memory.
		(We reserve 50K for Mac toolbox calls, the error console window, etc.
	******/

	/* read the image file and allocate memory for Squeak heap */
	f = sqImageFileOpen(imageName, "rb");
	if (f == NULL) {
		/* give a Mac-specific error message if image file is not found */
		printf("Could not open the Squeak image file '%s'\n\n", imageName);
		printf("In this minimal VM, the image file must be named 'squeak.image'\n");
		printf("and must be in the same directory as the Squeak application.\n");
		printf("Press the return key to exit.\n");
		getchar();
		printf("Aborting...\n");
		ioExit();
	}
	readImageFromFileHeapSizeStartingAt(f, availableMemory, 0);
	sqImageFileClose(f);

	/* run Squeak */
	interpret();
}
