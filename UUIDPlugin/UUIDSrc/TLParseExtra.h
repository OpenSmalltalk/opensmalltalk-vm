/*------------------------------------------------------------
| NAME: TLParseTxtra.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to less commonly used parsing 
|          procedures.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 02.15.93 
|          12.31.93 added 'IsByteInString'
|          08.19.97 added C++ support.
|          01.27.00 Split this file off from 'TLParse.h'.
------------------------------------------------------------*/
    
#ifndef _TLPARSEEXTRA_H_
#define _TLPARSEEXTRA_H_

#ifdef __cplusplus
extern "C"
{
#endif

f64     ParseNumber( s8** At );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLPARSEEXTRA_H_
