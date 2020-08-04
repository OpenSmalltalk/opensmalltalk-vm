/* sqUnixEvdevKeyboard.c -- libevdev code for keyboard
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

/* VM interacions */


static void recordKeyboardEvent(int keyCode, int pressCode, int modifiers, int ucs4)
{
  sqKeyboardEvent *evt= allocateKeyboardEvent();
  if (keyCode < 0) keyCode= 0;
  evt->charCode= keyCode;
  evt->pressCode= pressCode;
  evt->modifiers= modifiers;
  evt->utf32Code= ucs4;
  evt->reserved1= 0;
  evt->windowIndex= 0;
  signalInputEvent();
#if DEBUG_KEYBOARD_EVENTS
  DPRINTF("EVENT (recordKeyboardEvent): time: %ld key", evt->timeStamp);
  switch (pressCode)
    {
    case EventKeyDown: DPRINTF(" down "); break;
    case EventKeyChar: DPRINTF(" char "); break;
    case EventKeyUp:   DPRINTF(" up   "); break;
    default:           DPRINTF(" ***UNKNOWN***"); break;
    }
  printModifiers(modifiers);
  printKey(keyCode);
  DPRINTF(" ucs4 %d\n", ucs4);
#endif
}




/*==================*/
/* Keyboard Key     */
/*==================*/

static int  lastKeyCode = 0;
static int  keyRepeated = 0; /*FALSE;*/

int keyCode()  { return ( lastKeyCode ) ; }
int repeated() { return ( keyRepeated ) ; }

void clearKeyCode() {
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

void updateModifierState(struct input_event* evt); /* forward */

void setKeyCode(struct input_event* evt) {
  /* NB: possible to get a Key UP _withOUT_ a Key DOWN */
  if ( (evt->type == EV_KEY) && notModifier(evt->code) ) {
/*    DPRINTF("Setting key code: %d\n", evt->code);  */
    lastKeyCode = evt->code;
    switch (evt->value) {
      case 1: /* keydown */
	printKeyState(1);
	keyRepeated = 0;
	break;
      case 2: /* repeat */
	if (keyRepeated < 2)
	  printKeyState(2);
	keyRepeated = keyRepeated + 1;
	break;
      default: /* 0 => keyUp */
	printKeyState(0);
	clearKeyCode();
	break;
    }
  } else {
    updateModifierState(evt);
  }
}

void printKeyState(int kind) {
  if (keyCode() != 0) {
    DPRINTF("*** Key: ");
    printKey( keyCode() ) ;
    switch (kind) {
	case 1: DPRINTF(" DOWN   "); 
		printButtons(   buttonState() );
		printModifiers( modifierState() );
		DPRINTF("\n*** Key: ");
   		printKey( keyCode() ) ;
	/* send both DOWN and KEY events */
		DPRINTF(" KEY    ");
		break;
	case 0: DPRINTF(" UP     "); break;
        case 2: DPRINTF(" REPEAT "); break;
	default: break;
    }
    printButtons(   buttonState() );
    printModifiers( modifierState() );
    if (repeated()) {
      DPRINTF(" key repeated\n " );
    } else {
      DPRINTF("\n");
    }
  }
}

void printKey(int keyCode)
{
  if (key != 0) {
    DPRINTF("Raw KeyCode (%d = 0x%x) is Squeak key: 0x%x ",
	    keyCode,
	    keyCode,
	    keyCode2keyValue( keyCode, (modifiers & ShiftKeyBit) ) );
  }
}

void printModifiers(int modifiers)
{
  if (modifiers & ShiftKeyBit)   DPRINTF(" Shift");
  if (modifiers & CtrlKeyBit)    DPRINTF(" Control");
  if (modifiers & CommandKeyBit) DPRINTF(" Command");
  if (modifiers & OptionKeyBit)  DPRINTF(" Option");
}

void printModifierKey(struct input_event* evt) {
  DPRINTF( "*** %s ", codename(evt->type, evt->code) );
  switch (evt->value) {
	case 1: DPRINTF("DOWN\n"); break;
	case 2: DPRINTF("REPEAT\n"); break;
	case 0: DPRINTF("UP\n"); break;
	default: break;
  }
}

/*==================*/
/* Modifier/Adjunct Keys */
/*==================*/
static int leftAdjuncts  = 0;	/* left-  ctl, alt, shift, meta */
static int rightAdjuncts = 0;	/* right- ctl, alt, shift, meta */

int modifierState() {
  return ( leftAdjuncts | rightAdjuncts );
}

void clearModifierState() { 
  leftAdjuncts  = 0;
  rightAdjuncts = 0;
}

void updateModifierState(struct input_event* evt)
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


/*==================*/
/* Modifier/Adjunct Keys */
/*==================*/
static int leftAdjuncts  = 0;	/* left-  ctl, alt, shift, meta */
static int rightAdjuncts = 0;	/* right- ctl, alt, shift, meta */

int modifierState() {
  return ( leftAdjuncts | rightAdjuncts );
}

void clearModifierState() { 
  leftAdjuncts  = 0;
  rightAdjuncts = 0;
}

void printModifierKey(struct input_event* evt) {
  DPRINTF( "*** %s ", codename(evt->type, evt->code) );
  switch (evt->value) {
	case 1: DPRINTF("DOWN\n"); break;
	case 2: DPRINTF("REPEAT\n"); break;
	case 0: DPRINTF("UP\n"); break;
	default: break;
  }
}

void updateModifierState(struct input_event* evt)
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

/*==================*/

#define IEB_SIZE	 64	/* must be power of 2 */

sqInputEvent inputEventBuffer[IEB_SIZE];

int iebIn=  0;	/* next IEB location to write */
int iebOut= 0;	/* next IEB location to read  */

#define iebEmptyP()	(iebIn == iebOut)
#define iebAdvance(P)	(P= ((P + 1) & (IEB_SIZE - 1)))


static sqInputEvent *allocateInputEvent(int eventType)
{
  sqInputEvent *evt= &inputEventBuffer[iebIn];
  iebAdvance(iebIn);
  if (iebEmptyP())
    {
      /* overrun: discard oldest event */
      iebAdvance(iebOut);
    }
  evt->type= eventType;
  evt->timeStamp= ioMSecs() & MillisecondClockMask;
  return evt;
}


#define allocateKeyboardEvent() ( \
  (sqKeyboardEvent *)allocateInputEvent(EventTypeKeyboard) \
)

static sqInt getButtonState(void)
{
  /* red button honours the modifiers:
   *	red+ctrl    = yellow button
   *	red+command = blue button
   */
  int buttons   = buttonState();
  int modifiers = modifierState();

  DPRINTF( "BUTTONS (getButtonState)" );
  printModifiers( modifiers );
  printButtons( buttons );
  DPRINTF( "\n" );

  return buttons | (modifiers << 3); 
}


static void signalInputEvent(void)
{
#if DEBUG_EVENTS
  DPRINTF("signalInputEvent\n");
#endif
/*xxx
  if (inputEventSemaIndex > 0)
    signalSemaphoreWithIndex(inputEventSemaIndex); xxx*/
}


/*			E O F			*/
