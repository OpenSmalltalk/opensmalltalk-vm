/*------------------------------------------------------------
| TLQuads.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide quad-addressed memory access procedures.
|
| HISTORY: 01.22.97 from 'Pairs.c'.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include "NumTypes.h"
#include "TLQuads.h"

/*------------------------------------------------------------
| ABAddQuads
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
ABAddQuads( u32* SrcA, u32* SrcB, u32* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = (*SrcA++) + (*SrcB++);
    }
}

/*------------------------------------------------------------
| ABAndQuads
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
ABAndQuads( u32* SrcA, u32* SrcB, u32* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = *SrcA++ & *SrcB++;
    }
}

/*------------------------------------------------------------
| ABBlendQuads
|-------------------------------------------------------------
|
| PURPOSE: To blend a two ranges of quads using mass weights.
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
| EXAMPLE:  ABBlendQuads( SrcA, SrcAMass, 
|                         SrcB, SrcBMass, 
|                         Dst, DstMass, 
|                         MaxMass, (u32) 5 );
|
| ASSUMES: Overlap case is undefined.
|
| HISTORY: 01.27.97 from 'ABBlendBytes'.
------------------------------------------------------------*/
void
ABBlendQuads( u32* SrcA, u32* SrcAMass,
              u32* SrcB, u32* SrcBMass, 
              u32* Dst,  u32* DstMass, 
              u32 MaxMass, u32 Count )
{
    u32 A, a, B, b, ab;
    u32 D;
    
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
        *DstMass++ = ab;
    }
}

/*------------------------------------------------------------
| ABMultQuads
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
ABMultQuads( u32* SrcA, u32* SrcB, u32* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = (*SrcA++) * (*SrcB++);
    }
}

/*------------------------------------------------------------
| ABOrQuads
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
ABOrQuads( u32* SrcA, u32* SrcB, u32* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = *SrcA++ | *SrcB++;
    }
}

/*------------------------------------------------------------
| ABUnblendQuads
|-------------------------------------------------------------
|
| PURPOSE: To unblend a two ranges of quads using mass 
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
| EXAMPLE:  ABUnblendQuads( SrcA, SrcAMass, 
|                           SrcB, SrcBMass, 
|                           Dst, DstMass, 
|                           (u32) 5 );
|
| NOTE: Blend/Unblend are reversible as long as the maximum
|       mass limit isn't exceeded.
|
| ASSUMES: Overlap case is undefined.
|
| HISTORY: 01.27.97 from 'ABUnblendPairs'.
------------------------------------------------------------*/
void
ABUnblendQuads( u32* SrcA, u32* SrcAMass,
                u32* SrcB, u32* SrcBMass, 
                u32* Dst,  u32* DstMass, 
                u32 Count )
{
    s32 A, a, B, b, ab, x;
    u32 D;
    
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
        *DstMass++ = (u32) ab;
    }
}

/*------------------------------------------------------------
| ABXorQuads
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
ABXorQuads( u32* SrcA, u32* SrcB, u32* Dst, u32 Count )
{
    while( Count-- )
    {
        *Dst++ = *SrcA++ ^ *SrcB++;
    }
}

/*------------------------------------------------------------
| AndQuads
|-------------------------------------------------------------
|
| PURPOSE: To and a range of quads to another.
|
| DESCRIPTION: Correctly handles overlapping series of quads. 
|
| EXAMPLE:  AndQuads( From, To, (u32) 5 );
|
| NOTE: This could be sped up by moving 32-bit chunks where
|       possible.
|
| ASSUMES: 
|
| HISTORY: 01.22.97
------------------------------------------------------------*/
void
AndQuads( u32* From, u32* To, u32 Count )
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
| Compare_u32
|-------------------------------------------------------------
|
| PURPOSE: To compare two u32's.
|
| DESCRIPTION: A standard comparison function for use with
|              'SortList' and 'MakeTable'.
|
| EXAMPLE:   
|
| ASSUMES: 
|
| HISTORY: 11.05.98 TL From 'CompareItems()'.
------------------------------------------------------------*/
s32
Compare_u32( u8* A, u8* B )
{
    u32 a, b;
    s32 r;
    
    // Refer to A and B as 'u32' data units.
    a = *((u32*) A);
    b = *((u32*) B);
    
    // If A is greater than B.
    if( a > b )
    {
        // Return a positive number.
        r = 1;
    }
    else
    {
        // If A is less than B.
        if( a < b )
        {
            // Return a negative number.
            r = -1;
        }
        else // A and B are equal.
        {
            // Return zero.
            r = 0;
        }
    }

    return( r );
}

/*------------------------------------------------------------
| Compare_u64
|-------------------------------------------------------------
|
| PURPOSE: To compare two u64's.
|
| DESCRIPTION: A standard comparison function for use with
|              'SortList' and 'MakeTable'.
|
| EXAMPLE:   
|
| ASSUMES: 
|
| HISTORY: 06.27.00 TL From 'Compare_u32()'.
------------------------------------------------------------*/
s32
Compare_u64( u8* A, u8* B )
{
    u64 a, b;
    s32 r;
    
    // Refer to A and B as 'u64' data units.
    a = *((u64*) A);
    b = *((u64*) B);
    
    // If A is greater than B.
    if( a > b )
    {
        // Return a positive number.
        r = 1;
    }
    else
    {
        // If A is less than B.
        if( a < b )
        {
            // Return a negative number.
            r = -1;
        }
        else // A and B are equal.
        {
            // Return zero.
            r = 0;
        }
    }

    return( r );
}

/*------------------------------------------------------------
| CopyObjectQuads
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of quads defined by an object mask
|          from one place to another.
|
| DESCRIPTION: Correctly handles overlapping series of units. 
|
| Augments the destination mask with the source mask.
|
| EXAMPLE:  CopyObjectQuads( From, FromMask, 
|                            To, ToMask, (u32) 5 );
|
| ASSUMES: 
|
| HISTORY: 01.27.97 from 'CopyObjectPairs'.
------------------------------------------------------------*/
void
CopyObjectQuads( u32* Src, u32* SrcMask, 
                u32* Dst, u32* DstMask, u32 Count )
{
    u32 A, M, D;
    
    if( Src >= Dst )
    {
        while( Count-- )
        {
            A = *Src++;
            M = *SrcMask++;
            D = *Dst;
            
            *Dst++ = (A & M) | (~M & D);
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
            
            *Dst = (A & M) | (~M & D);
            *--DstMask |= M;
        }
    }
}

/*------------------------------------------------------------
| CopyQuads
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of quads from one place to another.
|
| DESCRIPTION: Correctly handles overlapping series of quads. 
|
| EXAMPLE:  CopyQuads( From, To, (u32) 5 );
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
CopyQuads( u32* From, 
           u32* To, 
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
| CopyInverseQuads
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of quads from one place 
|          to another, inverting them in the process.
|
| DESCRIPTION: Correctly handles overlapping series of pairs. 
|
| EXAMPLE:  CopyInverseQuads( From, To, (u32) 5 );
|
| NOTE: You must cast literal count parameters to be a 'u32' 
|       to avoid errors. 
|
| ASSUMES: 
|
| HISTORY: 01.24.97 from 'CopyPairs'.
------------------------------------------------------------*/
void
CopyInverseQuads( u32* From, u32* To, u32 Count )
{
    if( From >= To )
    {
        while( Count-- )
        {
            *To++ = ~(*From++);
        }
    }
    else
    {
        To   += Count;
        From += Count;
        
        while( Count-- )
        {
            *--To = ~(*--From);
        }
    }
}

/*------------------------------------------------------------
| FillQuads
|-------------------------------------------------------------
|
| PURPOSE: To fill a range of quads with a value.
|
| DESCRIPTION:  
|
| EXAMPLE:  FillQuads( Destination, QuadCount, QuadValue );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.22.97 from 'FillBytes'.
------------------------------------------------------------*/
void
FillQuads( u32* Destination, u32 QuadCount, u32 QuadValue )
{
    while( QuadCount-- )
    {
        *Destination++ = QuadValue;
    }
}

/*------------------------------------------------------------
| GetQuad
|-------------------------------------------------------------
|
| PURPOSE: To fetch a quad.
|
| DESCRIPTION:  
|
| EXAMPLE:  b = GetQuad( a );
|
| ASSUMES: 
|
| HISTORY: 01.22.97 
------------------------------------------------------------*/
u32
GetQuad( u32* a )
{
    return( *a );
}

/*------------------------------------------------------------
| OrQuads
|-------------------------------------------------------------
|
| PURPOSE: To OR a range of quads to another.
|
| DESCRIPTION: Correctly handles overlapping series of quads. 
|
| EXAMPLE:  OrQuads( From, To, (u32) 5 );
|
| NOTE: This could be sped up by moving 32-bit chunks where
|       possible.
|
| ASSUMES: 
|
| HISTORY: 01.22.97
------------------------------------------------------------*/
void
OrQuads( u32* From, u32* To, u32 Count )
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
| PutQuad
|-------------------------------------------------------------
|
| PURPOSE: To store a quad.
|
| DESCRIPTION:  
|
| EXAMPLE:    PutQuad( a, q );
|
| ASSUMES: 
|
| HISTORY: 01.22.97 
------------------------------------------------------------*/
void
PutQuad( u32* a, u32 q )
{
    *a = q;
}

/*------------------------------------------------------------
| XorQuads
|-------------------------------------------------------------
|
| PURPOSE: To XOR a range of quads to another.
|
| DESCRIPTION: Correctly handles overlapping series of quads. 
|
| EXAMPLE:  XorQuads( From, To, (u32) 5 );
|
| NOTE: This could be sped up by moving 32-bit chunks where
|       possible.
|
| ASSUMES: 
|
| HISTORY: 01.22.97
------------------------------------------------------------*/
void
XorQuads( u32* From, u32* To, u32 Count )
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
