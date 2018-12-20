//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCWindows.c
// It implements the interface to the windows, displaying the Squeak screen
// converting the big-endian Mac format pixels to RISC OS format, handling
// the palette differences and providing management of the HostWindow interface

// define this to get lots of debug notifiers
//#define DEBUG
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "sq.h"
#include <kernel.h>
#include <ctype.h>


/* set from header when image file is loaded */
extern int	getSavedWindowSize(void);
extern int	setSavedWindowSize(int value);


/*** Variables -- RPC Related ***/


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
os_coord			pointerOffset;
wimp_icon_create	sqIconBarIcon;
extern os_error		privateErr;

/* screen description. Needs updating when screenmode changes */
os_coord			screenSizeP,
					scalingFactor;
int					screenBitPerPixel;

windowDescriptorBlock *windowListRoot = NULL;
windowDescriptorBlock *rootWindow; // special case root window, especially for testing

/* display bitmap info */
unsigned int *		displaySpriteBits; // the sprite data
int					scanLine, startX, xLen, startY, stopY;
void (*reverserFunction)(void);
unsigned int *		displayBitmapIndex;
osspriteop_area *	spriteAreaPtr = NULL;
os_PALETTE (256)	paletteTable;

/*** Functions ***/
void		SetColorEntry(int index, int red, int green, int blue);
void		GetDisplayParameters(void);
extern int	HandleEventsNotTooOften(void);
extern int	HandleEvents(void);
void		CreateWindow(windowDescriptorBlock * currentWindow);
void		SetInitialWindowSize(int w, int h);
int			CreateSprite(windowDescriptorBlock * currentWindow);
void		SetupPixelTranslationTable(windowDescriptorBlock * currentWindow);
void		SetupPaletteTable(void);
extern void		platReportFatalError( os_error * e);
extern void		platReportError( os_error * e);

/* Display related stuff */

void GetDisplayParameters(void) {
// Read the screen metrics - size, bits per pixels, pixel<->os unit
// scaling factors
int bpp;
bits junk;
	/* get the screen size x & y */
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE,
		(os_mode_var)os_MODEVAR_XWIND_LIMIT, &screenSizeP.x, &junk);
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE,
		(os_mode_var)os_MODEVAR_YWIND_LIMIT, &screenSizeP.y, &junk);
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
#if 0
// dont implement now
	GetDisplayParameters();
	SetupPixelTranslationTable();
	SetWindowBounds(daWindow);
#endif
}


void SetDefaultPointer(void) {
/* setup the pointer buffer as shape #2 for use in the Squeak window
        In theory this ought to be replaced with calls to xwimpspriteop_set_pointer_shape() */
	xwimp_set_pointer_shape(2, (byte const *)pointerBuffer, 16, 16, 0, 0);
	/* and then return the pointer to no.1 */
	xwimp_set_pointer_shape(1, (byte const *)-1, 0, 0, 0, 0);
}

/* window list management */
/* we maintain a linked list of windowDescriptorBlocks describing each of the window created and used.*/

windowDescriptorBlock *windowBlockFromIndex(int windowIndex) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->windowIndex == windowIndex) return entry;
		entry = entry->next;
	}
	return NULL;
}

windowDescriptorBlock *windowBlockFromHandle(wimp_w windowHandle) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->handle == windowHandle) return entry;
		entry = entry->next;
	}
	return NULL;
}


wimp_w windowHandleFromIndex(int windowIndex)  {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->windowIndex == windowIndex) return entry->handle;
		entry = entry->next;
	}
	return NULL;
}

int windowIndexFromHandle(wimp_w windowHandle) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->handle == windowHandle) return entry->windowIndex;
		entry = entry->next;
	}
	return NULL;
}

int windowIndexFromBlock( windowDescriptorBlock * thisWindow) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry == thisWindow) return entry->windowIndex;
		entry = entry->next;
	}
	return NULL;
}

windowDescriptorBlock *AddWindowBlock(void) {
/* create a new entry in the linkedlist of windows.
 * If the calloc fails, return NULL which will then go back to the
 * prim and fail it cleanly.
 * Initialize the block to a sensible state
 */
static int nextIndex = 1;
windowDescriptorBlock *thisWindow;
	thisWindow = (windowDescriptorBlock*) calloc(1, sizeof(windowDescriptorBlock));
	if ( thisWindow == NULL) {
		return NULL;
	}
	thisWindow->next = windowListRoot;
	thisWindow->windowIndex = nextIndex++;
	thisWindow->handle = null;
	thisWindow->displaySprite = null;
	thisWindow->pixelTranslationTable = null;
	windowListRoot = thisWindow;
	return windowListRoot;
}

/*
 * RemoveWindowBlock:
 * Remove the given entry from the list of windows.
 * free it, if found.
 */
static int RemoveWindowBlock(windowDescriptorBlock * thisWindow) {
windowDescriptorBlock *prevEntry;

	/* Unlink the entry from the module chain */
	if(thisWindow == windowListRoot) {
		windowListRoot = thisWindow->next;
	} else {
		prevEntry = windowListRoot;
		while(prevEntry->next != thisWindow) {
			prevEntry = prevEntry->next;
			if (prevEntry == null) return null;
		}
		prevEntry->next = thisWindow->next;
	}
	free(thisWindow);
	return 1;
}

/* displaying bitmap related routines  */
/* we have to do pixel transformations as part of converting from a stupid big-endian Form layout to RISC OSs format */

void reverseNothing(void) {
/* do nothing, as fast as possible */
}

void reverse_image_1bpps(void) {
/* reverse the order of each bit winth the word */
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
/* swap 2-bit chunks ofwords */
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
/* swap 4-bit chunks of words */
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
/* swap byte chunks of words */
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
/* swap 15-bit chunks out of 16 bit words within the 32-bit word; we askip over the alpha bit assumed in other OSs */
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
                                // shift an extra bit to drop the alpha bit
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
/* swap 24-bit chunks out of 32-bit words. Skip the alpha bit assumed in some other OSs */
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
/* yay - no swapping version for some usages */
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

void DisplayReverseArea(windowDescriptorBlock * thisWindow, int x0, int y0, int x1, int y1) {
/* we have to process each pixel in the rectangle */
int stopX, pixelsPerWord, pixelsPerWordShift;
#ifdef DEBUG
unsigned int startTime, stopTime;
	startTime = millisecondTimerValue();
#endif
	switch (thisWindow->squeakDisplayDepth) {
	case 32:pixelsPerWordShift = 0;
			pixelsPerWord = 1;
			reverserFunction = reverse_image_longs; break;
	case 16:pixelsPerWordShift = 1;
			pixelsPerWord = 2;
			reverserFunction = reverse_image_words; break;
	case 8: pixelsPerWordShift = 2;
			pixelsPerWord = 4;
			reverserFunction = reverse_image_bytes;break;
	case 4: pixelsPerWordShift = 3;
			pixelsPerWord = 8;
			reverserFunction = reverse_image_4bpps;break;
	case 2: pixelsPerWordShift = 4;
			pixelsPerWord = 16;
			reverserFunction = reverse_image_2bpps;break;
	case 1: pixelsPerWordShift = 5;
			pixelsPerWord = 32;
			reverserFunction = reverse_image_1bpps;break;
	default: return; // something weird - abandon it
	}
	startX = (x0 >> pixelsPerWordShift) ;
	stopX  = (x1 + pixelsPerWord -1) >> pixelsPerWordShift;
	xLen = stopX - startX /* +1 */;
	scanLine = (thisWindow->bitmapExtentP.x + pixelsPerWord-1)
					>> pixelsPerWordShift;
	startY = y0 * scanLine;
	stopY  = y1 * scanLine;
	displaySpriteBits = (unsigned int *)((int)thisWindow->displaySprite
			+ thisWindow->displaySprite->image);
	reverserFunction();
#ifdef DEBUG
{int i; for(i=0; i<1; i++) {reverserFunction();}} // loop makes for multiple runs of the function make for better timing accuracy  - set the count to 9 for 10X etc
	stopTime = millisecondTimerValue();
	PRINTF(("\\t DisplayReverseArea @ %i for w:%d h:%d took:%d uSec\n", startTime, x1 - x0, y1 - y0, stopTime - startTime));
#endif
	return;
}

void DisplayPixmap(wimp_draw * wblock) {
/* bitblt the displaySprite to the screen */
extern osspriteop_area *spriteAreaPtr;
osbool more;
os_error * e;
windowDescriptorBlock * thisWindow;

	/* need the window block with this handle */
	thisWindow = (windowDescriptorBlock *)windowBlockFromHandle(wblock->w);

	if ( thisWindow->displaySprite == NULL ) {
                /* there's no window set up yet, so flush the damage rectangles */
		more = wimp_redraw_window( wblock );
		while ( more ) {
			xwimp_get_rectangle (wblock, &more);
		}
		return;
	}
        /* for each damage region in this window, update the display by writing the rectangle of our displaySprite
           with the appropriate scaling and pixel translation table. It really ought to be simpler than this */
	more = wimp_redraw_window( wblock );
	while ( more ) {
//		PRINTF(("\\t display pixmap l:%d t:%d r:%d b:%d\n", wblock->clip.x0, wblock->clip.y1, wblock->clip.x1, wblock->clip.y0));
		PRINTF(("\\t DisplayPixmap w:%d h:%d\n", (wblock->clip.x1- wblock->clip.x0)>>scalingFactor.x, (wblock->clip.y1 - wblock->clip.y0)>>scalingFactor.y));
#ifdef DEBUG
// do the screen update 10 times to get a measure of the time taken up by it
{
int i;
unsigned int startTime, stopTime;
	startTime = millisecondTimerValue();
for (i=0; i<1; i++) { // loop makes for multiple runs of the function make for better timing accuracy - set the count to 10 for 10X etc
#endif //DEBUG
		if ((e = xosspriteop_put_sprite_scaled (
			osspriteop_PTR,
			spriteAreaPtr,
			(osspriteop_id)thisWindow->displaySprite,
			wblock->box.x0,
			wblock->box.y1 - ((thisWindow->bitmapExtentP.y)<<scalingFactor.y),
			os_ACTION_OVERWRITE | osspriteop_GIVEN_WIDE_ENTRIES,
			(os_factors const *)0,
			thisWindow->pixelTranslationTable)) != NULL) {
			if ( spriteAreaPtr != null) {
				platReportError(e);
				return;
			}
		}
#ifdef DEBUG
}
	stopTime = millisecondTimerValue();
	PRINTF(("\\t DisplayPixmap took:%d uSec\n", stopTime - startTime));

}
#endif // DEBUG
		xwimp_get_rectangle (wblock, &more);
	}
}

#if 0
void DisplayPixmapNow(void) {
/* bitblt the displaySprite to the screen, not from a wimp_poll
 * it works but seems to suck up a huge % of cpu
 */
extern osspriteop_header *displaySprite;
extern osspriteop_trans_tab *	pixelTranslationTable;
osbool more;
wimp_draw wblock;
os_error * e;

	if ( sqWindowHandle == null )
		return;

	wblock.w = sqWindowHandle;
	/* set work area to suit these values */
	/* work area extent - set to screen size */
	wblock.box.x0 = 0 ;
	wblock.box.y0 = -screenSizeP.y<<scalingFactor.y;
	wblock.box.x1 = screenSizeP.x<<scalingFactor.x;
	wblock.box.y1 = 0;

	PRINTF(("\\t DisplayPixmapNow\n"));
	more = wimp_update_window( &wblock );
	while ( more ) {
		if ((e = xosspriteop_put_sprite_scaled (
			osspriteop_PTR,
			spriteAreaPtr,
			(osspriteop_id)displaySprite,
			wblock.box.x0, wblock.box.y1-(bitmapExtentP.y<<scalingFactor.y),
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
#endif


/* window status */

void ResizeWindow(windowDescriptorBlock * thisWindow) {
wimp_drag dragBlock;
	PRINTF(("\\t ResizeWindow %x\n", (int)thisWindow->handle));
	dragBlock.w = thisWindow->handle;
	dragBlock.type = wimp_DRAG_SYSTEM_SIZE;
	dragBlock.initial.x0 = thisWindow->visibleArea.x0;
	dragBlock.initial.y0 = thisWindow->visibleArea.y0;
	dragBlock.initial.x1 = thisWindow->visibleArea.x1;
	dragBlock.initial.y1 = thisWindow->visibleArea.y1;
	wimp_drag_box(&dragBlock);
	/* when the drag is finished a window open_Request is sent,
	 * and WindowOpen called to reset the cached size etc */
	return;
}

void SetWindowToTop(int index) {
/* raise the window to the top of the window stack */
wimp_window_state wblock;
os_error * e;
	/*  the sqWindowHandle state */
	wblock.w = windowHandleFromIndex(index);
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


void SetupWindowTitle(void) {
/* set the root window title string.
 * if the -windowlabel: option was used, the title is the
 * string given; if it's too long only the last WindowTitleLength (150) chars are used.
 */
extern char * windowLabel;
char * string;
	if ( windowLabel == NULL) {
		string = getImageName();
	} else {
		string = windowLabel;
	}
	if ( strlen(string) > WindowTitleLength ) {
		string += (strlen(string) - WindowTitleLength);
	}
	strcpy(rootWindow->title, string);
}

int SetWindowBounds(windowDescriptorBlock * thisWindow) {
/* arrange for the window to appear in window->visibleArea */
wimp_window_state wblock;
os_error * e;
	/* get the window handle state */
	wblock.w = thisWindow->handle;
	if ((e = xwimp_get_window_state(&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	/* set size of window */
	wblock.visible.x0 = thisWindow->visibleArea.x0;
	wblock.visible.y0 = thisWindow->visibleArea.y0;
	wblock.visible.x1 = thisWindow->visibleArea.x1;
	wblock.visible.y1 = thisWindow->visibleArea.y1;
	/* insist on 0 scroll offsets */
	wblock.xscroll = 0;
	wblock.yscroll = 0;
	/* (re-)open the window */
	if ( (e = xwimp_open_window((wimp_open *)&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	/* check the resulting state */
	if ((e = xwimp_get_window_state(&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	PRINTF(("\\t SetWindowBounds id: %d requested:%d@%d->%d@%d, actual: %d@%d->%d@%d\n",
		thisWindow->windowIndex,
		thisWindow->visibleArea.x0, thisWindow->visibleArea.y0,
		thisWindow->visibleArea.x1, thisWindow->visibleArea.y1,
		wblock.visible.x0, wblock.visible.y0,
		wblock.visible.x1, wblock.visible.y1));
	thisWindow->visibleArea.x0 =  wblock.visible.x0;
	thisWindow->visibleArea.x1 =  wblock.visible.x1;
	thisWindow->visibleArea.y0 =  wblock.visible.y0;
	thisWindow->visibleArea.y1 =  wblock.visible.y1;

	return true;
}

/* Colour translation table stuff */

void SetupPixelTranslationTable(windowDescriptorBlock * thisWindow) {
/* derive the pixel translation table suited to the current combination */
/* of Display mode and screen mode */
os_error * e;
int tableSize, log2bpp;
bits junk;
os_palette * currPal;
	/* set the appropriate palette */
	if ( ( e = xos_read_mode_variable( thisWindow->displaySprite->mode, os_MODEVAR_LOG2_BPP, &log2bpp, &junk)) != NULL) {
		platReportFatalError(e);
		return ;
	}

	/* fudge the pixel table to cope with the apparent fault in colourtrans_generate_table */
	if ((log2bpp <= 3) ) {
		int i, val;
		/* realloc the table to the new size. Use 1024 bytes since that is */
		/* plenty big enough for even 32bpp, but is not awkwardly big */
		thisWindow->pixelTranslationTable = realloc( thisWindow->pixelTranslationTable, 1024);
		for( i = 0; i<256; i++) {
			xcolourtrans_return_colour_number_for_mode((os_colour)(paletteTable.entries[i]), os_CURRENT_MODE, (os_palette*)colourtrans_CURRENT_PALETTE, &val);
			if ( screenBitPerPixel <= 8) {
				thisWindow->pixelTranslationTable->c[i] = (byte)(val & 0xFF);
			} else  {
				if ( screenBitPerPixel == 16) {
					thisWindow->pixelTranslationTable->c[i<<1] =
						(byte)(val & 0xFF);
					thisWindow->pixelTranslationTable->c[(i<<1)+1] =
						(byte)((val>>8) & 0xFF);
				} else { /* must be 32bpp */
					thisWindow->pixelTranslationTable->c[i<<2] =
						(byte)(val & 0xFF);
					thisWindow->pixelTranslationTable->c[(i<<2)+1] =
						(byte)((val>>8) & 0xFF);
					thisWindow->pixelTranslationTable->c[(i<<2)+2] =
						(byte)((val>>16) & 0xFF);
					thisWindow->pixelTranslationTable->c[(i<<2)+3] =
						(byte)((val>>24) & 0xFF);
				}
			}
		}
	} else {
		currPal = (log2bpp > 3) ? colourtrans_CURRENT_PALETTE : (os_palette*)&paletteTable;
		/* call colourTrans_generate_table to find out how big the tx table has to be */
		if ( (e = xcolourtrans_generate_table(  thisWindow->displaySprite->mode, currPal, os_CURRENT_MODE, colourtrans_CURRENT_PALETTE, NULL, colourtrans_RETURN_WIDE_ENTRIES, NULL, NULL, &tableSize )) != NULL) {
			platReportFatalError(e);
			return ;
		}
		/* realloc the table to the new size */
		PRINTF(("SetupPixelTranslationTable: pixel table %0x realloc\n", (int)thisWindow->pixelTranslationTable));
		thisWindow->pixelTranslationTable = realloc( thisWindow->pixelTranslationTable, tableSize);
		PRINTF(("SetupPixelTranslationTable: ok %0x s: %d\n", (int)thisWindow->pixelTranslationTable, tableSize));
		/* call colourTrans_generate_table to build the tx table  */
		if ( (e = xcolourtrans_generate_table(  thisWindow->displaySprite->mode, currPal, os_CURRENT_MODE, colourtrans_CURRENT_PALETTE, thisWindow->pixelTranslationTable,  colourtrans_RETURN_WIDE_ENTRIES, NULL, NULL, &tableSize )) != NULL) {
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
					sprintf( privateErr.errmess, "index out of range in color table computation\n");
					platReportError(&privateErr);
				}
				SetColorEntry(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
			}
		}
	}
}

void UpdateDisplaySpritePtrs(void) {
/* for all active windowDescriptorBlocks, use the stored spriteName to find  and
 * update the displaySprite ptr.
 * Needed after any sprite create/delete/resize etc
 */
windowDescriptorBlock * entry;
	entry = windowListRoot;
	while(entry) {
		if (entry->spriteName[0] != '\0') {
				PRINTF(("\\t Update Sprite %d\n", entry->windowIndex));
				/* find the sprite pointer using spriteop select */
				xosspriteop_select_sprite(osspriteop_NAME, spriteAreaPtr,
					(osspriteop_id)entry->spriteName,
						&(entry->displaySprite));
				PRINTF(("\\t Sprite %s at %0x, pTT: &%0x\n",
					entry->displaySprite->name,
					(int)entry->displaySprite,
					entry->pixelTranslationTable));
			}
		entry = entry->next;
	}
}

int CreateSpriteArea( int size) {
/* create a RiscOS sprite area which will be used by Squeak for its
 * Display bitmaps.
 */
os_error *e;
int ptr, daSizeLimit, neededSize;
byte * daBaseAddress;
	neededSize = size + sizeof(osspriteop_area);
	if ((e = xosdynamicarea_create (
				os_DYNAMIC_AREA_APPLICATION_SPACE,
				neededSize,
				(byte const*)-1,
                                os_AREA_NO_USER_DRAG, // stops it being draggable size in taskmanager
				40*1024*1024, // -1 means 'unlimited'
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
	spriteAreaPtr->size = neededSize;
	spriteAreaPtr->sprite_count = 1;
	spriteAreaPtr->first = 16;
	if ( (e = xosspriteop_clear_sprites( osspriteop_USER_AREA,  spriteAreaPtr)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	PRINTF(("\\t CreateSpriteArea size: %d count: %d limit: %d\n", spriteAreaPtr->size, spriteAreaPtr->sprite_count, daSizeLimit));

	return ptr;
}

int CreateSprite(windowDescriptorBlock * thisWindow) {
/* create the actual display sprite within the sprite area
 * If there is already a displaySprite, we must assume this is a window
 * resize or depth change */
os_error * e;
int sprMode;
	if (thisWindow->displaySprite) {
		/* delete the old sprite */
		osspriteop_delete_sprite(osspriteop_NAME, spriteAreaPtr,
			(osspriteop_id)thisWindow->spriteName);
	} else {
		/* make the sprite name be SqW0001 etc */
		sprintf(thisWindow->spriteName, "SqW%08d", thisWindow->windowIndex);
	}
		/* derive the sprite mode from the depth(d) requested */
	#define SPR_MODE_WORD(arg) ((arg<<osspriteop_TYPE_SHIFT) | (180<<osspriteop_YRES_SHIFT) | (180<<osspriteop_XRES_SHIFT) | 1 )
		switch (thisWindow->squeakDisplayDepth) {
			case 1: sprMode = SPR_MODE_WORD(osspriteop_TYPE1BPP); break;
			case 2: sprMode = SPR_MODE_WORD(osspriteop_TYPE2BPP); break;
			case 4: sprMode = SPR_MODE_WORD(osspriteop_TYPE4BPP); break;
			case 8: sprMode = SPR_MODE_WORD(osspriteop_TYPE8BPP); break;
			case 16: sprMode = SPR_MODE_WORD(osspriteop_TYPE16BPP); break;
			case 32: sprMode = SPR_MODE_WORD(osspriteop_TYPE32BPP); break;
		}

	/* now create a suitable sprite and hook it up */
	if ( (e = xosspriteop_create_sprite(osspriteop_NAME,
		spriteAreaPtr, thisWindow->spriteName, false,
		thisWindow->bitmapExtentP.x, thisWindow->bitmapExtentP.y,
		(os_mode)sprMode)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	PRINTF(("\\t CreateSprite %s %d@%d\n",thisWindow->spriteName, thisWindow->bitmapExtentP.x, thisWindow->bitmapExtentP.y));

	SetupPixelTranslationTable(thisWindow);
	UpdateDisplaySpritePtrs();

	return true;
}

void DeleteSprite(windowDescriptorBlock * thisWindow) {
/* remove the sprite from thisWindow, delete the actual sprite, update
 * all the sprite pointers and nul thisWindow's spriteName */
	PRINTF(("DeleteSprite: pTT %0x n: %s\n", thisWindow->pixelTranslationTable,
		thisWindow->spriteName));
	xosspriteop_delete_sprite(osspriteop_NAME, spriteAreaPtr, (osspriteop_id)thisWindow->spriteName);
	sprintf(thisWindow->spriteName, "\0");
	thisWindow->displaySprite = null;
	PRINTF(("DeleteSprite: pTT %0x\n", thisWindow->pixelTranslationTable));
	UpdateDisplaySpritePtrs();
}

void InitRootWindow(void) {
/* initialise the basic state of the root window so that other
 * code can run ok. Set the pointer to hostWindow[1] and make sure its
 * handle is null
 */
	rootWindow = AddWindowBlock();
	PRINTF(("\\t InitRootWindow: &%x, %d\n", (int)rootWindow, (int)rootWindow->handle));
}

void DeleteWindow(windowDescriptorBlock * thisWindow) {
/* Delete thisWindow :-)
 * delete the sprite, free any window block storage, null the entry
 * in hostWindowList
 */
	DeleteSprite(thisWindow);
	RemoveWindowBlock(thisWindow);
	xwimp_close_window(thisWindow->handle);


}

void BuildWindow(windowDescriptorBlock * thisWindow) {
/* Do the basic building of a window.
 *
 * Create a window block and set various structures and flags to suit the windowDescriptorBlock
 * Otherwise the title is copied into the literal string in the structure
 */
wimp_window wblock;
os_error * e;
wimp_w w;
	PRINTF(("\\t BuildWindow %d\n", thisWindow->windowIndex));

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
			| wimp_WINDOW_BOUNDED_ONCE | wimp_WINDOW_IGNORE_XEXTENT
			| wimp_WINDOW_IGNORE_YEXTENT
                        | thisWindow->attributes; // <--- these are the flags settable from Squeak
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
	wblock.extent.y0 = -screenSizeP.y<<scalingFactor.y;
	wblock.extent.x1 = screenSizeP.x<<scalingFactor.x;
	wblock.extent.y1 = 0;
	/* titlebar flags */
	wblock.title_flags = wimp_ICON_TEXT
		| wimp_ICON_FILLED  | wimp_ICON_HCENTRED
		| wimp_ICON_VCENTRED | wimp_ICON_BORDER | wimp_ICON_INDIRECTED;
	/* work area flags */
	wblock.work_flags=(wimp_BUTTON_CLICK)
		<<wimp_ICON_BUTTON_TYPE_SHIFT;
	/* sprite area +1 apparently refers to WIMP area */
	wblock.sprite_area = (osspriteop_area *)1;
	/* minimum window size allowed */
	wblock.xmin = (short)100;
	wblock.ymin = (short)100;
        /* window title - limited to 151 chars by struct defn
         * since it is indirected, the title is a pointer to a _global_ var string
         * and the wimp_ICON_INDIRECTED flag must be set (above).*/
	wblock.title_data.indirected_text.text =  thisWindow->title;
	wblock.title_data.indirected_text.validation = (char*)-1;
	wblock.title_data.indirected_text.size = strlen(thisWindow->title);
	/* icon count Assuming .icons=0 is ok for no icons ? */
	wblock.icon_count = 0;
	/* wblock.icons = (wimp_icon *)NULL;*/

        /* call wimp_create_window to actaully do the deed */
	if ( (e = xwimp_create_window(&wblock, &w)) != NULL) {
		platReportFatalError(e);
		return;
	}
        /* save the window handle in the windowDescriptorBlock */
	thisWindow->handle = w;

	/* actually set the window size/position - may modify windowVisibleArea */
	SetWindowBounds(thisWindow);
}

void CreateRootWindow(windowDescriptorBlock * thisWindow) {
/* create the root window for the main Display. This one has the image name
 * or otherwise specified title and is centred upon creation.
 */
os_coord originP, sizeP;
	/* set the size of the root window.
	 * don't make it bigger than the screen size and centre it
	 */

	/* maximum size is screen size */
	sizeP.x  = MIN( thisWindow->bitmapExtentP.x, screenSizeP.x);
	sizeP.y  = MIN( thisWindow->bitmapExtentP.y, screenSizeP.y);

	/* default origin is meant to centre the window */
	originP.x = (int)(screenSizeP.x - sizeP.x) / 2;
	originP.y = (int)(screenSizeP.y - sizeP.y) / 2;
	thisWindow->visibleArea.x0 = Pix2OSX(originP.x);
	thisWindow->visibleArea.y0 = Pix2OSY(originP.y);
	thisWindow->visibleArea.x1 = Pix2OSX(originP.x + sizeP.x);
	thisWindow->visibleArea.y1 = Pix2OSY(originP.y + sizeP.y);

	thisWindow->attributes =
		wimp_WINDOW_TITLE_ICON|
		wimp_WINDOW_CLOSE_ICON |
		wimp_WINDOW_BACK_ICON;

	BuildWindow(thisWindow);

}
void CreatePlainWindow(windowDescriptorBlock * thisWindow) {
/* Create a plain window. The visibleArea values MUST be setup before this
 * can be called, as well as the windowIndex
 */
	PRINTF(("\\t CreatePlainWindow %d\n", thisWindow->windowIndex));
	thisWindow->title[0] = '\0';

	BuildWindow( thisWindow);

}

int CreateDisplayBitmap(windowDescriptorBlock * thisWindow, int width, int height, int depth) {
/* create the window's bitmap */
int byteSize;
	/* save the dimensions of this Display object */
	thisWindow->bitmapExtentP.x = width;
	thisWindow->bitmapExtentP.y = height;
	thisWindow->squeakDisplayDepth  = depth>0 ?depth: -depth;

	/* if there is no window yet, create one */
	if (thisWindow->handle == null) {
		if (thisWindow->windowIndex == 1) {
			CreateRootWindow(thisWindow);
		} else {
			CreatePlainWindow(thisWindow);
		}
	}
	/* it is possible that the window is smaller than the
	 * requested width@height but the bitmap MUST be
	 * that size or we will have great fun trying to do
	 * the reversal echoing.
	 */
	PRINTF(("\\t CreateDisplayBitmap i: %d p:%x w: %d h:%d d:%d\n", thisWindow->windowIndex, (int)thisWindow->handle, width, height, depth));

	/* create the RiscOS pixmap to the right dimensions */
	/* delete the sprite if it already exists */
	if ( thisWindow->displaySprite ) DeleteSprite(thisWindow);

	/* byteSize is window width rounded to a word boundary *
	 * the window height * the number of bytes per pixel
	 * plus the sprite header size
	 */
#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)
	byteSize = bytesPerLine(thisWindow->bitmapExtentP.x, thisWindow->squeakDisplayDepth) * thisWindow->bitmapExtentP.y;

/* ((thisWindow->bitmapExtentP.x + 3)& ~3)  *
		thisWindow->bitmapExtentP.y * thisWindow->squeakDisplayDepth /8; */
	byteSize += sizeof(osspriteop_header);

	/* if no sprite area yet, create one ready for this first sprite */
	if ( spriteAreaPtr == NULL ) {
		CreateSpriteArea( byteSize );
	}
	/* if available space is too small, grow the DA & spritearea */
	if ( spriteAreaPtr->size - spriteAreaPtr->used < byteSize) {
		int changeSize;
		xos_change_dynamic_area_no_fail( SqueakDisplayDA, (byteSize + spriteAreaPtr->used - spriteAreaPtr->size), &changeSize);
		spriteAreaPtr->size += changeSize;
		// Now double check for enough room
		if ( spriteAreaPtr->size - spriteAreaPtr->used < byteSize) {
			PRINTF(("\\t Unable to extend sprite area enough\n"));
			return false;
		}
		PRINTF(("\\t extend sprite area to size: %d, used: %d\n", spriteAreaPtr->size, spriteAreaPtr->used));
	}

	/* build the actual sprite and translation table */
	CreateSprite(thisWindow);

	return true;
}



int createWindowWidthheightoriginXyattrlength(int w, int h, int x, int y, char * attributeList, int attributeListLength) {
/* Create a new host window and return the windowIndex */
windowDescriptorBlock * thisWindow = null;

	thisWindow = AddWindowBlock();
	PRINTF(("\\t createWindow  tw: %0x\n", thisWindow->windowIndex));
	if (!thisWindow) {
		return 0;
	}
	/* remember, RISC OS expects bottom left, topright rectangle, 0@0 is
	 * screen bottomleft
	 */
	thisWindow->visibleArea.x0 = Pix2OSX(x);
	thisWindow->visibleArea.y0 = Pix2OSY(screenSizeP.y - y - h);
	thisWindow->visibleArea.x1 = thisWindow->visibleArea.x0
		+ Pix2OSX(w);
	thisWindow->visibleArea.y1 = Pix2OSY(screenSizeP.y - y);

	thisWindow->attributes = 0;
	if (attributeListLength == 4) {
	/* if the attribute list is 4 bytes we treat it as an int
	 * otherwise we ignore it */
		thisWindow->attributes  = *(int*)attributeList;
	}
	return thisWindow->windowIndex;
}

int closeWindow(int windowIndex) {
/* closeWindow: arg is int windowIndex. Fail (return 0) if anything goes wrong
 * - typically the windowIndex invalid or similar */
windowDescriptorBlock * thisWindow;
	thisWindow = windowBlockFromIndex(windowIndex);
	if ( !thisWindow) return false;

	DeleteWindow(thisWindow);
	return true;
}

int ioCloseAllWindows(void) {
/* ioCloseAllWindows: intended for VM shutdown.
 * Close all the windows that appear to be open.
 * No useful return value since we're getting out of Dodge anyway.
 *
 * This looks a bit odd but since DeleteWindow(root) will remove the first
 * windowDescriptorBlock and then stick its 'next' in root, it will gradually
 * vacuum up the entire list
 */
	while(windowListRoot) {
		DeleteWindow(windowListRoot);
	}
        return true;
}

/* ioShowDisplayOnWindow: similar to ioShowDisplay but adds the int windowIndex
 * Return true if ok, false if not, but not currently checked
 * BitBlt has messed with part of the Display/Window - inform the WIMP so
 * that it gets redrawn when we do HandleEvents and get a
 * wimp_REDRAW_WINDOW_REQUEST */
int ioShowDisplayOnWindow( unsigned char * dispBitsIndex, int width, int height, int depth, int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex) {
os_error *e;
windowDescriptorBlock * thisWindow;
	/* quickly check bounds */
	affectedL = MAX(affectedL, 0);
	affectedR = MIN(affectedR, width);
	affectedT = MAX(affectedT, 0);
	affectedB = MIN(affectedB, height);

	if(affectedR <= affectedL || affectedT >= affectedB) return true;

	PRINTF(("\\t ioShowDisplayOnWindow: %d @ %d l:%d t:%d r:%d b:%d\n", windowIndex, millisecondTimerValue(), affectedL, affectedT, affectedR, affectedB));

	thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(windowIndex);
	if ( !thisWindow) return false;

	/*******************************************************/
	/* in init, we create hostWindowList[1] and set its sprite ptr  null
	 * so that when it first comes this way we can detect it and
	 * build a window to suit. That can be dropped someday when
	 * Display is not a special case.
	 */

	if( thisWindow->displaySprite == NULL ||
		thisWindow->bitmapExtentP.x != width ||
		thisWindow->bitmapExtentP.y != height ||
		thisWindow->squeakDisplayDepth != depth) {
		/* if the displaySprite is not set up, sort it out */
		CreateDisplayBitmap( thisWindow, width, height, depth);
	}

	/* transform the Display bits to the displaySprite */
	displayBitmapIndex = (unsigned int *)dispBitsIndex;
	DisplayReverseArea(thisWindow, affectedL, affectedT, affectedR, affectedB);

	/* inform the Wimp of the affected area,
	   scaled for the display mode etc */
	if( (e = xwimp_force_redraw( thisWindow->handle,
				affectedL<<scalingFactor.x,
				0-(affectedB<<scalingFactor.y),
				affectedR<<scalingFactor.x,
				0-(affectedT<<scalingFactor.y))) != NULL) {
		platReportError(e);
		return false;
	}
	return true;
}


/*** I/O Primitives ***/

sqInt ioSizeOfWindow(sqInt windowIndex) {
/* ioSizeOfWindow: arg is int windowIndex. Return the size of the specified
 * window in (width<<16 || height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowIndex
 * -1 is chosen since itwould correspond to a window size of 64k@64k which
 * I hope is unlikely for some time to come */
int w, h;
int maxWidth, maxHeight;
int minWidth = 100, minHeight = 100;
windowDescriptorBlock * thisWindow;

	thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(windowIndex);
	if (thisWindow == NULL) {
		/* seems to be an invalid window index */
		return -1;
	}
	if (windowIndex == 1 && thisWindow->handle == null) {
		/* main window not yet open, derive from saved size in image
		   if there's no window yet, we need to check the
		   screen metrics to make sure we
		   don't make too big a window later */
		GetDisplayParameters();
		w = (unsigned) getSavedWindowSize() >> 16 ;
		h = getSavedWindowSize() & 0xFFFF;
		/* maximum size is screen size (minus a little) */
		maxWidth  = (int)screenSizeP.x ;
		maxHeight = (int)(screenSizeP.y * 0.9);
		w = MAX(w, minWidth);
		w = MIN(w, maxWidth);
		h = MAX(h, minHeight);
		h = MIN(h, maxHeight);
//		PRINTF(("\\t ioScreenSize no window: %d@%d\n", w, h));
	} else {
		/* get extent from window object */
		w = OS2PixX(thisWindow->visibleArea.x1 - thisWindow->visibleArea.x0);
		h = OS2PixY( thisWindow->visibleArea.y1 - thisWindow->visibleArea.y0);
//		PRINTF(("\\t ioScreenSize %d@%d\n", w, h));
//		PRINTF(("\\t window handle: %0x\n", thisWindow->handle));
	}

	return (w << 16) | (h & 0xFFFF);
}

int ioSizeOfWindowSetxy(int windowIndex, int width, int height) {
/* ioSizeOfWindowSetxy: args are int windowIndex, int w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 || height) format or -1 for failure as above. */
windowDescriptorBlock * thisWindow;
int w,h;

	thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(windowIndex);
	if (thisWindow == NULL) {
		/* seems to be an invalid window index */
		return -1;
	}
	/* remember, RISC OS expects bottom left, topright rectangle, 0@0 is
	 * screen bottomleft
	 */
	/* x0 stays as currently set */
	/* y0 is y1 - h<<scale */
	thisWindow->visibleArea.y0 = thisWindow->visibleArea.y1
		- Pix2OSY(height);
	/* y1 stays as is */
	/* x1 is x0 + w<<scale */
	thisWindow->visibleArea.x1 = thisWindow->visibleArea.x0
		+ Pix2OSX(width);
	if ( thisWindow->handle ) {
		/* only really set the window bounds if there is one */
		SetWindowBounds(thisWindow);
	}

	/* get new extent from window object */
	w = OS2PixX(thisWindow->visibleArea.x1 - thisWindow->visibleArea.x0);
	h = OS2PixY(thisWindow->visibleArea.y1 - thisWindow->visibleArea.y0);
	return (w << 16) | (h & 0xFFFF);
}

int ioPositionOfWindow(int windowIndex) {
/* ioPositionOfWindow: arg is int windowIndex. Return the pos of the specified
 * window in (left<<16 || top) format like ioScreenSize.
 * Return -1 (as above) for failure - tpyically invalid windowIndex */
windowDescriptorBlock * thisWindow;
int x,y;

	thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(windowIndex);
	if (thisWindow == NULL) {
		/* seems to be an invalid window index */
		return -1;
	}
	/* get origin from window object */
	x = OS2PixX(thisWindow->visibleArea.x0);
	y = screenSizeP.y - OS2PixY(thisWindow->visibleArea.y1);
	return (x << 16) | (y & 0xFFFF);
}

int ioPositionOfWindowSetxy(int windowIndex, int x, int y) {
/* ioPositionOfWindowSetxy: args are int windowIndex, int x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 || top) format or -1 for failure, as above */
windowDescriptorBlock * thisWindow;
int w,h;

	thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(windowIndex);
	if (thisWindow == NULL) {
		/* seems to be an invalid window index */
		return -1;
	}
	/* remember, RISC OS expects bottom left, topright rectangle, 0@0 is
	 * screen bottomleft
	 */
	/* get current extent from window struct */
	w = OS2PixX(thisWindow->visibleArea.x1 - thisWindow->visibleArea.x0);
	h = OS2PixY( thisWindow->visibleArea.y1 - thisWindow->visibleArea.y0);
	/* work out new visible area */
	thisWindow->visibleArea.x0 = Pix2OSX(x);
	thisWindow->visibleArea.y0 = Pix2OSY(screenSizeP.y - y - h);
	thisWindow->visibleArea.x1 = thisWindow->visibleArea.x0
			+ Pix2OSX(w);
	thisWindow->visibleArea.y1 = Pix2OSY(screenSizeP.y - y);
	if ( thisWindow->handle ) {
		/* only really set the window bounds if there is one */
		SetWindowBounds(thisWindow);
	}

	/* get new origin from window object */
	w = OS2PixX(thisWindow->visibleArea.x0);
	h = screenSizeP.y - OS2PixY(thisWindow->visibleArea.y1);
	return (w << 16) | (h & 0xFFFF);
}

int ioSetTitleOfWindow(int windowIndex, char * newTitle, int sizeOfTitle) {
/* ioSetTitleOfWindow: args are int windowIndex, char* newTitle and
 * int size of new title. Fail with -1 if windowIndex is invalid, string is too long for platform etc. Leave previous title in place on failure */
windowDescriptorBlock * thisWindow;
os_error *e;
	thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(windowIndex);
	if (thisWindow == NULL) {
		/* seems to be an invalid window index */
		return -1;
	}
	/* check the string length is ok */
	if ( sizeOfTitle > WindowTitleLength ) {
		return -1;
	}
        PRINTF(( "\\t ioSetTitleOfWindow: string length & window ID ok\n"));

	/* check the titlebar flag is set */
        if ((thisWindow->attributes & wimp_WINDOW_TITLE_ICON) == 0 ) {
		return -1;
	}
        PRINTF(( "\\t ioSetTitleOfWindow: titlebar flag ok\n"));

	/* copy to the window */
	strncpy(thisWindow->title, newTitle, sizeOfTitle);
	thisWindow->title[sizeOfTitle] = '\0';
	/* update the titlebar if the window is built */
	if (thisWindow->handle) {
                if ((e = xwimp_force_redraw_furniture(thisWindow->handle, wimp_FURNITURE_TITLE)) != NULL) {
                platReportError(e);
                }
	}
        PRINTF(( "\\t ioSetTitleOfWindow: should be ok\n"));
	return true;
}

double ioScreenScaleFactor(void) {
	return 1.0;
}

sqInt ioScreenSize(void) {
/* return the screen size for the main Display window */
	return ioSizeOfWindow(1);
}

sqInt ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY) {
/* Move 1-bit form to pointer buffer and use mask to affect result.
 * Remember RPC pointer is 2-bits/pixel to allow 3 colours + mask.
 * As of Sq2.2, there can also be a mask 1-bit form specified.
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
		/* turn on revised pointer 2 immediately */
		e = xwimp_set_pointer_shape(2, (byte const *)&pointerBuffer, 16, 16, pointerOffset.x, pointerOffset.y );
	}

	return true;
}

sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY) {
/* older API for cursor setting */
	return ioSetCursorWithMask(cursorBitsIndex, NULL, offsetX, offsetY);
}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY) {
// no information on what this is supposed to do yet, assume old api can work for now
	return 0;
}

/* Backwards compat stub */
sqInt ioShowDisplay( sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth, sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB) {
	return ioShowDisplayOnWindow( (unsigned char *)dispBitsIndex, width, height, depth, affectedL, affectedR, affectedT, affectedB, 1);
}


sqInt ioForceDisplayUpdate(void) {
	PRINTF(("\\t ioForceDisplayUpdate @ %d\n", millisecondTimerValue()));
	// This immediate display update seems to display the right bits but
	// takes a huge % of the machine time. By going back to the older
	// HandleEvents we get a nice snappy machine. Weird.
	// DisplayPixmapNow();
	HandleEventsNotTooOften();   /* we might need to forceInterruptCheck() here ? */
	return false;
}


sqInt ioSetFullScreen(sqInt fullScreenWanted) {
/* if fullScreenWanted and we aren't already running fullScreen,
   change the window size and store the current origin and size
   for a later restore.
   if !fullScreenWanted and we are running fullScreen, restore those saved
   values
*/
static os_box prevSize = {0,0,0,0};
static int fullScreen = false;
windowDescriptorBlock * thisWindow;

	/* can only do this for the default window for now */
	thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(1);

	if (fullScreenWanted && !fullScreen) {
		/* save the current window size */
		prevSize.x0 = thisWindow->visibleArea.x0;
		prevSize.y0 = thisWindow->visibleArea.y0;
		prevSize.x1 = thisWindow->visibleArea.x1;
		prevSize.y1 = thisWindow->visibleArea.y1;
		/* set the fullscreen window size */
		thisWindow->visibleArea.x0 = 0;
		thisWindow->visibleArea.y0 = 0;
		thisWindow->visibleArea.x1 = Pix2OSX(screenSizeP.x);
		thisWindow->visibleArea.y1 = Pix2OSY(screenSizeP.y);
		SetWindowBounds(thisWindow);
		/* When we are setting fullscreen, we seem to get a window size
		 * that would fit with the included titlebar but positioned
		 * at 0@0. Thus there is a missing strip at the bottom and
		 * no titlebar. So, find out the resultant height and then REset
		 * the windowbounds with a new y0/1 to reposition
		 */
		if (thisWindow->visibleArea.y0 != 0) {
			thisWindow->visibleArea.y1 = Pix2OSY(screenSizeP.y) - thisWindow->visibleArea.y0;
			thisWindow->visibleArea.y0 = 0;
			SetWindowBounds(thisWindow);
		}
		/* save the new size in case the image is saved */
		setSavedWindowSize(
			(OS2PixX(thisWindow->visibleArea.x1 - thisWindow->visibleArea.x0) << 16)
			+ (OS2PixY(thisWindow->visibleArea.y1 - thisWindow->visibleArea.y0) & 0xFFFF));
		fullScreen = true;
		DeleteSprite(thisWindow);
		return true;
	}

	if (!fullScreenWanted && fullScreen) {
		thisWindow->visibleArea.x0 = prevSize.x0;
		thisWindow->visibleArea.y0 = prevSize.y0;
		thisWindow->visibleArea.x1 = prevSize.x1;
		thisWindow->visibleArea.y1 = prevSize.y1;
		SetWindowBounds(thisWindow);
		/* save the restored size in case the image is saved */
		setSavedWindowSize(
			(OS2PixX(thisWindow->visibleArea.x1 - thisWindow->visibleArea.x0) << 16)
			+ (OS2PixY(thisWindow->visibleArea.y1 - thisWindow->visibleArea.y0) & 0xFFFF));
		fullScreen = false;
		DeleteSprite(thisWindow);
		return true;
	}
	return true;
}

sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullScreenFlag) {
/* if fullScreenFlag, we are to try to change to a screen mode that matches
 * width, height and depth and then go fullscreen in that mode. Remember
 * the original screen mode _even if we change several times _. Somehow..
 * if not fullScreenFlag, simply change the window size.
 * Fail if we can't meet the request 'reasonably'.
 */

// not viable for multiple windows and not decently specified anyway
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

		/* can only do this for the default window for now */
		windowDescriptorBlock * thisWindow;
		thisWindow = (windowDescriptorBlock *)windowBlockFromIndex(1);
		if (!thisWindow) return false;

		prevSize.x0 = thisWindow->visibleArea.x0;
		prevSize.y0 = thisWindow->visibleArea.y0;
		prevSize.x1 = thisWindow->visibleArea.x1;
		prevSize.y1 = thisWindow->visibleArea.y1;
		/* set the fullscreen window size */
		thisWindow->visibleArea.y0 = thisWindow->visibleArea.y1 - Pix2OSX(height);
		thisWindow->visibleArea.x1 = thisWindow->visibleArea.x0 + Pix2OSX(width);
		SetWindowBounds(thisWindow);
		/* save the new size in case the image is saved */
		setSavedWindowSize(
			(OS2PixX(thisWindow->visibleArea.x1 - thisWindow->visibleArea.x0) << 16)
			+ (OS2PixY(thisWindow->visibleArea.y1 - thisWindow->visibleArea.y0) & 0xFFFF));
		DeleteSprite(thisWindow);
		return true;
	}
	return false;
}

sqInt ioScreenDepth(void) {
// what is the bpp setting of the screen right now?
	return screenBitPerPixel;
}

sqInt ioHasDisplayDepth(sqInt bitsPerPixel) {
// return true for all supported bpp supported.
	switch((int)bitsPerPixel) {
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

int ioIconiseWindow(wimp_message * wblock) {
/* We received an iconise message. Send the image a message to let it know */
extern void EventBufAppendWindow( int action, int left, int top, int right, int bottom, int windowIndex);
windowDescriptorBlock * thisWindow;
        /* find the window block with this OS handle */
        thisWindow = windowBlockFromHandle(((wimp_full_message_iconise *)wblock)->w);

        PRINTF(("\\t ioIconiseWindow: %d\n",thisWindow->windowIndex));
        EventBufAppendWindow( WindowEventIconise, 0,0,0,0, thisWindow->windowIndex);
        return true;
}
