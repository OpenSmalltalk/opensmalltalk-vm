/*------------------------------------------------------------
| TLRandom.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to pseudo-random number 
|          functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 05.06.01 Moved some function prototypes to 
|                   TLRandomPrivate.h.
|          06.12.01 Moved some function prototypes to 
|                   TLRandomExtra.h.
------------------------------------------------------------*/

#ifndef _TLRANDOM_H_
#define _TLRANDOM_H_

#ifdef __cplusplus
extern "C"
{
#endif

extern u32      IsRandomGeneratorSetUp;
                    // This is set to '1' only if the random
                    // number generator has been set up.

s32     RandomBit();
void    RandomBytes( u8*, u32 );
f64     RandomFraction();
s32     RandomInteger(s32);
s32     RandomIntegerFromRange( s32, s32 );
void    RandomIntegers( s32*, s32, s32 );
f64     RandomValueFromRange( f64, f64 );
void    SetUpRandomNumberGenerator( u32 );
void    ShuffleBytes( u8*, u32 );
void    ShuffleIntegers( u32*, u32 );
void    ShufflePairs( u16*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLRANDOM_H_
