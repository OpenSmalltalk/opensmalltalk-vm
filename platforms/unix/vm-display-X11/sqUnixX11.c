/* sqUnixX11.c -- support for display via the X Window System.
 * 
 *   Copyright (C) 1996-2008 by Ian Piumarta and other authors/contributors
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
 *	Bert Freudenberg <bert@freudenbergs.de>
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

#if defined(ENABLE_FAST_BLT)
  /* XXX referring to plugin variables *requires* BitBitPlugin to be included by VMM as an internal plugin */
# if defined(__arm__)
#   include "../../../Cross/plugins/BitBltPlugin/BitBltArm.h"
# else
#   error configuration error
# endif
#endif

#if defined(ioMSecs)
# undef ioMSecs
#endif

#define NO_ICON
#define PRINT_PS_FORMS
#define SQ_FORM_FILENAME	"squeak-form.ppm"
#undef	FULL_UPDATE_ON_EXPOSE

#if 0 /* The following is a pain.  Leave it to the command line. */
# undef	DEBUG_FOCUS
# undef	DEBUG_XIM
# undef	DEBUG_CONV
# undef	DEBUG_EVENTS
# undef	DEBUG_SELECTIONS
# undef	DEBUG_BROWSER
# undef	DEBUG_WINDOW
# undef DEBUG_VISUAL
#endif

#define	USE_XICFONT_OPTION
#undef	USE_XICFONT_RESOURCE
#undef	USE_XICFONT_DEFAULT

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
#include <X11/keysym.h> /* /not/ keysymdef.h */
#if defined(SUGAR)
# include <X11/XF86keysym.h>
#endif
#if defined(USE_XSHM)
#  include <sys/ipc.h>
#  include <sys/shm.h>
#  include <X11/extensions/XShm.h>
#endif
#if defined(HAVE_LIBXRENDER)
#  include <X11/extensions/Xrender.h>
#endif
#if !defined(NO_ICON)
#  include "squeakIcon.bitmap"
#endif

#if defined(HAVE_DLFCN_H)
# include <dlfcn.h>
#endif

#include <assert.h>

#define isAligned(T, V)	(((V) % sizeof(T)) == 0)
#define align(T, V)	(((V) / sizeof(T)) * sizeof(T))

/*** Variables -- Imported from Virtual Machine ***/

/*** Variables -- X11 Related ***/

/* name of Squeak windows in Xrm and the WM */
#ifdef PharoVM
# define xResClass	"pharo-vm"
# define xResName	"Pharo"
#else
# define xResClass	"Squeak"
# define xResName	"squeak"
#endif

#ifdef PharoVM
# define VMOPTION(arg) "--"arg
#else
# define VMOPTION(arg) "-"arg
#endif

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
Atom		 stSelectionName= None; /* None or XdndSelection */
Atom		 stSelectionType= None; /* type to send selection (multiple types should be supported) */
XColor		 stColorBlack;		/* black pixel value in stColormap */
XColor		 stColorWhite;		/* white pixel value in stColormap */
int		 savedWindowOrigin= -1;	/* initial origin of window */

#define		 SELECTION_ATOM_COUNT  10
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
	 "INCR",
#define xaINCR		selectionAtoms[8]
	 "XdndSelection",
#define xaXdndSelection selectionAtoms[9]
};

Atom		 wmProtocolsAtom;	/* for window deletion messages */
Atom		 wmDeleteWindowAtom;

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

#if defined(SUGAR)
char		*sugarBundleId= 0;
char		*sugarActivityId= 0;
#endif

typedef int (*x2sqKey_t)(XKeyEvent *xevt, KeySym *symbolic);

static int x2sqKeyPlain(XKeyEvent *xevt, KeySym *symbolic);
static int x2sqKeyInput(XKeyEvent *xevt, KeySym *symbolic);
static int x2sqKeyCompositionInput(XKeyEvent *xevt, KeySym *symbolic);

static x2sqKey_t x2sqKey= x2sqKeyPlain;

static int multi_key_pressed = 0;
static KeySym multi_key_buffer = 0;
static int compositionInput = 0;

/* #define INIT_INPUT_WHEN_KEY_PRESSED */
/* #define INIT_INPUT_WHEN_FOCUSED_IN */
/* #define INIT_INPUT_WHEN_MAPPED */

#if defined(INIT_INPUT_WHEN_KEY_PRESSED)
#  undef INIT_INPUT_WHEN_FOCUSED_IN
#  undef INIT_INPUT_WHEN_MAPPED
#elif defined(INIT_INPUT_WHEN_FOCUSED_IN)
#  undef INIT_INPUT_WHEN_MAPPED
#elif !defined(INIT_INPUT_WHEN_MAPPED)
#  define INIT_INPUT_WHEN_MAPPED
#endif

#if defined(USE_XICFONT_RESOURCE)
#  include <X11/Xresource.h>
#  define xicFontResClass "XIC.FontSet"
#  define xicFontResName  "xic.fontSet"
#elif defined(USE_XICFONT_DEFAULT)
#  define xicFontDefRes  "fontSet"
#endif

#define  xicDefaultFont  "-*-*-medium-r-normal--*"

#if defined(USE_XICFONT_OPTION)
static char    *inputFontStr= xicDefaultFont;
#endif

static XFontSet inputFont= NULL;
static XIMStyle inputStyle;
static XIC      inputContext= 0;
static XPoint   inputSpot= {0, 0};

static unsigned char  inputString[128];
static unsigned char *inputBuf= inputString;
static unsigned char *pendingKey= NULL;
static int	      inputCount= 0;
/* static int	      inputSymbol= 0; */

static void initInputI18n();

#if !defined(INIT_INPUT_WHEN_KEY_PRESSED)
static void initInputNone();
static void (*initInput)()= initInputNone;
#endif

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

#define recordKeystroke(ignored) 0

#include "sqUnixEvent.c"

#ifdef DEBUG_CONV
# define DCONV_PRINTF(...) printf(__VA_ARGS__)
# define DCONV_FPRINTF(...) fprintf(stderr,__VA_ARGS__)
#else
# define DCONV_PRINTF(...) 0
# define DCONV_FPRINTF(...) 0
#endif


#define SqueakWhite	0
#define SqueakBlack	1

int sleepWhenUnmapped=	0;
int noTitle=		0;
int fullScreen=		0;
int fullScreenDirect=	0;
int iconified=		0;
int withSpy=		0;


/*xxx REMOVE REFS TO THESE IN sqUnixSound*.* */

void feedback(int offset, int pixel)	{}
int inModalLoop= 0, dpyPitch= 0, dpyPixels= 0;

/* we are interested in these events...
 */
#define EVENTMASK   	ButtonPressMask | ButtonReleaseMask | \
			KeyPressMask | KeyReleaseMask | PointerMotionMask | \
		      	ExposureMask | VisibilityChangeMask | FocusChangeMask

#define WM_EVENTMASK	StructureNotifyMask | FocusChangeMask 

/* largest X selection that we will attempt to handle (bytes) */
#define MAX_SELECTION_SIZE	100*1024

/* longest we're prepared to wait for the selection owner to convert it (seconds) */
#define SELECTION_TIMEOUT	3

/* To coordinate default window title with dndLaunchFile */
static char *defaultWindowLabel = shortImageName;
static long launchDropTimeoutMsecs = 1000; /* 1 second default launch drop timeout */


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

/* Selection functions */

typedef struct _SelectionChunk
{
  unsigned char		 *data;
  size_t		  size;
  struct _SelectionChunk *next;
  struct _SelectionChunk *last;
} SelectionChunk;

static int   sendSelection(XSelectionRequestEvent *requestEv, int isMultiple);
static void  getSelection(void);
static char *getSelectionData(Atom selection, Atom target, size_t *bytes);
static char *getSelectionFrom(Atom source);
static int   translateCode(KeySym symbolic, int *modp, XKeyEvent *evt);

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


#if defined(DEBUG_VISUAL)
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
/*if (count + 1 > stPrimarySelectionSize)*/		/* XXX test removed for dnd out; maybe should be left in? XXX */
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

  /* XSelectionRequestEvent is used for both clipboard and Xdnd.  In
   * the case of Xdnd, XSelectionEvent is answered asynchronously
   * after the image prepares data because target (data type) is
   * informed only when the SelectionRequest is sent.
   * dndOutSelectionRequest() sends a SQDragRequest event to the image
   * for that.  Finally, the image calls
   * HandMorph>>primitiveDndOutSend: to send the SelectionRequest.
   */
  if (xaXdndSelection == requestEv->selection) return 0;

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
  else if ((stSelectionType == requestEv->target) && (None != stSelectionType))
    {
      /* In case of type other than image/png */
      XChangeProperty(requestEv->display, requestEv->requestor,
		      targetProperty, requestEv->target,
		      8, PropModeReplace,
		      (const unsigned char *) stPrimarySelection,
		      stPrimarySelectionSize);
    }
  else if (xaTargets == requestEv->target)
    {
      /* If we don't report COMPOUND_TEXT in this list, KMail (and maybe other
       * Qt/KDE apps) don't accept pastes from Squeak. Of course, they'll use
       * UTF8_STRING anyway... */
      Atom targets[7];
      int targetsSize= 6;
      targets[0]= xaTargets;
      targets[1]= xaMultiple;
      targets[2]= xaTimestamp;	        /* required by ICCCM */
      targets[3]= xaUTF8String;
      targets[4]= XA_STRING;
      targets[5]= xaCompoundText;
      if (stSelectionType != None)
	{
	  targetsSize += 1;
	  targets[6]= stSelectionType;
	}
      xError= XChangeProperty(requestEv->display, requestEv->requestor,
                              targetProperty, XA_ATOM,
                              32, PropModeReplace, (unsigned char *)targets, targetsSize);
    }
  else if (xaCompoundText == requestEv->target)
    {
      /* COMPOUND_TEXT is handled here for older clients that don't handle UTF-8 */
      XTextProperty  textProperty;
      char          *list[]= { stPrimarySelection, NULL };

      if (localeEncoding == sqTextEncoding)
	xError= XmbTextListToTextProperty(requestEv->display, list, 1, XCompoundTextStyle, &textProperty);
#    if defined(X_HAVE_UTF8_STRING)
      else if (uxUTF8Encoding == sqTextEncoding)
	xError= Xutf8TextListToTextProperty(requestEv->display, list, 1, XCompoundTextStyle, &textProperty);
#    endif
      else
	{
	  int	len= strlen(stPrimarySelection);
	  char *buf= (char *)malloc(len * 3 + 1);

	  list[0]= buf;
	  sq2uxText(stPrimarySelection, len, buf, len * 3 + 1, 1);
	  xError= XmbTextListToTextProperty(requestEv->display, list, 1, XCompoundTextStyle, &textProperty);
	  free(buf);
	}

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


static void getSelection(void)
{
  char *data;

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
}


static char *getSelectionFrom(Atom source)
{
  char * data= NULL;
  size_t bytes= 0;

  /* request the selection */
  Atom target= textEncodingUTF8 ? xaUTF8String : (localeEncoding ? xaCompoundText : XA_STRING);

  data= getSelectionData(source, target, &bytes);

  if (bytes == 0)
    return stEmptySelection;
  
  /* convert the encoding if necessary */
  if (bytes && allocateSelectionBuffer(bytes))
    {
      if (textEncodingUTF8)
	bytes= ux2sqUTF8(data, bytes, stPrimarySelection, bytes + 1, 1);
      else if (localeEncoding)
	{
	  char        **strList= NULL;
	  int           i, n, s= 0;
	  XTextProperty textProperty;

	  textProperty.encoding= xaCompoundText;
	  textProperty.format=   8;
	  textProperty.value=    data;
	  textProperty.nitems=   bytes;
# if defined(X_HAVE_UTF8_STRING)
	  if (uxUTF8Encoding == sqTextEncoding)
	    Xutf8TextPropertyToTextList(stDisplay, &textProperty, &strList, &n);
	  else
# endif
	    XmbTextPropertyToTextList(stDisplay, &textProperty, &strList, &n);
	  for (i= 0;  i < n;  ++i)
	    s+= strlen(strList[i]);
	  if (s > bytes)
	    {
	      bytes= min(s, MAX_SELECTION_SIZE - 1);
	      if (! allocateSelectionBuffer(bytes))
		{
#                if defined(DEBUG_SELECTIONS)
		  fprintf(stderr, "no bytes\n");
#                endif    
		  goto nobytes;
		}
	    }
	  if ((localeEncoding == sqTextEncoding)
#            if defined(X_HAVE_UTF8_STRING)
	      || (uxUTF8Encoding == sqTextEncoding)
#            endif
	      )
	    {
	      strcpy(stPrimarySelection, strList[0]);
	      for (i= 1;  i < n;  ++i)
		strcat(stPrimarySelection, strList[i]);
	    }
	  else
	    {
	      char *to= stPrimarySelection;
	      for (i= 0;  i < n - 1;  ++i)
		{
		  s= strlen(strList[i]);
		  s= ux2sqText(strList[i], s, to, bytes, 0);
		  bytes -= s;
		  to    += s;
		}
	      s= strlen(strList[n - 1]);
	      s= ux2sqText(strList[n - 1], s, to, bytes + 1, 1);
	    }
	  if (strList)
	    XFreeStringList(strList);

	  /* translate LF -> CR */
	  for (i= 0;  stPrimarySelection[i] != '\0';  ++i)
	    if ('\n' == stPrimarySelection[i])
	      stPrimarySelection[i]= '\r';
	}
      else
	bytes= ux2sqText(data, bytes, stPrimarySelection, bytes + 1, 1);
      /* wrong type check was omitted */
    }
  else
    {
#     if defined(DEBUG_SELECTIONS)
      fprintf(stderr, "no bytes\n");
#     endif
    }
 nobytes:
#  if defined(DEBUG_SELECTIONS)
  fprintf(stderr, "selection=");
  dumpSelectionData(stPrimarySelection, bytes, 1);
#  endif

  XFree((void *)data);
  return stPrimarySelection;
}


/* Wait specific event to get property change.
 * Return 1 if success.
 */
static int waitNotify(XEvent *ev, int (*condition)(XEvent *ev))
{
  fd_set  fdMask;

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

	  while (((status= select(FD_SETSIZE, &fdMask, 0, 0, &timeout)) < 0) && (errno == EINTR))
	    ;
	  if (status < 0)
	    {
	      perror("select(stDisplay)");
	      return 0; /* stEmptySelection */
	    }
	  if (status == 0)
	    {
#           if defined(DEBUG_SELECTIONS)
	      fprintf(stderr, "getSelection: select() timeout\n");
#           endif
	      if (isConnectedToXServer)
		XBell(stDisplay, 0);
	      return 0;
	    }
	}

      XNextEvent(stDisplay, ev);
      switch (ev->type)
	{
	case ConfigureNotify:
	  noteResize(ev->xconfigure.width, ev->xconfigure.height);
	  break;

        /* this is necessary so that we can supply our own selection when we
	   are the requestor -- this could (should) be optimised to return the
	   stored selection value instead! */
	case SelectionRequest:
#	 if defined(DEBUG_SELECTIONS)
	  fprintf(stderr, "getSelection: sending own selection\n");
#	 endif
	  sendSelection(&ev->xselectionrequest, 0);
	  break;

#       if defined(USE_XSHM)
	default:
	  if (ev->type == completionType)
	    --completions;
#       endif
	}
    }
  while (!condition(ev));

  return 1;
}

static int waitSelectionNotify(XEvent *ev)
{
  return ev->type == SelectionNotify;
}

static int waitPropertyNotify(XEvent *ev)
{
  return (ev->type == PropertyNotify) && (ev->xproperty.state == PropertyNewValue);
}


/* SelectionChunk functions.
 * SelectionChunk remembers (not copies) buffers from selections.
 * It is useful to handle partial data transfar with XGetWindowProperty.
 */

static SelectionChunk *newSelectionChunk(void)
{
  SelectionChunk * chunk= malloc(sizeof(SelectionChunk));
  chunk->data= NULL;
  chunk->size= 0;
  chunk->next= NULL;
  chunk->last=chunk;
  return chunk;
}

static void destroySelectionChunk(SelectionChunk *chunk)
{
  SelectionChunk * i;
  for (i= chunk; i != NULL;) {
    SelectionChunk * next= i->next;
    XFree(i->data);
    free(i);
    i= next;
  }
}

static void addSelectionChunk(SelectionChunk *chunk, unsigned char *src, size_t size)
{
  chunk->last->data= src;
  chunk->last->size= size;
  chunk->last->next= newSelectionChunk();
  chunk->last= chunk->last->next;
}

static size_t sizeSelectionChunk(SelectionChunk *chunk)
{
  size_t totalSize= 0;
  SelectionChunk * i;
  for (i= chunk; i != NULL; i= i->next)
    totalSize += i->size;
  return totalSize;
}

static void copySelectionChunk(SelectionChunk *chunk, char *dest)
{
  SelectionChunk *i;
  char *j= dest;
  for (i= chunk;  i;  j+= i->size, i= i->next)
    memcpy(j, i->data, i->size);
}


/* get the value of the selection from the containing property */
static size_t getSelectionProperty(SelectionChunk *chunk, Window requestor, Atom property, Atom *actualType)
{
  unsigned long bytesAfter= 0, nitems= 0, nread= 0;
  unsigned char *data= 0;
  size_t size;
  int format;
  
  do
    {
      XGetWindowProperty(stDisplay, requestor, property,
			 nread, (MAX_SELECTION_SIZE / 4),
			 True, AnyPropertyType,
			 actualType, &format, &nitems, &bytesAfter,
			 &data);
      
      size= nitems * format / 8;
      nread += size / 4;
      
#    if defined(DEBUG_SELECTIONS)
      fprintf(stderr, "getprop type ");
      printAtomName(*actualType);
      fprintf(stderr, " format %d nitems %ld bytesAfter %ld\ndata=",
	      format, nitems, bytesAfter);
      dumpSelectionData((char *) data, nitems, 1);
#    endif

      addSelectionChunk(chunk, data, size);
    }
  while (bytesAfter);

  return size;
}

static void getSelectionIncr(SelectionChunk *chunk, Window requestor, Atom property)
{
  XEvent ev;
  size_t size;
  Atom   actualType;
  do {
    fprintf(stderr, "getSelectionIncr: wait next chunk\n");
    waitNotify(&ev, waitPropertyNotify);
    size= getSelectionProperty(chunk, requestor, property, &actualType);
  } while (size > 0);
}

/* Read selection data from the target in the selection,
 * or chunk of zero length if unavailable.
 * Caller must free the returned data with destroySelectionChunk().
 */
static void getSelectionChunk(SelectionChunk *chunk, Atom selection, Atom target)
{
  Time	 timestamp= getXTimestamp();
  XEvent evt;
  int    success;
  Atom   actualType;
  Window requestor;
  Atom   property;

  XDeleteProperty(stDisplay, stWindow, selectionAtom);
  XConvertSelection(stDisplay, selection, target, selectionAtom, stWindow, timestamp);

  success= waitNotify(&evt, waitSelectionNotify);
  if (success == 0) return;
  requestor= evt.xselection.requestor;
  property= evt.xselection.property;

  /* check if the selection was refused */
  if (None == property)
    {
#    if defined(DEBUG_SELECTIONS)
      fprintf(stderr, "getSelection: xselection.property == None\n");
#    endif
      if (isConnectedToXServer)
	XBell(stDisplay, 0);
      return;
    }

  getSelectionProperty(chunk, requestor, property, &actualType);

  if (actualType == xaINCR)
    {
      destroySelectionChunk(chunk);
      chunk= newSelectionChunk();
      getSelectionIncr(chunk, requestor, property);
    }
}

/* Get selection data from the target in the selection.
 * Return NULL if there is no selection data.
 * Caller must free the return data.
 */
static char *getSelectionData(Atom selection, Atom target, size_t *bytes)
{
  char *data;
  SelectionChunk *chunk= newSelectionChunk();
  getSelectionChunk(chunk, selection, target);
  *bytes= sizeSelectionChunk(chunk);
  data= malloc(*bytes);
  copySelectionChunk(chunk, data);
  destroySelectionChunk(chunk);
  return data;
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
  stSelectionType= None;
}


static Atom stringToAtom(char *target, size_t size)
{
  char *formatString;
  Atom  result;
 
  formatString= (char *) malloc(size + 1);
  memcpy(formatString, target, size);
  formatString[size]= 0;
  result= XInternAtom(stDisplay, formatString, False);
  free(formatString);
  return result;
}


/* Prepare to write typed data for the selection; add a 0-terminator
 * at end of the data for safety.
 *
 * selectionName : None (CLIPBOARD and PRIMARY), or XdndSelection
 * type : None (various string), or target type ('image/png' etc.)
 * data : data
 * ndata : size of the data
 * typeName : 0 (various string), or target name ('image/png' etc.)
 * ntypeName : length of typeName
 * isDnd : true if XdndSelection, false if CLIPBOARD or PRIMARY
 * isClaiming : true if XGetSelectionOwner is needed
 */
static void display_clipboardWriteWithType(char *data, size_t ndata, char *typeName, size_t nTypeName, int isDnd, int isClaiming)
{
  if (allocateSelectionBuffer(ndata))
    {
      Atom type= stringToAtom(typeName, nTypeName);
      stSelectionName= isDnd ? xaXdndSelection : None;
      memcpy((void *)stPrimarySelection, data, ndata);
      stPrimarySelection[ndata]= '\0';
      stSelectionType= type;
      if (isClaiming) claimSelection();
    }
}


static sqInt display_clipboardSize(void)
{
  if (stOwnsClipboard) return 0;
  getSelection();
  return stPrimarySelectionSize;
}


static sqInt display_clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  display_clipboardWriteWithType(pointerForOop(byteArrayIndex + startIndex), count, NULL, 0, 0, 1);
  return 0;
}

/* Transfer the X selection into the given byte array; optimise local requests. */
/* Call clipboardSize() or clipboardSizeWithType() before this. */

static sqInt display_clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  int clipSize;

  if (!isConnectedToXServer)
    return 0;
  clipSize= min(count, stPrimarySelectionSize);
#if defined(DEBUG_SELECTIONS)
  fprintf(stderr, "clipboard read: %d selectionSize %d\n", count, stPrimarySelectionSize);
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
  extern sqInt isPointers(sqInt);
  extern sqInt lengthOf(sqInt);
  extern sqInt fetchPointerofObject(sqInt, sqInt);

  sqInt displayObj= displayObject();

  if (isPointers(displayObj) && lengthOf(displayObj) >= 4)
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
#    if DEBUG_KEYBOARD_EVENTS
      fprintf(stderr, "  8-bit: %d=%02x [%c->%c]\n", charCode, charCode,
	      (char *)uxXWinEncoding, (char *)sqTextEncoding);
#    endif
    }
  return charCode;
}

char *setLocale(char *localeName, size_t len)
{
  char  name[len + 1];
  char *locale;
  if (inputContext)
    {
      XIM im= XIMOfIC(inputContext);
      XDestroyIC(inputContext);
      if (im) XCloseIM(im);
    }
  strncpy(name, localeName, len);
  name[len]= '\0';
  if ((locale= setlocale(LC_CTYPE, name)))
    {
      setLocaleEncoding(locale);
      initInputI18n();
      return locale;
    }
  else
    {
      if (localeEncoding)
	{
	  freeEncoding(localeEncoding);
	  localeEncoding= NULL;
	}
      inputContext= 0;
      x2sqKey= x2sqKeyPlain;
      if (len)
	fprintf(stderr, "setlocale() failed for %s\n", name);
      else
 	fprintf(stderr, "setlocale() failed (check values of LC_CTYPE, LANG and LC_ALL)\n");
      return NULL;
    }
}

int setCompositionFocus(int focus)
{
  if (!inputContext)
    return 0;
  if (focus)
    XSetICFocus(inputContext);
  else
    XUnsetICFocus(inputContext);
  return 1;
}

int setCompositionWindowPosition(int x, int y)
{
  int ret= 1;
  inputSpot.x= x;
  inputSpot.y= y;
  if (inputContext && (inputStyle & XIMPreeditPosition))
    {
      XVaNestedList vlist= XVaCreateNestedList(0, XNSpotLocation, &inputSpot, NULL);
#    if defined(DEBUG_XIM)
      fprintf(stderr, "Set Preedit Spot %d %d\n", x, y);
#    endif
      if (XSetICValues(inputContext, XNPreeditAttributes, vlist, NULL))
	{
	  fprintf(stderr, "Failed to Set Preedit Spot\n");
	  ret= 0;
	}
      XFree(vlist);
    }
  return ret;
}

static void setInputContextArea(void)
{
    XWindowAttributes wa;
    XVaNestedList     vlist;
    XRectangle        pa, sa, *rect;
    if ((!inputContext) || (inputStyle & XIMPreeditPosition))
      return;
    if (inputStyle & XIMPreeditArea)
      {
	XGetWindowAttributes(stDisplay, stWindow, &wa);
#      if defined(DEBUG_XIM)
	fprintf(stderr, "window geometry %d %d %d %d %d\n", wa.x, wa.y, wa.width, wa.height, wa.border_width);
#      endif
	wa.width  -= wa.border_width * 2;
	wa.height -= wa.border_width * 2;
	vlist= XVaCreateNestedList(0, XNAreaNeeded, &rect, NULL);
	if (XGetICValues(inputContext, XNPreeditAttributes, vlist, NULL))
	  {
	    fprintf(stderr, "Failed to Get Needed PreeditArea\n");
	    pa.x= pa.y= pa.width= pa.height= 0;
	  }
	else
	  {
	    pa= *rect;
#          if defined(DEBUG_XIM)
	    fprintf(stderr, "PreeditArea needs %d %d %u %u\n", pa.x, pa.y, pa.width, pa.height);
#          endif
	  }
	XFree(vlist);
	if (inputStyle & XIMStatusArea)
	  {
	    static int minWidth= 0, minHeight= 0;
	    static XFontSetExtents *extents= NULL;
	    if (!extents) 
	      {
		extents= XExtentsOfFontSet(inputFont);
		minWidth= extents->max_logical_extent.width * 3;
		minHeight= extents->max_logical_extent.height - extents->max_logical_extent.y;
	      }
	    vlist= XVaCreateNestedList(0, XNAreaNeeded, &rect, NULL);
	    if (XGetICValues(inputContext, XNStatusAttributes, vlist, NULL))
	      {
		fprintf(stderr, "Failed to Get Needed StatusArea\n");
		sa.x= sa.y= sa.width= sa.height= 0;
	      }
	    else
	      {
		sa= *rect;
#              if defined(DEBUG_XIM)
		fprintf(stderr, "StatusArea needs %d %d %u %u\n", sa.x, sa.y, sa.width, sa.height);
#              endif
	      }
	    XFree(vlist);
	    if (minHeight > sa.height)
	      pa.height= sa.height= minHeight;
	    if (minWidth > sa.width)
	      sa.width= minWidth;
	    wa.width -= sa.width;
	    if (wa.width > pa.width)
	      pa.width= wa.width;
	    sa.x= wa.border_width;
	    pa.x= sa.x + sa.width;
	    sa.y= pa.y= wa.height + wa.border_width - sa.height;
	    vlist= XVaCreateNestedList(0, XNArea, &sa, NULL);
	    if (XSetICValues(inputContext, XNStatusAttributes, vlist, NULL))
	      {
		fprintf(stderr, "Failed to Set StatusArea %d %d %u %u\n", sa.x, sa.y, sa.width, sa.height);
	      }
#          if defined(DEBUG_XIM)
	    else
	      {
		XFree(vlist);
		vlist= XVaCreateNestedList(0, XNArea, &rect, NULL);
		XGetICValues(inputContext, XNStatusAttributes, vlist, NULL);
		fprintf(stderr, "Setted StatusArea %d %d %u %u\n", rect->x, rect->y, rect->width, rect->height);
	      }
#          endif
	    XFree(vlist);
	  }
	else
	  {
	    pa.x= wa.border_width;
	    pa.y= wa.border_width;
	    if (wa.width > pa.width)
	      pa.width= wa.width;
	    if (wa.height > pa.height)
	      pa.height= wa.height;
	  }
	vlist= XVaCreateNestedList(0, XNArea, &pa, NULL);
	if (XSetICValues(inputContext, XNPreeditAttributes, vlist, NULL))
	  {
	    fprintf(stderr, "Failed to Set PreeditArea %d %d %u %u\n", pa.x, pa.y, pa.width, pa.height);
	  }
	XFree(vlist);
    }
}

# if !defined(INIT_INPUT_WHEN_KEY_PRESSED)
static void initInputNone(void)
{
  /* do nothing */
}
# endif

static void initInputI18n(void)
{
  XIM im;
# if !defined(INIT_INPUT_WHEN_KEY_PRESSED)
  initInput= initInputNone;
# endif

  if (!compositionInput)
    return;

  x2sqKey= x2sqKeyPlain;
  if (XSupportsLocale() != True)
    fprintf(stderr, "XSupportsLocale() failed.\n");
  else if (!XSetLocaleModifiers(""))
    fprintf(stderr, "XSetLocaleModifiers() failed.\n");
  else if (!(im= XOpenIM(stDisplay, 0, 0, 0)))
    fprintf(stderr, "XOpenIM() failed\n");
  else
    {
      static const XIMStyle pstyle[]= { XIMPreeditPosition, XIMPreeditArea, XIMPreeditNothing, XIMPreeditNone };
      static const XIMStyle sstyle[]= { XIMStatusArea, XIMStatusNothing, XIMStatusNone, 0 };
      XIMStyles      *styles;
      int             i, j, k;
      XVaNestedList   vlist;
# if defined(DEBUG_XIM)
      static const char const *stylename[]= { "Position", "Area", "Nothing", "None" };
      char *locale= XLocaleOfIM(im);
      fprintf(stderr, "Locale of im is %s\n", locale); 
# endif
      XGetIMValues(im, XNQueryInputStyle, &styles, NULL);
      for (i= 0;  i < styles->count_styles;  ++i)
	for (j= 0;  j < sizeof(pstyle)/sizeof(XIMStyle);  ++j)
	  for (k= 0;  k < sizeof(pstyle)/sizeof(XIMStyle);  ++k)
	    {
	      inputStyle= (pstyle[j] | sstyle[k]);
	      if (styles->supported_styles[i] == inputStyle)
		goto foundStyle;
	    }
      fprintf(stderr, "Preffered XIMStyles are not Supported.\n");
      return;

    foundStyle:
# if defined(DEBUG_XIM)
      fprintf(stderr, "XIMStyle is Preedit%s and Status%s\n", stylename[j], stylename[k + 1]);
# endif
      if (!inputFont)
	{
	  char      **misscharset, *tmpstr;
# if defined(USE_XICFONT_RESOURCE)
	  XrmDatabase db;
# endif
# if !defined(USE_XICFONT_OPTION)
#  if defined(USE_XICFONT_RESOURCE) || defined(USE_XICFONT_DEFAULT)
	  char       *inputFontStr;
#  else
	  static char const *inputFontStr= xicDefaultFont;
#  endif
# else
	  if (!inputFontStr)
# endif
	    {
#            if defined(USE_XICFONT_RESOURCE)
	      static int rmInitialized= 0;

	      inputFontStr= xicDefaultFont;

	      if (!rmInitialized)
		{
		  XrmInitialize();
		  rmInitialized= 1;
		}
	      if ((tmpstr= XResourceManagerString(stDisplay)))
		{
		  XrmValue val;
		  char    *type;
		  db= XrmGetStringDatabase(tmpstr);
		  if (XrmGetResource(db, xResName  "." xicFontResName, xResClass "." xicFontResClass, &type, &val))
		    inputFontStr= (char*)val.addr;
		}
#            elif defined(USE_XICFONT_DEFAULT)
	      inputFontStr= XGetDefault(stDisplay, xResName, xicFontDefRes);
	      if (!inputFontStr)
		inputFontStr= xicDefaultFont;
#            endif
	    }
	  inputFont= XCreateFontSet(stDisplay, inputFontStr, &misscharset, &k, &tmpstr);
# if defined(USE_XICFONT_RESOURCE)
	  /* if db is NULL, XrmDestroyDatabase returns immediatelly */
	  XrmDestroyDatabase(db);
# endif
	  if (!inputFont)
	    {
	      fprintf(stderr, "XCreateFontSet() failed for \"%s\"\n", inputFontStr);
	      /* XNFontSet is mandatory */
	      return;
	    }
	}
      vlist= XVaCreateNestedList(0,
				 XNFontSet,       inputFont,
				 XNSpotLocation, &inputSpot,
				 NULL);
      inputContext= XCreateIC(im,
			      XNInputStyle,        inputStyle,
			      XNClientWindow,      stWindow,
			      XNFocusWindow,       stWindow,
			      XNPreeditAttributes, vlist,
			      XNStatusAttributes,  vlist,
			      NULL);
      XFree(vlist);
      if (inputContext)
	{
	  unsigned int mask;
	  XWindowAttributes xwa;
	  XGetWindowAttributes(stDisplay, stWindow, &xwa);
	  XGetICValues(inputContext, XNFilterEvents, &mask, NULL);
	  XSelectInput(stDisplay, stWindow, mask | xwa.your_event_mask);
# if defined(INIT_INPUT_WHEN_KEY_PRESSED)
	  setInputContextArea();
# endif
	  x2sqKey= x2sqKeyCompositionInput;
	}
      else
	fprintf(stderr, "XCreateIC() failed\n");
    }
}

/* Try to read keys into string using lookup function.
   If buffer overflows, allocate another buffer.
   Answer the buffer, that the caller must free if it != string.
*/

static unsigned char *lookupKeys(int (*lookup)(XIC, XKeyPressedEvent*, char*, int, KeySym*, Status*),
				 XKeyEvent *xevt,
				 unsigned char *string, int size,
				 int *count, KeySym *symbolic, Status *status)
{
  *count= lookup(inputContext, (XKeyPressedEvent *)xevt, string, size, symbolic, status);
  if (*status == XBufferOverflow)
    {
      unsigned char *buf= (unsigned char*)malloc((size_t)(*count * sizeof(unsigned char)));
      if (buf)
	*count= lookup(inputContext, (XKeyPressedEvent *)xevt, buf, *count, symbolic, status);
      else
	fprintf(stderr, "lookupKeys: out of memory\n");
      return buf;
    }
# if defined(DEBUG_XIM)
  fprintf(stderr, "lookupKeys: '%s'\n", string);
# endif 
  return string;
}

/*
  Answer 1 if some keys are still pending.
*/

static int recordPendingKeys(void)
{
  if (compositionInput)
    {
      if (inputCount <= 0) {
	if (inputBuf != inputString) {
	  free(inputBuf);
	  inputBuf= inputString;
	}
	return 0;
      }
    
      int utf32= 0;
      while (inputCount > 0) {
# if defined(DEBUG_XIM)
	fprintf(stderr, "%3d pending key 0x%02x\n", inputCount, *pendingKey);
# endif
	/* 110x xxxx 10xx xxxx */
	if (inputCount >= 2 &&
    	    pendingKey[0] >= 0xc0 && pendingKey[0] <= 0xdf && 
    	    pendingKey[1] >= 0x80 && pendingKey[1] <= 0xbf)
	  {
	    utf32= ((pendingKey[0] & 0x1f) << 6) |
		    (pendingKey[1] & 0x3f);
	    recordKeyboardEvent(0, EventKeyDown, modifierState, utf32);
	    recordKeyboardEvent(0, EventKeyChar, modifierState, utf32);
	    pendingKey += 2;
	    inputCount -= 2;
	  }
	/* 1110 xxxx 10xx xxxx 10xx xxxx */
	else if (inputCount >= 3 &&
		 pendingKey[0] >= 0xe0 && pendingKey[0] <= 0xef && 
		 pendingKey[1] >= 0x80 && pendingKey[1] <= 0xbf && 
		 pendingKey[2] >= 0x80 && pendingKey[2] <= 0xbf)
	  {
	    utf32= ((pendingKey[0]  & 0x0f) << 12) | 
		    ((pendingKey[1] & 0x3f) << 6) | 
		    (pendingKey[2] & 0x3f);
	    recordKeyboardEvent(0, EventKeyDown, modifierState, utf32);
	    recordKeyboardEvent(0, EventKeyChar, modifierState, utf32);
	    pendingKey += 3;
	    inputCount -= 3;
	  }
	/* 1111 0xxx 10xx xxxx 10xx xxxx 10xx xxxx */
	else if (inputCount >= 4 &&
		 pendingKey[0] >= 0xf0 && pendingKey[0] <= 0xf7 && 
		 pendingKey[1] >= 0x80 && pendingKey[1] <= 0xbf && 
		 pendingKey[2] >= 0x80 && pendingKey[2] <= 0xbf && 
		 pendingKey[3] >= 0x80 && pendingKey[3] <= 0xbf)
	  {
	    utf32= ((pendingKey[0] & 0x07) << 18) | 
		    ((pendingKey[1] & 0x3f) << 12) |
		    ((pendingKey[2] & 0x3f) << 6) |
		    (pendingKey[3] & 0x3f);
	    recordKeyboardEvent(0, EventKeyDown, modifierState, utf32);
	    recordKeyboardEvent(0, EventKeyChar, modifierState, utf32);
	    pendingKey += 4;
	    inputCount -= 4;
	  }
	else
	  {
	    recordKeyboardEvent(*pendingKey, EventKeyDown, modifierState, 0);
	    recordKeyboardEvent(*pendingKey, EventKeyChar, modifierState, 0);
	    recordKeystroke(*pendingKey); /* DEPRECATED */
	    pendingKey++;
	    inputCount--;
	  }
      }
      return 0;
    }
  else
    {
      if (inputCount > 0)
	{
	  int i= iebOut - iebIn;
	  for (i= (i > 0 ? i : IEB_SIZE + i) / 4; i > 0; -- i)
	    {
# if defined(DEBUG_XIM)
	      fprintf(stderr, "%3d pending key %2d=0x%02x\n", inputCount, i, *pendingKey);
# endif
	      recordKeyboardEvent(*pendingKey, EventKeyDown, modifierState, 0);
	      recordKeyboardEvent(*pendingKey, EventKeyChar, modifierState, 0);
	      recordKeystroke(*pendingKey);  /* DEPRECATED */
	      ++pendingKey;
	      if (--inputCount == 0) break;
	    }
	  return 1;
	}
      /* inputBuf is allocated by lookupKeys */
      if (inputBuf != inputString)
	{
	  free(inputBuf);
	  inputBuf= inputString;
	}
      return 0;
    }
}

static int xkeysym2ucs4(KeySym keysym);

static int x2sqKeyInput(XKeyEvent *xevt, KeySym *symbolic)
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
	  if (!(ic= XCreateIC(im, XNInputStyle, XIMPreeditNothing | XIMStatusNothing, XNClientWindow, stWindow, NULL)))
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
      lastKey= -1;
      return key;
    }

  DCONV_PRINTF("keycode %u\n", xevt->keycode);

  {
    char string[128];	/* way too much */
    Status status;
    int count= XmbLookupString(ic, (XKeyPressedEvent *)xevt, string, sizeof(string), symbolic, &status);
    switch (status)
      {
      case XLookupNone:		/* still composing */
	DCONV_FPRINTF(stderr, "x2sqKey XLookupNone\n");
	return -1;

      case XLookupChars:
	DCONV_FPRINTF(stderr, "x2sqKey XLookupChars count %d\n", count);
      case XLookupBoth:
	DCONV_FPRINTF(stderr, "x2sqKey XLookupBoth count %d\n", count);
	lastKey= (count ? recode(string[0]) : -1);
	DCONV_FPRINTF(stderr, "x2sqKey == %d\n", lastKey);
	return lastKey;

      case XLookupKeySym:
	DCONV_FPRINTF(stderr, "x2sqKey XLookupKeySym\n");
	{
	  int charCode= translateCode(*symbolic, 0, xevt);
	  DCONV_FPRINTF("SYM %d -> %d\n", symbolic, charCode);
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
  return x2sqKey(xevt, symbolic);
}

static int x2sqKeyCompositionInput(XKeyEvent *xevt, KeySym *symbolic)
{
  static int lastKey= -1;

# if defined(INIT_INPUT_WHEN_KEY_PRESSED)
  if (!inputContext)
    {
      initInputI18n();
      if (!inputContext)
	return x2sqKeyPlain(xevt, symbolic);
    }
# endif

  if (KeyPress != xevt->type)
    {
      int key= lastKey;
      lastKey= -1;
      return key;
    }

  DCONV_FPRINTF(stderr, "keycode %u\n", xevt->keycode);

  {
    Status status;
    int i;
    if (localeEncoding == sqTextEncoding)
      {
	if (!(inputBuf= lookupKeys(XmbLookupString, xevt, inputString, sizeof(inputString), &inputCount, symbolic, &status)))
	  return lastKey= -1;
      }
#  if defined(X_HAVE_UTF8_STRING)
    else if (uxUTF8Encoding == sqTextEncoding)
      {
	if (!(inputBuf= lookupKeys(Xutf8LookupString, xevt, inputString, sizeof(inputString), &inputCount, symbolic, &status)))
	  return lastKey= -1;
      }
#  endif
    else
      {
	unsigned char  aStr[128], *aBuf;
	if (!(aBuf= lookupKeys(XmbLookupString, xevt, aStr, sizeof(aStr), &inputCount, symbolic, &status)))
	  {
	    fprintf(stderr, "status xmb2: %d\n", status);
	    return lastKey= -1;
	  }
	if (inputCount > sizeof(inputString))
	  {
	    inputBuf= (unsigned char *) malloc((size_t) (inputCount * sizeof(unsigned char)));
	    if (!inputBuf)
	      {
		 fprintf(stderr, "x2sqKeyInput: out of memory\n");
		 if (aStr != aBuf)
		   free(aBuf);
		 return lastKey= -1;
	      }
	  }
	else
	  inputBuf= inputString;
	inputCount= ux2sqXWin(aBuf, inputCount, inputBuf, inputCount, 0);
	if (aStr != aBuf)
	  free(aBuf);
      }
    switch (status)
      {
      case XLookupNone:		/* still composing */
	DCONV_FPRINTF(stderr, "x2sqKey XLookupNone\n");
	return -1;

      case XLookupChars:
	DCONV_FPRINTF(stderr, "x2sqKey XLookupChars count %d\n", inputCount);
      case XLookupBoth:
	DCONV_FPRINTF(stderr, "x2sqKey XLookupBoth count %d\n", inputCount);
	if (inputCount == 0)
	  return lastKey= -1;
	else if (inputCount == 1)
	  {
	    inputCount= 0;
	    return lastKey= recode(inputBuf[0]);
	  }
	else
	  {
#          if defined(DEBUG_XIM)
	    int inputSymbol= xkeysym2ucs4(*symbolic);
	    fprintf(stderr, "x2sqKey string '%s' count %d\n", inputBuf, inputCount);	
	    fprintf(stderr, "x2sqKey symbol 0x%08x => 0x%08x\n", *symbolic, inputSymbol);
#          endif
	    /* record the key events here */
	    pendingKey= inputBuf;
	    recordPendingKeys();

	    /* unclear which is best value for lastKey... */
#          if 1
	    lastKey= (inputCount == 1 ? inputBuf[0] : -1);
#          else
	    lastKey= (inputCount ? inputBuf[0] : -1);
	    lastKey= (inputCount > 0 ? inputBuf[inputCount - 1] : -1);
#          endif
	
	    return -1; /* we've already recorded the key events */
	  }

      case XLookupKeySym:
	DCONV_FPRINTF(stderr, "x2sqKey XLookupKeySym\n");
	{
	  int charCode;
	  if (*symbolic == XK_Multi_key)
	    {
	      multi_key_pressed= 1;
	      multi_key_buffer= 0;
	      DCONV_FPRINTF(stderr, "multi_key was pressed\n");
	      return -1;
	  }
	  
	  charCode= translateCode(*symbolic, 0, xevt);
	  DCONV_PRINTF("SYM %x -> %d\n", *symbolic, charCode);
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
}

#if DEBUG_KEYBOARD_EVENTS
static const char *nameForKeycode(int keycode);
#endif

static int x2sqKeyPlain(XKeyEvent *xevt, KeySym *symbolic)
{
  unsigned char buf[32];
  int nConv= XLookupString(xevt, (char *)buf, sizeof(buf), symbolic, 0);
  int charCode= buf[0];
#if DEBUG_KEYBOARD_EVENTS
  int i;
  fprintf(stderr, "convert keycode");
  for (i = 0; i < nConv; i++) {
	if (!i) fprintf(stderr, " [");
	fprintf(stderr, "%d(%02x)%c", buf[i], buf[i], i + 1 < nConv ? ',' : ']');
  }
  fprintf(stderr, " %d(%02x) -> %d(%02x) (keysym %p %s)\n",
	 xevt->keycode, xevt->keycode, charCode, charCode, symbolic, nameForKeycode(*symbolic));
#endif
  if (!nConv && (charCode= translateCode(*symbolic, &modifierState, xevt)) < 0)
      return -1;	/* unknown key */
  if ((charCode == 127) && mapDelBs)
    charCode= 8;
  return nConv == 0 && (modifierState & (CommandKeyBit+CtrlKeyBit+OptionKeyBit))
			? charCode
			: recode(charCode);
}


static int xkeysym2ucs4(KeySym keysym)
{
    /* Latin 2 Mappings */
  static unsigned short const ucs4_01a1_01ff[] = {
            0x0104, 0x02d8, 0x0141, 0x0000, 0x013d, 0x015a, 0x0000, /* 0x01a0-0x01a7 */
    0x0000, 0x0160, 0x015e, 0x0164, 0x0179, 0x0000, 0x017d, 0x017b, /* 0x01a8-0x01af */
    0x0000, 0x0105, 0x02db, 0x0142, 0x0000, 0x013e, 0x015b, 0x02c7, /* 0x01b0-0x01b7 */
    0x0000, 0x0161, 0x015f, 0x0165, 0x017a, 0x02dd, 0x017e, 0x017c, /* 0x01b8-0x01bf */
    0x0154, 0x0000, 0x0000, 0x0102, 0x0000, 0x0139, 0x0106, 0x0000, /* 0x01c0-0x01c7 */
    0x010c, 0x0000, 0x0118, 0x0000, 0x011a, 0x0000, 0x0000, 0x010e, /* 0x01c8-0x01cf */
    0x0110, 0x0143, 0x0147, 0x0000, 0x0000, 0x0150, 0x0000, 0x0000, /* 0x01d0-0x01d7 */
    0x0158, 0x016e, 0x0000, 0x0170, 0x0000, 0x0000, 0x0162, 0x0000, /* 0x01d8-0x01df */
    0x0155, 0x0000, 0x0000, 0x0103, 0x0000, 0x013a, 0x0107, 0x0000, /* 0x01e0-0x01e7 */
    0x010d, 0x0000, 0x0119, 0x0000, 0x011b, 0x0000, 0x0000, 0x010f, /* 0x01e8-0x01ef */
    0x0111, 0x0144, 0x0148, 0x0000, 0x0000, 0x0151, 0x0000, 0x0000, /* 0x01f0-0x01f7 */
    0x0159, 0x016f, 0x0000, 0x0171, 0x0000, 0x0000, 0x0163, 0x02d9  /* 0x01f8-0x01ff */
  };

    /* Latin 3 Mappings */
  static unsigned short const ucs4_02a1_02fe[] = {
            0x0126, 0x0000, 0x0000, 0x0000, 0x0000, 0x0124, 0x0000, /* 0x02a0-0x02a7 */
    0x0000, 0x0130, 0x0000, 0x011e, 0x0134, 0x0000, 0x0000, 0x0000, /* 0x02a8-0x02af */
    0x0000, 0x0127, 0x0000, 0x0000, 0x0000, 0x0000, 0x0125, 0x0000, /* 0x02b0-0x02b7 */
    0x0000, 0x0131, 0x0000, 0x011f, 0x0135, 0x0000, 0x0000, 0x0000, /* 0x02b8-0x02bf */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x010a, 0x0108, 0x0000, /* 0x02c0-0x02c7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x02c8-0x02cf */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0120, 0x0000, 0x0000, /* 0x02d0-0x02d7 */
    0x011c, 0x0000, 0x0000, 0x0000, 0x0000, 0x016c, 0x015c, 0x0000, /* 0x02d8-0x02df */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x010b, 0x0109, 0x0000, /* 0x02e0-0x02e7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x02e8-0x02ef */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0121, 0x0000, 0x0000, /* 0x02f0-0x02f7 */
    0x011d, 0x0000, 0x0000, 0x0000, 0x0000, 0x016d, 0x015d          /* 0x02f8-0x02ff */
  };

    /* Latin 4 Mappings */
  static unsigned short const ucs4_03a2_03fe[] = {
                    0x0138, 0x0156, 0x0000, 0x0128, 0x013b, 0x0000, /* 0x03a0-0x03a7 */
    0x0000, 0x0000, 0x0112, 0x0122, 0x0166, 0x0000, 0x0000, 0x0000, /* 0x03a8-0x03af */
    0x0000, 0x0000, 0x0000, 0x0157, 0x0000, 0x0129, 0x013c, 0x0000, /* 0x03b0-0x03b7 */
    0x0000, 0x0000, 0x0113, 0x0123, 0x0167, 0x014a, 0x0000, 0x014b, /* 0x03b8-0x03bf */
    0x0100, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x012e, /* 0x03c0-0x03c7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0116, 0x0000, 0x0000, 0x012a, /* 0x03c8-0x03cf */
    0x0000, 0x0145, 0x014c, 0x0136, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x03d0-0x03d7 */
    0x0000, 0x0172, 0x0000, 0x0000, 0x0000, 0x0168, 0x016a, 0x0000, /* 0x03d8-0x03df */
    0x0101, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x012f, /* 0x03e0-0x03e7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0117, 0x0000, 0x0000, 0x012b, /* 0x03e8-0x03ef */
    0x0000, 0x0146, 0x014d, 0x0137, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x03f0-0x03f7 */
    0x0000, 0x0173, 0x0000, 0x0000, 0x0000, 0x0169, 0x016b          /* 0x03f8-0x03ff */
  };

    /* Katakana Mappings */
  static unsigned short const ucs4_04a1_04df[] = {
            0x3002, 0x3008, 0x3009, 0x3001, 0x30fb, 0x30f2, 0x30a1, /* 0x04a0-0x04a7 */
    0x30a3, 0x30a5, 0x30a7, 0x30a9, 0x30e3, 0x30e5, 0x30e7, 0x30c3, /* 0x04a8-0x04af */
    0x30fc, 0x30a2, 0x30a4, 0x30a6, 0x30a8, 0x30aa, 0x30ab, 0x30ad, /* 0x04b0-0x04b7 */
    0x30af, 0x30b1, 0x30b3, 0x30b5, 0x30b7, 0x30b9, 0x30bb, 0x30bd, /* 0x04b8-0x04bf */
    0x30bf, 0x30c1, 0x30c4, 0x30c6, 0x30c8, 0x30ca, 0x30cb, 0x30cc, /* 0x04c0-0x04c7 */
    0x30cd, 0x30ce, 0x30cf, 0x30d2, 0x30d5, 0x30d8, 0x30db, 0x30de, /* 0x04c8-0x04cf */
    0x30df, 0x30e0, 0x30e1, 0x30e2, 0x30e4, 0x30e6, 0x30e8, 0x30e9, /* 0x04d0-0x04d7 */
    0x30ea, 0x30eb, 0x30ec, 0x30ed, 0x30ef, 0x30f3, 0x309b, 0x309c  /* 0x04d8-0x04df */
  };

    /* Arabic mappings */
  static unsigned short const ucs4_0590_05fe[] = {
    0x06f0, 0x06f1, 0x06f2, 0x06f3, 0x06f4, 0x06f5, 0x06f6, 0x06f7, /* 0x0590-0x0597 */
    0x06f8, 0x06f9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x0598-0x059f */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x066a, 0x0670, 0x0679, /* 0x05a0-0x05a7 */
	
    0x067e, 0x0686, 0x0688, 0x0691, 0x060c, 0x0000, 0x06d4, 0x0000, /* 0x05ac-0x05af */
    0x0660, 0x0661, 0x0662, 0x0663, 0x0664, 0x0665, 0x0666, 0x0667, /* 0x05b0-0x05b7 */
    0x0668, 0x0669, 0x0000, 0x061b, 0x0000, 0x0000, 0x0000, 0x061f, /* 0x05b8-0x05bf */
    0x0000, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626, 0x0627, /* 0x05c0-0x05c7 */
    0x0628, 0x0629, 0x062a, 0x062b, 0x062c, 0x062d, 0x062e, 0x062f, /* 0x05c8-0x05cf */
    0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, 0x0637, /* 0x05d0-0x05d7 */
    0x0638, 0x0639, 0x063a, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x05d8-0x05df */
    0x0640, 0x0641, 0x0642, 0x0643, 0x0644, 0x0645, 0x0646, 0x0647, /* 0x05e0-0x05e7 */
    0x0648, 0x0649, 0x064a, 0x064b, 0x064c, 0x064d, 0x064e, 0x064f, /* 0x05e8-0x05ef */
    0x0650, 0x0651, 0x0652, 0x0653, 0x0654, 0x0655, 0x0698, 0x06a4, /* 0x05f0-0x05f7 */
    0x06a9, 0x06af, 0x06ba, 0x06be, 0x06cc, 0x06d2, 0x06c1          /* 0x05f8-0x05fe */
  };

    /* Cyrillic mappings */
  static unsigned short ucs4_0680_06ff[] = {
    0x0492, 0x0496, 0x049a, 0x049c, 0x04a2, 0x04ae, 0x04b0, 0x04b2, /* 0x0680-0x0687 */
    0x04b6, 0x04b8, 0x04ba, 0x0000, 0x04d8, 0x04e2, 0x04e8, 0x04ee, /* 0x0688-0x068f */
    0x0493, 0x0497, 0x049b, 0x049d, 0x04a3, 0x04af, 0x04b1, 0x04b3, /* 0x0690-0x0697 */
    0x04b7, 0x04b9, 0x04bb, 0x0000, 0x04d9, 0x04e3, 0x04e9, 0x04ef, /* 0x0698-0x069f */
    0x0000, 0x0452, 0x0453, 0x0451, 0x0454, 0x0455, 0x0456, 0x0457, /* 0x06a0-0x06a7 */
    0x0458, 0x0459, 0x045a, 0x045b, 0x045c, 0x0491, 0x045e, 0x045f, /* 0x06a8-0x06af */
    0x2116, 0x0402, 0x0403, 0x0401, 0x0404, 0x0405, 0x0406, 0x0407, /* 0x06b0-0x06b7 */
    0x0408, 0x0409, 0x040a, 0x040b, 0x040c, 0x0490, 0x040e, 0x040f, /* 0x06b8-0x06bf */
    0x044e, 0x0430, 0x0431, 0x0446, 0x0434, 0x0435, 0x0444, 0x0433, /* 0x06c0-0x06c7 */
    0x0445, 0x0438, 0x0439, 0x043a, 0x043b, 0x043c, 0x043d, 0x043e, /* 0x06c8-0x06cf */
    0x043f, 0x044f, 0x0440, 0x0441, 0x0442, 0x0443, 0x0436, 0x0432, /* 0x06d0-0x06d7 */
    0x044c, 0x044b, 0x0437, 0x0448, 0x044d, 0x0449, 0x0447, 0x044a, /* 0x06d8-0x06df */
    0x042e, 0x0410, 0x0411, 0x0426, 0x0414, 0x0415, 0x0424, 0x0413, /* 0x06e0-0x06e7 */
    0x0425, 0x0418, 0x0419, 0x041a, 0x041b, 0x041c, 0x041d, 0x041e, /* 0x06e8-0x06ef */
    0x041f, 0x042f, 0x0420, 0x0421, 0x0422, 0x0423, 0x0416, 0x0412, /* 0x06f0-0x06f7 */
    0x042c, 0x042b, 0x0417, 0x0428, 0x042d, 0x0429, 0x0427, 0x042a  /* 0x06f8-0x06ff */
  };

    /* Greek mappings */
  static unsigned short const ucs4_07a1_07f9[] = {
            0x0386, 0x0388, 0x0389, 0x038a, 0x03aa, 0x0000, 0x038c, /* 0x07a0-0x07a7 */
    0x038e, 0x03ab, 0x0000, 0x038f, 0x0000, 0x0000, 0x0385, 0x2015, /* 0x07a8-0x07af */
    0x0000, 0x03ac, 0x03ad, 0x03ae, 0x03af, 0x03ca, 0x0390, 0x03cc, /* 0x07b0-0x07b7 */
    0x03cd, 0x03cb, 0x03b0, 0x03ce, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x07b8-0x07bf */
    0x0000, 0x0391, 0x0392, 0x0393, 0x0394, 0x0395, 0x0396, 0x0397, /* 0x07c0-0x07c7 */
    0x0398, 0x0399, 0x039a, 0x039b, 0x039c, 0x039d, 0x039e, 0x039f, /* 0x07c8-0x07cf */
    0x03a0, 0x03a1, 0x03a3, 0x0000, 0x03a4, 0x03a5, 0x03a6, 0x03a7, /* 0x07d0-0x07d7 */
    0x03a8, 0x03a9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x07d8-0x07df */
    0x0000, 0x03b1, 0x03b2, 0x03b3, 0x03b4, 0x03b5, 0x03b6, 0x03b7, /* 0x07e0-0x07e7 */
    0x03b8, 0x03b9, 0x03ba, 0x03bb, 0x03bc, 0x03bd, 0x03be, 0x03bf, /* 0x07e8-0x07ef */
    0x03c0, 0x03c1, 0x03c3, 0x03c2, 0x03c4, 0x03c5, 0x03c6, 0x03c7, /* 0x07f0-0x07f7 */
    0x03c8, 0x03c9                                                  /* 0x07f8-0x07ff */
  };

    /* Technical mappings */
  static unsigned short const ucs4_08a4_08fe[] = {
                                    0x2320, 0x2321, 0x0000, 0x231c, /* 0x08a0-0x08a7 */
    0x231d, 0x231e, 0x231f, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x08a8-0x08af */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x08b0-0x08b7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x2264, 0x2260, 0x2265, 0x222b, /* 0x08b8-0x08bf */
    0x2234, 0x0000, 0x221e, 0x0000, 0x0000, 0x2207, 0x0000, 0x0000, /* 0x08c0-0x08c7 */
    0x2245, 0x2246, 0x0000, 0x0000, 0x0000, 0x0000, 0x22a2, 0x0000, /* 0x08c8-0x08cf */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x221a, 0x0000, /* 0x08d0-0x08d7 */
    0x0000, 0x0000, 0x2282, 0x2283, 0x2229, 0x222a, 0x2227, 0x2228, /* 0x08d8-0x08df */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x08e0-0x08e7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x08e8-0x08ef */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0192, 0x0000, /* 0x08f0-0x08f7 */
    0x0000, 0x0000, 0x0000, 0x2190, 0x2191, 0x2192, 0x2193          /* 0x08f8-0x08ff */
  };

    /* Special mappings from the DEC VT100 Special Graphics Character Set */
  static unsigned short const ucs4_09df_09f8[] = {
                                                            0x2422, /* 0x09d8-0x09df */
    0x2666, 0x25a6, 0x2409, 0x240c, 0x240d, 0x240a, 0x0000, 0x0000, /* 0x09e0-0x09e7 */
    0x240a, 0x240b, 0x2518, 0x2510, 0x250c, 0x2514, 0x253c, 0x2500, /* 0x09e8-0x09ef */
    0x0000, 0x0000, 0x0000, 0x0000, 0x251c, 0x2524, 0x2534, 0x252c, /* 0x09f0-0x09f7 */
    0x2502                                                          /* 0x09f8-0x09ff */
  };

    /* Publishing Mappings ? */
  static unsigned short const ucs4_0aa1_0afe[] = {
            0x2003, 0x2002, 0x2004, 0x2005, 0x2007, 0x2008, 0x2009, /* 0x0aa0-0x0aa7 */
    0x200a, 0x2014, 0x2013, 0x0000, 0x0000, 0x0000, 0x2026, 0x2025, /* 0x0aa8-0x0aaf */
    0x2153, 0x2154, 0x2155, 0x2156, 0x2157, 0x2158, 0x2159, 0x215a, /* 0x0ab0-0x0ab7 */
    0x2105, 0x0000, 0x0000, 0x2012, 0x2039, 0x2024, 0x203a, 0x0000, /* 0x0ab8-0x0abf */
    0x0000, 0x0000, 0x0000, 0x215b, 0x215c, 0x215d, 0x215e, 0x0000, /* 0x0ac0-0x0ac7 */
    0x0000, 0x2122, 0x2120, 0x0000, 0x25c1, 0x25b7, 0x25cb, 0x25ad, /* 0x0ac8-0x0acf */
    0x2018, 0x2019, 0x201c, 0x201d, 0x211e, 0x0000, 0x2032, 0x2033, /* 0x0ad0-0x0ad7 */
    0x0000, 0x271d, 0x0000, 0x220e, 0x25c2, 0x2023, 0x25cf, 0x25ac, /* 0x0ad8-0x0adf */
    0x25e6, 0x25ab, 0x25ae, 0x25b5, 0x25bf, 0x2606, 0x2022, 0x25aa, /* 0x0ae0-0x0ae7 */
    0x25b4, 0x25be, 0x261a, 0x261b, 0x2663, 0x2666, 0x2665, 0x0000, /* 0x0ae8-0x0aef */
    0x2720, 0x2020, 0x2021, 0x2713, 0x2612, 0x266f, 0x266d, 0x2642, /* 0x0af0-0x0af7 */
    0x2640, 0x2121, 0x2315, 0x2117, 0x2038, 0x201a, 0x201e          /* 0x0af8-0x0aff */
  };

    /* Hebrew Mappings */
  static unsigned short const ucs4_0cdf_0cfa[] = {
                                                            0x2017, /* 0x0cd8-0x0cdf */
    0x05d0, 0x05d1, 0x05d2, 0x05d3, 0x05d4, 0x05d5, 0x05d6, 0x05d7, /* 0x0ce0-0x0ce7 */
    0x05d8, 0x05d9, 0x05da, 0x05db, 0x05dc, 0x05dd, 0x05de, 0x05df, /* 0x0ce8-0x0cef */
    0x05e0, 0x05e1, 0x05e2, 0x05e3, 0x05e4, 0x05e5, 0x05e6, 0x05e7, /* 0x0cf0-0x0cf7 */
    0x05e8, 0x05e9, 0x05ea                                          /* 0x0cf8-0x0cff */
  };

    /* Thai Mappings */
  static unsigned short const ucs4_0da1_0df9[] = {
            0x0e01, 0x0e02, 0x0e03, 0x0e04, 0x0e05, 0x0e06, 0x0e07, /* 0x0da0-0x0da7 */
    0x0e08, 0x0e09, 0x0e0a, 0x0e0b, 0x0e0c, 0x0e0d, 0x0e0e, 0x0e0f, /* 0x0da8-0x0daf */
    0x0e10, 0x0e11, 0x0e12, 0x0e13, 0x0e14, 0x0e15, 0x0e16, 0x0e17, /* 0x0db0-0x0db7 */
    0x0e18, 0x0e19, 0x0e1a, 0x0e1b, 0x0e1c, 0x0e1d, 0x0e1e, 0x0e1f, /* 0x0db8-0x0dbf */
    0x0e20, 0x0e21, 0x0e22, 0x0e23, 0x0e24, 0x0e25, 0x0e26, 0x0e27, /* 0x0dc0-0x0dc7 */
    0x0e28, 0x0e29, 0x0e2a, 0x0e2b, 0x0e2c, 0x0e2d, 0x0e2e, 0x0e2f, /* 0x0dc8-0x0dcf */
    0x0e30, 0x0e31, 0x0e32, 0x0e33, 0x0e34, 0x0e35, 0x0e36, 0x0e37, /* 0x0dd0-0x0dd7 */
    0x0e38, 0x0e39, 0x0e3a, 0x0000, 0x0000, 0x0000, 0x0e3e, 0x0e3f, /* 0x0dd8-0x0ddf */
    0x0e40, 0x0e41, 0x0e42, 0x0e43, 0x0e44, 0x0e45, 0x0e46, 0x0e47, /* 0x0de0-0x0de7 */
    0x0e48, 0x0e49, 0x0e4a, 0x0e4b, 0x0e4c, 0x0e4d, 0x0000, 0x0000, /* 0x0de8-0x0def */
    0x0e50, 0x0e51, 0x0e52, 0x0e53, 0x0e54, 0x0e55, 0x0e56, 0x0e57, /* 0x0df0-0x0df7 */
    0x0e58, 0x0e59                                                  /* 0x0df8-0x0dff */
  };

    /* Hangul Mappings */
  static unsigned short const ucs4_0ea0_0eff[] = {
    0x0000, 0x1101, 0x1101, 0x11aa, 0x1102, 0x11ac, 0x11ad, 0x1103, /* 0x0ea0-0x0ea7 */
    0x1104, 0x1105, 0x11b0, 0x11b1, 0x11b2, 0x11b3, 0x11b4, 0x11b5, /* 0x0ea8-0x0eaf */
    0x11b6, 0x1106, 0x1107, 0x1108, 0x11b9, 0x1109, 0x110a, 0x110b, /* 0x0eb0-0x0eb7 */
    0x110c, 0x110d, 0x110e, 0x110f, 0x1110, 0x1111, 0x1112, 0x1161, /* 0x0eb8-0x0ebf */
    0x1162, 0x1163, 0x1164, 0x1165, 0x1166, 0x1167, 0x1168, 0x1169, /* 0x0ec0-0x0ec7 */
    0x116a, 0x116b, 0x116c, 0x116d, 0x116e, 0x116f, 0x1170, 0x1171, /* 0x0ec8-0x0ecf */
    0x1172, 0x1173, 0x1174, 0x1175, 0x11a8, 0x11a9, 0x11aa, 0x11ab, /* 0x0ed0-0x0ed7 */
    0x11ac, 0x11ad, 0x11ae, 0x11af, 0x11b0, 0x11b1, 0x11b2, 0x11b3, /* 0x0ed8-0x0edf */
    0x11b4, 0x11b5, 0x11b6, 0x11b7, 0x11b8, 0x11b9, 0x11ba, 0x11bb, /* 0x0ee0-0x0ee7 */
    0x11bc, 0x11bd, 0x11be, 0x11bf, 0x11c0, 0x11c1, 0x11c2, 0x0000, /* 0x0ee8-0x0eef */
    0x0000, 0x0000, 0x1140, 0x0000, 0x0000, 0x1159, 0x119e, 0x0000, /* 0x0ef0-0x0ef7 */
    0x11eb, 0x0000, 0x11f9, 0x0000, 0x0000, 0x0000, 0x0000, 0x20a9, /* 0x0ef8-0x0eff */
  };

    /* Non existing range in keysymdef.h */
  static unsigned short ucs4_12a1_12fe[] = {
            0x1e02, 0x1e03, 0x0000, 0x0000, 0x0000, 0x1e0a, 0x0000, /* 0x12a0-0x12a7 */
    0x1e80, 0x0000, 0x1e82, 0x1e0b, 0x1ef2, 0x0000, 0x0000, 0x0000, /* 0x12a8-0x12af */
    0x1e1e, 0x1e1f, 0x0000, 0x0000, 0x1e40, 0x1e41, 0x0000, 0x1e56, /* 0x12b0-0x12b7 */
    0x1e81, 0x1e57, 0x1e83, 0x1e60, 0x1ef3, 0x1e84, 0x1e85, 0x1e61, /* 0x12b8-0x12bf */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x12c0-0x12c7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x12c8-0x12cf */
    0x0174, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x1e6a, /* 0x12d0-0x12d7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0176, 0x0000, /* 0x12d8-0x12df */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x12e0-0x12e7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x12e8-0x12ef */
    0x0175, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x1e6b, /* 0x12f0-0x12f7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0177          /* 0x12f0-0x12ff */
  };
    
    /* Latin 9 Mappings */		
  static unsigned short const ucs4_13bc_13be[] = {
                                    0x0152, 0x0153, 0x0178          /* 0x13b8-0x13bf */
  };

    /* Non existing range in keysymdef.h */
  static unsigned short ucs4_14a1_14ff[] = {
            0x2741, 0x00a7, 0x0589, 0x0029, 0x0028, 0x00bb, 0x00ab, /* 0x14a0-0x14a7 */
    0x2014, 0x002e, 0x055d, 0x002c, 0x2013, 0x058a, 0x2026, 0x055c, /* 0x14a8-0x14af */
    0x055b, 0x055e, 0x0531, 0x0561, 0x0532, 0x0562, 0x0533, 0x0563, /* 0x14b0-0x14b7 */
    0x0534, 0x0564, 0x0535, 0x0565, 0x0536, 0x0566, 0x0537, 0x0567, /* 0x14b8-0x14bf */
    0x0538, 0x0568, 0x0539, 0x0569, 0x053a, 0x056a, 0x053b, 0x056b, /* 0x14c0-0x14c7 */
    0x053c, 0x056c, 0x053d, 0x056d, 0x053e, 0x056e, 0x053f, 0x056f, /* 0x14c8-0x14cf */
    0x0540, 0x0570, 0x0541, 0x0571, 0x0542, 0x0572, 0x0543, 0x0573, /* 0x14d0-0x14d7 */
    0x0544, 0x0574, 0x0545, 0x0575, 0x0546, 0x0576, 0x0547, 0x0577, /* 0x14d8-0x14df */
    0x0548, 0x0578, 0x0549, 0x0579, 0x054a, 0x057a, 0x054b, 0x057b, /* 0x14e0-0x14e7 */
    0x054c, 0x057c, 0x054d, 0x057d, 0x054e, 0x057e, 0x054f, 0x057f, /* 0x14e8-0x14ef */
    0x0550, 0x0580, 0x0551, 0x0581, 0x0552, 0x0582, 0x0553, 0x0583, /* 0x14f0-0x14f7 */
    0x0554, 0x0584, 0x0555, 0x0585, 0x0556, 0x0586, 0x2019, 0x0027, /* 0x14f8-0x14ff */
  };

    /* Non existing range in keysymdef.h */
  static unsigned short ucs4_15d0_15f6[] = {
    0x10d0, 0x10d1, 0x10d2, 0x10d3, 0x10d4, 0x10d5, 0x10d6, 0x10d7, /* 0x15d0-0x15d7 */
    0x10d8, 0x10d9, 0x10da, 0x10db, 0x10dc, 0x10dd, 0x10de, 0x10df, /* 0x15d8-0x15df */
    0x10e0, 0x10e1, 0x10e2, 0x10e3, 0x10e4, 0x10e5, 0x10e6, 0x10e7, /* 0x15e0-0x15e7 */
    0x10e8, 0x10e9, 0x10ea, 0x10eb, 0x10ec, 0x10ed, 0x10ee, 0x10ef, /* 0x15e8-0x15ef */
    0x10f0, 0x10f1, 0x10f2, 0x10f3, 0x10f4, 0x10f5, 0x10f6          /* 0x15f0-0x15f7 */
  };

    /* Non existing range in keysymdef.h */
  static unsigned short ucs4_16a0_16f6[] = {
    0x0000, 0x0000, 0xf0a2, 0x1e8a, 0x0000, 0xf0a5, 0x012c, 0xf0a7, /* 0x16a0-0x16a7 */
    0xf0a8, 0x01b5, 0x01e6, 0x0000, 0x0000, 0x0000, 0x0000, 0x019f, /* 0x16a8-0x16af */
    0x0000, 0x017e, 0xf0b2, 0x1e8b, 0x01d1, 0xf0b5, 0x012d, 0xf0b7, /* 0x16b0-0x16b7 */
    0xf0b8, 0x01b6, 0x01e7, 0x01d2, 0x0000, 0x0000, 0x0000, 0x0275, /* 0x16b8-0x16bf */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x018f, 0x0000, /* 0x16c0-0x16c7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x16c8-0x16cf */
    0x0000, 0x1e36, 0xf0d2, 0xf0d3, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x16d0-0x16d7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x16d8-0x16df */
    0x0000, 0x1e37, 0xf0e2, 0xf0e3, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x16e0-0x16e7 */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, /* 0x16e8-0x16ef */
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0259          /* 0x16f0-0x16f6 */
  };

    /* Vietnamesse Mappings */
  static unsigned short const ucs4_1e9f_1eff[] = {
                                                            0x0303,
    0x1ea0, 0x1ea1, 0x1ea2, 0x1ea3, 0x1ea4, 0x1ea5, 0x1ea6, 0x1ea7, /* 0x1ea0-0x1ea7 */
    0x1ea8, 0x1ea9, 0x1eaa, 0x1eab, 0x1eac, 0x1ead, 0x1eae, 0x1eaf, /* 0x1ea8-0x1eaf */
    0x1eb0, 0x1eb1, 0x1eb2, 0x1eb3, 0x1eb4, 0x1eb5, 0x1eb6, 0x1eb7, /* 0x1eb0-0x1eb7 */
    0x1eb8, 0x1eb9, 0x1eba, 0x1ebb, 0x1ebc, 0x1ebd, 0x1ebe, 0x1ebf, /* 0x1eb8-0x1ebf */
    0x1ec0, 0x1ec1, 0x1ec2, 0x1ec3, 0x1ec4, 0x1ec5, 0x1ec6, 0x1ec7, /* 0x1ec0-0x1ec7 */
    0x1ec8, 0x1ec9, 0x1eca, 0x1ecb, 0x1ecc, 0x1ecd, 0x1ece, 0x1ecf, /* 0x1ec8-0x1ecf */
    0x1ed0, 0x1ed1, 0x1ed2, 0x1ed3, 0x1ed4, 0x1ed5, 0x1ed6, 0x1ed7, /* 0x1ed0-0x1ed7 */
    0x1ed8, 0x1ed9, 0x1eda, 0x1edb, 0x1edc, 0x1edd, 0x1ede, 0x1edf, /* 0x1ed8-0x1edf */
    0x1ee0, 0x1ee1, 0x1ee2, 0x1ee3, 0x1ee4, 0x1ee5, 0x1ee6, 0x1ee7, /* 0x1ee0-0x1ee7 */
    0x1ee8, 0x1ee9, 0x1eea, 0x1eeb, 0x1eec, 0x1eed, 0x1eee, 0x1eef, /* 0x1ee8-0x1eef */
    0x1ef0, 0x1ef1, 0x0300, 0x0301, 0x1ef4, 0x1ef5, 0x1ef6, 0x1ef7, /* 0x1ef0-0x1ef7 */
    0x1ef8, 0x1ef9, 0x01a0, 0x01a1, 0x01af, 0x01b0, 0x0309, 0x0323  /* 0x1ef8-0x1eff */
  };

    /* Currency */
  static unsigned short const ucs4_20a0_20ac[] = {
    0x20a0, 0x20a1, 0x20a2, 0x20a3, 0x20a4, 0x20a5, 0x20a6, 0x20a7, /* 0x20a0-0x20a7 */
    0x20a8, 0x20a9, 0x20aa, 0x20ab, 0x20ac                          /* 0x20a8-0x20af */
  };

    /* Keypad numbers mapping */
  static unsigned short const ucs4_ffb0_ffb9[] = { 0x30, 0x31, 0x32, 0x33, 0x34,
             0x35, 0x36, 0x37, 0x38, 0x39};
 
     /* Keypad operators mapping */
  static unsigned short const ucs4_ffaa_ffaf[] = { 
             0x2a, /* Multiply  */
             0x2b, /* Add       */
             0x2c, /* Separator */
             0x2d, /* Substract */
             0x2e, /* Decimal   */
             0x2f  /* Divide    */
     };

 	static unsigned short const sqSpecialKey[] = { 
             1,  /* HOME  */
             28, /* LEFT  */ 
             30, /* UP    */
             29, /* RIGHT */
             31, /* DOWN  */
             11, /* PRIOR (page up?) */
             12, /* NEXT (page down/new page?) */
             4,  /* END */
             1   /* HOME */
     };


  /* Latin-1 */
  if (   (keysym >= 0x0020 && keysym <= 0x007e)
      || (keysym >= 0x00a0 && keysym <= 0x00ff)) return keysym;

  /* 24-bit UCS */
  if ((keysym & 0xff000000) == 0x01000000) return keysym & 0x00ffffff;

  /* control keys with ASCII equivalents */
  if (keysym > 0xff00 && keysym < 0xff10) return keysym & 0x001f;
  if (keysym > 0xff4f && keysym < 0xff59)
    {
      return sqSpecialKey[keysym - 0xff50];
    }
  if (keysym > 0xff58 && keysym < 0xff5f) return keysym & 0x007f; /* could be return 0; */
  if (keysym > 0xff94 && keysym < 0xff9d)
    {
      return sqSpecialKey[keysym - 0xff95];
    }
  if (keysym          ==          0xff1b) return keysym & 0x001f;
  if (keysym          ==          0xffff) return keysym & 0x007f;

  /* Misc mappings */
  if (keysym == XK_Escape)
 	return keysym & 0x001f;
  if (keysym == XK_Delete)
 	return keysym & 0x007f;
  if (keysym == XK_KP_Equal)
    return XK_equal;


  /* explicitly mapped */
#define map(lo, hi) if (keysym >= 0x##lo && keysym <= 0x##hi) return ucs4_##lo##_##hi[keysym - 0x##lo];
  map(01a1, 01ff);  map(02a1, 02fe);  map(03a2, 03fe);  map(04a1, 04df);
  map(0590, 05fe);  map(0680, 06ff);  map(07a1, 07f9);  map(08a4, 08fe);
  map(09df, 09f8);  map(0aa1, 0afe);  map(0cdf, 0cfa);  map(0da1, 0df9);
  map(0ea0, 0eff);  map(12a1, 12fe);  map(13bc, 13be);  map(14a1, 14ff);
  map(15d0, 15f6);  map(16a0, 16f6);  map(1e9f, 1eff);  map(20a0, 20ac);
  map(ffb0, ffb9);
  map(ffaa, ffaf);
#undef map

#if defined(XF86XK_Start)
  if (keysym == XF86XK_Start)                       /* OLPC view source */
    {
      modifierState |= CommandKeyBit;
      return ',';
    }
#endif

  /* convert to chinese char noe-qwan-doo */
  return 0;
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
      int shift= 1 & (state >> ShiftMapIndex);
      int ctrl=  1 & (state >> ControlMapIndex);
      int cmd=   1 & (state >> cmdMapIndex);
      int opt=   1 & (state >> optMapIndex);
      mods= (shift ? ShiftKeyBit   : 0)
	|   (ctrl  ? CtrlKeyBit    : 0)
	|   (cmd   ? CommandKeyBit : 0)
	|   (opt   ? OptionKeyBit  : 0);
#    if DEBUG_KEYBOARD_EVENTS || DEBUG_MOUSE_EVENTS
      fprintf(stderr, "X mod %x -> Sq mod %x (extended opt=%d cmd=%d)\n", state, mods,
	      optMapIndex, cmdMapIndex);
#    endif
    }
  else
    {
      enum { _= 0, S= ShiftKeyBit, C= CtrlKeyBit, O= OptionKeyBit, M= CommandKeyBit };
      static char midofiers[32]= {	/* ALT=Cmd, META=ignored, C-ALT=Opt, META=ignored */
       	/*                - -       - S       L -       L S */
       	/* - - - - */ _|_|_|_,  _|_|_|S,  _|_|_|_,  _|_|_|S,
       	/* - - - C */ _|_|C|_,  _|_|C|S,  _|_|C|_,  _|_|C|S,
       	/* - - A - */ _|M|_|_,  _|M|_|S,  _|M|_|_,  _|M|_|S,
       	/* - - A C */ O|_|_|_,  O|_|_|S,  O|_|_|_,  O|_|_|S,
       	/*                - -       - S       L -       L S */
       	/* M - - - */ _|M|_|_,  _|M|_|S,  _|M|_|_,  _|M|_|S,
       	/* M - - C */ _|M|C|_,  _|M|C|S,  _|M|C|_,  _|M|C|S,
       	/* M - A - */ _|M|_|_,  _|M|_|S,  _|M|_|_,  _|M|_|S,
       	/* M - A C */ O|_|_|_,  O|M|_|S,  O|M|_|_,  O|M|_|S,
      };
#    if defined(__POWERPC__) || defined(__ppc__)
      mods= midofiers[state & 0x1f];
#    else
      mods= midofiers[state & 0x0f];
#    endif
#    if DEBUG_KEYBOARD_EVENTS || DEBUG_MOUSE_EVENTS
	if (mods)
      fprintf(stderr, "X mod %x -> Sq mod %x (default)\n", state & 0xf, mods);
#    endif
    }
  return mods;
}

/* wait for pending completion events to arrive */

static void waitForCompletions(void)
{
#if defined(USE_XSHM)
  while (completions > 0)
    handleEvents();
#endif
}


#include "sqUnixXdnd.c"

/* Answers the available types (like "image/png") in XdndSelection or
 * CLIPBOARD as a NULL-terminated array of strings, or 0 on error.
 * The caller must free() the returned array.
 */
static char **display_clipboardGetTypeNames(void)
{
  Atom    *targets= NULL;
  size_t   bytes= 0;
  char   **typeNames= NULL;
  Status   success= 0;
  int      nTypeNames= 0;

  if (dndAvailable())
    dndGetTargets(&targets, &nTypeNames);
  else 
    {
      if (stOwnsClipboard) return 0;
      targets= (Atom *)getSelectionData(xaClipboard, xaTargets, &bytes);
      if (0 == bytes) return 0;
      nTypeNames= bytes / sizeof(Atom);
    }

  typeNames= calloc(nTypeNames + 1, sizeof(char *));
  if (!XGetAtomNames(stDisplay, targets, nTypeNames, typeNames)) return 0;
  typeNames[nTypeNames]= 0;

  return typeNames;
}

/* Read the clipboard data associated with the typeName to
 * stPrimarySelection.  Answer the size of the data.
 */
static sqInt display_clipboardSizeWithType(char *typeName, int nTypeName)
{
  size_t 	  bytes;
  Atom   	  type;
  int    	  isDnd= 0;
  Atom   	  inputSelection;
  SelectionChunk *chunk;
  
  isDnd= dndAvailable();
  inputSelection= isDnd ? xaXdndSelection : xaClipboard;

  if ((!isDnd) && stOwnsClipboard) return 0;

  chunk= newSelectionChunk();
  type= stringToAtom(typeName, nTypeName);
  getSelectionChunk(chunk, inputSelection, type);
  bytes= sizeSelectionChunk(chunk);

  allocateSelectionBuffer(bytes);
  copySelectionChunk(chunk, stPrimarySelection);
  destroySelectionChunk(chunk);
  if (isDnd) dndHandleEvent(DndInFinished, 0);

  return stPrimarySelectionSize;
}


#if DEBUG_KEYBOARD_EVENTS
/*
grep '^#[ 	]*define[ 	][ 	]*XK_.*0x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][^0-9a-fA-F]' /usr/include/X11/*.h |  sed 's/^.*\(XK_[^     ]*\)[   ]*\(0x[0-9a-fA-F]*\).*$/{ "\1", \2 }, /'
*/
typedef struct { char *name; int code; } KeyNameEntry;
static KeyNameEntry codes[] = {
{ "XK_BackSpace", 0xff08 }, 
{ "XK_Linefeed", 0xff0a }, 
{ "XK_Return", 0xff0d }, 
{ "XK_Pause", 0xff13 }, 
{ "XK_Delete", 0xffff }, 
{ "XK_Multi_key", 0xff20 }, 
{ "XK_Kanji", 0xff21 }, 
{ "XK_Muhenkan", 0xff22 }, 
{ "XK_Henkan_Mode", 0xff23 }, 
{ "XK_Henkan", 0xff23 }, 
{ "XK_Romaji", 0xff24 }, 
{ "XK_Hiragana", 0xff25 }, 
{ "XK_Katakana", 0xff26 }, 
{ "XK_Hiragana_Katakana", 0xff27 }, 
{ "XK_Zenkaku", 0xff28 }, 
{ "XK_Hankaku", 0xff29 }, 
{ "XK_Zenkaku_Hankaku", 0xff2a }, 
{ "XK_Touroku", 0xff2b }, 
{ "XK_Massyo", 0xff2c }, 
{ "XK_Kana_Lock", 0xff2d }, 
{ "XK_Kana_Shift", 0xff2e }, 
{ "XK_Eisu_Shift", 0xff2f }, 
{ "XK_Eisu_toggle", 0xff30 }, 
{ "XK_Kanji_Bangou", 0xff37 }, 
{ "XK_Zen_Koho", 0xff3d }, 
{ "XK_Mae_Koho", 0xff3e }, 
{ "XK_Left", 0xff51 }, 
{ "XK_Up", 0xff52 }, 
{ "XK_Right", 0xff53 }, 
{ "XK_Down", 0xff54 }, 
{ "XK_Prior", 0xff55 }, 
{ "XK_Next", 0xff56 }, 
{ "XK_End", 0xff57 }, 
{ "XK_Begin", 0xff58 }, 
{ "XK_Select", 0xff60 }, 
{ "XK_Execute", 0xff62 }, 
{ "XK_Insert", 0xff63 }, 
{ "XK_Redo", 0xff66 }, 
{ "XK_Find", 0xff68 }, 
{ "XK_Cancel", 0xff69 }, 
{ "XK_Help", 0xff6a }, 
{ "XK_Mode_switch", 0xff7e }, 
{ "XK_script_switch", 0xff7e }, 
{ "XK_KP_Space", 0xff80 }, 
{ "XK_KP_Enter", 0xff8d }, 
{ "XK_KP_F1", 0xff91 }, 
{ "XK_KP_Equal", 0xffbd }, 
{ "XK_KP_Separator", 0xffac }, 
{ "XK_Shift_L", 0xffe1 }, 
{ "XK_Shift_R", 0xffe2 }, 
{ "XK_Control_L", 0xffe3 }, 
{ "XK_Control_R", 0xffe4 }, 
{ "XK_Caps_Lock", 0xffe5 }, 
{ "XK_Shift_Lock", 0xffe6 }, 
{ "XK_Meta_L", 0xffe7 }, 
{ "XK_Meta_R", 0xffe8 }, 
{ "XK_Alt_L", 0xffe9 }, 
{ "XK_Alt_R", 0xffea }, 
{ "XK_Super_L", 0xffeb }, 
{ "XK_Super_R", 0xffec }, 
{ "XK_Hyper_L", 0xffed }, 
{ "XK_Hyper_R", 0xffee }, 
{ "XK_ISO_Group_Shift", 0xff7e }, 
{ "XK_space", 0x0020 }, 
{ "XK_exclam", 0x0021 }, 
{ "XK_quotedbl", 0x0022 }, 
{ "XK_numbersign", 0x0023 }, 
{ "XK_dollar", 0x0024 }, 
{ "XK_percent", 0x0025 }, 
{ "XK_ampersand", 0x0026 }, 
{ "XK_apostrophe", 0x0027 }, 
{ "XK_quoteright", 0x0027 }, 
{ "XK_parenleft", 0x0028 }, 
{ "XK_parenright", 0x0029 }, 
{ "XK_asterisk", 0x002a }, 
{ "XK_plus", 0x002b }, 
{ "XK_comma", 0x002c }, 
{ "XK_minus", 0x002d }, 
{ "XK_period", 0x002e }, 
{ "XK_slash", 0x002f }, 
{ "XK_0", 0x0030 }, 
{ "XK_1", 0x0031 }, 
{ "XK_2", 0x0032 }, 
{ "XK_3", 0x0033 }, 
{ "XK_4", 0x0034 }, 
{ "XK_5", 0x0035 }, 
{ "XK_6", 0x0036 }, 
{ "XK_7", 0x0037 }, 
{ "XK_8", 0x0038 }, 
{ "XK_9", 0x0039 }, 
{ "XK_colon", 0x003a }, 
{ "XK_semicolon", 0x003b }, 
{ "XK_less", 0x003c }, 
{ "XK_equal", 0x003d }, 
{ "XK_greater", 0x003e }, 
{ "XK_question", 0x003f }, 
{ "XK_at", 0x0040 }, 
{ "XK_A", 0x0041 }, 
{ "XK_B", 0x0042 }, 
{ "XK_C", 0x0043 }, 
{ "XK_D", 0x0044 }, 
{ "XK_E", 0x0045 }, 
{ "XK_F", 0x0046 }, 
{ "XK_G", 0x0047 }, 
{ "XK_H", 0x0048 }, 
{ "XK_I", 0x0049 }, 
{ "XK_J", 0x004a }, 
{ "XK_K", 0x004b }, 
{ "XK_L", 0x004c }, 
{ "XK_M", 0x004d }, 
{ "XK_N", 0x004e }, 
{ "XK_O", 0x004f }, 
{ "XK_P", 0x0050 }, 
{ "XK_Q", 0x0051 }, 
{ "XK_R", 0x0052 }, 
{ "XK_S", 0x0053 }, 
{ "XK_T", 0x0054 }, 
{ "XK_U", 0x0055 }, 
{ "XK_V", 0x0056 }, 
{ "XK_W", 0x0057 }, 
{ "XK_X", 0x0058 }, 
{ "XK_Y", 0x0059 }, 
{ "XK_Z", 0x005a }, 
{ "XK_bracketleft", 0x005b }, 
{ "XK_backslash", 0x005c }, 
{ "XK_bracketright", 0x005d }, 
{ "XK_asciicircum", 0x005e }, 
{ "XK_underscore", 0x005f }, 
{ "XK_grave", 0x0060 }, 
{ "XK_quoteleft", 0x0060 }, 
{ "XK_a", 0x0061 }, 
{ "XK_b", 0x0062 }, 
{ "XK_c", 0x0063 }, 
{ "XK_d", 0x0064 }, 
{ "XK_e", 0x0065 }, 
{ "XK_f", 0x0066 }, 
{ "XK_g", 0x0067 }, 
{ "XK_h", 0x0068 }, 
{ "XK_i", 0x0069 }, 
{ "XK_j", 0x006a }, 
{ "XK_k", 0x006b }, 
{ "XK_l", 0x006c }, 
{ "XK_m", 0x006d }, 
{ "XK_n", 0x006e }, 
{ "XK_o", 0x006f }, 
{ "XK_p", 0x0070 }, 
{ "XK_q", 0x0071 }, 
{ "XK_r", 0x0072 }, 
{ "XK_s", 0x0073 }, 
{ "XK_t", 0x0074 }, 
{ "XK_u", 0x0075 }, 
{ "XK_v", 0x0076 }, 
{ "XK_w", 0x0077 }, 
{ "XK_x", 0x0078 }, 
{ "XK_y", 0x0079 }, 
{ "XK_z", 0x007a }, 
{ "XK_braceleft", 0x007b }, 
{ "XK_bar", 0x007c }, 
{ "XK_braceright", 0x007d }, 
{ "XK_asciitilde", 0x007e }, 
{ "XK_nobreakspace", 0x00a0 }, 
{ "XK_exclamdown", 0x00a1 }, 
{ "XK_cent", 0x00a2 }, 
{ "XK_sterling", 0x00a3 }, 
{ "XK_currency", 0x00a4 }, 
{ "XK_yen", 0x00a5 }, 
{ "XK_brokenbar", 0x00a6 }, 
{ "XK_section", 0x00a7 }, 
{ "XK_diaeresis", 0x00a8 }, 
{ "XK_copyright", 0x00a9 }, 
{ "XK_ordfeminine", 0x00aa }, 
{ "XK_guillemotleft", 0x00ab }, 
{ "XK_notsign", 0x00ac }, 
{ "XK_hyphen", 0x00ad }, 
{ "XK_registered", 0x00ae }, 
{ "XK_macron", 0x00af }, 
{ "XK_degree", 0x00b0 }, 
{ "XK_plusminus", 0x00b1 }, 
{ "XK_twosuperior", 0x00b2 }, 
{ "XK_threesuperior", 0x00b3 }, 
{ "XK_acute", 0x00b4 }, 
{ "XK_mu", 0x00b5 }, 
{ "XK_paragraph", 0x00b6 }, 
{ "XK_periodcentered", 0x00b7 }, 
{ "XK_cedilla", 0x00b8 }, 
{ "XK_onesuperior", 0x00b9 }, 
{ "XK_masculine", 0x00ba }, 
{ "XK_guillemotright", 0x00bb }, 
{ "XK_onequarter", 0x00bc }, 
{ "XK_onehalf", 0x00bd }, 
{ "XK_threequarters", 0x00be }, 
{ "XK_questiondown", 0x00bf }, 
{ "XK_Agrave", 0x00c0 }, 
{ "XK_Aacute", 0x00c1 }, 
{ "XK_Acircumflex", 0x00c2 }, 
{ "XK_Atilde", 0x00c3 }, 
{ "XK_Adiaeresis", 0x00c4 }, 
{ "XK_Aring", 0x00c5 }, 
{ "XK_AE", 0x00c6 }, 
{ "XK_Ccedilla", 0x00c7 }, 
{ "XK_Egrave", 0x00c8 }, 
{ "XK_Eacute", 0x00c9 }, 
{ "XK_Ecircumflex", 0x00ca }, 
{ "XK_Ediaeresis", 0x00cb }, 
{ "XK_Igrave", 0x00cc }, 
{ "XK_Iacute", 0x00cd }, 
{ "XK_Icircumflex", 0x00ce }, 
{ "XK_Idiaeresis", 0x00cf }, 
{ "XK_ETH", 0x00d0 }, 
{ "XK_Eth", 0x00d0 }, 
{ "XK_Ntilde", 0x00d1 }, 
{ "XK_Ograve", 0x00d2 }, 
{ "XK_Oacute", 0x00d3 }, 
{ "XK_Ocircumflex", 0x00d4 }, 
{ "XK_Otilde", 0x00d5 }, 
{ "XK_Odiaeresis", 0x00d6 }, 
{ "XK_multiply", 0x00d7 }, 
{ "XK_Oslash", 0x00d8 }, 
{ "XK_Ooblique", 0x00d8 }, 
{ "XK_Ugrave", 0x00d9 }, 
{ "XK_Uacute", 0x00da }, 
{ "XK_Ucircumflex", 0x00db }, 
{ "XK_Udiaeresis", 0x00dc }, 
{ "XK_Yacute", 0x00dd }, 
{ "XK_THORN", 0x00de }, 
{ "XK_Thorn", 0x00de }, 
{ "XK_ssharp", 0x00df }, 
{ "XK_agrave", 0x00e0 }, 
{ "XK_aacute", 0x00e1 }, 
{ "XK_acircumflex", 0x00e2 }, 
{ "XK_atilde", 0x00e3 }, 
{ "XK_adiaeresis", 0x00e4 }, 
{ "XK_aring", 0x00e5 }, 
{ "XK_ae", 0x00e6 }, 
{ "XK_ccedilla", 0x00e7 }, 
{ "XK_egrave", 0x00e8 }, 
{ "XK_eacute", 0x00e9 }, 
{ "XK_ecircumflex", 0x00ea }, 
{ "XK_ediaeresis", 0x00eb }, 
{ "XK_igrave", 0x00ec }, 
{ "XK_iacute", 0x00ed }, 
{ "XK_icircumflex", 0x00ee }, 
{ "XK_idiaeresis", 0x00ef }, 
{ "XK_eth", 0x00f0 }, 
{ "XK_ntilde", 0x00f1 }, 
{ "XK_ograve", 0x00f2 }, 
{ "XK_oacute", 0x00f3 }, 
{ "XK_ocircumflex", 0x00f4 }, 
{ "XK_otilde", 0x00f5 }, 
{ "XK_odiaeresis", 0x00f6 }, 
{ "XK_division", 0x00f7 }, 
{ "XK_oslash", 0x00f8 }, 
{ "XK_ooblique", 0x00f8 }, 
{ "XK_ugrave", 0x00f9 }, 
{ "XK_uacute", 0x00fa }, 
{ "XK_ucircumflex", 0x00fb }, 
{ "XK_udiaeresis", 0x00fc }, 
{ "XK_yacute", 0x00fd }, 
{ "XK_thorn", 0x00fe }, 
{ "XK_ydiaeresis", 0x00ff }, 
{ "XK_Aogonek", 0x01a1 }, 
{ "XK_breve", 0x01a2 }, 
{ "XK_Lstroke", 0x01a3 }, 
{ "XK_Lcaron", 0x01a5 }, 
{ "XK_Sacute", 0x01a6 }, 
{ "XK_Scaron", 0x01a9 }, 
{ "XK_Scedilla", 0x01aa }, 
{ "XK_Tcaron", 0x01ab }, 
{ "XK_Zacute", 0x01ac }, 
{ "XK_Zcaron", 0x01ae }, 
{ "XK_Zabovedot", 0x01af }, 
{ "XK_aogonek", 0x01b1 }, 
{ "XK_ogonek", 0x01b2 }, 
{ "XK_lstroke", 0x01b3 }, 
{ "XK_lcaron", 0x01b5 }, 
{ "XK_sacute", 0x01b6 }, 
{ "XK_caron", 0x01b7 }, 
{ "XK_scaron", 0x01b9 }, 
{ "XK_scedilla", 0x01ba }, 
{ "XK_tcaron", 0x01bb }, 
{ "XK_zacute", 0x01bc }, 
{ "XK_doubleacute", 0x01bd }, 
{ "XK_zcaron", 0x01be }, 
{ "XK_zabovedot", 0x01bf }, 
{ "XK_Racute", 0x01c0 }, 
{ "XK_Abreve", 0x01c3 }, 
{ "XK_Lacute", 0x01c5 }, 
{ "XK_Cacute", 0x01c6 }, 
{ "XK_Ccaron", 0x01c8 }, 
{ "XK_Eogonek", 0x01ca }, 
{ "XK_Ecaron", 0x01cc }, 
{ "XK_Dcaron", 0x01cf }, 
{ "XK_Dstroke", 0x01d0 }, 
{ "XK_Nacute", 0x01d1 }, 
{ "XK_Ncaron", 0x01d2 }, 
{ "XK_Odoubleacute", 0x01d5 }, 
{ "XK_Rcaron", 0x01d8 }, 
{ "XK_Uring", 0x01d9 }, 
{ "XK_Udoubleacute", 0x01db }, 
{ "XK_Tcedilla", 0x01de }, 
{ "XK_racute", 0x01e0 }, 
{ "XK_abreve", 0x01e3 }, 
{ "XK_lacute", 0x01e5 }, 
{ "XK_cacute", 0x01e6 }, 
{ "XK_ccaron", 0x01e8 }, 
{ "XK_eogonek", 0x01ea }, 
{ "XK_ecaron", 0x01ec }, 
{ "XK_dcaron", 0x01ef }, 
{ "XK_dstroke", 0x01f0 }, 
{ "XK_nacute", 0x01f1 }, 
{ "XK_ncaron", 0x01f2 }, 
{ "XK_odoubleacute", 0x01f5 }, 
{ "XK_udoubleacute", 0x01fb }, 
{ "XK_rcaron", 0x01f8 }, 
{ "XK_uring", 0x01f9 }, 
{ "XK_tcedilla", 0x01fe }, 
{ "XK_abovedot", 0x01ff }, 
{ "XK_Hstroke", 0x02a1 }, 
{ "XK_Hcircumflex", 0x02a6 }, 
{ "XK_Iabovedot", 0x02a9 }, 
{ "XK_Gbreve", 0x02ab }, 
{ "XK_Jcircumflex", 0x02ac }, 
{ "XK_hstroke", 0x02b1 }, 
{ "XK_hcircumflex", 0x02b6 }, 
{ "XK_idotless", 0x02b9 }, 
{ "XK_gbreve", 0x02bb }, 
{ "XK_jcircumflex", 0x02bc }, 
{ "XK_Cabovedot", 0x02c5 }, 
{ "XK_Ccircumflex", 0x02c6 }, 
{ "XK_Gabovedot", 0x02d5 }, 
{ "XK_Gcircumflex", 0x02d8 }, 
{ "XK_Ubreve", 0x02dd }, 
{ "XK_Scircumflex", 0x02de }, 
{ "XK_cabovedot", 0x02e5 }, 
{ "XK_ccircumflex", 0x02e6 }, 
{ "XK_gabovedot", 0x02f5 }, 
{ "XK_gcircumflex", 0x02f8 }, 
{ "XK_ubreve", 0x02fd }, 
{ "XK_scircumflex", 0x02fe }, 
{ "XK_kra", 0x03a2 }, 
{ "XK_kappa", 0x03a2 }, 
{ "XK_Rcedilla", 0x03a3 }, 
{ "XK_Itilde", 0x03a5 }, 
{ "XK_Lcedilla", 0x03a6 }, 
{ "XK_Emacron", 0x03aa }, 
{ "XK_Gcedilla", 0x03ab }, 
{ "XK_Tslash", 0x03ac }, 
{ "XK_rcedilla", 0x03b3 }, 
{ "XK_itilde", 0x03b5 }, 
{ "XK_lcedilla", 0x03b6 }, 
{ "XK_emacron", 0x03ba }, 
{ "XK_gcedilla", 0x03bb }, 
{ "XK_tslash", 0x03bc }, 
{ "XK_ENG", 0x03bd }, 
{ "XK_eng", 0x03bf }, 
{ "XK_Amacron", 0x03c0 }, 
{ "XK_Iogonek", 0x03c7 }, 
{ "XK_Eabovedot", 0x03cc }, 
{ "XK_Imacron", 0x03cf }, 
{ "XK_Ncedilla", 0x03d1 }, 
{ "XK_Omacron", 0x03d2 }, 
{ "XK_Kcedilla", 0x03d3 }, 
{ "XK_Uogonek", 0x03d9 }, 
{ "XK_Utilde", 0x03dd }, 
{ "XK_Umacron", 0x03de }, 
{ "XK_amacron", 0x03e0 }, 
{ "XK_iogonek", 0x03e7 }, 
{ "XK_eabovedot", 0x03ec }, 
{ "XK_imacron", 0x03ef }, 
{ "XK_ncedilla", 0x03f1 }, 
{ "XK_omacron", 0x03f2 }, 
{ "XK_kcedilla", 0x03f3 }, 
{ "XK_uogonek", 0x03f9 }, 
{ "XK_utilde", 0x03fd }, 
{ "XK_umacron", 0x03fe }, 
{ "XK_OE", 0x13bc }, 
{ "XK_oe", 0x13bd }, 
{ "XK_Ydiaeresis", 0x13be }, 
{ "XK_overline", 0x047e }, 
{ "XK_kana_fullstop", 0x04a1 }, 
{ "XK_kana_openingbracket", 0x04a2 }, 
{ "XK_kana_closingbracket", 0x04a3 }, 
{ "XK_kana_comma", 0x04a4 }, 
{ "XK_kana_conjunctive", 0x04a5 }, 
{ "XK_kana_middledot", 0x04a5 }, 
{ "XK_kana_WO", 0x04a6 }, 
{ "XK_kana_a", 0x04a7 }, 
{ "XK_kana_i", 0x04a8 }, 
{ "XK_kana_u", 0x04a9 }, 
{ "XK_kana_e", 0x04aa }, 
{ "XK_kana_o", 0x04ab }, 
{ "XK_kana_ya", 0x04ac }, 
{ "XK_kana_yu", 0x04ad }, 
{ "XK_kana_yo", 0x04ae }, 
{ "XK_kana_tsu", 0x04af }, 
{ "XK_kana_tu", 0x04af }, 
{ "XK_prolongedsound", 0x04b0 }, 
{ "XK_kana_A", 0x04b1 }, 
{ "XK_kana_I", 0x04b2 }, 
{ "XK_kana_U", 0x04b3 }, 
{ "XK_kana_E", 0x04b4 }, 
{ "XK_kana_O", 0x04b5 }, 
{ "XK_kana_KA", 0x04b6 }, 
{ "XK_kana_KI", 0x04b7 }, 
{ "XK_kana_KU", 0x04b8 }, 
{ "XK_kana_KE", 0x04b9 }, 
{ "XK_kana_KO", 0x04ba }, 
{ "XK_kana_SA", 0x04bb }, 
{ "XK_kana_SHI", 0x04bc }, 
{ "XK_kana_SU", 0x04bd }, 
{ "XK_kana_SE", 0x04be }, 
{ "XK_kana_SO", 0x04bf }, 
{ "XK_kana_TA", 0x04c0 }, 
{ "XK_kana_CHI", 0x04c1 }, 
{ "XK_kana_TI", 0x04c1 }, 
{ "XK_kana_TSU", 0x04c2 }, 
{ "XK_kana_TU", 0x04c2 }, 
{ "XK_kana_TE", 0x04c3 }, 
{ "XK_kana_TO", 0x04c4 }, 
{ "XK_kana_NA", 0x04c5 }, 
{ "XK_kana_NI", 0x04c6 }, 
{ "XK_kana_NU", 0x04c7 }, 
{ "XK_kana_NE", 0x04c8 }, 
{ "XK_kana_NO", 0x04c9 }, 
{ "XK_kana_HA", 0x04ca }, 
{ "XK_kana_HI", 0x04cb }, 
{ "XK_kana_FU", 0x04cc }, 
{ "XK_kana_HU", 0x04cc }, 
{ "XK_kana_HE", 0x04cd }, 
{ "XK_kana_HO", 0x04ce }, 
{ "XK_kana_MA", 0x04cf }, 
{ "XK_kana_MI", 0x04d0 }, 
{ "XK_kana_MU", 0x04d1 }, 
{ "XK_kana_ME", 0x04d2 }, 
{ "XK_kana_MO", 0x04d3 }, 
{ "XK_kana_YA", 0x04d4 }, 
{ "XK_kana_YU", 0x04d5 }, 
{ "XK_kana_YO", 0x04d6 }, 
{ "XK_kana_RA", 0x04d7 }, 
{ "XK_kana_RI", 0x04d8 }, 
{ "XK_kana_RU", 0x04d9 }, 
{ "XK_kana_RE", 0x04da }, 
{ "XK_kana_RO", 0x04db }, 
{ "XK_kana_WA", 0x04dc }, 
{ "XK_kana_N", 0x04dd }, 
{ "XK_voicedsound", 0x04de }, 
{ "XK_semivoicedsound", 0x04df }, 
{ "XK_kana_switch", 0xff7e }, 
{ "XK_Arabic_comma", 0x05ac }, 
{ "XK_Arabic_semicolon", 0x05bb }, 
{ "XK_Arabic_question_mark", 0x05bf }, 
{ "XK_Arabic_hamza", 0x05c1 }, 
{ "XK_Arabic_maddaonalef", 0x05c2 }, 
{ "XK_Arabic_hamzaonalef", 0x05c3 }, 
{ "XK_Arabic_hamzaonwaw", 0x05c4 }, 
{ "XK_Arabic_hamzaunderalef", 0x05c5 }, 
{ "XK_Arabic_hamzaonyeh", 0x05c6 }, 
{ "XK_Arabic_alef", 0x05c7 }, 
{ "XK_Arabic_beh", 0x05c8 }, 
{ "XK_Arabic_tehmarbuta", 0x05c9 }, 
{ "XK_Arabic_teh", 0x05ca }, 
{ "XK_Arabic_theh", 0x05cb }, 
{ "XK_Arabic_jeem", 0x05cc }, 
{ "XK_Arabic_hah", 0x05cd }, 
{ "XK_Arabic_khah", 0x05ce }, 
{ "XK_Arabic_dal", 0x05cf }, 
{ "XK_Arabic_thal", 0x05d0 }, 
{ "XK_Arabic_ra", 0x05d1 }, 
{ "XK_Arabic_zain", 0x05d2 }, 
{ "XK_Arabic_seen", 0x05d3 }, 
{ "XK_Arabic_sheen", 0x05d4 }, 
{ "XK_Arabic_sad", 0x05d5 }, 
{ "XK_Arabic_dad", 0x05d6 }, 
{ "XK_Arabic_tah", 0x05d7 }, 
{ "XK_Arabic_zah", 0x05d8 }, 
{ "XK_Arabic_ain", 0x05d9 }, 
{ "XK_Arabic_ghain", 0x05da }, 
{ "XK_Arabic_tatweel", 0x05e0 }, 
{ "XK_Arabic_feh", 0x05e1 }, 
{ "XK_Arabic_qaf", 0x05e2 }, 
{ "XK_Arabic_kaf", 0x05e3 }, 
{ "XK_Arabic_lam", 0x05e4 }, 
{ "XK_Arabic_meem", 0x05e5 }, 
{ "XK_Arabic_noon", 0x05e6 }, 
{ "XK_Arabic_ha", 0x05e7 }, 
{ "XK_Arabic_heh", 0x05e7 }, 
{ "XK_Arabic_waw", 0x05e8 }, 
{ "XK_Arabic_alefmaksura", 0x05e9 }, 
{ "XK_Arabic_yeh", 0x05ea }, 
{ "XK_Arabic_fathatan", 0x05eb }, 
{ "XK_Arabic_dammatan", 0x05ec }, 
{ "XK_Arabic_kasratan", 0x05ed }, 
{ "XK_Arabic_fatha", 0x05ee }, 
{ "XK_Arabic_damma", 0x05ef }, 
{ "XK_Arabic_kasra", 0x05f0 }, 
{ "XK_Arabic_shadda", 0x05f1 }, 
{ "XK_Arabic_sukun", 0x05f2 }, 
{ "XK_Arabic_switch", 0xff7e }, 
{ "XK_Serbian_dje", 0x06a1 }, 
{ "XK_Macedonia_gje", 0x06a2 }, 
{ "XK_Cyrillic_io", 0x06a3 }, 
{ "XK_Ukrainian_ie", 0x06a4 }, 
{ "XK_Ukranian_je", 0x06a4 }, 
{ "XK_Macedonia_dse", 0x06a5 }, 
{ "XK_Ukrainian_i", 0x06a6 }, 
{ "XK_Ukranian_i", 0x06a6 }, 
{ "XK_Ukrainian_yi", 0x06a7 }, 
{ "XK_Ukranian_yi", 0x06a7 }, 
{ "XK_Cyrillic_je", 0x06a8 }, 
{ "XK_Serbian_je", 0x06a8 }, 
{ "XK_Cyrillic_lje", 0x06a9 }, 
{ "XK_Serbian_lje", 0x06a9 }, 
{ "XK_Cyrillic_nje", 0x06aa }, 
{ "XK_Serbian_nje", 0x06aa }, 
{ "XK_Serbian_tshe", 0x06ab }, 
{ "XK_Macedonia_kje", 0x06ac }, 
{ "XK_Ukrainian_ghe_with_upturn", 0x06ad }, 
{ "XK_Byelorussian_shortu", 0x06ae }, 
{ "XK_Cyrillic_dzhe", 0x06af }, 
{ "XK_Serbian_dze", 0x06af }, 
{ "XK_numerosign", 0x06b0 }, 
{ "XK_Serbian_DJE", 0x06b1 }, 
{ "XK_Macedonia_GJE", 0x06b2 }, 
{ "XK_Cyrillic_IO", 0x06b3 }, 
{ "XK_Ukrainian_IE", 0x06b4 }, 
{ "XK_Ukranian_JE", 0x06b4 }, 
{ "XK_Macedonia_DSE", 0x06b5 }, 
{ "XK_Ukrainian_I", 0x06b6 }, 
{ "XK_Ukranian_I", 0x06b6 }, 
{ "XK_Ukrainian_YI", 0x06b7 }, 
{ "XK_Ukranian_YI", 0x06b7 }, 
{ "XK_Cyrillic_JE", 0x06b8 }, 
{ "XK_Serbian_JE", 0x06b8 }, 
{ "XK_Cyrillic_LJE", 0x06b9 }, 
{ "XK_Serbian_LJE", 0x06b9 }, 
{ "XK_Cyrillic_NJE", 0x06ba }, 
{ "XK_Serbian_NJE", 0x06ba }, 
{ "XK_Serbian_TSHE", 0x06bb }, 
{ "XK_Macedonia_KJE", 0x06bc }, 
{ "XK_Ukrainian_GHE_WITH_UPTURN", 0x06bd }, 
{ "XK_Byelorussian_SHORTU", 0x06be }, 
{ "XK_Cyrillic_DZHE", 0x06bf }, 
{ "XK_Serbian_DZE", 0x06bf }, 
{ "XK_Cyrillic_yu", 0x06c0 }, 
{ "XK_Cyrillic_a", 0x06c1 }, 
{ "XK_Cyrillic_be", 0x06c2 }, 
{ "XK_Cyrillic_tse", 0x06c3 }, 
{ "XK_Cyrillic_de", 0x06c4 }, 
{ "XK_Cyrillic_ie", 0x06c5 }, 
{ "XK_Cyrillic_ef", 0x06c6 }, 
{ "XK_Cyrillic_ghe", 0x06c7 }, 
{ "XK_Cyrillic_ha", 0x06c8 }, 
{ "XK_Cyrillic_i", 0x06c9 }, 
{ "XK_Cyrillic_shorti", 0x06ca }, 
{ "XK_Cyrillic_ka", 0x06cb }, 
{ "XK_Cyrillic_el", 0x06cc }, 
{ "XK_Cyrillic_em", 0x06cd }, 
{ "XK_Cyrillic_en", 0x06ce }, 
{ "XK_Cyrillic_o", 0x06cf }, 
{ "XK_Cyrillic_pe", 0x06d0 }, 
{ "XK_Cyrillic_ya", 0x06d1 }, 
{ "XK_Cyrillic_er", 0x06d2 }, 
{ "XK_Cyrillic_es", 0x06d3 }, 
{ "XK_Cyrillic_te", 0x06d4 }, 
{ "XK_Cyrillic_u", 0x06d5 }, 
{ "XK_Cyrillic_zhe", 0x06d6 }, 
{ "XK_Cyrillic_ve", 0x06d7 }, 
{ "XK_Cyrillic_softsign", 0x06d8 }, 
{ "XK_Cyrillic_yeru", 0x06d9 }, 
{ "XK_Cyrillic_ze", 0x06da }, 
{ "XK_Cyrillic_sha", 0x06db }, 
{ "XK_Cyrillic_e", 0x06dc }, 
{ "XK_Cyrillic_shcha", 0x06dd }, 
{ "XK_Cyrillic_che", 0x06de }, 
{ "XK_Cyrillic_hardsign", 0x06df }, 
{ "XK_Cyrillic_YU", 0x06e0 }, 
{ "XK_Cyrillic_A", 0x06e1 }, 
{ "XK_Cyrillic_BE", 0x06e2 }, 
{ "XK_Cyrillic_TSE", 0x06e3 }, 
{ "XK_Cyrillic_DE", 0x06e4 }, 
{ "XK_Cyrillic_IE", 0x06e5 }, 
{ "XK_Cyrillic_EF", 0x06e6 }, 
{ "XK_Cyrillic_GHE", 0x06e7 }, 
{ "XK_Cyrillic_HA", 0x06e8 }, 
{ "XK_Cyrillic_I", 0x06e9 }, 
{ "XK_Cyrillic_SHORTI", 0x06ea }, 
{ "XK_Cyrillic_KA", 0x06eb }, 
{ "XK_Cyrillic_EL", 0x06ec }, 
{ "XK_Cyrillic_EM", 0x06ed }, 
{ "XK_Cyrillic_EN", 0x06ee }, 
{ "XK_Cyrillic_O", 0x06ef }, 
{ "XK_Cyrillic_PE", 0x06f0 }, 
{ "XK_Cyrillic_YA", 0x06f1 }, 
{ "XK_Cyrillic_ER", 0x06f2 }, 
{ "XK_Cyrillic_ES", 0x06f3 }, 
{ "XK_Cyrillic_TE", 0x06f4 }, 
{ "XK_Cyrillic_U", 0x06f5 }, 
{ "XK_Cyrillic_ZHE", 0x06f6 }, 
{ "XK_Cyrillic_VE", 0x06f7 }, 
{ "XK_Cyrillic_SOFTSIGN", 0x06f8 }, 
{ "XK_Cyrillic_YERU", 0x06f9 }, 
{ "XK_Cyrillic_ZE", 0x06fa }, 
{ "XK_Cyrillic_SHA", 0x06fb }, 
{ "XK_Cyrillic_E", 0x06fc }, 
{ "XK_Cyrillic_SHCHA", 0x06fd }, 
{ "XK_Cyrillic_CHE", 0x06fe }, 
{ "XK_Cyrillic_HARDSIGN", 0x06ff }, 
{ "XK_Greek_ALPHAaccent", 0x07a1 }, 
{ "XK_Greek_EPSILONaccent", 0x07a2 }, 
{ "XK_Greek_ETAaccent", 0x07a3 }, 
{ "XK_Greek_IOTAaccent", 0x07a4 }, 
{ "XK_Greek_IOTAdieresis", 0x07a5 }, 
{ "XK_Greek_IOTAdiaeresis", 0x07a5 }, 
{ "XK_Greek_OMICRONaccent", 0x07a7 }, 
{ "XK_Greek_UPSILONaccent", 0x07a8 }, 
{ "XK_Greek_UPSILONdieresis", 0x07a9 }, 
{ "XK_Greek_OMEGAaccent", 0x07ab }, 
{ "XK_Greek_accentdieresis", 0x07ae }, 
{ "XK_Greek_horizbar", 0x07af }, 
{ "XK_Greek_alphaaccent", 0x07b1 }, 
{ "XK_Greek_epsilonaccent", 0x07b2 }, 
{ "XK_Greek_etaaccent", 0x07b3 }, 
{ "XK_Greek_iotaaccent", 0x07b4 }, 
{ "XK_Greek_iotadieresis", 0x07b5 }, 
{ "XK_Greek_iotaaccentdieresis", 0x07b6 }, 
{ "XK_Greek_omicronaccent", 0x07b7 }, 
{ "XK_Greek_upsilonaccent", 0x07b8 }, 
{ "XK_Greek_upsilondieresis", 0x07b9 }, 
{ "XK_Greek_upsilonaccentdieresis", 0x07ba }, 
{ "XK_Greek_omegaaccent", 0x07bb }, 
{ "XK_Greek_ALPHA", 0x07c1 }, 
{ "XK_Greek_BETA", 0x07c2 }, 
{ "XK_Greek_GAMMA", 0x07c3 }, 
{ "XK_Greek_DELTA", 0x07c4 }, 
{ "XK_Greek_EPSILON", 0x07c5 }, 
{ "XK_Greek_ZETA", 0x07c6 }, 
{ "XK_Greek_ETA", 0x07c7 }, 
{ "XK_Greek_THETA", 0x07c8 }, 
{ "XK_Greek_IOTA", 0x07c9 }, 
{ "XK_Greek_KAPPA", 0x07ca }, 
{ "XK_Greek_LAMDA", 0x07cb }, 
{ "XK_Greek_LAMBDA", 0x07cb }, 
{ "XK_Greek_MU", 0x07cc }, 
{ "XK_Greek_NU", 0x07cd }, 
{ "XK_Greek_XI", 0x07ce }, 
{ "XK_Greek_OMICRON", 0x07cf }, 
{ "XK_Greek_PI", 0x07d0 }, 
{ "XK_Greek_RHO", 0x07d1 }, 
{ "XK_Greek_SIGMA", 0x07d2 }, 
{ "XK_Greek_TAU", 0x07d4 }, 
{ "XK_Greek_UPSILON", 0x07d5 }, 
{ "XK_Greek_PHI", 0x07d6 }, 
{ "XK_Greek_CHI", 0x07d7 }, 
{ "XK_Greek_PSI", 0x07d8 }, 
{ "XK_Greek_OMEGA", 0x07d9 }, 
{ "XK_Greek_alpha", 0x07e1 }, 
{ "XK_Greek_beta", 0x07e2 }, 
{ "XK_Greek_gamma", 0x07e3 }, 
{ "XK_Greek_delta", 0x07e4 }, 
{ "XK_Greek_epsilon", 0x07e5 }, 
{ "XK_Greek_zeta", 0x07e6 }, 
{ "XK_Greek_eta", 0x07e7 }, 
{ "XK_Greek_theta", 0x07e8 }, 
{ "XK_Greek_iota", 0x07e9 }, 
{ "XK_Greek_kappa", 0x07ea }, 
{ "XK_Greek_lamda", 0x07eb }, 
{ "XK_Greek_lambda", 0x07eb }, 
{ "XK_Greek_mu", 0x07ec }, 
{ "XK_Greek_nu", 0x07ed }, 
{ "XK_Greek_xi", 0x07ee }, 
{ "XK_Greek_omicron", 0x07ef }, 
{ "XK_Greek_pi", 0x07f0 }, 
{ "XK_Greek_rho", 0x07f1 }, 
{ "XK_Greek_sigma", 0x07f2 }, 
{ "XK_Greek_finalsmallsigma", 0x07f3 }, 
{ "XK_Greek_tau", 0x07f4 }, 
{ "XK_Greek_upsilon", 0x07f5 }, 
{ "XK_Greek_phi", 0x07f6 }, 
{ "XK_Greek_chi", 0x07f7 }, 
{ "XK_Greek_psi", 0x07f8 }, 
{ "XK_Greek_omega", 0x07f9 }, 
{ "XK_Greek_switch", 0xff7e }, 
{ "XK_leftradical", 0x08a1 }, 
{ "XK_topleftradical", 0x08a2 }, 
{ "XK_horizconnector", 0x08a3 }, 
{ "XK_topintegral", 0x08a4 }, 
{ "XK_botintegral", 0x08a5 }, 
{ "XK_vertconnector", 0x08a6 }, 
{ "XK_topleftsqbracket", 0x08a7 }, 
{ "XK_botleftsqbracket", 0x08a8 }, 
{ "XK_toprightsqbracket", 0x08a9 }, 
{ "XK_botrightsqbracket", 0x08aa }, 
{ "XK_topleftparens", 0x08ab }, 
{ "XK_botleftparens", 0x08ac }, 
{ "XK_toprightparens", 0x08ad }, 
{ "XK_botrightparens", 0x08ae }, 
{ "XK_leftmiddlecurlybrace", 0x08af }, 
{ "XK_rightmiddlecurlybrace", 0x08b0 }, 
{ "XK_lessthanequal", 0x08bc }, 
{ "XK_notequal", 0x08bd }, 
{ "XK_greaterthanequal", 0x08be }, 
{ "XK_integral", 0x08bf }, 
{ "XK_therefore", 0x08c0 }, 
{ "XK_variation", 0x08c1 }, 
{ "XK_infinity", 0x08c2 }, 
{ "XK_nabla", 0x08c5 }, 
{ "XK_approximate", 0x08c8 }, 
{ "XK_similarequal", 0x08c9 }, 
{ "XK_ifonlyif", 0x08cd }, 
{ "XK_implies", 0x08ce }, 
{ "XK_identical", 0x08cf }, 
{ "XK_radical", 0x08d6 }, 
{ "XK_includedin", 0x08da }, 
{ "XK_includes", 0x08db }, 
{ "XK_intersection", 0x08dc }, 
{ "XK_union", 0x08dd }, 
{ "XK_logicaland", 0x08de }, 
{ "XK_logicalor", 0x08df }, 
{ "XK_partialderivative", 0x08ef }, 
{ "XK_function", 0x08f6 }, 
{ "XK_leftarrow", 0x08fb }, 
{ "XK_uparrow", 0x08fc }, 
{ "XK_rightarrow", 0x08fd }, 
{ "XK_downarrow", 0x08fe }, 
{ "XK_soliddiamond", 0x09e0 }, 
{ "XK_checkerboard", 0x09e1 }, 
{ "XK_ht", 0x09e2 }, 
{ "XK_ff", 0x09e3 }, 
{ "XK_cr", 0x09e4 }, 
{ "XK_lf", 0x09e5 }, 
{ "XK_nl", 0x09e8 }, 
{ "XK_vt", 0x09e9 }, 
{ "XK_lowrightcorner", 0x09ea }, 
{ "XK_uprightcorner", 0x09eb }, 
{ "XK_upleftcorner", 0x09ec }, 
{ "XK_lowleftcorner", 0x09ed }, 
{ "XK_crossinglines", 0x09ee }, 
{ "XK_horizlinescan1", 0x09ef }, 
{ "XK_horizlinescan3", 0x09f0 }, 
{ "XK_horizlinescan5", 0x09f1 }, 
{ "XK_horizlinescan7", 0x09f2 }, 
{ "XK_horizlinescan9", 0x09f3 }, 
{ "XK_leftt", 0x09f4 }, 
{ "XK_rightt", 0x09f5 }, 
{ "XK_bott", 0x09f6 }, 
{ "XK_topt", 0x09f7 }, 
{ "XK_vertbar", 0x09f8 }, 
{ "XK_emspace", 0x0aa1 }, 
{ "XK_enspace", 0x0aa2 }, 
{ "XK_em3space", 0x0aa3 }, 
{ "XK_em4space", 0x0aa4 }, 
{ "XK_digitspace", 0x0aa5 }, 
{ "XK_punctspace", 0x0aa6 }, 
{ "XK_thinspace", 0x0aa7 }, 
{ "XK_hairspace", 0x0aa8 }, 
{ "XK_emdash", 0x0aa9 }, 
{ "XK_endash", 0x0aaa }, 
{ "XK_signifblank", 0x0aac }, 
{ "XK_ellipsis", 0x0aae }, 
{ "XK_doubbaselinedot", 0x0aaf }, 
{ "XK_onethird", 0x0ab0 }, 
{ "XK_twothirds", 0x0ab1 }, 
{ "XK_onefifth", 0x0ab2 }, 
{ "XK_twofifths", 0x0ab3 }, 
{ "XK_threefifths", 0x0ab4 }, 
{ "XK_fourfifths", 0x0ab5 }, 
{ "XK_onesixth", 0x0ab6 }, 
{ "XK_fivesixths", 0x0ab7 }, 
{ "XK_careof", 0x0ab8 }, 
{ "XK_figdash", 0x0abb }, 
{ "XK_leftanglebracket", 0x0abc }, 
{ "XK_decimalpoint", 0x0abd }, 
{ "XK_rightanglebracket", 0x0abe }, 
{ "XK_oneeighth", 0x0ac3 }, 
{ "XK_threeeighths", 0x0ac4 }, 
{ "XK_fiveeighths", 0x0ac5 }, 
{ "XK_seveneighths", 0x0ac6 }, 
{ "XK_trademark", 0x0ac9 }, 
{ "XK_signaturemark", 0x0aca }, 
{ "XK_leftopentriangle", 0x0acc }, 
{ "XK_rightopentriangle", 0x0acd }, 
{ "XK_emopencircle", 0x0ace }, 
{ "XK_emopenrectangle", 0x0acf }, 
{ "XK_leftsinglequotemark", 0x0ad0 }, 
{ "XK_rightsinglequotemark", 0x0ad1 }, 
{ "XK_leftdoublequotemark", 0x0ad2 }, 
{ "XK_rightdoublequotemark", 0x0ad3 }, 
{ "XK_prescription", 0x0ad4 }, 
{ "XK_minutes", 0x0ad6 }, 
{ "XK_seconds", 0x0ad7 }, 
{ "XK_latincross", 0x0ad9 }, 
{ "XK_filledrectbullet", 0x0adb }, 
{ "XK_filledlefttribullet", 0x0adc }, 
{ "XK_filledrighttribullet", 0x0add }, 
{ "XK_emfilledcircle", 0x0ade }, 
{ "XK_emfilledrect", 0x0adf }, 
{ "XK_enopencircbullet", 0x0ae0 }, 
{ "XK_enopensquarebullet", 0x0ae1 }, 
{ "XK_openrectbullet", 0x0ae2 }, 
{ "XK_opentribulletup", 0x0ae3 }, 
{ "XK_opentribulletdown", 0x0ae4 }, 
{ "XK_openstar", 0x0ae5 }, 
{ "XK_enfilledcircbullet", 0x0ae6 }, 
{ "XK_enfilledsqbullet", 0x0ae7 }, 
{ "XK_filledtribulletup", 0x0ae8 }, 
{ "XK_filledtribulletdown", 0x0ae9 }, 
{ "XK_leftpointer", 0x0aea }, 
{ "XK_rightpointer", 0x0aeb }, 
{ "XK_club", 0x0aec }, 
{ "XK_diamond", 0x0aed }, 
{ "XK_heart", 0x0aee }, 
{ "XK_maltesecross", 0x0af0 }, 
{ "XK_dagger", 0x0af1 }, 
{ "XK_doubledagger", 0x0af2 }, 
{ "XK_checkmark", 0x0af3 }, 
{ "XK_ballotcross", 0x0af4 }, 
{ "XK_musicalsharp", 0x0af5 }, 
{ "XK_musicalflat", 0x0af6 }, 
{ "XK_malesymbol", 0x0af7 }, 
{ "XK_femalesymbol", 0x0af8 }, 
{ "XK_telephone", 0x0af9 }, 
{ "XK_telephonerecorder", 0x0afa }, 
{ "XK_phonographcopyright", 0x0afb }, 
{ "XK_caret", 0x0afc }, 
{ "XK_singlelowquotemark", 0x0afd }, 
{ "XK_doublelowquotemark", 0x0afe }, 
{ "XK_leftcaret", 0x0ba3 }, 
{ "XK_rightcaret", 0x0ba6 }, 
{ "XK_downcaret", 0x0ba8 }, 
{ "XK_upcaret", 0x0ba9 }, 
{ "XK_overbar", 0x0bc0 }, 
{ "XK_downtack", 0x0bc2 }, 
{ "XK_upshoe", 0x0bc3 }, 
{ "XK_downstile", 0x0bc4 }, 
{ "XK_underbar", 0x0bc6 }, 
{ "XK_jot", 0x0bca }, 
{ "XK_quad", 0x0bcc }, 
{ "XK_uptack", 0x0bce }, 
{ "XK_circle", 0x0bcf }, 
{ "XK_upstile", 0x0bd3 }, 
{ "XK_downshoe", 0x0bd6 }, 
{ "XK_rightshoe", 0x0bd8 }, 
{ "XK_leftshoe", 0x0bda }, 
{ "XK_lefttack", 0x0bdc }, 
{ "XK_righttack", 0x0bfc }, 
{ "XK_hebrew_doublelowline", 0x0cdf }, 
{ "XK_hebrew_aleph", 0x0ce0 }, 
{ "XK_hebrew_bet", 0x0ce1 }, 
{ "XK_hebrew_beth", 0x0ce1 }, 
{ "XK_hebrew_gimel", 0x0ce2 }, 
{ "XK_hebrew_gimmel", 0x0ce2 }, 
{ "XK_hebrew_dalet", 0x0ce3 }, 
{ "XK_hebrew_daleth", 0x0ce3 }, 
{ "XK_hebrew_he", 0x0ce4 }, 
{ "XK_hebrew_waw", 0x0ce5 }, 
{ "XK_hebrew_zain", 0x0ce6 }, 
{ "XK_hebrew_zayin", 0x0ce6 }, 
{ "XK_hebrew_chet", 0x0ce7 }, 
{ "XK_hebrew_het", 0x0ce7 }, 
{ "XK_hebrew_tet", 0x0ce8 }, 
{ "XK_hebrew_teth", 0x0ce8 }, 
{ "XK_hebrew_yod", 0x0ce9 }, 
{ "XK_hebrew_finalkaph", 0x0cea }, 
{ "XK_hebrew_kaph", 0x0ceb }, 
{ "XK_hebrew_lamed", 0x0cec }, 
{ "XK_hebrew_finalmem", 0x0ced }, 
{ "XK_hebrew_mem", 0x0cee }, 
{ "XK_hebrew_finalnun", 0x0cef }, 
{ "XK_hebrew_nun", 0x0cf0 }, 
{ "XK_hebrew_samech", 0x0cf1 }, 
{ "XK_hebrew_samekh", 0x0cf1 }, 
{ "XK_hebrew_ayin", 0x0cf2 }, 
{ "XK_hebrew_finalpe", 0x0cf3 }, 
{ "XK_hebrew_pe", 0x0cf4 }, 
{ "XK_hebrew_finalzade", 0x0cf5 }, 
{ "XK_hebrew_finalzadi", 0x0cf5 }, 
{ "XK_hebrew_zade", 0x0cf6 }, 
{ "XK_hebrew_zadi", 0x0cf6 }, 
{ "XK_hebrew_qoph", 0x0cf7 }, 
{ "XK_hebrew_kuf", 0x0cf7 }, 
{ "XK_hebrew_resh", 0x0cf8 }, 
{ "XK_hebrew_shin", 0x0cf9 }, 
{ "XK_hebrew_taw", 0x0cfa }, 
{ "XK_hebrew_taf", 0x0cfa }, 
{ "XK_Hebrew_switch", 0xff7e }, 
{ "XK_Thai_kokai", 0x0da1 }, 
{ "XK_Thai_khokhai", 0x0da2 }, 
{ "XK_Thai_khokhuat", 0x0da3 }, 
{ "XK_Thai_khokhwai", 0x0da4 }, 
{ "XK_Thai_khokhon", 0x0da5 }, 
{ "XK_Thai_khorakhang", 0x0da6 }, 
{ "XK_Thai_ngongu", 0x0da7 }, 
{ "XK_Thai_chochan", 0x0da8 }, 
{ "XK_Thai_choching", 0x0da9 }, 
{ "XK_Thai_chochang", 0x0daa }, 
{ "XK_Thai_soso", 0x0dab }, 
{ "XK_Thai_chochoe", 0x0dac }, 
{ "XK_Thai_yoying", 0x0dad }, 
{ "XK_Thai_dochada", 0x0dae }, 
{ "XK_Thai_topatak", 0x0daf }, 
{ "XK_Thai_thothan", 0x0db0 }, 
{ "XK_Thai_thonangmontho", 0x0db1 }, 
{ "XK_Thai_thophuthao", 0x0db2 }, 
{ "XK_Thai_nonen", 0x0db3 }, 
{ "XK_Thai_dodek", 0x0db4 }, 
{ "XK_Thai_totao", 0x0db5 }, 
{ "XK_Thai_thothung", 0x0db6 }, 
{ "XK_Thai_thothahan", 0x0db7 }, 
{ "XK_Thai_thothong", 0x0db8 }, 
{ "XK_Thai_nonu", 0x0db9 }, 
{ "XK_Thai_bobaimai", 0x0dba }, 
{ "XK_Thai_popla", 0x0dbb }, 
{ "XK_Thai_phophung", 0x0dbc }, 
{ "XK_Thai_fofa", 0x0dbd }, 
{ "XK_Thai_phophan", 0x0dbe }, 
{ "XK_Thai_fofan", 0x0dbf }, 
{ "XK_Thai_phosamphao", 0x0dc0 }, 
{ "XK_Thai_moma", 0x0dc1 }, 
{ "XK_Thai_yoyak", 0x0dc2 }, 
{ "XK_Thai_rorua", 0x0dc3 }, 
{ "XK_Thai_ru", 0x0dc4 }, 
{ "XK_Thai_loling", 0x0dc5 }, 
{ "XK_Thai_lu", 0x0dc6 }, 
{ "XK_Thai_wowaen", 0x0dc7 }, 
{ "XK_Thai_sosala", 0x0dc8 }, 
{ "XK_Thai_sorusi", 0x0dc9 }, 
{ "XK_Thai_sosua", 0x0dca }, 
{ "XK_Thai_hohip", 0x0dcb }, 
{ "XK_Thai_lochula", 0x0dcc }, 
{ "XK_Thai_oang", 0x0dcd }, 
{ "XK_Thai_honokhuk", 0x0dce }, 
{ "XK_Thai_paiyannoi", 0x0dcf }, 
{ "XK_Thai_saraa", 0x0dd0 }, 
{ "XK_Thai_maihanakat", 0x0dd1 }, 
{ "XK_Thai_saraaa", 0x0dd2 }, 
{ "XK_Thai_saraam", 0x0dd3 }, 
{ "XK_Thai_sarai", 0x0dd4 }, 
{ "XK_Thai_saraii", 0x0dd5 }, 
{ "XK_Thai_saraue", 0x0dd6 }, 
{ "XK_Thai_sarauee", 0x0dd7 }, 
{ "XK_Thai_sarau", 0x0dd8 }, 
{ "XK_Thai_sarauu", 0x0dd9 }, 
{ "XK_Thai_phinthu", 0x0dda }, 
{ "XK_Thai_baht", 0x0ddf }, 
{ "XK_Thai_sarae", 0x0de0 }, 
{ "XK_Thai_saraae", 0x0de1 }, 
{ "XK_Thai_sarao", 0x0de2 }, 
{ "XK_Thai_saraaimaimuan", 0x0de3 }, 
{ "XK_Thai_saraaimaimalai", 0x0de4 }, 
{ "XK_Thai_lakkhangyao", 0x0de5 }, 
{ "XK_Thai_maiyamok", 0x0de6 }, 
{ "XK_Thai_maitaikhu", 0x0de7 }, 
{ "XK_Thai_maiek", 0x0de8 }, 
{ "XK_Thai_maitho", 0x0de9 }, 
{ "XK_Thai_maitri", 0x0dea }, 
{ "XK_Thai_maichattawa", 0x0deb }, 
{ "XK_Thai_thanthakhat", 0x0dec }, 
{ "XK_Thai_nikhahit", 0x0ded }, 
{ "XK_Thai_leksun", 0x0df0 }, 
{ "XK_Thai_leknung", 0x0df1 }, 
{ "XK_Thai_leksong", 0x0df2 }, 
{ "XK_Thai_leksam", 0x0df3 }, 
{ "XK_Thai_leksi", 0x0df4 }, 
{ "XK_Thai_lekha", 0x0df5 }, 
{ "XK_Thai_lekhok", 0x0df6 }, 
{ "XK_Thai_lekchet", 0x0df7 }, 
{ "XK_Thai_lekpaet", 0x0df8 }, 
{ "XK_Thai_lekkao", 0x0df9 }, 
{ "XK_Hangul", 0xff31 }, 
{ "XK_Hangul_Start", 0xff32 }, 
{ "XK_Hangul_End", 0xff33 }, 
{ "XK_Hangul_Hanja", 0xff34 }, 
{ "XK_Hangul_Jamo", 0xff35 }, 
{ "XK_Hangul_Romaja", 0xff36 }, 
{ "XK_Hangul_Codeinput", 0xff37 }, 
{ "XK_Hangul_Jeonja", 0xff38 }, 
{ "XK_Hangul_Banja", 0xff39 }, 
{ "XK_Hangul_PreHanja", 0xff3a }, 
{ "XK_Hangul_PostHanja", 0xff3b }, 
{ "XK_Hangul_SingleCandidate", 0xff3c }, 
{ "XK_Hangul_MultipleCandidate", 0xff3d }, 
{ "XK_Hangul_PreviousCandidate", 0xff3e }, 
{ "XK_Hangul_Special", 0xff3f }, 
{ "XK_Hangul_switch", 0xff7e }, 
{ "XK_Korean_Won", 0x0eff }, 
{ "XK_EuroSign", 0x20ac }, 
{ 0, 0 }};

static const char *
nameForKeycode(int keycode)
{	KeyNameEntry *kne;

	for (kne = codes; kne->name; kne++)
		if (kne->code == keycode)
			return kne->name;

	return "UNKNOWN CODE";
}

static const char *
nameForKeyboardEvent(XEvent *evt) { return nameForKeycode(evt->xkey.keycode); }
#endif /* DEBUG_EVENTS */

static void handleEvent(XEvent *evt)
{
#if DEBUG_EVENTS
  switch (evt->type)
    {
    case ButtonPress:
      fprintf(stderr, "\n(handleEvent)X ButtonPress   state 0x%x button %d\n",
	      evt->xbutton.state, evt->xbutton.button);
      break;
    case ButtonRelease:
      fprintf(stderr, "\n(handleEvent)X ButtonRelease state 0x%x button %d\n",
	      evt->xbutton.state, evt->xbutton.button);
      break;
    case KeyPress:
      fprintf(stderr, "\n(handleEvent)X KeyPress      state 0x%x raw keycode %d\n",
	      evt->xkey.state, evt->xkey.keycode);
      break;
    case KeyRelease:
      fprintf(stderr, "\n(handleEvent)X KeyRelease    state 0x%x raw keycode %d\n",
	      evt->xkey.state, evt->xkey.keycode);
      break;
    }
#endif /* DEBUG_EVENTS */

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

#if defined(DEBUG_FOCUS)
  if ((evt->type != EnterNotify) && (evt->type != LeaveNotify) && (evt->type != MotionNotify))
    {
      static char *eventName[]=	{
	"KeyPress", "KeyRelease", "ButtonPress", "ButtonRelease",
	"MotionNotify", "EnterNotify", "LeaveNotify", "FocusIn",
	"FocusOut", "KeymapNotify", "Expose", "GraphicsExpose",
	"NoExpose", "VisibilityNotify", "CreateNotify", "DestroyNotify",
	"UnmapNotify", "MapNotify", "MapRequest", "ReparentNotify",
	"ConfigureNotify", "ConfigureRequest", "GravityNotify",
	"ResizeRequest", "CirculateNotify", "CirculateRequest",
	"PropertyNotify", "SelectionClear", "SelectionRequest",
	"SelectionNotify", "ColormapNotify", "ClientMessage",
	"MappingNotify", "LASTEvent", 0
      };
      static char *modeName[]= { "Normal", "Grab", "Ungrab", "WhileGrabbed", 0 };
      static char *detailName[]= {
	"Ancestor", "Virtual", "Inferior", "Nonlinear", "NonlinearVirtual",
	"Pointer", "PointerRoot", "DetailNone", 0
      };
      fprintf(stderr, eventName[evt->type-2]);
      if (evt->xany.window == stParent)
	fprintf(stderr, " window=stParent");
      else if (evt->xany.window ==  stWindow)
	fprintf(stderr, " window=stWindow");
      else
	fprintf(stderr, " window=%x", evt->xany.window);
      if (evt->type == FocusIn || evt->type == FocusOut)
	fprintf(stderr, " mode=Notify%s detail=Notify%s\n", modeName[evt->xfocus.mode],	detailName[evt->xfocus.detail]);
      else
	fprintf(stderr, "\n");
    }
#endif
  if (True == XFilterEvent(evt, 0))
    return;

  switch (evt->type)
    {
    case MotionNotify:
      noteEventState(evt->xmotion);
      recordMouseEvent();
      break;

    case FocusIn:
      if (evt->xfocus.mode == NotifyNormal || evt->xfocus.mode == NotifyUngrab)
	{
	  switch (evt->xfocus.detail)
	    {
	    case NotifyNonlinear:
	    case NotifyInferior:
	      XSetInputFocus(stDisplay, stWindow, RevertToNone, CurrentTime);
	      break;
	    case NotifyAncestor:
#            if defined(INIT_INPUT_WHEN_FOCUSED_IN)
	      initInput();
#            endif
	      if (inputContext)
		{
		  setInputContextArea();
		  XSetICFocus(inputContext);
		}
	      break;
	    }
	}
      break;

    case FocusOut:
      if (inputContext && (evt->xfocus.mode == NotifyNormal) && (evt->xfocus.detail == NotifyNonlinear))
	XUnsetICFocus(inputContext);
      break;

#if 0
    case EnterNotify:
      if (inputContext && evt->xcrossing.focus && !(inputStyle & XIMPreeditPosition))
	{
	  setInputContextArea();
	  XSetICFocus(inputContext);
	}
      break;

    case LeaveNotify:
      if (inputContext && evt->xcrossing.focus && !(inputStyle & XIMPreeditPosition))
	XUnsetICFocus(inputContext);
      break;
#endif

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
	    recordKeyboardEvent(keyCode, EventKeyDown, modifiers, keyCode);
	    recordKeyboardEvent(keyCode, EventKeyChar, modifiers, keyCode);
	    recordKeyboardEvent(keyCode, EventKeyUp,   modifiers, keyCode);
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
	KeySym symbolic;
	int keyCode= x2sqKey(&evt->xkey, &symbolic);
	int ucs4= xkeysym2ucs4(symbolic);
	DCONV_FPRINTF(stderr, "symbolic, keyCode, ucs4: %x, %d, %d\n", symbolic, keyCode, ucs4);
	DCONV_FPRINTF(stderr, "pressed, buffer: %d, %x\n", multi_key_pressed, multi_key_buffer);
	if (multi_key_pressed && multi_key_buffer == 0)
	  {
	    switch (ucs4)
	      {
#              define key_case(sym, code)		\
	        case sym:				\
	          multi_key_buffer= (code);		\
		  keyCode= -1;				\
	          ucs4= -1;				\
	          break;
		key_case(0x60, 0x0300); /* grave */
		key_case(0x27, 0x0301); /* apostrophe */
		key_case(0x5e, 0x0302); /* circumflex */
		key_case(0x7e, 0x0303); /* tilde */
		key_case(0x22, 0x0308); /* double quote */
		key_case(0x61, 0x030a); /* a */
#              undef key_case
	      }
	  }
	else
	  {
	  switch (symbolic)
	    {
#            define dead_key_case(sym, code, orig)	\
	      case sym:					\
	        if (multi_key_buffer == code)		\
		  {					\
		    multi_key_buffer= 0;		\
		    keyCode= orig;			\
		    ucs4= orig;				\
		  }					\
		else					\
		  {					\
		    multi_key_buffer= (code);		\
		    keyCode= -1;			\
		    ucs4= -1;				\
		  }					\
	        break;
	      dead_key_case(XK_dead_grave, 0x0300, 0x60);
	      dead_key_case(XK_dead_acute, 0x0301, 0x27);
	      dead_key_case(XK_dead_circumflex, 0x0302, 0x5e);
	      dead_key_case(XK_dead_tilde, 0x0303, 0x7e);
	      dead_key_case(XK_dead_macron, 0x0304, 0x0304);
	      dead_key_case(XK_dead_abovedot, 0x0307, 0x0307);
	      dead_key_case(XK_dead_diaeresis, 0x0308, 0x0308);
	      dead_key_case(XK_dead_abovering, 0x030A, 0x030A);
	      dead_key_case(XK_dead_doubleacute, 0x030B, 0x030B);
	      dead_key_case(XK_dead_caron, 0x030C, 0x030C);
	      dead_key_case(XK_dead_cedilla, 0x0327, 0x0327);
	      dead_key_case(XK_dead_ogonek, 0x0328, 0x0328);
	      dead_key_case(XK_dead_iota, 0x0345, 0x0345);
	      dead_key_case(XK_dead_voiced_sound, 0x3099, 0x3099);
	      dead_key_case(XK_dead_semivoiced_sound, 0x309a, 0x309a);
	      dead_key_case(XK_dead_belowdot, 0x0323, 0x0323);
	      dead_key_case(XK_dead_hook, 0x0309, 0x0309);
	      dead_key_case(XK_dead_horn, 0x031b, 0x031b);
#            undef dead_key_case
	    }
	  if (symbolic != XK_Multi_key)
	    {
	      multi_key_pressed= 0; 
	      DCONV_FPRINTF(stderr, "multi_key reset\n");
	    }
	  }
	DCONV_FPRINTF(stderr, "keyCode, ucs4, multi_key_buffer: %d, %d, %x\n", keyCode, ucs4, multi_key_buffer);
	if (keyCode >= 0)
	  {
	    recordKeystroke(keyCode);			/* DEPRECATED */
	    if (multi_key_buffer != 0)
	      recordKeystroke(multi_key_buffer);
	  }
	if ((keyCode >= 0) || (ucs4 > 0))
	  {
	    recordKeyboardEvent(keyCode, EventKeyDown, modifierState, ucs4);
	    if (ucs4) /* only generate a key char event if there's a code. */
		recordKeyboardEvent(keyCode, EventKeyChar, modifierState, ucs4);
	    if (multi_key_buffer != 0)
	      {
		recordKeyboardEvent(multi_key_buffer, EventKeyDown, modifierState, multi_key_buffer);
		recordKeyboardEvent(multi_key_buffer, EventKeyChar, modifierState, multi_key_buffer);
		multi_key_buffer= 0;
	      }
	  }
      }
      break;

    case KeyRelease:
      noteEventState(evt->xkey);
      {
	KeySym symbolic;
	int keyCode, ucs4;
	if (XPending(stDisplay))
	  {
	    XEvent evt2;
	    XPeekEvent(stDisplay, &evt2);
	    if ((evt2.type == KeyPress) && (evt2.xkey.keycode == evt->xkey.keycode) && ((evt2.xkey.time - evt->xkey.time < 2)))
	      break;
	  }
	keyCode= x2sqKey(&evt->xkey, &symbolic);
	ucs4= xkeysym2ucs4(symbolic);
	if ((keyCode >= 0) || (ucs4 > 0))
	  recordKeyboardEvent(keyCode, EventKeyUp, modifierState, ucs4);
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

#  if 0
    case VisibilityNotify:
      {
	static int previousState= VisibilityFullyObscured;
	XVisibilityEvent *ex= &evt->xvisibility;
	if (ex->state < previusState)
	  fullDisplayUpdate();
	previousState= ex->state;
      }
#  endif

    case MapNotify:
      /* The window has just been mapped, possibly for the first
	 time: update mousePosition (which otherwise may not be
	 set before the first button event). */
      getMousePosition();
      noteWindowChange();
      fullDisplayUpdate();
#    if defined(INIT_INPUT_WHEN_MAPPED)
      initInput();
#    endif
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

    case ClientMessage:
      if (wmProtocolsAtom == evt->xclient.message_type && wmDeleteWindowAtom == evt->xclient.data.l[0])
	recordWindowEvent(WindowEventClose, 0, 0, 0, 0, 1); /* windowIndex 1 is main window */
      break;

#  if defined(USE_XSHM)
    default:
      if (evt->type == completionType)
	--completions;
      break;
#  endif
    }

  if (useXdnd)
    dndHandleEvent(evt->type, evt);

# undef noteEventState
}


int handleEvents(void)
{
  if (recordPendingKeys())
    return 0;
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
  char buf[1024];
  XGetErrorText(dpy, evt->error_code, buf, sizeof(buf));
  fprintf(stderr,
	  "X Error: %s\n"
	  "  Major opcode of failed request:  %ld\n"
	  "  Minor opcode of failed request:  %ld\n"
	  "  Serial number of failed request: %ld\n",
	  buf,
	  (long)evt->request_code,
	  (long)evt->minor_code,
	  (long)evt->serial);
  return 0;
}


void initWindow(char *displayName)
{
  XRectangle windowBounds= { 0, 0, 640, 480 };  /* default window bounds */
  int right, bottom;

#ifdef PharoVM
  // Some libraries require Xlib multi-threading support. When using
  // multi-threading XInitThreads() has to be first Xlib function called.
  XInitThreads();
#endif

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
      { 24, TrueColor },
      { 24, DirectColor },
      { 24, StaticColor },
      { 24, PseudoColor },
      { 16, TrueColor },
      { 16, DirectColor },
      { 16, StaticColor },
      { 16, PseudoColor },
      { 32, TrueColor },    /* 32 has alpha problems when compositing */
      { 32, DirectColor },
      { 32, StaticColor },
      { 32, PseudoColor },
      {  8, PseudoColor },
      {  8, DirectColor },
      {  8, TrueColor },
      {  8, StaticColor },
      {  0, 0 }
    };

    XVisualInfo viz;
    int i;

    stVisual= DefaultVisual(stDisplay, DefaultScreen(stDisplay));
    stDepth= DefaultDepth(stDisplay, DefaultScreen(stDisplay));

    if ((24 == stDepth) || (16 == stDepth))
      {
#      if defined(DEBUG_VISUAL)
	fprintf(stderr, "Using default visual (%d bits).\n", stDepth);
#      endif
      }
    else
      {
	for (i= 0; trialVisuals[i][0] != 0; ++i)
	  {
#          if defined(DEBUG_VISUAL)
	    fprintf(stderr, "Trying %d bit %s.\n", trialVisuals[i][0], debugVisual(trialVisuals[i][1]));
#          endif
	    if (XMatchVisualInfo(stDisplay, DefaultScreen(stDisplay), trialVisuals[i][0], trialVisuals[i][1], &viz) != 0)
	      break;
	  }
	if (trialVisuals [i][0] == 0)
	  {
#	   if defined(DEBUG_VISUAL)
	    fprintf(stderr, "Using default visual (%d bits).\n", stDepth);
#	   endif
	  }
	else
	  {
	    stVisual= viz.visual;
	    stDepth= trialVisuals[i][0];
	  }
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
	valuemask |= CWColormap;
	parentValuemask |= CWColormap;
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
#      if defined(SUGAR)
        if (sugarBundleId)
          XChangeProperty(stDisplay, stParent,
                          XInternAtom(stDisplay, "_SUGAR_BUNDLE_ID", 0), XA_STRING, 8,
			  PropModeReplace, (unsigned char *)sugarBundleId, strlen(sugarBundleId));

        if (sugarActivityId)
          XChangeProperty(stDisplay, stParent,
                          XInternAtom(stDisplay, "_SUGAR_ACTIVITY_ID", 0), XA_STRING, 8,
                          PropModeReplace, (unsigned char *)sugarActivityId, strlen(sugarActivityId));
#      endif /* defined(SUGAR) */

        { unsigned long pid = getpid();
	XChangeProperty(stDisplay, stParent,
			XInternAtom(stDisplay, "_NET_WM_PID", 0),
			XA_CARDINAL, 32, PropModeReplace,
			(unsigned char *)&pid, 1);
	}
	/* This is needed for PersonalShare, see sqUnixX11PShare.c */
	{ Atom normal = XInternAtom(stDisplay, "_NET_WM_WINDOW_TYPE_NORMAL", 0);
	XChangeProperty(stDisplay, stParent,
			XInternAtom(stDisplay, "_NET_WM_WINDOW_TYPE", 0),
			XA_ATOM, 32, PropModeReplace, 
			(unsigned char *)&normal, 1);
	}
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
	XStoreName(stDisplay, stParent, defaultWindowLabel);
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

  /* tell the WM that we do not want to be destroyed from the title bar close button */
  {
    wmProtocolsAtom=    XInternAtom(stDisplay, "WM_PROTOCOLS", False);
    wmDeleteWindowAtom= XInternAtom(stDisplay, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(stDisplay, stParent, &wmDeleteWindowAtom, 1);
  }

  /* create a suitable graphics context */
  {
    XGCValues gcValues;

    gcValues.function= GXcopy;
    gcValues.line_width= 0;
    gcValues.subwindow_mode= ClipByChildren; /* was IncludeInferiors */
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

/* Support for translateCode.  For KeyPress set meta.  For KeyRelease clear
 * notmeta.  Of course this is simplistic and wrong because it doesn't deal
 * with left and right versions of the key.  e.g. the key sequence
 * press left press right lift left lift right will release before lift right.
 */
static inline int
withMetaSet(int code, int meta, int notmeta, int *modStatp, XKeyEvent *evt)
{
	if (modStatp)
		*modStatp = evt->type == KeyPress
						? x2sqModifier(evt->state) | meta
						: x2sqModifier(evt->state) & ~notmeta;
	return code;
}

static int
translateCode(KeySym symbolic, int *modp, XKeyEvent *evt)
{
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

    case XK_KP_Left:	return 28;
    case XK_KP_Up:	return 30;
    case XK_KP_Right:	return 29;
    case XK_KP_Down:	return 31;
    case XK_KP_Insert:	return  5;
    case XK_KP_Prior:	return 11;	/* page up */
    case XK_KP_Next:	return 12;	/* page down */
    case XK_KP_Home:	return  1;
    case XK_KP_End:	return  4;

    /* "aliases" for Sun keyboards */
    case XK_R9:		return 11;	/* page up */
    case XK_R15:	return 12;	/* page down */
    case XK_R7:		return  1;	/* home */
    case XK_R13:	return  4;	/* end */

	/* if this is a key down event return the char with ALT/CommandKey set */
    case XK_L1: /* stop */
		return withMetaSet('.',CommandKeyBit,CommandKeyBit,modp,evt);
    case XK_L2: /* again */
		return withMetaSet('j',CommandKeyBit,CommandKeyBit,modp,evt);
    case XK_L4: /* undo */
		return withMetaSet('z',CommandKeyBit,CommandKeyBit,modp,evt);
    case XK_L6: /* copy */
		return withMetaSet('c',CommandKeyBit,CommandKeyBit,modp,evt);
    case XK_L8: /* paste */
		return withMetaSet('v',CommandKeyBit,CommandKeyBit,modp,evt);
    case XK_L9: /* find */
		return withMetaSet('f',CommandKeyBit,CommandKeyBit,modp,evt);
    case XK_L10:/* cut */
		return withMetaSet('x',CommandKeyBit,CommandKeyBit,modp,evt);

    /* XKB extensions */
# if defined(XK_ISO_Left_Tab)
    case XK_ISO_Left_Tab: return  9;	/* shift-tab */
# endif

# if defined(XF86XK_Start)
    case XF86XK_Start: /* OLPC view source */
		return withMetaSet(',',CommandKeyBit,CommandKeyBit,modp,evt);
# endif

# if defined(XK_Control_L)
	/* For XK_Shift_L, XK_Shift_R, XK_Caps_Lock & XK_Shift_Lock we can't just
	 * use the SHIFT metastate since it would generate key codes. We use
	 * META + SHIFT as these are all meta keys (meta == OptionKeyBit).
	 */
	case XK_Shift_L:
		return withMetaSet(255,OptionKeyBit+ShiftKeyBit,ShiftKeyBit,modp,evt);
	case XK_Shift_R:
		return withMetaSet(254,OptionKeyBit+ShiftKeyBit,ShiftKeyBit,modp,evt);
	case XK_Caps_Lock:
		return withMetaSet(253,OptionKeyBit+ShiftKeyBit,ShiftKeyBit,modp,evt);
	case XK_Shift_Lock:
		return withMetaSet(252,OptionKeyBit+ShiftKeyBit,ShiftKeyBit,modp,evt);
	case XK_Control_L:
		return withMetaSet(251,OptionKeyBit+CtrlKeyBit,CtrlKeyBit,modp,evt);
	case XK_Control_R:
		return withMetaSet(250,OptionKeyBit+CtrlKeyBit,CtrlKeyBit,modp,evt);
	case XK_Meta_L:
		return withMetaSet(249,OptionKeyBit,0,modp,evt);
	case XK_Meta_R:
		return withMetaSet(248,OptionKeyBit,0,modp,evt);
	case XK_Alt_L:
		return withMetaSet(247,OptionKeyBit+CommandKeyBit,OptionKeyBit,modp,evt);
	case XK_Alt_R:
		return withMetaSet(246,OptionKeyBit+CommandKeyBit,OptionKeyBit,modp,evt);
# endif

    default:;
    }
  return -1;
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
  aioSleepForUsecs(handleEvents() ? 0 : microSeconds);
  return 0;
}


static sqInt display_ioProcessEvents(void)
{
  LogEventChain((dbgEvtChF,"ioPE."));
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


static double display_ioScreenScaleFactor(void)
{
  return 1.0;
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
#    if defined (USE_XSHM)
      if (useXshm && !isAligned(void *, xWidth))
	{
	  xWidth= align(void *, xWidth);
	  if (!browserWindow)
	    {
	      XResizeWindow(stDisplay, stParent, xWidth, xHeight);
	    }
	}
#    endif
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

static int fakeBigCursor()
{
  static int fake= -1;

  if (-1 == fake)
    { 
      char *value= getenv("SQUEAK_FAKEBIGCURSOR");
      fake= value && (atoi(value) > 0);
    }

  return fake;
}

static sqInt display_ioSetCursorWithMaskBig(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY);

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

  if (fakeBigCursor())
    return display_ioSetCursorWithMaskBig(cursorBitsIndex, cursorMaskIndex, offsetX, offsetY);

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


static sqInt display_ioSetCursorWithMaskBig(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
  unsigned int *cursorBits= (unsigned int *)pointerForOop(cursorBitsIndex);
  unsigned int *cursorMask= (unsigned int *)pointerForOop(cursorMaskIndex);
  unsigned int data[32], mask[32], d, m;	/* cursors are rescaled from 16x16 to 32x32*/
  int i, j;
  Cursor cursor;
  Pixmap dataPixmap, maskPixmap;

  if (!isConnectedToXServer)
    return 0;

  if (cursorMaskIndex == null)
    cursorMask= cursorBits;

  for (i= 0; i < 32; i++)
    {
      for (j= 0; j < 32; j++)
	{
	  d= (d<<1) | ((cursorBits[i/2] >> (16 + j/2)) & 1);
	  m= (m<<1) | ((cursorMask[i/2] >> (16 + j/2)) & 1);
	}
      data[i]= d;
      mask[i]= m;
    }
 
  dataPixmap= XCreateBitmapFromData(stDisplay,
				    DefaultRootWindow(stDisplay),
				    (char *)data, 32, 32);
  maskPixmap= XCreateBitmapFromData(stDisplay,
				    DefaultRootWindow(stDisplay),
				    (char *)mask, 32, 32);
  cursor= XCreatePixmapCursor(stDisplay, dataPixmap, maskPixmap,
			      &stColorBlack, &stColorWhite,
			      -offsetX*2, -offsetY*2);

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


static sqInt display_ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
#if defined(HAVE_LIBXRENDER) && (RENDER_MAJOR > 0 || RENDER_MINOR >= 5)
  int eventbase, errorbase;
  int major= 0, minor= 0; 
  XImage *image;
  Pixmap pixmap;
  GC gc;
  XRenderPictFormat *pictformat;
  Picture picture;
  Cursor cursor;

  if (fakeBigCursor())
    return 0;

  if (!XRenderQueryExtension(stDisplay, &eventbase, &errorbase))
    return 0;

  XRenderQueryVersion(stDisplay, &major, &minor);
  if (!(major > 0 || minor >= 5))
    return 0;

  image= XCreateImage(stDisplay, DefaultVisual(stDisplay, DefaultScreen(stDisplay)), 32, ZPixmap, 0, (char *)pointerForOop(cursorBitsIndex), extentX, extentY, 32, 0);
  pixmap= XCreatePixmap (stDisplay, DefaultRootWindow(stDisplay), extentX, extentY, 32);
  gc= XCreateGC(stDisplay, pixmap, 0, 0);
  XPutImage(stDisplay, pixmap, gc, image, 0, 0, 0, 0, extentX, extentY);
  image->data= 0; /* otherwise XDestroyImage tries to free this */
  pictformat= XRenderFindStandardFormat(stDisplay, PictStandardARGB32);
  picture= XRenderCreatePicture(stDisplay, pixmap, pictformat, 0, 0);
  cursor= XRenderCreateCursor(stDisplay, picture, -offsetX, -offsetY);

  XDefineCursor(stDisplay, stWindow, cursor);
  XDestroyImage(image);
  XFreeGC(stDisplay, gc);
  XFreeCursor(stDisplay, cursor);
  XRenderFreePicture(stDisplay, picture);
  XFreePixmap(stDisplay, pixmap);

  return 1;
#else
  return 0;
#endif
}


static void overrideRedirect(Display *dpy, Window win, int flag)
{
  XSetWindowAttributes attrs;
  attrs.override_redirect= flag;
  XChangeWindowAttributes(dpy, win, CWOverrideRedirect, &attrs);
}


static void enterFullScreenMode(Window root)
{
  XSynchronize(stDisplay, True);
  overrideRedirect(stDisplay, stWindow, True);
  XReparentWindow(stDisplay, stWindow, root, 0, 0);
#if 1
  XResizeWindow(stDisplay, stWindow, scrW, scrH);
#else
  XResizeWindow(stDisplay, stParent, scrW, scrH);
#endif
  XLowerWindow(stDisplay, stParent);
  XRaiseWindow(stDisplay, stWindow);
  XSetInputFocus(stDisplay, stWindow, RevertToPointerRoot, CurrentTime);
  XSynchronize(stDisplay, False);
}


static void returnFromFullScreenMode()
{
  XSynchronize(stDisplay, True);
  XRaiseWindow(stDisplay, stParent);
  XReparentWindow(stDisplay, stWindow, stParent, 0, 0);
  overrideRedirect(stDisplay, stWindow, False);
#if 1
  XResizeWindow(stDisplay, stWindow, scrW, scrH);
#else
  XResizeWindow(stDisplay, stParent, winW, winH);
#endif
  XSetInputFocus(stDisplay, stWindow, RevertToPointerRoot, CurrentTime);
  XSynchronize(stDisplay, False);
}


static void sendFullScreenHint(int enable)
{
  XEvent xev;
  Atom wm_state = XInternAtom(stDisplay, "_NET_WM_STATE", False);
  Atom fullscreen = XInternAtom(stDisplay, "_NET_WM_STATE_FULLSCREEN", False);

  memset(&xev, 0, sizeof(xev));
  xev.type = ClientMessage;
  xev.xclient.window = stParent;
  xev.xclient.message_type = wm_state;
  xev.xclient.format = 32;
  xev.xclient.data.l[0] = enable; /* 1 enable, 0 disable fullscreen */
  xev.xclient.data.l[1] = fullscreen;
  xev.xclient.data.l[2] = 0;
  XSendEvent(stDisplay, DefaultRootWindow(stDisplay), False, SubstructureRedirectMask | SubstructureNotifyMask, &xev);
}


static sqInt display_ioSetFullScreen(sqInt fullScreen)
{
  int winX, winY;
  unsigned int winW, winH;

  setFullScreenFlag(fullScreen);
  if (!isConnectedToXServer)
    return 1;

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
	  if (fullScreenDirect)
	    enterFullScreenMode(root); /* simple window manager, e.g. twm */
	  else
	    sendFullScreenHint(1);  /* Required for Compiz window manager */
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
	  if (fullScreenDirect)
	    returnFromFullScreenMode(); /* simple window manager, e.g. twm */
	  else
	    sendFullScreenHint(0);  /* Required for Compiz window manager */
	  windowState= WIN_CHANGED;
	}
    }
  /* sync avoids race with ioScreenSize() reading geometry before resize event */
  XSync(stDisplay, False);
  getMousePosition();

  return 1;
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
  setSavedWindowSize((width << 16) + (height & 0xFFFF));
  setFullScreenFlag(fullScreen);
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

#if defined(ENABLE_FAST_BLT)
# if defined(__arm__)

    extern void armSimdConvert_x888_8_LEPacking32_8_wide(unsigned int width, unsigned int height,
							 unsigned int *dst, unsigned int dstStride,
							 unsigned int *src, unsigned int srcStride,
							 unsigned int halftone, unsigned int halftoneInfo,
							 unsigned int *colourMap);

    extern void armSimdConvert_x888_8_LEPacking32_8_narrow(unsigned int width, unsigned int height,
							   unsigned int *dst, unsigned int dstStride,
							   unsigned int *src, unsigned int srcStride,
							   unsigned int halftone, unsigned int halftoneInfo,
							   unsigned int *colourMap);

    static void armSimdCopyImage32To8(int *fromImageData, int *toImageData, int width, int height,
				      int affectedL, int affectedT, int affectedR, int affectedB,
				      unsigned int *downGradingColors)
    {
      /* Find image strides in 32-bit words */
      unsigned int srcStride= width;
      unsigned int dstStride= (width + 3) >> 2;
      /* Round affected region out to encompass complete words in both images */
      affectedL &= ~3;
      affectedR= (affectedR + 3) &~ 3;
      width=  affectedR - affectedL;
      height= affectedB - affectedT;
      /* Find first words */
      fromImageData += srcStride * affectedT + affectedL;
      toImageData += dstStride * affectedT + (affectedL >> 2);
      /* Adjust strides to remove number of words read/written */
      srcStride -= affectedR - affectedL;
      dstStride -= (affectedR - affectedL) >> 2;
      /* Work out which width class this operation is. */
      if (width > (128 - 32) / 8 && ((-1 ^ (width -(128 - 32) / 8)) & ~(31 / 8)))
	armSimdConvert_x888_8_LEPacking32_8_wide(width, height, toImageData, dstStride, fromImageData, srcStride, 0, 0, downGradingColors);
      else
	armSimdConvert_x888_8_LEPacking32_8_narrow(width, height, toImageData, dstStride, fromImageData, srcStride, 0, 0, downGradingColors);
    }
# else
#   error configuration error
# endif
#endif

void copyImage32To8(int *fromImageData, int *toImageData, int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
#if defined(ENABLE_FAST_BLT)
# if defined(__arm__)
    armSimdCopyImage32To8(fromImageData, toImageData, width, height, affectedL, affectedT, affectedR, affectedB, stDownGradingColors);
# else
#   error configuration error
# endif
#else
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
#endif /* !ENABLE_FAST_BLT */
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

#if defined(ENABLE_FAST_BLT)
# if defined(__arm__)

    extern void armSimdConvert_x888_0565_LEPacking32_16_wide(unsigned int width, unsigned int height,
							     unsigned int *dst, unsigned int dstStride,
							     unsigned int *src, unsigned int srcStride);

    extern void armSimdConvert_x888_0565_LEPacking32_16_narrow(unsigned int width, unsigned int height,
							       unsigned int *dst, unsigned int dstStride,
							       unsigned int *src, unsigned int srcStride);
    static void armSimdCopyImage32To16(int *fromImageData, int *toImageData, int width, int height,
				       int affectedL, int affectedT, int affectedR, int affectedB)
    {
      /* Find image strides in 32-bit words */
      unsigned int srcStride= width;
      unsigned int dstStride= (width + 1) >> 1;
      /* Round affected region out to encompass complete words in both images */
      affectedL &= ~1;
      affectedR += affectedR & 1;
      width=  affectedR - affectedL;
      height= affectedB - affectedT;
      /* Find first words */
      fromImageData += srcStride * affectedT + affectedL;
      toImageData += dstStride * affectedT + (affectedL >> 1);
      /* Adjust strides to remove number of words read/written */
      srcStride -= affectedR - affectedL;
      dstStride -= (affectedR - affectedL) >> 1;
      /* Work out which width class this operation is. */
      if (width > (128 - 32) / 16 && ((-1 ^ (width - (128 - 32) / 16)) & ~(31 / 16)))
	  armSimdConvert_x888_0565_LEPacking32_16_wide(width, height, toImageData, dstStride, fromImageData, srcStride);
      else
	  armSimdConvert_x888_0565_LEPacking32_16_narrow(width, height, toImageData, dstStride, fromImageData, srcStride);
    }

# else
#   error configuration error
# endif
#endif

void copyImage32To16(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
#if defined(ENABLE_FAST_BLT)
# if defined(__arm__)
  if (stRNMask == 5 && stRShift == 11 && stGNMask == 6 && stGShift == 5 && stBNMask == 5 && stBShift == 0)
    armSimdCopyImage32To16(fromImageData, toImageData, width, height, affectedL, affectedT, affectedR, affectedB);
  else
# else
#  error configuration error
# endif
#endif
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


#if defined(ENABLE_FAST_BLT)
# if defined(__arm__)
    extern void armSimdConvert_x888_x888BGR_LEPacking32_32_wide(unsigned int width, unsigned int height,
								unsigned int *dst, unsigned int dstStride,
								unsigned int *src, unsigned int srcStride);

    extern void armSimdConvert_x888_x888BGR_LEPacking32_32_narrow(unsigned int width, unsigned int height,
								  unsigned int *dst, unsigned int dstStride,
								  unsigned int *src, unsigned int srcStride);

    static void armSimdCopyImage32To32(int *fromImageData, int *toImageData, int width, int height,
				       int affectedL, int affectedT, int affectedR, int affectedB)
    {
      unsigned int stride= width;
      width=  affectedR - affectedL;
      height= affectedB - affectedT;
      /* Find first words */
      fromImageData += stride * affectedT + affectedL;
      toImageData   += stride * affectedT + affectedL;
      /* Adjust stride to remove number of words read/written */
      stride -= width;
      /* Work out which width class this operation is. */
      if (width > (128 - 32) / 32 && (-1 ^ (width - (128 - 32) / 32)))
	armSimdConvert_x888_x888BGR_LEPacking32_32_wide(width, height, toImageData, stride, fromImageData, stride);
      else
	armSimdConvert_x888_x888BGR_LEPacking32_32_narrow(width, height, toImageData, stride, fromImageData, stride);
    }
# else
#   error configuration error
# endif
#endif


void copyImage32To32(int *fromImageData, int *toImageData, int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
#if defined(ENABLE_FAST_BLT)
# if defined(__arm__)
    if ((armCpuFeatures & ARM_V6) && stRNMask == 8 && stRShift == 0 && stGNMask == 8 && stGShift == 8 && stBNMask == 8 && stBShift == 16)
      armSimdCopyImage32To32(fromImageData, toImageData, width, height, affectedL, affectedT, affectedR, affectedB);
    else
# else
#  error unsupported use of ENABLE_FAST_BLT
# endif
#endif
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
	  4 == write(browserPipes[1], &stWindow, 4);
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
  inputContext= 0;
  inputFont= NULL;
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
      if (inputContext)
        {
	  XIM im= XIMOfIC(inputContext);
	  XDestroyIC(inputContext);
	  if (im) XCloseIM(im);
	}
      if (inputFont)
	XFreeFontSet(stDisplay, inputFont);
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

  DPRINTF3D(3, (fp, "---- Creating new renderer ----\r\r"));

  /* sanity checks */
  if (w < 0 || h < 0)
    {
      DPRINTF3D(1, (fp, "Negative extent (%i@%i)!\r", w, h));
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
	DPRINTF3D(1, (fp, "No OpenGL visual found!\r"));
	goto fail;
      }
    DPRINTF3D(3, (fp, "\r#### Selected GLX visual ID 0x%lx ####\r", visinfo->visualid));
    if (verboseLevel >= 3)
      printVisual(visinfo);

    /* create context */
    if (!(_renderContext(r)= glXCreateContext(stDisplay, visinfo, 0, GL_TRUE)))
      {
	DPRINTF3D(1, (fp, "Creating GLX context failed!\r"));
	goto fail;
      }
    DPRINTF3D(3, (fp, "\r#### Created GLX context ####\r"  ));

    /* create window */
    {
      XSetWindowAttributes attributes;
      unsigned long valuemask= 0;

      attributes.colormap= XCreateColormap(stDisplay, DefaultRootWindow(stDisplay),
					   visinfo->visual, AllocNone);
      valuemask |= CWColormap;

      attributes.background_pixel= BlackPixel(stDisplay, DefaultScreen(stDisplay));
      valuemask |= CWBackPixel;

      attributes.border_pixel= 0;
      valuemask |= CWBorderPixel;

      if (!(_renderWindow(r)= (void *)XCreateWindow(stDisplay, stWindow, x, y, w, h, 0,
						    visinfo->depth, InputOutput, visinfo->visual, 
						    valuemask, &attributes)))
	{
	  DPRINTF3D(1, (fp, "Failed to create client window\r"));
	  goto fail;
	}
      XMapWindow(stDisplay, renderWindow(r));
    }
    DPRINTF3D(3, (fp, "\r#### Created window ####\r"  ));
    XFree(visinfo);
    visinfo= 0;
  }

  /* Make the context current */
  if (!glXMakeCurrent(stDisplay, renderWindow(r), renderContext(r)))
    {
      DPRINTF3D(1, (fp, "Failed to make context current\r"));
      goto fail;
    }
  DPRINTF3D(3, (fp, "\r### Renderer created! ###\r"));
  return 1;

 fail:
  DPRINTF3D(1, (fp, "OpenGL initialization failed\r"));
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
	  DPRINTF3D(1, (fp, "Failed to make context current\r"));
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
        { DPRINTF3D(3, (fp,"===> OpenGL visual\r")) }
      else
        { DPRINTF3D(3, (fp,"---> slow OpenGL visual\r")) }

      DPRINTF3D(3, (fp,"rgbaBits = %i+%i+%i+%i\r", red, green, blue, alpha));
      DPRINTF3D(3, (fp,"stencilBits = %i\r", stencil));
      DPRINTF3D(3, (fp,"depthBits = %i\r", depth));
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
      DPRINTF3D(3, (fp,"#### Checking pixel format (visual ID 0x%lx)\r", visinfo[i].visualid));
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


/*** host window support ***/

#if (SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 2)

static long display_hostWindowCreate(long w, long h, long x, long y, char *list, long attributeListLength)
											    { return 0; }
static long display_hostWindowClose(long index)                                               { return 0; }
static long display_hostWindowCloseAll(void)                                                 { return 0; }
static long display_hostWindowShowDisplay(unsigned *dispBitsIndex, long width, long height, long depth,
					 int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex)
											    { return 0; }

/* By convention for HostWindowPlugin, handle 1 refers to the display window */
#define realWindowHandle(handleFromImage) (handleFromImage == 1 ? stParent : handleFromImage)

/* Window struct addresses are not small integers */
#define isWindowHandle(winIdx) ((realWindowHandle(winIdx)) >= 65536)

static long display_ioSizeOfNativeWindow(void *windowHandle);
static long display_hostWindowGetSize(long windowIndex)
{
  return isWindowHandle(windowIndex)
    ? display_ioSizeOfNativeWindow((void *)realWindowHandle(windowIndex))
    : -1;
}

/* ioSizeOfWindowSetxy: args are int windowIndex, int w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 | height) format or -1 for failure as above. */
static long display_hostWindowSetSize(long windowIndex, long w, long h)
{
  XWindowAttributes attrs;
  int real_border_width;

  if (!isWindowHandle(windowIndex)
      || !XGetWindowAttributes(stDisplay, (Window)realWindowHandle(windowIndex), &attrs))
    return -1;

  /* At least under Gnome a window's border width in its attributes is zero
   * but the relative position of the left-hand edge is the actual border
   * width.
   */
  real_border_width= attrs.border_width ? attrs.border_width : attrs.x;
  return XResizeWindow(stDisplay, (Window)realWindowHandle(windowIndex),
   		       w - 2 * real_border_width,
		       h - attrs.y - real_border_width)
    ? display_ioSizeOfNativeWindow((void *)realWindowHandle(windowIndex))
    : -1;
}

static long display_ioPositionOfNativeWindow(void *windowHandle);
static long display_hostWindowGetPosition(long windowIndex)
{
  return isWindowHandle(windowIndex)
    ? display_ioPositionOfNativeWindow((void *)realWindowHandle(windowIndex))
    : -1;
}

/* ioPositionOfWindowSetxy: args are int windowIndex, int x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 | top) format or -1 for failure, as above */
static long display_hostWindowSetPosition(long windowIndex, long x, long y)
{
  if (!isWindowHandle(windowIndex))
    return -1;
  return XMoveWindow(stDisplay, (Window)realWindowHandle(windowIndex), x, y)
    ? display_ioPositionOfNativeWindow((void *)windowIndex)
    : -1;
}


static long display_hostWindowSetTitle(long windowIndex, char *newTitle, long sizeOfTitle)
{ 
  if (windowIndex != 1 && windowIndex != stParent && windowIndex != stWindow)
    return -1;

  XChangeProperty(stDisplay, stParent,
		  XInternAtom(stDisplay, "_NET_WM_NAME", False),
		  XInternAtom(stDisplay, "UTF8_STRING",  False),
		  8, PropModeReplace, newTitle, sizeOfTitle);

  return 0;
}

static long display_ioSizeOfNativeWindow(void *windowHandle)
{
  XWindowAttributes attrs;
  int real_border_width;

  if (!XGetWindowAttributes(stDisplay, (Window)windowHandle, &attrs))
    return -1;

  /* At least under Gnome a window's border width in its attributes is zero
   * but the relative position of the left-hand edge is the actual border
   * width.
   */
  real_border_width= attrs.border_width ? attrs.border_width : attrs.x;
  return (attrs.width + 2 * real_border_width << 16)
    | (attrs.height + attrs.y + real_border_width);
}

static long display_ioPositionOfNativeWindow(void *windowHandle)
{
  XWindowAttributes attrs;
  Window neglected_child;
  int rootx, rooty;

  if (!XGetWindowAttributes(stDisplay, (Window)windowHandle, &attrs)
      || !XTranslateCoordinates(stDisplay, (Window)windowHandle, attrs.root,
				-attrs.border_width, -attrs.border_width,
				&rootx, &rooty, &neglected_child))
    return -1;

  return (rootx - attrs.x << 16) | (rooty - attrs.y);
}

#endif /* (SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 2) */


static char *display_winSystemName(void) { return "X11"; }


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


static void display_winOpen(int argc, char *dropFiles[])
{
#if defined(DEBUG_WINDOW)
  int sws= getSavedWindowSize();
  fprintf(stderr, "saved window size is %d %d\n", sws >> 16, sws & 0xffff);
#endif
  int i, launched = 0;
  if (headless) {
    forgetXDisplay();
    return;
  }
  openXDisplay();

  for (i = 0; i < argc; i++)
    if (dndLaunchFile(dropFiles[i]))
      launched = 1;

  if (launched)
    exit(0);

}


static void display_winExit(void)
{
  disconnectXDisplay();
}


static long  display_winImageFind(char *buf, long len)	{ return 0; }
static void display_winImageNotFound(void)		{}

#if SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3

/* eem Mar 22 2010 - new code to come up to level of Qwaq host window support
 * on Mac & Win32.
 * In the following functions "Display" refers to the user area of a window and
 * "Window" refers to the entire window including border & title bar.
 */
static long
display_ioSetCursorPositionXY(long x, long y)
{
	if (!XWarpPointer(stDisplay, None, DefaultRootWindow(stDisplay),
					  0, 0, 0, 0, x, y))
		return -1;
	XFlush(stDisplay);
	return 0;
}

/* Return the pixel origin (topleft) of the platform-defined working area
   for the screen containing the given window. */
static long
display_ioPositionOfScreenWorkArea(long windowIndex)
{
/* We simply hard-code this.  There's no obvious window-manager independent way
 * to discover this that doesn't involve creating a window.
 * We're also not attempting multi-monitor support; attempting to configure a
 * laptop with a second monitor via ATI's "control center" resulted in no
 * cursor and no ATI control center once the multi-monitor mode was enabled.
 */
#define NominalMenubarHeight 24 /* e.g. Gnome default */
	return (0 << 16) | NominalMenubarHeight;
}

/* Return the pixel extent of the platform-defined working area
   for the screen containing the given window. */
static long
display_ioSizeOfScreenWorkArea(long windowIndex)
{
	XWindowAttributes attrs;

	if (!XGetWindowAttributes(stDisplay, DefaultRootWindow(stDisplay), &attrs))
		return -1;

	return (attrs.width << 16) | attrs.height;
}

void *display_ioGetWindowHandle() { return (void *)stParent; }

static long
display_ioPositionOfNativeDisplay(void *windowHandle)
{
	XWindowAttributes attrs;
	Window neglected_child;
	int rootx, rooty;

	if (!XGetWindowAttributes(stDisplay, (Window)windowHandle, &attrs)
	 || !XTranslateCoordinates(stDisplay, (Window)windowHandle, attrs.root,
								-attrs.border_width, -attrs.border_width,
								&rootx, &rooty, &neglected_child))
		return -1;

	return (rootx << 16) | rooty;
}

static long
display_ioSizeOfNativeDisplay(void *windowHandle)
{
	XWindowAttributes attrs;
	int rootx, rooty;

	if (!XGetWindowAttributes(stDisplay, (Window)windowHandle, &attrs))
		return -1;

	return (attrs.width << 16) | attrs.height;
}

#endif /* SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3 */


SqDisplayDefine(X11);


/*** module ***/


static void display_printUsage(void)
{
  printf("\nX11 <option>s:\n");
  printf("  "VMOPTION("browserWindow")" <wid>  run in window <wid>\n");
  printf("  "VMOPTION("browserPipes")" <r> <w> run as Browser plugin using descriptors <r> <w>\n");
  printf("  "VMOPTION("cmdmod")" <n>           map Mod<n> to the Command key\n");
  printf("  "VMOPTION("compositioninput")"     enable overlay window for composed characters\n");
  printf("  "VMOPTION("display")" <dpy>        display on <dpy> (default: $DISPLAY)\n");
  printf("  "VMOPTION("fullscreen")"           occupy the entire screen\n");
  printf("  "VMOPTION("fullscreenDirect")"     simple window manager support for fullscreen\n");
#if (USE_X11_GLX)
  printf("  "VMOPTION("glxdebug")" <n>         set GLX debug verbosity level to <n>\n");
#endif
  printf("  "VMOPTION("headless")"             run in headless (no window) mode\n");
  printf("  "VMOPTION("iconic")"               start up iconified\n");
  printf("  "VMOPTION("lazy")"                 go to sleep when main window unmapped\n");
  printf("  "VMOPTION("mapdelbs")"             map Delete key onto Backspace\n");
  printf("  "VMOPTION("nointl")"               disable international keyboard support\n");
  printf("  "VMOPTION("notitle")"              disable the " xResName " window title bar\n");
  printf("  "VMOPTION("title")" <t>            use t as the " xResName " window title instead of the image name\n");
  printf("  "VMOPTION("ldtoms")" <n>           launch drop timeout milliseconds\n");
  printf("  "VMOPTION("noxdnd")"               disable X drag-and-drop protocol support\n");
  printf("  "VMOPTION("optmod")" <n>           map Mod<n> to the Option key\n");
#if defined(SUGAR)
  printf("  "VMOPTION("sugarBundleId")" <id>   set window property _SUGAR_BUNDLE_ID to <id>\n");
  printf("  "VMOPTION("sugarActivityId")" <id> set window property _SUGAR_ACTIVITY_ID to <id>\n");
#endif
  printf("  "VMOPTION("swapbtn")"              swap yellow (middle) and blue (right) buttons\n");
  printf("  "VMOPTION("xasync")"               don't serialize display updates\n");
#if defined(USE_XICFONT_OPTION)
  printf("  "VMOPTION("xicfont")" <f>          use font set <f> for the input context overlay\n");
#endif
  printf("  "VMOPTION("xshm")"                 use X shared memory extension\n");
}

static void display_printUsageNotes(void)
{
  printf("  Using `unix:0' for <dpy> may improve local display performance.\n");
  printf("  "VMOPTION("xshm")" only works when " xResName " is running on the X server host.\n");
}


static void display_parseEnvironment(void)
{
  char *ev= 0;

  if (getenv("LC_CTYPE") || getenv("LC_ALL"))
    x2sqKey= x2sqKeyInput;

  if (localeEncoding) 
    {
      if (getenv("SQUEAK_COMPOSITIONINPUT"))
	{
	  compositionInput= 1;
	  initInput= initInputI18n;
	  x2sqKey= x2sqKeyCompositionInput;
	}
    }

  if (getenv("SQUEAK_LAZY"))		sleepWhenUnmapped= 1;
  if (getenv("SQUEAK_SPY"))		withSpy= 1;
#if !defined (INIT_INPUT_WHEN_KEY_PRESSED)
  if (getenv("SQUEAK_NOINTL"))		initInput= initInputNone;
#else
  if (getenv("SQUEAK_NOINTL"))		x2sqKey= x2sqKeyPlain;
#endif
  if (getenv("SQUEAK_NOTITLE"))		noTitle= 1;
  if (getenv("SQUEAK_NOXDND"))		useXdnd= 0;
  if (getenv("SQUEAK_FULLSCREEN"))	fullScreen= 1;
  if (getenv("SQUEAK_FULLSCREEN_DIRECT"))	fullScreenDirect= 1;
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

  if      (!strcmp(arg, VMOPTION("headless")))	headless= 1;
#if defined(USE_XSHM)
  else if (!strcmp(arg, VMOPTION("xshm")))	useXshm= 1;
  else if (!strcmp(arg, VMOPTION("xasync")))	asyncUpdate= 1;
#else
  else if (!strcmp(arg, VMOPTION("xshm"))) ||
           !strcmp(arg, VMOPTION("xasync")))	fprintf(stderr, "ignoring %s (not supported by this VM)\n", arg);
#endif
  else if (!strcmp(arg, VMOPTION("lazy")))	sleepWhenUnmapped= 1;
  else if (!strcmp(arg, VMOPTION("notitle")))	noTitle= 1;
  else if (!strcmp(arg, VMOPTION("mapdelbs")))	mapDelBs= 1;
  else if (!strcmp(arg, VMOPTION("swapbtn")))	swapBtn= 1;
  else if (!strcmp(arg, VMOPTION("fullscreen")))	fullScreen= 1;
  else if (!strcmp(arg, VMOPTION("fullscreenDirect")))	fullScreenDirect= 1;
  else if (!strcmp(arg, VMOPTION("iconic")))	iconified= 1;
#if !defined (INIT_INPUT_WHEN_KEY_PRESSED)
  else if (!strcmp(arg, VMOPTION("nointl")))	initInput= initInputNone;
#else
  else if (!strcmp(arg, VMOPTION("nointl")))	x2sqKey= x2sqKeyPlain;
#endif
  else if (!strcmp(arg, VMOPTION("compositioninput")))
    {
      compositionInput= 1;
      x2sqKey= x2sqKeyCompositionInput;
      initInput= initInputI18n;
    }
  else if (!strcmp(arg, VMOPTION("noxdnd")))	useXdnd= 0;
  else if (argv[1])	/* option requires an argument */
    {
      n= 2;
      if      (!strcmp(arg, VMOPTION("display"))) displayName= argv[1];
      else if (!strcmp(arg, VMOPTION("optmod")))	 optMapIndex= Mod1MapIndex + atoi(argv[1]) - 1;
      else if (!strcmp(arg, VMOPTION("cmdmod")))  cmdMapIndex= Mod1MapIndex + atoi(argv[1]) - 1;
#    if defined(SUGAR)
      else if (!strcmp(arg, VMOPTION("sugarBundleId")))   sugarBundleId= argv[1];
      else if (!strcmp(arg, VMOPTION("sugarActivityId"))) sugarActivityId= argv[1];
#    endif
#    if defined(USE_XICFONT_OPTION)
      else if (!strcmp(arg, VMOPTION("xicfont"))) inputFontStr= argv[1];
#    endif
      else if (!strcmp(arg, VMOPTION("browserWindow")))
	{
	  sscanf(argv[1], "%lu", (unsigned long *)&browserWindow);
	  if (browserWindow == 0)
	    {
	      fprintf(stderr, "Error: invalid argument for `-browserWindow'\n");
	      exit(1);
	    }
	}
      else if (!strcmp(arg, VMOPTION("browserPipes")))
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
      else if (!strcmp(arg, VMOPTION("glxdebug")))
	{
	  sscanf(argv[1], "%d", &verboseLevel);
	}
#    endif
      else if (!strcmp(arg, VMOPTION("title"))) defaultWindowLabel = argv[1];
      else if (!strcmp(arg, VMOPTION("ldtoms"))) launchDropTimeoutMsecs = atol(argv[1]);
      else
	n= 0;	/* not recognised */
    }
  else
    n= 0;
  return n;
}

static void *display_makeInterface(void) { return &display_X11_itf; }

#include "SqModule.h"

SqModuleDefine(display, X11);
