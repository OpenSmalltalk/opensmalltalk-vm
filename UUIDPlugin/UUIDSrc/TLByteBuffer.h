/*------------------------------------------------------------
| TLByteBuffer.h
|
| PURPOSE: To provide interface to byte buffer functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 10.12.95 
|          08.19.97 added C++ support.
|          09.10.98 Changed names of 'ByteBuffer' fields;
|                   added 'InsertDataBytes()' and 
|                   'MakeByteBuffer()'.
------------------------------------------------------------*/

#ifndef _BYTEBUFFER_H_
#define _BYTEBUFFER_H_

#ifdef __cplusplus
extern "C"
{
#endif

/*------------------------------------------------------------
| ByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To specify a buffer used to hold bytes.
|
| DESCRIPTION: The bytes are held in a dynamically allocated
| buffer.
|
| Each ByteBuffer record looks like this:
|
|                          ByteBuffer
|       -------------------------------------------------- 
|       | AtBuffer | BufferSize | DataOffset |  DataSize |  
|       -------------------------------------------------- 
| Bytes:    4       4              4              4          
|    
|
| and the allocated buffer looks like this:
|
|     AtBuffer
|     |
|     |-- DataOffset ->|<--    DataSize   -->|
|     -------------------------------------------------------
|     |                |/////////////////////|              |
|     -------------------------------------------------------
|     |<---------------------- BufferSize ----------------->|
|                         
| The position of the data section within the buffer may be
| shifted from the start of the buffer, particularly if data 
| is consumed there.  
|
| The buffer is reallocated as needed to accomodate all the
| data added to the buffer.                  
|
| NOTE: 
|
| HISTORY: 10.12.95  
|          09.10.98 Field name changes and added 
|                   'AllocationQuantum'.
------------------------------------------------------------*/
typedef struct
{
    u8* AtBuffer;           // Where the bytes are in RAM.
                            // Always dynamically allocated 
                            // and owned by the 'ByteBuffer' 
                            // structure.
                            //
    u32 BufferSize;         // How many bytes are allocated to
                            // the buffer.
                            //
    u32 AllocationQuantum;  // The allocation unit, the 
                            // minimum step size for buffer 
                            // growth expressed in terms of
                            // bytes.
                            //
    u32 DataOffset;         // Offset of the first data byte in
                            // the buffer.
                            //
    u32 DataSize;           // Count of how many data bytes are
                            // in the buffer, a contiguous span.
} ByteBuffer;

void        AppendByteBuffer( ByteBuffer*, ByteBuffer* );
void        AppendBytesToBuffer( ByteBuffer*, u8*, u32 );
void        AppendListDataAddressesToBuffer( ByteBuffer*, List* );
u8*         AtDataByteOffset( ByteBuffer*, s32 );
void        CopyByteBuffer( ByteBuffer*, ByteBuffer* );
void        DeleteByteBuffer( ByteBuffer* );
void        DeleteDataBytes( ByteBuffer*, u8*, u32 );
void        DeleteFirstDataBytes( ByteBuffer*, u32 );
void        DeleteLastDataBytes( ByteBuffer*, u32 );
void        DeleteByteBufferData( ByteBuffer* );
void        EmptyByteBuffer( ByteBuffer* );
void        EnsureByteBufferHasSpace( ByteBuffer*, u32 );
s32         GetByteAtDataOffset( ByteBuffer*, s32 );
void        InsertDataBytes( ByteBuffer*, u32, u8*, u32 );
void        LoadFileToByteBuffer( s8*, ByteBuffer* );
ByteBuffer* MakeByteBuffer( u32 );
void        PrependBytesToBuffer( ByteBuffer*, u8*, u32 );
s32         PullFirstDataByte( ByteBuffer* );
s32         PullLastDataByte( ByteBuffer* );
void        PutDataByteAtOffset( ByteBuffer*, s32, u8 );
void        ShiftDataToOffset( ByteBuffer*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _BYTEBUFFER_H_
