/*------------------------------------------------------------
| TLMatrixInput.c
|-------------------------------------------------------------
|
| PURPOSE: To provide data matrix input functions.
|
| HISTORY: 01.30.00 Separated from 'TLMatrix.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"  
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStrings.h"
#include "TLList.h"
#include "TLListIO.h"
#include "TLFile.h"
#include "TLStacks.h"
#include "TLParse.h"  // for 'ParseDatum'
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLNumber.h" // for 'ConvertStringToNumber'
                      // and 'ConvertNumberToString'
#include "TLf64.h"
#include "TLDate.h" 
#include "TLItems.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLVector.h"
#include "TLMatrixMath.h"
#include "TLMatrixExtra.h"
#include "TLMatrixInput.h"

/*------------------------------------------------------------
| LoadListOfMatricesAsBinary
|-------------------------------------------------------------
|
| PURPOSE: To load a list of matrices from the current 
|          position of a file in binary form.
|
| DESCRIPTION: Reads a 32-bit matrix count followed by the
| matrix data.  If a matrix header showing zero rows and 
| columns read then no matrix is created and instead an item
| is added to the list with the data address field holding
| zero as a placeholder.
|
| EXAMPLE: 
|
|           L = LoadListOfMatricesAsBinary( F );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.14.97 
------------------------------------------------------------*/
List*
LoadListOfMatricesAsBinary( FILE* AFile )
{
    s32     MatrixCount;
    u32     ByteCount;
    s32     BytesRead;
    Matrix  MatrixHeader;
    Matrix* AMatrix;
    List*   L;
    s32     i;
    
    // Make a list to hold the matrices.
    L = MakeList();
    
    // Read the matrix count.
    BytesRead = ReadBytes( AFile,
                           (u8*) &MatrixCount,
                           sizeof(s32) );
    // Trap errors.
    if( (u32) BytesRead != sizeof(s32) )
    {
        Debugger();
    }
 
    // For each matrix.
    for( i = 0; i < MatrixCount; i++ )
    {
        // 
        //     L O A D   M A T R I X   H E A D E R
        //  
        BytesRead =
            ReadBytes( AFile,
                       (u8*) &MatrixHeader,
                       sizeof(Matrix) );

        // Trap errors.
        if( (u32) BytesRead != sizeof(Matrix) )
        {
            Debugger();
        }

        // Calculate how many bytes are in the matrix image.
        ByteCount = MatrixHeader.RowCount *
                    MatrixHeader.ColCount * sizeof(f64);
    
        // If this is a matrix with data and not just a
        // placeholder.
        if( ByteCount )
        {
            // Allocate a matrix of the correct size.
            AMatrix = 
                MakeMatrix( &MatrixHeader.FileName[0], 
                            MatrixHeader.RowCount,
                            MatrixHeader.ColCount );
                            
            // Transfer the CRC.
            AMatrix->CheckSum = MatrixHeader.CheckSum;
                    
            // 
            //     L O A D   M A T R I X   I M A G E
            //  
            BytesRead = 
                ReadBytes( AFile,
                           (u8*) AMatrix->a[0],
                           ByteCount );
                    
            // Trap errors.
            if( (u32) BytesRead != ByteCount )
            {
                Debugger();
            }
            
            // Validate the image data.
            if( AMatrix->CheckSum != ComputeMatrixCRC( AMatrix ) )
            {
                Debugger();
            } 

            // Append the matrix to the list.
            InsertDataLastInList( L, (u8*) AMatrix );
        }
        else // Insert a placeholder in the list.
        {
            InsertDataLastInList( L, 0 );
        }
    }
    
    // Return the list.
    return( L );
}

/*------------------------------------------------------------
| LoadMatrixAsBinary
|-------------------------------------------------------------
|
| PURPOSE: To load a data matrix from a binary file.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
|   MyMatrix = SaveMatrixAsBinary( "C:TestFile.DAT" );
|
| NOTE: Imaginary numbers not yet supported.
|
| ASSUMES: 
|           
| HISTORY: 06.07.96 from 'SaveMatrixAsBinary'.
------------------------------------------------------------*/
Matrix*
LoadMatrixAsBinary( s8* AFileName )
{
    FILE*   AFile;
    u32     ByteCount;
    s32     BytesRead;
    Matrix  MatrixHeader;
    Matrix* AMatrix;
    
    // Open binary file.
    AFile = OpenFileTL( AFileName, ReadAccess );

    // 
    //     L O A D   M A T R I X   H E A D E R
    //  
    BytesRead =
        ReadBytes( AFile,
                   (u8*) &MatrixHeader,
                   sizeof(Matrix) );

    // Trap errors.
    if( (u32) BytesRead != sizeof(Matrix) )
    {
        Debugger();
    }

    // Allocate a matrix of the correct size.
    AMatrix = 
        MakeMatrix( &MatrixHeader.FileName[0], 
                    MatrixHeader.RowCount,
                    MatrixHeader.ColCount );
    
    // Transfer the CRC.
    AMatrix->CheckSum = MatrixHeader.CheckSum;
                    
    // Calculate how many bytes are in the matrix image.
    ByteCount = AMatrix->RowCount *
                AMatrix->ColCount * sizeof(f64);
    
    // 
    //     L O A D   M A T R I X   I M A G E
    //  
    BytesRead = 
        ReadBytes( AFile,
                   (u8*) AMatrix->a[0],
                   ByteCount );
                    
    // Trap errors.
    if( (u32) BytesRead != ByteCount )
    {
        Debugger();
    }
        
    CloseFile(AFile);
    
    // Return the matrix.
    return( AMatrix );
}

/*------------------------------------------------------------
| LoadPeriodOfDatedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To load a submatrix of a data matrix spanning a
|          given period.
|
| DESCRIPTION: Given start and end dates and the name of a
| matrix file, returns the matrix within the period,
| including the start and end dates.
|
| Halts if the file not found.  Returns 0 if the time
| span is not in the file.
|
| EXAMPLE:   M = LoadPeriodOfDatedMatrix( 
|                    "Mymatrix", Start, End );
|
| NOTE: Tested using:
|
|   {
|       Matrix* M;
|       s32     Start;
|       s32     End;
|       
|       Start = DateStringToTradeTime( "02/01/96" );
|       End   = DateStringToTradeTime( "02/29/96" );
|       M = LoadPeriodOfContract( "NG96M", Start, End );
|       SaveDatedMatrix( M, "TestNG96MPeriod" );
|    }
|
| ASSUMES:  
|           
| HISTORY: 05.07.96 Tested.
------------------------------------------------------------*/
Matrix*
LoadPeriodOfDatedMatrix( s8* AFileName, u32 Start, u32 End )
{
    Matrix* A;
    Matrix* B;
    u32     s, e;
    u32     AStart, AEnd;
    
    // Read the full matrix.
    A = ReadMatrix( AFileName );
 
    // Find the limits of the matrix.
    RangeOfOrderedMatrix( A, &AStart, &AEnd );

    // Limit the segment to what is in the matrix.
    Start = max( Start, AStart );
    End   = min( End, AEnd );
    
    if( Start > End )
    {
        DeleteMatrix( A );
        return( 0 );
    }
    
    // Find the indexes of the dates within the matrix.
    s = IndexOfKey( A, (s32) Start );
    e = IndexOfKey( A, (s32) End );
    
    // Make a submatrix.
    B = MakeSubMatrix( A, 
                       s,             // UpperRow 
                       0,             // LeftColumn 
                       e - s + 1,     // RowCount 
                       A->ColCount ); // ColCount

    // Discard the full matrix.
    DeleteMatrix( A );
    
    // Return the result.
    return( B );
}

/*------------------------------------------------------------
| ReadMatrix
|-------------------------------------------------------------
|
| PURPOSE: To read a data matrix from an ASCII file.
|
| DESCRIPTION: 
|
| EXAMPLE: AMatrix = ReadMatrix( "D:Data:NG92Z.TSV" );
|
|      returns address of the matrix in memory.
| 
|      and 'CountOfBytesParsed' is altered.
|
| NOTE: 
|
| ASSUMES: File exists and holds data.
|           
| HISTORY: 01.22.95 .
|          01.24.95 tested OK.
|          12.31.95 Added trap for missing file.
|          01.30.00 Revised to use 'AtCell()'.
------------------------------------------------------------*/
Matrix*
ReadMatrix( s8* AFileName )
{
    List*   AList;
    Matrix* AMatrix;
    u32     RowCount;
    u32     ColCount,c;
    f64*    AtDatum;
    s8*     AtTextDatum;
    u32     i;
    
    // Read in a list of ASCII lines.
    AList = ReadListOfTextLines( AFileName );
    
    if( AList == 0 )
    {
        Debugger(); // File is missing.
    }
    
    //
    //      C O U N T   R O W S   A N D   C O L U M N S
    //
    // Count the number of rows and columns so that memory
    // can be allocated to hold the real part in binary format.
    // Ignore lines the have no data.
    // Fail with an error if column count varies.
    
    ReferToList( AList );
    
    RowCount = 0;

    // Find the column count from the first text line.
//TBD   ColCount = CountDataInString( (s8*) TheDataAddress );
        
    while( TheItem )
    {
// TBD      c = CountDataInString( (s8*) TheDataAddress );

        // If there is data in this line but the count varies
        // from the count in the first line, then exit with 
        // error message.
        if( c )
        {
            if( c != ColCount )
            {
                //printf( "Column count error in row %d\n",RowCount);
                Debugger();
            }
            else
            {
                RowCount++;
            }
        }
        
        ToNextItem();
    }
    
    //
    //      M A K E   A   N E W   M A T R I X
    //
    
    AMatrix = 
        MakeMatrix( AFileName, RowCount, ColCount );
        
    // 
    //     C O N V E R T   D A T A   T O   B I N A R Y
    //  
    ToFirstItem();

    // Refer to where the next datum will go.
    AtDatum = AtCell( AMatrix, 
                      AMatrix->LoRowIndex,
                      AMatrix->LoColIndex );
        
    while( TheItem )
    {
        c = CountDataInString( (s8*) TheDataAddress );

        // If there is data in this row then convert it
        // to binary.
        if( c )
        {
            AtTextDatum = (s8*) TheDataAddress;
            
            for( i = 0; i < ColCount; i++ )
            {
                *AtDatum++ = GetFirstDatumInString( AtTextDatum );
                
                AtTextDatum += CountOfBytesParsed;
            }
        }
        
        ToNextItem();
    }
    
    // Discard the list that was created by this 
    // procedure.
    DeleteListOfDynamicData( AList );
    
    RevertToList();

    return( AMatrix );
}


