/*------------------------------------------------------------
| TLTls.h
|-------------------------------------------------------------
|
| PURPOSE: To supply the interface to the total 
|          least-squares function.
|
| DESCRIPTION: 
|        
| NOTE:  
|
| HISTORY: 02.18.00 From "Mathematical Methods and Algorithms
|                   for Signal Processing" by Todd K. Moon.
------------------------------------------------------------*/

#ifndef TLTLS_H
#define TLTLS_H

#ifdef __cplusplus 
extern "C"
{
#endif
void    ConvertDataToZScores( f64*, u32, s32, f64*, s32,
                              f64*, f64*, f64*);
void    HouseholderVector( f64*, f64*, s32 );

void    LineFit( f64*, f64*, s32, f64*, f64*, f64*, f64*, f64* );

u32     LineFitTls( f64*, f64*, s32, f64*, f64*, 
                    f64**, f64*, f64** );
                    
u32     TotalLeastSquares( f64**, f64*, s32, s32, f64*, f64**, 
                           f64*, f64* );
 
#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLTLS_H
