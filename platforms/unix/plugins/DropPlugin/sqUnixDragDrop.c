/* sqUnixDragDrop.c -- support for drag and drop, for those UIs that have it
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

/* Why on earth does this plugin exist at all?  Brain death strikes
 * again.  And why are half the functions never called from the VM?
 * Could it be that they are only there for certain ports (we'll
 * mention no names) in which the core support needs to grub around in
 * this plugin via ioLoadFunctionFromModule (and, putting disbelief
 * aside for a moment, maybe even VICE-VERSA)?  It seems to me that
 * truth is very definitely not beauty today.  Sigh...
 */

#include "sq.h"
#include "sqAssert.h"
#include "sqVirtualMachine.h"
#include "FilePlugin.h"
#include "DropPlugin.h"

extern struct VirtualMachine  *interpreterProxy;
extern int						uxDropFileCount;
extern char					  **uxDropFileNames;
extern void						dndReceived(char *fileName);

#if defined(SQUEAK_INTERNAL_PLUGIN)
extern SQFile * fileValueOf(sqInt objectPointer);
#else
/*	Return a pointer to the first byte of of the SQFile data structure file
	record within anSQFileRecord, which is expected to be a ByteArray of size
	self>>fileRecordSize. 
 */

	/* OSProcessPlugin>>#fileValueOf: */
static SQFile *
fileValueOf(sqInt anSQFileRecord)
{
	return interpreterProxy->arrayValueOf(anSQFileRecord);
}
#endif /* defined(SQUEAK_INTERNAL_PLUGIN) */

sqInt dropInit(void)     { return 1; }
sqInt dropShutdown(void) { return 1; }

/* We now set USE_FILE_URIs to 1 in platforms/unix//vm-display-X11/sqUnixXdnd.c
 * hence dropRequestFileName skips the URI prefix and dropRequestURI includes it
 */
char *
dropRequestFileName(sqInt dropIndex)	// in st coordinates
{
	char *fileURIPrefix = "file:///";
	int prefixLength = 0;
	char *dropFileName;

	if (dropIndex <= 0 || dropIndex > uxDropFileCount)
		return 0;

	assert(uxDropFileNames);
	dndReceived(uxDropFileNames[dropIndex - 1]);

	// The three valid schemes are
	// file://host/path (prefix length 7)
	// file:///path     (prefix length 8)
	// file:/path 		(prefix length 6)
	// see https://en.wikipedia.org/wiki/File_URI_scheme

	// Compute the length of the prefix...
	if (!(dropFileName = uxDropFileNames[dropIndex - 1]))
		return 0;
	while (*fileURIPrefix && *fileURIPrefix++ == *dropFileName++)
		++prefixLength;

	// file:///path & file:/path => path; anything else answered verbatim
	return prefixLength == 8 || prefixLength == 6
		? uxDropFileNames[dropIndex - 1] + prefixLength
		: uxDropFileNames[dropIndex - 1];
}

char *
dropRequestURI(sqInt dropIndex)	// in st coordinates
{
	if (dropIndex <= 0 || dropIndex > uxDropFileCount)
		return 0;

	assert(uxDropFileNames);
	dndReceived(uxDropFileNames[dropIndex - 1]);
	return uxDropFileNames[dropIndex - 1];
}

sqInt
dropRequestFileHandle(sqInt dropIndex)
{
	char *path= dropRequestFileName(dropIndex);
	if (path) {
		// you cannot be serious?
		sqInt handle = instantiateClassindexableSize(classByteArray(), fileRecordSize());
		sqFileOpen(fileValueOf(handle), path, strlen(path), 0);
		return handle;
	}  
	return interpreterProxy->nilObject();
}
