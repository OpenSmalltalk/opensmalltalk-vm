/*------------------------------------------------------------
| TLStat.c
|-------------------------------------------------------------
|
| PURPOSE: To provide functions for analyzing data.
|
| HISTORY: 02.19.95 
|          01.24.96 Separated out data sampling procedures to
|                   'Sample.c'.
|          02.02.96 Separated out entropy procedures to
|                   'Entropy.c'.
------------------------------------------------------------*/

#include "TLTarget.h" 

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
 
#ifdef macintosh
#include <QuickDraw.h>
#include <TextEdit.h>
#endif

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStrings.h"
#include "TLRandom.h"
#include "TLSubRandom.h"
#include "TLList.h"
#include "TLFile.h"
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLf64.h"
#include "TLNumber.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixInput.h"
#include "TLMatrixOutput.h"
#include "TLMatrixCopy.h"
#include "TLEntropy.h"
#include "TLPoints.h"
#include "TLComplexNumber.h"
#include "TLOptimize.h"
#include "TLGeometry.h"

#ifdef macintosh
#include "TLGraph.h"
#endif

#include "TLOrdinal.h"
#include "TLPointList.h"
#include "TLArray.h"
#include "TLExtent.h"
#include "TLCombinatorics.h"
#include "TLStacks.h"
#include "TLWin.h"
#include "TLWeight.h"
#include "TLTls.h"
#include "TLStat.h"

// This is the standard that controls how many replications 
// are generated when estimating the median.  200 is generally
// adequate.
s32 TheStandardReplicationCountForEstimateMedian = 200;

/*------------------------------------------------------------
| AddUnitsToBins
|-------------------------------------------------------------
|
| PURPOSE: To add a given number of units to a series
|          of bins whose chance of selection is determined by 
|          their weights.
|
| DESCRIPTION: The weighting of bins is controlled by the 
| 'Division' array which specifies the subdivision of the 
| range between 0 and 1.  If a subrandomly generated number 
| falls between two divisions cooresponding to a bin, than 
| that bin is selected and a unit is added to that bin.
|
| The process is repeated many times bootstrap fashion to
| arrive at the most probable result.
|
| If 'UnitSize' is negative then units will be subtracted
| from the bins instead of being added.
|
| The 'WorkBin' array is a work space that must be the same
| size as the 'Bin' array.
|
| The resulting bins are returned in 'ResultBin'.
|
| EXAMPLE: Three bins with weights .2, .2 and .6 contain
| 30, 10 and 50 units.  Subtract 12 units from the bins.
|
|   s32  Bin[3];
|   s32  WorkBin[3];
|   s32  ResultBin[3];
|   f64 Div[2]; // The number of divisions needed is one
|                // less than the number of bins.
|
|   Bin[0] = 30;
|   Bin[1] = 10;
|   Bin[2] = 50;
|
|   Div[0] = .2; // Any number <= .2 selects bin 0.
|   Div[1] = Div[0] + .2; 
|
|   AddUnitsToBins( Bin, WorkBin, ResultBin, 3, 
|                   Div, 12, -1 );
|
| NOTE: 
|
| ASSUMES: Subrandom number generator has been set up.
|          'Division' array is sorted in increasing order.
|
|          The bin counts * Replication count is less than
|          the capacity of an 's32', about 2 billion.
|
| HISTORY: 01.30.95
------------------------------------------------------------*/
void
AddUnitsToBins( 
    s32*  Bin, 
    s32*  WorkBin, 
    s32*  ResultBin,
    s32   BinCount, 
    f64* Division,
    s32   UnitCount,
    s32   UnitSize )
{
    s32  i, j, r;
    s32  TheBin;
    s32  *To, *From;
    s32  ReplicationCount;
    
    ReplicationCount = 10; // DEFER 256;
    
    // Clear the result bins.
    To = ResultBin;
    for( i = 0; i < BinCount; i++ )
    {
        *To++ = 0;
    }

    // Repeat the addition many times bootstrap fashion.
    for( r = 0; r < ReplicationCount; r++ )
    {
        // Copy the input bin counts to the working bin
        // array.
        From = Bin;
        To   = WorkBin;
        for( i = 0; i < BinCount; i++ )
        {
            *To++ = *From++;
        }
        
        // Add each unit to the working bins.
        for( j = 0; j < UnitCount; j++ )
        {
SelectTheBin:
            TheBin = SelectBin( Division, BinCount );
            
            // If adding OR if subtracting and 
            // there is a unit in the bin to subtract.
            if( UnitSize > 0 ||
                ( UnitSize < 0 && WorkBin[TheBin] > UnitSize ) )
            {
                WorkBin[TheBin] += UnitSize; // Add a unit.
            }
            else // Select another bin.
            {
                goto SelectTheBin;
            }
        }
        
        // Accumulate the bootstrap totals in the result
        // array.
        From = WorkBin;
        To   = ResultBin;
        for( i = 0; i < BinCount; i++ )
        {
            *To++ += *From++;
        }
    }
    
    // Find mean value of replications.
    To = ResultBin;
    for( i = 0; i < BinCount; i++ )
    {
        *To++ /= ReplicationCount;
    }
}

/*------------------------------------------------------------
| ApplyToFiles
|-------------------------------------------------------------
|
| PURPOSE: To apply a procedure to a set of data files.
|
| DESCRIPTION:
|
| EXAMPLE:  
|      ApplyToFiles( Generate2_63Samples, NG2_63PathNames );
|
| NOTE: 
|
| ASSUMES: List of path names is 0-terminated.
|
| HISTORY: 07.27.95 
------------------------------------------------------------*/
void
ApplyToFiles( AnyProcedure AProcedure, char** AtPathNames )
{
    s16 i;

    i = 0;
    
    // For each file in the set.
    while( AtPathNames[i] )
    {
         ( ( void (*)(char*) ) *AProcedure)( AtPathNames[i] );
        i++;
    }
}

/*------------------------------------------------------------
| BidirectionalExponentialMovingAverage
|-------------------------------------------------------------
|
| PURPOSE: To compute an bidirectional exponential moving 
|          average (BEMA) function for a list of values.
|
| DESCRIPTION: Returns a list of values the same length as the
| input. 
|
| 'K' is a value between 0.0 and 1.0 that controls the amount
| of relative weighting between the current value and the last
| EMA value.
|
|                   (( Value(t) * K + (1-K) * EMAf(t-1) ) +
|                    ( Value(t) * K + (1-K) * EMAb(t+1) ))
|       BEMA(t) =   --------------------------------------
|                                      2 
|
| Where 'EMAf' is forward going EMA value and
|       'EMAb' is backward going EMA value.
|
| EXAMPLE:  Find the exponential moving average 
| of copper:
|
|  BidirectionalExponentialMovingAverage( 
|        Dec92Copper, Out, ItemCount, .5 );
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY:  03.02.96
------------------------------------------------------------- */
void
BidirectionalExponentialMovingAverage( 
    f64* InputVector, 
    f64* OutputVector,
    s32   ItemCount, 
    f64  K )
{
    s32     i;
    f64 EMAf;
    f64 EMAb;
    f64 *Inf;
    f64    *Inb;
    f64 *Outf;
    f64    *Outb;
    f64    OneMinusK;
    
    OneMinusK = 1.0 - K;
    
    // Refer to the start and end of each list of values.
    Inf  = InputVector;
    Inb  = &InputVector[ItemCount-1];
    Outf = OutputVector;
    Outb = &OutputVector[ItemCount-1];
    
    // Do the forward direction EMA first.
    // The first value is the same as input.
    EMAf    = *Inf++;
    *Outf++ = EMAf;
    
    // Compute remaining values.        
    for( i = 1; i < ItemCount; i++ )
    {
        EMAf = (*Inf++ * K) + (OneMinusK*EMAf);
        
        *Outf++ = EMAf;
    }
    
    // Do the backward direction EMA next, summing and 
    // averaging the values.
    // The first value is the same as input.
    EMAb    = *Inb--;
    *Outb   = (*Outb + EMAb)/2.0; 
    Outb--;
    
    // Compute remaining values.        
    for( i = 1; i < ItemCount; i++ )
    {
        EMAb = (*Inb-- * K) + (OneMinusK*EMAb);
        
        *Outb = (*Outb + EMAb)/2.0; 
        
        Outb--;
    }
}

/*------------------------------------------------------------
| BinCounts
|-------------------------------------------------------------
|
| PURPOSE: To count how many samples of a list fall into a
|          number of evenly spaced bins.
|
| DESCRIPTION: Results in a list of counts, one for each bin.
|              Each count field is 2 bytes long.
|
| EXAMPLE:  
|           BinCounts( MyData, SampleCount, ResultBuffer, 10 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.13.95 
------------------------------------------------------------*/
void
BinCounts( f64* AtData, s16 SampleCount, 
           s16*  AtBins, s16 BinCount )
{
    f64  ASample;
    f64  BinSize;
    f64  MinSample;
    f64  MaxSample;
    f64  OverallRange;
    f64* AtSample;
    s16*  AtBin;
    s16   i;
    s16   bin;
    
    // Clear the bin counters to zero.
    AtBin = AtBins;
    for( i = 0; i < BinCount; i++ )
    {
        *AtBin++ = 0;
    }
    
    // Find the minimum and maximum values to define
    // the range to be subdivided.
    
    AtSample = AtData;
    
    // Start with the first value and adjust.
    MinSample = *AtSample++;
    MaxSample = MinSample;
    
    for( i = 1; i < SampleCount; i++ )
    {
        ASample = *AtSample++;
        
        if( ASample < MinSample )  MinSample = ASample;
        if( ASample > MaxSample )  MaxSample = ASample;
    }
    
    OverallRange = MaxSample - MinSample;
    BinSize      = OverallRange / BinCount;
    
    // For each sample
    AtSample = AtData;
    for( i = 0; i < SampleCount; i++ )
    {
        ASample = *AtSample++;
    
        bin = (s16) ( (ASample - MinSample) / BinSize );
        
        AtBins[bin]++;
    }
}

/*------------------------------------------------------------
| BinCountsWithFixedBinWidth
|-------------------------------------------------------------
|
| PURPOSE: To count how many samples of a list fall into
|          bins of a certain width that range over all the
|          samples.
|
| DESCRIPTION: Results in a list of counts, one for each bin.
|              Each count field is 2 bytes long.
|              Returns the number of bins.
|
| EXAMPLE:  
|           
|   c = BinCountsWithFixedBinWidth( 
|               MyData, SampleCount, ResultBuffer, .045 );
|
| NOTE: 
|
| ASSUMES: 'ResultBuffer' refers to an area large enough for
|          all of the bin counts.
|
| HISTORY: 07.30.95 
------------------------------------------------------------*/
s32
BinCountsWithFixedBinWidth( f64* AtData, 
                            s32   SampleCount, 
                            s32*  AtBins,
                            f64  BinWidth )
{
    f64     ASample;
    f64     MinSample;
    f64     MaxSample;
    f64     OverallRange;
    f64*    AtSample;
    s32*    AtBin;
    s32     i;
    s32     bin;
    s32     BinCount;
    
    // Find the minimum and maximum values to define
    // the range to be subdivided.
    
    AtSample = AtData;
    
    // Start with the first value and adjust.
    MinSample = *AtSample++;
    MaxSample = MinSample;
    
    for( i = 1; i < SampleCount; i++ )
    {
        ASample = *AtSample++;
        
        if( ASample < MinSample )  MinSample = ASample;
        if( ASample > MaxSample )  MaxSample = ASample;
    }
    
    OverallRange = MaxSample - MinSample;
    
    // Calculate the number of bins.
    BinCount = (s16) ceil( OverallRange / BinWidth );
    
    // Clear the bin counters to zero.
    AtBin = AtBins;
    for( i = 0; i < BinCount; i++ )
    {
        *AtBin++ = 0;
    }
    
    // For each sample
    AtSample = AtData;
    for( i = 0; i < SampleCount; i++ )
    {
        ASample = *AtSample++;
    
        bin = (s16) ( (ASample - MinSample) / BinWidth );
        
        AtBins[bin]++;
    }
    
    return( BinCount );
}

/*------------------------------------------------------------
| BlendFactors
|-------------------------------------------------------------
|
| PURPOSE: To combine the many factors of an estimate into the
|          one estimate value.
|
| DESCRIPTION: A list of factors are input and a single value
|              is returned.  This is a weighted average.
|
|              Each factor consists of three numbers:
|
|              { Base, Scale, Weight }
|
|              combined in the following way with other
|              factors to produce an estimate:
|
|                        (Base[1] X Scale[1] X Weight[1]) +
|                        (Base[2] X Scale[2] X Weight[2]) ...
|           Estimate =  ------------------------------------
|                             ( Sum of all weights) 
|
|              The 'Base' value is that source taken as
|              a basis for the estimate.  It must be united
|              with the value being estimated in some way
|              in order for the estimate to have any meaning.
|
|              The 'Scale' is a measure of the scale relation
|              between the base value and the estimate.  In
|              the absence of other factors:
|    
|                         Scale = Estimate / Base 
|
|              so that when the scale is multiplied by the
|              base, the base units cancel and the 
|              units of the estimated value remain.
|
|              The 'Weight' is the degree to which one
|              factor prevails over another: the higher
|              the weight of one factor relative to another,
|              the more that factor will figure in the
|              result. 
|           
| EXAMPLE: Estimate price of gold from silver and copper 
|          given that:
|
|             copper is $1.09, is usually about
|                    1/370th the price of gold and is
|                    related to gold by a unity factor of 
|                    .8
|
|             silver is $5.10, is usually about 1/200th
|                    the price of gold and is related
|                    to gold by a unity factor of .93.
|
|        double Base[2] = { 1.09, 5.10 };
|        double Scale[2] = { 370, 70 };
|        double Weight[2] = { .8, .93 };
|        GoldEst = BlendFactors( Base, Scale, Weight, 2);
|
|        ans = 378.4104
|
| NOTE: 
|
| EXAMPLE: 
|
| ASSUMES: Input values are unsigned values.
|
| HISTORY: 10.01.94 
|          10.24.94 converted to MATLAB.
|          10.26.94 sped up.
|          12.18.94 converted to C mexFunction.
|          12.26.94 revised interface.
-----------------------------------------------------------*/
f64
BlendFactors(
    f64 *Base,
    f64 *Scale,
    f64 *Weight,
    s16  FactorCount )
{
    f64  Result;
    f64  SumOfRowProducts;
    f64  SumOfWeights;
    s16   i;
    
    // Set up accumulators.
    SumOfRowProducts = 0;
    SumOfWeights     = 0;
    
    for( i = 0; i < FactorCount ; i++ )
    {
        SumOfRowProducts +=
            *Base * *Scale * *Weight;
        
        SumOfWeights += *Weight;
    
        // Advance to the next row.
        Base++;
        Scale++;
        Weight++;
    }
    
    Result = SumOfRowProducts / SumOfWeights;
    
    return( Result );
}

/*------------------------------------------------------------
| Compare_f64
|-------------------------------------------------------------
|
| PURPOSE: To compare two f64's.
|
| DESCRIPTION: A standard comparison function for use with
|              'qsort'.
|
| EXAMPLE:   
|
| NOTE: See also 'CompareItems' a similar routine for use
|       with 'SortList'.
|
| ASSUMES: 
|
| HISTORY: 12.24.95 
|          12.26.95 fixed truncation error.
------------------------------------------------------------*/
int
Compare_f64( const void * A, const void * B )
{
    f64 a,b;
    int     r;
    
    a = *((f64*) A);
    b = *((f64*) B);
    
    if( a > b )
    {
        r = 1;
    }
    else
    {
        if( a < b )
        {
            r = -1;
        }
        else
        {
            r = 0;
        }
    }

    return( r );
}

/*------------------------------------------------------------
| Compare_f64Magnitude
|-------------------------------------------------------------
|
| PURPOSE: To compare two f64's based on their unsigned 
|          magnitude.
|
| DESCRIPTION: A standard comparison function for use with
|              'qsort'.
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 08.08.96 from 'Compare_fl64'
|          12.26.95 fixed truncation error.
------------------------------------------------------------*/
int
Compare_f64Magnitude( const void * A, const void * B )
{
    f64 a,b;
    int     r;
    
    a = *((f64*) A);
    b = *((f64*) B);
    
    // Convert signed to unsigned.
    if( a < 0 ) a = -a;
    if( b < 0 ) b = -b;
    
    if( a > b )
    {
        r = 1;
    }
    else
    {
        if( a < b )
        {
            r = -1;
        }
        else
        {
            r = 0;
        }
    }

    return( r );
}

#if 0
/* ------------------------------------------------------------
| CompareEstimateMedians
|-------------------------------------------------------------
|
| PURPOSE: To compare the resampling methods used in estimating
|          the median to find out which converges more 
|          efficiently.
|
| DESCRIPTION: Prints out a report listing the number of 
| replications versus the median values arrived at using
| two different methods of resampling:
|
|       <RepCount><RandomMedian><SubRandomMedian>
|           
| Graph the results to see which converges faster.
|
| The sample data set comes from 'NG96G' closing prices.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 'BeginSubRandomSequence' called before this routine.
|
| HISTORY: 01.29.96 from 'EstimateMedian'.
-----------------------------------------------------------*/
void
CompareEstimateMedians()
{
    s16 SampleCount;
    f64 RandomMedian;
    f64 SubRandomMedian;
    f64
    Sample[] =
    { 
        1.784, 1.775, 1.787, 1.797, 1.804,
        1.798, 1.822, 1.815, 1.806, 1.825,
        1.817, 1.807, 1.803, 1.809, 1.825,
        1.810, 1.822, 1.831, 1.831, 1.811,
        1.833, 1.823, 1.852, 1.844, 1.843,
        1.823, 1.823, 1.837, 1.843, 1.832,
        1.852, 1.827, 1.835, 1.824, 1.833,
        1.830, 1.831, 1.839, 1.856, 1.862
    };
    
    f64 Replication[40];
    
    SampleCount = 40;
    
    BeginSubRandomSequence(0); // Needed for 'ResampleSubRandom'.
    SetUpRandomNumberGenerator(12314L); // Needed for 'Resample'.
    
    for( TheStandardReplicationCountForEstimateMedian = 1;
         TheStandardReplicationCountForEstimateMedian < 1000;
         TheStandardReplicationCountForEstimateMedian++ )
    {
        RandomMedian = 
            EstimateMedian(
                Sample,
                Replication,  // A work space as big as sample space.
                SampleCount );

        SubRandomMedian = 
            EstimateMedianSubRandom( // <-- no longer exists.
                Sample,
                Replication,  // A work space as big as sample space.
                SampleCount );

        printf( "%10.5d\t%10.5f\t%10.5f\n",
                TheStandardReplicationCountForEstimateMedian,
                RandomMedian,
                SubRandomMedian );
    }
}
#endif

/*------------------------------------------------------------
| CompareIntegerSelectors
|-------------------------------------------------------------
|
| PURPOSE: To compare the integer selection methods to find 
|          out if they contain a bias.
|
| DESCRIPTION: Prints out a report listing the series of
| integers selected using the random number generator and the
| sub-random sequencer.
|
|   <Integer> <RandomIntegerCount><SubRandomIntegerCount>
|           
| Look at the histogram of the results to determine bias.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 'BeginSubRandomSequence' called before this routine.
|
| HISTORY: 01.29.96 from 'EstimateMedian'.
-----------------------------------------------------------*/
void
CompareIntegerSelectors()
{
    s32 SampleCount;
    s32 i;
    s32 RandomSampleCount[40];
    s32 SubRandomSampleCount[40];
    
    SampleCount = 40;
    
    BeginSubRandomSequence(0); // Needed for 'ResampleSubRandom'.
    SetUpRandomNumberGenerator(12314L); // Needed for 'Resample'.

    for( i = 0; i < SampleCount; i++ )
    {
        RandomSampleCount[i] = 0;
        SubRandomSampleCount[i] = 0;
    }
    
    for( i = 1; i < 10000000; i++ )
    {
        RandomSampleCount[ RandomInteger(SampleCount) ]++;
        SubRandomSampleCount[ SubRandomInteger(SampleCount) ]++;

    }
    
    for( i = 0; i < SampleCount; i++ )
    {
        printf( "%10.5d\t%10.5d\t%10.5d\n",
                i,
                RandomSampleCount[i],
                SubRandomSampleCount[i] );
    }
    
}

/*------------------------------------------------------------
| ConvertColumnToPattern
|-------------------------------------------------------------
|
| PURPOSE: To convert part of a column of numbers in an array
|          into to a unique pattern number.
|
| DESCRIPTION: Range of cells is given by specifying the row
| and column of the last cell in the range and a cell count.
|
| EXAMPLE:  p = ConvertColumnToPattern( 
|                    MyMatrix, ARow, AColumn, 4 );
|
| NOTE: 
|
| ASSUMES: Cell count is less than 10.
|
| HISTORY: 02.19.95 
------------------------------------------------------------*/
s32
ConvertColumnToPattern( Matrix* AMatrix,
                        s32     ARow,
                        s32     AColumn,
                        s16     CellCount )
{
    f64 Values[10];
    f64 Ranks[10];
    s32     RowOfCell;
    s32     Pattern;
    s16     i;
    f64**   A;
    
    RowOfCell = ARow - CellCount + 1;
    
    A = (f64**) AMatrix->a;
    
    for( i = 0; i < CellCount; i++ )
    {
        Values[i] = A[ RowOfCell ][ AColumn ];
        RowOfCell++;
    }
    
    ConvertValuesToRank( Values, Ranks, (s32) CellCount );

    Pattern = ConvertRanksToPattern( Ranks, CellCount );
    
    return( Pattern );
}
    
/*------------------------------------------------------------
| ConvertPatternToItemIndex
|-------------------------------------------------------------
|
| PURPOSE: To find the index of an item in an array of a 
|          certain size list that cooresponds to a bit pattern.
|
| DESCRIPTION: Uses bits of the pattern to control the 
| subdivision of the array into equal sections until a single
| entry is defined.  
|
| Returns the 0-based index of the entry and an updated bit 
| pattern representing unconsumed bits.
|
| Uses bits of the pattern from least-significant to most.
|
| EXAMPLE:  
|
| i = ConvertPatternToItemIndex( ItemCount, &BitPattern );
|
| NOTE: This routine was thought to be a building block to
|       'NthPermutation' but doesn't work in that role.
|       Left here because the subdivision search may be useful
|       in another incarnation.
|
| ASSUMES: 
|
| HISTORY: 12.08.95 .
------------------------------------------------------------*/
s32
ConvertPatternToItemIndex( s32 ItemCount, u32 *BitPattern )
{
    s32     Lo,Mid,Hi;
    u32     Bit;
    u32     Bits;
    
    Bits = *BitPattern;
        
    Lo = 0;  
    Hi = ItemCount - 1;
    
    while( Lo < Hi )
    {
        Mid = (Hi + Lo) >> 1;  // (Hi+Lo)/2  

        Bit = Bits & 1;        // Pick out the right-most bit.
        
        Bits >>= 1;            // Shift right to consume the bit.    
        
        if( Bit == 0 )         // Entry is in lower section.
        {                      // The lower section includes
            Hi = Mid;          // the midpoint, it's the top
                               // of the lower section.
        }
        else // Bit == 1, so entry is in higher section.
        {    // (Mid + 1) is the bottom entry in the top
             // section.
            Lo = Mid + 1;
        }
    }
    
    // At this point Lo == Hi: the entry has been found.
    
    *BitPattern = Bits; // Update the given bit pattern.
    
    return( Lo );       // Return the entry index.
}

/*------------------------------------------------------------
| ConvertRanksToPattern
|-------------------------------------------------------------
|
| PURPOSE: To convert a set of rank order values to a unique
|          pattern number.
|
| DESCRIPTION: Builds a decimal number by using each rank
| value as a digit.  The first rank cell becomes the highest
| order digit.
|
| EXAMPLE:  p = ConvertRanksToPattern( &Ranks, ACount );
|
| NOTE: 
|
| ASSUMES: Number of ranks is less than 10 digits.
|
| HISTORY: 02.19.95 
------------------------------------------------------------*/
s32
ConvertRanksToPattern( f64* Ranks, s16 ACount )
{
    s16     i;
    s32     Pattern;
    
    Pattern = 0;
    i       = 0;
    switch( ACount )
    {
        case(9): Pattern += (s32) Ranks[i]*100000000; i++;
        case(8): Pattern += (s32) Ranks[i]*10000000; i++;
        case(7): Pattern += (s32) Ranks[i]*1000000; i++;
        case(6): Pattern += (s32) Ranks[i]*100000; i++;
        case(5): Pattern += (s32) Ranks[i]*10000; i++;
        case(4): Pattern += (s32) Ranks[i]*1000; i++;
        case(3): Pattern += (s32) Ranks[i]*100; i++;
        case(2): Pattern += (s32) Ranks[i]*10; i++;
        case(1): Pattern += (s32) Ranks[i];
    }
    
    return( Pattern );
}

/*------------------------------------------------------------
| ConvertValuesToRank
|-------------------------------------------------------------
|
| PURPOSE: To convert a set of values to their cooresponding 
|          rank numbers.
|
| DESCRIPTION: The smallest value has a rank of 1 and 
| duplicate values receive the same rank number.
|
| EXAMPLE:  ConvertValuesToRank( &Values, &Ranks, VCount );
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 01.22.95 
------------------------------------------------------------*/
void
ConvertValuesToRank( f64* AtValues, f64* AtRanks, s32 Count )
{
    s32     CurrentRank;
    s32     RankedCount;
    f64     *AtV;
    u32     SmallestFound;
    f64 Smallest;
    f64 *AtR;
    s32     i;
    
    // Start with rank 1.
    CurrentRank = 1;
    RankedCount = 0;

    // Fill 'AtRanks' array with zeros to mark ranks as undefined.
    AtR = AtRanks;
    i = Count;
    while( i-- )
    {
        *AtR++ = 0;
    }

    // Until each value is ranked.
    while( RankedCount < Count )
    {
        // Find the smallest un-ranked value in Values array.
        SmallestFound = 0;
        AtR = AtRanks;
        AtV = AtValues;
        i = Count;
        while( i-- )
        {
            if( *AtR == 0 &&             // unranked
                ((SmallestFound == 0) || // none found yet or
                 (*AtV < Smallest)) )    // this one smaller
            {
                Smallest = *AtV;
                SmallestFound++;
            }
            AtR++;
            AtV++;
        }

        // Give all values equal to the smallest the current rank.
        AtR = AtRanks;
        AtV = AtValues;
        i = Count;
        while( i-- )
        {
            if( *AtV == Smallest )
            {
                *AtR = CurrentRank;
                RankedCount++;
            }
            AtR++;
            AtV++;
        }
        
        // Increment the rank number.
        CurrentRank++;
    }
}

/*------------------------------------------------------------
| ConvertValuesToUniqueRanks
|-------------------------------------------------------------
|
| PURPOSE: To convert a set of values to their cooresponding 
|          rank numbers.
|
| DESCRIPTION: The smallest value has a rank of 1 and 
| duplicate values receive a unique rank number.
|
| EXAMPLE:  ConvertValuesToUniqueRank( &Values, &Ranks, VCount );
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 12.24.95 .
|          12.26.95 adjusted 0-based rank to be 1-based.
------------------------------------------------------------*/
void
ConvertValuesToUniqueRanks( f64* AtValues, 
                            f64* AtRanks, 
                            s32   Count )
{
    f64     *AtV;
    f64 *AtR;
    s32     i, index;
    f64*   AtRecords;
    f64 LocalRecords[ 64 ];
    s32     RecordSize;
    
    // How big each value:index record is.
    RecordSize = sizeof(f64) * 2;
    
    if( Count > 32 )
    {
        // Allocate memory for value:index records.
        AtRecords = (f64*) malloc( Count * RecordSize );
    }
    else // Use local storage.
    {
        AtRecords = &LocalRecords[0];
    }
    
    // Fill the records with values and array indices.
    AtR = AtRecords;
    AtV = AtValues;
    for( i = 0; i < Count; i++ )
    {
        *AtR++ = *AtV++;
        *AtR++ = (f64) i;
    }
    
    // Sort the records in increasing order.
    qsort( (void*)  AtRecords,
           (size_t) Count,
           (size_t) RecordSize,
           Compare_f64 );
           
    // Walk through the sorted records to set the ranks of
    // the values.
    AtR = AtRecords;
    for( i = 0; i < Count; i++ )
    {
        // Skip over value.
        AtR++;
        
        // Find the original index.
        index = (s32) *AtR++;
        
        // Set the rank.
        AtRanks[ index ] = i + 1;
    }
    
    if( Count > 32 )
    {
        // Free the records.
        free( (u8*) AtRecords );
    }
}

    
/*------------------------------------------------------------
| DeviationFromMedian
|-------------------------------------------------------------
|
| PURPOSE: To compute the absolute deviations from the median.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
|
| HISTORY: 06.24.97
------------------------------------------------------------*/
void
DeviationFromMedian( f64* Input, f64* Devs, s32 Count )
{
    f64 Med, Dev;

    // Compute the median value.
    Med = Median2( Input, Count );
    
    // For each input value.
    while( Count-- )
    {
        // Compute the absolute deviation from the median.
        Dev = *Input++ - Med;
        
        if( Dev < 0. ) Dev = -Dev;
        
        *Devs++ = Dev;
    }
}

/*------------------------------------------------------------
| EstimateDistribution
|-------------------------------------------------------------
|
| PURPOSE: To resample a vector, sort and average the results
|          many times to produce an estimate of the 
|          distribution from which the vector was derived.
|
| DESCRIPTION: Expects the address of a vector, address of
| a replication workspace, the address where the result
| vector is to be put, and a count of entries in the vector. 
|
| The resulting distribution is in increasing order with
| the median value found at the half way point.
|
| EXAMPLE:  
|
| EstimateDistribution( AtSample, AtReplication, 
|                       AtResult, ItemCount );
|
| NOTE: See "An Introduction to the Bootstrap" for complete 
|       explanation. Underestimates the extremes.
|
| ASSUMES: 'BeginSubRandomSequence' called.
|
|
| HISTORY: 06.22.95 .
------------------------------------------------------------*/
void
EstimateDistribution( f64* AtSample, 
                      f64* AtReplication, 
                      f64* AtResult, 
                      s32   ItemCount )
{
    s32  i, j;
    f64 *s, *d;
    
    // Clear the result accumulator.
    d = AtResult;
    for( i = 0; i < ItemCount; i++ )
    {
        *d++ = 0.0;
    }
    
    // Accumulate 200 sorted resamples.
    for( j = 0; j < 200; j++ )
    {
        Resample( AtSample, AtReplication, ItemCount );
        
        SortVector( AtReplication, ItemCount );
        
        s = AtReplication;
        d = AtResult;
        
        for( i = 0; i < ItemCount; i++ )
        {
            *d++ += *s++;
        }
    }
    
    // Average the results.
    d = AtResult;
    
    for( i = 0; i < ItemCount; i++ )
    {
        *d++ /= 200;
    }
}

/*------------------------------------------------------------
| EstimateDistribution2
|-------------------------------------------------------------
|
| PURPOSE: To estimate the distribution from which the vector 
|          was derived given the vector.
|
| DESCRIPTION: Makes small changes to the distribution to
| arrive at the maximum entropy distribution of the sample.
|
| Expects the address of a vector, address of
| a replication workspace, the address where the result
| vector is to be put, and a count of entries in the vector. 
|
| The resulting distribution is in increasing order with
| the median value found at the half way point.
|
| EXAMPLE:  
|
| EstimateDistribution2( AtSample, AtReplication, 
|                        AtResult, ItemCount );
|
| NOTE: This method is biased toward high values at the 
|       expense of low values.  Add constraint for low
|       and high means.
|
| ASSUMES: 'BeginSubRandomSequence' called.
|
|
| HISTORY: 02.19.95 from 'EstimateDistribution'.
------------------------------------------------------------*/
void
EstimateDistribution2( f64* AtSample, 
                       f64* AtResult, 
                       s32   ItemCount )
{
#if macintosh
    s32  i, a, b, c, Pass, FinalPass;
    s32  MaxPassesSinceLastChange;
    f64 *s, *dd;
    f64 BestEntropy, NewEntropy;
    f64 ChangeUnit, ShiftUnit;
    f64 *SaveValues;
    s32  ChangeItemCount;
    s32  *ItemVisit;
    f64 LowMean, NewLowMean;
    f64 HighMean, NewHighMean;
    
    // Change half of the items on each pass.
    ChangeItemCount = ItemCount/2;
    
    // Calculate the size of the change unit to be used
    // for variation.
    ChangeUnit = ( HighValue( AtSample, ItemCount) -
                   LowValue( AtSample, ItemCount) ) / 
                   (ItemCount*ChangeItemCount);

    // Allocate the vector for values of changed items.
    SaveValues = (f64*) malloc( ChangeItemCount * sizeof( f64 ));
    
    // This is used to detect leveling off of entropy.
    MaxPassesSinceLastChange = ItemCount/2;
    
    // Default result is the sample, copy it to the result.
    s = AtSample;
    dd = AtResult;
    for( i = 0; i < ItemCount; i++ )
    {
        *dd++ = *s++;
    }

    // Sort the sample.
    SortVector( AtResult, ItemCount );
    
    // Calculate the mean of the lower half.
    LowMean = Mean( AtResult, ItemCount/2 );
    
    // Calculate the mean of the upper half.
    HighMean = Mean( &AtResult[ ItemCount/2 ], 
                     ItemCount - ItemCount/2 );

    // Calculate the entropy of the sample.
    BestEntropy = 0; // TBD
//      DistanceOfEachToEachSum( AtResult, ItemCount );
//TBD           EntropyOfItems( AtResult, ItemCount );
//          ParityOfVector( AtResult, ItemCount );
    
    // Allocate a vector to hold the item visit list.
    ItemVisit = (s32*) malloc( ItemCount * sizeof(s32) );

    // Populate the visit list.
    for( i = 0; i < ItemCount; i++ )
    {
        ItemVisit[i] = i;
    }
    
    // Begin by shifting up.
    ShiftUnit = ChangeUnit;
    
    Pass = 1;
    FinalPass = MaxPassesSinceLastChange;
    
    while( Pass++ )
    {
        // Shuffle the item visit list.
        for( i = 0; i < ItemCount; i++ )
        {
            a = SubRandomInteger( ItemCount );
            b = SubRandomInteger( ItemCount );
        
            // Exchange the indices. 
            c = ItemVisit[a]; 
            ItemVisit[a] = ItemVisit[b];
            ItemVisit[b] = c;
        }

        // Use the first section of the visit list
        // to make a change.
        for( i = 0; i < ChangeItemCount; i++ )
        {
            // Refer to the item that changes.
            a = ItemVisit[i];
            
            // Preserve the values.
            SaveValues[i] = AtResult[a];
            
            // Shift the value.
            AtResult[a] += ShiftUnit;
        }
                
    // Sort the sample.
    SortVector( AtResult, ItemCount );
    
    // Calculate the mean of the lower half.
    NewLowMean = Mean( AtResult, ItemCount/2 );
    
    // Calculate the mean of the upper half.
    NewHighMean = Mean( &AtResult[ ItemCount/2 ], 
                     ItemCount - ItemCount/2 );

        // Measure the entropy.
        NewEntropy = 0;//TBD
//          DistanceOfEachToEachSum( AtResult, ItemCount );
//TBD           EntropyOfItems( AtResult, ItemCount );
//          ParityOfVector( AtResult, ItemCount );
        
        // Check to see if this is an improvement.  
        if( NewLowMean  >= LowMean &&
            NewHighMean <= HighMean &&
            NewEntropy  > BestEntropy )
        {
if( (Pass % 100) == 0 ) printf( "%d %10.5f\n", Pass, NewEntropy );

            // Keep the new distribution.
            BestEntropy = NewEntropy;
            
            // Reverse the shift direction.
            ShiftUnit = -ShiftUnit;
            
            // Reset the detector for entropy leveling off.
            FinalPass = Pass + MaxPassesSinceLastChange;
        }
        else // Discard the change.
        {
            for( i = 0; i < ChangeItemCount; i++ )
            {
                // Refer to the item that changes.
                a = ItemVisit[i];
            
                // Restore the values.
                AtResult[a] = SaveValues[i];
            }
            
            // Check for entropy leveling off.
            if( Pass > FinalPass || Pass > 50000 )
            {
                printf("\nNo entropy improvement after %d passes.\n", 
                       FinalPass - MaxPassesSinceLastChange);
                       
                goto Done;
            }
        }
        
        if(Button())
        {
            Debugger();
        }
    }

Done:
    
    // Sort the result in increasing order.
    SortVector( AtResult, ItemCount );
    
    // Discard the dynamic data.
    free( SaveValues );
    free( ItemVisit );
#endif // macintosh
}

/*------------------------------------------------------------
| EstimateDistribution3
|-------------------------------------------------------------
|
| PURPOSE: To resample a vector, sort and average the results
|          many times to produce an estimate of the 
|          distribution from which the vector was derived.
|
| DESCRIPTION: Expects the address of a vector, address of
| a replication workspace, the address where the result
| vector is to be put, and a count of entries in the vector. 
|
| The resulting distribution is in increasing order with
| the median value found at the half way point.
|
| Biased toward maximum entropy distribution.
|
| EXAMPLE:  
|
| EstimateDistribution3( AtSample, AtReplication, 
|                       AtResult, ItemCount );
|
| NOTE: See "An Introduction to the Bootstrap" for complete 
|       explanation. Underestimates the extremes.
|
| ASSUMES: 'BeginSubRandomSequence' called.
|
|
| HISTORY: 02.20.96 from 'EstimateDistribution'.
------------------------------------------------------------*/
void
EstimateDistribution3( f64* AtSample, 
                       f64* AtReplication, 
                       f64* AtResult, 
                       s32   ItemCount )
{
    s32  i, j;
    f64 *s, *d;
    f64 SampleEntropy, ReplicateEntropy;
    
    // Calculate the entropy of the sample.
    SampleEntropy = 0; //TBD
//TBD           EntropyOfItems( AtSample, ItemCount );

    // Clear the result accumulator.
    d = AtResult;
    for( i = 0; i < ItemCount; i++ )
    {
        *d++ = 0.0;
    }
    
    // Accumulate 200 sorted resamples.
    for( j = 0; j < 200; j++ )
    {
TryAgain: // Generate a replicate with a higher entropy
          // then the original sample.
        Resample( AtSample, AtReplication, ItemCount );

        // Calculate the entropy of the resample.
        ReplicateEntropy = 0; //TBD
//TBD           EntropyOfItems( AtReplication, ItemCount );
        
        if( ReplicateEntropy < SampleEntropy )
        {
            goto TryAgain;
        }

        SortVector( AtReplication, ItemCount );
        
        s = AtReplication;
        d = AtResult;
        
        for( i = 0; i < ItemCount; i++ )
        {
            *d++ += *s++;
        }
    }
    
    // Average the results.
    d = AtResult;
    
    for( i = 0; i < ItemCount; i++ )
    {
        *d++ /= 200;
    }
}

/*------------------------------------------------------------
| EstimateClusterCount
|-------------------------------------------------------------
|
| PURPOSE: To estimate the number of clusters in a group.
|
| DESCRIPTION: Expects the address of a vector, address of
| a replication workspace, the address where the result
| vector is to be put, and a count of entries in the vector. 
|
| The resulting distribution is in increasing order with
| the median value found at the half way point.
|
| EXAMPLE:  
|
| c = EstimateClusterCount( AtSample, AtReplication, 
|                           AtResult, ItemCount );
|
| NOTE: Also leaves an estimated distribution of the group
|       at 'AtResult' as a by-product. 
|
| ASSUMES: 'SetUpRandomNumberGenerator' called.
|          ItemCount is positive.
|
| NOTE: 
|
| HISTORY: 07.22.95 .
|          07.24.95 corrected delta calculation error.
------------------------------------------------------------*/
s16
EstimateClusterCount( f64* AtSample, 
                      f64* AtReplication, 
                      f64* AtResult, 
                      s16   ItemCount )
{
    s16  i;
    s16  ClusterCount;
    s16  DeltaCount;
    f64 *s, *d;
    f64 Prior;
    f64 Current;
    f64 Next;

    EstimateDistribution( AtSample, 
                          AtReplication, 
                          AtResult, 
                          ItemCount );

    // Count the clusters by looking for inflection points
    // in the distribution.
    
    // Calculate the differences from one entry to the next,
    // putting them at 'AtReplication'.
    DeltaCount = ItemCount - 1;
    d = AtReplication;
    s = AtResult;
    Prior = *s++;
    for( i = 0; i < DeltaCount; i++ )
    {
        Current = *s++;
        *d++ = Current - Prior;
        Prior = Current;
    }
    
    // There's always at least one cluster.
    ClusterCount = 1;
    
    // Refer to the delta entries.
    s = AtReplication;
    
    Prior   = *s++;
    Current = *s++;
    
    // Ignore the two end deltas.
    for( i = 2; i < DeltaCount; i++ )
    {
        Next = *s++;
        
        if( Prior < Current && Current > Next )
        {
            // A cluster boundary was found.
            ClusterCount++;
        }
        Prior   = Current;
        Current = Next;
    }
    
    return( ClusterCount );
}

/*------------------------------------------------------------
| EstimateClusterCount2
|-------------------------------------------------------------
|
| PURPOSE: To estimate the number of clusters in a group.
|
| DESCRIPTION: Uses anti-log of estimated entropy.
|
| EXAMPLE:  
|
| c = EstimateClusterCount2( AtSample,  
|                            AtReplication,
|                            AtEstimate,
|                            ItemCount );
|
| NOTE: Also leaves an estimated distribution of the group
|       at 'AtEstimate' as a by-product. 
|
| ASSUMES: 'SetUpRandomNumberGenerator' called.
|          ItemCount is positive.
|
| NOTE: 
|
| HISTORY: 07.30.95 .
------------------------------------------------------------*/
f64
EstimateClusterCount2(  f64* AtSample, 
                        f64* AtReplication, 
                        f64* AtEstimate, 
                        s32   ItemCount )
{
    f64 ClusterCount;
    f64 ent;
    
//TBD   ent = EstimateEntropy( AtSample, 
//TBD                          AtReplication, 
//TBD                          AtEstimate, 
//TBD                          ItemCount );

    ClusterCount = pow( 2, ent );
    
    return( ClusterCount );
}

/*------------------------------------------------------------
| EstimateContingencyTable
|-------------------------------------------------------------
|
| PURPOSE: To find the least biased estimate of a contingency 
|          table based on the assumption that the row and 
|          column variables are independent.
|
| DESCRIPTION: Uses extended MaxEnt method explained on page 
| 142 of 'Entropy Optimization Principles with Applications' 
| by Kapur and Kesavan. 
| 
| The filename associated with the matrix is the same as the
| input matrix with the additional suffix "MaxEnt".
|  
| EXAMPLE: est = EstimateContingencyTable( t );
|
| NOTE: 
|
| ASSUMES: Row and column variables are independent.
|          Matrix contains frequencies.
|
| HISTORY: 02.01.96 
-----------------------------------------------------------*/
Matrix*
EstimateContingencyTable( Matrix* AMatrix )
{
    Matrix*  Result;
    f64  TableTotal;
    f64  *RowTotal;
    f64     *ColTotal;
    f64  CellValue;
    s32      r, c;
    s32      RowCount;
    s32      ColCount;
    f64**    A;
    f64**    R;
    
    A = (f64**) AMatrix->a;
    
    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    
    // Allocate the result matrix.
    Result = MakeMatrix( AMatrix->FileName,
                         RowCount,
                         ColCount );
    R = (f64**) Result->a;
    
    // Append a suffix to the source file name to distinguish
    // it from the source file.                    
    AppendString2( (s8*) &(Result->FileName), (s8*) "MaxEnt" );
                  
    // Allocate the row total vector filled with zeros.
    RowTotal = (f64*) 
            calloc( RowCount, sizeof(f64) );            
                  
    // Allocate the column total vector filled with zeros.
    ColTotal = (f64*) 
            calloc( ColCount, sizeof(f64) );            
    
    // Accumulate row, column and table totals.
    TableTotal = 0;
    for( r = 0; r < RowCount; r++ )
    {
        for( c = 0; c < ColCount; c++ )
        {
            CellValue = A[r][c];
            RowTotal[r] += CellValue;
            ColTotal[c] += CellValue;
            TableTotal  += CellValue;
        }
    }
    
    // Estimate the new cells.
    for( r = 0; r < RowCount; r++ )
    {
        for( c = 0; c < ColCount; c++ )
        {
            R[r][c] = (RowTotal[r] * ColTotal[c]) / TableTotal;
        }
    }
    
    free( RowTotal );
    free( ColTotal );
    
    return( Result );
}

/* ------------------------------------------------------------
| EstimateMedian
|-------------------------------------------------------------
|
| PURPOSE: To estimate the median of a population given a 
|          sample from the population.
|
| DESCRIPTION: Returns the median estimate, assuming the
| underlying distribution is continuous.
|
| EXAMPLE: 
|
| NOTE: Normally use 200 for Reps, but use 100 on 68K for
|       speed.
|
| ASSUMES:  
|
| HISTORY: 12.19.94 .
|          12.21.94 added distinct precision for positive
|                   and negative.
|          12.26.94 changed interface.
|          01.01.95 made precision estimate separate.
|          12.30.95 Used 'Median2' instead of sorting.
|          01.29.96 Use 'TheStandardReplicationCountForEstimateMedian'.
|          01.09.97 changed to take the median of the
|                   resampled medians rather than the mean.
|          01.10.97 changed back to use mean -- made separate
|                   routine, 'EstimateMedianDiscrete' which
|                   uses the premise that the underlying
|                   distribution is discrete.
-----------------------------------------------------------*/
f64
EstimateMedian(
    f64  *AtSample,
    f64  *AtReplication,  // A work space as big as sample space.
    s32   SampleCount )
{
    f64    SumOfMedians;
    f64 TheEstimatedMedian;
    s32     i;
    
    // Set up the accumulator.
    SumOfMedians = 0;
    
    for( i = 0 ; 
         i < TheStandardReplicationCountForEstimateMedian; 
         i++ )
    {
        // Resample to make a replication.
        Resample( AtSample, AtReplication, SampleCount );
        
        // Compute median of replication.
        SumOfMedians += Median2( AtReplication, SampleCount );
    }
    
    // The median of replicated medians is the estimate.
    TheEstimatedMedian = 
        SumOfMedians /
          (f64) TheStandardReplicationCountForEstimateMedian;
    
    return( TheEstimatedMedian );
}

/*------------------------------------------------------------
| EstimateMedianAndPrecision
|-------------------------------------------------------------
|
| PURPOSE: To estimate the median of a population given a 
|          sample from the population.
|
| DESCRIPTION: Returns the median and a precision estimate.
| 
|           
| EXAMPLE: 
|
| NOTE: 
|
| EXAMPLE: 
|
| ASSUMES:  
|
| HISTORY: 12.19.94 .
|          12.21.94 added distinct precision for positive
|                   and negative.
|          12.26.94 changed interface.
-----------------------------------------------------------*/
f64
EstimateMedianAndPrecision(
    f64  *AtSample,
    f64  *AtReplication,  // A work space as big as sample space.
    f64  *AtPositiveDev,
    f64  *AtNegativeDev,
    s16   SampleCount )
{
    s16     Reps = 200;     // This is the standard.
    f64 AtMedians[200];
    f64 *AtMid;
    f64 *AtMed;
    f64 *AtMidPlusOne;
    f64 SumOfMedians;
    f64 AMedian;
    f64 SumOfPositiveDeviations;
    f64 SumOfNegativeDeviations;
    f64 TheEstimatedMedian;
    s16     PositiveCount;
    s16     NegativeCount;
    s16     i;
    
    // Set up the accumulators.
    SumOfMedians = 0;

    if( SampleCount & 1 ) // If there are an odd number of items.
    {
        AtMid = &AtReplication[SampleCount>>1];
        AtMed = AtMedians;
        
        for( i = 0 ; i < Reps ; i++ )
        {
            // Resample to make a replication.
            Resample( AtSample, AtReplication, SampleCount );
        
            // Sort the replication in increasing order.
            SortVector( AtReplication, SampleCount );
            
            // The middle value is the median.
            AMedian = *AtMid;
            
            *AtMed++      = AMedian;
            SumOfMedians += AMedian;
        }
    }
    else // An even number of items.
    {
        AtMid        = &AtReplication[SampleCount>>1];
        AtMidPlusOne = AtMid+1;
        AtMed        = AtMedians;
        
        for( i = 0 ; i < Reps ; i++ )
        {
            // Resample to make a replication.
            Resample( AtSample, AtReplication, SampleCount );
        
            // Sort the replication in increasing order.
            SortVector( AtReplication, SampleCount );
            
            // The average of middle values is the median.
            AMedian = (*AtMid + *AtMidPlusOne)/2;
            
            *AtMed++      = AMedian;
            SumOfMedians += AMedian;
        }
    }
    
    // The mean of replicated medians is the estimate.
    TheEstimatedMedian = SumOfMedians / ((f64) Reps);

    // Calculate the average of deviations from the mean
    // median value.
    SumOfPositiveDeviations = 0;
    SumOfNegativeDeviations = 0;
    PositiveCount = 0;
    NegativeCount = 0;

    AtMed           = AtMedians;
    for( i = 0; i < Reps; i++ )
    {
        AMedian = *AtMed++;
        
        if( TheEstimatedMedian > AMedian )
        {
            SumOfNegativeDeviations += 
                TheEstimatedMedian - AMedian;
            NegativeCount++;
        }
        else
        {
            SumOfPositiveDeviations += 
                AMedian - TheEstimatedMedian;
            PositiveCount++;
        }           
    }
    
    *AtPositiveDev = 0;
    if( PositiveCount )
    { 
        *AtPositiveDev = 
            SumOfPositiveDeviations / ((f64) PositiveCount);
    }
    
    *AtNegativeDev = 0;
    if( NegativeCount )
    { 
        *AtNegativeDev   = 
            SumOfNegativeDeviations / ((f64) NegativeCount);
    }
    
    return( TheEstimatedMedian );
}

/*------------------------------------------------------------
| EstimateMedianDiscrete
|-------------------------------------------------------------
|
| PURPOSE: To estimate the median of a population given a 
|          sample from the population.
|
| DESCRIPTION: Returns the median estimate, assuming the
| underlying distribution is discrete.
|
| EXAMPLE: 
|
| NOTE: Normally use 200 for Reps, but use 100 on 68K for
|       speed.
|
| ASSUMES:  
|
| HISTORY: 12.19.94 .
|          12.21.94 added distinct precision for positive
|                   and negative.
|          12.26.94 changed interface.
|          01.01.95 made precision estimate separate.
|          12.30.95 Used 'Median2' instead of sorting.
|          01.29.96 Use 'TheStandardReplicationCountForEstimateMedian'.
|          01.09.97 changed to take the median of the
|                   resampled medians rather than the mean.
-----------------------------------------------------------*/
f64
EstimateMedianDiscrete(
    f64  *AtSample,
    f64  *AtReplication,  // A work space as big as sample space.
    s32   SampleCount )
{
    f64 TheEstimatedMedian;
    s16     i;
    static  f64*    Meds = 0;
    
    // Set up the accumulators.
    if( Meds == 0 )
    {
        Meds = MakeItems( 
                    TheStandardReplicationCountForEstimateMedian, 0 );
    }

    for( i = 0 ; 
         i < TheStandardReplicationCountForEstimateMedian; 
         i++ )
    {
        // Resample to make a replication.
        Resample( AtSample, AtReplication, SampleCount );
        
        // Compute median of replication.
        Meds[i] = Median2( AtReplication, SampleCount );
    }
    
    // The median of replicated medians is the estimate.
    TheEstimatedMedian = 
        Median2( Meds,
                 TheStandardReplicationCountForEstimateMedian );
    
    return( TheEstimatedMedian );
}

/*------------------------------------------------------------
| ExponentialMovingAverage
|-------------------------------------------------------------
|
| PURPOSE: To compute an exponential moving average function 
|          for a list of values.
|
| DESCRIPTION: Returns a list of values the same length as the
| input.  The initial values conform to input values.
|
| 'K' is a value between 0.0 and 1.0 that controls the amount
| of relative weighting between the current value and the last
| EMA value.
|
|         EMA(t+1) = Value * K + (1-K) * EMA(t)
|
| The value for 'K' that cooresponds to the number of periods
| in the EMA is found by this formula from Elder:
|
|           K = 2 / ( N + 1 )
|
| See p. 123 of 'Trading For A Living'.
|
| EXAMPLE:  Find the exponential moving average 
| of copper:
|
|  ExponentialMovingAverage( 
|        Dec92Copper, Out, ItemCount, .5 );
|
| NOTE: 
|
| ASSUMES: None of the weights are zero.
|
| HISTORY:  09.05.93 
|           09.11.93 fixed weighting index bug
|           08.07.95 Converted from Mathematica format.
------------------------------------------------------------- */
void
ExponentialMovingAverage( f64* InputVector, 
                          f64* OutputVector,
                          s32   ItemCount, 
                          f64  K )
{
    s32     i;
    f64 EMA;
    f64    OneMinusK;
    
    OneMinusK = 1.0 - K;
    
    // The first value is just the same as input.
    EMA = *InputVector++;
    *OutputVector++ = EMA;
    
    // Compute remaining values.        
    for( i = 1; i < ItemCount; i++ )
    {
        EMA = (*InputVector++ * K) + (OneMinusK*EMA);
        
        *OutputVector++ = EMA;
    }
}

/*------------------------------------------------------------
| FilterMatrixUsingSampleDistribution
|-------------------------------------------------------------
|
| PURPOSE: To filter a matrix using the frequency distribution
|          implicit in the matrix.
|
| DESCRIPTION: Uses bootstrap to estimate population frequency
| from given sample, then applies to sample to filter improbable
| values.
|
| Returns filtered matrix. Dynamically allocates and frees
| working buffers.
|
| EXAMPLE:  
|
| result = FilterMatrixUsingSampleDistribution( m );
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 07.2.95 .
------------------------------------------------------------*/
Matrix*
FilterMatrixUsingSampleDistribution( Matrix* In )
{
    Matrix* Out;
    
    f64*    AtSample;
    f64*    AtWork1;
    f64*    AtWork2;
    f64*    AtResult;
    s16     MaxDimension;
    s32     i, j;
    s32     rows;
    s32     columns;
    s32     SizeOfWorkBuffer;
    f64 d;
    f64**   InData;
    f64**   OutData;
    
printf("FilterMatrix: %s\n", In->FileName);
    
    rows    = In->RowCount;
    columns = In->ColCount;
    InData  = (f64**) In->a;
        
    // Allocate the result matrix.
    Out = MakeMatrix( (s8*) "Result", rows, columns );
    OutData = (f64**) Out->a;
    
    // Allocate space for working buffers: maximum of row
    // column.
    MaxDimension = rows;
    if( columns > MaxDimension )
    {
        MaxDimension = columns;
    }
    
    SizeOfWorkBuffer = sizeof( f64 ) * MaxDimension;
    
    AtSample = (f64*)
                malloc( SizeOfWorkBuffer );
    AtWork1 = (f64*)
                malloc( SizeOfWorkBuffer );
    AtWork2 = (f64*)
                malloc( SizeOfWorkBuffer );
    AtResult = (f64*)
                malloc( SizeOfWorkBuffer );
    
    // For each row...
    for( i = 0; i < rows; i++ )
    {
printf("FilterMatrix: row %ld\n", i);

        // Copy row to sample buffer.
        for( j = 0; j < columns; j++ )
        {
            AtSample[j] = InData[i][j];
        }
        
        // Filter the row.
        FilterUsingSampleDistribution( AtSample, 
                                       AtWork1, 
                                       AtWork2, 
                                       AtResult, 
                                       (s16) columns );
                                       
        // Copy result to row of result matrix.
        for( j = 0; j < columns; j++ )
        {
            OutData[i][j] = AtResult[j];
        }
    }
        
    // For each column...
    for( j = 0; j < columns; j++ )
    {
printf("FilterMatrix: column %ld\n", j);
        // Copy column to sample buffer.
        for( i = 0; i < rows; i++ )
        {
            AtSample[i] = InData[i][j];
        }
        
        // Filter the column.
        FilterUsingSampleDistribution( AtSample, 
                                       AtWork1, 
                                       AtWork2, 
                                       AtResult, 
                                       (s16) columns );
                                       
        // Average result to column of result matrix.
        for( i = 0; i < rows; i++ )
        {
            d =  OutData[i][j];
            d += AtResult[i];
            d /= 2;
            OutData[i][j] = d;
        }
    }
    
    // Free working buffers.
    free( (u8*) AtSample );
    free( (u8*) AtWork1 );
    free( (u8*) AtWork2 );
    free( (u8*) AtResult );
    
    // Return the result.
    return( Out );
}

/*------------------------------------------------------------
| FilterMatrixFileUsingSampleDistribution
|-------------------------------------------------------------
|
| PURPOSE: To filter a matrix file using the frequency 
|          distribution implicit in the matrix.
|
| DESCRIPTION: Uses bootstrap to estimate population 
| frequency from given sample, then applies to sample to 
| filter improbable values.
|
| Writes out filtered matrix. Dynamically allocates and frees
| working buffers.
|
| EXAMPLE:  
|
|   FilterMatrixFileUsingSampleDistribution( In, Out );
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 01.03.96 .
------------------------------------------------------------*/
void
FilterMatrixFileUsingSampleDistribution( 
    s8* InputFile,
    s8* OutputFile )
{
    Matrix* AMatrix;
    Matrix* BMatrix;

//TBD   AMatrix = ReadMatrix( InputFile );
            
    BMatrix = FilterMatrixUsingSampleDistribution( AMatrix );
    
    SaveMatrix( BMatrix, OutputFile );

    DeleteMatrix( AMatrix );
    DeleteMatrix( BMatrix );
}

/*------------------------------------------------------------
| FilterUsingSampleDistribution
|-------------------------------------------------------------
|
| PURPOSE: To filter a vector using the frequency distribution
|          implicit in the vector.
|
| DESCRIPTION: Uses bootstrap to estimate population frequency
| from given sample, then applies to sample to filter improbable
| values.
|
| Requires two working buffers the same size as the input
| vector.
|
| EXAMPLE:  
|
| FilterUsingSampleDistribution( prices, 
|                                AtWork1, 
|                                AtWork2, 
|                                AtResult, 
|                                ItemCount );
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 06.25.95 .
------------------------------------------------------------*/
void
FilterUsingSampleDistribution( f64* AtSample, 
                               f64* AtWork1, 
                               f64* AtWork2, 
                               f64* AtResult, 
                               s32   ItemCount )
{
    f64*    a;
    f64*    b;
    s32     i;
    
    // Estimate the distribution of the sample.
    EstimateDistribution( AtSample, 
                          AtWork1, 
                          AtWork2, 
                          ItemCount );

    // Copy the sample to the first workspace for sorting.
    a = AtWork1;
    b = AtSample;
    
    for( i = 0; i < ItemCount; i++ )
    {
        *a++ = *b++;
    }
    
    // Sort the sample to make a lookup table.
    SortVector( AtWork1, ItemCount );
    
    // Translate sample values to cooresponding estimates.
    a = AtSample;
    b = AtResult;
    
    for( i = 0; i < ItemCount; i++ )
    {
        *b++ = LookUpCoorespondingNumber( *a++, 
                                          AtWork1,
                                          AtWork2,
                                          ItemCount );
    }
}

/*------------------------------------------------------------
| FilterUsingSampleDistribution2
|-------------------------------------------------------------
|
| PURPOSE: To filter a vector using the frequency distribution
|          implicit in the vector, biased toward MaxEnt.
|
| DESCRIPTION: Uses bootstrap to estimate population frequency
| from given sample, then applies to sample to filter improbable
| values.
|
| Requires two working buffers the same size as the input
| vector.
|
| EXAMPLE:  
|
| FilterUsingSampleDistribution2( prices, 
|                                  AtWork1, 
|                                  AtWork2, 
|                                  AtResult, 
|                                  ItemCount );
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 06.25.95 .
------------------------------------------------------------*/
void
FilterUsingSampleDistribution2( f64* AtSample, 
                                f64* AtWork1, 
                                f64* AtWork2, 
                                f64* AtResult, 
                                s32   ItemCount )
{
    f64*    a;
    f64*    b;
    s32     i;
    
    // Estimate the distribution of the sample, biased toward
    // MaxEnt.
    EstimateDistribution3( AtSample, 
                           AtWork1, 
                           AtWork2, 
                           ItemCount );

    // Copy the sample to the first workspace for sorting.
    a = AtWork1;
    b = AtSample;
    
    for( i = 0; i < ItemCount; i++ )
    {
        *a++ = *b++;
    }
    
    // Sort the sample to make a lookup table.
    SortVector( AtWork1, ItemCount );
    
    // Translate sample values to cooresponding estimates.
    a = AtSample;
    b = AtResult;
    
    for( i = 0; i < ItemCount; i++ )
    {
        *b++ = LookUpCoorespondingNumber( *a++, 
                                          AtWork1,
                                          AtWork2,
                                          ItemCount );
    }
}

/*------------------------------------------------------------
| GeometricMean
|-------------------------------------------------------------
|
| PURPOSE: To calculate geometric mean of a list of doubles.
|
| DESCRIPTION:   
|           
| EXAMPLE: f64 L[] = { 123.123, 12321, 1232.2 };
|          gm = GeometricMean( &L, 3 );
|
| NOTE: 
|
| ASSUMES: Input values are >= 0. 
|
| HISTORY: 10.23.94 
|          12.13.94 converted to use sum of logs
|          12.26.94 converted to 'C'.
-----------------------------------------------------------*/
f64
GeometricMean( f64* AtItem, s16 ItemCount )
{
    s16  i;
    f64 SumOfLogs;
    f64 GeoMean;
    
    SumOfLogs = 0;
    
    for( i = 0; i < ItemCount; i++ )
    {
        SumOfLogs += log( *AtItem++ );
    }
    
    GeoMean = exp( SumOfLogs / ((f64) ItemCount) );
    
    return( GeoMean );
}

/* ------------------------------------------------------------
| HighValue
|-------------------------------------------------------------
|
| PURPOSE: To find highest value of a list of doubles.
|
| DESCRIPTION:   
|           
| EXAMPLE: f64 L[] = { 123.123, 12321, 1232.2 };
|          m = HighValue( &L, 3 );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 07.31.95 
-----------------------------------------------------------*/
f64
HighValue( f64* AtItem, s32 ItemCount )
{
    s32  i;
    f64 v;
    f64 H;
    
    H = *AtItem;
    
    for( i = 0; i < ItemCount; i++ )
    {
        v = *AtItem++;
        
        if( v > H )
        {
            H = v;
        }
        
    }
    
    return( H );
}

/*------------------------------------------------------------
| InterpolateLinear
|-------------------------------------------------------------
|
| PURPOSE: To interpolate a value given two known points on
|          a line.
|
| DESCRIPTION: Interpolates using the line defined by the
| two endpoints.
|
| EXAMPLE: y = InterpolateLinear( XValues, YValues, x );
|
| NOTE: from p. 89 of 'C/Math Toolchest'.
|
| ASSUMES:
|
| HISTORY: 01.26.96  
|          01.27.96 validated.
------------------------------------------------------------*/
f64
InterpolateLinear( f64* xa, f64* ya, f64 x )
{
    if( xa[0] == x ) return( ya[0] );
    if( xa[1] == x ) return( ya[1] );

    return( ( ya[0] * ( x - xa[1] ) -
              ya[1] * ( x - xa[0] ) ) /
              ( xa[0] - xa[1] ) );
}

/*------------------------------------------------------------
| InterpolateLinearUsingNearestPoints
|-------------------------------------------------------------
|
| PURPOSE: To interpolate linearly using the two nearest known
|          points in a table.
|
| DESCRIPTION: Interpolates using the line defined by the
| two nearest X valued points.
|
| EXAMPLE: y = InterpolateLinearUsingNearestPoints( 
|                   XValues, YValues, n, x );
|
| NOTE: from p. 89 of 'C/Math Toolchest'.
|
| ASSUMES:
|
| HISTORY: 01.26.96
------------------------------------------------------------*/
f64
InterpolateLinearUsingNearestPoints( 
        f64* xa, f64* ya, s32 n, f64 x )
{
    s32  i;
    s32  n0, n1;
    f64 d, d0, d1;
    
    // Find the first nearest point.
    n0 = 0;
    d0 = fabs( xa[n0] - x );
    
    for( i = 0; i < n; i++ )
    {
        if( xa[i] == x ) return( ya[i] );
        
        d = fabs( xa[i] - x );
        
        if( d < d0 )
        {
            d0 = d;
            n0 = i;
        }
    }
    
    // Find the 2nd nearest point.
    n1 = -1;
    
    for( i = 0; i < n; i++ )
    {
        d = fabs( xa[i] - x );
        
        if( i != n0 && ( n1 < 0 || d < d1 ) )
        {
            d1 = d;
            n1 = i;
        }
    }
    
    return( ( ya[n0] * ( x - xa[n1] ) -
              ya[n1] * ( x - xa[n0] ) ) /
              ( xa[n0] - xa[n1] ) );
}

/*------------------------------------------------------------
| InterpolateToNearest
|-------------------------------------------------------------
|
| PURPOSE: To interpolate by returning the nearest known value.
|
| DESCRIPTION:  
|
| EXAMPLE: y = InterpolateToNearest( XValues, YValues, n, x );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 01.26.96
------------------------------------------------------------*/
f64
InterpolateToNearest( f64* xa, f64* ya, s32 n, f64 x )
{
    s32  i;
    s32  n0;
    f64 d, d0;
    
    // Find the nearest point.
    n0 = 0;
    d0 = fabs( xa[n0] - x );
    
    for( i = 1; i < n; i++ )
    {
        if( xa[i] == x ) return( ya[i] );
        
        d = fabs( xa[i] - x );
        
        if( d < d0 )
        {
            d0 = d;
            n0 = i;
        }
    }
    
    return( ya[n0] );
}

/*------------------------------------------------------------
| InterpolateUsingRationalFunction
|-------------------------------------------------------------
|
| PURPOSE: To interpolate a value given a table of known
| values.
|
| DESCRIPTION: Interpolates using a ratio of polynomials.
| *"Some functions are not well approximated by polynomials
| but are well approximated by rational functions."
|
| EXAMPLE:  
|
| y = InterpolateUsingRationalFunction( 
|          XValues, YValues, ItemCount, x );
|
| NOTE: * from p. 111 of 'Numerical Recipes in C'.
|
| ASSUMES: Tables are increasing x order.
|
| HISTORY: 01.13.96 .  Tested OK using two
|                   cases of 4 point tables.  Extrapolates 
|                   nicely.  Very stable.
|          01.26.96 Not stable enough for extrapolating
|                   index tables from known tables -- got
|                   pole condition.
------------------------------------------------------------*/
f64
InterpolateUsingRationalFunction( 
    f64* xa, f64* ya, s32 n, f64 x )
{
    s32     m, i, ns=0;
    f64 w, t, hh, h, dd, *c, *d;
    f64 y;
    f64 C[10], D[10];
    
    if( n > 10 )
    {
        c = (f64*) malloc( n * sizeof( f64 ) );
        d = (f64*) malloc( n * sizeof( f64 ) );
    }
    else
    {
        c = (f64*) &C;
        d = (f64*) &D;
    }
        
    hh = fabs( x - xa[0] );
    
    for( i = 0; i < n; i++ )
    {
        h = fabs( x - xa[i] );
        
        if( h == 0 ) // exact match?
        {
            if( n > 10 )
            {
                free( c );
                free( d );
            }
            
            return( ya[i] );
        }
        else
        {
            if( h < hh )
            {
                ns = i;
                hh = h;
            }
        }
        
        c[i] = ya[i];
        d[i] = ya[i] + 1.0e-25; // The small number is needed
                                // to prevent a rare 0/0 condition.
    }
    
    y = ya[ ns-- ];
    
    for( m = 1; m < n; m++ )
    {
        for( i = 0; i < n-m; i++ )
        {
            w = c[i+1] - d[i];
            h = xa[i+m]-x; // h is never 0: tested above.
            t = (xa[i]-x)*d[i]/h;
            dd = t - c[i+1];
            
            if( dd == 0.0 )
            {
                Debugger(); // Error: pole condition at x.
            }
            
            dd = w/dd;
            
            d[i] = c[i+1] * dd;
            c[i] = t * dd;
        }
        
        if( (2*(ns+1)) < ( n-m ) )
        {
            y += c[ns+1];
        }
        else
        {
            y += d[ns--];
        }
    }
    
    if( n > 10 )
    {
        free( c );
        free( d );
    }

    return(y);
}
    
/*------------------------------------------------------------
| LineFitMaxEnt
|-------------------------------------------------------------
|
| PURPOSE: To finds the line, Y=m*X+b, that maximizes the
|          residual entropy given a list of (x,y) pairs.
| 
| DESCRIPTION: The residual is the distance from an (x,y)
| point to the line being fitted.  Uses resampling and 
| 'LineFit' then selects the result that equalizes the 
| entropy of the positive and negative residuals.
|
| x[] is the abcissa array
| y[] is the ordinate array
| n is the length of x[] and y[]
| M is the returned slope in Y=m*X+b
| B is the returned y-intercept in Y=m*X+b
| 'IsPlot' is non-zero if a progress plot should be drawn.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: Vertical line solution never occurs.
|          At least 4 points given.
| 
| HISTORY: 03.25.96 
|          03.30.96 revised to use 'Vector'. 
------------------------------------------------------------*/
void 
LineFitMaxEnt( Vector* V, f64* M, f64* B, u32 IsPlot )
{
#if macintosh
    s32         i, j, k, ii, jj, kk;
    s32         pt, PartCount, Pos, Neg;
    f64         XLo, XHi, YLo, YHi;
    f64     x0, y0, x1, y1, xx1, yy1, xx0, yy0;
    f64        NetEnt, BestNetEnt;
    f64     PosResidEnt, NegResidEnt;
    f64     cosa, sina, a, p, m, rsqr, b, d;

    f64*        PosResid;
    f64*        NegResid;
    f64*        xx;
    f64*        yy;
    f64*        xxx;
    f64*        yyy;
    Vector*     XYp;
    Vector*     XYn;
    Vector*     ALine;
    f64*        x;
    f64*        y; 
    s32         n;
    Rect        ARect;
    LineGraph*  AGraph;
    
    // Refer to the vector parts.
    x = V->X;
    y = V->Y;
    n = V->ItemCount;
        
    // Allocate an array for residuals.
    PosResid = (f64*) malloc( n * sizeof(f64) );
    NegResid = (f64*) malloc( n * sizeof(f64) );
    
    // Compute some stats of x and y.
    XLo = LowValue( x, n);
    XHi = HighValue( x, n);
    YLo = LowValue( y, n);
    YHi = HighValue( y, n);
    
    // Pick the best line out of 1000 random trials.
        // Pick two points in the range.
    // Make one end point the median.
    // Duplicate vectors so that median can be applied.
    xx  = DuplicateItems( x, n );
    yy  = DuplicateItems( y, n );
    xxx = DuplicateItems( x, n );
    yyy = DuplicateItems( y, n );
    
    // Shuffle 'xxx' and 'yyy' to remove serial coorelations
    // so that subrandom resampling won't be biased.
    for( i = 0; i < n; i++ )
    {
        j = RandomInteger( n );
        k = RandomInteger( n );
        
        x0 = xxx[j];
        y0 = yyy[j];
        xxx[j] = xxx[k];
        yyy[j] = yyy[k];
        xxx[k] = x0;
        yyy[k] = y0;
    }   
    
    if( IsPlot )
    {
        // Place the line graph.
        ARect.top    = 50;
        ARect.left   = 50;
        ARect.bottom = 500;
        ARect.right  = 700;
    
        // Make the data series vectors.
        XYp = MakeVector( n, 0, 0 );
        
        XYn = MakeVector( n, 0, 0 );
        
        ALine = MakeVector( 2, 0, 0 );
    }
    
    BestNetEnt = 1000000;
    
    // Subsample size is 1/8th of the total, an even number.
    PartCount = (n/16) * 2;
    
    for( i = 0; i < 10000; i++ )
    {
        // Pick a set of points from the samples
        // subrandomly.
        for( k = 0; k < PartCount; k++ )
        {
            pt = SubRandomInteger( n );
            xx[k] = xxx[pt];
            yy[k] = yyy[pt];
        }
        
        // Fit a least squares line to the cluster.
 // TBD -- Fix as needed.       LineFit( xx, yy, PartCount, &m, &b, &rsqr );
        
        // Calculate the end points.
        y0 = m * XLo + b;
        x0 = XLo;
        y1 = m * XHi + b;
        x1 = XHi;
        
        // Calculate the line in Hessian Normal form:
        //
        //    x cos a + y sin a - p = 0
        //
        if( x0 == x1 )
        {
            a = 0; // A vertical line.
            p = x1;
        }
        else // A non-vertical line.
        {
            // The line perpendicular to the one 
            // through the two points has a slope
            // with opposite sign.  Slope is tangent,
            // so to get the angle, take the arctangent.
            //  m = (y1 - y0)/(x1 - x0);
            
            // The angle of the line normal to the line
            // through the points.  Convert the slope to
            // angle and add 90 degrees.
            a = atan( m ) + (pi/2.0);       
            
            // 'b' is the 'y' intercept of the line defined
            // by the two points.
            //
            //         y = mx + b
            //         y - mx = b
            // b = y0 - (m * x0);
            
            // The distance from the origin to the line
            // is calculated as:
            //
            //        p = sin(a) * b
            //
            p = sin( a ) * b;
        }
        
        sina = sin(a);
        cosa = cos(a);
        
        // Calculate the distance from each point to this
        // line.
        Pos = 0;
        Neg = 0;
        if( IsPlot )
        {
            for( j = 0; j < PartCount; j++ )
            {
                // The distance 'd' from a point P1(x1,y1) from
                // a line with the equation
                //
                //     x cos a + y sin a - p = 0
                //
                // is    d = x1 cos a + y1 sin a - p
                //
                // such that 'd' is positive if P1 and the origin
                // lie on opposite sides of the line. Otherwise
                // 'd' is negative.
                //
                d = xx[j] * cosa + yy[j] * sina - p;
            
                if( d < 0 )
                {
                    d = -d;
                    NegResid[Neg] = d;
                    XYn->X[Neg] = xx[j];
                    XYn->Y[Neg] = yy[j];
                    Neg++;
                }
                else
                {
                    PosResid[Pos] = d;
                    XYp->X[Pos] = xx[j];
                    XYp->Y[Pos] = yy[j];
                    Pos++;
                }
            }
        }
        else // No plot.
        {
            for( j = 0; j < PartCount; j++ )
            {
                // The distance 'd' from a point P1(x1,y1) from
                // a line with the equation
                //
                //     x cos a + y sin a - p = 0
                //
                // is    d = x1 cos a + y1 sin a - p
                //
                // such that 'd' is positive if P1 and the origin
                // lie on opposite sides of the line. Otherwise
                // 'd' is negative.
                //
                d = xx[j] * cosa + yy[j] * sina - p;
            
                if( d < 0 )
                {
                    d = -d;
                    NegResid[Neg++] = d;
                }
                else
                {
                    PosResid[Pos++] = d;
                }
            }
        }       
            
        // Calculate the entropy of the residuals.
 //TBD      PosResidEnt = EntropyOfItems( PosResid, Pos );
 //TBD      NegResidEnt = EntropyOfItems( NegResid, Neg );
                
        // Find the difference in the entropy.
        NetEnt = fabs( PosResidEnt - NegResidEnt );
// Probably should be the product of the entropy.
// DEFER        
        // Save the best endpoints.
        if( NetEnt < BestNetEnt )
        {
            BestNetEnt = NetEnt;
            xx0 = x0; 
            yy0 = y0;
            xx1 = x1; 
            yy1 = y1;
            
            // Shuffle 'xxx' and 'yyy' to remove serial coorelations
            // so that subrandom resampling won't be biased.
            for( ii = 0; ii < n; ii++ )
            {
                jj = RandomInteger( n );
                kk = RandomInteger( n );
        
                x0 = xxx[jj];
                y0 = yyy[jj];
                xxx[jj] = xxx[kk];
                yyy[jj] = yyy[kk];
                xxx[kk] = x0;
                yyy[kk] = y0;
            }   

            //
            //            B E G I N   P L O T
            //
            if( IsPlot )
            {
                AGraph = 
                    MakeGraph( (s8*) "LineFitMaxEnt: X vs. Y", 
                               &ARect );

                CopyString((s8*) "X", (s8*) &AGraph->XAxisLabel);
                CopyString((s8*) "Y", (s8*) &AGraph->YAxisLabel);
            
                // Make the positive residual series.
                if( Pos > 0 )
                {
                    AddPointsToGraph( AGraph, XYp, &Blue );
                }
            
                // Make the negative residual series.
                if( Neg > 0 )
                {
                    AddPointsToGraph( AGraph, XYn, &Green );
                }

                // Make a red line showing the fit.
                ALine->X[0] = XLo;
                ALine->Y[0] = m * XLo + b;
                ALine->X[1] = XHi;
                ALine->Y[1] = m * XHi + b;
        
                AddLinesToGraph( AGraph, ALine, &Red );

                DrawGraph( AGraph );

                DrawStringAt( ARect.left + 30, 
                              ARect.top + Line1, 
                              (s8*) "Line slope, m: %f", m);
                              
                DrawStringAt( ARect.left + 30, 
                              ARect.top + Line2, 
                              (s8*) "Line y offset, b: %f", b);
                              
                DrawStringAt( ARect.left + 30, 
                              ARect.top + Line3, (s8*) "NetEnt: %f", NetEnt);
            
                DeleteGraph( AGraph );
                
                // while(!Button());
            }
            //
            //             E N D   P L O T
            //
        }
     }
     
     // Return the slope.
     *M = (yy1 - yy0) / (xx1 - xx0);
     
     // Return the Y intercept.
     *B = yy0 - (*M * xx0);
     
     if( IsPlot )
     {
         free( XYp );
         free( XYn );
         free( ALine );
     }

     free( xx );
     free( yy );
     free( xxx );
     free( yyy );
     free( PosResid );
     free( NegResid );
#endif // macintosh
}

/*------------------------------------------------------------
| LineFitMaxEnt2
|-------------------------------------------------------------
|
| PURPOSE: To finds the line that best fits a list of (x,y) 
|          pairs.
| 
| DESCRIPTION: Returns the best line found in general form.
|
| Differs from 'LineFitMaxEnt' in that 'FindSimplexMinimum'
| is used to converge on the best line.
|
| 'V' is a vector of (x,y) points.
| 'g' is the returned line.
| 'IsPlot' is non-zero if a progress plot should be drawn.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: Vertical line solution never occurs.
|          At least 4 points given.
| 
| HISTORY: 04.01.96 from 'LineFitMaxEnt'.
------------------------------------------------------------*/
Vector* LFME_From;
Vector* LFME_To;
f64*    LFME_x;
f64*    LFME_y;
s32     LFME_ItemCount;
f64*    LFME_PosResid;
f64*    LFME_NegResid;
f64 LFME_XLo;
f64 LFME_XHi;
f64 LFME_YLo;
f64 LFME_YHi;
u32     LFME_IsPlot;
f64 LFME2_MeanX;
f64 LFME2_MeanY;
f64 LFME2_Radius;
f64 LFME2_BestAngle;
#if 0 // later
void 
LineFitMaxEnt2( Vector* V, General2DLine* g, u32 IsPlot )
{
    s32         i;
    f64     a, d, XSpan, YSpan;
    CX          A;
    Matrix*     Vertex;
    f64**       Vt;
    Vector*     Ys;
    HessianLine h;
    
//SaveVector( V, "NGIntVsPr" );
//return;
        
    // Make the global references for the subroutine.
    LFME_From = V;
    LFME_x = V->X;
    LFME_y = V->Y;
    LFME_ItemCount = V->ItemCount;
    LFME_IsPlot = IsPlot;
        
    // Allocate a vector for the mirror image points.
    LFME_To = MakeVector( LFME_ItemCount, 0, 0 );
    
    // Compute some stats of x and y.
    ExtentOfVector( V, 
                    &LFME_XLo, &LFME_XHi,
                    &LFME_YLo, &LFME_YHi );
    YSpan = LFME_YHi - LFME_YLo;
    XSpan = LFME_XHi - LFME_XLo;
    
    LFME2_MeanX = (LFME_XHi + LFME_XLo)/2.0;
    LFME2_MeanY = (LFME_YHi + LFME_YLo)/2.0;
    LFME2_Radius = max( YSpan, XSpan ) / 2.0;
    
    // Compute the center point of the high and low values.
    A.a = LFME2_MeanX;
    A.b = LFME2_MeanY;
    
    // Convert the center point to polar coordinates.
    ConvertToPolar( &A );
    a = A.a; // Vectorial Angle
    d = A.b; // Radius vector: may be negative.
    
    // Allocate the vertex matrix.
    Vertex = MakeMatrix( (s8*) "", 3, 2 );
    Vt = (f64**) Vertex->a;
    
    // Make the initial three points be lines near the
    // XY mean, expressed in Hessian Normal form,
    // angle and distance.
    Vt[0][0] = a;              Vt[0][1] = d;
    Vt[1][0] = a + (.5 * a);   Vt[1][1] = d + (.5 * d);
    Vt[2][0] = a - (.5 * a);   Vt[2][1] = d - (.5 * d);
    
    // Calculate the Y values for the initial vertices.
    Ys = MakeVector( 3, 0, 0 );
    for( i = 0; i < 3; i++ )
    {
        Ys->Y[i] = LFME2_TryLine( (f64*) Vt[i] );
    }
    
    // Now converge to the minimum.
    // This finds a line with the best slope but not necessarily
    // the most central fit.
    FindSimplexMinimum(
        LFME2_TryLine,   // FofX
        Vertex,          // Vertex
        Ys,              // Y vector
        ChopTolerance ); // Tolerance

#ifdef RESTART  
    // Restart at new location.
    // XY mean, expressed in Hessian Normal form,
    // angle and distance.
    h.a  = Vt[0][0];
    h.r  = Vt[0][1];    
    Vt[1][0] = h.a + (.5 * h.a);   Vt[1][1] = h.r + (.5 * h.r);
    Vt[2][0] = h.a - (.5 * h.a);   Vt[2][1] = h.r - (.5 * h.r);
    
    // Calculate the Y values for the initial vertices.
    for( i = 0; i < 3; i++ )
    {
        Ys->Y[i] = LFME2_TryLine( (f64*) Vt[i] );
    }
    
    // Now converge to the minimum.
    // This finds a line with the best slope but not necessarily
    // the most central fit.
    FindSimplexMinimum(
        LFME2_TryLine,   // FofX
        Vertex,          // Vertex
        Ys,              // Y vector
        ChopTolerance ); // Tolerance
#endif

    // Get the line with the best slope.
    //
    // Vt[0][0] holds the angle: Vt[0][1] holds the distance.
//  m = MeanSlopeOfVector( V );
    
    // Convert the slope of the normal to an angle.
    // The normal slope is the negative reciprocal.
    //
//  n = -1.0 / m;
        
    // Calculate the arctan of the slope to get the
    // angle of the normal line.
//  h.a = atan( n );

    h.a  = Vt[0][0];
    h.r  = Vt[0][1];    
    
    // Now vary radial vector of the normal line but keep the 
    // slope the same.  Minimize the magnitude of the residuals.
    LFME2_BestAngle = h.a;

    // Could calculate the upper and lower bounds here something
    // like this.
//  p.x = LFME2_MeanX;
//  p.y = LFME2_MeanY;
//  rad = fabs( DistanceOfPointToHessianLine( &h, &p ) );
    
    FindParabolicMinimum( LFME2_TryRadius, 
                          -h.r*100.0, // XLo 
                          h.r,        // XMid  
                          h.r*100.0,  // XHi  
                          ChopTolerance, // Tolerance 
                          &h.r );
    
    //
    // Convert Hessian normal line to general form.
    //
    HessianLineToGeneralLine( &h, g );
    
    // Free the dynamic memory.
    free( LFME_To );
    DeleteMatrix( Vertex );
}
#endif
    
/*------------------------------------------------------------
| LFME2_TryLine
|-------------------------------------------------------------
|
| PURPOSE: To compute the 1/entropy of (x,y) pairs with 
|          respect to mirror image points relative to
|          a line, x * cos(a) + y * sin(a) - d = 0.
| 
| DESCRIPTION: This is a subroutine called by 'LineFitMaxEnt2' 
| via 'FindSimplexMinimum'.
|
| Follows these steps:
|
| 1. Makes a mirror image of the (x,y) points reflected 
|    about the trial line.
|
| 2. Computes the entropy of the distances between the images.
|
| 3. Returns the reciprocal of the entropy.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
| 
| HISTORY: 04.01.96 from 'LineFitMaxEnt'.
------------------------------------------------------------*/
#if macintosh
f64 
LFME2_TryLine( f64* x )
{
    f64     xe,xe2;
    LineGraph*  AGraph;
    HessianLine h;
    General2DLine   g;
    
    // Get the angle and distance of the line, specified
    // in Hession Normal form, 
    // 
    //      x * cos(a) + y * sin(a) - d = 0
    //
    h.a = x[0];
    h.r = x[1];

    // Calculate the distances of each point to the line.
//  DistanceOfPointsToHessianLine( &h, LFME_From, LFME_To->X );
    
    // Calculate the entropy of the positive and negative
    // distance items separately.
//  neg =
//      EntropyOfNegativeItems( LFME_To->X, 
//                              LFME_From->ItemCount );
//  pos =
//      EntropyOfPositiveItems( LFME_To->X, 
//                              LFME_From->ItemCount );
                                
//  xe =  neg * pos;    
    // Compute the mirror image points.
    ReflectVectorAboutLine( &h, LFME_From, LFME_To );

    xe = CrossEntropyOfVectors( LFME_From, LFME_To );

    // Sum the magnitudes of the distances.
//  xe = SumMagnitudeOfItems( LFME_To->X, LFME_From->ItemCount );
    
    // Calculate the distances of each point to the line.
//  DistanceOfPointsToHessianLine( &h, LFME_To, LFME_To->X );
    // Sum the magnitudes of the distances.
//  xe += SumMagnitudeOfItems( LFME_To->X, LFME_From->ItemCount );
    

    // Change the ordering of reflected points.
    ShuffleVector( LFME_To );
    
    // Measure the cross entropy of the sets of points.
//      xe = CrossEntropyOfVectors( LFME_From, LFME_To );
    
    // Use reciprocal of entropy of angles and distances
    // as a standin for cross entropy which isn't working.
    xe = EntropyOfVectorDistances( LFME_From, LFME_To );
    ShuffleVector( LFME_To );
    xe2 = EntropyOfVectorDistances( LFME_From, LFME_To );
    
    xe =  xe * xe2;
//  xe = 1/EntropyOfVectorDistances( LFME_From, LFME_To );
//  xe =  EntropyOfVectorAngles( LFME_From, LFME_To );
    
    if( LFME_IsPlot )
    {
        //
        //            B E G I N   P L O T
        //
        // Make the data series vectors.
  
        AGraph = MakeGraph( 
                        (s8*) "LineFitMaxEnt2: X vs. Y", 
                        &DefaultGraphRect );

        CopyString((s8*) "X",(s8*)&AGraph->XAxisLabel);
        CopyString((s8*) "Y",(s8*)&AGraph->YAxisLabel);
        
        AddPointsToGraph( AGraph, LFME_From, &Green );  
        AddPointsToGraph( AGraph, LFME_To, &Blue ); 

        AutoScaleLineGraphSquare( AGraph );

        DrawGraph( AGraph );

        // Make a red line showing the fit.
        HessianLineToGeneralLine( &h, &g );
        OverlayLineOnGraph( AGraph, &g, &Red, 1.0 );

        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line1, 
                      (s8*) "Line A: %f", g.A);
                              
        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line2, 
                      (s8*) "Line B: %f", g.B);
                              
        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line3, 
                      (s8*) "Line C: %f", g.C);

        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line4, 
                      (s8*) "CrossEnt: %f", xe );
            
        DeleteGraph( AGraph );
                
//      while(!Button());
//      for(i=0;i<5000000;i++); // delay
        //
        //             E N D   P L O T
        //
    }
    return( xe );
}
#endif // macintosh  

/*------------------------------------------------------------
| LFME2_TryRadius
|-------------------------------------------------------------
|
| PURPOSE: To compute the magnitude of the sum of the residuals
|          of the points relative to the line with the best
|          angle and given radial vector.
| 
| DESCRIPTION: This is a subroutine called by 'LineFitMaxEnt2'
| via 'FindParabolicMinimum'.
|
| Follows these steps:
|
| 1. Makes a mirror image of the (x,y) points reflected 
|    about the trial line.
|
| 2. Computes the entropy of the distances between the images.
|
| 3. Returns the reciprocal of the entropy.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
| 
| HISTORY: 04.01.96 from 'LineFitMaxEnt'.
------------------------------------------------------------*/
f64 
LFME2_TryRadius( f64 x )
{
    f64     xe;
#if macintosh
    LineGraph*  AGraph;
    HessianLine h;
    General2DLine   g;
    
    // Get the angle and distance of the line, specified
    // in Hession Normal form, 
    // 
    //      x * cos(a) + y * sin(a) - d = 0
    //
    h.a = LFME2_BestAngle;
    h.r = x;

    // Calculate the distances of each point to the line.
    DistanceOfPointsToHessianLine( &h, LFME_From, LFME_To->X );
    
    // Sum the magnitudes of the distances.
    xe = SumMagnitudeOfItems( LFME_To->X, LFME_From->ItemCount );

    if( LFME_IsPlot )
    {
        //
        //            B E G I N   P L O T
        //
        // Make the data series vectors.
  
        AGraph = MakeGraph( 
                        (s8*) "LineFitMaxEnt2: X vs. Y", 
                        &DefaultGraphRect );

        CopyString((s8*) "X",(s8*)&AGraph->XAxisLabel);
        CopyString((s8*) "Y",(s8*)&AGraph->YAxisLabel);
        
        AddPointsToGraph( AGraph, LFME_From, &Green );  
 
        AutoScaleLineGraph( AGraph );

        DrawGraph( AGraph );

        // Make a red line showing the fit.
        HessianLineToGeneralLine( &h, &g );
        OverlayLineOnGraph( AGraph, &g, &Red, 1.0 );

        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line1, 
                      (s8*) "Line A: %f", g.A);
                              
        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line2, 
                      (s8*) "Line B: %f", g.B);
                              
        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line3, 
                      (s8*) "Line C: %f", g.C);

        DrawStringAt( DefaultGraphRect.left + 30, 
                      DefaultGraphRect.top + Line4, 
                      (s8*) "CrossEnt: %f", xe );
            
        DeleteGraph( AGraph );
                
//      while(!Button());
//      for(i=0;i<5000000;i++); // delay
        //
        //             E N D   P L O T
        //
    }
#endif
     
    return( xe );
}

/*------------------------------------------------------------
| LookUpCoorespondingNumber
|-------------------------------------------------------------
|
| PURPOSE: To translate one number in an ordered table to the 
|          value found at the same rank in another table.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| v = LookUpCoorespondingNumber( 
|          In, InTable, OutTable, ItemCount );
|
| NOTE:  
|
| ASSUMES: Given value is in the table.
|          The tables are the same length.
|
| NOTE:
|
| HISTORY: 06.25.95 .
------------------------------------------------------------*/
f64
LookUpCoorespondingNumber( f64   In, 
                           f64*  InTable,
                           f64*  OutTable,
                           u32    ItemCount )
{
    u32 i;
    
    i = FindOffsetOfValueInOrderedVector( 
            In, InTable, ItemCount );
        
    return( OutTable[i] );
}

/*------------------------------------------------------------
| LowValue
|-------------------------------------------------------------
|
| PURPOSE: To find the lowest value of a list of doubles.
|
| DESCRIPTION:   
|           
| EXAMPLE: f64 L[] = { 123.123, 12321, 1232.2 };
|          m = LowValue( &L, 3 );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 07.31.95 
-----------------------------------------------------------*/
f64
LowValue( f64* AtItem, s32 ItemCount )
{
    s32  i;
    f64 v;
    f64 L;
    
    L = *AtItem;
    
    for( i = 0; i < ItemCount; i++ )
    {
        v = *AtItem++;
        
        if( v < L )
        {
            L = v;
        }
        
    }
    
    return( L );
}

/*------------------------------------------------------------
| Mean
|-------------------------------------------------------------
|
| PURPOSE: To calculate mean of a number buffer.
|
| DESCRIPTION:   
|           
| EXAMPLE: f64 L[] = { 123.123, 12321, 1232.2 };
|          m = Mean( &L, 3 );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 12.26.94 
-----------------------------------------------------------*/
f64
Mean( f64* AtItem, s32 ItemCount )
{
    s32  i;
    f64 Sum;
    f64 m;
    
    Sum = 0;
    
    for( i = 0; i < ItemCount; i++ )
    {
        Sum += *AtItem++;
    }
    
    m = Sum / ((f64) ItemCount);
    
    return( m );
}

/*------------------------------------------------------------
| Median
|-------------------------------------------------------------
|
| PURPOSE: To calculate median of a list of doubles.
|
| DESCRIPTION:   
|           
| EXAMPLE: f64 L[] = { 123.123, 123.21, 1232.2 };
|          m = Median( &L, 3 );
|
| NOTE: 
|
| ASSUMES: Given vector can be sorted in place.
|
| HISTORY: 06.17.95 from 'EstimateMedian'.
|          10.13.95 corrected even number case: was using
|                   1-based index instead of 0-based.
-----------------------------------------------------------*/
f64
Median( f64* AtItem, s32 ItemCount )
{
    f64  *AtMid;
    f64  *AtMidPlusOne;
    f64  AMedian;

    // Sort the replication in increasing order.
    SortVector( AtItem, ItemCount );
    
    if( ItemCount & 1 ) // If there are an odd number of items.
    {
        AtMid = &AtItem[(ItemCount>>1)];
    
        // The middle value is the median.
        AMedian = *AtMid;
    }
    else // An even number of items.
    {
        AtMid = &AtItem[(ItemCount>>1) - 1];
    
        AtMidPlusOne = AtMid+1;
        
        // The average of middle values is the median.
        AMedian = (*AtMid + *AtMidPlusOne)/2;
    }
    
    return( AMedian );
}

/*------------------------------------------------------------
| Median2
|-------------------------------------------------------------
|
| PURPOSE: To calculate median of a list of f64's.
|
| DESCRIPTION: Uses 'SelectNthSmallest' algorithm instead
| of sorting the vector which is faster.
|
| Timing tests:
|
| Method        999 Items       1000 Items
| -----------------------------------------------
| Median         10 secs           10 secs
| Median2        1.5 secs           3 secs
| -----------------------------------------------
|           
| EXAMPLE: f64 L[] = { 123.123, 123.21, 1232.2 };
|          m = Median2( &L, 3 );
|
| NOTE: 
|
| ASSUMES: Given vector can be rearranged in place.
|
|          'SelectNthSmallest' partitions list so that
|          all values at AtItem[IndexOfMiddleItem] and 
|          above are >= the lo-middle value and all 
|          values below AtItem[IndexOfMiddleItem] are
|          <= the lo-middle value.
|
| HISTORY: 10.13.95  from 'Median' and
|                   Num. Recipes in C page 341. Fully tested.
|          10.14.95 Use LowValue instead of second call
|                   to 'SelectNthSmallest' for even item
|                   counts.
|          04.26.96 Added special handling for the case of
|                   a single item.
-----------------------------------------------------------*/
f64
Median2( f64* AtItem, s32 ItemCount )
{
    f64 AMedian;
    s32 IndexOfMiddleItem;
        
    // Test for degenerate case.
    if( ItemCount == 1 )
    {
        return( *AtItem );
    }

    // If 'ItemCount' is odd, then 'IndexOfMiddleItem'
    // really refers to the middle item, else to the 
    // lower of the middle two items.   
    IndexOfMiddleItem = (ItemCount+1)>>1;

    AMedian = 
        SelectNthSmallest( AtItem, 
                           ItemCount, 
                           IndexOfMiddleItem );
    
    // If there are an even number of items.
    if( (ItemCount & 1) == 0 ) 
    {
        // The average the middle two values.

        // This assumes all values above the lo-middle item
        // have values >= the lo-middle item and the all 
        // values below the lo-middle item have values <= the 
        // lo-middle item.                             
        AMedian += LowValue( &AtItem[IndexOfMiddleItem], 
                             ItemCount - IndexOfMiddleItem );
                             
        AMedian /= 2;
    }
    
    return( AMedian );
}

/*------------------------------------------------------------
| Median3
|-------------------------------------------------------------
|
| PURPOSE: To calculate median of a list of f64's.
|
| DESCRIPTION: Same as 'Median2' but doesn't average when
| there are an even number of items, rather, the lower of
| the middle two is used.
|           
| EXAMPLE: f64 L[] = { 123.123, 123.21, 1232.2 };
|          m = Median3( &L, 3 );
|
| NOTE: 
|
| ASSUMES: Given vector can be rearranged in place.
|
|          'SelectNthSmallest' partitions list so that
|          all values at AtItem[IndexOfMiddleItem] and 
|          above are >= the lo-middle value and all 
|          values below AtItem[IndexOfMiddleItem] are
|          <= the lo-middle value.
|
| HISTORY: 08.04.98 from 'Median2'.
-----------------------------------------------------------*/
f64
Median3( f64* AtItem, u32 ItemCount )
{
    f64 AMedian;
    s32 IndexOfMiddleItem;
        
    // Test for degenerate case.
    if( ItemCount == 1 )
    {
        return( *AtItem );
    }

    // If 'ItemCount' is odd, then 'IndexOfMiddleItem'
    // really refers to the middle item, else to the 
    // lower of the middle two items.   
    IndexOfMiddleItem = (ItemCount+1)>>1;

    AMedian = 
        SelectNthSmallest( AtItem, 
                           ItemCount, 
                           IndexOfMiddleItem );
    
    return( AMedian );
}

/*------------------------------------------------------------
| MedianByte
|-------------------------------------------------------------
|
| PURPOSE: To find median value of a list of bytes.
|
| DESCRIPTION: Returns the nearest of the given bytes to the
| value that evenly divides the group into equal parts.  If
| there is and even number of bytes then the lower middle
| byte is used as the median.
|           
| EXAMPLE: u8 L[] = { 123, 242, 45 };
|          m = MedianByte( &L, 3 );
|
| NOTE: For now use floating point median subroutines but
|       make byte-specific routine later as needed.
|
| ASSUMES: 
|
| HISTORY: 08.04.98 from 'Median3'.
-----------------------------------------------------------*/
u32
MedianByte( u8* Buf, u32 Count )
{
    f64*    Items;
    u32     i, result;
    
    // Allocate an floating point item buffer.
    Items = MakeItems( Count, 0 );
    
    // Copy the bytes to the items.
    for( i = 0; i < Count; i++ )
    {
        Items[i] = (f64) Buf[i];

    }
    
    // Find the median value.
    result = (u32) Median3( Items, Count );
    
    // Delete the item buffer.
    free( Items );
    
    // Return the result value.
    return( result );
}

/*------------------------------------------------------------
| MedianDataPoint
|-------------------------------------------------------------
|
| PURPOSE: To find the data point closest to the median
|          of given points in an n-dimensional space.
|
| DESCRIPTION: Places the results at 'P'.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 05.02.96
|          02.01.00 Revised to use 'CopyRowToBuffer'.
------------------------------------------------------------*/
void
MedianDataPoint( Matrix* A, f64* P )
{
    s32 i;

    // Find the point in space closest to the median.
    MedianSpacePoint( A, P );
    
    // Find the actual data point closest to the space point.
    i = FindNearestOrdinalPoint( A, P );

    // Copy the nearest point to the result.
    CopyRowToBuffer( A, i, (u8*) P );
}

/*------------------------------------------------------------
| MedianOfColumn
|-------------------------------------------------------------
|
| PURPOSE: To calculate median of a column of a matrix
|
| DESCRIPTION:   
|           
| EXAMPLE: 
|          m = MedianOfColumn( MyMatrix, 3L );
|
| NOTE: Dynamically allocates and frees a working buffer.
|
| ASSUMES:
|
| HISTORY: 07.27.95 
-----------------------------------------------------------*/
f64
MedianOfColumn( Matrix* AMatrix, s32 Column )
{
    f64     TheMedian;
    f64*    AtVector;
    
    // Allocate a vector and copy data there.
    AtVector = (f64*) CopyColumnToNewBuffer( AMatrix, Column );
    
    TheMedian = Median2( AtVector, AMatrix->RowCount );
    
    free( (u8*) AtVector );
    
    return( TheMedian );
}

/*------------------------------------------------------------
| MedianSpacePoint
|-------------------------------------------------------------
|
| PURPOSE: To calculate the n-dimensional median point in a
|          matrix of points.
|
| DESCRIPTION: Each point occupies one row in the matrix,
| with each column devoted to a separate dimension.
|
| This routine treats each dimension independently for 
| computation of the median, and places the results at 'P'.
|
| Since each dimension is treated independently, the resulting
| point is a point in space but may not be an actual data
| point.  Use the routine 'FindNearestOrdinalPoint' to pass
| from a data space point to an actual data point.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 04.22.96
------------------------------------------------------------*/
void
MedianSpacePoint( Matrix* A, f64* P )
{
    s32 i,DimCount;
    
    // Get the number of dimensions.
    DimCount = A->ColCount;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        P[i] = MedianOfColumn( A, i );
    }
}

/*------------------------------------------------------------
| ModeDataPoint
|-------------------------------------------------------------
|
| PURPOSE: To find the data point closest to the mode
|          of given points in an n-dimensional space.
|
| DESCRIPTION: Places the results at 'P'.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 05.02.96 from 'MedianDataPoint'.
|          02.01.00 Revised to use 'CopyRowToBuffer'.
------------------------------------------------------------*/
void
ModeDataPoint( Matrix* A, f64* P )
{
    s32 i;

    // Find the point in space closest to the median.
    ModeSpacePoint( A, P );
    
    // Find the actual data point closest to the space point.
    i = FindNearestOrdinalPoint( A, P );

    // Copy the nearest point to the result.
    CopyRowToBuffer( A, i, (u8*) P );
}

/*------------------------------------------------------------
| ModeOfColumn
|-------------------------------------------------------------
|
| PURPOSE: To calculate mode of a column of a matrix
|
| DESCRIPTION:   
|           
| EXAMPLE: 
|          m = ModeOfColumn( MyMatrix, 3L );
|
| NOTE: Dynamically allocates and frees a working buffer.
|
| ASSUMES:
|
| HISTORY: 05.02.96 from 'MedianOfColumn'.
-----------------------------------------------------------*/
f64
ModeOfColumn( Matrix* AMatrix, s32 Column )
{
    f64     TheMode;
    f64*    AtVector;
    
    // Allocate a vector and copy data there.
    AtVector = (f64*) CopyColumnToNewBuffer( AMatrix, Column );
    
    TheMode = ModeOfItems( AtVector, AMatrix->RowCount );
    
    free( (u8*) AtVector );
    
    return( TheMode );
}

/*------------------------------------------------------------
| ModeOfItems
|-------------------------------------------------------------
|
| PURPOSE: To calculate mode of a buffer of numbers.
|
| DESCRIPTION: The extent of the items is subdivided by
| medial cuts until one quadrant contains no items.
|
| When that happens the quadrant with remaining data points
| is taken as the mode quadrant, and the mean of the extent
| of this quadrant is used.
|
| Returns this mean value which may or may not be an actual
| value in the list. 
|           
| EXAMPLE: 
|          m = ModeOfItems( Buf, 3 );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 05.02.96 
-----------------------------------------------------------*/
f64
ModeOfItems( f64* Items, s32 Count )
{
    f64     TheMode, Med;
    Extent* Ex;
    Extent* LoEx;
    Extent* HiEx;
    f64     Lo;
    f64     Hi;
    f64*    buf;
    List*   Pts;
    u32     IsInLo, IsInHi;
    
    // Find the extent of the given items.
    ExtentOfItems( Items, Count, &Lo, &Hi );

    // Test for simple case.
    if( Lo == Hi ) 
    {
        return( Lo );
    }
    
    // Add a tiny amount to the high extent so that all
    // items fall within the extent.
    Hi += ChopTolerance;
    
    // Make extent records.
    Ex   = MakeExtent( 1, &Lo, &Hi );
    LoEx = MakeExtent( 1, &Lo, &Hi );
    HiEx = MakeExtent( 1, &Lo, &Hi );

    // Make a list of points within the current extent.
    Pts = FindItemsWithinExtent( Ex, Items, Count );

Begin:

    // If there are points outside the current extent,
    // delete them.
    if( MarkPointsOutsideExtent( Pts, Ex ) )
    {
        DeleteMarkedItems( Pts );
    }

    // Make a number buffer from the list of points.
    buf = PointListToItems( Pts );
    
    // Find the median of the current extent points.
    Med = Median2( buf, Pts->ItemCount );

    // Discard the matrix.
    free( buf );
    
    // Make a low extent and a high extent.
    LoEx->Lo[0] = Ex->Lo[0];
    LoEx->Hi[0] = Med;
    
    HiEx->Lo[0] = Med;
    HiEx->Hi[0] = Ex->Hi[0];
    
    // Test if any points fall within the extents.
    IsInLo = IsPointsInExtent( Pts, LoEx );
    IsInHi = IsPointsInExtent( Pts, HiEx ); 
    
    // If either extent is empty, then the other is
    // the maximum density extent.
    if( IsInLo == 0 || IsInHi == 0 )
    {
        // Make the mode equal to the mean of the 
        // maximum density extent.
        //
        if( IsInLo )
        {
            TheMode = (LoEx->Hi[0] + LoEx->Lo[0]) / 2.;
        }
        else // The high extent has points.
        {
            TheMode = (HiEx->Hi[0] + HiEx->Lo[0]) / 2.;
        }
        
        // Discard the working buffers.
        free( Ex );
        free( LoEx );
        free( HiEx );
        DeleteList( Pts );

        // Return the result.
        return( TheMode );
    }
    
    // There are points in both extents here.
    
    // Choose the extent that has the least length as the 
    // new current extent.
    
    if( ( LoEx->Hi[0] - LoEx->Lo[0] ) <
        ( HiEx->Hi[0] - HiEx->Lo[0] ) )
    {
        *Ex = *LoEx; // Lower extent is smaller/higher density.
    }
    else
    { 
        *Ex = *HiEx; // Higher extent is smaller/higher density.
    }
    
    goto Begin;
}

/*------------------------------------------------------------
| ModeSpacePoint
|-------------------------------------------------------------
|
| PURPOSE: To calculate the n-dimensional mode point in a
|          matrix of points.
|
| DESCRIPTION: Returns the space point of the mode, that is,
| the highest density location.
|
| This routine treats each dimension independently for 
| computation of the mode, and places the results at 'P'.
|
| Since each dimension is treated independently, the resulting
| point is a point in space but may not be an actual data
| point.  Use the routine 'FindNearestOrdinalPoint' to pass
| from a data space point to an actual data point.
|
| Each point occupies one row in the matrix, with each column 
| devoted to a separate dimension.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 05.02.96 from 'MedianSpacePoint'.
------------------------------------------------------------*/
void
ModeSpacePoint( Matrix* A, f64* P )
{
    s32 i,DimCount;
    
    // Get the number of dimensions.
    DimCount = A->ColCount;
    
    // For each dimension.
    for( i = 0; i < DimCount; i++ )
    {
        P[i] = ModeOfColumn( A, i );
    }
}

/*------------------------------------------------------------
| MovingEntropyOfTrend
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving entropy of trend of 
|          items.
|
| DESCRIPTION: Returns result items.
|
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 07.22.96 from 'MovingWeight'.
-----------------------------------------------------------*/
void
MovingEntropyOfTrend(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    s32   SampleCount,
    s32   Period )
{
    s32     i;
    f64 w;
    
    // Calculate the first valid value.
//TBD   w = EntropyOfTrend( AtSample, Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = w;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
//TBD       *AtResult++ = EntropyOfTrend( 
//TBD                           &AtSample[i-Period+1],
//TBD                           Period );
    }
}

/*------------------------------------------------------------
| MovingEstimatedClusterCount
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving estimated cluster count
|          of a vector.
|
| DESCRIPTION: Returns result vector.
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: Period is less than the sample count.
|
| HISTORY: 07.22.95 .
|          07.29.95 Corrected fill value count at beginning.
-----------------------------------------------------------*/
void
MovingEstimatedClusterCount(
    f64  *AtInput,  // Input 
    f64  *AtWork1,  // Working buffer as big as input.
    f64  *AtWork2,  // Working buffer as big as input.
    f64  *AtResult, // Output buffer as big as input.
    s16   ItemCount,
    s16   Period )
{
    s16     i;
    f64 c;
#ifdef TESTING_ONLY
    s16     j;
    s8*     AtNumberString;
    s8*     AFileName;
    FILE*   AFile;
    
    AFileName = "D:Data:NG:NG95Z:NG95Z.Distribution50";

    AFile = ReOpenFile(AFileName);
#endif

        
    
    // Calculate the first valid value.
    c = (f64) EstimateClusterCount( AtInput, 
                                     AtWork1, 
                                     AtWork2, 
                                     Period );
#ifdef TESTING_ONLY
    // Save the distribution.
    for( j = 0; j < Period-1; j++ )
    {
        UseFixedPointFormat = 0;
        UseScientificFormat = 0;
            
        AtNumberString = 
                ConvertNumberToString( (Number) AtWork2[j] );

        fprintf(AFile,"%s\t",AtNumberString);
    }
    AtNumberString = 
            ConvertNumberToString( (Number) AtWork2[j] );

    fprintf(AFile,"%s\n",AtNumberString);
#endif

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = c;
    }
    
    // Compute remaining values.        
    for( ; i < ItemCount; i++ )
    {
printf("MovingEstimatedClusterCount: %d\n", i);


        *AtResult++ =  (f64) 
                        EstimateClusterCount( 
                                 &AtInput[i-Period+1],
                                 AtWork1, 
                                 AtWork2, 
                                 Period );
#ifdef TESTING_ONLY
    // Save the distribution.
    for( j = 0; j < Period-1; j++ )
    {
        UseFixedPointFormat = 0;
        UseScientificFormat = 0;
            
        AtNumberString = 
                ConvertNumberToString( (Number) AtWork2[j] );

        fprintf(AFile,"%s\t",AtNumberString);
    }
    AtNumberString = 
            ConvertNumberToString( (Number) AtWork2[j] );

    fprintf(AFile,"%s\n",AtNumberString);
#endif
    }

#ifdef TESTING_ONLY
CloseFile(AFile);
    
/* Set the file to an MPW document for now. */
SetFileType(AFileName,"TEXT");
SetFileCreator(AFileName,"MPS ");
#endif

}

/*------------------------------------------------------------
| MovingEstimatedClusterCount2
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving estimated cluster count
|          of a vector using method 2.
|
| DESCRIPTION: Returns result vector.
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: Period is less than the sample count.
|
| HISTORY: 07.30.95 .
-----------------------------------------------------------*/
void
MovingEstimatedClusterCount2(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    f64  *AtWork1,  // Working buffer as big as Period.
    f64  *AtWork2,  // Working buffer as big as Period.
    s32   SampleCount,
    s32   Period )
{
    s16     i;
    f64 c;
    
    // Calculate the first valid value.
    c = EstimateClusterCount2( AtSample,
                               AtWork1, 
                               AtWork2, 
                               Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = c;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        *AtResult++ =  EstimateClusterCount2( 
                               &AtSample[i-Period+1],
                               AtWork1, 
                               AtWork2, 
                               Period );

//printf("MovingEstimatedClusterCount2: %d  %lf\n", i, AtResult[-1]);
    }
}

/*------------------------------------------------------------
| MovingEstimatedMedian
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving estimated median of a 
|          vector.
|
| DESCRIPTION: Returns result vector.
| First n-1 values of result contain original input values.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: Period is less than the sample count.
|
| HISTORY: 07.03.95 .
|          07.14.95 sped up indexing.
-----------------------------------------------------------*/
void
MovingEstimatedMedian(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    f64  *AtWork,   // A work space as big as period.
    s16   SampleCount,
    s16   Period )
{
    s16   i;
    s16   last;
    f64  *AtInput;
    
    // Copy first few values to result.
    AtInput = AtSample;
    last = Period - 1;
    for( i = 0; i < last; i++ )
    {
        *AtResult++ = *AtInput++;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
printf("MovingEstimatedMedian: %d\n", i);
        *AtResult++ =  EstimateMedian( &AtSample[i-Period+1],
                                       AtWork, 
                                       Period );
    }
}

/*------------------------------------------------------------
| MovingEstimatedMedianOfMatrix
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving estimated median of a 
|          vector.
|
| DESCRIPTION: Calcs column-wise moving median for all columns.
|
| First n-1 rows of result contain original input values.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 07.03.95 .
-----------------------------------------------------------*/
Matrix*
MovingEstimatedMedianOfMatrix( Matrix* In, s16 Period )
{
    Matrix* Out;
    f64*   AtSample;
    f64*   AtWork;
    f64*   AtResult;
    s32     i, j;
    s32     rows;
    s32     columns;
    s32     SizeOfWorkBuffer;
    f64**   A;
    f64**   B;
    
    rows    = In->RowCount;
    columns = In->ColCount;
    
    // Allocate the result matrix.
    Out = MakeMatrix( (s8*) "Result", rows, columns );
    
    // If period is longer than column, just return.
    if( rows < Period )
    {
        return( Out );
    }
    
    // Allocate space for working buffers: column size.
    
    SizeOfWorkBuffer = sizeof( f64 ) * rows;
    
    AtSample = (f64*) malloc( SizeOfWorkBuffer );
    AtResult = (f64*) malloc( SizeOfWorkBuffer );
    AtWork   = (f64*) malloc( sizeof( f64 ) * Period );
    
    A = (f64**) In->a;
    B = (f64**) Out->a;
    
    // For each column...
    for( j = 0; j < columns; j++ )
    {
        printf( "MovingEstimatedMedianOfMatrix, column: %ld\n", j);

        // Copy column to sample buffer.
        for( i = 0; i < rows; i++ )
        {
            AtSample[i] = A[i][j];
        }
        
        MovingEstimatedMedian( AtSample, // Input 
                               AtResult, // Output
                               AtWork,   // A work space as big as period.
                               rows,     // SampleCount
                               Period );

        // Move result to result matrix.
        for( i = 0; i < rows; i++ )
        {
            B[i][j] = AtResult[i];
        }
    }
    
    // Free working buffers.
    free( (u8*) AtSample );
    free( (u8*) AtResult );
    free( (u8*) AtWork );
    
    // Return the result.
    return( Out );
}

/* -----------------------------------------------------------
| MovingMostConsistentLogPrice
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving estimate of the most
|          consistent log prices of given log prices.
|
| DESCRIPTION: Returns result items.
|
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 08.12.96 from 'MovingTrend'.
-----------------------------------------------------------*/
#if 0 // Commented out because 'MostConsistentLogPrice'
      // isn't available.   
void
MovingMostConsistentLogPrice(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    s32   SampleCount,
    s32   Period,    // Basis period
    s32   Offset )   // Offset from first day in basis 
                     // period to the estimated price.
{
    s32     i;
    f64 w;

    // Calculate the first valid value.
    w = MostConsistentLogPrice( AtSample, 
                             Period, 
                             Offset,
                             AtSample[SampleCount-1] );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = w;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        *AtResult++ = MostConsistentLogPrice( 
                            &AtSample[i-Period+1],
                            Period, 
                            Offset,
                            AtResult[-1] );
    }
}
#endif

/*------------------------------------------------------------
| MovingPermutationNumber
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving permutation number of 
|          items.
|
| DESCRIPTION: Returns result items.
|
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 07.21.96 from 'MovingWeight'.
-----------------------------------------------------------*/
void
MovingPermutationNumber(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    s32   SampleCount,
    s32   Period )
{
    s32     i;
    f64 w;
    
    // Calculate the first valid value.
    w = PermutationNumberOfItems( AtSample, Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = w;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        *AtResult++ = PermutationNumberOfItems( 
                            &AtSample[i-Period+1],
                            Period );
    }
}

/*------------------------------------------------------------
| MovingTrend
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving degree of trend of 
|          items.
|
| DESCRIPTION: Returns result items.
|
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 07.22.96 from 'MovingWeight'.
-----------------------------------------------------------*/
void
MovingTrend(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    s32   SampleCount,
    s32   Period )
{
    s32     i;
    f64 w;
    
    // Calculate the first valid value.
    w = DegreeOfTrend2( AtSample, Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = w;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        *AtResult++ = DegreeOfTrend2( 
                            &AtSample[i-Period+1],
                            Period );
    }
}

/*------------------------------------------------------------
| MovingReversePermutationNumber
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving reverse permutation 
|          number of items.
|
| DESCRIPTION: Returns result items.
|
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 07.21.96 from 'MovingWeight'.
-----------------------------------------------------------*/
void
MovingReversePermutationNumber(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    s32   SampleCount,
    s32   Period )
{
    s32     i;
    f64 w;
    
    // Calculate the first valid value.
    w = ReversePermutationNumberOfItems( AtSample, Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = w;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        *AtResult++ = ReversePermutationNumberOfItems( 
                            &AtSample[i-Period+1],
                            Period );
    }
}


/*------------------------------------------------------------
| MovingWeight
|-------------------------------------------------------------
|
| PURPOSE: To calculate n-day moving weight of items.
|
| DESCRIPTION: Returns result items.
|
| First n values of result contain the first valid value.
|           
| EXAMPLE: 
|
| NOTE:  
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 07.16.96 from 'MovingEntropy'.
-----------------------------------------------------------*/
void
MovingWeight(
    f64  *AtSample, // Input 
    f64  *AtResult, // Output
    s32   SampleCount,
    s32   Period )
{
    s32     i;
    f64 w;
    
    // Calculate the first valid value.
    w = WeighItems( AtSample, Period );

    // Copy first value into range not calculated.
    for( i = 0; i < Period; i++ )
    {
        *AtResult++ = w;
    }
    
    // Compute remaining values.        
    for( ; i < SampleCount; i++ )
    {
        *AtResult++ = WeighItems( 
                            &AtSample[i-Period+1],
                            Period );
    }
}

/*------------------------------------------------------------
| Resample
|-------------------------------------------------------------
|
| PURPOSE: To resample items with replacement.
|
| DESCRIPTION: Expects the address of a buffer, address of
| a replication, and a count of entries in the vector. 
|
| EXAMPLE:  
|
|          Resample( AtSample, AtReplication, ItemCount );
|
| NOTE: Basic building block of bootstrap methods.
|       See "An Introduction to the Bootstrap" for complete 
|       explanation of resampling.   
|
|       See 'Numerical Recipes' for an explanation of sub-random 
|       sequences.
|
| The old 'RandomInteger' method has more bias and converges 
| more slowly: use 'SubRandomInteger' instead.  
| See 'Trading Notes 4.9.95' notebook for this analysis.
|
| This is the way it used to be:
|       AnIndex = RandomInteger(ItemCount);
|
| ASSUMES: 'BeginSubRandomSequence' called.
|
| HISTORY: 12.19.94 .
|          12.26.94 changed 'RandomFraction' to 
|                   'RandomInteger'.
|          01.29.96 changed 'RandomInteger' to 
|                   'SubRandomInteger'.
------------------------------------------------------------*/
void
Resample( f64* AtSample, f64* AtReplication, s16 ItemCount )
{
    s16 i;
    s16 AnIndex;
    
    for( i = 0; i < ItemCount; i++ )
    {
        AnIndex = SubRandomInteger( (s32) ItemCount );
        
        *AtReplication++ = AtSample[AnIndex];
    }
}

/*------------------------------------------------------------
| ResampleBinCounts
|-------------------------------------------------------------
|
| PURPOSE: To count how many samples randomly drawn from of a 
|          list, with replacement, fall into a number of 
|          evenly spaced bins.
|
| DESCRIPTION: Results in a list of counts, one for each bin.
|              Each count field is 2 bytes long.
|
| EXAMPLE:  
|    ResampleBinCounts( MyData, SampleCount, 
|                       ResultBuffer, 10, ResampleCount );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.13.95 
|          01.29.96 replaced 'RandomInteger' with 
|                   'SubRandomInteger'.
------------------------------------------------------------*/
void
ResampleBinCounts( f64* AtData, s16 ItemCount, 
                   s16*  AtBins, s16 BinCount, 
                   s16 ResampleCount )
{
    s16   AnIndex;
    f64  ASample;
    f64  BinSize;
    f64  MinSample;
    f64  MaxSample;
    f64  OverallRange;
    f64* AtSample;
    s16*  AtBin;
    s16   i;
    s16   bin;
    
    // Clear the bin counters to zero.
    AtBin = AtBins;
    for( i = 0; i < BinCount; i++ )
    {
        *AtBin++ = 0;
    }
    
    // Find the minimum and maximum values to define
    // the range to be subdivided.
    
    AtSample = AtData;
    
    // Start with the first value and adjust.
    MinSample = *AtSample++;
    MaxSample = MinSample;
    
    for( i = 1; i < ItemCount; i++ )
    {
        ASample = *AtSample++;
        
        if( ASample < MinSample )  MinSample = ASample;
        if( ASample > MaxSample )  MaxSample = ASample;
    }
    
    OverallRange = MaxSample - MinSample;
    BinSize      = OverallRange / BinCount;
    
    // For each sample
    for( i = 0; i < ResampleCount; i++ )
    {
        AnIndex = SubRandomInteger( (s32) ItemCount );
        
        ASample = AtData[ AnIndex ];
    
        bin = (s16) ( (ASample - MinSample) / BinSize );
        
        AtBins[bin]++;
    }
}

/*------------------------------------------------------------
| ResampleBinCountsWithFixedBinWidth
|-------------------------------------------------------------
|
| PURPOSE: To count how many samples randomly drawn from of a 
|          list, with replacement, fall into a number of 
|          fixed width bins.
|
| DESCRIPTION: Results in a list of counts, one for each bin.
|              Each count field is 2 bytes long.
|              Returns the bin count.
|
| EXAMPLE:  
|    c = ResampleBinCountsWithFixedBinWidth( MyData, 
|                                            SampleCount, 
|                                            ResultBuffer, 
|                                            .045, 
|                                            ResampleCount );
|
| NOTE: 
|
| ASSUMES: 'ResultBuffer' refers to an area large enough for
|          all of the bin counts.
|
| HISTORY: 07.30.95 
|          01.29.96 replaced 'RandomInteger' with 
|                   'SubRandomInteger'.
------------------------------------------------------------*/
s16
ResampleBinCountsWithFixedBinWidth( 
    f64* AtData, 
                            s16   SampleCount, 
                            s16*  AtBins,
                            f64  BinWidth,
                            s16   ResampleCount )
{
    s16   AnIndex;
    f64  ASample;
    f64  MinSample;
    f64  MaxSample;
    f64  OverallRange;
    f64* AtSample;
    s16*  AtBin;
    s16   i;
    s16   bin;
    s16   BinCount;
    
    // Find the minimum and maximum values to define
    // the range to be subdivided.
    
    AtSample = AtData;
    
    // Start with the first value and adjust.
    MinSample = *AtSample++;
    MaxSample = MinSample;
    
    for( i = 1; i < SampleCount; i++ )
    {
        ASample = *AtSample++;
        
        if( ASample < MinSample )  MinSample = ASample;
        if( ASample > MaxSample )  MaxSample = ASample;
    }
    
    OverallRange = MaxSample - MinSample;
    
    // Calculate the number of bins.
    BinCount = (s16) ceil( OverallRange / BinWidth );
    
    // Clear the bin counters to zero.
    AtBin = AtBins;
    for( i = 0; i < BinCount; i++ )
    {
        *AtBin++ = 0;
    }
    
    // For each sample
    for( i = 0; i < ResampleCount; i++ )
    {
        AnIndex = SubRandomInteger( (s32) SampleCount );
        
        ASample = AtData[ AnIndex ];
    
        bin = (s16) ( (ASample - MinSample) / BinWidth );
        
        AtBins[bin]++;
    }
    
    return( BinCount );
}       

/*------------------------------------------------------------
| ResampleByWeight
|-------------------------------------------------------------
|
| PURPOSE: To resample weighted items with replacement.
|
| DESCRIPTION: Expects the address of a buffer, address of
| a replication, and a count of entries in the vector and
| the weights assigned to each entry. 
|
| EXAMPLE:  
|
|   ResampleByWeight( AtSample, 
|                     AtReplication, 
|                     ItemCount, 
|                     W );
|
| NOTE: To guard against subtle interactions between the
|       sample and the subrandom algorithm, shuffle the 
|       sample and recompute the weights periodically.
|
| ASSUMES: 'BeginSubRandomSequence' called.
|          The weight count is the same as the ItemCount:
|          there must be a weight for each item, and the
|          weight table cumulative weights must be current.
|          See 'SumWeights()'.
|
| HISTORY: 07.05.97 from 'Resample'.
------------------------------------------------------------*/
void
ResampleByWeight( f64* AtSample, 
                  f64* AtReplication, 
                  s16   ItemCount,
                  Wt*   W )
{
    s16 i;
    s16 AnIndex;
    
    for( i = 0; i < ItemCount; i++ )
    {
//TBD       AnIndex = PickSubRandomWeight( W );

        *AtReplication++ = AtSample[AnIndex];
    }
}

/*------------------------------------------------------------
| ResampleVector
|-------------------------------------------------------------
|
| PURPOSE: To resample XY values from a vector.
|
| DESCRIPTION: Expects a sample vector and a replication
| vector.  The count of the replication vector determines
| how many resamples are produced: the result vector is filled.
|
| Every SampleCount interations, the original sample is 
| shuffled using the pseudo-random number generator.
|
| EXAMPLE:  
|
|          ResampleVector( AtSample, AtReplication );
|
| NOTE:  
|
| ASSUMES: Sample points can be shuffled.
|
| HISTORY: 04.11.96
------------------------------------------------------------*/
void
ResampleVector( Vector* ASample, Vector* Result )
{
    s32     i,j;
    s32     ItemCount, ResultCount;
    f64*    sX;
    f64*    sY;
    f64*    rX;
    f64*    rY;
    
    sX = ASample->X;
    sY = ASample->Y;
    rX = Result->X;
    rY = Result->Y;
    
    ItemCount   = ASample->ItemCount;
    ResultCount = Result->ItemCount;
    
    for( i = 0; i < ResultCount; i++ )
    {
        if( i % ItemCount == 0 )
        {
            ShuffleVector( ASample );
        }
        
        j = SubRandomInteger( ItemCount );
        
        rX[i] = sX[j];
        rY[i] = sY[j];
    }
}

/*------------------------------------------------------------
| SelectBin
|-------------------------------------------------------------
|
| PURPOSE: To select one of several weighted bins using 
|          sub-random selection.
|
| DESCRIPTION: Result is the index of the selected bin.
|
| The weighting of bins is controlled by the 'Divisions' 
| array which specifies the subdivision of the range between
| 0 and 1.  If a subrandomly generated number falls between
| two divisions cooresponding to a bin, than that bin is 
| selected.
|
| For example, three bins may be weighted using this array of
| divisions:
|
| f64 Divs[2]; // The number of divisions needed is one
|               // less than the number of bins.
|
| Divs[0] = .2; // Any number <= .2 selects bin 0.
| Divs[1] = .6; // Any number > .2 and <= .6 selects bin 1.
|               // Any number > .6 selects bin 2.
|
| ABin = SelectBin( Divs, 3 );
|
| EXAMPLE:  
|          b = SelectBin( Weights, BinCount );
|
| NOTE: Subrandom selection more completely ranges across 
|       the sample space than does pseudo-random selection. 
|
|       Could use binary search, but number of bins is expected
|       to be small.  Save this enhancement for later.
|
| ASSUMES: Subrandom number generator has been set up.
|          'Divisions' array is sorted in increasing order.
|
| HISTORY: 01.29.95
------------------------------------------------------------*/
s32
SelectBin( f64* Divisions, s32 BinCount )
{
    f64 Fraction;
    s32  i;
    s32  BinLimit;
    
    Fraction = SubRandomFraction();
    
    BinLimit = BinCount - 1;
    
    for( i = 0; i < BinLimit; i++ )
    {
        if( Fraction < Divisions[i] )
        {
            return( i );
        }
    }
    
    return( BinLimit );
}

/*------------------------------------------------------------
| SelectNthSmallest
|-------------------------------------------------------------
|
| PURPOSE: To select the nth smallest value in a vector of 
|          f64's.
|
| DESCRIPTION: Uses 'select' algorithm from
| 'Numerical Recipes in C' page 342.
|           
| EXAMPLE: f64 L[] = { 1.11, 2.21, 23.9 };
|          s = SelectNthSmallest( &L, 3, 2 );
|
|        result: s = 2.21
|
| NOTE: 
|
| ASSUMES: Given vector can be rearranged in place.
|
| HISTORY: 10.13.95 from 'Numerical' Recipes in C with 
|                   adjustments for 0-based arrays instead 
|                   of 1-based.
|          04.26.96 added special handling for degenerate
|                   case of only one item.
-----------------------------------------------------------*/
f64
SelectNthSmallest( f64* v, s32 ItemCount, s32 N )
{
    #define SWAP(a,b) {temp=(a);(a)=(b);(b)=temp;}
    
    u32  Lo, Hi, R, L, L1, M;
    f64 a, temp;
    
    // Test for degenerate case.
    if( ItemCount == 1 )
    {
        return( *v );
    }
    
    // Change from 1-based index to 0-based offset.
    N--;
    L = 0;
    R = ItemCount - 1;
    
    while(1)
    {
        L1 = L + 1;

        if( R <= L1 )
        { // Active parition contains 1 or 2 elements.
        
            if( R == L1 && v[R] < v[L] )
            { // Case of 2 elements.
                
                SWAP( v[L], v[R] )
            }
            
            return( v[N] );
        }
        else
        {
            // Choose median of left, center, and right
            // elements as partitioning element a.
            //
            M = ( L + R ) >> 1;
            
            // Rearrange so that v[L1] <= v[L],
            // v[R] >= v[L].
            //
            SWAP( v[M], v[L1] )
            
            if( v[L1] > v[R] ) SWAP( v[L1], v[R] )
            
            if( v[L]  > v[R] ) SWAP( v[L], v[R] )
            
            if( v[L1] > v[L] ) SWAP( v[L1], v[L] )
            
            // Initialize pointers for partioning.
            Lo = L1;
            Hi = R;
            a  = v[L]; // Partitioning element.
            
            while(1)
            {
            #if 0
                // Scan up to find element > a.
                MoveLo:
                    Lo++;
                    if( Lo == Hi ) break;  // Partitioning complete.
                    if( v[Lo] < a ) goto MoveLo; 
                
                MoveHi:
                    Hi--;
                    if( Lo == Hi ) break; // Partitioning complete.
                    if( v[Hi] > a ) goto MoveHi;
            #endif
            
                do Lo++; while( v[Lo] < a );
                do Hi--; while( v[Hi] > a );
                if( Hi < Lo ) break;    
                SWAP( v[Lo], v[Hi] )
            }
            
            v[L] = v[Hi]; // Insert partitioning element.
            v[Hi] = a;
            
            if( Hi >= N ) 
            {
                R = Hi - 1; // Keep active partition that contains
                            // the Nth element.
            }
            
            if( Hi <= N )
            {
                L = Lo;
            }
        }
    }
}

/*------------------------------------------------------------
| SmoothMatrix
|-------------------------------------------------------------
|
| PURPOSE: To smooth a matrix using the mean of
| the 8 nearest neighbors for n-passes.
|
| DESCRIPTION:  Returns smoothed matrix. Dynamically allocates 
| and frees working buffers.
|
| EXAMPLE:  
|
| result = SmoothMatrix( m, n );
|
| NOTE: Not as accurate as 'SmoothMatrixEstimatedMedian' but
|       much faster. 
|
| ASSUMES: OK to mess up the data in the input matrix
|
| HISTORY: 09.12.96 from 'SmoothMatrixEstimatedMedian'.
|          02.01.97 used 'DuplicateMatrix' so that 0 passes
|                   produces correct result.
------------------------------------------------------------*/
Matrix*
SmoothMatrix( Matrix* In, s16 passes )
{
    Matrix* Out;
    f64**   t;
    s32     i, j;
    s32     rows;
    s32     columns;
    f64**   A;
    f64**   B;
    
//  DrawStringOnLine( 
//          10, Line1,
//          "SmoothMatrix: %s", In->FileName);
    
    rows    = In->RowCount;
    columns = In->ColCount;
        
    // Allocate the result matrix.
    Out = DuplicateMatrix( In );
    
    A = (f64**) In->a;
    B = (f64**) Out->a;
    
    while( passes-- )
    {
//      DrawStringOnLine( 
//          10, Line2,
//          "SmoothMatrix: passes to go %d", passes + 1);

        // For upper left corner use 3 neighbors.
        B[0][0] = (A[0][0] +
                   A[0][1] +
                   A[1][0] +
                   A[1][1] ) / 4.;
    
        // For upper right corner use 3 neighbors.
        B[0][columns - 1] =  
            (A[0][ columns - 1 ] +
             A[0][ columns - 2 ] +
             A[1][ columns - 2 ] +
             A[1][ columns - 1 ]) / 4.;

        // For lower left corner use 3 neighbors.
        B[rows - 1][0] = 
            ( A[rows - 1][0] +
              A[rows - 2][0] +
              A[rows - 2][1] +
              A[rows - 1][1] ) / 4.;

        // For lower right corner use 3 neighbors.
        B[rows - 1][columns - 1] = 
            ( A[rows - 1][columns - 1] +
              A[rows - 2][columns - 1] +
              A[rows - 2][columns - 2] +
              A[rows - 1][columns - 2] ) / 4.;
        
        // For top border.
        for( j = 1; j < columns - 1; j++ )
        {
            B[0][j] = 
                ( A[0][j] +
                  A[0][j - 1] +
                  A[0][j + 1] +
                  A[1][j - 1] +
                  A[1][j] +
                  A[1][j + 1] ) / 6.;
        }
        
        // For bottom border.
        for( j = 1; j < columns - 1; j++ )
        {
            B[rows-1][j] =
                ( A[rows-1][j] +
                  A[rows-1][j - 1] +
                  A[rows-1][j + 1] +
                  A[rows-2][j - 1] +
                  A[rows-2][j] +
                  A[rows-2][j + 1] ) / 6.;
        }
        
        // For left border.
        for( i = 1; i < rows - 1; i++ )
        {
            B[i][0] = 
                ( A[i][0] +
                  A[i - 1][0] +
                  A[i + 1][0] +
                  A[i - 1][1] +
                  A[i][1] +
                  A[i + 1][1] ) / 6.;
        }
        
        // For right border.
        for( i = 1; i < rows - 1; i++ )
        {
            B[i][columns - 1] =
                ( A[i][columns - 1] +
                  A[i - 1][columns - 1] +
                  A[i + 1][columns - 1] +
                  A[i - 1][columns - 2] +
                  A[i][columns - 2] +
                  A[i + 1][columns - 2] ) / 6.;
        }
        
        // For each inner row, borders excluded.
        for( i = 1; i < rows - 1; i++ )
        {
//          DrawStringOnLine( 
//              10, Line3,
//              "row: %d", i );
                
            // For each inner column, borders excluded.
            for( j = 1; j < columns - 1; j++ )
            {
                B[i][j] = 
                    ( A[i][j] +
                      A[i - 1][j - 1] +
                      A[i - 1][j] +
                      A[i - 1][j + 1] +
                      A[i][j - 1] +
                      A[i][j + 1] +
                      A[i + 1][j - 1] +
                      A[i + 1][j] +
                      A[i + 1][j + 1] ) / 9.;
            }
        }
        
        // If there are remaining passes, exchange the data
        // for the matrices
        if( passes )
        {
            t = (f64**) In->a;
            In->a = Out->a;
            Out->a = (u8*) t;
            
            A = (f64**) In->a;
            B = (f64**) Out->a;
        }
    }
        
    // Return the result.
    return( Out );
}

/*------------------------------------------------------------
| SmoothMatrixDiagonal
|-------------------------------------------------------------
|
| PURPOSE: To smooth a matrix using the mean of
| the negative diagonal (SW-NE) neighbor for n-passes.
|
| DESCRIPTION:  Returns smoothed matrix. Dynamically allocates 
| and frees working buffers.
|
| EXAMPLE:  
|
| result = SmoothMatrixDiagonal( m, n );
|
| NOTE: Only uses one of the neighbors so that this routine
|       can be used for time-ordered data without distorting
|       causal ordering.
|
| ASSUMES: OK to mess up the data in the input matrix
|
| HISTORY: 02.03.96 from 'SmoothMatrix'.
------------------------------------------------------------*/
Matrix*
SmoothMatrixDiagonal( Matrix* In, s16 passes )
{
    Matrix* Out;
    f64**   t;
    s32     i, j;
    s32     rows;
    s32     columns;
    f64**   A;
    f64**   B;
    
    rows    = In->RowCount;
    columns = In->ColCount;
        
    // Allocate the result matrix.
    Out = DuplicateMatrix( In );
    
    A = (f64**) In->a;
    B = (f64**) Out->a;
    
    while( passes-- )
    {
        // For upper left corner: no neighbors.
        B[0][0] = A[0][0];
    
        // For upper right corner use 1 neighbor.
        B[0][columns - 1] =  
            (A[0][ columns - 1 ] +
             A[1][ columns - 2 ] )/2.;

        // For lower left corner use 1 neighbor.
        B[rows - 1][0] = 
            ( A[rows - 1][0] +
              A[rows - 2][1] )/2.;

        // For lower right corner: no neighbors.
        B[rows - 1][columns - 1] = A[rows - 1][columns - 1];
        
        // For top border.
        for( j = 1; j < columns - 1; j++ )
        {
            B[0][j] = 
                ( A[0][j] +
                  A[1][j - 1])/2.;
        }
        
        // For bottom border.
        for( j = 1; j < columns - 1; j++ )
        {
            B[rows-1][j] =
                ( A[rows-1][j] +
                  A[rows-2][j + 1] )/2.;
        }
        
        // For left border.
        for( i = 1; i < rows - 1; i++ )
        {
            B[i][0] = 
                ( A[i][0] +
                  A[i - 1][1] )/2.;
        }
        
        // For right border.
        for( i = 1; i < rows - 1; i++ )
        {
            B[i][columns - 1] =
                ( A[i][columns - 1] +
                  A[i + 1][columns - 2] )/2.;
        }
        
        // For each inner row, borders excluded.
        for( i = 1; i < rows - 1; i++ )
        {
            // For each inner column, borders excluded.
            for( j = 1; j < columns - 1; j++ )
            {
                B[i][j] = 
                    ( A[i][j] +
                      A[i + 1][j - 1] )/2.;
                      
                    // For both neighbors:
                    //( A[i][j] +
                    //  A[i - 1][j + 1] +
                    //  A[i + 1][j - 1] )/3.;
            }
        }
        
        // If there are remaining passes, exchange the data
        // for the matrices.
        if( passes )
        {
            t = (f64**) In->a;
            In->a = Out->a;
            Out->a = (u8*) t;
            
            A = (f64**) In->a;
            B = (f64**) Out->a;
        }
    }
        
    // Return the result.
    return( Out );
}

/*------------------------------------------------------------
| SmoothMatrixEstimatedMedian
|-------------------------------------------------------------
|
| PURPOSE: To smooth a matrix using the estimated median of
| the 8 nearest neighbors for n-passes.
|
| DESCRIPTION: Uses bootstrap to estimate median.
| Returns smoothed matrix. Dynamically allocates and frees
| working buffers.
|
| EXAMPLE:  
|
| result = SmoothMatrixEstimatedMedian( m, n );
|
| NOTE:  
|
| ASSUMES: OK to mess up the data in the input matrix
|
| HISTORY: 07.09.95 .
|          01.24.96 Fixed matrix exchange for multiple passes.
|          02.01.96 Added center of submatrix into median
|                   process.
|          04.11.96 Added test for identical cells to avoid
|                   wasting time in finding the median.
|          01.31.97 Added 'ProcessPendingEvents'.
------------------------------------------------------------*/
Matrix*
SmoothMatrixEstimatedMedian( Matrix* In, s16 passes )
{
    Matrix* Out;
    f64**   t;
    
    f64    AtSample[9];
    f64    AtWork[9];
    s32     i, j;
    s32     rows;
    s32     columns;
    f64**   A;
    f64**   B;
    
//  DrawStringOnLine( 
//          10, Line1,
//          "SmoothMatrix: %s", In->FileName);
    
    rows    = In->RowCount;
    columns = In->ColCount;
        
    // Allocate the result matrix.
    Out = MakeMatrix( (s8*) "Result", rows, columns );
    
    A = (f64**) In->a;
    B = (f64**) Out->a;
    
    while( passes-- )
    {
//      DrawStringOnLine( 
//          10, Line2,
//          "SmoothMatrix: passes to go %d", passes + 1);

        // For upper left corner use 3 neighbors.
        AtSample[0] = A[0][0];
        AtSample[1] = A[0][1];
        AtSample[2] = A[1][0];
        AtSample[3] = A[1][1];
        B[0][0] = EstimateMedian( AtSample, AtWork, 4);
    
        // For upper right corner use 3 neighbors.
        AtSample[0] = A[0][ columns - 1 ];
        AtSample[1] = A[0][ columns - 2 ];
        AtSample[2] = A[1][ columns - 2 ];
        AtSample[3] = A[1][ columns - 1 ];
        B[0][columns - 1] =  
                 EstimateMedian( AtSample, AtWork, 4);

        // For lower left corner use 3 neighbors.
        AtSample[0] = A[rows - 1][0];
        AtSample[1] = A[rows - 2][0];
        AtSample[2] = A[rows - 2][1];
        AtSample[3] = A[rows - 1][1];
        B[rows - 1][0] = 
                 EstimateMedian( AtSample, AtWork, 4);

        // For lower right corner use 3 neighbors.
        AtSample[0] = A[rows - 1][columns - 1];
        AtSample[1] = A[rows - 2][columns - 1];
        AtSample[2] = A[rows - 2][columns - 2];
        AtSample[3] = A[rows - 1][columns - 2];
        B[rows - 1][columns - 1] = 
                 EstimateMedian( AtSample, AtWork, 4);
        
        // For top border.
        for( j = 1; j < columns - 1; j++ )
        {
            AtSample[0] = A[0][j];
            AtSample[1] = A[0][j - 1];
            AtSample[2] = A[0][j + 1];
            AtSample[3] = A[1][j - 1];
            AtSample[4] = A[1][j];
            AtSample[5] = A[1][j + 1];
            B[0][j] = 
                 EstimateMedian( AtSample, AtWork, 6);
        }
        
        // For bottom border.
        for( j = 1; j < columns - 1; j++ )
        {
            AtSample[0] = A[rows-1][j];
            AtSample[1] = A[rows-1][j - 1];
            AtSample[2] = A[rows-1][j + 1];
            AtSample[3] = A[rows-2][j - 1];
            AtSample[4] = A[rows-2][j];
            AtSample[5] = A[rows-2][j + 1];
            B[rows-1][j] =
                 EstimateMedian( AtSample, AtWork, 6);
        }
        
        // For left border.
        for( i = 1; i < rows - 1; i++ )
        {
            AtSample[0] = A[i][0];
            AtSample[1] = A[i - 1][0];
            AtSample[2] = A[i + 1][0];
            AtSample[3] = A[i - 1][1];
            AtSample[4] = A[i][1];
            AtSample[5] = A[i + 1][1];
            B[i][0] = 
                 EstimateMedian( AtSample, AtWork, 6);
        }
        
        // For right border.
        for( i = 1; i < rows - 1; i++ )
        {
            AtSample[0] = A[i][columns - 1];
            AtSample[1] = A[i - 1][columns - 1];
            AtSample[2] = A[i + 1][columns - 1];
            AtSample[3] = A[i - 1][columns - 2];
            AtSample[4] = A[i][columns - 2];
            AtSample[5] = A[i + 1][columns - 2];
            B[i][columns - 1] =
                 EstimateMedian( AtSample, AtWork, 6);
        }
        
        // For each inner row, borders excluded.
        for( i = 1; i < rows - 1; i++ )
        {
//          DrawStringOnLine( 
//              10, Line3,
//              "row: %d", i );
            // Allow time to other processes.
//          ProcessPendingEvents();
                
            // For each inner column, borders excluded.
            for( j = 1; j < columns - 1; j++ )
            {
                AtSample[0] = A[i][j];
                AtSample[1] = A[i - 1][j - 1];
                AtSample[2] = A[i - 1][j];
                AtSample[3] = A[i - 1][j + 1];
                AtSample[4] = A[i][j - 1];
                AtSample[5] = A[i][j + 1];
                AtSample[6] = A[i + 1][j - 1];
                AtSample[7] = A[i + 1][j];
                AtSample[8] = A[i + 1][j + 1];
                
                // If any value differs
                if( AtSample[0] != AtSample[1] ||
                    AtSample[0] != AtSample[2] ||
                    AtSample[0] != AtSample[3] ||
                    AtSample[0] != AtSample[4] ||
                    AtSample[0] != AtSample[5] ||
                    AtSample[0] != AtSample[6] ||
                    AtSample[0] != AtSample[7] ||
                    AtSample[0] != AtSample[8] )
                {
                    B[i][j] = 
                        EstimateMedian( AtSample, AtWork, 9);
                }
                else // Use any of the samples because they
                     // are identical.
                {
                    B[i][j] = A[i][j];
                }
            }
        }
        
        // If there are remaining passes, exchange the data
        // for the matrices
        if( passes )
        {
            t = (f64**) In->a;
            In->a = Out->a;
            Out->a = (u8*) t;
            
            A = (f64**) In->a;
            B = (f64**) Out->a;
        }
    }
        
    // Return the result.
    return( Out );
}

/*------------------------------------------------------------
| SmoothMatrixEstimatedMedianDiscrete
|-------------------------------------------------------------
|
| PURPOSE: To smooth a matrix using the discrete estimated 
| median of the 8 nearest neighbors for n-passes.
|
| DESCRIPTION: Uses bootstrap to estimate median.
| Returns smoothed matrix. Dynamically allocates and frees
| working buffers.
|
| EXAMPLE:  
|
| result = SmoothMatrixEstimatedMedianDiscrete( m, n );
|
| NOTE:  
|
| ASSUMES: OK to mess up the data in the input matrix
|
| HISTORY: 01.12.97 from 'SmoothMatrixEstimatedMedian'.
------------------------------------------------------------*/
Matrix*
SmoothMatrixEstimatedMedianDiscrete( Matrix* In, s16 passes )
{
    Matrix* Out;
    f64**   t;
    
    f64    AtSample[9];
    f64    AtWork[9];
    s32     i, j;
    s32     rows;
    s32     columns;
    f64**   A;
    f64**   B;
    
//  DrawStringOnLine( 
//          10, Line1,
//          "SmoothMatrix: %s", In->FileName);
    
    rows    = In->RowCount;
    columns = In->ColCount;
        
    // Allocate the result matrix.
    Out = MakeMatrix( (s8*) "Result", rows, columns );
    
    A = (f64**) In->a;
    B = (f64**) Out->a;
    
    while( passes-- )
    {
//      DrawStringOnLine( 
//          10, Line2,
//          "SmoothMatrix: passes to go %d", passes + 1);

        // For upper left corner use 3 neighbors.
        AtSample[0] = A[0][0];
        AtSample[1] = A[0][1];
        AtSample[2] = A[1][0];
        AtSample[3] = A[1][1];
        B[0][0] = EstimateMedianDiscrete( AtSample, AtWork, 4);
    
        // For upper right corner use 3 neighbors.
        AtSample[0] = A[0][ columns - 1 ];
        AtSample[1] = A[0][ columns - 2 ];
        AtSample[2] = A[1][ columns - 2 ];
        AtSample[3] = A[1][ columns - 1 ];
        B[0][columns - 1] =  
                 EstimateMedianDiscrete( AtSample, AtWork, 4);

        // For lower left corner use 3 neighbors.
        AtSample[0] = A[rows - 1][0];
        AtSample[1] = A[rows - 2][0];
        AtSample[2] = A[rows - 2][1];
        AtSample[3] = A[rows - 1][1];
        B[rows - 1][0] = 
                 EstimateMedianDiscrete( AtSample, AtWork, 4);

        // For lower right corner use 3 neighbors.
        AtSample[0] = A[rows - 1][columns - 1];
        AtSample[1] = A[rows - 2][columns - 1];
        AtSample[2] = A[rows - 2][columns - 2];
        AtSample[3] = A[rows - 1][columns - 2];
        B[rows - 1][columns - 1] = 
                 EstimateMedianDiscrete( AtSample, AtWork, 4);
        
        // For top border.
        for( j = 1; j < columns - 1; j++ )
        {
            AtSample[0] = A[0][j];
            AtSample[1] = A[0][j - 1];
            AtSample[2] = A[0][j + 1];
            AtSample[3] = A[1][j - 1];
            AtSample[4] = A[1][j];
            AtSample[5] = A[1][j + 1];
            B[0][j] = 
                 EstimateMedianDiscrete( AtSample, AtWork, 6);
        }
        
        // For bottom border.
        for( j = 1; j < columns - 1; j++ )
        {
            AtSample[0] = A[rows-1][j];
            AtSample[1] = A[rows-1][j - 1];
            AtSample[2] = A[rows-1][j + 1];
            AtSample[3] = A[rows-2][j - 1];
            AtSample[4] = A[rows-2][j];
            AtSample[5] = A[rows-2][j + 1];
            B[rows-1][j] =
                 EstimateMedianDiscrete( AtSample, AtWork, 6);
        }
        
        // For left border.
        for( i = 1; i < rows - 1; i++ )
        {
            AtSample[0] = A[i][0];
            AtSample[1] = A[i - 1][0];
            AtSample[2] = A[i + 1][0];
            AtSample[3] = A[i - 1][1];
            AtSample[4] = A[i][1];
            AtSample[5] = A[i + 1][1];
            B[i][0] = 
                 EstimateMedianDiscrete( AtSample, AtWork, 6);
        }
        
        // For right border.
        for( i = 1; i < rows - 1; i++ )
        {
            AtSample[0] = A[i][columns - 1];
            AtSample[1] = A[i - 1][columns - 1];
            AtSample[2] = A[i + 1][columns - 1];
            AtSample[3] = A[i - 1][columns - 2];
            AtSample[4] = A[i][columns - 2];
            AtSample[5] = A[i + 1][columns - 2];
            B[i][columns - 1] =
                 EstimateMedianDiscrete( AtSample, AtWork, 6);
        }
        
        // For each inner row, borders excluded.
        for( i = 1; i < rows - 1; i++ )
        {
//          DrawStringOnLine( 
//              10, Line3,
//              "row: %d", i );
            // Allow time to other processes.
//          ProcessPendingEvents();
                
            // For each inner column, borders excluded.
            for( j = 1; j < columns - 1; j++ )
            {
                AtSample[0] = A[i][j];
                AtSample[1] = A[i - 1][j - 1];
                AtSample[2] = A[i - 1][j];
                AtSample[3] = A[i - 1][j + 1];
                AtSample[4] = A[i][j - 1];
                AtSample[5] = A[i][j + 1];
                AtSample[6] = A[i + 1][j - 1];
                AtSample[7] = A[i + 1][j];
                AtSample[8] = A[i + 1][j + 1];
                
                // If any value differs
                if( AtSample[0] != AtSample[1] ||
                    AtSample[0] != AtSample[2] ||
                    AtSample[0] != AtSample[3] ||
                    AtSample[0] != AtSample[4] ||
                    AtSample[0] != AtSample[5] ||
                    AtSample[0] != AtSample[6] ||
                    AtSample[0] != AtSample[7] ||
                    AtSample[0] != AtSample[8] )
                {
                    B[i][j] = 
                        EstimateMedianDiscrete( AtSample, AtWork, 9);
                }
                else // Use any of the samples because they
                     // are identical.
                {
                    B[i][j] = A[i][j];
                }
            }
        }
        
        // If there are remaining passes, exchange the data
        // for the matrices
        if( passes )
        {
            t = (f64**) In->a;
            In->a = Out->a;
            Out->a = (u8*) t;
            
            A = (f64**) In->a;
            B = (f64**) Out->a;
        }
    }
        
    // Return the result.
    return( Out );
}

/*------------------------------------------------------------
| SmoothMatrixFile
|-------------------------------------------------------------
|
| PURPOSE: To smooth a matrix file using the estimated median
|          of the neighbors.
|
| DESCRIPTION: 
|
| Writes out smoothed matrix. Dynamically allocates and frees
| working buffers.
|
| EXAMPLE:  
|
|   FilterMatrixFileUsingSampleDistribution( In, Out );
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 01.24.96 from 'FilterMatrixFileUsingSampleDistribution'.
------------------------------------------------------------*/
void
SmoothMatrixFile( s8* InputFile, s8* OutputFile, s32 Passes )
{
    Matrix* AMatrix;
    Matrix* BMatrix;

//TBD   AMatrix = ReadMatrix( InputFile );
            
    BMatrix = SmoothMatrixEstimatedMedian( AMatrix, Passes );
    
    SaveMatrix( BMatrix, OutputFile );

    DeleteMatrix( AMatrix );
    DeleteMatrix( BMatrix );
}

/*------------------------------------------------------------
| SmoothMatrixVertical
|-------------------------------------------------------------
|
| PURPOSE: To smooth a matrix using the mean of
|          the vertical neighbors for n-passes.
|
| DESCRIPTION:  Returns smoothed matrix. Dynamically allocates 
| and frees working buffers.
|
| EXAMPLE:  
|
| result = SmoothMatrixVertical( m, n );
|
| NOTE: Not as accurate as 'SmoothMatrixEstimatedMedian' but
|       much faster. 
|
| ASSUMES: OK to mess up the data in the input matrix
|
| HISTORY: 02.01.97 from 'SmoothMatrix'.
------------------------------------------------------------*/
Matrix*
SmoothMatrixVertical( Matrix* In, s32 passes )
{
    Matrix* Out;
    f64**   t;
    s32     i, j;
    s32     rows;
    s32     columns;
    f64**   A;
    f64**   B;
    
//  DrawStringOnLine( 
//          10, Line1,
//          "SmoothMatrix: %s", In->FileName);
    
    rows    = In->RowCount;
    columns = In->ColCount;
        
    // Allocate the result matrix.
    Out = DuplicateMatrix( In );
    
    A = (f64**) In->a;
    B = (f64**) Out->a;
    
    while( passes-- )
    {
        
        // For top border.
        for( j = 0; j < columns; j++ )
        {
            B[0][j] = 
                ( A[0][j] +
                  A[1][j] )/2.;
        }
        
        // For bottom border.
        for( j = 0; j < columns; j++ )
        {
            B[rows-1][j] =
                ( A[rows-1][j] +
                  A[rows-2][j] )/2.;
        }
        
        // For each inner row, borders excluded.
        for( i = 1; i < rows - 1; i++ )
        {
//          ProcessPendingEvents();
                
            // For each inner column, borders included.
            for( j = 0; j < columns; j++ )
            {
                B[i][j] = 
                    ( A[i][j] +
                      A[i - 1][j] +
                      A[i + 1][j] ) / 3.;
            }
        }
        
        // If there are remaining passes, exchange the data
        // for the matrices
        if( passes )
        {
            t = (f64**) In->a;
            In->a = Out->a;
            Out->a = (u8*) t;
            
            A = (f64**) In->a;
            B = (f64**) Out->a;
        }
    }
        
    // Return the result.
    return( Out );
}

/*------------------------------------------------------------
| SortVector
|-------------------------------------------------------------
|
| PURPOSE: To sort the entries in a given vector in increasing
|          order.
|
| DESCRIPTION: Expects the address of a vector, a count of 
| entries in the vector. 
|
| Uses fast Heap Sort procedure.
|
| EXAMPLE:  
|
| SortVector( AVector, ItemCount );
|
| NOTE: Especially well suited to long tables as the run time
| is proportional to Nlog2N as a worst case, eg. a 256 element
| list would take time proportional to 256*8 = 2048 vs.
| N*N or 64K for the bubble sort.
|
| ASSUMES: 
|
| NOTE: See "Numerical Recipes, The Art of Scientific 
|        Computing", page 229, for complete explanation. 
|
| HISTORY: 09.12.89 by 
|          12.22.91 revised to use Heap Sort algorithm.
|          11.02.93 ported from Focus.
|          12.19.93 revised for MATLAB.
------------------------------------------------------------*/
void
SortVector( f64* AVector, u32 ItemCount )
{
    f64  AData;
    f64  BData;
    f64  EntryBeingMoved;
    u32   HeapIndexL;
    u32   HeapIndexIR;
    u32   HeapIndexI;
    u32   HeapIndexJ;
    
    if( ItemCount < 2 ) return;
    
    HeapIndexL  = (ItemCount >> 1) + 1; 
    HeapIndexIR = ItemCount;
    
    while(1)
    {
        if(HeapIndexL > 1)
        {
            HeapIndexL--;
            EntryBeingMoved = AVector[HeapIndexL-1];
        }
        else
        {
            EntryBeingMoved = AVector[HeapIndexIR-1];
            AVector[HeapIndexIR-1] = AVector[0];
            HeapIndexIR--;
            if( HeapIndexIR == 1 ) // at the end
            {               
                AVector[0] = EntryBeingMoved;
                return;
            }
        }
        
        HeapIndexI = HeapIndexL;
        HeapIndexJ = HeapIndexL<<1;
        
        while( HeapIndexJ <= HeapIndexIR )
        {
            if( HeapIndexJ < HeapIndexIR )
            {
                AData = AVector[HeapIndexJ-1];
                BData = AVector[HeapIndexJ];

                if( AData < BData )
                {
                    HeapIndexJ++;
                }
            }
            
            AData = EntryBeingMoved;
            BData = AVector[HeapIndexJ-1];

            if( AData < BData )
            {
              
              AVector[HeapIndexI-1] = AVector[HeapIndexJ-1];
              HeapIndexI = HeapIndexJ;
              HeapIndexJ += HeapIndexJ;
            }
            else
            {
              HeapIndexJ = HeapIndexIR+1;
            }
        }
        
        AVector[HeapIndexI - 1] = EntryBeingMoved;
    }
}

/*------------------------------------------------------------
| StandardDeviation
|-------------------------------------------------------------
|
| PURPOSE: To find the standard deviation of a number buffer.
|
| DESCRIPTION: SquareRoot(Variance)
|
| EXAMPLE:  
|
| NOTE:
|
| ASSUMES: Normal distribution.
|
| HISTORY:  06.04.93 
|           05.15.96 revised.
------------------------------------------------------------*/
f64
StandardDeviation( f64* Items, s32 Count )
{
    return( sqrt( Variance( Items, Count ) ) );
}

/*------------------------------------------------------------
| Variance
|-------------------------------------------------------------
|
| PURPOSE: To find the variance of a number buffer.
|
| DESCRIPTION: Variance = Sum( x^2 - Mean^2 )/n
|  
| where  x    = a number in series
|        Mean = mean of the series
|        n    = count of numbers in the series
| 
| EXAMPLE:  
|
| NOTE: See page 123 of "Introduction to the Statistical 
| Method" by Hammond and Householder for the derivation of 
| a this form of the variance formula.  This form used
| for the sake of speed.
|
| ASSUMES: Normal distribution.
|
| HISTORY:  06.23.93  
|           05.15.96 revised.
|           03.04.00 Validate this: how come the MeanSquared
|                    is multiplied by the ItemCount?
------------------------------------------------------------*/
f64
Variance( f64* Items, s32 Count )
{
    f64 ItemCount;
    s32 i;
    f64 a;
    f64 Sum;
    f64 SumOfSquared;
    f64 Mean;
    f64 MeanSquared;
    f64 Var;
    
    Sum = 0;
    
    SumOfSquared = 0;

    for( i = 0; i < Count; i++ )
    {
        a = *Items++;
        
        Sum += a;
        
        SumOfSquared += a * a;
    }   

    ItemCount = (f64) Count;
    
    Mean = Sum / ItemCount;

    MeanSquared = Mean * Mean;
    
    Var = ( SumOfSquared - ( MeanSquared * ItemCount ) ) / 
          ItemCount;
    
    return(Var);

}   

/* ------------------------------------------------------------
| WeightedMovingAverage
|-------------------------------------------------------------
|
| PURPOSE: To compute the moving average function for a list of
|          values using weights associated with those values.
|
| DESCRIPTION: Returns a list of values the same length as the
| input.  The initial values are computed using the first 
| series of weights.
|
| The weights are ordered so that the first value cooresponds
| with the current input entry, the 2nd value with the prior 
| one.
|
| EXAMPLE:  Find the 10-day volume-weighted moving average 
| of copper:
|
|  WeightedMovingAverage( Dec92Copper, Out, 
|                         ItemCount, CopperVolume, 10 );
|
| NOTE: 
|
| ASSUMES: None of the weights are zero.
|
| HISTORY:  09.05.93 
|           09.11.93 fixed weighting index bug
|           08.07.95 Converted from Mathematica format.
------------------------------------------------------------- */
void
WeightedMovingAverage( f64* InputVector, 
                       f64* OutputVector,
                       s16   ItemCount, 
                       f64* WeightVector, 
                       s16   Period )
{
    s16     i;
    s16     p;
    s16     j;
    f64 WeightedSum;
    f64 SumOfWeights;
    f64 Weight;
    
    // The first value is just the same as input.
    *OutputVector++ = *InputVector++;
    
    // Compute remaining values.        
    for( i = 1; i < ItemCount; i++ )
    {
        // Limit period for initial values.
        if( i+1 < Period )
        {
            p = i+1;
        }
        else
        {
            p = Period;
        }
        
        WeightedSum  = 0;
        SumOfWeights = 0;
        
        for( j = 0; j < p; j++ )
        {
            Weight = WeightVector[j];
            
            WeightedSum += InputVector[-j] * Weight;
                          
            SumOfWeights += Weight;
        }
        
        *OutputVector++ = WeightedSum / SumOfWeights;
        
        InputVector++;
    }
}
