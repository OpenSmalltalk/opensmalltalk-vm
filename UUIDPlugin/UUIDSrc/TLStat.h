/*------------------------------------------------------------
| TLStat.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to functions for analyzing 
|          data.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 02.19.95 
------------------------------------------------------------*/

#ifndef _STATISTICS_H
#define _STATISTICS_H

// This is the standard that controls how many replications 
// are generated when estimating the median.  200 is generally
// adequate.
extern  s32 TheStandardReplicationCountForEstimateMedian;


void    AddUnitsToBins( s32*, s32*, s32*, s32, f64*, s32, s32 );
void    ApplyToFiles( AnyProcedure, s8** );
void    BidirectionalExponentialMovingAverage( 
            f64*, f64*, s32, f64 );
void    BinCounts( f64*, s16, s16*, s16 );
s32     BinCountsWithFixedBinWidth( f64*,  s32, s32*, f64 );
f64     BlendFactors( f64*, f64*, f64*, s16 );
int     Compare_f64( const void *, const void *);
int     Compare_f64Magnitude( const void *, const void * );
void    CompareEstimateMedians();
void    CompareIntegerSelectors();
s32     ConvertColumnToPattern( Matrix*, s32, s32, s16);
s32     ConvertPatternToItemIndex( s32, u32 *);
s32     ConvertRanksToPattern( f64*, s16 );
void    ConvertValuesToRank( f64*, f64*, s32);
void    ConvertValuesToUniqueRanks( f64*, f64*, s32);
void    DeviationFromMedian( f64*, f64*, s32 );
s16     EstimateClusterCount( f64*, f64*, f64*, s16);
f64     EstimateClusterCount2( f64*, f64*, f64*, s32);
Matrix* EstimateContingencyTable( Matrix* );
void    EstimateDistribution( f64*, f64*, f64*, s32);
void    EstimateDistribution2( f64*, f64*, s32 );
void    EstimateDistribution3( f64*, f64*, f64*, s32);
f64     EstimateMedian( f64*, f64*, s32);
f64     EstimateMedianAndPrecision( f64*, f64*, f64*, f64*, s16);
f64     EstimateMedianDiscrete( f64*, f64*, s32);
void    ExponentialMovingAverage( f64*, f64*, s32, f64 );
void    FilterMatrixFileUsingSampleDistribution( s8*, s8* );
void    FilterUsingSampleDistribution( f64*, f64*, f64*, f64*, s32 );
void    FilterUsingSampleDistribution2( f64*, f64*, f64*, f64*, s32 );
Matrix* FilterMatrixUsingSampleDistribution( Matrix* );
f64     GeometricMean( f64*, s16 );
f64     HighValue( f64*, s32 );
f64     InterpolateLinear( f64*, f64*, f64 );
f64     InterpolateLinearUsingNearestPoints( f64*, f64*, s32, f64);
f64     InterpolateToNearest( f64*, f64*, s32, f64 );
f64     InterpolateUsingRationalFunction( f64*, f64*, s32, f64);
f64     LFME2_TryLine( f64* );
f64     LFME2_TryRadius( f64 );
void    LineFitMaxEnt( Vector*, f64*, f64*, u32   );
void    LineFitMaxEnt2( Vector*, General2DLine*, u32   );
f64     LookUpCoorespondingNumber( f64, f64*, f64*, u32 );
f64     LowValue( f64*, s32 );
f64     Mean( f64*, s32 );
f64     Median( f64*, s32);
f64     Median2( f64*, s32);
f64     Median3( f64*, u32);
u32     MedianByte( u8*, u32 );
void    MedianDataPoint( Matrix*, f64* );
f64     MedianOfColumn( Matrix*, s32 );
void    MedianSpacePoint( Matrix*, f64* );
void    ModeDataPoint( Matrix*, f64* );
f64     ModeOfColumn( Matrix*, s32 );
f64     ModeOfItems( f64*, s32 );
void    ModeSpacePoint( Matrix*, f64* );
void    MovingEntropyOfTrend( f64*, f64*, s32, s32 );
void    MovingEstimatedClusterCount( f64*, f64*, f64*, 
                                     f64*, s16, s16 );
void    MovingEstimatedClusterCount2( f64*, f64*, f64*, f64*, 
                                      s32, s32 );
void    MovingEstimatedMedian( f64*, f64*, f64*, s16, s16 );
Matrix* MovingEstimatedMedianOfMatrix( Matrix*, s16 );
//void  MovingMostConsistentLogPrice( f64*, f64*, s32, s32, s32 ); 
void    MovingPermutationNumber( f64*, f64*, s32, s32 );
void    MovingReversePermutationNumber( f64*, f64*, s32, s32 );
void    MovingTrend( f64*, f64*, s32, s32 );
void    MovingWeight( f64*, f64*, s32, s32 );
void    Resample( f64*, f64*, s16 );
//void  ResampleAndAverage( f64*, f64*, f64*, s16 );
void    ResampleBinCounts( f64*, s16, s16*, s16, s16 );
s16     ResampleBinCountsWithFixedBinWidth( f64*, s16, s16*, f64, s16);
void    ResampleByWeight( f64*, f64*, s16, Wt* );
void    ResampleVector( Vector*, Vector* );
s32     SelectBin( f64*, s32 );
f64     SelectNthSmallest( f64* AtItem, s32 ItemCount, s32 N );
Matrix* SmoothMatrix( Matrix*, s16 );
Matrix* SmoothMatrixDiagonal( Matrix*, s16 );
Matrix* SmoothMatrixEstimatedMedian( Matrix*, s16 );
Matrix* SmoothMatrixEstimatedMedianDiscrete( Matrix*, s16 );
void    SmoothMatrixFile( s8*, s8*, s32 );
Matrix* SmoothMatrixVertical( Matrix*, s32 );
void    SortVector( f64*, u32 );
f64     StandardDeviation( f64*, s32 );
f64     Variance( f64*, s32 );
void    WeightedMovingAverage( f64*, f64*, s16, f64*, s16);

#endif // _STATISTICS_H
