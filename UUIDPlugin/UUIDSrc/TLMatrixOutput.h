/*------------------------------------------------------------
| TLMatrixOutput.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to matrix output functions.
|
| DESCRIPTION: 
|        
| NOTE:  
|
| HISTORY: 01.30.00 Separated from 'TLMatrix.c'.
------------------------------------------------------------*/

#ifndef _TLMATRIXOUTPUT_H_
#define _TLMATRIXOUTPUT_H_

#ifdef __cplusplus
extern "C"
{
#endif

void    print_matrix( s8*, f64**, s32, s32 );
void    print_quaternion( s8*, f64* );
void    print_vector( s8*, f64*, s32 );
void    SaveMatrix( Matrix*, s8* );
void    SaveDatedMatrix( Matrix*, s8* );
void    SaveDatedMatrixRounded( Matrix*, s8*, s32 );
void    SaveDatedMatrixRoundedDAY( Matrix*, s8*, s32 );
void    SaveDatedMatrixRoundedTSV( Matrix*, s8*, s32 );
void    SaveListOfMatricesAsBinary( List*, FILE* );
void    SaveMatrixAsBinary( Matrix*, s8* );
void    WriteMatrixInMathematicaFormat( FILE*, s8*, Matrix* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLMATRIXOUTPUT_H_
