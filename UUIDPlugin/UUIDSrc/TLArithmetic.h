/*------------------------------------------------------------
| FILE NAME: Arithmetic.h
|
| PURPOSE: To provide interface for multiple-precision
|          arithmetic.
|
| DESCRIPTION: 
|
| Number formats:
|
|  'UBin'   -- Unsigned binary ASCII digits terminated by a 
|              zero byte.  The ordering of digits is either
|              low-order first or high-order first.
|
|              For example, one hundred and twenty three is 
|              written in UBin form as "1101111" or as
|              "1111011".
|
|  'UDec'   -- Unsigned decimal ASCII digits terminated by a 
|              zero byte.  The ordering of digits is either
|              low-order first or high-order first.
|
|              For example, one hundred and twenty three is 
|              written in UDec form as "123" or as "321".
|
|  'UHex'   -- Unsigned hexadecimal ASCII digits terminated 
|              by a zero byte.  The ordering of digits is 
|              either low-order first or high-order first.
|
|              For example, one hundred and twenty three is 
|              written in UHex form as "7B" or as "B7".
|
|  'UOct'   -- Unsigned binary ASCII digits terminated by a 
|              zero byte.  The ordering of digits is either
|              low-order first or high-order first.
|
|              For example, one hundred and twenty three is 
|              written in UOct form as "371" or as "173".
|
|  'ULoBin' -- Unsigned low-order first binary ASCII digits
|              terminated by a zero byte.
|
|              For example, one hundred and twenty three is 
|              written in ULoBin form as "1101111".
|
|  'ULoDec' -- Unsigned low-order first decimal ASCII digits
|              terminated by a zero byte. 
|
|              For example, one hundred and twenty three is 
|              written in ULoDec form as "321".
|
|  'ULoHex' -- Unsigned low-order first hexadecimal ASCII 
|              digits terminated by a zero byte.  
|
|              Alpha digits are uppercase.
|
|              For example, one hundred and twenty three is 
|              written in ULoHex form as "B7".
|
|  'ULoOct' -- Unsigned low-order first octal ASCII 
|              digits terminated by a zero byte. 
|
|              For example, one hundred and twenty three is 
|              written in ULoOct form as "371".
|
| NOTE: 
|
| HISTORY:  03.07.97
------------------------------------------------------------*/

#ifndef _ARITHMETIC_H_
#define _ARITHMETIC_H_


void        AddASCIIDecimal( s8*, s8*, s8* );
void        AddULoDec( s8*, s8*, s8* );
s32         CompareASCIIDecimal( s8*, s8* );
s32         CompareULoDec( s8*, s8* );
void        ConvertASCIIBinaryToASCIIHex( s8*, s8* );
void        ConvertASCIIBinaryToASCIIOctal( s8*, s8* );
s32         ConvertASCIIHexDigitToInteger( s32 );
void        ConvertASCIIHexToASCIIBinary( s8*, s8* );
void        ConvertUHiHexToUHiBin( s8*, s8* );
void        ConvertULoBinToULoDec( s8*, s8* );
void        ConvertULoBinToULoHex( s8*, s8* );
void        ConvertULoBinToULoOct( s8*, s8* );
void        ConvertULoDecToULoBin( s8*, s8* );
void        ConvertULoHexToULoBin( s8*, s8* );
void        ConvertUOctToUBin( s8*, s8* );
void        DivideULoDec( s8*, s8*, s8* );
void        DivideByTwoULoDec( s8*, s8* );
void        DivideWithRemainderULoDec( s8*, s8*, s8*, s8* );
u32         IsOddULoDec( s8* );
void        ModuloULoDec( s8*, s8*, s8* );
void        MultiplyULoDec( s8*, s8*, s8* );
void        ShortMultiplyULoDec( s8*, s8*, s32 );
void        SubtractASCIIDecimal( s8*, s8*, s8* );
void        SubtractULoDec( s8*, s8*, s8* );
void        TimesPowerOfTenULoDec( s8*, s8*, s32 );

#endif
