/* sqPlatformSpecific.h -- platform-specific modifications to sq.h
 * 
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
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
 * Author: ian.piumarta@squeakland.org
 * 
 * Last edited: 2005-03-28 22:59:56 by piumarta on emilia.local
 */

/* undefine clock macros (these are implemented as functions) */

#undef ioMSecs
#undef ioMicroMSecs
#undef ioLowResMSecs

#undef sqAllocateMemory
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

#include "sqMemoryAccess.h"

extern sqInt sqAllocateMemory(sqInt minHeapSize, sqInt desiredHeapSize);
extern sqInt sqGrowMemoryBy(sqInt oldLimit, sqInt delta);
extern sqInt sqShrinkMemoryBy(sqInt oldLimit, sqInt delta);
extern sqInt sqMemoryExtraBytesLeft(sqInt includingSwap);

#include <sys/types.h>

typedef off_t squeakFileOffsetType;

#undef	sqFilenameFromString
#undef	sqFilenameFromStringOpen
#define sqFilenameFromStringOpen sqFilenameFromString

extern void sqFilenameFromString(char *uxName, sqInt stNameIndex, int sqNameLength);

#undef dispatchFunctionPointer
#undef dispatchFunctionPointerOnin
/* we'd like to untypedef fptr too, but such is life */

#include <unistd.h>

#undef	sqFTruncate
#define	sqFTruncate(f,o) ftruncate(fileno(f), o)

#ifndef __GNUC__
# if HAVE_ALLOCA_H
#   include <alloca.h>
# else
#   ifdef _AIX
#     pragma alloca
#   else
#     ifndef alloca /* predefined by HP cc +Olibcalls */
        char *alloca();
#     endif
#   endif
# endif
#endif
