/*------------------------------------------------------------
| TLWeight.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to functions for weighted 
|          collections.
|
| DESCRIPTION:  
| 
| NOTE: 
|
| HISTORY: 07.05.97 collected routines from 'RandomGen.c';
|                   added subrandom variations.
------------------------------------------------------------*/

#ifndef _TLWEIGHT_H_
#define _TLWEIGHT_H_

#ifdef __cplusplus
extern "C"
{
#endif


/*************************************************************/
/*                W E I G H T S   R E C O R D                */
/*************************************************************/
// A general structure for holding weight vectors, of which
// one kind is a probability vector where Sum == 1.
// All weights are non-negative values.
typedef struct
{
    s32     Count;      // Count of all weights.
                        //
    s32     CumCount;   // Count of weights in the cumulative
                        // sum vector.
                        //
    f64     Sum;        // Sum of all weights.
                        //
    f64*    Wt;         // Address of the weights appended to
                        // this record.
                        //
    f64*    CumWt;      // Address of the cumulative sum of
                        // non-zero weights, appended to this
                        // vector. Space is available for all
                        // of the weights but only the non-zero
                        // weights are put into this vector.
                        //
    s32*    CumIndex;   // Index of weights in 'Wt' which 
                        // coorespond to weights in 'CumWt'. 
} Wt;

Wt*     DuplicateWeights( Wt* );
Wt*     MakeWeights( s32 );
s32     PickRandomWeight( Wt* );
s32     PickSubRandomWeight( Wt* );
Wt*     ReadWeightsFromFile( FILE* );
void    SumWeights( Wt* );
void    WriteWeightsToFile( FILE*, Wt* );
void    ZeroWeights( Wt* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLWEIGHT_H_
