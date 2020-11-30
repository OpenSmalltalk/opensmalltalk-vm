/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32SpurAlloc.c
*   CONTENT: Virtual Memory Management For Spur
*
*   AUTHOR:  Eliot Miranda
*   EMAIL:   eliot.miranda@gmail.com
*
*****************************************************************************/

#include <windows.h>
#include <errno.h>
#include "sq.h"
#include "pharovm/debug.h"

/* Why does this have to be *here*?? eem 6/24/2014 */
#if !defined(NDEBUG)
/* in debug mode, let the system crash so that we can see where it happened */
#define EXCEPTION_WRONG_ACCESS EXCEPTION_CONTINUE_SEARCH
#else
/* in release mode, execute the exception handler notifying the user what happened */
#define EXCEPTION_WRONG_ACCESS EXCEPTION_EXECUTE_HANDLER
#endif

LONG CALLBACK sqExceptionFilter(LPEXCEPTION_POINTERS exp)
{
  /* always wrong access - we handle memory differently now */
  return EXCEPTION_WRONG_ACCESS;
}

static sqIntptr_t  pageMask;     /* bit mask for the start of a memory page */
static sqIntptr_t  pageSize;     /* size of a memory page */
static char  *minAppAddr;	/* SYSTEM_INFO lpMinimumApplicationAddress */
static char  *maxAppAddr;	/* SYSTEM_INFO lpMaximumApplicationAddress */

# define roundDownToPage(v) ((v)&pageMask)
# define roundUpToPage(v) (((v)+pageSize-1)&pageMask)

/************************************************************************/
/* sqAllocateMemory: Initialize virtual memory                          */
/************************************************************************/
usqInt
sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize, usqInt desiredBaseAddress)
{
	char *hint, *address, *alloc;
	usqIntptr_t alignment;
	sqInt allocBytes;
	SYSTEM_INFO sysInfo;

	if (pageSize) {
		logError("sqAllocateMemory have already been called");
		exit(1);
	}

	/* determine page boundaries & available address space */
	GetSystemInfo(&sysInfo);
	pageSize = sysInfo.dwPageSize;
	pageMask = ~(pageSize - 1);
	minAppAddr = sysInfo.lpMinimumApplicationAddress;
	maxAppAddr = sysInfo.lpMaximumApplicationAddress;

#if __MINGW32__
	/* choose a suitable starting point. In MinGW the malloc heap is below the
	 * program, so take the max of a malloc and something from uninitialized
	 * data.
	 */
	hint = malloc(1);
	free(hint);
	hint = max(hint, (char*)&fIsConsole);
#else
	hint = desiredBaseAddress;
#endif

	alignment = max(pageSize,1024*1024);
	address = (char *)(((usqInt)hint + alignment - 1) & ~(alignment - 1));

	alloc = sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto
				(roundUpToPage(desiredHeapSize), address, &allocBytes);
	if (!alloc) {
		exit(errno);
		sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Error:"),
					 TEXT("sqAllocateMemory: initial alloc failed!\n"));
		exit(1);
	}
	return alloc;
}

#define roundDownToPage(v) ((v)&pageMask)
#define roundUpToPage(v) (((v)+pageSize-1)&pageMask)

/* Allocate a region of memory of at least size bytes, at or above minAddress.
 *  If the attempt fails, answer null.  If the attempt succeeds, answer the
 * start of the region and assign its size through allocatedSizePointer.
 *
 * This from the VirtualFree doc is rather scary:
	dwSize [in]

		The size of the region of memory to be freed, in bytes.

		If the dwFreeType parameter is MEM_RELEASE, this parameter must be 0
		(zero). The function frees the entire region that is reserved in the
		initial allocation call to VirtualAlloc.
 *
 * So we rely on the SpurMemoryManager to free exactly the segments that were
 * allocated.
 */
#define SizeForRelease(bytes) 0

static int
address_space_used(char *address, usqInt bytes)
{
	MEMORY_BASIC_INFORMATION info;
	int addressSpaceUnused;

	if (address < minAppAddr || address > maxAppAddr)
		return 1;
	if (!VirtualQuery(address, &info, sizeof(info)))
		sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Error:"),
					TEXT("Unable to VirtualQuery range [%p, %p), Error: %u"),
					address, (char *)address + bytes, GetLastError());

	addressSpaceUnused = info.BaseAddress == address
						&& info.RegionSize >= bytes
						&& info.State == MEM_FREE;

	return !addressSpaceUnused;
}

void *
sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(sqInt size, void *minAddress, sqInt *allocatedSizePointer)
{
	char *address, *alloc;
	usqInt bytes, delta;

	address = (char *)roundUpToPage((usqIntptr_t)minAddress);
	bytes = roundUpToPage(size);
	delta = max(pageSize,1024*1024);

# define printProbes 0
# define printMaps 0
	while ((usqIntptr_t)(address + bytes) > (usqIntptr_t)address) {
		if (printProbes)
			logTrace("probing [%p,%p)\n", address, address + bytes);
		if (address_space_used(address, bytes)) {
			address += delta;
			continue;
		}
		alloc = VirtualAlloc(address, bytes, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE);
		/* For some reason (large page support?) we can ask for a page-aligned
		 * address such as 0xNNNNf000 but VirtualAlloc will answer 0xNNNN0000.
		 * So accept allocs above minAddress rather than allocs above address
		 */
		if (alloc >= (char *)minAddress && alloc <= address + delta) {
			if (printMaps)
				logWarn("VirtualAlloc [%p,%p) above %p)\n",
						address, address+bytes, minAddress);
			*allocatedSizePointer = bytes;
			return alloc;
		}
		if (!alloc) {
			DWORD lastError = GetLastError();
			logWarn("Unable to VirtualAlloc committed memory at desired address (%lld bytes requested at %p, above %p), Error: %lu\n",
						bytes, address, minAddress, lastError);
			return 0;
		}
		/* VirtualAlloc answered a mapping well away from where Spur prefers.
		 * Discard the mapping and try again delta higher.
		 */
		if (alloc && !VirtualFree(alloc, SizeForRelease(bytes), MEM_RELEASE)){
			logWarn("Unable to VirtualFree committed memory at desired address (%lld bytes requested at %p, above %p), Error: %lu\n",
						bytes, address, minAddress, GetLastError());
		}

		address += delta;
	}
	logWarn("Unable to VirtualAlloc committed memory at desired address");
	return 0;
}

/* Deallocate a region of memory previously allocated by
 * sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto.  Cannot fail.
 */
void
sqDeallocateMemorySegmentAtOfSize(void *addr, sqInt sz)
{
	if (!VirtualFree(addr, SizeForRelease(sz), MEM_RELEASE))
		sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Warning:"),
					TEXT("Unable to VirtualFree committed memory (%") TEXT(PRIuSQINT) TEXT(" bytes requested), Error: %ul"),
					sz, GetLastError());
}

# if COGVM
void
sqMakeMemoryExecutableFromTo(usqIntptr_t startAddr, usqIntptr_t endAddr)
{
	DWORD previous;
    SIZE_T size;

    size = endAddr - startAddr;
	if (!VirtualProtect((void *)startAddr,
						size,
						PAGE_EXECUTE_READWRITE,
						&previous))
		logErrorFromErrno("VirtualProtect(x,y,PAGE_EXECUTE_READWRITE)");
}

void
sqMakeMemoryNotExecutableFromTo(usqIntptr_t startAddr, usqIntptr_t endAddr)
{
	DWORD previous;
    SIZE_T size;

    size = endAddr - startAddr;
	if (!VirtualProtect((void *)startAddr,
						size,
						PAGE_READWRITE,
						&previous))
		logErrorFromErrno("VirtualProtect(x,y,PAGE_EXECUTE_READWRITE)");
}
# endif /* COGVM */

