
/* sqQNXScreenDisplay.c -- display driver for QNX Screen subsystem
 * 
 * Author: Ken Dickey <Ken.Dickey@Whidbey.COM>
 */

/* 
 * Copyright (C) 2025 Kenneth Alan Dickey
 * All Rights Reserved.
 * 
 * This file is part of the OpenSmalltalk-VM
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

/*
  OpenSmalltalk-vm
    https://OpenSmalltalk.org
    https://github.com/OpenSmalltalk/opensmalltalk-vm
  
  QNX free licence & details at
    https://qnx.com/getqnx

  QNX 8.0 Screen Developer Documentation
    https://www.qnx.com/developers/docs/8.0/
    	  com.qnx.doc.screen/topic/manual/cscreen_about.html

  Source cross-compiled on Ubuntu/Mint Linux on x86_64
  for target system: Raspberry Pi 4 (aarch64) + QNX 8.0

  VM Interface
    --  struct SqDisplay = access via ioGetDisplayModule()
    VM/platforms/unix/vm/SqDisplay.h -- struct sqDisplay def
    VM/platforms/Cross/vm/sq.h  -- Display/Keyboard/Mouse + events
    VM/platforms/unix/vm/sqUnixEvent.c -- SqPoint, mousePosition, recordMouseEvent()
    VM/platforms/unix/vm-display-custom/sqUnixCustomModule.h -- generic starting point
*/

/* OpenSmalltalk VM */
#include "sq.h"
#include "sqUnixMain.h"
#include "sqUnixGlobals.h"
#include "sqaio.h"

#include "SqDisplay.h"

#if defined(ioMSecs)
# undef ioMSecs
#endif

/* POSIX */
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/select.h>
#include <stdarg.h>
#include <stdbool.h>
#include <assert.h>

/* QNX */
#include <screen/screen.h>
#include <sys/keycodes.h>

//----------------------------------------------------------------

#include "sqUnixEvent.c"

//static inline int min(int a, int b) { return a < b ? a : b; }
//static inline int max(int a, int b) { return a > b ? a : b; }

/* Splash Screen Display Image: Squeak Balloon */

/* Pixels are kept as 32 bits: uint32_t */
typedef uint32_t pixel_t;
#include "Balloon.h"  /* Squeak Balloon image */
/* Forward declarations */
static void failPermissions(const char *who);
void handleKeyboardEvent(screen_event_t keyEvent);
void handlePointerEvent(screen_event_t keyEvent); /* mouse events */
void printQNXKeyFlags(int flags);
void printQNXModifiers(int modifiers);
void printQNXMouseButtons(int buttons);
void printQNXPCKeys(int keyCode);
static void showBalloons(void * bufPtr);
static void showBalloonAt(void *bufPtr, int left, int top);
static inline void putPixel(int x, int y, pixel_t pix);
static inline pixel_t getPixel(int x, int y);
const pixel_t blackPixel = 0x00000000;
const pixel_t whitePixel = 0x00FFFFFF;
static void showCursor(void);
static int cursorIn(int l, int r, int t, int b);
static inline void showCursorIn(int l, int r, int t, int b);
static inline void hideCursorIn(int l, int r, int t, int b);
static void setCursor(char *bits, char *mask, int xoff, int yoff);
static void advanceCursor(int dx, int dy);
static void cursorTo(int x, int y);


/* Software Defined Cursor Info */
static int cursorBits[] = {
  0b0000000000000000,
  0b0100000000000000,
  0b0110000000000000,
  0b0111000000000000,
  0b0111100000000000,
  0b0111110000000000,
  0b0111111000000000,
  0b0111111100000000,
  0b0111111110000000,
  0b0111110000000000,
  0b0110110000000000,
  0b0100011000000000,
  0b0000011000000000,
  0b0000001100000000,
  0b0000001100000000,
  0b0000000000000000
};
static int maskBits[] =  {
  0b1100000000000000,
  0b1110000000000000,
  0b1111000000000000,
  0b1111100000000000,
  0b1111110000000000,
  0b1111111000000000,
  0b1111111100000000,
  0b1111111110000000,
  0b1111111111000000,
  0b1111111111100000,
  0b1111111000000000,
  0b1110111100000000,
  0b1100111100000000,
  0b1000011110000000,
  0b0000011110000000,
  0b0000001110000000
};

struct softCursor {
  SqPoint	position;
  SqPoint	offset;
  int		visible;
  uint16_t	bits[16];
  uint16_t	mask[16];
  pixel_t	back[16][16];
};

/* QNX data structures */
screen_context_t screenContext = NULL;
screen_event_t   userEvent;
screen_window_t  window;
screen_session_t keyboardSession;
screen_buffer_t	 buffer;
void* bufPointer; /* buffer pointer */
int   stride;     /* buffer stride (bytes per scan line) */
int   displaySize[2];    /* {width,height} in pixels */
const int alwaysTrue = 1;

static inline int screenWidth(void)  { return displaySize[0]; }
static inline int screenHeight(void) { return displaySize[1]; }


/* OVERVIEW:
   - Create a Screen/Graphic Context
   - Create a Render Target
     + Set Render Properties
   - Allocate Pixmap Buffers
   - Render into Buffers
     + Post/Update to (re)draw a Buffer
   - Attache Devices [Keyboard,Mouse/Pointer,MultiTouch,Joystick]
   - Run Event Loop

 Note that microkernel message passing implies copying event data
 from external io managers into local storage.  When an event is
 received, an io manager process dealloctes its event data.

 Here we are staying simple.  Our application (the VM) is assumed
 here with a single Display, a Mouse, and a Keyboard.  Windowing
 is our own Smalltalk Windows/Morphs within a single QNX Window
 which is the size of the single/main Display. Software rendering.

 QNX architects for multiple displays, Windows, touch events, joystick, game pad..
 Future projects not addressed here.  Touch events will need VM support.
*/

#if (DEBUG)
static bool DPRINTF_redirecting = false;
typedef struct _debugmsg debugmsg;
struct _debugmsg {
  char* msg;
  debugmsg* next;
};
static debugmsg* DPRINTF_debugmsg = NULL;
static debugmsg* DPRINTF_debugmsg_new(void)
{
  debugmsg* msg = calloc(1, sizeof(debugmsg));
  if (!msg) {
    perror("no mem for redirect");
    exit(1);
  }
  if (!DPRINTF_debugmsg) {
    DPRINTF_debugmsg = msg;
  } else {
    debugmsg* cur = DPRINTF_debugmsg;
    while (cur->next != NULL) {
      cur = cur->next;
    }
    cur->next = msg;
  }
  return msg;
}

static void DPRINTF(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  if (DPRINTF_redirecting) {
    debugmsg* new = DPRINTF_debugmsg_new();
    vasprintf(&(new->msg), fmt, ap);
  } else {
    vprintf(fmt, ap);
  }
  va_end(ap);
}

static void DPRINTF_REDIRECT(bool flag)
{
  if (flag) {
    printf("DEBUG: saving incoming debug messages\n");
    fflush(stdout);
    fflush(stderr);
    DPRINTF_redirecting = true;
  } else {
    DPRINTF_redirecting = false;
    fflush(stdout);
    fflush(stderr);
    printf("DEBUG: replaying saved debug messages\n");
    debugmsg* cur = DPRINTF_debugmsg;
    while (cur != NULL) {
      printf("%s", cur->msg);
      debugmsg* next = cur->next;
      free(cur);
      cur=next;
    }
    fflush(stdout);
    fflush(stderr);
  }
}
#else
#define DPRINTF(fmt, ...)
#define DPRINTF_REDIRECT(b)
#endif

static void fatalError(const char *who)
{
  perror(who);
  exit(1);
}

static void fatal(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\n");
  exit(1);
}

static void outOfMemory(void)
{
  fatal("out of memory");
}


//----------------------------------------------------------------
/* PIXELS */

static inline int pixelPosition(int x, int y) {
  return ( (x * 4) /* 4 = (32/8) = bits-per-pixel/bits-per-byte = bytes/pixel  */
	 + (y * stride) ); /* stride = bytes per scan line */
}

static inline void putPixel(int x, int y, pixel_t pix)
{
  if ((x >= 0) && (y >= 0) && (x < screenWidth()) && (y < screenHeight()))
    {
      *((pixel_t *)(bufPointer + pixelPosition(x,y))) = pix;
    }
}

static inline pixel_t getPixel(int x, int y)
{
  return ((x >= 0) && (y >= 0) && (x < screenWidth()) && (y < screenHeight()))
    ? *((pixel_t *)(bufPointer + pixelPosition(x,y)))
    : 0;
}

 static inline void drawPixel(int x, int y, int r, int g, int b)
 {
   putPixel(x, y, (pixel_t)((r << 16) | (g << 8) | (b << 0)));
 }


//----------------------------------------------------------------
/* Soft(ware) Cursor Management */
 
struct softCursor cursor;

void initCursor(void)
{
  int x,y;
  
  cursor.position.x = screenHeight() / 2;
  cursor.position.y = screenWidth() / 2;
  cursor.offset.x = 0; /* Cuis has cursor: -1@-1, mask: 0@0 */
  cursor.offset.y = 0;
  cursor.visible  = 0;
 
  for (x = 0; x < 16; x++) {
    cursor.bits[x] = cursorBits[x];
    cursor.mask[x] = maskBits[x];
    for (y = 0; y < 16; y++) {
      cursor.back[x][y] = 0;
    }
  }
  showCursor();
}

static void hideCursor(void)
{
  if (cursor.visible)
    {
      int xo= cursor.position.x + cursor.offset.x;
      int yo= cursor.position.y + cursor.offset.y;
      int x, y;
      for (y= 0; y < 16; y++)
	for (x= 0; x < 16; x++)
	  putPixel( xo + x, yo + y, cursor.back[y][x] );
      cursor.visible= 0;
    }
}

static void showCursor(void)
{
  if (!cursor.visible)
    {
      int xo= cursor.position.x + cursor.offset.x;
      int yo= cursor.position.y + cursor.offset.y;
      int y;
      for (y= 0; y < 16; y += 1)
	{
	  unsigned short bits= cursor.bits[y];
	  unsigned short mask= cursor.mask[y];
	  int x;
	  for (x= 0; x < 16; x += 1)
	    {
	      /* Look at top bit, then shift & look at next bit.. */
	      cursor.back[y][x]= getPixel( xo + x, yo + y );
	      if      (bits & 0x8000) putPixel( xo + x, yo + y, blackPixel );
	      else if (mask & 0x8000) putPixel( xo + x, yo + y, whitePixel );
	      bits <<= 1;
	      mask <<= 1;
	    }
	}
      cursor.visible = 1;
    }
}

static int cursorIn(int l, int r, int t, int b)
{
  int cl= cursor.position.x + cursor.offset.x;
  int cr= cl + 15;
  int ct= cursor.position.y + cursor.offset.y;
  int cb= ct + 15;
  return !((cr < l) || (cl > r) || (ct > b) || (cb < t));
}

static inline void hideCursorIn(int l, int r, int t, int b)
{
  if (cursorIn(l, r, t, b))
    hideCursor();
}

static inline void showCursorIn(int l, int r, int t, int b)
{
  if (cursorIn(l, r, t, b))
    showCursor();
}


static void setCursor(char *bits, char *mask, int xoff, int yoff)
{
  int y;
  hideCursor();
  cursor.offset.x= xoff;
  cursor.offset.y= yoff;
  for (y= 0;  y < 16; y = y+1)
    {
      /* Pick off top 16 bits of 32 bit elements; lower 16 unused */
      cursor.bits[y]=   (((pixel_t *)bits)[y]) >> 16;
      if (mask) {
        cursor.mask[y]= (((pixel_t *)mask)[y]) >> 16;
      } else {  /* unmasked cursor */
        cursor.mask[y]= cursor.bits[y]; /* Black Bits matter */
      }
    }
  showCursor();
}


static void advanceCursor(int dx, int dy)
{
  hideCursor();
  cursor.position.x= max(0, min(cursor.position.x + dx, screenWidth() - 1));
  cursor.position.y= max(0, min(cursor.position.y + dy, screenHeight() - 1));
  showCursor();
}

static void cursorTo(int x, int y)
{
  hideCursor();
  cursor.position.x= x;
  cursor.position.y= y;
  showCursor();
}

//----------------------------------------------------------------

static sqInt display_ioBeep(void)
{
  /* @@FIXME: NYI@@ */
  return 0;
}


static sqInt display_ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
  aioSleepForUsecs(microSeconds);
  return 0;
}


static sqInt display_ioProcessEvents(void)
{
  int objectType, eventType;
  int pollMax = 0;

  while ((pollMax < 1) && (screen_get_event( screenContext, userEvent, 0) == 0)) { /* zero on success */

    pollMax += 1;
    
    if (screen_get_event_property_iv(userEvent,SCREEN_PROPERTY_OBJECT_TYPE,&objectType)
	!= 0) {
	DPRINTF("\nEvent Object type failure.  Errno = 0x%lx", errno);
	break;
    }
    if (screen_get_event_property_iv(userEvent,SCREEN_PROPERTY_OBJECT_TYPE,&objectType)
	!= 0) {
      DPRINTF("\nEvent Object type failure.  Errno = 0x%lx", errno);
      break;
    }
    /* else { */
    /*   printf("\nEvent Object Type: 0x%lx", objectType); */
      /* switch (objectType) { */
      /* case SCREEN_OBJECT_TYPE_CONTEXT: */
      /* 	printf(": Context"); */
      /* 	break; */
      /* case SCREEN_OBJECT_TYPE_GROUP: */
      /* 	printf(": Group"); */
      /* 	break; */
      /* case SCREEN_OBJECT_TYPE_DISPLAY: */
      /* 	printf(": Display"); */
      /* 	break; */
      /* case SCREEN_OBJECT_TYPE_DEVICE: */
      /* 	printf(": Device"); */
      /* 	break; */
      /* case SCREEN_OBJECT_TYPE_PIXMAP: */
      /* 	printf(": Pixmap"); */
      /* 	break; */
      /* case SCREEN_OBJECT_TYPE_SESSION: */
      /* 	printf(": Session"); */
      /* 	break; */
      /* case SCREEN_OBJECT_TYPE_STREAM: */
      /* 	printf(": Stream"); */
      /* 	break; */
      /* case SCREEN_OBJECT_TYPE_WINDOW: */
      /* 	printf(": Window"); */
      /* 	break; */
      /* default: */
      /* 	break; */
      /* } */
    /* } */      
    if (objectType == SCREEN_OBJECT_TYPE_WINDOW) {

      if (screen_get_event_property_iv(userEvent,SCREEN_PROPERTY_TYPE,&eventType) != 0) {
	DPRINTF("\nEvent type failure.  Errno = 0x%lx", errno);
	break;
      }
      
      switch (eventType) {

      case SCREEN_EVENT_NONE:
	  DPRINTF("\nGot NULL Event");
	  break;
	
	case SCREEN_EVENT_KEYBOARD:
	  /* DPRINTF("\nGot KEYBOARD Event"); */
	  handleKeyboardEvent(userEvent);
	  break;

	case SCREEN_EVENT_POINTER:
	  /* DPRINTF("\nGot MOUSE POINTER Event"); */
	  handlePointerEvent(userEvent);
	  break;

	case SCREEN_EVENT_GAMEPAD:
	case SCREEN_EVENT_JOYSTICK:
	  DPRINTF("\nGot Joystick/Game Event");
	  /* handleJoystickEvent(userEvent); */
	  break;
	default:
	  DPRINTF("\nGot UNHANDLED Event Type: 0x%lx", eventType);
	  break;
	}
      }
    }

  pollMax = 0; /* reset */

  return 0;
}


static sqInt display_ioScreenDepth(void)
{
  return 32; /* bits per pixel @@REVISIT: dynamic ask QNX? @@ */
}


static double display_ioScreenScaleFactor(void)
{
  return 1;
}

static sqInt display_ioScreenSize(void)
{ /* QNX Screen: displaySize[2] => {width, height} */
  return ((displaySize[0] << 16) | displaySize[1]);
}


static sqInt display_ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
  setCursor((char *)cursorBitsIndex,
	    (char *)cursorMaskIndex,
	    (int)offsetX,
	    (int)offsetY);
  return 0;
}


static sqInt display_ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
  return 0;
}

static inline unsigned long pixel_position(int x, int y) {
  return (x * sizeof(pixel_t)) +  (y * stride);
}

static sqInt display_ioShowDisplay(sqInt dispBitsIndex,
				   sqInt width, sqInt height,
				   sqInt depth,
				   sqInt left, sqInt right,
				   sqInt top,  sqInt bottom)
{
  int x, y;
  char *bits;

  if ((depth  != display_ioScreenDepth())
      || (width  != screenWidth())
      || (height != screenHeight())
      || (right < left)
      || (bottom < top))
    return 0;

  hideCursorIn(left, right, top, bottom);
  bits = pointerForOop(dispBitsIndex);
  for (y= top;  y < bottom;  y += 1)
    {
      pixel_t *in=  (pixel_t *)(bits + ((left + (y * screenWidth())) * 4));
      pixel_t *out= (pixel_t *)(bufPointer + pixelPosition(left, y));
      for (x= left;  x < right;  x += 1, in += 1, out += 1)
	{
	  out[0]= in[0];
	}
    }
  showCursorIn(left, right, top, bottom);
  return 0;
}


static sqInt display_ioHasDisplayDepth(sqInt i)
{
  DPRINTF("hasDisplayDepth %d (%d) => %d\n", i, 32, (i == 32));
  return (i == 32);
}


static void openDisplay(void)
{
  int sessionVisible = SCREEN_PROPERTY_VISIBLE; /* => active */
  int usage          = SCREEN_USAGE_NATIVE;
  int eventType	     = 0;
  int objectType     = 0;
  
  DPRINTF("openDisplay\n");
  DPRINTF_REDIRECT(true);
  if (screen_create_context(&screenContext,SCREEN_APPLICATION_CONTEXT) < 0) {
    perror("QNX: Cannot create Screen Context");
    exit(errno);
  }

  if (screen_create_window_type(&window,
				screenContext,
				(SCREEN_APPLICATION_WINDOW |SCREEN_ROOT_WINDOW)) < 0) {
    perror("QNX: Cannot create QNX Display Window");
    exit(errno);
  }

  if (screen_create_window_buffers(window, 1) < 0) {
    perror("QNX: Cannot create Window Buffer");
    exit(errno);
  } 

  /* Render Setup */
  screen_set_window_property_iv(window, SCREEN_PROPERTY_FORMAT,
	(const int[]){ SCREEN_FORMAT_RGBX8888 });
  screen_set_window_property_iv(window, SCREEN_PROPERTY_USAGE,
	(const int[]) { SCREEN_USAGE_READ | SCREEN_USAGE_WRITE });
  screen_get_window_property_iv(window, SCREEN_PROPERTY_BUFFER_SIZE, displaySize);
  screen_get_window_property_pv(window, SCREEN_PROPERTY_BUFFERS, (void **)&buffer);
  screen_get_buffer_property_pv(buffer, SCREEN_PROPERTY_POINTER, &bufPointer);
  screen_get_buffer_property_iv(buffer, SCREEN_PROPERTY_STRIDE,  &stride);

  screen_fill(screenContext,
	      buffer, 
	      (const int[]){ SCREEN_BLIT_COLOR, whitePixel, SCREEN_BLIT_END });

  screen_set_window_property_iv(window, SCREEN_PROPERTY_VISIBLE, &alwaysTrue);

  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  showBalloons(bufPointer);
  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  sleep( 1 ); /* Let the user see splash screen */
  
  /* FOR THE USER */
  
  if (screen_create_event(&userEvent) != 0) {
    perror("QNX: Cannot create User Event holder");
    exit(errno);
  }

  /*  ioSetInputSemaphore( 1 ) ; *@@??@@*/
}


static void closeDisplay(void)
{
  DPRINTF("closeDisplay\n");
  DPRINTF_REDIRECT(false);
  screen_destroy_window( window );
  screen_destroy_context( screenContext );
}


static char *display_winSystemName(void)
{
  return "qnxScreenDisplay";
}


static void display_winInit(void)
{
}


static void display_winOpen(int argc, char *dropFiles[])
{
  openDisplay();
  initCursor();
}


static void failPermissions(const char *who)
{
  fprintf(stderr, "Cannot open %s\n", who);
  fprintf(stderr, "You should be running QNX on a Raspberry Pi 4/5\n");
  fprintf(stderr, "  with a Display, Keyboard, & Mouse\n");
  fprintf(stderr, "Check sources at github.com/OpenSmalltalk/opensmalltalk-vm\n");
  fprintf(stderr, "  /platforms/unix/vm-display-qnxScreen\n");
  fprintf(stderr, "Ask/Report on  vm-dev@lists.squeakfoundation.org\n");
  exit(1);
}


static void display_printUsage(void)
{
  printf("\nNO currently used QNX Display options\n");
}


static void display_printUsageNotes(void)
{
  ; /* skip */
}


static void display_parseEnvironment(void)
{
  /*  Currently NO Environment Variables Used */

  /* How2:
  char *ev= 0;
  if ((ev= getenv("SQUEAK_FBDEV")))	fbDev=    strdup(ev);
  if ((ev= getenv("SQUEAK_KBMAP")))	kmPath=   strdup(ev);
  */
}


static int display_parseArgument(int argc, char **argv)
{
  /* Currently NO Arguments Used */

  /* how2: */
  /* int n= 1; */
  /* char *arg= argv[0]; */

  /* if      (!strcmp(arg, "-vtlock"))	 vtLock=   1; */
  /* else if (!strcmp(arg, "-vtswitch"))	 vtSwitch= 1; */
  /* else if (argv[1])	/\* option requires an argument *\/ */
  /*   { */
  /*     n= 2; */
  /*     if      (!strcmp(arg, "-fbdev"))	 fbDev=   argv[1]; */
  /*     else if (!strcmp(arg, "-kbmap"))	 kmPath=  argv[1]; */
  /*     else if (!strcmp(arg, "-msdev"))	 msDev=   argv[1]; */
  /*     else if (!strcmp(arg, "-kbdev"))	 kbDev.kbName=   argv[1];  */
  /*     else if (!strcmp(arg, "-msproto")) msProto= argv[1]; */
  /*     else */
  /* 	n= 0;	/\* not recognised *\/ */
  /*   } */
  /* else */
  /*   n= 0; */
  /* return n; */

  return( 0 ) ;
}

//----------------------------------------------------------------
/* KEYBOARD */

/* Map between QNX Screen World & OpenSmalltalk VM World */
/* Smalltalk: `Sensor kbdTest.` */
int keyMap( int keyValue, int keyFlags, int sqModifiers, int keyCap, int keySym ) {
  int keyResult;
  
  if (keyValue == 0) {
    keyResult = keyCap;  /* ctrl, alt */
  } else {
    keyResult = keyValue;
  }

  if (sqModifiers & CtrlKeyBit) { /* Control Keys */
    keyResult &= 0x00FF;
    keyResult -= 0x60; /* e.g. m=0x6D ^M=0x0D */
    if (keyResult > 0x20) {
      DPRINTF("\nkeyMap(): Bogus control key 0x%x\n", keyResult);
      return( 0 ) ;
    }
    return( keyResult );
  }

  if (keyResult <= 0x7F) { /* simple ASCII */
    return( keyResult );
  }

  if ((keyResult > KEYCODE_PC_KEYS) && (keyResult <= KEYCODE_F12)) {
    switch ( keyResult ) {
    /* Nota Bene: VM only handles some keys: `Sensor kbdTest.` */
    /* case KEYCODE_PAUSE: */
    /*   printf("PAUSE "); */
    /*   break; */
    /* case KEYCODE_SCROLL_LOCK: */
    /*   printf("SCROLL_LOCK "); */
    /*   break; */
    /* case KEYCODE_PRINT: */
    /*   printf("PRINT "); */
    /*   break; */
    /* case KEYCODE_SYSREQ: */
    /*   printf("SYSREQ "); */
    /*   break; */
    /* case KEYCODE_BREAK: */
    /*   printf("BREAK "); */
    /*   break; */
    case KEYCODE_ESCAPE:
      keyResult = 0x1B;
      break;
    case KEYCODE_BACKSPACE:
      keyResult = 0x08;
      break;
    case KEYCODE_TAB:
      keyResult = 0x09;
      break;
    /* case KEYCODE_BACK_TAB: */
    /*   printf("BACK_TAB "); */
    /*   break; */
    case KEYCODE_RETURN:
      keyResult = 0x0D; /* CR */
      break;
    /* case KEYCODE_CAPS_LOCK: */
    /*   printf("CAPS_LOCK "); */
    /*   break; */
    /* case KEYCODE_LEFT_SHIFT: */
    /*   printf("LEFT_SHIFT "); */
    /*   break; */
    /* case KEYCODE_RIGHT_SHIFT: */
    /*   printf("RIGHT_SHIFT "); */
    /*   break; */
    /* case KEYCODE_LEFT_CTRL: */
    /*   printf("LEFT_CTRL "); */
    /*   break; */
    /* case KEYCODE_RIGHT_CTRL: */
    /*   printf("RIGHT_CTRL "); */
    /*   break; */
    /* case KEYCODE_LEFT_ALT: */
    /*   printf("LEFT_ALT "); */
    /*   break; */
    /* case KEYCODE_RIGHT_ALT: */
    /*   printf("RIGHT_ALT "); */
    /*   break; */
    /* case KEYCODE_MENU: */
    /*   printf("MENU "); */
    /*   break; */
    /* case KEYCODE_LEFT_HYPER: */
    /*   printf("LEFT_HYPER "); */
    /*   break; */
    /* case KEYCODE_RIGHT_HYPER: */
    /*   printf("RIGHT_HYPER "); */
    /*   break; */
    case KEYCODE_INSERT:
      keyResult = 5;
      break;
    case KEYCODE_HOME:
      keyResult = 1;
      break;
    case KEYCODE_PG_UP:
      keyResult = 11;
      break;
    case KEYCODE_DELETE:
      keyResult = 127;
      break;
    case KEYCODE_END:
      keyResult = 4;
      break;
    case KEYCODE_PG_DOWN:
      keyResult = 12;
      break;
    case KEYCODE_LEFT: /* arrow */
      keyResult = 28;
      break;
    case KEYCODE_RIGHT: /* arrow */
      keyResult = 29;
      break;
    case KEYCODE_UP:  /* arrow */
      keyResult = 30;
      break;
    case KEYCODE_DOWN:  /* arrow */
      keyResult = 31;
      break;
    /* case KEYCODE_NUM_LOCK: */
    /*   printf("NUM_LOCK "); */
    /*   break; */
    case KEYCODE_KP_PLUS:
      keyResult = 0x2B;
      break;
    case KEYCODE_KP_MINUS:
      keyResult = 0x2D;
      break;
    case KEYCODE_KP_MULTIPLY:
      keyResult = 0x2A;
      break;
    case KEYCODE_KP_DIVIDE:
      keyResult = 0x2F;
      break;
    case KEYCODE_KP_ENTER:
      keyResult = 0x0D;
      break;
    case KEYCODE_KP_HOME:
      keyResult = 1;
      break;
    case KEYCODE_KP_UP:
      keyResult = 30;
      break;
    case KEYCODE_KP_PG_UP:
      keyResult = 11;
      break;
    case KEYCODE_KP_LEFT:
      keyResult = 28;
      break;
    case KEYCODE_KP_FIVE:
      keyResult = 0x35;
      break;
    case KEYCODE_KP_RIGHT:
      keyResult = 29;
      break;
    case KEYCODE_KP_END:
      keyResult = 4;
      break;
    case KEYCODE_KP_DOWN:
      keyResult = 31;
      break;
    case KEYCODE_KP_PG_DOWN:
      keyResult = 12;
      break;
    case KEYCODE_KP_INSERT:
      keyResult = 5;
      break;
    case KEYCODE_KP_DELETE:
      keyResult = 127;
      break;
    /* case KEYCODE_F1: */
    /*   printf("F1 "); */
    /*   break; */
    /* case KEYCODE_F2: */
    /*   printf("F2 "); */
    /*   break; */
    /* case KEYCODE_F3: */
    /*   printf("F3 "); */
    /*   break; */
    /* case KEYCODE_F4: */
    /*   printf("F4 "); */
    /*   break; */
    /* case KEYCODE_F5: */
    /*   printf("F5 "); */
    /*   break; */
    /* case KEYCODE_F6: */
    /*   printf("F6 "); */
    /*   break; */
    /* case KEYCODE_F7: */
    /*   printf("F7 "); */
    /*   break; */
    /* case KEYCODE_F8: */
    /*   printf("F8 "); */
    /*   break; */
    /* case KEYCODE_F9: */
    /*   printf("F9 "); */
    /*   break; */
    /* case KEYCODE_F10: */
    /*   printf("F10 "); */
    /*   break; */
    /* case KEYCODE_F11: */
    /*   printf("F11 "); */
    /*   break; */
    /* case KEYCODE_F12: */
    /*   printf("F12 "); */
    /*   break; */
    default:
      DPRINTF("\nUHANDLED PC_KEY: 0x%x\n", keyResult );
      keyResult = 0; /* UNHANDLED */
      break;
    }
    return( keyResult );
  }  
  return( 0 ); /* Not handled */
}

void
handleKeyboardEvent(screen_event_t keyEvent) {
/*
Event Type: SCREEN_EVENT_KEYBOARD

    SCREEN_PROPERTY_DEVICE
    SCREEN_PROPERTY_FLAGS
    SCREEN_PROPERTY_KEY_ALTERNATE_SYM
    SCREEN_PROPERTY_KEY_CAP
    SCREEN_PROPERTY_MODIFIERS
    SCREEN_PROPERTY_SCAN
    SCREEN_PROPERTY_SEQUENCE_ID
    SCREEN_PROPERTY_SYM 	  
*/
  int keyValue = 0;
  int keyFlags = 0;
  int keyModifiers = 0;
  int keyCap = 0;
  int keySym = 0;
  int keyScan = 0;
  int keyCodeSupplied = 0;
  int sqModifiers = 0;
  int sqPressCode = 0;

  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SYM,   &keyValue);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_FLAGS, &keyFlags);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MODIFIERS, &keyModifiers);
  if (keyFlags & SCREEN_FLAG_CAP_VALID) 
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_KEY_CAP, &keyCap);
  if (keyFlags & SCREEN_FLAG_SYM_VALID) 
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SYM, &keySym);

  /* Map between QNX Screen World & OpenSmalltalk VM World */
  if (keyModifiers & KEYMOD_SHIFT) { sqModifiers |= ShiftKeyBit; }
  if (keyModifiers & KEYMOD_CTRL)  { sqModifiers |= CtrlKeyBit; }
  if (keyModifiers & KEYMOD_ALT)   { sqModifiers |= CommandKeyBit;
    /* NB: ALT+. NOT CTL+. */
    if (keyValue == 0x2E) { /* Command+period = meta+dot */
      setInterruptPending(true);
      return;
    }
  }

  if (keyFlags & SCREEN_FLAG_KEY_DOWN) {
    sqPressCode = EventKeyDown;
  } else {
    sqPressCode = EventKeyUp;
  }

  keyCodeSupplied = keyMap( keyValue, keyFlags, sqModifiers, keyCap, keySym );

  if ((keyCodeSupplied != 0) && (keyCodeSupplied <= 0x7F)) {
#if defined(DEBUG)
    printf("\nKeyCodeSupplied: 0x%x", keyCodeSupplied);
#endif
    /*@@@    if (keyCodeSupplied < 0x20)  { sqModifiers |= CtrlKeyBit; } @@@*/
    recordKeyboardEvent( keyCodeSupplied, sqPressCode, sqModifiers, keyCodeSupplied );
    if (sqPressCode == EventKeyDown) {
      recordKeyboardEvent( keyCodeSupplied, EventKeyChar, sqModifiers, keyCodeSupplied );
    }
  }
  
#if defined(DEBUG)

  if ((keyValue >= 0x20) && (keyValue <= 0x7F))
    printf("\nASCII '%c' ", keyValue);
  else
    printf("\n");
  if ((keyModifiers & KEYMOD_CTRL) && (keyCap < 0x7F))
    printf("CTL ^%c ", (keyCap - 0x20));

  if ((keyModifiers & KEYMOD_ALT) && (keyCap < 0x7F))
    printf("ALT %c ", keyCap);

  printQNXPCKeys(keyValue);  /* NON-ASII, e.g. keypadkeys, home, .. */
  printQNXModifiers(keyModifiers); /* SHIFT, etc. */
  printf(" KeyCode=0x%x ", keyValue);
  printQNXKeyFlags(keyFlags);

  if (keyFlags & SCREEN_FLAG_CAP_VALID) {
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_KEY_CAP, &keyCap);
      printf(" keyCap=0x%x", keyCap);
  }
  
  if (keyFlags & SCREEN_FLAG_SYM_VALID) {
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SYM, &keySym);
      printf(" keySym=0x%x", keySym);
  }
  /* NB: For control keys, keySym is not valid. */

  if (keyFlags & SCREEN_FLAG_SCAN_VALID) { /* Physical Keyboard Key Location */
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SCAN, &keyScan);
      printf(" location=0x%x", keyScan);
  }
#endif
}

void printQNXKeyFlags(int flags) {
  
  if (flags & SCREEN_FLAG_KEY_DOWN)
    printf("KeyDOWN ");
  else
    printf("KeyUP ");

  if (flags & SCREEN_FLAG_KEY_REPEAT)
    printf("KeyRepeat ");

  /* if (flags & SCREEN_FLAG_SCAN_VALID) */
  /*   printf("KeyScanValid "); */

  /* if (flags & SCREEN_FLAG_SYM_VALID) */
  /*   printf("KeySym "); */

  /* if (flags & SCREEN_FLAG_CAP_VALID) */
  /*   printf("KeyCap "); */

  /* if (flags & SCREEN_FLAG_DISPLACEMENT_VALID) */
  /*   printf("KeyDisplacment "); */

  /* if (flags & SCREEN_FLAG_POSITION_VALID) */
  /*   printf("KeyPosition "); */

  /* if (flags & SCREEN_FLAG_SOURCE_POSITION_VALID) */
  /*   printf("KeySourcePosition "); */

  /* if (flags & SCREEN_FLAG_SIZE_VALID) */
  /*   printf("KeySize "); */
}

//----------------------------------------------------------------
/* MOUSE POINTER */

void
handlePointerEvent(screen_event_t keyEvent) {
/*
  Event Type: SCREEN_EVENT_POINTER

    SCREEN_PROPERTY_BUTTONS
    SCREEN_PROPERTY_DEVICE
    SCREEN_PROPERTY_MODIFIERS
    SCREEN_PROPERTY_MOUSE_HORIZONTAL_WHEEL
    SCREEN_PROPERTY_MOUSE_WHEEL
    SCREEN_PROPERTY_POSITION
    SCREEN_PROPERTY_SOURCE_POSITION 
*/
/* NB: keyValue is global loop flag */
  int qnxButtons = 0;
  int qnxModifiers = 0;
  int wheelHoriz = 0;
  int wheelVert  = 0;
  int position[2];
  int sourcePosition[2];

  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_BUTTONS,   &qnxButtons);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MODIFIERS, &qnxModifiers);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_POSITION,
			       (int *)&position);
  /* screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SOURCE_POSITION, */
  /* 			       (int *)&sourcePosition); */
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MOUSE_HORIZONTAL_WHEEL,
			       &wheelHoriz);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MOUSE_WHEEL,
			       &wheelVert);

  /* map between QNX Screen World & OpenSmalltalk VM World */
  mousePosition.x = position[0];
  mousePosition.y = position[1];
  /* NYI -- no single button mouse in QNX
   *  red button honours the modifiers:
   *	red+ctrl    = yellow button
   *	red+command = blue button
   */
  buttonState = 0;
  if (qnxButtons & 1) { buttonState |= RedButtonBit; }   /* Left */
  if (qnxButtons & 2) { buttonState |= YellowButtonBit; }/* Middle */
  if (qnxButtons & 4) { buttonState |= BlueButtonBit; }  /* Right */
  modifierState = 0;
  if (qnxModifiers & KEYMOD_SHIFT) { modifierState |= ShiftKeyBit; }
  if (qnxModifiers & KEYMOD_CTRL)  { modifierState |= CtrlKeyBit; }
  if (qnxModifiers & KEYMOD_ALT)   { modifierState |= CommandKeyBit; }

  cursorTo(mousePosition.x, mousePosition.y);
  
  if (wheelVert != 0) {
    recordMouseWheelEvent(0, (- wheelVert)); /* invert wheel direction */
  }
  else {
    recordMouseEvent();
  }
  
#if defined(EVENT_MOUSE)
  printf("\n Mouse Point @ (%d,%d) ", position[0], position[1]);
  printQNXMouseButtons(qnxButtons);
  printQNXModifiers(qnxModifiers);
  if (wheelHoriz != 0)
    printf("\n Horizontal wheel clicks = %d", wheelHoriz); 
  if (wheelVert != 0)
    printf("\n Vertical wheel clicks = %d", wheelVert); 
#endif
}

void printQNXMouseButtons(int buttons) {
  /* Just a bitmask */
  if (buttons != 0) {
    printf(" MouseButton: ");
    if (1 & buttons) printf("Left/Red ");
    if (2 & buttons) printf("Middle/Yellow ");
    if (4 & buttons) printf("Right/Blue ");
  }
}

void printQNXModifiers(int modifiers) 
{
  if (modifiers & KEYMOD_SHIFT)
    printf("SHIFT ");
  if (modifiers & KEYMOD_CTRL)
    printf("CTRL ");
  if (modifiers & KEYMOD_ALT)
    printf("ALT ");
  if (modifiers & KEYMOD_ALTGR)
    printf("ALTGR ");
  if (modifiers & KEYMOD_SHL3)
    printf("SHL3 ");
  if (modifiers & KEYMOD_MOD6)
    printf("MOD6 ");
  if (modifiers & KEYMOD_MOD7)
    printf("MOD7 ");
  if (modifiers & KEYMOD_MOD8)
    printf("MOD8 ");
  if (modifiers & KEYMOD_SHIFT_LOCK)
    printf("ShiftLock ");
  if (modifiers & KEYMOD_CTRL_LOCK)
    printf("CTRLLock ");
  if (modifiers & KEYMOD_ALT_LOCK)
    printf("ALTLock ");
  if (modifiers & KEYMOD_ALTGR_LOCK)
    printf("ALTGRLock ");
  if (modifiers & KEYMOD_SHL3_LOCK)
    printf("SHL3Lock ");
  if (modifiers & KEYMOD_MOD6_LOCK)
    printf("MOD6Lock ");
  if (modifiers & KEYMOD_MOD7_LOCK)
    printf("MOD7Lock ");
  if (modifiers & KEYMOD_MOD8_LOCK)
    printf("MOD8Lock ");
  if (modifiers & KEYMOD_CAPS_LOCK)
    printf("CapsLock ");
  if (modifiers & KEYMOD_NUM_LOCK)
    printf("NumLock ");
  if (modifiers & KEYMOD_SCROLL_LOCK )
    printf("ScrollLock  ");
}

void printQNXPCKeys(int keyCode)
{
  if ((keyCode > KEYCODE_PC_KEYS) && (keyCode <= KEYCODE_F12)) {
    switch (keyCode) {
    case KEYCODE_PAUSE:
      printf("PAUSE ");
      break;
    case KEYCODE_SCROLL_LOCK:
      printf("SCROLL_LOCK ");
      break;
    case KEYCODE_PRINT:
      printf("PRINT ");
      break;
    case KEYCODE_SYSREQ:
      printf("SYSREQ ");
      break;
    case KEYCODE_BREAK:
      printf("BREAK ");
      break;
    case KEYCODE_ESCAPE:
      printf("ESCAPE ");
      break;
    case KEYCODE_BACKSPACE:
      printf("BACKSPACE ");
      break;
    case KEYCODE_TAB:
      printf("TAB ");
      break;
    case KEYCODE_BACK_TAB:
      printf("BACK_TAB ");
      break;
    case KEYCODE_RETURN:
      printf("RETURN ");
      break;
    case KEYCODE_CAPS_LOCK:
      printf("CAPS_LOCK ");
      break;
    case KEYCODE_LEFT_SHIFT:
      printf("LEFT_SHIFT ");
      break;
    case KEYCODE_RIGHT_SHIFT:
      printf("RIGHT_SHIFT ");
      break;
    case KEYCODE_LEFT_CTRL:
      printf("LEFT_CTRL ");
      break;
    case KEYCODE_RIGHT_CTRL:
      printf("RIGHT_CTRL ");
      break;
    case KEYCODE_LEFT_ALT:
      printf("LEFT_ALT ");
      break;
    case KEYCODE_RIGHT_ALT:
      printf("RIGHT_ALT ");
      break;
    case KEYCODE_MENU:
      printf("MENU ");
      break;
    case KEYCODE_LEFT_HYPER:
      printf("LEFT_HYPER ");
      break;
    case KEYCODE_RIGHT_HYPER:
      printf("RIGHT_HYPER ");
      break;
    case KEYCODE_INSERT:
      printf("INSERT ");
      break;
    case KEYCODE_HOME:
      printf("HOME ");
      break;
    case KEYCODE_PG_UP:
      printf("PG_UP ");
      break;
    case KEYCODE_DELETE:
      printf("DELETE ");
      break;
    case KEYCODE_END:
      printf("END ");
      break;
    case KEYCODE_PG_DOWN:
      printf("PG_DOWN ");
      break;
    case KEYCODE_LEFT:
      printf("LEFT ");
      break;
    case KEYCODE_RIGHT:
      printf("RIGHT ");
      break;
    case KEYCODE_UP:
      printf("UP ");
      break;
    case KEYCODE_DOWN:
      printf("DOWN ");
      break;
    case KEYCODE_NUM_LOCK:
      printf("NUM_LOCK ");
      break;
    case KEYCODE_KP_PLUS:
      printf("KP_PLUS ");
      break;
    case KEYCODE_KP_MINUS:
      printf("KP_MINUS ");
      break;
    case KEYCODE_KP_MULTIPLY:
      printf("KP_MULTIPLY ");
      break;
    case KEYCODE_KP_DIVIDE:
      printf("KP_DIVIDE ");
      break;
    case KEYCODE_KP_ENTER:
      printf("KP_ENTER ");
      break;
    case KEYCODE_KP_HOME:
      printf("KP_HOME ");
      break;
    case KEYCODE_KP_UP:
      printf("KP_UP ");
      break;
    case KEYCODE_KP_PG_UP:
      printf("KP_PG_UP ");
      break;
    case KEYCODE_KP_LEFT:
      printf("KP_LEFT ");
      break;
    case KEYCODE_KP_FIVE:
      printf("KP_FIVE ");
      break;
    case KEYCODE_KP_RIGHT:
      printf("KP_RIGHT ");
      break;
    case KEYCODE_KP_END:
      printf("KP_END ");
      break;
    case KEYCODE_KP_DOWN:
      printf("KP_DOWN ");
      break;
    case KEYCODE_KP_PG_DOWN:
      printf("KP_PG_DOWN ");
      break;
    case KEYCODE_KP_INSERT:
      printf("KP_INSERT ");
      break;
    case KEYCODE_KP_DELETE:
      printf("KP_DELETE ");
      break;
    case KEYCODE_F1:
      printf("F1 ");
      break;
    case KEYCODE_F2:
      printf("F2 ");
      break;
    case KEYCODE_F3:
      printf("F3 ");
      break;
    case KEYCODE_F4:
      printf("F4 ");
      break;
    case KEYCODE_F5:
      printf("F5 ");
      break;
    case KEYCODE_F6:
      printf("F6 ");
      break;
    case KEYCODE_F7:
      printf("F7 ");
      break;
    case KEYCODE_F8:
      printf("F8 ");
      break;
    case KEYCODE_F9:
      printf("F9 ");
      break;
    case KEYCODE_F10:
      printf("F10 ");
      break;
    case KEYCODE_F11:
      printf("F11 ");
      break;
    case KEYCODE_F12:
      printf("F12 ");
      break;
    default:
      break;
    }
  }
}

/* CLIPBOARD */

static sqInt display_clipboardSize(void)									{ return 0; }
static sqInt display_clipboardWriteFromAt(sqInt n, sqInt ptr, sqInt off)					{ return 0; }
static sqInt display_clipboardReadIntoAt(sqInt n, sqInt ptr, sqInt off)					{ return 0; }
static char **display_clipboardGetTypeNames(void)								{ return 0; }
static sqInt  display_clipboardSizeWithType(char *typeName, int ntypeName)					{ return 0; }

static void  display_clipboardWriteWithType(char *data, size_t ndata, char *typeName, size_t ntypeName, int isDnd, int isClaiming) {}

static sqInt display_dndOutStart(char *types, int ntypes)	{ return 0; }
static void  display_dndOutSend(char *bytes, int nbytes)	{ return  ; }
/* UNUSED static void  display_dndLaunchFile(char *fileName)	{ return ; }  */
static sqInt display_dndOutAcceptedType(char * buf, int nbuf)	{ return 0; }
static sqInt display_dndReceived(char *fileName)	{ return 0; }

static sqInt display_ioFormPrint(sqInt bits, sqInt w, sqInt h, sqInt d, double hs, double vs, sqInt l)	{ return 0; }

static sqInt display_ioSetFullScreen(sqInt fullScreen)							{ return 0; } /* Our 1 window is already fullscreen */

static sqInt display_ioForceDisplayUpdate(void)
{
  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);
  return 0;
}

static sqInt display_ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)		{ return 0; }
static void display_winSetName(char *imageName)								{ return  ; }
static void display_winExit(void)									{ return  ; }
static long  display_winImageFind(char *buf, int len)							{ return 0; }
static void display_winImageNotFound(void)								{ return  ; }


//----------------------------------------------------------------

// OSPP
static void *display_ioGetDisplay(void)	{ return 0; }
static void *display_ioGetWindow(void)	{ return 0; }


static sqInt display_primitivePluginBrowserReady()	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestURLStream()	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestURL()	{ return primitiveFail(); }
static sqInt display_primitivePluginPostURL()		{ return primitiveFail(); }
static sqInt display_primitivePluginRequestFileHandle()	{ return primitiveFail(); }
static sqInt display_primitivePluginDestroyRequest()	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestState()	{ return primitiveFail(); }

// Host Windows

#if (SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 2)
static long display_hostWindowClose(long index)                                               { return 0; }
static long display_hostWindowCreate(long w, long h, long x, long y,
  char *list, long attributeListLength)                                                      { return 0; }
static long display_hostWindowShowDisplay(unsigned char *dispBitsIndex, long width, long height, long depth,
  long left, long right, long top, long bottom, sqIntptr_t windowIndex)              { return 0; }
static long display_hostWindowGetSize(long windowIndex)                                       { return -1; }
static long display_hostWindowSetSize(long windowIndex, long w, long h)                         { return -1; }
static long display_hostWindowGetPosition(long windowIndex)                                   { return -1; }
static long display_hostWindowSetPosition(long windowIndex, long x, long y)                     { return -1; }
static long display_hostWindowSetTitle(long windowIndex, char *newTitle, long sizeOfTitle)     { return -1; }
static long display_hostWindowCloseAll(void)                                                 { return 0; }
#endif

/* OpenGL */

static sqInt display_ioGLinitialise(void) {   return 0; }
static sqInt display_ioGLcreateRenderer(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags) {  return 0; }
static void  display_ioGLdestroyRenderer(glRenderer *r) {  }
static void  display_ioGLswapBuffers(glRenderer *r) {  }
static sqInt display_ioGLmakeCurrentRenderer(glRenderer *r) {   return 0; }
static void  display_ioGLsetBufferRect(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h) {  }


// new stubs for the CogVM
#if SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3
static long display_ioSetCursorPositionXY(long x, long y) { return 0; }
static long display_ioPositionOfScreenWorkArea (long windowIndex) { return -1; }
static long display_ioSizeOfScreenWorkArea (long windowIndex) { return -1; }
static void *display_ioGetWindowHandle() { return 0; }
static long display_ioPositionOfNativeDisplay(void *windowHandle) { return -1; }
static long display_ioSizeOfNativeDisplay(void *windowHandle) { return -1; }
static long display_ioPositionOfNativeWindow(void *windowHandle) { return -1; }
static long display_ioSizeOfNativeWindow(void *windowHandle) { return -1; }
#if SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 7
static long display_ioScreenRectangles(void) { return 0; }
#endif // SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 7
#endif // SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3

//----------------------------------------------------------------
/* Balloon splash image */

static void showBalloons(void *bufPtr) {
  int x, y;

  x = screenWidth() / 2;
  y = screenHeight() / 2;
  showBalloonAt(bufPtr,x,y) ;
  showBalloonAt(bufPtr,x+(x/2),y-(y/2)) ;
  showBalloonAt(bufPtr,x+(x/2),y+(y/2)) ;
  showBalloonAt(bufPtr,x-(x/2),y-(y/2)) ;
  showBalloonAt(bufPtr,x-(x/2),y+(y/2)) ;
}
  

static void showBalloonAt(void *bufPtr, int left, int top)
{
  int x, y;
  char *data = balloon_data, pixel[4];
  pixel_t myPixel;
  int balloon_bytes_per_pixel = 4; /* 32 bits */

  /* Center Balloon on x,y point */
  left -= balloon_width_pixels  / 2;
  top  -= balloon_height_pixels / 2;
  for (y = 0; y < balloon_height_pixels; y++) {
    for (x = 0; x < balloon_width_pixels; x++) {
      /* extract RGB values from Balloon data */
      BALLOON_PIXEL( data, pixel );
      /* above side effect: data += balloon_bytes_per_pixel */
      putPixel(left + x,
	       top + y,
	       ((pixel[0] << 16) | (pixel[1] << 8) | pixel[2])); /* RGB */
    }
  }
}


//----------------------------------------------------------------


#include "SqModule.h"

SqDisplayDefine(qnxScreen);

static void *display_makeInterface(void)
{
  return &display_qnxScreen_itf;
}

SqModuleDefine(display,	qnxScreen);


/* ------------------ E O F ------------------- */
