/*------------------------------------------------------------
| TLBytes.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide byte-addressed memory access functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 02.03.93 from Bytes.txt.
|          08.28.93 converted to new-style declarations
|          01.12.94 added IsByteInBytes
|          01.20.94 added 'ReplaceRangeInBuffer'
|          05.29.01 moved less commonly used functions to
|                   TLBytesExtra.c.
|          06.06.01 Moved Adler32() here from TLBytesExtra.h.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include "NumTypes.h"

#include "TLBytes.h"

#ifndef min
#define min(x,y)      ((x)>(y)?(y):(x))
#endif

/*------------------------------------------------------------
| Adler32
|-------------------------------------------------------------
|
| PURPOSE: To compute the Adler-32 checksum of a data stream.
|
| DESCRIPTION: An Adler-32 checksum is almost as reliable as 
| a CRC32 but can be computed much faster. 
|
| Always use 1 as the initial value.
|
| EXAMPLE:
|   
|    u32 adler = 1;
|
|    while( read_buffer(buffer, length ) != EOF ) 
|    {
|       adler = Adler32( buffer, length, adler );
|    }
|     
|    if( adler != original_adler) error();
|
| NOTE: This function is defined by the RFC 1950 standard.
|
| HISTORY: 01.10.99 From 'adler32()' of the 'zlib 1.1.3'
|                   release, by Mark Adler.  Preprocessed,
|                   reformatted and sped up.
|          06.06.01 Added parameter comments.
------------------------------------------------------------*/
u32
Adler32( u8* buf, 
                // Buffer address.
                //
         u32 HowManyBytes, 
                // Size of buffer in bytes.
                //
         u32 adler )
                // Cumulative Adler32 checksum computed so 
                // far.
                //
                // Always use 1 as the initial value.
{
    s16 HowManyThisPass;
    u32 s1;
    u32 s2;
    
    // Separate the check sum into two 16-bit parts and put
    // them into 32-bit variables.
    s1 = adler & 0xFFFF;
    s2 = (adler >> 16) & 0xFFFF;
 
    // Until all of the input has been processed.
    while( HowManyBytes )
    {
        // Calculate how many bytes to process on this pass
        // so that the 32-bit accumulators don't overflow:
        //
        //  65521 is the largest prime smaller than 65536.
        //  5552 is the largest n such that 
        //  255n (n+1)/2 + (n+1)(65520) <= 2^32-1.
        //
        HowManyThisPass = (s16) min( HowManyBytes, 5552 );      
        
        // Account for the bytes to be processed on this pass.
        HowManyBytes -= HowManyThisPass;
        
        // As long as 16 or more bytes remain to be 
        // processed on this pass.
        while( HowManyThisPass >= 16 ) 
        {
            // Sum the input bytes in 's1' and sum the
            // running 's1' values in 's2'.
            s1 += *buf++; s2 += s1; 
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            s1 += *buf++; s2 += s1;
            
            // Account for the bytes processed.
            HowManyThisPass -= 16;
        }
        
        // As long as any bytes remain to be processed.
        while( HowManyThisPass-- ) 
        {
            // Sum the input bytes in 's1' and sum the
            // running 's1' values in 's2'.
            s1 += *buf++; s2 += s1;
        } 
        
        // Compute the remainder mod 65521 of each
        // accumulator: 65521 is the largest 
        // prime smaller than 65536.
        s1 %= 65521L;
        s2 %= 65521L;
    }

    // Merge the two accumulators and return the result.
    return( (s2 << 16) | s1 );
}

/*------------------------------------------------------------
| CompareAddresses
|-------------------------------------------------------------
|
| PURPOSE: To compare two addresses.
|
| DESCRIPTION: Comparison operation.
|              Returns: 0 if address A = address B.
|                       positive number if A > B.
|                       negative number if A < B.
|
| EXAMPLE:  Result = CompareAddresses( A, B );
|
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.16.96 
------------------------------------------------------------*/
s32
CompareAddresses( s8* A, s8* B )
{
    return( (s32) ((s32) A) - ((s32) B) );
}

/*------------------------------------------------------------
| CompareBytes
|-------------------------------------------------------------
|
| PURPOSE: To compare two ranges of bytes based on their 
|          unsigned numeric ordering.
|
| DESCRIPTION: Comparison operation.
|
|              Returns: 0 if record A = record B.
|                       positive number if A > B.
|                       negative number if A < B.
|
| EXAMPLE:  Result = CompareBytes( A, ACount, B, BCount );
|
|
| NOTE: If both byte ranges match over the length of the 
|       shorter range, then the longer range follows the
|       shorter in terms of order.
|
| ASSUMES: 
|
| HISTORY:  09.19.89  
|           02.15.93 changed count to quad.
|           11.10.93 simplified logic.
|           03.01.99 Sped up.
------------------------------------------------------------*/
s32
CompareBytes( u8* A,
              u32 ACount, 
              u8* B, 
              u32 BCount )
{
    u32 MinSize;
    s32 C;
    
    // If the blocks start at the same place.
    if( A == B )
    {
        // Compare the lengths of the blocks.
        return( (s32) ACount - (s32) BCount ); 
    }
    
    // Calculate the size of the smaller block.
    MinSize = ACount;
    
    if( BCount < MinSize ) 
    {
        MinSize = BCount;
    }
    
    // If the A block is quad-aligned.
    if( ( ((u32) A) & 3 ) == 0 )
    {
        // If the B block is quad-aligned.
        if( ( ((u32) B) & 3 ) == 0 )
        {
            // If there are four or more bytes to compare.
            while( MinSize >= 4 )
            {
                // If the quads match.
                if( *( (u32*) A ) == *( (u32*) B ) )
                {
                    // Advance to the next quad.
                    A += 4;
                    B += 4;
                    
                    // Account for the bytes compared.
                    MinSize -= 4;
                }
                else // Mismatch found.
                {
                    // Handle the mismatch below.
                    break;
                }
            }
            
            // If the intersecting extent matches.
            if( MinSize == 0 )
            {
                // Compare the lengths of the blocks.
                return( (s32) ACount - (s32) BCount ); 
            }
        }
    }
    
    // While there are more bytes to compare.
    while( MinSize-- )
    {
        // Calculate the comparison.
        C = ( (s32) *A++ ) - ( (s32) *B++ );

        // If there is a difference.
        if( C )
        {
            // Return the difference.
            return( C );
        }
    }
    
    // The intersecting extent matches.
    //
    // Compare the lengths of the blocks.
    return( (s32) ACount - (s32) BCount ); 
}

/*------------------------------------------------------------
| CopyBytes
|-------------------------------------------------------------
|
| PURPOSE: To copy a range of bytes from one place to another.
|
| DESCRIPTION: Correctly handles overlapping series of bytes. 
|
| EXAMPLE:  CopyBytes( From, To, (u32) 5 );
|
| NOTE: The ROM-resident 'BlockMoveData' function is tuned to
| the processor and is very fast.  
|
| On the 8100/80 'BlockMoveData' uses an instruction to clear 
| and create cache line blocks for target bytes without 
| having to read them from RAM: this can be a very big time 
| savings when moving large blocks of memory.
|
| There is room to optimize 'BlockMoveData' for the 8100/80,
| specifically mis-alignment and using floating point loads,
| but using the cache clearing technique isn't portable to 
| other PowerPC chips because the cache block sizes may be 
| different.  There's a way to identify the CPU version when
| running in supervisor mode by reading a special register,
| but that register is inaccessible in user mode.  Probably
| there's a system call to find out the CPU so that later
| I can write special 'CopyBytes' routines tuned to each
| chip and configured at run-time.
|
| ASSUMES: The data being moved doesn't contain 68K instructions:
|          see Technote 1008 which talks about 'BlockMove' on
|          PCI PowerMacs.
|
| HISTORY: 08.25.89 
|          08.31.89 added overlapping capability
|          02.03.93 assembler version derived from Forthmacs 
|                   via AM.
|          09.22.93 replaced stack relative argument 
|                   addresses with names
|          11.01.93 assembler version replaced with general 
|                   'C' version.
|                   See 'FastBytes.c' for assembler version.
|          11.23.97 superceded with ROM-resident 'BlockMove'
|                   which is tuned to the processor.
|          12.02.97 superceded with ROM-resident 'BlockMoveData'
|                   which is faster than 'BlockMove' but can't
|                   be used to move 68K instructions.
------------------------------------------------------------*/
#ifndef CopyBytes
void
CopyBytes( u8* From, u8* To, u32 Count )
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
#endif

/*------------------------------------------------------------
| CountBytes
|-------------------------------------------------------------
|
| PURPOSE: To count how many times each byte pattern occurs
|          in a buffer.
|
| DESCRIPTION: Expects a buffer, count and reference to
| an array of 256 u32's, which will hold the result. 
|
| EXAMPLE: 
|
|
| NOTE: 
|
| ASSUMES: Buffer at 'Counts' is at least 1024 bytes long.
|
| HISTORY:  07.04.96
|           02.20.99 Sped up by 38%.
|           02.21.99 Validated.
|           05.29.01 Replaced memset with FillBytes.
------------------------------------------------------------*/
void
CountBytes( u8* Buf, u32 Count, u32* Counts )
{
    u32  a, b, c, d, e, f, u, v;
    u32* B;
    
    // Clear the count array.
    FillBytes( (u8*) Counts, 1024, 0 );
    
    // Refer to the buffer as u32's.
    B = (u32*) Buf;
    
    // While there are more than eight bytes left to count.
    while( Count > 8 )
    {
        // Get four bytes at a time.
        u = *B++;
        
        // Get four bytes at a time.
        v = *B++;
        
        // Unpack the number into bytes: if there are 
        // multiple integer units this sequence may be
        // done in parallel.
        a = u & 0xff; 
        b = v & 0xff;
        
        u >>= 8;
        v >>= 8;
        
        c = u & 0xff; 
        d = v & 0xff; 
        
        u >>= 8;
        v >>= 8;
        
        e = u & 0xff; 
        f = v & 0xff; 
        
        u >>= 8;
        v >>= 8;

        // Count the 8 bytes.
        Counts[ a ]++;
        Counts[ b ]++;
        Counts[ c ]++;
        Counts[ d ]++;
        Counts[ e ]++;
        Counts[ f ]++;
        Counts[ u ]++;
        Counts[ v ]++;
        
        // Account for the bytes just counted.
        Count -= 8;
    }
    
    // Refer to the remainder.
    Buf = (u8*) B;
    
    // While there are any other left over bytes.
    while( Count-- )
    {
        // Count the bytes.
        Counts[ *Buf++ ]++;
    }
}

/*------------------------------------------------------------
| ExchangeByte
|-------------------------------------------------------------
|
| PURPOSE: To exchange a byte value with a byte in memory.
|
| DESCRIPTION: Returns the value in the memory and puts a
| new value there.  This is an atomic operation with repect
| to memory and all other processors. 
|
| EXAMPLE:    v = ExchangeByte( AtByteInMemory, 5 );
|
| NOTE:  
|
| ASSUMES: This procedure is atomic.
|
| HISTORY: 05.29.00
------------------------------------------------------------*/
u32             // OUT: The value from memory.
ExchangeByte( 
    u8* A,      // Address of a byte in memory.
                //
    u32 b )     // Byte value to be put at the address.
{
    u8  r;
    
#if defined( __INTEL__ ) || defined( _M_IX86 )
    __asm
    {
        // Move the value 'b' to register EAX.
        mov eax, b

        // Exchange the byte at 'A' with the value in AL.
        //
        // NOTE: This is a bus locking instruction.
        xchg byte ptr A, al 
        
        // Move the result to r.
        mov r, al
    }
#else
        r = *A;
        
        *A = (u8) b;
#endif
    
    // Return the resulting byte in a 32-byte value.
    return( (u32) r );
}

/*------------------------------------------------------------
| ExchangeBytes
|-------------------------------------------------------------
|
| PURPOSE: To exchange the values in two non-overlapping 
|          ranges of bytes.
|
| DESCRIPTION:  
|
| EXAMPLE:  ExchangeBytes( SourceA, SourceB, Count );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 12.01.90 Create  from AM.
|          09.19.91 revised for Focus.
|          02.03.93 revised for WM.
------------------------------------------------------------*/
void
ExchangeBytes( u8* SourceA, 
               u8* SourceB, 
               u32          Count )
{
    u8    AByte;
    
    while( Count-- )
    {
        AByte    = *SourceA;
        *SourceA = *SourceB;
        *SourceB = AByte;
        SourceA++;
        SourceB++;
    }
}

/*------------------------------------------------------------
| FillBytes
|-------------------------------------------------------------
|
| PURPOSE: To fill a range of bytes with a byte value.
|
| DESCRIPTION:  
|
| EXAMPLE:  FillBytes( Destination, ByteCount, ByteValue );
|
| NOTE: 'u16' used as argument instead of 'u8' because
|       Think C can't pass 'u8' arguments properly. See
|       'TLTypes.h' for more.
|
| ASSUMES: 
|
| HISTORY: 08.25.89 
|          11.10.93 changed argument types to 'u16'.
|          01.22.97 changed 'ByteValue' to 'u32'.
------------------------------------------------------------*/
void
FillBytes( u8* Destination, u32 ByteCount, u32 ByteValue )
{
    while( ByteCount-- )
    {
        *Destination++ = (u8) ByteValue;
    }
}

/*------------------------------------------------------------
| IsByteInBytes
|-------------------------------------------------------------
|
| PURPOSE: To test if a byte value exists in a buffer.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| IsIt = IsByteInBytes( AddrOfBytes, ByteCount, ByteValue );
|
| HISTORY: 01.12.94 
|          08.19.01 Revised to clarify operation; changed size
|                   of ByteValue parameter from u16 to u32.
------------------------------------------------------------*/
u32         // OUT: 1 if byte is found in bytes or 0 if not.
IsByteInBytes( 
    u8*  AtBytes, 
            // The buffer containing the bytes to scan.
            //
    u32  ByteCount, 
            // Number of bytes in the buffer.
            //
    u32  Value )
            // The byte value to look for.
{
    // Scan each byte in the buffer.
    while( ByteCount-- )
    {
        // If the value is found in the buffer.
        if( *AtBytes == Value ) 
        {
            // Return 1 to indicate that the value was found.
            return(1);
        }
        
        // Advance to the next character in the buffer.
        AtBytes++;
    }
    
    // Return 0 to indicate that the value was not found in
    // the buffer.
    return(0);
}

/*------------------------------------------------------------
| IsMatchingBytes
|-------------------------------------------------------------
|
| PURPOSE: To tell if two ranges of bytes match in value.
|
| DESCRIPTION: Returns '1' if they match, else '0'. 
|
| EXAMPLE:  
|
|    Result = IsMatchingBytes( SomeBytes, OtherBytes, 10 );
|
| HISTORY: 10.21.89
|          02.15.93 changed count to quad.
|          03.03.99 Sped up.
|          06.16.01 Added test for quad alignment before
|                   using quad comparisons and added middle
|                   byte comparison test.
------------------------------------------------------------*/
u32
IsMatchingBytes( u8* A, u8* B, u32 Count )
{
    u32 m;
    
    // Calculate the index of the middle byte of the key.
    m = Count >> 1;
    
    // If the middle byte of the keys differ: this generally
    // improves performance.
    if( A[ m ] != B[ m ] )
    {
        // Return a mismatch.
        return( 0 );
    }
    
    // If the blocks start at the same place.
    if( A == B )
    {
        // Then they match.
        return( 1 ); 
    }
    
    // If the A block is quad-aligned.
    if( ( ((u32) A) & 3 ) == 0 )
    {
        // If the B block is quad-aligned.
        if( ( ((u32) B) & 3 ) == 0 )
        {
            // If there are four or more bytes to compare.
            while( Count >= 4 )
            {
                // If the quads don't match.
                if( *( (u32*) A ) != *( (u32*) B ) )
                {
                    // Return a mismatch.
                    return( 0 );
                }
                else // The quads match.
                {
                    // Advance to the next quad.
                    A += 4;
                    B += 4;
                    
                    // Account for the bytes compared.
                    Count -= 4;
                }
            }
        }
    }
    
    // While there are more bytes to compare.
    while( Count-- )
    {
        // If the bytes differ.
        if( *A++ != *B++ )
        {
            // Return a mismatch.
            return( 0 );
        }
    }
    
    // Return a match.
    return( 1 );         
}

#ifdef FOR_INTEL

/*------------------------------------------------------------
| LockByte
|-------------------------------------------------------------
|
| PURPOSE: To use any byte to control access to a resource.
|
| DESCRIPTION: On return from this procedure the byte is 
|              locked.
|
| EXAMPLE: 
|
|          u8 a;
|
|          LockByte( &a );
|
|          <code here>
|
|          UnlockByte( &a );
|
| ASSUMES: 'xchg' is an atomic operation with respect
|          to all processors and memory.
|
|          OK to stay in tight loop while waiting on byte to
|          become zero.
|
|          If a lock is locked by someone it will always be
|          unlocked without wasting time holding the lock to
|          no purpose.
|
| HISTORY: 05.29.00
------------------------------------------------------------*/
                     // Disable generation of standard entry
__declspec(naked)    // and exit code.
void
LockByte( u8* AddressOfByte )
{
    __asm
    {
        push esi               // Preserve ESI register.
                               //
        mov  esi, dword ptr [esp+8]
                               // Move the address to ESI.
                               //
///////////                    //
TryAgain://                    //
///////////                    //
                               //
        mov  al, 1             // Put a one into the AL 
                               // register.
                               //
        xchg al, byte ptr [esi]// Exchange the 1 in AL with 
                               // the lock byte at address 
                               // 'a'.
                               //
                               // The 'xchg' operation locks the
                               // bus and synchronizes the
                               // processor.
                               //
                               // This instruction fetches the
                               // lock byte and sets the lock
                               // byte to 1 while excluding all
                               // other processes and devices.
                               //
        cmp  al, 0             // Test the previous lock state.
                               //
        jne  WaitTop           // If the lock is held by someone
                               // else go to the wait loop.
                               //
        pop esi                // Otherwise the lock has been
                               // acquired: clean up and return.
        ret                    //
                               //
//////////                     //
WaitTop://                     //
//////////                     //
                               // Start waiting for the lock to
        mov  al, byte ptr [esi]// to be released.  Use the 'mov'
                               // instruction instead of 'xchg'
                               // to avoid needless locking and
                               // processor syncing.
                               //
        cmp  al, 0             // Test the lock state.
                               //
        jne  WaitTop           // If the lock is held by someone
                               // keep waiting.
                               //
        jmp TryAgain           // Otherwise, attempt to lock 
                               // again.
     
     }
    
    // Do something with address to avoid compiler warning.
    AddressOfByte = AddressOfByte;
}

#endif FOR_INTEL

/*------------------------------------------------------------
| ReadBytePort
|-------------------------------------------------------------
|
| PURPOSE: To read a hardware port on Intel machine.
|
| DESCRIPTION:  
|
|  
|
| The result is a 64-bit number.
|
| EXAMPLE: 
|
|       u64 t;
|
|       t = ReadPort( 0x3f );
|
| NOTE: This will NOT work on NT in User Mode.
|
| ASSUMES: Direct access to machine is not disabled.
|
| HISTORY: 05.01.00
|         
------------------------------------------------------------*/
u32
ReadBytePort( u32 PortAddress )
{
    u16 a;
    u8  b;
    
    a = (u16) PortAddress;
    
    // For Intel processors.
#if defined( __INTEL__ ) || defined( _M_IX86 )
    
    __asm
    {
        mov   dx, a
        in    al, dx
        mov   b, al
    }
#else // Not Intel.
    b = 0;
#endif
    
    return( (u32) b );
}
   
/*------------------------------------------------------------
| ReplaceBytes
|-------------------------------------------------------------
|
| PURPOSE: To replace all occurances of a byte in a range of 
|          bytes.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|            ReplaceBytes( TokenBuffer, (u32) 100, 
|                          (u16) 'a', (u16) 'A' );
|
| NOTE: 'u16' used as parameters instead of 'u8' because
|       Think C can't pass 'u8' arguments properly. See
|       'TLTypes.h' for more.
|
| ASSUMES: 
|
| HISTORY: 04.04.91 
|          11.10.93 changed argument types to 'u16'.
------------------------------------------------------------*/
void
ReplaceBytes( u8*   BaseAddress, 
              u32   Count, 
              u16   FindByte, 
              u16   ReplaceWithByte )
{
    while(Count--)
    {
        if( *BaseAddress == (u8) FindByte ) 
        {
            *BaseAddress = (u8) ReplaceWithByte;
        }
        BaseAddress++;
    }
}

#ifdef FOR_INTEL
 
/*------------------------------------------------------------
| UnlockByte
|-------------------------------------------------------------
|
| PURPOSE: To release a byte lock.
|
| DESCRIPTION: Given a locked byte, this procedure unlocks
| it.
|
| EXAMPLE: 
|                   u8  a;
|    
|                   UnlockByte( &a );
|
| ASSUMES: 'xchg' is an atomic operation with respect
|          to all processors and memory.
|
|          The caller currently holds the lock.
|
| HISTORY: 05.29.00
------------------------------------------------------------*/
                     // Disable generation of standard entry
__declspec(naked)    // and exit code.
void
UnlockByte( u8* AddressOfByte )
{
    __asm
    {
        push esi               // Preserve ESI register.
                               //
        mov  esi, dword ptr [esp+8]
                               // Move the address to ESI.
                               //
        mov  al, 0             // Put a zero into the AL 
                               // register.
                               //
        xchg al, byte ptr [esi]// Exchange the 0 in AL with 
                               // the lock byte at address 
                               // 'a'.
                               //
                               // The 'xchg' operation locks 
                               // the bus and synchronizes 
                               // the processor.
                               //
                               // This instruction fetches the
                               // lock byte and sets the lock
                               // byte to 0 while excluding all
                               // other processes and devices.
                               //
        pop esi                // The lock has been released: 
                               // clean up and return.
        ret                    //
    }
    
    // Do something with address to avoid compiler warning.
    AddressOfByte = AddressOfByte;
}

#endif FOR_INTEL
 
/*------------------------------------------------------------
| ZeroBytes
|-------------------------------------------------------------
|
| PURPOSE: To fill a buffer with zeros.
|
| DESCRIPTION: If memset is available it will be faster than
| this procedure.
|
| EXAMPLE:  ZeroBytes( Destination, ByteCount );
|
| HISTORY: 05.29.01 TL
------------------------------------------------------------*/
void
ZeroBytes( u8* Destination, u32 ByteCount )
{
    while( ByteCount-- )
    {
        *Destination++ = 0;
    }
}

