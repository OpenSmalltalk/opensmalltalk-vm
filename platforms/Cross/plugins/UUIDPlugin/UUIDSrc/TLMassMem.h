/*------------------------------------------------------------
| TLMassMem.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for mass memory allocation
|          procedures.
|
| DESCRIPTION: 
|
| HISTORY: 08.28.93 from ascii.txt.
|          02.24.94 added relocatable memory routines.
|          11.23.96 copied from 'MemAlloc.h' of AK2.
|          11.08.98 Pulled out of 'MacOSMemAlloc.h' and
|                   generalized.
------------------------------------------------------------*/

#ifndef TLMASSMEM_H 
#define TLMASSMEM_H 

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct Mass      Mass;
typedef struct MassBlock MassBlock;

/*------------------------------------------------------------
| MassBlock
|-------------------------------------------------------------
|
| PURPOSE: To provide a storage area for some variable length  
|          data blocks.
|
| DESCRIPTION: A mass memory is collected into blocks to 
| reduce fragmentation.
|
| This is how a 'MassBlock' is laid out:
|                  
|      Next    
|      ---->   
|      |            |<----- Data Storage Field  ------>|
|     ==================================================
|     |   <header>  | ....................|   <free>   |
|     ==================================================
|                    ^                     ^            ^
|                    |                     |            |
|                FirstData            EndOfData     EndOfBlock
|   where:
|
|   <header> holds the information about the mass block:
|            the <header> contains the fields of a 
|            'MassBlock' struct.
|
|   'Data Storage Field' is the field where the data blocks
|            are stored such that a data block is always
|            entirely contained in a single 'MassBlock',
|            never spaning 'MassBlock' boundaries.
|
|            The size of the Data Storage Field is never
|            less than the minimum block size defined for
|            the mass memory pool of which this block is
|            a part.
|
|   <free>   is the space where new data can be added.
|
|   'Next'   is the address of the 'MassBlock' immediately
|            after this one in the block list, or zero if
|            there is no next block.
|
|   The total size of a 'MassBlock' is calculated as
|
|       TotalByteCount = EndOfBlock - StartOfBlock
|
|   where 'StartOfBlock' is the address of the first byte
|   of the 'MassBlock'.
|
|   The total number of actual data bytes is calculated
|   using:
|
|          ActualDataBytes = EndOfData - FirstData
|
|   The total number of potential data bytes, the data storage
|   capacity of the block, is calculated by:
|
|          PotentialDataBytes = EndOfBlock - FirstData
| NOTE: 
|
| HISTORY: 11.08.98 From 'RecordBlock'.
------------------------------------------------------------*/
struct MassBlock
{
    MassBlock*  Next;       
                // Address of the next block in the 
                // list.  The last block has a zero
                // in this field.
                //
    u32         FreeByteCount;
                // How many data bytes are available in this
                // block, calculated using this formula:
                //
                //   FreeByteCount = EndOfBlock - EndOfData
                //
    u8*         FirstData;    
                // Where the data records are stored, 
                // the address of the first data 
                // record in the block if there is one.
                //
    u8*         EndOfData;   
                // Where the actual data records end, 
                // the first byte after the last 
                // actual data record.
                //
    u8*         EndOfBlock;     
                // Holds the address of where the 'MassBlock' 
                // ends, the first byte after the end of the 
                // block.
    // DATA STORAGE FIELD BEGINS HERE ----------------------- 
    //
    // Space for data is allocated here when the mass block is 
    // first allocated. 
    //
    // The address in 'FirstData' refers here, the byte
    // following the last byte of the 'EndOfBlock' field
    // above.
};

/*------------------------------------------------------------
| Mass
|-------------------------------------------------------------
|
| PURPOSE: To organize a mass memory pool.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.08.98
------------------------------------------------------------*/
struct Mass
{
    MassBlock*  FirstBlockToSearch;
                // Holds the address of first block in the
                // mass memory block list that should be 
                // searched for free space when allocating
                // data storage space.
                //
    MassBlock*  FirstBlock;
                // Holds the address of first block in the
                // of the mass memory block list.
                //
    MassBlock*  LastBlock;
                // Holds the address of last block in the
                // of the mass memory block list.
                //
    u32         FreeByteCount;
                // Total of how many free bytes are 
                // currently available in all mass blocks.
                //
    u32         TotalStorageCapacity;
                // The total amount of data storage space 
                // that is currently held in this mass 
                // memory pool, both in-use and free.
                //
    u32         MaximumStorageCapacity;
                // The most amount of memory space that can
                // be set aside to hold this mass memory 
                // pool.
                //
    u32         NextMassBlockSize;
                // The minimum size of the data storage 
                // field of a mass memory block: blocks may 
                // be larger if the required data block is 
                // larger.
};

extern Lot* TheMassMemPool;
                // The allocation pool from which all data
                // in MassMem functions is allocated.



void*       AllocateMS( Mass*, u32 );
void        DeleteDataMS( Mass*, u8*, u32 );
void        DeleteMass( Mass* );
void        EmptyMass( Mass* );
Mass*       MakeMass( u32, u32, u32 );
MassBlock*  MakeMassBlock( u32 );
                  
#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLMASSMEM_H
