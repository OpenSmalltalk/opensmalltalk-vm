/*------------------------------------------------------------
| TLSvdTest.c
|-------------------------------------------------------------
|
| PURPOSE: To provide test driver for SVD functions.
|
| DESCRIPTION:  
|        
| NOTE:  
|
| HISTORY: 01.30.00 Separated from 'TLMatrixMath.c'.
|          05.01.01 Removed testing of SVD routine from
|                   Numerical Recipes.
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
#include "TLRandom.h"
#include "TLTesting.h"
#include "TLSvd.h"

void    TestSingularValueDecompositionFromLINPACK();

/*------------------------------------------------------------
| main
|-------------------------------------------------------------
|
| PURPOSE: To test SVD functions.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Room exists for the log file on disk.
|
| HISTORY: 12.31.98 Bv From 'BvListTest.c'.
------------------------------------------------------------*/
void
main()
{
    TheLogFile = fopen( "TLSvdTestLog", "w+" );
    
    printt( (s8*)"***********************************\n" );
    printt( (s8*)"*  B E G I N    S V D    T E S T  *\n" );
    printt( (s8*)"*                                 *\n" );
    printt( (s8*)"*  Prints largest deviation from  *\n" );
    printt( (s8*)"*  original values of randomly    *\n" );
    printt( (s8*)"*  generated matrices.            *\n" );
    printt( (s8*)"*                                 *\n" );
    printt( (s8*)"*  Please be patient this has to  *\n" );
    printt( (s8*)"*  run through a million trials.  *\n" );
    printt( (s8*)"***********************************\n" );

    TestSingularValueDecompositionFromLINPACK();
     
    printt( (s8*)"***********************************\n" );
    printt( (s8*)"*    E N D    S V D    T E S T    *\n" );
    printt( (s8*)"***********************************\n" );

    fclose( TheLogFile );
}

/*------------------------------------------------------------
| TestSingularValueDecompositionFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To test the function 
|                'SingularValueDecompositionFromLINPACK'.
|
| DESCRIPTION: 
|
| HISTORY: 02.29.00 From TestSingularValueDecomposition.
------------------------------------------------------------*/
void
TestSingularValueDecompositionFromLINPACK()
{
    s32     i, j, m, n, t;
    f64     LargestError, dif;
    f64*    e;
    f64*    w;
    f64*    rv1;
    f64**   a;
    f64**   b;
    f64**   u;
    f64**   v;
    s32     NP, MP, info;
    Matrix* A;
    Matrix* B;
    Matrix* U;
    Matrix* V;
    
    NP = 60;
    MP = 60;
    
    // Initialize the random number generator.
    SetUpRandomNumberGenerator( 6543808 );
    
    // The largest error is initially zero.
    LargestError = 0.0;
    
    printf( "Trial\tLargest Error\n" );
    
    // For a certain number of trials.
    for( t = 1; t <= 1000000; t++ )
    {
        // Output a period every 1000 trials to enable event
        // processing.
        if( (t % 1000) == 0)
        {
            // printf( ".\n" );
        }
        
        // Randomly select a number of rows.
        //m = RandomIntegerFromRange( 2, NP );
        
m = 100;
        
        // Randomly select a number of columns less than
        // the number of rows.
        //n = RandomIntegerFromRange( 1, m );
n = 2;      

        e   = vectorr( 1, n );
        w   = vectorr( 1, n );
        rv1 = vectorr( 1, m );
        
        a  = matrix( 1, m, 1, n );
        b  = matrix( 1, m, 1, n );
        u  = matrix( 1, m, 1, n );
        v  = matrix( 1, n, 1, n );
        
        // Refer to the matrix headers.
        A = ToMatrixHeader( a,  1, 2, 64, BASE_INDEX );
        B = ToMatrixHeader( b,  1, 2, 64, BASE_INDEX );
        U = ToMatrixHeader( u,  1, 2, 64, BASE_INDEX );
        V = ToMatrixHeader( v,  1, 2, 64, BASE_INDEX );
 
        // Generate a random matrix from positive values
        // less than 1000.
        for( i = 1; i <= m; i++ )
        {
            for( j = 1; j <= n; j++ )
            {
                a[i][j] = RandomValueFromRange( 0.0, 1000.0 );
            }
        }
    
        // Copy the orignal 'a' matrix into 'u'.
        CopyRegionOfMatrix( 
            A,  // SourceMatrix
            1,  //  SourceUpperRow,
            1,  //  SourceLeftColumn, 
            m,  //  ARowCount,
            n,  //  AColumnCount,
            U,  // TargetMatrix
            1,  //  TargetUpperRow,
            1 );//  TargetLeftColumn
        
        // Copy the orignal 'a' matrix into 'b'.
        CopyRegionOfMatrix( 
            A,  // SourceMatrix
            1,  //  SourceUpperRow,
            1,  //  SourceLeftColumn, 
            m,  //  ARowCount,
            n,  //  AColumnCount,
            B,  // TargetMatrix
            1,  //  TargetUpperRow,
            1 );//  TargetLeftColumn
        
        // Perform the decomposition.
        SingularValueDecompositionFromLINPACK( 
            u,      // IN:  x[1..xRows][1..xCols] array.
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
                    //      The storage of x can be used to return u or v.
                    //
            m,      // IN: The number of rows of the matrix x.
                    //
            n,      // IN: The number of columns of the matrix x.
                    //
            w,      // OUT: Diagonal matrix of singular values as a
                    //      vector, s[1..xCols].
                    //
                    //      The entries of s contain the singular values 
                    //      of x as NON-NEGATIVE VALUES arranged in 
                    //      DESCENDING ORDER OF MAGNITUDE.
                    //
            e,      // OUT: e[1..xCols], ordinarily contains zeros.  However 
                    //      see the discussion of info for exceptions. 
                    //
            u,      // OUT:  u[1..xRows][1..xCols] array.
                    //
                    //       u contains the matrix of left singular vectors.
                    //
                    //       u is not referenced if joba == 0.  
                    //
                    //       u may be identified with x to re-use the 
                    //       storage of x.
                    //
            v,      // OUT: v[1..xCols][1..xCols] array 
                    //
                    //      v contains the matrix of right singular vectors. 
                    //
                    //      v is not referenced if job == 0.  
                    //
                    //      v may be identified with x to re-use the 
                    //      storage of x.
                    //
            rv1,    // IN: work[1..xRows] is a scratch vector. 
                    //
            11,     // IN: job controls the computation of the singular
                    //     vectors.  It has the decimal expansion ab with 
                    //     the following meaning:
                    //
                    //     a == 0    Do not compute the left singular vectors. 
                    //
                    //     a == 1    Return the left singular vectors in u. 
                    //
                    //     b == 0    Do not compute the right singular vectors.
                    // 
                    //     b == 1    Return the right singular vectors in v.
                    // 
            &info );// OUT: The singular values and their corresponding singular 
                    //      vectors s(info+1),s(info+2),...,s(xCols) are correct. 
                    //
                    //      Thus if info == 0, all the singular values and their
                    //      vectors are correct.  
                    //
                    //      In any event, the matrix b = transpose(u)*x*v is the 
                    //      bidiagonal matrix with the elements of s on its 
                    //      diagonal and the elements of e on its super-diagonal.
                    //      Thus the singular values of x and b are the same.

//print_matrix( "a", a, m, n );
//print_matrix( "u", u, m, n );
//print_matrix( "v", v, n, n );
//print_vector( "w", w, n );
 
//return;                           
        // Make sure the singular values don't increase in magnitude
        // from one column to the next.
        for( i = 1; i < n; i++ )
        {
            // If the magnitude increases.
            if( fabs( w[i] ) < fabs( w[i+1] ) )
            {
                // Halt in the debugger.
                Debugger();
            }
        }
        
        // Recompose the original matrix from the parts.
        SingularValueComposition( 
            a,  // OUT: Contains the A matrix of this formula...
                //
                //                    T
                //       A = U * W * V
                //
            m,  // Number of rows in matrix 'a'.
                //
            n,  // Number of columns in matrix 'a'.
                //
            u,  // IN: Contains the U matrix of the above
                //     formula.
                //
            w,  // IN: Diagonal matrix of singular values as a
                //     vector, w[1..n].
                //
            v );// IN: An n x n matrix to hold the 'V' result of
                //     a SVD decomposition...
                //
                //                            T
                //               A = U * W * V
                //
                // 'v' is not the transpose of V, its just V 
                // itself.
        
        // Calculate the largest deviation from the original
        // values.
        for( i = 1; i <= m; i++ )
        {
            for( j = 1; j <= n; j++ )
            {
                dif = fabs( a[i][j] - b[i][j] );
                
                if( dif > LargestError )
                {
                    LargestError = dif;
                    
                    printf( "%ld\t%15.10lg\n", t, LargestError );
                }
            }
        }
    
        free_matrix( v,  1, n, 1, n );
        free_matrix( u,  1, m, 1, n );
        free_matrix( b,  1, m, 1, n );
        free_matrix( a,  1, m, 1, n );
        free_vector( rv1, 1, m );
        free_vector( w,   1, n );
        free_vector( e,   1, n );
    }
}

