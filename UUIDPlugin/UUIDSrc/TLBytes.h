/*------------------------------------------------------------
| TLBytes.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for basic byte-addressed 
|          memory functions.
|
| DESCRIPTION:  
|
| NOTE: See 'TLParse.h' for scanning and parsing functions.
|
| HISTORY: 02.15.93 
|          01.12.94 added IsByteInBytes
|          01.20.94 added 'ReplaceRangeInBuffer'
|          08.19.97 added C++ support.
|          05.29.01 moved less commonly used functions to
|                   TLBytesExtra.h.
|          06.06.01 Moved Adler32() here from TLBytesExtra.h.
|          08.19.01 Changed size of parameter for 
|                   IsByteInBytes.
------------------------------------------------------------*/
    
#ifndef TLBYTES_H
#define TLBYTES_H

#ifdef __cplusplus
extern "C"
{
#endif

u32         Adler32( u8*, u32, u32 );
s32         CompareAddresses( s8*, s8* );
s32         CompareBytes( u8*, u32, u8*, u32 );

#ifndef     CopyBytes // May be already defined to use 'BlockMoveData'.
void        CopyBytes( u8*, u8*, u32 );
#endif

void        CountBytes( u8*, u32, u32*);
u32         ExchangeByte( u8*, u32 );
void        ExchangeBytes(u8*, u8*, u32);
void        FillBytes( u8*, u32, u32 );
u32         IsByteInBytes( u8*, u32, u32 );
u32         IsMatchingBytes( u8*, u8*, u32 );
void        LockByte( u8* );
u32         ReadBytePort( u32 );
void        ReplaceBytes(u8*, u32, u16, u16);
void        UnlockByte( u8* );
void        ZeroBytes( u8*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
