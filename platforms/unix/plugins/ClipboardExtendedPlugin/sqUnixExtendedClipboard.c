/*  sqUnixExtendedClipboard.c  -- support for clipboard with multiple types
 *
 * Copyright (C) 2007 by Viewpoints Research Institute and other
 *                             authors/contributors as listed.
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

#include "sqVirtualMachine.h"
extern struct VirtualMachine *interpreterProxy;

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

extern Display *stDisplay;

char **clipboardGetTypeNames();
sqInt clipboardSizeWithType(char *typeName, int ntypeName);
sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex);
void *firstIndexableField(sqInt oop);
void clipboardWriteWithType(char *data, size_t ndata, char *typeName, size_t ntypeName, int isDnd, int isClaiming);

// TODO: clipboardGetTypeNames() should be cached. And the simplest way to do
// this is to have display_clipboardGetTypeNames do the cacheing and freeing,
// it freeing the previous invocation's data if the clipboard has changed,
// then all the multiple frees below can disappear. Further, the signature can
// be changed to include a pointer to the item count and then the indexing
// can safely be done directly. eem. '23/3/25

/* In X11 clipboard is global in a display, so just return 1 */
sqInt
sqCreateClipboard(void) { return 1; }

void
sqPasteboardClear(sqInt inPasteboard)
{
// perhaps PrimErrUnsupported is better, but it's inaccurate
// we don't yet have PrimErrUnimplemented

	// i.e. this still has to be implemented
	interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
}

/* Return a number of types.
 * Update it only if the selection is CLIPBOARD
 */
int
sqPasteboardGetItemCount(sqInt inPasteboard)
{
	int i;
	char **types = clipboardGetTypeNames();
	if (!types)
		return 0;
	for (i = 0; types[i]; i++)
		free(types[i]); /* XFree() is better */
	free(types);
	return i;
}

/* Answer a type name at index. */
int
sqPasteboardCopyItemFlavorsitemNumber(sqInt inPasteboard, sqInt formatNumber)
{
	int i;
	sqInt outData = 0;
	char **types = clipboardGetTypeNames();

	if (!types)
		return 0;
	for (i = 0; types[i]; i++) {
		if (i + 1 == formatNumber) {
			int length = strlen(types[i]);
			outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), length);

			memcpy(	interpreterProxy->firstIndexableField(outData),
					types[i],
					length);
		}
		free(types[i]); /* XFree() is better */
	}
	free(types);
	return outData;
}

void
sqPasteboardPutItemFlavordatalengthformatTypeformatLength(sqInt inPasteboard, char *data, sqInt ndata, char *typeName, sqInt ntypeName)
{
	clipboardWriteWithType(data, ndata, typeName, ntypeName, 0, 1);
}


void
sqPasteboardPutItemFlavordatalengthformatType(sqInt inPasteboard, char *inData, sqInt dataLength, sqInt format)
{
	interpreterProxy->primitiveFailFor(PrimErrUnsupported);
}


/* Read the clipboard */
int
sqPasteboardCopyItemFlavorDataformatformatLength(sqInt inPasteboard, char *format, sqInt formatLength)
{
	int bytes = clipboardSizeWithType(format, formatLength);
	sqInt outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), bytes);
	clipboardReadIntoAt(bytes, (sqInt) firstIndexableField(outData), 0);
	return outData;
}

sqPasteboardCopyItemFlavorDataformat(sqInt inPasteboard, sqInt format)
{
	interpreterProxy->primitiveFailFor(PrimErrUnsupported);
	return interpreterProxy->nilObject();
}

sqInt
sqPasteboardhasDataInFormatformatLength(sqInt inPasteboard, char *format, sqInt formatLength)
{
	int i, found = 0;
	char **types = clipboardGetTypeNames();

	if (!types)
		return 0;
	for (i = 0; types[i]; i++) {
		if (strlen(types[i]) == formatLength
		 && !strncmp(types[i],format,formatLength))
			found = 1;
		free(types[i]); /* XFree() is better */
	}
	free(types);
	return found;
}

sqInt
sqPasteboardhasDataInFormat(sqInt inPasteboard, sqInt format)
{
	interpreterProxy->primitiveFailFor(PrimErrUnsupported);
	return interpreterProxy->nilObject();
}
