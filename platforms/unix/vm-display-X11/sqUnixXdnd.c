/* sqUnixXdnd.c -- drag-and-drop for the X Window System.	-*- C -*-
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
 */

/* Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * Last edited: 2004-04-04 23:06:38 by piumarta on cartman.inria.fr
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
static	Atom	 *xdndTypeList= 0;
static	int	  xdndWillAccept= 0;

enum XdndState {
  XdndStateIdle,
  XdndStateEntered,
  XdndStateTracking
};

static enum XdndState xdndState= XdndStateIdle;


#define xdndEnter_sourceWindow(evt)		( (evt)->data.l[0])
#define xdndEnter_version(evt)			( (evt)->data.l[1] >> 24)
#define xdndEnter_hasThreeTypes(evt)		(((evt)->data.l[1] & 0x1UL) == 0)
#define xdndEnter_typeAt(evt, idx)		( (evt)->data.l[2 + (idx)])

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
# define dprintf(ARGS) do { fprintf ARGS; } while (0)
#else
# define dprintf(ARGS) do { } while (0)
#endif


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
  dprintf((stderr, "uri2string: <%s>\n", string));
  return string;
}


static void dndGetTypeList(XClientMessageEvent *evt)
{
  if (xdndTypeList)
    {
      free(xdndTypeList);
      xdndTypeList= 0;
    }

  xdndWillAccept= 0;

  if (xdndEnter_hasThreeTypes(evt))
    {
      int i;
      dprintf((stderr, "  3 types\n"));
      xdndTypeList= (Atom *)xcalloc(3 + 1, sizeof(Atom));
      for (i= 0;  i <  3;  ++i)
	xdndTypeList[i]= xdndEnter_typeAt(evt, i);
      xdndTypeList[3]= 0;
    }
  else
    {
      Atom type, *atoms;
      int format;
      unsigned long i, count, remaining;
      unsigned char *data= 0;

      XGetWindowProperty(stDisplay, xdndSourceWindow, XdndTypeList, 0, 0x8000000L, False, XA_ATOM,
			 &type, &format, &count, &remaining, &data);

      if ((type != XA_ATOM) || (format != 32) || (count == 0) || !data)
	{
	  if (data) XFree(data);
	  fprintf(stderr, "XGetWindowProperty failed in xdndGetTypeList\n");
	  return;
	}

      xdndTypeList= (Atom *)xcalloc(count + 1, sizeof(Atom));
      atoms= (Atom *)data;
      for (i= 0;  i < count;  ++i)
	xdndTypeList[i]= atoms[i];
      xdndTypeList[count]= 0;
      XFree(data);
      dprintf((stderr, "  %ld types\n", count));
    }

  /* We only accept filenames (MIME type "text/uri-list"). */
  {
    int i;
    for (i= 0;  xdndTypeList[i];  ++i)
      {
	dprintf((stderr, "  type %d == %ld %s\n", i, xdndTypeList[i], XGetAtomName(stDisplay, xdndTypeList[i])));
	if (XdndTextUriList == xdndTypeList[i])
	  xdndWillAccept= 1;
      }
  }
}


static void dndSendStatus(Window target, int willAccept, Atom action)
{
  XClientMessageEvent evt;
  memset(&evt, 0, sizeof(evt));

  evt.type	   = ClientMessage;
  evt.display	   = stDisplay;
  evt.window	   = xdndSourceWindow;
  evt.message_type = XdndStatus;
  evt.format	   = 32;

  xdndStatus_targetWindow(&evt)= target;
  xdndStatus_setWillAccept(&evt, willAccept);
  xdndStatus_setWantPosition(&evt, 0);
  xdndStatus_action(&evt)= action;

  XSendEvent(stDisplay, xdndSourceWindow, 0, 0, (XEvent *)&evt);

  dprintf((stderr, "sent status to %ld will accept %d data %ld action %ld %s\n",
	   xdndSourceWindow, willAccept, evt.data.l[1], action, XGetAtomName(stDisplay, action)));
}


static void dndSendFinished(Window target)
{
    XClientMessageEvent evt;
    memset (&evt, 0, sizeof(evt));

    evt.type	     = ClientMessage;
    evt.display	     = stDisplay;
    evt.window	     = xdndSourceWindow;
    evt.message_type = XdndFinished;
    evt.format	     = 32;

    xdndFinished_targetWindow(&evt)= target;

    XSendEvent(stDisplay, xdndSourceWindow, 0, 0, (XEvent *)&evt);

    dprintf((stderr, "sent finished to %ld\n", xdndSourceWindow));
}


static void dndEnter(XClientMessageEvent *evt)
{
  dprintf((stderr, "dndEnter\n"));
  if (xdndEnter_version(evt) < 3)
    {
      fprintf(stderr, "xdnd: protocol version %ld not supported\n", xdndEnter_version(evt));
      return;
    }
  xdndSourceWindow= xdndEnter_sourceWindow(evt);
  dndGetTypeList(evt);
  xdndState= XdndStateEntered;
}


static void dndLeave(XClientMessageEvent *evt)
{
  dprintf((stderr, "dndLeave\n"));
  recordDragEvent(DragLeave, 1);
  xdndState= XdndStateIdle;
}


static void dndPosition(XClientMessageEvent *evt)
{
  dprintf((stderr, "dndPosition\n"));

  if (xdndSourceWindow != xdndPosition_sourceWindow(evt))
    {
      dprintf((stderr, "dndPosition: wrong source window\n"));
      return;
    }

  {
    Window root;
    unsigned int x, y, w, h, b, d;
    XGetGeometry(stDisplay, stWindow, &root, &x, &y, &w, &h, &b, &d);
    mousePosition.x= xdndPosition_rootX(evt) - x;
    mousePosition.y= xdndPosition_rootY(evt) - y;
  }

  if (xdndState == XdndStateEntered)
    {
      if (xdndWillAccept)
	recordDragEvent(DragEnter, 1);
      xdndState= XdndStateTracking;
    }

  if (xdndState != XdndStateTracking)
    {
      dprintf((stderr, "dndPosition: wrong state\n"));
      return;
    }

  if (xdndWillAccept)
    {
      Atom action= xdndPosition_action(evt);
      dprintf((stderr, "  action = %ld %s\n", action, XGetAtomName(stDisplay, action)));
      xdndWillAccept= (action == XdndActionMove) | (action == XdndActionCopy)
	|             (action == XdndActionLink) | (action == XdndActionAsk);
    }

  if (xdndWillAccept)
    {
      dprintf((stderr, "accepting\n"));
      dndSendStatus(evt->window, 1, XdndActionCopy);
      recordDragEvent(DragMove, 1);
    }
  else /* won't accept */
    {
      dprintf((stderr, "not accepting\n"));
      dndSendStatus(evt->window, 0, XdndActionPrivate);
    }
}


static void dndDrop(XClientMessageEvent *evt)
{
  dprintf((stderr, "dndDrop\n"));

  if (xdndSourceWindow != xdndDrop_sourceWindow(evt))
    dprintf((stderr, "dndDrop: wrong source window\n"));
  else if (xdndWillAccept)
    {
      Window owner;
      dprintf((stderr, "converting selection\n"));
      if (!(owner= XGetSelectionOwner(stDisplay, XdndSelection)))
	fprintf(stderr, "dndDrop: XGetSelectionOwner failed\n");
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
    dprintf((stderr, "refusing selection -- finishing\n"));

  dndSendFinished(evt->window);
  dndLeave(evt);

  xdndState= XdndStateIdle;
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
      char *tokens= data;
      char *item= 0;
      while ((item= strtok(tokens, "\n\r")))
	{
	  dprintf((stderr, "got URI <%s>\n", item));
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
      dprintf((stderr, "+++ DROP %d\n", uxDropFileCount));
    }
  XFree(data);
}


int dndHandleSelectionNotify(XSelectionEvent *evt)
{
  if (evt->property == XdndSelectionAtom)
    {
      dndGetSelection(evt->requestor, evt->property);
      dndSendFinished(evt->requestor);
      dndLeave((XClientMessageEvent *)evt);
      return 1;
    }
  return 0;
}


int dndHandleClientMessage(XClientMessageEvent *evt)
{
  int handled= 1;
  Atom type= evt->message_type;
  if      (type == XdndEnter)	 dndEnter(evt);
  else if (type == XdndPosition) dndPosition(evt);
  else if (type == XdndDrop)	 dndDrop(evt);
  else if (type == XdndLeave)	 dndLeave(evt);
  else				 handled= 0;
  return handled;
}


void dndInitialise(void)
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

  XChangeProperty(stDisplay, stParent, XdndAware, XA_ATOM, 32, PropModeReplace, (unsigned char *)&XdndVersion, 1);
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


int main()
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
		       100, 100, 100, 100,	// geom
		       0,			// border
		       CopyFromParent,		// depth
		       CopyFromParent,		// class
		       CopyFromParent,		// visual
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
