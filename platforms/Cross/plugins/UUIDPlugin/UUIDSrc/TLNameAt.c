/*------------------------------------------------------------
| TLNameAt.c
|-------------------------------------------------------------
|
| PURPOSE: To provide a way of naming unique and fixed place
|          addresses such as memory locations.
|
| DESCRIPTION: The procedures in this file are used to 
| associate names with fixed places.  
|
| Memory addresses can be associated with names so that,
| given a name a memory location can be found -- and given
| a location, the name can be found.
|
| (Place,Name) pairs are held as a list of 'PlaceNameRecord'
| records held in a mass memory storage area associated with 
| each name table.
|
| Each 'PlaceNameRecord' has this form:
|
|                  PlaceNameRecord
|      --------------------------------------
|      |  PlaceAddress  |  NameOfPlace  | 0 |
|      --------------------------------------
|          4 bytes      |<-size varies->| terminal 0
|
| where: 'PlaceAddress' is the address associated with the name
|
|        'NameOfPlace' is the name associated with the place.
|
| There are two index tables:
|
| 'NameLookUpTable' - holds addresses of the 'PlaceName'
|                     records sorted by the 'NameOfPlace' 
|                     field
|
| 'PlaceLookUpTable' - holds addresses of the 'PlaceName'
|                     records sorted by the 'PlaceAddress' 
|                     field.
|
| The look-up tables are maintained in order each time a 
| symbol is added to or deleted from a list.
|
| NOTE: 
|
| ASSUMES: Each name is unique.
|  
|          Each place is unique.
|
|          No more than one name will be associated with any
|          place.
|
|          OK to relocate 'PlaceName' records in the mass 
|          storage area on deletion of other 'PlaceName'
|          records.
|
| HISTORY: 09.06.89
|          09.20.89 revised to use long encapsulated strings
|          10.31.89 added ListOrdered flag to reduce needless 
|                   sorting
|          02.08.93 from symbols.c.
|          11.30.93 from SymbolTable.c
|          12.10.93 passed 'NameTest.c'.
|          11.08.98 Revised to use tables instead of lists;
|                   generalized to multiple name tables.
|          11.24.98 Name changed from 'TLNameIt.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "TLTypes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLList.h"
#include "TLTable.h"
#include "TLMassMem.h"
#include "TLFile.h"

#include "TLNameAt.h"

/*------------------------------------------------------------
| ComparePlaceAddresses
|-------------------------------------------------------------
|
| PURPOSE: To compare the place address fields of two 
|          placename records.
|
| DESCRIPTION: Comparison operation.
|              Returns: 0 if addr AA = addr BB.
|                       positive number if AA > BB.
|                       negative number if AA < BB.
|
| EXAMPLE:  Result = ComparePlaceAddresses( Apn, Bpn );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.09.93
------------------------------------------------------------*/
s32
ComparePlaceAddresses( PlaceName** Apn, PlaceName** Bpn )
{
    u8* A;
    u8* B;
    s32 Result;
    
    A = (*Apn)->PlaceAddress;
    B = (*Bpn)->PlaceAddress;
    
    Result = (s32)(A - B);
    
    return( Result );   
}

/*------------------------------------------------------------
| ComparePlaceNames
|-------------------------------------------------------------
|
| PURPOSE: To compare two place names based on their ASCII
| ordering. Case sensitive.
|
| DESCRIPTION: Comparison operation.
|              Returns: 0 if string AA = string BB.
|                       positive number if AA > BB.
|                       negative number if AA < BB.
|
| Compared until end of either string or until an in-equality 
| is detected.
|
| EXAMPLE:  Result = ComparePlaceNames( Apn, Bpn );
|
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY:  12.09.93
------------------------------------------------------------*/
s32
ComparePlaceNames( PlaceName** Apn, PlaceName** Bpn )
{
    s8* A;
    s8* B;
    s32 Result;
    
    A = &(*Apn)->NameOfPlace;
    B = &(*Bpn)->NameOfPlace;
    
    Result = CompareStringsCaseSensitive( A, B );
    
    return( Result );   
}

/*------------------------------------------------------------
| DeleteNameAt
|-------------------------------------------------------------
|
| PURPOSE: To free memory resources used by a place name table.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTES: 
|
| ASSUMES: 
|
| HISTORY: 11.08.98 TL
|          11.27.98 Added free list support.
|          03.06.99 Added Patricia tree option.
------------------------------------------------------------*/
void
DeleteNameAt( NameAt* N )
{
#if USE_PATRICIA_TREE

    // Delete the name-to-place index.
    DeletePatricia( N->NameIndex ); 
     
    // Delete the place-to-name index.
    DeletePatricia( N->PlaceIndex );  

#else // Not using Patricia trees.

    // Delete the place look-up table.
    DeleteTable( N->PlaceLookUpTable );
    
    // Delete the name look-up table.
    DeleteTable( N->NameLookUpTable );
    
#endif

    // Delete any data associated with the table.
    DeleteMass( N->Storage );
    
    // Delete the free list table.
    free( N->FreeListTable );
    
    // Delete the name table control record itself.
    free( N );
}

/*------------------------------------------------------------
| DeletePlaceNameByName
|-------------------------------------------------------------
|
| PURPOSE: To delete the place name record for the given name.
|
| DESCRIPTION: Deletes the 'PlaceName' record in the table,
| possibly shifting other records, and also deletes the lookup
| table entries that refer to the record.
|
| EXAMPLE:  DeletePlaceNameByName( N, "Radius" );
|
| NOTES: 
|
| ASSUMES: OK to relocate 'PlaceName' records as long as
|          lookup tables are also adjusted.
|
| HISTORY: 12.09.93
|          11.08.98 Generalized for multiple name tables.
|          11.14.98 Revised to delete the 'PlaceName' record.
------------------------------------------------------------*/
void
DeletePlaceNameByName( NameAt* N, s8* AName )
{
    PlaceName*  P;
    s32         C;
    ThatRecord  R;
    
    // Refer to the given name as if it were already in a
    // 'PlaceName' record.
    P = (PlaceName*) (AName - 4);
    
    // Locate the 'PlaceName' address entry in the name 
    // look-up table.
    C = FindRecord( 
            N->NameLookUpTable,   
                  // The record table.
                  //
            (u8*) &P, 
                  // Address of the search key: regard the name
                  // as part of a PlaceName record for searching
                  // purposes.
                  //
            &R ); // Returns the record or nearby record.

    // If the name is in the table.
    if( C == 0 ) 
    {
        // Refer to the address of the 'PlaceName' record.
        P = *( (PlaceName**) R.TheRecord );
        
        // Delete the name look-up table record.
        DeleteRecords( &R, 1 );
        
        // Locate the name record address in the place 
        // look-up table.
        FindRecord( 
                N->PlaceLookUpTable,   
                      // The record table.
                      //
                (u8*) &P, 
                      // Address of the search key.
                      //
                &R ); // Returns the record or nearby record.

        // Delete the place look-up table record.
        DeleteRecords( &R, 1 );

        // Delete the record from storage, adjusting other
        // lookup table entries accordingly.
        DeletePlaceNameRecord( N, P );
    } 
}

/*------------------------------------------------------------
| DeletePlaceNameByPlace
|-------------------------------------------------------------
|
| PURPOSE: To delete the place name record for the given place.
|
| DESCRIPTION: Deletes the 'PlaceName' record in the table,
| possibly shifting other records, and also deletes the lookup
| table entries that refer to the record.
|
| EXAMPLE:  DeletePlaceNameByPlace( N, 17 );
|
| NOTES: 
|
| ASSUMES: OK to relocate 'PlaceName' records as long as
|          lookup tables are also adjusted.
|
| HISTORY: 11.15.98 From 'DeletePlaceNameByName()'.
------------------------------------------------------------*/
void
DeletePlaceNameByPlace( NameAt* N, u32 APlace )
{
    PlaceName*  P;
    s32         C;
    ThatRecord  R;
    
    // Refer to the given place as if it were a 'PlaceName' 
    // record.
    P = (PlaceName*) &APlace;
    
    // Locate the 'PlaceName' address entry in the place 
    // look-up table.
    C = FindRecord( 
            N->PlaceLookUpTable,   
                  // The record table.
                  //
            (u8*) &P, 
                  // Address of the search key: regard the place
                  // as part of a PlaceName record for searching
                  // purposes.
                  //
            &R ); // Returns the record or nearby record.

    // If the place is in the table.
    if( C == 0 ) 
    {
        // Refer to the address of the 'PlaceName' record.
        P = *( (PlaceName**) R.TheRecord );
        
        // Delete the place look-up table record.
        DeleteRecords( &R, 1 );
        
        // Locate the name record address in the name 
        // look-up table.
        FindRecord( 
                N->NameLookUpTable,   
                      // The record table.
                      //
                (u8*) &P, 
                      // Address of the search key.
                      //
                &R ); // Returns the record or nearby record.

        // Delete the place look-up table record.
        DeleteRecords( &R, 1 );

        // Delete the record from storage, adjusting other
        // lookup table entries accordingly.
        DeletePlaceNameRecord( N, P );
    } 
}

/*------------------------------------------------------------
| DeletePlaceNameRecord
|-------------------------------------------------------------
|
| PURPOSE: To delete a place name record.
|
| DESCRIPTION: Deletes a 'PlaceName' record by putting it
| on a free list so that it can be reused.
|
| Doesn't delete the the look up table entries that refer
| to the record -- this must be done elsewhere.
|
| EXAMPLE:  DeletePlaceNameRecord( N, P );
|
| NOTES: 
|
| ASSUMES: Not OK to relocate 'PlaceName' records.
|
| HISTORY: 11.15.98 From 'DeletePlaceName()'.
|          11.27.98 Revised to use 'FreeListTable'. Tested.
------------------------------------------------------------*/
void
DeletePlaceNameRecord( NameAt* N, PlaceName* P )
{
    u32     SizeOfRecord, i;
    u8**    AtFreeList;
    
    // Calculate the total size of the record.
    SizeOfRecord = 
       sizeof(u8*) +        // 'PlaceAddress' field.
                            //
       CountString(&P->NameOfPlace) + 
                            // Size of given name.
                            //
       1;                   // terminal 0 byte.
    
    // If the record is less than 256 bytes long.
    if( SizeOfRecord < 256 )
    {
        // The index of the free list is the same as
        // the length of the record.
        i = SizeOfRecord;
    }
    else // The record size is more than 255 bytes.
    {
        // Save the record length in the first 4 bytes
        // of the 'NameOfPlace' field.
        ((u32*) P)[1] = SizeOfRecord;
        
        // If the record is less than 512 bytes long.
        if( SizeOfRecord < 512 )
        {
            // The free list index is 0.
            i = 0;
        }
        else // The records size if more than 511 bytes.
        {
            // If the record is less than 1024 bytes long.
            if( SizeOfRecord < 1024 )
            {
                // The free list index is 1.
                i = 1;
            }
            else // The records size if more than 1024 bytes.
            {
                // If the record is less than 2048 bytes long.
                if( SizeOfRecord < 2048 )
                {
                    // The free list index is 2.
                    i = 2;
                }
                else // The records size if more than 2048 bytes.
                {
                    // If the record is less than 4096 bytes long.
                    if( SizeOfRecord < 4096 )
                    {
                        // The free list index is 3.
                        i = 3;
                    }
                    else // The records size if more than 4096 bytes.
                    {
                        // The free list index is 4.
                        i = 4;
                    }
                }
            }
        }
    }
    
    // Refer to the address of the start of the free list.
    AtFreeList = (u8**) ( N->FreeListTable + (i<<2) );

    // Link any existing free records to the record being freed.
    P->PlaceAddress = *AtFreeList;

    // Link the start of the free list to the first record.
    *AtFreeList = (u8*) (&P->PlaceAddress);
}

/*------------------------------------------------------------
| DumpPlaceNames
|-------------------------------------------------------------
|
| PURPOSE: To output all place/name records in a symbol
|          table, in order by name.
|
| DESCRIPTION: 
|   
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.15.98
------------------------------------------------------------*/
void
DumpPlaceNames( FILE* F, NameAt* N )
{
    ThatRecord R;
    PlaceName* P;
    
    // Refer to the first record of the name index.
    ToFirstRecord( N->NameLookUpTable, &R );
    
    // Until all records have been printed.
    while( R.TheRecord )
    {
        // Refer to the address of the 'PlaceName' record.
        P = *( (PlaceName**) R.TheRecord );

        // Output the place number followed by the name.
        fprintf( F, 
                 "%ld\t%s\n", 
                 (u32) P->PlaceAddress,
                 &P->NameOfPlace );
                
        // Advance to the next record.
        ToNextRecord( &R );
    }
}

/*------------------------------------------------------------
| DumpPlaceNamesByPlace
|-------------------------------------------------------------
|
| PURPOSE: To output all place/name records in a symbol
|          table, in order by place.
|
| DESCRIPTION: 
|   
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.27.98 From 'DumpPlaceNames()'.
------------------------------------------------------------*/
void
DumpPlaceNamesByPlace( FILE* F, NameAt* N )
{
    ThatRecord R;
    PlaceName* P;
    
    // Refer to the first record of the name index.
    ToFirstRecord( N->PlaceLookUpTable, &R );
    
    // Until all records have been printed.
    while( R.TheRecord )
    {
        // Refer to the address of the 'PlaceName' record.
        P = *( (PlaceName**) R.TheRecord );

        // Output the place number followed by the name.
        fprintf( F, 
                 "%ld\t%s\n", 
                 (u32) P->PlaceAddress,
                 &P->NameOfPlace );
                
        // Advance to the next record.
        ToNextRecord( &R );
    }
}

/*------------------------------------------------------------
| EmptyPlaceNames
|-------------------------------------------------------------
|
| PURPOSE: To discard all place name records presently in the 
|          name table.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTES: 
|
| ASSUMES: 
|
| HISTORY: 12.09.93
|          11.08.98 Generalized to support multiple name 
|                   tables.
------------------------------------------------------------*/
void
EmptyPlaceNames( NameAt* N )
{
    // Delete all the records in the place look-up table.
    EmptyTable( N->PlaceLookUpTable );
                   
    // Delete all the records in the name look-up table.
    EmptyTable( N->NameLookUpTable );
    
    // Empty any data associated with the table.
    EmptyMass( N->Storage );
}

/*------------------------------------------------------------
| FindName
|-------------------------------------------------------------
|
| PURPOSE: To return the name associated with a given place.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTES: 
|
| ASSUMES: 
|
| HISTORY: 12.09.93
|          11.08.98 Name changed from 'FindNameGivenPlace' and
|                   generalized for multiple name tables.
------------------------------------------------------------*/
s8*
FindName(
    NameAt* N,        // The symbol table holding the desired
                      // record.
                      //
    u8*     APlace )  // An address that is used as a key to
                      // match the 'PlaceAddress' of a 'PlaceName'
                      // record in the symbol table.
{
    PlaceName*  P;
    s32         C;
    ThatRecord  R;
    
    // Refer to the given place as if it were already in a
    // 'PlaceName' record.
    P = (PlaceName*) (APlace);

    // Locate the place name record address in the place 
    // look-up table.
    C = FindRecord( 
            N->PlaceLookUpTable,   
                  // The record table.
                  //
            (u8*) &P, 
                  // Address of the search key.
                  //
            &R ); // Returns the record or nearby record.

    // If the place is in the table.
    if( C == 0 ) 
    {
        // Refer to the address of the 'PlaceName' record.
        P = *( (PlaceName**) R.TheRecord );
        
        // Return the name of the place.                  
        return( &P->NameOfPlace );
    }
    else // Name isn't in the table.
    {
        // Just return zero.
        return( 0 );
    }
}

/*------------------------------------------------------------
| FindPlace
|-------------------------------------------------------------
|
| PURPOSE: To return the address associated with a name in a
|          name table.
|
| DESCRIPTION: Returns zero if the place isn't found.
|
| EXAMPLE:  
|
| NOTES: 
|
| ASSUMES: 
|
| HISTORY: 12.09.93
|          11.08.98 Name changed from 'FindPlaceGivenName' and
|                   generalized for multiple name tables.
------------------------------------------------------------*/
u8*
FindPlace( NameAt* N, s8* AName )
{
    PlaceName*  P;
    s32         C;
    ThatRecord  R;

    // Refer to the given name as if it were already in a
    // 'PlaceName' record.
    P = (PlaceName*) (AName - 4);
    
    // Locate the 'PlaceName' address entry in the name 
    // look-up table.
    C = FindRecord( 
            N->NameLookUpTable,   
              // The record table.
              //
            (u8*) &P, 
              // Address of the search key: regard the name
              // as part of a PlaceName record for searching
              // purposes.
              //
            &R ); // Returns the record or nearby record.

    // If the name is in the table.
    if( C == 0 ) 
    {
        // Refer to the address of the 'PlaceName' record.
        P = *( (PlaceName**) R.TheRecord );
        
        // Return the address of the place.               
        return( P->PlaceAddress );
    }
    else // Name isn't in the table.
    {
        // Just return zero.
        return( 0 );
    }
}

/*------------------------------------------------------------
| MakeNameAt
|-------------------------------------------------------------
|
| PURPOSE: To make a new symbol table.
|
| DESCRIPTION: Makes a new symbol table for associating names
| with 4-byte numbers, where the numbers are regarded 
| as addresses, locations or places.
|
| The basic idea is to provide a way to name anything, where a 
| 4-byte number is somehow connected to the place being
| named, the "at".
|
| EXAMPLE:  n = MakeNameAt();
|
| NOTES: 
|
| ASSUMES: Memory is avaliable.
|          Names will be 256 bytes long or less.
|
| HISTORY: 11.08.98
|          11.27.98 Added free list support.
------------------------------------------------------------*/
NameAt* 
MakeNameAt()
{
    NameAt* N;
    
    // Allocate a control record for the symbol table.
    N = (NameAt*) malloc( sizeof( NameAt ) );
    
    //
    // Fill in the fields of the record.
    //

#if USE_PATRICIA_TREE

    // Make the name-to-place index.
    N->NameIndex =
        MakePatricia(
            1,      // The minimum size of each key 
                    // in bytes.
                    //
            256 );  // The maximum size of each key 
                    // in bytes.
                    
    // Make the place-to-name index.
    N->PlaceIndex =
        MakePatricia(
            4,      // The minimum size of each key 
                    // in bytes.
                    //
            4 );    // The maximum size of each key 
                    // in bytes.

#else // Don't use a Patricia tree.
    
    // Make a table to hold the place look up records, 
    // addresses of 'PlaceName' records sorted by place 
    // address.
    N->PlaceLookUpTable = 
        MakeTable( 
            sizeof( PlaceName* ), 
                            // How many bytes are in each
                            // data record.
                            //
            50,             // How many records should be
                            // held in each block.  This 
                            // controls the separation of 
                            // the table into contiguous
                            // chunks of memory.
                            //
            (CompareProc) ComparePlaceAddresses,
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
            sizeof(u8*) );  // Size of the key field in bytes.
                            // Only used for ordered tables,
                            // use zero if unordered.
    
    // Make a table to hold the name look up records, 
    // addresses of 'PlaceName' records sorted by name. 
    N->NameLookUpTable = 
        MakeTable( 
            sizeof( PlaceName* ), 
                            // How many bytes are in each
                            // data record.
                            //
            50,             // How many records should be
                            // held in each block.  This 
                            // controls the separation of 
                            // the table into contiguous
                            // chunks of memory.
                            //
            (CompareProc) ComparePlaceNames,
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
            1 );            // Size of the key field in bytes.
                            // The key is really variable length,
                            // depending on the string -- 1 is
                            // used here because it's the minimum
                            // key size.
                            //
                            // Only used for ordered tables,
                            // use zero if unordered.
#endif
    
    // Allocate a mass memory buffer to be used to hold the
    // 'PlaceName' records and any other data associated with
    // the table.
    N->Storage = 
        MakeMass( 
            0xFFFFFFFF,
            // The most amount of memory space that can
            // be set aside to hold this mass memory 
            // pool.
            //
            1024,
            // The size of the data storage field
            // of the first mass memory block made when 
            // this mass memory pool is first made.
            //
            1024 );
            // The minimum size of the data storage 
            // field of a mass memory block: blocks may 
            // be larger if the required data block is 
            // larger.

    // Make a table to hold the 256 free lists.
    N->FreeListTable = malloc( 1024 );
    
    // Fill the free list table with zeros.
    memset( N->FreeListTable, 0, 1024 );
    
    // Return the control record address for the new
    // symbol table.
    return( N );
}

/*------------------------------------------------------------
| MakePlaceNameRecord
|-------------------------------------------------------------
|
| PURPOSE: To return the address of a new place name record in 
|          a name table which contains the given place name.
|
| DESCRIPTION: 
|
| EXAMPLE:  pnr = MakePlaceNameRecord( 
|                     MyNameAt, APlace, "Radius" );
|
| NOTES: 
|
| ASSUMES: Memory is avaliable.
|
| HISTORY: 12.09.93
|          11.08.98 Generalized to allow multiple name tables.
|          11.27.98 Added freelist so that records can be
|                   quickly recycled without fragmenting
|                   memory.
------------------------------------------------------------*/
PlaceName*
MakePlaceNameRecord( NameAt* N, u8* APlace, s8* AName )
{
    PlaceName*  P;
    u32         SizeOfRecord, i;
    u8**        AtFreeList;
    u8**        C;
    
    // Calculate the total size of the new record.
    SizeOfRecord = 
       sizeof(u8*) +        // 'PlaceAddress' field.
                            //
       CountString(AName) + // Size of given name.
                            //
       1;                   // terminal 0 byte.
    
    // If the record is less than 256 bytes long.
    if( SizeOfRecord < 256 )
    {
        // The index of the free list is the same as
        // the length of the record.
        i = SizeOfRecord;
    }
    else // The record size is more than 255 bytes.
    {
        // If the record is less than 512 bytes long.
        if( SizeOfRecord < 512 )
        {
            // The free list index is 0.
            i = 0;
        }
        else // The records size if more than 511 bytes.
        {
            // If the record is less than 1024 bytes long.
            if( SizeOfRecord < 1024 )
            {
                // The free list index is 1.
                i = 1;
            }
            else // The records size if more than 1024 bytes.
            {
                // If the record is less than 2048 bytes long.
                if( SizeOfRecord < 2048 )
                {
                    // The free list index is 2.
                    i = 2;
                }
                else // The records size if more than 2048 bytes.
                {
                    // If the record is less than 4096 bytes long.
                    if( SizeOfRecord < 4096 )
                    {
                        // The free list index is 3.
                        i = 3;
                    }
                    else // The records size if more than 4096 bytes.
                    {
                        // The free list index is 4.
                        i = 4;
                    }
                }
            }
        }
    }
    
    // Refer to the address of the start of the free list
    // associated with records of the given size.
    AtFreeList = (u8**) ( N->FreeListTable + (i<<2) );

    // If the record would be on one of the homogenous free lists.
    if( i > 4 )
    {
        // Refer to the first element on the free list as a
        // 'PlaceName' record.
        P = (PlaceName*) *AtFreeList;
        
        // If there's a record on the free list.
        if( P )
        {
            // Take the record off the free list.
            *AtFreeList = P->PlaceAddress;
        }
        else // Allocate a record within the mass memory.
        {
            // Allocate space for the record in the name table.
            P = (PlaceName*) 
                AllocateMS( N->Storage, SizeOfRecord );
        }
    }
    else // This record could be found on a heterogenous 
         // free list.
    {
        // Default to no record being found on any free list.
        P = 0;
    
        // Make a cursor to scan the free list.
        C = AtFreeList;
        
        // As long as the end of the list hasn't been reached.
        while( C )
        {
            // If the size of the current record matches the
            // size needed.
            if( ( (u32) C[1] ) == SizeOfRecord )
            {
                // Refer to the element on the free list as a
                // 'PlaceName' record.
                P = (PlaceName*) C;
                
                // Take the record off the free list.
                *AtFreeList = P->PlaceAddress;
            }
            else // Not the right size.
            {
                // Update the trailing cursor.
                AtFreeList = C;
                
                // Advance the leading cursor.
                C = (u8**) *C;
            }
        }
        
        // If a free record was not found.
        if( P == 0 )
        {
            // Allocate space for the record in the name table.
            P = (PlaceName*) 
                AllocateMS( N->Storage, SizeOfRecord );
        }
    }

    // Set the place address.
    P->PlaceAddress = APlace;
    
    // Copy the string into place.
    CopyString( AName, &P->NameOfPlace );

    // Return the address of the new record.
    return( P );
}

/*------------------------------------------------------------
| NamePlace
|-------------------------------------------------------------
|
| PURPOSE: To associate a name with an abstract place, perhaps
|          a place in memory.
|
| DESCRIPTION: 
|
|      1. Look for record matching the given name.
|
|      2a. If existing record found:
|          If the new place address is different than the 
|          current one, delete the old place index and
|          insert the new one.
|
|      2b. If matching record is not found:
|          i.   Makes a 'PlaceNameRecord' for the name in 'Storage'.
|          ii.  Insert a place look-up record.
|          iii. Insert a name look-up record.
|
| EXAMPLE:  
|           NamePlace( N, "Atlantis", SomeAddress );
|
| NOTES: 
|
| ASSUMES: If using Patricia tree, names can be at most 256
|          bytes under current configuration.
|
| HISTORY: 09/05/89
|          09/20/89 Pre-existing record check added
|          10/13/89 Name changed from 
|                      'AssociateIdentifierWithReferent'
|          11.30.93 Name changed from 
|                   'AssociateUniqueIdentifierWithReferent'.
|          11.08.98 Generalized to support multiple name 
|                   tables.
------------------------------------------------------------*/
void
NamePlace( NameAt* N, s8* AName, u8* APlace )
{
    PlaceName*  P;
    s32         C;
    ThatRecord  R;

#if USE_PATRICIA_TREE

    PatNode*    Q;
    u32         NameSize, NameSizeFound;
    
    // Calculate the length of the given name string without
    // the terminal zero byte.
    NameSize = CountString( AName );

**** replace this with FindMatchPatricia when updating.

    // Look up the name in the name-to-place index.
    Q = FindLongestMatchPatricia( 
            N->NameIndex,   // The tree to be searched. 
                            // 
            (u8*) AName,    // The value of the key to look for.
                            //
            NameSize,       // How many bytes are in the key.
                            // 
            &NameSizeFound );   
                            // OUT: How many bytes are in the 
                            // longest matching key.

    // If the name was found in the index.
    if( Q && *NameSizeFound >= NameSize )
    {
        // Refer to the address of the 'PlaceName' record.
        P = (PlaceName*) Q->Info;
        
        // If the address is new.
        if( P->PlaceAddress != APlace )
        {
            // Locate the place address in the place look-up
            // table.
            FindRecord( 
                N->PlaceLookUpTable,   
                      // The record table.
                      //
                (u8*) &P, 
                      // Address of the search key.
                      //
                &R ); // Returns the record or nearby record.
                
            // Delete the old place record.
            DeleteRecords( &R, 1 );
            
            // Update the address of in the 'PlaceName' record.
            P->PlaceAddress = APlace;
            
            // Insert a new place index record.
            InsertPatricia( 
                N->PlaceIndex,      
                        // The tree where the key should be
                        // inserted.
                        // 
                (u8*) &APlace,  
                        // The address of the key to insert.
                        //
                4,      // How many bytes are in the key.
                        //
                P );    // Any value associated with the key. 
        }
    }

#else // Not USE_PATRICIA_TREE

    // Refer to the given name as if it were already in a
    // 'PlaceName' record.
    P = (PlaceName*) (AName - 4);
    
    // Locate the place address in the place look-up
    // table.
    C = FindRecord( 
            N->NameLookUpTable,   
              // The record table.
              //
            (u8*) &P, 
              // Address of the search key: regard the name
              // as part of a PlaceName record for searching
              // purposes.
              //
            &R ); // Returns the record or nearby record.

    // If the name is already in the table.
    if( C == 0 ) 
    {
        // Refer to the address of the 'PlaceName' record.
        P = *( (PlaceName**) R.TheRecord );
        
        // If the address is new.
        if( P->PlaceAddress != APlace )
        {
            // Locate the place address in the place look-up
            // table.
            FindRecord( 
                N->PlaceLookUpTable,   
                      // The record table.
                      //
                (u8*) &P, 
                      // Address of the search key.
                      //
                &R ); // Returns the record or nearby record.
                
            // Delete the old place record.
            DeleteRecords( &R, 1 );
            
            // Update the address of in the 'PlaceName' record.
            P->PlaceAddress = APlace;
            
            // Insert a new place index into the table.
            InsertOrderedRecords( 
                N->PlaceLookUpTable,                
                            // The table where the records go.
                            //
                (u8*)&P,    // Where the records to be 
                            // inserted are.  If there is more
                            // than one record they are
                            // adjacent in memory.
                            //
                1 );        // How many records are to be
                            // inserted.
        }
    }
    else // The name isn't yet in the table.
    {
        // Make a 'PlaceName' record in the name table.
        P = MakePlaceNameRecord( N, APlace, AName );
    
        // Insert a new place index into the table.
        InsertOrderedRecords( 
            N->PlaceLookUpTable,                
                        // The table where the records go.
                        //
            (u8*)&P,    // Where the records to be 
                        // inserted are.  If there is more
                        // than one record they are
                        // adjacent in memory.
                        //
            1 );        // How many records are to be
                        // inserted.
    
        // Insert a new name index into the table.
        InsertOrderedRecords( 
            N->NameLookUpTable,             
                        // The table where the records go.
                        //
            (u8*)&P,    // Where the records to be 
                        // inserted are.  If there is more
                        // than one record they are
                        // adjacent in memory.
                        //
            1 );        // How many records are to be
                        // inserted.
    }
#endif

}

/*------------------------------------------------------------
| RunMeToDemoNameAt
|-------------------------------------------------------------
|
| PURPOSE: To demonstrate some 'NameAt' functions.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.27.98 From 'NameItDemonstration()'.  Tested OK.
------------------------------------------------------------*/
void
RunMeToDemoNameAt()
{
    NameAt*     N;
    
    printf( "\n============ BEGIN NameAt DEMO =============\n" );
    
    printf("\nMake a new 'NameAt' symbol table.\n");

    N = MakeNameAt();
    
    printf("\nName five places.\n");
 
    NamePlace( N, "Length", (u8*)  17 );
    NamePlace( N, "Width",  (u8*) 134 );
    NamePlace( N, "Height", (u8*) 124 );
    NamePlace( N, "Depth",  (u8*)  33 );
    NamePlace( N, "Radius", (u8*)  78 );

    printf("\nList the named places by name:\n");
    DumpPlaceNames( stdout, N );
    
    printf("\nList the named places by address:\n");
    DumpPlaceNamesByPlace( stdout, N );

    printf("\nDelete the record named 'Depth':\n");
    DeletePlaceNameByName( N, "Depth" );
    DumpPlaceNames( stdout, N );

    printf("\nDelete the record named 'Width':\n");
    DeletePlaceNameByName( N, "Width" );
    DumpPlaceNames( stdout, N );

    printf("\nName 39 as 'abcde':\n");
    NamePlace( N, "abcde", (u8*)  39 );
    DumpPlaceNames( stdout, N );

    printf("\nDelete the record addressed '78':\n");
    DeletePlaceNameByPlace( N, 78 );
    DumpPlaceNames( stdout, N );
    
    printf("\nDelete the symbol table.\n");
    DeleteNameAt( N );

    printf( "\n============ END NameAt DEMO =============\n" );
}
