/* sqUnixX11.c -- support for display via the X Window System.
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
 * Last edited: 2006-04-18 16:46:44 by piumarta on margaux.local
 *
 * Support for more intelligent CLIPBOARD selection handling contributed by:
 *	Ned Konz <ned@bike-nomad.com>
 * 
 * Support for displays deeper than 8 bits contributed by: Kazuki YASUMATSU
 *	<kyasu@crl.fujixerox.co.jp> <Kazuki.Yasumatsu@fujixerox.co.jp>
 *
 * Support for cursor and keypad editing keys based on code contributed by:
 *	Stefan Matthias Aust <sma@kiel.netsurf.de>
 *
 * Support for intelligent visual class selection contributed by:
 *	Bill Cattey <wdc@MIT.EDU>
 *
 * Support for European accented characters in selections, and
 * Support for displays shallower than 8 bits contributed, and
 * Support for browser plugins, and
 * Support for accelerated OpenGL contributed by:
 *	Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>
 *
 * Support for 24bpp TrueColour X display devices contributed by:
 *	Tim Rowledge <tim@sumeru.stanford.edu>
 *
 * Support for OSProcess plugin contributed by:
 *	Dave Lewis <lewis@mail.msen.com> Mon Oct 18 20:36:54 EDT 1999
 */

#include "sq.h"
#include "sqMemoryAccess.h"

#include "sqUnixMain.h"
#include "sqUnixGlobals.h"
#include "sqUnixCharConv.h"
#include "sqaio.h"

#undef HAVE_OPENGL_GL_H		/* don't include Quartz OpenGL if configured */
#include "SqDisplay.h"

#if defined(ioMSecs)
# undef ioMSecs
#endif

#define NO_ICON
#define PRINT_PS_FORMS
#define SQ_FORM_FILENAME	"squeak-form.ppm"
#undef	FULL_UPDATE_ON_EXPOSE

#undef	DEBUG_CONV
#undef	DEBUG_EVENTS
#undef	DEBUG_SELECTIONS
#undef	DEBUG_BROWSER
#undef	DEBUG_WINDOW

#if defined(HAVE_LIBXEXT)
# define USE_XSHM
#endif

#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/param.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <locale.h>

#if defined(HAVE_SYS_SELECT_H)
# include <sys/select.h>
#endif

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#define XK_MISCELLANY
#define XK_XKB_KEYS
#include <X11/keysymdef.h>
#if defined(USE_XSHM)
#  include <sys/ipc.h>
#  include <sys/shm.h>
#  include <X11/extensions/XShm.h>
#endif
#if !defined(NO_ICON)
#  include "squeakIcon.bitmap"
#endif

#if defined(HAVE_LIBDL)
# include <dlfcn.h>
# if !defined(NDEBUG)
#   define NDEBUG
# endif
# include <assert.h>
#endif

#define isAligned(T, V)	(((V) % sizeof(T)) == 0)
#define align(T, V)	(((V) / sizeof(T)) * sizeof(T))

#if defined(SQ_IMAGE32)
# define BytesPerOop	4
#elif defined(SQ_IMAGE64)
# define BytesPerOop	8
#else
# error cannot determine image word size
#endif

#define BaseHeaderSize	BytesPerOop

/*** Variables -- Imported from Virtual Machine ***/

/*** Variables -- X11 Related ***/

/* name of Squeak windows in Xrm and the WM */
#define xResClass	"Squeak"
#define xResName	"squeak"

char		*displayName= 0;	/* name of display, or 0 for $DISPLAY */
Display		*stDisplay= null;	/* Squeak display */
int		 isConnectedToXServer=0;/* True when connected to an X server */
int		 stXfd= -1;		/* X connection file descriptor */
Window		 stParent= null;	/* Squeak parent window */
Window		 stWindow= null;	/* Squeak window */
int		 stWidth= 0;
int		 stHeight= 0;
int		 xWidth= 0;
int		 xHeight= 0;
Visual		*stVisual;		/* the default visual */
GC		 stGC;			/* graphics context used for rendering */
Colormap	 stColormap= null;	/* Squeak color map */
int		 scrW= 0;
int		 scrH= 0;
XImage		*stImage= 0;		/* ...and it's client-side pixmap */
char		*stEmptySelection= "";	/* immutable "empty string" value */
char		*stPrimarySelection;	/* buffer holding selection */
int		 stPrimarySelectionSize;/* size of buffer holding selection */
int		 stOwnsSelection= 0;	/* true if we own the X selection */
int		 stOwnsClipboard= 0;	/* true if we own the X clipboard */
int		 usePrimaryFirst= 0;	/* true if we should look to PRIMARY before CLIPBOARD */
Time		 stSelectionTime;	/* Time of setting the selection */
XColor		 stColorBlack;		/* black pixel value in stColormap */
XColor		 stColorWhite;		/* white pixel value in stColormap */
int		 savedWindowOrigin= -1;	/* initial origin of window */

#define		 SELECTION_ATOM_COUNT  8
/* http://www.freedesktop.org/standards/clipboards-spec/clipboards.txt */
Atom		 selectionAtoms[SELECTION_ATOM_COUNT];
char		*selectionAtomNames[SELECTION_ATOM_COUNT]= {
         "CLIPBOARD",
#define xaClipboard	selectionAtoms[0]
	 "CUT_BUFFER0",
#define xaCutBuffer0	selectionAtoms[1]
	 "TARGETS",
#define xaTargets	selectionAtoms[2]
	 "MULTIPLE",
#define xaMultiple	selectionAtoms[3]
	 "UTF8_STRING",
#define xaUTF8String	selectionAtoms[4]
	 "COMPOUND_TEXT",
#define xaCompoundText	selectionAtoms[5]
	 "TIMESTAMP",
#define xaTimestamp     selectionAtoms[6]
	 "SQUEAK_SELECTION",		/* used for XGetSelectionOwner() data */
#define selectionAtom   selectionAtoms[7]
};

#if defined(USE_XSHM)
XShmSegmentInfo  stShmInfo;		/* shared memory descriptor */
int		 completions= 0;	/* outstanding completion events */
int		 completionType;	/* the type of XShmCompletionEvent */
int		 useXshm= 0;		/* 1 if shared memory is in use */
int		 asyncUpdate= 0;	/* 1 for asynchronous screen updates */
#endif

int		 mapDelBs= 0;		/* 1 to map delete to backspace */
int		 optMapIndex= 0;	/* Option key modifier map index */
int		 cmdMapIndex= 0;	/* Command key modifier map index */
int		 stDepth= 0;
int		 stBitsPerPixel= 0;
unsigned int	 stColors[256];
unsigned int	 stDownGradingColors[256];
int		 stHasSameRGBMask16;
int		 stHasSameRGBMask32;
int		 stRNMask, stGNMask, stBNMask;
int		 stRShift, stGShift, stBShift;
char		*stDisplayBitmap= 0;
Window           browserWindow= 0;      /* parent window */
int		 browserPipes[]= {-1, -1}; /* read/write fd for browser communication */
int		 headless= 0;

int		 useXdnd= 1;		/* true if we should handle XDND protocol messages */

typedef int (*x2sqKey_t)(XKeyEvent *xevt);

static int x2sqKeyPlain(XKeyEvent *xevt);
static int x2sqKeyInput(XKeyEvent *xevt);

static x2sqKey_t x2sqKey= x2sqKeyPlain;

#define inBrowser()	(-1 != browserPipes[0])

/* window states */

#define WIN_NORMAL	0
#define WIN_CHANGED	1
#define WIN_ZOOMED	2

int windowState= WIN_CHANGED;

#define noteWindowChange()			\
  {						\
    if (windowState == WIN_NORMAL)		\
      windowState= WIN_CHANGED;			\
  }

#include "sqUnixEvent.c"

#define SqueakWhite	0
#define SqueakBlack	1

int sleepWhenUnmapped=	0;
int noTitle=		0;
int fullScreen=		0;
int iconified=		0;
int withSpy=		0;


/*xxx REMOVE REFS TO THESE IN sqUnixSound*.* */

void feedback(int offset, int pixel)	{}
int inModalLoop= 0, dpyPitch= 0, dpyPixels= 0;

/* we are interested in these events...
 */
#define	EVENTMASK	ButtonPressMask | ButtonReleaseMask | \
			KeyPressMask | KeyReleaseMask | PointerMotionMask | \
			ExposureMask

#define	WM_EVENTMASK	StructureNotifyMask

/* largest X selection that we will attempt to handle (bytes) */
#define MAX_SELECTION_SIZE	100*1024

/* longest we're prepared to wait for the selection owner to convert it (seconds) */
#define SELECTION_TIMEOUT	3



/*** Functions ***/

static void xHandler(int fd, void *data, int flags);
static void npHandler(int fd, void *data, int flags);
static void handleEvent(XEvent *event);
static int  handleEvents(void);
static void waitForCompletions(void);
static Time getXTimestamp(void);
static void claimSelection(void);

#if defined(DEBUG_SELECTIONS)
static void printAtomName(Atom atom);
#endif

void setWindowSize(void);
void getMaskbit(unsigned long ul, int *nmask, int *shift);

void initDownGradingColors(void);

void copyReverseImageBytes(int *fromImageData, int *toImageData, int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB);

void copyReverseImageWords(int *fromImageData, int *toImageData, int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB);

#define declareCopyFunction(NAME) \
  void NAME (int *fromImageData, int *toImageData, int width, int height, \
	     int affectedL, int affectedT, int affectedR, int affectedB)

declareCopyFunction(copyImage1To8);
declareCopyFunction(copyImage1To16);
declareCopyFunction(copyImage1To24);
declareCopyFunction(copyImage1To32);

declareCopyFunction(copyImage2To8);
declareCopyFunction(copyImage2To16);
declareCopyFunction(copyImage2To24);
declareCopyFunction(copyImage2To32);

declareCopyFunction(copyImage4To8);
declareCopyFunction(copyImage4To16);
declareCopyFunction(copyImage4To24);
declareCopyFunction(copyImage4To32);

declareCopyFunction(copyImage8To8);
declareCopyFunction(copyImage8To16);
declareCopyFunction(copyImage8To24);
declareCopyFunction(copyImage8To32);

declareCopyFunction(copyImage16To8);
declareCopyFunction(copyImage16To16);
declareCopyFunction(copyImage16To24);
declareCopyFunction(copyImage16To32);

declareCopyFunction(copyImage32To8);
declareCopyFunction(copyImage32To16);
declareCopyFunction(copyImage32To24);
declareCopyFunction(copyImage32To32);
declareCopyFunction(copyImage32To32Same);

#undef declareCopyFunction

static void  redrawDisplay(int l, int r, int t, int b);

static int   sendSelection(XSelectionRequestEvent *requestEv, int isMultiple);
static char *getSelection(void);
static char *getSelectionFrom(Atom source);
static int   translateCode(KeySym symbolic);

#if defined(USE_XSHM)
int    XShmGetEventBase(Display *);
#endif
void   browserProcessCommand(void);       /* see sqUnixMozilla.c */


static inline int min(int x, int y) { return (x < y) ? x : y; }


#if 0

/* Conversion table from X to Squeak (reversible) */

static unsigned char X_to_Squeak[256] =
{
  0,   1,   2,   3,   4,   5,   6,   7,       /*   0 -   7 */
  8,   9,   13,  11,  12,  10,  14,  15,      /*   8 -  15 */
  16,  17,  18,  19,  20,  21,  22,  23,      /*  16 -  23 */
  24,  25,  26,  27,  28,  29,  30,  31,      /*  24 -  31 */
  32,  33,  34,  35,  36,  37,  38,  39,      /*  32 -  39 */
  40,  41,  42,  43,  44,  45,  46,  47,      /*  40 -  47 */
  48,  49,  50,  51,  52,  53,  54,  55,      /*  48 -  55 */
  56,  57,  58,  59,  60,  61,  62,  63,      /*  56 -  63 */
  64,  65,  66,  67,  68,  69,  70,  71,      /*  64 -  71 */
  72,  73,  74,  75,  76,  77,  78,  79,      /*  72 -  79 */
  80,  81,  82,  83,  84,  85,  86,  87,      /*  80 -  87 */
  88,  89,  90,  91,  92,  93,  94,  95,      /*  88 -  95 */
  96,  97,  98,  99, 100, 101, 102, 103,      /*  96 - 103 */
  104, 105, 106, 107, 108, 109, 110, 111,     /* 104 - 111 */
  112, 113, 114, 115, 116, 117, 118, 119,     /* 112 - 119 */
  120, 121, 122, 123, 124, 125, 126, 127,     /* 120 - 127 */
  196, 197, 165, 201, 209, 247, 220, 225,     /* 128 - 135 */
  224, 226, 228, 227, 198, 176, 170, 248,     /* 136 - 143 */
  213, 206, 195, 207, 211, 212, 210, 219,     /* 144 - 151 */
  218, 221, 246, 245, 250, 249, 251, 252,     /* 152 - 159 */
  160, 193, 162, 163, 223, 180, 182, 164,     /* 160 - 167 */
  172, 169, 187, 199, 194, 173, 168, 255,     /* 168 - 175 */
  161, 177, 178, 179, 171, 181, 166, 183,     /* 176 - 183 */
  184, 185, 188, 200, 186, 189, 202, 192,     /* 184 - 191 */
  203, 231, 229, 204, 128, 129, 174, 130,     /* 192 - 199 */
  233, 131, 230, 232, 237, 234, 235, 236,     /* 200 - 207 */
  208, 132, 241, 238, 239, 205, 133, 215,     /* 208 - 215 */
  175, 244, 242, 243, 134, 217, 222, 167,     /* 216 - 223 */
  136, 135, 137, 139, 138, 140, 190, 141,     /* 224 - 231 */
  143, 142, 144, 145, 147, 146, 148, 149,     /* 232 - 239 */
  240, 150, 152, 151, 153, 155, 154, 214,     /* 240 - 247 */
  191, 157, 156, 158, 159, 253, 254, 216,     /* 248 - 255 */
};

unsigned char Squeak_to_X[256];

void initCharmap(void)
{
  int i;
  for(i= 0; i < 256; i++)
    Squeak_to_X[X_to_Squeak[i]]= i;
}

void st2ux(unsigned char *string)
{
  if (!string) return;
  while (*string)
    {
     *string= Squeak_to_X[*string];
      string++;
    }
}

void ux2st(unsigned char *string)
{
  if (!string) return;
  while (*string)
    {
      *string= X_to_Squeak[*string];
      string++;
    }
}

#endif

/*** X-related Functions ***/

/* Called prior to forking a squeak session.
 */
int synchronizeXDisplay(void)
{
  if (isConnectedToXServer)
    XSync(stDisplay, False);
  return 0;
}

static Bool timestampPredicate(Display *dpy, XEvent *evt, XPointer arg)
{
  return ((  (PropertyNotify   == evt->type))
	  && (stWindow         == evt->xproperty.window)
	  && (xaTimestamp      == evt->xproperty.atom)
	  && (PropertyNewValue == evt->xproperty.state))
    ? True : False;
}

/* answer the real current server time */

static Time getXTimestamp(void)
{
  unsigned char dummy;
  XEvent evt;

  XWindowAttributes xwa;
  XGetWindowAttributes(stDisplay, stWindow, &xwa);
  XSelectInput(stDisplay, stWindow, xwa.your_event_mask | PropertyChangeMask);
  XChangeProperty(stDisplay, stWindow, xaTimestamp, XA_INTEGER, 8, PropModeAppend, &dummy, 0);
  XIfEvent(stDisplay, &evt, timestampPredicate, 0);
  XSelectInput(stDisplay, stWindow, xwa.your_event_mask);
  return evt.xproperty.time;
}


#if 0
static char *debugVisual(int x)
{
  switch (x)
    {
    case 0: return "StaticGray";
    case 1: return "GrayScale";
    case 2: return "StaticColor";
    case 3: return "PseudoColor";
    case 4: return "TrueColor";
    case 5: return "DirectColor";
    default: return "Invalid";
    }
}
#endif


static void noteResize(int w, int h)
{
  xWidth= w;
  xHeight= h;
#if defined(USE_XSHM)
  if (asyncUpdate)
    waitForCompletions();
#endif
  noteWindowChange();
}


static int resized(void)
{
  return ((stWidth != xWidth) || (stHeight != xHeight));
}


/*** selection handling ***/


#if defined(DEBUG_SELECTIONS)

static void dumpSelectionData(const char *data, int n, int newline)
{
  if (NULL == data)
    fprintf(stderr, "dumpSelectionData: data is NULL\n");
  else
    {
      for (n= min(30, n);  n > 0;  --n)
	{
	  unsigned char c= (unsigned char)*data++;
	  fprintf(stderr, (0x20 <= c && c <= 0x7e) ? "%c" : "<%02x>", c);
	}
      if (newline)
	fprintf(stderr, "\n");
    }
}

/* this is needed because the atom names must be freed */
static void printAtomName(Atom atom)
{
  if (None == atom)
    {
      fprintf(stderr, "None");
    }
  else
    {
      char *atomName= XGetAtomName(stDisplay, atom);
      fprintf(stderr, "%s", atomName);
      XFree((void *)atomName);
    }
}

#endif


static int allocateSelectionBuffer(int count)
{
  if (count + 1 > stPrimarySelectionSize)
    {
      if (stPrimarySelection != stEmptySelection)
	{
	  free(stPrimarySelection);
	  stPrimarySelection= stEmptySelection;
	  stPrimarySelectionSize= 0;
	}
      if (!(stPrimarySelection= (char *)malloc(count + 1)))
	{
	  fprintf(stderr, "failed to allocate X selection buffer\n");
	  stPrimarySelection= stEmptySelection;
 	  stPrimarySelectionSize= 0;
	  return 0;
	}
      stPrimarySelectionSize= count;
    }
  return 1;
}


/* answers true if selection could be handled */
static int sendSelection(XSelectionRequestEvent *requestEv, int isMultiple)
{
  int xError= 0;
  XSelectionEvent notifyEv;
  Atom targetProperty= ((None == requestEv->property)
			? requestEv->target 
			: requestEv->property);

  notifyEv.property= targetProperty;

#if defined(DEBUG_SELECTIONS)
  fprintf(stderr, "%d selection request sel ", isMultiple);
  printAtomName(requestEv->selection);
  fprintf(stderr, " prop ");
  printAtomName(requestEv->property);
  fprintf(stderr, " target ");
  printAtomName(requestEv->target);
  fprintf(stderr, "\n");
#endif

  if ((XA_STRING == requestEv->target) || (xaUTF8String == requestEv->target))
    {
      int   len= strlen(stPrimarySelection);
      char *buf= (char *)malloc(len * 3 + 1);
      int   n;

#    if defined(DEBUG_SELECTIONS)
      fprintf(stderr, "sendSelection: len=%d, sel=", len);
      dumpSelectionData(stPrimarySelection, len, 1);
#    endif
      if (xaUTF8String == requestEv->target)
        n= sq2uxUTF8(stPrimarySelection, len, buf, len * 3 + 1, 1);
      else
        n= sq2uxText(stPrimarySelection, len, buf, len * 3 + 1, 1);
#    if defined(DEBUG_SELECTIONS)
      fprintf(stderr, "sendSelection: n=%d, buf=", n);
      dumpSelectionData(buf, n, 1);
#    endif
      XChangeProperty(requestEv->display, requestEv->requestor,
		      targetProperty, requestEv->target,
		      8, PropModeReplace, (const unsigned char *)buf, n);
      free(buf);
    }
  else if (xaTargets == requestEv->target)
    {
      /* If we don't report COMPOUND_TEXT in this list, KMail (and maybe other
       * Qt/KDE apps) don't accept pastes from Squeak. Of course, they'll use
       * UTF8_STRING anyway... */
      Atom targets[6];
      targets[0]= xaTargets;
      targets[1]= xaMultiple;
      targets[2]= xaTimestamp;	        /* required by ICCCM */
      targets[3]= xaUTF8String;
      targets[4]= XA_STRING;
      targets[5]= xaCompoundText;

      xError= XChangeProperty(requestEv->display, requestEv->requestor,
                              targetProperty, XA_ATOM,
                              32, PropModeReplace, (unsigned char *)targets, sizeof(targets) / sizeof(Atom));
    }
  else if (xaCompoundText == requestEv->target)
    {
      /* COMPOUND_TEXT is handled here for older clients that don't handle UTF-8 */
      int	    len=    strlen(stPrimarySelection);
      char	   *buf=    (char *)malloc(len * 3 + 1);
      XTextProperty textProperty;
      char	   *list[2];

      list[0]= buf;
      list[1]= NULL;

      /* convert our locale text to CTEXT */
      sq2uxText(stPrimarySelection, len, buf, len * 3 + 1, 1);
      xError= XmbTextListToTextProperty(requestEv->display, list, 1,
                                        XCompoundTextStyle, &textProperty);
      free(buf);

      if (Success == xError)
        {
	  xError= XChangeProperty(requestEv->display, requestEv->requestor,
				  targetProperty, xaCompoundText,
				  8, PropModeReplace, textProperty.value, textProperty.nitems);
          XFree((void *)textProperty.value);
        }
      else
        {
          fprintf(stderr, "XmbTextListToTextProperty returns %d\n", xError);
          notifyEv.property= None;
        }
    }
  else if (xaTimestamp == requestEv->target)
    {
      xError= XChangeProperty(requestEv->display, requestEv->requestor,
                              targetProperty, XA_INTEGER,
                              32, PropModeReplace, (unsigned char *)&stSelectionTime, 1);
    }
  else if (xaMultiple == requestEv->target)
    {
      /* The ICCCM requires MULTIPLE, but I'm not sure who sends it. */
      if (None == requestEv->property)
	  notifyEv.property= None;	/* illegal request */
      else
	{
	  Atom* multipleAtoms= NULL;
	  int	format;
	  Atom  type;
	  unsigned long numberOfItems, bytesAfter;

	  xError= XGetWindowProperty(requestEv->display,
				      requestEv->requestor,
				      requestEv->property,
				      0, 100, False,
				      AnyPropertyType,  /* XA_ATOM */
				      &type, &format,
				      &numberOfItems,
				      &bytesAfter,
				      (unsigned char **)&multipleAtoms);
	  if ((xError != Success) || (bytesAfter != 0)
	      || (format != 32) || (type == None))
	    {
	      notifyEv.property= None;
	    }
	  else
	    {
	      unsigned long i;
	      for (i= 0; i < numberOfItems; i+= 2)
		{
		  XSelectionRequestEvent individualRequestEv;

		  memcpy(&individualRequestEv, requestEv, sizeof(XSelectionRequestEvent));
		  individualRequestEv.target= multipleAtoms[i];
		  individualRequestEv.property= multipleAtoms[i+1];
		  if (individualRequestEv.target == None)
		    {
		      multipleAtoms[i+1]= None;
		    }
		  else
		    {
		      /* call this function recursively for each target/property pair */
		      if (!sendSelection(&individualRequestEv, i/2 + 1))
			{
			  multipleAtoms[i+1]= None;
			}
		    }
		}
	    }
	}
    }
  else
    {
      notifyEv.property= None;	/* couldn't handle it */
    }

#if defined(DEBUG_SELECTIONS)
  if (xError == BadAlloc || xError == BadAtom || xError == BadMatch 
      || xError == BadValue || xError == BadWindow)
    fprintf(stderr, "sendSelection: XChangeProperty err %d\n", xError);
#endif

  /* on MULTIPLE requests, we notify only once */
  if (!isMultiple)
    {
      notifyEv.type= SelectionNotify;
      notifyEv.display= requestEv->display;
      notifyEv.requestor= requestEv->requestor;
      notifyEv.selection= requestEv->selection;
      notifyEv.target= requestEv->target;
   /* notifyEv.property set above */
      notifyEv.time= requestEv->time;
      notifyEv.send_event= True;

      XSendEvent(requestEv->display, requestEv->requestor, False, 0, (XEvent *)&notifyEv);
      XFlush(stDisplay);
    }

  return notifyEv.property != None;
}


static char *getSelection(void)
{
  char *data;

  if (stOwnsClipboard)
    {
#    if defined(DEBUG_SELECTIONS)
      fprintf(stderr, "getSelection: returning own selection\n");
#    endif
      return stPrimarySelection;
    }

  if (usePrimaryFirst)
    {
      data= getSelectionFrom(XA_PRIMARY);     /* try PRIMARY first */
      if (stEmptySelection == data)
	data= getSelectionFrom(xaClipboard);  /* then try CLIPBOARD (TODO CUT_BUFFER0?) */
    }
  else
    {
      data= getSelectionFrom(xaClipboard);    /* try clipboard first */
      if (stEmptySelection == data)
	data= getSelectionFrom(XA_PRIMARY);   /* then try PRIMARY */
    }

  return data;
}


static char *getSelectionFrom(Atom source)
{
  XEvent  ev;
  fd_set  fdMask;
  Time	  timestamp= getXTimestamp();

  XDeleteProperty(stDisplay, stWindow, selectionAtom);

  /* request the selection */
  if (textEncodingUTF8)
    XConvertSelection(stDisplay, source, xaUTF8String, selectionAtom, stWindow, timestamp);
  else
    XConvertSelection(stDisplay, source, XA_STRING, selectionAtom, stWindow, timestamp);

  /* wait for selection notification, ignoring (most) other events. */
  FD_ZERO(&fdMask);
  if (stXfd >= 0)
    FD_SET(stXfd, &fdMask);

  do
    {
      if (XPending(stDisplay) == 0)
	{
	  int status;
	  struct timeval timeout= { SELECTION_TIMEOUT, 0 };

	  while (((status= select(FD_SETSIZE, &fdMask, 0, 0, &timeout)) < 0)
		 && (errno == EINTR))
	    ;
	  if (status < 0)
	    {
	      perror("select(stDisplay)");
	      return stEmptySelection;
	    }
	  if (status == 0)
	    {
#	     if defined(DEBUG_SELECTIONS)
	      fprintf(stderr, "getSelection: select() timeout\n");
#	     endif
	      if (isConnectedToXServer)
		XBell(stDisplay, 0);
	      return stEmptySelection;
	    }
	}

      XNextEvent(stDisplay, &ev);
      switch (ev.type)
	{
	case ConfigureNotify:
	  noteResize(ev.xconfigure.width, ev.xconfigure.height);
	  break;

        /* this is necessary so that we can supply our own selection when we
	   are the requestor -- this could (should) be optimised to return the
	   stored selection value instead! */
	case SelectionRequest:
#	 if defined(DEBUG_SELECTIONS)
	  fprintf(stderr, "getSelection: sending own selection\n");
#	 endif
	  sendSelection(&ev.xselectionrequest, 0);
	  break;

#       if defined(USE_XSHM)
	default:
	  if (ev.type == completionType)
	    --completions;
#       endif
	}
    }
  while (ev.type != SelectionNotify);

  /* check if the selection was refused */
  if (None == ev.xselection.property)
    {
#    if defined(DEBUG_SELECTIONS)
      fprintf(stderr, "getSelection: xselection.property == None\n");
#    endif
      if (isConnectedToXServer)
	XBell(stDisplay, 0);
      return stEmptySelection;
    }

  /* get the value of the selection from the containing property */
  {
    Atom	 type;
    int		 format;
    unsigned	 long nitems=0, bytesAfter= 0;
    int		 bytes;
    char	*data= NULL;

    XGetWindowProperty(stDisplay, ev.xselection.requestor, ev.xselection.property,
		       (long)0, (long)(MAX_SELECTION_SIZE/4),
		       True, AnyPropertyType,
		       &type, &format, &nitems, &bytesAfter,
		       (unsigned char **)&data);

#  if defined(DEBUG_SELECTIONS)
    fprintf(stderr, "getprop type ");
    printAtomName(type);
    fprintf(stderr, " format %d nitems %ld bytesAfter %ld\ndata=",
	    format, nitems, bytesAfter);
    dumpSelectionData(data, nitems, 1);
#  endif

    if (bytesAfter > 0)
      XBell(stDisplay, 0);

    /* convert the encoding if necessary */
    bytes= min(nitems, MAX_SELECTION_SIZE - 1) * (format / 8);
    if (bytes && allocateSelectionBuffer(bytes))
      {
	if (xaUTF8String == type)
	  bytes= ux2sqUTF8(data, bytes, stPrimarySelection, bytes + 1, 1);
	else if (XA_STRING == type)
	  bytes= ux2sqText(data, bytes, stPrimarySelection, bytes + 1, 1);
	else
	  {
	    char* atomName;

	    bytes= 0;
	    atomName= XGetAtomName(stDisplay, type);
	    if (atomName != NULL)
	      {
		fprintf(stderr, "selection data is of wrong type (%s)\n", atomName);
		XFree((void *)atomName);
	      }
	  }
      }
    else
      {
#      if defined(DEBUG_SELECTIONS)
	fprintf(stderr, "no bytes\n");
#      endif
      }
#  if defined(DEBUG_SELECTIONS)
    fprintf(stderr, "selection=");
    dumpSelectionData(stPrimarySelection, bytes, 1);
#  endif
    if (data != NULL)
      {
	XFree((void *)data);
      }
  }

  return stPrimarySelection;
}


/* claim ownership of the X selection, providing the given string to requestors */

static void claimSelection(void)
{
  Time selectionTime= getXTimestamp();

  XSetSelectionOwner(stDisplay, XA_PRIMARY, stWindow, selectionTime);
  XSetSelectionOwner(stDisplay, xaClipboard, stWindow, selectionTime);
  stSelectionTime= selectionTime;
  XFlush(stDisplay);
  stOwnsClipboard= (XGetSelectionOwner(stDisplay, xaClipboard) == stWindow);
  stOwnsSelection= (XGetSelectionOwner(stDisplay, XA_PRIMARY) == stWindow);
#if defined(DEBUG_SELECTIONS)
  fprintf(stderr, "claim selection stOwnsClipboard=%d, stOwnsSelection=%d\n",
	  stOwnsClipboard, stOwnsSelection);
#endif
}


void initClipboard(void)
{
  stPrimarySelection= stEmptySelection;
  stPrimarySelectionSize= 0;
  stOwnsSelection= 0;
  stOwnsClipboard= 0;
}


static sqInt display_clipboardSize(void)
{
  return strlen(getSelection());
}


static sqInt display_clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  if (allocateSelectionBuffer(count))
    {
      memcpy((void *)stPrimarySelection, pointerForOop(byteArrayIndex + startIndex), count);
      stPrimarySelection[count]= '\0';
      claimSelection();
    }
  return 0;
}

/* transfer the X selection into the given byte array; optimise local requests */

static sqInt display_clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  int clipSize;
  int selectionSize;

  if (!isConnectedToXServer)
    return 0;
  selectionSize= strlen(getSelection());
  clipSize= min(count, selectionSize);
#if defined(DEBUG_SELECTIONS)
  fprintf(stderr, "clipboard read: %d selectionSize %d\n", count, selectionSize);
#endif
  memcpy(pointerForOop(byteArrayIndex + startIndex), (void *)stPrimarySelection, clipSize);
  return clipSize;
}


/* a modified copy of fullDisplayUpdate() that redraws
   only the damaged parts of the window according to each
   expose event on the queue.
   Note: if the format of Form or Bitmap changes, or if
   the special object index of Display is changed, this
   version of the code WILL FAIL!  Otherwise it is to be
   preferred.
*/
static void redrawDisplay(int l, int r, int t, int b)
{
  extern sqInt displayObject(void);
  extern sqInt lengthOf(sqInt);
  extern sqInt fetchPointerofObject(sqInt, sqInt);

  sqInt displayObj= displayObject();

  if ((((((unsigned)(oopAt(displayObj))) >> 8) & 15) <= 4)
      && ((lengthOf(displayObj)) >= 4))
    {
      sqInt dispBits= fetchPointerofObject(0, displayObj);
      sqInt w= fetchIntegerofObject(1, displayObj);
      sqInt h= fetchIntegerofObject(2, displayObj);
      sqInt d= fetchIntegerofObject(3, displayObj);
      sqInt dispBitsIndex= dispBits + BaseHeaderSize;
      ioShowDisplay(dispBitsIndex, w, h, d, (sqInt)l, (sqInt)r, (sqInt)t, (sqInt)b);
    }
}


static void getMousePosition(void)
{
  Window root, child;
  int rootX, rootY, winX, winY;
  unsigned int mask;
  if (True == XQueryPointer(stDisplay, stWindow, &root, &child,
			    &rootX, &rootY, &winX, &winY, &mask))
    {
      mousePosition.x= winX;
      mousePosition.y= winY;
      /* could update modifiers from mask too, but I can't be bothered... */
    }
}


int recode(int charCode)
{
  if (charCode >= 128)
    {
      unsigned char buf[32];
      unsigned char out[32];
      buf[0]= charCode;
      if (convertChars((char *)buf, 1, uxXWinEncoding,
		       (char *)out, sizeof(out),
		       sqTextEncoding, 0, 1))
	charCode= out[0];
#    if defined(DEBUG_EVENTS)
      fprintf(stderr, "  8-bit: %d=%02x [%c->%c]\n", charCode, charCode,
	      (char *)uxXWinEncoding, (char *)sqTextEncoding);
#    endif
    }
  return charCode;
}


static int x2sqKeyInput(XKeyEvent *xevt)
{
  static int initialised= 0;
  static XIM im= 0;
  static XIC ic= 0;
  static int lastKey= -1;

  if (!initialised)
    {
      initialised= 1;
      if (!setlocale(LC_CTYPE, ""))
	{
	  fprintf(stderr, "setlocale() failed (check values of LC_CTYPE, LANG and LC_ALL)\n");
	  goto revertInput;
	}
      if (!(im= XOpenIM(stDisplay, 0, 0, 0)))
	{
	  fprintf(stderr, "XOpenIM() failed\n");
	  goto revertInput;
	}
      else
	{
	  if (!(ic= XCreateIC(im, XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
			      XNClientWindow, stWindow, 0)))
	    {
	      fprintf(stderr, "XCreateIC() failed\n");
	      goto revertInput;
	    }
	  else
	    {
	      unsigned int mask;
	      XWindowAttributes xwa;
	      XGetWindowAttributes(stDisplay, stWindow, &xwa);
	      XGetICValues(ic, XNFilterEvents, &mask, NULL);
	      mask |= xwa.your_event_mask;
	      XSelectInput(stDisplay, stWindow, mask);
	    }
	}
    }

  if (KeyPress != xevt->type)
    {
      int key= lastKey;
      lastKey= -1;;
      return key;
    }

#if defined(DEBUG_CONV)
  printf("keycode %u\n", xevt->keycode);
#endif

  {
    unsigned char string[128];	/* way too much */
    KeySym symbolic;
    Status status;
    int count= XmbLookupString(ic, (XKeyPressedEvent *)xevt,
			       string, sizeof(string), &symbolic, &status);
    switch (status)
      {
      case XLookupNone:		/* still composing */
#	 if defined(DEBUG_CONV)
	fprintf(stderr, "x2sqKey XLookupNone\n");
#	 endif
	return -1;

      case XLookupChars:
#	 if defined(DEBUG_CONV)
	fprintf(stderr, "x2sqKey XLookupChars count %d\n", count);
#	 endif
      case XLookupBoth:
#	 if defined(DEBUG_CONV)
	fprintf(stderr, "x2sqKey XLookupBoth count %d\n", count);
#	 endif
	lastKey= (count ? recode(string[0]) : -1);
#	 if defined(DEBUG_CONV)
	fprintf(stderr, "x2sqKey == %d\n", lastKey);
#	 endif
	return lastKey;

      case XLookupKeySym:
#	 if defined(DEBUG_CONV)
	fprintf(stderr, "x2sqKey XLookupKeySym\n");
#	 endif
	{
	  int charCode= translateCode(symbolic);
#	   if defined(DEBUG_CONV)
	  printf("SYM %d -> %d\n", symbolic, charCode);
#	   endif
	  if (charCode < 0)
	    return -1;	/* unknown key */
	  if ((charCode == 127) && mapDelBs)
	    charCode= 8;
	  return lastKey= charCode;
	}

      default:
	fprintf(stderr, "this cannot happen\n");
	return lastKey= -1;
      }
    return lastKey= -1;
  }

 revertInput:
  x2sqKey= x2sqKeyPlain;
  return x2sqKey(xevt);
}


static int x2sqKeyPlain(XKeyEvent *xevt)
{
  unsigned char buf[32];
  KeySym symbolic;
  int nConv= XLookupString(xevt, (char *)buf, sizeof(buf), &symbolic, 0);
  int charCode= buf[0];
#if defined(DEBUG_EVENTS)
  fprintf(stderr, "convert keycode %d=%02x -> %d=%02x (keysym %ld)\n",
	 xevt->keycode, xevt->keycode, charCode, charCode, symbolic);
#endif
  if (nConv == 0 && (charCode= translateCode(symbolic)) < 0)
    return -1;	/* unknown key */
  if ((charCode == 127) && mapDelBs)
    charCode= 8;
  if (charCode > 256) /* ALT+?? */
    {
      modifierState= charCode >> 8;
      charCode &= 0xff;
    }
  return recode(charCode);
}


static int x2sqButton(int button)
{
  /* ASSUME: (button >= 1) & (button <= 3) */
  static int rybMap[4]= { 0, RedButtonBit, YellowButtonBit, BlueButtonBit };
  static int rbyMap[4]= { 0, RedButtonBit, BlueButtonBit, YellowButtonBit };
  return (swapBtn ? rbyMap : rybMap)[button];
}

static int x2sqModifier(int state)
{
  int mods= 0;
  if (optMapIndex || cmdMapIndex)
    {
      int shift= 1 & ((state >> ShiftMapIndex) ^ (state >> LockMapIndex));
      int ctrl=  1 & (state >> ControlMapIndex);
      int cmd=   1 & (state >> cmdMapIndex);
      int opt=   1 & (state >> optMapIndex);
      mods= (shift ? ShiftKeyBit   : 0)
	|   (ctrl  ? CtrlKeyBit    : 0)
	|   (cmd   ? CommandKeyBit : 0)
	|   (opt   ? OptionKeyBit  : 0);
#    if defined(DEBUG_EVENTS)
      fprintf(stderr, "X mod %x -> Sq mod %x (extended opt=%d cmd=%d)\n", state, mods,
	      optMapIndex, cmdMapIndex);
#    endif
    }
  else
    {
      enum { _= 0, S= ShiftKeyBit, C= CtrlKeyBit, O= OptionKeyBit, M= CommandKeyBit };
      static char midofiers[32]= {	/* ALT=Cmd, META=ignored, C-ALT=Opt, META=ignored */
	/*              - -       - S       L -       L S */
	/* - - - - */ _|_|_|_,  _|_|_|S,  _|_|_|S,  _|_|_|_,
	/* - - - C */ _|_|C|_,  _|_|C|S,  _|_|C|S,  _|_|C|_,
	/* - - A - */ _|M|_|_,  _|M|_|S,  _|M|_|S,  _|M|_|_,
	/* - - A C */ O|_|_|_,  O|_|_|S,  O|_|_|S,  O|_|_|_,
	/*              - -       - S       L -       L S */
	/* M - - - */ _|M|_|_,  _|M|_|S,  _|M|_|S,  _|M|_|_,
	/* M - - C */ _|M|C|_,  _|M|C|S,  _|M|C|S,  _|M|C|_,
	/* M - A - */ _|M|_|_,  _|M|_|S,  _|M|_|S,  _|M|_|_,
	/* M - A C */ O|_|_|_,  O|M|_|S,  O|M|_|S,  O|M|_|_,
      };
#    if defined(__POWERPC__) || defined(__ppc__)
      mods= midofiers[state & 0x1f];
#    else
      mods= midofiers[state & 0x0f];
#    endif
#    if defined(DEBUG_EVENTS)
      fprintf(stderr, "X mod %x -> Sq mod %x (default)\n", state & 0xf, mods);
#    endif
    }
  return mods;
}

/* wait for pending completion events to arrive */

static void waitForCompletions(void)
{
  while (completions > 0)
    handleEvents();
}


#include "sqUnixXdnd.c"


static void handleEvent(XEvent *evt)
{
#if defined(DEBUG_EVENTS)
  switch (evt->type)
    {
    case ButtonPress:
      fprintf(stderr, "\nX ButtonPress   state 0x%x button %d\n",
	      evt->xbutton.state, evt->xbutton.button);
      break;
    case ButtonRelease:
      fprintf(stderr, "\nX ButtonRelease state 0x%x button %d\n",
	      evt->xbutton.state, evt->xbutton.button);
      break;
    case KeyPress:
      fprintf(stderr, "\nX KeyPress      state 0x%x keycode %d\n",
	      evt->xkey.state, evt->xkey.keycode);
      break;
    case KeyRelease:
      fprintf(stderr, "\nX KeyRelease    state 0x%x keycode %d\n",
	      evt->xkey.state, evt->xkey.keycode);
      break;
    }
#endif

# define noteEventPosition(evt)				\
  {							\
    mousePosition.x= evt.x;				\
    mousePosition.y= evt.y;				\
  }

# define noteEventState(evt)				\
  {							\
    noteEventPosition(evt);				\
    modifierState= x2sqModifier(evt.state);		\
  }

  if (True == XFilterEvent(evt, 0))
    return;

  switch (evt->type)
    {
    case MotionNotify:
      noteEventState(evt->xmotion);
      recordMouseEvent();
      break;

    case ButtonPress:
      noteEventState(evt->xbutton);
      switch (evt->xbutton.button)
	{
	case 1: case 2: case 3:
	  buttonState |= x2sqButton(evt->xbutton.button);
	  recordMouseEvent();
	  break;
	case 4: case 5:	/* mouse wheel */
	  {
	    int keyCode= evt->xbutton.button + 26;	/* up/down */
	    int modifiers= modifierState ^ CtrlKeyBit;
	    recordKeyboardEvent(keyCode, EventKeyDown, modifiers);
	    recordKeyboardEvent(keyCode, EventKeyChar, modifiers);
	    recordKeyboardEvent(keyCode, EventKeyUp,   modifiers);
	  }
	  break;
	default:
	  ioBeep();
	  break;
	}
      break;

    case ButtonRelease:
      noteEventState(evt->xbutton);
      switch (evt->xbutton.button)
	{
	case 1: case 2: case 3:
	  buttonState &= ~x2sqButton(evt->xbutton.button);
	  recordMouseEvent();
	  break;
	case 4: case 5:	/* mouse wheel */
	  break;
	default:
	  ioBeep();
	  break;
	}
      break;

    case KeyPress:
      noteEventState(evt->xkey);
      {
	int keyCode= x2sqKey(&evt->xkey);
	if (keyCode >= 0)
	  {
	    recordKeyboardEvent(keyCode, EventKeyDown, modifierState);
	    recordKeyboardEvent(keyCode, EventKeyChar, modifierState);
	    recordKeystroke(keyCode);			/* DEPRECATED */
	  }
      }
      break;

    case KeyRelease:
      noteEventState(evt->xkey);
      {
	int keyCode;
	if (XPending(stDisplay))
	  {
	    XEvent evt2;
	    XPeekEvent(stDisplay, &evt2);
	    if ((evt2.type == KeyPress) && (evt2.xkey.keycode == evt->xkey.keycode) && ((evt2.xkey.time - evt->xkey.time < 2)))
	      break;
	  }
	keyCode= x2sqKey(&evt->xkey);
	if (keyCode >= 0)
	  recordKeyboardEvent(keyCode, EventKeyUp, modifierState);
      }
      break;

    case SelectionClear:
      if (xaClipboard == evt->xselectionclear.selection)
	{
#	 if defined(DEBUG_SELECTIONS)
	  fprintf(stderr, "SelectionClear(xaClipboard)\n");
#	 endif
	  stOwnsClipboard= 0;
	  stOwnsSelection= 0;   /* clear both CLIPBOARD and PRIMARY */
	  usePrimaryFirst= 0;
	}
      else if (XA_PRIMARY == evt->xselectionclear.selection)
	{
#	 if defined(DEBUG_SELECTIONS)
	  fprintf(stderr, "SelectionClear(XA_PRIMARY)\n");
#	 endif
	  stOwnsSelection= 0;   /* but maintain CLIPBOARD if we have it */
	}
      break;

    case SelectionRequest:
      sendSelection(&evt->xselectionrequest, 0);
      break;

    case PropertyNotify:
      if (evt->xproperty.atom == xaCutBuffer0)
	{
#	 if defined(DEBUG_SELECTIONS)
	  fprintf(stderr, "CUT_BUFFER0 changed\n");
#	 endif
	  stOwnsClipboard= 0;
	  usePrimaryFirst= 1;
	}
      break;

    case SelectionNotify:
      if (useXdnd)
	dndHandleSelectionNotify(&evt->xselection);
      break;

    case ClientMessage:
      if (useXdnd)
	dndHandleClientMessage(&evt->xclient);
      break;

    case Expose:
      {
	XExposeEvent *ex= &evt->xexpose;
#      if defined(USE_XSHM)
	if (asyncUpdate)
	  waitForCompletions();
#      endif
#      if defined(FULL_UPDATE_ON_EXPOSE)
	/* ignore it if there are other exposures upstream */
	if (ex->count == 0)
	  fullDisplayUpdate();  /* this makes VM call ioShowDisplay */
#      else
	redrawDisplay(ex->x, ex->x + ex->width, ex->y, ex->y + ex->height);
#      endif /*!FULL_UPDATE_ON_EXPOSE*/
      }
      break;

    case MapNotify:
      /* The window has just been mapped, possibly for the first
	 time: update mousePosition (which otherwise may not be
	 set before the first button event). */
      getMousePosition();
      noteWindowChange();
      fullDisplayUpdate();
      break;

    case UnmapNotify:
      {
	XEvent ev;
	if (sleepWhenUnmapped)
	  do
	    {
	      /* xxx SelectInput() ??? -- need to filter key events? */
	      XNextEvent(stDisplay, &ev);
	      handleEvent(&ev);
	    }
	  while (ev.type != MapNotify);
	getMousePosition();
      }
      noteWindowChange();
      break;

    case ConfigureNotify:
      noteResize(evt->xconfigure.width, evt->xconfigure.height);
      break;

    case MappingNotify:
      XRefreshKeyboardMapping(&evt->xmapping);
      break;

#  if defined(USE_XSHM)
    default:
      if (evt->type == completionType)
	--completions;
      break;
#  endif
    }
# undef noteEventState
}


int handleEvents(void)
{
  if (!isConnectedToXServer || !XPending(stDisplay))
    return !iebEmptyP();

  while (XPending(stDisplay))
    {
      XEvent evt;
      XNextEvent(stDisplay, &evt);
      handleEvent(&evt);
    }
  return 1;
}


static void xHandler(int fd, void *data, int flags)
{
  handleEvents();	/* XPending() drains display connection input */
  aioHandle(stXfd, xHandler, AIO_RX);
}


static void npHandler(int fd, void *data, int flags)
{
  browserProcessCommand();
  aioHandle(browserPipes[0], npHandler, AIO_RX);
}


void getMaskbit(unsigned long ul, int *nmask, int *shift)
{
  int i;
  unsigned long hb;

  *nmask= *shift= 0;
  hb= 0x8000;  hb= (hb<<16);  /* hb = 0x80000000UL */
  for (i= 31; ((ul & hb) == 0) && i >= 0; --i, ul<<= 1)
    ;
  for (; ((ul & hb) != 0) && i >= 0; --i, ul<<= 1)
    (*nmask)++;
  *shift= i+1;
}

void initDownGradingColors(void)
{
  int r, g, b, i;

  if (stVisual->class == PseudoColor)
    {
      for (r= 0; r < 0x8; r++)
	for (g= 0; g < 0x8; g++)
	  for (b= 0; b < 0x4; b++)
	    {
	      int mindiff= 0x7*0x7 + 0x7*0x7 + 0x3*0x3 + 1;
	      for (i= 0; i < 256; i++)
		{
		  int rdiff, gdiff, bdiff, diff;
		  rdiff= r - ((stColors[i]>>5) & 0x7);
		  gdiff= g - ((stColors[i]>>2) & 0x7);
		  bdiff= b -  (stColors[i] & 0x3);
		  diff= rdiff*rdiff + gdiff*gdiff + bdiff*bdiff;
		  if (diff < mindiff)
		    {
		      mindiff= diff;
		      stDownGradingColors[(r << 5) + (g << 2) + b]= i;
		    }
		}
	    }
    }
  else
    for (i= 0; i < 256; i++)
      stDownGradingColors[i]=
	(  ((i >> 5) & ((1 << stRNMask) - 1)) << stRShift)
	| (((i >> 2) & ((1 << stGNMask) - 1)) << stGShift)
	| (((i >> 0) & ((1 << stBNMask) - 1)) << stBShift);
}

void initColourmap(int index, int red, int green, int blue)
{
  if (index >= 256)
    return;

  if (stVisual->class == TrueColor || stVisual->class == DirectColor)
    {
      unsigned int r, g, b;
      r= red;
      g= green;
      b= blue;

      stColors[index]= (((r>>(16-stRNMask))<<stRShift) |
			((g>>(16-stGNMask))<<stGShift) |
			((b>>(16-stBNMask))<<stBShift));
    }
  else
    {
      XColor color;
      color.pixel= index;
      color.red= red;
      color.green= green;
      color.blue= blue;
      color.flags= DoRed|DoGreen|DoBlue;
      XStoreColor(stDisplay, stColormap, &color);
      /* map rgb weight=332 */
      stColors[index]= ((((unsigned int)red  >>(16-3))<<5) |
			(((unsigned int)green>>(16-3))<<2) |
			((unsigned int)blue >>(16-2)));
    }
}

void initPixmap(void)
{
  int count;
  XPixmapFormatValues *xpv;

  xpv= XListPixmapFormats(stDisplay, &count);

  if (xpv)
    {
      while (--count >= 0)
	{
	  if (stDepth == xpv[count].depth)
	    stBitsPerPixel= xpv[count].bits_per_pixel;
	}
      XFree((void *)xpv);
    }
  if (stBitsPerPixel == 0)
    stBitsPerPixel= stDepth;

  switch (stVisual->class)
    {
    case PseudoColor:
      if (stBitsPerPixel == 8)
	break;
      else
	{
	  fprintf(stderr, "Visual class PseudoColor is not supported at depth %d\n", stBitsPerPixel);
	  exit(1);
	  return;
	}
    case TrueColor:
    case DirectColor:
      getMaskbit(stVisual->red_mask,   &stRNMask, &stRShift);
      getMaskbit(stVisual->green_mask, &stGNMask, &stGShift);
      getMaskbit(stVisual->blue_mask,  &stBNMask, &stBShift);
      if (stBitsPerPixel == 16)
	{
	  stHasSameRGBMask16= (stVisual->red_mask   == (0x1f << 10) &&
			       stVisual->green_mask == (0x1f << 5) &&
			       stVisual->blue_mask  == (0x1f));
	  break;
	}
      else if (stBitsPerPixel == 32)
	{
	  stHasSameRGBMask32= (stVisual->red_mask   == (0xff << 16) &&
			       stVisual->green_mask == (0xff << 8) &&
			       stVisual->blue_mask  == (0xff));
	  break;
	}
      else if (stBitsPerPixel == 24)
	{
	  /* nothing to do... */
	  break;
	}
      else
	{
	  fprintf(stderr, "Visual class TrueColor is not supported at depth %d\n", stBitsPerPixel);
	  exit(1);
	  return;
	}
    case GrayScale:
    case StaticColor:
    case StaticGray:
    default:
      fprintf(stderr, "This visual class is not supported\n");
      exit(1);
      return;
    }

  if (stVisual->class == PseudoColor)
    stColormap= XCreateColormap(stDisplay, stWindow, stVisual, AllocAll);



  /* 1-bit colors (monochrome) */
  initColourmap(0, 65535, 65535, 65535);	/* white or transparent */
  initColourmap(1,     0,     0,     0);	/* black */

	/* additional colors for 2-bit color */
  initColourmap(2, 65535, 65535, 65535);	/* opaque white */
  initColourmap(3, 32768, 32768, 32768);	/* 1/2 gray */

	/* additional colors for 4-bit color */
  initColourmap( 4, 65535,     0,     0);	/* red */
  initColourmap( 5,     0, 65535,     0);	/* green */
  initColourmap( 6,     0,     0, 65535);	/* blue */
  initColourmap( 7,     0, 65535, 65535);	/* cyan */
  initColourmap( 8, 65535, 65535,     0);	/* yellow */
  initColourmap( 9, 65535,     0, 65535);	/* magenta */
  initColourmap(10,  8192,  8192,  8192);	/* 1/8 gray */
  initColourmap(11, 16384, 16384, 16384);	/* 2/8 gray */
  initColourmap(12, 24576, 24576, 24576);	/* 3/8 gray */
  initColourmap(13, 40959, 40959, 40959);	/* 5/8 gray */
  initColourmap(14, 49151, 49151, 49151);	/* 6/8 gray */
  initColourmap(15, 57343, 57343, 57343);	/* 7/8 gray */

	/* additional colors for 8-bit color */
	/* 24 more shades of gray (does not repeat 1/8th increments) */
  initColourmap(16,  2048,  2048,  2048);	/*  1/32 gray */
  initColourmap(17,  4096,  4096,  4096);	/*  2/32 gray */
  initColourmap(18,  6144,  6144,  6144);	/*  3/32 gray */
  initColourmap(19, 10240, 10240, 10240);	/*  5/32 gray */
  initColourmap(20, 12288, 12288, 12288);	/*  6/32 gray */
  initColourmap(21, 14336, 14336, 14336);	/*  7/32 gray */
  initColourmap(22, 18432, 18432, 18432);	/*  9/32 gray */
  initColourmap(23, 20480, 20480, 20480);	/* 10/32 gray */
  initColourmap(24, 22528, 22528, 22528);	/* 11/32 gray */
  initColourmap(25, 26624, 26624, 26624);	/* 13/32 gray */
  initColourmap(26, 28672, 28672, 28672);	/* 14/32 gray */
  initColourmap(27, 30720, 30720, 30720);	/* 15/32 gray */
  initColourmap(28, 34815, 34815, 34815);	/* 17/32 gray */
  initColourmap(29, 36863, 36863, 36863);	/* 18/32 gray */
  initColourmap(30, 38911, 38911, 38911);	/* 19/32 gray */
  initColourmap(31, 43007, 43007, 43007);	/* 21/32 gray */
  initColourmap(32, 45055, 45055, 45055);	/* 22/32 gray */
  initColourmap(33, 47103, 47103, 47103);	/* 23/32 gray */
  initColourmap(34, 51199, 51199, 51199);	/* 25/32 gray */
  initColourmap(35, 53247, 53247, 53247);	/* 26/32 gray */
  initColourmap(36, 55295, 55295, 55295);	/* 27/32 gray */
  initColourmap(37, 59391, 59391, 59391);	/* 29/32 gray */
  initColourmap(38, 61439, 61439, 61439);	/* 30/32 gray */
  initColourmap(39, 63487, 63487, 63487);	/* 31/32 gray */

  /* The remainder of color table defines a color cube with six steps
     for each primary color. Note that the corners of this cube repeat
     previous colors, but simplifies the mapping between RGB colors and
     color map indices. This color cube spans indices 40 through 255.
     */
  {
    int r, g, b;

    for (r= 0; r < 6; r++)
      for (g= 0; g < 6; g++)
	for (b= 0; b < 6; b++)
	  {
	    int i= 40 + ((36 * r) + (6 * b) + g);
	    if (i > 255) error("index out of range in color table compuation");
	    initColourmap(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
	  }
  }

  stColorWhite.red= stColorWhite.green= stColorWhite.blue= 65535;
  stColorBlack.red= stColorBlack.green= stColorBlack.blue= 0;

  if (stVisual->class == PseudoColor)
    {
      XSetWindowColormap(stDisplay, stParent, stColormap);
      stColorWhite.pixel= 0;
      stColorBlack.pixel= 1;
#if 0
      /* initialise the black and white color values for cursor creation */
      if (XAllocColor(stDisplay, stColormap, &stColorWhite))
	fprintf(stderr, "failed to find white pixel in Squeak colormap\n");

      if (XAllocColor(stDisplay, stColormap, &stColorBlack))
	fprintf(stderr, "failed to find black pixel in Squeak colormap\n");
#endif
      initDownGradingColors();
    }
  else
    {
      stColorWhite.pixel= WhitePixel(stDisplay, DefaultScreen(stDisplay));
      stColorBlack.pixel= BlackPixel(stDisplay, DefaultScreen(stDisplay));
    }
}


static int xError(Display *dpy, XErrorEvent *evt)
{
  fprintf(stderr, "X error\n");
  return 0;
}


void initWindow(char *displayName)
{
  XRectangle windowBounds= { 0, 0, 640, 480 };  /* default window bounds */
  int right, bottom;

  XSetErrorHandler(xError);

  stDisplay= XOpenDisplay(displayName);
  if (!stDisplay)
    {
      fprintf(stderr, "Could not open display `%s'.\n", displayName);
      exit(1);
    }

  /* get screen size */
  scrH= (DisplayHeight(stDisplay, DefaultScreen(stDisplay)));
  scrW= (DisplayWidth(stDisplay, DefaultScreen(stDisplay)));
  if ((scrW % sizeof(void *)) != 0)
    scrW= (scrW / sizeof(void *)) * sizeof(void *);

  stXfd= ConnectionNumber(stDisplay);

  /* find the most suitable Visual */
  {
    /* preferred visuals in order of decreasing priority */
    static int trialVisuals[][2]= {
      { 32, TrueColor },
      { 32, DirectColor },
      { 32, StaticColor },
      { 32, PseudoColor },
      { 24, TrueColor },
      { 24, DirectColor },
      { 24, StaticColor },
      { 24, PseudoColor },
      { 16, TrueColor },
      { 16, DirectColor },
      { 16, StaticColor },
      { 16, PseudoColor },
      {  8, PseudoColor },
      {  8, DirectColor },
      {  8, TrueColor },
      {  8, StaticColor },
      {  0, 0 }
    };

    XVisualInfo viz;
    int i;

    for (i= 0; trialVisuals[i][0] != 0; ++i)
      {
#       if 0
	fprintf(stderr, "Trying %d bit %s.\n", trialVisuals[i][0],
		debugVisual(trialVisuals[i][1]));
#       endif
	if (XMatchVisualInfo(stDisplay, DefaultScreen(stDisplay),
			     trialVisuals[i][0], trialVisuals[i][1],
			     &viz) != 0) break;
      }
    if (trialVisuals [i][0] == 0)
      {
#	if 0
	fprintf(stderr, "Using default visual.\n");
#	endif
	stVisual= DefaultVisual(stDisplay, DefaultScreen(stDisplay));
	stDepth= DefaultDepth(stDisplay, DefaultScreen(stDisplay));
      }
    else
      {
	stVisual= viz.visual;
	stDepth= trialVisuals[i][0];
      }
  }

  if (fullScreen)
    {
      right=  scrW;
      bottom= scrH;
    }
  else
    {
      int savedWindowSize= getSavedWindowSize();
      if (savedWindowSize != 0)
	{
	  right=  windowBounds.x + ((unsigned)savedWindowSize >> 16);
	  bottom= windowBounds.y + (savedWindowSize & 0xFFFF);
	}
      else
	{
	  right= windowBounds.x + windowBounds.width;
	  bottom= windowBounds.y + windowBounds.height;
	}
    }
  /* minimum size is 64 x 64 */
  right= ( right > (windowBounds.x + 64)) ?  right : (windowBounds.x + 64);
  bottom= (bottom > (windowBounds.y + 64)) ? bottom : (windowBounds.y + 64);

  /* maximum bottom-right is screen bottom-right */
  right=  ( right <= DisplayWidth(stDisplay, DefaultScreen(stDisplay)))
    ?  right : (DisplayWidth(stDisplay, DefaultScreen(stDisplay))  - 8);
  bottom= (bottom <= DisplayHeight(stDisplay, DefaultScreen(stDisplay)))
    ? bottom : (DisplayHeight(stDisplay, DefaultScreen(stDisplay)) - 8);

  windowBounds.width= right - windowBounds.x;
  windowBounds.height= bottom - windowBounds.y;

  if (windowBounds.width % sizeof(void *))
    windowBounds.width= (windowBounds.width / sizeof(void *)) * sizeof(void *);

  stWidth= windowBounds.width;
  stHeight= windowBounds.height;

  /* create the Squeak window */
  {
    XSetWindowAttributes attributes;
    unsigned long valuemask, parentValuemask;

    attributes.border_pixel= WhitePixel(stDisplay, DefaultScreen(stDisplay));
    attributes.background_pixel= WhitePixel(stDisplay, DefaultScreen(stDisplay));
    attributes.event_mask= WM_EVENTMASK;
    attributes.backing_store= NotUseful;

    if (useXdnd)
      attributes.event_mask |= EnterWindowMask;

    valuemask= CWEventMask | CWBackingStore | CWBorderPixel | CWBackPixel;
    parentValuemask= CWEventMask | CWBackingStore | CWBorderPixel;

    /* A visual that is not DefaultVisual requires its own color map.
       If visual is PseudoColor, the new color map is made elsewhere. */
    if ((stVisual != DefaultVisual(stDisplay, DefaultScreen(stDisplay))) &&
	(stVisual->class != PseudoColor))
      {
	stColormap= XCreateColormap(stDisplay,
				    RootWindow(stDisplay, DefaultScreen(stDisplay)),
				    stVisual,
				    AllocNone);
	attributes.colormap= stColormap;
	valuemask|= CWColormap;
	parentValuemask|= CWColormap;
      }

#  if defined(DEBUG_BROWSER)
    fprintf(stderr, "browser window %d\n", browserWindow);
#  endif

    if (browserWindow != 0)
      {
	Window root;
	int s;
	unsigned int w, h, u;
	stParent= browserWindow;
	XGetGeometry(stDisplay, stParent, &root, &s, &s, &w, &h, &u, &u);
	stWidth= xWidth= w;
	stHeight= xHeight= h;
	setSavedWindowSize((w << 16) | h);
      }
    else
      {
	int s= getSavedWindowSize();
	if (s)
	  {
	    stWidth=  s >> 16;
	    stHeight= s &  0xffff;
	  }
	stParent= XCreateWindow(stDisplay,
				DefaultRootWindow(stDisplay),
				windowBounds.x, windowBounds.y,
				stWidth, stHeight,
				0,
				stDepth, InputOutput, stVisual,
				parentValuemask, &attributes);
      }

    attributes.event_mask= EVENTMASK;
    attributes.backing_store= NotUseful;

    stWindow= XCreateWindow(stDisplay, stParent,
			    0, 0,
			    stWidth, stHeight,
			    0,
			    stDepth, InputOutput, stVisual,
			    valuemask, &attributes);
  }

  /* look for property changes on root window to track selection */
  XSelectInput(stDisplay, DefaultRootWindow(stDisplay), PropertyChangeMask);

  /* set the geometry hints */
  if (!browserWindow)
    {
      XSizeHints *sizeHints= XAllocSizeHints();
      sizeHints->min_width= 16;
      sizeHints->min_height= 16;
      sizeHints->width_inc= sizeof(void *);
      sizeHints->height_inc= 1;
      sizeHints->win_gravity= NorthWestGravity;
      sizeHints->flags= PWinGravity | PResizeInc;
      XSetWMNormalHints(stDisplay, stWindow, sizeHints);
      XSetWMNormalHints(stDisplay, stParent, sizeHints);
      XFree((void *)sizeHints);
    }

  /* set the window title and resource/class names */
  {
    XClassHint *classHints= XAllocClassHint();
    classHints->res_class= xResClass;
    classHints->res_name= xResName;
    if (browserWindow == 0)
      {
	XSetClassHint(stDisplay, stParent, classHints);
	XStoreName(stDisplay, stParent, shortImageName);
      }
    XFree((void *)classHints);
  }

  /* tell the WM that we can't be bothered managing focus for ourselves */
  {
    XWMHints *wmHints= XAllocWMHints();
    wmHints->input= True;
    wmHints->initial_state= NormalState;
    wmHints->flags= InputHint|StateHint;
# if !defined(NO_ICON)
    wmHints->icon_pixmap=
      XCreateBitmapFromData(stDisplay, DefaultRootWindow(stDisplay),
			    sqXIcon_bits, sqXIcon_width, sqXIcon_height);
    if (wmHints->icon_pixmap != None)
      wmHints->flags |= IconPixmapHint;
# endif
    if (iconified)
      {
	wmHints->initial_state= IconicState;
	wmHints->flags |= StateHint;
      }
    XSetWMHints(stDisplay, stParent, wmHints);
    XFree((void *)wmHints);
  }

  /* create a suitable graphics context */
  {
    XGCValues gcValues;

    gcValues.function= GXcopy;
    gcValues.line_width= 0;
    gcValues.subwindow_mode= IncludeInferiors;
    gcValues.clip_x_origin= 0;
    gcValues.clip_y_origin= 0;
    gcValues.clip_mask= None;
    gcValues.foreground= SqueakWhite;
    gcValues.background= SqueakWhite;
    gcValues.fill_style= FillSolid;
    stGC= XCreateGC(stDisplay,
		    stWindow,
		    GCFunction | GCLineWidth | GCSubwindowMode |
		    GCClipXOrigin | GCClipYOrigin | GCClipMask |
		    GCForeground | GCBackground | GCFillStyle,
		    &gcValues);
  }

  if (noTitle || fullScreen)
    /* naughty, but effective */
    XSetTransientForHint(stDisplay, stParent, DefaultRootWindow(stDisplay));

# if defined(USE_XSHM)
  if (useXshm)
    completionType= XShmGetEventBase(stDisplay) + ShmCompletion;
# endif

  XInternAtoms(stDisplay, selectionAtomNames, SELECTION_ATOM_COUNT, False, selectionAtoms);

  if (useXdnd)
    dndInitialise();
}


void setWindowSize(void)
{
  int width, height, maxWidth, maxHeight;
  int winSize= getSavedWindowSize();

#if defined(DEBUG_BROWSER)
  fprintf(stderr, "browserWindow %d\n", browserWindow);
#endif

  if (browserWindow) return;

#if defined(DEBUG_WINDOW)
  fprintf(stderr, "savedWindowSize %x (%d %d)\n", winSize, winSize >> 16, winSize & 0xffff);
#endif

  if (winSize != 0)
    {
      width=  (unsigned)winSize >> 16;
      height= winSize & 0xFFFF;
    }
  else
    {
      width=  640;
      height= 480;
    }

  /* minimum size is 64 x 64 */
  width=  ( width > 64) ?   width : 64;
  height= (height > 64) ?  height : 64;

  /* maximum size is screen size */
  maxWidth=  (DisplayWidth(stDisplay, DefaultScreen(stDisplay)));
  maxHeight= (DisplayHeight(stDisplay, DefaultScreen(stDisplay)));
  width=  ( width <= maxWidth)  ?  width : maxWidth;
  height= (height <= maxHeight) ? height : maxHeight;

  if (fullScreen)
    {
      width= maxWidth;
      height= maxHeight;
    }

#if defined(DEBUG_WINDOW)
  fprintf(stderr, "resize %d %d\n", width, height);
#endif

  noteResize(stWidth= width, stHeight= height);
}


/*** Event Recording Functions ***/


static int translateCode(KeySym symbolic)
{
# define ALT (8<<8)
  switch (symbolic)
    {
    case XK_Left:	return 28;
    case XK_Up:		return 30;
    case XK_Right:	return 29;
    case XK_Down:	return 31;
    case XK_Insert:	return  5;
    case XK_Prior:	return 11;	/* page up */
    case XK_Next:	return 12;	/* page down */
    case XK_Home:	return  1;
    case XK_End:	return  4;

    /* "aliases" for Sun keyboards */
    case XK_R9:		return 11;	/* page up */
    case XK_R15:	return 12;	/* page down */
    case XK_R7:		return  1;	/* home */
    case XK_R13:	return  4;	/* end */
    case XK_L1:		return ALT+'.';	/* stop */
    case XK_L2:		return ALT+'j';	/* again */
    case XK_L4:		return ALT+'z';	/* undo */
    case XK_L6:		return ALT+'c';	/* copy */
    case XK_L8:		return ALT+'v';	/* paste */
    case XK_L9:		return ALT+'f';	/* find */
    case XK_L10:	return ALT+'x';	/* cut */

    /* XKB extensions */
# if defined(XK_ISO_Left_Tab)
    case XK_ISO_Left_Tab: return  9;	/* shift-tab */
# endif

    default:		return -1;
    }
  /*NOTREACHED*/
# undef ALT
}



/*** I/O Primitives ***/


#if !defined(HAVE_SNPRINTF)
# if defined(HAVE___SNPRINTF)	/* Solaris 2.5 */
    extern int __snprintf(char *buf, size_t limit, const char *fmt, ...);
#   define snprintf __snprintf
#   define HAVE_SNPRINTF
# endif
#endif


static sqInt display_ioFormPrint(sqInt bitsIndex, sqInt width, sqInt height, sqInt depth, double hScale, double vScale, sqInt landscapeFlag)
{
# if defined(PRINT_PS_FORMS)

  char *bitsAddr= pointerForOop(bitsIndex);
  FILE *ppm;
  float scale;			/* scale to use with pnmtops */
  char printCommand[1000];
  unsigned int *form32;		/* the form data, in 32 bits */

  /* convert the form to 32 bits */

  typedef void (*copyFn)(int *, int *, int, int, int, int, int, int);
  static copyFn copyFns[33]= {
    0,
    copyImage1To32,	/* 1 */
    copyImage2To32,	/* 2 */
    0,
    copyImage4To32,	/* 4 */
    0, 0, 0,
    copyImage8To32,	/* 8 */
    0, 0, 0, 0, 0, 0,
    copyImage16To32,	/* 15 */
    copyImage16To32,	/* 16 */
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0,
    copyImage32To32	/* 32 */
  };

  copyFn copy= ((depth > 0) && (depth <= 32)) ? copyFns[depth] : 0;
  if (!copy)
    {
      fprintf(stderr, "ioFormPrint: depth %d not supported\n", depth);
      return false;
    }

  form32= malloc(width * height * 4);
  if (!form32)
    {
      fprintf(stderr, "ioFormPrint: out of memory\n");
      return false;
    }

  copy((int *)bitsAddr, (int *)form32, width, height, 1, 1, width, height);

  /* pick a scale. unfortunately, pnmtops requires the same scale
     horizontally and vertically */
  if (hScale < vScale)
    scale= hScale;
  else
    scale= vScale;

  /* assemble the command for printing.  pnmtops is part of "netpbm",
     a widely-available set of tools that eases image manipulation */
#if defined(HAVE_SNPRINTF)
  snprintf(printCommand, sizeof(printCommand),
	   "pnmtops -scale %f %s | lpr",
	   scale,
	   (landscapeFlag ? "-turn" : "-noturn"));
#else /* if your OS is broken then so might be this code */
  sprintf(printCommand,
	  "pnmtops -scale %f %s | lpr",
	  scale,
	  (landscapeFlag ? "-turn" : "-noturn"));
#endif

  /* open a pipe to print through */
  if ((ppm= popen(printCommand, "w")) == 0)
    {
      free(form32);
      return false;
    }

  /* print the PPM magic number */
  fprintf(ppm, "P3\n%d %d 255\n", width, height);

  /* write the pixmap */
  {
    int y;
    for (y= 0; y < height; ++y)
      {
	int x;
	for (x= 0; x < width; ++x)
	  {
	    int pixel= form32[y*width + x];
	    int red=   (pixel >> 16) & 0xFF;
	    int green= (pixel >> 8)  & 0xFF;
	    int blue=  (pixel >> 0)  & 0xFF;
	    fprintf(ppm, "%d %d %d\n", red, green, blue);
	  }
      }
  }
  free(form32);
  pclose(ppm);
  return true;

# else  /* !PRINT_PS_FORMS */

  /* Write the form as a PPM (Portable PixMap) file, from which it can
     be converted into almost any existing graphical format (including
     PostScript).  See the "netpbm" utilities for a huge collection of
     image manipulation tools that understand the PPM format.
     Note that "xv" can also read, convert, and do image processing on
     PPM files.
     The output filename is defined in "sqPlatformSpecific.h". */

  FILE *ppm;
  int ok= true;

  if ((ppm= fopen(SQ_FORM_FILENAME, "wb")) == 0)
    return false;

  /* PPM magic number and pixmap header */
  fprintf(ppm, "P3\n%d %d 65535\n", width, height);

  switch (depth)
    {
    case 8:
      {
	unsigned char *bits= (unsigned char *) bitsAddr;
	int ppw= 32 / depth;
	int raster= ((width + ppw - 1) / ppw) * 4;
	/* stColors[] is too approximate: query the real colormap */
	XColor colors[256];
	int i;
	for (i= 0; i < 256; ++i) colors[i].pixel= i;
	/* all colors in one query reduces server traffic */
	XQueryColors(stDisplay, stColormap, colors, 256);
	/* write the pixmap */
	{
	  int y;
	  for (y= 0; y < height; ++y) {
	    int x;
	    for (x= 0; x < width; ++x) {
	      /* everything is backwards (as usual ;) */
	      int index= y * raster + x;
	      int byte= 3 - (index & 0x00000003);
	      int word= index & -4;
	      int pixel= bits[word + byte];
	      fprintf(ppm, "%d %d %d\n",
		      colors[pixel].red, colors[pixel].green, colors[pixel].blue);
	    }
	  }
	}
	break;
      } /* case 8 */
    default:
      fprintf(stderr, "ioFormPrint: depth %d not supported.\n", depth);
      ok= false;
      break;
    } /* switch */

  fclose(ppm);
  return ok;

# endif /* !PRINT_PS_FORMS */
}


static sqInt display_ioBeep(void)
{
  if (isConnectedToXServer)
    XBell(stDisplay, 0);	/* ring at default volume */
  return 0;
}


static sqInt display_ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
  aioSleep(handleEvents() ? 0 : microSeconds);
  return 0;
}


static sqInt display_ioProcessEvents(void)
{
  handleEvents();
  aioPoll(0);
  return 0;
}


/* returns the depth of the Squeak window */
static sqInt display_ioScreenDepth(void)
{
  Window root;
  int x, y;
  unsigned int w, h, b, d;

  if (!isConnectedToXServer)
    return 1;

  XGetGeometry(stDisplay, stParent, &root, &x, &y, &w, &h, &b, &d);
  return d;
}


/* returns the size of the Squeak window */
static sqInt display_ioScreenSize(void)
{
  int winSize= getSavedWindowSize();

  if (headless || !isConnectedToXServer)
    return winSize ? winSize : ((64 << 16) | 64);

  if ((windowState == WIN_ZOOMED) && !resized())
    return (scrW << 16) | scrH;

  if (resized())
    {
      windowState= WIN_NORMAL;
      if (useXshm && !isAligned(void *, xWidth))
	{
	  xWidth= align(void *, xWidth);
	  if (!browserWindow)
	    {
	      XResizeWindow(stDisplay, stParent, xWidth, xHeight);
	    }
	}
      XResizeWindow(stDisplay, stWindow, (stWidth= xWidth), (stHeight= xHeight));
    }
  return (stWidth << 16) | stHeight;  /* w is high 16 bits; h is low 16 bits */
}


static unsigned char swapBits(unsigned char in)
{
  unsigned char out= 0;
  int i;
  for (i= 0; i < 8; i++)
    {
      out= (out << 1) + (in & 1);
      in >>= 1;
    }
  return out;
}


static sqInt display_ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
  unsigned int *cursorBits= (unsigned int *)pointerForOop(cursorBitsIndex);
  unsigned int *cursorMask= (unsigned int *)pointerForOop(cursorMaskIndex);
  unsigned char data[32], mask[32];	/* cursors are always 16x16 */
  int i;
  Cursor cursor;
  Pixmap dataPixmap, maskPixmap;

  if (!isConnectedToXServer)
    return 0;

  if (cursorMaskIndex == null)
    cursorMask= cursorBits;

  for (i= 0; i < 16; i++)
    {
      data[i*2+0]= (cursorBits[i] >> 24) & 0xFF;
      data[i*2+1]= (cursorBits[i] >> 16) & 0xFF;
      mask[i*2+0]= (cursorMask[i] >> 24) & 0xFF;
      mask[i*2+1]= (cursorMask[i] >> 16) & 0xFF;
    }

  /*  if (BitmapBitOrder(stDisplay) == LSBFirst)*/
    {
      /* the bytes are always in the right order: swap only bits within bytes */
      char *dp= (char *)data;
      char *mp= (char *)mask;
      for (i= 0; i < 32; i++)
	{
	  dp[i]= swapBits(dp[i]);
	  mp[i]= swapBits(mp[i]);
	}
    }

  dataPixmap= XCreateBitmapFromData(stDisplay,
				    DefaultRootWindow(stDisplay),
				    (char *)data, 16, 16);
  maskPixmap= XCreateBitmapFromData(stDisplay,
				    DefaultRootWindow(stDisplay),
				    (char *)mask, 16, 16);
  cursor= XCreatePixmapCursor(stDisplay, dataPixmap, maskPixmap,
			      &stColorBlack, &stColorWhite,
			      -offsetX, -offsetY);

  XFreePixmap(stDisplay, dataPixmap);
  XFreePixmap(stDisplay, maskPixmap);

  if (cursor != None)
    XDefineCursor(stDisplay, stWindow, cursor);

  XFreeCursor(stDisplay, cursor);

  return 0;
}


#if 0
sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY)
{
  /* Deprecated: forward to new version with explicit mask. */
  ioSetCursorWithMask(cursorBitsIndex, null, offsetX, offsetY);
  return 0;
}
#endif


static void overrideRedirect(Display *dpy, Window win, int flag)
{
  XSetWindowAttributes attrs;
  attrs.override_redirect= flag;
  XChangeWindowAttributes(dpy, win, CWOverrideRedirect, &attrs);
}


static sqInt display_ioSetFullScreen(sqInt fullScreen)
{
  int winX, winY;
  unsigned int winW, winH;

  if (!isConnectedToXServer)
    return 0;

  if (fullScreen)
    {
      /* setting full-screen mode */
      if (savedWindowOrigin == -1)
	{
	  /* EITHER: no previous call, OR: previous call disabled full-screen mode */
	  Window root;
	  {
	    /* need extent only */
	    unsigned int b, d;
	    XGetGeometry(stDisplay, stWindow, &root, &winX, &winY, &winW, &winH, &b, &d);
	  }
	  /* width must be a multiple of sizeof(void *), or X[Shm]PutImage goes gaga */
	  if ((winW % sizeof(void *)) != 0)
	    winW= (winW / sizeof(void *)) * sizeof(void *);
	  setSavedWindowSize((winW << 16) + (winH & 0xFFFF));
	  savedWindowOrigin= (winX << 16) + (winY & 0xFFFF);
	  XSynchronize(stDisplay, True);
	  overrideRedirect(stDisplay, stWindow, True);
	  XReparentWindow(stDisplay, stWindow, root, 0, 0);
#	 if 1
	  XResizeWindow(stDisplay, stWindow, scrW, scrH);
#	 else
	  XResizeWindow(stDisplay, stParent, scrW, scrH);
#	 endif
	  XLowerWindow(stDisplay, stParent);
	  XRaiseWindow(stDisplay, stWindow);
	  XSetInputFocus(stDisplay, stWindow, RevertToPointerRoot, CurrentTime);
	  XSynchronize(stDisplay, False);
	  windowState= WIN_ZOOMED;
	  fullDisplayUpdate();
	}
    }
  else
    {
      /* reverting to sub-screen mode */
      if (savedWindowOrigin != -1)
	{ /* previous call enabled full-screen mode */
	  /* get old window size */
	  int winSize= getSavedWindowSize();
	  winW= (unsigned)winSize >> 16;
	  winH= winSize & 0xFFFF;
	  /* minimum size is 64 x 64 */
	  winW= (winW > 64) ? winW : 64;
	  winH= (winH > 64) ? winH : 64;
	  /* old origin */
	  winX= savedWindowOrigin >> 16;
	  winY= savedWindowOrigin & 0xFFFF;
	  savedWindowOrigin= -1; /* prevents consecutive full-screen disables */
	  XSynchronize(stDisplay, True);
	  XRaiseWindow(stDisplay, stParent);
	  XReparentWindow(stDisplay, stWindow, stParent, 0, 0);
	  overrideRedirect(stDisplay, stWindow, False);
#	 if 1
	  XResizeWindow(stDisplay, stWindow, scrW, scrH);
#	 else
	  XResizeWindow(stDisplay, stParent, winW, winH);
#	 endif
	  XSynchronize(stDisplay, False);
	  windowState= WIN_CHANGED;
	}
    }
  /* sync avoids race with ioScreenSize() reading geometry before resize event */
  XSync(stDisplay, False);
  getMousePosition();

  return 0;
}



/*** shared-memory stuff ***/



# if defined(USE_XSHM)
static int shmError(Display *dpy, XErrorEvent *evt)
{
  char buf[2048];
  XGetErrorText(stDisplay, evt->error_code, buf, sizeof(buf));
  fprintf(stderr, "XShmAttach: %s\n", buf);
  return 0;
}
#endif


static void *stMalloc(size_t lbs)
{
# if defined(USE_XSHM)
  if (useXshm)
    {
      if ((stShmInfo.shmid= shmget(IPC_PRIVATE, lbs, IPC_CREAT|0777)) == -1)
	perror("shmget");
      else
	{
	  if ((long)(stShmInfo.shmaddr= (char *)shmat(stShmInfo.shmid, 0, 0)) == -1)
	    perror("shmat");
	  else
	    {
	      /* temporarily install error handler */
	      XErrorHandler prev= XSetErrorHandler(shmError);
	      int result= 0;
	      stShmInfo.readOnly= False;
	      result= XShmAttach(stDisplay, &stShmInfo);
	      XSync(stDisplay, False);
	      XSetErrorHandler(prev);
	      if (result)
		{
#		 if defined(__linux__)
		  /* destroy ID now; segment will be destroyed at exit */
		  shmctl(stShmInfo.shmid, IPC_RMID, 0);
#		 endif
		  return stShmInfo.shmaddr;
		}
	      shmdt(stShmInfo.shmaddr);
	    }
	  /* could not attach to allocated shared memory segment */
	  shmctl(stShmInfo.shmid, IPC_RMID, 0);
	}
      /* could not allocate shared memory segment */
      useXshm= 0;
    }
# endif /* USE_XSHM */
  return (void *)malloc(lbs);
}


static void stFree(void *addr)
{
#if defined(USE_XSHM)
  if (!useXshm)
#endif
    {
      free(addr);
      return;
    }
#if defined(USE_XSHM)
  shmdt(stShmInfo.shmaddr);
  shmctl(stShmInfo.shmid, IPC_RMID, NULL);
#endif
}

#if defined(USE_XSHM)
static void shmExit(void)
{
  if (stDisplayBitmap && useXshm)
    {
      stFree(stDisplayBitmap);
      stDisplayBitmap= 0;
    }
}
#endif


static XImage *stXCreateImage(Display *display, Visual *visual,
			      int depth, int format, int flags, char *data,
			      int width, int height, int bpp, int pad)
{
#if defined(USE_XSHM)
  if (!useXshm)
#endif
    return XCreateImage(display, visual, depth, format, flags,
			data, width, height, bpp, pad);
#if defined(USE_XSHM)
  return XShmCreateImage(display, visual, depth, format, data,
			 &stShmInfo, width, height);
#endif
}


static void stXPutImage(Display *display, Window window, GC gc, XImage *image,
			int src_x, int src_y, int dst_x, int dst_y, int w, int h)
{
#if defined(USE_XSHM)
  if (!useXshm)
#endif
    {
      XPutImage(display, window, gc, image, src_x, src_y, dst_x, dst_y, w, h);
      return;
    }
#if defined(USE_XSHM)
  XShmPutImage(display, window, gc, image, src_x, src_y, dst_x, dst_y, w, h, True);
  ++completions;
  if (!asyncUpdate)
    waitForCompletions();
#endif
}


static void stXDestroyImage(XImage *image)
{
#if defined(USE_XSHM)
  if (useXshm)
    XShmDetach(stDisplay, &stShmInfo);
#endif
  XDestroyImage(image);
}


#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)
#define bytesPerLineRD(width, depth)	((((width)*(depth)) >> 5) << 2)


static sqInt display_ioForceDisplayUpdate(void)
{
#if defined(USE_XSHM)
  if (asyncUpdate && isConnectedToXServer)
    {
      XFlush(stDisplay);
      waitForCompletions();
    }
#endif
  return 0;
}


static sqInt display_ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
				   sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
  static char *stDisplayBits= 0;	/* last known oop of the VM's Display */
  static sqInt  stDisplayWidth= 0;	/* ditto width */
  static sqInt  stDisplayHeight= 0;	/* ditto height */
  static sqInt  stDisplayDepth= 0;	/* ditto depth */

  char *dispBits= pointerForOop(dispBitsIndex);

  int geometryChanged= ((stDisplayBits != dispBits)
			|| (stDisplayWidth  != width)
			|| (stDisplayHeight != height)
			|| (stDisplayDepth  != depth));

  if (stWindow == 0)
    return 0;

  if ((width < 1) || (height < 1))
    return 0;

  if (affectedL > width)  affectedL= width;
  if (affectedR > width)  affectedR= width;
  if (affectedT > height) affectedT= height;
  if (affectedB > height) affectedB= height;

  if ((affectedL > affectedR) || (affectedT > affectedB))
    return 0;

  if (!(depth == 1 || depth == 2 || depth == 4
	|| depth == 8 || depth == 16 || depth == 32))
    {
      fprintf(stderr, "depth %d is not supported\n", depth);
      exit(1);
      return 0;
    }

  if (resized())
    return 0;

  if (geometryChanged)
    {
      stDisplayBits= dispBits;
      stDisplayWidth= width;
      stDisplayHeight= height;
      stDisplayDepth= depth;

# if defined(USE_XSHM)
      if (asyncUpdate)
	/* wait for pending updates to complete before freeing the XImage */
	waitForCompletions();
# endif
      stDisplayBits= dispBits;
      if (stImage)
	{
	  stImage->data= 0; /* don't you dare free() Display's Bitmap! */
	  stXDestroyImage(stImage);
	  if (stDisplayBitmap)
	    {
	      stFree(stDisplayBitmap);
	      stDisplayBitmap= 0;
	    }
	}

# if !defined(USE_XSHM)
#  define useXshm 0
# endif

#    if defined(WORDS_BIGENDIAN)
      if (!useXshm && depth == stBitsPerPixel &&
	  (depth != 16 || stHasSameRGBMask16) &&
	  (depth != 32 || stHasSameRGBMask32))
#    else
      if (!useXshm && depth == stBitsPerPixel && depth == 32 && stHasSameRGBMask32)
#    endif
	{
	  stDisplayBitmap= 0;
	}
      else
	{
	  stDisplayBitmap= stMalloc(bytesPerLine(width, stBitsPerPixel) * height);
	}

# if !defined(USE_XSHM)
#  undef useXshm
# endif

      stImage= stXCreateImage(stDisplay,
			      DefaultVisual(stDisplay, DefaultScreen(stDisplay)),
			      stDepth,
			      ZPixmap,
			      0,
			      (stDisplayBitmap
			         ? stDisplayBitmap
			         : stDisplayBits),
			      width,
			      height,
			      32,
			      0);
      /* Xlib ignores the following */
# if defined(WORDS_BIGENDIAN)
      stImage->byte_order= MSBFirst;
      stImage->bitmap_bit_order= MSBFirst;
# else
      stImage->byte_order= LSBFirst;
      stImage->bitmap_bit_order= LSBFirst;
# endif
      /* not really required (since we never call Get/PutPixel), but what the hey */
      /*
      if (!XInitImage(stImage))
	fprintf(stderr, "XInitImage failed (but we don't care)\n");
      */
    }

  /* this can happen after resizing the window */
  if (affectedR > width) affectedR= width;
  if (affectedB > height) affectedB= height;
  if ((affectedR <= affectedL) || (affectedT >= affectedB))
    return 1;

  if (depth != stBitsPerPixel)
    {
      if (depth == 1)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage1To8((int *)dispBits, (int *)stDisplayBitmap,
			    width, height,
			    affectedL, affectedT, affectedR, affectedB);
	    }
	  if (stBitsPerPixel == 16)
	    {
	      copyImage1To16((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (stBitsPerPixel == 24)
	    {
	      copyImage1To24((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage1To32((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}

      else if (depth == 2)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage2To8((int *)dispBits, (int *)stDisplayBitmap,
			    width, height,
			    affectedL, affectedT, affectedR, affectedB);
	    }
	  if (stBitsPerPixel == 16)
	    {
	      copyImage2To16((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (stBitsPerPixel == 24)
	    {
	      copyImage2To24((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage2To32((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}

      else if (depth == 4)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage4To8((int *)dispBits, (int *)stDisplayBitmap,
			    width, height,
			    affectedL, affectedT, affectedR, affectedB);
	    }
	  if (stBitsPerPixel == 16)
	    {
	      copyImage4To16((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (stBitsPerPixel == 24)
	    {
	      copyImage4To24((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage4To32((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}

      else if (depth == 8)
	{
	  if (stBitsPerPixel == 16)
	    {
	      copyImage8To16((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (stBitsPerPixel == 24)
	    {
	      copyImage8To24((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage8To32((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}
      else if (depth == 16)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage16To8((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if ( stBitsPerPixel == 24)
	    {
	      copyImage16To24((int *)dispBits, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage16To32((int *)dispBits, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }
	}
      else /* depth == 32 */
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage32To8((int *)dispBits, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (stBitsPerPixel == 16)
	    {
	      copyImage32To16((int *)dispBits, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitPerPixel == 24 */
	    {
	      copyImage32To24((int *)dispBits, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }
	}
    }
  else /* depth == stBitsPerPixel */
    {
      if (depth == 16 && !stHasSameRGBMask16)
	{
	  copyImage16To16((int *)dispBits, (int *)stDisplayBitmap,
			  width, height,
			  affectedL, affectedT, affectedR, affectedB);
	}
      else if (depth == 32 && !stHasSameRGBMask32)
	{
	  copyImage32To32((int *)dispBits, (int *)stDisplayBitmap,
			  width, height,
			  affectedL, affectedT, affectedR, affectedB);
	}
# if defined(WORDS_BIGENDIAN)
#   if defined(USE_XSHM)
      else if (useXshm)
	{
	  if (depth == 8)
	    {
	      copyImage8To8((int *)dispBits, (int *)stDisplayBitmap,
			    width, height,affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (depth == 16)
	    {
	      copyImage16To16((int *)dispBits, (int *)stDisplayBitmap,
			      width, height,affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (depth == 32)
	    {
	      copyImage32To32((int *)dispBits, (int *)stDisplayBitmap,
			      width, height,affectedL, affectedT, affectedR, affectedB);
	    }
	  else
	    {
	      fprintf(stderr, "shared memory not supported for this depth/byte-order\n");
	      exit(1);
	    }
	}
#   endif
# else /* !WORDS_BIGENDIAN */
      else if (depth == 8)
	{
	  copyReverseImageBytes((int *)dispBits, (int *)stDisplayBitmap,
				depth, width, height,
				affectedL, affectedT, affectedR, affectedB);
	}
      else if (depth == 16)
	{
	  copyReverseImageWords((int *)dispBits, (int *)stDisplayBitmap,
				depth, width, height,
				affectedL, affectedT, affectedR, affectedB);
	}
      else if (stDisplayBitmap != 0)
	{
	  /* there is a separate map, so we still need to copy */
	  if (depth == 32)
	    {
	      copyImage32To32Same((int *)dispBits, (int *)stDisplayBitmap,
				  width, height,
				  affectedL, affectedT, affectedR, affectedB);
	    }
	}
# endif
    }

  stXPutImage(stDisplay, stWindow, stGC, stImage,
	      affectedL, affectedT,	/* src_x, src_y */
	      affectedL, affectedT,	/* dst_x, dst_y */
	      affectedR-affectedL,	/* width */
	      affectedB-affectedT);	/* height */

  return 0;
}


static sqInt display_ioHasDisplayDepth(sqInt i)
{
  switch (i)
    {
    case 1:
    case 2:
    case 4:
      return stBitsPerPixel == 32;
    case 8:
    case 16:
    case 32:
      return true;
    }
  return false;
}


static sqInt display_ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
  fprintf(stderr, "ioSetDisplayMode(%d, %d, %d, %d)\n",
	  width, height, depth, fullscreenFlag);
  return 0;
}


void copyReverseImageBytes(int *fromImageData, int *toImageData, int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB)
{
  register int scanLine, firstWord, lastWord;
  register int line;

  scanLine= bytesPerLine(width, depth);
  firstWord= scanLine*affectedT + bytesPerLineRD(affectedL, depth);
  lastWord= scanLine*affectedT + bytesPerLine(affectedR, depth);

  for (line= affectedT; line < affectedB; line++)
  {
    register unsigned char *from= (unsigned char *)((long)fromImageData+firstWord);
    register unsigned char *limit= (unsigned char *)((long)fromImageData+lastWord);
    register unsigned char *to= (unsigned char *)((long)toImageData+firstWord);
    while (from < limit)
      {
	to[0]= from[3];
	to[1]= from[2];
	to[2]= from[1];
	to[3]= from[0];
	from+= 4;
	to+= 4;
      }
    firstWord+= scanLine;
    lastWord+= scanLine;
  }
}

void copyReverseImageWords(int *fromImageData, int *toImageData, int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB)
{
  register int scanLine, firstWord, lastWord;
  register int line;

  scanLine= bytesPerLine(width, depth);
  firstWord= scanLine*affectedT + bytesPerLineRD(affectedL, depth);
  lastWord= scanLine*affectedT + bytesPerLine(affectedR, depth);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned short *from= (unsigned short *)((long)fromImageData+firstWord);
      register unsigned short *limit= (unsigned short *)((long)fromImageData+lastWord);
      register unsigned short *to= (unsigned short *)((long)toImageData+firstWord);
      while (from < limit)
	{
	  to[0]= from[1];
	  to[1]= from[0];
	  from+= 2;
	  to+= 2;
	}
      firstWord+= scanLine;
      lastWord+= scanLine;
    }
}

void copyImage1To8(int *fromImageData, int *toImageData, int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 1 not yet implemented in 8 bpp\n");
  exit(1);
}

void copyImage2To8(int *fromImageData, int *toImageData, int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 2 not yet implemented in 8 bpp\n");
  exit(1);
}

void copyImage4To8(int *fromImageData, int *toImageData, int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 4 not yet implemented in 8 bpp\n");
  exit(1);
}

void copyImage8To8(int *fromImageData, int *toImageData, int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  register int scanLine, firstWord, lastWord;
  register int line;

  scanLine= bytesPerLine(width, 8);
  firstWord= scanLine*affectedT + bytesPerLineRD(affectedL, 8);
  lastWord= scanLine*affectedT + bytesPerLine(affectedR, 8);

  for (line= affectedT; line < affectedB; line++) {
    register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord);
    register unsigned int *limit= (unsigned int *)((long)fromImageData+lastWord);
    register unsigned int *to= (unsigned int *)((long)toImageData+firstWord);
    while (from < limit)
      *to++= *from++;
    firstWord+= scanLine;
    lastWord+= scanLine;
  }
}

void copyImage1To16(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 1 not yet implemented in 16 bpp\n");
  exit(1);
}

void copyImage2To16(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 2 not yet implemented in 16 bpp\n");
  exit(1);
}

void copyImage4To16(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 4 not yet implemented in 16 bpp\n");
  exit(1);
}

void copyImage8To16(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine8, firstWord8, lastWord8;
  int scanLine16, firstWord16;
  register int line;

  scanLine8= bytesPerLine(width, 8);
  firstWord8= scanLine8*affectedT + bytesPerLineRD(affectedL, 8);
  lastWord8= scanLine8*affectedT + bytesPerLine(affectedR, 8);
  scanLine16= bytesPerLine(width, 16);
  firstWord16= scanLine16*affectedT + (bytesPerLineRD(affectedL, 8) << 1);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned char *from= (unsigned char *)((long)fromImageData+firstWord8);
      register unsigned char *limit= (unsigned char *)((long)fromImageData+lastWord8);
      register unsigned short *to= (unsigned short *)((long)toImageData+firstWord16);
      while (from < limit)
	{
#	 if defined(WORDS_BIGENDIAN)
	  to[0]= stColors[from[0]];
	  to[1]= stColors[from[1]];
	  to[2]= stColors[from[2]];
	  to[3]= stColors[from[3]];
#	 else
	  to[0]= stColors[from[3]];
	  to[1]= stColors[from[2]];
	  to[2]= stColors[from[1]];
	  to[3]= stColors[from[0]];
#	 endif
	  from+= 4;
	  to+= 4;
	}
      firstWord8+= scanLine8;
      lastWord8+= scanLine8;
      firstWord16+= scanLine16;
    }
}

void copyImage16To8(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine16, firstWord16, lastWord16;
  int scanLine8, firstWord8;
  int line;

#define map16To8(w) (col= (w), stDownGradingColors[ \
  (((col >> (10+(5-3))) & 0x7) << 5) | \
  (((col >> (5+(5-3)))  & 0x7) << 2) | \
   ((col >> (0+(5-2)))  & 0x7)])

  scanLine16= bytesPerLine(width, 16);
  firstWord16= scanLine16*affectedT + bytesPerLineRD(affectedL, 16);
  lastWord16= scanLine16*affectedT + bytesPerLine(affectedR, 16);
  scanLine8= bytesPerLine(width, 8);
  firstWord8= scanLine8*affectedT + (bytesPerLineRD(affectedL, 16) >> 1);

  for (line= affectedT; line < affectedB; line++)
    {
      register int col;
      register unsigned short *from= (unsigned short *)((long)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((long)fromImageData+lastWord16);
      register unsigned char *to= (unsigned char *)((long)toImageData+firstWord8);

      while (from < limit)
	{
#	 if defined(WORDS_BIGENDIAN)
	  to[0]= map16To8(from[0]);
	  to[1]= map16To8(from[1]);
#	 else
	  to[0]= map16To8(from[1]);
	  to[1]= map16To8(from[0]);
#	 endif
	  from+= 2;
	  to+= 2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
      firstWord8+= scanLine8;
    }
#undef map16To8
}

void copyImage1To32(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine1, firstWord1, firstShift1;
  int scanLine32, firstWord32, lastWord32;
  int line;

  scanLine1= bytesPerLine(width, 1);
  firstWord1= scanLine1*affectedT + bytesPerLineRD(affectedL, 1);
  firstShift1= 31 - (affectedL & 31);

  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLine(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLine(affectedR, 32);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord1);
      register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((long)toImageData+lastWord32);
      register int shift= firstShift1;
      while (to < limit)
	{
	  *to= stColors[(*from >> shift) & 1];
	  to++;
	  shift--;
	  if (shift < 0)
	    {
	      shift= 31;
	      from++;
	    }
	}
      firstWord1+= scanLine1;
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
}

void copyImage2To32(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine2, firstWord2, firstShift2;
  int scanLine32, firstWord32, lastWord32;
  int line;

  scanLine2= bytesPerLine(width, 2);
  firstWord2= scanLine2*affectedT + bytesPerLineRD(affectedL, 2);
  firstShift2= 30 - ((affectedL & 15) * 2);

  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLineRD(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLineRD(affectedR, 32);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord2);
      register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((long)toImageData+lastWord32);
      register int shift= firstShift2;
      while (to < limit)
	{
	  *to= stColors[(*from >> shift) & 3];
	  to++;
	  shift-= 2;
	  if (shift < 0)
	    {
	      shift= 30;
	      from++;
	    }
	}
      firstWord2+= scanLine2;
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
}

void copyImage4To32(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine4, firstWord4, firstShift4;
  int scanLine32, firstWord32, lastWord32;
  int line;

  scanLine4= bytesPerLine(width, 4);
  firstWord4= scanLine4*affectedT + bytesPerLineRD(affectedL, 4);
  firstShift4= 28 - ((affectedL & 7) * 4);

  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLineRD(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLineRD(affectedR, 32);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord4);
      register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((long)toImageData+lastWord32);
      register int shift= firstShift4;
      while (to < limit)
	{
	  *to= stColors[(*from >> shift) & 15];
	  to++;
	  shift-= 4;
	  if (shift < 0)
	    {
	      shift= 28;
	      from++;
	    }
	}
      firstWord4+= scanLine4;
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
}

void copyImage8To32(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine8, firstWord8, lastWord8;
  int scanLine32, firstWord32;
  int line;

  scanLine8= bytesPerLine(width, 8);
  firstWord8= scanLine8*affectedT + bytesPerLineRD(affectedL, 8);
  lastWord8= scanLine8*affectedT + bytesPerLine(affectedR, 8);
  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + (bytesPerLineRD(affectedL, 8) << 2);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned char *from= (unsigned char *)((long)fromImageData+firstWord8);
      register unsigned char *limit= (unsigned char *)((long)fromImageData+lastWord8);
      register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
      while (from < limit)
	{
#	 if defined(WORDS_BIGENDIAN)
	  to[0]= stColors[from[0]];
	  to[1]= stColors[from[1]];
	  to[2]= stColors[from[2]];
	  to[3]= stColors[from[3]];
#	 else
	  to[0]= stColors[from[3]];
	  to[1]= stColors[from[2]];
	  to[2]= stColors[from[1]];
	  to[3]= stColors[from[0]];
#	 endif
	  from+= 4;
	  to+= 4;
	}
      firstWord8+= scanLine8;
      lastWord8+= scanLine8;
      firstWord32+= scanLine32;
    }
}

void copyImage1To24(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 1 not yet implemented in 24 bpp\n");
  exit(1);
}

void copyImage2To24(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 2 not yet implemented in 24 bpp\n");
  exit(1);
}

void copyImage4To24(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 4 not yet implemented in 24 bpp\n");
  exit(1);
}

void copyImage8To24(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine8, firstWord8, lastWord8;
  int scanLine24, firstWord24;
  int line;

  scanLine8= bytesPerLine(width, 8);
  firstWord8= scanLine8*affectedT + bytesPerLineRD(affectedL, 8);
  lastWord8= scanLine8*affectedT + bytesPerLine(affectedR, 8);
  scanLine24= bytesPerLine(width, 24);
  firstWord24= scanLine24*affectedT + ((affectedL>>2) * 12);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned char *from= (unsigned char *)((long)fromImageData+firstWord8);
      register unsigned char *limit= (unsigned char *)((long)fromImageData+lastWord8);
      register unsigned char *to= (unsigned char *)((long)toImageData+firstWord24);
      register unsigned int newpix= 0;
      while (from < limit)
	{
#	 if defined(WORDS_BIGENDIAN)
	  newpix= stColors[from[0]];
#	 else
	  newpix= stColors[from[3]];
#	 endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#	 if defined(WORDS_BIGENDIAN)
	  newpix= stColors[from[1]];
#	 else
	  newpix= stColors[from[2]];
#	 endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#	 if defined(WORDS_BIGENDIAN)
	  newpix= stColors[from[2]];
#	 else
	  newpix= stColors[from[1]];
#	 endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#	 if defined(WORDS_BIGENDIAN)
	  newpix= stColors[from[3]];
#	 else
	  newpix= stColors[from[0]];
#	 endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
	  from+= 4;
	}
      firstWord8+= scanLine8;
      lastWord8+= scanLine8;
      firstWord24+= scanLine24;
    }
}

void copyImage32To8(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine32, firstWord32, lastWord32;
  int scanLine8, firstWord8;
  int line;

#define map32To8(w) (col= (w), stDownGradingColors[\
  (((col >> (16+(8-3))) & 0x7) << 5) | \
  (((col >> ( 8+(8-3))) & 0x7) << 2) | \
   ((col >> ( 0+(8-2))) & 0x7)])

  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLineRD(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLine(affectedR, 32);
  scanLine8= bytesPerLine(width, 8);
  firstWord8= scanLine8*affectedT + (bytesPerLineRD(affectedL, 32) >> 2);

  for (line= affectedT; line < affectedB; line++)
  {
    register int col;
    register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord32);
    register unsigned int *limit= (unsigned int *)((long)fromImageData+lastWord32);
    register unsigned char *to= (unsigned char *)((long)toImageData+firstWord8);
    while (from < limit)
    {
      to[0]= map32To8(from[0]);
      from++;
      to++;
    }
    firstWord32+= scanLine32;
    lastWord32+= scanLine32;
    firstWord8+= scanLine8;
  }
#undef map32To8
}

void copyImage16To32(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine16, firstWord16, lastWord16;
  int scanLine32, firstWord32;
  int line;
  int rshift, gshift, bshift;
  register unsigned int col;

#if defined(DEBUG)
  fprintf(stderr, "copyImg16to32 %p -> %p (%d %d) %d %d %d %d\n",
	  fromImageData, toImageData, width, height,
	  affectedL, affectedT, affectedR, affectedB);
#endif

  rshift= stRNMask-5 + stRShift;
  gshift= stGNMask-5 + stGShift;
  bshift= stBNMask-5 + stBShift;

#define map16To32(w) (col= (w), \
  (((col >> 10) & 0x1f) << rshift) | \
  (((col >> 5)  & 0x1f) << gshift) | \
   ((col & 0x1f) << bshift))

  scanLine16= bytesPerLine(width, 16);
  firstWord16= scanLine16*affectedT + bytesPerLineRD(affectedL, 16);
  lastWord16= scanLine16*affectedT + bytesPerLine(affectedR, 16);
  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + (bytesPerLineRD(affectedL, 16) << 1);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned short *from= (unsigned short *)((long)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((long)fromImageData+lastWord16);
      register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
      while (from < limit)
	{
#	 if defined(WORDS_BIGENDIAN)
	  to[0]= map16To32(from[0]);
	  to[1]= map16To32(from[1]);
#	 else
	  to[0]= map16To32(from[1]);
	  to[1]= map16To32(from[0]);
#	 endif
	  from+= 2;
	  to+= 2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
      firstWord32+= scanLine32;
    }
#undef map16To32
}

void copyImage16To24(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine16, firstWord16, lastWord16;
  int scanLine24, firstWord24;
  int line;

  int rshift, gshift, bshift;
  register unsigned int col;

  rshift= stRNMask-5 + stRShift;
  gshift= stGNMask-5 + stGShift;
  bshift= stBNMask-5 + stBShift;

#define map16To24(w) (col= (w), \
  (((col >> 10) & 0x1f) << rshift) | \
  (((col >> 5)  & 0x1f) << gshift) | \
   ((col & 0x1f) << bshift))

  scanLine16= bytesPerLine(width, 16);
  firstWord16= scanLine16*affectedT + bytesPerLineRD(affectedL, 16);
  lastWord16= scanLine16*affectedT + bytesPerLine(affectedR, 16);
  scanLine24= bytesPerLine(width, 24);
  firstWord24= scanLine24*affectedT + ((affectedL>>1) * 6);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned short *from= (unsigned short *)((long)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((long)fromImageData+lastWord16);
      register unsigned char *to= (unsigned char *)((long)toImageData+firstWord24);
      register unsigned int newpix= 0;
      while (from < limit)
	{
#	 if defined(WORDS_BIGENDIAN)
	  newpix= map16To24(from[0]);
#	 else
	  newpix= map16To24(from[1]);
#	 endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#	 if defined(WORDS_BIGENDIAN)
	  newpix= map16To24(from[1]);
#	 else
	  newpix= map16To24(from[0]);
#	 endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
	  from+= 2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
      firstWord24+= scanLine24;
    }
#undef map16To24
}


void copyImage32To16(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine32, firstWord32, lastWord32;
  int scanLine16, firstWord16;
  int line;
  int rshift, gshift, bshift;
  register unsigned int col;

  rshift= stRNMask-5 + stRShift;
  gshift= stGNMask-5 + stGShift;
  bshift= stBNMask-5 + stBShift;

#define map32To16(w) (col= (w), \
  (((col >> 19) & 0x1f) << rshift) | \
  (((col >> 11) & 0x1f) << gshift) | \
  (((col >>  3) & 0x1f) << bshift))

  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLineRD(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLine(affectedR, 32);
  scanLine16= bytesPerLine(width, 16);
  firstWord16= scanLine16*affectedT + (bytesPerLineRD(affectedL, 32) >> 1);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((long)fromImageData+lastWord32);
      register unsigned short *to= (unsigned short *)((long)toImageData+firstWord16);
      while (from < limit)
	{
	  to[0]= map32To16(from[0]);
	  from++;
	  to++;
	}
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
      firstWord16+= scanLine16;
    }
#undef map32To16
}

void copyImage16To16(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine16, firstWord16, lastWord16;
  int line;
  int rshift, gshift, bshift;
  register unsigned int col;

  rshift= stRNMask-5 + stRShift;
  gshift= stGNMask-5 + stGShift;
  bshift= stBNMask-5 + stBShift;

#define map16To16(w) (col= (w), \
  (((col >> 10) & 0x1f) << rshift) | \
  (((col >> 5)  & 0x1f) << gshift) | \
   ((col & 0x1f) << bshift))

  scanLine16= bytesPerLine(width, 16);
  firstWord16= scanLine16*affectedT + bytesPerLineRD(affectedL, 16);
  lastWord16= scanLine16*affectedT + bytesPerLine(affectedR, 16);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned short *from= (unsigned short *)((long)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((long)fromImageData+lastWord16);
      register unsigned short *to= (unsigned short *)((long)toImageData+firstWord16);
      while (from < limit)
	{
#	 if defined(WORDS_BIGENDIAN)
	  to[0]= map16To16(from[0]);
	  to[1]= map16To16(from[1]);
#	 else
	  to[0]= map16To16(from[1]);
	  to[1]= map16To16(from[0]);
#	 endif
	  from+= 2;
	  to+= 2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
    }
#undef map16To16
}

void copyImage32To32(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine32, firstWord32, lastWord32;
  int line;
  int rshift, gshift, bshift;
  register unsigned int col;

  rshift= stRNMask-8 + stRShift;
  gshift= stGNMask-8 + stGShift;
  bshift= stBNMask-8 + stBShift;

#define map32To32(w) (col= (w), \
  (((col >> 16) & 0xff) << rshift) | \
  (((col >> 8)  & 0xff) << gshift) | \
   ((col & 0xff) << bshift))

  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLineRD(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLine(affectedR, 32);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((long)fromImageData+lastWord32);
      register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
      while (from < limit)
	{
	  *to= map32To32(*from);
	  from++;
	  to++;
	}
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
#undef map32To32
}

void copyImage32To32Same(int *fromImageData, int *toImageData,
			 int width, int height,
			 int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine32, firstWord32, lastWord32;
  int line;

  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLineRD(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLine(affectedR, 32);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((long)fromImageData+lastWord32);
      register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
      while (from < limit)
	{
	  *to= *from;
	  from++;
	  to++;
	}
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
}

void copyImage32To24(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine24, firstWord24;
  int scanLine32, firstWord32, lastWord32;
  int line;
  int rshift, gshift, bshift;
  register unsigned int col;
  rshift= stRNMask-8 + stRShift;
  gshift= stGNMask-8 + stGShift;
  bshift= stBNMask-8 + stBShift;

#define map32To24(w) (col= (w), \
  (((col >> 16) & 0xff) << rshift) | \
  (((col >> 8)  & 0xff) << gshift) | \
   ((col & 0xff) << bshift))

  /* offsets for the 24bpp destination */
  scanLine24= bytesPerLine(width, 24);
  firstWord24= scanLine24*affectedT + (affectedL * 3) /* NOT bytesPerLineRD(affectedL, 24) ! */ ;

  /* offsets for the 32bpp source */
  scanLine32= bytesPerLine(width, 32);
  firstWord32= scanLine32*affectedT + bytesPerLineRD(affectedL, 32);
  lastWord32= scanLine32*affectedT + bytesPerLine(affectedR, 32);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((long)fromImageData+lastWord32);
      register unsigned char *to= (unsigned char *)((long)toImageData+firstWord24);
      register unsigned int newpix= 0;
      while (from < limit)
	{
	  newpix= map32To24(*from);
	  from++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
	}
      firstWord24+= scanLine24;
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
#undef map32To24
}


static void display_winSetName(char *imageName)
{
  /* update the window title */
  if (isConnectedToXServer)
    XStoreName(stDisplay, stParent, imageName);
}


/*** display connection ***/


int openXDisplay(void)
{
  /* open the Squeak window. */
  if (!isConnectedToXServer)
    {
      initClipboard();
      initWindow(displayName);
      initPixmap();
      if (!inBrowser())
	{
	  setWindowSize();
	  XMapWindow(stDisplay, stParent);
	  XMapWindow(stDisplay, stWindow);
	}
      else /* if in browser we will be reparented and mapped by plugin */
	{
	  /* tell browser our window */
#        if defined(DEBUG_BROWSER)
	  fprintf(stderr, "browser: sending squeak window = 0x%x\n", stWindow);
#        endif
	  write(browserPipes[1], &stWindow, 4);
#        if defined(DEBUG_BROWSER)
	  fprintf(stderr, "browser: squeak window sent\n");
#        endif
	  /* listen for commands */
	  aioEnable(browserPipes[0], 0, AIO_EXT);
	  aioHandle(browserPipes[0], npHandler, AIO_RX);
	}
      isConnectedToXServer= 1;
      aioEnable(stXfd, 0, AIO_EXT);
      aioHandle(stXfd, xHandler, AIO_RX);
    }
  return 0;
}

int forgetXDisplay(void)
{
  /* Initialise variables related to the X connection, and
     make the existing connection to the X Display invalid
     for any further access from this Squeak image.  Any socket
     connection to the X server is closed, but the server is
     not told to terminate any windows or X sessions.  This
     is used to support fork() for an existing Squeak image,
     where the child is expected to continue as a headless
     image, and the parent continues its normal execution. */

  displayName= 0;       /* name of display, or 0 for $DISPLAY   */
  stDisplay= null;      /* Squeak display                       */
  if (isConnectedToXServer)
    close(stXfd);
  if (stXfd >= 0)
    aioDisable(stXfd);
  stXfd= -1;		/* X connection file descriptor         */
  stParent= null;
  stWindow= null;       /* Squeak window                        */
  isConnectedToXServer= 0;
  return 0;
}


int disconnectXDisplay(void)
{
  if (isConnectedToXServer)
    {
      XSync(stDisplay, False);
      handleEvents();
      XDestroyWindow(stDisplay, stWindow);
      if (browserWindow == 0)
	XDestroyWindow(stDisplay, stParent);
      XCloseDisplay(stDisplay);
    }
  forgetXDisplay();
  return 0;
}


/*** OpenGL ***/

static void *display_ioGetDisplay(void)	{ return (void *)stDisplay; }
static void *display_ioGetWindow(void)	{ return (void *)stWindow; }

#if (!USE_X11_GLX)

static sqInt display_ioGLinitialise(void) { return 0; }
static sqInt display_ioGLcreateRenderer(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags) { return 0; }
static void display_ioGLdestroyRenderer(glRenderer *r) {}
static void display_ioGLswapBuffers(glRenderer *r) {}
static sqInt display_ioGLmakeCurrentRenderer(glRenderer *r) { return 0; }
static void display_ioGLsetBufferRect(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h) {}

#else

# include "B3DAcceleratorPlugin.h"
# include "sqOpenGLRenderer.h"

# include <GL/gl.h>
# include <GL/glx.h>

static void printVisual(XVisualInfo* visinfo);
static void listVisuals();

static int visualAttributes[]= {
  GLX_STENCIL_SIZE,     0,  /* filled in later - must be first item! */
  GLX_ALPHA_SIZE,       1,  /* filled in later - must be second item! */
  GLX_RGBA,                 /* no indexed colors */
  GLX_DOUBLEBUFFER,         /* will swap */
  GLX_LEVEL,            0,  /* frame buffer, not overlay */
  GLX_DEPTH_SIZE,       16, /* decent depth */   
  GLX_AUX_BUFFERS,      0,  /* no aux buffers */
  GLX_ACCUM_RED_SIZE,   0,  /* no accumulation */
  GLX_ACCUM_GREEN_SIZE, 0,
  GLX_ACCUM_BLUE_SIZE,  0,
  GLX_ACCUM_ALPHA_SIZE, 0,
  None
};

extern int verboseLevel;

static sqInt display_ioGLinitialise(void) { return 1; }

#define _renderWindow(R)	((R)->drawable)
#define renderWindow(R)		((Window)(R)->drawable)
#define _renderContext(R)	((R)->context)
#define renderContext(R)	((GLXContext)(R)->context)

static sqInt display_ioGLcreateRenderer(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags)
{
  XVisualInfo* visinfo= 0;

  if (flags & B3D_STENCIL_BUFFER)
    visualAttributes[1]= 1;
  else 
    visualAttributes[1]= 0;
  _renderWindow(r)= 0;
  _renderContext(r)= 0;

  DPRINTF(3, (fp, "---- Creating new renderer ----\r\r"));

  /* sanity checks */
  if (w < 0 || h < 0)
    {
      DPRINTF(1, (fp, "Negative extent (%i@%i)!\r", w, h));
      goto fail;
    }
  /* choose visual and create context */
  if (verboseLevel >= 3)
    listVisuals();
  {
    visinfo= glXChooseVisual(stDisplay, DefaultScreen(stDisplay), visualAttributes);
    if (!visinfo)
      {
	/* retry without alpha */
	visualAttributes[3]= 0;
	visinfo= glXChooseVisual(stDisplay, DefaultScreen(stDisplay), visualAttributes);
      }
    if (!visinfo)
      {
	DPRINTF(1, (fp, "No OpenGL visual found!\r"));
	goto fail;
      }
    DPRINTF(3, (fp, "\r#### Selected GLX visual ID 0x%lx ####\r", visinfo->visualid));
    if (verboseLevel >= 3)
      printVisual(visinfo);

    /* create context */
    if (!(_renderContext(r)= glXCreateContext(stDisplay, visinfo, 0, GL_TRUE)))
      {
	DPRINTF(1, (fp, "Creating GLX context failed!\r"));
	goto fail;
      }
    DPRINTF(3, (fp, "\r#### Created GLX context ####\r"  ));

    /* create window */
    {
      XSetWindowAttributes attributes;
      unsigned long valuemask= 0;

      attributes.colormap= XCreateColormap(stDisplay, DefaultRootWindow(stDisplay),
					   visinfo->visual, AllocNone);
      valuemask|= CWColormap;

      attributes.background_pixel= BlackPixel(stDisplay, DefaultScreen(stDisplay));
      valuemask|= CWBackPixel;

      if (!(_renderWindow(r)= (void *)XCreateWindow(stDisplay, stWindow, x, y, w, h, 0,
						    visinfo->depth, InputOutput, visinfo->visual, 
						    valuemask, &attributes)))
	{
	  DPRINTF(1, (fp, "Failed to create client window\r"));
	  goto fail;
	}
      XMapWindow(stDisplay, renderWindow(r));
    }
    DPRINTF(3, (fp, "\r#### Created window ####\r"  ));
    XFree(visinfo);
    visinfo= 0;
  }

  /* Make the context current */
  if (!glXMakeCurrent(stDisplay, renderWindow(r), renderContext(r)))
    {
      DPRINTF(1, (fp, "Failed to make context current\r"));
      goto fail;
    }
  DPRINTF(3, (fp, "\r### Renderer created! ###\r"));
  return 1;

 fail:
  DPRINTF(1, (fp, "OpenGL initialization failed\r"));
  if (visinfo)
    XFree(visinfo);
  if (renderContext(r))
    glXDestroyContext(stDisplay, renderContext(r));
  if (renderWindow(r))
    XDestroyWindow(stDisplay, renderWindow(r));
  return 0;
}


static void display_ioGLdestroyRenderer(glRenderer *r)
{
  glXDestroyContext(stDisplay, renderContext(r));
  XDestroyWindow(stDisplay, renderWindow(r));
}


static void display_ioGLswapBuffers(glRenderer *r)
{
  glXSwapBuffers(stDisplay, renderWindow(r));
}


static sqInt display_ioGLmakeCurrentRenderer(glRenderer *r)
{
  if (r)
    {
      if (!glXMakeCurrent(stDisplay, renderWindow(r), renderContext(r)))
	{
	  DPRINTF(1, (fp, "Failed to make context current\r"));
	  return 0;
	}
    }
  else
    glXMakeCurrent(stDisplay, 0, 0);
  return 1;
}


static void display_ioGLsetBufferRect(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h)
{
  XMoveResizeWindow(stDisplay, renderWindow(r), x, y, w, h);
}


/* GLX_CONFIG_CAVEAT might not be supported */
/* but the test below is worded so it does not matter */
# if !defined(GLX_CONFIG_CAVEAT)
#   define GLX_CONFIG_CAVEAT  0x20
#   define GLX_SLOW_CONFIG    0x8001
# endif

static void printVisual(XVisualInfo* visinfo)
{
  int isOpenGL; 
  glXGetConfig(stDisplay, visinfo, GLX_USE_GL, &isOpenGL);
  if (isOpenGL) 
    {
      int slow= 0;
      int red, green, blue, alpha, stencil, depth;
      glXGetConfig(stDisplay, visinfo, GLX_CONFIG_CAVEAT, &slow);
      glXGetConfig(stDisplay, visinfo, GLX_RED_SIZE,      &red);
      glXGetConfig(stDisplay, visinfo, GLX_GREEN_SIZE,    &green);
      glXGetConfig(stDisplay, visinfo, GLX_BLUE_SIZE,     &blue);
      glXGetConfig(stDisplay, visinfo, GLX_ALPHA_SIZE,    &alpha);
      glXGetConfig(stDisplay, visinfo, GLX_STENCIL_SIZE,  &stencil);
      glXGetConfig(stDisplay, visinfo, GLX_DEPTH_SIZE,    &depth);

      if (slow != GLX_SLOW_CONFIG)
        { DPRINTF(3, (fp,"===> OpenGL visual\r")) }
      else
        { DPRINTF(3, (fp,"---> slow OpenGL visual\r")) }

      DPRINTF(3, (fp,"rgbaBits = %i+%i+%i+%i\r", red, green, blue, alpha));
      DPRINTF(3, (fp,"stencilBits = %i\r", stencil));
      DPRINTF(3, (fp,"depthBits = %i\r", depth));
    }
  glGetError();	/* reset error flag */
}

static void listVisuals(void)
{
  XVisualInfo* visinfo;
  int nvisuals, i;
   
  visinfo= XGetVisualInfo(stDisplay, VisualNoMask, NULL, &nvisuals);

  for (i= 0; i < nvisuals; i++)
    {
      DPRINTF(3, (fp,"#### Checking pixel format (visual ID 0x%lx)\r", visinfo[i].visualid));
      printVisual(&visinfo[i]);
    }
  XFree(visinfo);
}

#endif /* defined(USE_X11_GLX) */



/*** browser plugin (from sqUnixMozilla.c) ***/

sqInt display_primitivePluginBrowserReady(void);
sqInt display_primitivePluginRequestURLStream(void);
sqInt display_primitivePluginRequestURL(void);
sqInt display_primitivePluginPostURL(void);
sqInt display_primitivePluginRequestFileHandle(void);
sqInt display_primitivePluginDestroyRequest(void);
sqInt display_primitivePluginRequestState(void);


static char *display_winSystemName(void)
{
  return "X11";
}


static void display_winInit(void)
{
  if (!strcmp(argVec[0], "headlessSqueak"))
    headless= 1;

#if defined(USE_XSHM)
  {
#  if defined(AT_EXIT)
    AT_EXIT(shmExit);
    AT_EXIT((void(*)(void))ioShutdownAllModules);
#  else
#    warning: cannot free display bitmap on exit!
#    warning: cannot shut down module system on exit!
#   endif
  }
#endif

  /* avoid compiler warning */
  (void)recordDragEvent;
}


static void display_winOpen(void)
{
#if defined(DEBUG_WINDOW)
  int sws= getSavedWindowSize();
  fprintf(stderr, "saved window size is %d %d\n", sws >> 16, sws & 0xffff);
#endif
  if (headless)
    forgetXDisplay();
  else
    openXDisplay();
}


static void display_winExit(void)
{
  disconnectXDisplay();
}


static int  display_winImageFind(char *buf, int len)	{ return 0; }
static void display_winImageNotFound(void)		{}

SqDisplayDefine(X11);


/*** module ***/


static void display_printUsage(void)
{
  printf("\nX11 <option>s:\n");
  printf("  -browserWindow <wid>  run in window <wid>\n");
  printf("  -browserPipes <r> <w> run as Browser plugin using descriptors <r> <w>\n");
  printf("  -cmdmod <n>           map Mod<n> to the Command key\n");
  printf("  -display <dpy>        display on <dpy> (default: $DISPLAY)\n");
  printf("  -fullscreen           occupy the entire screen\n");
  printf("  -headless             run in headless (no window) mode\n");
  printf("  -iconic               start up iconified\n");
  printf("  -lazy                 go to sleep when main window unmapped\n");
  printf("  -mapdelbs             map Delete key onto Backspace\n");
  printf("  -nointl               disable international keyboard support\n");
  printf("  -notitle              disable the Squeak window title bar\n");
  printf("  -noxdnd               disable X drag-and-drop protocol support\n");
  printf("  -optmod <n>           map Mod<n> to the Option key\n");
  printf("  -swapbtn              swap yellow (middle) and blue (right) buttons\n");
  printf("  -xasync               don't serialize display updates\n");
  printf("  -xshm                 use X shared memory extension\n");
#if (USE_X11_GLX)
  printf("  -glxdebug <n>         set GLX debug verbosity level to <n>\n");
#endif
}

static void display_printUsageNotes(void)
{
  printf("  Using `unix:0' for <dpy> may improve local display performance.\n");
  printf("  -xshm only works when Squeak is running on the X server host.\n");
}


static void display_parseEnvironment(void)
{
  char *ev= 0;

  if (getenv("LC_CTYPE") || getenv("LC_ALL"))
    x2sqKey= x2sqKeyInput;

  if (getenv("SQUEAK_LAZY"))		sleepWhenUnmapped= 1;
  if (getenv("SQUEAK_SPY"))		withSpy= 1;
  if (getenv("SQUEAK_NOINTL"))		x2sqKey= x2sqKeyPlain;
  if (getenv("SQUEAK_NOTITLE"))		noTitle= 1;
  if (getenv("SQUEAK_NOXDND"))		useXdnd= 0;
  if (getenv("SQUEAK_FULLSCREEN"))	fullScreen= 1;
  if (getenv("SQUEAK_ICONIC"))		iconified= 1;
  if (getenv("SQUEAK_MAPDELBS"))	mapDelBs= 1;
  if (getenv("SQUEAK_SWAPBTN"))		swapBtn= 1;
  if ((ev= getenv("SQUEAK_OPTMOD")))	optMapIndex= Mod1MapIndex + atoi(ev) - 1;
  if ((ev= getenv("SQUEAK_CMDMOD")))	cmdMapIndex= Mod1MapIndex + atoi(ev) - 1;
#if defined(USE_XSHM)
  if (getenv("SQUEAK_XSHM"))		useXshm= 1;
  if (getenv("SQUEAK_XASYNC"))		asyncUpdate= 1;
#endif
}



static int display_parseArgument(int argc, char **argv)
{
  int n= 1;
  char *arg= argv[0];

  if      (!strcmp(arg, "-headless"))	headless= 1;
#  if defined(USE_XSHM)
  else if (!strcmp(arg, "-xshm"))	useXshm= 1;
  else if (!strcmp(arg, "-xasync"))	asyncUpdate= 1;
#  endif
  else if (!strcmp(arg, "-lazy"))	sleepWhenUnmapped= 1;
  else if (!strcmp(arg, "-notitle"))	noTitle= 1;
  else if (!strcmp(arg, "-mapdelbs"))	mapDelBs= 1;
  else if (!strcmp(arg, "-swapbtn"))	swapBtn= 1;
  else if (!strcmp(arg, "-fullscreen"))	fullScreen= 1;
  else if (!strcmp(arg, "-iconic"))	iconified= 1;
  else if (!strcmp(arg, "-nointl"))	x2sqKey= x2sqKeyPlain;
  else if (!strcmp(arg, "-noxdnd"))	useXdnd= 0;
  else if (argv[1])	/* option requires an argument */
    {
      n= 2;
      if      (!strcmp(arg, "-display")) displayName= argv[1];
      else if (!strcmp(arg, "-optmod"))	 optMapIndex= Mod1MapIndex + atoi(argv[1]) - 1;
      else if (!strcmp(arg, "-cmdmod"))  cmdMapIndex= Mod1MapIndex + atoi(argv[1]) - 1;
      else if (!strcmp(arg, "-browserWindow"))
	{
	  sscanf(argv[1], "%lu", (unsigned long *)&browserWindow);
	  if (browserWindow == 0)
	    {
	      fprintf(stderr, "Error: invalid argument for `-browserWindow'\n");
	      exit(1);
	    }
	}
      else if (!strcmp(arg, "-browserPipes"))
	{
	  if (!argv[2]) return 0;
	  sscanf(argv[1], "%i", &browserPipes[0]);
	  sscanf(argv[2], "%i", &browserPipes[1]);
	  /* receive browserWindow */
#	 if defined(DEBUG_BROWSER)
	  fprintf(stderr, "browser: reading window\n");
#	 endif
	  if (sizeof(browserWindow) !=
	      read(browserPipes[0], (void *)&browserWindow, sizeof(browserWindow)))
	    {
	      perror("reading browserWindow");
	      exit(1);
	    }
#	 if defined(DEBUG_BROWSER)
	  fprintf(stderr, "browser: window = 0x%x\n", browserWindow);
#	 endif
	  return 3;
	}
#    if (USE_X11_GLX)
      else if (!strcmp(arg, "-glxdebug"))
	{
	  sscanf(argv[1], "%d", &verboseLevel);
	}
#    endif
      else
	n= 0;	/* not recognised */
    }
  else
    n= 0;
  return n;
}

static void *display_makeInterface(void)
{
  return &display_X11_itf;
}

#include "SqModule.h"

SqModuleDefine(display, X11);
