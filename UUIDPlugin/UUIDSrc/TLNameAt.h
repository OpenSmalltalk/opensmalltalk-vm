/*------------------------------------------------------------
| TLNameAt.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to named place functions.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 12.09.93
|          11.08.98 Revised to use tables instead of lists;
|                   generalized to multiple name tables.
|          11.24.98 Name changed from 'TLNameIt.h'.
------------------------------------------------------------*/

#ifndef _TLNAMEAT_H_
#define _TLNAMEAT_H_

typedef struct NameAt     NameAt;
typedef struct PlaceName  PlaceName;
     
/*------------------------------------------------------------
| PlaceName
|-------------------------------------------------------------
|
| PURPOSE: To associate a place with a name.
|
| DESCRIPTION:
| 
| Each 'PlaceName' record has this form: 
|                                                             
|                  PlaceName Record          
|      --------------------------------------  
|      |  PlaceAddress  |  NameOfPlace  | 0 |  
|      --------------------------------------  
|          4 bytes      |<-size varies->| terminal 0  
|   
| where: 'PlaceAddress' is the address associated with the 
|                       name.
|
|        'NameOfPlace' is the name associated with the place. 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.07.98 Updated.
------------------------------------------------------------*/
struct PlaceName
{
    u8* PlaceAddress;   // The abstract address associated 
                        // with the name: this can be any
                        // 4-byte number.
                        //
    s8  NameOfPlace;    // The name associated with the 
                        // abstract address.
};
 
/*------------------------------------------------------------
| NameAt
|-------------------------------------------------------------
|
| PURPOSE: To organize a place name table.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.07.98
|          11.27.98 Added 'FreeListTable'.
|          03.06.99 Added Patricia tree option.
------------------------------------------------------------*/
struct NameAt
{
#if USE_PATRICIA_TREE

    PatTree*    NameIndex;
                // A dictionary of names associated with 
                // addresses of PlaceName records.  The key of
                // each dictionary entry is the name held in
                // the PlaceName record.

    PatTree*    PlaceIndex;
                // A dictionary of names associated with 
                // addresses of PlaceName records.  The key of
                // each dictionary entry is the place address
                // held in the PlaceName record.
#else

    Table*  PlaceLookUpTable;
            // A table of 'PlaceName' record addresses
            // sorted in increasing order using the
            // 'PlaceAddress' field as a key.
                    
    Table*  NameLookUpTable;
            // A table of 'PlaceName' record addresses
            // sorted by the 'NameOfPlace' field.
#endif
                    
    Mass*   Storage;
            // A mass memory pool for holding any data
            // associated with this table.
            
    u8*     FreeListTable;
            // A table that holds the starting link of
            // 256 linked lists for organizing records
            // in 'Storage' that have been freed for re-use.
            //
            // The lists are indexed by the total size of
            // the 'PlaceName' record that has been freed.
            //
            // For example, a 'PlaceName' record that held
            // the name 'Cat' would have a total size of
            // 4 + 3 + 1 = 8 bytes, in other words, 4 bytes 
            // for the 'PlaceAddress' field, 3 bytes for 
            // 'Cat' and one byte for the zero terminator.
            //
            // The index of the list used to hold the record
            // would be '8', so the entry at FreeListTable[8]
            // would hold the address of the 'PlaceAddress'
            // field of the free record.  When 'PlaceName'
            // records are on a free list, the 'PlaceAddress'
            // field holds the address of the next record
            // in the chain or zero if there is no next record.
            //
            // The lists at indices 0, 1, 2, 3 and 4 are used
            // to hold 'PlaceName' records larger than 255 
            // bytes long such that:
            //
            //   [0] is for records >  255 bytes and <  512.
            //   [1] is for records >  512 bytes and < 1024.
            //   [2] is for records > 1024 bytes and < 2048.
            //   [3] is for records > 2048 bytes and < 4096.
            //   [4] is for records > 4096 bytes.
            //
            // For records larger than 255, the total size of 
            // the record is held in the first 4 bytes of the
            // 'NameOfPlace' field.
};

s32         ComparePlaceAddresses( PlaceName**, PlaceName** );
s32         ComparePlaceNames( PlaceName**, PlaceName** );
void        DeleteNameAt( NameAt* );
void        DeletePlaceNameByName( NameAt*, s8* );
void        DeletePlaceNameByPlace( NameAt* N, u32 );
void        DeletePlaceNameRecord( NameAt*, PlaceName* );
void        DumpPlaceNames( FILE*, NameAt* );
void        DumpPlaceNamesByPlace( FILE*, NameAt* );
void        EmptyPlaceNames( NameAt* );
s8*         FindName( NameAt*, u8* );
u8*         FindPlace( NameAt*, s8* );
NameAt*     MakeNameAt();
PlaceName*  MakePlaceNameRecord( NameAt*, u8*, s8* );
void        NamePlace( NameAt*, s8*, u8* );
void        RunMeToDemoNameAt();


#endif
