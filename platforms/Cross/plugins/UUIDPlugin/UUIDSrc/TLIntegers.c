/*------------------------------------------------------------
| TLIntegers.c
|-------------------------------------------------------------
|
| PURPOSE: To provide integer buffer functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 04.23.96 
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLByteBuffer.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLRandom.h"
#include "TLIntegers.h"

/*------------------------------------------------------------
| AddToIntegers
|-------------------------------------------------------------
|
| PURPOSE: To add a number to each item in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE:  AddToIntegers( Integers, Count, .001 );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.23.96 from 'AddToItems'. 
------------------------------------------------------------*/
void
AddToIntegers( s32* Integers, s32 Count, s32 n )
{
    while( Count-- )
    {
        *Integers += n;
        
        Integers++;
    }
}

/*------------------------------------------------------------
| AppendIntegerToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To append an integer to a buffer.
|
| DESCRIPTION: Also increments the buffer item count.
|
| EXAMPLE:    
|           AppendIntegerToBuffer( B, &BCount, 123 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.96 
------------------------------------------------------------*/
void
AppendIntegerToBuffer( s32* Buffer, s32* Count, s32 n )
{
    Buffer[*Count] = n;
    
    *Count++;
}

/*------------------------------------------------------------
| DeleteInteger
|-------------------------------------------------------------
|
| PURPOSE: To delete the first occurance of an integer from
|          a buffer.
|
| DESCRIPTION: Shift following integers forward to take up
| position occupied by the integer if found.  Also decrements
| the buffer item count.
|
| EXAMPLE:    
|           DeleteInteger( B, &BCount, 123 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.96 
------------------------------------------------------------*/
void
DeleteInteger( s32* Buffer, s32* Count, s32 n )
{
    s32  ItemsLeft;
    s32* Next;
    
    // Get the item count.
    ItemsLeft = *Count;
    
    // If the buffer is empty, just return.
    if( ItemsLeft == 0 )
    {
        return;
    }
    
    // Find the integer if it exists.
    while( *Buffer != n && ItemsLeft )
    {
        Buffer++;
        ItemsLeft--;
    }
    
    // If the integer wasn't found, just return.
    if( ItemsLeft == 0 )
    {
        return;
    }
    
    // Integer was found.
    
    // Deduct the item from the total.
    ItemsLeft--;
    *Count -= 1;
    
    // If there are following items to move.
    if( ItemsLeft )
    {
        // Refer to the next item.
        Next = Buffer + 1;
        
        // While there are items to copy.
        while( ItemsLeft-- )
        {
            *Buffer++ = *Next++;
        }
    }
    
    // Fill the vacant cell with zero.
    *Buffer = 0;
}

/*------------------------------------------------------------
| DeleteMatchingIntegers
|-------------------------------------------------------------
|
| PURPOSE: To delete the all occurances of an integer from
|          a buffer.
|
| DESCRIPTION: Shifts following integers forward to take up
| position occupied by the integer if found.  Also decrements
| the buffer item count.
|
| EXAMPLE:    
|           DeleteMatchingIntegers( B, &BCount, 123 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.96 
------------------------------------------------------------*/
void
DeleteMatchingIntegers( s32* Buffer, s32* Count, s32 n )
{
    s32  ItemsLeft;
    s32  Items;
    s32* Next;
    s32* Here;
    
    // Get the item count.
    ItemsLeft = *Count;
    
    // If the buffer is empty, just return.
    if( ItemsLeft == 0 )
    {
        return;
    }
    
    // While there are items left to check.
    while( ItemsLeft )
    {
        // Find the integer if it exists.
        while( *Buffer != n && ItemsLeft )
        {
            Buffer++;
            ItemsLeft--;
        }
    
        // If the integer wasn't found, just return.
        if( ItemsLeft == 0 )
        {
            return;
        }
    
        // Integer was found.
        Here = Buffer;
        
        // Deduct the item from the total.
        ItemsLeft--;
        *Count -= 1;
    
        // If there are following items to move.
        if( ItemsLeft )
        {
            // Refer to the next item.
            Next = Here + 1;
        
            // While there are items to copy.
            Items = ItemsLeft;
            
            while( Items-- )
            {
                *Here++ = *Next++;
            }
        }
            
        // Fill the vacant cell with zero.
        *Here = 0;
    }
}

/*------------------------------------------------------------
| DeltaIntegers
|-------------------------------------------------------------
|
| PURPOSE: To subtract each item from each following item
|          to produce a list of differences.
|
| DESCRIPTION: Returns the differences, which have a count of
|              one less than the input item count. 
|
| EXAMPLE:    DeltaIntegers( V, D, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.23.96 from 'DeltaItems'.
------------------------------------------------------------*/
void
DeltaIntegers( s32* Integers, s32* AtResult, s32 Count )
{
    s32 AnItem;
    s32 NextItem;
    
    AnItem = *Integers++;
    
    Count--;
    
    while( Count-- )
    {
        NextItem = *Integers++;
        
        *AtResult++ = NextItem - AnItem;
        
        AnItem = NextItem;
    }
}

/*------------------------------------------------------------
| DuplicateIntegers
|-------------------------------------------------------------
|
| PURPOSE: To make a dynamic copy of an integer buffer.
|
| DESCRIPTION: 
|
| EXAMPLE: d = DuplicateIntegers( Integers, n );
|
| NOTE: 
|
| ASSUMES: Will be freed using 'free'.
|           
| HISTORY: 04.23.96 from 'DuplicateItems'.
------------------------------------------------------------*/
s32*
DuplicateIntegers( s32* Integers, u32 Count )
{
    s32*    B;
    u32     ByteCount;
    
    // Calculate the size of the overall buffer.
    ByteCount = Count * sizeof(s32);
    
    // Allocate the new buffer.
    B = (s32*) malloc( ByteCount );
    
    // Copy the data.
    memcpy( (void*) B, (void*) Integers, ByteCount );
    
    // Return the buffer.
    return( B );
}

/*------------------------------------------------------------
| ExtentOfIntegers
|-------------------------------------------------------------
|
| PURPOSE: To find the smallest and largest values in a buffer.
|
| DESCRIPTION: Returns the min, max and range, the range being
| the return value. 
|
| EXAMPLE: s = ExtentOfIntegers( V, 100, &Min, &Max );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.23.96 from 'ExtentOfItems'.
------------------------------------------------------------*/
s32
ExtentOfIntegers( s32* Integers, s32 Count, 
                  s32* AtMin, s32* AtMax )
{
    s32  i;
    s32  Lo, Hi,v;
    
    Lo = Hi = *Integers++;
  
    for( i = 1; i < Count; i++ )
    {
        v = *Integers++;
        
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
| InsertValueInIntegerTable
|-------------------------------------------------------------
|
| PURPOSE: To shift the entries in a table of integers to make
|          room for a new value.
|
| DESCRIPTION: Given the entry index of where a new value will 
| be inserted, and the index of where an expendable value will
| be deleted, shift the integers to open up the insertion 
| space, and then store the value there.
|
| EXAMPLE:   
|
|    InsertValueInIntegerTable( ATable, 
|                               InsertIndex, 
|                               DeleteIndex,
|                               123 );
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 10.05.97 TL
------------------------------------------------------------*/
void
InsertValueInIntegerTable( 
    s32* ATable,
    u32  InsertIndex,
    u32  DeleteIndex,
    s32  NewValue )
{
    u8* From;
    u8* To;
    u32  ByteCount;
    
    // If the insertion and deletion points differ.
    if( InsertIndex != DeleteIndex )
    {
        // Then existing entries need to be shifted.
    
        // If the insertion point follows the deletion point.
        if( InsertIndex > DeleteIndex )
        {
            // Shift the values following the deletion point
            // up to and including the insertion point.
            // 
            //        [....DxxxI...]
            //             <--
            //        [....xxxI_...]
            //        
            From = (u8*) &ATable[DeleteIndex+1];
            To   = From - 4;
            ByteCount = (InsertIndex - DeleteIndex) << 2;
        }
        else // Insertion point is before the deletion point.
        {
            // Shift the values following the deletion point
            // up to and including the insertion point.
            // 
            //        [....IxxxD...]
            //              -->
            //        [...._Ixxx...]
            //        
            From = (u8*) &ATable[InsertIndex];
            To   = From + 4;
            ByteCount = (DeleteIndex - InsertIndex) << 2;
        }
        
        // Shift the values to make room.
        CopyBytes( From, To, ByteCount );
    }
    
    // Insert new value.
    ATable[InsertIndex] = NewValue;
}

/*------------------------------------------------------------
| IntegersToItems
|-------------------------------------------------------------
|
| PURPOSE: To convert integer values to floating point.
|
| DESCRIPTION:  
|
| EXAMPLE:  IntegersToItems( from, to, count );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.23.96 
------------------------------------------------------------*/
void
IntegersToItems( s32* From, f64* To, s32 Count )
{
    s32 i;
    
    for( i = 0; i < Count; i++ )
    {
        To[i] = (f64) From[i];
    }
}

/*------------------------------------------------------------
| IsBuffersWithIntegersInCommon
|-------------------------------------------------------------
|
| PURPOSE: To test if any integer in a buffer occurs in
|          another buffer.
|
| DESCRIPTION: 
|
| EXAMPLE:    
|       t = IsBuffersWithIntegersInCommon( A, ACount,
|                                          B, BCount );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.96 
------------------------------------------------------------*/
u32  
IsBuffersWithIntegersInCommon( 
    s32* A, s32 ACount, 
    s32* B, s32 BCount )
{
    s32  i, j;
    
    // For each integer in the first buffer.
    for( i = 0; i < ACount; i++ )
    {
        // For each integer in the other buffer. 
        for( j = 0; j < BCount; j++ )
        {
            if( A[i] == B[j] )
            {
                return( 1 );
            }
        }
    }
    
    // No duplicate found.
    return( 0 );
}

/*------------------------------------------------------------
| IsDuplicateIntegersInBuffer
|-------------------------------------------------------------
|
| PURPOSE: To test if any integer in a buffer occurs more than
|          once.
|
| DESCRIPTION: 
|
| EXAMPLE:    
|           t = IsDuplicateIntegersInBuffer( B, BCount );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.96 
------------------------------------------------------------*/
u32  
IsDuplicateIntegersInBuffer( s32* Buffer, s32 Count )
{
    s32  i, j;
    
    // For each integer but the last one.
    for( i = 0; i < Count-1; i++ )
    {
        // For each other integer.
        for( j = i + 1; j < Count; j++ )
        {
            if( Buffer[i] == Buffer[j] )
            {
                return( 1 );
            }
        }
    }
    
    // No duplicate found.
    return( 0 );
}

/*------------------------------------------------------------
| IsIntegerInBuffer
|-------------------------------------------------------------
|
| PURPOSE: To test if an integer is in a buffer.
|
| DESCRIPTION: 
|
| EXAMPLE:    
|           t = IsIntegerInBuffer( B, BCount, 123 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.96 
------------------------------------------------------------*/
u32  
IsIntegerInBuffer( s32* Buffer, s32 Count, s32 n )
{
    // Find the integer if it exists.
    while( *Buffer != n && Count )
    {
        Buffer++;
        Count--;
    }
    
    // If the integer wasn't found.
    if( Count == 0 )
    {
        return( 0 );
    }
    else
    {
        return( 1 );
    }
}

/*------------------------------------------------------------
| ItemsToIntegers
|-------------------------------------------------------------
|
| PURPOSE: To convert floating point to integer values.
|
| DESCRIPTION:  
|
| EXAMPLE:  ItemsToIntegers( from, to, count );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.23.96 
------------------------------------------------------------*/
void
ItemsToIntegers( f64* From, s32* To, s32 Count )
{
    s32 i;
    
    for( i = 0; i < Count; i++ )
    {
        To[i] = (s32) From[i];
    }
}

/*------------------------------------------------------------
| MakeIntegers
|-------------------------------------------------------------
|
| PURPOSE: To make a new integer buffer.
|
| DESCRIPTION: Allocates a new number buffer with room for
| 'ItemCount' 's32' numbers.  
|
| If 'X'  parameters is non-zero, then the items 
| referenced are copied to the new buffer.
|
| EXAMPLE: v = MakeIntegers( n, 0 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.23.96 from 'MakeItems'.
------------------------------------------------------------*/
s32*
MakeIntegers( u32 ItemCount, s32* X )
{
    s32*    Integers;
    u32     ByteCount;
    
    // Calculate the size of the overall record.
    ByteCount = ItemCount * sizeof( s32 );
                 
    // Allocate the new vector record.
    Integers = (s32*) malloc( ByteCount );
        
    // If there are values to store, store them.
    if( X != 0 )
    {
        memcpy( (void*) Integers, (void*) X, ByteCount );
    }
    
    // Return the buffer.
    return( Integers );
}

/*------------------------------------------------------------
| MultiplyToIntegers
|-------------------------------------------------------------
|
| PURPOSE: To multiply a value to each item in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE:  MultiplyToIntegers( Integers, ItemCount, .001 );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.23.96 from 'MultiplyToItems'.
------------------------------------------------------------*/
void
MultiplyToIntegers( s32* Integers, u32 Count, s32 x )
{
    while( Count-- )
    {
        *Integers *= x;
        
        Integers++;
    }
}

/*------------------------------------------------------------
| RoundInteger
|-------------------------------------------------------------
|
| PURPOSE: To round an integer to the nearest interval of a
|          certain size.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|       
|       n = RoundInteger( 19, 15 );
|
|       n -> 15
|
| NOTE: 
|
| ASSUMES: 'n' and 'Interval' are positive.
|           
| HISTORY: 01.02.97
------------------------------------------------------------*/
s32
RoundInteger( s32 n, s32 Interval )
{
    n += Interval / 2;
    n /= Interval;
    n *= Interval;
    
    return( n );
}

/*------------------------------------------------------------
| SaveIntegers
|-------------------------------------------------------------
|
| PURPOSE: To save an integer buffer to an ASCII file.
|
| DESCRIPTION: Saves values one per line.
|
| EXAMPLE: SaveIntegers( Integers, ItemCount, "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.23.96 from 'SaveItems'.
------------------------------------------------------------*/
void
SaveIntegers( s32* Integers, u32 Count, s8* AFileName )
{
    FILE*   AFile;
    u32     i;
    
    // Open the file.
    AFile = ReOpenFile(AFileName);
    
    // Save the numbers, 1 per line.

    // For each number.
    for( i = 0; i < Count; i++ )
    {
        // Save 1 number per line.  
        fprintf( AFile, "%d\n", Integers[i] );
    }                   
        
    CloseFile( AFile );
    
#if macintosh
    // Set the file as a CodeWarrior document.
    SetFileType( AFileName, (s8*) "TEXT" );
    SetFileCreator( AFileName, (s8*) "CWIE" );
#endif
}

/*------------------------------------------------------------
| SortIntegers
|-------------------------------------------------------------
|
| PURPOSE: To sort signed 32-bit integers in increasing order.
|
| DESCRIPTION: Expects the address of a buffer, a count of 
| entries in the buffer. 
|
| Uses fast Heap Sort procedure.
|
| EXAMPLE:  
|
|       SortIntegers( AVector, ItemCount );
|
| NOTE: Especially well suited to long tables as the run time
| is proportional to Nlog2N as a worst case, eg. a 256 element
| list would take time proportional to 256*8 = 2048 vs.
| N*N or 64K for the bubble sort.
|
| ASSUMES: 
|
| NOTE: See "Numerical Recipes, The Art of Scientific 
|        Computing", page 229, for complete explanation. 
|
| HISTORY: 05.11.97 from 'SortVector.
------------------------------------------------------------*/
void
SortIntegers( s32* Integers, u32 ItemCount )
{
    s32  AData;
    s32  BData;
    s32  EntryBeingMoved;
    u32  HeapIndexL;
    u32  HeapIndexIR;
    u32  HeapIndexI;
    u32  HeapIndexJ;
    
    if( ItemCount < 2 ) return;
    
    HeapIndexL  = (ItemCount >> 1) + 1; 
    HeapIndexIR = ItemCount;
    
    while(1)
    {
        if(HeapIndexL > 1)
        {
            HeapIndexL--;
            EntryBeingMoved = Integers[HeapIndexL-1];
        }
        else
        {
            EntryBeingMoved = Integers[HeapIndexIR-1];
            Integers[HeapIndexIR-1] = Integers[0];
            HeapIndexIR--;
            if( HeapIndexIR == 1 ) /* at the end */
            {               
                Integers[0] = EntryBeingMoved;
                return;
            }
        }
        
        HeapIndexI = HeapIndexL;
        HeapIndexJ = HeapIndexL<<1;
        
        while( HeapIndexJ <= HeapIndexIR )
        {
            if( HeapIndexJ < HeapIndexIR )
            {
                AData = Integers[HeapIndexJ-1];
                BData = Integers[HeapIndexJ];

                if( AData < BData )
                {
                    HeapIndexJ++;
                }
            }
            
            AData = EntryBeingMoved;
            BData = Integers[HeapIndexJ-1];

            if( AData < BData )
            {
              
              Integers[HeapIndexI-1] = Integers[HeapIndexJ-1];
              HeapIndexI = HeapIndexJ;
              HeapIndexJ += HeapIndexJ;
            }
            else
            {
              HeapIndexJ = HeapIndexIR+1;
            }
        }
        
        Integers[HeapIndexI - 1] = EntryBeingMoved;
    }
}

/*------------------------------------------------------------
| SumIntegers
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumIntegers( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.23.96 from 'SumItems'.
------------------------------------------------------------*/
s32
SumIntegers( s32* Integers, u32 Count )
{
    s32 Total;
    
    Total = 0;
    
    while( Count-- )
    {
        Total += *Integers++;
    }
    
    return( Total );
}

/*------------------------------------------------------------
| SumMagnitudeOfIntegers
|-------------------------------------------------------------
|
| PURPOSE: To sum the values in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE: s = SumMagnitudeOfIntegers( V, 100 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.23.96 from 'SumMagnitudeOfItems'.
|          11.24.97 revised to avoid use of 'abs'.
------------------------------------------------------------*/
s32
SumMagnitudeOfIntegers( s32* Integers, u32 Count )
{
    s32 Total;
    s32 x;
    
    Total = 0;
    
    while( Count-- )
    {
        x = *Integers++;
        
        if( x >= 0 )
        {
            Total += x;
        }
        else
        {
            Total += -x;
        }
    }
    
    return( Total );
}

/*------------------------------------------------------------
| ZeroIntegers
|-------------------------------------------------------------
|
| PURPOSE: To fill a number buffer with zeros.
|
| DESCRIPTION:  
|
| EXAMPLE: ZeroIntegers( B, ItemCount );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.23.96 from 'ZeroItems'.
------------------------------------------------------------*/
void
ZeroIntegers( s32* Integers, u32 Count )
{
    u32   ByteCount;
    
    ByteCount = Count * sizeof(s32);
    
    memset( (void*) Integers, 0, ByteCount );
}
