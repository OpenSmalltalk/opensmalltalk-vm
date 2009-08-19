/* sqUnixXdnd.c -- drag-and-drop for the X Window System.	-*- C -*-
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

/* Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * Last edited: 2009-08-19 04:21:30 by piumarta on emilia-2.local
 * 
 * BUGS
 * 
 * - This only works with version 3 and higher of the XDND protocol.
 *   No attempt whatsoever is made to check for and deal with earlier
 *   versions.  Since version 3 is at least six years old now, I doubt
 *   this matters much.
 * 
 * - Some memory could be released between drop operations, but it's
 *   only a few tens of bytes so who cares?
 * 
 * - Only filenames (MIME type text/uri-list) are handled, although
 *   it would be trivial to extend the code to cope with dropping text
 *   selections into the Squeak clipboard.  I'm simply too lazy to be
 *   bothered.
 * 
 * - No attempt is made to verify that XDND protocol messages arrive
 *   in the correct order.  (If your WM or file manager is broken, you
 *   get to keep all the shrapnel that will be left behind after
 *   dragging something onto Squeak).
 */


#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#include <X11/Xlib.h>
#include <X11/Xatom.h>


#define DEBUG_XDND	0


static	Atom	  XdndVersion= (Atom)3;

static	Atom	  XdndAware;
static	Atom	  XdndSelection;
static	Atom	  XdndEnter;
static	Atom	  XdndLeave;
static	Atom	  XdndPosition;
static	Atom	  XdndDrop;
static	Atom	  XdndFinished;
static	Atom	  XdndStatus;
static	Atom	  XdndActionCopy;
static	Atom	  XdndActionMove;
static	Atom	  XdndActionLink;
static	Atom	  XdndActionAsk;
static	Atom	  XdndActionPrivate;
static	Atom	  XdndTypeList;
static	Atom	  XdndTextUriList;
static	Atom	  XdndSelectionAtom;

static	Window	  xdndSourceWindow= 0;
static	int	  isUrlList= 0;
static	int	  xdndWillAccept= 0;

/* To keep backword compatibitily, xdndWillAccept is always 1.
 * isUrlList is 1 only if the dropped type includes "text/uri-list".
 * 
 * case isUrlList == 1: Get url list and send dndFinished immediately.  Then record drag event.
 * case isUrlList == 0: Record drag event anyway (uxDropFileCount= 0).  The image will get the data and send dndFinished.
 */

static Atom	 *xdndInTypes= 0;   /* all targets in clipboard */

static Window     xdndOutTarget= None;
static Atom      *xdndOutTypes= 0;  /* Types offered by source window */

static XSelectionRequestEvent xdndOutRequestEvent; /* RequestEvent from target */

enum XdndState {
  XdndStateIdle,
  XdndStateEntered,
  XdndStateTracking,
  XdndStateOutTracking,
  XdndStateOutAccepted
};

enum {
  DndOutStart	= -1,
  DndInFinished	= -2
};

#define xdndEnter_sourceWindow(evt)		( (evt)->data.l[0])
#define xdndEnter_version(evt)			( (evt)->data.l[1] >> 24)
#define xdndEnter_hasThreeTypes(evt)		(((evt)->data.l[1] & 0x1UL) == 0)
#define xdndEnter_typeAt(evt, idx)		( (evt)->data.l[2 + (idx)])
#define xdndEnter_targets(evt)			( (evt)->data.l + 2)

#define xdndPosition_sourceWindow(evt)		((Window)((evt)->data.l[0]))
#define xdndPosition_rootX(evt)			((evt)->data.l[2] >> 16)
#define xdndPosition_rootY(evt)			((evt)->data.l[2] & 0xffffUL)
#define xdndPosition_action(evt)		((Atom)((evt)->data.l[4]))

#define xdndStatus_targetWindow(evt)		((evt)->data.l[0])
#define xdndStatus_setWillAccept(evt, b)	((evt)->data.l[1]= (((evt)->data.l[1] & ~1UL) | ((b) ? 1 : 0)))
#define xdndStatus_setWantPosition(evt, b)	((evt)->data.l[1]= (((evt)->data.l[1] & ~2UL) | ((b) ? 2 : 0)))
#define xdndStatus_action(evt)			((evt)->data.l[4])

#define xdndDrop_sourceWindow(evt)		((Window)((evt)->data.l[0]))
#define xdndDrop_time(evt)			((evt)->data.l[2])

#define xdndFinished_targetWindow(evt)		((evt)->data.l[0])


#if (DEBUG_XDND)
# define fdebugf(ARGS) do { fprintf ARGS; } while (0)
#else
# define fdebugf(ARGS) do { } while (0)
#endif

static void updateCursor(int state);

void getMousePosition(void);


static void *xmalloc(size_t size)
{
  void *ptr= malloc(size);
  if (!ptr)
    {
      fprintf(stderr, "out of memory\n");
      exit(1);
    }
  return ptr;
}


static void *xcalloc(size_t nmemb, size_t size)
{
  void *ptr= calloc(nmemb, size);
  if (!ptr)
    {
      fprintf(stderr, "out of memory\n");
      exit(1);
    }
  return ptr;
}


static void *xrealloc(void *ptr, size_t size)
{
  ptr= realloc(ptr, size);
  if (!ptr)
    {
      fprintf(stderr, "out of memory\n");
      exit(1);
    }
  return ptr;
}


static int hexValue(const int c)
{
  if (c <  '0') return 0;
  if (c <= '9') return c - '0';
  if (c <  'A') return 0;
  if (c <= 'F') return c - 'A' + 10;
  if (c <  'a') return 0;
  if (c <= 'f') return c - 'a' + 10;
  return 0;
}


static char *uri2string(const char *uri)
{
  size_t len= strlen(uri);
  char *string= (char *)xmalloc(len + 3);
  /* whoever wrote the URL stuff in the the image was too damn stupid to understand file URIs */
  if (!strncmp(uri, "file:", 5))
    {
      char *in= string, *out= string;
      strncpy(string, uri + 5, len);
      while (*in)
	if ((in[0] == '%') && isxdigit(in[1]) && isxdigit(in[2]))
	  {
	    *out++= hexValue(in[1]) * 16 + hexValue(in[2]);
	    in += 3;
	  }
	else
	  *out++= *in++;
      *out= '\0';
    }
  else
    {
      strncpy(string, uri, len);
    }
  fdebugf((stderr, "  uri2string: <%s>\n", string));
  return string;
}


/*** Handle DnD Output ***/


#define DndWindow stParent

/* Answer dndAware window under the cursor, or None if not found.
 */
static Window dndAwareWindow(Window root, Window child, int *versionReturn)
{
  Atom actualType;
  int actualFormat;
  unsigned long nitems, bytesAfter;
  unsigned char *data;
  Window rootReturn, childReturn;
  int rootX, rootY, winX, winY;
  unsigned int mask;

  if (None == child) return None;
  XGetWindowProperty(stDisplay, child, XdndAware,
		     0, 0x8000000L, False, XA_ATOM,
		     &actualType, &actualFormat, &nitems,
		     &bytesAfter, &data);
  if (nitems > 0)
    {
      *versionReturn= (int)*data;
      return child;
    }
  
  XQueryPointer(stDisplay, child, &rootReturn, &childReturn, &rootX, &rootY, &winX, &winY, &mask);

  if (childReturn == None) return None;

  return dndAwareWindow(root, childReturn, versionReturn);
}


/* Send ClientMessage to drop target.
 *
 * long data[5] : event specific data
 * Window source : source window (stParent)
 * Window target : target window
 * char * type : event type name
 */
static void sendClientMessage(long *data, Window source, Window target, Atom type)
{
  XEvent e;
  XClientMessageEvent *evt= &e.xclient;
  if (None == target) return;
  evt->type= ClientMessage;
  evt->serial= 0;
  evt->send_event= 0;
  evt->display= stDisplay;
  evt->window= target;
  evt->message_type= type;
  evt->format= 32;
  evt->data.l[0]= source;
  evt->data.l[1]= data[1];
  evt->data.l[2]= data[2];
  evt->data.l[3]= data[3];
  evt->data.l[4]= data[4];
  XSendEvent(stDisplay, target, 0, 0, &e);
/*fdebugf((stderr, "Send %s to: 0x%lx\n", type, target));*/
}

static void sendEnter(Window target, Window source)
{
  long data[5]= { 0, 0, 0, 0, 0 };
  data[1] |= 0x0UL; /* just three data types */
  data[1] |= XdndVersion << 24; /* version num */

  if (0 != xdndOutTypes)
    {
      data[2]= xdndOutTypes[0];
      if (None != xdndOutTypes[1])
	{
	  data[3]= xdndOutTypes[1];
	  if (None != xdndOutTypes[2])
	    {
	      data[4]= xdndOutTypes[1];
	    }
	}
    }
  fdebugf((stderr, "Send XdndEnter (output) source: 0x%lx target: 0x%lx\n", source, target));
  sendClientMessage(data, source, target, XdndEnter);
}


static void sendPosition(Window target, Window source, int rootX, int rootY, Time timestamp)
{
  long data[5]= { 0, 0, 0, 0, 0 };
  data[2]= (rootX << 16) | rootY;
  data[3]= timestamp;
  data[4]= XdndActionCopy;
  sendClientMessage(data, source, target, XdndPosition);
}


static void sendDrop(Window target, Window source, Time timestamp)
{
  long data[5]= { 0, 0, 0, 0, 0 };
  data[2]= timestamp;
  fdebugf((stderr, "Send XdndDrop (output) source: 0x%lx target: 0x%lx\n", source, target));

  sendClientMessage(data, source, target, XdndDrop);
}


static void sendLeave(Window target, Window source)
{
  long data[5]= { 0, 0, 0, 0, 0 };
  fdebugf((stderr, "Send XdndLeave (output) source: 0x%lx target: 0x%lx\n", source, target));
  sendClientMessage(data, source, target, XdndLeave);
}


static enum XdndState dndOutInitialize(enum XdndState state)
{
  fdebugf((stderr, "Internal signal DndOutStart (output)\n"));
  memset(&xdndOutRequestEvent, 0, sizeof(xdndOutRequestEvent));
  XSetSelectionOwner(stDisplay, XdndSelection, DndWindow, CurrentTime);
  updateCursor(-1);
  return XdndStateOutTracking;
}


/* Track the current mouse position.
 */
static enum XdndState dndOutMotion(enum XdndState state, XMotionEvent *evt)
{
  Window currentWindow= None;
  int versionReturn= 0;

  if ((XdndStateOutTracking != state) && (XdndStateOutAccepted != state)) return state;

  currentWindow= dndAwareWindow(evt->root, evt->root, &versionReturn);
  if (DndWindow == currentWindow) /* Cursor is on myself */
    {
      xdndOutTarget= None;
      return XdndStateOutTracking;
    }
  
  updateCursor(XdndStateOutAccepted == state);

  if ((XdndVersion > versionReturn)	/* Target's version is too low. */
      || (None == currentWindow))	/* I can't find XdndAware window. */
    {
      xdndOutTarget= None;
      return XdndStateOutTracking;
    }
  
  fdebugf((stderr, "Receive MotionNotify (output) root: 0x%lx awareWindow: 0x%lx\n", evt->root, currentWindow));
  if (currentWindow != xdndOutTarget)
    {
      sendLeave(xdndOutTarget, DndWindow);
      sendEnter(currentWindow, DndWindow);
    }

  sendPosition(currentWindow, DndWindow, evt->x_root, evt->y_root, evt->time);
  xdndOutTarget= currentWindow;

  return state;
}


/* A status message to know accept or not is received.
 */
static enum XdndState dndOutStatus(enum XdndState state, XClientMessageEvent *evt)
{
  long *ldata= evt->data.l;
  fdebugf((stderr, "Receive XdndStatus (output) status: 0x%lx target: 0x%lx\n", ldata[1], ldata[0]));

  if ((XdndStateOutTracking != state) && (XdndStateOutAccepted != state))
    {
      /*printf("%i is not expected in XdndStatus\n", state);*/
      sendLeave(ldata[0], DndWindow);
      return state;
    }
  
  if (xdndOutTarget != ldata[0]) return state;

  if (ldata[1] && 0x1UL)
    return XdndStateOutAccepted;
  else
    return XdndStateOutTracking;
}


/* The mouse button was released.
*/
static enum XdndState dndOutRelease(enum XdndState state, XButtonEvent *evt)
{
  if (XdndStateIdle == state) return XdndStateIdle;
  fdebugf((stderr, "Receive ButtonRelease (output) window: 0x%lx\n", evt->window));

  if (XdndStateOutAccepted == state)
    {
      sendDrop(xdndOutTarget, DndWindow, evt->time);
      return XdndStateOutAccepted;
    }
  sendLeave(xdndOutTarget, DndWindow);
  return XdndStateIdle;
}


/* Another application is requesting the selection.
*/
static enum XdndState dndOutSelectionRequest(enum XdndState state, XSelectionRequestEvent *req)
{
  fdebugf((stderr, "Receive SelectionRequest for %s (output) owner: 0x%lx : requestor: 0x%lx\n",
           XGetAtomName(stDisplay, req->target), req->owner, req->requestor));
  if (XdndStateOutAccepted != state)
    {
      /*printf("%i is not expected in SelectionRequest\n", state);*/
      return state;
    }
  memcpy(&xdndOutRequestEvent, req, sizeof(xdndOutRequestEvent));
  recordDragEvent(DragRequest, 1);
  return state;
}


/* A finished message is received.
 */
static enum XdndState dndOutFinished(enum XdndState state, XClientMessageEvent *evt)
{
  fdebugf((stderr, "Receive XdndFinished (output) source: 0x%lx target: 0x%lx\n",
           DndWindow, xdndFinished_targetWindow(evt)));
  xdndOutTarget= None;
  return XdndStateIdle;
}


/* Change cursor
 * TODO: The cursor should be controlled by the image, so it should be removed finally.
 *
 * state = -1 : Cursor is on Squeak window.
 * state =  0 : Target window doesn't accept.
 * state =  1 : Target window accepts.
 */
static void updateCursor(int state)
{
  static int lastCursor= -1;

  if (lastCursor == state) return;
  fdebugf((stderr, "Cursor change (output) previous: %i new: %i\n", lastCursor, state));
  if (1 == state)
    {
      Cursor cursor;
      cursor= XCreateFontCursor(stDisplay, 90);
      XDefineCursor(stDisplay, stWindow, cursor);
    }
  else
    XDefineCursor(stDisplay, stWindow, None);
  
  lastCursor= state;
}


static void dndInDestroyTypes(void)
{
  if (xdndInTypes == NULL)
    return;
  free(xdndInTypes);
  xdndInTypes= NULL;
}


static void updateInTypes(Atom *newTargets, int targetSize)
{
  int i;
  dndInDestroyTypes();
  xdndInTypes= (Atom *)calloc(targetSize + 1, sizeof(Atom));
  for (i= 0;  i < targetSize;  ++i)
    xdndInTypes[i]= newTargets[i];
  xdndInTypes[targetSize]= None;
}


/* Answer non-zero if dnd input object is available.
*/
static int dndAvailable(void)
{
  return useXdnd && xdndInTypes;
}


/* Answer types for dropping object.
 * types - returned types (it should be copied by client), or NULL if unavailable.
 * count - number of types.
 */
static void dndGetTargets(Atom **types, int *count)
{
  int i;
  *types= 0;
  *count= 0;
  if (!xdndInTypes) return;
  for (i= 0;  None != xdndInTypes[i];  ++i);
  *count= i;
  *types= xdndInTypes;
}


static void dndGetTypeList(XClientMessageEvent *evt)
{
  xdndWillAccept= 0;
  isUrlList= 0;

  if (xdndEnter_hasThreeTypes(evt))
    {
      fdebugf((stderr, "  3 types\n"));
      updateInTypes((Atom *) xdndEnter_targets(evt), 3);
    }
  else
    {
      Atom type;
      int format;
      unsigned long count, remaining;
      unsigned char *data= 0;

      XGetWindowProperty(stDisplay, xdndSourceWindow, XdndTypeList, 0, 0x8000000L, False, XA_ATOM,
			 &type, &format, &count, &remaining, &data);

      if ((type != XA_ATOM) || (format != 32) || (count == 0) || !data)
	{
	  if (data) XFree(data);
	  fprintf(stderr, "XGetWindowProperty failed in xdndGetTypeList\n");
	  return;
	}

      updateInTypes((Atom *) data, count);
      XFree(data);
      fdebugf((stderr, "  %ld types\n", count));
    }

  /* We only accept filenames (MIME type "text/uri-list"). */
  {
    int i;
    for (i= 0;  xdndInTypes[i];  ++i)
      {
	fdebugf((stderr, "  type %d == %ld %s\n", i, xdndInTypes[i], XGetAtomName(stDisplay, xdndInTypes[i])));
	if (XdndTextUriList == xdndInTypes[i])
	  {
	    isUrlList= 1;
	    xdndWillAccept= 1;
	  }
      }
  }
  xdndWillAccept= 1;
}

static void dndSendStatus(int willAccept, Atom action)
{
  XClientMessageEvent evt;
  memset(&evt, 0, sizeof(evt));

  evt.type	   = ClientMessage;
  evt.display	   = stDisplay;
  evt.window	   = xdndSourceWindow;
  evt.message_type = XdndStatus;
  evt.format	   = 32;

  xdndStatus_targetWindow(&evt)= DndWindow;
  xdndStatus_setWillAccept(&evt, willAccept);
  xdndStatus_setWantPosition(&evt, 0);
  xdndStatus_action(&evt)= action;

  XSendEvent(stDisplay, xdndSourceWindow, 0, 0, (XEvent *)&evt);

  /* fdebugf((stderr, "  sent status to 0x%lx willAccept=%d data=%ld action=%s(%ld)\n",
             xdndSourceWindow, willAccept, evt.data.l[1], XGetAtomName(stDisplay, action), action)); */
}

static void dndSendFinished(void)
{
    XClientMessageEvent evt;
    memset(&evt, 0, sizeof(evt));

    evt.type	     = ClientMessage;
    evt.display	     = stDisplay;
    evt.window	     = xdndSourceWindow;
    evt.message_type = XdndFinished;
    evt.format	     = 32;

    xdndFinished_targetWindow(&evt)= DndWindow;
    XSendEvent(stDisplay, xdndSourceWindow, 0, 0, (XEvent *)&evt);

    fdebugf((stderr, "dndSendFinished target: 0x%lx source: 0x%lx\n", DndWindow, xdndSourceWindow));
}


static enum XdndState dndInEnter(enum XdndState state, XClientMessageEvent *evt)
{
  fdebugf((stderr, "Receive XdndEnter (input)\n"));
  if (xdndEnter_version(evt) < 3)
    {
      fprintf(stderr, "  xdnd: protocol version %ld not supported\n", xdndEnter_version(evt));
      return state;
    }
  xdndSourceWindow= xdndEnter_sourceWindow(evt);
  dndGetTypeList(evt);

  fdebugf((stderr, "  dndEnter target: 0x%lx source: 0x%lx\n", evt->window, xdndSourceWindow));
  return XdndStateEntered;
}


static enum XdndState dndInLeave(enum XdndState state)
{
  fdebugf((stderr, "Receive XdndLeave (input)\n"));
  recordDragEvent(DragLeave, 1);
  return XdndStateIdle;
}


static enum XdndState dndInPosition(enum XdndState state, XClientMessageEvent *evt)
{
  /*fdebugf((stderr, "Receive XdndPosition (input)\n"));*/

  if (xdndSourceWindow != xdndPosition_sourceWindow(evt))
    {
      fdebugf((stderr, "dndInPosition: wrong source window\n"));
      return XdndStateIdle;
    }

  getMousePosition();

  if ((state != XdndStateEntered) && (state != XdndStateTracking))
    {
      fdebugf((stderr, "dndInPosition: wrong state\n"));
      return XdndStateIdle;
    }
  
  if ((state == XdndStateEntered) && xdndWillAccept)
    recordDragEvent(DragEnter, 1);
  
  if (xdndWillAccept)
    {
      Atom action= xdndPosition_action(evt);
      /*fdebugf((stderr, "  dndInPosition: action = %ld %s\n", action, XGetAtomName(stDisplay, action)));*/
      xdndWillAccept= (action == XdndActionMove) | (action == XdndActionCopy)
	|             (action == XdndActionLink) | (action == XdndActionAsk);
    }

  if (xdndWillAccept)
    {
      /*fdebugf((stderr, "  dndInPosition: accepting\n"));*/
      dndSendStatus(1, XdndActionCopy);
      recordDragEvent(DragMove, 1);
    }
  else /* won't accept */
    {
      /*fdebugf((stderr, "  dndInPosition: not accepting\n"));*/
      dndSendStatus(0, XdndActionPrivate);
    }
  return XdndStateTracking;
}


enum XdndState dndInDrop(enum XdndState state, XClientMessageEvent *evt)
{
  fdebugf((stderr, "Receive XdndDrop (input)\n"));

  /* If there is "text/url-list" in xdndInTypes, the selection is
   * processed only in DropFilesEvent. But if none (file count == 0),
   * the selection is handled ClipboardExtendedPlugin.
   */
  if (isUrlList == 0)
    {
      fdebugf((stderr, "  dndInDrop: no url list\n"));
      recordDragEvent(DragDrop, 0);
      return state;
    }
  dndInDestroyTypes();

  if (xdndSourceWindow != xdndDrop_sourceWindow(evt))
    {
      fdebugf((stderr, "  dndInDrop: wrong source window\n"));
    }
  else if (xdndWillAccept)
    {
      Window owner;
      fdebugf((stderr, "  dndInDrop: converting selection\n"));
      if (!(owner= XGetSelectionOwner(stDisplay, XdndSelection)))
	fprintf(stderr, "  dndInDrop: XGetSelectionOwner failed\n");
      else
	XConvertSelection(stDisplay, XdndSelection, XdndTextUriList, XdndSelectionAtom, stWindow, xdndDrop_time(evt));
      if (uxDropFileCount)
	{
	  int i;
	  assert(uxDropFileNames);
	  for (i= 0;  i < uxDropFileCount;  ++i)
	    free(uxDropFileNames[i]);
	  free(uxDropFileNames);
	  uxDropFileCount= 0;
	  uxDropFileNames= 0;
	}
    }
  else
    {
      fdebugf((stderr, "  dndInDrop: refusing selection -- finishing\n"));
    }

  dndSendFinished();
  recordDragEvent(DragLeave, 1);

  return XdndStateIdle;
}


static void dndGetSelection(Window owner, Atom property)
{
  unsigned long remaining;
  unsigned char *data= 0;
  Atom actual;
  int format;
  unsigned long count;

  if (Success != XGetWindowProperty(stDisplay, owner, property, 0, 65536, 1, AnyPropertyType,
				    &actual, &format, &count, &remaining, &data))
    fprintf(stderr, "dndGetSelection: XGetWindowProperty failed\n");
  else if (remaining)
    /* a little violent perhaps */
    fprintf(stderr, "dndGetSelection: XGetWindowProperty has more than 64K (why?)\n");
  else
    {
      char *tokens= (char *)data;
      char *item= 0;
      while ((item= strtok(tokens, "\n\r")))
	{
	  fdebugf((stderr, "  got URI <%s>\n", item));
	  if (!strncmp(item, "file:", 5))		/*** xxx BOGUS -- just while image is broken ***/
	    {
	      if (uxDropFileCount)
		uxDropFileNames= (char **)xrealloc(uxDropFileNames, (uxDropFileCount + 1) * sizeof(char *));
	      else
		uxDropFileNames= (char **)xcalloc(1, sizeof(char *));
	      uxDropFileNames[uxDropFileCount++]= uri2string(item);
	    }
	  tokens= 0;
	}
      if (uxDropFileCount)
	recordDragEvent(DragDrop, uxDropFileCount);
      fdebugf((stderr, "  uxDropFileCount = %d\n", uxDropFileCount));
    }
  XFree(data);
}


static enum XdndState dndInSelectionNotify(enum XdndState state, XSelectionEvent *evt)
{
  fdebugf((stderr, "Receive SelectionNotify (input)\n"));
  if (evt->property != XdndSelectionAtom) return state;

  dndGetSelection(evt->requestor, evt->property);
  dndSendFinished();
  recordDragEvent(DragLeave, 1);
  return XdndStateIdle;
}


static enum XdndState dndInFinished(enum XdndState state)
{
  fdebugf((stderr, "Internal signal DndInFinished (input)\n"));
  dndSendFinished();
  recordDragEvent(DragLeave, 1);
  dndInDestroyTypes();
  return XdndStateIdle;
}


/* DnD client event handler */

static enum XdndState dndHandleClientMessage(enum XdndState state, XClientMessageEvent *evt)
{
  Atom type= evt->message_type;
  if      (type == XdndStatus)   return dndOutStatus(state, evt);
  else if (type == XdndFinished) return dndOutFinished(state, evt);
  else if (type == XdndEnter)	 return dndInEnter(state, evt);
  else if (type == XdndPosition) return dndInPosition(state, evt);
  else if (type == XdndDrop)	 return dndInDrop(state, evt);
  else if (type == XdndLeave)	 return dndInLeave(state);
  else                           return state;
}


/* DnD event handler */

static void dndHandleEvent(int type, XEvent *evt)
{
  static enum XdndState state= XdndStateIdle;

  switch(type)
    {
    case DndOutStart:	   state= dndOutInitialize(state);					break;
    case MotionNotify:	   state= dndOutMotion(state, &evt->xmotion);				break;
    case ButtonRelease:	   state= dndOutRelease(state, &evt->xbutton);				break;
    case SelectionRequest: state= dndOutSelectionRequest(state, &evt->xselectionrequest);	break;
    case SelectionNotify:  state= dndInSelectionNotify(state, &evt->xselection);		break;
    case DndInFinished:	   state= dndInFinished(state);						break;
    case ClientMessage:	   state= dndHandleClientMessage(state, &evt->xclient);			break;
    }
}


static sqInt display_dndOutStart(char *types, int ntypes)
{
  int pos, i;
  int typesSize= 0;

  if (xdndOutTypes != 0)
    {
      free(xdndOutTypes);
      xdndOutTypes= 0;
    }

  for (pos= 0; pos < ntypes; pos += strlen(types + pos) + 1)
    typesSize++;

  if (typesSize > 3) return 0; /* Supported types are up to 3 now */

  xdndOutTypes= xmalloc(sizeof(Atom) * (typesSize + 1));
  xdndOutTypes[typesSize]= None;

  for (pos= 0, i= 0; pos < ntypes; pos += strlen(types + pos) + 1, i++)
    xdndOutTypes[i]= XInternAtom(stDisplay, types + pos, False);

  for (i= 0; i < typesSize; i++)
    fdebugf((stderr, "dndOutStart: %s\n", XGetAtomName(stDisplay, xdndOutTypes[i])));
  dndHandleEvent(DndOutStart, 0);

  return 1;
}

static void display_dndOutSend (char *bytes, int nbytes)
{
  XEvent notify;
  XSelectionEvent *res= &notify.xselection;
  Atom targetProperty= ((None == xdndOutRequestEvent.property)
			? xdndOutRequestEvent.target
			: xdndOutRequestEvent.property);

  res->type	  = SelectionNotify;
  res->display	  = xdndOutRequestEvent.display;
  res->requestor  = xdndOutRequestEvent.requestor;
  res->selection  = xdndOutRequestEvent.selection;
  res->target	  = xdndOutRequestEvent.target;
  res->time	  = xdndOutRequestEvent.time;
  res->send_event = True;
  res->property	  = targetProperty; /* override later if error */

  XChangeProperty(stDisplay, res->requestor,
		  targetProperty, xdndOutRequestEvent.target,
		  8, PropModeReplace,
		  (unsigned char *)bytes,
		  nbytes);

  XSendEvent(stDisplay, res->requestor, False, 0, &notify);
  fdebugf((stderr, "Send data for %s (output) requestor: 0x%lx\n",
           XGetAtomName(stDisplay, res->target), res->requestor));
}

static sqInt display_dndOutAcceptedType(char * buf, int nbuf)
{
  char *type;
  if (xdndOutRequestEvent.target == None) return 0;
  type= XGetAtomName(stDisplay, xdndOutRequestEvent.target);
  strncpy(buf, type, nbuf);
  XFree(type);
  return 1;
}

static void dndInitialise(void)
{
  XdndAware=		 XInternAtom(stDisplay, "XdndAware", False);
  XdndSelection=	 XInternAtom(stDisplay, "XdndSelection", False);
  XdndEnter=		 XInternAtom(stDisplay, "XdndEnter", False);
  XdndLeave=		 XInternAtom(stDisplay, "XdndLeave", False);
  XdndPosition=		 XInternAtom(stDisplay, "XdndPosition", False);
  XdndDrop=		 XInternAtom(stDisplay, "XdndDrop", False);
  XdndFinished=		 XInternAtom(stDisplay, "XdndFinished", False);
  XdndStatus=		 XInternAtom(stDisplay, "XdndStatus", False);
  XdndActionCopy=	 XInternAtom(stDisplay, "XdndActionCopy", False);
  XdndActionMove=	 XInternAtom(stDisplay, "XdndActionMove", False);
  XdndActionLink=	 XInternAtom(stDisplay, "XdndActionLink", False);
  XdndActionAsk=	 XInternAtom(stDisplay, "XdndActionAsk", False);
  XdndActionPrivate=	 XInternAtom(stDisplay, "XdndActionPrivate", False);
  XdndTypeList=		 XInternAtom(stDisplay, "XdndTypeList", False);
  XdndTextUriList=	 XInternAtom(stDisplay, "text/uri-list", False);
  XdndSelectionAtom=	 XInternAtom(stDisplay, "XdndSqueakSelection", False);

  XChangeProperty(stDisplay, DndWindow, XdndAware, XA_ATOM, 32, PropModeReplace, (unsigned char *)&XdndVersion, 1);
}


#if (TEST_XDND)


#define fail(why)	do { fprintf(stderr, "%s\n", why);  exit(1); } while (0)


static void run(void)
{
  for (;;)
    {
      XEvent evt;
      XNextEvent(stDisplay, &evt);
      switch (evt.type)
	{
	case MotionNotify:	printf("MotionNotify\n");			break;
	case EnterNotify:	printf("EnterNotify\n");			break;
	case LeaveNotify:	printf("LeaveNotify\n");			break;
	case ButtonPress:	printf("ButtonPress\n");			break;
	case ButtonRelease:	printf("ButtonRelease\n");			break;
	case KeyPress:		printf("KeyPress\n");				break;
	case KeyRelease:	printf("KeyRelease\n");				break;
	case SelectionClear:	printf("SelectionClear\n");			break;
	case SelectionRequest:	printf("SelectionRequest\n");			break;
	case PropertyNotify:	printf("PropertyNotify\n");			break;
	case Expose:		printf("Expose\n");				break;
	case MapNotify:		printf("MapNotify\n");				break;
	case UnmapNotify:	printf("UnmapNotify\n");			break;
	case ConfigureNotify:	printf("ConfigureNotify\n");			break;
	case MappingNotify:	printf("MappingNotify\n");			break;
	case ClientMessage:	dndHandleClientMessage(&evt.xclient);		break;
	case SelectionNotify:	dndHandleSelectionNotify(&evt.xselection);	break;
	default:		printf("unknown event type %d\n", evt.type);	break;
	}
    }
}


int main(int argc, char **argv)
{
  stDisplay= XOpenDisplay(0);
  if (!stDisplay) fail("cannot open display");

  dndInitialise();

  {
    XSetWindowAttributes attributes;
    unsigned long valuemask= 0;

    attributes.event_mask= ButtonPressMask | ButtonReleaseMask
      |			   KeyPressMask | KeyReleaseMask
      |			   PointerMotionMask
      |			   EnterWindowMask | LeaveWindowMask | ExposureMask;
    valuemask |= CWEventMask;

    win= XCreateWindow(stDisplay, DefaultRootWindow(stDisplay),
		       100, 100, 100, 100,	/* geom */
		       0,			/* border */
		       CopyFromParent,		/* depth */
		       CopyFromParent,		/* class */
		       CopyFromParent,		/* visual */
		       valuemask,
		       &attributes);
  }
  if (!win) fail("cannot create window");

  XChangeProperty (stDisplay, win, XdndAware, XA_ATOM, 32, PropModeReplace, (unsigned char *)&XdndVersion, 3);
  XMapWindow(stDisplay, stWindow);
  run();
  XCloseDisplay(stDisplay);

  return 0;
}


#endif /* TEST_XDND */
