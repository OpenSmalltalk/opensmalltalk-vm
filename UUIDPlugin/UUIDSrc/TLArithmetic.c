/*------------------------------------------------------------
| TLArithmetic.c
|-------------------------------------------------------------
|
| PURPOSE: To provide multiple-precision unsigned integer 
|          arithmetic functions.
|
| DESCRIPTION: The multiple-precision numbers used here are
| strings of ASCII decimal digits ordered such that the most
| significant digit is first in the string.  No number sign
| is supported.
|
| HISTORY: 03.08.97
------------------------------------------------------------*/

#include "TLTypes.h"
#include "TLStrings.h"
#include "TLAscii.h"
#include "TLArithmetic.h"


/*------------------------------------------------------------
| AddASCIIDecimal
|-------------------------------------------------------------
|
| PURPOSE: To add two unsigned integers expressed as ASCII 
|          decimal strings.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|           AddASCIIDecimal( &Result, "123", "2930" );
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer isn't one of the sources.
|
|          The most significant digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
| HISTORY: 03.08.97 Tested.
------------------------------------------------------------*/
void
AddASCIIDecimal( s8* Result, s8* A, s8* B )
{
    s8* AEnd;
    s8* BEnd;
    s8* R;
    s8  a,b,c,r;
    
    // Refer to the first byte in the result buffer.
    R = Result;
    
    // Locate the low-order digits of the inputs.
    AEnd = AddressOfLastCharacterInString( A );
    BEnd = AddressOfLastCharacterInString( B );
    
    // Clear the carry digit.
    c = 0;
    
    // While there are digits to add.
    while( (AEnd >= A) || (BEnd >= B) )
    {
        // Get the remaining low-order 'A' digit and convert 
        // to binary.
        if( AEnd >= A )
        {
            a = (*AEnd--) - '0';
        }
        else // No more source digits: use 0.
        {
            a = 0;
        }
    
        // Get the remaining low-order 'B' digit and convert 
        // to binary.
        if( BEnd >= B )
        {
            b = (*BEnd--) - '0';
        }
        else // No more source digits: use 0.
        {
            b = 0;
        }
        
        // Calculate the result digit bundled with carry.
        r = a + b + c;
        
        // Separate result digit from carry.
        if( r > 9 )
        {
            c = 1;
            r = r - 10;
        }
        else // No carry out.
        {
            c = 0;
        }
        
        // Convert result digit to ASCII and save.
        *R++ = r + '0';
    }
    
    // If there is a carry, add another digit to the result.
    if( c )
    {
        *R++ = '1';
    }
    
    // Append a string terminator to the result.
    *R = 0;
    
    // Reverse the result string to make high-order digit
    // first.
    ReverseString( Result );
}
        
/*------------------------------------------------------------
| AddULoDec
|-------------------------------------------------------------
|
| PURPOSE: To add two unsigned integers expressed as ASCII 
|          low-order-first decimal strings.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|           AddULoDec( &Result, "123", "293" );
|
|           Result: "317", or "713" as high-order first.
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer may be one of the sources.
|
|          The least significant digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
| HISTORY: 03.12.97 tested.
|          03.22.97 Revised to allow result to be one of
|                   the source buffers. Tested.
------------------------------------------------------------*/
void
AddULoDec( s8* Result, s8* A, s8* B )
{
    s8* R;
    s8  a,b,c,r;
    s32 ADigitCount;
    s32 BDigitCount;
    s32 DigitCount;
    
    // Refer to the first byte in the result buffer.
    R = Result;
    
    // Clear the carry digit.
    c = 0;
    
    // Count the number of digits in the two sources.
    ADigitCount = CountString( A );
    BDigitCount = CountString( B );
    
    // Select the count of the longer string.
    DigitCount = max( ADigitCount, BDigitCount );
    
    // While there are digits to add.
    while( DigitCount-- )
    {
        // Get the remaining low-order 'A' digit and convert 
        // to binary.
        if( ADigitCount )
        {
            ADigitCount--;
            
            a = (*A++) - '0';
        }
        else // No more source digits: use 0.
        {
            a = 0;
        }
    
        // Get the remaining low-order 'B' digit and convert 
        // to binary.
        if( BDigitCount )
        {
            BDigitCount--;
            
            b = (*B++) - '0';
        }
        else // No more source digits: use 0.
        {
            b = 0;
        }
        
        // Calculate the result digit bundled with carry.
        r = a + b + c;
        
        // Separate result digit from carry.
        if( r > 9 )
        {
            c = 1;
            r = r - 10;
        }
        else // No carry out.
        {
            c = 0;
        }
        
        // Convert result digit to ASCII and save.
        *R++ = r + '0';
    }
    
    // If there is a carry, add another digit to the result.
    if( c )
    {
        *R++ = '1';
    }

    // Drop any insignificant zeros.
    R--;
    while( (*R == '0') && (R > Result) )
    {
        R--;
    }
    R++;
    
    // Append a string terminator to the result.
    *R = 0;
}

/*------------------------------------------------------------
| CompareASCIIDecimal
|-------------------------------------------------------------
|
| PURPOSE: To compare two unsigned integers expressed as  
|          ASCII high-order-first decimal strings.
|
| DESCRIPTION: Comparison operation.
|              Returns: 0 if A = B.
|                       positive number if A > B.
|                       negative number if A < B.
|
| EXAMPLE:  Result = CompareASCIIDecimal( "123", "122" );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY:  03.12.97 from 'CompareStrings' and 
|                    'SubtractASCIIDecimal'.  Tested.
------------------------------------------------------------*/
s32
CompareASCIIDecimal( s8* A, s8* B )
{
    s8*     AEnd;
    s8*     BEnd;
    s8      a,b,c;
    u32     IsDifferent;
    
    // Assume numbers are the same until proven different.
    IsDifferent = 0;
    
    // Locate the low-order digits of the inputs.
    AEnd = AddressOfLastCharacterInString( A );
    BEnd = AddressOfLastCharacterInString( B );
    
    // Clear the carry digit.
    c = 0;
    
    // While there are digits to compare.
    while( (AEnd >= A) || (BEnd >= B) )
    {
        // Get the remaining low-order 'A' digit and convert 
        // to binary.
        if( AEnd >= A )
        {
            a = (*AEnd--) - '0';
        }
        else // No more source digits: use 0.
        {
            a = 0;
        }
    
        // Get the remaining low-order 'B' digit and convert 
        // to binary.
        if( BEnd >= B )
        {
            b = (*BEnd--) - '0';
        }
        else // No more source digits: use 0.
        {
            b = 0;
        }
        
        // Determine if any digit is different.
        if( a != b )
        {
            IsDifferent = 1;
        }
        
        // If carry-adjusted minuend is larger than the
        // subtrahend.
        if( (a - c) >= b )
        {
            // Absorb the borrow flag.
            c = 0;
        }
        else // Need to borrow.
        {
            // Propagate the borrow.
            c = 1;
        }
    }
    
    // If the numbers are different
    if( IsDifferent )
    {
        // If there is a carry then B > A.
        if( c )
        {
            return( -1 );
        }
        else // A > B
        {
            return( 1 );
        }
    }
    else // Numbers are equal.
    {
        return( 0 ); 
    }
}

/*------------------------------------------------------------
| CompareULoDec
|-------------------------------------------------------------
|
| PURPOSE: To compare two unsigned integers expressed as  
|          ASCII low-order-first decimal strings.
|
| DESCRIPTION: Comparison operation.
|              Returns: 0 if A = B.
|                       positive number if A > B.
|                       negative number if A < B.
|
| EXAMPLE:  Result = CompareULoDec( "123", "122" );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY:  03.12.97 from 'CompareASCIIDecimal'.  Tested.
------------------------------------------------------------*/
s32
CompareULoDec( s8* A, s8* B )
{
    s8      a,b,c;
    u32     IsDifferent;
    
    // If 'A' and 'B' refer to the same buffer then they
    // are equal.
    if( A == B )
    {
        return( 0 );
    }
    
    // Assume numbers are the same until proven different.
    IsDifferent = 0;
    
    // Clear the carry digit.
    c = 0;
    
    // While there are digits to compare.
    while( *A || *B )
    {
        // Get the remaining low-order 'A' digit and convert 
        // to binary.
        if( *A )
        {
            a = (*A++) - '0';
        }
        else // No more source digits: use 0.
        {
            a = 0;
        }
    
        // Get the remaining low-order 'B' digit and convert 
        // to binary.
        if( *B )
        {
            b = (*B++) - '0';
        }
        else // No more source digits: use 0.
        {
            b = 0;
        }
        
        // Determine if any digit is different.
        if( a != b )
        {
            IsDifferent = 1;
        }
        
        // If carry-adjusted minuend is larger than the
        // subtrahend.
        if( (a - c) >= b )
        {
            // Absorb the borrow flag.
            c = 0;
        }
        else // Need to borrow.
        {
            // Propagate the borrow.
            c = 1;
        }
    }
    
    // If the numbers are different
    if( IsDifferent )
    {
        // If there is a carry then B > A.
        if( c )
        {
            return( -1 );
        }
        else // A > B
        {
            return( 1 );
        }
    }
    else // Numbers are equal.
    {
        return( 0 ); 
    }
}
                
/*------------------------------------------------------------
| ConvertASCIIBinaryToASCIIHex
|-------------------------------------------------------------
|
| PURPOSE: To convert string of ASCII binary digits to 
|          an equivalent string of ASCII hexidecimal digits. 
|
| DESCRIPTION: Takes as input the location of the source 
| buffer, the location of destination buffer, and a source 
| count. 
|
|    ConvertASCIIBinaryToASCIIHex( "10110", AtHex );
|
| EXAMPLE: 
|
| NOTE: Result is roughly one fourth as long as the source.
|
| ASSUMES: Hex digits should be uppercase.
|
| HISTORY: 03.04.97
------------------------------------------------------------*/
void
ConvertASCIIBinaryToASCIIHex( s8* AtBinary, s8* AtHex )
{
    s8   h, b;
    s32  i, j;
    s32  BinCount, HexCount;
    s8*  AtEndBinary;
    s8*  AtEndHex;
    
    // Count the binary digits.
    BinCount = CountString(AtBinary);
    
    // Calculate the resulting number of hex digits.
    HexCount = BinCount >> 2;
    if( BinCount & 3 ) 
    {
        HexCount++;
    }
    
    // Refer to the last binary and hex digits.
    AtEndBinary = &AtBinary[ BinCount - 1 ];
    AtEndHex    = &AtHex[ HexCount - 1 ];
    
    // For each hex digit.
    for( i = 0; i < HexCount; i++ )
    {
        // Clear the digit accumulator.
        h = 0;
        
        // Get up to the last 4 binary digits.
        for( j = 1; 
             (j < 16) && (AtEndBinary >= AtBinary); 
             j <<= 1 )
        {
            // Get the lowest-order unprocessed binary digit.
            b = *AtEndBinary--;
            
            // Convert the ASCII binary to binary.
            if( b == '1' )
            {
                h |= j;
            }
        }
        
        // Save the hex digit.
        *AtEndHex-- = HexDigit[ h ];
    }
    
    // Append a string terminator.
    AtHex[ HexCount ] = 0;
}

/*------------------------------------------------------------
| ConvertASCIIBinaryToASCIIOctal
|-------------------------------------------------------------
|
| PURPOSE: To convert string of ASCII binary digits to 
|          an equivalent string of ASCII octal digits. 
|
| DESCRIPTION: Takes as input the location of the source 
| string and the location of destination string.
|
|    ConvertASCIIBinaryToASCIIOctal( "10110", AtOctal );
|
| EXAMPLE: 
|
| NOTE: Result is roughly one third as long as the source.
|
| ASSUMES: 
|
| HISTORY: 03.05.97 from 'ConvertASCIIBinaryToASCIIHex'.
------------------------------------------------------------*/
void
ConvertASCIIBinaryToASCIIOctal( s8* AtBinary, s8* AtOctal )
{
    s8   a, b;
    s32  i, j;
    s32  BinCount, OctalCount;
    s8*  AtEndBinary;
    s8*  AtEndOctal;
    
    // Count the binary digits.
    BinCount = CountString(AtBinary);
    
    // Calculate the resulting number of octal digits.
    OctalCount = BinCount / 3;
    if( BinCount % 3 ) 
    {
        OctalCount++;
    }
    
    // Refer to the last binary and octal digits.
    AtEndBinary = &AtBinary[ BinCount - 1 ];
    AtEndOctal  = &AtOctal[ OctalCount - 1 ];
    
    // For each octal digit.
    for( i = 0; i < OctalCount; i++ )
    {
        // Clear the digit accumulator.
        a = 0;
        
        // Get up to the last 3 binary digits.
        for( j = 1; 
             (j < 8) && (AtEndBinary >= AtBinary); 
             j <<= 1 )
        {
            // Get the lowest-order unprocessed binary digit.
            b = *AtEndBinary--;
            
            // Convert the ASCII binary to binary.
            if( b == '1' )
            {
                a |= j;
            }
        }
        
        // Save the octal digit.
        *AtEndOctal-- = OctalDigit[ a ];
    }
    
    // Append a string terminator.
    AtOctal[ OctalCount ] = 0;
}

/*------------------------------------------------------------
| ConvertASCIIHexDigitToInteger
|-------------------------------------------------------------
|
| PURPOSE: To convert an ASCII hexidecimal digits to 
|          an equivalent binary integer. 
|
| DESCRIPTION:  
|
| EXAMPLE: n = ConvertASCIIHexDigitToInteger( 'f' );
|
| NOTE:  
|
| ASSUMES: Hex digits may be upper or lower case.
|
| HISTORY: 03.04.97
------------------------------------------------------------*/
s32
ConvertASCIIHexDigitToInteger( s32 H )
{
    if( H <= '9' )
    {
        return( H - '0' );
    }
    
    // Either 'A-F' or 'a-f'.
    if( H <= 'F' )
    {
        return( 10 + ( H - 'A' ) );
    }
    else // Lower case.
    {
        return( 10 + ( H - 'a' ) );
    }
}
          
/*------------------------------------------------------------
| ConvertUHiHexToUHiBin
|-------------------------------------------------------------
|
| PURPOSE: To convert high-order-first unsigned ASCII 
|          hexidecimal digits to an equivalent string of 
|          high-order-first ASCII binary digits. 
|
| DESCRIPTION: Handles upper and lower case hex digits.
|
| May produce insignificant leading zeros.
|
|       ConvertUHiHexToUHiBin( "FfEb9", AtBinary );
|
| EXAMPLE: 
|
| NOTE: Result is four times as long as the source.
|
| ASSUMES: Hex digits may be upper or lower case.
|
|          Source and destination buffers may be the same.
|
| HISTORY: 03.22.97 from 'ConvertULoHexToULoBin'. Tested.
------------------------------------------------------------*/
void
ConvertUHiHexToUHiBin( s8* AtHex, s8* AtBinary )
{
    s8   h;
    s32  n, i;
    s8   C[512];
    s8*  H;
    
    // Refer to the source.
    H = AtHex;
    
    // If the source and destination are the same.
    if( AtHex == AtBinary )
    {
        // Preserve the source value.
        CopyString( AtHex, C );
    
        H = C;
    }
    
    while( *H )
    {
        h = *H++;
        
        n = ConvertASCIIHexDigitToInteger( h );
        
        for( i = 8; i; i >>= 1 )
        {
            if( n & i )
            {
                *AtBinary++ = '1';
            }
            else
            {
                *AtBinary++ = '0';
            }
        }
    }
    
    // Append the string terminator.
    *AtBinary = 0;
}

/*------------------------------------------------------------
| ConvertULoHexToULoBin
|-------------------------------------------------------------
|
| PURPOSE: To convert low-order-first unsigned ASCII 
|          hexidecimal digits to an equivalent string of 
|          low-order-first ASCII binary digits. 
|
| DESCRIPTION: Handles upper and lower case hex digits.
|
| May produce insignificant zeros in high-order digits. 
|
|       ConvertULoHexToULoBin( "FfEb9", AtBinary );
|
| EXAMPLE: 
|
| NOTE: Result is four times as long as the source.
|
| ASSUMES: Hex digits may be upper or lower case.
|
|          Source and destination buffers may be the same.
|
| HISTORY: 03.22.97 Tested.
------------------------------------------------------------*/
void
ConvertULoHexToULoBin( s8* AtHex, s8* AtBinary )
{
    s8   h;
    s32  n, i;
    s8   C[512];
    s8*  H;
    
    // Refer to the source.
    H = AtHex;
    
    // If the source and destination are the same.
    if( AtHex == AtBinary )
    {
        // Preserve the source value.
        CopyString( AtHex, C );
    
        H = C;
    }
    
    while( *H )
    {
        h = *H++;
        
        n = ConvertASCIIHexDigitToInteger( h );
        
        for( i = 1; i < 16; i <<= 1 )
        {
            if( n & i )
            {
                *AtBinary++ = '1';
            }
            else
            {
                *AtBinary++ = '0';
            }
        }
    }
    
    // Append the string terminator.
    *AtBinary = 0;
}

/*------------------------------------------------------------
| ConvertULoBinToULoDec
|-------------------------------------------------------------
|
| PURPOSE: To convert string of low-order-first ASCII  
|          binary digits to an equivalent string of 
|          low-order-first ASCII decimal digits. 
|
| DESCRIPTION:  
|
|    ConvertULoBinToULoDec( "110101", AtDec );
|
| EXAMPLE: 
|
| NOTE: Result is roughly a quarter as long as the source.
|
| ASSUMES: Less than 1200 digits in the binary number.
|
|          Source and destination buffers may be the same.
|
| HISTORY: 03.20.97 from 'ConvertULoDecToULoBin'. Tested.
|          03.22.97 revised to allow source and destination
|                   to be the same. Tested.
------------------------------------------------------------*/
void
ConvertULoBinToULoDec( s8* B, s8* D )
{
    s8  C[1200];
    s8* BEnd;
    s8* b;
    
    // Refer to the source.
    b = B;
    
    // Copy the source string if the source and destination
    // are the same.
    if( B == D )
    {
        CopyString( B, C );
        b = C;
    }
    
    // Start with zero in the accumulator 'X'.
    D[0] = '0';
    D[1] = 0;
 
    // Locate the high-order digit of the binary number.
    BEnd = AddressOfLastCharacterInString( b );

    while( BEnd >= b )
    {
        // Multiply the accumulator by two to make
        // room for the value of the next binary digit.
        ShortMultiplyULoDec( D, D, '2' );
        
        if( *BEnd-- == '1' )
        {
            AddULoDec( (s8*) D, (s8*) D, (s8*) "1" );
        }
    }
}

/*------------------------------------------------------------
| ConvertULoBinToULoHex
|-------------------------------------------------------------
|
| PURPOSE: To convert string of low-order-first ASCII  
|          binary digits to an equivalent string of 
|          low-order-first ASCII hexadecimal digits. 
|
| DESCRIPTION:  
|
|    ConvertULoBinToULoHex( "110101", AtHex );
|
| EXAMPLE: 
|
| NOTE: Result is roughly a quarter as long as the source.
|
| ASSUMES: Less than 512 digits in the binary number.
|
|          Source and destination buffers may be the same.
|
|          Hex digits should be uppercase.
|
| HISTORY: 03.22.97 from 'ConvertASCIIBinaryToASCIIHex'. 
|                   Tested.
------------------------------------------------------------*/
void
ConvertULoBinToULoHex( s8* B, s8* H )
{
    s8  h, b, bit;
    s8  C[512];
    s8* BB;
    
    // Refer to the source buffer.
    BB = B;
    
    // If the source and destination are the same, make
    // a copy of the source string.
    if( B == H )
    {
        CopyString( B, C );
        
        BB = C;
    }
 
    // Reset the digit accumulator and mask.
    h   = 0;
    bit = 1;
    
    // For each binary digit.
    while( *BB )
    {
        // Get the next lowest binary gigit.
        b = *BB++;
        
        // Convert the ASCII binary to binary.
        if( b == '1' )
        {
            h |= bit;
        }
        
        // Shift the mask to left one position. 
        bit = bit << 1;
        
        // If four bits have been accumulated.
        if( bit == 16 )
        {
            // Move hex digit to the result.
            *H++ = HexDigit[ h ];
                
            // Reset the digit accumulator.
            h   = 0;
            bit = 1;
        }
    }
    
    // If there is a remainder.
    if( bit > 1 )
    {
        // Move hex digit to the result.
        *H++ = HexDigit[ h ];
    }
    
    // Add the string terminator.
    *H = 0;
}

/*------------------------------------------------------------
| ConvertULoBinToULoOct
|-------------------------------------------------------------
|
| PURPOSE: To convert string of low-order-first ASCII  
|          binary digits to an equivalent string of 
|          low-order-first ASCII octal digits. 
|
| DESCRIPTION:  
|
|    ConvertULoBinToULoOct( "110101", AtHex );
|
| EXAMPLE: 
|
| NOTE: Result is roughly a third as long as the source.
|
| ASSUMES: Less than 512 digits in the binary number.
|
|          Source and destination buffers may be the same.
|
| HISTORY: 03.22.97 from 'ConvertULoBinToULoHex'. 
|                   Tested.
------------------------------------------------------------*/
void
ConvertULoBinToULoOct( s8* B, s8* AtOct )
{
    s8  h, b, bit;
    s8  C[512];
    s8* BB;
    
    // Refer to the source buffer.
    BB = B;
    
    // If the source and destination are the same, make
    // a copy of the source string.
    if( B == AtOct )
    {
        CopyString( B, C );
        
        BB = C;
    }
 
    // Reset the digit accumulator and mask.
    h   = 0;
    bit = 1;
    
    // For each binary digit.
    while( *BB )
    {
        // Get the next lowest binary gigit.
        b = *BB++;
        
        // Convert the ASCII binary to binary.
        if( b == '1' )
        {
            h |= bit;
        }
        
        // Shift the mask to left one position. 
        bit = bit << 1;
        
        // If three bits have been accumulated.
        if( bit == 8 )
        {
            // Move hex digit to the result.
            *AtOct++ = OctalDigit[ h ];
                
            // Reset the digit accumulator.
            h   = 0;
            bit = 1;
        }
    }
    
    // If there is a remainder.
    if( bit > 1 )
    {
        // Move hex digit to the result.
        *AtOct++ = OctalDigit[ h ];
    }
    
    // Add the string terminator.
    *AtOct = 0;
}

/*------------------------------------------------------------
| ConvertULoDecToULoBin
|-------------------------------------------------------------
|
| PURPOSE: To convert string of low-order-first ASCII decimal
|          binary digits to an equivalent string of 
|          low-order-first ASCII binary digits. 
|
| DESCRIPTION:  
|
|    ConvertULoDecToULoBin( "12345", AtBin );
|
| EXAMPLE: 
|
| NOTE: Result is roughly four times as long as the source.
|
| ASSUMES: Less than 512 digits in decimal number.
|
|          Source and destination buffers may be the same.
|
| HISTORY: 03.15.97 
|          03.20.97 tested.
------------------------------------------------------------*/
void
ConvertULoDecToULoBin( s8* D, s8* B )
{
    s8  X[512];
    s8  Y[512];
    
    // Duplicate the input string.
    CopyString( D, X );

Another:
    
    if( IsOddULoDec( X ) )
    {
        *B++ = '1';
    }
    else
    {
        *B++ = '0';
    }
        
    DivideByTwoULoDec( Y, X );
    
    // If no more digits to go. 
    if( CompareULoDec( (s8*) Y, (s8*) "0" ) == 0 )
    {
        goto Done;
    }
    
    if( IsOddULoDec( Y ) )
    {
        *B++ = '1';
    }
    else
    {
        *B++ = '0';
    }
        
    DivideByTwoULoDec( X, Y );
    
    // If the current result is non-zero.
    if( CompareULoDec( (s8*) X, (s8*) "0" ) )
    {
        goto Another;
    }

Done:
    
    // Append string terminator.
    *B = 0;
}

/*------------------------------------------------------------
| DivideULoDec
|-------------------------------------------------------------
|
| PURPOSE: To divide one unsigned integer expressed as 
|          ASCII low-order-first decimal string by another.
|
| DESCRIPTION: Result = A / B.
|
| Uses a binary search which depends on calculating trial
| products.  There's probably a faster way to do this most
| likely to convert to binary and perform the division
| in binary the convert back to decimal.
|
|       Quotient = Dividend / Divisor
| 
| Dividend : number to be divided
| Divisor : number of times to divide another number
|
| EXAMPLE:
| 
|     DivideULoDec( &Result, "238521", "293" );
|
|     Result: "123" 
|
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer may be one or both of the sources.
|
|          The low-order digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
|          Result is less than 512 digits.
|
| HISTORY: 03.15.97 tested.
|          03.22.97 revised to allow source and destination
|                   to be the same. Tested.
------------------------------------------------------------*/
void
DivideULoDec( s8* Result, s8* A, s8* B )
{
    s8  Hi[512];
    s8  Lo[512];
    s8  Work[512];
    s8  Rem[512];
    s8  Q[512];
    s32 c;

    // Determine the relative sizes of the dividend and
    // the divisor.
    c = CompareULoDec( A, B );
    
    // If the divisor is larger than the dividend then the
    // result is zero.
    if( c < 0 )
    {
        Result[0] = '0';
        Result[1] = 0;
        
        return;
    }
    
    // If the divisor is equal to the dividend then the
    // result is one.
    if( c == 0 )
    {
        Result[0] = '1';
        Result[1] = 0;
        
        return;
    }
    
    // If get this far then the divisor is smaller than the
    // dividend.
    
    // Use binary search for the result.
    CopyString( A,   Hi );
    CopyString( (s8*) "1", (s8*) Lo );
        
    while( 1 ) 
    {
        // Calculate the mid point.
        AddULoDec( Work, Lo, Hi );
        DivideByTwoULoDec( Q, Work );
        
        // Make a trial product using the midpoint.
        MultiplyULoDec( Work, Q, B );
        
        // Compare the trial product to the dividend.
        c = CompareULoDec( A, Work );

        if( c == 0 )
        {
            // Exact match.
            CopyString( Q, Result );
            
            return;
        }

        // If the trial product is too big.
        if( c < 0 ) 
        {
            // Reduce the upper bound.
            //
            // Hi = Mid - 1;
            SubtractULoDec( (s8*) Hi, (s8*) Q, (s8*) "1" );
        }
        else // Trial product is less than the dividend.
        {
            // Compute the remainder.
            SubtractULoDec( Rem, A, Work );
            
            // If the remainder is less than the divisor
            // then return.
            if( CompareULoDec( Rem, B ) < 0 )
            {
                CopyString( Q, Result );
                
                return;
            }
            else // Increase the lower bound.
            {
                // Lo = Mid + 1;
                AddULoDec( Lo, Q, (s8*) "1" );
            }
        }
    }
}

/*------------------------------------------------------------
| DivideByTwoULoDec
|-------------------------------------------------------------
|
| PURPOSE: To divide by two an unsigned integer expressed as 
|          ASCII low-order-first decimal string.
|
| DESCRIPTION: Result = A / 2.
|
|       Quotient = Dividend / Divisor
| 
| Dividend : number to be divided
| Divisor  : number of times to divide another number
|
| EXAMPLE:
| 
|     DivideByTwoULoDec( &Result, "238521" );
|
|     Result: "61926" 
|
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer may be the source.
|
|          The low-order digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
|          Result is less than 512 digits.
|
|          No insignificant zeros in 'A'.
|
| HISTORY: 03.15.97 tested.
|          03.22.97 revised to allow source to be destination.
|                   Tested.
------------------------------------------------------------*/
void
DivideByTwoULoDec( s8* Result, s8* A )
{
    s32 a, r;
    s8* AEnd;
    s8* R;
    s8  C[512];
    s8* AA;
    
    // Refer to the source string indirectly.
    AA = A;
    
    // If the result is source A, then make a copy of A
    // first.
    if( Result == A )
    {
        CopyString( A, C );
        AA = C;
    }
    
    // Locate the high-order digit of the dividend.
    AEnd = AddressOfLastCharacterInString( AA );

    // Refer to the location of the last digit in the result.
    R = Result + (AEnd - AA);
    
    // If multiple digits and the high order digit is '1' 
    // then avoid making an insignificant zero.
    if( (AEnd > AA) && ( *AEnd == '1' ) )
    {
        // Make string terminator for result.
        *R-- = 0;
        AEnd--;
        
        // Scaled remainder is 10.
        r = 10;
    }
    else // High-order digit of quotient will be non-zero 
         // or zero is the result.
    {
        // Make a string terminator for result.
        R[1] = 0;
        
        // Clear the remainder.
        r = 0;
    }
    
    // While digits remain to divide.
    while( AEnd >= AA )
    {
        // Get a digit.
        a = (*AEnd--) - '0';
        
        // Calculate the quotient digit.
        *R-- = ( (a + r) >> 1 ) + '0';
        
        // Set the scaled remainder, if any.
        if( a & 1 )
        {
            r = 10;
        }
        else
        {
            r = 0;
        }
    }
}

/*------------------------------------------------------------
| DivideWithRemainderULoDec
|-------------------------------------------------------------
|
| PURPOSE: To divide one unsigned integer expressed as 
|          ASCII low-order-first decimal string by another.
|
| DESCRIPTION: Result = A / B.
|
|       Quotient  = Dividend / Divisor
|       Remainder = Dividend % Divisor
| 
| Dividend : number to be divided
| Divisor : number of times to divide another number
|
| EXAMPLE:
| 
|     DivideWithRemainderULoDec( &Q, &R, "238521", "293" );
|
|     Result: Q = "123" R = "0".
|
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffers may be the sources.
|
|          The low-order digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
|          Result is less than 512 digits.
|
| HISTORY: 03.15.97
|          03.22.97 revised to allow destinations to be the
|                   source buffers.
------------------------------------------------------------*/
void
DivideWithRemainderULoDec( s8* Q, s8* R, s8* A, s8* B )
{
    s8  Hi[512];
    s8  Lo[512];
    s8  Work[512];
    s8  q[512];
    s8  r[512];
    
    s32 c;
    
    // Determine the relative sizes of the dividend and
    // the divisor.
    c = CompareULoDec( A, B );
    
    // If the divisor is larger than the dividend then the
    // result is zero.
    if( c < 0 )
    {
        Q[0] = '0';
        Q[1] = 0;
        
        // Remainder is the divisor.
        CopyString( B, R );
        
        return;
    }
    
    // If the divisor is equal to the dividend then the
    // result is one.
    if( c == 0 )
    {
        Q[0] = '1';
        Q[1] = 0;
        
        R[0] = '0';
        R[1] = 0;
        
        return;
    }
    
    // If get this far then the divisor is smaller than the
    // dividend.

    // Use binary search for the result.
    CopyString( A,   Hi );
    CopyString( (s8*) "1", Lo );
        
    while( 1 ) 
    {
        // Calculate the mid point.
        AddULoDec( Work, Lo, Hi );
        
        DivideByTwoULoDec( q, Work );
        
        // Make a trial product using the midpoint.
        MultiplyULoDec( Work, q, B );
        
        // Compare the trial product to the dividend.
        c = CompareULoDec( A, Work );

        if( c == 0 )
        {
            // Exact match.
            CopyString( q, Q );
            
            R[0] = '0';
            R[1] = 0;
            
            return;
        }

        // If the trial product is too big.
        if( c < 0 ) 
        {
            // Reduce the upper bound.
            //
            // Hi = Mid - 1;
            SubtractULoDec( Hi, q, (s8*) "1" );
        }
        else // Trial product is less than the dividend.
        {
            // Compute the remainder.
            SubtractULoDec( r, A, Work );
            
            // If the remainder is less than the divisor
            // then return.
            if( CompareULoDec( r, B ) < 0 )
            {
                CopyString( q, Q );
                CopyString( r, R );
                
                return;
            }
            else // Increase the lower bound.
            {
                // Lo = Mid + 1;
                AddULoDec( Lo, q, (s8*) "1" );
            }
        }
    }
}

/*------------------------------------------------------------
| IsOddULoDec
|-------------------------------------------------------------
|
| PURPOSE: To test if an unsigned integer expressed as 
|          ASCII low-order-first decimal string is an odd 
|          number.
|
| DESCRIPTION: Returns non-zero if the number is odd, else
| returns 0.
|
| EXAMPLE:
| 
|     t = IsOddULoDec( &Result, "238521" );
|
|     t: 0
|
| NOTE:  
|
| ASSUMES: The low-order digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
| HISTORY: 03.15.97 
------------------------------------------------------------*/
u32  
IsOddULoDec( s8* A )
{
    s8  n;
    
    n = *A - '0';
    
    return( n & 1 );
}

/*------------------------------------------------------------
| ModuloULoDec
|-------------------------------------------------------------
|
| PURPOSE: To calculate the remainder of dividing one unsigned 
|          integer expressed as ASCII low-order-first decimal 
|          string by another.
|
| DESCRIPTION: Result = A % B.
|
| EXAMPLE:
| 
|     ModuloULoDec( &Result, "338521", "293" );
|
|     Result: "1" 
|
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer may be one of the sources.
|
|          The low-order digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
|          Result is less than 512 digits.
|
| HISTORY: 03.15.97 
|          03.22.97 revised to allow destination to be source.
|                   Tested.
------------------------------------------------------------*/
void
ModuloULoDec( s8* Result, s8* A, s8* B )
{
    s8  Hi[512];
    s8  Mid[512];
    s8  Lo[512];
    s8  Work[512];
    s8  R[512];
    
    s32 c;
    
    // Determine the relative sizes of the dividend and
    // the divisor.
    c = CompareULoDec( A, B );
    
    // If the divisor is larger than the dividend then the
    // result is the divisor.
    if( c < 0 )
    {
        CopyString( B, Result );
        
        return;
    }
    
    // If the divisor is equal to the dividend then the
    // result is zero.
    if( c == 0 )
    {
        Result[0] = '0';
        Result[1] = 0;
        
        return;
    }
    
    // If get this far then the divisor is smaller than the
    // dividend.
    
    // Use binary search for the result.
    CopyString( A,   Hi );
    CopyString( (s8*) "1", Lo );
        
    while( 1 ) 
    {
        // Calculate the mid point.
        AddULoDec( Work, Lo, Hi );
        
        DivideByTwoULoDec( Mid, Work );
        
        // Make a trial product using the midpoint.
        MultiplyULoDec( Work, Mid, B );
        
        // Compare the trial product to the dividend.
        c = CompareULoDec( A, Work );

        if( c == 0 )
        {
            // Exact match, nothing left over.
            
            Result[0] = '0';
            Result[1] = 0;
            
            return;
        }

        // If the trial product is too big.
        if( c < 0 ) 
        {
            // Reduce the upper bound.
            //
            // Hi = Mid - 1;
            SubtractULoDec( Hi, Mid, (s8*) "1" );
        }
        else // Trial product is less than the dividend.
        {
            // Compute the remainder.
            SubtractULoDec( R, A, Work );
            
            // If the remainder is less than the divisor
            // then return.
            if( CompareULoDec( R, B ) < 0 )
            {
                CopyString( R, Result );
                
                return;
            }
            else // Increase the lower bound.
            {
                // Lo = Mid + 1;
                AddULoDec( Lo, Mid, (s8*) "1" );
            }
        }
    }
}

/*------------------------------------------------------------
| MultiplyULoDec
|-------------------------------------------------------------
|
| PURPOSE: To multiply two unsigned integers expressed as 
|          ASCII low-order-first decimal strings.
|
| DESCRIPTION: Result = A * B.
|
| EXAMPLE:
| 
|   MultiplyULoDec( &Result, "123", "293" );
|
|   Result: "238521", which is "125832" as high-order first.
|
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer may be one of the sources.
|
|          The low-order digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
|          Result is less than 512 digits.
|
| HISTORY: 03.15.97 tested.
|          03.22.97 removed wasted copy motion; allowed
|                   result buffer to be one or both of the 
|                   sources. Tested.
------------------------------------------------------------*/
void
MultiplyULoDec( s8* Result, s8* A, s8* B )
{
    s32     t;
    s8      Work[512];
    s8      C[512];
    s8*     a;
    s8*     b;
    
    // Refer to the source strings indirectly.
    a = A;
    b = B;
    
    // If the result is source A, then make a copy of A
    // first.
    if( Result == A )
    {
        CopyString( A, C );
        a = C;
    }
    
    // If the result is source B, then make a copy of B
    // first.
    if( Result == B )
    {
        if( A != B )
        {
            CopyString( B, C );
        }
        
        b = C;
    }
    
    // Clear the power of ten.
    t = 0;
    
    // While there are digits to multiply.
    while( *b )
    {
        // If not the first digit.
        if( t )
        {
            // Multiply the first number by a digit from the
            // second number.
            ShortMultiplyULoDec( Work, a, *b );
        
            // Align the intermediate result using the power
            // of ten.
            TimesPowerOfTenULoDec( Work, Work, t );
        
            // Accumulate the partial product.
            AddULoDec( Result, Result, Work );
        }
        else // First digit.
        {
            // Multiply the first number by the lowest order
            // digit from the second number.
            ShortMultiplyULoDec( Result, a, *b );
        }
        
        // Advance to the next digit.
        b++;
        t++;
    }
}

/*------------------------------------------------------------
| ShortMultiplyULoDec
|-------------------------------------------------------------
|
| PURPOSE: To multiply an unsigned integer expressed as ASCII 
|          low-order-first decimal string by a single ASCII
|          digit.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|           ShortMultiplyULoDec( &Result, "123", '2' );
|
|           Result: "246", or "642" as high-order first.
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer may also be the source.
|
|          The least significant digit is first.
|
|          String contains only ASCII decimal digits and are 
|          not empty. 
|
| HISTORY: 03.15.97 tested.
|          03.22.97 revised to allow source and destination
|                   to be the same buffer. Tested.
------------------------------------------------------------*/
void
ShortMultiplyULoDec( s8* Result, s8* A, s32 B )
{
    s8* R;
    s8  a,b,c,r;
    s32 DigitCount;
    
    // Convert the ASCII digit to binary.
    b = B - '0';
    
    // Refer to the first byte in the result buffer.
    R = Result;
    
    // Clear the carry digit.
    c = 0;
    
    // Count the number of digits in the multiplicand.
    DigitCount = CountString( A );
    
    // While there are digits to multiply.
    while( DigitCount-- )
    {
        // Get the remaining low-order 'A' digit and convert 
        // to binary.
        a = (*A++) - '0';
        
        // Calculate the result digit bundled with carry.
        r = a * b + c;
        
        // Separate result digit from carry.
        if( r > 9 )
        {
            c = r / 10;
            r = r % 10;
        }
        else // No carry out.
        {
            c = 0;
        }
        
        // Convert result digit to ASCII and save.
        *R++ = r + '0';
    }
    
    // If there is a carry, add another digit to the result.
    if( c )
    {
        *R++ = c + '0';
    }

    // Drop any insignificant zeros.
    R--;
    while( (*R == '0') && (R > Result) )
    {
        R--;
    }
    R++;
    
    // Append a string terminator to the result.
    *R = 0;
}

/*------------------------------------------------------------
| SubtractASCIIDecimal
|-------------------------------------------------------------
|
| PURPOSE: To subtract two unsigned integers expressed as  
|          ASCII decimal strings.
|
| DESCRIPTION: Result = A - B. 
|
| EXAMPLE: 
|           SubtractASCIIDecimal( &Result, "2930", "123" );
|
| NOTE: May produce leading zeros.
|
| ASSUMES: A >= B.
|
|          Result buffer is large enough for the result.
|
|          Result buffer isn't one of the sources.
|
|          The most significant digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
| HISTORY: 03.08.97 Tested.
------------------------------------------------------------*/
void
SubtractASCIIDecimal( s8* Result, s8* A, s8* B )
{
    s8* AEnd;
    s8* BEnd;
    s8* R;
    s8  a,b,c,r;
    
    // Refer to the first byte in the result buffer.
    R = Result;
    
    // Locate the low-order digits of the inputs.
    AEnd = AddressOfLastCharacterInString( A );
    BEnd = AddressOfLastCharacterInString( B );
    
    // Clear the carry digit.
    c = 0;
    
    // While there are digits to subtract.
    while( (AEnd >= A) || (BEnd >= B) )
    {
        // Get the remaining low-order 'A' digit and convert 
        // to binary.
        if( AEnd >= A )
        {
            a = (*AEnd--) - '0';
        }
        else // No more source digits: use 0.
        {
            a = 0;
        }
    
        // Get the remaining low-order 'B' digit and convert 
        // to binary.
        if( BEnd >= B )
        {
            b = (*BEnd--) - '0';
        }
        else // No more source digits: use 0.
        {
            b = 0;
        }
        
        // Calculate the result digit.
        
        // If carry-adjusted minuend is larger than the
        // subtrahend.
        if( (a - c) >= b )
        {
            r = (a - c) - b;
            
            // Absorb the borrow flag.
            c = 0;
        }
        else // Need to borrow.
        {
            r = ( (a - c) + 10 ) - b;
            
            // Propagate the borrow.
            c = 1;
        }
        
        // Convert result digit to ASCII and save.
        *R++ = r + '0';
    }
    
    // If there is a carry, then an error because B > A.
    if( c )
    {
        Debugger();
    }
    
    // Drop any insignificant zeros.
    R--;
    while( (*R == '0') && (R > Result) )
    {
        R--;
    }
    R++;
    
    // Append a string terminator to the result.
    *R = 0;
    
    // Reverse the result string to make high-order digit
    // first.
    ReverseString( Result );
}
        
/*------------------------------------------------------------
| SubtractULoDec
|-------------------------------------------------------------
|
| PURPOSE: To subtract two unsigned integers expressed as  
|          ASCII low-order-first decimal strings.
|
| DESCRIPTION: Result = A - B. 
|
| EXAMPLE: 
|           SubtractULoDec( &Result, "123", "1" );
|
|           Result: "023", which is "320" high-order first.
|
| NOTE: Drops insignificant zeros.
|
| ASSUMES: A >= B.
|
|          Result buffer is large enough for the result.
|
|          Result buffer may be one of the sources.
|
|          The least significant, low-order digit is first.
|
|          Strings contain only ASCII decimal digits and are 
|          not empty. 
|
| HISTORY: 03.12.97 tested.
|          03.22.97 revised to allow sources and destination
|                   to be the same.
------------------------------------------------------------*/
void
SubtractULoDec( s8* Result, s8* A, s8* B )
{
    s8* R;
    s8  a,b,c,r;
    s32 DigitCount, ADigitCount, BDigitCount;
    
    // Refer to the first byte in the result buffer.
    R = Result;
    
    // Clear the carry digit.
    c = 0;
    
    // Count the number of digits in the two sources.
    ADigitCount = CountString( A );
    BDigitCount = CountString( B );
    
    // Select the count of the longer string.
    DigitCount = max( ADigitCount, BDigitCount );
    
    // While there are digits to subtract.
    while( DigitCount-- )
    {
        // Get the remaining low-order 'A' digit and convert 
        // to binary.
        if( ADigitCount )
        {
            ADigitCount--;
            
            a = (*A++) - '0';
        }
        else // No more source digits: use 0.
        {
            a = 0;
        }
    
        // Get the remaining low-order 'B' digit and convert 
        // to binary.
        if( BDigitCount )
        {
            BDigitCount--;
            
            b = (*B++) - '0';
        }
        else // No more source digits: use 0.
        {
            b = 0;
        }
        
        // Calculate the result digit.
        
        // If carry-adjusted minuend is larger than the
        // subtrahend.
        if( (a - c) >= b )
        {
            r = (a - c) - b;
            
            // Absorb the borrow flag.
            c = 0;
        }
        else // Need to borrow.
        {
            r = ( (a - c) + 10 ) - b;
            
            // Propagate the borrow.
            c = 1;
        }
        
        // Convert result digit to ASCII and save.
        *R++ = r + '0';
    }
    
    // If there is a carry, then an error because B > A.
    if( c )
    {
        Debugger();
    }
    
    // Drop any insignificant zeros.
    R--;
    while( (*R == '0') && (R > Result) )
    {
        R--;
    }
    R++;
    
    // Append a string terminator to the result.
    *R = 0;
}
    
/*------------------------------------------------------------
| TimesPowerOfTenULoDec
|-------------------------------------------------------------
|
| PURPOSE: To multiply an unsigned integer expressed as 
|          ASCII low-order-first decimal string times a given
|          power of ten.
|
| DESCRIPTION: Multiply number times 10^n, where n is the 
| ends up being the number of zeros to insert at the low
| order end if 'n' is positive.  If 'n' is negative, n is 
| how many low-order digits are deleted.
|
| EXAMPLE: 
|
| A:            
|    TimesPowerOfTenULoDec( &Result, "123", 2 );
|
|    Result: "00123" 
|
| B:
|    TimesPowerOfTenULoDec( &Result, "123", -2 );
|
|    Result: "3" 
|
| NOTE:  
|
| ASSUMES: Result buffer is large enough for the result.
|
|          Result buffer may be one of the sources.
|
|          The least significant digit is first.
|
|          String contains only ASCII decimal digits and is 
|          not empty. 
|
| HISTORY: 03.15.97 tested.
|          03.22.97 revised to allow source and destination
|                   buffers to be the same. Tested.
------------------------------------------------------------*/
void
TimesPowerOfTenULoDec( s8* Result, s8* A, s32 n )
{
    
    if( n == 0 ) 
    {
        MoveString( A, Result );
    }
     
    if( n > 0 )
    {
        // Copy possibly overlapping source string to the
        // result buffer at offset 'n'.
        MoveString( A, Result + n );

        // Prefix source digits with 'n' zeros at the result 
        // buffer.
        while( n-- )
        {
            *Result++ = '0';
        }
    }
    else // Truncate 'n' digits.
    {
        // If there aren't any digits left the result is "0".
        if( CountString( A ) < (-n) )
        {
            *Result++ = '0';
            *Result   = 0;
        }
        else // Drop 'n' digits.
        {
            MoveString( &A[-n], Result );
        }
    }
}
        
    
    
