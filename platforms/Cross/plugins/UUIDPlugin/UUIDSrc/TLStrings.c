/*------------------------------------------------------------
| TLStrings.c
|-------------------------------------------------------------
|
| PURPOSE: To provide string manipulation functions.
|
| NOTE: See 'DynString.c' for dynamically allocated string 
|       functions.
|
|       See 'Parse.c' for string parsing functions.
|
| HISTORY: 02.03.93 from xstrings.c.
|          11.08.93 moved parsing functions to 'Parse.c'
|          01.12.94 added #include <Ascii.h> replacing ctype.h
|          01.13.94 added ConvertIntegerToString, ReverseString
------------------------------------------------------------*/

#include "TLTarget.h"  

#ifndef FOR_DRIVER
#include <string.h>
#include <stdlib.h> // for atoi, atol 
#endif

#include "NumTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"

#include "TLStrings.h"

/*------------------------------------------------------------
| AddressOfLastCharacterInString
|-------------------------------------------------------------
|
| PURPOSE: To find the address of the last character in a 
|          string, or the place where the last character 
|          should be if the string is empty.
|
| DESCRIPTION: Returns the address of the byte immediately
| prior to the terminating 0 byte if there are characters in
| the string.
|
| Empty strings return the address of the string terminator.
|
| EXAMPLE:  
|          A = AddressOfLastCharacterInString(AString);
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|          Characters are single bytes.
|
| HISTORY: 02.01.89 
|          03.08.97 changed name from 'FindLastByteInString';
|                   changed handling of empty string case.
------------------------------------------------------------*/
s8*
AddressOfLastCharacterInString( s8* A )
{
    s8* B;
    
    B = A;
    
    while( *B ) B++;

    if( B > A )
    {
        B--;
    }

    return( B );
}

/*------------------------------------------------------------
| AppendString2
|-------------------------------------------------------------
|
| PURPOSE: To append a string to another.
|
| DESCRIPTION: 
|
| EXAMPLE:  AppendString2( AString, SuffixString );
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 02.01.89 TL 
|          10.06.97 name changed from 'AppendString' to fix
|                   collision with other symbol.
|          05.25.01 Replaced CountString by advancing AString.
|          06.01.01 Fixed error in string advance, failed to
|                   fetch byte in while() test.
------------------------------------------------------------*/
void
AppendString2( s8* AString, s8* SuffixString )
{
    // While not at the end of the first string.
    while( *AString )
    {
        // Advance the character pointer.
        AString++;
    }

    // Copy the the suffix to the end of the first string.
    CopyString( SuffixString, AString );
}

/*------------------------------------------------------------
| AppendStrings
|-------------------------------------------------------------
|
| PURPOSE: To append a variable number of strings together.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|     String  ABuffer[255];        
|                                  
|     CopyString( "This", ABuffer );
|                                  
|     AppendStrings( ABuffer,  <-- destination string
|                    " is",    <-- AddressOf suffix string
|                    " a",     <-- AddressOf suffix string
|                    " test.", <-- AddressOf suffix string
|                    (s8*) 0 ); <-- 0 terminates parameter list
|                                 
|                                  
|       yields: "This is a test."
|
|
| NOTE: The terminating 0 parameter must be cast as 
|       's8*' to prevent errors.
|
| ASSUMES: String is terminated with a 0.
|          Destination buffer is large enough to hold result.
|          Parameters are compiled in 
|              left-to-right:low-to-high-memory order.
|
| HISTORY: 12.06.89 by  from source by Jack A. Zucker
------------------------------------------------------------*/
void
AppendStrings( s8* AString, 
               s8* SuffixString, ... ) 
{
   s8**  ParameterPointer;

   ParameterPointer = &SuffixString;

   while( *ParameterPointer )
   {
       AppendString2( AString, *ParameterPointer );
       ParameterPointer++;
   }
}

/*------------------------------------------------------------
| AppendUnicodeString
|-------------------------------------------------------------
|
| PURPOSE: To append a Unicode string to another.
|
| DESCRIPTION: 
|
| EXAMPLE:  AppendUnicodeString( AString, SuffixString );
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 05.25.01 From AppendString2.
------------------------------------------------------------*/
void
AppendUnicodeString( u16* AString, u16* SuffixString )
{
    // While not at the end of the first string.
    while( AString )
    {
        // Advance the character pointer.
        AString++;
    }
    
    // Copy the the suffix to the end of the first string.
    CopyUnicodeString( AString, SuffixString );
}

/*------------------------------------------------------------
| CompareStrings
|-------------------------------------------------------------
|
| PURPOSE: To compare two strings based on their ordering in 
|          the alphabet, independent of upper/lower case.
|
| DESCRIPTION: Comparison operation.
|              Returns: 0 if string AA = string BB.
|                       positive number if AA > BB.
|                       negative number if AA < BB.
|
| Compared until end of either string or until an in-equality 
| is detected.
|
| EXAMPLE:  Result = CompareStrings( Name, "Edison" );
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY:  01.11.89 
|           04.04.91 removed case sensitive comparison
|           11.11.93 changed name from 
|                    'CompareStringsLexigraphic'
|           01.12.94 changed tolower() to 
|                    ConvertLetterToUpperCase.
|                    
------------------------------------------------------------*/
s32
CompareStrings( s8* A, s8* B )
{
    s32  Result;
    s16  AByte;
    s16  BByte;
    
    while(1)
    {
        AByte = (s16) ConvertLetterToUpperCase(*A);
        BByte = (s16) ConvertLetterToUpperCase(*B);
        
        Result = (s32) (AByte - BByte);
        
        // Return if unequal or end of either string.
        
        if( Result || AByte == 0 || BByte == 0)
        {
            return( Result );   
        }
        
        A++;
        B++;
    }
}

/*------------------------------------------------------------
| CompareStringsCaseSensitive
|-------------------------------------------------------------
|
| PURPOSE: To compare two strings based on their ordering in 
|          the ASCII code.
|
| DESCRIPTION: Comparison operation.
|              Returns: 0 if string AA = string BB.
|                       positive number if AA > BB.
|                       negative number if AA < BB.
|
| Compared until end of either string or until an in-equality 
| is detected.
|
| EXAMPLE: 
|
|  Result = CompareStringsCaseSensitive( Name, "Edison" );
|
| NOTE: 
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY:  12.09.93 from 'CompareStrings'
|           01.12.94 added AByte,BByte
|           05.18.01 from TLStrings.c, changed size of working
|                    variables for bytes from s16 to s8 and 
|                    revised comments.
------------------------------------------------------------*/
s32
CompareStringsCaseSensitive( s8* A, s8* B )
{
    s32 Result;
    s8  AByte;
    s8  BByte;
    
    // Until the ordering of the strings has been determined.
    while(1)
    {
        // Get the next byte from string A.
        AByte = *A++;
        
        // Get the next byte from string B.
        BByte = *B++;
        
        // Calculate the relationship between the two bytes.
        Result = (s32) (AByte - BByte);
        
        // If the bytes differ or the end of the string has
        // been reached.
        if( Result || AByte == 0 || BByte == 0 )
        {
            // Return the result of the last comparison which
            // determines the relative ordering of the 
            // strings.
            return( Result );   
        }
    }
}

/*------------------------------------------------------------
| ConvertStringToLowerCase
|-------------------------------------------------------------
|
| PURPOSE: To convert a string in place to lower case.
|
| DESCRIPTION: 
|
| EXAMPLE:  ConvertStringToLowerCase( AString );
|
| NOTE: Untested.
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 03.25.91 by  
|          11.11.93 fixed 'isupper' error
|          01.12.94 replaced tolower
------------------------------------------------------------*/
void
ConvertStringToLowerCase( s8* AString )
{
    u16 AByte;
    
NextByte:

    AByte = (u16) *AString;
    
    if( AByte == 0 ) return;
    
    if( AByte >= 'A' && AByte <= 'Z' )
    {
        *AString = (s8) ( AByte + 32 );
    }

    AString++;
    
    goto NextByte;
}

/*------------------------------------------------------------
| ConvertStringToUpperCase
|-------------------------------------------------------------
|
| PURPOSE: To convert a string in place to upper case.
|
| DESCRIPTION: 
|
| EXAMPLE:  ConvertStringToUpperCase( AString );
|
| NOTE: Untested.
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 03.22.89  
|          01.12.94 replaced toupper
------------------------------------------------------------*/
void
ConvertStringToUpperCase( s8* AString )
{
    u16 AByte;
    
NextByte:

    AByte = (u16) *AString;
    
    if( AByte == 0 ) return;
    
    if( AByte >= 'a' && AByte <= 'z' )
    {
        *AString = (s8) ( AByte - 32 );
    }

    AString++;
    
    goto NextByte;
}

/*------------------------------------------------------------
| Convertu64ToString
|-------------------------------------------------------------
|
| PURPOSE: To produce an ASCII string equivalent to an
|          unsigned 64-bit binary integer.
|
| DESCRIPTION: Returns the number of bytes in the result not 
| counting the terminating 0.
|
| EXAMPLE: 
|
|      ByteCount = Convertu64ToString( (u64) 123, MyString );
|
| On output:
|
| in MyString: ['1']['2']['3'][0]
|
| in ByteCount: 3
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 01.13.94 copied from 'The C Programming
|                   Language, 2nd Ed.' p. 64
|                   p. 93.
|          01.07.97 minor cleanup.
|          05.06.97 fixed error for negative values.
|          02.07.00 From 'ConvertIntegerToString()'.
------------------------------------------------------------*/
u32
Convertu64ToString( u64 n, s8* s )
{
    u32 i;
    
    i = 0;
    
NextDigit:

    s[i++] = (s8) (n % 10 + '0'); // get next digit
    
    n /= 10;
    
    if( n > 0 ) goto NextDigit;
    
    s[i] = 0; // add end-of-string
    
    // Reverse the order of the digits.
    ReverseString( s );
    
    // Return the string length.
    return( i );
}

/*------------------------------------------------------------
| CopyCToPascalString
|-------------------------------------------------------------
|
| PURPOSE: To copy a C string from one place to another, 
|          converting it to Pascal format in the process.
|
| DESCRIPTION: 
|
| EXAMPLE:  CopyCToPascalString( ACString, APString );
|
| NOTE:  
|
| ASSUMES: String is not more than 255 bytes long.
|          Source and destination strings don't overlap.
|
| HISTORY: 03.22.98 from '__ctopstring'.
------------------------------------------------------------*/
void
CopyCToPascalString( s8* c, s8* p )
{
    s32 ByteCount; 
    s8* P;
    s8  b;

    // Refer to the first destination address.
    P = p + 1;
    
    // Keep a count of the bytes copied.
    ByteCount = 0;
    
TopOfLoop:

    // Get a byte from the source.
    b = *c++;
    
    // If this byte is in the string, being non-zero.
    if( b )
    {
        // Copy the byte to the target.
        *P++ = b;
        
        // Account for the new byte.
        ByteCount++;
        
        // Get the next one.
        goto TopOfLoop;
    }
        
    // Save the byte count prefix.
    *p = (s8) ByteCount;
}

/*------------------------------------------------------------
| CopyPascalToCString
|-------------------------------------------------------------
|
| PURPOSE: To copy a Pascal string from one place to another, 
|          converting it to C-string format in the process.
|
| DESCRIPTION: 
|
| EXAMPLE:  CopyPascalToCString( APString, ACString );
|
| NOTE:  
|
| ASSUMES: String is not more than 255 bytes long.
|          Source and destination strings don't overlap.
|
| HISTORY: 09.25.98 from 'CopyCToPascalString'.
------------------------------------------------------------*/
void
CopyPascalToCString( s8* p, s8* c )
{
    u8  ByteCount; 

    // Get the byte count of the string.
    ByteCount = (u8) *p++;
    
    // For each byte in the string.
    while( ByteCount-- )
    {
        // Copy the byte to the C string buffer.
        *c++ = *p++;
    }
    
    // Append the zero-terminator.
    *c = 0;
}

/*------------------------------------------------------------
| CopyString
|-------------------------------------------------------------
|
| PURPOSE: To copy a zero-terminated string from one place 
|          to another.
|
| DESCRIPTION: 
|
| EXAMPLE:  CopyString( FromString, ToBuffer );
|
| NOTE: The parameter order for this procedure is just the
|       opposite of that used by strcpy().
|
| ASSUMES: Source and Destination buffers are non-overlapping 
|          or Destination is lower in memory than Source.
|
| HISTORY: 11.14.89  
|          02.15.93 changed to quad count.
|          11.01.93 return value removed; now buffers must
|                   not overlap.
|          05.18.01 From TLStrings.c and revised comments.
------------------------------------------------------------*/
void
CopyString( s8* Source, s8* Destination )
{
    // Until the end of the source string.
    while( *Source != 0 )
    {
        // Copy a byte from the source to the destination.
        *Destination++ = *Source++;
    }
    
    // Add the string terminator to the destination string.
    *Destination = 0;
}

/*------------------------------------------------------------
| CopyStringToUnicodeString
|-------------------------------------------------------------
|
| PURPOSE: To copy a zero-terminated ASCII string from one 
|          place to another, expanding from 1 to 2 bytes in
|          the process.
|
| DESCRIPTION: 
|
| EXAMPLE:  CopyStringToUnicodeString( 
|                FromString, ToUnicodeBuffer );
|
| NOTE: The parameter order for this procedure is just the
|       opposite of that used by strcpy().
|
| ASSUMES: Source and Destination buffers are non-overlapping.
|
|          Source string is ASCII.
|
| HISTORY: 05.30.01 From CopyString().
------------------------------------------------------------*/
void
CopyStringToUnicodeString( s8* Source, u16* Destination )
{
    // Until the end of the source string.
    while( *Source )
    {
        // Copy a byte from the source to the destination.
        *Destination++ = (u16) ( *Source++ );
    }
    
    // Add the string terminator to the destination string.
    *Destination = 0;
}

/*------------------------------------------------------------
| CopyUnicodeString
|-------------------------------------------------------------
|
| PURPOSE: To copy a zero-terminated Unicode string from one 
|          place to another.
|
| DESCRIPTION: 
|
| EXAMPLE:  CopyUnicodeString( FromString, ToBuffer );
|
| ASSUMES: Source and Destination buffers are non-overlapping 
|          or Destination is lower in memory than Source.
|
| HISTORY: 11.14.89  
|          02.15.93 changed to quad count.
|          11.01.93 return value removed; now buffers must
|                   not overlap.
|          05.18.01 From TLStrings.c and revised comments.
------------------------------------------------------------*/
void
CopyUnicodeString( u16* Source, u16* Destination )
{
    // Until the end of the source string.
    while( *Source != 0 )
    {
        // Copy a byte from the source to the destination.
        *Destination++ = *Source++;
    }
    
    // Add the string terminator to the destination string.
    *Destination = 0;
}

/*------------------------------------------------------------
| CountString
|-------------------------------------------------------------
|
| PURPOSE: To count the data bytes in a 0-terminated string. 
|
| DESCRIPTION: Terminating 0 is not included in the count.
|
| EXAMPLE:  ByteCount = CountString( MyString );
|
| HISTORY: 08.31.89 
|          02.15.93 changed to return u32 instead of u16.
|          01.01.96 chaged to use pointer instead of indexed
|                   array.
------------------------------------------------------------*/
u32
CountString( s8* AString )
{
    u32 ByteCount;

    ByteCount = 0;

    while( *AString++ )
    {
        ByteCount++;
    }
    
    return( ByteCount );
}

/*------------------------------------------------------------
| CountStringMB
|-------------------------------------------------------------
|
| PURPOSE: To count the characters in a 0-terminated string
|          that holds either one or two byte characters.
|
| DESCRIPTION:  Terminating 0 is not included in the count
| returned by this routine.
|
| EXAMPLE:  ByteCount = CountStringMB( MyString, 2 );
|
| NOTE: The 'MB' suffix stands for 'MultiByte'.
|
| ASSUMES: 
|
| HISTORY: 01.31.99 From 'CountString()'.
------------------------------------------------------------*/
u32
CountStringMB( u8* AString, u32 BytesPerChar )
{
    u32  ByteCount;
    u16* UString;

    // Start with no characters counted.
    ByteCount = 0;

    // If this is a single-byte string.
    if( BytesPerChar == 1 )
    {
        // Until a zero byte is found.
        while( *AString++ )
        {
            // Account for the character found.
            ByteCount++;
        }
    }
    else // Two bytes per character.
    {
        // Refer to the string as a string of 16-bit
        // integers.
        UString = (u16*) AString;
        
        // Until a zero u16 is found.
        while( *UString++ )
        {
            // Account for the character found.
            ByteCount++;
        }
    }
    
    // Return the resulting count.
    return( ByteCount );
}

/*------------------------------------------------------------
| CountUnicodeString
|-------------------------------------------------------------
|
| PURPOSE: To count the data bytes in a 0-terminated Unicode
|          string. 
|
| DESCRIPTION: Terminating 0 is not included in the count.
|
| EXAMPLE:  ByteCount = CountUnicodeString( MyString );
|
| HISTORY: 05.25.01 From CountString.
------------------------------------------------------------*/
u32
CountUnicodeString( u16* AString )
{
    u32 ByteCount;

    ByteCount = 0;

    while( *AString++ )
    {
        ByteCount += 2;
    }
    
    return( ByteCount );
}

/*------------------------------------------------------------
| FillString
|-------------------------------------------------------------
|
| PURPOSE: To fill a string with a given byte value. 
|
| DESCRIPTION:  
|
| EXAMPLE:   FillString( MyString, ' ' );
|
| HISTORY: 08.07.01 From CountString.
------------------------------------------------------------*/
void
FillString( s8* AString, u32 FillByte )
{
    // Until the end of the string has been reached.
    while( *AString )
    {
        // Copy the fill byte to the string.
        *AString = (s8) FillByte;
        
        // Advance to the next character in the string.
        AString++;
    }
}

/*------------------------------------------------------------
| FindLastByteInLine
|-------------------------------------------------------------
|
| PURPOSE: To find the address of the last byte in a text 
|          line.
|
| DESCRIPTION: Returns the address of the byte immediately
|              prior to the first 'CarriageReturn' or 0 byte.  
|              Empty lines return the address of the byte 
|              prior to where the first byte would be found.
|
| EXAMPLE:  LastByteAddress = FindLastByteInLine(AString);
|
| NOTE: Untested.
|
| ASSUMES: Line is terminated with a 'CarriageReturn' or 0.
|
| HISTORY: 01.14.93 
------------------------------------------------------------*/
s8*
FindLastByteInLine( s8* AString )
{
    while(*AString != 0 && *AString != CarriageReturn) 
    {
        ++AString;
    }

    AString--;

    return( AString );
}

/*------------------------------------------------------------
| IndexOfStringInArray
|-------------------------------------------------------------
|
| PURPOSE: To find the index of a string, in a zero-terminated
|          array of strings, that matches a given string.
|
| DESCRIPTION: Returns the entry index of the matching string
| or -1 if the string isn't found.
|
| EXAMPLE:  
|
|    s32 f;
|
|    ColorList[] = { "Red", "Green", "Blue", 0 };
|
|    f = IndexOfStringInArray( ColorList, "Green" )
|
|   Results in 'f' being equal to 1.
|
| NOTE: 
|
| ASSUMES: String must match exactly.
|
| HISTORY:  02.05.99 From 'IsStringInArray()'.
------------------------------------------------------------*/
s32
IndexOfStringInArray( s8** AStringList, s8* AString )
{
    s8* BString;
    s32 i;
    
    // Start with the first entry.
    i = 0;
    
    while( 1 )
    {
        BString = *AStringList++;
        
        // If there are no more strings.
        if( BString == 0 )
        {
            // Then the target string isn't in the array.
            return( -1 );
        }
        
        // If the strings match exactly.
        if( strcmp( (s8*) AString, (s8*) BString ) == 0 )
        {
            // Return the index of the string.
            return( i );
        }
        
        // Advance to the next entry.
        i++;
    }
}

/*------------------------------------------------------------
| InsertString
|-------------------------------------------------------------
|
| PURPOSE: To insert a string into another string.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|      String  ABuffer[255];        
|                                  
|      CopyString( "This a test", ABuffer );
|                                  
|      InsertString( "is ", ABuffer, 5 );
|                                  
|      yields: "this is a test"
|
| NOTE:  
|
| ASSUMES: There is room in the destination buffer for the 
|          new insertion.
|
| HISTORY: 12.06.89  from source by Jack A. Zucker
|          02.15.93 changed offset to quad.
------------------------------------------------------------*/
void
InsertString( s8*  SourceString, 
              s8*  DestinationString, 
              u32  DestinationByteOffset )
{
   u32   SourceByteCount;

   SourceByteCount = CountString( SourceString );

   // Make room for the new string.
   MoveString( (s8*) DestinationString+
                                 DestinationByteOffset, 
               (s8*) DestinationString+
                                 DestinationByteOffset+
                                 SourceByteCount );

   // Put the new string in place.
   CopyBytes( (u8*) SourceString, 
              (u8*) DestinationString+
                              DestinationByteOffset, 
              (u32) SourceByteCount );
}

/*------------------------------------------------------------
| IsMatchingStrings
|-------------------------------------------------------------
|
| PURPOSE: To test if two strings match exactly in content
|          and length.
|
| DESCRIPTION: Returns '1' if they match, else '0'. 
|
| EXAMPLE:  
|
|    Result = IsMatchingStrings( "ABA", "ABA" );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 01.02.97 from 'IsMatchingBytes'.
------------------------------------------------------------*/
u32
IsMatchingStrings( s8* A, s8* B )
{
    // While not at the end of either string.
    while( *A && *B )            
    {
        if( *A != *B )
        {
            return( 0 );
        }
        
        A++;
        B++;
    }
    
    // If the end of both strings reached at the same offset.
    if( *A == *B )
    {
        return( 1 );
    }
    else // Strings are of different length.
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| IsStringInArray
|-------------------------------------------------------------
|
| PURPOSE: To test if a string matches any of the strings
| in a zero-terminated array of strings.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|    s8*
|    ColorList[] = { "Red", "Green", "Blue", 0 };
|    f = IsStringInArray( "Red", ColorList )
|
| NOTE: 
|
| ASSUMES: String must match exactly.
|
| HISTORY:  01.11.96
|           09.01.98 Revised to silence compiler warning. 
------------------------------------------------------------*/
u32
IsStringInArray( s8* AString, s8** AStringList )
{
    s8* BString;
    
BeginLoop:
    
    BString = *AStringList++;
    
    // If there are no more strings.
    if( BString == 0 )
    {
        // Then the target string isn't in the array.
        return( 0 );
    }
    
    // If the strings match exactly.
    if( strcmp( (s8*) AString, (s8*) BString ) == 0 )
    {
        // The string is in the array.
        return( 1 );
    }
        
    goto BeginLoop;
}

/*------------------------------------------------------------
| LookUpString
|-------------------------------------------------------------
|
| PURPOSE: To look up a string at a relative offset to a given
| string, in a zero-terminated array of strings.
|
| DESCRIPTION: Returns the address of the string at the 
| given relative array offset if the string is found, or '0'
| if the key string is not found.
|
| EXAMPLE:  
|
|    s8*
|    NGLastTradingDays[] =
|    {
|       "NG96F", "12/21/95",
|       "NG96G", "01/25/96",
|       "NG96H", "02/23/96",
|       "NG96J", "03/25/96",
|       "NG96K", "04/24/96",
|       0
|    }; 
|     
|     
|    d = LookUpString( NGLastTradingDays, "NG96H", 1 );
|
|    returns d = "02/23/96"
|
| NOTE: 
|
| ASSUMES: String must match exactly.
|
| HISTORY:  01.19.96 Tested on one case.
|           09.01.98 Revised to silence compiler.
------------------------------------------------------------*/
s8*
LookUpString( s8** AStringList, s8* AString, s32 Offset )
{
    s8* BString;
    
Next:
    
    // Refer to a string in the list.
    BString = *AStringList;

    // If the end of the list has been reached.
    if( BString == 0 )
    {
        // Signal that the target string hasn't been found.
        return( 0 );
    }
    
    // If the string from the list matches the one sought.
    if( strcmp( (s8*) AString, (s8*) BString) == 0 )
    {
        // Return the string relative to the one found.
        return( AStringList[Offset] );
    }
    
    // Advance to the next string in the list.
    AStringList++;
    
    // Try the new string.
    goto Next;
}

/*------------------------------------------------------------
| MoveString
|-------------------------------------------------------------
|
| PURPOSE: To copy a zero-delimited string from one place 
| to another including the delimiter, allowing for possible
| overlap.
|
| DESCRIPTION: 
|
| EXAMPLE:  MoveString(FromString,ToBuffer);
|
| NOTE:  
|
| ASSUMES: Source and Target buffers may overlap.
|
| HISTORY: 01.01.96
------------------------------------------------------------*/
void
MoveString( s8* Source, s8* Target )
{
    s8*     S;
    u32     ByteCount;

    ByteCount = 1; // For terminating 0.
    S = Source;

    while( *S++ )
    {
        ByteCount++;
    }
   
    CopyBytes( (u8*) Source, (u8*) Target, ByteCount );
}

/*------------------------------------------------------------
| NthStringTable
|-------------------------------------------------------------
|
| PURPOSE: To refer to the nth string table in a list.
|
| DESCRIPTION: Returns the address to the nth string table
| record in a list where n = 0 for the first table, 1 for the 
| second  and so on. 
|
| If there is no nth table then zero is returned.
|
| EXAMPLE:  
|
|    S = NthStringTable( AListOfStringTables, n );
|
| NOTE:
|
| ASSUMES: List is zero-terminated.
|
| HISTORY: 04.04.99 
------------------------------------------------------------*/
StringTable*
NthStringTable( StringTable* L, u32 n )
{
    // Until the nth table has been found.
    while( L && n )
    {
        // Advance to the next table.
        L = L->Next;
        
        // Account for the step.
        n--;
    }
    
    // Return the result.
    return( L );
}

/*------------------------------------------------------------
| ReplaceBytesInString
|-------------------------------------------------------------
|
| PURPOSE: To replace all occurances of a byte within a 
| string with another.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|    ReplaceBytesInString( AString, (u16) 'a', (u16) 'A' );
|
| NOTE:
|
| ASSUMES: 
|
| HISTORY: 04.04.91 
|          11.11.93 changed 'u8' parameters to 'u16'.
------------------------------------------------------------*/
void
ReplaceBytesInString( s8* AString, u16 From, u16 To )
{
    while(*AString)
    {
        if( *AString == (s8) From ) 
        {
            *AString = (s8) To;
        }
        
        AString++;
    }
}

/*------------------------------------------------------------
| ReverseString
|-------------------------------------------------------------
|
| PURPOSE: To reverse the bytes in a string in place.
|
| DESCRIPTION:  
|
| EXAMPLE:  ReverseString( AString );
|
| NOTE:
|
| ASSUMES: 
|
| HISTORY: 01.13.94 copied from K&R2, p. 62
|          03.08.97 used pointers for speed.
------------------------------------------------------------*/
void
ReverseString( s8* A )
{
    s8  a, b;
    s8* B;
    
    // Locate the last character in the string.
    B = A;
    
    while( *B ) 
    {
        B++;
    }
    
    B--;

    // Swap high and low order bytes, moving to the center
    // till they meet.
    while( A < B ) 
    {
        a = *A;
        b = *B;
    
        *A++ = b;
        *B-- = a;
    }
}

/*------------------------------------------------------------
| RightJustifyInteger
|-------------------------------------------------------------
|
| PURPOSE: To convert a binary integer to a right-justified
|          ASCII decimal value and pad with leading spaces.
|
| DESCRIPTION: Does not put a string terminator in the field. 
|
| EXAMPLE:  
|
| ASSUMES: 
|
| HISTORY: 05.02.00
------------------------------------------------------------*/
void
RightJustifyInteger( 
    s8* AtField,
        // The destination field.
        //
    s32 FieldSize,
        // Size of the destination field in bytes.
        //
    s64 n )
        // The signed integer to be stored into the field.
{
    s8  b[1024];
    s32 i, ByteCount;
    s8* From;
    
    // Convert the number to an unsigned string in 'b'.
    ByteCount = Convertu64ToString( (u64) n, b );
    
    // If there is a sign.
    if( n < 0 )
    {
        // Increase the byte count by one.
        ByteCount += 1;
    }
    
    // Calculate the field offset.
    i = FieldSize - ByteCount;
    
    // If the result is too big for the field.
    if( i < 0 )
    {
        // Truncate on the left.
        From = b + -i;
        
        ByteCount = FieldSize;
        
        i = 0;
    }
    else // The result will fit in the field without
         // cutting it down to size.
    {
        // The starting byte is the first one.
        From = b;
    }
    
    // Pad the field with leading spaces.
    while( i-- )
    {
        *AtField++ = ' ';
    }
    
    // If there is a sign.
    if( n < 0 )
    {
        // Output the sign.
        *AtField++ = '-';
        
        // Account for the sign.
        ByteCount--;
    }
    
    // Copy the digits of the number string.
    while( ByteCount-- )
    {
        *AtField++ = *From++;
    }
}
    
