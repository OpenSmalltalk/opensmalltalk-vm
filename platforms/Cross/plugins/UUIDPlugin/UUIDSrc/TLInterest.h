/*------------------------------------------------------------
| FILE NAME: Interest.h
|
| PURPOSE: To provide interface to interest rate functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 03.28.96 
------------------------------------------------------------*/

#ifndef _INTEREST_H
#define _INTEREST_H

void    EstimateEquilibriumPrices( f64*, f64*, s32 );
void    EstimateEquilibriumPrices2( f64*, f64*, s32 );
void    EstimateEquilibriumPrices3( f64*, f64*, s32 );
f64     ForceOfInterest( f64, f64, f64 );
f64     FutureAmount( f64, f64, f64 );
f64     GeneralNetPresentValue( f64*, f64*, f64*, s32 );
void    GeneralPresentValues( f64*, f64*, f64*, f64*, s32 );
f64     ImplicitForceOfInterest( f64*, s32 );
f64     InternalRateOfReturn( f64, f64*, s32 );
f64     InternalRateOfReturnOfContract(       
            f64, f64, f64, f64*, s32 );
f64     LookUpShortTermInterestRate( s32 );
f64     MostConsistentLogPrice( f64*, s32, s32, f64 );
f64     MostConsistentLogPrice2( f64*, s32, s32, f64 );
s32     MostConsistentAntecedentPeriod( f64*, s32, s32, s32, s32, s32 );  
f64     NetPresentValue( f64*, s32, f64 );
f64     PerDayRate( f64 );
f64     PerTradingDayRate( f64 );
f64     PresentValue( f64, f64, f64 );
void    PresentValues( f64*, f64*, s32, f64 );
void    RatesOfLogPriceCombinations( f64*, f64*, s32 );
void    RatesOfLogPricesWithOtherLogPrice( f64*, f64*, s32, f64, s32 );
f64     TryAntecedentPeriod( f64 );
f64     TryDiscountRate( f64 );
f64     TryImplicitForceOfInterest( f64 );
f64     TryLogPrice( f64 );
f64     TryLogPrice2( f64 );


#endif // _INTEREST_H
