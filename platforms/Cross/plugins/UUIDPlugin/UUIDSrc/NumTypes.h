/*------------------------------------------------------------
| NumTypes.h  
|-------------------------------------------------------------
|
| PURPOSE: To explicitly define the size of numeric data 
|          types.
|
| DESCRIPTION: The types defined in this file follow these
| conventions:
|
| 1) The prefix letter indicates the interpretation of the 
|    number, whether the number is signed, 's', or unsigned
|    'u' or floating point, 'f'. 
|
| 2) The suffix number explicitly states the number of bits 
|    in each type.
|
| Revise the definitions in this file to suit the compiler
| for the current target.
|
| HISTORY: 12.09.99 Tim Lee from 'TLTypes.h', following the
|                   practice once used by Hyphen Corporation.
|
|          02.14.00 Added NUMTYPES_H define because some
|                   compilers don't recognize typedefs as
|                   being defined.
|
------------------------------------------------------------*/

#ifndef NUMTYPES_H
#define NUMTYPES_H

// DATA TYPES ------------------------------------------------

// Abbreviated integer types.
typedef unsigned char       u8;         
typedef unsigned short      u16; 
typedef unsigned long       u32; 
typedef char                s8;
typedef short               s16; // range: +/-        32,768 
typedef long                s32; // range: +/- 2,147,483,647

// For 64-bit integers...
//
// ... for Metrowerks compiler.
#if __MWERKS__
typedef unsigned long long  u64;
typedef long long           s64; 
#endif // __MWERKS__

// ...for Microsoft Visual C++, as recommended by:
// http://premium.microsoft.com/msdn/library/devprods/vs6/vc++/aralpha/html/int64.htm
#if defined( _MSC_VER ) && !defined( __MWERKS__ ) && defined( _INTEGRAL_MAX_BITS ) && ( _INTEGRAL_MAX_BITS >= 64 )
typedef unsigned __int64    u64; // VC++ doesn't fully support this type: use s64 instead.
typedef __int64             s64;
#endif // _MSC_VER

// Abbreviated floating point types.
typedef float               f32;
typedef double              f64;

#endif // NUMTYPES_H
 
