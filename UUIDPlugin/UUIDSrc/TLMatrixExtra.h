/*------------------------------------------------------------
| TLMatrixExtra.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to less commonly used 
|          data matrix functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 01.24.95
------------------------------------------------------------*/

#ifndef _TLMATRIXEXTRA_H_
#define _TLMATRIXEXTRA_H_

#ifdef __cplusplus
extern "C"
{
#endif

// -------------------------------------------------------------------
//
// .EST files have this format:
//
//       Date     PriceCount  Prices...
// eg. '19960612  5           1.870  1.920  1.880...'
//                            Newest ------> Oldest estimates.
// Field index constants:
#define EST_Date            0
#define EST_PriceCount      1
#define EST_Prices          2

// -------------------------------------------------------------------
//
// .IDX files have this format:
//
//       Date     ActualPrice Upward price move probabilities
//                           1 day fwd  2nd day  3rd day... 
// eg. '19960612  1.870       .5        .53      .52...'
// Field index constants:
#define IDX_Date            0
#define IDX_ActualPrice     1
#define IDX_UpProb          2

// -------------------------------------------------------------------
//
// .INX files have this format:
//
//       Date     Time  ActualPrice Upward price move probabilities
//                                1 day fwd  2nd day  3rd day... 
// eg. '19960612  0930  1.870       .5        .53      .52...'
// Field index constants:
#define INX_Date        0   // 'yyyymmdd', the date local to the exchange
                            // at the end of the sample interval
                            //
#define INX_Time        1   // 'hhmm.' the time local to the exchange at
                            // the end of the sample interval.  0 if 
                            // unspecified.
                            //
#define INX_ActualPrice 2   // Actual price at the time.
#define INX_UpProb      3   // Start of the 50-item probability field.

// The structure of a INX record in memory.  Fields are the same
// as defined for the file above.
typedef struct
{
    f64 Date;
    f64 Time;
    f64 ActualPrice;
    f64 UpProb[50];
} Inx;

// -------------------------------------------------------------------
//
// .OPT files have this format:
//
//       Strike   CallPrice  PutPrice 
// eg. '390        5.50      .25'
// Field index constants:
#define OPT_Strike          0
#define OPT_CallPrice       1
#define OPT_PutPrice        2

// -------------------------------------------------------------------
// 
// .TIC files are used to hold tick-by-tick or sampled price data.
//
// .TIC files have this format:
//
//       Date      Time    Price 
//
// eg. '12/12/96   09:21   1.25'
//
// Field index constants:
#define TIC_Date            0
#define TIC_Time            1
#define TIC_Price           2

#define TIC_ColCount        3
// -------------------------------------------------------------------
//
// .TSV files have this format:
//
//       Date     High    Low   Close Open Volume OpenInterest
// eg. '12/20/90  1.944  1.870  1.920  1.880  742  1889'
// Field index constants:
#define TSV_Date            0
#define TSV_High            1
#define TSV_Low             2
#define TSV_Close           3
#define TSV_Open            4
#define TSV_Volume          5
#define TSV_OpenInterest    6

#define TSV_ColCount        7

// -------------------------------------------------------------------
// Note: Open-High-Low-Close order is the same as WSJ and IBD.
//
// .DAY files have this format: 
//                                                    Open     Data
//       Date     Open   High   Low    Close  Volume Interest Source
// eg. '19901220 1.880  1.944  1.870   1.920    742    1889     9'
// Field index constants:
#define DAY_Date            0
#define DAY_Open            1
#define DAY_High            2
#define DAY_Low             3
#define DAY_Close           4
#define DAY_Volume          5
#define DAY_OpenInterest    6
#define DAY_DataSource      7

#define DAY_ColCount        8

// The structure of a DAY record in memory.  Fields are the same
// as defined for the file above.
typedef struct
{
    f64 Date;
    f64 Open;
    f64 High;
    f64 Low;
    f64 Close;
    f64 Volume;
    f64 OpenInterest;
    f64 Source;
} DayPrice;

// -------------------------------------------------------------------
// Note: Open-High-Low-Close order is the same as WSJ and IBD.
// From TurtleTalk.com:
//
// .ASC files have this format: 
//                                                        Open      
//       Date     Open   High      Low    Close  Volume Interest 
// eg  '730823,65.40000,67.75000,65.40000,66.75000,151,1165'
// Field index constants:
#define ASC_Date            0
#define ASC_Open            1
#define ASC_High            2
#define ASC_Low             3
#define ASC_Close           4
#define ASC_Volume          5
#define ASC_OpenInterest    6

#define ASC_ColCount        7

Vector* ColumnToVector( Matrix*, u32 );
Vector* ColumnToVectorY( Matrix*, u32 );
void    CopyRandomRows( Matrix*, Matrix*, u32 );
void    CopySubRandomRows( Matrix*, Matrix*, u32 );
void    DeleteListOfMatrices( List* );
u32     FindMissingCellWithMostNeighbors( Matrix*, u32*, u32* );
s32     FillMissingValuesInMatrix( Matrix* );
f64     GetCellByKey( Matrix*, f64, u32 );
void    GetMatrixExtremes( Matrix*, f64*, f64*);
u32     IndexOfKey( Matrix*, s32 );
u32     IndexOfNearestKey( Matrix*, s32 );
void    InvertIntoMatrix( Matrix*, s32, s32, s32, s32, Matrix*, s32, s32 );
u32     IsDateInMatrix( Matrix*, u32 );
u32     IsEmptyMatrix( Matrix* );
u32     IsMissingValueInMatrix( Matrix* );
Matrix* MakeDedupedOrderedMatrix( Matrix* );
Matrix* MakeDedupedOrderedMatrix2( Matrix* );
Vector* MatrixToVector( Matrix* );
void    MeanDataPoint( Matrix*, f64* );
f64     MeanDifferenceInMatrix( Matrix* );
void    MeanSpacePoint( Matrix*, f64* );
Matrix* MergeOrderedMatrices( Matrix*, Matrix* );
Matrix* MergeOrderedMatrices2( Matrix*, Matrix* );
f64     PercentMatching( Matrix*, Matrix* );
s8*     PeriodStringOfDatedMatrix( Matrix* );
void    RangeOfOrderedMatrix( Matrix*, u32*, u32*);
void    SelectAnyNeighborCell( s32, s32, s32, s32, s32*, s32* );
f64     SmallestDifferenceInMatrix( Matrix* );
void    StripCommentsInSourceCodeMatrix( Matrix* );
Matrix* VectorToMatrix( Vector* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLMATRIXEXTRA_H_
