/*------------------------------------------------------------
| TLCombinatorics.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to combinatorics functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 04.16.96
------------------------------------------------------------*/

#ifndef _COMBINATORICS_H
#define _COMBINATORICS_H

f64     Combinations( f64, f64 );
f64     DegreeOfTrend( f64*, s32 );
f64     DegreeOfTrend2( f64*, s32 );
f64     Factorial( f64 );
void    NthPermutation( u32 *, u32*, u32, u32 );
s32     PermutationNumberOfBytes( u8*, s32 );
f64     PermutationNumberOfItems( f64*, s32 );
f64     Permutations( f64, f64 );
f64     ReversePermutationNumberOfItems( f64*, s32 );

#endif
