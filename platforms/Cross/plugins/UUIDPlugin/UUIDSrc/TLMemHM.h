/*------------------------------------------------------------
| TLMemHM.h
|-------------------------------------------------------------
|
| PURPOSE: To provide an interface to hierarchical memory 
|          allocation functions.
|
| DESCRIPTION:  
|
| HISTORY: 05.26.01 TL From TLMassMem.h and TLMem.h.
------------------------------------------------------------*/

#ifndef TLMEMHM_H
#define TLMEMHM_H

#ifdef __cplusplus
extern "C"
{
#endif

#define MAX_WASTED_BYTES (1024)
            // The most number of bytes that we're willing
            // to waste in a best-fit allocation.

typedef struct Lot   Lot;

/*------------------------------------------------------------
| Lot
|-------------------------------------------------------------
|
| PURPOSE: To specify a hierarchical memory allocation block.
|
| DESCRIPTION: The term 'lot' is used here to mean a distinct 
| portion, parcel or allotment of memory.
|
| This structure unites the functions of a memory allocation
| block with a directory tree to provide a way to integrate
| and subdivide memory allocation blocks.   
|
| This structure organizes the information needed to allocate
| memory lots directly from the operating system or 
| indirectly within another memory lot.
|
| This structure is also designed to support sharing lots
| between processes which may independently allocate and
| free the same lot.  A reference counter implements this
| function.
|
| There are four link fields used to connect Lot records
| together, 'Super', 'Next', 'Prev' and 'Sub'.
|
|                        [LOT]
|                          ^
|                          | via Super
|                          | 
|                          |
|             [LOT]<-----[LOT]----------->[LOT]
|                    via   |   via Next
|                    Prev  |            
|                          | 
|                          | via Sub
|                          V
|                        [LOT]
|  
| The logical interpretation of these links is explained
| below in the LINKS section.
|
| This is how a 'Lot' is laid out in memory:
|          
|                   |<--------- Data Buffer  --------->|
|     ==================================================
|     |   <header>  |.....................|   <free>   |
|     ==================================================
|                    ^                     ^            ^
|                    |                     |            |
|                    Lo                    Hi         HiBuf
|   where:
|
|   <header> contains all the fields of a 'Lot' struct.
|
|   'Data Buffer' is the field where data can be stored.
|                 Subordinate Lots if any are stored here.
|
|   <free>   is the area of the Data Buffer which does not
|            currently contain data.
|
| ASSUMES: Lots must remain at fixed locations in memory
|          throughout their allocated lifetime.
|
| HISTORY: 05.24.01 TL From TLBuf.h, TLMassMem.h., TLMem.h.
|          05.30.01 TL Changed links to support bidirectional
|                      links within the same pool.  This was
|                      done to make it easier to allocate
|                      blocks directly from the OS.
------------------------------------------------------------*/
struct Lot
{
//  u32 ID;         // ID number field for a Lot record 
                    // holding the value 'Pool'.
                    //
    ////////////////////////////////////////////////////////// 
    //                                                      //
    //                      L I N K S                       //
    //                                                      //
    Lot* Super;     // To the superior lot, the one from which 
                    // the current lot is allocated.  
                    //
                    // If this lot is allocated directly from 
                    // the operating system then the Super 
                    // link is zero.
                    //
    Lot* Next;      // To the next block in the current pool
                    // or zero if there is no next lot.
                    //
    Lot* Prev;      // To the prior block in the current pool
                    // or zero if there is no prior lot.
                    //
    Lot* Sub;       // To the first subordinate lot or 
                    // zero if there are no subordinates.
    //                                                      //
    ////////////////////////////////////////////////////////// 
                    // 
                    //
    s32 ReferenceCount; 
                    // Reference counter for this allocation
                    // lot.
                    //
                    // Zero means this lot is free for re-use.
                    //
    u8* Lo;         // Base address of the Data Buffer, the
                    // place where the first byte of data is 
                    // stored.
                    //
    u8* Hi;         // Where the actual data ends in the 
                    // Data Buffer, the address of the first 
                    // byte after the data.
                    //
                    //        DataSize = Hi - Lo
                    //
    u8* HiBuf;      // Where the Data Buffer itself ends, the 
                    // address of the first byte after the 
                    // Data Buffer.
                    //
                    //        BufferSize = HiBuf - Lo
                    //
    ////////////////////////////////////////////////////////// 
    //                                                      //
    //               DATA BUFFER BEGINS HERE                //
    //
    // Space for data is allocated here when the Lot is 
    // allocated. 
    //
    // |<---------The 'Lo' address refers here, the first 
    //            byte following the 'HiBuf' field.
    //                                                      //
    ////////////////////////////////////////////////////////// 
};

// PURPOSE: To translate the data buffer address of a Lot
//          allocation block into the Lot header address.
#define AddressOfLotHeader(d)  ((Lot*) ((u8*) d - sizeof(Lot)))

// PURPOSE: To translate the a Lot header address into the 
//          data field address.
#define AddressOfLotDataBuffer(u) ( (u8*) u + sizeof(Lot) ) 

extern Lot* TheBufPool;
                // The allocation pool from which all data
                // in Buf functions is allocated.

extern u32  TheTotalBytesInUseHM;
                // The total number of bytes allocated by HM
                // functions which have not also been freed
                // via HM functions.
                
extern u32  TheMostBytesInUseHM;
                // The highest total number of bytes ever
                // in-use at any one time that were allocated 
                // by HM functions.
                
extern u32  ThePoolQuantum;
                // The size of an allocation unit when 
                // allocating a pool from the OS memory pool.
                //
                // Set the default allocation pool unit to
                // 4K, the size of PAGE_SIZE in Windows2000.

extern u32  TheMinimumPoolSize;
                // The minimum number of bytes that can be
                // allocated from the OS memory pool.
                //
                // Set the default allocation pool unit to
                // 4K, the size of PAGE_SIZE in Windows2000.
 
void    AllocateBuf( Buf*, u32 );
void*   AllocateMemoryAnyPoolHM( Lot*, u32 );
void*   AllocateMemoryHM( Lot*, u32 );
u32     CalculateTotalBlockSize( u32 );
u32     CalculateTotalPoolSize( u32 );
void    DumpLot( Lot* );
void    EmptyLot( Lot* );
void    ExtractLot( Lot* );
Lot*    FindBestFitLot( Lot*, u32 );
void    FreeBuf( Buf* );
void    FreeMemoryHM( void* );
void    MakeRoomInBuf( Buf*, u32 ); 
Lot*    ToMostSuperiorPool( Lot* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLMEMHM_H
