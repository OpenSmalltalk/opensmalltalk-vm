/*------------------------------------------------------------
| TLMatrixCopy.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to matrix copy functions.
|
| DESCRIPTION: 
|        
| NOTE:  
|
| HISTORY: 01.26.00 TL From 'TLMatrix.c'.
------------------------------------------------------------*/

#ifndef TLMATRIXCOPY_H
#define TLMATRIXCOPY_H

#ifdef __cplusplus
extern "C"
{
#endif

void    CopyCell( Matrix*, u32, u32, Matrix*, u32, u32 );
void    CopyColumnToBuffer( Matrix*, u32, f64* );
f64*    CopyColumnToNewBuffer( Matrix*, u32 );
void    CopyIndexedRows( Matrix*, Matrix*, u32*, u32 );
void    CopyRegionOfMatrix( Matrix*, u32, u32, u32, u32,
                                Matrix*, u32, u32 );
void    CopyRowToBuffer( Matrix*, u32, u8* );
u8*     CopyRowToNewBuffer( Matrix*, u32 );
void    CopyVectorFromLINPACK( s32, f64*, s32, f64*, s32 );  
Matrix* DuplicateMatrix( Matrix* );
void    FillMatrix( Matrix*, s32, s32, s32, s32, f64 );
f64     GetCell( Matrix*, s32, s32 );
Matrix* MakeSubMatrix( Matrix*, u32, u32, u32, u32 );
void    PutCell( Matrix*, s32, s32, f64 );
void    SwapVectorsFromLINPACK( s32, f64*, s32, f64*, s32 ); 

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLMATRIXCOPY_H
