/*------------------------------------------------------------
| TLMatrixExtra.c
|-------------------------------------------------------------
|
| PURPOSE: To provide less commonly used matrix functions.
|
| HISTORY: 01.26.00 From 'TLMatrix.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"  
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLMatrixAlloc.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLList.h"
#include "TLListIO.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLStacks.h"
#include "TLParse.h"  // for 'ParseDatum'
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLNumber.h" // for 'ConvertStringToNumber'
                      // and 'ConvertNumberToString'
#include "TLDate.h" 
#include "TLItems.h"
#include "TLVector.h"
#include "TLPoints.h"
#include "TLArray.h"
#include "TLGeometry.h"
#include "TLRandom.h"
#include "TLSubRandom.h"
#include "TLWeight.h"
#include "TLStat.h"
#include "TLPointList.h"
//#include "TLWin.h"
//#include "TLLog.h"
#include "TLOrdinal.h"
#include "TLf64.h"
#include "TLMatrixCopy.h"
#include "TLMatrixMath.h"
#include "TLMatrixExtra.h"

/*------------------------------------------------------------
| ColumnToVector
|-------------------------------------------------------------
|
| PURPOSE: To allocate a vector and copy a column of a matrix
|          to the X part of that space.
|
| DESCRIPTION: 
|
| EXAMPLE: AVector = ColumnToVector( AMatrix, 10L );
|
| NOTE: 
|
| ASSUMES: Enough memory.
|           
| HISTORY: 03.30.96 from 'CopyColumnToNewBuffer'.
------------------------------------------------------------*/
Vector*
ColumnToVector( Matrix* AMatrix, u32 Column )
{
    Vector* V;
    f64*    X;
    u32     RowCount, r;
    f64**   a;
    
    RowCount = AMatrix->RowCount;
    a = (f64**) AMatrix->a;
    
    // Allocate the memory.
    V = MakeVector( RowCount, 0, 0 );
    V->IsY = 0;
    
    // For each row.
    X = V->X;
    for( r = 0; r < RowCount; r++ )
    {
        *X++ = a[ r ][ Column ];
    }
    
    return( V );
}

/*------------------------------------------------------------
| ColumnToVectorY
|-------------------------------------------------------------
|
| PURPOSE: To allocate a vector and copy a column of a matrix
|          to the Y part of that space.
|
| DESCRIPTION: 
|
| EXAMPLE: AVector = ColumnToVectorY( AMatrix, 10L );
|
| NOTE: 
|
| ASSUMES: Enough memory.
|           
| HISTORY: 03.30.96 from 'CopyColumnToNewBuffer'.
------------------------------------------------------------*/
Vector*
ColumnToVectorY( Matrix* AMatrix, u32 Column )
{
    Vector* V;
    f64     *Y;
    u32     RowCount, r;
    f64**   a;
    
    RowCount = AMatrix->RowCount;
    a = (f64**) AMatrix->a;
    
    // Allocate the memory.
    V = MakeVector( RowCount, 0, 0 );
    V->IsX = 0;
    
    // For each row.
    Y = V->Y;
    for( r = 0; r < RowCount; r++ )
    {
        *Y++ = a[ r ][ Column ];
    }
    
    return( V );
}

/*------------------------------------------------------------
| CopyRandomRows
|-------------------------------------------------------------
|
| PURPOSE: To copy randomly chosen rows from one matrix
|          to another.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 05.11.97
|          01.25.00 From 'CopyIndexedRows'.
------------------------------------------------------------*/
void
CopyRandomRows( Matrix* From, Matrix* To, u32 Count ) 
{
    u8**    F;
    u8**    T;
    u32     BytesPerCell;
    u32     BytesPerRow;
    u32     i, j;
    u32     FromRowCount;
    
    // Calculate the number of bytes per cell.
    BytesPerCell = From->BitsPerCell >> 3;
    
    // Calculate the number of bytes in a row of cells.
    BytesPerRow = From->ColCount * BytesPerCell;
    
    F = (u8**) From->a;
    T = (u8**) To->a;

    FromRowCount = From->RowCount;
    
    // For the given number of rows.               
    for( i = 0; i < Count; i++ )
    {
        // Select a random source row.
        j = (u32) RandomInteger( (s32) FromRowCount );
        
        // Copy the data from the source to the beginning
        // of the target array, filling downward.
        memcpy( T[i], F[j], BytesPerRow );
    }
}

/*------------------------------------------------------------
| CopySubRandomRows
|-------------------------------------------------------------
|
| PURPOSE: To copy subrandomly chosen rows from one matrix
|          to another.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 05.11.97
|          01.25.00 From 'CopyRandomRows'.
------------------------------------------------------------*/
void
CopySubRandomRows( Matrix* From, Matrix* To, u32 Count ) 
{
    u8**    F;
    u8**    T;
    u32     BytesPerCell;
    u32     BytesPerRow;
    u32     i, j;
    u32     FromRowCount;
    
    // Calculate the number of bytes per cell.
    BytesPerCell = From->BitsPerCell >> 3;
    
    // Calculate the number of bytes in a row of cells.
    BytesPerRow = From->ColCount * BytesPerCell;
    
    F = (u8**) From->a;
    T = (u8**) To->a;

    FromRowCount = From->RowCount;
    
    // For the given number of rows.               
    for( i = 0; i < Count; i++ )
    {
        // Select a random source row.
        j = (u32) SubRandomInteger( (s32) FromRowCount );
        
        // Copy the data from the source to the beginning
        // of the target array, filling downward.
        memcpy( T[i], F[j], BytesPerRow );
    }
}

/*------------------------------------------------------------
| DeleteListOfMatrices
|-------------------------------------------------------------
|
| PURPOSE: To delete a list of dynamically allocated matrices.
|
| DESCRIPTION: 
|
| EXAMPLE: DeleteListOfMatrices( MatrixList );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.02.96 
------------------------------------------------------------*/
void
DeleteListOfMatrices( List* MatrixList )
{
    ReferToList( MatrixList );
    
    while( TheItem )
    {
        if( TheDataAddress )
        {
            DeleteMatrix( (Matrix*) TheDataAddress );
        }
            
        ToNextItem();
    }
    
    RevertToList();
    
    DeleteList( MatrixList );
}

/*------------------------------------------------------------
| FindMissingCellWithMostNeighbors
|-------------------------------------------------------------
|
| PURPOSE: To test if there is at least one missing value in
|          a matrix, and if so return the cell address of
|          the missing value with the most known neighbors.
|
| DESCRIPTION: Returns '1' if a missing value was found.
|
| EXAMPLE:  while( 
|             FindMissingCellWithMostNeighbors( 
|                      AMatrix, &r, &c ) )
|
| NOTE: Missing values == 'NoNum'.
|
| ASSUMES:  
|           
| HISTORY: 01.25.96
------------------------------------------------------------*/
u32  
FindMissingCellWithMostNeighbors( Matrix* AMatrix, 
                                  u32*    AtRow,
                                  u32*    AtCol )
{
    u32     r, c;
    f64**   A;
    u32     rows;
    u32     cols;
    u32     rmost, cmost;
    u32     mostneighbors;
    u32     IsMissingCell;
    u32     lastcol;
    u32     lastrow;
    u32     neighbors;
    
    IsMissingCell = 0;
    
    A = (f64**) AMatrix->a;
    
    rows = AMatrix->RowCount;
    cols = AMatrix->ColCount;
    
    lastcol = cols - 1;
    lastrow = rows - 1;
    
    mostneighbors = 0;
    
    for( r = 0; r < rows; r++ )
    {
        for( c = 0; c < cols; c++ )
        {
            if( A[r][c] == NoNum )
            {
                IsMissingCell = 1;
                neighbors = 0;
                
                // Count known neighbors.
                if( r == 0 ) // in first row.
                {
                    if( c == 0 ) // in first column: 3 possible.
                    {
                        if( A[r][c+1]   != NoNum ) neighbors++;
                        if( A[r+1][c+1] != NoNum ) neighbors++;
                        if( A[r+1][c]   != NoNum ) neighbors++;
                    }
                    else
                    {
                        if( c == lastcol ) // in last column: 3 possible.
                        {
                            if( A[r][c-1]   != NoNum ) neighbors++;
                            if( A[r+1][c-1] != NoNum ) neighbors++;
                            if( A[r+1][c]   != NoNum ) neighbors++;
                        }
                        else // Middle of first row: 5 possible.
                        {
                            if( A[r][c-1]   != NoNum ) neighbors++;
                            if( A[r][c+1]   != NoNum ) neighbors++;
                            if( A[r+1][c-1] != NoNum ) neighbors++;
                            if( A[r+1][c]   != NoNum ) neighbors++;
                            if( A[r+1][c+1] != NoNum ) neighbors++;
                        }
                    }
                        
                    goto TestMost;
                }
                    
                if( r == lastrow ) // in last row.
                {
                    if( c == 0 ) // in first column: 3 possible.
                    {
                        if( A[r][c+1]   != NoNum ) neighbors++;
                        if( A[r-1][c+1] != NoNum ) neighbors++;
                        if( A[r-1][c]   != NoNum ) neighbors++;
                    }
                    else
                    {
                        if( c == lastcol ) // in last column: 3 possible.
                        {
                            if( A[r][c-1]   != NoNum ) neighbors++;
                            if( A[r-1][c-1] != NoNum ) neighbors++;
                            if( A[r-1][c]   != NoNum ) neighbors++;
                        }
                        else // Middle of last row: 5 possible.
                        {
                            if( A[r][c-1]   != NoNum ) neighbors++;
                            if( A[r][c+1]   != NoNum ) neighbors++;
                            if( A[r-1][c-1] != NoNum ) neighbors++;
                            if( A[r-1][c]   != NoNum ) neighbors++;
                            if( A[r-1][c+1] != NoNum ) neighbors++;
                        }
                    }
                        
                    goto TestMost;
                }
                    
                if( c == 0 ) // Middle of first column: 5 possible.
                {
                    if( A[r-1][c]   != NoNum ) neighbors++;
                    if( A[r-1][c+1] != NoNum ) neighbors++;
                    if( A[r][c+1]   != NoNum ) neighbors++;
                    if( A[r+1][c+1] != NoNum ) neighbors++;
                    if( A[r+1][c]   != NoNum ) neighbors++;
                        
                    goto TestMost;
                }
                    
                if( c == lastcol ) // Middle of last column: 5 possible.
                {
                    if( A[r-1][c]   != NoNum ) neighbors++;
                    if( A[r-1][c-1] != NoNum ) neighbors++;
                    if( A[r][c-1]   != NoNum ) neighbors++;
                    if( A[r+1][c-1] != NoNum ) neighbors++;
                    if( A[r+1][c]   != NoNum ) neighbors++;
                        
                    goto TestMost;
                }
                    
                // Non-border cell is missing.
                if( A[r-1][c-1] != NoNum ) neighbors++;
                if( A[r-1][c]   != NoNum ) neighbors++;
                if( A[r-1][c+1] != NoNum ) neighbors++;
                if( A[r][c-1]   != NoNum ) neighbors++;
                if( A[r][c+1]   != NoNum ) neighbors++;
                if( A[r+1][c-1] != NoNum ) neighbors++;
                if( A[r+1][c]   != NoNum ) neighbors++;
                if( A[r+1][c+1] != NoNum ) neighbors++;
                
TestMost:       // Update the most.
                if( neighbors > mostneighbors )
                {
                    mostneighbors = neighbors;
                    rmost = r;
                    cmost = c;
                }                   

                // void can have more than eight neighbors.
                if( neighbors == 8 )
                {
                    goto Done;
                }
            }
        }
    }

Done:
    
    *AtRow = rmost;
    *AtCol = cmost;
    
    return( IsMissingCell );
}

/*------------------------------------------------------------
| FillMissingValuesInMatrix
|-------------------------------------------------------------
|
| PURPOSE: To fill in unknown values in a matrix using the
|          known values.
|
| DESCRIPTION: Unknown values are marked using the 'NoNum'
| value.  Fills in values with the most neighbors first and 
| then progresses to cells with fewer neighbors.  Computes 
| fill value by estimating the median of known neighbors.
|
| Returns number of missing cell filled.
|
| EXAMPLE: FillMissingValuesInMatrix( AMatrix );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.25.96 from 'SmoothMatrixEstimatedMedian'.
------------------------------------------------------------*/
s32
FillMissingValuesInMatrix( Matrix* AMatrix )
{
    f64     AtSample[8];
    f64     AtWork[8];
    u32     r, c;
    u32     rows;
    u32     cols;
    s32     K;
    f64**   A;
    s32     FillCount;
    
    FillCount = 0;
        
    rows = AMatrix->RowCount;
    cols = AMatrix->ColCount;
        
    A = (f64**) AMatrix->a;

    while( FindMissingCellWithMostNeighbors( AMatrix, &r, &c ) )
    {
        // Keep track of the number of cells filled.
        FillCount++;
        
        // Reset the known neighbor counter.
        K = 0;
        
        // For upper border.
        if( r == 0 )
        {
            // For upper left corner use 3-neighbor median.
            if( c == 0 )
            {
                if( A[r][c+1]   != NoNum ) AtSample[K++] = A[r][c+1] ;
                if( A[r+1][c+1] != NoNum ) AtSample[K++] = A[r+1][c+1];
                if( A[r+1][c]   != NoNum ) AtSample[K++] = A[r+1][c];
            }
            else
            {
                // For upper right corner use 3-neighbor median.
                if( c == (cols - 1) )
                {
                    if( A[r][c-1]   != NoNum ) AtSample[K++] = A[r][c-1];
                    if( A[r+1][c-1] != NoNum ) AtSample[K++] = A[r+1][c-1];
                    if( A[r+1][c]   != NoNum ) AtSample[K++] = A[r+1][c];
                }
                else // For middle of top border.
                {
                    if( A[r][c-1]   != NoNum ) AtSample[K++] = A[r][c-1];
                    if( A[r][c+1]   != NoNum ) AtSample[K++] = A[r][c+1];
                    if( A[r+1][c-1] != NoNum ) AtSample[K++] = A[r+1][c-1];
                    if( A[r+1][c]   != NoNum ) AtSample[K++] = A[r+1][c];
                    if( A[r+1][c+1] != NoNum ) AtSample[K++] = A[r+1][c+1];
                }
            }
            
            goto Next;
        }
        
        // For lower border.
        if( r == (rows - 1) )
        {
            // For lower left corner use 3-neighbor median.
            if( c == 0 )
            {
                if( A[r-1][c]   != NoNum ) AtSample[K++] = A[r-1][c];
                if( A[r-1][c+1] != NoNum ) AtSample[K++] = A[r-1][c+1];
                if( A[r][c+1]   != NoNum ) AtSample[K++] = A[r][c+1];
            }
            else
            {
                // For lower right corner use 3-neighbor median.
                if( c == (cols - 1) )
                {
                    if( A[r-1][c]   != NoNum ) AtSample[K++] = A[r-1][c];
                    if( A[r-1][c-1] != NoNum ) AtSample[K++] = A[r-1][c-1];
                    if( A[r][c-1]   != NoNum ) AtSample[K++] = A[r][c-1];
                }
                else // For middle of bottom border.
                {
                    if( A[r][c-1]   != NoNum ) AtSample[K++] = A[r][c-1];
                    if( A[r][c+1]   != NoNum ) AtSample[K++] = A[r][c+1];
                    if( A[r-1][c-1] != NoNum ) AtSample[K++] = A[r-1][c-1];
                    if( A[r-1][c]   != NoNum ) AtSample[K++] = A[r-1][c];
                    if( A[r-1][c+1] != NoNum ) AtSample[K++] = A[r-1][c+1];
                }
            }
            
            goto Next;
        }
        
        // For middle of left border.
        if( c == 0 )
        {
            if( A[r-1][c]   != NoNum ) AtSample[K++] = A[r-1][c];
            if( A[r+1][c]   != NoNum ) AtSample[K++] = A[r+1][c];
            if( A[r-1][c+1] != NoNum ) AtSample[K++] = A[r-1][c+1];
            if( A[r][c+1]   != NoNum ) AtSample[K++] = A[r][c+1];
            if( A[r+1][c+1] != NoNum ) AtSample[K++] = A[r+1][c+1];
                    
            goto Next;
        }
        
        // For middle of right border.
        if( c == (cols - 1) )
        {
            if( A[r-1][c]   != NoNum ) AtSample[K++] = A[r-1][c];
            if( A[r+1][c]   != NoNum ) AtSample[K++] = A[r+1][c];
            if( A[r-1][c-1] != NoNum ) AtSample[K++] = A[r-1][c-1];
            if( A[r][c-1]   != NoNum ) AtSample[K++] = A[r][c-1];
            if( A[r+1][c-1] != NoNum ) AtSample[K++] = A[r+1][c-1];

            goto Next;
        }
        
        // For non-border cell.
        if( A[r-1][c-1] != NoNum ) AtSample[K++] = A[r-1][c-1];
        if( A[r-1][c]   != NoNum ) AtSample[K++] = A[r-1][c];
        if( A[r-1][c+1] != NoNum ) AtSample[K++] = A[r-1][c+1];
        if( A[r][c-1]   != NoNum ) AtSample[K++] = A[r][c-1];
        if( A[r][c+1]   != NoNum ) AtSample[K++] = A[r][c+1];
        if( A[r+1][c-1] != NoNum ) AtSample[K++] = A[r+1][c-1];
        if( A[r+1][c]   != NoNum ) AtSample[K++] = A[r+1][c];
        if( A[r+1][c+1] != NoNum ) AtSample[K++] = A[r+1][c+1];
        
Next:
        A[r][c] = EstimateMedian( AtSample, AtWork, K );
    }
    
    return( FillCount );
}

/*------------------------------------------------------------
| GetCellByKey
|-------------------------------------------------------------
|
| PURPOSE: To return the contents of the cell at a given 
|          column and row indexed by the contents of the
|          first column, the key.
|
| DESCRIPTION: 
|
| EXAMPLE: InCell = GetCellByKey( MyMatrix, 930, 1 );
|
| NOTE:  
|
| ASSUMES: Keys are in ascending order.
|           
| HISTORY: 07.13.97
------------------------------------------------------------*/
f64 
GetCellByKey( Matrix* A, f64 Key, u32 Column )
{
    u32 Row;
    f64** a;
 
    a = (f64**) A->a;
    
    Row = IndexOfNearestKey( A, (s32) Key );
    
    return( a[ Row ][ Column ] );
}

/*------------------------------------------------------------
| GetMatrixExtremes
|-------------------------------------------------------------
|
| PURPOSE: To find the smallest and largest values in a matrix.
|
| DESCRIPTION:  
|
| EXAMPLE: GetMatrixExtremes( A, &Min, &Max );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.26.96
|          04.01.96 converted to use 'ExtentOfItems'.
|          01.30.00 Revised to use 'AtCell'.
------------------------------------------------------------*/
void
GetMatrixExtremes( Matrix* AMatrix, f64* AtMin, f64* AtMax )
{
    u32     CellCount;
    f64*    AtCells;
    
    CellCount = AMatrix->RowCount * AMatrix->ColCount;
    
    AtCells = (f64*) AtCell( AMatrix,
                             AMatrix->LoRowIndex,
                             AMatrix->LoColIndex );

    ExtentOfItems( AtCells, CellCount, AtMin, AtMax );
}

/*------------------------------------------------------------
| IndexOfKey
|-------------------------------------------------------------
|
| PURPOSE: To find the index of a row in an ordered 
|          matrix that has a certain key field value.
|
| DESCRIPTION: This procedure locates the record index of a 
| given key in an ordered matrix.
|
| If the key is not found in the matrix, the index of the
| place where the record would be inserted is returned. 
|
| May return index of record one beyond the last record in the 
| table if the key follows the last record.
|
| An ordered matrix is one in which the first column holds 
| integral key values that don't decrease from one row to the 
| next.  In other words, the rows are sorted by the key field
| in ascending order with an allowance for duplicate key
| values.
|
| EXAMPLE:  
|
|   FirstDateIndex = IndexOfKey( CopperDateAndPrice, t );
|
| NOTE: Uses a binary search for speed.
|
| ASSUMES: First column in matrix holds the integer key values.
|          The keys are in increasing order.
|
| HISTORY:  01.16.96 from 'FindPlaceInTheLargeUnitDirectory'.
|           01.01.97 name changed from 'IndexOfDate'.
------------------------------------------------------------*/
u32
IndexOfKey( Matrix* AMatrix, s32 Key )
{
    u32     RowCount;
    s32     KeyInRow;
    f64**   A;
    s32     Hi, Lo, Mid, Cond; 
    
    RowCount = AMatrix->RowCount;
    A = (f64**) AMatrix->a;

    // Binary search matrix, which is maintained
    // in increasing date order.  Returns the record
    // address of where a matching date is or
    // should be.

    // Binary search; table must be in 
    // ascending order.
    Lo = 0;  
    Hi = (s32) RowCount - 1;
    
    while( Lo <= Hi )
    {
        Mid = (Hi + Lo) >> 1; // (Hi+Lo)/2  

        KeyInRow = (s32) A[Mid][0];
        
        Cond = Key - KeyInRow;    

        if( Cond == 0 )
        {    
            // Exact match.
            return( (u32) Mid );
        }

        if( Cond < 0 )  // Key < KeyInRow
        {
            Hi = Mid - 1;
        }
        else // Key > KeyInRow
        {
            Lo = Mid + 1;
        }
    }
    
    // If no exact match is found, use the place referred to by
    // the current value of 'Lo', which on exit from the above
    // loop is 1 higher than 'Hi'.
    
    return( (u32) Lo );
}

/*------------------------------------------------------------
| IndexOfNearestKey
|-------------------------------------------------------------
|
| PURPOSE: To find the index of a row in an ordered 
|          matrix that most nearly matches a certain key value.
|
| DESCRIPTION: This procedure locates the record index of the
| nearest key before or after a given key in an ordered matrix.
|
| EXAMPLE:  
|
|   n = IndexOfNearestKey( CopperDateAndPrice, t );
|
| NOTE: 
|
| ASSUMES: First column in matrix holds the integer key values.
|          The keys are in non-decreasing order.
|
| HISTORY: 01.01.97  
------------------------------------------------------------*/
u32
IndexOfNearestKey( Matrix* A, s32 Key )
{
    u32     i;
    s32     iKey, nKey, pKey;
    f64**   a;
    
    // Search for an exact match.
    i = IndexOfKey( A, Key );
    
    // Limit i to the array.
    if( i >= A->RowCount )
    {
        i = A->RowCount - 1; // Last row.
        
        // No row follows so this is the nearest.
        return( i );
    }
    
    // Refer to the matrix using standard C array syntax.
    a = (f64**) A->a;
    
    // Get the key of the row located.
    iKey = (s32) a[i][0];
    
    // Test for an exact match.
    if( iKey == Key )
    {
        // Exact match found.
        return( i );
    }
    
    // If the key of the prior row is nearer, make that 
    // the row.
    if( i > 0 ) // If not the first row.
    {
        // Get the key of the prior row.
        pKey = (s32) a[i-1][0];
        
        // Select the smaller difference.
        if( abs( pKey - Key ) < abs( iKey - Key ) )
        {
            // Prior is nearer...
            i--;
            
            // ... which means the next one isn't, so return.
            return( i );
        }
    }
        
    // If the key of the next row is nearer, make that the
    // row.
    if( i < (A->RowCount - 1) ) // If not the last row.
    {
        // Get the key of the next row.
        nKey = (s32) a[i+1][0];
        
        // Select the smaller difference.
        if( abs( nKey - Key ) < abs( iKey - Key ) )
        {
            // Next is nearer.
            i++;
        }
    }
    
    // Return the row index.
    return( i );
}

/*------------------------------------------------------------
| InvertIntoMatrix
|-------------------------------------------------------------
|
| PURPOSE: To invert a region of a matrix into another, 
|          analogous to the xor function.
|
| DESCRIPTION: Given the upper-cell in a matrix, together with
| the number of rows and columns which be copied and a 
| target matrix and upper-left cell.
|
| EXAMPLE: InvertIntoMatrix( AMatrix, 10L, 10L, 4L, 4L,
|                            ToMatrix, 0L,  0L );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 07.15.97 from CopyRegionOfMatrix.
------------------------------------------------------------*/
void
InvertIntoMatrix( Matrix* SourceMatrix,
                  s32     SourceUpperRow,
                  s32     SourceLeftColumn, 
                  s32     ARowCount,
                  s32     AColumnCount,
                  Matrix* TargetMatrix,
                  s32     TargetUpperRow,
                  s32     TargetLeftColumn )
{
    s32 i,j;
    s32 SrcRow, SrcCol, DstRow, DstCol;
    f64 t, s, d;
    f64**   S;
    f64**   T;
    
    S = (f64**) SourceMatrix->a;
    T = (f64**) TargetMatrix->a;
    
    for( i = 0; i < ARowCount; i++ )
    {
        for( j = 0; j < AColumnCount; j++ )
        {
            SrcRow = SourceUpperRow+i;
            SrcCol = SourceLeftColumn+j;
            DstRow = TargetUpperRow+i;
            DstCol = TargetLeftColumn+j;
            
            t = T[ DstRow ][ DstCol ];
            s = S[ SrcRow ][ SrcCol ];

            d = t - s;
            if( d < 0. ) d = -d;
            
            T[ DstRow ][ DstCol ] = 1. - d;
        }
    }
}

/*------------------------------------------------------------
| IsDateInMatrix
|-------------------------------------------------------------
|
| PURPOSE: To test if a date is listed in a dated matrix.
|
| DESCRIPTION: Returns '1' if the date is recorded in the
| matrix, '0' otherwise.
|
| The given date is in TradeTime format.
|
| EXAMPLE:  
|
|   f = IsDateInMatrix( CopperPrices, t );
|
| NOTE: 
|
|
| ASSUMES: First column in matrix holds the date in TradeTime
|          format.
|
| HISTORY:  01.16.96 from 'FindPlaceInTheLargeUnitDirectory'.
|           01.14.97 revised to used 'IndexOfNearestKey' 
|                    instead of 'IndexOfKey'.
------------------------------------------------------------*/
u32  
IsDateInMatrix( Matrix* AMatrix, u32 Date )
{
    u32     Row;
    u32     DateInRow;
    f64**   A;
    
    A = (f64**) AMatrix->a;

    Row = IndexOfNearestKey( AMatrix, (s32) Date );
    
    DateInRow = (u32) A[Row][0];
        
    return( DateInRow == Date );
}

/*------------------------------------------------------------
| IsEmptyMatrix
|-------------------------------------------------------------
|
| PURPOSE: To test if the entire matrix is filled with
|          'NoNum' values.
|
| DESCRIPTION: Missing values are marked using the value
| returned by 'NoNum' macro. 
|
| EXAMPLE: t = IsEmptyMatrix( AMatrix );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.26.96
|          01.30.00 Revised to use 'AtCell()'.
------------------------------------------------------------*/
u32  
IsEmptyMatrix( Matrix* AMatrix )
{
    u32     i;
    f64*    Cell;
    u32     CellCount;
    
    CellCount = AMatrix->RowCount * AMatrix->ColCount;
    
    Cell = (f64*) AtCell( AMatrix,
                          AMatrix->LoRowIndex,
                          AMatrix->LoColIndex );
    
    for( i = 0; i < CellCount; i++ )
    {
        if( *Cell++ != NoNum )
        {
            return( 0 );
        }
    }
    
    return( 1 );
}

/*------------------------------------------------------------
| IsMissingValueInMatrix
|-------------------------------------------------------------
|
| PURPOSE: To test if there is at least one missing value in
|          a matrix.
|
| DESCRIPTION: Missing values are marked using the value
| returned by 'NoNum' macro. 
|
| EXAMPLE:  while( IsMissingValueInMatrix( AMatrix ) )
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.25.96
|          01.30.00 Revised to use 'AtCell()'.
------------------------------------------------------------*/
u32  
IsMissingValueInMatrix( Matrix* AMatrix )
{
    u32     i;
    f64*    Cell;
    u32     CellCount;
    
    CellCount = AMatrix->RowCount * AMatrix->ColCount;
    
    Cell = (f64*) AtCell( AMatrix,
                          AMatrix->LoRowIndex,
                          AMatrix->LoColIndex );
    
    for( i = 0; i < CellCount; i++ )
    {
        if( *Cell++ == NoNum )
        {
            return( 1 );
        }
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| MakeDedupedOrderedMatrix
|-------------------------------------------------------------
| 
| PURPOSE: To make a new matrix from an existing one such that
|          there are no duplicate records and the records
|          are sorted in increasing order by the first field.
| 
| DESCRIPTION: More than one record can have the same first
| field value but at least one other field must differ.
|
| Fields within the chop tolerance are regarded as equal.
|
| EXAMPLE:  B = MakeDedupedOrderedMatrix( A );
|
| NOTE: See 'MakeDedupedOrderedMatrix2' for matrices that
|       allow only one record with a given first field value.
| 
| ASSUMES: 
| 
| HISTORY: 12.30.96 from 'MergeOrderedMatrices'.
------------------------------------------------------------*/
Matrix*
MakeDedupedOrderedMatrix( Matrix* A )
{
    List*   AList;
    Matrix* B;
    u32     RecordSize;
    
    // Make list that refer to each row of matrix.
    AList = MatrixToPointList( A );
    
    // Sort the list in ascending order using the entire
    // record.
    //
    // Calculate the record size to be used 
    // in 'SortListAsBinaryData'.
    RecordSize = sizeof(f64) * A->ColCount;
    
    SortListAsBinaryData( AList, RecordSize );
    
    // Delete extra records that say exactly the same thing,
    // within the chop tolerance.
    DeleteDuplicateDataPoints( AList );
    
    // Sort the records by the first field only.
    SortList( AList, (CompareProc) CompareItems );
    
    // Make the result matrix.
    B = PointListToMatrix( AList );
    
    // Discard the point list.
    DeleteList( AList );
    
    // Return the result.
    return( B );
}

/*------------------------------------------------------------
| MakeDedupedOrderedMatrix2
|-------------------------------------------------------------
| 
| PURPOSE: To make a new matrix from an existing such that
|          there are no duplicate records and the records
|          are sorted in increasing order by the first field.
| 
| DESCRIPTION: Only one record can have a given first
| field value.
|
| EXAMPLE:  B = MakeDedupedOrderedMatrix2( A );
|
| NOTE: See 'MakeDedupedOrderedMatrix' for matrices that
|       allow more than one record with a given first field 
|       value.
| 
| ASSUMES: 
| 
| HISTORY: 12.30.96 from 'MakeDedupedOrderedMatrix'.
------------------------------------------------------------*/
Matrix*
MakeDedupedOrderedMatrix2( Matrix* A )
{
    List*   AList;
    Matrix* B;
    
    // Make list that refer to each row of matrix.
    AList = MatrixToPointList( A );
    
    // Sort the list in ascending order using the first field 
    // in each record.
    SortList( AList, (CompareProc) CompareItems );

    // Delete extra records that have the same first field
    // value.
    DeleteDuplicateFieldReferences( AList, 0, sizeof(f64) );
    
    // Make the result matrix.
    B = PointListToMatrix( AList );
    
    // Discard the point list.
    DeleteList( AList );
    
    // Return the result.
    return( B );
}

/*------------------------------------------------------------
| MatrixToVector
|-------------------------------------------------------------
|
| PURPOSE: To allocate a vector and copy a 2-column matrix
|          to the vector.
|
| DESCRIPTION: 
|
| EXAMPLE: AVector = ColumnToVector( AMatrix, 10L );
|
| NOTE: 
|
| ASSUMES: Enough memory.
|           
| HISTORY: 03.30.96 from 'CopyColumnToNewBuffer'.
------------------------------------------------------------*/
Vector*
MatrixToVector( Matrix* AMatrix )
{
    Vector* V;
    f64     *X;
    f64     *Y;
    u32     RowCount, r;
    f64**   a;
    
    RowCount = AMatrix->RowCount;
    a = (f64**) AMatrix->a;
    
    // Allocate the memory.
    V = MakeVector( RowCount, 0, 0 );
    
    // For each row.
    X = V->X;
    Y = V->Y;
    for( r = 0; r < RowCount; r++ )
    {
        *X++ = a[ r ][ 0 ];
        *Y++ = a[ r ][ 1 ];
    }
    
    return( V );
}

/*------------------------------------------------------------
| MeanDataPoint
|-------------------------------------------------------------
|
| PURPOSE: To find the data point closest to the mean
|          of given points in an n-dimensional space.
|
| DESCRIPTION: Places the results at 'P'.
|
| EXAMPLE:  
|
| HISTORY: 05.02.96 from 'ModeDataPoint'.
|          01.26.00 Revised to use 'CopyRowToBuffer'.
------------------------------------------------------------*/
void
MeanDataPoint( Matrix* A, f64* P )
{
    s32 i;

    // Find the point in space closest to the median.
    MeanSpacePoint( A, P );
    
    // Find the actual data point closest to the space point.
    i = FindNearestOrdinalPoint( A, P );

    // Copy the nearest point to the result.
    CopyRowToBuffer( A, i, (u8*) P );
}

/*------------------------------------------------------------
| MeanDifferenceInMatrix
|-------------------------------------------------------------
|
| PURPOSE: To find the mean of the gaps between values 
|          in a matrix.
|
| DESCRIPTION:  
|
| EXAMPLE: s = MeanDifferenceInMatrix( V );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.14.96 from 'SmallestDifferenceInMatrix'.
|          01.30.00 Revised to use 'AtCell()'.
------------------------------------------------------------*/
f64
MeanDifferenceInMatrix( Matrix* AMatrix )
{
    u32     CellCount, i;
    f64*    AtCells;
    Matrix* DupMat;
    f64     Diff;
    f64     DiffSum, DiffCount;
    
    // Duplicate the matrix so it can be sorted.
    DupMat = DuplicateMatrix( AMatrix );
    
    CellCount = DupMat->RowCount * DupMat->ColCount;
    
    AtCells = (f64*) 
              AtCell( DupMat,
                      DupMat->LoRowIndex,
                      DupMat->LoColIndex ); 
    
    // Sort the value in increasing order.
    SortVector( AtCells, CellCount );

    DiffSum = 0;
    DiffCount = 0;
    
    for( i = 0; i < CellCount-1; i++ )
    {
        Diff = AtCells[i+1] - AtCells[i];
        
        if( Diff > 0 )
        {
            DiffSum += Diff;
            DiffCount++;
        }
    }
    
    DeleteMatrix( DupMat );
    
    return( DiffSum/DiffCount );
}

/*------------------------------------------------------------
| MeanSpacePoint
|-------------------------------------------------------------
|
| PURPOSE: To calculate the n-dimensional mean point in a
|          matrix of points.
|
| DESCRIPTION: Returns the space point of the mean.
|
| This routine treats each dimension independently for 
| computation of the mean, and places the results at 'P'.
|
| Since each dimension is treated independently, the resulting
| point is a point in space but may not be an actual data
| point.  Use the routine 'FindNearestOrdinalPoint' to pass
| from a data space point to an actual data point.
|
| Each point occupies one row in the matrix, with each column 
| devoted to a separate dimension.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 05.02.96 from 'MedianSpacePoint'.
------------------------------------------------------------*/
void
MeanSpacePoint( Matrix* A, f64* P )
{
    s32 i,DimCount;
    
    // Get the number of dimensions.
    DimCount = A->ColCount;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        P[i] = MeanOfColumn( A, i );
    }
}

/*------------------------------------------------------------
| MergeOrderedMatrices
|-------------------------------------------------------------
| 
| PURPOSE: To combine two matrices which are ordered by the
|          value in the first column to form a single
|          matrix. 
| 
| DESCRIPTION: 
|
|   1. Appends the records of matrix 'B' to the end
|      of 'A'.
|
|   2. Sorts all the records by the first field.
|
|   3. Deletes duplicate records. 
|
|   4. Returns the new matrix.
|
| EXAMPLE:  C = MergeOrderedMatrices( A, B );
|
| NOTE: See 'Intra.h' for '.IN' file format.
| 
| ASSUMES: The data field holds the time of the price in
|          TradeTime format.
| 
| HISTORY: 12.19.96 from 'ConvertMatrixDateAndTimeToTradeTime'.
|          12.29.96 now sorts by the entire record when 
|                   removing duplicates. 
|          12.30.96 factored out 'MakeDedupedOrderedMatrix'.
------------------------------------------------------------*/
Matrix*
MergeOrderedMatrices( Matrix* A, Matrix* B )
{
    Matrix* C;
    Matrix* D;
    
    // Make one big matrix to hold A and B.
    C = MakeMatrix( (s8*) "", 
                    A->RowCount + B->RowCount, 
                    A->ColCount );
                    
    CopyRegionOfMatrix( 
        A,
        0,
        0, 
        A->RowCount,
        A->ColCount,
        C,
        0,
        0 );

    CopyRegionOfMatrix( 
        B,
        0,              // SourceUpperRow,
        0,              // SourceLeftColumn, 
        B->RowCount,    // ARowCount,
        B->ColCount,    // AColumnCount,
        C,
        A->RowCount,    // TargetUpperRow,
        0 );            // TargetLeftColumn
    
    // Remove duplicate records and sort records in ascending 
    // order using the first field in each record.
     
    D = MakeDedupedOrderedMatrix( C );
    
    // Delete the working matrix.
    DeleteMatrix( C );
    
    // Return the result.
    return( D );
}

/*------------------------------------------------------------
| MergeOrderedMatrices2
|-------------------------------------------------------------
| 
| PURPOSE: To combine two matrices which are ordered by the
|          value in the first column to form a single
|          matrix. 
| 
| DESCRIPTION: 
|
|   1. Appends the records of matrix 'B' to the end
|      of 'A'.
|
|   2. Sorts all the records by the first field.
|
|   3. Deletes records which duplicate the first field.
|
|   4. Returns the new matrix.
|
| EXAMPLE:  C = MergeOrderedMatrices2( A, B );
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.30.96 from 'MergeOrderedMatrices'.
------------------------------------------------------------*/
Matrix*
MergeOrderedMatrices2( Matrix* A, Matrix* B )
{
    Matrix* C;
    Matrix* D;
    
    // Make one big matrix to hold A and B.
    C = MakeMatrix( (s8*) "", 
                    A->RowCount + B->RowCount, 
                    A->ColCount );
                    
    CopyRegionOfMatrix( 
        A,
        0,
        0, 
        A->RowCount,
        A->ColCount,
        C,
        0,
        0 );

    CopyRegionOfMatrix( 
        B,
        0,              // SourceUpperRow,
        0,              // SourceLeftColumn, 
        B->RowCount,    // ARowCount,
        B->ColCount,    // AColumnCount,
        C,
        A->RowCount,    // TargetUpperRow,
        0 );            // TargetLeftColumn
    
    // Remove duplicate records and sort records in ascending 
    // order using the first field in each record.
    D = MakeDedupedOrderedMatrix2( C );
    
    // Delete the working matrix.
    DeleteMatrix( C );
    
    // Return the result.
    return( D );
}

/*------------------------------------------------------------
| PercentMatching
|-------------------------------------------------------------
|
| PURPOSE: To calculate the percentage of matching cells in
|          two matrices.
|
| DESCRIPTION: Returns a number from 0 to 1.
|
| EXAMPLE:  
|
|    P = PercentMatching( A, B );
|
| NOTE: 
|
| ASSUMES: Matrices have the same dimensions.
|
| HISTORY:  05.07.97
|          01.30.00 Revised to use 'AtCell()'.
------------------------------------------------------------*/
f64
PercentMatching( Matrix* A, Matrix* B )
{
    u32     Matches;
    u32     CellCount;
    u32     i;
    f64*    a;
    f64*    b;
    
    a = (f64*) AtCell( A, A->LoRowIndex, A->LoColIndex );
    b = (f64*) AtCell( B, B->LoRowIndex, B->LoColIndex );
    
    CellCount = A->RowCount * A->ColCount;
    
    Matches = 0;
    
    for( i = 0; i < CellCount; i++ )
    {
        if( *a++ == *b++ )
        {
            Matches++;
        }
    }
    
    return( ( (f64) Matches ) / ( (f64) CellCount ) );
}

/*------------------------------------------------------------
| PeriodStringOfDatedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To find the first and last date in a dated matrix.
|
| DESCRIPTION: Returns a time period string in the format:
|
|              "07/01/93-07/31/93"
|
| EXAMPLE:  
|
|    Period = PeriodStringOfDatedMatrix( CopperJuly93 );
|
|    Result is "07/01/93-07/31/93".
|
| NOTE: 
|
| ASSUMES: First column in matrix holds the date in TradeTime
|          format.
|
| HISTORY:  07.08.93 
|           01.15.96 converted from Mathematica.
------------------------------------------------------------*/
s8*
PeriodStringOfDatedMatrix( Matrix* AMatrix )
{
    static s8   Period[ 18 ];
    
    u32 Start, End;
    
    RangeOfOrderedMatrix( AMatrix, &Start, &End );

    CopyString( TradeTimeToDateString( Start ), &Period[0] );
    
    Period[8] = '-';
    
    CopyString( TradeTimeToDateString( End ), &Period[9] );
    
    return( Period );
}

/*------------------------------------------------------------
| RangeOfOrderedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To get the first and last date in a dated matrix.
|
| DESCRIPTION: Dates returned are in TradeTime format.
|
| EXAMPLE:  
|
|   RangeOfOrderedMatrix( CopperJuly93, &start, &end );
|
| NOTE: 
|
| ASSUMES: First column in matrix holds the date in TradeTime
|          format.
|
| HISTORY:  01.15.96 
|           01.30.00 Revised to use 'GetCell()'.
------------------------------------------------------------*/
void
RangeOfOrderedMatrix( Matrix* A, u32* Start, u32* End )
{
    *Start = (u32) GetCell( A, A->LoRowIndex, A->LoColIndex );
    
    *End   = (u32) GetCell( A, 
                            A->LoRowIndex + A->RowCount - 1, 
                            A->LoColIndex );
}


/*------------------------------------------------------------
| SaveTextMatrixToFile 
|-------------------------------------------------------------
|
| PURPOSE: To save a matrix that contains lines of text to a
|          text file. 
|
| DESCRIPTION: Each cell in the matrix is one byte and holds
| and ASCII character.
|
| The right-most column of each row holds a zero terminator 
| byte so that rows can be treated as strings.
|
| Trailing spaces in a line are stripped before writing the
| the line to the file.
|
| EXAMPLE: 
|
|         SaveTextMatrixToFile( M, "Myfile.txt", 4 );
|
| ASSUMES: OK to store zero-terminator bytes into row to
|          strip whitespace.
|
| HISTORY: 08.05.01 From ReadTextFileIntoMatrix().
------------------------------------------------------------*/
void
SaveTextMatrixToFile( 
    Matrix* AMatrix,
                // The matrix holding lines of text.
                //
    s8*     FilePath,
                // Path of the file to be written.
                //
    s8*     EndOfLineString )
                // The string to use for the end-of-line
                // marker, one of these:
                //
                //      MacEOLString 
                //      WinEOLString 
                //      UnixEOLString 
{
    s8** S;
    u32  i;
    FILE* F;

    // Open the file as binary to write to it.
    F = OpenFileTL( FilePath, WriteAccess );
    
    // If the file couldn't be opened.
    if( F == 0 )
    {
        // Return.
        return;
    }

    // Refer to the first row in the matrix.
    S = (s8**) AMatrix->a;
    
    // For each row.
    for( i = 0; i < AMatrix->RowCount; i++ )
    {
        // Strip trailing whitespace from the row by
        // inserting a zero-terminator after the last
        // non-space.
        StripTrailingWhiteSpace( S[i] );
        
        // Write the row to the file.
        WriteString( F, S[i] );
        
        // If this is not the last line.
        if( i < AMatrix->RowCount - 1 )
        {
            // Write an end-of-line marker.
            WriteString( F, EndOfLineString );
        }
    }

    // Close the file.
    CloseFile( F );
}    

/*------------------------------------------------------------
| SelectAnyNeighborCell
|-------------------------------------------------------------
|
| PURPOSE: To find the row and column of any cell next to
|          the given cell, subject to matrix limits.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|           SelectAnyNeighborCell( 100, 100,
|                                  TheRow, TheCol,
|                                  &ARow,  &ACol );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.27.96 
------------------------------------------------------------*/
void
SelectAnyNeighborCell( s32  RowCount, s32 ColCount,
                       s32  TheRow,   s32 TheCol,
                       s32* ARow,     s32* ACol )
{
    // This defines where the neighbors are and how many.
    s32     RowOfNeighborCell[] =
            // 0    1    2    3    4    5    6    7
            {  -1, -1,  -1,   0,   1,   1,   1,   0 };
    s32     ColOfNeighborCell[] =
            // 0    1    2    3    4    5    6    7
            {  -1,  0,   1,   1,   1,   0,  -1,  -1 };
            
    s32 NeighborCellCount = 8;  
    
    s32 r,c;
    s32 n;

TryAgain:
    
    n = SubRandomInteger( 8 );
    
    r = TheRow + RowOfNeighborCell[n];
    c = TheCol + ColOfNeighborCell[n];
    
    if( r < 0 || r > RowCount-1 ) goto TryAgain;
    if( c < 0 || c > ColCount-1 ) goto TryAgain;
    
    *ARow = r;
    *ACol = c;
}
    
/*------------------------------------------------------------
| SmallestDifferenceInMatrix
|-------------------------------------------------------------
|
| PURPOSE: To find the smallest gap between values 
|          in a matrix.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SmallestDifferenceInMatrix( V );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.14.96 
|          01.30.00 Revised to use 'AtCell()'.
------------------------------------------------------------*/
f64
SmallestDifferenceInMatrix( Matrix* AMatrix )
{
    u32     CellCount, i;
    f64*    AtCells;
    Matrix* DupMat;
    f64 Diff;
    f64 SmallestDiff;
    
    // Duplicate the matrix so it can be sorted.
    DupMat = DuplicateMatrix( AMatrix );
    
    CellCount = DupMat->RowCount * DupMat->ColCount;
    
    AtCells = (f64*) 
                AtCell( DupMat, 
                        DupMat->LoRowIndex, 
                        DupMat->LoColIndex );
                        
    // Sort the value in increasing order.
    SortVector( AtCells, CellCount );

    SmallestDiff = 0;
    
    for( i = 0; i < CellCount-1; i++ )
    {
        Diff = AtCells[i+1] - AtCells[i];
        
        if( (Diff > 0) &&
            ( (SmallestDiff == 0) ||
              (Diff < SmallestDiff) ) )
        {
            SmallestDiff = Diff;
        }
    }
    
    DeleteMatrix( DupMat );
    
    return( SmallestDiff );
}

/*------------------------------------------------------------
| StripCommentsInSourceCodeMatrix
|-------------------------------------------------------------
| 
| PURPOSE: To remove comments from source code held in a text
|          matrix.
| 
| DESCRIPTION: Removes comments from C source code by 
| replacing them with spaces while leaving the source code in 
| place.
|
| EXAMPLE:   
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 08.06.01 TL
------------------------------------------------------------*/
void
StripCommentsInSourceCodeMatrix( Matrix* AMatrix )
{
    s8** S;
    u32  i;
    s8*  Start;
    s8*  End;
    u32  FillCount;
    
    // Refer to the first row in the matrix.
    S = (s8**) AMatrix->a;
    
    // For each row.
    for( i = 0; i < AMatrix->RowCount; i++ )
    {
        // Look through the current row for a // comment.
        Start = FindStringInString( "\/\/", (s8*) S[i] );
            
        // If a // comment has been found in the current row.
        if( Start )
        {
            // Fill the rest of the row with spaces.
            FillString( Start, ' ' );
        }
            
        // Look through the current row to see if there is
        // '/*' comment.
        Start = FindStringInString( "\/*", (s8*) S[i] );
            
        // If a /* comment has been found in the current
        // row.
        if( Start )
        {
//////////
NextRow://
//////////
            // Look through the current row to find any 
            // */ end-of-comment marker.
            End = FindStringInString( "*\/", (s8*) S[i] );
                
            // If the end-of-comment marker is found.
            if( End )
            {
                // Calculate the number of bytes to fill
                // to erase the comment.
                FillCount = End - Start + 2;
                
                // Fill the comment with spaces.
                FillBytes( (u8*) Start, FillCount, ' ' );
            }
            else // The comment ends on another row.
            {
                // Fill the rest of the row with spaces.
                FillString( Start, ' ' );
                
                // Advance to the next row.
                i++;
                
                // Advance the place where filling starts.
                Start = S[i];
                
                // Then go search for the end of the comment.
                goto NextRow;
            }
        }
    }
}            

/*------------------------------------------------------------
| VectorToMatrix
|-------------------------------------------------------------
|
| PURPOSE: To convert a vector to matrix form.
|
| DESCRIPTION: 'X' part of vector goes to column 0, 'Y' part
| to column 1.
|
| EXAMPLE: M = VectorToMatrix( V );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.25.96
------------------------------------------------------------*/
Matrix*
VectorToMatrix( Vector* V )
{
    Matrix* M;
    u32     RowCount, r;
    f64**   D;
    
    RowCount = V->ItemCount;
    
    // Allocate the matrix.
    M = MakeMatrix( (s8*) "", RowCount, 2 );
    
    // Refer to the effective address of the matrix.
    D = (f64**) M->a;
    
    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        D[r][0] = V->X[r];
        D[r][1] = V->Y[r];
    }
    
    return( M );
}

