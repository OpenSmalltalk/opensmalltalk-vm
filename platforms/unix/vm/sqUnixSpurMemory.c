/* sqUnixSpurMemory.c -- dynamic memory management for Spur on unix & Mac OS X.
 *
 * Author: eliot.miranda@gmail.com
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
#include "sq.h"

#include <stdio.h>
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif
#include <errno.h>
#ifdef HAVE_SYS_TYPES_H
#  include <sys/types.h>
#endif
#ifdef HAVE_MMAP
#  include <sys/mman.h>
#endif
#if DUAL_MAPPED_CODE_ZONE
# if !__APPLE__
#	include <sys/prctl.h>
# endif
#ifdef HAVE_SYS_STAT_H
#  include <sys/stat.h> /* For mode constants */
#endif
#ifdef HAVE_FCNTL_H
#  include <fcntl.h>   /* For O_* constants */
#endif
#endif

#include "sqMemoryAccess.h"
#include "sqAssert.h"
#include "debug.h"

#if SPURVM

/* Spur uses a segmented heap; it can add or remove segments, provided they
 * are above the first segment.  For this scheme to be able to allocate lots
 * of memory the first alloc to be at as low an address as possible.
 *
 * We would like subsequent mmaps to be at ascending addresses, without
 * impacting other users of mmap.  On the systems we have tested the address
 * parameter is only observed if either there is no existing overlapping
 * mapping in the [address, address + size) range or if MAP_FIXED is used.
 * If MAP_FIXED is not used and there is an existing mapping, mmap answers a
 * mapping at a high address.
 *
 * mmap obeys the address hint if it can.  So if mmap answers a mapping at other
 * than the hint we can infer there is an extant mapping in [hint, hint+bytes).
 * We can then free the mapping and continue the search with a hint further up.
 *
 * So we find the lowest suitable address for the initial mapping at startup
 * via sbrk, and then using the hint passed from the Spur memory manager for
 * subsequent mappings.  When there is an existing mapping we search for the
 * next available gap in e.g. 1 Mb increments.  This effectively allocates at
 * the the nearest address above that requested (something one might expect
 * mmap would do anyway).
 */

static long          pageSize = 0;
static unsigned long pageMask = 0;

# define roundDownToPage(v) ((v)&pageMask)
# define roundUpToPage(v) (((v)+pageSize-1)&pageMask)

int mmapErrno = 0;

# if !defined(HAVE_MMAP)
#	error "Spur requires mmap"
# endif
# if !defined(MAP_ANON) && !defined(MAP_ANONYMOUS)
#	error "Spur assumes MAP_ANON or MAP_ANONYMOUS"
#	error "You're going to have to add a file descriptor."
#	error "You can cpy the code in sqUnixMemory.c"
# endif

# if !defined(MAP_ANON)
#	define MAP_ANON MAP_ANONYMOUS
# endif
# if __OpenBSD__
#	define MAP_FLAGS	(MAP_ANON | MAP_PRIVATE | MAP_STACK)
# else
#	define MAP_FLAGS	(MAP_ANON | MAP_PRIVATE)
# endif

static int min(int x, int y) { return (x < y) ? x : y; }
static int max(int x, int y) { return (x > y) ? x : y; }

/* Answer the address of minHeapSize rounded up to page size bytes of memory. */

#if COGVM
static void *endOfJITZone;
#endif

usqInt
sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize)
{
	char *hint, *address, *alloc;
    unsigned long alignment;
    sqInt allocBytes;

#if !COGVM
	if (pageSize) {
		fprintf(stderr, "sqAllocateMemory: already called\n");
		exit(1);
	}
	pageSize = getpagesize();
	pageMask = ~(pageSize - 1);

	hint = sbrk(0);
#else
	assert(pageSize != 0 && pageMask != 0);
	hint = endOfJITZone;
#endif

	alignment = max(pageSize,1024*1024);
	address = (char *)(((usqInt)hint + alignment - 1) & ~(alignment - 1));

	alloc = sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto
				(roundUpToPage(desiredHeapSize), address, &allocBytes);
	if (!alloc) {
		fprintf(stderr, "sqAllocateMemory: initial alloc failed!\n");
		exit(errno);
	}
	return (usqInt)alloc;
}

/* Allocate a region of memory of at least size bytes, at or above minAddress.
 *  If the attempt fails, answer null.  If the attempt succeeds, answer the
 * start of the region and assign its size through allocatedSizePointer.
 */
void *
sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(usqInt size, void *minAddress, usqInt *allocatedSizePointer)
{
	char *address, *alloc;
	unsigned long bytes, delta;

	address = (char *)roundUpToPage((unsigned long)minAddress);
	bytes = roundUpToPage(size);
	delta = max(pageSize,1024*1024);

	while ((unsigned long)(address + bytes) > (unsigned long)address) {
		alloc = mmap(address, bytes, PROT_READ | PROT_WRITE /*| PROT_EXEC*/,
					 MAP_FLAGS, -1, 0);
		if (alloc == MAP_FAILED) {
			mmapErrno = errno;
			perror("sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto mmap");
			return 0;
		}
		if (alloc >= address && alloc <= address + delta) {
			*allocatedSizePointer = bytes;
			return alloc;
		}
		/* mmap answered a mapping well away from where Spur prefers.  Discard
		 * the mapping and try again delta higher.
		 */
		if (munmap(alloc, bytes) != 0)
			perror("sqAllocateMemorySegment... munmap");
		address += delta;
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

# if COGVM
#   if DUAL_MAPPED_CODE_ZONE
/* We are indebted to Chris Wellons who designed this elegant API for dual
 * mapping which we depend on for fine-grained code modification (classical
 * Deutsch/Schiffman style inline cacheing and derivatives).  Chris's code is:
	https://nullprogram.com/blog/2016/04/10/
 *
 * To cope with modern OSs that disallow executing code in writable memory we
 * dual-map the code zone, one mapping with read/write permissions and the other
 * with read/execute permissions. In such a configuration the code zone has
 * already been allocated and is not included in (what is no longer) the initial
 * alloc.
 */
static void
memory_alias_map(size_t size, size_t naddr, void **addrs)
{
extern char  *exeName;
	char path[128];
	snprintf(path, sizeof(path), "/%s(%lu,%p)",
			 exeName ? exeName : __FUNCTION__, (long)getpid(), addrs);
	int fd = shm_open(path, O_RDWR | O_CREAT | O_EXCL, 0600);
	if (fd == -1) {
		perror("memory_alias_map: shm_open");
		exit(0666);
	}
	shm_unlink(path);
	ftruncate(fd, size);
	for (size_t i = 0; i < naddr; i++) {
		addrs[i] = mmap(addrs[i], size, PROT_READ | PROT_WRITE,
								addrs[i] ? MAP_FIXED | MAP_SHARED : MAP_SHARED,
								fd, 0);
		if (addrs[i] == MAP_FAILED) {
			perror("memory_alias_map: mmap(addrs[i]...");
			exit(0667);
		}
	}
	close(fd);
	return;
}
#   endif /* DUAL_MAPPED_CODE_ZONE */
void
sqMakeMemoryExecutableFromToCodeToDataDelta(usqInt startAddr,
											usqInt endAddr,
											sqInt *codeToDataDelta)
{
	usqInt firstPage = roundDownToPage(startAddr);
	usqInt size = endAddr - firstPage;

#  if DUAL_MAPPED_CODE_ZONE
	usqInt mappings[2];

	mappings[0] = firstPage;
	mappings[1] = 0;

	memory_alias_map(size, 2, (void **)mappings);
	assert(mappings[0] == firstPage);
	*codeToDataDelta = mappings[1] - startAddr;

	if (mprotect((void *)firstPage,
				 size,
				 PROT_READ | PROT_EXEC) < 0)
		perror("mprotect(x,y,PROT_READ | PROT_EXEC)");

#  elif defined(MAP_JIT)

	assert(!codeToDataDelta);

#  else /* DUAL_MAPPED_CODE_ZONE */

	if (mprotect((void *)firstPage,
				 size,
				 PROT_READ | PROT_WRITE | PROT_EXEC) < 0)
		perror("mprotect(x,y,PROT_READ | PROT_WRITE | PROT_EXEC)");

	assert(!codeToDataDelta);
#  endif
}

// Allocate memory for the code zone, which must be executable, and is
// perferably writable.  Since the code zone lies below the heap, allocate at
// as low an address as possible, to allow maximal space for heap growth.
void *
allocateJITMemory(usqInt *desiredSize)
{
	void *hint = sbrk(0); // a hint of the lowest possible address for mmap
	void *result;

	pageSize = getpagesize();
	pageMask = ~(pageSize - 1);

#if !defined(MAP_JIT)
# define MAP_JIT 0
#endif

	*desiredSize = roundUpToPage(*desiredSize);
	result =   mmap(hint, *desiredSize,
#if DUAL_MAPPED_CODE_ZONE
					PROT_READ | PROT_EXEC,
#else
					PROT_READ | PROT_WRITE | PROT_EXEC,
#endif
					MAP_FLAGS | MAP_JIT, -1, 0);
	if (result == MAP_FAILED) {
		perror("Could not allocate JIT memory");
		exit(1);
	}
	// Note the address for sqAllocateMemory above
	endOfJITZone = (char *)result + *desiredSize;

	return result;
}
# endif /* COGVM */

# if TEST_MEMORY

#	define MBytes	*1024UL*1024UL

int
main()
{
	char *mem;
	usqInt i, t = 16 MBytes;

	printf("hint at %p\n", sbrk(0));

	mem= (char *)sqAllocateMemory(t, t);
	printf("memory allocated at %p\n", mem);
	/* create some roadbumps */
	for (i = 80 MBytes; i < 2048UL MBytes; i += 80 MBytes)
		printf("roadbump created at %p\n",
				mmap(mem + i, pageSize, PROT_READ | PROT_WRITE,
					 MAP_FLAGS, -1, 0));
	for (;;) {
		sqInt segsz = 0;
		char *seg = sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(32 MBytes, mem + 16 MBytes, &segsz);
		if (!seg)
			return 0;
		t += segsz;
		printf("memory extended at %p (total %ld Mb)\n", seg, t / (1 MBytes));
	}
	return 0;
}
# endif /* TEST_MEMORY */
#endif /* SPURVM */
