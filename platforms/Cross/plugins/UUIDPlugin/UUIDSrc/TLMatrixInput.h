/*------------------------------------------------------------
| TLMatrixInput.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to matrix input functions.
|
| DESCRIPTION: 
|        
| NOTE:  
|
| HISTORY: 01.30.00 Separated from 'TLMatrix.c'.
------------------------------------------------------------*/

#ifndef _TLMATRIXINPUT_H_
#define _TLMATRIXINPUT_H_

#ifdef __cplusplus
extern "C"
{
#endif

List*   LoadListOfMatricesAsBinary( FILE* );
Matrix* LoadMatrixAsBinary( s8* );
Matrix* LoadPeriodOfDatedMatrix( s8*, u32, u32 );
Matrix* ReadMatrix( s8* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLMATRIXINPUT_H_
