/*------------------------------------------------------------
| TLEntropy.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to entropy functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 02.02.95 Separated out from 'Statistics.h'.
------------------------------------------------------------*/

#ifndef ENTROPY_H
#define ENTROPY_H

extern f64* pLog2p;

f64     BinaryEntropy( f64 );
f64     BurgEntropyOfItems( f64*, s32 );
f64     CrossEntropy( f64*, f64*, s32 );
f64     CrossEntropy2( f64*, f64*, s32 );
f64     CrossEntropyOfVectors( Vector*, Vector* );
void    DependencyTableEntropyStats( 
            Matrix*, f64*, f64*, f64*, f64*, f64*, f64*,
            f64*, f64* ); 
f64     EntropicMedian( f64 *, s32 );
f64     Entropy( f64 );
f64     EntropyOfColumn( Matrix*, s32 );
f64     EntropyOfColumns( Matrix*, s32, s32 );
f64     EntropyOfConstrainedMatrix( Matrix* );
f64     EntropyOfDeviations( f64*, f64*, s32 );
f64     EntropyOfRegion( Matrix*, s32, s32, s32, s32 );
f64     EntropyOfRow( Matrix*, s32 );
f64     EntropyOfRows( Matrix*, s32, s32 );
f64     EntropyOfMatrix( Matrix* );
f64     EntropyOfMatrixUpwardDiagonals( Matrix* );
f64     EntropyOfItems( f64*, s32 );
f64     EntropyOfItems2( f64*, s32 );
f64     EntropyOfItemsUsingBins( f64 *, s32, s32*, f64 );
f64     EntropyOfNegativeItems( f64*, s32 );
f64     EntropyOfPositiveItems( f64*, s32 );
f64     EntropyOfTrend( f64*, s32 );
f64     EntropyOfTrendWithTimes( f64*, f64*, s32 );
f64     EntropyOfVectorAngles( Vector*, Vector* );
f64     EntropyOfVectorDistances( Vector*, Vector* );
f64     EntropyOfVectors( Vector*, Vector* );
f64     EstimateEntropicMedian( f64*, f64*, f64*, s32 );
f64     EstimateEntropy( f64*, f64*, f64*, s32 );
Matrix* MakeEntropyMatrix( Matrix* );
void    MakepLog2pTable();
f64     MedianEntropyOfMatrix( Matrix* );
void    MovingEntropicMedian( f64*, f64*, f64*, s16*, s16, s16, s16 );
void    MovingEntropy( f64*, f64*, s32, s32 );
void    MovingEstimatedEntropicMedian( f64*, f64*, f64*, f64*,
                                       s32, s32 );
Matrix* OptimizeEntropyOfMatrix( Matrix* , f64, s32 );
void    OptimizeEntropyOfMatrixFile( s8*, s8*, f64, s32 );
f64     Unity( f64, f64, f64, f64 );
f64     VectorUnity( f64 *, f64 *, f64 *, f64 *, s16 );

#endif // ENTROPY_H
