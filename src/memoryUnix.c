#include "pharovm/pharo.h"
#include <sys/mman.h>
#include <fcntl.h>
#include <signal.h>


#define roundDownToPage(v) ((v)&pageMask)
#define roundUpToPage(v) (((v)+pageSize-1)&pageMask)

char *uxGrowMemoryBy(char *oldLimit, sqInt delta);
char *uxShrinkMemoryBy(char *oldLimit, sqInt delta);
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

static sqInt min(int x, int y) { return (x < y) ? x : y; }
static sqInt max(int x, int y) { return (x > y) ? x : y; }

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
//		perror("mprotect(x,y,PROT_READ | PROT_WRITE)");
}

/* answer the address of (minHeapSize <= N <= desiredHeapSize) bytes of memory. */

usqInt
sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize)
{
	if (heap) {
		logError("uxAllocateMemory: already called\n");
		exit(1);
	}
	pageSize= getpagesize();
	pageMask= ~(pageSize - 1);

  heapLimit= valign(max(desiredHeapSize, 1));

  while ((!heap) && (heapLimit >= minHeapSize)) {
      if (MAP_FAILED == (heap= mmap(0, heapLimit, MAP_PROT, MAP_FLAGS, devZero, 0))) {
	  heap= 0;
	  heapLimit= valign(heapLimit / 4 * 3);
	}
  }

  if (!heap) {
      logError("uxAllocateMemory: failed to allocate at least %lld bytes)\n", (long long)minHeapSize);
      return (usqInt)malloc(desiredHeapSize);
  }

  heapSize= heapLimit;

  if (overallocateMemory)
    uxShrinkMemoryBy(heap + heapLimit, heapLimit - desiredHeapSize);

  return (usqInt)heap;
}

char *uxGrowMemoryBy(char *oldLimit, sqInt delta) {
	int newSize = min(valign(oldLimit - heap + delta), heapLimit);
	int newDelta = newSize - heapSize;
	assert(0 == (newDelta & ~pageMask));
	assert(0 == (newSize & ~pageMask));
	assert(newDelta >= 0);
	if (newDelta) {
		if (overallocateMemory) {
			char *base = heap + heapSize;
			if (MAP_FAILED
					== mmap(base, newDelta, MAP_PROT, MAP_FLAGS | MAP_FIXED,
							devZero, heapSize)) {
				perror("mmap");
				return oldLimit;
			}
		}
		heapSize += newDelta;
		assert(0 == (heapSize & ~pageMask));
	}
	return heap + heapSize;
}


/* shrink the heap by delta bytes.  answer the new end of memory. */

char *uxShrinkMemoryBy(char *oldLimit, sqInt delta) {
	int newSize = max(0, valign((char * )oldLimit - heap - delta));
	int newDelta = heapSize - newSize;

	assert(0 == (newDelta & ~pageMask));
	assert(0 == (newSize & ~pageMask));
	assert(newDelta >= 0);
	if (newDelta) {
		if (overallocateMemory) {
			char *base = heap + heapSize - newDelta;
			if (munmap(base, newDelta) < 0) {
				perror("unmap");
				return oldLimit;
			}
		}
		heapSize -= newDelta;
		assert(0 == (heapSize & ~pageMask));
	}
	return heap + heapSize;
}


/* answer the number of bytes available for growing the heap. */

sqInt uxMemoryExtraBytesLeft(sqInt includingSwap)
{
  return heapLimit - heapSize;
}


sqInt sqGrowMemoryBy(sqInt oldLimit, sqInt delta)			{ return (sqInt)(long)uxGrowMemoryBy((char *)(long)oldLimit, delta); }
sqInt sqShrinkMemoryBy(sqInt oldLimit, sqInt delta)			{ return (sqInt)(long)uxShrinkMemoryBy((char *)(long)oldLimit, delta); }
sqInt sqMemoryExtraBytesLeft(sqInt includingSwap)			{ return uxMemoryExtraBytesLeft(includingSwap); }


/* Deallocate a region of memory previously allocated by
 * sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto.  Cannot fail.
 */
void
sqDeallocateMemorySegmentAtOfSize(void *addr, sqInt sz)
{
	if (munmap(addr, sz) != 0)
		perror("sqDeallocateMemorySegment... munmap");
}

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

