/*------------------------------------------------------------
| TLMacOSMem.c
|-------------------------------------------------------------
|
| PURPOSE: To provide memory allocation using the MacOS 
|          procedures.
|
| DESCRIPTION: Adds support for fixed and relocatable memory
| blocks using the MacOS.
|
| Additional record keeping to support control of handles.
|
| Used in conjunction with routines in 'TLMem.c'.
|
| HISTORY: 01.21.94 from OSMemoryAllocation.a & 
|                        MemoryAllocation.a
|          02.24.94 added relocatable memory routines.
|          11.23.96 copied from 'MemAlloc.c' of AK2.
------------------------------------------------------------*/

#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdio.h>      // For memory stat dumping to file.
#include <stdlib.h>
#include <Errors.h>     // For memory error codes.
#include <Memory.h>     // For Mac OS memory functions.
#include <string.h>
#include <Events.h>     // For TickCount.
#include <SegLoad.h>    // For 'ExitToShell'.
#include "TLTypes.h"   // Includes "TLMem.h"
#include "TLBytes.h"
//#include "TLMem.h"

#include "TLMacOSMem.h"

LockedHandle LockedHandleArray[MaxLockedHandles];
        // Holds the records of all currently locked 
        // handles.

u16     CountOfLockedHandles;
        // Count of currently locked handles. 

u32*    TheMassMemorySegmentChain=0;     
        // Holds the address of first memory segment
        // of the mass memory segment list.
        // This is a singly-linked list.

u8*     TheMassMemoryFreeAddress;
        // The first free byte in the current mass memory
        // segment.
         
s32     TheMassMemoryFreeCount=0;
        // The number of available bytes in the current
        // mass memory segment.

/*------------------------------------------------------------
| AdvanceLockedHandle
|-------------------------------------------------------------
|
| PURPOSE: To move a locked handle record towards the 
|          beginning of the array.
|
| DESCRIPTION: This is so that future searches for the given
|              handle will be found more quickly.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.24.94
------------------------------------------------------------*/
void
AdvanceLockedHandle( s32 AHandleIndex )
{
    LockedHandle    ALockedHandle;
    s32         CounterpartIndex;
    
    /* Return if at the beginning of the array. */
    if( AHandleIndex == 0 ) 
    {
        return;
    }
    
    /* Exchange with record at index/2 */
    ALockedHandle = LockedHandleArray[AHandleIndex];
    
    CounterpartIndex = AHandleIndex>>1;
    
    LockedHandleArray[AHandleIndex] = 
        LockedHandleArray[CounterpartIndex];
        
    LockedHandleArray[CounterpartIndex] = ALockedHandle;
}

/*------------------------------------------------------------
| AllocateMassMemory
|-------------------------------------------------------------
|
| PURPOSE: To request a non-relocatable memory segment from 
|          the mass memory pool.
|
| DESCRIPTION: Similar to 'AllocateMemory' except that
| mass memory is deallocated as a mass, all at the same
| time.  Much faster than 'AllocateMemory'.
|
| Given the length required in bytes, this
| procedure returns the address of the newly allocated
| segment. If allocation fails the error is handled
| according to the current error interpreter.
|
| EXAMPLE: AtSeg = AllocateMassMemory( 14 );
|
| NOTE: OBSOLETE: See 'AllocateMS()' for replacement.
|
| ASSUMES: Mass memory will be deallocated all at once by
|          a call to 'FreeMassMemory()'.
|
| HISTORY: 06.10.94 from 'MakeList'.
|          11.23.96 changed to use 'malloc' instead of
|                   'AllocateMemory'.
------------------------------------------------------------*/
void*
AllocateMassMemory( s32 ByteCount )
{
    u8*     AChunk;
    s32     SizeOfSegment;
    u32*    ASegment;
    
    /* Make ByteCount an even number of bytes. */
    ByteCount = ((ByteCount+1) >> 1) << 1;
    
    /* If free mass memory available, use it. */
    if( TheMassMemoryFreeCount >= ByteCount )
    {
AllocChunkOfMass:
        TheMassMemoryFreeCount -= ByteCount;
        AChunk = TheMassMemoryFreeAddress;
        TheMassMemoryFreeAddress += ByteCount;

        return(AChunk);
    }
    else // If no free mass memory available, make some.
    {
        SizeOfSegment = MinMassMemorySegmentSize;
        
        if( SizeOfSegment < ByteCount )
        {
            SizeOfSegment = ByteCount;
        }
        
        SizeOfSegment += sizeof(void*); 
            // Include link for list.
            
        ASegment = (u32*) malloc( SizeOfSegment );
        
        // Attach the new segment to the segment chain so that
        // it can be deallocated in mass.
        
        ASegment[0]  = (u32) TheMassMemorySegmentChain;
        TheMassMemorySegmentChain = ASegment;
        
        TheMassMemoryFreeAddress = (u8*) &ASegment[1];
        
        TheMassMemoryFreeCount = SizeOfSegment;
        
        goto AllocChunkOfMass;
    }
}

/*------------------------------------------------------------
| AllocateMemory
|-------------------------------------------------------------
|
| PURPOSE: To request a non-relocatable memory segment from 
|          the OS memory pool.
|
| DESCRIPTION: Given the length required in bytes, this
| procedure returns the address of the newly allocated
| segment or 0 if allocation failed.
|
| Allows allocation during a low memory condition.
|
| EXAMPLE: 
|
| NOTE: May be slow due to compaction.
|       See also similar 'AllocateMemoryOS'.
|
| ASSUMES: Maybe revise this later to take advantage of 
|          Multifinder temporary memory allocation.
|
| HISTORY: 12.26.90 
|          01.21.93 converted to 'C'
|          02.24.94 added MemoryErrorInterpreter.
|          07.04.95 added AtMemError for CW.
|          11
------------------------------------------------------------*/
void*
AllocateMemory( s32 ByteCount )
{
    void*   Result;
    s32         BytesAvailWithoutCompaction;
    s32         BytesAvailAfterCompaction;

    BytesAvailWithoutCompaction = 
        SizeOfLargestBlockAvailableFromOS();
    
    if( BytesAvailWithoutCompaction < ByteCount )
    {
        // Find out how much would be available after
        // compaction.
        BytesAvailAfterCompaction =
            SizeOfLargestBlockAvailableFromOS();
            
        if( BytesAvailAfterCompaction < 
//            ( ByteCount + MemoryCushion) )
            ( ByteCount ) )
        {
//            IsOutOfMemory = 1;
        }
        else
        {
            Result = (void*) NewPtr( ByteCount );
        }
    }
    else
    {
        Result = (void*) NewPtr( ByteCount );
    }

//    InterpretMemoryError();
    
    return( Result );
}

/*------------------------------------------------------------
| AllocateRelocatableMemory
|-------------------------------------------------------------
|
| PURPOSE: To request a relocatable memory segment from 
|          the OS memory pool.
|
| DESCRIPTION: Given the length required in bytes, this
| procedure returns the handle of the newly allocated
| segment or 0 if allocation failed.
|
| Allows allocation during a low memory condition.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Maybe revise this later to take advantage of 
|          Multifinder temporary memory allocation.
|
| HISTORY: 02.24.94
|          11.23.96 revised. 
|          10.16.97 pulled out 'MemoryCushion'.
------------------------------------------------------------*/
void**
AllocateRelocatableMemory( s32 ByteCount )
{
    void**  Result;
    s32 BytesAvailWithoutCompaction;
    s32 BytesAvailAfterCompaction;

    BytesAvailWithoutCompaction = 
        SizeOfLargestBlockAvailableFromOS();
    
    if( BytesAvailWithoutCompaction < ByteCount )
    {
        // Find out how much would be available after
        // compaction.
        BytesAvailAfterCompaction =
            SizeOfLargestBlockAvailableFromOS();
            
        if( BytesAvailAfterCompaction < ByteCount )
        {
 //           IsOutOfMemory = 1;
        }
        else
        {
            Result = NewHandle( (s32) ByteCount );
        }
    }
    else
    {
        Result = NewHandle( (s32) ByteCount );
    }

 //   InterpretMemoryError();
    
    return( Result );
}

/*------------------------------------------------------------
| ClearRelocatableMemory
|-------------------------------------------------------------
|
| PURPOSE: To fill a relocatable memory segment with 0's.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 11.23.96 
------------------------------------------------------------*/
void
ClearRelocatableMemory( void** h )
{
    Size    ByteCount;
    
    Lock( h );
    
    ByteCount = GetHandleSize( (char**) h );
    
    FillBytes( (u8*) *h, (u32) ByteCount, 0 );
    
    Unlock( h );
}

/*------------------------------------------------------------
| CountOfBytesAvailableFromOperatingSystem
|-------------------------------------------------------------
|
| PURPOSE: To return the total number of bytes in the OS 
|          memory pool which are available for allocation.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Maybe revise this later to take advantage of 
|          Multifinder temporary memory allocation.
|
| HISTORY: 12.13.90
|          01.21.93 converted to 'C'
------------------------------------------------------------*/
u32
CountOfBytesAvailableFromOperatingSystem()
{
    u32 Au32;
    
    Au32 = (u32) FreeMem();
    
    return( Au32 );
}

/*------------------------------------------------------------
| FindEmptyLockedHandle
|-------------------------------------------------------------
|
| PURPOSE: To find the index of the first empty 
|          LockedHandle record in the 'LockedHandleArray'.
|
| DESCRIPTION: Returns -1 if not found in array.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Will have enough locked handle records. 
|
| HISTORY: 02.24.94 
------------------------------------------------------------*/
s32
FindEmptyLockedHandle()
{
    s32 i;
    
    i = 0;
    
    while( LockedHandleArray[i].LockLevel != 0 )
    {
        i++;
    }
    
    return(i);
}
        
/*------------------------------------------------------------
| FindLockedHandle
|-------------------------------------------------------------
|
| PURPOSE: To find the index of the LockedHandle record
|          in the 'LockedHandleArray' of the given handle.
|
| DESCRIPTION: Returns -1 if not found in array.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.24.94
------------------------------------------------------------*/
s32
FindLockedHandle( void** AHandle )
{
    s32 i;
    s32 CountOfActiveRecords;
    
    CountOfActiveRecords = 0;
    i = 0;
    
    while( LockedHandleArray[i].AHandle != AHandle &&
           CountOfActiveRecords != CountOfLockedHandles )
    {
        if( LockedHandleArray[i].LockLevel )
        {
            CountOfActiveRecords++;
        }
    
        i++;
    }
    
    if( LockedHandleArray[i].AHandle == AHandle )
    {
        return(i);
    }
    else
    {
        return(-1);
    }
}

/*------------------------------------------------------------
| FreeMassMemory
|-------------------------------------------------------------
|
| PURPOSE: To deallocate the entire mass memory pool.
|
| DESCRIPTION: Frees all mass memory as a mass.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.12.94 from 
|                   'CleanUpTheListSystem'
------------------------------------------------------------*/
void
FreeMassMemory( void )
{
    u32*    NextSegment;

    while( TheMassMemorySegmentChain )
    {
        NextSegment = (u32*) 
                      TheMassMemorySegmentChain[0];
        free((u8*) TheMassMemorySegmentChain);
        TheMassMemorySegmentChain = NextSegment;
    }
    TheMassMemoryFreeCount = 0;
}

/*------------------------------------------------------------
| FreeMemory
|-------------------------------------------------------------
|
| PURPOSE: To deallocate a non-relocatable memory segment to 
|          the OS memory pool.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Maybe revise this later to take advantage of 
|          Multifinder temporary memory allocation.
|
| HISTORY: 12.26.90
|          01.21.93 converted to 'C'
------------------------------------------------------------*/
void
FreeMemory( void* ABlock )
{
    DisposePtr( (Ptr) ABlock );
    
 //   InterpretMemoryError();
}

/*------------------------------------------------------------
| FreeRelocatableMemory
|-------------------------------------------------------------
|
| PURPOSE: To deallocate a relocatable memory segment to 
|          the OS memory pool.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Maybe revise this later to take advantage of 
|          Multifinder temporary memory allocation.
|
| HISTORY: 02.23.94 
------------------------------------------------------------*/
void
FreeRelocatableMemory( void** AHandle )
{
    s32 i;
    u16 *AtMemError;
    
    i = FindLockedHandle( AHandle );
    
    if( i != -1 )
    {
        AtMemError  = (u16*) 0x0220; // MemError.
        *AtMemError = -117;          // memLockedErr
    }
    else
    {
        DisposeHandle( (char**) AHandle );
    }

 //   InterpretMemoryError();
}

/*------------------------------------------------------------
| GetHandleState
|-------------------------------------------------------------
|
| PURPOSE: To get the state of a given handle.
|
| DESCRIPTION:  Used in conjunction with 'PutHandleState'
| to save and restore the locking state of a handle.
|
| EXAMPLE:    s = GetHandleState(TheTextEditHandle);  
|
| NOTES:   
|
| ASSUMES: 
|
| HISTORY: 02.23.94
------------------------------------------------------------*/
u16
GetHandleState( void** AHandle )
{
    u16 AState;
    
    AState = (u16) HGetState( (char**) AHandle );
    
 //   InterpretMemoryError();
    
    return( AState );
}
    
/*------------------------------------------------------------
| Lock
|-------------------------------------------------------------
|
| PURPOSE: To lock a handle and exit with error message
|          if an error occurred.
|
| DESCRIPTION: If the handle isn't currently locked it is
| locked and installed in the 'LockedHandleArray'; if already 
| locked the 'LockLevel' for the handle is incremented. 
|
| EXAMPLE:    Lock(TheTextEditHandle);  
|
| NOTES:   
|
| ASSUMES: Will be unlocked using 'Unlock'.
|
| HISTORY: 02.23.94
|          02.25.94 added 'MoveHHi'
------------------------------------------------------------*/
void
Lock( void** AHandle )
{
    s16 i;
    
    i = FindLockedHandle( AHandle );
    
    if( i == -1 ) // Not yet locked.
    {
        // Move block to top of heap before locking to
        // reduce fragmentation.
        
        MoveHHi( (char**) AHandle);
        
        HLock( (char**) AHandle);
        
//        InterpretMemoryError();
        
        CountOfLockedHandles++;
        
        i = FindEmptyLockedHandle();
        
        LockedHandleArray[i].AHandle   = (char**) AHandle;
        LockedHandleArray[i].LockLevel = 1;
    }
    else // Already locked.
    { 
        LockedHandleArray[i].LockLevel++;
        
        AdvanceLockedHandle(i);
    }
}

/*------------------------------------------------------------
| SetHandleSizeWithCompaction
|-------------------------------------------------------------
|
| PURPOSE: To change the size of a relocatable block, 
|          compacting heap if necessary.
|
| DESCRIPTION: Use this as a replacement for 'SetHandleSize'.
|   
|   Entry:  handle = handle to block.
|           len = new size of block.
|   
|   Exit:   function result = error code.
|
| EXAMPLE: SetHandleSizeWithCompaction( h, s );
|
| NOTES:   
|
| ASSUMES: Handle is unlocked.
|
| HISTORY: 11.23.96 from 'MySetHandleSize' of 'NewsWatcher'
|                   'memutil.c'.
------------------------------------------------------------*/
void
SetHandleSizeWithCompaction( void** h, Size s )
{
    OSErr   err;
    
    SetHandleSize( (char**) h, s );
     
    err = MemError();
    
    // The Memory Manager is too stupid to do this itself.
    if( err != noErr ) 
    {
        MoveHHi( (char**) h );
        
        CompactMem( maxSize );
        
        SetHandleSize( (char**) h, s );
         
        err = MemError();
        
        if( err != noErr )
        {
//            InterpretMemoryError();
        } 
    }
}

/*------------------------------------------------------------
| SetHandleState
|-------------------------------------------------------------
|
| PURPOSE: To set the state of a given handle.
|
| DESCRIPTION:  Used in conjunction with 'GetHandleState'
| to save and restore the locking state of a handle.
|
| EXAMPLE:    SetHandleState(TheTextEditHandle,s);  
|
| NOTES:   
|
| ASSUMES: 
|
| HISTORY: 02.23.94
------------------------------------------------------------*/
void
SetHandleState( void** AHandle, u16 AState )
{
    HSetState( (char**) AHandle, (s8) AState );
    
//    InterpretMemoryError();
}

/*------------------------------------------------------------
| SetUpLockedHandleArray
|-------------------------------------------------------------
|
| PURPOSE: To set up the locked handle array.
|
| DESCRIPTION: Sets the LockLevel fields of all entries in
| the array to 0 and sets the CountOfLockedHandles to 0.
|
| EXAMPLE:    SetUpLockedHandleArray();  
|
| NOTES:   
|
| ASSUMES: 
|
| HISTORY: 02.23.94
------------------------------------------------------------*/
void
SetUpLockedHandleArray()
{
    u16 i;
    
    CountOfLockedHandles = 0;
    
    i = 0;
    
    while( i < MaxLockedHandles )
    {
        LockedHandleArray[i].AHandle = 0;
        LockedHandleArray[i].LockLevel = 0;
        i++;
    }
}

/*------------------------------------------------------------
| SizeOfLargestBlockAvailableFromOS
|-------------------------------------------------------------
|
| PURPOSE: To return the number of bytes in the largest 
|          available block in the OS application heap. 
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: This procedure doesn't compact the application heap.
|
| ASSUMES: 
|
| HISTORY: 12.13.90 by Tim Lee
|          01.21.93 converted to 'C'
|          08.11.94 uses PurgeSpace instead of MaxMem.
|          01.11.98 Mad
|          01.25.99 Changed return value to unsigned.
------------------------------------------------------------*/
u32
SizeOfLargestBlockAvailableFromOS()
{
    u32 BiggestBlock;

#ifdef macintosh
    u32 TotalBytes;
    
    PurgeSpace( (s32*) &TotalBytes, (s32*) &BiggestBlock );

#else // Not MacOS

    // Default to nothing for now.
    BiggestBlock = 0;
    
    // Add support for other operating systems as needed.
    Debugger();
    
#endif
    
    // Return the result.
    return( BiggestBlock );
}

/*------------------------------------------------------------
| Unlock
|-------------------------------------------------------------
|
| PURPOSE: To unlock a handle and exit with error message
|          if an error occurred.
|
| DESCRIPTION: If the handle is currently locked the LockLevel
| is decremented. If the LockLevel is now 0, then unlock.
|
| EXAMPLE:    Unlock(TheTextEditHandle);  
|
| NOTES:   
|
| ASSUMES: 
|
| HISTORY: 02.23.94
------------------------------------------------------------*/
void
Unlock( void** AHandle)
{
    s16 i;
    
    i = FindLockedHandle( AHandle );
    
    if( i == -1 ) // Not locked by this application.
    {
        // Treat as though unlocking a block locked by
        // the operating system rather than by the application.
        HUnlock( (char**) AHandle);
        
 //       InterpretMemoryError();
    }
    else // Is locked by this application.
    { 
        LockedHandleArray[i].LockLevel--;
        
        if( LockedHandleArray[i].LockLevel == 0 )
        {
            LockedHandleArray[i].AHandle = 0;
            
            HUnlock( (char**) AHandle);
        
 //           InterpretMemoryError();
        
            CountOfLockedHandles--;
        }
        else
        {
            AdvanceLockedHandle(i);
        }
    }
}

/*------------------------------------------------------------
| UnlockAllLocks
|-------------------------------------------------------------
|
| PURPOSE: To unlock all currently locked relocatable blocks.
|
| DESCRIPTION: Used during memory error interpretation prior
| to exit.
|
| EXAMPLE:    UnlockAllLocks();  
|
| NOTES:   
|
| ASSUMES: 
|
| HISTORY: 02.24.94
------------------------------------------------------------*/
void
UnlockAllLocks()
{
    s16 i;
    
    i = 0;
    
    while( CountOfLockedHandles )
    {
        if(LockedHandleArray[i].LockLevel != 0 )
        {
            HUnlock( LockedHandleArray[i].AHandle);
            LockedHandleArray[i].AHandle = 0;
            LockedHandleArray[i].LockLevel = 0;
            CountOfLockedHandles--;
        }
        i++;
    }
}
        
#endif // FOR_MACOS
