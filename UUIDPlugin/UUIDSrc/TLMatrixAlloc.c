/*------------------------------------------------------------
| TLMatrixAlloc.c
|-------------------------------------------------------------
|
| PURPOSE: To provide matrix allocation functions.
|
| NOTE: Later add alignment to 8-byte boundaries for speed.
|
| HISTORY: 01.22.95 From Numerical Recipies.
|          11.15.99 Additions by J. Watlington.
|          01.23.00 TL Revised allocation routines.
------------------------------------------------------------*/

#include "TLTarget.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "TLTypes.h"
#include "TLMatrixAlloc.h"

/*------------------------------------------------------------
| AllocateMatrix
|-------------------------------------------------------------
|
| PURPOSE: To allocate a matrix or vector.
|
| DESCRIPTION: This function dynamically allocates a 1D or
| 2D array that can be used in C syntax just like an array
| defined at compile time.
|
| Use a value of zero for the BaseIndex parameter if standard
| zero-based C array indexing is desired.
|
| Use a value of '1' for the BaseIndex parameter if standard
| one-based array indexing is desired.
|
| EXAMPLE:  To use the matrix like a standard C array, recast 
| the address held in the 'a' field as 
| an array or vector like this:
|
|   // Make a 4 row by 3 column matrix that will be use
|   // zero-based addressing with the lowest row index of
|   // 5 and the lowest column index of 2, using f64 values
|   // in each cell of the matrix.
|   {
|       Matrix* M;
|       f64**   m;
|       s32     LoRow, LoCol, HiRow, HiCol;
|       s32     RowCount, ColCount, BitsPerCell;
|
|       // Set the given values.
|       RowCount    = 4;
|       ColCount    = 3;
|       LoRow       = 5;
|       LoCol       = 2;
|       BitsPerCell = sizeof(f64) << 3;
|
|       // Calculate the high index values for each dimension.
|       HiRow       = LoRow + RowCount - 1;
|       HiCol       = LoCol + ColCount - 1;
|
|       // Allocate the matrix.
|       M = AllocateMatrix( 
|               LoRow,  // Index number used to refer to the first
|                       // row.
|                       //
|               HiRow,  // Index number used to refer to the last
|                       // row.
|                       // 
|               LoCol,  // Index number used to refer to the first
|                       // column.
|                       //
|               HiCol,  //
|                       // Index number used to refer to the last
|                       // column.
|                       //
|               2,      // Number of dimensions, 1 or 2.
|                       //
|               BitsPerCell,
|                       // Number of bits in each data cell,
|                       // a multiple of 8.
|                       //
|               0 );    // '0' if zero-based indexing is used or
|                       // '1' if one-based indexing is used, 
|                       // other values are possible but less
|                       // used.
|
|       // Refer to the matrix in such a way that it can be
|       // used like a standard C array.
|       m = (f64**) M->a;
|
|       // Then fill in the matrix with zeros.
|       for( r = LoRow; r <= HiRow; r++ )
|       {
|           for( c = LoCol; c <= HiCol; c++ )
|           {
|               m[r][c] = 0.0;
|           }
|       }
|
|       // Do other things here...
|
|       // Then just free the matrix using 'free'.
|       free( M );
|   }
|
| NOTE: There are special allocators such as 'MakeMatrix' which
|       handle commonly used types of matrices.
|
| ASSUMES: BitsPerCell is a multiple of 8.
|
|          Default data cell interpretation is unsigned
|          integer: edit the returned Matrix record to
|          override this if needed.
|
| HISTORY: 01.16.00 Generalized all other matrix allocation
|                   routines.
|          01.24.00 Changed to return the matrix header 
|                   address rather than the effective matrix
|                   address.
|          01.26.00 Added RowSectionSize, DataSection, and
|                   DataSectionSize;
|          08.11.01 Added error exit on allocation failure.
------------------------------------------------------------*/
                    // OUT: The address of the matrix header
Matrix*             //      record or zero on error.
AllocateMatrix( 
    s32 LoRowIndex, // Index number used to refer to the first
                    // row.
                    //
    s32 HiRowIndex, // Index number used to refer to the last
                    // row.
                    // 
    s32 LoColIndex, // Index number used to refer to the first
                    // column.
                    //
    s32 HiColIndex, // Index number used to refer to the last
                    // column.
                    //
    u32 DimCount,   // Number of dimensions, 1 or 2.
                    //
    u32 BitsPerCell,// Number of bits in each data cell,
                    // a multiple of 8.
                    //
    u32 BaseIndex ) // '0' if zero-based indexing is used or
                    // '1' if one-based indexing is used, 
                    // other values are possible but less
                    // used.
{
    s32     i, BytesPerCell;
    s32     BytesPerRowEntry;
    s32     CellCount;
    s32     RowEntryCount;
    s32     RecordByteCount;
    s32     BytesPerRow;
    u8*     R;
    u8**    AtRow;
    Matrix  M;
    
    // Save the given specifications.
    M.DimCount    = DimCount;
    M.BitsPerCell = BitsPerCell;
    M.BaseIndex   = BaseIndex;
    M.LoRowIndex  = LoRowIndex;
    M.LoColIndex  = LoColIndex;
    
    // Calculate the logical number of rows and columns.
    M.RowCount = HiRowIndex - LoRowIndex + 1;
    M.ColCount = HiColIndex - LoColIndex + 1;
    
    // Calculate the number of bytes per cell.
    BytesPerCell = BitsPerCell >> 3;
    
    // If this is an array.
    if( DimCount == 2 )
    {
        // Then each row entry is an address.
        BytesPerRowEntry = sizeof( u8* );
        
        // The Data section is the logical number of 
        // cells plus the base index number.
        CellCount = ( M.RowCount * M.ColCount ) + BaseIndex;
        
        // Calculate the size of the Data section in bytes.
        M.DataSectionSize = CellCount * BytesPerCell;
    }
    else // This is a vector.
    {
        // Each row entry is the same size as a data cell.
        BytesPerRowEntry = BytesPerCell;
         
        // There is no separate Data section.
        CellCount = 0;
        
        // There is no separate Data section.
        M.DataSectionSize = 0;
    }
    
    // Calculate the physical number of row address 
    // entries needed.
    RowEntryCount = M.RowCount + BaseIndex;
    
    // Calculate the size of the Row section.
    M.RowSectionSize = RowEntryCount * BytesPerRowEntry;
            
    // Calculate the total number of bytes in the record.
    RecordByteCount = 
        sizeof( Matrix ) +
        M.RowSectionSize +
        M.DataSectionSize;
        
    // Allocate the record.
    R = (u8*) malloc( RecordByteCount );

    // If allocation failed.
    if( R == 0 )
    {
        // Return zero to indicate failure.
        return( 0 );
    }

#ifdef DEBUG_MATRIX
    // Fill the array with zero bytes.
    memset( R, 0, RecordByteCount );
#endif
    
    // Refer to the first byte of the Row section.
    M.RowSection = R + sizeof( Matrix );
    
    // Refer to the first byte of the Data section.
    M.DataSection = M.RowSection + M.RowSectionSize;
    
    // Apply logical row indexing adjustments.
    {
        // Calculate the address that should be used
        // when treating the matrix like a statically
        // defined C array.

        // Adjust the row address by the base index.
        M.a = 
            M.RowSection + ( BaseIndex * BytesPerRowEntry );
            
        // Adjust the row address by the low row index.
        M.a -= ( LoRowIndex * BytesPerRowEntry );
    }
    
    // Clear the file name string.
    M.FileName[0] = 0;
    
    // Clear the data checksum field.
    M.CheckSum = 0;
    
    // Default to unsigned integer cells.
    M.IsInteger = 1;
    M.IsSigned  = 0;
    M.IsFloat   = 0;
    
    // Copy the matrix header to the allocated record.
    *( (Matrix*) R ) = M;

    // If this is a matrix.
    if( DimCount == 2 )
    {
        // Fill in the row address entries for each row in the 
        // index range [LoRowIndex...HiRowIndex].
        {
            // Refer to the matrix using the effective matrix
            // address that will be used when the matrix is
            // treated like a standard C matrix defined at
            // compile time.
            AtRow = (u8**) M.a;
            
            // Fill in the address of the first physical data cell.
            AtRow[ LoRowIndex ] = M.RowSection + M.RowSectionSize;
                     
            // Apply logical column indexing adjustments.
            {
                // Adjust the cell address by the column base 
                // index.
                AtRow[ LoRowIndex ] += ( BaseIndex * BytesPerCell );
                
                // Adjust the cell address by the column low index.
                AtRow[ LoRowIndex ] -= ( LoColIndex * BytesPerCell );
            }
            
            // Calculate the number of bytes per row.
            BytesPerRow = M.ColCount * BytesPerCell;
            
            // For each remaining row.
            for( i = LoRowIndex + 1; i <= HiRowIndex; i++ )
            {
                // Add the number of bytes in each row.
                AtRow[i] = AtRow[i-1] + BytesPerRow;
            }
        }
    }
    
    // Return the matrix header address, the first byte of
    // the entire matrix record.
    return( (Matrix*) R );
}

/*------------------------------------------------------------
| AtCell
|-------------------------------------------------------------
|
| PURPOSE: To return the cell address given row and column of
|          a matrix.
|
| DESCRIPTION: 
|
| EXAMPLE: ACell = AtCell( MyMatrix, 10L, 30L );
|
|      returns address of the matrix cell in memory.
|
| NOTE: Avoid use of this form due to bug: &m[r][c].
|
| ASSUMES: Matrix exists.
|           
| HISTORY: 02.04.95 .
|          01.07.95 revised matrix format.
|          01.25.00 Revised matrix format.
------------------------------------------------------------*/
f64*
AtCell( Matrix* AMatrix, 
        s32     ARow,
        s32     AColumn )
{
    f64**   m;
    f64*    r;
    
    // Refer to the matrix using its effective address.
    m = (f64**) AMatrix->a;
    
    // Refer to the address of the row.
    r = m[ ARow ];
    
    // Add the column offset.
    r += AColumn;
     
    // Return the address of the cell.
    return( r );
}

/*------------------------------------------------------------
| CalculateMatrixStorageSize
|-------------------------------------------------------------
|
| PURPOSE: To calculate how many bytes will be needed to store
|          a matrix or vector including any overhead bytes.
|
| DESCRIPTION:  with subscript range 
|          m[LoRowIndex..HiRowIndex][LoColIndex..HiColIndex].
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: BitsPerCell is a multiple of 8.
|
| HISTORY: 01.23.00 Factored out of AllocateMatrix.
------------------------------------------------------------*/
u32
CalculateMatrixStorageSize( 
    s32 LoRowIndex, // Index number used to refer to the first
                    // row.
                    //
    s32 HiRowIndex, // Index number used to refer to the last
                    // row.
                    // 
    s32 LoColIndex, // Index number used to refer to the first
                    // column.
                    //
    s32 HiColIndex, // Index number used to refer to the last
                    // column.
                    //
    u32 DimCount,   // Number of dimensions, 1 or 2.
                    //
    u32 BitsPerCell,// Number of bits in each data cell,
                    // a multiple of 8.
                    //
    u32 BaseIndex ) // '0' if zero-based indexing is used or
                    // '1' if one-based indexing is used, 
                    // other values are possible but less
                    // used.
{
    s32 BytesPerCell;
    s32 BytesPerRowEntry;
    s32 CellCount;
    s32 RowEntryCount;
    s32 RowCount, ColCount;
    u32 RecordByteCount;

    // Calculate the logical number of rows and columns.
    RowCount = HiRowIndex - LoRowIndex + 1;
    ColCount = HiColIndex - LoColIndex + 1;

    // Calculate the number of bytes per cell.
    BytesPerCell = BitsPerCell >> 3;
    
    // If this is an array.
    if( DimCount == 2 )
    {
        // Then each row entry is an address.
        BytesPerRowEntry = sizeof( u8* );
        
        // The Data section is the logical number of 
        // cells plus the base index number.
        CellCount = ( RowCount * ColCount ) + BaseIndex;
    }
    else // This is a vector.
    {
        // Each row entry is the same size as a cell.
        BytesPerRowEntry = BytesPerCell;
         
        // There is no separate Data section.
        CellCount = 0;
    }
    
    // Calculate the physical number of row address 
    // entries needed.
    RowEntryCount = RowCount + BaseIndex;
    
    // Calculate the total number of bytes in the record.
    RecordByteCount = 
        sizeof( Matrix ) +
        ( RowEntryCount * BytesPerRowEntry ) +
        ( CellCount     * BytesPerCell );

    // Return the size of the record in bytes.
    return( RecordByteCount );
}       

/*------------------------------------------------------------
| convert_matrix
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION: allocate a f64 matrix 
| m[LoRowIndex..HiRowIndex][LoColIndex..HiColIndex] 
| that points to the matrix declared in the standard C manner 
| as a[RowCount][ColCount], where 
|
|       RowCount = HiRowIndex-LoRowIndex + 1 and 
|       ColCount = HiColIndex-LoColIndex + 1. 
|
| The routine should be called with the address &a[0][0] as 
| the first argument.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
f64** 
convert_matrix( 
    f64*    a,
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    s32     i, j, RowCount, ColCount; 
    f64**  m; 

    RowCount = HiRowIndex - LoRowIndex  +  1; 
    ColCount = HiColIndex - LoColIndex  +  1;
    
    // Allocate pointers to rows.
    m = (f64**) 
        malloc( (u32) ( RowCount  +  BASE_INDEX ) * sizeof(f64*) );
     
    m += BASE_INDEX;
    m -=  LoRowIndex;
     
    // set pointers to rows.
    m[ LoRowIndex ] = a - LoColIndex;
    
    for( i = 1, j = LoRowIndex + 1; i < RowCount; i++ ,j++  ) 
    {
        m[j] = m[j-1]  +  ColCount;
    }
         
    // Return pointer to array of pointers to rows.
    return( m ); 
}

/*------------------------------------------------------------
| cvector
|-------------------------------------------------------------
|
| PURPOSE: To allocate an u8 vector with subscript range 
|          v[LoIndex..HiIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
u8*
cvector( s32 LoIndex, s32 HiIndex )
{
    Matrix* M;
    u8*     v;

    // Allocate the vector using a general routine.
    M = AllocateMatrix( 
            LoIndex,    // Index number used to refer to the 
                        // first row.
                        //
            HiIndex,    // Index number used to refer to the 
                        // last row.
                        // 
            0,          // Index number used to refer to the 
                        // first column.
                        //
            0,          // Index number used to refer to the 
                        // last column.
                        //
            1,          // Number of dimensions, 1 or 2.
                        //
            8,          // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
                        
    // Mark the matrix as being unsigned integer.
    M->IsInteger = 1;
    M->IsSigned  = 0;
    M->IsFloat   = 0;
    
    // Refer to the vector using its effective address.
    v = (u8*) M->a;

    // Return vector.
    return( v );
}

/*------------------------------------------------------------
| DeleteMatrix
|-------------------------------------------------------------
|
| PURPOSE: To delete a matrix.
|
| DESCRIPTION: 
|
| EXAMPLE: DeleteMatrix( AMatrix );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.12.95 .
|          01.07.95 revised matrix format.
|          01.23.00 Revised matrix format.
------------------------------------------------------------*/
void
DeleteMatrix( Matrix* AMatrix )
{
    // Free the matrix header and all concatentated data.
    free( (u8*)  AMatrix );
}

/*------------------------------------------------------------
| DeleteMatrixOfMatrices
|-------------------------------------------------------------
|
| PURPOSE: To delete a matrix and the subordinate matrices
|          that it refers to. 
|
| DESCRIPTION: 
|
| EXAMPLE: DeleteMatrixOfMatrices( MatrixMatrix );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.20.96 
------------------------------------------------------------*/
void
DeleteMatrixOfMatrices( Matrix* MatrixMatrix )
{
    s32     r,  c;
    u32     Au32;
    f64**   M;
    
    // Refer to the superior matrix as a C array.
    M = (f64**) MatrixMatrix->a;
    
    // Delete the subordinate matrices.
    for( r = 0; r < MatrixMatrix->RowCount; r++ )
    {
        for( c = 0; c < MatrixMatrix->ColCount; c++ )
        {
            Au32 = (u32) M[r][c];
            
            DeleteMatrix( (Matrix*) Au32 );
        }
    }
    
    // Delete the superior matrix.
    DeleteMatrix( MatrixMatrix );
}

/*------------------------------------------------------------
| dmatrix  
|-------------------------------------------------------------
|
| PURPOSE: To allocate a f64 matrix with subscript range 
|          m[LoRowIndex..HiRowIndex][LoColIndex..HiColIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
|          01.17.00 Revised to use 'AllocateMatrix'.
------------------------------------------------------------*/
f64** 
dmatrix( 
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    Matrix* M;
    f64**   m;

    // Allocate the matrix using a general routine.
    M = AllocateMatrix( 
            LoRowIndex, // Index number used to refer to the 
                        // first row.
                        //
            HiRowIndex, // Index number used to refer to the 
                        // last row.
                        // 
            LoColIndex, // Index number used to refer to the 
                        // first column.
                        //
            HiColIndex, // Index number used to refer to the 
                        // last column.
                        //
            2,          // Number of dimensions, 1 or 2.
                        //
            64,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used 
                        // or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
                        
    // Mark the matrix as being floating point.
    M->IsInteger = 0;
    M->IsSigned  = 1;
    M->IsFloat   = 1;
    
    // Refer to the matrix using its effective address.
    m = (f64**) M->a;
        
    // Return the matrix.
    return( m );
}

/*------------------------------------------------------------
| dvector
|-------------------------------------------------------------
|
| PURPOSE: To allocate a f64 vector with subscript range 
|          v[LoIndex..HiIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
f64*
dvector( s32 LoIndex, s32 HiIndex )
{
    Matrix* M;
    f64*    v;

    // Allocate the vector using a general routine.
    M = AllocateMatrix( 
            LoIndex,    // Index number used to refer to the 
                        // first row.
                        //
            HiIndex,    // Index number used to refer to the 
                        // last row.
                        // 
            0,          // Index number used to refer to the 
                        // first column.
                        //
            0,          // Index number used to refer to the 
                        // last column.
                        //
            1,          // Number of dimensions, 1 or 2.
                        //
            64,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
                        
    // Mark the vector as being floating point.
    M->IsInteger = 0;
    M->IsSigned  = 1;
    M->IsFloat   = 1;
    
    // Refer to the vector using its effective address.
    v = (f64*) M->a;
        
    // Return the vector.
    return( v );
}

/*------------------------------------------------------------
| fmatrix
|-------------------------------------------------------------
|
| PURPOSE: To allocate a f32 matrix with subscript range 
|          m[LoRowIndex..HiRowIndex][LoColIndex..HiColIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00 
------------------------------------------------------------*/
f32**
fmatrix( 
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    Matrix* M;
    f32**   m;

    // Allocate the matrix using a general routine.
    M = AllocateMatrix( 
            LoRowIndex, // Index number used to refer to the 
                        // first row.
                        //
            HiRowIndex, // Index number used to refer to the 
                        // last row.
                        // 
            LoColIndex, // Index number used to refer to the 
                        // first column.
                        //
            HiColIndex, // Index number used to refer to the 
                        // last column.
                        //
            2,          // Number of dimensions, 1 or 2.
                        //
            32,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.

    // Mark the matrix as being floating point.
    M->IsInteger = 0;
    M->IsSigned  = 1;
    M->IsFloat   = 1;
    
    // Refer to the matrix using its effective address.
    m = (f32**) M->a;
        
    // Return the matrix.
    return( m );
}

/*------------------------------------------------------------
| free_convert_matrix
|-------------------------------------------------------------
|
| PURPOSE: To free a matrix allocated by convert_matrix( ).
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00 
------------------------------------------------------------*/
void 
free_convert_matrix( 
    f64**   b, 
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    // Assign unused parameters to themselves to keep the
    // compiler from generating warnings.
    HiRowIndex = HiRowIndex;
    LoColIndex = LoColIndex;
    HiColIndex = HiColIndex;
    
    free( (s8*) ( b + LoRowIndex - BASE_INDEX ) );
}

/*------------------------------------------------------------
| free_cvector
|-------------------------------------------------------------
|
| PURPOSE: To free an u8 vector allocated with cvector().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_cvector( u8* v, s32 LoIndex, s32 HiIndex )
{
    // Assign unused parameters to themselves to keep the
    // compiler from generating warnings.
    HiIndex = HiIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) v,     // The effective address of a matrix 
                        // or vector.
                        //
        LoIndex,        // Index number used to refer to the 
                        // first row.
                        //
        1,              // Number of dimensions, 1 or 2.
                        //
        8,              // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_dmatrix
|-------------------------------------------------------------
|
| PURPOSE: To free a f64 matrix allocated by dmatrix().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_dmatrix( 
    f64**   m, 
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    // Assign unused parameters to themselves to keep the
    // compiler from generating warnings.
    HiRowIndex = HiRowIndex;
    LoColIndex = LoColIndex;
    HiColIndex = HiColIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) m,     // The effective address of a matrix 
                        // or vector.
                        //
        LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
        2,              // Number of dimensions, 1 or 2.
                        //
        64,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_dvector
|-------------------------------------------------------------
|
| PURPOSE: To free a f64 vector allocated with dvector().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_dvector( f64*v, s32 LoIndex, s32 HiIndex )
{
    // Assign unused parameters to themselves to keep the
    // compiler from generating warnings.
    HiIndex = HiIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) v,     // The effective address of a matrix 
                        // or vector.
                        //
        LoIndex,        // Index number used to refer to the 
                        // first row.
                        //
        1,              // Number of dimensions, 1 or 2.
                        //
        64,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_fmatrix
|-------------------------------------------------------------
|
| PURPOSE: To free a f32 matrix allocated by fmatrix().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_fmatrix( 
    f32**   m, 
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    // Assign unused parameters to themselves to keep the
    // compiler from generating warnings.
    HiRowIndex = HiRowIndex;
    LoColIndex = LoColIndex;
    HiColIndex = HiColIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) m,     // The effective address of a matrix 
                        // or vector.
                        //
        LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
        2,              // Number of dimensions, 1 or 2.
                        //
        32,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_fvector
|-------------------------------------------------------------
|
| PURPOSE: To free a f32 vector allocated with fvector()
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_fvector( f32* v, s32 LoIndex, s32 HiIndex )
{
    // Assign unused parameters to themselves to keep the
    // compiler from generating warnings.
    HiIndex = HiIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) v,     // The effective address of a matrix 
                        // or vector.
                        //
        LoIndex,        // Index number used to refer to the 
                        // first row.
                        //
        1,              // Number of dimensions, 1 or 2.
                        //
        32,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_imatrix
|-------------------------------------------------------------
|
| PURPOSE: To free an s32 matrix allocated by imatrix().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_imatrix( 
    s32**   m,          // The effective address of a matrix.
                        //
    s32     LoRowIndex, // Index number used to refer to the 
                        // first row.
                        //
    s32     HiRowIndex, // Index number used to refer to the 
                        // last row.
                        // 
    s32     LoColIndex, // Index number used to refer to the 
                        // first column.
                        //
    s32     HiColIndex )// Index number used to refer to the 
                        // last column.
{ 
    // Assign unused parameters to themselves to keep the
    // compiler from generating warnings.
    HiRowIndex = HiRowIndex;
    LoColIndex = LoColIndex;
    HiColIndex = HiColIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) m,     // The effective address of the
                        // matrix.
                        //
        LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
        2,              // Number of dimensions, 1 or 2.
                        //
        32,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_ivector
|-------------------------------------------------------------
|
| PURPOSE: To free an s32 vector allocated with ivector().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_ivector( s32 *v, s32 LoIndex, s32 HiIndex )
{
    HiIndex = HiIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) v,     // The effectvie address of a matrix 
                        // or vector.
                        //
        LoIndex,        // Index number used to refer to the 
                        // first row.
                        //
        1,              // Number of dimensions, 1 or 2.
                        //
        32,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_lvector
|-------------------------------------------------------------
|
| PURPOSE: To free an u32 vector allocated with lvector().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_lvector( u32* v, s32 LoIndex, s32 HiIndex )
{
    HiIndex = HiIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) v,     // The effective address of a matrix 
                        // or vector.
                        //
        LoIndex,        // Index number used to refer to the 
                        // first row.
                        //
        1,              // Number of dimensions, 1 or 2.
                        //
        32,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_matrix
|-------------------------------------------------------------
|
| PURPOSE: To free a matrix allocated by matrix().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
|          01.23.00 Revised to use FreeMatrix.
------------------------------------------------------------*/
void 
free_matrix( 
    f64**   m,          // The effective address of a matrix.
                        //
    s32     LoRowIndex, // Index number used to refer to the 
                        // first row.
                        //
    s32     HiRowIndex, // Index number used to refer to the 
                        // last row.
                        // 
    s32     LoColIndex, // Index number used to refer to the 
                        // first column.
                        //
    s32     HiColIndex )// Index number used to refer to the 
                        // last column.
{
    HiRowIndex = HiRowIndex;
    LoColIndex = LoColIndex;
    HiColIndex = HiColIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) m,     // The effective address of the
                        // matrix.
                        //
        LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
        2,              // Number of dimensions, 1 or 2.
                        //
        64,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| free_submatrix
|-------------------------------------------------------------
|
| PURPOSE: To free a submatrix allocated by submatrix( ).
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00 
------------------------------------------------------------*/
void 
free_submatrix( 
    f64**   b, 
    s32     LoRowIndex, // Index number used to refer to the 
                        // first row.
                        //
    s32     HiRowIndex, // Index number used to refer to the 
                        // last row.
                        // 
    s32     LoColIndex, // Index number used to refer to the 
                        // first column.
                        //
    s32     HiColIndex )// Index number used to refer to the 
                        // last column.
{
    HiRowIndex = HiRowIndex;
    LoColIndex = LoColIndex;
    HiColIndex = HiColIndex;
    
    free( (s8*) ( b + LoRowIndex - BASE_INDEX ) );
}

/*------------------------------------------------------------
| free_vector  
|-------------------------------------------------------------
|
| PURPOSE: To free a vector allocated with vector().
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
void 
free_vector( f64* v, s32 LoIndex, s32 HiIndex )
{
    HiIndex = HiIndex;
    
    // Use the general purpose free routine.
    FreeMatrix( 
        (void**) v,     // The effective address of the
                        // vector.
                        //
        LoIndex,        // Index number used to refer to the 
                        // first row.
                        //
        1,              // Number of dimensions, 1 or 2.
                        //
        64,             // Number of bits in each data cell,
                        // a multiple of 8.
                        //
        BASE_INDEX );       // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
}

/*------------------------------------------------------------
| FreeMatrix
|-------------------------------------------------------------
|
| PURPOSE: To deallocate a matrix or vector.
|
| DESCRIPTION:  with subscript range 
|          m[LoRowIndex..HiRowIndex][LoColIndex..HiColIndex].
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: BitsPerCell is a multiple of 8.
|
| HISTORY: 01.23.00 From AllocateMatrix.
------------------------------------------------------------*/
void          
FreeMatrix( 
    void**  A,      // The effective address of a matrix or 
                    // vector.
                    //
    s32     LoRowIndex, 
                    // Index number used to refer to the first
                    // row.
                    //
    u32     DimCount,   
                    // Number of dimensions, 1 or 2.
                    //
    u32     BitsPerCell,
                    // Number of bits in each data cell,
                    // a multiple of 8.
                    //
    u32     BaseIndex ) 
                    // '0' if zero-based indexing is used or
                    // '1' if one-based indexing is used, 
                    // other values are possible but less
                    // used.
{
    Matrix* M;
    
    // Calculate the address of the beginning of the 
    // 'Matrix' record.
    M = ToMatrixHeader( 
            A,      // The effective address of a matrix or 
                    // vector.
                    //
            LoRowIndex, 
                    // Index number used to refer to the first
                    // row.
                    //
            DimCount,   
                    // Number of dimensions, 1 or 2.
                    //
            BitsPerCell,
                    // Number of bits in each data cell,
                    // a multiple of 8.
                    //
            BaseIndex );
                    // '0' if zero-based indexing is used or
                    // '1' if one-based indexing is used, 
                    // other values are possible but less
                    // used.

#ifdef DEBUG_MATRIX
                    
    // For debugging verify the matrix parameters.
    {
        // Compare the parameters
        if( M->DimCount    != DimCount    ||
            M->BitsPerCell != BitsPerCell ||
            M->BaseIndex   != BaseIndex   ||
            M->LoRowIndex  != LoRowIndex  )
        {
            // Call the debugger.
            Debugger();
        }
    }
    
#endif // DEBUG_MATRIX
            
    // Free the record.
    free( M );
}       

/*------------------------------------------------------------
| fvector 
|-------------------------------------------------------------
|
| PURPOSE: To allocate a fvector with subscript range 
|          v[LoIndex..HiIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
f32*
fvector( s32 LoIndex, s32 HiIndex )
{
    f32*    v;
    Matrix* M;

    // Allocate the vector using a general routine.
    M = AllocateMatrix( 
            LoIndex,    // Index number used to refer to the 
                        // first row.
                        //
            HiIndex,    // Index number used to refer to the 
                        // last row.
                        // 
            0,          // Index number used to refer to the 
                        // first column.
                        //
            0,          // Index number used to refer to the 
                        // last column.
                        //
            1,          // Number of dimensions, 1 or 2.
                        //
            32,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.

    // Mark the vector as being floating point.
    M->IsInteger = 0;
    M->IsSigned  = 1;
    M->IsFloat   = 1;
    
    // Refer to the vector using its effective address.
    v = (f32*) M->a;

    // Return the vector.
    return( v );
}

/*------------------------------------------------------------
| imatrix
|-------------------------------------------------------------
|
| PURPOSE: To allocate a s32 matrix with subscript range 
|          m[LoRowIndex..HiRowIndex][LoColIndex..HiColIndex]
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
s32**
imatrix( 
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    s32**   m;
    Matrix* M;

    // Allocate the matrix using a general routine.
    M = AllocateMatrix( 
            LoRowIndex, // Index number used to refer to the 
                        // first row.
                        //
            HiRowIndex, // Index number used to refer to the 
                        // last row.
                        // 
            LoColIndex, // Index number used to refer to the 
                        // first column.
                        //
            HiColIndex, // Index number used to refer to the 
                        // last column.
                        //
            2,          // Number of dimensions, 1 or 2.
                        //
            32,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
                        
    // Mark the matrix as being signed integer type.
    M->IsInteger = 1;
    M->IsSigned  = 1;
    M->IsFloat   = 0;
    
    // Refer to the matrix using its effective address.
    m = (s32**) M->a;

    // Return the matrix address.
    return( m );
}

/*------------------------------------------------------------
| ivector 
|-------------------------------------------------------------
|
| PURPOSE: To allocate an s32 vector with subscript range 
|          v[LoIndex..HiIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
s32*
ivector( s32 LoIndex, s32 HiIndex )
{
    s32*    v;
    Matrix* M;

    // Allocate the vector using a general routine.
    M = AllocateMatrix( 
            LoIndex,    // Index number used to refer to the 
                        // first row.
                        //
            HiIndex,    // Index number used to refer to the 
                        // last row.
                        // 
            0,          // Index number used to refer to the 
                        // first column.
                        //
            0,          // Index number used to refer to the 
                        // last column.
                        //
            1,          // Number of dimensions, 1 or 2.
                        //
            32,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
                        
    // Mark the vector as being signed integer type.
    M->IsInteger = 1;
    M->IsSigned  = 1;
    M->IsFloat   = 0;
    
    // Refer to the vector using its effective address.
    v = (s32*) M->a;

    // Return the vector.
    return( v );
}

/*------------------------------------------------------------
| lvector
|-------------------------------------------------------------
|
| PURPOSE: To allocate an u32 vector with subscript range 
|          v[LoIndex..HiIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
u32*
lvector( s32 LoIndex, s32 HiIndex )
{
    u32*    v;
    Matrix* M;

    // Allocate the vector using a general routine.
    M = AllocateMatrix( 
            LoIndex,    // Index number used to refer to the 
                        // first row.
                        //
            HiIndex,    // Index number used to refer to the 
                        // last row.
                        // 
            0,          // Index number used to refer to the 
                        // first column.
                        //
            0,          // Index number used to refer to the 
                        // last column.
                        //
            1,          // Number of dimensions, 1 or 2.
                        //
            32,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
                        
    // Mark the vector as being unsigned integer type.
    M->IsInteger = 1;
    M->IsSigned  = 0;
    M->IsFloat   = 0;
    
    // Refer to the vector using its effective address.
    v = (u32*) M->a;

    // Return the vector.
    return( v );
}

/*------------------------------------------------------------
| MakeMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a new matrix record and place for the 
|          data of the matrix.
|
| DESCRIPTION: 
|
| EXAMPLE: AMatrix = MakeMatrix( "D:Data:NG92Z.TSV",
|                                10L, 30L );
|
| ASSUMES: Zero-based indexing.
|
|          f64 cells.
|           
| HISTORY: 01.22.95 TL
|          01.07.95 revised matrix format.
|          01.24.00 Revised matrix format.
|          08.11.01 Added allocation error exit.
------------------------------------------------------------*/
            // OUT: The address of the matrix header
Matrix*     //      record or zero on error.
MakeMatrix( 
    s8* AFileName,      
            // The path where the matrix is stored.
            //
            // This can also be used to just name a matrix 
            // even if the data will never be saved in a 
            // file.
            //
            // Use zero if no name or file path is to be 
            // assigned to the matrix.
            //
    u32 ARowCount,      
            // Number of rows.
            //
    u32 AColumnCount )  
            // Number of columns.
{
    Matrix* M;
    
    // Halt if row or col count is invalid.
    if( (ARowCount <= 0) || (AColumnCount <= 0) )
    {
        Debugger();
    }
    
    // Allocate the matrix.
    M = AllocateMatrix( 
            0,      // Index number used to refer to the first
                    // row.
                    //
            ARowCount - 1, 
                    // Index number used to refer to the last
                    // row.
                    // 
            0,      // Index number used to refer to the first
                    // column.
                    //
            AColumnCount - 1, 
                    // Index number used to refer to the last
                    // column.
                    //
            2,      // Number of dimensions, 1 or 2.
                    //
            64,     // Number of bits in each data cell,
                    // a multiple of 8.
                    //
            0 );    // '0' if zero-based indexing is used or
                    // '1' if one-based indexing is used, 
                    // other values are possible but less
                    // used.
    
    // If allocation failed.
    if( M == 0 )
    {
        // Return zero to indicate failure.
        return( 0 );
    }
    
    // Mark the matrix as being floating point.
    M->IsInteger = 0;
    M->IsSigned  = 1;
    M->IsFloat   = 1;
    
    // If there is a name or file name.
    if( AFileName )
    {
        // Copy the filename into the matrix specification.
        strcpy( (s8*) &(M->FileName), AFileName );
    }

    // Return the matrix header address.
    return( M );
}

/*------------------------------------------------------------
| MakeTextMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a new matrix for holding text characters.
|
| DESCRIPTION: Use DeleteMatrix() to deallocate matrices 
| allocated with this function.
| 
| EXAMPLE: AMatrix = MakeTextMatrix( "MyMatrix", 10, 30 );
|
| ASSUMES: Zero-based indexing.
|
|          8-bit cells that will be used to hold ASCII codes.
|           
| HISTORY: 08.11.01 From MakeMatrix().
------------------------------------------------------------*/
            // OUT: The address of the matrix header
Matrix*     //      record or zero on error.
MakeTextMatrix( 
    s8* AFileName,      
            // The path where the matrix is stored.
            //
            // This can also be used to just name a matrix 
            // even if the data will never be saved in a 
            // file.
            //
            // Use zero if no name or file path is to be 
            // assigned to the matrix.
            //
    u32 ARowCount,      
            // Number of rows.
            //
    u32 AColumnCount )  
            // Number of columns.
{
    Matrix* M;
    
    // Halt if row or col count is invalid.
    if( (ARowCount <= 0) || (AColumnCount <= 0) )
    {
        Debugger();
    }
    
    // Allocate the matrix.
    M = AllocateMatrix( 
            0,  // Index number used to refer to the first
                // row.
                //
            ARowCount - 1, 
                // Index number used to refer to the last
                // row.
                // 
            0,  // Index number used to refer to the first
                // column.
                //
            AColumnCount - 1, 
                // Index number used to refer to the last
                // column.
                //
            2,  // Number of dimensions, 1 or 2.
                //
            8,  // Number of bits in each data cell,
                // a multiple of 8.
                //
            0 );// '0' if zero-based indexing is used or
                // '1' if one-based indexing is used, 
                // other values are possible but less
                // used.

    // If allocation failed.
    if( M == 0 )
    {
        // Return zero to indicate failure.
        return( 0 );
    }
    
    // Mark the matrix as holding text.
    M->IsInteger = 0;
    M->IsSigned  = 0;
    M->IsFloat   = 0;
    M->IsText    = 1;
    
    // If there is a name or file name.
    if( AFileName )
    {
        // Copy the filename into the matrix specification.
        strcpy( (s8*) &(M->FileName), AFileName );
    }

    // Return the matrix header address.
    return( M );
}

/*------------------------------------------------------------
| matrix  
|-------------------------------------------------------------
|
| PURPOSE: To allocate a f64 matrix with subscript range 
|          m[LoRowIndex..HiRowIndex][LoColIndex..HiColIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
f64** 
matrix( 
    s32 LoRowIndex,     // Index number used to refer to the 
                        // first row.
                        //
    s32 HiRowIndex,     // Index number used to refer to the 
                        // last row.
                        // 
    s32 LoColIndex,     // Index number used to refer to the 
                        // first column.
                        //
    s32 HiColIndex )    // Index number used to refer to the 
                        // last column.
{
    Matrix* M;
    f64**   m;

    // Allocate the matrix using a general routine.
    M = AllocateMatrix( 
            LoRowIndex, // Index number used to refer to the 
                        // first row.
                        //
            HiRowIndex, // Index number used to refer to the 
                        // last row.
                        // 
            LoColIndex, // Index number used to refer to the 
                        // first column.
                        //
            HiColIndex, // Index number used to refer to the 
                        // last column.
                        //
            2,          // Number of dimensions, 1 or 2.
                        //
            64,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   // '0' if zero-based indexing is used 
                        // or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
                        
    // Mark the matrix as being floating point.
    M->IsInteger = 0;
    M->IsSigned  = 1;
    M->IsFloat   = 1;
    
    // Refer to the matrix using its effective address.
    m = (f64**) M->a;
        
    // Return the matrix.
    return( m );
}

/*------------------------------------------------------------
| submatrix 
|-------------------------------------------------------------
|
| PURPOSE: To point a submatrix [newrl..][newcl..] to 
|          a[oldrl..oldrh][oldcl..oldch]
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: TBD
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
f64** 
submatrix( 
    f64**   a,
    s32     oldrl, 
    s32     oldrh, 
    s32     oldcl, 
    s32     oldch,
    s32     newrl, 
    s32     newcl )
{
    s32     i, j, RowCount, ColOffset;
    f64**   m;

    oldch = oldch;
    
    RowCount  = oldrh - oldrl + 1;
    ColOffset = oldcl - newcl;
    
    // Allocate array of pointers to rows.
    m = (f64**) 
        malloc( (u32) ( ( RowCount + BASE_INDEX ) * sizeof(f64*) ) );
     
    m += BASE_INDEX;
    m -= newrl;

    // Set pointers to rows.
    for( i = oldrl,j = newrl;i<= oldrh;i++ ,j++ ) 
    {
        m[j] = a[i] + ColOffset;
    }

    // Return pointer to array of pointers to rows.
    return( m );
}

/*------------------------------------------------------------
| ToMatrixHeader
|-------------------------------------------------------------
|
| PURPOSE: To find the matrix header record of a matrix or
|          vector given the effective matrix address.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: BitsPerCell is a multiple of 8.
|
| HISTORY: 01.23.00 From FreeMatrix.
------------------------------------------------------------*/
Matrix*      
ToMatrixHeader( 
    void**  A,      // The effective address of a matrix or 
                    // vector.
                    //
    s32     LoRowIndex, 
                    // Index number used to refer to the first
                    // row.
                    //
    u32     DimCount,   
                    // Number of dimensions, 1 or 2.
                    //
    u32     BitsPerCell,
                    // Number of bits in each data cell,
                    // a multiple of 8.
                    //
    u32     BaseIndex ) 
                    // '0' if zero-based indexing is used or
                    // '1' if one-based indexing is used, 
                    // other values are possible but less
                    // used.
{
    s32     BytesPerCell;
    s32     BytesPerRowEntry;
    u8*     AtRow;
    Matrix* M;
    
    // Calculate the number of bytes per row entry.
    {
        // If this is an array.
        if( DimCount == 2 )
        {
            // Then each row entry is an address.
            BytesPerRowEntry = sizeof( u8* );
        }
        else // This is a vector.
        {
            // Calculate the number of bytes per cell.
            BytesPerCell = BitsPerCell >> 3;
        
            // Each row entry is the same size as a cell.
            BytesPerRowEntry = BytesPerCell;
        }
    }
    
    // Regard the matrix or row base address as a byte
    // address.
    AtRow = (u8*) A;
    
    // Reverse the low  row index adjustment.
    AtRow += ( LoRowIndex * BytesPerRowEntry );
    
    // Reverse the row base index adjustment.
    AtRow -= ( BaseIndex * BytesPerRowEntry );
        
    // 
    // 'AtRow' now refers to the first byte of the 'Row'
    // section.
    //
    
    // Calculate the address of the beginning of the 
    // 'Matrix' record.
    M = (Matrix*) ( AtRow - sizeof( Matrix ) );

    // Return the address of the matrix header record.
    return( M );
}

/*------------------------------------------------------------
| vectorr 
|-------------------------------------------------------------
|
| PURPOSE: To allocate a vector with subscript range 
|          v[LoIndex..HiIndex].
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.15.00
------------------------------------------------------------*/
f64*
vectorr( s32 LoIndex, s32 HiIndex )
{
    f64*    v;
    Matrix* M;

    // Allocate the vector using a general routine.
    M = AllocateMatrix( 
            LoIndex,    // Index number used to refer to the 
                        // first row.
                        //
            HiIndex,    // Index number used to refer to the 
                        // last row.
                        // 
            0,          // Index number used to refer to the 
                        // first column.
                        //
            0,          // Index number used to refer to the 
                        // last column.
                        //
            1,          // Number of dimensions, 1 or 2.
                        //
            64,         // Number of bits in each data cell,
                        // a multiple of 8.
                        //
            BASE_INDEX );   
                        // '0' if zero-based indexing is used or
                        // '1' if one-based indexing is used, 
                        // other values are possible but less
                        // used.
    
    // Mark the vector as being floating point.
    M->IsInteger = 0;
    M->IsSigned  = 1;
    M->IsFloat   = 1;
    
    // Refer to the vector using its effective address.
    v = (f64*) M->a;

    // Return the vector.
    return( v );
}


