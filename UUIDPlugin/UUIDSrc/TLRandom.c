/*------------------------------------------------------------
| TLRandom.c
|-------------------------------------------------------------
|
| PURPOSE: To provide pseudo-random number functions.
|
| TO DO: Make sure the new algorithm installed on 05.06.01 
|        matches the test case from George Marsaglia.
|
| HISTORY: 05.06.01 Moved copyrighted material to 
|                   TLRandomPrivate.c and installed SWB
|                   algorithm from sci.math news article by 
|                   George Marsaglia <geo@stat.fsu.edu> 
|                   "Random numbers for C: The END?" posted 
|                   20 Jan 1999, found on the web at
|                   http://www.io.com/~ritter/NEWS4/RANDC.HTM.
|          06.12.01 Moved less commonly used functions to
|                   TLRandomExtra.c.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include "TLBytes.h"

#include "TLRandom.h"

u32     IsRandomGeneratorSetUp = 0;
            // This is set to '1' the first time the
            // random number generator has been set up.
        
#define znew   (z=36969*(z&65535)+(z>>16))
#define wnew   (w=18000*(w&65535)+(w>>16))
#define MWC    ((znew<<16)+wnew )
#define SHR3  (jsr^=(jsr<<17), jsr^=(jsr>>13), jsr^=(jsr<<5))
#define CONG  (jcong=69069*jcong+1234567)
#define FIB   ((b=a+b),(a=b-a))
#define KISS  ((MWC^CONG)+SHR3)
#define LFIB4 (c++,t[c]=t[c]+t[UC(c+58)]+t[UC(c+119)]+t[UC(c+178)])
#define SWB   (c++,bro=(x<y),t[c]=(x=t[UC(c+34)])-(y=t[UC(c+19)]+bro))
#define UNI   (KISS*2.328306e-10)
#define VNI   ((long) KISS)*4.656613e-10
#define UC    (unsigned char)  /*a cast operation*/
typedef unsigned long UL;

/* Use random seeds to reset z,w,jsr,jcong,a,b, and the table t[256]*/

/* Example procedure to set the table, using KISS: */
// void settable(UL i1,UL i2,UL i3,UL i4,UL i5, UL i6)
// { int i; z=i1;w=i2,jsr=i3; jcong=i4; a=i5; b=i6;
// for(i=0;i<256;i=i+1)  t[i]=KISS;
// }

static u32 z=362436069, w=521288629, jsr=123456789, jcong=380116160;
static u32 a=224466889, b=7584631, t[256];
static u32 x=0, y=0, bro=0; 
static u8  c=0;

//#define SWB   (c++,bro=(x<y),t[c]=(x=t[(u8)(c+34)])-(y=t[(u8)(c+19)]+bro))
 
// c++;
// bro = x < y;
// x=t[(u8)(c+34)];
// y=t[(u8)(c+19)]+bro;
// t[c] = x - y;

/*------------------------------------------------------------
| RandomBit
|-------------------------------------------------------------
|
| PURPOSE: To generate a uniform random bit.
|
| DESCRIPTION: 
|
| EXAMPLE: r = RandomBit();
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 05.08.97 from 'RandomInteger'.
|          07.14.97 added cacheing of bits.
|          05.06.01 Applied Marsaglia's public domain SWB 
|                   algorithm.
------------------------------------------------------------*/
s32
RandomBit()
{
    static u32  Bits;
    static u32  BitCount = 0;
    s32 b;
    
    // If need to get more bits.
    if( BitCount == 0 )
    {
        // Generate 32 new bits.
        Bits = SWB;
        
        // Account for the new bits.
        BitCount = 32;  
    }
    
    // Get the low bit.
    b = Bits & 1;
    
    // Shift bits to right and consume the bit.
    Bits = Bits >> 1;
    
    // Account for the bit used.
    BitCount--;

    // Return the result.
    return( (s32) b );
}

/*------------------------------------------------------------
| RandomBytes
|-------------------------------------------------------------
|
| PURPOSE: To generate uniform random bytes.
|
| DESCRIPTION: 
|
| EXAMPLE: RandomBytes( B, n );
|
| NOTE: This can be sped up by 
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 03.03.99 from 'RandomIntegers'.
|          05.06.01 Replaced Knuth's subtractive method from
|                   Numerical Recipes with Marsaglia's public
|                   domain SWB algorithm.
------------------------------------------------------------*/
void
RandomBytes( u8* A, u32 Count )
{
    u32  r;
     
    // As long as more than 3 bytes remain to be generated.
    while( Count > 3 )
    {
        // Generate a new unsigned 32-bit value using the
        // SWB algorithm.
        r = SWB;
           
        // Put the 4 bytes to the destination.
        *A++ = (u8) r; r = r >> 8;
        *A++ = (u8) r; r = r >> 8;
        *A++ = (u8) r; r = r >> 8;
        *A++ = (u8) r; 
        
        // Account for the bytes generated.
        Count -= 4;
    }
    
    // If there are any left over bytes to generate.
    while( Count-- )
    {
        // Generate a new unsigned 32-bit value using the
        // SWB algorithm.
        r = SWB;
           
        // Put the low byte to the destination.
        *A++ = (u8) r;  
    }
}

/*------------------------------------------------------------
| RandomFraction
|-------------------------------------------------------------
|
| PURPOSE: To generate a uniform random deviate between 0.0 
|          and 1.0. 
|
| DESCRIPTION: 
|
| EXAMPLE: r = RandomFraction();
|
| NOTE: from 'Numerical Recipes in C' page 212-213. Based on 
|       Knuth's subtractive method.
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 12.20.94 .
|          07.16.97 revised to avoid &a[] form which is buggy
|                    in CW.
|          05.06.01 Replaced Knuth's subtractive method from
|                   Numerical Recipes with Marsaglia's public
|                   domain SWB algorithm.
------------------------------------------------------------*/
f64
RandomFraction()
{
    u32  r;
    f64  f;
    
    // Generate new random unsigned 32-bit value.
    r = SWB;
    
    // Make a floating point fraction in the range 0 < 1.0.
    // TODO: faster way of doing this to avoid divide.
    f = ((f64) r) / (f64) ( (u32) 0xFFFFFFFF );
      
    return( f );  
}

/*------------------------------------------------------------
| RandomInteger
|-------------------------------------------------------------
|
| PURPOSE: To generate a uniform random integer from 0 to
|          N, excluding N.
|
| DESCRIPTION: The algorithm used is SWB, a fast subtract-
| with-borrow generator by George Marsaglia, his comments 
| follow: 
|
| "SWB is a subtract-with-borrow generator that I developed 
|  to give a simple method for producing extremely long 
|  periods: 
|
|      x(n) = x(n-222) - x(n-237) - borrow mod 2^32.
|
|  The 'borrow' is 0, or set to 1 if computing x(n-1) caused 
|  overflow in 32-bit integer arithmetic. 
|
|  This generator has a very long period, 2^7098(2^480-1), 
|  about 2^7578.   
|
|  Subtract-with-borrow has the same local behaviour as 
|  lagged Fibonacci using +,-,xor--- the borrow merely 
|  provides a much longer period.
|
|  It seems to pass all tests of randomness, except for the 
|  Birthday Spacings test, which it fails badly, as do all 
|  lagged Fibonacci generators using +, - or xor. Those 
|  failures are for a particular case: m = 512 birthdays in 
|  a year of n=2^24 days. There are choices of m and n for 
|  which lags >1000 will also fail the test.  A reasonable 
|  precaution is to always combine a 2-lag Fibonacci or SWB 
|  generator with another kind of generator, unless the 
|  generator uses *, for which a very satisfactory sequence 
|  of odd 32-bit integers results."
|
| EXAMPLE: r = RandomInteger(N);
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 12.24.94 .
|          03.20.96 changed to set the upper bound to fit
|                   with 'SubRandomInteger' usage.
|          07.16.97 revised to avoid &a[] form which is buggy
|                    in CW.
|          05.06.01 Replaced Knuth's subtractive method from
|                   Numerical Recipes with Marsaglia's public
|                   domain SWB algorithm.
------------------------------------------------------------*/
s32
RandomInteger( s32 n )
{
    u32  r;
    s32  Result;
    f64  f;
    
    // Generate new random unsigned 32-bit value.
    r = SWB;
    
    // Make a floating point fraction in the range 0 < 1.0.
    // TODO: faster way of doing this to avoid divide.
    f = ((f64) r) / (f64) ( (u32) 0xFFFFFFFF );
    
    // Scale the random fraction to the range.
    Result = (s32) (f * ((f64) n));
    
    // If the result is n.
    if( Result == n )
    {
        Result--;
    }
    
    return( Result );
}

/*------------------------------------------------------------
| RandomIntegerFromRange
|-------------------------------------------------------------
|
| PURPOSE: To generate a uniform random integer from Lo to
|          Hi, including Lo and Hi.
|
| DESCRIPTION: 
|
| EXAMPLE: r = RandomIntegerFromRange(1,10);
|
| NOTE: 
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 06.03.97
------------------------------------------------------------*/
s32
RandomIntegerFromRange( s32 Lo, s32 Hi )
{
    s32 Diff;
    
    Diff = (Hi - Lo) + 1;
    
    return( RandomInteger( Diff ) + Lo );
}

/*------------------------------------------------------------
| RandomIntegers
|-------------------------------------------------------------
|
| PURPOSE: To generate uniform random integers between 0 and
|          N, excluding N.
|
| DESCRIPTION: 
|
| EXAMPLE: r = RandomInteger(N);
|
| NOTE: from 'Numerical Recipes in C' page 212-213. Based on 
|       Knuth's subtractive method.
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 05.11.97 from 'RandomInteger'.
|          07.16.97 revised to avoid &a[] form which is buggy
|                    in CW.
|          05.06.01 Revised to just call RandomInterger.
------------------------------------------------------------*/
void
RandomIntegers( s32* Integers, s32 Count, s32 n )
{
    s32  i;

    for( i = 0; i < Count; i++ )
    {   
        Integers[i] = RandomInteger( n );
    }   
}


/*------------------------------------------------------------
| RandomValueFromRange
|-------------------------------------------------------------
|
| PURPOSE: To generate a uniform random floating point value
|          within a given range.
|
| DESCRIPTION: 
|
| EXAMPLE: r = RandomValueFromRange( 15.2, 123.12 );
|
| NOTE: Need to to clarify the bounds of this function.
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 12.24.94 .
|          07.16.97 revised to avoid &a[] form which is buggy
|                   in CW.
|          05.06.01 Just call RandomFraction().
------------------------------------------------------------*/
f64
RandomValueFromRange( f64 low, f64 high )
{
    return( RandomFraction() * (high - low) + low );  
}

/*------------------------------------------------------------
| SetUpRandomNumberGenerator
|-------------------------------------------------------------
|
| PURPOSE: To initialize the random number generator with a
|          given seed.
|
| DESCRIPTION: 
|
| EXAMPLE:  u32 MySeed = 12314;
|
|           SetUpRandomNumberGenerator( MySeed );
| 
| HISTORY:  12.24.94 From 'Numerical Recipes in C'. Based on 
|                    Knuth's subtractive method.
|           07.16.97 revised to avoid &a[] form which is buggy
|                    in CW. Fixed typo 'i' should have been '1'.
|                    The typo bug has been here for years 
|                    resulting in inability to init to known
|                    state when object code loads at different
|                    locations.
|           12.04.98 Added 'IsRandomGeneratorSetUp'.
|           05.06.01 Revised to base on George Marsaglia's  
|                    code instead of code from Numerical 
|                    Recipes.
|           06.18.01 Added initialization of other working
|                    static variables, x, y, bro, c.
------------------------------------------------------------*/
void
SetUpRandomNumberGenerator( u32 NewSeed )
                                // A 32-bit value used to 
                                // initialize the random 
                                // number generator.
{
    s32 i; 
    
    // Set static variables to values used in Marsaglia's
    // test case.
    z     = 12345;
    w     = 65435;
    jsr   = 34221; 
    jcong = 12345; 
    a     = 9983651; 
    b     = 95746118;
    
    // Initialize other static variables.
    x     = 0;
    y     = 0;
    bro   = 0;
    c     = 0;
    
    // Fill in the table to be used for SWB method by using
    // the KISS method, merging in the given seed.
    for( i = 0; i < 256; i++ )  
    {
        // Calculate a 32-bit random number using KISS
        // algorithm and XOR with given seed.
        t[i] = KISS ^ NewSeed;
    }
    
    // Set the status flag for the random number generator
    // to indicate that the generator has been set up.
    IsRandomGeneratorSetUp = 1;
}

/*------------------------------------------------------------
| ShuffleBytes
|-------------------------------------------------------------
|
| PURPOSE: To randomly shuffle bytes in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: ShuffleBytes( Buffer, 10 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.14.97 from 'ShuffleVector'.
------------------------------------------------------------*/
void
ShuffleBytes( u8* Bytes, u32 Count )
{
    u32 i;
    u32 a, b, v;
    
    for( i = 0; i < Count; i++ )
    {
        a = RandomInteger( (s32) Count );
        b = RandomInteger( (s32) Count );
        
        v = Bytes[a]; 
        
        Bytes[a] = Bytes[b];
         
        Bytes[b] = v;
    }
}

/*------------------------------------------------------------
| ShuffleIntegers
|-------------------------------------------------------------
|
| PURPOSE: To randomly shuffle values in an integer buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: ShuffleIntegers( Buffer, 10 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.14.97 from 'ShuffleVector'.
------------------------------------------------------------*/
void
ShuffleIntegers( u32* Integers, u32 Count )
{
    u32 i;
    u32 a, b, v;
    
    for( i = 0; i < Count; i++ )
    {
        a = RandomInteger( (s32) Count );
        b = RandomInteger( (s32) Count );
        
        v = Integers[a]; 
        
        Integers[a] = Integers[b];
         
        Integers[b] = v;
    }
}

/*------------------------------------------------------------
| ShufflePairs
|-------------------------------------------------------------
|
| PURPOSE: To randomly shuffle bytes in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: ShuffleBytes( Buffer, 10 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.19.01 from 'ShuffleIntegers'.
------------------------------------------------------------*/
void
ShufflePairs( u16* Pairs, u32 Count )
{
    u32 i;
    u32 a, b, v;
    
    for( i = 0; i < Count; i++ )
    {
        a = RandomInteger( (s32) Count );
        b = RandomInteger( (s32) Count );
        
        v = Pairs[a]; 
        
        Pairs[a] = Pairs[b];
         
        Pairs[b] = v;
    }
}


