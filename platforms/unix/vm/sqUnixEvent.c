/* sqUnixEvent.c -- support for window system events.
 * 
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
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
 */

/* Author: Ian Piumarta <ian.piumarta@squeakland.org>
 *
 * Last edited: 2005-04-19 09:06:38 by piumarta on pauillac.hpl.hp.com
 *
 * NOTE: this file is included by the window support files that need it.
 */

#define IEB_SIZE	 64	/* must be power of 2 */

typedef struct
{
  int x, y;
} SqPoint;

SqPoint mousePosition= { 0, 0 };	/* position at last motion event */
int	swapBtn= 0;			/* 1 to swap yellow and blue buttons */

sqInputEvent inputEventBuffer[IEB_SIZE];

int iebIn=  0;	/* next IEB location to write */
int iebOut= 0;	/* next IEB location to read  */

#define iebEmptyP()	(iebIn == iebOut)
#define iebAdvance(P)	(P= ((P + 1) & (IEB_SIZE - 1)))

int buttonState= 0;		/* mouse button state or 0 if not pressed */
int modifierState= 0;		/* modifier key state or 0 if none pressed */

#if defined(DEBUG_EVENTS)

#include <ctype.h>

static void printKey(int key)
{
  printf(" `%c' (%d = 0x%x)", (isgraph(key) ? key : ' '), key, key);
}

static void printButtons(int buttons)
{
  if (buttons & RedButtonBit)    printf(" red");
  if (buttons & YellowButtonBit) printf(" yellow");
  if (buttons & BlueButtonBit)   printf(" blue");
}

static void printModifiers(int midofiers)
{
  if (midofiers & ShiftKeyBit)   printf(" Shift");
  if (midofiers & CtrlKeyBit)    printf(" Control");
  if (midofiers & CommandKeyBit) printf(" Command");
  if (midofiers & OptionKeyBit)  printf(" Option");
}

#endif


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
  evt->timeStamp= ioMSecs();
  return evt;
}

#define allocateMouseEvent() ( \
  (sqMouseEvent *)allocateInputEvent(EventTypeMouse) \
)

#define allocateKeyboardEvent() ( \
  (sqKeyboardEvent *)allocateInputEvent(EventTypeKeyboard) \
)

#define allocateDragEvent() ( \
  (sqDragDropFilesEvent *)allocateInputEvent(EventTypeDragDropFiles) \
)


static sqInt getButtonState(void)
{
  /* red button honours the modifiers:
   *	red+ctrl    = yellow button
   *	red+command = blue button
   */
  int buttons= buttonState;
  int modifiers= modifierState;
  if ((buttons == RedButtonBit) && modifiers)
    {
      int yellow= swapBtn ? BlueButtonBit   : YellowButtonBit;
      int blue=   swapBtn ? YellowButtonBit : BlueButtonBit;
      switch (modifiers)
	{
	case CtrlKeyBit:    buttons= yellow; modifiers &= ~CtrlKeyBit;    break;
	case CommandKeyBit: buttons= blue;   modifiers &= ~CommandKeyBit; break;
	}
    }
#ifdef DEBUG_EVENTS
  printf("BUTTONS");
  printModifiers(modifiers);
  printButtons(buttons);
  printf("\n");
#endif
  return buttons | (modifiers << 3);
}


static void signalInputEvent(void)
{
#ifdef DEBUG_EVENTS
  printf("signalInputEvent\n");
#endif
  if (inputEventSemaIndex > 0)
    signalSemaphoreWithIndex(inputEventSemaIndex);
}


static void recordMouseEvent(void)
{
  int state= getButtonState();
  sqMouseEvent *evt= allocateMouseEvent();
  evt->x= mousePosition.x;
  evt->y= mousePosition.y;
  evt->buttons= (state & 0x7);
  evt->modifiers= (state >> 3);
  evt->reserved1=
    evt->windowIndex= 0;
  signalInputEvent();
#ifdef DEBUG_EVENTS
  printf("EVENT: mouse (%d,%d)", mousePosition.x, mousePosition.y);
  printModifiers(state >> 3);
  printButtons(state & 7);
  printf("\n");
#endif
}


static void recordKeyboardEvent(int keyCode, int pressCode, int modifiers)
{
  sqKeyboardEvent *evt= allocateKeyboardEvent();
  evt->charCode= keyCode;
  evt->pressCode= pressCode;
  evt->modifiers= modifiers;
  evt->reserved1=
    evt->windowIndex= 0;
  signalInputEvent();
#ifdef DEBUG_EVENTS
  printf("EVENT: key");
  switch (pressCode)
    {
    case EventKeyDown: printf(" down "); break;
    case EventKeyChar: printf(" char "); break;
    case EventKeyUp:   printf(" up   "); break;
    default:           printf(" ***UNKNOWN***"); break;
    }
  printModifiers(modifiers);
  printKey(keyCode);
  printf("\n");
#endif
}


static void recordDragEvent(int dragType, int numFiles)
{
  int state= getButtonState();
  sqDragDropFilesEvent *evt= allocateDragEvent();
  evt->dragType= dragType;
  evt->x= mousePosition.x;
  evt->y= mousePosition.y;
  evt->modifiers= (state >> 3);
  evt->numFiles= numFiles;
  evt->windowIndex= 0;
  signalInputEvent();
#ifdef DEBUG_EVENTS
  printf("EVENT: drag (%d,%d)", mousePosition.x, mousePosition.y);
  printModifiers(state >> 3);
  printButtons(state & 7);
  printf("\n");
#endif
}


/* retrieve the next input event from the queue */

static sqInt display_ioGetNextEvent(sqInputEvent *evt)
{
  if (iebEmptyP())
    ioProcessEvents();
  if (iebEmptyP())
    return false;
  *evt= inputEventBuffer[iebOut];
  iebAdvance(iebOut);
  return true;
}


/*** the following are deprecated and should really go away.  for now
     we keep them for backwards compatibility with ancient images	 ***/


#define KEYBUF_SIZE 64

static int keyBuf[KEYBUF_SIZE];		/* circular buffer */
static int keyBufGet= 0;		/* index of next item of keyBuf to read */
static int keyBufPut= 0;		/* index of next item of keyBuf to write */
static int keyBufOverflows= 0;		/* number of characters dropped */

static void recordKeystroke(int keyCode)			/* DEPRECATED */
{
  if (inputEventSemaIndex == 0)
    {
      int keystate= keyCode | (modifierState << 8);
#    ifdef DEBUG_EVENTS
      printf("RECORD keystroke");
      printModifiers(modifierState);
      printKey(keyCode);
      printf(" = %d 0x%x\n", keystate, keystate);
#    endif
      if (keystate == getInterruptKeycode())
	{
	  setInterruptPending(true);
	  setInterruptCheckCounter(0);
	}
      else
	{
	  keyBuf[keyBufPut]= keystate;
	  keyBufPut= (keyBufPut + 1) % KEYBUF_SIZE;
	  if (keyBufGet == keyBufPut)
	    {
	      /* buffer overflow; drop the last character */
	      keyBufGet= (keyBufGet + 1) % KEYBUF_SIZE;
	      keyBufOverflows++;
	    }
	}
    }
}




static sqInt display_ioPeekKeystroke(void)			/* DEPRECATED */
{
  int keystate;

  ioProcessEvents();  /* process all pending events */
  if (keyBufGet == keyBufPut)
    return -1;  /* keystroke buffer is empty */
  keystate= keyBuf[keyBufGet];
  return keystate;
}


static sqInt display_ioGetKeystroke(void)			/* DEPRECATED */
{
  int keystate;

  ioProcessEvents();  /* process all pending events */
  if (keyBufGet == keyBufPut)
    return -1;  /* keystroke buffer is empty */
  keystate= keyBuf[keyBufGet];
  keyBufGet= (keyBufGet + 1) % KEYBUF_SIZE;
  return keystate;
}


static sqInt display_ioGetButtonState(void)
{
  ioProcessEvents();  /* process all pending events */
  return getButtonState();
}


static sqInt display_ioMousePoint(void)
{
  ioProcessEvents();  /* process all pending events */
  /* x is high 16 bits; y is low 16 bits */
  return (mousePosition.x << 16) | (mousePosition.y);
}
