/*------------------------------------------------------------
| TLMatrixAlloc.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to matrix allocation 
|          functions.
|
| DESCRIPTION: 
|        
| NOTE:  
|
| HISTORY: 01.22.95 From Numerical Recipies.
|          11.15.99 Additions by J. Watlington.
|          01.23.00 TL Revised allocation routines.
------------------------------------------------------------*/

#ifndef TLMATRIXALLOC_H
#define TLMATRIXALLOC_H

#ifdef __cplusplus
extern "C"
{
#endif

// Zero-based indexing.
//#define BASE_INDEX 0

// One-based indexing.
#define BASE_INDEX 1

//#define DEBUG_MATRIX  1
        // Define the above symbol to enable error checking.

/*------------------------------------------------------------
| MatrixInfo
|-------------------------------------------------------------
|
| PURPOSE: To organize 1 or 2-D matrix structure information.
|
| DESCRIPTION: Data is in C-standard row-major order rather 
| than the Fortran-standard column-major order.  
|
| In other words, if you consider the case where all 
| dimensions have a uniform extent, say a square with 
| dimensions (3x3), then physical memory is divided into 
| the largest chunks in the first dimension and divided into 
| smaller chunks with each successive dimension until the 
| last dimension where the cells are contiguous.  
|
| Logically the elements of a matrix are address by ROW
| and COLUMN index number.
|
|          ------------- --- The first dimension specifies 
|         /@@@/@@@/@@@/      the coarsest chunk, the ROW of
|        /---/---/---/ ---   a matrix.
|       /   /   /   /      
|      /---/---/---/
|     /   /   /   / 
|    -------------
|           /   /    The second dimension gives the
|          /   /<----finest resolution, the COLUMN of
|                    a row.
|
| Physically memory is stored row-by-row with the first
| row lowest in memory.
|
|            Low Memory Byte
|           /
|          ------------------------------------- 
|         /@@@/@@@/@@@/   /   /   /   /   /   /  
|        /------------------------------------
|       /   Row 0   /   Row 1   /   Row 1   /   
| 
| For speed and ease of use in the C-Language, a row 
| address array is built to refer to the first byte in 
| each row, like this.     
|
| ZERO-BASED INDEXING CASE:
|
|          ----------          ------------- 
|          | Row[0] |-------> /@@@/@@@/@@@/
|          |--------|        /---/---/---/ 
|          | Row[1] |-----> /   /   /   /      
|          |--------|      /---/---/---/
|          | Row[2] |---> /   /   /   / 
|          ----------    -------------
|
| ONE-BASED INDEXING CASE:
|
|          ----------           
|          | Row[0] | not used
|          |--------|          ------------- 
|          | Row[1] |-------> /@@@/@@@/@@@/
|          |--------|        /---/---/---/ 
|          | Row[2] |-----> /   /   /   /      
|          |--------|      /---/---/---/
|          | Row[3] |---> /   /   /   / 
|          ----------    -------------
|
| To reduce fragmentation and allocation and free time
| all data for a matrix is allocated in a single chunk
| structured like this...
|
| 2-D, MATRIX CASE:
|                    --------------------------
|                    |           |      |     |
|                    |           v      v     v
|    ----------------|-------------------------------
|    |  MatrixInfo  |   Row[]   |      Data         |
|    -|----------------------------------------------
|     |              ^
|     _______________|
|
| 1-D, VECTOR CASE:
|
| One-dimensional matrices, vectors, have no second Data
| section, the data itself being stored in the 'Row[]'
| array, like this...
|
|    ---------------------------- 
|    |  MatrixInfo  |   Row[]   |
|    -|-------------------------- 
|     |              ^
|     _______________|
|
| EFFECTIVE MATRIX ADDRESS:
|
| The effective matrix or vector address is the address that
| permits dynamically allocated matrices and vectors to be 
| used in C syntax exactly as if they were statically 
| allocated 1D or 2D arrays, eg.
|
|             x = M[2][3];  or   y = V[3];
|
| HISTORY: 01.16.00 TL
|          01.23.00 Merged with 'Matrix' structure in 
|                   'TLMatrixAlloc.h' and renamed from 
|                   'MatrixInfo'.
|          08.11.01 Added IsText.
------------------------------------------------------------*/
typedef struct Matrix
{
    //--------------------------------------------------------
    //
    // STORAGE
    //--------------------------------------------------------
    u8*     a;              // The address to use with this
                            // matrix in order to use it like
                            // a standard C matrix defined
                            // at compile time, eg. u8 a[5][6];
                            //
    u8*     RowSection;     // The address of the first byte
                            // of the 'Row' section.
                            //
    u32     RowSectionSize; // Number of bytes in the Row
                            // size.
                            //
    u8*     DataSection;    // The address of the first byte
                            // of the 'Data' section.
                            //
    u32     DataSectionSize;// Number of bytes in the 'Data'
                            // section.
                            //
    s8      FileName[128];  // Holds path of file where stored.
    //--------------------------------------------------------
    //
    // EXTENT
    //--------------------------------------------------------
    u32     DimCount;       // Number of dimensions.
                            //        
    s32     RowCount;       // Number of cells in each column.      
                            //
    s32     ColCount;       // Number of cells in each row.
                            //
    s32     BitsPerCell;    // Number of bits in each cell.
    //--------------------------------------------------------
    //
    // INDEXING 
    //--------------------------------------------------------
    s32     BaseIndex;      // The number used to address the
                            // the first element in any 
                            // dimension: eg. 0 for zero-based 
                            // indexing or 1 for one-based
                            // indexing.
                            //
    s32     LoRowIndex;     // The number used to index the
                            // first row in the matrix.
                            //
    s32     LoColIndex;     // The number used to index the
                            // first column in each row.
    //--------------------------------------------------------
    //
    // DATA INTERPRETATION 
    //--------------------------------------------------------
    u32     CheckSum;       // 32 bit CRC of the data in the 
                            // matrix cells.
                            //
    u8      IsInteger;      // '1' if the cells hold integer
                            // values or '0' if not.
                            //
    u8      IsSigned;       // '1' if the cells hold signed
                            // values or '0' if not.
                            //
    u8      IsFloat;        // '1' if the cells hold floating
                            // point values or '0' if not.
                            //
    u8      IsText;         // '1' if the cells hold text
                            // characters or '0' if not.
} Matrix;

typedef struct 
{
    s32     n; 
    f64**   m; 
    f64**   in; 
    f64**   lu; 
    s32*    indx; 
    f64     det; 
} dmatrix_family; 

Matrix* AllocateMatrix( s32, s32, s32, s32, u32, u32, u32 );
f64*    AtCell( Matrix*, s32, s32 );
u32     CalculateMatrixStorageSize( s32, s32, s32, s32, u32, u32, u32 );
f64**   convert_matrix( f64*, s32, s32, s32, s32 );
u8*     cvector( s32, s32 );
void    DeleteMatrix( Matrix* );
void    DeleteMatrixOfMatrices( Matrix* );
f64**   dmatrix( s32, s32, s32, s32 );
f64*    dvector( s32, s32 );
f32**   fmatrix( s32, s32, s32, s32 );
void    free_convert_matrix( f64**, s32, s32, s32, s32 );
void    free_cvector( u8*, s32, s32 );
void    free_dmatrix( f64**, s32, s32, s32, s32 );
void    free_dvector( f64*, s32, s32 );
void    free_fmatrix( f32**, s32, s32, s32, s32 );
void    free_fvector( f32*, s32, s32 );
void    free_imatrix( s32**, s32, s32, s32, s32 );
void    free_ivector( s32*, s32, s32 );
void    free_lvector( u32*, s32, s32 );
void    free_matrix( f64**, s32, s32, s32, s32 );
void    free_submatrix( f64**, s32, s32, s32, s32 );
void    free_vector( f64*, s32, s32 );
void    FreeMatrix( void**, s32, u32, u32, u32 );   
f32*    fvector( s32, s32 );
s32**   imatrix( s32, s32, s32, s32 );
s32*    ivector( s32, s32 );
u32*    lvector( s32, s32 );
Matrix* MakeMatrix( s8*, u32, u32 );
Matrix* MakeTextMatrix( s8*, u32, u32 );
f64**   matrix( s32, s32, s32, s32 );
f64**   submatrix( f64**, s32, s32, s32, s32, s32, s32 );
Matrix* ToMatrixHeader( void**, s32, u32, u32, u32 );
f64*    vectorr( s32, s32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLMATRIXALLOC_H
