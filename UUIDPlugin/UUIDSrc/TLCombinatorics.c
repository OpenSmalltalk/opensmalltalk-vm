/*------------------------------------------------------------
| TLCombinatorics.c
|-------------------------------------------------------------
|
| PURPOSE: To provide combinatorics functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 04.16.96
------------------------------------------------------------*/
    
#include <string.h>
#include <stdio.h>

#include "TLTarget.h"
#include "NumTypes.h"
#include "TLCombinatorics.h"

/*------------------------------------------------------------
| Combinations
|-------------------------------------------------------------
|
| PURPOSE: To calculate the number of combinations of 'n' 
|          things taken 'r' at a time.
|
| DESCRIPTION: 
|                         n!
|              nCr = ----------- 
|                     r! (n-r)!  
|
| EXAMPLE:  
|
|         i = Combinations( 34, 5 );
|
| NOTE: From 'CMATH', 'COMBIN.C'.
|
| ASSUMES: 'n' and 'r' are positive integers.
|
| HISTORY: 04.16.96
------------------------------------------------------------*/
f64 
Combinations( f64 n, f64 r )
{
    f64     denom,k,nmr;
    f64     prod;
 
    denom = r;
    
    nmr = n - r;
    
    if( nmr < r )
    {
        denom = nmr;
    }
    
    prod = 1.;
    
    for( k = 0; k < denom; k++ )
    { 
        prod *= (n-k)/(denom-k);
    }
    
    return( prod );
}

/*------------------------------------------------------------
| DegreeOfTrend
|-------------------------------------------------------------
|
| PURPOSE: To measure the degree of up trend vs. down trend.
|
| DESCRIPTION: Finds the permutation number and reverse
| permutation number for a series of items and then expresses
| the relative degree of upness versus downness as a number
| between 0 and 1, with 1 being perfect uptrend and 0 being
| perfect down trend.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.22.96 
-----------------------------------------------------------*/
f64
DegreeOfTrend( f64* Items, s32 Count )
{
    f64 OffsetFactor;
    s32  i, j,IntervalCount;
    f64 Sum, RevSum, RevSubSum, SubSum;
    
    OffsetFactor = 1;
    Sum    = 0;
    RevSum = 0;
    
    // For each interval amount from minor to major order.
    for( i = 1; i < Count; i++ )
    {
        // Calculate the number of intervals of size 'i'.
        IntervalCount = Count - i;
        
        // For each interval from beginning to end.
        SubSum    = 0;
        RevSubSum = 0;
        for( j = 0; j < IntervalCount; j++ )
        {
            SubSum    += Items[j] < Items[j+i];
            RevSubSum += Items[j] > Items[j+i];
        }
        
        // Accumulate the overall sum.
        Sum    += SubSum    * OffsetFactor;
        RevSum += RevSubSum * OffsetFactor;
        
        // Increase the offset factor for next set of
        // intervals.
        OffsetFactor *= Count - i + 1;
    }
    
    if( Sum == RevSum )
    {
        return( .5 );
    }
    
    return( Sum / (Sum+RevSum) );
}

/*------------------------------------------------------------
| DegreeOfTrend2
|-------------------------------------------------------------
|
| PURPOSE: To measure the degree of up trend vs. down trend.
|
| DESCRIPTION: Finds the permutation number and reverse
| permutation number for a series of items and then expresses
| the relative degree of upness versus downness as the 
| difference in the logs of the permutations numbers.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.22.96 from 'DegreeOfTrend'.
-----------------------------------------------------------*/
f64
DegreeOfTrend2( f64* Items, s32 Count )
{
    f64 OffsetFactor;
    s32  i, j,IntervalCount;
    f64 Sum, RevSum, RevSubSum, SubSum;
    
    OffsetFactor = 1;
    Sum    = 0;
    RevSum = 0;
    
    // For each interval amount from minor to major order.
    for( i = 1; i < Count; i++ )
    {
        // Calculate the number of intervals of size 'i'.
        IntervalCount = Count - i;
        
        // For each interval from beginning to end.
        SubSum    = 0;
        RevSubSum = 0;
        for( j = 0; j < IntervalCount; j++ )
        {
            SubSum    += Items[j] < Items[j+i];
            RevSubSum += Items[j] > Items[j+i];
        }
        
        // Accumulate the overall sum.
        Sum    += SubSum    * OffsetFactor;
        RevSum += RevSubSum * OffsetFactor;
        
        // Increase the offset factor for next set of
        // intervals.
        OffsetFactor *= Count - i + 1;
    }
    
    if( Sum == RevSum )
    {
        return( 0 );
    }
    
    return( log(Sum) - log(RevSum) );
}

/*------------------------------------------------------------
| Factorial
|-------------------------------------------------------------
|
| PURPOSE: To find the factorial of an integer.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|         i = Factorial( 4 ); // i == 24
|
| NOTE:  
|
| ASSUMES: 'n' is a positive integer.
|
| HISTORY: 12.08.95 
------------------------------------------------------------*/
f64
Factorial( f64 n )
{
    f64 f;
    
    f = 1;
    
    while( n > 1 )
    {
        f *= n;
        n--;
    }
    
    return( f );
}

/*------------------------------------------------------------
| PermutationNumberOfBytes
|-------------------------------------------------------------
|
| PURPOSE: To compute the permutation number which specifies 
|          the ordering of a given number of values.
|
| DESCRIPTION: Given some value in a certain order, symbolized
| by 'A', 'B', 'C' and 'D' for example:
|
|           A   B   C   D
|
| If there are 4 items then the number of permutations is 
| 4!.  The permutation number is computed so as to increase
| in value as the ordering approaches ascending order.  This
| is accomplished by progressing from major to minor 
| comparisons, thus:
|
|          A   B   C   D
|          ^___________^    A < D
|          ^_______^        A < C
|              ^_______^    B < D
|          ^___^            A < B
|              ^___^        B < C
|                  ^___^    C < D
|
| The permutation number is then computed as:
|
| PermutationNumber = ( (A < B) + (B < C) + (C < D ) ) + 
|                     ( (A < C) + (B < D) ) * 4 +
|                     (A < D) * 12
|
| Returns a value from 0 to n!-1, where n is the item count.
|
| EXAMPLE 1:  
|
|          8   3   9   2
|          A   B   C   D
|          ^___^            A < B = 0
|              ^___^        B < C = 1
|                  ^___^    C < D = 0
|          ^_______^        A < C = 1
|              ^_______^    B < D = 0
|          ^___________^    A < D = 0
|
| PermutationNumber = ( 0 + 1 + 0 ) + 
|                     ( 1 + 0 ) * 4 +
|                     0 * 12 
|
|                   = 5
|
| EXAMPLE 2:  
|
|          2   3   8   9
|          A   B   C   D
|          ^___^            A < B = 1
|              ^___^        B < C = 1
|                  ^___^    C < D = 1
|          ^_______^        A < C = 1
|              ^_______^    B < D = 1
|          ^___________^    A < D = 1
|
| PermutationNumber = ( 1 + 1 + 1 ) + 
|                     ( 1 + 1 ) * 4 +
|                     1 * 12 
|
|                   = 23
|
| NOTE: The permutation number of a set of prices can be used
|       as a measure of the ordinal degree of trend.
|
|       Not presently consistent with 'NthPermutation', but
|       they should be inverses of one another.
|
| ASSUMES: Result can fit in 32 bits.
|
| HISTORY: 07.21.96 Tested.
-----------------------------------------------------------*/
s32
PermutationNumberOfBytes( u8* Bytes, s32 Count )
{
    s32 OffsetFactor;
    s32 i, j,IntervalCount;
    s32 Sum, SubSum;
    
    OffsetFactor = 1;
    Sum = 0;
    
    // For each interval amount from minor to major order.
    for( i = 1; i < Count; i++ )
    {
        // Calculate the number of intervals of size 'i'.
        IntervalCount = Count - i;
        
        // For each interval from beginning to end.
        SubSum= 0;
        for( j = 0; j < IntervalCount; j++ )
        {
            SubSum += Bytes[j] < Bytes[j+i];
        }
        
        // Accumulate the overall sum.
        Sum += SubSum * OffsetFactor;
        
        // Increase the offset factor for next set of
        // intervals.
        OffsetFactor *= Count - i + 1;
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| PermutationNumberOfItems
|-------------------------------------------------------------
|
| PURPOSE: To compute the permutation number which specifies 
|          the ordering of a given number of floating point
|          values.
|
| DESCRIPTION: See 'PermutationNumberOfBytes'.
|
| EXAMPLE:  
|
| NOTE: The permutation number of a set of prices can be used
|       as a measure of the ordinal degree of trend.
|
|       Not presently consistent with 'NthPermutation', but
|       they should be inverses of one another.
|
| ASSUMES: Result can fit in f64.
|
| HISTORY: 07.21.96 Tested.
-----------------------------------------------------------*/
f64
PermutationNumberOfItems( f64* Items, s32 Count )
{
    f64 OffsetFactor;
    s32  i, j,IntervalCount;
    f64 Sum, SubSum;
    
    OffsetFactor = 1;
    Sum = 0;
    
    // For each interval amount from minor to major order.
    for( i = 1; i < Count; i++ )
    {
        // Calculate the number of intervals of size 'i'.
        IntervalCount = Count - i;
        
        // For each interval from beginning to end.
        SubSum= 0;
        for( j = 0; j < IntervalCount; j++ )
        {
            SubSum += Items[j] < Items[j+i];
        }
        
        // Accumulate the overall sum.
        Sum += SubSum * OffsetFactor;
        
        // Increase the offset factor for next set of
        // intervals.
        OffsetFactor *= Count - i + 1;
    }
    
    return( Sum );
}
        
/*------------------------------------------------------------
| ReversePermutationNumberOfItems
|-------------------------------------------------------------
|
| PURPOSE: To compute the permutation number which specifies 
|          the ordering of a given number of floating point
|          values.
|
| DESCRIPTION: Same as 'PermutationNumberOfItems' but with 
| the standard order descending instead of ascending.
|
| EXAMPLE:  
|
| NOTE: The permutation number of a set of prices can be used
|       as a measure of the ordinal degree of trend.
|
| ASSUMES: Result can fit in f64.
|
| HISTORY: 07.21.96 Tested.
-----------------------------------------------------------*/
f64
ReversePermutationNumberOfItems( f64* Items, s32 Count )
{
    f64 OffsetFactor;
    s32  i, j,IntervalCount;
    f64 Sum, SubSum;
    
    OffsetFactor = 1;
    Sum = 0;
    
    // For each interval amount from minor to major order.
    for( i = 1; i < Count; i++ )
    {
        // Calculate the number of intervals of size 'i'.
        IntervalCount = Count - i;
        
        // For each interval from beginning to end.
        SubSum= 0;
        for( j = 0; j < IntervalCount; j++ )
        {
            SubSum += Items[j] > Items[j+i];
        }
        
        // Accumulate the overall sum.
        Sum += SubSum * OffsetFactor;
        
        // Increase the offset factor for next set of
        // intervals.
        OffsetFactor *= Count - i + 1;
    }
    
    return( Sum );
}
        
/*------------------------------------------------------------
| NthPermutation
|-------------------------------------------------------------
|
| PURPOSE: To make a permutation of an array of 32-bit values.
|
| DESCRIPTION: Leaves the array at 'Src' unmodified, returning
| the permuted array at 'Dst'.
|
|
| 1. Copy 'Src' array to 'Dst', with items pictured as:
| 
|         [1][2][3][4][5]
|
| 2. Set 'PickCount' to 0.
|
| 3. Set 'Range' equal to the number of items in 'Src', 'n'.
|
|         |    Range    |
|         [1][2][3][4][5]
|
| 4. If 'Range' is less than 2, return.
|
| 5. Set n = n mod Factorial(Range).
|
| 6. Set i = n / Factorial(Range-1);
|
| 7. If 'i' is 0 then the item is correctly positioned, go
|    to step 10.
|
| 8. Use 'PickCount' (say it was 0) and 'i' (suppose it was 2) 
|    to pick a value from the array, setting 
|    variable 'v' = Dst[PickCount+i], in this example...
| 
|         [1][2][3][4][5]
|                ^--- v = Dst[0+2] = 3.
|
| 9. Shift the entries between 'PickCount' and 'i', upward
|    to take up the space held by the value just picked.
| 
|         [1][2][.][4][5]
|         |    |-->
|            |    |    
|         [.][1][2][4][5]
|
| 10. Put the picked value at 'Dst[PickCount]'
|
|         [3]
|          |
|         [3][1][2][4][5]
|          ^_ PickCount = 0, on first pass.
|
| 11. Increment 'PickCount'.
|
| 12. Decrement 'Range' and go to step 4.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 'n' ranges from 1 to ItemCount!.
|
| HISTORY: 12.09.95 
|          12.22.95 copied algorithm from Mathematica w/o
|                   the bug.  Validated using 
|                   'Test_NthPermutation'.
-----------------------------------------------------------*/
void
NthPermutation( u32 *Src, u32* Dst, u32 ItemCount, u32 n )
{
    u32 v;
    u32 i;
    u32 Range;
    u32 PickCount;
    
    // Copy the source array to the destination.
    memcpy( (void*) Dst, 
            (void*) Src, 
            (size_t) ItemCount << 2 );
    
    PickCount = 0;
    Range = ItemCount;

BeginLoop:
    
    if( Range < 2 )
    {
         return;
    }
    
    // Select the item to pick.
    n = n % (u32) Factorial( (f64) Range );

    i = n / (u32) Factorial( (f64) Range-1 );
    
    // If 'i' is zero then it is in the right place:
    // go to the next item.
    if( i == 0 ) 
    {
        goto NextItem;
    }
    
    // Pick up the value of the item.
    v = Dst[ PickCount + i ];
    
    // Shift the un-picked items to the right to 
    // take up the space of the picked item.
    memmove( (void*)  &Dst[ PickCount + 1 ], 
             (void*)  &Dst[ PickCount ], 
             (size_t) i << 2 );
    
    // Append the picked value to the end of the
    // picked items.  
    Dst[ PickCount ] = v;

NextItem:
    
    // Prepare for the next item.
    PickCount++;
    Range--;
    
    goto BeginLoop;
}

/*------------------------------------------------------------
| Permutations
|-------------------------------------------------------------
|
| PURPOSE: To calculate the number of permutations of 'n' 
|          things taken 'r' at a time.
|
| DESCRIPTION: 
|                        n!
|              nPr = ---------- 
|                      (n-r)!  
|
| EXAMPLE:  
|
|         i = Permutations( 34, 5 );
|
| NOTE: From 'CMATH', 'COMBIN.C'.
|
| ASSUMES: 'n' and 'r' are positive integers.
|
| HISTORY: 04.16.96
------------------------------------------------------------*/
f64 
Permutations( f64 n, f64 r )
{
    f64     k;
    f64     prod;
 
    if( r > n )
    {
        return( 0.0 );
    }
    
    prod = 1.;
    
    for( k=0; k < r; k++ )
    {
        prod *= (n-k);
    }
    
    return( prod );
}

