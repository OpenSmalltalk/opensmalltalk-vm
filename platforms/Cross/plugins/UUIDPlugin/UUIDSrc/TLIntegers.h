/*------------------------------------------------------------
| TLIntegers.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to integer buffer functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 04.23.96 
------------------------------------------------------------*/

#ifndef _INTEGERS_H
#define _INTEGERS_H

#ifdef __cplusplus
extern "C"
{
#endif

void    AddToIntegers( s32*, s32, s32 );
void    AppendIntegerToBuffer( s32*, s32*, s32 );
void    DeleteInteger( s32*, s32*, s32 );
void    DeleteMatchingIntegers( s32*, s32*, s32 );
void    DeltaIntegers( s32*, s32*, s32 );
s32*    DuplicateIntegers( s32*, u32 );
s32     ExtentOfIntegers( s32*, s32, s32*, s32* );
void    InsertValueInIntegerTable( s32*, u32, u32, s32 );
void    IntegersToItems( s32*, f64*, s32 );
u32     IsBuffersWithIntegersInCommon( s32*, s32, s32*, s32 );
u32     IsDuplicateIntegersInBuffer( s32*, s32 );
u32     IsIntegerInBuffer( s32*, s32, s32 );
void    ItemsToIntegers( f64*, s32*, s32 );
s32*    MakeIntegers( u32, s32* );
void    MultiplyToIntegers( s32*, u32, s32 );
s32     RoundInteger( s32, s32 );
void    SaveIntegers( s32*, u32 , s8* );
void    SortIntegers( s32*, u32 );
s32     SumIntegers( s32*, u32 );
s32     SumMagnitudeOfIntegers( s32*, u32 );
void    ZeroIntegers( s32*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _INTEGERS_H
