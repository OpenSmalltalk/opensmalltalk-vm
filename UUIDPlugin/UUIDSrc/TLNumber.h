/*------------------------------------------------------------
| TLNumber.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to number formatting 
|          procedures.
|
| DESCRIPTION: 
|
| HISTORY: 01.12.94 
|          08.19.97 added C++ support.
------------------------------------------------------------*/

#ifndef _NUMBER_H_
#define _NUMBER_H_

#ifdef __cplusplus
extern "C"
{
#endif

// Interface to Standard Apple Numerics Environment.

#define MaxMagnitudeOfDecimalExponent   4932                

#define MaxCountOfExponentDigits        4

// 07.22.97 changed from 18 to 100.
// 10.16.97 changed back to 18 for Ak2.
#define MaxCountOfSignificandDigits  18

//#define MaxCountOfSignificandDigits       100

// 07.22.97 changed from 26 to 108.
// 10.16.97 changed back to 26 for Ak2.
#define MaxCountOfNumberStringDigits    26
//#define MaxCountOfNumberStringDigits  108
        /* Largest that a number can be:
         * 1 byte for a sign.
         * 100 significand digits.
         * 1 byte for decimal point.
         * 1 byte for 'e'
         * 1 byte for sign of exponent.
         * 4 bytes for the exponent.
         * Total: 108
         */

extern s16   CountOfDigitsToRightOfDecimal;
            /* Number of digits in the significand to 
             * the right of the decimal point.
             */
             
extern s16   ExponentDigitCount;
            /* Number of digits found in the exponent.
             */

extern u8    ExponentString[];
            /* Holds the exponent digits without any sign; 
             * 0 terminated.
             */

extern u16          FixedPointDecimalPlaces;
            /* If 'UseFixedPointFormat' is true, this
             * value specifies the number of decimal
             * places to use.
             */

extern u32          IsDecimalPoint;
            /* '1' if there is a decimal point in
             * the significand.
             */

extern u32          IsExponentMarker;
            /* '1' if there is a 'e' or 'E' character
             * in the number.
             */

extern u32          IsSignInExponent;
            /* '1' if an exponent sign has been 
             * encountered in the number.
             */

extern u32          IsSignInSignificand;
            /* '1' if a significand sign has been 
             * encountered in the number.
             */

extern u32          IsValidNumberParse;
            /* '1' if no formal rules have been 
             * violated during the parse.
             */

extern s32      NumberExit;  
            /* Number conversion exit code. */

extern s16  SignificandDigitCount;
            /* Number of digits found in the significand.
             */

extern u8           SignificandString[];
            /* Holds the significand digits without any sign; 
             * 0 terminated.
             */

#if macintosh

extern decform          TheDecimalFormRecord;
                        // Used for SANE conversion.

extern decimal          TheDecimalRecord; 
                        // Used for SANE conversion.
#endif


extern DecimalNumber    TheDecimalNumber;
                        // Holds the result of string to 
                        // 'DecimalNumber' conversion.

extern u8               TheNumberString[];
                        // Where the converted number string is put.

extern u16              TheNumberStringCount;
                        // How many bytes there are in the resulting
                        // number string.

extern u32              UseFixedPointFormat; 
                        // Controls whether fixed point format should
                        //  be used.
             
extern u32              UseScientificFormat; 
                        // Controls whether scientific format should
                        //  be used.

s8*             ConvertNumberToString(Number);
Number          ConvertDecimalNumberToNumber(DecimalNumber*);
s8*             ConvertDecimalNumberToString(DecimalNumber*);
s32             ConvertIntegerToString( s32, s8* );
DecimalNumber*  ConvertStringToDecimalNumber(s8*);
s32             ConvertStringToInteger(s8*);
Number          ConvertStringToNumber(s8*);
u32             ConvertStringToUnsignedInteger( s8* );
void            UnifyDecimalNumbers( DecimalNumber*, 
                                     DecimalNumber*);
#ifdef __cplusplus
} // extern "C"
#endif

#endif
