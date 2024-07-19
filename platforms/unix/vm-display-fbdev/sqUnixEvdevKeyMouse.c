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
/* #include <X11/keysym.h>  * /usr/include/X11/keysym.h */
#include <libevdev-1.0/libevdev/libevdev.h> /*  /usr/include/libevdev-1.0/libevdev/libevdev.h */

extern sqInt sendWheelEvents; /* If true deliver EventTypeMouseWheel else kybd */

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
static int  getModifierState();
static void updateModifierState(struct input_event* evt); 
static void processLibEvdevKeyEvents();
static void enqueueMouseEvent(int b, int dx, int dy);
static void enqueueKeyboardEvent(int key, int up, int modifiers);
#ifdef DEBUG_EVENTS
static void printKeyState(int kind); 
#endif
static void setSqueakModifierState();

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


static int ms_open(struct ms *mouseSelf, char *msDevName, char *msProto)
{
  int rc = 0;

  assert(mouseDev.fd == -1);

  if (msDevName) {
    mouseDev.fd= open(mouseDev.msName= msDevName, O_RDONLY|O_NONBLOCK);
  } else {
    mouseDev.fd= open(mouseDev.msName= MOUSE_DEV_NAME, O_RDONLY|O_NONBLOCK);
  }
  
  if (mouseDev.fd < 0) {
    fprintf(stderr, "You do not have access to %s. Try "
	             "running as root instead.\n",
	    mouseDev.msName );
    failPermissions("mouse");
  }
  else {
    DPRINTF("evdev opened Mouse device %s\n", mouseDev.msName);
    rc = ioctl(mouseDev.fd, EVIOCGRAB, (void*)1);
    /* @@FIXME: test rc @@*/

    /*   rc = libevdev_new_from_fd( mouseDev.fd, &mouseDev.dev );
    if (rc < 0) {
      fatal("Unable to initialize libevdev mouse (%s)\n", strerror(-rc) );
    } else {
      DPRINTF("Opened for input: \"%s\" bus %#x vendor %#x product %#x\n",
	      libevdev_get_name(      mouseDev.dev),
	      libevdev_get_id_bustype(mouseDev.dev),
	      libevdev_get_id_vendor( mouseDev.dev),
      	      libevdev_get_id_product(mouseDev.dev) );
	      } */
  }
  
  return 0;
}


static void ms_close(struct ms *mouseSelf)
{
  if (mouseDev.fd >= 0)
    {
      ioctl(mouseDev.fd, EVIOCGRAB, (void*)0); /* ungrab device */
      close(mouseDev.fd);
      /*      libevdev_free(mouseDev.dev); */
      DPRINTF("%s (%d) closed\n", mouseDev.msName, mouseDev.fd);
      mouseDev.fd= -1;
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

/* this is done by enqueueMouseEvent() 
static void setSqueakMousePosition( int newX, int newY ) {
  mousePosition.x = newX;
  mousePosition.y = newY;
  } */

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
		mousePosition.y = max(0, mousePosition.y + evt->value) ;  
	break;
      default:
	break;
    }
  }
}

#ifdef DEBUG_EVENTS
static void printMouseState() {
   if ( (mousePosition.x != 0) || (mousePosition.y != 0) ) {
     DPRINTF( "*** Mouse at %4d,%4d ", mousePosition.x, mousePosition.y );
     printButtons( buttonState );
     printModifiers( getModifierState() );
     if (mouseWheelDelta() != 0) {
       	DPRINTF( " Mouse Wheel: %d", mouseWheelDelta() );
     }
     DPRINTF("\n");
   }
}
#endif


/*==========================*/
/* Track Mouse Button State */
/*==========================*/

/* Distinguish 'sqInt getButtonState(void)' in sqUnixEvent.c 
 *   which ORs mouse and key modifiers (mouse button bits are shifted)
 */

static void clearMouseButtons() { buttonState = 0 ; wheelDelta = 0; }

static void updateMouseButtons(struct input_event* evt) {
  if (evt->type == EV_KEY) {
    if ((evt->value == 1) || (evt->value == 2)) { /* button down|repeat */
      switch (evt->code) {
	case BTN_LEFT:   buttonState |= LeftMouseButtonBit;  break;
	case BTN_MIDDLE: buttonState |= MidMouseButtonBit;   break;
	case BTN_RIGHT:  buttonState |= RightMouseButtonBit; break;
	default: break;
      }
    } else if (evt->value == 0) { /* button up */
      switch (evt->code) {
	case BTN_LEFT:   buttonState &= ~LeftMouseButtonBit;  break;
	case BTN_MIDDLE: buttonState &= ~MidMouseButtonBit;   break;
	case BTN_RIGHT:  buttonState &= ~RightMouseButtonBit; break;
	default: break;
      }
    }
  }
}

/* Translate between libevdev and OpenSmalltalk/Squeak VM view of keystrokes */

/*==================*/
/* Keyboard Key     */
/*==================*/

static int  lastKeyCode = 0;

static int keyCode()  { return ( lastKeyCode ) ; }

static void clearKeyCode() {
  lastKeyCode = 0 ; 
}

static int isModifier(int code) {
  switch (code) {
    case KEY_LEFTMETA:  
    case KEY_LEFTALT:   
    case KEY_LEFTCTRL:  
    case KEY_LEFTSHIFT: 
    case KEY_RIGHTMETA: 
    case KEY_RIGHTALT:  
    case KEY_RIGHTCTRL: 
    case KEY_RIGHTSHIFT:
	return( TRUE );
	break;
    default: return( FALSE ); /* NOT a modifier/adjunct key */
  }
}


static void setKeyCode(struct input_event* evt) {
  int squeakKeyCode, modifierBits;
  /* NB: possible to get a Key UP _withOUT_ a Key DOWN */
  if (evt->type == EV_KEY) {

    lastKeyCode = evt->code;
    modifierBits = getModifierState();
    squeakKeyCode = keyCode2keyValue( lastKeyCode,
				      (modifierBits & ShiftKeyBit) );

    if (isModifier(evt->code)) {
      /* Track, but do NOT report, modifier-key state. */
      updateModifierState(evt); 
      setSqueakModifierState();
    } else {
#ifdef DEBUG_KEYBOARD_EVENTS
	DPRINTF("Setting key code: %d from raw: %d\n", squeakKeyCode, evt->code);
	printKeyState(evt->value);
#endif
	if (squeakKeyCode == 0) return; /* no mapping for key */

	switch (evt->value) {
	case 0: /* keyUp */
	  enqueueKeyboardEvent(squeakKeyCode,
			       1, /* keyUp: C TRUE */
			       modifierBits);
	  clearKeyCode();
	  break;
	case 1: /* keydown */
	case 2: /* repeat */
	  enqueueKeyboardEvent(squeakKeyCode,
			       0, /* keyUp: C FALSE */
			       modifierBits);
	/* initially cmd-. (command+period) */
	if ((squeakKeyCode && (modifierBits << 8)) == getInterruptKeycode())	
	  setInterruptPending(true);

	  break;
	default:
	  DPRINTF("Key code: %d with UNKNOWN STATE: (%d) ? (0=up|1=down|2=repeat)\n", squeakKeyCode, evt->value);
	  break;
	}
    }
  }
}

#ifdef DEBUG_EVENTS
static void printKeyState(int kind) {
  int evdevKeyCode, squeakKeyCode, mouseButtonBits, modifierBits;
  if ((evdevKeyCode= keyCode()) != 0) {
    mouseButtonBits = buttonState;
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
    DPRINTF("\n");
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

#endif

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
    if ((evt->value == 1) || (evt->value == 2)) { /* button down|repeat */
#ifdef DEBUG_EVENTS
      printEvtModifierKey(evt);
#endif
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
#ifdef DEBUG_EVENTS
       printEvtModifierKey(evt);
#endif
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

  assert(kbDev.fd == -1);
  if (kbDev.kbName == 0) {
    kbDev.kbName= KEYBOARD_DEV_NAME;
  }
  kbDev.fd= open(kbDev.kbName, O_RDONLY|O_NONBLOCK);
  if (kbDev.fd < 0) {
    DPRINTF("FAILED TO OPEN: %s\n", kbDev.kbName);
    failPermissions("console");
  } else {
    DPRINTF("evdev opened Keyboard device %s\n", kbDev.kbName);
    rc = ioctl(kbDev.fd, EVIOCGRAB, (void*)1);
    /* @@FIXME: test rc @@*/
  }
  /*  rc = libevdev_new_from_fd( kbDev.fd, &kbDev.dev );
  if (rc < 0) {
      fatal("Unable to initialize libevdev keyboard (%s)\n", strerror(-rc) );
  } else {
      DPRINTF("Opened for input: \"%s\" bus %#x vendor %#x product %#x\n",
	      libevdev_get_name(      kbDev.dev),
	      libevdev_get_id_bustype(kbDev.dev),
	      libevdev_get_id_vendor( kbDev.dev),
      	      libevdev_get_id_product(kbDev.dev) );
	      }*/

  /*  kb_initKeyMap(kbdSelf, kmPath);   * squeak key mapping */
}


void kb_close(struct kb *kbdSelf)
{
  if (kbDev.fd >= 0)
    {
      ioctl(kbDev.fd, EVIOCGRAB, (void*)0); /* ungrab device */
      close(kbDev.fd);
      /*      libevdev_free(kbDev.dev);  */
      DPRINTF("%s (%d) closed\n", kbDev.kbName, kbDev.fd);
      kbDev.fd= -1;
    }
}


struct kb *kb_new(void)
{
  /*  struct kb *kbdSelf= (struct kb *)calloc(1, sizeof(struct kb)); */
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
    return; /* asynch read */
  }

  for (i = 0; i < rd / sizeof(struct input_event); i++) {
    setKeyCode(&ev[i]); /* invokes enqueueKeyboardEvent() */
  }
}

static void processLibEvdevMouseEvents() {
  struct input_event evt[64];
  int i, read_size;
  int arrowCode, modifierBits; /* for Wheel delta sent as arrow keys */

  read_size = read(mouseDev.fd, evt, sizeof(evt));
  if (read_size < (int) sizeof(struct input_event)) {
    return; /* asynch read */
  }

  for (i = 0; i < read_size / sizeof(struct input_event); i++) {
    unsigned int type, code;
    int value;

    type=  evt[i].type;
    code=  evt[i].code;
    value= evt[i].value;
#ifdef DEBUG_MOUSE_EVENTS
      DPRINTF("EVDEV Mouse Event type %d, code %d, value: %d\n ", type, code, value);
      DPRINTF("      Mouse Event time %ld.%06ld \n",
	      evt[i].input_event_sec,
	      evt[i].input_event_usec);
#endif
    if (type == EV_KEY) { /* (l|m|r)=(r|y|b) mouse keys */
      updateMouseButtons(&evt[i]); 
      setSqueakModifierState();
      setKeyCode(&evt[i]);
#ifdef DEBUG_EVENTS
      printKeyState(value);
#endif
      /* enqueueMouseEvent( buttonState, 0, 0 );  */
      recordMouseEvent();  /* should see mouse buttons.. */
#ifdef DEBUG_EVENTS
      /*      printMouseState(); */
#endif
    } else if ( (type == EV_SYN) | (type == EV_MSC) ) {
      continue; /* skip me, keep looking */
    } else {
      updateMouseButtons(&evt[i]); 
      setSqueakModifierState();
     
      if (type == EV_REL) {
	switch (code) {
	case REL_X:
	  enqueueMouseEvent( buttonState, value, 0 );
	  break;
	case REL_Y:
	  enqueueMouseEvent( buttonState, 0, value );
	  break;
	case REL_WHEEL:
#ifdef DEBUG_EVENTS
	  DPRINTF("EVDEV  Wheel value: %d\n", value);
#endif
	  if (sendWheelEvents) {
	    recordMouseWheelEvent( 0, value ); /* delta-y only */
	  } else { /* Send wheel events as arrow up/down */
	    if (value > -1) {
	      arrowCode = 30; /* arrow ^ up  */
	    } else {
	      arrowCode = 31; /* arrow v down */
	    }
	    /* Use OR of modifier bits to signal synthesized arrow keys */
	    enqueueKeyboardEvent(arrowCode,
				 0, /* key down */
			     (CtrlKeyBit|OptionKeyBit|CommandKeyBit|ShiftKeyBit)); 
	    enqueueKeyboardEvent(arrowCode,
				 1, /* key up */
			     (CtrlKeyBit|OptionKeyBit|CommandKeyBit|ShiftKeyBit)); 
	  }
	  break;
	default:
	  break;
	}
      }
    }
  }
}




/*			E O F			*/

