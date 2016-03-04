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


/* How to use this file:
   This file is for general platform-specific macros and declarations.
   The goal is to keep most of the other header files generic across platforms.
   To override a definition or macro from sq.h, you must first #undef it, then
   provide the new definition.

*/

/* This odd looking declaration is to allow the global variable foo to be
 * kept in a register all the time. This produces an approx 30% speedup */
#ifdef ACORN

#pragma -r1
extern struct foo * foo;
#pragma -r0

#include "oslib/os.h"
#include "oslib/wimp.h"
#include "oslib/osspriteop.h"

/* acorn memory allocation */
#undef sqAllocateMemory
int platAllocateMemory(int amount);
#define sqAllocateMemory(minHeapSize, desiredHeapSize) platAllocateMemory(desiredHeapSize)

#undef sqFilenameFromString
extern int canonicalizeFilenameToString(char * sqString, int sqSize, char * cString);
#define sqFilenameFromString(dst, src, num) (canonicalizeFilenameToString((char*)src, (int)num, (char*)dst))

#define sqGetFilenameFromString(dst, src, sz, aBoolean)\
 canonicalizeFilenameToString(src, sz, dst)

int sqCopyFilesizetosize(char *srcName, int srcNameSize, char *dstName, int dstNameSize);

#undef sqImageFileRead
size_t sqImageFileRead(void *ptr, size_t sz, size_t count, FILE* f);

#undef sqImageFileWrite
size_t sqImageFileWrite(void *ptr, size_t sz, size_t count, FILE* f);

#define squeakFileOffsetType int

/* string copying macro to compensate for bug in Acorn library code */
#define copyNCharsFromTo(num, src, dst)\
if(1) {int sqfni;\
	char cc;\
	for (sqfni = 0; sqfni < num; sqfni++) {\
		dst[sqfni] = cc = *((char *) (src + sqfni));\
		if ( cc == 0) break;\
	}\
	dst[num] = 0;\
}

/* less important timer, return mSec values but can be lower actual resolution */
/* a high-res timer for debugging */
unsigned int microsecondsvalue(void);


usqInt millisecondTimerValue(void);
#define ioMSecs()  (sqInt)(millisecondTimerValue())


/* extended fileplugin support */
extern int dir_DirectoryExists(char *pathString, int pathStringLength);
extern int dir_FileExists(char *pathString, int pathStringLength);
extern void dir_SetImageFileType(void);

/* Debugging support - printf is #def'd to repprint which outputs to
 * a logfile or to !Reporter if it is active
 */
#ifdef DEBUG
#define PRINTF(s)\
{\
	repprintf s;\
};
#else
#define PRINTF(s)
#endif

extern int repprintf(const char * format, ...);
extern int repfprintf(FILE *strm, const char * format, ...);
#define printf repprintf
#define fprintf repfprintf
#define MAXDIRNAMELENGTH 1024

#ifndef MIN
#define MIN( a, b )   ( ( (a) < (b) ) ? (a) : (b) )
#define MAX( a, b )   ( ( (a) > (b) ) ? (a) : (b) )
#endif

/* multiple host windows stuff */
typedef struct windowDescriptorBlock {
	struct windowDescriptorBlock * next;
	wimp_w			handle;
	int				windowIndex;
	os_coord		bitmapExtentP;
	os_box			visibleArea;  // rename to visibleArea
	int				squeakDisplayDepth;
	osspriteop_header *	displaySprite; // the sprite pointer
	char			spriteName[12];
#define WindowTitleLength 150
	char			title[WindowTitleLength + 2];
	wimp_window_flags attributes;
	osspriteop_trans_tab *	pixelTranslationTable;
} windowDescriptorBlock;

extern windowDescriptorBlock *windowBlockFromHandle(wimp_w windowHandle);
extern int windowIndexFromBlock( windowDescriptorBlock * thisWindow);
extern int windowIndexFromHandle(wimp_w windowHandle);

#define OS2PixX(val) ((val)>>scalingFactor.x)
#define OS2PixY(val) ((val)>>scalingFactor.y)

#define Pix2OSX(val) ((val)<<scalingFactor.x)
#define Pix2OSY(val) ((val)<<scalingFactor.y)


#else

#endif /* ACORN */
