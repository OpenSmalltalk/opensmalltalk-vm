/*------------------------------------------------------------
| TLSubRandom.c
|-------------------------------------------------------------
|
| PURPOSE: To provide functions for sub-random number 
|          generation.
|
| DESCRIPTION: From 'Numerical Recipes In C' p. 309:
|
| "Sequences of n-tuples that fill n-space more uniformly
|  than uncorrelated random points are called 'quasi-random
|  sequences'.  That term is somewhat of a misnomer, since
|  there is nothing "random" about quasi-random sequences:
|  they are cleverly crafted to be, in fact, sub-random.
|  The sample points in a quasi-random sequence are, in a
|  precise sense, "maximally avoiding" of each other."
|
| Sub-random selection more completely ranges across 
| the sample space than does pseudo-random selection.
| Use this method to get the most information for the least
| work.
|
| The method used here was developed by Sobol' and improved
| by Antonov and Saleev.
| 
| HISTORY: 01.29.96 from 'Numerical Recipes in C'
------------------------------------------------------------*/

#include "TLTarget.h"

#include <stdio.h>

#include "NumTypes.h"

#include "TLSubRandom.h"


f64 fac; // Scaling factor.

u32  in, ix[MAXDIM+1], *iu[MAXBIT+1];

u32  mdeg[MAXDIM+1] = { 0, 1, 2, 3, 3, 4, 4 };

u32  ip[MAXDIM+1]   = { 0, 0, 1, 1, 2, 1, 4 };

u32 
iv[ MAXDIM*MAXBIT+1 ] =
{
     0, 1,  1,  1,  1,
     1, 1,  3,  1,  3,
     3, 1,  1,  5,  7, 
     7, 3,  3,  5, 15, 
    11, 5, 15, 13,  9
}; 

/*------------------------------------------------------------
| BeginSubRandomSequence
|-------------------------------------------------------------
|
| PURPOSE: To initialize the sub-random number generator to
|          start a given point in the sequence.
|
| DESCRIPTION: Sets up the generator and then cycles it the
| given number of times.
|
| "Initializes a set of MAXBIT direction numbers for each of
|  MAXDIM different Sobol' sequences."
|
| This procedure must be called if the number of dimensions
| required for each generated point is changed.
|
| EXAMPLE:  s32 Nth = 10;
|           BeginSubRandomSequence( Nth );
|
| NOTE: If starting point is very large, it could take a 
|       long time for this routine to complete.
|
| ASSUMES: 
|
| HISTORY:  01.29.96
------------------------------------------------------------*/
void
BeginSubRandomSequence( s32 Nth )
{
    u32 i, ipp;
    s32 j,k,l;
    
    for( k = 1; k <= MAXDIM; k++ )
    {
        ix[k] = 0;
    }
    
    in = 0;
    
    if( iv[1] != 1 ) return;
    
    fac = 1.0 / ( 1L << MAXBIT );
    
    // To allow both 1D and 2D addressing.
    for( j = 1, k = 0; j <= MAXBIT; j++, k+=MAXDIM )
    {
        iu[j] = &iv[k];
    }
    
    for( k = 1; k <= MAXDIM; k++ )
    {
        // Stored values only need normalization.
        for( j = 1; j <= mdeg[k]; j++ )
        {
            iu[j][k] <<= (MAXBIT-j);
        }
        
        // Use recurrence to get other values.
        for( j = mdeg[k]+1; j <= MAXBIT; j++ )
        {
            ipp = ip[k];
            i = iu[j-mdeg[k]][k];
            i ^= (i >> mdeg[k]);
            
            for( l = mdeg[k] - 1; l >= 1; l-- )
            {
                if( ipp & 1 ) i ^= iu[j-l][k];
                ipp >>= 1;
            }
            iu[j][k] = i;
        }
        
    }
    
    // Advance to the nth point.
    while( Nth )
    {
        SubRandomFraction();
    }
}

/*------------------------------------------------------------
| SubRandomFraction
|-------------------------------------------------------------
|
| PURPOSE: To generate the next 1 dimensional sub-random 
|          fraction in the current sequence.
|
| DESCRIPTION: Returns a number between 0.0 and 1.0. 
|
| EXAMPLE: r = SubRandomFraction();
|
| NOTE: 
|
| ASSUMES: 'BeginSubRandomSequence' called at least once.
|
| HISTORY: 01.29.96
|          01.31.96 added reset on overflow.
------------------------------------------------------------*/
f64
SubRandomFraction()
{
    u32 im;
    s32 j, k;

TryAgain:
    
    im = in++; // Calculate next number in sequence.
    
    // Find rightmost zero bit.
    for( j = 1; j <= MAXBIT; j++ )
    {
        if( !(im & 1) ) break;
        im >>= 1;
    }
    
    // Test for overflow.
    if( j > MAXBIT ) 
    {
        BeginSubRandomSequence( 0 );
        goto TryAgain;
    }
    
    im = (j-1) * MAXDIM;
    
    // XOR the appropriate direction number into each
    // component of the vector and convert to a floating
    // point number.  1D case doesn't need loop here: deleted.
    
    k = 1;
    
    ix[k] ^= iv[im+k];
    
    return( ix[k] * fac );
}

/*------------------------------------------------------------
| SubRandomInteger
|-------------------------------------------------------------
|
| PURPOSE: To generate a sub-random integer between 0 and
|          N, excluding N.
|
| DESCRIPTION: 
|
| EXAMPLE: r = SubRandomInteger(n);
|
| NOTE: 
|
| ASSUMES: 'BeginSubRandomSequence' called at least once.
|
| HISTORY: 01.29.96
|          01.31.96 added reset on overflow.
------------------------------------------------------------*/
s32
SubRandomInteger( s32 n )
{
    u32  im;
    s32  j, k;
    s32  Result;

TryAgain:
    
    im = in++; // Calculate next number in sequence.
    
    // Find rightmost zero bit.
    for( j = 1; j <= MAXBIT; j++ )
    {
        if( !(im & 1) ) break;
        im >>= 1;
    }
    
    // Test for overflow.
    if( j > MAXBIT ) 
    {
        BeginSubRandomSequence( 0 );
        goto TryAgain;
    }
    
    im = (j-1) * MAXDIM;
    
    // XOR the appropriate direction number into each
    // component of the vector and convert to a floating
    // point number.  1D case doesn't need loop here: deleted.
    
    k = 1;
    
    ix[k] ^= iv[im+k];
    
    // Scale the sub-random fraction to the range.
    Result = (s32) (ix[k] * fac * ((f64) n));
    
    // Exclude the exact upper bound. If 'ix[k] * fac' == 1
    // then the result could exactly equal 'n', which is 
    // out of range.
    if( Result == n )
    {
        Debugger(); // Does this ever happen?
        goto TryAgain;
    }
    
    return( Result );
}

/*------------------------------------------------------------
| SubRandomIntegers
|-------------------------------------------------------------
|
| PURPOSE: To generate sub-random integers between 0 and
|          N, excluding N.
|
| DESCRIPTION: 
|
| EXAMPLE: r = SubRandomInteger(n);
|
| NOTE: 
|
| ASSUMES: 'BeginSubRandomSequence' called at least once.
|
| HISTORY: 05.12.97
------------------------------------------------------------*/
void
SubRandomIntegers( s32* Integers, s32 Count, s32 n )
{
    s32  i;
    u32  im;
    s32  j, k;
    s32  Result;

    for( i = 0; i < Count; i++ )
    {   
TryAgain:
    
        im = in++; // Calculate next number in sequence.
    
        // Find rightmost zero bit.
        for( j = 1; j <= MAXBIT; j++ )
        {
            if( !(im & 1) ) break;
            im >>= 1;
        }
    
        // Test for overflow.
        if( j > MAXBIT ) 
        {
            BeginSubRandomSequence( 0 );
            goto TryAgain;
        }
    
        im = (j-1) * MAXDIM;
    
        // XOR the appropriate direction number into each
        // component of the vector and convert to a floating
        // point number.  1D case doesn't need loop here: deleted.
    
        k = 1;
    
        ix[k] ^= iv[im+k];
    
        // Scale the sub-random fraction to the range.
        Result = (s32) (ix[k] * fac * ((f64) n));
    
        // Exclude the exact upper bound. If 'ix[k] * fac' == 1
        // then the result could exactly equal 'n', which is 
        // out of range.
        if( Result == n )
        {
            Debugger(); // Does this ever happen?
            goto TryAgain;
        }
    
        // Scale the random fraction to the range.
        Integers[i] = Result;
    }   
}

/*------------------------------------------------------------
| SubRandomValueFromRange
|-------------------------------------------------------------
|
| PURPOSE: To generate a sub-random floating point value
|          within a given range.
|
| DESCRIPTION: 
|
| EXAMPLE: r = SubRandomValueFromRange( 15.2, 123.12 );
|
| NOTE:  
|
| ASSUMES: 'BeginSubRandomSequence' called at least once.
|
| HISTORY: 01.29.96
|          01.31.96 added reset on overflow.
------------------------------------------------------------*/
f64
SubRandomValueFromRange( f64 low, f64 high )
{
    u32  im;
    s32  j, k;
    f64 Result;

TryAgain:
    
    im = in++; // Calculate next number in sequence.
    
    // Find rightmost zero bit.
    for( j = 1; j <= MAXBIT; j++ )
    {
        if( !(im & 1) ) break;
        im >>= 1;
    }
    
    // Test for overflow.
    if( j > MAXBIT ) 
    {
        BeginSubRandomSequence( 0 );
        goto TryAgain;
    }
    
    im = (j-1) * MAXDIM;
    
    // XOR the appropriate direction number into each
    // component of the vector and convert to a floating
    // point number.  1D case doesn't need loop here: deleted.
    
    k = 1;
    
    ix[k] ^= iv[im+k];
    
    // Scale the sub-random fraction to the range and
    // apply the offset to the bottom of the range.
    Result = ix[k] * fac * (high - low) + low;
    
    return( Result );
}

/*------------------------------------------------------------
| SubRandomVector
|-------------------------------------------------------------
|
| PURPOSE: To generate the next n-dimensional sub-random 
|          vector in the current sequence.
|
| DESCRIPTION: Returns a vector of numbers between 0.0 and 1.0. 
|
| EXAMPLE:  SubRandomVector(&X);
|
| NOTE: 
|
| ASSUMES: 'BeginSubRandomSequence' called at least once.
|          'Dimensions' is less or equal to 'MAXDIM'.
|
| HISTORY: 01.29.96
|          01.31.96 added reset on overflow.
------------------------------------------------------------*/
void
SubRandomVector( f64* x, s32 Dimensions )
{
    u32 im;
    s32 j, k;

TryAgain:
    
    im = in++; // Calculate next number in sequence.
    
    // Find rightmost zero bit.
    for( j = 1; j <= MAXBIT; j++ )
    {
        if( !(im & 1) ) break;
        im >>= 1;
    }
    
    // Test for overflow.
    if( j > MAXBIT ) 
    {
        BeginSubRandomSequence( 0 );
        goto TryAgain;
    }
    
    im = (j-1) * MAXDIM;
    
    // XOR the appropriate direction number into each
    // component of the vector and convert to floating
    // point numbers.  
    
    for( k = 1; k <= Dimensions; k++ )
    {
        ix[k] ^= iv[im+k];
        x[k-1] = ix[k] * fac;
    }
}

/*------------------------------------------------------------
| Test_SubRandomVector
|-------------------------------------------------------------
|
| PURPOSE: To test the 'SubRandomVector' and 
|          'BeginSubRandomSequence' routines.
|
| DESCRIPTION: Compare results to those on page 133-134 of
| 'Numerical Recipes, Example Book [C]'. 
|
| EXAMPLE:  Test_SubRandomVector();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.29.96 from 'Numerical Recipes, Example Book [C]'.
|                   Results check with book.  See also
|                   'Permutation.c' for a visual test which
|                   confirms results.
------------------------------------------------------------*/
void
Test_SubRandomVector()
{
    s32  i;
    f64 x[3];
    
    BeginSubRandomSequence( 0 );
    
    for( i = 1; i <= 32; i++ )
    {
        SubRandomVector( x, 3 );
        
        printf(" %10.5f %10.5f %10.5f %5d\n",
               x[0], x[1], x[2], i );
    }
}


