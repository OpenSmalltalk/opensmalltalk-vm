/*------------------------------------------------------------
| TimePPC.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide timing functions for PowerPC chips.
|
| DESCRIPTION: There are two different ways of measuring the
| rate of change in the PowerPC chip family: one way only 
| works with the 601 chip and the other way only works for
| non-601 chips.
|
| On the PowerMac these differences are smoothed over by
| using the illegal instruction handler to emulate one
| or the other timing methods.  The seam that shows up is 
| the extra time spent servicing the illegal instruction 
| exception.
|
| The two functions 'GetRealTimePPC' and 'GetTimeBasePPC'
| are opcode-for-opcode identical to the low-level routines 
| used by the Metrowerks Profiler.  These routines are also
| published in the official PowerPC manuals as the right
| way to get the contents of the timing registers.
|
| The following is from 'PowerPC 601 RISC Microprocessor 
| User's Manual', p. B-7:
|
| "B.24 Timing Facilities
|  
|  This section describes differences between the POWER 
|  architecture and the PowerPC architecture timer facilities.
|
|  B.24.1 Real-Time Clock
|
|  The 601 implements a POWER-based RTC.  Note that the
|  POWER RTC is not supported in the PowerPC architecture.
|  Instead, the PowerPC architecture provides a time base
|  (TB).
|
|  Both the RTC and the time base are 64-bit special purpose
|  registers, but they differ in the following respects.
|
|  * The RTC counts seconds, and nanoseconds, while the TB
|    counts 'ticks'.  The frequency of the RTC is implementation-
|    dependent.
|
|  * The RTC increments discontinuously -- 1 is added to RTCU
|    when the value in RTCL passes 999_999_999.  The TB
|    increments continuously -- 1 is added to TBU when the
|    value in TBL passes x'FFFF FFFF'.
|
|  * The RTC is written and read by the 'mtspr' and 'mfspr'
|    instructions, using SPR numbers that denote the RTCU and
|    RTCL.  The TB is written to and read by the instructions
|    'mtspr' and 'mftb'.
|
|  * The SPR numbers that denote RTCL and RTCU are invalid in
|    the PowerPC architecture except the 601.
|
|  * The RTC is gauranteed to increment at least once in the
|    time required to execute 10 Add Immediate (addi) 
|    instructions.  No analogous gaurantee is made for the TB.
|
|  * Not all bits of RTCL need to be implemented, while all
|    bits of the TB must be implemented."
|
| From page 10-127: "For forward compatibility with other
| members of the PowerPC microprocessor family the 'mftb'
| instruction should be used to obtain the contents of the
| RTCL and RTCU registers.  The 'mftb' instruction is a
| PowerPC instruction unimplemented by the 601, and will
| be trapped by the illegal instruction exception handler,
| which can then issue the appropriate mfspr instructions
| for reading the RTCL and RTCU registers."
|
| HISTORY: 02.07.98 from "MacTech" Jan '98 p. 48 which cites
|                   PowerPC 601 RISC User's Manual by
|                   Motorola as it's source.
|          06.15.98 Added notes and updated for chips beyond
|                   601.
|          06.16.98 Revised to read entire 64-bit register not
|                   just the low part.
|          06.18.98 Edited comments.
|          12.20.98 Made set up one-shot, added 
|                   'IsTimePPCSetUp', 'SetUpOriginOfTickCount' 
|                   and 'SetUpOriginOfTimebase'; changed name
|                   of 'CPUType' to 'TypeOfTimebase' and
|                   made global.
------------------------------------------------------------*/
#include <stdio.h>
#include <Gestalt.h>
#include <Events.h>        // For 'TickCount()'.

#if ( __MWERKS__ >= 0x2000 ) // Release 2+
#include <DateTimeUtils.h> // For 'GetDateTime()'.
#else
#include <OSUtils.h>
#endif

#include "NumTypes.h"
#include "TimePPC.h"

#define TicksPerSecond   60
        // Number of TickCount() ticks per second.

u32     TypeOfTimebase = 0;
        // Holds '601' if the currently running CPU is a 
        // 601 chip, else holds '603'.  These are the only
        // two types of timebases defined for the PowerPC.

u64     GetTimePPCOverhead = 0; 
        // The number of ticks that need to be subtracted from
        // an elapsed time result to correct for the time taken
        // to measure the time. In practice timing overhead has
        // been seen to vary so much that it isn't possible
        // accurately apply a timing overhead correction factor.
        // This is here more for general information than 
        // anything else.

u32     IsTimePPCSetUp = 0;
        // This flag indicates whether the timebase functions
        // have been set up for use.
        //
        // It holds '1' when the functions are is enabled, 
        // '0' when not available.

        // The following 'SetUpOrigin...' values are used to 
        // convert timebase values to real-time values at a 
        // resolution that gets progressively better as time 
        // passes.
        //
u32     SetUpOriginOfDateTime = 0;
        // This is the value returned by 'GetDateTime()' when
        // 'SetUpTimePPC()' is first executed.  Holds the number 
        // of seconds since 00:00 January 1 1904 in local time.  
    
u32     SetUpOriginOfTickCount = 0;
        // This is the value of 'TickCount()' measured when
        // 'SetUpTimePPC()' is first executed.  
    
u64     SetUpOriginOfTimebase = 0;
        // This is the value of 'GetTimePPC()' measured when
        // 'SetUpTimePPC()' is first executed.  

u64     TimeBaseTicksPerSecond = 0;
        // A run-time measurement of how many timebase 
        // ticks occur in a second as measured against the
        // real-time second clock.  Set by a call to 
        // 'MeasureTimeBaseTicksPerSecond()'.
        
u64     TimeBaseTicksPerTick = 0;
        // A run-time measurement of how many timebase 
        // ticks occur between ticks of the 'TickCount()'
        // clock.  Set by a call to 
        // 'MeasureTimeBaseTicksPerSecond()'.
        
u32     IsTimeBaseTicksPerTickPrecise = 0;
        // A flag to control whether improvements can be made
        // to the precision of 'TimeBaseTicksPerSecond'.

/*------------------------------------------------------------
| ElapsedTimePPC
|-------------------------------------------------------------
|
| PURPOSE: To compute the elapsed time since a time 
| measurement was taken.
|
| DESCRIPTION: This is a generic routine for high-frequency
| time measurement on any PowerPC chip.  
|
| Takes a time value as input, computes the number of ticks
| between then and now, and saves the result over the input.
|
| Returns the elapsed time measured in units dependent on the 
| tick rate of the chip.
|
| The input/result is a 64-bit number with this format:
|
|          -------------------
|          |   Hi   |   Lo   |
|  Byte    -------------------
| Offset   0        4
|
| EXAMPLE: 
|
|       u64 ATime;
|
|       GetTimePPC( &ATime );
|
|       < Some code to be timed goes here. >
|
|       ElapsedTimePPC( &ATime );
|
| NOTE: Doesn't attempt to compensate for timing overhead.
|
| ASSUMES: The function 'SetUpTimePPC()' has been called
|          prior to calling this function to identify the
|          CPU type that is running.
|
|          The process takes less time than the longest span
|          that can be measured by the time base.
|
| HISTORY: 06.17.98 
|          12.06.98 Removed needless test for 'now' being 
|                   larger than 't'.
------------------------------------------------------------*/
void
ElapsedTimePPC( u64* t )
{
    u64 now;
    
    // Mark the end of a process being timed.
    GetTimePPC( &now );
    
    // Compute the difference.
    *t = now - *t;
}

/*------------------------------------------------------------
| GetRealTimePPC
|-------------------------------------------------------------
|
| PURPOSE: To read the real-time clock registers of the
|          PowerPC 601 chip.
|
| DESCRIPTION: Returns the contents of the RTC registers as a
| a 64-bit number with this format:
|
|          -----------------------
|          |   RTCU   |   RTCL   |
|  Byte    -----------------------
| Offset   0          4
|
| where:
|
|   RTCU is the upper register of the real time clock which
|       holds the number of seconds since the time specified
|       in the software.
|
|   RTCL is the lower register of the real time clock.  It
|       holds the number of nanoseconds since the beginning
|       of the second, with a resolution of 128 nanoseconds 
|       per tick.
|
|       Not all the bits are implemented and should always
|       read as 0.
|
|                         RTCL
|          ---------------------------------
|          | 00 |                | 0000000 |
|          ---------------------------------
|           0  1  2            24 25       31
|                               ^
|                               |__ Least Significant Bit
|
| The low register counts from zero to 999,999,872, one
| billion minus 128 after 999,999,999 nS.  The next time
| RTCL is incremented, it cycles to all zeros and RTCU is
| incremented.
|
| The RTCL is incremented 7812500 times per second, once
| every 128 nanoseconds.
|
| EXAMPLE: 
|
|       u64 RTCL_HiLo;
|
|       GetRealTimePPC( &RTCL_HiLo );
|
| NOTE: See page 2-16 of 601 User's Manual for the detailed
| 
|
| ASSUMES: 
|
| HISTORY:  06.17.98
|           06.24.98 Updated description.
------------------------------------------------------------*/
asm
void
GetRealTimePPC( u64* /* t */ )
{
    machine 601      // This is only for the 601 chip.
A:  mfspr   r4, 4    // Get upper real time clock register.
    mfspr   r5, 5    // Get lower real time clock register.
    mfspr   r6, 4    // Get upper real time clock register again.
    cmpw    r4,r6    // If the upper register has changed.
    bne     A        // Try reading again.
    stw     r4,0(r3) // Put the hi part at the result.
    stw     r5,4(r3) // Put the lo part at offset 4 of result.
    blr              // Return.
}

/*------------------------------------------------------------
| GetTimeBasePPC
|-------------------------------------------------------------
|
| PURPOSE: To read the time base register of any PowerPC chip
|          other than the 601 chip.
|
| DESCRIPTION: Returns a number measured in units dependent
| on the time base tick rate of the chip.
|
| The result is a 64-bit number with this format:
|
|          -------------------
|          |   Hi   |   Lo   |
|  Byte    -------------------
| Offset   0        4
|
| EXAMPLE: 
|
|       u64 Before, After, Diff;
|
|       GetTimeBasePPC( &Before );
|
|       < Some code to be timed goes here. >
|
|       GetTimeBasePPC( &After );
|
|       // Assuming value in 'After' is larger than 'Before',
|       // calculate the elapsed time in ticks.
|       Diff = After - Before; 
|
| NOTE: Not supported on the 601, use 'GetRealTimePPC()'
|       instead.
|
| ASSUMES:  
|
| HISTORY:  06.17.98 
------------------------------------------------------------*/
asm 
void
GetTimeBasePPC( u64* /* t */ )
{
    machine 603      // For any PowerPC chip other than the 601.
A:  mftbu   r4       // Get the upper time base register.
    mftb    r5       // Get the lower time base register.
    mftbu   r6       // Get upper time base register again.
    cmpw    r4,r6    // If the upper register has changed.
    bne     A        // Try reading again.
    stw     r4,0(r3) // Put the hi part at the result.
    stw     r5,4(r3) // Put the lo part at offset 4 of result.
    blr              // Return.
}

/*------------------------------------------------------------
| GetTimePPC
|-------------------------------------------------------------
|
| PURPOSE: To read the time register of any PowerPC chip.
|
| DESCRIPTION: This is a generic routine for high-frequency
| time measurement on any PowerPC chip.  
|
| Returns a number measured in units dependent on the tick 
| rate of the chip.
|
| The result is a 64-bit number with this format:
|
|          -------------------
|          |   Hi   |   Lo   |
|  Byte    -------------------
| Offset   0        4
|
| EXAMPLE: 
|
|       u64 ATime;
|
|       GetTimePPC( &ATime );
|
|       < Some code to be timed goes here. >
|
|       ElapsedTimePPC( &ATime );
|
| NOTE:
|
| ASSUMES: The function 'SetUpTimePPC()' has been called
|          prior to calling this function to identify the
|          CPU type that is running.
|
| HISTORY: 06.17.98 
|          06.29.98 Added unit conversion for 601 chip.
------------------------------------------------------------*/
void
GetTimePPC( u64* t )
{
    u32*    lo;
    u32*    hi;
    u32     H, L;  
    
    // If this is a 601 chip.
    if( TypeOfTimebase == 601 )
    {
        // Read the real time clock register.
        GetRealTimePPC( t );
        
        // Convert seconds:nanoseconds to units of 128 
        // nanoseconds each...
        
        // Refer to the upper register field, RTCU.
        hi = (u32*) t;
        
        // Refer to the lower register field, RTCL.
        lo = (u32*) ( ((u8*) t) + 4 );
        
        // Get the value of the lower register.
        L = *lo;
        
        // Shift the lo part to the left two bits, then right 
        // 9 bits to clear the high bits and right justify the 
        // significant bits.
        //
        // This converts nanosecond units to 128-nS units.
        L = ( L << 2 ) >> 9;
        
        // Get the value of the upper registers.
        H = *hi;

        // Shift high value to the right nine bits to convert 
        // seconds to 128-nS units.
        *hi = H >> 9;
        
        // Shift high value left 23 bits to left justify the 
        // section of the upper 32 bits that shifts into the 
        // lower 32-bits when converting seconds to 128-nS units.
        H = H << 23;
        
        // Merge the bits shifted down from the upper register 
        // with the justified bits of the lower register.
        *lo = H | L;
    }
    else // This is a non-601 chip.
    {
        // Read the time base register.
        GetTimeBasePPC( t );
    }
}

/*------------------------------------------------------------
| MeasureTimeBaseTicksPerSecond
|-------------------------------------------------------------
|
| PURPOSE: To measure how fast the timebase ticks in real 
|          time. 
|
| DESCRIPTION: This function measures the elapsed time since
| the time function set up origin using the real-time clock
| and the timebase reference then computes the ratio.
|
| Returns results in 'TimeBaseTicksPerSecond' and
| 'TimeBaseTicksPerTick'.
|
| The precision of 'TimeBaseTicksPerTick' the result improves 
| each time this routine is called up to the limit imposed 
| by 'TickCount()' rolling over.
|
| From 'InsideMac Vol 1, p. I-260':
|
|  "Warning: Don't rely on the tick count being exact; it 
|   will usually be accurate to within one tick, but may
|   be off by more than that.  The tick count is incremented
|   during the vertical retrace interrupt, but it's possible
|   for this interrupt to be disabled.  Furthermore, don't
|   rely on the tick count being incremented to a certain
|   value, such as testing whether it has become equal to 
|   its old value plus 1; check instead for "greater than or
|   equal to" since the interrupt task may keep control for
|   more than one tick."
|
| Measurements made using this routine on 12.24.98 on an
| 8100/80 and on a PowerBook 2400c/180 show that 'TickCount()'
| increments at around 60.14 times per second.  On the 8100
| the clock used for 'TickCount()' fell further and further
| behind the timebase reference, but on the 2400c the 
| 'TickCount()' clock was constant relative to the timebase.
|
| This is how the measurements were made:
|
|   for( i = 0; i < 10000; i++ )
|   {
|       // Wait for ten seconds to provide a basis
|       // for measuring the timebase speed.
|       
|       // Calculate the final tick count: now + 600 ticks.
|       Tick = TickCount() + 600;
|    
|       // Wait for the tick count to hit the limit.
|       while( TickCount() < Tick ) {};
|       
|       MeasureTimeBaseTicksPerSecond();
|
|       printf( "%ld\t%ld\t%f\n", 
|               (u32) TimeBaseTicksPerSecond,
|               (u32) TimeBaseTicksPerTick,
|               (f64) TimeBaseTicksPerSecond/
|               (f64) TimeBaseTicksPerTick );
|   }
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 'SetUpOriginOfTickCount', 'SetUpOriginOfDateTime' 
|          and 'SetUpOriginOfTimebase' were set at the same 
|          time from their respective clocks prior to calling 
|          this routine.
|
| HISTORY: 12.06.98 
|          12.21.98 Revised to return an increasingly precise
|                   result as time passes.
|          12.24.98 Separated real-time second clock from
|                   'TickCount()' clock.
------------------------------------------------------------*/
void
MeasureTimeBaseTicksPerSecond()
{
    u32 Tick, TickDelta;
    u64 TimeBase, TimeBaseDelta;
    
    //
    // First measure timebase relative to the second
    // clock.
    //
    
    // Get the time base value now.
    GetTimePPC( &TimeBase );

    // Mark when 'SetUpTimePPC()' was called using
    // the real-time second clock.
    GetDateTime( &Tick );
    
    // Calculate the elapsed number of seconds.
    TickDelta = Tick - SetUpOriginOfDateTime;

    // Calculate the elapsed number of timebase units.
    TimeBaseDelta = TimeBase - SetUpOriginOfTimebase;
    
    // Calculate the number of timebase units per second.
    TimeBaseTicksPerSecond =
        ( TimeBaseDelta ) / ( (u64) TickDelta );

    // If the measurement isn't as precise as it can be.
    if( IsTimeBaseTicksPerTickPrecise == 0 )
    {
        //
        // Then measure timebase relative to the 1/60th second
        // clock.
        //

        // Get the tick count now.
        Tick = TickCount();

        // If the real-time clock has rolled over.
        if( Tick < SetUpOriginOfTickCount )
        {
            // Then the maximum precision has been reached.
            IsTimeBaseTicksPerTickPrecise = 1;
            
            // Just return.
            return;
        }

        // Calculate the elapsed number of roughly 1/60 th 
        // second Ticks.
        TickDelta = Tick - SetUpOriginOfTickCount;

        // Calculate the elapsed number of timebase units.
        TimeBaseDelta = TimeBase - SetUpOriginOfTimebase;
        
        // Calculate the number of timebase units per tick.
        TimeBaseTicksPerTick =
            ( TimeBaseDelta ) / ( (u64) TickDelta );
            
        // If this routine is called before a second has passed
        // since the set up origin.
        if( TimeBaseTicksPerSecond == 0 )
        {
            // Approximate the timebase units per second based
            // on the 'TickCount()' clock.
            TimeBaseTicksPerSecond = TimeBaseTicksPerTick * 60;
        }
    }
}
    
/*------------------------------------------------------------
| ReadTimeStamp
|-------------------------------------------------------------
|
| PURPOSE: To read the time stamp counter from the CPU.
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
|         
------------------------------------------------------------*/
u64
ReadTimeStamp()
{
    u64 t;
    
    // If timer functions haven't been set up.
    if( IsTimePPCSetUp == 0 )
    {
        SetUpTimePPC();
    }
    
    // Read the timer register.
    GetTimePPC( &t );
    
    // Return the result.
    return( t );
}

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
|       u64 UnitsPerSecond;
|
|       RoughTimeStampFrequency( &UnitsPerSecond );
|
| NOTE:
|
| ASSUMES: A Pentium or more advanced chip is running.
|
| HISTORY: 03.09.00
|          03.13.00 Revised to save the computed value to
|                   avoid delays.
|          07.14.00 Revised to avoid wild NT delays.
|          07.17.00 Ported to Mac.
|          08.05.00 Revised to make it faster.
------------------------------------------------------------*/
u64        // OUT: Number of ticks per second.
RoughTimeStampFrequency()
{
    u64 LoTS;
    u64 HiTS;
    u64 Repetitions, i, j, x, Samples;
    static u64 FreqTS = 0;
    u64 DifTick[100];
    u64 DifTS[100];
    u32 LoTick;
    u32 HiTick;
    u32 NextTick;
   
    // If the value has already been computed once.
    if( FreqTS != 0 )
    {
        // Just return the value.
        return( FreqTS );
    }
 
    // Collect 10 samples.
    Samples = 10;
    
    // Collect samples.
    for( i = 0; i < Samples; i++ )
    {   
        // Read the tick counter.
        LoTick = TickCount(); 

/////////////////
ReadNextTickLo://
/////////////////
        
        // Read the tick counter again.
        NextTick = TickCount();
        
        // Wait till the tick count changes.
        if( NextTick == LoTick )
        {
            // Go read the next tick.
            goto ReadNextTickLo;
        }
        else // The tick count changed.
        {
            // Regard the new tick value as
            // the low one.
            LoTick = NextTick;
        }
        
        // Read the timestamp counter.
        LoTS = ReadTimeStamp();
    
    
/////////////////
ReadNextTickHi://
/////////////////
        
        // Read the tick counter again.
        NextTick = TickCount();
        
        // Wait till the tick count changes.
        if( NextTick == LoTick )
        {
            // Go read the next tick.
            goto ReadNextTickHi;
        }
        else // The tick count changed.
        {
            // Regard the new tick value as
            // the high one.
            HiTick = NextTick;
        }
        
        // Read the timestamp counter.
        HiTS = ReadTimeStamp();
    

        // Calculate the difference in the performance counter
        // readings.
        DifTick[i] = (u64) HiTick - (u64) LoTick;
        
        // Calculate the difference in the time-stamp counter
        // readings.
        DifTS[i] = HiTS - LoTS;
    }
    
    // Find the smallest difference in timestamp values.
    j = 0;
    for( i = 1; i < Samples; i++ )
    {   
        // If the current difference is smaller than the best
        // yet.
        if( DifTS[i] < DifTS[j] )
        {
            // Then make i the new smallest difference.
            j = i;
        }
    }
    
    // Calculate the time-stamp counter frequency.
    FreqTS = (u64) TicksPerSecond * DifTS[j] / DifTick[j];

printf( "RoughTimeStampFrequency = %lf\n", (f64)(s64) FreqTS );

    // Return the result.
    return( FreqTS );
}

/*------------------------------------------------------------
| SetUpTimePPC
|-------------------------------------------------------------
|
| PURPOSE: To prepare for high-resolution time measurement on
|          the PowerPC chip.
|
| DESCRIPTION: Call this routine prior to taking a time 
| measurement.  The CPU type and timing overhead are computed
| for use by the timing functions.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: The timing overhead factor computed by this 
|          function is based on having the timing functions 
|          resident in the on-chip cache at the time they are 
|          called.  It's your responsibility to pre-fetch
|          the timing functions to make this true.
|
| HISTORY:  06.17.98
|           12.06.98 Added 'MeasureTimeBaseTicksPerSecond()'.
|           12.20.98 Revised to perform set up at most once;
|                    added 'SetUpOriginOfDateTime',
|                    'SetUpOriginOfTickCount' and
|                    'SetUpOriginOfTimebase'.
------------------------------------------------------------*/
void
SetUpTimePPC()
{
    OSErr   err;
    s32     result;
    u64     Timer;
    u32     Tick;
    
    // If timer functions haven't been set up.
    if( IsTimePPCSetUp == 0 )
    {
        // Find what kind of CPU is running.
        err = Gestalt( gestaltProcessorType, &result );
    
        // If this is a PowerPC 601 chip.
        if( result == gestaltCPU601 )
        {
            TypeOfTimebase = 601;
        }
        else // Treat all other PowerPC chips as if they
             // have a time base register like the 603.
        {
            TypeOfTimebase = 603;
        }
        
        // Mark when 'SetUpTimePPC()' was called using
        // the real-time second clock.
        GetDateTime( &SetUpOriginOfDateTime );
        
        // Mark when 'SetUpTimePPC()' was called using
        // the real-time clock counter.
        SetUpOriginOfTickCount = TickCount();
    
        // Mark when 'SetUpTimePPC()' was called using
        // the timebase.
        GetTimePPC( &SetUpOriginOfTimebase );
 
        // Assume that there is no overhead for timing calls.
        GetTimePPCOverhead = 0;
        
        // Call these two routines here just to get them into
        // the on-chip cache.
        GetTimePPC( &Timer );
        ElapsedTimePPC( &Timer );

        // Now make the real measurement of how long it takes 
        // to do nothing.
        GetTimePPC( &Timer );
        ElapsedTimePPC( &Timer );
        
        // The resulting time is the timing overhead, a correction 
        // factor that could be applied to future timings if it
        // didn't vary so much.  This is a rough cost of time
        // measurement.
        GetTimePPCOverhead = Timer;
        
        // Wait for a quarter of a second to provide a basis
        // for measuring the timebase speed.
        
        // Calculate the final tick count: now + 15 ticks.
        Tick = TickCount() + 15;
     
        // Wait for the tick count to hit the limit.
        while( TickCount() < Tick ) {};

        // Measure roughly how fast the timebase ticks.
        MeasureTimeBaseTicksPerSecond();
        
        // Signal that timebase has been set up.
        IsTimePPCSetUp = 1;
    }
}
