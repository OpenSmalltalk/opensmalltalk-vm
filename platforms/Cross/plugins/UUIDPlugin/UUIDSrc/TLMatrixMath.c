/*------------------------------------------------------------
| TLMatrixMath.c
|-------------------------------------------------------------
|
| PURPOSE: To provide matrix math functions.
|
| DESCRIPTION:  This is a roughly self-contained code module 
| for matrix math, which started with the Numerical Recipes 
| in C code and matrix representations.
|        
| NOTE: See 'TLMatrixMathText.c' for routines that validate
|       the functions defined below.
|
| HISTORY: 11.15.95 From J. Watlington as part of his Kalman
|                   filter code, file 'matmath.c'.
|          01.23.00 Separated matrix allocation code into
|                   'TLMatrixAlloc.c'.
------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBytesExtra.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLMatrixMath.h"

#define SIGN(a,b) ((b) >= 0.0 ? fabs(a) : -fabs(a))

/*------------------------------------------------------------
| AddMatrix
|-------------------------------------------------------------
|
| PURPOSE: To add the contents of region of a matrix to 
|          a target region in another matrix.
|
| DESCRIPTION: Given the upper-cell in a matrix, together with
| the number of rows and columns which be copied and a 
| target matrix and upper-left cell, copy the region.
|
| EXAMPLE: AddMatrix( FromMatrix, 10L, 10L, 4L, 4L,
|                     ToMatrix, 0L,  0L );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.03.95 .
------------------------------------------------------------*/
void
AddMatrix( 
    Matrix* SourceMatrix,
        s32 SourceUpperRow,
        s32 SourceLeftColumn, 
        s32 ARowCount,
        s32 AColumnCount,
    Matrix* TargetMatrix,
        s32 TargetUpperRow,
        s32 TargetLeftColumn )
{
    s32     i,j;
    f64**   Source;
    f64**   Target;
    
    Source = (f64**) SourceMatrix->a;
    Target = (f64**) TargetMatrix->a;
    
    for( i = 0; i < ARowCount; i++ )
    {
        for( j = 0; j < AColumnCount; j++ )
        {
            Target[ TargetUpperRow+i ][ TargetLeftColumn+j ] += 
                Source[ SourceUpperRow+i ][ SourceLeftColumn+j ];
        }
    }
}

/*------------------------------------------------------------
| AddScaledVectorFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To scale a vector 'X' by a constant 'a' and add
|          it to vector 'Y', element by element.
|
|                          Y += a * X
|       
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.11.78 LINPACK by Jack Dongarra.
|          03.01.93 Modified to return if incx <= 0. 
|          12.03.93 Modified array(1) declarations changed to 
|                   array(*).
|          02.29.00 Obtained LINPACK Fortran source, 'daxpy.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'daxpy'.
|                   Replaced indexing with pointers for incx
|                   == 1 case and removed loop unrolling 
|                   because RISC chips handle this.
------------------------------------------------------------*/
void
AddScaledVectorFromLINPACK(
    s32  n, // Number of elements in 'x'.
            //
    f64  a, // Scaling factor to multiply by 'x'.
            //
    f64* x, // The input vector, x[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incx,
            // Array increment between elements of x.
            //
    f64* y, // IN: vector, y[1..n], 1-based indexing 
            //     and 1-based storage -- the given 
            //     address is the address of the 1th 
            //     element.
            //
            // OUT: Result vector.
            //
    s32  incy )
            // Array increment between elements of y.
{
    s32 ix, iy;

    // If there are no elements.
    if( n <= 0 || incx <= 0 ) 
    {
        // Just return.
        return;
    }
    
    // If both increments are one.
    if( incx == 1 && incy == 1 ) 
    {
        // Code for increment equal to 1.
        while( n-- ) 
        {
            *y++ += a * (*x++);
        }
    }
    else // Increment is not 1.
    {
        // Parameter adjustments.
        --y;
        --x;

        // Calculate the index of the first element
        // in each vector.
        {
            ix = 1;
            iy = 1;
        
            if( incx < 0 ) 
            {
                ix = (1 - n) * incx + 1;
            }
        
            if( incy < 0 ) 
            {
                iy = (1 - n) * incy + 1;
            }
        }
    
        // Refer to elements using pointers.
        x += ix;
        y += iy;
        
        // For each element of vectors x and y. 
        while( n-- )
        {
            *y += a * (*x);
        
            x += incx;
            y += incy;
        }
    }
}

/*------------------------------------------------------------
| clip_eigs
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
s32 
clip_eigs( f64* d, s32 n, f64 min )
{
    s32 i, count; 

    count = 0;
    
    for( i = n; i >= 1; i-- ) 
    {
        if( d[i] < min )
        { 
            d[i] = min;  
            count++;  
        }
    }
    
    return( count ); 
}

/*------------------------------------------------------------
| ComputeMatrixCRC
|-------------------------------------------------------------
|
| PURPOSE: To compute a 32-bit CRC check sum for the data in 
|          a matrix.
|
| DESCRIPTION: Returns the CRC but doesn't change the CRC
| held in the matrix header.
|
| EXAMPLE: 
|
|        CRC = ComputeMatrixCRC( AMatrix );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.14.97
------------------------------------------------------------*/
u32
ComputeMatrixCRC( Matrix* M )
{
    u32 CRC;
    u32 ByteCount;
    
    ByteCount = M->RowCount * M->ColCount * sizeof(f64);
    
    CRC = CRC32Bytes( (u8*) M->a[0], ByteCount, 0 );

    return( CRC );
}

/*------------------------------------------------------------
| det_and_tr_from_eigs
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
void    
det_and_tr_from_eigs( 
    f64*    d, 
    s32     n, 
    f64*    alt_det_p, 
    f64*    alt_tr_p )
{
    s32 i; 

    alt_det_p[0] = 1.; 
    alt_tr_p[0]  = 0.;
     
    for( i = n; i >= 1; i-- ) 
    {
        alt_det_p[0] /= d[i];
         
        alt_tr_p[0] += 1. / d[i]; 
    }
}

/*------------------------------------------------------------
| dmatrixfromdmatrix
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.29.97 
------------------------------------------------------------*/
void 
dmatrixfromdmatrix( f64** b, 
                    s32 l1, s32 h1, 
                    s32 l2, s32 h2, f64** f )
{
    s32 i, j; 

    for( i = l1;  i <= h1;  i++ )
    {
        for( j = l2;  j <= h2;  j++ )
        {
            b[i][j] = ( f[i][j] );
        }
    } 
}

/*------------------------------------------------------------
| DotProductOfVectorsFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To compute the dot product of two vectors.
|       
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.11.78 LINPACK by Jack Dongarra.
|          03.01.93 Modified to return if incx <= 0. 
|          12.03.93 Modified array(1) declarations changed to 
|                   array(*).
|          02.29.00 Obtained LINPACK Fortran source, 'ddot.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'ddot'.
|                   Replaced indexing with pointers for incx
|                   == 1 case and removed loop unrolling 
|                   because RISC chips handle this.
------------------------------------------------------------*/
f64
DotProductOfVectorsFromLINPACK(
    s32  n, // Number of elements in vectors x and y.
            //
    f64* x, // The input vector, x[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incx,
            // Array increment between elements of x.
            //
    f64* y, // The input vector, y[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incy )
            // Array increment between elements of y.
{
    f64 sum;
    s32 ix, iy;

    // Default to zero result.
    sum = 0.;
    
    if( n <= 0 ) 
    {
        return( sum );
    }
    
    // If both increments are one.
    if( incx == 1 && incy == 1 ) 
    {
        // For each element of vectors x and y. 
        while( n-- )
        {
            sum += (*x++) * (*y++);
        }
    }
    else // Increments are not both one.
    {
        // Parameter adjustments.
        --y;
        --x;

        // Calculate the index of the first element
        // in each vector.
        {
            ix = 1;
            iy = 1;
        
            if( incx < 0 ) 
            {
                ix = (1 - n) * incx + 1;
            }
        
            if( incy < 0 ) 
            {
                iy = (1 - n) * incy + 1;
            }
        }
    
        // Refer to elements using pointers.
        x += ix;
        y += iy;
        
        // For each element of vectors x and y. 
        while( n-- )
        {
            sum += (*x) * (*y);
        
            x += incx;
            y += incy;
        }
    }
    
    // Return the sum of the elementary products
    // of x and y.
    return( sum );
} 

/*------------------------------------------------------------
| Eigensystem
|-------------------------------------------------------------
|
| PURPOSE: To compute the eigenvalues and eigenvectors of a 
|          real, symmetric, n x n matrix. 
|
| DESCRIPTION: Converts matrix to form used by Numerical
| Recipes, performs the calculation and then returns the 
| result.
|
| Row 0 holds the eigenvalues sorted in descending order.
|
| Subsequent rows hold the eigenvectors, one per row.
|
| Input matrix is left unchanged.
|
| EXAMPLE:  
|
| NOTE: Patterned on the Mathematica routine with same name.
|
| ASSUMES: Input matrix is 0-based.  Enough memory to
|          duplicate the input matrix.
|
| HISTORY: 08.03.97 validated using 'TestEigensystem3' and
|                   Mathematica.
------------------------------------------------------------*/
Matrix*
Eigensystem( Matrix* A )
{
    u32     DimCount, i, j;
    f64**   a;
    f64**   c;
    f64*    e;
    f64**   B;
    Matrix* C;
    
    // Get the counts.
    DimCount = A->RowCount;
    
    // Refer to the matrix data.
    a = (f64**) A->a;
    
    // Make a 1-based matrix.
    B = dmatrix( 1, (s32) DimCount, 1, (s32) DimCount );
    
    // Copy the values to the matrix.
    for( i = 1; i <= DimCount; i++ )
    {
        for( j = 1; j <= DimCount; j++ )
        {
            B[i][j] = a[i-1][j-1];
        }
    }
    
    // Make a vector to hold the eigenvalues.
    e = dvector( 1, (s32) DimCount );
    
    // Calculate and sort the eigenvalues and eigenvectors.
    find_eigs( B,         // Input: Real, symmetric matrix.
                          // Output: eigenvectors in columns.
               (s32) DimCount,  // Number of rows or columns.
               e );       // Returns the eigenvalues.
   
    // Make a result matrix.           
    C = MakeMatrix( (s8*) "", DimCount+1, DimCount );
    
    // Refer to the data of the matrix.
    c = (f64**) C->a;
    
    // Copy the results to the matrix.
    
    // Copy the eigenvalues to the output matrix row 0.
    for( i = 1; i <= DimCount; i++ )
    {
        c[0][i-1] = e[i];
    }
    
    // Copy the eigenvectors from the columns of 'a' to the 
    // rows of 'C'.
    
    // For each column of 'a'.
    for( j = 1; j <= DimCount; j++ )
    {
        // For each row of 'a'.
        for( i = 1; i <= DimCount; i++ )
        {
            // Copy the column to the row of C.
            c[j][i-1] = B[i][j];
        }
    }
    
    // Clean up.
    free_dvector( e, 1, (s32) DimCount );
    free_dmatrix( B, 1, (s32) DimCount, 1, (s32) DimCount );

    // Return the result.
    return( C );            
}

/*------------------------------------------------------------
| eigsrt
|-------------------------------------------------------------
|
| PURPOSE: To sort eigenvalues and eigenvectors in descending
|          order of eigenvalue.
|
| DESCRIPTION: Given the eigenvalues d[1..n] and eigenvectors
| v[1..n][1..n] as output from 'jacobi' or 'tqli', this
| routine sorts the eigenvalues into descending order, and
| rearranges the columns of v correspondingly.  The method
| is straight insertion.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: Matrix and vectors use 1-based indexing.
|
| HISTORY: 08.02.97 from p. 468 of Numerical Recipes.
------------------------------------------------------------*/
void
eigsrt( f64* d, f64** v, s32 n )
{
    s32 i, j, k;
    f64 p;
    
    for( i = 1; i < n; i++ )
    {
        k=i;
        
        p = d[i];
        
        for( j = i + 1; j <= n; j++ )
        {
            if( d[j] >= p )
            {
                k = j;
                
                p = d[j];
            }
        }
        
        if( k != i )
        {
            d[k] = d[i];
            d[i] = p;
            
            for( j = 1; j <= n; j++ )
            {
                p = v[j][i];
                v[j][i] = v[j][k];
                v[j][k] = p;
            }
        }
    }
}

/*------------------------------------------------------------
| evaluate_determinant
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
evaluate_determinant( f64** hessin, s32 n )
{
    s32     j; 
    s32*    indx; 
    f64**   a;
    f64 d; 

    indx = ivector( 1, n );
     
    a = dmatrix( 1, n, 1, n );
     
    dmatrixfromdmatrix( a, 1, n, 1, n, hessin ); 

    ludcmp( a, n, indx, &d ); 

    for( j = 1; j <= n; j++ ) 
    {
        d *= a[j][j]; 
    }
    
    free_ivector( indx, 1, n );
     
    free_dmatrix( a, 1, n, 1, n ); 

    return( d ); 
}

/*------------------------------------------------------------
| find_eigs
|-------------------------------------------------------------
|
| PURPOSE: To compute the eigenvalues and eigenvectors of a 
|          real, symmetric, n x n matrix. 
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: Matrix and vectors use 1-based indexing.
|
| HISTORY:  06.30.97 
|           08.02.97 deleted 'd' which wasn't used; added
|                    'eigsrt'.
|                    Validated using 'TestEigensystem'.
------------------------------------------------------------*/
void    
find_eigs( f64** m,  // Input: Real, symmetric matrix.
                     // Output: eigenvectors in columns.
           s32   n,  // Number of rows or columns.
           f64*  l ) // Returns the eigenvalues.
{
    f64* e; 
    
    // Make a working buffer to hold the off-diagonal values.
    e = dvector( 1, n );
    
    // Reduce the matrix to tridiagonal form using the
    // Householder method.
    tred2( m,   // Real, symmetric matrix.
           n,   // Number of rows or columns.
           l,   // Returns the diagonal elements of the
                // tridiagonal matrix.
           e ); // Returns the off-diagonal elements with
                // e[1] = 0.
    
    // Compute the eigen values and vectors of the tridiagonal
    // matrix.
    tqli( l,   // Diagonal elements of the tridiagonal matrix.
               // Output: eigenvalues.
          e,   // Returns the off-diagonal elements with
               // e[1] = 0.
          n,   // Number of rows or columns.
          m ); // Input: matrix reduced to tridiagonal form.
               // Output: eigenvectors in columns.

    // Sort the vectors and values in descending eigenvalue
    // order.
    eigsrt( l, m, n );
    
    // Free the working buffer.
    free_dvector( e, 1, n );    
}
            
/*------------------------------------------------------------
| GivensPlaneRotationFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To construct givens plane rotation.   
|       
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.11.78 LINPACK by Jack Dongarra.
|          02.29.00 Obtained LINPACK Fortran source, 'drotg.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'drotg'.
|                   Replaced indexing with pointers for incx
|                   == 1 case.
------------------------------------------------------------*/
void 
GivensPlaneRotationFromLINPACK(
    f64 *a, 
    f64 *b, 
    f64 *c, // Cosine of rotation angle.
            //
    f64 *s )// Sine of rotation angle.
{
    f64 d1, d2;
    f64 r, scale, z, roe;
 
    roe = *b;
    
    if( fabs(*a) > fabs(*b) ) 
    {
        roe = *a;
    }
    
    scale = fabs(*a) + fabs(*b);
    
    if( scale != 0. ) 
    {
        goto L10;
    }
    
    *c = 1.;
    *s = 0.;
    r  = 0.;
    z  = 0.;
    
    goto L20;
    
    
////// 
L10://
////// 
 
    d1 = *a / scale;
    d2 = *b / scale;
    
    r = scale * sqrt(d1 * d1 + d2 * d2);
    
    r = SIGN(1., roe) * r;
    
    *c = *a / r;
    *s = *b / r;
    z  = 1.;
    
    if( fabs(*a) > fabs(*b) ) 
    {
        z = *s;
    }
    
    if( fabs(*b) >= fabs(*a) && *c != 0. ) 
    {
        z = 1. / *c;
    }
    
////// 
L20://
////// 

    *a = r;
    *b = z;
} 

/*------------------------------------------------------------
| invert_dmatrix
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
invert_dmatrix( 
    f64** m, 
    s32    n, 
    f64** inverse ) // returns the determinant of m too.
{
    s32*    indx;
    s32     i, j; 
    f64**  a;
    f64    d;
    f64*   col;
    
    d = 1.;  

    col  = dvector( 1, n ); 
    indx = ivector( 1, n ); 
    a    = dmatrix( 1, n, 1, n ); 
    
    dmatrixfromdmatrix( a, 1, n, 1, n, m ); 

    ludcmp( a, n, indx, &d );  // from NR page 46.

    for( j = 1; j <= n; j++ ) 
    {
        d *= a[j][j]; 
    }

    for( j = 1; j <= n; j++ ) 
    {
        for( i = 1; i <= n; i++ ) 
        {
            col[i] = 0.;
        }

        col[j] = 1.; 
        
        lubksb( a, n, indx, col );
         
        for( i = 1; i <= n; i++ ) 
        {   
            inverse[i][j] = col[i];
        } 
    }

    free_dvector( col, 1, n ); 
    free_ivector( indx, 1, n ); 
    free_dmatrix( a, 1, n, 1, n ); 

    return( d ); 
}

/*------------------------------------------------------------
| invert_dmatrixfamily
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
invert_dmatrixfamily( dmatrix_family* mp ) 
                        // returns the determinant of m too.
{
    s32     n; 
    s32     i, j; 
    f64     d;  
    f64*   col;
    
    d = 1.;
    
    n = mp->n;
     
    col = dvector( 1, n );
     
    dmatrixfromdmatrix( mp->lu, 1, n, 1, n, mp->m ); 
  
    ludcmp( mp->lu, n, mp->indx, &d );  // from NR page 46.

    for( j = 1; j <= n; j++ ) 
    {
        d *= mp->lu[j][j];
    } 
  
    for( j = 1; j <= n; j++ ) 
    {
        for( i = 1; i <= n; i++ ) 
        {
            col[i] = 0.;
        }
      
        col[j] = 1.;
         
        lubksb( mp->lu, n, mp->indx, col );
         
        for( i = 1; i <= n; i++ ) 
        {
            mp->in[i][j] = col[i];
        } 
    }

    free_dvector( col, 1, n );
     
    mp->det = d;
     
//      Note( "%f\n", d ); 
//      Note( "%f\n", mp->det ); 
    
    return( d ); 
}

/*------------------------------------------------------------
| InvertMatrixGaussJordan
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION: This function performs gauss-jordan elimination 
| to solve a set of linear equations, at the same time 
| generating the inverse of the A matrix.
|
| a[1..n][1..n] is the input matrix.
|
| b[1..n][1..m] is input containing the m right-hand side
| vectors.
|
| On the output, 'a' is replaced by its matrix inverse, and
| 'b' is replaced by the corresponding set of solution vectors.
|
| EXAMPLE:  
|
| NOTE: Makes 3 mallocs and 3 frees each time.
|
| ASSUMES: 1-based array indexing.<<<<<<<<<<<<<<<<<<<<<<<<<<<<
|
|          Able to exchange effective location of rows by
|          just exchanging the row address table entries.
|
| HISTORY: (C) Copr. 1986-92 Numerical Recipes Software
|          01.15.00 Reformatted for ease of validation.
|          01.29.00 Renamed from 'gaussj'.
|          02.04.00 Pulled out the full scanning of the matrix
|                   for a pivot in favor of simply scanning
|                   the current column.
------------------------------------------------------------*/
#define SWAP( a, b ) { temp = (a);(a) = (b);(b) = temp; }

void 
InvertMatrixGaussJordan( 
    f64**   a, // IN: An (n x n) matrix to be inverted.
               //
               // OUT: The resulting inverse.
               //
    s32     n, // Number of rows and columns to invert in 
               // matrix 'a'.
               //
    f64**   b, // IN: An (n x m) matrix holding the 'm' right
               //     side vectors.
               //
               // OUT: The solution vectors.
               //
    s32     m )// Number of columns in matrix 'b'.
{
    s32*    OrigRow;
    s32*    OrigCol;
    s32*    ipiv;
    s32     i, j, k, irow, icol;
    f64     MaxMagnitude, Magnitude, dum, pivinv, temp;
    f64*    t;
    s32     r, c;
    s32     LoRow,  HiRow;
    s32     LoCol,  HiCol;
    s32     LoColB, HiColB;
    Matrix* A;
    Matrix* B;

    // Refer to the matrix headers.
    A = ToMatrixHeader( (void**) a, 1, 2, 64, BASE_INDEX );
    B = ToMatrixHeader( (void**) b, 1, 2, 64, BASE_INDEX );
    //                              ^
    //                              |
    //                           This is the only thing that
    //                           limits the use of this routine
    //                           to one-based indexing.
    
    // Refer to the low index numbers for each dimension.
    LoRow = A->LoRowIndex;
    LoCol = A->LoColIndex;

    // Calculate the high index numbers for each dimension.
    HiRow = LoRow + n - 1;
    HiCol = LoCol + n - 1;

    // Refer to the low column index number in 'B'.
    LoColB = B->LoColIndex;

    // Calculate the high column index number in 'B' given
    // that there are 'm' columns.
    HiColB = LoColB + m - 1;
    
    // These integer arrays are used for bookkeeping on the 
    // pivoting.
    OrigRow = ivector( LoRow, HiRow );
    OrigCol = ivector( LoRow, HiRow );
    ipiv    = ivector( LoRow, HiRow );
    
    // Clear 'ipiv'.
    for( j = LoRow; j <= HiRow; j++ )  
    {
        ipiv[j] = 0;
    }
    
    // This is the main loop over the columns to be reduced.
    //
    // For each column in matrix 'a'.
    for( i = LoCol; i <= HiCol; i++ ) 
    {
        // Search for a pivot element, the cell with the
        // maximum magnitude in a row not yet chosen.
        //
        MaxMagnitude = 0.0; 

        // For each row in 'a'.
        for( j = LoRow; j <= HiRow; j++ ) 
        {        
            if( ipiv[j] != 1 )
            {      
                // For each col in 'a'.
                for( k = LoCol; k <= HiCol; k++ ) 
                {
                    if( ipiv[k] == 0 ) 
                    {
                        Magnitude = fabs( a[j][k] );
                        
                        if( Magnitude >= MaxMagnitude ) 
                        {
                            MaxMagnitude = Magnitude;
                            irow = j;
                            icol = k;
                        }
                    } 
                    else 
                    {
                        if( ipiv[k] > 1 )
                        {  
                            printf("GAUSSJ: Singular Matrix-1");
                        }
                    }
                }
            }
        }
       
        ++(ipiv[icol]);
        
        // We now have the pivot element, so we interchange rows,
        // if needed, to put the pivot element on the diagonal.
        //
        // The rows are not physically interchanged, only re-indexed.
        //
        // If irow <> icol there is an implied column interchange.  
        //
        // With this form of bookkeeping, the solution b's will end up 
        // in the correct order, and the inverse matrix will be scrambled 
        // by columns.
        if( irow != icol ) 
        {
            // Exchange the row index entries for the two rows
            // to swap the effective location of the data without 
            // moving the data itself.
            t = a[irow]; a[irow] = a[icol]; a[icol] = t;
            t = b[irow]; b[irow] = b[icol]; b[icol] = t;
        }
        
        // Save the original location of the pivot cell.    
        OrigRow[i] = irow;
        OrigCol[i] = icol;
        
        // At this point the pivot cell is the diagonal element
        // at a[i][i].
        
        // We are now ready to divide the pivot row by the pivot
        // element...
        //
        // But division is undefined for a zero divisor.
        if( a[icol][icol] == 0.0 ) 
        {
            nrerror( "InvertMatrixGaussJordan: Singular Matrix-2" );
        }
            
        // Divide every cell in the pivot row by the pivot value.
        {
            // Calculate the inverse of the pivot value so that 
            // division can be accomplished by more efficient 
            // multiplication.
            pivinv = 1.0 / a[icol][icol];
            
            a[icol][icol] = 1.0;
            
            // For each column in matrix 'a'.
            for( c = LoCol; c <= HiCol; c++ ) 
            {
                // Divide by the pivot value.
                a[icol][c] *= pivinv;
            }
            
            // For each column in matrix 'b'.
            for( c = LoColB; c <= HiColB; c++ ) 
            {
                // Divide by the pivot value.
                b[icol][c] *= pivinv;
            }
        }

        // Next, we reduce the rows except for the pivot one.
        //
        // For each row in 'a' and 'b'.
        for( r = LoRow; r <= HiRow; r++ )
        {
            // If current row is not the pivot row.
            if( r != icol ) 
            {
                dum = a[r][icol];
                
                a[r][icol] = 0.0;
                
                // For each column in matrix 'a'.
                for( c = LoCol; c <= HiCol; c++ ) 
                {
                    a[r][c] -= a[icol][c] * dum;
                }
                
                // For each column in matrix 'b'.
                for( c = LoCol; c <= HiCol; c++ ) 
                {
                    b[r][c] -= b[icol][c] * dum;
                }
            }
        }
    }
  
    // This is the end of the main loop over columns of
    // the reduction.  It only remains to unscramble
    // the solution in view of the column interchanges.
    // We do this by interchanging pairs of columns in
    // the reverse order that the permutation was built
    // up.
    for( c = HiCol; c >= LoCol; c-- ) 
    {
        if( OrigRow[c] != OrigCol[c] )
        {
            for( r = LoRow; r <= HiRow; r++ )
            {
                SWAP( a[r][OrigRow[c]], a[r][OrigCol[c]] )
            }
        }
    }

    free_ivector( ipiv,    LoRow, HiRow );
    free_ivector( OrigRow, LoRow, HiRow );
    free_ivector( OrigCol, LoRow, HiRow );
}
#undef SWAP
 
/*------------------------------------------------------------
| jacobi
|-------------------------------------------------------------
|
| PURPOSE: To find the eigensystem for a real, symmetric
|          matrix. 
|
| DESCRIPTION: Computes all eigenvalues and eigenvectors of
| a real, symmetric matrix a[1..n][1..n].  On output, elements
| of 'a' above the diagonal are destroyed.  d[1..n] returns
| the eigenvalues of 'a'. v[1..n][1..n] is a matrix whose
| columns contain, on output, the normalized eigenvectors of
| a.  'nrot' returns the number of Jacobi rotations that were
| required. 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: Underflows are set to zero.
|
| HISTORY:  08.03.97 from Numerical Recipes p. 466.
|                    Validated using 'TestEigensystem2'.
------------------------------------------------------------*/
#define ROTATE(a,i,j,k,l) g=a[i][j];h=a[k][l];a[i][j]=g-s*(h+g*tau);\
                          a[k][l]=h+s*(g-h*tau);
void
jacobi( f64** a, s32 n, f64* d, f64** v, s32* nrot )
{
    s32 j, iq, ip, i;
    f64 tresh, theta, tau, t, sm, s, h, g, c, *b, *z;
    
    b = dvector(1,n);
    z = dvector(1,n);
    
    // Initialize the identity matrix.
    for( ip = 1; ip <= n; ip++ )
    {
        for( iq = 1; iq <= n; iq++ )
        {
            v[ip][iq] = 0.;
        }
        
        v[ip][ip] = 1.;
    }
    
    // Initialize b and d to the diagonal of a.
    for( ip = 1; ip <= n; ip++ )
    {
        b[ip] = d[ip] = a[ip][ip];
        
        // This vector will accumulate terms of the form ta(pq) 
        // as in equation (11.1.14).
        z[ip] = 0.;
    }
    
    *nrot = 0;
    
    for( i = 1; i <= 50; i++ )
    {
        sm = 0.;
        
        // Sum off-diagonal elements.
        for( ip = 1; ip <= n-1; ip++ )
        {
            for( iq = ip + 1; iq <= n; iq++ )
            {
                sm += fabs( a[ip][iq] );
            }
        }
        
        // The normal return, which relies on quadratic convergence
        // to machine underflow.
        if( sm == 0. )
        {
            free_dvector( z, 1, n );
            free_dvector( b, 1, n );
            
            // Sort by eigenvalue.
            eigsrt( d, v, n );
            
            return;
        }
        
        if( i < 4 )
        {
            // On the first three sweeps.
            tresh = .2 * sm/(n*n);
        }
        else // Thereafter.
        {
            tresh = 0.;
        }
        
        for( ip = 1; ip <= n-1; ip++ )
        {
            for( iq = ip + 1; iq <= n; iq++ )
            {
                g = 100. * fabs( a[ip][iq] );
                
                // After four sweeps, skip the rotation if the 
                // off-diagonal element is small.
                if( i > 4 && 
                    (f64) ( fabs( d[ip] ) + g ) == (f64) fabs(d[ip]) &&
                    (f64) ( fabs( d[iq] ) + g ) == (f64) fabs(d[iq]) )
                {
                    a[ip][iq] = 0.;
                }
                else
                {   
                    if( fabs( a[ip][iq] ) > tresh )
                    {
                        h = d[iq] - d[ip];
                        
                        if( (f64) (fabs(h) + g) == (f64) fabs(h) )
                        {
                            // t = 1/(2theta).
                            t = (a[ip][iq])/h;
                        }
                        else
                        {
                            // Equation (11.1.10).
                            theta = .5*h/(a[ip][iq]);
                            t = 1./(fabs(theta) + sqrt(1.+theta*theta) );
                            
                            if( theta < 0. )
                            {
                                t = -t;
                            }
                        }
                        
                        c = 1./sqrt(1+t*t);
                        s = t * c;
                        tau = s/(1.+c);
                        h = t * a[ip][iq];
                        z[ip] -= h;
                        z[iq] += h;
                        d[ip] -= h;
                        d[iq] += h;
                        a[ip][iq] = 0.;
                        
                        for( j = 1; j <= ip-1; j++ )
                        {
                            // Case of rotations 1 <= j < p.
                            ROTATE(a,j,ip,j,iq)
                        }
                        
                        for( j = ip+1; j <= iq-1; j++ )
                        {
                            // Case of rotations p < j < q.
                            ROTATE(a,ip,j,j,iq)
                        }
                        
                        for( j = iq+1; j <= n; j++ )
                        {
                            // Case of rotations q < j <= n.
                            ROTATE(a,ip,j,iq,j)
                        }
                        
                        for( j = 1; j <= n; j++ )
                        {
                            ROTATE( v, j, ip, j, iq )
                        }
                        
                        ++(*nrot);
                    }
                }
            }
        }
        
        for( ip = 1; ip <= n; ip++ )
        {
            b[ip] += z[ip];
            
            // Update d with the sum of ta(pq) and
            // reinitialize z
            d[ip] = b[ip];
            z[ip] = 0.;
        }
    }
    
    nrerror( (s8*) "Too many iterations in routine jacobi" );
}               
        
/*------------------------------------------------------------
| lubksb
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
void 
lubksb( f64** a, s32 n, s32* indx, f64* b )
{
    s32 i, ii, ip, j; 
    f64 sum; 

    ii = 0;
    
    for( i = 1; i <= n; i++ ) 
    {
        ip    = indx[i]; 
        sum   = b[ip]; 
        b[ip] = b[i]; 
        
        if( ii )
        {
            for( j = ii; j <= i - 1; j++ ) 
            {
                sum -= a[i][j] * b[j];
            }
        } 
        else
        { 
            if( sum ) 
            {
                ii = i;
            }
        }
         
        b[i] = sum; 
    }
    
    for( i = n; i >= 1; i-- ) 
    {
        sum = b[i];
         
        for( j = i + 1; j <= n; j++ ) 
        {
            sum -= a[i][j] * b[j];
        }
             
        b[i] = sum / a[i][i]; 
    }
}

/*------------------------------------------------------------
| ludcmp
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 from NR page 46.
------------------------------------------------------------*/
#define TINY 1.0e-20; 

void 
ludcmp( f64** a, s32 n, s32* indx, f64* d )
{
    s32     i, imax, j, k; 
    f64     big, dum, sum, temp; 
    f64*    vv; 
 
    vv = dvector( 1, n );
     
    *d = 1.;
     
    for( i = 1; i <= n; i++ ) 
    {
        big = 0.;
         
        for( j = 1; j <= n; j++ )
        {
            if( ( temp = fabs( a[i][j] ) ) > big ) 
            {
                big = temp;
            }
        }
             
        if( big == 0. ) 
        {
            nrerror( (s8*) "Singular matrix in routine LUDCMP" );
        } 
            
        vv[i] = 1. / big; 
    }
    
    for( j = 1; j <= n; j++ ) 
    {
        for( i = 1; i < j; i++ ) 
        {
            sum = a[i][j];
             
            for( k = 1; k < i; k++ ) 
            {
                sum -= a[i][k] * a[k][j];
            }
                 
            a[i][j] = sum; 
        }
        
        big = 0.;
         
        for( i = j; i <= n; i++ ) 
        {
            sum = a[i][j];
             
            for( k = 1; k < j; k++ )
            {
                sum -= a[i][k] * a[k][j];
            }
                 
            a[i][j] = sum; 
            
            if( ( dum = vv[i] * fabs( sum ) ) >= big ) 
            {
                big = dum; 
                imax = i; 
            }
        }
        
        if( j != imax ) 
        {
            for( k = 1; k <= n; k++ ) 
            {
                dum = a[imax][k]; 
                a[imax][k] = a[j][k]; 
                a[j][k] = dum; 
            }
            
            *d = -(*d );
             
            vv[imax] = vv[j]; 
        }
        
        indx[j] = imax;
         
        if( a[j][j] == 0. )
        { 
            a[j][j] = TINY;
        }
             
        if( j != n ) 
        {
            dum = 1. / ( a[j][j] );
             
            for( i = j + 1; i <= n; i++ ) 
            {
                a[i][j] *= dum;
            } 
        }
    }
    
    free_dvector( vv, 1, n ); 
}

#undef TINY

/*------------------------------------------------------------
| luinvert_dmatrix
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: "this is a silly idea"
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
luinvert_dmatrix( 
    f64**   m, 
    s32     n, 
    f64**   inverse, 
    f64**   lu, 
    s32*    indx, 
    f64*    col ) // returns the determinant of m too.
{
    s32     i, j; 
    f64     d;
    
    d = 1.; 

    // assume col = dvector( 1, n );  scratch vector, supplied 
    // assume indx = ivector( 1, n ); 
    // assume lu = dmatrix( 1, n, 1, n ); 
    dmatrixfromdmatrix( lu, 1, n, 1, n, m ); 

    ludcmp( lu, n, indx, &d );  // from NR page 46. 

    for( j = 1; j <= n; j++ ) 
    {
        d *= lu[j][j];
    } 

    for( j = 1; j <= n; j++ ) 
    {
        for( i = 1; i <= n; i++ ) 
        {
            col[i] = 0.0;
        } 
            
        col[j] = 1.0;
         
        lubksb( lu, n, indx, col );
         
        for( i = 1; i <= n; i++ ) 
        {
            inverse[i][j] = col[i];
        } 
    }

    return( d ); 
}

/*------------------------------------------------------------
| lumatrixproduct
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
lumatrixproduct( f64*  v1, 
                 f64** m, 
                 f64*  v2, 
                 s32    n, 
                 s32*   indx ) // NB v2 must be scratchable
{
    s32  i; 
    f64 d;
    
    d = 0.; 

    lubksb( m, n, indx, v2 );
     
    for( i = 1; i <= n; i++ )
    { 
        d += v1[i] * v2[i];
    }
     
    return( d ); 
}

/*------------------------------------------------------------
| MakeCovarianceMatrix
|-------------------------------------------------------------
|
| PURPOSE: To compute the covariance matrix for a set of 
|          data points.
|
| DESCRIPTION: The covariance matrix for a data set is an
| m by m symmetric matrix whose diagonal contains the 
| variances of each m measured variable and whose off-diagonal
| area contains their covariances.
|
| This is the formula:
|
| Let X[i][j] stand for the measured value of variable j in
| case i of a collection of n cases that comprises the data
| set.
|
| Calculate the mean of each measure variable for all cases
| and call the mean "M[j]".     
|
| C[i][j] = C[j][i] =
|
|           n
|         -----
|      1  \
|   = ---  >  ( X[k][i] - M[i] ) ( X[k][j] - M[j] )
|      n  /____
|         k = 1
|           
| EXAMPLE:  
|
| NOTE: From p. 298 of "Advanced Algorithms For Neural
|       Networks" by Masters.
|
| ASSUMES:
|
| HISTORY: 08.02.97 
-----------------------------------------------------------*/
Matrix*
MakeCovarianceMatrix( Matrix* A )
{
    Matrix* Cv;
    f64*    M;
    f64**   X;
    f64**   C;
    s32     i, j, k, CaseCount, DimCount;
    
    // Get the counts: each row holds a data point so 
    // columns hold values for each dimension.
    CaseCount = A->RowCount;
    DimCount  = A->ColCount;
    
    // Allocate a matrix for the result.
    Cv = MakeMatrix( "CovarianceMatrix", 
                     DimCount, 
                     DimCount );
    
    // Refer to the matrix data.
    X = (f64**) A->a;
    C = (f64**) Cv->a;
    
    // Allocate a buffer for the means.
    M = (f64*) malloc( DimCount * sizeof( f64 ) );
    
    // Compute the mean for each variable.
    for( i = 0; i < DimCount; i++ )
    {
        M[i] = MeanOfColumn( A, i );
    }
    
    // Clear the matrix.
    ZeroMatrix( Cv );
    
    // Accumulate the covariances.
    
    // For each row.
    for( i = 0; i < DimCount; i++ )
    {
        // For each column.
        for( j = 0; j < DimCount; j++ )
        {
            // For each case.
            for( k = 0; k < CaseCount; k++ )
            {
                C[i][j] += 
                    ( X[k][i] - M[i] ) *
                    ( X[k][j] - M[j] );
            }
        }
    }
    
    // Clean up.
    free( M );
    
    // Return the result.
    return( Cv );
}    
    
/*------------------------------------------------------------
| mat_add 
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION: matrix C = matrix A + matrix B , both of 
| size RowCount x ColCount
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: One-based indexing.
|
| HISTORY: 01.15.00
|          02.01.00 Revised to avoid compiler bug.
------------------------------------------------------------*/
void 
mat_add( f64** a, f64** b, f64** c, s32 RowCount, s32 ColCount )
{
    s32     i, j;
    f64*    a_ptr;
    f64*    b_ptr;
    f64*    c_ptr;

    for( j = 1; j <= RowCount; j++ )
    {
        a_ptr = a[j] + 1;
        b_ptr = b[j] + 1;
        c_ptr = c[j] + 1;

        for( i = 1; i <= ColCount; i++ )
        {
            *c_ptr++ = *a_ptr++ + *b_ptr++;
        }
    }
}

/*------------------------------------------------------------
| mat_copy
|-------------------------------------------------------------
|
| PURPOSE: To copy a matrix.
|
| DESCRIPTION: matrix B = matrix A, of size RowCount x ColCount
|
| EXAMPLE:  
|
| NOTE: Lots of indirection: slow.
|
| ASSUMES: 
|
| HISTORY: (C) 1986-92 Numerical Recipes Software
|          01.15.00 Reformatted for ease of validation.
------------------------------------------------------------*/
void 
mat_copy( f64** src, f64** dst, s32 RowCount, s32 ColCount )
{
    s32  i, j;

    for( i = 1; i <= RowCount; i++ )
    {
        for( j = 1; j <= ColCount; j++ )
        {
            dst[i][j] = src[i][j];
        }
    }
}

/*------------------------------------------------------------
| mat_mult  
|-------------------------------------------------------------
|
| PURPOSE: To perform a matrix multiplication
|
| DESCRIPTION: matrix C = matrix A x matrix B , 
|              A(a_rows x a_cols), B(a_cols x b_cols)
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
mat_mult( 
    f64**   a, 
    f64**   b, 
    f64**   c,
    s32     a_rows, 
    s32     a_cols, 
    s32     b_cols )
{
    s32     i, j, k;
    f64*    a_ptr;
    f64     temp;

    for( i = 1; i <= a_rows; i++ )
    {
        a_ptr = a[i];
        
        for( j = 1; j <= b_cols; j++  )
        {
            temp = 0.0;
            
            for( k = 1; k <= a_cols; k++ )
            {
                temp = temp + ( a_ptr[k] * b[k][j]); 
            }
            
            c[i][j] = temp;
        }
    }
}

/*------------------------------------------------------------
| mat_mult_transpose 
|-------------------------------------------------------------
|
| PURPOSE: To performs a matrix multiplication of A x 
|          transpose B.
|
| DESCRIPTION: C = matrix A x trans( matrix B ), 
|              A(a_rows x a_cols), B(b_cols x a_cols)
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: One-based indexing.
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
mat_mult_transpose( 
    f64**   a, 
    f64**   b, 
    f64**   c,
    s32     a_rows, 
    s32     a_cols, 
    s32     b_cols )
{
    s32     i, j, k;
    f64*    a_ptr;
    f64*    b_ptr;
    f64     temp;

    for( i = 1; i <= a_rows; i++ )
    {
        a_ptr = a[i];
        
        for( j = 1; j <= b_cols; j++ )
        {
            b_ptr = b[j] + 1;

            temp = 0.0;

            for( k = 1; k <= a_cols; k++ )
            {
                temp += a_ptr[k] * *b_ptr++;
            }

            c[i][j] = temp;
        }
    }
}

/*------------------------------------------------------------
| mat_mult_vector
|-------------------------------------------------------------
|
| PURPOSE: To perform a matrix x vector multiplication
|
| DESCRIPTION: matrix C = matrix A x vector B , 
|              A(a_rows x a_cols), B(a_cols x 1)
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
mat_mult_vector( 
    f64**   a, 
    f64*    b, 
    f64*    c,
    s32     a_rows, 
    s32     a_cols )
{
    s32     i, j;
    f64*    a_ptr;
    f64*    b_ptr;
    f64     temp;

    for( i = 1; i <= a_rows; i++ )
    {
        a_ptr = a[i];
        b_ptr = b + 1;
        temp = 0.0;

        for( j = 1; j <= a_cols; j++ )
        {
            temp += a_ptr[j] * *b_ptr++;
        }

        c[i] = temp;
    }
}

/*------------------------------------------------------------
| mat_sub 
|-------------------------------------------------------------
|
| PURPOSE: To compute C = A - B, for matrices of size RowCount x ColCount.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
mat_sub(f64** a, f64** b, f64** c, s32 RowCount, s32 ColCount )
{
    s32     i, j;
    f64*    a_ptr;
    f64*    b_ptr;
    f64*    c_ptr;

    for( j = 1; j <= RowCount; j++ )
    {
        a_ptr = a[j] + 1;
        b_ptr = b[j] + 1;
        c_ptr = c[j] + 1;

        for( i = 1; i <= ColCount; i++ )
        {
            *c_ptr++ = *a_ptr++ - *b_ptr++;
        }
    }
}

/*------------------------------------------------------------
| mat_transpose_mult
|-------------------------------------------------------------
|
| PURPOSE: To perform a matrix multiplication of 
|          transpose A x B.
|
| DESCRIPTION: a_rows refers to the transposed A, is a_cols 
| in actual A storage a_cols is same, is a_rows in actual A 
| storage.
|
| C = trans( matrix A ) x matrix B, A(a_cols x a_rows),
|      B(a_cols x b_cols)
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
mat_transpose_mult( 
    f64**   A, 
    f64**   B, 
    f64**   C,
    s32     a_rows, 
    s32     a_cols, 
    s32     b_cols )
{
    s32     i, j, k;
    f64     temp;

    for( i = 1; i <= a_rows; i++ )
    {
        for( j = 1; j <= b_cols; j++ )
        {
            temp = 0.0;

            for( k = 1; k <= a_cols; k++ )
            {
                temp += A[k][i] * B[k][j];
            }

            C[i][j] = temp;
        }
    }
}

/*------------------------------------------------------------
| matrixproduct
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
matrixproduct( f64* v1, f64** m, f64* v2, s32 lo, s32 hi )
{
    s32     i, j; 
    f64     d;
    
    d = 0.; 

    for( i = lo; i <= hi; i++ )
    { 
        for( j = lo; j <= hi; j++ )
        {
            d += v1[i] * m[i][j] * v2[j];
        }
    }
     
    return( d ); 
}

/*------------------------------------------------------------
| MatrixTimesMatrix
|-------------------------------------------------------------
|
| PURPOSE: To multiply one matrix times another.
|
| DESCRIPTION: C = AB 
|
| "Definition: Let A be an m x k matrix and B be a k x n
|  matrix; then the product matrix C = AB is an m x n matrix
|  whose components are
|                                    ( b   )
|                                    (  1j )
|                                    (     )
|          c   = ( a   a   ... a   ) ( b   )
|           ij      i1  i2      ik   (  2j )
|                                    ( .   )
|                                    ( .   )
|                                    ( .   )
|                                    ( b   )
|                                    (  kj )
|
|              = a  b   + a  b   + ... a  b
|                 i1 1j    i2 2j        ik kj
|
|  The important things to remember about this definition 
|  are: first, in order to be able to multiply matrix A times
|  matrix B, the number of columns of A must be equal to the 
|  number of rows of B; second, the product matrixt C = AB
|  has the same number of rows as A and the same number of
|  columns as B; finally, to get the entry of the ith row
|  and the jth column of AB we multiply the ith row of A 
|  times the jth column of B.
|
|  Notice that the product of a vector times a matrix is a
|  special case of matrix multiplication."
|  
| EXAMPLE:  
|
| NOTE: See p. 249 of 'Finite Mathematics with Business
|                      Applications'.
|
| ASSUMES: 
|           
| HISTORY: 04.27.96  
------------------------------------------------------------*/
void
MatrixTimesMatrix( Matrix* A, Matrix* B, Matrix* C )
{
     u32    i, j, k, RowCount, ColCount;
     f64**  a;
     f64**  b;
     f64**  c;
     
     // Refer to the data of each matrix.
     a = (f64**) A->a;
     b = (f64**) B->a;
     c = (f64**) C->a;
     
     // Calculate the number of rows and columns in the
     // result.
     RowCount = A->RowCount;
     ColCount = B->ColCount;

     // For each row of the result.
     for( i = 0; i < RowCount; i++ )
     {
        // For each column of the result.
        for( j = 0; j < ColCount; j++ )
        {
            // Clear the result accumulator.
            c[i][j] = 0;
            
            // For each cooresponding component.
            for( k = 0; k < ColCount; k++ )
            {
                c[i][j] += a[i][k] * b[k][j];
            }
        }
     }
}

/*------------------------------------------------------------
| MeanOfColumn
|-------------------------------------------------------------
|
| PURPOSE: To calculate mean of a column of a matrix
|
| DESCRIPTION:   
|           
| EXAMPLE: 
|          m = MeanOfColumn( MyMatrix, 3L );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 07.27.95 
-----------------------------------------------------------*/
f64
MeanOfColumn( Matrix* M, s32 Column )
{
    f64     Sum;
    f64     m;
    s32     RowCount,r;
    f64**   A;
    
    Sum = 0;
    
    RowCount = M->RowCount;
    
    A = (f64**) M->a;
    
    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        Sum += A[r][Column];
    }
    
    m = Sum / ((f64) RowCount);
    
    return( m );
}

/*------------------------------------------------------------
| nrerror  
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION: Numerical Recipes standard error handler.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
nrerror( s8* error_text )
{
    fprintf( stderr,"Numerical Recipes run-time error...\n");
    
    fprintf( stderr,"%s\n",error_text);
    
    fprintf( stderr,"...now exiting to system...\n");
    
    exit(1);
}

/*------------------------------------------------------------
| PlaneRotationFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To apply a plane rotation.
|       
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.11.78 LINPACK by Jack Dongarra.
|          12.03.93 Modified array(1) declarations changed to 
|                   array(*).
|          02.29.00 Obtained LINPACK Fortran source, 'drot.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'drot'.
|                   Replaced indexing with pointers.
------------------------------------------------------------*/
void
PlaneRotationFromLINPACK(
    s32  n, // Number of elements in vectors x and y.
            //
    f64* x, // The input vector, x[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incx,
            // Array increment between elements of x.
            //
    f64* y, // The input vector, y[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incy,  
            // Array increment between elements of y.
            //
    f64  c, // Cosine of rotation angle.
            //
    f64  s )// Sine of rotation angle.
{
    s32 ix, iy;
    f64 xt, yt;
  
    if( n <= 0 ) 
    {
        return;
    }
    
    // If both increments are one.
    if( incx == 1 && incy == 1 ) 
    {
        while( n-- ) 
        {
            xt = *x;
            yt = *y;
            
            *x++ = c * xt + s * yt;
            *y++ = c * yt - s * xt;
        }
    }
    else // Not both increments are one.
    {
        // Parameter adjustments.
        --y;
        --x;

        ix = 1;
        iy = 1;
        
        if( incx < 0 ) 
        {
            ix = (1 - n) * incx + 1;
        }
        
        if( incy < 0 ) 
        {
            iy = (1 - n) * incy + 1;
        }
        
        x += ix;
        y += iy;
        
        while( n-- ) 
        {
            xt = *x;
            yt = *y;
            
            *x = c * xt + s * yt;
            *y = c * yt - s * xt;
            
            x += incx;
            y += incy;
        }
    }
}

/*------------------------------------------------------------
| PrincipalComponents
|-------------------------------------------------------------
|
| PURPOSE: To reduce a data set to it's n principal components.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|           b = PrincipalComponents( a, 3 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 08.03.97 from page 300 of "Advanced Algorithms for
|                   Neural Networks".
------------------------------------------------------------*/
Matrix*
PrincipalComponents( Matrix* A, u32 n )
{
    Matrix* B;
    Matrix* C;
    Matrix* E;
    u32     i, j, k, RowCount, ColCount;
    f64**   a;
    f64**   b;
    f64**   e;
    
    // Get the counts.
    RowCount = A->RowCount;
    ColCount = A->ColCount;
    
    // Compute the covariance matrix of the data.
    C = MakeCovarianceMatrix( A );
    
    // Compute the eigensystem of the covariance matrix.
    E = Eigensystem( C );
    
    // Make a new matrix to hold the result data.
    B = MakeMatrix( (s8*) "", A->RowCount, n );
    
    // Clear the result.
    ZeroMatrix( B );
    
    // Refer to A, B, and E using standard C array syntax.
    a = (f64**) A->a;
    b = (f64**) B->a;
    e = (f64**) E->a;
    
    // For each row of A.
    for( k = 0; k < RowCount; k++ )
    {
        // For each of the first n eigen vectors.
        for( i = 1; i <= n; i++ )
        {
            // For each column of A.
            for( j = 0; j < ColCount; j++ )
            {
                // Accumulate the dot product of the
                // eigenvector and the input data.
                b[k][i-1] += a[k][j] * e[i][j];
            }
        }
    }
     
    // Cleanup working matrices.
    DeleteMatrix( E );
    DeleteMatrix( C );
    
    // Return the result.
    return( B );
}
 
/*------------------------------------------------------------
| pythag
|-------------------------------------------------------------
|
| PURPOSE: To compute (a^2 + b^2)^1/2 without destructive
| underflow or overflow.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: from p. 70 of Numerical Recipes.  
|
| ASSUMES: 
|
| HISTORY: 08.02.97 transcribed and made double precision;
|                   corrected apparent error in case where
|                   b == 0.
------------------------------------------------------------*/
f64
pythag( f64 a, f64 b )
{
    f64 absa, absb, x;
    
    absa = fabs( a );
    absb = fabs( b );
    
    if( absa > absb )
    {
        x = absb / absa;
        
        return( absa * sqrt( 1. + x * x ) );
    }
    else
    {
        if( absb == 0. )
        {
            return( absa );
        }
        else
        {
            x = absa / absb;
        
            return( absb * sqrt( 1. + x * x ) );
        }
    }
}
        
/*------------------------------------------------------------
| quadratic_form
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
quadratic_form( f64** m, f64* v, s32 lo, s32 hi )
{
    s32  i, j; 
    f64 d;
    
    d = 0.; 

    for( i = lo; i <= hi; i++ ) 
    {
        for( j = lo; j <= hi; j++ ) 
        {
            d += v[i] * m[i][j] * v[j];
        }
    }
     
    return( d ); 
}

/*------------------------------------------------------------
| RowTimesMatrix
|-------------------------------------------------------------
|
| PURPOSE: To multiply a row vector times a matrix, resulting
|          in another row vector.
|
| DESCRIPTION: rM = q
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: r and q are different memory spaces.
|           
| HISTORY: 04.27.96  
------------------------------------------------------------*/
void
RowTimesMatrix( f64* r, Matrix* M, f64* q )
{
     u32    i, j, RowCount;
     f64**  m;
     
     m = (f64**) M->a;
     
     RowCount = M->RowCount;
     
     // For each column.
     for( i = 0; i < RowCount; i++ )
     {
        q[i] = 0;
        
        // For each row.
        for( j = 0; j < RowCount; j++ )
        {
            q[i] += r[j] * m[j][i];
        }
     }
}

/*------------------------------------------------------------
| ScaleVectorFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To scale a vector 'X' by a constant 'a',
|
|                          X = a * X
|       
| DESCRIPTION: Uses unrolled loops for increment equal to one.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.11.78 LINPACK by Jack Dongarra.
|          03.01.93 Modified to return if incx <= 0. 
|          12.03.93 Modified array(1) declarations changed to 
|                   array(*).
|
|          02.29.00 Obtained LINPACK Fortran source, 'dscal.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'dscal'.
|                   Replaced indexing with pointers for incx
|                   == 1 case and removed loop unrolling 
|                   because RISC chips handle this.
------------------------------------------------------------*/
void
ScaleVectorFromLINPACK(
    s32  n, // Number of elements in 'x'.
            //
    f64  a, // Scaling factor to multiply to 'x'.
            //
    f64* x, // The input vector, x[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incx )
            // Array increment between elements of 'x'.
{
    s32  i, j;

    // If there are no elements.
    if( n <= 0 || incx <= 0 ) 
    {
        // Just return.
        return;
    }
    
    if( incx == 1 ) 
    {
        // Code for increment equal to 1.
        while( n-- ) 
        {
            *x++ *= a;
        }
    }
    else // Increment is not 1.
    {
        // Parameter adjustments.
        --x;

        j = n * incx;
        
        for( i = 1; incx < 0 ? i >= j : i <= j; i += incx ) 
        {
            x[i] *= a;
        }
    }
}

/*------------------------------------------------------------
| SumOfColumn
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a column of a matrix.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumOfColumn( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.05.96 
------------------------------------------------------------*/
f64
SumOfColumn( Matrix* AMatrix, u32 Col )
{
    f64     Sum;
    f64*    ACell;
    u32     RowCount;
    u32     BytesPerRow;
    
    // Refer to the first cell in the column.
    ACell = AtCell( AMatrix, 
                    AMatrix->LoRowIndex,
                    Col );
        
    // Calc offset to next cell in the column.
    BytesPerRow = AMatrix->ColCount * sizeof( f64 );
    
    RowCount = AMatrix->RowCount;
    
    Sum = 0;
    
    while( RowCount-- )
    {
        Sum += *ACell;
        
        ACell = (f64*) ( ((s8*) ACell) + BytesPerRow );
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| SumOfMatrix
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a matrix.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumOfMatrix( M );
|
| NOTE: 
|
| ASSUMES: All cells are contiguous.
|           
| HISTORY: 02.27.96
|          01.30.00 Revised to use AtCell(). 
------------------------------------------------------------*/
f64
SumOfMatrix( Matrix* AMatrix )
{
    f64     Sum;
    f64*    ACell;
    u32     CellCount;
    
    // Refer to the first cell in the matrix.
    ACell = AtCell( AMatrix, 
                    AMatrix->LoRowIndex,
                    AMatrix->LoColIndex );
    
    CellCount = AMatrix->ColCount * 
                AMatrix->RowCount;
    Sum = 0;
    
    while( CellCount-- )
    {
        Sum += *ACell++;
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| SumOfRow
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a row of a matrix.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumOfRow( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.05.96 
------------------------------------------------------------*/
f64
SumOfRow( Matrix* AMatrix, s32 Row )
{
    f64     Sum;
    f64*    ACell;
    u32     ColCount;
    
    // Refer to the first cell in the row.
    ACell = AtCell( AMatrix, 
                    Row,
                    AMatrix->LoColIndex );
    
    ColCount = AMatrix->ColCount;
    
    Sum = 0;
    
    while( ColCount-- )
    {
        Sum += *ACell++;
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| symmetrise_dmatrix
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
void    
symmetrise_dmatrix( f64** m, s32 n )
{
    s32 i, j; 

    for( j = 2; j <= n; j++ ) 
    {
        for( i = 1; i < j; i++ )
        { 
            m[j][i] = 0.5 * ( m[i][j] + m[j][i] );
            
            m[i][j] = m[j][i];
        }
    } 
}
    
/*------------------------------------------------------------
| tqli, "Tridiagonal QL Implicit"
|-------------------------------------------------------------
|
| PURPOSE: To determine the eigenvalues and eigenvectors of
| a real, symmetric, tridiagonal matrix, or of a real,
| symmetric matrix previously reduced by 'tred2'.
|
| DESCRIPTION: QL algorithm with implicit shifts.
|
| On input, d[1..n] contains the diagonal elements of the 
| tridiagonal matrix.  On output, it returns the eigenvalues.
|
| The vector e[1..n] inputs the subdiagonal elements of the
| tridiagonal matrix, with e[1] arbitrary.  On output e is
| destroyed.
|
| When finding only the eigenvalues, several lines may be
| omitted, as noted in the comments.
|
| If the eigenvectors of a tridiagonal matrix are desired,
| the matrix z[1..n][1..n] is input as the identity matrix.
|
| If the eigenvectors of a matrix that has been reduced by
| tred2 are required, then z is input as the matrix output
| by 'tred2'.
|
| In either case, the kth column of z returns the 
| normalized eigenvector corresponding to d[k].
|
| EXAMPLE:  
|
| NOTE: From p. 480 of "Numerical Recipes in C, 2nd Ed.". 
|
| ASSUMES: 
|
| HISTORY:  06.30.97 from 'bigback5' source. 
|           08.02.97 added comments and checked against code
|                    in Num Recipes.
------------------------------------------------------------*/
void 
tqli( f64* d, f64* e, s32 n, f64** z )
{
    s32  m, l, iter, i, k;
    f64 s, r, p, g, f, dd, c, b;
 
    // Convenient to renumber the elements of e.
    for( i = 2; i <= n; i++ ) 
    {
        e[i - 1] = e[i];
    }
    
    e[n] = 0.;
    
    for( l = 1; l <= n; l++ ) 
    {
        iter = 0;
                
        do 
        {
            // Look for a single small subdiagonal element
            // to split the matrix.
            for( m = l; m <= n - 1; m++ ) 
            {
                dd = fabs( d[m] ) + fabs( d[m + 1] );
                
                if( fabs( e[m] ) + dd == dd ) 
                    break;
            }
                        
            if( m != l ) 
            {
                if( iter++== 60 ) // NR: 30
                    nrerror( (s8*) "Too many iterations in TQLI" );
                    
                g = ( d[l + 1] - d[l] ) / ( 2. * e[l] ); // Form shift.
                
                // NR: r = pythag( g, 1.);
                r = sqrt( ( g * g ) + 1. );
                
                // This is d(m) - k(s).
                g = d[m] - d[l] + e[l] / ( g + SIGN( r, g ) );
                
                s = c = 1.;
                
                p = 0.;
                
                // A plane rotation as in the original QL, followed by
                // Givens rotations to restore tridiagonal form.                
                for( i = m - 1; i >= l; i-- ) 
                {
                    f = s * e[i];
                    b = c * e[i];
#if USE_MACKAY
// Starting here Mackay has made changes to incorporate 'pythag'.               
                    if( fabs( f ) >= fabs( g ) ) 
                    {
                        c = g / f;
                        
                        r = sqrt( ( c * c ) + 1. );
                        
                        e[i + 1] = f * r;
                        
                        s = 1. / r;
                        
                        c *= s;
                    } 
                    else 
                    {
                        s = f / g;
                        
                        r = sqrt( ( s * s ) + 1. );
                        
                        e[i + 1] = g * r;
                        
                        c = 1. / r;
                        
                        s *= c;
                    }
#else // Use NR unmodified.
                    r = pythag( f, g );
                    
                    e[ i + 1 ] = r;
                    
                    // Recover from underflow.
                    if( r == 0. )
                    {
                        d[ i + 1 ] -= p;
                        e[m] = 0.;
                        break;
                    }
                    
                    s = f / r;
                    c = g / r;
#endif                    
                    g = d[i + 1] - p;
                    
                    r = ( d[i] - g ) * s + 2. * c * b;
                    
                    p = s * r;
                    
                    d[i + 1] = g + p;
                    
                    g = c * r - b;
                                        
                    // Next loop can be omitted if eigenvectors not wanted.
                    
                    // Form eigenvectors. 
                    for( k = 1; k <= n; k++ ) 
                    {
                        f = z[k][i + 1];
                        z[k][i + 1] = s * z[k][i] + c * f;
                        z[k][i] = c * z[k][i] - s * f;
                    }
                }
                
#ifndef USE_MACKAY
                if( r == 0. && i >= l ) continue;
#endif
                
                d[l] = d[l] - p;
                e[l] = g;
                e[m] = 0.;
            }
        } while( m != l );
    }
}

/*------------------------------------------------------------
| trace
|-------------------------------------------------------------
|
| PURPOSE: To  
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
------------------------------------------------------------*/
f64 
trace( f64** m, s32 n )
{
    s32     j;  
    f64     d; 

    d = 0.;
    
    for( j = 1; j <= n; j++ )
    { 
        d += m[j][j]; 
    }
    
    return( d ); 
}

/*------------------------------------------------------------
| TransposeMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a new matrix that is the transpose of 
|          a given matrix.
|
| DESCRIPTION: Exchanges the rows and column, such that a
| 5-row, 10-column matrix produces a 10-row, 5 column one.
|
| EXAMPLE: BMatrix = TransposeMatrix( AMatrix );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.03.95 .
------------------------------------------------------------*/
Matrix*
TransposeMatrix( Matrix* AMatrix )
{
    u32 i, j;
    u32 AColumnCount;
    u32 ARowCount;
    
    Matrix* BMatrix;
    
    AColumnCount = AMatrix->ColCount;
    ARowCount    = AMatrix->RowCount;
    
    BMatrix = MakeMatrix( AMatrix->FileName,
                          AColumnCount, ARowCount );
    
    for( i = 0; i < ARowCount; i++ )
    {
        for( j = 0; j < AColumnCount; j++ )
        {
            CopyCell( AMatrix, i, j,
                      BMatrix, j, i );
        }
    }
    
    return( BMatrix );
}

/*------------------------------------------------------------
| tred2
|-------------------------------------------------------------
|
| PURPOSE: To reduce a real, symmetric matrix to tridiagonal 
|          form using the Householder method. 
|
| DESCRIPTION: Householder reduction of a real, symmetric
| matrix a[1..n][1..n].  On output, a[][] is replaced by the
| orthogonal matrix Q effecting the transformation.
|
| d[1..n] returns the diagonal elements of the tridiagonal
| matrix, and e[1..n] the off-diagonal elements, with e[1]=0.
|
| Several statements, as noted in comments, can be omitted
| if only eigenvalues are to be found, in which case 'a'
| contains no useful information on output.
|
| EXAMPLE:  
|
| NOTE: See page 474 of Numerical Recipes.
|
| ASSUMES: 
|
| HISTORY:  06.30.97 
|           08.02.97 commented and verified from Num Recipes.
------------------------------------------------------------*/
void 
tred2( f64**    a,  // Real, symmetric matrix.
                    //
       s32      n,  // Number of rows or columns.
                    //
       f64*     d,  // Returns the diagonal elements of the
                    // tridiagonal matrix.
                    //
       f64*     e ) // Returns the off-diagonal elements with
                    // e[1] = 0.
{
    s32  l, k, j, i;
    f64 scale, hh, h, g, f;

    for( i = n; i >= 2; i-- ) 
    {
        l = i - 1; 
        h = scale = 0.;
         
        if( l > 1 ) 
        {
            for( k = 1; k <= l; k++ )
            {
                scale += fabs( a[i][k] ); 
            }
                       
            if( scale == 0. )
            {
                // Skip transformation.
                e[i] = a[i][l]; 
            }
            else 
            {
                for( k = 1; k <= l; k++ ) 
                {
                     // Use scaled a's for transformation.
                     a[i][k] /= scale;
                     
                     // Form sigma in h.
                     h += a[i][k] * a[i][k]; 
                }
                
                f = a[i][l]; 

// Mackay has this line as:                
//              g = f > 0. ? -sqrt( h ) : sqrt( h ); 

                g = ( f >= 0. ? -sqrt( h ) : sqrt( h ) ); 
                
                e[i] = scale * g; 
               
                // Now h is equation (11.2.4).
                h -= f * g; 
               
                // Store u in the ith row of a.
                a[i][l] = f - g; 
                
                f = 0.; 
                                
                for( j = 1; j <= l; j++ ) 
                {
                    // Next statement can be omitted if 
                    // eigenvectors not wanted. 
                    // Store u/H in ith column of a.
                    a[j][i] = a[i][j] / h;
                    
                    // Form an element of A dot u in g.
                    g = 0.; 
                   
                    for( k = 1; k <= j; k++ )
                    {
                        g += a[j][k] * a[i][k];
                    }
                         
                    for( k = j + 1; k <= l; k++ )
                    {
                        g += a[k][j] * a[i][k];
                    }
                    
                    // Form element of p in temporarily unused 
                    // element of e. 
                    e[j] = g / h;
                     
                    f += e[j] * a[i][j]; 
                }
                
                // Form K, equation (11.2.11).                
                hh = f / ( h + h ); 
                
                // Form q and store in e overwriting p.               
                for( j = 1; j <= l; j++ ) 
                {
                    f = a[i][j];
                    
                    // Note that e[l] = e[i-1] survives.
                    e[j] = g = e[j] - hh * f;
                     
                    for( k = 1; k <= j; k++ )
                    {
                        a[j][k] -= ( f * e[k] + g * a[i][k] );
                    } 
                }
            }
        } 
        else
        {
            e[i] = a[i][l]; 
        }
        
        d[i] = h; 
    }
    
    // Next statement can be omitted if eigenvectors not wanted.
    d[1] = 0.; 
    e[1] = 0.;
     
    // Contents of this loop can be omitted if eigenvectors not
    // wanted except for statement d[i] = a[i][i];
    
    // Begin accumulation of transformation matrices.
    for( i = 1; i <= n; i++ ) 
    {
        l = i - 1;
        
        // This block skipped when i == 1.
        if( d[i] ) 
        {
            for( j = 1; j <= l; j++ ) 
            {
                g = 0.; 
                
                // Use u and u/H stored in a to form P dot Q.
                for( k = 1; k <= l; k++ )
                {
                    g += a[i][k] * a[k][j];
                }
                     
                for( k = 1; k <= l; k++ )
                {
                    a[k][j] -= g * a[k][i];
                } 
            }
        }
        
        // This statement remains.
        d[i] = a[i][i];
        
        // Reset row and column of 'a' to identity matrix for 
        // next iteration.
        a[i][i] = 1.; 
        
        for( j = 1; j <= l; j++ ) 
        {
            a[j][i] = a[i][j] = 0.;
        } 
    }
}

/*------------------------------------------------------------
| vect_add 
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION: vector C = vector A + vector B , both of size n
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
|          02.11.00 Name changed from 'vec_add' to avoid
|                   collision with Altivec functions.
------------------------------------------------------------*/
void 
vect_add(f64* a, f64* b, f64* c, s32 n )
{
    s32     i;
    f64*    a_ptr;
    f64*    b_ptr;
    f64*    c_ptr;

    a_ptr = a + 1;
    b_ptr = b + 1;
    c_ptr = c + 1;

    for( i = 1; i <= n; i++ )
    {
        *c_ptr++ = *a_ptr++ + *b_ptr++;
    }
}

/*------------------------------------------------------------
| vect_copy 
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION: vector B = vector A, of size num_elements
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
|          02.11.00 Name changed from 'vec_copy' to avoid
|                   collision with Altivec functions.
------------------------------------------------------------*/
void 
vect_copy( f64* src, f64* dst, s32 num_elements )
{
    s32  i;

    for( i = 1; i <= num_elements; i++ )
    {
        dst[i] = src[i];
    }
}

/*------------------------------------------------------------
| vect_sub 
|-------------------------------------------------------------
|
| PURPOSE: To compute C = A - B, for vectors of size n.
|
| DESCRIPTION:   
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
|          02.11.00 Name changed from 'vec_sub' to avoid
|                   collision with Altivec functions.
------------------------------------------------------------*/
void 
vect_sub( f64* a, f64* b, f64* c, s32 n )
{
    s32     i;
    f64*    a_ptr;
    f64*    b_ptr;
    f64*    c_ptr;

    a_ptr = a + 1;
    b_ptr = b + 1;
    c_ptr = c + 1;

    for( i = 1; i <= n; i++ )
    {
        *c_ptr++ = *a_ptr++ - *b_ptr++;
    }
}

/*------------------------------------------------------------
| VectorNorm
|-------------------------------------------------------------
|
| PURPOSE: To compute the distance from the origin to the
|          endpoint of a vector, the vector norm.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 02.18.00 
|          02.29.00 Added special handling for single element
|                   case based on LINPACK example.
------------------------------------------------------------*/
f64
VectorNorm(
    f64*    v, 
            // IN: The input vector, v[1..n].
            //
    s32     n ) 
            // Number of elements in 'v'.
{
    f64 sum;
    s32 i;
    
    // If there are no elements.
    if( n < 1 )
    {
        // Just return zero.
        return( 0. );
    }
    
    // If there is only one element in the vector.
    if( n == 1 ) 
    {
        // Then the norm is just the magnitude of the
        // element.
        return( fabs( v[1] ) );
    } 

    // More than one element.

    // Start with nothing.
    sum = 0.0;
    
    // For each element.
    for( i = 1; i <= n; i++ )
    {
        // Accumulate the square of each element.
        sum += v[i] * v[i];
    }
    
    // Return the total distance.
    return( sqrt( sum ) );
}

/*------------------------------------------------------------
| VectorNormFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To compute the euclidean norm of a vector such that 
|
|                     norm = sqrt( x' * x )
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 10.25.82 
|          10.14.93 Modified to inline the call to DLASSQ by
|                   Sven Hammarling, Nag Ltd. 
|
|          02.28.00 Obtained LINPACK Fortran source, 'dnrm2.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'dnrm2'.
------------------------------------------------------------*/
f64 
VectorNormFromLINPACK(
    s32  n, // Number of elements in 'x'.
            //
    f64* x, // The input vector, x[1..n].
            //
    s32  incx )
            // Array increment between elements of 'x'.
{
    f64 norm, scale, absxi;
    s32 ix;
    f64 ssq;
    s32 i1, i2;
    f64 d1;

    // Parameter adjustments.
    --x;

    // If the vector is empty or has an invalid increment.
    if( n < 1 || incx < 1 ) 
    {
        norm = 0.;
    } 
    else 
    {
        // If there is only one element in the vector.
        if( n == 1) 
        {
            // Then the norm is just the magnitude of the
            // element.
            norm = fabs( x[1] );
        } 
        else // There is more than one element.
        {
            scale = 0.;
            ssq   = 1.;
            
            // The following loop is equivalent to this call to the LAPACK 
            // auxiliary routine:
            //
            //        CALL DLASSQ( N, X, INCX, SCALE, SSQ ) 
            
            i1 = (n - 1) * incx + 1;
        
            i2 = incx;
        
            for( ix = 1; i2 < 0 ? ix >= i1 : ix <= i1; ix += i2 ) 
            {
                if( x[ix] != 0. ) 
                {
                    absxi = fabs( x[ix] );
                    
                    if( scale < absxi ) 
                    {
                        d1 = scale / absxi;
                        
                        ssq = ssq * (d1 * d1) + 1.;
                         
                        scale = absxi;
                    } 
                    else 
                    {
                        d1 = absxi / scale;
                        
                        ssq += d1 * d1;
                    }
                }
            }
            
            norm = scale * sqrt(ssq);
        }
    }

    return( norm ); 
} 

/*------------------------------------------------------------
| ZeroMatrix
|-------------------------------------------------------------
|
| PURPOSE: To fill a matrix with zeros.
|
| DESCRIPTION:  
|
| EXAMPLE: ZeroMatrix( AMatrix );
|
| ASSUMES: Floating point zero values are all zero bits.
|           
| HISTORY: 02.01.96 
|          04.18.96 Fixed error where column count wasn't
|                   being used properly.
|          01.26.00 Updated for new matrix format.
------------------------------------------------------------*/
void
ZeroMatrix( Matrix* M )
{
    // Fill the entire Data section with zero bytes.
    memset( M->DataSection, 0, M->DataSectionSize );
}

