/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS 3.7 for StrongARM RPCs, other machines        */
/*  not yet tested.                                                       */
/*                       sqRPCWindows.c                                   */
/* Window & OS interface stuff, commandline option handling and so on     */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* Jonathon Coxhead's OSLib,                   */
/* AcornC_C++, the Acorn sockets libs          */
/* and a little luck                           */
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osfscontrol.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "sq.h"
#include "sqArguments.h"
#include <kernel.h>

#define longAt(i) (*((int *) (i)))



/*** Compilation Options:
*
*	define LITTLE_ENDIAN to compile code for the little endian bitblt needed by ARMs
*
***/

/*** Variables -- Imported from Virtual Machine ***/
extern unsigned char 	*memory;
extern int				interruptPending;
extern int				interruptCheckCounter;
extern int				savedWindowSize;  /* set from header when image file is loaded */


/*** Variables -- image and path names ***/
#define IMAGE_NAME_SIZE 300
char					imageName[IMAGE_NAME_SIZE + 1];  /* full path to image */

#define VMPATH_SIZE 300
char					vmPath[VMPATH_SIZE + 1];  /* full path to interpreter's directory */

#ifndef MIN
#define MIN( a, b )   ( ( (a) < (b) ) ? (a) : (b) )
#define MAX( a, b )   ( ( (a) > (b) ) ? (a) : (b) )
#endif

/*** Variables -- RPC Related ***/
wimp_w					sqWindowHandle = null;
char					sqTaskName[] = "Squeak!";
wimp_t					Task_Handle;
os_dynamic_area_no		SqueakObjectSpaceDA, SqueakDisplayDA;
char *					clipboardBuffer = null;
int						clipboardByteSize = 0;
extern int				windowActive;
extern int				sqHasClipboard;
int						pointerBuffer[16] =
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
os_coord				pointerOffset;
wimp_icon_create		sqIconBarIcon;
wimp_MESSAGE_LIST(4)	importantWimpMessages;
int						osLevelOver350;
wimp_version_no			actualOSLevel;
os_error				privateErr;
char					VMVersion[] = "2.30 of "__DATE__;
// temp for coping with filename handling transition period. Set to 1 if new image is run, and use to test for translate for filenames
int						newImageVersion = 0;

/* argument handling stuff  -- see c.sqArgument */
int 					numOptionsVM;
char					*(vmOptions[MAX_OPTIONS]);
int 					numOptionsImage;
char					*(imageOptions[MAX_OPTIONS]);

int						headlessFlag = 0;
int						helpMe = 0;
int						versionMe = 0;
int						objectHeadroom = 4*1024*1024;

vmArg args[] = {
		{ ARG_FLAG,   &headlessFlag, "-headless" },
		{ ARG_FLAG,   &helpMe, "-help" },
		{ ARG_FLAG,   &versionMe, "-version" },
		{ ARG_UINT,    &objectHeadroom, "-memory:"},
		{ ARG_NONE, NULL, NULL }
	};

/* screen description. Needs updating when screenmode changes */
os_coord				squeakDisplaySize,
						screenSize,
						scalingFactor,
						scrollOffset,
						visibleArea;
int						BitsPerPixel, squeakDisplayDepth;

/* display bitmap info */
osspriteop_area *		spriteAreaPtr = NULL;
osspriteop_header *		displaySprite = NULL;
osspriteop_trans_tab *	pixelTranslationTable = NULL;
os_PALETTE (256)		paletteTable;
extern int				displayBits;


/*** Variables -- Event Recording -- see c.sqRPCEvent ***/
extern int				keyBuf[];
extern int				keyBufGet;
extern int				keyBufPut;

/*** Functions ***/
			 void SetColorEntry(int index, int red, int green, int blue);
			 void getDisplayParameters(void);
			 void displayModeChanged(void);
extern		  int HandleEvents(int);
			  int InitRiscOS(void);
			 void MouseButtons( wimp_pointer * wblock);
			 void SetUpWindow(void);
			 void SetInitialWindowSize(void);
			  int SetupPixmap(int w, int h, int d);
			 void SetupPixelTranslationTable(void);
			 void SetupPaletteTable(void);
			  int createSpriteArea( int size);
			  int platAllocateMemory( int amount);
			 void platReportFatalError( os_error * e);
			 void platReportError( os_error * e);
			 void setDefaultPointer(void);
extern		 void claimClipboard(void);
extern		 void fetchClipboard(void); 

/*** RPC-related Functions ***/
void platReportError( os_error * e) {
/* Use the RiscOS Error dialogue to notify users of some problem */
	wimp_report_error( e, wimp_ERROR_BOX_CANCEL_ICON | wimp_ERROR_BOX_HIGHLIGHT_CANCEL |wimp_ERROR_BOX_SHORT_TITLE ,  sqTaskName);
}


void platReportFatalError( os_error * e) {
/* Report an error considered fatal */
	platReportError(e);
	exit(e->errnum);
}

int platAllocateMemory( int amount) {
os_error * e;
int daSizeLimit;
byte * daBaseAddress;
	if ((e = xosdynamicarea_create (
				os_DYNAMIC_AREA_APPLICATION_SPACE,
				amount,
				(byte const*)-1,
				(bits)128,
				-1,
				NULL,
				NULL,
				"Squeak ObjectSpace",
				&SqueakObjectSpaceDA,
				&daBaseAddress,
				&daSizeLimit
			)) !=NULL) {
		platReportFatalError(e);
		return false;
	}
	return (int)daBaseAddress;
}

int platMallocChunk(int size) {
	int chunk;
	chunk = (int) malloc(size);
	if ( chunk ==  NULL) return -1;
	return chunk;
}

int platFree(int chunk) {
	free( (void *)chunk);
}          

int InitRiscOS(void) {
/* Initialise RiscOS for desktop wimp program use */
os_error * e;

	importantWimpMessages.messages[0] = message_MODE_CHANGE;

	if ((e = xwimp_initialise (wimp_VERSION_RO35,
					sqTaskName,
					(wimp_message_list*)&importantWimpMessages,
					&actualOSLevel,
					&Task_Handle)) != NULL) {
		platReportFatalError( e);
		return false;
	}
	if (actualOSLevel >= wimp_VERSION_RO35) {
		osLevelOver350 = true;
	} else {
		osLevelOver350 = false;
	}
	SqueakDisplayDA =SqueakObjectSpaceDA = (os_dynamic_area_no)NULL;
 
	sqIconBarIcon.w = (wimp_w)-1;
	sqIconBarIcon.icon.extent.x0 = 0;
	sqIconBarIcon.icon.extent.y0 = 0;
	sqIconBarIcon.icon.extent.x1 = 68;
	sqIconBarIcon.icon.extent.y1 = 68;
	sqIconBarIcon.icon.flags = wimp_ICON_INDIRECTED | wimp_ICON_SPRITE | wimp_ICON_HCENTRED | wimp_ICON_VCENTRED ;
	sqIconBarIcon.icon.data.indirected_sprite.id = (osspriteop_id )&sqTaskName;
	sqIconBarIcon.icon.data.indirected_sprite.area = (osspriteop_area *)1;
	sqIconBarIcon.icon.data.indirected_sprite.size = 7;
	wimp_create_icon(&sqIconBarIcon);

	SetupPaletteTable();

	setFPStatus(0);
	
return true;
}


/* display related routines  */

void setDefaultPointer(void) {
	xwimp_set_pointer_shape(2, (byte const *)pointerBuffer, 16, 16, 0, 0);
	/* and then return the pointer to no.1 */
	xwimp_set_pointer_shape(1, (byte const *)-1, 0, 0, 0, 0);
}


int setWindowParameters(os_coord *origin) {
/* arrange for the window to appear from origin to origin+squeakDisplaySize */
int width, height;
wimp_window_info wblock;
os_error * e;
	/*  the sqWindowHandle state */
	wblock.w = sqWindowHandle;
	if ((e = xwimp_get_window_info(&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	/* scale w & h by OSUnit/pixel factor */
	width = squeakDisplaySize.x <<scalingFactor.x;
	height = squeakDisplaySize.y << scalingFactor.y;
	/* set work area to suit these values */
	wblock.extent.y0 = -height;
	wblock.extent.x1 = width;
	xwimp_set_extent( sqWindowHandle, &(wblock.extent));
	/* set size of window */
	if ( origin  != null ) { /* only set origin at start up */
		wblock.visible.x0 = (int)(origin->x)<<scalingFactor.x;
		wblock.visible.y1 = (int)(origin->y)<<scalingFactor.y;
	}


	wblock.visible.x1 = (wblock.visible.x0)+width;
	wblock.visible.y0 = (wblock.visible.y1) - height;
	wblock.next = (wimp_w)-1;
	wblock.xscroll = 0;
	wblock.yscroll = 0;
	if ( (e = xwimp_open_window((wimp_open *)&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	};
	if ((e = xwimp_get_window_info(&wblock)) != NULL) {
		platReportFatalError(e);
		return false;
	}
	scrollOffset.x = wblock.xscroll;
	scrollOffset.y = wblock.yscroll;
	visibleArea.x =  wblock.visible.x0;
	visibleArea.y =  wblock.visible.y1;

	/* set work area to suit these values */
	wblock.extent.y0 = /* -height */ wblock.visible.y0 - wblock.visible.y1;
	wblock.extent.x1 = /* width */ wblock.visible.x1 - wblock.visible.x0;
	xwimp_set_extent( sqWindowHandle, &(wblock.extent));

	/* now reset squeakDisplaySize to reflect the eventual sizes */
	squeakDisplaySize.x = (wblock.extent.x1)>>scalingFactor.x;
	squeakDisplaySize.y = ( -wblock.extent.y0)>> scalingFactor.y;
	return true;
}

void getDisplayParameters(void) {
int bpp;
bits junk;
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE, (os_mode_var)os_MODEVAR_XWIND_LIMIT, &screenSize.x, &junk);
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE, (os_mode_var)os_MODEVAR_YWIND_LIMIT, &screenSize.y, &junk);
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE, (os_mode_var)os_MODEVAR_LOG2_BPP, &bpp, &junk);
	/* this gets us log2 of actual bpp, so convert back */
	BitsPerPixel = 1<<bpp;
	/* now find the OSunit to pixel scaling factors */
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE, (os_mode_var)os_MODEVAR_XEIG_FACTOR, &scalingFactor.x, &junk);
	xos_read_mode_variable( (os_mode)os_CURRENT_MODE, (os_mode_var)os_MODEVAR_YEIG_FACTOR, &scalingFactor.y, &junk);
}

void displayModeChanged(void){
	getDisplayParameters();
	SetupPixelTranslationTable();
	setWindowParameters( (os_coord *)null);
}

int createSpriteArea( int size) {
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
			if ( BitsPerPixel <= 8) {
				pixelTranslationTable->c[i] = (byte)(val & 0xFF);
			} else  {
				if ( BitsPerPixel == 16) {
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

	/* derive the sprite mode from the depth requested. Needs to work with new
	spritemode stuff and support 16/32 bits etc */
	if ( osLevelOver350) {
#define SPR_MODE_WORD(arg) ((arg<<osspriteop_TYPE_SHIFT) | (180<<osspriteop_YRES_SHIFT) | (180<<osspriteop_XRES_SHIFT) | 1 )
		switch (d) {
			case 1: sprMode = SPR_MODE_WORD(osspriteop_TYPE1BPP); break;
			case 2: sprMode = SPR_MODE_WORD(osspriteop_TYPE2BPP); break;
			case 4: sprMode = SPR_MODE_WORD(osspriteop_TYPE4BPP); break;
			case 8: sprMode = SPR_MODE_WORD(osspriteop_TYPE8BPP); break;
			case 16: sprMode = SPR_MODE_WORD(osspriteop_TYPE16BPP); break;
			case 32: sprMode = SPR_MODE_WORD(osspriteop_TYPE32BPP); break;
		}
	} else {
		switch (d) {
			case 1: sprMode = 18; break;
			case 2: sprMode = 19; break;
			case 4: sprMode = 20; break;
			case 8: sprMode = 21; break;
			default: sprMode = 21;
		}
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
	/* believe it or not, the following is derived from Acorn recommended code
	to add a palette to a sprite...
	we do this move-up to allow room for a Squeak object header just in front
	of the  actual bits. Kinky huh?  */
#define extraRoom (256 )
	spriteAreaPtr->used = spriteAreaPtr->used + extraRoom;
	displaySprite = (osspriteop_header *)((int)spriteAreaPtr + spriteAreaPtr->first);
	displaySprite->size = displaySprite->size +extraRoom;
	displaySprite->image = displaySprite->image + extraRoom;
	displaySprite->mask = displaySprite->mask + extraRoom;

	return true;
}

void SetUpWindow(void) {
wimp_window wblock;
os_error * e;
wimp_w w;

	/* create window block */
	/* initial visible area on screen - almost irrelevant, but we need to set something */
	wblock.visible.x0 = 800;
	wblock.visible.y0 = 1200;
	wblock.visible.x1 = 1800;
	wblock.visible.y1 = 2200;
	/* scroll offsets */
	wblock.xscroll = 0;
	wblock.yscroll = 0;
	/* open as top window */
	wblock.next = (wimp_w)-1;
	/* window flags */
	wblock.flags = wimp_WINDOW_NEW_FORMAT | wimp_WINDOW_MOVEABLE | wimp_WINDOW_BOUNDED_ONCE | /* wimp_WINDOW_SIZE_ICON | wimp_WINDOW_VSCROLL |*/ wimp_WINDOW_TITLE_ICON | wimp_WINDOW_CLOSE_ICON | wimp_WINDOW_BACK_ICON /* | wimp_WINDOW_TOGGLE_ICON */;
	/* colours */
	wblock.title_fg = wimp_COLOUR_BLACK;
	wblock.title_bg = wimp_COLOUR_LIGHT_GREY;
	wblock.work_fg = wimp_COLOUR_BLACK;
	wblock.work_bg = wimp_COLOUR_TRANSPARENT;
	wblock.scroll_outer = wimp_COLOUR_MID_LIGHT_GREY;
	wblock.scroll_inner = wimp_COLOUR_VERY_LIGHT_GREY;
	wblock.highlight_bg = wimp_COLOUR_CREAM;
	/* work area extent - also almost irrelevant at this time */
	wblock.extent.x0 = 0 ;
	wblock.extent.y0 = -1000;
	wblock.extent.x1 = 1000;
	wblock.extent.y1 = 0;
	/* titlebar flags */
	wblock.title_flags = wimp_ICON_TEXT | wimp_ICON_INDIRECTED | wimp_ICON_FILLED  | wimp_ICON_HCENTRED | wimp_ICON_VCENTRED | wimp_ICON_BORDER  ;
	/* work area flags */
	wblock.work_flags =  (wimp_BUTTON_CLICK)  <<12;
	/* sprite area +1 apparently refers to WIMP area */
	wblock.sprite_area = (osspriteop_area *)1;
	/* minimum window size allowed */
	wblock.xmin = (short)0;
	wblock.ymin = (short)0;
	/* title data */
	wblock.title_data.indirected_text.text =  &imageName[0];
	wblock.title_data.indirected_text.validation = (char*)-1;
	wblock.title_data.indirected_text.size = strlen(imageName);
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
	setDefaultPointer();

	/* set the window size & position */
	SetInitialWindowSize();

	return;
}

void SetInitialWindowSize(void) {
/* set the size of the SQ window, assuming there is one.
	use the save window size value if the image had one,
	use half the screen width/height otherwise.
	If there is a window, do not use less than 64X64 pixels
*/
int maxWidth, maxHeight;
os_coord origin;

	/* is there an SQ window? */
	if ( sqWindowHandle == null ) {
		privateErr.errnum = 0;
		sprintf( privateErr.errmess, "Squeak has no window\n");
		platReportFatalError(&privateErr);
		return;
	}

	/* if there is, find the screen width, height, bpp etc */
	getDisplayParameters();

	if (savedWindowSize != 0) {
	} else {
		/* set h & w to half screen */
		squeakDisplaySize.x = screenSize.x / 2;
		squeakDisplaySize.y = screenSize.y / 2;
	}

	/* minimum size is 64 x 64 */
	squeakDisplaySize.x = ( squeakDisplaySize.x > 64) ? squeakDisplaySize.x : 64;
	squeakDisplaySize.y = ( squeakDisplaySize.y > 64) ? squeakDisplaySize.y : 64;

	/* maximum size is screen size (minus a little) */
	maxWidth  = (int)(screenSize.x * 0.9);
	maxHeight = (int)(screenSize.y * 0.9);
	squeakDisplaySize.x  = ( squeakDisplaySize.x <= maxWidth)  ?  squeakDisplaySize.x : maxWidth;
	squeakDisplaySize.y = (squeakDisplaySize.y <= maxHeight) ? squeakDisplaySize.y : maxHeight;

	origin.x = (int)(screenSize.x * 0.05);
	origin.y = (int)(screenSize.y * 0.95);
	setWindowParameters( &origin);
	
	return ;
}
int SetDisplayBitmap( int dispBitsIndex, int width, int height, int depth) {
/* setup the display bitmap */
int dispBits, sizeHdr, classHdr, basicHdr, hdrSize, byteSize;
int displayObj, w, h, d;
	/* if there is no stWindow yet, open the main window */
	if (sqWindowHandle == null) SetUpWindow();

	/* find the special object that is the display object*/
	displayObj = splObj(14);
	if (isPointers(displayObj) && (lengthOf(displayObj) >= 4)) {
		w = fetchIntegerofObject(1, displayObj);
		h = fetchIntegerofObject(2, displayObj);
		d = fetchIntegerofObject(3, displayObj);
		/* ought to double check the w/h/d against the passed in width/height/depth */
	}

	/* get the 0th oop from displayObj, the bits object */
	dispBits = fetchPointerofObject( 0, displayObj);
	/* cache the display bits header bytes ready to emplace in sprite. If we are re-doing the beDisplay, we may very well be nilling out these values in the current sprite ! */
	switch(hdrSize = extraHeaderBytes(dispBits)) {
		case 8: sizeHdr = longAt(dispBits - 8) /* sizeHeader(dispBits) */;
		case 4: classHdr = longAt( dispBits - 4)/* classHeader(dispBits) */;
		case 0: basicHdr = longAt(dispBits) /* baseHeader(dispBits) */;
		break;
	}

	/* create the RiscOS pixmap to the right dimensions */
	byteSize = ((w + 3)& ~3)  * h * d /8 ;
	byteSize += 4096;
	if ( spriteAreaPtr == NULL ) {
		/* if no sprite area yet, malloc enough room for bits + assorted headers */
		createSpriteArea( byteSize );
	} else if ( spriteAreaPtr->size < byteSize) {
		/* current size is too small, so free it and realloc */
		xosdynamicarea_delete ( SqueakDisplayDA );
		//free( spriteAreaPtr);
		createSpriteArea( byteSize );
	} 
	/* build the sprite area, sprite and translation table */
	SetupPixmap(w, h, d);
	SetupPixelTranslationTable();

	/* alter the window size to suit this display object */
	squeakDisplaySize.x = w;
	squeakDisplaySize.y = h;
	squeakDisplayDepth  = d;
	setWindowParameters( (os_coord *)null);

	/* insert the original header bytes in front of the Pixmap
	so that the plain header word is at ((int)displaySprite + displaySprite->image - 4) */
	displayBits = ((int)displaySprite + displaySprite->image - 4);
	switch(hdrSize) {
		case 8: *(int*)(displayBits-8) = sizeHdr;
		case 4: *(int*)(displayBits-4) = classHdr;
		case 0: *(int*)displayBits = basicHdr;
		break;
	}

	/* memcpy the image bits to the new bitmap, just in case anything interesting is supposed to be there */
	memcpy((void *)(displayBits+4), (void *)dispBitsIndex, (size_t)(((w + 3)& ~3)  * h * d /8));

	/* finally, link the Display object to the new DisplayBits object */
	storePointerofObjectwithValue(0, displayObj, displayBits);
	return true;
}

/*** I/O Primitives ***/

int ioBeep(void) {
	os_writec((char)7);
	return true;
}

int ioExit(void)
{
	exit(1);
	return 1;
}

int ioAssertion(void) {
 return 1;
 }
 
void exit_function(void)
{
/* do we need to do any special tidy up here ? RiscOS needs to kill the pointer bitmap */
extern void ioShutdownAllModules(void);
	ioShutdownAllModules(); 

	setDefaultPointer();
	if (SqueakObjectSpaceDA != (os_dynamic_area_no)NULL)
		xosdynamicarea_delete ( SqueakObjectSpaceDA );
	if (SqueakDisplayDA != (os_dynamic_area_no)NULL)
		xosdynamicarea_delete ( SqueakDisplayDA );
}

int ioGetButtonState(void) {
extern int buttonState;
	ioProcessEvents();  /* process all pending events */
	return buttonState;
}

int ioGetKeystroke(void) {
extern int nextKeyPressOrNil(void);

	ioProcessEvents();  /* process all pending events */
	return nextKeyPressOrNil();
}


int ioMicroMSecs(void) {
	/* The
   function ioMicroMSecs() is used only to collect timing statistics
   for the garbage collector and other VM facilities. (The function
   name is meant to suggest that the function is based on a clock
   with microsecond accuracy, even though the times it returns are
   in units of milliseconds.) This clock must have enough precision to
   provide accurate timings, and normally isn't called frequently
   enough to slow down the VM. Thus, it can use a more expensive clock
   that ioMSecs(). */
	return ioMSecs();
}



int ioMousePoint(void) {
extern os_coord savedMousePosition;
/* return the mouse point as 16bits of x | 16bits of y */
	ioProcessEvents();  /* process all pending events */
	return (savedMousePosition.x << 16 | savedMousePosition.y & 0xFFFF);
}

int ioPeekKeystroke(void) {
extern int peekKeyPressOrNil(void);

	ioProcessEvents();  /* process all pending events */
	return peekKeyPressOrNil();
}

int ioProcessEvents(void) {
	static clock_t nextPollTick = 0;
	clock_t currentTick;
	if( (currentTick = clock()) > nextPollTick) {
		HandleEvents(0 );
		nextPollTick = currentTick + 1;
	}
	return true; 
}


/*** I/O Primitives ***/

/* set an asynchronous input semaphore index for events */
int ioSetInputSemaphore(int semaIndex) {
primitiveFail();
}

/* retrieve the next input event from the OS */
int ioGetNextEvent(sqInputEvent *evt) {
primitiveFail();
}

int ioIsEventVM(void) {
	//return true;
	return false;
}


int ioEventHandle(void) {
/* do all the vm event stuff */
	ioProcessEvents();
	return 0;
}


int ioRelinquishProcessorForMicroseconds(int microSeconds) {
	/* This operation is platform dependent. On the Mac, it simply calls
	 * HandleEvents(), which gives other applications a chance to run.
	 * Here, we use microSeconds as the parameter to HandleEvents, so that wimpPollIdle
	 * gets a timeout.
	 */

	HandleEvents(microSeconds);
	return microSeconds;
}

int ioScreenSize(void) {
/* return the size of the SQ window in use */
int w = 10, h = 10;
int maxWidth, maxHeight;

	if (sqWindowHandle != null) {
		/* get extent  from window object */
		w = squeakDisplaySize.x;
		h = squeakDisplaySize.y;
	} else { /* derive from saved size in image */
		/* if there's no window yet, we need to check the screen metrics to make sure we
		   don't make too big a window later */
		getDisplayParameters();
		w = (unsigned) savedWindowSize >> 16 ;
		h = savedWindowSize & 0xFFFF;
		/* maximum size is screen size (minus a little) */
		maxWidth  = (int)screenSize.x ;
		maxHeight = (int)(screenSize.y * 0.9);
		w = (w <= maxWidth)  ? w : maxWidth;
		h = (h <= maxHeight) ? h : maxHeight;
	}

	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

int ioSeconds(void) {
	/*	  Unix epoch to Smalltalk epoch conversion.
		(Date newDay: 1 year: 1970) asSeconds
				- (Date newDay: 1 year: 1901) asSeconds
		is
				2177452800
		limit is about 2057ad- this may cause problems...
	*/
 
	return  (int)((unsigned long)time(NULL) + 2177452800uL);
}

int ioSetCursor(int cursorBitsIndex, int offsetX, int offsetY) {
	return ioSetCursorWithMask(cursorBitsIndex, NULL, offsetX, offsetY);
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
/* expand each bit in cursor bitmap to two bits in cursor h/w word */

	for (i = 0; i < 16; i++) {
		register int cursorWord, maskWord;
		register int j,line;
		cursorWord = (checkedLongAt(cursorBitsIndex + (4 * i)) ) >>16;
		 if (cursorMaskIndex != NULL) {
			maskWord = (checkedLongAt(cursorMaskIndex + (4 * i)) ) >>16;
		} else  maskWord = cursorWord;
		line = 0;
		for(j = 15; j >= 0; j--) {
				/* if the mask bit is 1, set 'white' and only then check the cursor word.
				   if it is 1 as well, set 'black' */
				if(maskWord & (1<<(j))) {
						line |= (1<< ((15-j)<<1));
						if(cursorWord & (1<<(j))) 
								line |= (2<< ((15-j)<<1));
				}
		}
		pointerBuffer[i] = line;
	}
	pointerOffset.x =  MIN(-offsetX, 15);
	pointerOffset.y = MIN(-offsetY, 15) ;
	if ( windowActive) {
		e = xwimp_set_pointer_shape(2, (byte const *)&pointerBuffer, 16, 16, pointerOffset.x, pointerOffset.y ); /* turn on pointer 2 */
	}

	return true;
}

int ioSetFullScreen(int fullScreen) {
	static os_coord prevOrigin = {0,0};
	int width, height, maxWidth, maxHeight;
	int oldWidth, oldHeight;
	wimp_window_info wblock;
	os_error * e;

	if (fullScreen) {
		os_coord screenTopLeft = {0,0};
		oldWidth = squeakDisplaySize.x;
		oldHeight = squeakDisplaySize.y;
		width  = screenSize.x;
		height = screenSize.y;
		if ((oldWidth < width) || (oldHeight < height)) {
			/* save old size if it wasn't already full-screen */ 
			savedWindowSize = (oldWidth << 16) + (oldHeight & 0xFFFF);
			squeakDisplaySize.x = width;
			squeakDisplaySize.y = height;
			/*  save the current window origin */
			wblock.w = sqWindowHandle;
			if ((e = xwimp_get_window_info(&wblock)) != NULL) {
				platReportFatalError(e);
				return false;
			}
			prevOrigin.x = wblock.visible.x0>>scalingFactor.x;
			prevOrigin.y = wblock.visible.y1>>scalingFactor.y;
		}
		setWindowParameters(&screenTopLeft);
	} else {
		squeakDisplaySize.x = (unsigned) savedWindowSize >> 16 ;
		squeakDisplaySize.y  = savedWindowSize & 0xFFFF;
		setWindowParameters( &prevOrigin);
	}
}

int ioShowDisplay( int dispBitsIndex, int width, int height, int depth, int affectedL, int affectedR, int affectedT, int affectedB) {
os_error *e;

	if(affectedR <= affectedL || affectedT >= affectedB) return true;

		/* If the latest display bitmap does not match the cached one, fix it up. Remember that the dispBitsIndex is the _body_ address not the _header_ address so subtract 4! */
	if( (dispBitsIndex-4) != displayBits ) {
		SetDisplayBitmap(dispBitsIndex, width, height, depth);
		//addEventToBuffer(1);
	}


	/* inform the Wimp of the affected area, scaled for the display mode etc */
	if( (e = xwimp_force_redraw( sqWindowHandle,
					affectedL<<scalingFactor.x,
					0-(affectedB<<scalingFactor.y),
					affectedR<<scalingFactor.x,
					0-(affectedT<<scalingFactor.y))) != NULL) {
		platReportFatalError(e);
		return false;
	}
	return true;
}

int ioForceDisplayUpdate(void) {
	ioProcessEvents();
//extern void DisplayPixmapNow(void);
//    DisplayPixmapNow();
}

int ioSetDisplayMode(int width, int height, int depth, int fullScreenFlag) {
	return false;
}

int ioScreenDepth(void) {
// what is the bpp setting of the screen right now?
	return BitsPerPixel;
}

int ioHasDisplayDepth(int bitsPerPixel) {
	switch(bitsPerPixel) {
		case 1:
		case 2:
		case 4:
		case 8:
		case 16:
		case 24:
		case 32: return true;
		default: return false;
	}
}

/*** Image File Naming ***/

void sqStringFromFilename( int sqString, char*fileName, int sqSize) {
// copy chars TO a Squeak String FROM a C filename char array. You may transform the characters as needed
	int i;
	char c;

	for (i = 0; i < sqSize; i++) {
		c =  *fileName++; ;
		if ( c =='.') c = '/';
		else if (c=='/') c = '.';
		*((char *) (sqString + i)) = c;
	}
}

void sqFilenameFromString(char*fileName, int sqString, int sqSize) {
// copy chars from a Squeak String to a C filename char array. You may transform the characters as needed
	int i;
	int junk;
	char c;
	char temp[1000];
	os_error * e;

	for (i = 0; i < sqSize; i++) {
		c =  *((char *) (sqString + i));
		if ( c =='.') c = '/';
		else if (c=='/') c = '.';
		temp[i] = c;
	}
	temp[i] = 0;
	if ((e = xosfscontrol_canonicalise_path (temp, fileName, (char const *) NULL, (char const *)NULL, 1000, &junk)) != null) {
		platReportError(e);
	}
}

int plugInAllowAccessToFilePath ( char * path, int size) {
// faked for now. What is really needed ?
	return true;
}

int imageNameSize(void) {
	return strlen(imageName);
}

int imageNameGetLength(int sqImageNameIndex, int length) {
int count;

	count = strlen(imageName);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	sqStringFromFilename( sqImageNameIndex, imageName, count);
}

int imageNamePutLength(int sqImageNameIndex, int length) {
char *sqImageName = (char *) sqImageNameIndex;
int count;
// should update the window struct details for title bar; length, address etc
	count = (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

	/* copy the file name into a null-terminated C string */
	sqFilenameFromString( imageName, sqImageNameIndex, count);
	return count;
}


/*** VM Home Directory Path ***/

int vmPathSize(void) {
	return strlen(vmPath);
}

int vmPathGetLength(int sqVMPathIndex, int length) {
char *stVMPath = (char *) sqVMPathIndex;
int count;

	count = strlen(vmPath);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	sqStringFromFilename( sqVMPathIndex, vmPath, count);
	return count;
}


/*** Clipboard Support (text only for now) Not integrated into the RiscOS clipboard system yet ***/
#define clipboardDefaultSize (10 * 1024)

int clipboardReadIntoAt(int count, int byteArrayIndex, int startIndex) {
// paste - clipboardSize() will actually do any fetching
	int clipSize, charsToMove;
	char *srcPtr, *dstPtr;
	clipSize = clipboardSize();
	charsToMove = (count < clipSize) ? count : clipSize;

	srcPtr = (char *) clipboardBuffer;
	dstPtr = (char *) byteArrayIndex + startIndex;
	copyNCharsFromTo( charsToMove, srcPtr, dstPtr);

	return charsToMove;
}

int clipboardSize(void)
{
	if (sqHasClipboard) {
		if ( clipboardByteSize == 0) {
			if ((clipboardBuffer = malloc (clipboardDefaultSize)) == null) return 0;
			clipboardByteSize = clipboardDefaultSize;
			memset(clipboardBuffer, 0, (size_t)clipboardDefaultSize);
			// *clipboardBuffer  = (char)NULL;
		}
	} else {
		// need to fetch the clipboard contents from the current holder
		fetchClipboard();
	} 
	return strlen(clipboardBuffer);
}

int clipboardWriteFromAt(int count, int byteArrayIndex, int startIndex) {
	int  charsToMove;
	char *srcPtr, *dstPtr, *newPtr;

	// write from the String to the clipboard buffer
	if ( clipboardByteSize < count) {
		/* try to realloc to match sizes */
		newPtr = realloc( clipboardBuffer, count+4);
		if ( newPtr != null ) {
				clipboardByteSize = count+4;
				clipboardBuffer = newPtr;
		}
	}
	charsToMove = (count < clipboardByteSize) ? count : clipboardByteSize;

	srcPtr = (char *) byteArrayIndex + startIndex;
	dstPtr = (char *) clipboardBuffer;
	copyNCharsFromTo( charsToMove,  srcPtr, dstPtr);

	// need to claim the clipboard
	if (!sqHasClipboard ) claimClipboard();

	return charsToMove;
}

/* null version */
int ioDisablePowerManager(int disableIfNonZero) {
return 0;
}

/*** Profiling ***/

int clearProfile(void) {
#ifdef MAKE_PROFILE
		ProfilerClear();
#endif
}

int dumpProfile(void) {
#ifdef MAKE_PROFILE
	ProfilerDump("\pProfile.out");
#endif
}

int startProfiling(void) {
#ifdef MAKE_PROFILE
	ProfilerSetStatus(true);
#endif
}

int stopProfiling(void) {
#ifdef MAKE_PROFILE
	ProfilerSetStatus(false);
#endif
}

/*** System Attributes ***/


char * getAttributeString(int id) {
	/* This is a hook for getting various status strings back from
	   the OS. In particular, it allows Squeak to be passed arguments
	   such as the name of a file to be processed. Command line options
	   could be reported this way as well.
	*/
char * tmp;
	if( (id < -1000) || (id >1004)) return "";

	switch (id) {
		case 0: return vmPath; break;
		case 1: if(newImageVersion) return imageName;
				else return "" /* imageName*/;
				break;
		case 1001: newImageVersion = 1; return "RiscOS"; break;  // this will only be called by a newer image that expects the filenames to be translated. I hope!
		case 1002: return "RiscOS 3.70"; break;
		case 1003: return "ARM"; break;
		case 1004: return  (char *)interpreterVersion; break;
		default: break;
	}
	if (id < 0) {
		if ( -id >= numOptionsVM) return "";
		tmp = vmOptions[-id];
		if (*tmp) return tmp;
	} 
	if (id > 1) {
		// we have an offset of 1 for + ids in order to accommodate the vmPath at 0
		if ( id > numOptionsImage) return "";
		tmp = imageOptions[id-1];
		if (*tmp) return tmp;
	} 
}

int attributeSize(int id) {
	return strlen(getAttributeString(id));
}

int getAttributeIntoLength(int id, int byteArrayIndex, int length) {
	char *srcPtr, *dstPtr, *end;
	int charsToMove;

	srcPtr = getAttributeString(id);
	charsToMove = strlen(srcPtr);
	if (charsToMove > length) {
		charsToMove = length;
	}

	dstPtr = (char *) byteArrayIndex;
	end = srcPtr + charsToMove;
	while (srcPtr < end) {
		*dstPtr++ = *srcPtr++;
	}
	return charsToMove;
}

/* Commandline option processing */
void helpMessage(char * progname) {
char runHelp[256];
	sprintf(runHelp, "chain:Filer_Run %s!Help\n", progname);
	system(runHelp); 
}

void versionMessage(char * progname) {
	privateErr.errnum = (bits)0;
	sprintf(privateErr.errmess, "This is version %s of %s.!Squeak\n", VMVersion, progname);
	platReportError((os_error *)&privateErr);
}


void decodePath(char *srcptr, char * dstPtr) {
os_error * e;
int spare;

	/* do the actual canonicalisation */
	if ((e = xosfscontrol_canonicalise_path (srcptr, dstPtr, (char const *) null, (char const *)null, VMPATH_SIZE, &spare)) != null) {
		platReportFatalError(e);
		return;
	}

}
void decodeVMPath(char *srcptr) {
char * endChar;

	decodePath(srcptr, vmPath);
	/* find the last dir separator in the string and zap it with a dirsep and
	   null to make the end of the string. */
	endChar = strrchr( vmPath, '.');
	if (endChar) *(++endChar) = null;

}

/*** Main ***/

int main(int argc,  char  *argv[]) {
FILE *f;
	parseArguments( argv, argc, args);

	if (versionMe) versionMessage(vmPath);
	if (helpMe) helpMessage(vmPath);

	atexit(exit_function);   // setup a clean exit function

	InitRiscOS();

	/* quick wimp_poll to allow icon to appear */
	{	wimp_event_no wimpPollEvent;
		wimp_block wimpPollBlock;
		int wimpPollWord;
		do xwimp_poll((wimp_MASK_POLLWORD| wimp_MASK_GAIN | wimp_MASK_LOSE | wimp_MASK_MESSAGE | wimp_MASK_RECORDED | wimp_SAVE_FP) , &wimpPollBlock,  &wimpPollWord, (wimp_event_no*)&wimpPollEvent);
		while (wimpPollEvent != wimp_NULL_REASON_CODE);
	}

	/* read the image file and allocate memory for Squeak heap */
	f = fopen(imageName, "rb");
	if (f == NULL) {
		/* give a RPC-specific error message if image file is not found */
		privateErr.errnum = (bits)0;
		sprintf(privateErr.errmess, "Could not open the Squeak image file '%s'\n", imageName);
		platReportFatalError((os_error *)&privateErr);
		ioExit();
	}
	readImageFromFileHeapSize(f, objectHeadroom);
	fclose(f);


	/* run Squeak */
	interpret();
}

