/* sqUnixQuartz.m -- display via native windows on Mac OS X	-*- ObjC -*-
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 * Last edited: 2005-04-06 08:08:38 by piumarta on squeak.hpl.hp.com
 */


//xxx ...
// 
// check use of winRect and titleRect.  reduce to (int)winHeight and
// (int)titleHeight in setRects.
// 
// investigate creating sq events in the UI thread and then sending
// them down the notification pipe, instead of locking the event
// queue.


#import <Cocoa/Cocoa.h>

#include "sqUnixMain.h"
#include "sqUnixGlobals.h"

#include "sq.h"
#include "sqaio.h"

#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <pthread.h>
#include <sched.h>

#include "debug.h"

#include "config.h"
#undef HAVE_GL_GL_H
#include "SqDisplay.h"


/// 
/// Things you can tweak, if you're curious/bored enough to want to...
/// 

// do we draw the current screen extent (width x height) in the title
// bar during live resize?
// 
#define	RESIZE_IN_TITLE	 1

// how large a (square) area, in the lower right of the window, should
// respond to mouse down by initiating window resize?  (the resize
// icon itself is, when we allow it to be shown, 13x13 pixels.)
// 
#define	RESIZE_EXTENT	 8

// do we fade the screen out and back in gently when changing to
// fullscreen mode, or just switch with one big violent click?  if
// this is defined then it represents the incr/decrement per
// millisecond of the gamma multiplier (1.0 to 0.0 and back); if
// undefined then the switch is immediate.
// 
#undef	FULLSCREEN_FADE	 0.02

#ifdef PharoVM
# define VMOPTION(arg) "--"arg
#else
# define VMOPTION(arg) "-"arg
#endif

/// 
/// No more user-serviceable parts in this file.  Stop Tweaking Now!
/// 


static inline int min(int x, int y) { return x < y ? x : y; }
static inline int max(int x, int y) { return x > y ? x : y; }


@interface Squeak : NSApplication
- (void) applicationDidFinishLaunching: (NSNotification *)note;
- (void) applicationDidChangeScreenParameters: (NSNotification *)note;
- (void) unhideAllApplications: (id)sender;
- (BOOL) windowShouldClose: (id)sender;
- (void) maybeTerminate: (id)sender;
- (void) terminate: (id)sender;
- (void) performEnableKeys: (id)sender;
- (void) performDisableKeys: (id)sender;
@end


@interface SqueakWindow : NSWindow
{
  NSImage *icon;
}
- (BOOL) isOpaque;
- (BOOL) canBecomeKeyWindow;
- (void) setIcon;
- (void) performMiniaturize: (id)sender;
- (void) miniaturize: (id)sender;
@end


// Why QDView?  Well...
// 
//   1) we can trivially obtain a raw pointer to its backing store, so
//   2) no need to putz around with the lockFocus/DataProvider/ImageRep crap; plus
//   3) its buffer's coordinate system is already the right way up for Squeak, so
//   4) we avoid potential recopy (just to have CG recopy again); besides
//   5) QDFlushBuffer is _blindingly_ fast (even compared to drawing directly on
//      the framebuffer [go measure it if you don't believe me]); but most importantly
//   6) the QD API is completely free of ObjC and attendant inefficiencies.

@interface SqueakView : NSQuickDrawView
- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) isOpaque;
- (BOOL) isFlipped;
- (id)   initWithFrame: (NSRect)frame;
- (void) setFrame: (NSRect)rect;
- (void) drawRect: (NSRect)rect;
- (void) viewWillStartLiveResize;
- (void) viewDidEndLiveResize;
- (int)  draggingEntered: (id<NSDraggingInfo>)sender;
- (int)  draggingUpdated: (id<NSDraggingInfo>)sender;
- (void) draggingExited: (id<NSDraggingInfo>)sender;
- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender;
@end


static SqueakView	*view	    = 0; /* app view (occupies topRect)		 */


@interface TopView : NSView
- (void) setFrame: (NSRect)rect;
@end

@implementation TopView
- (void) setFrame: (NSRect)rect
{
  [super setFrame: rect];
  if (view)
    [view setFrame: rect];
}
@end


static int		 styleMask  = 0; /* window style mask			*/
static int		 dragCount  = 0; /* number of items during drag/drop	*/
static int		 showExtent = 0; /* 1 if title bar shows view extent	*/
       int		 inModalLoop= 0; /* 1 when WS is in tracking loop	*/
static int		 active     = 0; /* 1 when app window is active		*/

//static CFArrayRef	   dpyModes   = 0; /* one of these days... */

static CGDirectDisplayID dpy	    = 0;
static NSDictionary	*dpyMode    = 0;
static int		 dpyWidth   = 0;
static int		 dpyHeight  = 0;
static int		 dpyDepth   = 0;
       char		*dpyPixels  = 0;
       int		 dpyPitch   = 0;

static SqueakWindow	*win	    = 0; /* main application window		 */
static NSRect		 topRect;	 /* main window frame (excl. decoration) */
static NSRect		 titleRect;	 /* decoration area (above topRect)	 */
static NSRect		 resizeRect;	 /* area sensitive to resize		 */

static TopView		*topView    = 0; /* top view (occupies topRect)		 */

static char		*pixBase    = 0;
static int		 pixPitch   = 0;
static int		 pixWidth   = 0; /* pixmap width (pixels)		 */
static int		 pixHeight  = 0; /* pixmap height			 */
static RgnHandle	 pixRegion  = 0;

static int		 cmdKeys    = 0; /* 1 if app command keys enabled	 */
static int		 fromFinder = 0; /* 1 if app launched from finder	 */
static int		 noTitle    = 0; /* 1 if app window is undecorated	 */
static int		 headless   = 0; /* 1 if app has no window		 */
static int		 noDock     = 0; /* 1 if app window is undocked		 */
static int		 fullscreen = 0; /* 1 if window fullscreen and on top	 */

static int		 stXfd	    = -1;
static int		 osXfd	    = -1;

static pthread_mutex_t	 displayMx  = PTHREAD_MUTEX_INITIALIZER;

static char		 resourcePath[MAXPATHLEN];

static int  glActive= 0;
static void reframeRenderers(void);
static void updateRenderers(void);



#if 1 //xxx REMOVE ME

#define RED	0xff0000
#define GREEN	0x00ff00
#define BLUE	0x0000ff
#define WHITE	0xffffff
#define BLACK	0x000000

void feedback(int offset, int pixel)
{
  const int width= 4, height= 4;
  long *base=  CGDisplayBaseAddress(dpy);
  int   pitch= CGDisplayBytesPerRow(dpy);
  int x, y;

  base= base + width * offset;

  for (y= 0; y < height; ++y)
    {
      for (x= 0; x < width; ++x)
	base[x]= pixel;
      base= (long *)((char *)base + pitch);
    }
}

#endif


//xxx FIXME SOON: check all uses of lock() and conditionalise the
//  sections where failure could cause SEGV (rather than just
//  inconsistent geometry or whatever)

static int doLock(pthread_mutex_t *mx, char *who)
{
  static char *owner= "<none>";
  int backoff, i= 0;
  // wait about 1 second before giving up (10000 == timeslice quantum)
  for (backoff= 10000;  backoff < 1280000;  ++i, backoff <<= 1)
    if (0 == pthread_mutex_trylock(mx))
      {
	owner= who;
	return 1;
      }
    else
      {
#      ifndef NDEBUG
	fprintf(stderr, "lock %d: %s waiting for %-20s\n", i, who, owner);
#      endif
	usleep(backoff);
      }
  perror("pthread_mutex_trylock");
  return 0;
}

static void doUnlock(pthread_mutex_t *mx)
{
  if (pthread_mutex_unlock(mx))
    perror("pthread_mutex_unlock");
}


#define lock(MX)	doLock(&MX##Mx, __FUNCTION__)
#define unlock(MX)	doUnlock(&MX##Mx)


#include "sqUnixEvent.c"



//xxx FIXME: this is currently monochrome

static int display_ioFormPrint(int bitsAddr, int width, int height, int depth,
			       double hScale, double vScale, int landscapeFlag)
{
  //xxx hScale and vScale are ppi.  is there a way to use this
  // meaningfully with PrintInfo or NSPrinter?

  NSAutoreleasePool *pool= [[NSAutoreleasePool alloc] init];
  int opp=     depth / 8;
  int success= 1;

  DPRINTF(("ioFormPrint %f %f\n", hScale, vScale));
  {
    unsigned char    *planes[1]= { (char *)bitsAddr };
    NSBitmapImageRep *bitmap= 	 0;
    NSImage	     *image=  	 0;
    NSImageView	     *view=   	 0;

    bitmap= [[NSBitmapImageRep alloc]
	      initWithBitmapDataPlanes: planes
	      pixelsWide:		width
	      pixelsHigh:		height
	      bitsPerSample:		depth
	      samplesPerPixel:		1
	      hasAlpha:			NO
	      isPlanar:			NO
	      colorSpaceName:		NSCalibratedBlackColorSpace
	      bytesPerRow:		width * opp
	      bitsPerPixel:		depth];
    if (!bitmap) { DPRINTF(("bitmap fail\n")); success= 0; goto done; }
    image= [NSImage alloc];
    //[image setSize: NSMakeSize(width, height)];
    [image addRepresentation: bitmap];
    if (!image) { DPRINTF(("image fail\n")); success= 0; goto done; }
    view= [[NSImageView alloc] initWithFrame: NSMakeRect(0, 0, width, height)];
    [view setImage: image];
    {
      NSPrintOperation *op=  [NSPrintOperation printOperationWithView: view];
      [op setShowPanels: YES];
      DPRINTF(("launch print operation\n"));
      [op runOperation];
    }
  }

 done:
  DPRINTF(("ioFormPrint done.\n"));
  [pool release];
  return success;
}


static int display_ioBeep(void)
{
  NSBeep();
  return 0;
}


static int display_ioRelinquishProcessorForMicroseconds(int microSeconds)
{
  return aioPoll(microSeconds);
}



///
/// events
/// 


static unsigned int qz2sqModifiers(unsigned int qz)
{
  return
    ( ((qz & (NSShiftKeyMask | NSAlphaShiftKeyMask)) ? ShiftKeyBit   : 0))
    | ((qz &  NSControlKeyMask)			     ? CtrlKeyBit    : 0)
    | ((qz &  NSAlternateKeyMask)		     ? OptionKeyBit  : 0)
    | ((qz &  NSCommandKeyMask)			     ? CommandKeyBit : 0);
}

static unsigned int qz2sqButton(unsigned int button)
{
#if 0
  // the image has blue and yellow back-to-front.  fix that here...
  switch (button)
    {
    case 0: return RedButtonBit;
    case 1: return (swapBtn ? YellowButtonBit : BlueButtonBit);
    case 2: return (swapBtn ? BlueButtonBit   : YellowButtonBit);
    }
  DPRINTF(("unknown mouse button %d\n", button));
#endif
  return RedButtonBit;
}


// there appears to be no way to persuade OSX to do multi key
// composition for us without entirely relinquishing control of
// events...

#define makeMap(name, A,E,I,N,O,U,Y,a,e,i,n,o,u,y)	\
static int name##Map(int key)				\
{							\
  switch (key)						\
    {							\
    case 'A': return A;					\
    case 'E': return E;					\
    case 'I': return I;					\
    case 'N': return N;					\
    case 'O': return O;					\
    case 'U': return U;					\
    case 'Y': return Y;					\
    case 'a': return a;					\
    case 'e': return e;					\
    case 'i': return i;					\
    case 'n': return n;					\
    case 'o': return o;					\
    case 'u': return u;					\
    case 'y': return y;					\
    }							\
  return 0;						\
}

makeMap(acute,		0347, 0203, 0352, 0000, 0356, 0362, 0000, 0207, 0216, 0222, 0000, 0227, 0234, 0000);
makeMap(grave,		0313, 0351, 0355, 0000, 0361, 0364, 0000, 0210, 0217, 0223, 0000, 0230, 0235, 0000);
makeMap(circumflex,	0345, 0346, 0353, 0000, 0357, 0363, 0000, 0211, 0220, 0224, 0000, 0231, 0236, 0000);
makeMap(tilde,		0314, 0000, 0000, 0204, 0315, 0000, 0000, 0213, 0000, 0000, 0226, 0233, 0000, 0000);
makeMap(umlaut,		0200, 0350, 0354, 0000, 0205, 0206, 0331, 0212, 0221, 0225, 0000, 0232, 0237, 0330);

#undef makeMap

static int (*accentMap)(int)= 0;


static int characterCodeFromEvent(NSEvent *event)
{
  static int fnKeys[256], keyMapInited= NO;
  char theCharacter= 0;
  int keyFlags= [event modifierFlags];
  if (!keyMapInited)
    {
      int i;
      memset(fnKeys, 0, sizeof fnKeys);
      for (i= 0;  i < 4;  ++i)
	fnKeys[i]= 28 + (i^2);
      fnKeys[0x28]= 127;
      fnKeys[0x29]= 1;
      fnKeys[0x2b]= 4;
      fnKeys[0x2c]= 11;
      fnKeys[0x2d]= 12;
      keyMapInited= YES;
    }
  if ([[event characters] cStringLength] == 1)
    {
      [[event characters] getCString: &theCharacter maxLength: 1];
      if (theCharacter == 127)
	theCharacter= 8;
      if (theCharacter == '.' && keyFlags & NSCommandKeyMask)
	{
	  setInterruptPending(1);
	  setInterruptCheckCounter(0);
        }
      printf("character %d %x\n", theCharacter, theCharacter);
    }
  else
    {
      unichar codes[32];
      NSRange zeroToOne= { 0, [[event characters] length] };
      [[event characters] getCharacters: &codes[0] range: zeroToOne];
      printf("unichar %d %x\n", codes[0], codes[0]);
      if (codes[0] >> 8 == 0xf7)
	{
	  theCharacter= fnKeys[codes[0] & 0xff];
	  printf("  => %d %x\n", theCharacter, theCharacter);
	}
    }
  return theCharacter;
}



static unsigned int qz2sqKey(NSEvent *event)
{
  NSAutoreleasePool *pool=  [[NSAutoreleasePool alloc] init];
  NSString	    *chars= [event characters];
  NSData	    *data=  [chars dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion: NO];
  int keyCode= 0;

# define returnKey(N)	keyCode= (N);  goto done

  characterCodeFromEvent(event);

  if ([data length])
    {
      keyCode= ((unsigned char *)[data bytes])[0];
      //printf("data keyCode %d\n", keyCode);
      if (accentMap)
	{
	  unsigned char alt= accentMap(keyCode);
	  //printf("data alt %d\n", alt);
	  if (alt)
	    keyCode= alt;
	  if (NSKeyUp == [event type])
	    accentMap= 0;
	}
      if (keyCode == 127)
	keyCode= 8;
      goto done;
    }

  if ([chars length])
    {
      keyCode= [chars characterAtIndex: 0];
      switch (keyCode)
	{
	case 127:	// this is not up for discussion.  PERIOD.
	case NSDeleteFunctionKey:	returnKey( 8);
	case NSUpArrowFunctionKey:	returnKey(30);
	case NSDownArrowFunctionKey:	returnKey(31);
	case NSLeftArrowFunctionKey:	returnKey(28);
	case NSRightArrowFunctionKey:	returnKey(29);
	case NSHomeFunctionKey:		returnKey( 1);
	case NSEndFunctionKey:		returnKey( 4);
	case NSPageUpFunctionKey:	returnKey(11);
	case NSPageDownFunctionKey:	returnKey(12);
	  /* -- these should probably be implemented --
	     NSClearLineFunctionKey	Clear/Num Lock
	     NSHelpFunctionKey		Help
	     -- the rest are missing on most mac keyboards --
	     NSBeginFunctionKey		Begin
	     NSPrintScreenFunctionKey	Print Screen
	     NSScrollLockFunctionKey	Scroll Lock
	     NSPauseFunctionKey		Pause
	     NSSysReqFunctionKey	System Request
	     NSBreakFunctionKey		Break
	     NSResetFunctionKey		Reset
	     NSStopFunctionKey		Stop
	     NSMenuFunctionKey		Menu
	     NSUserFunctionKey		User
	     NSSystemFunctionKey	System
	     NSPrintFunctionKey		Print
	     NSClearDisplayFunctionKey	Clear Display
	     NSInsertLineFunctionKey	Insert Line
	     NSDeleteLineFunctionKey	Delete Line
	     NSInsertCharFunctionKey	Insert Character
	     NSDeleteCharFunctionKey	Delete Character
	     NSPrevFunctionKey		Previous
	     NSNextFunctionKey		Next
	     NSSelectFunctionKey	Select
	     NSExecuteFunctionKey	Execute
	     NSUndoFunctionKey		Undo
	     NSRedoFunctionKey		Redo
	     NSFindFunctionKey		Find
	     NSModeSwitchFunctionKey	Mode Switch
	  */
	}
      if (keyCode & 0xff00)
	keyCode= 0;
    }

  if (keyCode)
    goto done;

  if (NSAlternateKeyMask == [event modifierFlags])
    {
      int key, type;
      chars= [event charactersIgnoringModifiers];
      key=   [chars characterAtIndex: 0];
      type=  [event type];
      //printf("chars key %d\n", key);
      switch (key)
	{
#       define mapAccent(code,name) \
	  /*printf(#name"'n");*/ if (accentMap) keyCode= code; else if (NSKeyUp == type) accentMap= name##Map
	case 'e': mapAccent(0253, acute);	break;
	case 'i': mapAccent(0366, circumflex);	break;
	case 'u': mapAccent(0254, umlaut);	break;
	case '`': mapAccent(0140, grave);	break;
	case 'n': mapAccent(0367, tilde);	break;
#	undef mapAccent
	}
    }

 done:
  [pool release];

  //printf("KEY %d\n", keyCode);
  return keyCode;
}



static inline void noteMousePoint(NSPoint loc)
{
  int x= (int)loc.x;
  int y= (int)topRect.size.height - (int)loc.y;
  // mouse motion/up is tracked outside of topRect when active, so
  // clamp it explicitly
  // (note: there's a race here, but it's benign)
  mousePosition.x= max(0, min(x, pixWidth  - 1));
  mousePosition.y= max(0, min(y, pixHeight - 1));
}


static void evtHandler(int fd, void *data, int flags)
{
  for (;;)
    {
      sqInputEvent evt;
      int n= read(fd, (void *)&evt, sizeof(evt));
      if (n < 0)
	{
	  if ((EINTR == errno) || (EAGAIN == errno))
	    break;
	  perror("evtHandler: read");
	}
      else if (n == 0)
	break;
      else if (n != sizeof(evt))
	fprintf(stderr, "evtHandler: read returned %d -- why?\n", n);
      else
	{
	  sqInputEvent *evp= allocateInputEvent(0);
	  *evp= evt;
	  signalInputEvent();
	}
    }
  aioHandle(fd, evtHandler, AIO_RX);
}


static void sendEvent(sqInputEvent *evt)
{
  if (inModalLoop)    //xxx there are other ways to escape from one of these
    inModalLoop= 0;
  if (sizeof(*evt) != write(osXfd, evt, sizeof(*evt)))
    perror("sendEvent: write");
}


static int makeButtonState(void)
{
  int btn= buttonState;
  int mod= modifierState;
  if (btn == RedButtonBit)
    switch (mod)
      {
      case OptionKeyBit:	btn= YellowButtonBit;	mod= 0;	break;
      case CommandKeyBit:	btn= BlueButtonBit;	mod= 0;	break;
      }
  return (mod << 3) | btn;
}


static void noteMouseEvent(void)
{
  int state= makeButtonState();
  sqMouseEvent evt;
  evt.type= EventTypeMouse;
  evt.timeStamp= ioMSecs();
  evt.x= mousePosition.x;
  evt.y= mousePosition.y;
  evt.buttons= (state & 0x7);
  evt.modifiers= (state >> 3);
  evt.reserved1= 0;
  evt.reserved2= 0;
#ifdef DEBUG_EVENTS
  printf("EVENT: mouse (%d,%d)", mousePosition.x, mousePosition.y);
  printModifiers(state >> 3);
  printButtons(state & 7);
  printf("\n");
#endif
  sendEvent((sqInputEvent *)&evt);
}


static void noteKeyboardEvent(int keyCode, int pressCode, int modifiers)
{
  sqKeyboardEvent evt;
  evt.type= EventTypeKeyboard;
  evt.timeStamp= ioMSecs();
  evt.charCode= keyCode;
  evt.pressCode= pressCode;
  evt.modifiers= modifiers;
  evt.reserved1= 0;
  evt.reserved2= 0;
  evt.reserved3= 0;
#ifdef DEBUG_EVENTS
  printf("EVENT: keyboard");
  printModifiers(modifiers);
  printKey(keyCode);
  printf("\n");
#endif
  sendEvent((sqInputEvent *)&evt);
}


static void noteDragEvent(int dragType, int numFiles)
{
  int state= makeButtonState();
  sqDragDropFilesEvent evt;
  evt.type= EventTypeDragDropFiles;
  evt.timeStamp= ioMSecs();
  evt.dragType= dragType;
  evt.x= mousePosition.x;
  evt.y= mousePosition.y;
  evt.modifiers= (state >> 3);
  evt.numFiles= numFiles;
  evt.reserved1= 0;
  sendEvent((sqInputEvent *)&evt);
}


static int display_ioProcessEvents(void)
{
  return aioPoll(0);
}


static int display_ioScreenDepth(void)
{
  return headless ? 1 : dpyDepth;
}

static double display_ioScreenScaleFactor(void)
{
  return 1.0;
}

static int display_ioScreenSize(void)
{
  int size;
  if (headless)
    return ((16 << 16) | 16);
  lock(display);
  size= getSavedWindowSize();
  unlock(display);
  return size;
}


static int display_ioSetCursorWithMask(int cursorBitsIndex, int cursorMaskIndex,
				       int offsetX, int offsetY)
{
  if (headless)
    return 0;

  if ([view lockFocusIfCanDraw])
    {
      NSAutoreleasePool *pool= [[NSAutoreleasePool alloc] init];
      NSBitmapImageRep *bitmap= 0;
      NSImage          *image=  0;
      NSCursor         *cursor= 0;

      if (cursorMaskIndex == 0)
	cursorMaskIndex= cursorBitsIndex;

      bitmap= [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes: 0 pixelsWide: 16 pixelsHigh: 16
		bitsPerSample: 1 samplesPerPixel: 2
		hasAlpha: YES isPlanar: YES
		colorSpaceName: NSCalibratedBlackColorSpace
		bytesPerRow: 2
		bitsPerPixel: 0];
      {
	unsigned char *planes[5];
	[bitmap getBitmapDataPlanes: planes];
	{
	  unsigned char *data= planes[0];
	  unsigned char *mask= planes[1];
	  int            i;

	  for (i= 0; i < 16; ++i)
	    {
	      unsigned int word= ((unsigned int *)cursorBitsIndex)[i];
	      data[i*2 + 0]= (word >> 24) & 0xFF;
	      data[i*2 + 1]= (word >> 16) & 0xFF;
	      word= ((unsigned int *)cursorMaskIndex)[i];
	      mask[i*2 + 0]= (word >> 24) & 0xFF;
	      mask[i*2 + 1]= (word >> 16) & 0xFF;
	    }
	}
      }
      image= [[NSImage alloc] init];
      [image addRepresentation: bitmap];
      {
	NSPoint hotSpot= { -offsetX, -offsetY };
	cursor= [[NSCursor alloc] initWithImage: image hotSpot: hotSpot];
      }
      [cursor set];
      [pool release];
      [view unlockFocus];
    }
  return 1;
}

#if 0
static int display_ioSetCursor(int cursorBitsIndex, int offsetX, int offsetY)
{
  return ioSetCursorWithMask(cursorBitsIndex, cursorBitsIndex, offsetX, offsetY);
}
#endif


static int display_ioForceDisplayUpdate(void)
{
  return 0;
}


#if 0

static void setRects(int w, int h)
{
  DPRINTF(("setRects %d %d\n", w, h));
  topRect= NSMakeRect(0,0, w,h);
  if (fullscreen)
    {
      titleRect=  NSMakeRect(0, dpyHeight, dpyWidth, 0);
      resizeRect= NSMakeRect(dpyWidth, 0, 0, 0);
    }
  else
    {
      void *port= [view qdPort];
      titleRect  = [NSWindow frameRectForContentRect: topRect styleMask: styleMask];
      titleRect.origin.y += h;
      titleRect.size.height -= h;
      resizeRect= NSMakeRect(pixWidth - RESIZE_EXTENT, 0, RESIZE_EXTENT, RESIZE_EXTENT);
      if (port)	// no port while window is deferred
	{
	  PixMapHandle pix;
	  LockPortBits(port);
	  {
	    pix      = GetPortPixMap(port);
	    pixPitch = GetPixRowBytes(pix);
	    pixBase  = ((char *)GetPixBaseAddr(pix)
			+ ((int)titleRect.size.height * pixPitch));
	  }
	  UnlockPortBits(port);
	}
    }
  setSavedWindowSize((w << 16) | h);	// assume this is atomic
}

#endif


static char *updatePix(void)
{
  void *port= [view qdPort];
  assert(win);  assert(topView);  assert(view);
  if (port)	// no port while window is deferred
    {
      int w, h;
      NSRect winRect= [win frame];
      winRect.origin= NSMakePoint(0, 0);	// window coordinates
      topRect= [NSWindow contentRectForFrameRect: winRect styleMask: styleMask];
      DPRINTF(("updatePix w=%d h=%d\n", (int)NSWidth(topRect), (int)NSHeight(topRect)));
      w= NSWidth(topRect);
      h= NSHeight(topRect);
      setSavedWindowSize((w << 16) | h);			// assume this is atomic
      if (fullscreen)
	{
	  titleRect=  NSMakeRect(0, dpyHeight, dpyWidth, 0);	// empty & offscreen
	  resizeRect= NSMakeRect(dpyWidth, 0, 0, 0);		// empty & offscreen
	}
      else
	{
	  titleRect= winRect;
	  titleRect.origin.y    += h;
	  titleRect.size.height -= h;
	  resizeRect= NSMakeRect(w - RESIZE_EXTENT, 0, RESIZE_EXTENT, RESIZE_EXTENT);
	}
      pixWidth= w;
      pixHeight= h;
      LockPortBits(port);
      {
	PixMapHandle pix= GetPortPixMap(port);
	pixPitch= GetPixRowBytes(pix);
	assert(pixPitch);
	assert(pixPitch >= w * 4);				//xxx FIXME for 16-bit depth
	pixBase= ((char *)GetPixBaseAddr(pix) + ((int)NSHeight(titleRect) * pixPitch));
	assert(pixBase);
      }
      UnlockPortBits(port);
    }
  else
    {
      DPRINTF(("updatePix: NO PORT!\n"));
      pixBase= 0;
    }
  DPRINTF(("pixBase %p, width %d, height %d, pitch %d\n", pixBase, pixWidth, pixHeight, pixPitch));
  return pixBase;
}



#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)

static int display_ioShowDisplay(int dispBitsIndex, int width, int height, int depth,
				 int affectedL, int affectedR, int affectedT, int affectedB)
{
  int   affectedW, affectedH;

  if (headless
      || (width != pixWidth) || (width < 1) || (height != pixHeight) || (height < 1)
      || ((!pixBase) && !updatePix())
      || (![view lockFocusIfCanDraw]))
    return 0;

  lock(display);
  affectedR= min(affectedR, min(width,  pixWidth ));
  affectedB= min(affectedB, min(height, pixHeight));
  affectedW= affectedR - affectedL;
  affectedH= affectedB - affectedT;
  if ((affectedW > 0) && (affectedH > 0))
    {
      int   opp=	depth / 8;	// octets per pixel
      char *out=	pixBase;
      int   outPitch=	pixPitch;
      void *port=	[view qdPort];
      LockPortBits(port);
      //xxx FIXME SOON: cope with dpy depth mismatch (share the code
      // used by the other types of Unix display)
      {
	int   pitch= bytesPerLine(width, depth);
	char *in=    (char *)dispBitsIndex + affectedL * opp + affectedT * pitch;
	int   lines= affectedH;
	int   bytes= affectedW * opp;

	out += (affectedL * opp) + (affectedT * outPitch);

	if ((bytes == pitch) && (bytes == outPitch))
	  memcpy(out, in, bytes * lines);
	else if (bytes < 9) // empirical
	  while (lines--)
	    {
	      register char *to=    out;
	      register char *from=  in;
	      register int   count= bytes;
	      while (count--)
		*to++= *from++;
	      in  += pitch;
	      out += outPitch;
	    }
	else
	  while (lines--)
	    {
	      memcpy((void *)out, (void *)in, bytes);
	      in  += pitch;
	      out += outPitch;
	    }
      }
      SetRectRgn(pixRegion, affectedL, affectedT, affectedR, affectedB);
      QDFlushPortBuffer([view qdPort], pixRegion);
      UnlockPortBits(port);
    }
  unlock(display);
  [view unlockFocus];

  return 0;
}


#if 0

static void display_ioFlushDisplay(void)
{
  void *port;
  lock(display);
  port= [view qdPort];
  LockPortBits(port);
  SetRectRgn(pixRegion, 0, 0, pixWidth, pixHeight);
  QDFlushPortBuffer([view qdPort], pixRegion);
  UnlockPortBits(port);
  unlock(display);
}

#endif

static int display_ioHasDisplayDepth(int i)
{
  return i == (headless ? 1 : dpyDepth);
}

static int display_ioSetDisplayMode(int width, int height, int depth, int fullscreenFlag)
{
  if (headless)
    return 0;

  printf("ioSetDisplayMode: IMPLEMENT ME\n");
  return ((width == dpyWidth) && (height == dpyHeight) && (depth == dpyDepth));
}


static void *display_ioGetDisplay(void)
{
  if (headless)
    return 0;

  DPRINTF(("ioGetDisplay: WARNING: check the client to see it knows what it's doing\n"));
  return dpy;
}

static void *display_ioGetWindow(void)
{
  if (headless)
    return 0;

  printf("ioGetWindow: WARNING: check the client to see it knows what it's doing\n");
  return 0;
}


static char *clipboard= 0;


static int display_clipboardWriteFromAt(int count, int byteArrayIndex, int startIndex)
{
  NSAutoreleasePool *pool=   [[NSAutoreleasePool alloc] init];
  NSPasteboard      *pboard= [NSPasteboard generalPasteboard];
  NSString          *string= [NSString
			       stringWithCString: (char *)byteArrayIndex + startIndex
			       length:            count];
  [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
  [pboard setString: string forType: NSStringPboardType];
  [pool release];
  return 0;
}


static int display_clipboardSize(void)
{
  NSAutoreleasePool *pool=   [[NSAutoreleasePool alloc] init];
  NSPasteboard      *pboard= [NSPasteboard generalPasteboard];
  NSString          *type=   [pboard availableTypeFromArray:
				       [NSArray arrayWithObject:
						  NSStringPboardType]];
  if (clipboard) free(clipboard);
  clipboard= 0;
  if (type != nil)
    {
      NSString *contents= [pboard stringForType: type];
      if (contents != nil)
	clipboard= strdup([contents cString]);
    }
  [pool release];
  return clipboard ? strlen(clipboard) : 0;
}


static int display_clipboardReadIntoAt(int count, int byteArrayIndex, int startIndex)
{
  if (clipboard)
    {
      strncpy((char *)byteArrayIndex + startIndex, clipboard, count);
      return count;
    }
  return 0;
}



static void display_winExit(void)
{
  [win close];
}


static void display_winSetName(char *title)
{
  char *base= strrchr(title, '/');
  if (base) title= base + 1;
#if (RESIZE_IN_TITLE)
  if (showExtent)
    {
      char buf[NAME_MAX];
      NSRect frame= [view frame];
      sprintf(buf, "%s (%dx%d)", title, (int)NSWidth(frame), (int)NSHeight(frame));
      title= buf;
    }
#endif
  [win setTitle: [NSString stringWithCString: title]];
}


static void  display_parseEnvironment(void) {}

static int display_parseArgument(int argc, char **argv)
{
  if     (!strncmp(*argv, VMOPTION("psn_"), strlen(VMOPTION("psn_"))))		return fromFinder= 1;
  else if (!strcmp(*argv, VMOPTION("quartz")))		return 1;
  else if (!strcmp(*argv, VMOPTION("fullscreen")))	return fullscreen= 1;
  else if (!strcmp(*argv, VMOPTION("headless")))		return headless= 1;
  else if (!strcmp(*argv, VMOPTION("notitle")))		return noTitle= 1;
  else if (!strcmp(*argv, VMOPTION("nodock")))		return noDock= 1;
  else if (!strcmp(*argv, VMOPTION("swapbtn")))		return swapBtn= 1;
  return 0;
}

static void display_printUsage(void)
{
  printf("\nQuartz/Aqua <option>s:\n");
  printf("  "VMOPTION("fullscreen")"           occupy the entire screen\n");
  printf("  "VMOPTION("headless")"             run in headless (no window) mode\n");
  printf("  "VMOPTION("nodock")"               don't show Squeak in the dock\n");
  printf("  "VMOPTION("notitle")"              disable the Squeak window title bar\n");
  printf("  "VMOPTION("swapbtn")"              swap mouse buttons 2 (yellow) and 3 (blue)\n");
}

static void display_printUsageNotes(void)
{
  printf("  -nodock is only useful with `-headless'.\n");
}


/// 
/// window initialization
/// 


static void menuAddItem(NSMenu *menu, NSString *title, SEL action,
			NSString *key, int opt)
{
  NSMenuItem *item= [[NSMenuItem alloc]
		      initWithTitle: title
		      action:        action
		      keyEquivalent: (cmdKeys ? key : @"")];
  [menu addItem: item];
  if (opt)
    [item setKeyEquivalentModifierMask: (NSCommandKeyMask | NSAlternateKeyMask)];
  [item release];
}

static void installMenu(SEL install, NSMenu *menu)
{
  NSMenuItem *item= [[NSMenuItem alloc]
		      initWithTitle: @""
		      action:	 nil
		      keyEquivalent: @""];
  [item setSubmenu: menu];
  [[NSApp mainMenu] addItem: item];
  if (install != NULL)
    {
      extern id objc_msgSend(id theReceiver, SEL theSelector, ...);
      objc_msgSend(NSApp, install, menu);
    }
  [menu release];
  [item release];
}


// InterfaceBuilder?  Just Say No!

static void setUpMenus(void)
{
  if (headless && noDock)
    return;

  [NSApp setMainMenu: [[NSMenu alloc] init]];
  {
    NSMenu *menu= [[NSMenu alloc] initWithTitle: @"Squeak"];
    menuAddItem(menu, @"About Squeak",   @selector(performAbout:),          @"",  0);
    [menu addItem: [NSMenuItem separatorItem]];
    menuAddItem(menu, @"Preferences...", @selector(performPreferences:),    @"y", 0);
    [menu addItem: [NSMenuItem separatorItem]];
    menuAddItem(menu, @"Hide Squeak",    @selector(hide:),                  @"h", 0);
    menuAddItem(menu, @"Hide Others",    @selector(hideOtherApplications:), @"h", 1);
    menuAddItem(menu, @"Show All",       @selector(unhideAllApplications:), @"",  0);
    [menu addItem: [NSMenuItem separatorItem]];
    menuAddItem(menu, @"Quit Squeak",    @selector(terminate:),             @"q", 0);
    installMenu(@selector(setAppleMenu:), menu);
  }
  {
    NSMenu *menu= [[NSMenu alloc] initWithTitle: @"File"];
    menuAddItem(menu, @"Page Setup...", @selector(performPageSetup:), @"P", 0);
    menuAddItem(menu, @"Print",         @selector(performPrint:),     @"p", 0);
    installMenu(NULL, menu);
  }
  {
    NSMenu *menu= [[NSMenu alloc] initWithTitle: @"Window"];
    menuAddItem(menu, @"Minimise", @selector(performMiniaturize:), @"m", 0);
    if (cmdKeys)
      menuAddItem(menu, @"Disable Command Keys",
		  @selector(performDisableKeys:), @"k", 0);
    else
      menuAddItem(menu, @"Enable Command Keys",
		  @selector(performEnableKeys:),  @"",  0);
    installMenu(@selector(setWindowsMenu:), menu);
  }
  {
    NSMenu *menu= [[NSMenu alloc] initWithTitle: @"Help"];
    menuAddItem(menu, @"Squeak Help", @selector(showHelp:), @"?", 0);
    installMenu(NULL, menu);
  }
}


static void setUpDock(void)
{
  typedef struct CPSProcessSerNum { UInt32 lo, hi; } CPSProcessSerNum;

  extern OSErr CPSGetCurrentProcess(CPSProcessSerNum *psn);
  extern OSErr CPSSetProcessName(CPSProcessSerNum *psn, char *name);
  extern OSErr CPSEnableForegroundOperation(CPSProcessSerNum *psn,
					    UInt32 arg1, UInt32 arg2,
					    UInt32 arg3, UInt32 arg4);
  extern OSErr CPSSetFrontProcess(CPSProcessSerNum *psn);

  // this was passed to us in argv, but we have to pick it up from CPS
  // anyway if the VM was started from a command line or script
  CPSProcessSerNum psn;

  if (headless && noDock)
    return;

  if ((  CPSGetCurrentProcess(&psn))
      || CPSSetProcessName(&psn, "Squeak") // regardless of the bundle name
      || CPSEnableForegroundOperation(&psn, 0x03, 0x3c, 0x2c, 0x1103)
      || CPSSetFrontProcess(&psn))
    fprintf(stderr, "the court failed to put Squeak in the dock\n");
}


static char *display_winSystemName(void)
{
  return "Quartz";
}


static void display_winInit(void)
{
  [[NSAutoreleasePool alloc] init];
  [Squeak sharedApplication];
  [NSApp setDelegate: NSApp];
  // from winOpen()...
  setUpMenus();
  setUpDock();
  [NSApp run];
}


static void display_winOpen(void) {}


static void setUpDisplay(void)
{
  if (headless)
    return;

  dpy        = kCGDirectMainDisplay;
  dpyMode    = (NSDictionary *)CGDisplayCurrentMode(dpy);
  dpyWidth   = [[dpyMode objectForKey: (id)kCGDisplayWidth] intValue];
  dpyHeight  = [[dpyMode objectForKey: (id)kCGDisplayHeight] intValue];
  dpyDepth   = [[dpyMode objectForKey: (id)kCGDisplayBitsPerPixel] intValue];
  dpyPixels  = CGDisplayBaseAddress(dpy);
  dpyPitch   = CGDisplayBytesPerRow(dpy);

  pixRegion  = NewRgn();

  DPRINTF(("display is %dx%dx%d at %p pitch %d\n",
	   dpyWidth, dpyHeight, dpyDepth, dpyPixels, dpyPitch));
}


static void setUpWindow(int fs)
{
  if (!headless)
    {
      int w, h;
      NSRect contentRect;
      if (fs)
	{
	  w= dpyWidth;
	  h= dpyHeight;
	}
      else
	{
	  int winSize= getSavedWindowSize();
	  w= winSize >> 16;
	  h= winSize & 0xffff;
	}
      DPRINTF(("initial winSize %d %d\n", w, h));
      styleMask= (fs
		  ? (NSBorderlessWindowMask)
		  : (  NSTitledWindowMask
		     | NSMiniaturizableWindowMask
		     | NSResizableWindowMask));
      //xxx does quartz _really_ have _no_ mechanism to set window bit gravity?!?
      win= [[SqueakWindow alloc]
	     initWithContentRect: NSMakeRect(0,0, w,h)
	     styleMask:           styleMask
	     backing:             NSBackingStoreBuffered
	     defer:               NO];
      contentRect= [[win contentView] frame];
      w= NSWidth(contentRect);
      h= NSHeight(contentRect);
      setSavedWindowSize((w << 16) | h);
      view= [[SqueakView alloc] initWithFrame: contentRect];
      [view setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
      [win setReleasedWhenClosed: YES];
      [win setAcceptsMouseMovedEvents: YES];
      [win setShowsResizeIndicator: NO];
      topView= [[TopView alloc] initWithFrame: contentRect];
      [win setInitialFirstResponder: view];
      [win setDelegate: NSApp];
      [win useOptimizedDrawing: YES];
      if (fs)
	[win setLevel: CGShieldingWindowLevel()];
      else
	{
	  [win center];
	  [win setIcon];
	  display_winSetName(shortImageName);
	}
      [topView addSubview: view];	[view release];
      [win setContentView: topView];	[topView release];
      [win makeKeyAndOrderFront: nil];	// need platform window to get pixBase
    }
}


static int		  imageWidth;
static int		  imageHeight;
static char		 *imageData;
static CGDataProviderRef  imageDataProvider;
static CGImageRef	  imageRef;

static void cgdpRelease(void *info, const void *data, size_t size) {}

static void captureImage(int inverted)
{
  imageWidth=  pixWidth;
  imageHeight= pixHeight;
  imageData=   (char *)malloc(pixPitch * imageHeight);
  if (inverted)
    {
      char *in= pixBase, *out= imageData + ((imageHeight - 1) * pixPitch);
      int   y;
      for (y= pixHeight;  y--;  (in += pixPitch), (out -= pixPitch))
	memcpy(out, in, pixPitch);
    }
  else
    {
      memcpy(imageData, pixBase, imageHeight * pixPitch);
    }
  imageDataProvider=
    CGDataProviderCreateWithData(0, imageData, pixPitch*imageHeight,
				 cgdpRelease);
  imageRef=
    CGImageCreate(imageWidth, imageHeight, 8, 32, pixPitch,
		  CGColorSpaceCreateDeviceRGB(),
		  kCGImageAlphaNoneSkipFirst,
		  imageDataProvider, 0, 0,
		  kCGRenderingIntentDefault);
}


static void drawImage(CGContextRef cgc, int offset)
{
  CGContextDrawImage(cgc, CGRectMake(0, offset, imageWidth, imageHeight), imageRef);
}


static void releaseImage(int malloced)
{
  CGImageRelease(imageRef);
  CGDataProviderRelease(imageDataProvider);
  if (malloced)
    free(imageData);
}

  
#ifdef FULLSCREEN_FADE

// YES, I know there's a CG API to do this.  But it sucks.

static struct
{
  CGGammaValue r[256], g[256], b[256];
} dpyGamma;

static void fadeOut(float delta)
{
  CGGammaValue r[256], g[256], b[256];
  int sz;

  if ((CGDisplayNoErr == CGGetDisplayTransferByTable
			   (dpy, 256, dpyGamma.r, dpyGamma.g, dpyGamma.b, &sz))
      && (256 == sz))
    {
      float scale;
      memcpy(r, dpyGamma.r, sizeof(r));
      memcpy(g, dpyGamma.g, sizeof(g));
      memcpy(b, dpyGamma.b, sizeof(b));
      for (scale= 1.0;  scale >= 0.0;  scale -= delta)
	{
	  int i;
	  for (i= 256;  i--;)
	    {
	      r[i]= dpyGamma.r[i] * scale;
	      g[i]= dpyGamma.g[i] * scale;
	      b[i]= dpyGamma.b[i] * scale;
	    }
	  if (CGDisplayNoErr != CGSetDisplayTransferByTable(dpy, 256, r, g, b))
	    {
	      printf("failed to set transfer table\n");
	      CGDisplayRestoreColorSyncSettings();
	      return;
	    }
	  usleep(10000);
	}
    }
  else
    {
      printf("failed to get display transfer table (%d)\n", sz);
    }
}

static void fadeIn(float delta)
{
  CGGammaValue r[256], g[256], b[256];
  float scale;
  memset(r, 0, sizeof(r));
  memset(g, 0, sizeof(g));
  memset(b, 0, sizeof(b));
  for (scale= 0.0;  scale <= 1.0;  scale += delta)
    {
      int i;
      for (i= 256; i--;)
	{
	  r[i] = dpyGamma.r[i] * scale;
	  g[i] = dpyGamma.g[i] * scale;
	  b[i] = dpyGamma.b[i] * scale;
	}
      if (CGDisplayNoErr != CGSetDisplayTransferByTable(dpy, 256, r, g, b))
	break;
      usleep(10000);
    }
  CGDisplayRestoreColorSyncSettings();
}

#endif


#if 1

static int display_ioSetFullScreen(int flag)
{
  static int originalWindowSize= 0;
  SqueakWindow *old;

  printf("ioSetFullScreen(%d)\n", flag);

  if (headless || (fullscreen == flag))
    return 0;	// nothing to do
  old= win;
  win= 0;  view= 0;  topView= 0;  pixBase= 0; pixWidth= 0; pixHeight= 0; pixPitch= 0;
  if (flag)
    originalWindowSize= getSavedWindowSize();
  else if (originalWindowSize)
    setSavedWindowSize(originalWindowSize);
  setFullScreenFlag(fullscreen= flag);
  setUpWindow(flag);
  reframeRenderers();
  [old close];
  return 1;
}

#else

static int display_ioSetFullScreen(int flag)
{
  static int originalWindowSize= (800 << 16) | 600;

  printf("ioSetFullScreen(%d)\n", flag);

  if (headless || (fullscreen == flag) || glActive)
    return 0;	// nothing to do

  if (flag)	// switch to fullscreen
    {
      CGDisplayHideCursor(dpy);
#    ifdef FULLSCREEN_FADE
      captureImage(0);
      fadeOut(FULLSCREEN_FADE);
#    endif
      if (CGDisplayNoErr != CGDisplayCapture(dpy))
	DPRINTF(("failed to capture display\n"));
      else
	{
#        ifdef FULLSCREEN_FADE
	  CGContextRef cgc;
	  memset(dpyPixels, -1U, dpyPitch * dpyHeight);
	  cgc= CGBitmapContextCreate(dpyPixels, dpyWidth, dpyHeight,
				     8, dpyPitch,
				     CGColorSpaceCreateDeviceRGB(),
				     kCGImageAlphaNoneSkipFirst);
	  drawImage(cgc, dpyHeight - pixHeight);
	  CGContextRelease(cgc);
#	 endif
	  lock(display);
	  originalWindowSize= getSavedWindowSize();
	  pixWidth=   dpyWidth;
	  pixHeight=  dpyHeight;
	  fullscreen= 1;
	  updatePix();
	  unlock(display);
	  [NSMenu setMenuBarVisible: NO];
	}
#    ifdef FULLSCREEN_FADE
      fadeIn(FULLSCREEN_FADE);
      releaseImage(0);
#    endif
      mousePosition.x= mousePosition.y= -1;
      CGDisplayShowCursor(dpy);
    }
  else		// switch to windowed
    {
#    ifdef FULLSCREEN_FADE
      fadeOut(FULLSCREEN_FADE);
#    endif
      [NSMenu setMenuBarVisible: YES];
      CGDisplayRelease(dpy);
      fullscreen= 0;
      lock(display);
      setSavedWindowSize(originalWindowSize);
      pixWidth=  originalWindowSize >> 16;
      pixHeight= originalWindowSize & 0xffff;
      updatePix();
      unlock(display);
#    ifdef FULLSCREEN_FADE
      fadeIn(FULLSCREEN_FADE);
#    endif
    }

  return 1;
}

#endif



@implementation Squeak


-(void) sendEvent: (NSEvent *)event
{
  int	  type=     [event type];
  NSPoint loc=      [event locationInWindow];
  NSWindow *evtWin= [event window];
#if 0
  NSPoint loc=      (fullscreen
		     ? [NSEvent mouseLocation]	//xxx should use deltas
		     : [event locationInWindow]);
#endif

  if (evtWin && ((NSWindow *)win != [event window]))
    {
      [super sendEvent: event];
      return;
    }

  switch (type)
    {
#     define down buttonState |= qz2sqButton([event buttonNumber])
#     define move
#     define up	  buttonState &= ~qz2sqButton([event buttonNumber])

#     define recordEvent(delta)					\
      if (fullscreen || NSPointInRect(loc, [view frame]))	\
	{							\
	  noteMousePoint(loc);					\
	  delta;						\
	  modifierState= qz2sqModifiers([event modifierFlags]);	\
	  noteMouseEvent();					\
	}							\
      else							\
	[super sendEvent: event]	// don't track outside window

    case NSLeftMouseDown: case NSOtherMouseDown: case NSRightMouseDown:
      if ((!active) || NSPointInRect(loc, resizeRect))
	[super sendEvent: event];	// first click, or start resize
      else
	recordEvent(down);
      break;

    case NSLeftMouseDragged: case NSRightMouseDragged: case NSOtherMouseDragged:
      if (!(buttonState & qz2sqButton([event buttonNumber])))
	{
	  [super sendEvent: event];	// already tracking window move
	  break;
	}
      // fall through...
    case NSMouseMoved:
      recordEvent(move);
      break;

    case NSLeftMouseUp: case NSOtherMouseUp: case NSRightMouseUp:
      recordEvent(up);
      break;

#     undef recordEvent
#     undef down
#     undef move
#     undef up

    case NSKeyDown:
      {
	int keyCode= qz2sqKey(event);
	if (keyCode)
	  {
	    modifierState= qz2sqModifiers([event modifierFlags]);
	    if (cmdKeys)
	      {
		if ((modifierState == CommandKeyBit) || (modifierState == CommandKeyBit + ShiftKeyBit))
		  switch (keyCode)
		    {
		    case '?': [self showHelp: self];		keyCode= 0; break;
		    case 'h': [self hide: self];		keyCode= 0; break;
		    case 'k': [self performDisableKeys: self];	keyCode= 0; break;
		    case 'm': [win  performMiniaturize: self];	keyCode= 0; break;
		    case 'q': [self maybeTerminate: self];	keyCode= 0; break;
		    }
		else if (modifierState == CommandKeyBit + OptionKeyBit)
		  switch (keyCode)
		    {
		    case 'h': [self hideOtherApplications: self];	keyCode= 0; break;
		    }
	      }
	    if (keyCode)
	      {
		noteKeyboardEvent(keyCode, EventKeyDown, modifierState);
		noteKeyboardEvent(keyCode, EventKeyChar, modifierState);
		recordKeystroke(keyCode);			/* DEPRECATED */
	      }
	  }
      }
      break;

    case NSKeyUp:
      {
	int keyCode= qz2sqKey(event);
	if (keyCode)
	  {
	    modifierState= qz2sqModifiers([event modifierFlags]);
	    noteKeyboardEvent(keyCode, EventKeyUp, modifierState);
	    accentMap= 0;
	  }
      }
      break;

    case NSScrollWheel:
      {
	int keyCode= ([event deltaY] >= 0.0) ? 30 : 31;
	noteKeyboardEvent(keyCode, EventKeyDown, modifierState);
	noteKeyboardEvent(keyCode, EventKeyChar, modifierState);
	noteKeyboardEvent(keyCode, EventKeyUp,   modifierState);
      }
      break;

    case NSAppKitDefined:
      switch ([event subtype])
	{
	case NSApplicationActivatedEventType:
	  active= 1;
	  break;

	case NSApplicationDeactivatedEventType:
	  active= 0;
	  break;
	  // case NSScreenChangedEventType: //xxx this means the window
	  // changed to a different physical screen, which is useless
	  // info (we'd far rather be informed that the current screen's
	  // depth has changed)
	}
      //DPRINTF(("AppKitDefinedEvent subtype %d\n", [event subtype]));
      [super sendEvent: event];
      break;

      // case NSFlagsChanged:
      // case NSApplicationDefined: break;
      // case NSPeriodic: break;
      // case NSCursorUpdate: break;

    default: // almost always NSSystemDefined
      //DPRINTF(("Event type %d subtype %d\n", [event type], [event subtype]));
      [super sendEvent: event];
    }
}


+ (void) initialize
{
  NSMutableDictionary *dict;
  NSUserDefaults *defaults;

  defaults= [NSUserDefaults standardUserDefaults];
  dict= [NSMutableDictionary dictionary];
    
  [dict setObject: @"YES" forKey: @"AppleDockIconEnabled"];
  [defaults registerDefaults: dict];
}


static char *documentName= 0;


-(BOOL) application: (NSApplication *) theApplication
	openFile:    (NSString *)      filename
{
  if (fromFinder)
    documentName= strdup([filename cString]);
  return YES;
}


-(void) applicationDidFinishLaunching: (NSNotification *) note
{
  int fds[2];

  // this saves an awful lot of tedious mutex contention (and besides
  // is essentially free, since there's no way to avoid writing a
  // socket to inform aio of the availability of the event)
#if 0
  if (socketpair(AF_UNIX, SOCK_STREAM, 0, fds) != 0)
    {
      perror("socketpair");
      exit(1);
    }
  osXfd= fds[0];
  stXfd= fds[1];
#else
  if (pipe(fds))
    {
      perror("pipe");
      exit(1);
    }
  stXfd= fds[0];
  osXfd= fds[1];
#endif
  aioEnable(stXfd, 0, 0);
  aioHandle(stXfd, evtHandler, AIO_RX);
  {
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
#  ifndef NDEBUG
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
#  endif
    if (pthread_mutex_init(&displayMx, &attr))
      {
	perror("pthread_mutex_init");
	exit(1);
      }
    pthread_mutexattr_destroy(&attr);
  }

  if (fromFinder)
    {
      char *ptr= 0;
      strncpy(resourcePath, argVec[0], sizeof(resourcePath));	// .app/Contents/MacOS/squeak
      if ((ptr= strrchr(resourcePath, '/')))
	{
	  *ptr= '\0';						// .app/Contents/MacOS
	  if ((ptr= strrchr(resourcePath, '/')))
	    {
	      *ptr= '\0';						// .app/Contents
	      strcpy(ptr, "/Resources/");				// .app/Contents/Resources/
	    }
	  else
	    resourcePath[0]= '\0';
	}
      else
	resourcePath[0]= '\0';
    }

  imgInit();

  // vmPath has been set to the realpath() of the VM, which might be
  // bogus (since the more cultivated OS X user will make it a symlink
  // to /usr/local/bin/squeak).  put it back where it should be.  note
  // that we would also like to pick up the sources file from
  // resourcePath/SqueakV*.sources, but I guess the stupid image is
  // going to look for it in the vmPath.  ho hum.
  {
    char *ptr;
    assert(strlen(argVec[0]) < MAXPATHLEN);
    strcpy(vmPath, argVec[0]);
    if ((ptr= strrchr(vmPath, '/')))
      ptr[1]= '\0';
  }

  setUpDisplay();
  printf("fullScreenFlag %d\n", getFullScreenFlag());
  setUpWindow(fullscreen= getFullScreenFlag());

  [NSThread
    detachNewThreadSelector: @selector(interpret:)
    toTarget:		     self
    withObject:		     nil];
}


- (void) interpret: (id)context
{
  [[NSAutoreleasePool alloc] init];	// running in new thread
  interpret();
  (void)recordMouseEvent;
  (void)recordKeyboardEvent;
  (void)recordDragEvent;
}


- (void) applicationDidChangeScreenParameters: (NSNotification *)note
{
  //xxx this one might be tricky in the absence of appWillChangeScreenParams:
  fprintf(stderr, "your Squeak is probably about to dump core...\n");	//xxx FIXME SOON!
}


- (void) unhideAllApplications: (id)sender
{
  [super unhideAllApplications: sender];
  [win orderFront: self]; // so that unhinding once more will reveal the Sq window
}


- (BOOL) windowShouldClose: (id)sender
{
  return NO;
}


- (void) terminate: (id)sender
{
  [super terminate: sender];
  exit(0);
}

- (void) maybeTerminate: (id)sender
{
  switch (NSRunAlertPanel(@"Really quit?",
			  @"All changes since your last save will be lost.\n\nIf you want to save your changes, press `Cancel' and then choose `save and quit' from the background menu in the Squeak window.",
			  @"Quit",
			  @"Cancel",
			  nil))
    {
    case NSAlertDefaultReturn:	[self terminate: self];
    }
}


- (void) performAbout: (id)sender
{
  extern char *getVersionInfo(int verbose);
  char *info= getVersionInfo(1);
  NSPanel *panel= NSGetInformationalAlertPanel(@"About Squeak",
					       @"%s",
					       @"Dismiss",
					       nil,
					       nil,
					       info);
  NSRect frame= [panel frame];
  frame.size.width *= 1.5;
  [panel setFrame: frame display: NO];
  [NSApp runModalForWindow: panel];
  [panel close];
  free(info);
}



//xxx why does rebuilding the menu lose boldface on the Apple menu item???

- (void) performEnableKeys:  (id)sender	{ cmdKeys= 1;  setUpMenus(); }
- (void) performDisableKeys: (id)sender	{ cmdKeys= 0;  setUpMenus(); }


- (void) windowWillMove: (NSNotification *)note
{
  //xxx FIXME SOON: there are other ways to enter this (and ways other than
  // noteEvent to escape from it)
  inModalLoop= 1;
}


- (NSSize) windowWillResize: (NSWindow *)sender toSize: (NSSize)size
{
  return glActive ? [sender frame].size : size;
}


- (void) windowDidResize: (NSNotification *)note
{
  reframeRenderers();
}


@end // Squeak



@implementation SqueakWindow

- (BOOL) isOpaque		{ return YES; }
- (BOOL) canBecomeKeyWindow	{ return YES; }

- (void) setIcon
{
  /////////////xxxxxxxxxxxxxxxxxxxxxxxxxx REMOVE
  icon= [[NSImage alloc] initWithContentsOfFile: @"transp.icns"];
  if (icon)
    [NSApp setApplicationIconImage: icon];
}

- (NSImage *) dockImage
{
  NSBitmapImageRep *rep= [NSBitmapImageRep alloc];
  if ([rep initWithFocusedViewRect: topRect])
    {
      NSImage *image= [[NSImage alloc] init];
      [image addRepresentation: rep];
      if (icon)
	{
	  [image lockFocus];
	  [icon drawInRect: NSMakeRect(0, 0, [image size].width, [image size].height)
		fromRect:   NSMakeRect(0, 0, [icon size].width, [icon size].height)
		operation:  NSCompositeSourceOver
		fraction:   1.0];
	  [image unlockFocus];
	}
      return image;
    }
  return nil;
}

- (void) performMiniaturize: (id)sender
{
  if (!glActive)
    [super performMiniaturize: sender];
}

- (void) miniaturize: (id)sender
{
  NSImage *image= [self dockImage];
  if (image)
    [self setMiniwindowImage: image];
  [image release];
  [super miniaturize: sender];
}


@end // SqueakWindow



@implementation SqueakView

- (BOOL) isOpaque		{ return YES; }
- (BOOL) isFlipped		{ return YES; }
- (BOOL) acceptsFirstResponder	{ return YES; }
- (BOOL) becomeFirstResponder	{ return YES; }
- (BOOL) resignFirstResponder	{ return NO; }

- (id) initWithFrame: (NSRect)frame
{
  id result= [super initWithFrame: frame];
  if (self == result)
    [self registerForDraggedTypes:
	    [NSArray arrayWithObjects:
		       NSFilenamesPboardType, nil]];
  return result;
}


- (void) setFrame: (NSRect)rect
{
  lock(display);
  [super setFrame: rect];
  if ([self inLiveResize])
    {
#    if (RESIZE_IN_TITLE)
      display_winSetName(shortImageName);
#    endif
    }
  else
    if ([self qdPort])
      updatePix();
  unlock(display);
}


- (void) drawRect: (NSRect)rect		// view already has focus
{
  printf("drawRect:\n");
  if ([self inLiveResize])
    {
      [[NSColor whiteColor] set];
      NSRectFill(rect);
      drawImage([[NSGraphicsContext currentContext] graphicsPort], 0);
    }
  else
    {
      if (!pixBase)
	{
	  printf("drawRect: calling updatePix\n");
	  assert([self qdPort]);
	  updatePix();
	}
      fullDisplayUpdate();
    }
}

- (void) viewWillStartLiveResize
{
  captureImage(1);
  [win setShowsResizeIndicator: YES];
  
#if (RESIZE_IN_TITLE)
  showExtent= 1;
  display_winSetName(shortImageName);
#endif
  pixWidth= 0;
  pixHeight= 0;
}

- (void) viewDidEndLiveResize
{
  releaseImage(1);
  [win setShowsResizeIndicator: NO];
#if (RESIZE_IN_TITLE)
  showExtent= 0;
  display_winSetName(shortImageName);
#endif
  updatePix();
  fullDisplayUpdate(); // gets rid of the resize icon if window didn't resize
}


- (int) draggingEntered: (id<NSDraggingInfo>)info
{
  if ((dragCount == 0) // cannot drag again until previous drag completes
      && ([info draggingSourceOperationMask] & NSDragOperationCopy))
    {
      int count= [[[info draggingPasteboard]
		    propertyListForType: NSFilenamesPboardType] count];
      noteMousePoint([info draggingLocation]);
      noteDragEvent(SQDragEnter, dragCount= count);
      return NSDragOperationCopy;
    }
  return NSDragOperationNone;
}

- (int) draggingUpdated: (id<NSDraggingInfo>)info
{
  noteMousePoint([info draggingLocation]);
  noteDragEvent(SQDragMove, dragCount);
  return NSDragOperationCopy;
}

- (void) draggingExited: (id<NSDraggingInfo>)info
{
  noteMousePoint([info draggingLocation]);
  noteDragEvent(SQDragLeave, dragCount);
  dragCount= 0;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)info
{
  NSPasteboard *pboard= [info draggingPasteboard];
  noteMousePoint([info draggingLocation]);
  if ([[pboard types] containsObject: NSFilenamesPboardType])
    {
      NSArray *files= [pboard propertyListForType: NSFilenamesPboardType];
      int i;
      if (uxDropFileCount)
	{
	  assert(uxDropFileNames);
	  for (i= 0;  i < uxDropFileCount;  ++i)
	    free(uxDropFileNames[i]);
	  free(uxDropFileNames);
	  uxDropFileNames= 0;
	}
      if ((  (!(uxDropFileCount= [files count])))
	  || (!(uxDropFileNames= (char **)malloc(uxDropFileCount * sizeof(char *)))))
	{
	  uxDropFileCount= 0;
	  return NO;
	}
      for (i= 0;  i < uxDropFileCount;  ++i)
	uxDropFileNames[i]= strdup([[files objectAtIndex: i] cString]);
    }
  noteDragEvent(SQDragDrop, uxDropFileCount);
  dragCount= 0;

  return YES;	// under some duress, I might add (see sqUxDragDrop.c)
}


@end // SqueakView



/// 
/// Dialogues for sqUnixMain
/// 


@interface ProgressBar : NSPanel
{
  NSText		*message;
  NSProgressIndicator	*indicator;
  int			 value;
  NSModalSession	 session;
}
+(ProgressBar *) openWithTitle: (NSString *) title message: (NSString *) message;
-(void) displayProgressFrom: (int) min to: (int) max during: (void (*)(ProgressBar *)) thunk;
-(id)   value: (int) value;
-(id)   setMinValue: (int) value;
-(id)   setMaxValue: (int) value;
-(void) close;
@end

@implementation ProgressBar

-(id) initWithTitle: (NSString *) titleString message: (NSString *) messageString
{
  NSSize messageSize;
  NSProgressIndicator *ind;
  NSText *text;
  int inset, y, w;

  message= 0;
  indicator= 0;
  value= 0;
  messageSize= (nil == messageString)
    ? NSMakeSize(0,0)
    : [messageString sizeWithAttributes: nil];
  inset= 10;
  y= inset;
  w= max(100, messageSize.width + 50);
  ind= [[NSProgressIndicator alloc]
	 initWithFrame: NSMakeRect(inset, y, w, NSProgressIndicatorPreferredThickness)];
  [ind setIndeterminate: NO];
  y += NSProgressIndicatorPreferredThickness + inset;
  text= [[NSText alloc] initWithFrame: NSMakeRect(inset, y, w, messageSize.height)];
  [text setString: messageString];
  [text setEditable: NO];
  y += messageSize.height + inset;
  if ((self= [super initWithContentRect: NSMakeRect(0, 0, w + inset * 2, y)
		    styleMask:           ((nil == titleString)
					  ? NSBorderlessWindowMask
					  : NSTitledWindowMask)
		    backing:             NSBackingStoreBuffered
		    defer:               NO]))
    {
      [[self contentView] addSubview: (indicator= ind)];
      [[self contentView] addSubview: (message= text)];
      if (nil != titleString)
	[self setTitle: titleString];
      session= [NSApp beginModalSessionForWindow: self];
    }
  return self;
}

+(ProgressBar *) openWithTitle: (NSString *) titleString
		       message: (NSString *) messageString
{
  ProgressBar *bar= [[ProgressBar alloc] initWithTitle: titleString message: messageString];
  [bar center];
  [bar makeKeyAndOrderFront: nil];
  return bar;
}

-(id) setMinValue: (int) min
{
  [indicator setMinValue: (double)min];
  return self;
}

-(id) setMaxValue: (int) max
{
  [indicator setMaxValue: (double)max];
  return self;
}

-(id) value: (int) newValue
{
  if (newValue != value)
    {
      value= newValue;
      [indicator setDoubleValue: (double) value];
      [indicator displayIfNeeded];
      [NSApp runModalSession: session];
    }
  return self;
}

-(void) dealloc
{
  if (message) [message release];
  if (indicator) [indicator release];
  [super dealloc];
}

-(void) close
{
  [NSApp endModalSession: session];
  [super close];
  [self release];
}

-(void) displayProgressFrom: (int) min to: (int) max during: (void (*)(ProgressBar *)) thunk
{
  [indicator setMinValue: (double)min];
  [indicator setMaxValue: (double)max];
  thunk(self);
}

@end // ProgressBar


static int fileCopy(char *src, char *dst)
{
  int in, out, r= -1;
  struct stat st;
  if (stat(src, &st)) return (errno= ENOENT);
  if ((in=  open(src, O_RDONLY)) < 0) return (errno= ENOENT);
  if ((out= open(dst, O_WRONLY | O_CREAT | O_TRUNC, 0755)) >= 0)
    {
      char *buf;
      int  done;
      ProgressBar *bar= [ProgressBar openWithTitle: @"Writing..."
				     message: [NSString stringWithCString: dst]];
      [bar setMaxValue: (double)st.st_size];
      buf= (char *)alloca(st.st_blksize);
      done= 0;
      while ((r= read(in, buf, st.st_blksize)) > 0)
	if (r == write(out, buf, r))
	  {
	    done += r;
	    [bar value: done];
	  }
	else
	  {
	    r= -1;
	    break;
	  }
      [bar close];
      close(out);
    }
  close(in);
  return (r == 0) ? 0 : errno;
}


static void copyFile(const char *filename, char *ext, char *source)
{
  char dest[MAXPATHLEN], *ptr= 0;
  strncpy(dest, filename, sizeof(dest));
  if ((ptr= strrchr(dest, '.')))
    {
      strcpy(ptr, ext);
      if (fileCopy(source, dest))
	{
	  perror("FileCopy");
	  NSRunCriticalAlertPanel(@"Oops...",
				  @"I encountered an error while copying the image/changes files.  The system told me `%s'.  Sorry."
				  @"Quit",
				  nil,
				  nil,
				  [NSString stringWithCString: strerror(errno)]);
	  exit(1);
	}
    }
}


static void display_winImageNotFound(void)	{}


static int winCopyOrOpen(void)
{
  switch (NSRunAlertPanel(@"Create a new image?",
			  @"You have started Squeak without specifying an image file.  Would you like to create a new image or open an image that you saved earlier?",
			  @"Open",
			  @"Cancel",
			  @"New"))
    {
    case NSAlertDefaultReturn:	return 0;	// open
    case NSAlertOtherReturn:	return 1;	// new
    default:					// cancel or error
      exit(0);
    }
  return 0;
}


static int winImageCopy(char *buf, int len, char *image, char *changes)
{
  NSSavePanel *panel= [NSSavePanel savePanel];
  NSString    *home=  [NSString stringWithCString: getenv("HOME")];
  int          reply;
  //xxx release the string

  [panel setTitle: @"Where should I save the new image file?"];
  [panel setRequiredFileType: @"image"];
  [panel setFloatingPanel: YES];
  [panel setOneShot: YES];
  [panel setReleasedWhenClosed: YES]; //xxx does the previous imply this???
//[panel setContentSize: NSMakeSize(400, 350)];
  [panel center];

  reply= [panel runModalForDirectory: home file: @"squeak.image"];
//[home release];

  if (NSFileHandlingPanelOKButton == reply)
    {
      const char *path= [[panel filename]  cString];
      copyFile(path, ".image",   image);
      copyFile(path, ".changes", changes);
      strncpy(buf, path, len);
      return 1;
    }
  return 0;
}


static int winImageOpen(char *buf, int len)
{
  NSOpenPanel *panel= [NSOpenPanel openPanel];

  [panel setTitle: @"Which image file should I open?"];
  [panel setFloatingPanel: YES];
  [panel setOneShot: YES];
  [panel setReleasedWhenClosed: YES]; //xxx does the previous imply this???
//[panel setContentSize: NSMakeSize(400, 350)];
  [panel center];

  if (NSOKButton == [panel runModalForTypes: [NSArray arrayWithObject: @"image"]])
    {
      NSArray *files= [panel filenames];
      if (1 == [files count])
	{
	  strncpy(buf, [[files objectAtIndex: 0] cString], len);
	  return 1;
	}
    }
  return 0;
}


static int display_winImageFind(char *buf, int len)
{
  if (documentName)
    {
      strncpy(buf, documentName, len);
      free(documentName);
      documentName= 0;
      return 1;
    }
  else
    {
      char image[MAXPATHLEN], changes[MAXPATHLEN];
      strlcat(strncpy(image, resourcePath, sizeof(image)),
	      "squeak.image",
	      sizeof(image));
      strlcat(strncpy(changes, resourcePath, sizeof(changes)),
	      "squeak.changes",
	      sizeof(changes));
      return ((  (0 == access(image,   R_OK)))
	      && (0 == access(changes, R_OK))
	      && winCopyOrOpen())
	? winImageCopy(buf, len, image, changes)
	: winImageOpen(buf, len);
    }
  return 0;
}


static int display_primitivePluginBrowserReady()	{ return primitiveFail(); }
static int display_primitivePluginRequestURLStream()	{ return primitiveFail(); }
static int display_primitivePluginRequestURL()		{ return primitiveFail(); }
static int display_primitivePluginPostURL()		{ return primitiveFail(); }
static int display_primitivePluginRequestFileHandle()	{ return primitiveFail(); }
static int display_primitivePluginDestroyRequest()	{ return primitiveFail(); }
static int display_primitivePluginRequestState()	{ return primitiveFail(); }


/// 
/// OpenGL stuff
/// 


#include <OpenGL/OpenGL.h>

#include "B3DAcceleratorPlugin.h"
#include "sqOpenGLRenderer.h"
#include "sqUnixQuartzGL.h"

#define renderView(R)		(assert(R), (NSOpenGLView    *)((R)->drawable))
#define renderContext(R)	(assert(R), (NSOpenGLContext *)((R)->context))

static glRenderer *renderers[MAX_RENDERER];

static int display_ioGLinitialise(void)
{
  int i;
  for (i= 0;  i < MAX_RENDERER;  ++i)
    renderers[i]= 0;
  glActive= 0;
  return 1;
}

static void addRenderer(glRenderer *r)
{
  int i;
  for (i= 0;  i < MAX_RENDERER;  ++i)
    if (!renderers[i])
      {
	renderers[i]= r;
	++glActive;
	return;
      }
  assert(!"this cannot happen");
}

static void removeRenderer(glRenderer *r)
{
  int i;
  for (i= 0;  i < MAX_RENDERER;  ++i)
    if (renderers[i] == r)
      {
	renderers[i]= 0;
	--glActive;
	return;
      }
  assert(!"this cannot happen");
}

// fix dumb inverted coordinates after window geometry change

static void reframeRenderer(glRenderer *r)
{
  NSRect frame= NSMakeRect(r->bufferRect[0], r->bufferRect[1],
			   r->bufferRect[2], r->bufferRect[3]);
  frame.origin.y= [topView bounds].size.height - frame.size.height - frame.origin.y;
  [renderView(r) removeFromSuperview];
  [renderView(r) setFrame: frame];
  [topView addSubview: renderView(r)];
}

static void reframeRenderers(void)
{
  int i;
  for (i= 0;  i < MAX_RENDERER;  ++i)
    if (renderers[i])
      reframeRenderer(renderers[i]);
}

#if 0

static void updateRenderer(glRenderer *r)
{
  [[renderView(r) openGLContext] makeCurrentContext];
}

static void updateRenderers(void)
{
  int i;
  for (i= 0;  i < MAX_RENDERER;  ++i)
    if (renderers[i])
      updateRenderer(renderers[i]);
}

#endif


static int display_ioGLcreateRenderer(glRenderer *r, int x, int y, int w, int h, int flags)
{
  long swapInterval;
  NSOpenGLView *drawable;
  NSOpenGLPixelFormatAttribute attrs[]=
    {
      NSOpenGLPFANoRecovery,
      NSOpenGLPFAWindow,
      NSOpenGLPFAAccelerated,
      NSOpenGLPFADoubleBuffer,
      //NSOpenGLPFAColorSize,	16, //24
      NSOpenGLPFAAlphaSize,	 8, //8
      NSOpenGLPFADepthSize,	24, //16
      NSOpenGLPFAStencilSize,	((flags & B3D_STENCIL_BUFFER) ? 8 : 0),
      NSOpenGLPFAAccumSize, 0,
      0
    };
  NSOpenGLPixelFormat *fmt= [[NSOpenGLPixelFormat alloc] initWithAttributes: attrs];
  if (!fmt)
    {
      fprintf(stderr, "ioGLcreateRenderer: illegal pixel format\n");
      return 0;
    }

  if (verboseLevel >= 3)
    printFormatInfo(fmt);

  drawable= [[NSOpenGLView alloc]
	      initWithFrame: NSMakeRect(x, [topView bounds].size.height - h - y, w, h)
	      pixelFormat:   fmt];
  [fmt release];
  if (!drawable)
    {
      fprintf(stderr, "ioGLcreateRenderer: could not create view\n");
      return 0;
    }
  r->drawable= drawable;
  r->context=  [drawable openGLContext];
  addRenderer(r);

  swapInterval= 0;

  [renderContext(r) setValues: &swapInterval forParameter: NSOpenGLCPSwapInterval];
  [topView addSubview: drawable];

  return 1;

  (void)glErrString;	// declared static in sqOpenGLRenderer.h, but never used
}


static int display_ioGLmakeCurrentRenderer(glRenderer *r)
{
  if (r)
    {
      assert(r->context);
      [renderContext(r) makeCurrentContext];
    }
  else
    [NSOpenGLContext clearCurrentContext];

  return 1;
}


static void display_ioGLdestroyRenderer(glRenderer *r)
{
  [NSOpenGLContext clearCurrentContext];
  assert(r->drawable);
  [renderView(r) removeFromSuperview];
  [renderView(r) release];
  removeRenderer(r);
}


static void display_ioGLswapBuffers(glRenderer *r)
{
  assert(r->context);
  [renderContext(r) flushBuffer];
}


static void display_ioGLsetBufferRect(glRenderer *r, int x, int y, int w, int h)
{
  NSRect frame= NSMakeRect(x, y, w, h);
  fprintf(stderr, "ioGLsetBufferRect(%p, %d, %d, %d, %d)\n", r->context, x, y, w, h);
  assert(r->context);
  frame.origin.y= [topView bounds].size.height - frame.size.height - frame.origin.y;
  fprintf(stderr, "view setFrame: %d %d %d %d\n",
	  (int)frame.origin.x, (int)frame.origin.y, (int)frame.size.width, (int)frame.size.height);
  [renderView(r) setFrame: frame];
}



SqDisplayDefine(Quartz);


#include "SqModule.h"

static void *display_makeInterface(void)
{
  return &display_Quartz_itf;
}

SqModuleDefine(display, Quartz);
