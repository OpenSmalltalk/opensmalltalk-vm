/*------------------------------------------------------------
| TLArray.c
|-------------------------------------------------------------
|
| PURPOSE: To provide multi-dimensional array functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 03.04.96
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"
#include "TLBit.h"
#include "TLBytes.h"
#include "TLBytesExtra.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"
#include "TLStacks.h"
#include "TLParse.h"  // for 'ParseDatum'
#include "TLList.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLTable.h"
#include "TLMassMem.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLNumber.h" // for 'ConvertStringToNumber'
                      // and 'ConvertNumberToString'
#include "TLListIO.h"
#include "TLDate.h" 
#include "TLSubRandom.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLMatrixAlloc.h"
#include "TLBitIO.h"
#include "TLHuffman.h"
#include "TLArray.h"
#include "TLExtent.h"
#include "TLPoints.h"
#include "TLGeometry.h"
#include "TLWeight.h"
#include "TLStat.h"
#include "TLTwo.h"
#include "TLf64.h"

/*------------------------------------------------------------
| AddToCell
|-------------------------------------------------------------
|
| PURPOSE: To add a value to a cell in an array.
|
| DESCRIPTION: Expects a cell reference and a value to be 
| added.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: There are no empty extents in the section.
|           
| HISTORY: 04.09.96 from 'AddToExtent'. 
------------------------------------------------------------*/
void
AddToCell( Array* A, u32* Index, f64 v )
{
    u32     LastDim, CellOffset;
    u32     i;
    f64*    ACell;
    
    // Calculate the index of the last dimension for speed.
    LastDim = A->DimCount - 1;
    
    // For each dimension.
    CellOffset = 0;
    for( i = 0; i < LastDim; i++ )
    {
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[i] * Index[i];
    }
    
    // Add the offset of the last dimension.
    CellOffset += Index[LastDim];
    
    // Refer to the cell.
    ACell = (f64*) &A->Data[CellOffset];

    // Add to the cell value.
    *ACell += v;
}

/*------------------------------------------------------------
| AddToSection
|-------------------------------------------------------------
|
| PURPOSE: To add a value to each cell in a section of an 
|          array.
|
| DESCRIPTION: Expects a section record specifying the bounds
| of the section in the array. The 'Lo' bound is the first
| cell to be included in the section and the 'Hi' bound is one
| larger than the last cell to be included in the section.
|
| EXAMPLE: Add .001 to a section of a four dimensional array 
| with dimensions 3 x 5 x 6 x 8 with the value .001.  The 
| section ranges from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32  DimExtent[4];
|      s32  ACell[4];
|      s32  BCell[4];
|      Array*   A;
|      Section* S;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      ACell[0] = 1;
|      ACell[1] = 2;
|      ACell[2] = 3;
|      ACell[3] = 4;
|
|      BCell[0] = 3; // Upper bound is one larger than the 
|      BCell[1] = 4; // address of the last cell in the section.
|      BCell[2] = 5;
|      BCell[3] = 6;
|
|      S = MakeSection( A, ACell, BCell );
| 
|      AddToSection( S, .001 );
|
| NOTE: 
|
| ASSUMES: There are no empty extents in the section.
|           
| HISTORY: 03.06.96 from 'FillSection'. 
|          03.07.96 revise to support multiple extents.
------------------------------------------------------------*/
void
AddToSection( Section* S, f64 v )
{
    Array*  A;
    
    // Refer to the array.
    A = S->OfArray;
    
    // For each extent.
    ReferToList(S->ExtentList);
    
    while( TheItem )
    {
        // Add the value to each cell in the extent.
        AddToExtent( A, 
                     (Extent*) TheDataAddress,
                     v );
                     
        ToNextItem();
    }
    
    RevertToList();
}

/*------------------------------------------------------------
| ArrayToMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a matrix from a two dimensional array.
|
| DESCRIPTION: Dynamically allocates the new matrix.
|  
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Matrix data is stored in the same format as 
|          2D array data.
|
|          The given array is a 2D array.
|
|          The first dimension of the array coorsponds to
|          rows and second to columns in the matrix.
|           
| HISTORY: 04.11.96 from 'AddToCell'. 
------------------------------------------------------------*/
Matrix*
ArrayToMatrix( Array* A )
{
    Matrix* AMatrix;
    u32     RowCount;
    u32     ColCount;
    
    RowCount = A->DimExtent[0];
    ColCount = A->DimExtent[1];
    
    // Allocate the matrix.
    AMatrix = MakeMatrix( (s8*) "", RowCount, ColCount );

    // Copy the data.
    memcpy( (void*) AMatrix->a[0],
            (void*) A->Data,
            sizeof( f64 ) * A->CellCount );
    
    // Return the matrix.
    return( AMatrix );
}

/*------------------------------------------------------------
| At
|-------------------------------------------------------------
|
| PURPOSE: To get the address of a cell in an array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Get the address of cell (2,3,4,5) in array A:
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      a = At( A, ACell );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.05.96
|          03.06.96 Made cell address a vector.
------------------------------------------------------------*/
f64*
At( Array* A, u32* ACell )
{
    u32 i, Dim;
    u32 DimCount;
    u32 CellOffset;
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateCellInArray( A, ACell );
#endif

    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    CellOffset = 0;
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension index.
        Dim = *ACell++;
        
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[i] * Dim;
    }
    
    // Return the cell address.
    return( &A->Data[CellOffset] );
}

/*------------------------------------------------------------
| AtInteger
|-------------------------------------------------------------
|
| PURPOSE: To get the address of an integer cell in an array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Get the address of cell (2,3,4,5) in array A:
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      a = AtInteger( A, ACell );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 06.08.96 from 'At'.
------------------------------------------------------------*/
u16*
AtInteger( Array* A, u32* ACell )
{
    u32     i, Dim;
    u32     DimCount;
    u32     CellOffset;
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateCellInArray( A, ACell );
#endif

    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    CellOffset = 0;
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension index.
        Dim = *ACell++;
        
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[i] * Dim;
    }
    
    // Return the cell address.
    return( &( ((u16*)A->Data)[CellOffset] ) );
}

/*------------------------------------------------------------
| CountCellsInSection
|-------------------------------------------------------------
|
| PURPOSE: To count the number of cells in a section of an 
|          array.
|
| DESCRIPTION: Expects a section record specifying the bounds
| of the section in the array. The 'Lo' bound is the first
| cell to be included in the section and the 'Hi' bound is one
| larger than the last cell to be included in the section.
|
| EXAMPLE: 
|
|     c = CountCellsInSection( S );
|
| NOTE: 
|
| ASSUMES: Section record specifies bounds for all dimensions. 
|           
| HISTORY: 03.05.96 from 'SumOfSection'. 
------------------------------------------------------------*/
u32
CountCellsInSection( Section* S )
{
    u32     Sum;
    
    // Begin the summation.
    Sum = 0;
    
    // For each extent.
    ReferToList( S->ExtentList ); 
     
    while( TheItem )
    {
        // Count each cell in the extent.
        Sum += 
            CountCellsInExtent( (Extent*) TheDataAddress );
        ToNextItem();
    }
    
    RevertToList();
    
    // Return the sum.
    return( Sum );
}

/*------------------------------------------------------------
| DeleteArray
|-------------------------------------------------------------
|
| PURPOSE: To deallocate an array.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|       DeleteArray( A );
|
| NOTE: 
|
| ASSUMES: If there is a name it is dynamically allocated.
|           
| HISTORY: 03.05.96 
|          03.06.96 made dimension specs and name dynamic.
|          06.07.96 no longer free dimension specs or name
|                   which were dynamic.
------------------------------------------------------------*/
void
DeleteArray( Array* A )
{
    // Free the data for the array.
    free( A->Data );

    // Free array specification record.
    free( A );
}

/*------------------------------------------------------------
| DeleteSection
|-------------------------------------------------------------
|
| PURPOSE: To discard a section record and it's memory.
|
| DESCRIPTION: Complement to 'MakeSection'.
|
| EXAMPLE: 
|
|      DeleteSection( S );
|
| NOTE: Sections may assigned an optional, dynamic name. 
|
| ASSUMES: 
|           
| HISTORY: 03.06.96 
------------------------------------------------------------*/
void
DeleteSection( Section* S )
{
    // If there is a name, discard it.
    if( S->Name )
    {
        free( S->Name );
    }
    
    // Delete the extent list.
    DeleteListOfDynamicData( S->ExtentList );
    
    // Free the section specification record.
    free( S );
}

/*------------------------------------------------------------
| DuplicateSection
|-------------------------------------------------------------
|
| PURPOSE: To make a duplicate copy of a section.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
|      q = DuplicateSection( S );
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 03.12.96 
------------------------------------------------------------*/
Section*
DuplicateSection( Section* S )
{
    Section*    s;
    
    // Allocate a section specification record.
    s = (Section*) malloc( sizeof( Section ) );
    
    // Copy in the array that this is a section of.
    s->OfArray = S->OfArray;
    
    // Copy the ortholist.
    s->ExtentList = DuplicateExtents( S->ExtentList );
    
    // Transfer the sums and status.
    s->Sum     = S->Sum;
    s->IsSum   = S->IsSum;
    s->IsEmpty = S->IsEmpty;
    
    return( s );
}

/*------------------------------------------------------------
| FillSection
|-------------------------------------------------------------
|
| PURPOSE: To fill a section of an array with a value.
|
| DESCRIPTION: Expects a section record specifying the bounds
| of the section in the array. The 'Lo' bound is the first
| cell to be included in the section and the 'Hi' bound is one
| larger than the last cell to be included in the section.
|
| EXAMPLE: Fill a section of a four dimensional array with 
| dimensions 3 x 5 x 6 x 8 with the value .001.  The section 
| ranges from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32  DimExtent[4];
|      s32  ACell[4];
|      s32  BCell[4];
|      Array*   A;
|      Section* S;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      ACell[0] = 1;
|      ACell[1] = 2;
|      ACell[2] = 3;
|      ACell[3] = 4;
|
|      BCell[0] = 3; // Upper bound is one larger than the 
|      BCell[1] = 4; // address of the last cell in the section.
|      BCell[2] = 5;
|      BCell[3] = 6;
|
|      S = MakeSection( A, ACell, BCell );
| 
|      FillSection( S, .001 );
|
| NOTE: 
|
| ASSUMES: Section record specifies bounds for all dimensions. 
|           
| HISTORY: 03.05.96 from 'SumOfSection'. 
------------------------------------------------------------*/
void
FillSection( Section* S, f64 v )
{
    Array*  A;
    
    // Refer to the array.
    A = S->OfArray;
    
    // For each extent.
    ReferToList( S->ExtentList ); 

    while( TheItem )
    {
        // Store the value to each cell in the extent.
        FillExtent( A, 
                    (Extent*) TheDataAddress,
                    v );
        ToNextItem();
    }
    
    RevertToList();
}

/*------------------------------------------------------------
| Get
|-------------------------------------------------------------
|
| PURPOSE: To get the value of a cell in an array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Get the value of cell (2,3,4,5) in array A:
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      v = Get( A, ACell );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.05.96
|          03.06.96 Made cell address a vector.
------------------------------------------------------------*/
f64
Get( Array* A, u32* ACell )
{
    u32     i, Dim;
    u32     DimCount;
    u32     CellOffset;
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateCellInArray( A, ACell );
#endif

    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    CellOffset = 0;
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension index.
        Dim = *ACell++;
        
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[i] * Dim;
    }
    
    // Return the cell value.
    return( A->Data[CellOffset] );
}

/*------------------------------------------------------------
| GetBit
|-------------------------------------------------------------
|
| PURPOSE: To get the value of a cell in a bit array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Get the value of cell (2,3,4,5) in array A:
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      v = GetBit( A, ACell );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 06.24.96 from 'GetInteger'.
------------------------------------------------------------*/
u32
GetBit( Array* A, u32* ACell )
{
    u32     i;
    u32     DimCount;
    u32     BitOffset, ByteOffset;
    u8*     ByteAddr;
    u32     BitNum;
    u32*    DimOffset;
    
    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    BitOffset = 0;
    DimOffset = &A->DimOffsetFactor[0];
    for( i = 0; i < DimCount; i++ )
    {
        // Accumulate the cell offset.
        BitOffset += *DimOffset++ * *ACell++;
    }
    
    // Convert bit offset to byte offset and bit-in-byte.
    ByteOffset = BitOffset >> 3;
    BitNum     = BitOffset & 7; // Leaving a value from 0-7.
    
    // Calculate the address of the byte containing the bit.
    ByteAddr = ( (u8*) A->Data ) + ByteOffset;
    
    // Test the bit.
    if( *ByteAddr & BitOfByte[BitNum] )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| GetInteger
|-------------------------------------------------------------
|
| PURPOSE: To get the value of a cell in an integer array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Get the value of cell (2,3,4,5) in array A:
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      v = Get( A, ACell );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 06.08.96 from 'Get'.
------------------------------------------------------------*/
u16
GetInteger( Array* A, u32* ACell )
{
    u32     i, Dim;
    u32     DimCount;
    u32     CellOffset;
    
    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    CellOffset = 0;
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension index.
        Dim = *ACell++;
        
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[i] * Dim;
    }
    
    // Return the cell value.
    return( ((u16*)A->Data)[CellOffset] );
}

/*------------------------------------------------------------
| Intersect
|-------------------------------------------------------------
|
| PURPOSE: To find the intersection of two sections in the
|          same array.
|
| DESCRIPTION: Creates a new section record consisting of
| the intersection of two sections of the same array.  If
| there is no intersection across all dimensions, then the 
| first dimension of the result is marked as empty, and the 
| remaining dimensions are undefined.
|
| If the sections both have names, the resulting section will 
| have a name generated by combination of the original names:
|
| e.g. If "A" and "B" are sections to be formed into an
|      intersection, then the result will be named:
|
|           "(A&B)"
|
| EXAMPLE:  S = Intersect( A, B );
|
| NOTE: 
|
| ASSUMES: The sections are in the same array.
|           
| HISTORY: 03.06.96 
------------------------------------------------------------*/
Section*
Intersect( Section* A, Section* B )
{
    Section*    S;
    u32         i;
    
    // Make a new empty section record using the same array
    // as is used by 'A'.
    S = MakeSection( A->OfArray, 0, 0 );
    
    // If the sections both have names, generate a name for
    // the intersection.
    if( A->Name && B->Name )
    {
        i = CountString( A->Name ) +
            CountString( B->Name ) + 3;
        
        S->Name = AllocateString(i);
        
        AppendStrings( S->Name,
                       (s8*) "(", 
                       A->Name, 
                       (s8*) "&", 
                       B->Name,
                       (s8*) ")", 0 );
    }
    
    // If either 'A' or 'B' is empty then just return
    // the empty section.
    if( A->IsEmpty || B->IsEmpty )
    {
        return( S );
    }
    
    // Otherwise, form the intersection of the extent
    // lists of each section.
    S->ExtentList = 
        IntersectExtents( A->ExtentList,
                            B->ExtentList );
    
    // Set the status of the section.
    if( IsExtentsEmpty( S->ExtentList ) )
    {
        S->IsEmpty = 1;
    }
    else
    {
        S->IsEmpty = 0;
    }
    
    // Return the result.
    return( S );
}

/*------------------------------------------------------------
| IsCellInArray
|-------------------------------------------------------------
|
| PURPOSE: To test whether a cell is within an array.
|
| DESCRIPTION: Expects a vector specifying the cell address
| in the array.  Returns '1' if the cell is in the array,
| else returns '0'.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.16.96 from 'IsExtentInArray'.
|          04.23.96 changed '>' to '>=' for upper bound test.
------------------------------------------------------------*/
u32  
IsCellInArray( Array* A, u32* c )
{
    u32 DimCount, i;
    
    // Get the dimension count of the array.
    DimCount = A->DimCount;
    
    // Then make sure the cell is in the array.
    for( i = 0; i < DimCount; i++ )
    {
        if( ( *c >= A->DimExtent[i] ) ||
            ( *c < 0 ) )
        {
            return( 0 );
        }
        
        // To next dimension.
        c++;
    }
    
    // No problem.
    return( 1 );
}

/*------------------------------------------------------------
| IsSectionEmpty
|-------------------------------------------------------------
|
| PURPOSE: To test if a section is empty, referring of no
|          cells.
|
| DESCRIPTION: Tests the 'IsEmpty' flag of the 'Section' 
| record which is maintained by all operations that alter
| sections.
|
| EXAMPLE:     t = IsSectionEmpty( S );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.06.96 
|          03.10.96 updated for extents.
------------------------------------------------------------*/
u32  
IsSectionEmpty( Section* S )
{
    return( S->IsEmpty );
}

/*------------------------------------------------------------
| LoadArray
|-------------------------------------------------------------
|
| PURPOSE: To load an array from an ASCII file.
|
| DESCRIPTION: Reads the data previously written to a file
| using the 'SaveArray' procedure.  Returns the address of
| a dynamically allocated array or 0 if the file can't be
| opened.
|
| EXAMPLE: MyArray = LoadArray( "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.05.96 from 'SaveMatrix' and 
|                   'ReadListOfTextLines'.
|          06.07.96 made name integral to array.
------------------------------------------------------------*/
Array*
LoadArray( s8* AFileName )
{
    FILE*   AFile;
    f64 *   ACell;
    s16     ByteCount;
    s8      ABuffer[MaxLineBuffer];
    u32     i, c, CellCount;
    Array*  A;
    s8*     AtTextDatum;
    
    // Open the file.
    AFile = OpenFileTL(AFileName, ReadAccess);

    // Make sure it opened OK.
    if( AFile == 0 )
    {
        return( 0 );
    }
    
    // Allocate an array specification record.
    A = (Array*) malloc( sizeof( Array ) );
    
    // Get the array parameters.
    fscanf( AFile, 
            "%s %d %d\n", 
            &ABuffer, // Read the name to the buffer.
            &A->DimCount, 
            &A->CellCount );
    
    // If the name is not 'NoName' then set the name of
    // the array.
    if( CompareStringsCaseSensitive( (s8*) &ABuffer, 
                                     (s8*) "NoName" ) )
    {
        CopyString( ABuffer, &A->Name[0] );
    }
    else
    {
        A->Name[0] = 0;
    }
    
    // Read the dimension parameters, one dimension per line.
    for( i = 0; i < A->DimCount; i++ )
    {
        fscanf( AFile, 
                "%d %d\n",
                &A->DimExtent[i],
                &A->DimOffsetFactor[i] );
    }
    
    // Allocate the cell data area.        
    A->Data = (f64*) malloc( A->CellCount * sizeof(f64) );

    // Load the data cell values, up to 20 per line.
    CellCount = A->CellCount;
    ACell     = A->Data;

ReadLine:
    
    ByteCount = ReadMacTextLine(AFile, ABuffer);
        
    if( ByteCount == -1 ) goto Done;
    
    c = CountDataInString( (s8*) &ABuffer );

    // If there is data in this line then convert it
    // to binary and put it in the array.
    if( c )
    {
        AtTextDatum = (s8*) &ABuffer;
            
        for( i = 0; i < c; i++ )
        {
            *ACell++ = GetFirstDatumInString( AtTextDatum );
                
            AtTextDatum += CountOfBytesParsed;
            
            CellCount--; // Account for each cell.
        }
    }
    
    goto ReadLine;
    
Done:
        
    if( CellCount )
    {
        Debugger(); // CellCount mismatch.
    }
    
    CloseFile( AFile );
    
    return( A );
}

/*------------------------------------------------------------
| LoadArrayAsBinary
|-------------------------------------------------------------
|
| PURPOSE: To load an array from a binary file.
|
| DESCRIPTION: Ran three times faster than 'LoadArray' in one
| test on an index array: 14 secs vs. 42 secs.
|
| EXAMPLE: MyArray = LoadArrayAsBinary( "C:TestFile.DAT" );
|
| NOTE: See counterpart routine 'SaveArrayAsBinary'.
|
| ASSUMES: Array record size is same as when the array was
|          saved.
|           
| HISTORY: 06.07.96 from 'SaveArrayAsBinary'. Tested.
|          06.08.96 added 'BytesPerCell' to support integer
|                   arrays.
|          06.24.96 accomodated bit arrays.
|          07.06.96 added compressed file option.
|          07.24.96 converted to CRC32 from 16 bit version.
|          01.19.97 upgraded CRC16 for uncompressed to CRC32.
------------------------------------------------------------*/
Array*
LoadArrayAsBinary( s8* AFileName )
{
    BIT_FILE*   F;
    u32         ByteCount;
    s32         BytesRead;
    u32         DimCount;
    u32         CRC32;
    Array*      A;
        
    // Open binary file, possibly a compressed file.
    F = OpenInputBitFile( AFileName );

    // Allocate an array specification record.
    A = (Array*) malloc( sizeof( Array ) );

    // 
    //     L O A D   A R R A Y   H E A D E R
    //  
    BytesRead =
        ReadBytes( F->file,
                   (u8*) A,
                   sizeof(Array) );

    // Trap errors.
    if( BytesRead != sizeof(Array) )
    {
        Debugger();
    }
    
    // Get the number of dimensions.
    DimCount = A->DimCount;
    
    // Calculate how many bytes are in the array image.
    ByteCount = ((A->CellCount * A->BitsPerCell) + 7) / 8;

    // Allocate the data space for the array.
    A->Data = (f64*) malloc( ByteCount );

    // 
    //     L O A D   A R R A Y   I M A G E
    //
    if( A->Format == HuffmanEncodedCRC32 )
    {
        ExpandBytesFromFile( F, (u8*) A->Data );
    }
    else
    {   
        BytesRead =
            ReadBytes( F->file,
                       (u8*) A->Data,
                       ByteCount );
                    
        // Trap errors.
        if( BytesRead != (s32) ByteCount )
        {
            Debugger();
        }
    }
    
    // Close the array data file.
    CloseInputBitFile( F );

    // Validate the array data image.
    CRC32 = CRC32Bytes( (u8*) A->Data, ByteCount, 0 );
    
    if( CRC32 != A->CRC32 )
    {
        Debugger();
    }
    
    // Return the array.
    return( A );
}

/*------------------------------------------------------------
| MakeArray
|-------------------------------------------------------------
|
| PURPOSE: To make a new array record and allocate the
|          cell data area.
|
| DESCRIPTION: Expects a dimension count and a vector that
| defines how many cells are in each dimension.
|
| EXAMPLE: Make a four dimensional array with dimensions
| 3 x 5 x 6 x 8.
|
|      s32  DimExtent[4];
|      
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
| NOTE: Doesn't initialize the cell data.
|
| ASSUMES: 
|           
| HISTORY: 03.04.96 from 'MakeMatrix' and 'AppendStrings'.
|          03.06.96 made dimension specification a vector.
|          06.07.96 made dimension specs integral to 'Array'.
|          06.08.96 added 'BytesPerCell'.
|          06.24.96 accomodated bit arrays.
------------------------------------------------------------*/
Array*
MakeArray( u32 DimCount, u32* DimExtent )
{
    Array*  A;
    u32     i,Dim;
    u32     CellCount;
    
    // Allocate an array specification record.
    A = (Array*) malloc( sizeof( Array ) );
    
    A->DimCount = DimCount;
    
    CellCount   = 1;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension extent.
        Dim = DimExtent[i];
        
        // Save the extent in the Array record.
        A->DimExtent[i] = Dim;
        
        // Accumulate the number of cells in
        // the array.
        CellCount *= Dim;
    }
    
    // Save the total cell count.
    A->CellCount = CellCount;
    
    // Save the cell size: f64 data is 64 bits.
    A->BitsPerCell = 64;
    
    // Allocate the data for the array.
    A->Data = (f64*) malloc( CellCount * sizeof(f64) );
    
    // Compute the dimension offset factor.
    for( i = 0; i < DimCount; i++ )
    {
        CellCount /= A->DimExtent[i];
        
        A->DimOffsetFactor[i] = CellCount;
    }
    
    // Set a default name to be no name.
    A->Name[0] = 0;
    
    return( A );
}

/*------------------------------------------------------------
| MakeArrayListFromSectionList
|-------------------------------------------------------------
|
| PURPOSE: To make a list of different arrays that are
|          referenced in a list of sections.
|
| DESCRIPTION: Expects a standard list that refers to section
| records.  Returns a standard list that refers to array
| records, the count being contained in the list record.
| Duplicate references to arrays are removed.
|
| EXAMPLE: 
| 
|     c = MakeArrayListFromSectionList( S );
|
| NOTE: 
|
| ASSUMES: Section record specifies bounds for all dimensions. 
|           
| HISTORY: 03.05.96 from 'SumOfSection'. 
------------------------------------------------------------*/
List*
MakeArrayListFromSectionList( List* SectionList )
{
    List*    ArrayList;
    Section* S;
    
    // Create the list of arrays.
    ArrayList = MakeList();
    
    ReferToList( SectionList );
    
    // For each section.
    while( TheItem )
    {
        S = (Section*) TheDataAddress;
        
        // Put the section's array into the array list.
        InsertDataLastInList( ArrayList, (u8*) S->OfArray );
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Sort the array list by record address so that
    // 'DeleteDuplicateDataReferences' will work.
    SortListByDataAddress( ArrayList );
    
    // Delete the duplicate array references.
    DeleteDuplicateDataReferences( ArrayList );
    
    // Return the list of arrays.
    return( ArrayList );
}

/*------------------------------------------------------------
| MakeMultiDimensionalBitArray
|-------------------------------------------------------------
|
| PURPOSE: To make a new bit array.
|
| DESCRIPTION: Expects a dimension count and a vector that
| defines how many cells are in each dimension.
|
| EXAMPLE: Make a four dimensional bit array with 
| dimensions 3 x 5 x 6 x 8.
|
|      s32  DimExtent[4];
|      
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeMultiDimensionalBitArray( 4, DimExtent );
|
| NOTE: Doesn't initialize the cell data.
|
| ASSUMES: 
|           
| HISTORY: 06.24.96 from 'MakeIntegerArray'.
------------------------------------------------------------*/
Array*
MakeMultiDimensionalBitArray( u32 DimCount, u32* DimExtent )
{
    Array*  A;
    u32     i, Dim;
    u32     CellCount;
    u32     ByteCount;
    
    // Allocate an array specification record.
    A = (Array*) malloc( sizeof( Array ) );
    
    A->DimCount = DimCount;
    
    CellCount = 1;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension extent.
        Dim = DimExtent[i];
        
        // Save the extent in the Array record.
        A->DimExtent[i] = Dim;
        
        // Accumulate the number of cells in
        // the array.
        CellCount *= Dim;
    }
    
    // Save the total cell count.
    A->CellCount = CellCount;
    
    // Save the cell size.
    A->BitsPerCell = 1;
    
    // Calculate the least number of whole bytes that can
    // hold the bits of the array.
    ByteCount = (CellCount + 7) >> 3;
    
    // Allocate the data for the array.
    A->Data = (f64*) malloc( ByteCount );
    
    // Compute the dimension offset factor.
    for( i = 0; i < DimCount; i++ )
    {
        CellCount /= A->DimExtent[i];
        
        A->DimOffsetFactor[i] = CellCount;
    }
    
    // Set a default name to be no name.
    A->Name[0] = 0;
    
    return( A );
}

/*------------------------------------------------------------
| MakeIntegerArray
|-------------------------------------------------------------
|
| PURPOSE: To make a new integer array.
|
| DESCRIPTION: Expects a dimension count and a vector that
| defines how many cells are in each dimension.
|
| EXAMPLE: Make a four dimensional integer array with 
| dimensions 3 x 5 x 6 x 8.
|
|      s32  DimExtent[4];
|      
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeIntegerArray( 4, DimExtent );
|
| NOTE: Doesn't initialize the cell data.
|
| ASSUMES: 
|           
| HISTORY: 06.08.96 from 'MakeArray'.
|          06.24.96 accomodated bit arrays.
------------------------------------------------------------*/
Array*
MakeIntegerArray( u32 DimCount, u32* DimExtent )
{
    Array*  A;
    u32     i, Dim;
    u32     CellCount;
    
    // Allocate an array specification record.
    A = (Array*) malloc( sizeof( Array ) );
    
    A->DimCount = DimCount;
    
    CellCount   = 1;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension extent.
        Dim = DimExtent[i];
        
        // Save the extent in the Array record.
        A->DimExtent[i] = Dim;
        
        // Accumulate the number of cells in
        // the array.
        CellCount *= Dim;
    }
    
    // Save the total cell count.
    A->CellCount = CellCount;
    
    // Save the cell size.
    A->BitsPerCell = 16;
    
    // Allocate the data for the array.
    A->Data = (f64*) malloc( CellCount * sizeof(u16) );
    
    // Compute the dimension offset factor.
    for( i = 0; i < DimCount; i++ )
    {
        CellCount /= A->DimExtent[i];
        
        A->DimOffsetFactor[i] = CellCount;
    }
    
    // Set a default name to be no name.
    A->Name[0] = 0;
    
    return( A );
}

#ifdef USE_GROUPS
/*------------------------------------------------------------
| MakeGroup
|-------------------------------------------------------------
|
| PURPOSE: To make a new group record that refers to a group
|          of sections in one or more arrays.
|
| DESCRIPTION: Expects a list of sections to be included in
| the group.  Creates a group record and then computes the
| union and intersections between sections in the same
| array.  See 'TLArray.h' for more on 'Group' records.
| 
|
| EXAMPLE: G = MakeGroup( SectionList );
|
| NOTE: Groups may assigned an optional, dynamic name. 
|
| ASSUMES: 
|           
| HISTORY: 03.06.96 
------------------------------------------------------------*/
Group*
MakeGroup( List* SectionList )
{
    Group*      G;
    List*       ArrayList;
    Section*    S;
    s32         i;
    s32         DimCount;
    s32         ByteCount;
    
    // Allocate a group specification record.
    G = (Group*) malloc( sizeof( Group ) );
    
    // Make a list of arrays referenced in the section list.
    ArrayList = MakeArrayListFromSectionList( SectionList );
    
    // Save the array count in the group record.
    G->ArrayCount = ArrayList->ItemCount;
    
    // Allocate a vector to hold the array references.
    G->ToArray = (Array**)
                 malloc( G->ArrayCount * sizeof( Array* ) );
    
    // Copy the array references from the list to
    // the vector.
    ReferToList( ArrayList ); 

    for( i = 0; i < G->ArrayCount; i++ )
    {
        G->ToArray[i] = (Array*) TheDataAddress;
        ToNextItem();
    }
    
    RevertToList();
    
    // Delete the array list.
    DeleteList( ArrayList );
    
    // Allocate a vector of lists for the section lists.
    G->SectionLists = (List**)
            malloc( G->ArrayCount * sizeof( List* ) );
    for( i = 0; i < G->ArrayCount; i++ )
    {
        G->SectionLists[i] = MakeList();
    }
    
    // Allocate a vector of lists for the union lists.
    G->UnionLists = (List**)
            malloc( G->ArrayCount * sizeof( List* ) );
    for( i = 0; i < G->ArrayCount; i++ )
    {
        G->UnionLists[i] = MakeList();
    }
    
    // Allocate a vector of lists for the intersection lists.
    G->IntersectionLists = (List**)
            malloc( G->ArrayCount * sizeof( List* ) );
    for( i = 0; i < G->ArrayCount; i++ )
    {
        G->IntersectionLists[i] = MakeList();
    }
    
    // Now group sections according to the array they refer
    // to.
    ReferToList( SectionList );
    
    while( TheItem )
    {
        S = (Section*) TheDataAddress;
        
        // Find the index of the array this section belongs to.
        i = IndexOfArrayInGroup( G, S->OfArray );
        
        // Append an item to the array list for this section.
        InsertDataLastInAList( G->SectionLists[i], 
                               (u8*) S );
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Form the union lists.
    UpdateGroupUnions( G );
    
    // Form the intersection lists.
    UpdateGroupIntersections( G );
    
    // Set the default name to nothing.
    S->Name = 0;
    
    // Return the group.
    return( G );
}
#endif // USE_GROUPS

/*------------------------------------------------------------
| MakeSection
|-------------------------------------------------------------
|
| PURPOSE: To make a new section record that refers to section
|          of an array.
|
| DESCRIPTION: Expects an array and vectors which specify
| lower and upper limits of the section, where the upper limit
| is the address of the cell just beyond the section and the
| lower limit is the address of the first cell in the section.
|
| The reason that the upper bound is one beyond the last cell
| rather than being the last cell, is so that an empty section
| can be specified when upper and lower bounds equal.
|
| The section boundaries are copied to a dynamic buffer
| associated with the new section record: later this can be 
| deleted by 'DeleteSection'.
|
| For convenience, if an empty section is to be created, the 
| vector addresses can be set to 0.
|
| EXAMPLE: Make a section of a four dimensional array with 
| dimensions 3 x 5 x 6 x 8.  The section ranges from
| (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32  DimExtent[4];
|      s32  ACell[4];
|      s32  BCell[4];
|      Array*   A;
|      Section* S;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      ACell[0] = 1;
|      ACell[1] = 2;
|      ACell[2] = 3;
|      ACell[3] = 4;
|
|      BCell[0] = 3; // Upper bound is one larger than the 
|      BCell[1] = 4; // address of the last cell in the section.
|      BCell[2] = 5;
|      BCell[3] = 6;
|
|      S = MakeSection( A, ACell, BCell );
|
| NOTE: Sections may assigned an optional, dynamic name. 
|
| ASSUMES: The lower extents are <= the upper extents.
|           
| HISTORY: 03.06.96 
------------------------------------------------------------*/
Section*
MakeSection( Array* A, u32* Lo, u32* Hi )
{
    Section*    S;
    Extent*     o;
    u32         i;
    f64*        aLo;
    f64*        aHi;
    u32         DimCount;
    u32         ByteCount;
    
    // Allocate a section specification record.
    S = (Section*) malloc( sizeof( Section ) );
    
    // Save the array that this is a section of.
    S->OfArray = A;
    
    // Get the dimension count.
    DimCount = A->DimCount;
    
    // Allocate memory for the actual extents.
    ByteCount = DimCount * sizeof( f64 );
    aLo = (f64*) malloc( ByteCount );
    aHi = (f64*) malloc( ByteCount );
    
    // Convert universal extent specifications to 
    // their equivalent actual boundaries.
    for( i = 0; i < DimCount; i++ )
    {
        // If this is an empty section.
        if( Lo == 0 || Hi == 0 )
        {
            // Make an empty segment.
            aLo[i] = 0;
            aHi[i] = 0;
        }
        else
        {
            // If this is a universal section specification.
            if( (Lo[i] < 0) || (Hi[i] < 0) )
            {
                // Use the entire dimension.
                aLo[i] = 0;
                aHi[i] = (f64) A->DimExtent[i];
            }
            else // A literal specification.
            {
                aLo[i] = (f64) Lo[i];
                aHi[i] = (f64) Hi[i];
            }
        }
    }
    
    // Make an extent for the actual section extents.
    o = MakeExtent( DimCount, aLo, aHi );

    // Free the actual extent vectors.
    free( aLo );
    free( aHi );

    // Create a list for the extents of the section.
    S->ExtentList = MakeList();
    
    // Add the extent to the list.
    InsertDataLastInList( S->ExtentList, (u8*) o );
    
    // Clear the 'IsSum' flag to show that the 'Sum' is
    // invalid.
    S->IsSum = 0;
    
    // Test to see if the section is empty.
    S->IsEmpty = IsExtentEmpty( o );
    
    // Set the default name to nothing.
    S->Name = 0;
    
    // Return the section.
    return( S );
}

/*------------------------------------------------------------
| MultiplyToSection
|-------------------------------------------------------------
|
| PURPOSE: To multiply a value to each cell in a section of an 
|          array.
|
| DESCRIPTION: Expects a section record specifying the bounds
| of the section in the array. The 'Lo' bound is the first
| cell to be included in the section and the 'Hi' bound is one
| larger than the last cell to be included in the section.
|
| EXAMPLE: Multiply .001 to a section of a four dimensional 
| array with dimensions 3 x 5 x 6 x 8.  
| The section ranges from (1,2,3,4) to (2,3,4,5) inclusive.
|
|      s32  DimExtent[4];
|      s32  ACell[4];
|      s32  BCell[4];
|      Array*   A;
|      Section* S;
|
|      DimExtent[0] = 3;
|      DimExtent[1] = 5;
|      DimExtent[2] = 6;
|      DimExtent[3] = 8;
|      
|      A = MakeArray( 4, DimExtent );
|
|      ACell[0] = 1;
|      ACell[1] = 2;
|      ACell[2] = 3;
|      ACell[3] = 4;
|
|      BCell[0] = 3; // Upper bound is one larger than the 
|      BCell[1] = 4; // address of the last cell in the section.
|      BCell[2] = 5;
|      BCell[3] = 6;
|
|      S = MakeSection( A, ACell, BCell );
| 
|      MultiplyToSection( S, .001 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.06.96 from 'FillSection'. 
------------------------------------------------------------*/
void
MultiplyToSection( Section* S, f64 v )
{
    Array*  A;
    
    // Refer to the array.
    A = S->OfArray;
    
    // For each extent.
    ReferToList( S->ExtentList ); 
    
    while( TheItem )
    {
        // Multiply the value to each cell in the extent.
        MultiplyToExtent( A, 
                            (Extent*) TheDataAddress,
                            v );
        ToNextItem();
    }
    RevertToList();
}

/*------------------------------------------------------------
| OnesArray
|-------------------------------------------------------------
|
| PURPOSE: To fill an array with ones.
|
| DESCRIPTION:  
|
| EXAMPLE:  OnesArray( A );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.06.96 from 'ZeroArray'.
------------------------------------------------------------*/
void
OnesArray( Array* A )
{
    u32   CellCount;
    f64* ACell;
    
    ACell  = A->Data;
    
    CellCount = A->CellCount;
    
    while( CellCount-- )
    {
        *ACell++ = 1.0;
    }
}

/*------------------------------------------------------------
| Put
|-------------------------------------------------------------
|
| PURPOSE: To put a value into a cell of an array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Put .023 into the cell (2,3,4,5) of array A:
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      Put( A, ACell, .023 );
|
| NOTE: 
|
| ASSUMES: Dimensions are zero-based.
|           
| HISTORY: 03.05.96
|          03.06.96 Made cell address a vector.
------------------------------------------------------------*/
void
Put( Array* A, u32* ACell, f64 v )
{
    u32     i, Dim;
    u32     DimCount;
    u32     CellOffset;
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateCellInArray( A, ACell );
#endif

    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    CellOffset = 0;
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension index.
        Dim = *ACell++;
        
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[i] * Dim;
    }
    
    // Put the value in the cell.
    A->Data[CellOffset] = v;
}

/*------------------------------------------------------------
| PutBit
|-------------------------------------------------------------
|
| PURPOSE: To put a bit value into the cell of a bit array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Set the value of cell (2,3,4,5) in array A to '1':
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      v = PutBit( A, ACell, 1 );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 06.24.96 from 'GetBit'.
------------------------------------------------------------*/
void
PutBit( Array* A, u32* ACell, u32 v )
{
    u32     i;
    u32     DimCount;
    u32     BitOffset, ByteOffset;
    u8*     ByteAddr;
    u32     BitNum;
    u32*    DimOffset;              
    
    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    BitOffset = 0;
    DimOffset = &A->DimOffsetFactor[0];
    for( i = 0; i < DimCount; i++ )
    {
        // Accumulate the cell offset.
        BitOffset += *DimOffset++ * *ACell++;
    }
    
    // Convert bit offset to byte offset and bit-in-byte.
    ByteOffset = BitOffset >> 3;
    BitNum     = BitOffset & 7; // Leaving a value from 0-7.
    
    // Calculate the address of the byte containing the bit.
    ByteAddr = ((u8*)A->Data) + ByteOffset;
    
    if( v )
    {
         // Put a 1 bit into the cell.
        *ByteAddr |= BitOfByte[BitNum];
    }
    else // Put a 0 bit into the cell.
    {
        *ByteAddr &= NotBitOfByte[BitNum];
    }
}

/*------------------------------------------------------------
| PutInteger
|-------------------------------------------------------------
|
| PURPOSE: To put a value into a cell of an integer array.
|
| DESCRIPTION: Expects a vector, organized in order
| of array dimensions, that refers to the desired cell.
|
| EXAMPLE: Put .023 into the cell (2,3,4,5) of array A:
|
|      s32  ACell[4];
|
|      ACell[0] = 2;
|      ACell[1] = 3;
|      ACell[2] = 4;
|      ACell[3] = 5;
|
|      PutInteger( A, ACell, 4 );
|
| NOTE: 
|
| ASSUMES: Dimensions are zero-based.
|           
| HISTORY: 06.08.96 from 'Put'.
|          03.06.96 Made cell address a vector.
------------------------------------------------------------*/
void
PutInteger( Array* A, u32* ACell, u16 v )
{
    u32     i, Dim;
    u32     DimCount;
    u32     CellOffset;
    
#ifdef ARRAY_ERROR_CHECKING
    ValidateCellInArray( A, ACell );
#endif

    // Get the dimension count from the array record.
    DimCount = A->DimCount;
    
    // For each dimension.
    CellOffset = 0;
    for( i = 0; i < DimCount; i++ )
    {
        // Get the dimension index.
        Dim = *ACell++;
        
        // Accumulate the cell offset.
        CellOffset += A->DimOffsetFactor[i] * Dim;
    }
    
    // Put the value in the cell.
    ((u16*)A->Data)[CellOffset] = v;
}

/*------------------------------------------------------------
| ReviseSection
|-------------------------------------------------------------
|
| PURPOSE: To change the size or placement of a section in
|          its current array.
|
| DESCRIPTION: Same as 'MakeSection' but used to adjust
| an existing section.
|
| Doesn't alter the name if there is one.
|
| EXAMPLE: 
|
|       ReviseSection( S, Lo, Hi );
|
| NOTE:  
|
| ASSUMES: The lower extents are <= the upper extents.
|           
| HISTORY: 03.10.96 from 'MakeSection'.
|          01.20.98 Made bounds unsigned.
------------------------------------------------------------*/
void
ReviseSection( Section* S, u32* Lo, u32* Hi )
{
    Extent*     o;
    u32         i;
    f64*        aLo;
    f64*        aHi;
    u32         DimCount;
    u32         ByteCount;
    
    // Get the dimension count.
    DimCount = S->OfArray->DimCount;
    
    // Allocate memory for the actual extents.
    ByteCount = DimCount * sizeof( f64 );
    
    aLo = (f64*) malloc( ByteCount );
    aHi = (f64*) malloc( ByteCount );
    
    // Convert universal extent specifications to 
    // their equivalent actual boundaries.
    for( i = 0; i < DimCount; i++ )
    {
        // If this is an empty section.
        if( Lo == 0 || Hi == 0 )
        {
            // Make an empty segment.
            aLo[i] = 0;
            aHi[i] = 0;
        }
        else
        {
            // If this is a universal section specification.
            if( (Lo[i] < 0) || (Hi[i] < 0) )
            {
                // Use the entire dimension.
                aLo[i] = 0;
                aHi[i] = (f64) S->OfArray->DimExtent[i];
            }
            else // A literal specification.
            {
                aLo[i] = (f64) Lo[i];
                aHi[i] = (f64) Hi[i];
            }
        }
    }
    
    // Make an extent for the actual section extents.
    o = MakeExtent( DimCount, aLo, aHi );

    // Free the actual extent vectors.
    free( aLo );
    free( aHi );
    
    // Delete the current list of extents.
    DeleteListOfDynamicData( S->ExtentList );
    
    // Create a new list for the extents of the section.
    S->ExtentList = MakeList();
    
    // Add the extent to the list.
    InsertDataLastInList( S->ExtentList, (u8*) o );
    
    // Clear the 'IsSum' flag to show that the 'Sum' is
    // invalid.
    S->IsSum = 0;
    
    // Test to see if the section is empty.
    S->IsEmpty = IsExtentEmpty( o );
}

/*------------------------------------------------------------
| SaveArray
|-------------------------------------------------------------
|
| PURPOSE: To save an array to an ASCII file.
|
| DESCRIPTION: 
|
| EXAMPLE: SaveArray( MyArray, "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.05.96 from 'SaveMatrix'.
|          03.06.96 improved formatting.
------------------------------------------------------------*/
void
SaveArray( Array* A, s8* AFileName )
{
    FILE*   AFile;
    f64 *   ACell;
    s8*     AtNumberString;
    u32     i;
    u32     DimCount, d, LastDim, CellOffset;
    static u32* Index;  
    static u32  IndexCount = 0;
    
    // Open the file.
    AFile = ReOpenFile(AFileName);
    
    // Save the array parameters.
    if( A->Name )
    {
        fprintf( AFile, 
                 "%s %d %d\n", 
                 &A->Name, 
                 A->DimCount, 
                 A->CellCount );
    }
    else
    {
        fprintf( AFile, 
                 "%s %d %d\n", 
                 "NoName", 
                 A->DimCount, 
                 A->CellCount );
    }
            
    // Save the dimension parameters, one per line.
    for( i = 0; i < A->DimCount; i++ )
    {
        fprintf( AFile, 
                 "%d %d\n",
                 A->DimExtent[i],
                 A->DimOffsetFactor[i] );
    }

    // Get the number of dimensions.
    DimCount = A->DimCount;
    
    // If the dimension count is larger than the space
    // in the index buffer, make enough room.
    if( DimCount > IndexCount )
    {
        // If there is an existing buffer, free it.
        if( IndexCount )
        {
            free( Index );
        }
        
        // Allocate a buffer to hold the indices.
        Index = (u32*) malloc( DimCount * sizeof( s32 ));
        
        // Retain the size of the buffer.
        IndexCount = DimCount;
    }
    
    // For each dimension set the index to start of
    // dimension.
    for( d = 0; d < DimCount; d++ )
    {
        // Refer to the first cell in this dimension. 
        Index[d] = 0;
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
    
    // Test for not a number.
    if( ISNAN(*ACell) || *ACell == NoNum )
    {
        AtNumberString = (s8*) "NaN";
    }
    else
    {
        UseFixedPointFormat = 0;
        UseScientificFormat = 0;
            
        AtNumberString = 
                ConvertNumberToString( (Number) *ACell );
    }
    
    // Output the cell value followed by a tab.
    fprintf(AFile,"%s\t", AtNumberString);
    
    // Advance to next cell.
    ACell++;
    
    // Advance the index of the last dimension
    // and check for the upper bound of the run.
    Index[LastDim]++;
    
    if( Index[LastDim] < A->DimExtent[LastDim] )
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
            if( Index[d] == A->DimExtent[d] )
            {
                // Reset to lower bound.
                Index[d] = 0;
                
                // Increment next outer dimension.
                Index[d-1]++;
                
                // Output an end-of-line character. 
                fprintf( AFile, "\n" );
            }
        }
        
        // If the first dimension exceeds its bounds
        // then we are done.
        if( Index[0] == A->DimExtent[0] )
        {
            goto Done;
        }
    }
    
    goto DoCurrentCell;

Done:
        
    CloseFile(AFile);
    
#if macintosh   
    /* Set the file to an MPW document for now. */
    SetFileType(AFileName,(s8*) "TEXT");
    SetFileCreator(AFileName,(s8*) "MPS ");
#endif
}

/*------------------------------------------------------------
| SaveArrayAsBinary
|-------------------------------------------------------------
|
| PURPOSE: To save an array to a binary file.
|
| DESCRIPTION: 
|
| EXAMPLE: SaveArrayAsBinary( MyArray, "C:TestFile.DAT" );
|
| NOTE: See counterpart routine 'LoadArrayAsBinary'.
|
| ASSUMES: 
|           
| HISTORY: 06.07.96 from  'SaveMatrixAsBinary'.
|          06.08.96 added 'BytesPerCell'.
|          06.24.96 accomodated bit arrays.
|          01.19.97 revised to use CRC32 instead of CRC16.
------------------------------------------------------------*/
void
SaveArrayAsBinary( Array* A, s8* AFileName )
{
    FILE*   AFile;
    u32     ByteCount;
    u32     BytesWritten;
    u32     DimCount;
        
    // Get the number of dimensions.
    DimCount = A->DimCount;

    // Create/recreate binary file.
    AFile = ReOpenFile(AFileName);

    // Calculate how many bytes are in the array image.
    ByteCount = ((A->CellCount * A->BitsPerCell) + 7) / 8;
    
    // Compute the check sum for the array data image.
    A->CRC32 = CRC32Bytes( (u8*) A->Data, ByteCount, 0 );

    // Set the format code in the header.
    A->Format = Uncompressed;

    // 
    //     S A V E   A R R A Y   H E A D E R
    //  
    WriteBytes( AFile,
                (u8*) A,
                sizeof(Array) );
    
    // 
    //     S A V E   A R R A Y   I M A G E
    //  
    BytesWritten = 
        WriteBytes( AFile,
                    (u8*) A->Data,
                    ByteCount );
        
    fflush(AFile);
    
    CloseFile(AFile);
    
#if macintosh   
    // Set the file type and creator. 
    SetFileType(AFileName,(s8*) "ARRY");
    SetFileCreator(AFileName,(s8*) "$$$$");
#endif
}

/*------------------------------------------------------------
| SaveArrayAsBinaryCompressed
|-------------------------------------------------------------
|
| PURPOSE: To save an array to a binary file.
|
| DESCRIPTION: 
|
| EXAMPLE: SaveArrayAsBinary( MyArray, "C:TestFile.DAT" );
|
| NOTE: See counterpart routine 'LoadArrayAsBinary'.
|
| ASSUMES: 
|           
| HISTORY: 07.06.96 from  'SaveArrayAsBinary'.
|          07.24.96 converted to CRC32 from 16 bit version.
------------------------------------------------------------*/
void
SaveArrayAsBinaryCompressed( Array* A, s8* AFileName )
{
    BIT_FILE* F;
    u32       ByteCount;
    u32       DimCount;
        
    // Get the number of dimensions.
    DimCount = A->DimCount;

    // Create/recreate binary file.
    F = OpenOutputBitFile( AFileName );

    // Calculate how many bytes are in the array image.
    ByteCount = ((A->CellCount * A->BitsPerCell) + 7) / 8;
    
    // Compute the check sum for the array data image.
    A->CRC32 = CRC32Bytes( (u8*) A->Data, ByteCount, 0 );

    // Set the format code in the header.
    A->Format = HuffmanEncodedCRC32;
    
    // 
    //     S A V E   A R R A Y   H E A D E R
    //  
    WriteBytes( F->file,
                (u8*) A,
                sizeof(Array) );
    
    // 
    //     S A V E   A R R A Y   I M A G E
    //  
    CompressBytesToFile( F, (u8*) A->Data, ByteCount );

    CloseOutputBitFile( F );
        
#if macintosh       
    // Set the file type and creator. 
    SetFileType(AFileName,(s8*) "ARRY");
    SetFileCreator(AFileName,(s8*) "$$$$");
#endif
}

/*------------------------------------------------------------
| SectionToItems
|-------------------------------------------------------------
|
| PURPOSE: To copy the cells in a section of an array into
|          dynamically allocated vector.
|
| DESCRIPTION: Expects a section record specifying the bounds
| of the section in the array. The 'Lo' bound is the first
| cell to be included in the sum and the 'Hi' bound is one
| larger than the last cell to be included in the sum.
|
| If all cells in a dimension are to be included, the start
| and end values of (0,0) can be used to signal this.
|
| EXAMPLE: 
|
|     Section   S;
|
|     S.OfArray = A;
|     S.Lo[0]   = xmin;  S.Hi[0]   = xmax;
|     S.Lo[1]   = ymin;  S.Hi[1]   = ymax;
|     S.Lo[2]   = zmin;  S.Hi[2]   = zmax;
| 
|     v = SectionToItems( &S );
|
| NOTE: 
|
| ASSUMES: Section record specifies bounds for all dimensions. 
|           
| HISTORY: 03.05.96 from 'SumOfSection'. 
|          01.20.98 Pulled out unreferenced label, 'Done'.
------------------------------------------------------------*/
f64*
SectionToItems( Section* S )
{
    Array*  A;
    f64     *ACell;
    f64 *VCell;
    f64 *V;
    Extent* o;
    u32     DimCount, d, LastDim, CellOffset, CellCount;
    static u32* Index;  
    static u32  IndexCount = 0;
    
    // Refer to the array.
    A = S->OfArray;
    
    // Get the number of dimensions.
    DimCount = A->DimCount;

    // Calculate the index of the last dimension for speed.
    LastDim = DimCount - 1;

    // If the dimension count is larger than the space
    // in the index buffer, make enough room.
    if( DimCount > IndexCount )
    {
        // If there is an existing buffer, free it.
        if( IndexCount )
        {
            free( Index );
        }
        
        // Allocate a buffer to hold the indices.
        Index = (u32*) malloc( DimCount * sizeof( s32 ));
        
        // Retain the size of the buffer.
        IndexCount = DimCount;
    }

    // Count the cells in the section.
    CellCount = CountCellsInSection( S );
    
    // Allocate the buffer to hold the vector.
    V = (f64*) malloc( CellCount * sizeof(f64) );
    
    // Refer to the first cell in the vector buffer.
    VCell = V;
    
    // 
    //    F O R   E A C H   O R T H O G O N
    //
    ReferToList( S->ExtentList );
    
    while( TheItem )
    {
        // Refer to the extent.
        o = (Extent*) TheDataAddress;
        
        // For each dimension set the index to start of
        // segment.
        for( d = 0; d < DimCount; d++ )
        {
            // Refer to the first cell in this segment. 
            Index[d] = (u32) o->Lo[d];
        }

CopyCurrentCell: // Copy the current cell to the vector.
    
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
    
        // Copy the value to the vector.
        *VCell++ = *ACell++;
    
        // Advance the index of the last dimension
        // and check for the upper bound of the run.
        Index[LastDim]++;
    
        if( Index[LastDim] < o->Hi[LastDim] )
        {
            // More in this run, so add them.
            goto NextCell;
        }
        else // End of last dimension reached.
             // adjust the indices.
        {
            for( d = LastDim; d > 0; d-- )
            {
                // If end of this dimension reached.
                if( Index[d] == o->Hi[d] )
                {
                    // Reset to lower bound.
                    Index[d] = (u32) o->Lo[d];
                
                    // Increment next outer dimension.
                    Index[d-1]++;
                }
            }
        
            // If the first dimension exceeds its bounds
            // then we are done with this extent.
            if( Index[0] == o->Hi[0] )
            {
                goto DoneExtent;
            }
        }
    
        goto CopyCurrentCell;
    
DoneExtent:
        ToNextItem();
    }
    
    RevertToList();
    
    return( V );
}   

/*------------------------------------------------------------
| SumOfArray
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in an array.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumOfArray( A );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.05.96 from 'SumOfMatrix'. 
------------------------------------------------------------*/
f64
SumOfArray( Array* A )
{
    f64 Sum;
    f64 *AtCell;
    u32  CellCount;
    
    AtCell    = A->Data;
    CellCount = A->CellCount;
    Sum       = 0;
    
    while( CellCount-- )
    {
        Sum += *AtCell++;
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| SumOfSection
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a section of an array.
|
| DESCRIPTION: Expects a section record specifying the bounds
| of the section in the array. The 'Lo' bound is the first
| cell to be included in the sum and the 'Hi' bound is one
| larger than the last cell to be included in the sum.
|
| EXAMPLE: 
|
|     Section*  S;
|     s32       Lo[3],Hi[3];
|
|     Lo[0]   = xmin;  Hi[0]   = xmax;
|     Lo[1]   = ymin;  Hi[1]   = ymax;
|     Lo[2]   = zmin;  Hi[2]   = zmax;
|
|     S = MakeSection( A, Lo, Hi );
|
|     s = SumOfSection( S );
|
| NOTE: 
|
| ASSUMES: Section record specifies bounds for all dimensions. 
|           
| HISTORY: 03.05.96 from 'SumOfArray'. 
------------------------------------------------------------*/
f64
SumOfSection( Section* S )
{
    Array*  A;
    f64 Sum;
    
    // If the sum is valid, just return it.
    if( S->IsSum )
    {
        return( S->Sum );
    }
    
    // Refer to the array.
    A = S->OfArray;
    
    // Begin the summation.
    Sum = 0;
    
    // For each extent.
    ReferToList( S->ExtentList );

    while( TheItem )
    {
        // Add up each cell in the extent.
        Sum += SumOfExtent( A, 
                              (Extent*) TheDataAddress );
        ToNextItem();
    }
    RevertToList();
    
    // Save the sum for later.
    S->Sum   = Sum;
    S->IsSum = 1;
    
    // Return the sum.
    return( Sum );
}

/*------------------------------------------------------------
| TestArray
|-------------------------------------------------------------
|
| PURPOSE: To test array procedures.
|
| DESCRIPTION:  
|
| EXAMPLE:  TestArray();
|
| NOTE: 
|
| ASSUMES: The list system has been set up.
|           
| HISTORY: 03.05.96 
|          03.06.96 made sections dynamic, cell addresses
|                   made into vectors.
------------------------------------------------------------*/
void
TestArray()
{
    Array*   A;
    Array*   B;
    Section* S;
    Section* Sa;
    Section* Sb;
    Section* Si;
    f64  s;
    u32      c,i,j,k;
    u32      ADims[3];
    u32      ACell[3];
    u32      Lo[3];
    u32      Hi[3];
    f64*     V1;
    f64*     V2;
    
    ADims[0] = 3;
    ADims[1] = 3;
    ADims[2] = 3;
        
    A = MakeArray( 3, ADims );
    
    ZeroArray( A );
    
    s = SumOfArray( A );
    
    if( s != 0 ) Debugger();
    
    ACell[0] = 0;
    ACell[1] = 0;
    ACell[2] = 0;
    
    Put( A, ACell, 1.0 );
    
    s = SumOfArray( A );
    
    if( s != 1.0 ) Debugger();
    
    s = Get( A, ACell );
    
    if( s != 1.0 ) Debugger();
    
    ACell[0] = 1;
    Put( A, ACell, 2.0 );
    ACell[0] = 2;
    Put( A, ACell, 3.0 );
    
    s = SumOfArray( A );
    
    if( s != 6.0 ) Debugger();
    
    // Make a section of array A, consisting of the
    // entire array.

    Lo[0] = 0;  Hi[0] = 3;
    Lo[1] = 0;  Hi[1] = 3;
    Lo[2] = 0;  Hi[2] = 3;

    S = MakeSection( A, Lo, Hi );
    
    s = SumOfSection( S );
    
    if( s != 6.0 ) Debugger();

    Lo[0] = 1; Hi[0] = 2;
    ReviseSection( S, Lo, Hi );

    s = SumOfSection( S );
    
    if( s != 2.0 ) Debugger();

    Lo[0] = 1; Hi[0] = 3;
    ReviseSection( S, Lo, Hi );

    s = SumOfSection( S );
    
    if( s != 5.0 ) Debugger();
    
    SaveArray( A, (s8*) "ArrayTest" );
    
    B = LoadArray( (s8*) "ArrayTest" );
    
    s = SumOfArray( B );
    
    if( s != 6 ) Debugger();

    Lo[0] = 0;  Hi[0] = 3;
    Lo[1] = 0;  Hi[1] = 3;
    Lo[2] = 0;  Hi[2] = 3;
    ReviseSection( S, Lo, Hi );

    c = CountCellsInSection( S );
    
    if( c != 27 ) Debugger();
    
    Lo[0] = 0;  Hi[0] = 3;
    Lo[1] = 0;  Hi[1] = 3;
    Lo[2] = 0;  Hi[2] = 3;
    ReviseSection( S, Lo, Hi );
    
    c = CountCellsInSection( S );
    
    if( c != 27 ) Debugger();
    
    Lo[0] = 0; Hi[0] = 1;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 0; Hi[2] = 3;
    ReviseSection( S, Lo, Hi );
    
    c = CountCellsInSection( S );
    
    if( c != 9 ) Debugger();
    
    Lo[0] = 0; Hi[0] = 1;
    Lo[1] = 0; Hi[1] = 1;
    Lo[2] = 0; Hi[2] = 3;
    ReviseSection( S, Lo, Hi );
    
    c = CountCellsInSection( S );
    
    if( c != 3 ) Debugger();
    
    Lo[0] = 1; Hi[0] = 2;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 0; Hi[2] = 3;
    ReviseSection( S, Lo, Hi );

    FillSection( S, 5.0 );
    
    s = SumOfSection( S );
    
    if( s != 45.0 ) Debugger();
    
    SaveArray( A, (s8*) "ArrayTest2" );
    
    V1 = SectionToItems( S );
    
    SaveItems( V1, 
               CountCellsInSection( S ),
               (s8*) "ArrayTextVector" );
    
    for( i = 0; i < 3; i++ )
    {
        ACell[0] = i;
        for( j = 0; j < 3; j++ ) 
        {
            ACell[1] = j;
            for( k = 0; k < 3; k++ ) 
            {
                ACell[2] = k;

                Put( A, ACell, (f64) i );
            }
        }
    }
               
    SaveArray( A, (s8*) "ArrayTest3" );
    
    V2 = SectionToItems( S );
    
    SaveItems( V2, 
                CountCellsInSection( S ),
                (s8*) "ArrayTextVector2" );
    
    Lo[0] = 0; Hi[0] = 3;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 0; Hi[2] = 1;
    ReviseSection( S, Lo, Hi );

    FillSection( S, 1.0 );

    Lo[0] = 0; Hi[0] = 3;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 1; Hi[2] = 2;
    ReviseSection( S, Lo, Hi );

    FillSection( S, 2.0 );

    Lo[0] = 0; Hi[0] = 3;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 2; Hi[2] = 3;
    ReviseSection( S, Lo, Hi );

    FillSection( S, 3.0 );

    SaveArray( A, (s8*) "ArrayTest4" );


    Lo[0] = 0; Hi[0] = 1;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 0; Hi[2] = 3;
    ReviseSection( S, Lo, Hi );

    FillSection( S, 1.0 );

    Lo[0] = 1; Hi[0] = 2;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 0; Hi[2] = 3;
    ReviseSection( S, Lo, Hi );
    FillSection( S, 2.0 );

    Lo[0] = 2; Hi[0] = 3;
    Lo[1] = 0; Hi[1] = 3;
    Lo[2] = 0; Hi[2] = 3;
    ReviseSection( S, Lo, Hi );
    FillSection( S, 3.0 );

    SaveArray( A, (s8*) "ArrayTest5" );

    free( V1 );
    free( V2 );
    
    DeleteSection( S );
    DeleteArray( A );
    DeleteArray( B );

    // Begin test of section intersection.
    ADims[0] = 5;
    ADims[1] = 5;
    ADims[2] = 5;
    
    A = MakeArray( 3, ADims );
    
    // Make the first section consist of the 2/3rd of
    // array (x,y,2/3z).
    Lo[0] = 0;  Hi[0] = 5;
    Lo[1] = 0;  Hi[1] = 5;
    Lo[2] = 0;  Hi[2] = 2;
    
    Sa = MakeSection( A, Lo, Hi );
    Sa->Name = DuplicateString((s8*) "Sa");
    
    // Make the second section consist of the 2/3rd of
    // array (2/3x,y,z).
    Lo[0] = 0;  Hi[0] = 2;
    Lo[1] = 0;  Hi[1] = 5;
    Lo[2] = 0;  Hi[2] = 5;
    
    Sb = MakeSection( A, Lo, Hi );
    Sb->Name = DuplicateString((s8*) "Sb");
    
    // Form the intersection of (Sa,Sb).
    Si = Intersect( Sa, Sb );
    
    if( IsSectionEmpty( Si ) ) Debugger();

    // One-fill the array.
    OnesArray( A );
    
    // Multiply a different number to each section.
    MultiplyToSection( Sa, 2.0 );
    MultiplyToSection( Sb, 3.0 );
    MultiplyToSection( Si, 5.0 );
     
    // Save to file.
    SaveArray( A, (s8*) "TestIntersect" );
    
    DeleteSection( Si );
    
    // Now test for an empty intersection.
    Lo[0] = 0; Hi[0] = 1;
    Lo[1] = 0; Hi[1] = 1;
    Lo[2] = 0; Hi[2] = 1;
    ReviseSection( Sa, Lo, Hi );
    Lo[0] = 1; Hi[0] = 2;
    Lo[1] = 1; Hi[1] = 2;
    Lo[2] = 1; Hi[2] = 2;
    ReviseSection( Sb, Lo, Hi );
    
    // Form the intersection of (Sa,Sb).
    Si = Intersect( Sa, Sb );

    if( ! IsSectionEmpty( Si ) ) Debugger();
    // END INTERSECT TEST.
    
    DeleteSection( Sa );
    DeleteSection( Sb );
    DeleteSection( Si );
    DeleteArray( A );
    
    CleanUpTheListSystem();
    
//  DumpUnitsInUse();
    
    exit(0);
}

/*------------------------------------------------------------
| Unite
|-------------------------------------------------------------
|
| PURPOSE: To find the union of two sections in the
|          same array.
|
| DESCRIPTION: Creates a new section record consisting of
| the union of two sections of the same array.  
|
| If the sections both have names, the resulting section will 
| have a name generated by combination of the original names:
|
| e.g. If "A" and "B" are sections to be formed into an
|      union, then the result will be named:
|
|           "(A+B)"
|
| EXAMPLE:  S = Unite( A, B );
|
| NOTE: 
|
| ASSUMES: The sections are in the same array.
|           
| HISTORY: 03.10.96 from 'Intersect'.
------------------------------------------------------------*/
Section*
Unite( Section* A, Section* B )
{
    Section*    S;
    u32         i;
    
    // Make a new empty section record using the same array
    // as is used by 'A'.
    S = MakeSection( A->OfArray, 0, 0 );
    
    // If the sections both have names, generate a name for
    // the intersection.
    if( A->Name && B->Name )
    {
        i = CountString( A->Name ) +
            CountString( B->Name ) + 3;
        
        S->Name = AllocateString(i);
        
        AppendStrings( S->Name,
                       (s8*) "(", 
                       A->Name, 
                       "+", 
                       B->Name,
                       (s8*) ")", 0 );
    }
    
    // Otherwise, form the intersection of the extent
    // lists of each section.
    S->ExtentList = 
        UniteExtents( A->ExtentList,
                        B->ExtentList );
    
    // Set the status of the section.
    if( IsExtentsEmpty( S->ExtentList ) )
    {
        S->IsEmpty = 1;
    }
    else
    {
        S->IsEmpty = 0;
    }
    
    // Return the result.
    return( S );
}

/*------------------------------------------------------------
| ValidateCellInArray
|-------------------------------------------------------------
|
| PURPOSE: To test whether a cell is valid with respect
|          to an array.
|
| DESCRIPTION: Expects a vector specifying the cell in the
| array. Halts in the debugger if the cell isn't in the array.
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
ValidateCellInArray( Array* A, u32* c )
{
    // Make sure the extent is in the array.
    if( ! IsCellInArray( A, c ) )
    {
        Debugger();
    }
}

/*------------------------------------------------------------
| ZeroArray
|-------------------------------------------------------------
|
| PURPOSE: To fill an array with zeros.
|
| DESCRIPTION:  
|
| EXAMPLE:  ZeroArray( A );
|
| NOTE: 
|
| ASSUMES: Floating point zero is all 0 bits.
|           
| HISTORY: 03.05.96 from 'ZeroMatrix'.
|          06.08.96 updated for integer arrays.
|          06.24.96 accomodated bit arrays.
------------------------------------------------------------*/
void
ZeroArray( Array* A )
{
    u32   ByteCount;
    f64* RealBase;
    
    RealBase  = A->Data;
    
    ByteCount = ((A->CellCount * A->BitsPerCell) + 7) / 8;
    
    memset( (void*) RealBase, 0, ByteCount );
}

