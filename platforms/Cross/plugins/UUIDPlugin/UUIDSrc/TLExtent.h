/*------------------------------------------------------------
| TLExtent.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to extent functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 03.07.96
------------------------------------------------------------*/

#ifndef _EXTENT_H_
#define _EXTENT_H_

#ifdef __cplusplus
extern "C"
{
#endif

// Type definitions and forward references to the structures 
// defined below.
typedef struct LoHi     LoHi;
typedef struct Extent   Extent;
 
/*************************************************************/
/*                   E X T E N T   R E C O R D               */
/*************************************************************/
//
// This record is used to refer to an orthagonal section of
// a space.  
//
// An extent is an n-dimensional generalization of a line
// segment.  
//
// It is specified by giving the min and max end points.
//
// These records are dynamically allocated, or prefixed to
// the beginning of a larger structure, with data for the
// endpoints appended to this record.
//
// When used as a space indicator, the assumption is that the
// reference is to the points inside the extent.
// 
// A point is inside an extent if it is greater than or 
// equal to the 'Lo' point in all dimensions and less than
// the 'Hi' point in all dimensions.
//
struct Extent
{
    u32     DimCount;   // A count of the number of dimensions
                        // in the vectors.
                        //
    f64*    Lo;         // Point defining the lower extreme:
                        // the smallest point inside the 
                        // extent.
                        //
    f64*    Hi;         // Point defining the upper extreme:
                        // the smallest point outside the 
                        // extent.
                        //
    // The end point data is stored here.
};

/*------------------------------------------------------------
| LoHi 
|-------------------------------------------------------------
|
| PURPOSE: To define a one-dimensional 64-bit extent 
|          specification.
|
| DESCRIPTION:  
|
| ASSUMES: Hi >= Lo
|
| HISTORY: 06.21.00 
------------------------------------------------------------*/
struct LoHi
{
    u64 Lo; // The low end of the extent, the address of the 
            // first item in that range.
            //
    u64 Hi; // The high end of the extent, the address of the 
            // first item beyond the end of the range.
};

void        AddToExtent( Array*, Extent*, f64 );
void        CopyExtent( Extent*, Extent* );
void        CopyExtentToBuffer( Array*, Extent*, f64* );
void        CopyExtentToByteBuffer( Array*, Extent*, u8* );
u32         CountCellsInExtent( Extent* );
u32         CountExtentIntersections( List*, List* );
List*       DeductExtent( Extent*, Extent* );
Extent*     DuplicateExtent( Extent* );
List*       DuplicateExtents( List* );
Extent*     ExtentOfColumns( Matrix* );
void        ExtentOfSubQuad( Extent*, f64*, s32, Extent* );
f64*        ExtentToVector( Array*, Extent* );
void        FillBitExtent( Array*, u32*, u32*, u32 ); 
void        FillExtent( Array*, Extent*, f64 );
Item*       FindIntersectingExtent( List*, Extent* );
List*       FindItemsWithinExtent( Extent*, f64*, s32 );
void        FindMaxCellInExtent( Array*, Extent*, u32* );
List*       FindPointsWithinExtent( Matrix*, Extent* );
Extent*     IntersectExtent( Extent*, Extent* );
List*       IntersectExtents( List*, List* );
u32         IsCellInExtent( Extent*, u32* );
u32         IsIntersectingExtents( Extent*, Extent* );
u32         IsExtentEmpty( Extent* );
u32         IsExtentInArray( Array*, Extent* );
u32         IsExtentLarger( Extent*, Extent* );
u32         IsExtentsEmpty( List* );
u32         IsExtentSmaller( Extent*, Extent* );
u32         IsExtentSubsumed( Extent*, Extent* );
u32         IsPartialPointInExtent( Extent*, f64*, s32* );
u32         IsPointInExtent( Extent*, f64* );
u32         IsPointsInExtent( List*, Extent* );
Extent*     MakeExtent( u32, f64*, f64* );
u32         MarkIntersectingExtents( List*, List* );
u32         MarkPointsOutsideExtent( List*, Extent* );
u32         MarkPointsWithinExtent( List*, Extent* );
u32         MarkSubsumedExtents( List*, List* );
f64         MeanOfExtent( Array*, Extent* );
f64         MedianOfExtent( Array*, Extent* );
List*       MergeIntersectingExtents( List*, List* ); 
void        MidpointOfExtent( Extent*, f64* );
void        MultiplyToExtent( Array*, Extent*, f64 );
f64         SumOfExtent( Array*, Extent* );
f64         SumOf4DIntegerExtent( Array*, Extent* );
f64         SumOfIntegerExtent( Array*, Extent* );
f64*        ToFirstCellInExtent( Array*, Extent* );
f64*        ToNextCellInExtent( Array*, Extent* );
List*       UniteExtents( List*, List* );
void        ValidateExtentInArray( Array*, Extent* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _EXTENT_H_
