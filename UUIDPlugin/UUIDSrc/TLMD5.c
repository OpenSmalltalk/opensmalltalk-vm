/*------------------------------------------------------------
| TLMD5.c
|-------------------------------------------------------------
|
| PURPOSE: To supply MD5 message-digest functions.
|
| DESCRIPTION: "This code implements the MD5 message-digest 
| algorithm. The algorithm is due to Ron Rivest.  This code 
| was written by Colin Plumb in 1993, no copyright is 
| claimed.
|
| This code is in the public domain; do with it what you 
| wish.
|
| Equivalent code is available from RSA Data Security, Inc.
| This code has been tested against that, and is equivalent.
|
| To compute the message digest of a chunk of bytes, declare 
| an MD5Context structure, pass it to MD5Init, call MD5Update 
| as needed on buffers full of bytes, and then call MD5Final, 
| which will fill a supplied 16-byte array with the digest."
|        
| NOTE: See RFC1321 for the MD5 specification.
|
| HISTORY: 01.14.99 From 'http://ftp.sunet.se/ftp/pub/
|                         security/tools/crypt/md5sum/md5.c'.
|                   Revised to use run-time determined 
|                   packing order.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdio.h>
#include <string.h>             // for memcpy()

#include "TLTypes.h"
#include "TLPacking.h"
#include "TLMD5.h"

u32     MD5RelativePackingOrder;
        // The packing order of the currently running 
        // machine relative to the machine for which this 
        // MD5 algorithm was designed.
        
// The four core functions - F1 is optimized somewhat.

// #define F1(x, y, z) (x & y | ~x & z) */
#define F1(x, y, z) (z ^ (x & (y ^ z)))
#define F2(x, y, z) F1(z, x, y)
#define F3(x, y, z) (x ^ y ^ z)
#define F4(x, y, z) (y ^ (x | ~z))

// This is the central step in the MD5 algorithm.
#define MD5STEP(f, w, x, y, z, data, s) \
        ( w += f(x, y, z) + data,  w = w<<s | w>>(32-s),  w += x )


/*------------------------------------------------------------
| MD5Final
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION: Final wrapup - pad to 64-byte boundary with 
| the bit pattern 1 0* (64-bit count of bits processed, 
| MSB-first)
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99
------------------------------------------------------------*/
void 
MD5Final( MD5Context* C, u8* digest )
{
    u32 count;
    u8* p;

    // Compute number of bytes mod 64.
    count = (C->bits[0] >> 3) & 0x3F;

    // Set the first char of padding to 0x80.  This is safe 
    // since there is always at least one byte free.
    p = C->in + count;
    
    *p++ = 0x80;

    // Bytes of padding needed to make 64 bytes.
    count = 64 - 1 - count;

    // Pad out to 56 mod 64.
    if( count < 8 ) 
    {
        // Two lots of padding:  Pad the first block to 64 
        // bytes.
        memset( p, 0, count );
        
        RepackQuads( 
            MD5RelativePackingOrder, 
            (u32*) C->in, 
            (u32*) C->in, 
            16 );
        
        MD5Transform( C->buf, (u32*) C->in );

        // Now fill the next block with 56 bytes.
        memset( C->in, 0, 56 );
    } 
    else 
    {
        // Pad block to 56 bytes.
        memset( p, 0, count - 8 );
    }
    
    RepackQuads( 
        MD5RelativePackingOrder, 
        (u32*) C->in, 
        (u32*) C->in, 
        14 );

    // Append length in bits and transform.
    ((u32 *) C->in)[14] = C->bits[0];
    ((u32 *) C->in)[15] = C->bits[1];

    MD5Transform( C->buf, (u32*) C->in );
    
    RepackQuads( 
        MD5RelativePackingOrder, 
        (u32*) C->buf, 
        (u32*) C->buf, 
        4 );
    
    memcpy(digest, C->buf, 16);
    
    // In case it's sensitive.
    memset( C, 0, sizeof(C) ); 
}


/*------------------------------------------------------------
| MD5Init
|-------------------------------------------------------------
|
| PURPOSE: To start MD5 accumulation. 
|
| DESCRIPTION: Set bit count to 0 and buffer to mysterious
| initialization constants.  
|
| Also identifies the binary packing order of the currently 
| running computer so that 32-bit numbers can be repacked
| to suit this implementation of the MD5 algorithm.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99 Added 'IdentifyThePackingOrder()'.
------------------------------------------------------------*/
void 
MD5Init( MD5Context* C )
{
    // Determine the binary packing order for the currently
    // running CPU.
    IdentifyThePackingOrder();

    // Calculate the packing order relative to the machine
    // for which the code was originally written, an 
    // 'SSSSS' machine.
    MD5RelativePackingOrder = ThePackingOrder ^ SSSSS; 
        
    C->buf[0] = 0x67452301;
    C->buf[1] = 0xefcdab89;
    C->buf[2] = 0x98badcfe;
    C->buf[3] = 0x10325476;

    C->bits[0] = 0;
    C->bits[1] = 0;
}


/*------------------------------------------------------------
| MD5Print
|-------------------------------------------------------------
|
| PURPOSE: To print a message digest in hexadecimal.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99 From 'MDPrint()' in RFC1321.
------------------------------------------------------------*/
void 

MD5Print( u8* digest )
{
    u32 i;

    for( i = 0; i < 16; i++ )

    {
        printf( "%02x", digest[i] );

    }
}

/*------------------------------------------------------------
| MD5String
|-------------------------------------------------------------
|
| PURPOSE: To digest a string and prints the result.
|
| DESCRIPTION:
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99 From 'MDString()' in RFC1321.
------------------------------------------------------------*/
void 

MD5String( s8* string )
{
    MD5Context  context;
    u8          digest[16];
    u32         len;

    len = strlen (string);

    MD5Init( &context );
    MD5Update( &context, (u8*) string, len );
    MD5Final( &context, digest );

    printf("MD5( \"%s\" ) = ", string);
  
    MD5Print( digest );
  
    printf("\n");
}

/*------------------------------------------------------------
| MD5TestSuite
|-------------------------------------------------------------
|
| PURPOSE: To digest a reference suite of strings and print 
|          the results.
|
| DESCRIPTION: This procedure should produce the following
| results:
|
|  MD5 test suite:
|  MD5 ("") = d41d8cd98f00b204e9800998ecf8427e
|  MD5 ("a") = 0cc175b9c0f1b6a831c399e269772661
|  MD5 ("abc") = 900150983cd24fb0d6963f7d28e17f72
|  MD5 ("message digest") = f96b697d7cb7938d525a2f31aaf161d0
|  MD5 ("abcdefghijklmnopqrstuvwxyz") = c3fcd3d76192e4007dfb496cca67e13b
|  MD5 ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") =
|  d174ab98d277d9f5a5611c2c9f419d9f
|  MD5 ("123456789012345678901234567890123456789012345678901234567890123456
|  78901234567890") = 57edf4a22be3c955ac49da2e2107b67a
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99 From 'MDTestSuite()' in RFC1321. 
|                   Tested OK on both Mac and NT.
------------------------------------------------------------*/
void 
MD5TestSuite()
{
    printf ( "MD5 test suite:\n" );

    MD5String( "" );
    MD5String( "a" );
    MD5String( "abc" );
    MD5String( "message digest" );
    MD5String( "abcdefghijklmnopqrstuvwxyz" );
    MD5String( "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
               "abcdefghijklmnopqrstuvwxyz0123456789" );
    MD5String( "123456789012345678901234567890"
               "123456789012345678901234567890"
               "12345678901234567890" );
}

/*------------------------------------------------------------
| MD5Transform
|-------------------------------------------------------------
|
| PURPOSE: To alter an existing MD5 hash to reflect the 
|          addition of 16 longwords of new data.
|
| DESCRIPTION: This is the core of the MD5 algorithm.
| MD5Update blocks the data and converts bytes into u32's 
| for this routine.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99
------------------------------------------------------------*/
void 

MD5Transform( u32* buf, u32* in )
{
    u32 a, b, c, d;

    a = buf[0];
    b = buf[1];
    c = buf[2];
    d = buf[3];

    MD5STEP(F1, a, b, c, d, in[0] + 0xd76aa478, 7);
    MD5STEP(F1, d, a, b, c, in[1] + 0xe8c7b756, 12);
    MD5STEP(F1, c, d, a, b, in[2] + 0x242070db, 17);
    MD5STEP(F1, b, c, d, a, in[3] + 0xc1bdceee, 22);
    MD5STEP(F1, a, b, c, d, in[4] + 0xf57c0faf, 7);
    MD5STEP(F1, d, a, b, c, in[5] + 0x4787c62a, 12);
    MD5STEP(F1, c, d, a, b, in[6] + 0xa8304613, 17);
    MD5STEP(F1, b, c, d, a, in[7] + 0xfd469501, 22);
    MD5STEP(F1, a, b, c, d, in[8] + 0x698098d8, 7);
    MD5STEP(F1, d, a, b, c, in[9] + 0x8b44f7af, 12);
    MD5STEP(F1, c, d, a, b, in[10] + 0xffff5bb1, 17);
    MD5STEP(F1, b, c, d, a, in[11] + 0x895cd7be, 22);
    MD5STEP(F1, a, b, c, d, in[12] + 0x6b901122, 7);
    MD5STEP(F1, d, a, b, c, in[13] + 0xfd987193, 12);
    MD5STEP(F1, c, d, a, b, in[14] + 0xa679438e, 17);
    MD5STEP(F1, b, c, d, a, in[15] + 0x49b40821, 22);

    MD5STEP(F2, a, b, c, d, in[1] + 0xf61e2562, 5);
    MD5STEP(F2, d, a, b, c, in[6] + 0xc040b340, 9);
    MD5STEP(F2, c, d, a, b, in[11] + 0x265e5a51, 14);
    MD5STEP(F2, b, c, d, a, in[0] + 0xe9b6c7aa, 20);
    MD5STEP(F2, a, b, c, d, in[5] + 0xd62f105d, 5);
    MD5STEP(F2, d, a, b, c, in[10] + 0x02441453, 9);
    MD5STEP(F2, c, d, a, b, in[15] + 0xd8a1e681, 14);
    MD5STEP(F2, b, c, d, a, in[4] + 0xe7d3fbc8, 20);
    MD5STEP(F2, a, b, c, d, in[9] + 0x21e1cde6, 5);
    MD5STEP(F2, d, a, b, c, in[14] + 0xc33707d6, 9);
    MD5STEP(F2, c, d, a, b, in[3] + 0xf4d50d87, 14);
    MD5STEP(F2, b, c, d, a, in[8] + 0x455a14ed, 20);
    MD5STEP(F2, a, b, c, d, in[13] + 0xa9e3e905, 5);
    MD5STEP(F2, d, a, b, c, in[2] + 0xfcefa3f8, 9);
    MD5STEP(F2, c, d, a, b, in[7] + 0x676f02d9, 14);
    MD5STEP(F2, b, c, d, a, in[12] + 0x8d2a4c8a, 20);

    MD5STEP(F3, a, b, c, d, in[5] + 0xfffa3942, 4);
    MD5STEP(F3, d, a, b, c, in[8] + 0x8771f681, 11);
    MD5STEP(F3, c, d, a, b, in[11] + 0x6d9d6122, 16);
    MD5STEP(F3, b, c, d, a, in[14] + 0xfde5380c, 23);
    MD5STEP(F3, a, b, c, d, in[1] + 0xa4beea44, 4);
    MD5STEP(F3, d, a, b, c, in[4] + 0x4bdecfa9, 11);
    MD5STEP(F3, c, d, a, b, in[7] + 0xf6bb4b60, 16);
    MD5STEP(F3, b, c, d, a, in[10] + 0xbebfbc70, 23);
    MD5STEP(F3, a, b, c, d, in[13] + 0x289b7ec6, 4);
    MD5STEP(F3, d, a, b, c, in[0] + 0xeaa127fa, 11);
    MD5STEP(F3, c, d, a, b, in[3] + 0xd4ef3085, 16);
    MD5STEP(F3, b, c, d, a, in[6] + 0x04881d05, 23);
    MD5STEP(F3, a, b, c, d, in[9] + 0xd9d4d039, 4);
    MD5STEP(F3, d, a, b, c, in[12] + 0xe6db99e5, 11);
    MD5STEP(F3, c, d, a, b, in[15] + 0x1fa27cf8, 16);
    MD5STEP(F3, b, c, d, a, in[2] + 0xc4ac5665, 23);

    MD5STEP(F4, a, b, c, d, in[0] + 0xf4292244, 6);
    MD5STEP(F4, d, a, b, c, in[7] + 0x432aff97, 10);
    MD5STEP(F4, c, d, a, b, in[14] + 0xab9423a7, 15);
    MD5STEP(F4, b, c, d, a, in[5] + 0xfc93a039, 21);
    MD5STEP(F4, a, b, c, d, in[12] + 0x655b59c3, 6);
    MD5STEP(F4, d, a, b, c, in[3] + 0x8f0ccc92, 10);
    MD5STEP(F4, c, d, a, b, in[10] + 0xffeff47d, 15);
    MD5STEP(F4, b, c, d, a, in[1] + 0x85845dd1, 21);
    MD5STEP(F4, a, b, c, d, in[8] + 0x6fa87e4f, 6);
    MD5STEP(F4, d, a, b, c, in[15] + 0xfe2ce6e0, 10);
    MD5STEP(F4, c, d, a, b, in[6] + 0xa3014314, 15);
    MD5STEP(F4, b, c, d, a, in[13] + 0x4e0811a1, 21);
    MD5STEP(F4, a, b, c, d, in[4] + 0xf7537e82, 6);
    MD5STEP(F4, d, a, b, c, in[11] + 0xbd3af235, 10);
    MD5STEP(F4, c, d, a, b, in[2] + 0x2ad7d2bb, 15);
    MD5STEP(F4, b, c, d, a, in[9] + 0xeb86d391, 21);

    buf[0] += a;
    buf[1] += b;
    buf[2] += c;
    buf[3] += d;
}

/*------------------------------------------------------------
| MD5Update
|-------------------------------------------------------------
|
| PURPOSE: To update an MD5 context by processing of another 
|          buffer full of bytes.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99
------------------------------------------------------------*/
void 
MD5Update( MD5Context *C, u8* buf, u32 len )
{
    u32 t;
    u8* p;
    
    // Update bitcount.
    t = C->bits[0];
    
    // Carry from low to high.
    if( (C->bits[0] = t + ((u32) len << 3)) < t )
    {
        C->bits[1]++; 
    }        
        
    C->bits[1] += len >> 29;

    // Bytes already in shsInfo->data.
    t = (t >> 3) & 0x3f;        

    // Handle any leading odd-sized chunks.
    if( t ) 
    {
        p = (u8*) C->in + t;

        t = 64 - t;
        
        if( len < t ) 
        {
            memcpy( p, buf, len );
            return;
        }
        
        memcpy( p, buf, t );
        
        RepackQuads( 
            MD5RelativePackingOrder, 
            (u32*) C->in, 
            (u32*) C->in, 
            16 );
        
        MD5Transform( C->buf, (u32*) C->in );
        
        buf += t;
        len -= t;
    }
    
    // Process data in 64-byte chunks.
    while( len >= 64 ) 
    {
        memcpy(C->in, buf, 64);
        
        RepackQuads( 
            MD5RelativePackingOrder, 
            (u32*) C->in, 
            (u32*) C->in, 
            16 );
         
        MD5Transform(C->buf, (u32 *) C->in);
        
        buf += 64;
        len -= 64;
    }

    // Handle any remaining bytes of data.
    memcpy(C->in, buf, len);
}

