/*------------------------------------------------------------
| TLTimeNT.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide timing functions for Windows NT.
|
| DESCRIPTION: This whole file is NT-specific.
|
| HISTORY: 01.14.98 From 'TimePPC.c'.
|          02.06.00 Replaced include file "TLTypes.h" with
|                   smaller "NumTypes.h".
------------------------------------------------------------*/

#include "TLTarget.h" 

#if defined(FOR_WINNT) | defined(FOR_WIN98) | defined(FOR_WIN2000)  

#ifndef FOR_DRIVER
 
#include <time.h>
#include <stdio.h>

#endif // not FOR_DRIVER

#include "NumTypes.h"

#include "TLTimeNT.h"

/*

From: http://www.bluewatersystems.com/scripts/kb_view.cfm?view=151

Getting 1 ms timers on NT 

NT uses 10 or 15 ms timers by default, how to set time 
granularity to 1ms 


By default most NT systems use 10 milliseconds or 15 ms as there 
minimum clock timer. The multimedia APIs can be used to set the 
timer to a 1 ms granularity. This change will be global for the 
system. A change a user mode application will also affect timers 
in kernel drivers. The following code will set the clock 
granularity to 1 ms:


  TIMECAPS tc;
  timeGetDevCaps(&tc, sizeof(tc));
  printf("Min Time %d, Max %d\n", tc.wPeriodMin, tc.wPeriodMax);
  timeBeginPeriod(tc.wPeriodMin);

To return the original timer granularity use:

timeEndPeriod(tc.wPeriodMin);

*/

/*------------------------------------------------------------
| ElapsedTimeNT
|-------------------------------------------------------------
|
| PURPOSE: To compute the elapsed time since a time 
|          measurement was taken.
|
| DESCRIPTION: This is a generic routine for high-frequency
| time measurement on any Windows NT machine.  
|
| Takes a time value as input, computes the number of ticks
| between then and now, and saves the result over the input.
|
| Returns the elapsed time measured in 100 nanosecond units.
|
| The input/result is a 64-bit number.
|
| EXAMPLE: 
|
|       u64 ATime;
|
|       GetTimeNT( &ATime );
|
|       < Some code to be timed goes here. >
|
|       ElapsedTimeNT( &ATime );
|
| NOTE: Doesn't attempt to compensate for timing overhead.
|
| ASSUMES: 
|
| HISTORY: 01.14.98 From 'ElapsedTimePPC()'.
------------------------------------------------------------*/
void
ElapsedTimeNT( u64* t )
{
    u64 now;
    
    // Mark the end of a process being timed.
    GetTimeNT( &now );
    
    // Compute the difference.
    *t = now - *t;
}

/*------------------------------------------------------------
| GetTimeNT
|-------------------------------------------------------------
|
| PURPOSE: To read the current time at a high resolution from
|          the NT operating system.
|
| DESCRIPTION: This is a generic routine for high-frequency
| time measurement on Windows NT systems that are running on
| at least a Pentium.
|
| Returns the number of clock cycles since the CPU was last
| reset.
|
| The result is a 64-bit number.
|
| EXAMPLE: 
|
|       u64 ATime;
|
|       GetTimeNT( &ATime );
|
|       < Some code to be timed goes here. >
|
|       ElapsedTimeNT( &ATime );
|
| NOTE:
|
| ASSUMES: At least a Pentium chip is running.
|
| HISTORY: 01.14.99 From 'GetTimePPC()'.
|          02.15.00 Using 'GetProcessTimes' doesn't give a
|                   precise clock.  A test run today showed
|                   long stretches of time where the clock
|                   was not updated.  Converted to using
|                   the performance counter instead.
|          03.08.00 QueryPerformanceCounter has problems too.
|                   The latency of QueryPerformanceCounter
|                   ranges from 4 to 16576 ticks with 5 being
|                   the mean.  The method now used is to read
|                   the Time-stamp Counter Register from the
|                   Intel chip, assuming at least a Pentium
|                   is running.  The resolution is higher:
|                   minimum latency is 63, max is 132 and
|                   mean is 66.
------------------------------------------------------------*/
void
GetTimeNT( u64* t )
{
    u32 lo, hi;
    
    // Read the Time-Stamp Counter register into 'lo' and 'hi.
    __asm
    {
        // If this is the Metrowerks compiler.
#ifdef __MWERKS__

        rdtsc
        
#else // Visual C++ Compiler doesn't recognize the 'rdtsc'
      // instruction so the opcodes are used instead.
      
        __emit  0fh
        __emit  031h
#endif
        mov   lo, eax
        mov   hi, edx
    }

    // Combine the low and high 32-bit parts into a single
    // 64-bit number and return the result.
    *t = ( (u64) hi << 32 ) | (u64) lo;
}

#ifndef FOR_DRIVER

//
// Keep the following around for documentation only:
//
#ifdef USE_GET_PROCESS_TIMES
    HANDLE      P;
    u64         c, k, u;
    FILETIME    CreationTime, ExitTime;
    FILETIME    KernelTime, UserTime;
    
    // Get the handle to the current process.
    P = GetCurrentProcess();
    
    // Get the current time information for the current
    // process.
    GetProcessTimes( 
        P, 
        &CreationTime,
        &ExitTime,
        &KernelTime,
        &UserTime );
    
    // Convert the creation time FILETIME format to 
    // integer format.
    c = CreationTime.dwHighDateTime;
    c = ( c << 32 ) | CreationTime.dwLowDateTime;
        
    // Convert the kernel time FILETIME format to 
    // integer format.
    k = KernelTime.dwHighDateTime;
    k = ( k << 32 ) | KernelTime.dwLowDateTime;
        
    // Convert the user time FILETIME format to 
    // integer format.
    u = UserTime.dwHighDateTime;
    u = ( u << 32 ) | UserTime.dwLowDateTime;
        
    // Return the current time.
    *t = c + k + u;
#endif

#ifdef USE_QUERY_PERFORMANCE_COUNTER
    LARGE_INTEGER   L;
    
    // Get the performance counter value.
    QueryPerformanceCounter( &L );

    // Return the result.
    *t = (u64) L.QuadPart;
#endif

/*------------------------------------------------------------
| GetUtcInSeconds
|-------------------------------------------------------------
|
| PURPOSE: To read the UTC time in seconds.
|
| DESCRIPTION:  
|
| Returns the number of seconds since 0 AD.
|
| The result is a 64-bit number.
|
| EXAMPLE: 
|
|       u64 t;
|
|       t = GetUtcInSeconds();
|
| NOTE:
|
| ASSUMES:  
|
| HISTORY: 04.03.00 From MSL C Reference.
------------------------------------------------------------*/
u64
GetUtcInSeconds()
{
    u64     t;
    time_t  systime;
    struct tm* utc;
    
    systime = time(0);
    
    utc = gmtime(&systime);
    
//  printf( "UTC: \n" );
    
//  puts( asctime(utc) );
    
    // Convert compound time number to seconds.
    t = ( (u64) utc->tm_year * (u64) SECONDS_PER_YEAR   ) +
        ( (u64) utc->tm_yday * (u64) SECONDS_PER_DAY    ) +
        ( (u64) utc->tm_hour * (u64) SECONDS_PER_HOUR   ) +
        ( (u64) utc->tm_min  * (u64) SECONDS_PER_MINUTE ) +
        (u64) utc->tm_sec;
    
    // Return the time in seconds.
    return( t );
}

#endif // FOR_DRIVER
 
/*------------------------------------------------------------
| ReadTimeStamp
|-------------------------------------------------------------
|
| PURPOSE: To read the time stamp counter from the Pentium.
|
| DESCRIPTION:  
|
| Returns the number of clock cycles since the CPU was last
| reset.
|
| The result is a 64-bit number.
|
| EXAMPLE: 
|
|       u64 t;
|
|       t = ReadTimeStamp();
|
| NOTE:
|
| ASSUMES: At least a Pentium chip is running.
|
| HISTORY: 03.10.00
|          05.30.00 Optimized added CPUID instruction to
|                   serialize the processor.
|          06.22.00 Pulled out serialization code.
------------------------------------------------------------*/
                    // Disable generation of standard entry
__declspec(naked)   // and exit code.
u64
ReadTimeStamp()
{
    // Read the Time-Stamp Counter register into 'lo' and 'hi.
    __asm
    {
        // If this is the Metrowerks compiler.
#ifdef __MWERKS__

        // Read the timestamp register and put the result
        // into eax:edx.
        rdtsc
        
#else // Visual C++ Compiler doesn't recognize the 'rdtsc'
      // instruction so the opcodes are used instead.
      
        __emit  0fh
        __emit  031h
#endif
        ret
    }
}

#ifndef FOR_DRIVER

/*------------------------------------------------------------
| ReadTimeStampInSeconds
|-------------------------------------------------------------
|
| PURPOSE: To read the timestamp counter from the CPU
|          and make a rough conversion to seconds.
|
| DESCRIPTION: 
|
| EXAMPLE:  t = ReadTimeStampInSeconds();
|
| ASSUMES: 
|
| HISTORY: 08.14.00 
------------------------------------------------------------*/
f64     // OUT: Current CPU timestamp in seconds.
ReadTimeStampInSeconds()
{
    f64 t;
  
    // Read the mux clock reference and convert to seconds.
    t = ( (f64) (s64) ReadTimeStamp() ) / 
        ( (f64) (s64) RoughTimeStampFrequency() );
 
    // Return the MCR value in seconds.
    return( t );
}

/*------------------------------------------------------------
| RoughTimeStampFrequency
|-------------------------------------------------------------
|
| PURPOSE: To roughly estimate the frequency of the time-stamp 
|          counter of the CPU.
|
| DESCRIPTION: This routine uses the nominal frequency of the
| NT Performance Counter and it samples the time-stamp counter
| with the NT Performance Counter to return a rough estimate
| of the time-stamp counter frequency.
|
| Returns the rate of the time-stamp counter in units per 
| second.
|
| The result is a 64-bit number.
|
| EXAMPLE: 
|
|            u64 UnitsPerSecond;
|
|            RoughTimeStampFrequency( &UnitsPerSecond );
|
| NOTE:
|
| ASSUMES: A Pentium or more advanced chip is running.
|
| HISTORY: 03.09.00
|          03.13.00 Revised to save the computed value to
|                   avoid delays.
|          07.14.00 Revised to avoid wild NT delays.
------------------------------------------------------------*/
u64        // OUT: Number of ticks per second.
RoughTimeStampFrequency()
{
    u64 LoTS;
    u64 HiTS;
    u64 Repetitions, i, j, x;
    static u64 FreqTS = 0;
    u64 DifPC[100];
    u64 DifTS[100];
    LARGE_INTEGER   LoPC;
    LARGE_INTEGER   HiPC;
    LARGE_INTEGER   FreqPC;
    
    // If the value has already been computed once.
    if( FreqTS != 0 )
    {
        // Just return the value.
        return( FreqTS );
    }
    
    // Set the number of units of work that should be
    // measured.
    Repetitions = 10000;

/////////// 
TryAgain://
/////////// 
    
    // Collect 10 samples.
    for( i = 0; i < 10; i++ )
    {   
        // Read the timestamp counter.
        LoTS = ReadTimeStamp();
    
        // Read the performance counter 
        QueryPerformanceCounter( &LoPC );
        
        // Waste some time.
        x = 0;
        for( j = 0; j < Repetitions; j++ )
        {
            // Do some small amount of work that takes time.
            x += 1;
        }

        // Read the timestamp counter.
        HiTS = ReadTimeStamp();
    
        // Read the performance counter 
        QueryPerformanceCounter( &HiPC );

        // Calculate the difference in the performance counter
        // readings.
        DifPC[i] = (u64) HiPC.QuadPart - (u64) LoPC.QuadPart;
        
        // Calculate the difference in the time-stamp counter
        // readings.
        DifTS[i] = HiTS - LoTS;
    }
    
    // Find the smallest difference in timestamp values.
    j = 0;
    for( i = 1; i < 10; i++ )
    {   
        // If the current difference is smaller than the best
        // yet.
        if( DifTS[i] < DifTS[j] )
        {
            // Then make i the new smallest difference.
            j = i;
        }
    }
            
    // If the difference in the PC values is less than
    // 100.
    if( DifPC[j] < 100 )
    {
        // Then the number of repetitions is too small.
    
        // Double the number of repetitions
        Repetitions += Repetitions;
    
        // Repeat the sampling.
        goto TryAgain;
    }
    
    // Read the nominal performance counter frequency which
    // is not the actual frequency but good enough for a
    // rough estimate.  Result is units per second.
    QueryPerformanceFrequency( &FreqPC );
    
    // Calculate the time-stamp counter frequency.
    FreqTS = (u64) FreqPC.QuadPart * DifTS[j] / DifPC[j];

printf( "RoughTimeStampFrequency = %lf\n", (f64)(s64) FreqTS );

    // Return the result.
    return( FreqTS );
}
#endif // not FOR_DRIVER

#endif // defined(FOR_WINNT) | defined(FOR_WIN98) | defined(FOR_WIN2000)  
