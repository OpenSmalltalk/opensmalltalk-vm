/*------------------------------------------------------------
| TLTls.c
|-------------------------------------------------------------
|
| PURPOSE: To determine the total least-squares solution of
|
|                            A x = b
|
| HISTORY: 02.18.00 From "Mathematical Methods and Algorithms
|                   for Signal Processing" by Todd K. Moon
|                   and "The Total Least Squares Problem, 
|                   Computational Aspects and Analysis" by 
|                   Sabine Van Huffel and Joos Vandewalle.
------------------------------------------------------------*/

#include "TLTarget.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "NumTypes.h"
#include "TLTypes.h"
#include "TLBytes.h"
#include "TLf64.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLMatrixMath.h"
#include "TLSvd.h"

#include "TLTls.h"

/*------------------------------------------------------------
| ConvertDataToZScores
|-------------------------------------------------------------
|
| PURPOSE: To prepare data for total least-squares fitting.
| 
| DESCRIPTION: The TLS algorithm assumes that each dimension 
| has zero mean and equal standard deviation.
|
| This routine centers the data mean at zero and scales the
| data so that the standard deviation is equal to 1.
|
| The resulting value is called a "z-score" and the formula
| is:                           _
|                        Xi  -  X
|                 z  = ------------ 
|                  i        s
|
| where:
|            Xi is a raw data item.
|            _
|            X  is the mean of the raw data.
|
|            s  is the standard deviation of the raw data.
|
| EXAMPLE:  
|
| NOTE: This process of scaling to a uniform variance is
|       sometimes called "whitening".
|
| HISTORY: 03.04.00 From "Introduction to the Statistical 
|                   Method" by Hammond and Householder, page 
|                   164.  The computation of standard 
|                   standard deviation came from Form II on
|                   page 125.
------------------------------------------------------------*/
void
ConvertDataToZScores( 
    f64* X,      // The first raw data item.
                 //
    u32  xCount, // The number of data items.
                 //
    s32  xStep,  // The address increment from one data item
                 // to the next in bytes.
                 //
    f64* Z,      // The first z-score result -- this can be
                 // the same address as 'x' to convert the
                 // data in place.
                 //
    s32  zStep,  // The address increment from one z-score
                 // to the next in bytes.
                 //
    f64* xSub,   // OUT: The displacement value used to 
                 //      reduce the magnitude of the data 
                 //      initially before computing the 
                 //      moments.
                 //
    f64* xMean,  // OUT: The mean of the magnitude-reduced
                 //      data.
                 //
    f64* xStd )  // OUT: The standard deviation of the
                 //      magnitude-reduced data.
{
    f64  MeanX, MagnitudeReducer, StdX;
    f64  Sum, SumOfSquares, dx;
    f64  ItemCount;
    f64* z;
    u32  i;
    
    // Sometimes a group of data consists of very large 
    // numbers spaced closely together.  To avoid calculation
    // errors like overflow and round-off, it's a good idea
    // to first displace the numbers toward zero by 
    // subtracting some representative value from the group:
    // the first value will do.
    
    // Get the first x.
    MagnitudeReducer = *X;
    
    // Use lower-case letter z for a data cursor.
    z = Z;
    
    // Use i for the counter.
    i = xCount;
    
    // For each data item.
    while( i-- )
    {
        // Subtract the value of the first data item.
        *z = *X - MagnitudeReducer;
        
        // Step to the next source item.
        X = (f64*) ( ( (u8*) X ) + xStep );
        
        // Step to the next destination item.
        z = (f64*) ( ( (u8*) z ) + zStep );
    }
    
    //
    // Now prepare to accumulate the sums of x and x^2.
    //
    
    // Clear the sums.
    Sum          = 0;
    SumOfSquares = 0;
    
    // Reset the data cursor.
    z = Z;
    
    // Reset the item counter.
    i = xCount;
    
    // For each data item.
    while( i-- )
    {
        // Fetch the displaced X value.
        dx = *z;
        
        // Add it to the sum.
        Sum += dx;
        
        // Accumulate the square of a.
        SumOfSquares += dx * dx;
    
        // Step to the next adjusted data item.
        z = (f64*) ( ( (u8*) z ) + zStep );
    }
    
    // Convert the item count to floating point.
    ItemCount = (f64) xCount;
    
    // Calculate the mean.
    MeanX = Sum / ItemCount;
 
    // Calculate the standard deviation.
    StdX = sqrt( ItemCount * SumOfSquares - Sum * Sum ) / ItemCount;

    //
    // Center and scale the data.
    //

    // For each data item.
    while( xCount-- )
    {
        // Subtract the mean and divide by the standard deviation.
        *Z = ( *Z - MeanX ) / StdX;
        
        // Step to the next item.
        Z = (f64*) ( ( (u8*) Z ) + zStep );
    }
    
    // Return the adjustment values.
    *xSub  = MagnitudeReducer;
    *xMean = MeanX;
    *xStd  = StdX;
}

/*------------------------------------------------------------
| HouseholderVector
|-------------------------------------------------------------
|
| PURPOSE: To make the Householder vector 'v' such that Hx
|          has zeros in all be the first component.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 02.18.00 From "Mathematical Methods and Algorithms
|                   for Signal Processing" by Todd K. Moon,
|                   algorithm 'makehouse' on the disk.
------------------------------------------------------------*/
void
HouseholderVector(
    f64*    v, 
            // IN: The input vector, v[1..n].
            //
    f64*    h, 
            // OUT: Result vector, h[1..n].
    s32     n ) 
            // Number of entries in the vector.
{
    f64 nv;
    s32 i;
    
    // Copy the input vector to the result.
    for( i = 1; i <= n; i++ )
    {
        h[i] = v[i];
    }
    
    // Compute the vector norm of 'v'.
    nv = VectorNorm( h, n );
    
    // If the entire magnitude of the vector norm is 
    // derived from the first component.
    if( Eq( fabs( h[1] ), nv ) )
    {
        // Then the result vector is entirely filled
        // with zeros.
        for( i = 1; i <= n; i++ )
        {
            h[i] = 0.0;
        }
    }
    else // More than one dimension have magnitude.
    {
        // If the first component of the vector is
        // zero.
        if( Eq( h[1], 0.0 ) )
        {
            // Add the norm for the first component.
            h[1] += nv;
        }
        else // The first component is non-zero.
        {
            // Add the sign-adjusted norm.
            h[1] += Sign( h[1] ) * nv;
        }
    }
}

/*------------------------------------------------------------
| LineFit
|-------------------------------------------------------------
|
| PURPOSE: To finds the line, Y=m*X+b, that is the least mean
|          square error fit to a set of (x,y) pairs.
| 
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: No error in the 'x' measurements.
|  
|          Use 'LineFitTls()' if there is error in the 'x'
|          measurements as well as the 'y'.
|
| NOTE:
|
| HISTORY: 03.25.96 from 'LINREG.C' of 'C/Math Toolchest'
|                   p.330.
|          03.07.00 Copied from 'TLStat.c', added z-score 
|                   conversion step.
------------------------------------------------------------*/
void 
LineFit(
    f64* x,     // IN: The X values, the abscissa array.
                //
    f64* y,     // IN: The Y values, the ordinate array.
                //
    s32  n,     // IN: The number of items in 'x' and 'y'.
                //
    f64* m,     // OUT: The returned slope in Y = m * X + b.
                //
    f64* b,     // OUT: The returned y-intercept in Y = m * X + b.
                //
    f64* rsq,   // OUT: The returned coefficient of determination; 
                //      0 < rsq < 1; 
                //
                // where:
                //      If rsq is near 1, then the data are well 
                //      described by a line.
                //
                //      If rsq is near 0, then the data are NOT 
                //      well described by a line.
                //
                //
    f64* zx,    // OUT: Z-scores for x input values.
                //
    f64* zy )   // OUT: Z-scores for y input values.
{
    f64 xx, yy, xy, xsum, ysum;
    f64 xval, yval, num, ymean, xmean;
    s32 i;
    f64 xMean, yMean;
    f64 xSub,  ySub;
    f64 xStd,  yStd;
    
    // Scale and center the x values, moving them into the matrix.
    ConvertDataToZScores( 
        x,           // The first raw data item.
                     //
        n,           // The number of data items.
                     //
        sizeof(f64), // The address increment from one data item
                     // to the next in bytes.
                     //
        zx,          // The first z-score result -- this can be
                     // the same address as 'x' to convert the
                     // data in place.
                     //
        sizeof(f64), // The address increment from one z-score
                     // to the next in bytes.
                     //
        &xSub,       // OUT: The displacement value used to 
                     //      reduce the magnitude of the data 
                     //      initially before computing the 
                     //      other moments.
                     //
        &xMean,      // OUT: The mean of the magnitude-reduced
                     //      data.
                     //
        &xStd );     // OUT: The standard deviation of the
                     //      magnitude-reduced data.
    
    // Scale and center the y values, moving them into the matrix.
    ConvertDataToZScores( 
        y,           // The first raw data item.
                     //
        n,           // The number of data items.
                     //
        sizeof(f64), // The address increment from one data item
                     // to the next in bytes.
                     //
        zy,          // The first z-score result -- this can be
                     // the same address as 'y' to convert the
                     // data in place.
                     //
        sizeof(f64), // The address increment from one z-score
                     // to the next in bytes.
                     //
        &ySub,       // OUT: The displacement value used to 
                     //      reduce the magnitude of the data 
                     //      initially before computing the 
                     //      other moments.
                     //
        &yMean,      // OUT: The mean of the magnitude-reduced
                     //      data.
                     //
        &yStd );     // OUT: The standard deviation of the
                     //      magnitude-reduced data.
  
    xx = yy = xy = xsum = ysum = 0.0;
    
    for( i=0; i<n; i++ ) 
    {
        xval = x[i];
        yval = y[i];
        xx += xval*xval;
        yy += yval*yval;;
        xy += xval*yval;
        xsum += xval;
        ysum += yval;
    }
    
    xmean = xsum/n; 
    ymean = ysum/n;
    num   = xy - xsum*ymean;
    
    *m    = num/(xx - xsum*xmean);
    *rsq  = (*m)*num/(yy - ysum*ymean);
    
    // 'm' is the slope of the scaled points, dy/dx.
    //
    // To compute the slope of the unscaled points multiply by
    // the scaling factors.
    *m = *m * yStd / xStd; 
    
    // Calculate the unadjusted mean of the points, taking it as
    // being on the line.
    xMean += xSub; 
    yMean += ySub; 

    // At this point we have the slope and one point on the line,
    // the mean point.
    //
    // Solving for the y intercept, 'b'...
    // 
    //         y = mx + b 
    //
    //         y - mx = b
    //
    *b = yMean - ( *m * xMean ); 
}

/*------------------------------------------------------------
| LineFitTls
|-------------------------------------------------------------
|
| PURPOSE: To finds the line, Y = m*X + b, that is the total
|          least-squares fit to a set of (x,y) pairs.
| 
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: There are errors in both the 'x' and the 'y'
|          measurements.
|  
|          Use 'LineFit()' if there is error only in the 'y'
|          measurements.
|
|          Errors in 'x' and 'y' are not correlated.
|
| NOTE:
|
| HISTORY: 03.02.00 from 'LineFit', 'Variance'.
|                   Centers and scales using simple midpoint
|                   and range of x an y.
|          03.04.00 Changed scaling to use z-scores. Tested.
|          03.04.00 Made workspaces input parameters to reduce
|                   memory fragmentation.
|          04.17.00 Fixed array bounds error: 'w[2]' and 
|                   'e[2]' were one element too small due to
|                   the use of 1-based indexing within SVD
|                   routine.
------------------------------------------------------------*/
                // OUT: Returns flag 1 if a solution was found
u32             //      or returns 0 if no solution was found. 
LineFitTls( 
    f64*    x,  // IN: The X values, the abscissa array.
                //
    f64*    y,  // IN: The Y values, the ordinate array.
                //
    s32     n,  // IN: The number of items in 'x' and 'y'.
                //
    f64*    m,  // OUT: The returned slope in Y = m * X + b.
                //
    f64*    b,  // OUT: The returned y-intercept in Y = m * X + b.
                //
                // WORKSPACES: Allocate theses structures to hold
                // intermediate results ...
                //
    f64**   a,  //  a = matrix( 1, n, 1, 2 );
    f64*    r,  //  r = vector( 1, n );
    f64**   v ) //  v = matrix( 1, 2, 1, 2 ); 
                //
                // Free the working space like this...
                //
                //  free_matrix( v, 1, 2, 1, 2 );
                //  free_vector( r, 1, n  );
                //  free_matrix( a, 1, n, 1, 2 );
{
    s32     RowCount, ColCount, ok;
    f64     xMean, yMean;
    f64     xSub, ySub;
    f64     xStd, yStd;
    f64     X[4];
    f64     w[4];
    f64     e[4];

    // Set the number of rows and columns.
    RowCount = n;
    ColCount = 2;
    
    // Scale and center the x values, moving them into the matrix.
    ConvertDataToZScores( 
        x,           // The first raw data item.
                     //
        n,           // The number of data items.
                     //
        sizeof(f64), // The address increment from one data item
                     // to the next in bytes.
                     //
        a[1] + 1,    // The first z-score result -- this can be
                     // the same address as 'x' to convert the
                     // data in place.
                     //
        sizeof(f64)*2,  
                     // The address increment from one z-score
                     // to the next in bytes.
                     //
        &xSub,       // OUT: The displacement value used to 
                     //      reduce the magnitude of the data 
                     //      initially before computing the 
                     //      other moments.
                     //
        &xMean,      // OUT: The mean of the magnitude-reduced
                     //      data.
                     //
        &xStd );     // OUT: The standard deviation of the
                     //      magnitude-reduced data.
    
    // Scale and center the y values, moving them into the matrix.
    ConvertDataToZScores( 
        y,           // The first raw data item.
                     //
        n,           // The number of data items.
                     //
        sizeof(f64), // The address increment from one data item
                     // to the next in bytes.
                     //
        a[1] + 2,    // The first z-score result -- this can be
                     // the same address as 'y' to convert the
                     // data in place.
                     //
        sizeof(f64)*2,  
                     // The address increment from one z-score
                     // to the next in bytes.
                     //
        &ySub,       // OUT: The displacement value used to 
                     //      reduce the magnitude of the data 
                     //      initially before computing the 
                     //      other moments.
                     //
        &yMean,      // OUT: The mean of the magnitude-reduced
                     //      data.
                     //
        &yStd );     // OUT: The standard deviation of the
                     //      magnitude-reduced data.
    
    // Calculate the TLS solution.
    ok = TotalLeastSquares( 
            a,      // IN: A matrix such that there are at least as
                    //     many rows as columns.
                    //
                    //     The matrix is constructed by joining the
                    //     'b' column to the right of the 'A' matrix.
                    //
                    //        Ab is [ A b ]
                    //
                    // OUT: This matrix gets messed up.
                    //
            X,      // IN: A buffer with ColCount - 1 elements.
                    //
                    // OUT: The solution vector, 'X' 
                    //      with ColCount - 1 elements.
                    //
            RowCount,       
                    // Number of rows in matrix 'a'.
                    //
            ColCount,       
                    // Number of columns in matrix 'a'.
                    //
            w,      // IN: Workspace, allocate using...
                    //
                    //     w = vector( 1, ColCount );
                    //
            v,      // IN: Workspace, allocate using... 
                    //
                    //     v = matrix( 1, ColCount, 1, ColCount );
                    //
            r,      // IN: Workspace, allocate using...
                    //
                    //     r = vector( 1, RowCount );
            e );    //
                    // IN: Workspace, allocate using...
                    //
                    //     e = vector( 1, ColCount );

    // X[1] is the slope of the scaled points, dy/dx.
    //
    // To compute the slope of the unscaled points multiply by
    // the scaling factors.
    *m = X[1] * yStd / xStd; 
    
    // Calculate the unadjusted mean of the points, taking it as
    // being on the line.
    xMean += xSub; 
    yMean += ySub; 

    // At this point we have the slope and one point on the line,
    // the mean point.
    //
    // Solving for the y intercept, 'b'...
    // 
    //         y = mx + b 
    //
    //         y - mx = b
    //
    *b = yMean - ( *m * xMean ); 
        
    // Return the status flag.
    return( ok );
}

/*------------------------------------------------------------
| TotalLeastSquares
|-------------------------------------------------------------
|
| PURPOSE: To determine the total least-squares solution of
|
|                           A x = b
|
| DESCRIPTION: [From page 381 of the book] "In the least-
| squares problems considered up to this point, the solution 
| minimizing 
|
|                        || A x - b ||
|
| has been sought, with the tacit assumption that the matrix
| 'A' is correct, and any errors in the problem are in 'b'.
|
| The vector 'b' is projected into the range of A to find the
| solution.  By the assumption, any changes needed to find a
| a solution must come from modifying only 'b'.
|
| However, in many problems, the matrix 'A' is determined from
| measured data, and hence may have errors also.  Thus, it may
| be of use to find a solution to the problem A x = b which
| allows for the fact that both 'A' and 'b' may be in error.
| Problems of this sort are known as "total least-squares
| problems (TLS)".
|
| EXAMPLE:  
|
| NOTE:  'A' is the system matrix.
|
|        'b' is the right-hand side.
|
|        'x' is the solution to A x = b.
|
| ASSUMES: Both 'A' and 'b' contain errors which must be 
|          minimized. 
|           
| HISTORY: 02.18.00 From "Mathematical Methods and Algorithms
|                   for Signal Processing" by Todd K. Moon.
|          02.27.00 Validated using Van Huffel's test example.
|          03.01.00 Replaced Numerical Recipes SVD routine
|                   with routine from LINPACK -- it has a
|                   feature that the other lacks, namely that
|                   the singular values are ordered in
|                   descending order, also it allows the 
|                   U matrix to be neglected which saves time
|                   in TLS where the U matrix is not needed.
|              TBD  Unfortunately dropping the U matrix 
|                   causes wrong answers and I don't why.
|          03.13.00 Fixed error where all of w vector is equal.
------------------------------------------------------------*/
u32         // OUT: 1 if solution is found, else 0.
TotalLeastSquares( 
    f64**   ab, 
            // IN: A matrix such that there are at least as
            //     many rows as columns.
            //
            //     The matrix is constructed by joining the
            //     'b' column to the right of the 'A' matrix.
            //
            //        Ab is [ A b ]
            //
            // OUT: This matrix gets messed up.
            //
    f64*    x, 
            // IN: A buffer with n - 1 elements.
            //
            // OUT: The solution vector, 'x' 
            //      with n - 1 elements.
    s32     m, 
            // Number of rows in matrix 'Ab'.
            //
    s32     n, 
            // Number of columns in matrix 'Ab'.
            //
    f64*    w, 
            // IN: Workspace, allocate using...
            //
            //     w = vector( 1, n );
    f64**   v,
            // IN: Workspace, allocate using... 
            //
            //     v = matrix( 1, n, 1, n );
            //
    f64*    r, 
            // IN: Workspace, allocate using...
            //
            //     r = vector( 1, m );
    f64*    e ) 
            // IN: Workspace, allocate using...
            //
            //     e = vector( 1, n );
{
    s32     i, j, nc;
    f64     beta, gg, Q, vv, z;
    Matrix* Ab;
    Matrix* V;
    s32     info;
    
    // Refer to the matrix headers.
    Ab = ToMatrixHeader( (void**) ab, 1, 2, 64, BASE_INDEX );
    V  = ToMatrixHeader( (void**) v, 1, 2, 64, BASE_INDEX );

    // Perform the decomposition.
    SingularValueDecompositionFromLINPACK( 
        ab,     // IN:  x[1..xRows][1..xCols] array.
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
        ab,     // OUT:  u[1..xRows][1..xCols] array.
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
        r,      // IN: work[1..xRows] is a scratch vector. 
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
            
    // Determine how many of the singular values in 'w' are
    // the same.  
    //
    // NOTE: The magnitude of the values in 'w' always 
    //       decreases or stays the same as the index 'n' 
    //       increases.
    //
    
    // Starting with the last pair of elements in 'w'.
    i = n;
    
    // While the pair of elements are equal within the chop tolerance.
    while( Eq( w[i], w[i-1] ) )
    {
        // Step back to the next pair.
        i--;
        
        // If there are no more pairs to test.
        if( i < 2 )
        {
            // Then exit the loop.
            break;
        }
    }
             
    // Reuse matrix 'Ab' to hold the null space of 'v'.
    //
    // The book calls this matrix 'Vtilde'.
    //
    // Calculate the number of columns in null space: at least one column.
    nc = n - i + 1;
    
    // 'Vtilde' consists of the right-most columns of 'v' such
    // that their corresponding singular values, 'w', are
    // the same, with the right-most column always included.
    CopyRegionOfMatrix( 
        V,      // SourceMatrix
        1,      //    SourceUpperRow 
        n - nc + 1,     
                //    SourceLeftColumn 
        n,      //    RowCount 
        nc,     //    ColumnCount 
        Ab,     // TargetMatrix
        1,      //    TargetUpperRow 
        1 );    //    TargetLeftColumn

    // 'Ab' now contains data in rows[1..m], columns [1..nc]. 
    //
    // The book calls this matrix 'Vtilde', the null space of 'v'.
     
    // Make the Householder vector from the last row of the
    // nullspace matrix, reusing 'w' to hold the result.
    HouseholderVector( ab[m], w, nc );
    
    // Expanding 'qrmakeq()' for the case where there is only
    // one Householder vector in the input matrix with 'nc' 
    // columns. 
    {
        // The result matrix degenerates to a single number, 'Q'.
        //
        // 'Q' starts with the value 1.0.
        Q = 1.0;
        
        // For each column in the nullspace vector, 'w', working
        // from right to left.
        for( j = nc; j >= 1; j-- )
        {
            // Pick off one number from 'w' and call it 'vv'.
            vv = w[j];
            
            // Update 'Q' by applying the Householder transformation
            // based on 'vv' to Q on the left -- expanding 
            // 'houseleft()' in place for this case.
            {
                // If 'vv' is non-zero.
                if( ! Eq( vv, 0.0 ) )
                {
                    // Some stuff I don't understand...
                    
                    gg = Q * vv;
                    
                    beta = -2.0 / ( vv * vv );
                    
                    Q = Q + beta * vv * gg;
                }
            }
        }
    }       
     
    // Multiply 'Q' times the null space matrix currently
    // held in 'Ab' as rows[1..m], columns [1..nc].
    //
    // The net result is that the null space is scaled.
    for( i = 1; i <= m; i++ )
    {
        for( j = 1; j <= nc; j++ )
        {
            ab[i][j] *= Q;
        }
    }
     
    // Get the value in the first column of the 'nth'
    // row as 'z'.
    z = ab[n][1];
    
    // If 'z' is non-zero then there is a solution.
    if( ! Eq( z, 0.0 ) )
    {
        // For each element of the result vector,'x'.
        for( i = 1; i <= n - 1; i++ )
        {
            // Calculate the result vector, 'x'.
            x[i] = -( ab[i][1] / z );
        }
        
        // And return successfully.
        return( 1 );
    }
 
    // Signal failure to find a solution.
    return( 0 );
 }      
        
    
