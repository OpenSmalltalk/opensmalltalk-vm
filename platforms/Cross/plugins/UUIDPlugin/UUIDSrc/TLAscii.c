/*------------------------------------------------------------
| TLAscii.c
|-------------------------------------------------------------
|
| PURPOSE: To provide ASCII code procedures.
|
| DESCRIPTION: 
|
| HISTORY: 02.03.93 from ascii.txt.
------------------------------------------------------------*/

#include "TLTarget.h" 

#ifndef FOR_DRIVER
#include <stdio.h>
#endif

#include "NumTypes.h"
#include "TLAscii.h"

u8  BinaryDigit[]  = { '0', '1' };

u8  OctalDigit[]   = { '0','1','2','3','4','5','6','7' };

u8  DecimalDigit[] = { '0','1','2','3','4','5','6','7',
                       '8','9' };

u8  HexDigit[] = { '0','1','2','3','4','5','6','7',
                   '8','9','A','B','C','D','E','F' };

// Subtract '0' from an ASCII hex digit and then use
// the result as an index into this table to convert
// an ASCII hex digit to binary, like this:
//
//     b = HexDigitToBinary[ h - '0' ];
u8
HexDigitToBinary[] =
{ // Binary  ASCII
    0,      // "0"
    1,      // "1"
    2,      // "2"
    3,      // "3"
    4,      // "4"
    5,      // "5"
    6,      // "6"
    7,      // "7"
    8,      // "8"
    9,      // "9"
    0,      // ":"
    0,      // ";"
    0,      // "<"
    0,      // "="
    0,      // ">"
    0,      // "?"
    0,      // "@"
    0xA,    // "A"
    0xB,    // "B"
    0xC,    // "C"
    0xD,    // "D"
    0xE,    // "E"
    0xF,    // "F"
    0,      // "G"
    0,      // "H"
    0,      // "I"
    0,      // "J"
    0,      // "K"
    0,      // "L"
    0,      // "M"
    0,      // "N"
    0,      // "O"
    0,      // "P"
    0,      // "Q"
    0,      // "R"
    0,      // "S"
    0,      // "T"
    0,      // "U"
    0,      // "V"
    0,      // "W"
    0,      // "X"
    0,      // "Y"
    0,      // "Z"
    0,      // "["
    0,      // "\"
    0,      // "]"
    0,      // "asciicircum"
    0,      // "_" 
    0,      // "grave" 
    0xA,    // "a" 
    0xB,    // "b"
    0xC,    // "c"
    0xD,    // "d"
    0xE,    // "e"
    0xF     // "f"
};

// End-of-line strings.
s8  MacEOLString[3]  = { CarriageReturn, 0, 0 };
s8  WinEOLString[3]  = { CarriageReturn, LineFeed, 0 };
s8  UnixEOLString[3] = { LineFeed, 0, 0 };

// Array of references to end-of-line strings that
// are indexed by the type of end-of-line:
s8*
EOLString[3] =
{
    (s8*) MacEOLString, // MacEOL  == 0
    (s8*) WinEOLString, // WinEOL  == 1
    (s8*) UnixEOLString // UnixEOL == 2
};

/*------------------------------------------------------------
| ConvertDataToASCIIHex
|-------------------------------------------------------------
|
| PURPOSE: To convert a range of bytes to their ASCII hex 
|          equivalent.
|
| DESCRIPTION: Takes as input the location of the source 
| buffer, the location of destination buffer, and a source 
| count.
|               Spaces inserted after n hex pairs.
|
| EXAMPLE: 
|
| NOTE: Result is at least twice as long as the source count.
|
| ASSUMES: 
|
| HISTORY: 08.29.89 
|          09.15.89 added spacing option
|          02.15.93 changed count to quad.
------------------------------------------------------------*/
void
ConvertDataToASCIIHex( u8* Source, 
                       u8* Destination, 
                       u32 Count, 
                       u32 Spacing )
{
    u8      AByte;
    u32     SpacingCountDown;

    SpacingCountDown = Spacing;  // pad with spaces

    while( Count-- )
    {
        AByte = *Source++;
        *Destination++ = HexDigit[ (AByte >> 4) & 0x0f ]; 
         
        // ordering is [Hi-nibble][Lo-nibble] 
        *Destination++ = HexDigit[ AByte & 0x0f ];

        if( Spacing && (--SpacingCountDown == 0 ))
        {
            SpacingCountDown = Spacing;  // pad with spaces
            *Destination++ = ' ';
        }
    }                 
}

/*------------------------------------------------------------
| ConvertDataToPrintableASCII
|-------------------------------------------------------------
|
| PURPOSE: To convert a range of bytes to a string which 
|          can be printed.
|
| DESCRIPTION: Replaces unprintable bytes with '.'.
|
| EXAMPLE: 
|
| NOTE: Result may be longer than the source count due to
|       spacing.
|
| ASSUMES: 
|
| HISTORY: 08.29.89 
|          09.15.89 added spacing option
|          02.15.93 changed count to quad.
------------------------------------------------------------*/
void
ConvertDataToPrintableASCII( u8* Source, 
                             u8* Destination, 
                             u32 Count, 
                             u32 Spacing )
{
    u32 SpacingCountDown;

    while( Count-- )
    {
        if( IsPrintableASCIICharacter( (u16) *Source ) )
        {
            *Destination = *Source;
        }
        else // Use '.' as placeholder.
        {
            *Destination = '.';
        }
        
        Destination++;
        Source++;

        SpacingCountDown = Spacing;  // pad with spaces

        while( SpacingCountDown-- )
        {
            *Destination++ = ' ';
        }
    }
}

#ifndef FOR_DRIVER

/*------------------------------------------------------------
| ConvertDataToSourceCode
|-------------------------------------------------------------
|
| PURPOSE: To convert data to lines of C source code.
|
| DESCRIPTION: Generates a byte array description that a C
| compiler can use.
|
| Returns the number of bytes in the output string not 
| counting the zero terminator.
|
| Outputs in the following format, a zero-delimited C-string
| with spaces between each of the numbers:
|
|   u8
|   MyData[] =
|   {
|      0, 1, 3, 234, 17, 93, 210, 213,
|      0, 1, 3, 234, 17, 93, 210, 213,
|      0, 1, 3, 234, 17, 93, 210, 213,
|   };
|     ^
|     |___ includes new line here.
|
| EXAMPLE: 
|
| NOTE: Result may be longer than the source count due to
|       spacing.
|
| ASSUMES: Target buffer is large enough for the result.
|
| HISTORY: 02.24.99
------------------------------------------------------------*/
                            // OUT: How many bytes of output
u32                         // were produced.
ConvertDataToSourceCode( 
    s8* Name,               // The name of the data to be used
                            // as the name of the byte array.
                            //
    u8* Source,             // Where the source bytes are.
                            //
    s8* Destination,        // Where the target buffer is.
                            //
    u32 Count,              // How many source bytes there are.
                            //
    u32 BytesPerLine,       // How many bytes to put on each
                            // output line.
                            //
    u8* EOL )               // The end-of-line characters to
                            // use, one these three:
                            //      MacEOLString[3];
                            //      WinEOLString[3];
                            //      UnixEOLString[3];
                            // 
{
    s8* T;
    s8* End;
    
    // Refer to target buffer as 'T'.
    T = Destination;
    
    // Output the prefix of the array:
    //
    //   u8
    //   MyData[] =
    //   {
    //  
    T += sprintf( T, "u8%s%s[] = %s{%s    ", EOL, Name, EOL, EOL );
    
    // Calculate the address of end of the line.
    End = T + BytesPerLine;
    
    // For each source byte.
    while( Count-- )
    {
        // If it's time to insert a line break.
        if( T >= End )
        {
            // Output an end-of-line sequence followed by a tab.
            T += sprintf( T, "%s    ", EOL );
            
            // Calculate the address of end of the line.
            End = T + BytesPerLine;
        }
        
        // If this is not the last byte.
        if( Count )
        {
            // Output the current source byte as an unsigned decimal.
            T += sprintf( T, "%u, ", (u32) *Source++ );
        }
        else // This is the last byte.
        {
            // Output the current source byte as an unsigned decimal.
            T += sprintf( T, "%u%s};%s", (u32) *Source, EOL, EOL );
        }
    }
    
    // Append a zero terminator.
    *T = 0;
    
    // Return the number of bytes generated.
    return( T - Destination );
}

#endif // FOR_DRIVER

/*------------------------------------------------------------
| ConvertLetterToLowerCase
|-------------------------------------------------------------
|
| PURPOSE: To convert upper case letters to lower case.
|
| DESCRIPTION: Accepts any byte value as input. 
|
| EXAMPLE: 
|
| NOTE: Untested.  
|
| ASSUMES: 
|
| HISTORY: 01.12.94 
------------------------------------------------------------*/
u16
ConvertLetterToLowerCase( u16 AByte )
{
    if( IsUpperCaseLetter( AByte ) )
    {
        return( (u16) ( AByte + 32 ) );
    }
    
    return( AByte );
}

/*------------------------------------------------------------
| ConvertLetterToUpperCase
|-------------------------------------------------------------
|
| PURPOSE: To convert lower case letters to upper case.
|
| DESCRIPTION: Accepts any byte value as input. 
|
| EXAMPLE: 
|
| NOTE: Untested.  
|
| ASSUMES: 
|
| HISTORY: 01.12.94 
------------------------------------------------------------*/
u16
ConvertLetterToUpperCase( u16 AByte )
{
    if( IsLowerCaseLetter(AByte) )
    {
        return( (u16) ( AByte - 32 ) );
    }
    
    return( AByte );
}

/*------------------------------------------------------------
| GetCharMB
|-------------------------------------------------------------
|
| PURPOSE: To get a 1 or 2 byte character from a buffer and
|          return the address of the next character.
|
| DESCRIPTION: If the character is two bytes then the high
| order byte is comes first followed by the low order byte. 
|
| Handles the hex form special case in which a '>' is found 
| as the second nibble, treating it as a zero and not 
| advancing past the '>' -- this is for interpreting PDF hex 
| form strings like this <901fa> which is read as 901fa0.
|
| If hex form, ignores non-hex digits.
|
| EXAMPLE:  At = GetCharMB( At, &FromChar, 2, 0 );
|
| NOTE: The 'MB' suffix stands for 'MultiByte'.
|       See the companion procedure, 'PutCharMB()'.
|
| ASSUMES: 1 or 2 bytes per character.
|
|          Last nibble of character may be '>' if hex form
|          and last nibble was a zero, according to PDF
|          conventions.
|
|          Embedded whitespace may be present for hex form.
|
| HISTORY: 02.07.99 From 'PutCharMB()'.
|          02.21.99 Added whitespace skipping for hex form.
|          03.14.99 Added 'IsSwapBytes'.
|          03.28.99 Changed source parameter name from 'Buf'
|                   to 'A' to avoid confusion with 'Buf'
|                   data type.
|          03.29.99 Changed 'IsSwapBytes' to 'IsHiByteFirst'.
------------------------------------------------------------*/
                           // Returns location following the
                           // character in the source data
u8*                        // buffer.
GetCharMB( 
    u8*     A,             // Where the source data is.
                           //
    u32*    AChar,         // Where the target character is.
                           //
    u32     BytesPerChar,  // How many bytes are used to hold
                           // the resulting target character 
                           // code in internal form.
                           //
    u32     IsHexForm,     // '1' if the source data is
                           // in ASCII hex digit form, either
                           // upper or lower case 0-F.
                           //
    u32     IsHiByteFirst )// '1' if a double-byte character
                           // character and the most-significant
                           // byte comes first.
{
    u32 C;
    u32 Hi;
    u32 Lo;
    u8  c;
    
    // If this is a single-byte string.
    if( BytesPerChar == 1 )
    {
        // If hex form is to be read.
        if( IsHexForm )
        {
TryNextHi:
            // Get the next byte, possibly a high nibble.
            c = *A++;
            
            // If this isn't a hex digit.
            if( ! IsHexDigit(c) )
            {
                // Skip non-hex digit high nibbles.
                goto TryNextHi;
            }
            
            // Get the high nibble as an ASCII hex digit,
            // converting it to binary.
            Hi = (u32) HexDigitToBinary[ c - '0' ];

TryNextLo:
            // Get the next byte, possibly a low nibble.
            c = *A++;
            
            // If a '>' character has been found.
            if( c == '>' )
            {
                // Back up the buffer address.
                A--;
                
                // Then treat the low nibble as zero.
                Lo = 0;
            }
            else // Either a hex digit or non-digit were 
                 // parsed.
            {
                // If this isn't a hex digit.
                if( ! IsHexDigit(c) )
                {
                    // Skip non-hex digit low nibbles.
                    goto TryNextLo;
                }
                
                // Get the low nibble as an ASCII hex digit,
                // converting it to binary.
                Lo = (u32) HexDigitToBinary[ c - '0' ];
            }
            
            // Combine the high and low nibbles.
            C = ( Hi << 4 ) | Lo;
        }
        else // Not using hex form.
        {
            // Get the character.
            C = (u32) ( *A++ );
        }
    }
    else // Two bytes per character.
    {
        // If hex form is to be read.
        if( IsHexForm )
        {
TryNextHi2:
            // Get the next byte, possibly a high nibble.
            c = *A++;
            
            // If this isn't a hex digit.
            if( ! IsHexDigit(c) )
            {
                // Skip non-hex digit high nibbles.
                goto TryNextHi2;
            }
            
            // Get the high nibble of the high byte as an 
            // ASCII hex digit, converting it to binary.
            Hi = (u32) HexDigitToBinary[ c - '0' ];
            
TryNextLo2:
            // Get the next byte, possibly a low nibble.
            c = *A++;
            
            // If this isn't a hex digit.
            if( ! IsHexDigit(c) )
            {
                // Skip non-hex digit high nibbles.
                goto TryNextLo2;
            }
            
            // Get the low nibble of the high byte as an 
            // ASCII hex digit, converting it to binary.
            Lo = (u32) HexDigitToBinary[ c - '0' ];
            
            // Combine the high and low nibbles of the high
            // byte.
            C = ( ( Hi << 4 ) | Lo ) << 8;
            
TryNextHi3:
            // Get the next byte, possibly a high nibble.
            c = *A++;
            
            // If this isn't a hex digit.
            if( ! IsHexDigit(c) )
            {
                // Skip non-hex digit high nibbles.
                goto TryNextHi3;
            }
            
            // Get the high nibble of the low byte as an 
            // ASCII hex digit, converting it to binary.
            Hi = (u32) HexDigitToBinary[ c - '0' ];
            
TryNextLo3:
            // Get the next byte, possibly a low nibble.
            c = *A++;
            
            // If a '>' character has been found.
            if( c == '>' )
            {
                // Back up the buffer address.
                A--;
                
                // Then treat the low nibble as zero.
                Lo = 0;
            }
            else // Either a hex digit or non-digit were 
                 // parsed.
            {
                // If this isn't a hex digit.
                if( ! IsHexDigit(c) )
                {
                    // Skip non-hex digit low nibbles.
                    goto TryNextLo3;
                }
                
                // Get the low nibble as an ASCII hex digit,
                // converting it to binary.
                Lo = (u32) HexDigitToBinary[ c - '0' ];
            }
            
            // Combine the high and low nibbles of the low
            // byte with the high byte.
            C |= ( Hi << 4 ) | Lo;
        }
        else // Not using hex form.
        {
            // Get the high-order character.
            C = ( (u32) ( *A++ ) ) << 8;
            
            // Get the low-order byte of the character.
            C |= (u32) ( *A++ );
        }
        
        // If the bytes should be swapped.
        if( ! IsHiByteFirst )
        {
            // Swap the bytes.
            C = ( ( C & 0xff ) << 8 ) | ( ( C >> 8 ) & 0xff );
        }
    }
        
    // Copy the character to the result.
    *AChar = C;
    
    // Return the address of the next character.
    return( A );
}

/*------------------------------------------------------------
| IsPrintableASCIICharacter
|-------------------------------------------------------------
|
| PURPOSE: To tell if an ASCII character is printable.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: Untested.  Doesn't include Apple extended chars.
|
| ASSUMES: An ascii code is <= 126.
|
| HISTORY: 01.12.94
|          02.15.99 Replaced with macro with the same name.
------------------------------------------------------------*/
#if 0
u32 
IsPrintableASCIICharacter( u16 AByte )
{
    if( AByte >= 32 && AByte <= 126 ) 
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}
#endif 

/*------------------------------------------------------------
| IsDigit
|-------------------------------------------------------------
|
| PURPOSE: To determine if a byte is an ASCII digit.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: Untested.  
|
| ASSUMES: 
|
| HISTORY: 01.12.94 
------------------------------------------------------------*/
u32
IsDigit( u16 AByte )
{
   if( AByte >= '0' && AByte <= '9' ) return(1);
   return(0);
}

/*------------------------------------------------------------
| Is1Thru9
|-------------------------------------------------------------
|
| PURPOSE: To determine if a byte is an ASCII digit in the
| range 1 thru 9 inclusive.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: Untested.  
|
| ASSUMES: 
|
| HISTORY: 01.12.94
------------------------------------------------------------*/
u32
Is1Thru9( u16 AByte )
{
   if( AByte >= '1' && AByte <= '9' ) return(1);
   return(0);
}

/*------------------------------------------------------------
| IsHex
|-------------------------------------------------------------
|
| PURPOSE: To determine if a byte is a hexadecimal digit.
|
| DESCRIPTION: Handles both upper and lower case letters.
|
| HISTORY: 08.12.01 
------------------------------------------------------------*/
u32 // OUT: 1 if byte is hex digit or 0 if not.
IsHex( s8 AByte )
{
   if( ( AByte >= '0' && AByte <= '9' ) ||
       ( AByte >= 'a' && AByte <= 'f' ) ||
       ( AByte >= 'A' && AByte <= 'F' ) )
   {
        return(1);
   }
   
   return(0);
}

/*------------------------------------------------------------
| IsLetter
|-------------------------------------------------------------
|
| PURPOSE: To determine if a byte is an ASCII letter.
|
| DESCRIPTION: Returns 1 if the character is a letter or 0
| if it isn't.
|
| HISTORY: 01.12.94
|          12.26.99 Cleaned up logic.
------------------------------------------------------------*/
u32
IsLetter( u16 C )
{
    // If the given character is either an lower or upper
    // case letter.
    if( ( C >= 'a' && C <= 'z') ||
        ( C >= 'A' && C <= 'Z')  ) 
    {
        return( 1 );
    }
    else // Not a letter.
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| IsLowerCaseLetter
|-------------------------------------------------------------
|
| PURPOSE: To determine if a byte is a lower case ASCII 
|          letter.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: Untested.  
|
| ASSUMES: 
|
| HISTORY: 01.12.94 
------------------------------------------------------------*/
u32
IsLowerCaseLetter( u16 AByte )
{
   if( AByte >= 'a' && AByte <= 'z' ) return(1);
   return(0);
}

/*------------------------------------------------------------
| IsUpperCaseLetter
|-------------------------------------------------------------
|
| PURPOSE: To determine if a byte is an upper case ASCII 
|          letter.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: Untested.  
|
| ASSUMES: 
|
| HISTORY: 01.12.94 
------------------------------------------------------------*/
u32
IsUpperCaseLetter( u16 AByte )
{
   if( AByte >= 'A' && AByte <= 'Z' ) return(1);
   return(0);
}

/*------------------------------------------------------------
| PutCharMB
|-------------------------------------------------------------
|
| PURPOSE: To put a 1 or 2 byte character to a buffer and
|          return the address of the next character.
|
| DESCRIPTION: If the character is two bytes then the high
| order byte is output first followed by the low order byte. 
|
| If the 'IsHexForm' parameter is set to 1 then the output
| is converted to hexidecimal digits, two per byte of input
| data.
|
| EXAMPLE:  At = PutCharMB( At, '[', 2, 0 );
|
| NOTE: The 'MB' suffix stands for 'MultiByte'.
|
| ASSUMES: 1 or 2 bytes per character.
|
| HISTORY: 01.31.99 From 'CountString()'.
|          02.07.99 Added 'IsHexForm' parameter.
|          03.14.99 Added 'IsSwapBytes'.
------------------------------------------------------------*/
                            // Returns location following the
                            // character in the target data
u8*                         // buffer.
PutCharMB( 
    u8*     A,              // Where the target buffer is.
                            //
    u32     AChar,          // The source character.
                            //
    u32     BytesPerChar,   // How many bytes are in the 
                            // the source character.
                            //
    u32     IsHexForm,      // '1' if the target data is
                            // in ASCII hex digit form, 
                            // upper case 0-F.
                            //
    u32     IsSwapBytes )   // '1' if a double-byte character
                            // and the bytes should be swapped.
                            // before storing to the target.
{
    u8  Hi, Lo, Temp;
    
    // Get the low-order byte of the character.
    Lo = (u8) ( AChar & 0xFF );
    
    // If this is a single-byte character.
    if( BytesPerChar == 1 )
    {
        // If hex form is to be generated.
        if( IsHexForm )
        {
            // Output the high nibble as a hex digit.
            *A++ = HexDigit[ (Lo >> 4) & 0x0F ];
            
            // Output the low nibble as a hex digit.
            *A++ = HexDigit[ Lo & 0x0F ];
        }
        else // Not using hex form.
        {
            // Copy the high-order byte of the character.
            *A++ = Lo;
        }
    }
    else // Two bytes per character.
    {
        // Get the high byte of the character.
        Hi = (u8) ( AChar >> 8 );
        
        // If the bytes should be swapped.
        if( IsSwapBytes )
        {
            // Swap low and high bytes.
            Temp = Lo;
            Lo = Hi;
            Hi = Temp;
        }
        
        // If hex form is to be generated.
        if( IsHexForm )
        {
            // Output the high nibble as a hex digit.
            *A++ = HexDigit[ (Hi >> 4) & 0x0F ];
            
            // Output the low nibble as a hex digit.
            *A++ = HexDigit[ Hi & 0x0F ];
            
            // Output the high nibble as a hex digit.
            *A++ = HexDigit[ (Lo >> 4) & 0x0F ];
            
            // Output the low nibble as a hex digit.
            *A++ = HexDigit[ Lo & 0x0F ];
        }
        else // Not using hex form.
        {
            // Copy the high-order byte of the character.
            *A++ = Hi;
            
            // Copy the high-order byte of the character.
            *A++ = Lo;
        }
    }
    
    // Return the address of the next character.
    return( A );
}

/*------------------------------------------------------------
| ReplaceControlCodesWithSpaces
|-------------------------------------------------------------
|
| PURPOSE: To replace control codes in a buffer with spaces.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: Untested.  Maybe expand to all control codes.
|       What about tabs?
|
| ASSUMES: A control code is one of the following:
|          LineFeed 
|          CarriageReturn
|          ControlZ 
|
| HISTORY: 03.20.92 
------------------------------------------------------------*/
void
ReplaceControlCodesWithSpaces( s8* AString, u32 ACount )
{
    u8  AByte;
    
    while(ACount--)
    {
        AByte = (u8) *AString;
        
        if( AByte == LineFeed ||
            AByte == CarriageReturn ||
            AByte == ControlZ ) 
        {
            *AString = Space;
        }
        
        AString++;
    }
}
 


