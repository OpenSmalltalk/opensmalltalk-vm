/*------------------------------------------------------------
| TLTwo.h
|
| PURPOSE: To provide access to functions associated with 
|          the number 2.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 04.26.96 
------------------------------------------------------------*/

#ifndef _TWO_H_
#define _TWO_H_

#ifdef __cplusplus
extern "C"
{
#endif

// This is large enough for the 128-bit long double format:
// see p. 2-16 of PowerPC Numerics: >= 32 decimal digits
#define NaturalLogOfTwo 0.6931471805599453094172321214581765 
//                      0.6931471805599452862  
//                                       **** wrong: 
// This is the value output by 'printf' which exceeds the
// precision of 'f64' which is 15 or 16 decimal digits.
//
// From Mathematica: SetPrecision[Log[2],64]
//    0.6931471805599453094172321214581765680755001343602552541206800095
//
// From CRC, 66th ed p. A-1:
//    0.693147180559945309417232121458176568075500134360256

  
extern u32  NotPowerOf2[32];
extern u32  PowerOf2[32];
extern u32  PowerOfPowerOf2[32][32];

f64 Log2ForHalfToOne( f64 );
f64 Log2ForZeroToOne( f64 );
f64 Log2ForZeroToOneBySeriesMethod( f64 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TWO_H_
