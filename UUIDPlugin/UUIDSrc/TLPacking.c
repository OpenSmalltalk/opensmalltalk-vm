/*------------------------------------------------------------
| TLPacking.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide bit packing functions.
|
| DESCRIPTION: Computers vary in how they store binary numbers
| into storage bits.  The routines in this file provide a
| system for translating data written on one computer type
| to another computer that uses a different way of storing
| numbers.  
|
| Since all computer data is ultimately represented as binary 
| numbers, the functions in this file provide a universal 
| translation system for all computer data.
|
| ------------------------------------------------------------
|
|                    THE BITPACK STANDARD
|
| The following conventions constitute The BitPack Standard.
|
| This specification describes how binary numbers are packed 
| into storage units with 1, 8, 16, 32 or 64 bit capacity.
|
| Those storage units are named:
|
|             Storage Capacity 
|   Name     in Binary Digits
| ------------------------------ 
|  bit...............1                 
|  byte..............8
|  pair.............16
|  quad.............32
|  oct..............64
| ------------------------------ 
|
| On most machines, a single binary digit can be fetched 
| from storage in more than one way: for example, as part 
| of a byte, a pair, a quad, or as part of an oct.
|
| Since the same information can be accessed in more than
| one way, and since there is more than one way to pack
| storage units one within the other, the way a CPU accesses 
| memory must be known in order to validly interpret binary 
| numbers stored in the memory of that CPU.
|
| PACKING ORDER
| =============
|
| A packing order specifies how binary numbers are organized 
| in storage units.
|
| In this standard the placement of bits in a byte will be 
| expressed like this:
|
|       [...nn]      or like this        [nn...]
|
|    where '[' and ']' means a byte is enclosed and
|          'nn' is the bit number of the least significant
|           bit in the byte.
|
|    Examples: [...0], [...16],  [8...]
|
| STANDARD PACKING ORDER
| ======================
|
| For purposes of establishing a universal packing reference, 
| a standard packing arrangement needs to be defined.  This is 
| how the standard packing arrangement is laid out:
|
| Binary digit '1' is encoded as a '1' bit when stored in RAM.
|
| Bit Order Of Binary Number Held In CPU Register:
|
|    <--Left Shift                           Right Shift-->
|                    
|    [...56][...48][...40][...32][...24][...16][...8][...0]
|                                                        |
|                                                Low order 
|                                                 digit of
|                                            binary number
|                                           is held in the
|                                           low order cell
|                                         of the register.
|          
| Bit Order Of Binary Number Stored in RAM:
|
|    [0...][8...][16...][24...][32...][40...][48...][56...]
|
|    <--- Low Mem                              High Mem--->
|
|
| PACKING ORDER CODE FORMAT
| =========================
| A particular packing order is fully specified using a
| Packing Order Code formed by encoding the bit packing
| attributes as five bits like this:
|
|    [ 0 0 0 0 0 ]
|       \ \ \ \ \_ BitEncoding
|        \ \ \ \__ BitInByte
|         \ \ \___ ByteInPair
|          \______ QuadInOct
|
| where a '0' means that the ordering is the same as the 
| Standard Packing Order; a '1' means that the ordering is 
| different.  Each attribute has only two possibilities: the 
| same as the standard or different.
|
| Thus, the packing order code for the Standard Packing Order
| itself is '00000' -- all attributes are the same as the 
| standard.
|
| Here's a packing order example: given the following packing
| order derive the packing order code that identifies it.
|
|       Binary digit '1' is encoded as a '1' bit when stored
|       in RAM.
|
|       Bit Order Of Binary Number Held In CPU Register:
|
|     <--Left Shift                          Right Shift-->
|                    
|    [...56][...48][...40][...32][...24][...16][...8][...0]
|                                                        |
|                                                Low order 
|                                                 digit of
|                                            binary number
|                                           is held in the
|                                           low order cell
|                                         of the register.
|          
|       Bit Order Of Binary Number Stored in RAM:
|
|    [48...][56...][32...][40...][16...][24...][0...][8...]
|
|    <--- Low Mem                              High Mem--->
|
|    This is The Standard Packing Order:
|
|      Bit Order Of Binary Number Stored in RAM:
|
|    [0...][8...][16...][24...][32...][40...][48...][56...]
|
|    <--- Low Mem                              High Mem--->
|
|    By comparing the RAM storage formats the coorespondence 
|    to The Standard Packing Order can be determined:
|
|      BitEncoding: cooresponding,     0
|      BitInByte:   cooresponding,     0
|      ByteInPair:  cooresponding,     0
|      PairInQuad:  not cooresponding, 1
|      QuadInOct:   not cooresponding, 1
|
|      The resulting packing order code is: 11000.
|
|--------------------------------------------------------------
|
| NOTE: 
|
| HISTORY: 02.10.97
|          09.03.98 Extended from 32-bit to 64-bit.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLPairs.h"
#include "TLQuads.h"
#include "TLBit.h"

#include "TLPacking.h"

u64 ThePackingReference = 0x0807060504030201;
        // A known reference pattern used for run-time 
        // identification of the bit packing order of 
        // binary numbers.
        
u32 ThePackingOrder;
        // The current binary packing order used by the CPU as
        // determined at run-time.
        
/*------------------------------------------------------------
| HostToNetwork32Bit
|-------------------------------------------------------------
|
| PURPOSE: To translate a 32-bit host value to network byte
|          order.
|
| DESCRIPTION: Translates the order of the bytes in the given
| host value to produce another number such that when it is 
| saved to memory using a 32-bit store instruction it will
| end up in memory in network byte order, which is 
| most-significant byte to least-significant.
|
| HISTORY: 02.22.01 TL 
------------------------------------------------------------*/
u32
HostToNetwork32Bit( u32 HostValue )
{
    u8  NetworkOrderBuf[4];
    u32 NetValue;
    
    // Save the bytes to the buffer in order from most-
    // significant to least-significant.
    NetworkOrderBuf[0] = (u8) ( ( HostValue >> 24 ) & 0xFF );
    NetworkOrderBuf[1] = (u8) ( ( HostValue >> 16 ) & 0xFF );
    NetworkOrderBuf[2] = (u8) ( ( HostValue >>  8 ) & 0xFF );
    NetworkOrderBuf[3] = (u8) (   HostValue         & 0xFF );
    
    // Fetch the value using a 32-bit fetch instruction.
    NetValue = *( (u32*) NetworkOrderBuf );
    
    // Return the result.
    return( NetValue );
}

/*------------------------------------------------------------
| IdentifyRelativePackingOrder
|-------------------------------------------------------------
|
| PURPOSE: To identify the relative binary packing order 
|          implied by two copies of the same number held
|          in possibly different formats.
|
| DESCRIPTION: Expects to copies of the same number in 
| possibly different packing orders.
|
| The number must consist of eight differnt bytes that are 
| unique under bit reversal.
|
| Returns a packing order code or 0xFFFFFFFF if the packing 
| order can't be determined.
|
| EXAMPLE:   
|
|    IdentifyRelativePackingOrder( u, 0x0807060504030201 );
|
| NOTE: See 'TLPacking.h' for more on packing order codes.
|
| ASSUMES: 
|           
| HISTORY: 01.21.97 
|          01.23.97 revised to use 'Repack'.
|          09.03.98 Extended to 64-bit format from 32-bit.
------------------------------------------------------------*/
u32
IdentifyRelativePackingOrder( u64 a, u64 b )
{
    u64 x;
    u32 i;
    
    // For all possible packing orders.
    for( i = 0; i < 32; i++ )
    {
        x = Repack( i, a );
        
        // If transform 'i' produces a match...
        if( x == b )
        {
            // Then 'i' is the relative packing order.
            return( i );
        }
    }
    
    // Signal failure to identify the relative packing order.
    return( 0xFFFFFFFF );
}
    
/*------------------------------------------------------------
| IdentifyThePackingOrder
|-------------------------------------------------------------
|
| PURPOSE: To identify the current binary packing order used
|          by the CPU.
|
| DESCRIPTION: This sets the global variable 'ThePackingOrder'
| to be the packing order relative to the Standard Packing
| Order defined as follows:
|
| STANDARD PACKING ORDER
| ======================
|
| For purposes of establishing a universal packing reference, 
| a standard packing arrangement needs to be defined.  
|
| This is how the standard packing arrangement is laid out:
|
| Binary digit '1' is encoded as a '1' bit when stored in RAM.
|
| Bit Order Of Binary Number Held In CPU Register:
|
|    <--Left Shift                           Right Shift-->
|                    
|    [...56][...48][...40][...32][...24][...16][...8][...0]
|                                                        |
|                                                Low order 
|                                                 digit of
|                                            binary number
|                                           is held in the
|                                           low order cell
|                                         of the register.
|          
| Bit Order Of Binary Number Stored in RAM:
|
|    [0...][8...][16...][24...][32...][40...][48...][56...]
|
|    <--- Low Mem                              High Mem--->
|
| EXAMPLE:   IdentifyThePackingOrder();
|
| NOTE: See header for this file and 'TLPacking.h' for more 
|       on packing order codes.
|
| ASSUMES: This routine should be executed when the 
|          application first boots as part of the operating
|          environment configuration.
|
|          'ThePackingReference' == 0x0807060504030201.
|           
| HISTORY: 01.20.97 
|          09.03.98 Extended to 64-bit format from 32-bit.
------------------------------------------------------------*/
void
IdentifyThePackingOrder()
{
    u8   b[8];
    u64* AtOct;
    u32  bitEncoding, bitInByte, byteInPair;
    u32  pairInQuad, quadInOct;
    
    // Bit encoding is impossible to determine at run-time.
    // Defaults to being the same as the standard.
    //
    // Note that relative bit encoding CAN be determined 
    // when a copy of ThePackingReference number is sent
    // from one computer to another.  This has been seen when 
    // display buffers are read using XWindows under Unix.
    bitEncoding = Same;
    
    // Store known binary number into the byte buffer.
    AtOct  = (u64*) &b[0];
    *AtOct = ThePackingReference; // 0x0807060504030201
    
    // If any of the bytes is larger than 8 when read, then
    // the BitInByte order differs from the standard.
    if( b[0] > 8 )
    {
        bitInByte = Diff;
        
        // Reverse the bits so the other parts can be
        // identified.
        b[0] = ReverseBits[ b[0] ];
        b[1] = ReverseBits[ b[1] ];
        b[2] = ReverseBits[ b[2] ];
        b[3] = ReverseBits[ b[3] ];
        b[4] = ReverseBits[ b[4] ];
        b[5] = ReverseBits[ b[5] ];
        b[6] = ReverseBits[ b[6] ];
        b[7] = ReverseBits[ b[7] ];
    }
    else
    {
        bitInByte = Same;
    }
    
    // Determine the byte order in a pair.
    if( b[0] < b[1] )
    {
        byteInPair = Same;
    }
    else
    {
        byteInPair = Diff;
    }
    
    // Determine the pair order in a quad.
    if( b[0] < b[2] )
    {
        pairInQuad = Same;
    }
    else
    {
        pairInQuad = Diff;
    }
    
    // Determine the quad order in an oct.
    if( b[0] < b[4] )
    {
        quadInOct = Same;
    }
    else
    {
        quadInOct = Diff;
    }
    
    // Combine the parts of the packing code.
    ThePackingOrder = 
        ( quadInOct  << 4 ) | 
        ( pairInQuad << 3 ) | 
        ( byteInPair << 2 ) |
        ( bitInByte  << 1 ) |
        bitEncoding;
}
    
/*------------------------------------------------------------
| Repack
|-------------------------------------------------------------
|
| PURPOSE: To translate a binary number with a certain packing
|          order to the same number as expressed in another 
|          packing order.
|
| DESCRIPTION: The relative packing order parameter expresses
| the packing order attributes which need to be changed: if a
| one-bit is in the attribute mask position, that attribute
| should be changed.
|
| 'Repack' is reversible: to 'Repack' the same number twice 
| using the same packing order returns it to it's original 
| pattern.
|
| EXAMPLE:   
|
|        u = Repack( SSSSD, 0x010203 );
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.21.97
|          01.23.97 made parameter a relative packing order.
|          09.03.98 Extended to 64-bit format from 32-bit.
------------------------------------------------------------*/
u64
Repack( u32 RelativePackingOrder, u64 u )
{
    u8 i, U0, U1, U2, U3, U4, U5, U6, U7;

    // If the bit-encoding needs to change.
    if( RelativePackingOrder & BitEncoding )
    {
        // Flip the bits.
        u = ~u;
        
        // If this is the only attribute that changes,
        // return.
        if( RelativePackingOrder == BitEncoding )
        {
            return( u );
        }
    }

    // Unpack the number into bytes.
    U0 = (u8) ( u & 0xff ); u >>= 8;
    U1 = (u8) ( u & 0xff ); u >>= 8;
    U2 = (u8) ( u & 0xff ); u >>= 8;
    U3 = (u8) ( u & 0xff ); u >>= 8;
    U4 = (u8) ( u & 0xff ); u >>= 8;
    U5 = (u8) ( u & 0xff ); u >>= 8;
    U6 = (u8) ( u & 0xff ); u >>= 8;
    U7 = (u8) u;

    // If the bit-in-byte order needs to be changed.
    if( RelativePackingOrder & BitInByte )
    {
        U0 = ReverseBits[U0];
        U1 = ReverseBits[U1];
        U2 = ReverseBits[U2];
        U3 = ReverseBits[U3];
        U4 = ReverseBits[U4];
        U5 = ReverseBits[U5];
        U6 = ReverseBits[U6];
        U7 = ReverseBits[U7];
    }
    
    // If the byte-in-pair order needs to be changed.
    if( RelativePackingOrder & ByteInPair )
    {
        i = U0; U0 = U1; U1 = i; // Exchange the 1st pair of bytes.
        i = U2; U2 = U3; U3 = i; // Exchange the 2nd pair of bytes.
        i = U4; U4 = U5; U5 = i; // Exchange the 3rd pair of bytes.
        i = U6; U6 = U7; U7 = i; // Exchange the 4th pair of bytes.
    }
    
    // If the pair-in-quad order needs to be changed.
    if( RelativePackingOrder & PairInQuad )
    {
        i = U0; U0 = U2; U2 = i;
        i = U1; U1 = U3; U3 = i;
        i = U4; U4 = U6; U6 = i;
        i = U5; U5 = U7; U7 = i;
    }
    
    // If the quad-in-oct order needs to be changed.
    if( RelativePackingOrder & QuadInOct )
    {
        i = U0; U0 = U4; U4 = i;
        i = U1; U1 = U5; U5 = i;
        i = U2; U2 = U6; U6 = i;
        i = U3; U3 = U7; U7 = i;
    }
    
    // Repack the number into bytes.
    u =  U7; u <<= 8;
    u |= U6; u <<= 8;
    u |= U5; u <<= 8;
    u |= U4; u <<= 8;
    u |= U3; u <<= 8;
    u |= U2; u <<= 8;
    u |= U1; u <<= 8;
    u |= U0;
     
    return( u );
}

/*------------------------------------------------------------
| RepackBytes
|-------------------------------------------------------------
|
| PURPOSE: To convert a series of bytes holding binary 
|          numbers with a certain packing order to the same 
|          numbers as expressed in another packing order.
|
| DESCRIPTION: The relative packing order parameter expresses
| the packing order attributes which need to be changed: if a
| one-bit is in the attribute mask position, that attribute
| should be changed.
|
| 'RepackBytes' is reversible: to 'RepackBytes' the same 
| numbers twice using the same packing order returns the bytes
| to the original pattern.
|
| Only the low two bits of the RelativePackingOrder which 
| pertain to packing within a byte are active.
|
| EXAMPLE:   
|
|        u = RepackBytes( SSSSD, From, To, Count );
| NOTE: 
|
| ASSUMES: If the ranges overlap they are the same.
|           
| HISTORY: 02.10.97 from 'Repack'.
------------------------------------------------------------*/
void
RepackBytes( u32 RelativePackingOrder, 
             u8* From, u8* To, u32 Count )
{
    // There are four cases:
    switch( RelativePackingOrder & (BitEncoding|BitInByte) )
    {
        case( BitEncoding ): 
        {
            // Just flip the bits.
            
            // For each byte.
            while( Count-- )
            {
                // Flip the bits.
                *To++ = (u8) ~(*From++);
            }
            return;
        }
        
        case( BitInByte ): 
        {
            // Just reverse the bits.
            
            // For each byte.
            while( Count-- )
            {
                // Reverse the bits.
                *To++ = ReverseBits[ (*From++) ];
            }
            return;
        }
        
        case( BitEncoding|BitInByte ): 
        {
            // Flip and reverse the bits.
            
            // For each byte.
            while( Count-- )
            {
                // Reverse and flip the bits.
                *To++ = (u8) ~(ReverseBits[ (*From++) ]);
            }
            return;
        }
        
        case( 0 ):
        {   // No conversion is needed, just copy the bytes 
            // if source and destination are different.
            if( From != To ) 
            {
                CopyBytes( From, To, Count );
            }
            
            return;
        }
    }
}
        
/*------------------------------------------------------------
| RepackOcts
|-------------------------------------------------------------
|
| PURPOSE: To convert a series of octs holding binary 
|          numbers with a certain packing order to the same 
|          numbers as expressed in another packing order.
|
| DESCRIPTION: The relative packing order parameter expresses
| the packing order attributes which need to be changed: if a
| one-bit is in the attribute mask position, that attribute
| should be changed.
|
| 'RepackOcts' is reversible: to 'RepackOcts' the same 
| numbers twice using the same packing order returns the bits
| to the original pattern.
|
| Only the low two bits which pertain to packing within a byte
| are active.
|
| EXAMPLE:   
|
|        u = RepackQuads( SSSD, From, To, Count );
| NOTE: 
|
| ASSUMES: If the ranges overlap they are the same.
|           
| HISTORY: 09.03.98 from 'RepackQuads'.
------------------------------------------------------------*/
void
RepackOcts( u32 RelativePackingOrder, 
             u64* From, u64* To, u32 OctCount )
{
    u8      b[8], b0, b1, b2, b3, b4, b5, b6, b7;
    u16     p0, p1, p2, p3;
    u32     q0, q1;
    u8*     Atb0;
    u8*     Atb1;
    u8*     Atb2;
    u8*     Atb3;
    u8*     Atb4;
    u8*     Atb5;
    u8*     Atb6;
    u8*     Atb7;
    u16*    Atp0;
    u16*    Atp1;
    u16*    Atp2;
    u16*    Atp3;
    u32*    Atq0;
    u32*    Atq1;
    u64*    Atb;
    u32     IsFlipBits, IsReverseBits, IsSwapBytesInPair;
    u32     IsSwapPairsInQuad, IsSwapQuadsInOct;
    
    // Refer to the oct buffer.
    Atb = (u64*) &b[0];
    
    // Refer to the quads in the oct buffer.
    Atq0 = (u32*) &b[0];
    Atq1 = (u32*) &b[4];

    // Refer to the pairs in the oct buffer.
    Atp0 = (u16*) &b[0];
    Atp1 = (u16*) &b[2];
    Atp2 = (u16*) &b[4];
    Atp3 = (u16*) &b[6];

    // Refer the individual bytes in the oct buffer.
    Atb0 = &b[0];
    Atb1 = &b[1];
    Atb2 = &b[2];
    Atb3 = &b[3];
    Atb4 = &b[4];
    Atb5 = &b[5];
    Atb6 = &b[6];
    Atb7 = &b[7];
    
    // Determine the packing options.
    IsSwapQuadsInOct  = (u32) ( RelativePackingOrder & QuadInOct   );
    IsSwapPairsInQuad = (u32) ( RelativePackingOrder & PairInQuad  );
    IsSwapBytesInPair = (u32) ( RelativePackingOrder & ByteInPair  );
    IsFlipBits        = (u32) ( RelativePackingOrder & BitEncoding );
    IsReverseBits     = (u32) ( RelativePackingOrder & BitInByte   );
        
    // For each oct.
    while( OctCount-- )
    {
        // Get the oct from the source.
        *Atb = *From++;
                    
        // Get the separate bytes.
        b0 = *Atb0;
        b1 = *Atb1;
        b2 = *Atb2;
        b3 = *Atb3;
        b4 = *Atb4;
        b5 = *Atb5;
        b6 = *Atb6;
        b7 = *Atb7;
                
        // If the bits need flipping.
        if( IsFlipBits )
        {
            b0 = (u8) ~b0;
            b1 = (u8) ~b1;
            b2 = (u8) ~b2;
            b3 = (u8) ~b3;
            b4 = (u8) ~b4;
            b5 = (u8) ~b5;
            b6 = (u8) ~b6;
            b7 = (u8) ~b7;
        }
                
        // If the bits in byte need reversing.
        if( IsReverseBits )
        {
            b0 = ReverseBits[b0];
            b1 = ReverseBits[b1];
            b2 = ReverseBits[b2];
            b3 = ReverseBits[b3];
            b4 = ReverseBits[b4];
            b5 = ReverseBits[b5];
            b6 = ReverseBits[b6];
            b7 = ReverseBits[b7];
        }
                
        // If need to swap the bytes in each pair.
        if( IsSwapBytesInPair )
        {
            *Atb0 = b1;
            *Atb1 = b0;
            *Atb2 = b3;
            *Atb3 = b2;
            *Atb4 = b5;
            *Atb5 = b4;
            *Atb6 = b7;
            *Atb7 = b6;
        }
        else // Leave byte-in-pair ordering the same.
        {
            *Atb0 = b0;
            *Atb1 = b1;
            *Atb2 = b2;
            *Atb3 = b3;
            *Atb4 = b4;
            *Atb5 = b5;
            *Atb6 = b6;
            *Atb7 = b7;
        }
        
        // If pairs need to be swapped.
        if( IsSwapPairsInQuad )
        {       
            p0 = *Atp0;
            p1 = *Atp1;
            p2 = *Atp2;
            p3 = *Atp3;
            *Atp0 = p1;
            *Atp1 = p0;
            *Atp2 = p3;
            *Atp3 = p2;
        }
        
        // If quads need to be swapped.
        if( IsSwapQuadsInOct )
        {       
            q0 = *Atq0;
            q1 = *Atq1;
            *Atq0 = q1;
            *Atq1 = q0;
        }
                
        // Save the repacked oct at the destination.
        *To++ = *Atb;
    }
}

/*------------------------------------------------------------
| RepackPairs
|-------------------------------------------------------------
|
| PURPOSE: To convert a series of pairs holding binary 
|          numbers with a certain packing order to the same 
|          numbers as expressed in another packing order.
|
| DESCRIPTION: The relative packing order parameter expresses
| the packing order attributes which need to be changed: if a
| one-bit is in the attribute mask position, that attribute
| should be changed.
|
| 'RepackPairs' is reversible: to 'RepackPairs' the same 
| numbers twice using the same packing order returns the bits
| to the original pattern.
|
| Only the low three bits of the RelativePackingOrder which 
| pertain to packing within a pair are active.
|
| EXAMPLE:   
|
|        u = RepackPairs( SSSSD, From, To, Count );
| NOTE: 
|
| ASSUMES: If the ranges overlap they are the same.
|           
| HISTORY: 02.10.97 from 'RepackBytes'.
------------------------------------------------------------*/
void
RepackPairs( u32 RelativePackingOrder, 
             u16* From, u16* To, u32 PairCount )
{
    u8      b[2], b0, b1;
    u8*     Atb0;
    u8*     Atb1;
    u16*    Atb;
    u32     IsFlipBits, IsReverseBits;
    
    // If the bytes in a pair need to be swapped.
    if( RelativePackingOrder & ByteInPair )
    {
        // Refer to the byte buffer as a pair.
        Atb = (u16*) &b[0];
        
        // Refer the individual bytes in the pair buffer.
        Atb0 = &b[0];
        Atb1 = &b[1];
        
        // Determine if bit flipping or reversal are 
        // needed.
        IsFlipBits    = (u32) ( RelativePackingOrder & BitEncoding );
        IsReverseBits = (u32) ( RelativePackingOrder & BitInByte   );
        
        // For each pair.
        while( PairCount-- )
        {
            // Get the pair from the source.
            *Atb = *From++;
            
            // Get the separate bytes.
            b0 = *Atb0;
            b1 = *Atb1;
            
            // If the bits need flipping.
            if( IsFlipBits )
            {
                b0 = (u8) ~b0;
                b1 = (u8) ~b1;
            }
            
            // If the bits in byte need reversing.
            if( IsReverseBits )
            {
                b0 = ReverseBits[b0];
                b1 = ReverseBits[b1];
            }
            
            // Swap the bytes.
            *Atb0 = b1;
            *Atb1 = b0;
            
            // Save the repacked pair at the destination.
            *To++ = *Atb;
        }
    }
    else // Treat this as byte-wise repacking.
    {
        RepackBytes( RelativePackingOrder, 
                     (u8*) From, (u8*) To, PairCount<<1 );
    }
}

/*------------------------------------------------------------
| RepackQuads
|-------------------------------------------------------------
|
| PURPOSE: To convert a series of quads holding binary 
|          numbers with a certain packing order to the same 
|          numbers as expressed in another packing order.
|
| DESCRIPTION: The relative packing order parameter expresses
| the packing order attributes which need to be changed: if a
| one-bit is in the attribute mask position, that attribute
| should be changed.
|
| 'RepackQuads' is reversible: to 'RepackQuads' the same 
| numbers twice using the same packing order returns the bits
| to the original pattern.
|
| Only the low four bits of the RelativePackingOrder which 
| pertain to packing within a quad are active.
|
| EXAMPLE:   
|
|        u = RepackQuads( SSSSD, From, To, Count );
| NOTE: 
|
| ASSUMES: If the ranges overlap they are the same.
|           
| HISTORY: 02.10.97 from 'RepackPairs'.
|          01.14.98 Added test for simple case where no 
|                   change is needed.
------------------------------------------------------------*/
void
RepackQuads( u32 RelativePackingOrder, 
             u32* From, u32* To, u32 QuadCount )
{
    u8      b[4], b0, b1, b2, b3;
    u16     p0, p1;
    u8*     Atb0;
    u8*     Atb1;
    u8*     Atb2;
    u8*     Atb3;
    u16*    Atp0;
    u16*    Atp1;
    u32*    Atb;
    u32     IsFlipBits, IsReverseBits, IsSwapBytesInPair;
    u32     IsSwapPairsInQuad;
    
    // If there is no relative difference.
    if( RelativePackingOrder == SSSSS )
    {
        // Just return.
        return;
    }
    
    // Refer to the quad buffer.
    Atb = (u32*) &b[0];
    
    // Refer to the pairs in the quad buffer.
    Atp0 = (u16*) &b[0];
    Atp1 = (u16*) &b[2];

    // Refer the individual bytes in the quad buffer.
    Atb0 = &b[0];
    Atb1 = &b[1];
    Atb2 = &b[2];
    Atb3 = &b[3];
    
    // Determine the packing options.
    IsSwapPairsInQuad = (u32) ( RelativePackingOrder & PairInQuad  );
    IsSwapBytesInPair = (u32) ( RelativePackingOrder & ByteInPair  );
    IsFlipBits        = (u32) ( RelativePackingOrder & BitEncoding );
    IsReverseBits     = (u32) ( RelativePackingOrder & BitInByte   );
        
    // For each quad.
    while( QuadCount-- )
    {
        // Get the quad from the source.
        *Atb = *From++;
        
        // If pairs need to be swapped.
        if( IsSwapPairsInQuad )
        {       
            p0 = *Atp0;
            p1 = *Atp1;
            *Atp0 = p1;
            *Atp1 = p0;
        }
            
        // Get the separate bytes.
        b0 = *Atb0;
        b1 = *Atb1;
        b2 = *Atb2;
        b3 = *Atb3;
                
        // If the bits need flipping.
        if( IsFlipBits )
        {
            b0 = (u8) ~b0;
            b1 = (u8) ~b1;
            b2 = (u8) ~b2;
            b3 = (u8) ~b3;
        }
                
        // If the bits in byte need reversing.
        if( IsReverseBits )
        {
            b0 = ReverseBits[b0];
            b1 = ReverseBits[b1];
            b2 = ReverseBits[b2];
            b3 = ReverseBits[b3];
        }
                
        // If need to swap the bytes in each pair.
        if( IsSwapBytesInPair )
        {
            *Atb0 = b1;
            *Atb1 = b0;
            *Atb2 = b3;
            *Atb3 = b2;
        }
        else // Leave byte-in-pair ordering the same.
        {
            *Atb0 = b0;
            *Atb1 = b1;
            *Atb2 = b2;
            *Atb3 = b3;
        }
                
        // Save the repacked quad at the destination.
        *To++ = *Atb;
    }
}

/*------------------------------------------------------------
| TestPacking
|-------------------------------------------------------------
|
| PURPOSE: To validate the packing functions.
|
| DESCRIPTION: Compares the operation of all the packing
| functions using all of the different packing options to 
| make sure that the operation is consistent.
|
| Halts in the debugger on an error.
|
| EXAMPLE:   
|
|        TestPacking();
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 09.03.98 Wrote and ran this test, found an error
|                   and fixed it.
------------------------------------------------------------*/
void
TestPacking()
{
    u64 a[2], b[2];
    u32 i, j, RelOrder;
    
    // First identify the packing order of the current CPU.
    IdentifyThePackingOrder();

    // For all packing order combinations, 'i' and 'j'.
    for( i = 0; i < 32; i++ )
    {
        for( j = 0; j < 32; j++ )
        {
            // Make two copies of a known number in terms
            // of packing order 'i'.
            a[0] = Repack( i, ThePackingReference );
            a[1] = a[0];
            
            // Make two copies of a known number in terms
            // of packing order 'j'.
            b[0] = Repack( j, ThePackingReference );
            b[1] = b[0];
            
            // Determine the relative packing order between
            // 'i' and 'j'.
            RelOrder = 
                IdentifyRelativePackingOrder( a[0], b[0] );
                
            // If the relative packing orders don't tally
            // with the difference between the packing order
            // codes.
            if( RelOrder != ( i ^ j ) )
            {
                // Halt to show error.
//TBD               Debugger();
            }
            
            // Repack the octs for 'j' using the packing order 
            // relative to 'i', thereby translating the number 
            // into the same form as 'i'.
            RepackOcts( RelOrder, (u64*) &b[0], (u64*) &b[0], 2 );
        
            // If the results are not the same.
            if( CompareBytes( (u8*) &a[0], 16, (u8*) &b[0], 16 ) )
            {
                // Halt to show error.
//TBD               Debugger();
            }
                        
            // Make two copies of a known number in terms
            // of packing order 'i', ignoring the QuadInOct ordering.
            a[0] = Repack( i & SDDDD, ThePackingReference );
            a[1] = a[0];
            
            
            // Make two copies of a known number in terms
            // of packing order 'j', ignoring the QuadInOct ordering.
            b[0] = Repack( j & SDDDD, ThePackingReference );
            b[1] = b[0];
            
            // Repack the quads for 'j' using the packing order 
            // relative to 'i', thereby translating the number 
            // into the same form as 'i'.
            RepackQuads( RelOrder, (u32*) &b[0], (u32*) &b[0], 4 );
        
            // If the results are not the same.
            if( CompareBytes( (u8*) &a[0], 16, (u8*) &b[0], 16 ) )
            {
                // Halt to show error.
//TBD               Debugger();
            }
                
                        
            // Make two copies of a known number in terms
            // of packing order 'i', ignoring the QuadInOct and 
            // PairInQuad ordering.
            a[0] = Repack( i & SSDDD, ThePackingReference );
            a[1] = a[0];
            
            // Make two copies of a known number in terms
            // of packing order 'j',  ignoring the QuadInOct and 
            // PairInQuad ordering.
            b[0] = Repack( j & SSDDD, ThePackingReference );
            b[1] = b[0];
            
            // Repack the pairs for 'j' using the packing order 
            // relative to 'i', thereby translating the number 
            // into the same form as 'i'.
            RepackPairs( RelOrder, (u16*) &b[0], (u16*) &b[0], 8 );
        
            // If the results are not the same.
            if( CompareBytes( (u8*) &a[0], 16, (u8*) &b[0], 16 ) )
            {
                // Halt to show error.
//TBD               Debugger();
            }
            
                                    
            // Make two copies of a known number in terms
            // of packing order 'i', ignoring the QuadInOct,
            // PairInQuad and ByteInPair ordering.
            a[0] = Repack( i & SSSDD, ThePackingReference );
            a[1] = a[0];
            
            // Make two copies of a known number in terms
            // of packing order 'j', ignoring the QuadInOct,
            // PairInQuad and ByteInPair ordering.
            b[0] = Repack( j & SSSDD, ThePackingReference );
            b[1] = b[0];
            
            // Repack the pairs for 'j' using the packing order 
            // relative to 'i', thereby translating the number 
            // into the same form as 'i'.
            RepackBytes( RelOrder, (u8*) &b[0], (u8*) &b[0], 16 );
        
            // If the results are not the same.
            if( CompareBytes( (u8*) &a[0], 16, (u8*) &b[0], 16 ) )
            {
                // Halt to show error.
//TBD               Debugger();
            }
        }
    }
}
