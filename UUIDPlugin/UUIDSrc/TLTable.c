/*------------------------------------------------------------
| TLTable.c
|-------------------------------------------------------------
|
| PURPOSE: To provide general-purpose data table functions.
|
| DESCRIPTION: This is a facility for working with tables of 
| fixed-length data records that are either ordered or 
| unordered.
|
| A data record can be as little as one byte to as big as 
| a gigabyte.
|
| In an ordered table, records are maintained in the order
| defined by a given procedure that compares two records.
|
| See 'TLTable.h' for more.
|
| HISTORY: 09.29.98 TL
|          10.22.98 Replaced calls to 'CopyBytes' with 
|                   calls to 'memmove' to make more portable.
|                   Revalidated.
|          12.31.98 Moved testing procedures to 
|                   'TLTableTest.c'.
------------------------------------------------------------*/

#include "TLTarget.h"  

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "TLTypes.h"

#include "TLTable.h"

/*------------------------------------------------------------
| CompareKeyToRecord
|-------------------------------------------------------------
|
| PURPOSE: To compare a key value to the key value of a data 
|          record in a table.
|
| DESCRIPTION: This is a generic comparison operation that 
| applies the specific comparison function of a table to 
| compare a key to the key of a record in the table.
|
|   Returns:            0 if Key = KeyOf(R).
|         positive number if Key > KeyOf(R).
|         negative number if Key < KeyOf(R).
|
| EXAMPLE: 
|
|            C = CompareKeyToRecord( "ABC", R );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 09.30.98
------------------------------------------------------------*/
s32
CompareKeyToRecord( 
    u8* Key,  // Address of the search key.
              //
    u8* D )   // Reference to a data record in a table,
              // the address of a 'ThatRecord' structure.
{
    ThatRecord* R;
    Table*      T;
    u8*         KeyOfR;
    s32         Result;
    
    // Refer to D as a reference to a record.
    R = (ThatRecord*) D;
    
    // Refer to the table of the record.
    T = R->TheTable;
    
    // Refer to the key field of record R.
    KeyOfR = R->TheRecord + T->KeyOffset;
    
    // Call the table-specific comparison function.
    Result = (*T->CompareKeyProcedure)( Key, KeyOfR );

    // Return the result.
    return( Result );
}

/*------------------------------------------------------------
| CompareKeyToRecordBlock
|-------------------------------------------------------------
|
| PURPOSE: To compare a search key value to the range of keys
|          spanned by a given block of records.
|
| DESCRIPTION: This is a comparison function used to locate 
| the block where a desired record is or could be held.
| 
| This is a standard comparison operation.
|
| Returns: 0 if Key is, or would be, contained in block B.
|          positive number if Key > B.
|          negative number if Key < B.
|
| EXAMPLE:  
|
|     Result = 
|       CompareKeyToRecordBlock( 
|           (u8*) "ABC", (u8*) &MyRecordBlock );
|
| NOTE: Use this function with
|       'FindPlaceInOrderedBlockAddressTableTable'.
|
| ASSUMES: The records in the block are ordered according to
|          the comparison procedure of the table.
|
| HISTORY:  09.30.98 TL From 'CompareXAddressToRecordBlock'.
------------------------------------------------------------*/
s32
CompareKeyToRecordBlock( 
    u8* Key,  // Address of the search key.
    u8* B )   // Address of a 'RecordBlock' record.
{
    RecordBlock*    R;
    ThatRecord      Lo;
    ThatRecord      Hi;
    s32             Result;
    
    // Refer to B as a block address.
    R = (RecordBlock*) B;
    
    // Locate the first record in the block.
    ToFirstRecordInBlock( R, &Lo );
    
    // Compare the given key to the first record.
    Result = CompareKeyToRecord( Key, (u8*) &Lo );
    
    // If the key doesn't follow the low record.
    if( Result <= 0 )
    {
        // Then the comparison is determined by Lo.
        //
        // Just return.
        return( Result );
    }
    
    // Locate the last record in the block.
    ToLastRecordInBlock( R, &Hi );
    
    // Compare the given key to the last record.
    Result = CompareKeyToRecord( Key, (u8*) &Hi );
    
    // If the key doesn't follow the high record.
    if( Result <= 0 )
    {
        // Then the key matches the block.
        return( 0 );
    }
    else // The key follows the block.
    {
        // Return the result, a positive number.
        return( Result );
    }
}

/*------------------------------------------------------------
| CopyRecord
|-------------------------------------------------------------
|
| PURPOSE: To copy a record from one place to another.
|
| DESCRIPTION: Copies the record itself, not the references
| to the record.
|
| EXAMPLE:     CopyRecord( From, To );
|
| NOTE:  
|
| ASSUMES: The records are the same size.
|
| HISTORY: 09.17.98 TL
------------------------------------------------------------*/
void
CopyRecord( ThatRecord* From, ThatRecord* To )
{
    // Copy the bytes that constitute the data record.
    memmove( To->TheRecord,           // To
             From->TheRecord,         // From
             (u32) From->BytesPerRecord );  // ByteCount
}

/*------------------------------------------------------------
| DeleteIntermediateRecords
|-------------------------------------------------------------
|
| PURPOSE: To delete one or more records between two given
|          records in a table, but leave the given endpoint
|          records.
|
| DESCRIPTION: Scans from the given start record until the 
| given ending record is found, counting the intermediate
| records.  Then the intermediate records are deleted and
| the end record reference is updated to correct for any
| movement due to record deletion -- both record references
| are valid on exit.
|
| Returns a count of how many records were deleted.
|
| EXAMPLE:     
|          n = DeleteIntermediateRecords( &A, &B );
|
| NOTE:  
|
| ASSUMES: The given records exist in the table.
|
|          Record 'B' follows or is refers to record 'A' in 
|          the table.
|
|          Other record pointers currently referring to the 
|          records in the table do not depend on the table 
|          being unchanged.
|
| HISTORY: 11.18.98 TL
------------------------------------------------------------*/
                        // Returns the number of records
u32                     // deleted.
DeleteIntermediateRecords( 
    ThatRecord* A,      // The first record BEFORE the
                        // records to be deleted.
                        //
    ThatRecord* B )     // The first record AFTER the
                        // records to be deleted.
{
    ThatRecord  X;
    ThatRecord  AfterA;
    u32         IntermediateCount;
    u8*         RecordAtB;
    
    // If 'A' and 'B' refer to the same record.
    if( A->TheRecord == B->TheRecord )
    {
        // No intermediate records.
        return( 0 );
    }
        
    // Start searching at the 'A' record.
    X = *A;
    
    // Advance 'X' to the next record.
    ToNextRecord( &X );
    
    // Refer to the record right after 'A' in case deletion
    // is needed later.
    AfterA = X;
    
    // Get the address of the 'B' record for speed.
    RecordAtB = B->TheRecord;
    
    // If the record after 'A' and 'B' refer to the 
    // same record.
    if( AfterA.TheRecord == RecordAtB )
    {
        // No intermediate records.
        return( 0 );
    }

    // Start with no known intermediate records. 
    IntermediateCount = 0;
    
    // Count the intermediate records.
    do
    {
        // Advance 'X' to the next record.
        ToNextRecord( &X );
        
        // Increment the intermediate record counter.
        IntermediateCount++;
        
    } // Repeat if record 'B' has not been found.
    while( X.TheRecord != RecordAtB );
    
    // Delete the records found, there will be at least one.
    DeleteRecords( &AfterA, IntermediateCount );
    
    // Restore the reference to record 'B'.
    *B = *A;
    ToNextRecord( B );
    
    // Return the number of records deleted.
    return( IntermediateCount );
}
    
/*------------------------------------------------------------
| DeleteRecords
|-------------------------------------------------------------
|
| PURPOSE: To delete one or more records from a table.
|
| DESCRIPTION: Deletes a given number of records starting with
| and including the record specified in 'R'.  
|
| If the deletion of records results in empty record blocks,
| then those blocks are deleted as well, with the following
| exception: the last block in the table will never be deleted.
|
| The values in record reference 'R' are not changed but may
| not be valid following the execution of this routine due to
| changes to the table.
|
| EXAMPLE:     DeleteRecords( R, 1 );
|
| NOTE:  
|
| ASSUMES: The given records exist in the table to be deleted.
|
|          Other record pointers currently referring to the 
|          records in the table do not depend on the table 
|          being unchanged.
|
| HISTORY: 10.01.98 TL From 'DeleteExtentRecord()'.
|          10.04.98 Added block deletion.
|          10.12.98 Bypassed general list functions for speed.
|          10.14.98 Added multiple record capability.
|          12.01.98 Added 'IsLookasideEmpty'.
------------------------------------------------------------*/
void
DeleteRecords( ThatRecord* R, u32 HowManyRecordsToDelete )
{
    RecordBlock* B;
    RecordBlock* Prior;
    RecordBlock* Next;
    Table*       T;
    u8*          AtTheRecord;
    u8*          AtEndOfData;
    u8*          AfterTheDeletedRecords;
    u32          BytesPerRecord;
    u32          BytesToBeDeleted;
    u32          BytesToDeleteThisPass;
    u32          BytesFromTheRecordToEndOfData;
    u32          RecordsDeletedThisPass;
    
    // Refer to table that holds the block.
    T = R->TheTable;
    
    // Get the size of record in this table.
    BytesPerRecord = R->BytesPerRecord;

    // Calculate the total number of bytes remaining
    // to be deleted.
    BytesToBeDeleted = HowManyRecordsToDelete * BytesPerRecord;
    
    // Refer to the block containing the record.
    B = R->TheBlock;
    
    // Get the address of the record.
    AtTheRecord = R->TheRecord;
    
    // Until all the records have been deleted.
    while( HowManyRecordsToDelete )
    {
        // Get the address of the end of the data in
        // the block.
        AtEndOfData = B->EndOfData;
        
        // Calculate the number of bytes from the record
        // to the end of the data in the record block.
        //
        // FirstRecord
        //    |---------[TheRecord]-----------|<EndOfData
        //              |<---This Quantity--->|
        //
        BytesFromTheRecordToEndOfData = (u32)
            ( AtEndOfData - AtTheRecord );
        
        // Calculate the address of the first byte
        // following the deleted records.
        //
        //    FirstRecord
        //    |---------[x][x][x]------|<EndOfData
        //               ^       ^
        //               R       |
        //                       AfterTheRecords
        AfterTheDeletedRecords = 
            AtTheRecord + 
            ( BytesPerRecord * HowManyRecordsToDelete );
        
        // If the deleted records span a block boundary.
        if( AfterTheDeletedRecords > AtEndOfData )
        {
            // Reduce the number to delete this pass
            // to the number that can be deleted in this block.
            BytesToDeleteThisPass =
                BytesFromTheRecordToEndOfData;
                
            // Limit the position of the end of the deleted
            // bytes to the end of the data in the block.
            AfterTheDeletedRecords = AtEndOfData;
        }
        else // Enough bytes remain in the current block
             // to satisfy all of the remaining bytes
             // to be deleted.
        {   
            // Schedule all of the remainder for deletion.
            BytesToDeleteThisPass = BytesToBeDeleted;
        }
        
        // If there are records following the deleted ones
        // in the current block.
        if( AfterTheDeletedRecords < AtEndOfData )
        {
            // Copy the following records to take up the slack
            // space.
            //
            // BEFORE:     AtTheRecord      AtEndOfData
            //              :               :
            //    |---------[x][x][x][o][o]|
            //                       ^
            //                       :
            //                       AfterTheDeletedRecords
            //
            //
            // AFTER: AtTheRecord          AtEndOfData (Invalid)
            //              :              :
            //    |---------[o][o]--------|
            //                       ^
            //                       :
            //                       AfterTheDeletedRecords
            //
            //
            memmove( AtTheRecord,             // To
                     AfterTheDeletedRecords,  // From
                     (u32)
                     ( AtEndOfData - AfterTheDeletedRecords ) ); // ByteCount
        }
        
        // Update the end of the records in the block.
        B->EndOfData -= BytesToDeleteThisPass;

        // Calculate the number of records just deleted.
        RecordsDeletedThisPass = 
            BytesToDeleteThisPass / BytesPerRecord;
        
        // Reduce the total number of records in the table.
        T->RecordCount -= RecordsDeletedThisPass;
        
        // Reduce the total number of records in the block.
        B->RecordCount -= RecordsDeletedThisPass;
        
        // Reduce the number of records that remain to be deleted.
        HowManyRecordsToDelete -= RecordsDeletedThisPass;
        
        // Reduce the number of bytes that remain to be deleted.
        BytesToBeDeleted -= BytesToDeleteThisPass;

        // If the block is now empty but there are other blocks
        // in the table.
        if( B->RecordCount == 0 && T->BlockCount > 1 )
        {
            // Extract the block from the table list.
            
            // Refer to the block prior to the current one, if any.
            Prior = B->Prior;
            
            // Refer to the next block, if any.
            Next  = B->Next;
            
            // Update forward link if there is one.
            if( Prior )
            {
                Prior->Next = Next;
            }
            
            // Update backward link if there is one.
            if( Next )
            {
                Next->Prior = Prior;
            }
            
            // If the block is first.
            if( T->FirstBlock == B )
            {
                // Revise the first block link.
                T->FirstBlock = Next; // May be zero.
            }
            
            // If the block is last.
            if( T->LastBlock == B )
            {
                // Revise the last block link.
                T->LastBlock = Prior;  // May be zero.
            }
            
            // Free the extracted record block itself.
            free( B );
            
            // Account for the deleted block.
            T->BlockCount -= 1;
            
            // Mark the block address table as needing update.
            T->IsBlockAddressTableCurrent = 0;
        }
        else // Current block isn't empty.
        {
            // Refer to the next block.
            Next = B->Next;
        }

        // If more remains to be done.
        if( HowManyRecordsToDelete )
        {
            // Advance to the first record of the next block.
            B = Next;
            AtTheRecord = Next->FirstRecord;
        }
    }
    
    // Mark the lookaside buffer as empty because the record 
    // structure of the table has changed.
    T->IsLookasideEmpty = 1;
}       

/*------------------------------------------------------------
| DeleteTable
|-------------------------------------------------------------
|
| PURPOSE: To free all resources used a data table.
|
| DESCRIPTION: Use this procedure to clean up tables created 
|              by 'MakeTable()'.
|
| EXAMPLE:     DeleteTable( T );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 09.30.98 TL From 'DeleteExtentTable()'.
|          10.12.98 Revised to directly manage block list.
------------------------------------------------------------*/
void
DeleteTable( Table* T )
{
    RecordBlock*    B;
    RecordBlock*    Next;
    
    // Refer to the first block in the list.
    B = T->FirstBlock;
    
    // For each block.
    while( B )
    {
        // Refer to the next block.
        Next = B->Next;
        
        // Free the current block.
        free( B );
        
        // Make the next block the current one.
        B = Next;
    }
    
    // If there's a block address table.
    if( T->BlockAddressTable )
    {
        // Free it.
        DeleteTable( T->BlockAddressTable );
    }
    
    // Free the table record itself.
    free( T );
}

/*------------------------------------------------------------
| DisplaceSomeKeys
|-------------------------------------------------------------
|
| PURPOSE: To displace the key field values of selected keys.
|
| DESCRIPTION: Scans through a table looking for records with
| key field values that fall between the given 'Lo' and 'Hi'
| values, adding the displacement to those keys found.
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: Records have a key field four bytes long holding
|          an unsigned 32-bit number.
|
| HISTORY: 11.14.98
------------------------------------------------------------*/
void
DisplaceSomeKeys( 
    Table*  T,          // The table containing the records.
                        //
    u32     Lo,         // The lowest key value to be selected.
                        //
    u32     Hi,         // The key value after the highest
                        // key to be selected.
                        //
    s32     Displacement )
                        // The number to be added to the 
                        // selected key values, a signed
                        // number.
{
    ThatRecord  R;
    u32         Key, KeyOffset;
    u32*        AtKeyField;
    
    // Get the key field offset.
    KeyOffset = T->KeyOffset;
    
    // Start with the first record in the table.
    ToFirstRecord( T, &R );
            
    // Until all of the records have been reviewed.
    while( R.TheRecord )
    {
        // Refer to the key field.
        AtKeyField = (u32*) (R.TheRecord + KeyOffset);
        
        // Get the key.
        Key = *AtKeyField;
        
        // If this is one of the selected keys.
        if( Key >= Lo && Key < Hi )
        {
            // If the displacement is positive.
            if( Displacement > 0 )
            {
                // Add the displacement to the key.
                Key += (u32) Displacement;
            }
            else // Displacement is negative.
            {
                // Subtract the negative of the displacement.
                Key -= (u32) (-Displacement);
            }
            
            // Put the new key value back in the record.
            *AtKeyField = Key;
        }

        // Advance to the next record.
        ToNextRecord( &R );
    }
}

/*------------------------------------------------------------
| DumpTable
|-------------------------------------------------------------
|
| PURPOSE: To output a description of a record table to the 
|          log for debugging.
|
| DESCRIPTION: Outputs the table to standard output with all
| records on the same line separated by commas between 
| records, like this:
|
|      AAA, BC, CCD
|
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: The data table holds only printable ASCII chars:
|          this isn't a limitation on data table generally,
|          just on this particular procedure.
|
| HISTORY: 10.01.98 TL From 'DumpExtentTable()'.
|          10.15.98 Revised to put entire table on one line.
------------------------------------------------------------*/
void
DumpTable( Table* T )
{
    ThatRecord   n;
    RecordBlock* LastBlock;
    s32          i;
    s8           LineBuffer[132];
    
    // Refer to the first record in the table.
    ToFirstRecord( T, &n );
    
    // Clear the block change detector.
    LastBlock = 0;
    
    // Initialize the record index counter.
    i = 0;
    
    // For every record.
    while( n.TheRecord )
    {
        // If the current block isn't the same as the last
        // one.
        if( n.TheBlock != LastBlock )
        {
            // If not the first record.
            if( i != 0 )
            {
                printf( ", ", (s32) n.TheBlock );
            }
            
            // Remember the block.
            LastBlock = n.TheBlock;
        }
        
        // Copy the record to the line buffer.
        memmove( LineBuffer,          // To
                 n.TheRecord,         // From
                 n.BytesPerRecord );  // ByteCount
        
        // Append a terminating zero.
        LineBuffer[ n.BytesPerRecord ] = 0;
        
        // Print the record as a text string.
        printf( "%s", LineBuffer );
        
        // Advance the record index.
        i++;
        
        // Advance to the next record.
        ToNextRecord( &n );
    }
    
    printf( "\n" ); //
}

/*------------------------------------------------------------
| EmptyTable
|-------------------------------------------------------------
|
| PURPOSE: To delete all of the records in a table.
|
| DESCRIPTION:  
|
| EXAMPLE:     EmptyTable( T );
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 11.08.98 TL 
------------------------------------------------------------*/
void
EmptyTable( Table* T )
{
    ThatRecord  R;
    
    // If there are any records in the table.
    if( T->RecordCount )
    {
        // Refer to the first record in the table.
        ToFirstRecord( T, &R );
        
        // Then delete all the records.
        DeleteRecords( &R, T->RecordCount );
    }
}

/*------------------------------------------------------------
| FindBlockInTable
|-------------------------------------------------------------
|
| PURPOSE: To find a block of records in a table that may 
|          contain a given key value.
|
| DESCRIPTION: Returns address of the block found, else 0 if 
| the keyed record should be appended to the end of the table.
|
| A binary search is made of the block list via a direct
| block address table that will be built as needed if it doesn't
| already exist.
|
| EXAMPLE: B = FindBlockInTable( T, Key );
|
| NOTE: Uses fast binary search algorithm.
|
| ASSUMES: The table is an ordered table and there is more
|          than one block.
|
| HISTORY: 10.12.98 From 'FindPlaceInOrderedBlockAddressTableTable'.
|          10.14.98 Revised to use a sub-table for the block
|                   addresses to reduce fragmentation.
------------------------------------------------------------*/
RecordBlock*
FindBlockInTable( 
    Table*  T,    // Address of the table.
                  //
    u8*     Key ) // Address of the search key.
{
    RecordBlock*    B;
    s32             Hi, Lo, Mid; 
    s32             Cond;
    u32             BlockCount;
    Table*          S;
    ThatRecord      SR;
    RecordBlock*    AtBlock;
    
    // Get the count of the number of blocks in the table.
    BlockCount = T->BlockCount;
    
    // If there is a block address table and it needs to be updated.
    if( T->BlockAddressTable &&
        T->IsBlockAddressTableCurrent == 0 )
    {
        // Delete the block address table.
        DeleteTable( T->BlockAddressTable );
        
        // Mark the block address table as missing.
        T->BlockAddressTable = 0;
    }

    // If the block address table for the block list needs to 
    // be built.
    if( T->BlockAddressTable == 0 )
    {
        // Make a table for the block addresses, 50 addresses per block.
        S = MakeTable( 
                sizeof( RecordBlock* ), // How many bytes are in each
                                // data record.
                                //
                50,             // How many records should be
                                // held in each block.   
                                //
                0,              // Use zero for
                                // 'CompareKeyProcedure' 
                                // if the table isn't ordered.
                                //
                0,              // Key offset. Only used for ordered 
                                // tables, use zero if unordered.
                                //
                0 );            // Size of the key field in bytes.
                                // Only used for ordered tables,
                                // use zero if unordered.
            
        // Connect the main table to the block address sub table.
        T->BlockAddressTable = S;
        
        // Refer to the first block in the main table.
        B = T->FirstBlock;
        
        // For every block in the main block list.
        while( B )
        {
            // Treat the block address as a four-byte record
            // and put the block address into the block address 
            // table.
            InsertRecordsLast( 
                S,          // The table where the records
                            // will be inserted.
                            //
                (u8*) &B,   // Where the records are that 
                            // are to be inserted.  This is
                            // a contiguous block of records.
                            //
                1 );        // How many records are to be
                            // inserted.
            
            // Advance to the next block.
            B = B->Next;
        }
        
        // Mark the block address table as being up-to-date.
        T->IsBlockAddressTableCurrent = 1;
    }
    
    // Refer to the block address table.
    S = T->BlockAddressTable;
    
    // Prepare for the binary search.
    Lo = 0;  
    Hi = (s32) ( BlockCount - 1 );
    
    // Begin binary search.
    while( Lo <= Hi )
    {
        // Calculate the index of the current middle entry.
        Mid = (Hi + Lo) >> 1; // (Hi+Lo)/2 

        // Refer to the address of the block with the index equal to Mid.
        ToNthRecord( S, &SR, (u32) Mid );
        
        // Fetch the block address.
        AtBlock = *((RecordBlock**) SR.TheRecord);
        
        // Compare the search key to the records held in the
        // middle block.  NOTE: This can be sped up by expanding
        // the function call here.
        Cond = CompareKeyToRecordBlock( Key, (u8*) AtBlock );

        // If the key falls in the block.
        if( Cond == 0 )
        {    
            // Return the block address.
            return( AtBlock );
        }
        
        // If the key comes before the block.
        if( Cond < 0 ) 
        {
            Hi = Mid - 1;
        }
        else // The key follows the block.
        {
            Lo = Mid + 1;
        }
    }
    
    // If ran off the end of the table.
    if( (u32) Lo == BlockCount ) 
    {
        // Signal that the key follows the end of the table.
        return( 0 ); 
    }
    else // Converged to a point not in any block.
    {
        // Find to the address of the block with index equal to Lo.
        ToNthRecord( S, &SR, (u32) Lo );
        
        // Fetch the block address.
        AtBlock = *((RecordBlock**) SR.TheRecord);
        
        // Return the address of the block that immediately
        // follows the key.
        return( AtBlock );
    }
}

/*------------------------------------------------------------
| FindNextRecord
|-------------------------------------------------------------
|
| PURPOSE: To find the record with a key value after the
|          given key.
|
| DESCRIPTION:  
|
| EXAMPLE:       C = FindNextRecord( T, Key, &R );
|
| NOTE:  
|
| ASSUMES: No duplicate key values in the table.
|
| HISTORY: 06.28.00 From FindPriorRecord.
------------------------------------------------------------*/
                      // OUT: 1 if next record was found 
s32                   //      else 0.
FindNextRecord( 
    Table*       T,   // The record table.
                      //
    u8*          Key, // Address of the search key.
                      //
    ThatRecord*  R )  // OUT: Returns the next record if
                      //      the return value is 1 or a
                      //      nearby record if the return
                      //      value is 0.
{
    s32 C;
    
    // Look for the key in the table.
    C = FindRecord( 
            T,   // The record table.
                 //
            Key, // Address of the search key.
                 //
            R ); // Returns the record or nearby record.

    // If no record was found in the table.
    if( R->TheRecord == 0 )
    {
        // Return 0 to signal failure.
        return( 0 );
    }
    
    // If a record was found comes after the search key.
    if( C < 0 )
    {
        // Then the next record has been found.
        
        // Return 1 to signal success.
        return( 1 );
    }
    else // The record found is the same as or comes
         // before the key.
    {
        // Move to the next record.
        ToNextRecord( R );

        // If there is no next record.
        if( R->TheRecord == 0 )
        {
            // Return 0 to signal failure.
            return( 0 );
        }
        else // There is a next record.
        {
            // Return 1 to signal success.
            return( 1 );
        }
    }
}

/*------------------------------------------------------------
| FindPriorRecord
|-------------------------------------------------------------
|
| PURPOSE: To find the record with a key value prior to the
|          given key.
|
| DESCRIPTION:  
|
| EXAMPLE:       C = FindPriorRecord( T, Key, &R );
|
| NOTE:  
|
| ASSUMES: No duplicate key values in the table.
|
| HISTORY: 06.28.00  
------------------------------------------------------------*/
                      // OUT: 1 if prior record was found 
s32                   //      else 0.
FindPriorRecord( 
    Table*       T,   // The record table.
                      //
    u8*          Key, // Address of the search key.
                      //
    ThatRecord*  R )  // OUT: Returns the prior record if
                      //      the return value is 1 or a
                      //      nearby record if the return
                      //      value is 0.
{
    s32 C;
    
    // Look for the key in the table.
    C = FindRecord( 
            T,   // The record table.
                 //
            Key, // Address of the search key.
                 //
            R ); // Returns the record or nearby record.

    // If no record was found in the table.
    if( R->TheRecord == 0 )
    {
        // Return 0 to signal failure.
        return( 0 );
    }
    
    // If a record was found comes before the search key.
    if( C > 0 )
    {
        // Then the prior record has been found.
        
        // Return 1 to signal success.
        return( 1 );
    }
    else // The record found is the same as or comes
         // after the key.
    {
        // Move to the prior record.
        ToPriorRecord( R );

        // If there is no prior record.
        if( R->TheRecord == 0 )
        {
            // Return 0 to signal failure.
            return( 0 );
        }
        else // There is a prior record.
        {
            // Return 1 to signal success.
            return( 1 );
        }
    }
}

/*------------------------------------------------------------
| FindRecord
|-------------------------------------------------------------
|
| PURPOSE: To find a record in a table given a key value.
|
| DESCRIPTION: If the record matching the key is found, a 
| reference to it is returned in 'R' and the return value of
| this procedure is zero.
|
| If a record matching the key is not found then a nearby
| record is returned in 'R' and the return value indicates
| the relationship of the record returned to the key:
|
| Return value is:
|                       0 if Key == KeyOf(R) 
|
|         positive number if Key >  KeyOf(R) 
|
|         negative number if Key <  KeyOf(R) 
|   
| where R is the record returned.
|
| The search method consists of a two-stage binary search
| as follows:
|
| 1) A binary search is made of the record blocks until the
|    block is found that could contain the key.
|
| 2) A binary search is made of the block to locate the
|    record.
|
| 3) If the table is empty then 'R->TheRecord' returns zero
|    and a positive number is returned.
|
| EXAMPLE:     C = FindRecord( T, Key, &R );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 09.30.98 From 'FindExtent'.
|          10.07.98 Fixed case where the sought after record
|                   falls beyond the end of the table; added
|                   optimization for case where only one 
|                   record block exists in the table.
|          10.12.98 Revised to directly manage block list.
------------------------------------------------------------*/
s32 
FindRecord( 
    Table*       T,   // The record table.
                      //
    u8*          Key, // Address of the search key.
                      //
    ThatRecord*  R )  // Returns the record or nearby record.
{
    RecordBlock*    B;
    
    // If the table is empty.
    if( T->RecordCount == 0 )
    {
        // Mark the record as missing and set the table and
        // block references.
        ToFirstRecord( T, R );
        
        // Return a positive number.
        return( 1 );
    }
    
    // If there is more than one block.
    if( T->BlockCount > 1 )
    {
        // Find the block where the target record should be.
        B = FindBlockInTable( T , Key );  
                
        // If 'B' is zero, meaning that the record
        // falls beyond the table.
        if( B == 0 )
        {
            // Refer to the last record in the table.
            ToLastRecord( T, R );
            
            // Return a positive number to indicate that the new
            // record should follow the table.
            return( 1 );
        }
        else // The record falls within the table.
        {   
            // Find the record in the block and return the result.
            return( FindRecordInBlock( B, Key, R ) );
        }
    }
    else // There is only one block.
    {
        // Refer to the target location in the first block.
        return( FindRecordInBlock( T->FirstBlock, Key, R ) );
    }
}

/*------------------------------------------------------------
| FindRecordInBlock
|-------------------------------------------------------------
|
| PURPOSE: To find a record in a block given a key value.
|
| DESCRIPTION: If matching record is found a reference to it 
| is returned in 'R' and the return value of this procedure 
| is zero.
|
| If an exact match is not found then one of the nearest
| matching records is returned in 'R' and the function return 
| value indicates the relationship of the key to the record 
| found, as follows:
|
| Return value is:
|
|     Positive number if Key > R
|     Negative number if Key < R
|
| A binary search is made of the block to locate the record.
|
| EXAMPLE:  
|           C = FindRecordInBlock( B, Key, &R );
| NOTE:  
|
| ASSUMES: Records in the block are maintained in increasing
|          key field value order as determined by the record
|          comparison procedure of the table.
|
|          There is at least one block.
|
| HISTORY:  09.30.96 from 'IndexOfKey'.
------------------------------------------------------------*/
s32 
FindRecordInBlock( 
    RecordBlock*    B,    // The block in the table.
                          //
    u8*             Key,  // Address of the search key.
                          //
    ThatRecord*     R )   // Returns the record or a nearby 
                          // record.
{
    Table*          T;
    s32             C;
    s32             Hi, Lo, Mid; 
    u32             BytesPerRecord;
    u8*             FirstRecord;
    u8*             LastRecord;
    u8*             KeyInFirstRecord;
    u8*             AtMidKey;
    u32             KeyOffset;
    CompareProc     CompareKeyProcedure;
    
    // Refer to the table holding the block.
    T = (Table*) B->MyTable;
    
    // Get the table-specific compare function.
    CompareKeyProcedure = T->CompareKeyProcedure;
    
    // Get the number of bytes per record.
    BytesPerRecord = T->BytesPerRecord;
    
    // Refer to the first record in the block.
    FirstRecord = B->FirstRecord;
    
    // Refer to the last record.
    LastRecord = B->EndOfData - BytesPerRecord;
    
    // Get the byte offset of the key field.
    KeyOffset = T->KeyOffset;
    
    // Calculate the address of the key field in the first record.
    KeyInFirstRecord = FirstRecord + KeyOffset;
    
    // Calculate the index of the last record.
    Hi = (s32) ( B->RecordCount - 1 );
    
    // Set the index of the first low record.
    Lo = 0;
 
    // Binary search: table must be in ascending order.
    while( Lo <= Hi )
    {
        // Calculate the index of the middle record.
        Mid = ( Hi + Lo ) >> 1; // (Hi+Lo)/2  

        //
        // Calculate the key field address of the middle record.
        //
        AtMidKey = KeyInFirstRecord + ( Mid * BytesPerRecord );
        
        // Call the table-specific comparison function.
        C = (*CompareKeyProcedure)( Key, AtMidKey );

        // If the keys match exactly.
        if( C == 0 )
        {
            // Go return the result.
            goto Finish;    
        }

        if( C < 0 )  // Key < KeyInRow
        {
            Hi = Mid - 1;
        }
        else // Key > KeyInRow
        {
            Lo = Mid + 1;
        }
    }

Finish:

    // Prepare the return values.
    R->TheTable  = T;
    R->TheBlock  = B;
    R->TheRecord = AtMidKey - KeyOffset;
    R->BytesPerRecord = BytesPerRecord;
    
    // Return the result of the last comparison.
    return( C );
}

/*------------------------------------------------------------
| InsertBlockAfterBlock
|-------------------------------------------------------------
|
| PURPOSE: To insert a record block after another in a table's
|          block list.
|
| DESCRIPTION: Inserts the new block and updates all links and
| block counts to reflect the insertion of the new block.
|
| EXAMPLE:     
|
|       InsertBlockAfterBlock( PriorBlock, NewBlock );
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 10.05.98 TL From 'InsertItemAfterItemInList'.
|          10.14.98 TL Fixed missing link.
------------------------------------------------------------*/
void
InsertBlockAfterBlock( 
    RecordBlock* A,   // The prior block already in the list.
                      //
    RecordBlock* B )  // New block to be inserted after 'A'.
{
    Table*  T;
    
    // Refer to the table holding the existing block.
    T = A->MyTable;          
                    
    // Connect the link from the new block to the table.
    B->MyTable = T;

    // Update the table block count.
    T->BlockCount += 1;
    
    // If block A is the last one in the list.
    if( A == T->LastBlock )
    {
        // Update the last block reference of the table.
        T->LastBlock = B;
    }
 
    // Mark the block address table as out-of-date.
    T->IsBlockAddressTableCurrent = 0;

    // Set the next link of the new block, B, to refer to
    // the block following block A.
    B->Next = A->Next;
    
    // If there is a block following B.
    if( B->Next )
    {
        // Set the back link of the next block to refer to B.
        B->Next->Prior = B;
    }
    
    // Set the prior link of the new block to refer to A.
    B->Prior = A;
    
    // Update the next link of A to refer to B.
    A->Next = B;
}

/*------------------------------------------------------------
| InsertBlockBeforeBlock
|-------------------------------------------------------------
|
| PURPOSE: To insert a record block before another one in the
|          block list of a data table. 
|
| DESCRIPTION: Inserts the new block and updates all links and
| block counts to reflect the insertion of the new block.
|
| EXAMPLE:     
|
|       InsertBlockBeforeBlock( NewBlock, NextBlock );
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 10.13.98 TL From 'InsertBlockAfterBlock'.
|          10.14.98 TL Fixed missing link; also fixed bad
|                      source for table address.
------------------------------------------------------------*/
void
InsertBlockBeforeBlock( 
    RecordBlock* A,   // New block to be inserted before 'B'.
                      //
    RecordBlock* B )  // The next block already in the list.
                      //
{
    Table*  T;
    
    // Refer to the table holding the existing block.
    T = B->MyTable;          
                    
    // Connect the link from the new block to the table.
    A->MyTable = T;
    
    // Update the table block count.
    T->BlockCount += 1;
    
    // If block B is the first one in the list.
    if( B == T->FirstBlock )
    {
        // Update the first block reference of the table.
        T->FirstBlock = A;
    }
 
    // Mark the block address table as out-of-date.
    T->IsBlockAddressTableCurrent = 0;

    // Set the next link of the new block, A, to refer to
    // the block following block B.
    A->Next = B;
    
    // Set the prior link of the new block to refer to the
    // predecessor of A.
    A->Prior = B->Prior;
    
    // If there is a prior block.
    if( A->Prior )
    {
        // Set the prior's next link to refer to A.
        A->Prior->Next = A;
    }
    
    // Update the back link from B to refer to A.
    B->Prior = A;
}

/*------------------------------------------------------------
| InsertBlockFirst
|-------------------------------------------------------------
|
| PURPOSE: To insert a record block as first in a table's
|          block list.
|
| DESCRIPTION: Inserts the new block and updates all links and
| block counts to reflect the insertion of the new block.
|
| EXAMPLE:     
|
|       InsertBlockFirst( T, NewBlock );
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 10.13.98 TL From 'InsertBlockBeforeBlock'.
------------------------------------------------------------*/
void
InsertBlockFirst( 
    Table* T,         // The table where the block will be
                      // inserted.
                      //
    RecordBlock* B )  // The new block.
                      //
{
    // Connect the link from the new block to the table.
    B->MyTable = T;
    
    // Update the table block count.
    T->BlockCount += 1;
    
    // Mark the block address table as out-of-date.
    T->IsBlockAddressTableCurrent = 0;

    // Set the next link of the new block, B, to refer to
    // the current first block in the table.
    B->Next = T->FirstBlock;
    
    // Update the back link from the former first block to 
    // refer to B.
    T->FirstBlock->Prior = B;
    
    // Update the first block reference of the table.
    T->FirstBlock = B;
    
    // Clear the prior link of the new block to show that
    // it's first.
    B->Prior = 0;
}

/*------------------------------------------------------------
| InsertBlockLast
|-------------------------------------------------------------
|
| PURPOSE: To insert a record block as last in a table's
|          block list.
|
| DESCRIPTION: Inserts the new block and updates all links and
| block counts to reflect the insertion of the new block.
|
| EXAMPLE:     
|
|       InsertBlockLast( T, NewBlock );
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 10.13.98 TL From 'InsertBlockFirst'.
------------------------------------------------------------*/
void
InsertBlockLast( 
    Table* T,         // The table where the block will be
                      // inserted.
                      //
    RecordBlock* B )  // The new block.
                      //
{
    // Connect the link from the new block to the table.
    B->MyTable = T;
    
    // Update the table block count.
    T->BlockCount += 1;
    
    // Mark the block address table as out-of-date.
    T->IsBlockAddressTableCurrent = 0;

    // Set the prior link of the new block, A, to refer to
    // the current last block in the table.
    B->Prior = T->LastBlock;
    
    // Update the next link from the former last block to 
    // refer to B.
    T->LastBlock->Next = B;
    
    // Update the last block reference of the table.
    T->LastBlock = B;
    
    // Clear the next link of the new block to show that
    // it's last.
    B->Next = 0;
}

/*------------------------------------------------------------
| InsertOrderedRecords
|-------------------------------------------------------------
|
| PURPOSE: To insert one or more records into an ordered 
|          table.
|
| DESCRIPTION: Uses the key comparison procedure of the
| table to locate the appropriate place in the table for
| each new record and then inserts the record at that point.  
|
| No changes are made to the source records nor are the 
| source records incorporated into the table -- only the 
| content of the source record storage area is copied into 
| the table.
|
| New memory storage may be allocated by this procedure to
| hold new records if space is not already available in the
| table.
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.06.98
------------------------------------------------------------*/
void
InsertOrderedRecords( 
    Table*  T,              // The table where the records go.
                            //
    u8*     AtRecords,      // Where the records are that will
                            // be inserted.  If there is more
                            // than one record they are
                            // adjacent in memory.
                            //
    u32     RecordCount )   // How many records will be
                            // inserted.
{
    s32         TargetRelation;
    u32         KeyOffset;
    u32         BytesPerRecord;
    u8*         AtKey;
    ThatRecord  R;
    
    // Get the size of each record in the table.
    BytesPerRecord = T->BytesPerRecord;
    
    // Get the record offset of the key field.
    KeyOffset = T->KeyOffset;
    
    // As long as there are records to insert.
    while( RecordCount )
    {
        // If there are records in the table.
        if( T->RecordCount )
        {
            // Refer to the key of the current record.
            AtKey = AtRecords + KeyOffset;
            
            // Find the closest record to the given record
            // in the table.
            TargetRelation =
                FindRecord( 
                    T,      // The record table.
                            //
                    AtKey,  // Address of the search key.
                            //
                    &R );   // Returns the record or nearby record.

            // If the record should be inserted after 'R'.
            //
            // Exact matches are inserted after the first matching 
            // key found which may or may not be the first key with 
            // the matching value in the table.
            //
            if( TargetRelation >= 0 )
            {
                // Insert one new record after R.
                InsertRecordsAfter( 
                    &R,          // The record in the table 
                                 // after which the new record will 
                                 // be inserted.
                                 //
                    AtRecords,   // Where the source records is.
                                 //
                    1 );         // How many records are to be
                                 // inserted.
            }
            else // The record should be inserted before R.
            {
                // Insert one new record before R.
                InsertRecordsBefore( 
                    &R,          // The record in the table 
                                 // before which the new record will 
                                 // be inserted.
                                 //
                    AtRecords,   // Where the source records is.
                                 //
                    1 );         // How many records are to be
                                 // inserted.
            }
        }
        else // No records currently in the table.
        {
            // Insert a new record as first.
            InsertRecordsFirst( 
                T,          // The table where the record 
                            // will be inserted.
                            //
                AtRecords,  // Where the record is.
                            //
                1 );        // How many records are to be
                            // inserted.
        }

        // Account for the record just inserted.
        RecordCount--;
        
        // Advance the reference to the next record.
        AtRecords += BytesPerRecord;
    }
}

/*------------------------------------------------------------
| InsertRecordsAfter
|-------------------------------------------------------------
|
| PURPOSE: To insert one or more records into a table 
|          following a given record already in the table.
|
| DESCRIPTION: The table is regarded as an unordered table
| for purposes of record insertion: the key field of the
| inserted records is ignored so that it doesn't cause the
| reordering of the records.
|
| No changes are made to the source records nor are the source
| records incorporated into the table -- only the content of 
| the source record storage area is copied into the table.
|
| No changes are made to the reference to the target record.
|
| New memory storage may be allocated by this procedure to
| hold new records if space is not already available in the
| table.
|
| EXAMPLE:     
|
|   InsertRecordsAfter( SomeRecord, MyRecords, Count );
|
| NOTE:  
|
| ASSUMES: Source records are the same size as those in the
|          table and are contiguous in memory.
|
| HISTORY: 10.05.98 TL From 'InsertRecordsLast'.
|          10.15.98 Revised to shift to adjacent blocks on
|                   either side before inserting a new block.
|          12.01.98 Added 'IsLookasideEmpty'.
------------------------------------------------------------*/
void            
InsertRecordsAfter( 
    ThatRecord* R,           // The record in the table 
                             // after which new records will 
                             // be inserted.
                             //
    u8*         AtRecords,   // Where the records to be 
                             // inserted are.  If there is 
                             // more than one record they are
                             // adjacent in memory.
                             //
    u32         RecordCount )// How many records are to be
                             // inserted.
{
    Table*       T;
    RecordBlock* B;
    RecordBlock* C;
    ThatRecord   Q;
    ThatRecord   X;
    ThatRecord   FirstRecord;
    u8*          AfterQ;
    u32          RecordsPerBlock;
    u32          BytesPerRecord;
    u32          BytesToBeInserted;
    u32          BytesToBeMoved;
    u32          RecordCountToInsert;
    u32          EmptyRecordCount;
    u32          HowManyMoreEmptyRecordsNeededInCurrentBlock;
    u32          HowManyRecordsBeforeQ;
    u32          HowManyRecordsAfterQ;
    u32          HowManyRecordsToShiftBack;
    u32          HowManyRecordsToShiftToNext;
    u32          HowManyBytesShifted;
    
    // Copy 'R' to a record reference named 'Q' that will 
    // be used as a cursor.
    Q = *R;
    
    // Refer to the table that holds the target record.
    T = Q.TheTable;
    
    // Get the number of records per block.
    RecordsPerBlock = T->RecordsPerBlock;

    // Get the record size.
    BytesPerRecord = T->BytesPerRecord;
    
    // As long as there are records to insert.
    while( RecordCount )
    {
        // Refer to the block that holds the target record.
        B = Q.TheBlock;
    
        // Calculate the number of empty records in the current block.
        EmptyRecordCount = RecordsPerBlock - B->RecordCount;
        
        // If the number of records to be inserted exceeds the space
        // available.
        if( RecordCount > EmptyRecordCount )
        {
            // Calculate the number of additional empty records needed 
            // in the current block.
            HowManyMoreEmptyRecordsNeededInCurrentBlock =
                RecordCount - EmptyRecordCount;
            // 
            // Attempt to shift records to adjacent blocks to make room.
            //
            
            // If the insertion point isn't the first record in the block.
            if( Q.TheRecord != B->FirstRecord )
            {
                // If there is a prior block.
                if( B->Prior )
                {
                    // If there is any room in the prior block.
                    if( B->Prior->EndOfData < B->Prior->EndOfBlock )
                    {
                        // Calculate how many records preceed the insertion 
                        // record.
                        HowManyRecordsBeforeQ =
                            (Q.TheRecord - B->FirstRecord)/BytesPerRecord;
            
                        // Calculate the number of records to shift, the
                        // lesser of what is there and what is required.
                        HowManyRecordsToShiftBack =
                            min( HowManyMoreEmptyRecordsNeededInCurrentBlock,
                                 HowManyRecordsBeforeQ );
                                 
                        // Refer to the first record in the current block.
                        ToFirstRecordInBlock( B, &FirstRecord );
            
                        // Shift some records to the prior block: some of the
                        // requested records may not be moved if space doesn't
                        // permit.
                        HowManyBytesShifted =
                            ShiftRecordsToPriorBlock( 
                                &FirstRecord, 
                                HowManyRecordsToShiftBack );
                        
                        // Displace Q to adjust for shifting.
                        Q.TheRecord -= HowManyBytesShifted;
                        
                        // Update the number of empty records in the 
                        // current block.
                        EmptyRecordCount = RecordsPerBlock - B->RecordCount;
 
                        // Update the number of additional empty records needed 
                        // in the current block.
                        HowManyMoreEmptyRecordsNeededInCurrentBlock =
                             RecordCount - EmptyRecordCount;
                    }
                }
            }
            
            // If more empty records in the current block are still needed.
            if( HowManyMoreEmptyRecordsNeededInCurrentBlock )
            {
                // If there is a next block.
                if( B->Next )
                {
                    // If there is some room in the next block.
                    if( B->Next->EndOfData < B->Next->EndOfBlock )
                    {
                        // If Q is a record that contains data.
                        if( Q.TheRecord < B->EndOfData )
                        {
                            // Refer to the address after record Q.
                            AfterQ = Q.TheRecord + BytesPerRecord;
                        }
                        else // Q is an empty record.
                        {
                            // The address after Q is Q.
                            AfterQ = Q.TheRecord;
                        }
            
                        // Calculate how many records follow the insertion 
                        // record, may be none.
                        HowManyRecordsAfterQ =
                            (B->EndOfData - AfterQ)/BytesPerRecord;
            
                        // If there are any records following Q.
                        if( HowManyRecordsAfterQ )
                        {
                            // Calculate the number of records to shift, the
                            // lesser of what is there and what is required.
                            HowManyRecordsToShiftToNext =
                                min( HowManyMoreEmptyRecordsNeededInCurrentBlock,
                                     HowManyRecordsAfterQ );
                                     
                            // Refer to the first record to shift to the next
                            // block, the last so many records.
                            X = Q;
                            X.TheRecord = B->EndOfData - 
                                ( HowManyRecordsToShiftToNext * BytesPerRecord );

                            // Shift some records to the next block.
                            HowManyBytesShifted =
                                ShiftRecordsToNextBlock( 
                                    &X, 
                                    HowManyRecordsToShiftToNext );
                            
                            // Update the number of empty records in the 
                            // current block.
                            EmptyRecordCount = RecordsPerBlock - B->RecordCount;
     
                            // Update the number of additional empty records needed 
                            // in the current block.
                            HowManyMoreEmptyRecordsNeededInCurrentBlock =
                                 RecordCount - EmptyRecordCount;
                        }
                    }
                }
            }
        }
            
        //
        // At this point all of the empty space that can be gained by
        // shifting records to adjacent blocks has been gained.
        //
            
        // If the current block is full.
        if( B->RecordCount == RecordsPerBlock )
        {
            // Make a new, empty record block
            C = MakeRecordBlock( RecordsPerBlock, BytesPerRecord );
            
            // Insert block 'C' into the block list after block 'B'.
            InsertBlockAfterBlock( B, C );
            
            // If the insertion point, Q, is the last record.
            if( Q.TheRecord == (B->EndOfData - BytesPerRecord) )
            {
                // Change Q to be the first record in the new next
                // empty block.
                Q.TheBlock = C;
                Q.TheRecord = C->FirstRecord;
            }
        }
        else // There is room for at least one record in the current block.
        {   
            //
            // At this point there's room in the current block for at
            // least one record and 'Q' refers to the record after which
            // new records should be put.  If there are records after Q 
            // they will need to be shifted toward the end of the block.
            //
            
            // Calculate the most number of records that can now
            // be inserted into the current record block, B.
            RecordCountToInsert = RecordsPerBlock - B->RecordCount;
            
            // If there is more capacity for records than there
            // are records to copy.
            if( RecordCountToInsert > RecordCount )
            {
                // Copy only the remaining records.
                RecordCountToInsert = RecordCount;
            }
            
            // Calculate the number of bytes that will be inserted.
            BytesToBeInserted = RecordCountToInsert * BytesPerRecord;
            
            // If Q is a record that contains data.
            if( Q.TheRecord < B->EndOfData )
            {
                // Refer to the address after record Q.
                AfterQ = Q.TheRecord + BytesPerRecord;
            }
            else // Q is an empty record.
            {
                // The address after Q is Q.
                AfterQ = Q.TheRecord;
            }
            
            // If records follow Q.
            if( AfterQ < B->EndOfData )
            {
                // Calculate the byte count of the records 
                // following Q that will need to be shifted.
                BytesToBeMoved = (u32)
                    ( B->EndOfData - AfterQ );
            
                // Shift the records toward the end of the block.
                memmove( AfterQ + BytesToBeInserted, // To
                         AfterQ,                     // From
                         BytesToBeMoved );           // ByteCount
            }
    
            // Copy the new records into place.
            memmove( AfterQ,               // To
                     AtRecords,            // From
                     BytesToBeInserted );  // ByteCount
            
            //   
            // Account for the records just copied into the block:
            //
            
            // Update the record counter for the block.
            B->RecordCount += RecordCountToInsert;
            
            // Update the pointer to the end of the records.
            B->EndOfData += BytesToBeInserted;
            
            // Account for the records just copied into the table.
            T->RecordCount += RecordCountToInsert;
    
            // Reduce the number of records to be copied.
            RecordCount -= RecordCountToInsert;
    
            // Advance the source record pointer.
            AtRecords += BytesToBeInserted;
            
            // Advance the target record pointer to refer to the
            // last record just inserted: this formulation handles
            // the insertion into empty blocks.
            Q.TheRecord = AfterQ + 
                (BytesToBeInserted - BytesPerRecord);
        }
    }
    
    // Mark the lookaside buffer as empty because the record 
    // structure of the table has changed.
    T->IsLookasideEmpty = 1;
}

/*------------------------------------------------------------
| InsertRecordsBefore
|-------------------------------------------------------------
|
| PURPOSE: To insert one or more records to a table preceeding
|          a given record already in the table.
|
| DESCRIPTION: The table is regarded as an unordered table
| for purposes of record insertion: the key field of each
| inserted record is ignored so that it doesn't cause the
| reordering of the record.
|
| No changes are made to the source records nor are the source
| records incorporated into the table -- only the content of 
| the source record storage area is copied into the table.
|
| No changes are made to the reference to the target record.
|
| New memory storage may be allocated by this procedure to
| hold new records if space is not already available in the
| table.
|
| EXAMPLE:     
|
|   InsertRecordsBefore( SomeRecord, MyRecords, Count );
|
| NOTE:  
|
| ASSUMES: Source records are the same size as those in the
|          table and are contiguous in memory.
|
| HISTORY: 10.05.98 TL From 'InsertRecordsAfter'.
|          10.15.98 Revised to shift to adjacent blocks on
|                   either side before inserting a new block.
|          12.01.98 Added 'IsLookasideEmpty'.
------------------------------------------------------------*/
void            
InsertRecordsBefore( 
    ThatRecord* R,           // The record in the table before
                             // which new records will be 
                             // inserted.
                             //
    u8*         AtRecords,   // Where the records to be 
                             // inserted are.  If there is 
                             // more than one record they are
                             // adjacent in memory.
                             //
    u32         RecordCount )// How many records are to be
                             // inserted.
{
    Table*       T;
    RecordBlock* B;
    RecordBlock* C;
    ThatRecord   Q;
    ThatRecord   X;
    ThatRecord   FirstRecord;
    u32          RecordsPerBlock;
    u32          BytesPerRecord;
    u32          BytesToBeInserted;
    u32          BytesToBeMoved;
    u32          RecordCountToInsert;
    u32          EmptyRecordCount;
    u32          HowManyMoreEmptyRecordsNeededInCurrentBlock;
    u32          HowManyRecordsBeforeQ;
    u32          HowManyRecordsAfterQ;
    u32          HowManyRecordsToShiftBack;
    u32          HowManyRecordsToShiftToNext;
    u32          HowManyBytesShifted;
    
    // Copy 'R' to a record reference named 'Q' so it can
    // be used as a cursor.
    Q = *R;
    
    // Refer to the table that holds the target record.
    T = Q.TheTable;
    
    // Get the number of records per block.
    RecordsPerBlock = T->RecordsPerBlock;

    // Get the record size.
    BytesPerRecord = T->BytesPerRecord;
    
    // As long as there are records to insert.
    while( RecordCount )
    {
        // Refer to the block that holds the target record.
        B = Q.TheBlock;
    
        // Calculate the number of empty records in the current block.
        EmptyRecordCount = RecordsPerBlock - B->RecordCount;
        
        // If the number of records to be inserted exceeds the space
        // available.
        if( RecordCount > EmptyRecordCount )
        {
            // Calculate the number of additional empty records needed 
            // in the current block.
            HowManyMoreEmptyRecordsNeededInCurrentBlock =
                RecordCount - EmptyRecordCount;
            // 
            // Attempt to shift records to adjacent blocks to make room.
            //
            
            // If the insertion point isn't the first record in the block.
            if( Q.TheRecord != B->FirstRecord )
            {
                // If there is a prior block.
                if( B->Prior )
                {
                    // If there is some room in the prior block.
                    if( B->Prior->EndOfData < B->Prior->EndOfBlock )
                    {
                        // Calculate how many records preceed the insertion 
                        // record.
                        HowManyRecordsBeforeQ =
                            (Q.TheRecord - B->FirstRecord)/BytesPerRecord;
            
                        // Calculate the number of records to shift, the
                        // lesser of what is there and what is required.
                        HowManyRecordsToShiftBack =
                            min( HowManyMoreEmptyRecordsNeededInCurrentBlock,
                                 HowManyRecordsBeforeQ );
                                 
                        // Refer to the first record in the current block.
                        ToFirstRecordInBlock( B, &FirstRecord );
            
                        // Shift some records to the prior block.
                        HowManyBytesShifted =
                            ShiftRecordsToPriorBlock( 
                                &FirstRecord, 
                                HowManyRecordsToShiftBack );
                        
                        // Displace Q to adjust for shifting.
                        Q.TheRecord -= HowManyBytesShifted;
                        
                        // Update the number of empty records in the 
                        // current block.
                        EmptyRecordCount = RecordsPerBlock - B->RecordCount;
 
                        // Update the number of additional empty records needed 
                        // in the current block.
                        HowManyMoreEmptyRecordsNeededInCurrentBlock =
                             RecordCount - EmptyRecordCount;
                    }
                }
            }
            
            // If more empty records in the current block are still needed.
            if( HowManyMoreEmptyRecordsNeededInCurrentBlock )
            {
                // If there is a next block.
                if( B->Next )
                {
                    // If there is some room in the next block.
                    if( B->Next->EndOfData < B->Next->EndOfBlock )
                    {
                        // Calculate how many records follow the insertion 
                        // point, always at least one.
                        HowManyRecordsAfterQ =
                            (B->EndOfData - Q.TheRecord)/BytesPerRecord;
            
                        // Calculate the number of records to shift, the
                        // lesser of what is there and what is required.
                        HowManyRecordsToShiftToNext =
                            min( HowManyMoreEmptyRecordsNeededInCurrentBlock,
                                 HowManyRecordsAfterQ );
                        
                        // Refer to the first record to shift to the next
                        // block, the last so many records.
                        X = Q;
                        X.TheRecord = B->EndOfData - 
                            ( HowManyRecordsToShiftToNext * BytesPerRecord );
                            
                        // Shift some records to the next block.
                        HowManyBytesShifted =
                            ShiftRecordsToNextBlock( 
                                &X, 
                                HowManyRecordsToShiftToNext );
                        
                        // Update the number of empty records in the 
                        // current block.
                        EmptyRecordCount = RecordsPerBlock - B->RecordCount;
 
                        // Update the number of additional empty records needed 
                        // in the current block.
                        HowManyMoreEmptyRecordsNeededInCurrentBlock =
                             RecordCount - EmptyRecordCount;
                    }
                }
            }
        }
            
        //
        // At this point all of the empty space that can be gained by
        // shifting records to adjacent blocks has been gained.
        //
            
        // If the current block is full.
        if( B->RecordCount == RecordsPerBlock )
        {
            // Make a new, empty record block
            C = MakeRecordBlock( RecordsPerBlock, BytesPerRecord );
            
            // Insert block 'C' into the block list before block 'B'.
            InsertBlockBeforeBlock( C, B );
            
            // If the insertion point, Q, is the first record.
            if( Q.TheRecord == B->FirstRecord )
            {
                // Change Q to be the first record in the new prior
                // empty block.
                Q.TheBlock = C;
                Q.TheRecord = C->FirstRecord;
            }
        }
        else // There is room for at least one record in the current block.
        {   
            //
            // At this point there's room in the current block for at
            // least one record and 'Q' refers to where new records 
            // should be put.  If there are records at the insertion
            // point they will need to be shifted downward.
            //
            
            // Calculate the most number of records that can now
            // be inserted into the current record block, B.
            RecordCountToInsert = RecordsPerBlock - B->RecordCount;
            
            // If there is more capacity for records than there
            // are records to copy.
            if( RecordCountToInsert > RecordCount )
            {
                // Copy only the remaining records.
                RecordCountToInsert = RecordCount;
            }
            
            // Calculate the number of bytes that will be inserted.
            BytesToBeInserted = RecordCountToInsert * BytesPerRecord;
            
            // If Q refers to an existing record.
            if( Q.TheRecord < B->EndOfData )
            {
                // Calculate the byte count of the records 
                // following Q that will need to be shifted.
                BytesToBeMoved = (u32) ( B->EndOfData - Q.TheRecord );
            
                // Shift the records toward the end of the block.
                memmove( Q.TheRecord + BytesToBeInserted, // To
                         Q.TheRecord,                     // From
                         BytesToBeMoved );                // ByteCount
            }
    
            // Copy the new records into place.
            memmove( Q.TheRecord,          // To
                     AtRecords,            // From
                     BytesToBeInserted );  // ByteCount
               
            // Account for the records just copied into the block:
            
            // Update the record counter for the block.
            B->RecordCount += RecordCountToInsert;
            
            // Update the pointer to the end of the records.
            B->EndOfData += BytesToBeInserted;
            
            // Account for the records just copied into the table.
            T->RecordCount += RecordCountToInsert;
    
            // Reduce the number of records to be copied.
            RecordCount -= RecordCountToInsert;
    
            // Advance the source record pointer.
            AtRecords += BytesToBeInserted;
            
            // Advance the target record pointer to refer to the
            // last record just inserted: do this in stages, first
            // refer to the last record inserted, then use the
            // traversal function to move to the following record
            // so that block boundaries can be crossed if need be.
            Q.TheRecord += (BytesToBeInserted - BytesPerRecord);
            ToNextRecord( &Q );
        }
    }
    
    // Mark the lookaside buffer as empty because the record 
    // structure of the table has changed.
    T->IsLookasideEmpty = 1;
}

/*------------------------------------------------------------
| InsertRecordsFirst
|-------------------------------------------------------------
|
| PURPOSE: To prepend one or more records to a table.
|
| DESCRIPTION: The table is regarded as an unordered table
| for purposes of record insertion.
|
| No changes are made to the source records nor are the source
| records incorporated into the table -- only the content of 
| the source record storage area is copied into the table.
|
| New memory storage may be allocated by this procedure to
| hold new records if space is not already available in the
| table.
|
| EXAMPLE:     
|
|       InsertRecordsFirst( MyTable, MyRecords, Count );
|
| NOTE:  
|
| ASSUMES: Source records are the same size as those in the
|          table and are contiguous in memory.
|
| HISTORY: 10.05.98 TL
|          12.01.98 Added 'IsLookasideEmpty'.
------------------------------------------------------------*/
void            
InsertRecordsFirst( 
    Table*     T,           // The table where the records
                            // will be inserted.
                            //
    u8*         AtRecords,  // Where the records to be 
                            // inserted are.  If there is 
                            // more than one record they are
                            // adjacent in memory.
                            //
    u32        RecordCount )// How many records are to be
                            // inserted.
{
    RecordBlock* B;
    u32          RecordsPerBlock;
    u32          RecordsInTheBlock;
    u32          BytesPerRecord;
    u32          BytesToBeInserted;
    u32          BytesToBeMoved;
    u32          RecordCountToInsert;
    u8*          EndOfData;
    u8*          AtRecordsToInsert;
    
    // Get the number of records per block.
    RecordsPerBlock = T->RecordsPerBlock;

    // Get the record size.
    BytesPerRecord = T->BytesPerRecord;
    
    // As long as there are records to insert.
    while( RecordCount )
    {   
        // Refer to the first block in the table: there
        // will always be one.
        B = T->FirstBlock;
    
        // If there is no room in the block for new records.
        if( B->RecordCount == RecordsPerBlock )
        {
            // Make a record block able to hold a given number
            // of records but initially it will hold none.
            B = MakeRecordBlock( RecordsPerBlock, BytesPerRecord );
    
            // Prepend the block to the block list.
            InsertBlockFirst( T, B );
        }
        
        // Get the number records currently in the block.
        RecordsInTheBlock = B->RecordCount;
        
        // Calculate the most number of records that can now
        // be inserted into the record block, B.
        RecordCountToInsert = RecordsPerBlock - RecordsInTheBlock;
        
        // If there is more capacity for records than there
        // is records to copy.
        if( RecordCountToInsert > RecordCount )
        {
            // Copy only the remaining records.
            RecordCountToInsert = RecordCount;
        }
        
        //
        // Let's recap: at this point it's known that there
        // is space available in block 'B' to receive 
        // 'RecordCountToInsert' records.
        //
        // What remains to be done is the shifting of any
        // already existing records to make room at the 
        // beginning of the block for the new records.
        //
        // Then the new records can be copied into place.
        //
        
        // Calculate the byte count of the records to
        // be inserted on this pass through the loop.
        BytesToBeInserted = 
                BytesPerRecord * RecordCountToInsert;
        
        // If there are any records in the block.
        if( RecordsInTheBlock )
        {
            // Calculate the byte count of the records 
            // already in the block that will need to be
            // shifted.
            BytesToBeMoved = 
                    RecordsInTheBlock * BytesPerRecord;
        
            // Shift the records toward the end of the block.
            memmove( B->FirstRecord + BytesToBeInserted, // To
                     B->FirstRecord,                     // From
                     BytesToBeMoved );                   // ByteCount
        }
        
        // Calculate the address of the byte following the
        // remaining records to move.
        EndOfData = AtRecords + 
                       RecordCount * BytesPerRecord;
                       
        // Calculate the address of the first byte of the
        // last 'RecordCountToInsert' records.
        AtRecordsToInsert =
            EndOfData - BytesToBeInserted;
            
        // Copy the records into the block.
        memmove( B->FirstRecord,      // To
                 AtRecordsToInsert,   // From
                 BytesToBeInserted ); // ByteCount
                   
        // Account for the records just copied into the block:
        
        // Update the record counter for the block.
        B->RecordCount  += RecordCountToInsert;
        
        // Update the pointer to the end of the records.
        B->EndOfData += BytesToBeInserted;
        
        // Account for the records just copied into the table.
        T->RecordCount += RecordCountToInsert;
        
        // Reduce the number of records to be copied.
        RecordCount -= RecordCountToInsert;
    }
    
    // Mark the lookaside buffer as empty because the record 
    // structure of the table has changed.
    T->IsLookasideEmpty = 1;
}

/*------------------------------------------------------------
| InsertRecordsLast
|-------------------------------------------------------------
|
| PURPOSE: To append one or more records to a table.
|
| DESCRIPTION: The table is regarded as an unordered table
| for purposes of record insertion.
|
| No changes are made to the source records nor are the source
| records incorporated into the table -- only the content of 
| the source record storage area is copied into the table.
|
| New memory storage may be allocated by this procedure to
| hold new records if space is not already available in the
| table.
|
| EXAMPLE:     
|
|       InsertRecordsLast( MyTable, MyRecords, Count );
|
| NOTE:  
|
| ASSUMES: Source records are the same size as those in the
|          table and are contiguous in memory.
|
| HISTORY: 10.05.98 TL From 'InsertRecordsLast'.
|          12.01.98 Added 'IsLookasideEmpty'.
------------------------------------------------------------*/
void            
InsertRecordsLast( 
    Table*     T,           // The table where the records
                            // will be inserted.
                            //
    u8*        AtRecords,   // Where the records to be 
                            // inserted are.  If there is 
                            // more than one record they are
                            // adjacent in memory.
                            //
    u32        RecordCount )// How many records are to be
                            // inserted.
{
    RecordBlock* B;
    u32          RecordsPerBlock;
    u32          RecordsInTheBlock;
    u32          BytesPerRecord;
    u32          BytesToBeInserted;
    u32          RecordCountToInsert;
    
    // Get the number of records per block.
    RecordsPerBlock = T->RecordsPerBlock;

    // Get the record size.
    BytesPerRecord = T->BytesPerRecord;
    
    // As long as there are records to insert.
    while( RecordCount )
    {   
        // Refer to the last block in the table: there
        // will always be one.
        B = T->LastBlock;
    
        // If there is no room in the block for new records.
        if( B->RecordCount == RecordsPerBlock )
        {
            // Make a record block able to hold a given number
            // of records but initially it will hold none.
            B = MakeRecordBlock( RecordsPerBlock, BytesPerRecord );
    
            // Append the block to the block list.
            InsertBlockLast( T, B );
        }
        
        // Get the number records currently in the block.
        RecordsInTheBlock = B->RecordCount;
        
        // Calculate the most number of records that can now
        // be inserted into the record block, B.
        RecordCountToInsert = RecordsPerBlock - RecordsInTheBlock;
        
        // If there is more capacity for records than there
        // is records to copy.
        if( RecordCountToInsert > RecordCount )
        {
            // Copy only the remaining records.
            RecordCountToInsert = RecordCount;
        }
        
        //
        // Let's recap: at this point it's known that there
        // is space available in block 'B' to receive 
        // 'RecordCountToInsert' records.
        //
        // Now all that remains is to copy the records into
        // the block after any existing records.
        //
        
        // Calculate the byte count of the records to
        // be inserted on this pass through the loop.
        BytesToBeInserted = 
                BytesPerRecord * RecordCountToInsert;
        
        // Copy the records to the table.
        memmove( B->EndOfData,        // To
                 AtRecords,           // From
                 BytesToBeInserted ); // ByteCount
                   
        // Account for the records just copied into the block:
        
        // Update the record counter for the block.
        B->RecordCount  += RecordCountToInsert;
        
        // Update the pointer to the end of the records.
        B->EndOfData += BytesToBeInserted;
        
        // Account for the records just copied into the table.
        T->RecordCount += RecordCountToInsert;
        
        // Reduce the number of records to be copied.
        RecordCount -= RecordCountToInsert;
        
        // Advance the source record pointer.
        AtRecords += BytesToBeInserted;
    }
    
    // Mark the lookaside buffer as empty because the record 
    // structure of the table has changed.
    T->IsLookasideEmpty = 1;
}

/*------------------------------------------------------------
| MakeRecordBlock
|-------------------------------------------------------------
|
| PURPOSE: To make a new record block.
|
| DESCRIPTION: When a RecordBlock record is initially made
| is holds no records. 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 'Next', 'Prev' and 'MyTable' fields are set to
|          zero and will be filled in later when the block is 
|          made part of a table.
|
| HISTORY: 09.29.98 TL From 'MakeExtentBlock'.
|          10.04.98 TL Added 'RecordCount' initialization.
------------------------------------------------------------*/
RecordBlock* 
MakeRecordBlock( 
    u32 RecordsPerBlock, // How many records can be held in 
                         // a block.
                         //
    u32 BytesPerRecord ) // The number of bytes in each record.
{
    RecordBlock* B;
    u32          BlockByteCount;
    
    // Calculate the total size of the memory block that
    // holds the block.
    BlockByteCount = sizeof( RecordBlock ) +
                     RecordsPerBlock * BytesPerRecord;
    
    // Allocate a record for the block.
    B = (RecordBlock*) malloc( BlockByteCount );
    
    // Fill in the fields of the record.
    
    // Clear the block list link fields which will be 
    // filled in when the block is inserted into a table.
    B->Next  = 0;
    B->Prior = 0;
    
    // Clear the reference to the table that refers 
    // to this block for now: this will be filled in 
    // when the block is made part of a table.
    B->MyTable = 0;
    
    // Initially there are no records in the block.
    B->RecordCount = 0;
    
    // Set the RAM address of the first record in the
    // block: the records immediately follow the
    // block header.
    B->FirstRecord =
        ( ((u8*) B ) + sizeof( RecordBlock ) );

    // Set the address that marks the end of the existing 
    // data records in the block, the first byte following 
    // the last record.  Initially there will be no records 
    // in the block.
    B->EndOfData = B->FirstRecord;

    // Set the address that marks the end of the block.
    B->EndOfBlock = ( ((u8*) B ) + BlockByteCount );
    
    // Return the address of the block.
    return( B );
}

/*------------------------------------------------------------
| MakeTable
|-------------------------------------------------------------
|
| PURPOSE: To make a new data table.
|
| DESCRIPTION: Instead of holding data records in a single 
| contiguous memory block, provision is made to separate the 
| table into chunks that can be more easily allocated and to 
| allow for insertion and deletion of records without badly 
| fragmenting memory.
|
| The 'RecordsPerBlock' parameter controls the number of 
| records that can be held in any single memory allocation 
| block. 
|
| If the records in the table should be maintained in order
| then the parameters 'CompareKeyProcedure', 'KeyOffset'
| and 'KeySize' specify the order: these fields should be
| set to zero for unordered tables.  
|
|
| The comparison function supplied in 'CompareKeyProcedure'
| must have this format:
|
|    s32
|    MyCompareFunction( u8* A, u8* B )
|    {
|
|    }
| 
|    where 'A' and 'B' are the addresses of a key field in
|    a record, not the beginning of a record.
|
|    It returns:
|                0 if A = B.
|  positive number if A > B.
|  negative number if A < B. 
|
|  See 'CompareStrings()' for an example.
|
| EXAMPLE: 
|
| NOTE: Use 'DeleteTable()' to free data tables that are no
|       longer useful.
|
| ASSUMES: 
|
| HISTORY: 09.29.98 TL From 'MakeExtentTable'.
|          10.12.98 Revised to bypass general list indirection
|                   for speed.
|          12.01.98 Added emptying of the lookaside table.
------------------------------------------------------------*/
Table* 
MakeTable( 
    u32     BytesPerRecord, // How many bytes are in each
                            // data record.
                            //
    u32     RecordsPerBlock,// How many records should be
                            // held in each block.  This 
                            // controls the separation of 
                            // the table into contiguous
                            // chunks of memory.
                            //
    CompareProc CompareKeyProcedure,
                            // The function that's called to
                            // compare two records in the
                            // table. This function controls
                            // sorting and searching of
                            // ordered tables. 
                            //
                            // Use zero for
                            // 'CompareKeyProcedure' 
                            // if the table isn't ordered.
                            //
    u32     KeyOffset,      // Byte offset from the beginning
                            // of a data record to the field
                            // that holds the sorting key 
                            // value of the record.  Only used
                            // for ordered tables, use zero if
                            // unordered.
                            //
    u32     KeySize )       // Size of the key field in bytes.
                            // Only used for ordered tables,
                            // use zero if unordered.
{
    Table* T;
    RecordBlock* B;
    
    // Allocate a record for the table.
    T = (Table*) malloc( sizeof( Table ) );
    
    // Fill in the fields of the record.
    
    // Set the record size.
    T->BytesPerRecord = BytesPerRecord;
    
    // Set the block size.
    T->RecordsPerBlock = RecordsPerBlock;
    
    // Initially there will be no records in the table.
    T->RecordCount = 0;
    
    // Set the comparison procedure.
    T->CompareKeyProcedure = CompareKeyProcedure;
    
    // Set the key field offset.
    T->KeyOffset = KeyOffset;

    // Set the key field size.
    T->KeySize = KeySize;
    
    // Make a record block able to hold a given number
    // of records but initially it will hold none.
    B = MakeRecordBlock( RecordsPerBlock, BytesPerRecord );
    
    // Connect the link from the block to the table.
    B->MyTable = T;
    
    // Add the block to the block list as the only block.
    T->FirstBlock = B;
    T->LastBlock  = B;
    T->BlockCount = 1;
    
    // Defer building of the block address table until the
    // first search.
    T->BlockAddressTable = 0;

    // Mark the block address table as needing update.
    T->IsBlockAddressTableCurrent = 0;
    
    // Mark the lookaside table as empty.
    T->IsLookasideEmpty = 1;

    // Return the table record address.
    return( T );
}

/*------------------------------------------------------------
| RunMeToDemoTLTable
|-------------------------------------------------------------
|
| PURPOSE: To demonstrate the operation of the TLTable library.
|
| DESCRIPTION: Run this procedure to demonstrate how to make
| and use data tables.  Output is sent to standard output.
|
| To keep this example simple, a simple data record format
| will be used with only one field holding ASCII data so that
| it can be printed out easily.  Keep in mind that any kind of
| fixed-length data record can be used with TLTable.
|
| EXAMPLE: Suppose you have five names no longer than five 
| bytes each that need to be organized in the same place.  
|
| Use TLTable functions to make one table that keeps the names 
| in alphabetical order, and a second table that holds them in 
| any order.  
|
| Show how to process the records in various ways.  Use a 
| blocking factor of three records per block.
|
|        RunMeToDemoTLTable();
|
| Output produced should be like this, with differing addresses:
|
|       ============ BEGIN ORDERED TABLE DEMO =============
|
|       Make an ordered table.
|
|       Insert records into an ordered table.
|
|       List records in ordered table from last to first:
|          Sandy at 7e2a09a
|          Mark  at 7e2a094
|          Lucy  at 7e2a110
|          Dave  at 7e2a10a
|          Bev   at 7e2a104
|
|       List records in ordered table from first to last:
|          Bev   at 7e2a104
|          Dave  at 7e2a10a
|          Lucy  at 7e2a110
|          Mark  at 7e2a094
|          Sandy at 7e2a09a
|
|       Print the second record in ordered table:
|          Dave  at 7e2a10a
|
|       Delete the fourth record in ordered table.
|
|       List records to show deletion of fourth record:
|          Bev   at 7e2a104
|          Dave  at 7e2a10a
|          Lucy  at 7e2a110
|          Sandy at 7e2a094
|
|       Find the record that contains the string 'Dave  '.
|          Dave  at 7e2a10a
|
|       Delete the ordered table.
|
|       ============= END ORDERED TABLE DEMO ==============
|
|       =========== BEGIN UNORDERED TABLE DEMO ============
|
|       Insert the first record into the table:
|          Mark  at 7e2a024
|
|       Insert a record as last:
|          Mark  at 7e2a024
|          Dave  at 7e2a02a
|
|       Insert a record as first:
|          Lucy  at 7e2a024
|          Mark  at 7e2a02a
|          Dave  at 7e2a030
|
|       Insert two records after the first one:
|          Lucy  at 7e2a024
|          Sandy at 7e2a02a
|          Bev   at 7e2a030
|          Mark  at 7e2a094
|          Dave  at 7e2a09a
|
|       Delete the first three records:
|          Mark  at 7e2a094
|          Dave  at 7e2a09a
|
|       Delete the unordered table.
|
|       ============ END UNORDERED TABLE DEMO =============
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 10.20.98 TL.
------------------------------------------------------------*/
void
RunMeToDemoTLTable()
{

    Table*      MyOrderedTable;
    Table*      MyUnorderedTable;
    u32         BytesPerRecord;
    u32         RecordsPerBlock;
    u32         KeyOffset;
    u32         KeySize;
    ThatRecord  R;
    s32         C;
    
    // Use 6 byte records to allow for five characters in
    // a name and a string terminator.
    BytesPerRecord = 6;
    
    // Set the blocking factor for the table to three records
    // per block.
    RecordsPerBlock = 3;
    
    // Treat the whole name record as a key.
    KeyOffset = 0;
    
    // Use a five byte key: this parameter is used only
    // by comparison functions that rely on being able to
    // look up the key size of a table, which is not the
    // case here.
    KeySize = 5;

    printf( "\n============ BEGIN ORDERED TABLE DEMO =============\n" );

    printf( "\nMake an ordered table.\n" );
        
    // Make an ordered table.
    MyOrderedTable =
        MakeTable( 
            BytesPerRecord, // How many bytes are in each
                            // data record.
                            //
            RecordsPerBlock,// How many records should be
                            // held in each block.  This 
                            // controls the separation of 
                            // the table into contiguous
                            // chunks of memory.
                            //
            (CompareProc) strcmp,   
                            // The function that's called to
                            // compare two records in the
                            // table. This function controls
                            // sorting and searching of
                            // ordered tables. 
                            //
                            // Use zero for
                            // 'CompareKeyProcedure' 
                            // if the table isn't ordered.
                            //
            KeyOffset,      // Byte offset from the beginning
                            // of a data record to the field
                            // that holds the sorting key 
                            // value of the record.  Only used
                            // for ordered tables, use zero if
                            // unordered.
                            //
            KeySize );      // Size of the key field in bytes.
                            // Only used for ordered tables,
                            // use zero if unordered.

    printf( "\nInsert records into an ordered table.\n" );

    // Insert the names into the ordered table, one at a time.
    InsertOrderedRecords( 
        MyOrderedTable,     // The table where the records go.
                            //
        (u8*) "Mark ",      // Where the records to be 
                            // inserted are.  If there is more
                            // than one record they are
                            // adjacent in memory.
                            //
        1 );                // How many records are to be
                            // inserted.

    InsertOrderedRecords( MyOrderedTable, (u8*) "Dave ",  1 );               
    InsertOrderedRecords( MyOrderedTable, (u8*) "Lucy ",  1 );               
    InsertOrderedRecords( MyOrderedTable, (u8*) "Sandy",  1 );               
    InsertOrderedRecords( MyOrderedTable, (u8*) "Bev  ",  1 );               

    printf( "\nList records in ordered table from last to first:\n" );
    
    // Refer to the last record in the table.
    ToLastRecord( MyOrderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToPriorRecord( &R );
    }
    
    printf( "\nList records in ordered table from first to last:\n" );
    
    // Refer to the first record in the table.
    ToFirstRecord( MyOrderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    printf( "\nPrint the second record in ordered table:\n" );
    
    // Refer to the second record: zero-based index.
    ToNthRecord( MyOrderedTable, &R, 1 );
    
    // Print out the record string.
    printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
    printf( "\nDelete the fourth record in ordered table.\n" );
    
    // Refer to the third record: zero-based index.
    ToNthRecord( MyOrderedTable, &R, 3 );
    
    // Delete the record.
    DeleteRecords( &R, 1 );
    
    printf( "\nList records to show deletion of fourth record:\n" );
    
    // Refer to the first record in the table.
    ToFirstRecord( MyOrderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    printf( "\nFind the record that contains the string 'Dave  '.\n" );
    
    // Locate the record.
    C = FindRecord( 
         MyOrderedTable,  // The record table.
                          //
         (u8*) "Dave ",   // Address of the search key.
                          //
         &R );            //
    
    // If the record was found.
    if( C == 0 )
    {
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    }
    
    printf( "\nDelete the ordered table.\n" );
    
    // Discard the table.
    DeleteTable( MyOrderedTable );

    printf( "\n============= END ORDERED TABLE DEMO ==============\n" );
    
    printf( "\n=========== BEGIN UNORDERED TABLE DEMO ============\n" );
    
    // Make an unordered table.
    MyUnorderedTable =
        MakeTable( 
            BytesPerRecord, // How many bytes are in each
                            // data record.
                            //
            RecordsPerBlock,// How many records should be
                            // held in each block.  This 
                            // controls the separation of 
                            // the table into contiguous
                            // chunks of memory.
                            //
            0,              // Use zero for
                            // 'CompareKeyProcedure' 
                            // if the table isn't ordered.
                            //
            0,              // Only used for ordered tables, 
                            // use zero if unordered.
                            //
            0 );            // Only used for ordered tables,
                            // use zero if unordered.

    printf( "\nInsert the first record into the table:\n" );

    // Insert the record.
    InsertRecordsFirst( MyUnorderedTable, (u8*) "Mark ", 1 );  

    // Refer to the first record in the table.
    ToFirstRecord( MyUnorderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    printf( "\nInsert a record as last:\n" );

    // Insert the record.
    InsertRecordsLast( MyUnorderedTable, (u8*) "Dave ", 1 );  

    // Refer to the first record in the table.
    ToFirstRecord( MyUnorderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    printf( "\nInsert a record as first:\n" );

    // Insert the record.
    InsertRecordsFirst( MyUnorderedTable, (u8*) "Lucy ", 1 );  

    // Refer to the first record in the table.
    ToFirstRecord( MyUnorderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    printf( "\nInsert two records after the first one:\n" );

    // Refer to the first record in the table.
    ToFirstRecord( MyUnorderedTable, &R );
    
    // Insert a new record after the first one.
    InsertRecordsAfter( &R, (u8*) "Sandy\0Bev  ", 2 );              

    // Refer to the first record in the table.
    ToFirstRecord( MyUnorderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    printf( "\nDelete the first three records:\n" );

 
    // Refer to the first record in the table.
    ToFirstRecord( MyUnorderedTable, &R );
    
    // Delete the records.
    DeleteRecords( &R, 3 );
    
    // Refer to the first record in the table.
    ToFirstRecord( MyUnorderedTable, &R );
    
    // For each record.
    while( R.TheRecord )
    {
        // Print out the record string.
        printf( "   %s at %lx\n", (s8*) R.TheRecord, R.TheRecord );
    
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    printf( "\nDelete the unordered table.\n" );
    
    // Discard the table.
    DeleteTable( MyUnorderedTable );
    
    printf( "\n============ END UNORDERED TABLE DEMO =============\n" );
}

/*------------------------------------------------------------
| ShiftRecordsToNextBlock
|-------------------------------------------------------------
|
| PURPOSE: To shift up to a given number of records from one 
|          block to the beginning of the next block.
|
| DESCRIPTION: Shifts some records from the current block to
| the next one, taking up any slack in the current block.
|
| Returns the number of bytes that were shifted, possibly
| none if there is no next block or no room in the next 
| block.
|
| EXAMPLE:     
|
|        n = ShiftRecordsToNextBlock( R, Count );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 10.14.98 TL From 'ShiftRecordsToPriorBlock'.
|          10.16.98 Corrected to copy only the last so many
|                   records from the source in the case where 
|                   all the desired records can't fit in the 
|                   next block.
|          10.19.98 Fixed calculation of 'EndOfDataShifted'.
------------------------------------------------------------*/
u32
ShiftRecordsToNextBlock( ThatRecord* R, u32 RecordCount )
{
    RecordBlock*    A;
    RecordBlock*    B;
    Table*          T;
    u32             HowManyRecordsToShift;          
    u32             HowManyBytesFollow;
    u32             HowManyBytesToShift;
    u32             HowManyBytesToShiftInB;
    u32             FreeRecordsInB;
    u32             BytesPerRecord;
    u8*             EndOfDataShifted;
    u8*             AtRecordInBlockA;
    
    // Refer to the first block as 'A'.
    A = R->TheBlock;
    
    // Refer to the second block as 'B'.
    B = A->Next;
    
    // If there is a next block and there are records to shift.
    if( B && RecordCount )
    {
        // Refer to the table.
        T = A->MyTable;
        
        // Get the number of bytes per record.
        BytesPerRecord = T->BytesPerRecord;
        
        // Calculate the space available for records
        // in the prior block.
        FreeRecordsInB = T->RecordsPerBlock - B->RecordCount;
        
        // Calculate the number of records to shift.
        HowManyRecordsToShift =  
            min( RecordCount, FreeRecordsInB );
            
        // If there are records to be shifted.
        if( HowManyRecordsToShift )
        {
            // Calculate the number of bytes to shift.
            HowManyBytesToShift = 
                HowManyRecordsToShift * BytesPerRecord;
                
            // Calculate how many bytes in B need to be 
            // shifted towards the end of the block.
            HowManyBytesToShiftInB = (u32)
                ( B->EndOfData - B->FirstRecord );
            
            // If there are records in B.
            if( HowManyBytesToShiftInB )
            {
                // Make room for the new records in B.
                memmove( B->FirstRecord + HowManyBytesToShift, // To
                         B->FirstRecord,                       // From
                         (u32) HowManyBytesToShiftInB );       // ByteCount
            }
            
            // Calculate the address of the first record to be
            // copied from the source block, A.  
            //
            // If there isn't room in block B for all of the requested 
            // records, just copy the last so many records that will 
            // fit in block B.
            AtRecordInBlockA = 
                R->TheRecord + 
                ( RecordCount * BytesPerRecord ) -
                HowManyBytesToShift;
                            
            // Copy the records from A to B.
            memmove( B->FirstRecord,        // To
                     AtRecordInBlockA,      // From
                     (u32) HowManyBytesToShift ); // ByteCount
                       
            // Adjust the end of the data in B.
            B->EndOfData += HowManyBytesToShift;
            
            // Adjust the record count in B.
            B->RecordCount += HowManyRecordsToShift;
            
            // Calculate the address of the byte after
            // the last shifted record.
            EndOfDataShifted = 
                AtRecordInBlockA + HowManyBytesToShift;
                
            // Calculate how many bytes follow the ones 
            // moved out of A.
            HowManyBytesFollow = (u32)
                ( A->EndOfData - EndOfDataShifted );
            
            // If there are records following the ones moved out
            // of A, in A.
            if( HowManyBytesFollow )
            {
                // Move the records following the ones moved
                // in A to take up the slack.
                memmove( R->TheRecord,        // To
                         EndOfDataShifted,    // From
                         (u32) HowManyBytesFollow );// ByteCount
            }
                      
            // Reduce the data end marker in A.     
            A->EndOfData -= HowManyBytesToShift;

            // Reduce the record count in A.
            A->RecordCount -= HowManyRecordsToShift;
        }
        
        // Return the number of records shifted.
        return( HowManyBytesToShift );
    }
    else // No next block.
    {
        // So no bytes were shifted.
        return( 0 );
    }
}

/*------------------------------------------------------------
| ShiftRecordsToPriorBlock
|-------------------------------------------------------------
|
| PURPOSE: To shift up to a given number of records from one 
|          block to the end of the prior block.
|
| DESCRIPTION: Shifts some records from the current block to
| the prior one, taking up any slack in the current block.
|
| Returns the number of bytes that were shifted, possibly
| none if there was no prior block or no room in the prior 
| block.
|
| EXAMPLE:     
|
|        n = ShiftRecordsToPriorBlock( R, Count );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 10.14.98 TL
------------------------------------------------------------*/
u32
ShiftRecordsToPriorBlock( ThatRecord* R, u32 RecordCount )
{
    RecordBlock*    A;
    RecordBlock*    B;
    Table*          T;
    u32             HowManyRecordsToShift;          
    u32             HowManyBytesFollow;
    u32             HowManyBytesToShift;
    u32             FreeRecordsInA;
    u8*             EndOfDataShifted;
    
    // Refer to the second block as 'B'.
    B = R->TheBlock;
    
    // Refer to the first block as 'A'.
    A = B->Prior;
    
    // If there is a prior block and there are records to shift.
    if( A && RecordCount )
    {
        // Refer to the table.
        T = B->MyTable;
        
        // Calculate the space available for records
        // in the prior block.
        FreeRecordsInA = T->RecordsPerBlock - A->RecordCount;
        
        // Calculate the number of records to shift.
        HowManyRecordsToShift =  
            min( RecordCount, FreeRecordsInA );
            
        // If there are records to be shifted.
        if( HowManyRecordsToShift )
        {
            // Calculate the number of bytes to shift.
            HowManyBytesToShift = 
                HowManyRecordsToShift * R->BytesPerRecord;
            
            // Copy the records from B to A.
            memmove( A->EndOfData,          // To
                     R->TheRecord,          // From
                     (u32) HowManyBytesToShift ); // Count
                       
            // Adjust the end of the data in A.
            A->EndOfData += HowManyBytesToShift;
            
            // Adjust the record count in A.
            A->RecordCount += HowManyRecordsToShift;
            
            // Calculate the address of the byte after
            // the last shifted record.
            EndOfDataShifted = 
                R->TheRecord + HowManyBytesToShift;
                
            // Calculate how many bytes follow the ones 
            // moved out of B.
            HowManyBytesFollow = (u32)
                ( B->EndOfData - EndOfDataShifted );
                
            // Move the records following the ones moved
            // in B to take up the slack.
            memmove( R->TheRecord,         // To
                     EndOfDataShifted,     // From
                     (u32) HowManyBytesFollow ); // Count
                       
            // Reduce the data end marker in B.     
            B->EndOfData -= HowManyBytesToShift;

            // Reduce the record count in B.
            B->RecordCount -= HowManyRecordsToShift;
        }
        
        // Return the number of records shifted.
        return( HowManyBytesToShift );
    }
    else // No prior block.
    {
        // So no bytes were shifted.
        return( 0 );
    }
}

/*------------------------------------------------------------
| ToFirstRecord
|-------------------------------------------------------------
|
| PURPOSE: To refer to the first record in a table.
|
| DESCRIPTION: Sets 'R' to refer to the first record in the
| table.  If there is no first record then 'R->TheRecord' 
| will hold zero.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 09.29.98 TL From 'ToFirstExtent'.
|          10.12.98 TL Revised to bypass general list 
|                      indirection.
------------------------------------------------------------*/
void
ToFirstRecord( Table* T, ThatRecord* R )
{
    RecordBlock* B;

    // Set the table address in the record reference, 'R'.
    R->TheTable = T;
    
    // Refer to the first block in the table: there
    // will always be one.
    B = T->FirstBlock;
    
    // Set the block address in the record reference.
    R->TheBlock = B;
    
    // If there is at least one record in the table.
    if( T->RecordCount )
    {   
        // Refer to the first record in the block.
        R->TheRecord = B->FirstRecord;
    }
    else // No records in the table.
    {
        // Signal that the record is missing.
        R->TheRecord = 0;
    }
    
    // Set the number of bytes per record to speed record
    // traversal.
    R->BytesPerRecord = T->BytesPerRecord;
}

/*------------------------------------------------------------
| ToFirstRecordInBlock
|-------------------------------------------------------------
|
| PURPOSE: To refer to the first record of the given block.
|
| DESCRIPTION: Sets 'R' fields to refer to the first record 
| in the given block.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: There is at least one record in the block.
|
| HISTORY: 09.29.98 TL From 'ToFirstExtentInBlock'.
------------------------------------------------------------*/
void
ToFirstRecordInBlock( RecordBlock* B, ThatRecord* R )
{
    // Set the table reference.
    R->TheTable = (Table*) B->MyTable;

    // Set the block reference.
    R->TheBlock = B;

    // Refer to the first record in the block.
    R->TheRecord = B->FirstRecord;
    
    // Set the number of bytes per record to speed record
    // traversal.
    R->BytesPerRecord = R->TheTable->BytesPerRecord;
}   

/*------------------------------------------------------------
| ToLastRecord
|-------------------------------------------------------------
|
| PURPOSE: To refer to the last record in the table.
|
| DESCRIPTION: Sets 'R' to refer to the last record in the
| table.  If there is no last record then 'R->TheRecord' 
| will hold zero.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: There will always be at least one record block
|          in the table.
|
| HISTORY: 09.29.98 TL From 'ToLastExtent'.
|          09.30.98 TL Added 'R->BytesPerRecord'.
|          10.12.98 TL Revised to bypass general list 
|                      indirection.
------------------------------------------------------------*/
void
ToLastRecord( Table* T, ThatRecord* R )
{
    RecordBlock* B;
    u32          BytesPerRecord;
    
    // Get the bytes per record.
    BytesPerRecord = T->BytesPerRecord;

    // Set the number of bytes per record to speed record
    // traversal.
    R->BytesPerRecord = BytesPerRecord;

    // Set the table address in the record reference, 'R'.
    R->TheTable = T;
    
    // Refer to the last block in the table: there
    // will always be one.
    B = T->LastBlock;
        
    // Set the block address in 'R'.
    R->TheBlock = B;
        
    // If there is at least one record in the table.
    if( T->RecordCount )
    {   
        // Refer to the last record in the block.
        R->TheRecord = B->EndOfData - BytesPerRecord;
    }
    else // No records in the table.
    {
        // Signal that the record is missing.
        R->TheRecord = 0;
    }
}

/*------------------------------------------------------------
| ToLastRecordInBlock
|-------------------------------------------------------------
|
| PURPOSE: To refer to the last record of the current 
|          block.
|
| DESCRIPTION: Sets 'R' fields to refer to the last record 
| in the given block.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: There is at least one record in the block.
|
| HISTORY: 09.30.98 TL From 'ToLastExtentInBlock'.
------------------------------------------------------------*/
void
ToLastRecordInBlock( RecordBlock* B, ThatRecord* R )
{
    Table*  T;
    u32     BytesPerRecord;
    
    // Refer to the table holding the block.
    T = (Table*) B->MyTable;
    
    // Get the bytes per record.
    BytesPerRecord = T->BytesPerRecord;
    
    // Save the number of bytes per record.
    R->BytesPerRecord = BytesPerRecord;

    // Set the table reference.
    R->TheTable = T;

    // Set the block reference.
    R->TheBlock = B;

    // Refer to the last record in this block.
    R->TheRecord = B->EndOfData - BytesPerRecord;
}

/*------------------------------------------------------------
| ToNextRecord
|-------------------------------------------------------------
|
| PURPOSE: To traverse to the next record from the current
|          one.
|
| DESCRIPTION: Updates all the fields of the given reference
| to refer to the next record in the table, such that 'next' 
| means towards the end of the table.
|
| Returns with 'TheRecord' field set to zero if there is no
| next record.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: The given reference is to a valid record.
|          
|
| HISTORY: 09.30.98 TL From 'ToPriorExtent'.
|          10.04.98 Made more efficient.
|          10.12.98 Removed 'Item' indirection for speed.
------------------------------------------------------------*/
void
ToNextRecord( ThatRecord* R )
{
    RecordBlock* B;
    
    // Refer to the block that holds the record.
    B = R->TheBlock;
    
    // Advance to the next record in this block.
    R->TheRecord += R->BytesPerRecord;
        
    // If the end of the block has been reached.
    if( R->TheRecord >= B->EndOfData )
    {
        // Refer to the next block.
        B = B->Next;
        
        // If there is a next record block.
        if( B )
        {
            // Set the block address of the record to refer to 
            // the block.
            R->TheBlock = B;
            
            // Refer to the first record in the block.
            R->TheRecord = B->FirstRecord;
        }
        else // No next block.
        {
            // Signal that no next record exists.
            R->TheRecord = 0;
        }
    }
}

/*------------------------------------------------------------
| ToNthNextRecord
|-------------------------------------------------------------
|
| PURPOSE: To traverse to the nth next record from the current
|          one.
|
| DESCRIPTION: Updates all the fields of the given record to 
| refer to the next nth record in the table, such that 'next' 
| means towards the last record in the table.
|
| Returns with 'TheRecord' field set to zero if there is no
| nth next record.
|
| EXAMPLE: 
|
| NOTE:
|
| ASSUMES: The current record fields are valid.
|
| HISTORY: 12.01.98 TL From 'ToNthPriorRecord()'.
------------------------------------------------------------*/
void
ToNthNextRecord( ThatRecord* R, u32 n )
{
    RecordBlock* B;
    u8*          TheRecord;
    u32          BytesToGo, BytesInThisBlock;
    
    // Refer to the record using a local variable for speed.
    TheRecord = R->TheRecord;
    
    // Refer to the block that holds the record.
    B = R->TheBlock;

    // Calculate the total number of bytes to be traversed.
    BytesToGo = n * R->BytesPerRecord;

TryThisBlock:

    // Calculate the byte offset of the current record from 
    // the end of the current block.
    BytesInThisBlock = (u32) ( B->EndOfData - TheRecord ); 
    
    // If the target record is in the current block.
    if( BytesInThisBlock > BytesToGo )
    {
        // Calculate the new record address.
        R->TheRecord = TheRecord + BytesToGo;
        
        // Set the block address.
        R->TheBlock  = B;
        
        // All done.
        return;
    }
    
    // Reduce the number of bytes to go by the number in 
    // the current block.
    BytesToGo -= BytesInThisBlock;
        
    // Refer to the next block.
    B = B->Next;
            
    // If there is a next record block.
    if( B )
    {
        // Set the current record to the first record in 
        // the current block.
        TheRecord = B->FirstRecord;
        
        // Now see if the target record is in this block.
        goto TryThisBlock;
    }
    
    // No next block.
    
    // Signal that no next record exists.
    R->TheRecord = 0;
}

/*------------------------------------------------------------
| ToNthPriorRecord
|-------------------------------------------------------------
|
| PURPOSE: To traverse to the nth prior record from the current
|          one.
|
| DESCRIPTION: Updates all the fields of the given record to 
| refer to the prior record in the table, such that 'prior' 
| means towards the first record in the table.
|
| Returns with 'TheRecord' field set to zero if there is no
| nth prior record.
|
| EXAMPLE: 
|
| NOTE:
|
| ASSUMES: The current record fields are valid.
|
| HISTORY: 12.01.98 TL From 'ToPriorRecord()'.
------------------------------------------------------------*/
void
ToNthPriorRecord( ThatRecord* R, u32 n )
{
    RecordBlock* B;
    u8*          TheRecord;
    u32          BytesToGo, BytesInThisBlock;
    
    // Refer to the record using a local variable for speed.
    TheRecord = R->TheRecord;
    
    // Refer to the block that holds the record.
    B = R->TheBlock;

    // Calculate the total number of bytes to be traversed.
    BytesToGo = n * R->BytesPerRecord;

TryThisBlock:

    // Calculate the byte offset of the current record from 
    // the beginning of the current block.
    BytesInThisBlock = (u32) ( TheRecord - B->FirstRecord ); 
    
    // If the target record is in the current block.
    if( BytesInThisBlock >= BytesToGo )
    {
        // Calculate the new record address.
        R->TheRecord = TheRecord - BytesToGo;
        
        // Set the block address.
        R->TheBlock  = B;
        
        // All done.
        return;
    }
    
    // Reduce the number of bytes to go by the number in 
    // the current block.
    BytesToGo -= BytesInThisBlock;
        
    // Refer to the prior block.
    B = B->Prior;
            
    // If there is a prior record block.
    if( B )
    {
        // Set the current record to just after the last 
        // record in the current block.
        TheRecord = B->EndOfData;
        
        // Now see if the target record is in this block.
        goto TryThisBlock;
    }
    
    // No prior block.
    
    // Signal that no prior record exists.
    R->TheRecord = 0;
}

/*------------------------------------------------------------
| ToNthRecord
|-------------------------------------------------------------
|
| PURPOSE: To refer to the nth record in a table.
|
| DESCRIPTION: Sets 'R' to refer to the nth record in the
| table where n = 0 for the first record, 1 for the second 
| and so on. 
|
| If there is no nth record then 'R->TheRecord' will hold 
| zero.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 10.06.98 TL From 'ToFirstExtent' and 'FindNthItem'.
|          10.07.98 Fixed error where last record was ruled
|                   as out of bounds.
|          10.12.98 Removed general list indirection for 
|                   speed.
|          12.01.98 Added lookaside buffer, variable 
|                   direction traversal and relative traversal.
------------------------------------------------------------*/
void
ToNthRecord( Table* T, ThatRecord* R, u32 n )
{
    u32          BytesPerRecord;
    u32          i, j;
    u32          Offset, OffsetN;
    u32*         L;
    u32          RecordCount, EndDiff;
    u32          NearestDiff, Diff;
    u32          NearestJ;
    u32          NearestIndex;
    u8*          AtLookIndex;
    u8*          AtLookBlock;
    u8*          AtLookRecord;
    
    // Refer to the base of the lookaside index table.
    AtLookIndex = (u8*) &T->LookIndex;
    
    // Refer to the base of the lookaside block table.
    AtLookBlock = (u8*) &T->LookBlock;
    
    // Refer to the base of the lookaside record table.
    AtLookRecord = (u8*) &T->LookRecord;
    
    // Calculate the lookaside table index for 'n' using the
    // low four bits of 'n' as an index.
    i = n & 0x0f;
    
    // Calculate the lookaside table entry byte offset.
    Offset = i << 2;
    
    // Set the table address in the record reference, 'R'.
    R->TheTable = T;

    // Get the number of bytes per record.
    BytesPerRecord = T->BytesPerRecord;

    // Set the number of bytes per record in the reference
    // to speed possible traversal later.
    R->BytesPerRecord = BytesPerRecord;

    // If the lookaside buffer is empty.
    if( T->IsLookasideEmpty )
    {
        // Mark all the index numbers in the lookaside index
        // array as invalid.
        for( j = 0; j < 16; j++ )
        {
            ((u32*)AtLookIndex)[j] = 0xFFFFFFFF;
        }
        
        // Get the table record count.
        RecordCount = (u32) T->RecordCount;
        
        // If N exceeds the number of records in the table.
        if( n >= RecordCount )
        {
            // Signal that the record is missing.
            R->TheRecord = 0;
        }
        else // The record is in the table.
        {
            // Calculate the number of records from the end of 
            // the table to 'n'.
            EndDiff = (RecordCount - 1) - n;
            
            // If the record is closer to the end of the table
            // than the beginning.
            if( EndDiff < n )
            {
                // Go to the end.
                ToLastRecord( T, R );
                
                // If n isn't the last record.
                if( EndDiff )
                {
                    // Travel back.
                    ToNthPriorRecord( R, EndDiff );
                }
            }
            else // Closer to the beginning.
            {
                // Go to the first record.
                ToFirstRecord( T, R );
                
                // If n isn't the first record.
                if( n )
                {
                    // Travel forward.
                    ToNthNextRecord( R, n );
                }
            }
        }
    }
    else // There is at least one record in the lookaside buffer.
    {
        //
        // T R Y   L O O K A S I D E   B U F F E R
        //     F O R   E X A C T   R E C O R D
        //
        
        // If the record index is in the lookaside buffer.
        if( *( (u32*) ( AtLookIndex + Offset ) ) == n )
        {
            // Set the block address in the return record.
            R->TheBlock = 
                *( (RecordBlock**) ( AtLookBlock + Offset ) );
        
            // Set the record address in the return record.
            R->TheRecord = 
                *( (u8**) ( AtLookRecord + Offset ) );
        
            // All done.
            return;
        }
    
        //
        // S C A N   L O O K A S I D E   B U F F E R
        //  F O R   N E A R E S T   N E I G H B O R
        //
        
        // Refer to the first entry in the lookaside index buffer.
        L = (u32*) AtLookIndex;
        
        // Set the default nearest record index value to the first
        // record index in the lookaside index table and advance 'L'.
        NearestIndex = *L++;
        
        // Set the default nearest lookaside entry index to
        // the first record.
        NearestJ = 0;
        
        // Calculate the difference from the nearest to the
        // target index.
        if( NearestIndex > n )
        {
            NearestDiff = NearestIndex - n;
        }
        else // n >= NearestIndex.
        {
            NearestDiff = n - NearestIndex;
        }
        
        // Scan the table.
        for( j = 1; j < 16; j++ )
        {
            // Get the record index number and advance 'L'.
            i = *L++;
            
            // Calculate the difference between record index 
            // 'i' and the target record index, 'n'.
            if( i > n )
            {
                Diff = i - n;
            }
            else // n >= i.
            {
                Diff = n - i;
            }
            
            // If the new difference is less than the current.
            if( Diff < NearestDiff )
            {
                // Make this the new nearest.
                NearestIndex = i;
                NearestDiff  = Diff;
                NearestJ     = j;
            }
        }
    
        // Calculate the byte offset to the entry.
        OffsetN = NearestJ << 2;
        
        // Set the block address in the return record.
        R->TheBlock = 
            *( (RecordBlock**) ( AtLookBlock + OffsetN ) );
    
        // Set the record address in the return record.
        R->TheRecord = 
            *( (u8**) ( AtLookRecord + OffsetN ) );
    
        // If nearest follows 'n' in the table.
        if( n < NearestIndex )
        {
            // Move to back to the target record.
            ToNthPriorRecord( R, NearestDiff );
        }
        else // 'n' follows nearest.
        {
            // Move forward to the target record.
            ToNthNextRecord( R, NearestDiff );
        }
    }
    
    // If a valid record was found.
    if( R->TheRecord )
    {
        // Mark the lookaside buffer as having at least one record.
        T->IsLookasideEmpty = 0;
        
        // Put record index into lookaside buffer.
        *( (u32*) ( AtLookIndex + Offset ) ) = n;
 
        // Put block address into lookaside buffer.
        *( (RecordBlock**) ( AtLookBlock + Offset ) ) = R->TheBlock;
    
        // Put record address into lookaside buffer.
        *( (u8**) ( AtLookRecord + Offset ) ) = R->TheRecord;
    }
}

/*------------------------------------------------------------
| ToPriorRecord
|-------------------------------------------------------------
|
| PURPOSE: To traverse to the prior record from the current
|          one.
|
| DESCRIPTION: Updates all the fields of the given record to 
| refer to the prior record in the table, such that 'prior' 
| means towards the first record in the table.
|
| Returns with 'TheRecord' field set to zero if there is no
| prior record.
|
| EXAMPLE: 
|
| NOTE:
|
| ASSUMES: The current record fields are valid.
|
| HISTORY: 09.30.98 TL From 'ToNextRecord'.
|          10.04.98 Made more efficient.
|          10.12.98 Removed general list indirection for 
|                   speed.
------------------------------------------------------------*/
void
ToPriorRecord( ThatRecord* R )
{
    RecordBlock* B;
    
    // Refer to the block that holds the record.
    B = R->TheBlock;
    
    // Go back one to the prior record in the same block.
    R->TheRecord -= R->BytesPerRecord;
 
    // If the current record falls in the prior block.
    if( R->TheRecord < B->FirstRecord )
    {
        // Refer to the prior block.
        B = B->Prior;
        
        // If there is a prior record block.
        if( B )
        {
            // Set the block address of the record to refer to 
            // the block.
            R->TheBlock = B;
            
            // Refer to the last record in the block.
            R->TheRecord = B->EndOfData - R->BytesPerRecord;
        }
        else // No prior block.
        {
            // Signal that no prior record exists.
            R->TheRecord = 0;
        }
    }
}

/*------------------------------------------------------------
| ValidateTable
|-------------------------------------------------------------
|
| PURPOSE: To validate a table.
|
| DESCRIPTION: Returns if it's a valid table, else calls the 
|              debugger to report the specific error.  
|
| Performs the following tests:
|
|   1. The record count of a block must be consistent with
|      the end of records marker for the block.
|
|   2. The accumulated total for record count must tally with 
|      the total in the table.
|
|   3. If the table is ordered, adjacent records must be
|      in order.
|
|   4. Forward and back links must be consistent.
|
|   5. Links from blocks to table must be valid.
|
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: Not called within 'ToFirstRecord()'.
|
| HISTORY: 10.06.98 TL From 'ValidateExtentTable'.
------------------------------------------------------------*/
void
ValidateTable( Table* T )
{
    ThatRecord   Q;
    ThatRecord   R;
    u32          TotalRecords; 
    RecordBlock* B;
    RecordBlock* LastBlock;
    s32          C;
    u32          BytesPerRecord;
    u32          ImpliedRecordCount;
    
    // Get the number of bytes per record.
    BytesPerRecord = T->BytesPerRecord;
    
    // Clear the validation totals.
    TotalRecords = 0; 
    
    // Start with the first record.
    ToFirstRecord( T, &R );
    
    // Start the prior record reference to be
    // the same as the first record.
    Q = R;
    
    // Clear the block change detector.
    LastBlock = 0;
    
    // For each record in the table.
    while( R.TheRecord )
    {
        // Refer to the current block.
        B = R.TheBlock;
        
        // Verify that the block is valid.
        if( B->MyTable != T )
        {
            // Table link error.
            Debugger();
        }
        
        // If there is a prior record.
        if( Q.TheRecord != R.TheRecord )
        {
            // If the table is an ordered table.
            if( T->CompareKeyProcedure )
            {
                // Compare the key of the last record to
                // the key in this record, R.
                C = CompareKeyToRecord( 
                      Q.TheRecord + T->KeyOffset,  // Address of the search key.
                                                   //
                      (u8*) &R );   // Reference to a data record in a table.

                // If Q follows R.
                if( C > 0 )
                {
                    // Dump the table.
                    DumpTable( T );
                    
                    // Out of order error.
                    Debugger();
                }
            }
        }
            
        // If there is a block change.
        if( B != LastBlock )
        {
            // If there is a prior block.
            if( B->Prior )
            {
                // If the link from B to prior to next doesn't refer to B.
                if( B->Prior->Next != B )
                {
                    // Block link error.
                    Debugger();
                }
            }
            
            // Count the implied records in the block.
            ImpliedRecordCount = 
                ( B->EndOfData - B->FirstRecord ) / BytesPerRecord;
            
            // If the record count in the block doesn't match.
            if( B->RecordCount != ImpliedRecordCount )
            {
                // Block record count error.
                Debugger();
            }
            
            // Make this the last block.
            LastBlock = B;
        }
        
        // Increment the total number of records.
        TotalRecords++;
        
        // Regard the current record as the old one.
        Q = R;
        
        // Advance to the next record.
        ToNextRecord( &R );
    }
    
    // If the table record count doesn't tally with traveral
    // total.
    if( T->RecordCount != TotalRecords )
    {
        // Record count error.
        Debugger();
    }
}
