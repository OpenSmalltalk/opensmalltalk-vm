/****************************************************************************
*   PROJECT: Mac window, memory, keyboard interface.
*   FILE:    sqMacWindow.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:  $Id: sqMacWindow.c,v 1.29 2003/11/20 01:35:47 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Feb 26th, 2002, JMM - use carbon get dominate device 
*  Apr  17th, 2002, JMM Use accessors for VM variables.
*  May 5th, 2002, JMM cleanup for building as NS plugin
 3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
 3.5.1b5 June 25th, 2003 JMM fix memory leak on color table free, pull preferences from Info.plist under os-x
*****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

#include "sq.h"
#include "sqMacUIConstants.h"
#include "sqMacWindow.h"
#include "sqMacFileLogic.h"
#include "sqmacUIEvents.h"
#include "sqMacUIMenuBar.h"

#if !TARGET_API_MAC_CARBON
    inline pascal long InvalWindowRect(WindowRef  window,  const Rect * bounds) {InvalRect (bounds);}
#endif

/*** Variables -- Imported from Virtual Machine ***/
extern int getFullScreenFlag();    /* set from header when image file is loaded */
extern int setFullScreenFlag(int value);    /* set from header when image file is loaded */
extern int getSavedWindowSize();   /* set from header when image file is loaded */
extern int setSavedWindowSize(int value);   /* set from header when image file is loaded */

/*** Variables -- Mac Related ***/
CTabHandle	stColorTable = nil;
PixMapHandle	stPixMap = nil;
WindowPtr	stWindow = nil;
Boolean  	gWindowsIsInvisible=true;

/*** Functions ***/
void SetColorEntry(int index, int red, int green, int blue);
GDHandle getDominateDevice(WindowPtr theWindow,Rect *windRect);
void getDominateGDeviceRect(GDHandle dominantGDevice,Rect *dGDRect,Boolean forgetMenuBar);

WindowPtr getSTWindow(void) {
    return stWindow;
}

#ifndef BROWSERPLUGIN
#if TARGET_API_MAC_CARBON
extern struct VirtualMachine *interpreterProxy;
int ioSetFullScreenActual(int fullScreen);
void fetchPrefrencesForWindow(int *windowType,int *windowAttributes);
void SetupSurface(void);

int ioSetFullScreen(int fullScreen) {
        int giLocker,return_value=0;
        giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
        if (giLocker != 0) {
            long *foo;
            foo = malloc(sizeof(long)*4);
            foo[0] = 1;
            foo[1] = (int) ioSetFullScreenActual;
            foo[2] = fullScreen;
            foo[3] = 0;
            ((int (*) (void *)) giLocker)(foo);
            return_value = interpreterProxy->positive32BitIntegerFor(foo[3]);
            free(foo);
        }
        return return_value;
}

int ioSetFullScreenActual(int fullScreen) {
#else
int ioSetFullScreen(int fullScreen) {
#endif
    Rect                screen,portRect,ignore;
    int                 width, height, maxWidth, maxHeight;
    int                 oldWidth, oldHeight;
    static Rect		rememberOldLocation = {44,8,0,0};		
    GDHandle            dominantGDevice;

#if TARGET_API_MAC_CARBON
    GetWindowGreatestAreaDevice(stWindow,kWindowContentRgn,&dominantGDevice,&ignore); 
    if (dominantGDevice == null) {
        success(false);
        return 0;
    }
    screen = (**dominantGDevice).gdRect;
#else
    dominantGDevice = getDominateDevice(stWindow,&ignore);
    if (dominantGDevice == null) {
        success(false);
        return 0;
    }
    getDominateGDeviceRect(dominantGDevice,&screen,true);
#endif  
        
    if (fullScreen) {
		GetPortBounds(GetWindowPort(stWindow),&rememberOldLocation);
		LocalToGlobal((Point*) &rememberOldLocation.top);
		LocalToGlobal((Point*) &rememberOldLocation.bottom);
		MenuBarHide();
		GetPortBounds(GetWindowPort(stWindow),&portRect);
		oldWidth =  portRect.right -  portRect.left;
		oldHeight =  portRect.bottom -  portRect.top;
		width  = screen.right - screen.left; 
		height = (screen.bottom - screen.top);
		if ((oldWidth < width) || (oldHeight < height)) {
			/* save old size if it wasn't already full-screen */ 
			setSavedWindowSize((oldWidth << 16) + (oldHeight & 0xFFFF));
		}
		MoveWindow(stWindow, screen.left, screen.top, true);
		SizeWindow(stWindow, width, height, true);
		setFullScreenFlag(true);
	} else {
		MenuBarRestore();

		/* get old window size */
		width  = (unsigned) getSavedWindowSize() >> 16;
		height = getSavedWindowSize() & 0xFFFF;

		/* minimum size is 64 x 64 */
		width  = (width  > 64) ?  width : 64;
		height = (height > 64) ? height : 64;

		/* maximum size is screen size inset slightly */
		maxWidth  = (screen.right  - screen.left) - 16;
		maxHeight = (screen.bottom - screen.top)  - 52;
		width  = (width  <= maxWidth)  ?  width : maxWidth;
		height = (height <= maxHeight) ? height : maxHeight;
		MoveWindow(stWindow, rememberOldLocation.left, rememberOldLocation.top, true);
		SizeWindow(stWindow, width, height, true);
		setFullScreenFlag(false);
	}
}

#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)
#if !TARGET_API_MAC_CARBON
int ioShowDisplay(
	int dispBitsIndex, int width, int height, int depth,
	int affectedL, int affectedR, int affectedT, int affectedB) {

        CGrafPtr	windowPort;
	static 		RgnHandle maskRect = nil;
	static Rect	dstRect = { 0, 0, 0, 0 };
	static Rect	srcRect = { 0, 0, 0, 0 };
        static int	rememberWidth=0,rememberHeight=0,rememberDepth=0;
        
	if (stWindow == nil) {
            return;
	}
    
        if (maskRect == nil) {
            maskRect = NewRgn();
        }

        (*stPixMap)->baseAddr = (void *) dispBitsIndex;
        
	if (!((rememberHeight == height) && (rememberWidth == width) && (rememberDepth == depth))) {
            rememberWidth  = dstRect.right = width;
            rememberHeight = dstRect.bottom = height;
    
            srcRect.right = width;
            srcRect.bottom = height;
    
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
        windowPort = GetWindowPort(stWindow);
	SetPort((GrafPtr) windowPort);
	CopyBits((BitMap *) *stPixMap, GetPortBitMapForCopyBits(windowPort), &srcRect, &dstRect, srcCopy, maskRect);

        if (gWindowsIsInvisible) {
            ShowWindow(stWindow);
            gWindowsIsInvisible = false;
        }
}
#else
int ioShowDisplay(
	int dispBitsIndex, int width, int height, int depth,
	int affectedL, int affectedR, int affectedT, int affectedB) {

        CGrafPtr	windowPort;
	static 		RgnHandle maskRect = nil;
        static int	titleH=0;
        int 		affectedW,affectedH;
        
        affectedW= affectedR - affectedL;
        affectedH= affectedB - affectedT;

	if ((stWindow == nil) || (affectedW <= 0) || (affectedH <= 0)){
            return;
	}

        windowPort = GetWindowPort(stWindow);
 
        if (maskRect == nil) {
            Rect structureRect;
            
            maskRect = NewRgn();            
            GetWindowRegion(stWindow,kWindowTitleBarRgn,maskRect);
            GetRegionBounds(maskRect,&structureRect);
            titleH = structureRect.bottom- structureRect.top;
        }

#if TARGET_API_MAC_CARBON
        LockPortBits(windowPort); 
#endif          
       {
            PixMapHandle    pix;
            int   pixPitch,pixDepth,pitch,bytes;
            char *in,*out;
                        
            pix = GetPortPixMap(windowPort);
            pixPitch = GetPixRowBytes(pix);
            pixDepth = GetPixDepth(pix);
            
            pitch = bytesPerLine(width, depth);
            bytes= affectedW * (depth / 8);
            
            in = (char *)dispBitsIndex + affectedL * (depth / 8) + affectedT * pitch;
            out = ((char *)GetPixBaseAddr(pix) + ((int)titleH * pixPitch)) +
                (affectedL * (pixDepth/8)) + (affectedT * pixPitch);
    
  
            if (depth == pixDepth) {  // either 16 or 32 bit 2 or 4 bytes */
                if (bytes > 32)
                    while (affectedH--)  {
                        memcpy((void *)out, (void *)in, bytes);
                        in  += pitch;
                        out += pixPitch;
                    }
                else if (bytes == 2)  // empirical
                    while (affectedH--) {
                        *((short *)out)= *((short *)in);
                        in  += pitch;
                        out += pixPitch;
                    } 
                else if (depth == 16)
                 while (affectedH--) {
                        register long   i,count= bytes/2;
                        register short   *to=   (short *) out;
                        register short   *from= (short *) in;
                        while (count--)
                            *to++= *from++;
                        in  += pitch;
                        out += pixPitch;
                    } 
                else while (affectedH--) {
                        register long   count= bytes/4;
                        register long   *to=   (long *) out;
                        register long   *from=  (long *)in;
                        while (count--)
                            *to++= *from++;
                        in  += pitch;
                        out += pixPitch;
                }
            } else if ( depth == 16 && pixDepth == 32) {
                while (affectedH--)  {
                        register long   *to=    (long *) out;
                        register short  *from=  (short *) in;
                        register long   count= bytes/2,target,r,g,b;  

                        while (count--) { /* see '11111'b needs to be '11111111'b */
                            target = *from++;
                            r = (target & 0x00007C00);
                            g = (target & 0x000003E0);
                            b = (target & 0x0000001F);
                            r = (r | (r << 3)) << 6;
                            g = (g | (g << 3)) << 3;
                            b = b | (b << 3) ;
                            *to++ =  r | g | b; 
                            /* *to++ = ((target & 0x00007C00) << 9) |
                                ((target &  0x000003E0) << 6) |
                                ((target & 0x0000001F) << 3); */

                        }
                        in  += pitch;
                        out += pixPitch;
                }
            } else if (depth == 32 && pixDepth == 16) {
                while (affectedH--)  {
                        register short *to=    (short *) out;
                        register long  *from=   (long *) in;
                        register long   count= bytes/4,target;  
                        while (count--) {
                            target = *from++;
                            *to++ = ((target & 0x00F80000) >> 9) |
                                ((target    &  0x0000F800) >> 6) |
                                ((target & 0x000000F8) >> 3); 
                        }
                        in  += pitch;
                        out += pixPitch;
                }
            } else if (depth == 8 && pixDepth == 16) {
                while (affectedH--)  {
                        short *to=   (short *)  out;
                        unsigned char  *from= ( unsigned char *) in;
                        long   count= bytes;
                        unsigned short r,g,b;
                        unsigned long target;
                        while (count--) {
                            target = *from++;
                            r = (short) (*stColorTable)->ctTable[target].rgb.red;  
                            g = (short) (*stColorTable)->ctTable[target].rgb.green;  
                            b = (short) (*stColorTable)->ctTable[target].rgb.blue;  
                            *to++ = ((r>>11) << 10) |
                                ((g>>11) << 5) |
                                ((b>>11)); 
                        }
                        in  += pitch;
                        out += pixPitch;
                }
            }else if (depth == 8 && pixDepth == 32) {
                while (affectedH--)  {
                    long *to=   (long *) out;
                    unsigned char  *from=  (unsigned char *) in;
                        long   count= bytes;
                        unsigned short r,g,b;
                        unsigned long target;
                        while (count--) {
                            target = *from++;
                            r = (short) (*stColorTable)->ctTable[target].rgb.red;  
                            g = (short) (*stColorTable)->ctTable[target].rgb.green;  
                            b = (short) (*stColorTable)->ctTable[target].rgb.blue;  
                            *to++ = ((r>>8) << 16) |
                                ((g>>8) << 8) |
                                ((b>>8)); 
                        }
                        in  += pitch;
                        out += pixPitch;
                }
            } else if (depth == 16 && pixDepth == 8) { // Untested, perhaps will not get called
                SetPort(windowPort);
                while (affectedH--)  {
                    unsigned char   *to=   (unsigned char *) out;
                    unsigned short  *from=  (unsigned short *) in;
                    long   count= bytes/2;
                    unsigned short target;
                    RGBColor colorPixel;
            
                    while (count--) {
                        target = *from++;
                        colorPixel.red = (target & 0x7C00) >> 10;
                        colorPixel.green = (target & 0x03E0) >> 5;
                        colorPixel.blue = (target & 0x001F);
                        *to++ = (unsigned char) Color2Index(&colorPixel);
                    }
                    in  += pitch;
                    out += pixPitch;
                }
            } else if (depth == 32 && pixDepth == 8) {
                SetPort(windowPort);
                while (affectedH--)  {
                    unsigned char   *to=   (unsigned char *) out;
                    unsigned short  *from=  (unsigned short *) in;
                    long   count= bytes/4;
                    unsigned long target;
                    RGBColor colorPixel;
            
                    while (count--) {
                        target = *from++;
                        colorPixel.red = (target & 0x00FF0000) >> 16;
                        colorPixel.green = (target & 0x0000FF00) >> 8;
                        colorPixel.blue = (target & 0x000000FF);
                        *to++ = (unsigned char) Color2Index(&colorPixel);
                    }
                    in  += pitch;
                    out += pixPitch;
                }
            }



            
#if TARGET_API_MAC_CARBON
            SetRectRgn(maskRect, affectedL, affectedT, affectedR, affectedB);
            QDFlushPortBuffer(windowPort, maskRect);
            UnlockPortBits(windowPort);
#endif
        }

        if (gWindowsIsInvisible) {
            ShowWindow(stWindow);
            gWindowsIsInvisible = false;
           //  NOT YET givers poor performance SetupSurface();
        }
}

#endif
#endif

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

void SetColorEntry(int index, int red, int green, int blue) {
	(*stColorTable)->ctTable[index].value = index;
	(*stColorTable)->ctTable[index].rgb.red = red;
	(*stColorTable)->ctTable[index].rgb.green = green;
	(*stColorTable)->ctTable[index].rgb.blue = blue;
}

void FreePixmap(void) {
	if (stPixMap != nil) {
		DisposePixMap(stPixMap);
		stPixMap = nil;
	}

	if (stColorTable != nil) {
		//JMM disposepixmap does this DisposeHandle((void *) stColorTable);
		stColorTable = nil;
	}
}

void SetUpWindow(void) {
	Rect windowBounds = {44, 8, 300, 500};

#ifndef IHAVENOHEAD
#if TARGET_API_MAC_CARBON & !defined(__MWERKS__)

    if ((Ptr)CreateNewWindow != (Ptr)kUnresolvedCFragSymbolAddress) {
        int windowType,windowAttributes;
        fetchPrefrencesForWindow(&windowType,&windowAttributes);
	CreateNewWindow(windowType,windowAttributes,&windowBounds,&stWindow);
    } else
#endif
	stWindow = NewCWindow(
		0L, &windowBounds,
		"\p Welcome to Squeak!  Reading Squeak image file... ",
		false, zoomDocProc, (WindowPtr) -1L, false, 0);
#endif
    SetUpPixmap();
}

void SetWindowTitle(char *title) {
    Str255 tempTitle;
	CopyCStringToPascal(title,tempTitle);
#ifndef IHAVENOHEAD
	SetWTitle(stWindow, tempTitle);
#endif
}

int ioForceDisplayUpdate(void) {
	/* do nothing on a Mac */
}

int ioHasDisplayDepth(int depth) {
	/* Return true if this platform supports the given color display depth. */

	switch (depth) {
	case 1:
	case 2:
	case 4:
            return false;  //OS-X 10.3.0/1 bug in copybits, force silly manual move
            break;
	case 8:
	case 16:
	case 32:
		return true;
	}
	return false;
}

int ioScreenDepth(void) {
    Rect ignore;
    GDHandle mainDevice;
    
#if TARGET_API_MAC_CARBON
    GetWindowGreatestAreaDevice(stWindow,kWindowContentRgn,&mainDevice,&ignore); 
#else
    mainDevice = getDominateDevice(stWindow,&ignore);
#endif

    if (mainDevice == null) 
        return 8;
    
    return (*(*mainDevice)->gdPMap)->pixelSize;
}

#ifndef BROWSERPLUGIN
int ioScreenSize(void) {
	int w = 10, h = 10;
    Rect portRect;
    
#ifndef IHAVENOHEAD
	if (stWindow != nil) {
            GetPortBounds(GetWindowPort(stWindow),&portRect);
            w =  portRect.right -  portRect.left;
            h =  portRect.bottom - portRect.top;
	}
#endif
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}
#endif

int ioSetCursor(int cursorBitsIndex, int offsetX, int offsetY) {
	/* Old version; forward to new version. */
	ioSetCursorWithMask(cursorBitsIndex, nil, offsetX, offsetY);
}

int ioSetCursorWithMask(int cursorBitsIndex, int cursorMaskIndex, int offsetX, int offsetY) {
	/* Set the 16x16 cursor bitmap. If cursorMaskIndex is nil, then make the mask the same as
	   the cursor bitmap. If not, then mask and cursor bits combined determine how cursor is
	   displayed:
			mask	cursor	effect
			 0		  0		transparent (underlying pixel shows through)
			 1		  1		opaque black
			 1		  0		opaque white
			 0		  1		invert the underlying pixel
	*/
	Cursor macCursor;
	int i;

	if (cursorMaskIndex == nil) {
		for (i = 0; i < 16; i++) {
			macCursor.data[i] = (checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFFFF;
			macCursor.mask[i] = (checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFFFF;
		}
	} else {
		for (i = 0; i < 16; i++) {
			macCursor.data[i] = (checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFFFF;
			macCursor.mask[i] = (checkedLongAt(cursorMaskIndex + (4 * i)) >> 16) & 0xFFFF;
		}
	}

	/* Squeak hotspot offsets are negative; Mac's are positive */
	macCursor.hotSpot.h = -offsetX;
	macCursor.hotSpot.v = -offsetY;
	SetCursor(&macCursor);
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


int ioSetDisplayMode(int width, int height, int depth, int fullscreenFlag) {
	/* Set the window to the given width, height, and color depth. Put the window
	   into the full screen mode specified by fullscreenFlag. */
	

    GDHandle		dominantGDevice;
	Rect 			ignore;
	Handle			displayState;
	UInt32			depthMode=depth;
	long			value = 0,displayMgrPresent;
	DMDisplayModeListIteratorUPP	myModeIteratorProc = nil;	
	DisplayIDType	theDisplayID;				
	DMListIndexType	theDisplayModeCount;		
	DMListType		theDisplayModeList;			
	VideoRequestRec	request;
	
#ifndef IHAVENOHEAD


	Gestalt(gestaltDisplayMgrAttr,&value);
	displayMgrPresent=value&(1<<gestaltDisplayMgrPresent);
    if (!displayMgrPresent) {
    	success(false);
    	return 0;
    }

#if TARGET_API_MAC_CARBON
        GetWindowGreatestAreaDevice(stWindow,kWindowContentRgn,&dominantGDevice,&ignore); 
#else
        dominantGDevice = getDominateDevice(stWindow,&ignore);
#endif
        if (dominantGDevice == null) {
            success(false);
            return 0;
        }
	request.screenDevice  = dominantGDevice;
	request.reqBitDepth = depth;
	request.reqHorizontal = width;
	request.reqVertical = height;
	request.requestFlags = 1<<kAbsoluteRequestBit;
	request.displayMode = 0;
	myModeIteratorProc = NewDMDisplayModeListIteratorUPP(ModeListIterator);	// for DM2.0 searches

	if  (dominantGDevice && myModeIteratorProc) {
		if( noErr == DMGetDisplayIDByGDevice( dominantGDevice, &theDisplayID, false ) ) {
			theDisplayModeCount = 0;
			if (noErr == DMNewDisplayModeList(theDisplayID, 0, 0, &theDisplayModeCount, &theDisplayModeList) ) {
				GetRequestTheDM2Way (&request, dominantGDevice, myModeIteratorProc, theDisplayModeCount, &theDisplayModeList);
				DMDisposeList(theDisplayModeList);	
			} else {
			}
		}
	}
	
	if (myModeIteratorProc)
		DisposeDMDisplayModeListIteratorUPP(myModeIteratorProc);
	if (request.displayMode == 0)  {
    	success(false);
    	return 0;
    }
	DMBeginConfigureDisplays(&displayState);
	DMSetDisplayMode(dominantGDevice,request.displayMode,&depthMode,null,displayState);
	DMEndConfigureDisplays(displayState);
	ioSetFullScreen(fullscreenFlag);
	
    return 1;
#endif
}


#if !I_AM_CARBON_EVENT || defined(BROWSERPLUGIN)
#define rectWidth(aRect) ((aRect).right - (aRect).left)
#define rectHeight(aRect) ((aRect).bottom - (aRect).top)
#define MinWindowWidth(foo) 72*3
#define MinWindowHeight(foo) 72*3

#define max(X, Y) ( ((X)>(Y)) ? (X) : (Y) )
#define min(X, Y) (  ((X)>(Y)) ? (Y) : (X) )

#define pin(VALUE, MIN, MAX) ( ((VALUE) < (MIN)) ? (MIN) : ( ((VALUE) > (MAX)) ? (MAX) : (VALUE) ) )

void DoZoomWindow (EventRecord* theEvent, WindowPtr theWindow, short zoomDir, short hMax, short vMax)
{

	Rect				zoomRect,windRect,globalPortRect, dGDRect;
	GDHandle			dominantGDevice;
   
	if (TrackBox(theWindow, theEvent->where, zoomDir)) {
		SetPortWindowPort(theWindow);
		GetPortBounds(GetWindowPort(stWindow),&windRect);
		EraseRect(&windRect);	// recommended for cosmetic reasons

		if (zoomDir == inZoomOut) {

			/*
			 *	ZoomWindow() is a good basic tool, but it doesn't do everything necessary to
			 *	implement a good human interface when zooming. In fact it's not even close for
			 *	more high-end hardware configurations. We must help it along by calculating an
			 *	appropriate window size and location any time a window zooms out.
			 */

            dominantGDevice = getDominateDevice(theWindow,&windRect);
            if (dominantGDevice == null) {
                return;
            }

			/*
			 *	At this point, we know the dimensions of the window we're zooming, and we know
			 *	what screen we're going to put it on. To be more specific, however, we need a
			 *	rectangle which defines the maximum dimensions of the resized window's contents.
			 *	This rectangle accounts for the thickness of the window frame, the menu bar, and
			 *	one or two pixels around the edges for cosmetic compatibility with ZoomWindow().
			 */

            getDominateGDeviceRect(dominantGDevice,&dGDRect,false);
            
			GetPortBounds(GetWindowPort(theWindow),&globalPortRect);
			LocalToGlobal(&(((Point *) &(globalPortRect))[0]));		// calculate the window's portRect
			LocalToGlobal(&(((Point *) &(globalPortRect))[1]));		// in global coordinates

			// account for the window frame and inset it a few pixels
			dGDRect.left	+= 2 + globalPortRect.left - windRect.left;
			dGDRect.top		+= 2 + globalPortRect.top - windRect.top;
			dGDRect.right	-= 1 + windRect.right - globalPortRect.right;
			dGDRect.bottom	-= 1 + windRect.bottom - globalPortRect.bottom;

			/*
			 *	Now we know exactly what our limits are, and since there are input parameters
			 *	specifying the dimensions we'd like to see, we can move and resize the zoom
			 *	state rectangle for the best possible results. We have three goals in this:
			 *	1. Display the window entirely visible on a single device.
			 *	2. Resize the window to best represent the dimensions of the document itself.
			 *	3. Move the window as short a distance as possible to achieve #1 and #2.
			 */

			GetWindowStandardState(theWindow, &zoomRect);

			/*
			 *	Initially set the zoom rectangle to the size requested by the input parameters,
			 *	although not smaller than a minimum size. We do this without moving the origin.
			 */

			zoomRect.right = (zoomRect.left = globalPortRect.left) +
									max(hMax, MinWindowWidth(theWindow));
			zoomRect.bottom = (zoomRect.top = globalPortRect.top) +
									max(vMax, MinWindowHeight(theWindow));

			// Shift the entire rectangle if necessary to bring its origin inside dGDRect.
			OffsetRect(&zoomRect,
						max(dGDRect.left - zoomRect.left, 0),
						max(dGDRect.top - zoomRect.top, 0));

			/*
			 *	Shift the rectangle up and/or to the left if necessary to accomodate the view,
			 *	and if it is possible to do so. The rectangle may not be moved such that its
			 *	origin would fall outside of dGDRect.
			 */

			OffsetRect(&zoomRect,
						-pin(zoomRect.right - dGDRect.right, 0, zoomRect.left - dGDRect.left),
						-pin(zoomRect.bottom - dGDRect.bottom, 0, zoomRect.top - dGDRect.top));

			// Clip expansion to dGDRect, in case view is larger than dGDRect.
			zoomRect.right = min(zoomRect.right, dGDRect.right);
			zoomRect.bottom = min(zoomRect.bottom, dGDRect.bottom);
			SetWindowStandardState(theWindow, &zoomRect);
		}

		ZoomWindow(theWindow, zoomDir, false);		// all it needed was a brain transplant
	}
}

GDHandle getDominateDevice( WindowPtr theWindow,Rect *windRect) {
	GDHandle			nthDevice, dominantGDevice;
	long				sectArea, greatestArea;
    long                quickDrawAttributes;
	Rect				theSect;
 
    
#if TARGET_API_MAC_CARBON
    RgnHandle           windowRegion;
			windowRegion = NewRgn();
			GetWindowRegion(theWindow,kWindowStructureRgn,windowRegion);
			GetRegionBounds(windowRegion,windRect);
#else
			*windRect = (**((WindowPeek) theWindow)->strucRgn).rgnBBox;
			if (windRect->left == 0 && windRect->top == 0 && windRect->bottom == 0 && windRect->right == 0) {
				windRect->right = (unsigned) getSavedWindowSize() >> 16;
				windRect->bottom = getSavedWindowSize() & 0xFFFF;

			}
#endif
			dominantGDevice = nil;
    	    if (! Gestalt(gestaltQuickdrawFeatures, &quickDrawAttributes) && 
    	        (quickDrawAttributes & (1<<gestaltHasColor))) {

				/*
				 *	Color QuickDraw implies the possibility of multiple monitors. This is where
				 *	zooming becomes more interesting. One should zoom onto the monitor containing
				 *	the greatest portion of the window. This requires walking the gDevice list.
				 */

				nthDevice = GetDeviceList();
				greatestArea = 0;
				while (nthDevice != nil) {
					if (TestDeviceAttribute(nthDevice, screenDevice)) {
						if (TestDeviceAttribute(nthDevice, screenActive)) {
							SectRect(windRect, &(**nthDevice).gdRect, &theSect);
							sectArea = (long) rectWidth(theSect) * (long) rectHeight(theSect);
							if (sectArea > greatestArea) {
								greatestArea = sectArea;		// save the greatest intersection
								dominantGDevice = nthDevice;	// and which device it belongs to
							}
						}
					}
					nthDevice = GetNextDevice(nthDevice);
				}
			}
    return dominantGDevice;
}

void getDominateGDeviceRect(GDHandle dominantGDevice,Rect *dGDRect,Boolean forgetMenuBar) {
    BitMap              bmap;

	if (dominantGDevice != nil) {
			*dGDRect = (**dominantGDevice).gdRect;
			if (dominantGDevice == GetMainDevice())		// account for menu bar on main device
				if (!forgetMenuBar) 
				        dGDRect->top += GetMBarHeight();
		}
		else {
			GetQDGlobalsScreenBits(&bmap);
			*dGDRect = bmap.bounds;				// if no gDevice, use default monitor
			if (!forgetMenuBar)
			    dGDRect->top += GetMBarHeight();
		}
}
#endif

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
	unsigned long			depthCount;
	short					iCount;
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
	short					jCount;
	short					kCount;
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
	if	(	nil == requestRecPtr->displayMode
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
			if	(	abs((requestRecPtr->reqHorizontal - horizontal)) <=
					abs((requestRecPtr->reqHorizontal - requestRecPtr->availHorizontal)) &&
					abs((requestRecPtr->reqVertical - vertical)) <=
					abs((requestRecPtr->reqVertical - requestRecPtr->availVertical))
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
	return (false);
}
  
#if TARGET_API_MAC_CARBON
void fetchPrefrencesForWindow(int *windowType,int *windowAttributes) {
    CFBundleRef  myBundle;
    CFDictionaryRef myDictionary;
    CFNumberRef SqueakWindowType,SqueakMaxHeapSizeType;
    CFBooleanRef SqueakWindowHasTitleType,SqueakFloatingWindowGetsFocusType;
    CFDataRef 	SqueakWindowAttributeType;    
    extern	Boolean gSqueakWindowIsFloating,gSqueakWindowHasTitle,gSqueakFloatingWindowGetsFocus;
    extern 	UInt32 gMaxHeapSize;
    
    myBundle = CFBundleGetMainBundle();
    myDictionary = CFBundleGetInfoDictionary(myBundle);
    SqueakWindowType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowType"));
    SqueakWindowAttributeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowAttribute"));
    SqueakWindowHasTitleType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakWindowHasTitle"));
    SqueakFloatingWindowGetsFocusType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakFloatingWindowGetsFocus"));
    SqueakMaxHeapSizeType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakMaxHeapSize"));
    
    if (SqueakWindowType) 
        CFNumberGetValue(SqueakWindowType,kCFNumberLongType,windowType);
    else
        *windowType = kDocumentWindowClass;
        
    gSqueakWindowIsFloating = *windowType == kUtilityWindowClass;
        
    if (SqueakWindowAttributeType && CFDataGetLength(SqueakWindowAttributeType) == 4) {
            const UInt8 *where;
            where = CFDataGetBytePtr(SqueakWindowAttributeType);
            memmove(windowAttributes,where,4);
    } else {
        *windowAttributes = kWindowStandardDocumentAttributes
            +kWindowStandardHandlerAttribute
            +kWindowNoConstrainAttribute
            -kWindowCloseBoxAttribute;
    }
    
    if (SqueakWindowHasTitleType) 
        gSqueakWindowHasTitle = CFBooleanGetValue(SqueakWindowHasTitleType);
    else 
        gSqueakWindowHasTitle = true;
        
    if (SqueakFloatingWindowGetsFocusType) 
        gSqueakFloatingWindowGetsFocus = CFBooleanGetValue(SqueakFloatingWindowGetsFocusType);
    else
        gSqueakFloatingWindowGetsFocus = false;

    if (SqueakMaxHeapSizeType) 
        CFNumberGetValue(SqueakMaxHeapSizeType,kCFNumberLongType,(long *) &gMaxHeapSize);
    
}
#endif 
#ifdef JMMFOO2

int ioShowDisplay(
	int dispBitsIndex, int width, int height, int depth,
	int affectedL, int affectedR, int affectedT, int affectedB) {

        static int  rememberWidth=0,rememberHeight=0,rememberDepth=0,rememberDispBitsIndex=0;
        static CGContextRef context=NULL;
        static CGImageRef image;
        static CGRect rectangle;
        CGRect clip;

	if (stWindow == nil) {
            return;
	}


	if (!((rememberHeight == height) && (rememberWidth == width) && (rememberDepth == depth) && (rememberDispBitsIndex == dispBitsIndex))) {
            CGDataProviderRef provider;
            CGColorSpaceRef colorspace;
            size_t size;
            long    bytes = (((width * depth) + 31) / 32) * 4;
            
            rememberWidth  = width;
            rememberHeight = height;
            rememberDepth  = depth;
            rectangle = CGRectMake(0, 0, width, height);  

            if (context == NULL) {
                CreateCGContextForPort(GetWindowPort(stWindow), &context);
            }
            
            if (image)    
                CGImageRelease(image);
            /* Create a data provider with a pointer to the memory bits
            for testing just do the 16bit argb and ignore other color space issues
            see http://developer.apple.com/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/chapter_6_section_3.html
            */
            provider = CGDataProviderCreateWithData(NULL, (void*)dispBitsIndex, bytes * height, NULL);
            colorspace = CGColorSpaceCreateDeviceRGB();
            /* Create the image  **** NOT COMPLETE ONLY GOOD FOR 16BIT NEED TO ADJUST FOR OTHER SQUEAK COLOR SPACE 1 8 or 32 */
            image = CGImageCreate(width, height, 5 /* bitsPerComponent */,
                    16 /* bitsPerPixel */,
                    bytes, colorspace, kCGImageAlphaNoneSkipFirst, provider, NULL, 0, kCGRenderingIntentDefault);
            /* Once the image is created we can release our reference to the
            provider and the colorspace. They will be retained by the
            image */
            CGDataProviderRelease(provider);
            CGColorSpaceRelease(colorspace);
        }

        if (gWindowsIsInvisible) {
            ShowWindow(stWindow);
            gWindowsIsInvisible = false;
        }

        /* Draw the image to the Core Graphics context */
        CGContextSaveGState(context);
        clip = CGRectMake(affectedL,height-affectedB, affectedR-affectedL, affectedB-affectedT);
        CGContextClipToRect(context, clip);
        CGContextDrawImage(context, rectangle, image);
        CGContextFlush(context);
        CGContextRestoreGState(context);
        return;
}
#endif

#if JMMFoo 
#include "SurfacePlugin.h"

int osxGetSurfaceFormat(int handle, int* width, int* height, int* depth, int* isMSB);
int osxLockSurface(int handle, int *pitch, int x, int y, int w, int h);
int osxUnlockSurface(int handle, int x, int y, int w, int h);
int osxShowSurface(int handle, int x, int y, int w, int h);


static sqSurfaceDispatch osxTargetDispatch = {
  1,
  0,
  (fn_getSurfaceFormat) osxGetSurfaceFormat,
  (fn_lockSurface) osxLockSurface,
  (fn_unlockSurface) osxUnlockSurface,
  (fn_showSurface) osxShowSurface
};

static fn_ioRegisterSurface registerSurface = 0;
static fn_ioUnregisterSurface unregisterSurface = 0;
static int surfaceID;
static int unknown=0x0000BEEF;

void SetupSurface() {
    registerSurface = (fn_ioRegisterSurface) interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
    unregisterSurface = (fn_ioUnregisterSurface) interpreterProxy->ioLoadFunctionFrom("ioUnregisterSurface","SurfacePlugin");
    (*registerSurface)(unknown, &osxTargetDispatch, &surfaceID);
}


int osxGetSurfaceFormat(int handle, int* width, int* height, int* depth, int* isMSB) {
    CGrafPtr	windowPort = GetWindowPort(stWindow);
    PixMapHandle pix;
    Rect        rectangle;
    
    LockPortBits(windowPort); 
    pix = GetPortPixMap(windowPort);
    *depth= GetPixDepth(pix);
    GetPixBounds(pix,&rectangle);
    *width = rectangle.right - rectangle.left;
    *height = rectangle.bottom - rectangle.top;
    *isMSB = 1;
    UnlockPortBits(windowPort);
    return 1;
}

int osxLockSurface(int handle, int *pitch, int x, int y, int w, int h) {
    static Boolean firstTime=true;
    static int offsetTitle=0;
    CGrafPtr    windowPort = GetWindowPort(stWindow);
    PixMapHandle pixMap;
    
    LockPortBits(windowPort);
    pixMap =  GetPortPixMap(windowPort);
    *pitch = GetPixRowBytes(pixMap);

    if (firstTime) {
        Rect structureRect;
        RgnHandle rect;
        firstTime = false;
             
        rect = NewRgn();            
        GetWindowRegion(stWindow,kWindowTitleBarRgn,rect);
        GetRegionBounds(rect,&structureRect);
        offsetTitle = (structureRect.bottom- structureRect.top)* *pitch;
        DisposeRgn(rect);
    }
    
    return (char *)GetPixBaseAddr(pixMap) + offsetTitle;
}

int osxUnlockSurface(int handle, int x, int y, int w, int h) {
    UnlockPortBits(GetWindowPort(stWindow)); 
}

int osxShowSurface(int handle, int x, int y, int w, int h) {
    
    static RgnHandle maskRect=NULL;
    
    if (maskRect == NULL)
        maskRect = NewRgn();
        
    SetRectRgn(maskRect, x, y, x+w, y+h);
    QDFlushPortBuffer(GetWindowPort(stWindow), maskRect); 
}

inline void DuffsDevicesCopyLong(long *to, long *from, long count) {
    long n=(count+7)/8;
    switch(count%8){
    case 0: do{     *to = *from++;
    case 7:         *to = *from++;
    case 6:         *to = *from++;
    case 5:         *to = *from++;
    case 4:         *to = *from++;
    case 3:         *to = *from++;
    case 2:         *to = *from++;
    case 1:         *to = *from++;
            }while(--n>0);
    }
}

#endif 