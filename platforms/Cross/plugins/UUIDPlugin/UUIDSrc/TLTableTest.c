/*------------------------------------------------------------
| TLTableTest.c
|-------------------------------------------------------------
|
| PURPOSE: To test and demonstrate the use of the 'TLTable'
|          functions.
|
| DESCRIPTION: TLTable functions are validated relative to
| TLList functions which must already have been validated:
| see 'TLListTest.c'.
|
| NOTE: 
|
| HISTORY: 12.31.98 From 'TLListTest.c'.
------------------------------------------------------------*/
#include "TLTarget.h" // Include this first.

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
     
#include "TLTypes.h"
#include "TLBuf.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"
#include "TLStrings.h"
#include "TLList.h"
#include "TLTesting.h"
#include "TLRandom.h"  

#if macintosh
#include "TimePPC.h"
#endif // macintosh

#include "TLTable.h"

u32     IsTableAndListEquivalent( Table*, List* );
void    TestOrderedTable();
void    TestUnorderedTable();

/*------------------------------------------------------------
| IsTableAndListEquivalent
|-------------------------------------------------------------
|
| PURPOSE: To test if a table of records and a list of records 
|          are logically equivalent, meaning that they contain
|          the same data, in the same order.
|
| DESCRIPTION: Compares each record in a given table with the 
| corresponding records in a list to make sure that they 
| contain the same data.   
|
| Debugging code prints where any mismatch occurs.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: Table record length is the same as the record 
|          length for items in the list.
|
|          If debugging is enabled, the records are assumed
|          to be zero-terminated ASCII strings.
|
| HISTORY: 10.06.98 TL
------------------------------------------------------------*/
u32  
IsTableAndListEquivalent( Table* T, List* L )
{
    ThatRecord  R;
    s32         BytesPerRecord, i;
    s32         C;
    
    // Get the number of bytes in each record.
    BytesPerRecord = T->BytesPerRecord;
    
    // If the table record count differs from the list.
    if( T->RecordCount != L->ItemCount )
    {
        // Then the table and list aren't equivalent.
        return( 0 );
    }
    
    // Refer to the first record in the table.
    ToFirstRecord( T, &R );
    
    // Refer to the first item in the list. 
    ReferToList( L );
    
    // Start the item counter at zero.
    i = 0;
    
    // For each record in the list.
    while( TheItem )
    {       
        // Compare the list record and the table record.
        C = CompareBytes( TheDataAddress,
                          BytesPerRecord, 
                          R.TheRecord, 
                          BytesPerRecord );
                          
        // If the records differ.
        if( C )
        {
            // Output the error.
            printf( "List/Table mismatch at record %d.\n", i );
            printf( "   Table Record: %s\n", (s8*) R.TheRecord );
            printf( "   List  Record: %s\n", (s8*) TheDataAddress );
              
            // Print out a description of the table.
            DumpTable( T );     
            
            // Refer to the prior list.
            RevertToList();
            
            // Return 0 to indicate a mismatch.
            return( 0 );
        }
        
        // Advance to the next record in the list.
        ToNextItem();
        
        // Advance to the next record in the table.
        ToNextRecord( &R );
        
        // Increment the record index.
        i++;
    }

    // Refer to the prior list.
    RevertToList();
    
    // All records match.
    return( 1 );
}

/*------------------------------------------------------------
| TestOrderedTable
|-------------------------------------------------------------
|
| PURPOSE: To validate the operation of table functions.
|
| DESCRIPTION: This test pseudo-randomly inserts and deletes 
| records in an ordered table in tandem with an ordered list 
| of records, comparing both forms to make sure they match 
| after each operation.  
|
| This test is exactly repeatable since the same random 
| number seed is used each time.
|
| Functions tested by this procedure:
|
|   CompareKeyToRecord
|   CompareKeyToRecordBlock
|   DeleteRecords
|   DeleteTable
|   DumpTable
|   FindRecord
|   FindRecordInBlock
|   InsertOrderedRecords
|   InsertRecordsAfter
|   InsertRecordsBefore
|   InsertRecordsFirst
|   InsertRecordsLast
|   IsTableAndListEquivalent
|   MakeTable
|   MakeRecordBlock
|   ToFirstRecord
|   ToFirstRecordInBlock
|   ToLastRecord
|   ToLastRecordInBlock
|   ToNextRecord
|   ToNthRecord
|   ValidateTable
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: The list system has been set up.
|
| HISTORY: 10.07.98 TL Ran millions of trials for various
|                      blocking factors.
|          10.14.98 Re-ran millions of trials following block
|                   list revision: now runs 10% faster.
|          10.19.98 Ran millions of trials on up to 1000 records
|                   with a wide range of blocking factors.
|          12.01.98 Ran a million trials after installing
|                   lookaside buffer.
------------------------------------------------------------*/
void
TestOrderedTable()
{
    List*       L;
    Item*       RinL;
    Item*       RinLNext;
    Table*      T;
    ThatRecord  R;
    s32         RecordsPerBlock, FirstRecordToDelete;
    s32         i, CountToInsert, CountToDelete;
    s32         BytesPerRecord, KeyOffset, KeySize;
    u8          SampleRecords[20] =
                {
                    'A', 0, 'B', 0, 
                    'C', 0, 'D', 0, 
                    'E', 0, 'F', 0,
                    'G', 0, 'H', 0, 
                    'I', 0, 'J', 0
                };
    s32         SampleRecordCount, SampleRecordIndex;
    s32         MaxRecordCount;
    u8*         RecordToInsert;
#if macintosh
    u64         StartTime;
#endif

    // Specify how many sample records there are.
    SampleRecordCount = 10;
    
    // Specify the number of bytes in each record: two
    // ASCII characters followed by a zero string terminator.
    BytesPerRecord = 2; 
             
    // The offset of the search key is zero.
    KeyOffset = 0;
    
    // The key size is three bytes long.
    KeySize = 2;

    // To keep the table from growing without limit, specify
    // the maximum record count that the table may hold for
    // this test.
    MaxRecordCount = 40; // 1000; 
    
    // For various blocking factors.
    for( RecordsPerBlock = 1; 
         RecordsPerBlock < MaxRecordCount; 
         RecordsPerBlock += 1 ) 
    {

#if macintosh       
        // Record the start time.
        GetTimeCPU( &StartTime );
#endif
        
        // Make a table for the records.
        T = MakeTable( 
                BytesPerRecord, // How many bytes are in each
                                // data record.
                                //
                RecordsPerBlock,// How many records should be
                                // held in each block.  This 
                                // controls the separation of 
                                // the table into contiguous
                                // chunks of memory.
                                //
                (CompareProc) CompareStringsCaseSensitive,
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

        // Make a list for the records.
        L = MakeList();
        
        // Set the starting seed for the pseudo-random number generator.
        SetUpRandomNumberGenerator( 92134 );
        
        // For a large number of trials.
        for( i = 0; i < 1000000; i++ )
        {
            // If the table is full.
            if( T->RecordCount == MaxRecordCount )
            {
                // Pick a random number of records to delete, from 1 to all.
                CountToDelete = RandomIntegerFromRange( 1, MaxRecordCount );
                
                // Pick a random location in the table to delete records.
                FirstRecordToDelete = RandomIntegerFromRange( 0, MaxRecordCount - 1 );
                
                // If the count to delete extends outside the table.
                if( CountToDelete > (MaxRecordCount - FirstRecordToDelete) )
                {
                    // Restrict the size to the records in the table.
                    CountToDelete = MaxRecordCount - FirstRecordToDelete;
                }
                
                // Refer to the first record to delete in the table.
                ToNthRecord( T, &R, FirstRecordToDelete );

                // Delete the record from the table.
                DeleteRecords( &R, CountToDelete );
                
                // Refer to the first record to delete in the list.
                RinL = FindNthItem( L, FirstRecordToDelete );

                // Until all the specified records are deleted.
                while( CountToDelete )
                {
                    // Refer to the item after the one to be deleted.
                    RinLNext = RinL->NextItem;
                    
                    // Extract the item to be deleted from the list.
                    ExtractItemFromList( L, RinL );
                    
                    // Free the data connected to the item.
                    free( RinL->DataAddress );
                    
                    // Delete the item record.
                    DeleteItem( RinL );
                    
                    // Make the next item the current one.
                    RinL = RinLNext;
                
                    // Account for the record just deleted.
                    CountToDelete--;
                }
                
                // Validate the table structure following the
                // deletion of records.
                ValidateTable( T );
                
                // If the list and the table are not logically
                // equivalent after making logically equivalent
                // changes to both.
                if( IsTableAndListEquivalent( T, L ) == 0 )
                {
                    // Mismatch error.
                    Debugger();
                }
            }
            else // There is room to insert new records.
            {
                // Pick a random number of records to insert, from 1 to 5.
                CountToInsert = RandomIntegerFromRange( 1, 5 );
                    
                // If the count to insert exceeds the table space.
                if( CountToInsert > (MaxRecordCount - T->RecordCount) )
                {
                    // Restrict the size to the space available.
                    CountToInsert = MaxRecordCount - T->RecordCount;
                }

                // Pick a random first record from the samples.
                SampleRecordIndex = 
                    RandomIntegerFromRange( 0, SampleRecordCount - 6 );

                // Insert the records into the ordered table.
                InsertOrderedRecords( 
                    T,               // The table where the records go.
                                     //
                    &SampleRecords[ SampleRecordIndex * BytesPerRecord ],       
                                     // Where the records are that 
                                     // are to be inserted.  This is
                                     // a contiguous block of records.
                                     //
                    CountToInsert ); // How many records are to be
                                     // inserted.
                
                // Insert the records into the ordered list.
                while( CountToInsert )
                {
                    // Make a copy of the record string.
                    RecordToInsert = (u8*)
                        DuplicateString( (s8*)
                            &SampleRecords[ SampleRecordIndex * BytesPerRecord ] );
                            
                    // Insert the record in the list.
                    InsertDataInOrderedList( 
                        L,
                        RecordToInsert,
                        (CompareProc) CompareStringsCaseSensitive );
                
                    // Account for the record just inserted.
                    CountToInsert--;

                    // Refer to the next record to insert.
                    SampleRecordIndex++;
                }

                // Validate the table structure following the
                // insertion of records.
                ValidateTable( T );
                
                // If the list and the table are not logically
                // equivalent after making logically equivalent
                // changes to both.
                if( IsTableAndListEquivalent( T, L ) == 0 )
                {
                    // Mismatch error.
                    Debugger();
                }
            }
            
            // If this is one of the periodic reporting periods.
            if( ( i % 100000 ) == 0 )
            {
                // Print the trial number.
                printf( "%d: ", i );
                
                // Dump the table for inspection.
                DumpTable( T );
            }
        }
        
        // Throw away the table.
        DeleteTable( T );
        
        // Clean up the list
        DeleteListOfDynamicData( L );

#if macintosh       
        // Compute the elapsed time.
        ElapsedTimeCPU( &StartTime );
        
        // Report the elapsed time and the blocking factor.
        printf( "BlockingFactor: %ld Elapsed time: %ld \n", 
                RecordsPerBlock, 
                (u32) StartTime );
#endif // macintosh
    }
}

/*------------------------------------------------------------
| TestUnorderedTable
|-------------------------------------------------------------
|
| PURPOSE: To validate the operation of functions used with
|          unordered tables.
|
| DESCRIPTION: This test pseudo-randomly inserts and deletes 
| records in an unordered table in tandem with a list of 
| records, comparing both forms to make sure they match after 
| each operation.  
|
| This test is exactly repeatable since the same random 
| number seed is used each time.
|
| Functions tested by this procedure:
|
|   DeleteRecords
|   DeleteTable
|   DumpTable
|   InsertRecordsAfter
|   InsertRecordsBefore
|   InsertRecordsFirst
|   InsertRecordsLast
|   IsTableAndListEquivalent
|   MakeTable
|   MakeRecordBlock
|   ToFirstRecord
|   ToNthRecord
|   ValidateTable
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: The list system has been set up.
|
| HISTORY: 10.07.98 TL From 'TestOrderedTable'.
|                   Ran millions of trials for various 
|                   blocking factors.
|          10.19.98 Revalidated after revising the block list.
|                   Ran one million reps for each blocking 
|                   factors ranging from 1 to 40.
------------------------------------------------------------*/
void
TestUnorderedTable()
{
    List*       L;
    Item*       RinL;
    Item*       RinLNext;
    Table*      T;
    ThatRecord  R;
    s32         RecordsPerBlock, FirstRecordToDelete;
    s32         FirstRecordToInsert;
    s32         i, CountToInsert, CountToDelete;
    s32         BytesPerRecord, SampleOffset;
    u8          SampleRecords[20] =
                {
                    'A', 0, 'B', 0, 
                    'C', 0, 'D', 0, 
                    'E', 0, 'F', 0,
                    'G', 0, 'H', 0, 
                    'I', 0, 'J', 0
                };
    s32         SampleRecordCount, SampleRecordIndex;
    s32         MaxRecordCount, InsertionMethod;
    s32         IsBefore;
    u8*         RecordToInsert;
#if macintosh
    u64         StartTime;
#endif

    // Specify how many sample records there are.
    SampleRecordCount = 10;
    
    // Specify the number of bytes in each record: two
    // ASCII characters followed by a zero string terminator.
    BytesPerRecord = 2; 
             
    // To keep the table from growing without limit, specify
    // the maximum record count that the table may hold for
    // this test.
    MaxRecordCount = 40;
    
    // For various blocking factors.
    for( RecordsPerBlock = 1; 
         RecordsPerBlock <= MaxRecordCount; 
         RecordsPerBlock++ )
    {
#if macintosh       
        // Record the start time.
        GetTimeCPU( &StartTime );
#endif
        
        // Make a table for the records.
        T = MakeTable( 
                BytesPerRecord, // How many bytes are in each
                                // data record.
                                //
                RecordsPerBlock,// How many records should be
                                // held in each block.  This 
                                // controls the separation of 
                                // the table into contiguous
                                // chunks of memory.
                                //
                0,              // No comparison function because
                                // this is an unordered table.
                                //
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
                0,              // Byte offset from the beginning
                                // of a data record to the field
                                // that holds the sorting key 
                                // value of the record.  Only used
                                // for ordered tables, use zero if
                                // unordered.
                                //
                0 );            // Size of the key field in bytes.
                                // Only used for ordered tables,
                                // use zero if unordered.

        // Make a list for the records.
        L = MakeList();
        
        // Set the starting seed for the pseudo-random number generator.
        SetUpRandomNumberGenerator( 33245 );
        
        // For a large number of trials.
        for( i = 0; i < 1000000; i++ )
        {
            // If the table is full.
            if( T->RecordCount == MaxRecordCount )
            {
                // Pick a random number of records to delete, from 1 to all.
                CountToDelete = RandomIntegerFromRange( 1, MaxRecordCount );
                
                // Pick a random location in the table to delete records.
                FirstRecordToDelete = RandomIntegerFromRange( 0, MaxRecordCount - 1 );
                
                // If the count to delete extends outside the table.
                if( CountToDelete > (MaxRecordCount - FirstRecordToDelete) )
                {
                    // Restrict the size to the records in the table.
                    CountToDelete = MaxRecordCount - FirstRecordToDelete;
                }
                
                // Refer to the first record to delete in the table.
                ToNthRecord( T, &R, FirstRecordToDelete );

                // Delete the record from the table.
                DeleteRecords( &R, CountToDelete );
                    
                // Refer to the first record to delete in the list.
                RinL = FindNthItem( L, FirstRecordToDelete );

                // Until all the specified records are deleted.
                while( CountToDelete )
                {
                    // Refer to the item after the one to be deleted.
                    RinLNext = RinL->NextItem;
                    
                    // Extract the item to be deleted from the list.
                    ExtractItemFromList( L, RinL );
                    
                    // Free the data connected to the item.
                    free( RinL->DataAddress );
                    
                    // Delete the item record.
                    DeleteItem( RinL );
                    
                    // Make the next item the current one.
                    RinL = RinLNext;
                
                    // Account for the record just deleted.
                    CountToDelete--;
                }
                
                // Validate the table structure following the
                // deletion of records.
                ValidateTable( T );
                
                // If the list and the table are not logically
                // equivalent after making logically equivalent
                // changes to both.
                if( IsTableAndListEquivalent( T, L ) == 0 )
                {
                    // Mismatch error.
                    Debugger();
                }
            }
            else // There is room to insert new records.
            {
                // Pick a random number of records to insert, from 1 to 5.
                CountToInsert = RandomIntegerFromRange( 1, 5 );
                    
                // If the count to insert exceeds the table space.
                if( CountToInsert > (MaxRecordCount - T->RecordCount) )
                {
                    // Restrict the size to the space allotted.
                    CountToInsert = MaxRecordCount - T->RecordCount;
                }

                // Pick a random first record from the samples.
                SampleRecordIndex = 
                    RandomIntegerFromRange( 0, SampleRecordCount - 6 );
                
                // Separate the insertion methods into three cases.
                InsertionMethod = RandomIntegerFromRange( 1, 3 );
                
                // If the table is empty.
                if( T->RecordCount == 0 )
                {
                    // Append if empty.
                    InsertionMethod = 2;
                }
                
                // Select one of three cases.
                switch( InsertionMethod )
                {
                    case 1: // Prepend the records.
                    {
                        // Prepend the records to the table.
                        InsertRecordsFirst( 
                            T,          // The table where the records
                                        // will be inserted.
                                        //
                            &SampleRecords[ SampleRecordIndex * BytesPerRecord ], 
                                        // Where the records are that 
                                        // are to be inserted.  This is
                                        // a contiguous block of records.
                                        //
                            CountToInsert ); // How many records are to be
                                        // inserted.
                                        
                        // Validate the table structure following the
                        // insertion of records.
                        ValidateTable( T );
                        
                        // Insert the records first in the list.
                        while( CountToInsert )
                        {
                            // Refer to the offset of the sample record.
                            SampleOffset = 
                                (SampleRecordIndex + CountToInsert - 1) * BytesPerRecord;
                                
                            // Make a copy of the record string.
                            RecordToInsert = (u8*)
                                DuplicateString( (s8*) &SampleRecords[ SampleOffset ] );
                                    
                            // Insert the record in the list first.
                            InsertDataFirstInList( L, RecordToInsert );
                        
                            // Account for the record just inserted.
                            CountToInsert--;
                        }
                        
                        // If the list and the table are not logically
                        // equivalent after making logically equivalent
                        // changes to both.
                        if( IsTableAndListEquivalent( T, L ) == 0 )
                        {
                            // Mismatch error.
                            Debugger();
                        }
                        
                        // Finished with Case 1.
                        break;
                    }
                    
                    case 2: // Append the records.
                    {
                        // Append the records to the table.
                        InsertRecordsLast( 
                            T,          // The table where the records
                                        // will be inserted.
                                        //
                            &SampleRecords[ SampleRecordIndex * BytesPerRecord ], 
                                        // Where the records are that 
                                        // are to be inserted.  This is
                                        // a contiguous block of records.
                                        //
                            CountToInsert ); // How many records are to be
                                        // inserted.
                                        
                        // Validate the table structure following the
                        // insertion of records.
                        ValidateTable( T );
                        
                        // Insert the records last in the list.
                        while( CountToInsert )
                        {
                            // Refer to the offset of the sample record.
                            SampleOffset = SampleRecordIndex * BytesPerRecord;
                                
                            // Make a copy of the record string.
                            RecordToInsert = (u8*)
                                DuplicateString( (s8*) &SampleRecords[ SampleOffset ] );
                                    
                            // Insert the record in the list first.
                            InsertDataLastInList( L, RecordToInsert );
                        
                            // Account for the record just inserted.
                            CountToInsert--;
                            
                            // Advance the source index.
                            SampleRecordIndex++;
                        }
                        
                        // If the list and the table are not logically
                        // equivalent after making logically equivalent
                        // changes to both.
                        if( IsTableAndListEquivalent( T, L ) == 0 )
                        {
                            // Mismatch error.
                            Debugger();
                        }
                        
                        // Finished with Case 2.
                        break;
                    }
                    
                    default: // Insert records in the middle of the records.
                    {
                        // Pick a random location in the table to insert records.
                        FirstRecordToInsert = 
                            RandomIntegerFromRange( 0, T->RecordCount - 1 );
                        
                        // If the count to delete extends outside the table.
                        if( CountToInsert > (MaxRecordCount - FirstRecordToInsert) )
                        {
                            // Restrict the count to the records in the table.
                            CountToInsert = MaxRecordCount - FirstRecordToInsert;
                        }
                        
                        // Refer to the record next to where records will be
                        // inserted into the table.
                        ToNthRecord( T, &R, FirstRecordToInsert );
                        
                        // Refer to the record next to where records will be
                        // inserted into the list.
                        RinL =  FindNthItem( L, FirstRecordToInsert );
                        
                        // Decide to insert the records before or after.
                        IsBefore = RandomBit();
                        
                        // If should insert before.
                        if( IsBefore )
                        {
                            // Insert the records before the insertion record.
                            InsertRecordsBefore( 
                                &R,  // The record in the table before
                                     // which new records will be 
                                     // inserted.
                                     //
                                &SampleRecords[ SampleRecordIndex * BytesPerRecord ],       
                                     // Where the records are that 
                                     // are to be inserted.  This is
                                     // a contiguous block of records.
                                     //
                                CountToInsert ); // How many records are to be
                                     // inserted.
                                     
                            // Validate the table structure following the insertion 
                            // of records.
                            ValidateTable( T );
                
                            // Insert the records into the list before the reference item.
                            while( CountToInsert )
                            {
                                // Make a copy of the record string.
                                RecordToInsert = (u8*)
                                    DuplicateString( (s8*)
                                        &SampleRecords[ SampleRecordIndex * BytesPerRecord ] );
                                        
                                // Insert the record in the list.
                                InsertDataBeforeItemInList( L, RinL, RecordToInsert );
                            
                                // Account for the record just inserted.
                                CountToInsert--;

                                // Refer to the next record to insert.
                                SampleRecordIndex++;
                            }
                            
                            // If the list and the table are not logically
                            // equivalent after making logically equivalent
                            // changes to both.
                            if( IsTableAndListEquivalent( T, L ) == 0 )
                            {
                                // Mismatch error.
                                Debugger();
                            }
                        }
                        else // The other half of the cases.
                        {
                            // Insert the records after the insertion record.
                            InsertRecordsAfter( 
                                &R,  // The record in the table after
                                     // which new records will be 
                                     // inserted.
                                     //
                                &SampleRecords[ SampleRecordIndex * BytesPerRecord ],       
                                     // Where the records are that 
                                     // are to be inserted.  This is
                                     // a contiguous block of records.
                                     //
                                CountToInsert ); // How many records are to be
                                     // inserted.
                                     
                            // Validate the table structure following the
                            // insertion of records.
                            ValidateTable( T );
                
                            // Insert the records into the list after the reference item.
                            while( CountToInsert )
                            {
                                // Make a copy of the record string.
                                RecordToInsert = (u8*)
                                    DuplicateString( (s8*)
                                        &SampleRecords[ SampleRecordIndex * BytesPerRecord ] );
                                        
                                // Insert the record in the list.
                                RinL = InsertDataAfterItemInList( L, RinL, RecordToInsert );
                            
                                // Account for the record just inserted.
                                CountToInsert--;

                                // Refer to the next record to insert.
                                SampleRecordIndex++;
                            }
                            
                            // If the list and the table are not logically
                            // equivalent after making logically equivalent
                            // changes to both.
                            if( IsTableAndListEquivalent( T, L ) == 0 )
                            {
                                // Mismatch error.
                                Debugger();
                            }
                        }
                    }
                }
 
                // Validate the table structure following the
                // insertion of records.
                ValidateTable( T );
                
                // If the list and the table are not logically
                // equivalent after making logically equivalent
                // changes to both.
                if( IsTableAndListEquivalent( T, L ) == 0 )
                {
                    // Mismatch error.
                    Debugger();
                }
            }
            
            // If this is one of the periodic reporting periods.
            if( ( i % 100000 ) == 0 )
            {
                // Print the trial number.
                printf( "%d: ", i );
                
                // Dump the table for inspection.
                DumpTable( T );
            }
        }
        
        // Throw away the table.
        DeleteTable( T );
        
        // Clean up the list
        DeleteListOfDynamicData( L );
        
#if macintosh       
        // Compute the elapsed time.
        ElapsedTimeCPU( &StartTime );
        
        // Report the elapsed time and the blocking factor.
        printf( "BlockingFactor: %ld Elapsed time: %ld \n", 
                RecordsPerBlock, 
                (u32) StartTime );
#endif // macintosh
    }
}

/*------------------------------------------------------------
| TLTableTest_main
|-------------------------------------------------------------
|
| PURPOSE: To test TLTable functions.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Room exists for the log file on disk.
|
|          TLList test has passed OK: list operations are
|          run in tandem with table operations to validate
|          table functions.
|
| HISTORY: 12.31.98 TL From 'TLListTest.c'.
|       
------------------------------------------------------------*/
void
//TLTableTest_main()
main()
{
    // Set up the TLList functions for use.
    SetUpTheListSystem(0);
    
    TheLogFile = fopen( "TLTableTestLog", "w+" );
    
    printt( (s8*)"*******************************************\n" );
    printt( (s8*)"*  B E G I N   T L T A B L E   T E S T S  *\n" );
    printt( (s8*)"*******************************************\n" );

    TestOrderedTable();

    TestUnorderedTable();
    
    printt( (s8*)"***************************************************\n" );
    printt( (s8*)"*   A L L   T E S T S   C O M P L E T E D   O K   *\n" );
    printt( (s8*)"*                                                 *\n" );
    printt( (s8*)"*           'TLTable' is ready to use.            *\n" );
    printt( (s8*)"*                                                 *\n" );
    printt( (s8*)"***************************************************\n\n" );

    printt( (s8*)"***********************************************\n" );
    printt( (s8*)"*   B E G I N   T L T A B L E   D E M O       *\n" );
    printt( (s8*)"***********************************************\n" );
    
    RunMeToDemoTLTable();
    
    printt( (s8*)"*******************************************\n" );
    printt( (s8*)"*     E N D   T L T A B L E   D E M O     *\n" );
    printt( (s8*)"*******************************************\n" );
    
    fclose( TheLogFile );
}

