/*------------------------------------------------------------
| TLStringList.c
|-------------------------------------------------------------
|
| PURPOSE: To provide functions for 8-bit character string 
|          lists.
|
| DESCRIPTION: String list functions operate on lists of
| zero-terminated strings and/or lists of counted character
| sequences.
|
| The strings may be either statically or dynamically 
| allocated.
|
| ASSUMES: Strings are 8-bit characters.
|
| HISTORY: 08.11.01
------------------------------------------------------------*/


#include "TLTarget.h"   // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"  
#include "TLBytes.h"
#include "TLAscii.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"
#include "TLList.h"
#include "TLListIO.h"
#include "TLStacks.h"
#include "TLParse.h"    
#include "TLMatrixAlloc.h"
#include "TLMatrixCopy.h"
#include "TLMatrixMath.h"

#include "TLStringList.h"

/*------------------------------------------------------------
| CopyStringListToMatrix
|-------------------------------------------------------------
|
| PURPOSE: To copy a string list into a matrix.
|
| DESCRIPTION: Copies strings into a matrix with given upper
| left location where the strings should begin.
|
| EXAMPLE: 
|
|          CopyStringListToMatrix( AMatrix, 0, 0, L );
|
| ASSUMES: Enough room in the matrix for the strings.
|           
| HISTORY: 02.03.95
|          08.11.01 Generalized for other 8-bit cell sizes.
------------------------------------------------------------*/
void
CopyStringListToMatrix( 
    Matrix* AMatrix,
                // The destination matrix.
                //
    s32     UpperRow,
                // Row offset for the first string copied into
                // the matrix, a zero-based index.
                //
    s32     LeftColumn, 
                // Column offset to be applied to each 
                // string copied into the matrix, a 
                // zero-based index.
                //
    List*   L ) // The list of strings to be copied.
{
    u8** M;
    u32  Row;
    u32  RowCount;
    u32  MaxDataSize;
    u32  BytesToCopy;
    
    // Get the row count of the matrix.
    RowCount = AMatrix->RowCount;
    
    // Calculate the maximum number of characters 
    // that can be validly copied into the matrix
    // assuming the right most column can't be written
    // into because it contains the zero-terminator 
    // byte.
    MaxDataSize = ( AMatrix->ColCount - LeftColumn ) - 1;
    
    // Refer to the matrix as an array of bytes.
    M = (u8**) AMatrix->a;
    
    // Start with the first row.
    Row = UpperRow;

    // Refer to the list as the current list.
    ReferToList( L );
    
    // For each item in the list or until the end
    // of the matrix has been reached.
    while( TheItem && Row < RowCount )
    {
        // If the string count is not yet known.
        if( ( TheDataType & COUNTED_STRING ) == 0 )
        {
            // Then get the string count.
            SizeOfString( TheItem );
        }
 
        // If there are characters in the string.
        if( TheDataSize )
        {
            // Default to copying all of the string.
            BytesToCopy = TheDataSize;
            
            // If the number characters to be copied
            // would exceed the space available.
            if( TheDataSize > MaxDataSize )
            {
                // Then just copy the maximum possible.
                BytesToCopy = MaxDataSize;
            }

            // Copy the bytes of the string into 
            // the current row of the matrix.
            CopyBytes( 
                TheDataAddress, 
                M[Row] + LeftColumn, 
                BytesToCopy );
        }
        
        // Advance to the next item in the list.
        ToNextItem();
        
        // Advance to the next row of the matrix.
        Row++;
    }

    // Revert to the prior list context.
    RevertToList();
}

/*------------------------------------------------------------
| DetabStringList
|-------------------------------------------------------------
|
| PURPOSE: To detab a list of text lines.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| ASSUMES: Text lines in list are dynamically allocated
|          C strings, one per list item.
|
|          OK to dynamically reallocate a new line buffer for 
|          a line.
|
|          No line of text exceeds 20K bytes after detabbing.
|
| HISTORY: 05.02.01 From WriteListOfTextLines.
|          08.11.01 Moved from TLFileExtra.c and changed name.
------------------------------------------------------------*/
void
DetabStringList(
    List*   AList,
                // List of text lines, one line string per 
                // item as a C string with no end-of-line 
                // characters.
                //
    u32     TabStopInterval )
                // Number of characters between tab stops
                // assuming that tab stops are placed at
                // uniform intervals across the line.
{
    s8* AtInput;
    s8* AtOutput;
    u32 InputSize;
    u32 OutputSize;
    
    // Allocate a 20K working buffer.
    AtOutput = (s8*) malloc( 20 * 1024 );
    
    ReferToList( AList ); 
    
    // For each line of text.
    while( TheItem )
    {
        // Refer to the current line.
        AtInput = (s8*) TheDataAddress;
        
        // Measure the size of the current line.
        InputSize = CountString( (s8*) TheDataAddress );
        
        // If the input string contains any tabs.
        if( IsByteInString( AtInput, (u16) Tab ) )
        {
            // Detab the input line to the output buffer 
            // and measure the size of the output line.
            OutputSize = 
                DeTabLine( 
                    AtInput,            
                        // IN: Input buffer holding a 
                        // single line of text.
                        //
                    AtOutput,
                        // OUT: Output buffer that will 
                        //      hold the result line with 
                        //      tabs replaced by spaces.
                    InputSize,
                        // IN: Number of bytes in the input 
                        //     line.
                        // 
                    TabStopInterval );
                        // IN: Number of characters between 
                        //     tab stops assuming that tab 
                        //     stops are placed at uniform 
                        //     intervals across the line.
            
            // Append a string terminator.
            AtOutput[OutputSize] = 0;
            
            // Free the string currently attached to the
            // item.
            free( AtInput );
            
            // Duplicate the output string and link it to
            // the list item.
            TheDataAddress = 
                (u8*) DuplicateString( AtOutput );
                
            // Update the buffer address field of the item
            // too to avoid an error later when the list
            // is deleted.
            TheBufferAddress = TheDataAddress;
        }
                
        ToNextItem();
    }
        
    RevertToList();
    
    // Delete the working buffer.
    free( AtOutput );
}

/*------------------------------------------------------------
| ExtentOfStringList
|-------------------------------------------------------------
|
| PURPOSE: To measure the number of characters in the longest 
|          and shortest strings in a list.
|
| DESCRIPTION: This function is used to get the basic limits
| of how big strings are in a list.
|
| EXAMPLE:  
|
|        ExtentOfStringList( AList, &MinSize, &MaxSize );
|
| ASSUMES: The string list contains at least one string.
|
| HISTORY: 08.11.01 Factored out of ReadTextFileIntoMatrix().
------------------------------------------------------------*/
void
ExtentOfStringList(
    List* L,
            // The list of strings.
            //
    u32*  MinStringSize,
            // OUT: The number of characters in the shortest 
            // string not counting the terminal zero.
            //
    u32*  MaxStringSize )
            // OUT: The number of characters in the longest 
            // string not counting the terminal zero.
{
    u32 MinString, MaxString;
    
    // Measure the number of characters in each string 
    // in a list.
    //
    // OUT: Sets the SizeOfData field for each item in the
    //      list to the number of characters in each string.
    MeasureStringList( L );
    
    // Refer to the list as the current list.
    ReferToList( L );
    
    // Initialize the length of the shortest-string-found
    // to the first string length.
    MinString = TheDataSize;
    
    // Initialize the longest-string-found to zero.
    MaxString = 0;
    
    // For each item in the list.
    while( TheItem )
    {
        // If the length of the current string is shorter 
        // than the shortest found so far.
        if( TheDataSize < MinString )
        {
            // Then update the shortest.
            MinString = TheDataSize;
        }

        // If the length of the current string is longer 
        // than the longest found so far.
        if( TheDataSize > MaxString )
        {
            // Then update the longest.
            MaxString = TheDataSize;
        }
            
        // Advance to the next item in the list.
        ToNextItem();
    }
    
    // Revert to the prior list context.
    RevertToList();
 
    // Return the size of the shortest string.
    *MinStringSize = MinString;
    
    // Return the size of the longest string.
    *MaxStringSize = MaxString;
}

/*------------------------------------------------------------
| MatrixToStringList
|-------------------------------------------------------------
|
| PURPOSE: To make a list of strings from a text matrix.
|
| DESCRIPTION: Each matrix row holds one string.
|
| EXAMPLE:  M = MatrixToStringList( L );
|
| ASSUMES: The right most column of the matrix holds a zero
|          terminator byte.
|
| HISTORY: 08.12.01 From StringListToMatrix().
------------------------------------------------------------*/
List*      // OUT: The resulting string list or zero on error.
MatrixToStringList( Matrix* M )
                            // A text matrix.
{
    s8**    s;
    List*   L;
    u32     i;
    u32     RowCount;
    s8*     n;
    
    // Allocate a new list to hold the strings.
    L = MakeList();
    
    // Get the row count of the matrix.
    RowCount = M->RowCount;
        
    // Refer to the matrix as an array of bytes.
    s = (s8**) M->a;

    // For every row in the matrix.
    for( i = 0; i < RowCount; i++ )
    {
        // Duplicate the current row string.
        n = DuplicateString( s[i] );
        
        // Append the string to the list.
        InsertDataLastInList( L, (u8*) n );
    }     
    
    // Return the list.
    return( L );
}

/*------------------------------------------------------------
| MeasureStringList
|-------------------------------------------------------------
|
| PURPOSE: To measure the number of characters in each string 
|          in a list.
|
| DESCRIPTION: This function measures the number of characters
| in each string, not counting the zero-terminator, and then
| stores that count into the SizeOfData field of the Item 
| record that refers to the string.
|
| This function also marks the type of each string to indicate
| that it has a zero terminator byte as well as a character
| count... this is done by setting bits in the TypeOfData
| field of the Item record that refers to each string.
|
| EXAMPLE:  
|              MeasureStringList( AList );
|
| ASSUMES: Every string has a zero terminator.
|
|          OK to change the SizeOfData field in string Item
|          records.
|
| HISTORY: 08.11.01 Factored out of ReadTextFileIntoMatrix().
|          08.19.01 Factored out SizeOfString().
------------------------------------------------------------*/
void
MeasureStringList( List* L )
                         // A list of zero-terminated strings.
{
    // Refer to the list as the current list.
    ReferToList( L );
    
    // For each item in the list.
    while( TheItem )
    {
        // Count the characters in the current string and
        // put the count in the SizeOfData field and mark
        // the strings as counted and zero-terminated.
        SizeOfString( TheItem );
             
        // Advance to the next item in the list.
        ToNextItem();
    }
    
    // Revert to the prior list context.
    RevertToList();
}

/*------------------------------------------------------------
| ReadTextFileIntoMatrix
|-------------------------------------------------------------
|
| PURPOSE: To read a text file into a matrix.
|
| DESCRIPTION: Each cell in the matrix is one byte.
|
| The extent of the matrix is the same as the text file
| except that an extra right-most column is added to hold a
| zero terminator byte so that rows can be treated as strings.
|
| The end-of-line characters in the text file are not copied
| into the matrix.
|
| Tab characters read from the file are translated into spaces
| according to the 'TabStopInterval' parameter.
|
| Lines that are shorter than the matrix width are padded
| on the right with spaces.
|
| EXAMPLE: 
|
|     AMatrix = ReadTextFileIntoMatrix( "Myfile.txt", 4 );
|
| ASSUMES: File exists and holds text data.
|           
| HISTORY: 08.05.01 From ReadMatrix().
|          08.11.01 Factored out string list functions.
------------------------------------------------------------*/
            // OUT: Matrix holding the data of the file or 0
Matrix*     //      if the file can't be opened.
ReadTextFileIntoMatrix( 
    s8* FilePath,
            // Path of the file to be read.
            //
    u32 TabStopInterval )
            // Number of characters between tab stops
            // assuming that tab stops are placed at
            // uniform intervals across the line.
{
    List*   L;
    Matrix* AMatrix;
    
    // Read the text file as a list of text lines.
    L = ReadListOfTextLines( FilePath );

    // If the file couldn't be opened.
    if( L == 0 )
    {
        // Return 0 to signal failure.
        return( 0 );
    }

    // Detab the text by replacing tabs with spaces.
    DetabStringList(
        L,  // List of text lines, one line string per 
            // item as a C string with no end-of-line 
            // characters.
            //
        TabStopInterval );
            // Number of characters between tab stops
            // assuming that tab stops are placed at
            // uniform intervals across the line.
   
    // Make a text matrix from the string list.         
    AMatrix = StringListToMatrix( L );
        
    // Discard the list that was created by this procedure.
    DeleteListOfDynamicData( L );
 
    // Return the matrix.
    return( AMatrix );
}

/*------------------------------------------------------------
| ReplaceStringInStringList
|-------------------------------------------------------------
|
| PURPOSE: To replace every occurance of a string in a list
|          with another string.
|
| DESCRIPTION: Comparison is case sensitive and strings 
| matched may not span line boundaries.
|
| EXAMPLE:  
|         
|      ReplaceStringInStringList( L, "int", "s32" );
|
| ASSUMES: Every string has a zero terminator.
|
|          Strings are dynamically allocated and may be
|          individually reallocated to make room.
|
| HISTORY: 08.12.01  
------------------------------------------------------------*/
void
ReplaceStringInStringList( 
    List* L,
          // A list of zero-terminated strings.
          //
    s8*   SearchString,
          // The literal search string to look for.
          //
    s8*   ReplacementString )
          // The new string to be used in place of the 
          // one specified by SearchString.
{
    u32 SearchSize;
    u32 ReplaceSize;
    u32 AddByteCount;
    u8* AtSegment;
    u8* AtPattern;
    u32 PatternOffset;
    
    // Measure the number of characters of the search string
    // not counting the terminal zero.
    SearchSize = CountString( SearchString );
    
    // Measure the size of the replacement string.
    ReplaceSize = CountString( ReplacementString );
    
    // If the replacement is longer than the substring it
    // replaces.
    if( ReplaceSize > SearchSize )
    {
        // Calculate the net number of bytes that will need 
        // to be added to a string in which a replacement 
        // occurs.
        AddByteCount = ReplaceSize - SearchSize;
    }
    else // The replacement is not more than the search 
         // substring.
    {
        // So no additional bytes are needed.
        AddByteCount = 0;
    }
     
    // Refer to the list as the current list.
    ReferToList( L );
    
    // For each item in the list.
    while( TheItem )
    {
        // Count the characters in the current string.
        SizeOfString( TheItem );

        // Refer to the whole string as the current segment.
        AtSegment = TheDataAddress;
                
        // If the current string is long enough to hold
        // the search pattern.
        if( TheDataSize >= SearchSize )
        {
        
///////////
TryAgain://
///////////
            // Look for the search pattern in the current
            // string.
            AtPattern =
                FindBytesInBytes( 
                    (u8*) SearchString, 
                    SearchSize,  
                    TheDataAddress,  
                    TheDataSize );

            // If the pattern is found.
            if( AtPattern )
            {
                // Calculate the offset of the pattern in
                // the string.
                PatternOffset = AtPattern - TheDataAddress;
                
                // If the string needs to be extended.
                if( AddByteCount )
                {
                    // Update the data size.
                    TheDataSize += AddByteCount;
                    
                    // Reallocate the string buffer.
                    TheDataAddress = (u8*)
                        realloc( TheDataAddress, 
                                 TheDataSize + 1 );
                }
                
                // Replace the pattern with the replacement.
                ReplaceRangeInBuffer( 
                    TheDataAddress,
                        // The buffer containing range A.
                        //
                    TheDataSize + 1,
                        // The size of the buffer in bytes.
                        //
                    TheDataAddress + PatternOffset, 
                        // A sequence of bytes in ABuffer to be
                        // replaced with the bytes from BRange.
                        //
                    SearchSize,
                        // Size of ARange in bytes.
                        //
                    (u8*) ReplacementString,
                        // The location of the replacement bytes.
                        //
                    ReplaceSize );
                        // The size of the replacement section 
                        // in bytes.
                        
                // Refer to the byte after the replacement as
                // the current search segment.
                AtSegment = 
                    TheDataAddress + PatternOffset + ReplaceSize;
                    
                // Try to replace more substrings in the current
                // string.
                goto TryAgain;
            }
        }
        
        // Advance to the next item in the list.
        ToNextItem();
    }
    
    // Revert to the prior list context.
    RevertToList();
}

/*------------------------------------------------------------
| SizeOfString
|-------------------------------------------------------------
|
| PURPOSE: To count the number of characters in a string.
|
| DESCRIPTION: Returns the number of characters, not counting
| any zero terminator.
|
| ASSUMES: The given Item record refers to a string via its
|          DataAddress field.
|
|          Conventions for identifying strings specified in
|          TLStringList.h are followed.
|
| HISTORY: 08.19.01 From ToPriorRecord().
------------------------------------------------------------*/
    // OUT: Number of characters or zero if the string is
u32 //      empty or missing.
SizeOfString( Item* S )
                    // Item record that refers to a string.
{
    // If the Item record doesn't refer to any string.
    if( S->DataAddress == 0 )
    {
        // Clear the type of data field to avoid implying
        // that a string exists of a certain type.
        S->TypeOfData = 0;
        
        // Return 0 to indicate that the string is empty.
        return( 0 );
    }
        
    // If the string is not yet counted.
    if( ( S->TypeOfData & COUNTED_STRING ) == 0 )
    {
        // Count the characters in the string.
        S->SizeOfData = 
            CountString( (s8*) S->DataAddress );
            
        // Identify the data as being a zero-terminated
        // string.
        S->TypeOfData |= ZERO_ENDED_STRING;
        
        // Identify the data as also being a counted 
        // character sequence.
        S->TypeOfData |= COUNTED_STRING;
    }
    
    // Return the number of characters.
    return( S->SizeOfData );
}

/*------------------------------------------------------------
| SizeOfStringList
|-------------------------------------------------------------
|
| PURPOSE: To count the number of characters in a string list.
|
| DESCRIPTION: Returns the number of characters in the string
| list not counting any string terminator bytes.
|
| NOTE: The number of strings is the same as the ItemCount in
|       the List record.
|
| ASSUMES: The given Item record refers to a string via its
|          DataAddress field.
|
|          Conventions for identifying strings specified in
|          TLStringList.h are followed.
|
| HISTORY: 08.19.01 From ToPriorRecord().
------------------------------------------------------------*/
    // OUT: Number of characters or zero if the string list is
u32 //      empty or missing.
SizeOfStringList( List* L )
                        // A list of strings.
{
    u32 CharCount;
    
    // If the List record doesn't refer to any list.
    if( L == 0 )
    {
        // Return 0 to indicate no characters.
        return( 0 );
    }
    
    // Start with no characters counted.
    CharCount = 0;
    
    // Preserve the list context and set L as the current
    // list.
    ReferToList( L );
    
    // For each string in the list.
    while( TheItem )
    {
        // Count the number of characters in the string.
        CharCount += SizeOfString( TheItem );
        
        // Advance to the next string.
        ToNextItem();
    }
    
    // Restore the previous list context.
    RevertToList();
        
    // Return the number of characters.
    return( CharCount );
}

/*------------------------------------------------------------
| StringListToMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a matrix from a list of strings.
|
| DESCRIPTION: Each matrix row is used to hold one of the 
| strings.
|
| The width of the matrix is the same as the number of 
| characters in longest string except that an extra right-most 
| column is added to hold a zero terminator byte so that rows 
| can be treated as strings.
|
| Lines that are shorter than the matrix width are padded
| on the right with spaces.
|
| EXAMPLE:  M = StringListToMatrix( L );
|
| HISTORY: 08.11.01 From PointListToMatrix() and 
|                   ReadTextFileIntoMatrix().
------------------------------------------------------------*/
Matrix* // OUT: The resulting matrix or zero on error.
StringListToMatrix( List* L )
                         // A list of zero-terminated strings.
{
    Matrix* AMatrix;
    u32     MinStringSize, MaxStringSize;

    // Calculate the length of the shortest and longest
    // strings in the list.
    ExtentOfStringList(
        L,  // The list of strings.
            //
        &MinStringSize,
            // OUT: The number of characters in the shortest 
            // string not counting the terminal zero.
            //
        &MaxStringSize );
            // OUT: The number of characters in the longest 
            // string not counting the terminal zero.
      
    // Make a new text matrix.
    AMatrix = 
        MakeTextMatrix( 
            "", // Don't name the matrix.
                //
            L->ItemCount, 
                // The row count of the matrix is the number
                // of strings in the list.
                //
            MaxStringSize + 1 );
                // Increase the column count by one to hold 
                // the string terminator.
    
    // Fill the matrix with spaces.
    FillMatrix( 
        AMatrix,
            // The matrix to be filled.
            //
        0,  // Index of the top row to be filled.
            //
        0,  // Index of the left column to be filled.
            //
        AMatrix->RowCount,
            // Number of rows to be filled.
            //
        AMatrix->ColCount,
            // Number of columns to be filled.
            //
        (f64) ' ' );
            // The fill value passed as a floating point 
            // value.
            
    // Fill the right column of the matrix with zeros.
    FillMatrix( 
        AMatrix,
            // The matrix to be filled.
            //
        0,  // Index of the top row to be filled.
            //
        AMatrix->ColCount-1,  
            // Index of the left column to be filled.
            //
        AMatrix->RowCount,
            // Number of rows to be filled.
            //
        1,  // Number of columns to be filled.
            //
        (f64) 0 );
            // The fill value passed as a floating point 
            // value.

    // Copy the string list into the matrix.
    CopyStringListToMatrix( 
        AMatrix,
            // The destination matrix.
            //
        0,  // Row offset for the first string copied into
            // the matrix, a zero-based index.
            //
        0,  // Column offset to be applied to each 
            // string copied into the matrix, a 
            // zero-based index.
            //
        L );// The list of strings to be copied.

    // Return the matrix.
    return( AMatrix );
}

/*------------------------------------------------------------
| StripLeadingWhiteSpaceInStringList
|-------------------------------------------------------------
|
| PURPOSE: To strip "white space" characters (defined below) 
|          from the start of each string in a list.
|
| DESCRIPTION: White space characters are any of the 
| following:
|
|           spaces, tabs, carriage returns, line feeds
|
| EXAMPLE:  
|          StripLeadingWhiteSpaceInStringList( AList );
|
| HISTORY: 08.12.01 
|          08.19.01 Added SizeOfString().
|          08.25.01 Revised to support counted strings.
------------------------------------------------------------*/
void
StripLeadingWhiteSpaceInStringList( List* L )
                                          // A list of 
                                          // strings.
{
    ThatChar C;
    s8*      Here;
    u32      CharCount;
    u32      WhiteCount;
    
    // Refer to the first string in the list.
    ToFirstString( L, &C );
    
    // For each string in the list.
    while( C.TheStringItem )
    {
        // If the current string contains characters.
        if( C.TheCharAddress )
        {
            // Refer to the first character of the string.
            Here = C.TheCharAddress;
            
            // Scan to the first non-white character in
            // the string.
            SkipWhiteSpace( &Here );
            
            // Calculate the number of whitespace chars
            // found.
            WhiteCount = Here - C.TheCharAddress;
            
            // If white chars have been found.
            if( WhiteCount )
            {
                // Get the string count.
                CharCount = 
                    SizeOfString( C.TheStringItem );
                    
                // If the white character count is less
                // than the string count.
                if( WhiteCount < CharCount )
                {
                    // Copy the non-white characters to
                    // beginning of the string.
                    CopyBytes( 
                        (u8*) Here,            
                                // Source address.
                                //
                        (u8*) C.TheCharAddress,     
                                // Destination address.
                                //
                        CharCount - WhiteCount ); 
                                // Byte count.  
                
                    // Adjust the byte count.
                    C.TheStringItem->SizeOfData = 
                        CharCount - WhiteCount;
                }   
                else // The entire string is white.
                {
                    // Adjust the byte count.
                    C.TheStringItem->SizeOfData = 0;
                }
                
                // If the string has a zero-terminator.
                if( C.TheStringItem->TypeOfData &
                    ZERO_ENDED_STRING )
                {
                    // Refer to the string terminator byte.
                    Here = 
                        C.TheCharAddress +
                        C.TheStringItem->SizeOfData;
                        
                    // Update the string terminator.
                    *Here = 0;
                }
            }
        }
              
        // Advance to the next string in the list.
        ToNextString(&C);
    }
}

/*------------------------------------------------------------
| StripTrailingWhiteSpaceInStringList
|-------------------------------------------------------------
|
| PURPOSE: To strip "white space" characters (defined below) 
|          from the end of each string in a list.
|
| DESCRIPTION: White space characters are any of the 
| following:
|
|           spaces, tabs, carriage returns, line feeds
|
| EXAMPLE:  
|          StripTrailingWhiteSpaceInStringList( AList );
|
| HISTORY: 08.12.01 
|          08.19.01 Added SizeOfString().
|          08.25.01 Revised to support counted strings.
------------------------------------------------------------*/
void
StripTrailingWhiteSpaceInStringList( List* L )
                                          // A list of 
                                          // strings.
{
    ThatChar C;
    s8*      Here;
    s8*      Last;
    u32      CharCount;
    u32      WhiteCount;
    
    // Refer to the first string in the list.
    ToFirstString( L, &C );
    
    // For each string in the list.
    while( C.TheStringItem )
    {
        // If the current string contains characters.
        if( C.TheCharAddress )
        {
            // Get the string count.
            CharCount = SizeOfString( C.TheStringItem );

            // Refer to the last character of the string.
            Last = C.TheCharAddress + CharCount - 1;
            
            // Make a separate string cursor for scanning.
            Here = Last;
            
            // Scan back to the first non-white character 
            // in the string.
            SkipWhiteSpaceBackward( &Here );
            
            // Calculate the number of whitespace chars
            // found.
            WhiteCount = Last - Here;
            
            // If white chars have been found.
            if( WhiteCount )
            {
                // If the white character count is less
                // than the string count.
                if( WhiteCount < CharCount )
                {
                    // Adjust the byte count.
                    C.TheStringItem->SizeOfData = 
                        CharCount - WhiteCount;
                }   
                else // The entire string is white.
                {
                    // Adjust the byte count.
                    C.TheStringItem->SizeOfData = 0;
                }
                
                // If the string has a zero-terminator.
                if( C.TheStringItem->TypeOfData &
                    ZERO_ENDED_STRING )
                {
                    // Refer to the string terminator byte.
                    Here = 
                        C.TheCharAddress +
                        C.TheStringItem->SizeOfData;
                        
                    // Update the string terminator.
                    *Here = 0;
                }
            }
        }
              
        // Advance to the next string in the list.
        ToNextString(&C);
    }
}

/*------------------------------------------------------------
| ToCharNotOfClass
|-------------------------------------------------------------
|
| PURPOSE: To scan for a member of a class of characters.
|
| DESCRIPTION: Tests the current character in a string list to 
| find out if it is a member of a class of characters, 
| scanning forward till a match is found or the end of the 
| string list is reached.
|
| EXAMPLE: 
|
|  Scan to the any characters that is not 'a', 'b' or 'c'.
|
|            ToCharNotOfClass( &C, "abc", 3 );
|
| HISTORY: 08.19.01 From ToCharOfClass().
------------------------------------------------------------*/
void
ToCharNotOfClass( 
    ThatChar* C, 
                // A character cursor.
                // 
    s8*       ClassBuffer,
                // A buffer containing all the characters that
                // are members of the class.
                //
    u32       MemberCount )
                // Number of characters in the class buffer.
{
    // Until whitespace is found or end of list is reached.
    while(1)
    {
        // If the end of the string list has been reached.
        if( C->TheStringItem == 0 )
        {
            // Just return.
            return;
        }
    
        // If the current string has characters.
        if( C->TheCharAddress )
        {
            // If the current character is not in class.
            if( IsByteInBytes( (u8*) 
                    ClassBuffer, 
                        // The buffer containing the bytes 
                        // to scan.
                        //
                    MemberCount, 
                        // Number of bytes in the buffer.
                        //
                    (u32) C->TheCharAddress[0] ) == 0 )  
                        // The byte value to look for.
            {
                // Then return.
                return;
            }
        }
        
        // Advance to the next character.
        ToNextChar( C );
    }
}

/*------------------------------------------------------------
| ToChar
|-------------------------------------------------------------
|
| PURPOSE: To scan forward until a matching character has 
|          been found.
|
| DESCRIPTION: Tests the current character in a string list to 
| find out if it matches the given character value, scanning 
| forward till a match is found or the end of the string list 
| is reached.
|
| EXAMPLE: Scan to the character 'a'.
|
|                  ToChar( &C, 'a' );
|
| HISTORY: 08.25.01 ToCharOfClass().
------------------------------------------------------------*/
void
ToChar( 
    ThatChar* C, 
                // A character cursor.
                // 
    s8        CharValue )
                // The character to search for.
{
    // Until character is found or end of list is reached.
    while( C->TheStringItem )
    {
        // If the cursor refers to a character.
        if( C->TheCharAddress )
        {
            // If the current character matches.
            if( C->TheCharAddress[0] == (s8) CharValue )  
            {
                // Then return.
                return;
            }
        }
        
        // Advance to the next character.
        ToNextChar( C );
    }
}

/*------------------------------------------------------------
| ToCharOfClass
|-------------------------------------------------------------
|
| PURPOSE: To scan for a member of a class of characters.
|
| DESCRIPTION: Tests the current character in a string list to 
| find out if it is a member of a class of characters, 
| scanning forward till a match is found or the end of the 
| string list is reached.
|
| EXAMPLE: Scan to the any of the characters 'a', 'b' or 'c'.
|
|                ToCharOfClass( &C, "abc", 3 );
|
| HISTORY: 08.19.01 From ToWhiteSpace().
|          08.25.01 Simplified logic.
------------------------------------------------------------*/
void
ToCharOfClass( 
    ThatChar* C, 
                // A character cursor.
                // 
    s8*       ClassBuffer,
                // A buffer containing all the characters that
                // are members of the class.
                //
    u32       MemberCount )
                // Number of characters in the class buffer.
{
    // Until character is found or end of list is reached.
    while( C->TheStringItem )
    {
        // If the cursor refers to a character.
        if( C->TheCharAddress )
        {
            // If the current character is in class.
            if( IsByteInBytes( (u8*) 
                    ClassBuffer, 
                        // The buffer containing the bytes 
                        // to scan.
                        //
                    MemberCount, 
                        // Number of bytes in the buffer.
                        //
                    C->TheCharAddress[0] ) )  
                        // The byte value to look for.
            {
                // Then return.
                return;
            }
        }
        
        // Advance to the next character.
        ToNextChar( C );
    }
}

/*------------------------------------------------------------
| ToChars
|-------------------------------------------------------------
|
| PURPOSE: To scan for a given sequence of characters.
|
| DESCRIPTION: Tests the current character in a string list to 
| find out if it matches the given sequence, scanning forward 
| till a match is found or the end of the string list is 
| reached.
|
| EXAMPLE: Scan to the characters "IPTION".
|
|                ToChars( &C, "IPTION", 6 );
|
| HISTORY: 08.25.01 From ToCharOfClass().
------------------------------------------------------------*/
void
ToChars( 
    ThatChar* A, 
                // A character cursor.
                // 
    s8*       MatchChars,
                // A buffer containing the sequence of 
                // characters to match.
                //
    u32       CharCount )
                // Number of characters in the sequence.
{
    u32       i;
    ThatChar  B;
    s8        LastChar;
    
    // Start by searching to match the last character.
    i = CharCount - 1;
    
    // Get the last character of the match pattern.
    LastChar = MatchChars[i];
    
    // Advance the scanner to the place which would 
    // correspond with the last character to be matched.
    ToNextChars( A, i );
    
    // Until match is found or end of list is reached.
    while( A->TheStringItem )
    {
        // Scan for the last character.
        ToChar( A, LastChar );
        
        // If the cursor refers to a character then the
        // last character has been found.
        if( A->TheCharAddress )
        {
            // Note the starting forward point where matching
            // begins as 'B'.
            B = *A;
    
            // While the current character matches, from
            // last-to-first.
            while( A->TheCharAddress[0] == MatchChars[i] )
            {
                // If the first char matches.
                if( i == 0 )
                {
                    // Then return with a match.
                    return;
                }
                else // Not yet at the first character of
                     // the match sequence.
                {
                    // Decrement to the prior char in the
                    // match pattern.
                    i--;
                    
                    // Step the scanner back one char.
                    ToPriorChar( A );
                }
            }
            
            // No match has been found.
            
            // Reset the match char to the last one.
            i = CharCount - 1;
            
            // Advance the new start by one char.
            ToNextChar( &B );
            
            // Reset the scanner A to where it should start.
            *A = B;
        }
    }
}

/*------------------------------------------------------------
| ToFirstCharInString
|-------------------------------------------------------------
|
| PURPOSE: To go to the first character in the current string.
|          from another character in the string.
|
| DESCRIPTION: Updates all the fields of the character cursor
| to refer to the first character in the string.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no character in the current string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.25.01 From ToPriorCharInString().
------------------------------------------------------------*/
void
ToFirstCharInString( ThatChar* C )
{
    // If the current character or string is missing.
    if( ( C->TheCharAddress == 0 ) || 
        ( C->TheStringItem  == 0 ) )
    {
        // Then there is no prior character.
        
        // Just return.
        return;
    }
     
    // If the current character is the first one in the
    // string.
    if( C->TheCharInStringOffset == 0 )
    {
        // Just return.
        return;
    }
    else // The current character is not the first in the
         // string.
    {
        // Decrement the character address by the 
        // char-in-string offset.
        C->TheCharAddress -= C->TheCharInStringOffset;
        
        // Decrement the character-in-list offset by
        // the char-in-string offset.
        C->TheCharOffset -= C->TheCharInStringOffset;
        
        // Zero the character-in-string offset.
        C->TheCharInStringOffset = 0;
    }
}

/*------------------------------------------------------------
| ToFirstString
|-------------------------------------------------------------
|
| PURPOSE: To refer to the first character in the first 
|          string.
|
| DESCRIPTION: Updates the fields of the character cursor
| to refer to the first character in the first string.
|
| Returns with 'TheCharAddress' field set to zero if the 
| current string is empty.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorString().
|          08.25.01 Added char-in-list offset support.
------------------------------------------------------------*/
void
ToFirstString( List* L, ThatChar* C )
{
    u32 Size;
    
    // Set the string list.
    C->TheStringList = L;
     
    // Make the cursor refer to the first string. 
    C->TheStringItem = L->FirstItem;
    
    // Set the string offset to 0 to indicate the first
    // string in the list.
    C->TheStringOffset = 0;
    
    // Set the character offset to 0 to indicate the first
    // character in the list.
    C->TheCharOffset = 0;
    
    // Measure the size of the string.
    Size = SizeOfString( C->TheStringItem );

    // If there are characters in the string.
    if( Size )
    {
        // Refer to the first character in the string.
        C->TheCharAddress = (s8*) 
            C->TheStringItem->DataAddress;
            
        // Set the character offset to 0 to indicate the first
        // character in the string.
        C->TheCharInStringOffset = 0;
    }
    else // There is no next string.
    {
        // Mark the address of the current character to
        // indicate that there is no character.
        C->TheCharAddress = 0;
    }
}

/*------------------------------------------------------------
| ToLastCharInString
|-------------------------------------------------------------
|
| PURPOSE: To go to the last character in the current string.
|          from another character in the string.
|
| DESCRIPTION: Updates all the fields of the character cursor
| to refer to the last character in the string.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no character in the current string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.25.01 From ToFirstCharInString().
------------------------------------------------------------*/
void
ToLastCharInString( ThatChar* C )
{
    u32 CharCount;
    u32 AdvanceCount;
    s8* Last;

    // If the current character or string is missing.
    if( ( C->TheCharAddress == 0 ) || 
        ( C->TheStringItem  == 0 ) )
    {
        // Then there is no last character.
        
        // Just return.
        return;
    }
    
    // Get the string count.
    CharCount = SizeOfString( C->TheStringItem );
     
    // Refer to the last character of the string.
    Last = (s8*) 
        C->TheStringItem->DataAddress + 
        CharCount - 1;
    
    // Calculate the number of characters to advance.
    AdvanceCount = Last - C->TheCharAddress;

    // If the current character is not the last one in
    // the string.
    if( AdvanceCount )
    {
        // Advance the character address to the last
        // character.
        C->TheCharAddress += AdvanceCount;
        
        // Advance the character-in-list offset by
        // the same amount.
        C->TheCharOffset += AdvanceCount;
        
        // Advance the character-in-string offset.
        C->TheCharInStringOffset += AdvanceCount;
    }
}

/*------------------------------------------------------------
| ToLastString
|-------------------------------------------------------------
|
| PURPOSE: To go to the first character in the last string.
|
| DESCRIPTION: Updates the fields of the character cursor
| to refer to the first character in the last string.
|
| Returns with 'TheCharAddress' field set to zero if the last
| string is empty.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorString().
|          08.25.01 Revised to scan from the start of the
|                   list so that TheCharOffset will be 
|                   computed.
------------------------------------------------------------*/
void
ToLastString(  List* L, ThatChar* C )
{
    // Refer to the first character in the first string.
    ToFirstString( L, C );

    // Until the last string has been reached.
    while( C->TheStringItem != L->LastItem )
    {
        // Advance to the next string.
        ToNextString( C );
    }
}
 
/*------------------------------------------------------------
| ToNextChar
|-------------------------------------------------------------
|
| PURPOSE: To advance to the next character in the string list
|          from the current one.
|
| DESCRIPTION: Updates all the fields of the character cursor
| to refer to the next existing character in the list.
|
| Empty strings are skipped over.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no next string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorChar().
------------------------------------------------------------*/
void
ToNextChar( ThatChar* C )
{
    // If the current string is missing.
    if( C->TheStringItem == 0 )
    {
        // Then the end of the string list as been reached.
        //
        // There is no next character.
        
        // Clear the character address.
        C->TheCharAddress = 0;
        
        // And return.
        return;
    }

    // If the current character position holds a character,
    // this being a reference into a non-empty string.
    if( C->TheCharAddress )
    {
        // Advance to the next character in the current 
        // string.
        ToNextCharInString( C );
    }

    // If the current character position doesn't refer to
    // a character, the current string being empty.
    if( C->TheCharAddress == 0 )
    {
        // Make the current string the next string that has
        // characters in it and set the first character as 
        // current.
        ToNextStringWithChars( C );
    }
}

/*------------------------------------------------------------
| ToNextCharInString
|-------------------------------------------------------------
|
| PURPOSE: To go to the next character in the current string.
|
| DESCRIPTION: Updates all the fields of the character cursor
| to refer to the next character in the string.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no next character in the current string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorChar().
------------------------------------------------------------*/
void
ToNextCharInString( ThatChar* C )
{
    u32   CharCount;

    // If the current character or string is missing.
    if( ( C->TheCharAddress == 0 ) || 
        ( C->TheStringItem  == 0 ) )
    {
        // Then there is no next character.
        
        // Just return.
        return;
    }
     
    // Count the number of characters in the current string.
    CharCount = SizeOfString( C->TheStringItem );
    
    // If the current character is the last one in the
    // string.
    if( C->TheCharInStringOffset == ( CharCount - 1 ) )
    {
        // Mark the character as missing by setting the
        // address to zero.
        //
        // Setting TheCharAddress to 0 makes TheCharOffset
        // and TheCharInStringOffset fields invalid.
        //
        C->TheCharAddress = 0;
    }
    else // The current character is not the last in the
         // string.
    {
        // Just refer to the next character in the same
        // string.
        C->TheCharAddress += 1;
        
        // Update the character-in-string offset.
        C->TheCharInStringOffset += 1;
        
        // Update the character-in-list offset.
        C->TheCharOffset += 1;
    }
}

/*------------------------------------------------------------
| ToNextChars
|-------------------------------------------------------------
|
| PURPOSE: To advance a given number of characters from the
|          current one in a string list.
|
| DESCRIPTION: Updates all the fields of the character cursor
| to refer to the next existing character in the list.
|
| Empty strings are skipped over.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no next string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.25.01 From ToNextChar().
------------------------------------------------------------*/
void
ToNextChars( ThatChar* C, u32 CharCount )
{
    // While character steps remain.
    while( CharCount-- )
    {
        // Advance to the next character.
        ToNextChar( C );
        
        // If the current string is missing.
        if( C->TheStringItem == 0 )
        {
            // Then the end of the string list as been 
            // reached.
            // 
            // So just return.
            return;
        }
    }
}

/*------------------------------------------------------------
| ToNextString
|-------------------------------------------------------------
|
| PURPOSE: To go to the first character position in the next 
|          string, which may or may not hold a character.
|
| DESCRIPTION: Updates the fields of the character cursor
| to refer to the first character position in the next string.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no next string, or if the next string is empty.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorString().
------------------------------------------------------------*/
void
ToNextString( ThatChar* C )
{
    u32   CharCount;
    u32   CharsLeft;

    // If there is no current string.
    if( C->TheStringItem == 0 )
    {
        // Then the end of the string list as been reached.
        //
        // There is no next character.
        
        // Clear the character address.
        C->TheCharAddress = 0;

        // And return.
        return;
    }

    // If the current character position holds a character.
    if( C->TheCharAddress )
    {
        // Count the number of characters in the current 
        // string.
        CharCount = SizeOfString( C->TheStringItem );
    
        // Calculate the number of characters remaining in 
        // the current string.
        CharsLeft = CharCount - C->TheCharInStringOffset;
        
        // Update the character-in-list offset.
        C->TheCharOffset += CharsLeft;
    }
    
    // Make the current string refer to the next string. 
    C->TheStringItem = C->TheStringItem->NextItem;
    
    // Increment the string-in-list offset.
    C->TheStringOffset += 1;
    
    // Count the number of characters in the current string.
    CharCount = SizeOfString( C->TheStringItem );
    
    // If there are any characters in the current string.
    if( CharCount )
    {
        // Refer to the first character in the string.
        //
        // The address of this string may be zero.
        C->TheCharAddress = (s8*) 
            C->TheStringItem->DataAddress;
            
        // Set the character-in-string offset to 0 to indicate 
        // the first character in the string.
        C->TheCharInStringOffset = 0;
    }
    else // There are no characters in the string.
    {
        // Zero the address of the current character to 
        // indicate that there is no character at the current
        // position.
        C->TheCharAddress = 0;
    }
}

/*------------------------------------------------------------
| ToNextStringWithChars
|-------------------------------------------------------------
|
| PURPOSE: To go to the first character in the next string 
|          that has characters in it.
|
| DESCRIPTION: Updates the fields of the character cursor
| to refer to the first character in the next non-empty 
| string.
|
| Returns with 'TheCharAddress' field set to zero if there is no
| next non-empty string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorString().
|          08.25.01 Simplified logic.
------------------------------------------------------------*/
void
ToNextStringWithChars( ThatChar* C )
{
    u32   CharCount;

    // Until a string with characters is found or the end
    // of the list is reached.
    while( C->TheStringItem )
    {
        // Advance to the next string which may be empty.
        ToNextString( C );
        
        // Count the number of characters in the current 
        // string.
        CharCount = SizeOfString( C->TheStringItem );
    
        // If the string has characters.
        if( CharCount )
        {
            // Then return.
            return;
        }
    }
}
 
/*------------------------------------------------------------
| ToNonWhiteSpaceSL
|-------------------------------------------------------------
|
| PURPOSE: To find the first non-whitespace character at or 
|          following the current character in a string list.
|
| DESCRIPTION: 
|
|  White space characters are any of the following:
|
|          spaces, tabs, carriage returns, line feeds
|
| HISTORY: 08.19.01 From ToWhiteSpaceSL().
|          08.25.01 Simplified logic.
------------------------------------------------------------*/
void
ToNonWhiteSpaceSL( ThatChar* C )
{
    s8  c;

    // Until non-whitespace is found or end of list is 
    // reached.
    while( C->TheStringItem )
    {
        // If the current position holds a character.
        if( C->TheCharAddress )
        {
            // Get the current character.
            c = C->TheCharAddress[0];
            
            // Is the current character non-white?
            if( IsWhiteSpace( c ) == 0 )  
            {
                // Then return.
                return;
            }
        }
        
        // Advance to the next character.
        ToNextChar( C );
    }
}

/*------------------------------------------------------------
| ToPriorChar
|-------------------------------------------------------------
|
| PURPOSE: To go to the prior character from the current one.
|
| DESCRIPTION: Updates all the fields of the character cursor
| to refer to the prior character in the list, such that 
| 'prior' means towards the first character in the list.
|
| Returns with 'TheCharAddress' field set to zero if there is no
| prior record.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorRecord().
|          08.25.01 Factored out ToPriorCharInString() and
|                   ToPriorStringWithChars().
------------------------------------------------------------*/
void
ToPriorChar( ThatChar* C )
{
    // If the current string is missing.
    if( C->TheStringItem == 0 )
    {
        // Then the start of the string list as been reached.
        //
        // There is no prior character.
        
        // Clear the character address.
        C->TheCharAddress = 0;
        
        // And return.
        return;
    }
    
    // If the current character position holds a character,
    // this being a reference into a non-empty string.
    if( C->TheCharAddress )
    {
        // Retreat to the next character in the current 
        // string.
        ToPriorCharInString( C );
    }

    // If the current character position doesn't refer to
    // a character, meaning that the first character has
    // been passed.
    if( C->TheCharAddress == 0 )
    {
        // Make the current string the prior string that 
        // has characters in it and set the first character 
        // as current.
        ToPriorStringWithChars( C );
        
        // If the character cursor refers to a character.
        if( C->TheCharAddress )
        {
            // Go the last character in the string.
            ToLastCharInString( C );
        }
    }
}

/*------------------------------------------------------------
| ToPriorCharInString
|-------------------------------------------------------------
|
| PURPOSE: To go to the prior character in the current string.
|
| DESCRIPTION: Updates all the fields of the character cursor
| to refer to the prior character in the string.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no prior character in the current string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.25.01 From ToNextCharInString().
------------------------------------------------------------*/
void
ToPriorCharInString( ThatChar* C )
{
    // If the current character or string is missing.
    if( ( C->TheCharAddress == 0 ) || 
        ( C->TheStringItem  == 0 ) )
    {
        // Then there is no prior character.
        
        // Just return.
        return;
    }
     
    // If the current character is the first one in the
    // string.
    if( C->TheCharInStringOffset == 0 )
    {
        // Mark the character as missing by setting the
        // address to zero.
        //
        // Setting TheCharAddress to 0 makes TheCharOffset
        // and TheCharInStringOffset fields invalid.
        //
        C->TheCharAddress = 0;
    }
    else // The current character is not the first in the
         // string.
    {
        // Just refer to the prior character in the same
        // string.
        C->TheCharAddress -= 1;
        
        // Update the character-in-string offset.
        C->TheCharInStringOffset -= 1;
        
        // Update the character-in-list offset.
        C->TheCharOffset -= 1;
    }
}

/*------------------------------------------------------------
| ToPriorString
|-------------------------------------------------------------
|
| PURPOSE: To go to the first character in the prior string.
|
| DESCRIPTION: Updates the fields of the character cursor
| to refer to the first character in the prior string.
|
| Returns with 'TheCharAddress' field set to zero if there is no
| prior string, or if the prior string is empty.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.19.01 From ToPriorRecord().
|          08.25.01 Added accounting for TheCharOffset.
------------------------------------------------------------*/
void
ToPriorString( ThatChar* C )
{
    u32   CharCount;

    // If there is no current string.
    if( C->TheStringItem == 0 )
    {
        // Then the start of the string list as been reached.
        //
        // There is no prior character.
        
        // Clear the character address.
        C->TheCharAddress = 0;

        // And return.
        return;
    }

    // If the current character position holds a character.
    if( C->TheCharAddress )
    {
        // Move to the first character in the current string.
        ToFirstCharInString( C );
    }
    
    // Make the current string refer to the prior string. 
    C->TheStringItem = C->TheStringItem->PriorItem;
    
    // Decrement the string offset.
    C->TheStringOffset -= 1;
    
    // Count the number of characters in the current 
    // string.
    CharCount = SizeOfString( C->TheStringItem );
    
    // If there are characters in the current string.
    if( CharCount )
    {
        // Refer to the first character in the string.
        C->TheCharAddress = (s8*) 
            C->TheStringItem->DataAddress;
            
        // Set the character offset to 0 to indicate the 
        // first character in the string.
        C->TheCharInStringOffset = 0;
    
        // Update the character-in-list offset to move
        // from the beginning of the old line to the
        // beginning of the new line.
        C->TheCharOffset -= CharCount;
    }
    else // There is no prior string or it is empty.
    {
        // Mark the address of the current character to
        // indicate that there is no character.
        C->TheCharAddress = 0;
    }
}

/*------------------------------------------------------------
| ToPriorStringWithChars
|-------------------------------------------------------------
|
| PURPOSE: To go to the first character in the prior string 
|          that has characters in it.
|
| DESCRIPTION: Updates the fields of the character cursor
| to refer to the first character in the first prior non-empty 
| string encountered.
|
| Returns with 'TheCharAddress' field set to zero if there is 
| no prior non-empty string.
|
| ASSUMES: The string list may contain empty strings.
|
| HISTORY: 08.25.01 From ToNextStringWithChars().
------------------------------------------------------------*/
void
ToPriorStringWithChars( ThatChar* C )
{
    u32   CharCount;

    // Until a string with characters is found or the start
    // of the list is reached.
    while( C->TheStringItem )
    {
        // Retreat to the prior string which may be empty.
        ToPriorString( C );
        
        // Count the number of characters in the current 
        // string.
        CharCount = SizeOfString( C->TheStringItem );
    
        // If the string has characters.
        if( CharCount )
        {
            // Then return.
            return;
        }
    }
}

/*------------------------------------------------------------
| ToWhiteSpaceSL
|-------------------------------------------------------------
|
| PURPOSE: To find the first whitespace character at or 
|          following the current character in a string list.
|
| DESCRIPTION: 
|
|  White space characters are any of the following:
|
|          spaces, tabs, carriage returns, line feeds
|
| HISTORY: 08.19.01 From ToWhiteSpace().
------------------------------------------------------------*/
void
ToWhiteSpaceSL( ThatChar* C )
{
    s8  c;

    // Until whitespace is found or end of list is reached.
    while(1)
    {
        // If the end of the string list has been reached.
        if( C->TheStringItem == 0 )
        {
            // Just return.
            return;
        }
    
        // If the current string has characters.
        if( C->TheCharAddress )
        {
            // Get the current character.
            c = C->TheCharAddress[0];
            
            // Is the current character white?
            if( IsWhiteSpace( c ) )  
            {
                // Then return.
                return;
            }
        }
        
        // Advance to the next character.
        ToNextChar( C );
    }
}
