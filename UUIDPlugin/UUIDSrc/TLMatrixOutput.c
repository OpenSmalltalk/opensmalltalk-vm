/*------------------------------------------------------------
| TLMatrixOutput.c
|-------------------------------------------------------------
|
| PURPOSE: To provide data matrix output functions.
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
#include "TLFileExtra.h"
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
#include "TLVector.h"
#include "TLMatrixMath.h"
#include "TLMatrixExtra.h"
#include "TLMatrixOutput.h"

/*------------------------------------------------------------
| print_matrix
|-------------------------------------------------------------
|
| PURPOSE: To 
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
print_matrix( s8* str, f64** A, s32 RowCount, s32 ColCount )
{
    s32 i, j;

    printf( "%s:  ( %d x %d )\n", str, RowCount, ColCount );
    
    for( i = 1; i <= RowCount; i++  )
    {
        printf( ">" );
        
        for( j = 1; j <= ColCount; j++  )
        {
            printf( " %12.6lf", A[i][j] );
        }
        
        printf( "\n" );
    }
}

/*------------------------------------------------------------
| print_quaternion
|-------------------------------------------------------------
|
| PURPOSE: To 
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
print_quaternion( s8* str, f64*x )
{
    s32     i;

    printf( "%s:\n", str );
    
    for( i = 0; i < QUATERNION_SIZE; i++  )
    {
        printf( " %12.6lf", x[ i ] );
    }
    
    printf( "\n" );
}

/*------------------------------------------------------------
| print_vector
|-------------------------------------------------------------
|
| PURPOSE: To 
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
print_vector( s8* str, f64* x, s32 n )
{
    s32     i;

    printf( "%s:\n", str );
    
    for( i = 1; i <= n; i++  )
    {
        printf( " %12.6lf", x[ i ] );
    }
    
    printf( "\n" );
}

/*------------------------------------------------------------
| SaveMatrix
|-------------------------------------------------------------
|
| PURPOSE: To save a data matrix to an ASCII file.
|
| DESCRIPTION: 
|
| EXAMPLE: SaveMatrix( MyMatrix, "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: All cells are contiguous.
|           
| HISTORY: 01.24.95 .
|          01.24.95 tested OK.
|          02.26.95 set 'UseFixedPointFormat' and 
|                   'UseScientificFormat' to false.
|          07.24.95 changed '\r' to '\n'
|          01.25.96 added support for 'NaN'.
|          05.08.96 added 'fflush'.
|          01.30.00 Revised to call 'AtCell'.
------------------------------------------------------------*/
void
SaveMatrix( Matrix* AMatrix, s8* AFileName )
{
    FILE*   AFile;
    u32     RowCount, r;
    u32     ColCount, c;
    f64*    AtDatum;
    s8*     AtNumberString;
    
    // 
    //     C O N V E R T   D A T A   T O   A S C I I
    //  
    
    // Refer to where the next datum will come from.
    AtDatum = AtCell( AMatrix, 
                      AMatrix->LoRowIndex,
                      AMatrix->LoColIndex );

    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    
    AFile = ReOpenFile(AFileName);

    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        // For each column.
        for( c = 0; c < ColCount; c++ )
        {
            UseFixedPointFormat = 0;
            UseScientificFormat = 0;
            
            // Test for not a number.
            if( ISNAN(*AtDatum) || *AtDatum == NoNum )
            {
                AtNumberString = (s8*) "NaN";
            }
            else
            {
                AtNumberString = 
                    ConvertNumberToString( (Number) *AtDatum );
            }
            
            if( c < ColCount-1 )
            {
                fprintf(AFile,"%s\t",AtNumberString);
            }
            else // last datum in row.
            {
                fprintf(AFile,"%s\n",AtNumberString);
            }
            
            // To next datum.
            AtDatum++;
        }                   
    }
        
    fflush(AFile);
    
    CloseFile(AFile);
#ifdef macintosh    
    // Set the file to a Code Warrior document.
    SetFileType(AFileName, (s8*) "TEXT");
    SetFileCreator(AFileName, (s8*) "CWIE");
#endif  
}

/*------------------------------------------------------------
| SaveDatedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To save a data matrix to an ASCII file converting
|          the first column values from TradeTime to a 
|          calendar date.
|
| DESCRIPTION: 
|
| EXAMPLE: SaveDatedMatrix( MyMatrix, "C:TestFile.DAT" );
|
| NOTE: Imaginary numbers not yet supported.
|
| ASSUMES: 
|           
| HISTORY: 01.24.95 .
|          01.24.95 tested OK.
|          01.15.96 Changed to use 'TradeTimeToDateString'.
------------------------------------------------------------*/
void
SaveDatedMatrix( Matrix* AMatrix,
                 s8* AFileName )
{
    FILE*   AFile;
    u32     RowCount, r;
    u32     ColCount, c;
    f64 *   AtDatum;
    s8*     AtNumberString;
    s8*     Date;
    
    // 
    //     C O N V E R T   D A T A   T O   A S C I I
    //  
    
    // Refer to where the next datum will come from.
    AtDatum = AtCell( AMatrix, 
                      AMatrix->LoRowIndex,
                      AMatrix->LoColIndex );


    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    
    AFile = ReOpenFile(AFileName);

    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        // Output the date from first column.
//TBD       Date = TradeTimeToDateString( (u32) *AtDatum++ );
        
        fprintf(AFile,"%s\t", Date);
        
        // For each column but the first.
        for( c = 1; c < ColCount; c++ )
        {
            AtNumberString = 
                ConvertNumberToString( (Number) *AtDatum++ );

            if( c < ColCount-1 )
            {
                fprintf(AFile,"%s\t",AtNumberString);
            }
            else // last datum in row.
            {
                fprintf(AFile,"%s\r",AtNumberString);
            }
        }                   
    }
        
    CloseFile(AFile);
#ifdef macintosh    
    // Set the file to a Code Warrior document.
    SetFileType(AFileName, (s8*) "TEXT");
    SetFileCreator(AFileName, (s8*) "CWIE");
#endif
}

/*------------------------------------------------------------
| SaveDatedMatrixRounded
|-------------------------------------------------------------
|
| PURPOSE: To save a data matrix to an ASCII file converting 
|          the first column values from TradeTime to a calendar 
|          date, and rounding remaining data to the specified 
|          number of decimal places.
|
| DESCRIPTION: Saves numbers rounded to given number of
|              decimal places.
|
| EXAMPLE: SaveDatedMatrixRounded( 
|               MyMatrix, 
|               "C:TestFile.DAT",
|               3 );
|
| NOTE: 
|
| ASSUMES: 0-9 value for 'PriceDecimalPlaces'.
|           
| HISTORY: 01.04.95 from 'SaveDatedMatrix_TSV3'.
|          01.15.96 Changed to use 'TradeTimeToDateString'.
|          01.24.96 Added number of decimal places parameter.
------------------------------------------------------------*/
void
SaveDatedMatrixRounded( Matrix* AMatrix,
                        s8*     AFileName,
                        s32     DecimalPlaces )
{
    FILE*   AFile;
    u32     RowCount, r;
    u32     ColCount, c;
    f64*    AtDatum;
    f64 ANumber;
    s8*     AtNumberString;
    s8*     Date;
    s8      NumberFormat[20];
    s8      Places[2];
    
    // Make the price formatting string.
    CopyString( (s8*) "%1.", NumberFormat );
    Places[0] = (s8) ( DecimalPlaces + '0' );
    Places[1] = 0;
    AppendStrings( NumberFormat,
                   Places,
                   "f", 0 );
    // 
    //     C O N V E R T   D A T A   T O   A S C I I
    //  
    
    // Refer to where the next datum will come from.
    AtDatum = AtCell( AMatrix, 
                      AMatrix->LoRowIndex,
                      AMatrix->LoColIndex );

    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    
    AFile = ReOpenFile(AFileName);

    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        // Output the date from first column.
//TBD       Date = TradeTimeToDateString( (u32) *AtDatum++ );
        
        fprintf(AFile,"%s\t", Date);
        
        // For each column but the first.
        for( c = 1; c < ColCount; c++ )
        {
            ANumber = *AtDatum;
            
            // If the number is an integer, don't use
            // decimal places.
            if( ANumber == floor( ANumber ) )
            {
                AtNumberString = 
                    ConvertNumberToString( (Number) ANumber );

                fprintf(AFile,"%s",AtNumberString);
            }
            else // Round to specified decimal places.
            {
                fprintf(AFile,(char*) NumberFormat,ANumber);
            }
            
            // Use tabs between columns.
            if( c < ColCount-1 )
            {
                fprintf(AFile,"\t",AtNumberString);
            }
            else // Mark end of line with carriage return.
            {
                fprintf(AFile,"\r",AtNumberString);
            }
            
            AtDatum++;
        }                   
    }
        
    CloseFile(AFile);
#ifdef macintosh    
    // Set the file to a Code Warrior document.
    SetFileType(AFileName, (s8*) "TEXT");
    SetFileCreator(AFileName, (s8*) "CWIE");
#endif
}

/*------------------------------------------------------------
| SaveDatedMatrixRoundedDAY
|-------------------------------------------------------------
|
| PURPOSE: To save a data matrix to an ASCII file rounding the 
|          price data to the specified number of decimal places.
|
| DESCRIPTION: Saves prices rounded to given number of
|              decimal places.
|
| EXAMPLE: SaveDatedMatrixRoundedDAY( 
|               MyMatrix, 
|               "C:TestFile.DAT",
|               3 );
|
| NOTE: 
|
| ASSUMES: 0-9 value for 'PriceDecimalPlaces'.
|           
| HISTORY: 12.25.96 from 'SaveDatedMatrixRoundedTSV'.
------------------------------------------------------------*/
void
SaveDatedMatrixRoundedDAY( Matrix* AMatrix,
                           s8*     AFileName,
                           s32     DecimalPlaces )
{
    FILE*   AFile;
    u32     RowCount, r;
    u32     ColCount, c;
    f64 *   AtDatum;
    f64 ANumber;
    s8*     AtNumberString;
    s32     Date;
    s8      NumberFormat[20];
    s8      Places[2];
    
    // Make the price formatting string.
    CopyString( (s8*) "%1.", NumberFormat );
    Places[0] = (s8) ( DecimalPlaces + '0' );
    Places[1] = 0;
    AppendStrings( NumberFormat,
                   Places,
                   "f", 0 );
    // 
    //     C O N V E R T   D A T A   T O   A S C I I
    //  
    
    // Refer to where the next datum will come from.
    AtDatum = AtCell( AMatrix, 
                      AMatrix->LoRowIndex,
                      AMatrix->LoColIndex );

    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    
    AFile = ReOpenFile(AFileName);

    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        // Output the date from first column.
        Date = (s32) *AtDatum++;
        
        fprintf( AFile,"%8d\t", Date );
        
        // For each column but the first.
        for( c = 1; c < ColCount; c++ )
        {
            ANumber = *AtDatum++;
            
            // If the number isn't a price don't use
            // decimal places.
            if( c >= DAY_Volume )
            {
                AtNumberString = 
                    ConvertNumberToString( (Number) ANumber );

                fprintf(AFile,"%s",AtNumberString);
            }
            else // Round price to specified decimal places.
            {
                fprintf(AFile,(char*) NumberFormat,ANumber);
            }
            
            // Use tabs between columns.
            if( c < ColCount-1 )
            {
                fprintf(AFile,"\t",AtNumberString);
            }
            else // Mark end of line with carriage return.
            {
                fprintf(AFile,"\r",AtNumberString);
            }
        }                   
    }
        
    CloseFile(AFile);
#ifdef macintosh    
    // Set the file to a Code Warrior document.
    SetFileType(AFileName, (s8*) "TEXT");
    SetFileCreator(AFileName, (s8*) "CWIE");
#endif
}

/*------------------------------------------------------------
| SaveDatedMatrixRoundedTSV
|-------------------------------------------------------------
|
| PURPOSE: To save a data matrix to an ASCII file converting 
|          the first column values from TradeTime to a calendar 
|          date, and rounding the price data to the specified 
|          number of decimal places.
|
| DESCRIPTION: Saves numbers rounded to given number of
|              decimal places.
|
| EXAMPLE: SaveDatedMatrixRoundedTSV( 
|               MyMatrix, 
|               "C:TestFile.DAT",
|               3 );
|
| NOTE: 
|
| ASSUMES: 0-9 value for 'PriceDecimalPlaces'.
|           
| HISTORY: 01.04.95 from 'SaveDatedMatrix_TSV3'.
|          01.15.96 Changed to use 'TradeTimeToDateString'.
|          01.24.96 Added number of decimal places parameter.
------------------------------------------------------------*/
void
SaveDatedMatrixRoundedTSV( Matrix* AMatrix,
                           s8*     AFileName,
                           s32     DecimalPlaces )
{
    FILE*   AFile;
    u32     RowCount,r;
    u32     ColCount,c;
    f64*    AtDatum;
    f64     ANumber;
    s8*     AtNumberString;
    s8*     Date;
    s8      NumberFormat[20];
    s8      Places[2];
    
    // Make the price formatting string.
    CopyString( (s8*) "%1.", NumberFormat );
    Places[0] = (s8) ( DecimalPlaces + '0' );
    Places[1] = 0;
    AppendStrings( NumberFormat,
                   Places,
                   "f", 0 );
    // 
    //     C O N V E R T   D A T A   T O   A S C I I
    //  
    
    // Refer to where the next datum will come from.
    AtDatum = AtCell( AMatrix, 
                      AMatrix->LoRowIndex,
                      AMatrix->LoColIndex );

    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    
    AFile = ReOpenFile(AFileName);

    // For each row.
    for( r = 0; r < RowCount; r++ )
    {
        // Output the date from first column.
//TBD       Date = TradeTimeToDateString( (u32) *AtDatum++ );
        
        fprintf(AFile,"%s\t", Date);
        
        // For each column but the first.
        for( c = 1; c < ColCount; c++ )
        {
            ANumber = *AtDatum;
            
            // If the number isn't a price don't use
            // decimal places.
            if( c >= TSV_Volume )
            {
                AtNumberString = 
                    ConvertNumberToString( (Number) ANumber );

                fprintf(AFile,"%s",AtNumberString);
            }
            else // Round to specified decimal places.
            {
                fprintf(AFile, (char*) NumberFormat,ANumber);
            }
            
            // Use tabs between columns.
            if( c < ColCount-1 )
            {
                fprintf(AFile,"\t",AtNumberString);
            }
            else // Mark end of line with carriage return.
            {
                fprintf(AFile,"\r",AtNumberString);
            }
            
            AtDatum++;
        }                   
    }
        
    CloseFile(AFile);
#ifdef macintosh    
    // Set the file to a Code Warrior document.
    SetFileType(AFileName, (s8*) "TEXT");
    SetFileCreator(AFileName, (s8*) "CWIE");
#endif
}

/*------------------------------------------------------------
| SaveListOfMatricesAsBinary
|-------------------------------------------------------------
|
| PURPOSE: To save a list of matrices to the current location
|          of a file.  Saves in binary form.
|
| DESCRIPTION: Saves a 32-bit matrix count followed by the
| matrix data.  If an item of the list holds 0 for a matrix
| address then a matrix header showing zero rows and columns 
| is output as a placeholder: on reading the process is reversed.
|
| EXAMPLE: SaveListOfMatricesAsBinary( MatrixList, F );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.14.96 
------------------------------------------------------------*/
void
SaveListOfMatricesAsBinary( List* MatrixList, FILE* AFile )
{
    u32     ByteCount;
    u32     BytesWritten;
    Matrix* AMatrix;
    u32     MatrixCount;
    Matrix  MatrixHeader;
    
    // Clear the dummy matrix header.
    MatrixHeader.RowCount = 0;
    MatrixHeader.ColCount = 0;
    
    // Save the count of matrices as a 32-bit number.
    MatrixCount = MatrixList->ItemCount;
    
    BytesWritten = 
            WriteBytes( AFile,
                        (u8*) &MatrixCount,
                        sizeof(s32) );
                    
    // Trap errors.
    if( BytesWritten != sizeof(s32) )
    {
        Debugger();
    }
    
    ReferToList( MatrixList );
    
    // For each matrix in the list.
    while( TheItem )
    {
        if( TheDataAddress )
        {
            // Refer to the matrix.
            AMatrix = (Matrix*) TheDataAddress;
            
            // Compute the 32-bit CRC. 
            AMatrix->CheckSum =
                ComputeMatrixCRC( AMatrix );
        }
        else // Missing matrix: use placeholder.
        {
            AMatrix = &MatrixHeader;
        }
        
        // 
        //     S A V E   M A T R I X   H E A D E R
        //  
        BytesWritten = 
            WriteBytes( AFile,
                        (u8*) AMatrix,
                        sizeof(Matrix) );
                    
        // Trap errors.
        if( BytesWritten != sizeof(Matrix) )
        {
                Debugger();
        }

        // Calculate how many bytes are in the matrix image.
        ByteCount = AMatrix->RowCount *
                    AMatrix->ColCount * sizeof(f64);
    
        // If there are cells in the matrix.
        if( ByteCount )
        {
            // 
            //     S A V E   M A T R I X   I M A G E
            //  
            BytesWritten = 
                WriteBytes( AFile,
                            (u8*) AMatrix->a[0],
                            ByteCount );
                    
            // Trap errors.
            if( BytesWritten != ByteCount )
            {
                Debugger();
            }
        }
            
        ToNextItem();
    }
    
    RevertToList();
}

/*------------------------------------------------------------
| SaveMatrixAsBinary
|-------------------------------------------------------------
|
| PURPOSE: To save a data matrix to a binary file.
|
| DESCRIPTION: 
|
| EXAMPLE: SaveMatrixAsBinary( MyMatrix, "C:TestFile.DAT" );
|
| NOTE: See counterpart routine 'LoadMatrixAsBinary'.
|
| ASSUMES: 
|           
| HISTORY: 06.07.96 from 'SaveMatrix'.
|          01.30.00 Revised for new matrix format.
------------------------------------------------------------*/
void
SaveMatrixAsBinary( Matrix* AMatrix,
                    s8*     AFileName )
{
    FILE*   AFile;
    u32     ByteCount;
    u32     BytesWritten;
    
    // Create/recreate binary file.
    AFile = ReOpenFile(AFileName);

    // Trap errors.
    if( AFile == 0 )
    {
        Debugger();
    }

    // 
    //     S A V E   M A T R I X
    //  
    
    // Calculate the number of bytes in the entire
    // record.
    ByteCount = sizeof( Matrix ) +
                AMatrix->RowSectionSize +
                AMatrix->DataSectionSize;
                
    BytesWritten = 
        WriteBytes( AFile,
                    (u8*) AMatrix,
                    ByteCount );
                    
    // Trap errors.
    if( BytesWritten != ByteCount )
    {
        Debugger();
    }

    fflush(AFile);
    
    CloseFile(AFile);
#ifdef macintosh    
    // Set the file type and creator. 
    SetFileType(AFileName, (s8*) "MTRX");
    SetFileCreator(AFileName, (s8*) "$$$$");
#endif
}

/*------------------------------------------------------------
| WriteMatrixInMathematicaFormat
|-------------------------------------------------------------
|
| PURPOSE: To write the values of a matrix in ASCII 
|          Mathematica form to a file.
|
| DESCRIPTION:  
|
| EXAMPLE: WriteMatrixInMathematicaFormat( F, "MatB", MatB );
|
| Outputs like this:
|
| MatB =
| { 
| { 3, 4, 5 },
| { 6, 8, 9 }
| };
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 07.20.97
|          07.31.97 added row brackets.
|          08.03.97 added 20 digit per number limit.
|          02.04.00 Revised to support general indexing.
------------------------------------------------------------*/
void
WriteMatrixInMathematicaFormat( FILE* F, s8* Name, Matrix* A )
{
    s8      S[200];
    f64**   a;
    u32     r, c;
    u32     LoRow, LoCol;
    u32     HiRow, HiCol;
    
    // Refer to the matrix data via standard C syntax.
    a = (f64**) A->a;
    
    // Refer to the low index numbers for each dimension.
    LoRow = A->LoRowIndex;
    LoCol = A->LoColIndex;

    // Calculate the high index numbers for each dimension.
    HiRow = LoRow + A->RowCount - 1;
    HiCol = LoCol + A->ColCount - 1;

    // Output the matrix name and opening brace.
    fprintf( F, "%s =\n", Name );
    fprintf( F, "{\n" );

    // For each row in the matrix.
    for( r = LoRow; r <= HiRow; r++ )
    {
        fprintf( F, "  { " );
    
        // For each column of the matrix.
        for( c = LoCol; c <= HiCol; c++ )
        {
            // Convert the number to a string.
            // TBD - add full precision here to avoid
            // information loss.
            sprintf( S, "%12.6lf", a[r][c] );
            
            // Limit result to 20 digits.
            S[20] = 0;
            
            // If this is the last column.
            if( c == HiCol )
            {
                // If this is the last row.
                if( r == HiRow )
                {
                    fprintf( F, "%s }\n", S );
                }
                else // Not the last row.
                {
                    fprintf( F, "%s },\n", S );
                }
            }
            else // Not the last column.
            {
                // Output a tab separator.
                fprintf( F, "%s,\t", S );
            }
        }
    }
    
    fprintf( F, "};\n\n" );
}

