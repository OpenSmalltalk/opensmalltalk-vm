/*------------------------------------------------------------
| TLMemOS.c
|-------------------------------------------------------------
|
| PURPOSE: To provide OS-specific, fixed-location memory block 
|          allocation functions.
|
| DESCRIPTION:  
|
| HISTORY: 05.26.01 TL From TLMassMem.h and TLMem.h.
------------------------------------------------------------*/

#include "TLTarget.h"

#include "NumTypes.h"

#ifdef macintosh
#include <Memory.h>     // For Mac OS memory functions.
#endif

#include "TLMemOS.h"

#ifdef FOR_DRIVER
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "UserMap.h"
#endif

/*------------------------------------------------------------
| AllocateMemoryOS
|-------------------------------------------------------------
|
| PURPOSE: To allocate a fixed-location memory block from the 
|          operating system.
|
| DESCRIPTION: Given the length required in bytes, this 
| procedure returns the address of the newly allocated memory 
| block or 0 if allocation failed.
|
| EXAMPLE:  
|               A = AllocateMemoryOS( BlockSize );
|
| NOTE: May be slow due to compaction.
|
| HISTORY: 12.26.90 by Tim Lee
|          01.21.93 converted to 'C'
|          02.24.94 added MemoryErrorInterpreter.
|          08.05.94 revised for Trapper.
|          01.11.99 Revised for NT.
|          01.25.99 Changed 'ByteCount' to unsigned.
|          05.26.01 Copied from TLMem.c and added Win32 driver 
|                   support.
------------------------------------------------------------*/
void*  // OUT: Address of the buffer or 0 if failed.
AllocateMemoryOS( u32 BlockSize ) 
                    // Size of the data block to allocate
                    // in bytes.
{
    u8* ABlock;
    
#ifdef macintosh

    // Allocate the requested memory.
    ABlock = (u8*) NewPtr( BlockSize );
    
#else // Not MacOS.

#if defined( __INTEL__ ) || defined( _M_IX86 )

#ifdef FOR_DRIVER

    //
    // If building for a kernel mode driver.
    //
    
    DebugPrint( "AllocateMemoryOS BlockSize = %d\n",
                BlockSize );
                
    // TL: Don't allocate using MmAllocateContiguousMemory
    //     here because it's less likely to succeed.
    
    // If the current IRQL is above DISPATCH_LEVEL.
    if( KeGetCurrentIrql() > DISPATCH_LEVEL )
    {
        DebugPrint( "AllocateMemoryOS invalid IRQL.\n",
                    BlockSize );
                    
        // Return zero to signal failure.
        ABlock = 0;
    }
    else // IRQL <= DISPATCH_LEVEL
    {
        // Allocate a block from the non-paged pool aligned
        // on the processor cache boundary.
        //
        // This must be called at IRQL <= DISPATCH_LEVEL.
        ABlock = (u8*) 
            ExAllocatePool( 
                NonPagedPoolCacheAligned, 
                BlockSize );
    }
    
    DebugPrint( "AllocateMemoryOS BlockAddr = 0x%x\n",
                ABlock );

#else // Not building for a kernel mode driver.

    // Try to allocate a new block from the OS.
    ABlock = (u8*) 
        VirtualAlloc( 
            0,      // Allocate the block anywhere
                    // but do it towards the high
                    // end of VM: see 'MEM_TOP_DOWN'
                    // below.
                    //          
            BlockSize,
                    // How many bytes are requested
                    // in the region.
                    //
            ( MEM_RESERVE | MEM_COMMIT | MEM_TOP_DOWN ),
                    // Reserve and commit the memory
                    // at the same time, allocating
                    // from top of VM space downward.
                    //
            PAGE_EXECUTE_READWRITE );
                    // Allow reading, writing and
                    // execution of memory in the 
                    // block.
                    
#endif // FOR_DRIVER   
        
#endif // __INTEL__

#endif // macintosh

    // Return the block address or zero on failure.   
    return( (void*) ABlock );
}

/*------------------------------------------------------------
| FreeMemoryOS
|-------------------------------------------------------------
|
| PURPOSE: To deallocate a fixed-location memory block to 
|          the OS memory pool.
|
| DESCRIPTION: Use this routine to free memory acquired using
| 'AllocateMemoryOS()'.
|
| EXAMPLE:           FreeMemoryOS( ABlock );
|
| ASSUMES: IRQL <= DISPATCH_LEVEL for Win32 drivers.
|
| HISTORY: 12.26.90 by Tim Lee
|          01.21.93 converted to 'C'.
|          01.12.98 Added NT support.
|          05.26.01 Copied from TLMem.c and added Win32 driver 
|                   support.
|          06.08.01 Added DeleteUserMapsThatReferToBlock.
------------------------------------------------------------*/
void
FreeMemoryOS( void* ABlock )
{
#ifdef macintosh

    // Return the block to the Mac Memory Manager.
    DisposePtr( (Ptr) ABlock );
    
#else // Not MacOS.

#if defined( __INTEL__ ) || defined( _M_IX86 )

#ifdef FOR_DRIVER

    // If building for a kernel mode driver.
    
    DebugPrint( "FreeMemoryOS BlockAddr = 0x%x\n", ABlock );

    // If the current IRQL is above DISPATCH_LEVEL.
    if( KeGetCurrentIrql() > DISPATCH_LEVEL )
    {
        DebugPrint( "    Failed, IRQL > DISPATCH_LEVEL.\n" );
    }
    else // IRQL <= DISPATCH_LEVEL
    {
        // Delete all UserMaps that refer to this block.
        DeleteUserMapsThatReferToBlock( (u8*) ABlock );
                    // Base address of the block in system VM
                    // space.
            
        // Deallocate the block to the non-paged pool.
        //
        // This must be called at IRQL <= DISPATCH_LEVEL.
        ExFreePool( ABlock );
    }

#else // Not building for a kernel mode driver.

    // Free the memory block back to the NT OS.
    VirtualFree( (LPVOID) ABlock, 0, MEM_RELEASE );

#endif // FOR_DRIVER

#endif // __INTEL__

#endif // macintosh
}
