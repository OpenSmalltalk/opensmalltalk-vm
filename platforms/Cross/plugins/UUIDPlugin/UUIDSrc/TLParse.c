/*------------------------------------------------------------
| TLParse.c
|-------------------------------------------------------------
|
| PURPOSE: To provide commonly used data scanning and parsing 
|          procedures.
|
| HISTORY: 11.08.93 pulled from 'Bytes.c' and 'StringSys.c'
|          12.31.93 added 'IsByteInString'
|          01.14.94 added 'FindNthByteOfType'
|          01.27.00 Split out less commonly used functions
|                   to a new file called 'TLParseExtra.c'.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include <ctype.h>
#include <stdio.h>

#include "NumTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStrings.h"
#include "TLStacks.h"
#include "TLDate.h"
#include "TLf64.h"

#include "TLParse.h"

#define lower(c)        (isupper(c) ? tolower(c) : (c))

// Globals used to refer to the current word in the 
// current string.
s8* AtTheString;        // Address of first byte of current 
                        // string.
                        //
s8* AtTheStringEnd;     // Address of terminal zero of current 
                        // string.
                        //
s8* TheWord;            // Address of first byte of the 
                        // current word in the current string
                        // or zero if no word is current.
                        //
s8* AtTheWordEnd;       // Address of first byte after the
                        // current word or the address of the
                        // string terminator if there is no
                        // current word.
                        //
s8  TheWordDelimiter;   // The byte following the current 
                        // word which has temporarily been
                        // replaced with a zero to make the
                        // word a string.

Stack* StringStack = 0; // Stack used to preserve/restore
                        // the current string context.

/*------------------------------------------------------------
| AddressOfNthWordInLine
|-------------------------------------------------------------
|
| PURPOSE: To return the address of the nth word in a line.
|
| DESCRIPTION: The index of the first word is 0, the second
| is 1 and so on.  Expects the address of a byte somewhere
| in the line.
|
| EXAMPLE:  
|
|      At = AddressOfNthWordInLine( InLine );
|
| NOTES:  
|
| ASSUMES: There is a prior line.
|
| HISTORY: 06.27.97
------------------------------------------------------------*/
s8*
AddressOfNthWordInLine( s8* InLine, s32 n )
{
    s8* A;
    
    // Put the cursor at the word.
    A = InLine;
    
    // Move cursor back to the start of the line.   
    ToStartOfLine( &A );
    
    // Skip over preceeding words to the one sought.
    while( n-- )
    {
        SkipWord( &A );
    }
    
    // Skip any white space following the last word.
    SkipWhiteSpace( &A );
    
    // Return the address of the word.
    return( A );
}

/*------------------------------------------------------------
| CopyBytesUntilDelimiter
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of bytes up to a given delimiter.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTES:  Not validated.
|
| ASSUMES: Delimiter byte is passed in the low byte of a u16.
|          Source and Target buffers are non-overlapping.
|
| HISTORY: 02.04.93 
|          09.22.93 replaced stack relative argument addresses 
|                   with names
|          11.01.93 assembler version replaced with portable 
|                   'C' routine
|          11.10.93 parameter changed to 'u16' from 'u8'.
|          12.23.96 parameter changed to 'u32' from 'u16';
|                   added byte count of copied bytes.
|          
------------------------------------------------------------*/
s32
CopyBytesUntilDelimiter( u8* Source, 
                         u8* Target, 
                         u32 Delimiter )
{
    s32 i;
    
    i = 0;
    
    while( *Source != Delimiter )
    {
        *Target++ = *Source++;
        i++;
    }
    
    return( i );
}

/*------------------------------------------------------------
| CountBytesOfTypeInString
|-------------------------------------------------------------
|
| PURPOSE: To count the number of occurances of the 
|          given byte in the given string.
|
| DESCRIPTION: Returns count.
|
| EXAMPLE:  n = CountBytesOfTypeInString( AString, (u16) ':' );
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 08.03.96
------------------------------------------------------------*/
u32
CountBytesOfTypeInString( s8* AString, u16 AByte )
{
    u32 N;
    u8  b;
    
    N = 0;

FindAnother:    

    b = (u8) *AString;
    
    if( b == AByte ) 
    {
        N++;
    }
    
    if( b )
    {
        AString++;
        
        goto FindAnother;
    }
    
    return( N );
}

/*------------------------------------------------------------
| CountDataInString
|-------------------------------------------------------------
|
| PURPOSE: To return a count of the data items in the given 
|          ASCII string.
|
| DESCRIPTION: 
|
| EXAMPLE: ACount = 
|             CountDataInString( "05/23/68 1.655 110" );
|
|      returns 3.
| 
|      and 'CountOfBytesParsed' is altered.
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.22.95 .
------------------------------------------------------------*/
u32
CountDataInString( s8* Source )
{
    u32 ACount;
    
    ACount = 0;
    
GetDatum:

    GetFirstDatumInString( Source );
    
    if( CountOfBytesParsed ) // a datum found.
    {
        ACount++;
        Source += CountOfBytesParsed;
        goto GetDatum;
    }
    
    return( ACount );
}

/*------------------------------------------------------------
| CountFiguresInString
|-------------------------------------------------------------
|
| PURPOSE: To count the figures, that is non-blank, ASCII 
|          characters in a 0-terminated string. 
|
| DESCRIPTION:  Terminating 0 is not included in the count.
|
| EXAMPLE:  ByteCount = CountFiguresInString( MyString );
|
| HISTORY: 02.17.97 from 'CountString'. 
------------------------------------------------------------*/
u32
CountFiguresInString( s8* AString )
{
    u32 FigureCount;
    s8  c;

    FigureCount = 0;

Another:

    // Get a character.
    c = *AString++;
    
    // Is end of string reached?
    if( c == 0 ) 
    {
        return( FigureCount );
    }
    
    // Is the character white-space.
    if( c == ' '  || c == '\t' || c == '\n' || c == '\r' )  
    {
        goto Another;
    }
    else // Found a figure.
    {
        FigureCount++;
        
        goto Another;
    }
}

/*------------------------------------------------------------
| CountItemsInCommaDelimitedString
|-------------------------------------------------------------
|
| PURPOSE: To count the fields in a comma-delimited string.
|
| DESCRIPTION:   
|
| EXAMPLE:  
|
|   ItemCount = CountItemsInCommaDelimitedString( "a,b,c" );
|
| results in 'ItemCount' = 3.
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 03.01.97 
------------------------------------------------------------*/
u32
CountItemsInCommaDelimitedString( s8* S )
{
    return( CountBytesOfTypeInString( S, (u16) ',' ) + 1 );
}

/*------------------------------------------------------------
| DeTabLine
|-------------------------------------------------------------
|
| PURPOSE: To translate a line of text containing tabs into 
|          one in which the tabs are replaced by spaces.
|
| DESCRIPTION: The occurance of a tab character in a line of
| text is interpreted as an instruction to move the following
| characters in the line to the next tab stop.  To translate
| tabs to an equivalent line with tabs replaces with spaces 
| it is necessary to know the tab stop interval to use.
|
| Note that the number of spaces needed to replace a tab 
| depends on the offset of the tab character from the 
| start of the line.
|
| EXAMPLE: The input line is "ab<tab>c<tab>de" and the tab 
| stop interval is 4 characters.
|
|                          
|   BEFORE:         
|             ----- Symbolize tabs using 'T'. 
|             | | 
| AtInput:  abTcTde              
|           +---+---+---+---+---+---+---+---+---+---+---+
|           |      |                         -->| 4 |<--
|           ---------- InputSize = 7       TabStopInterval 
|
|   OutputSize =                    
|       DeTabLine( 
|           AtInput, 
|           InputSize,        
|           TabStopInterval,  
|           AtOutput );
|
|    AFTER:
|                   
| AtOutput: ab  c   de              
|           +---+---+---+---+---+---+---+---+---+---+---+
|           |         |
|           -------------- OutputSize = 10
|
| ASSUMES: Input buffer holds only one line of text.
|
|          Input and output buffers are separate.
|
| HISTORY: 05.01.01 From DeTabBytes in TLTextEditor.c.
------------------------------------------------------------*/
u32         // OUT: Number of bytes in the output line buffer.
DeTabLine( 
    s8* AtInput,            
            // Input buffer holding a single line of text.
            //
    s8* AtOutput,
            // OUT: Output buffer that will hold the result
            //      line with tabs replaced by spaces.
    u32 InputSize,
            // Number of bytes in the input line.
            // 
    u32 TabStopInterval )
            // Number of characters between tab stops
            // assuming that tab stops are placed at
            // uniform intervals across the line.
{
    s32 i;
    u32 OutputSize;
    s32 SpacesToInsert;
    u8  TheByte;
 
    // Start the size of the output line at zero.
    OutputSize = 0;
    
    // For each input byte.
    for( i = 0; i < InputSize; i++ )
    {
        // Get next byte from the input line.
        TheByte = *AtInput++;
        
        // If the byte is a tab.
        if( TheByte == Tab )
        {
            // Calculate the number of spaces to insert
            // in order to shift subsequent characters to
            // the next tab stop.
            SpacesToInsert = 
                TabStopInterval - 
                ( OutputSize % TabStopInterval );
                
            // Account for the spaces that will be inserted
            // into the output line.
            OutputSize += SpacesToInsert;
                
            // Append spaces to the output line.
            while( SpacesToInsert-- )
            {
                *AtOutput++ = ' ';
            }
        }
        else // The byte is not a tab.
        {
            // Append the byte to the output line.
            *AtOutput++ = TheByte;
            
            // Account for the byte added to the output
            // line.
            OutputSize++;
        }
    }
    
    // Return the number of bytes in the output line.
    return( OutputSize );
}

/*------------------------------------------------------------
| FindByteInBytes
|-------------------------------------------------------------
|
| PURPOSE: To find a byte in a buffer, if it is there.
|
| DESCRIPTION: Returns address of the byte or 0 if not found.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.20.96 from 'FindByteInString'.
------------------------------------------------------------*/
u8*
FindByteInBytes( s32 SearchByte, u8* Buffer, s32 BufferCount )
{
    s8 AByte;
    s8 SByte;
    
    SByte = (s8) SearchByte;
    
    while( BufferCount-- )
    {
        AByte = (s8) *Buffer;
    
        if( AByte == SByte ) return( Buffer );
    
        Buffer++;
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| FindByteInString
|-------------------------------------------------------------
|
| PURPOSE: To find a byte in a given string, if it is there.
|
| DESCRIPTION: Returns address of the byte or 0 if not found.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 12.12.96 from 'IsByteInString'.
------------------------------------------------------------*/
s8*
FindByteInString( s32 SearchByte, s8* AString )
{
    s8 AByte;
    s8 SByte;
    
    SByte = (s8) SearchByte;
    
Another:
    
    AByte = *AString;
    
    if( AByte == SByte ) return( AString );
    
    if( AByte == 0 )     return( 0 );
    
    AString++;
    
    goto Another;
}

/*------------------------------------------------------------
| FindBytesInBytes
|-------------------------------------------------------------
|
| PURPOSE: To find the address of a byte pattern in a buffer. 
|
| DESCRIPTION: Returns the address or 0 if not found.
|
| EXAMPLE:  
|
| NOTE: This could be made more efficient.
|
| ASSUMES: 
|
| HISTORY: 04.04.91 
------------------------------------------------------------*/
u8*
FindBytesInBytes( u8* Pattern, s32 PatternCount,  
                  u8* Buffer,  s32 BufferCount ) 
{
    s32 i;
    
    i = BufferCount - PatternCount + 1;
    
    while( i )
    {
        if( IsMatchingBytes( Pattern, Buffer, (u32) PatternCount ) )
        {
            return( Buffer );
        }
        
        Buffer++;
        
        i--;
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| FindFieldHoldingValueInCommaDelimitedString
|-------------------------------------------------------------
|
| PURPOSE: To find the number of the first field in a comma-
|          delimited string that holds a given value.
|
| DESCRIPTION: Returns 0 for the first field, 1 for the second
| and so on.
|
| EXAMPLE:  
|
|   n = FindFieldHoldingValueInCommaDelimitedString( "a,b,c",
|                                                    "b" );
| results in n = 1.
|
| NOTE:  
|
| ASSUMES: The sought after value is in the string.
|
| HISTORY: 03.01.97 
------------------------------------------------------------*/
u32
FindFieldHoldingValueInCommaDelimitedString( s8* S, s8* Value )
{
    u32 n;
    s8* NthValue;
    
    n = 0;

Another:
    
    NthValue = ValueOfNthItemInCommaDelimitedString( n, S );

    if( IsMatchingStrings( NthValue, Value ) )
    {
        return( n );
    }
    
    n++;
    
    goto Another;
}

/*------------------------------------------------------------
| FindStringInBytes
|-------------------------------------------------------------
|
| PURPOSE: To find the address of a string pattern in a buffer. 
|
| DESCRIPTION: Returns the address or 0 if not found.
|
| EXAMPLE:  
|
| NOTE: This could be made more efficient.
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 04.04.91 
------------------------------------------------------------*/
s8*
FindStringInBytes( s8* Pattern, u8* Buffer,  s32 BufferCount ) 
{
    u32 PatternCount; 
    u32 i;
    
    // Count the length of the string.
    PatternCount = CountString( Pattern );
    
    i = BufferCount - PatternCount + 1;
    
    while( i )
    {
        if( IsMatchingBytes( (u8*) Pattern, Buffer, PatternCount ) )
        {
            return( (s8*) Buffer );
        }
        
        Buffer++;
        
        i--;
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| FindStringInString
|-------------------------------------------------------------
|
| PURPOSE: To find the address of a substring in another 
|          string.
|
| DESCRIPTION: Matching is case-insensitive. Returns 0 if not 
| found.
|
| This can be further optimized.
|
| ASSUMES: Strings are terminated with a 0.
|
| HISTORY: 04.04.91
|          01.02.97 simplified logic.
|          07.30.01 Optimized for speed.
------------------------------------------------------------*/
s8*
FindStringInString( s8* SubString, s8* String )
{
    s8 FirstSub;
    
    // Get the first character of the substring.
    FirstSub = lower( *SubString );
    
    // Until the end of the main string has been reached.
    while( *String )
    {
        // If the current character in String is the same
        // as the first character of the SubString.
        if( lower( *String ) == FirstSub )
        {
            // If the substring matches the string over the
            // entire length of the substring.
            if( IsPrefixForString( SubString, String ) )
            {
                // Return the location of the match.
                return( String );
            }
        }
        
        // Advance to the next character of the main
        // string.
        String++;
    }
    
    return(0);
}

/*------------------------------------------------------------
| FindNthByteOfType
|-------------------------------------------------------------
|
| PURPOSE: To find the address of the nth occurance of the 
|          given byte in the given string.
|
| DESCRIPTION: Returns 0 if nth occurance not found before
|              the end of the string.  The first occurance
|              is called index 0, the 2nd is called index 1 
|              and so on.
|
| EXAMPLE:  NthByteAddress = FindNthByteOfType(AString,
|                                 Index, (u16) '=');
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 01.14.94
|          08.03.96 found bug: was always returning the first
|                   occurance.  Rewrote.
------------------------------------------------------------*/
s8*
FindNthByteOfType( s8*  AString,
                   u32  Nth,
                   u32  AByte)
{
    s8  b;
    
FindAnother:
    
    b = *AString;
    
    if( b == 0 )
    {
        return( 0 ); // not found.
    }
    
    if( b == (s8) AByte )
    {
        if( Nth == 0 )
        {
            return( AString );
        }
        else
        {
            Nth--;
        }
    }
    
    AString++;
    
    goto FindAnother;
}

/*------------------------------------------------------------
| GetFirstDatumInString
|-------------------------------------------------------------
|
| PURPOSE: To return value of the first datum in the given 
|          ASCII string.
|
| DESCRIPTION: Always returns a 'fl64' format number.
|
| Dates expressed as 'mm/dd/yy' are converted to TradeTime format.
|
| 'NaN' is converted to the value of 'NoNum'.
|
| Time values expressed as 'hh:mm' are converted to 'hh.mm'
| number.
|
| Sets 'CountOfBytesParsed' to the number of
| bytes consumed from the given string.
|
| EXAMPLE: ADatum = 
|             GetFirstDatumInString( "05/23/68 1.655 NaN" );
| 
|      and 'CountOfBytesParsed' = 8
|
| NOTE: 
|
| ASSUMES: All data are non-complex numbers or dates.
|           
| HISTORY: 01.15.95 from 'GetFirstTokenInBytes'.
|          01.25.96 added support for 'NaN'.
|          12.18.96 added support for 'hh:mm'.
|          12.23.96 made 'hh:mm' -> 'hhmm' instead of 'hh.mm'.
|          07.20.96 fixed case where single digit number is
|                   parsed and ':' happens to be in the buffer
|                   at offset 2.
------------------------------------------------------------*/
f64
GetFirstDatumInString( s8* Source )
{
    s8      DatumStringBuffer[64];
    s8*     AfterDatum;
    f64     Result;
    
    // Parse the datum to the string buffer.
    AfterDatum = ParseDatum( Source, DatumStringBuffer );
    
    // An empty string returns a value of 0.
    if( AfterDatum == 0 )
    {
        CountOfBytesParsed = 0;
        return(0);
    }
    
    // Calculate how many bytes were consumed.
    CountOfBytesParsed = (u32) ( AfterDatum - Source );
    
    // Now convert the datum string to a number.
    if( DatumStringBuffer[2] == '/' )
    {
        Result = (f64) DateStringToTradeTime( DatumStringBuffer );
    }
    else // Either 'NaN', time, or a single number, possibly in scientific 
         // format.
    {
        if( DatumStringBuffer[0] == 'N' )
        {
            Result = NoNum; // Don't use 'NAN' because it doesn't hold
                            // its identity for use in comparisons with 
                            // '=='.
        }
        else // Either time or single number.
        {
            if( CountOfBytesParsed > 2 && DatumStringBuffer[2] == ':' )
            {
                Result = TimeStringTof64( DatumStringBuffer );
            }
            else // single number.
            {
                Result = ConvertStringTof64( DatumStringBuffer );
            }
        }
    }
    
    return( Result );
}

/*------------------------------------------------------------
| IndexOfWordInLine
|-------------------------------------------------------------
|
| PURPOSE: To compute the index of a word in a line.
|
| DESCRIPTION: Returns 0 if the addressed word is first, 1
| if second and so on.
|
| EXAMPLE:  
|
|      n = IndexOfWordInLine( AtWord );
|
| NOTES:  
|
| ASSUMES: There is a prior line.
|
| HISTORY: 06.27.97
------------------------------------------------------------*/
s32
IndexOfWordInLine( s8* AtWord )
{
    s8* A;
    s32 n;
    
    // Put the cursor at the word.
    A = AtWord;
    
    // Move cursor back to the start of the line.   
    ToStartOfLine( &A );
    
    // Count words until the given word is passed.
    
    n = 0;

Another:

    // Advance the cursor past the first word
    SkipWord( &A );

    // If the cursor is past the given word address.
    if( A >= AtWord )
    {
        // Return the index.
        return( n );
    }
        
    // Account for the word just passed.
    n++;
    
    goto Another;
}

/*------------------------------------------------------------
| InsertDelimiters
|-------------------------------------------------------------
|
| PURPOSE: To insert delimiter bytes between blocks of data 
|          bytes.
|
| DESCRIPTION: 
|
| EXAMPLE: You can use this procedure to insert end-of-line
| sequences into text at regular intervals.
|
|                          
|   BEFORE:          
|                    
|        AtData:[abcdefgh............]
|                |      |
|                --------- DataSize = 8
|
|        AtDelimiter:[///...]
|                     | |
|                     ------DelimiterSize=3 
|
|   NewDataSize =                    
|       InsertDelimiters( 
|           AtData, 
|           DataSize,
|           2, 
|           AtDelimiter, 
|           DelimiterSize );
|
|    AFTER:                   
|        AtData:[ab///cd///ef///gh............]
|                |               |
|                ------------------ NewDataSize = 17
|
| NOTE: Delimiters only appear between blocks, not at the
|       ends.
|
| ASSUMES: The buffer is large enough for the result.
|
| HISTORY: 02.15.99
------------------------------------------------------------*/
                            // Returns the size of the
                            // data after inserting 
u32                         // delimiter bytes.
InsertDelimiters( 
    u8*  AtData,            // Where the data is.
                            //
    u32  DataSize,          // How many data bytes there.
                            //
    u32  BlockSize,         // How many bytes are in each
                            // block of data.
                            //
    u8*  AtDelimiter,       // The delimiter bytes to insert.
                            //
    u32  DelimiterSize )    // How many delimiter bytes
                            // there are.
{
    u32 DelimiterCount;
    u32 LastBlockSize;
    u32 NewDataSize;
    u32 BlockPlusDelimiterSize;
    u32 BlockCount;
    u8* AtBlock;
    u8* AtNewBlock;
    
    // Calculate the size of a block plus a delimiter.
    BlockPlusDelimiterSize = BlockSize + DelimiterSize;
    
    // The last block may not have the same number of
    // bytes as the others.  Calculate the number of
    // bytes in the last block.
    LastBlockSize = DataSize % BlockSize;
    
    // If there is a fractional last block.
    if( LastBlockSize )
    {
        // Calculate the total number of blocks in the 
        // data buffer.
        BlockCount = ( DataSize / BlockSize ) + 1;
    }
    else // The data size is evenly divisible by the
         // block size.
    {
        // Then the last block is the same size as the
        // others.
        LastBlockSize = BlockSize;
    
        // Calculate the total number of blocks in the 
        // data buffer.
        BlockCount = DataSize / BlockSize;
    }
    
    // Calculate the number of delimiters.
    DelimiterCount = BlockCount - 1;
    
    // If there are no delimiters.
    if( DelimiterCount == 0 )
    {
        // Return the original data size.
        return( DataSize );
    }
    
    // Calculate the address of the last block.
    AtBlock =
        AtData + ( DelimiterCount * BlockSize );
        
    // Calculate the new address of the last block.
    AtNewBlock =
        AtData + ( DelimiterCount * 
                   BlockPlusDelimiterSize );
    
    // Calculate the new data size.
    NewDataSize =
        ( AtNewBlock + LastBlockSize ) - AtData;
        
    // Copy the last block to the new location.
    CopyBytes( AtBlock,         // From
               AtNewBlock,      // To
               LastBlockSize ); // ByteCount
    
    // For each delimiter.
    while( DelimiterCount-- )
    {       
        // Copy the delimiter before the new
        // block.
        CopyBytes( AtDelimiter,          // From
                   AtNewBlock -          // To
                      DelimiterSize,
                   DelimiterSize );      // ByteCount
                   
        // Refer to the prior source block.
        AtBlock -= BlockSize;
        
        // Refer to the prior target block.
        AtNewBlock -= BlockPlusDelimiterSize;
        
        // If the block needs to be moved: the
        // first block won't need to.
        if( AtBlock != AtNewBlock )
        {
            // Copy the prior block below the delimiter.
            CopyBytes( AtBlock,      // From
                       AtNewBlock,   // To
                       BlockSize );  // ByteCount
        }
    }
    
    // Return the new data size.
    return( NewDataSize );
}

/*------------------------------------------------------------
| IntersectString
|-------------------------------------------------------------
|
| PURPOSE: To make a string of characters that are common to
|          two given strings.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|      s8*  ABuffer[255];        
|                                  
|      IntersectString( "ABC", "ACX", ABuffer );
|                                  
|      yields: "AC"
|
| NOTE:  
|
| ASSUMES: There is room in the destination buffer for the 
|          result
|
| HISTORY: 07.25.96
------------------------------------------------------------*/
void
IntersectString( s8* A, s8* B, s8* Dest )
{
    s8  c;
    
    while( *A )
    {
        c = *A++;
        
        if( IsByteInString( B, c ) )
        {
            *Dest++ = c;
        }
    }
    
    *Dest = 0; // String terminator.
}

/*------------------------------------------------------------
| IsAnySubStringInString
|-------------------------------------------------------------
|
| PURPOSE: To find the address of any substring in another 
|          string.
|
| DESCRIPTION: Matching is case-insensitive. Returns 0 if not 
| found.
|
| ASSUMES: Substring list is terminated with a 0.
|
| HISTORY: 07.16.01
|          01.02.97 simplified logic.
------------------------------------------------------------*/
u32
IsAnySubStringInString( s8** SubString, s8* String )
{   
    // As long as there is a substring.
    while( *SubString )
    {
        // If the substring is found in the other string.
        if( FindStringInString( *SubString, String ) )
        {
            // Return 1 to signal a substring was found.
            return(1);
        }
        
        // Advance to the next substring.
        SubString++;
    }
    
    // Return 0 to signal no substring found.
    return(0);
}

/*------------------------------------------------------------
| IsByteInString
|-------------------------------------------------------------
|
| PURPOSE: To tell if a byte exists in a given string.
|
| DESCRIPTION: Returns 1 if the byte is found before the
| end of the string, else 0.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY:  12.31.93 
------------------------------------------------------------*/
u32
IsByteInString(s8* AString, u16 SearchByte)
{
    u8 AByte;
    u8 SByte;
    u8* AtBytes;
    
    AtBytes = (u8*) AString;
    SByte   = (u8) SearchByte;
    
Another:    
    AByte = *AtBytes;
    
    if(AByte == SByte) return(1);
    if(AByte == 0)     return(0);
    
    AtBytes++;
    
    goto Another;
}

/*------------------------------------------------------------
| IsParensBalancedInString
|-------------------------------------------------------------
|
| PURPOSE: To test if the parentheses characters in a string
|          of character codes are properly paired with each 
|          other.
|
| DESCRIPTION: Expects the address of a buffer holding the
| characters
|
| Returns '1' if parens are present and balanced or if 
| there are no parens.  
|
| Returns '0' if there are unbalanced parens in the 
| string buffer.
|
| EXAMPLE:  
|
| IsOk = IsParensBalancedInString( (u8*) "ab(c", 4, 1 );
| IsOk = IsParensBalancedInString( (u8*) "a)(c", 4, 1 );
|
|   return '0', whereas
|
| IsOk = IsParensBalancedInString( (u8*) "a(b)", 4, 1 );
|
|   returns '1'.
|
| NOTE: This routine is Unicode compatible provided that
|       the 'BytePerChar' parameter is set to 2.
|
| ASSUMES: Character code 40 decimal is left paren and 
|          character code 41 decimal is right paren in all 
|          encoding schemes used for string data.
|
|          One or two bytes per character.
|
|          The high order byte of a Unicode character appears
|          first.
|
| HISTORY: 01.31.99 From 'IsParensValidInFormula()'.
|          03.14.99 Added 'IsHiByteFirst'.
------------------------------------------------------------*/
u32
IsParensBalancedInString( 
    u8*     ACharBuf,       // Address of buffer holding the
                            // character codes.
                            //
    u32     CharCount,      // How many character codes there are.
                            //
    u32     BytesPerChar,   // How many bytes per character.
                            //
    u32     IsHiByteFirst ) // 1 if the high-order byte of the 
                            // source characters come first, 0
                            // if low-order byte comes first.
{
    s32 ParenLevel;
    u16 AChar;
    
    // Start with no parens registered.
    ParenLevel = 0;
    
    // Until all of the characters have been scanned.
    while( CharCount-- )
    {
        // If there is one byte per character in this string.
        if( BytesPerChar == 1 )
        {
            // Get the next 8-bit character from the buffer
            // and advance the character pointer. 
            AChar = (u16) (*ACharBuf++);
        }
        else // Assume a double byte Unicode character.
        {
            // If the high-order byte comes first.
            if( IsHiByteFirst )
            {
                // Get the next 16-bit character from the buffer:
                // high-order byte is first.
                AChar = ( (u16) (*ACharBuf++) ) << 8;
                
                // Low-order byte follows.
                AChar |= (u16) (*ACharBuf++);
            }
            else // Low-order byte comes first.
            {
                // Get the next 16-bit character from the buffer:
                // low-order byte is first.
                AChar = (u16) ( *ACharBuf++ );
                
                // High-order byte follows.
                AChar |= ( (u16) ( *ACharBuf++ ) ) << 8;
            }
        }
        
        // If the character is a left paren, '('.
        if( AChar == (u16) '(' )
        {
            // Update the paren nesting level: enter the
            // next deeper level.
            ParenLevel++;
        }
        else // Not a left paren.
        {
            // If the character is a right paren, ')'.
            if( AChar == (u16) ')' )
            {
                // Update the paren nesting level: exit the
                // the current level to the next shallower one.
                ParenLevel--;
                
                // If the paren level is negative.
                if( ParenLevel < 0 ) 
                {
                    // Then parens are unbalanced.
                    return( 0 );
                }       
            }
        }
    }
    
    // If paren level has returned to the initial state.
    if( ParenLevel == 0 ) 
    {
        // Then any parens in the string are balanced.
        return( 1 );
    }
    else // Parens are in the string but aren't balanced.
    {
        // Signal the presence of unbalanced parens.
        return( 0 );
    }
}

/*------------------------------------------------------------
| IsPrefixForString
|-------------------------------------------------------------
|
| PURPOSE: To tell if one case-insensitive string is the 
|          prefix for another.
|
| DESCRIPTION: Comparison operation.
|              Returns: 1 if string AA prefix for string BB.
|                       0 if AA <> BB.
|
| Compared until end of first string or until an in-equality 
| is detected.
|
| EXAMPLE:  
|
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY:  04.04.91 
|           09.22.93 added 1/0, changed for() to while()
------------------------------------------------------------*/
u32
IsPrefixForString( s8* AA, s8* BB )
{
    while(1)
    {
        // Look for end of first string.
        if(*AA == 0) return(1);  
               
        if(lower(*AA) != lower(*BB))
            return(0);          // unequal
        AA++;
        BB++;
    }
}

/*------------------------------------------------------------
| IsSuffixForString
|-------------------------------------------------------------
|
| PURPOSE: To tell if the endings of two strings match.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTES:  
|
| ASSUMES: 
|
| HISTORY: 02.01.89 
------------------------------------------------------------*/
u32
IsSuffixForString(s8* EndingString, 
                  s8* AString)
{
    s8* EndingCharPointer;
    s8* ACharPointer;
    u32 MatchFound;
    
    EndingCharPointer = AddressOfLastCharacterInString(EndingString);
    ACharPointer      = AddressOfLastCharacterInString(AString);


    while(*EndingCharPointer == *ACharPointer)
    {
        --EndingCharPointer;
        --ACharPointer;
    }
    
    ++EndingCharPointer;
    ++ACharPointer;
    
    MatchFound = 0;

    if( 
            ( EndingCharPointer  == EndingString  ) && 
            ( *EndingCharPointer == *ACharPointer )
       )
    {
        MatchFound = 1;
    }

    return (MatchFound);
}

/*------------------------------------------------------------
| JoinNameAndValue
|-------------------------------------------------------------
|
| PURPOSE: To form a name:value pair connected by a 
|          delimiter, eg. "X=2".
|
| DESCRIPTION: 
|
| EXAMPLE:  JoinNameAndValue( NameAndValue, 
|                             Name, 
|                             '=', 
|                             Value ); 
| HISTORY: 03.01.97
------------------------------------------------------------*/
void
JoinNameAndValue( s8* NameAndValue, 
                  s8* Name, 
                  u32 Delimiter, 
                  s8* Value ) 
{
    s8  D[2];
    
    // Copy the delimiter byte to the delimiter string buffer.
    D[0] = (s8) Delimiter;
    D[1] = 0;
    
    // Mark the result as empty.
    NameAndValue[0] = 0;
    
    // Append the parts together.
    AppendStrings( Name, D, Value, 0 );
}

/*------------------------------------------------------------
| LocationOfNthItemInCommaDelimitedString
|-------------------------------------------------------------
|
| PURPOSE: To get the address of the nth field in a comma-
|          delimited string.
|
| DESCRIPTION: The first field is referred as field 0, the
| next as field 1, and so on. 
|
| Returns the address of the field or a zero if the field 
| isn't found in the string.
|
| EXAMPLE:  
|
|     x = LocationOfNthItemInCommaDelimitedString( 2, "a,b,c" );
|
| results in 'x' holding the address of the 'c' in "a,b,c".
|
| NOTES:  
|
| ASSUMES:  
|
| HISTORY: 03.01.97
------------------------------------------------------------*/
s8*
LocationOfNthItemInCommaDelimitedString( u32 n, s8* S )
{
    s8* AtComma;
    
    // The first item begins where the string begins.
    if( n == 0 )
    {
        return( S );
    }
    
    // Find the comma that marks the beginning of the field.
    AtComma = FindNthByteOfType( S, (u32) n, (u32) ',' );
    
    // If the comma was found.
    if( AtComma )
    {   
        // The field starts just after the comma.
        return( AtComma + 1 );
    }
    else // Field not found.
    {
        return( 0 );
    }
}              

/*------------------------------------------------------------
| ParseBytes
|-------------------------------------------------------------
|
| PURPOSE: To parse a series of bytes delimited by a byte code,
| from a byte zone to a buffer.  
|
| DESCRIPTION: The result is a series of bytes held in the
| target buffer, a count of those byte in the global variable
| 'CountOfBytesParsed', and finally, the address of the next 
| byte to be parsed is the return value.  The return value
| is the address of the byte immediately following the terminal
| delimiter, or 0 if there are no more bytes to parse.
|
| EXAMPLE:  Head = ParseBytes( Head, Tail, Target, '"' );
|
| Before:
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*]["][a]["][&][ ][ ][ ][ ][ ][ ]
|                       ^              ^
|                       Head           Tail    
|
|       [ ][ ][ ][ ][ ][ ][ ]
|        ^
|        Target
|
|       CountOfBytesParsed = 0 
|
| After:
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*]["][a]["][&][ ][ ][ ][ ][ ][ ]
|                                   ^  ^
|                                Head  Tail    
|
|       [a][ ][ ][ ][ ][ ][ ]
|        ^
|        Target
|
|       CountOfBytesParsed = 1 
|       return value = Head, the byte following the delimiter.
|
| NOTE: See also 'ParseWord' & 'ParseString' in 'StringSys.c'.
|
| ASSUMES: 
|
| HISTORY: 03.20.92 
|          03.22.92 fixed error where result args not returned
|          11.10.93 parameter changed to 'u16' from 'u8'.
------------------------------------------------------------*/

u8*
ParseBytes(u8* Head,
           u8* Tail,
           u8* Target,
           u16 Delimiter)
{
    u8* CurrentHead;
    u8* StartAddress;

    CountOfBytesParsed = 0;
   /* 
    * Find the first delimiter.
    */
    CurrentHead = ScanBytesEQ(Head,Tail,Delimiter);
    
    if(CurrentHead) /* Beginning delimiter found. */
    {
     /* 
      * Remember the start address.
      */
        StartAddress = CurrentHead+1;
     
        // Now look for the ending delimiter.
        CurrentHead = ScanBytesEQ(StartAddress,Tail,Delimiter);
     
        // Ending delimiter found.
        if( CurrentHead ) 
        {
            CountOfBytesParsed = (u32)
                ( CurrentHead - StartAddress );
            
            // Copy parsed segment to target buffer.
            CopyBytes( StartAddress, Target, (u32) CountOfBytesParsed );
            
            return( CurrentHead+1 );
        }
    }
    return(0); /* void parsed. */
}

/*------------------------------------------------------------
| ParseDatum
|-------------------------------------------------------------
|
| PURPOSE: To extract a whitespace or comma delimited word 
|          from a 0 terminated string.
|
| DESCRIPTION: Given source string and destination buffer, 
| this procedure moves the first non-whitespace word to the 
| buffer and returns the address of the byte immediately 
| following the word.
| Returns 0 if word not found before end of string.
|
| EXAMPLE:  
|
|    NextAddress = ParseDatum( SourceBuffer, WordBuffer );
|
|    if SourceBuffer holds: <aaaaa, abdbd, adsfasdf>
|    then after ParseWord, WordBuffer will hold: <aaaaa>0
|    and the returned address will be that of the first space.
|
| NOTE:  
|
| ASSUMES: String is terminated with a 0. 
|
| HISTORY: 01.22.95 from 'ParseWord'.
------------------------------------------------------------*/
s8*
ParseDatum( s8* Source, s8* Target )
{
    s8* Scan;
    u8  b;
    
    Scan = Source;

GetNextByte: 
    
    b = *Scan;
    
    if(b == 0) return(0); // No data in string.

    if( IsWhiteSpace( b ) ||
        b == ',' )
    {
        Scan++;
        goto GetNextByte;
    }
    
CopyNextByte:

    *Target++ = (s8) b;
    Scan++;
    
    b = *Scan;
    
    if( b != Space          && 
        b != ','            && 
        b != Tab            && 
        b != LineFeed       &&
        b != CarriageReturn && 
        b != FormFeed       && 
        b != 0 )
    {
        goto CopyNextByte;
    }
    
    *Target = 0; // Add the string terminator.
    
    return( Scan ); // At byte after datum.
}   

/*------------------------------------------------------------
| ParseString
|-------------------------------------------------------------
|
| PURPOSE: To extract a delimited string from a 0 terminated 
|          string.
|
| DESCRIPTION: Given delimiter, source string and destination 
| buffer, this procedure moves the first delimited string to 
| the buffer and returns the address of the byte immediately 
| following the terminal delimiter.
| Returns 0 if terminal delimiter not found before end of 
| string.
|
| EXAMPLE: 
|
| NextAddress = ParseString( SourceBuffer, WordBuffer, '"' );
|
| if SourceBuffer holds: <aaaaa "abdbd" adsfasdf>
| then after ParseString, WordBuffer will hold: <abdbd>0
| and the returned address will be that of the space following
| the last ".
|
| NOTE: See also 'ParseBytes' in 'Bytes.c'.
|
| ASSUMES: String is terminated with a 0. 
|          Delimiter <> 0.
|
| HISTORY: 03.25.91 
|          11.02.93 simplified
|          11.10.93 parameter changed to 'u16' from 'u8'.
------------------------------------------------------------*/
s8*
ParseString( s8* Source, 
             s8* Target, 
             u32 Delimiter )
{
    s8* Scan;
    
    Scan = Source;
    
    /* Look for the first delimiter or the end of the string. */
    while( *Scan != (s8) Delimiter && *Scan != 0 )
    {
        Scan++; 
    }
    
    if( *Scan == (s8) Delimiter ) /* First delimiter found */
    {
        Scan++;
        
        while( *Scan != (s8) Delimiter && *Scan != 0 )
        {
            *Target++ = *Scan++;
        }
        
        if( *Scan == (s8) Delimiter ) /* 2nd delimiter found */
        {
            *Target = 0;
            return( Scan+1 );
        }
    }
    return(0); /* if either delimiter not found. */
}

/*------------------------------------------------------------
| ParseUnsignedInteger
|-------------------------------------------------------------
| 
| PURPOSE: To parse an unsigned decimal or hexadecimal integer 
|          from a string after skipping any white space.
|
| DESCRIPTION: 
|
|       Entry:  *x = pointer to ASCII string.
|
|       Exit:   function result = parsed number.
|               *x = pointer to first character following 
|               number in string.
| EXAMPLE: 
|
| NOTE: See also 'ConvertStringToUnsignedInteger'.
| 
| ASSUMES: 
| 
| HISTORY: 11.23.96 from 'CrackNum' of 'strutil.c' in
|                   'NewsWatcher'.
|          01.07.97 added end-of-line characters to the
|                   white-space; factored 'SkipWhiteSpace';
|                   made loop more efficient.
|          01.21.99 Revised to return unsigned rather than
|                   signed number.
|          12.23.99 Added hexadecimal handling.
------------------------------------------------------------*/
u32 
ParseUnsignedInteger( s8** S )
{   
    u32 result;
    s8* s;
    s8  c;
    u32 Base;
    
    // Default to decimal.
    Base = 10;
    
    SkipWhiteSpace( S );
    
    // Refer to the string.
    s = *S;

    // Accumulate the result.
    result = 0;

GetAByte:
    
    c = *s;
    
    // If the hex number indicator is found.
    if( c == 'x' || c == 'X' )
    {
        Base = 16;
        
        s++;
        
        goto GetAByte;
    }
    
    // If the byte is an ASCII digit.
    if( c >= '0' && c <= '9' )
    {
        result = Base * result + (c - '0');
        
        s++;
        
        goto GetAByte;
    }
    
    // If in base 16.
    if( Base == 16 )
    {
        // If the byte is a lowercase ASCII hex digit.
        if( c >= 'a' && c <= 'f' )
        {
            result = ( result << 4 ) + ( c - 'a' + 10 );
        
            s++;
            
            goto GetAByte;
        }
        
        // If the byte is a uppercase ASCII hex digit.
        if( c >= 'A' && c <= 'F' )
        {
            result = ( result << 4 ) + ( c - 'A' + 10 );
        
            s++;
            
            goto GetAByte;
        }
    }
    
    *S = s;
    
    return( result );
}

/*------------------------------------------------------------
| ParseUnsignedIntegerTof64
|-------------------------------------------------------------
| 
| PURPOSE: To parse an unsigned decimal integer from a string 
|          after skipping any white space, accumulating it as
|          a 'f64'.
|
| DESCRIPTION: Works the same way as 'ParseUnsignedInteger'
| but uses 64-bit floating point number as accumulator.  This
| allows the parsing of very large numbers of digits.
|
|       Entry:  *x = pointer to ASCII string.
|
|       Exit:   function result = parsed number.
|               *x = pointer to first character following 
|               number in string.
| EXAMPLE: 
|
| NOTE: See also 'ConvertStringToUnsignedInteger'.
| 
| ASSUMES: 
| 
| HISTORY: 01.08.97 from 'ParseUnsignedInteger'.
------------------------------------------------------------*/
f64
ParseUnsignedIntegerTof64( s8** S )
{   
    f64 result;
    s8* s;
    s8  c;
    
    SkipWhiteSpace( S );
    
    // Refer to the string.
    s = *S;

    // Accumulate the result.
    result = 0;

GetAByte:
    
    c = *s;
    
    if( c >= '0' && c <= '9' )
    {
        result = 10. * result + (f64) ( c - '0' );
        
        s++;
        
        goto GetAByte;
    }
    
    *S = s;
    
    return( result );
}

/*------------------------------------------------------------
| ParseWord
|-------------------------------------------------------------
|
| PURPOSE: To extract a whitespace delimited word from a 0 
|          terminated string.
|
| DESCRIPTION: Given source string and destination buffer, 
| this procedure moves the first non-whitespace word to the 
| buffer and returns the address of the byte immediately 
| following the word.
|
| Returns 0 if word not found before end of string.
|
| EXAMPLE:  
|
|    NextAddress = ParseWord( SourceBuffer, WordBuffer );
|
|    if SourceBuffer holds: <aaaaa "abdbd" adsfasdf>
|    then after ParseWord, WordBuffer will hold: <aaaaa>0
|    and the returned address will be that of the first space.
|
| NOTE: See also 'ParseBytes' in 'Bytes.c'.
|
| ASSUMES: String is terminated with a 0. 
|
| HISTORY: 04.06.91 
|          12.23.96 added empty string terminator for
|                   empty input string condition.
|          02.15.99 Factored out 'IsWhiteSpace' and 
|                   'IsNotWhiteSpace'; sped up.
------------------------------------------------------------*/
s8*
ParseWord( s8* Source, s8* Target )
{
    s8* Scan;
    s8  b;
    
    Scan = Source;

NextByte:

    // Get a byte and advance the character pointer.
    b = *Scan++;
    
    // If the end of the string has not been reached.
    if( b )
    {
        // If this is a white space character.
        if( IsWhiteSpace( b ) )
        {
            // Go get the next byte.
            goto NextByte;
        }
    }
    else // End of string has been reached without 
         // getting any word.
    {
        // Mark the result string as empty.
        *Target = 0;
        
        // Signal that no word was found.
        return( 0 );
    }
    
NextByteOfWord:

    // Get a byte.
    b = *Scan;
    
    // If the end of the string has not been reached.
    if( b )
    {
        // If this is a white space character.
        if( IsWhiteSpace( b ) )
        {
            // Go finish up.
            goto Finish;
        }
        else // Not whitespace.
        {
            // Copy the byte to the target.
            *Target++ = b;
            
            // Advance to the next character.
            Scan++;
            
            // Go get the next byte of the word.
            goto NextByteOfWord;
        }
    }
    
Finish:

    // Mark the end of the result string.
    *Target = 0;

    // Return the address of the first byte after the
    // word.
    return( Scan );
}   

/*------------------------------------------------------------
| ReferToString
|-------------------------------------------------------------
|
| PURPOSE: To refer to a string as a list of words.
|
| DESCRIPTION: Words are separated by white-space where
| white-space characters are any of the following:
|
|       spaces, tabs, carriage returns, line feeds
|
| The current word address is held in 'TheWord'.
|
| The white-space byte following the current word is 
| replaced with a zero so that the word can be used by
| string functions.  That byte is held in 'TheWordDelimiter'
| so that it can be restored later.
|
| Use the counterpart function 'RevertToString' to restore
| the prior string context.
|
| EXAMPLE:  
|
|       ReferToString( "a b c" );
|
|       while( TheWord )
|       {
|           printf( "%s\n", TheWord );
|
|           ToNextWord();
|       }
|
|       RevertToString();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.02.97 patterned on 'ReferToList'. 
|
------------------------------------------------------------*/
void
ReferToString( s8* s )
{
    // Make a string stack if necessary.
    if( StringStack == 0 )
    {
        StringStack = MakeStack( 50 );
    }
    
    // Preserve the current string context.
    Push( StringStack, (u32) AtTheString );
    Push( StringStack, (u32) AtTheStringEnd );
    Push( StringStack, (u32) TheWord );
    Push( StringStack, (u32) AtTheWordEnd );
    Push( StringStack, (u32) TheWordDelimiter );
    
    // Set the address of the first byte of the string.
    AtTheString = s;
    
    // Set the address of the last byte of the string, the 0
    // byte.
    AtTheStringEnd = s;
    ToStringTerminator( &AtTheStringEnd );
    
    // Set the address of the first word in the string.
    TheWord = AtTheString;
    SkipWhiteSpace( &TheWord );
    
    // If this is an empty string.
    if( TheWord == AtTheStringEnd )
    {
        // Signal no word.
        ToNoWord();
    }
    else // There is at least one word in the string.
    {
        // Set the address of the byte following the first
        // word.
        AtTheWordEnd = TheWord;
        ToWhiteSpace( &AtTheWordEnd );
        
        // Save the delimiter of the word.
        TheWordDelimiter = *AtTheWordEnd;
    
        // Temporarily replace the delimiter of the word.
        *AtTheWordEnd = 0;
    }
}

/*------------------------------------------------------------
| ReplaceRangeInBuffer
|-------------------------------------------------------------
|
| PURPOSE: To replace a given range of bytes in a buffer with
| another range of bytes.
|
| DESCRIPTION:  
|
| EXAMPLE:
|                           BufferCount=10
|   BEFORE:         ------------------------------
|                   |                            |
|        TextBuffer:[t][h][i][s][ ][i][s][ ][a][ ]
|                         |    |
|                         ---------TheRange
|                                  TheRangeCount=2
|
|        NewBytes:[x][x][x][x] 
|                 |          |
|                 --------------NewRangeCount=4 
|
|        ReplaceRangeInBuffer( TextBuffer, 
|                              BufferCount,
|                              TheRange,
|                              TheRangeCount,
|                              NewBytes,
|                              NewRangeCount);
|
|    AFTER:                   BufferCount=12
|                   ------------------------------------
|                   |                                  |
|        TextBuffer:[t][h][x][x][x][x][ ][i][s][ ][a][ ]
|                         |          |
|                         ------------
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.20.93 
------------------------------------------------------------*/
void
ReplaceRangeInBuffer( 
    u8* ABuffer,
            // The buffer containing range A.
            //
    u32 SizeOfABuffer,
            // The size of the buffer in bytes.
            //
    u8* ARange,
            // A sequence of bytes in ABuffer to be
            // replaced with the bytes from BRange.
            //
    u32 SizeOfARange,
            // Size of ARange in bytes.
            //
    u8* BRange,
            // The location of the replacement bytes.
            //
    u32 SizeOfBRange )
            // The size of the replacement section in bytes.
{
    // Make room or take up slack.
    CopyBytes( &ARange[SizeOfARange],
               &ARange[SizeOfBRange],
               (u32) (&ABuffer[SizeOfABuffer]-
                       &ARange[SizeOfARange])
             );
    
    // Copy in new bytes.   
    CopyBytes( BRange, ARange, SizeOfBRange );
}

/*------------------------------------------------------------
| ReplaceRangeInBufferAndPadSlack
|-------------------------------------------------------------
|
| PURPOSE: To replace a given range of bytes in a buffer with
| another range of bytes.  If the new range is smaller than
| the old range, fill the slack space with a given pad byte.
|
| DESCRIPTION:  
|
| EXAMPLE:
|                           BufferCount=10
|   BEFORE:         ------------------------------
|                   |                            |
|        TextBuffer:[t][h][i][s][ ][i][s][ ][a][ ]
|                         |    |
|                         ---------TheRange
|                                  TheRangeCount=2
|
|        NewBytes:[x]
|                 | |
|                 --------------NewRangeCount=1 
|
|        ReplaceRangeInBufferAndPadSlack( TextBuffer, 
|                              BufferCount,
|                              TheRange,
|                              TheRangeCount,
|                              NewBytes,
|                              NewRangeCount, ' ');
|
|    AFTER:                BufferCount=10
|                   ------------------------------
|                   |                            |
|        TextBuffer:[t][h][x][ ][ ][i][s][ ][a][ ]
|                          \  \___Pad byte
|                           \_____New byte 
|
| HISTORY: 01.20.93 
|          01.22.97 changed 'PadByte' to 'u32' from 'u16'.
------------------------------------------------------------*/
void
ReplaceRangeInBufferAndPadSlack(
                     u8* ABuffer,
                     u32 SizeOfABuffer,
                     u8* ARange,
                     u32 SizeOfARange,
                     u8* BRange,
                     u32 SizeOfBRange,
                     u32 PadByte )
{
    // Make room if needed but don't take up slack.
    if( SizeOfBRange > SizeOfARange )
    {
        CopyBytes( &ARange[SizeOfARange],
                   &ARange[SizeOfBRange],
            (u32) (&ABuffer[SizeOfABuffer]-
                   &ARange[SizeOfARange])
                 );
    }
    
    // Copy in new bytes.     
    CopyBytes( BRange, ARange, SizeOfBRange );
    
    // Pad slack if needed. 
    if( SizeOfBRange < SizeOfARange )
    {
        FillBytes( &ARange[SizeOfBRange],
                   SizeOfARange-SizeOfBRange,
                   PadByte );
    }
}

/*------------------------------------------------------------
| RevertToString
|-------------------------------------------------------------
|
| PURPOSE: To revert to the suspended string of words.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|       ReferToString( "a b c" );
|
|       while( TheWord )
|       {
|           printf( TheWord );
|
|           ToNextWord();
|       }
|
|       RevertToString();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.02.97 patterned on 'ReferToList'. 
|
------------------------------------------------------------*/
void
RevertToString()
{
    // Restore the word delimiter.
    *AtTheWordEnd = TheWordDelimiter;
    
    // Restore the prior string context.
    TheWordDelimiter = (s8)  Pull( StringStack );
    AtTheWordEnd     = (s8*) Pull( StringStack );
    TheWord          = (s8*) Pull( StringStack );
    AtTheStringEnd   = (s8*) Pull( StringStack );
    AtTheString      = (s8*) Pull( StringStack );
}

/*------------------------------------------------------------
| ScanBytesEQ
|-------------------------------------------------------------
|
| PURPOSE: To scan forward through a series of bytes to find  
|          the first byte equal to a given byte.
|
| DESCRIPTION: Given a byte zone (see NOTE), this procedure 
| scans from low memory to high memory for the first byte 
| matching a given byte pattern.  The address of the first
| byte found is returned or, if not found a 0 is returned.
|
| EXAMPLE:   
|
|      ByteFoundAt = ScanBytesEQ( Head, Tail, BytePattern );     
|
| NOTE: A zone is defined such that the first byte is pointed 
|       to by "head" and "tail" is the address of the byte 
|       immediately following the last u8 of the zone ie.
|
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*][*][*][*][*][ ][ ][ ][ ][ ][ ]
|                       ^              ^
|                       head           tail    
|
|       where:   bytes_in_zone = tail - head
|
| ASSUMES: tail is >= head.
|
| HISTORY: 03.20.92 
|          11.02.93 converted to 'C'
|          11.10.93 parameter changed to 'u16' from 'u8'.
------------------------------------------------------------*/
u8*                  
ScanBytesEQ( u8* Head, 
             u8* Tail, 
             u16           BytePattern )
{
    while( Head != Tail && *Head != BytePattern )
    {
        Head++;
    }
    
    if( Head != Tail )
    {
        return( Head );
    }
    
    return(0);
}

/*------------------------------------------------------------
| ScanBytesEQBackward
|-------------------------------------------------------------
|
| PURPOSE: To scan backward through a series of bytes to find  
|          the first byte equal to a given byte.
|
| DESCRIPTION: Given a byte zone (see NOTE), this procedure 
| scans from high memory to low memory for the first byte 
| matching a given byte pattern.  The address of the first
| byte found is returned or, if not found a 0 is returned.
|
| EXAMPLE:   
|
|  ByteFoundAt = ScanBytesEQBackward( Head, Tail, BytePattern );     
|
| NOTE: A zone is defined such that the first byte is pointed 
|       to by "head" and "tail" is the address of the byte 
|       immediately following the last u8 of the zone ie.
|
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*][*][*][*][*][ ][ ][ ][ ][ ][ ]
|                       ^              ^
|                       head           tail    
|
|       where:   bytes_in_zone = tail - head
|
| ASSUMES: tail is >= head.
|
| HISTORY: 03.20.92 
|          11.02.93 converted to 'C'
|          11.10.93 parameter changed to 'u16' from 'u8'.
------------------------------------------------------------*/
u8*                  
ScanBytesEQBackward( u8* Head, 
                     u8* Tail, 
                     u16 BytePattern )
{
    Tail--;
    
    while( Head <= Tail && *Tail != BytePattern )
    {
        Tail--;
    }
    
    if(  Head <= Tail  )
    {
        return( Tail );
    }
    
    return(0);
}

/*------------------------------------------------------------
| ScanBytesNE
|-------------------------------------------------------------
|
| PURPOSE: To scan forward through a series of bytes to find  
|          the first byte not equal to a given byte.
|
| DESCRIPTION: Given a byte zone (see NOTE), this procedure 
| scans from low memory to high memory for the first byte 
| not matching a given byte pattern.  The address of the first
| non-matching byte found is returned or, if not found a 0 
| is returned.
|
| EXAMPLE:   
|
|      ByteFoundAt = ScanBytesNE( Head, Tail, BytePattern );     
|
| NOTE: A zone is defined such that the first byte is pointed 
|       to by "head" and "tail" is the address of the byte 
|       immediately following the last u8 of the zone ie.
|
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*][*][*][*][*][ ][ ][ ][ ][ ][ ]
|                       ^              ^
|                       head           tail    
|
|       where:   bytes_in_zone = tail - head
|
| ASSUMES: tail is >= head.
|
| HISTORY: 03.20.92 
|          11.02.93 converted to 'C'
|          11.10.93 parameter changed to 'u16' from 'u8'.
------------------------------------------------------------*/
u8*                  
ScanBytesNE( u8* Head, 
             u8* Tail, 
             u16           BytePattern )
{
    while( Head != Tail && *Head == BytePattern )
    {
        Head++;
    }
    
    if( Head != Tail )
    {
        return( Head );
    }
    
    return(0);
}

/*------------------------------------------------------------
| ScanToDigit
|-------------------------------------------------------------
|
| PURPOSE: To scan through a series of bytes to find  
|          the first ASCII digit.
|
| DESCRIPTION: Given a byte zone (see NOTE), this procedure 
| scans from low memory to high memory for the first ASCII
| digit.  The address of the first byte found is returned or, 
| if not found a 0 is returned.
|
| EXAMPLE:   
|
|  ByteFoundAt = ScanToDigit( Head, Tail );     
|
| NOTE: A zone is range of bytes located at a base
|       address called 'head' and extending to but 
|       not including another address called 'tail'.
|
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*][*][*][*][*][ ][ ][ ][ ][ ][ ]
|                       ^              ^
|                       head           tail    
|
|       where:   bytes_in_zone = tail - head
|
| ASSUMES: tail is >= head.
|
| HISTORY: 12.24.96 from 'ScanBytesEQBackward'.
------------------------------------------------------------*/
u8*                  
ScanToDigit( u8* Head, u8* Tail )
{
    while( Head < Tail && !IsDigit( *Head ) )
    {
        Head++;
    }
    
    if(  Head < Tail  )
    {
        return( Head );
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| ScanToDigitBackward
|-------------------------------------------------------------
|
| PURPOSE: To scan backward through a series of bytes to find  
|          the first ASCII digit.
|
| DESCRIPTION: Given a byte zone (see NOTE), this procedure 
| scans from high memory to low memory for the first ASCII
| digit.  The address of the first byte found is returned or, 
| if not found a 0 is returned.
|
| EXAMPLE:   
|
|  ByteFoundAt = ScanToDigitBackward( Head, Tail );     
|
| NOTE: A zone is range of bytes located at a base
|       address called 'head' and extending to but 
|       not including another address called 'tail'.
|
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*][*][*][*][*][ ][ ][ ][ ][ ][ ]
|                       ^              ^
|                       head           tail    
|
|       where:   bytes_in_zone = tail - head
|
| ASSUMES: tail is >= head.
|
| HISTORY: 12.24.96 from 'ScanBytesEQBackward'.
------------------------------------------------------------*/
u8*                  
ScanToDigitBackward( u8* Head, u8* Tail )
{
    Tail--;
    
    while( Head <= Tail && !IsDigit( *Tail ) )
    {
        Tail--;
    }
    
    if(  Head <= Tail  )
    {
        return( Tail );
    }
    
    return(0);
}

/*------------------------------------------------------------
| ScanForNonDigitOrPeriodBackward
|-------------------------------------------------------------
|
| PURPOSE: To scan backward through a series of bytes to find  
|          the first byte that is neither an ASCII digit or
|          an ASCII period.
|
| DESCRIPTION: Given a byte zone (see NOTE), this procedure 
| scans from high memory to low memory.
|  
| The address of the first byte found is returned or, if not 
| found a 0 is returned.
|
| EXAMPLE:   
|
|  ByteFoundAt = ScanForNonDigitOrPeriodBackward( Head, Tail );     
|
| NOTE: A zone is range of bytes located at a base
|       address called 'head' and extending to but 
|       not including another address called 'tail'.
|
|        (low mem)     |<----zone--->|      (high mem)
|       [ ][ ][ ][ ][ ][*][*][*][*][*][ ][ ][ ][ ][ ][ ]
|                       ^              ^
|                       head           tail    
|
|       where:   bytes_in_zone = tail - head
|
| ASSUMES: tail is >= head.
|
| HISTORY: 12.24.96 from 'ScanToDigitBackward'.
------------------------------------------------------------*/
u8*                  
ScanForNonDigitOrPeriodBackward( u8* Head, u8* Tail )
{
    Tail--;
    
    while( Head <= Tail && 
           ( IsDigit( *Tail ) || *Tail == '.' ) )
    {
        Tail--;
    }
    
    if( Head <= Tail )
    {
        return( Tail );
    }
    
    return(0);
}

/*------------------------------------------------------------
| SkipWhiteSpace
|-------------------------------------------------------------
|
| PURPOSE: To advance a parsing cursor past white space 
|          characters.
|
| DESCRIPTION: White space characters are any of the following:
|
|              spaces, tabs, carriage returns, line feeds
|
| EXAMPLE:  SkipWhiteSpace(&At);
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 12.25.96
------------------------------------------------------------*/
void
SkipWhiteSpace( s8** Here )
{
    s8* At;
    s8  c;
    
    At = *Here;

GetAByte:
    
    c = *At;
    
    if( IsWhiteSpace( c ) )  
    {
        At++;
        
        goto GetAByte;
    }
    
    *Here = At;
}

/*------------------------------------------------------------
| SkipWhiteSpaceBackward
|-------------------------------------------------------------
|
| PURPOSE: To move a parsing cursor backward past white space 
|          characters.
|
| DESCRIPTION: White space characters are any of the 
| following:
|
|           spaces, tabs, carriage returns, line feeds
|
| EXAMPLE:  SkipWhiteSpaceBackward(&At);
|
| HISTORY: 08.25.01 From SkipWhiteSpace().
------------------------------------------------------------*/
void
SkipWhiteSpaceBackward( s8** Here )
{
    s8* At;
    s8  c;
    
    At = *Here;

GetAByte:
    
    c = *At;
    
    if( IsWhiteSpace( c ) )  
    {
        At--;
        
        goto GetAByte;
    }
    
    *Here = At;
}

/*------------------------------------------------------------
| SkipWord
|-------------------------------------------------------------
|
| PURPOSE: To advance a parsing cursor past any white space 
|          bytes and one contiguous set of non-white bytes.
|
| DESCRIPTION: White space characters are any of the following:
|
|              spaces, tabs, carriage returns, line feeds
|
| A zero byte terminates scan.
|
| EXAMPLE:  SkipWord(&At);
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 12.25.96
------------------------------------------------------------*/
void
SkipWord( s8** Here )
{
    // If at white space, skip it.
    SkipWhiteSpace( Here );
    
    // Skip forward to next whitespace.
    ToWhiteSpace( Here );
}

/*------------------------------------------------------------
| SplitNameAndValue
|-------------------------------------------------------------
|
| PURPOSE: To separate a name:value pair connected by a 
|          delimiter, eg. "X=2".
|
| DESCRIPTION: 
|
| EXAMPLE:  SplitNameAndValue( "X=2", 
|                              Name, 
|                              '=', 
|                              Value ); 
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 03.01.97
------------------------------------------------------------*/
void
SplitNameAndValue( s8* NameAndValue, 
                   s8* Name, 
                   u32 Delimiter, 
                   s8* Value ) 
{
    s32 NameByteCount;
    
    // Copy the name part.
    NameByteCount =
            CopyBytesUntilDelimiter( (u8*) NameAndValue, 
                                     (u8*) Name, 
                                     Delimiter );

    // Append string terminator to name string.
    Name[ NameByteCount ] = 0;
    
    // Copy the remainder of the string to the value buffer.
    CopyString( &NameAndValue[ NameByteCount + 1 ],
                Value );
} 

/*------------------------------------------------------------
| StripByteFromString
|-------------------------------------------------------------
|
| PURPOSE: To strip every occurance of a given byte from a
|          0 terminated string.
|
| DESCRIPTION: White space characters are any of the following:
|
|              spaces, tabs, carriage returns, line feeds
|
| EXAMPLE:  StripByteFromString( "abab", 'b' );
|
|           --> "aa"
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 12.25.96 from 'StripLeadingWhiteSpace'.
------------------------------------------------------------*/
void
StripByteFromString( s8* S, u32 AByte )
{
    while( *S )
    {
        if( *S == (s8) AByte )
        {
            CopyString( &S[1], S );
        }
        
        S++;
    }
}

/*------------------------------------------------------------
| StripLeadingWhiteSpace
|-------------------------------------------------------------
|
| PURPOSE: To strip "white space" characters (defined below) 
| from the beginning of a 0 terminated string.
|
| DESCRIPTION: White space characters are any of the following:
|
|    spaces, tabs, carriage returns, line feeds, form feeds
|
| EXAMPLE:  StripLeadingWhiteSpace(MyInputBuffer);
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 03.25.91
|          02.15.99 Added form feed. 
------------------------------------------------------------*/
void
StripLeadingWhiteSpace( s8* Buffer )
{
    s8* Scan;
    
    Scan = Buffer;
    
    while( *Scan != 0 && IsWhiteSpace( *Scan ) )
    {
        Scan++;
    }
    
    if( Scan != Buffer )
    {
        CopyString( Scan, Buffer );
    }
}

/*------------------------------------------------------------
| StripTrailingWhiteSpace
|-------------------------------------------------------------
|
| PURPOSE: To strip "white space" characters (defined below) 
|          from the end of a 0 terminated string.
|
| DESCRIPTION: White space characters are any of the 
| following:
|
|           spaces, tabs, carriage returns, line feeds
|
| EXAMPLE:  StripTrailingWhiteSpace(MyInputBuffer);
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 03.25.91
|          03.07.97 revised to handle empty string case.
------------------------------------------------------------*/
void
StripTrailingWhiteSpace( s8* Buffer )
{
    s8* A;
    s8  a;
    
    A = AddressOfLastCharacterInString( Buffer );

Another:

    // Get the last character in the string.
    a = *A;
    
    // If the character is a whitespace character then
    // replace it with a zero.
    if( IsWhiteSpace( a ) ) 
    {
        *A = 0;
    }
    else // Not whitespace, so return.
    {
        return;
    }
    
    // If the beginning of the string hasn't been reached,
    // try another character.
    if( A > Buffer )
    {
        A--;
    
        goto Another;
    }
}

/*------------------------------------------------------------
| ToFirstWord
|-------------------------------------------------------------
|
| PURPOSE: To refer to the first word in the current string.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|       ReferToString( "a b c" );
|
|       while( TheWord )
|       {
|           printf( TheWord );
|
|           ToNextWord();
|       }
|
|       ToFirstWord(); ...
|
|       RevertToString();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.02.97 patterned on 'ReferToList'. 
|
------------------------------------------------------------*/
void
ToFirstWord()
{
    // Restore the delimiter of the current word.
    *AtTheWordEnd = TheWordDelimiter;
    
    // Set the address of the first word in the string.
    TheWord = AtTheString;
    SkipWhiteSpace( &TheWord );
    
    // If this is an empty string.
    if( TheWord == AtTheStringEnd )
    {
        // Signal no word.
        TheWord = 0;
        AtTheWordEnd = AtTheStringEnd;
    }
    else // There is at least one word in the string.
    {
        // Set the address of the byte following the first
        // word.
        AtTheWordEnd = TheWord;
        ToWhiteSpace( &AtTheWordEnd );
    }

    // Save the delimiter of the word.
    TheWordDelimiter = *AtTheWordEnd;
    
    // Temporarily replace the delimiter of the word.
    *AtTheWordEnd = 0;
}   

/*------------------------------------------------------------
| ToLastWord
|-------------------------------------------------------------
|
| PURPOSE: To refer to the last word in the current string.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|       ReferToString( "a b c" );
|
|       ToLastWord(); 
|
|       printf(TheWord);
|
|       RevertToString();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.02.97 patterned on 'ReferToList'. 
|
------------------------------------------------------------*/
void
ToLastWord()
{
    s8 c;
    
    // Restore the delimiter of the current word.
    *AtTheWordEnd = TheWordDelimiter;
    
    // Begin search for the end of the last word.
    AtTheWordEnd = AtTheStringEnd;
    
ScanBack:
    
    // No word was found.
    if( AtTheWordEnd == AtTheString )
    {
        // Signal no word.
        TheWord = 0;
        AtTheWordEnd = AtTheStringEnd;
        TheWordDelimiter = 0;
        return;
    }
    
    // Back up one byte.
    AtTheWordEnd--;
    
    // Get the byte.
    c = *AtTheWordEnd;
    
    // Is it white?
    if( IsWhiteSpace( c ) )  
    {
        goto ScanBack;
    }

    // Found a word.
    TheWord = AtTheWordEnd;

    // Correct for overshoot.
    AtTheWordEnd++;
    
    // Preserve the delimiter.
    TheWordDelimiter = *AtTheWordEnd;
    
    // Mark the end of the word with a string terminator.
    *AtTheWordEnd = 0;
    
    // Search back for the first whitespace or the
    // beginning of the string, which ever comes first.
    
ScanBack2:

    if( TheWord == AtTheString )        
    {
        return;
    }
    
    // Back up one byte.
    TheWord--;
    
    // Get the byte.
    c = *AtTheWordEnd;
    
    // Is it white?
    if( IsWhiteSpace( c ) )  
    {
        // Correct for overshoot.
        TheWord++;
        return;
    }

    goto ScanBack2;
}

/*------------------------------------------------------------
| ToNextLine
|-------------------------------------------------------------
|
| PURPOSE: To move a parsing cursor forward to the first byte 
|          in the next line.
|
| DESCRIPTION: Scans forward looking for any newline 
| character(s) and returns the address of the following byte.
|
| If the newline is <CR><LF>, then the <LF> is skipped.
|
| EXAMPLE:  
|
|      ToNextLine( &Here );
|
| NOTES:  
|
| ASSUMES: There is a next line.
|
| HISTORY: 06.27.97
------------------------------------------------------------*/
void
ToNextLine( s8** Here )
{
    s8* A;
    s8  c;
    
    A = *Here;
    
    // Advance to the first new line character.
Again:

    // Step forward one byte.
    A++;
    
    // Get the value of the byte.
    c = *A;
    
    // If the byte isn't a newline.
    if( c != LineFeed && c != CarriageReturn )
    {
        goto Again;
    }
    
    // Found a new line. Move to the next byte.
    A++;
    
    // If the next byte is a LineFeed, skip it.
    if( *A == LineFeed )
    {
        A++;
    }
    
    // Return the address following the newline.
    *Here = A;
}              

/*------------------------------------------------------------
| ToNextWord
|-------------------------------------------------------------
|
| PURPOSE: To refer to the next word in the current string.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|       ReferToString( "a b c" );
|
|       while( TheWord )
|       {
|           printf(TheWord);
|
|           ToNextWord();
|       }
|
|       ToFirstWord(); ...
|
|       RevertToString();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.02.97 patterned on 'ReferToList'. 
|
------------------------------------------------------------*/
void
ToNextWord()
{
    // Restore the delimiter of the current word.
    *AtTheWordEnd = TheWordDelimiter;
    
    // Set the address of the next word in the string.
    TheWord = AtTheWordEnd;
    SkipWhiteSpace( &TheWord );
    
    // Signal no word if none found.
    if( TheWord == AtTheStringEnd )
    {
        ToNoWord();
    }
    else // A word was found before the end of the string.
    {
        // Set the address of the byte following the first
        // in the word.
        AtTheWordEnd = TheWord + 1;

        // Find the end of the word.
        ToWhiteSpace( &AtTheWordEnd );
    
        // Save the delimiter of the word.
        TheWordDelimiter = *AtTheWordEnd;
    
        // Temporarily replace the delimiter of the word.
        *AtTheWordEnd = 0;
    }
}

/*------------------------------------------------------------
| ToNoWord
|-------------------------------------------------------------
|
| PURPOSE: To signal that no word is referenced in the current 
|          string.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.03.97 
------------------------------------------------------------*/
void
ToNoWord()
{
    TheWord = 0;
    AtTheWordEnd = AtTheStringEnd;
    TheWordDelimiter = 0;
}

/*------------------------------------------------------------
| ToPriorWord
|-------------------------------------------------------------
|
| PURPOSE: To refer to the prior word in the current string.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|       ReferToString( "a b c" );
|
|       ToLastWord(); 
|
|       ToPriorWord();
| 
|       printf(TheWord);
|
|       RevertToString();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.02.97 patterned on 'ReferToList'. 
|
------------------------------------------------------------*/
void
ToPriorWord()
{
    s8 c;
    
    // Restore the delimiter of the current word.
    *AtTheWordEnd = TheWordDelimiter;

    // If already at the first word and that word is start
    // of the string.
    if( TheWord == AtTheString )
    {
        // Signal no word.
        ToNoWord();
        
        return;
    }
    
    // Scan back to a non-whitespace still in the string.
ScanBack:

    TheWord--;
    
    c = *TheWord;
        
    // Is this white?
    if( IsWhiteSpace( c ) )  
    {
        // If the beginning of the string was reached, then 
        // there is no prior word.
        if( TheWord == AtTheString )
        {
            ToNoWord();
        
            return;
        }
        else
        {
            // Keep traveling through the white.
            goto ScanBack;
        }
    }
    
    // Not white.  
    
    // Make the end of the word the point found.
    AtTheWordEnd = TheWord + 1;
    
    // Save the delimiter.
    TheWordDelimiter = *AtTheWordEnd;
    
    // Mark the end of the word.
    *AtTheWordEnd = 0;
    
    // Now search for the beginning of the word.
ScanBack2:

    TheWord--;
    
    // If the beginning of the string was reached, then the
    // first word is the current word.
    if( TheWord == AtTheString )
    {
        return;
    }
            
    c = *TheWord;
        
    // Is this white?
    if( IsWhiteSpace( c ) )  
    {
        // Correct for overshoot.
        TheWord++;
        
        return;
    }

    goto ScanBack2;
}

/*------------------------------------------------------------
| ToStartOfLine
|-------------------------------------------------------------
|
| PURPOSE: To move a parsing cursor back to the first byte 
|          in the current line.
|
| DESCRIPTION: Scans backward looking for any newline 
| character and returns the address of the following byte.
|
| EXAMPLE:  
|
|      ToStartOfLine( &Here );
|
| NOTES:  
|
| ASSUMES: There is a prior line.
|
| HISTORY: 06.27.97
------------------------------------------------------------*/
void
ToStartOfLine( s8** Here )
{
    s8* A;
    s8  c;
    
    A = *Here;

Again:

    // Step back one byte.
    A--;
    
    // Get the value of the byte.
    c = *A;
    
    // If the byte isn't a newline.
    if( c != LineFeed && c != CarriageReturn )
    {
        goto Again;
    }
    
    // Return the address following the newline.
    *Here = A + 1;
}              

/*------------------------------------------------------------
| ToStringTerminator
|-------------------------------------------------------------
|
| PURPOSE: To advance a parsing cursor to the terminating zero
|          of a string.
|
| DESCRIPTION:  
|
| EXAMPLE:  ToStringTerminator(&At);
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 01.03.97 from 'ToWhiteSpace'.
------------------------------------------------------------*/
void
ToStringTerminator( s8** Here )
{
    s8* At;
    
    At = *Here;
    
    while( *At )
    {
        At++;
    }
 
    *Here = At;
}

/*------------------------------------------------------------
| ToWhiteSpace
|-------------------------------------------------------------
|
| PURPOSE: To advance a parsing cursor to the first white space 
|          byte.
|
| DESCRIPTION: White space characters are any of the following:
|
|              spaces, tabs, carriage returns, line feeds
|
| A zero byte terminates scan.
|
| EXAMPLE:  ToWhiteSpace(&At);
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 12.25.96
------------------------------------------------------------*/
void
ToWhiteSpace( s8** Here )
{
    s8* At;
    s8  c;
    
    At = *Here;
    
GetAByte:
    
    c = *At;
    
    // Is it end of string?
    if( c == 0 )
    {
        goto Done;
    }
    
    // Is it white?
    if( IsWhiteSpace( c ) )  
    {
        // Found white: done.
        goto Done;
    }
    else // Non-white, so try next byte.
    {
        At++;
        
        goto GetAByte;
    }

Done:

    *Here = At;
}

/*------------------------------------------------------------
| ValueOfNthItemInCommaDelimitedString
|-------------------------------------------------------------
|
| PURPOSE: To get the value of the nth field in a comma-
|          delimited string.
|
| DESCRIPTION: The first field is referred as field 0, the
| next as field 1, and so on. 
|
| EXAMPLE:  
|
|     x = ValueOfNthItemInCommaDelimitedString( 2, "a,b,c" );
|
| results in x = "c".
|
| NOTES:  
|
| ASSUMES: Result string is less than 256 bytes long.
| 
|          Result will be copied elsewhere if it is to be
|          preserved.
|
| HISTORY: 03.01.97
------------------------------------------------------------*/
s8*
ValueOfNthItemInCommaDelimitedString( u32 n, s8* S )
{
    static s8   Result[256];
    s8* Target;
    s8* Source;
    
    // Locate the field value.
    Source = LocationOfNthItemInCommaDelimitedString( n, S );
    
    Target = (s8*) &Result[0];
    
    // Copy the value to the result buffer.
    while( Source && *Source && *Source != ',' )
    {
        *Target++ = *Source++;
    }
    
    // Append a string delimiter.
    *Target = 0;
    
    // Return the result.
    return( Result );
}

