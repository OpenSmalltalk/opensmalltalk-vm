/*------------------------------------------------------------
| TLBuf.h
|-------------------------------------------------------------
| 
| PURPOSE: To provide interface to simple memory buffer 
|          functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 12.11.98
------------------------------------------------------------*/

#ifndef TLBUF_H
#define TLBUF_H

#ifdef __cplusplus
extern "C"
{
#endif

/*------------------------------------------------------------
| Buf
|-------------------------------------------------------------
|
| PURPOSE: To specify a standard data storage buffer.
|
| DESCRIPTION: A standard data storage buffer consists of
| two parts, a control record and a data storage buffer. 
|
| Each Buf control record looks like this:
|
|                  Buf
|       -------------------------------
|       | Lo | Hi |  HiBuf  | IsOwned |
|       ------------------------------- 
| Bytes:  4    4        4       1   
|    
|
| and the data buffer looks like this:
|
|     Lo                Hi               HiBuf
|     |                 |                  |
|     |                 |                  |
|     ------------------------------------- 
|     |100101....1010101                  |
|     ------------------------------------- 
|              variable length
|
| NOTE: Data always begins at 'Lo'.
|
| HISTORY: 12.11.98 TL
|          04.10.99 Added the 'IsOwned' field.
|          03.28.00 Name changes: 'HiData' -> 'Hi'
|                                 'Hi' -> 'HiBuf'
------------------------------------------------------------*/
typedef struct
{
    u8* Lo;         // Where the data buffer starts.  Holds
                    // zero if there is no data buffer.
                    //
    u8* Hi;         // Where the data ends in the buffer, the
                    // address of the first byte after the
                    // data.
                    //
                    // DataSize = Hi - Lo;
                    //
    u8* HiBuf;      // Where the data buffer ends, the address 
                    // of the first byte after the buffer.
                    //
                    // BufferSize = HiBuf - Lo;
                    //
    u8 IsOwned;     // 1 if the buffer is dynamically 
                    // allocated and owned by this record,
                    // 0 if not owned or not dynamic.
                    //
                    // Ownership implies that the buffer 
                    // should be deallocated when this 
                    // record is deallocated or abandoned.
} Buf;

/*------------------------------------------------------------
| STANDARD BUFFER MACROS
|-------------------------------------------------------------
|
| PURPOSE: To standardize buffer arithmetic.
|
| DESCRIPTION: These macros take the address of any buffer 
| control record which contains the address fields 'Lo', 'Hi' 
| and 'HiBuf' such that
| 
|      Lo......is the address of the first byte of the buffer.
|
|      Hi......marks the end of the DATA in the buffer, being 
|              the address of the first byte AFTER the data.
|
|      HiBuf...marks the end of the buffer itself, being the 
|              address of the first byte AFTER the buffer.
|
| This diagram shows the relationship of these addresses:
|
|         Lo                Hi               HiBuf
|         |                 |                  |
|         v                 v                  v
|         ------------------------------------- 
|         |SOME.DATA.BYTES..                  |
|         ------------------------------------- 
|
| In otherwords, (Lo, HiBuf) defines the buffer itself and 
| (Lo,Hi) defines the data in the buffer.
|
| ASSUMES: If there is data in the buffer it always begins at
|          the first byte of the buffer.
|
|          Hi can never exceed HiBuf or be less than Lo.
|
| HISTORY: 05.25.01 TL
------------------------------------------------------------*/
// PURPOSE: To calculate the size of a buffer in bytes.
#define SizeOfBuf( b )        (u32) ( (b)->HiBuf - (b)->Lo )

// PURPOSE: To calculate the number of data bytes in a buffer.
#define SizeOfDataInBuf( b )  (u32) ( (b)->Hi - (b)->Lo )

// PURPOSE: To calculate the how many bytes of free space are
//          available at the end of a buffer.
#define RoomInBuf( b )       (u32) ( (b)->HiBuf - (b)->Hi )

// PURPOSE: To test if a buffer is empty.
#define IsBufEmpty( b )      ( (b)->Lo == (b)->Hi )

// PURPOSE: To test if a buffer is full.
#define IsBufFull( b )       ( (b)->HiBuf == (b)->Hi )

// PURPOSE: To test if there is any data in a buffer.
#define IsDataInBuf( b )     ( (b)->Hi > (b)->Lo )

// PURPOSE: To test if there is room in a buffer for a given
//          amount of data.
#define IsRoomInBuf(b,n)     ( RoomInBuf(b) >= n )

u8*  AtDataInBuf( Buf*, s32 );
u32  CopyBuf( Buf*, Buf* );
void DeleteAllMatchingDataInBuf( Buf*, u8*, u32 );
void DeleteDataInBuf( Buf*, u32, u32 );
void DeleteFirstDataInBuf( Buf*, u32 );
void DeleteLastDataInBuf( Buf*, u32 );
void EmptyBuf( Buf* );
u32  GetByteInBuf( Buf*, s32 );
void InsertDataFirstInBuf( Buf*, u8*, u32 );
void InsertDataInBuf( Buf*, u32, u8*, u32 ); 
void InsertDataLastInBuf( Buf*, u8*, u32 );
void PutByteInBuf( Buf*, s32, u8 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLBUF_H
