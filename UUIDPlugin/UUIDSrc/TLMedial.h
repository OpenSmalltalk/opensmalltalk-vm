/*------------------------------------------------------------
| FILE NAME: Medial.h
|
| PURPOSE: To provide interface to medial classification
|          functions.
|
| DESCRIPTION: 
|        
| Definitions:
|
| 'data space'........ the coordinate system used to express
|                      the input points.
|
| 'quadrant'.......... a part of data space delimited by 
|                      minimum and maximum values in each
|                      dimension, such that a point is included
|                      in the range if it is greater than or
|                      equal to the minimums and less than the 
|                      maximums.
|
| 'extent'............ a specification of minimums and maximums
|                      for each dimension.  This is the form of
|                      a quadrant definition.
|
| 'medial point'...... a point computed to subdivide a set of 
|                      points into equal density parts.  Each 
|                      dimension is treated independently of 
|                      the others.  The medial point may not 
|                      be an actual point in the given set, 
|                      but is rather an axial point used 
|                      to subdivide the given points into 
|                      quadrants.
|
| QUADRANT ORGANIZATION:
|
| 1. Quadrants are identified by a number which ranges from 
|    zero to one less than the 'QuadrantCount' in the 
|    'Subdivision' record.
|
| 2. All quadrants at a level of subdivision are contiguous
|    in the quadrant number space.
|
| 3. Quadrants at a higher level of subdivision follow those
|    at a lower level of subdivision.
|
| 4. If a quadrant is subdivided, it is split into 2^DimCount
|    subquadrants which have a level number one greater than
|    the quadrant.
|
| 5. Subquadrants within a quadrant are indexed by a
|    SubQuadrant Index Number.
|
| SUBQUADRANT INDEX NUMBERING RULES:
|
| 1.  Within each SubQuadrant Index the dimensions 
|     are organized such that the least significant bit
|     corresponds with dimension 0, the next bit with
|     dimension 1 and so on.
|
|      SubQuadrant Index
|     --------------------      
|     |     .... 0 1 0 0 |
|     --------------------
|         n .... 3 2 1 0  <-- Dimension cooresponds to bit.
|
| 2. Each bit tells which side of the axial point of the 
|    quadrant that the sub-quadrant falls on.
|
|    A '0' bit means that the part below the axial point 
|    for that dimension is indicated; a '1' bit means that 
|    the part is above or equal to the axial point,'X'.
|
|                    '1'           '0'
|                     111111000000000      
|                     |----X--------|  
|                    Max           Min  
| FORMULAS:
|
| NUMBER OF QUADRANTS AT A LEVEL OF SUBDIVISION:
|
|                       D L
|     QuadrantCount = (2 )  
|
|     where 'D' ....... number of dimensions, 1 or higher.
|
|           'L' ....... is the level of subdivision, 0 or higher.
|
|     So, suppose you have a set of 2-dimensional points 
|     that you want to subdivide into 100 quadrants, what
|     level number should be used?
|
|     Solving for L:
|
|               ln( QuadrantCount )
|         L = ---------------------- 
|                 D * ln(2)
|
|               ln( 100 )
|         L = ------------- 
|               2 * ln(2)
|
|         L = 3.32..
| 
|     But since 'L' has to be an integer, you must choose
|     between 'L' = 3 or 4:
|                       
|                       2 3
|     QuadrantCount = (2 )  = 64 
|     
|                       2 4
|     QuadrantCount = (2 )  = 256 
|
| CUMULATIVE NUMBER OF QUADRANTS TO A LEVEL OF SUBDIVISION:
|
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
|     So, suppose you have a set of 2-dimensional points 
|     that you want to subdivide into 64 final quadrants, 
|     how many total quadrants are there?
|     From above we have the subdivision level value of 3.
|
|                      D 0    D 1    D 2     D 3
|     CumQuadrants = (2 ) + (2 ) + (2 )  + (2 )
|
|                        2 0     2 1     2 2     2 3
|                    = (2 )  + (2 )  + (2 )  + (2 )
|
|                    = 1 + 4 + 16 + 64 = 85
|
|
| NOTE: 
|
| HISTORY: 04.23.96 
------------------------------------------------------------*/

#ifndef _MEDIAL_H_
#define _MEDIAL_H_

    
/*************************************************************/
/*           M E D I A N   A X I S   R E C O R D             */
/*************************************************************/
//
// This organizes points into hierarchy of quadrants defined 
// by axes centered on axial points.
// 
typedef struct 
{
    s32      DimCount;  // The number of dimensions for each
                        // point.
                        //
    s32      SubdivisionLevel;
                        // The number that controls the nesting
                        // of axes within quadrants, 0 +.
                        //
    s32      QuadrantCount; 
                        // The cumulative number of quadrants
                        // in this system.
                        //
    Matrix*  Pts;       // The data space points. 
                        //
    Matrix*  AxialPts;  // Each row holds the median/axial  
                        // point for a quadrant.  The axial
                        // point subdivides the quadrant 
                        // into 2^DimCount subquadrants.
                        //
    Extent** Extents;   // Extents of each quadrant.
} Subdivision;

s32             CountCumulativeQuadrants( s32, s32 );
s32             CountQuadrantsAtLevel( s32, s32 );
void            DeleteSubdivision( Subdivision* );
u32             IsIndivisibleQuad( Subdivision*, s32 );
s32             LevelOffsetToQuadNumber( s32, s32, s32 );
Subdivision*    MakeMeanSubdivision( Matrix*, s32 );
Subdivision*    MakeMedianSubdivision( Matrix*, s32 );
s32             PointToQuadrant( Subdivision*, f64* );
void            QuadrantNumberToLevelOffset( s32, s32, s32*, s32* );
f64*            QuadrantToPoint( Subdivision*, s32 );
Subdivision*    SubdivideArray( Array*, s32 );
void            TestMakeSubdivision();
s32             ToSubQuadIndex( s32, s32 );
s32             ToSubQuadNumber( s32, s32, s32 );
s32             ToSuperQuadNumber( s32, s32 );

//void      QuadrantToExtent( Subdivision*, s32, Extent* );

#endif // _MEDIAL_H_
