/*------------------------------------------------------------
| TLMatrixMathTest.c
|-------------------------------------------------------------
|
| PURPOSE: To provide tests for matrix math functions.
|
| HISTORY: 01.30.00 Separated from 'TLMatrixMath.c'.
------------------------------------------------------------*/

#include "TLTarget.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "TLTypes.h"
#include "TLBytes.h"
#include "TLMatrixAlloc.h"
#include "TLOrdinal.h"
#include "TLMatrixMath.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLMatrixOutput.h"
#include "TLMatrixCopy.h"
#include "TLSvd.h"
#include "TLTls.h"
#include "TLRandom.h"
#include "TLMatrixMathTest.h"

/*------------------------------------------------------------
| TestEigensystem
|-------------------------------------------------------------
|
| PURPOSE: To test the production of eigenvalues and 
|          eigenvectors using 'find_eigen'. 
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  08.02.97 from Numerical Recipes Example Book, p.
|                    190.  Compared results to Mathematica
|                    and they were the same except the
|                    eigenvectors had signs of the components
|                    reversed with respect to the values
|                    produced by this routine.  Since any 
|                    multiple of an eigenvector is also an 
|                    eigenvector the difference in signs 
|                    may not be important.  But why the dif?
------------------------------------------------------------*/
void
TestEigensystem()
{
    f64*    e;
    f64*    f;
    f64**   a;
    s32   DimCount, i, j, k;
    
    f64 c[10][10] =
            {
                 5.,  4.3, 3.,  2., 1., 0., -1., -2., -3., -4.,
                 4.3, 5.1, 4.,  3., 2., 1.,  0., -1., -2., -3.,
                 3.,  4.,  5.,  4., 3., 2.,  1.,  0., -1., -2.,
                 2.,  3.,  4.,  5., 4., 3.,  2.,  1.,  0., -1.,
                 1.,  2.,  3.,  4., 5., 4.,  3.,  2.,  1.,  0.,
                 0.,  1.,  2.,  3., 4., 5.,  4.,  3.,  2.,  1.,
                -1.,  0.,  1.,  2., 3., 4.,  5.,  4.,  3.,  2.,
                -2., -1.,  0.,  1., 2., 3.,  4.,  5.,  4.,  3.,
                -3., -2., -1.,  0., 1., 2.,  3.,  4.,  5.,  4.,
                -4., -3., -2., -1., 0., 1.,  2.,  3.,  4.,  5.
            };

    DimCount = 10;
    
    // Make a 1-based matrix.
    a = dmatrix( 1, DimCount, 1, DimCount );
    
    // Copy the values to the matrix.
    for( i = 1; i <= DimCount; i++ )
    {
        for( j = 1; j <= DimCount; j++ )
        {
            a[i][j] = c[i-1][j-1];
        }
    }
    
    // Make a vector to hold the eigenvalues.
    e = dvector( 1, DimCount );
    
    find_eigs( a,        // Input: Real, symmetric matrix.
                         // Output: eigenvectors in columns.
               DimCount, // Number of rows or columns.
               e );      // Returns the eigenvalues.
    
    // Report the results to the log.
    
    f = dvector( 1, DimCount );
    
    for( i = 1; i <= DimCount; i++ )
    {
        for( j = 1; j <= DimCount; j++ )
        {
            f[j] = 0.;
            
            for( k = 1; k <= DimCount; k++ )
            {
                f[j] += (c[j-1][k-1] * a[k][i]);
            }
        }
#if 0   // Comment out so 'Note' doesn't need to be defined.    
        Note( (s8*) "%s %3d %s %10.6f\n", 
              "eigenvalue",
              i,
              " =",
              e[i] );
        
        Note( (s8*) "%11s %14s %9s\n",
              "vector",
              "mtrx*vect.",
              "ratio" );
#endif      
        for( j = 1; j <= DimCount; j++ )
        {
            if( fabs(a[j][i]) < 1.0e-6 )
            {
#if 0   // Comment out so 'Note' doesn't need to be defined.    
                Note( (s8*) "%12.6f %12.6f %12s\n",
                      a[j][i],
                      f[j],
                      "div. by 0" );
#endif
            }
            else
            {
#if 0   // Comment out so 'Note' doesn't need to be defined.    
                Note( (s8*) "%12.6f %12.6f %12.6f\n",
                      a[j][i],
                      f[j],
                      f[j]/a[j][i] );
#endif
            }
        }
    }
    
    free_dvector( f, 1, DimCount );
    free_dvector( e, 1, DimCount );
    free_dmatrix( a, 1, DimCount, 1, DimCount );
}
 
/*------------------------------------------------------------
| TestEigensystem2
|-------------------------------------------------------------
|
| PURPOSE: To test the production of eigenvalues and 
|          eigenvectors using 'jacobi'. 
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  08.02.97 from Numerical Recipes Example Book, p.
|                    190.  Compared results to Mathematica
|                    and they were the same except the
|                    eigenvectors had signs of the components
|                    are sometimes reversed with respect to 
|                    the values produced by this routine. 
|                    Also the signs of this routine don't
|                    always match the signs of the tqli method.
|                    Since any multiple of an eigenvector is 
|                    also an eigenvector the difference in signs 
|                    may not be important.  But why the dif?
------------------------------------------------------------*/
void
TestEigensystem2()
{
    f64*   d;
    f64**  v;
    f64**  a;
    f64*    f;
     
    s32     DimCount, i, j, k, nrot;
    
    f64 c[10][10] =
            {
                 5.,  4.3, 3.,  2., 1., 0., -1., -2., -3., -4.,
                 4.3, 5.1, 4.,  3., 2., 1.,  0., -1., -2., -3.,
                 3.,  4.,  5.,  4., 3., 2.,  1.,  0., -1., -2.,
                 2.,  3.,  4.,  5., 4., 3.,  2.,  1.,  0., -1.,
                 1.,  2.,  3.,  4., 5., 4.,  3.,  2.,  1.,  0.,
                 0.,  1.,  2.,  3., 4., 5.,  4.,  3.,  2.,  1.,
                -1.,  0.,  1.,  2., 3., 4.,  5.,  4.,  3.,  2.,
                -2., -1.,  0.,  1., 2., 3.,  4.,  5.,  4.,  3.,
                -3., -2., -1.,  0., 1., 2.,  3.,  4.,  5.,  4.,
                -4., -3., -2., -1., 0., 1.,  2.,  3.,  4.,  5.
            };

    DimCount = 10;
    
    // Make a 1-based matrix for the output.
    v = dmatrix( 1, DimCount, 1, DimCount );
    
    // Make a 1-based matrix for the input.
    a = dmatrix( 1, DimCount, 1, DimCount );
    
    // Copy the values to the matrix.
    for( i = 1; i <= DimCount; i++ )
    {
        for( j = 1; j <= DimCount; j++ )
        {
            a[i][j] = c[i-1][j-1];
        }
    }
    
    // Make a vector to hold the eigenvalues.
    d = dvector( 1, DimCount );
    
    // Compute the eigensystem.
    jacobi( a, DimCount, d, v, &nrot );

    // Report the results to the log.
    
    f = dvector( 1, DimCount );
    
    for( i = 1; i <= DimCount; i++ )
    {
        for( j = 1; j <= DimCount; j++ )
        {
            f[j] = 0.;
            
            for( k = 1; k <= DimCount; k++ )
            {
                f[j] += (c[j-1][k-1] * v[k][i]);
            }
        }
#if 0   // Comment out so 'Note' doesn't need to be defined.    
        
        Note( (s8*) "%s %3d %s %10.6f\n", 
              "eigenvalue",
              i,
              " =",
              d[i] );
        
        Note( (s8*) "%11s %14s %9s\n",
              "vector",
              "mtrx*vect.",
              "ratio" );
        
        for( j = 1; j <= DimCount; j++ )
        {
            if( fabs(v[j][i]) < 1.0e-6 )
            {
                Note( (s8*) "%12.6f %12.6f %12s\n",
                      v[j][i],
                      f[j],
                      "div. by 0" );
            }
            else
            {
                Note( (s8*) "%12.6f %12.6f %12.6f\n",
                      v[j][i],
                      f[j],
                      f[j]/v[j][i] );
            }
        }
#endif
    }
    
    free_dvector( f, 1, DimCount );
    free_dvector( d, 1, DimCount );
    free_dmatrix( a, 1, DimCount, 1, DimCount );
    free_dmatrix( v, 1, DimCount, 1, DimCount );
}
 
/*------------------------------------------------------------
| TestEigensystem3
|-------------------------------------------------------------
|
| PURPOSE: To test the production of eigenvalues and 
|          eigenvectors using 'Eigensystem'. 
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  08.03.97 from Numerical Recipes Example Book, p.
|                    190.   
------------------------------------------------------------*/
void
TestEigensystem3()
{
    u32     DimCount, i, j;
    Matrix* A;
    Matrix* B;
    FILE*   F;
    f64**   a;
    
    f64 c[10][10] =
            {
                 5.,  4.3, 3.,  2., 1., 0., -1., -2., -3., -4.,
                 4.3, 5.1, 4.,  3., 2., 1.,  0., -1., -2., -3.,
                 3.,  4.,  5.,  4., 3., 2.,  1.,  0., -1., -2.,
                 2.,  3.,  4.,  5., 4., 3.,  2.,  1.,  0., -1.,
                 1.,  2.,  3.,  4., 5., 4.,  3.,  2.,  1.,  0.,
                 0.,  1.,  2.,  3., 4., 5.,  4.,  3.,  2.,  1.,
                -1.,  0.,  1.,  2., 3., 4.,  5.,  4.,  3.,  2.,
                -2., -1.,  0.,  1., 2., 3.,  4.,  5.,  4.,  3.,
                -3., -2., -1.,  0., 1., 2.,  3.,  4.,  5.,  4.,
                -4., -3., -2., -1., 0., 1.,  2.,  3.,  4.,  5.
            };

    DimCount = 10;
    
    // Make a 0-based matrix.
    A = MakeMatrix( (s8*) "", DimCount, DimCount );
    
    // Refer to the matrix as a standard 2D C array.
    a = (f64**) A->a;
    
    // Copy the values to the matrix.
    for( i = 0; i < DimCount; i++ )
    {
        for( j = 0; j < DimCount; j++ )
        {
            a[i][j] = c[i][j];
        }
    }
    
    // Calculate the eigensystem.
    B = Eigensystem( A );
    
    // Save the resulting matrix to a file in Mathematica form.
    F = ReOpenFile( (s8*) "TestEigensystem3" );
    fprintf( F, "(* Output of 'Eigensystem' test. *)\n" );
        
    WriteMatrixInMathematicaFormat( F, (s8*) "B", B );
    
    CloseFile(F);

//  SetFileType( (s8*)"TestEigensystem3", (s8*) "TEXT" );
    
//  SetFileCreator( (s8*)"TestEigensystem3", (s8*) "MPS " );
    
    // Clean up.
    DeleteMatrix( A );
    DeleteMatrix( B );
}

/*------------------------------------------------------------
| TestInvertMatrixGaussJordon
|-------------------------------------------------------------
|
| PURPOSE: To test the function 'InvertMatrixGaussJordon'.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  Compared results to Mathematica
|
| ASSUMES: 
|
| HISTORY: 01.29.00 from Numerical Recipes Example Book, p. 6.
|          02.01.00 Revised to avoid compiler error for form
|                   &m[r][c].
------------------------------------------------------------*/
void
TestInvertMatrixGaussJordon()
{
    s32     j, k, l, m, n;
    f64**   a;
    f64**   ai;
    f64**   u;
    f64**   b;
    f64**   x;
    f64**   t;
    s8      dummy[80];
    FILE*   fp;
    FILE*   MathematicaFile;
    s32     NP, MP;
    f64     z;
    Matrix* A;
    Matrix* AI;
    Matrix* U;
    Matrix* B;
    Matrix* X;
    Matrix* T;
    
    NP = 20;
    MP = 20;
    
    a  = matrix( 1, NP, 1, NP );
    ai = matrix( 1, NP, 1, NP );
    u  = matrix( 1, NP, 1, NP );
    b  = matrix( 1, NP, 1, MP );
    x  = matrix( 1, NP, 1, MP );
    t  = matrix( 1, NP, 1, MP );

    
    // Refer to the matrix headers.
    A  = ToMatrixHeader( a,  1, 2, 64, BASE_INDEX );
    AI = ToMatrixHeader( ai, 1, 2, 64, BASE_INDEX );
    U  = ToMatrixHeader( u,  1, 2, 64, BASE_INDEX );
    
    B = ToMatrixHeader( b, 1, 2, 64, BASE_INDEX );
    X = ToMatrixHeader( x, 1, 2, 64, BASE_INDEX );
    T = ToMatrixHeader( t, 1, 2, 64, BASE_INDEX );
    
    if( ( fp = fopen( "matrix1.dat", "r" ) ) == NULL )
    {
        nrerror( "Data file matrix1.dat not found.\n" );
    }
    
    // Open a file for passing data to Mathematica.
    MathematicaFile = fopen( "matrix1.out", "w" );
    
    while( !feof( fp ) )
    {
        fgets( dummy, 80L, fp );
        fgets( dummy, 80L, fp );
        
        fscanf( fp, "%ld %ld ", &n, &m );
        
        fgets( dummy, 80L, fp );
        
        for( k = 1; k <= n; k++ )
        {
            for( l = 1; l <= n; l++ )
            {
                fscanf( fp, "%lf ", &z );
                
                a[k][l] = z;
            }
        }
        
        print_matrix( "a", a, n, n );
        
        // Save the matrix to a Mathematica file.
        WriteMatrixInMathematicaFormat( MathematicaFile, "a", A );
        
        fgets( dummy, 80L, fp );
        
        for( l = 1; l <= m; l++ )
        {
            for( k = 1; k <= n; k++ )
            {
                fscanf( fp, "%lf ", &z );
                
                b[l][k] = z;
            }
        }
        
        // Save matrices for later testing of results.
        for( l = 1; l <= n; l++ )
        {
            for( k = 1; k <= n; k++ )
            {
                ai[k][l] = a[k][l];
            }
            for( k = 1; k <= n; k++ )
            {
                x[k][l] = b[k][l];
            }
        }
        
        // Invert matrix.
        InvertMatrixGaussJordan( ai, n, x, m );
        
        // Save the matrix to a Mathematica file.
        WriteMatrixInMathematicaFormat( MathematicaFile, "ai", AI );

        printf( "\nInverse of matrix a: \n" );
        
        for( k = 1; k <= n; k++ )
        {
            for( l = 1; l <= n; l++ )
            {
                printf( "%12.6f", ai[k][l] );
            }
            
            printf( "\n" );
        }       
        
        // Check inverse.
        printf( "\na times a-inverse:\n" );
        
        for( k = 1; k <= n; k++ )
        {
            for( l = 1; l <= n; l++ )
            {
                u[k][l] = 0.0;
                
                for( j = 1; j <= n; j++ )
                {
                    u[k][l] += ( a[k][j] * ai[j][l] );
                }
            }
            
            for( l = 1; l <= n; l++ )
            {
                printf( "%12.6f", u[k][l] );
            }
            
            printf( "\n" );
        }
        
        // Check vector solutions.
        printf( "\nCheck the following for equality:\n" );
        printf( "%21s %14s\n", "original", "matrix*sol'n" );
        
        for( l = 1; l <= m; l++ )
        {
            printf( "vector %2d: \n", l );
            
            for( k = 1; k <= n; k++ )
            {
                t[k][l] = 0.0;
                
                for( j = 1; j <= n; j++ )
                {
                    t[k][l] += (a[k][j]*x[j][l]);
                }
                
                printf( "%8s %12.6f %12.6f\n", 
                        " ",
                        b[k][l],
                        t[k][l] );
            }
        }
        
        printf( "*********************************\n" );
        printf( " press RETURN for next problem: \n" );
        getchar();
    }
    
    fclose( MathematicaFile );
    fclose( fp );
    
    free_matrix( t, 1, NP, 1, MP );
    free_matrix( x, 1, NP, 1, MP );
    free_matrix( b, 1, NP, 1, MP );
    
    free_matrix( u,  1, NP, 1, NP );
    free_matrix( ai, 1, NP, 1, NP );
    free_matrix( a,  1, NP, 1, NP );
}


