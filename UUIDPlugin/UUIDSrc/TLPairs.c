/*------------------------------------------------------------
| TLPairs.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide pair-addressed memory access procedures.
|
| HISTORY: 01.22.97 from 'Bytes.c'.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include "NumTypes.h"
#include "TLPairs.h"

/*------------------------------------------------------------
| ABAddPairs
|-------------------------------------------------------------
|
| PURPOSE: To add two ranges of pairs to store at a third.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
|
| NOTE: 
|
| ASSUMES: One of the sources may also be the destination. 
|
| HISTORY:  01.24.97
------------------------------------------------------------*/
void
ABAddPairs( u16* SrcA, u16* SrcB, u16* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = (u16) ( (*SrcA++) + (*SrcB++) );
    }
}

/*------------------------------------------------------------
| ABAndPairs
|-------------------------------------------------------------
|
| PURPOSE: To AND two ranges of pairs to store at a third.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
|
| NOTE: 
|
| ASSUMES: One of the sources may also be the destination. 
|
| HISTORY:  01.24.97
------------------------------------------------------------*/
void
ABAndPairs( u16* SrcA, u16* SrcB, u16* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = (u16) ( *SrcA++ & *SrcB++ );
    }
}

/*------------------------------------------------------------
| ABBlendPairs
|-------------------------------------------------------------
|
| PURPOSE: To blend a two ranges of pairs using mass weights.
|
| DESCRIPTION:  
|
|  Blend(SrcA,MassA,SrcB,MassB,MaxMass) = 
|   if( (MassA+MassB)<=MaxMass, 
|       (SrcA*MassA)/(MassA+MassB) + 
|       (SrcB*MassB)/(MassA+MassB), 
|       Blend( SrcA,
|              (MassA/(MassA+MassB)) * MaxMass, 
|              SrcB, 
|              (MassB/(MassA+MassB)) * MaxMass, 
|              MaxMass) ) --> Dst
|
| BlendMass( MassA, MassB, MassMax ) = 
|    if( (MassA+MassB) <= MassMax, (MassA+MassB), MassMax ) 
|       --> MassDst
|
| EXAMPLE:  ABBlendPairs( SrcA, SrcAMass, 
|                         SrcB, SrcBMass, 
|                         Dst, DstMass, 
|                         MaxMass, (u32) 5 );
|
| ASSUMES: Overlap case is undefined.
|
| HISTORY: 01.27.97 from 'ABBlendQuads'.
------------------------------------------------------------*/
void
ABBlendPairs( u16* SrcA, u16* SrcAMass,
              u16* SrcB, u16* SrcBMass, 
              u16* Dst,  u16* DstMass, 
              u32 MaxMass, u32 Count )
{
    u32 A, a, B, b, ab;
    u16 D;
    
    while( Count-- )
    {
        A = (u32) *SrcA++;
        a = (u32) *SrcAMass++;
        B = (u32) *SrcB++;
        b = (u32) *SrcBMass++;
        
        // Sum the mass.
        ab = a+b;
        
        // If there is any mass.
        if( ab )
        {
            // If the mass exceeds the limit.
            if( ab > MaxMass )
            {
                // Rescale the masses.
                a = (a/ab) * MaxMass;
                b = (b/ab) * MaxMass;
                ab = MaxMass;
            }
            
            // Blend the parts.
            D = (u8) ( ( (A*a) + (B*b) ) / ab );
        }
        else
        {
            D = 0;
        }
        
        // Save the result.
        *Dst++ = D;
        *DstMass++ = (u16) ab;
    }
}

/*------------------------------------------------------------
| ABMultPairs
|-------------------------------------------------------------
|
| PURPOSE: To multiply two ranges of pairs to store at a third.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
|
| NOTE: 
|
| ASSUMES: One of the sources may also be the destination. 
|
| HISTORY:  01.24.97
------------------------------------------------------------*/
void
ABMultPairs( u16* SrcA, u16* SrcB, u16* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = (u16) ( (*SrcA++) * (*SrcB++) );
    }
}

/*------------------------------------------------------------
| ABOrPairs
|-------------------------------------------------------------
|
| PURPOSE: To OR two ranges of pairs to store at a third.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
|
| NOTE: 
|
| ASSUMES: One of the sources may also be the destination. 
|
| HISTORY:  01.24.97
------------------------------------------------------------*/
void
ABOrPairs( u16* SrcA, u16* SrcB, u16* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = (u16) ( *SrcA++ | *SrcB++ );
    }
}

/*------------------------------------------------------------
| ABUnblendPairs
|-------------------------------------------------------------
|
| PURPOSE: To unblend a two ranges of pairs using mass 
|          weights.
|
| DESCRIPTION:  
|
|  Unblend(SrcA,MassA,SrcB,MassB,MaxMass) = 
|   if( (-MassA+MassB) > 0, 
|       (SrcA*-MassA)/(-MassA+MassB) + 
|       (SrcB*MassB)/(-MassA+MassB), 
|       0 ) --> Dst
|
| UnblendMass( MassA, MassB, MassMax ) = 
|    if( (MassA+MassB) <= MassMax, (MassA+MassB), MassMax ) 
|       --> MassDst
|
| EXAMPLE:  ABUnblendPairs( SrcA, SrcAMass, 
|                           SrcB, SrcBMass, 
|                           Dst, DstMass, 
|                           (u32) 5 );
|
| NOTE: Blend/Unblend are reversible as long as the maximum
|       mass limit isn't exceeded.
|
| ASSUMES: Overlap case is undefined.
|
| HISTORY: 01.27.97 from 'ABUnblendBytes'.
------------------------------------------------------------*/
void
ABUnblendPairs( u16* SrcA, u16* SrcAMass,
                u16* SrcB, u16* SrcBMass, 
                u16* Dst,  u16* DstMass, 
                u32 Count )
{
    s32 A, a, B, b, ab, x;
    u16 D;
    
    while( Count-- )
    {
        A = (s32) *SrcA++;
        a = (s32) *SrcAMass++;
        B = (s32) *SrcB++;
        b = (s32) *SrcBMass++;
        
        // Deduct the 'a' mass.
        ab = b-a;
        
        // If there is any mass.
        if( ab > 0 )
        {
            // Unblend the 'A' part.
            x = ( ( (B*b) - (A*a) ) / ab );
            
            if( x > 0 )
            {
                D = (u8) x;
            }
            else
            {
                D = 0;
            }
        }
        else
        {
            ab = 0;
            D = 0;
        }
        
        // Save the result.
        *Dst++ = D;
        *DstMass++ = (u16) ab;
    }
}

/*------------------------------------------------------------
| ABXorPairs
|-------------------------------------------------------------
|
| PURPOSE: To XOR two ranges of pairs to store at a third.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
|
| NOTE: 
|
| ASSUMES: One of the sources may also be the destination. 
|
| HISTORY:  01.24.97
------------------------------------------------------------*/
void
ABXorPairs( u16* SrcA, u16* SrcB, u16* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = (u16) ( *SrcA++ ^ *SrcB++ );
    }
}

/*------------------------------------------------------------
| AndPairs
|-------------------------------------------------------------
|
| PURPOSE: To and a range of pairs to another.
|
| DESCRIPTION: Correctly handles overlapping series of pairs. 
|
| EXAMPLE:  AndPairs( From, To, (u32) 5 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.22.97
------------------------------------------------------------*/
void
AndPairs( u16* From, u16* To, u32 Count )
{
    if( From >= To )
    {
        while( Count-- )
        {
            *To++ &= *From++;
        }
    }
    else
    {
        To   += Count;
        From += Count;
        
        while( Count-- )
        {
            *--To &= *--From;
        }
    }
}

/*------------------------------------------------------------
| Compare_u16
|-------------------------------------------------------------
|
| PURPOSE: To compare two u16's.
|
| DESCRIPTION: A standard comparison function for use with
|              'SortList' and 'Table'.
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.15.98 From 'CompareItems'.
------------------------------------------------------------*/
s32
Compare_u16( s8* A, s8* B )
{
    u16     a,b;
    s32     r;
    
    a = *((u16*) A);
    b = *((u16*) B);
    
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
| CopyObjectPairs
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of pairs defined by an object mask
|          from one place to another.
|
| DESCRIPTION: Correctly handles overlapping series of units. 
|
| Augments the destination mask with the source mask.
|
| EXAMPLE:  CopyObjectPairs( From, FromMask, 
|                          To, ToMask, (u32) 5 );
|
| ASSUMES: 
|
| HISTORY: 01.27.97 from 'CopyObjectBytes'.
------------------------------------------------------------*/
void
CopyObjectPairs( u16* Src, u16* SrcMask, 
                 u16* Dst, u16* DstMask, u32 Count )
{
    u16 A, M, D;
    
    if( Src >= Dst )
    {
        while( Count-- )
        {
            A = *Src++;
            M = *SrcMask++;
            D = *Dst;
            
            *Dst++ = (u16) ( (A & M) | (~M & D) );
            *DstMask++ |= M;
        }
    }
    else // Travel high-to-low.
    {
        Src     += Count;
        SrcMask += Count;
        Dst     += Count;
        DstMask += Count;
        
        while( Count-- )
        {
            A = *--Src;
            M = *--SrcMask;
            D = *--Dst;
            
            *Dst = (u16) ( (A & M) | (~M & D) );
            *--DstMask |= M;
        }
    }
}

/*------------------------------------------------------------
| CopyPairs
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of pairs from one place to another.
|
| DESCRIPTION: Correctly handles overlapping series of pairs. 
|
| EXAMPLE:  CopyPairs( From, To, (u32) 5 );
|
| NOTE: You must cast literal count parameters to be a 'u32' 
|       to avoid errors. 
|
|       This could be sped up by moving 32-bit chunks where
|       possible.
|
| ASSUMES: 
|
| HISTORY: 01.22.97 from 'CopyBytes'.
------------------------------------------------------------*/
void
CopyPairs( u16* From, 
           u16* To, 
           u32 Count )
{
    if( From >= To )
    {
        while( Count-- )
        {
            *To++ = *From++;
        }
    }
    else
    {
        To   += Count;
        From += Count;
        
        while( Count-- )
        {
            *--To = *--From;
        }
    }
}

/*------------------------------------------------------------
| CopyInversePairs
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of pairs from one place 
|          to another, inverting them in the process.
|
| DESCRIPTION: Correctly handles overlapping series of pairs. 
|
| EXAMPLE:  CopyInversePairs( From, To, (u32) 5 );
|
| NOTE: You must cast literal count parameters to be a 'u32' 
|       to avoid errors. 
|
| ASSUMES: 
|
| HISTORY: 01.24.97 from 'CopyPairs'.
------------------------------------------------------------*/
void
CopyInversePairs( u16* From, u16* To, u32 Count )
{
    if( From >= To )
    {
        while( Count-- )
        {
            *To++ = (u16) ( ~(*From++) );
        }
    }
    else
    {
        To   += Count;
        From += Count;
        
        while( Count-- )
        {
            *--To = (u16) ( ~(*--From) );
        }
    }
}

/*------------------------------------------------------------
| FillPairs
|-------------------------------------------------------------
|
| PURPOSE: To fill a range of pairs with a value.
|
| DESCRIPTION:  
|
| EXAMPLE:  FillPairs( Destination, PairCount, PairValue );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.22.97 from 'FillBytes'.
------------------------------------------------------------*/
void
FillPairs( u16* Destination, u32 PairCount, u32 PairValue )
{
    while( PairCount-- )
    {
        *Destination++ = (u16) PairValue;
    }
}

/*------------------------------------------------------------
| GetPair
|-------------------------------------------------------------
|
| PURPOSE: To fetch a pair.
|
| DESCRIPTION:  
|
| EXAMPLE:  b = GetPair( a );
|
| ASSUMES: 
|
| HISTORY: 01.22.97 
------------------------------------------------------------*/
u32
GetPair( u16* a )
{
    return( *a );
}

/*------------------------------------------------------------
| OrPairs
|-------------------------------------------------------------
|
| PURPOSE: To OR a range of pairs to another.
|
| DESCRIPTION: Correctly handles overlapping series of pairs. 
|
| EXAMPLE:  OrPairs( From, To, (u32) 5 );
|
| NOTE: This could be sped up by moving 32-bit chunks where
|       possible.
|
| ASSUMES: 
|
| HISTORY: 01.22.97
------------------------------------------------------------*/
void
OrPairs( u16* From, u16* To, u32 Count )
{
    if( From >= To )
    {
        while( Count-- )
        {
            *To++ |= *From++;
        }
    }
    else
    {
        To   += Count;
        From += Count;
        
        while( Count-- )
        {
            *--To |= *--From;
        }
    }
}

/*------------------------------------------------------------
| PutPair
|-------------------------------------------------------------
|
| PURPOSE: To store a pair.
|
| DESCRIPTION:  
|
| EXAMPLE:    PutPair( a, p );
|
| ASSUMES: 
|
| HISTORY: 01.22.97 
------------------------------------------------------------*/
void
PutPair( u16* a, u32 p )
{
    *a = (u16) p;
}

/*------------------------------------------------------------
| XorPairs
|-------------------------------------------------------------
|
| PURPOSE: To XOR a range of pairs to another.
|
| DESCRIPTION: Correctly handles overlapping series of pairs. 
|
| EXAMPLE:  XorPairs( From, To, (u32) 5 );
|
| NOTE: This could be sped up by moving 32-bit chunks where
|       possible.
|
| ASSUMES: 
|
| HISTORY: 01.22.97
------------------------------------------------------------*/
void
XorPairs( u16* From, u16* To, u32 Count )
{
    if( From >= To )
    {
        while( Count-- )
        {
            *To++ ^= *From++;
        }
    }
    else
    {
        To   += Count;
        From += Count;
        
        while( Count-- )
        {
            *--To ^= *--From;
        }
    }
}
