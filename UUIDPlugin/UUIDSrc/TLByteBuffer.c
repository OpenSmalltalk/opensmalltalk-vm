/*------------------------------------------------------------
| TLByteBuffer.c
|-------------------------------------------------------------
|
| PURPOSE: To provide byte buffer functions.
|
| DESCRIPTION: The functions in this file support the use
| of a flexible byte buffer.
|
| Since adding bytes to a buffer can cause reallocation or
| movement of data within a buffer, avoid referring to bytes
| within the buffer except by way of the routines in this
| file.
|
| NOTE: 
|
| HISTORY: 10.12.95 
|          09.10.98 Changed names of 'ByteBuffer' fields;
|                   added 'InsertDataBytes()'.
|          12.11.98 Field name changes.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLFile.h"
#include "TLByteBuffer.h"

/*------------------------------------------------------------
| AppendByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To append the bytes of one byte buffer to another.
|
| DESCRIPTION:
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: O.K. to shift data bytes within buffer.
|          O.K. to reallocate the data field.
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
void 
AppendByteBuffer( ByteBuffer* dst, ByteBuffer* src )
{
    AppendBytesToBuffer( dst, 
                         &src->AtBuffer[src->DataOffset],
                         src->DataSize );
}

/*------------------------------------------------------------
| AppendBytesToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To append a range of bytes to a byte buffer.
|
| DESCRIPTION:
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: O.K. to shift data bytes within buffer.
|          O.K. to reallocate the data field.
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
void 
AppendBytesToBuffer( ByteBuffer* dst, u8* src, u32 count )
{
    u32 AvailBytesAfterData;

    // Make sure there is room for the new bytes.
    EnsureByteBufferHasSpace( dst, count );

    // Make sure there is room following the data bytes
    // within the buffer.
    AvailBytesAfterData = dst->BufferSize - 
                          (dst->DataSize + dst->DataOffset);

    if( AvailBytesAfterData < count )
    {
        // Shift the data bytes toward the beginning of 
        // the buffer to allow for new data bytes.

        ShiftDataToOffset( dst, 
                           dst->DataOffset -
                           ( count - AvailBytesAfterData ) );
    }

    // Copy in the new bytes.
    memcpy( (void*) &dst->AtBuffer[dst->DataOffset +
                               dst->DataSize], 
            (void*) src, count );

    // Update the data count.
    dst->DataSize += count;
}

/*------------------------------------------------------------
| AppendListDataAddressesToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To append the data addresses of a list to a buffer.
|
| DESCRIPTION:
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: O.K. to shift data bytes within buffer.
|          O.K. to reallocate the data field.
|
| HISTORY: 06.23.97 
------------------------------------------------------------*/
void
AppendListDataAddressesToBuffer( ByteBuffer* b, List* L )
{
    u32  ItemCount;
    u32  NewByteCount;
    u8** A;

    // Get the item count.
    ItemCount = L->ItemCount;

    // If there are no items, just return.
    if( ItemCount == 0 )
    {
        return;
    }

    // Calculate the number of new bytes to be added.
    NewByteCount = ItemCount * sizeof(u8*);

    // Make sure there is space for the incoming addresses.
    EnsureByteBufferHasSpace( b, NewByteCount );

    // Move the data to the beginning of the buffer.
    if( b->DataOffset )
    {
        ShiftDataToOffset( b, 0 );
    }

    // Refer to where the data will go.
    A = (u8**) ( b->AtBuffer + b->DataSize );

    // For each item in the list.
    ReferToList( L );

    while( TheItem )
    {
        *A++ = TheDataAddress;

        ToNextItem();
    }

    RevertToList();

    // Update the data count.
    b->DataSize += NewByteCount;
}

/*------------------------------------------------------------
| AtDataByteOffset
|-------------------------------------------------------------
|
| PURPOSE: To return the current address of a data byte at 
|          a given data byte offset in a ByteBuffer.
|
| DESCRIPTION: Returns the absolute address of the byte.
|
| EXAMPLE: 
|
| NOTE: Expected offset is from beginning of data field, not 
|       from the beginning of the buffer. 
|
| ASSUMES: The user of this procedure won't assume that the 
|          current address for the given byte is permanent.
|
| HISTORY: 10.16.95 
------------------------------------------------------------*/
u8*  
AtDataByteOffset( ByteBuffer* b, s32 offset )
{
    return( b->AtBuffer + b->DataOffset + offset );
}

/*------------------------------------------------------------
| CopyByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To copy the data from one buffer to another.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES:
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
void 
CopyByteBuffer( ByteBuffer* dst, ByteBuffer* src )
{
    // Make sure there is room for the new bytes.
    EnsureByteBufferHasSpace( dst, src->DataSize );

    // Copy the bytes.
    memcpy( (void*) dst->AtBuffer, 
            (void*) &src->AtBuffer[ src->DataOffset ], 
            src->DataSize );

    // Update the position of the data in the buffer.
    dst->DataOffset = 0;

    // Copy the count.
    dst->DataSize  = src->DataSize;
}

/*------------------------------------------------------------
| DeleteByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To deallocate a ByteBuffer and all subordinate 
|          data.
|
| DESCRIPTION: Use this procedure to discard ByteBuffers
| produced by 'MakeByteBuffer'.
|
| EXAMPLE:      DeleteByteBuffer( B );
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 09.10.98  
------------------------------------------------------------*/
void
DeleteByteBuffer( ByteBuffer* B )
{
    // Get rid of any data buffer.
    EmptyByteBuffer( B );
    
    // Free the organization record.
    free( B );
}

/*------------------------------------------------------------
| DeleteDataBytes
|-------------------------------------------------------------
|
| PURPOSE: To delete the 'n' data bytes in the buffer at
|          the given address by shifting subsequent data
|          to fill the space deleted.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: Do not change this later to avoid shifting of
|       subsequent data: other code depends on this property. 
|
| ASSUMES: There are at least 'n' data bytes following 'At'
|          in the buffer.
|
| HISTORY: 06.25.97 
------------------------------------------------------------*/
void 
DeleteDataBytes( ByteBuffer* b, u8* At, u32 n )
{
    u8* First;
    u8* AfterLast;
    u8* AfterSection;
    u32 BytesToMove;

    // Refer to the address of the first data byte.
    First = b->AtBuffer + b->DataOffset;
    
    // Refer to the address of the first byte after the
    // last data byte.
    AfterLast = First + b->DataSize;

    // Refer to the address of the first byte after the
    // section being cut.
    AfterSection = At + n;

    // Calculate the number of bytes that follow the deleted
    // section.
    BytesToMove = (u32) ( AfterLast - AfterSection );

    // If there are bytes to move.
    if( BytesToMove )
    {
        // Copy the bytes after the section, over the section.
        CopyBytes( AfterSection, At, BytesToMove );
    }

    // Update the count.
    b->DataSize -= n;
}

/*------------------------------------------------------------
| DeleteFirstDataBytes
|-------------------------------------------------------------
|
| PURPOSE: To delete the first 'n' data bytes in the buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: There are at least 'n' data bytes in the buffer.
|
| HISTORY: 10.16.95 
------------------------------------------------------------*/
void 
DeleteFirstDataBytes( ByteBuffer* b, u32 n )
{
    // Update the position of the data in the buffer.
    b->DataOffset += n;

    // Update the count.
    b->DataSize  -= n;
}

/*------------------------------------------------------------
| DeleteLastDataBytes
|-------------------------------------------------------------
|
| PURPOSE: To delete the last 'n' data bytes in the buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: There are at least 'n' data bytes in the buffer.
|
| HISTORY: 10.16.95 
------------------------------------------------------------*/
void 
DeleteLastDataBytes( ByteBuffer* b, u32 n )
{
    // Update the count.
    b->DataSize -= n;
}

/*------------------------------------------------------------
| DeleteByteBufferData
|-------------------------------------------------------------
|
| PURPOSE: To delete the data bytes from a byte buffer.
|
| DESCRIPTION: Keeps the byte buffer itself.
|
| Also positions the data field to the beginning of of the 
| byte buffer. 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 10.16.95 
------------------------------------------------------------*/
void 
DeleteByteBufferData( ByteBuffer * b )
{
    b->DataOffset  = 0;
    b->DataSize   = 0;
}

/*------------------------------------------------------------
| EmptyByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To empty the data from an existing byte buffer and
|          deallocate the data buffer if any.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: If AtBuffer is non-zero it refers to a 
|          dynamically allocated space that should be freed.
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
void 
EmptyByteBuffer( ByteBuffer* b )
{
    // If there is a data buffer.
    if( b->AtBuffer )
    {
        // Free the data buffer.
        free( b->AtBuffer );

        // Clear the data buffer reference.
        b->AtBuffer = 0;
    }

    // Clear the buffer size.
    b->BufferSize = 0;

    // Reset the location of the data to be the beginning
    // of the buffer.
    b->DataOffset = 0;

    // Clear the count of how many data bytes are in the
    // buffer.
    b->DataSize = 0;
}

/*------------------------------------------------------------
| EnsureByteBufferHasSpace
|-------------------------------------------------------------
|
| PURPOSE: To make sure a byte buffer has enough space to
|          add a given number of data bytes.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES:
|
| HISTORY: 10.12.95 TL from 'HPS_ensure_path_has_space'
|          10.16.95 TL Added additional 50% buffer growth
|                      factor.
|          09.10.98 TL Added 'AllocationQuantum'.
------------------------------------------------------------*/
void
EnsureByteBufferHasSpace( ByteBuffer* b, u32 AddedBytes )
{
    u32 TotalBytesNeeded;
    u32 AvailBytes;
    
    // Calculate the free space available.
    AvailBytes = b->BufferSize - b->DataSize;
    
    // If there isn't sufficient space for the new data.
    if( AvailBytes < AddedBytes )
    {
        // Calculate the new buffer size.
        TotalBytesNeeded = b->DataSize + AddedBytes;

        // Add the number of bytes needed to bring the total
        // to a multiple of the allocation quantum.
        TotalBytesNeeded += 
            TotalBytesNeeded % b->AllocationQuantum;
        
        // Allocate new bigger space and copy the data there.  
        b->AtBuffer = (u8*) 
            realloc( b->AtBuffer, TotalBytesNeeded );
        
        // Update the buffer count. 
        b->BufferSize = TotalBytesNeeded;
    }
}   

/*------------------------------------------------------------
| GetByteAtDataOffset
|-------------------------------------------------------------
|
| PURPOSE: To get byte at the given data byte offset.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: Offset is from beginning of data field, not from
| beginning of the buffer. 
|
| ASSUMES:
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
s32  
GetByteAtDataOffset( ByteBuffer* b, s32 offset )
{
    u32 ByteInU32;

    // Get the byte in a 32-bit field without sign extending.
    ByteInU32 = (u32) b->AtBuffer[ b->DataOffset + offset ];

    return( (s32) ByteInU32 );
}

/*------------------------------------------------------------
| InsertDataBytes
|-------------------------------------------------------------
|
| PURPOSE: To insert data bytes into a byte buffer relative
|          to the beginning of the data.
|
| DESCRIPTION: This procedure allows the insertion of any 
| amount data into any existing data in a byte buffer.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: O.K. to shift data bytes within buffer.
|          O.K. to reallocate the data field.
|
| HISTORY: 09.10.98 From 'AppendBytesToBuffer()'.
------------------------------------------------------------*/
void 
InsertDataBytes( 
    ByteBuffer* B,            // The byte buffer where the
                              // data is to be inserted.
                              //
    u32         InsertOffset, // 0 if insert before the first
                              // data byte, 1 if insert before
                              // the 2nd data byte, etc.
                              //
    u8*         From,         // The source buffer where the
                              // data bytes will come from.
                              //
    u32         ByteCount )   // How many data bytes are to be
                              // inserted.
{
    u32 AvailBytesAfterData;
    u8* InsertHere;
    u32 TailByteCount;
    
    // Make sure there is room for the new bytes.
    EnsureByteBufferHasSpace( B, ByteCount );

    // Calculate how many bytes follow the data bytes
    // within the buffer.
    AvailBytesAfterData = B->BufferSize - 
                          ( B->DataSize + B->DataOffset );

    // If there isn't enough space following the data for the
    // new data.
    if( AvailBytesAfterData < ByteCount )
    {
        // Shift the data bytes to the beginning of 
        // the buffer to allow for new data bytes.
        ShiftDataToOffset( B, 0 );
    }

    // Calculate the byte address of the insertion point.
    InsertHere = B->AtBuffer + B->DataOffset + InsertOffset;
    
    // Calculate the size of the tail end of the data section
    // that needs to be moved to make room.
    TailByteCount = B->DataSize - InsertOffset;
    
    // If there is a tail to be moved.
    if( TailByteCount )
    {
        // Shift the tail higher in memory to make room.
        CopyBytes( InsertHere,             // From
                   InsertHere + ByteCount, // To
                   TailByteCount );        // How many bytes to move.
    }
                                
    // Copy in the new bytes.
    CopyBytes( From, InsertHere, ByteCount );
    
    // Update the data count.
    B->DataSize += ByteCount;
}

/*------------------------------------------------------------
| LoadFileToByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To load a file into a byte buffer.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.01.96 from 'LoadFile'.
|          08.25.97 changed 'GetFileSize' to 'GetFileSize2'.
------------------------------------------------------------*/
void
LoadFileToByteBuffer( s8* Path, ByteBuffer* b )
{
    FILE*   F;
    u32     FileSize;
    u32     BytesRead;
    
    // Empty the byte buffer.
    EmptyByteBuffer( b );
    
    // Make sure the file exists.
    if( IsFileExisting( Path ) == 0 ) 
    {
        // File doesn't exist.
        return;
    }
    
    F = OpenFileTL( Path, ReadAccess );
    
    FileSize = GetFileSize2( F );
 
    // Allocate space in the buffer for the file.
    EnsureByteBufferHasSpace( b, FileSize );
    
    // Read the file to the buffer.
    BytesRead = (u32)
        ReadBytes( F, b->AtBuffer, FileSize );
    
    // Make sure the exact file size was read.
    if( BytesRead != FileSize )
    {
//      Note( " FileSize: %d, BytesRead: %d\n",
//              FileSize, BytesRead );
//      while( !Button() );
        Debugger();
    }
    
    // Set the data byte count.
    b->DataSize = BytesRead;
    
    // Close the file.
    CloseFile(F);
}

/*------------------------------------------------------------
| MakeByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To allocate a new 'ByteBuffer' record.
|
| DESCRIPTION: Expects the minimum allocation unit that the 
| buffer can grow by in bytes.  Defers allocation of the data
| buffer until data is put into the buffer.
|
| EXAMPLE: B = MakeByteBuffer( 16 );
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 09.10.98  
------------------------------------------------------------*/
ByteBuffer* 
MakeByteBuffer( u32 AllocationQuantum ) // Number of bytes,
                                        // must be greater
                                        // than zero.
{
    ByteBuffer* B;
    
    // Allocate a new byte buffer record.
    B = (ByteBuffer*) malloc( sizeof( ByteBuffer ) );
    
    // Zero the record.
    FillBytes( (u8*) B, sizeof( ByteBuffer ), 0 ) ;
    
    // Record the allocation quantum.
    B->AllocationQuantum = AllocationQuantum;
    
    // Return the record address.
    return( B );
}

/*------------------------------------------------------------
| PrependBytesToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To prepend a range of bytes to a byte buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: O.K. to shift data bytes within buffer.
|          O.K. to reallocate the data field.
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
void 
PrependBytesToBuffer( ByteBuffer* dst, u8 * src, u32 count )
{
    u32 AvailBytesBeforeData;
    u32 ShiftCount;

    // Make sure there is room for the new bytes.
    EnsureByteBufferHasSpace( dst, count );

    // Make sure there is room prior to the data bytes
    // within the buffer.
    AvailBytesBeforeData = dst->DataOffset;

    if( AvailBytesBeforeData < count )
    {
        // Shift the data bytes toward the end of 
        // the buffer to allow for new data bytes.

        ShiftCount = count - AvailBytesBeforeData;

        ShiftDataToOffset( dst, 
                           dst->DataOffset + ShiftCount );
    }

    // Copy in the new bytes.
    memcpy( (void*) &dst->AtBuffer[dst->DataOffset - count], 
            (void*) src, count );

    // Update the data count.
    dst->DataSize += count;

}

/*------------------------------------------------------------
| PullFirstDataByte
|-------------------------------------------------------------
|
| PURPOSE: To pull the first data byte from the buffer.
|
| DESCRIPTION: Returns the byte or '-1' if there is no data
|              in the buffer.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES:
|
| HISTORY: 10.17.95 
------------------------------------------------------------*/
s32 
PullFirstDataByte( ByteBuffer* b )
{
    u32 ByteInU32;

    // If there is no data, return -1
    if( ! b->DataSize )
    {
        return( -1 );
    }

    // Get the byte in a 32-bit field without sign extending.
    ByteInU32 = (u32) b->AtBuffer[ b->DataOffset ];

    // Update the position of the data in the buffer.
    b->DataOffset++;

    // Update the count.
    b->DataSize--;

    return( (s32) ByteInU32 );
}

/*------------------------------------------------------------
| PullLastDataByte
|-------------------------------------------------------------
|
| PURPOSE: To pull the last data byte from the buffer.
|
| DESCRIPTION: Returns the byte or '-1' if there is no data
|              in the buffer.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES:
|
| HISTORY: 10.17.95 
------------------------------------------------------------*/
s32 
PullLastDataByte( ByteBuffer* b )
{
    u32 ByteInU32;

    // If there is no data, return -1
    if( ! b->DataSize )
    {
        return( -1 );
    }

    // Get the byte in a 32-bit field without sign extending.
    ByteInU32 = (u32) b->AtBuffer[ b->DataOffset + 
                               b->DataSize - 1 ];

    // Update the count.
    b->DataSize--;

    return( (s32) ByteInU32 );
}

/*------------------------------------------------------------
| PutDataByteAtOffset
|-------------------------------------------------------------
|
| PURPOSE: To put the data byte at the given offset with
|          respect to the beginning of the data in the buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: The byte is in the buffer.
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
void  
PutDataByteAtOffset( ByteBuffer* b, s32 offset, u8 byte )
{
    b->AtBuffer[ b->DataOffset + offset ] = byte;
}

/*------------------------------------------------------------
| ShiftDataToOffset
|-------------------------------------------------------------
|
| PURPOSE: To shift the data bytes within a ByteBuffer to
|          a given offset.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: Assumes the new offset is valid given the number
|          of data bytes.
|
| HISTORY: 10.12.95 
------------------------------------------------------------*/
void
ShiftDataToOffset( ByteBuffer* b, u32 NewOffset )
{
    // If the location of the data differs from the new
    // offset.
    if( b->DataOffset != NewOffset )
    {
        // Shift the data bytes to the beginning of the
        // buffer to allow for new data bytes.

        CopyBytes( &b->AtBuffer[b->DataOffset], // From
                   &b->AtBuffer[NewOffset],     // To 
                   b->DataSize  );              // Count

        // Update the offset of the data in the buffer.
        b->DataOffset = NewOffset;
    }
}
