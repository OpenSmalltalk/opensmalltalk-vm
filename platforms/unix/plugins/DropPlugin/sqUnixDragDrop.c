/* sqUnixDragDrop.c -- support for drag and drop, for those UIs that have it
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 *   Copyright (C) 1996-2002 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
 *   All rights reserved.
 *   
 *     You are NOT ALLOWED to distribute modified versions of this file
 *     under its original name.  If you want to modify it and then make
 *     your modifications available publicly, rename the file first.
 * 
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 * Last edited: 2002-12-06 11:07:42 by piumarta on calvin.local.
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


int dropInit(void)	{ return 1; }
int dropShutdown(void)	{ return 1; }

char *dropRequestFileName(int dropIndex)	// in st coordinates
{
  if ((dropIndex > 0) && (dropIndex <= uxDropFileCount))
    {
      assert(uxDropFileNames);
      return uxDropFileNames[dropIndex - 1];
    }
  return 0;
}

int dropRequestFileHandle(int dropIndex)
{
  char *path= dropRequestFileName(dropIndex);
  if (path)
    {
      // you cannot be serious?
      int handle= instantiateClassindexableSize(classByteArray(), fileRecordSize());
      sqFileOpen((SQFile *)fileValueOf(handle), (int)path, strlen(path), 0);
      return handle;
    }  
  return interpreterProxy->nilObject();
}

int  sqSecFileAccessCallback(void *callback)		 { return 0; }
void sqSetNumberOfDropFiles(int numberOfFiles)		 { }
void sqSetFileInformation(int dropIndex, void *dropFile) { }
