/*------------------------------------------------------------
| TLMassMem.c
|-------------------------------------------------------------
|
| PURPOSE: To provide a special kind of memory allocation such
|          that memory blocks are allocated individually and
|          can be freed collectively as a mass.
|
| HISTORY: 01.21.94 from OSMemoryAllocation.a & 
|                        MemoryAllocation.a
|          02.24.94 added relocatable memory routines.
|          11.23.96 copied from 'MemAlloc.c' of AK2.
|          11.08.98 Pulled out of 'MacOSMemAlloc.c' and
|                   generalized.
|          02.07.01 Removed dependence on TLBytes.h.
------------------------------------------------------------*/

#include "TLTarget.h"

#ifndef FOR_DRIVER

#include <stdlib.h>
#include <string.h>

#endif // FOR_DRIVER

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLMassMem.h"

#ifndef max
#define max(x,y)      ((x)>(y)?(x):(y))
#endif

Lot*    TheMassMemPool = 0;
                // The allocation pool from which all data
                // in MassMem functions is allocated.


/*------------------------------------------------------------
| AllocateMS
|-------------------------------------------------------------
|
| PURPOSE: To allocate space for data in a mass memory pool.
|
| DESCRIPTION: Similar to 'malloc' except that mass memory 
| can be deallocated collectively as a mass instead of 
| pairing a 'free' call with each 'malloc'.  
|
| This saves time and is more space efficient for some 
| applications -- there is no per-data-block header required.
|
| This routine is perfect for very small block allocations 
| where the bits and pieces can be freed later as a group.
|
| Given the control record for a mass memory pool and 
| the size of the data space required, this procedure 
| returns the address of the allocated data block in the pool. 
|
| If allocation fails a zero is returned.
|
| EXAMPLE: 
|               Buf = AllocateMS( 12 );
| NOTE: 
|
| ASSUMES: Mass memory can be deallocated all at once by
|          a call to 'DeleteMass()' or 'EmptyMass()'.
|
|          Segments of memory can also be deallocated using
|          'FreeMS()', at the cost of relocating other data
|          in the mass.
|
|          OK to allocate memory at odd memory addresses.
|
| HISTORY: 11.08.98 From 'AllocateMassMemory()'.
------------------------------------------------------------*/
void*
AllocateMS( Mass* M, u32 DataByteCount )
{
    MassBlock*  B;
    u8*         Result;
    u32         NewBlockSize;
    
    // If the total amount of free space currently in the
    // pool currently exceeds the amount required.
    if( M->FreeByteCount > DataByteCount )
    {
        // Begin searching for a block with enough space.
        B = M->FirstBlockToSearch;
        
        // As long as there is a block.
        while( B )
        {
            // If there is enough space in the block.
            if( B->FreeByteCount > DataByteCount )
            {
                // Record the block found.
                Result = B->EndOfData;
                
                //
                // Account for the space just allocated.
                //
                
                // Update the end of data marker.
                B->EndOfData += DataByteCount;
                
                // Reduce the number of free bytes in the
                // block.
                B->FreeByteCount -= DataByteCount;
                
                // Reduce the number of free bytes in the
                // pool.
                M->FreeByteCount -= DataByteCount;
                
                // If the current block is now full.
                if( B->FreeByteCount == 0 )
                {
                    // If there is a next block.
                    if( B->Next )
                    {
                        // Make that next block the first
                        // one to search for free space.
                        M->FirstBlockToSearch = B->Next;
                    }
                }
                
                // Return the result.
                return( Result );
            }
            
            // Advance to the next block.
            B = B->Next;
        }
    }
    
    //
    // Need to add a new block.
    //
    
    // Calculate the size of the new block, the maximum of
    // the 'NextMassBlockSize' of the pool and the data
    // block size required.
    NewBlockSize = max( M->NextMassBlockSize, DataByteCount );
    
    // If this new block would exceed the maximum storage
    // capacity.
    if( NewBlockSize + M->TotalStorageCapacity > 
        M->MaximumStorageCapacity )
    {
        // Can't allocate, just return zero.
        return( 0 );
    }
     
    // Make the block.
    B = MakeMassBlock( NewBlockSize );
    
    // Insert the new block as last.
    M->LastBlock->Next = B;
    M->LastBlock       = B;
    
    // Update the free byte count for the pool.
    M->FreeByteCount += NewBlockSize;
    
    // Update the current storage capacity.
    M->TotalStorageCapacity += NewBlockSize;
    
    // Record the block found.
    Result = B->EndOfData;
    
    //
    // Account for the space just allocated.
    //
    
    // Update the end of data marker.
    B->EndOfData += DataByteCount;
    
    // Reduce the number of free bytes in the block.
    B->FreeByteCount -= DataByteCount;
    
    // Reduce the number of free bytes in the pool.
    M->FreeByteCount -= DataByteCount;
    
    // Return the result.
    return( Result );
}

/*------------------------------------------------------------
| DeleteDataMS
|-------------------------------------------------------------
|
| PURPOSE: To delete some data held in a mass memory pool but
|          leave the storage allocated.
|
| DESCRIPTION: This procedure deletes a series of data bytes
| from a mass memory pool given an address in the pool and a 
| count of how many bytes are to be deleted.
|
| The data block to be deleted may span block boundaries.
|
| If the data being deleted is not at the end of a 
| 'MassBlock', then subsequent data is shifted toward the 
| beginning of the block to fill the gap left by the deleted 
| data.
|
| EXAMPLE: 
|               DeleteDataMS( M, AtData, 12 );
| NOTE: 
|
| ASSUMES: OK to relocate subsequent data in the mass.
|
|          Data being deleted may span 'MassBlock' boundaries.
|
|          The data exists in the mass to be deleted.
|
| HISTORY: 11.15.98 TL From 'DeletePlaceName()'.
|          02.07.01 TL Replaced CopyBytes with memcpy.
------------------------------------------------------------*/
void
DeleteDataMS( 
    Mass* M,                // The mass memory pool.
                            //
    u8*   DataAddress,      // The address of the first data
                            // byte in the pool.
                            //
    u32   DataSize )        // The number of bytes to be
                            // deleted.
{
    MassBlock*  B;
    u32         SubsequentSize;
    u32         DataSizeThisPass;
    u8*         Lo;
    u8*         Hi;
        
    // Update the free data count for the mass.
    M->FreeByteCount += DataSize;
            
    // Refer to the first block in the mass memory.
    B = M->FirstBlock;
    
    // Until the block that contains the record has
    // been found.
    while( B &&
           DataAddress <  B->FirstData ||
           DataAddress >= B->EndOfData )
    {
        // Advance to the next block.
        B = B->Next;
    }
    
NextPass:

    // Block 'B' holds the current 'DataAddress'.

    // Set the size of the data to be deleted on this
    // pass to the entire amount remaining.
    DataSizeThisPass = DataSize;
    
    // If the end of the segment would extend beyond the
    // end of the data in the current block.
    if( (DataAddress + DataSizeThisPass) > B->EndOfData )
    {
        // Limit the size for this pass.
        DataSizeThisPass = (u32) ( B->EndOfData - DataAddress );
    }
    
    // Calculate the address of the first data byte after
    // the segment being deleted.
    Lo = DataAddress + DataSizeThisPass;
    
    // Record the end of the segment that follows the
    // deleted one.
    Hi = B->EndOfData;
    
    // Calculate the number of bytes in the extent 
    // subsequent to the deleted one.
    SubsequentSize = (u32) ( Hi - Lo );
    
    // Update the 'EndOfData' for the block.
    B->EndOfData -= DataSizeThisPass;
    
    // Update the free data count for the block.
    B->FreeByteCount += DataSizeThisPass;
    
    // If there is data left at the end of the block.
    if( SubsequentSize )
    {
        // Move the surviving data toward the beginning 
        // of the block.
        CopyBytes( Lo,               // From
                   DataAddress,      // To
                   SubsequentSize ); // ByteCount
    }
    
    // Reduce the number of bytes remaining.
    DataSize -= DataSizeThisPass;
        
    // If there are bytes remaining to be deleted.
    if( DataSize )
    {
        // Advance to the next block.
        B = B->Next;
        
        // Set the data address to the first data.
        DataAddress = B->FirstData;
        
        // Go delete some more data.
        goto NextPass;
    }
}

/*------------------------------------------------------------
| DeleteMass
|-------------------------------------------------------------
|
| PURPOSE: To delete a mass memory pool.
|
| DESCRIPTION: Frees all memory associated with a mass memory
| pool including the pool control record itself.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.08.98 from 'FreeMassMemory'.
------------------------------------------------------------*/
void
DeleteMass( Mass* M )
{
    MassBlock*  B;
    MassBlock*  BNext;

    // Start with the first block.
    B = M->FirstBlock;
    
    // Until all of the data storage blocks have been 
    // deleted.
    while( B )
    {
        // Record the address of the block that follows
        // the current one.
        BNext = B->Next;
        
        // Free the current block.       
        FreeMemoryHM( B );
        
        // Regard the next block as the current block.
        B = BNext;
    }
    
    // Then delete the control record.
    FreeMemoryHM( M );
}

/*------------------------------------------------------------
| EmptyMass
|-------------------------------------------------------------
|
| PURPOSE: To empty all of the data from a mass memory pool.
|
| DESCRIPTION: Empties all data and deletes all storage blocks
| following the first one, but keeps the pool control record
| intact and retains the first allocation block.  
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.08.98 from 'FreeMassMemory'.
------------------------------------------------------------*/
void
EmptyMass( Mass* M )
{
    MassBlock*  B;
    MassBlock*  BNext;

    // Start with the second block if any.
    B = M->FirstBlock->Next;
    
    // Until all of the data storage blocks following the
    // first one have been deleted.
    while( B )
    {
        // Record the address of the block that follows
        // the current one.
        BNext = B->Next;
        
        // Free the current block.       
        FreeMemoryHM( B );
        
        // Regard the next block as the current block.
        B = BNext;
    }
    
    // Refer to the first block.
    B = M->FirstBlock;
    
    // Mark the first block as the only block.
    B->Next = 0;

    // Empty the data in the first block.
    B->EndOfData     = B->FirstData;
    B->FreeByteCount = (u32) ( B->EndOfBlock - B->EndOfData );

    // The first block is also the first block to 
    // search for free space.
    M->FirstBlockToSearch = B;
    
    // The first block is also the last block.
    M->LastBlock = B;
    
    // The total free byte count is the free byte count 
    // of the first block.
    M->FreeByteCount = B->FreeByteCount;
    
    // The total storage capacity is also the same as
    // the total free byte count right now.
    M->TotalStorageCapacity = B->FreeByteCount;
}

/*------------------------------------------------------------
| MakeMass
|-------------------------------------------------------------
|
| PURPOSE: To make a new mass memory storage pool.
|
| DESCRIPTION: Makes a structure to organize the mass memory
| pool and allocates the first storage block.
|
| Use 'AllocateMS()' to allocate memory for data storage
| within a mass memory pool -- there is no corresponding
| 'free' routine to free individual data blocks.
|
| Use 'EmptyMass()' to empty the all the data, but retain the
| storage blocks, in a mass memory pool.
|
| Use 'DeleteMass()' to free mass memory pools that are 
| no longer useful.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.08.98 TL From 'MakeTable'.
|          06.23.01 Added return of 0 on allocation failure.
------------------------------------------------------------*/
        // OUT: Address of a mass memory pool or zero on 
Mass*   //      failure.
MakeMass( 
    u32 MaximumStorageCapacity,
            // The most amount of memory space that can
            // be set aside to hold this mass memory 
            // pool.
            //
    u32 FirstMassBlockSize,
            // The size of the data storage field
            // of the first mass memory block made when 
            // this mass memory pool is first made.
            //
    u32 NextMassBlockSize )
            // The minimum size of the data storage 
            // field of a mass memory block: blocks may 
            // be larger if the required data block is 
            // larger.
{
    Mass*       M;
    MassBlock*  B;
    
    // Allocate a record for the mass memory pool.
    M = (Mass*) 
        AllocateMemoryAnyPoolHM( 
            TheMassMemPool, 
            sizeof( Mass ) );
            
    // If unable to allocate the record.
    if( M == 0 )
    {
        // Just return zero to signal failure.
        return(0);
    }
     
    //
    // Fill in the fields of the record.
    //
    
    // Make the first data storage block.
    B = MakeMassBlock( FirstMassBlockSize );
    
    // If unable to allocate the block.
    if( B == 0 )
    {
        // Free the Mass record.
        FreeMemoryHM( M );
        
        // Just return zero to signal failure.
        return(0);
    }
     
    // Record the block as being first.
    M->FirstBlock = B;
    
    // The first block is also the first block with
    // free space.
    M->FirstBlockToSearch = B;
    
    // The first block is also the last block.
    M->LastBlock = B;
    
    // The total free byte count is the free byte count 
    // of the first block.
    M->FreeByteCount = B->FreeByteCount;
    
    // The total storage capacity is also the same as
    // the total free byte count right now.
    M->TotalStorageCapacity = B->FreeByteCount;
    
    // Set the upper limit on storage for this pool.
    M->MaximumStorageCapacity = MaximumStorageCapacity;
    
    // Record the minimum size of the subsequent blocks.
    M->NextMassBlockSize = NextMassBlockSize;
    
    // Return the control record address for the new
    // mass memory pool.
    return( M );
}

/*------------------------------------------------------------
| MakeMassBlock
|-------------------------------------------------------------
|
| PURPOSE: To make a new MassBlock record. 
|
| DESCRIPTION: When a MassBlock record is initially made
| is holds no data. 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 'Next', 'Prev' and 'MyTable' fields are set to
|          zero and will be filled in later when the block is 
|          made part of a table.
|
| HISTORY: 11.08.98 TL From 'MakeRecordBlock'.
|          06.23.01 Added return of 0 on allocation failure.
------------------------------------------------------------*/
            // OUT: Address of a mass memory block or zero on 
MassBlock*  //      failure.
MakeMassBlock( 
    u32 DataStorageCapacity )
        // How many data bytes can be stored in this new 
        // block.
{
    MassBlock*  B;
    u32         BlockByteCount;
    
    // Calculate the total size of the memory block that
    // holds the block.
    BlockByteCount = sizeof( MassBlock ) +
                     DataStorageCapacity;
    
    // Allocate space for the block.
    B = (MassBlock*) 
        AllocateMemoryAnyPoolHM( 
            TheMassMemPool, 
            BlockByteCount );

    // If failed to allocate the block.
    if( B == 0 )
    {
        // Just return zero to signal failure.
        return(0);
    }
        
    //
    // Fill in the fields of the record.
    //
    
    // Clear the block list link field which will be 
    // filled in when the block is inserted into a list.
    B->Next  = 0;
    
    // Initially all storage bytes are free.
    B->FreeByteCount = DataStorageCapacity;
    
    // Set the RAM address of the first byte in the
    // data storage field: the data immediately follow 
    // the block header.
    B->FirstData =
        ( ((u8*) B ) + sizeof( MassBlock ) );

    // Set the address that marks the end of the existing 
    // data bytes in the block, the first byte following 
    // the last byte.  Initially there will be no bytes 
    // in the block.
    B->EndOfData = B->FirstData;

    // Set the address that marks the end of the block.
    B->EndOfBlock = ( ((u8*) B ) + BlockByteCount );
    
    // Return the address of the block.
    return( B );
}

