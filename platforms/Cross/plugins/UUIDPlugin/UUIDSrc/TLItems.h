/*------------------------------------------------------------
| TLItems.h
|
| PURPOSE: To provide interface to number buffer functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 03.28.96 
------------------------------------------------------------*/

#ifndef _ITEMS_H
#define _ITEMS_H

#ifdef __cplusplus
extern "C"
{
#endif

void        AbsItems( f64*, f64*, s32 );
void        AddItems( f64*, f64*, s32 );
void        AddToItems( f64*, s32, f64 );
void        ChopItems( f64*, u32 );
s32         CompareItems( s8*, s8* );
void        CopyIndexedRowsOfItems( f64*, s32*, f64*, s32*, s32, s32 );
void        CopyItems( f64*, f64*, s32 );
s32         CountInstancesOfItem( f64*, s32, f64 );
void        DeltaItems( f64*, f64*, u32 );
f64         DeltaItemSum( f64*, s32 );
f64         DeltaItemSum2ndOrder( f64*, s32 );
f64*        DerivativeOfItems( f64*, u32 );

f64         DistanceOfEachToEach( f64*, f64*, s32 );
f64         DistanceOfEachToEachSquaredSum( f64*, s32 );
f64         DistanceOfEachToEachSum( f64*, s32 );

f64*        DuplicateItems( f64*, u32 );
void        ExpItems( f64*, f64*, s32 );
f64         ExtentOfItems( f64*, u32, f64*, f64* );
void        FillItems( f64*, s32, f64 );
s32         FindOffsetOfPlaceInOrderedVector( f64, f64 *, s32);
u32         FindOffsetOfValueInOrderedVector( f64, f64 *, u32);
f64*        LoadItems( s8* );
void        Logis3Items( f64*, f64*, s32 );
void        LogItems( f64*, f64*, s32 );

f64*        MakeItems( u32, f64* );
f64         MaxItem( f64*, s32 );
s32         MaxItemIndex( f64*, s32 );
f64         MinItem( f64*, s32 );
void        MultiplyToItems( f64*, s32, f64 );
void        NormalizeItems( f64*, u32 );
void        NormalizeItemsToOne( f64*, s32 );
void        NormalizeItemsToZ1( f64*, u32 );
f64         ProductOfItems( f64*, s32 );
void        ReciprocalOfItems( f64*, f64*, s32 );
f64*        RoughDerivative( f64*, u32 );
void        SaveItems( f64*, u32 , s8* );

void        SortItems( f64*, s32 );
f64         SumItems( f64*, u32 );
f64         SumItemSquareRoots( f64*, s32 );
f64         SumItemSquares( f64*, s32 );
f64         SumMagnitudeOfItems( f64*, s32 );

f64         VectorSumOfSquares( f64*, s32 );
f64         WeighGroupsOfItems( f64*, f64*, s32, s32);
f64         WeighItems( f64*, u32 );
void        ZeroItems( f64*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _ITEMS_H
