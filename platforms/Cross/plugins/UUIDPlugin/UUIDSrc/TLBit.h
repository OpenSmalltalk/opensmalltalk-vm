/*------------------------------------------------------------
| TLBit.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for bit-addressed memory 
|          access procedures.
|
| DESCRIPTION:  
|
| NOTE: See also 'TLTwo.c' for working with powers of 2.
|
| ASSUMES: Bytes are 8 bits.
|
| HISTORY: 01.20.00 Move bit transfer functions to 
|                   TLBitTransfer.h.
------------------------------------------------------------*/
    
#ifndef TLBIT_H
#define TLBIT_H

#ifdef __cplusplus
extern "C"
{
#endif

/*------------------------------------------------------------
| BitCursor
|-------------------------------------------------------------
| 
| PURPOSE: To refer to a bit in memory.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
|            
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 12.28.99
------------------------------------------------------------*/
typedef struct
{
    u8* AtByte; // Address of the current byte.
                //
    u8  AtBit;  // Mask of the current bit -- a single '1'
                // bit in the position of the current bit.
                //
    u8  IsLowBitFirst;
                // '1' if the low-order bit of the byte is
                // first or '0' if the high-order bit is
                // first.
} BitCursor;

extern u8   BitOfByte[8];
extern u32  BitOfUnit[32];
extern u8   NotBitOfByte[8];
extern u32  LoMask[32];
extern u32  HiMask[32];
extern u8   ReverseBits[256];

void    AlignToByte( BitCursor* ); 
u64     BitsBetweenBits( BitCursor*, BitCursor* );
u32     CountBitsInBytes( u8*, u32 );
u64     GetBits( BitCursor*, u32 );
void    MakeReverseBits();
void    PadToByte( BitCursor*, u32 );
void    PutBits( BitCursor*, u32, u64 );
void    ReferToFirstBit( BitCursor*, u8*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
