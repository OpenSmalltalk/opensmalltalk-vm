/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCWindows.c                                   */
/* Window & OS interface stuff                                            */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
// define this to get lots of debug notifiers
//#define DEBUG
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "sq.h"
#include <kernel.h>

#define longAt(i) (*((int *) (i)))


/* set from header when image file is loaded */
extern int	getSavedWindowSize(void);
extern int	setSavedWindowSize(int value);


#ifndef MIN
#define MIN( a, b )   ( ( (a) < (b) ) ? (a) : (b) )
#define MAX( a, b )   ( ( (a) > (b) ) ? (a) : (b) )
#endif

/*** Variables -- RPC Related ***/
wimp_w			sqWindowHandle = null;
os_dynamic_area_no	SqueakDisplayDA;
extern int		windowActive;
int			pointerBuffer[16] =
				{0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999,
				0x99999999};
os_coord		pointerOffset;
wimp_icon_create	sqIconBarIcon;
extern os_error		privateErr;

/* screen description. Needs updating when screenmode changes */
os_coord		squeakDisplaySize,
			screenSize,
			scalingFactor;
extern os_box		windowVisibleArea;
int			screenBitPerPixel, squeakDisplayDepth;
// osbool squeakDisplayNeedsReversing = true;


/* display bitmap info */
int scanLine, startX, xLen, startY, stopY, pixelsPerWord, pixelsPerWordShift;
void (*reverserFunction)(void);
unsigned int *		displayBitmapIndex;
osspriteop_area *	spriteAreaPtr = NULL;
osspriteop_header *	displaySprite = NULL;
osspriteop_trans_tab *	pixelTranslationTable = NULL;
os_PALETTE (256)	paletteTable;
unsigned int *		displaySpriteBits = NULL;

/*** Functions ***/
void		SetColorEntry(int index, int red, int green, int blue);
void		GetDisplayParameters(void);
extern int	HandleEvents(int);
int		InitRiscOS(void);
void		MouseButtons( wimp_pointer * wblock);
void		SetUpWindow(int w, int h);
void		SetInitialWindowSize(int w, int h);
int		SetupPixmap(int w, int h, int d);
void		SetupPixelTranslationTable(void);
void		SetupPaletteTable(void);
int		platAllocateMemory( int amount);
void		platReportFatalError( os_error * e);
void		platReportError( os_error * e);


/* display related routines  */


void reverseNothing(void) {
/* do nothing, as fast as possible */
}

void reverse_image_1bpps(void) {
unsigned int * srcPtr, *dstPtr;
int j;
	for(j = startY; j < stopY; j += scanLine) {
		srcPtr = displayBitmapIndex + j + startX;
		dstPtr = displaySpriteBits + j + startX;
		{ int i, k;
		unsigned int w, nw;
			for (i=xLen; i--; srcPtr++, dstPtr++) {
				w = (unsigned int ) *srcPtr;
				nw = w & 0x1;
				for (k=31; k--;) {
					w = w >> 1;
					nw = (nw << 1) | (w & 0x1);
				}
				*dstPtr = nw;
			}
		}
	}
}

void reverse_image_2bpps(void) {
unsigned int * srcPtr, *dstPtr;
int j;
	for(j = startY; j < stopY; j += scanLine) {
		srcPtr = displayBitmapIndex + j + startX;
		dstPtr = displaySpriteBits + j + startX;
		{ int i, k;
		unsigned int w, nw;
			for (i=xLen; i--; srcPtr++, dstPtr++) {
				w = (unsigned int ) *srcPtr;
				nw = w & 0x3;
				for (k=15; k--;) {
					w = w >> 2;
					nw = (nw << 2) | (w & 0x3);
				}
				*dstPtr = nw;
			}
		}
	}
}

void reverse_image_4bpps(void) {
unsigned int * srcPtr, *dstPtr;
int j;
	for(j = startY; j < stopY; j += scanLine) {
		srcPtr = displayBitmapIndex + j + startX;
		dstPtr = displaySpriteBits + j + startX;
		{ int i;
		unsigned int w, nw;
			for (i=xLen; i--; srcPtr++, dstPtr++) {
				w = (unsigned int ) *srcPtr;
				nw = w & 0xF;
				w = w >> 4;
				nw = (nw << 4) | (w & 0xF);
				w = w >> 4;
				nw = (nw << 4) | (w & 0xF);
				w = w >> 4;
				nw = (nw << 4) | (w & 0xF);
				w = w >> 4;
				nw = (nw << 4) | (w & 0xF);
				w = w >> 4;
				nw = (nw << 4) | (w & 0xF);
				w = w >> 4;
				nw = (nw << 4) | (w & 0xF);
				w = w >> 4;
				nw = (nw << 4) | (w & 0xF);
				*dstPtr = nw;
			}
		}
	}
}

void reverse_image_bytes(void)  {
unsigned int * srcPtr, *dstPtr;
int j;
	for(j = startY; j < stopY; j += scanLine) {
		srcPtr = displayBitmapIndex + j + startX;
		dstPtr = displaySpriteBits + j + startX;
		{ int i;
		unsigned int w, nw;
			for (i=xLen; i--; srcPtr++, dstPtr++) {
				w = *srcPtr;
				nw = w & 0xFF;
				w = w >>8;
				nw = (nw << 8) | (w & 0xFF);
				w = w >>8;
				nw = (nw << 8) | (w & 0xFF);
				w = w >>8;
				nw = (nw << 8) | (w & 0xFF);
				*dstPtr = nw;
			}
		}
	}
}

void reverse_image_words(void) {
unsigned int * srcPtr, *dstPtr;
int j;
	for(j = startY; j < stopY; j += scanLine) {
		srcPtr = displayBitmapIndex + j + startX;
		dstPtr = displaySpriteBits + j + startX;
		{ int i;
		unsigned int w, nw;
			for (i=xLen; i--; srcPtr++, dstPtr++) {
				w = (unsigned int ) *srcPtr;
				nw = w & 0x1F;
				w = w >> 5;
				nw = (nw << 5) | (w & 0x1F);
				w = w >> 5;
				nw = (nw << 5) | (w & 0x1F);
				w = w >> 6;
				nw = (nw << 6) | (w & 0x1F);
				w = w >> 5;
				nw = (nw << 5) | (w & 0x1F);
				w = w >> 5;
				nw = (nw << 5) | (w & 0x1F);
				*dstPtr = nw;
			}
		}
	}
}

void reverse_image_longs(void) {
unsigned int * srcPtr, *dstPtr;
int j;
	for(j = startY; j < stopY; j += scanLine) {
		srcPtr = displayBitmapIndex + j + startX;
		dstPtr = displaySpriteBits + j + startX;
		{ int i;
		unsigned int w, nw;
			for (i=xLen; i--; srcPtr++, dstPtr++) {
				w = (unsigned int ) *srcPtr;
				nw = w & 0xFF;
				w = w >> 8;
				nw = (nw << 8) | (w & 0xFF);
				w = w >> 8;
				nw = (nw << 8) | (w & 0xFF);
				*dstPtr = nw;
			}
		}
	}
}

void simple_copy_image(void) {
unsigned int * srcPtr, *dstPtr;
int j;
	for(j = startY; j < stopY; j += scanLine) {
		srcPtr = displayBitmapIndex + j + startX;
		dstPtr = displaySpriteBits + j + startX;
		{ int i;
			for (i=xLen; i--; srcPtr++, dstPtr++) {
				*dstPtr = *srcPtr;
			}
		}
	}
}

void DisplayReverseSetup() {
int log2Depth;
	switch (squeakDisplayDepth) {
	case 32:log2Depth=5; reverserFunction = reverse_image_longs; break;
	case 16:log2Depth=4; reverserFunction = reverse_image_words; break;
	case 8: log2Depth=3; reverserFunction = reverse_image_bytes;break;
	case 4: log2Depth=2; reverserFunction = reverse_image_4bpps;break;
	case 2: log2Depth=1; reverserFunction = reverse_image_2bpps;break;
	case 1: log2Depth=0; reverserFunction = reverse_image_1bpps;break;
	default: reverserFunction = reverseNothing; return; 
	}
//	if (!squeakDisplayNeedsReversing)
//		reverserFunction = simple_copy_image;
	/* work out words per scan line */
	pixelsPerWordShift = 5-log2Depth;
	pixelsPerWord= 1 << pixelsPerWordShift;
	scanLine= (squeakDisplaySize.x + pixelsPerWord-1) >> pixelsPerWordShift;
}

void DisplayReverseArea(int x0, int y0, int x1, int y1) {
int stopX;
	startX = (x0 >> pixelsPerWordShift) ;
	stopX  = (x1 + pixelsPerWord -1) >> pixelsPerWordShift;
	xLen = stopX - startX /* +1 */;
	startY = y0 * scanLine;
	stopY  = y1 * scanLine;
	if(stopX <= startX || stopY <= startY) return;
	reverserFunction();
	return;
}

void DisplayPixmap(void) {
/* bitblt the displaySprite to the screen */
extern osspriteop_area *spriteAreaPtr;
extern osspriteop_header *displaySprite;
extern osspriteop_trans_tab *	pixelTranslationTable;
osbool more;
wimp_draw wblock;
os_error * e;
	if ( displaySpriteBits == NULL ) {
		/* flush the damage rectangles */
		wblock.w = sqWindowHandle;
		more = wimp_redraw_window( &wblock );
		while ( more ) {
			xwimp_get_rectangle (&wblock, &more);
		}
		return;
	}
	wblock.w = sqWindowHandle;
	more = wimp_redraw_window( &wblock );
	while ( more ) {
		if ((e = xosspriteop_put_sprite_scaled (
			osspriteop_PTR,
			spriteAreaPtr,
			(osspriteop_id)displaySprite,
			wblock.box.x0, wblock.box.y1-(squeakDisplaySize.y<<scalingFactor.y),
			os_ACTION_OVERWRITE | osspriteop_GIVEN_WIDE_ENTRIES,
			(os_factors const *)0,pixelTranslationTable)) != NULL) {
			if ( spriteAreaPtr != null) {
				platReportError(e);
				return;
			}
		}
		xwimp_get_rectangle (&wblock, &more);
	}
}

void DisplayPixmapNow(void) {
/* bitblt the displaySprite to the screen, not from a wimp_poll */
extern osspriteop_area *spriteAreaPtr;
extern osspriteop_header *displaySprite;
extern osspriteop_trans_tab *	pixelTranslationTable;
osbool more;
wimp_draw wblock;
os_error * e;
	if ( sqWindowHandle == null ) return;
	wblock.w = sqWindowHandle;
	/* set work area to suit these values */
	/* work area extent - set to screen size */
	wblock.box.x0 = 0 ;
	wblock.box.y0 = -screenSize.y<<scalingFactor.y;
	wblock.box.x1 = screenSize.x<<scalingFactor.x;
	wblock.box.y1 = 0;

	more = wimp_update_window( &wblock );
	while ( more ) {
		if ((e = xosspriteop_put_sprite_scaled (
			osspriteop_PTR,
			spriteAreaPtr,
			(osspriteop_id)displaySprite,
			wblock.box.x0, wblock.box.y1-(squeakDisplaySize.y<<scalingFactor.y),
			os_ACTION_OVERWRITE | osspriteop_GIVEN_WIDE_ENTRIES,
			(os_factors const *)0,pixelTranslationTable)) != NULL) {
			if ( spriteAreaPtr != null) {
				platReportError(e);
				return;
			}
		}
		xwimp_get_rectangle (&wblock, &more);
	}
}

void ResizeWindow(void) {
wimp_drag dragBlock;
	PRINTF(("\\t ResizeWindow\n"));
	dragBlock.w = sqWindowHandle;
	dragBlock.type = wimp_DRAG_SYSTEM_SIZE;
	dragBlock.initial.x0 = windowVisibleArea.x0;
	dragBlock.initial.y0 = windowVisibleArea.y0; 
	dragBlock.initial.x1 = windowVisibleArea.x1;
	dragBlock.initial.y1 = windowVisibleArea.y1; 
	wimp_drag_box(&dragBlock);
	return;
}

void SetDefaultPointer(void) {
	xwimp_set_pointer_shape(2, (byte const *)pointerBuffer, 16, 16, 0, 0);
	/* and then return the pointer to no.1 */
	xwimp_set_pointer_shape(1, (byte const *)-1, 0, 0, 0, 0);
}

void SetWindowToTop(void) {
/* raise the window to the top of the window stack */
wimp_window_state wblock;
os_error * e;
	/*  the sqWindowHandle state */
	wblock.w = sqWindowHandle;
	if ((e = xwimp_get_window_state(&wblock)) != NULL) {
		platReportFatalError(e);
		return;
	}
	wblock.next = wimp_TOP;
	/* re-open the window */
	if ( (e = xwimp_open_window((wimp_open *)&wblock)) != NULL) {
		platReportFatalError(e);
		return;
	};
}

int SetWindowParameters(void) {
/* arrange for the window to appear in windowVisibleArea */
wimp_window_state wblock;
os_error * e;
	/*  the sqWindowHandle state */
	wblock.w = sqWindowHandle;
	if ((e = xwimp_get_window_state(&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	/* set size of window */
	wblock.visible.x0 = windowVisibleArea.x0;
	wblock.visible.y0 = windowVisibleArea.y0; 
	wblock.visible.x1 = windowVisibleArea.x1; 
	wblock.visible.y1 = windowVisibleArea.y1; 
	/* insist on 0 scroll offsets */
	wblock.xscroll = 0;
	wblock.yscroll = 0;
	/* re-open the window */
	if ( (e = xwimp_open_window((wimp_open *)&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	};
	/* check the resulting state */
	if ((e = xwimp_get_window_state(&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	windowVisibleArea.x0 =  wblock.visible.x0;
	windowVisibleArea.x1 =  wblock.visible.x1;
	windowVisibleArea.y0 =  wblock.visible.y0;
	windowVisibleArea.y1 =  wblock.visible.y1;

	return true;
}

void GetDisplayParameters(void) {
int bpp;
bits junk;
	/* get the screen size x & y */
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE,
		(os_mode_var)os_MODEVAR_XWIND_LIMIT, &screenSize.x, &junk);
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE,
		(os_mode_var)os_MODEVAR_YWIND_LIMIT, &screenSize.y, &junk);
	/* find the screen depth */
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE,
		(os_mode_var)os_MODEVAR_LOG2_BPP, &bpp, &junk);
	/* this gets us log2 of actual bpp, so convert back */
	screenBitPerPixel = 1<<bpp;
	/* find the OSunit to pixel scaling factors */
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE,
		(os_mode_var)os_MODEVAR_XEIG_FACTOR, &scalingFactor.x, &junk);
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE,
		(os_mode_var)os_MODEVAR_YEIG_FACTOR, &scalingFactor.y, &junk);
}

void DisplayModeChanged(void){
/* the display mode has been changed so we need to refetch all the details */
	GetDisplayParameters();
	SetupPixelTranslationTable();
	SetWindowParameters();
	DisplayReverseSetup();
}

int CreateSpriteArea( int size) {
/* create a RiscOS sprite which will be use by Squeak as its Display bitmap */
int ptr;
os_error *e;
int daSizeLimit;
byte * daBaseAddress;
	if ((e = xosdynamicarea_create (
				os_DYNAMIC_AREA_APPLICATION_SPACE,
				size,
				(byte const*)-1,
				(bits)128,
				-1,
				NULL,
				NULL,
				"Squeak Display Sprite",
				&SqueakDisplayDA,
				&daBaseAddress,
				&daSizeLimit
			)) !=NULL) {
		platReportFatalError(e);
		return false;
	}

	ptr = (int) daBaseAddress;
	if ( ptr == NULL) {
		privateErr.errnum = 0;
		sprintf( privateErr.errmess, "Squeak failed to malloc sprite area of size &%0x\n", size);
		platReportFatalError(&privateErr);
			return false;
	}
	/* setup the sprite area . Start it at the beginning of the allocated chunk */
	spriteAreaPtr = (osspriteop_area *)(ptr); 
	spriteAreaPtr->size = size;
	spriteAreaPtr->sprite_count = 1;
	spriteAreaPtr->first = 16;
	if ( (e = xosspriteop_clear_sprites( osspriteop_USER_AREA,  spriteAreaPtr)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	return ptr;
}

void SetupPixelTranslationTable(void) {
/* derive the pixel translation table suited to the current combination */
/* of Display mode and screen mode */
os_error * e;
int tableSize, log2bpp;
bits junk;
os_palette * currPal;
	/* set the appropriate palette */
	if ( ( e = xos_read_mode_variable( displaySprite->mode, os_MODEVAR_LOG2_BPP, &log2bpp, &junk)) != NULL) {
		platReportFatalError(e);
		return ;
	}

	/* fudge the pixel table to cope with the apparent fault in colourtrans_generate_table */
	if ((log2bpp <= 3) ) {
		int i, val;
		/* realloc the table to the new size. Use 1024 bytes since that is */
		/* plenty big enough for even 32bpp, but is not awkwardly big */
		pixelTranslationTable = realloc( pixelTranslationTable, 1024);
		for( i = 0; i<256; i++) {
			xcolourtrans_return_colour_number_for_mode((os_colour)(paletteTable.entries[i]), colourtrans_CURRENT_MODE, (os_palette*)colourtrans_CURRENT_PALETTE, &val);
			if ( screenBitPerPixel <= 8) {
				pixelTranslationTable->c[i] = (byte)(val & 0xFF);
			} else  {
				if ( screenBitPerPixel == 16) {
					pixelTranslationTable->c[i<<1] = (byte)(val & 0xFF);
					pixelTranslationTable->c[(i<<1)+1] = (byte)((val>>8) & 0xFF);
				} else { /* must be 32bpp */
					pixelTranslationTable->c[i<<2] = (byte)(val & 0xFF);
					pixelTranslationTable->c[(i<<2)+1] = (byte)((val>>8) & 0xFF);
					pixelTranslationTable->c[(i<<2)+2] = (byte)((val>>16) & 0xFF);
					pixelTranslationTable->c[(i<<2)+3] = (byte)((val>>24) & 0xFF);
				}
			}
		}
	} else {
		currPal = (log2bpp > 3) ? colourtrans_CURRENT_PALETTE : (os_palette*)&paletteTable;
		/* call colourTrans_generate_table to find out how big the tx table has to be */
		if ( (e = xcolourtrans_generate_table(  displaySprite->mode, currPal, colourtrans_CURRENT_MODE, colourtrans_CURRENT_PALETTE, NULL, colourtrans_RETURN_WIDE_ENTRIES, NULL, NULL, &tableSize )) != NULL) {
			platReportFatalError(e);
			return ;
		}
		/* realloc the table to the new size */
		pixelTranslationTable = realloc( pixelTranslationTable, tableSize);
		
		/* call colourTrans_generate_table to build the tx table  */
		if ( (e = xcolourtrans_generate_table(  displaySprite->mode, currPal, colourtrans_CURRENT_MODE, colourtrans_CURRENT_PALETTE, pixelTranslationTable,  colourtrans_RETURN_WIDE_ENTRIES, NULL, NULL, &tableSize )) != NULL) {
			platReportFatalError(e);
			return ;
		}
	}
}

void SetColorEntry(int index, int red, int green, int blue) {
#define blah(arg)  ((arg)>>8)
	paletteTable.entries[index] =  (os_colour)(blah(blue)<<os_BSHIFT | blah(green) <<os_GSHIFT | blah(red) <<os_RSHIFT | 0x0);
}

void SetupPaletteTable(void) {
/* build a palette for the <256 colour display bitmaps; will be used */
/* to generate the pixel translation table later */
int i,r,g,b;

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
				if (i > 255) {
					privateErr.errnum = 0;
					sprintf( privateErr.errmess, "index out of range in color table compuation\n");
					platReportFatalError(&privateErr);
				}
				SetColorEntry(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
			}
		}
	}
}

int SetupPixmap(int w, int h, int d) {
/* create the display sprite */
os_error * e;
int sprMode;
	/* derive the sprite mode from the depth(d) requested. */
#define SPR_MODE_WORD(arg) ((arg<<osspriteop_TYPE_SHIFT) | (180<<osspriteop_YRES_SHIFT) | (180<<osspriteop_XRES_SHIFT) | 1 )
	switch (d) {
		case 1: sprMode = SPR_MODE_WORD(osspriteop_TYPE1BPP); break;
		case 2: sprMode = SPR_MODE_WORD(osspriteop_TYPE2BPP); break;
		case 4: sprMode = SPR_MODE_WORD(osspriteop_TYPE4BPP); break;
		case 8: sprMode = SPR_MODE_WORD(osspriteop_TYPE8BPP); break;
		case 16: sprMode = SPR_MODE_WORD(osspriteop_TYPE16BPP); break;
		case 32: sprMode = SPR_MODE_WORD(osspriteop_TYPE32BPP); break;
	}

	/* now clear the sprite area and create a sprite in it */
	if ( (e = xosspriteop_clear_sprites( osspriteop_USER_AREA,  spriteAreaPtr)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	if ( (e = xosspriteop_create_sprite(osspriteop_NAME, spriteAreaPtr, "SqDisplayBits", false, w, h,(os_mode)sprMode)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	displaySprite = (osspriteop_header *)((int)spriteAreaPtr + spriteAreaPtr->first);
	SetupPixelTranslationTable();
	/* the displaySpriteBits ptr will be used when copying bits
	 * from the Display object to a RiscOS pixel format buffer
	 */
	displaySpriteBits = (unsigned int *)((int)displaySprite + displaySprite->image);
	return true;
}

void SetUpWindow(int width, int height) {
/* create a window of width and height, centred on the screen
 * since it is possible that width and height are not possible on the screen
 * we check against the screen metrics and modify, then set the
 * global values as required.
 */
wimp_window wblock;
os_error * e;
wimp_w w;
os_coord origin, size;
extern char * windowLabel;

	PRINTF(("\\t initial open window\n"));

	/*  find the screen width, height, bpp etc */
	GetDisplayParameters();

	/* fill-in window block */

	/* initial visible area on screen -
	 * almost irrelevant, but we need to set something */
	wblock.visible.x0 = 800;
	wblock.visible.y0 = 1200;
	wblock.visible.x1 = 1800;
	wblock.visible.y1 = 2200;
	/* scroll offsets */
	wblock.xscroll = 0;
	wblock.yscroll = 0;
	/* open as top window */
	wblock.next = (wimp_w)wimp_TOP;
	/* window flags */
	wblock.flags = wimp_WINDOW_NEW_FORMAT | wimp_WINDOW_MOVEABLE
			| wimp_WINDOW_BOUNDED_ONCE | wimp_WINDOW_TITLE_ICON
			| wimp_WINDOW_CLOSE_ICON | wimp_WINDOW_BACK_ICON
			| wimp_WINDOW_IGNORE_XEXTENT | wimp_WINDOW_IGNORE_YEXTENT;
	/* colours */
	wblock.title_fg = wimp_COLOUR_BLACK;
	wblock.title_bg = wimp_COLOUR_LIGHT_GREY;
	wblock.work_fg = wimp_COLOUR_BLACK;
	wblock.work_bg = wimp_COLOUR_TRANSPARENT;
	wblock.scroll_outer = wimp_COLOUR_MID_LIGHT_GREY;
	wblock.scroll_inner = wimp_COLOUR_VERY_LIGHT_GREY;
	wblock.highlight_bg = wimp_COLOUR_CREAM;
	/* work area extent - set to screen size */
	wblock.extent.x0 = 0 ;
	wblock.extent.y0 = -screenSize.y<<scalingFactor.y;
	wblock.extent.x1 = screenSize.x<<scalingFactor.x;
	wblock.extent.y1 = 0;
	/* titlebar flags */
	wblock.title_flags = wimp_ICON_TEXT | wimp_ICON_INDIRECTED
		| wimp_ICON_FILLED  | wimp_ICON_HCENTRED
		| wimp_ICON_VCENTRED | wimp_ICON_BORDER;
	/* work area flags */
	wblock.work_flags=(wimp_BUTTON_CLICK)
		<<wimp_ICON_BUTTON_TYPE_SHIFT;
	/* sprite area +1 apparently refers to WIMP area */
	wblock.sprite_area = (osspriteop_area *)1;
	/* minimum window size allowed */
	wblock.xmin = (short)100;
	wblock.ymin = (short)100;
	/* title data; if the -windowlabel vm option was set, use its arg
	 * instead of the image pathname */
	if( strlen(windowLabel)) {
		wblock.title_data.indirected_text.text =  windowLabel;
		wblock.title_data.indirected_text.validation = (char*)-1;
		wblock.title_data.indirected_text.size = strlen(windowLabel);
	} else {
		wblock.title_data.indirected_text.text =  &imageName[0];
		wblock.title_data.indirected_text.validation = (char*)-1;
		wblock.title_data.indirected_text.size = strlen(imageName);
	}
	/* icon count Assuming .icons=0 is ok for no icons ? */
	wblock.icon_count = 0;
	/* wblock.icons = (wimp_icon *)NULL;*/

	/* call wimp_createWindow */
	if ( (e = xwimp_create_window(&wblock, &w)) != NULL) {
		platReportFatalError(e);
		return;
	}
	/* save the window handle */
	sqWindowHandle = w;
	/* create a default no.2 pointer pixmap */
	SetDefaultPointer();

	/* set the size of the SQ window.
	 * don't make it bigger than the screen size and centre it 
	 */

	/* maximum size is screen size */
	size.x  = MIN( width, screenSize.x);
	size.y  = MIN(height, screenSize.y);

	/* default origin is meant to centre the window */
	origin.x = (int)(screenSize.x - size.x) / 2;
	origin.y = (int)(screenSize.y + size.y) / 2;
	windowVisibleArea.x0 = origin.x<<scalingFactor.x;
	windowVisibleArea.y0 = origin.y<<scalingFactor.y;
	windowVisibleArea.x1 = (origin.x + size.x)<<scalingFactor.x;
	windowVisibleArea.y1 = (origin.y + size.y)<<scalingFactor.y;

	/* actually set the window size - may modify windowVisibleArea */
	SetWindowParameters();
}

int SetDisplayBitmap( int width, int height, int depth) {
/* setup the display bitmap */
int byteSize;
	/* save the dimensions of this Display object */
	squeakDisplaySize.x = width;
	squeakDisplaySize.y = height;
	squeakDisplayDepth  = depth>0 ?depth: -depth;
//	if ( depth < 0 ) squeakDisplayNeedsReversing = false;
//	else squeakDisplayNeedsReversing = true;

	/* if there is no stWindow yet, open the main window */
	if (sqWindowHandle == null)
		SetUpWindow(squeakDisplaySize.x, squeakDisplaySize.y);
	/* it is possible that the window is smaller than the
	 * requested width@height but the bitmap MUST be
	 * that size or we will have great fun trying to do
	 * the reversal echoing.
	 */ 

	/* create the RiscOS pixmap to the right dimensions */
	byteSize = ((squeakDisplaySize.x + 3)& ~3)  *
		squeakDisplaySize.y * squeakDisplayDepth /8 ;
	byteSize += 4096;
	if ( spriteAreaPtr == NULL ) {
		/* if no sprite area yet, create one */
		CreateSpriteArea( byteSize );
	} else if ( spriteAreaPtr->size < byteSize) {
		/* current size is too small, so free it and recreate */
		xosdynamicarea_delete ( SqueakDisplayDA );
		CreateSpriteArea( byteSize );
	} 
	/* build the sprite area, the actual sprite and translation table */
	SetupPixmap(squeakDisplaySize.x, squeakDisplaySize.y,
			squeakDisplayDepth);

	DisplayReverseSetup();

	return true;
}

/*** I/O Primitives ***/

int ioScreenSize(void) {
/* return the size of the SQ window in use,
   or the default size held in the image */
int w, h;
int maxWidth, maxHeight;
int minWidth = 100, minHeight = 100;

	if (sqWindowHandle != null) {
		/* get extent from window object */
		w = (windowVisibleArea.x1 - windowVisibleArea.x0)
				>>scalingFactor.x;
		h = ( windowVisibleArea.y1 - windowVisibleArea.y0)
			>> scalingFactor.y;
		PRINTF(("\\t ioScreenSize %d@%d\n", w, h));
	} else {/* derive from saved size in image 
		   if there's no window yet, we need to check the
		   screen metrics to make sure we
		   don't make too big a window later */
		GetDisplayParameters();
		w = (unsigned) getSavedWindowSize() >> 16 ;
		h = getSavedWindowSize() & 0xFFFF;
		/* maximum size is screen size (minus a little) */
		maxWidth  = (int)screenSize.x ;
		maxHeight = (int)(screenSize.y * 0.9);
		w = MAX(w, minWidth);
		w = MIN(w, maxWidth);
		h = MAX(h, minHeight);
		h = MIN(h, maxHeight);
	}

	return (w << 16) | (h & 0xFFFF);
}



int ioSetCursorWithMask(int cursorBitsIndex, int cursorMaskIndex, int offsetX, int offsetY) {
/* Move 1-bit form to pointer buffer and use mask to affect result. Remember RPC pointer is 2-bits/pixel to allow 3 colours + mask. As of Sq2.2, there can also be a mask 1-bit form specified.
mask	cursor
  0		0		transparent
  1		1		black
  1		0		white
  0		1		invert ?? Seems rather dumb-Mac */
int i;
os_error *e;

	for (i = 0; i < 16; i++) {
		register int cursorWord, maskWord;
		register int j,line;
		cursorWord = (checkedLongAt(cursorBitsIndex + (4 * i)) ) >>16;
		 if (cursorMaskIndex != NULL) {
			maskWord = (checkedLongAt(cursorMaskIndex + (4 * i)) ) >>16;
		} else
			maskWord = cursorWord;
		line = 0;
		for(j = 15; j >= 0; j--) {
			/* if the mask bit is 1, set 'white' and only
			   then check the cursor word.
			   if it is 1 as well, set 'black' */
			if(maskWord & (1<<(j))) {
				line |= (1<< ((15-j)<<1));
				if(cursorWord & (1<<(j))) 
					line |= (2<< ((15-j)<<1));
			}
		}
		pointerBuffer[i] = line;
	}
	pointerOffset.x = MIN(-offsetX, 15);
	pointerOffset.y = MIN(-offsetY, 15) ;
	if ( windowActive) {
		/* turn on pointer 2 */
		e = xwimp_set_pointer_shape(2, (byte const *)&pointerBuffer, 16, 16, pointerOffset.x, pointerOffset.y );
	}

	return true;
}

int ioSetCursor(int cursorBitsIndex, int offsetX, int offsetY) {
/* older API for cursor setting */
	return ioSetCursorWithMask(cursorBitsIndex, NULL, offsetX, offsetY);
}

int ioSetFullScreen(int fullScreenWanted) {
/* if fullScreenWanted and we aren't already running fullScreen,
   change the window size and store the current origin and size
   for a later restore.
   if !fullScreenWanted and we are running fullScreen, restore those saved
   values
*/
static os_box prevSize = {0,0,0,0};
static int fullScreen = false;

	if (fullScreenWanted && !fullScreen) {
		/* save the current window size */
		prevSize.x0 = windowVisibleArea.x0;
		prevSize.y0 = windowVisibleArea.y0;
		prevSize.x1 = windowVisibleArea.x1;
		prevSize.y1 = windowVisibleArea.y1;
		/* set the fullscreen window size */
		windowVisibleArea.x0 = 0;
		windowVisibleArea.y0 = 0;
		windowVisibleArea.x1 = screenSize.x<<scalingFactor.x;
		windowVisibleArea.y1 = screenSize.y<<scalingFactor.y;
		SetWindowParameters();
		/* save the new size in case the image is saved */
		setSavedWindowSize(((windowVisibleArea.x1
			   - windowVisibleArea.x0)>>scalingFactor.x << 16)
			+ ((windowVisibleArea.y1
			  - windowVisibleArea.y0)>>scalingFactor.y & 0xFFFF));
		fullScreen = true;
		displaySpriteBits = NULL;
		return true;
	}

	if (!fullScreenWanted && fullScreen) {
		windowVisibleArea.x0 = prevSize.x0;
		windowVisibleArea.y0 = prevSize.y0;
		windowVisibleArea.x1 = prevSize.x1;
		windowVisibleArea.y1 = prevSize.y1;
		SetWindowParameters();
		/* save the restored size in case the image is saved */
		setSavedWindowSize(((windowVisibleArea.x1
			   - windowVisibleArea.x0)>>scalingFactor.x << 16)
			+ ((windowVisibleArea.y1
			  - windowVisibleArea.y0)>>scalingFactor.y & 0xFFFF));
		fullScreen = false;
		displaySpriteBits = NULL;
		return true;
	}

	return true;
}

int ioShowDisplay( int dispBitsIndex, int width, int height, int depth, int affectedL, int affectedR, int affectedT, int affectedB) {
os_error *e;
	if(affectedR <= affectedL || affectedT >= affectedB) return true;

	if( displaySpriteBits == NULL ||
		squeakDisplaySize.x != width ||
		squeakDisplaySize.y != height ||
		squeakDisplayDepth != depth) {
		/* if the displaySprite is not set up, sort it out */
		SetDisplayBitmap( width, height, depth);
	}

	/* transform the Display bits to the displaySprite */
	displayBitmapIndex = (unsigned int *)dispBitsIndex;
	DisplayReverseArea(affectedL, affectedT, affectedR, affectedB);

	PRINTF(("\\t ioShowDisplay\n"));
	/* inform the Wimp of the affected area,
	   scaled for the display mode etc */
	if( (e = xwimp_force_redraw( sqWindowHandle,
				affectedL<<scalingFactor.x,
				0-(affectedB<<scalingFactor.y),
				affectedR<<scalingFactor.x,
				0-(affectedT<<scalingFactor.y))) != NULL) {
		platReportError(e);
		return false;
	}
	return true;
}

int ioForceDisplayUpdate(void) {
	PRINTF(("\\t ioForceDisplayUpdate"));
	//ioProcessEvents();
	DisplayPixmapNow();
}

int ioSetDisplayMode(int width, int height, int depth, int fullScreenFlag) {
/* if fullScreenFlag, we are to try to change to a screen mode that matches
 * width, height and depth and then go fullscreen in that mode. Remember
 * the original screen mode _even if we change several times _. Somehow..
 * if not fullScreenFlag, simply change the window size.
 * Fail if we can't meet the request 'reasonably'.
 */
static os_box prevSize = {0,0,0,0}; 
	if (fullScreenFlag) {
		/* find out if we can do a screen mode change to requested size.
		 * fail if not.
		 * save the current screen mode UNLESS we already have one saved
		 * save current window origin
		 * change screen mode
		 * set to fullScreen mode (what if we already were?)
		 */
		return false;
	}
	if (!fullScreenFlag) {
		/* IF we have a saved screen mode, return to it and clear the
		 * saved value (use it as a flag)
		 * restore saved origin point as well
		 * The only time we change the window size is when
		 * fullscreen is false  */
		/* save the current window size. Not sure why since
		 * there is no api to restore it right now... */
		prevSize.x0 = windowVisibleArea.x0;
		prevSize.y0 = windowVisibleArea.y0;
		prevSize.x1 = windowVisibleArea.x1;
		prevSize.y1 = windowVisibleArea.y1;
		/* set the fullscreen window size */
		windowVisibleArea.y0 = windowVisibleArea.y1
			- (height<<scalingFactor.y);
		windowVisibleArea.x1 = (windowVisibleArea.x0
			+ width<<scalingFactor.x);
		SetWindowParameters();
		/* save the new size in case the image is saved */
		setSavedWindowSize(((windowVisibleArea.x1
			   - windowVisibleArea.x0)>>scalingFactor.x << 16)
			+ ((windowVisibleArea.y1
			  - windowVisibleArea.y0)>>scalingFactor.y & 0xFFFF));
		displaySpriteBits = NULL;
		return true;
	}

	return true;
}

int ioScreenDepth(void) {
// what is the bpp setting of the screen right now?
	return screenBitPerPixel;
}

int ioHasDisplayDepth(int bitsPerPixel) {
// return true for all supported bpp supported. 
	switch(bitsPerPixel) {
// -ve numbers invoke a littleendian display - doesn't quite work for
// some reason.
//		case -8:
//		case -16:
//		case -24:
//		case -32:
		case 1:
		case 2:
		case 4:
		case 8:
		case 16:
		case 24:
		case 32:
		 return true;
		default: return false;
	}
}

