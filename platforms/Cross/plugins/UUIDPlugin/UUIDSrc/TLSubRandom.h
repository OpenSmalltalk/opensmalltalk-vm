/*------------------------------------------------------------
| TLSubRandom.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to functions for sub-random
|          number generation.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 01.29.96 from 'Numerical Recipes in C'
------------------------------------------------------------*/

#ifndef SUBRANDOM_H
#define SUBRANDOM_H

#define MAXDIM 6
#define MAXBIT 30

extern f64 fac; // Scaling factor.

extern u32  in, ix[MAXDIM+1], *iu[MAXBIT+1];

extern u32  mdeg[MAXDIM+1];

extern u32  ip[MAXDIM+1];

extern u32  iv[ MAXDIM*MAXBIT+1 ];

void    BeginSubRandomSequence( s32 );
f64     SubRandomFraction();
s32     SubRandomInteger( s32 );
void    SubRandomIntegers( s32*, s32, s32 );
f64     SubRandomValueFromRange( f64, f64 );
void    SubRandomVector( f64*, s32);
void    Test_SubRandomVector();

#endif
