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

extern usqInt  gMaxHeapSize;
static usqInt	gHeapSize;
void *mmapWasAt;

/* compute the desired memory allocation */

static usqInt	memoryAllocationBase;
static int	    pageSize = 0;
static unsigned int pageMask = 0;

usqInt	sqGetAvailableMemory() {

	sqInt 	availableMemory;
	
	availableMemory = gMaxHeapSize;

	/******
	  Note: 	    
	    For os-x this doesn't matter we just mmap 512MB for the image, and 
	    the application allocates more out of the 4GB address for VM logic. 
	******/

	return availableMemory;
}

usqInt sqAllocateMemoryMac(sqInt minHeapSize, sqInt desiredHeapSize) {
    void * debug, *actually;
	#pragma unused(minHeapSize,desiredHeapSize)
     
	pageSize= getpagesize();
	pageMask= ~(pageSize - 1);
    gHeapSize = gMaxHeapSize;
    debug = mmap( NULL, gMaxHeapSize+pageSize, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED,-1,0);
    //debug = mmap( /*2147483648U-512*1024*1024*/
	//			3221225472U, gMaxHeapSize+pageSize , PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED,-1,0);
	
    if(debug == MAP_FAILED)
        return 0;
	mmapWasAt = debug;
	actually = debug+pageSize-1;
	actually = (void*) (((usqInt) actually) & pageMask);
	
	return memoryAllocationBase = (usqInt) actually;
}

sqInt sqGrowMemoryBy(sqInt memoryLimit, sqInt delta) {
    if ((usqInt) memoryLimit + (usqInt) delta - memoryAllocationBase > gMaxHeapSize)
        return memoryLimit;
   
    gHeapSize += delta;
    return memoryLimit + delta;
}

sqInt sqShrinkMemoryBy(sqInt memoryLimit, sqInt delta) {
    return sqGrowMemoryBy(memoryLimit,0-delta);
}

sqInt sqMemoryExtraBytesLeft(int flag) {
    return (flag) ? gMaxHeapSize - gHeapSize : 0;
}

void sqMacMemoryFree() {
	if (memoryAllocationBase == nil) 
		return;
	if (munmap((void *)memoryAllocationBase,gMaxHeapSize+pageSize))
		perror("munmap");
	memoryAllocationBase = nil;
}

#if COGVM
# define roundDownToPageBoundary(v) ((v)&pageMask)
# define roundUpToPageBoundary(v) (((v)+pageSize-1)&pageMask)
void
sqMakeMemoryExecutableFromTo(unsigned long startAddr, unsigned long endAddr)
{
	unsigned long firstPage = roundDownToPageBoundary(startAddr);
	if (mprotect((void *)firstPage,
				 endAddr - firstPage + 1,
				 PROT_READ | PROT_WRITE | PROT_EXEC) < 0)
		perror("mprotect(x,y,PROT_READ | PROT_WRITE | PROT_EXEC)");
}

void
sqMakeMemoryNotExecutableFromTo(unsigned long startAddr, unsigned long endAddr)
{
	unsigned long firstPage = roundDownToPageBoundary(startAddr);
	/* We get EACCESS on 10.6.3 when trying to disable exec perm; Why? */
	if (mprotect((void *)firstPage,
				 endAddr - firstPage + 1,
				 PROT_READ | PROT_WRITE) < 0
	 && errno != EACCES)
		perror("mprotect(x,y,PROT_READ | PROT_WRITE)");
}
#endif /* COGVM */
