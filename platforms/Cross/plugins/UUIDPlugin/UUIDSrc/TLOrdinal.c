/*------------------------------------------------------------
| TLOrdinal.c
|-------------------------------------------------------------
|
| PURPOSE: To provide ordinal space functions.
|
| HISTORY: 04.29.96
------------------------------------------------------------*/
    
#include <string.h>
#include <stdio.h>
#include "TLTarget.h"

#include "TLTypes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLAscii.h"
#include "TLStrings.h"
#include "TLSubRandom.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLList.h"
#include "TLMatrixAlloc.h"
#include "TLOrdinal.h"

/*------------------------------------------------------------
| FindNearestHiOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To find the nearest ordinal point in a matrix 
|          to a given point, approaching from the high side.
|       
|
| DESCRIPTION: Returns the index of the nearest, higher or
|              equal point.
|
|
|              If there is no nearest high point then returns
|              '-1'.
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
s32
FindNearestHiOrdinalPoint( Matrix* M, f64* P )
{
    s32         DimCount, PtCount, i, Nearest;
    f64**       m;
    u32         IsNearest;
    
    DimCount = M->ColCount;
    PtCount  = M->RowCount;
    
    m = (f64**) M->a;
    
    Nearest = 0;
    IsNearest = 0;
    
    for( i = 0; i < PtCount; i++ )
    {
        if( IsNearerHiOrdinalPoint( DimCount, 
                                    P,
                                    m[i], 
                                    m[Nearest] ) )
        {
            Nearest = i;
            IsNearest = 1;
        }
    }
    
    if( IsNearest )
    {
        return( Nearest );
    }
    else
    {
        return( -1 );
    }
}

/*------------------------------------------------------------
| FindNearestLoOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To find the nearest ordinal point in a matrix 
|          to a given point, approaching from the low side.
|       
|
| DESCRIPTION: Returns the index of the nearest, lower or
|              equal point.
|
|              If there is no nearest low point then returns
|              '-1'.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
s32
FindNearestLoOrdinalPoint( Matrix* M, f64* P )
{
    s32         DimCount, PtCount, i, Nearest;
    f64**       m;
    u32         IsNearest;
    
    DimCount = M->ColCount;
    PtCount  = M->RowCount;
    
    m = (f64**) M->a;
    
    Nearest = 0;
    IsNearest = 0;
    for( i = 0; i < PtCount; i++ )
    {
        if( IsNearerLoOrdinalPoint( DimCount, 
                                    P,
                                    m[i], 
                                    m[Nearest] ) )
        {
            Nearest = i;
            IsNearest = 1;
        }
    }
    
    if( IsNearest )
    {
        return( Nearest );
    }
    else
    {
        return( -1 );
    }
}


/*------------------------------------------------------------
| FindNearestOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To find the nearest ordinal point in a matrix 
|          to a given point.
|       
|
| DESCRIPTION: Returns the index of the nearest point.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
s32
FindNearestOrdinalPoint( Matrix* M, f64* P )
{
    s32         DimCount, PtCount, i, Nearest;
    f64**       m;
    
    DimCount = M->ColCount;
    PtCount  = M->RowCount;
    
    m = (f64**) M->a;
    
    Nearest = 0;
    
    for( i = 1; i < PtCount; i++ )
    {
        if( IsNearerOrdinalPoint( DimCount, 
                                  P,
                                  m[i], 
                                  m[Nearest] ) )
        {
            Nearest = i;
        }
    }
    
    return( Nearest );
}

/*------------------------------------------------------------
| IsNearerHiOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To test if a point is nearer to a point than
|          another point, approaching it from the high side, 
|          treating each dimension independently.
|
| DESCRIPTION: Returns '1' if point 'A' is not farther from
| than point 'X' than point 'B' in any of it's dimensions
| compared separately AND 'A' is closer to 'X' than 'B' is
| in at least one dimension AND 'A' is greater than or equal
| to 'X' in all dimensions.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
u32  
IsNearerHiOrdinalPoint( s32 DimCount, 
                        f64* X, f64* A, f64* B )
{
    u32     IsNearer;
    
    // Test that 'A' isn't farther from 'X' than 'B' in
    // any dimension.
    IsNearer = IsNearerOrdinalPoint( DimCount, X, A, B );
    
    // If not nearer, then return false.
    if( IsNearer == 0 ) 
    {
        return( 0 );
    }
    
    return( IsMoreOrEqualOrdinalPoint( DimCount, X, A ) );
}


/*------------------------------------------------------------
| IsNearerLoOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To test if a point is nearer to a point than
|          another point, approaching it from the low side, 
|          treating each dimension independently.
|
| DESCRIPTION: Returns '1' if point 'A' is not farther from
| than point 'X' than point 'B' in any of it's dimensions
| compared separately AND 'A' is closer to 'X' than 'B' is
| in at least one dimension AND 'A' is not greater than 'X' 
| in any dimension.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
u32  
IsNearerLoOrdinalPoint( s32 DimCount, 
                        f64* X, f64* A, f64* B )
{
    u32     IsNearer;
    
    // Test that 'A' isn't farther from 'X' than 'B' in
    // any dimension.
    IsNearer = IsNearerOrdinalPoint( DimCount, X, A, B );
    
    // If not nearer, then return false.
    if( IsNearer == 0 ) 
    {
        return( 0 );
    }
    
    return( IsLessOrEqualOrdinalPoint( DimCount, X, A ) );
}

/*------------------------------------------------------------
| IsLessOrEqualOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To test if a point is not greater than another
|          in any dimension.
|
| DESCRIPTION: Returns '1' if point 'A' is not more 
| than point 'X' in any of it's dimensions.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
u32  
IsLessOrEqualOrdinalPoint( s32 DimCount, f64* X, f64* A )
{
    f64 a,x;
    s32     i;
    
    // Check that 'A' not greater than 'X' in any
    // dimension.
    for( i = 0; i < DimCount; i++ )
    {
        x = *X++;
        a = *A++;
        
        if( a > x )
        {
            return( 0 );
        }
    }
    return( 1 );
}

/*------------------------------------------------------------
| IsMoreOrEqualOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To test if a point is not less than another
|          in any dimension.
|
| DESCRIPTION: Returns '1' if point 'A' is not less 
| than point 'X' in any of it's dimensions.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
u32  
IsMoreOrEqualOrdinalPoint( s32 DimCount, f64* X, f64* A )
{
    f64 a,x;
    s32     i;

    // Check that 'A' not greater than 'X' in any
    // dimension.
    for( i = 0; i < DimCount; i++ )
    {
        x = *X++;
        a = *A++;
        
        if( a < x )
        {
            return( 0 );
        }
    }
    return( 1 );
}


/*------------------------------------------------------------
| IsNearerOrdinalPoint
|-------------------------------------------------------------
|
| PURPOSE: To test if a point is nearer to a point than
|          another point, treating each dimension 
|          independently.
|
| DESCRIPTION: Returns '1' if point 'A' is not farther from
| than point 'X' than point 'B' in any of it's dimensions
| compared separately AND 'A' is closer to 'X' than 'B' is
| in at least one dimension. 
|
| Some but not all dimensions can be the same distance.
|
| RULE: If 'A' is not farther from 'X' in any dimension than
|       'B' is and 'A' is closer in at least one dimension, 
|       then 'A' is nearer.
|
| All comparisons are made subject to the chop tolerance.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.29.96 
------------------------------------------------------------*/
u32  
IsNearerOrdinalPoint( s32 DimCount, f64* X, f64* A, f64* B )
{
    s32     i;
    f64     a, b, x, adif, bdif;
    u32     IsNearer;
    
    // Test that 'A' isn't farther from 'X' than 'B' in
    // any dimension.
    IsNearer = 0;
    
    for( i = 0; i < DimCount; i++ )
    {
        x = *X++;
        a = *A++;
        b = *B++;
        
        adif = ( x > a ) ? x - a : a - x;
        bdif = ( x > b ) ? x - b : b - x;
        
        // If 'A' is farther in any dimension then it
        // isn't nearer.
        if( adif > bdif )
        {
            return( 0 );
        }
        else // less or equal
        {
            // Nearer in at least one dimension.
            if( adif < bdif )
            {
                IsNearer = 1;
            }
        }
    }
    
    return( IsNearer );
}
