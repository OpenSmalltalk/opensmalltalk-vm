/*------------------------------------------------------------
| TLListTest.c
|-------------------------------------------------------------
|
| PURPOSE: To test and demonstrate the use of the 'TLList' 
|          linked list system.
|
| DESCRIPTION: Almost every procedure in 'TLList' is 
| validated using automated testing.  Known values are given 
| to each procedure and tests are made for expected results.  
| Test results are reported to the display and to the file 
| 'ListTest.txt'.  Some tests require visual validation.
|
| NOTE: 
|
| HISTORY: 11.04.93 
|          05.01.96 Retested.
|          12.31.98 NT port.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#ifndef FOR_DRIVER

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#endif // not FOR_DRIVER
     
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLTypes.h"
#include "TLBuf.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLList.h"
#include "TLTesting.h"

#include "TLListTest.h"

Item    TestItem[1] = {  (Item*) 2,   // NextItem
                         (Item*) 4,   // PriorItem
                         (u8*)   9,   // BufferAddress
                         (u32)  10,   // SizeOfBuffer
                         (u8*)   6,   // DataAddress
                         (u32)   5,   // SizeOfData
                         (u16)   7,   // TypeOfData
                         (u16)   8 }; // ItemMark
                         
List    TestList[1] = { (Item*) 10, 
                        (Item*) 12, 
                        (u32)   14, 
                        (u16)   16 };

// Test order is important: validity of later tests depends on earlier ones. 
TestRecord    
ListTestSequence[] =
{
// From 'TLTypes.h': 
    { Test_Byte,                                (s8*) "DataSize: u8"                        }, 
    { Test_u16,                                 (s8*) "DataSize: u16"                       }, 
    { Test_u32,                                 (s8*) "DataSize: u32"                       }, 
    { Test_s8,                                  (s8*) "DataSize: s8"                        }, 
    { Test_s16,                                 (s8*) "DataSize: s16"                       }, 
    { Test_s32,                                 (s8*) "DataSize: s32"                       }, 
// From 'Bytes.c':
    { Test_CompareBytes,                        (s8*) "CompareBytes"                        }, 
    { Test_CopyBytes,                           (s8*) "CopyBytes"                           }, 
    { Test_ExchangeBytes,                       (s8*) "ExchangeBytes"                       }, 
    { Test_FillBytes,                           (s8*) "FillBytes"                           }, 
    { Test_IsMatchingBytes,                     (s8*) "IsMatchingBytes"                     }, 
    { Test_ReplaceBytes,                        (s8*) "ReplaceBytes"                        }, 
// From 'Strings.c':
    { Test_CountString,                         (s8*) "CountString"                         }, 
    { Test_CopyString,                          (s8*) "CopyString"                          }, 
    { Test_AppendString,                        (s8*) "AppendString2"                       }, 
    { Test_AppendStrings,                       (s8*) "AppendStrings"                       }, 
    { Test_ConvertStringToLowerCase,            (s8*) "ConvertStringToLowerCase"            }, 
    { Test_ConvertStringToUpperCase,            (s8*) "ConvertStringToUpperCase"            }, 
    { Test_CompareStrings,                      (s8*) "CompareStrings"                      }, 
    { Test_AddressOfLastCharacterInString,      (s8*) "AddressOfLastCharacterInString"      }, 
    { Test_InsertString,                        (s8*) "InsertString"                        }, 
    { Test_ReplaceByteInString,                 (s8*) "ReplaceByteInString"                 }, 
// From 'TLList.c':
    { Test_GetNextItem,                         (s8*) "GetNextItem"                         }, 
    { Test_PutNextItem,                         (s8*) "PutNextItem"                         }, 
    { Test_TheNextItem,                         (s8*) "TheNextItem"                         }, 
    { Test_GetPriorItem,                        (s8*) "GetPriorItem"                        }, 
    { Test_PutPriorItem,                        (s8*) "PutPriorItem"                        }, 
    { Test_ThePriorItem,                        (s8*) "ThePriorItem"                        }, 
    { Test_GetItemDataAddress,                  (s8*) "GetItemDataAddress"                  }, 
    { Test_PutItemDataAddress,                  (s8*) "PutItemDataAddress"                  }, 
    { Test_TheDataAddress,                      (s8*) "TheDataAddress"                      }, 
    { Test_TheItemMark,                         (s8*) "TheItemMark"                         }, 
    { Test_GetFirstItemOfList,                  (s8*) "GetFirstItemOfList"                  }, 
    { Test_PutFirstItemOfList,                  (s8*) "PutFirstItemOfList"                  }, 
    { Test_TheFirstItem,                        (s8*) "TheFirstItem"                        }, 
    { Test_GetLastItemOfList,                   (s8*) "GetLastItemOfList"                   }, 
    { Test_PutLastItemOfList,                   (s8*) "PutLastItemOfList"                   }, 
    { Test_TheLastItem,                         (s8*) "TheLastItem"                         }, 
    { Test_GetListItemCount,                    (s8*) "GetListItemCount"                    }, 
    { Test_PutListItemCount,                    (s8*) "PutListItemCount"                    }, 
    { Test_TheItemCount,                        (s8*) "TheItemCount"                        }, 
    { Test_TheListMark,                         (s8*) "TheListMark"                         }, 
    { Test_MarkItem,                            (s8*) "MarkItem"                            }, 
    { Test_UnMarkItem,                          (s8*) "UnMarkItem"                          }, 
    { Test_IsItemMarked,                        (s8*) "IsItemMarked"                        }, 
    { Test_MarkList,                            (s8*) "MarkList"                            }, 
    { Test_UnMarkList,                          (s8*) "UnMarkList"                          }, 
    { Test_IsListMarked,                        (s8*) "IsListMarked"                        }, 
    { Test_MarkItemAsFirst,                     (s8*) "MarkItemAsFirst"                     }, 
    { Test_IsItemFirst,                         (s8*) "IsItemFirst"                         }, 
    { Test_MarkItemAsLast,                      (s8*) "MarkItemAsLast"                      }, 
    { Test_IsItemLast,                          (s8*) "IsItemLast"                          }, 
    { Test_IsItemAlone,                         (s8*) "IsItemAlone"                         }, 
    { Test_ToNextItem,                          (s8*) "ToNextItem"                          }, 
    { Test_ToPriorItem,                         (s8*) "ToPriorItem"                         }, 
    { Test_ToFirstItem,                         (s8*) "ToFirstItem"                         }, 
    { Test_ToLastItem,                          (s8*) "ToLastItem"                          }, 
    { Test_SetUpTheListSystem,                  (s8*) "SetUpTheListSystem"                  }, 
    { Test_PushTheItem,                         (s8*) "PushTheItem"                         }, 
    { Test_PullTheItem,                         (s8*) "PullTheItem"                         }, 
    { Test_PushTheList,                         (s8*) "PushTheList"                         }, 
    { Test_PullTheList,                         (s8*) "PullTheList"                         }, 
    { Test_PushTheListAndItem,                  (s8*) "PushTheListAndItem"                  }, 
    { Test_PullTheListAndItem,                  (s8*) "PullTheListAndItem"                  }, 
    { Test_MarkListAsEmpty,                     (s8*) "MarkListAsEmpty"                     }, 
    { Test_IsAnyItemsInList,                    (s8*) "IsAnyItemsInList"                    }, 
    { Test_MakeItem,                            (s8*) "MakeItem"                            }, 
    { Test_DeleteItem,                          (s8*) "DeleteItem"                          }, 
    { Test_MakeItemForData,                     (s8*) "MakeItemForData"                     }, 
    { Test_MakeList,                            (s8*) "MakeList"                            }, 
    { Test_MakeList,                            (s8*) "MakeList"                            }, 
    { Test_AddToListItemCount,                  (s8*) "AddToListItemCount"                  }, 
    { Test_InsertItemLastInList,                (s8*) "InsertItemLastInList"                }, 
    { Test_InsertDataLastInList,                (s8*) "InsertDataLastInList"                }, 
    { Test_ExtractTheItem,                      (s8*) "ExtractTheItem"                      }, 
    { Test_ExtractItemFromList,                 (s8*) "ExtractItemFromList"                 }, 
    { Test_DeleteList,                          (s8*) "DeleteList"                          }, 
    { Test_DeleteListOfDynamicData,             (s8*) "DeleteListOfDynamicData"             }, 
    { Test_FindFirstItemLinkedToData,           (s8*) "FindFirstItemLinkedToData"           }, 
    { Test_DeleteFirstReferenceToData,          (s8*) "DeleteFirstReferenceToData"          }, 
    { Test_DeleteAllReferencesToData,           (s8*) "DeleteAllReferencesToData"           }, 
    { Test_IsTheDataMatching,                   (s8*) "IsTheDataMatching"                   }, 
    { Test_FindFirstMatchingItem,               (s8*) "FindFirstMatchingItem"               }, 
    { Test_FindNextMatchingItem,                (s8*) "FindNextMatchingItem"                }, 
    { Test_FindFirstMarkedItem,                 (s8*) "FindFirstMarkedItem"                 }, 
    { Test_FindFirstUnMarkedItem,               (s8*) "FindFirstUnMarkedItem"               }, 
    { Test_UnMarkAllItemsInList,                (s8*) "UnMarkAllItemsInList"                }, 
    { Test_FindIndexOfFirstMarkedItem,          (s8*) "FindIndexOfFirstMarkedItem"          }, 
    { Test_ExtractMarkedItems,                  (s8*) "ExtractMarkedItems"                  }, 
    { Test_DeleteMarkedItems,                   (s8*) "DeleteMarkedItems"                   }, 
    { Test_IsAnyItemMarkedInList,               (s8*) "IsAnyItemMarkedInList"               }, 
    { Test_DuplicateList,                       (s8*) "DuplicateList"                       }, 
    { Test_DuplicateMarkedItems,                (s8*) "DuplicateMarkedItems"                }, 
    { Test_ExtractFirstItemFromList,            (s8*) "ExtractFirstItemFromList"            }, 
    { Test_ExtractLastItemFromList,             (s8*) "ExtractLastItemFromList"             }, 
    { Test_ReverseList,                         (s8*) "ReverseList"                         }, 
    { Test_JoinLists,                           (s8*) "JoinLists"                           }, 
    { Test_ExchangeItems,                       (s8*) "ExchangeItems"                       }, 
    { Test_InsertItemFirstInList,               (s8*) "InsertItemFirstInList"               }, 
    { Test_InsertItemAfterItemInList,           (s8*) "InsertItemAfterItemInList"           }, 
    { Test_InsertItemBeforeItemInList,          (s8*) "InsertItemBeforeItemInList"          }, 
    { Test_InsertDataFirstInList,               (s8*) "InsertDataFirstInList"               }, 
    { Test_InsertDataAfterItemInList,           (s8*) "InsertDataAfterItemInList"           }, 
    { Test_InsertDataBeforeItemInList,          (s8*) "InsertDataBeforeItemInList"          }, 
    { Test_FindPlaceInOrderedList,              (s8*) "FindPlaceInOrderedList"              }, 
    { Test_InsertDataInOrderedList,             (s8*) "InsertDataInOrderedList"             }, 
    { Test_SortShortList,                       (s8*) "SortShortList"                       }, 
    { Test_CleanUpTheListSystem,                (s8*) "CleanUpTheListSystem"                }, 
    { 0, 0 } // This terminates the list.
};

/*------------------------------------------------------------
| OutputListOfStrings
|-------------------------------------------------------------
|
| PURPOSE: To output strings attached to a list.
|
| DESCRIPTION: Each string is placed on a separate line.
| A blank line is printed after the list.
|
| EXAMPLE:  OutputListOfStrings( MyList );
|
| NOTE: 
|
| ASSUMES: Each string is able to fit on a single line.
|
| HISTORY: 01.13.88
|          02.08.93 removed item count control in favor of 
|                    TheItem being non-0.
|          11.08.93 added explicit stream parameter.
|          08.07.01 Replaced fprintf with printt.
------------------------------------------------------------*/
void
OutputListOfStrings( List* AList )
{
    ReferToList( AList ); 
    
    while(TheItem)
    {
        printt( "%s\n", (s8*)TheDataAddress);
        
        ToNextItem();
    }

    printt( "\n" );

    RevertToList();
}

/*------------------------------------------------------------
| OutputListSystemStatus
|-------------------------------------------------------------
|
| PURPOSE: To report on list system status.
|
| DESCRIPTION:  
|
| EXAMPLE:  OutputListSystemStatus();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.26.91
|          11.01.93 extended 
|          11.08.93 added 'OutputStream' parameter
|          01.12.97 revised for new free list structure.
|          08.06.01 Replaced fprintf with printt.
------------------------------------------------------------*/
void
OutputListSystemStatus()
{
    s8* MarkString;
    u32 FreeLists;
    u32 FreeItems;
    
    if( TheListOfFreeLists )
    {
        FreeLists = TheListOfFreeLists->ItemCount;
    }
    else
    {
        FreeLists = 0;
    }
    
    if( TheListOfFreeItems )
    {
        FreeItems = TheListOfFreeItems->ItemCount;
    }
    else
    {
        FreeItems = 0;
    }
    
    printt( "\n" );
    printt( "List System Status:\n" );
    printt( "    TheListSystemIsSetUp...%d\n\n",
            TheListSystemIsSetUp );

    printt( "    ListsInUse.............%ld\n",
                                  CountOfListsInUse);
    printt( "    ItemsInUse.............%ld\n\n",
                                  CountOfItemsInUse);
    printt( "    FreeLists..............%ld\n",
                                  FreeLists);
                         
    printt( "    FreeItems..............%ld\n\n",
                                  FreeItems);

    printt( "    TheList................%lx\n",TheList);
    if(TheList)
    {
          printt( "        TheFirstItem.......%lx\n",
                                            TheFirstItem);
          printt( "        TheLastItem........%lx\n",
                                            TheLastItem);
          MarkString = (s8*) "UnMarked";
          if(IsListMarked(TheList)) MarkString = (s8*) "Marked";
          printt( "        TheListMark........%s\n",
                                               MarkString);
          printt( "        TheItemCount.......%ld\n\n",
                                            TheItemCount);
    }
    
    printt( "    TheItem................%lx\n",TheItem);
    if(TheItem)
    {
        printt( "        ThePriorItem.......%lx\n",
                                            ThePriorItem);
        printt( "        TheNextItem........%lx\n",
                                            TheNextItem);
        MarkString = (s8*) "UnMarked";
        if(IsItemMarked(TheItem)) MarkString = (s8*) "Marked";
        printt( "        TheItemMark........%s\n",
                                            MarkString);
        printt( "        TheDataAddress.....%lx\n",
                                            TheDataAddress);
    }
}

/*------------------------------------------------------------
| Test_Byte
|-------------------------------------------------------------
|
| PURPOSE: To test the 'u8' data type.
|
| DESCRIPTION: Returns non-zero, if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.08.93
|
------------------------------------------------------------*/
u32  
Test_Byte()
{
    s32 Result;
    u8          AByte;
    u8          ByteTable[2] = { 1, 2 };
    u8*         ByteAddress;
    
    if( sizeof( u8 ) != 1 ) return( 1 );
   
    Result = ByteTable[0] - 1; 
        if( Result != 0 ) return( 2 );
    
    Result = ByteTable[1] - 2; 
        if( Result != 0 ) return( 3 );
    
    ByteAddress = ByteTable;
    Result = ByteTable[0] - *ByteAddress;
        if( Result != 0 ) return( 4 );

    AByte = 250; // a 'u8' is unsigned.
        if( AByte < 0 ) return( 5 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_u16
|-------------------------------------------------------------
|
| PURPOSE: To test the 'u16' data type.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.08.93
|
------------------------------------------------------------*/
u32  
Test_u16()
{
    s32 Result;
    u16         Au16;
    u16         u16Table[2] = { 0, 1 };
    u16*        u16Address;
    
    if( sizeof(u16) != 2 ) return( 1 );
    
    Result = u16Table[0] - 0; 
        if( Result != 0 ) return( 2 );
    
    Result = u16Table[1] - 1; 
        if( Result != 0 ) return( 3 );
    
    u16Address = u16Table;
    Result = u16Table[0] - *u16Address;
        if( Result != 0 ) return( 4 );

    Au16 = 35000; // a 'u16' is unsigned.
        if( Au16 < 0 ) return( 5 );
     
    return( 0 );
}

/*------------------------------------------------------------
| Test_u32
|-------------------------------------------------------------
|
| PURPOSE: To test the 'u32' data type.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.08.93
|
------------------------------------------------------------*/
u32  
Test_u32()
{
    s32 Result;
    u32         Au32;
    u32         u32Table[2] = { 0, 1 };
    u32*        u32Address;
    
    if( sizeof(u32) != 4 ) return( 1 );

    Result = u32Table[0] - 0; 
        if( Result != 0 ) return( 2 );
    
    Result = u32Table[1] - 1; 
        if( Result != 0 ) return( 3 );
    
    u32Address = u32Table;
    Result = u32Table[0] - *u32Address;
        if( Result != 0 ) return( 4 );

    Au32 = 2200000000; // a 'u32' is unsigned.
        if( Au32 < 0 ) return( 5 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_s8
|-------------------------------------------------------------
|
| PURPOSE: To test the 's8' data type.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.09.93
|
------------------------------------------------------------*/
u32  
Test_s8()
{
    s32 Result;
    s8          As8;
    s8          s8Table[2] = { -1, 1 };
    s8*         As8Address;
    
    if( sizeof( s8 ) != 1 ) return( 1 );
    
    Result = s8Table[0] + 1; 
        if( Result != 0 ) return( 2 );
    
    Result = s8Table[1] - 1; 
        if( Result != 0 ) return( 3 );
    
    As8Address = s8Table;
    Result = s8Table[0] - *As8Address;
        if( Result != 0 ) return( 4 );

    As8 = (s8) 250; // A 's8' must be in the range
                    // +/- 127, so '250' should be 
                    // interpreted as a negative number. 
                
        if( As8 > 0 ) return( 5 );
   
    return( 0 );
}

/*------------------------------------------------------------
| Test_s16
|-------------------------------------------------------------
|
| PURPOSE: To test the 's16' data type.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.09.93
|
------------------------------------------------------------*/
u32  
Test_s16()
{
    s32 Result;
    s16         As16;
    s16         s16Table[2] = { 0, -1 };
    s16*        As16Address;
    
    if( sizeof( s16 ) != 2 ) return( 1 );

    Result = s16Table[0] - 0; 
        if( Result != 0 ) return( 2 );
    
    Result = s16Table[1] + 1; 
        if( Result != 0 ) return( 3 );
    
    As16Address = s16Table;
    Result = s16Table[0] - *As16Address;
        if( Result != 0 ) return( 4 );

    As16 = (s16) 35000; 
        if( As16 > 0 ) return( 5 );
   
    return( 0 );
}

/*------------------------------------------------------------
| Test_s32
|-------------------------------------------------------------
|
| PURPOSE: To test the 's32' data type.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.09.93
|
------------------------------------------------------------*/
u32  
Test_s32()
{
    s32 Result;
    s32         As32;
    s32         s32Table[2] = { 0, -1 };
    s32*        As32Address;
    
    if( sizeof( s32 ) != 4 ) return( 1 );

    Result = s32Table[0] - 0; 
        if( Result != 0 ) return( 2 );
    
    Result = s32Table[1] + 1; 
        if( Result != 0 ) return( 3 );
    
    As32Address = s32Table;
    Result = s32Table[0] - *As32Address;
        if( Result != 0 ) return( 4 );

    As32 = 2200000000; // a 's32' is signed.
        if( As32 > 0 ) return( 5 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_CompareBytes
|-------------------------------------------------------------
|
| PURPOSE: To test the 'CompareBytes' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: You must cast the count parameters of 'CompareBytes'
|       to be a 'u32' to avoid errors when using 'Think C'.
|
| ASSUMES: 
|
| HISTORY: 11.04.93
|
------------------------------------------------------------*/
u32  
Test_CompareBytes()
{
    s32  Result;
    u8          ABytes[] = { 1, 1, 1, 1 };
    u8          BBytes[] = { 1, 1, 1, 8, 1 };
    u8          CBytes[] = { 1, 1, 1, 1, 2, 1 };
    
    Result = CompareBytes( ABytes, (u32) 4, BBytes, (u32) 5 );
        if( Result >= 0 ) return( 1 );
    
    Result = CompareBytes( ABytes, (u32) 4, CBytes, (u32) 6 );
        if( Result >= 0 ) return( 2 );
    
    Result = CompareBytes( BBytes, (u32) 5, CBytes, (u32) 6 );
        if( Result <= 0 ) return( 3 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_CopyBytes
|-------------------------------------------------------------
|
| PURPOSE: To test the 'CopyBytes' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: You must cast literal count parameters to be a 'u32' 
|       to avoid errors when using 'Think C'.
|
| ASSUMES: 
|
| HISTORY: 11.10.93
|
------------------------------------------------------------*/
u32  
Test_CopyBytes()
{
    u8  ABytes[] = { 1, 2, 3, 4 };
    u8  BBytes[] = { 0, 0, 0, 0, 0, 0 };
    u8  CBytes[] = { 5, 6, 7, 8 };
    
    // Copy ABytes into middle of BBytes.
    CopyBytes( ABytes, &BBytes[1], (u32) 4 );
        if( BBytes[0] != 0 ) return( 1 );
        if( BBytes[1] != 1 ) return( 2 );
        if( BBytes[2] != 2 ) return( 3 );
        if( BBytes[3] != 3 ) return( 4 );
        if( BBytes[4] != 4 ) return( 5 );
        if( BBytes[5] != 0 ) return( 6 );
        
    // Copy CBytes into middle of BBytes.
    CopyBytes( CBytes, &BBytes[1], (u32) 4 );
        if( BBytes[0] != 0 ) return( 7 );
        if( BBytes[1] != 5 ) return( 8 );
        if( BBytes[2] != 6 ) return( 9 );
        if( BBytes[3] != 7 ) return( 10 );
        if( BBytes[4] != 8 ) return( 11 );
        if( BBytes[5] != 0 ) return( 12 );
    
    // Copy last 4 bytes of BBytes into the first 4.
    CopyBytes( &BBytes[2], BBytes, (u32) 4 );
        if( BBytes[0] != 6 ) return( 13 );
        if( BBytes[1] != 7 ) return( 14 );
        if( BBytes[2] != 8 ) return( 15 );
        if( BBytes[3] != 0 ) return( 16 );
        if( BBytes[4] != 8 ) return( 17 );
        if( BBytes[5] != 0 ) return( 18 );
    
    // Copy first 4 bytes of BBytes into the last 4.
    CopyBytes( BBytes, &BBytes[2], (u32) 4 );
        if( BBytes[0] != 6 ) return( 19 );
        if( BBytes[1] != 7 ) return( 20 );
        if( BBytes[2] != 6 ) return( 21 );
        if( BBytes[3] != 7 ) return( 22 );
        if( BBytes[4] != 8 ) return( 23 );
        if( BBytes[5] != 0 ) return( 24 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_ExchangeBytes
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ExchangeBytes' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: You must cast literal count parameters to be a 'u32' 
|       to avoid errors when using 'Think C'.
|
| ASSUMES: 
|
| HISTORY: 11.10.93
|
------------------------------------------------------------*/
u32  
Test_ExchangeBytes()
{
    u8  ABytes[] = { 1, 2, 3, 4 };
    u8  BBytes[] = { 5, 6, 7, 8 };
    
    ExchangeBytes( ABytes, BBytes, (u32) 4 );
        if( BBytes[0] != 1 ) return( 1 );
        if( BBytes[1] != 2 ) return( 2 );
        if( BBytes[2] != 3 ) return( 3 );
        if( BBytes[3] != 4 ) return( 4 );
        
        if( ABytes[0] != 5 ) return( 5 );
        if( ABytes[1] != 6 ) return( 6 );
        if( ABytes[2] != 7 ) return( 7 );
        if( ABytes[3] != 8 ) return( 8 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_FillBytes
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FillBytes' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: You must cast literal count parameter to be a 'u32'
|       to avoid errors.
|
| ASSUMES: 
|
| HISTORY: 11.10.93
|
------------------------------------------------------------*/
u32  
Test_FillBytes()
{
    u8    ABytes[] = { 0, 0, 0, 0 };

    FillBytes( &ABytes[1], (u32) 2, (u16) 1 );
        if( ABytes[0] != 0 ) return( 1 );
        if( ABytes[1] != 1 ) return( 2 );
        if( ABytes[2] != 1 ) return( 3 );
        if( ABytes[3] != 0 ) return( 4 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_IsMatchingBytes
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsMatchingBytes' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: You must cast literal count parameter to be a 'u32'
|       to avoid errors.
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_IsMatchingBytes()
{
    u32     Result;
    u8      ABytes[] = { 0, 0, 0, 0 };
    u8      BBytes[] = { 0, 1, 2, 3 };

    Result = IsMatchingBytes( ABytes, BBytes, (u32) 4 );
        if( Result != 0 ) return( 1 );
        
    Result = IsMatchingBytes( ABytes, ABytes, (u32) 4 );
        if( Result == 0 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_ReplaceBytes
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ReplaceBytes' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: You must cast literal count parameter to be a 'u32'
|       to avoid errors.
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_ReplaceBytes()
{
    u8    ABytes[] = { 4, 3, 6, 1 };

    ReplaceBytes( ABytes, (u32) 4, (u16) 3, (u16) 9 );
    ReplaceBytes( ABytes, (u32) 4, (u16) 6, (u16) 7 );
        if( ABytes[0] != 4 ) return( 1 );
        if( ABytes[1] != 9 ) return( 2 );
        if( ABytes[2] != 7 ) return( 3 );
        if( ABytes[3] != 1 ) return( 4 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_AppendString
|-------------------------------------------------------------
|
| PURPOSE: To test the 'AppendString2' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_AppendString()
{
    s8    ABytes[] = "First\0      ";
    s8    BBytes[] = "Last";

    AppendString2( ABytes, BBytes );
        if( ABytes[0] != 'F' ) return( 1 );
        if( ABytes[1] != 'i' ) return( 2 );
        if( ABytes[2] != 'r' ) return( 3 );
        if( ABytes[3] != 's' ) return( 4 );
        if( ABytes[4] != 't' ) return( 5 );
        if( ABytes[5] != 'L' ) return( 6 );
        if( ABytes[6] != 'a' ) return( 7 );
        if( ABytes[7] != 's' ) return( 8 );
        if( ABytes[8] != 't' ) return( 9 );
        if( ABytes[9] != 0 ) return( 10 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_AppendStrings
|-------------------------------------------------------------
|
| PURPOSE: To test the 'AppendStrings' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_AppendStrings()
{
    s8    ABytes[] = "1st\0         ";
    s8    BBytes[] = "2nd";
    s8    CBytes[] = "3rd";

    AppendStrings( ABytes, 
                   BBytes, 
                   CBytes, 
                   (s8*) 0 );
                   
        if( ABytes[0] != '1' ) return( 1 );
        if( ABytes[1] != 's' ) return( 2 );
        if( ABytes[2] != 't' ) return( 3 );
        if( ABytes[3] != '2' ) return( 4 );
        if( ABytes[4] != 'n' ) return( 5 );
        if( ABytes[5] != 'd' ) return( 6 );
        if( ABytes[6] != '3' ) return( 7 );
        if( ABytes[7] != 'r' ) return( 8 );
        if( ABytes[8] != 'd' ) return( 9 );
        if( ABytes[9] != 0 ) return( 10 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_CountString
|-------------------------------------------------------------
|
| PURPOSE: To test the 'CountString' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_CountString()
{
    u32 Result;
    s8  ABytes[] = "First";
    s8  BBytes[] = "Last";

    Result = CountString( ABytes );
        if( Result != 5 ) return( 1 );

    Result = CountString( BBytes );
        if( Result != 4 ) return( 2 );
        
    Result = CountString( (s8*) "First" );
        if( Result != 5 ) return( 3 );

    Result = CountString( (s8*) "Last" );
        if( Result != 4 ) return( 4 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_CopyString
|-------------------------------------------------------------
|
| PURPOSE: To test the 'CopyString' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_CopyString()
{
    s8    AString[] = "abc";
    s8    BString[] = ".....";
    
    // Copy AString into middle of BString.
    CopyString( AString, &BString[1] );
        if( BString[0] != '.' ) return( 1 );
        if( BString[1] != 'a' ) return( 2 );
        if( BString[2] != 'b' ) return( 3 );
        if( BString[3] != 'c' ) return( 4 );
        if( BString[4] !=  0 )  return( 5 );
            
    return( 0 );
}

/*------------------------------------------------------------
| Test_CompareStrings
|-------------------------------------------------------------
|
| PURPOSE: To test the 'CompareStrings' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_CompareStrings()
{
    s32    Result;
    
    
    Result = CompareStrings( (s8*) "abc", (s8*) "ABC" );
        if( Result != 0 ) return( 1 );
            
    Result = CompareStrings( (s8*) "abc", (s8*) "ACC" );
        if( Result >= 0 ) return( 2 );
            
    Result = CompareStrings( (s8*) "abc", (s8*) "ABCD" );
        if( Result >= 0 ) return( 3 );
            
    Result = CompareStrings( (s8*) "ABCD", (s8*) "abc" );
        if( Result < 0 ) return( 4 );
            
    return( 0 );
}

/*------------------------------------------------------------
| Test_ConvertStringToLowerCase
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ConvertStringToLowerCase' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_ConvertStringToLowerCase()
{
    s8    AString[] = "123ABC";
    
    ConvertStringToLowerCase( AString );
        if( AString[0] != '1' ) return( 1 );
        if( AString[1] != '2' ) return( 2 );
        if( AString[2] != '3' ) return( 3 );
        if( AString[3] != 'a' ) return( 4 );
        if( AString[4] != 'b' ) return( 5 );
        if( AString[5] != 'c' ) return( 6 );
            
    return( 0 );
}

/*------------------------------------------------------------
| Test_ConvertStringToUpperCase
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ConvertStringToUpperCase' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_ConvertStringToUpperCase()
{
    s8    AString[] = "123abc";
    
    ConvertStringToUpperCase( AString );
        if( AString[0] != '1' ) return( 1 );
        if( AString[1] != '2' ) return( 2 );
        if( AString[2] != '3' ) return( 3 );
        if( AString[3] != 'A' ) return( 4 );
        if( AString[4] != 'B' ) return( 5 );
        if( AString[5] != 'C' ) return( 6 );
            
    return( 0 );
}

/*------------------------------------------------------------
| Test_AddressOfLastCharacterInString
|-------------------------------------------------------------
|
| PURPOSE: To test the 'AddressOfLastCharacterInString' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_AddressOfLastCharacterInString()
{
    s8  AString[] = "123abc";
    s8  BString[] = "\0";
    
    s8* LastByte;
    
    LastByte = AddressOfLastCharacterInString( AString );
        if( LastByte != &AString[5] ) return( 1 );
            
    LastByte = AddressOfLastCharacterInString( BString );
        if( LastByte != &BString[0] ) return( 2 );
            
    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertString
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertString' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_InsertString()
{
    s8  AString[] = "AA.\0       ";
    s8  BString[] = " is ";
    
    InsertString( BString, AString, (u32) 1 );
        if( AString[0] != 'A' ) return( 1 );
        if( AString[1] != ' ' ) return( 2 );
        if( AString[2] != 'i' ) return( 3 );
        if( AString[3] != 's' ) return( 4 );
        if( AString[4] != ' ' ) return( 5 );
        if( AString[5] != 'A' ) return( 6 );
        if( AString[6] != '.' ) return( 7 );
            
    return( 0 );
}

/*------------------------------------------------------------
| Test_ReplaceByteInString
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ReplaceByteInString' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 'u16' used as parameter instead of 'u8' because
|       Think C can't pass 'u8' parameters properly. See
|       'TLTypes.h' for more. 
|
| ASSUMES: 
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_ReplaceByteInString()
{
    s8 AString[] = "A is B.";

    ReplaceBytesInString( AString, (u16) 'B', (u16) 'A' );
        if( AString[0] != 'A' ) return( 1 );
        if( AString[1] != ' ' ) return( 2 );
        if( AString[2] != 'i' ) return( 3 );
        if( AString[3] != 's' ) return( 4 );
        if( AString[4] != ' ' ) return( 5 );
        if( AString[5] != 'A' ) return( 6 );
        if( AString[6] != '.' ) return( 7 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_GetNextItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'GetNextItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: A specific order of fields within an ItemRecord.
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_GetNextItem()
{
    Item*    AnItem;

    AnItem = GetNextItem( TestItem );
    
        if( AnItem != (Item*) 2 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PutNextItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PutNextItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PutNextItem()
{
    Item*    AnItem;

    PutNextItem( TestItem, (Item*) 20 );
    AnItem = GetNextItem( TestItem );
    
        if( AnItem != (Item*) 20 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_TheNextItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'TheNextItem' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_TheNextItem()
{
    TheItem = TestItem;
    
        if( TheNextItem != GetNextItem( TestItem ) ) return( 1 );
        
    TheNextItem = (Item*) 44;
        if( GetNextItem( TestItem ) != (Item*) 44 ) return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_GetPriorItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'GetPriorItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: A specific order of fields within an ItemRecord.
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_GetPriorItem()
{
    Item*    AnItem;

    AnItem = GetPriorItem( TestItem );
    
        if( AnItem != (Item*) 4 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PutPriorItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PutPriorItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PutPriorItem()
{
    Item*    AnItem;

    PutPriorItem( TestItem, (Item*) 22 );
    AnItem = GetPriorItem( TestItem );
    
        if( AnItem != (Item*) 22 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_ThePriorItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ThePriorItem' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_ThePriorItem()
{
    TheItem = TestItem;
    
        if( ThePriorItem != GetPriorItem( TestItem ) ) return( 1 );
        
    ThePriorItem = (Item*) 46;
        if( GetPriorItem( TestItem ) != (Item*) 46 ) return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_GetItemDataAddress
|-------------------------------------------------------------
|
| PURPOSE: To test the 'GetItemDataAddress' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: A specific order of fields within an ItemRecord.
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_GetItemDataAddress()
{
    u8*    SomeData;

    SomeData = GetItemDataAddress( TestItem );
    
        if( SomeData != (u8*) 6 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PutItemDataAddress
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PutItemDataAddress' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PutItemDataAddress()
{
    u8*    SomeData;

    PutItemDataAddress( TestItem, (u8*) 24 );
    SomeData = GetItemDataAddress( TestItem );
    
        if( SomeData != (u8*) 24 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_TheDataAddress
|-------------------------------------------------------------
|
| PURPOSE: To test the 'TheDataAddress' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_TheDataAddress()
{
    TheItem = TestItem;
    
        if( TheDataAddress != GetItemDataAddress( TestItem ) ) 
            return( 1 );
        
    TheDataAddress = (u8*) 33;
        if( GetItemDataAddress( TestItem ) != (u8*) 33 ) 
            return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_TheItemMark
|-------------------------------------------------------------
|
| PURPOSE: To test the 'TheItemMark' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|          11.24.97 replaced 'GetItemMark' with direct field 
|                   access.
------------------------------------------------------------*/
u32  
Test_TheItemMark()
{
    TheItem = TestItem;
    
        if( TheItemMark != TestItem->ItemMark ) return( 1 );
        
    TheItemMark = (u16) Marked;
        if( TestItem->ItemMark != (u16) Marked ) return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_GetFirstItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'GetFirstItemOfList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: A specific order of fields within an ItemRecord.
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_GetFirstItemOfList()
{
    Item*    AnItem;

    AnItem = GetFirstItemOfList( TestList );
    
        if( AnItem != (Item*) 10 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PutFirstItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PutFirstItemOfList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PutFirstItemOfList()
{
    Item*    AnItem;

    PutFirstItemOfList( TestList, (Item*) 24 );
    
    AnItem = GetFirstItemOfList( TestList );
    
        if( AnItem != (Item*) 24 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_TheFirstItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'TheFirstItem' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_TheFirstItem()
{
    TheList = TestList;
    
        if( TheFirstItem != GetFirstItemOfList( TestList ) ) 
            return( 1 );
        
    TheFirstItem = (Item*) 888;
        if( GetFirstItemOfList( TestList ) != 
           (Item*) 888 ) return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_GetLastItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'GetLastItemOfList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: A specific order of fields within an ItemRecord.
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_GetLastItemOfList()
{
    Item*    AnItem;

    AnItem = GetLastItemOfList( TestList );
    
        if( AnItem != (Item*) 12 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PutLastItemOfList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PutLastItemOfList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PutLastItemOfList()
{
    Item*    AnItem;

    PutLastItemOfList( TestList, (Item*) 26 );
    
    AnItem = GetLastItemOfList( TestList );
    
        if( AnItem != (Item*) 26 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_TheLastItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'TheLastItem' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_TheLastItem()
{
    TheList = TestList;
    
        if( TheLastItem != GetLastItemOfList( TestList ) ) 
            return( 1 );
        
    TheLastItem = (Item*) 890;
        if( GetLastItemOfList( TestList ) != 
           (Item*) 890 ) return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_GetListItemCount
|-------------------------------------------------------------
|
| PURPOSE: To test the 'GetListItemCount' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: A specific order of fields within an ItemRecord.
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_GetListItemCount()
{
    u32    ACount;

    ACount = GetListItemCount( TestList );
    
        if( ACount != (u32) 14 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PutListItemCount
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PutListItemCount' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PutListItemCount()
{
    u32    ACount;

    PutListItemCount( TestList, (u32) 17 );
    
    ACount = GetListItemCount( TestList );
    
        if( ACount != (u32) 17 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_TheItemCount
|-------------------------------------------------------------
|
| PURPOSE: To test the 'TheItemCount' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_TheItemCount()
{
    TheList = TestList;
    
        if( TheItemCount != GetListItemCount( TestList ) ) 
            return( 1 );
        
    TheItemCount = (u32) 123;
        if( GetListItemCount( TestList ) != (u32) 123 ) 
            return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_GetListMark
|-------------------------------------------------------------
|
| PURPOSE: To test the 'GetListMark' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: A specific order of fields within an ItemRecord.
|
| HISTORY: 11.11.93
|
------------------------------------------------------------*/
u32  
Test_GetListMark()
{
    u16    AMark;

    AMark = GetListMark( TestList );
    
        if( AMark != (u16) 16 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PutListMark
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PutListMark' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PutListMark()
{
    u16    AMark;

    PutListMark( TestList, (u16) 19 );
    
    AMark = GetListMark( TestList );
    
        if( AMark != (u16) 19 ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_TheListMark
|-------------------------------------------------------------
|
| PURPOSE: To test the 'TheListMark' reference macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_TheListMark()
{
    TheList = TestList;
    
        if( TheListMark != GetListMark( TestList ) ) 
            return( 1 );
        
    TheListMark = (u16) Marked;
        if( GetListMark( TestList ) != (u16) Marked ) 
            return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_MarkItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MarkItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|          11.24.97 deleted special mark field accessors.
------------------------------------------------------------*/
u32  
Test_MarkItem()
{
    u16    AMark;

    TestItem->ItemMark = (u16) 0;
    
    MarkItem( TestItem );
    
    AMark = TestItem->ItemMark;
    
        if( AMark != (u16) Marked ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_UnMarkItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'UnMarkItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|          11.24.97 deleted special mark field accessors.
------------------------------------------------------------*/
u32  
Test_UnMarkItem()
{
    u16    AMark;

    TestItem->ItemMark = (u16) Marked;
    
    UnMarkItem( TestItem );
    
    AMark = TestItem->ItemMark;
    
        if( AMark == (u16) Marked ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_IsItemMarked
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsItemMarked' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_IsItemMarked()
{
    MarkItem( TestItem );
    
        if( !IsItemMarked( TestItem ) ) return( 1 );
        
    UnMarkItem( TestItem );
    
        if( IsItemMarked( TestItem ) ) return( 2 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_MarkList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MarkList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_MarkList()
{
    u16    AMark;

    PutListMark( TestList, (u16) 0 );
    
    MarkList( TestList );
    
    AMark = GetListMark( TestList );
    
        if( AMark != (u16) Marked ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_UnMarkList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'UnMarkList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_UnMarkList()
{
    u16    AMark;

    PutListMark( TestList, (u16) Marked );
    
    UnMarkList( TestList );
    
    AMark = GetListMark( TestList );
    
        if( AMark == (u16) Marked ) return( 1 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_IsListMarked
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsListMarked' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_IsListMarked()
{
    MarkList( TestList );
    
        if( !IsListMarked( TestList ) ) return( 1 );
        
    UnMarkList( TestList );
    
        if( IsListMarked( TestList ) ) return( 2 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_MarkItemAsFirst
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MarkItemAsFirst' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_MarkItemAsFirst()
{
    PutPriorItem( TestItem, (Item*) 1900 );
    
    MarkItemAsFirst( TestItem );
    
        if( GetPriorItem( TestItem ) != (Item*) 0 ) 
            return( 1 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_IsItemFirst
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsItemFirst' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_IsItemFirst()
{
    
    MarkItemAsFirst( TestItem );
    
        if( !IsItemFirst( TestItem ) )  return( 1 );

    PutPriorItem( TestItem, (Item*) 1900 );
        if( IsItemFirst( TestItem ) )   return( 2 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_MarkItemAsFirst
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MarkItemAsFirst' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_MarkItemAsLast()
{
    PutNextItem( TestItem, (Item*) 1904 );
    
    MarkItemAsLast( TestItem );
    
        if( GetNextItem( TestItem ) != (Item*) 0 ) 
            return( 1 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_IsItemLast
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsItemLast' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_IsItemLast()
{
    
    MarkItemAsLast( TestItem );
    
        if( !IsItemLast( TestItem ) )  return( 1 );

    PutNextItem( TestItem, (Item*) 1902 );
        if( IsItemLast( TestItem ) )   return( 2 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_IsItemAlone
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsItemAlone' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_IsItemAlone()
{
    
    PutNextItem( TestItem, (Item*) 1906 );
        if( IsItemAlone( TestItem ) )  return( 1 );
        
    MarkItemAsLast( TestItem );
    
    PutPriorItem( TestItem, (Item*) 1908 );
        if( IsItemAlone( TestItem ) )  return( 2 );
    
    MarkItemAsFirst( TestItem );
        if( !IsItemAlone( TestItem ) )  return( 3 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_ToNextItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ToNextItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_ToNextItem()
{
    
    TheItem = TestItem;
    
    PutNextItem( TestItem, (Item*) 1908 );
    
    ToNextItem();
        if( TheItem != (Item*) 1908 )  return( 1 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_ToPriorItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ToPriorItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_ToPriorItem()
{
    
    TheItem = TestItem;
    
    PutPriorItem( TestItem, (Item*) 1910 );
    
    ToPriorItem();
        if( TheItem != (Item*) 1910 )  return( 1 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_ToFirstItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ToFirstItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_ToFirstItem()
{
    
    TheList = TestList;
    
    TheFirstItem = TestItem;
    TheLastItem  = (Item*) 0;
    
    TheItem = (Item*) 1912;
    
    ToFirstItem();
        if( TheItem != TestItem )  return( 1 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_ToLastItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ToLastItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_ToLastItem()
{
    
    TheList = TestList;
    
    TheLastItem   = TestItem;
    TheFirstItem  = (Item*) 0;
    
    TheItem = (Item*) 1914;
    
    ToLastItem();
        if( TheItem != TestItem )  return( 1 );

    return( 0 );
}

/*------------------------------------------------------------
| Test_SetUpTheListSystem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'SetUpTheListSystem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|          05.01.96 deleted 'MaxCountOfLists', 'MaxCountOfItems', 
|                   'ListSpace', 'ItemSpace'.
|          01.10.97 revised for new free list structure.
------------------------------------------------------------*/
u32  
Test_SetUpTheListSystem()
{
    TheListSystemIsSetUp = 0;
    
    TheListStackIndex  = 10;
    TheListOfFreeItems = (List*) 0;
    TheListOfFreeLists = (List*) 0;
    SegmentChain       = (u32*)  0;
     
    SetUpTheListSystem(0);
    
        if( TheListSystemIsSetUp == 0 )         return( 1 );
        if( TheListStackIndex != 0 )            return( 2 );
        if( TheListOfFreeItems == (List*) 0 )   return( 3 );
        if( TheListOfFreeLists == (List*) 0 )   return( 4 );
        if( SegmentChain == (u32*) 0 )          return( 5 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PushTheItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PushTheItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PushTheItem()
{
    u32    i;
    
    TheItem = TestItem;
    i = TheListStackIndex;
    
    PushTheItem();
    
        if( TheListStackIndex != i+1 ) return( 1 );
        if( TheListStack[i+1] != (u32) TestItem ) return( 2 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PullTheItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PullTheItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PullTheItem()
{
    u32    i;
    
    TheItem = TestItem;
    i = TheListStackIndex;
    
    PushTheItem();
    TheItem = (Item*) 0;
    PullTheItem();
    
        if( TheListStackIndex != i ) return( 1 );
        if( TheItem != TestItem )    return( 2 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PushTheList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PushTheList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PushTheList()
{
    u32    i;
    
    TheList = TestList;
    i = TheListStackIndex;
    
    PushTheList();
    
        if( TheListStackIndex != i+1 ) return( 1 );
        if( TheListStack[i+1] != (u32) TestList ) return( 2 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PullTheList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PullTheList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PullTheList()
{
    u32    i;
    
    TheList = TestList;
    i = TheListStackIndex;
    
    PushTheList();
    TheList = (List*) 0;
    PullTheList();
    
        if( TheListStackIndex != i ) return( 1 );
        if( TheList != TestList )    return( 2 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PushTheListAndItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PushTheListAndItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PushTheListAndItem()
{
    u32    i;
    
    TheList = TestList;
    TheItem = TestItem;
    
    i = TheListStackIndex;
    
    PushTheListAndItem();
    
        if( TheListStackIndex != i+2 ) return( 1 );
        if( TheListStack[i+1] != (u32) TestList ) return( 2 );
        if( TheListStack[i+2] != (u32) TestItem ) return( 3 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_PullTheListAndItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'PullTheListAndItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_PullTheListAndItem()
{
    u32    i;
    
    TheList = TestList;
    TheItem = TestItem;
    
    i = TheListStackIndex;
    
    PushTheListAndItem();
    
    TheList = (List*) 0;
    TheItem = (Item*) 0;
    
    PullTheListAndItem();
    
        if( TheListStackIndex != i )  return( 1 );
        if( TheList != TestList )     return( 2 );
        if( TheItem != TestItem )     return( 3 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_MarkListAsEmpty
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MarkListAsEmpty' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_MarkListAsEmpty()
{
    
    TheList = TestList;
    
    TheFirstItem = TestItem;
    TheLastItem  = TestItem;
    TheItemCount = (u32) 1;
    
    MarkListAsEmpty( TestList );
    
        if( TheItemCount != (u32) 0 )             return( 1 );
        if( TheFirstItem != (Item*) 0 )    return( 2 );
        if( TheLastItem  != (Item*) 0 )    return( 3 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_IsAnyItemsInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsAnyItemsInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.16.93
|
------------------------------------------------------------*/
u32  
Test_IsAnyItemsInList()
{
    
    TheList = TestList;
    
    TheFirstItem = TestItem;
    TheLastItem  = TestItem;
    TheItemCount = (u32) 1;
        if( !IsAnyItemsInList( TheList ) ) return( 1 );

    MarkListAsEmpty( TestList );
        if( IsAnyItemsInList( TheList ) ) return( 2 );
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_MakeItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MakeItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: There are no existing items.
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_MakeItem()
{
    Item*    AnItem;
    
    // Assuming no existing items.
    AnItem = MakeItem();
    
        if( TheListOfFreeItems->ItemCount != 
            ItemsRecordsPerSegment - 1 ) 
                    return( 1 );
        
        if( SegmentChain == 0 )         return( 2 );
        if( CountOfItemsInUse != 1 )    return( 3 );
                                               
        if( IsItemMarked( AnItem ) )    return( 4 );
        if( GetItemDataAddress( AnItem ) != 0 ) return( 5 );
        if( GetSizeOfItemData( AnItem ) != 0 ) return( 6 );
        if( GetTypeOfItemData( AnItem ) != 0 ) return( 7 );
        
        if( ! IsItemAlone( AnItem ) ) return( 8 );
        
    // The following procedure is not validated at this 
    // point in the test sequence so it can't be used
    // to establish the validity of the procedure being
    // tested.  It's only to clean up after the test.
    DeleteItem( AnItem ); 
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_DeleteItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DeleteItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_DeleteItem()
{
    Item*    AnItem;
    u32             CountBefore;
    Item*    FreeItemBefore;
    
    AnItem = MakeItem();

    CountBefore     = TheListOfFreeItems->ItemCount;
    FreeItemBefore  = TheListOfFreeItems->FirstItem;
    
    DeleteItem( AnItem ); 

        if( TheListOfFreeItems->ItemCount <= 0 )               
            return( 1 );
        if( TheListOfFreeItems->ItemCount != CountBefore + 1 ) 
            return( 2 );
        if( TheListOfFreeItems->FirstItem->NextItem != 
           FreeItemBefore ) 
            return( 3 );
            
    return( 0 );
}

/*------------------------------------------------------------
| Test_MakeItemForData
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MakeItemForData' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_MakeItemForData()
{
    u8            SomeData[] = "A is A.";
    Item*   AnItem;

    AnItem = MakeItemForData( SomeData );
    
        if( GetItemDataAddress( AnItem ) != SomeData ) return( 1 );

    DeleteItem( AnItem ); 
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_MakeList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'MakeList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_MakeList()
{
    List*    AList;
     
    AList = MakeList();
    
        if( TheListOfFreeLists->ItemCount < 0 )   return( 1 );
        if( IsListMarked( AList ) )               return( 2 );
        if( IsAnyItemsInList( AList ) )           return( 3 );
        
    // The following procedure is not validated at this 
    // point in the test sequence so it can't be used
    // to establish the validity of the procedure being
    // tested.  It's only to clean up after the test.
    DeleteList( AList ); 
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_AddToListItemCount
|-------------------------------------------------------------
|
| PURPOSE: To test the 'AddToListItemCount' macro.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_AddToListItemCount()
{
    PushTheListAndItem();
    
    TheList = TestList;
    
    TheItemCount = 0;
    
    AddToListItemCount( TheList, 1 );
        if( TheItemCount != (u32) 1 ) return( 1 );

    PullTheListAndItem();
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertItemLastInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertItemLastInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_InsertItemLastInList()
{
    Item*   FirstItem;
    Item*   SecondItem;
    u8*     SomeData;
    
    PushTheListAndItem();
    
    TheList = MakeList();

    SomeData = (u8*) "Existence is identity.";
    FirstItem = MakeItemForData( SomeData );
    InsertItemLastInList( TheList, FirstItem );
    
        if( TheItemCount != 1 )             return( 1 );
        if( TheFirstItem != FirstItem )     return( 2 );
        if( TheLastItem  != FirstItem )     return( 3 );

    SomeData = (u8*) "Consciousness is identification.";
    SecondItem = MakeItemForData( SomeData );
    InsertItemLastInList( TheList, SecondItem );
    
        if( TheItemCount != 2 )                         return( 4 );
        if( TheLastItem != SecondItem )                 return( 5 );
        if( TheFirstItem != FirstItem )                 return( 6 );
        if( GetNextItem( FirstItem ) != SecondItem )    return( 7 );
        if( GetPriorItem( SecondItem ) != FirstItem )   return( 8 );
        
    // The following procedure is not validated at this 
    // point in the test sequence so it can't be used
    // to establish the validity of the procedure being
    // tested.  It's only to clean up after the test.
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertDataLastInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertDataLastInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_InsertDataLastInList()
{
    Item*   FirstItem;
    Item*   SecondItem;
    u8*     SomeData;
    
    PushTheListAndItem();
    
    TheList = MakeList();

    SomeData = (u8*) "Existence is identity.";
    FirstItem = InsertDataLastInList( TheList, SomeData );
    
    TheItem = FirstItem;
        if( TheDataAddress != SomeData )     return( 1 );

    SomeData = (u8*) 
               "Consciousness is identification.";
    SecondItem = InsertDataLastInList( TheList, SomeData );
    
    TheItem = SecondItem;
        if( TheDataAddress != SomeData )     return( 2 );
        
    // The following procedure is not validated at this 
    // point in the test sequence so it can't be used
    // to establish the validity of the procedure being
    // tested.  It's only to clean up after the test.
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_ExtractTheItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ExtractTheItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_ExtractTheItem()
{
    Item*   FirstItem;
    Item*   SecondItem;
    Item*   ThirdItem;
    Item*   ExtractedItem;
    u8*     SomeData;
    
    PushTheListAndItem();
    
    TheList = MakeList();

    SomeData = (u8*) "aaa";
    FirstItem = InsertDataLastInList( TheList, SomeData );
    
    SomeData = (u8*) "bbb";
    SecondItem = InsertDataLastInList( TheList, SomeData );

    SomeData = (u8*) "ccc";
    ThirdItem = InsertDataLastInList( TheList, SomeData );
    
    // CASE: extracting last item.
    TheItem = ThirdItem;
    ExtractedItem = ExtractTheItem();
        if( ExtractedItem != ThirdItem )                return( 1 );
        if( TheItemCount != 2 )                         return( 2 );
        if( TheItem != SecondItem )                     return( 3 );
        if( GetNextItem( FirstItem ) != SecondItem )    return( 4 );
        if( GetPriorItem( SecondItem ) != FirstItem )   return( 5 );
        if( TheFirstItem != FirstItem )                 return( 6 );
        if( TheLastItem != SecondItem )                 return( 7 );
    
    // Put back the item.    
    InsertItemLastInList( TheList, ExtractedItem ); 
    
    // CASE: Extracting middle item.
    TheItem = SecondItem;
    ExtractedItem = ExtractTheItem();
    
        if( ExtractedItem != SecondItem )               return( 8 );
        if( TheItemCount != 2 )                         return( 9 );
        if( TheItem != FirstItem )                      return( 10 );
        if( GetNextItem( FirstItem ) != ThirdItem )     return( 11 );
        if( GetPriorItem( ThirdItem ) != FirstItem )    return( 12 );
        if( TheFirstItem != FirstItem )                 return( 13 );
        if( TheLastItem != ThirdItem )                  return( 14 );

    DeleteItem( ExtractedItem );
    
    // CASE: Extracting first item.
    TheItem = FirstItem;
    ExtractedItem = ExtractTheItem();
    
        if( ExtractedItem != FirstItem )                return( 15 );
        if( TheItemCount != 1 )                         return( 16 );
        if( TheItem != ThirdItem )                      return( 17 );
        if( !IsItemAlone( ThirdItem ) )                 return( 18 );
        if( TheFirstItem != ThirdItem )                 return( 19 );
        if( TheLastItem != ThirdItem )                  return( 20 );

    DeleteItem( ExtractedItem );

    // CASE: extracting lone item.
    ExtractedItem = ExtractTheItem();
    
        if( ExtractedItem != ThirdItem )                return( 21 );
        if( TheItemCount != 0 )                         return( 22 );
        if( TheItem != (Item*) 0 )                      return( 23 );
        if( TheFirstItem != (Item*) 0 )                 return( 24 );
        if( TheLastItem != (Item*) 0 )                  return( 25 );
    DeleteItem( ExtractedItem );

    // The following procedure is not validated at this 
    // point in the test sequence so it can't be used
    // to establish the validity of the procedure being
    // tested.  It's only to clean up after the test.
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_ExtractItemFromList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ExtractItemFromList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_ExtractItemFromList()
{
    Item*   FirstItem;
    Item*   SecondItem;
    Item*   ThirdItem;
    Item*   ExtractedItem;
    u8*     SomeData;
    
    PushTheListAndItem();
    
    TheList = MakeList();

    SomeData = (u8*) "aaa";
    FirstItem = InsertDataLastInList( TheList, SomeData );
    
    SomeData = (u8*) "bbb";
    SecondItem = InsertDataLastInList( TheList, SomeData );

    SomeData = (u8*) "ccc";
    ThirdItem = InsertDataLastInList( TheList, SomeData );
    
    // CASE: extracting last item.
    ToFirstItem();
    ExtractedItem = ExtractItemFromList( TheList, ThirdItem );
        if( ExtractedItem != ThirdItem )                return( 1 );
        if( TheItemCount != 2 )                         return( 2 );
        if( TheItem != FirstItem )                      return( 3 );
        if( GetNextItem( FirstItem ) != SecondItem )    return( 4 );
        if( GetPriorItem( SecondItem ) != FirstItem )   return( 5 );
        if( TheFirstItem != FirstItem )                 return( 6 );
        if( TheLastItem != SecondItem )                 return( 7 );
    
    // Put back the item.
    InsertItemLastInList( TheList, ExtractedItem ); 
    
    // CASE: extracting middle item.
    ToLastItem();
    ExtractedItem = ExtractItemFromList( TheList, SecondItem );
    
        if( ExtractedItem != SecondItem )               return( 8 );
        if( TheItemCount != 2 )                         return( 9 );
        if( TheItem != ThirdItem )                      return( 10 );
        if( GetNextItem( FirstItem ) != ThirdItem )     return( 11 );
        if( GetPriorItem( ThirdItem ) != FirstItem )    return( 12 );
        if( TheFirstItem != FirstItem )                 return( 13 );
        if( TheLastItem != ThirdItem )                  return( 14 );
    DeleteItem( ExtractedItem );

    // CASE: extracting first item.
    
    ExtractedItem = ExtractItemFromList( TheList, FirstItem );
    
        if( ExtractedItem != FirstItem )                return( 15 );
        if( TheItemCount != 1 )                         return( 16 );
        if( TheItem != ThirdItem )                      return( 17 );
        if( !IsItemAlone( ThirdItem ) )                 return( 18 );
        if( TheFirstItem != ThirdItem )                 return( 19 );
        if( TheLastItem != ThirdItem )                  return( 20 );
    DeleteItem( ExtractedItem );

    // CASE: extracting lone item.
    ExtractedItem = ExtractItemFromList( TheList, ThirdItem );
    
        if( ExtractedItem != ThirdItem )                return( 21 );
        if( TheItemCount != 0 )                         return( 22 );
        if( TheItem != ThirdItem )                      return( 23 );
        if( TheFirstItem != (Item*) 0 )                 return( 24 );
        if( TheLastItem != (Item*) 0 )                  return( 25 );
    DeleteItem( ExtractedItem );
   
    // The following procedure is not validated at this 
    // point in the test sequence so it can't be used
    // to establish the validity of the procedure being
    // tested.  It's only to clean up after the test.
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_DeleteList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DeleteList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.17.93
|
------------------------------------------------------------*/
u32  
Test_DeleteList()
{
    u32     ItemCountBefore;
    u32     ListCountBefore;
    Item*   FreeListBefore;
    
    PushTheListAndItem();
    
    TheList = MakeList();
    
    InsertDataLastInList( TheList, (u8*) "aaa" );
    InsertDataLastInList( TheList, (u8*) "bbb" );
    InsertDataLastInList( TheList, (u8*) "ccc" );
    
    ItemCountBefore = TheListOfFreeItems->ItemCount;
    ListCountBefore = TheListOfFreeLists->ItemCount;
    FreeListBefore  = TheListOfFreeLists->FirstItem;
    
    DeleteList( TheList );
    
        if( TheListOfFreeItems->ItemCount != 
            ItemCountBefore + (u32) 3 ) return( 1 );
        if( TheListOfFreeLists->ItemCount != 
            ListCountBefore + (u32) 1 ) return( 2 );
        if( TheListOfFreeLists->FirstItem != (Item*) TheList )                       
            return( 3 );
        if( TheListOfFreeLists->FirstItem->NextItem != 
            FreeListBefore )                           
            return( 4 );
           
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| MakeSampleListOfStaticStrings
|-------------------------------------------------------------
|
| PURPOSE: To make a list of strings allocated at compile time
| to be used for testing other procedures. 
|
| DESCRIPTION: Returns the list record address of a list
| which looks like this:
|
|        [LIST]--->[ITEM]--->"AAAA"
|                  [ITEM]--->"BBBB"
|                  [ITEM]--->"CCCC"
|
| EXAMPLE:  AList = MakeSampleListOfStaticStrings();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u8  AData[] = "AAAA";
u8  BData[] = "BBBB";
u8  CData[] = "CCCC";
List*
MakeSampleListOfStaticStrings()
{
    List*    AList;
    
    AList = MakeList();
    
    InsertDataLastInList( AList, AData );
    InsertDataLastInList( AList, BData );
    InsertDataLastInList( AList, CData );
    
    return( AList );
}

/*------------------------------------------------------------
| MakeSampleListOfDynamicStrings
|-------------------------------------------------------------
|
| PURPOSE: To make a list of dynamically allocated strings
| to be used for testing other procedures. 
|
| DESCRIPTION: Returns the list record address of a list
| which looks like this:
|
|        [LIST]--->[ITEM]--->"AAAA"
|                  [ITEM]--->"BBBB"
|                  [ITEM]--->"CCCC"
|
| EXAMPLE:  AList = MakeSampleListOfDynamicStrings();
|
| NOTE: 
|
| ASSUMES: 'AllocateMemoryAnyPoolHM' is valid.
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
List*
MakeSampleListOfDynamicStrings()
{
    List*   AList;
    u8*     SomeData;
    
    AList = MakeList();
    
    SomeData = (u8*)
               AllocateMemoryAnyPoolHM( 
                    TheListMemoryPool, 
                    5 );

    CopyString( (s8*)"AAAA", (s8*) SomeData );
    InsertDataLastInList( AList, SomeData );
    
    SomeData = (u8*) 
               AllocateMemoryAnyPoolHM( 
                    TheListMemoryPool, 
                    5 );

    CopyString( (s8*)"BBBB", (s8*) SomeData );
    InsertDataLastInList( AList, SomeData );
    
    SomeData = (u8*) 
               AllocateMemoryAnyPoolHM( 
                    TheListMemoryPool, 
                    5 );
                    
    CopyString( (s8*)"CCCC", (s8*) SomeData );
    InsertDataLastInList( AList, SomeData );
    
    return( AList );
}

/*------------------------------------------------------------
| Test_DeleteListOfDynamicData
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DeleteListOfDynamicData' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Memory allocation functions are valid.
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_DeleteListOfDynamicData()
{
    u32     ItemCountBefore;
    u32     ListCountBefore;
    List*   AList;
    
    AList = MakeSampleListOfDynamicStrings();
    
    ItemCountBefore = TheListOfFreeItems->ItemCount;
    ListCountBefore = TheListOfFreeLists->ItemCount;
    
    DeleteListOfDynamicData( AList );
        if( ItemCountBefore != 
            TheListOfFreeItems->ItemCount - (u32) 3 ) 
            return( 1 );
        if( ListCountBefore != 
            TheListOfFreeLists->ItemCount - (u32) 1 ) 
            return( 2 );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_FindFirstItemLinkedToData
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindFirstItemLinkedToData' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_FindFirstItemLinkedToData()
{
    u8*     FirstData;
    u8*     MiddleData;
    u8*     LastData;
    Item*   AnItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfDynamicStrings();
    
    FirstData  = GetItemDataAddress( TheFirstItem );
    MiddleData = GetItemDataAddress( GetNextItem( TheFirstItem ) );
    LastData   = GetItemDataAddress( TheLastItem );
    
    AnItem = FindFirstItemLinkedToData( TheList, FirstData );
        if( AnItem != TheFirstItem ) return( 1 );
        
    AnItem = FindFirstItemLinkedToData( TheList, MiddleData );
        if( AnItem != GetNextItem( TheFirstItem ) ) return( 2 );

    AnItem = FindFirstItemLinkedToData( TheList, LastData );
        if( AnItem != TheLastItem ) return( 3 );

    DeleteListOfDynamicData( TheList );
        
    return( 0 );
}

/*------------------------------------------------------------
| Test_DeleteFirstReferenceToData
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DeleteFirstReferenceToData' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_DeleteFirstReferenceToData()
{
    Item*    AnItem;
    Item*    FirstItem;
    Item*    MiddleItem;
    Item*    LastItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();
    
    FirstItem  = TheFirstItem;
    MiddleItem = GetNextItem( TheFirstItem );
    LastItem   = TheLastItem;
    
    AnItem = DeleteFirstReferenceToData( TheList, (u8*) 1 );
        if( AnItem ) return( 1 );
        if( TheItemCount != (u32) 3 ) return( 2 );

    AnItem = DeleteFirstReferenceToData( TheList, BData );
        if( AnItem != MiddleItem ) return( 3 );

    AnItem = DeleteFirstReferenceToData( TheList, AData );
        if( AnItem != FirstItem ) return( 4 );
        
    AnItem = DeleteFirstReferenceToData( TheList, CData );
        if( AnItem != LastItem ) return( 5 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_DeleteAllReferencesToData
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DeleteAllReferencesToData' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_DeleteAllReferencesToData()
{
    Item*    FirstItem;
    Item*    MiddleItem;
    Item*    LastItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();
    
    FirstItem  = TheFirstItem;
    MiddleItem = GetNextItem( TheFirstItem );
    LastItem   = TheLastItem;
    
    PutItemDataAddress( TheLastItem, BData );
    
    DeleteAllReferencesToData( TheList, (u8*) 1 );
        if( TheItemCount != (u32) 3 )       return( 1 );
    
    DeleteAllReferencesToData( TheList, BData );
        if( TheItemCount != (u32) 1 )       return( 2 );
        if( TheFirstItem != FirstItem )     return( 3 );
        if( TheLastItem != FirstItem )      return( 4 );

    DeleteAllReferencesToData( TheList, AData );
        if( TheItemCount != (u32) 0 )       return( 5 );
        if( TheFirstItem != (Item*) 0 )     return( 6 );
        if( TheLastItem != (Item*) 0 )      return( 7 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_IsTheDataMatching
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsTheDataMatching' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_IsTheDataMatching()
{
    u32   Result;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    ToFirstItem();
    Result = IsTheDataMatching( (u16) 0, (u16) 4, AData );
        if( Result == 0 ) return( 1 );

    ToNextItem();
    Result = IsTheDataMatching( (u16) 0, (u16) 4, BData );
        if( Result == 0 ) return( 2 );
        
    ToNextItem();
    Result = IsTheDataMatching( (u16) 0, (u16) 4, CData );
        if( Result == 0 ) return( 3 );

    Result = IsTheDataMatching( (u16) 0, (u16) 4, BData );
        if( Result != 0 ) return( 4 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_FindFirstMatchingItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindFirstMatchingItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_FindFirstMatchingItem()
{
    Item*   AnItem;
    u16     SearchKeyFieldOffset;
    u16     SearchKeyFieldWidth;
    u8*     SearchValue;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    SearchValue          = (u8*) "XXXX";
    SearchKeyFieldOffset = 0;
    SearchKeyFieldWidth  = 4;
    
    AnItem = FindFirstMatchingItem( TheList, 
                                    SearchKeyFieldOffset, 
                                    SearchKeyFieldWidth, 
                                    SearchValue );
    
        if( AnItem != (Item*) 0 ) return( 1 );
        
    SearchValue = (u8*) "AAAA";
    AnItem = FindFirstMatchingItem( TheList, 
                                    SearchKeyFieldOffset, 
                                    SearchKeyFieldWidth, 
                                    SearchValue );
    
        if( AnItem != TheFirstItem ) return( 2 );
        
    SearchValue = (u8*) "BBBB";
    AnItem = FindFirstMatchingItem( TheList, 
                                    SearchKeyFieldOffset, 
                                    SearchKeyFieldWidth, 
                                    SearchValue );
    
        if( AnItem != GetNextItem( TheFirstItem ) ) return( 3 );
        
    SearchValue = (u8*) "CCCC";
    AnItem = FindFirstMatchingItem( TheList, 
                                    SearchKeyFieldOffset, 
                                    SearchKeyFieldWidth, 
                                    SearchValue );
    
        if( AnItem != TheLastItem ) return( 3 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_FindNextMatchingItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindNextMatchingItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.18.93
|
------------------------------------------------------------*/
u32  
Test_FindNextMatchingItem()
{
    Item*   AnItem;
    u16     SearchKeyFieldOffset;
    u16     SearchKeyFieldWidth;
    u8*     SearchValue;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    SearchValue          = (u8*) "XXXX";
    SearchKeyFieldOffset = 0;
    SearchKeyFieldWidth  = 4;
    
    AnItem = FindNextMatchingItem( TheList, 
                                   TheFirstItem, 
                                   SearchKeyFieldOffset, 
                                   SearchKeyFieldWidth, 
                                   SearchValue );
    
        if( AnItem != (Item*) 0 ) return( 1 );
        
    SearchValue = (u8*) "AAAA";
    AnItem = FindNextMatchingItem( TheList, 
                                   TheFirstItem, 
                                   SearchKeyFieldOffset, 
                                   SearchKeyFieldWidth, 
                                   SearchValue );
    
        if( AnItem == TheFirstItem ) return( 2 );
        
    SearchValue = (u8*) "BBBB";
    AnItem = FindNextMatchingItem( TheList, 
                                   TheFirstItem, 
                                   SearchKeyFieldOffset, 
                                   SearchKeyFieldWidth, 
                                   SearchValue );
    
        if( AnItem != GetNextItem( TheFirstItem ) ) return( 3 );
        
    SearchValue = (u8*) "CCCC";
    AnItem = FindNextMatchingItem( TheList, 
                                   TheFirstItem, 
                                   SearchKeyFieldOffset, 
                                   SearchKeyFieldWidth, 
                                   SearchValue );
    
        if( AnItem != TheLastItem ) return( 3 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_FindFirstMarkedItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindFirstMarkedItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_FindFirstMarkedItem()
{
    Item*    AnItem;
    
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    AnItem = FindFirstMarkedItem( TheList );
    
        if( AnItem != (Item*) 0 ) return( 1 );

    MarkItem( TheLastItem );
    
    AnItem = FindFirstMarkedItem( TheList );
    
        if( AnItem != TheLastItem ) return( 2 );
        
    MarkItem( GetPriorItem( TheLastItem ) );
    
    AnItem = FindFirstMarkedItem( TheList );
    
        if( AnItem != GetPriorItem( TheLastItem ) ) return( 3 );

    MarkItem( TheFirstItem );
    
    AnItem = FindFirstMarkedItem( TheList );
    
        if( AnItem != TheFirstItem ) return( 4 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_FindFirstUnMarkedItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindFirstUnMarkedItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_FindFirstUnMarkedItem()
{
    Item*    AnItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    AnItem = FindFirstUnMarkedItem( TheList );
        if( AnItem != TheFirstItem ) return( 1 );

    MarkItem( TheFirstItem );
    AnItem = FindFirstUnMarkedItem( TheList );
        if( AnItem != GetNextItem( TheFirstItem ) ) return( 2 );
        
    MarkItem( GetNextItem( TheFirstItem ) );
    AnItem = FindFirstUnMarkedItem( TheList );
        if( AnItem != TheLastItem ) return( 3 );

    MarkItem( TheLastItem );
    AnItem = FindFirstUnMarkedItem( TheList );
    
        if( AnItem != (Item*) 0 ) return( 4 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_UnMarkAllItemsInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'UnMarkAllItemsInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_UnMarkAllItemsInList()
{
    Item*    AnItem;
    
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    MarkItem( TheFirstItem );
    MarkItem( GetNextItem( TheFirstItem ) );
    MarkItem( TheLastItem );
    
    UnMarkAllItemsInList( TheList );
    
    AnItem = FindFirstMarkedItem( TheList );
        if( AnItem != (Item*) 0 ) return( 1 );
        
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_FindIndexOfFirstMarkedItem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindIndexOfFirstMarkedItem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_FindIndexOfFirstMarkedItem()
{
    u32    ItemIndex;    
    
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    MarkItem( TheLastItem );
    
    ItemIndex = FindIndexOfFirstMarkedItem( TheList );
    
        if( ItemIndex != (u32) 2 ) return( 1 );
        
    MarkItem( GetPriorItem( TheLastItem ) );
    
    ItemIndex = FindIndexOfFirstMarkedItem( TheList );
    
        if( ItemIndex != (u32) 1 ) return( 2 );

    MarkItem( TheFirstItem );
    
    ItemIndex = FindIndexOfFirstMarkedItem( TheList );
    
        if( ItemIndex != (u32) 0 ) return( 3 );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_ExtractMarkedItems
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ExtractMarkedItems' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_ExtractMarkedItems()
{
    List*    AList;
    Item*    AnItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    AList = ExtractMarkedItems( TheList );
        if( IsAnyItemsInList( AList ) ) return( 1 );
    DeleteList( AList );
        
    MarkItem( TheLastItem );
    AnItem = TheLastItem;
    AList = ExtractMarkedItems( TheList );
        if( GetListItemCount( AList ) != (u32) 1 ) return( 2 );
        if( GetFirstItemOfList( AList ) != AnItem ) return( 3 );
        if( TheItemCount != (u32) 2 ) return( 4 );
    DeleteList( AList );
        
    MarkItem( TheLastItem );
    AnItem = TheLastItem;
    AList = ExtractMarkedItems( TheList );
        if( GetListItemCount( AList ) != (u32) 1 ) return( 5 );
        if( GetFirstItemOfList( AList ) != AnItem ) return( 6 );
        if( TheItemCount != (u32) 1 ) return( 7 );
    DeleteList( AList );
    
    MarkItem( TheLastItem );
    AnItem = TheLastItem;
    AList = ExtractMarkedItems( TheList );
        if( GetListItemCount( AList ) != (u32) 1 ) return( 8 );
        if( GetFirstItemOfList( AList ) != AnItem ) return( 9 );
        if( TheItemCount != (u32) 0 ) return( 10 );
    DeleteList( AList );

    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_DeleteMarkedItems
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DeleteMarkedItems' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_DeleteMarkedItems()
{
    Item*    AnItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    DeleteMarkedItems( TheList );
        if( TheItemCount != (u32) 3 ) return( 1 );
        
    MarkItem( TheLastItem );
    AnItem = TheLastItem;
    DeleteMarkedItems( TheList );
        if( TheItemCount != (u32) 2 ) return( 2 );
        if( TheLastItem == AnItem ) return( 3 );
        
    MarkItem( TheLastItem );
    AnItem = TheLastItem;
    DeleteMarkedItems( TheList );
        if( TheItemCount != (u32) 1 ) return( 4 );
        if( TheLastItem == AnItem ) return( 5 );

    MarkItem( TheLastItem );
    AnItem = TheLastItem;
    DeleteMarkedItems( TheList );
        if( TheItemCount != (u32) 0 ) return( 6 );
        if( TheLastItem == AnItem ) return( 7 );
        
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_IsAnyItemMarkedInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'IsAnyItemMarkedInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_IsAnyItemMarkedInList()
{
    u32     Result;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    Result = IsAnyItemMarkedInList( TheList );
        if( Result ) return( 1 );
    
    MarkItem( TheLastItem );

    Result = IsAnyItemMarkedInList( TheList );
        if( !Result ) return( 1 );
    
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_DuplicateList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DuplicateList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_DuplicateList()
{
    List*   AList;
    List*   BList;
    u8*     FirstDataA;
    u8*     FirstDataB;
    u8*     SecondDataA;
    u8*     SecondDataB;
    u8*     ThirdDataA;
    u8*     ThirdDataB;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();

    BList = DuplicateList( AList );
    
    TheList = AList;
    FirstDataA  = GetItemDataAddress( TheFirstItem );
    SecondDataA = GetItemDataAddress( GetNextItem( TheFirstItem ) );
    ThirdDataA  = GetItemDataAddress( TheLastItem );
    
    TheList = BList;
    FirstDataB  = GetItemDataAddress( TheFirstItem );
    SecondDataB = GetItemDataAddress( GetNextItem( TheFirstItem ) );
    ThirdDataB  = GetItemDataAddress( TheLastItem );
    
        if( FirstDataA  != FirstDataB )  return( 1 );
        if( SecondDataA != SecondDataB ) return( 2 );
        if( ThirdDataA  != ThirdDataB )  return( 3 );
        if( GetListItemCount( AList ) != GetListItemCount( BList ) ) 
                                         return( 4 );
    
    DeleteList( AList );
    DeleteList( BList );
        
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_DuplicateMarkedItems
|-------------------------------------------------------------
|
| PURPOSE: To test the 'DuplicateMarkedItems' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_DuplicateMarkedItems()
{
    List*   AList;
    List*   BList;
    u8*     FirstDataA;
    u8*     FirstDataB;
    u8*     LastDataA;
    u8*     LastDataB;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();

    TheList = AList;
    MarkItem( TheFirstItem );
    MarkItem( TheLastItem );
    
    BList = DuplicateMarkedItems( AList );
    
    FirstDataA  = GetItemDataAddress( TheFirstItem );
    LastDataA   = GetItemDataAddress( TheLastItem );
    
    TheList = BList;
    FirstDataB  = GetItemDataAddress( TheFirstItem );
    LastDataB   = GetItemDataAddress( TheLastItem );
    
        if( FirstDataA != FirstDataB ) return( 1 );
        if( LastDataA  != LastDataB )  return( 2 );
        if( GetListItemCount( BList ) != (u32) 2 ) return( 3 );
    
    DeleteList( AList );
    DeleteList( BList );
        
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_ExtractFirstItemFromList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ExtractFirstItemFromList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_ExtractFirstItemFromList()
{
    Item*    AnItem;
    Item*    FirstItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    FirstItem = TheFirstItem;
    
    AnItem = ExtractFirstItemFromList( TheList );
        if( AnItem != FirstItem ) return( 1 );
    DeleteItem( AnItem );
    
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_ExtractLastItemFromList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ExtractLastItemFromList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_ExtractLastItemFromList()
{
    Item*    AnItem;
    Item*    LastItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    LastItem = TheLastItem;
    
    AnItem = ExtractLastItemFromList( TheList );
        if( AnItem != LastItem ) return( 1 );
    DeleteItem( AnItem );
        
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_ReverseList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ReverseList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_ReverseList()
{
    Item*    FirstItem;
    Item*    MiddleItem;
    Item*    LastItem;
    
    PushTheListAndItem();
    
    TheList = MakeSampleListOfStaticStrings();

    FirstItem = TheFirstItem;
    MiddleItem = GetNextItem( TheFirstItem );
    LastItem = TheLastItem;
    
    ReverseList( TheList );
    
        if( TheFirstItem != LastItem ) return( 1 );
        if( TheLastItem != FirstItem ) return( 2 );
        if( GetNextItem( TheFirstItem ) != MiddleItem ) return( 3 );
        if( TheItemCount != (u32) 3 ) return( 4 );
    
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_JoinLists
|-------------------------------------------------------------
|
| PURPOSE: To test the 'JoinLists' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_JoinLists()
{
    Item*    FirstItem;
    Item*    LastItem;
    List*    AList;
    List*    BList;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();
    BList = DuplicateList( AList );
    
    FirstItem = GetFirstItemOfList( AList );
    LastItem  = GetLastItemOfList( BList );
    
    JoinLists( AList, BList );
    
    TheList = AList;
        if( TheFirstItem != FirstItem ) return( 1 );
        if( TheLastItem != LastItem )   return( 2 );
        if( TheItemCount != (u32) 6 )  return( 3 );
        if( IsAnyItemsInList( BList ) )   return( 4 );
        
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_ExchangeItems
|-------------------------------------------------------------
|
| PURPOSE: To test the 'ExchangeItems' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_ExchangeItems()
{
    List*    AList;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();
    InsertDataLastInList( AList, (u8*)"DDDD" );
    // Now 'AList' has four items.
    
    TheList = AList;
    
    // Exchange the first two items, 'AAAA' & 'BBBB'.
    ExchangeItems( AList, TheFirstItem, GetNextItem( TheFirstItem ) );
    
    ToFirstItem();
        if( TheDataAddress != BData ) return( 1 );
    
    ToNextItem();
        if( TheDataAddress != AData ) return( 2 );
        
    // Exchange what are now the second two items, 
    // 'AAAA' & 'CCCC'.
    ExchangeItems( AList, TheItem, GetNextItem( TheItem ) );
    
    ToFirstItem();
    ToNextItem();
        if( TheDataAddress != CData ) return( 3 );
    ToNextItem();
        if( TheDataAddress != AData ) return( 4 );
    
    // Exchange what are now the last two items, 
    // 'AAAA' & 'DDDD'.
    ExchangeItems( AList, TheItem, TheLastItem );
    ToLastItem();
        if( TheDataAddress != AData ) return( 5 );
    ToPriorItem();
        if( TheDataAddress[0] != ( u8 ) 'D' ) return( 6 );
    
    DeleteList( TheList );
    
    PullTheListAndItem();
    
    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertItemFirstInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertItemFirstInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_InsertItemFirstInList()
{
    Item*   FirstItem;
    Item*   SecondItem;
    u8*     SomeData;
    
    PushTheListAndItem();
    
    TheList = MakeList();

    SomeData = (u8*) "Existence is identity.";
    FirstItem = MakeItemForData( SomeData );
    InsertItemFirstInList( TheList, FirstItem );
    
        if( TheItemCount != 1 )             return( 1 );
        if( TheFirstItem != FirstItem )     return( 2 );
        if( TheLastItem  != FirstItem )     return( 3 );

    SomeData = (u8*) "Consciousness is identification.";
    SecondItem = MakeItemForData( SomeData );
    InsertItemFirstInList( TheList, SecondItem );
    
        if( TheItemCount != 2 )                         return( 4 );
        if( TheLastItem != FirstItem )                  return( 5 );
        if( TheFirstItem != SecondItem )                return( 6 );
        if( GetNextItem( SecondItem ) != FirstItem )    return( 7 );
        if( GetPriorItem( FirstItem ) != SecondItem )   return( 8 );
        
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertItemAfterItemInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertItemAfterItemInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_InsertItemAfterItemInList()
{
    u8      DData[]="DDDD";
    List*   AList;
    Item*   AnItem;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();
    TheList = AList;
    AnItem = MakeItemForData( DData );
    InsertItemAfterItemInList( AList, TheFirstItem, AnItem );
    // Now 'AList' has four items:
    // {'AAAA', 'DDDD', 'BBBB', 'CCCC'}

        if( TheItemCount != 4 )    return( 1 );

    ToFirstItem();
    ToNextItem();
        if( TheItem != AnItem ) return( 2 );
        
    ToPriorItem();
        if( TheItem != TheFirstItem ) return( 3 );
        
    AnItem = MakeItemForData( DData );
    InsertItemAfterItemInList( AList, TheLastItem, AnItem );
    // Now 'AList' has five items:
    // {'AAAA', 'DDDD', 'BBBB', 'CCCC', 'DDDD'}
    
    ToLastItem();
        if( TheItem != AnItem ) return( 4 );
    ToPriorItem();
        if( TheDataAddress != CData ) return( 5 );
    ToNextItem();
        if( TheItem != AnItem ) return( 6 );

    AnItem = MakeItemForData( DData );
    InsertItemAfterItemInList( AList, (Item*)0, AnItem );
    // Now 'AList' has six items:
    // {'DDDD', 'AAAA', 'DDDD', 'BBBB', 'CCCC', 'DDDD'}
  
    ToFirstItem();
        if( TheItem != AnItem ) return( 7 );
    ToNextItem();
        if( TheDataAddress != AData ) return( 8 );
    ToPriorItem();
        if( TheItem != AnItem ) return( 9 );

    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertItemBeforeItemInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertItemBeforeItemInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_InsertItemBeforeItemInList()
{
    u8    DData[]="DDDD";
    Item* AnItem;
    List* AList;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();
    TheList = AList;
    AnItem = MakeItemForData( DData );
    InsertItemBeforeItemInList( AList, TheLastItem, AnItem );
    // Now 'AList' has four items:
    // {'AAAA', 'BBBB', 'DDDD', 'CCCC'}

        if( TheItemCount != 4 )    return( 1 );

    ToLastItem();
    ToPriorItem();
        if( TheItem != AnItem ) return( 2 );
        
    ToNextItem();
        if( TheItem != TheLastItem ) return( 3 );
        
    AnItem = MakeItemForData( DData );
    InsertItemBeforeItemInList( AList, TheFirstItem, AnItem );
    // Now 'AList' has five items:
    // {'DDDD', 'AAAA', 'BBBB', 'DDDD', 'CCCC'}
    
    ToFirstItem();
        if( TheItem != AnItem ) return( 4 );
    ToNextItem();
        if( TheDataAddress != AData ) return( 5 );
    ToPriorItem();
        if( TheItem != AnItem ) return( 6 );
    
    AnItem = MakeItemForData( DData );
    InsertItemBeforeItemInList( AList, (Item*) 0, AnItem );
    // Now 'AList' has six items:
    // {'DDDD', 'AAAA', 'BBBB', 'DDDD', 'CCCC', 'DDDD'}
    
    ToLastItem();
        if( TheItem != AnItem ) return( 7 );
    ToPriorItem();
        if( TheDataAddress != CData ) return( 8 );
    ToNextItem();
        if( TheItem != AnItem ) return( 9 );
    
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertDataFirstInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertDataFirstInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_InsertDataFirstInList()
{
    u8*    SomeData;
    
    PushTheListAndItem();
    
    TheList = MakeList();

    SomeData = (u8*) "Existence is identity.";
    InsertDataFirstInList( TheList, SomeData );
    
    ToFirstItem();
        if( TheDataAddress != SomeData ) return( 1 );
                
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertDataAfterItemInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertDataAfterItemInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_InsertDataAfterItemInList()
{
    u8             DData[]="DDDD";
    List*    AList;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();
    TheList = AList;
    
    InsertDataAfterItemInList( AList, TheFirstItem, DData );
    // Now 'AList' has four items:
    // {'AAAA', 'DDDD', 'BBBB', 'CCCC'}

    ToFirstItem();
    ToNextItem();
        if( TheDataAddress != DData ) return( 1 );
        
    InsertDataAfterItemInList( AList, TheLastItem, DData );
    // Now 'AList' has five items:
    // {'AAAA', 'DDDD', 'BBBB', 'CCCC', 'DDDD'}
    
    ToLastItem();
        if( TheDataAddress != DData ) return( 2 );

    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertDataBeforeItemInList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertDataBeforeItemInList' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.19.93
|
------------------------------------------------------------*/
u32  
Test_InsertDataBeforeItemInList()
{
    u8      DData[]="DDDD";
    List*   AList;
    
    PushTheListAndItem();
    
    AList = MakeSampleListOfStaticStrings();
    TheList = AList;
    
    InsertDataBeforeItemInList( AList, TheLastItem, DData );
    // Now 'AList' has four items:
    // {'AAAA', 'BBBB', 'DDDD', 'CCCC'}

    ToLastItem();
    ToPriorItem();
        if( TheDataAddress != DData ) return( 1 );
        
    InsertDataBeforeItemInList( AList, TheFirstItem, DData );
    // Now 'AList' has five items:
    // {'DDDD', 'AAAA', 'BBBB', 'DDDD', 'CCCC'}
    
    ToFirstItem();
        if( TheDataAddress != DData ) return( 2 );
    
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_FindPlaceInOrderedList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindPlaceInOrderedList' 
|          procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.21.93
|
------------------------------------------------------------*/
u32  
Test_FindPlaceInOrderedList()
{
    List*    AList;
    Item*    AnItem;
    
    PushTheListAndItem();
    
    AList  = MakeSampleListOfStaticStrings();

    TheList = AList;

    AnItem = FindPlaceInOrderedList( AList, 
                              (u8*) "A", 
                              ( CompareProc ) CompareStrings );
                              
    ToFirstItem();
        if( AnItem != TheItem ) return( 1 );

    AnItem = FindPlaceInOrderedList( AList, 
                              (u8*) "B", 
                              ( CompareProc ) CompareStrings );
                              
    ToNextItem();
        if( AnItem != TheItem ) return( 2 );

    AnItem = FindPlaceInOrderedList( AList, 
                              (u8*) "C", 
                              ( CompareProc ) CompareStrings );
                              
    ToNextItem();
        if( AnItem  != TheItem ) return( 3 );
        
    AnItem = FindPlaceInOrderedList( AList, 
                              (u8*) "D", 
                              ( CompareProc ) CompareStrings );
                              
        if( AnItem != (Item*) 0 ) return( 4 );

    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}

/*------------------------------------------------------------
| Test_InsertDataInOrderedList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'InsertDataInOrderedList' 
|          procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.21.93
|
------------------------------------------------------------*/
u32  
Test_InsertDataInOrderedList()
{
    List*    AList;
    Item*    AnItem;
    
    
    PushTheListAndItem();
    
    AList  = MakeSampleListOfStaticStrings();
    
    // This is what the list looks like: 
    // { 'AAAA', 'BBBB', 'CCCC' }

    TheList = AList;

    AnItem = InsertDataInOrderedList( AList, 
                              (u8*) "A", 
                              ( CompareProc ) CompareStrings );
    // { 'A', 'AAAA', 'BBBB', 'CCCC' }
                              
    ToFirstItem();
        if( AnItem != TheItem ) return( 1 );

    AnItem = InsertDataInOrderedList( AList, 
                              (u8*) "B", 
                              ( CompareProc ) CompareStrings );
                              
    // { 'A', 'AAAA', 'B', 'BBBB', 'CCCC' }
    ToFirstItem();
    ToNextItem();
    ToNextItem();
        if( AnItem != TheItem ) return( 2 );

    AnItem = InsertDataInOrderedList( AList, 
                              (u8*) "C", 
                              ( CompareProc ) CompareStrings );

    // { 'A', 'AAAA', 'B', 'BBBB', 'C', 'CCCC' }
                              
    ToFirstItem();
    ToNextItem();
    ToNextItem();
    ToNextItem();
    ToNextItem();
        if( AnItem  != TheItem ) return( 3 );
        
    AnItem = InsertDataInOrderedList( AList, 
                              (u8*) "D", 
                              ( CompareProc ) CompareStrings );
    // { 'A', 'AAAA', 'B', 'BBBB', 'C', 'CCCC', 'D'  }
                              
    ToLastItem();
        if( AnItem != AnItem ) return( 4 );

    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}



/*------------------------------------------------------------
| Test_SortShortList
|-------------------------------------------------------------
|
| PURPOSE: To test the 'SortShortList' 
|          procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.21.93
|
------------------------------------------------------------*/
u32  
Test_SortShortList()
{
    List* AList;
    
    PushTheListAndItem();
    
    AList  = MakeSampleListOfStaticStrings();

    ReverseList( AList );
    
    SortShortList( AList, ( CompareProc ) CompareStrings );

    TheList = AList;
    
    ToFirstItem();
        if( TheDataAddress != AData ) return( 1 );
    ToNextItem();
        if( TheDataAddress != BData ) return( 2 );
    ToNextItem();
        if( TheDataAddress != CData ) return( 3 );

    ToLastItem();
        if( TheDataAddress != CData ) return( 4 );
    ToPriorItem();
        if( TheDataAddress != BData ) return( 5 );
    ToPriorItem();
        if( TheDataAddress != AData ) return( 6 );
    
    DeleteList( TheList ); 

    PullTheListAndItem();

    return( 0 );
}






/*------------------------------------------------------------
| Test_CleanUpTheListSystem
|-------------------------------------------------------------
|
| PURPOSE: To test the 'CleanUpTheListSystem' procedure.
|
| DESCRIPTION: Returns non-zero if error detected.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: State after prior tests.
|
| HISTORY: 11.22.93
|
------------------------------------------------------------*/
u32  
Test_CleanUpTheListSystem()
{
    CleanUpTheListSystem();
    
        if( TheListSystemIsSetUp )      return( 1 );
        if( TheListStackIndex != 0 )    return( 2 );
        if( SegmentChain != 0 )         return( 3 );
        if( TheList != 0 )              return( 4 );
        if( TheItem != 0 )              return( 5 );
        if( TheListOfFreeItems != 0 )   return( 6 );
        if( TheListOfFreeLists != 0 )   return( 7 );
        
    return( 0 );
}

/*------------------------------------------------------------
| TLListDemonstration
|-------------------------------------------------------------
|
| PURPOSE: To demonstrate some 'TLList' functions.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.22.93
|
------------------------------------------------------------*/
void
TLListDemonstration()
{
    List* AList;
    Item* AnItem;
    u8* SomeData;
    u8* SearchKey;
    u16          KeyFieldOffset;
    u16          KeyFieldWidth;

    // These are the data elements to be itemized.
    u8    John[]   = "John";
    u8    Dagny[]  = "Dagny";
    u8    Hank[]   = "Hank";
    u8    Frisco[] = "Francisco";
    u8    Hugh[]   = "Hugh";

    printt( "Set up the list system:\n" );
    SetUpTheListSystem(0);

    printt( "\nCreate a list of five names:\n" );

     AList = MakeList();
     
    InsertDataLastInList( AList, John );
    InsertDataLastInList( AList, Dagny );
    InsertDataLastInList( AList, Hank  );
    InsertDataLastInList( AList, Frisco );
    InsertDataLastInList( AList, Hugh  );

    OutputListOfStrings( AList );
 
    printt( "Sort the list alphabetically:\n" );
    SortListAlphabetically( AList );
    OutputListOfStrings( AList );
 
    printt( "Reverse the list:\n" );
    ReverseList( AList );
    OutputListOfStrings( AList );
 
    printt( "Find and print the name starting with 'J':\n" );
    
    SearchKey = (u8*) "J";
    KeyFieldOffset = 0;
    KeyFieldWidth = 1;
    
    AnItem = FindFirstMatchingItem( AList, 
                                   KeyFieldOffset, 
                                   KeyFieldWidth, 
                                   SearchKey );
    
    SomeData = GetItemDataAddress( AnItem );
    
    printt( "%s\n\n", (s8*) SomeData );

    DeleteList( AList ); 

    printt( "Clean up the list system:\n" );
    CleanUpTheListSystem();
    OutputListSystemStatus();
}

/*------------------------------------------------------------
| ListTest_main
|-------------------------------------------------------------
|
| PURPOSE: To test list functions.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Room exists for the log file on disk.
|
| HISTORY: 01.09.88
|          11.08.93 extended
|
------------------------------------------------------------*/
u32
//ListTest_main()
main()
{
    u32 OverallResult;
    
    // Open the test log file.
    TheLogFile = fopen( "testlog.txt", "w" );
    
    // Report the beginning of all the API tests.
    printt( "===============\n" );
    printt( "BEGIN ALL TESTS\n" );
    printt( "===============\n" );
    
    // Start with the overall result code set to zero.
    OverallResult = 0;
 
    // Run a test sequence and accumulate the result.
    OverallResult |= 
        RunTestSequence( 
            ListTestSequence,
            "ListTestSequence" );

// Put other test sequences here.
//          
//    OverallResult |= 
//      RunTestSequence( 
//          "AnotherTestSequence", 
//          AnotherTestSequence );

    printt( "=======================================\n" );
    printt( "END ALL TESTS\n" );
    printt( "=======================================\n" );
    
    // If any of the test sequences resulted in an error.
    if( OverallResult )
    {
        printt( "SUMMARY: At least one test failed.\n" );
    }
    else
    {
        printt( "SUMMARY: All tests passed OK.\n" );
    }
    
    printt( "=======================================\n" );
    
    fclose( TheLogFile );
    
    // Return the overall result.
    return( OverallResult );
}

