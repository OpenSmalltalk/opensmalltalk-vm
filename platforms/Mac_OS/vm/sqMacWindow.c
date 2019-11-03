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
*****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

#include "sq.h"
#include "sqMacUIConstants.h"
#include "sqMacWindow.h"
#include "sqMacUnixFileInterface.h"
#include "sqmacUIEvents.h"
#include "sqMacUIMenuBar.h"
#include "sqMacEncoding.h"
#include "sqMacHostWindow.h"

/*** Variables -- Imported from Virtual Machine ***/
extern int getFullScreenFlag();    /* set from header when image file is loaded */
extern int setFullScreenFlag(int value);    /* set from header when image file is loaded */
extern int getSavedWindowSize();   /* set from header when image file is loaded */
extern int setSavedWindowSize(int value);   /* set from header when image file is loaded */
extern struct VirtualMachine *interpreterProxy;

/*** Variables -- Mac Related ***/
CTabHandle	stColorTable = nil;
PixMapHandle	stPixMap = nil;
Boolean  	gWindowsIsInvisible=true;


/*** Functions ***/
void SetColorEntry(int index, int red, int green, int blue);
GDHandle getDominateDevice(WindowPtr theWindow,Rect *windRect);
void getDominateGDeviceRect(GDHandle dominantGDevice,Rect *dGDRect,Boolean forgetMenuBar);

WindowPtr getSTWindow(void) {
    return  windowHandleFromIndex(1);
}

#ifndef BROWSERPLUGIN
#if TARGET_API_MAC_CARBON
extern struct VirtualMachine *interpreterProxy;
int ioSetFullScreenActual(int fullScreen);
void SetupSurface(int whichWindowIndex);

int ioSetFullScreen(int fullScreen) {
        void *  giLocker;
		int return_value=0;
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
    Rect                screen,portRect;
    int                 width, height, maxWidth, maxHeight;
    int                 oldWidth, oldHeight;
    static Rect		rememberOldLocation = {0,0,0,0};		
    GDHandle            dominantGDevice;
	
	if (fullScreen && getFullScreenFlag() && !gWindowsIsInvisible)
			return 0;

	dominantGDevice = getThatDominateGDevice(getSTWindow());
    if (dominantGDevice == null) {
        success(false);
        return 0;
    }

#if TARGET_API_MAC_CARBON
    screen = (**dominantGDevice).gdRect;
#else
    getDominateGDeviceRect(dominantGDevice,&screen,true);
#endif  
        
    if (fullScreen) {
		GetPortBounds(GetWindowPort(getSTWindow()),&rememberOldLocation);
		if (gWindowsIsInvisible) {
			rememberOldLocation.top = 44;
			rememberOldLocation.left = 8;
		}
		LocalToGlobal((Point*) &rememberOldLocation.top);
		LocalToGlobal((Point*) &rememberOldLocation.bottom);
		MenuBarHide();
		GetPortBounds(GetWindowPort(getSTWindow()),&portRect);
		oldWidth =  portRect.right -  portRect.left;
		oldHeight =  portRect.bottom -  portRect.top;
		width  = screen.right - screen.left; 
		height = (screen.bottom - screen.top);
		MoveWindow(getSTWindow(), screen.left, screen.top, true);
		SizeWindow(getSTWindow(), width, height, true);
		setFullScreenFlag(true);
	} else {
		MenuBarRestore();

		if (EmptyRect(&rememberOldLocation)) {
			/* get old window size */
			width  = (unsigned) getSavedWindowSize() >> 16;
			height = getSavedWindowSize() & 0xFFFF;

			/* minimum size is 1 x 1 */
			width  = (width  > 0) ?  width : 64;
			height = (height > 0) ? height : 64;

		/* maximum size is screen size inset slightly */
		maxWidth  = (screen.right  - screen.left) - 16;
		maxHeight = (screen.bottom - screen.top)  - 52;
		width  = (width  <= maxWidth)  ?  width : maxWidth;
		height = (height <= maxHeight) ? height : maxHeight;
			MoveWindow(getSTWindow(), 8, 44, true);
			SizeWindow(getSTWindow(), width, height, true);
		} else {
		MoveWindow(getSTWindow(), rememberOldLocation.left, rememberOldLocation.top, true);
			SizeWindow(getSTWindow(), rememberOldLocation.right - rememberOldLocation.left, rememberOldLocation.bottom - rememberOldLocation.top, true);
		}
		
		setFullScreenFlag(false);
	}
	return 0;
}

#if TARGET_API_MAC_CARBON

extern struct VirtualMachine *interpreterProxy;
void sqShowWindow(int windowIndex);
void sqShowWindowActual(int windowIndex);

void sqShowWindow(int windowIndex) {
        void *  giLocker;
        giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
        if (giLocker != 0) {
            long *foo;
            foo = malloc(sizeof(long)*4);
            foo[0] = 1;
            foo[1] = (int) sqShowWindowActual;
            foo[2] = windowIndex;
            foo[3] = 0;
            ((int (*) (void *)) giLocker)(foo);
            free(foo);
        }
}

void sqShowWindowActual(int windowIndex){
#else
void sqShowWindow(int windowIndex) {
#endif
	if ( windowHandleFromIndex(windowIndex))
	ShowWindow( windowHandleFromIndex(windowIndex));
}

int ioShowDisplay(
	int dispBitsIndex, int width, int height, int depth,
	int affectedL, int affectedR, int affectedT, int affectedB) {
	
	ioShowDisplayOnWindow( (unsigned int*)  dispBitsIndex,  width,  height,  depth, affectedL,  affectedR,  affectedT,  affectedB, 1);
	return 1;
}

#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)
#if !TARGET_API_MAC_CARBON
int ioShowDisplayOnWindow( unsigned int* dispBitsIndex, int width, int height, int depth, 
	int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex) {

        CGrafPtr	windowPort;
	static 		RgnHandle maskRect = nil;
	static Rect	dstRect = { 0, 0, 0, 0 };
	static Rect	srcRect = { 0, 0, 0, 0 };
        static int	rememberWidth=0,rememberHeight=0,rememberDepth=0;
        
	if (gWindowsIsInvisible && getSTWindow() == NULL) {
		makeMainWindow();
	}
	
	if (windowHandleFromIndex(windowIndex) == nil) {
            return 0;
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
	windowPort = GetWindowPort(windowHandleFromIndex(windowIndex));
	SetPort((GrafPtr) windowPort);
	CopyBits((BitMap *) *stPixMap, GetPortBitMapForCopyBits(windowPort), &srcRect, &dstRect, srcCopy, maskRect);

        if (gWindowsIsInvisible) {
		sqShowWindow(1);
		gWindowsIsInvisible = false;
	}
	return 1;
}
#else
void * copy124BitsTheHardWay(
	unsigned int * dispBitsIndex, int width, int height, int depth, int desiredDepth,
	int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex,int *pixPitch);

#ifdef JMMFoo
void ReduceQDFlushLoad(CGrafPtr	windowPort, int windowIndexToUse,  int affectedL, int affectedT, int affectedR, int affectedB);
	
int ioShowDisplayOnWindow( unsigned int* dispBitsIndex, int width, int height, int depth, 
	int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex) {

        CGrafPtr	windowPort;
		static RgnHandle maskRect = nil;
        static int	titleH=0,lastWindowIndex=-1;
        int 		affectedW,affectedH;
        
	if (gWindowsIsInvisible && getSTWindow() == NULL) {
		makeMainWindow();
	}
		if (affectedL < 0) affectedL = 0;
		if (affectedT < 0) affectedT = 0;
		if (affectedR > width) affectedR = width;
		if (affectedB > height) affectedB = height;
		
        affectedW= affectedR - affectedL;
        affectedH= affectedB - affectedT;

	if ((windowHandleFromIndex(windowIndex) == nil) || (affectedW <= 0) || (affectedH <= 0)){
            return 0;
	}

        windowPort = GetWindowPort(windowHandleFromIndex(windowIndex));
		if (windowPort == nil) 
			return 0;
 
        if (maskRect == nil) {            
            maskRect = NewRgn();            
        }
		
		
		if (lastWindowIndex != windowIndex) {
            Rect structureRect;
            GetWindowRegion(windowHandleFromIndex(windowIndex),kWindowTitleBarRgn,maskRect);
            GetRegionBounds(maskRect,&structureRect);
            titleH = structureRect.bottom- structureRect.top;
			lastWindowIndex = windowIndex;
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
            
			if (depth == 1 || depth == 2 || depth == 4) {
				dispBitsIndex = copy124BitsTheHardWay((unsigned int *) dispBitsIndex, width, height, depth, pixDepth, affectedL, affectedR, affectedT,  affectedB,  windowIndex, &pitch);
				depth = pixDepth;
			} else {
				pitch = bytesPerLine(width, depth);
			}
 
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
                        register long   count= bytes/2;
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
				//(2r0 to: 2r11111000 by: 2r1000) collectWithIndex: [:e :i | (e + ((8/32*(i-1)) asInteger)) bitShift: 16]
				long lookupTableB[32] = { 
				 0, 8, 16, 24, 33, 41, 49, 57,
				 66, 74, 82, 90, 99, 107, 115, 123,
				 132, 140, 148, 156, 165, 173, 181, 189,
				 198, 206, 214, 222, 231, 239, 247, 255};

				long lookupTableG[32] = { 
				0, 2048, 4096, 6144, 8448, 10496, 12544, 14592, 
				16896, 18944, 20992, 23040, 25344, 27392, 29440, 31488, 
				33792, 35840, 37888, 39936, 42240, 44288, 46336, 48384, 
				50688, 52736, 54784, 56832, 59136, 61184, 63232, 65280};

 				long lookupTableR[32] = { 
				0, 524288, 1048576, 1572864, 2162688, 2686976, 3211264, 3735552,
				4325376, 4849664, 5373952, 5898240, 6488064, 7012352, 7536640, 8060928,
				8650752, 9175040, 9699328, 10223616, 10813440, 11337728, 11862016, 12386304,
				12976128, 13500416, 14024704, 14548992, 15138816, 15663104, 16187392, 16711680};
				
                while (affectedH--)  {
                        register long   *to=    (long *) out;
                        register short  *from=  (short *) in;
                        register long   count= bytes/2,target,r,g,b;  

                        while (count--) { /* see '11111'b needs to be '11111111'b */
                            target = *from++;
                            r = (target & 0x00007C00) >> 10;
                            g = (target & 0x000003E0) >> 5;
                            b = (target & 0x0000001F);
                            r = lookupTableR[r];
                            g = lookupTableG[g];
                            b = lookupTableB[b];
                            *to++ =   r | g | b ; 
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
            } else if (depth == 16 && pixDepth == 8) { //Tested by Steve Moffitt <stevia@citlink.net> not all machines do true 8bit windows, some the GPU does and window stays as 16bits
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
			ReduceQDFlushLoad(windowPort, windowIndex, affectedL,  affectedT,  affectedR,  affectedB);		
#endif
        }

	UnlockPortBits(windowPort);			 //JMM BEWARE

	if (gWindowsIsInvisible) {
		sqShowWindow(1);
		gWindowsIsInvisible = false;
	}
	return 1;
}

void ReduceQDFlushLoad(CGrafPtr	windowPort, int windowIndexToUse, int affectedL, int affectedT, int affectedR, int affectedB) {
	Rect rect;
	windowDescriptorBlock * validWindowHandle = windowBlockFromIndex(windowIndexToUse);

		
	rect.top = affectedT;
	rect.left = affectedL;
	rect.bottom = affectedB;
	rect.right = affectedR; 

	if (EmptyRect(&validWindowHandle->dirtyRectangle))
		validWindowHandle->dirtyRectangle = rect;
	else
		UnionRect(&validWindowHandle->dirtyRectangle,&rect,&validWindowHandle->dirtyRectangle);
			
}


#endif 

static const void *get_byte_pointer(void *bitmap)
{
    return (void *) bitmap;
}

CGDataProviderDirectAccessCallbacks gProviderCallbacks = {
    get_byte_pointer,
    NULL,
    NULL,
    NULL
};


int ioShowDisplayOnWindow(
	unsigned int*  dispBitsIndex, int width, int height, int depth,
	int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex) {

	static CGColorSpaceRef colorspace = NULL;
	int 		pitch;
	CGImageRef image;
	CGRect		clip;
	windowDescriptorBlock *targetWindowBlock;
	CGDataProviderRef provider;

	if (gWindowsIsInvisible) {
		if (getSTWindow() == NULL) {
			makeMainWindow();
		}
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
	}

	if (affectedL < 0) affectedL = 0;
	if (affectedT < 0) affectedT = 0;
	if (affectedR > width) affectedR = width;
	if (affectedB > height) affectedB = height;
	
	if ((windowHandleFromIndex(windowIndex) == nil) || ((affectedR - affectedL) <= 0) || ((affectedB - affectedT) <= 0)){
            return 0;
	}

	if (depth > 0 && depth <= 8) {
		dispBitsIndex = copy124BitsTheHardWay((unsigned int *) dispBitsIndex, width, height, depth, 32, affectedL, affectedR, affectedT,  affectedB,  windowIndex, &pitch);
		depth = 32;
	} else {
		pitch = bytesPerLine(width, depth);
	}
			
	targetWindowBlock = windowBlockFromIndex(windowIndex);	
	provider = CGDataProviderCreateDirectAccess((void*)dispBitsIndex
				+ pitch*affectedT 
				+ affectedL*(depth==32 ? 4 : 2),  
				pitch * (affectedB-affectedT)-affectedL*(depth==32 ? 4 : 2), 
				&gProviderCallbacks);
	image = CGImageCreate( affectedR-affectedL, affectedB-affectedT, depth==32 ? 8 : 5 /* bitsPerComponent */,
				depth /* bitsPerPixel */,
				pitch, colorspace, kCGImageAlphaNoneSkipFirst, provider, NULL, 0, kCGRenderingIntentDefault);

	clip = CGRectMake(affectedL,height-affectedB, affectedR-affectedL, affectedB-affectedT);

	if (gWindowsIsInvisible) {
		sqShowWindow(1);
		gWindowsIsInvisible = false;
	}

	if (targetWindowBlock->width != width && targetWindowBlock->height  != height) {
		if (targetWindowBlock->context) {
			QDEndCGContext(GetWindowPort(targetWindowBlock->handle),&targetWindowBlock->context);
			//CGContextRelease(targetWindowBlock->context);
		}
 		//CreateCGContextForPort(GetWindowPort(targetWindowBlock->handle),&targetWindowBlock->context); 
		QDBeginCGContext(GetWindowPort(targetWindowBlock->handle),&targetWindowBlock->context); 
		targetWindowBlock->sync = false;
		
		targetWindowBlock->width = width;
		targetWindowBlock->height = height; 
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
	CGContextDrawImage(targetWindowBlock->context, clip, image);
	
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
	
	CGImageRelease(image);
	CGDataProviderRelease(provider);
	
	return 1;
}


void * copy124BitsTheHardWay(unsigned int* dispBitsIndex, int width, int height, int depth, int desiredDepth,
	int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex, int *pitch) {
	
	static GWorldPtr offscreenGWorld = nil;
	Rect structureRect;
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
			GetWindowRegion(windowHandleFromIndex(windowIndex),kWindowContentRgn,maskRect);
			GetRegionBounds(maskRect,&structureRect);
			structureRect.bottom = structureRect.bottom - structureRect.top;
			structureRect.right = structureRect.right - structureRect.left;
			structureRect.top = structureRect.left = 0;
			
			if (offscreenGWorld != nil)
				DisposeGWorld(offscreenGWorld);
			
			error	= NewGWorld (&offscreenGWorld,desiredDepth,&structureRect,0,0,keepLocal);
			LockPixels(GetGWorldPixMap(offscreenGWorld));
			
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
	CopyBits((BitMap *) *stPixMap,(BitMap *)*GetGWorldPixMap(offscreenGWorld), &srcRect, &dstRect, srcCopy, maskRect);
	*pitch = GetPixRowBytes(GetGWorldPixMap(offscreenGWorld));
	return GetPixBaseAddr(GetGWorldPixMap(offscreenGWorld));
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

extern Boolean gSqueakWindowHasTitle;
int makeMainWindow(void) {
	WindowPtr window;
	char	shortImageName[256];
	int width,height;
	windowDescriptorBlock *windowBlock;
	extern UInt32 gSqueakWindowType,gSqueakWindowAttributes;
		
	/* get old window size */
	width  = (unsigned) getSavedWindowSize() >> 16;
	height = getSavedWindowSize() & 0xFFFF;
	
	
	window = SetUpWindow(44, 8, 44+height, 8+width,gSqueakWindowType,gSqueakWindowAttributes);
	windowBlock = AddWindowBlock();
	windowBlock-> handle = (wHandleType) window;

#ifndef MINIMALVM
	 ioLoadFunctionFrom(NULL, "DropPlugin");
#endif
    
#ifndef IHAVENOHEAD
	if (gSqueakWindowHasTitle) {
		getShortImageNameWithEncoding(shortImageName,gCurrentVMEncoding);
		SetWindowTitle(1,shortImageName);
	}
#ifndef BROWSERPLUGIN
#if I_AM_CARBON_EVENT	
        ioSetFullScreenActual(getFullScreenFlag());
		SetUpCarbonEventForWindowIndex(1);
		CreateCGContextForPort(GetWindowPort(windowBlock->handle),&windowBlock->context);  
   
 	Rect portRect;
	int	w,h;
	
		GetPortBounds(GetWindowPort(windowBlock->handle),&portRect);
		w =  portRect.right -  portRect.left;
		h =  portRect.bottom - portRect.top;
		setSavedWindowSize((w << 16) |(h & 0xFFFF));
		windowBlock->width = w;
		windowBlock->height = h; 
#else
	ioSetFullScreen(getFullScreenFlag());
#endif
#endif 
#endif

	//SetupSurface(1);
	return (int) window;
}


WindowPtr SetUpWindow(int t,int l,int b, int r, UInt32 windowType, UInt32 windowAttributes) {
	Rect windowBounds;
	WindowPtr   createdWindow;
	
	SetRect (&windowBounds,l,t,r,b);

#ifndef IHAVENOHEAD
#if TARGET_API_MAC_CARBON & !defined(__MWERKS__)

    if ((Ptr)CreateNewWindow != (Ptr)kUnresolvedCFragSymbolAddress) {
		CreateNewWindow(windowType,windowAttributes,&windowBounds,&createdWindow);
    } else
#endif
	createdWindow = NewCWindow(
		0L, &windowBounds,
		"\p",
		false, windowType, (WindowPtr) -1L, windowAttributes, 0);
#endif
	return createdWindow;
}

void SetWindowTitle(int windowIndex,char *title) {
    Str255 tempTitle;
	CopyCStringToPascal(title,tempTitle);
#ifndef IHAVENOHEAD
	if (windowHandleFromIndex(windowIndex))
	SetWTitle(windowHandleFromIndex(windowIndex), tempTitle);
#endif
}

int ioForceDisplayUpdate(void) {
	/* do nothing on a Mac */
	return 0;
}

int ioHasDisplayDepth(int depth) {
	/* Return true if this platform supports the given color display depth. */

	switch (depth) {
	case 1:
	case 2:
	case 4:
//            return false;  //OS-X 10.3.0/1 bug in copybits, force silly manual move
//            break;
	case 8:
	case 16:
	case 32:
		return true;
	}
	return false;
}

int ioScreenDepth(void) {
    GDHandle mainDevice;
    
	mainDevice = getThatDominateGDevice(getSTWindow());
    if (mainDevice == null) 
        return 8;
    
    return (*(*mainDevice)->gdPMap)->pixelSize;
}

#ifndef BROWSERPLUGIN
int ioScreenSize(void) {
	int w, h;
    Rect portRect;
    
	w  = (unsigned) getSavedWindowSize() >> 16;
	h= getSavedWindowSize() & 0xFFFF;

#ifndef IHAVENOHEAD
	if (getSTWindow() == NULL && gWindowsIsInvisible) {
		makeMainWindow();
	}

	if (getSTWindow() != nil) {
            GetPortBounds(GetWindowPort(getSTWindow()),&portRect);
            w =  portRect.right -  portRect.left;
            h =  portRect.bottom - portRect.top;
	}
#endif
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}
#endif

int ioSetCursorARGB(sqInt bitsIndex, sqInt w, sqInt h, sqInt x, sqInt y) {
  return 0;
}

int ioSetCursor(int cursorBitsIndex, int offsetX, int offsetY) {
	/* Old version; forward to new version. */
	ioSetCursorWithMask(cursorBitsIndex, nil, offsetX, offsetY);
	return 0;
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


int ioSetDisplayMode(int width, int height, int depth, int fullscreenFlag) {
	/* Set the window to the given width, height, and color depth. Put the window
	   into the full screen mode specified by fullscreenFlag. */
	

    GDHandle		dominantGDevice;
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

	dominantGDevice = getThatDominateGDevice(getSTWindow());
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

GDHandle	getThatDominateGDevice(WindowPtr window) {
	GDHandle		dominantGDevice=NULL;
#if TARGET_API_MAC_CARBON
	GetWindowGreatestAreaDevice((WindowRef) window,kWindowContentRgn,&dominantGDevice,NULL); 
#else
        dominantGDevice = getDominateDevice((WindowRef) window,&ignore);
#endif
	
	return dominantGDevice;
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
		GetPortBounds(GetWindowPort(theWindow),&windRect);
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
  

#include "SurfacePlugin.h"

int osxGetSurfaceFormat(sqIntptr_t handle, int* width, int* height, int* depth, int* isMSB);
sqIntptr_t osxLockSurface(sqIntptr_t handle, int *pitch, int x, int y, int w, int h);
int osxUnlockSurface(sqIntptr_t handle, int x, int y, int w, int h);
int osxShowSurface(sqIntptr_t handle, int x, int y, int w, int h);


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

void SetupSurface(int whichWindowIndex) {
    registerSurface = (fn_ioRegisterSurface) interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
    unregisterSurface = (fn_ioUnregisterSurface) interpreterProxy->ioLoadFunctionFrom("ioUnregisterSurface","SurfacePlugin");
    (*registerSurface)((sqIntptr_t)whichWindowIndex, &osxTargetDispatch, &surfaceID);
}


int osxGetSurfaceFormat(sqIntptr_t index, int* width, int* height, int* depth, int* isMSB) {
    PixMapHandle pix;
    Rect        rectangle;
    
    pix = GetPortPixMap(GetWindowPort(windowHandleFromIndex(index)));
    *depth= GetPixDepth(pix);
    GetPixBounds(pix,&rectangle);
    *width = rectangle.right - rectangle.left;
    *height = rectangle.bottom - rectangle.top;
    *isMSB = 1;
#warning "fix for intel"
    return 1;
}

sqIntptr_t osxLockSurface(sqIntptr_t index, int *pitch, int x, int y, int w, int h) {
    static int rememberW=0;
    static int offsetTitle=0;
	windowDescriptorBlock *targetWindowBlock = windowBlockFromIndex(index);
    CGrafPtr    windowPort = GetWindowPort(targetWindowBlock->handle);
    PixMapHandle pixMap;
	
    if (!targetWindowBlock->locked) {
		LockPortBits(windowPort);
		targetWindowBlock->locked = ioMSecs();
//		fprintf(stderr,"<L %i> ",ioMSecs());
	}
	
    pixMap =  GetPortPixMap(windowPort);
    *pitch = GetPixRowBytes(pixMap);

    if (rememberW == 0) {
        Rect structureRect;
        RgnHandle rect;

		rememberW = 1;	
        rect = NewRgn();            
        GetWindowRegion(windowHandleFromIndex(index),kWindowTitleBarRgn,rect);
        GetRegionBounds(rect,&structureRect);
        offsetTitle = (structureRect.bottom- structureRect.top)* *pitch;
        DisposeRgn(rect);
    }
    
    return (sqIntptr_t)GetPixBaseAddr(pixMap) + offsetTitle;
}

int osxUnlockSurface(sqIntptr_t index, int x, int y, int w, int h) {
    //NOPE UnlockPortBits(GetWindowPort(windowHandleFromIndex(index))); 
	return 1;
}

int osxShowSurface(sqIntptr_t index, int x, int y, int w, int h) {
	static RgnHandle dirtyRgn = NULL;
	static RgnHandle maskRect;
	extern	long	gSqueakUIFlushPrimaryDeferNMilliseconds;
	windowDescriptorBlock *targetWindowBlock = windowBlockFromIndex(index);
	long now = ioMSecs() - targetWindowBlock->rememberTicker;

	if (dirtyRgn == NULL) {
		dirtyRgn = NewRgn();
		maskRect = NewRgn();
	}
							
	SetRectRgn(maskRect, x, y, x+w, y+h);
	UnionRgn (dirtyRgn, maskRect, dirtyRgn);
	
	if (targetWindowBlock->dirty && ((now >= gSqueakUIFlushPrimaryDeferNMilliseconds) || (now < 0))) {
		if ((ioMSecs() - targetWindowBlock->locked) > 500) {
			UnlockPortBits(GetWindowPort(targetWindowBlock->handle)); 
//			fprintf(stderr,"<U %i> ",ioMSecs());
			targetWindowBlock->locked = 0;
		}
		QDFlushPortBuffer(GetWindowPort(targetWindowBlock->handle), dirtyRgn);
//		fprintf(stderr,"<F %i> ",ioMSecs());
		SetEmptyRgn(dirtyRgn);
		targetWindowBlock->dirty = 0;
		targetWindowBlock->rememberTicker = ioMSecs();
	} else {
		targetWindowBlock->dirty = 1;
//		fprintf(stderr,"<W %i> ",ioMSecs());
	}
	return 1;
}

#if JMMFoo 

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

		
			{
				static int pastTime=0;
				int check;
				static RgnHandle dirtyRgn = NULL;

				if (dirtyRgn == NULL) 
					dirtyRgn = NewRgn();
										
				UnionRgn (dirtyRgn, maskRect, dirtyRgn);
				
				if (((check = (ioMSecs() - pastTime)) > 7) || check < 0) {
					QDFlushPortBuffer(windowPort, dirtyRgn);
					SetEmptyRgn(dirtyRgn);
					pastTime = pastTime + check;
				}
			} 

			
		
#endif 
