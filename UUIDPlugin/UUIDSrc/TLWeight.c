/*------------------------------------------------------------
| TLWeight.c
|-------------------------------------------------------------
|
| PURPOSE: To provide functions for probability distributions 
|          defined by a histogram.
|
| HISTORY: 07.05.97 collected routines from 'RandomGen.c';
|                   added subrandom variations.
------------------------------------------------------------*/

#include "TLTarget.h"  // Include this first.

#include <stdio.h>
#include <stdlib.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLSubRandom.h"
#include "TLRandom.h"
#include "TLItems.h"
#include "TLList.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLWeight.h"

/*------------------------------------------------------------
| DuplicateWeights
|-------------------------------------------------------------
|
| PURPOSE: To make a new weight vector record with the same
|          information as a given set of weights.
|
| DESCRIPTION:  
|
| EXAMPLE: W = DuplicateWeights( A );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 07.05.97 from 'MakeWeights'.
------------------------------------------------------------*/
Wt*
DuplicateWeights( Wt* A ) 
{
    Wt* B;
    u32 ByteCount;
    
    // Calculate the record size.
    ByteCount = sizeof(Wt) + 
                2 * sizeof(f64) * A->Count +
                sizeof(s32) * A->Count;
    
    // Allocate a weight vector record.
    B = (Wt*) malloc( ByteCount );
    
    // Copy the source.
    CopyBytes( (u8*) A, (u8*) B, ByteCount );
    
    // Return the result.
    return( B );
}

/*------------------------------------------------------------
| MakeWeights
|-------------------------------------------------------------
|
| PURPOSE: To make a new weight vector record.
|
| DESCRIPTION: Given a weight count, makes a structure 
|              like this:
|      
|    ------------------------------------------------------
|    |  'Wts' header  |  Wt[]  |  CumWt[]  |  CumIndex[]  |
|    ------------------------------------------------------
|      |  |  |         ^        ^           ^
|      |  |  |         |        |           |
|      |  |  -----------        |           |
|      |  -----------------------           |
|      --------------------------------------
|
| EXAMPLE: W = MakeWeights( 14 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.19.97
------------------------------------------------------------*/
Wt*
MakeWeights( s32 WeightCount ) 
{
    Wt* W;
    u32 ByteCount;
    
    // Calculate the record size.
    ByteCount = sizeof(Wt) + 
                2 * sizeof(f64) * WeightCount +
                sizeof(s32) * WeightCount;
    
    // Allocate a weight vector record.
    W = (Wt*) malloc( ByteCount );
    
    // Clear the record.
    FillBytes( (u8*) W, ByteCount, 0 );

    // Set the counts.
    W->Count    = WeightCount;
    W->CumCount = 0;
    
    // Clear the sum.
    W->Sum      = 0.;
    
    // Set the links.
    W->Wt       = (f64*) ( ((u8*) W) + sizeof(Wt) );
    
    W->CumWt    = W->Wt + WeightCount;
    
    W->CumIndex = (s32*) ( W->CumWt + WeightCount );
    
    // Return the result.
    return( W );
}

/*------------------------------------------------------------
| PickRandomWeight
|-------------------------------------------------------------
|
| PURPOSE: To pick a random weight with the probability of 
| picking a weight equal to the ratio of the weight to the
| sum of the weights -- heavier weights are more likely.
|
| DESCRIPTION: Returns the index of the weight selected.
|
| Returns -1 if no weights are selected. 
|
| EXAMPLE:   
|
| NOTE: Only non-zero weights will be picked.
|
| ASSUMES: All weights are non-negative.
|
|          Weight sum has been accumulated using 'SumWeights'.
|          
|          'SetUpRandomNumberGenerator' has been called.
|
| HISTORY: 06.19.97
------------------------------------------------------------*/
s32
PickRandomWeight( Wt* W )
{
    f64 Which;
    s32  i;
    
    // If the cumulative weight count is zero.
    if( W->CumCount == 0 )
    {
        return( -1 );
    }
    
    // If there is only one non-zero weight.
    if( W->CumCount == 1 )
    {
        return( W->CumIndex[0] );
    }
    
    // Select a random value between 0 and the sum of all
    // weights.
    Which = RandomValueFromRange( 0, W->Sum );
    
    // Find the index in the cumulative weights vector.
    i = FindOffsetOfPlaceInOrderedVector( 
           Which, W->CumWt, W->CumCount );
    
    // Pass from the cumulative weight index to the simple
    // weight index.
    return( W->CumIndex[i] );
}

/*------------------------------------------------------------
| PickSubRandomWeight
|-------------------------------------------------------------
|
| PURPOSE: To pick a subrandom weight with the probability of 
| picking a weight equal to the ratio of the weight to the
| sum of the weights -- heavier weights are more likely.
|
| DESCRIPTION: Returns the index of the weight selected.
|
| Returns -1 if no weights are selected. 
|
| EXAMPLE:   
|
| NOTE: Only non-zero weights will be picked.
|
| ASSUMES: All weights are non-negative.
|
|          Weight sum has been accumulated using 'SumWeights'.
|          
|          'BeginSubRandomSequence' called at least once.
|
| HISTORY: 07.05.97 from 'PickRandomWeight'.
------------------------------------------------------------*/
s32
PickSubRandomWeight( Wt* W )
{
    f64 Which;
    s32  i;
    
    // If the cumulative weight count is zero.
    if( W->CumCount == 0 )
    {
        return( -1 );
    }
    
    // If there is only one non-zero weight.
    if( W->CumCount == 1 )
    {
        return( W->CumIndex[0] );
    }
    
    // Select a random value between 0 and the sum of all
    // weights.
    Which = SubRandomValueFromRange( 0, W->Sum );
    
    // Find the index in the cumulative weights vector.
    i = FindOffsetOfPlaceInOrderedVector( 
           Which, W->CumWt, W->CumCount );
    
    // Pass from the cumulative weight index to the simple
    // weight index.
    return( W->CumIndex[i] );
}

/*------------------------------------------------------------
| ReadWeightsFromFile
|-------------------------------------------------------------
|
| PURPOSE: To read weights from a file.
|
| DESCRIPTION: See 'WriteWeightsToFile'.
|
| Returns zero if there are no weights else returns a dynamic
| 'Wt' structure with the weights as they were before they
| were written to the file.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: File is positioned at the first number of a set
|          of weights, the count field. 
|           
| HISTORY: 07.05.97 from 'WriteWeightsToFile'.
------------------------------------------------------------*/
Wt*
ReadWeightsFromFile( FILE* F ) 
{
    Wt* W;
    s32 i;
    s32 Count;
    
    // Read the count.
    Count = (s32) ReadNumber( F );
        
    // If there are no weights.
    if( Count == 0 )
    {
        return( 0 );
    }
    else // There are weights.
    {
        // Make a new strucure.
        W = MakeWeights( Count );
    
        // For each weight.
        for( i = 0; i < Count; i++ )
        {
            // Read the weight.
            W->Wt[i] = ReadNumber( F );
        }
        
        // Reconstruct the cumulative sums.
        SumWeights( W );
        
        // Return the result.
        return( W );
    }
}

/*------------------------------------------------------------
| SumWeights
|-------------------------------------------------------------
|
| PURPOSE: To accumulate the sum of all the weights and set up
|          the cumulative non-zero weights.
|
| DESCRIPTION:  
|
| EXAMPLE:  SumWeights( W );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.19.97
------------------------------------------------------------*/
void
SumWeights( Wt* W )
{
    f64     Sum;
    f64     v;
    f64*    w;
    f64*    cw;
    s32*    ci;
    s32     i;
    s32     CumCount;
    s32     Count;
    
    // Get the count.
    Count = W->Count;
    
    // Accumulate the total sum and cumulative totals.
    Sum      = 0.;
    CumCount = 0;
    w        = W->Wt;
    cw       = W->CumWt;
    ci       = W->CumIndex;
    
    // For each weight.
    for( i = 0; i < Count; i++ )
    {
        // Get the weight value.
        v = *w++;
        
        // If the weight is positive.
        if( v > 0. )
        {
            // Accumulate the sum.
            Sum += v;
            
            // Save the cumulative sum.
            *cw++ = Sum;
            
            // Save the index of the weight which contributed
            // to the cumulative sum.
            *ci++ = i;
            
            // Account for the cumulative weight.
            CumCount++;
        }
    }
    
    // Save the sum.
    W->Sum = Sum;
    
    // Save the count of non-zero weights.
    W->CumCount = CumCount;
}

/*------------------------------------------------------------
| WriteWeightsToFile
|-------------------------------------------------------------
|
| PURPOSE: To write weights to a file.
|
| DESCRIPTION: Only saves the essential information necessary
| to reconstruct the weight structure when read back in.  
|
| Preceeds the weights by a count, which may be zero,
| followed by the weights.  Each number is in ASCII form,
| one per line.
|
| If the given weight address is zero, then a zero is written
| for the count.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 'SumWeights()' will be excuted when the data is
|          read back in to reconstruct the cumulative data.
|           
| HISTORY: 07.05.97
------------------------------------------------------------*/
void
WriteWeightsToFile( FILE* F, Wt* W ) 
{
    s32   i;
    s32   Count;
    
    // If there are no weights.
    if( W == 0 )
    {
        // Save a placeholder count.
        WriteNumber( F, 0. );
        
        return;
    }
    
    // Get the count.
    Count = W->Count;
    
    // Save the count.
    WriteNumber( F, (f64) Count );
    
    // For each weight.
    for( i = 0; i < Count; i++ )
    {
        // Save the weight to the file.
        WriteNumber( F, W->Wt[i] );
    }
}

/*------------------------------------------------------------
| ZeroWeights
|-------------------------------------------------------------
|
| PURPOSE: To clear a weight vector record.
|
| DESCRIPTION:  
|
| EXAMPLE: ZeroWeights( W );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.19.97
------------------------------------------------------------*/
void
ZeroWeights( Wt* W ) 
{
    f64* w;
    f64* cw;
    s32*  ci;
    s32   i;
    s32   Count;
    
    // Get the count.
    Count = W->Count;
    
    // Accumulate the total sum and cumulative totals.
    w  = W->Wt;
    cw = W->CumWt;
    ci = W->CumIndex;
    
    // For each weight.
    for( i = 0; i < Count; i++ )
    {
        *w++  = 0.;
        *cw++ = 0.;
        *ci++ = 0;
    }
    
    // Clear the sum.
    W->Sum = 0.;
    
    // Mark cumulative weights as empty.
    W->CumCount = 0;
}

