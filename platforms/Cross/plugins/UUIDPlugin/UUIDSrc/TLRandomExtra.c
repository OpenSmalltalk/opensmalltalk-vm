/*------------------------------------------------------------
| TLRandomExtra.c
|-------------------------------------------------------------
|
| PURPOSE: To provide less commonly used random number
|          functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 06.12.01 Split off from 'TLRandom.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.


#include <stdio.h>

#if macintosh

#include <QuickDraw.h>
#include <TextEdit.h>
#include <Processes.h>
#include <stdlib.h>
#endif // macintosh

#include "TLTypes.h"

#if macintosh

#include "TimePPC.h"

#endif // macintosh

#if defined( __INTEL__ ) || defined( _M_IX86 )

#include "TLTimeNT.h"

#endif // __INTEL__

#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLMatrixAlloc.h"
#include "TLPoints.h"
#include "TLGeometry.h"
#include "TLWeight.h"
//#include "TLStat.h"
#include "TLIntegers.h"
#include "TLWin.h"
//#include "TLLog.h"
#include "TLMD5.h"

#include "TLRandom.h"

#include "TLRandomExtra.h"

#define znew   (z=36969*(z&65535)+(z>>16))
#define wnew   (w=18000*(w&65535)+(w>>16))
#define MWC    ((znew<<16)+wnew )
#define SHR3  (jsr^=(jsr<<17), jsr^=(jsr>>13), jsr^=(jsr<<5))
#define CONG  (jcong=69069*jcong+1234567)
#define FIB   ((b=a+b),(a=b-a))
#define KISS  ((MWC^CONG)+SHR3)
#define LFIB4 (c++,t[c]=t[c]+t[UC(c+58)]+t[UC(c+119)]+t[UC(c+178)])
#define SWB   (c++,bro=(x<y),t[c]=(x=t[UC(c+34)])-(y=t[UC(c+19)]+bro))
#define UNI   (KISS*2.328306e-10)
#define VNI   ((long) KISS)*4.656613e-10
#define UC    (unsigned char)  /*a cast operation*/
typedef unsigned long UL;

/* Use random seeds to reset z,w,jsr,jcong,a,b, and the table t[256]*/

/* Example procedure to set the table, using KISS: */
// void settable(UL i1,UL i2,UL i3,UL i4,UL i5, UL i6)
// { int i; z=i1;w=i2,jsr=i3; jcong=i4; a=i5; b=i6;
// for(i=0;i<256;i=i+1)  t[i]=KISS;
// }

static u32 z=362436069, w=521288629, jsr=123456789, jcong=380116160;
static u32 a=224466889, b=7584631, t[256];
static u32 x=0, y=0, bro; 
static u8  c=0;

//#define SWB   (c++,bro=(x<y),t[c]=(x=t[(u8)(c+34)])-(y=t[(u8)(c+19)]+bro))
 
// c++;
// bro = x < y;
// x=t[(u8)(c+34)];
// y=t[(u8)(c+19)]+bro;
// t[c] = x - y;

/*------------------------------------------------------------
| PickUniqueRandomIntegers
|-------------------------------------------------------------
|
| PURPOSE: To generate several unique integers at random
|          between zero and N, including zero and excluding N.
|
| DESCRIPTION:  
|
| EXAMPLE:   
|
| NOTE:  
|
| ASSUMES: 'SetUpRandomNumberGenerator' has been called.
|
|          Target buffer is big enough.
|
| HISTORY: 06.23.97
------------------------------------------------------------*/
void
PickUniqueRandomIntegers( s32* Buffer, s32 Count, s32 N )
{
    s32* A;
    s32  i;
    s32  FoundCount;
    
    // Refer to where the first integer will go.
    A = Buffer;
    
    // Until enough integers have been picked.
    FoundCount = 0;
    
    while( FoundCount < Count )
    {
        // Generate a candidate.
        i = RandomInteger( N );
        
        // If this integer hasn't been picked yet, save it.
        if( ! IsIntegerInBuffer( Buffer, FoundCount, i ) )
        {
            *A++ = i;
        
            // Note that I found one.
            FoundCount++;
        }
    }
}


/*------------------------------------------------------------
| RandomPointsAround
|-------------------------------------------------------------
|
| PURPOSE: To generate uniform random n-dimensional points
|          at a uniform distance from another point.
|
| DESCRIPTION: Randomly generates n-dimensional points on
| a sphere of a given radius from a given origin.
|
| EXAMPLE: RandomPointsAround( Origin, 
|                              DimCount,
|                              Radius, 
|                              Buffer, 
|                              PtCount );
|
| NOTE:  
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 05.18.97
------------------------------------------------------------*/
void
RandomPointsAround( f64* Origin,
                    s32 DimCount,
                    f64  Radius,
                    f64* Pts,
                    s32 PtCount )
{
    s32 i;
    
    // For each point.
    for( i = 0; i < PtCount; i++ )
    {
        // Make a random unit vector.
        RandomUnitVector( Pts, DimCount );
        
        // Scale the point by the radius.
        MultiplyToItems( Pts, DimCount, Radius );
        
        // Displace the point to the origin point.
        AddItems( Origin, Pts, DimCount );
        
        // Advance to the next point.
        Pts += DimCount;
    }
}

/*------------------------------------------------------------
| RandomUnitVector
|-------------------------------------------------------------
|
| PURPOSE: To generate a uniform random n-dimensional vector 
|          with unit length.
|
| DESCRIPTION: Randomly generates an n-dimensional point on
| the unit sphere centered at the origin.
|
| EXAMPLE: RandomUnitVector( &Buffer, DimCount );
|
| NOTE:  
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|
| HISTORY: 05.18.97
------------------------------------------------------------*/
void
RandomUnitVector( f64* V, s32 DimCount )
{
    s32 i;
    f64 Length, v;
    
    Length = 0;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        v = RandomValueFromRange( -1., 1. );
        
        V[i] = v;
        
        Length += v * v;
    }
    
    Length = sqrt( Length );
    
    // Normalize vector to length 1.
    for( i = 0; i < DimCount; i++ )
    {
        V[i] /= Length;
    }
}


/*------------------------------------------------------------
| TrueRandomNumber
|-------------------------------------------------------------
|
| PURPOSE: To generate a truly random 64-bit number.
|
| DESCRIPTION:  
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 'SetUpTimePPC()' has been called prior to calling
|          this routine.
|
| HISTORY: 12.06.98
|          12.28.98 Revised after tests on G3 machine reveals
|                   poor randomization.  Simple test shows
|                   excellent randomization: count how often
|                   the mask bit is added or substracted and
|                   if the number of adds is close to the
|                   number subtracted then the resulting
|                   number will be random.  Changed way of
|                   returning value when link problems found
|                   in one case: high 32-bits was being lost.
|                   Made 'A' static and initialized to time
|                   and process number only once.
|          12.30.98 Made Mac-specific.
|          01.14.99 Added NT support via MD5 hash function.
		   10.09.01 JMM changed mac to do use randomx call 
------------------------------------------------------------*/
void
TrueRandomNumber( u64* n )
{
#if macintosh

    static  u64         A = 0;
    static  u64         b = 0, c = 0;
    u64                 t,u,M;
    u32                 i;
    ProcessSerialNumber PSN;
    u64 				check;
    
    // If 'A' hasn't been initialized.
    if( A == 0 )
    {
        // Get the 64-bit timebase value from the PowerPC.
        GetTimeCPU( &A );
        
        // Get the process serial number of the current process.
        GetCurrentProcess( &PSN );
        // Set the working value of the number being generated to
        // the XOR product of the current timebase value and
        // the process serial number.
        A = t;
        A ^= *( (u64*) &PSN );
        check  = A;
        srand(check);
    }
    u = 0;
    M = 1;
    for (i=0;i<64;i++) {
    	check = rand();
    	check = (check/2*2==check) ? 1 : 0;
    	b = M << i;
    	u = u | (check*b);
    }
    
    // Return the result.
    *n = u;
    
#else // Not MacOS.

#if defined( __INTEL__ ) || defined( _M_IX86 )

    u32         ThreadID, ProcessID, Ticks;
    HANDLE      H;
    CONTEXT     C;
    MD5Context  M;
    u8          Digest[16];
    u64         t;
    
    // Get a handle to the current thread.
    H = GetCurrentThread();
    
    // Get the register context of the current thread.
    GetThreadContext( H, &C );
     
    // Get the current thread ID.
    ThreadID = GetCurrentThreadId();
    
    // Get the current process ID.
    ProcessID = GetCurrentProcessId();
    
    // Get the number of milliseconds since Windows
    // started, modulo 49.7 days.
    Ticks = GetTickCount();
    
    // Get the current time.
    GetTimeNT( &t );
    
    // Begin calculating an MD5 message-digest hash.
    MD5Init( &M );
    
    // Add the thread handle to the hash.
    MD5Update( &M, (u8*) &H, sizeof( HANDLE ) );
    
    // Add the thread ID to the hash.
    MD5Update( &M, (u8*) &ThreadID, sizeof( u32 ) );
    
    // Add the thread context to the hash.
    MD5Update( &M, (u8*) &C, sizeof( CONTEXT ) );
    
    // Add the process ID to the hash.
    MD5Update( &M, (u8*) &ProcessID, sizeof( u32 ) );

    // Add the tick count to the hash.
    MD5Update( &M, (u8*) &Ticks, sizeof( u32 ) );
    
    // Add the current time to the hash.
    MD5Update( &M, (u8*) &t, sizeof( u64 ) );
    
    // Complete the message digest computation.
    MD5Final( &M, Digest );
    
    // Copy the first eight bytes of the digest to
    // the result.
    CopyBytes( Digest, (u8*) n, 8 );
    
#endif // __INTEL__
    
#endif // macintosh
}

