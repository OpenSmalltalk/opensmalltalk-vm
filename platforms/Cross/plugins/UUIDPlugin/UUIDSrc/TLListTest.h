/*------------------------------------------------------------
| TLListTest.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to list test functions.
|
| DESCRIPTION:
|
| NOTE: 
|
| HISTORY: 05.01.96
------------------------------------------------------------*/

#ifndef _TLLISTTEST_H_
#define _TLLISTTEST_H_

void    TLListDemonstration();
u32     ListTest_main();

List*   MakeSampleListOfDynamicStrings();
List*   MakeSampleListOfStaticStrings();
void    OutputListOfStrings( List* );
void    OutputListSystemStatus();

u32     Test_Byte();
u32     Test_u16();
u32     Test_u32();
u32     Test_s8();
u32     Test_s16();
u32     Test_s32();
u32     Test_CompareBytes();
u32     Test_CopyBytes();
u32     Test_ExchangeBytes();
u32     Test_FillBytes();
u32     Test_IsMatchingBytes();
u32     Test_ReplaceBytes();
u32     Test_AppendString();
u32     Test_AppendStrings();
u32     Test_CountString();
u32     Test_CopyString();
u32     Test_CompareStrings();
u32     Test_ConvertStringToLowerCase();
u32     Test_ConvertStringToUpperCase();
u32     Test_AddressOfLastCharacterInString();
u32     Test_InsertString();
u32     Test_ReplaceByteInString();
u32     Test_GetNextItem();
u32     Test_PutNextItem();
u32     Test_TheNextItem();
u32     Test_GetPriorItem();
u32     Test_PutPriorItem();
u32     Test_ThePriorItem();
u32     Test_GetItemDataAddress();
u32     Test_PutItemDataAddress();
u32     Test_TheDataAddress();
u32     Test_GetItemMark();
u32     Test_PutItemMark();
u32     Test_TheItemMark();
u32     Test_GetFirstItemOfList();
u32     Test_PutFirstItemOfList();
u32     Test_TheFirstItem();
u32     Test_GetLastItemOfList();
u32     Test_PutLastItemOfList();
u32     Test_TheLastItem();
u32     Test_GetListItemCount();
u32     Test_PutListItemCount();
u32     Test_TheItemCount();
u32     Test_GetListMark();
u32     Test_PutListMark();
u32     Test_TheListMark();
u32     Test_MarkItem();
u32     Test_UnMarkItem();
u32     Test_IsItemMarked();
u32     Test_MarkList();
u32     Test_UnMarkList();
u32     Test_IsListMarked();
u32     Test_MarkItemAsFirst();
u32     Test_IsItemFirst();
u32     Test_MarkItemAsLast();
u32     Test_IsItemLast();
u32     Test_IsItemAlone();
u32     Test_ToNextItem();
u32     Test_ToPriorItem();
u32     Test_ToFirstItem();
u32     Test_ToLastItem();
u32     Test_SetUpTheListSystem();
u32     Test_PushTheItem();
u32     Test_PullTheItem();
u32     Test_PushTheList();
u32     Test_PullTheList();
u32     Test_PushTheListAndItem();
u32     Test_PullTheListAndItem();
u32     Test_MarkListAsEmpty();
u32     Test_IsAnyItemsInList();
u32     Test_MakeItem();
u32     Test_DeleteItem();
u32     Test_MakeItemForData();
u32     Test_MakeList();
u32     Test_AddToListItemCount();
u32     Test_InsertItemLastInList();
u32     Test_InsertDataLastInList();
u32     Test_ExtractTheItem();
u32     Test_ExtractItemFromList();
u32     Test_DeleteList();
u32     Test_DeleteListOfDynamicData();
u32     Test_FindFirstItemLinkedToData();
u32     Test_DeleteFirstReferenceToData();
u32     Test_DeleteAllReferencesToData();
u32     Test_IsTheDataMatching();
u32     Test_FindFirstMatchingItem();
u32     Test_FindNextMatchingItem();
u32     Test_FindFirstMarkedItem();
u32     Test_FindFirstUnMarkedItem();
u32     Test_UnMarkAllItemsInList();
u32     Test_FindIndexOfFirstMarkedItem();
u32     Test_ExtractMarkedItems();
u32     Test_DeleteMarkedItems();
u32     Test_IsAnyItemMarkedInList();
u32     Test_DuplicateList();
u32     Test_DuplicateMarkedItems();
u32     Test_ExtractFirstItemFromList();
u32     Test_ExtractLastItemFromList();
u32     Test_ReverseList();
u32     Test_JoinLists();
u32     Test_ExchangeItems();
u32     Test_InsertItemFirstInList();
u32     Test_InsertItemAfterItemInList();
u32     Test_InsertItemBeforeItemInList();
u32     Test_InsertDataFirstInList();
u32     Test_InsertDataAfterItemInList();
u32     Test_InsertDataBeforeItemInList();
u32     Test_BuildDirectAccessTableForList();
u32     Test_FindPlaceInOrderedList();
u32     Test_InsertDataInOrderedList();
u32     Test_FindPlaceInOrderedDirectAccessTable();
u32     Test_ReorderListToMatchDirectAccessTable();
u32     Test_SortShortList();
u32     Test_SortDirectAccessTable();
u32     Test_SortListViaDirectAccessTable();
u32     Test_SortList();
u32     Test_SortListAlphabetically();
u32     Test_SortListDescending();
u32     Test_OutputListOfStrings();
u32     Test_OutputListSystemStatus();
u32     Test_CleanUpTheListSystem();

#endif // _TLLISTTEST_H_













































































































