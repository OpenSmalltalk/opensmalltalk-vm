/*------------------------------------------------------------
| TLTwo.c
|-------------------------------------------------------------
|
| PURPOSE: To provide functions associated with the number 2.
|
| HISTORY: 04.26.96 
------------------------------------------------------------*/

#include "TLTarget.h"  // Include this first.

#include "NumTypes.h"
#include "TLTwo.h"
#include "TLBit.h"

/*------------------------------------------------------------
| NotPowerOf2
|-------------------------------------------------------------
|
| PURPOSE: To provide the bit inverse of powers of 2.
|
| DESCRIPTION: Used to find the inverse bit mask associated 
| with a given bit.
|
|   Each entry takes the form:
|
|         [NotPowerOf2]
|           4 bytes
|       
|       and the (entry offset)/4 is equal to the bit inverse 
|       of the amount that 1 is shifted left to equal that 
|       number.
|
| EXAMPLE: 
|   
|      The inverse bit mask for bit 5 is at offset 20, 
|      NotPowerOf2[5].
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  06.24.96 from 'PowerOf2'.
|           01.20.99 Added 'U' to make size explicit.
------------------------------------------------------------*/
u32
NotPowerOf2[32] =
{
            ~1U, // 1 << 0 = 2 ^ 0
            ~2U,
            ~4U,
            ~8U, 
           ~16U,
           ~32U,
           ~64U,
          ~128U,
          ~256U,
          ~512U,
         ~1024U,
         ~2048U,
         ~4096U,
         ~8192U,
        ~16384U,
        ~32768U,
        ~65536U,
       ~131072U,
       ~262144U,
       ~524288U,
      ~1048576U,
      ~2097152U,
      ~4194304U,
      ~8388608U,
     ~16777216U,
     ~33554432U,
     ~67108864U,
    ~134217728U,
    ~268435456U,
    ~536870912U,
   ~1073741824U,
   ~2147483648U
};
 
/*------------------------------------------------------------
| PowerOf2
|-------------------------------------------------------------
|
| PURPOSE: To provide the powers of 2.
|
| DESCRIPTION: One application is to provide a way of finding 
| the shift count associated with multiplying or dividing by
| that power of 2. Another application is to find the bit mask 
| associated with a given bit.
|
|   Each entry takes the form:
|
|         [PowerOf2]
|           4 bytes
|       
|       and the (entry offset)/4 is equal to the amount that 
|       1 is shifted left to equal that number.
|
| EXAMPLE: 
|   
|   1.  [2] is at offset 4, so to multiply of divide by 2, 
|       shift left or right by 1 (4/4).
|
|   2.  The mask for bit 5 is at offset 20, 
|       PowerOf2[5].
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  05.25.90
|           04.26.96 from Sage file, 'Math.a'.
------------------------------------------------------------*/
u32
PowerOf2[32] =
{
             1, // 1 << 0 = 2 ^ 0
             2,
             4,
             8, 
            16,
            32,
            64,
           128,
           256,
           512,
          1024,
          2048,
          4096,
          8192,
         16384,
         32768,
         65536,
        131072,
        262144,
        524288,
       1048576,
       2097152,
       4194304,
       8388608,
      16777216,
      33554432,
      67108864,
     134217728,
     268435456,
     536870912,
    1073741824,
    2147483648
};

/*------------------------------------------------------------
| PowerOfPowerOf2
|-------------------------------------------------------------
|
| PURPOSE: To provide the powers of powers of 2.
|
| DESCRIPTION:                               A B
|                PowersOfPowersOf2[A][B] = (2 )
|
| EXAMPLE: 
|   
|
| NOTE: Table produced using this routine:
|
|   {
|       s32  i, j;
|       f64 v;
|       
|       printf("u32\n");
|       printf("PowerOfPowerOf2[32][32] =\n");
|       printf("{\n");
|       for( i = 0; i < 32; i++ )
|       {
|           printf("    {   ");
|           for( j = 0; j < 32; j++ )
|           {
|               v = pow( pow( 2.0, (f64) i ), (f64) j );
|               
|               // Truncate values that would overflow.
|               if( v > pow( 2.0, 32 ) )
|               {
|                   v = 0;
|               }
|               
|               if( j != 31 )
|               {
|                   printf( "%u,    ", (u32) v );
|               }
|               else
|               {
|                   printf( "%u },\n", (u32) v );
|               }               
|           }
|       }
|       printf( "};\n" );
|   }
|
| ASSUMES: 
|
| HISTORY: 04.26.96 
------------------------------------------------------------*/
u32
PowerOfPowerOf2[32][32] =
{
    {   1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  
        1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  
        1,  1,  1,  1 },
    {   1,  2,  4,  8,  16, 32, 64, 128,    256,    512,    
        1024,   2048,   4096,   8192,   16384,  32768,  65536,  
        131072, 262144, 524288, 1048576,    2097152,    4194304,    
        8388608,    16777216,   33554432,   67108864,   134217728,  
        268435456,  536870912,  1073741824, 2147483648 },
    {   1,  4,  16, 64, 256,    1024,   4096,   16384,  65536,  
        262144, 1048576,    4194304,    16777216,   67108864,   
        268435456,  1073741824, 4294967295, 0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  8,  64, 512,    4096,   32768,  262144, 2097152,    
        16777216,   134217728,  1073741824, 0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0 },
    {   1,  16, 256, 4096,   65536,  1048576,    16777216,   
        268435456,  4294967295, 0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0 },
    {   1,  32, 1024,   32768,  1048576,    33554432,   
        1073741824, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  64, 4096,   262144, 16777216,   1073741824, 0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  128,    16384,  2097152,    268435456,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  256,    65536,  16777216,   4294967295, 0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  512,    262144, 134217728,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  1024,   1048576,    1073741824, 0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  2048,   4194304,    0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0 },
    {   1,  4096,   16777216,   0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0 },
    {   1,  8192,   67108864,   0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0 },
    {   1,  16384,  268435456,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0 },
    {   1,  32768,  1073741824, 0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0 },
    {   1,  65536,  4294967295, 0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0 },
    {   1,  131072, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0 },
    {   1,  262144, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0 },
    {   1,  524288, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0 },
    {   1,  1048576,    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  2097152,    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  4194304,    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  8388608,    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  16777216,   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  33554432,   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  67108864,   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  134217728,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  268435456,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  536870912,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  1073741824, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 },
    {   1,  2147483648, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
        0,  0,  0,  0,  0,  0 }
};

/*------------------------------------------------------------
| Log2ForHalfToOne
|-------------------------------------------------------------
|
| PURPOSE: To compute the base 2 log of a number in the range
|          .5 <= 1.
|
| DESCRIPTION: Uses an approximation generated using 
| Mathematica 'EconomizedRationalApproximation' as follows:
|
|
|   pd = SetPrecision[
|       N[EconomizedRationalApproximation[
|           Log[2,x],{x,{.5,1},8,8}]], 32]
|
| Precision is rounded to 14 decimal places, near the 15 or 16 
| digit limit of an 'f64'.
| 
| The constants used will support 128 bit floating point
| calculations.
|                          
| Validated by comparison with 'Mathematica'.
|
| EXAMPLE: 
|
| NOTE: Roughly as precise as 'Log2ForZeroToOne'.
|
| ASSUMES: .5 <= x <= 1.
|
| HISTORY:  08.12.96
------------------------------------------------------------*/
f64
Log2ForHalfToOne( f64 x )
{
    f64 X, X2, L2;
    f64 X3, X4, X5, X6, X7, X8;
    f64 Numer, Denom;

    X   = x - .75;
    X2  = X   * X;
    X3  = X   * X2;
    X4  = X2  * X2;
    X5  = X3  * X2;
    X6  = X3  * X3;
    X7  = X4  * X3;
    X8  = X4  * X4;
 
    Numer = -0.40288937170018929156967146809620 - 
            0.289453420280495365979334110306809   * X + 
            4.0355533825665474978450220078230     * X2 + 
            10.8861337096357360110232548322529    * X3 + 
            11.8447933015428539249569439562038    * X4 + 
            6.3907737263360626656094609643333     * X5 + 
            1.69332577030682651653137327230070    * X6 + 
            0.189886910572759359805417034294805   * X7 + 
            0.0057643119931949371448354213498533  * X8;
    
    Denom = 0.97073004824922393130037789887865 + 
            5.1965023069708120573295673239045       * X + 
            11.3617303700811493882838476565666      * X2 + 
            13.0392704917401740516424979432486      * X3 + 
            8.3949437212993913703940052073449       * X4 + 
            2.99799648363043758081403211690485      * X5 + 
            0.54736420757188308794383146960172      * X6 + 
            0.041846067504350624444153794456724     * X7 + 
            0.00077612505702798206819181814353215   * X8;
 
    L2 = Numer / Denom;
    
    return( L2 );
}

/*------------------------------------------------------------
| Log2ForZeroToOne
|-------------------------------------------------------------
|
| PURPOSE: To compute the base 2 log of a number in the range
|          0 < x <= 1.
|
| DESCRIPTION: 
|
| Uses Pade approximation produced by 'Mathematica'.
|
| Precision is 14 to 16 decimal places, that of 'f64'.
|                           
| Other Identities:
|
|            log(xy)  = log(x) + log(y)
|
|            log(x/y) = log(x) - log(y)
|
|            log(c^y) = y log(c)
|
|            log x = log x / log c
|               c       b       b
|
| Validated by comparison with 'Mathematica'.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 0 < x <= 1.
|
| HISTORY:  08.01.96 from p. 472 of 'CRC Standard Mathemaical
|                    Tables, 23rd Ed.'.
|           08.13.96 optimized characteristic extraction
|                    and replaced series with Pade 
|                    approximation.
------------------------------------------------------------*/
f64
Log2ForZeroToOne( f64 x )
{
    f64     X, X2, X3, X4, X5, X6, X7, X8;
    f64     Mantissa, Characteristic;
    s16     n[4], exponent;
    f64*    nn;
    f64     Numer, Denom;
    
    // Refer to the buffer used to extract the exponent
    // from the floating point number
    nn = (f64*) &n[0];
    
    // Store the floating point number in the buffer.
    *nn = x;
    
    // Extract the exponent: assumes no sign.
    exponent = (s16) ( n[0] >> 4 );
    
    // Log2 of the exponent part is found by finding
    // the difference from .5 exponent.  For example,
    // .1 has an exponent of 1019, and .5 has an
    // exponent of 1022, so the characteristic
    // (the integral part of the log) is 
    // (1019 - 1022) = -3.
    Characteristic = (f64) ( exponent - 1022 );
    
    // Shift x into the range 1/2 < x < 1.
    // Preserve the 4bits that are part of the fraction
    // and replace the exponent with that of .5.
    n[0] = (s16) ( (n[0] & 0x000f) | 0x3fe0 );
    x = *nn;

    // Economized Pade approximation produced using
    // Mathematica. See p.32 of 'Guide To Standard
    // Mathematica Packages'.
    X   = x - .75;
    X2  = X   * X;
    X3  = X   * X2;
    X4  = X2  * X2;
    X5  = X3  * X2;
    X6  = X3  * X3;
    X7  = X4  * X3;
    X8  = X4  * X4;
 
    Numer = -0.40288937170018929156967146809620 - 
            0.289453420280495365979334110306809   * X + 
            4.0355533825665474978450220078230     * X2 + 
            10.8861337096357360110232548322529    * X3 + 
            11.8447933015428539249569439562038    * X4 + 
            6.3907737263360626656094609643333     * X5 + 
            1.69332577030682651653137327230070    * X6 + 
            0.189886910572759359805417034294805   * X7 + 
            0.0057643119931949371448354213498533  * X8;
    
    Denom = 0.97073004824922393130037789887865 + 
            5.1965023069708120573295673239045       * X + 
            11.3617303700811493882838476565666      * X2 + 
            13.0392704917401740516424979432486      * X3 + 
            8.3949437212993913703940052073449       * X4 + 
            2.99799648363043758081403211690485      * X5 + 
            0.54736420757188308794383146960172      * X6 + 
            0.041846067504350624444153794456724     * X7 + 
            0.00077612505702798206819181814353215   * X8;
 
    // Make the fractional part.
    Mantissa = Numer / Denom;
    
    return( Characteristic + Mantissa );
}

/*------------------------------------------------------------
| Log2ForZeroToOneBySeriesMethod
|-------------------------------------------------------------
|
| PURPOSE: To compute the base 2 log of a number in the range
|          0 < x <= 1.
|
| DESCRIPTION: 
|
| Uses series approximation valid for the range
| from x > 0:
|
|              --                       --
|              |      1    3   1    5    |
|  ln(x) = 2 * |  z + - * z  + - * z ... |
|              |      3        5         |
|              --                       --
|                     (x-1)        
|         where: z = -------
|                     (x+1)
|
| Precision is 15 to 16 decimal places, that of 'f64'.
|                           
| Other Identities:
|
|            log(xy)  = log(x) + log(y)
|
|            log(x/y) = log(x) - log(y)
|
|            log(c^y) = y log(c)
|
|            log x = log x / log c
|               c       b       b
|
| Validated by comparison with 'Mathematica'.
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 0 < x <= 1.
|
| HISTORY:  08.01.96 from p. 472 of 'CRC Standard Mathemaical
|                    Tables, 23rd Ed.'.
|           08.13.96 Superceded by Pade approx method.
|           07.15.96 commented out because it requires global
|                    register optimization with may be buggy.
------------------------------------------------------------*/
#if 0
f64
Log2ForZeroToOneBySeriesMethod( f64 x )
{
    f64 X, X2, Ln, L2, Characteristic;
    f64 X3, X5, X7, X9, X11, X13, X15, X17, X19;
    f64 X21, X23, X25, X27, X29, X31;
    s16     n[4], exponent;
    f64*   nn;
    
    // Refer to the buffer used to extract the exponent
    // from the floating point number
    nn = (f64*) &n[0];
    
    // Store the floating point number in the buffer.
    *nn = x;
    
    // Extract the exponent: assumes no sign.
    exponent = n[0] >> 4;
    
    // Log2 of the exponent part is found by finding
    // the difference from .5 exponent.  For example,
    // .1 has an exponent of 1019, and .5 has an
    // exponent of 1022, so the characteristic
    // (the integral part of the log) is 
    // (1019 - 1022) = -3.
    Characteristic = (f64) ( exponent - 1022 );
    
    // Shift x into the range 1/2 < x < 1.
    // Preserve the 4bits that are part of the fraction
    // and replace the exponent with that of .5.
    n[0] = (n[0] & 0x000f) | 0x3fe0;
    x = *nn;

    // For 15 terms minimizes the differences between
    // the 'log2' function and this one: any more terms
    // offers no improvement.

    X  = (x - 1.)/(x + 1.);
    
    X2  = X   * X;
    X3  = X   * X2;
    X5  = X3  * X2;
    X7  = X5  * X2;
    X9  = X7  * X2;
    X11 = X9  * X2;
    X13 = X11 * X2;
    X15 = X13 * X2;
    X17 = X15 * X2;
    X19 = X17 * X2;
    X21 = X19 * X2;
    X23 = X21 * X2;
    X25 = X23 * X2;
    X27 = X25 * X2;
    X29 = X27 * X2;
    X31 = X29 * X2;

    Ln = X + 
         X3  * (1./3.)  + 
         X5  * (1./5.)  +
         X7  * (1./7.)  + 
         X9  * (1./9.)  +
         X11 * (1./11.) +
         X13 * (1./13.) +
         X15 * (1./15.) +
         X17 * (1./17.) +
         X19 * (1./19.) +
         X21 * (1./21.) +
         X23 * (1./23.) +
         X25 * (1./25.) +
         X27 * (1./27.) +
         X29 * (1./29.) +
         X31 * (1./31.);
  
#ifdef SLIGHTLY_MORE_ACCURATE 
// Takes 3 times as long to run.
    Ln = X + 
         X3  /  3. + 
         X5  /  5. +
         X7  /  7. + 
         X9  /  9. +
         X11 / 11. +
         X13 / 13. +
         X15 / 15. +
         X17 / 17. +
         X19 / 19. +
         X21 / 21. +
         X23 / 23. +
         X25 / 25. +
         X27 / 27. +
         X29 / 29. +
         X31 / 31.; 
#endif 
     
    // Convert the natural log to log2.
    L2 = Characteristic + (2. * Ln) / NaturalLogOfTwo;

    return( L2 );
}
#endif
