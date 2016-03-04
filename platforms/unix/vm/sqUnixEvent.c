/* sqUnixEvent.c -- support for window system events.
 * 
 *   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

/* Author: Ian Piumarta <ian.piumarta@squeakland.org>
 *
 * Last edited: 2009-08-15 15:39:46 by piumarta on emilia-2.local
 * Last edited: Tue Jan 19 17:10:19 PST 2010 by eliot, nuke
 * setInterruptCheckCounter calls.
 *
 * NOTE: this file is included by the window support files that need it.
 */

#if defined(DEBUG_EVENTS)
# undef DEBUG_EVENTS
# define DEBUG_EVENTS 1
# define DEBUG_KEYBOARD_EVENTS 1
# define DEBUG_MOUSE_EVENTS 1
#else
# if defined(DEBUG_KEYBOARD_EVENTS)
#	undef DEBUG_KEYBOARD_EVENTS
#	define DEBUG_KEYBOARD_EVENTS 1
# endif
# if defined(DEBUG_MOUSE_EVENTS)
#	undef DEBUG_MOUSE_EVENTS
#	define DEBUG_MOUSE_EVENTS 1
# endif
#endif

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

#if DEBUG_EVENTS || DEBUG_KEYBOARD_EVENTS || DEBUG_MOUSE_EVENTS

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

#endif /* DEBUG_KEYBOARD_EVENTS || DEBUG_MOUSE_EVENTS */


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

#define allocateMouseEvent() ( \
  (sqMouseEvent *)allocateInputEvent(EventTypeMouse) \
)

#define allocateKeyboardEvent() ( \
  (sqKeyboardEvent *)allocateInputEvent(EventTypeKeyboard) \
)

#define allocateDragEvent() ( \
  (sqDragDropFilesEvent *)allocateInputEvent(EventTypeDragDropFiles) \
)

#define allocateWindowEvent() ( \
  (sqWindowEvent *)allocateInputEvent(EventTypeWindow) \
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
#if DEBUG_MOUSE_EVENTS
  printf("BUTTONS (getButtonState)");
  printModifiers(modifiers);
  printButtons(buttons);
  printf("\n");
#endif
  return buttons | (modifiers << 3);
}


static void signalInputEvent(void)
{
#if DEBUG_EVENTS
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
  evt->nrClicks=
    evt->windowIndex= 0;
  signalInputEvent();
#if DEBUG_MOUSE_EVENTS
  printf("EVENT (recordMouseEvent): time: %d  mouse (%d,%d)", evt->timeStamp, mousePosition.x, mousePosition.y);
  printModifiers(state >> 3);
  printButtons(state & 7);
  printf("\n");
#endif
}


static void recordKeyboardEvent(int keyCode, int pressCode, int modifiers, int ucs4)
{
  sqKeyboardEvent *evt= allocateKeyboardEvent();
  if (keyCode < 0) keyCode= 0;
  evt->charCode= keyCode;
  evt->pressCode= pressCode;
  evt->modifiers= modifiers;
  evt->utf32Code= ucs4;
  evt->reserved1=
    evt->windowIndex= 0;
  signalInputEvent();
#if DEBUG_KEYBOARD_EVENTS
  printf("EVENT (recordKeyboardEvent): time: %d key", evt->timeStamp);
  switch (pressCode)
    {
    case EventKeyDown: printf(" down "); break;
    case EventKeyChar: printf(" char "); break;
    case EventKeyUp:   printf(" up   "); break;
    default:           printf(" ***UNKNOWN***"); break;
    }
  printModifiers(modifiers);
  printKey(keyCode);
  printf(" ucs4 %d\n", ucs4);
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
#if DEBUG_EVENTS
  printf("EVENT (recordDragEvent): drag (%d,%d)", mousePosition.x, mousePosition.y);
  printModifiers(state >> 3);
  printButtons(state & 7);
  printf("\n");
#endif
}


static void recordWindowEvent(int action, int v1, int v2, int v3, int v4, int windowIndex)
{
  sqWindowEvent *evt= allocateWindowEvent();
  evt->action= action;
  evt->value1= v1;
  evt->value2= v2;
  evt->value3= v3;
  evt->value4= v4;
  evt->windowIndex= windowIndex;
  signalInputEvent();
#if DEBUG_EVENTS
  printf("EVENT (recordWindowEvent): window (%d %d %d %d %d %d) ", action, v1, v2, v3, v4, 0);
  switch (action)
    {
    case WindowEventMetricChange: printf("metric change");  break;
    case WindowEventClose:        printf("close");	    break;
    case WindowEventIconise:      printf("iconise");	    break;
    case WindowEventActivated:    printf("activated");	    break;
    case WindowEventPaint:        printf("paint");	    break;
    default:                      printf("***UNKNOWN***");  break;
    }
  printf("\n");
#endif
}


/* retrieve the next input event from the queue */

static sqInt display_ioGetNextEvent(sqInputEvent *evt)
{
  if (iebEmptyP())
    ioProcessEvents();
  LogEventChain((dbgEvtChF,"ioGNE%s",iebEmptyP()?"_":"!\n"));
  if (iebEmptyP())
       return false;
  *evt= inputEventBuffer[iebOut];
#if DEBUG_EVENTS
  if (evt->type == EventTypeMouse) {
   printf( "(ioGetNextEvent) MOUSE evt: time: %d x: %d y: %d ", evt->timeStamp, evt->unused1, evt->unused2);
   printButtons( evt->unused3);
   printf("\n");
  }
  if (evt->type == EventTypeKeyboard) {
   printf( "(ioGetNextEvent) KEYBOARD evt: time: %d char: %d utf32: %d ", evt->timeStamp, evt->unused1, evt->unused4);
   printf("\n");
  }
  
#endif
  iebAdvance(iebOut);
  return true;
}


#if !defined(recordKeystroke)
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
#    if DEBUG_KEYBOARD_EVENTS
      printf("RECORD keystroke");
      printModifiers(modifierState);
      printKey(keyCode);
      printf(" = %d 0x%x\n", keystate, keystate);
#    endif
      if (keystate == getInterruptKeycode())
	  setInterruptPending(true);
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
#else
static sqInt display_ioPeekKeystroke(void) { return 0; }	/* DEPRECATED */
static sqInt display_ioGetKeystroke(void) { return 0; }	/* DEPRECATED */
#endif /* !defined(recordKeystroke) */


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
