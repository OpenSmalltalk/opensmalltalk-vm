/*------------------------------------------------------------
| TLMedial.c
|-------------------------------------------------------------
|
| PURPOSE: To provide classification of data by medial 
|          subdivision. 
|
| DESCRIPTION: 
|        
| HISTORY: 04.22.96 
------------------------------------------------------------*/

#include "TLTarget.h"
    
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fp.h>
#include <Events.h> // For 'Button'.

#include "TLTypes.h"
#include "TLf64.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"  // for 'ParseDatum'
#include "TLList.h"
#include "TLNumber.h" // for 'ConvertStringToNumber'
                      // and 'ConvertNumberToString'
#include "TLListIO.h"
#include "TLDate.h" 
#include "TLSubRandom.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLMatrixExtra.h"
#include "TLArray.h"
#include "TLExtent.h"
#include "TLPoints.h"
#include "TLGeometry.h"
#include "TLWeight.h"
#include "TLStat.h"
#include "TLGraph.h"
#include "TLTwo.h"
#include "TLOrdinal.h"
#include "TLPointList.h"

#include "TLMedial.h"

/*------------------------------------------------------------
| CountCumulativeQuadrants
|-------------------------------------------------------------
|
| PURPOSE: To calculate the cumulative number of quadrants to
|          a given level of subdivision.
|
| DESCRIPTION: 
|
| The formula is: 
|                       L 
|                      ---
|                      \      D J
|       CumQuadrants = /    (2 ) 
|                      ---
|                      J=0
|
|     where 'D' ....... number of dimensions.
|
|           'L' ....... level of subdivision.
|
| EXAMPLE:  
|
|          c = CountCumulativeQuadrants( DimCount, Level );
|
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.24.96 
------------------------------------------------------------*/
s32
CountCumulativeQuadrants( s32 DimCount, s32 Level )
{
    s32 i;
    s32 CumQuads, QuadCount;
    
    // Calculate the cumulative number of quadrants including
    // the current level.
    CumQuads = 0;
    for( i = 0; i <= Level; i++ )
    {
        // Quads at a level of subdivision.
        QuadCount = PowerOfPowerOf2[DimCount][i];
        
        // Accumulate the sum.
        CumQuads += QuadCount;
    }

    // Return the cumulative quad count.
    return( CumQuads );
}

/*------------------------------------------------------------
| CountQuadrantsAtLevel
|-------------------------------------------------------------
|
| PURPOSE: To calculate the number of quadrants in a given 
|          level of subdivision.
|
| DESCRIPTION: 
|
| The formula is: 
|                       D L
|     QuadrantCount = (2 )  
|
|     where 'D' ....... number of dimensions, 1 or higher.
|
|           'L' ....... is the level of subdivision, 0 or higher.
|
| EXAMPLE:  
|
|          c = CountQuadrantsAtLevel( DimCount, Level );
|
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.24.96 
------------------------------------------------------------*/
s32
CountQuadrantsAtLevel( s32 DimCount, s32 Level )
{
    s32 QuadCount;
    
    // Quads at a level of subdivision.
    QuadCount = PowerOfPowerOf2[DimCount][Level];
        
    // Return the quad count.
    return( QuadCount );
}

/*------------------------------------------------------------
| DeleteSubdivision
|-------------------------------------------------------------
|
| PURPOSE: To discard data produced by 'MakeSubdivision'.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 04.25.96 from 'MakeSubdivision'.
------------------------------------------------------------*/
void
DeleteSubdivision( Subdivision* S )
{
    s32 i;
    
    // Discard the data points.
    DeleteMatrix( S->Pts );
    
    // Discard the axial points.
    DeleteMatrix( S->AxialPts );
    
    // Discard the extents.
    for( i = 0; i < S->QuadrantCount; i++ )
    {
        free( S->Extents[i] );
    }
    free( S->Extents );
    
    // Discard the 'Subdivision' record itself.
    free( S );
}

/*------------------------------------------------------------
| IsIndivisibleQuad
|-------------------------------------------------------------
|
| PURPOSE: To test if a given quadrant in a subdivision is 
|          indivisible. 
|
| DESCRIPTION: This distinguishes intermediate from final
| level quadrants.
|
| Returns '1' if the quadrant is indivisible/final level.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.02.96 
------------------------------------------------------------*/
u32  
IsIndivisibleQuad( Subdivision* S, s32 QuadNumber )
{
    s32 SubQuadNumber;
    
    // Calculate the subquad number.
    SubQuadNumber = 
        ToSubQuadNumber( S->DimCount, QuadNumber, 0 );
        
    // If the subquad falls outside the valid quadrants,
    // then this is an indivisible quadrant.
    if( SubQuadNumber >= S->QuadrantCount )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| MakeMeanSubdivision
|-------------------------------------------------------------
|
| PURPOSE: To organize data points into sections using mean 
|          cuts.
|
| DESCRIPTION: Expects a matrix of points where the number of
| columns is the number of dimensions of the points.  
|
| Also expects a subdivision level number which controls how
| many hierarchical subdivisions are made.
|
| The axial point of the indivisible quadrants is the actual
| point closest to the mean.
|
| EXAMPLE: 
|
| NOTE: See 'Medial.h' for formulas and rules.
|
| ASSUMES: 
|           
| HISTORY: 05.02.96 from 'MakeMedianSubdivision'.
------------------------------------------------------------*/
Subdivision*
MakeMeanSubdivision( Matrix* A, s32 SubdivisionLevel )
{
    Subdivision* M;
    s32         DimCount,QuadNumber,SuperQuadNumber;
    s32         SubQuadsPerQuad,i;
    s32         SubQuadIndex;
    Matrix*     SubQuadrantMatrix;
    f64*        SuperAxialPt;
    Extent*     SuperExtent;
    List*       SubQuadrantPoints;
    
    // Get the number of dimensions of the points.
    DimCount = A->ColCount;
    
    // Allocate a record for this medial section.
    M = (Subdivision*) 
        malloc( sizeof( Subdivision ) + 
                 (DimCount - 1) * sizeof( f64 ) );
    
    // Set the dimension count in the medial section record.
    M->DimCount = DimCount;
    
    // Set the subdivision level in the medial section record.
    M->SubdivisionLevel = SubdivisionLevel;
    
    // Calculate the total number of quadrants.
    M->QuadrantCount = 
        CountCumulativeQuadrants( DimCount, SubdivisionLevel );
    
    // Calculate the number of sub-quadrants per quadrant.
    SubQuadsPerQuad = PowerOf2[DimCount];
    
    // Duplicate the input points and save them as part
    // of this median axis system.
    M->Pts = DuplicateMatrix( A );
    
    // Allocate a matrix to hold the axial points of each
    // quadrant.
    M->AxialPts = MakeMatrix( "", M->QuadrantCount, DimCount );
    
    // Calculate the mean data point for the first quadrant.
    MeanDataPoint( A, (f64*) M->AxialPts->a[0] );
            
    // Allocate the quadrant extents.
    M->Extents = 
        (Extent**) malloc( sizeof( Extent*) * M->QuadrantCount );
    
    for( i = 1; i < M->QuadrantCount; i++ )
    {
        M->Extents[i] = MakeExtent( DimCount, 0, 0 );
    }
    
    // Set the extent for the first quadrant.  Add 'ChopTolerance'
    // to all extents so that all points are included.
    M->Extents[0] = ExtentOfColumns( A );
    
    for( i = 0; i < DimCount; i++ )
    {
        M->Extents[0]->Lo[i] -= ChopTolerance;
        M->Extents[0]->Hi[i] += ChopTolerance;
    }
    
    // For each quadrant following the first one.
    for( QuadNumber = 1; 
         QuadNumber < M->QuadrantCount; 
         QuadNumber++ )
    {
        // Calculate the quadrant that holds this one.
        SuperQuadNumber =
            ToSuperQuadNumber( DimCount, QuadNumber );
            
        // Calculate the sub-quadrant index for this
        // quadrant.
        SubQuadIndex = 
            ToSubQuadIndex( DimCount, QuadNumber );
                
        // Refer to the axial point of the super quad.
        SuperAxialPt = (f64*)
            M->AxialPts->a[SuperQuadNumber];
            
        // Refer to the extent of the super quad.
        SuperExtent = M->Extents[SuperQuadNumber];
            
        // Calculate the subquadrant extent.
        ExtentOfSubQuad( SuperExtent,
                         SuperAxialPt,
                         SubQuadIndex,
                         M->Extents[QuadNumber] );
        
        // Find the points in the subquadrant.
        SubQuadrantPoints = 
            FindPointsWithinExtent( A, M->Extents[QuadNumber] );
        
        // If there are points in the subquadrant.
        if( SubQuadrantPoints->ItemCount )
        {   
            // Make a matrix for the points.
            SubQuadrantMatrix = 
                PointListToMatrix( SubQuadrantPoints );

            // If this is an indivisible quadrant containing 
            // data points, use the maximum density point within 
            // the quadrant as the axial point.
            if( IsIndivisibleQuad( M, QuadNumber ) )
            {
                // Calculate the maximum density data point.
                MeanDataPoint( SubQuadrantMatrix, 
                               (f64*) M->AxialPts->a[QuadNumber] );
            }
            else // Use the mean space point for divisible quadrants.
            {
                // Calculate the medial data point.
                MeanSpacePoint( SubQuadrantMatrix, 
                                (f64*) M->AxialPts->a[QuadNumber] );
            }
            
            // Discard the subquadrant point matrix.
            DeleteMatrix( SubQuadrantMatrix );
        }
        else // No points in the subquadrant.
        {
            // Make the axial point equal to the mean of the
            // extents.
            MidpointOfExtent( M->Extents[QuadNumber],
                          (f64*) M->AxialPts->a[QuadNumber] );
        }
        
        // Discard the point list.
        DeleteList( SubQuadrantPoints );
    }
    
    // Return the mean section record.
    return( M );
}

/*------------------------------------------------------------
| MakeMedianSubdivision
|-------------------------------------------------------------
|
| PURPOSE: To organize data points into sections using medial 
|          cuts.
|
| DESCRIPTION: Expects a matrix of points where the number of
| columns is the number of dimensions of the points.  
|
| Also expects a subdivision level number which controls how
| many hierarchical subdivisions are made.
|
| The axial point of the indivisible quadrants is the median
| for quadrants that contain data points, and the mean for
| quadrants that don't contain data points.
|
| EXAMPLE: 
|
| NOTE: See 'Medial.h' for formulas and rules.
|
| ASSUMES: 
|           
| HISTORY: 04.22.96 
|          05.02.96 added mode axis for indivisible quadrants.
------------------------------------------------------------*/
Subdivision*
MakeMedianSubdivision( Matrix* A, s32 SubdivisionLevel )
{
    Subdivision *M;
    s32         DimCount,QuadNumber,SuperQuadNumber;
    s32         SubQuadsPerQuad,i;
    s32         SubQuadIndex;
    Matrix*     SubQuadrantMatrix;
    f64*        SuperAxialPt;
    Extent*     SuperExtent;
    List*       SubQuadrantPoints;
    
    // Get the number of dimensions of the points.
    DimCount = A->ColCount;
    
    // Allocate a record for this medial section.
    M = (Subdivision*) 
        malloc( sizeof( Subdivision ) + 
                 (DimCount - 1) * sizeof( f64 ) );
    
    // Set the dimension count in the medial section record.
    M->DimCount = DimCount;
    
    // Set the subdivision level in the medial section record.
    M->SubdivisionLevel = SubdivisionLevel;
    
    // Calculate the total number of quadrants.
    M->QuadrantCount = 
        CountCumulativeQuadrants( DimCount, SubdivisionLevel );
    
    // Calculate the number of sub-quadrants per quadrant.
    SubQuadsPerQuad = PowerOf2[DimCount];
    
    // Duplicate the input points and save them as part
    // of this median axis system.
    M->Pts = DuplicateMatrix( A );
    
    // Allocate a matrix to hold the axial points of each
    // quadrant.
    M->AxialPts = MakeMatrix( "", M->QuadrantCount, DimCount );
    
    // Calculate the medial data point for the first quadrant.
    MedianDataPoint( A, (f64*) M->AxialPts->a[0] );
            
    // Allocate the quadrant extents.
    M->Extents = 
        (Extent**) malloc( sizeof( Extent*) * M->QuadrantCount );
    
    for( i = 1; i < M->QuadrantCount; i++ )
    {
        M->Extents[i] = MakeExtent( DimCount, 0, 0 );
    }
    
    // Set the extent for the first quadrant.  Add 'ChopTolerance'
    // to all extents so that all points are included.
    M->Extents[0] = ExtentOfColumns( A );
    
    for( i = 0; i < DimCount; i++ )
    {
        M->Extents[0]->Lo[i] -= ChopTolerance;
        M->Extents[0]->Hi[i] += ChopTolerance;
    }
    
    // For each quadrant following the first one.
    for( QuadNumber = 1; 
         QuadNumber < M->QuadrantCount; 
         QuadNumber++ )
    {
        // Calculate the quadrant that holds this one.
        SuperQuadNumber =
            ToSuperQuadNumber( DimCount, QuadNumber );
            
        // Calculate the sub-quadrant index for this
        // quadrant.
        SubQuadIndex = 
            ToSubQuadIndex( DimCount, QuadNumber );
                
        // Refer to the axial point of the super quad.
        SuperAxialPt = (f64*) 
             M->AxialPts->a[SuperQuadNumber];
            
        // Refer to the extent of the super quad.
        SuperExtent = M->Extents[SuperQuadNumber];
            
        // Calculate the subquadrant extent.
        ExtentOfSubQuad( SuperExtent,
                         SuperAxialPt,
                         SubQuadIndex,
                         M->Extents[QuadNumber] );
        
#ifdef TEST_MEDIAL
        // Verify that the subquad falls in the super quad.
        // DEFER                 
        if( ! IsExtentSubsumed( SuperExtent, M->Extents[QuadNumber] ) )
        {
            Debugger();
        }
#endif // TEST_MEDIAL
        
        // Find the points in the subquadrant.
        SubQuadrantPoints = 
            FindPointsWithinExtent( A, M->Extents[QuadNumber] );
        
        // If there are points in the subquadrant.
        if( SubQuadrantPoints->ItemCount )
        {   
            // Make a matrix for the points.
            SubQuadrantMatrix = 
                PointListToMatrix( SubQuadrantPoints );

            // If this is an indivisible quadrant containing 
            // data points, use the maximum density point within 
            // the quadrant as the axial point.
            if( IsIndivisibleQuad( M, QuadNumber ) )
            {
                // Calculate the maximum density data point.
                ModeDataPoint( SubQuadrantMatrix, 
                               (f64*) M->AxialPts->a[QuadNumber] );
            }
            else // Use the medial point for divisible quadrants.
            {
                // Calculate the medial data point.
                MedianDataPoint( SubQuadrantMatrix, 
                                 (f64*) M->AxialPts->a[QuadNumber] );
            }
            
            // Discard the subquadrant point matrix.
            DeleteMatrix( SubQuadrantMatrix );
        }
        else // No points in the subquadrant.
        {
            // Make the axial point equal to the mean of the
            // extents.
            MidpointOfExtent( M->Extents[QuadNumber],
                              (f64*) M->AxialPts->a[QuadNumber] );
        }
        
        // Discard the point list.
        DeleteList( SubQuadrantPoints );
    }
    
    // Return the medial section record.
    return( M );
}

/*------------------------------------------------------------
| LevelOffsetToQuadNumber
|-------------------------------------------------------------
|
| PURPOSE: To calculate the quadrant number given
|          coordinates in terms of dimension, level,
|          and level-relative quadrant offset.
|
| DESCRIPTION: 
|
| The formula for the quadrant number is:
|
|   Quadrant = QuadsInAllPriorLevels + QuadOffset
|
|                          Level-1
|                           ---- 
|                           \      Dim J
|   QuadsInAllPriorLevels = /    (2   ) 
|                           ----
|                           J=0
|                             
| where 'Dim' ............ number of dimensions, 1 +
|
|       'Level' .......... is the level of subdivision, 0 +
|
|                                                   Dim Level
|       'QuadOffset'...... is a number from 0 to ((2   )     ) - 1.
|
| EXAMPLE:  
|
|   q = LevelOffsetToQuadNumber( 1, 0, 0 );
|
|           Quadrant = 0
|    
|   q = LevelOffsetToQuadNumber( 1, 1, 0 );
|
|           QuadsInAllPriorLevels = 1,
|           QuadOffset = 0,
|
|           Quadrant = 1 + 0 = 1
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.24.96 
------------------------------------------------------------*/
s32
LevelOffsetToQuadNumber( s32 DimCount, 
                         s32 Level,
                         s32 QuadOffset )
{
    s32 QuadsInAllPriorLevels;
    s32 QuadNumber;
    
    // Calculate the cumulative number of quadrants for all
    // prior levels.
    QuadsInAllPriorLevels = 
        CountCumulativeQuadrants( DimCount, Level-1 );
    
    // Calculate the quadrant number.
    QuadNumber = QuadsInAllPriorLevels + QuadOffset;
    
    return( QuadNumber );
}

/*------------------------------------------------------------
| ToSubQuadIndex
|-------------------------------------------------------------
|
| PURPOSE: To calculate the subquad index given a quadrant
|          number and cooresponding subquadrant number.
|
| DESCRIPTION: 
|
| The formula for the sub-quadrant number is:
|
|   SubQuadNumber = SuperQuadOffset % SubQuadsPerQuad
|
| EXAMPLE:  
|
|
| NOTE:  
|
| ASSUMES:
|
| HISTORY:  04.25.96 
------------------------------------------------------------*/
s32
ToSubQuadIndex( s32 DimCount, s32 SubQuadNumber )
{
    s32 SubQuadsPerQuad;
    s32 SubQuadIndex,Level;
    s32 SubQuadOffset;
    
    // Calculate the number of sub-quadrants per quadrant.
    SubQuadsPerQuad = PowerOf2[DimCount]; 
    
    // Convert sub-quadrant number to level and offset.
    QuadrantNumberToLevelOffset( DimCount,
                                 SubQuadNumber, 
                                 &Level,
                                 &SubQuadOffset );
    
    // The subquad index is the quad level offset number
    // modulo the subquads per quad.
    SubQuadIndex = SubQuadOffset % SubQuadsPerQuad;
                   
    // Return the result.              
    return( SubQuadIndex );
}

/*------------------------------------------------------------
| ToSubQuadNumber
|-------------------------------------------------------------
|
| PURPOSE: To calculate the quadrant number of a sub-quadrant
|          within a given quadrant at a given subquad index.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.24.96 
|           04.26.96 Fixed calculation error.
------------------------------------------------------------*/
s32
ToSubQuadNumber( s32 DimCount, 
                 s32 QuadNumber,
                 s32 SubQuadIndex )
{
    s32 QuadsIncludingThisLevel,SubQuadsPerQuad;
    s32 Level, QuadOffset, SubQuadNumber;
    
    // Calculate the number of sub-quadrants per quadrant.
    SubQuadsPerQuad = PowerOf2[DimCount]; 

    // Calculate the level and offset of the quadrant.
    QuadrantNumberToLevelOffset( DimCount,
                                 QuadNumber, 
                                 &Level,
                                 &QuadOffset );
    
    // Calculate the number of quadrants including this level.
    QuadsIncludingThisLevel =
            CountCumulativeQuadrants( DimCount, Level );
    
    // Calculate the subquadrant number.
    SubQuadNumber = QuadsIncludingThisLevel + 
                    QuadOffset * SubQuadsPerQuad +
                    SubQuadIndex;
    
    // Return the result.              
    return( SubQuadNumber );
}

/*------------------------------------------------------------
| ToSuperQuadNumber
|-------------------------------------------------------------
|
| PURPOSE: To calculate the quadrant number of the super-
|          quadrant which contains a given quadrant.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|           q = ToSuperQuadNumber( 1, 0 );
|
| NOTE:  
|
| ASSUMES: The subquadrant is at least level 1.
|
| HISTORY:  04.25.96 
------------------------------------------------------------*/
s32
ToSuperQuadNumber( s32 DimCount, s32 SubQuadNumber )
{
    s32 Level, SuperQuadOffset, SuperQuadNumber;
    s32 SubQuadOffset, SuperLevel;
    s32 SubQuadsPerQuad;

    // Calculate the number of sub-quadrants per quadrant.
    SubQuadsPerQuad = PowerOf2[DimCount]; 
    
    // Calculate the level and offset of the sub-quadrant.
    QuadrantNumberToLevelOffset( DimCount,
                                 SubQuadNumber, 
                                 &Level,
                                 &SubQuadOffset );
    
    // Refer to the level of the super-quadrant. 
    SuperLevel = Level - 1;
    
    // If super level is zero, then quadrant zero is the
    // superquadrant.
    if( SuperLevel == 0 )
    {
        return( 0 );
    }
    
    // Calculate the super-quadrant offset number.
    SuperQuadOffset = SubQuadOffset / SubQuadsPerQuad;
    
    // Calculate the super-quadrant number.
    SuperQuadNumber = 
        LevelOffsetToQuadNumber( DimCount, 
                                 SuperLevel,
                                 SuperQuadOffset );
    // Return the result.              
    return( SuperQuadNumber );
}
        
/*------------------------------------------------------------
| PointToQuadrant
|-------------------------------------------------------------
|
| PURPOSE: To find the number of the quadrant that most 
|          narrowly encloses the given data space point.
|
| DESCRIPTION: Hierarchically decends to the smallest enclosing
| quadrant.
|
| EXAMPLE:  q = PointToQuadrant( M, &APoint[0] );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.22.96 
|           04.26.96 fixed subquad index construction.
------------------------------------------------------------*/
s32
PointToQuadrant( Subdivision* S, f64* P )
{
    s32     SuperQuadNumber,SubQuadNumber;
    s32     DimCount,SubQuadIndex,i;
    u32     Bit;
    s32     LastSuperQuad;
    f64**   M;
    
    M = (f64**) S->AxialPts->a;
    
    // Get the number of dimensions in data space.
    DimCount = S->DimCount;
    
    // Start with the highest level quadrant, 0.
    SuperQuadNumber = 0;
    LastSuperQuad = 0;
        
    // Decend to indivisible quadrants.
Begin:

#ifdef TEST_MEDIAL
    {
    Extent* qEx;
    Extent* qExLast;
    // Verify that the extents nest.
    qExLast = S->Extents[LastSuperQuad];
    qEx     = S->Extents[SuperQuadNumber];
 
    if( ! IsExtentSubsumed( qExLast, qEx ) )
    {
        Debugger();
    }

    // Verify that the point falls in the current extent.
             
    if( IsPointInExtent( qEx, P ) == 0 )
    {
        Debugger(); // DEFER
    }
    }
#endif // TEST_MEDIAL

    // Calculate the sub-quadrant index based on
    // which side of the axial point 'P' is on.
        
    // For each dimension.
    Bit = 1;
    SubQuadIndex = 0;
    for( i = 0; i < DimCount; i++ )
    {
        // If the point is above or equal to the axial point,
        // then it is in segment '1'.
        if( P[i] >= M[SuperQuadNumber][i] )
        {
            // 'OR' in a 1 bit at position cooresponding to
            // the current dimension.
            SubQuadIndex |= Bit;
        }
        
        // Shift bit to the left one bit.
        Bit <<= 1;
    }
        
    // Calculate the subquad number.
    SubQuadNumber = 
        ToSubQuadNumber( DimCount, 
                         SuperQuadNumber, 
                         SubQuadIndex );
        
    // If the subquad falls outside the valid quadrants,
    // then we have found the final, indivisible quadrant.
    if( SubQuadNumber >= S->QuadrantCount )
    {
        return( SuperQuadNumber );
    }
    else // Decend to the next sub-level.
    {
        LastSuperQuad = SuperQuadNumber;
        SuperQuadNumber = SubQuadNumber;
    }
    
    goto Begin;
}
            
/*------------------------------------------------------------
| QuadrantNumberToLevelOffset
|-------------------------------------------------------------
|
| PURPOSE: To convert a quadrant number to level and 
|          and level-relative quadrant offset terms.
|
| DESCRIPTION: 
|
| The formula for the level number is: 
|
|
| The formula for level-relative quadrant offset is:
|
|   QuadOffset = QuadNumber - QuadsInAllPriorLevels
|
|                          Level-1
|                           ---- 
|                           \      Dim J
|   QuadsInAllPriorLevels = /    (2   ) 
|                           ----
|                           J=0
|                             
| where 'Dim' ............ number of dimensions, 1 +
|
|       'Level' .......... is the level of subdivision, 0 +
|
|                                                   Dim Level
|       'QuadOffset'...... is a number from 0 to ((2   )     ) - 1.
|
|       'QuadNumber'...... is a number from 0 to the cumulative
|                          number of all quadrants in the current
|                          system.
|                 
| EXAMPLE:  
|
|   QuadrantNumberToLevelOffset( DimCount, 3, &Level, &Offset );
|
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.24.96 
------------------------------------------------------------*/
void
QuadrantNumberToLevelOffset( s32  DimCount,
                             s32  QuadNumber, 
                             s32* Level,
                             s32* QuadOffset )
{
    s32 QuadsInAllPriorLevels;
    s32 Lvl;
    
    // Calculate the level number.
    // DEFER: there's a faster way to do this.
    Lvl = 0;
    while( LevelOffsetToQuadNumber( DimCount, Lvl, 0 ) <=
           QuadNumber )
    {
        Lvl++;
    }
    
    Lvl--;
    
    // Calculate the cumulative number of quadrants for all
    // prior levels.
    QuadsInAllPriorLevels =  
        CountCumulativeQuadrants( DimCount, Lvl-1);
    
    // Calculate the quad offset.
    *QuadOffset = QuadNumber - QuadsInAllPriorLevels;
    
    // Return the level number.
    *Level = Lvl;
}

/*------------------------------------------------------------
| QuadrantToPoint
|-------------------------------------------------------------
|
| PURPOSE: To find the axial point of a quadrant in a 
|          subdivision.
|
| DESCRIPTION: Returns the address of the axial point. 
|
| EXAMPLE:   
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.26.96 
------------------------------------------------------------*/
f64*
QuadrantToPoint( Subdivision* S, s32 QuadNumber )
{
    return( (f64*) S->AxialPts->a[QuadNumber] );
}

/*------------------------------------------------------------
| SubdivideArray
|-------------------------------------------------------------
|
| PURPOSE: To organize an array into sections by subdividing
|          at the midpoint recursively to a given level of
|          subdivision.
|
| DESCRIPTION: Expects an array that defines the structure to 
| be subdivided.
|
| Also expects a subdivision level number which controls how
| many hierarchical subdivisions are made.
|
| Returns a structure of that lists the extent and axial
| point of each quadrant ordered from coarse to fine.
|
| EXAMPLE: 
|
| NOTE: See 'Medial.h' for formulas and rules.
|
| ASSUMES: 
|           
| HISTORY: 08.07.98 from 'MakeMedianSubdivision'.
------------------------------------------------------------*/
Subdivision*
SubdivideArray( Array* A, s32 SubdivisionLevel )
{
    Subdivision* M;
    s32          DimCount, QuadNumber, SuperQuadNumber;
    s32          SubQuadsPerQuad, i;
    s32          SubQuadIndex;
    f64*         SuperAxialPt;
    Extent*      SuperExtent;
     
    // Get the number of dimensions in the array
    DimCount = A->DimCount;
    
    // Allocate a record for this subdivision.
    M = (Subdivision*) 
        malloc( sizeof( Subdivision ) + 
                 (DimCount - 1) * sizeof( f64 ) );
    
    // Set the dimension count in the record.
    M->DimCount = DimCount;
    
    // Set the subdivision level in the record.
    M->SubdivisionLevel = SubdivisionLevel;
    
    // Calculate the total number of quadrants.
    M->QuadrantCount = 
        CountCumulativeQuadrants( DimCount, SubdivisionLevel );
    
    // Calculate the number of sub-quadrants per quadrant.
    SubQuadsPerQuad = PowerOf2[DimCount];
    
    // There are no data points for this type of subdivision,
    // just an array structure.
    M->Pts = 0;
    
    // Allocate a matrix to hold the axial points of each
    // quadrant.
    M->AxialPts = MakeMatrix( "", M->QuadrantCount, DimCount );
    
    // Allocate the quadrant extents.
    M->Extents = 
        (Extent**) malloc( sizeof( Extent*) * M->QuadrantCount );
    
    for( i = 0; i < M->QuadrantCount; i++ )
    {
        M->Extents[i] = MakeExtent( DimCount, 0, 0 );
    }
    
    // Set the extent for the first quadrant so that the entire
    // array is included. 
    for( i = 0; i < DimCount; i++ )
    {
        M->Extents[0]->Lo[i] = 0.;
        M->Extents[0]->Hi[i] = A->DimExtent[i];
    }
    
    // Refer to the quadrant number of the first quadrant.
    QuadNumber = 0;
    
    // Calculate the axial point of the first quadrant using
    // the midpoint.
    MidpointOfExtent( M->Extents[QuadNumber],
                      (f64*) M->AxialPts->a[QuadNumber] );

    // For each quadrant following the first one.
    for( QuadNumber = 1; 
         QuadNumber < M->QuadrantCount; 
         QuadNumber++ )
    {
        // Calculate the quadrant that holds this one.
        SuperQuadNumber = ToSuperQuadNumber( DimCount, QuadNumber );
            
        // Calculate the sub-quadrant index for this
        // quadrant.
        SubQuadIndex = ToSubQuadIndex( DimCount, QuadNumber );
                
        // Refer to the axial point of the super quad.
        SuperAxialPt = (f64*) M->AxialPts->a[SuperQuadNumber];
            
        // Refer to the extent of the super quad.
        SuperExtent = M->Extents[SuperQuadNumber];
            
        // Calculate the subquadrant extent.
        ExtentOfSubQuad( SuperExtent,
                         SuperAxialPt,
                         SubQuadIndex,
                         M->Extents[QuadNumber] );
        
        // Make the axial point equal to the midpoint of the
        // extent.
        MidpointOfExtent( M->Extents[QuadNumber],
                          (f64*) M->AxialPts->a[QuadNumber] );
    }
    
    // Return the medial section record.
    return( M );
}

/*------------------------------------------------------------
| TestMakeSubdivision
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MakeSubdivision' routine.
|
| DESCRIPTION:  
|
| EXAMPLE:   
|
| NOTE:  
|
| ASSUMES: Graphics and memory management have been set up.
|
| HISTORY:  04.25.96 Tested. 
------------------------------------------------------------*/
void
TestMakeSubdivision()
{
    Subdivision*    S;
    Vector*         P;
    Vector*         MedPts;
    Matrix*         Pm;
    DataSeries*     Med;
    LineGraph*      G;
    s32             L,q;
    Extent*         qEx;
    f64*            qPt;
    f64*            pqp;
    s32             pq;
    
    // Load in a 2D vector.
    P = LoadVector("PriceRateVs20DayEntropyGold");
    
    // Convert the vector to a matrix.
    Pm = VectorToMatrix( P );
    
    for( L = 1; L < 4; L++ )
    {
        // Make a medial subdivision.
        S = MakeMedianSubdivision( Pm, L );
//      S = MakeMeanSubdivision( Pm, L );
    
        // Verify that all axial points fall within the
        // cooresponding quad extents.
        for( q = 0; q < S->QuadrantCount; q++ )
        {
            qEx = S->Extents[q];
            qPt = (f64*) S->AxialPts->a[q];
             
            if( IsPointInExtent( qEx, qPt ) == 0 )
            {
                Debugger();
            }
        }
        
        // Verify that all quadrants can be correctly
        // addressed by their axial points.
        for( q = 0; q < S->QuadrantCount; q++ )
        {
            // Refer to the axial point.
            qPt = (f64*) S->AxialPts->a[q];
            
            // Refer to the extent of the quad.
            qEx = S->Extents[q];
            
            // Find the most intense quadrant holding
            // the axial point.
            pq = PointToQuadrant( S, qPt );
            
            // Find the axial point of the most intense
            // quadrant.
            pqp = QuadrantToPoint( S, pq );
            
            if( IsPointInExtent( qEx, pqp ) == 0 )
            {
                Debugger();
            }
        }

        // Make a graph.
        G = MakeGraph( "PriceRateVs20DayEntropyGold",
                       &DefaultGraphRect );
                   
        // Add the data points to the graph.
        AddPointsToGraph( G, P, &Black );
    
        // Add the axial points as big red points.
        MedPts = MatrixToVector( S->AxialPts );
    
        Med = AddPointsToGraph( G, MedPts, &Red );

        Med->PointRadius = 2.0;

        // Draw the graph.
        DrawGraph(G);
        
        // Report the number of axial points.
        DrawStringOnLine( 20, Line2, 
                          "Axial Pts: %d", 
                          S->AxialPts->RowCount );
    
        // Wait for a button press.
        while(!Button());
        
        // Delete the dynamic data.
        DeleteGraph(G);
        DeleteSubdivision( S );
        free( MedPts );
    }
    
    DeleteMatrix( Pm );
    free( P );
}
