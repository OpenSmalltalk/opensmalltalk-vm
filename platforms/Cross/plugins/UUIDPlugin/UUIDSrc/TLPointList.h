/*------------------------------------------------------------
| TLPointList.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to data point list functions.
|
| DESCRIPTION:
| 
| Convention: The 'SizeOfData' field of each list item holds
|             the dimension count of the data point.
|        
| NOTE: 
|
| HISTORY: 03.28.96 
------------------------------------------------------------*/

#ifndef _POINTLIST_H_
#define _POINTLIST_H_

#ifdef __cplusplus
extern "C"
{
#endif

void        DeleteDuplicateDataPoints( List* );
u32         DimensionOfPointList( List* );
f64*        DuplicateDataPoint( f64*, u32 );
void        InsertPointLastInList(  List*, f64*, u32 );
u32         IsDataPointsEqual( f64*, f64*, u32 );
List*       MatrixToPointList( Matrix* );
f64*        PointListToItems( List* );
Matrix*     PointListToMatrix( List* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _POINTLIST_H_
