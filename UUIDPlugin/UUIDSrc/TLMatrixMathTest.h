/*------------------------------------------------------------
| NAME: TLMatrixMathTest.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to matrix math test 
|          functions.
|
| DESCRIPTION: 
|        
| NOTE:  
|
| HISTORY: 01.30.00 Separated from 'TLMatrixMath.h'.
------------------------------------------------------------*/

#ifndef _TLMATRIXMATHTEST_H_
#define _TLMATRIXMATHTEST_H_

#ifdef __cplusplus
extern "C"
{
#endif

void    TestEigensystem();
void    TestEigensystem2();
void    TestEigensystem3();
void    TestInvertMatrixGaussJordon();


#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLMATRIXMATHTEST_H_
