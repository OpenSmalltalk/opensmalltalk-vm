/*------------------------------------------------------------
| TLRandomExtra.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to less commonly used
|          pseudo-random number functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 05.06.01 Moved some function prototypes to 
|                   TLRandomPrivate.h.
------------------------------------------------------------*/

#ifndef _TLRANDOMEXTRA_H_
#define _TLRANDOMEXTRA_H_

#ifdef __cplusplus
extern "C"
{
#endif

void    PickUniqueRandomIntegers( s32*, s32, s32 );
void    RandomPointsAround( f64*, s32, f64, f64*, s32 );
void    RandomUnitVector( f64*, s32 );
void    TrueRandomNumber( u64* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLRANDOMEXTRA_H_
