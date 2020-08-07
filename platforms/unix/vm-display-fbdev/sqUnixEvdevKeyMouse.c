/* sqUnixEvdevKeyMouse.c
 * Connect libevdev events into Squeak Mouse and Keyboard Events
 *
 * Author: Ken.Dickey@whidbey.com
 * Last Updated: August 2020
 */
/* 
 * Copyright (C) 2020 Kenneth A Dickey
 * All Rights Reserved.
 * 
 * This file is part of OpenSmalltalk / Unix Squeak.
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

/* Note: "platforms/unix/vm/sqUnixEvent.c" */

/*
 * OpenSmalltalk buffers keystrokes but just 
 * tracks the 'now'/current state of the mouse.
 *
 */

#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <dirent.h>
#include <errno.h>
#include <getopt.h>
#include <ctype.h>
#include <signal.h>
#include <limits.h> /* PATH_MAX */
#include <input.h>   /* /usr/include/linux/input.h */
#include <keysym.h>  /* /usr/include/X11/keysym.h */

#ifndef input_event_sec
#define input_event_sec  time.tv_sec
#define input_event_usec time.tv_usec
#endif

#define BITS_PER_LONG (sizeof(long) * 8)
#define NBITS(x) ((((x)-1)/BITS_PER_LONG)+1)
#define OFF(x)  ((x)%BITS_PER_LONG)
#define BIT(x)  (1UL<<OFF(x))
#define LONG(x) ((x)/BITS_PER_LONG)
#define test_bit(bit, array)	((array[LONG(bit)] >> OFF(bit)) & 1)

#ifndef EV_SYN
#define EV_SYN 0
#endif
#ifndef SYN_MAX
#define SYN_MAX 3
#define SYN_CNT (SYN_MAX + 1)
#endif
#ifndef SYN_MT_REPORT
#define SYN_MT_REPORT 2
#endif
#ifndef SYN_DROPPED
#define SYN_DROPPED 3
#endif

/* wiki.squeak.org/squeak/897 shows:
   red    #b100 left  (4)	button1
   yellow #b010 mid   (2)	button2
   blue   #b001 right (1)	button3
 So binary view of bit matches mouse (left|mid|right) position
 */
#define LeftMouseButtonBit  RedButtonBit
#define MidMouseButtonBit   YellowButtonBit
#define RightMouseButtonBit BlueButtonBit


#define _mouse	struct ms *mouseSelf

struct ms;

typedef void (*ms_callback_t)(int buttons, int dx, int dy);
typedef void (*ms_init_t)(_mouse);
typedef void (*ms_handler_t)(_mouse);

struct ms
{
  char		*msName;
  int		 fd;
  ms_init_t	 init;
  ms_handler_t	 handleEvents;
  ms_callback_t  callback;
  unsigned char	 buf[3*64];
  int		 bufSize;
  struct libevdev *dev;
};

static struct ms mouseDev; /* singleton */

/* NB: defaults on RPi3 Alpine Linux */
const char* mousePathDefault=    "/dev/input/event1"; 
const char* keyboardPathDefault= "/dev/input/event0";



static void ms_noCallback(int b, int x, int y) {}

static void msHandler(int fd, void *data, int flags)
{
  _mouse= (struct ms *)data;
  mouseSelf->handleEvents(mouseSelf);
  /* @@@FIXME@@@ */
  /*  aioHandle(fd, msHandler, AIO_RX); */
}


static ms_callback_t ms_setCallback(_mouse, ms_callback_t callback)
{
  /* Dummy */
  mouseSelf->callback= ms_noCallback;
  return ms_noCallback
}

static int ms_open(_mouse, char *msDev, char *msProto)
{
  ms_init_t init= 0;
  ms_handler_t handler= 0;
  int rc = 0;

  assert(mouseSelf->fd == -1);

  if (msDev)
    mouseSelf->fd= open(mouseSelf->msName= msDev, O_RDONLY);
  else
    {
      static struct _mstab {
  	  char *dev;		char *proto;
      } mice[]=	{
	{ mousePathDefault,  "evdev" }, /* Alpine Linux RasPi3 */
	{ 0, 0 }
      };
      int i;
      for (i= 0;  mice[i].dev;  ++i)
	if ((mouseSelf->fd= open(mouseSelf->msName= mice[i].dev,  O_RDWR)) >= 0)
	  {
	    if (!msProto)
	      msProto= mice[i].proto;
	    break;
	  }
	else
	  perror(mice[i].dev);
    }
  if (mouseSelf->fd < 0) {
    if (errno == EACCES && getuid() != 0)
	fprintf(stderr, "You do not have access to %s. Try "
			"running as root instead.\n",
			mouseSelf->msName );
    failPermissions("mouse");
  } else {
    rc = libevdev_new_from_fd( mouseSelf->fd, &mouseSelf->dev );
    if (rc < 0) {
      fatal("Unable to initialize libevdev mouse (%s)\n", strerror(-rc) );
    } else {
      DPRINTF("Opened for input: \"%s\" bus %#x vendor %#x product %#x\n",
	      libevdev_get_name(      mouseSelf->dev),
	      libevdev_get_id_bustype(mouseSelf->dev),
	      libevdev_get_id_vendor( mouseSelf->dev),
      	      libevdev_get_id_product(mouseSelf->dev) );
    }
  }
  
  if (msProto)
    {
      static struct _mptab {
	char *name;	ms_init_t init;	ms_handler_t handler;
      } protos[]= {
	{ "evdev",	ms_evdev_init,	ms_evd_handleEvents,	},		
	{ 0,	0,	0 }
      };
      int i;
      for (i= 0;  protos[i].name;  ++i)
	if (!strcmp(msProto, protos[i].name))
	  {
	    init=    protos[i].init;
	    handler= protos[i].handler;
	    break;
	  }
      if (!init)
	{
	  fprintf(stderr, "unknown mouse protocol: '%s'\n", msProto);
	  fprintf(stderr, "supported protocols:");
	  for (i= 0;  protos[i].name;  ++i)
	    fprintf(stderr, " %s", protos[i].name);
	  fprintf(stderr, "\n");
	  exit(1);
	}
    }

  DPRINTF("using: %s (%d), %s\n", mouseSelf->msName, mouseSelf->fd, msProto);

  mouseSelf->init= init;
  mouseSelf->handleEvents= handler;

  return 1;
}


static void ms_close(_mouse)
{
  if (mouseSelf->fd >= 0)
    {
      close(mouseSelf->fd);
      libevdev_free(mouseSelf->dev);
      DPRINTF("%s (%d) closed\n", mouseSelf->msName, mouseSelf->fd);
      mouseSelf->fd= -1;
    }
}


static struct ms *ms_new(void)
{
  /*  _mouse= (struct ms *)calloc(1, sizeof(struct ms)); */
  _mouse = &mouseDev;
  mouseSelf->fd= -1;
  mouseSelf->dev= 0;
  mouseSelf->callback= ms_noCallback;
  return mouseSelf;
}


static void ms_delete(_mouse)
{
  /*  free(mouseSelf); */
}


/* Interactin with VM */

static int wheelDelta = 0;  /* reset in clearMouseButtons() */

static void setSqueakMousePosition( int newX, int newY ) {
  mousePosition.x = newX;
  mousePosition.y = newY;
}

static void copyMousePositionInto(SqPoint *mousePt) {
  mousePt->x = mousePosition.x;
  mousePt->y = mousePosition.y;
}

static void updateSqueakMousePosition(struct input_event* evt) {
/* Nota Bene: up => deltaY UP is negative; {0,0} at topLeft of screen */
  if (evt->type == EV_REL) {
    switch (evt->code) {
      case REL_X:
	/* no less than 0 */
	mousePosition.x = max(0, mousePosition.x + evt->value) ;
	break;
      case REL_Y:
	/* no less than 0 */
	mousePosition.y = max(0, mousePosition.y + evt->value) ; 
	break;
      case REL_WHEEL:
	wheelDelta += evt->value;
	DPRINTF( "*** Wheel VALUE: %d; DELTA: %d ",
		 mouseWheelDelta(),
		 evt->value ) ;
	break;
      default:
	break;
    }
  }
}

static void printMouseState() {
   if ( (mousePosition.x != 0) || (mousePosition.y != 0) ) {
     DPRINTF( "*** Mouse at %4d,%4d ", mousePosition.x, mousePosition.y );
     printButtons( mouseButtonState() );
     printModifiers( modifierState() );
     if (mouseWheelDelta() != 0) {
       	DPRINTF( " Mouse Wheel: %d", mouseWheelDelta() );
     }
     DPRINTF("\n");
   }
}

static void clearMouseWheel() {  wheelDelta = 0 ; }
static int mouseWheelDelta() { return ( wheelDelta ) ; }


/*==========================*/
/* Track Mouse Button State */
/*==========================*/

static int mouseButtonsDown = 0;  /* (left|mid|right) = (Red|Yellow|Blue) */

/* Distinguish 'sqInt getButtonState(void)' in sqUnixEvent.c 
 *   which ORs mouse and key modifiers (mouse button bits are shifted)
 */

static int mouseButtonState() { return ( mouseButtonsDown ) ; }

static int setSqueakButtonState() {
  buttonState= mouseButtonState();
}

static void clearMouseButtons() { mouseButtonsDown = 0 ; wheelDelta = 0; }

static void updateMouseButtons(struct input_event* evt) {
  if (evt->type == EV_KEY) {
    if (evt->value == 1) { /* button down */
      switch (evt->code) {
	case BTN_LEFT:   mouseButtonsDown |= LeftMouseButtonBit;  break;
	case BTN_MIDDLE: mouseButtonsDown |= MidMouseButtonBit;   break;
	case BTN_RIGHT:  mouseButtonsDown |= RightMouseButtonBit; break;
	default: break;
      }
    } else if (evt->value == 0) { /* button up */
      switch (evt->code) {
	case BTN_LEFT:   mouseButtonsDown &= ~LeftMouseButtonBit;  break;
	case BTN_MIDDLE: mouseButtonsDown &= ~MidMouseButtonBit;   break;
	case BTN_RIGHT:  mouseButtonsDown &= ~RightMouseButtonBit; break;
	default: break;
      }
    /* ignore repeats (evt->value == 2) */
    }
  }
}

#undef _mouse




/* Translate between libevdev and OpenSmalltalkVM view of keystrokes */

/*==================*/
/* Keyboard Key     */
/*==================*/

static int  lastKeyCode = 0;
static int  keyRepeated = 0; /*FALSE;*/

static int keyCode()  { return ( lastKeyCode ) ; }
static int repeated() { return ( keyRepeated ) ; }

static void clearKeyCode() {
  lastKeyCode = 0 ; 
  keyRepeated = 0;
}

static int notModifier(int code) {
  switch (code) {
    case KEY_LEFTMETA:  
    case KEY_LEFTALT:   
    case KEY_LEFTCTRL:  
    case KEY_LEFTSHIFT: 
    case KEY_RIGHTMETA: 
    case KEY_RIGHTALT:  
    case KEY_RIGHTCTRL: 
    case KEY_RIGHTSHIFT:
	return( FALSE );
	break;
    default: return( TRUE ); /* NOT a modifier/adjunct key */
  }
}

static void updateModifierState(struct input_event* evt); /* forward */

static void setKeyCode(struct input_event* evt) {
  int squeakKeyCode, modifiers;
  /* NB: possible to get a Key UP _withOUT_ a Key DOWN */
  if ( (evt->type == EV_KEY) && notModifier(evt->code) ) {
    lastKeyCode = evt->code;
    modifiers = modifierState();
    squeakKeyCode = keyCode2keyValue( lastKeyCode, (modifiers & ShiftKeyBit) )
#ifdef DEBUG_KEYBOARD_EVENTS
    DPRINTF("Setting key code: %d from raw: %d\n", squeakKeyCode, evt->code);
#endif
    switch (evt->value) {

      case 1: /* keydown */
        recordKeyboardEvent(squeakKeyCode,
			    EventKeyDown,
			    modifiers,
			    squeakKeyCode);
#ifdef DEBUG_KEYBOARD_EVENTS
	printKeyState(1);
#endif
	keyRepeated = 0;
	break;
      
      case 2: /* repeat */
        recordKeyboardEvent(squeakKeyCode,
			    EventKeyChar, /* Squeak lacks EventKeyRepeat */
			    modifiers,
			    squeakKeyCode);
#ifdef DEBUG_KEYBOARD_EVENTS
	if (keyRepeated < 2)
	  printKeyState(2);
#endif
	keyRepeated = keyRepeated + 1;
	break;

    default: /* 0 => keyUp */
        recordKeyboardEvent(squeakKeyCode,
			    EventKeyUp,
			    modifiers,
			    squeakKeyCode);
#ifdef DEBUG_KEYBOARD_EVENTS
	printKeyState(0);
#endif
	clearKeyCode();
	break;
    }
  } else {
    updateModifierState(evt);
  }
}

static void printKeyState(int kind) {
  int squeakKeyCode;
  if (keyCode() != 0) {
    squeakKeyCode= keyCode2keyValue( keyCode(), (modifiers & ShiftKeyBit) );
    DPRINTF("*** Key: ");
    printKey( squeakKeyCode ) ;
    switch (kind) {
	case 1: DPRINTF(" DOWN   "); 
		printButtons(   mouseButtonState() );
		printModifiers( modifierState() );
		DPRINTF("\n*** Key: ");
   		printKey( squeakKeyCode ) ;
	/* send both DOWN and KEY events */
		DPRINTF(" KEY    ");
		break;
	case 0: DPRINTF(" UP     "); break;
        case 2: DPRINTF(" REPEAT "); break;
	default: break;
    }
    printButtons(   mouseButtonState() );
    printModifiers( modifierState() );
    if (repeated()) {
      DPRINTF(" key repeated\n " );
    } else {
      DPRINTF("\n");
    }
  }
}

/* === Defined for Squeak in: "platforms/unix/vm/sqUnixEvent.c" 

void printKey(int keyCode)
{
  if (key != 0) {
    DPRINTF("Raw KeyCode (%d = 0x%x) is Squeak key: 0x%x ",
	    keyCode,
	    keyCode,
	    keyCode2keyValue( keyCode, (modifiers & ShiftKeyBit) ) );
  }
}

* === */

static void printModifierKey(struct input_event* evt) {
  DPRINTF( "*** %s ", codename(evt->type, evt->code) );
  switch (evt->value) {
	case 1: DPRINTF("DOWN\n"); break;
	case 2: DPRINTF("REPEAT\n"); break;
	case 0: DPRINTF("UP\n"); break;
	default: break;
  }
}

/*=======================*/
/* Modifier/Adjunct Keys */
/*=======================*/
/* left and right keys down and up must be tracked separately */
static int leftAdjuncts=  0;	/* left-  ctl, alt, shift, meta */
static int rightAdjuncts= 0;	/* right- ctl, alt, shift, meta */

/*
 * Evdev modifiers tracked during processing of libevdev key events.
 * Squeak/OpenSmalltalk VM tracks 'modifierState' in sqUnixEvent.c as
 * queued Squeak key events are processed by the VM.
 *
 * Beware that mouse events are unbuffered and the current state of the
 * mouse is shared.  Keystroke reporting is buffered and processing
 * is separate between libevdev and the VM.
 */

static int modifierState() {
  /* NB: Distinguish 'int modifierState' in sqUnixEvent.c */
  return ( leftAdjuncts | rightAdjuncts );
}

static int setSqueakModifierState() {
  modifierState= ( leftAdjuncts | rightAdjuncts );
}

static void clearModifierState() { 
  leftAdjuncts  = 0;
  rightAdjuncts = 0;
}

static void updateModifierState(struct input_event* evt)
/* left and right keys down and up must be tracked separately */
{  /* harmless if not modifier key */
  if (evt->type == EV_KEY) {
    if (evt->value == 1) { /* button down */
      printModifierKey(evt);
      switch (evt->code) {
	case KEY_LEFTMETA:   leftAdjuncts  |= CommandKeyBit; break;
	case KEY_LEFTALT:    leftAdjuncts  |= OptionKeyBit;  break;
	case KEY_LEFTCTRL:   leftAdjuncts  |= CtrlKeyBit;    break;
	case KEY_LEFTSHIFT:  leftAdjuncts  |= ShiftKeyBit;   break;
	case KEY_RIGHTMETA:  rightAdjuncts |= CommandKeyBit; break;
	case KEY_RIGHTALT:   rightAdjuncts |= OptionKeyBit;  break;
	case KEY_RIGHTCTRL:  rightAdjuncts |= CtrlKeyBit;    break;
	case KEY_RIGHTSHIFT: rightAdjuncts |= ShiftKeyBit;   break;
	default: break;
	}
     } else if (evt->value == 0) { /* button up */
       printModifierKey(evt);
       switch (evt->code) {
	case KEY_LEFTMETA:   leftAdjuncts  &= ~CommandKeyBit; break;
	case KEY_LEFTALT:    leftAdjuncts  &= ~OptionKeyBit;  break;
	case KEY_LEFTCTRL:   leftAdjuncts  &= ~CtrlKeyBit;    break;
	case KEY_LEFTSHIFT:  leftAdjuncts  &= ~ShiftKeyBit;   break;
	case KEY_RIGHTMETA:  rightAdjuncts &= ~CommandKeyBit; break;
	case KEY_RIGHTALT:   rightAdjuncts &= ~OptionKeyBit;  break;
	case KEY_RIGHTCTRL:  rightAdjuncts &= ~CtrlKeyBit;    break;
	case KEY_RIGHTSHIFT: rightAdjuncts &= ~ShiftKeyBit;   break;
	default: break;
        }
     }
    /* ignore repeats (evt->value == 2) */
  } 
}

static void printModifierKey(struct input_event* evt) {
  DPRINTF( "*** %s ", codename(evt->type, evt->code) );
  switch (evt->value) {
	case 1: DPRINTF("DOWN\n"); break;
	case 2: DPRINTF("REPEAT\n"); break;
	case 0: DPRINTF("UP\n"); break;
	default: break;
  }
}



#define _keyboard	struct kb *kbdSelf


typedef void (*kb_callback_t)(int key, int up, int mod);

struct kb
{
  char			 *kbName;
  int			  fd;
  int			  kbMode;
  struct termios	  tcAttr;
  int			  vtActive;
  int			  vtLock;
  int			  vtSwitch;
  int			  state;
  kb_callback_t		  callback;
  unsigned short	**keyMaps;
  struct libevdev	 *dev;  
};

static struct ms kbdDev; /* singleton */

/* NB: Distinguish (libevdev keycode) -> (squeak keycode)
 *     vs  unix key value substitution 'keymapping'
 *  i.e.  sqUnixEvdevKeycodeMap.c  vs  sqUnixFBDevKeymap.c
 *
 * Key mapping transform must be applied only AFTER 
 *  'raw' keycodes have been transformed to 'squeak' keycodes
 */
#include "sqUnixFBDevKeymap.c"


static void updateModifiers(int kstate)
{
  modifierState= 0;
  if (kstate & (1 << KG_SHIFT))	modifierState |= ShiftKeyBit;
  if (kstate & (1 << KG_CTRL))	modifierState |= CtrlKeyBit;
  if (kstate & (1 << KG_ALT))	modifierState |= CommandKeyBit;
  if (kstate & (1 << KG_ALTGR))	modifierState |= OptionKeyBit;
  DPRINTF("state %02x mod %02x\n", kstate, modifierState);
}


static void kb_chvt(_keyboard, int vt)
{
  if (ioctl(kbdSelf->fd, VT_ACTIVATE, vt))
    perror("chvt: VT_ACTIVATE");
  else
    {
      while (ioctl(kbdSelf->fd, VT_WAITACTIVE, vt))
	{
	  if (EINTR == errno)
	    continue;
	  perror("VT_WAITACTIVE");
	  break;
	}
      updateModifiers(kbdSelf->state= 0);
    }
}


static void kb_post(_keyboard, int code, int up)
{
  if (code == 127) code= 8;		//xxx OPTION!!!
  kbdSelf->callback(code, up, modifierState);
}


static void kb_translate(_keyboard, int code, int up)
{
  static int prev= 0;
  unsigned short *keyMap= kbdSelf->keyMaps[kbdSelf->state];
  int rep= (!up) && (prev == code);
  prev= up ? 0 : code;

  DPRINTF("+++ code %d up %d prev %d rep %d map %p\n", code, up, prev, rep, keyMap);

  if (keyMap)
    {
      int sym=  keyMap[code];
      int type= KTYP(sym);
      DPRINTF("+++ sym %x (%02x) type %d\n", sym, sym & 255, type);
      sym &= 255;
      if (type >= 0xf0)		// shiftable
	type -= 0xf0;
      if (KT_LETTER == type)	// lockable
	type= KT_LATIN;
      DPRINTF("+++ type %d\n", type);
      switch (type)
	{
	case KT_LATIN:
	case KT_META:
	  kb_post(kbdSelf, sym, up);
	  break;

	case KT_SHIFT:
	  if      (rep) break;
	  else if (up)  kbdSelf->state &= ~(1 << sym);
	  else          kbdSelf->state |=  (1 << sym);
	  updateModifiers(kbdSelf->state);
	  break;

	case KT_FN:
	case KT_SPEC:
	case KT_CUR:
	  switch (K(type,sym))
	    {
	      // FN
	    case K_FIND:	kb_post(kbdSelf,  1, up);	break;	// home
	    case K_INSERT:	kb_post(kbdSelf,  5, up);	break;
	    case K_SELECT:	kb_post(kbdSelf,  4, up);	break;	// end
	    case K_PGUP:	kb_post(kbdSelf, 11, up);	break;
	    case K_PGDN:	kb_post(kbdSelf, 12, up);	break;
	      // SPEC
	    case K_ENTER:	kb_post(kbdSelf, 13, up);	break;
	      // CUR
	    case K_DOWN:	kb_post(kbdSelf, 31, up);	break;
	    case K_LEFT:	kb_post(kbdSelf, 28, up);	break;
	    case K_RIGHT:	kb_post(kbdSelf, 29, up);	break;
	    case K_UP:		kb_post(kbdSelf, 30, up);	break;
	    }
	  break;

	case KT_CONS:
	  if (kbdSelf->vtSwitch && !kbdSelf->vtLock)
	    kb_chvt(kbdSelf, sym + 1);
	  break;

	default:
	  if (type > KT_SLOCK)
	    DPRINTF("ignoring unknown scancode %d.%d\n", type, sym);
	  break;
	}
    }
}


static void kb_noCallback(int k, int u, int s) {}


static int kb_handleEvents(_keyboard)
{
  DPRINTF("+++ kb_handleEvents\n");
  while (fdReadable(kbdSelf->fd, 0))
    {
      unsigned char buf;
      if (1 == read(kbdSelf->fd, &buf, 1))
	{
	  DPRINTF("+++ kb_translate %3d %02x + %d\n", buf & 127, buf & 127, (buf >> 7) & 1);
	  kb_translate(kbdSelf, buf & 127, (buf >> 7) & 1);
	}
    }
  return 0;
}


static void kbHandler(int fd, void *kbdSelf, int flags)
{
  kb_handleEvents((struct kb *)kbdSelf);
  aioHandle(fd, kbHandler, AIO_RX);
}


static kb_callback_t kb_setCallback(_keyboard, kb_callback_t callback)
{
  /* dummy */
  kbdSelf->callback= kb_noCallback;
  return kb_noCallback;
}


static void kb_bell(_keyboard)
{
  /* NoOp @@FIXME: Squeak Sound @@ */
}


static void sigusr1(int sig)
{
  extern sqInt fullDisplayUpdate(void);
  updateModifiers(kbdSelf->state= 0);
  fullDisplayUpdate();
}


static void kb_initGraphics(_keyboard)
{
  /* NoOp */
}

static void kb_freeGraphics(_keyboard)
{
  /* NoOp */
}


void kb_open(_keyboard, int vtSwitch, int vtLock)
{
  int rc;

  assert(kbdSelf->fd == -1);
  kbdSelf->fd= open(kbdSelf->kbName= keyboardPathDefault, O_RDONLY)
  if (kbdSelf->fd < 0)
    failPermissions("console");

  rc = libevdev_new_from_fd( kbdSelf->fd, &kbdSelf->dev );
  if (rc < 0) {
      fatal("Unable to initialize libevdev keyboard (%s)\n", strerror(-rc) );
  } else {
      DPRINTF("Opened for input: \"%s\" bus %#x vendor %#x product %#x\n",
	      libevdev_get_name(      kbdSelf->dev),
	      libevdev_get_id_bustype(kbdSelf->dev),
	      libevdev_get_id_vendor( kbdSelf->dev),
      	      libevdev_get_id_product(kbdSelf->dev) );
  }

  kb_initKeyMap(kbdSelf, kmPath); /* squeak key mapping */
}


void kb_close(_keyboard)
{
  if (kbdSelf->fd >= 0)
    {
      close(kbdSelf->fd);
      libevdev_free(kbdSelf->dev);
      DPRINTF("%s (%d) closed\n", kbdSelf->msName, kbdSelf->fd);
      kbdSelf->fd= -1;
    }
}


struct kb *kb_new(void)
{
  /*  _keyboard= (struct kb *)calloc(1, sizeof(struct kb)); */
  _keyboard= &kbdDev;
  kbdSelf->fd= -1;
  kbdSelf->dev = 0;
  kbdSelf->callback= kb_noCallback;
  return kbdSelf;
}


void kb_delete(_keyboard)
{
  /*  free(kbdSelf); */
}

#undef _keyboard

/* @@FIXME: only event polling for now @@ */

static void processLibEvdevKeyEvents() {
  struct input_event ev[64];
  int rd;

  rd = read(kbdDev->fd, ev, sizeof(ev));
  if (rd < (int) sizeof(struct input_event)) {
    DPRINTF("expected %d bytes, got %d\n", (int) sizeof(struct input_event), rd);
    DPRINTF("\nevtest: error reading Keyboard");
    return 1;
  }

  for (i = 0; i < rd / sizeof(struct input_event); i++) {
    unsigned int type, code;

    type = ev[i].type;
    code = ev[i].code;

    setKeyCode(ev[i]); /* invokes updateModifierState() */

    enqueueKeyboardEvent(int key, int up, int modifiers);
      
    return EXIT_SUCCESS;
}

static void processLibEvdevMouseEvents() {
  struct input_event ev[64];
  int rd;

  rd = read(mouseDev->fd, ev, sizeof(ev));
  if (rd < (int) sizeof(struct input_event)) {
    DPRINTF("expected %d bytes, got %d\n", (int) sizeof(struct input_event), rd);
    DPRINTF("\nevtest: error reading Mouse");
    return 1;
  }

  for (i = 0; i < rd / sizeof(struct input_event); i++) {
    unsigned int type, code, value;

    type=  ev[i].type;
    code=  ev[i].code;
    value= ev[i].value;

    if ( (type == EV_SYN) | (type == EV_MSC) ) {
      clearMouseWheel();
      /* NB: does NOT clear modifierState */
    } else {
#ifdef DEBUG_MOUSE_EVENTS
      DPRINTF("Event: time %ld.%06ld, ",
	      ev[i].input_event_sec,
	      ev[i].input_event_usec);
      DPRINTF("evdev Mouse type %d, code %d, value: %d\n ", type, code, value);
#endif
      updateMousePosition(ev[i]);
      updateMouseButtons(ev[i]); 

      setSqueakButtonState();
      if (code == REL_WHEEL) {
	recordMouseWheelEvent( 0, value ); /* only up & down => delta-y */
	clearMouseWheel();
      } else {
	recordMouseEvent();  /* Only current mouse pos tracked */
      }
    }
    return EXIT_SUCCESS;
}



/*			E O F			*/

