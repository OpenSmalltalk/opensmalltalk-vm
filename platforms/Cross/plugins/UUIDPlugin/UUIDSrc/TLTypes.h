/*------------------------------------------------------------
| TLTypes.h
|-------------------------------------------------------------
|
| PURPOSE: To make it easier to say what you mean.
|
| DESCRIPTION: 
|
|   The 8-bit 'u8' is taken as the basic unit of storage.
|    
|   Edit the 'typedef' statements in this file so that they 
|   are 1 of your compiler.
|    
|   To avoid ambiguity, use the types defined in this 
|   file in place of the systematically ambiguous types:
|   'int', 'short', 'long' etc.
|
| NOTE: 
| 
| HISTORY: 11.08.93 
|          12.30.93 added 'Number*'
|          02.26.94 pulled out malloc-related defines.
|          02.27.94 added 'RenamedTypes.h'.
|          08.19.97 added C++ support.
|          08.20.97 conformed to Code Warrior PowerPlant 
|                   integer types.
|          06.16.98 added integer types with short names.
|          12.29.98 Added Intel support.
|          01.19.99 Added Microsoft compiler support.
|          12.17.99 Separated out "NumTypes.h".
------------------------------------------------------------*/

#ifndef TLTYPES_H
#define TLTYPES_H

#ifdef __cplusplus
extern "C"
{
#endif

#include "NumTypes.h"

// To test if compiling for Win32 on Intel processor use 
// the following:
//
// #if defined( __INTEL__ ) || defined( _M_IX86 )


#define kMaxLong    0x7fffffff // from 'NewsWatcher'
#define kMaxShort   0x7fff     // from 'NewsWatcher'

/* Comparison values are interpreted as follows:

   Given two values, A and B, in which A is the left-most
   parameter of a comparison procedure:
   
             SomeComparisonProcedure( A, B );
   
   Comparison Value    Condition
        0              if A = B.
    positive number    if A > B.
    negative number    if A < B.
    
    Comparison values are used for searching and sorting
    procedures.
*/

// Types that refer to procedures of various kinds:
typedef void    (*AnyProcedure)();  
typedef u8      (*u8Procedure)();
typedef s32     (*CompareProc)( u8*, u8* );
typedef u16     (*u16Procedure)();
typedef u32     (*u32Procedure)();
typedef s16     (*s16Procedure)();
typedef s32     (*s32Procedure)();


// Floating point types borrowed from 'Hyphen': 
typedef long double     f128;  // Exact size unknown.[]

// Use 'NoNum' in place of 'NAN' because 'NAN' can't be used in
// comparisons.  'NoNum' is used as a placeholder for missing
// data values.  The value allocated to 'NoNum' should not be used for
// any other purpose.
#define NoNum   ((f64) -123456789.987654321)

#define twopi   (pi*2.0)
#define piby2   (pi/2.0)
#define piby4   (pi/4.0)
#define piby8   (pi/8.0)
#define piby16  (pi/16.0)


#define RoundToInt(x) ( ((x) > 0.) ? ( (s32)( (x) + .5 ) ) : ( (s32)( (x) - .5 ) ) ) 

#ifndef min
#define min(x,y)      ((x)>(y)?(y):(x))
#endif

#ifndef max
#define max(x,y)      ((x)>(y)?(x):(y))
#endif

// The following floating point types are for high-precision base-10
// arithmetic and number conversions.

#define Number   long double 

//#define Number     double
typedef struct
{
    Number  Numerator;      
    Number  Denominator;
} Ratio;

// A 'DecimalNumber' can be converted to a 'Number' like this:
//
//        ANumber = ADecimalNumber.BinaryPart * 
//                  pow( (Number) 10, (Number) ADecimalNumber.DecimalExponent );
//
//
typedef struct
{
    Number  BinaryPart;      
    s16     DecimalExponent; // of denominator.
} DecimalNumber;

//
//         C O M P L E X   N U M B E R S
//

typedef struct ComplexNumberRecord
{
    // First part: Real part / Modulus / X / radius vector
    f64 a; // Cartesian form: the real number part: X coordinate.
            // Polar form: the length of the vector, the modulus.

    // Second part: Imaginary part / Argument / Y / vectorial angle.
    f64 b; // Cartesian form: the imaginary part  
            // Polar form: the angle of the vector, the argument 
} CX;

#ifdef macintosh

// Define 'CopyBytes' as 'BlockMoveData' because that routine is
// tuned to the processor.  The arguments are the same.
// ASSUMES: The data being moved doesn't contain 68K instructions:
//          see Technote 1008.
#ifndef BlockMoveData
#include <Memory.h> // For Release 3: <MacMemory.h>
#endif

// 'BlockMoveData' is built into the firmware and is optimized
// for each PowerPC processor so it's much faster than the
// generic 'CopyBytes' routine.
#define CopyBytes   BlockMoveData

// Define the CPU-specific timing functions:
#define GetTimeCPU      GetTimePPC
#define ElapsedTimeCPU  ElapsedTimePPC

#else // Not Mac.

// 'GetTickCount()' returns ticks in milliseconds but the MacOS
// function 'TickCount()' returns ticks in roughly 1/60th of a second.  
// This macro handles the conversion.
#define TickCount() ( (u32) ( ( (u64) GetTickCount() * (u64) 60 ) / (u64) 1000 ) )

// Define the CPU-specific timing functions:
#define GetTimeCPU      GetTimeNT
#define ElapsedTimeCPU  ElapsedTimeNT

// From 'MacTypes.h'.
struct Rect 
{
    short   top;
    short   left;
    short   bottom;
    short   right;
};

typedef struct Rect Rect;
typedef Rect*       RectPtr;

typedef long        Fixed;
typedef Fixed *     FixedPtr;

typedef char *      Ptr;
typedef Ptr *       Handle;

typedef u8*         WindowPtr;
typedef Handle      TEHandle;

#endif // macintosh

// If 'size_t' isn't defined...
//
// ... on Metrowerks compiler.
#if defined( __MWERKS__ ) && !defined( __size_t__ )
#include <size_t.h>
#endif

// ... on Microsoft compiler.
#if defined( _MSC_VER ) && !defined( __MWERKS__ ) && !defined( _SIZE_T_DEFINED )
#include <stddef.h>
#endif // _SIZE_T_DEFINED

// Extra support for memory management.
#ifndef _TLMEM_H_
//#include "TLMem.h" 
#endif

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLTYPES_H
