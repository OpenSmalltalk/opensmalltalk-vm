/*------------------------------------------------------------
| TLEntropy.c
|-------------------------------------------------------------
|
| PURPOSE: To provide functions that use Shannon's entropy
|          function for analyzing data.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 02.02.95 Separated out from 'Statistics.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>

#include "TLTypes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLList.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLMatrixInput.h"
#include "TLMatrixOutput.h"
#include "TLMatrixMath.h"
#include "TLArray.h"
#include "TLExtent.h"
#include "TLRandom.h"
#include "TLSubRandom.h"
#include "TLFile.h"
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLf64.h"
#include "TLNumber.h"
#include "TLPoints.h"
#include "TLGeometry.h"
#include "TLWeight.h"
#include "TLStat.h"
//#include "TLGraph.h"
#include "TLCombinatorics.h"
//#include "TLInterest.h"
#include "TLTwo.h"

#include "TLEntropy.h"

#ifndef log2
#define log2    Log2ForZeroToOne
#endif

// This refers to a look-up table for the function
// Ÿ(p) = p * log2(p), where 'p' is a value 0 <= p <= 1.
// See 'MakepLog2pTable'.
f64* pLog2p = 0;

/*------------------------------------------------------------
| BinaryEntropy
|-------------------------------------------------------------
|
| PURPOSE: To compute the binary entropy function.
|
| DESCRIPTION:  
|
|       f(x) = x log2( 1/x ) + (1-x) log2( 1/(1-x) )
|
|       with f(x) = 0 if x == 0 or 1.
| 
| EXAMPLE: 
|
| NOTE: See Mathematica worksheet "Binary Entropy Function".
|
| ASSUMES: One input, one output. Intype: Z1 OutType: Z1.
|           
| HISTORY: 06.23.97 
|          06.25.97 found bug in 'log2' for numbers very 
|                   close to .5, this function produced 
|                   values slightly larger than 1.  Tried out
|                   long double log2 function and found that
|                   long double support is flaky.
------------------------------------------------------------*/
f64
BinaryEntropy( f64 x )
{
//#define LOG2L
#ifdef LOG2L
    fl128 a, y, Lx, one, OneOverLx, OneOverA, LxTerm, ATerm;
    f64  oneb;
    
    Lx  = (fl128) x;
//  one = (fl128) 1.; This is interpreted as a very small fraction.
//                    This is a compiler bug.
//                    Don't use long doubles until compiler is
//                    fixed.
    oneb = 1.;  
    one  = (f64) oneb;
    
    if( Lx <= 0. || Lx >= 1. )
    {
        return( 0. );
    }
    else
    {
         a = one - Lx;
         OneOverLx = one / Lx;
         OneOverA  = one / a;
         
         LxTerm = log2l( OneOverLx );
         ATerm  = log2l( OneOverA );
         
         y = Lx * LxTerm +  a * ATerm;
             
         return( (f64) y );
    }
#else
    f64 a, y;
    
    if( x <= 0. || x >= 1. )
    {
        return( 0. );
    }
    else
    {
         a = 1. - x;
         
         y = x * log2( 1./x ) + 
             a * log2( 1./a );
         
         // Limit values to less than or equal to 1 to 
         // correct for log2 imprecision.
         if( y > 1. ) y = 1.;
         
         return( y );
    }
#endif
}

/*------------------------------------------------------------
| BurgEntropyOfItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a group of data values
|          using Burg measure of entropy.
|
| DESCRIPTION: Treats each value in the group as a proportion
| of the sum of the values in the group and then applies the
| Burg entropy function: log2(n).
|
| The Burg entropy function differs from the Shannon entropy
| measure in these ways:
|
|   The result is always negative, although we flip it to
|   positive for compatibility.
|
|   The Burg maximum entropy probability distribution (MEPD)
|   follows a harmonic progression whereas the Shannon MEPD
|   follows a geometric progression.
|
| EXAMPLE:  
|           g = BurgEntropyOfItems( Prices, SampleCount );
|
| NOTE: See p. 260 'Measures of Information' by Kapur.
|
| ASSUMES: 
|
| HISTORY: 03.02.96  
------------------------------------------------------------*/
f64
BurgEntropyOfItems( f64* AtData, s32 ItemCount )
{
    f64 DataSum;
    f64 v;
    s32  i;
    f64 *D;
    f64 TotalEntropy;
    
    // Total the data.
    DataSum = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        DataSum += *D++;
    }
    
    // Total the entropy.
    TotalEntropy = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        v = *D++;
        
        if( v != 0 )
        {
            v /= DataSum;
            
            TotalEntropy += log2( v );
        }
    }
    
    return( -TotalEntropy );
}

/*------------------------------------------------------------
| CrossEntropy
|-------------------------------------------------------------
|
| PURPOSE: To calculate the Kullback-Leibler cross-entropy
|          measure for two sets of values with the same number
|          of items.
|
| DESCRIPTION: 
|
| "Let P = (p1, p2, ... pn ) and Q = (q1, q1... qn) be two
|  probability distributions.  Then, Kullback-Leibler's
|  measure is defined as
|
|                     n
|                   -----
|                   \         Pi
|           D(P:Q) = > Pi ln ----
|                   /         Qi
|                   -----
|                    i=1
| 
|  where we assume that whenever Qi = 0, the corresponding
|  Pi is also zero.  We define 0 ln( 0/0 ) = 0."
|
| "Though D(P:Q) is not symmetric, the measure
|
|          J(P:Q) = D(P:Q) + D(Q:P)        (4.26)
|
|  is symmetric, since clearly J(P:Q) = J(Q:P)."
|
| EXAMPLE: xe = CrossEntropy( ClosePrice, Open, ItemCount );
|
| NOTE: See p.155 of 'Entropy Optimization Principles with
|       Applications'.
|
| ASSUMES: The same number of items are present in each
|          vector.
|
|          Values are zero or positive.
|
| HISTORY: 09.05.96 from 'CrossEntropyOfVectors'.
|          05.14.97 fixed case where division by zero occurs.
------------------------------------------------------------*/
f64
CrossEntropy( f64* p, f64* q, s32 ItemCount )
{
    s32     i;
    f64 pSum, qSum, qx, px;
    f64 xe;

    // Calculate the sums used for converting XY values to
    // proportions. 
    pSum = SumItems( p, ItemCount );
    qSum = SumItems( q, ItemCount );

    // Reject all zero distributions.
    if( (pSum == 0 ) || ( qSum == 0 ) )
    {
        return( 1. );
    }
    
    // Accumulate the cross-entropy.
    xe = 0;
    for( i = 0; i < ItemCount; i++ )
    {
        // Make the proportions.
        qx = q[i] / qSum;
        px = p[i] / pSum;
        
        if( qx > 0 && px > 0 )
        {
            xe += px * log( px/qx );
        }
    }
    
    return( xe );
}

/*------------------------------------------------------------
| CrossEntropy2
|-------------------------------------------------------------
|
| PURPOSE: To calculate the Kullback-Leibler cross-entropy
|          measure for two sets of values with the same number
|          of items.
|
| DESCRIPTION: 
|
| "Let P = (p1, p2, ... pn ) and Q = (q1, q1... qn) be two
|  probability distributions.  Then, Kullback-Leibler's
|  measure is defined as
|
|                     n
|                   -----
|                   \         Pi
|           D(P:Q) = > Pi ln ----
|                   /         Qi
|                   -----
|                    i=1
| 
|  where we assume that whenever Qi = 0, the corresponding
|  Pi is also zero.  We define 0 ln( 0/0 ) = 0."
|
| "Though D(P:Q) is not symmetric, the measure
|
|          J(P:Q) = D(P:Q) + D(Q:P)        (4.26)
|
|  is symmetric, since clearly J(P:Q) = J(Q:P)."
|
| EXAMPLE: xe = CrossEntropy( ClosePrice, Open, ItemCount );
|
| NOTE: See p.155 of 'Entropy Optimization Principles with
|       Applications'.
|
| ASSUMES: The same number of items are present in each
|          vector.
|
|          Values are positive or negative but positive and
|          negative values of the same magnitude are confused
|          by this function.
|
| HISTORY: 09.05.96 from 'CrossEntropyOfVectors'.
|          05.14.97 fixed case where division by zero occurs.
------------------------------------------------------------*/
f64
CrossEntropy2( f64* p, f64* q, s32 ItemCount )
{
    s32     i;
    f64 pSum, qSum, qx, px;
    f64 xe;

    // Calculate the sums used for converting XY values to
    // proportions. 
    pSum = SumMagnitudeOfItems( p, ItemCount );
    qSum = SumMagnitudeOfItems( q, ItemCount );

    // Accumulate the cross-entropy.
    xe = 0;
    for( i = 0; i < ItemCount; i++ )
    {
        // Make the proportions.
        qx = q[i] / qSum;
        px = p[i] / pSum;

        if( qx < 0 ) qx = -qx;
        if( px < 0 ) px = -px;
        
        if( qx > 0 && px > 0 )
        {
            xe += px * log( px/qx );
        }
    }
    
    return( xe );
}

/*------------------------------------------------------------
| CrossEntropyOfVectors
|-------------------------------------------------------------
|
| PURPOSE: To calculate the Kullback-Leibler cross-entropy
|          measure for two XY vectors.
|
| DESCRIPTION: 
|
| "Let P = (p1, p2, ... pn ) and Q = (q1, q1... qn) be two
|  probability distributions.  Then, Kullback-Leibler's
|  measure is defined as
|
|                     n
|                   -----
|                   \         Pi
|           D(P:Q) = > Pi ln ----
|                   /         Qi
|                   -----
|                    i=1
| 
|  where we assume that whenever Qi = 0, the corresponding
|  Pi is also zero.  We define 0 ln( 0/0 ) = 0."
|
| "Though D(P:Q) is not symmetric, the measure
|
|          J(P:Q) = D(P:Q) + D(Q:P)        (4.26)
|
|  is symmetric, since clearly J(P:Q) = J(Q:P)."
|
|
|
| Translates the values to positive to avoid zeros and
| negative values.
|
| EXAMPLE: xe = CrossEntropyOfVectors( ClosePrice, Open );
|
| NOTE: See p.155 of 'Entropy Optimization Principles with
|       Applications'.
|
| ASSUMES: The same number of items are present in each
|          vector.
|
|          Both X and Y values are present.
|
| HISTORY: 04.02.96
------------------------------------------------------------*/
f64
CrossEntropyOfVectors( Vector* p, Vector* q )
{
    s32     i, ItemCount;
    f64 PxSum, PySum, QxSum, QySum;
    f64 xe,ye,px,py,qx,qy;
    f64*    PX;
    f64*    PY;
    f64*    QX;
    f64*    QY;
    Vector* P; 
    Vector* Q;
    f64 minX,minY;
    f64 PLoX,PLoY,QLoX,QLoY;
    
    ItemCount = p->ItemCount;
    
    // Get the vector extents.
    PLoX = LowValue( p->X, ItemCount );
    PLoY = LowValue( p->Y, ItemCount );
    QLoX = LowValue( q->X, ItemCount );
    QLoY = LowValue( q->Y, ItemCount );
    
    // Compute the X and Y values needed to add to the vectors
    // in order to make all values positive.
    minX = min( PLoX, QLoX );
    minY = min( PLoY, QLoY );

    // Translate the working copies if necessary.
    if( minX <= 0.0 || minY <= 0.0 )
    {
        // Make working copies of the vectors.
        P = DuplicateVector(p);
        Q = DuplicateVector(q);
        
        if( minX <= 0.0 )
        {
            AddToItems( P->X, ItemCount, (-minX) + ChopTolerance );
            AddToItems( Q->X, ItemCount, (-minX) + ChopTolerance );
        }
        
        if( minY <= 0.0 )
        {
            AddToItems( P->Y, ItemCount, (-minY) + ChopTolerance );
            AddToItems( Q->Y, ItemCount, (-minY) + ChopTolerance );
        }
    }
    else // Refer to the existing vectors with new names.
    {
        P = p;
        Q = q;
    }   
    
    // Refer to vectors.
    PX = P->X;
    PY = P->Y;
    QX = Q->X;
    QY = Q->Y;
    
    // Calculate the sums used for converting XY values to
    // proportions. 
    SumOfVector( P, &PxSum, &PySum );
    SumOfVector( Q, &QxSum, &QySum );

    // Accumulate the cross-entropy.
    xe = 0;
    ye = 0;
    for( i = 0; i < ItemCount; i++ )
    {
        // Make the proportions for Q.
        qx = QX[i] / QxSum;
        qy = QY[i] / QySum;
        
        // Make the proportions for P.
        px = PX[i] / PxSum;
        py = PY[i] / PySum;
        
        // Ignore values that fall below the chop threshold.
        if( qx < ChopTolerance ||
            qy < ChopTolerance ||
            px < ChopTolerance ||
            py < ChopTolerance )
        {
            continue;
        }
             
        // Sum the symmetric X and Y dimension KL measures.
        // DEFER: this is a mess. Need to integrate X and Y
        //        but don't know how. 
        xe += (px * log( px/qx ) + qx * log( qx/px )) + 
              (py * log( py/qy ) + qy * log( qy/py ));
        
    }
//  xe += ye; // result is sum of both X and Y.

//  if( isnan(xe) ) Debugger();
    
    // If working copies of vectors were made, delete them.
    if( minX <= 0.0 || minY <= 0.0 )
    {
        free( P );
        free( Q );
    }
    
    return( xe );
}

/*------------------------------------------------------------
| DependencyTableEntropyStats
|-------------------------------------------------------------
|
| PURPOSE: To calculate a set of entropy statistics for a
|          two-dimensional dependency table.
|
| DESCRIPTION: Given a two-dimensional dependency table with
| x rows and y columns (in the sense of y = f(x)),
| calculates the following quantities:
|
|      H(x,y)....entropy of the whole table
|      H(x)......entropy of the x distribution, rows
|      H(y)......entropy of the y distribution, cols
|      H(x|y)....entropy of x given y
|      H(y|x)....entropy of y given x
|      U(x|y)....dependency of x on y
|      U(y|x)....dependency of y on x
|      U(x,y)....symmetrical dependency
|
| where the dependency values range from 0, independent, to
| 1, complete dependency: knowledge of one determines that
| of the other.
|
| An identity:
|
|      H(x,y) = H(x) + H(y|x) = H(y) + H(x|y)
|
| EXAMPLE: 
|
|    DependencyTableEntropyStats( Table, 
|                                 &Hxy,
|                                 &Hx,
|                                 &Hy,
|                                 &Hxgy,
|                                 &Hygx,
|                                 &Uxgy,
|                                 &Uygx,
|                                 &Uxy );
|
| NOTE: See p.633 of 'Numerical Recipes in C'.
|
| HISTORY: 05.24.96
------------------------------------------------------------*/
void
DependencyTableEntropyStats( 
    Matrix* Table, 
    f64* Hxy,
    f64* Hx,
    f64* Hy,
    f64* Hxgy,
    f64* Hygx,
    f64* Uxgy,
    f64* Uygx,
    f64* Uxy ) 
{
    f64**  T;
    s32     i, j, RowCount, ColCount;
    f64 Sum, *RowSum, *ColSum;
    f64 hxy, hx, hy, hxgy, hygx, uxgy, uygx, uxy;
    
    // Get the table extent.
    RowCount = Table->RowCount;
    ColCount = Table->ColCount;
    
    // Refer to the data.
    T = (f64**) Table->a;
    
    // Allocate buffers for the row and column sums.
    RowSum = MakeItems(RowCount, 0);
    ColSum = MakeItems(ColCount, 0);
    
    // Form the row totals and overall total.
    Sum = 0;
    for( i = 0; i < RowCount; i++ )
    {
        RowSum[i] = 0;
        
        for( j = 0; j < ColCount; j++ )
        {
            RowSum[i] += T[i][j];
            
            Sum += T[i][j];
        }
    }
    
    // Form the column totals.
    for( j = 0; j < ColCount; j++ )
    {
        ColSum[j] = 0;
        
        for( i = 0; i < RowCount; i++ )
        {
            ColSum[j] += T[i][j];
        }
    }
    
    // Calculate the x entropy, the rows.
    hx = EntropyOfItems( RowSum, RowCount );
    
    // Calculate the y entropy, the columns.
    hy = EntropyOfItems( ColSum, ColCount );
    
    // Calculate the total entropy of the matrix.
    hxy = EntropyOfMatrix( Table );
    
    // Calc H(y|x) using the identity
    // H(x,y) = H(x) + H(y|x) = H(y) + H(x|y)
    hygx = hxy - hx;
    
    // Calc H(x|y) using the identity
    // H(x,y) = H(x) + H(y|x) = H(y) + H(x|y)
    hxgy = hxy - hy;

    // Calc U(y|x). Small number added to avoid divide
    // by zero error.
    uygx = (hy - hygx)/(hy + 1.0e-30);
    
    // Calc U(x|y).  
    uxgy = (hx - hxgy)/(hx + 1.0e-30);
    
    // Calc U(x,y). 
    uxy = 2.0 * (hx + hy - hxy)/(hx + hy + 1.0e-30);
    
    // Return the results.
    *Hxy  = hxy;
    *Hx   = hx;
    *Hy   = hy;
    *Hygx = hygx;
    *Hxgy = hxgy;
    *Uygx = uygx;
    *Uxgy = uxgy;
    *Uxy  = uxy;
     
    // Discard the dynamic buffers.
    free( RowSum );
    free( ColSum );
}   

/*------------------------------------------------------------
| EntropicMedian
|-------------------------------------------------------------
|
| PURPOSE: To calculate the median value of a set of data 
|          such that the entropy of the groups of data points 
|          on either side are most nearly identical.
|
| DESCRIPTION: 
|
| EXAMPLE:     m = EntropicMedian( Prices, EntryCount );
|
| NOTE: 
|
| ASSUMES: Given vector can be sorted in place.
|
| HISTORY: 07.16.95 
|          02.02.96 removed bin classification.
------------------------------------------------------------*/
f64
EntropicMedian( f64* AtData, s32 EntryCount )
{
    s32 Lo, Mid, Hi;
    f64 LoEnt;
    f64 HiEnt;
    f64 Cond;

    // Sort the data in place.
    SortVector( AtData, EntryCount );

    Lo = 0;  
    Hi = EntryCount - 1;
    
    while( Lo <= Hi )
    {
        Mid = (Hi + Lo) >> 1; // (Hi+Lo)/2  

        // Entropy of values before 'Mid'.
        LoEnt = EntropyOfItems( AtData, Mid );
        
        // Entropy of values after 'Mid'.
        HiEnt = EntropyOfItems( &AtData[Mid+1], 
                                 EntryCount - (Mid+1) );
        
        Cond = HiEnt - LoEnt;    

        if( Cond == 0 )
        {    
            // Exact match.
            return( AtData[Mid] );
        }

        if( Cond < 0 )  // HiEnt < LoEnt, so give more entries
        {               // to high section to increase entropy.
            Hi = Mid - 1;
        }
        else // HiEnt > LoEnt
        {
            Lo = Mid + 1;
        }
    }

    return( AtData[Hi] ); // Hi is last best.
}

/*------------------------------------------------------------
| EntropyOfColumn
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a column of a matrix.
|
| DESCRIPTION:  
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfColumn( ASpace, c1 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.03.96
------------------------------------------------------------*/
f64
EntropyOfColumn( Matrix* AMatrix, s32 Col )  
{
    f64     v;
    s32     r;
    f64     DataSum;
    f64     EntropySum;
    f64**  A;
    s32     RowCount;
    
    // Refer to the cells.
    A = (f64**) AMatrix->a;

    // Local copy of row count for speed.
    RowCount = AMatrix->RowCount;
    
    // Total the entropy.
    EntropySum = 0;
    
    // Total the data in the column.
    DataSum = 0;
    for( r = 0; r < RowCount; r++ )
    {
        DataSum += A[r][Col];
    }
        
    for( r = 0; r < RowCount; r++ )
    {
        v =  A[r][Col];
        
        if( v != 0 )
        {
            v /= DataSum;
            
            EntropySum += -( v * log2( v ) );
        }
    }
    
    return( EntropySum );
}

/*------------------------------------------------------------
| EntropyOfColumns
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of columns of a matrix.
|
| DESCRIPTION: The entropy of each column in the range is 
| computed separately and summed to produce the result.
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfColumns( ASpace, c1, c2 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.02.96
------------------------------------------------------------*/
f64
EntropyOfColumns( Matrix* AMatrix, s32 ColFirst, s32 ColLast  )  
{
    f64     v;
    s32     r,c;
    f64     DataSum;
    f64     EntropySum;
    f64**  A;
    s32     RowCount;
    
    // Refer to the cells.
    A = (f64**) AMatrix->a;

    // Local copy of row count for speed.
    RowCount = AMatrix->RowCount;
    
    
    // Total the entropy.
    EntropySum = 0;
    for( c = ColFirst; c <= ColLast; c++ )
    {
        // Total the data in the column.
        DataSum = 0;
        for( r = 0; r < RowCount; r++ )
        {
            DataSum +=  A[r][c];
        }
        
        for( r = 0; r < RowCount; r++ )
        {
            v =  A[r][c];
        
            if( v != 0 )
            {
                v /= DataSum;
            
                EntropySum += -( v * log2( v ) );
            }
        }
    }
    
    return( EntropySum );
}

/*------------------------------------------------------------
| EntropyOfConstrainedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a matrix with the
|          natural constraint that row entopy should equal
|          column entropy.
|
| DESCRIPTION: 
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfConstrainedMatrix( ASpace );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.03.95 
------------------------------------------------------------*/
#ifdef DEFER
f64
EntropyOfConstrainedMatrix( Matrix** MatrixVector, s32 Count )
{
    f64  TotalEntropy;

    // Sum entropies of rows and columns separately.
    TotalEntropy = 
        EntropyOfRows( AMatrix, 0, AMatrix->RowCount - 1 ) +
        EntropyOfColumns( AMatrix, 0, AMatrix->ColCount - 1 ); 
    
    return( TotalEntropy );
}
#endif

/*------------------------------------------------------------
| EntropyOfConstrainedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a matrix with the
|          natural constraint that row entopy should equal
|          column entropy.
|
| DESCRIPTION: 
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfConstrainedMatrix( ASpace );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.03.95 
------------------------------------------------------------*/
f64
EntropyOfConstrainedMatrix( Matrix* AMatrix )
{
    f64  TotalEntropy;

    // Sum entropies of rows and columns separately.
    TotalEntropy = 
        EntropyOfRows( AMatrix, 0, AMatrix->RowCount - 1 ) +
        EntropyOfColumns( AMatrix, 0, AMatrix->ColCount - 1 ); 
    
    return( TotalEntropy );
}

/*------------------------------------------------------------
| EntropyOfDeviations
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of the absolute deviations
|          in two series of values.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|           g = EntropyOfDeviations( A, B, Count );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 09.14.96
------------------------------------------------------------*/
f64
EntropyOfDeviations( f64* A, f64* B, s32 ItemCount )
{
    f64* Diffs;
    f64  Dif, ent;
    s32   i;
    
    Diffs = MakeItems( ItemCount, 0 );
    
    for( i = 0; i < ItemCount; i++ )
    {
        Dif = A[i] - B[i];
        
        if( Dif < 0 )
        {
            Dif = -Dif;
        }
         
        Diffs[i] = Dif;
    }
    
    ent = EntropyOfItems( Diffs, ItemCount );
    
    free( Diffs );
    
    return( ent );
}

/*------------------------------------------------------------
| EntropyOfItemsUsingBins
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of data that is
|          quantized into fixed width bins.
|
| DESCRIPTION: Result is sum of
|
|                     p x -ln(p)
|  
|              for all bins where 'p' is the probability of
|              a sample falling into a bin.
|
| Result is in base 2 logarithm or bits/sample(bin).
|
| EXAMPLE:  
|      EntropyOfItemsUsingBins( Prices, 
|                                SampleCount, 
|                                WorkingBuffer, 
|                                .01 );
|
| NOTE: 
|
| ASSUMES: Bin buffer is large enough.
|
| HISTORY: 07.13.95 
|          07.30.95 Changed to use fixed width bins.
|          02.02.96 fixed error where sample count was used
|                   instead of bin count. Changed name from
|                   'Entropy'.
------------------------------------------------------------*/
f64
EntropyOfItemsUsingBins( 
    f64* AtData, s32  SampleCount, 
    s32*  AtBins, f64 BinWidth )
{
    f64 TotalEntropy;
    f64 BinProportion;
    f64 fSampleCount;
    s32* AtBin;
    s32  i;
    s32  ACount;
    s32  BinCount;
    
    // Calculate frequencies.
    BinCount = 
        BinCountsWithFixedBinWidth( AtData, 
                                    SampleCount, 
                                    AtBins,
                                    BinWidth );
    // Accumulate the entropy.
    AtBin = AtBins;
    TotalEntropy = 0;
    fSampleCount = (f64) SampleCount; // for speed.
    for( i = 0; i < BinCount; i++ )
    {
        ACount = *AtBin++;
        
        if( ACount ) // non-zero
        {
            BinProportion =  ((f64) ACount) / BinCount;
        
            TotalEntropy += BinProportion *
                        ( -log2( BinProportion ) );
        }
    }
    
    return( TotalEntropy );
}

/*------------------------------------------------------------
| EntropyOfRegion
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a region of a matrix.
|
| DESCRIPTION: Result is sum of
|
|                     c/T x -ln(c/t)
|  
|              for all 'T' cells in the region, 
|              where 'c' is the value in a cell.
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfRegion( ASpace, r1, r2, c2, c5 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.02.96
------------------------------------------------------------*/
f64
EntropyOfRegion( Matrix* AMatrix,
                 s32     RowFirst,
                 s32     RowLast,   
                 s32     ColFirst,
                 s32     ColLast )  
{
    f64     v;
    s32     r,c ;
    f64     DataSum;
    f64     EntropySum;
    f64**  A;
    
    // Refer to the cells.
    A = (f64**) AMatrix->a;

    // Total the data in the region.
    DataSum = 0;
    for( r = RowFirst; r <= RowLast; r++ )
    {
        for( c = ColFirst; c <= ColLast; c++ )
        {
            DataSum += A[r][c];
        }
    }
    
    // Total the entropy.
    EntropySum = 0;
    for( r = RowFirst; r <= RowLast; r++ )
    {
        for( c = ColFirst; c <= ColLast; c++ )
        {
            v =  A[r][c];
        
            if( v != 0 )
            {
                v /= DataSum;
            
                EntropySum += -( v * log2( v ) );
            }
        }
    }
    
    return( EntropySum );
}

/*------------------------------------------------------------
| EntropyOfRow
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a row in a matrix.
|
| DESCRIPTION: Each cell is treated as a proportion of the
| entire row.
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfRows( ASpace, r1, r2 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.02.96
|          02.01.00 Added 'SumOfRow' to avoid compiler bug.
------------------------------------------------------------*/
f64
EntropyOfRow( Matrix* AMatrix, s32 Row )  
{
    f64     v;
    s32     c;
    f64     DataSum;
    f64     EntropySum;
    f64**   A;
    s32     ColCount;
    
    // Refer to the cells.
    A = (f64**) AMatrix->a;

    // Local copy of column count for speed.
    ColCount = AMatrix->ColCount;
    
    // Total the data in the row.
    DataSum = SumOfRow( AMatrix, Row );

    // Total the entropy.
    EntropySum = 0;
        
    for( c = 0; c < ColCount; c++ )
    {
        v = A[Row][c];
        
        if( v != 0 )
        {
            v /= DataSum;
            
            EntropySum += -( v * log2( v ) );
        }
    }
    
    return( EntropySum );
}

/*------------------------------------------------------------
| EntropyOfRows
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a range of rows of a 
|          matrix.
|
| DESCRIPTION: The entropy of each row in the range is computed
| separately and summed to produce the result.
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfRows( ASpace, r1, r2 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.02.96
|          02.01.00 Added 'SumOfRow' to avoid compiler bug.
------------------------------------------------------------*/
f64
EntropyOfRows( Matrix* AMatrix, s32  RowFirst, s32 RowLast  )  
{
    f64     v;
    s32     r,c;
    f64     DataSum;
    f64     EntropySum;
    f64**   A;
    s32     ColCount;
    
    // Refer to the cells.
    A = (f64**) AMatrix->a;

    // Local copy of column count for speed.
    ColCount = AMatrix->ColCount;
    
    // Total the entropy.
    EntropySum = 0;
    for( r = RowFirst; r <= RowLast; r++ )
    {
        // Total the data in the row.
        DataSum = SumOfRow( AMatrix, r );
        
        for( c = 0; c < ColCount; c++ )
        {
            v =  A[r][c];
        
            if( v != 0 )
            {
                v /= DataSum;
            
                EntropySum += -( v * log2( v ) );
            }
        }
    }
    
    return( EntropySum );
}

/*------------------------------------------------------------
| EntropyOfMatrix
|-------------------------------------------------------------
|
| PURPOSE: To calculate the unconstrained entropy sum of a 
|          matrix.
|
| DESCRIPTION: Result is sum of
|
|                     c/T x -ln(c/t)
|  
|              for all 'T' cells where 'c' is the value in
|              a cell.
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfMatrix( ASpace );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.15.95 
------------------------------------------------------------*/
f64
EntropyOfMatrix( Matrix* AMatrix )
{
    f64* ACell;
    s32  CellCount;

    // Calculate how many cells there are in the matrix.
    CellCount = AMatrix->RowCount * AMatrix->ColCount;
    
    // Refer to the address of the first cell. 
    ACell = AtCell( AMatrix, 
                    AMatrix->LoRowIndex,
                    AMatrix->LoColIndex );
    
    // Treat the matrix as a vector.
    return( EntropyOfItems( ACell, CellCount ) );
}

/*------------------------------------------------------------
| EntropyOfMatrixUpwardDiagonals
|-------------------------------------------------------------
|
| PURPOSE: To calculate the mean per cell entropy of the upward 
|          diagonal strips of a matrix.
|
| DESCRIPTION: This is used mainly to evaluate the consistency
| of an index table as a predictor.
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = EntropyOfMatrixUpwardDiagonals( ASpace );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.22.96 from EntropyOfMatrix
|          05.24.96 fixed diagonal cell count when matrix
|                   wider than tall.
------------------------------------------------------------*/
f64
EntropyOfMatrixUpwardDiagonals( Matrix* AMatrix )
{
    s32     i,j;
    s32     ColCount,RowCount,LeastDimension;
    s32     LastCol,LastRow;
    s32     DiagonalCellCount;
    f64     Sum;
    f64**   A;
    f64*    ADiagonal;
    
    // Get matrix dimensions.
    ColCount = AMatrix->ColCount;
    RowCount = AMatrix->RowCount;
    LastCol  = ColCount - 1;
    LastRow  = RowCount - 1;
    
    A = (f64**) AMatrix->a;
    
    // Smallest dimension.
    LeastDimension = 
        (ColCount>RowCount) ? RowCount : ColCount;
    
    // Allocate a buffer to hold the values along a
    // diagonal.
    ADiagonal = (f64*) 
        malloc( LeastDimension * sizeof(f64) );
        
    // Clear the sum of the diagonal entropies.
    Sum = 0;
    
    // For each diagonal that terminates in the top row
    // but not on the right column.
    for( i = 1; i < LastCol; i++ )
    {
        // Calculate the number of cells in the diagonal.
        DiagonalCellCount = min(RowCount,i+1);

        // Fill the diagonal buffer with values.
        for( j = 0; j < DiagonalCellCount; j++ )
        {
            ADiagonal[j] = A[j][i-j];
        }
        
        Sum += EntropyOfItems( ADiagonal, DiagonalCellCount );
    }
    
    // For each diagonal that terminates on the right column.
    for( i = 0; i < LastRow; i++ )
    {
        // Calculate the number of cells in the diagonal.
        DiagonalCellCount = RowCount - i;
        if( DiagonalCellCount > LeastDimension )
        {
            DiagonalCellCount = LeastDimension;
        }
            
        // Fill the diagonal buffer with values.
        for( j = 0; j < DiagonalCellCount; j++ )
        {
            ADiagonal[j] = A[i+j][LastCol-j];
        }
        
        Sum += EntropyOfItems( ADiagonal, DiagonalCellCount );
    }
    
    // Free the buffer that holds the diagonal values.
    free( ADiagonal );
    
    // Convert the sum to a per cell average.
    Sum /= RowCount * ColCount - 2;
    
    // Return the entropy sum.
    return( Sum );
}

/*------------------------------------------------------------
| EntropyOfItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a group of data values.
|
| DESCRIPTION: Treats each value in the group as a proportion
| of the sum of the values in the group and then applies the
| Shannon entropy function: -n log2(n).
|
| The Shannon entropy function has this beautiful property:
| the entropy (symmetry) measures can be added, and if the
| group is perfectly symmetrical then the entropy sum  
| is maximized.
|
|      Number of 
|     Symmetrical      Shannon's
|   Items in Group     Entropy
|         2            1.000000
|         3            1.584963
|         4            2.000000
|         5            2.321928
|         6            2.584963
|         7            2.807355
|         8            3.000000
|         9            3.169925
|        10            3.321928
|
| It has many other excellent properties: see 
| 'Entropy Optimization Principles with Applications' by Kapur 
| and Kesavan.
|
| EXAMPLE:  
|           g = EntropyOfItems( Prices, SampleCount );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.02.96 
|          07.31.96 added 'DataScale' so that multiply can
|                   be used in place of divide which is faster.
|          08.01.96 applied '-' at end rather than for each
|                   part of entropy to speed things a bit.
|          08.02.96 put inline log2 calculation to improve 
|                   speed: actually ended up a bit slower;
|                   restored to the way it was.
|          08.06.96 factored out scaling of term before
|                   log2() to improve precision.
|          08.13.96 installed Pade approximated log2.
------------------------------------------------------------*/
f64
EntropyOfItems( f64* AtData, s32 ItemCount )
{
    f64     DataSum, DataScale;
    f64     v,w;
    s32     i;
    f64     *D;
    f64     TotalEntropy;
    
    // Total the data.
    DataSum = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        DataSum += *D++;
    }
    
    DataScale = 1. / DataSum;
    
    // Total the entropy.
    TotalEntropy = 0;
    D = AtData;
    i = ItemCount;
    
    while( i-- )
    {
        v = *D++;
        
        if( v > 0 )
        {
            w = v * DataScale;

#ifdef OLDWAY
            TotalEntropy += v * log2( w );
#else // Compute log2 in-line: from 'Log2ForZeroToOne'.
{
    f64 X, X2, X3, X4, X5, X6, X7, X8;
    f64 Mantissa, Characteristic;
    s16     n[4], exponent;
    f64*   nn;
    f64 Numer, Denom;
    
    // Refer to the buffer used to extract the exponent
    // from the floating point number
    nn = (f64*) &n[0];
    
    // Store the floating point number in the buffer.
    *nn = w;

    // Extract the exponent: assumes no sign.
    exponent = n[0] >> 4;
    
    // Log2 of the exponent part is found by finding
    // the difference from .5 exponent.  For example,
    // .1 has an exponent of 1019, and .5 has an
    // exponent of 1022, so the characteristic
    // (the integral part of the log) is 
    // (1019 - 1022) = -3.
    Characteristic = (f64) ( exponent - 1022 );
    
    // Shift x into the range 1/2 < x < 1.
    // Preserve the 4bits that are part of the fraction
    // and replace the exponent with that of .5.
    n[0] = (n[0] & 0x000f) | 0x3fe0;
    w = *nn;

    // Economized Pade approximation produced using
    // Mathematica. See p.32 of 'Guide To Standard
    // Mathematica Packages'.
    X   = w - .75;
    X2  = X   * X;
    X3  = X   * X2;
    X4  = X2  * X2;
    X5  = X3  * X2;
    X6  = X3  * X3;
    X7  = X4  * X3;
    X8  = X4  * X4;
 
    Numer = -0.40288937170018929156967146809620 - 
            0.289453420280495365979334110306809   * X + 
            4.0355533825665474978450220078230     * X2 + 
            10.8861337096357360110232548322529    * X3 + 
            11.8447933015428539249569439562038    * X4 + 
            6.3907737263360626656094609643333     * X5 + 
            1.69332577030682651653137327230070    * X6 + 
            0.189886910572759359805417034294805   * X7 + 
            0.0057643119931949371448354213498533  * X8;
    
    Denom = 0.97073004824922393130037789887865 + 
            5.1965023069708120573295673239045       * X + 
            11.3617303700811493882838476565666      * X2 + 
            13.0392704917401740516424979432486      * X3 + 
            8.3949437212993913703940052073449       * X4 + 
            2.99799648363043758081403211690485      * X5 + 
            0.54736420757188308794383146960172      * X6 + 
            0.041846067504350624444153794456724     * X7 + 
            0.00077612505702798206819181814353215   * X8;
 
    // Make the fractional part.
    Mantissa = Numer / Denom;
    TotalEntropy += v * ( Characteristic + Mantissa );
}
#endif
        }
    }
    
    v = -TotalEntropy / DataSum;
    
    return( v );
}

/*------------------------------------------------------------
| EntropyOfItems2
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of a group of data values.
|
| DESCRIPTION: Same as 'EntropyOfItems' but uses table 
|              look-up method.
|
| EXAMPLE:  
|           g = EntropyOfItems2( Prices, SampleCount );
|
| NOTE: Usually not as accurate as 'EntropyOfItems'.
|
| ASSUMES: 
|
| HISTORY: 08.05.96
------------------------------------------------------------*/
f64
EntropyOfItems2( f64* AtData, s32 ItemCount )
{
    f64     DataSum, DataScale;
    f64     v;
    s32     i;
    f64     *D;
    f64     TotalEntropy;
    
    // Total the data.
    DataSum = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        DataSum += *D++;
    }
    
    DataScale = 1. / DataSum;
    
    // Total the entropy.
    TotalEntropy = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        v = *D++;
        
        if( v > 0 )
        {
            v *= DataScale;
            
            TotalEntropy += 
                pLog2p[(u32) ( (v + .0000005) * 1000000. )];
        }
    }
    
    return( -TotalEntropy );
}

/*------------------------------------------------------------
| EntropyOfNegativeItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of the negative values
|          in a group of data values.
|
| DESCRIPTION: Treats each negative value in the group as a 
| proportion of the sum of the negative values in the group 
| and then applies the Shannon entropy function: -n log2(n).
|
| EXAMPLE:  
|           g = EntropyOfNegativeItems( Prices, SampleCount );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 04.08.96 from 'EntropyOfItems'
------------------------------------------------------------*/
f64
EntropyOfNegativeItems( f64* AtData, s32 ItemCount )
{
    f64 DataSum;
    f64 v;
    s32  i;
    f64 *D;
    f64 TotalEntropy;
    
    // Total the data.
    DataSum = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        v = *D++;
        
        if( v < 0 )
        {
            DataSum += -v;
        }
    }
    
    // Total the entropy.
    TotalEntropy = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        v = *D++;
        
        if( v < 0 )
        {
            v /= -DataSum;
            
            TotalEntropy += -( v * log2( v ) );
        }
    }
    
    return( TotalEntropy );
}

/*------------------------------------------------------------
| EntropyOfPositiveItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the entropy of the positive values
|          in a group of data values.
|
| DESCRIPTION: Treats each positive value in the group as a 
| proportion of the sum of the positive values in the group 
| and then applies the Shannon entropy function: -n log2(n).
|
| EXAMPLE:  
|           g = EntropyOfPositiveItems( Prices, SampleCount );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 04.08.96 from 'EntropyOfItems'
------------------------------------------------------------*/
f64
EntropyOfPositiveItems( f64* AtData, s32 ItemCount )
{
    f64 DataSum;
    f64 v;
    s32  i;
    f64 *D;
    f64 TotalEntropy;
    
    // Total the data.
    DataSum = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        v = *D++;
        
        if( v > 0 )
        {
            DataSum += v;
        }
    }
    
    // Total the entropy.
    TotalEntropy = 0;
    D = AtData;
    i = ItemCount;
    while( i-- )
    {
        v = *D++;
        
        if( v > 0 )
        {
            v /= DataSum;
            
            TotalEntropy += -( v * log2( v ) );
        }
    }
    
    return( TotalEntropy );
}

/* ------------------------------------------------------------
| EntropyOfTrend
|-------------------------------------------------------------
|
| PURPOSE: To measure the entropy of a range of prices treated
|          as a trend.
|
| DESCRIPTION: Every combination of two prices is selected,
| implicit interest rate computed, and then the entropy of
| the whole set of rates is taken.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Item[0] preceeds Item[1] in time.
|          All items are daily prices without gaps.
|
| HISTORY: 07.30.96 
-----------------------------------------------------------*/
f64
EntropyOfTrend( f64* Items, s32 Count )
{
    s32             HowMany;
    static f64* ABuf;
    static s32      ABufCount = 0;
    static f64* BBuf;
    static s32      BBufCount = 0;
    
    // Calculate how many combinations of prices there will
    // be.
    HowMany = (s32) Combinations( (f64) Count, 2. );
    
    // Make sure there is room in the buffer to receive
    // the rate values.
    if( HowMany > ABufCount )
    {
        if( ABufCount > 0 )
        {
            free( ABuf );
        }
        
        ABuf = MakeItems( HowMany, 0 );
        
        ABufCount = HowMany;
    }
    
    // Make a buffer large enough to hold the logs of the
    // items.
    if( Count > BBufCount )
    {
        if( BBufCount > 0 )
        {
            free( BBuf );
        }
        
        BBuf = MakeItems( Count, 0 );
        
        BBufCount = Count;
    }
    
    // Compute the logs of the input prices to save time 
    // in later calculations.
    LogItems( Items, BBuf, Count );
    
    // For each pair of logprices.
    Debugger(); // Following line commented out for now:
                // put back as needed.
//  RatesOfLogPriceCombinations( BBuf, ABuf, Count );
    
    // Return the entropy of the rates.
    return( EntropyOfItems( ABuf, HowMany ) );
}

/* ------------------------------------------------------------
| EntropyOfTrendWithTimes
|-------------------------------------------------------------
|
| PURPOSE: To measure the entropy of a range of prices treated
|          as a trend.
|
| DESCRIPTION: Every combination of two prices is selected,
| implicit interest rate computed, and then the entropy of
| the whole set of rates is taken.  
|
| The 'Times' buffer holds the time points associated with 
| each price used for calculating the number of time periods.
|
| EXAMPLE:  
|
| NOTE: Untested.
|
| ASSUMES: Items are in time order.
|          All items are daily prices without gaps.
|
| HISTORY: 07.31.96 from 'EntropyOfTrend'
-----------------------------------------------------------*/
f64
EntropyOfTrendWithTimes( f64* Prices, f64* Times, s32 Count )
{
    s32             i, j,iMax;
    f64             LnPrincipal, LnAmount, Time, PrinTime;
    s32             HowMany;
    static f64* ABuf;
    static s32      ABufCount = 0;
    static f64* BBuf;
    static s32      BBufCount = 0;
    f64*            AA;
    f64*            BB;
    f64*            CC;
    
    // Calculate how many combinations of prices there will
    // be.
    HowMany = (s32) Combinations( (f64) Count, 2. );
    
    // Make sure there is room in the buffer to receive
    // the rate values.
    if( HowMany > ABufCount )
    {
        if( ABufCount > 0 )
        {
            free( ABuf );
        }
        
        ABuf = MakeItems( HowMany, 0 );
        
        ABufCount = HowMany;
    }
    
    // Make a buffer large enough to hold the logs of the
    // items.
    if( Count > BBufCount )
    {
        if( BBufCount > 0 )
        {
            free( BBuf );
        }
        
        BBuf = MakeItems( Count, 0 );
        
        BBufCount = Count;
    }
    
    // Compute the logs of the input prices to save time 
    // in later calculations.
    LogItems( Prices, BBuf, Count );
    
    
    // For each pair of logprices.
    iMax = Count - 1;
    AA   = ABuf;
    BB   = BBuf;
    
    for( i = 0; i < iMax; i++ )
    {
        LnPrincipal = *BB++;
        PrinTime = Times[i];
        
        CC = BB;
        
        for( j = i+1; j < Count; j++ )
        {
            LnAmount = *CC++;
            
            // Calculate the force of interest and then add 1 so
            // that the number is always positive. From
            // 'ForceOfInterest'.
            if( LnPrincipal == LnAmount ) 
            {
                *AA++ = 1.;
            }
            else
            {
                Time = Times[j] - PrinTime;
                
                *AA++ = 1. + (( LnAmount - LnPrincipal ) / Time);
            }
        }
    }
    
    // Return the entropy of the rates.
    return( EntropyOfItems( ABuf, HowMany ) );
}

/*------------------------------------------------------------
| EntropyOfVectorAngles
|-------------------------------------------------------------
|
| PURPOSE: To calculate the angular entropy of paired XY 
|          vectors.
|
| DESCRIPTION:  
|
| EXAMPLE: e = EntropyOfVectorAngles( ClosePrice, Open );
|
| NOTE:  
|
| ASSUMES: The same number of items are present in each
|          vector.
|
|          Both X and Y values are present, in Cartesian form.
|
| HISTORY: 04.04.96
------------------------------------------------------------*/
f64
EntropyOfVectorAngles( Vector* p, Vector* q )
{
    s32     ItemCount;
    Vector* P; 
    f64 ent;
    
    // Duplicate the first vector.
    P = DuplicateVector(p);
    
    // Subtract the second vector from the first.
    SubtractVector( P, q );
    
    // Convert the result to polar form.
    ConvertVectorToPolar( P );
    
    ItemCount = P->ItemCount;
    
    // Calculate the entropy of the angles.
    ent = EntropyOfItems( P->Y, ItemCount );
    
    // Discard the working vector.
    free( P );
    
    // Return the result.
    return( ent );
}

/*------------------------------------------------------------
| EntropyOfVectorDistances
|-------------------------------------------------------------
|
| PURPOSE: To calculate the distance entropy of paired XY 
|          vectors.
|
| DESCRIPTION:  
|
| EXAMPLE: e = EntropyOfVectorDistances( ClosePrice, Open );
|
| NOTE:  
|
| ASSUMES: The same number of items are present in each
|          vector.
|
|          Both X and Y values are present, in Cartesian form.
|
| HISTORY: 04.04.96
------------------------------------------------------------*/
f64
EntropyOfVectorDistances( Vector* p, Vector* q )
{
    s32     ItemCount;
    Vector* P; 
    f64 ent,x,y;
    f64*    X;
    f64*    Y;
    s32     i;
    
    
    // Duplicate the first vector.
    P = DuplicateVector(p);
    
    // Subtract the second vector from the first.
    SubtractVector( P, q );
    
    // Calculate the distance from the X,Y displacements.
    X = P->X;
    Y = P->Y;
    
    ItemCount = P->ItemCount;
    
    for(i = 0; i < ItemCount; i++)
    {
        x = X[i];
        y = Y[i];
        
        X[i] = sqrt(x*x + y*y);
    }   
    
    // Calculate the entropy of the distances.
    ent = EntropyOfItems( P->X, ItemCount );
//  ent = SumItems( P->X, ItemCount );
    
    // Discard the working vector.
    free( P );
    
    // Return the result.
    return( ent );
}

/*------------------------------------------------------------
| EntropyOfVectors
|-------------------------------------------------------------
|
| PURPOSE: To calculate the combined distance and angular
|          entropy of paired XY vectors.
|
| DESCRIPTION: This approaches a maximum as the vectors 
| converge.
|
| EXAMPLE: e = EntropyOfVectors( ClosePrice, Open );
|
| NOTE:  
|
| ASSUMES: The same number of items are present in each
|          vector.
|
|          Both X and Y values are present, in Cartesian form.
|
| HISTORY: 04.03.96
------------------------------------------------------------*/
f64
EntropyOfVectors( Vector* p, Vector* q )
{
    s32     ItemCount;
    Vector* P; 
    f64 ent;
    
    // Duplicate the first vector.
    P = DuplicateVector(p);
    
    // Subtract the second vector from the first.
    SubtractVector( P, q );
    
    // Convert the result to polar form.
    ConvertVectorToPolar( P );
    
    // Calculate the entropy of the distances.
    ItemCount = P->ItemCount;
    ent = EntropyOfItems( P->X, ItemCount );
    
    // Add the entropy of the angles.
    ent += EntropyOfItems( P->Y, ItemCount );
    
    // Discard the working vector.
    free( P );
    
    // Return the result.
    return( ent );
}

/*------------------------------------------------------------
| EstimateEntropicMedian
|-------------------------------------------------------------
|
| PURPOSE: To calculate the estimated entropic median of
|          a population.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|      m = EstimateEntropicMedian( Prices, A, B, C, 300 );
|
| NOTE: Have to use an algorithm less efficient than 
|       binary search because range of entropies may not
|       be completely in order.
|
| ASSUMES: 
|
| HISTORY: 07.16.95 
|          07.16.95 Estimating distribution of data gives
|                   worse results -- reverted back to just
|                   sorting incoming data.
|          07.16.95 Tried w/o sorting -- worse.
|          02.02.96 simplified.
------------------------------------------------------------*/
f64
EstimateEntropicMedian( f64* AtSample, 
                        f64* AtReplication, 
                        f64* AtEstimate, 
                        s32   EntryCount )
{
    s16  Lo,Mid,Hi;
    f64 LoEnt;
    f64 HiEnt;
    f64 Cond;

    // Convert the sample to an estimate of the
    // population from which it was drawn. 
    EstimateDistribution( AtSample, 
                          AtReplication, 
                          AtEstimate, 
                          EntryCount );

    // The estimate is sorted in increasing order.
    
    Lo = 0;  
    Hi = EntryCount - 1;
    
Start: // Until Lo,Mid & Hi converge.

    Mid = (Hi + Lo) >> 1; // (Hi+Lo)/2  

    // Entropy of values before and including 'Mid'.
    LoEnt = EntropyOfItems( AtEstimate, Mid+1 );
    
    // Entropy of values after 'Mid'.
    HiEnt = EntropyOfItems( &AtEstimate[Mid+1], 
                             EntryCount - (Mid+1) );
        
    Cond = HiEnt - LoEnt;    

    if( Cond == 0 )
    {    
        // Exact match.
        return( (AtEstimate[Mid] + AtEstimate[Mid-1])/2 );
    }

    // Have we converged?
    if( Lo+1 == Mid && Mid+1 == Hi )
    {
        // The best value falls between final values at the
        // hi/lo boundary.
        // Return the mean.
        return( (AtEstimate[Mid] + AtEstimate[Mid-1])/2 ); 
    }
    
    // Alter mid point by altering extremes.    
    
    if( Cond < 0 )  // HiEnt < LoEnt, so give more entries
    {               // to high section to increase entropy.
        if( Hi > Mid+1 )
        {
            Hi = (Hi+Mid) >> 1;
        }
        else // Increase lo by one.
        {
            Lo++;
        }
    }
    else // HiEnt > LoEnt
    {
        if( Lo < Mid-1 )
        {
            Lo = (Lo+Mid) >> 1;
        }
        else // Decrease Hi by one.
        {
            Hi--;
        }
    }
    
    goto Start;
}

/*------------------------------------------------------------
| EstimateEntropy
|-------------------------------------------------------------
|
| PURPOSE: To estimate the entropy of a population using a
|          sample data set from the population.
|
| DESCRIPTION: 
|
| Result is in base 2 logarithm or bits.
|
| Also returns the estimate of the population distribution
| as a by-product.
|
| EXAMPLE:
|  
|     en = EstimateEntropy( Prices, A, B, 500 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.16.95 
|          07.30.95 Added unit precision.
|          02.02.96 simplified.
------------------------------------------------------------*/
f64
EstimateEntropy( f64* AtSample, 
                 f64* AtReplication, 
                 f64* AtEstimate, 
                 s32   EntryCount )
{
    // Convert the sample to an estimate of the
    // population from which it was drawn. 
    EstimateDistribution( AtSample, 
                          AtReplication, 
                          AtEstimate, 
                          EntryCount );
    
    // Compute the entropy of the population estimate.
    return( EntropyOfItems( AtEstimate, EntryCount ) );
}

/*------------------------------------------------------------
| MakeEntropyMatrix
|-------------------------------------------------------------
|
| PURPOSE: To calculate an entropy matrix of a matrix.
|
| DESCRIPTION: Each result cell is:
|
|                  cell = p/T * -ln(p/T) 
|  
|              for all cells where 'p' is the original value
|              of the cell and T is the total of all the cells.
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           en = MakeEntropyMatrix( ASpace );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 07.15.95 
|          02.02.96 revised.
------------------------------------------------------------*/
Matrix*
MakeEntropyMatrix( Matrix* AMatrix )
{
    f64*    ACell;
    f64*    AtResultCell;
    s32     CellCount;
    Matrix* BMatrix;
    f64     DataSum;
    f64     v;
    s32     i;
    f64*    C;

//printf( "MakeEntropyMatrix...: %s\n", AMatrix->FileName );

    // Make a result matrix.
    BMatrix = MakeMatrix( (s8*) "Entropy", 
                          AMatrix->RowCount, 
                          AMatrix->ColCount );

    // Calculate how many cells there are in the matrix.
    CellCount = AMatrix->RowCount * AMatrix->ColCount;
    
    // Refer to the address of the first source cell. 
    ACell = AtCell( AMatrix, 
                    AMatrix->LoRowIndex,
                    AMatrix->LoColIndex );
    
    // Refer to the address of the first result cell. 
    AtResultCell = 
        AtCell( BMatrix, 
                BMatrix->LoRowIndex,
                BMatrix->LoColIndex );
    
    // Total the data.
    DataSum = 0;
    C = ACell;
    i = CellCount;
    while( i-- )
    {
        DataSum += *C++;
    }
    
    // Compute the entropy for each cell.
    C = ACell;
    i = CellCount;
    while( i-- )
    {
        v = *C++;
        
        if( v != 0 )
        {
            v /= DataSum; 
            
            *AtResultCell++ = -( v * log2( v ) );
        }
    }
    
    return( BMatrix );
}

/*------------------------------------------------------------
| MakepLog2pTable
|-------------------------------------------------------------
|
| PURPOSE: To make a 6-place look-up table for the function
|          p * log2(p) where 0 <= p <= 1.
|
| DESCRIPTION: There are 1,000,001 entries in the table, each
| 8 bytes long holding an 'f64'.
|
| To use the table convert a value 'p' to an index 'i' by:
|
|        i = (u32) ( (p + .0000005) * 1000000. );
| 
| The about formula rounds 'p' to six decimal places and then
| scales it by 100,000 to convert it to an integer.
|
| EXAMPLE:  
|           MakepLog2pTable();
|
|           i = (u32) ( (p + .0000005) * 1000000. );
|
|           x += pLog2p[i];
|
| NOTE: 
|
| ASSUMES: This will only be run once at progra start up.
|
| HISTORY: 08.05.96
------------------------------------------------------------*/
void
MakepLog2pTable()
{
    s32   i;
    s32   EntryCount;
    f64* plp;
    f64  p;
    
    EntryCount = 1000001; // one million for 0 thru 999,999
                          // and one for the case where 'p'
                          // is 1.
                          
    // Allocate the table.
    pLog2p = MakeItems( EntryCount, 0 );
    
    // The entry for p == 0 is 0.
    pLog2p[0] = 0;
    
    // Refer to the 2nd entry in the table.
    plp = &pLog2p[1];
                         
    for( i = 1 ;i < EntryCount; i++ )
    {
         p = i * .000001;
         
         *plp++ = p * log2( p );
    }
}

/*------------------------------------------------------------
| MedianEntropyOfMatrix
|-------------------------------------------------------------
|
| PURPOSE: To calculate median entropy of a matrix.
|
| DESCRIPTION: 
|
| Result is in base 2 logarithm or bits/sample.
|
| EXAMPLE:  
|           m = MedianEntropyOfMatrix( ASpace );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 01.03.96 from 'EntropyOfMatrix'.
|        
------------------------------------------------------------*/
f64
MedianEntropyOfMatrix( Matrix* AMatrix )
{
    f64     MedianEntropy;
    s32     CellCount;
    Matrix* BMatrix;
    f64*    AtFirstCell;
    
    // Calculate how many cells there are in the matrix.
    CellCount = AMatrix->RowCount * AMatrix->ColCount;
    
    // Compute the entropy matrix.
    BMatrix = MakeEntropyMatrix( AMatrix );

    // Refer to the first cell.
    AtFirstCell = AtCell( AMatrix, 
                          AMatrix->LoRowIndex,
                          AMatrix->LoColIndex );
                          
    // Compute the median of the entropy values.
    MedianEntropy = Median2( AtFirstCell, CellCount );
    
    // Discard the entropy matrix.
    DeleteMatrix( BMatrix );
    
    return( MedianEntropy  );
}

/* ------------------------------------------------------------
| MovingEntropicMedian
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving entropic median of a 
|          vector, resampled into a number of bins.
|
| DESCRIPTION: Returns result vector.
| First n-1 values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: Period is less than the sample count.
|
| HISTORY: 07.15.95  from 'MovingEntropy'.
|          07.29.95 Corrected fill value count at beginning.
-----------------------------------------------------------*/
void
MovingEntropicMedian(
    f64*    AtSample, // Input 
    f64*    AtResult, // Output
    f64*    AtWork,   // Working buffer as big as Period.
    s16*    AtBins,   // A work space as big as BinCount.
    s16     BinCount,
    s16     SampleCount,
    s16     Period )
{
    s16     i,j;
    f64 ent;
    f64 *AtSrcCell;
    f64 *AtDstCell;
    
    AtBins = AtBins;
    BinCount = BinCount;
    
    // Copy data to working buffer that can be changed.
    AtSrcCell = AtSample;
    AtDstCell = AtWork;
    for( j = 0; j < Period; j++ )
    {
        *AtDstCell++ = *AtSrcCell++;
    }
    
    // Calculate the first valid value.
    
    ent = EntropicMedian( AtWork, Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = ent;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        // Copy data to working buffer that can be changed.
        AtSrcCell = &AtSample[i-Period+1];
        AtDstCell = AtWork;
        for( j = 0; j < Period; j++ )
        {
            *AtDstCell++ = *AtSrcCell++;
        }
    
printf("MovingEntropicMedian: %d\n", i);
        *AtResult++ =  EntropicMedian( AtWork, Period );
    }
}

/* ------------------------------------------------------------
| MovingEntropy
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving entropy of a 
|          vector, resampled into a number of bins.
|
| DESCRIPTION: Returns result vector.
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: Period is less than the sample count.
|
| HISTORY: 07.13.95 .
|          07.29.95 Corrected fill value count at beginning.
|          07.30.95 Converted to fixed precision entropy.
|          02.02.96 Use 'EntropyOfItems'.
-----------------------------------------------------------*/
void
MovingEntropy(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    s32   SampleCount,
    s32   Period )
{
    s32     i;
    f64 ent;
    
    
    // Calculate the first valid value.
    ent = EntropyOfItems( AtSample, Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = ent;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        *AtResult++ =  EntropyOfItems( 
                            &AtSample[i-Period+1],
                            Period );
    }
}

/* ------------------------------------------------------------
| MovingEstimatedEntropicMedian
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving estimated entropic 
|          median of a vector.
|
| DESCRIPTION: Returns result vector.
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: Period is less than the sample count.
|
| HISTORY: 07.16.95  from 'MovingEntropicMedian'.
|          07.29.95 Corrected fill value count at beginning.
|          02.02.96 simplified.
-----------------------------------------------------------*/
void
MovingEstimatedEntropicMedian(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    f64  *AtWork1,  // Working buffer as big as Period.
    f64  *AtWork2,  // Working buffer as big as Period.
    s32   SampleCount,
    s32   Period )
{
    s32     i;
    f64 ent;
    
    // Calculate the first valid value.
    
    ent = EstimateEntropicMedian( AtSample,
                                  AtWork1, 
                                  AtWork2, 
                                  Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = ent;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
    
printf("MovingEstimatedEntropicMedian: %d\n", i);

        *AtResult++ =  EstimateEntropicMedian( 
                                       &AtSample[i-Period+1],
                                       AtWork1,
                                       AtWork2,
                                       Period );
    }
}

/*------------------------------------------------------------
| OptimizeEntropyOfMatrixFile
|-------------------------------------------------------------
|
| PURPOSE: To estimate matrix distribution from sample matrix
|          file for a number of passes.
|
| DESCRIPTION: Loads in the matrix file and then applies
| maximum entropy optimization on subrandomly selecte points
| until the given number of passes is complete, when the
| result is written to a file.
|
| Only contraint is that column entropy should equal row
| entropy.
|
| Dynamically allocates and frees working buffers.
|
| Shows progress.
|
| EXAMPLE:  
|
|           OptimizeEntropyOfMatrixFile( In, Out, 5, 10000 );
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 02.03.96 from 'SmoothMatrixFile'.
------------------------------------------------------------*/
void
OptimizeEntropyOfMatrixFile( 
    s8* InputFile,
    s8* OutputFile,
    f64 PointSpreadRadius,
    s32 Passes )
{
    Matrix* AMatrix;
    Matrix* BMatrix;

    AMatrix = ReadMatrix( InputFile );
            
    BMatrix = OptimizeEntropyOfMatrix( AMatrix, PointSpreadRadius, Passes );
    
    SaveMatrix( BMatrix, OutputFile );

    DeleteMatrix( AMatrix );
    DeleteMatrix( BMatrix );
}

/*------------------------------------------------------------
| OptimizeEntropyOfMatrix
|-------------------------------------------------------------
|
| PURPOSE: To estimate matrix distribution from sample matrix
|          for a number of passes.
|
| DESCRIPTION: Applies maximum entropy optimization on 
| subrandomly selected points until the given number of passes 
| is complete, when the result is written to a file.
|
| Only constraint is that column entropy should equal row
| entropy.
|
| Dynamically allocates and frees working buffers.
|
| Shows progress.
|
| EXAMPLE:  
|
|       Out = OptimizeEntropyOfMatrix( In, 1000 );
|
| NOTE:
|
| ASSUMES: 'BeginSubRandomSequence' called sometime before.
|
| NOTE:
|
| HISTORY: 02.03.96 from 'CorrectBiasInSummary3'.
------------------------------------------------------------*/
#define MAX_POINTS_TO_EQUALIZE  2
Matrix*
OptimizeEntropyOfMatrix( Matrix* In, f64 PointSpreadRadius, s32 Passes )
{
    f64 SavedPointValue[ MAX_POINTS_TO_EQUALIZE ];
    f64 SavedPointRowEntropy[ MAX_POINTS_TO_EQUALIZE ];
    f64 SavedPointColEntropy[ MAX_POINTS_TO_EQUALIZE ];
    f64 *SavedPointCell[ MAX_POINTS_TO_EQUALIZE ];
    f64 *RowEntropy;
    f64 *ColEntropy;
    f64 PointAverage;
    s32     i;
    f64 v;
    f64    BestEntropy;
    f64    NewEntropy;
    f64 PointVector[4];
    f64 PointTotal;
    Matrix* Out;
    s32     RowCount;
    s32     ColCount;
    s32     Row;
    s32     Col;
    s32     CenterRow;
    s32     CenterCol;
    s32     Pass;
    s32     LastUpdatePass;
    f64**   B;
    f64 PointSpreadDiameter;
    s32     PointsToEqualize;
    
printf("OptimizeEntropyOfMatrix: %s\n", In->FileName);
    
    RowCount = In->RowCount; 
    ColCount = In->ColCount;
    
    // Allocate a separate result matrix.
    Out = DuplicateMatrix( In );
    
    // Refer to the data cells.
    B = (f64**) Out->a;
    
    // Allocate vectors to hold row & column entropies.
    RowEntropy = malloc( RowCount * sizeof( f64 ) );
    ColEntropy = malloc( ColCount * sizeof( f64 ) );
    
    
    // Measure current entropy while setting the row 
    // and column totals for future update.
    BestEntropy = 0;
    for( i = 0; i < RowCount; i++ )
    {
        v = EntropyOfRow( Out, i );
        RowEntropy[i] = v;
        BestEntropy += v;
    }
    
    for( i = 0; i < ColCount; i++ )
    {
        v = EntropyOfColumn( Out, i );
        ColEntropy[i] = v;
        BestEntropy += v;
    }

    PointsToEqualize = 2; // Start small.

    PointSpreadDiameter = PointSpreadRadius * 2;
     
    // For each pass.
    LastUpdatePass = 0;
    for( Pass = 1; Pass < Passes; Pass++ )
    {
TryAnother:
        // Subrandomly choose two points to equalize.

        // Choose a center point and a radial point.
        SubRandomVector( PointVector, 4 );
            
        CenterRow = (s32) (PointVector[0] * RowCount);
        CenterCol = (s32) (PointVector[1] * ColCount);

        // Set up the radial point.
            
        Row = (s32) 
              ( (CenterRow - PointSpreadRadius) +
                (PointVector[2] * PointSpreadDiameter)
              );

        Col = (s32) 
              ( (CenterCol - PointSpreadRadius) +
                (PointVector[3] * PointSpreadDiameter)
              );
              
        // If point falls off screen, try another point.
        if( Row < 0           || 
            Row > RowCount-1  || 
            Col < 0           ||
            Col > ColCount-1 )
        {
            goto TryAnother;
        }
        
        // Save the values of the points and total the
        // values.      
        SavedPointCell[0] = &(B[CenterRow][CenterCol]);
        v = B[CenterRow][CenterCol];
        SavedPointValue[0] = v;
        PointTotal = v;

        SavedPointCell[1] = &(B[Row][Col]);
        v = B[Row][Col];
        SavedPointValue[1] = v;
        PointTotal += v;
        
        // Preserve the row and column entropy values.
        SavedPointRowEntropy[0] = RowEntropy[CenterRow];
        SavedPointColEntropy[0] = ColEntropy[CenterCol];
        SavedPointRowEntropy[1] = RowEntropy[Row];
        SavedPointColEntropy[1] = ColEntropy[Col];
        
        // Equalize the points.
        PointAverage = PointTotal / PointsToEqualize; 
        for( i = 0; i < PointsToEqualize; i++ )
        {
            *SavedPointCell[i] = PointAverage;
        }
        
        // Compute the new entropy, a departure from
        // the current best.
        NewEntropy = BestEntropy - 
                     RowEntropy[CenterRow] -
                     ColEntropy[CenterCol];

        // Calculate the entropy of changed row(s).
        v = EntropyOfRow( Out, CenterRow );
        RowEntropy[CenterRow] = v;
        NewEntropy += v;
        if( CenterRow != Row )
        {
            NewEntropy -= RowEntropy[Row];
            v = EntropyOfRow( Out, Row );
            RowEntropy[Row] = v;
            NewEntropy += v;
        }
        
        // Calculate the entropy of changed column(s).
        v = EntropyOfColumn( Out, CenterCol );
        ColEntropy[CenterCol] = v;
        NewEntropy += v;
        if( CenterCol != Col )
        {
            NewEntropy -= ColEntropy[Col];
            v = EntropyOfColumn( Out, Col );
            ColEntropy[Col] = v;
            NewEntropy += v;
        }
        
        // If the new entropy is higher, keep the points.
        if( NewEntropy > BestEntropy )
        {
            LastUpdatePass = Pass;
            BestEntropy = NewEntropy;
            
            // Add a carriage return.
//          if( Pass % 100 == 0)
//          {
//              printf( "+\n" );
//          }
//          fflush(stdout);
            
//          printf( "\nStep: %5.5d  entropy: %10.6f \n", 
//                  Pass+1, 
//                  BestEntropy );
        }
        else // Restore the point values and entropy values.
        {
            for( i = 0; i < PointsToEqualize; i++ )
            {
                *SavedPointCell[i] = SavedPointValue[i];
                
            }

            RowEntropy[CenterRow] = SavedPointRowEntropy[0];
            RowEntropy[Row]       = SavedPointRowEntropy[1];
            ColEntropy[CenterCol] = SavedPointColEntropy[0];
            ColEntropy[Col]       = SavedPointColEntropy[1];
            
            // Add a carriage return.
//          if( Pass % 100 == 0)
//          {
//              printf( ".\n" );
//          }
//          fflush(stdout);
        }

//      if( Button() )
//      {
//          Debugger();
//      }
    }
    
    free( RowEntropy );
    free( ColEntropy );

    // Return the result.
    return( Out );
}

/*------------------------------------------------------------
| Entropy 
|-------------------------------------------------------------
|
| PURPOSE: To measure the symmetry of a unit with respect to
|          a group.
|
| DESCRIPTION:  This is a measure of symmetry based on the 
| ratio of the unit size to the total group size, implemented 
| using the Shannon entropy function.
|
| The input value is a fraction with a value between 0 and 1, 
| inclusive, where 1 is the size of the entire group.
|
| Returns: 0, if value is 0 or 1, OR
|
|          n x -log2(n), for any other input value.
|
| Result is in base 2 logarithm or bits/sample(bin).
|
| EXAMPLE:    x = Entropy( .01 );
|
| NOTE:
|
| ASSUMES: 
|
| HISTORY: 02.02.96  
------------------------------------------------------------*/
f64
Entropy( f64 n )
{   
    f64 e;
    
    if( n == 0 || n == 1 ) 
    {
        e = 0;
    }
    else
    {
        e = - ( n * log2(n) );
    }
    
    return( e );
}


/* ------------------------------------------------------------
| Unity
|-------------------------------------------------------------
|
| PURPOSE: To calculate the strength of relation between two
|          signals (called 'A', 'B') measured at two different 
|          reference points (called 'x', 'y'), such as points 
|          in time or locations in space.
|
| DESCRIPTION: Returns a value greater than or equal to 0 and
|              less than or equal to 1.  1 means perfect unity,
|              meaning that each signal changes at the same
|              rate; a value near 0 means that the signals
|              change at very different rates.
|
|              This property is called 'Unity' because it is
|              a measure of the degree to which two things
|              can be regarded as one thing composed of parts
|              bearing a fixed relationship to one another.
|
|              Unity result is in terms of generic units.  
| EXAMPLE:  
|         
|        ax = 10;
|        ay = 1;
|        bx = 11;
|        by = 1;
|        u = Unity( ax, ay, bx, by )
|
|         ans =
|
|            0.9091
|
| NOTE: This is the Mex file for 'Unity.m'.
|
| ASSUMES: Input values are scalar >= 0.
|          'ax' parameter is a measure of the first object
|               at reference point (time) x.
|          'ay' parameter is a measure of the first object
|               at reference point (time) y.
|          'bx' parameter is a measure of the second object
|               at reference point (time) x.
|          'by' parameter is a measure of the second object
|               at reference point (time) y.
|           Correct number of parameters.
|          
| HISTORY:  09.24.94 
|           09.25.94 added displacement case.
|           10.23.94 converted to MATLAB.
|           12.10.94 changed to absratio of absratios.
|           12.18.94 converted to C mexFunction.
|           12.26.94 changed interface.
|           06.21.97 return zero if any value is zero.
|           07.14.97 return 1 if all values are zero.
-----------------------------------------------------------*/
f64
Unity( f64 ax, f64 ay,
       f64 bx, f64 by )
{
    f64 Result;
    f64 a,b;
    
    // If all values are zero, the result is one.
    if( ax == 0. && ay == 0. && bx == 0. && by == 0. )
    {
        return( 1. );
    }

    // If any value is zero, the result is zero.
    if( ax == 0. || ay == 0. || bx == 0. || by == 0. )
    {
        return( 0. );
    }
    
    // Find the absolute ratio of ax & ay.
    if( ax > ay )
    {
        a = ay / ax;
    }
    else
    {
        a = ax / ay;
    }
    
    // Find the absolute ratio of bx & by.
    if( bx > by )
    {
        b = by / bx;
    }
    else
    {
        b = bx / by;
    }
    
    // Calculate the absolute ratio of the ratios.
    if( a > b )
    {
        Result = b / a;
    }
    else
    {
        Result = a / b;
    }

    return( Result );
}

/* ------------------------------------------------------------
| VectorUnity
|-------------------------------------------------------------
|
| PURPOSE: To calculate the strength of relation between two
|          signal vectors (called 'A', 'B') measured at two 
|          different reference points (called 'x', 'y'), such 
|          as points in time or locations in space.
|
| DESCRIPTION: Returns a value greater than 0 and less than or 
|              equal to 1.  1 means perfect unity,
|              meaning a strong relation between the two 
|              signals; nearer to 0 means weak relation.
|
|              This property is called 'Unity' because it is
|              a measure of the degree to which two things
|              can be regarded as one thing composed of parts
|              bearing a fixed relationship to one another.
|
|              Unity result is in terms of generic units.  
| EXAMPLE:  
|
|        f64 ax[2] = {10, 1};
|        f64 ay[2] = {11,1.5};
|        f64 bx[2] = {.3, 5};
|        f64 by[2] = {.5,7};
|        VectorUnity( &ax, &ay, &bx, &by, 2 )
|
|        ans = 0.8275
|
| NOTE: 
|
| ASSUMES: Input values are >= 0.
|          'ax' parameter is a measure of the first object
|               at reference point (time) x.
|          'ay' parameter is a measure of the first object
|               at reference point (time) y.
|          'bx' parameter is a measure of the second object
|               at reference point (time) x.
|          'by' parameter is a measure of the second object
|               at reference point (time) y.
|
|          All input vectors are the same length.
|
| HISTORY:  11.13.94 
|           12.14.94 made each element of input vectors as
|                    an absolute ratio: Largest Unit Standard.
|           12.18.94 converted to C mexFunction.
|           12.26.94 changed interface.
-----------------------------------------------------------*/
f64
VectorUnity( f64 *ax, f64 *ay,
             f64 *bx, f64 *by,
             s16    EntryCount )
{
    f64 Result;
    
    f64 a,b,axx,ayy,bxx,byy;
    f64  SumOfASquared;
    f64  SumOfBSquared;
    s16     i;
    
    // Set up accumulators.
    SumOfASquared = 0;
    SumOfBSquared = 0;
    
    for( i = 0; i < EntryCount; i++ )
    {
        // Take the absolute ratio of each element
        // of a.
        
        axx = *ax++;
        ayy = *ay++;
        
        // Find the absolute ratio of ax & ay.
        if( axx > ayy )
        {
            a = ayy / axx;
        }
        else
        {
            a = axx / ayy;
        }
    
        SumOfASquared += a * a;
        
        // Take the absolute ratio of each element
        // of b.
        
        bxx = *bx++;
        byy = *by++;
        
        // Find the absolute ratio of ax & ay.
        if( bxx > byy )
        {
            b = byy / bxx;
        }
        else
        {
            b = bxx / byy;
        }
    
        SumOfBSquared += b * b;
    }
    
    // Calculate the length of each standardized vector.
    a = sqrt( SumOfASquared );
    b = sqrt( SumOfBSquared );
    
    // Calculate the absolute ratio of the ratios.
    if( a > b )
    {
        Result = b / a;
    }
    else
    {
        Result = a / b;
    }

    return( Result );
}

