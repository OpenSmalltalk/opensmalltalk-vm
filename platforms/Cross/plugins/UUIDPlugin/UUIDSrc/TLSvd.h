/*------------------------------------------------------------
| TLSvd.h
|-------------------------------------------------------------
|
| PURPOSE: To supply the interface to the singular value
|          decomposition function.
|
| HISTORY: 02.17.00 From "Numerical Recipes in C", 2nd Ed.
|          05.01.01 Replaced Numerical Recipes code with
|                   code from LINPACK.
------------------------------------------------------------*/

#ifndef TLSVD_H
#define TLSVD_H

#ifdef __cplusplus
extern "C"
{
#endif
void    SingularValueComposition( f64**, s32, s32, 
            f64**, f64*, f64** );

void    SingularValueDecompositionFromLINPACK(
            f64**, s32, s32, f64*, f64*,
            f64**, f64**, f64*, s32,
            s32* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLSVD_H
