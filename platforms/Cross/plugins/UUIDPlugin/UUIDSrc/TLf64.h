/*------------------------------------------------------------
| TLf64.h
|-------------------------------------------------------------
|
| PURPOSE: To provide 64-bit floating point number functions.
|
| DESCRIPTION: 
|
| HISTORY: 02.05.00 From 'TLNumber.h'.
------------------------------------------------------------*/

#ifndef TLF64_H
#define TLF64_H

#ifdef __cplusplus
extern "C"
{
#endif

// This is the tolerance that is used to compare floating
// point numbers.  Differences less than this amount are
// regarded as no difference.
//#define ChopTolerance (.0000000001)
// 07.04.97 Changed from above.  See also 'SafeLog()' which
//          should be compatible with this.
#define ChopTolerance (1.e-8) // (1.e-30)


// 'NoNum' is used as a placeholder for missing data values. 
//
// Use 'NoNum' in place of 'NAN' because 'NAN' can't be used 
// in comparisons.   
//
// The value allocated to 'NoNum' should not be used for any 
// other purpose.
//
// This in not part of the IEEE 754 Standard it's just a 
// just a convention that I follow.
#define NoNum   ((f64) -123456789.987654321)

#define twopi   (pi*2.0)
#define piby2   (pi/2.0)
#define piby4   (pi/4.0)
#define piby8   (pi/8.0)
#define piby16  (pi/16.0)

//#define   MaxMagnitudeOfDecimalExponent   4932                

//#define MaxCountOfExponentDigits      4

// 07.22.97 changed from 18 to 100.
// 10.16.97 changed back to 18 for Ak2.
//#define MaxCountOfSignificandDigits  18

//#define MaxCountOfSignificandDigits       100

#define NUMBER_STRING_BUFFER_SIZE   (512)
        // The number of bytes to allocate for parsing or
        // generating number strings.
        
//#define MaxCountOfNumberStringDigits  26
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

// Data types defined below.
typedef struct Parsedf64            Parsedf64;
typedef struct ParsedNumberString   ParsedNumberString;

/*------------------------------------------------------------
| IEEE 754 32-bit Single Format
|-------------------------------------------------------------
|
| PURPOSE: To specify the format of IEEE 754 single precision
|          floating point numbers.
|
| DESCRIPTION: The 32-bit single format is divided into three
| fields having 1, 8 and 23 bits.
|
|                 1     8           23
|               ------------------------------ 
|               | s |   e   |       f        |
|               ------------------------------ 
|              msb                          lsb
|
| ABBREVIATIONS:
|
|   'v'......value of number.
|   's'......sign bit, 1 means negative and 0 non-negative.
|   'e'......biased exponent (exponent + bias).
|   'f'......fraction (significand without leading bit).
|   'msb'....most significant bit.
|   'lsb'....least significant bit.
|
| Values are interpreted this way:
|
|  'e'       'f'              'v'                  'v' class
|-------------------------------------------------------------
| 1 - 2046  (any)   (-1)^s x 2^(e-1023) x (1.f)   Normalized
| 0         not 0   (-1)^s x 2^(e-1022) x (0.f)   Denormalized
| 0           0     (-1)^s x 0                    Zero
| 2047        0     (-1)^s x infinity             Infinity
| 2047      not 0   NaN                           NaN
|-------------------------------------------------------------
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.05.00 From "PowerPC Numerics" by Apple.
------------------------------------------------------------*/
// Field masks for 32-bit floating point numbers.
#define f32_s_mask ((u32) 0x80000000)
#define f32_e_mask ((u32) 0x7F800000)
#define f32_f_mask ((u32) 0x007FFFFF)
#define f32_bias   (127)

/*------------------------------------------------------------
| IEEE 754 64-bit Double Format
|-------------------------------------------------------------
|
| PURPOSE: To specify the format of IEEE 754 double precision
|          floating point numbers.
|
| DESCRIPTION: The 64-bit double format is divided into three
| fields having 1, 11 and 52 bits.
|
|                 1    11          52
|               ------------------------------ 
|               | s |   e   |       f        |
|               ------------------------------ 
|              msb                          lsb
|
| ABBREVIATIONS:
|
|   'v'......value of number.
|   's'......sign bit, 1 means negative and 0 non-negative.
|   'e'......biased exponent (exponent + bias).
|   'f'......fraction (significand without leading bit).
|   'msb'....most significant bit.
|   'lsb'....least significant bit.
|
| Values are interpreted this way:
|
|  'e'       'f'              'v'                  'v' class
|-------------------------------------------------------------
| 1 - 2046  (any)   (-1)^s x 2^(e-1023) x (1.f)   Normalized
| 0         not 0   (-1)^s x 2^(e-1022) x (0.f)   Denormalized
| 0           0     (-1)^s x 0                    Zero
| 2047        0     (-1)^s x infinity             Infinity
| 2047      not 0   NaN                           NaN
|-------------------------------------------------------------
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.05.00 From "PowerPC Numerics" by Apple.
------------------------------------------------------------*/

// Field sizes for IEEE 754 64-bit floating point numbers.
#define f64_s_size   (1)
#define f64_e_size   (11)
#define f64_f_size   (52)

// Field offsets for IEEE 754 64-bit floating point numbers.
#define f64_s_offset (63)
#define f64_e_offset (52)
#define f64_f_offset (0)

// Field masks for IEEE 754 64-bit floating point numbers.
#define f64_s_mask   ((u64) 0x8000000000000000)
            // Sign bit.
            
#define f64_e_mask   ((u64) 0x7FF0000000000000)
            // Biased exponent part.
            
#define f64_f_mask   ((u64) 0x000FFFFFFFFFFFFF)
            // Fraction part bits.
            
#define f64_i_mask   ((u64) 0x0010000000000000)
            // Implied leading one bit for normalized 
            // numbers.

// Key values.
#define f64_bias     (1023)

/*------------------------------------------------------------
| Parsedf64
|-------------------------------------------------------------
|
| PURPOSE: To hold the values of f64 fields in parsed form.
|
| DESCRIPTION:
|
| NOTE:  
|
| ASSUMES: f64 is in IEEE 754 64-bit format.
|
| HISTORY: 02.05.00
------------------------------------------------------------*/
struct Parsedf64
{
    u8  s;  // The value of the sign bit field. 
            //
    s16 e;  // The value of the biased exponent field. 
            // 
    u64 f;  // The value of the fraction field (significand 
            // without leading bit.)
};
    
/*------------------------------------------------------------
| ParsedNumberString
|-------------------------------------------------------------
|
| PURPOSE: To hold a number string in parsed form.
|
| DESCRIPTION:
| 
| Represents the content of a number formatted like this:
|
|     [+|-] [digits] [.digits] [e|E [-|+] digits]
|
| Anything in brackets is optional.  If items are separated
| by vertical bars, only one of those items may be in that
| position.  See p. 25 of ANM for formal grammar.
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 02.05.00
------------------------------------------------------------*/
struct ParsedNumberString
{
    //////////////////////////////////////////////////////////
    //                                                      //
    //                     S T A T U S                      //
    //                                                      //
    u8      IsValidParse;                                   //
    //          '1' if no rules have been violated during   // 
    //          the parse or '0' if there was an error.     //
    //                                                      //
    u8      IsZero;                                         //
    //          '1' if the value of the number is zero or   //  
    //          '0' if not.                                 //
    //                                                      //
    u8      IsInfinity;                                     //
    //          '1' if infinity is signified or '0' if not. //
    //                                                      //
    u8      IsNaN;                                          //
    //          '1' if Not-A-Number is signified or '0' if  // 
    //          not.                                        //
    //                                                      //
    //////////////////////////////////////////////////////////
       
    //////////////////////////////////////////////////////////
    //                                                      //
    //                    E X P O N E N T                   //
    //                                                      //
    u8      IsSignInExponent;                               //
    //          '1' if the exponent is negative,            //
    //          '0' if not.                                 //
    //                                                      //
    u8      IsExponentMarker;                               //
    //          '1' if there is a 'e' or 'E' character      //
    //          in the number string.                       //
    //                                                      //
    u8      ExponentDigitCount;                             //
    //          Number of digits in the exponent string.    //
    //                                                      //
    s8      ExponentString[ NUMBER_STRING_BUFFER_SIZE ];    //
    //          The exponent digits without any sign,       //
    //          0 terminated.                               //
    //                                                      //
    u16     ExponentValue;                                  //
    //          The binary value of the exponent without    //
    //          any sign.                                   //
    //                                                      //
    //////////////////////////////////////////////////////////
 
    //////////////////////////////////////////////////////////
    //                                                      //
    //                 S I G N I F I C A N D                //
    //                                                      //
    u8      IsSignInSignificand;                            //
    //          '1' if the significand is a negative value  //
    //          or '0' if not.                              //
    //                                                      //
    u8      IsDecimalPoint;                                 //
    //          '1' if there is a decimal point in the      //
    //          significand.                                //
    //                                                      //
    u16     SignificandDigitCount;                          //
    //          Number of digits found in the significand.  //
    //                                                      //
    u16     CountOfDigitsToRightOfDecimal;                  //
    //          Number of digits in the significand to      //
    //          the right of the decimal point.             //
    //                                                      //
    s8      SignificandString[ NUMBER_STRING_BUFFER_SIZE ]; //
    //          Holds the significand digits without any    //
    //          sign; 0 terminated.                         //
    //                                                      //
    u64     SignificandValue;                               //
    //          The binary value of the significand without //
    //          any sign.                                   //
    //                                                      //
    //////////////////////////////////////////////////////////
};
    
f64     Chop( f64 );
f64     Compare( f64, f64 );
u32     Convertf64ToString( f64, s8*, u32 );
f64     ConvertStringTof64( s8* );
u32     Eq( f64, f64 );
u32     IsSameSign( f64, f64 );
void    Parsef64( f64*, Parsedf64* );
void    ParseNumberString( s8*, ParsedNumberString* );
f64     Sign( f64 );
s8*     strf64( f64, s32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
