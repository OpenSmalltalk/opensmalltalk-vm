/*------------------------------------------------------------
| TimePPC.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to time functions for the 
|          PowerPC chips.
|
| DESCRIPTION:  
|
| NOTE:
|
| HISTORY: 02.07.98
|          12.20.98 Added global timebase variables.
------------------------------------------------------------*/
    
#ifndef _TIMEPPC_H_
#define _TIMEPPC_H_

#ifdef __cplusplus
extern "C"
{
#endif

extern u32  TypeOfTimebase;
            // Holds '601' if the currently running CPU is a 
            // 601 chip, else holds '603'.  These are the only
            // two types of timebases defined for the PowerPC.

extern u64  GetTimePPCOverhead; 
            // The number of ticks that need to be subtracted 
            // from an elapsed time result to correct for the 
            // time taken to measure the time. In practice 
            // timing overhead has been seen to vary so much 
            // that it isn't possible accurately apply a 
            // timing overhead correction factor.
            // This is here more for general information than 
            // anything else.

extern u32  IsTimePPCSetUp;
            // This flag indicates whether the timebase 
            // functions have been set up for use.
            //
            // It holds '1' when the functions are is 
            // enabled, '0' when not available.

            // The following 'SetUpOrigin...' values are used to 
            // convert timebase values to real-time values at a 
            // resolution that gets progressively better as time 
            // passes.
            //
extern u32  SetUpOriginOfDateTime;
            // This is the value returned by 'GetDateTime()' 
            // when 'SetUpTimePPC()' is first executed.  Holds 
            // the number of seconds since 00:00 January 1 1904 
            // in local time.  
    
extern u32  SetUpOriginOfTickCount;
            // This is the value of 'TickCount()' measured when
            // 'SetUpTimePPC()' is first executed.  
    
extern u64  SetUpOriginOfTimebase;
            // This is the value of 'GetTimePPC()' measured when
            // 'SetUpTimePPC()' is first executed.  

extern u64  TimeBaseTicksPerSecond;
            // A run-time measurement of how many timebase 
            // ticks occur in a second as measured against the
            // real-time second clock.  Set by a call to 
            // 'MeasureTimeBaseTicksPerSecond()'.
        
extern u64  TimeBaseTicksPerTick;
            // A run-time measurement of how many timebase 
            // ticks occur in a second as measured against the
            // 1/60th second clock.  Set by a call to 
            // 'MeasureTimeBaseTicksPerSecond()'.
        

void     ElapsedTimePPC( u64* );
asm void GetRealTimePPC( u64* );
asm void GetTimeBasePPC( u64* );
void     GetTimePPC( u64* );
void     MeasureTimeBaseTicksPerSecond();
u64      ReadTimeStamp();
f64      ReadTimeStampInSeconds();
u64      RoughTimeStampFrequency();
void     SetUpTimePPC();

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TIMEPPC_H_
