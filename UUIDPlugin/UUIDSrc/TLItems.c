/*------------------------------------------------------------
| TLItems.c
|-------------------------------------------------------------
|
| PURPOSE: To provide number buffer functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 03.28.95 separated from 'Datum.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLListIO.h"
#include "TLStrings.h"

#include "TLStacks.h"
#include "TLParse.h"  // for 'ParseDatum'
#include "TLf64.h"
#include "TLNumber.h" // for 'ConvertStringToNumber'
                    // and 'ConvertNumberToString'
#include "TLVector.h"
#include "TLMatrixAlloc.h"
#include "TLWeight.h"
#include "TLItems.h"

/*------------------------------------------------------------
| AbsItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the absolute value of each item.
|
| DESCRIPTION:  
|
| EXAMPLE:  AbsItems( Items, Result, Count );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.28.97 from 'ReciprocalOfItems'. 
------------------------------------------------------------*/
void
AbsItems( f64* Items, f64* Result, s32 Count )
{
    f64 v;
    
    while( Count-- )
    {
        v = *Items++;
        
        if( v < 0 ) v = -v;
        
        *Result++ = v;
    }
}

/*------------------------------------------------------------
| AddItems
|-------------------------------------------------------------
|
| PURPOSE: To add one set of items to another.
|
| DESCRIPTION:  
|
| EXAMPLE:  AddItems( From, To, Count );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.28.96 
------------------------------------------------------------*/
void
AddItems( f64* From, f64* To, s32 Count )
{
    while( Count-- )
    {
        *To += *From;
        
        To++;
        From++;
    }
}

/*------------------------------------------------------------
| AddToItems
|-------------------------------------------------------------
|
| PURPOSE: To add a number to each item in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE:  AddToItems( Items, Count, .001 );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.28.96 from 'MultiplyToVector'. 
------------------------------------------------------------*/
void
AddToItems( f64* Items, s32 Count, f64 n )
{
    while( Count-- )
    {
        *Items += n;
        
        Items++;
    }
}

/*------------------------------------------------------------
| ChopItems
|-------------------------------------------------------------
|
| PURPOSE: To replace all numbers with a magnitude less than 
|          10^-10 with zero.
|
| DESCRIPTION:  
|
| EXAMPLE:    Chop( V, 100 );
|
| NOTE: From p. 541 of Mathematica.
|
| ASSUMES:  
|           
| HISTORY: 03.28.96 from 'VectorSum'.
|          04.29.96 replaced 'fabs' call with faster test.
------------------------------------------------------------*/
void
ChopItems( f64* Items, u32 Count )
{
    f64 v;
    
    while( Count-- )
    {
        v = *Items;
        v = ( v < 0 ) ? -v : v;
        
        if( v < .0000000001 )
        {
            *Items = 0;
        }
        
        Items++;
    }
}

/*------------------------------------------------------------
| CompareItems
|-------------------------------------------------------------
|
| PURPOSE: To compare two f64's.
|
| DESCRIPTION: A standard comparison function for use with
|              'SortList'.
|
| EXAMPLE:   
|
| NOTE: See also 'Compare_fl64' a similar routine for use
|       with 'qsort'.
|
| ASSUMES: 
|
| HISTORY: 12.24.95 
|          12.26.95 fixed truncation error.
------------------------------------------------------------*/
s32
CompareItems( s8* A, s8* B )
{
    f64     a,b;
    s32     r;
    
    a = *((f64*) A);
    b = *((f64*) B);
    
    if( a > b )
    {
        r = 1;
    }
    else
    {
        if( a < b )
        {
            r = -1;
        }
        else
        {
            r = 0;
        }
    }

    return( r );
}

/*------------------------------------------------------------
| CopyIndexedRowsOfItems
|-------------------------------------------------------------
|
| PURPOSE: To copy indexed rows from one buffer
|          to another.
|
| DESCRIPTION: Given items organized into rows of fixed length,
| copy indexed rows from source to target buffer.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 08.05.97 from 'CopyIndexedRows'.
------------------------------------------------------------*/
void
CopyIndexedRowsOfItems( 
    f64* From, 
    s32*  FromRows,
    f64* To, 
    s32*  ToRows, 
    s32   RowCount,
    s32   DimCount ) 
{
    s32    i, j;
    f64*  F;
    f64*  T;
    
    // For each row to be copied.
    for( i = 0; i < RowCount; i++ )
    {
        // Refer to the source and target addresses.
        F = From + FromRows[i] * DimCount;
        T = To   + ToRows[i]   * DimCount;
        
        // For each element of the row.
        for( j = 0; j < DimCount; j++ )
        {
            *T++ = *F++;
        }
    }
}

/*------------------------------------------------------------
| CopyItems
|-------------------------------------------------------------
|
| PURPOSE: To copy a number buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: CopyItems( From, To, Count );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.28.96 
------------------------------------------------------------*/
void
CopyItems( f64* From, f64* To, s32 Count )
{
    u32 ByteCount;
    
    // Calculate the size of the overall buffer.
    ByteCount = Count * sizeof(f64);
    
    // Copy the data.
    memcpy( (void*) To, (void*) From, ByteCount );
}

/*------------------------------------------------------------
| CountInstancesOfItem
|-------------------------------------------------------------
|
| PURPOSE: To count the number of times a value occurs in
|          a buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: c = CountInstancesOfItem( Buf, 15, .213 );
|
| NOTE: 
|
| ASSUMES: Exact equality for matching.
|           
| HISTORY: 07.29.97 
------------------------------------------------------------*/
s32
CountInstancesOfItem( f64* A, s32 Count, f64 x )
{
    s32 InstanceCount;
    
    InstanceCount = 0;
    
    while( Count-- )
    {
        if( *A++ == x )
        {
            InstanceCount++;
        }
    }
    
    // Return the result.
    return( InstanceCount );
}

/*------------------------------------------------------------
| DeltaItems
|-------------------------------------------------------------
|
| PURPOSE: To subtract each item from each following item
|          to produce a list of differences.
|
| DESCRIPTION: Returns the differences, which have a count of
|              one less than the input item count. 
|
| EXAMPLE:    DeltaItems( V, D, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.15.96 
------------------------------------------------------------*/
void
DeltaItems( f64* Items, f64* AtResult, u32 Count )
{
    f64 AnItem;
    f64 NextItem;
    
    AnItem = *Items++;
    
    Count--;
    
    while( Count-- )
    {
        NextItem = *Items++;
        
        *AtResult++ = NextItem - AnItem;
        
        AnItem = NextItem;
    }
}

/*------------------------------------------------------------
| DeltaItemSum
|-------------------------------------------------------------
|
| PURPOSE: To add up the deltas of the items in a buffer.
|
| DESCRIPTION: Returns the total of the sequential differences.
|
| EXAMPLE:    d = DeltaItemSum( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.15.96 
------------------------------------------------------------*/
f64
DeltaItemSum( f64* AtItems, s32 ItemCount )
{
    f64 AnItem;
    f64 NextItem;
    f64 Sum;
    
    Sum = 0;
    
    AnItem = *AtItems++;
    
    ItemCount--;
    
    while( ItemCount-- )
    {
        NextItem = *AtItems++;
        
        Sum += NextItem - AnItem;
        
        AnItem = NextItem;
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| DeltaItemSum2ndOrder
|-------------------------------------------------------------
|
| PURPOSE: To sum the second order differences in a list of 
|          values.
|
| DESCRIPTION: Returns the total of the 2nd order sequential 
|              differences, subtracting the first from the
|              following value.
|
| EXAMPLE:    d = DeltaItemSum2ndOrder( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.15.96 
------------------------------------------------------------*/
f64
DeltaItemSum2ndOrder( f64* Items, s32 Count )
{
    f64 AnItem;
    f64 NextItem;
    f64 ADiff;
    f64 NextDiff;
    f64 Sum;
    
    AnItem = *Items++;
    Count--;
    
    NextItem = *Items++;
    Count--;
    
    ADiff = NextItem - AnItem;

    AnItem = NextItem;
    
    Sum = 0;
    
    while( Count-- )
    {
        NextItem = *Items++;
        
        NextDiff = NextItem - AnItem;
        
        Sum += NextDiff - ADiff;
            
        ADiff  = NextDiff;      
        AnItem = NextItem;
    }
    
    return( Sum );
}

/* ------------------------------------------------------------
| DerivativeOfItems
|-------------------------------------------------------------
|
| PURPOSE: To approximate the derivative of an item buffer.
|
| DESCRIPTION: Returns a newly allocated buffer with n-4 
| values given a buffer of n values.  Uses the central 
| difference method with two reference points on either 
| side of a value item.
|
| Formula used:
|         
|            Ÿ(xo-2) - 8Ÿ(xo-1) + 8Ÿ(xo+1) - Ÿ(xo+2)
|   Ÿ'(xo) = --------------------------------------- + O(h^4)
|                              12h
|
| Where:  h = the x between y values, assumed to be 1 for
|             this implementation.
|
|         f(x) = the y value at displacement x
|
|         O(h^4) = the error term
|
| SOURCE: "Applied Numerical Analysis, 2nd Ed." by Curtis F.
|         Gerald, page 206.
|
| EXAMPLE:  
|
|    d = DerivativeOfItems( Dec92CopperSeries, Count );
|
| NOTE: Precision of 9 places has been found to
|       work best for one application. No rounding is being
|       done now. See page 204 of source for a discussion of 
|       roundoff and accuracy of derivatives.
|
| ASSUMES: 
|
| HISTORY:  05.23.92 
|           05.27.93 sped up: replaced 'Table' with 'Take'
|           06.04.93 translated from Mathematica
|           03.28.96 revised from 'DerivativeOfSeries'.
 ------------------------------------------------------------- */
f64*
DerivativeOfItems( f64* Items, u32 Count )
{
    u32     i;
    u32     ResultCount;
    f64*    R;
    
    // Round numbers to 9 decimal places. Disabled for now. 

    // The first two and the last two values of the given
    // list have no derivatives since they don't have the
    // required terms for the central difference 
    // approximation.
    //   
    ResultCount = Count - 4;
    
    // Make the result buffer.
    R = MakeItems( ResultCount, 0 );

    for( i = 0; i < ResultCount; i++ )
    {
        R[i] = 
            ( Items[i] - Items[i+1] * 8 + 
              Items[i+2] * 8 - Items[i+3] ) / 12;
    }       
       
    return( R );
}

/*------------------------------------------------------------
| DistanceOfEachToEach
|-------------------------------------------------------------
|
| PURPOSE: To calculate the distance from each value to each
|          other value in a buffer.
|
| DESCRIPTION: Calculates the magnitudes of each-to-each 
| differences.
|
| The smaller this number, the closer to uniform spacing.
|
| Returns a count of the results and puts the results in
| the given buffer.
|
|      The result count is computed as:
|
|                         (n^2) - n
|          ResultCount = -----------
|                            2
|
| EXAMPLE:   u = DistanceOfEachToEach( V, R, ItemCount );
|
| NOTE: Much faster than the alternative which required sorting.
|
| ASSUMES:  
|
| HISTORY: 02.15.96  
------------------------------------------------------------*/
f64
DistanceOfEachToEach( f64* Items, 
                      f64* AtResult, 
                      s32   ItemCount )
{
    s32  i,j;
    f64 *AtFollower;
    f64 a,f;
    s32  LastItem,ResultCount;
    
    ResultCount = ((ItemCount * ItemCount) - ItemCount)/2;

    // While there are results to produce.
    LastItem = ItemCount - 1;
    
    for( i = 0; i < LastItem; i++ )
    {
        // Get the first value.
        a =  *Items++;
        
        AtFollower = Items;
        
        for( j = i+1; j < ItemCount; j++ )
        {
            f = *AtFollower++;
            
            if( f > a )
            {
                *AtResult++ = f - a;
            }
            else
            {
                *AtResult++ = a - f;
            }
        }
    }
    
    return( ResultCount );
}

/*------------------------------------------------------------
| DistanceOfEachToEachSquaredSum
|-------------------------------------------------------------
|
| PURPOSE: To calculate the sum of the squared distance from 
|          each value to each other value in a vector.
|
| DESCRIPTION: Sums the squares of each-to-each differences.
| The smaller this number, the closer to uniform spacing.
|
| Returns a count of the results and puts the results in
| the given vector.
|
|      The result count is computed as:
|
|                         (n^2) - n
|          ResultCount = -----------
|                            2
|
| EXAMPLE:   u = DistanceOfEachToEachSquaredSum( V, ItemCount );
|
| NOTE: Much faster than the alternative which required sorting.
|
| ASSUMES:  
|
| HISTORY: 02.20.96 from 'DistanceOfEachToEachSum'.
------------------------------------------------------------*/
f64
DistanceOfEachToEachSquaredSum( f64* Items, s32 ItemCount )
{
    s32  i,j;
    s32  LastItem;
    f64 *AtFollower;
    f64 a,f;
    f64 Sum;
    f64 Diff;
    
    Sum = 0;
    
    // For each item but the last one
    LastItem = ItemCount - 1;
    
    for( i = 0; i < LastItem; i++ ) 
    {
        // Get the first value.
        a = *Items++;
        
        // Refer to the next value.
        AtFollower = Items;
        
        // Calculate the distance to all following items.
        j = LastItem - i;
        
        while( j-- )
        {
            f = *AtFollower++;
            
            Diff = f - a;
            
            Sum += Diff * Diff;
        }
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| DistanceOfEachToEachSum
|-------------------------------------------------------------
|
| PURPOSE: To calculate the sum of the distance from each 
|          value to each other value in a vector.
|
| DESCRIPTION: Sums the magnitudes of each-to-each differences.
| The smaller this number, the closer to uniform spacing.
|
| Returns a count of the results and puts the results in
| the given vector.
|
|      The result count is computed as:
|
|                         (n^2) - n
|          ResultCount = -----------
|                            2
|
| EXAMPLE:   u = UniformityOfSpacing2( V, ItemCount );
|
| NOTE: Much faster than the alternative which required sorting.
|
| ASSUMES:  
|
| HISTORY: 02.15.96  
------------------------------------------------------------*/
f64
DistanceOfEachToEachSum( f64* Items, s32 ItemCount )
{
    s32  i,j;
    s32  LastItem;
    f64 *AtFollower;
    f64 a,f;
    f64 Sum;
    
    Sum = 0;
    
    // For each item but the last one
    LastItem = ItemCount - 1;
    
    for( i = 0; i < LastItem; i++ ) 
    {
        // Get the first value.
        a = *Items++;
        
        // Refer to the next value.
        AtFollower = Items;
        
        // Calculate the distance to all following items.
        j = LastItem - i;
        
        while( j-- )
        {
            f = *AtFollower++;
            
            if( f > a )
            {
                Sum += f - a;
            }
            else
            {
                Sum += a - f;
            }
        }
    }
    
    return( Sum );
}

/*------------------------------------------------------------
| DuplicateItems
|-------------------------------------------------------------
|
| PURPOSE: To make a dynamic copy of a number buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: d = DuplicateItems( Items, n );
|
| NOTE: 
|
| ASSUMES: Will be freed using 'free'.
|           
| HISTORY: 03.28.96 
------------------------------------------------------------*/
f64*
DuplicateItems( f64* Items, u32 Count )
{
    f64*    B;
    u32     ByteCount;
    
    // Calculate the size of the overall buffer.
    ByteCount = Count * sizeof(f64);
    
    // Allocate the new buffer.
    B = (f64*) malloc( ByteCount );
    
    // Copy the data.
    memcpy( (void*) B, (void*) Items, ByteCount );
    
    // Return the buffer.
    return( B );
}

/*------------------------------------------------------------
| ExpItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the e^x of each item.
|
| DESCRIPTION:  
|
| EXAMPLE:  ExpItems( Items, Result, Count );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 08.22.96 from 'LogItems'. 
------------------------------------------------------------*/
void
ExpItems( f64* Items, f64* Result, s32 Count )
{
    while( Count-- )
    {
        *Result++ = exp( *Items++ );
    }
}

/*------------------------------------------------------------
| ExtentOfItems
|-------------------------------------------------------------
|
| PURPOSE: To find the smallest and largest values in a buffer.
|
| DESCRIPTION: Returns the min, max and range, the range being
| the return value. 
|
| EXAMPLE: s = ExtentOfItems( V, 100, &Min, &Max );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.02.96 
------------------------------------------------------------*/
f64
ExtentOfItems( f64* Items, u32 Count, 
               f64* AtMin, f64* AtMax )
{
    u32  i;
    f64 Lo, Hi,v;
    
    Lo = Hi = *Items++;
  
    for( i = 1; i < Count; i++ )
    {
        v = *Items++;
        
        if( v < Lo )
        {
            Lo = v;
        }
        else
        {
            if( v > Hi )
            {
                Hi = v;
            }
        }
    }
    
    *AtMin = Lo;
    *AtMax = Hi;
    
    return( Hi - Lo );
}

/*------------------------------------------------------------
| FillItems
|-------------------------------------------------------------
|
| PURPOSE: To put a number into each item in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE:  FillItems( Items, Count, .001 );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.17.97 from 'AddToItems'. 
------------------------------------------------------------*/
void
FillItems( f64* Items, s32 Count, f64 n )
{
    while( Count-- )
    {
        *Items = n;
        
        Items++;
    }
}

/*------------------------------------------------------------
| FindOffsetOfPlaceInOrderedVector
|-------------------------------------------------------------
|
| PURPOSE: To search a table of numbers sorted in increasing
|          order for the offset of the place where a given
|          value should be placed.
|
| DESCRIPTION: Uses fast binary search method.
|
| EXAMPLE:  
|
| i = FindOffsetOfPlaceInOrderedVector( In, InTable, ItemCount );
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 07.05.96 from 'FindOffsetOfValueInOrderedVector'.
|          07.05.97 moved from 'Statistics.c'.
------------------------------------------------------------*/
s32
FindOffsetOfPlaceInOrderedVector( 
    f64 Value, f64* Table, s32 ItemCount )
{
    s32     Lo,Mid,Hi;
    f64     Cond;
        
    Lo = 0;  
    Hi = ItemCount - 1;
    
    while( Lo <= Hi )
    {
        Mid = (Hi + Lo) >> 1; // (Hi+Lo)/2  

        Cond = Value - Table[Mid];    

        if( Cond == 0. )
        {    
            // Exact match.
            return( Mid );
        }

        if( Cond < 0. )  // Value < Table[Mid]
        {
            Hi = Mid - 1;
        }
        else // Value > Table[Mid]
        {
            Lo = Mid + 1;
        }
    }
    
    // Exact match not found.
    // 'Lo' refers to the place where it should go.
    return( Lo ); // 'Lo' is now the higher order entry.
}

/*------------------------------------------------------------
| FindOffsetOfValueInOrderedVector
|-------------------------------------------------------------
|
| PURPOSE: To search a table of numbers sorted in increasing
|          order for the offset of the entry containing a
|          value known to be in the table.
|
| DESCRIPTION: Uses fast binary search method.
|
| EXAMPLE:  
|
| i = FindOffsetOfValueInOrderedVector( In, InTable, ItemCount );
|
| NOTE:  
|
| ASSUMES: Given value is in the table.
|
| NOTE:
|
| HISTORY: 06.25.95 
|          07.05.97 moved from 'Statistics.c'.
------------------------------------------------------------*/
u32
FindOffsetOfValueInOrderedVector( 
    f64 Value, f64* Table, u32 ItemCount )
{
    s32     Lo, Mid, Hi;
    f64     Cond;
        
    Lo = 0;  
    Hi = (s32) ( ItemCount - 1 );
    
    while( Lo <= Hi )
    {
        Mid = (Hi + Lo) >> 1; // (Hi+Lo)/2  

        Cond = Value - Table[Mid];    

        if( Cond == 0 )
        {    
            // Exact match: this should always be the case.
            return( (u32) Mid );
        }

        if( Cond < 0 )  // Value < Table[Mid]
        {
            Hi = Mid - 1;
        }
        else // Value > Table[Mid]
        {
            Lo = Mid + 1;
        }
    }
    
    Debugger();
    return( 0 );
}

/*------------------------------------------------------------
| LoadItems
|-------------------------------------------------------------
|
| PURPOSE: To load floating point numbers from an ASCII file.
|
| DESCRIPTION: Reads the data previously written to a file
| using the 'SaveItems' procedure.  Returns the address of
| a dynamically allocated buffer or 0 if the file can't be
| opened.
|
| EXAMPLE: b = LoadItems( "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.17.97 from 'LoadVector'.
------------------------------------------------------------*/
f64*
LoadItems( s8* AFileName )
{
    u32     c, i;
    f64*    X;
    List*   L;
    
    // Read in the numbers in text format, one per line.
    L = ReadListOfTextLines( AFileName);
    
    // Make sure data read OK.
    if( L )
    {
        return(0);
    }
    
    // Allocate a buffer large enough for the numbers.
    X = MakeItems( L->ItemCount, 0 );
    
    // Convert the numbers to binary format.
    ReferToList( L );
    i = 0;
    while( TheItem )
    {
        c = CountDataInString( (s8*) TheDataAddress );

        // If there is data in this line then convert it
        // to binary and put it in the buffer.
        if( c == 1 )
        {
            X[i] = GetFirstDatumInString( 
                        (s8*) TheDataAddress );
            
            i++;
        }
        
        ToNextItem();   
    }
    
    RevertToList();
    
    DeleteListOfDynamicData( L );
    
    return( X );
}

/*------------------------------------------------------------
| Logis3Items
|-------------------------------------------------------------
|
| PURPOSE: To calculate the third order logistic of each item.
|
| DESCRIPTION:  
|
| EXAMPLE:  Logis3Items( Items, Result, Count );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 07.31.96 from 'AddToItems'. 
|          01.12.98 disabled to get this file to compile.
------------------------------------------------------------*/
void
Logis3Items( f64* Items, f64* Result, s32 Count )
{
    Debugger(); // Trap calls here because following is disabled.
#if 0  // 'Logis' isn't defined so disable for now.
    while( Count-- )
    {
        *Result++ = Logis( Logis( Logis( *Items++ )));
    }
#else // To silence compiler warnings:
Items = 0;
Result = 0;
Count = 0;
#endif
}

/*------------------------------------------------------------
| LogItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the log of each item.
|
| DESCRIPTION:  
|
| EXAMPLE:  LogItems( Items, Result, Count );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 07.31.96 from 'AddToItems'. 
------------------------------------------------------------*/
void
LogItems( f64* Items, f64* Result, s32 Count )
{
    while( Count-- )
    {
        *Result++ = log( *Items++ );
    }
}

/*------------------------------------------------------------
| MakeItems
|-------------------------------------------------------------
|
| PURPOSE: To make a new number buffer.
|
| DESCRIPTION: Allocates a new number buffer with room for
| 'ItemCount' 'f64' numbers.  
|
| If 'X'  parameters is non-zero, then the items 
| referenced are copied to the new buffer.
|
| EXAMPLE: v = MakeItems( n, 0 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.28.96 from 'MakeVector'
------------------------------------------------------------*/
f64*
MakeItems( u32 ItemCount, f64* X )
{
    f64*    Items;
    u32     ByteCount;
    
    // Calculate the size of the overall record.
    ByteCount = ItemCount * sizeof( f64 );
                 
    // Allocate the new vector record.
    Items = (f64*) malloc( ByteCount );
        
    // If there are values to store, store them.
    if( X != 0 )
    {
        memcpy( (void*) Items, (void*) X, ByteCount );
    }
    
    // Return the buffer.
    return( Items );
}

/*------------------------------------------------------------
| MaxItem
|-------------------------------------------------------------
|
| PURPOSE: To find the largest value in a buffer.
|
| DESCRIPTION: Returns the max. 
|
| EXAMPLE: s = MaxItem( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.25.96 from 'ExtentOfItems'
------------------------------------------------------------*/
f64
MaxItem( f64* Items, s32 Count )
{
    f64 Hi,v;
    
    Hi = *Items++;
    Count--;
    
    while( Count-- )
    {
        v = *Items++;
        
        if( v > Hi )
        {
            Hi = v;
        }
    }
    
    return( Hi );
}

/*------------------------------------------------------------
| MaxItemIndex
|-------------------------------------------------------------
|
| PURPOSE: To find the index of the largest value in a buffer.
|
| DESCRIPTION: Returns the index of the max. 
|
| EXAMPLE: s = MaxItemIndex( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.26.96 from 'MaxItem'
------------------------------------------------------------*/
s32
MaxItemIndex( f64* Items, s32 Count )
{
    f64 Hi,v;
    s32  HiIndex,i;
    
    Hi = *Items++;
    HiIndex = 0;
    
    for( i = 1; i < Count; i++ )
    {
        v = *Items++;
        
        if( v > Hi )
        {
            Hi = v;
            HiIndex = i;
        }
    }
    
    return( HiIndex );
}


/*------------------------------------------------------------
| MinItem
|-------------------------------------------------------------
|
| PURPOSE: To find the smallest value in a buffer.
|
| DESCRIPTION: Returns the min. 
|
| EXAMPLE: s = MinItem( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.25.96 from 'ExtentOfItems'
------------------------------------------------------------*/
f64
MinItem( f64* Items, s32 Count )
{
    f64 Lo,v;
    
    Lo = *Items++;
    Count--;
    
    while( Count-- )
    {
        v = *Items++;
        
        if( v < Lo )
        {
            Lo = v;
        }
    }
    
    return( Lo );
}

/*------------------------------------------------------------
| MultiplyToItems
|-------------------------------------------------------------
|
| PURPOSE: To multiply a value to each item in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE:  MultiplyToItems( Items, ItemCount, .001 );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.28.96 from 'MultiplyToExtent'. 
------------------------------------------------------------*/
void
MultiplyToItems( f64* Items, s32 Count, f64 x )
{
    while( Count-- )
    {
        *Items *= x;
        
        Items++;
    }
}

/*------------------------------------------------------------
| NormalizeItems
|-------------------------------------------------------------
|
| PURPOSE: To rescale the values in a buffer by the mean
|          value.
|
| DESCRIPTION:  
|
| EXAMPLE:  NormalizeItems( V, 100 );
|
| NOTE: TBD - This doesn't compensate for variance.
|
| ASSUMES:  
|           
| HISTORY: 04.02.96 
------------------------------------------------------------*/
void
NormalizeItems( f64* Items, u32 Count )
{
    f64 Total,mean;
    f64 *It;
    u32  Remain;
    
    Total = 0;
    Remain = Count;
    It = Items;
    
    while( Remain-- )
    {
        Total += *It++;
    }
    
    mean = Total / Count;
    
    Remain = Count;
    It = Items;
    
    while( Remain-- )
    {
        *It++ /= mean; 
    }
}

/*------------------------------------------------------------
| NormalizeItemsToOne
|-------------------------------------------------------------
|
| PURPOSE: To rescale the values in a buffer so that they all
|          add up to one.
|
| DESCRIPTION:  
|
| EXAMPLE:  NormalizeItemsToSumToOne( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 05.23.96 
------------------------------------------------------------*/
void
NormalizeItemsToOne( f64* Items, s32 Count )
{
    f64 Total;
    f64 *It;
    s32  i;
    
    // Add up the total of all the items.
    Total = 0;
    It = Items;
    i = Count;
    while( i-- )
    {
        Total += *It++;
    }
    
    // Divide the items by the total.
    while( Count-- )
    {
        *Items++ /= Total; 
    }
}

/*------------------------------------------------------------
| NormalizeItemsToZ1
|-------------------------------------------------------------
|
| PURPOSE: To rescale the values in a buffer so that they  
|          span the range from 0 to 1.
|
| DESCRIPTION: Subtracts the minimum from every value and
| divides by the range.
|
| EXAMPLE: NormalizeItemsToZ1( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 08.04.97 from paper on kNN. 
------------------------------------------------------------*/
void
NormalizeItemsToZ1( f64* Items, u32 Count )
{
    f64 Range, Min, Max;
    
    // Calculate the range and find the min and max.
    Range = ExtentOfItems( Items, Count, &Min, &Max );

    // Translate and scale the values.
    while( Count-- )
    {
        *Items = ( *Items - Min ) / Range;
        
        Items++;
    }
}

/*------------------------------------------------------------
| ProductOfItems
|-------------------------------------------------------------
|
| PURPOSE: To multiply the values in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: s = ProductOfItems( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.02.96 
------------------------------------------------------------*/
f64
ProductOfItems( f64* Items, s32 Count )
{
    f64 Total;
    
    Total = 0;
    
    while( Count-- )
    {
        Total *= *Items++;
    }
    
    return( Total );
}

/*------------------------------------------------------------
| ReciprocalOfItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate the reciprocal of each item.
|
| DESCRIPTION:  
|
| EXAMPLE:  ReciprocalOfItems( Items, Result, Count );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 08.22.96 from 'LogItems'. 
------------------------------------------------------------*/
void
ReciprocalOfItems( f64* Items, f64* Result, s32 Count )
{
    while( Count-- )
    {
        *Result++ = 1./(*Items++);
    }
}

/*------------------------------------------------------------
| RoughDerivative
|-------------------------------------------------------------
|
| PURPOSE: To approximate the derivative of a list of values
| using only the immediate prior value.
|
| DESCRIPTION: Returns a list with n-1 values given a list of
| n values.  Uses this formula:
|
| Formula used:
|         
|                      Ÿ(xo) - Ÿ(xo-1) 
|             Ÿ'(xo) = --------------- 
|                            h
|
| Where:  h = the x between y values, assumed to be 1 for
|             this implementation.
|
|         f(x) = the y value at displacement x
|
| Source: "A Guide to Mathematics for the Intelligent
|          Nonmathematician" by Edmond C. Berkeley, page 166.
|
| EXAMPLE:  
|
|    d = RoughDerivative( Dec92Copper, 50 );
|
| NOTE: 
|
| ASSUMES: The vector will be deallocated somewhere else.
|
| HISTORY:  06.11.93
|           06.12.93 added Chop to handle near-zero error.
|           03.28.96 converted from Mathematica.
------------------------------------------------------------*/
f64*
RoughDerivative( f64* Items, u32 Count )
{
    f64* R;
    u32   RCount;
    
    RCount = Count - 1;

    R = MakeItems( RCount, 0 );
    
    DeltaItems( Items, R, Count );
    
    ChopItems( R, RCount );
    
    return( R );
}

/*------------------------------------------------------------
| SaveItems
|-------------------------------------------------------------
|
| PURPOSE: To save a number buffer to an ASCII file.
|
| DESCRIPTION: Saves values one per line.
|
| EXAMPLE: SaveItems( Items, ItemCount, "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.05.96 from 'SaveArray'.
------------------------------------------------------------*/
void
SaveItems( f64* Items, u32 Count, s8* AFileName )
{
    FILE*   AFile;
    s8*     AtNumberString;
    u32     i;
    
    // Open the file.
    AFile = ReOpenFile(AFileName);
    
    // Save the numbers, 1 per line.

    // For each number.
    for( i = 0; i < Count; i++ )
    {
        // Test for not a number.
        if( ISNAN(*Items) || *Items == NoNum )
        {
            AtNumberString = (s8*) "NaN";
        }
        else
        {
            UseFixedPointFormat = 0;
            UseScientificFormat = 0;
            
            AtNumberString = 
                ConvertNumberToString( (Number) *Items );
        }
        
        // Save 1 number per line.  
        fprintf(AFile,"%s\n",AtNumberString);
            
        // To next number in the buffer.
        Items++;
    }                   
        
    CloseFile(AFile);
    
#if macintosh
    /* Set the file to an MPW document for now. */
    SetFileType(AFileName,(s8*) "TEXT");
    SetFileCreator(AFileName,(s8*) "MPS ");
#endif

}

/*------------------------------------------------------------
| SumItems
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumItems( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.02.96 
------------------------------------------------------------*/
f64
SumItems( f64* Items, u32 Count )
{
    f64 Total;
    
    Total = 0;
    
    while( Count-- )
    {
        Total += *Items++;
    }
    
    return( Total );
}

/*------------------------------------------------------------
| SumItemSquareRoots
|-------------------------------------------------------------
|
| PURPOSE: To sum the square roots of values in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumItemSquareRoots( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.08.96 from 'SumItems'.
------------------------------------------------------------*/
f64
SumItemSquareRoots( f64* Items, s32 Count )
{
    f64 Total;
    f64 v;
    
    Total = 0;
    
    while( Count-- )
    {
        v = *Items++;
        Total += sqrt( fabs(v) );
    }
    
    return( Total );
}

/*------------------------------------------------------------
| SumItemSquares
|-------------------------------------------------------------
|
| PURPOSE: To sum the values squared in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumItemSquares( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.15.96 from 'SumItems'.
------------------------------------------------------------*/
f64
SumItemSquares( f64* Items, s32 Count )
{
    f64 Total;
    f64 v;
    
    Total = 0;
    
    while( Count-- )
    {
        v = *Items++;
        Total += v * v;
    }
    
    return( Total );
}

/*------------------------------------------------------------
| SumMagnitudeOfItems
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumMagnitudeOfItems( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.08.96 
|          09.14.96 replaced 'fabs' with 'if' statement for
|                   speed.
------------------------------------------------------------*/
f64
SumMagnitudeOfItems( f64* Items, s32 Count )
{
    f64 Total;
    
    Total = 0;
    
    while( Count-- )
    {
        if( *Items < 0 )
        {
            Total += -( *Items++ );
        }
        else
        {
            Total += *Items++;
        }           
    }
    
    return( Total );
}

/*------------------------------------------------------------
| SortItems
|-------------------------------------------------------------
|
| PURPOSE: To sort items in ascending order.
|
| DESCRIPTION: See 'PermutationNumberOfBytes'.
|
| EXAMPLE:  
|
| NOTE: I came up with this algorithm and then found that it
|       is similar to 'Shellsort'.
|
| ASSUMES:  
|
| HISTORY: 07.22.96 from 'PermutationNumberOfItems'. Tested
|                   against 'SortVector' and found to be
|                   more than 20 times slower when sorting
|                   1000 random items.
-----------------------------------------------------------*/
void
SortItems( f64* Items, s32 Count )
{
    f64 v;
    s32  i, j, IntervalCount;
    
    // For each interval amount from major to minor order.
    for( i = Count-1; i > 0; i-- )
    {
        // Calculate the number of intervals of size 'i'.
        IntervalCount = Count - i;
        
        // For each interval from beginning to end.
        for( j = 0; j < IntervalCount; j++ )
        {
            if( Items[j] > Items[j+i] )
            {
                v = Items[j];
                Items[j] = Items[j+i];
                Items[j+i] = v;
            }
        }
    }
}

// The following routine was used to test the above.
#ifdef TEST_SORTITEMS
{
    f64 Items[1000],Items2[1000];
    f64 RndItems[1000];
    s32     StartTime, EndTime, SITicks, SVTicks;
    s32     i, reps;
    
    // Generate 100 random items as a standard.
    for( i = 0; i < 1000; i++ )
    {
        RndItems[i] = RandomFraction();
    }
    
    // Time 1000 reps of sorting 100 items in random order.
    StartTime = Now();
    for( i = 0; i < 1000; i++ )
    {
        // Copy the standard list to the working buffer.
        CopyItems( RndItems, Items, 1000 );
        
        SortItems( Items, 1000 );
    }
    EndTime = Now();
    
    SITicks = EndTime - StartTime;
    
    // Time 1000 reps of sorting 100 items in random order.
    StartTime = Now();
    for( i = 0; i < 1000; i++ )
    {
        // Copy the standard list to the working buffer.
        CopyItems( RndItems, Items2, 1000 );
        
        SortVector( Items2, 1000 );
    }
    EndTime = Now();
    
    SVTicks = EndTime - StartTime;
    
    printf("SI:%d, SV:%d\n", SITicks, SVTicks);
    
    // Compare the results to make sure that they are both
    // in the same order.
    for( i = 0; i < 1000; i++ )
    {
        if( Items[i] != Items2[i] )
        {
            printf("Mismatch: [%d] %f %f\n", i, Items[i], Items2[i] );
            //break;
        }
    }
    exit(0);
}
#endif // TEST_SORTITEMS

/*------------------------------------------------------------
| WeighGroupsOfItems
|-------------------------------------------------------------
| 
| PURPOSE: To measure the degree to which items in group B 
|          are in general above items in group A.
| 
| DESCRIPTION: The result is a number between 0 and 1 with
| 1 being that all items in group B are above all items in
| group A; a value of .5 means that group A and group B are 
| roughly or exactly balanced with respect to each other.
|
| Every item in group A is paired with every item in group
| B for comparison.
|
| EXAMPLE:   
|
|          w = WeighItems( A, B, ACount, BCount );
|
| NOTE: 
| 
| ASSUMES: The number of items in each group may be different.
| 
| HISTORY: 07.16.96 from 'ClassifyConsequents'.
|          07.20.96 changed to be ratio of up and down from
|                   'ClassifyConsequents3'.
------------------------------------------------------------*/
f64
WeighGroupsOfItems( f64* A, f64* B, s32 ACount, s32 BCount )
{
    f64 AVal, BVal, Upness;
    s32     i, j, UpCount, DnCount, Total;
    
    UpCount = 0;
    DnCount = 0;

    // For each item in group A.
    for( i = 0; i < ACount; i++ )
    {
        AVal = A[i];
        
        // For each item in group B.
        for( j = 0; j < BCount; j++ )
        {
            BVal = B[j];
            
            UpCount += AVal < BVal;
            DnCount += AVal > BVal;
        }
    }
    
    // If none are up or down, return .5.
    // Equality is treated as an exact balance of up and down.
    if( UpCount == DnCount )
    {
        return( .5 );
    }
    
    Total = UpCount + DnCount;
    
    // Upness is relative to the total number of differences.
    Upness = ((f64) UpCount) / ((f64) Total);
    
    return( Upness );
}       

/*------------------------------------------------------------
| WeighItems
|-------------------------------------------------------------
| 
| PURPOSE: To measure the degree to which items in a group
|          are above other items in the group.
| 
| DESCRIPTION: This measures the degree of up trend in the
| group of items, where the order of the items is taken as
| significant.
|
| Every item is paired with every subsequent item in the 
| group for comparison.
|
| EXAMPLE:   
|
|          w = WeighItems( A, ACount );
|
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 07.16.96 from 'WeighGroupsOfItems'.
|          07.20.96 changed to be ratio of up and down from
|                   'ClassifyConsequents3'.
------------------------------------------------------------*/
f64
WeighItems( f64* A, u32 ACount )
{
    f64 AVal, BVal, Upness;
    u32     i, j, UpCount, DnCount, Total;
    
    UpCount = 0;
    DnCount = 0;

    // For each item in group.
    for( i = 0; i < ACount-1; i++ )
    {
        AVal = A[i];
        
        // For each subsequent item in group.
        for( j = i+1; j < ACount; j++ )
        {
            BVal = A[j];
            
            UpCount += AVal < BVal;
            DnCount += AVal > BVal;
        }
    }
    
    // If none are up or down, return .5.
    // Equality is treated as an exact balance of up and down.
    if( UpCount == DnCount )
    {
        return( .5 );
    }
    
    // Upness is relative to the total number of pairs.
    Total = UpCount + DnCount;
    
    Upness = ((f64) UpCount) / ((f64) Total);
    
    return( Upness );
}       

/*------------------------------------------------------------
| ZeroItems
|-------------------------------------------------------------
|
| PURPOSE: To fill a number buffer with zeros.
|
| DESCRIPTION:  
|
| EXAMPLE: ZeroItems( B, ItemCount );
|
| NOTE: 
|
| ASSUMES: Floating point zero consists of all 0 bits.
|           
| HISTORY: 03.28.96 from 'ZeroMatrix'
------------------------------------------------------------*/
void
ZeroItems( f64* Items, u32 Count )
{
    u32   ByteCount;
    
    ByteCount = Count * sizeof(f64);
    
    memset( (void*) Items, 0, ByteCount );
}
