/*------------------------------------------------------------
| TLTimeNT.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to time functions for Windows
|          NT.
|
| DESCRIPTION:  
|
| NOTE:
|
| HISTORY: 01.14.98 From 'TimePPC.h'.
|          02.06.00 Added inclusion of 'NumTypes.h'.
------------------------------------------------------------*/
    
#ifndef TLTIMENT_H
#define TLTIMENT_H

#ifdef __cplusplus
extern "C"
{
#endif
    
#include "NumTypes.h" // Explicit number types.

#define SECONDS_PER_MINUTE (60)
#define SECONDS_PER_HOUR   (3600)
#define SECONDS_PER_DAY    (86400)
#define SECONDS_PER_YEAR   (31536000)

void     ElapsedTimeNT( u64* );
void     GetTimeNT( u64* );
u64      GetUtcInSeconds();
u64      ReadTimeStamp();
void     ReadTimeStamp2x( u64* BufferAddr );
void     ReadTimeStamp3x( u64* BufferAddr );
f64      ReadTimeStampInSeconds();
f64      ReadTimeStampSmooth();
u64      RoughTimeStampFrequency();

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLTIMENT_H
