/*------------------------------------------------------------
| TLArray.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to array functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 03.04.96
|          06.07.96 added 'MaxArrayDimensions' and made
|                   dimension extents integral with the
|                   'Array' record.
|          07.03.96 added format code to array record to
|                   support data compression.
------------------------------------------------------------*/

#ifndef _ARRAY_H_
#define _ARRAY_H_

#ifdef __cplusplus
extern "C"
{
#endif

// The most number of dimensions supported: this limit can be 
// changed to any number depending on the requirements of the 
// application.
#define MaxArrayDimensions  12

// Format codes:
#define Uncompressed        0
#define HuffmanEncoded      1  // Obsolete: don't use.
#define HuffmanEncodedCRC32 2

// Define this to enable bounds checking in array.
//#define ARRAY_ERROR_CHECKING  1

/*------------------------------------------------------------
| Array
|-------------------------------------------------------------
|
| PURPOSE: 
|
| DESCRIPTION: Data is in C-standard row-major order rather 
| than the Fortran-standard column-major order.  
|
| In other words, if you consider the case where all 
| dimensions have a uniform extent, say a cube with dimensions 
| (3x3x3), then physical memory is divided into the largest 
| chunks in the first dimension and divided into smaller 
| chunks with each successive dimension until the last 
| dimension where the cells are contiguous.  
|
|  Low Memory Byte
|       \
|        \ -------------  The first dimension specifies the
|         /@@@/@@@/@@@/   coarsest chunk, the PLANE.
|        /---/---/---/
|       /@@@/@@@/@@@/
|      /---/---/---/
|     /@@@/@@@/@@@/
|    -------------
|          -------------
|         /@@@/@@@/@@@/   The second dimension specifies
|        /---/---/---/    the next finer chunk, the ROW of  
|       /   /   /   /     a plane.
|      /---/---/---/
|     /   /   /   /
|    -------------
|          -------------
|         /   /   /@@@/
|        /---/---/---/    The third dimension gives the
|       /   /   /   /     finest resolution, the COLUMN of
|      /---/---/---/      a row.
|     /   /   /   /  
|    -------------
|                 \
|                  High Memory Byte
|
| For this cubic example, a three-dimensional array, the 
| first dimension specifies a physical plane of bytes, the 
| second dimension specifies the physical row, and the 
| third dimension gives the column offset from the beginning 
| of the row.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.27.99 Moved 'Data' field to first in record 
|          to avoid bug in Visual C++ 6 compiler.
------------------------------------------------------------*/
typedef struct 
{
    f64*   Data;           // Where the cells are. 
                           //
                           // Data is stored in one of three
                           // formats: 64, 16 or 1 bit cells,
                           // with 64 being the default. 
                           //
    s8      Name[120];     // Holds name of the array.
                           //
    u32     CRC32;         // 32-bit check sum of 'Data' field.
                           //
    u16     Format;        // A code which specifies the
                           // data format.  See above codes.
                           //   
    u16     BitsPerCell;   // Number of bits in each cell.
                           // Supports 1, 16, 64. See
                           // 'LoadArrayAsBinary' for interim
                           // conversion code which precludes
                           // 8 bits per cell.
                           //
    u32     DimCount;      // Count of dimensions.
                           //        
    u32     DimExtent[MaxArrayDimensions]; 
                           // Number of cells in each dimension.
                           //                
    u32     DimOffsetFactor[MaxArrayDimensions];
                           // Offset factor used to compute 
                           // offset of a particular cell given 
                           // indices: each index is multiplied 
                           // times it's cooresponding dimension 
                           // offset factor and the resulting
                           // sum is the offset of the cell.
                           //
    u32     CellCount;     // Total cell count.
                           //  
} Array;

/*------------------------------------------------------------
| Section
|-------------------------------------------------------------
|
| PURPOSE: To specify any part of an array.
|
| DESCRIPTION: This record is used to refer to some or any 
| part of an array.  A section consists of one or more 
| extents.
|
| A 'section' used in this sense is a logical section, 
| meaning any concievable distinction, whether or not the 
| distinction is simple or compound, contiguous or 
| disparate.
|
| No extents in a section intersect: they are mutually 
| exclusive.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.27.99
------------------------------------------------------------*/
typedef struct
{
    s8*     Name;       // Name of this section. Optional. 
                        // Dynamic.
                        //
    Array*  OfArray;    // The array that this is a section of.
                        //
    List*   ExtentList; // A list of dynamic extents that 
                        // compose the section.
                        //
    f64     Sum;        // Sum of all the cells in the section.
                        //
    u32     IsSum;      // 1 if 'Sum' is true reflection of 
                        // the the sum of the cells.
                        //
    u32     IsEmpty;    // 1 if this is an empty section.
                        // 
} Section;


void        AddToCell( Array*, u32*, f64 );
void        AddToSection( Section*, f64 );
Matrix*     ArrayToMatrix( Array* );
f64*        At( Array*, u32* );
u16*        AtInteger( Array*, u32* );
u32         CountCellsInSection( Section* );
void        DeleteArray( Array* );
void        DeleteSection( Section* );
Array*      DuplicateArray( Array* );
Section*    DuplicateSection( Section* );
void        FillArray( Array*, f64 );
void        FillSection( Section*, f64 );
f64         Get( Array*, u32* );
void        GetArrayExtremes( Array*, f64*, f64*);
u32         GetBit( Array*, u32* );
u16         GetInteger( Array*, u32* );
Section*    Intersect( Section*, Section* );
u32         IsCellInArray( Array*, u32* );
u32         IsSectionEmpty( Section* );
Array*      LoadArray( s8* );
Array*      LoadArrayAsBinary( s8* );
Array*      MakeArray( u32, u32* );
List*       MakeArrayListFromSectionList( List* );
Array*      MakeMultiDimensionalBitArray( u32, u32* );
Array*      MakeIntegerArray( u32, u32* );
Section*    MakeSection( Array*, u32*, u32* );
Array*      MakeSubArray( Section* );
void        MultiplyToSection( Section*, f64 );
void        OnesArray( Array* );
void        Put( Array*, u32*, f64 );
void        PutBit( Array*, u32*, u32 );
void        PutInteger( Array*, u32*, u16 );
void        ReviseSection( Section*, u32*, u32* );
void        SaveArray( Array*, s8* );
void        SaveArrayAsBinary( Array*, s8* );
void        SaveArrayAsBinaryCompressed( Array*, s8* );
f64*        SectionToItems( Section* );
f64         SumOfArray( Array* );
f64         SumOfSection( Section* );
Section*    Unite( Section*, Section* );
void        ValidateCellInArray( Array*, u32* );
void        ZeroArray( Array* );
void        TestArray();

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _ARRAY_H_
