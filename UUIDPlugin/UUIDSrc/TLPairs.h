/*------------------------------------------------------------
| TLPairs.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for pair-addressed memory 
|          access procedures.
|
| DESCRIPTION: A 'pair' is two contiguous bytes.
|
| NOTE: 
|
| HISTORY: 01.22.97 from 'Bytes.h'.
------------------------------------------------------------*/
    
#ifndef TLPAIRS_H
#define TLPAIRS_H

#ifdef __cplusplus
extern "C"
{
#endif

void        ABAddPairs( u16*, u16*, u16*, u32 );
void        ABAndPairs( u16*, u16*, u16*, u32 );
void        ABBlendPairs( u16*, u16*, u16*, u16*, u16*, u16*, 
                          u32, u32 );
void        ABMultPairs( u16*, u16*, u16*, u32 );
void        ABOrPairs( u16*, u16*, u16*, u32 );
void        ABUnblendPairs( u16*, u16*, u16*, u16*, 
                            u16*,  u16*, u32 );
void        ABXorPairs( u16*, u16*, u16*, u32 );
void        AndPairs( u16*, u16*, u32 );
s32         Compare_u16( s8*, s8* );
void        CopyObjectPairs( u16*, u16*, u16*, u16*, u32 );
void        CopyPairs( u16*, u16*, u32 );
void        CopyInversePairs( u16*, u16*, u32 );
void        FillPairs( u16*,  u32, u32 );
u32         GetPair( u16* );
void        OrPairs( u16*, u16*, u32 );
void        PutPair( u16*, u32 );
void        XorPairs( u16*, u16*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLPAIRS_H
