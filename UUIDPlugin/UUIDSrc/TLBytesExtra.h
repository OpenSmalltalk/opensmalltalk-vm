/*------------------------------------------------------------
| TLBytesExtra.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for less commonly used 
|          byte-addressed memory functions.
|
| DESCRIPTION:  
|
| NOTE: See 'TLParse.h' for scanning and parsing functions.
|
| HISTORY: 05.29.01 from TLBytes.h.
------------------------------------------------------------*/
    
#ifndef TLBYTESEXTRA_H
#define TLBYTESEXTRA_H

#ifdef __cplusplus
extern "C"
{
#endif

// Info about an array of byte values organized in
// row major order.
typedef struct
{
    u32 RowCount; // How many rows are in the array.
    u32 ColCount; // How many columns.
    u8* Data;     // Where the data is.
} ByteArray;

// Info about an array of printable Ascii values organized in
// row major order. Must be same exact format as 'ByteArray'
// so that they can be interchangable with respect to 
// procedures that use the two structures.
typedef struct
{
    u32 RowCount; // How many rows are in the array.
    u32 ColCount; // How many columns.
    s8* Data;     // Where the data is.
} AsciiArray;

void        ABAddBytes( u8*, u8*, u8*, u32 );
void        ABBlendBytes( u8*, u8*, u8*, u8*, u8*, u8*, u32, u32 );
void        ABMultBytes( u8*, u8*, u8*, u32 );
void        ABOrBytes( u8*, u8*, u8*, u32 );
void        ABUnblendBytes( u8*, u8*, u8*, u8*, u8*, u8*, u32 );
void        ABXorBytes( u8*, u8*, u8*, u32 );
void        AddToBytes( u8*, u32, u32 );
void        AndBytes( u8*, u8*, u32 );
void        AndBytesTwoSrc( u8*, u8*, u8*, u32);
void        BuildCRC32Table();
u16         BytesToUint16(u8*);
u32         BytesToUint32(u8*);
void        CopyInverseBytes( u8*, u8*, u32 );
void        CopyObjectBytes( u8*, u8*, u8*, u8*, u32 );
u32         CRC32Byte( u32, u16 );
u32         CRC32Bytes( u8*, u32, u32 );
u16         CRCByte(u16, u16);
u16         CRCBytes(u8*, u32, u16);
void        DeleteByteArray( ByteArray* );
u32         GetByte( u8* );
ByteArray*  MakeByteArray( u32, u32 );
void        OrBytes( u8*, u8*, u32 );
void        OrBytesTwoSrc( u8*, u8*, u8*, u32 );
void        PutByte( u8*, u32 );
void        Uint16ToBytes(u16,u8*);
void        Uint32ToBytes(u32,u8*);
void        ValidateBytesMatch( u8*, u8*, u32 );
void        XorBytes( u8*, u8*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
