/*------------------------------------------------------------
| TLOrdinal.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to ordinal number functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 04.29.96 
------------------------------------------------------------*/

#ifndef _ORDINAL_H_
#define _ORDINAL_H_

s32     FindNearestHiOrdinalPoint( Matrix*, f64* );
s32     FindNearestLoOrdinalPoint( Matrix*, f64* );
s32     FindNearestOrdinalPoint( Matrix*, f64* );
u32     IsLessOrEqualOrdinalPoint( s32, f64*, f64* );
u32     IsMoreOrEqualOrdinalPoint( s32, f64*, f64* );
u32     IsNearerHiOrdinalPoint( s32, f64*, f64*, f64* );
u32     IsNearerLoOrdinalPoint( s32, f64*, f64*, f64* );
u32     IsNearerOrdinalPoint( s32, f64*, f64*, f64* );

 
#endif // _ORDINAL_H_
