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
#include <linux/input.h>   /* /usr/include/linux/input.h */
#include <X11/keysym.h>  /* /usr/include/X11/keysym.h */
#include <libevdev-1.0/libevdev/libevdev.h> /*  /usr/include/libevdev-1.0/libevdev/libevdev.h */

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

/* C thinks these are booleans */
#define FALSE 0
#define TRUE (!FALSE)

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

/* forward declarations */
static int  getMouseButtonState();
static int  getModifierState(); 
static void printKeyState(int kind); 
static void processLibEvdevKeyEvents();

  
/* Mouse */

struct ms
{
  char 		  *msName;
  int		   fd;
  struct libevdev *dev;
};

static struct ms mouseDev;


/* NB: defaults on RPi3 Alpine Linux */
#define MOUSE_DEV_NAME    "/dev/input/event1"
#define KEYBOARD_DEV_NAME "/dev/input/event0"


static int ms_open(struct ms *mouseSelf, char *msDev, char *msProto)
{
  int rc = 0;

  assert(mouseSelf->fd == -1);

  if (msDev) {
    mouseSelf->fd= open(mouseSelf->msName= msDev, O_RDONLY);
  } else {
    mouseSelf->fd= open(mouseSelf->msName= MOUSE_DEV_NAME, O_RDWR);
  }
  
  if (mouseSelf->fd < 0) {
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
  
  return 0;
}


static void ms_close(struct ms *mouseSelf)
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
  mouseDev.fd= -1;
  mouseDev.dev= 0;
  return &mouseDev;
}


static void ms_delete(struct ms *mouseSelf)
{
  /*  free(mouseSelf); */
}


/* Interactin with VM */

static int wheelDelta = 0;  /* reset in clearMouseButtons() */

static void clearMouseWheel() {  wheelDelta = 0 ; }
static int  mouseWheelDelta() { return ( wheelDelta ) ; }

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
     printButtons( getMouseButtonState() );
     printModifiers( getModifierState() );
     if (mouseWheelDelta() != 0) {
       	DPRINTF( " Mouse Wheel: %d", mouseWheelDelta() );
     }
     DPRINTF("\n");
   }
}



/*==========================*/
/* Track Mouse Button State */
/*==========================*/

static int mouseButtonsDown = 0;  /* (left|mid|right) = (Red|Yellow|Blue) */

/* Distinguish 'sqInt getButtonState(void)' in sqUnixEvent.c 
 *   which ORs mouse and key modifiers (mouse button bits are shifted)
 */

static int getMouseButtonState() { return ( mouseButtonsDown ) ; }

static void setSqueakButtonState() {
  buttonState= getMouseButtonState();
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





/* Translate between libevdev and OpenSmalltalk/Squeak VM view of keystrokes */

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
  int squeakKeyCode, modifierBits;
  /* NB: possible to get a Key UP _withOUT_ a Key DOWN */
  if ( (evt->type == EV_KEY) && notModifier(evt->code) ) {
    lastKeyCode = evt->code;
    modifierBits = getModifierState();
    squeakKeyCode = keyCode2keyValue( lastKeyCode,
				      (modifierBits & ShiftKeyBit) );
#ifdef DEBUG_KEYBOARD_EVENTS
    DPRINTF("Setting key code: %d from raw: %d\n", squeakKeyCode, evt->code);
#endif
    switch (evt->value) {

      case 1: /* keydown */
        recordKeyboardEvent(squeakKeyCode,
			    EventKeyDown,
			    modifierBits,
			    squeakKeyCode);
#ifdef DEBUG_KEYBOARD_EVENTS
	printKeyState(1);
#endif
	keyRepeated = 0;
	break;
      
      case 2: /* repeat */
        recordKeyboardEvent(squeakKeyCode,
			    EventKeyChar, /* Squeak lacks EventKeyRepeat */
			    modifierBits,
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
			    modifierBits,
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
  int evdevKeyCode, squeakKeyCode, mouseButtonBits, modifierBits;
  if ((evdevKeyCode= keyCode()) != 0) {
    mouseButtonBits = getMouseButtonState();
    modifierBits    = getModifierState();
    squeakKeyCode= keyCode2keyValue( keyCode(),
				     (modifierBits & ShiftKeyBit) );
    DPRINTF("*** Evdev Key: ");
    printKey( squeakKeyCode ) ;
    switch (kind) {
	case 1: DPRINTF(" DOWN   "); 
		printButtons(   mouseButtonBits );
		printModifiers( modifierBits );
		DPRINTF("\n*** Squeak Key: ");
   		printKey( squeakKeyCode ) ;
	/* send both DOWN and KEY events */
		DPRINTF(" KEY    ");
		break;
	case 0: DPRINTF(" UP     "); break;
        case 2: DPRINTF(" REPEAT "); break;
	default: break;
    }
    printButtons(   mouseButtonBits );
    printModifiers( modifierBits );
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
	    keyCode2keyValue( keyCode, (getModifierState() & ShiftKeyBit) ) );
  }
}

* === */

static void printEvtModifierKey(struct input_event* evt) {
  DPRINTF( "*** Modifier (type,code) = (%d,%d) ", evt->type, evt->code );
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

static int getModifierState() {
  /* NB: Distinguish 'int modifierState' in sqUnixEvent.c */
  return ( leftAdjuncts | rightAdjuncts );
}

static void setSqueakModifierState() {
  modifierState= getModifierState();
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
      printEvtModifierKey(evt);
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
       printEvtModifierKey(evt);
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


struct kb
{
  char			 *kbName;
  int			  fd;
  int			  kbMode;
  int			  state;
  struct libevdev	 *dev;  
};

static struct kb kbDev;


/* NB: Distinguish (libevdev keycode) -> (squeak keycode)
 *     vs  unix key value substitution 'keymapping'
 *  i.e.  sqUnixEvdevKeycodeMap.c  vs  sqUnixFBDevKeymap.c
 *
 * Key mapping transform must be applied only AFTER 
 *  'raw' keycodes have been transformed to 'squeak' keycodes
 *
 *   @@  @@FIXME: elided for now. @@ 
 */
/* include "sqUnixFBDevKeymap.c" */



static void kb_bell(struct kb *kbdSelf)
{
  /* NoOp @@FIXME: Squeak Sound @@ */
}


static void sigusr1(int sig)
{
  extern sqInt fullDisplayUpdate(void);

  clearMouseButtons();
  clearModifierState();
  /* @@FIXME: other cleanouts? @@ */
  fullDisplayUpdate();
}


static void kb_initGraphics(struct kb *kbdSelf)
{
  /* NoOp */
}

static void kb_freeGraphics(struct kb *kbdSelf)
{
  /* NoOp */
}


void kb_open(struct kb *kbdSelf, int vtSwitch, int vtLock)
{
  int rc;

  assert(kbdSelf->fd == -1);
  kbdSelf->fd= open(kbdSelf->kbName= KEYBOARD_DEV_NAME, O_RDONLY);
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

  /*  kb_initKeyMap(kbdSelf, kmPath);   * squeak key mapping */
}


void kb_close(struct kb *kbdSelf)
{
  if (kbdSelf->fd >= 0)
    {
      close(kbdSelf->fd);
      libevdev_free(kbdSelf->dev);
      DPRINTF("%s (%d) closed\n", kbdSelf->kbName, kbdSelf->fd);
      kbdSelf->fd= -1;
    }
}


struct kb *kb_new(void)
{
  /*  struct kb *kbdSelf= (struct kb *)calloc(1, sizeof(struct kb)); */
  struct kb *kbdSelf= &kbDev;
  kbDev.fd= -1;
  kbDev.dev = 0;
  return &kbDev;
}


/* @@FIXME: only event polling for now @@ */

static void processLibEvdevKeyEvents() {
  struct input_event ev[64];
  int i, rd;

  rd = read(kbDev.fd, ev, sizeof(ev));
  if (rd < (int) sizeof(struct input_event)) {
    DPRINTF("expected %d bytes, got %d\n", (int) sizeof(struct input_event), rd);
    DPRINTF("\nevtest: error reading Keyboard");
    return; /* @@FIXME: resynch? @@ */
  }

  for (i = 0; i < rd / sizeof(struct input_event); i++) {
    setKeyCode(&ev[i]); /* invokes recordKeyboardEvent() */
  }
}

static void processLibEvdevMouseEvents() {
  struct input_event ev[64];
  int i, rd;

  rd = read(mouseDev.fd, ev, sizeof(ev));
  if (rd < (int) sizeof(struct input_event)) {
    DPRINTF("expected %d bytes, got %d\n", (int) sizeof(struct input_event), rd);
    DPRINTF("\nevtest: error reading Mouse");
    return; /* @@FIXME: resynch @@ */
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
      updateSqueakMousePosition(&ev[i]);
      updateMouseButtons(&ev[i]); 

      setSqueakButtonState();
      if (code == REL_WHEEL) {
	recordMouseWheelEvent( 0, value ); /* only up & down => delta-y */
	clearMouseWheel();
      } else {
	recordMouseEvent();  /* Only current mouse pos tracked */
      }
    }
  }
}



/*			E O F			*/

