/*------------------------------------------------------------
| TLMemHM.c
|-------------------------------------------------------------
|
| PURPOSE: To provide hierarchical memory allocation 
|          functions.
|
| DESCRIPTION: These functions support memory allocation of
| memory blocks which can be used as pools for subdivision
| into memory blocks.
|
| HISTORY: 05.26.01 TL From TLMassMem.h and TLMem.h.
------------------------------------------------------------*/

#include "TLTarget.h"

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLMemOS.h"
#include "TLBuf.h"

#include "TLMemHM.h"

Lot*    TheBufPool = 0;
                // The allocation pool from which all data
                // in Buf functions is allocated.

u32     TheTotalBytesInUseHM = 0;
                // The total number of bytes allocated from
                // the OS pool by HM functions which have not 
                // also been freed via HM functions.
                
u32     TheMostBytesInUseHM = 0;
                // The highest total number of bytes ever
                // allocated by HM functions from the OS 
                // memory pool at any one time.
                
u32     ThePoolQuantum = 4096;
                // The size of an allocation unit when 
                // allocating a pool from the OS memory pool.
                //
                // Set the default allocation pool unit to
                // 4K, the size of PAGE_SIZE in Windows2000.

u32     TheMinimumPoolSize = 4096;
                // The minimum number of bytes that can be
                // allocated from the OS memory pool.
                //
                // Set the default allocation pool unit to
                // 4K, the size of PAGE_SIZE in Windows2000.
                
/*------------------------------------------------------------
| AllocateBuf
|-------------------------------------------------------------
|
| PURPOSE: To allocate a data buffer for a 'Buf' control 
|          record.
|
| DESCRIPTION: Allocates a data buffer and then updates the
| 'Buf' record to refer to it.  The data buffer is initially
| empty of data.
|
| EXAMPLE:      AllocateBuf( &B, 16 );
|
| NOTE: Use 'FreeBuf()' to discard a data buffer allocated 
|       using this procedure.
|
| ASSUMES: Memory space is available for the buffer.
|
| HISTORY: 12.11.98 TL
|          04.10.99 Added 'IsOwned' field setting.
------------------------------------------------------------*/
void
AllocateBuf( 
    Buf* B,     // The control record that will refer to
                // the new data buffer on exit from this
                // function.
                //      
    u32  Size ) // How many bytes of storage to allocate for
                // holding data.
{
    // Allocate a data buffer.
    B->Lo = (u8*) 
        AllocateMemoryAnyPoolHM( 
            TheBufPool, 
            Size );
     
    // Mark the end of the buffer.
    B->HiBuf = B->Lo + Size;
    
    // Mark the end of the data.
    B->Hi = B->Lo;
    
    // Claim ownership of the buffer.
    B->IsOwned = 1;
}

/*------------------------------------------------------------
| AllocateMemoryAnyPoolHM
|-------------------------------------------------------------
|
| PURPOSE: To allocate a memory buffer from a given pool or 
|          failing allocation there, from any superior pool 
|          in the hierarchy, ultimately allowing allocation
|          directly from the operating system.
|
| DESCRIPTION:  
|
| Use the companion function FreeMemoryHM() to deallocate
| buffers allocated using this function.
|
| EXAMPLE: 
|             B = AllocateMemoryAnyPoolHM( 0, SizeInBytes );
|
| HISTORY: 05.24.01 TL From MakeDataRecord and AllocateBuf.
|          05.25.01 Added nested buffer allocation.  
|          07.05.01 Revised new pool allocation so that
|                   blocks are never allocated as pools but
|                   always within pools owned by the user.
|                   This keeps blocks from been freed back
|                   to the OS -- only pools get freed back
|                   to the OS pool.  Also added minimum pool
|                   size and quantization.
------------------------------------------------------------*/
                // OUT: The data buffer address of an 
void*           //      allocated memory block.
AllocateMemoryAnyPoolHM( 
    Lot*    Pool,
                // If the new buffer should be allocated
                // within an existing pool then this 
                // is the address of that pool.  
                // 
                // Use zero here if the buffer should be 
                // allocated directly from an OS memory 
                // pool.
                //
    u32     DataBlockSize )
                // Size of the data block to allocate
                // in bytes.  The actual block size
                // allocated will be larger by the size
                // of the Lot header record prepended to
                // the data buffer.
{
    void*   ABlock;
    Lot*    NewPool;
    u32     PoolSize;

///////////
TryAgain://
/////////// 

    // Attempt to allocate the block from the current pool.
    ABlock =
        AllocateMemoryHM( 
            Pool,
                // If the new buffer should be allocated
                // within an existing pool then this 
                // is the address of that pool.  
                // 
                // Use zero here if the buffer should be 
                // allocated directly from an OS memory 
                // pool.
                //
            DataBlockSize );
                // Size of the data block to allocate
                // in bytes.  The actual block size
                // allocated will be larger by the size
                // of the Lot header record prepended to
                // the data buffer.

    // If the allocation failed.
    if( ABlock == 0 )
    {
        // If the current pool came directly from the
        // operating system.
        if( Pool && Pool->Super == 0 )
        {
            // If there is another OS pool following the
            // current pool.
            if( Pool->Next )
            {
                // Then make the next pool the current pool.
                Pool = Pool->Next;
                
                // And try again.
                goto TryAgain;
            }
            else // There is no next pool.
            {
                //
                // Try to allocate a new pool from the OS
                // and add it to the end of the pool chain.
                //
                // Then allocate the block within that pool.
                //
                // The motivation for the above approach is 
                // to keep blocks from been freed back to the 
                // OS -- only pools get freed back to the OS 
                // pool.  
                //
                
                // Calculate the size that should be used for the 
                // new allocation pool.
                PoolSize = CalculateTotalPoolSize( DataBlockSize );
                
                // Try to allocate a new pool from the OS.
                ABlock =
                    AllocateMemoryHM( 
                        0,
                            // If the new buffer should be 
                            // allocated within an existing 
                            // pool then this is the address 
                            // of that pool.  
                            // 
                            // Use zero here if the buffer 
                            // should be allocated directly 
                            // from an OS memory pool.
                            //
                        PoolSize );
                            // Size of the data block to 
                            // allocate in bytes.  The actual 
                            // block size allocated will be 
                            // larger by the size of the Lot 
                            // header record prepended to
                            // the data buffer.
                
                // If the pool was allocated.
                if( ABlock )
                {
                    DebugPrint( "TLMemHM: new pool allocated.\n" );
                    
                    // Refer to the new pool header.
                    NewPool = AddressOfLotHeader(ABlock);
                    
                    // Empty the pool so it can be used for 
                    // allocating the data block.
                    EmptyLot( NewPool );
                        
                    // Link this new pool after the last OS pool.
                    Pool->Next    = NewPool;
                    NewPool->Prev = Pool;
                    
                    // Regard the new pool as the one to allocate
                    // from.
                    Pool = NewPool;
                    
                    // Now go allocate the block from the new pool.
                    goto TryAgain;
                }
    
                DebugPrint( "TLMemHM: failed to allocate new pool.\n" );
                
                // All done now: failed to get a new pool 
                // from the OS.
                goto Done;
            }
        }
        else // The current pool did not come directly from
             // the operating system.
        {
            // If the current pool is explicitly defined.
            if( Pool )
            {
                // Make the superior pool the current one.
                Pool = Pool->Super;
        
                // And try again.
                goto TryAgain;
            }
        }
    }       
            
/////// 
Done://
/////// 
    
    // Return the block allocated or zero if unable to
    // allocate a block.
    return( ABlock );
}

/*------------------------------------------------------------
| AllocateMemoryHM
|-------------------------------------------------------------
|
| PURPOSE: To allocate a memory block from a pool of memory.
|
| DESCRIPTION: This function allocates memory buffers directly
| or indirectly from a pool managed by the operating system.
|
| Indirect allocation entails allocation within a pool
| previously allocated directly from the operating system.
|
| If a pool is allocated within another then link fields 
| are used to connect them all together as shown in the 
| comment header of the Lot structure -- see 
| TLMemHM.h.
|
| Use the companion function FreeMemoryHM() to deallocate
| buffers allocated using this function.
|
| EXAMPLE: 
|             B = AllocateMemoryHM( 0, SizeInBytes );
|
| ASSUMES: The data field is allocated as being full, in
|          other words the Hi marker which indicates the end
|          of the data in the buffer is set to the physical
|          end of the block.
|
|          If the allocated block is to be used as a memory 
|          pool it must first be emptied of data by setting 
|          the Hi field to the value of the Lo field in the 
|          Lot header.
|
| HISTORY: 05.24.01 TL From MakeDataRecord and AllocateBuf.
|          05.25.01 Added nested buffer allocation.  
|          05.20.01 Revised sibling link usage.
|          06.17.01 Added TheTotalBytesInUseHM and
|                   TheMostBytesInUseHM.
|          07.01.01 Fixed case where FindBestFitLot() returns
|                   zero and closed a similar hole when
|                   returning zero from AllocateMemoryOS().
|          07.05.01 Fixed error in which data was not being
|                   accounted as present in a block allocated
|                   directly from the OS pool.
------------------------------------------------------------*/
                // OUT: The data buffer address of an 
void*           //      allocated memory block.
AllocateMemoryHM( 
    Lot*    Pool,
                // If the new buffer should be allocated
                // within an existing pool then this 
                // is the address of that pool.  
                // 
                // Use zero here if the buffer should be 
                // allocated directly from an OS memory 
                // pool.
                //
    u32     DataBlockSize ) 
                // Size of the data block to allocate
                // in bytes.  The actual block size
                // allocated will be larger by the size
                // of the Lot header record prepended to
                // the data buffer.
{
    Lot* A;
    u32  TotalSize;
  
    // Calculate the total number of bytes required to hold a 
    // data block along with any overhead for the Lot header.
    //
    // OUT: The total block size in bytes.
    TotalSize = CalculateTotalBlockSize( DataBlockSize );

    // If the memory block is to be allocated within a pool
    // explicitly defined by a Lot structure.
    if( Pool )
    {
        // If there is room in the pool to allocate a block
        // at the end of the data section.
        if( IsRoomInBuf( Pool, TotalSize ) )
        {
            // Allocate the block at the end of the data
            // section of the pool.
            A = (Lot*) Pool->Hi;
            
            // Zero the Lot record.
            ZeroBytes( (u8*) A, sizeof( Lot ) );
            
            // Account for the new data added to the
            // data section of the super buffer.
            Pool->Hi += TotalSize;
            
            //
            // Link the new block as logically first in 
            // the pool block list, but physically last.
            //
            {
                // If there is already a block in the pool.
                if( Pool->Sub )
                {
                    // Link the old first block back to the 
                    // new block.
                    Pool->Sub->Prev = A;
                }
                
                // Link the new block forward to the old 
                // first block if any.
                A->Next = Pool->Sub;
            
                // Set A's Prev link is zero to show that
                // it is logically first in the pool.
                A->Prev = 0;
                
                // Make the new block the first block in 
                // the pool subordinate list.
                Pool->Sub = A;
            }
        }
        else // Not enough room to allocate append a new 
             // sub-buffer at the end of the data section.
        {
            // Look for the smallest free block in the 
            // pool that is big enough for the required
            // data block.
            //
            // Warning: this could be very wasteful of
            // space, but it's simple to do and avoids
            // splitting blocks.
            A = FindBestFitLot( Pool, DataBlockSize );
            
            // If a block has been found.
            if( A )
            {
                // If the block wastes too much space.
                if( ( SizeOfBuf( A ) - DataBlockSize ) >
                    MAX_WASTED_BYTES )
                {
                    // Then fail in this allocation.
                    A = 0;
                }
            }
        }
    }
    else // No allocation pool is specified, implying that
         // the block should come from the OS pool.
    {
        // This is the only place where memory is allocated
        // from the OS memory pool.
        //
        // Allocate the memory from the OS.
        A = (Lot*) AllocateMemoryOS( TotalSize );
        
        // If a block was allocated from the OS pool.
        if( A )
        {
            // Zero the Lot record.
            ZeroBytes( (u8*) A, sizeof( Lot ) );
            
            // Account for the bytes allocated from which ever
            // pool.
            TheTotalBytesInUseHM += TotalSize;
            
            // If the total in use now is higher than ever.
            if( TheTotalBytesInUseHM > TheMostBytesInUseHM )
            {
                // Update the high water mark.
                TheMostBytesInUseHM = TheTotalBytesInUseHM;
            }
        }
    }
    
    // If the memory block was not allocated.
    if( A == 0 )
    {
        // Abort the operation.
        goto OnAbort;
    }

    // Link to the superior pool of this block if any.
    A->Super = Pool;
    
    // Mark the new block as having no subordinates.
    A->Sub = 0;
    
    // Set the reference count to 1.
    A->ReferenceCount = 1;
    
    // Refer to the base of the data buffer.
    A->Lo = ( (u8*) A ) + sizeof(Lot);
    
    // Mark the physical end of the buffer.
    A->HiBuf = ( (u8*) A ) + TotalSize;

    // Assume that the entire data buffer is in use as a 
    // data block.
    //
    // This is needed to avoid allocation of sub blocks 
    // within an area already allocated for another use.
    //
    // It is therefore necessary to empty this data block 
    // before it can be used as a pool for allocation of 
    // sub blocks.
    A->Hi = A->HiBuf;
     
    // Return the address of the data buffer.
    return( (void*) AddressOfLotDataBuffer(A) );

//////////
OnAbort://
//////////

    // Return status code for failure, zero.
    return( 0 );
}

/*------------------------------------------------------------
| CalculateTotalBlockSize
|-------------------------------------------------------------
|
| PURPOSE: To calculate the total number of bytes required to
|          hold a data block along with any overhead for the
|          Lot header.
|
| DESCRIPTION:  
|
| EXAMPLE:        t = CalculateTotalBlockSize( 6 );
|
| HISTORY: 07.05.01 TL
------------------------------------------------------------*/
u32 // OUT: The total block size in bytes.
CalculateTotalBlockSize( u32 DataBlockSize )
                               // Size of the desired data
                               // block in bytes.
{
    u32 TotalSize;
    
    // Calculate the total number of bytes to allocate for a 
    // block header and appended data buffer.
    TotalSize = sizeof( Lot ) + DataBlockSize;
    
    // Make block size an even multiple of 16 bytes for 
    // alignment and unit economy.
    TotalSize = ( TotalSize + 15 ) & 0xFFFFFFF0;
    
    // Return the effective block size in bytes for the
    // given nominal size.
    return( TotalSize );
}

/*------------------------------------------------------------
| CalculateTotalPoolSize
|-------------------------------------------------------------
|
| PURPOSE: To calculate the adjusted total number of bytes 
|          required to hold an allocation pool.
|
| DESCRIPTION:  
|
| EXAMPLE:        t = CalculateTotalPoolSize( 6 );
|
| HISTORY: 07.05.01 TL
------------------------------------------------------------*/
u32 // OUT: The total pool size in bytes.
CalculateTotalPoolSize( u32 DataBlockSize )
                               // Size of the desired data
                               // field of the pool in bytes.
{
    u32 TotalSize;
    u32 PoolUnits;
    
    // Calculate the total number of bytes required to hold a 
    // data block along with any overhead for the Lot header.
    //
    // OUT: The total block size in bytes.
    TotalSize = CalculateTotalBlockSize( DataBlockSize );
    
    // Then calculate the size needed to hold this data block 
    // in a pool as a block.
    TotalSize = CalculateTotalBlockSize( TotalSize );
    
    // Calculate the number of pool units required to hold 
    // the pool.
    PoolUnits = TotalSize / ThePoolQuantum;
    
    // If there is any remainder.
    if( TotalSize % ThePoolQuantum ) 
    {
        // Add another pool unit.
        PoolUnits += 1;
    }
                
    // Convert the number of pool units back into bytes.
    TotalSize = PoolUnits * ThePoolQuantum;
                
    // Limit the pool to a minimum size.
    if( TotalSize < TheMinimumPoolSize )
    {
        // Set the total size to the minimum pool size.
        TotalSize = TheMinimumPoolSize;
    }
    
    // Return the total number of bytes that should be
    // allocated for this pool.
    return( TotalSize );
}

/*------------------------------------------------------------
| DumpLot
|-------------------------------------------------------------
|
| PURPOSE: To output the field values of a Lot record to the 
|          debug output.
|
| DESCRIPTION: This routine uses the DebugPrint() routine to
| send output to DebugView.
| 
| HISTORY: 05.31.01 TL  
------------------------------------------------------------*/
void
DumpLot( Lot* A )
{
    DebugPrint( "BEGIN LOT RECORD AT 0x%x ------------ \n", 
                (u32) A );
              
    // If the address of the device is valid.
    if( A )
    {
        // Print the field values.
        DebugPrint( "Super.................. 0x%x\n", (u32) A->Super );
        DebugPrint( "Next................... 0x%x\n", (u32) A->Next );
        DebugPrint( "Prev................... 0x%x\n", (u32) A->Prev );
        DebugPrint( "Sub.................... 0x%x\n", (u32) A->Sub );
        DebugPrint( "ReferenceCount......... 0x%x\n", (u32) A->ReferenceCount );
        DebugPrint( "Lo..................... 0x%x\n", (u32) A->Lo );
        DebugPrint( "Hi..................... 0x%x\n", (u32) A->Hi );
        DebugPrint( "HiBuf.................. 0x%x\n\n", (u32) A->HiBuf );
        
        DebugPrint( "SizeOfBuf.............. 0x%x\n", 
                    (u32) SizeOfBuf( A ) );
                    
        DebugPrint( "SizeOfDataInBuf........ 0x%x\n", 
                    (u32) SizeOfDataInBuf( A ) );
    }

    DebugPrint( "END LOT RECORD ---------------------- \n" );
}

/*------------------------------------------------------------
| EmptyLot
|-------------------------------------------------------------
|
| PURPOSE: To empty the data from the data buffer owned by a 
|          'Lot' but leave the buffer allocated.
|
| DESCRIPTION: Use this routine to convert a data block to
| a pool for allocation of sub blocks.
|
| EXAMPLE:        EmptyLot( A );
|
| HISTORY: 07.05.01 From EmptyBuf().
------------------------------------------------------------*/
void 
EmptyLot( Lot* A )
{
    // Set the end of data marker to the beginning of the
    // data buffer.
    A->Hi = A->Lo;
}

/*------------------------------------------------------------
| ExtractLot
|-------------------------------------------------------------
|
| PURPOSE: To extract a Lot record from the tree structure
|          in which it is held.
|
| DESCRIPTION:  
| 
| EXAMPLE: 
|                     ExtractLot( A );
|
| HISTORY: 05.30.01 TL
------------------------------------------------------------*/
void
ExtractLot( Lot* A )
{
    Lot* Super;
    Lot* Nxt;
    Lot* Prv;
    Lot* Sub;
    
    // Refer to the block above A.
    Super = A->Super;

    // Refer to the block after A.
    Nxt = A->Next;

    // Refer to the block prior to A.
    Prv = A->Prev;
    
    // Refer to the block below A.
    Sub = A->Sub;
    
    // If A has a superior.
    if( Super )
    {
        // If the superior refers to A as a subordinate.
        if( Super->Sub == A )
        {
            // Then revise the superior's subordinate link
            // to refer to the block following A.
            Super->Sub = Nxt;
        }
    }

    // Patch forward link if there is one.
    if( Prv )
    {
        Prv->Next = Nxt;
    }
    
    // Patch backward link if there is one.
    if( Nxt )
    {
        Nxt->Prev = Prv;
    }
}

/*------------------------------------------------------------
| FindBestFitLot
|-------------------------------------------------------------
|
| PURPOSE: To find the smallest free block in a pool that is 
|          big enough for a data block of a given size.
|
| DESCRIPTION: Returns the block address if successful, else 
| returns 0 on failure.
| 
| EXAMPLE:    
|              L = FindBestFitLot( Pool, ADataSize );
|
| ASSUMES: OK to scan every block in a pool to find the
|          the best one.
|
| HISTORY: 05.26.01 TL From FindBigEnoughUnitToSplit.
------------------------------------------------------------*/
Lot*            // OUT: A free memory block with header.
FindBestFitLot( 
    Lot*    Pool,
                // If the new buffer should be allocated
                // within an existing pool then this 
                // is the address of that pool.  
                // 
                // Use zero here if the buffer should be 
                // allocated directly from an OS memory 
                // pool.
                //
    u32     DataBlockSize ) 
                // The minimum satisfactory size of the data 
                // block to allocate in bytes.  
{
    Lot* A;
    Lot* BestLot;
    u32  BestSize;
    
    // Start with no best block found.
    BestLot = 0;
        
    // If a valid pool was specified.
    if( Pool )
    {
        // Refer to first block in the pool.
        A = Pool->Sub;
        
        // As long as the current block is valid.
        while( A )
        {
            // If the block is marked as free.
            if( A->ReferenceCount == 0 )
            {
                // If this block is big enough.
                if( SizeOfBuf( A ) >= DataBlockSize )
                {
                    // If this is the first good block found.
                    if( BestLot == 0 )
                    {
                        // Then this is the best one too.
                        BestLot = A;
                        
                        // Note the size of the best found
                        // so far.
                        BestSize = SizeOfBuf( A );
                    }
                    else // Another free block has been
                         // found before.
                    {
                        // If the current block is a better
                        // fit than the best so far.
                        if( SizeOfBuf( A ) < BestSize )
                        {
                            // Then a better block has been
                            // found.
                            BestLot = A;
                            
                            // Note the size of the best found
                            // so far.
                            BestSize = SizeOfBuf( A );
                        }
                    }
                    
                    // If a perfect fit has been found.
                    if( BestSize == DataBlockSize )
                    {
                        // Return the block found.
                        return( BestLot );
                    }
                }
            }
        
            // Traverse to another block in the pool.
            A = A->Next;
        }
    }
    
    // Return the best block found or zero if none found.
    return( BestLot );      
}

/*------------------------------------------------------------
| FreeBuf
|-------------------------------------------------------------
|
| PURPOSE: To deallocate the data buffer owned by a 'Buf'.
|
| DESCRIPTION: Use this procedure to discard data buffers
| produced by 'AllocateBuf'.
|
| Doesn't free the 'Buf' record itself.
|
| EXAMPLE:      FreeBuf( B );
|
| NOTE: 
|
| ASSUMES: If the 'Lo' field of the buffer is non-zero then
|          value is the address of a buffer allocated using
|          'AllocateMemoryAnyPoolHM'.
|
| HISTORY: 12.13.98  
|          04.10.99 Added 'IsOwned' control.
------------------------------------------------------------*/
void
FreeBuf( Buf* B )
{
    // If there is a buffer and it is owned.
    if( B->Lo && B->IsOwned )
    {
        // Free the data buffer.
        FreeMemoryHM( B->Lo );
    
        // Mark the data buffer as free.
        B->Lo = 0;
    }
}

/*------------------------------------------------------------
| FreeMemoryHM
|-------------------------------------------------------------
|
| PURPOSE: To free a memory block allocated by the procedure 
|          AllocateMemoryHM().
|
| DESCRIPTION: This function deallocates memory blocks to the
| pool from which they were allocated.
|
| If deallocating to a pool defined by a Lot record then the
| reference count indicates the free/in-use status of the
| block and no attempt is made to merge free blocks.
| 
| EXAMPLE: 
|                FreeMemoryHM( A );
|
| HISTORY: 05.25.01 TL
|          05.30.01 TL Added ExtractLot() to allow linking
|                      OS blocks together.
|          06.17.01 Added TheTotalBytesInUseHM.
|          07.04.01 Changed TheTotalBytesInUseHM to account
|                   for memory allocated from the OS pool.
|          07.06.01 Fixed error where access was made to a
|                   block header after it had been freed.
------------------------------------------------------------*/
void
FreeMemoryHM( void* AtDataBuffer ) 
              // The data buffer address of a block allocated
              // by AllocateMemoryHM().
{
    Lot* H;
    u32  TotalSize;
    
    // If there is no buffer to be freed.
    if( AtDataBuffer == 0 )
    {   
        // Then just return.
        return;
    }
    
    // Refer to the block header.
    H = AddressOfLotHeader( AtDataBuffer );
    
    // If the reference counter for the buffer is above zero.
    if( H->ReferenceCount > 0 )
    {
        // Decrement the reference counter.
        H->ReferenceCount -= 1;
        
        // If the reference counter has reached zero.
        if( H->ReferenceCount == 0 )
        {
            // If this block was allocated directly from
            // the operating system.
            if( H->Super == 0 )
            {
                // Extract the block from the tree structure
                // in which it is held.
                ExtractLot( H );
                
                // Calculate the total size of the allocation 
                // block including the Lot header.
                TotalSize = H->HiBuf - (u8*) H;
                
                // Account for the bytes deallocated to the 
                // OS pool. 
                TheTotalBytesInUseHM -= TotalSize;

                // Free the block to the OS.
                FreeMemoryOS( (u8*) H );
            }
            else // The block was allocated from a Lot-defined
                 // pool.
            {
                // Just leave the block where it is so that it
                // can be recycled by FindBestFitLot().
                ;
            }
        }
    }
}

/*------------------------------------------------------------
| MakeRoomInBuf
|-------------------------------------------------------------
|
| PURPOSE: To make sure a buffer has enough space to
|          add a given number of data bytes.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: OK to reallocate buffers owned.
|
|          OK to create a new buffer even if current buffer
|          referenced is not owned.
|
| HISTORY: 04.10.99 TL from 'EnsureByteBufferHasSpace()'.
|          06.12.01 Removed realloc() and applied MemHM 
|                   functions.
------------------------------------------------------------*/
void
MakeRoomInBuf( 
    Buf* B,     // The control record that refers to
                // the data buffer.
                //      
    u32  AddedBytes ) 
                // How many data bytes need to be added
                // to the buffer.
{
    u32 NewSize, DataSize;
    u8* A;
    
    // If there isn't sufficient space for the new data.
    if( RoomInBuf( B ) < AddedBytes )
    {
        // Calculate the size of the data already
        // in the buffer.
        DataSize = SizeOfDataInBuf( B );
            
        // Calculate the new buffer size.
        NewSize = DataSize + AddedBytes;

        // If the current buffer is owned.
        if( B->IsOwned )
        {
            // Allocate a buffer.
            A = (u8*) 
                AllocateMemoryAnyPoolHM( 
                    TheBufPool, 
                    NewSize );
           
            // If there is any data.
            if( DataSize )
            {
                // Copy data to the new buffer.
                CopyBytes( B->Lo, A, DataSize );
            }
            
            // Free the old buffer.
            FreeMemoryHM( B->Lo );
            
            // Connect the 'Buf' record to the new
            // data buffer.
            B->Lo = A;
        }
        
        // Update the buffer high boundary.
        B->HiBuf = B->Lo + NewSize;
        
        // Update the end-of-data marker.
        B->Hi = B->Lo + DataSize;
    }
}   

/*------------------------------------------------------------
| ToMostSuperiorPool
|-------------------------------------------------------------
|
| PURPOSE: To follow the superior links from a pool to the
|          most superior or widest enclosing pool from which
|          the given pool is allocated.
|
| DESCRIPTION: This finds the pool that is allocated directly
| from the operating system.
|
| EXAMPLE: 
|                S = ToMostSuperiorPool( Pool );
|
| HISTORY: 05.30.01 TL   
------------------------------------------------------------*/
                // OUT: The address of the most superior pool.
Lot*            //  
ToMostSuperiorPool( Lot* Pool )
                // Address of an allocation pool or block
                // defined by a Lot record.
{
    // As long as the current pool is valid and refers to
    // a superior pool.
    while( Pool && Pool->Super )
    {
        // Traverse up one level.
        Pool = Pool->Super;
    }
    
    // Return the resulting address.
    return( Pool );
}

