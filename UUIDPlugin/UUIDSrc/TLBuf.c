/*------------------------------------------------------------
| TLBuf.c
|-------------------------------------------------------------
|
| PURPOSE: To provide simple, fast memory buffer functions.
|
| DESCRIPTION: These are functions common to all buffers no
| matter if they are statically or dynamically allocated.
|
| The emphasis of the functions in this file is on speed so 
| there is no support for automatic bounds checking.
|
| NOTE: 
|
| HISTORY: 12.11.98 From 'TLByteBuffer.c'.
|          06.12.01 Adapted for drivers.
|          06.14.01 Moved allocation functions to TLMemHM.c.
------------------------------------------------------------*/

#include "TLTarget.h" 

#ifndef FOR_DRIVER

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#endif // FOR_DRIVER

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"

/*------------------------------------------------------------
| AtDataInBuf
|-------------------------------------------------------------
|
| PURPOSE: To return the address of a data byte in a buffer.
|
| DESCRIPTION: Returns the absolute address of the byte.
|
| EXAMPLE: 
|
| NOTE: Expected offset is from the beginning of the buffer. 
|
| ASSUMES: 
|
| HISTORY: 12.13.98
------------------------------------------------------------*/
u8*  
AtDataInBuf( Buf* B, s32 Offset )
{
    return( B->Lo + Offset );
}

/*------------------------------------------------------------
| CopyBuf
|-------------------------------------------------------------
|
| PURPOSE: To copy the contents of one buffer to another.
|
| DESCRIPTION: On return, all of the data in the source
| buffer will be copied to the target buffer where it will
| become the entire contents of the target buffer.
|
| EXAMPLE:      
|
| NOTE: 
|
| ASSUMES: Enough room in the target buffer for the incoming
|          data: no automatic reallocation of buffer space.
|          Use 'MakeRoomInBuf()' to ensure a large
|          enough target buffer.
|
| HISTORY: 04.10.99
------------------------------------------------------------*/
                 // OUT: The number of data bytes copied to 
u32              // the target buffer.
CopyBuf( 
    Buf* Source, // IN: Where the source bytes are.
                 //
    Buf* Target )// IN: Where the target bytes go.
                 //
                 // OUT: 'Hi' is updated to mark the
                 // end of the incoming data.
{
    u32 DataByteCount;
    
    // Calculate the number of data bytes in the source 
    // buffer.
    DataByteCount = SizeOfDataInBuf( Source );
    
    // If there are any source bytes.
    if( DataByteCount )
    {
        // Copy the bytes.
        CopyBytes( Source->Lo, Target->Lo, (s32) DataByteCount );
    }

    // Set the number of bytes in the target buffer.
    Target->Hi = Target->Lo + DataByteCount;

    // Return the number of data bytes.
    return( DataByteCount );
}

/*------------------------------------------------------------
| DeleteAllMatchingDataInBuf
|-------------------------------------------------------------
|
| PURPOSE: To delete every occurance of a byte pattern in
|          a buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
|           DeleteAllMatchingDataInBuf( 
|               B,              // The buffer holding the data.
|                               //
|              (u8*) "abc",     // The location of the byte 
|                               // pattern to match.
|                               //
|              3 ); // How many bytes are in the pattern.
|
| NOTE:  
|
| ASSUMES:
|
| HISTORY: 03.15.99
------------------------------------------------------------*/
void 
DeleteAllMatchingDataInBuf( 
    Buf* B,     // The buffer holding the data.
                //
    u8*  S,     // The location of the byte pattern to 
                // match.
                //
    u32  Count )// How many bytes are in the pattern.
{
    u8* To;
    u8* From;
    u8* Hi;
    u32 i, Last;
    
    // If the pattern is empty.
    if( Count == 0 )
    {
        // Just return.
        return;
    }
    
    // Refer to where the first data byte will go in the 
    // buffer.
    To = B->Lo;
    
    // Refer to where the first data byte will come from
    // in the buffer.
    From = To;
    
    // Refer to the byte after the last data byte.
    Hi = B->Hi;
    
    // Calculate the index of the last byte in the pattern.
    Last = Count - 1;
    
    // Until the entire buffer has been scanned.
Next:

    while( From < Hi )
    {
        // If the last byte of the pattern doesn't match
        // at the offset.
        if( From[Last] != S[Last] )
        {
            // Copy one byte from the 'From' pointer to
            // the 'To' pointer, advancing both.
            *To++ = *From++;
            
            // Go test match at the next 'From' position.
            goto Next;
        }
        
        // Until a mismatch or end of the pattern.
        for( i = 0; i < Last; i++ )
        {
            // If there is a mismatch.
            if( From[i] != S[i] )
            {
                // Copy one byte from the 'From' pointer to
                // the 'To' pointer, advancing both.
                *To++ = *From++;
                
                // Go test match at the next 'From' position.
                goto Next;
            }
        }
        
        // Just skip the 'From' pointer past the
        // matching string.
        From += Count;
    }
    
    // Set the new end of data.
    B->Hi = To;
}

/*------------------------------------------------------------
| DeleteDataInBuf
|-------------------------------------------------------------
|
| PURPOSE: To delete the 'n' data bytes in the buffer at
|          the given offset by shifting subsequent data
|          to fill the space deleted.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: There are at least 'n' data bytes at 'DeleteOffset'
|          in the buffer.
|
| HISTORY: 12.13.98
------------------------------------------------------------*/
void 
DeleteDataInBuf( 
    Buf* B,             // The buffer holding the data.
                        //
    u32  DeleteOffset,  // The byte offset from the beginning
                        // of the data buffer where data will
                        // be deleted.
                        // 
    u32  n )            // How many bytes to delete.
{
    u32 BytesAfter;
    
    // Calculate the number of bytes already in the buffer
    // that follow the part to be deleted.
    BytesAfter = (u32)
        ( B->Hi - ( B->Lo + DeleteOffset + n ) );
    
    // If there is any data following the deleted segment.
    if( BytesAfter )
    {
        // Shift the data bytes to the new offset.
        CopyBytes( &B->Lo[ DeleteOffset + n ], // From
                   &B->Lo[ DeleteOffset ],     // To 
                   BytesAfter );               // Count
    }
    
    // Move the end-of-data marker to delete 'n' bytes.
    B->Hi -= n;
}

/*------------------------------------------------------------
| DeleteFirstDataInBuf
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
| HISTORY: 12.13.98
------------------------------------------------------------*/
void 
DeleteFirstDataInBuf( Buf* B, u32 n )
{
    u32 BytesAfterN;
    
    // Calculate the number of bytes already in the buffer
    // that follow the part to be deleted.
    BytesAfterN = SizeOfDataInBuf( B ) - n;
    
    // Shift the data bytes to the new offset.
    CopyBytes( &B->Lo[n],     // From
               B->Lo,         // To 
               BytesAfterN ); // Count

    // Move the end-of-data marker to delete 'n' bytes.
    B->Hi -= n;
}

/*------------------------------------------------------------
| DeleteLastDataInBuf
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
DeleteLastDataInBuf( Buf* B, u32 n )
{
    // Move the end-of-data marker to delete 'n' bytes.
    B->Hi -= n;
}

/*------------------------------------------------------------
| EmptyBuf
|-------------------------------------------------------------
|
| PURPOSE: To empty the data from the data buffer owned by a 
|          'Buf' but leave the buffer allocated.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 12.11.98
------------------------------------------------------------*/
void 
EmptyBuf( Buf* B )
{
    // Set the end of data marker to the beginning of the
    // data buffer.
    B->Hi = B->Lo;
}

/*------------------------------------------------------------
| GetByteInBuf
|-------------------------------------------------------------
|
| PURPOSE: To get a byte at the given offset in a data buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: The offset is in the data portion of the buffer.
|
| HISTORY: 12.13.95 
------------------------------------------------------------*/
u32  
GetByteInBuf( Buf* B, s32 ByteOffset )
{
    return( (u32) ( B->Lo[ ByteOffset ] ) );
}

/*------------------------------------------------------------
| InsertDataFirstInBuf
|-------------------------------------------------------------
|
| PURPOSE: To prepend data bytes to the data buffer of a Buf.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.11.98
------------------------------------------------------------*/
void 
InsertDataFirstInBuf( Buf* B, u8* Data, u32 DataSize )
{
    u32 BytesInBuf;
    
    // Calculate the number of bytes already in the buffer.
    BytesInBuf = SizeOfDataInBuf( B );
    
    // If there are any bytes in the buffer.
    if( BytesInBuf )
    {
        // Shift the data bytes to the new offset.
        CopyBytes( B->Lo,            // From
                   &B->Lo[DataSize], // To 
                   BytesInBuf );     // Count
    }
    
    // Copy in the new bytes.
    CopyBytes( Data,       // From
               B->Lo,      // To
               DataSize ); // Count
     
    // Update the data end marker.
    B->Hi += DataSize;
}

/*------------------------------------------------------------
| InsertDataInBuf
|-------------------------------------------------------------
|
| PURPOSE: To insert data into a buffer relative to the 
|          beginning of the buffer.
|
| DESCRIPTION: This procedure inserts of a given number of
| bytes into existing data in a byte buffer.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: The buffer has room for the new data.
|
|          O.K. to shift data bytes within buffer.
|
| HISTORY: 09.10.98 From 'InsertDataLastInBuf()'.
|          12.13.98 Revised.
------------------------------------------------------------*/
void 
InsertDataInBuf( 
    Buf*    B,            // The reference to the buffer 
                          // where the data is to be inserted.
                          //
    u32     InsertOffset, // 0 if insert before the first
                          // data byte, 1 if insert before
                          // the 2nd data byte, etc.
                          //
    u8*     From,         // The source buffer where the
                          // data bytes will come from.
                          //
    u32     ByteCount )   // How many data bytes are to be
                          // inserted.
{
    u8* InsertHere;
    u32 TailByteCount;
    
    // Calculate the byte address of the insertion point.
    InsertHere = B->Lo + InsertOffset;
    
    // Calculate the size of the tail end of the data 
    // section that needs to be moved to make room.
    TailByteCount = (u32) ( B->Hi - InsertHere );
    
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
    
    // Update the end-of-data marker.
    B->Hi += ByteCount;
}

/*------------------------------------------------------------
| InsertDataLastInBuf
|-------------------------------------------------------------
|
| PURPOSE: To append data bytes to the data held in a 'Buf'.
|
| DESCRIPTION: Simply copies the data to the buffer as 
| quickly as possible without any bounds checking.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Enough room exists in the buffer for the new data.
|
| HISTORY: 12.11.98 
------------------------------------------------------------*/
void 
InsertDataLastInBuf( Buf* B, u8* Data, u32 DataSize )
{
    // Copy in the new bytes.
    CopyBytes( Data,        // From
               B->Hi,   // To
               DataSize );  // Count

    // Update the end of data marker.
    B->Hi += DataSize;
}

/*------------------------------------------------------------
| PutByteInBuf
|-------------------------------------------------------------
|
| PURPOSE: To put a byte at the given offset in a data buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: The offset is in the data portion of the buffer.
|
| HISTORY: 12.13.95 
------------------------------------------------------------*/
void  
PutByteInBuf( Buf* B, s32 ByteOffset, u8 b )
{
    B->Lo[ ByteOffset ] = b;
}

