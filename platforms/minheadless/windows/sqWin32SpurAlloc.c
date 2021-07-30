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
#include "sqWin32.h"

#if SPURVM /* Non-spur uses sqWin32Alloc.c */

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

# define roundDownToPage(v) ((sqIntptr_t)(v)&pageMask)
# define roundUpToPage(v) (((sqIntptr_t)(v)+pageSize-1)&pageMask)

static char *
minAddressHint()
{
	char *hint;
	usqIntptr_t alignment;
	SYSTEM_INFO sysInfo;

	/* determine page boundaries & available address space */
	if (!pageSize) {
		GetSystemInfo(&sysInfo);
		pageSize = sysInfo.dwPageSize;
		pageMask = ~(pageSize - 1);
		minAppAddr = sysInfo.lpMinimumApplicationAddress;
		maxAppAddr = sysInfo.lpMaximumApplicationAddress;
	}

	/* choose a suitable starting point. In MinGW the malloc heap is below the
	 * program, so take the max of a malloc and something from uninitialized
	 * data.
	 */
	hint = malloc(1);
	free(hint);
	hint = max(hint,(char *)&fIsConsole);

	alignment = max(pageSize,1024*1024);
	return (char *)(((usqInt)hint + alignment - 1) & ~(alignment - 1));
}

/************************************************************************/
/* sqAllocateMemory: Initialize virtual memory                          */
/************************************************************************/
void *
sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize)
{
	char *alloc;
	sqInt allocBytes;

#if !COGVM
	if (pageSize) {
		sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Error:"),
					 TEXT("sqAllocateMemory already called"));
		exit(1);
	}
#endif

	alloc = sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto
				(desiredHeapSize, minAddressHint(), &allocBytes);
	if (!alloc) {
		sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Error:"),
					 TEXT("sqAllocateMemory: initial alloc failed!\n"));
		exit(1);
	}
	return alloc;
}

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
		if (printProbes && fIsConsole)
			printf("probing [%p,%p)\n", address, address + bytes);
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
			if (printMaps && fIsConsole)
				fprintf(stderr,
						"VirtualAlloc [%p,%p) above %p)\n",
						address, address+bytes, minAddress);
			*allocatedSizePointer = bytes;
			return alloc;
		}
		if (!alloc) {
			DWORD lastError = GetLastError();
#if 0 /* Can't report this without making the system unusable... */
			sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Error:"),
						TEXT("Unable to VirtualAlloc committed memory at desired address (%") TEXT(PRIuSQINT) TEXT(" bytes requested at %p, above %p), Error: %lu")),
						bytes, address, minAddress, lastError);
#else
			if (fIsConsole)
				fprintf(stderr,
						TEXT("Unable to VirtualAlloc committed memory at desired address (%" PRIuSQINT " bytes requested at %p, above %p), Error: %lu\n"),
						bytes, address, minAddress, lastError);
#endif
			return 0;
		}
		/* VirtualAlloc answered a mapping well away from where Spur prefers.
		 * Discard the mapping and try again delta higher.
		 */
		if (alloc && !VirtualFree(alloc, SizeForRelease(bytes), MEM_RELEASE))
			sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Warning:"),
						TEXT("Unable to VirtualFree committed memory (%") TEXT(PRIuSQINT) TEXT(" bytes requested), Error: %ul"),
						bytes, GetLastError());
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
	if (!VirtualFree(addr, SizeForRelease(sz), MEM_RELEASE))
		sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Warning:"),
					TEXT("Unable to VirtualFree committed memory (%") TEXT(PRIuSQINT) TEXT(" bytes requested), Error: %ul"),
					sz, GetLastError());
}

# if COGVM
void
sqMakeMemoryExecutableFromToCodeToDataDelta(usqInt startAddr,
											usqInt endAddr,
											sqInt *codeToDataDelta)
{
	DWORD previous;
    SIZE_T size;

    size = endAddr - startAddr;
	if (!VirtualProtect((void *)startAddr,
						size,
						PAGE_EXECUTE_READWRITE,
						&previous))
		sqWin32PrintLastError("VirtualProtect(x,y,PAGE_EXECUTE_READWRITE)");
    if (codeToDataDelta)
        *codeToDataDelta = 0;
}

void *
allocateJITMemory(usqInt *desiredSize)
{
	sqInt allocBytes;

	char *alloc = sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto
				(*desiredSize, minAddressHint(), &allocBytes);

	if (!alloc) {
		sqWin32PrintLastError("Could not allocate JIT memory");
		exit(1);
	}
	*desiredSize = allocBytes;
	return alloc;
}
# endif /* COGVM */

# if TEST_MEMORY

#	define MBytes	*1024UL*1024UL

BOOL fIsConsole = 1;

int
main()
{
	char *mem;
	usqInt i, t = 16 MBytes;

	mem= (char *)sqAllocateMemory(t, t);
	printf("memory allocated at %p\n", mem);
	*mem = 1;
	/* create some roadbumps */
	for (i = 80 MBytes; i < 2048UL MBytes; i += 80 MBytes) {
		void *alloc = VirtualAlloc(mem + i, pageSize, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE);
		printf("roadbump created at %p (%p)\n", mem + i, alloc);
		*(char *)alloc = 1;
	}
	for (;;) {
		sqInt segsz = 0;
		char *seg = sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(32 MBytes, mem + 16 MBytes, &segsz);
		if (!seg)
			return 0;
		*seg = 1;
		t += segsz;
		printf("memory extended at %p (total %ld Mb)\n", seg, t / (1 MBytes));
	}
	return 0;
}
int __cdecl
sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const char* fmt, ...)
{
	va_list args;
	int result;
	char buf[1024];

	strcpy(buf, titleString);
	strcat(buf, fmt);
	strcat(buf, "\n");
	va_start(args, fmt);
#if 0
	result = vfprintf(stderr, buf, args);
#else
	result = vprintf(buf, args);
#endif
	va_end(args);
	printLastError((char *)titleString);
	return result;
}
void printLastError(TCHAR *prefix)
{ LPVOID lpMsgBuf;
  DWORD lastError;

  lastError = GetLastError();
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |  FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                (LPTSTR) &lpMsgBuf, 0, NULL );
  fprintf(stderr,TEXT("%s (%d) -- %s\n"), prefix, lastError, lpMsgBuf);
  LocalFree( lpMsgBuf );
}
# endif /* TEST_MEMORY */
#endif /* SPURVM */
