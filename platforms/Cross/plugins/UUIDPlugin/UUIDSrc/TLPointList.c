/*------------------------------------------------------------
| TLPointList.c
|-------------------------------------------------------------
|
| PURPOSE: To provide data point list functions.
|
| HISTORY: 05.02.96
------------------------------------------------------------*/

#include "TLTarget.h"   // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"  
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLListIO.h"
#include "TLStacks.h"
#include "TLParse.h"  // for 'ParseDatum'
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLf64.h"
#include "TLNumber.h" // for 'ConvertStringToNumber'
                    // and 'ConvertNumberToString'
#include "TLDate.h" 
#include "TLItems.h"
#include "TLVector.h"
#include "TLMatrixAlloc.h"
#include "TLArray.h"
#include "TLPoints.h"
#include "TLGeometry.h"
#include "TLSubRandom.h"
#include "TLWeight.h"
#include "TLStat.h"

#include "TLPointList.h"

/*------------------------------------------------------------
| DeleteDuplicateDataPoints
|-------------------------------------------------------------
|
| PURPOSE: To delete extra adjacent data points that have the
|          same content, within the chop tolerance.
|
| DESCRIPTION: Given a list sorted by 'SortListAsBinaryData',
| this procedure deletes all extra items that refer to
| records that contain the same content.
|
| The content of an item is addressed by the 'DataAddress'
| field for 'SizeOfData' bytes.
|
| EXAMPLE:  DeleteDuplicateDataPoints( AList );
|
| NOTE: 
|
| ASSUMES: The 'SizeOfData' field of each 'Item' is valid.
|          The data points themselves are not owned by the
|          list and will be deleted by other means.
|
| HISTORY: 01.07.97 from 'DeleteDuplicateContentReferences'.
------------------------------------------------------------*/
void
DeleteDuplicateDataPoints( List* AList )
{
    u8* PriorDataAddress;
    u32 PriorDataSize;
    u32 DimCount;
    
    ReferToList( AList ); 
    
    while( TheItem )
    {
        if( IsItemFirst( TheItem ) == 0 )
        {
            if( TheDataSize == PriorDataSize )
            {
                DimCount = PriorDataSize / sizeof(f64);
                
                if( IsDataPointsEqual( 
                        (f64*) TheDataAddress, 
                        (f64*) PriorDataAddress, 
                        DimCount ) )
                {
                    MarkItem(TheItem);
                }
            }
        }
        
        PriorDataAddress = TheDataAddress;
        PriorDataSize    = TheDataSize;
        
        ToNextItem();
    }
    
    RevertToList();
    
    DeleteMarkedItems(AList);
}

/*------------------------------------------------------------
| DimensionOfPointList
|-------------------------------------------------------------
|
| PURPOSE: To get the dimension count of a point list.
|
| DESCRIPTION: The 'SizeOfData' field holds the number of 
| bytes in the point, that is, the number of dimensions of 
| each point times the size of an f64.
|
| EXAMPLE:  d = DimensionOfPointList( L );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.02.96
|          12.19.96 changed the content of the 'SizeOfData'
|                   field from dimension count to byte count
|                   of the data point.
------------------------------------------------------------*/
u32
DimensionOfPointList( List* P )
{
    // If there are points in the list.
    if( P->ItemCount )
    {
        return( P->FirstItem->SizeOfData / sizeof(f64) );
    }
    else // No items, no dimensions.
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| DuplicateDataPoint
|-------------------------------------------------------------
|
| PURPOSE: To make a dynamic copy of a data point record.
|
| DESCRIPTION: 
|
| EXAMPLE: d = DuplicateDataPoint( AtPt, n );
|
| NOTE: 
|
| ASSUMES: Will be freed using 'free'.
|           
| HISTORY: 12.31.96 from 'DuplicateItems'.
------------------------------------------------------------*/
f64*
DuplicateDataPoint( f64* A, u32 DimCount )
{
    f64*    B;
    u32     ByteCount;
    
    // Calculate the size of the overall buffer.
    ByteCount = DimCount * sizeof(f64);
    
    // Allocate the new buffer.
    B = (f64*) malloc( ByteCount );
    
    // Copy the data.
    CopyBytes( (u8*) A, (u8*) B, ByteCount );

    // Return the buffer.
    return( B );
}

/*------------------------------------------------------------
| IsDataPointsEqual
|-------------------------------------------------------------
|
| PURPOSE: To test if two data points are equal within the
|          chop tolerance.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.07.97
------------------------------------------------------------*/
u32  
IsDataPointsEqual( f64* A, f64* B, u32 DimCount )
{
    u32 i;
    
    for( i = 0; i < DimCount; i++ )
    {
        if( Eq( A[i], B[i] ) == 0 )
        {
            return( 0 );
        }
    }
    
    return( 1 );
}

/*------------------------------------------------------------
| MatrixToPointList
|-------------------------------------------------------------
|
| PURPOSE: To make a point list that refers to points in a
|          matrix.
|
| DESCRIPTION: Each row is devoted to holding the coordinates
| of a single point.  Each item in the list refers to a row
| in the matrix.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.02.96 from 'PointListToMatrix'.
------------------------------------------------------------*/
List*
MatrixToPointList( Matrix* M )
{
    List*   L;
    u32     i;
    u32     DimCount, PtCount;
    f64**   a;
    
    // Get the dimension count from the columns in the matrix.
    DimCount = M->ColCount;
    PtCount  = M->RowCount;
    
    a = (f64**) M->a;
    
    // Make a list for the points.
    L = MakeList();
    
    // For each point.
    for( i = 0; i < PtCount; i++ )
    {
        InsertPointLastInList( L, a[i], DimCount );
    }
    
    // Return the list.
    return( L );
}

/*------------------------------------------------------------
| PointListToItems
|-------------------------------------------------------------
|
| PURPOSE: To make a dynamic number buffer from a list of 
|          points.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.02.96 from 'PointListToMatrix'
------------------------------------------------------------*/
f64*
PointListToItems( List* P )
{
    f64*    A;
    u32     BytesPerPoint, i, DimCount;
    
    // Get the dimension count from the list.
    DimCount = DimensionOfPointList( P );
    
    // Make a buffer for the points.
    A = MakeItems( P->ItemCount * DimCount, 0 );
    
    // Calculate how many bytes are occupied by each point.
    BytesPerPoint = sizeof(f64) * DimCount;
            
    // Copy the points to the new matrix.
    ReferToList( P );
    
    i = 0;
    
    while( TheItem )
    {
        memcpy( (void*) &A[i],
                (void*) TheDataAddress, 
                BytesPerPoint );
                
        ToNextItem();
        i += DimCount;
    }
    
    RevertToList();
    
    // Return the buffer.
    return( A );
}

/*------------------------------------------------------------
| PointListToMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a matrix from a list of points.
|
| DESCRIPTION: Each row is devoted to holding the coordinates
| of a single point.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.22.96
------------------------------------------------------------*/
Matrix*
PointListToMatrix( List* P )
{
    Matrix* M;
    u32     BytesPerPoint, DimCount;
    f64*    AtRow;
    
    // Get the dimension count from the list.
    DimCount = DimensionOfPointList( P );
    
    // Make a matrix for the points.
    M = MakeMatrix( (s8*) "", P->ItemCount, DimCount );
    
    // Calculate how many bytes are occupied by each point.
    BytesPerPoint = sizeof(f64) * DimCount;
            
    // Copy the points to the new matrix.
    ReferToList( P );
    
    // Refer to the first cell of the first row of the matrix.
    AtRow = AtCell( M, 
                    M->LoRowIndex,
                    M->LoColIndex );
    
    while( TheItem )
    {
        // Copy the data point to the matrix row.
        memcpy( AtRow, TheDataAddress, BytesPerPoint );
                
        ToNextItem();
    }
    
    RevertToList();
    
    // Return the matrix.
    return( M );
}

/*------------------------------------------------------------
| InsertPointLastInList
|-------------------------------------------------------------
|
| PURPOSE: To append a data point reference to a list.
|
| DESCRIPTION: Doesn't duplicate the data point, just adds
| the reference to a list.
|
| The 'SizeOfData' field holds the number of bytes in the
| point, that is, the number of dimensions of each point 
| times the size of an f64.
|
| EXAMPLE:  InsertPointLastInList( L, Pt, DimCount );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.02.96
|          12.19.96 changed the content of the 'SizeOfData'
|                   field from dimension count to byte count
|                   of the data point.
------------------------------------------------------------*/
void
InsertPointLastInList( List* L, f64* Pt, u32 DimCount )
{
    InsertDataLastInList( L, (u8*) Pt );
    
    L->LastItem->SizeOfData   = DimCount * sizeof(f64);
    L->LastItem->SizeOfBuffer = L->LastItem->SizeOfData;
}
