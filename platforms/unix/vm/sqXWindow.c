/* sqXWindow.c -- support for Unix and the X Window System.
 * 
 *   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
 *      authors/contributors listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice may not be removed or altered in any source distribution.
 * 
 *   Using or modifying this file for use in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the base
 *   of the distribution before proceeding with any such use.
 * 
 *   You are STRONGLY DISCOURAGED from distributing a modified version of
 *   this file under its original name without permission.  If you must
 *   change it, rename it first.
 */

/* Author: Ian Piumarta <ian.piumarta@inria.fr>
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
 * Support for displays shallower than 8 bits contributed by:
 *	Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>
 *
 * Support for 24bpp TrueColour X display devices contributed by:
 *	Tim Rowledge <tim@sumeru.stanford.edu>
 *
 * Support for OSProcess plugin contributed by:
 *	Dave Lewis <lewis@mail.msen.com> Mon Oct 18 20:36:54 EDT 1999
 *
 * Support for browser plugins contributed by:
 *	Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>
 *
 * BUGS: this file is too long; it should be split into two (Unix vs. X11).
 *	 icon stuff should be removed (window manager's responsibility).
 *	 RCS stuff has been removed.
 */

#include "sq.h"
#include "sqaio.h"

# if 0
/* Nope, no need for these at all. TPR */
#include "FilePlugin.h"			/* sqFileInit() */
#include "JoystickTabletPlugin.h"	/* joystickInit() */
# endif

#define NO_ICON
#undef	FULL_UPDATE_ON_EXPOSE

/* if defined then the main Squeak window is a subwindow in an
   invisible enclosing InputOutput window.  helps integrate the
   Mozilla plugin stuff and fullscreen mode. */

#ifdef HAVE_LIBXEXT
# define USE_XSHM
#endif

/* OS_TYPE may be set in configure.in and passed via the Makefile */

#ifndef OS_TYPE
# ifdef UNIX
#   define OS_TYPE "unix"
# else
#  define OS_TYPE "unknown"
# endif
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

#ifdef HAVE_SYS_SELECT_H
# include <sys/select.h>
#endif

#ifndef HEADLESS
# include <X11/Xlib.h>
# include <X11/Xutil.h>
# include <X11/Xatom.h>
# define XK_MISCELLANY
# define XK_XKB_KEYS
# include <X11/keysymdef.h>
# ifdef USE_XSHM
#   include <sys/ipc.h>
#   include <sys/shm.h>
#   include <X11/extensions/XShm.h>
# endif
# ifndef NO_ICON
#   include "squeakIcon.bitmap"
# endif
#endif

#if defined(HAVE_LIBDL)
# undef USE_INTERNAL_IMAGE
# include <dlfcn.h>
# if !defined(NDEBUG)
#   define NDEBUG
# endif
# include <assert.h>
# include "zipio.h"
#endif

/*** Variables -- Imported from Virtual Machine ***/
extern unsigned char *memory;
extern int interruptKeycode;
extern int interruptPending;
extern int interruptCheckCounter;
extern int savedWindowSize;

/*** Variables -- image and path names ***/
#define IMAGE_NAME_SIZE MAXPATHLEN

static char shortImageName[MAXPATHLEN+1];	/* image name */
char        imageName[MAXPATHLEN+1];		/* full path to image */
static char vmPath[MAXPATHLEN+1];		/* full path to image directory */
static char vmName[MAXPATHLEN+1];		/* full path to vm */

#define DefaultHeapSize		50	/* megabytes */

int initialHeapSize= DefaultHeapSize * 1024 * 1024;

/*** Variables -- globals for access from pluggable primitives ***/
int    argCnt= 0;
char **argVec= 0;
char **envVec= 0;

/* Pointers to arguments for VM.  Used by getAttributeIntoLength(). */
int    vmArgCnt= 0;
char **vmArgVec= 0;

/* Pointers to arguments for Squeak.  Used by getAttributeIntoLength(). */
int    squeakArgCnt= 0;
char **squeakArgVec= 0;

#if defined(USE_INTERNAL_IMAGE)
unsigned char *internalImage=    0;	/* non-zero means use internal image */
unsigned char *internalImagePtr= 0;	/* non-zero means plain image */
z_stream      *internalZStream=  0;	/* non-zero means gzipped image */
#endif

#undef USE_ITIMER			/* severely confuses GNU's profil() */

#ifdef USE_ITIMER
unsigned int	lowResMSecs= 0;
#define	LOW_RES_TICK_MSECS	20	/* 1/50 second resolution */
#endif

#ifndef HEADLESS
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
int              stWindowWidth=-1;      /* last-known dimensions of that window */
int              stWindowHeight=-1;
Visual		*stVisual;		/* the default visual */
GC		 stGC;			/* graphics context used for rendering */
Colormap	 stColormap= null;	/* Squeak color map */
int		 scrW= 0;               /* the size of the whole screen */
int		 scrH= 0;
int		 stDisplayBitsIndex= 0;	/* last known oop of the VM's Display */
XImage		*stImage= 0;		/* the X pixmap to be drawn;
					   it either refers to the Display object,
					   or it refers to a pixmap in shared memory */

char		*stPrimarySelection;	/* buffer holding selection */
char		*stEmptySelection= "";	/* immutable "empty string" value */
int		 stPrimarySelectionSize;/* size of buffer holding selection */
int		 stOwnsSelection= 0;	/* true if we own the X PRIMARY selection */
int		 stOwnsClipboard= 0;	/* true if we own the X CLIPBOARD selection */
XColor		 stColorBlack;		/* black pixel value in stColormap */
XColor		 stColorWhite;		/* white pixel value in stColormap */
int		 savedWindowOrigin= -1;	/* initial origin of window */
XPoint		 mousePosition;		/* position at last PointerMotion event */
Time		 stButtonTime;		/* time of last ButtonRelease (for SetSeln) */
# ifdef USE_XSHM
XShmSegmentInfo  stShmInfo;		/* shared memory descriptor */
int		 completions= 0;	/* outstanding completion events */
int		 completionType;	/* the type of XShmCompletionEvent */
int		 useXshm= 0;		/* 1 if shared memory is in use */
int		 asyncUpdate= 0;	/* 1 for asynchronous screen updates */
#else
#define useXshm 0                       /* this is handy sometimes */
# endif
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
int              browserPipes[]= {-1, -1};   /* read/write fd for communication with browser */ 
int		 headless= 0;
Atom		 clipboardAtom= 0;
Atom		 primaryAtom= 0;

#define          inBrowser\
  (-1 != browserPipes[0])

#else
/* some vars need setting for headless */
int		 noEvents= 1;		/* 1 to disable new event handling */
/* XXX is there a reason to turn off event-based input?  what's it matter?
   feel free to replace this query with an explanation :)  -lex */

#endif  /* !HEADLESS */

/* events */

int inputEventSemaIndex= 0;
#define IEB_SIZE	 64

sqInputEvent inputEventBuffer[IEB_SIZE];
int iebIn=  0;	/* next IEB location to write */
int iebOut= 0;	/* next IEB location to read  */

#define SqueakWhite	0
#define SqueakBlack	1

int		 asmAlign= 1;
int		 sleepWhenUnmapped= 0;
int		 noJitter= 1;
int		 withSpy= 0;
int		 noTitle= 0;
int		 fullScreen= 0;
struct timeval	 startUpTime;
int		 noEvents= 0;		/* 1 to disable new event handling */


#ifndef HEADLESS

static Time lastKeystrokeTime;  /* XXX is initializing this to 0 okay?? */
                                /* XXX er, uh, als, isn't this supposed to get set somewhere? */

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


/*** Variables -- Event Recording ***/
#define KEYBUF_SIZE 64

int keyBuf[KEYBUF_SIZE];	/* circular buffer */
int keyBufGet= 0;		/* index of next item of keyBuf to read */
int keyBufPut= 0;		/* index of next item of keyBuf to write */
int keyBufOverflows= 0;		/* number of characters dropped */


unsigned stButtons= 0;          /* mouse buttons currently pressed
				   down; the mask bits are described
				   in sq.h as RedButtonBit, etc.  */
unsigned modifiers;             /* the modifiers curretnly pressed down;
				   the mask bits are described in sq.h
				   as CtrlKeyBit, etc. */
unsigned buttonState= 0;        /* the combination of the stButtons
				   and modifiers in the format Squeak
				   expects:

				   buttonState == (stButtons | (modifiers << 3)
				*/


#endif   /* !HEADLESS */



/*** Functions ***/

#ifdef ioMSecs
# undef ioMSecs
#endif

#ifndef HEADLESS
static void xDescriptorHandler(void *data, int readFlag, int writeFlag, int exceptionFlag);
static void npDescriptorHandler(void *data, int readFlag, int writeFlag, int exceptionFlag);
#endif
static int  HandleEvents(void);
void RecordFullPathForVmName(char *localVmName);
void RecordFullPathForImageName(char *localImageName);
void SetUpTimers(void);
void usage(void);
void imageNotFound(char *imageName);
void ParseArguments(int argc, char **argv, int);
void segv(int ignored);
void keyBufAppend(int keystate);

#ifndef HEADLESS
void SetColorEntry(int index, int red, int green, int blue);
void SetUpClipboard(void);
void SetUpPixmap(void);
void SetUpWindow(char *displayName);
void SetWindowSize(void);
void getMaskbit(unsigned long ul, int *nmask, int *shift);
void setupDownGradingColors(void);
void copyReverseImageBytes(int *fromImageData, int *toImageData,
			   int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB);
void copyReverseImageWords(int *fromImageData, int *toImageData,
			   int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB);

# define declareCopyFunction(NAME) \
  void NAME (int *fromImageData, int *toImageData, \
	     int width, int height, \
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

# undef declareCopyFunction

void SetUpCharmap();
void ux2st(unsigned char *string);
void st2ux(unsigned char *string);
void claimSelection(void);
void sendSelection(XSelectionRequestEvent *requestEv);
char *getSelection(void);
static void redrawDisplay(int l, int r, int t, int b);
static int translateCode(KeySym symbolic);
static void recordMouseEvent(XButtonEvent *theEvent);
static void recordKeystrokeEvent(XKeyEvent *theEvent);
static void recordModifierButtons(XButtonEvent *theEvent,
				  int buttonToAdd,
				  int buttonToRemove);
# ifdef USE_XSHM
int XShmGetEventBase(Display *);
# endif
int ioMSecs(void);
void browserProcessCommand(void);       /* see sqUnixMozilla.c */
#endif /*!HEADLESS*/

int strtobkm(const char *str);


time_t convertToSqueakTime(time_t);	/* unix epoch -> Squeak epoch */


/*** VM Home Directory Path ***/

int vmPathSize(void)
{
  return strlen(vmPath);
}

int vmPathGetLength(int sqVMPathIndex, int length)
{
  char *stVMPath= (char *)sqVMPathIndex;
  int count, i;

  count= strlen(vmPath);
  count= (length < count) ? length : count;

  /* copy the file name into the Squeak string */
  for (i= 0; i < count; i++)
    stVMPath[i]= vmPath[i];

  return count;
}

#ifndef HEADLESS

/* Conversion table from X to Squeak (reversible) */

unsigned char X_to_Squeak[256] =
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

void SetUpCharmap()
{
  int i;
  for(i=0; i<256; i++)
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

/*** X-related Functions ***/

/* Called prior to forking a squeak session.
 */
int synchronizeXDisplay()
{
  if (isConnectedToXServer)
    XSync(stDisplay, False);
  return 0;
}

int openXDisplay()
{
  /* open the Squeak window. */
  if (!isConnectedToXServer) {
    SetUpCharmap();
    SetUpClipboard();
    SetUpWindow(displayName);
    SetUpPixmap();
    if (!inBrowser)
      {
	SetWindowSize();
	XMapWindow(stDisplay, stParent);
	XMapWindow(stDisplay, stWindow);
      }
    else /* if in browser we will be reparented and mapped by plugin */
      {
	/* tell browser our window */
	write(browserPipes[1], &stWindow, 4);
	/* listen for commands */
	aioHandle(browserPipes[0], npDescriptorHandler, NULL, AIO_RD);
      }
    aioHandle(stXfd, xDescriptorHandler, NULL, AIO_RD | AIO_EX);
    isConnectedToXServer= 1;
  }
  return 0;
}

int forgetXDisplay()
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
  if (isConnectedToXServer) {
    aioStopHandling(stXfd);
    close(stXfd);
  }
  stXfd= -1;             /* X connection file descriptor         */
  stParent= null;
  stWindow= null;       /* Squeak window                        */
  isConnectedToXServer= 0;
  return 0;
}

int disconnectXDisplay()
{
  if (isConnectedToXServer) {
    XSync(stDisplay, False);
    HandleEvents(); /* process all pending window events */
     XDestroyWindow(stDisplay, stWindow);
     if (browserWindow == 0)
       XDestroyWindow(stDisplay, stParent);
     XCloseDisplay(stDisplay);
   }
   forgetXDisplay();
   return 0;
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

static void handleOneEvent(XEvent *theEvent) 
{
    switch (theEvent->type)
      {
      case MotionNotify:
	recordMouseEvent((XButtonEvent *) theEvent);
	break;

      case ButtonPress:
	recordMouseEvent((XButtonEvent *) theEvent);
	break;

      case ButtonRelease:
	recordMouseEvent((XButtonEvent *) theEvent);

	/* button up on "paste" causes a selection retrieval:
	   record the event time in case we need it later */
	stButtonTime= ((XButtonEvent *) theEvent)->time;
	break;

      case KeyPress:
	recordKeystrokeEvent((XKeyEvent *) theEvent);
	break;

      case KeyRelease:
	recordKeystrokeEvent((XKeyEvent *) theEvent);
	break;

      case SelectionClear:
	if (((XSelectionClearEvent *)theEvent)->selection == clipboardAtom)
	  stOwnsClipboard= 0;
	else if (((XSelectionClearEvent *)theEvent)->selection == primaryAtom)
	  stOwnsSelection= 0;
	break;

      case SelectionRequest:
	sendSelection(&theEvent->xselectionrequest);
	break;

      case Expose:
	{
	  XExposeEvent *ex= (XExposeEvent *)theEvent;
#      if defined(USE_XSHM)
	  if (asyncUpdate)
	    {
	      /* wait for pending updates */
	      /* XXX Lex Spoon has observed an infinite recursion here; it should be investigated further.... */
	      while (completions) HandleEvents();
	    }
#      endif
#      ifdef FULL_UPDATE_ON_EXPOSE
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
	break;

      case UnmapNotify:
	{
	  XEvent theEvent;
	  
	  if (sleepWhenUnmapped)
	    do
	      {
		
		XNextEvent(stDisplay, &theEvent);
		switch (theEvent.type)
		  {
		  case SelectionClear:
		    if (((XSelectionClearEvent*)&theEvent)->selection == clipboardAtom)
		      stOwnsClipboard= 0;
		    else if (((XSelectionClearEvent*)&theEvent)->selection == primaryAtom)
		      stOwnsSelection= 0;
		    break;
		  case SelectionRequest:
		    sendSelection(&theEvent.xselectionrequest);
		    break;
		  }
	      } while (theEvent.type != MapNotify);
	  getMousePosition();
	}
	break;

      case ConfigureNotify:
	{
	  XConfigureEvent *ec= (XConfigureEvent *) theEvent;
	  int width= ec->width;
	  int height= ec->height;
	  
	  
	  /* width must be a multiple of sizeof(void *), or X[Shm]PutImage goes gaga */
	  if ((width % sizeof(void *)) != 0)
	    {
	      width= (width / sizeof(void *)) * sizeof(void *);
	      if(! inBrowser) {
		/* it would be rude to resize the window the browser gave us! */
		XResizeWindow(stDisplay, stParent, width, height);
	      }
	    }
	  

#      if defined(USE_XSHM)
	  if (asyncUpdate)
	    {
	      /* wait for pending updates */
	      while (completions) HandleEvents();
	    }
#      endif

	  /* resize the display window to match the parent, unless
	     we are in full screen mode */
	  if (! fullScreen)
	    {
	      XResizeWindow(stDisplay, stWindow, ec->width, ec->height);
	      stWindowWidth= ec->width;
	      stWindowHeight= ec->height;
	    }
	}
	
	break;

      case MappingNotify:
	XRefreshKeyboardMapping((XMappingEvent *) theEvent);
	break;
	  
#  ifdef USE_XSHM
      default:
	if (theEvent->type == completionType) --completions;
	break;
#  endif
      }
}


void claimSelection(void)
{
  XSetSelectionOwner(stDisplay, clipboardAtom, stWindow, lastKeystrokeTime);
  XSetSelectionOwner(stDisplay, primaryAtom, stWindow, lastKeystrokeTime);
  XFlush(stDisplay);
  stOwnsClipboard= (XGetSelectionOwner(stDisplay, clipboardAtom) == stWindow);
  stOwnsSelection= (XGetSelectionOwner(stDisplay, primaryAtom) == stWindow);
}

void sendSelection(XSelectionRequestEvent *requestEv)
{
  XSelectionEvent notifyEv;

  /* REFUSE the selection if the target type isn't XA_STRING */
  if (requestEv->target == XA_STRING)
    {
      st2ux(stPrimarySelection);
 
      XChangeProperty(requestEv->display,
		      requestEv->requestor,
		      (requestEv->property == None
		       ? requestEv->target
		       : requestEv->property),
		      requestEv->target,
		      8, PropModeReplace, stPrimarySelection,
		      (stPrimarySelection ? strlen(stPrimarySelection) : 0));

      ux2st(stPrimarySelection);
      notifyEv.property= (requestEv->property == None)
	? requestEv->target
	: requestEv->property;
    }
  else
    {
      notifyEv.property= None;
    }

  notifyEv.type= SelectionNotify;
  notifyEv.display= requestEv->display;
  notifyEv.requestor= requestEv->requestor;
  notifyEv.selection= requestEv->selection;
  notifyEv.target= requestEv->target;
  notifyEv.time= requestEv->time;

  XSendEvent(requestEv->display, requestEv->requestor,
	     False, 0, (XEvent *)&notifyEv);

  XFlush(stDisplay);
}


char *getSelection(void)
{
  XEvent  ev;
  fd_set  fdMask;
  char	 *data;

  /* request the PRIMARY selection, since this should be the same as the CLIPBOARD */
  XConvertSelection(stDisplay, primaryAtom, XA_STRING, XA_STRING, stWindow, CurrentTime);

  /* wait for selection notification, ignoring (most) other events. */
  FD_ZERO(&fdMask);
  if(stXfd >= 0)
    FD_SET(stXfd, &fdMask);

  /* loop until a selection notify event is received */
  do
    {
      /* wait until some event has arrived */
      while(! XPending(stDisplay))
	{
	  /* empty event queue; wait for a while */
	  struct timeval timeout= {SELECTION_TIMEOUT, 0};
	  int status;

	  while ((status= select(FD_SETSIZE, &fdMask, 0, 0, &timeout)) < 0
		 && errno == EINTR);
	  if (status < 0)
	    {
	      /* uh oh */
	      perror("select(stDisplay)");
	      return stEmptySelection;
	    }
	  if (status == 0)
	    {
	      /* timeout; give up */
	      if (isConnectedToXServer)
		XBell(stDisplay, 0);
	      return stEmptySelection;
	    }
	}

      /* retrieve it */
      XNextEvent(stDisplay, &ev);

      if(ev.type != SelectionNotify)
	{
	  /* wrong kind of event */
	  handleOneEvent(&ev);
	}
    }
  while (ev.type != SelectionNotify);

  /* check if the selection was refused */
  if (ev.xselection.property == None)
    {
      if (isConnectedToXServer)
	XBell(stDisplay, 0);
      return stEmptySelection;
    }

  /* get the value of the selection from the containing property */
  {
    Atom type;
    int format;
    unsigned long nitems, bytesAfter;

    XGetWindowProperty(stDisplay, ev.xselection.requestor, ev.xselection.property,
		       (long)0, (long)(MAX_SELECTION_SIZE/4),
		       False, AnyPropertyType,
		       &type, &format, &nitems, &bytesAfter,
		       (unsigned char **)&data);
    if (bytesAfter > 0)
      XBell(stDisplay, 0);
  }

  /* return the selection -- which must be XFreed() when no longer needed! */

  return data;
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
  extern int lengthOf(int);
  extern int displayObject(void);
# define longAt(i) (*((int *) (i)))
  int displayObj= displayObject();
  if ((((((unsigned)(longAt(displayObj))) >> 8) & 15) <= 4) &&
      ((lengthOf(displayObj)) >= 4))
    {
      int dispBits= longAt((displayObj + 4) + (0 * 4));
      int w= fetchIntegerofObject(1, displayObj);
      int h= fetchIntegerofObject(2, displayObj);
      int d= fetchIntegerofObject(3, displayObj);
      int dispBitsIndex= dispBits + 4;
      ioShowDisplay(dispBitsIndex, w, h, d, l, r, t, b);
    }
# undef longAt
}



#endif /*!HEADLESS*/


/*** event handling ***/


/* set asynchronous input event semaphore
 */
int ioSetInputSemaphore(int semaIndex)
{
  if ((semaIndex == 0) || (noEvents == 1))
    {
      success(false);
    }
  else
    {
      inputEventSemaIndex= semaIndex;
    }
  return true;
}


#define iebEmptyP()	(iebIn == iebOut)
#define iebAdvance(P)	(P= ((P + 1) % IEB_SIZE))


/* retrieve the next input event from the OS
 */
int ioGetNextEvent(sqInputEvent *evt)
{
  if (iebEmptyP()) ioProcessEvents();
  if (iebEmptyP()) return false;
  *evt= inputEventBuffer[iebOut];
  iebAdvance(iebOut);
  return true;
}


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

#ifndef HEADLESS

static void signalInputEvent() 
{
  if(inputEventSemaIndex > 0)
    signalSemaphoreWithIndex(inputEventSemaIndex);
}





/* record a mouse event.  This handles button presses, button releases, and motion notify.
   Note that the fields in motion notify that this structure uses line up exactly
   with the same-named fields in XButtonEvent */
static void recordMouseEvent(XButtonEvent *theEvent) 
{
  int buttonToAdd= 0;
  int buttonToRemove= 0;
  
  if(theEvent->type == ButtonPress)
    buttonToAdd= theEvent->button;
  if(theEvent->type == ButtonRelease)
    buttonToRemove= theEvent->button;
  
  
  recordModifierButtons(theEvent, buttonToAdd, buttonToRemove);
  
  mousePosition.x= theEvent->x;
  mousePosition.y= theEvent->y;

  if(theEvent->type == ButtonPress) {
    if(theEvent->button==4 || theEvent->button==5) {
      /* Mouse wheel support */
      keyBufAppend((theEvent->button + 26)        /* Up/Down */
		   | (2 << 8)                          /* Ctrl  */
		   | (modifiers << 8));


      if(inputEventSemaIndex != 0) {
      	sqKeyboardEvent *evt= allocateKeyboardEvent();
	evt->charCode= (theEvent->button + 26);       /* Up/Down */
	evt->pressCode= EventKeyChar;
	evt->modifiers= CtrlKeyBit | modifiers;
	evt->reserved1=
	  evt->reserved2=
	  evt->reserved3= 0;
      }

      return;
    }

    if(theEvent->button > 5) {
      ioBeep();
    }
  }
  

  if(inputEventSemaIndex != 0) {
    sqMouseEvent *evt= allocateMouseEvent();
    evt->x= mousePosition.x;
    evt->y= mousePosition.y;
    evt->buttons= stButtons;
    evt->modifiers= modifiers;
    evt->reserved1= 0;
    evt->reserved2= 0;
    
    signalInputEvent();
  }
}


/* record a keystroke event, whether it is a release or a press */
static void recordKeystrokeEvent(XKeyEvent *theEvent) 
{
  int charCode= 0;       /* the character code for the key, in Squeak's encoding */
  int keystate= 0;       /* the combined character code and modifiers */
  unsigned char buf[32];
  int nConv= 0;
  KeySym symbolic;

  recordModifierButtons((XButtonEvent *) theEvent, 0, 0);


  /* translate the key from X11 to Squeak */
  nConv= XLookupString(theEvent, buf, sizeof(buf), &symbolic, 0);

  /* check for special keys */
  charCode= translateCode(symbolic);
  if(charCode < 0) {
    /* not a special key */
    if(nConv==0) {
      /* key not known at all.  Give up */
      return;
    }

    /* just use the first character of the string; conceivably all
       the characters could be sent in */
    charCode= buf[0];
  }

  /* Squeak uses the Macintosh 8-bit character encoding */
  if (charCode >= 128)
    charCode= X_to_Squeak[charCode];

  
  keystate= charCode | (modifiers << 8);

  if (keystate == interruptKeycode)
    {
      /* Treat the interrupt key specially; don't just pass it into the image */
      if(theEvent->type==KeyPress) {
	interruptPending= true;
	interruptCheckCounter= 0;
      }
      
      return;
    }

  keyBufAppend(keystate);


  if(inputEventSemaIndex != 0)     {
    int codes[2];
    int numCodes;
    int i;

    if(theEvent->type==KeyPress) {
      codes[0] = EventKeyDown;
      codes[1] = EventKeyChar;
      numCodes=2;
    }
    else {
      codes[0] = EventKeyUp;
      numCodes=1;
    }

    for(i=0; i<numCodes; i++) {
      sqKeyboardEvent *evt= allocateKeyboardEvent();
    
      evt->charCode= charCode;
      evt->pressCode= codes[i];
      evt->modifiers= modifiers;
      evt->reserved1=
	evt->reserved2=
	evt->reserved3= 0;
    }
  }
  signalInputEvent();
}


#endif /* !HEADLESS */

int HandleEvents(void)
{
#ifdef HEADLESS
  return 0;
#else /*!HEADLESS*/
  XEvent theEvent;

  
  if (!isConnectedToXServer)
    return 0;
  

  while(XPending(stDisplay)) {
    XNextEvent(stDisplay, &theEvent);

    handleOneEvent(&theEvent);
    
      
  }
  
  return 0;
#endif /* !HEADLESS */
}



#ifndef HEADLESS

/* called via the aio module */
static void xDescriptorHandler(void *data, int readFlag, int writeFlag, int exceptionFlag)
{
  HandleEvents();
}

static void npDescriptorHandler(void *data, int readFlag, int writeFlag, int exceptionFlag)
{
  browserProcessCommand();
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

void setupDownGradingColors(void)
{
  int r, g, b, i;

  for (r= 0; r < 0x8; r++)
    {
      for (g= 0; g < 0x8; g++)
	{
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
    }
}

void SetColorEntry(int index, int red, int green, int blue)
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

void SetUpPixmap(void)
{
  int count;
  XPixmapFormatValues *xpv;

  xpv= XListPixmapFormats(stDisplay, &count);

  if (xpv)
    {
      while(--count >= 0)
	{
	  if (stDepth == xpv[count].depth)
	    stBitsPerPixel= xpv[count].bits_per_pixel;
	}
      XFree((void*)xpv);
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
	} else if (stBitsPerPixel == 24)
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
  SetColorEntry(0, 65535, 65535, 65535);	/* white or transparent */
  SetColorEntry(1,     0,     0,     0);	/* black */

	/* additional colors for 2-bit color */
  SetColorEntry(2, 65535, 65535, 65535);	/* opaque white */
  SetColorEntry(3, 32768, 32768, 32768);	/* 1/2 gray */

	/* additional colors for 4-bit color */
  SetColorEntry( 4, 65535,     0,     0);	/* red */
  SetColorEntry( 5,     0, 65535,     0);	/* green */
  SetColorEntry( 6,     0,     0, 65535);	/* blue */
  SetColorEntry( 7,     0, 65535, 65535);	/* cyan */
  SetColorEntry( 8, 65535, 65535,     0);	/* yellow */
  SetColorEntry( 9, 65535,     0, 65535);	/* magenta */
  SetColorEntry(10,  8192,  8192,  8192);	/* 1/8 gray */
  SetColorEntry(11, 16384, 16384, 16384);	/* 2/8 gray */
  SetColorEntry(12, 24576, 24576, 24576);	/* 3/8 gray */
  SetColorEntry(13, 40959, 40959, 40959);	/* 5/8 gray */
  SetColorEntry(14, 49151, 49151, 49151);	/* 6/8 gray */
  SetColorEntry(15, 57343, 57343, 57343);	/* 7/8 gray */

	/* additional colors for 8-bit color */
	/* 24 more shades of gray (does not repeat 1/8th increments) */
  SetColorEntry(16,  2048,  2048,  2048);	/*  1/32 gray */
  SetColorEntry(17,  4096,  4096,  4096);	/*  2/32 gray */
  SetColorEntry(18,  6144,  6144,  6144);	/*  3/32 gray */
  SetColorEntry(19, 10240, 10240, 10240);	/*  5/32 gray */
  SetColorEntry(20, 12288, 12288, 12288);	/*  6/32 gray */
  SetColorEntry(21, 14336, 14336, 14336);	/*  7/32 gray */
  SetColorEntry(22, 18432, 18432, 18432);	/*  9/32 gray */
  SetColorEntry(23, 20480, 20480, 20480);	/* 10/32 gray */
  SetColorEntry(24, 22528, 22528, 22528);	/* 11/32 gray */
  SetColorEntry(25, 26624, 26624, 26624);	/* 13/32 gray */
  SetColorEntry(26, 28672, 28672, 28672);	/* 14/32 gray */
  SetColorEntry(27, 30720, 30720, 30720);	/* 15/32 gray */
  SetColorEntry(28, 34815, 34815, 34815);	/* 17/32 gray */
  SetColorEntry(29, 36863, 36863, 36863);	/* 18/32 gray */
  SetColorEntry(30, 38911, 38911, 38911);	/* 19/32 gray */
  SetColorEntry(31, 43007, 43007, 43007);	/* 21/32 gray */
  SetColorEntry(32, 45055, 45055, 45055);	/* 22/32 gray */
  SetColorEntry(33, 47103, 47103, 47103);	/* 23/32 gray */
  SetColorEntry(34, 51199, 51199, 51199);	/* 25/32 gray */
  SetColorEntry(35, 53247, 53247, 53247);	/* 26/32 gray */
  SetColorEntry(36, 55295, 55295, 55295);	/* 27/32 gray */
  SetColorEntry(37, 59391, 59391, 59391);	/* 29/32 gray */
  SetColorEntry(38, 61439, 61439, 61439);	/* 30/32 gray */
  SetColorEntry(39, 63487, 63487, 63487);	/* 31/32 gray */

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
	    SetColorEntry(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
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
      setupDownGradingColors();
    }
  else
    {
      stColorWhite.pixel= WhitePixel(stDisplay, DefaultScreen(stDisplay));
      stColorBlack.pixel= BlackPixel(stDisplay, DefaultScreen(stDisplay));
    }
}


void SetUpWindow(char *displayName)
{
  XRectangle windowBounds= { 0, 0, 640, 480 };  /* default window bounds */

  int right, bottom;

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

  if (savedWindowSize != 0)
    {
      right=  windowBounds.x + ((unsigned) savedWindowSize >> 16);
      bottom= windowBounds.y + (savedWindowSize & 0xFFFF);
    }
  else
    {
      right= windowBounds.x + windowBounds.width;
      bottom= windowBounds.y + windowBounds.height;
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

  /* create the Squeak window */
  {
    XSetWindowAttributes attributes;
    unsigned long valuemask, valuemaskForParent;

    attributes.border_pixel= BlackPixel(stDisplay, DefaultScreen(stDisplay));
    attributes.background_pixel= BlackPixel(stDisplay, DefaultScreen(stDisplay));
    attributes.event_mask= WM_EVENTMASK;
    attributes.backing_store= Always;

    valuemask= CWEventMask | CWBackingStore | CWBorderPixel | CWBackPixel;
    valuemaskForParent= CWEventMask | CWBorderPixel ;  /* For some reason, leaving out CWBorderPixel causes errors on certain Sun boxes */

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
	valuemaskForParent|= CWColormap;
      }

    if (browserWindow != 0)
      stParent= browserWindow;
    else
      stParent= XCreateWindow(stDisplay,
			      DefaultRootWindow(stDisplay),
			      windowBounds.x, windowBounds.y,
			      windowBounds.width, windowBounds.height,
			      0,
			      stDepth, CopyFromParent, stVisual,
			      valuemaskForParent, &attributes);

    attributes.event_mask= EVENTMASK;

    stWindow= XCreateWindow(stDisplay, stParent,
			    0, 0,
			    windowBounds.width, windowBounds.height,
			    0,
			    stDepth, InputOutput, stVisual,
			    valuemask, &attributes);
    stWindowWidth= windowBounds.width;
    stWindowHeight= windowBounds.height;
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
  }

  /* tell the WM that we can't be bothered managing focus for ourselves */
  {
    XWMHints *wmHints= XAllocWMHints();
    wmHints->input= True;
    wmHints->initial_state= NormalState;
    wmHints->flags= InputHint|StateHint;
# ifndef NO_ICON
    wmHints->icon_pixmap=
      XCreateBitmapFromData(stDisplay, DefaultRootWindow(stDisplay),
			    sqXIcon_bits, sqXIcon_width, sqXIcon_height);
    if (wmHints->icon_pixmap != None) wmHints->flags |= IconPixmapHint;
# endif
    XSetWMHints(stDisplay, stParent, wmHints);
    XFree((void *)wmHints);
  }

  /* create a suitable graphics context */
  {
    XGCValues gcValues;

    gcValues.function= GXcopy;
    gcValues.subwindow_mode= IncludeInferiors;
    gcValues.clip_x_origin= 0;
    gcValues.clip_y_origin= 0;
    gcValues.clip_mask= None;
    gcValues.foreground= SqueakBlack;
    gcValues.background= SqueakWhite;
    gcValues.fill_style= FillSolid;
    stGC= XCreateGC(stDisplay,
		    stWindow,
		    GCFunction | GCSubwindowMode |
		    GCClipXOrigin | GCClipYOrigin | GCClipMask |
		    GCForeground | GCBackground | GCFillStyle,
		    &gcValues);
  }

  if (noTitle || fullScreen)
    /* naughty, but effective */
    XSetTransientForHint(stDisplay, stParent, DefaultRootWindow(stDisplay));

# ifdef USE_XSHM
  completionType= XShmGetEventBase(stDisplay) + ShmCompletion;
# endif

	clipboardAtom = XInternAtom(stDisplay, "CLIPBOARD", False);
	primaryAtom = XInternAtom(stDisplay, "PRIMARY", False);
}


void SetWindowSize(void)
{
  int width, height, maxWidth, maxHeight;

  if (browserWindow) return;

  if (savedWindowSize != 0)
    {
      width=  (unsigned)savedWindowSize >> 16;
      height= savedWindowSize & 0xFFFF;
    }
  else
    {
      width=  640;
      height= 480;
    }

  /* minimum size is 64 x 64 */
  width=  ( width > 64) ?   width : 64;
  height= (height > 64) ?  height : 64;

  /* maximum size is screen size, rounded down to a multiple of sizeof(void *) */
  maxWidth=  (DisplayWidth(stDisplay, DefaultScreen(stDisplay)));
  maxHeight= (DisplayHeight(stDisplay, DefaultScreen(stDisplay)));
  maxWidth= (maxWidth / sizeof(void *)) * sizeof(void *);
  maxHeight= (maxHeight / sizeof(void *)) * sizeof(void *);
  
  width=  ( width <= maxWidth)  ?  width : maxWidth;
  height= (height <= maxHeight) ? height : maxHeight;

  if (fullScreen)
    {
      width= maxWidth;
      height= maxHeight;
    }

  XResizeWindow(stDisplay, stParent, width, height);
}


/*** Event Recording Functions ***/

/* translate special keys; return -1 if the key isn't recognized */
static int translateCode(KeySym symbolic)
{
  int ALT=(8<<8);
  
    
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
    case XK_BackSpace:  return  8;
    case XK_Delete:     return 127;
 
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
# ifdef XK_ISO_Left_Tab
    case XK_ISO_Left_Tab: return  9;	/* shift-tab */
# endif

    default:		return -1;
    }
  /*NOTREACHED*/
}


void keyBufAppend(int keystate)
{
  /* bug: this should be rewritten to cope with nConv > 1 */
  keyBuf[keyBufPut]= keystate;
  keyBufPut= (keyBufPut + 1) % KEYBUF_SIZE;
  if (keyBufGet == keyBufPut)
    {
      /* buffer overflow; drop the last character */
      keyBufGet= (keyBufGet + 1) % KEYBUF_SIZE;
      keyBufOverflows++;
    }
}



/* return the squeak mask for an X button number */
static unsigned int squeakMaskForXButton(int button) 
{
  switch(button)     {
  case 1:
    return RedButtonBit;

  case 2:
    return YellowButtonBit;

  case 3:
    return BlueButtonBit;

  default:
    /* ignore buttons other than 1-3 */
    return 0;
  }
  
}


/* record the mouse buttons and modifier keys pressed according to an X event.
   This routine also translates meta-button1 into button3 */
static void recordModifierButtons(XButtonEvent *theEvent,
				  int buttonToAdd,
				  int buttonToRemove)
{
  /* translate the button encodings */
  stButtons= 0;
  if(theEvent->state & Button1Mask)  stButtons|= RedButtonBit;
  if(theEvent->state & Button2Mask)  stButtons|= YellowButtonBit;
  if(theEvent->state & Button3Mask)  stButtons|= BlueButtonBit;
  stButtons|= squeakMaskForXButton(buttonToAdd);
  stButtons&= ~ squeakMaskForXButton(buttonToRemove);

  /* translate the modifiers pressed */
  modifiers= 0;
  if(theEvent->state & ShiftMask)        modifiers|= ShiftKeyBit;
  if(theEvent->state & LockMask)         modifiers|= ShiftKeyBit;
  if(theEvent->state & ControlMask)      modifiers|= CtrlKeyBit;
  if(theEvent->state & Mod1Mask)         modifiers|= CommandKeyBit;
  


  /* remap the red button, if Control or Meta is pressed */
  if ((stButtons == RedButtonBit) && (modifiers & CtrlKeyBit))
  {
    /* ctrl-red is mapped to the yellow button */
    stButtons= YellowButtonBit;
    modifiers &= ~CtrlKeyBit;
  }
    
  if ((stButtons == RedButtonBit) && (modifiers & CommandKeyBit)) {
    /* meta-red is mapped to the blue button */
    stButtons= BlueButtonBit;
    modifiers &= ~CommandKeyBit;
  }


  
  /* combine the button state in the format Squeak likes */
  buttonState= (modifiers << 3) | (stButtons & 0x7);
}


#endif /*!HEADLESS*/


/*** I/O Primitives ***/


int ioFormPrint(int bitsAddr, int width, int height, int depth,
		double hScale, double vScale, int landscapeFlag)
{
#ifdef HEADLESS
  return false;
#else
  FILE *ppm;
  float scale;  /* scale to use with pnmtops */
  char printCommand[1000];
  unsigned int *form32;  /* the form data, in  32 bits */
  

  /* convert the form to 32 bits */
  form32 = malloc(width * height * 4);
  if(form32 == NULL) {
    fprintf(stderr, "not enough memory\n");
    return false;
  }
  switch(depth) {
  case 1:
    copyImage1To32((int *) bitsAddr, (int *) form32,
		   width, height,
		   1, 1, width, height);
    break;
  case 2:
    copyImage2To32((int *) bitsAddr, (int *) form32,
		   width, height,
		   1, 1, width, height);
    break;
  case 4:
    copyImage4To32((int *) bitsAddr, (int *) form32,
		   width, height,
		   1, 1, width, height);
    break;
  case 8:
    copyImage8To32((int *) bitsAddr, (int *) form32,
		   width, height,
		   1, 1, width, height);
    break;

  case 15:
  case 16:
    copyImage16To32((int *) bitsAddr, (int *) form32,
		    width, height,
		    1, 1, width, height);
    break;
  case 32:
    copyImage32To32((int *) bitsAddr, (int *) form32,
		    width, height,
		    1, 1, width, height);
    break;
  default:
    fprintf(stderr, "error in formPrint: unhandled form depth %d\n", depth);
    free(form32);
    return false;
  }
  
  /* pick a scale. unfortunately, pnmtops requires the same scale
     horizontally and vertically */
  if(hScale < vScale)
    scale= hScale;
  else
    scale= vScale;


  /* assemble the command for printing.  pnmtops is part of "netpbm",
     a widely-available set of tools that eases image manipulation */ 
  snprintf(printCommand, sizeof(printCommand),
	   "pnmtops -scale %f %s | lpr",
	   scale,
	   (landscapeFlag ? "-turn" : "-noturn"));


  
  /* open a pipe to print through */
  if ((ppm= popen(printCommand, "w")) == 0) {
    free(form32);
    return false;
  }
  
  
  /* print the PPM magic number */
  fprintf(ppm, "P3\n%d %d 255\n", width, height);

  /* write the pixmap */
  {
    int y;
    for (y= 0; y < height; ++y) {
      int x;
      for (x= 0; x < width; ++x) {
	int pixel, red, green, blue;

	pixel= form32[y*width + x];
	red=   (pixel >> 16) & 0xFF;
	green= (pixel >> 8)  & 0xFF;
	blue=  (pixel >> 0)  & 0xFF;

	fprintf(ppm, "%d %d %d\n", red, green, blue);
      }
    }
  }
    
      
  free(form32);
  pclose(ppm);
  return true;
#endif  /* HEADLESS */
}


int ioBeep(void)
{
#ifndef HEADLESS
  XBell(stDisplay, 0);	/* ring at default volume */
#endif
  return 0;
}


int ioGetButtonState(void)
{
  ioProcessEvents();  /* process all pending events */
#ifndef HEADLESS
  return buttonState;
#else
  return 0;
#endif
}

int ioGetKeystroke(void)
{
#ifndef HEADLESS
  int keystate;
#endif

  ioProcessEvents();  /* process all pending events */
#ifdef HEADLESS
  return -1;  /* keystroke buffer is empty */
#else
  if (keyBufGet == keyBufPut)
    return -1;  /* keystroke buffer is empty */

  keystate= keyBuf[keyBufGet];
  keyBufGet= (keyBufGet + 1) % KEYBUF_SIZE;

  return keystate;
#endif
}


int ioLowResMSecs(void)
{
#ifdef USE_ITIMER
  return lowResMSecs;
#else
  return ioMSecs();
#endif
}


int ioMSecs(void)
{
  struct timeval now;
  gettimeofday(&now, 0);
  if ((now.tv_usec-= startUpTime.tv_usec) < 0) {
    now.tv_usec+= 1000000;
    now.tv_sec-= 1;
  }
  now.tv_sec-= startUpTime.tv_sec;
  return (now.tv_usec / 1000 + now.tv_sec * 1000);
}

int ioMicroMSecs(void)
{
  /* return the highest available resolution of the millisecond clock */
  return ioMSecs();	/* this already to the nearest millisecond */
}

int ioRelinquishProcessorForMicroseconds(int microSeconds)
{
  aioPoll(microSeconds);
  return microSeconds;
}

int ioMousePoint(void)
{
  ioProcessEvents();  /* process all pending events */
  /* x is high 16 bits; y is low 16 bits */
#ifndef HEADLESS
  return (mousePosition.x << 16) | (mousePosition.y);
#else
  return 0;
#endif
}

int ioPeekKeystroke(void)
{
#ifdef HEADLESS
  ioProcessEvents();  /* process all pending events */
  return -1;  /* keystroke buffer is empty */
#else
  int keystate;

  ioProcessEvents();  /* process all pending events */

  if (keyBufGet == keyBufPut)
    return -1;  /* keystroke buffer is empty */

  keystate= keyBuf[keyBufGet];
  return keystate;
#endif
}


int ioProcessEvents(void)
{
  /* This code used to delay before processing events, but that
     behavior is pretty well taken care of if you are in morphic.
     Plus, aioPoll() is just a select() call, anyway -- it should be
     pretty fast if there are no events.  */
  aioPoll(0);
  return 0;
}


/* returns the depth of the Squeak window */
int ioScreenDepth(void)
{
#ifdef HEADLESS
  return 1;
#else
  Window root;
  int x, y;
  unsigned int w, h, b, d;

  if (!isConnectedToXServer)
    return 1;

  XGetGeometry(stDisplay, stParent, &root, &x, &y, &w, &h, &b, &d);
  return d;
#endif
}


/* returns most recently known size of the Squeak window */
/* the return is encoded as:
      (width << 16) | height
*/
int ioScreenSize(void)
{
#ifdef HEADLESS
  int headless= 1;
#else

  if (headless || !isConnectedToXServer)
    {
      if(savedWindowSize != 0)
	return savedWindowSize;
      else
	return (64 << 16) | 64;
    }
  
    
  return (stWindowWidth << 16) | stWindowHeight;

#endif
}


time_t convertToSqueakTime(time_t unixTime)
{
#ifdef HAVE_TM_GMTOFF
  unixTime+= localtime(&unixTime)->tm_gmtoff;
#else
# ifdef HAVE_TIMEZONE
  unixTime+= ((daylight) * 60*60) - timezone;
# else
#  error: cannot determine timezone correction
# endif
#endif
  /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
     and 52 non-leap years later than Squeak. */
  return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
}


/* returns the local wall clock time */
int ioSeconds(void)
{
  return convertToSqueakTime(time(0));
}

#ifndef HEADLESS
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
#endif


int ioSetCursorWithMask(int cursorBitsIndex, int cursorMaskIndex,
			int offsetX, int offsetY)
{
#ifndef HEADLESS
  unsigned char data[32], mask[32];	/* cursors are always 16x16 */
  int i;
  Cursor cursor;
  Pixmap dataPixmap, maskPixmap;

  if (!isConnectedToXServer)
    return 0;

#if 0
  if (cursorMaskIndex == null) {
    for (i= 0; i < 16; i++)
      {
	data[i*2+0]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 24) & 0xFF;
	data[i*2+1]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFF;
	mask[i*2+0]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 24) & 0xFF;
	mask[i*2+1]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFF;
      }
  } else {
    for (i= 0; i < 16; i++)
      {
	data[i*2+0]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 24) & 0xFF;
	data[i*2+1]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFF;
	mask[i*2+0]= ((unsigned)checkedLongAt(cursorMaskIndex + (4 * i)) >> 24) & 0xFF;
	mask[i*2+1]= ((unsigned)checkedLongAt(cursorMaskIndex + (4 * i)) >> 16) & 0xFF;
      }
  }
#else
  if (cursorMaskIndex == null)
    cursorMaskIndex= cursorBitsIndex;

  for (i= 0; i < 16; i++)
    {
      data[i*2+0]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 24) & 0xFF;
      data[i*2+1]= ((unsigned)checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFF;
      mask[i*2+0]= ((unsigned)checkedLongAt(cursorMaskIndex + (4 * i)) >> 24) & 0xFF;
      mask[i*2+1]= ((unsigned)checkedLongAt(cursorMaskIndex + (4 * i)) >> 16) & 0xFF;
    }
#endif

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
#endif
  return 0;
}


int ioSetCursor(int cursorBitsIndex, int offsetX, int offsetY)
{
  /* Deprecated: forward to new version with explicit mask. */
  ioSetCursorWithMask(cursorBitsIndex, null, offsetX, offsetY);
  return 0;
}

#ifndef HEADLESS

static void overrideRedirect(Display *dpy, Window win, int flag)
{
  XSetWindowAttributes attrs;
  attrs.override_redirect= flag;
  XChangeWindowAttributes(dpy, win, CWOverrideRedirect, &attrs);
}

#endif

int ioSetFullScreen(int fs)
{
#ifndef HEADLESS
  int winX, winY;
  unsigned int winW, winH;

  if (!isConnectedToXServer)
    return 0;
  
  fullScreen= fs;
  

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
	  savedWindowSize= (winW << 16) + (winH & 0xFFFF);
	  savedWindowOrigin= (winX << 16) + (winY & 0xFFFF);
	  XSynchronize(stDisplay, True);
	  overrideRedirect(stDisplay, stWindow, True);
	  XReparentWindow(stDisplay, stWindow, root, 0, 0);
	  XResizeWindow(stDisplay, stWindow, scrW, scrH);
	  XRaiseWindow(stDisplay, stWindow);
	  XSetInputFocus(stDisplay, stWindow, RevertToPointerRoot, CurrentTime);
	  XSynchronize(stDisplay, False);

	  stWindowWidth= scrW;
	  stWindowHeight= scrH;
	}
    }
  else
    {
      /* reverting to sub-screen mode */
      if (savedWindowOrigin != -1)
	{ /* previous call enabled full-screen mode */
	  /* get old window size */
	  winW= (unsigned) savedWindowSize >> 16;
	  winH= savedWindowSize & 0xFFFF;
	  /* minimum size is 64 x 64 */
	  winW= (winW > 64) ? winW : 64;
	  winH= (winH > 64) ? winH : 64;
	  /* old origin */
	  winX= savedWindowOrigin >> 16;
	  winY= savedWindowOrigin & 0xFFFF;
	  savedWindowOrigin= -1; /* prevents consecutive full-screen disables */
	  XSynchronize(stDisplay, True);
	  XReparentWindow(stDisplay, stWindow, stParent, 0, 0);
	  overrideRedirect(stDisplay, stWindow, False);
	  XResizeWindow(stDisplay, stWindow, winW, winH);
	  XSynchronize(stDisplay, False);

	  stWindowWidth= winW;
	  stWindowHeight= winH;
	}
    }
  /* sync avoids race with ioScreenSize() reading geometry before resize event */
  XSync(stDisplay, False);
  getMousePosition();
#endif /*!HEADLESS*/
  return 0;
}


#ifndef HEADLESS



/*** shared-memory stuff ***/



# ifdef USE_XSHM
static int xError(Display *dpy, XErrorEvent *evt)
{
  char buf[2048];
  XGetErrorText(stDisplay, evt->error_code, buf, sizeof(buf));
  fprintf(stderr, "XShmAttach: %s\n", buf);
  return 0;
}
#endif


static void *stMalloc(size_t lbs)
{
# ifdef USE_XSHM
  if (useXshm)
    {
      if ((stShmInfo.shmid= shmget(IPC_PRIVATE, lbs, IPC_CREAT|0777)) == -1)
	perror("shmget");
      else
	{
	  if ((int)(stShmInfo.shmaddr= (char *)shmat(stShmInfo.shmid, 0, 0)) == -1)
	    perror("shmat");
	  else
	    {
	      /* temporarily install error handler */
	      XErrorHandler prev= XSetErrorHandler(xError);
	      int result= 0;
	      stShmInfo.readOnly= False;
	      result= XShmAttach(stDisplay, &stShmInfo);
	      XSync(stDisplay, False);
	      XSetErrorHandler(prev);
	      if (result)
		/* success */
		return stShmInfo.shmaddr;
	    }
	  /* could not attach to allocated shared memory segment */
	  shmctl(stShmInfo.shmid, IPC_RMID, 0);
	  shmdt(stShmInfo.shmaddr);
	}
      /* could not allocate shared memory segment */
      useXshm= 0;
    }
# endif /* USE_XSHM */
  return (void *)malloc(lbs);
}


static void stFree(void *addr)
{
#ifdef USE_XSHM
  if (!useXshm)
#endif
    {
      free(addr);
      return;
    }
#ifdef USE_XSHM
  shmctl(stShmInfo.shmid, IPC_RMID, 0);
  shmdt(stShmInfo.shmaddr);
#endif
}

#ifdef USE_XSHM
static void shmExit(void)
{
  if (stDisplayBitmap && useXshm)
    stFree(stDisplayBitmap);
}
#endif


static XImage *stXCreateImage(Display *display, Visual *visual,
			      int depth, int format, int flags, char *data,
			      int width, int height, int bpp, int pad)
{
#ifdef USE_XSHM
  if (!useXshm)
#endif
    return XCreateImage(display, visual, depth, format, flags,
			data, width, height, bpp, pad);
#ifdef USE_XSHM
  return XShmCreateImage(display, visual, depth, format, data,
			 &stShmInfo, width, height);
#endif
}


static void stXPutImage(Display *display, Window window, GC gc, XImage *image,
			int src_x, int src_y, int dst_x, int dst_y, int w, int h)
{
#ifdef USE_XSHM
  if (!useXshm)
#endif
    {
      XPutImage(display, window, gc, image, src_x, src_y, dst_x, dst_y, w, h);
      return;
    }
#ifdef USE_XSHM
  XShmPutImage(display, window, gc, image, src_x, src_y, dst_x, dst_y, w, h, True);
  ++completions;
  if (!asyncUpdate)
    do {
      HandleEvents();
    } while (completions);
#endif
}


static void stXDestroyImage(XImage *image)
{
#ifdef USE_XSHM
  if (useXshm)
    XShmDetach(stDisplay, &stShmInfo);
#endif
  XDestroyImage(image);
}


#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)
#define bytesPerLineRD(width, depth)	((((width)*(depth)) >> 5) << 2)

#endif /*!HEADLESS*/


int ioForceDisplayUpdate(void)
{
#if !defined(HEADLESS) && defined(USE_XSHM)
  if (asyncUpdate && isConnectedToXServer) {
    XFlush(stDisplay);
    do {
      HandleEvents();
    } while (completions);
  }
#endif
  return 0;
}


int ioShowDisplay(int dispBitsIndex, int width, int height, int depth,
		  int affectedL, int affectedR, int affectedT, int affectedB)
{
#ifndef HEADLESS
  if (stWindow == 0)
    return 0;


  /* Sanitize the input values */
  if (affectedR >= width)  affectedR= width-1;
  if (affectedL >= width)  affectedL= width-1;
  if (affectedB >= height) affectedB= height-1;
  if (affectedT >= height) affectedT= height-1;
  

  
  /* quit, if its a trivial region */
  if(affectedR < affectedL || affectedT > affectedB)
    return 1;

  if (!(depth == 1 || depth == 2 || depth == 4
	|| depth == 8 || depth == 16 || depth == 32))
    {
      fprintf(stderr, "depth %d is not supported\n", depth);
      exit(1);
      return 0;
    }

  if (stImage == NULL
      || stImage->width != width
      || stImage->height != height
      || stDisplayBitsIndex != dispBitsIndex) 
    {
      /* Display has changed size;  recreate stImage */
# if defined(USE_XSHM)
      if (asyncUpdate)
	{
	  /* wait for pending updates to complete before freeing the XImage */
	  while (completions) HandleEvents();
	}
# endif
      
      
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
      

# ifdef WORDS_BIGENDIAN
      if (!useXshm && depth == stBitsPerPixel &&
	  (depth != 16 || stHasSameRGBMask16) &&
	  (depth != 32 || stHasSameRGBMask32))
# else
      if (!useXshm && depth == stBitsPerPixel && depth == 32 && stHasSameRGBMask32)
# endif
	{
	  stDisplayBitmap= 0;
	}
      else
	{
	  stDisplayBitmap= stMalloc(bytesPerLine(width, stBitsPerPixel) * height);
	}

      stImage= stXCreateImage(stDisplay,
			      DefaultVisual(stDisplay, DefaultScreen(stDisplay)),
			      stDepth,
			      ZPixmap,
			      0,
			      (stDisplayBitmap
			         ? stDisplayBitmap
			         : (char *)dispBitsIndex),
			      width,
			      height,
			      32,
			      0);
      /* Xlib ignores the following */
# ifdef WORDS_BIGENDIAN
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

      stDisplayBitsIndex= dispBitsIndex;
    }
  

  if (depth != stBitsPerPixel)
    {
      if (depth == 1)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage1To8((int *)dispBitsIndex, (int *)stDisplayBitmap,
			    width, height,
			    affectedL, affectedT, affectedR, affectedB);
	    }
	  if (stBitsPerPixel == 16)
	    {
	      copyImage1To16((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if(stBitsPerPixel == 24)
	    {
	      copyImage1To24((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage1To32((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}
      
      else if (depth == 2)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage2To8((int *)dispBitsIndex, (int *)stDisplayBitmap,
			    width, height,
			    affectedL, affectedT, affectedR, affectedB);
	    }
	  if (stBitsPerPixel == 16)
	    {
	      copyImage2To16((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if(stBitsPerPixel == 24)
	    {
	      copyImage2To24((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage2To32((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}

      else if (depth == 4)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage4To8((int *)dispBitsIndex, (int *)stDisplayBitmap,
			    width, height,
			    affectedL, affectedT, affectedR, affectedB);
	    }
	  if (stBitsPerPixel == 16)
	    {
	      copyImage4To16((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if(stBitsPerPixel == 24)
	    {
	      copyImage4To24((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitsPerPixel == 32 */
	    {
	      copyImage4To32((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}

      else if (depth == 8)
	{
	  if (stBitsPerPixel == 16)
	    {
	      copyImage8To16((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if(stBitsPerPixel == 24)
	    {
	      copyImage8To24((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    } else /* stBitsPerPixel == 32 */
	    {
	      copyImage8To32((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	}
      else if (depth == 16)
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage16To8((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if ( stBitsPerPixel == 24)
	    {
	      copyImage16To24((int *)dispBitsIndex, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }else /* stBitsPerPixel == 32 */
	    {
	      copyImage16To32((int *)dispBitsIndex, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }
	}
      else /* depth == 32 */
	{
	  if (stBitsPerPixel == 8)
	    {
	      copyImage32To8((int *)dispBitsIndex, (int *)stDisplayBitmap,
			     width, height,
			     affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (stBitsPerPixel == 16)
	    {
	      copyImage32To16((int *)dispBitsIndex, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }
	  else /* stBitPerPixel == 24 */
	    {
	      copyImage32To24((int *)dispBitsIndex, (int *)stDisplayBitmap,
			      width, height,
			      affectedL, affectedT, affectedR, affectedB);
	    }
	}
    }
  else /* depth == stBitsPerPixel */
    {
      if (depth == 16 && !stHasSameRGBMask16)
	{
	  copyImage16To16((int *)dispBitsIndex, (int *)stDisplayBitmap,
			  width, height,
			  affectedL, affectedT, affectedR, affectedB);
	}
      else if (depth == 32 && !stHasSameRGBMask32)
	{
	  copyImage32To32((int *)dispBitsIndex, (int *)stDisplayBitmap,
			  width, height,
			  affectedL, affectedT, affectedR, affectedB);
	}
# ifdef WORDS_BIGENDIAN
#   ifdef USE_XSHM
      else if (useXshm)
	{
	  if (depth == 8)
	    {
	      copyImage8To8((int *)dispBitsIndex, (int *)stDisplayBitmap,
			    width, height,affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (depth == 16)
	    {
	      copyImage16To16((int *)dispBitsIndex, (int *)stDisplayBitmap,
			      width, height,affectedL, affectedT, affectedR, affectedB);
	    }
	  else if (depth == 32)
	    {
	      copyImage32To32((int *)dispBitsIndex, (int *)stDisplayBitmap,
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
	  copyReverseImageBytes((int *)dispBitsIndex, (int *)stDisplayBitmap,
				depth, width, height,
				affectedL, affectedT, affectedR, affectedB);
	}
      else if (depth == 16)
	{
	  copyReverseImageWords((int *)dispBitsIndex, (int *)stDisplayBitmap,
				depth, width, height,
				affectedL, affectedT, affectedR, affectedB);
	}
      else if (stDisplayBitmap != 0)
	{
	  /* there is a separate map, so we still need to copy */
	  if (depth == 32)
	    {
	      copyImage32To32Same((int *)dispBitsIndex, (int *)stDisplayBitmap,
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
#endif /* !HEADLESS */
  return 0;
}


int ioHasDisplayDepth(int i)
{
  switch (i)
    {
    case 1:
    case 2:
    case 4:
#    ifndef HEADLESS
      return stBitsPerPixel == 32;
#    endif
    case 8:
    case 16:
    case 32:
      return true;
    }
  return false;
}


int ioSetDisplayMode(int width, int height, int depth, int fullscreenFlag)
{
  fprintf(stderr, "ioSetDisplayMode(%d, %d, %d, %d)\n",
	  width, height, depth, fullscreenFlag);
  return 0;
}


#ifndef HEADLESS
void copyReverseImageBytes(int *fromImageData, int *toImageData,
			   int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB)
{
  register int scanLine, firstWord, lastWord;
  register int line;

  scanLine= bytesPerLine(width, depth);
  firstWord= scanLine*affectedT + bytesPerLineRD(affectedL, depth);
  lastWord= scanLine*affectedT + bytesPerLine(affectedR, depth);

  for (line= affectedT; line < affectedB; line++)
  {
    register unsigned char *from= (unsigned char *)((int)fromImageData+firstWord);
    register unsigned char *limit= (unsigned char *)((int)fromImageData+lastWord);
    register unsigned char *to= (unsigned char *)((int)toImageData+firstWord);
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

void copyReverseImageWords(int *fromImageData, int *toImageData,
			   int depth, int width, int height,
			   int affectedL, int affectedT, int affectedR, int affectedB)
{
  register int scanLine, firstWord, lastWord;
  register int line;

  scanLine= bytesPerLine(width, depth);
  firstWord= scanLine*affectedT + bytesPerLineRD(affectedL, depth);
  lastWord= scanLine*affectedT + bytesPerLine(affectedR, depth);

  for (line= affectedT; line < affectedB; line++)
    {
      register unsigned short *from= (unsigned short *)((int)fromImageData+firstWord);
      register unsigned short *limit= (unsigned short *)((int)fromImageData+lastWord);
      register unsigned short *to= (unsigned short *)((int)toImageData+firstWord);
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

void copyImage1To8(int *fromImageData, int *toImageData,
		   int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 1 not yet implemented in 8 bpp\n");
  exit(1);
}

void copyImage2To8(int *fromImageData, int *toImageData,
		   int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 2 not yet implemented in 8 bpp\n");
  exit(1);
}

void copyImage4To8(int *fromImageData, int *toImageData,
		   int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 4 not yet implemented in 8 bpp\n");
  exit(1);
}

void copyImage8To8(int *fromImageData, int *toImageData,
		   int width, int height,
		   int affectedL, int affectedT, int affectedR, int affectedB)
{
  register int scanLine, firstWord, lastWord;
  register int line;

  scanLine= bytesPerLine(width, 8);
  firstWord= scanLine*affectedT + bytesPerLineRD(affectedL, 8);
  lastWord= scanLine*affectedT + bytesPerLine(affectedR, 8);

  for (line= affectedT; line < affectedB; line++) {
    register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord);
    register unsigned int *limit= (unsigned int *)((int)fromImageData+lastWord);
    register unsigned int *to= (unsigned int *)((int)toImageData+firstWord);
    while (from < limit)
      *to++= *from++;
    firstWord+= scanLine;
    lastWord+= scanLine;
  }
}

void copyImage1To16(int *fromImageData, int *toImageData,
		    int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 1 not yet implemented in 16 bpp\n");
  exit(1);
}

void copyImage2To16(int *fromImageData, int *toImageData,
		    int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 2 not yet implemented in 16 bpp\n");
  exit(1);
}

void copyImage4To16(int *fromImageData, int *toImageData,
		    int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 4 not yet implemented in 16 bpp\n");
  exit(1);
}

void copyImage8To16(int *fromImageData, int *toImageData,
		    int width, int height,
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
      register unsigned char *from= (unsigned char *)((int)fromImageData+firstWord8);
      register unsigned char *limit= (unsigned char *)((int)fromImageData+lastWord8);
      register unsigned short *to= (unsigned short *)((int)toImageData+firstWord16);
      while (from < limit)
	{
#ifdef WORDS_BIGENDIAN
	  to[0]= stColors[from[0]];
	  to[1]= stColors[from[1]];
	  to[2]= stColors[from[2]];
	  to[3]= stColors[from[3]];
#else
	  to[0]= stColors[from[3]];
	  to[1]= stColors[from[2]];
	  to[2]= stColors[from[1]];
	  to[3]= stColors[from[0]];
#endif
	  from+= 4;
	  to+= 4;
	}
      firstWord8+= scanLine8;
      lastWord8+= scanLine8;
      firstWord16+= scanLine16;
    }
}

void copyImage16To8(int *fromImageData, int *toImageData,
		    int width, int height,
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
      register unsigned short *from= (unsigned short *)((int)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((int)fromImageData+lastWord16);
      register unsigned char *to= (unsigned char *)((int)toImageData+firstWord8);

      while (from < limit)
	{
#ifdef WORDS_BIGENDIAN
	  to[0]= map16To8(from[0]);
	  to[1]= map16To8(from[1]);
#else
	  to[0]= map16To8(from[1]);
	  to[1]= map16To8(from[0]);
#endif
	  from+= 2;
	  to+= 2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
      firstWord8+= scanLine8;
    }
#undef map16To8
}

void copyImage1To32(int *fromImageData, int *toImageData,
		    int width, int height,
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
      register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord1);
      register unsigned int *to= (unsigned int *)((int)toImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((int)toImageData+lastWord32);
      register int shift= firstShift1;
      while (to < limit)
	{
	  *to= stColors[(*from >> shift) & 1];
	  to++;
	  shift--;
	  if (shift < 0) {
	    shift= 31;
	    from++;
	  }
	}
      firstWord1+= scanLine1;
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
}

void copyImage2To32(int *fromImageData, int *toImageData,
		    int width, int height,
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
      register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord2);
      register unsigned int *to= (unsigned int *)((int)toImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((int)toImageData+lastWord32);
      register int shift= firstShift2;
      while (to < limit)
	{
	  *to= stColors[(*from >> shift) & 3];
	  to++;
	  shift-= 2;
	  if (shift < 0) {
	    shift= 30;
	    from++;
	  }
	}
      firstWord2+= scanLine2;
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
}

void copyImage4To32(int *fromImageData, int *toImageData,
		    int width, int height,
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
      register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord4);
      register unsigned int *to= (unsigned int *)((int)toImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((int)toImageData+lastWord32);
      register int shift= firstShift4;
      while (to < limit)
	{
	  *to= stColors[(*from >> shift) & 15];
	  to++;
	  shift-= 4;
	  if (shift < 0) {
	    shift= 28;
	    from++;
	  }
	}
      firstWord4+= scanLine4;
      firstWord32+= scanLine32;
      lastWord32+= scanLine32;
    }
}

void copyImage8To32(int *fromImageData, int *toImageData,
		    int width, int height,
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
      register unsigned char *from= (unsigned char *)((int)fromImageData+firstWord8);
      register unsigned char *limit= (unsigned char *)((int)fromImageData+lastWord8);
      register unsigned int *to= (unsigned int *)((int)toImageData+firstWord32);
      while (from < limit)
	{
#ifdef WORDS_BIGENDIAN
	  to[0]= stColors[from[0]];
	  to[1]= stColors[from[1]];
	  to[2]= stColors[from[2]];
	  to[3]= stColors[from[3]];
#else
	  to[0]= stColors[from[3]];
	  to[1]= stColors[from[2]];
	  to[2]= stColors[from[1]];
	  to[3]= stColors[from[0]];
#endif
	  from+= 4;
	  to+= 4;
	}
      firstWord8+= scanLine8;
      lastWord8+= scanLine8;
      firstWord32+= scanLine32;
    }
}

void copyImage1To24(int *fromImageData, int *toImageData,
		    int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 1 not yet implemented in 24 bpp\n");
  exit(1);
}

void copyImage2To24(int *fromImageData, int *toImageData,
		    int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 2 not yet implemented in 24 bpp\n");
  exit(1);
}

void copyImage4To24(int *fromImageData, int *toImageData,
		    int width, int height,
		    int affectedL, int affectedT, int affectedR, int affectedB)
{
  fprintf(stderr, "depth 4 not yet implemented in 24 bpp\n");
  exit(1);
}

void copyImage8To24(int *fromImageData, int *toImageData,
		    int width, int height,
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
      register unsigned char *from= (unsigned char *)((int)fromImageData+firstWord8);
      register unsigned char *limit= (unsigned char *)((int)fromImageData+lastWord8);
      register unsigned char *to= (unsigned char *)((int)toImageData+firstWord24);
      register unsigned int newpix= 0;
      while (from < limit)
	{
#ifdef WORDS_BIGENDIAN
	  newpix= stColors[from[0]];
#else
	  newpix= stColors[from[3]];
#endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#ifdef WORDS_BIGENDIAN
	  newpix= stColors[from[1]];
#else
	  newpix= stColors[from[2]];
#endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#ifdef WORDS_BIGENDIAN
	  newpix= stColors[from[2]];
#else
	  newpix= stColors[from[1]];
#endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#ifdef WORDS_BIGENDIAN
	  newpix= stColors[from[3]];
#else
	  newpix= stColors[from[0]];
#endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
	  from+=4;
	}
      firstWord8+= scanLine8;
      lastWord8+= scanLine8;
      firstWord24+= scanLine24;
    }
}

void copyImage32To8(int *fromImageData, int *toImageData,
		    int width, int height,
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
    register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord32);
    register unsigned int *limit= (unsigned int *)((int)fromImageData+lastWord32);
    register unsigned char *to= (unsigned char *)((int)toImageData+firstWord8);
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

void copyImage16To32(int *fromImageData, int *toImageData,
		     int width, int height,
		     int affectedL, int affectedT, int affectedR, int affectedB)
{
  int scanLine16, firstWord16, lastWord16;
  int scanLine32, firstWord32;
  int line;
  int rshift, gshift, bshift;
  register unsigned int col;

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
      register unsigned short *from= (unsigned short *)((int)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((int)fromImageData+lastWord16);
      register unsigned int *to= (unsigned int *)((int)toImageData+firstWord32);
      while (from < limit)
	{
#ifdef WORDS_BIGENDIAN
	  to[0]= map16To32(from[0]);
	  to[1]= map16To32(from[1]);
#else
	  to[0]= map16To32(from[1]);
	  to[1]= map16To32(from[0]);
#endif
	  from+= 2;
	  to+= 2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
      firstWord32+= scanLine32;
    }
#undef map16To32
}

void copyImage16To24(int *fromImageData, int *toImageData,
		     int width, int height,
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
      register unsigned short *from= (unsigned short *)((int)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((int)fromImageData+lastWord16);
      register unsigned char *to= (unsigned char *)((int)toImageData+firstWord24);
      register unsigned int newpix= 0;
      while (from < limit)
	{
#ifdef WORDS_BIGENDIAN
	  newpix= map16To24(from[0]);
#else
	  newpix= map16To24(from[1]);
#endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
#ifdef WORDS_BIGENDIAN
	  newpix= map16To24(from[1]);
#else
	  newpix= map16To24(from[0]);
#endif
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  newpix= newpix >> 8;
	  to++;
	  *to= (unsigned char) (newpix & 0xff);
	  to++;
	  from+=2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
      firstWord24+= scanLine24;
    }
#undef map16To24
}


void copyImage32To16(int *fromImageData, int *toImageData,
		     int width, int height,
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
      register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((int)fromImageData+lastWord32);
      register unsigned short *to= (unsigned short *)((int)toImageData+firstWord16);
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

void copyImage16To16(int *fromImageData, int *toImageData,
		     int width, int height,
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
      register unsigned short *from= (unsigned short *)((int)fromImageData+firstWord16);
      register unsigned short *limit= (unsigned short *)((int)fromImageData+lastWord16);
      register unsigned short *to= (unsigned short *)((int)toImageData+firstWord16);
      while (from < limit)
	{
#ifdef WORDS_BIGENDIAN
	  to[0]= map16To16(from[0]);
	  to[1]= map16To16(from[1]);
#else
	  to[0]= map16To16(from[1]);
	  to[1]= map16To16(from[0]);
#endif
	  from+= 2;
	  to+= 2;
	}
      firstWord16+= scanLine16;
      lastWord16+= scanLine16;
    }
#undef map16To16
}

void copyImage32To32(int *fromImageData, int *toImageData,
		     int width, int height,
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
      register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((int)fromImageData+lastWord32);
      register unsigned int *to= (unsigned int *)((int)toImageData+firstWord32);
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
      register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((int)fromImageData+lastWord32);
      register unsigned int *to= (unsigned int *)((int)toImageData+firstWord32);
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

void copyImage32To24(int *fromImageData, int *toImageData,
		     int width, int height,
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
      register unsigned int *from= (unsigned int *)((int)fromImageData+firstWord32);
      register unsigned int *limit= (unsigned int *)((int)fromImageData+lastWord32);
      register unsigned char *to= (unsigned char *)((int)toImageData+firstWord24);
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

#endif


/*** power management ***/


int ioDisablePowerManager(int disableIfNonZero)
{
  return true;
}

/*** VM & Image File Naming ***/


/* copy src filename to target, if src is not an absolute filename,
 * prepend the cwd to make target absolute */
void pathCopyAbs(char *target, const char *src, size_t targetSize)
{
  if (src[0] == '/')
  {
    strcpy(target, src);
  }
  else
  {
    getcwd(target, targetSize);
    strcat(target, "/");
    strcat(target, src);
  }
}

void RecordFullPathForVmName(char *localVmName)
{
  /* get canonical path to vm */
  if (realpath(localVmName, vmPath) == 0)
    pathCopyAbs(vmPath, localVmName, sizeof(vmPath));

  /* truncate vmPath to dirname */
  {
    int i= 0;
    for (i= strlen(vmPath); i >= 0; i--)
      if ('/' == vmPath[i])
	{
	  vmPath[i+1]= '\0';
	  return;
	}
  }
}

void RecordFullPathForImageName(char *localImageName)
{
  struct stat s;
  /* get canonical path to image */
  if ((stat(localImageName, &s) == -1) || (realpath(localImageName, imageName) == 0))
    pathCopyAbs(imageName, localImageName, sizeof(imageName));
}

int imageNameSize(void)
{
  return strlen(imageName);
}

int imageNameGetLength(int sqImageNameIndex, int length)
{
  char *sqImageName= (char *)sqImageNameIndex;
  int count, i;

  count= strlen(imageName);
  count= (length < count) ? length : count;

  /* copy the file name into the Squeak string */
  for (i= 0; i < count; i++)
    sqImageName[i]= imageName[i];

  return count;
}

int imageNamePutLength(int sqImageNameIndex, int length)
{
  char *sqImageName= (char *)sqImageNameIndex;
  int count, i;

  count= (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

  /* copy the file name into a null-terminated C string */
  for (i= 0; i < count; i++) imageName[i]= sqImageName[i];
  imageName[count]= 0;

#ifndef HEADLESS
  /* update the window title */
  if (isConnectedToXServer)
    XStoreName(stDisplay, stParent, imageName);
#endif

  return count;
}


/*** Timer support ***/


#ifdef USE_ITIMER
void sigalrm(int signum)
{
  lowResMSecs+= LOW_RES_TICK_MSECS;
}
#endif


void SetUpTimers(void)
{
  /* set up the micro/millisecond clock */
  gettimeofday(&startUpTime, 0);
#ifdef USE_ITIMER
  /* set up the low-res (50th second) millisecond clock */
  /* WARNING: all system calls must check for EINTR!!! */
  {
    struct sigaction sa;
    sigset_t ss1, ss2;
    sigemptyset(&ss1);
    sigprocmask(SIG_BLOCK, &ss1, &ss2);
    sa.sa_handler= sigalrm;
    sa.sa_mask= ss2;
#ifdef SA_RESTART
    sa.sa_flags= SA_RESTART;
#else
    sa.sa_flags= 0;	/* assume that we have default BSD behaviour */
#endif
#ifdef __linux__
    sa.sa_restorer= 0;
#endif
    sigaction(SIGALRM, &sa, 0);
  }
  {
    struct itimerval iv;
    iv.it_interval.tv_sec= 0;
    iv.it_interval.tv_usec= LOW_RES_TICK_MSECS * 1000;
    iv.it_value.tv_sec= 0;
    iv.it_value.tv_usec= LOW_RES_TICK_MSECS;
    setitimer(ITIMER_REAL, &iv, 0);
  }
#endif
}



/*** X selection handling ***/



#ifndef HEADLESS
void SetUpClipboard(void)
{
  stPrimarySelection= 0;
  stPrimarySelectionSize= 0;
  stOwnsSelection= 0;
  stOwnsClipboard= 0;
}
#endif

int clipboardSize(void)
{
#ifndef HEADLESS
  if (stOwnsSelection || stOwnsClipboard)
    return stPrimarySelection ? strlen(stPrimarySelection) : 0;
  return strlen(getSelection());
#else
  return 0;
#endif
}

#ifndef HEADLESS
static void allocateSelectionBuffer(int count)
{
  if (count+1 > stPrimarySelectionSize)
    {
      if (stPrimarySelection)
	{
	  free(stPrimarySelection);
	  stPrimarySelection= 0;
	  stPrimarySelectionSize= 0;
	}
      if (!(stPrimarySelection= (char *)malloc(count+1)))
	{
	  fprintf(stderr, "failed to allocate X selection buffer\n");
	  return;
	}
      stPrimarySelectionSize= count;
    }
}
#endif

/* claim ownership of the X selection, providing the given string to requestors */
int clipboardWriteFromAt(int count, int byteArrayIndex, int startIndex)
{
#ifndef HEADLESS
  char *srcPtr, *dstPtr, *end;

  allocateSelectionBuffer(count);

  srcPtr= (char *)byteArrayIndex + startIndex;
  dstPtr= stPrimarySelection;
  end= srcPtr + count;
  while (srcPtr < end)
    *dstPtr++= *srcPtr++;

  *dstPtr= '\0';

  claimSelection();
#endif
  return 0;
}

/* transfer the X selection into the given byte array; optimise local requests */
int clipboardReadIntoAt(int count, int byteArrayIndex, int startIndex)
{
#ifndef HEADLESS
  long clipSize, charsToMove;
  char *srcPtr, *dstPtr, *end;

  if (!isConnectedToXServer)
    return 0;

  if (!stOwnsSelection && !stOwnsClipboard)
    {
      char *newSelection;
      int newSize;

      /* need to keep a separate selection buffer, or we wouldn't know if it
	 was allocated by us or by X */
      newSelection= getSelection();	/* not necessarily allocated by X... */
      newSize= strlen(newSelection);
      allocateSelectionBuffer(newSize);
      strcpy(stPrimarySelection, newSelection);
      if (newSelection != stEmptySelection) /* ...so we only *sometimes*... */
	XFree(newSelection);		/* ...need to XFree() it! */
      ux2st(stPrimarySelection);
    }

  clipSize= clipboardSize();
  charsToMove= (count < clipSize) ? count : clipSize;

  srcPtr= (char *)stPrimarySelection;
  dstPtr= (char *)byteArrayIndex + startIndex;
  end= srcPtr + charsToMove;
  while (srcPtr < end)
    *dstPtr++= *srcPtr++;

  return charsToMove;
#else
  return 0;
#endif
}



/*** Profiling ***/



int clearProfile(void) { return 0; }
int dumpProfile(void) { return 0; }
int startProfiling(void) { return 0; }
int stopProfiling(void) { return 0; }



/*** Access to system attributes and command-line arguments ***/



static char *getAttribute(int id)
{
  if (id < 0) {
    /* VM argument */
    if (-id  < vmArgCnt)
      return vmArgVec[-id];
  } else switch (id) {
    case 0: 
      return vmArgVec[0];
    case 1:
      return imageName;
    case 1001:
      /* basic OS type: "unix", "win32", "mac", ... */
      return OS_TYPE;
    case 1002:
      /* specific OS type: "solaris2.5" on unix, "win95" on win32 */
      return VM_HOST_OS;
    case 1003:
      /* processor architecture: "68k", "x86", "PowerPC", ...  */
      return VM_HOST_CPU;
    case 1004:
      return  (char *)interpreterVersion;
    default:
      if ((id-2) < squeakArgCnt)
	return squeakArgVec[id-2];
  }
  success(false);
  return "";
}

int attributeSize(int id)
{
  return strlen(getAttribute(id));
}

int getAttributeIntoLength(int id, int byteArrayIndex, int length)
{
  if (length > 0)
    strncpy((char *)byteArrayIndex, getAttribute(id), length);
  return 0;
}



/*** Command line ***/



static char *progName= 0;

void usage()
{
  printf("Usage: %s [<option>...] [<imageName> [<argument>...]]\n", progName);
  printf("       %s [<option>...] -- [<argument>...]\n\n", progName);
  printf("<option> can be:\n");
  printf("  -align <n>           align functions at n-bytes (jit)\n");
#ifndef HEADLESS
  printf("  -browserWindow <id>  run in window <id>\n"); 
  printf("  -browserPipes <fds>  run as Browser plugin using command pipes <fds>\n");
  printf("  -display <dpy>       display on <dpy> (default: $DISPLAY)\n");
  printf("  -fullscreen          occupy the entire screen\n");
  printf("  -headless            run in headless (no window) mode\n");
#endif
  printf("  -help                print this help message, then exit\n");
  printf("  -jit                 enable the dynamic (runtime) compiler\n");
#ifndef HEADLESS
  printf("  -lazy                go to sleep when main window unmapped\n");
#endif
  printf("  -memory <size>[mk]   set initial memory size (default: %dm)\n",
	 DefaultHeapSize);
#ifndef HEADLESS
  printf("  -noevents            disable event-driven input support\n");
  printf("  -notitle             disable the Squeak window title bar\n");
#endif
  printf("  -spy                 enable the system spy (jit)\n");
  printf("  -version             print version information, then exit\n");
#ifndef HEADLESS
  printf("  -xasync              don't serialize display updates\n");
  printf("  -xshm                use X shared memory extension\n");
#endif
#if 0  /* on second thought, it makes absolutely no sense for someone
	  to use -args_in_header from the command line.  This is left
	  here for documentation, but it doesn't really need to be
	  printed out by -help */
  printf("  -args_in_header      read NUL-separated arguments from image header\n");
#endif
  printf("\nNotes:\n");
  printf("  <imageName> defaults to `squeak.image'.\n");
#ifndef HEADLESS
  printf("  Using `unix:0' for <dpy> may improve local display performance.\n");
  printf("  -xshm only works when Squeak is running on the X server host.\n");
#endif
  printf("  <argument>s are ignored, but are processed by the Squeak image.\n");
  printf("  The first <argument> normally names a Squeak `script' to execute.\n");
  printf("  Precede <arguments> by `--' to use default image.\n");
  exit(1);
}


void imageNotFound(char *imageName)
{
  /* image file is not found */
  fprintf(stderr,"\
Could not open the Squeak image file `%s'.

There are three ways to open a Squeak image file.  You can:
  1. Put copies of the default image and changes files in this directory.
  2. Put the name of the image file on the command line when you
     run squeak (use the `-help' option for more information).
  3. Set the environment variable SQUEAK_IMAGE to the name of the image
     that you want to use by default.

For more information, type: `man squeak' (without the quote characters).
", imageName);
  exit(1);
}


void versionInfo(void)
{
  extern int vm_serial;
  extern char *vm_date, *cc_version, *ux_version;
  
  fprintf(stderr, "%s %s #%d",
	  VM_HOST, SQ_VERSION, vm_serial);
  
    
  fprintf(stderr, " ["
	  AUDIO_INTERFACE " audio"
#if defined(USE_XSHM)
	  ", xshm"
#endif
#if defined(USE_MEMORY_MMAP)
	  ", memory-mmap"
#endif
	  "] ");
  

  fprintf(stderr, "%s %s\n",  vm_date, cc_version);
  fprintf(stderr,"%s\n", ux_version);


  fprintf(stderr, "default plugin location: %s/%s*.so\n",
	  SQ_LIBDIR, SQ_MODULE_PREFIX);
  
  exit(0);
}


void outOfMemory(void)
{
  fprintf(stderr, "out of memory\n");
  exit(1);
}


int strtobkm(const char *str)
{
  char *suffix;
  int value= strtol(str, &suffix, 10);
  switch (*suffix)
    {
    case 'k': case 'K':
      value*= 1024;
      break;
    case 'm': case 'M':
      value*= 1024*1024;
      break;
    }
  return value;
}


void ParseEnvironment(void)
{
  char *ev= 0;

  if ((ev= getenv("SQUEAK_ALIGN")))	asmAlign= atoi(ev);
  if (asmAlign <  1) asmAlign= 1;
  if (asmAlign > 16) asmAlign= 16;

  if ((ev= getenv("SQUEAK_IMAGE")))	strcpy(shortImageName, ev);
  else					strcpy(shortImageName,
					       "squeak.image");
  if ((ev= getenv("SQUEAK_MEMORY")))	initialHeapSize= strtobkm(ev);
#ifndef HEADLESS
  if (getenv("SQUEAK_LAZY"))		sleepWhenUnmapped= 1;
  if (getenv("SQUEAK_NOJIT"))		noJitter= 1;
  if (getenv("SQUEAK_JIT"))		noJitter= 0;
  if (getenv("SQUEAK_SPY"))		withSpy= 1;
  if (getenv("SQUEAK_NOTITLE"))		noTitle= 1;
  if (getenv("SQUEAK_FULLSCREEN"))	fullScreen= 1;  /* XXX should check whether the environment variable is 1 or 0 */
  if (getenv("SQUEAK_NOEVENTS"))	noEvents= 1;
#if defined(USE_XSHM)
  if (getenv("SQUEAK_XSHM"))		useXshm= 1;
  if (getenv("SQUEAK_XASYNC"))		asyncUpdate= 1;
#endif
#endif
}


/* defined below */
static void readHeaderOptions(const char *image_filename);


void ParseArguments(int argc, char *argv[], int parsing_header_args)
{
# define skipArg()	(--argc, argv++)
# define saveArg()	(vmArgVec[vmArgCnt++]= *skipArg())
  int args_in_header=0;   /* whether to read arguments from the image header */
  

  /* vm name */
  if(vmArgCnt == 0)
    saveArg();
  

  while ((argc > 0) && (**argv == '-'))	/* more options to parse */
    {
      char *arg= *argv;
      if (!strcmp(arg, "--"))		/* escape from option processing */
	break;

      saveArg();

      if      (!strcmp(arg, "-help"))		usage();
#    ifndef HEADLESS
      else if (!strcmp(arg, "-headless"))	headless= 1;
#      if defined(USE_XSHM)
      else if (!strcmp(arg, "-xshm"))		useXshm= 1;
      else if (!strcmp(arg, "-xasync"))		asyncUpdate= 1;
#      endif
      else if (!strcmp(arg, "-lazy"))		sleepWhenUnmapped= 1;
      else if (!strcmp(arg, "-noevents"))	noEvents= 1;
      else if (!strcmp(arg, "-notitle"))	noTitle= 1;
#    endif
      else if (!strcmp(arg, "-nojit"))		noJitter= 1;
      else if (!strcmp(arg, "-jit"))		noJitter= 0;
      else if (!strcmp(arg, "-spy"))		withSpy= 1;
#    ifndef HEADLESS
      else if (!strcmp(arg, "-fullscreen"))	fullScreen= 1;
#    endif
      else if (!strcmp(arg, "-version"))	versionInfo();
      else if (!strcmp(arg, "-args_in_header")) {
	args_in_header=1;
	if(argc > 0) {
	  /* record the image name */
	  strcpy(shortImageName, *skipArg());
	}
	/* read the arguments */
	if(!parsing_header_args)   /* but don't recurse */
	  readHeaderOptions(shortImageName);
      }
      else
	{
	  /* option requires an argument */
	  if      (arg == 0)			usage();
	  else if (!strcmp(arg, "-align"))
	    {
	      asmAlign= atoi(saveArg());
	      if (asmAlign <  1) asmAlign= 1;
	      if (asmAlign > 16) asmAlign= 16;
	    }
	  else if (!strcmp(arg, "-memory")) {
	    const char *arg = saveArg();
	    if (arg)
	      initialHeapSize= strtobkm(arg);
	  }
#        if !defined(HEADLESS)
	  else if (!strcmp(arg, "-display"))	displayName= saveArg();
	  else if (!strcmp(arg, "-browserWindow"))
	    {
	      sscanf(saveArg(), "%li", &browserWindow);
	      if (browserWindow == 0)
		{
		  fprintf(stderr, "Error: invalid -browserWindow argument!\n");
		  exit(1);
		}
	    }
	  else if (!strcmp(arg, "-browserPipes"))
	    { 
	      if (argc < 2) usage();
	      sscanf(saveArg(), "%i", &browserPipes[0]);
	      sscanf(saveArg(), "%i", &browserPipes[1]);
	      /* receive browserWindow */
#if 0
	      DPRINT("VM: reading browserWindow\n");
#endif
	      read(browserPipes[0], &browserWindow, 4);
	    }
#        endif
	  else
	    usage();
	} /* option with argument */
    } /* while(more options) */

  if (argc > 0)
    {
      if (!strcmp(*argv, "--"))
	skipArg();
      else
	{
	  /* look for an image name */
	  if(! args_in_header) {  /* if args_in_header, then the image name
				     will have already been read  */
	    if(parsing_header_args)
	      skipArg();
	    else {
	      strcpy(shortImageName, saveArg());
	      if (0 == strstr(shortImageName, ".image"))
		strcat(shortImageName, ".image");
	    }
	  }
	}
    }
  
  /* save remaining arguments as Squeak arguments */
  while (argc > 0)
    squeakArgVec[squeakArgCnt++]= *skipArg();

  
# undef saveArg
# undef skipArg
}


/* read options from the header of the specified image */
#define HEADER_SIZE 512
static void readHeaderOptions(const char *image_filename) 
{
  int fd;
  char *header;
  int header_argc=0;
  char *header_argv[512];
  int header_pos;   /* position in the header as we read from it */

  
  /* allocate the header on the heap, so that strings within it can be
     stored by ParseArguments later */
  header = malloc(HEADER_SIZE+1);
  if(header == NULL) {
    error("Out of Memory\n");
  }
  

  /* read the header */
  fd = open(image_filename, O_RDONLY);
  if(fd < 0) return;
  if(read(fd, header, HEADER_SIZE) < HEADER_SIZE) {
    free(header);
    close(fd);
    return;
  }
  header[HEADER_SIZE] = '\0';  /* make sure header is a valid C string */
  close(fd);
  
  

  if(header[0] != '#' || header[1] != '!') {
    /* not a Unix image file */
    free(header);
    return;
  }
  
  
  /* find the newline which marks the beginning of the options */
  header_pos = 0;
  while(header_pos < HEADER_SIZE && header[header_pos] != '\n')
    header_pos += 1;
  header_pos += 1;   /* skip the newline */

  /* read in options, one at a time; we are finished when either the
     header is exhausted, or a NUL character is seen at the beginning
     of an option */
  while(header_pos < HEADER_SIZE && header[header_pos] != '\0') {
    /* record one option */
    header_argv[header_argc] = &header[header_pos];
    header_argc += 1;

    /* find the begining of the next option */
    while(header_pos < HEADER_SIZE && header[header_pos] != '\0')
      header_pos += 1;

    /* skip over the '\0' */
    header_pos += 1;
  }


  /* got all options -- process them */
  ParseArguments(header_argc, header_argv, 1);
}




/*** internal image ***/



#if defined(USE_INTERNAL_IMAGE)

  /*-- EXPERIMENTAL -- read [and inflate] an internal image file --*/

int sqImageFileClose(FILE *f)
  {
    int err= 0;
    if (f != 0)
      return fclose(f);
    assert(internalImage != 0);
    if (internalZStream != 0)
      {
	printf("decompressed %ld bytes\n", ztell(internalZStream));
	err= zclose(internalZStream);
      }
    internalImage= 0;
    internalImagePtr= 0;
    internalZStream= 0;
    return err;
  }

  int sqImageFilePosition(FILE *f)
  {
    if (f != 0)
      return ftell(f);
    assert(internalImage != 0);
    if (internalZStream != 0)
      return ztell(internalZStream);
    return internalImagePtr - internalImage;
  }

  int sqImageFileRead(void *ptr, size_t sz, size_t count, FILE *f)
  {
    if (f != 0)
      return fread(ptr, sz, count, f);
    assert(internalImage != 0);
    if (internalZStream != 0)
      return zread(ptr, sz, count, internalZStream);
    memcpy(ptr, (void *)internalImagePtr, sz * count);
    internalImagePtr+= sz*count;
    return sz*count;
  }

  int sqImageFileSeek(FILE *f, long pos)
  {
    if (f != 0)
      return fseek(f, pos, SEEK_SET);
    assert(internalImage != 0);
    if (internalZStream != 0)
      return zseek(internalZStream, pos, SEEK_SET);
    internalImagePtr= internalImage + pos;
    return 0;
  }

/* get a value for RTLD_NOW, with increasing levels of desperation... */

#if !defined(RTLD_NOW)
# if defined(DL_NOW)
#   define RTLD_NOW DL_NOW
# elif defined(RTLD_LAZY)
#   define RTLD_NOW RTLD_LAZY
# elif defined(DL_LAZY)
#   define RTLD_NOW DL_LAZY
# else
#   warning: defining RTLD_NOW as 1
#   define RTLD_NOW 1
# endif
#endif
 
  int openInternal(void)
  {
    unsigned char *internalImageEnd= 0;
    void *handle= dlopen(0, RTLD_NOW);
    if (handle == 0)
      {
	fprintf(stderr, "dlopen: %s\n", dlerror());
	exit(1);
      }
    /* non-zero means use in-memory file operations */
    internalImage= (unsigned char *)dlsym(handle, "__squeak_image_start");
    if (internalImage != 0)
      {
	internalImageEnd= (unsigned char *)dlsym(handle, "__squeak_image_end");
	internalImagePtr= internalImage;
	printf("reading internal image at 0x%08x + %d\n",
	       (unsigned)internalImage,
	       (int)(internalImageEnd - internalImage));
	strcpy(shortImageName, "internal.image");
      }
    else
      {
	internalImage= (unsigned char *)dlsym(handle, "__squeak_image_gz_start");
	if (internalImage == 0)
	  return 0;
	internalImageEnd= (unsigned char *)dlsym(handle, "__squeak_image_gz_end");
	{
	  char name[64], comment[64];
	  if (0 == gzstat(internalImage,
			  name, sizeof(name), comment, sizeof(comment)))
	    {
	      fprintf(stderr, "internal image: %s\n", z_error);
	      exit(1);
	    }
	  printf("decompressing %s at 0x%08x + %d\n",
		 ((*name == '\0') ? "internal image" : name),
		 (unsigned)internalImage,
		 (int)(internalImageEnd - internalImage));
	  if (*name == '\0')
	    strcpy(shortImageName, "internal.image");
	  else
	    strcpy(shortImageName, name);
	  if (*comment != '\0')
	    printf("%s\n", comment);
	}
	/* non-zero means inflate on-the-fly */
	internalZStream= gzopen(internalImage, internalImageEnd - internalImage);
	if (internalZStream == 0)
	  {
	    fprintf(stderr, "zopen: %s\n", z_error);
	    exit(1);
	  }
      }
    dlclose(handle);
    return internalImage != 0;
  }

#endif /* USE_INTERNAL_IMAGE */


/*** Segmentation fault handler ***/


#include <signal.h>

void segv(int ignore)
{
  error("Segmentation fault");
}

#ifdef __alpha__
/* headers for setsysinfo (see below) */
# include <sys/sysinfo.h>
# include <sys/proc.h>
#endif



/*** ...we came in? ***/

int main(int argc, char **argv, char **envp)
{
  /* check the interpreter's size assumptions for basic data types */
  if (sizeof(int)    != 4) error("This C platform's integers are not 32 bits.");
  if (sizeof(double) != 8) error("This C platform's floats are not 64 bits.");
  if (sizeof(time_t) != 4) error("This C platform's time_t's are not 32 bits.");

  /* Make parameters global for access from pluggable primitives */
  argCnt= argc;
  argVec= argv;
  envVec= envp;

  /* Allocate arrays to store copies of pointers to command line
     arguments.  Used by getAttributeIntoLength(). */
  if ((vmArgVec= calloc(argc + 1, sizeof(char *))) == 0)
    outOfMemory();

  if ((squeakArgVec= calloc(argc + 1, sizeof(char *))) == 0)
    outOfMemory();

  signal(SIGSEGV, segv);

  /* initialisation */

# if defined(__alpha__)
  /* disable printing of unaligned access exceptions */
  {
    int buf[2]= { SSIN_UACPROC, UAC_NOPRINT };
    if (setsysinfo(SSI_NVPAIRS, buf, 1, 0, 0, 0) < 0)
      {
	perror("setsysinfo(UAC_NOPRINT)");
      }
  }
# endif

  progName= argv[0];
#ifndef HEADLESS
  if (!strcmp(progName, "headlessSqueak"))
    headless= 1;
#endif
  ParseEnvironment();
  ParseArguments(argc, argv, 0);
  SetUpTimers();
  aioInitialize();
  

# if !defined(HEADLESS) && defined(USE_XSHM)
#   ifdef AT_EXIT
      AT_EXIT(shmExit);
      {
	AT_EXIT((void(*)(void))ioShutdownAllModules);
      }
#   else
#     warning: cannot free display bitmap on exit!
#     warning: cannot shut down module system on exit!
#   endif
# endif

# if 0
 /* TPR - do not call these here; the module mechanism will call them at the right time automagically */
  sqFileInit();
  joystickInit();
# endif

# if defined(HAVE_TZSET)
  tzset();	/* should _not_ be necessary! */
# endif

  if (!realpath(argv[0], vmName))
    vmName[0]= 0; /* full VM name */

  /* read the image file and allocate memory for Squeak heap */
  {
    FILE *f= 0;

#   if defined(USE_INTERNAL_IMAGE) /* EXPERIMENTAL */
    if (openInternal())
      {
	RecordFullPathForImageName(shortImageName);
      }
    else
#   endif
      {
	if (0 == (f= fopen(shortImageName, "r")))
	  imageNotFound(shortImageName);
	else
	  RecordFullPathForImageName(shortImageName); /* full image path */
      }
    RecordFullPathForVmName(argv[0]); /* full vm path */
    readImageFromFileHeapSize(f, initialHeapSize);
    sqImageFileClose(f);
  }

#ifndef HEADLESS
  /* open the Squeak window. */
  if (headless)
    forgetXDisplay();
  else
    openXDisplay();
#endif

#if defined(HAVE_LIBDL) && defined(J_ENABLED) && !defined(J_PROFILE)
  {
    /* first try to find an internal dynamic compiler... */
    int handle= ioLoadModule(0);
    int comp= ioFindExternalFunctionIn("j_interpret", handle);
    /* ...and if that fails... */
    if ((comp == 0) && !noJitter)
      {
	/* ...try to find an external one */
	handle= ioLoadModule("SqueakCompiler");
	if (handle != 0)
	  comp= ioFindExternalFunctionIn("j_interpret", handle);
      }
    if (comp)
      {
	((void(*)(void))comp)();
	return 0;
      }
    else
      printf("could not find j_interpret\n");
  }
#endif /*HAVE_LIBDL*/

  /* run Squeak */
#ifndef J_PROFILE
  interpret();
#else
  j_interpret();
#endif

  return 0;
}


int ioExit(void)
{
#ifndef HEADLESS
  disconnectXDisplay();
#endif

  /*** Isn't this where... ***/

  exit(0);
}
