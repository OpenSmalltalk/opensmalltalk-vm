/*------------------------------------------------------------
| TLMenuList.h
|-------------------------------------------------------------
|
| PURPOSE: To provide inteface to general routines for 
|          managing menus.
|
| DESCRIPTION: See the header of 'TLMenuList.c'.
|
| NOTE: 
|
| HISTORY: 11.26.97
------------------------------------------------------------*/

#ifdef __cplusplus
extern "C"
{
#endif

#ifndef MenuHandle
#include <Menus.h>
#endif

void    AppendItemToMenuList( List*, u8*, u8*, u8* );
void    EnableMenuAndItems( MenuHandle );
void    ExecuteNthItemOfMenuList( List*, s32 );
s32     FindMenuItemNumberByName( MenuHandle, s8* );
void    InsertMenuItemC( MenuHandle, s8*, s32 );
void    PutItemNamesIntoMenu( MenuHandle, List* );

#ifdef __cplusplus
} // extern "C"
#endif
