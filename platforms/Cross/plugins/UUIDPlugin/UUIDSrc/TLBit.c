/*------------------------------------------------------------
| TLBit.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide bit-addressed memory procedures.
|
| DESCRIPTION: 
|
| NOTE: Update to use 64-bit addresses.
|
| HISTORY: 01.13.97
|          01.20.00 Move bit transfer functions to 
|                   TLBitTransfer.c.
------------------------------------------------------------*/

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLBytesExtra.h"
#include "TLBit.h"

// Used for selecting a bit within a byte.
u8      
BitOfByte[8] =
{
    1, 
    2,
    4,
    8, 
    16,
    32,
    64,
    128
};

// Used for clearing a bit within a byte.
u8      
NotBitOfByte[8] =
{
    (u8) ~1, 
    (u8) ~2,
    (u8) ~4,
    (u8) ~8, 
    (u8) ~16,
    (u8) ~32,
    (u8) ~64,
    (u8) ~128
};

// Used for selecting a bit within an access unit.
u32     
BitOfUnit[32] = // Same as 'PowerOf2'.
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
| LoMask
|-------------------------------------------------------------
|
| PURPOSE: To provide a bit mask for the least significant 
|          bits at a given bit offset.
|
| DESCRIPTION: 
|
|   Each entry takes the form:
|
|         [LoMask]
|          4 bytes
|       
|       and the (entry offset)/4 is equal to the bit offset 
|       to which the mask corresponds
|
| EXAMPLE: The LSB mask for bit 5 is at offset 20 (5 << 2) 
|          and the value is
|          0x0000003f or in binary, 
|          %00000000000000000000000000111111.
|                                     ^-bit offset 5
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  05.25.90
|           04.26.96 from Sage file, 'Math.a'.
------------------------------------------------------------*/
u32
LoMask[32] =
{
    0x00000001,
    0x00000003,
    0x00000007,
    0x0000000f,
    0x0000001f,
    0x0000003f,
    0x0000007f,
    0x000000ff,
    0x000001ff,
    0x000003ff,
    0x000007ff,
    0x00000fff, 
    0x00001fff, 
    0x00003fff, 
    0x00007fff, 
    0x0000ffff,  
    0x0001ffff, 
    0x0003ffff, 
    0x0007ffff, 
    0x000fffff, 
    0x001fffff, 
    0x003fffff, 
    0x007fffff, 
    0x00ffffff, 
    0x01ffffff, 
    0x03ffffff, 
    0x07ffffff, 
    0x0fffffff, 
    0x1fffffff, 
    0x3fffffff, 
    0x7fffffff, 
    0xffffffff
};
                    
/*------------------------------------------------------------
| HiMask
|-------------------------------------------------------------
|
| PURPOSE: To provide a bit mask for the most significant 
|          bits at a given bit offset.
|
| DESCRIPTION: 
|
|   Each entry takes the form:
|
|         [HiMask]
|           4 bytes
|       
|       and the (entry offset)/4 is equal to the bit offset 
|       to which the mask corresponds
|
| EXAMPLE: The MSB mask for bit 5 is at offset 20, HiMask[5],
|          (5 << 2) and the value is
|           0xffffffe0 or in binary, 
|           %11111111111111111111111111100000.
|                                      ^-bit offset 5
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  05.25.90
|           04.26.96 from Sage file, 'Math.a'.
------------------------------------------------------------*/
u32
HiMask[32] =
{
    0xffffffff,
    0xfffffffe,
    0xfffffffc,
    0xfffffff8,
    0xfffffff0,
    0xffffffe0,
    0xffffffc0,
    0xffffff80,
    0xffffff00,
    0xfffffe00,
    0xfffffc00,
    0xfffff800, 
    0xfffff000, 
    0xffffe000, 
    0xffffc000, 
    0xffff8000,  
    0xffff0000, 
    0xfffe0000, 
    0xfffc0000, 
    0xfff80000,
    0xfff00000, 
    0xffe00000, 
    0xffc00000, 
    0xff800000, 
    0xff000000, 
    0xfe000000, 
    0xfc000000, 
    0xf8000000, 
    0xf0000000, 
    0xe0000000, 
    0xc0000000, 
    0x80000000
};

/*------------------------------------------------------------
| ReverseBits
|-------------------------------------------------------------
|
| PURPOSE: To reverse the bits in a byte.
|
| DESCRIPTION: The table entry at the offset equal to the
|              byte value contains the bit-reversed value.
|
| Table produced with this program:
|
| {
|       s32 i,j;
|       FILE* F;
|   
|       F = fopen("ReverseBitsFile", "w+");
|
|       MakeReverseBits();
|   
|       // Output 32 rows of 8 numbers per row.
|       for( i = 0; i < 32; i++ )
|       {
|           fprintf( F, "  " );
|
|           for( j = 0; j < 8; j++ )
|           {
|               fprintf( F, "%5d,", ReverseBits[ i*8 + j ] );
|           
|               if( j == 7 )
|               {
|                   fprintf( F, "\n" );
|               }
|           }
|       }
|
|       fclose(F);
|   
|       SetFileType("ReverseBitsFile","TEXT");
|       SetFileCreator("ReverseBitsFile","CWIE");
|   
|       ExitToShell();
| }
|
| EXAMPLE:    r = ReverseByte[b];
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 01.21.97
------------------------------------------------------------*/
u8
ReverseBits[256] =
{
      0,  128,   64,  192,   32,  160,   96,  224,
     16,  144,   80,  208,   48,  176,  112,  240,
      8,  136,   72,  200,   40,  168,  104,  232,
     24,  152,   88,  216,   56,  184,  120,  248,
      4,  132,   68,  196,   36,  164,  100,  228,
     20,  148,   84,  212,   52,  180,  116,  244,
     12,  140,   76,  204,   44,  172,  108,  236,
     28,  156,   92,  220,   60,  188,  124,  252,
      2,  130,   66,  194,   34,  162,   98,  226,
     18,  146,   82,  210,   50,  178,  114,  242,
     10,  138,   74,  202,   42,  170,  106,  234,
     26,  154,   90,  218,   58,  186,  122,  250,
      6,  134,   70,  198,   38,  166,  102,  230,
     22,  150,   86,  214,   54,  182,  118,  246,
     14,  142,   78,  206,   46,  174,  110,  238,
     30,  158,   94,  222,   62,  190,  126,  254,
      1,  129,   65,  193,   33,  161,   97,  225,
     17,  145,   81,  209,   49,  177,  113,  241,
      9,  137,   73,  201,   41,  169,  105,  233,
     25,  153,   89,  217,   57,  185,  121,  249,
      5,  133,   69,  197,   37,  165,  101,  229,
     21,  149,   85,  213,   53,  181,  117,  245,
     13,  141,   77,  205,   45,  173,  109,  237,
     29,  157,   93,  221,   61,  189,  125,  253,
      3,  131,   67,  195,   35,  163,   99,  227,
     19,  147,   83,  211,   51,  179,  115,  243,
     11,  139,   75,  203,   43,  171,  107,  235,
     27,  155,   91,  219,   59,  187,  123,  251,
      7,  135,   71,  199,   39,  167,  103,  231,
     23,  151,   87,  215,   55,  183,  119,  247,
     15,  143,   79,  207,   47,  175,  111,  239,
     31,  159,   95,  223,   63,  191,  127,  255 
};

/*------------------------------------------------------------
| AlignToByte
|-------------------------------------------------------------
|
| PURPOSE: To align a bit cursor to a byte boundary, moving
|          higher in memory if not already at a byte boundary.
|
| DESCRIPTION:
|
| EXAMPLE:        AlignToByte( &B );
|
| ASSUMES: 
|
| HISTORY: 03.29.00
------------------------------------------------------------*/
void  
AlignToByte( BitCursor* B )  
             // Address of a BitCursor record that refers to 
             // the next bit to be read. 
{
    // If the low-order bit of a byte is first.
    if( B->IsLowBitFirst )
    {
        // If the indicated bit is not the low bit of a byte.
        if( B->AtBit != 1 )
        {
            // Advance to the next byte.
            B->AtByte += 1;
            B->AtBit  =  1;
        }
    }
    else // The high bit is regarded as first.
    {
        // If the indicated bit is not the high bit of a byte.
        if( B->AtBit != 128 )
        {
            // Advance to the next byte.
            B->AtByte += 1;
            B->AtBit  =  128;
        }
    }
}

/*------------------------------------------------------------
| BitsBetweenBits
|-------------------------------------------------------------
| 
| PURPOSE: To subtract one bit address from another to find
|          the number of bits between them.
| 
| DESCRIPTION:  Result = Hi - Lo
| 
| EXAMPLE:  
|
|             
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 01.14.00
------------------------------------------------------------*/
                    // Returns the bit count found by 
u64                 // subtracting the 'Lo' address from 'Hi'.
BitsBetweenBits( 
    BitCursor* Hi,  // Address of a BitCursor record that
                    // refers to a bit that is at or above the 
                    // bit referred to by 'Lo'.
                    //
    BitCursor* Lo ) // Address of a BitCursor record that
                    // refers to a bit that is at or below the 
                    // bit referred to by 'Hi'.
                    //
{
    u64         Hb, Lb, D;
    BitCursor   H, L;
    
    // Make local copies of the bit cursors.
    H = *Hi;
    L = *Lo;
    
    // Calculate the bit addresses of 'Lo' and 'Hi'.
    Hb = ( (u64) H.AtByte ) << 3;
    Lb = ( (u64) L.AtByte ) << 3;  
                
    // If the low-order bit of a byte is first.
    if( H.IsLowBitFirst )
    {
        // Until the bit mask is in the first position.
        while( !( H.AtBit & 1 ) )
        {
            // Add one to the bit address.
            Hb += 1;
            
            // Shift the bit mask to the right.
            H.AtBit = H.AtBit >> 1;
        }
            
        // Until the bit mask is in the first position.
        while( !( L.AtBit & 1 ) )
        {
            // Add one to the bit address.
            Lb += 1;
            
            // Shift the bit mask to the right.
            L.AtBit = L.AtBit >> 1;
        }
    }
    else // High-order bit is first.
    {
        // Until the bit mask is in the first position.
        while( !( H.AtBit & 128 ) )
        {
            // Add one to the bit address.
            Hb += 1;
            
            // Shift the bit mask to the left.
            H.AtBit = H.AtBit << 1;
        }
            
        // Until the bit mask is in the first position.
        while( !( L.AtBit & 128 ) )
        {
            // Add one to the bit address.
            Lb += 1;
            
            // Shift the bit mask to the left.
            L.AtBit = L.AtBit << 1;
        }
    }
    
    // Substract the low from the high address.
    D = Hb - Lb;
    
    // Return the difference.
    return( D );
}

/*------------------------------------------------------------
| CountBitsInBytes
|-------------------------------------------------------------
|
| PURPOSE: To count the number of '1' bits in a range of bytes.
|
| DESCRIPTION:  
|
| EXAMPLE:  c = CountBitsInBytes( (u8*) ABuffer, (u32) count );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.26.95 
|          12.27.95 validated by stepping through an example.
|          07.04.96 sped up by using 'CountBytes'.
------------------------------------------------------------*/
u32
CountBitsInBytes( u8* AtBytes, u32 Count )
{
    u32     total;
    u32     i;
    u8      b;
    u32     BitsInByte;
    u32     Counts[256];

    // First accumulate the number of byte patterns.
    CountBytes( AtBytes, Count, Counts );
    
    // Then total the bytes times the number of times 
    // they occur.
    total = 0;
    
    for( i = 0; i < 256; i++ )
    {
        // Count '1' bits in each byte pattern. 
        b = (u8) i;
        BitsInByte = 0;
        
        while( b )
        {
            BitsInByte += (u32) ( b & 1 );
            b >>= 1;
        }
        
        // Subtotal instances of byte pattern and bitcount.
        total += BitsInByte * Counts[i];
    }

    return( total );
}

/*------------------------------------------------------------
| GetBits
|-------------------------------------------------------------
| 
| PURPOSE: To fetch the next BitCount bits at a bit cursor.
| 
| DESCRIPTION: Fetches up to the next 64 bits.
| 
| EXAMPLE:  
|
|    BitCursor B;
|
|    B.AtByte = TheByteOfInterest;
|    B.AtBit  = 1;
|    B.IsLowBitFirst = 1;
|
|    r = GetBits( &B, 15 );
|             
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 12.28.99
------------------------------------------------------------*/
                  // Returns the bits fetched in the low-order
u64               // end of a 'u64'.
GetBits( 
    BitCursor* B, // Address of a valid BitCursor record that
                  // refers to the next bit to be read.
                  //
    u32 BitCount )// Number of bits to fetch, up to 64.
{
    u8   A;
    u64  Result;
    u8*  AtByte;
    u8   AtBit;
    u8   IsLowBitFirst;
    
    // Get local copies of the cursor fields.
    AtByte        = B->AtByte;
    AtBit         = B->AtBit;
    IsLowBitFirst = B->IsLowBitFirst;
    
    // Clear the result.
    Result = 0;  
    
    // Fetch the first byte to 'A'.
    A = *AtByte;
        
    // If the low-order bit of a byte is first.
    if( IsLowBitFirst )
    {
        // Until all bits are fetched.
        while( BitCount-- )
        {
            // Make room in the result for the next bit.
            Result = Result << 1;
            
            // If the indexed bit is '1'.
            if( A & AtBit )
            {
                // Move a '1' into the result.
                Result |= 1;
            }
            
            // Shift the bit-in-byte mask to the left.
            AtBit = AtBit << 1;
            
            // If the next byte is needed.
            if( AtBit == 0 )
            {
                // Advance the byte address.
                AtByte++;
                
                // Get the byte.
                A = *AtByte;
                
                // Set the bit-in-byte mask to the first bit 
                // in the byte, the lowest one in this case.
                AtBit = 1;
            }
        }
    }
    else // High-order bit in a byte is regarded as
         // first.
    {
        // Until all bits are fetched.
        while( BitCount-- )
        {
            // Make room in the result for the next bit.
            Result = Result << 1;
            
            // If the indexed bit is '1'.
            if( A & AtBit )
            {
                // Move a '1' into the result.
                Result |= 1;
            }
            
            // Shift the bit-in-byte mask to the right.
            AtBit = AtBit >> 1;
            
            // If the next byte is needed.
            if( AtBit == 0 )
            {
                // Advance the byte address.
                AtByte++;
                
                // Get the byte.
                A = *AtByte;
                
                // Set the bit-in-byte mask to the first bit 
                // in the byte, the highest one in this case.
                AtBit = 128;
            }
        }
    }
        
    // Update the cursor record.
    B->AtByte = AtByte;
    B->AtBit  = AtBit;
    
    // Return the result.
    return( Result );
}

/*------------------------------------------------------------
| MakeReverseBits
|-------------------------------------------------------------
|
| PURPOSE: To generate the 'ReverseBits' table.
|
| DESCRIPTION: 
|
| EXAMPLE:     
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.21.97
------------------------------------------------------------*/
void
MakeReverseBits()
{
    s32 i;
    u8  j;
    
    for( i = 0; i < 256; i++ )
    {
        j =  (u8) ( (i & BitOfByte[0]) ? BitOfByte[7] : 0 );
        j |= (u8) ( (i & BitOfByte[1]) ? BitOfByte[6] : 0 );
        j |= (u8) ( (i & BitOfByte[2]) ? BitOfByte[5] : 0 );
        j |= (u8) ( (i & BitOfByte[3]) ? BitOfByte[4] : 0 );
        j |= (u8) ( (i & BitOfByte[4]) ? BitOfByte[3] : 0 );
        j |= (u8) ( (i & BitOfByte[5]) ? BitOfByte[2] : 0 );
        j |= (u8) ( (i & BitOfByte[6]) ? BitOfByte[1] : 0 );
        j |= (u8) ( (i & BitOfByte[7]) ? BitOfByte[0] : 0 );
        
        ReverseBits[i] = j;
    }
}
 
/*------------------------------------------------------------
| PadToByte
|-------------------------------------------------------------
|
| PURPOSE: To fill bits from the current bit to a byte 
|          boundary if not already at a byte boundary.
|
| DESCRIPTION: Moves upward in memory if necessary and fills
| with the given pad bit.
|
| EXAMPLE:        PadToByte( &B, 0 );
|
| ASSUMES: 
|
| HISTORY: 03.29.00
------------------------------------------------------------*/
void  
PadToByte( 
    BitCursor* B,  
               // Address of a BitCursor record that refers to 
               // the next bit to be written. 
    u32        Value )
               // Padding bit value, 1 or 0.
{
    // If the low-order bit of a byte is first.
    if( B->IsLowBitFirst )
    {
        // Until the indicated bit is the low bit of a byte.
        while( B->AtBit != 1 )
        {
            // Pad with zero bits.
            PutBits( B,  1, (u64) Value );
        }
    }
    else // The high bit is regarded as first.
    {
        // Until the indicated bit is the high bit of a byte.
        while( B->AtBit != 128 )
        {
            // Pad with zero bits.
            PutBits( B,  1, (u64) Value );
        }
    }
}

/*------------------------------------------------------------
| PutBits
|-------------------------------------------------------------
| 
| PURPOSE: To store the next BitCount bits at a bit cursor.
| 
| DESCRIPTION: Stores up to the next 64 bits.
| 
| EXAMPLE:  
|
|    BitCursor B;
|    u64       SomeBits;
|
|    B.AtByte = TheByteOfInterest;
|    B.AtBit  = 1;
|    B.IsLowBitFirst = 1;
|
|    SomeBits = 0xfe10;
|   
|    r = PutBits( &B, 15, SomeBits );
|             
| NOTE: PutBits and GetBits work together consistently to
|       keep bit field values in the same order.
| 
| ASSUMES:  
| 
| HISTORY: 12.28.99
------------------------------------------------------------*/
void 
PutBits( 
    BitCursor* B, // Address of a valid BitCursor record that
                  // refers to the next bit to be written.
                  //
    u32 BitCount, // Number of bits to store, up to 64.
                  //
    u64 Value )   // The bits to be stored, low-order bit will
                  // be stored last.
{
    u8   A;
    u64  AtBitInValue;
    u8*  AtByte;
    u8   AtBit;
    u8   IsLowBitFirst;
    
    // Get local copies of the cursor fields.
    AtByte        = B->AtByte;
    AtBit         = B->AtBit;
    IsLowBitFirst = B->IsLowBitFirst;
    
    // Refer to the first bit to store.
    AtBitInValue = ((u64) 1) << ( BitCount - 1 );
    
    // Fetch the first byte to 'A'.
    A = *AtByte;
        
    // If the low-order bit of a byte is first.
    if( IsLowBitFirst )
    {
        // Until all bits are stored.
        while( BitCount-- )
        {
            // If the indexed value bit is '1'.
            if( Value & AtBitInValue )
            {
                // Move a '1' into the target byte.
                A = A | AtBit;
            }
            else
            {
                // Put a '0' in the target byt.
                A = A & (~AtBit);
            }
            
            // Refer to the next source bit.
            AtBitInValue = AtBitInValue >> 1;
            
            // Refer to the next target bit.
            AtBit = AtBit << 1;
            
            // If the next target byte is needed.
            if( AtBit == 0 )
            {
                // Put the byte back.
                *AtByte = A;
                
                // Advance the byte address.
                AtByte++;
                
                // Get the byte.
                A = *AtByte;
                
                // Set the bit-in-byte mask to the first bit 
                // in the byte, the lowest one in this case.
                AtBit = 1;
            }
        }
    }
    else // High-order bit in a byte is regarded as
         // first.
    {
        // Until all bits are stored.
        while( BitCount-- )
        {
            // If the indexed value bit is '1'.
            if( Value & AtBitInValue )
            {
                // Move a '1' into the target byte.
                A = A | AtBit;
            }
            else
            {
                // Put a '0' in the target byt.
                A = A & (~AtBit);
            }
            
            // Refer to the next source bit.
            AtBitInValue = AtBitInValue >> 1;
            
            // Refer to the next target bit.
            AtBit = AtBit >> 1;
            
            // If the next target byte is needed.
            if( AtBit == 0 )
            {
                // Put the byte back.
                *AtByte = A;
                
                // Advance the byte address.
                AtByte++;
                
                // Get the byte.
                A = *AtByte;
                
                // Set the bit-in-byte mask to the first bit 
                // in the byte, the highest one in this case.
                AtBit = 128;
            }
        }
    }
    
    // Put the byte back.
    *AtByte = A;    
    
    // Update the cursor record.
    B->AtByte = AtByte;
    B->AtBit  = AtBit;
}

/*------------------------------------------------------------
| ReferToFirstBit
|-------------------------------------------------------------
|
| PURPOSE: To configure a bit cursor to refer to the first 
|          bit at a byte address.
|
| DESCRIPTION:
|
| EXAMPLE:  ReferToFirstBit( &B, AtByte, 1 );
|
| ASSUMES: 
|
| HISTORY: 04.04.00
------------------------------------------------------------*/
void  
ReferToFirstBit( 
    BitCursor*  B,  
                // Address of a BitCursor record to be set up.
                //
    u8*         AtByte,
                // Address of the byte containing the bit
                // of interest.
                //
    u32         IsLowBitFirst )
                // A flag equal to 1 if the first bit is the
                // least-significant-bit or 0 if the most-
                // significant-bit is first.
{
    // Save the byte address in the bit cursor record.
    B->AtByte = AtByte;
     
    // Save the orientation flag in the bit cursor record.
    B->IsLowBitFirst = IsLowBitFirst;
    
    // If the low bit is first.
    if( IsLowBitFirst )
    {
        // Set the bit mask to refer to the least-significant-
        // bit of the byte.
        B->AtBit = 1;
    }
    else // The most-significant bit is first.
    {
        // Set the bit mask to refer to the most-significant-
        // bit of the byte.
        B->AtBit = 128;
    }
}
