/*------------------------------------------------------------
| NAME: DateList.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to date list functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 05.26.96
------------------------------------------------------------*/

#ifndef _DATELIST_H_
#define _DATELIST_H_

#ifdef __cplusplus
extern "C"
{
#endif

//List*       IntersectionOfDateLists( List*, List* );
List*       MakeListOfBusinessDayGapsInDatedMatrix( Matrix* );
List*       MakeListOfDatesInDatedMatrix( Matrix* );
List*       MakeListOfRecentBusinessDays( u32, u32 );
List*       UnionOfDateLists( List*, List* );

#ifdef __cplusplus
} // extern "C"
#endif
 
#endif // _DATELIST_H_
