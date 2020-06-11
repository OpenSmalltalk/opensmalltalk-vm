#include "pharovm/pharo.h"
#include <sys/mman.h>
#include <fcntl.h>
#include <signal.h>


#define roundDownToPage(v) ((v)&pageMask)
#define roundUpToPage(v) (((v)+pageSize-1)&pageMask)

sqInt uxMemoryExtraBytesLeft(sqInt includingSwap);

#if !defined(MAP_ANON)
# if defined(MAP_ANONYMOUS)
#   define MAP_ANON MAP_ANONYMOUS
# else
#   define MAP_ANON 0
# endif
#endif

#define MAP_PROT	(PROT_READ | PROT_WRITE)

#define MAP_FLAGS	(MAP_ANON | MAP_PRIVATE)

#define valign(x)	((x) & pageMask)

/*xxx THESE SHOULD BE COMMAND-LINE/ENVIRONMENT OPTIONS */
/* Note:
 *
 *   The code allows memory to be overallocated; i.e., the initial
 *   block is reserved via mmap() and then the unused portion
 *   munmap()ped from the top end.  This is INHERENTLY DANGEROUS since
 *   malloc() may randomly map new memory in the block we "reserved"
 *   and subsequently unmap()ped.  Enabling this causes crashes in
 *   Croquet, which makes heavy use of the FFI and thus calls malloc()
 *   all over the place.
 *
 *   For this reason, overallocateMemory is DISABLED by default.
 *
 *   The upshot of all this is that Squeak will claim (and hold on to)
 *   ALL of the available virtual memory (or at least 75% of it) when
 *   it starts up.  If you can't live with that, use the -memory
 *   option to allocate a fixed size heap.
 */

int overallocateMemory	= 0;

static sqInt   devZero	= -1;
static char *heap	=  0;
static sqInt   heapSize	=  0;
static sqInt   heapLimit	=  0;

#ifndef max
# define max(a, b)  (((a) > (b)) ? (a) : (b))
#endif
#ifndef min
# define min(a, b)  (((a) < (b)) ? (a) : (b))
#endif

static sqInt pageSize = 0;
static usqInt pageMask = 0;
int mmapErrno = 0;


void
sqMakeMemoryExecutableFromTo(unsigned long startAddr, unsigned long endAddr)
{
	sqInt firstPage = roundDownToPage(startAddr);
	if (mprotect((void *)firstPage,
				 endAddr - firstPage + 1,
				 PROT_READ | PROT_WRITE | PROT_EXEC) < 0){
		logWarn("mprotect(x,y,PROT_READ | PROT_WRITE | PROT_EXEC)");
		logWarn("ERRNO: %d\n", errno);
	}
}

void
sqMakeMemoryNotExecutableFromTo(unsigned long startAddr, unsigned long endAddr)
{
	sqInt firstPage = roundDownToPage(startAddr);
	/* Arguably this is pointless since allocated memory always does include
	 * write permission.  Annoyingly the mprotect call fails on both linux &
	 * mac os x.  So make the whole thing a nop.
	 */
//	if (mprotect((void *)firstPage,
//				 endAddr - firstPage + 1,
//				 PROT_READ | PROT_WRITE) < 0)
//		logErrorFromErrno("mprotect(x,y,PROT_READ | PROT_WRITE)");
}

/* answer the address of (minHeapSize <= N <= desiredHeapSize) bytes of memory. */

usqInt
sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize, usqInt desiredBaseAddress) {

	if (heap) {
		logError("uxAllocateMemory: already called\n");
		exit(1);
	}

	pageSize = getpagesize();
	pageMask = ~(pageSize - 1);

	heapLimit = valign(max(desiredHeapSize, 1));
	usqInt desiredBaseAddressAligned = valign(desiredBaseAddress);

	logDebug("Trying to load the image in %p\n",
			(void* )desiredBaseAddressAligned);

	while ((!heap) && (heapLimit >= minHeapSize)) {
		if (MAP_FAILED == (heap = mmap((void*) desiredBaseAddressAligned, heapLimit, MAP_PROT, MAP_FLAGS, devZero, 0))) {
			heap = 0;
			heapLimit = valign(heapLimit / 4 * 3);
		}

/*
 * If we are in linux we have the problem that maybe it gives us a memory location too high in the memory map.
 * To avoid it, we force to use the required base address
 */
#ifndef __APPLE__
		if(heap != MAP_FAILED && heap != desiredBaseAddressAligned){

			desiredBaseAddressAligned = valign(desiredBaseAddressAligned + pageSize);

			if(heap < desiredBaseAddress){
				logError("I cannot find a good memory address starting from: %p", (void*)desiredBaseAddress);
				exit(-1);
			}

			//If I overflow.
			if(desiredBaseAddress > desiredBaseAddressAligned){
				logError("I cannot find a good memory address starting from: %p", (void*)desiredBaseAddress);
				exit(-1);
			}

			munmap(heap, heapLimit);
			heap = 0;
		}
#endif
	}

	if (!heap) {
		logError("Failed to allocate at least %lld bytes)\n",
				(long long )minHeapSize);
		exit(-1);
	}

	heapSize = heapLimit;

	logDebug("Loading the image in %p\n", (void* )heap);

	return (usqInt) heap;
}

/* answer the number of bytes available for growing the heap. */

sqInt uxMemoryExtraBytesLeft(sqInt includingSwap)
{
  return heapLimit - heapSize;
}


sqInt sqMemoryExtraBytesLeft(sqInt includingSwap)			{ return uxMemoryExtraBytesLeft(includingSwap); }


/* Deallocate a region of memory previously allocated by
 * sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto.  Cannot fail.
 */
void
sqDeallocateMemorySegmentAtOfSize(void *addr, sqInt sz)
{
	if (munmap(addr, sz) != 0)
		logErrorFromErrno("sqDeallocateMemorySegment... munmap");
}

void *
sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(sqInt size, void *minAddress, sqInt *allocatedSizePointer)
{
	void *alloc;
	long bytes = roundUpToPage(size);
	void *startAddress;
	int count = 0;

	if (!pageSize) {
		pageSize = getpagesize();
		pageMask = pageSize - 1;
	}
	*allocatedSizePointer = bytes;
	while ((char *)minAddress + bytes > (char *)minAddress) {
		startAddress = roundUpToPage((long long)minAddress);

		alloc = mmap(startAddress, bytes,
					PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0);
		if (alloc == MAP_FAILED) {
			logWarnFromErrno("sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto mmap");
			return 0;
		}

		if(count >= 6){
			logTrace("More than 6 retries... maybe something is wrong\n");
		}

		logTrace("Asked: %10p %10p %10p\n", alloc, minAddress, startAddress);
		if (alloc >= minAddress){
			logTrace("Allocated Piece: %10p\n", alloc);
			return alloc;
		}

		count++;

		if (munmap(alloc, bytes) != 0)
			logWarnFromErrno("sqAllocateMemorySegment... munmap");
		minAddress = (void *)((char *)minAddress + bytes);
	}
	return 0;
}

