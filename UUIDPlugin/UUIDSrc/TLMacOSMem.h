/*------------------------------------------------------------
| NAME: TLMacOSMem.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for memory allocation
|          procedures.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 08.28.93 from ascii.txt.
|          02.24.94 added relocatable memory routines.
|          11.23.96 copied from 'MemAlloc.h' of AK2.
------------------------------------------------------------*/

#ifndef _MACOSMEMALLOC_H_
#define _MACOSMEMALLOC_H_

/*------------------------------------------------------------
| NAME: LockedHandleRecord
|
| PURPOSE: To hold the status of a locked handle.
|
| DESCRIPTION: Each record looks like this:
|
|              LockedHandleRecord
|          ------------------------- 
|          | Handle |   LockLevel  | 
|          ------------------------- 
|            4 bytes     4 bytes    
|
| where: Handle is the address of a locked handle.
|
|        LockingLevel is a count of how many times the
|                     handle has been locked: 1 if locked
|                     once, 2 if locked twice...
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.23.94 
|
------------------------------------------------------------*/
typedef struct LockedHandleRecord
{
    Handle      AHandle;
    u32         LockLevel;
} LockedHandle;

#define MaxLockedHandles    100
        // The upper limit of how many locked handles there
        // can be at any one time.
        
#define MinMassMemorySegmentSize    4096
        // The minimum unit size of mass memory segments:
        // segments may be larger.
         
extern  u32* TheMassMemorySegmentChain;     
        // Holds the address of first memory segment
        // of the mass memory segment list.
        // This is a singly-linked list.

extern  u8* TheMassMemoryFreeAddress;
        // The first free byte in the current mass memory
        // segment.
         
extern s32      TheMassMemoryFreeCount;
        // The number of available bytes in the current
        // mass memory segment.

void        AdvanceLockedHandle(s32);
void*       AllocateMassMemory(s32);
void*       AllocateMemory(s32);
void**      AllocateRelocatableMemory(s32);              
void        ClearRelocatableMemory( void** );
u32         CountOfBytesAvailableFromOperatingSystem();
s32         FindEmptyLockedHandle();
s32         FindLockedHandle(void**);
void        FreeMassMemory();
void        FreeMemory(void*);
void        FreeRelocatableMemory(void**);
u16         GetHandleState(void**);
void        Lock(void**);
void        SetHandleSizeWithCompaction( void**, Size );
void        SetHandleState( void**, u16 );
void        SetUpLockedHandleArray();
u32         SizeOfLargestBlockAvailableFromOS();
void        Unlock( void** );
void        UnlockAllLocks();

#endif // _MACOSMEMALLOC_H_
