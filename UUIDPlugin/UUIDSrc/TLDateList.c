/*------------------------------------------------------------
| TLDateList.c
|-------------------------------------------------------------
|
| PURPOSE: To provide functions for manipulating lists of
|          dates.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 05.26.96
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"  
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLList.h"
#include "TLListIO.h"
#include "TLFile.h"
#include "TLParse.h" 
#include "TLTable.h"
#include "TLMassMem.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLNumber.h" // for 'ConvertStringToNumber'
                      // and 'ConvertNumberToString'
#include "TLDate.h" 
#include "TLItems.h"
#include "TLVector.h"
#include "TLMatrixAlloc.h"
#include "TLArray.h"
#include "TLPoints.h"
#include "TLGeometry.h"
#include "TLSubRandom.h"
#include "TLWeight.h"
#include "TLStat.h"
#include "TLDateList.h"

/*------------------------------------------------------------
| MakeListOfBusinessDayGapsInDatedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a list of non-weekend days not found in
| the period spanned by a dated matrix.
|
| DESCRIPTION: Gaps in a dated matrix may indicate holidays
| or missing data.  This procedure makes a list of all days
| on which trading would normally occur but didn't.
|
| The date is held in the 'DataAddress' field of each
| Item record.  The date is in TradeTime format.
|
| EXAMPLE:  
|
|   L = MakeListOfBusinessDayGapsInDatedMatrix( M );
|
| NOTE: 
|
| ASSUMES: First column in matrix holds the date in TradeTime
|          format.
|          The list system is set up.
|
| HISTORY:  01.15.96 
------------------------------------------------------------*/
List*
MakeListOfBusinessDayGapsInDatedMatrix( Matrix* AMatrix )
{
    List*   AList;
    u32     RowCount, r;
    u32     ThePriorDay;
    u32     TheCurrentDay;
    f64**   A;
    
    RowCount = AMatrix->RowCount;
    A = AMatrix->a;
    
    AList = MakeList();
    
    // The date of the first row is the first prior day.
    ThePriorDay = (u32) A[0][0];
    
    // For the 2nd row through the last.
    for( r = 1; r < RowCount; r++ )
    {
        TheCurrentDay = (u32) A[ r ][ 0 ];

Start:
        ThePriorDay = NextDay2( ThePriorDay );
        
        // If the day after the prior day is not the
        // current day but it is a business day,
        // then a gap has been found.
        if( ThePriorDay != TheCurrentDay &&
            ThePriorDay <  TheCurrentDay &&
            IsBusinessDay2( ThePriorDay ) )
        {
            InsertDataLastInList( AList, (u8*) ThePriorDay);
            
            goto Start; // Look for more days in the gap.
        }
    }
    
    return( AList );
}

/*------------------------------------------------------------
| MakeListOfDatesInDatedMatrix
|-------------------------------------------------------------
|
| PURPOSE: To make a list dates found in a dated matrix.
|
| DESCRIPTION:  
|
| The date is held in the 'DataAddress' field of each
| Item record.  The date is in TradeTime format.
|
| EXAMPLE:  
|
|   L = MakeListOfDatesInDatedMatrix( M );
|
| NOTE: 
|
| ASSUMES: First column in matrix holds the date in TradeTime
|          format.
|          The list system is set up.
|
| HISTORY:  05.26.96 from 
|                 'MakeListOfBusinessDayGapsInDatedMatrix'
------------------------------------------------------------*/
List*
MakeListOfDatesInDatedMatrix( Matrix* AMatrix )
{
    List*   AList;
    u32     RowCount, i;
    f64**   A;
    
    RowCount = AMatrix->RowCount;
    A = AMatrix->a;
    
    AList = MakeList();
    
    // For the each row.
    for( i = 0; i < RowCount; i++ )
    {
        InsertDataLastInList( AList, (u8*) ((s32) A[i][0]));
    }
    
    return( AList );
}

/*------------------------------------------------------------
| MakeListOfRecentBusinessDays
|-------------------------------------------------------------
|
| PURPOSE: To make a list of the 'n' most recent business
|          days including the given date if it is a business
|          day.
|
| DESCRIPTION: Returns a list in increasing date order.
|
| The date is held in the 'DataAddress' field of each
| Item record.  The date is in TradeTime format.
|
| EXAMPLE: 
|
| NOTE: Doesn't take holidays into account.
|
| ASSUMES: 'n' is positive number.
|
| HISTORY: 01.15.97
------------------------------------------------------------*/
List*
MakeListOfRecentBusinessDays( u32 YYYYMMDD, u32 n )
{
    u32     TradeTime;
    List*   L;
    
    // Convert date to TradeTime format.
    TradeTime = YYYYMMDDToTradeTime( YYYYMMDD );
    
    // Make the list.
    L = MakeList();
    
    // For the last 'n' business days.
    while( n )
    {
        // If this is a business day.
        if( IsBusinessDay2( TradeTime ) )
        {
            // Save it in the list.
            InsertDataFirstInList( L, (u8*) TradeTime );
            
            // Reduce the number of days sought after.
            n--;
        }
        
        // Walk back to the prior day.
        TradeTime = PriorDay2( TradeTime );
    }
    
    // Return the resulting list.
    return( L );
}                              

/*------------------------------------------------------------
| UnionOfDateLists
|-------------------------------------------------------------
|
| PURPOSE: To make a single list of dates that is the logical
|          union of two lists of dates, duplicates removed.
|
| DESCRIPTION:  
|
| The date is held in the 'DataAddress' field of each
| Item record.  The date is in TradeTime format.
|
| EXAMPLE: L = UnionOfDateLists( A, B );
|
| NOTE: 
|
| ASSUMES: 
|          The list system is set up.
|
| HISTORY:  05.26.96
------------------------------------------------------------*/
List*
UnionOfDateLists( List* A, List* B )
{
    List* U;
    
    // Make the new list.
    U = DuplicateList(A);
    
    // Join lists A and B.
    JoinLists( U, DuplicateList(B) );
    
    // Sort so that dates are in order.
    SortListByDataAddress(U);
    
    // Remove the duplicate dates.
    DeleteDuplicateDataReferences( U );
    
    // Return the list.
    return( U );
}

    
