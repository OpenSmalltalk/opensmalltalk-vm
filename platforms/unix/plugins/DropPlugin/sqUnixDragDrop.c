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
 * 
 * Last edited: 2008-11-10 13:19:29 by piumarta on ubuntu.piumarta.com
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
#include "sqVirtualMachine.h"
#include "FilePlugin.h"
#include "DropPlugin.h"

#include <assert.h>


extern struct VirtualMachine  *interpreterProxy;
extern int		       uxDropFileCount;
extern char		     **uxDropFileNames;

SQFile *fileValueOf(sqInt objectPointer);
sqInt 	instantiateClassindexableSize(sqInt classPointer, sqInt size);
sqInt 	classByteArray(void);
sqInt 	fileRecordSize(void);
sqInt 	sqFileOpen(SQFile *f, char *sqFileName, sqInt sqFileNameSize, sqInt writeFlag);
sqInt 	dndOutStart(char *types, int ntypes);
sqInt 	dndOutAcceptedType(char *type, int ntype);
void    dndOutSend(char *bytes, int nbytes);

sqInt dropInit(void)	{ return 1; }
sqInt dropShutdown(void)	{ return 1; }

char *dropRequestFileName(sqInt dropIndex)	/* in st coordinates */
{
  if ((dropIndex > 0) && (dropIndex <= uxDropFileCount))
    {
      assert(uxDropFileNames);
      return uxDropFileNames[dropIndex - 1];
    }
  return 0;
}

sqInt dropRequestFileHandle(sqInt dropIndex)
{
  char *path= dropRequestFileName(dropIndex);
  if (path)
    {
      /* you cannot be serious? */
      int handle= instantiateClassindexableSize(classByteArray(), fileRecordSize());
      sqFileOpen((SQFile *)fileValueOf(handle), path, strlen(path), 0);
      return handle;
    }  
  return interpreterProxy->nilObject();
}

void sqDndOutStart(char *types, int ntypes)
{
  /* XDnD supports up to 3 types */
  if (!dndOutStart(types, ntypes))
    interpreterProxy->success(false);
}

int sqDndOutAcceptedType(void)
{
  int outData;
  char *dest;
  size_t nbuf;
  char buf[256];

  int result= dndOutAcceptedType(buf, 256);
  if (result == 0) return interpreterProxy->nilObject();

  nbuf= strlen(buf);
  outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), nbuf);
  dest = ((char *) (interpreterProxy->firstIndexableField(outData)));
  memcpy(dest, buf, nbuf);

  return outData;
}

void sqDndOutSend(char *aByteArray, int nbytes)
{
  dndOutSend(aByteArray, nbytes);
}

sqInt  sqSecFileAccessCallback(void *callback)		 { return 0; }
void sqSetNumberOfDropFiles(sqInt numberOfFiles)		 { }
void sqSetFileInformation(sqInt dropIndex, void *dropFile) { }
