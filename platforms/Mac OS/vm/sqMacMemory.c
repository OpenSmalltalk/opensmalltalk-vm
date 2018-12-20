/****************************************************************************
*   PROJECT: Mac allocate memory from somewhere for the image
*   FILE:    sqMacMemory.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMemory.c 1708 2007-06-10 00:40:04Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar  8th, 2002, JMM Must unmap view first then free.
*  3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
*  3.5.1b5 June 25th, 2003 JMM get memory upper limit from os-x user preferences
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
*	3.8.14b1 Oct	,2006 JMM browser rewrite

*****************************************************************************/

#include "sq.h" 
#include "sqMacMemory.h"
#include "sqMacMain.h"

#include <sys/mman.h>
#include <unistd.h>

extern usqLong  gMaxHeapSize;
static usqLong	gHeapSize;
void *mmapWasAt;

/* compute the desired memory allocation */

static usqInt	memoryAllocationBase;
static int	    pageSize = 0;
static unsigned int pageMask = 0;

#define roundDownToPage(v) ((v)&pageMask)
#define roundUpToPage(v) (((v)+pageSize-1)&pageMask)

usqInt
sqGetAvailableMemory()
{
	/******
	  Note:  (Except Spur)
	    For os-x this doesn't matter we just mmap 512MB for the image, and 
	    the application allocates more out of the 4GB address for VM logic. 
	******/

	return gMaxHeapSize >= 0xFFFFFFFFULL ? 0xFFFFFFFF : gMaxHeapSize;
}

usqInt
sqAllocateMemoryMac(usqInt desiredHeapSize, usqInt minHeapSize)
{
    void * debug, *actually;
#if SPURVM
	pageSize= getpagesize();
	pageMask= ~(pageSize - 1);

    gHeapSize = roundUpToPage(desiredHeapSize);
    debug = mmap(NULL, gHeapSize,PROT_READ|PROT_WRITE,MAP_ANON|MAP_SHARED,-1,0);
#else
# pragma unused(minHeapSize,desiredHeapSize)

	pageSize= getpagesize();
	pageMask= ~(pageSize - 1);
    gHeapSize = gMaxHeapSize;
    debug = mmap( NULL, gMaxHeapSize+pageSize, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED,-1,0);
#endif /* SPURVM */

    if (debug == MAP_FAILED)
        return 0;
	mmapWasAt = debug;
	actually = debug+pageSize-1;
	actually = (void*) (((usqInt) actually) & pageMask);

	return memoryAllocationBase = (usqInt) actually;
}

#if !SPURVM
sqInt
sqGrowMemoryBy(sqInt memoryLimit, sqInt delta)
{
    if ((usqInt) memoryLimit + (usqInt) delta - memoryAllocationBase > gMaxHeapSize)
        return memoryLimit;

    gHeapSize += delta;
    return memoryLimit + delta;
}

sqInt
sqShrinkMemoryBy(sqInt memoryLimit, sqInt delta)
{
    return sqGrowMemoryBy(memoryLimit,0-delta);
}

sqInt
sqMemoryExtraBytesLeft(int flag)
{
    return flag ? gMaxHeapSize - gHeapSize : 0;
}
#endif /* ! SPURVM */

void
sqMacMemoryFree()
{
	if (!memoryAllocationBase) 
		return;
#if SPURVM
	/* N.B. This is a hack for an unsupported configuration (NSPlugin(*/
	/* If we really need to free memry we need to unmap all segments. */
	/* But right now this is called only on exit and so is unnecessary. */
	if (munmap((void *)memoryAllocationBase,gHeapSize))
		perror("munmap");
#else
	if (munmap((void *)memoryAllocationBase,gMaxHeapSize+pageSize))
		perror("munmap");
#endif
	memoryAllocationBase = 0;
}

#if COGVM
void
sqMakeMemoryExecutableFromTo(unsigned long startAddr, unsigned long endAddr)
{
	unsigned long firstPage = roundDownToPage(startAddr);
	if (mprotect((void *)firstPage,
				 endAddr - firstPage + 1,
				 PROT_READ | PROT_WRITE | PROT_EXEC) < 0)
		perror("mprotect(x,y,PROT_READ | PROT_WRITE | PROT_EXEC)");
}

void
sqMakeMemoryNotExecutableFromTo(unsigned long startAddr, unsigned long endAddr)
{
# if 0
	/* We get EACCESS on 10.6.3 when trying to disable exec perm; Why? */
	/* Arguably this is pointless since allocated memory always does include
	 * write permission.  Annoyingly the mprotect call fails on both linux &
	 * mac os x.  So make the whole thing a nop.
	 */
	unsigned long firstPage = roundDownToPage(startAddr);
	if (mprotect((void *)firstPage,
				 endAddr - firstPage + 1,
				 PROT_READ | PROT_WRITE) < 0
	 && errno != EACCES)
		perror("mprotect(x,y,PROT_READ | PROT_WRITE)");
# endif
}
#endif /* COGVM */

#if SPURVM
/* Allocate a region of memory of al least size bytes, at or above minAddress.
 *  If the attempt fails, answer null.  If the attempt succeeds, answer the
 * start of the region and assign its size through allocatedSizePointer.
 */
void *
sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(sqInt size, void *minAddress, sqInt *allocatedSizePointer)
{
	void *alloc;
	long bytes = roundUpToPage(size);

	if (!pageSize) {
		pageSize = getpagesize();
		pageMask = pageSize - 1;
	}
	*allocatedSizePointer = bytes;
	while ((char *)minAddress + bytes > (char *)minAddress) {
		alloc = mmap((void *)roundUpToPage((unsigned long)minAddress), bytes,
					PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0);
		if (alloc == MAP_FAILED) {
			perror("sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto mmap");
			return 0;
		}
		if (alloc >= minAddress)
			return alloc;
		if (munmap(alloc, bytes) != 0)
			perror("sqAllocateMemorySegment... munmap");
		minAddress = (void *)((char *)minAddress + bytes);
	}
	return 0;
}

/* Deallocate a region of memory previously allocated by
 * sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto.  Cannot fail.
 */
void
sqDeallocateMemorySegmentAtOfSize(void *addr, sqInt sz)
{
	if (munmap(addr, sz) != 0)
		perror("sqDeallocateMemorySegment... munmap");
}
#endif /* SPURVM */
