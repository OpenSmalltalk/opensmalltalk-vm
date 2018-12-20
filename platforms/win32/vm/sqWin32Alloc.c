/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Alloc.c
*   CONTENT: Virtual Memory Management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*****************************************************************************/
#include <windows.h>
#include "sq.h"

#if !defined(NO_VIRTUAL_MEMORY) && !SPURVM /* Spur uses sqWin32SpurAlloc.c */

/* For Qwaq Forums: Disallow memory shrinking to avoid crashes
   due to GC/OpenGL relocation problems within glDrawElements.
   It appears that in rare circumstances we trigger a full GC
   which moves the data away from under OGLs feet and if the
   memory gets released at this point OGL may crash.
*/
#define DO_NOT_SHRINK


static LPSTR  pageBase;     /* base address of allocated memory */
static DWORD  pageMask;     /* bit mask for the start of a memory page */
static DWORD  pageSize;     /* size of a memory page */
static DWORD  nowReserved;  /* 'publicly' reserved virtual memory */
static LPSTR  pageLimit;    /* upper limit of commited pages */
static DWORD  maxReserved;  /* maximum reserved virtual memory */
static DWORD  usedMemory;   /* amount of memory currently in use */

#ifndef NDEBUG
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

/************************************************************************/
/* sqAllocateMemory: Initialize virtual memory                          */
/************************************************************************/
void *sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize)
{ SYSTEM_INFO sysInfo;
  DWORD initialCommit, commit;

  /* determine page boundaries */
  GetSystemInfo(&sysInfo);
  pageSize = sysInfo.dwPageSize;
  pageMask = ~(pageSize - 1);

  /* round the requested size up to the next page boundary */
  nowReserved = (desiredHeapSize + pageSize) & pageMask;

  /* round the initial commited size up to the next page boundary */
  initialCommit = (minHeapSize + pageSize) & pageMask;

  /* Here, we only reserve the maximum memory to be used
     It will later be committed during actual access */
  maxReserved = MAX_VIRTUAL_MEMORY;
  do {
    pageBase = VirtualAlloc(NULL,maxReserved,MEM_RESERVE, PAGE_NOACCESS);
    if(!pageBase) {
      if(maxReserved == nowReserved) break;
      /* make it smaller in steps of 128MB */
      maxReserved -= 128*1024*1024;
      if(maxReserved < nowReserved) maxReserved = nowReserved;
    }
  } while(!pageBase);
  if(!pageBase) {
    sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Error:"),
		 "Unable to allocate memory (%d bytes requested)",
		 maxReserved);
    return pageBase;
  }
  /* commit initial memory as requested */
  commit = nowReserved;
  if(!VirtualAlloc(pageBase, commit, MEM_COMMIT, PAGE_READWRITE)) {
    sqMessageBox(MB_OK | MB_ICONSTOP, TEXT("VM Error:"),
		 "Unable to commit memory (%d bytes requested)",
		 commit);
    return NULL;
  }
  pageLimit = pageBase + commit;
  usedMemory += commit;
  return pageBase;
}

/************************************************************************/
/* sqGrowMemoryBy: Grow object memory if possible                       */
/************************************************************************/
int sqGrowMemoryBy(int oldLimit, int delta) {
  /* round delta UP to page size */
  if(fShowAllocations) {
    warnPrintf("Growing memory by %d...", delta);
  }
  delta = (delta + pageSize) & pageMask;
  if(!VirtualAlloc(pageLimit, delta, MEM_COMMIT, PAGE_READWRITE)) {
    if(fShowAllocations) {
      warnPrintf("failed\n");
    }
    /* failed to grow */
    return oldLimit;
  }
  /* otherwise, expand pageLimit and return new top limit */
  if(fShowAllocations) {
    warnPrintf("okay\n");
  }
  pageLimit += delta;
  usedMemory += delta;
  return (int)pageLimit;
}

/************************************************************************/
/* sqShrinkMemoryBy: Shrink object memory if possible                   */
/************************************************************************/
int sqShrinkMemoryBy(int oldLimit, int delta) {
  /* round delta DOWN to page size */
  if(fShowAllocations) {
    warnPrintf("Shrinking by %d...",delta);
  }
#ifdef DO_NOT_SHRINK
  {
    /* Experimental - do not unmap memory and avoid OGL crashes */
    if(fShowAllocations) warnPrintf(" - ignored\n");
    return oldLimit;
  }
#endif
  delta &= pageMask;
  if(!VirtualFree(pageLimit-delta, delta, MEM_DECOMMIT)) {
    if(fShowAllocations) {
      warnPrintf("failed\n");
    }
    /* failed to shrink */
    return oldLimit;
  }
  /* otherwise, shrink pageLimit and return new top limit */
  if(fShowAllocations) {
    warnPrintf("okay\n");
  }
  pageLimit -= delta;
  usedMemory -= delta;
  return (int)pageLimit;
}

/************************************************************************/
/* sqMemoryExtraBytesLeft: Return memory available to Squeak            */
/************************************************************************/
int sqMemoryExtraBytesLeft(int includingSwap) {
  DWORD bytesLeft;
  MEMORYSTATUS mStat;

  ZeroMemory(&mStat,sizeof(mStat));
  mStat.dwLength = sizeof(mStat);
  GlobalMemoryStatus(&mStat);
  bytesLeft = mStat.dwAvailPhys;
  if(includingSwap) {
    bytesLeft += mStat.dwAvailPageFile;
  };
  /* max bytes is also limited by maxReserved page size */
  if(bytesLeft > (maxReserved - usedMemory)) {
    bytesLeft = maxReserved - usedMemory;
  }
  return bytesLeft;
}

#define roundDownToPage(v) ((v)&pageMask)
#define roundUpToPage(v) (((v)+pageSize-1)&pageMask)

# if COGVM
void
sqMakeMemoryExecutableFromTo(usqIntptr_t startAddr, usqIntptr_t endAddr)
{
	DWORD previous;

	if (!VirtualProtect((void *)startAddr,
						endAddr - startAddr + 1,
						PAGE_EXECUTE_READWRITE,
						&previous))
		perror("VirtualProtect(x,y,PAGE_EXECUTE_READWRITE)");
}

void
sqMakeMemoryNotExecutableFromTo(usqIntptr_t startAddr, usqIntptr_t endAddr)
{
	DWORD previous;

	if (!VirtualProtect((void *)startAddr,
						endAddr - startAddr + 1,
						PAGE_READWRITE,
						&previous))
		perror("VirtualProtect(x,y,PAGE_EXECUTE_READWRITE)");
}
# endif /* COGVM */
#endif /* !defined(NO_VIRTUAL_MEMORY) && !SPURVM */
