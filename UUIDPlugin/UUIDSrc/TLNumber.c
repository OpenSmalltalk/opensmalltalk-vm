/*------------------------------------------------------------
| TLNumber.c
|-------------------------------------------------------------
|
| PURPOSE: To provide number formatting procedures.
|
| DESCRIPTION: 
|
| HISTORY: 01.12.94 
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>

#include "TLTypes.h"
#include "TLAscii.h"
#include "TLStrings.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLf64.h"
//#include "TLMem.h"
#include "TLNumber.h"

#define __dec2num   dec2num
 
s16         CountOfDigitsToRightOfDecimal;
            // Number of digits in the significand to 
            // the right of the decimal point.
             
s16         ExponentDigitCount;
            // Number of digits found in the exponent.

u8          ExponentString[MaxCountOfExponentDigits+1];
            // Holds the exponent digits without any sign; 
            // 0 terminated.

u16         FixedPointDecimalPlaces=2;
            // If 'UseFixedPointFormat' is true, this
            // value specifies the number of decimal
            // places to use.

u32         IsDecimalPoint;
            // '1' if there is a decimal point in
            // the significand.

u32         IsExponentMarker;
            // '1' if there is a 'e' or 'E' character
            // in the number.

u32         IsSignInExponent;
            // '1' if an exponent sign has been 
            // encountered in the number.

u32         IsSignInSignificand;
            // '1' if a significand sign has been 
            // encountered in the number.

u32         IsValidNumberParse;
            // '1' if no formal rules have been 
            // violated during the parse.

s32         NumberExit;  
            // Number conversion exit code. 

s16         SignificandDigitCount;
            // Number of digits found in the significand.

u8          SignificandString[MaxCountOfSignificandDigits+1];
            // Holds the significand digits without any sign; 
            // 0 terminated.

DecimalNumber       TheDecimalNumber;
            // Holds the result of string to 'DecimalNumber' 
            // conversion.

#if macintosh
decform     TheDecimalFormRecord;
            // Used for SANE conversion.

decimal     TheDecimalRecord; 
            // Used for SANE conversion.
#endif

u8          TheNumberString[MaxCountOfNumberStringDigits];
            // Where the converted number string is put.

u16         TheNumberStringCount;
            // How many bytes there are in the resulting
            // number string.

Ratio       TheRatio;
            // Holds the result of string to ratio conversion.
            
u32         UseFixedPointFormat=0; 
            // Controls whether fixed point format should
            // be used for output formatting.
             
u32         UseScientificFormat=0; 
            // Controls whether scientific format should
            // be used for output formatting.

/*------------------------------------------------------------
| ConvertNumberToString
|-------------------------------------------------------------
|
| PURPOSE: To convert a number in binary floating point 
|          format to ASCII format.
|
| DESCRIPTION: Begins by converting the number into a
| decimal record.
| 
| Default Conversion Rule: Use floating point. If the exponent 
| field can be eliminated by moving the decimal point, then 
| that is done.  Otherwise, scientific format is used.  
|
| The setting of these variables over-rides the default
| conversion rule:
|
| UseScientificFormat ---- if 1, then use scientific
| UseFixedPointFormat ---- if 1, then use fixed number
|                          of digits to the right of the
|                          decimal point
| FixedPointDecimalPlaces - how many decimal places should be
|                           used if 'UseFixedPointFormat' is
|                           true.
|
| The returned string address is the address of the
| number conversion buffer.  The number string must be 
| copied elsewhere to preserve it.
|
| Also sets 'TheNumberStringCount' to the number of digits
| in the result string.
|
| EXAMPLE: AString = ConvertNumberToString(123.23);
|
| NOTE: See p. 31 of 'Apple Numerics Manual,2nd Ed.' (ANM).
|
|       *** Develop a number formatting context record. 
|
| ASSUMES: 
|          Ok to change 'TheDecimalRecord'.
|          Ok to change 'TheDecimalFormRecord'.
|
| HISTORY: 01.12.94 
|          01.16.94 added fixed point format
|          02.18.94 removed degrade from fixed point when
|                   value is very small.
|          06.01.94 strip sign from zero, if any.
|          06.11.94 simplified case for zero.
|          07.08.95 replace 'x96tox80' for CW.
|          12.24.95 Converted to used 'fp.h' call instead of
|                   SANE.
|          01.25.96 added support for 'NaN'.
|          02.27.96 added resetting of scientific format
|                   when it is used as a last resort.
|          07.20.97 disabled degrade to scientific format.
------------------------------------------------------------*/
s8*
ConvertNumberToString( Number ANumber )
{
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
    u16         LastDigitIndex;
    Number      PlacesForANumber;

    // Handle 0 specially to strip any nonsense sign.
    if( ANumber == 0 ) 
    {
        TheNumberString[0]   = '0';
        TheNumberString[1]   = 0;
        TheNumberStringCount = 1;
        
        return( (s8*) TheNumberString );
    }

    DegradeFromFixed = 0;
    DegradeToSci     = 0;
//TBD ValidateMemory();     
NormNumber:
        
UnpackNumber:
    // Call SANE routine to convert double_t to decimal
    // record, with decimal point formatting.
    if( UseFixedPointFormat )
    {
//TBD       TheDecimalFormRecord.style  = FIXEDDECIMAL;
//TBD       TheDecimalFormRecord.digits = FixedPointDecimalPlaces;
    }
    else
    {
//TBD       TheDecimalFormRecord.style  = FLOATDECIMAL;
//TBD       TheDecimalFormRecord.digits = MaxCountOfSignificandDigits;
    }
//TBDValidateMemory();      
    // Rounding is done here.
//TBD   num2dec( &TheDecimalFormRecord,
//TBD            (double_t) ANumber,
//TBD            &TheDecimalRecord );
//TBDValidateMemory();  

//TBD   TheSign       = TheDecimalRecord.sgn;
//TBD   TheExponent   = TheDecimalRecord.exp;
//TBD   TheDigits     = (u8*) &TheDecimalRecord.sig.text;
//TBD   SigDigitCount = TheDecimalRecord.sig.length;

    // Check first for 'NaN' result.
    if( TheDigits[0] == 'N' )
    {
        CopyString( (s8*) "NaN", (s8*) &TheNumberString );
        TheNumberStringCount = 3;
        return((s8*) TheNumberString);
    }
        
    // Test if a fixed point number exceeds the space 
    // available on the high magnitude end.
    if( UseFixedPointFormat && fabs(ANumber) > 1 )
    {
        PlacesForANumber = fabs(log10(ANumber));
        
        if(PlacesForANumber > MaxCountOfSignificandDigits ||
           TheDigits[0] == '?')
        {
            // Degrades to floating point if not enough room.
            // Could generate a warning message here.
            UseFixedPointFormat = 0;
            DegradeFromFixed = 1;
            goto UnpackNumber;
        }
    }
//TBD ValidateMemory();     
    AtOutputByte  = (u8*) TheNumberString;
    
    /* if negative, make a minus sign. */
    if(TheSign) 
    {
        *AtOutputByte++ = '-';
    }
//TBD ValidateMemory(); 
CalcDigitsToLeft:

    DigitsToLeftOfDecimal  = SigDigitCount + TheExponent;
    DigitsToRightOfDecimal = -TheExponent;
    
    SigZerosAppendedToLeft   = 0;
    SigZerosPrependedToRight = 0;
    SigZerosAppendedToRight  = 0;
    
    if(DigitsToLeftOfDecimal < 0)
    {
        SigZerosPrependedToRight = -DigitsToLeftOfDecimal;
        DigitsToLeftOfDecimal = 0;
    }

    if(DigitsToRightOfDecimal < 0)
    {
        SigZerosAppendedToLeft = -DigitsToRightOfDecimal;
        DigitsToRightOfDecimal = 0;
    }
    
    if( UseScientificFormat )
    {
        if( DigitsToLeftOfDecimal )
        {
            DecimalPointDisplacement = 
                -(DigitsToLeftOfDecimal-1);
        }
        else
        {
            DecimalPointDisplacement =
                SigZerosPrependedToRight+1;
        }
        
        // Set one sig digit to left of the decimal point.
        TheExponent += DecimalPointDisplacement;
        DigitsToLeftOfDecimal = 1;
        DigitsToRightOfDecimal = SigDigitCount-1;
        
        SigZerosAppendedToLeft   = 0;
        SigZerosPrependedToRight = 0;
        SigZerosAppendedToRight  = 0;
    }
//TBD ValidateMemory(); 
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
//TBD ValidateMemory();
         
    // Trim trailing zeros if floating point. 
    if( TheExponent<0 && !UseFixedPointFormat )
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
//TBD ValidateMemory(); 

    // Trim excess or pad right digits if fixed point
    // or degraded fixed point.
    if( UseFixedPointFormat || DegradeFromFixed )
    {
        Carry = 0;
        
        // Remove any extra bytes.
        while( SigDigitsToRightOfDecimal>
               FixedPointDecimalPlaces )
        {
            LastDigitIndex = SigDigitsToLeftOfDecimal+
                             SigDigitsToRightOfDecimal-1;
                             
            // Round as we go.
            if( TheDigits[LastDigitIndex] > '4' )
            {
                Round = 1;
            }
            else
            {
                Round = 0;
            }
                
            TheDigits[LastDigitIndex-1] +=
                      Round + Carry;
            
            if( TheDigits[LastDigitIndex-1] > '9')
            {
                Carry = 1;
                TheDigits[LastDigitIndex-1] = '0';
            }
            else
            {
                Carry = 0;
            }
            
            SigDigitsToRightOfDecimal--;
            DigitsToRightOfDecimal--;
            SigDigitCount--;
        }
        
        // Pad with zeros if needed.
        if( DigitsToRightOfDecimal < FixedPointDecimalPlaces )
        {
            SigZerosAppendedToRight =
                FixedPointDecimalPlaces -
                DigitsToRightOfDecimal;
        }
    }
//TBD ValidateMemory();     
    // Calculate bytes occupied by a decimal point.
    TheDecimalPoint = 1; 
    if(SigDigitsToRightOfDecimal == 0 &&
       SigZerosAppendedToRight == 0)
    {
        TheDecimalPoint = 0;
    }
    
    if( UseScientificFormat ) goto FormatDecimalNumber;

    // Decide if scientific format should be used 
    // due to space taken up by resulting number. 
    //
    if( ( DigitsToLeftOfDecimal+  // is sign and dp needed here?
          DigitsToRightOfDecimal+
          SigZerosAppendedToRight ) > 
        MaxCountOfSignificandDigits ) 
    {

        // If it is OK to use scientific format.
//      if( IsOkToUseScientificFormat )
//      {
            UseScientificFormat = 1;
            DegradeToSci        = 1;
            
            goto NormNumber;
//      }
//      else // Not OK to use scientific format.
//      {
            // If digits to the left
//***** Fix this here: figure out how much total space is required
//      and clip accordingly, maybe with rounding.          
            
//      }
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
    
//TBD ValidateMemory(); 
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
//TBD ValidateMemory(); 
        // Copy right significant digits to output string.
        CopyBytes(&TheDigits[DigitsToLeftOfDecimal],
                  AtOutputByte,
                  SigDigitsToRightOfDecimal);
              
        AtOutputByte+=SigDigitsToRightOfDecimal;
    }
    
    // Append any zeros to right hand side for fixed point.
    if(SigZerosAppendedToRight)
    {
//TBD ValidateMemory();
        FillBytes( (u8*) AtOutputByte, 
                   (u32) SigZerosAppendedToRight, 
                   (u16) '0' );
                       
        AtOutputByte += SigZerosAppendedToRight;
    }
    
    if( !UseScientificFormat ) goto CleanUp;
//TBD ValidateMemory();     
FormatExponent:
    
    // Make a scientific format number by adding
    // the exponent marker. 
    *AtOutputByte++ = 'e'; 
        
    // Convert exponent to ASCII.
    ExponentByteCount = ConvertIntegerToString( 
                            (s32) -DecimalPointDisplacement,
                            (s8*) AtOutputByte);
                                
    AtOutputByte += ExponentByteCount;
    
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
    
//TBD ValidateMemory();     
    return( (s8*) TheNumberString );
}

/*------------------------------------------------------------
| ConvertDecimalNumberToNumber
|-------------------------------------------------------------
|
| PURPOSE: To convert a number in 'DecimalNumber' format to 
|          'Number' format.
|
| DESCRIPTION: Scales number according to the decimal exponent.
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 04.06.94 
|          06.11.94 added special case for zero.
------------------------------------------------------------*/
Number
ConvertDecimalNumberToNumber( 
    DecimalNumber*  ADecimalNumber )
{
    Number  Result;
    
    if( ADecimalNumber->BinaryPart == 0 )
    {
        return( (Number) 0);
    }
    
    if( ADecimalNumber->DecimalExponent == 0 )
    {
        Result = ADecimalNumber->BinaryPart;
    }
    else
    {
        Result = ADecimalNumber->BinaryPart *
                 pow((Number) 10, 
                     (Number) ADecimalNumber->DecimalExponent);
    }
    
    return( Result );
}

/*------------------------------------------------------------
| ConvertDecimalNumberToString
|-------------------------------------------------------------
|
| PURPOSE: To convert a number in decimal number format to 
|          ASCII format.
|
| DESCRIPTION: 
|
| NOTE: See 'ConvertNumberToString'. 
|
| ASSUMES: 
|          Ok to change 'TheDecimalRecord'.
|          Ok to change 'TheDecimalFormRecord'.
|
| HISTORY: 03.25.94 
|          03.26.94 changed denominator to be a power
|                   of ten.
|          04.06.94 changed 'Ratio' to 'DecimalNumber' type.
------------------------------------------------------------*/
s8*
ConvertDecimalNumberToString( 
    DecimalNumber*  ADecimalNumber )
{
    return( 
        ConvertNumberToString( 
            ConvertDecimalNumberToNumber(ADecimalNumber) ) );
}

/*------------------------------------------------------------
| ConvertIntegerToString
|-------------------------------------------------------------
|
| PURPOSE: To produce an ASCII string equivalent to a
|          binary integer.
|
| DESCRIPTION: Makes an ASCII number with a leading '-'
| sign if the number is negative.  Returns the number of
| bytes in the result not counting the terminating 0.
|
| EXAMPLE: ByteCount = ConvertIntegerToString((s32)-123,
|                                             MyString);
|
| in MyString: ['-']['1']['2']['3'][0]
| in ByteCount: 4
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
------------------------------------------------------------*/
s32
ConvertIntegerToString( s32 n, s8* s )
{
    s32 Sign;
    s32 i;
    
    Sign = n; // record the sign
    
    if( Sign < 0 ) // make number positive 
    {
        n = -n;
    }
    
    i = 0;
    
NextDigit:

    s[i++] = n % 10 + '0'; // get next digit
    
    n /= 10;
    
    if( n > 0 ) goto NextDigit;
    
    // Append the sign if any so that reversal routine
    // will make it first.
    if( Sign < 0 ) 
    {
        s[i++] = '-';
    }
    
    s[i] = 0; // add end-of-string
    
    // Reverse the order of the digits.
    ReverseString( s );
    
    // Return the string length.
    return( i );
}

/*------------------------------------------------------------
| ConvertStringToInteger
|-------------------------------------------------------------
|
| PURPOSE: To convert a string to a 32-bit signed integer.
|
| DESCRIPTION: 
|
| EXAMPLE:  n = ConvertStringToInteger("12343");
|
| NOTE: atol() requires the ANSI library: include stdlib.h.
|
| ASSUMES: String is terminated with a 0.
|
| HISTORY: 01.27.94  
------------------------------------------------------------*/
s32
ConvertStringToInteger( s8* AString )
{
    return( atol( (char*) AString ) );
}

/*------------------------------------------------------------
| ConvertStringToNumber
|-------------------------------------------------------------
|
| PURPOSE: To convert a number in ASCII format to binary
|          floating point format.
|
| DESCRIPTION: Stops converting when it reaches a byte that 
| can't be part of a number.
| 
| Looks for a number formatted like this:
|
|     [+|-] [digits] [.digits] [e|E [-|+] digits]
|
| Anything in brackets is optional.  If items are separated
| by vertical bars, only one of those items may be in that
| position.  See p. 25 of ANM for formal grammar.
|
| Sets 'NumberExit' to 'OK' if conversion was successful.
|
| Sets 'NumberExit' to 'OutOfRange' if exponent is too
| large and returns a 0.
| 
| EXAMPLE: ANumber = ConvertStringToNumber("123.23");
|
|          ANumber = ConvertStringToNumber("-123.23E-34");
|
| NOTE: See p. 113 of Think C 'Standard Libraries Reference',
| p. 71 of 'The C Answer Book', page 214 of 
| 'Think C User Manual',  p. 235 of 'Apple Numerics Manual,
| Second Ed.' (ANM), 
|
| 'cstr2dec' is defined on p. 176 of ANM, superceded by
| equivalent function in MathLib, 'str2dec'.
|
| ASSUMES: If invalid prefix, then number must be out of 
|          range.
|
|          Ok to change 'TheDecimalRecord'.
|
| HISTORY: 01.12.94 copied from 'The C Answer Book'.
|          12.24.95 converted from SANE to MathLib format.
------------------------------------------------------------*/
Number
ConvertStringToNumber( s8* AString )
{
#if macintosh // just mac Sfor now
    s16     StrIndex;
    s16     ValidPrefix;
    Number  Result;
    
    /* Call SANE routine to convert string to a decimal 
     * record, an intermediate format.
     */
    StrIndex = 0;
    
    str2dec( (char*) AString, 
             (s16*) &StrIndex, 
             (decimal *) &TheDecimalRecord, 
             (s16 *) &ValidPrefix);

    if(!ValidPrefix)
    {
        NumberExit = OutOfRange;
        Result = 0.0;
        return(Result);
    }

    NumberExit = OK;
    
    /* Call fp routine to convert decimal to extended 
     * number. 
     */
    Result = (Number) __dec2num(&TheDecimalRecord);
    
    return(Result);
#endif // macintosh for now
}

/*------------------------------------------------------------
| ConvertStringToDecimalNumber
|-------------------------------------------------------------
|
| PURPOSE: To convert a number in ASCII format to decimal 
|          number format.
|
| DESCRIPTION: Stops converting when it reaches a byte that 
| can't be part of a number.
| 
| Looks for a number formatted like this:
|
|     [+|-] [digits] [.digits] [e|E [-|+] digits]
|
| Anything in brackets is optional.  If items are separated
| by vertical bars, only one of those items may be in that
| position.  See p. 25 of ANM for formal grammar.
|
| Sets 'NumberExit' to 'OK' if conversion was successful.
|
| Sets 'NumberExit' to 'OutOfRange' if exponent is too
| large and returns a 0.
| 
| EXAMPLE: AtDecNum = ConvertStringToDecimalNumber("123.23");
|          MyDecNum = TheDecimalNumber;
|
|          AtDecNum = ConvertStringToDecimalNumber("-123.23E-34");
|          MyDecNum = TheDecimalNumber;
|
| NOTE: See p. 113 of Think C 'Standard Libraries Reference',
| p. 71 of 'The C Answer Book', page 214 of 
| 'Think C User Manual',  p. 235 of 'Apple Numerics Manual,
| Second Ed.' (ANM), 
|
| 'cstr2dec' is defined on p. 176 of ANM.
|
| 'DecimalNumber' format is used to eliminate rounding error 
| on ASCII to floating point format conversion.
|
| The significand is held as an integer; the exponent is held 
| as the power of 10 needed to produce the number through a 
| mulplication.
|
|
| ASSUMES: If invalid prefix, then number must be out of 
|          range.
|
|          Ok to change 'TheDecimalRecord'.
|
|          No leading or trailing whitespace.
| 
|          Only characters in the string are part of the
|          the number.
|
|          Ok to change 'TheDecimalNumber'
|
| HISTORY: 03.25.94 
|          04.06.94 changed 'Ratio' to 'DecimalNumber' type.
|          06.01.94 filtered out negative zeros on input.
------------------------------------------------------------*/
DecimalNumber*
ConvertStringToDecimalNumber( s8* AString )
{
    s16                 Exponent;
    Number              BinaryPart;
    s16                 DecimalExponent;
    ParsedNumberString  P;
    
    // Reduce the number to its component parts.
    ParseNumberString( 
        AString,
        // The number to be parsed as a C string: all 
        // characters in the string must be part of the 
        // number.
        //  
        &P );
        // Resulting number in parsed form.

    if( P.IsValidParse == 0 ) goto ErrorExit;
    
    // 
    // Build the binary part integer. 
    //

    // If the number has no decimal point or exponent,
    // then it is an integer. 
    if( P.IsDecimalPoint == 0 && 
        P.IsExponentMarker == 0)
    {
        // Use 'ConvertStringToNumber' for speed.
        BinaryPart = ConvertStringToNumber( AString );

        // DecimalExponent holds the power of 10 of the
        // decimal scaling factor.
        DecimalExponent = 0;

        goto MakeTheDecimalNumber;
    }
    
    // Has a decimal point or exponent 
    // so make the BinaryPart integer separately. 
    BinaryPart = ConvertStringToNumber( P.SignificandString );
    
    // Ascribe sign to number if present and non-zero magnitude.
    if( P.IsSignInSignificand && BinaryPart != 0)
    {
        BinaryPart = -BinaryPart;
    }
    
    // Convert exponent to floating point number.
    if( P.IsExponentMarker )
    {
        Exponent = ConvertStringToInteger( P.ExponentString );
    
        // if Exponent has sign, apply it.
        if( P.IsSignInExponent )
        {
            Exponent = -Exponent;
        }
    }
    else
    {
        Exponent = 0;
    }

    // DecimalExponent holds the power of 10 of the
    // decimal scaling factor.
    DecimalExponent = Exponent - CountOfDigitsToRightOfDecimal;
    
MakeTheDecimalNumber:
    NumberExit = OK;
    TheDecimalNumber.BinaryPart      = BinaryPart;
    TheDecimalNumber.DecimalExponent = DecimalExponent;

ReturnNumberAddress:
    return( &TheDecimalNumber );

ErrorExit:
    NumberExit                       = OutOfRange;
    TheDecimalNumber.BinaryPart      = 0;
    TheDecimalNumber.DecimalExponent = 0;
    
    goto ReturnNumberAddress;
}

/*------------------------------------------------------------
| ConvertStringToUnsignedInteger
|-------------------------------------------------------------
| 
| PURPOSE: To convert and ASCII unsigned decimal number to an
|          binary after skipping any white space.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: Could be faster if multiply factored out.
| 
| ASSUMES: ASCII number is decimal.
| 
| HISTORY: 01.07.97 from 'ParseUnsignedInteger'.
------------------------------------------------------------*/
u32 
ConvertStringToUnsignedInteger( s8* s )
{   
    u32 result;
    s8  c;
    
    result = 0;
    
    // Skip leading whitespace.
GetAByte:
    
    c = *s;
    
    if( c == ' '  || 
        c == '\t' || 
        c == '\n' ||
        c == '\r' )  
    {
        s++;
        
        goto GetAByte;
    }
    
    // Convert any digits.
GetAByte2:
    
    c = *s;
    
    if( c >= '0' && c <= '9' )
    {
        result = 10 * result + (c - '0');
        
        s++;
        
        goto GetAByte2;
    }
    
    return( result );
}
    
/*------------------------------------------------------------
| UnifyDecimalNumbers
|-------------------------------------------------------------
|
| PURPOSE: To conform two decimal number to a common decimal
|          scaling factor.
|
| DESCRIPTION: Uses the largest DecimalExponent as the
| standard to which the other number must conform.
| 
| EXAMPLE:  UnifyDecimalNumbers(ANumber,BNumber);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 04.06.94 
|          05.30.94 fixed error.
------------------------------------------------------------*/
void                    
UnifyDecimalNumbers( DecimalNumber* ANumber, 
                     DecimalNumber* BNumber) 
{
    s16             AAbsEx;
    s16             BAbsEx;
    s16             ADecimalEx;
    s16             BDecimalEx;
    s16             ScaleEx;
    DecimalNumber*  CNumber;

    ADecimalEx = ANumber->DecimalExponent;
    BDecimalEx = BNumber->DecimalExponent;
    
    if( ADecimalEx == BDecimalEx ) return;
    
    // Calc the magnitudes of the exponents.
    AAbsEx = ADecimalEx;
    if(ADecimalEx < 0) AAbsEx = -ADecimalEx;
    
    BAbsEx = BDecimalEx;
    if(BDecimalEx < 0) BAbsEx = -BDecimalEx;
    
    // Make 'ANumber' refer to the number with the exponent
    // having the largest magnitude.
    if( AAbsEx < BAbsEx )
    {
        CNumber = ANumber;
        ANumber = BNumber;
        BNumber = CNumber;
        
        ADecimalEx = ANumber->DecimalExponent;
        BDecimalEx = BNumber->DecimalExponent;
    }
    
    // Use the exponent with the largest magnitude as the norm. 
    // Calculate the scaling amount based on the sign of the
    // exponent with the largest magnitude.
    if( ADecimalEx > 0 )
    {
        ScaleEx =  ADecimalEx - BDecimalEx;
    }
    else
    {
        ScaleEx =  BDecimalEx - ADecimalEx;
    }
    
    // Scale the mantissa of the number with the smaller-magnitude
    // exponent by the power of ten needed to align the decimal
    // points.
    BNumber->BinaryPart *= pow( (Number) 10, (Number) ScaleEx);
    BNumber->DecimalExponent = ADecimalEx;
}
