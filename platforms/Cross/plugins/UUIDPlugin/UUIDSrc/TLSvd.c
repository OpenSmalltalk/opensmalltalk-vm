/*------------------------------------------------------------
| TLSvd.c
|-------------------------------------------------------------
|
| PURPOSE: To perform singular value decomposition of a 
|          matrix.
|
| HISTORY: 02.17.00 From "Numerical Recipes in C", 2nd Ed.
|          05.01.01 Deleted code from Numerical Recipes,
|                   replacing it with code from LINPACK.
|                   Retested using TLSvdTest.c.
------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLMatrixMath.h"

#include "TLSvd.h"

#ifndef min
#define min(x,y)      ((x)>(y)?(y):(x))
#endif

#ifndef max
#define max(x,y)      ((x)>(y)?(x):(y))
#endif

#define SIGN(a,b) ((b) >= 0.0 ? fabs(a) : -fabs(a))

/*------------------------------------------------------------
| SingularValueComposition
|-------------------------------------------------------------
|
| PURPOSE: To recompose a matrix that has been decomposed
|          using SingularValueDecomposition.
|
| DESCRIPTION: Given the products of a sigular value 
| decomposition, U, W and V, this procedure combines them to
| form the original matrix from which they were derived
| according to this formula:
|
|                                   T
|                      A = U * W * V
|
| The diagonal matrix of singular values W is a vector
| w[1..n].
|                                   T
| The matrix V ( not the transpose V ) is input as 
| v[1..n][1..n].
|
| EXAMPLE:  
|
| NOTE:
|
| ASSUMES:  
|           
| HISTORY: 02.21.00 From 'TestSingularValueDecomposition'.
------------------------------------------------------------*/
void 
SingularValueComposition( 
    f64**   a, 
            // OUT: Contains the A matrix of this formula...
            //
            //                    T
            //       A = U * W * V
            //
    s32     m, 
            // Number of rows in matrix 'a'.
            //
    s32     n, 
            // Number of columns in matrix 'a'.
            //
    f64**   u, 
            // IN: Contains the U matrix of the above
            //     formula.
    f64*    w, 
            // IN: Diagonal matrix of singular values as a
            //      vector, w[1..n].
    f64**   v )
            // IN: An n x n matrix to hold the 'V' result of
            //     a SVD decomposition...
            //
            //                            T
            //               A = U * W * V
            //
            //  'v' is not the transpose of V, its just V 
            // itself.
{
    s32 j, k, L;
    
    // For each row.
    for( k = 1; k <= m; k++ )
    {
        // For each column.
        for( L = 1; L <= n; L++ )
        {
            // Clear the cell.
            a[k][L] = 0.0;
            
            // For each column.
            for( j = 1; j <= n; j++ )
            {
                // Calculate an element of 'A' from
                // U, W and V.
                a[k][L] += u[k][j] * w[j] * v[L][j];
            }
        }       
    }
}

/*------------------------------------------------------------
| SingularValueDecompositionFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To compute the singular value decomposition of a
|          matrix.
|
| DESCRIPTION: Given a matrix x[1..ldx][1..xCols], this routine
| computes its singular value decomposition,
|
|                                   T
|                      X = U * S * V
|
| The diagonal matrix of singular values S is output as vector
| s[1..xCols].
|                                   T
| The matrix V ( not the transpose V ) is output as 
| v[1..xCols][1..xCols].
|
| This procedure reduces matrix X by orthogonal 
| transformations U and V to diagonal form.
|
| The diagonal elements s(i) are the singular values of x.  
| The columns of u are the corresponding left singular 
| vectors, and the columns of v the right singular vectors. 
|
| EXAMPLE: 
|
| NOTE: The values returned in 's' are in order of descending
|       magnitude, a feature required by TLS and not found
|       in 'SingularValueDecomposition()'.
|
| ASSUMES:  
|
| HISTORY: 08.14.78 LINPACK, 'dsvdc.f'.  
|          02.01.84 Correction made to shift by G.W. Stewart,
|                   University of Maryland, Argonne National 
|                   Lab.
|          02.28.00 Obtained LINPACK Fortran source, 'dsvdc.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'dsvdc'.
|          03.01.00 Revised matrix format from column-major
|                   Fortran format to row-major C format.
|                   Validated using Matlab on simple tests 
|                   and ran many thousand random test with
|                   TestSingularValueDecompositionFromLINPACK.
------------------------------------------------------------*/
void 
SingularValueDecompositionFromLINPACK(
    f64** x,
        // IN:  x[1..xRows][1..xCols] array.
        //
        // x contains the matrix whose singular value 
        //   decomposition is to be computed.
        //
        // There must be at least as many rows as columns:  
        // if there aren't enough rows add rows containing 
        // zeros.
        //
        // OUT: The input values are destroyed. 
        //
        //      The storage of x can be used to return u or
        //      v if it is big enough.
        //
    s32  xRows, 
        // IN: The number of rows of the matrix x.
        //
    s32  xCols, 
        // IN: The number of columns of the matrix x.
    f64* s, 
        // OUT: Diagonal matrix of singular values as a
        //      vector, s[1..xCols]. 
        //
        //      The entries of s contain the singular values 
        //      of x as NON-NEGATIVE VALUES arranged in 
        //      DESCENDING ORDER OF MAGNITUDE.
        //
    f64* e, 
        // OUT: e[1..xCols], ordinarily contains zeros.  However 
        //      see the discussion of info for exceptions. 
        //
    f64** u, 
        // OUT:  u[1..xRows][1..xCols] array.
        //
        //       u contains the matrix of left singular vectors.
        //
        //       u is not referenced if joba == 0.  
        //
        //       u may be identified with x to re-use the 
        //       storage of x.
    f64** v, 
        //
        // OUT: v[1..xCols][1..xCols] array 
        //
        //      v contains the matrix of right singular vectors. 
        //
        //      v is not referenced if job == 0.  
        //
        //      If xCols <= xRows, then v may be identified with x 
        //      to re-use the storage of x.
        //
    f64* work, 
        // IN: work[1..xRows] is a scratch vector. 
        //
    s32  job, 
        // IN: job controls the computation of the singular
        //     vectors.  It has the decimal expansion ab with 
        //     the following meaning:
        //
        //     a == 0    Do not compute the left singular vectors. 
        //
        //     a == 1    Return the xRows left singular vectors in u. 
        //
        //     b == 0    Do not compute the right singular vectors.
        // 
        //     b == 1    Return the right singular vectors in v. 
    s32* info )
        // OUT: The singular values and their corresponding singular 
        //      vectors s(info+1),s(info+2),...,s(xCols) are correct.
        //
        //      Thus if info == 0, all the singular values and their
        //      vectors are correct.  
        //
        //      In any event, the matrix b = transpose(u)*x*v is the 
        //      bidiagonal matrix with the elements of s on its 
        //      diagonal and the elements of e on its super-diagonal.
        //      Thus the singular values of x and b are the same.
{
    s32 kase;
    s32 jobu, iter;
    f64 test;
    s32 nctp1;
    f64 b, c;
    s32 nrtp1;
    f64 f, g;
    s32 i, j, k, L, m;
    f64 t, scale;
    f64 shift;
    s32 MaxIterations;
    u32 IsWantU, IsWantV;
    f64 t1, ztest, el;
    s32 kk;
    f64 cs;
    s32 ll, mm, ls;
    f64 sl;
    s32 RowsOrColsToTransform;
    f64 sm, sn;
    s32 lm1, mm1, lp1, mp1, ColsToTransform, lls, RowsToTransform;
    f64 emm1, smm1;

    // System generated locals.
    s32 i3;
    f64 d1, d2, d3, d4, d5;

    // Set the maximum number of iterations.
    MaxIterations = 30;

    // Determine what is to be computed.
    {
        IsWantU = 0;
        
        IsWantV = 0;
        
        jobu = (job % 100) / 10;
        
        if( jobu != 0 ) 
        {
            IsWantU = 1;
        }
        
        if( (job % 10) != 0 ) 
        {
            IsWantV = 1;
        }
    }

    // Reduce x to bidiagonal form, storing the diagonal elements 
    // in s and the super-diagonal elements in e. 

    *info = 0;
    
    ColsToTransform = min( (xRows - 1), xCols );
    
    RowsToTransform = xCols - 2;

    RowsOrColsToTransform = max( ColsToTransform, RowsToTransform );
    
    if( RowsOrColsToTransform < 1 ) 
    {
        goto L170;
    }
    
    
    // For each element along the longest dimension.
    for( L = 1; L <= RowsOrColsToTransform; ++L ) 
    {
        lp1 = L + 1;
        
        if( L > ColsToTransform ) 
        {
            goto L20;
        }

        // Compute the transformation for the L-th column and 
        // place the L-th diagonal in s(L).
        s[L] = VectorNormFromLINPACK( 
                    (xRows - L + 1), // n
                    &x[L][L],        // x
                    xCols );         // incx
                       
        if( s[L] == 0. ) 
        {
            goto L10;
        }
        
        if( x[L][L] != 0. ) 
        {
            s[L] = SIGN( s[L], x[L][L] );
        }
    
        d1 = 1. / s[L];
        
        // Multiply vector 'x' by scalar 'd1'.
        ScaleVectorFromLINPACK( 
            (xRows - L + 1), 
                // Number of elements in 'x'.
                //
            d1, // Scaling factor to multiply to 'x'.
                //
            &x[L][L],  
                // The input vector, x[1..n], 1-based indexing 
                // and 1-based storage -- the given address 
                // is the address of the 1th element.
                //
            xCols );
                // Array increment between elements of 'x'.
        
        x[L][L] += 1.;
//////
L10://
//////
        s[L] = -s[L];
        
//////
L20://
//////
 
        if( xCols < lp1 ) 
        {
            goto L50;
        }
        
        for( j = lp1; j <= xCols; ++j ) 
        {
            if( L > ColsToTransform ) 
            {
                goto L30;
            }
            
            if( s[L] == 0. ) 
            {
                goto L30;
            }

            // Apply the transformation.

            i3 = xRows - L + 1;
            
            t = -DotProductOfVectorsFromLINPACK( 
                    i3, // Number of elements in vectors x and y.
                        //
                    &x[L][L],  
                        // The input vector, x[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                    xCols,  
                        // Array increment between elements of x.
                        //
                    &x[L][j],  
                        // The input vector, y[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                    xCols ) 
                        // Array increment between elements of y.
                    / 
                    x[L][L];
                        
            AddScaledVectorFromLINPACK( 
                i3, // Number of elements in 'x'.
                    //
                t,  // Scaling factor to multiply by 'x'.
                    //
                &x[L][L], 
                    // The input vector, x[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of x.
                    //
                &x[L][j], 
                    // IN: vector, y[1..n], 1-based indexing 
                    //     and 1-based storage -- the given 
                    //     address is the address of the 1th 
                    //     element.
                    //
                    // OUT: Result vector.
                    //
                xCols );
                    // Array increment between elements of y.
//////
L30://
//////
            // Place the L-th row of x into e for the subsequent 
            // calculation of the row transformation. 
            e[j] = x[L][j];
        }
        
//////
L50://
//////
        if( IsWantU && (L <= ColsToTransform) ) 
        {
            // If u and x are not already stored in the same place.
            if( u != x )
            {
                // Place the transformation in u for subsequent back 
                // multiplication.
                for( i = L; i <= xRows; ++i ) 
                {
                    // Copy the part of column L in x at and below 
                    // the diagonal to u.
                    u[i][L] = x[i][L];
                }
            }
        }

        if( L > RowsToTransform ) 
        {
            goto L140;
        }

        // Compute the L-th row transformation and place the L-th 
        // super-diagonal in e(L).
        e[L] = VectorNormFromLINPACK( 
                    xCols - L,// n
                    &e[lp1],  // x
                    1 );      // incx
        
        if( e[L] == 0. ) 
        {
            goto L80;
        }
        
        if( e[lp1] != 0. ) 
        {
            e[L] = SIGN( e[L], e[lp1] );
        }
        
        d1 = 1. / e[L];
        
        // Multiply vector 'e' by scalar 'd1'.
        ScaleVectorFromLINPACK( 
            xCols - L, 
                // Number of elements in 'e'.
                //
            d1, // Scaling factor to multiply to 'e'.
                //
            &e[lp1],  
                // The input vector, e[1..n], 1-based indexing 
                // and 1-based storage -- the given address 
                // is the address of the 1th element.
                //
            1 );// Array increment between elements of 'x'.
        
        e[lp1] += 1.;
//////
L80://
//////
        e[L] = -e[L];
        
        if( lp1 > xRows || e[L] == 0. ) 
        {
            goto L120;
        }

        // Apply the transformation.

        for( i = lp1; i <= xRows; ++i ) 
        {
            work[i] = 0.;
        }
        
        for( j = lp1; j <= xCols; ++j ) 
        {
            AddScaledVectorFromLINPACK( 
                xRows - L,  
                        // Number of elements in 'x'.
                        //
                e[j],   // Scaling factor to multiply by 'x'.
                        //
                &x[lp1][j], 
                        // The input vector, x[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                xCols,  // Array increment between elements of x.
                        //
                &work[lp1],  
                        // IN: vector, y[1..n], 1-based indexing 
                        //     and 1-based storage -- the given 
                        //     address is the address of the 1th 
                        //     element.
                        //
                        // OUT: Result vector.
                        //
                1 );    // Array increment between elements of y.
        }
        
        for( j = lp1; j <= xCols; ++j ) 
        {
            d1 = -e[j] / e[lp1];
            
            AddScaledVectorFromLINPACK( 
                xRows - L,  
                        // Number of elements in 'x'.
                        //
                d1,     // Scaling factor to multiply by 'x'.
                        //
                &work[lp1], 
                        // The input vector, x[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                1,      // Array increment between elements of x.
                        //
                 &x[lp1][j],  
                        // IN: vector, y[1..n], 1-based indexing 
                        //     and 1-based storage -- the given 
                        //     address is the address of the 1th 
                        //     element.
                        //
                        // OUT: Result vector.
                        //
                xCols );    
                        // Array increment between elements of y.
        }
        
///////
L120://
///////

        // If V is to be computed.
        if( IsWantV ) 
        {
            // Place the transformation in v for subsequent back 
            // multiplication. 
            for( i = lp1; i <= xCols; ++i ) 
            {
                v[i][L] = e[i];
            }
        }
    
///////
L140://
///////
        ;
    }
    
///////
L170:// Set up the final bidiagonal matrix of order m.
///////
 
    m = xCols;
    
    nctp1 = ColsToTransform + 1;
    
    nrtp1 = RowsToTransform + 1;
    
    if( ColsToTransform < xCols ) 
    {
        s[nctp1] = x[nctp1][nctp1];
    }
    
    if( nrtp1 < xCols ) 
    {
        e[nrtp1] = x[nrtp1][xCols];
    }
    
    e[xCols] = 0.;

    // If required, generate u.

    if( ! IsWantU ) 
    {
        goto L300;
    }
    
    if( xCols >= nctp1 ) 
    {
        for( j = nctp1; j <= xCols; ++j ) 
        {
            for( i = 1; i <= xRows; ++i ) 
            {
                u[i][j] = 0.;
            }
            
            u[j][j] = 1.;
        }
    }
    
    if( ColsToTransform < 1 ) 
    {
        goto L300;
    }
    
    for( ll = 1; ll <= ColsToTransform; ++ll ) 
    {
        L = ColsToTransform - ll + 1;
        
        if( s[L] == 0. ) 
        {
            goto L250;
        }
        
        lp1 = L + 1;
        
        if( xCols < lp1 ) 
        {
            goto L220;
        }
        
        for( j = lp1; j <= xCols; ++j ) 
        {
            i3 = xRows - L + 1;
            
            t = -DotProductOfVectorsFromLINPACK( 
                    i3, // Number of elements in vectors x and y.
                        //
                    &u[L][L],  
                        // The input vector, x[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                    xCols,  
                        // Array increment between elements of x.
                        //
                    &u[L][j],  
                        // The input vector, y[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                    xCols ) 
                        // Array increment between elements of y.
                    / 
                    u[L][L];
                        
            AddScaledVectorFromLINPACK( 
                i3,     // Number of elements in 'x'.
                        //
                t,      // Scaling factor to multiply by 'x'.
                        //
                &u[L][L], 
                        // The input vector, x[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                xCols,  // Array increment between elements of x.
                        //
                &u[L][j],  
                        // IN: vector, y[1..n], 1-based indexing 
                        //     and 1-based storage -- the given 
                        //     address is the address of the 1th 
                        //     element.
                        //
                        // OUT: Result vector.
                        //
                xCols );// Array increment between elements of y.
        }
    
///////
L220://
///////
 
        // Multiply vector 'u[L..xRows]' by scalar '-1.'.
        ScaleVectorFromLINPACK( 
            xRows - L + 1, 
                // Number of elements in 'u'.
                //
            -1.,// Scaling factor to multiply to 'u'.
                //
            &u[L][L],  
                // The input vector, u[1..n], 1-based indexing 
                // and 1-based storage -- the given address 
                // is the address of the 1th element.
                //
            xCols );
                // Array increment between elements of 'u'.
        
        u[L][L] += 1.;
        
        lm1 = L - 1;
        
        if( lm1 < 1 ) 
        {
            goto L270;
        }
        
        for( i = 1; i <= lm1; ++i ) 
        {
            u[i][L] = 0.;
        }
        
        goto L270;
    
///////
L250://
///////
 
        // Zero column L.
        for( i = 1; i <= xRows; ++i ) 
        {
            u[i][L] = 0.;
        }
        
        u[L][L] = 1.;
    
///////
L270://
///////

        ;
    }
    
///////
L300://
///////

    // If it is required, generate v.
    if( IsWantV ) 
    {
        for( ll = 1; ll <= xCols; ++ll ) 
        {
            L = xCols - ll + 1;
            
            lp1 = L + 1;
            
            if( L > RowsToTransform ) 
            {
                goto L320;
            }
            
            if( e[L] == 0. ) 
            {
                goto L320;
            }
            
            for( j = lp1; j <= xCols; ++j ) 
            {
                i3 = xCols - L;
                
                t = -DotProductOfVectorsFromLINPACK( 
                        i3, // Number of elements in vectors x and y.
                            //
                        &v[lp1][L],  
                            // The input vector, x[1..n], 1-based indexing 
                            // and 1-based storage -- the given address 
                            // is the address of the 1th element.
                            //
                        xCols,  
                            // Array increment between elements of x.
                            //
                        &v[lp1][j],  
                            // The input vector, y[1..n], 1-based indexing 
                            // and 1-based storage -- the given address 
                            // is the address of the 1th element.
                            //
                        xCols ) // Array increment between elements of y.
                        / 
                        v[lp1][L];
                
                AddScaledVectorFromLINPACK( 
                    i3, // Number of elements in 'x'.
                        //
                    t,  // Scaling factor to multiply by 'x'.
                        //
                    &v[lp1][L], 
                        // The input vector, x[1..n], 1-based indexing 
                        // and 1-based storage -- the given address 
                        // is the address of the 1th element.
                        //
                    xCols,  
                        // Array increment between elements of x.
                        //
                    &v[lp1][j], 
                        // IN: vector, y[1..n], 1-based indexing 
                        //     and 1-based storage -- the given 
                        //     address is the address of the 1th 
                        //     element.
                        //
                        // OUT: Result vector.
                        //
                    xCols );// Array increment between elements of y.
            }
///////
L320://
///////     // Zero column L of v.
            for( i = 1; i <= xCols; ++i ) 
            {
                v[i][L] = 0.;
            }
            
            v[L][L] = 1.;
        
        }
    }

    ////////////////////////////////////////////////////////////////////////
    //                                                                    //
    //     M A I N    L O O P   F O R   S I N G U L A R   V A L U E S     //
    //                                                                    //

    // Initialize values for singular value calculation.
    mm = m;
    
    iter = 0;
    
///////
L360:// Test exit conditions.
///////

    // Quit if all the singular values have been found.
    if( m == 0 ) 
    {
        return;
    }

    // If too many iterations have been performed, set flag and return.
    if( iter >= MaxIterations ) 
    {
        *info = m;
        
        // Exit.
        return;
    }
    
    // This section of the program inspects for negligible elements in the 
    // s and e arrays.  On completion the variables kase and L are set as 
    // follows:
    //
    //       kase = 1     if s(m) and e(L-1) are negligible and L.lt.m 
    //
    //       kase = 2     if s(L) is negligible and L.lt.m 
    //
    //       kase = 3     if e(L-1) is negligible, L.lt.m, and 
    //                    s(L), ..., s(m) are not negligible (qr step). 
    //
    //       kase = 4     if e(m-1) is negligible (convergence). 

    for( ll = 1; ll <= m; ++ll ) 
    {
        L = m - ll;
        
        // ...exit.
        if( L == 0) 
        {
            goto L400;
        }
        
        test = fabs( s[L] ) + fabs( s[L + 1] );
        
        ztest = test + fabs( e[L] );
        
        if( ztest != test ) 
        {
            goto L380;
        }
        
        e[L] = 0.;
        
        // ...exit.
        goto L400;

///////
L380://
///////
 
        ;
    }
    
///////
L400://
///////
 
    if( L != m - 1 ) 
    {
        goto L410;
    }
    
    kase = 4;
    
    goto L470;
    
///////
L410://
///////

    lp1 = L + 1;
    
    mp1 = m + 1;
    
    for( lls = lp1; lls <= mp1; ++lls ) 
    {
        ls = m - lls + lp1;
        
        // ...exit.
        if( ls == L ) 
        {
            goto L440;
        }
        
        test = 0.;
        
        if( ls != m ) 
        {
            test += fabs( e[ls] );
        }
        
        if( ls != L + 1 ) 
        {
            test += fabs( e[ls - 1] );
        }
        
        ztest = test + fabs( s[ls] );
        
        if( ztest != test ) 
        {
            goto L420;
        }
        
        s[ls] = 0.;
        
        // ...exit.
        goto L440;
        
///////
L420://
///////
 
        ;
    }
    
///////
L440://
///////
 
    if( ls != L ) 
    {
        goto L450;
    }
    
    kase = 3;
    
    goto L470;
    
///////
L450://
///////
   
    if( ls != m ) 
    {
        goto L460;
    }
    
    kase = 1;
    
    goto L470;
    
///////
L460://
///////

    kase = 2;
    
    L = ls;
    
///////
L470://
///////

    ++L;

    // Perform the task indicated by kase.
    switch( kase ) 
    {
        case 1:  goto L490;
        case 2:  goto L520;
        case 3:  goto L540;
        case 4:  goto L570;
    }
    
///////
L490:// Deflate negligible s(m).
///////

    mm1 = m - 1;
    
    f = e[m - 1];
    
    e[m - 1] = 0.;
    
    for( kk = L; kk <= mm1; ++kk ) 
    {
        k = mm1 - kk + L;
        
        t1 = s[k];
        
        GivensPlaneRotationFromLINPACK( 
            &t1, 
            &f, 
            &cs, 
            &sn );
        
        s[k] = t1;
        
        if( k != L ) 
        {
            f = -sn * e[k - 1];
            
            e[k - 1] = cs * e[k - 1];
        }

        if( IsWantV ) 
        {
            PlaneRotationFromLINPACK( 
                xCols,  // Number of elements in vectors x and y.
                    //
                &v[1][k],
                    // The input vector, x[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of x.
                    //
                &v[1][m], 
                    // The input vector, y[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of y.
                    //
                cs, // Cosine of rotation angle.
                    //
                sn);// Sine of rotation angle.
        }
    }
    
    goto L360;

///////
L520:// Split at negligible s(L).
///////
 
    f = e[L - 1];
    
    e[L - 1] = 0.;
    
    for( k = L; k <= m; ++k ) 
    {
        t1 = s[k];
        
        GivensPlaneRotationFromLINPACK(&t1, &f, &cs, &sn);
        
        s[k] = t1;
        
        f = -sn * e[k];
        
        e[k] = cs * e[k];
        
        if( IsWantU ) 
        {
            PlaneRotationFromLINPACK(  
                xRows,  // Number of elements in vectors x and y.
                    //
                &u[1][k], 
                    // The input vector, x[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of x.
                    //
                &u[1][L-1], 
                    // The input vector, y[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of y.
                    //
                cs, // Cosine of rotation angle.
                    //
                sn);// Sine of rotation angle.
        }
    }
    
    goto L360;

///////
L540:// Perform one qr step.
///////
 
    // Calculate the shift.
    d1 = fabs( s[m] );
    d2 = fabs( s[m - 1] );
    d3 = fabs( e[m - 1] );
    d4 = fabs( s[L] );
    d5 = fabs( e[L] );
        
    scale = max( d1, d2 );
    scale = max( scale, d3 );
    scale = max( scale, d4 );
    scale = max( scale, d5 );
    
    sm = s[m] / scale;
    
    smm1 = s[m - 1] / scale;
    
    emm1 = e[m - 1] / scale;
    
    sl = s[L] / scale;
    
    el = e[L] / scale;
    
    d1 = emm1;
    
    b = ((smm1 + sm) * (smm1 - sm) + d1 * d1) / 2.;
    
    d1 = sm * emm1;
    
    c = d1 * d1;
    
    shift = 0.;
    
    if( b == 0. && c == 0. ) 
    {
        goto L550;
    }
    
    d1 = b;
    
    shift = sqrt(d1 * d1 + c);
    
    if( b < 0. ) 
    {
        shift = -shift;
    }
    
    shift = c / (b + shift);
    
///////
L550://  
///////

    f = (sl + sm) * (sl - sm) + shift;
    
    g = sl * el;
 
    // Chase zeros.

    mm1 = m - 1;
    
    for( k = L; k <= mm1; ++k ) 
    {
        GivensPlaneRotationFromLINPACK( 
            &f, 
            &g, 
            &cs, 
            &sn );
                
        if( k != L ) 
        {
            e[k - 1] = f;
        }
        
        f = cs * s[k] + sn * e[k];
        
        e[k] = cs * e[k] - sn * s[k];
        
        g = sn * s[k + 1];
        
        s[k + 1] = cs * s[k + 1];
        
        if( IsWantV ) 
        {
            PlaneRotationFromLINPACK( 
                xCols,  
                    // Number of elements in vectors x and y.
                    //
                &v[1][k], 
                    // The input vector, x[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of x.
                    //
                &v[1][k+1], 
                    // The input vector, y[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of y.
                    //
                cs, // Cosine of rotation angle.
                    //
                sn);// Sine of rotation angle.
        }
        
        GivensPlaneRotationFromLINPACK( 
            &f, 
            &g, 
            &cs, 
            &sn );
        
        s[k] = f;
        
        f = cs * e[k] + sn * s[k + 1];
        
        s[k + 1] = -sn * e[k] + cs * s[k + 1];
        
        g = sn * e[k + 1];
        
        e[k + 1] = cs * e[k + 1];
        
        if( IsWantU && ( k < xRows ) ) 
        {
            PlaneRotationFromLINPACK( 
                xRows,  // Number of elements in vectors x and y.
                    //
                &u[1][k],
                    // The input vector, x[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of x.
                    //
                &u[1][k+1], 
                    // The input vector, y[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
                xCols,  
                    // Array increment between elements of y.
                    //
                cs, // Cosine of rotation angle.
                    //
                sn);// Sine of rotation angle.
        }
    }
    
    e[m - 1] = f;
    
    ++iter;
    
    goto L360;

///////
L570://  Convergence.
///////
 
    // Make the singular value  positive.

    if( s[L] >= 0. ) 
    {
        goto L580;
    }
    
    s[L] = -s[L];
    
    if( IsWantV ) 
    {
        // Multiply vector 'v' by scalar '-1.'.
        ScaleVectorFromLINPACK( 
            xCols,  // Number of elements in 'v'.
                    //
            -1.,    // Scaling factor to multiply to 'v'.
                    //
            &v[1][L],  
                    // The input vector, v[1..n], 1-based indexing 
                    // and 1-based storage -- the given address 
                    // is the address of the 1th element.
                    //
            xCols );// Array increment between elements of 'v'.
    }
    
///////
L580://  Order the singular value. 
///////
 
    if( L == mm ) 
    {
        goto L600;
    }
    
    // If the singular values are in ascending order of magnitude.
    if( s[L] < s[L + 1] ) 
    {
        // Exchange singular values at L and L+1.
        t = s[L];   s[L] = s[L + 1];   s[L + 1] = t;
        
        // If the v matrix is of interest.
        if( IsWantV && (L < xCols) ) 
        {
            // Exchange the corresponding columns of v.
            SwapVectorsFromLINPACK( 
                xCols, 
                &v[1][L], 
                xCols, 
                &v[1][L+1], 
                xCols );
        }
        
        // If the u matrix is of interest.
        if( IsWantU && (L < xRows) ) 
        {
            // Exchange the corresponding columns of u.
            SwapVectorsFromLINPACK( 
                xRows, 
                &u[1][L], 
                xCols, 
                &u[1][L+1], 
                xCols );
        }
        
        ++L;
        
        goto L580;
    }
    
///////
L600://   
///////

    iter = 0;
    
    --m;
 
    goto L360;
} 

