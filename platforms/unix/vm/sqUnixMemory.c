/* sqUnixMemory -- low-level routines to obtain space for Squeak's
   object memory */



#include <sq.h>


#ifdef  USE_MEMORY_MMAP

/* This mmap-based allocator will initially mmap a huge region on
   /dev/zero.  To free memory, it will re-mmap over the original map.
   It's a complicated hack, but sometimes it actually works.  This
   allocator can handle extending and shrinking squeak's effective
   heap size at run-time.
*/

#include <stdio.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <assert.h>
#include <errno.h>

#undef DEBUG

/* Amount of the memory map to try reserve for Squeak.  The startup
   code will try and reserve this much of the address space for
   Squeak's heap.  Larger spaces mean that the maximum size of the
   heap is larger, but that less address space is available for other
   purposes such as malloc().  Also, on some OS's, allocating the
   address space may in fact allocate real swap space or memory, and
   so on such OS's the maximum should be reduced.  */

#ifndef MEMORY_TO_TRY
# define MEMORY_TO_TRY (1024*1024*1024)   /* 1 gig */
#endif


static int devZeroFd = -1;    /* fd for /dev/zero */
static char *heap = NULL;  /* location of the heap */
static int heapSize = 0;  /* amount of space currently mmap-ed */
static int maxHeapSize;   /* amount of address space available for the
			     heap */



/* return the granularity at which to run mmap() */
static int mmapGranularity() 
{
  return getpagesize();
}


/* return the first byte past the end of the heap */
static void *heapLimit() 
{
  return heap + heapSize;
}


/* internal routine: adjust the size of the heap to at least the
   requested size.  This both shrinks and grows.  When shrinking, the
   memory will attempt to be freed by re-running mmap() over the
   now-unused region
*/
static void adjustHeapSize(int newHeapSize) 
{
  /* enforce a little sanity */
  if(newHeapSize > maxHeapSize)
    newHeapSize = maxHeapSize;
  if(newHeapSize < 0)
    newHeapSize = 0;

  
  /* first, round up newHeapSize so that the heap will end an
     mmapGranularity() boundary */
  {
    char *realEnd;
    int newHeapSizeToUse;
  
    realEnd = (char *)
      (((int)heap + newHeapSize + (mmapGranularity() - 1)) /
       mmapGranularity() * mmapGranularity());

    newHeapSizeToUse = realEnd - heap;
    
    assert(newHeapSizeToUse >= newHeapSize);
    newHeapSize = newHeapSizeToUse;

    assert(newHeapSize >= 0);
    assert(newHeapSize <= maxHeapSize);
    assert(((int)heap + newHeapSize) % mmapGranularity() == 0);
  }

  
  if(newHeapSize == heapSize) {
    /* no change in size */
    return;
  }
  
  if(newHeapSize < heapSize) {
    /* heap is shrinking */
    void *result;
    
    /* first, munmap pages past the end of the new heap */
#if 0  /* LEX don't bother: on Linux, at least, you can mmap() on top of the region, anyway.  Plus, it REALLY sucks if we munmap, some other process grabs memory, and then suddenly our mmap() fails.... */
    munmap(heap + newHeapSize, maxHeapSize - newHeapSize);
#endif
    heapSize = newHeapSize;

    
    /* now remap them, so that the heap area remains contiguous. */
    /* (This won't actually waste memory on most Unices.) */
    result = mmap(heap+newHeapSize, maxHeapSize - newHeapSize,
		  PROT_READ|PROT_WRITE, MAP_FIXED|MAP_PRIVATE,
		  devZeroFd, newHeapSize);
    if(result == MAP_FAILED) {
      perror("mmap");
    }
  }
  else {
    /* heap is growing.  The memory is already allocated, so just
       updated the bookkeeping */
    heapSize = newHeapSize ;
  }
}



/* initial allocation routine */
void * sqAllocateMemory(int minHeapSize, int desiredHeapSize)  {
  /* sanity checks */
  if(heap != NULL) {
    fprintf(stderr, "sqAllocateMemory called twice!\n");
    exit(1);
  }
  if(desiredHeapSize > MEMORY_TO_TRY) {
    fprintf(stderr, "requested %d memory for heap!  Giving up.\n", desiredHeapSize);
    return NULL;
  }

  /* open /dev/zero */
  devZeroFd = open("/dev/zero", O_RDWR);
  if(devZeroFd < 0) {
    perror("open(\"/dev/zero\")");
    return NULL;
  }

  /* mmap() a large chunk.  If it fails, try smaller sizes */
  maxHeapSize = MEMORY_TO_TRY / mmapGranularity() * mmapGranularity();

  while(heap==NULL && maxHeapSize > (10*mmapGranularity())) {
#ifdef DEBUG
    printf("trying size %d.\n", maxHeapSize);
#endif
    heap = mmap(NULL, maxHeapSize,
		PROT_READ|PROT_WRITE, MAP_PRIVATE,
		devZeroFd, 0);

    if(heap == MAP_FAILED) {
      heap = NULL;
      
      /* try again with a smaller heap */
      maxHeapSize = maxHeapSize / 4 * 3;

      /* make sure we are still a multipple of mmapGranularity() */
      maxHeapSize = maxHeapSize / mmapGranularity() * mmapGranularity();
    }
  }

  if(heap == NULL) {
    /* failure */
    return NULL;
  }

  /* success */
  heapSize = maxHeapSize;

  /* double check that we got enough */
  if(maxHeapSize < minHeapSize) {
    printf("could not allocate but %d for the heap, but %d was requested\n", maxHeapSize, minHeapSize);
    return NULL;
  }
  

  
  /* adjust the size of the mapping */
  adjustHeapSize(desiredHeapSize);
  if(heapSize == 0) {
    return NULL;
  }


  /* all done */
  return heap;
}


/* external interface: increase the size of memory */
int sqGrowMemoryBy(int oldLimit, int delta) {
#ifdef DEBUG
  printf("growing by %d...\n", delta);
#endif
  

  adjustHeapSize((char *)oldLimit - heap + delta);

#ifdef DEBUG
  printf("new heap size is %d\n", heapSize);
#endif
  
  return (int) heapLimit();
}


/* external interface: decrease the size of memory */
int sqShrinkMemoryBy(int oldLimit, int delta) {
#ifdef DEBUG
  printf("shrinking by %d...\n", delta);
#endif
  
  adjustHeapSize((char *)oldLimit - heap - delta);
  
#ifdef DEBUG
  printf("new heap size is %d\n", heapSize);
#endif
  return (int) heapLimit();
}


/* ask how much space can possibly be allocated */
int sqMemoryExtraBytesLeft(int includingSwap) {
  return maxHeapSize - heapSize;
}


#else  

/* The default memory allocator just uses malloc(), and makes no
    attempts to resize the heap */


void * sqAllocateMemory(int minHeapSize, int desiredHeapSize) {
  return malloc(desiredHeapSize);
}

int sqGrowMemoryBy(int oldLimit, int delta) {
  return oldLimit;
}

int sqShrinkMemoryBy(int oldLimit, int delta) {
  return oldLimit;
}

int sqMemoryExtraBytesLeft(int includingSwap) {
  return 0;
}


#endif
