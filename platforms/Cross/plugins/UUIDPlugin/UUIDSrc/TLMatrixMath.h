/*------------------------------------------------------------
| TLMatrixMath.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to matrix math 
|          functions.
|
| DESCRIPTION: 
|        
| NOTE:  
|
| HISTORY: 01.22.95 From Numerical Recipies.
|          11.15.99 Additions by J. Watlington.
|          01.23.00 TL Split off from matrix allocation
|                      functions.
------------------------------------------------------------*/

#ifndef TLMATRIXMATH_H
#define TLMATRIXMATH_H

#ifdef __cplusplus
extern "C"
{
#endif

#define QUATERNION_SIZE             4
#define MIN_QUATERNION_MAGNITUDE    0.000001

void    AddMatrix( Matrix*, s32, s32, s32, s32,
                   Matrix*, s32, s32 );
void    AddScaledVectorFromLINPACK( s32, f64, f64*, s32, f64*, s32 );
s32     clip_eigs( f64*, s32, f64 );
u32     ComputeMatrixCRC( Matrix* );
void    det_and_tr_from_eigs( f64*, s32, f64*, f64* );
void    dmatrixfromdmatrix( f64**, s32, s32, s32, s32, f64** );
f64     DotProductOfVectorsFromLINPACK( s32, f64*, s32, f64*, s32 );
Matrix* Eigensystem( Matrix* );
void    eigsrt( f64*, f64**, s32 );
f64     evaluate_determinant( f64**, s32 );
void    find_eigs( f64**, s32, f64* );
void    GivensPlaneRotationFromLINPACK( f64*, f64*, f64*, f64* );
f64     invert_dmatrix( f64**, s32, f64** );
f64     invert_dmatrixfamily( dmatrix_family* );
void    InvertMatrixGaussJordan( f64**, s32, f64**, s32 );
void    jacobi( f64**, s32, f64*, f64**, s32* );
void    lubksb( f64**, s32, s32*, f64* );
void    ludcmp( f64**, s32, s32*, f64* );
f64     luinvert_dmatrix( f64**, s32, f64**, f64**, s32*, f64* );
f64     lumatrixproduct( f64*, f64**, f64*, s32, s32* );
Matrix* MakeCovarianceMatrix( Matrix* );
void    mat_add( f64**, f64**, f64**, s32, s32 );
void    mat_copy( f64**, f64**, s32, s32 );
void    mat_mult( f64**, f64**, f64**, s32, s32, s32 );
void    mat_mult_transpose( f64**, f64**, f64**, s32, s32, s32 );
void    mat_mult_vector( f64**, f64*, f64*, s32, s32 );
void    mat_sub( f64**, f64**, f64**, s32, s32 );
void    mat_transpose_mult( f64**, f64**, f64**, s32, s32, s32 );
f64     matrixproduct( f64*, f64**, f64*, s32, s32 );
void    MatrixTimesMatrix( Matrix*, Matrix*, Matrix* );
f64     MeanOfColumn( Matrix*, s32 );
void    nrerror( s8* );   
void    PlaneRotationFromLINPACK( s32, f64*, s32, f64*, s32, f64, f64 );
Matrix* PrincipalComponents( Matrix*, u32 );
f64     pythag( f64, f64 );
f64     quadratic_form( f64**, f64*, s32, s32 );
void    RowTimesMatrix( f64*, Matrix*, f64* );
void    ScaleVectorFromLINPACK( s32, f64, f64*, s32 );
f64     SumOfColumn( Matrix*, u32 );
f64     SumOfMatrix( Matrix* );
f64     SumOfRow( Matrix*, s32 );
void    symmetrise_dmatrix( f64**, s32 );
void    tqli( f64*, f64*, s32, f64** );
f64     trace( f64**, s32 );
Matrix* TransposeMatrix( Matrix* );
void    tred2( f64**, s32, f64*, f64* );
void    vect_add( f64*, f64*, f64*, s32 );
void    vect_copy( f64*, f64*, s32 );
void    vect_sub( f64*, f64*, f64*, s32 );
f64     VectorNorm( f64*, s32 );
f64     VectorNormFromLINPACK( s32, f64*, s32 );
void    ZeroMatrix( Matrix* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLMATRIXMATH_H
