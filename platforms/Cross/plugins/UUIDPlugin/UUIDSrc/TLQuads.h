/*------------------------------------------------------------
| TLQuads.h
|-------------------------------------------------------------
| 
| PURPOSE: To provide interface for quad-addressed memory 
|          access procedures.
|
| DESCRIPTION: A 'quad' is four contiguous bytes.
|
| NOTE: 
|
| HISTORY: 01.22.97 from 'Bytes.h'.
------------------------------------------------------------*/
    
#ifndef TLQUADS_H
#define TLQUADS_H

#ifdef __cplusplus
extern "C"
{
#endif

void        ABAddQuads( u32*, u32*, u32*, u32 );
void        ABAndQuads( u32*, u32*, u32*, u32 );
void        ABBlendQuads( u32*, u32*, u32*, u32*, u32*,  u32*, 
                          u32, u32 );
void        ABMultQuads( u32*, u32*, u32*, u32 );
void        ABOrQuads( u32*, u32*, u32*, u32 );
void        ABUnblendQuads( u32*, u32*, u32*, u32*, 
                            u32*,  u32*, u32 );
void        ABXorQuads( u32*, u32*, u32*, u32 );
void        AndQuads(  u32*, u32*, u32 );
s32         Compare_u32( u8*, u8* );
s32         Compare_u64( u8*, u8* );

void        CopyObjectQuads( u32*, u32*, u32*, u32*, u32 );
void        CopyQuads( u32*, u32*, u32 );
void        CopyInverseQuads( u32*, u32*, u32 );
void        FillQuads( u32*,  u32, u32 );
u32         GetQuad( u32* );
void        OrQuads(   u32*, u32*, u32 );
void        PutQuad( u32*, u32 );
void        XorQuads(  u32*, u32*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLQUADS_H
