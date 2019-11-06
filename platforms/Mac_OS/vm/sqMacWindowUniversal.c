/****************************************************************************
*   PROJECT: Mac window, memory, keyboard interface.
*   FILE:    sqMacWindow.c
*   CONTENT:
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS:
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:  $Id: sqMacWindow.c 1296 2006-02-02 07:50:50Z johnmci $
*
*   NOTES:
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Feb 26th, 2002, JMM - use carbon get dominate device
*  Apr  17th, 2002, JMM Use accessors for VM variables.
*  May 5th, 2002, JMM cleanup for building as NS plugin
 3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
 3.5.1b5 June 25th, 2003 JMM fix memory leak on color table free, pull preferences from Info.plist under os-x
 3.7.0bx Nov 24th, 2003 JMM move preferences to main, the proper place.
 3.7.3bx Apr 10th, 2004 JMM fix crash on showscreen
 3.8.1b1 Jul 20th, 2004 JMM Start on multiple window logic
 3.8.6b1 Jan 25th, 2005 JMM flush qd buffers less often
 3.8.6b3 Jan 25th, 2005 JMM Change locking of pixels (less often)
 3.8.8b3 Jul 15th, 2005 JMM Add window(s) flush logic every 1/60 second for os-x
 3.8.8b6 Jul 19th, 2005 JMM tuning of the window flush
 3.8.8b15	Sept 12th, 2005, JMM set full screen only if not in full screen.
 3.8.10B5  Feb 3rd, 2006 JMM complete rewrite carbon only for universal
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
 3.8.13b4 Oct 16th, 2006 JMM headless
 3.8.14b1 Oct	,2006 JMM browser rewrite
 3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
 3.8.17b1  Apr 25th, 2007 JMM explict window open, add back ioSetDisplayModeOLD for 10.2.8

*****************************************************************************/

#include <Carbon/Carbon.h>
#include <QuickTime/Movies.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <pthread.h>
#include <unistd.h>

#include "sq.h"
#include "sqMacUIConstants.h"
#include "sqMacWindow.h"
#include "sqMacUnixFileInterface.h"
#include "sqMacUIEvents.h"
#include "sqMacUIMenuBar.h"
#include "sqMacEncoding.h"
#include "sqMacHostWindow.h"
#include "sqMacTime.h"
#include "sqMacNSPluginUILogic2.h"

extern int gSqueakDebug;

# define DPRINTF(ARGS) if (gSqueakDebug) fprintf ARGS

/*** Variables -- Imported from Virtual Machine ***/
extern int getFullScreenFlag();    /* set from header when image file is loaded */
extern int setFullScreenFlag(int value);    /* set from header when image file is loaded */
extern int getSavedWindowSize();   /* set from header when image file is loaded */
extern int setSavedWindowSize(int value);   /* set from header when image file is loaded */
extern struct VirtualMachine *interpreterProxy;
extern Boolean gSqueakHeadless;
static void sqShowWindowActual(int windowIndex);

Boolean gSqueakHasCursor = false;

/*** Variables -- Mac Related ***/
static CTabHandle	stColorTable = nil;
PixMapHandle	stPixMap = nil;


/*** Functions ***/
static void SetColorEntry(int index, int red, int green, int blue);

WindowPtr getSTWindow(void) {
	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return NULL;
    return  windowHandleFromIndex(1);
}

double ioScreenScaleFactor(void) {
    return 1.0;
}

/*
 * Brad's Mac-ification of Andreas' window sizing prims.
 */
sqInt ioGetWindowWidth(void) {
  Rect r;
  WindowPtr win = getSTWindow();

  if (! win) return -1;

  r.left = r.right = r.top = r.bottom = 0;
  if (GetWindowBounds( win, kWindowStructureRgn, &r) != 0) {
	return -1;
  }
  return (r.right - r.left);
}

sqInt ioGetWindowHeight(void) {
  Rect r;
  WindowPtr win = getSTWindow();

  if (! win) return -1;

  r.left = r.right = r.top = r.bottom = 0;
  if (GetWindowBounds( win, kWindowStructureRgn, &r) != 0) {
	return -1;
  }
  return (r.bottom - r.top);
}

void* ioGetWindowHandle(void)
{
	return getSTWindow();
}

sqInt
ioSetWindowWidthHeight(sqInt w, sqInt h) {
#if _LP64
	/* SetWindowBounds is unsupported on 64-bits.  For now bail. */
	return 0;
#else
  Rect workArea;
  Rect newBounds;
  Rect oldBounds;
  int width, height, maxWidth, maxHeight;
  WindowPtr win;
  GDHandle device;
  OSStatus result;
  void *  giLocker;

  win = getSTWindow();
  if(! win) return 0;
  device = getThatDominateGDevice (win);
  if (! device) return 0;

  windowDescriptorBlock *windowBlock = windowBlockFromIndex(1);
  if (! windowBlock) return 0;

  if (GetAvailableWindowPositioningBounds (device, &workArea) != 0) return 0;

  width = w;
  height = h;

  /* minimum size is 64 x 64 */
  width  = (width > 64) ? width : 64;
  height = (height > 64) ? height : 64;

  /* maximum size is working area less a bit of slop so the result
     remains 'within' the screen' */
  maxWidth  = workArea.right - workArea.left;
  maxHeight = workArea.bottom - workArea.top;
  width  = (width <= (maxWidth-4)) ? width : maxWidth-4;
  height = (height <= (maxHeight-4)) ? height : maxHeight-4;

  result = GetWindowBounds (win, kWindowStructureRgn, &oldBounds);
  if (result != 0) return 0;

  /* Do we need to move the window to fit onscreen? */
  if ((oldBounds.top >= workArea.top) && (oldBounds.left >= workArea.left) &&
      (oldBounds.left + width < workArea.right) && (oldBounds.top + height <= workArea.bottom)) {
  	newBounds.left = oldBounds.left;
  	newBounds.top = oldBounds.top;
  } else {
  	newBounds.left = workArea.left + ((maxWidth - width) / 2);
  	newBounds.top = workArea.top + ((maxHeight - height) / 2);
  }
  newBounds.right = newBounds.left + width;
  newBounds.bottom = newBounds.top + height;

  /* Do we need to do anything? */
  if ( (oldBounds.top = newBounds.top) && (oldBounds.left == newBounds.left) &&
	   ((oldBounds.right - oldBounds.left) == (newBounds.right - newBounds.left)) &&
       ((oldBounds.bottom - oldBounds.top) == (newBounds.bottom - newBounds.top)) ) {
	return 1;
  }

  /** And awayyyyyy we go **/
  giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
  if (giLocker != 0) {
    sqInt foo[6] = { 3,
					(sqInt)SetWindowBounds,
					(sqInt)win,
					kWindowStructureRgn,
					(sqInt) &newBounds,
					0 };
    ((sqInt (*) (void *)) giLocker)(foo);
    result = interpreterProxy->positive32BitIntegerFor(foo[5]);
  }

  /* Remember new port extent for subsequent drawing */
  {
    Rect portRect;
    GetWindowPortBounds(win, &portRect);
    w =  portRect.right -  portRect.left;
    h =  portRect.bottom - portRect.top;
    windowBlock->width = w;
    windowBlock->height = h;
  }

  if (result != 0) return 0;	 /* Failed */

  return 1;
#endif /* _LP64 */
}


static char windowTitle[1024];

char *ioGetWindowLabel(void) {
	CFStringRef cfTitle;
	if (CopyWindowTitleAsCFString(getSTWindow(), & cfTitle) != 0) {
		return 0;
	}
	if (! CFStringGetCString( cfTitle, windowTitle, sizeof(windowTitle), kCFStringEncodingUTF8)) {
		windowTitle[0] = 0;
	}
	CFRelease(cfTitle);
	return windowTitle;
}

sqInt ioSetWindowLabelOfSize(void *lblIndex, sqInt sz) {
	char string[1024];
	if(sz > 1023) sz = 1023;
	if (sz > 0) {
		memcpy(string, lblIndex, sz);
		string[sz] = 0;
	} else {
		/* Empty string means reset to short image name */
		getShortImageNameWithEncoding(string,gCurrentVMEncoding);
	}
	SetWindowTitle(1, string);
	return 1;
}

sqInt ioIsWindowObscured(void) {
  /* not knowing any better just lie and pretend we're visible */
  return false;
}

sqInt makeMainWindow(void);
static sqInt ioSetFullScreenActual(sqInt fullScreen);

sqInt
ioSetFullScreen(sqInt fullScreen) {
        void *  giLocker;
		int return_value=0;
		if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return 0;
        giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
        if (giLocker != 0) {
            sqInt foo[4];
            foo[0] = 1;
            foo[1] = (sqInt) ioSetFullScreenActual;
            foo[2] = fullScreen;
            foo[3] = 0;
            ((sqInt (*) (void *)) giLocker)(foo);
            return_value = interpreterProxy->positive32BitIntegerFor(foo[3]);
        }
        return return_value;
}

static sqInt
ioSetFullScreenActual(sqInt fullScreen) {
    Rect                screen, workArea;
    int                 width, height, maxWidth, maxHeight;
    int                 oldWidth, oldHeight;
    static Rect			rememberOldLocation = {0,0,0,0};
    GDHandle            dominantGDevice;
	windowDescriptorBlock *	targetWindowBlock  = windowBlockFromIndex(1);
	extern Boolean gSqueakBrowserWasHeadlessButMadeFullScreen;
	extern Boolean gSqueakBrowserSubProcess;


	if (browserActiveAndDrawingContextOk()) {
		if (!gSqueakBrowserWasHeadlessButMadeFullScreen) {
			gSqueakBrowserWasHeadlessButMadeFullScreen = true;
			SetUpMenus();
			AdjustMenus();
		}
		sqShowWindowActual(1);
		if (targetWindowBlock->context) {  //Set context to NULL, if screen is same size as fullscreen we wouldn't get new context
			QDEndCGContext(GetWindowPort(targetWindowBlock->handle),&targetWindowBlock->context);
			targetWindowBlock->context = NULL;
		}
	}

	if ((targetWindowBlock == NULL) || (fullScreen && getFullScreenFlag() && !targetWindowBlock->isInvisible))
		return 0;

	dominantGDevice = getThatDominateGDevice(targetWindowBlock->handle);
    if (dominantGDevice == null) {
        success(false);
        return 0;
    }
    GetAvailableWindowPositioningBounds (dominantGDevice, &workArea);
    screen = (**dominantGDevice).gdRect;

    if (fullScreen) {

		GetWindowBounds(targetWindowBlock->handle, kWindowContentRgn, &rememberOldLocation);
		if (targetWindowBlock->isInvisible) {
			/* I.e. we're going straight to fullscreen */
			rememberOldLocation.top = workArea.top + 28;
			rememberOldLocation.left = workArea.left + 8;
			rememberOldLocation.bottom = (rememberOldLocation.bottom >= workArea.bottom-8) ? workArea.bottom-8 : rememberOldLocation.bottom;
			rememberOldLocation.right = (rememberOldLocation.right >= workArea.right-8) ? workArea.right-8 : rememberOldLocation.right;
		}

		if (gSqueakBrowserSubProcess) {
			ProcessSerialNumber psn = { 0, kCurrentProcess };
			ProcessInfoRec info;
			info.processName = NULL;
#if _LP64
			info.processAppRef = NULL;
#else
			info.processAppSpec = NULL;
#endif
			info.processInfoLength = sizeof(ProcessInfoRec);
			GetProcessInformation(&psn,&info);
			SetFrontProcess(&psn);
		}
		MenuBarHide();
		width  = screen.right - screen.left;
		height = (screen.bottom - screen.top);
		SetWindowBounds (targetWindowBlock->handle, kWindowContentRgn, &screen);
		setFullScreenFlag(true);

	} else {
		MenuBarRestore();

		if (gSqueakBrowserWasHeadlessButMadeFullScreen) {
			HideWindow(targetWindowBlock->handle);
			{
				ProcessSerialNumber psn;
				pid_t parent;
				OSStatus err;
				parent = getppid();
				if (parent != 1) {
					err = GetProcessForPID(parent,&psn);
					if(err == 0)
						SetFrontProcess(&psn);
				}
			}
		}


		if (EmptyRect(&rememberOldLocation)) {
			Rect newBounds;

			/* get old window size */
			width  = (unsigned) getSavedWindowSize() >> 16;
			height = getSavedWindowSize() & 0xFFFF;

			/* minimum size is 1 x 1 */
			width  = (width  > 0) ? width : 64;
			height = (height > 0) ? height : 64;

			workArea.top = workArea.top + 20; 	/* Cheat a bit, for my win title bar's space,
			 since we have to set bounds via ContentRgn */

			/* maximum size is working area less a bit of slop so the result
			 remains 'within' the screen' */
			maxWidth  = workArea.right - workArea.left;
			maxHeight = workArea.bottom - workArea.top;

			width  = (width <= (maxWidth-4)) ? width : maxWidth-4;
			height = (height <= (maxHeight-24)) ? height : maxHeight-24;	 /* Cheat a bit for the window title bar */

			newBounds.left = workArea.left + ((maxWidth - width) / 2);
			newBounds.top = workArea.top + ((maxHeight - height) / 2);
			newBounds.right = newBounds.left + width;
			newBounds.bottom = newBounds.top + height;

			SetWindowBounds (targetWindowBlock->handle, kWindowContentRgn, &newBounds);
		} else {
			SetWindowBounds (targetWindowBlock->handle, kWindowContentRgn, &rememberOldLocation);
		}
		setFullScreenFlag(false);
	}
	return 0;
}

void sqShowWindow(int windowIndex) {
        void *  giLocker;

		if (gSqueakHeadless && browserActiveAndDrawingContextOkAndNOTInFullScreenMode()) return;
        giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
        if (giLocker != 0) {
            sqInt foo[4];
            foo[0] = 1;
            foo[1] = (sqInt) sqShowWindowActual;
            foo[2] = windowIndex;
            foo[3] = 0;
            ((sqInt (*) (void *)) giLocker)(foo);
        }
}

static void sqShowWindowActual(int windowIndex){
	if (windowHandleFromIndex(windowIndex)) {
		ShowWindow( windowHandleFromIndex(windowIndex));
		windowBlockFromIndex(windowIndex)->isInvisible  = false;
	}
}

sqInt
ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB) {

	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return 1;
	ioShowDisplayOnWindow( (unsigned char*)  dispBitsIndex,  width,  height,  depth, affectedL,  affectedR,  affectedT,  affectedB, 1);
	return 1;
}

#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)

static const void *get_byte_pointer(void *bitmap)
{
    return (void *) bitmap;
}

static CGDataProviderDirectAccessCallbacks gProviderCallbacks = {
    get_byte_pointer,
    NULL,
    NULL,
    NULL
};

static void * copy124BitsTheHardWay(unsigned int* dispBitsIndex, int width, int height, int depth, int desiredDepth,
	int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex, int *pitch);

sqInt
ioShowDisplayOnWindow(
	unsigned char*  dispBitsIndex, sqInt width, sqInt height, sqInt depth,
	sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB, sqInt windowIndex) {

	static CGColorSpaceRef colorspace = NULL;
	extern CGContextRef SharedBrowserBitMapContextRef;
	extern SqueakSharedMemoryBlock *SharedMemoryBlock;
	extern int SharedBrowserBitMapLength;

	int 		pitch;
	CGImageRef image;
	CGRect		clip;
	windowDescriptorBlock *targetWindowBlock = windowBlockFromIndex(windowIndex);
	CGDataProviderRef provider;

	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return 1;

	if (colorspace == NULL) {
			// Get the Systems Profile for the main display
		CMProfileRef sysprof = NULL;
		if (CMGetSystemProfile(&sysprof) == noErr) {
			// Create a colorspace with the systems profile
			colorspace = CGColorSpaceCreateWithPlatformColorSpace(sysprof);
			CMCloseProfile(sysprof);
		} else
			colorspace = CGColorSpaceCreateDeviceRGB();
	}

	if (targetWindowBlock == NULL) {
		extern Boolean gSqueakExplicitWindowOpenNeeded;
		if (gSqueakExplicitWindowOpenNeeded || (windowIndex != 1))
			return 0;
		makeMainWindow();
		targetWindowBlock = windowBlockFromIndex(windowIndex);
	}


	if (affectedL < 0) affectedL = 0;
	if (affectedT < 0) affectedT = 0;
	if (affectedR > width) affectedR = width;
	if (affectedB > height) affectedB = height;

	if ((targetWindowBlock->handle == nil) || ((affectedR - affectedL) <= 0) || ((affectedB - affectedT) <= 0)){
            return 0;
	}

	if (depth > 0 && depth <= 16) {
		dispBitsIndex = copy124BitsTheHardWay((unsigned int *) dispBitsIndex, width, height, depth, 32, affectedL, affectedR, affectedT,  affectedB,  windowIndex, &pitch);
		depth = 32;
	} else {
		pitch = bytesPerLine(width, depth);
	}

	provider = CGDataProviderCreateDirectAccess((void*)dispBitsIndex
				+ pitch*affectedT
				+ affectedL*(depth==32 ? 4 : 2),
				pitch * (affectedB-affectedT)-affectedL*(depth==32 ? 4 : 2),
				&gProviderCallbacks);
	image = CGImageCreate( affectedR-affectedL, affectedB-affectedT, depth==32 ? 8 : 5 /* bitsPerComponent */,
				depth /* bitsPerPixel */,
#ifdef __BIG_ENDIAN__
				pitch, colorspace, kCGImageAlphaNoneSkipFirst, provider, NULL, 0, kCGRenderingIntentDefault);
#else
				pitch, colorspace, kCGImageAlphaNoneSkipFirst | (depth==32 ? kCGBitmapByteOrder32Host : kCGBitmapByteOrder16Host), provider, NULL, 0, kCGRenderingIntentDefault);
#endif


	clip = CGRectMake(affectedL,height-affectedB, affectedR-affectedL, affectedB-affectedT);

	if (targetWindowBlock->isInvisible) {
		sqShowWindow(windowIndex);
	}

		if (targetWindowBlock->context == nil || (targetWindowBlock->width != width || targetWindowBlock->height  != height)) {
			if (targetWindowBlock->context) {
				QDEndCGContext(GetWindowPort(targetWindowBlock->handle),&targetWindowBlock->context);
				//CGContextRelease(targetWindowBlock->context);
			}
			//CreateCGContextForPort(GetWindowPort(targetWindowBlock->handle),&targetWindowBlock->context);
			QDBeginCGContext(GetWindowPort(targetWindowBlock->handle),&targetWindowBlock->context);
			targetWindowBlock->sync = false;

			targetWindowBlock->width = width;
			targetWindowBlock->height = height;
			DPRINTF((stderr,"targetWindow index %i, width %i height %i\n",windowIndex,width,height));
	}


	if (targetWindowBlock->sync) {
			CGRect	clip2;
			Rect	portRect;
			int		w,h;

			GetPortBounds(GetWindowPort(windowHandleFromIndex(windowIndex)),&portRect);
            w =  portRect.right -  portRect.left;
            h =  portRect.bottom - portRect.top;
			clip2 = CGRectMake(0,0, w, h);
			CGContextClipToRect(targetWindowBlock->context, clip2);
	}

	/* Draw the image to the Core Graphics context */
	if (provider && image) {

		if (browserActiveAndDrawingContextOkAndNOTInFullScreenMode() ) {
			static pthread_mutex_t SleepLock;
			static pthread_cond_t SleepLockCondition;
			struct timespec tspec;
			static bool mutexTimerStartNeeded = true;
			int err,counter = 0;

			if (mutexTimerStartNeeded) {
				mutexTimerStartNeeded = false;
				pthread_mutex_init(&SleepLock, NULL);
				pthread_cond_init(&SleepLockCondition,NULL);
			}

			while (SharedMemoryBlock->written && counter++ < 100) {

				tspec.tv_sec=  10 / 1000;
				tspec.tv_nsec= (10 % 1000)*1000000;

				err = pthread_mutex_lock(&SleepLock);
				err = pthread_cond_timedwait_relative_np(&SleepLockCondition,&SleepLock,&tspec);
				err = pthread_mutex_unlock(&SleepLock);
			}

			CGContextDrawImage(SharedBrowserBitMapContextRef, clip, image);
			CGContextFlush(SharedBrowserBitMapContextRef);
			SharedMemoryBlock->top = affectedT;
			SharedMemoryBlock->left = affectedL;
			SharedMemoryBlock->bottom = affectedB;
			SharedMemoryBlock->right = affectedR;
			SharedMemoryBlock->written = 1;
			msync(SharedMemoryBlock,SharedBrowserBitMapLength,MS_SYNC);

	} else
			if (targetWindowBlock->context)
		CGContextDrawImage(targetWindowBlock->context, clip, image);
	}

	CGImageRelease(image);
	CGDataProviderRelease(provider);

	if (browserActiveAndDrawingContextOkAndNOTInFullScreenMode())
		return 1;

	{
			extern	long	gSqueakUIFlushPrimaryDeferNMilliseconds;
			long now = ioMSecs() - targetWindowBlock->rememberTicker;

		if (((now >= gSqueakUIFlushPrimaryDeferNMilliseconds) || (now < 0))) {
			CGContextFlush(targetWindowBlock->context);
			targetWindowBlock->dirty = 0;
			targetWindowBlock->rememberTicker = ioMSecs();
		} else {
			if (targetWindowBlock->sync)
				CGContextSynchronize(targetWindowBlock->context);
			targetWindowBlock->dirty = 1;
		}
	}

	return 1;
}


static void *
copy124BitsTheHardWay(unsigned int* dispBitsIndex, int width, int height, int depth, int desiredDepth,
	int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex, int *pitch)
{
#if _LP64
	error("copy124BitsTheHardWay unimplemented because GetGWorldPixMap is unavailable");
#else

	static GWorldPtr offscreenGWorld = nil;
	QDErr error;
	static 		RgnHandle maskRect = nil;
	static Rect	dstRect = { 0, 0, 0, 0 };
	static Rect	srcRect = { 0, 0, 0, 0 };
	static int	rememberWidth=0,rememberHeight=0,rememberDepth=0,lastWindowIndex=0;

	if (maskRect == nil)
		maskRect = NewRgn();

	(*stPixMap)->baseAddr = (void *) dispBitsIndex;

	if (!((lastWindowIndex == windowIndex) && (rememberHeight == height) && (rememberWidth == width) && (rememberDepth == depth))) {
			lastWindowIndex = windowIndex;
            rememberWidth  = srcRect.right = dstRect.right = width;
            rememberHeight = srcRect.bottom = dstRect.bottom = height;
			if (offscreenGWorld != nil)
				DisposeGWorld(offscreenGWorld);

#ifdef __BIG_ENDIAN__
			error	= NewGWorld (&offscreenGWorld,desiredDepth,&dstRect,0,0,keepLocal);
#else
			error	= NewGWorld (&offscreenGWorld,desiredDepth,&dstRect,0,0,keepLocal | kNativeEndianPixMap);
#endif
			LockPixels(GetGWorldPixMap(offscreenGWorld));

            /* Note: top three bits of rowBytes indicate this is a PixMap, not a BitMap */
            (*stPixMap)->rowBytes = (((((width * depth) + 31) / 32) * 4) & 0x1FFF) | 0x8000;
            (*stPixMap)->bounds = srcRect;
            rememberDepth = (*stPixMap)->pixelSize = depth;

            if (depth<=8) { /*Duane Maxwell <dmaxwell@exobox.com> fix cmpSize Sept 18,2000 */
                (*stPixMap)->cmpSize = depth;
                (*stPixMap)->cmpCount = 1;
            } else if (depth==16) {
                (*stPixMap)->cmpSize = 5;
                (*stPixMap)->cmpCount = 3;
            } else if (depth==32) {
                (*stPixMap)->cmpSize = 8;
                (*stPixMap)->cmpCount = 3;
            }
        }

	/* create a mask region so that only the affected rectangle is copied */
	SetRectRgn(maskRect, affectedL, affectedT, affectedR, affectedB);
	CopyBits((BitMap *) *stPixMap,
			 (BitMap *)*GetGWorldPixMap(offscreenGWorld),
			 &srcRect, &dstRect, srcCopy, maskRect);
	*pitch = GetPixRowBytes(GetGWorldPixMap(offscreenGWorld));
	return GetPixBaseAddr(GetGWorldPixMap(offscreenGWorld));
#endif /* _LP64 */
}

void SetUpPixmap(void) {
	int i, r, g, b;

	stColorTable = (CTabHandle) NewHandle(sizeof(ColorTable) + (256 * sizeof(ColorSpec)));
	(*stColorTable)->ctSeed = GetCTSeed();
	(*stColorTable)->ctFlags = 0;
	(*stColorTable)->ctSize = 255;

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
	for (r = 0; r < 6; r++) {
		for (g = 0; g < 6; g++) {
			for (b = 0; b < 6; b++) {
				i = 40 + ((36 * r) + (6 * b) + g);
				if (i > 255) error("index out of range in color table compuation");
				SetColorEntry(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
			}
		}
	}

	stPixMap = NewPixMap();
	(*stPixMap)->pixelType = 0; /* chunky */
	(*stPixMap)->cmpCount = 1;
        DisposeCTable((*stPixMap)->pmTable);
	(*stPixMap)->pmTable = stColorTable;
}

static void SetColorEntry(int index, int red, int green, int blue) {
	(*stColorTable)->ctTable[index].value = index;
	(*stColorTable)->ctTable[index].rgb.red = red;
	(*stColorTable)->ctTable[index].rgb.green = green;
	(*stColorTable)->ctTable[index].rgb.blue = blue;
}

void FreePixmap(void) {
	extern Boolean gSqueakBrowserWasHeadlessButMadeFullScreen;

	if (gSqueakHeadless && !gSqueakBrowserWasHeadlessButMadeFullScreen) return;
	if (stPixMap != nil) {
		DisposePixMap(stPixMap);
		stPixMap = nil;
	}

	if (stColorTable != nil) {
		//JMM disposepixmap does this DisposeHandle((void *) stColorTable);
		stColorTable = nil;
	}
}

static void
displayReconfigurationCallback(	CGDirectDisplayID display,
								CGDisplayChangeSummaryFlags flags,
								void *userInfo)
{
	if (flags & (kCGDisplayRemoveFlag | kCGDisplayDisabledFlag)) {
		Rect dispRect;
		CGPoint centre;
		CGDirectDisplayID displays[4];
		uint32_t nDisplays;
		/* Use CGGetDisplaysWithPoint with the centre of the Smalltalk window.
		 * If we get none back we need to move to the main monitor.  If so,
		 * ioSetFullScreenActual does most of the work.  All we need to do in
		 * addition is force a screen update and currently I have no idea. eem.
		 */
		GetWindowBounds(getSTWindow(), kWindowContentRgn, &dispRect);
		centre.x = (dispRect.left + dispRect.right) / 2;
		centre.y = (dispRect.top + dispRect.bottom) / 2;
		CGGetDisplaysWithPoint(centre, 4, displays, &nDisplays);
		if (!nDisplays) {
			windowDescriptorBlock *squeakWB  = windowBlockFromIndex(1);
			ioSetFullScreenActual(getFullScreenFlag());
		}
	}
	postFullScreenUpdate();
}

sqInt
makeMainWindow(void) {
	WindowPtr window;
	char	shortImageName[256];
	int width,height;
	windowDescriptorBlock *windowBlock;
	extern UInt32 gSqueakWindowType,gSqueakWindowAttributes;
	extern Boolean gSqueakWindowHasTitle;

	/* get old window size */
	width  = (unsigned) getSavedWindowSize() >> 16;
	height = getSavedWindowSize() & 0xFFFF;

	window = SetUpWindow(44, 8, 44+height, 8+width,gSqueakWindowType,gSqueakWindowAttributes);
	windowBlock = AddWindowBlock();
	windowBlock-> handle = (wHandleType) window;
	windowBlock->isInvisible = !MacIsWindowVisible(window);

	ioLoadFunctionFrom(NULL, "DropPlugin");

	if (gSqueakWindowHasTitle) {
		getShortImageNameWithEncoding(shortImageName,gCurrentVMEncoding);
		SetWindowTitle(1,shortImageName);
	}

	CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, 0);
	ioSetFullScreenActual(getFullScreenFlag());
	SetUpCarbonEventForWindowIndex(1);
	QDBeginCGContext(GetWindowPort(windowBlock->handle),&windowBlock->context);

	Rect portRect;
	int	w,h;

	GetPortBounds(GetWindowPort(windowBlock->handle),&portRect);
	w =  portRect.right -  portRect.left;
	h =  portRect.bottom - portRect.top;
	setSavedWindowSize((w << 16) |(h & 0xFFFF));
	windowBlock->width = w;
	windowBlock->height = h;

	//SetupSurface(1);
	return (int) window;
}

WindowPtr
SetUpWindow(int t,int l,int b, int r, UInt32 windowType, UInt32 windowAttributes) {
	Rect windowBounds;
	OSStatus err;
	WindowPtr   createdWindow;
	windowBounds.left = l;
	windowBounds.top = t;
	windowBounds.right = r;
	windowBounds.bottom = b;
	err = CreateNewWindow(windowType,windowAttributes,&windowBounds,&createdWindow);
	return createdWindow;
}

void SetWindowTitle(int windowIndex,char *title) {
	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return;

    if (windowIndex == 1) {
		int sz = strlen(title);
		if (sz > 1023) sz = 1023;
		memcpy(windowTitle, title, sz);
		windowTitle[sz] = 0;
	}

	CFStringRef tempTitle = CFStringCreateWithCString(NULL, title, kCFStringEncodingMacRoman);
	if (windowHandleFromIndex(windowIndex))
		SetWindowTitleWithCFString(windowHandleFromIndex(windowIndex), tempTitle);
	CFRelease(tempTitle);
}

sqInt ioForceDisplayUpdate(void) { /* do nothing on a Mac */ return 0; }

sqInt
ioHasDisplayDepth(sqInt depth) {
	/* Return true if this platform supports the given color display depth. */

	switch (depth) {
	case 1:
	case 2:
	case 4:
	case 8:
	case 16:
	case 32:
		return true;
	}
	return false;
}

double
ioSceenScaleFactor(void) {
    return 1.0;
}

sqInt
ioScreenDepth(void) {
    GDHandle mainDevice;

	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return 32;
	mainDevice = getThatDominateGDevice(getSTWindow());
    if (mainDevice == null)
        return 8;

    return (*(*mainDevice)->gdPMap)->pixelSize;
}

sqInt
ioScreenSize(void) {
	int w, h;
    Rect portRect;
    extern Boolean gSqueakExplicitWindowOpenNeeded;

	if (gSqueakHeadless && !browserActiveAndDrawingContextOk())
		return getSavedWindowSize();

	if (browserActiveAndDrawingContextOkAndNOTInFullScreenMode())
		return browserGetWindowSize();

	w  = (unsigned) getSavedWindowSize() >> 16;
	h= getSavedWindowSize() & 0xFFFF;

	if (getSTWindow() == NULL && !gSqueakExplicitWindowOpenNeeded) {
		makeMainWindow();
	}

	if (getSTWindow() != nil) {
            GetPortBounds(GetWindowPort(getSTWindow()),&portRect);
            w =  portRect.right -  portRect.left;
            h =  portRect.bottom - portRect.top;
	}

	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

sqInt
ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY) {
	/* Old version; forward to new version. */
	ioSetCursorWithMask(cursorBitsIndex, nil, offsetX, offsetY);
	return 0;
}

Cursor macCursor;

sqInt
ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY) {
	/* Set the 16x16 cursor bitmap. If cursorMaskIndex is nil, then make the mask the same as
	   the cursor bitmap. If not, then mask and cursor bits combined determine how cursor is
	   displayed:
			mask	cursor	effect
			 0		  0		transparent (underlying pixel shows through)
			 1		  1		opaque black
			 1		  0		opaque white
			 0		  1		invert the underlying pixel
	*/
	int i;
	extern Boolean biggerCursorActive;

	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return 0;
	biggerCursorActive = false;

	if (cursorMaskIndex == 0) {
		for (i = 0; i < 16; i++) {
			macCursor.data[i] = CFSwapInt16BigToHost((short)(checkedLongAt(cursorBitsIndex + (4 * i)) >> 16)) & 0xFFFF;
			macCursor.mask[i] = CFSwapInt16BigToHost((short)(checkedLongAt(cursorBitsIndex + (4 * i)) >> 16)) & 0xFFFF;
		}
	} else {
		for (i = 0; i < 16; i++) {
			macCursor.data[i] = CFSwapInt16BigToHost((short)(checkedLongAt(cursorBitsIndex + (4 * i)) >> 16)) & 0xFFFF;
			macCursor.mask[i] = CFSwapInt16BigToHost((short)(checkedLongAt(cursorMaskIndex + (4 * i)) >> 16)) & 0xFFFF;
		}
	}

	/* Squeak hotspot offsets are negative; Mac's are positive */
	macCursor.hotSpot.h = -offsetX;
	macCursor.hotSpot.v = -offsetY;
	if (browserActiveAndDrawingContextOkAndNOTInFullScreenMode())
		browserSetCursor(&macCursor);
	if (!gSqueakHeadless || browserActiveAndDrawingContextOkAndInFullScreenMode()) {
		gSqueakHasCursor = true;
		SetCursor(&macCursor);
	}
	return 0;
}

// requestFlags bit values in VideoRequestRec (example use: 1<<kAbsoluteRequestBit)
enum {
	kBitDepthPriorityBit		= 0,	// Bit depth setting has priority over resolution
	kAbsoluteRequestBit			= 1,	// Available setting must match request
	kShallowDepthBit			= 2,	// Match bit depth less than or equal to request
	kMaximizeResBit				= 3,	// Match screen resolution greater than or equal to request
	kAllValidModesBit			= 4		// Match display with valid timing modes (may include modes which are not marked as safe)
};

// availFlags bit values in VideoRequestRec (example use: 1<<kModeValidNotSafeBit)
enum {
	kModeValidNotSafeBit		= 0		//  Available timing mode is valid but not safe (requires user confirmation of switch)
};

// video request structure
struct VideoRequestRec	{
	GDHandle		screenDevice;		// <in/out>	nil will force search of best device, otherwise search this device only
	short			reqBitDepth;		// <in>		requested bit depth
	short			availBitDepth;		// <out>	available bit depth
	unsigned long	reqHorizontal;		// <in>		requested horizontal resolution
	unsigned long	reqVertical;		// <in>		requested vertical resolution
	unsigned long	availHorizontal;	// <out>	available horizontal resolution
	unsigned long	availVertical;		// <out>	available vertical resolution
	unsigned long	requestFlags;		// <in>		request flags
	unsigned long	availFlags;			// <out>	available mode flags
	unsigned long	displayMode;		// <out>	mode used to set the screen resolution
	unsigned long	depthMode;			// <out>	mode used to set the depth
	VDSwitchInfoRec	switchInfo;			// <out>	DM2.0 uses this rather than displayMode/depthMode combo
};
typedef struct VideoRequestRec VideoRequestRec;
typedef struct VideoRequestRec *VideoRequestRecPtr;

struct DepthInfo {
	VDSwitchInfoRec			depthSwitchInfo;			// This is the switch mode to choose this timing/depth
	VPBlock					depthVPBlock;				// VPBlock (including size, depth and format)
};
typedef struct DepthInfo DepthInfo;

struct ListIteratorDataRec {
	VDTimingInfoRec			displayModeTimingInfo;		// Contains timing flags and such
	unsigned long			depthBlockCount;			// How many depths available for a particular timing
	DepthInfo				*depthBlocks;				// Array of DepthInfo
};
typedef struct ListIteratorDataRec ListIteratorDataRec;
void GetRequestTheDM2Way (		VideoRequestRecPtr requestRecPtr,
								GDHandle walkDevice,
								DMDisplayModeListIteratorUPP myModeIteratorProc,
								DMListIndexType theDisplayModeCount,
								DMListType *theDisplayModeList);

pascal void ModeListIterator (	void *userData,
								DMListIndexType itemIndex,
								DMDisplayModeListEntryPtr displaymodeInfo);

Boolean FindBestMatch (			VideoRequestRecPtr requestRecPtr,
								short bitDepth,
								unsigned long horizontal,
								unsigned long vertical);

/*#	MacOSª Sample Code
#
#	Written by: Eric Anderson
#	 email: eric3@apple.com
#
#	Display Manager sample code
#	RequestVideo demonstrates the usage of the Display Manager introduced
#	with the PowerMacs and integrated into the system under System 7.5. With
#	the RequestVideo sample code library, developers will be able to explore
#	the Display Manager API by changing bit depth and screen resolution on
#	multisync displays on built-in, NuBus, and PCI based video. Display Manager 1.0
#	is built into the Systems included with the first PowerMacs up through System 7.5.
#	Display Manager 2.0 is included with the release of the new PCI based PowerMacs,
#	and will be included in post 7.5 System Software releases.
*/

pascal void ModeListIterator(void *userData, DMListIndexType itemIndex, DMDisplayModeListEntryPtr displaymodeInfo)
{
#pragma unused(itemIndex)
	unsigned long			depthCount;
	unsigned long			iCount;
	ListIteratorDataRec		*myIterateData		= (ListIteratorDataRec*) userData;
	DepthInfo				*myDepthInfo;

	// set user data in a round about way
	myIterateData->displayModeTimingInfo		= *displaymodeInfo->displayModeTimingInfo;

	// now get the DMDepthInfo info into memory we own
	depthCount = displaymodeInfo->displayModeDepthBlockInfo->depthBlockCount;
	myDepthInfo = (DepthInfo*)NewPtrClear(depthCount * sizeof(DepthInfo));

	// set the info for the caller
	myIterateData->depthBlockCount = depthCount;
	myIterateData->depthBlocks = myDepthInfo;

	// and fill out all the entries
	if (depthCount) for (iCount=0; iCount < depthCount; iCount++)
	{
		myDepthInfo[iCount].depthSwitchInfo =
			*displaymodeInfo->displayModeDepthBlockInfo->depthVPBlock[iCount].depthSwitchInfo;
		myDepthInfo[iCount].depthVPBlock =
			*displaymodeInfo->displayModeDepthBlockInfo->depthVPBlock[iCount].depthVPBlock;
	}
}

void GetRequestTheDM2Way (	VideoRequestRecPtr requestRecPtr,
							GDHandle walkDevice,
							DMDisplayModeListIteratorUPP myModeIteratorProc,
							DMListIndexType theDisplayModeCount,
							DMListType *theDisplayModeList)
{
	DMListIndexType			jCount;
	DMListIndexType			kCount;
	ListIteratorDataRec		searchData;

	searchData.depthBlocks = nil;
	// get the mode lists for this GDevice
	for (jCount=0; jCount<theDisplayModeCount; jCount++)		// get info on all the resolution timings
	{
		DMGetIndexedDisplayModeFromList(*theDisplayModeList, jCount, 0, myModeIteratorProc, &searchData);

		// for all the depths for this resolution timing (mode)...
		if (searchData.depthBlockCount) for (kCount = 0; kCount < searchData.depthBlockCount; kCount++)
		{
			// only if the mode is valid and is safe or we override it with the kAllValidModesBit request flag
			if	(	searchData.displayModeTimingInfo.csTimingFlags & 1<<kModeValid &&
					(	searchData.displayModeTimingInfo.csTimingFlags & 1<<kModeSafe ||
						requestRecPtr->requestFlags & 1<<kAllValidModesBit
					)
				)
			{
				if (FindBestMatch (	requestRecPtr,
									searchData.depthBlocks[kCount].depthVPBlock.vpPixelSize,
									searchData.depthBlocks[kCount].depthVPBlock.vpBounds.right,
									searchData.depthBlocks[kCount].depthVPBlock.vpBounds.bottom))
				{
					requestRecPtr->screenDevice = walkDevice;
					requestRecPtr->availBitDepth = searchData.depthBlocks[kCount].depthVPBlock.vpPixelSize;
					requestRecPtr->availHorizontal = searchData.depthBlocks[kCount].depthVPBlock.vpBounds.right;
					requestRecPtr->availVertical = searchData.depthBlocks[kCount].depthVPBlock.vpBounds.bottom;

					// now set the important info for DM to set the display
					requestRecPtr->depthMode = searchData.depthBlocks[kCount].depthSwitchInfo.csMode;
					requestRecPtr->displayMode = searchData.depthBlocks[kCount].depthSwitchInfo.csData;
					requestRecPtr->switchInfo = searchData.depthBlocks[kCount].depthSwitchInfo;
					if (searchData.displayModeTimingInfo.csTimingFlags & 1<<kModeSafe)
						requestRecPtr->availFlags = 0;							// mode safe
					else requestRecPtr->availFlags = 1<<kModeValidNotSafeBit;	// mode valid but not safe, requires user validation of mode switch

				}
			}

		}

		if (searchData.depthBlocks)
		{
			DisposePtr ((Ptr)searchData.depthBlocks);	// toss for this timing mode of this gdevice
			searchData.depthBlocks = nil;				// init it just so we know
		}
	}
}

Boolean FindBestMatch (VideoRequestRecPtr requestRecPtr, short bitDepth, unsigned long horizontal, unsigned long vertical)
{
	// ¥¥ do the big comparison ¥¥
	// first time only if	(no mode yet) and
	//						(bounds are greater/equal or kMaximizeRes not set) and
	//						(depth is less/equal or kShallowDepth not set) and
	//						(request match or kAbsoluteRequest not set)
	if	(	0 == requestRecPtr->displayMode
			&&
			(	(horizontal >= requestRecPtr->reqHorizontal &&
				vertical >= requestRecPtr->reqVertical)
				||
				!(requestRecPtr->requestFlags & 1<<kMaximizeResBit)
			)
			&&
			(	bitDepth <= requestRecPtr->reqBitDepth ||
				!(requestRecPtr->requestFlags & 1<<kShallowDepthBit)
			)
			&&
			(	(horizontal == requestRecPtr->reqHorizontal &&
				vertical == requestRecPtr->reqVertical &&
				bitDepth == requestRecPtr->reqBitDepth)
				||
				!(requestRecPtr->requestFlags & 1<<kAbsoluteRequestBit)
			)
		)
		{
			// go ahead and set the new values
			return (true);
		}
	else	// can we do better than last time?
	{
		// if	(kBitDepthPriority set and avail not equal req) and
		//		((depth is greater avail and depth is less/equal req) or kShallowDepth not set) and
		//		(avail depth less reqested and new greater avail)
		//		(request match or kAbsoluteRequest not set)
		if	(	(	requestRecPtr->requestFlags & 1<<kBitDepthPriorityBit &&
					requestRecPtr->availBitDepth != requestRecPtr->reqBitDepth
				)
				&&
				(	(	bitDepth > requestRecPtr->availBitDepth &&
						bitDepth <= requestRecPtr->reqBitDepth
					)
					||
					!(requestRecPtr->requestFlags & 1<<kShallowDepthBit)
				)
				&&
				(	requestRecPtr->availBitDepth < requestRecPtr->reqBitDepth &&
					bitDepth > requestRecPtr->availBitDepth
				)
				&&
				(	(horizontal == requestRecPtr->reqHorizontal &&
					vertical == requestRecPtr->reqVertical &&
					bitDepth == requestRecPtr->reqBitDepth)
					||
					!(requestRecPtr->requestFlags & 1<<kAbsoluteRequestBit)
				)
			)
		{
			// go ahead and set the new values
			return (true);
		}
		else
		{
			// match resolution: minimize Æh & Æv
			if	(	labs((long)(requestRecPtr->reqHorizontal - horizontal)) <=
					labs((long)(requestRecPtr->reqHorizontal - requestRecPtr->availHorizontal)) &&
					labs((long)(requestRecPtr->reqVertical - vertical)) <=
					labs((long)(requestRecPtr->reqVertical - requestRecPtr->availVertical))
				)
			{
				// now we have a smaller or equal delta
				//	if (h or v greater/equal to request or kMaximizeRes not set)
				if (	(horizontal >= requestRecPtr->reqHorizontal &&
						vertical >= requestRecPtr->reqVertical)
						||
						!(requestRecPtr->requestFlags & 1<<kMaximizeResBit)
					)
				{
					// if	(depth is equal or kBitDepthPriority not set) and
					//		(depth is less/equal or kShallowDepth not set) and
					//		([h or v not equal] or [avail depth less reqested and new greater avail] or depth equal avail) and
					//		(request match or kAbsoluteRequest not set)
					if	(	(	requestRecPtr->availBitDepth == bitDepth ||
								!(requestRecPtr->requestFlags & 1<<kBitDepthPriorityBit)
							)
							&&
							(	bitDepth <= requestRecPtr->reqBitDepth ||
								!(requestRecPtr->requestFlags & 1<<kShallowDepthBit)
							)
							&&
							(	(requestRecPtr->availHorizontal != horizontal ||
								requestRecPtr->availVertical != vertical)
								||
								(requestRecPtr->availBitDepth < requestRecPtr->reqBitDepth &&
								bitDepth > requestRecPtr->availBitDepth)
								||
								(bitDepth == requestRecPtr->reqBitDepth)
							)
							&&
							(	(horizontal == requestRecPtr->reqHorizontal &&
								vertical == requestRecPtr->reqVertical &&
								bitDepth == requestRecPtr->reqBitDepth)
								||
								!(requestRecPtr->requestFlags & 1<<kAbsoluteRequestBit)
							)
						)
					{
						// go ahead and set the new values
						return (true);
					}
				}
			}
		}
	}
	return false;
}

sqInt
ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag) {
	/* Set the window to the given width, height, and color depth. Put the window
	   into the full screen mode specified by fullscreenFlag. */

    GDHandle		dominantGDevice;
	CGDirectDisplayID	mainDominateWindow;
    CFDictionaryRef mode;
	CGDisplayErr err;
	boolean_t exactMatch;

	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return 0;

#if !_LP64
	dominantGDevice = getThatDominateGDevice(getSTWindow());
    if (dominantGDevice == null) {
		success(false);
		return 0;
	}


	mainDominateWindow = QDGetCGDirectDisplayID(dominantGDevice);

	mode = CGDisplayBestModeForParameters(mainDominateWindow, depth,  width, height,  &exactMatch);
	err = CGDisplaySwitchToMode(mainDominateWindow, mode);
	if ( err != CGDisplayNoErr ) {
		return 0;
	}
#endif /* !_LP64 */

	ioSetFullScreen(fullscreenFlag);

    return 1;
}

GDHandle
getThatDominateGDevice(WindowPtr window) {
	GDHandle		dominantGDevice=NULL;

	if (!window) return NULL;

	GetWindowGreatestAreaDevice((WindowRef) window,kWindowContentRgn,&dominantGDevice,NULL);
	return dominantGDevice;
}
