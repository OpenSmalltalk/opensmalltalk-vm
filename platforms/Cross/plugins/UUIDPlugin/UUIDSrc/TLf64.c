/*------------------------------------------------------------
| TLf64.c
|-------------------------------------------------------------
|
| PURPOSE: To provide 64-bit floating point number functions.
|
| DESCRIPTION: 
|
| HISTORY: 02.05.00 From 'TLNumber.c'.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"
#include "TLAscii.h"
#include "TLStrings.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"

#include "TLf64.h"
    
/*------------------------------------------------------------
| Chop 
|-------------------------------------------------------------
|
| PURPOSE: To replace a number with a magnitude less than 
|          'ChopTolerance' with zero.
|
| DESCRIPTION:  
|
| EXAMPLE:    v = Chop( v );
|
| NOTE: From p. 541 of Mathematica.
|
| ASSUMES:  
|           
| HISTORY: 04.04.96 from 'ChopItems'.
|          04.29.96 replaced 'fabs' call with faster test.
------------------------------------------------------------*/
f64
Chop( f64 v )
{
    f64 x;
    
    x = ( v < 0 ) ? -v : v;
        
    if( x < ChopTolerance )
    {
        return( 0 );
    }
    else
    {
        return( v );
    }
}

/*------------------------------------------------------------
| Compare
|-------------------------------------------------------------
|
| PURPOSE: To compare two numbers to produce a relation number.
|
| DESCRIPTION:  
|
| EXAMPLE:   
|
| NOTE: See also 'CompareItems' a similar routine for use
|       with 'SortList'.
|
| ASSUMES: 
|
| HISTORY: 05.07.97 from 'Compare_fl64'.
------------------------------------------------------------*/
f64
Compare( f64 a, f64 b )
{
    if( a > b )
    {
        return( 1. );
    }
     
    if( a < b )
    {
        return( -1. );
    }
 
    return( 0. );
}

/*------------------------------------------------------------
| Convertf64ToString
|-------------------------------------------------------------
|
| PURPOSE: To convert a f64 to ASCII string format.
|
| DESCRIPTION: Produces a number string formatted like this:
|
|             [-] [digits] [.digits]
|
| for example,  "123.0002", "23", "0", "-17.89"...
|
| ...such that all digits are decimal digits.
|
| Non-numeric values may also be encoded as f64s.  
|
| Their string output format is as follows:
|
|     "INF".................... Positive infinity.
|
|     "-INF"................... Negative infinity.
|
|     "NAN(035)"............... Not-a-number with various
|                               NaN code numbers.
|
|     "-123456789.987654321"... Missing number, "NoNum", 
|                               (not IEEE754 standard).
| EXAMPLE: 
|
|     ByteCount = Convertf64ToString( 123.23, &Buffer );
|
| NOTE: See p. 31 of 'Apple Numerics Manual,2nd Ed.' (ANM).
|
| I don't care what the bozos who wrote IEEE754 say, zero is 
| never output with a sign because NOTHING has no direction, 
| it's just a placeholder.
|
| ASSUMES: 
|
| HISTORY: 02.06.00 From 'ConvertNumberToString()'.
------------------------------------------------------------*/
            // OUT: Number of bytes in the result string
            //      not counting the terminal zero byte.
            //      Returns zero if the buffer isn't big
u32         //      enough.
Convertf64ToString( 
    f64 n,  // The input number.
            //
    s8* s,  // The output string buffer.
            //
    u32 BufferSize )
            // Number of bytes available in the string buffer.
{
    n = n;
    s = s;
    BufferSize = BufferSize;
#if 0 // under construction...
    BitCursor   B;
    s8          IntegerBits[ 1100 ];
    s8          IntegerDecimalDigits[ 400 ];
    u8          FractionBits[ 1100 ];
    
    s32         IntegerBitCount;
    s32         FractionBitCount;
   
    u8*         AtOutputByte;
    s32         DigitsToLeftOfDecimal;
    s32         DigitsToRightOfDecimal;
    u16         ExponentByteCount;
    u8          SigDigitCount;
    s32         SigDigitsToLeftOfDecimal;
    s32         SigDigitsToRightOfDecimal;
    u8          TheSign;
    u8          TheDecimalPoint; 
    s16         TheExponent;
    u8*         TheDigits;
    s32         SigZerosAppendedToLeft;
    s32         SigZerosPrependedToRight;
    s32         SigZerosAppendedToRight;
    s32         DecimalPointDisplacement;
    u32         DegradeFromFixed;
    u32         DegradeToSci;
    u8          Carry;
    u8          Round;
    s8*         z;
    u16         LastDigitIndex;
    Number      PlacesForANumber;
    ParsedNumberString  Q;
    Parsedf64           P;
    
    // Parse the input number into parts.
    Parsef64( &n, &P ); 
    
    // Refer to 'z' as a cursor for the output string.
    z = s;
    
    // If the input number is zero.
    if( P.e == 0 && P.f == 0 )
    {
        // Make a string for zero.
        *z++ = '0';
        *z = 0;
        
        // There is one character in the string.
        return( z - s );
    }

    // If the number is an infinity or NaN.
    if( P.e == 2047 )
    {
        // If the number is an infinity.
        if( P.f == 0 )
        {
            // If negative infinity.
            if( P.s )
            {
                // Output a leading minus sign.
                *z++ = '-';
            }
            
            // Output the mnemonic 'INF'
            *z++ = 'I';
            *z++ = 'N';
            *z++ = 'F';
        }
        else // The number is a 'NAN'.
        {
            // Output the mnemonic 'NAN'
            *z++ = 'N';
            *z++ = 'A';
            *z++ = 'N';
            
            // We could identify the NaN code here 
            // and whether it is a quiet or signalling
            // Nan, but for now don't bother.
        }
        
        // Append the string terminator.
        *z = 0;
        
        // Return the size of the output symbol.
        return( z - s );
    }
    
    // If a negative value.
    if( P.s )
    {
        // Output a leading minus sign.
        *z++ = '-';
    }
    
    // The number of bits to the right of the binary 
    // point prior to exponent adjustment is the
    // size of the fraction field.  This includes
    // insignificant trailing zero bits.
    FractionBitCount = f64_f_size;
    
    // If the number is denormalized.
    if( P.e == 0 )
    {
        // Classify the type of number format as 
        // denormalized.
        IsNormalized = 0;
        
        // NOTE: A denormalized number results in a very 
        // small number with lots of significant zeros to 
        // the right of the decimal point, like this...
        //
        //         .0000000000000...00023425
        //
        // To be economical with output space this number
        // could be output in exponential form or clipped
        // to zero, but this routine does neither of those
        // things.
       
        // Set the binary exponent.
        BinaryExponent = -1022;
        
        // The fraction field holds all the significan bits.
        SigBits = P.f;
        
        // Begin with the assumption that all bits in the
        // fraction field are significant.
        SigBitCount = FractionBitCount;
    }
    else // The number is normalized.
    {
        // Classify the type of number format as normalized.
        IsNormalized = 1;
        
        // Calculate the binary exponent.
        BinaryExponent = P.e - 1023;
        
        // Add the implied leading one bit to the fraction part.
        SigBits = P.f | f64_i_mask;
        
        // Begin with the assumption that all bits in the
        // fraction field are significant and add the implied
        // one bit that normalized numbers have.
        SigBitCount = FractionBitCount + 1;
    }
    
    // Count the number of significant bits.
    //
    // In a binary fraction, '0' bits without any '1' bits to 
    // the right of them are insignificant, 
    //
    //   eg. 1.010101011110000000
    //                    ======= <-- insignificant bits
    //
    
    // While there are significant bits in 'SigBits' 
    // and the lowest bit is '0'.
    while( SigBits && ( ( SigBits & 1 ) == 0 ) )
    {
        // Decrement the number of significant bits.
        SigBitCount -= 1;
        
        // Decrement the number of bits to the right
        // of the binary point.
        FractionBitCount -= 1;
        
        // Shift the working fraction part to the right 
        // by one bit.
        SigBits = SigBits >> 1;
    }
    
    // At this point the least significant bit of the
    // 'SigBits' value is one and the total number of
    // significant bits is contained in 'SigBitCount'.
    //
    //                 SigBitCount
    //               |<-----13----->|
    //            eg. 1.001010101111
    //                 |<----12---->|
    //                FractionBitCount
    //
    // 'FractionBitCount' is a count of the bits to
    // the right of the binary point.
    //
    
    // Now we need to adjust the binary point using
    // the unbiased exponent value.
    
    // Calculate the number of integer bits.
    IntegerBitCount = 
        SigBitCount - FractionBitCount + BinaryExponent;
        
    // If the integer bit count is less than zero.
    if( IntegerBitCount < 0 )
    {
        // Then there are no integer bits.
        IntegerBitCount = 0;
    }
    
    // Adjust the number of fraction bits.
    //
    // For example if BinaryExponent = 3...
    //
    //            1.001010101111    BEFORE
    //              .
    //               .  3-->
    //                .
    //             1001.010101111    AFTER
    //                 |<---9--->|
    //               FractionBitCount
    //
    FractionBitCount -= BinaryExponent;
    
    // If the fraction bit count is less than zero.
    if( FractionBitCount < 0 )
    {
        // Then there are no fraction bits.
        FractionBitCount = 0;
    }
    
    // If there are integer bits.
    if( IntegerBitCount )
    {
        // Make a mask to refer to the first integer bit.
        m = 1 << ( SigBitCount - 1 );
        
        // Start with the index of the most-significant
        // bit in the integer part.
        i = IntegerBitCount - 1;
        
        // Set the string terminator.
        IntegerBits[ IntegerBitCount ] = 0;
        
        // Find the intersection between the significant
        // bits and the number of integer bits.
        
        // Until all of the integer bits in 'SigBits' have 
        // been moved to the integer part buffer.
        while( i >= 0 && m )
        {
            // If the 'm'th bit is 1.
            if( m & SigBits )
            {
                // Save '1' into the string.
                IntegerBits[i] = '1';
            }
            else // The 'm' bit is not set.
            {
                // Save '0' into the string.
                IntegerBits[i] = '0';
            }
            
            // Refer to the next bit.
            m = m >> 1;
            
            // Refer to the index of the next destination bit.
            i--;
        }
        
        // While 'i' is >= zero.
        while( i >= 0 )
        {
            // Fill in the least-significant bits with zeros.
            IntegerBits[i] = '0';
            
            // Refer to the index of the next destination bit.
            i--;
        }
        
        // Convert the binary string to decimal digits: the 
        // resulting string will be in reverse order.
        ConvertULoBinToULoDec( IntegerBits, IntegerDecimalDigits );
        
        // Count the number of decimal digits in the integer part.
        DecimalIntegerDigitCount = CountString( IntegerDecimalDigits );
    }
    else // No integer part.
    {
        // There are no decimal integer digits.
        DecimalIntegerDigitCount = 0;
    } 
.... handle fraction part here.          
    B.AtByte        = IntegerBits;
    B.AtBit         = 128;
    B.IsLowBitFirst = 0;
 
    PutBits( &B, 15 );
    
    // If the binary exponent is negative.
    if( BinaryExponent < 0 )
    {
        // Then the there are no digits to the left
        // of the decimal (binary) point.
        DigitsToLeftOfDecimal = 0;
    }
    else // 
    

NormNumber:
        
UnpackNumber:

    TheExponent   = TheDecimalRecord.exp;
    TheDigits     = (u8*) &TheDecimalRecord.sig.text;
    SigDigitCount = TheDecimalRecord.sig.length;

    PlacesForANumber = fabs( log10(ANumber) );
 
CalcDigitsToLeft:

    DigitsToLeftOfDecimal  = SigDigitCount + TheExponent;
    DigitsToRightOfDecimal = -TheExponent;
    
    SigZerosAppendedToLeft   = 0;
    SigZerosPrependedToRight = 0;
    SigZerosAppendedToRight  = 0;
    
    if( DigitsToLeftOfDecimal < 0 )
    {
        SigZerosPrependedToRight = -DigitsToLeftOfDecimal;
        DigitsToLeftOfDecimal = 0;
    }

    if( DigitsToRightOfDecimal < 0 )
    {
        SigZerosAppendedToLeft = -DigitsToRightOfDecimal;
        DigitsToRightOfDecimal = 0;
    }
        
    SigDigitsToLeftOfDecimal = DigitsToLeftOfDecimal;
    
    if( SigDigitsToLeftOfDecimal > SigDigitCount )
    {
        SigDigitsToLeftOfDecimal = SigDigitCount;
    }

    SigDigitsToRightOfDecimal = DigitsToRightOfDecimal;
    
    if( SigDigitsToRightOfDecimal > SigDigitCount )
    {
        SigDigitsToRightOfDecimal = SigDigitCount;
    }
 
         
    // Trim trailing zeros if floating point. 
    if( TheExponent < 0 && !UseFixedPointFormat )
    {
        // Remove any trailing zeros.
        while( SigDigitsToRightOfDecimal>0 &&
               TheDigits[SigDigitsToLeftOfDecimal+
                         SigDigitsToRightOfDecimal-1]
                         == '0')
        {
            SigDigitsToRightOfDecimal--;
            DigitsToRightOfDecimal--;
            SigDigitCount--;
        }
    }
    

    
    // Calculate bytes occupied by a decimal point.
    TheDecimalPoint = 1; 
    if(SigDigitsToRightOfDecimal == 0 &&
       SigZerosAppendedToRight == 0)
    {
        TheDecimalPoint = 0;
    }

FormatDecimalNumber:
    
    // Copy any left significant digits to output string.
    if( SigDigitsToLeftOfDecimal )
    {
        CopyBytes( TheDigits,
                   AtOutputByte,
                   SigDigitsToLeftOfDecimal ); 
                   
        AtOutputByte += SigDigitsToLeftOfDecimal;
        
        // Append any zeros to output string needed to the
        // left of the decimal point if any.
        if( SigZerosAppendedToLeft )
        {
            FillBytes( (u8*) AtOutputByte, 
                       (u32) SigZerosAppendedToLeft, 
                       (u16) '0' );
                       
            AtOutputByte += SigZerosAppendedToLeft;
        }
    }
    
    // If a decimal point is needed.
    if( TheDecimalPoint )
    {
        // Add the decimal point.
        *AtOutputByte++ = '.'; 
    }

    // If there any siginificant digits to the right of
    // the decimal.
    if( SigDigitsToRightOfDecimal )
    {
        // If zeros are prepended, insert them.
        if( SigZerosPrependedToRight )
        {
            FillBytes( (u8*) AtOutputByte, 
                       (u32) SigZerosPrependedToRight, 
                       (u16) '0' );
                       
            AtOutputByte += SigZerosPrependedToRight;
        }
    
        // Copy right significant digits to output string.
        CopyBytes(&TheDigits[DigitsToLeftOfDecimal],
                  AtOutputByte,
                  SigDigitsToRightOfDecimal);
              
        AtOutputByte+=SigDigitsToRightOfDecimal;
    }
    
    // Append any zeros to right hand side for fixed point.
    if(SigZerosAppendedToRight)
    {
        FillBytes( (u8*) AtOutputByte, 
                   (u32) SigZerosAppendedToRight, 
                   (u16) '0' );
                       
        AtOutputByte += SigZerosAppendedToRight;
    }
        
CleanUp:    
    // Add the end-of-string marker.
    *AtOutputByte = 0;
    TheNumberStringCount = (u16) 
                         ( AtOutputByte - TheNumberString );
    
    // If scientific format used as a last resort,
    // disable the scientific mode used above.                  
    if( DegradeToSci == 1 )
    {
         UseScientificFormat = 0;
    }
        
    return( (s8*) TheNumberString );
#endif // ... under construction.

    // Just to remove compiler warning, return
    // some value.
    return( 0 );
}

/*------------------------------------------------------------
| ConvertStringTof64
|-------------------------------------------------------------
|
| PURPOSE: To convert a an ASCII number to a 64-bit 
|          binary floating point number.  
|
| DESCRIPTION:  
|
| Expects a number formatted like this:
|
|    [+|-] [digits][,][digits] [.digits] [e|E [-|+] digits]
|
| Anything in brackets is optional.  If items are separated
| by vertical bars, only one of those items may be in that
| position.   
|
| Returns 'NoNum' if an error occurred.
|
| EXAMPLE: Tested using the following: 
|
|   {
|       f64 n;
| 
|       n = ConvertStringTof64( "123" );        printf("%lf\n",n);
|       n = ConvertStringTof64( "-123" );       printf("%lf\n",n);
|       n = ConvertStringTof64( "+123" );       printf("%lf\n",n);
|       n = ConvertStringTof64( "1,223" );      printf("%lf\n",n);
|       n = ConvertStringTof64( "1,234.32" );   printf("%lf\n",n);
|       n = ConvertStringTof64( "-1,234.32" );  printf("%lf\n",n);
|       n = ConvertStringTof64( "1.23e2" );     printf("%lf\n",n);
|       n = ConvertStringTof64( "-1.23e2" );    printf("%lf\n",n);
|       n = ConvertStringTof64( "-1.23e+2" );   printf("%lf\n",n);
|       n = ConvertStringTof64( "-1.23e-2" );   printf("%lf\n",n);
|       n = ConvertStringTof64( ".999" );       printf("%lf\n",n);
|       exit(0);
|   }
|
|   Output generated:
|       123.000000
|       -123.000000
|       123.000000
|       1223.000000
|       1234.320000
|       -1234.320000
|       123.000000
|       -123.000000
|       -123.000000
|       -0.012300
|       0.999000
|
| NOTE:  
|
| ASSUMES: No leading or trailing whitespace.
|
| HISTORY: 01.07.97 written & tested.
|          01.08.97 changed 'ParseUnsignedInteger' to
|                   'ParseUnsignedIntegerTof64' to handle
|                   very large numbers of digits.
|          02.05.00 Revised to use 'ParsedNumberString'.
|                   Retested using above procedure.
------------------------------------------------------------*/
f64
ConvertStringTof64( s8* s )
{
    f64                 n, Divisor;
    s32                 i, ex, ShiftDecimalLeftCount;
    s8                  W[ NUMBER_STRING_BUFFER_SIZE ];
    ParsedNumberString  P;
    s8*                 S;
    
    // Copy the string to working buffer.
    CopyString( s, W );
    
    // Strip any commas from the string.
    StripByteFromString( W, ',' );
    
    // Reduce the number string into its parts.
    ParseNumberString( 
        W,
        // The number to be parsed as a C string: all 
        // characters in the string must be part of the 
        // number.
        //  
        &P );
        // Resulting number in parsed form.
        
    // If this is a valid number.
    if( P.IsValidParse )
    {
        // Convert the significand string to an integer.
        S = P.SignificandString;
        n = ParseUnsignedIntegerTof64( &S );
        
        // If there is an exponent, convert it.
        if( P.ExponentDigitCount )
        {
            // Convert the exponent string to an integer.
            S = P.ExponentString;
            ex = (s32) ParseUnsignedIntegerTof64( &S );
            
            // Apply the sign.
            if( P.IsSignInExponent )
            {
                ex = -ex;
            }
        }
        else // No exponent.
        {
            ex = 0;
        }
        
        // Calculate the direction and number of decimal
        // point shifts.
        ShiftDecimalLeftCount = 
            P.CountOfDigitsToRightOfDecimal - ex;
            
        // Make decimial point adjustment if necessary.
        if( ShiftDecimalLeftCount )
        {
            Divisor = 1.;
            
            for( i = 0; 
                 i < ShiftDecimalLeftCount;
                 i++ )
            {
                Divisor *= 10.;
            }
            
            // If should shift to left.
            if( ShiftDecimalLeftCount > 0 )
            {
                // Shift the decimal to the left.
                n /= Divisor;
            }
            else // Shift to the right instead.
            {
                n *= Divisor;
            }
        }
        
        // If there is a sign, apply it.
        if( P.IsSignInSignificand )
        {
            n = -n;
        }
    }
    else // return signal that number is invalid.
    {
        n = NoNum;
    }
    
    // Return the result.
    return( n );
}

/*------------------------------------------------------------
| Eq 
|-------------------------------------------------------------
|
| PURPOSE: To test if two floating point numbers are equal
|          within the 'ChopTolerance'.
|
| DESCRIPTION:  
|
| EXAMPLE:    t = Eq( a, b );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.06.96 
------------------------------------------------------------*/
u32  
Eq( f64 a, f64 b )
{
    f64 dif;

    if( a < b )
    {
        dif = b - a;
    }
    else
    {
        dif = a - b;
    }
    
    if( dif < ChopTolerance )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}   

/*------------------------------------------------------------
| IsSameSign 
|-------------------------------------------------------------
|
| PURPOSE: To test if two floating point numbers have the 
|          same sign.
|
| DESCRIPTION:  
|
| EXAMPLE:    t = IsSameSign( a, b );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.30.96 
------------------------------------------------------------*/
u32  
IsSameSign( f64 a, f64 b )
{
    if( (a > 0) && (b > 0) )
    {
        return( 1 );
    }
    else
    {
        if( (a < 0) && (b < 0) )
        {
            return( 1 );
        }
        else
        {
            if( (a == 0) && (b == 0) )
            {
                return( 1 );
            }
            else
            {
                return( 0 );
            }
        }
    }
}   

/*------------------------------------------------------------
| ParseNumberString
|-------------------------------------------------------------
|
| PURPOSE: To separate a number in ASCII format into it's
|          component parts.
|
| DESCRIPTION: 
| 
| Expects a number formatted like this:
|
|     [+|-] [digits] [.digits] [e|E [-|+] digits]
|
| Anything in brackets is optional.  If items are separated
| by vertical bars, only one of those items may be in that
| position.  See p. 25 of ANM for formal grammar.
|
| EXAMPLE: ParseNumberString("123.23");
|          ParseNumberString("-123.23E-34");
|
| NOTE: See p. 113 of Think C 'Standard Libraries Reference',
| p. 71 of 'The C Answer Book', page 214 of 
| 'Think C User Manual',  p. 235 of 'Apple Numerics Manual,
| Second Ed.' (ANM), 
|
| See also 'ParseUnsignedInteger' in 'Parse.c'.
|
| ASSUMES: No leading or trailing whitespace.
| 
|          All characters in the string are part of the
|          the number.
|
|          Valid digits are 0 thru 9 only -- no hex support.
|
| HISTORY: 03.26.94 
|          05.30.94 added allowance for '+' characters.
|          02.05.00 Revised to use 'ParsedNumberString'.
|          02.06.00 Fixed '+' char handling in exponent.
------------------------------------------------------------*/
void
ParseNumberString( 
    s8*                 S,
                        // The number to be parsed as a C
                        // string: all characters in the 
                        // string must be part of the number.
                        //  
    ParsedNumberString* P )
                        // Resulting number in parsed form.
{
    s8                  c;
    ParsedNumberString  Q;
    
    // Clear the parse record to begin with.
    memset( &Q, 0, sizeof( ParsedNumberString ) );
    
    // Decrement 'S' to compensate for immediate increment.
    S--;
    
    //////////////////////////////////////////////////////////
    //                                                      //
    //                 S I G N I F I C A N D                //
    //                                                      //
    
NextCharacter:

    // Advance to the next character.
    S++;

    // Fetch the current character as 'c'.
    c = *S;

    // If the current character is a digit.
    if( IsDigit(c) )
    {
        // If there is room for another digit.
        if( Q.SignificandDigitCount < 
            (NUMBER_STRING_BUFFER_SIZE - 1) )
        {
            // Append the digit to the significand string.
            Q.SignificandString[Q.SignificandDigitCount] = c;
            
            // Account for the new digit.
            Q.SignificandDigitCount++;
        
            // If a decimal point has been found.
            if( Q.IsDecimalPoint )
            {
                // Count the digit as being to the
                // right of the decimal point.
                Q.CountOfDigitsToRightOfDecimal++;
            }
        }
        else // There is no room for another digit.
        {
            // Error: stop parsing.
            goto ErrorExit;
        }
        
        // Go process the next character.
        goto NextCharacter;
    }

    // Depending on the character.
    switch( c )
    {
        // If end of string has been reached.
        case 0: 
        {
            goto NormalExit;
        }
                
        // If the current character is an exponent marker.
        case 'e':
        case 'E':
        {
            // Note the presence of an exponent marker.
            Q.IsExponentMarker = 1;
            
            // Go process the exponent.
            goto NextExponentCharacter;
        }
        
        // If the current character is a minus sign.    
        case '-':
        {
            // If a sign has already been found.
            if( Q.IsSignInSignificand ) 
            {
                // Error: stop parsing.
                goto ErrorExit;
            }
            else // No sign found so far.
            {
                // Note the sign in the significand.
                Q.IsSignInSignificand = 1;
            }
            
            // Go process the next character.
            goto NextCharacter;
        }
        
        // If the current character is a decimal point. 
        case '.':
        {
            // If a decimal point has already been found.
            if( Q.IsDecimalPoint )
            {
                // Error: stop parsing.
                goto ErrorExit;
            }
            else
            {
                // Not the sign in the significand.
                Q.IsDecimalPoint = 1;
            }
            
            // Go process the next character.
            goto NextCharacter;
        }
        
        // If the current character is a plus sign. 
        case '+':
        {
            // Go process the next character.
            goto NextCharacter;
        }
                
        default:
        {
            // Treat any other character as invalid. 
            goto ErrorExit;
        }
    }
    //                 S I G N I F I C A N D                //
    //                                                      //
    //////////////////////////////////////////////////////////
        
    //////////////////////////////////////////////////////////
    //                                                      //
    //                    E X P O N E N T                   //
    //                                                      //

NextExponentCharacter:

    // Advance to the next character.
    S++;

    // Fetch the current character as 'c'.
    c = *S;

    // If the current character is a digit.
    if( IsDigit(c) )
    {
        // If there is room for another digit.
        if( Q.ExponentDigitCount < 
            (NUMBER_STRING_BUFFER_SIZE - 1) )
        {
            // Append the digit to the exponent string.
            Q.ExponentString[Q.ExponentDigitCount] = c;
            
            // Account for the new digit.
            Q.ExponentDigitCount++;
        }
        else // There is no room for another digit.
        {
            // Error: stop parsing.
            goto ErrorExit;
        }
        
        // Go process the next character.
        goto NextExponentCharacter;
    }

    // Depending on the character.
    switch( c )
    {
        // If end of string has been reached.
        case 0: 
        {
            goto NormalExit;
        }
                
        // If the current character is an exponent marker.
        case 'e':
        case 'E':
        {
            // Error: stop parsing.
            goto ErrorExit;
        }
        
        // If the current character is a minus sign.    
        case '-':
        {
            // If a sign has already been found.
            if( Q.IsSignInExponent ) 
            {
                // Error: stop parsing.
                goto ErrorExit;
            }
            else // No sign found so far.
            {
                // Note the sign in the exponent.
                Q.IsSignInExponent = 1;
            }
            
            // Go process the next character.
            goto NextExponentCharacter;
        }
        
        // If the current character is a plus sign. 
        case '+':
        {
            // Go process the next character.
            goto NextExponentCharacter;
        }
        
        default:
        {
            // Any other character is invalid. 
            goto ErrorExit;
        }
    }
    
    //                    E X P O N E N T                   //
    //                                                      //
    //////////////////////////////////////////////////////////

NormalExit:
    
    // Mark the parse as valid.
    Q.IsValidParse = 1;
 
ErrorExit:

    // Add string terminators.
    Q.ExponentString[Q.ExponentDigitCount] = 0;
    
    Q.SignificandString[Q.SignificandDigitCount] = 0;
    
    // Return the result.
    *P = Q;
}
    
/*------------------------------------------------------------
| Parsef64
|-------------------------------------------------------------
|
| PURPOSE: To parse a f64 into fields.
|
| DESCRIPTION:   
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 02.05.00
------------------------------------------------------------*/
void
Parsef64( f64*       a, 
                     // The address of the f64 to be parsed.
                     //
          Parsedf64* b )
                     // The address of the resulting parse 
                     // record.
{
    u64 u;
    
    // Get the f64 bits in the form of an u64.
    u = *( (u64*) a );
    
    // If the sign bit of 'a' is set.
    if( u & f64_s_mask )
    {
        // Set the value of the sign to '1'.
        b->s = 1;
    }
    else // The sign is not set.
    {
        // Set the value of the sign to '0'.
        b->s = 0;
    }
    
    // Extract the biased exponent field value.
    b->e = (u16) ( ( u & f64_e_mask ) >> f64_e_offset );
    
    // Extract the fraction field value.
    b->f = ( u & f64_f_mask );
}

/*------------------------------------------------------------
| Sign
|-------------------------------------------------------------
|
| PURPOSE: To convert a number to +1, 0 or -1 depending on
|          whether the number is positive, zero or negative.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 05.07.97
------------------------------------------------------------*/
f64
Sign( f64 n )
{
    if( n > 0 )
    {
        return( 1. );
    }
    
    if( n < 0 )
    {
        return( -1. );
    }
     
    return( 0 );
}

/*------------------------------------------------------------
| strf64
|-------------------------------------------------------------
|
| PURPOSE: To return a fixed-format version of a floating 
|          point number.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.30.00 From Allan Moluf.
------------------------------------------------------------*/
s8* 
strf64( f64 val, s32 numDigits )
{
    // rotate among several static buffers
    // in case several results are in use at the same time
    static s8 bufs[64][32];
    static s32 bufNum = 0;
    s8*buf = &bufs[(++bufNum) & (64 - 1)][0];
    
    if( numDigits < 0 ) 
    {
        numDigits = 0;
    }
    
    if( numDigits > 15 ) 
    {
        numDigits = 15;
    }
    
    sprintf (buf, "%.*lf", numDigits, val);
    
    return buf;
}

