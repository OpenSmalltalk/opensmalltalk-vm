/*------------------------------------------------------------
| TLTable.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to data table functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 09.10.98 
------------------------------------------------------------*/

#ifndef TLTABLE_H
#define TLTABLE_H

#ifdef __cplusplus
extern "C"
{
#endif

// Type definitions and forward references to the structures 
// defined below.
typedef struct Table        Table;
typedef struct RecordBlock  RecordBlock;
typedef struct ThatRecord   ThatRecord;

/*------------------------------------------------------------
| RecordBlock
|-------------------------------------------------------------
|
| PURPOSE: To provide a storage area for some fixed length  
|          data records.
|
| DESCRIPTION: A data table is segmented into blocks of 
| records to reduce fragmentation and facilitate insertion 
| and deletion of records without having to move lots of 
| data.
|
| This is how a 'RecordBlock' is laid out:
|                    
|              MyTable
|                 ^
|   Next  Prior   | 
|   <---  ---->   |
|      |  |       |                        
|     ==================================================
|     |   <header>  | Record0, 1, 2 ... N |   <free>   |
|     ==================================================
|                    ^                     ^            ^
|                    |                     |            |
|                FirstRecord          EndOfData  EndOfBlock
|   where:
|
|   <header> holds the information about the record block:
|            the <header> contains the fields of a 
|            'RecordBlock' struct.
|
|   'Record0, 1, 2...' is the field where the data records
|                      are stored.
|
|   <free>    is the space where new records can be added.
|
|   'Next'    is the address of the record block immediately
|             after this one in the table.
|
|   'Prior'   is the address of the record block immediately
|             before this one in the table.
|
|   'MyTable' is a link to the data table that owns this
|             block of records.
|
|   The total size of a 'RecordBlock' is calculated as
|
|       TotalByteCount = EndOfBlock - StartOfBlock
|
|   where 'StartOfBlock' is the address of the first byte
|   of the 'RecordBlock'.
|
|   The total number of actual data bytes is calculated
|   using:
|
|          ActualDataBytes = EndOfData - FirstRecord
|
|   The total number of potential data bytes, the data storage
|   capacity of the block, is calculated by:
|
|          PotentialDataBytes = EndOfBlock - FirstRecord
|
|   The record size can be found via the 'MyTable' link to the 
|   'Table' record that owns this block, in the 'BytesPerRecord' 
|   field of that record.
| 
| NOTE: The header of this record is 28 bytes long.
|
| HISTORY: 09.10.98 
|          10.04.98 Added 'RecordCount' field.
|          10.12.98 Replaced 'Item' record with 'Next' and
|                   'Prior' fields for speed.
------------------------------------------------------------*/
struct RecordBlock
{
    RecordBlock*    Next;       
                        // Address of the next block in the 
                        // list.  The last block has a zero
                        // in this field.
                        //
    RecordBlock*    Prior;      
                        // Address of the prior block in the 
                        // list. The first block has a zero
                        // in this field.
                        //
    Table*          MyTable;        
                        // The address of the 'Table'
                        // record that owns this block.
                        //
    u32             RecordCount;    
                        // How many records are currently 
                        // held in the block.
                        //
    u8*             FirstRecord;    
                        // Where the data records are stored, 
                        // the address of the first data 
                        // record in the block if there is one.
                        //
    u8*             EndOfData;   
                        // Where the actual data records end, 
                        // the first byte after the last 
                        // actual data record.
                        //
    u8*             EndOfBlock;     
                        // Where the 'RecordBlock' ends, the 
                        // first byte after the end of the 
                        // block.
    // RECORD DATA BEGINS HERE ------------------------------
    //
    // Space for 'RecordsPerBlock' (see Table below) data 
    // records is allocated here when the record block is 
    // first allocated. 
    //
    // The address in 'FirstRecord' refers here, the byte
    // following the last byte of the 'EndOfBlock' field.
};

/*------------------------------------------------------------
| Table
|-------------------------------------------------------------
|
| PURPOSE: To specify a table of fixed-length data records 
|          that are either ordered or unordered.
|
| DESCRIPTION: This data structure is used in situations 
| where the record size is known but the number of records is 
| unknown and subject to change.  While it's possible to 
| simply reallocate the whole table each time, that could
| badly fragment memory.
|
| The solution is to compose the table out of fixed size 
| blocks that are linked together to form the whole table,
| like this:
|
| Records are held in a fixed size RecordBlock,
|
|                        RecordBlock
|       ================================================
|       |  [Record0] [Record1] [Record2] ... [RecordN] |       
|       ================================================
|
| and record blocks are linked together like this:
|
|               RecordBlock  RecordBlock  RecordBlock
|                 ========     ========     ========
|      [Table]--> |      |---->|      |---->|      | 
|                 |      |<----|      |<----|      |
|                 ========     ========     ========
|
| When the space within a block is exhausted, a new record
| block is inserted adjacent to the original block to receive 
| the overflow records generated by the insertion of new records.
|
| When the last record is deleted from a block, the record
| block is deleted, unless the block is the last block in
| the table: the table always has at least one block 
| available to hold data records.
|
| In addition, for speed, there is a subordinate table of
| block addresses that refers to each record block indirectly, 
| like this:
|
|                         RecordBlock  RecordBlock  RecordBlock
|                          ========     ========     ========
|      [Table]<----------> |      |---->|      |---->|      |--->
|       |                  |      |<----|      |<----|      |<---
|       |                  ========     ========     ========
|      \|/                 ^            ^            ^
|   [BlockAddressTable]    |            |            |
|       |                  |            |            |
|      ==========          |            |            |
|      |[Block0]------------            |            |
|      |[Block1]-------------------------            |
|      |[Block2]--------------------------------------
|      ==========
|    
|
| The Block Address Table must be updated after block list 
| changes to keep it in sync.
| 
| To avoid needless updating of the Block Address Table, 
| updating is deferred until the Block Address Table is 
| required for sorting or searching.
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
| NOTE: 
|
| HISTORY: 09.10.98 
|          10.12.98 Removed reliance on general 'List' 
|                   structures after testing to remove 
|                   indirection and increase speed.
|          12.01.98 Added lookaside buffer to increase search
|                   speed.
------------------------------------------------------------*/
struct Table
{
    u32             LookIndex[16];
                        // A lookaside buffer that holds 
                        // record index numbers of recently 
                        // found records using 'ToNthRecord()'.
                        //
                        // The low four bits of the target
                        // record index is used as the index
                        // into this table.
                        //
                        // Empty entries hold 0xFFFFFFFF.
                        //
    RecordBlock*    LookBlock[16];
                        // The block address corresponding to
                        // the record index in 'LookIndex[]'.
                        //
    u8*             LookRecord[16];
                        // The record address corresponding to
                        // the record index in 'LookIndex[]'.
                        //
    u32             BytesPerRecord; 
                        // How many bytes are in each
                        // data record.
                        //
    u32             RecordsPerBlock;
                        // How many records should be
                        // held in each block.  This 
                        // controls the separation of 
                        // the table into contiguous
                        // blocks.
                        //
    u32             RecordCount;    
                        // How many data records are 
                        // currently in the table.
                        //
    CompareProc     CompareKeyProcedure;
                        // The function that's called to
                        // compare the keys of records 
                        // in the table. This function 
                        // controls sorting and 
                        // searching of ordered tables. 
                        //
                        // 'CompareKeyProcedure' holds
                        // zero if the table isn't ordered.
                        //
    u32             KeyOffset;      
                        // Byte offset from the beginning
                        // of a data record to the field
                        // that holds the sorting key 
                        // value of the record.
                        //
    u32             KeySize;        
                        // Size of the key field in bytes.
                        //
    RecordBlock*    FirstBlock;
                        // The first block in the block list.
                        //
    RecordBlock*    LastBlock; 
                        // The last block in the block list.
                        //
    u32             BlockCount; 
                        // How many blocks are in the list.
                        //
    Table*          BlockAddressTable;      
                        // Table of block addresses in the
                        // block list. This table is only used 
                        // to speed searching for records by 
                        // key in ordered lists. This holds 
                        // zero if the table is missing.  
                        //
    u32             IsBlockAddressTableCurrent;
                        // Holds '1' if the records in the
                        // Block Address Table are current
                        // with respect to the block list.
                        // This flag controls the updating of
                        // the Block Address Table prior to
                        // searching.
                        //
    u32             IsLookasideEmpty;
                        // Holds '1' if the lookaside buffer
                        // is empty.
};

/*------------------------------------------------------------
| ThatRecord
|-------------------------------------------------------------
|
| PURPOSE: To provide a way to refer to a single record in
|          the context of a table.  
|
| DESCRIPTION: Think of this record as a finger pointing at a 
| record in a table to select it for special processing. 
|
| This record organizes everything needed to refer to a data 
| record in a way that supports easy traversal through the 
| table.
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 09.29.98
|          10.12.98 Name changed from 'OneRecord'.
------------------------------------------------------------*/
struct ThatRecord
{
    u8*          TheRecord; // Address of the data record or
                            // zero if there is no record.
                            //
    RecordBlock* TheBlock;  // Address of the block that holds
                            // the data record.
                            //
    Table*       TheTable;  // Address of the table that holds
                            // the data record.
                            //
    u32          BytesPerRecord; 
                            // The number of bytes per record, 
                            // copied here from the 'Table' 
                            // record to speed record 
                            // traversal.
};
  
s32             CompareKeyToRecord( u8*, u8* );
s32             CompareKeyToRecordBlock( u8*, u8* );
void            CopyRecord( ThatRecord*, ThatRecord* );
u32             DeleteIntermediateRecords( ThatRecord*, ThatRecord* );
void            DeleteRecords( ThatRecord*, u32 );
void            DeleteTable( Table* );
void            DisplaceSomeKeys( Table*, u32, u32, s32 );
void            DumpTable( Table* );
void            EmptyTable( Table* );
RecordBlock*    FindBlockInTable( Table*, u8* );
s32             FindNextRecord( Table*, u8*, ThatRecord* );
s32             FindPriorRecord( Table*, u8*, ThatRecord* );
s32             FindRecord( Table*, u8*, ThatRecord* );
s32             FindRecordInBlock( RecordBlock*, u8*, ThatRecord* );
void            InsertBlockAfterBlock( RecordBlock*, RecordBlock* );
void            InsertBlockBeforeBlock( RecordBlock*, RecordBlock* );
void            InsertBlockFirst( Table*, RecordBlock* );
void            InsertBlockLast( Table*, RecordBlock* );
void            InsertOrderedRecords( Table*, u8*, u32 );
void            InsertRecordsAfter( ThatRecord*, u8*, u32 );
void            InsertRecordsBefore( ThatRecord*, u8*, u32 );
void            InsertRecordsFirst( Table*, u8*, u32 );
void            InsertRecordsLast( Table*, u8*, u32 );
RecordBlock*    MakeRecordBlock( u32, u32 );
Table*          MakeTable( u32, u32, CompareProc, u32, u32 );
void            RunMeToDemoTLTable();
u32             ShiftRecordsToNextBlock( ThatRecord*, u32 );
u32             ShiftRecordsToPriorBlock( ThatRecord*, u32 );
void            ToFirstRecord( Table*, ThatRecord* );
void            ToFirstRecordInBlock( RecordBlock*, ThatRecord* );
void            ToLastRecord( Table*, ThatRecord* );
void            ToLastRecordInBlock( RecordBlock*, ThatRecord* );
void            ToNextRecord( ThatRecord* );
void            ToNthNextRecord( ThatRecord*, u32 );
void            ToNthPriorRecord( ThatRecord*, u32 );
void            ToNthRecord( Table*, ThatRecord*, u32 );
void            ToPriorRecord( ThatRecord* );
void            ValidateTable( Table* );

#ifdef __cplusplus
}
#endif

#endif // TLTABLE_H
