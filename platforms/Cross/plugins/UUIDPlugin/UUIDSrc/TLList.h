/*------------------------------------------------------------
| TLList.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to list functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY:  01.12.89 Created
|           01.30.89 Added SortListAlphabetically
|           02.01.89 Added Item, LIST structs
|           02.02.89 Added DeleteAllItemsFromAListThatMatchAAddressOfData
|           02.16.89 Split of stack functions to stacks.h
|           03.07.89 Added , u8->u8, Truth->Truth
|           07.09.89 Changed structure of LIST and Item -- 
|                    added status field, datatype field, name 
|                    field
|           07.11.89 Added Name field to Item
|           10.11.89 Remove Name fields and DataTypeID fields
|           02.03.93 Copied from lists.h
|           10.25.93 Revised to conform to Focus usage.
|           11.22.93 Release 5.0
|           01.19.94 Added ByteCount field to ItemRecord,
|                    GetSizeOfItemData(), PutSizeOfItemData(),
|                    TheDataSize, 
|                    GetTypeOfItemData(), PutTypeOfItemData(),
|                    TheDataType, TypeOfData.
|           01.20.94 Added 'FindFirstItemOfType', 'FindNextItemOfType',
|                    'DuplicateItem'
|           01.21.94 added dynamic allocation of list & item 
|                    records, deleted 'IsListCreationPossible',
|                    'IsItemCreationPossible', 'ListSpace',
|                    'ItemSpace','MaxCountOfLists','MaxCountOfItems',
|                    added 'CountOfListsInUse', 'CountOfItemsInUse'
|                    added '#include <MemAlloc.h>'
|           01.27.94 added 'IsListsWithDataInCommon'
|           02.26.94 revised include files.
|           08.19.97 added C++ support.
|           08.28.97 Extended the 'TypeOfData' field of an
|                    'Item' record to 32 bits from 16.
------------------------------------------------------------*/

#ifndef TLLIST_H
#define TLLIST_H

#ifdef __cplusplus
extern "C"
{
#endif

// You can set the size of the list stack here. 
#define     MaxListStackItems       400

// This controls the number item records allocated at a time.
#define     ItemsRecordsPerSegment  500

typedef struct Item             Item;
typedef struct List             List;
typedef struct ListSystemState  ListSystemState;

//*************************************************************
//*               T H E   I T E M   R E C O R D               *
//*************************************************************
struct Item
{
    ////////////////////////////////////////////////////////// 
    //                                                      //
    //                      L I N K S                       //
    //                                                      //
    // These two link fields must be first so that 'List'   //
    // records can be treated as 'Items' when on the free   //
    // list.                                                //
    //                                                      //
    Item*   NextItem;
                // The next item in a list of items or zero
                // if there is no next item.
                //
    Item*   PriorItem;
                // The prior item in a list of items or zero
                // if there is no previous item.
    //                                                      //
    ////////////////////////////////////////////////////////// 
                //
    u8*     BufferAddress; 
                // Where the data buffer begins.
                //
    u32     SizeOfBuffer;  
                // Size of the data buffer in bytes.
                //
    u8*     DataAddress;   
                // Where the data itself is: usually
                // the same as the 'BufferAddress'.
                //
    u32     SizeOfData;    
                // Number of data bytes currently in the 
                // buffer.
                //
    u32     TypeOfData;    
                // User-specified type code for this item.
                //
    u16     ItemMark;      
                // Whether this item is marked or not.
};

//
//   Item Mark Field format:
//    
//   Bit 0    = 1 if marked by user, eg. to mark selected items
//
//   Bit 1    = 1 if DataAddress is the address of a list record,
//                implemented in 'Trees.c' extension -- not included.
//
//   Bit 2-15 = available to user
//

// Mark field masks:  
#define    Marked         1
#define    DataIsList (1<<1)  // Used exclusively by 'Trees.c'.

/*------------------------------------------------------------
| GetItemDataAddress
|-------------------------------------------------------------
|
| PURPOSE: To get the address of the data for the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  WhereDataIs = GetItemDataAddress(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.26.93
|
------------------------------------------------------------*/
#define GetItemDataAddress(I) (I->DataAddress) 

/*------------------------------------------------------------
| GetNextItem
|-------------------------------------------------------------
|
| PURPOSE: To get the address of the item following the given 
|          item.
|
| DESCRIPTION: If no item follows the given item then 0 is
| returned as the address.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.26.93
|
------------------------------------------------------------*/
#define GetNextItem(I) (I->NextItem)  

/*------------------------------------------------------------
| GetPriorItem
|-------------------------------------------------------------
|
| PURPOSE: To get the address of the item preceeding the given 
|          item.
|
| DESCRIPTION: If no item preceeds the given item then 0 is
| returned as the address.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.26.93
|
------------------------------------------------------------*/
#define GetPriorItem(I) (I->PriorItem)

/*------------------------------------------------------------
| GetItemMark
|-------------------------------------------------------------
|
| PURPOSE: To get the mark code of the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.26.93
|          11.09.97 pulled out 'GetItemMark' macro which
|                   collides with a Mac function in 
|                   'InterfaceLib'.
|
------------------------------------------------------------*/
//#define GetItemMark(I) (I->ItemMark)

/*------------------------------------------------------------
| GetSizeOfItemData
|-------------------------------------------------------------
|
| PURPOSE: To get the size of the data for the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  SizeOfData = GetSizeOfItemData(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.19.94
|
------------------------------------------------------------*/
#define GetSizeOfItemData(I) (I->SizeOfData) 

/*------------------------------------------------------------
| GetTypeOfItemData
|-------------------------------------------------------------
|
| PURPOSE: To get the type of the data for the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  TypeOfData = GetTypeOfItemData(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.19.94
|
------------------------------------------------------------*/
#define GetTypeOfItemData(I) (I->TypeOfData) 

/*------------------------------------------------------------
| PutItemDataAddress
|-------------------------------------------------------------
|
| PURPOSE: To put the data address into the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.26.93
|
------------------------------------------------------------*/
#define PutItemDataAddress(I,D) (I->DataAddress = D) 

/*------------------------------------------------------------
| PutItemMark
|-------------------------------------------------------------
|
| PURPOSE: To put the item mark code into the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: This is now obsolete: use AnItem->ItemMark instead.
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|          11.09.97 pulled out 'GetItemMark' macro which
|                   collides with a Mac function in 
|                   'InterfaceLib'.
|
------------------------------------------------------------*/
// #define PutItemMark(I,S) (I->ItemMark = S)

/*------------------------------------------------------------
| PutNextItem
|-------------------------------------------------------------
|
| PURPOSE: To put the item address of the following item into
|          given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define PutNextItem(I,N) (I->NextItem = N) 

/*------------------------------------------------------------
| PutPriorItem
|-------------------------------------------------------------
|
| PURPOSE: To put the item address of the preceeding item into
|          the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define PutPriorItem(I,P) (I->PriorItem = P) 

/*------------------------------------------------------------
| PutSizeOfItemData
|-------------------------------------------------------------
|
| PURPOSE: To put the data size into the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.19.94
|
------------------------------------------------------------*/
#define PutSizeOfItemData(I,S) (I->SizeOfData = S) 

/*------------------------------------------------------------
| PutTypeOfItemData
|-------------------------------------------------------------
|
| PURPOSE: To put the data type into the given item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.19.94
|
------------------------------------------------------------*/
#define PutTypeOfItemData(I,S) (I->TypeOfData = S) 

/*------------------------------------------------------------
| TheBufferAddress
|-------------------------------------------------------------
|
| PURPOSE: To refer to the address of the buffer associated 
|          with the current item.
|
| DESCRIPTION: 
|
| EXAMPLE:  a = TheBufferAddress;
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 12.07.96
------------------------------------------------------------*/
#define TheBufferAddress    (TheItem->BufferAddress)

/*------------------------------------------------------------
| TheBufferSize
|-------------------------------------------------------------
|
| PURPOSE: To refer to the size of the buffer associated with 
|          the current item.
|
| DESCRIPTION: 
|
| EXAMPLE:  s = TheBufferSize;
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 12.07.96
|
------------------------------------------------------------*/
#define TheBufferSize    (TheItem->SizeOfBuffer)

/*------------------------------------------------------------
| TheDataAddress
|-------------------------------------------------------------
|
| PURPOSE: To refer to the address of the data associated with 
|          the current item.
|
| DESCRIPTION: 
|
| EXAMPLE:  a = TheDataAddress;
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define TheDataAddress    (TheItem->DataAddress)

/*------------------------------------------------------------
| TheDataSize
|-------------------------------------------------------------
|
| PURPOSE: To refer to the size of the data associated with 
|          the current item.
|
| DESCRIPTION: 
|
| EXAMPLE:  s = TheDataSize;
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 01.19.94
|
------------------------------------------------------------*/
#define TheDataSize    (TheItem->SizeOfData)

/*------------------------------------------------------------
| TheDataType
|-------------------------------------------------------------
|
| PURPOSE: To refer to the type of the data associated with 
|          the current item.
|
| DESCRIPTION: 
|
| EXAMPLE:  s = TheDataType;
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 01.19.94
|
------------------------------------------------------------*/
#define TheDataType    (TheItem->TypeOfData)

/*------------------------------------------------------------
| TheNextItem
|-------------------------------------------------------------
|
| PURPOSE: To refer to the address of the item following 
|          the current item.
|
| DESCRIPTION: If no item follows the current item then 0 is
| returned as the address.
|
| EXAMPLE:  next = TheNextItem;
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define    TheNextItem        (TheItem->NextItem)

/*------------------------------------------------------------
| ThePriorItem
|-------------------------------------------------------------
|
| PURPOSE: To refer to the address of the item preceeding the 
|          current item.
|
| DESCRIPTION: If no item preceeds the current item then 0 is
| returned as the address.
|
| EXAMPLE:  
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 10.26.93
|
------------------------------------------------------------*/
#define ThePriorItem    (TheItem->PriorItem)

/*------------------------------------------------------------
| TheItemMark
|-------------------------------------------------------------
|
| PURPOSE: To refer to the mark code of the current item.
|
| DESCRIPTION: 
|
| EXAMPLE:  mark = TheItemMark;
|
| NOTE: The address of the current item is held in 'TheItem'.
|
| ASSUMES: 
|
| HISTORY: 10.26.93
|
------------------------------------------------------------*/
#define TheItemMark        (TheItem->ItemMark)

/*************************************************************/
/*               T H E   L I S T   R E C O R D               */
/*************************************************************/

struct List
{
    Item*   FirstItem; // Refers to the first item in the list.
    Item*   LastItem;  // Refers to the last item in the list.
    u32     ItemCount; // Number of items in the list.
    u8      ListMark;  // User marks.
};

/*
 *   List Mark Field format:
 *    
 *   Bit 0   = 1 if marked by user, eg. to mark selected lists
 *
 *   Bit 1-7 = available to user
 */

/* List Mark Bit field Masks */
/* #define    Marked         1 -- defined above */

/*------------------------------------------------------------
| AddToListItemCount
|-------------------------------------------------------------
|
| PURPOSE: To add a value to the item count into the given 
|          list record.
|
| DESCRIPTION: 
|
| EXAMPLE:  AddToListItemCount(NameList,1);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.28.93
|
------------------------------------------------------------*/
#define AddToListItemCount(L,C)    (L->ItemCount += (u32) C)

/*------------------------------------------------------------
| GetFirstItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To get the address of the first item of the 
|          given list.
|
| DESCRIPTION: 
|
| EXAMPLE:  AnItem = GetFirstItemOfList(NameList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.28.93
|
------------------------------------------------------------*/
#define GetFirstItemOfList(L)    (L->FirstItem)

/*------------------------------------------------------------
| GetLastItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To get the address of the last item of the 
|          given list.
|
| DESCRIPTION: 
|
| EXAMPLE:  AnItem = GetLastItemOfList(NameList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define GetLastItemOfList(L)    (L->LastItem)

/*------------------------------------------------------------
| GetListItemCount
|-------------------------------------------------------------
|
| PURPOSE: To get the count of items in the given list.
|
| DESCRIPTION: 
|
| EXAMPLE:  HowMany = GetListItemCount(NameList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define GetListItemCount(L)    (L->ItemCount)

/*------------------------------------------------------------
| GetListMark
|-------------------------------------------------------------
|
| PURPOSE: To get the mark code of the given list.
|
| DESCRIPTION: 
|
| EXAMPLE:  mark = GetListMark(NameList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.28.93
|
------------------------------------------------------------*/
#define GetListMark(L)        (L->ListMark)

/*------------------------------------------------------------
| PutFirstItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To put the address of the first item into the 
|          given list record.
|
| DESCRIPTION: 
|
| EXAMPLE:  PutFirstItemOfList(NameList,AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.28.93
|
------------------------------------------------------------*/
#define PutFirstItemOfList(L,I)    (L->FirstItem = I)

/*------------------------------------------------------------
| PutLastItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To put the address of the last item into the 
|          given list record.
|
| DESCRIPTION: 
|
| EXAMPLE:  PutLastItemOfList(NameList,AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.28.93
|
------------------------------------------------------------*/
#define PutLastItemOfList(L,I)    (L->LastItem = I)

/*------------------------------------------------------------
| PutListItemCount
|-------------------------------------------------------------
|
| PURPOSE: To put the item count into the given list record.
|
| DESCRIPTION: 
|
| EXAMPLE:  PutListItemCount(NameList,5);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.28.93
|
------------------------------------------------------------*/
#define PutListItemCount(L,C)    (L->ItemCount = C)

/*------------------------------------------------------------
| PutListMark
|-------------------------------------------------------------
|
| PURPOSE: To put the list mark code into the given list.
|
| DESCRIPTION: 
|
| EXAMPLE:  PutListMark(NameList,Marked);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define PutListMark(L,M) (L->ListMark = M)


/*------------------------------------------------------------
| TheItemCount
|-------------------------------------------------------------
|
| PURPOSE: To refer to the item count of the current list.
|
| DESCRIPTION: 
|
| EXAMPLE:  CountOfItems = TheItemCount;
|
| NOTE: The address of the current list is held in 'TheList'.
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define TheItemCount        (TheList->ItemCount)

/*------------------------------------------------------------
| TheFirstItem
|-------------------------------------------------------------
|
| PURPOSE: To refer to the address of the first item of the 
|          current list.
|
| DESCRIPTION: 
|
| EXAMPLE:  AnItem = TheFirstItem;
|
| NOTE: The address of the current list is held in 'TheList'.
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define TheFirstItem        (TheList->FirstItem)

/*------------------------------------------------------------
| TheLastItem
|-------------------------------------------------------------
|
| PURPOSE: To refer to the address of the last item of the 
|          current list.
|
| DESCRIPTION: 
|
| EXAMPLE:  AnItem = TheLastItem;
|
| NOTE: The address of the current list is held in 'TheList'.
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define TheLastItem            (TheList->LastItem)

/*------------------------------------------------------------
| TheListMark
|-------------------------------------------------------------
|
| PURPOSE: To refer to the mark code of the current list.
|
| DESCRIPTION: 
|
| EXAMPLE:  mark = TheListMark;
|
| NOTE: The address of the current list is held in 'TheList'.
|
| ASSUMES: 
|
| HISTORY: 10.27.93
|
------------------------------------------------------------*/
#define TheListMark        (TheList->ListMark)

#define IN_LINE_TRAVERSALS
        // Define the above statement to enable in-line
        // traversal operations.

#ifdef IN_LINE_TRAVERSALS   
#define ToFirstItem()   (TheItem = TheList->FirstItem)
#define ToLastItem()    (TheItem = TheList->LastItem)
#define ToNextItem()    (TheItem = TheItem->NextItem)
#define ToPriorItem()   (TheItem = TheItem->PriorItem)
#endif

extern    Lot*      TheListMemoryPool;
extern    u32       CountOfListsInUse;
extern    u32       CountOfItemsInUse;
extern    List*     TheListOfFreeLists;
extern    List*     TheListOfFreeItems;
extern    List*     TheListOfFreeItemChains; 
extern    u32*      SegmentChain;  
extern    List*     TheList;
extern    Item*     TheItem;
extern    u32       TheListStack[];
extern    u32       TheListStackIndex;
extern    u16       TheListSystemIsSetUp;
extern    u32       TheRecordSize;  

/* 
   Operations implemented using the preceeding #define 
   statements are included below within comments for reference.
*/

/* void   AddToListItemCount(List*,u32);         */

void        AppendDataToBufferList( List**, u32, u8*, u32 );
void        AppendItems( List*, List* );
void        CleanUpTheListSystem();
void        CompactList( List* );
s32         CompareRecords( s8*, s8* );
u32         CountContiguousItems( Item* );
u32         CountMarkedItems( List* );
void        DeleteAllReferencesToData( List*, u8* );
void        DeleteDuplicateContentReferences( List* );
void        DeleteDuplicateDataReferences( List* );
void        DeleteDuplicateFieldReferences( List*, s32, u32 );
Item*       DeleteFirstReferenceToData( List*, u8* );
void        DeleteList( List* );
void        DeleteListOfDynamicData( List* );
void        DeleteListOfLists( List* );
void        DeleteItem( Item* );
void        DeleteItems( Item* );
void        DeleteMarkedItems( List* );
void        DumpListSystemStatus();
Item*       DuplicateItem( Item* );
List*       DuplicateList( List* );
List*       DuplicateListCompact( List* );
List*       DuplicateMarkedItems( List* );
void        EmptyList( List* );
void        EnsureEnoughFreeItems( u32 );
void        ExchangeItems( List*, Item*, Item* );
Item*       ExtractItemFromList( List*, Item* );
void        ExtractItems( List*, Item*, u32 );
Item*       ExtractFirstItemFromList( List* );
Item*       ExtractLastItemFromList( List* );
List*       ExtractMarkedItems( List* );
Item*       ExtractTheItem();
Item*       FindContiguousItemsInList( List*, u32 );
u8*         FindDataAddressOfNthItem( List*, u32 );
Item*       FindFirstItemLinkedToBuffer( List*, u8* );
Item*       FindFirstItemLinkedToData( List*, u8* );
Item*       FindFirstItemOfSize( List*, u32 );
Item*       FindFirstItemOfType( List*,u32 );
Item*       FindFirstMarkedItem( List* );
Item*       FindFirstMatchingItem( List*, s32, u32, u8* );
Item*       FindFirstUnMarkedItem(List*);
u32         FindIndexOfFirstMarkedItem(List*);
u32         FindIndexOfItemLinkedToData( List*, u8* );
Item*       FindNextItemOfType(List*,Item*,u32);
Item*       FindNextMatchingItem( List*, Item*, u16, u16, u8* );
Item*       FindNthItem( List*, s32 );
Item*       FindPlaceInOrderedList(List*,
                         u8*,
                         s32 (*)( u8*, u8* ) );
void        ForEachItem( List*, void (*)(s8*, u32), u32 );

/* Operations used to get values from Item records:   */
/* u8*   GetItemDataAddress(Item*); */
/* u16  GetItemMark(Item*);        */
/* Item*    GetNextItem(Item*);        */
/* Item*    GetPriorItem(Item*);       */
/* u32  GetSizeOfItemData(Item*);  */
/* u16  GetTypeOfItemData(Item*);  */

/* Operations used to get values from List records:   */
/* u32  GetListItemCount(List*);   */
/* Item*    GetFirstItemOfList(List*); */
/* Item*    GetLastItemOfList(List*);  */
/* u16  GetListMark(List*);        */

void        InsertItemAfterItemInList(List*,Item*,Item*);
void        InsertItemBeforeItemInList(List*,Item*,Item*);
void        InsertItemFirstInList(List*,Item*);
void        InsertItemLastInList(List*,Item*);

Item*       InsertDataAfterItemInList(List*,Item*,u8*);
Item*       InsertDataBeforeItemInList(List*,Item*,u8*);
Item*       InsertDataFirstInList(List*,u8*);
Item*       InsertDataInOrderedList( List*, u8*, s32 (*)( u8*, u8* ) );
Item*       InsertDataLastInList(List*,u8*);

u32         IsAnyItemMarkedInList(List*);
u32         IsAnyItemsInList(List*);
u32         IsItemAlone(Item*);
u32         IsItemFirst(Item*);
u32         IsItemLast(Item*);
u32         IsItemMarked(Item*);
u32         IsListMarked(List*);
u32         IsListsWithDataInCommon(List*,List*);
u32         IsMultipleReferencesToData( List* );
u32         IsTheDataMatching( s32, u32, u8* );

void        JoinLists(List*,List*);
Item*       MakeChainOfItems( u32 );
void        MakeFreeItems( u32 );
Item*       MakeItem();
Item*       MakeItemForData(u8*);
List*       MakeList();
List*       MakeListWithItems( u32 );
void        MarkItem(Item*);
void        MarkItemAsFirst(Item*);
void        MarkItemAsLast(Item*);
void        MarkList(List*);
void        MarkListAsEmpty(List*);
void        MoveChainsToGeneralFreeList();
void        MoveItems( List*, Item*, List*, u32 );
void        MoveItemToFirst( List*, Item* );
u8*         PickRandomData( List* );
List*       PickRandomItems( List*, u32 );
void        PullTheItem();
void        PullTheList();
void        PullTheListAndItem();
void        PushTheList();
void        PushTheListAndItem();
void        PushTheItem();

/* Operations used to put values into Item records:               */
/* void       PutItemDataAddress(Item*,u8*); */
/* void       PutItemMark(Item*,u16);                 */
/* void       PutNextItem(Item*,Item*);        */
/* void       PutPriorItem(Item*,Item*);       */
/* void       PutSizeOfItemData(Item*,u32);           */
/* void       PutTypeOfItemData(Item*,u16);           */

/* Operations used to put values into List records:               */
/* void       PutFirstItemOfList(List*,Item*); */
/* void       PutLastItemOfList(List*,Item*);  */
/* void       PutListItemCount(List*,u32);            */
/* void       PutListMark(List*,u16);                 */

void        ReferToList( List* );
void        ReverseList(List*);
void        RevertToList();
void        SetSizeOfItemsInList( List*, u32 );
void        SetUpTheListSystem( Lot* );
void        SortList(List*, s32 (*)( u8*, u8* ) );
void        SortListAlphabetically(List*);
void        SortListAsBinaryData( List*, u32 );
void        SortListByDataAddress(List*);
void        SortListByItemAddress(List*);
void        SortListDescending(List*, s32 (*)( u8*, u8* ) );
void        SortShortList(List*, s32 (*)( u8*, u8* ) );

/* Fields of the current item:  */                                               
/* u8*      TheDataAddress;     */
/* Item*    TheNextItem;        */
/* Item*    ThePriorItem;       */
/* u16      TheItemMark;        */

/* Fields of the current list:  */                                               
/*  u32     TheItemCount;       */
/*  Item*   TheFirstItem;       */
/*  Item*   TheLastItem;        */
/*  u16     TheListMark;        */

#ifndef IN_LINE_TRAVERSALS
void        ToFirstItem();
void        ToLastItem();
void        ToNextItem();
void        ToPriorItem();
#endif

void        UnMarkAllItemsInList(List*);
void        UnMarkList(List*);
void        UnMarkItem(Item*);
void        ValidateList( List*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
