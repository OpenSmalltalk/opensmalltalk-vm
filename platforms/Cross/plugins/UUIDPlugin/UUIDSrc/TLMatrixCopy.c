/*------------------------------------------------------------
| TLMatrixCopy.c
|-------------------------------------------------------------
|
| PURPOSE: To provide matrix data copying functions.
|
| HISTORY: 01.26.00 From 'TLMatrix.c'.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"  
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"

/*------------------------------------------------------------
| CopyCell
|-------------------------------------------------------------
|
| PURPOSE: To copy the cell from one matrix to another.
|
| DESCRIPTION: 
|
| EXAMPLE: CopyCell( AMatrix, 10L, 30L, 
|                    BMatrix,  0L,  0L );
|
|      puts the content of AMatrix(10,30) into BMatrix(0,0).
|
| NOTE: 
|
| ASSUMES: Matrices exist.  Not a complex array.
|           
| HISTORY: 02.04.95 .
|          01.07.95 revised matrix format.
|          01.25.00 From CopyRegionOfMatrix.
------------------------------------------------------------*/
void 
CopyCell( Matrix*   SrcMatrix, 
          u32       SrcRow,
          u32       SrcCol,
          Matrix*   DstMatrix,
          u32       DstRow,
          u32       DstCol )
{
    switch( SrcMatrix->BitsPerCell )
    {
        case 8:
        {
            u8**    S;
            u8**    D;
            
            S = (u8**) SrcMatrix->a;
            D = (u8**) DstMatrix->a;
            
            D[ DstRow ][ DstCol ] = S[ SrcRow ][ SrcCol ];
            
            break;
        }
        
        case 16:
        {
            u16**   S;
            u16**   D;
            
            S = (u16**) SrcMatrix->a;
            D = (u16**) DstMatrix->a;
            
            D[ DstRow ][ DstCol ] = S[ SrcRow ][ SrcCol ];
            
            break;
        }
        
        case 32:
        {
            u32**   S;
            u32**   D;
            
            S = (u32**) SrcMatrix->a;
            D = (u32**) DstMatrix->a;
            
            D[ DstRow ][ DstCol ] = S[ SrcRow ][ SrcCol ];
            
            break;
        }
        
        case 64:
        {
            u64**   S;
            u64**   D;
            
            S = (u64**) SrcMatrix->a;
            D = (u64**) DstMatrix->a;
            
            D[ DstRow ][ DstCol ] = S[ SrcRow ][ SrcCol ];
            
            break;
        }
        
        default: // All other cell sizes.
        {
            u8**    S;
            u8**    D;
            u8*     From;
            u8*     To;
            u32     BytesPerCell;
            
            // Calculate the number of bytes per cell.
            BytesPerCell = SrcMatrix->BitsPerCell >> 3;
            
            S = (u8**) SrcMatrix->a;
            D = (u8**) DstMatrix->a;
            
            // Calculate the source byte address.
            From = S[ SrcRow ] + ( SrcCol * BytesPerCell );
                   
            // Calculate the target byte address.
            To = D[ DstRow ] + ( DstCol * BytesPerCell );
                   
            // Copy the data.
            memcpy( To, From, BytesPerCell );
            
            break;
        }
    }
}

/*------------------------------------------------------------
| CopyColumnToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To copy a column of a matrix to a given buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: CopyColumnToBuffer( AMatrix, 10L, &Buf );
|
| NOTE: 
|
| ASSUMES: Enough memory.
|           
| HISTORY: 04.01.96 from 'CopyColumnToNewBuffer'.
|          01.25.00 Revised matrix format.
------------------------------------------------------------*/
void
CopyColumnToBuffer( Matrix* AMatrix, u32 Column, f64* Buf )
{
    u32     RowCount, r;
    f64**   m;
    
    RowCount = AMatrix->RowCount;
    
    m = (f64**) AMatrix->a;
    
    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        *Buf++ = m[ r ][ Column ];
    }
}

/*------------------------------------------------------------
| CopyColumnToNewBuffer
|-------------------------------------------------------------
|
| PURPOSE: To allocate a buffer and copy a column of a matrix
|          to that space.
|
| DESCRIPTION: 
|
| EXAMPLE: AtVector = CopyColumnToNewBuffer( AMatrix, 10L );
|
| NOTE: 
|
| ASSUMES: Enough memory.
|           
| HISTORY: 07.26.95 .
------------------------------------------------------------*/
f64*
CopyColumnToNewBuffer( Matrix* AMatrix, u32 Column )
{
    f64     *AtVector;
    f64     *AtEntry;
    u32     RowCount, r;
    f64**   a;
    
    RowCount = AMatrix->RowCount;
    a = (f64**) AMatrix->a;
    
    // Allocate the memory.
    AtVector = (f64*) 
               malloc( RowCount * sizeof( f64 ) );
    
    // For each row.
    AtEntry = AtVector;
    for( r = 0; r < RowCount; r++ )
    {
        *AtEntry++ = a[ r ][ Column ];
    }
    
    return( AtVector );
}

/*------------------------------------------------------------
| CopyIndexedRows
|-------------------------------------------------------------
|
| PURPOSE: To copy indexed rows from one matrix to another.
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
|          01.25.00 Revised for new matrix format.
------------------------------------------------------------*/
void
CopyIndexedRows( Matrix* From, Matrix* To, u32* Rows, u32 Count ) 
{
    u8**    F;
    u8**    T;
    u32     BytesPerCell;
    u32     BytesPerRow;
    u32     i, j;
    
    // Calculate the number of bytes per cell.
    BytesPerCell = From->BitsPerCell >> 3;
    
    // Calculate the number of bytes in a row of cells.
    BytesPerRow = From->ColCount * BytesPerCell;
    
    F = (u8**) From->a;
    T = (u8**) To->a;

    // For the given number of rows.               
    for( i = 0; i < Count; i++ )
    {
        // Get a row index.
        j = Rows[i];
        
        // Copy the data from the source to the beginning
        // of the target array, filling downward.
        memcpy( T[i], F[j], BytesPerRow );
    }
}

/*------------------------------------------------------------
| CopyRegionOfMatrix
|-------------------------------------------------------------
|
| PURPOSE: To copy a region of a matrix.
|
| DESCRIPTION: Given the upper-cell in a matrix, together with
| the number of rows and columns which be copied and a 
| target matrix and upper-left cell, copy the region.
|
| EXAMPLE: CopyRegionOfMatrix( AMatrix, 10L, 10L, 4L, 4L,
|                              ToMatrix, 0L,  0L );
|
|      returns address of the matrix in memory.
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.03.95  
|          07.17.97 sped up.
|          01.24.00 Revised matrix format.
------------------------------------------------------------*/
void
CopyRegionOfMatrix( 
    Matrix* SourceMatrix,
    u32         SourceUpperRow,
    u32         SourceLeftColumn, 
    u32         ARowCount,
    u32         AColumnCount,
    Matrix* TargetMatrix,
    u32         TargetUpperRow,
    u32         TargetLeftColumn )
{
    u32 i, j;
    u32 SrcRow, SrcCol, DstRow, DstCol;
    
    switch( SourceMatrix->BitsPerCell )
    {
        case 8:
        {
            u8**    S;
            u8**    D;
            
            S = (u8**) SourceMatrix->a;
            D = (u8**) TargetMatrix->a;
            
            for( i = 0; i < ARowCount; i++ )
            {
                SrcRow = SourceUpperRow+i;
                DstRow = TargetUpperRow+i;
                
                for( j = 0; j < AColumnCount; j++ )
                {
                    SrcCol = SourceLeftColumn+j;
                    DstCol = TargetLeftColumn+j;
                    
                    D[ DstRow ][ DstCol ] = 
                        S[ SrcRow ][ SrcCol ];
                }
            }
            
            break;
        }
        
        case 16:
        {
            u16**   S;
            u16**   D;
            
            S = (u16**) SourceMatrix->a;
            D = (u16**) TargetMatrix->a;
            
            for( i = 0; i < ARowCount; i++ )
            {
                SrcRow = SourceUpperRow+i;
                DstRow = TargetUpperRow+i;
                
                for( j = 0; j < AColumnCount; j++ )
                {
                    SrcCol = SourceLeftColumn+j;
                    DstCol = TargetLeftColumn+j;
                    
                    D[ DstRow ][ DstCol ] = 
                        S[ SrcRow ][ SrcCol ];
                }
            }
            
            break;
        }
        
        case 32:
        {
            u32**   S;
            u32**   D;
            
            S = (u32**) SourceMatrix->a;
            D = (u32**) TargetMatrix->a;
            
            for( i = 0; i < ARowCount; i++ )
            {
                SrcRow = SourceUpperRow+i;
                DstRow = TargetUpperRow+i;
                
                for( j = 0; j < AColumnCount; j++ )
                {
                    SrcCol = SourceLeftColumn+j;
                    DstCol = TargetLeftColumn+j;
                    
                    D[ DstRow ][ DstCol ] = 
                        S[ SrcRow ][ SrcCol ];
                }
            }
            
            break;
        }
        
        case 64:
        {
            u64**   S;
            u64**   D;
            
            S = (u64**) SourceMatrix->a;
            D = (u64**) TargetMatrix->a;
            
            for( i = 0; i < ARowCount; i++ )
            {
                SrcRow = SourceUpperRow+i;
                DstRow = TargetUpperRow+i;
                
                for( j = 0; j < AColumnCount; j++ )
                {
                    SrcCol = SourceLeftColumn+j;
                    DstCol = TargetLeftColumn+j;
                    
                    D[ DstRow ][ DstCol ] = 
                        S[ SrcRow ][ SrcCol ];
                }
            }
            
            break;
        }
        
        default: // All other cell sizes.
        {
            u8**    S;
            u8**    D;
            u8*     From;
            u8*     To;
            u32     BytesPerCell;
            u32     BytesPerRun;
            
            // Calculate the number of bytes per cell.
            BytesPerCell = SourceMatrix->BitsPerCell >> 3;
            
            // Calculate the number of bytes in a run
            // of cells.
            BytesPerRun = AColumnCount * BytesPerCell;
            
            S = (u8**) SourceMatrix->a;
            D = (u8**) TargetMatrix->a;
            
            for( i = 0; i < ARowCount; i++ )
            {
                SrcRow = SourceUpperRow+i;
                DstRow = TargetUpperRow+i;
                
                // Calculate the source byte address.
                From = S[ SrcRow ] + 
                       ( SourceLeftColumn * BytesPerCell );
                       
                // Calculate the target byte address.
                To = D[ DstRow ] + 
                       ( TargetLeftColumn * BytesPerCell );
                       
                // Copy the data.
                memcpy( To, From, BytesPerRun );
            }
            
            break;
        }
    }
}

/*------------------------------------------------------------
| CopyRowToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To copy a row of a matrix to a given buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: CopyRowToBuffer( AMatrix, 10L, &Buf );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.30.00 From CopyColumnToBuffer.
------------------------------------------------------------*/
void
CopyRowToBuffer( Matrix* AMatrix, u32 Row, u8* AtBuf )
{
    u32 BytesPerCell;
    u32 BytesPerRow;
    u8* AtRow;
    
    // Calculate the number of bytes per cell.
    BytesPerCell = AMatrix->BitsPerCell >> 3;
      
    // Calculate the number of bytes per row.
    BytesPerRow = AMatrix->ColCount * BytesPerCell;
        
    // Refer to the first byte of the row.
    AtRow = (u8*) AtCell( AMatrix, Row, AMatrix->LoColIndex );
    
    // Copy the data from the row to the buffer.
    memcpy( AtBuf, AtRow, BytesPerRow );
}

/*------------------------------------------------------------
| CopyRowToNewBuffer
|-------------------------------------------------------------
|
| PURPOSE: To copy a row of a matrix to a new buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|             b = CopyRowToNewBuffer( AMatrix, 10L );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.30.00 From CopyRowToBuffer.
------------------------------------------------------------*/
u8*
CopyRowToNewBuffer( Matrix* AMatrix, u32 Row )
{
    u32     BytesPerCell;
    u32     BytesPerRow;
    u8*     AtBuf;
    u8*     AtRow;
    
    // Calculate the number of bytes per cell.
    BytesPerCell = AMatrix->BitsPerCell >> 3;
      
    // Calculate the number of bytes per row.
    BytesPerRow = AMatrix->ColCount * BytesPerCell;
        
    // Allocate a new buffer.
    AtBuf = (u8*) malloc( BytesPerRow );
    
    // Refer to the first byte of the row.
    AtRow = (u8*) AtCell( AMatrix, Row, AMatrix->LoColIndex );
    
    // Copy the data from the row to the buffer.
    memcpy( AtBuf, AtRow, BytesPerRow );
    
    // Return the new buffer.
    return( AtBuf );
}

/*------------------------------------------------------------
| CopyVectorFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To copy one vector from one place to another.
|       
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.11.78 LINPACK by Jack Dongarra.
|          12.03.93 Modified array(1) declarations changed to 
|                   array(*).
|          02.29.00 Obtained LINPACK Fortran source, 'dcopy.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'dcopy'.
|                   Replaced indexing with pointers.
------------------------------------------------------------*/
void
CopyVectorFromLINPACK(
    s32  n, // Number of elements in vectors x and y.
            //
    f64* x, // SOURCE: vector, x[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incx,
            // Array increment between elements of x.
            //
    f64* y, // DESTINATION: vector, y[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incy )  
            // Array increment between elements of y.
{
    s32 ix, iy;
  
    if( n <= 0 ) 
    {
        return;
    }
    
    // If both increments are one.
    if( incx == 1 && incy == 1 ) 
    {
        while( n-- ) 
        {
            *y++ = *x++;
        }
    }
    else // Not both increments are one.
    {
        // Parameter adjustments.
        --y;
        --x;

        ix = 1;
        iy = 1;
        
        if( incx < 0 ) 
        {
            ix = (1 - n) * incx + 1;
        }
        
        if( incy < 0 ) 
        {
            iy = (1 - n) * incy + 1;
        }
        
        x += ix;
        y += iy;
        
        while( n-- ) 
        {
            *y = *x;
            
            x += incx;
            y += incy;
        }
    }
}

/*------------------------------------------------------------
| DuplicateMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a copy of a matrix.
|
| DESCRIPTION: 
|
| EXAMPLE: d = DuplicateMatrix( AMatrix );
|
| NOTE: 
|
| ASSUMES: Matrix is 2D.
|           
| HISTORY: 02.03.96 
|          01.26.00 Revised for the new matrix format.
------------------------------------------------------------*/
Matrix*
DuplicateMatrix( Matrix* AMatrix )
{
    Matrix* BMatrix;
    u32     Rows;
    u32     Cols;

    // If the given data is missing, return 0.
    if( AMatrix == 0 )
    {
        return( 0 );
    }
    
    Rows = AMatrix->RowCount;
    Cols = AMatrix->ColCount;
    
    // Allocate the space for the matrix.
    BMatrix = MakeMatrix( AMatrix->FileName, Rows, Cols );
    
    // Copy the DataCheckSum field.
    BMatrix->CheckSum = AMatrix->CheckSum;
    
    // Copy the Data section.
    memcpy( BMatrix->DataSection, 
            AMatrix->DataSection, 
            AMatrix->DataSectionSize );
    
    // Return the resulting matrix.
    return( BMatrix );
}
 
/*------------------------------------------------------------
| FillMatrix
|-------------------------------------------------------------
|
| PURPOSE: To fill a region of a matrix with a value.
|
| DESCRIPTION: Fills a rectangular region of a matrix with
| the same value given the upper-cell in a matrix together 
| with the number of rows and columns in the region.
|
| EXAMPLE: FillMatrix( AMatrix, 10, 10, 4, 4, 3.14 );
|
| ASSUMES: 8-bit cell size.
|           
| HISTORY: 02.03.95
|          08.11.01 Generalized for other 8-bit cell sizes.
------------------------------------------------------------*/
void
FillMatrix( 
    Matrix* AMatrix,
                // The matrix to be filled.
                //
    s32     UpperRow,
                // Index of the top row to be filled.
                //
    s32     LeftColumn, 
                // Index of the left column to be filled.
                //
    s32     ARowCount,
                // Number of rows to be filled.
                //
    s32     AColumnCount,
                // Number of columns to be filled.
                //
    f64     AValue )
                // The fill value passed as a floating point 
                // value.
{
    s32     i,j;
    f64**   A;
    u8**    B;
    u8      AByte;
    u16**   P;
    u16     APair;
    u32**   Q;
    u32     AQuad;
    
    // Depending on the cell size.
    switch( AMatrix->BitsPerCell )
    {
        case 8:
        {
            B = (u8**) AMatrix->a;
            
            AByte = (u8) AValue;
            
            for( i = 0; i < ARowCount; i++ )
            {
                for( j = 0; j < AColumnCount; j++ )
                {
                    B[ UpperRow+i ][ LeftColumn+j ] = AByte;
                }
            }
            
            break;
        }
        
        case 16:
        {
            P = (u16**) AMatrix->a;
            
            APair = (u16) AValue;
            
            for( i = 0; i < ARowCount; i++ )
            {
                for( j = 0; j < AColumnCount; j++ )
                {
                    P[ UpperRow+i ][ LeftColumn+j ] = APair;
                }
            }
            
            break;
        }
        
        case 32:
        {
            Q = (u32**) AMatrix->a;
            
            AQuad = (u32) AValue;
            
            for( i = 0; i < ARowCount; i++ )
            {
                for( j = 0; j < AColumnCount; j++ )
                {
                    Q[ UpperRow+i ][ LeftColumn+j ] = AQuad;
                }
            }
            
            break;
        }
        
        case 64:
        {
            A = (f64**) AMatrix->a;
            
            for( i = 0; i < ARowCount; i++ )
            {
                for( j = 0; j < AColumnCount; j++ )
                {
                    A[ UpperRow+i ][ LeftColumn+j ] = AValue;
                }
            }
            
            break;
        }
    }
}

/*------------------------------------------------------------
| GetCell
|-------------------------------------------------------------
|
| PURPOSE: To return the contents of the cell at row and 
|          column of a matrix.
|
| DESCRIPTION: 
|
| EXAMPLE: InCell = GetCell( MyMatrix, 10L, 30L );
|
|      returns value of the 'f64' cell.
|
| NOTE: 
|
| ASSUMES: Matrix exists.
|           
| HISTORY: 02.04.95 
|          01.07.95 revised matrix format.
|          01.26.00 revised matrix format.
------------------------------------------------------------*/
f64 
GetCell( Matrix* AMatrix, 
         s32     ARow,
         s32     AColumn )
{
    f64** a;
 
    a = (f64**) AMatrix->a;
    
    return( a[ ARow ][ AColumn ] );
}

/*------------------------------------------------------------
| MakeSubMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a new matrix holding the same values as
|          part of a given matrix.
|
| DESCRIPTION: Given the upper-cell in a matrix, together with
| the number of rows and columns which will form a new matrix,
| make a new matrix using the values in the given matrix.
|
| EXAMPLE: 
|
|    BMatrix = MakeSubMatrix( AMatrix, 10L, 10L, 4L, 4L );
|
| NOTE: 
|
| ASSUMES: Uses the same file name as the source matrix.
|           
| HISTORY: 02.03.95 .
|          01.24.00 Added copying of data interpretation
|                   fields.
------------------------------------------------------------*/
Matrix*
MakeSubMatrix( 
    Matrix* AMatrix,
    u32     UpperRow,
    u32     LeftColumn, 
    u32     ARowCount,
    u32     AColumnCount )
{
    Matrix* BMatrix;
    
    // Make a new matrix with the appropriate size.
    BMatrix = MakeMatrix( AMatrix->FileName, 
                          ARowCount,
                          AColumnCount );
                          
    // Interpret the data the same way in the derivative
    // matrix.
    BMatrix->IsInteger = AMatrix->IsInteger;
    BMatrix->IsSigned  = AMatrix->IsSigned;
    BMatrix->IsFloat   = AMatrix->IsFloat;
    
    // Copy the values from the source matrix to the new
    // matrix.
    CopyRegionOfMatrix( 
        AMatrix,
        UpperRow,
        LeftColumn, 
        ARowCount,
        AColumnCount,
        BMatrix,
        0L,
        0L );
    
    // Return the new matrix.
    return( BMatrix );
}

/*------------------------------------------------------------
| PutCell
|-------------------------------------------------------------
|
| PURPOSE: To put a new value into the cell at row and 
|          column of a matrix.
|
| DESCRIPTION: 
|
| EXAMPLE: PutCell( MyMatrix, 10L, 30L, MyValue );
|
|      puts contents of 'MyValue' into cell (10,30) of matrix.
|
| NOTE: 
|
| ASSUMES: Matrix exists.
|           
| HISTORY: 02.04.95 .
|          01.07.95 revised matrix format.
|          01.26.00 revised matrix format.
------------------------------------------------------------*/
void 
PutCell( Matrix* AMatrix, 
         s32    ARow,
         s32    AColumn,
         f64    AValue )
{
    f64** a;
 
    a = (f64**) AMatrix->a;

    a[ ARow ][ AColumn ] = AValue;
}

/*------------------------------------------------------------
| SwapVectorsFromLINPACK
|-------------------------------------------------------------
|
| PURPOSE: To exchange the locations of two vectors.
|       
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.11.78 LINPACK by Jack Dongarra.
|          12.03.93 Modified array(1) declarations changed to 
|                   array(*).
|          02.29.00 Obtained LINPACK Fortran source, 'dswap.f', 
|                   translated it using AT&T's Fortran-to-C
|                   translator, 'f2c.exe', edited for 
|                   readibility and integration with other
|                   code.  Name changed from 'dswap'.
|                   Replaced indexing with pointers.
------------------------------------------------------------*/
void
SwapVectorsFromLINPACK(
    s32  n, // Number of elements in vectors x and y.
            //
    f64* x, // The input vector, x[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incx,
            // Array increment between elements of x.
            //
    f64* y, // The input vector, y[1..n], 1-based indexing 
            // and 1-based storage -- the given address 
            // is the address of the 1th element.
            //
    s32  incy )  
            // Array increment between elements of y.
{
    s32 ix, iy;
    f64 xt;
  
    if( n <= 0 ) 
    {
        return;
    }
    
    // If both increments are one.
    if( incx == 1 && incy == 1 ) 
    {
        while( n-- ) 
        {
            xt = *x;
            *x++ = *y;
            *y++ = xt;
        }
    }
    else // Not both increments are one.
    {
        // Parameter adjustments.
        --y;
        --x;

        ix = 1;
        iy = 1;
        
        if( incx < 0 ) 
        {
            ix = (1 - n) * incx + 1;
        }
        
        if( incy < 0 ) 
        {
            iy = (1 - n) * incy + 1;
        }
        
        x += ix;
        y += iy;
        
        while( n-- ) 
        {
            xt = *x;
            *x = *y;
            *y = xt;
            
            x += incx;
            y += incy;
        }
    }
}

