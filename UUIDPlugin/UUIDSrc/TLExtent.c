/*------------------------------------------------------------
| TLExtent.c
|-------------------------------------------------------------
|
| PURPOSE: To provide extent functions.
|
| DESCRIPTION:  An extent is an n-dimensional generalization
| of a rectangle [simplex?].
|        
| NOTE: 
|
| HISTORY: 03.07.96
|          04.23.96 Generalized from integral to floating
|                   point. Name changed from 'orthogon' to
|                   'extent'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>

#include "TLTypes.h"
#include "TLBit.h"
#include "TLBytes.h"
#include "TLf64.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLList.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLArray.h"
#include "TLPoints.h"
#include "TLPointList.h"
#include "TLGeometry.h"
#include "TLWeight.h"
#include "TLStat.h"

#include "TLExtent.h"

/*------------------------------------------------------------
| AddToExtent
|-------------------------------------------------------------
|
| PURPOSE: To add a value to each cell in an orthogonal region
|          of an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: Add .001 to an extent of a four dimensional array 
| with dimensions 3 x 5 x 6 x 8.  The 
| extent cells range from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32      DimExtent[4];
|      s32      Lo[4];
|      s32      Hi[4];
|      Array*   A;
|      Extent*  E;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      Lo[0] = 1;
|      Lo[1] = 2;
|      Lo[2] = 3;
|      Lo[3] = 4;
|
|      Hi[0] = 3; // Upper bound is one larger than the 
|      Hi[1] = 4; // address of the last cell in the extent.
|      Hi[2] = 5;
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
| 
|      AddToExtent( A, E, .001 );
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|           
| HISTORY: 03.06.96 from 'FillSection'. 
|          06.12.96 made 'Index[]' local rather than
|                   dynamically allocated.
------------------------------------------------------------*/
void
AddToExtent( Array* A, Extent* E, f64 v )
{
    f64*    ACell;
    u32     DimCount, d, LastDim, CellOffset;
    u32     Index[MaxArrayDimensions];  

#ifdef ARRAY_ERROR_CHECKING
    ValidateExtentInArray( A, E );
#endif
    
    // Get the number of dimensions.
    DimCount = A->DimCount;
        
    // For each dimension set the index to the start of
    // the orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
    }
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
DoCurrentCell:  // Set the value of the current cell.
    
    // For each dimension.
    CellOffset = 0;
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[d] * Index[d];
    }
    
    // Add the offset of the last dimension.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = &A->Data[CellOffset];

NextCell:
    
    // Add to the cell value.
    *ACell += v;
    
    // Advance to next cell.
    ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < (u32) E->Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds
        // then we are done.
        if( Index[0] == (u32) E->Hi[0] )
        {
            goto Done;
        }
    }
    
    goto DoCurrentCell;

Done:
    return;
}   

/*------------------------------------------------------------
| CopyExtentToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To copy the extent of an array to a buffer.
|
| DESCRIPTION: Expects a destination buffer and an extent 
| record specifying the bounds of the region in the array. 
| The 'Lo' bound is the first cell to be included in the 
| region and the 'Hi' bound is one larger than the last cell 
| to be included in the region.
|
| EXAMPLE: Copy the values in an extent of a four 
| dimensional array with dimensions 3 x 5 x 6 x 8.  
| 
| The extent cells range from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32      DimExtent[4];
|      s32      Lo[4];
|      s32      Hi[4];
|      Array*   A;
|      Extent*  E;
|      f64* T;
|      s32      CellCount;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      Lo[0] = 1;
|      Lo[1] = 2;
|      Lo[2] = 3;
|      Lo[3] = 4;
|
|      Hi[0] = 3; // Upper bound is one larger than the 
|      Hi[1] = 4; // address of the last cell in the extent.
|      Hi[2] = 5;
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
|
|      T = MakeItems( CountCellsInExtent( E ), 0 );
| 
|      CopyExtentToBuffer( A, E, T );
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|
|          Working buffer is big enough.
|           
| HISTORY: 08.05.98 from 'SumOfExtent'.
|           
------------------------------------------------------------*/
void
CopyExtentToBuffer( Array* A, Extent* E, f64* B )
{
    f64*    ACell;
    u32     DimCount, d, LastDim, CellOffset;
    u32     Index[MaxArrayDimensions];  
    
    // Get the number of dimensions.
    DimCount = A->DimCount;
        
    // For each dimension set the index to the start of
    // the orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
    }
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
DoCurrentCell:  // Move the current cell to the buffer.
    
    // For each dimension.
    CellOffset = 0;
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[d] * Index[d];
    }
    
    // Add the offset of the last dimension.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = &A->Data[CellOffset];

NextCell:
    
    // Copy the cell value to the buffer.
    *B++ = *ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < (u32) E->Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds
        // then we are done.
        if( Index[0] == (u32) E->Hi[0] )
        {
            return;
        }
    }
    
    goto DoCurrentCell;
}   

/*------------------------------------------------------------
| CopyExtentToByteBuffer
|-------------------------------------------------------------
|
| PURPOSE: To copy the extent of an array to a byte buffer.
|
| DESCRIPTION: Expects a destination buffer and an extent 
| record specifying the bounds of the region in the array. 
| The 'Lo' bound is the first cell to be included in the 
| region and the 'Hi' bound is one larger than the last cell 
| to be included in the region.
|
| EXAMPLE: See 'CopyExtentToBuffer'.
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|
|          Working buffer is big enough.
|           
| HISTORY: 08.07.98 from 'CopyExtentToBuffer'.
------------------------------------------------------------*/
void
CopyExtentToByteBuffer( Array* A, Extent* E, u8* B )
{
    f64*    ACell;
    u32     DimCount, d, LastDim, CellOffset;
    u32     Index[MaxArrayDimensions];  
    
    // Get the number of dimensions.
    DimCount = A->DimCount;
        
    // For each dimension set the index to the start of
    // the orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
    }
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
DoCurrentCell:  // Move the current cell to the buffer.
    
    // For each dimension.
    CellOffset = 0;
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[d] * Index[d];
    }
    
    // Add the offset of the last dimension.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = &A->Data[CellOffset];

NextCell:
    
    // Copy the cell value to the buffer as a byte.
    *B++ = (u8) *ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < (u32) E->Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds
        // then we are done.
        if( Index[0] == (u32) E->Hi[0] )
        {
            return;
        }
    }
    
    goto DoCurrentCell;
}   

/*------------------------------------------------------------
| CountCellsInExtent
|-------------------------------------------------------------
|
| PURPOSE: To count the number of cells in an extent.
|
| DESCRIPTION: Expects an extent specifying the bounds
| of the cell space. The 'Lo' bound is the first
| cell to be included in the extent and the 'Hi' bound is one
| larger than the last cell to be included in the extent.
|
| EXAMPLE: 
|
|     c = CountCellsInExtent( E );
|
| NOTE: 
|
| ASSUMES: Extent may be empty.
|           
| HISTORY: 03.07.96 from 'CountCellsInSection'. 
------------------------------------------------------------*/
u32
CountCellsInExtent( Extent* E )
{
    u32 DimCount, d;
    u32 CellCount;
    
    // Get the number of dimensions.
    DimCount = E->DimCount;
    
    CellCount = 1;
    
    // For each dimension.
    for( d = 0; d < DimCount; d++ )
    {   
        // Check for an empty segment.
        if( E->Lo[d] >= E->Hi[d] )
        {
            return( 0 );
        }
        else
        {
            // Accumulate the cells.
            CellCount *= (u32) E->Hi[d] - 
                         (u32) E->Lo[d];
        }
    }
    
    return( CellCount );
}

/*------------------------------------------------------------
| CountExtentIntersections
|-------------------------------------------------------------
|
| PURPOSE: To count how many extents in a list intersect
|          with each extent in another list.
|
| DESCRIPTION: Given two lists of extents, compare each with
| each extent to determine if extents intersect some
| other extents in the other list.  
|
| Count the intersections  and return the count in the 
| 'SizeOfData' field of each item.
|
| Return a total count of the intersections.
|
| EXAMPLE:  c = CountExtentIntersections( A, B );
|
| NOTE: 
|
| ASSUMES: The given lists each contain disjoint extents.
|          OK to change the 'SizeOfData' fields in the items
|          in the given lists.
|           
| HISTORY: 03.07.96 from 'IntersectExtents'. 
------------------------------------------------------------*/
u32
CountExtentIntersections( List* A, List* B )
{
    Item*   AItem;
    Extent* Ao;
    Extent* Bo;
    u32     InterCount;
    
    // Reset the intersection count.
    InterCount = 0;
    
    // Zero the data size fields in each list.
    SetSizeOfItemsInList( A, 0 );
    SetSizeOfItemsInList( B, 0 );
    
    // For each extent in list 'A'.
    ReferToList( A );
     
    while( TheItem )
    {
        // Refer to an extent in list 'A'.
        Ao = (Extent*) TheDataAddress;
        AItem = TheItem;
        
        // For each extent in list 'B'.
        ReferToList( B );
        
        while( TheItem )
        {
            // Refer to an extent in list 'B'.
            Bo = (Extent*) TheDataAddress;
            
            if( IsIntersectingExtents( Ao, Bo ) )
            {
                // The extents intersect so add 1 to both.
                TheItem->SizeOfData++;
                AItem->SizeOfData++;
                InterCount++;
            }
            
            // Advance to the next extent in list 'B'.
            ToNextItem();
        }
        RevertToList();
        
        // Advance to the next extent in list 'A'.
        ToNextItem();
    }
    
    RevertToList();
    
    // Return the result.
    return( InterCount );
}

/*------------------------------------------------------------
| DeductExtent
|-------------------------------------------------------------
|
| PURPOSE: To deduct part of an extent leaving a list
|          of extents that refers to the remainder.
|
| DESCRIPTION: Given two extents, the first larger and
| containing the second, such that the boundary of the
| smaller coincides with the boundary of the larger at some
| point.
|
| EXAMPLE:  c = DeductExtent( Bigger, PartOfBigger );
|
| NOTE: 
|
| ASSUMES: Neither given extent should be altered.
|           
| HISTORY: 03.10.96 
------------------------------------------------------------*/
List*
DeductExtent( Extent* AWhole, Extent* APart )
{
    List*   Result;
    u32     i, DimCount;
    Extent* W;
    Extent* A;
    
    // Create the result list.
    Result = MakeList();
    
    // Duplicate the larger extent to make a working copy.
    W = DuplicateExtent( AWhole );
    
    // Get the dimension count.
    DimCount = W->DimCount;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        // If the whole extends below the part in this
        // dimension, then generate a new extent.
        if( W->Lo[i] < APart->Lo[i] )
        {
            // Copy the whole.
            A = DuplicateExtent( W );
            
            // Make the maximum extreme of this dimension
            // of the splinter the same as the minimum of 
            // the part.
            A->Hi[i] = APart->Lo[i];
            
            // Append the splinter to the result list.
            InsertDataLastInList( Result, (u8*) A );
            
            // Reduce the size of the working whole.
            W->Lo[i] = APart->Lo[i];
        }

        // If the whole extends above the part in this
        // dimension, then generate a new extent.
        if( W->Hi[i] > APart->Hi[i] )
        {
            // Copy the whole.
            A = DuplicateExtent( W );
            
            // Make the minimum extreme of this dimension
            // of the splinter the same as the maximum of 
            // the part.
            A->Lo[i] = APart->Hi[i];
            
            // Append the splinter to the result list.
            InsertDataLastInList( Result, (u8*) A );
            
            // Reduce the size of the working whole.
            W->Hi[i] = APart->Hi[i];
        }
    }
    
    // Return the result list.
    return( Result );
}

/*------------------------------------------------------------
| DuplicateExtent
|-------------------------------------------------------------
|
| PURPOSE: To make a dynamically allocated copy of an extent.
|
| DESCRIPTION:  
|
| EXAMPLE:  B = DuplicateExtent( A );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.10.96 
|          03.11.96 fixed pointers to arrays.
------------------------------------------------------------*/
Extent*
DuplicateExtent( Extent* E )
{
    Extent* oo;
    u32     DimCount;
    u32     RecordSize;
    
    // Get the original dimension count.
    DimCount = E->DimCount;
    
    // Calculate the record size.
    RecordSize = sizeof( Extent ) +
                 sizeof( f64 ) * DimCount * 2;
                 
    // Allocate an extent record with space for the vectors.
    oo = (Extent*) malloc( RecordSize );
    
    // Copy the original record data.
    CopyBytes( (u8*) E, (u8*) oo, RecordSize );

    // Refer to where the end point vectors will be stored.
    oo->Lo = (f64*) ( ((s8*) oo) + sizeof( Extent ) );
    oo->Hi = &oo->Lo[DimCount];
    
    // Return the new extent.
    return( oo );
}

/*------------------------------------------------------------
| DuplicateExtents
|-------------------------------------------------------------
|
| PURPOSE: To make a dynamically allocated copy of a list of
|          extents.
|
| DESCRIPTION:  
|
| EXAMPLE:  B = DuplicateExtents( A );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.12.96 
------------------------------------------------------------*/
List*
DuplicateExtents( List* A )
{
    List*   B;
    
    // Create the new list.
    B = MakeList();
    
    // Copy extents to B.
    ReferToList(A);
    
    while( TheItem )
    {
        InsertDataLastInList( B, (u8*)
            DuplicateExtent( (Extent*) TheDataAddress ) );
            
        ToNextItem();
    }
    RevertToList();
    
    return( B );
}

/*------------------------------------------------------------
| ExtentOfColumns
|-------------------------------------------------------------
|
| PURPOSE: To find the smallest and largest values in each
|          column of a matrix.
|
| DESCRIPTION: Returns an extent with the Lo values holding 
| the minimum value of each column and the Hi values holding 
| the maximum value of each column.
|
| EXAMPLE: Ex = ExtentOfColumns( M );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.22.96 
|          04.25.96 revised to use 'Extent' instead of
|                   'Vector'.
------------------------------------------------------------*/
Extent*
ExtentOfColumns( Matrix* A )
{
    u32     RowCount, ColCount, i; 
    Extent* E;
    f64*    AColumn;
    
    RowCount = A->RowCount;
    ColCount = A->ColCount;
    
    // Allocate the extent.
    E = MakeExtent( ColCount, 0, 0 );
    
    // For each column.
    for( i = 0; i < ColCount; i++ )
    {
        AColumn = (f64*) CopyColumnToNewBuffer( A, i );
        
        ExtentOfItems( AColumn, 
                       RowCount, 
                       &E->Lo[i], 
                       &E->Hi[i] );
        
        free( AColumn );
    }
    
    return( E );
}

/*------------------------------------------------------------
| ExtentOfSubQuad
|-------------------------------------------------------------
|
| PURPOSE: To calculate the extent of a subquadrant within
|          a given quadrant.
|
| DESCRIPTION: Expects a quadrant, axial point within that
| quadrant and a subquadrant index.
|
| Returns the extent of the subquadrant.
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
|                    '0'           '1'
|                     000001111111111      
|                     |----X--------|  
|                    Min           Max  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  04.25.96
|           04.26.96 added 'ChopTolerance' to low end too;
|                    changed bit indexing method. 
------------------------------------------------------------*/
void
ExtentOfSubQuad( Extent* SuperExtent, 
                 f64*   AxialPt,
                 s32     SubQuadIndex,
                 Extent* SubExtent ) 
{
    u32 DimCount, i;
    u32 Bit;
    
    // Get the dimension count from the super extent.
    DimCount = SuperExtent->DimCount;
    
    // For each dimension.
    Bit = 1;
    for( i = 0; i < DimCount; i++ )
    {
        if( SubQuadIndex & Bit )
        {
            SubExtent->Lo[i] = AxialPt[i];
            SubExtent->Hi[i] = SuperExtent->Hi[i];
        }
        else
        {
            SubExtent->Lo[i] = SuperExtent->Lo[i];
            SubExtent->Hi[i] = AxialPt[i];
        }
        
        // If this segment degenerates to a point, add
        // a very small amount to both ends so that
        // the extent won't be empty.
        if( SubExtent->Lo[i] == SubExtent->Hi[i] )
        {
            SubExtent->Lo[i] -= ChopTolerance;
            SubExtent->Hi[i] += ChopTolerance;
        }
        
        // Shift index bit left one bit to advance
        // to the next dimension.
        Bit <<= 1; 
    }
}

/*------------------------------------------------------------
| FillBitExtent
|-------------------------------------------------------------
|
| PURPOSE: To fill an orthogonal section of a bit array with 
|          a given bit value.
|
| DESCRIPTION: Expects two vectors that specify the low and
| high extremes of the extent to be filled.  Each extreme is
| is the coordinate of a cell in the array.
|
| A point is inside an extent if it is greater than or equal 
| to the 'Lo' point in all dimensions and less than the 'Hi' 
| point in all dimensions.
|
| EXAMPLE: In array A, set the value of cells in the extent 
| (2,3,4,5) to (4,4,9,6) to the value of 1:
|
|      s32  Lo[4], Hi[4];
|
|      Lo[0] = 2;
|      Lo[1] = 3;
|      Lo[2] = 4;
|      Lo[3] = 5;
|
|      Hi[0] = 4;
|      Hi[1] = 4;
|      Hi[2] = 9;
|      Hi[3] = 6;
|
|      v = FillBitExtent( A, Lo, Hi, 1 );
|
| NOTE: This could be made much faster by working with four
|       byte access units and by using masks that span multiple
|       bits.  Do later as needed.
|
| ASSUMES: The array is a bit array created using
|          'MakeMultiDimensionalBitArray()'.
|           
| HISTORY: 09.21.96 from 'PutBit' and 'FillExtent'.
------------------------------------------------------------*/
void
FillBitExtent( 
    Array* A,    // The array where the bits are held.
    u32*   Lo,   // The lower extreme of the extent.
    u32*   Hi,   // The upper extreme of the extent.
    u32    v )   // The value of the bits to be set, 0 or 1.
{
    u32     d;
    u32     DimCount, LastDim;
    u32     BitOffset, ByteOffset;
    u8*     ByteAddr;
    u32     BitNum;
    u8      BitMask;
    u32*    DimOffset;              
    u32     Index[ MaxArrayDimensions ];  
    
    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension set the index to the start of the
    // orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = Lo[d];
    }

    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
DoCurrentCell:  // Set the value of the current cell.

    // Clear the offset accumulator.
    BitOffset = 0;
    
    // Refer to the dimension offset factors of the array.
    DimOffset = &A->DimOffsetFactor[0];
    
    // For each dimension except the last one.
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        BitOffset += *DimOffset++ * Index[d];
    }
    
    // Add the offset of the last dimension outside the
    // loop to avoid a multiply because the DimOffset factor 
    // of the last dimension is always 1.
    BitOffset += Index[LastDim];
    
    // Convert bit offset to byte offset and bit-in-byte.
    ByteOffset = BitOffset >> 3;
    BitNum     = (u32) BitOffset & 7; // Leaving a value from 0-7.
    
    // Look up the mask for the nth bit: there is a '1' 
    // where the bit is and '0's in every other position.
    BitMask    = BitOfByte[BitNum];
    
    // Refer to the byte containing the bit.
    ByteAddr = ((u8*)A->Data) + ByteOffset;
    
NextCell:

    // If the value to store is '1'.
    if( v )
    {
         // Put a 1 bit into the cell.
        *ByteAddr |= BitMask;
    }
    else // The value to store is '0'.
    {
        // Invert the mask and AND with the target byte.
        *ByteAddr &= (u8) ( ~BitMask );
    }
    
    // Advance to the next bit by shifting the mask to
    // the left one position.
    BitMask = (u8) ( BitMask << 1 );
    
    // If the current position has moved into a new byte.
    if( BitMask == 0 )
    {
        // Advance to the next byte address.
        ByteAddr++;
        
        // Start with the first bit of the next byte.
        BitMask = 1;
    }
        
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    // If the current position is still within the
    // run of the last dimension.
    if( Index[LastDim] < Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds.
        if( Index[0] == Hi[0] )
        {
            // Then we are done.
            return;
        }
    }
    
    goto DoCurrentCell;
}   

/*------------------------------------------------------------
| FillExtent
|-------------------------------------------------------------
|
| PURPOSE: To store a value to each cell in an orthogonal 
|          region of an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: Store .001 to each cell of an extent of a four 
| dimensional array with dimensions 3 x 5 x 6 x 8.  
| 
| The extent cells range from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32     DimExtent[4];
|      s32     Lo[4];
|      s32     Hi[4];
|      Array*  A;
|      Extent* E;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      Lo[0] = 1;
|      Lo[1] = 2;
|      Lo[2] = 3;
|      Lo[3] = 4;
|
|      Hi[0] = 3; // Upper bound is one larger than the 
|      Hi[1] = 4; // address of the last cell in the extent.
|      Hi[2] = 5;
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
| 
|      FillExtent( A, E, .001 );
|
| NOTE: Doesn't support bit arrays: see 'FillBitExtent'.
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|           
| HISTORY: 03.07.96 from 'FillSection'. 
|          09.21.98 Added 'DimOffset' for speed but didn't
|                   test the change.
------------------------------------------------------------*/
void
FillExtent( Array* A, Extent* E, f64 v )
{
    f64*    ACell;
    u32     DimCount, d, LastDim, CellOffset;
    u32     Index[MaxArrayDimensions];  
    u32*    DimOffset;              
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateExtentInArray( A, E );
#endif

    // Get the number of dimensions.
    DimCount = A->DimCount;
    
    // For each dimension set the index to the start of
    // the orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
    }
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
DoCurrentCell:  // Set the value of the current cell.
    
    // For each dimension.
    CellOffset = 0;
    
    // Refer to the dimension offset factors of the array.
    DimOffset = &A->DimOffsetFactor[0];
    
    // For each dimension except the last one.
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += *DimOffset++ * Index[d];
    }
    
    // Add the offset of the last dimension outside the
    // loop to avoid a multiply because the DimOffset factor 
    // of the last dimension is always 1.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = &A->Data[CellOffset];

NextCell:
    
    // Store the cell value.
    *ACell = v;
    
    // Advance to next cell.
    ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < (u32) E->Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds.
        if( Index[0] == (u32) E->Hi[0] )
        {
            // Then we are done.
            return;
        }
    }
    
    goto DoCurrentCell;
}   

/*------------------------------------------------------------
| FindIntersectingExtent
|-------------------------------------------------------------
|
| PURPOSE: To find the extent in a list that intersects 
|          an extent.
|
| DESCRIPTION: Returns the extent item address, else 0 if 
| none found. 
|
| EXAMPLE:  A = FindIntersectingExtent( L, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.10.96 
------------------------------------------------------------*/
Item*
FindIntersectingExtent( List* L, Extent* E )
{
    Item* Result;
    
    ReferToList(L);
    
    while( TheItem )
    {
        // Is the current extent intersecting?
        if( IsIntersectingExtents( E, 
                                   (Extent*) TheDataAddress) )
        {
            // Found intersection: clean up and return.
            Result = TheItem;
            
            RevertToList();
            
            return( Result );
        }
        
        // Try next extent.
        ToNextItem();
    }
    RevertToList();
    
    // No intersection found.       
    return( 0 );
}   

/*------------------------------------------------------------
| FindItemsWithinExtent
|-------------------------------------------------------------
|
| PURPOSE: To find the points in a buffer of items that fall 
|          with a given extent.
|
| DESCRIPTION: Each item hold the 1-dimensional coordinates 
| of a single point.  
|
| Returns a list referring to the points in the buffer that 
| fall within the data space extent given.
|
| The extent includes all 'n' such that:
|
|          Min <= n < Max
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.02.96 from 'FindPointsWithinExtent'.
------------------------------------------------------------*/
List*
FindItemsWithinExtent( Extent* E, f64* P, s32 Count )
{
    List*   L;
    s32 i;
    
    // Collect the points that fall into this extent.
    L = MakeList();
    
    // For each point.
    
    for( i = 0; i < Count; i++ )
    {
        if( E->Lo[0] <= P[i] && P[i] < E->Hi[0] )
        {
            // This one is in the section so add it to the 
            // list.
            InsertPointLastInList( L, &P[i], 1 );
        }
    }
    
    return( L );
}

/*------------------------------------------------------------
| FindMaxCellInExtent
|-------------------------------------------------------------
|
| PURPOSE: To find the cell that has the highest value in
|          an extent of an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| Returns the resulting cell in buffer 'c'.  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|           
| HISTORY: 04.09.96 from 'AddToExtent'. 
|          04.23.96 made return value integer rather than
|                   part of an 'Extent'.
------------------------------------------------------------*/
void
FindMaxCellInExtent( Array* A, Extent* E, u32* c )
{
    f64 Max;
    f64 v;
    f64*    ACell;
    u32     DimCount, d, LastDim, CellOffset;
    u32     Index[MaxArrayDimensions];  

#ifdef ARRAY_ERROR_CHECKING
    ValidateExtentInArray( A, E );
#endif

    // Get the number of dimensions.
    DimCount = A->DimCount;
    
    // For each dimension set the index to the start of
    // the orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
    }
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
    // Set the current max value to an improbably small number.
    Max = -1.0e34;
    
DoCurrentCell:  // Set the value of the current cell.
    
    // For each dimension.
    CellOffset = 0;
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[d] * Index[d];
    }
    
    // Add the offset of the last dimension.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = &A->Data[CellOffset];

NextCell:
    
    // Get the cell value.
    v = *ACell;
    
    // If this value is larger than the current maximum, then
    // make it the new maximum.
    if( v > Max )
    {
        Max = v;
        
        // Save the index.
        for( d = 0; d < DimCount; d++ )
        {
            c[d] = Index[d];
        }
    }
    
    // Advance to next cell.
    ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < (u32) E->Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds
        // then we are done.
        if( Index[0] == (u32) E->Hi[0] )
        {
            goto Done;
        }
    }
    
    goto DoCurrentCell;

Done:
    
    return;
}   

/*------------------------------------------------------------
| FindPointsWithinExtent
|-------------------------------------------------------------
|
| PURPOSE: To find the points in a matrix that fall with a
|          given extent.
|
| DESCRIPTION: Each matrix row is devoted to holding the 
| coordinates of a single point.  
|
| Returns a point list referring to the points in the matrix 
| that fall within the data space extent given.
|
| The extent includes all 'n' such that:
|
|          Min <= n < Max
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.22.96
------------------------------------------------------------*/
List*
FindPointsWithinExtent( Matrix* M, Extent* E )
{
    List*   L;
    f64**   P;
    u32     ItemCount, DimCount, i, j;
    
    // Collect the points that fall into this extent.
    L = MakeList();
    
    // Get the number of points.        
    ItemCount = M->RowCount;
    DimCount  = M->ColCount;
     
    // Refer to the cell data.
    P = (f64**) M->a;
    
    for( i = 0; i < ItemCount; i++ )
    {
        for( j = 0; j < DimCount; j++ )
        {
            if( P[i][j] < E->Lo[j] || P[i][j] >= E->Hi[j] )
            {
                // Skip this one because it isn't in range.
                goto LabelA;
            }
        }
                
        // This one is in the section so add it to the list.
        InsertPointLastInList( L, P[i], DimCount );
LabelA:;

    }
    
    return( L );
}

/*------------------------------------------------------------
| IntersectExtent
|-------------------------------------------------------------
|
| PURPOSE: To find the intersection of extent A in extent
|          B. 
|
| DESCRIPTION: Creates a new extent record consisting of
| the intersection of two extents.  
|
| If there is no intersection across all dimensions, then the 
| first dimension of the result is marked as empty, and the 
| remaining dimensions are undefined.
|
| EXAMPLE:  E = IntersectExtent( A, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.07.96 from 'Intersect'. 
------------------------------------------------------------*/
Extent*
IntersectExtent( Extent* A, Extent* B )
{
    Extent* E;
    u32     i;
    u32     DimCount;
    f64 maxLo, minHi;
    
    // Get the dimension count.
    DimCount = A->DimCount;

    // Make a new extent record using the first extent.
    // as a template.
    E = MakeExtent( DimCount, A->Lo, A->Hi );
    
    // Form the intersection by finding the overlapping
    // segments of each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        maxLo = max( A->Lo[i], B->Lo[i] );
        minHi = min( A->Hi[i], B->Hi[i] );

        // If the two segments don't intersect.
        if( maxLo >= minHi )
        {
            E->Lo[0] = 0;
            E->Hi[0] = 0;
            
            return( E );
        }
        else // Save the intersection in E.
        {
            E->Lo[i] = maxLo;
            E->Hi[i] = minHi;
        }
    }
    
    // Return the result.
    return( E );
}

/*------------------------------------------------------------
| IntersectExtents
|-------------------------------------------------------------
|
| PURPOSE: To find the intersection of extent list 'A' in 
|          extent list 'B'. 
|
| DESCRIPTION: Creates a new list of extent records 
| consisting of the intersection of the first list in the
| second.
|
| If there is no intersection then a list with an empty
| extent is returned. 
|
| EXAMPLE:  C = IntersectExtents( A, B );
|
| NOTE: 
|
| ASSUMES: The given lists each contain disjoint extents.
|           
| HISTORY: 03.07.96 from 'Intersect'. 
------------------------------------------------------------*/
List*
IntersectExtents( List* A, List* B )
{
    List*       Result;
    Extent*     E;
    Extent*     Ao;
    Extent*     Bo;
    
    // Create the result list.
    Result = MakeList();
    
    // For each extent in list 'A'.
    ReferToList(A);
    
    while( TheItem )
    {
        // Refer to an extent in list 'A'.
        Ao = (Extent*) TheDataAddress;
        
        // For each extent in list 'B'.
        ReferToList(B);
        
        while( TheItem )
        {
            // Refer to an extent in list 'B'.
            Bo = (Extent*) TheDataAddress;
            
            // If they intersect.
            if( IsIntersectingExtents( Ao, Bo ) )
            {
                // Find the intersection of 'Ao' in 'Bo'.
                E = IntersectExtent( Ao, Bo );
            
                // Add the extent to the result.
                InsertDataLastInList( Result, (u8*) E );
            }
            
            // Advance to the next extent in list 'B'.
            ToNextItem();
        }
        RevertToList();
        
        // Advance to the next extent in list 'A'.
        ToNextItem();
    }
    RevertToList();
    
    // If the result list is empty, add an empty extent.
    if( Result->ItemCount == 0 )
    {
        // Make empty one-dimensional extent.
        InsertDataLastInList( Result, 
                              (u8*) MakeExtent( 1, 0, 0 ) );
    }
    
    // Return the result list.
    return( Result );
}

/*------------------------------------------------------------
| IsCellInExtent
|-------------------------------------------------------------
|
| PURPOSE: To test if a cell falls in an extent.
|
| DESCRIPTION: Expects an extent and a vector identifying
| a cell by it's lower bound.  Treats the cell as a very 
| small extent and then performs an intersection test.
|
| EXAMPLE:     t = IsCellInExtent( A, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.08.96 from 'IsIntersectingExtents'.
------------------------------------------------------------*/
u32  
IsCellInExtent( Extent* A, u32* ACell )
{
    u32 i;
    u32 DimCount;
    u32 maxLo, minHi;
    
    // Get the dimension count.
    DimCount = A->DimCount;

    // Form the intersection by finding the overlapping
    // segments of each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        maxLo = max( ( (u32) A->Lo[i] ), ACell[i] );
        minHi = min( ( (u32) A->Hi[i] ), ACell[i]+1 );

        // If the two segments don't intersect.
        if( maxLo >= minHi )
        {
            return( 0 );
        }
    }
    
    // There is an intersection in all dimensions.
    return( 1 );
}

/*------------------------------------------------------------
| IsIntersectingExtents
|-------------------------------------------------------------
|
| PURPOSE: To test if two extents contain any cells in 
|          common.
|
| DESCRIPTION: 
|
| EXAMPLE:     t = IsIntersectingExtents( A, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.07.96 from 'IsSectionEmpty'.
------------------------------------------------------------*/
u32  
IsIntersectingExtents( Extent* A, Extent* B )
{
    u32 i;
    u32 DimCount;
    u32 maxLo, minHi;
    
    // Get the dimension count.
    DimCount = A->DimCount;

    // Form the intersection by finding the overlapping
    // segments of each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        maxLo = (u32) max( A->Lo[i], B->Lo[i] );
        minHi = (u32) min( A->Hi[i], B->Hi[i] );

        // If the two segments don't intersect.
        if( maxLo >= minHi )
        {           
            return( 0 );
        }
    }
    
    // There is an intersection in all dimensions.
    return( 1 );
}

/*------------------------------------------------------------
| IsExtentEmpty
|-------------------------------------------------------------
|
| PURPOSE: To test if an extent is empty, consisting of no
|          cells.
|
| DESCRIPTION: Expects a record that specifies the lower and 
| upper limits of the extent, where the upper limit
| is the address of the cell just beyond the extent and the
| lower limit is the address of the first cell in the extent.
|
| The reason that the upper bound is one beyond the last cell
| rather than being the last cell, is so that an empty extent
| can be specified when upper and lower bounds equal.
|
| This procedure tests for any equal dimension segments, and 
| returns '1' if there are any, else returns '0'.
|
| EXAMPLE:     t = IsExtentEmpty( S );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.07.96 from 'IsSectionEmpty'.
------------------------------------------------------------*/
u32  
IsExtentEmpty( Extent* E )
{
    u32 i;
    u32 DimCount;
    
    // Get the dimension count.
    DimCount = E->DimCount;
    
    // Look for any empty segments.
    for( i = 0; i < DimCount; i++ )
    {
        // If dimension has an empty segment.
        if( E->Lo[i] >= E->Hi[i] )
        {
            return( 1 );
        }
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| IsExtentsEmpty
|-------------------------------------------------------------
|
| PURPOSE: To test if a list of extents is empty in the 
|          sense that it refers to no cells.
|
| DESCRIPTION: Returns '1' if all of the othogons in the
| given list are empty, else returns '0'.
|
| EXAMPLE:     t = IsExtentEmpty( S );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.07.96 from 'IsExtentEmpty'.
------------------------------------------------------------*/
u32  
IsExtentsEmpty( List* L )
{
    ReferToList(L);
    
    while( TheItem )
    {
        if( IsExtentEmpty( (Extent*) TheDataAddress ) ==
            0 )
        {
            // Found an extent with substance.
            // Clean up and return '0'.
            RevertToList();
            
            return( 0 );
        }
        
        // Check next extent.
        ToNextItem();
    }
    RevertToList();
    
    // If get here then the extents are empty.
    return( 1 );
}

/*------------------------------------------------------------
| IsExtentInArray
|-------------------------------------------------------------
|
| PURPOSE: To test whether an extent is within an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array.  Returns '1' if the extent
| doesn't extend beyond the bounds of the array, else returns
| '0'.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.16.96 
------------------------------------------------------------*/
u32  
IsExtentInArray( Array* A, Extent* E )
{
    u32 DimCount, i;
    
    // Get the dimension count of the array.
    DimCount = A->DimCount;
    
    // Make sure the dimensions match.
    if( DimCount != E->DimCount )
    {
        return( 0 );
    }
    
    // Then make sure the extent is in the array.
    for( i = 0; i < DimCount; i++ )
    {
        if( ( E->Hi[i] > A->DimExtent[i] ) ||
            ( E->Lo[i] < 0 ) )
        {
            return( 0 );
        }
    }
    
    // No problem.
    return( 1 );
}

/*------------------------------------------------------------
| IsExtentLarger
|-------------------------------------------------------------
|
| PURPOSE: To test if magnitude of every dimension of extent
|          'A' is larger or equal to extent 'B' and at least
|          one dimension is larger.
|
| DESCRIPTION: Returns '1' if extent 'A' is larger than 'B'. 
|
| EXAMPLE:     t = IsExtentLarger( A, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.09.96 from 'IsExtentSubsumed'.
------------------------------------------------------------*/
u32  
IsExtentLarger( Extent* A, Extent* B )
{
    u32     i;
    u32     DimCount;
    f64 ASize, BSize;
    u32     IsAtLeastOneLarger;
    
    // Get the dimension count.
    DimCount = A->DimCount;

    // Test each dimension.
    IsAtLeastOneLarger = 0;
    for( i = 0; i < DimCount; i++ )
    {
        ASize = A->Hi[i] - A->Lo[i];
        BSize = B->Hi[i] - B->Lo[i];
        
        if( ASize < BSize )
        {
            return( 0 );
        }
        else
        {
            if( ASize > BSize )
            {
                IsAtLeastOneLarger = 1;
            }
        }
    }
    
    return( IsAtLeastOneLarger );
}

/*------------------------------------------------------------
| IsExtentSmaller
|-------------------------------------------------------------
|
| PURPOSE: To test if magnitude of every dimension of extent
|          'A' is smaller or equal to extent 'B' and at least
|          one dimension is smaller.
|
| DESCRIPTION: Returns '1' if extent 'A' is smaller than 'B'. 
|
| EXAMPLE:     t = IsExtentSmaller( A, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.09.96 from 'IsExtentSubsumed'.
------------------------------------------------------------*/
u32  
IsExtentSmaller( Extent* A, Extent* B )
{
    u32     i;
    u32     DimCount;
    f64 ASize, BSize;
    u32     IsAtLeastOneSmaller;
    
    // Get the dimension count.
    DimCount = A->DimCount;

    // Test each dimension.
    IsAtLeastOneSmaller = 0;
    for( i = 0; i < DimCount; i++ )
    {
        ASize = A->Hi[i] - A->Lo[i];
        BSize = B->Hi[i] - B->Lo[i];
        
        if( ASize > BSize )
        {
            return( 0 );
        }
        else
        {
            if( ASize < BSize )
            {
                IsAtLeastOneSmaller = 1;
            }
        }
    }
    
    return( IsAtLeastOneSmaller );
}

/*------------------------------------------------------------
| IsExtentSubsumed
|-------------------------------------------------------------
|
| PURPOSE: To test if the contents of extent 'B' are
|          contained in extent 'A'.
|
| DESCRIPTION: Returns '1' if every cell in extent 'B' 
|              falls inside extent 'A'.
|
| EXAMPLE:     t = IsSubsumedExtent( A, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.08.96 from 'IsIntersectingExtents'.
------------------------------------------------------------*/
u32  
IsExtentSubsumed( Extent* A, Extent* B )
{
    u32 i;
    u32 DimCount;
    
    // Get the dimension count.
    DimCount = A->DimCount;

    // Form the intersection by finding the overlapping
    // segments of each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        if( B->Lo[i] < A->Lo[i] || A->Hi[i] < B->Hi[i] )
        {
            return( 0 );
        }
    }
    
    // 'B' is subsumed by 'A'.
    return( 1 );
}

/*------------------------------------------------------------
| IsPartialPointInExtent
|-------------------------------------------------------------
|
| PURPOSE: To test if a partially defined point falls within  
|          an extent in all of the defined dimensions.
|
| DESCRIPTION: Expects an extent and a partially defined 
| point.  
|
| A partially defined point consists of the coordinates of
| a data point coupled with a set of integers that are 
| non-zero if the cooresponding dimension of the data point
| is defined.
|
| EXAMPLE:   t = IsPartialPointInExtent( A, B, IsBDefined );
|
| NOTE: 
|
| ASSUMES: At least one dimension is defined.
|           
| HISTORY: 05.09.96 from 'IsPointInExtent'.
------------------------------------------------------------*/
u32  
IsPartialPointInExtent( Extent* E, f64* P, s32* IsDefined )
{
    u32 i;
    u32 DimCount;
    
    // Get the dimension count.
    DimCount = E->DimCount;

    // Check each dimension of the point separately.
    for( i = 0; i < DimCount; i++ )
    {
        if( IsDefined[i] &&
            ( P[i] < E->Lo[i] || P[i] >= E->Hi[i] ) )
        {
            return( 0 );
        }
    }
    
    return( 1 );
}

/*------------------------------------------------------------
| IsPointInExtent
|-------------------------------------------------------------
|
| PURPOSE: To test if a point falls in an extent.
|
| DESCRIPTION: Expects an extent and a point.   
|
| EXAMPLE:     t = IsPointInExtent( A, B );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.25.96 from 'IsCellInExtent'.
------------------------------------------------------------*/
u32  
IsPointInExtent( Extent* E, f64* P )
{
    u32 i;
    u32 DimCount;
    
    // Get the dimension count.
    DimCount = E->DimCount;

    // Check each dimension of the point separately.
    for( i = 0; i < DimCount; i++ )
    {
        if( P[i] < E->Lo[i] || P[i] >= E->Hi[i] )
        {
            return( 0 );
        }
    }
    
    return( 1 );
}

/*------------------------------------------------------------
| IsPointsInExtent
|-------------------------------------------------------------
|
| PURPOSE: To test if any points in a list fall within an
|          extent.
|
| DESCRIPTION: Each list item refers to a single data point.
| The 'SizeOfData' field holds the number of bytes in the
| point, that is, the number of dimensions of each point 
| times the size of an f64.
|
| Returns '1' if there are any points fall within
| the extent. 
|
| The extent includes all 'n' such that:
|
|          Min <= n < Max
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
IsPointsInExtent( List* L, Extent* E )
{
    f64*   P;
    u32     DimCount, i;
    
    DimCount = DimensionOfPointList( L );

    ReferToList( L );
    
    // For each point.
    while( TheItem )
    {   
        // Refer to the point.
        P = (f64*) TheDataAddress;
    
        for( i = 0; i < DimCount; i++ )
        {
            if( P[i] < E->Lo[i] || P[i] >= E->Hi[i] )
            {
                // Skip this one because it isn't in range.
                goto LabelA;
            }
        }
        
        // This one is inside.
        RevertToList();
        
        return( 1 );    
        
LabelA:;

        ToNextItem();
    }
    
    RevertToList();
    
    return( 0 );
}

/*------------------------------------------------------------
| MakeExtent
|-------------------------------------------------------------
|
| PURPOSE: To make a new extent record that refers to an
|          orthagonal section of a space.
|
| DESCRIPTION: Expects a dimension count and points which 
| specify lower and upper limits of the extent, where the 
| upper limit is the point just beyond the extent and the 
| lower limit is the first point in the extent.
|
| The reason that the upper bound is one beyond the point in
| the extent rather than being the last point is so that an
| empty extent can be indicated, by setting upper and lower
| bounds equal.
|
| The end points that define the extent are copied to the 
| memory just following the 'Extent' record.  This memory is 
| freed when the 'Extent' is freed: use 'free()'.
|
| If an empty extent is desired, use 0's for 'Lo' and 'Hi'.
|
| EXAMPLE: Make a four dimensional extent that includes
| cells ranging from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      f64     Lo[4];
|      f64     Hi[4];
|      Extent* E;
|
|      Lo[0] = 1.;
|      Lo[1] = 2.;
|      Lo[2] = 3.;
|      Lo[3] = 4.;
|
|      Hi[0] = 3.; // Upper bound is one larger than the 
|      Hi[1] = 4.; // address of the last cell in the 
|      Hi[2] = 5.; // extent.
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
|
| ASSUMES: The lower extents are <= the upper extents.
|           
| HISTORY: 03.07.96 from 'MakeSection'.
|          04.23.96 generalized to floating point.
------------------------------------------------------------*/
Extent*
MakeExtent( u32 DimCount, f64* Lo, f64* Hi )
{
    Extent* E;
    u32 i;
    
    // Allocate an extent record with space for the vectors.
    E = (Extent*) malloc( sizeof( Extent ) +
                             sizeof( f64 ) * DimCount * 2 );
    
    // Save the dimension count.
    E->DimCount = DimCount;
    
    // Refer to where the end point vectors will be stored.
    E->Lo = (f64*) ( ((s8*) E) + sizeof( Extent ) );
    E->Hi = &E->Lo[DimCount];
    
    // Copy the end point vectors, if any.
    for( i = 0; i < DimCount; i++ )
    {
        // If no end point vectors, make empty extent.
        if( Lo == 0 || Hi == 0 )
        {
            E->Lo[i] = 0;
            E->Hi[i] = 0;
        }
        else // Transfer the vectors.
        {
            E->Lo[i] = Lo[i];
            E->Hi[i] = Hi[i];
        }
    }
    
    // Return the new extent.
    return( E );
}

/*------------------------------------------------------------
| MarkIntersectingExtents
|-------------------------------------------------------------
|
| PURPOSE: To mark extents that intersect extents
|          in another list.
|
| DESCRIPTION: Given two lists of extents, compare each with
| each extent to determine if extents intersect some
| some other extent.  Mark the intersecting extent items.
|
| Returns '1' if there are any intersecting extents, else
| '0'.   
|
| EXAMPLE:  t = MarkIntersectingExtents( A, B );
|
| NOTE: 
|
| ASSUMES: The given lists each contain disjoint extents.
|          Items are unmarked.
|           
| HISTORY: 03.07.96 from 'IntersectExtents'. 
------------------------------------------------------------*/
u32  
MarkIntersectingExtents( List* A, List* B )
{
    Item*       AItem;
    Extent*     Ao;
    Extent*     Bo;
    u32         IsMarked;
    
    // Reset the marking flag.
    IsMarked = 0;
    
    // For each extent in list 'A'.
    ReferToList(A);
    
    while( TheItem )
    {
        // Refer to an extent in list 'A'.
        Ao = (Extent*) TheDataAddress;
        AItem = TheItem;
        
        // For each extent in list 'B'.
        ReferToList(B);
        
        while( TheItem )
        {
            // Refer to an extent in list 'B'.
            Bo = (Extent*) TheDataAddress;
            
            if( IsIntersectingExtents( Ao, Bo ) )
            {
                // The extents intersect so mark them both.
                MarkItem( TheItem );
                MarkItem( AItem );
                IsMarked = 1;
            }
            
            // Advance to the next extent in list 'B'.
            ToNextItem();
        }
        RevertToList();
        
        // Advance to the next extent in list 'A'.
        ToNextItem();
    }
    RevertToList();
    
    // Return the result.
    return( IsMarked );
}

/*------------------------------------------------------------
| MarkPointsOutsideExtent
|-------------------------------------------------------------
|
| PURPOSE: To mark the points in a list that fall outside an
|          extent.
|
| DESCRIPTION: Each list item refers to a single data point.
| The 'SizeOfData' field holds the number of bytes in the
| point, that is, the number of dimensions of each point 
| times the size of an f64.
|
| Leaves existing marks of points not in the extent unchanged.
|
| Returns '1' if there are any points that fall outside
| the extent. 
|
| The extent includes all 'n' such that:
|
|          Min <= n < Max
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.02.96 from 'MarkPointsWithinExtent'.
------------------------------------------------------------*/
u32  
MarkPointsOutsideExtent( List* L, Extent* E )
{
    f64*   P;
    u32     DimCount, i;
    u32     IsOutside;
    
    DimCount = DimensionOfPointList( L );

    ReferToList( L );
    
    // For each point.
    IsOutside = 0;
    while( TheItem )
    {   
        // Refer to the point.
        P = (f64*) TheDataAddress;
    
        for( i = 0; i < DimCount; i++ )
        {
            if( P[i] < E->Lo[i] || P[i] >= E->Hi[i] )
            {
                // This one is outside the section so mark it.
                MarkItem( TheItem );
                IsOutside = 1;
                goto LabelA;
            }
        }

LabelA: 

        ToNextItem();
    }
    
    RevertToList();
    
    return( IsOutside );
}

/*------------------------------------------------------------
| MarkPointsWithinExtent
|-------------------------------------------------------------
|
| PURPOSE: To mark the points in a list that fall within an
|          extent.
|
| DESCRIPTION: Each list item refers to a single data point.
| The 'SizeOfData' field holds the number of bytes in the
| point, that is, the number of dimensions of each point 
| times the size of an f64.
|
| Leaves existing marks of points not in the extent unchanged.
|
| Returns '1' if there are any points fall within
| the extent. 
|
| The extent includes all 'n' such that:
|
|          Min <= n < Max
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
MarkPointsWithinExtent( List* L, Extent* E )
{
    f64*   P;
    u32     DimCount, i;
    u32     IsWithin;
    
    DimCount = DimensionOfPointList( L );

    ReferToList( L );
    
    // For each point.
    IsWithin = 0;
    while( TheItem )
    {   
        // Refer to the point.
        P = (f64*) TheDataAddress;
    
        for( i = 0; i < DimCount; i++ )
        {
            if( P[i] < E->Lo[i] || P[i] >= E->Hi[i] )
            {
                // Skip this one because it isn't in range.
                goto LabelA;
            }
        }
                
        // This one is in the section so mark it.
        MarkItem( TheItem );
        IsWithin = 1;
        
LabelA:;

        ToNextItem();
    }
    
    RevertToList();
    
    return( IsWithin );
}

/*------------------------------------------------------------
| MarkSubsumedExtents
|-------------------------------------------------------------
|
| PURPOSE: To mark extents that are subsumed by extents
|          in another list.
|
| DESCRIPTION: Given two lists of extents, compare each with
| each extent to determine which extents are subsumed
| by some other extent.  Mark the subsumed extent items.
|
| Returns '1' if there are any subsumed extents, else
| '0'.  Also marks lists that contain subsumed extents.
|
| EXAMPLE:  t = MarkSubsumedExtents( A, B );
|
| NOTE: 
|
| ASSUMES: The given lists each contain disjoint extents.
|          Lists and items are unmarked.
|           
| HISTORY: 03.07.96 from 'IntersectExtents'. 
------------------------------------------------------------*/
u32  
MarkSubsumedExtents( List* A, List* B )
{
    Item*       AItem;
    Extent*     Ao;
    Extent*     Bo;
    u32         IsMarked;
    
    // Reset the marking flag.
    IsMarked = 0;
    
    // For each extent in list 'A'.
    ReferToList( A );
 
    while( TheItem )
    {
        // Refer to an extent in list 'A'.
        Ao = (Extent*) TheDataAddress;
        AItem = TheItem;
        
        // For each extent in list 'B'.
        ReferToList( B );
        
        while( TheItem )
        {
            // Refer to an extent in list 'B'.
            Bo = (Extent*) TheDataAddress;
            
            if( IsExtentSubsumed( Ao, Bo ) )
            {
                // Bo is subsumed by Ao, so mark Bo
                // for later deletion.
                MarkItem( TheItem );
                MarkList( B );
                IsMarked = 1;
            }
            else
            {
                if( IsExtentSubsumed( Bo, Ao ) )
                {
                    // Ao is subsumed by Bo, so mark
                    // Ao for later deletion and
                    // stop checking the BB list.
                    MarkItem( AItem );
                    MarkList( A );
                    IsMarked = 1;
                    goto AfterB;
                }
            }
            
            // Advance to the next extent in list 'B'.
            ToNextItem();
        }
AfterB:
        RevertToList();
        
        // Advance to the next extent in list 'A'.
        ToNextItem();
    }
    RevertToList();
    
    // Return the result.
    return( IsMarked );
}

/*------------------------------------------------------------
| MidpointOfExtent
|-------------------------------------------------------------
|
| PURPOSE: To calculate the mean point of an extent.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: Rename later to 'MidpointOfExtent'.
|
| ASSUMES: 
|
| HISTORY:  04.25.96 
------------------------------------------------------------*/
void
MidpointOfExtent( Extent* E, f64* MeanPt ) 
{
    u32 DimCount, i;
    
    // Get the dimension count from the extent.
    DimCount = E->DimCount;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        MeanPt[i] = (E->Hi[i] + E->Lo[i]) / 2.;
    }
}

/*------------------------------------------------------------
| MeanOfExtent
|-------------------------------------------------------------
|
| PURPOSE: To find the mean of the values held in an extent 
|          of an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: 
| 
|      v = MeanOfExtent( A, E );
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|
|          Enough room for a working buffer to hold the
|          contents of the extent must exist.
|           
| HISTORY: 08.07.98 from 'MedianOfExtent'.
------------------------------------------------------------*/
f64
MeanOfExtent( Array* A, Extent* E )
{
    f64     Sum;
    u32     CellCount;
    
    // Count up how many cells there are in the extent.
    CellCount = CountCellsInExtent( E );
    
    // Sum up the values.
    Sum = SumOfExtent( A, E );

    // Returns the result.
    return( Sum / ((f64) CellCount) );
}

/*------------------------------------------------------------
| MedianOfExtent
|-------------------------------------------------------------
|
| PURPOSE: To find the median value held in an extent of an
|          array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: 
| 
|      v = MedianOfExtent( A, E );
|
| NOTE: Dynamically allocates and frees a working buffer.
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|
|          Enough room for a working buffer to hold the
|          contents of the extent must exist.
|           
| HISTORY: 08.05.98 from 'SumOfExtent'.
|           
------------------------------------------------------------*/
f64
MedianOfExtent( Array* A, Extent* E )
{
    f64*    B;
    f64     Med;
    u32     CellCount;
    
    // Count up how many cells there are in the extent.
    CellCount = CountCellsInExtent( E );
    
    // Make a buffer large enough
    B = MakeItems( CellCount, 0 );
    
    // Copy the extent to the buffer.
    CopyExtentToBuffer( A, E, B );
    
    // Calculate the median.
    Med = Median3( B, CellCount );
    
    // Delete the buffer.
    free( B );
    
    // Return the result.
    return( Med );
}

/*------------------------------------------------------------
| MergeIntersectingExtents
|-------------------------------------------------------------
|
| PURPOSE: To form a single list of disjoint extents from
|          two other lists, known to intersect at every
|          extent.
|
| DESCRIPTION: 
|
| EXAMPLE:
|
| NOTE: 
|
| ASSUMES:
|  
| 1. Each extent in list 'A' intersects with at least
|    one extent in list 'B', and vice versa.
|
| 2. Each list is composed only of disjoint extents.
|
| 3. No extent in either list subsumes an extent in the
|    other list.
|
| 4. Both lists may be deleted by this procedure.
|
| 5. The referenced extents should NOT be deleted.
|
|           
| HISTORY: 03.08.96  
------------------------------------------------------------*/
List*
MergeIntersectingExtents( List* A, List* B ) 
{
    List*   AB;
    u32     InterCount;
    List*   TheNonIntersection;
    Item*   TheOne;
    Item*   TheOther;
    List*   TheOneList;
    List*   TheOtherList;
    Extent* TheIntersection;
    
    // Create a result list.
    AB = MakeList();
    
    // Identify the manner of the intersections.
    InterCount = CountExtentIntersections( A, B );
    
BeginLoop:
    
    // If there are no more intersections, join the remaining
    // extents to the result and then return.
    if( InterCount == 0 )
    {
        JoinLists( AB, A ); // Also deletes list 'A'.
        JoinLists( AB, B ); // Also deletes list 'B'.
        
        return( AB );
    }
    
    // Find an extent with a single intersection in 
    // either list.
    TheOne = FindFirstItemOfSize( A, 1 );
    if( TheOne )
    {
        // Identify the list with the single intersection.
        TheOneList   = A;
        TheOtherList = B;
    }
    else // The single must in list 'B': find it.
    {
        TheOne        = FindFirstItemOfSize( B, 1 );
        TheOneList    = B;
        TheOtherList  = A;
    }
    
    // Find the other extent that intersects 'TheOne'.
    TheOther = 
        FindIntersectingExtent( TheOtherList, 
                      (Extent*) (TheOne->DataAddress) );
    
    // Calculate the intersection.
    TheIntersection = 
        IntersectExtent( (Extent*) TheOne->DataAddress, 
                           (Extent*) TheOther->DataAddress );
    
    // Form a set of extents that is 'TheOne' with 
    // 'TheIntersection' deducted.
    TheNonIntersection = 
        DeductExtent( (Extent*) TheOne->DataAddress,
                        TheIntersection );
    
    // Append the non-intersection to the final result and
    // delete list 'TheNonIntersection'.
    JoinLists( AB, TheNonIntersection ); 
    
    // Delete 'TheOne' from 'TheOneList'.
    ExtractItemFromList( TheOneList, TheOne );
    DeleteItem( TheOne );
    
    // Decrement the intersection count of 'TheOther'.
    TheOther->SizeOfData--;
    
    // Decrement the overall intersection count.
    InterCount--;
            
    goto BeginLoop;
}

/*------------------------------------------------------------
| MultiplyToExtent
|-------------------------------------------------------------
|
| PURPOSE: To multiply a value to each cell in an orthogonal 
|          region of an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: Multiply .001 to an extent of a four dimensional 
| array with dimensions 3 x 5 x 6 x 8.  
| 
| The extent cells range from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32  DimExtent[4];
|      f64      Lo[4];
|      f64  Hi[4];
|      Array*   A;
|      Extent*  S;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      Lo[0] = 1;
|      Lo[1] = 2;
|      Lo[2] = 3;
|      Lo[3] = 4;
|
|      Hi[0] = 3; // Upper bound is one larger than the 
|      Hi[1] = 4; // address of the last cell in the extent.
|      Hi[2] = 5;
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
| 
|      MultiplyToExtent( A, E, .001 );
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|           
| HISTORY: 03.06.96 from 'FillSection'. 
------------------------------------------------------------*/
void
MultiplyToExtent( Array* A, Extent* E, f64 v )
{
    f64*    ACell;
    u32     DimCount, d, LastDim, CellOffset;
    u32     Index[MaxArrayDimensions];  
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateExtentInArray( A, E );
#endif

    // Get the number of dimensions.
    DimCount = A->DimCount;
    
    // For each dimension set the index to the start of
    // the orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
    }
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
DoCurrentCell:  // Set the value of the current cell.
    
    // For each dimension.
    CellOffset = 0;
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[d] * Index[d];
    }
    
    // Add the offset of the last dimension.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = &A->Data[CellOffset];

NextCell:
    
    // Multiply to the cell value.
    *ACell *= v;
    
    // Advance to next cell.
    ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < (u32) E->Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds
        // then we are done.
        if( Index[0] == (u32) E->Hi[0] )
        {
            goto Done;
        }
    }
    
    goto DoCurrentCell;

Done:
    return;
}   

/*------------------------------------------------------------
| SumOfExtent
|-------------------------------------------------------------
|
| PURPOSE: To add up the values of each cell in an orthogonal 
|          region of an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: Add up the cells in an extent of a four 
| dimensional array with dimensions 3 x 5 x 6 x 8.  
| 
| The extent cells range from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32  DimExtent[4];
|      s32  Lo[4];
|      s32  Hi[4];
|      Array*   A;
|      Extent*  E;
|      f64* v;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      Lo[0] = 1;
|      Lo[1] = 2;
|      Lo[2] = 3;
|      Lo[3] = 4;
|
|      Hi[0] = 3; // Upper bound is one larger than the 
|      Hi[1] = 4; // address of the last cell in the extent.
|      Hi[2] = 5;
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
| 
|      v = SumOfExtent( A, E );
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|           
| HISTORY: 03.07.96 from 'FillSection'. 
------------------------------------------------------------*/
f64
SumOfExtent( Array* A, Extent* E )
{
    f64*    ACell;
    f64     Sum;
    u32     DimCount, d, LastDim, CellOffset;
    u32     Index[MaxArrayDimensions];  
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateExtentInArray( A, E );
#endif

    // Get the number of dimensions.
    DimCount = A->DimCount;
        
    // For each dimension set the index to the start of
    // the orthogonal region.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
    }
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;
    
    // Begin adding up the cells.
    Sum = 0;

DoCurrentCell:  // Add the current cell to the sum.
    
    // For each dimension.
    CellOffset = 0;
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[d] * Index[d];
    }
    
    // Add the offset of the last dimension.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = &A->Data[CellOffset];

NextCell:
    
    // Store the cell value.
    // Accumulate the sum.
    Sum += *ACell;
    
    // Advance to next cell.
    ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < (u32) E->Hi[LastDim] )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        for( d = LastDim; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
            }
        }
        
        // If the first dimension exceeds its bounds
        // then we are done.
        if( Index[0] == (u32) E->Hi[0] )
        {
            goto Done;
        }
    }
    
    goto DoCurrentCell;

Done:
    return( Sum );
}   

/*------------------------------------------------------------
| SumOf4DIntegerExtent
|-------------------------------------------------------------
|
| PURPOSE: To add up the values of each cell in an orthogonal 
|          region of a 4-dimensional integer array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: Add up the cells in an extent of a four 
| dimensional array with dimensions 3 x 5 x 6 x 8.  
| 
| The extent cells range from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32              DimExtent[4];
|      s32              Lo[4];
|      s32              Hi[4];
|      IntegerArray*    A;
|      Extent*          E;
|      f64*             v;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeIntegerArray( 4, DimExtent );
|
|      Lo[0] = 1;
|      Lo[1] = 2;
|      Lo[2] = 3;
|      Lo[3] = 4;
|
|      Hi[0] = 3; // Upper bound is one larger than the 
|      Hi[1] = 4; // address of the last cell in the extent.
|      Hi[2] = 5;
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
| 
|      v = SumOf4DIntegerExtent( A, E );
|
| NOTE: 
|
| ASSUMES: Array dimension count is 4. 
|          The extent isn't empty.
|          Expects an integer array.
|          Extent of the last dimension is less than 67K.
|           
| HISTORY: 06.12.96 from 'SumOfIntegerExtent'.
------------------------------------------------------------*/
f64
SumOf4DIntegerExtent( Array* A, Extent* E )
{
    u16*    ACell;
    u16*    Data;
    f64 Sum;
    u32     CellOffset;
    u32     Hi0, Hi1, Hi2, Hi3;
    u32     Lo1, Lo2, Lo3;
    u32     Index0,Index1,Index2, Index3;  
    u32     DimOffsetFactor0;
    u32     DimOffsetFactor1;
    u32     DimOffsetFactor2;
    u32     IntSum;
      
    // Refer to the data as integers.
    Data = (u16*) A->Data;
    
    // Get the extent limits to local variables.
    Lo1 = (u32) E->Lo[1];
    Lo2 = (u32) E->Lo[2];
    Lo3 = (u32) E->Lo[3];

    Hi0 = (u32) E->Hi[0];
    Hi1 = (u32) E->Hi[1];
    Hi2 = (u32) E->Hi[2];
    Hi3 = (u32) E->Hi[3];
    
    // For each dimension set the index to the start of
    // the orthogonal region; get dimension offsets.

    // Refer to the first cell in each extent. 
    Index0 = (u32) E->Lo[0];
    Index1 = Lo1;
    Index2 = Lo2;
    Index3 = Lo3;
        
    // Get dimension offset factors for speed.
    DimOffsetFactor0 = A->DimOffsetFactor[0];
    DimOffsetFactor1 = A->DimOffsetFactor[1];
    DimOffsetFactor2 = A->DimOffsetFactor[2];
    
    // Begin adding up the cells.
    
    // Clear the integer and floating point sums.
    Sum    = 0;
    IntSum = 0;

DoCurrentCell:  // Add the current cell to the sum.
    
    // Calculate the cell offset.
    CellOffset = DimOffsetFactor0 * Index0 +
                 DimOffsetFactor1 * Index1 +
                 DimOffsetFactor2 * Index2 +
                 Index3;
    
    // Refer to the 16-bit integer cell.
    ACell = (u16*)
            (((u8*) Data) + (CellOffset << 1));
    
NextCell:
    
    // Store the cell value.
    // Accumulate the sum to an integer; advance to next cell.
    IntSum += *ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index3++;
    
    if( Index3 < Hi3 )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        // Accumulate the floating point sum and 
        // reset integer sum.
        Sum += (f64) IntSum;
        IntSum = 0;
        
        // Reset index of the last dimension.
        Index3 = Lo3;
        
        // Increment next outer dimension.
        Index2++;
        
        // If end of this dimension reached.
        if( Index2 == Hi2 )
        {
            // Reset to lower bound.
            Index2 = Lo2;
                
            // Increment next outer dimension.
            Index1++;
                
            if( Index1 == Hi1 )
            {
                // Reset to lower bound.
                Index1 = Lo1;
                
                // Increment next outer dimension.
                Index0++;
                
                // If the first dimension exceeds its 
                // bounds then we are done.
                if( Index0 == Hi0 )
                {
                    goto Done;
                }
            }
        }
    }
    
    goto DoCurrentCell;

Done:
    return( Sum );
}   

/*------------------------------------------------------------
| SumOfIntegerExtent
|-------------------------------------------------------------
|
| PURPOSE: To add up the values of each cell in an orthogonal 
|          region of an integer array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array. The 'Lo' bound is the first
| cell to be included in the region and the 'Hi' bound is one
| larger than the last cell to be included in the region.
|
| EXAMPLE: Add up the cells in an extent of a four 
| dimensional array with dimensions 3 x 5 x 6 x 8.  
| 
| The extent cells range from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32          DimExtent[4];
|      s32          Lo[4];
|      s32              Hi[4];
|      IntegerArray*    A;
|      Extent*          E;
|      f64*             v;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeIntegerArray( 4, DimExtent );
|
|      Lo[0] = 1;
|      Lo[1] = 2;
|      Lo[2] = 3;
|      Lo[3] = 4;
|
|      Hi[0] = 3; // Upper bound is one larger than the 
|      Hi[1] = 4; // address of the last cell in the extent.
|      Hi[2] = 5;
|      Hi[3] = 6;
|
|      E = MakeExtent( 4, Lo, Hi );
| 
|      v = SumOfIntegerExtent( A, E );
|
| NOTE: 
|
| ASSUMES: Array dimension matches the extent. 
|          The extent isn't empty.
|          Expects an integer array.
|          Extent of the last dimension is less than 67K.
|           
| HISTORY: 06.08.96 from 'SumOfExtent'. 
|          06.12.96 optimized for speed.
------------------------------------------------------------*/
f64
SumOfIntegerExtent( Array* A, Extent* E )
{
    u16*    ACell;
    u16*    Data;
    f64 Sum;
    u32     DimCount, d, LastDim, CellOffset;
    u32     LastDimIndex, LastDimHi, LastDimLo;
    u32     Index[MaxArrayDimensions];  
    u32     DimOffsetFactor[MaxArrayDimensions];
    u32     IntSum;
      
    // Refer to the data as intergers.
    Data = (u16*)A->Data;
    
    // Get the number of dimensions.
    DimCount = A->DimCount;
    
    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;

    // For each dimension set the index to the start of
    // the orthogonal region; get dimension offsets.
    for( d = 0; d < LastDim; d++ )
    {
        // Refer to the first cell in this extent. 
        Index[d] = (u32) E->Lo[d];
        
        // Get dimension offset factor for speed.
        DimOffsetFactor[d] = A->DimOffsetFactor[d];
    }
    
    // Handle the last dimension in fast variables.
    LastDimHi    = (u32) E->Hi[LastDim];
    LastDimLo    = (u32) E->Lo[LastDim];
    LastDimIndex = LastDimLo;
    
    // Begin adding up the cells.
    
    // Clear the integer and floating point sums.
    IntSum = 0;
    Sum = 0;

DoCurrentCell:  // Add the current cell to the sum.
    
    // For each dimension except the last one.
    CellOffset = LastDimIndex;
    for( d = 0; d < LastDim; d++ )
    {
        // Accumulate the cell offset.
        CellOffset += DimOffsetFactor[d] * Index[d];
    }
    
    // Refer to the 16-bit integer cell.
    ACell = &Data[CellOffset];
    
NextCell:
    
    // Store the cell value.
    // Accumulate the sum to an integer.
    IntSum += *ACell;
    
    // Advance to next cell.
    ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    LastDimIndex++;
    
    if( LastDimIndex < LastDimHi )
    {
        // More in this run, so do them.
        goto NextCell;
    }
    else // End of last dimension reached.
         // adjust the indices.
    {
        // Accumulate the floating point sum and 
        // reset integer sum.
        Sum += (f64) IntSum;
        IntSum = 0;
        
        // Reset index of the last dimension.
        LastDimIndex = LastDimLo;
        
        // Increment next outer dimension.
        Index[LastDim-1]++;
        
        for( d = LastDim-1; d > 0; d-- )
        {
            // If end of this dimension reached.
            if( Index[d] == (u32) E->Hi[d] )
            {
                // Reset to lower bound.
                Index[d] = (u32) E->Lo[d];
                
                // Increment next outer dimension.
                Index[d-1]++;
                
                if( d == 1 )
                {
                    // If the first dimension exceeds its 
                    // bounds then we are done.
                    if( Index[0] == (u32) E->Hi[0] )
                    {
                        goto Done;
                    }
                }
            }
            else // If not end of this dim then can't be
                 // end of others.
            {
                break;
            }
        }
    }
    
    goto DoCurrentCell;

Done:
    return( Sum );
}   

/*------------------------------------------------------------
| UniteExtents
|-------------------------------------------------------------
|
| PURPOSE: To find the union of extent list 'A' with 
|          extent list 'B'. 
|
| DESCRIPTION: Creates a new list of extent records 
| consisting of the disjunction of the first list with the
| second.  In other words, after joining, all of the cells
| that were referred to in 'A' and 'B' separately are now
| referred to by a single list of extents, with no 
| duplication of reference.
|
| EXAMPLE:  C = UniteExtents( A, B );
|
| NOTE: 
|
| ASSUMES: The given lists each contain disjoint extents.
|           
| HISTORY: 03.07.96 from 'IntersectExtents'. 
------------------------------------------------------------*/
List*
UniteExtents( List* A, List* B )
{
    List*   Result;
    List*   AA;
    List*   BB;
    List*   AAA;
    List*   BBB;
    List*   AB;
    u32     IsSubsumed;
    u32     IsIntersecting;
    
    // Create the result list.
    Result = MakeList();

    // Make duplicate working lists of 'A' and 'B'.
    AA = DuplicateList( A );
    BB = DuplicateList( B );
        
    // 
    //     R E M O V E   S U B S U M E D   E X T E N T S
    //
    IsSubsumed = MarkSubsumedExtents( AA, BB );
    
    if( IsSubsumed )
    {
        // Delete items referring to subsumed extents.
        if( IsListMarked( AA ) )
        {
            DeleteMarkedItems( AA );
        }
        
        if( IsListMarked( BB ) )
        {
            DeleteMarkedItems( BB );
        }
    }   

    //
    //     M A R K   I N T E R S E C T I N G   E X T E N T S
    //
    IsIntersecting = MarkIntersectingExtents( AA, BB );

    if( IsIntersecting )
    {
        // Make new lists containing just the intersecting
        // items.
        AAA = ExtractMarkedItems( AA );
        BBB = ExtractMarkedItems( BB );
        
        // Join the independent items to the result list and
        // delete the lists.
        JoinLists( Result, AA ); // Also deletes 'AA'.
        JoinLists( Result, BB ); // Also deletes 'BB'.
        
        // Merge the intersecting lists into a single list
        // of disjoint extents; also deletes the given
        // lists.
        AB = MergeIntersectingExtents( AAA, BBB );
        
        // Append the merged list to the result and delete
        // the merged list.
        JoinLists( Result, AB );
    }
    else // No overlap between lists so they can just be joined.
    {
        JoinLists( Result, AA ); // Also deletes 'AA'.
        JoinLists( Result, BB ); // Also deletes 'BB'.
    }
        
    // Return the result list.
    return( Result );
}

/*------------------------------------------------------------
| ValidateExtentInArray
|-------------------------------------------------------------
|
| PURPOSE: To test whether an extent is valid with respect
|          to an array.
|
| DESCRIPTION: Expects an extent record specifying the bounds
| of the region in the array.  Halts in the debugger if the
| extent isn't entirely in the array or if the dimensions
| don't match.  Otherwise, just returns.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.16.96 
------------------------------------------------------------*/
void
ValidateExtentInArray( Array* A, Extent* E )
{
    // Make sure the extent is in the array.
    if( ! IsExtentInArray( A, E ) )
    {
        Debugger();
    }
}

