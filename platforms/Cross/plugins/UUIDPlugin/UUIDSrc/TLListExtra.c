/*------------------------------------------------------------
| TLListExtra.c
|-------------------------------------------------------------
|
| PURPOSE: To provide less commonly used linked list 
|          functions.
|
| DESCRIPTION:  
| 
| HISTORY: 01.27.00 Split this file off from 'TLList.c'.
------------------------------------------------------------*/
#if 0 // WORK IN PROGRESS

#include "TLTarget.h" // Include this first.

#include <ctype.h>
#include <stdio.h>
     
#include "TLTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"
#include "TLRandom.h"
#include "TLList.h"
#include "TLListExtra.h"


u32 DirectAccessTableThreshold = 20;
            // Quantity of items, above which a 
            // direct access table is used for sorting. 

/*------------------------------------------------------------
| AppendDataToBufferList
|-------------------------------------------------------------
|
| PURPOSE: To add data bytes to a list of dynamic buffers.
|
| DESCRIPTION: If there is room in the last buffer of the
| list, the data bytes are copied there.  Any excess bytes
| are copied to newly created buffers of the size given
| in 'BytesPerBuffer'.
| 
| The parameter 'ABufferList' refers to the address of the
| address of a list record.  If the list is empty the value
| at 'ABufferList' is zero.
|
| Use 'DeleteListOfDynamicData' to free a buffer list.
|
| EXAMPLE:  
|            
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 12.10.96
------------------------------------------------------------*/
void
AppendDataToBufferList( List** ABufferList,
                        u32    BytesPerBuffer,
                        u8*    Data,
                        u32    DataByteCount )
{
    u8*     ABuffer;
    Item*   ABufferItem;
    u8*     AfterDataInBuffer;
    u8*     AfterBuffer;
    u32     BytesAvailableInLastBuffer;
    u32     BytesToCopy;
    
    // If the buffer list reference is 0 then the list
    // record itself needs to be created.
    if( *ABufferList == 0 )
    {
        // Make the list.
        *ABufferList = MakeList();
    }
    
    // Refer to the list of buffers.
    ReferToList( *ABufferList );
    
    // If the list of buffers is empty, add an empty buffer.
    if( TheItemCount == 0 )
    {
AppendNewBuffer:

        // Allocate a new data buffer.
        ABuffer = (u8*) malloc( BytesPerBuffer );
        
        // Insert the buffer in the list.  This sets the
        // buffer and data address to the same value.
        ABufferItem = InsertDataLastInList( TheList, ABuffer );

        // Set the buffer size and data size.
        ABufferItem->SizeOfBuffer = BytesPerBuffer;
        ABufferItem->SizeOfData   = 0; // It's empty.
    }
    
    // While there are bytes to be appended to buffers. 
    while( DataByteCount )
    {
        // Refer to the last buffer in the list.
        ToLastItem();
    
        AfterDataInBuffer = TheDataAddress + TheDataSize;
        AfterBuffer       = TheBufferAddress + TheBufferSize;
        
        BytesAvailableInLastBuffer = 
            (u32) ( AfterBuffer - AfterDataInBuffer );
        
        // If there is some room, copy some bytes.                           
        if( BytesAvailableInLastBuffer > 0 )
        {
            // Copy as much of the remaining bytes as 
            // possible into the space available.
            BytesToCopy = min( BytesAvailableInLastBuffer,
                               DataByteCount );
            
            CopyBytes( Data, AfterDataInBuffer, BytesToCopy );

            // Advance to the next source byte.
            Data += BytesToCopy;
            
            // Account for the bytes copied.
            TheDataSize   += BytesToCopy;
            DataByteCount -= BytesToCopy;
            
        }
        else // Append a new buffer to the list.
        {
            goto AppendNewBuffer;
        }
    }
    
    RevertToList();
}

/*------------------------------------------------------------
| AppendItems
|-------------------------------------------------------------
|
| PURPOSE: To move items from one list to the end of another.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|            
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 02.04.97 factored out of 'JoinLists'.
------------------------------------------------------------*/
void
AppendItems( List* To, List* From )
{
    // If 'From' list is empty, just return.
    if( From->ItemCount == 0 )
    {
        return;
    }
    
    // If the 'To' list has existing items.
    if( To->ItemCount )
    {
        // Link the next link of the 'To' list
        // to the beginning of the 'From' list.
        To->LastItem->NextItem = From->FirstItem;
        
        // Link the prior link of the 'From' list
        // to the end of the 'To' list.
        From->FirstItem->PriorItem = To->LastItem;
    }
    else // 'To' list is empty. 
    {
        // Set the first item pointer in the
        // destination list from the source list
        To->FirstItem = From->FirstItem;
    }
    
    // Set the last item pointer in the
    // destination list from the source list
    To->LastItem = From->LastItem;
    
    // Sum the counts of the two lists.
    To->ItemCount += From->ItemCount;
    
    // OR the marks of the two lists.
    To->ListMark |= From->ListMark;
         
    // Clear the list count & pointers for the
    // 'From' list.
    MarkListAsEmpty( From );
}

/*------------------------------------------------------------
| BuildDirectAccessTableForList
|-------------------------------------------------------------
|
| PURPOSE: To build a structure which permits direct access to 
|          the items of a list.
|
| DESCRIPTION: Normally a linked list is accessed sequentially 
| but there are some situations where direct access of items 
| is needed. This procedure builds an index which can satisfy 
| this requirement. 
|
| A Direct Access Table is just an array of item record 
| addresses.
|
| Direct access tables are dynamically allocated using
| 'malloc()'.
|
| The overall size of a direct access table depends on the
| number of items in the list that it is created from:
| 
|      table size = ItemCount X sizeof(Item*)
|
| Use the 'free()' procedure to discard useless
| direct access tables created by this procedure.
| 
| See 'ReorderListToMatchDirectAccessTable()' to make the
| order of items in a list conform to the order in a
| cooresponding direct access table.
|
| EXAMPLE:  
|           MyTable = BuildDirectAccessTableForList(MyList);
| NOTE:  
|
| ASSUMES: Item pool has been set up.
|          Sufficient memory exists to hold the table.
|          At least one item exists in the given list.
|
| HISTORY: 09.12.89
|          10.03.91 Revised for Focus.
|                   Name changed from 
|                   BuildARandomAccessTableForAList
|          12.22.91 pointers to data rather than pointers
|                   to items
|          02.08.93 name changed from 
|                   BuildALinearAccessTableForAList
|          10.28.93 changed back to point to item records 
|                   because mark field is part of data.
|          11.21.93 name changed from 
|                   BuildLinearAccessTableForList
------------------------------------------------------------*/
Item**
BuildDirectAccessTableForList(List* AList)
{
    Item**    Table;
    u32    Entry;
    u32    TableSize;

    ReferToList( AList ); 
    
    TableSize = ((u32) sizeof(Item*)) * TheItemCount;
    
    Table = (Item**) malloc(TableSize);

    for( Entry = 0; Entry < TheItemCount; Entry++ )
    {
        Table[Entry] = TheItem;
        ToNextItem();
    }

    RevertToList();

    return(Table);
}

/*------------------------------------------------------------
| CleanUpTheListSystem
|-------------------------------------------------------------
|
| PURPOSE: To reverse the action of SetUpTheListSystem.
|
| DESCRIPTION: 
|
| EXAMPLE:  CleanUpTheListSystem();
|
| NOTE: 
|
| ASSUMES: Any dynamic data attached to items has already
|          been deallocated.
|
| HISTORY: 03.10.89
|          07.10.89 upgraded to new structure
|          07.28.89 added set up flag
|          11.01.93 cleared the current list and item
|          01.21.94 added deallocation of segment chain
|          01.07.97 revised for new list structure.
|          01.12.97 cleared the items and lists in use counts.
|          02.04.97 freed the list of free lists.
------------------------------------------------------------*/
void
CleanUpTheListSystem()
{
    u32*    NextSegment;
    
    if(!TheListSystemIsSetUp) return;
    
    TheListSystemIsSetUp--;
    if( !TheListSystemIsSetUp )
    {
        while( SegmentChain )
        {
            NextSegment = (u32*) SegmentChain[0];
            free((u8*) SegmentChain);
            SegmentChain = NextSegment;
        }
        
        if( TheListOfFreeLists )
        {
            free( TheListOfFreeLists );
            TheListOfFreeLists = 0;
        }
        
        TheListOfFreeItems = 0;
        TheList = 0;
        TheItem = 0;
        TheListStackIndex = 0;
        CountOfListsInUse = 0;
        CountOfItemsInUse = 0;
    }
}
        
/*------------------------------------------------------------
| CompactList
|-------------------------------------------------------------
|
| PURPOSE: To make all of the items in a list contiguous in
|          memory if not already that way.
|
| DESCRIPTION: Speeds list operations for CPUs with data 
| caches.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Item records are not referenced by any other 
|          structure than the list. 
|           
| HISTORY: 06.15.97  
------------------------------------------------------------*/
#ifdef DEFER
void
CompactList( List* L )
{
    List* B;
    Item* BItem;
    s32   Count;
    
    // Get the item count.
    Count = L->ItemCount;
    
    // If already compact or empty, just return.
    if( L->IsCompact || ( Count == 0 ) )
    {
        return;
    }
    
    // Allocate a new list of compact items.
    B = MakeCompactList( Count );
    
    // Refer to the first item in the compact list.
    BItem = B->FirstItem;
    
    // Transfer the item data to the new list.
    ReferToList( L );
    
    while( TheItem )
    {
        BItem->BufferAddress = TheItem->BufferAddress;
    
        BItem->SizeOfBuffer  = TheItem->SizeOfBuffer;
    
        BItem->DataAddress   = TheItem->DataAddress;
            
        BItem->SizeOfData    = TheItem->SizeOfData; 

        BItem->TypeOfData    = TheItem->TypeOfData;
    
        BItem->ItemMark      = TheItem->ItemMark; 
        
        BItem++;
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Discard the old item records.
    EmptyList( L );
    
    // Transfer the new items to the list and discard the
    // working list.
    JoinLists( L, B );
    
    // Mark the list as compact.
    L->IsCompact = True;
}
#endif

/*------------------------------------------------------------
| DuplicateListCompact
|-------------------------------------------------------------
|
| PURPOSE: To duplicate a list to make a list with contiguous
|          items.  
|
| DESCRIPTION: Creates a new list of item records pointing to 
| the same data as the given list.
|
| EXAMPLE:  DupList = DuplicateListCompact(AList);
|
| NOTE: This tends to fragment memory: use with care.
|
| ASSUMES: 
|
| HISTORY: 06.17.97 from 'DuplicateList'.
------------------------------------------------------------*/
List*
DuplicateListCompact( List* AList )
{
    List* L;
    Item* A;

    L = MakeCompactList( AList->ItemCount );
    
    if( AList->ItemCount )
    {        
        ReferToList( AList ); 
        A = L->FirstItem;
        
        while( TheItem )
        {
            A->BufferAddress = TheItem->BufferAddress;
    
            A->SizeOfBuffer  = TheItem->SizeOfBuffer;
    
            A->DataAddress   = TheItem->DataAddress;
            
            A->SizeOfData    = TheItem->SizeOfData; 

            A->TypeOfData    = TheItem->TypeOfData;
    
            A->ItemMark      = TheItem->ItemMark; 
            
            A = A->NextItem;
             
            ToNextItem();
        }
    
        RevertToList();
    }

    return( L );
}

/*------------------------------------------------------------
| DuplicateMarkedItems
|-------------------------------------------------------------
|
| PURPOSE: To duplicate the marked items of a list.  
|
| DESCRIPTION: Creates a new list of item records pointing to 
| the same data as the marked items in the given list.
|
| This is useful when it is desirable to access the same data 
| but in different orders or select different sets of data
| from the list using the marking bits in the mark field.
|
| EXAMPLE:  DupList = DuplicateMarkedItems(AList);
|
| NOTE: Does NOT duplicate the data associated with the item
|       records.
|
| ASSUMES: 
|
| HISTORY: 11.04.93
|          11.19.93 simplified logic
|          01.20.94 converted to use 'DuplicateItem'
------------------------------------------------------------*/
List*
DuplicateMarkedItems(List* AList)
{
    List* TheDuplicateList;
    Item* NewItem;

    TheDuplicateList = MakeList();

    if(!IsAnyItemsInList(AList)) return(TheDuplicateList);
    
    ReferToList( AList ); 
        
    while(TheItem)
    {
        if(IsItemMarked(TheItem))
        {
            NewItem = DuplicateItem(TheItem);
            InsertItemLastInList(TheDuplicateList,NewItem);
        }
        ToNextItem();
    }
    
    RevertToList();

    return(TheDuplicateList);
}

/*------------------------------------------------------------
| EmptyList
|-------------------------------------------------------------
|
| PURPOSE: To delete items in a list but keep the list itself.
|
| DESCRIPTION:
|
| EXAMPLE:  EmptyList( AList );
|
| NOTE:
|
| ASSUMES: 
|
| HISTORY: 02.04.97 from 'DeleteList', 'JoinLists'.
------------------------------------------------------------*/
void
EmptyList( List* L )
{
    // If the list is already empty, just return.
    if( L->ItemCount == 0 ) 
    {   
        return;
    }
    
    // If this is a compact list with more than one item.
//    if( L->IsCompact && (L->ItemCount > 1) )
//    {
        // Get rid of the possibly contiguous items in such
        // a way that chains can be found quickly.
//      DeleteItems( L->FirstItem );
        
        // Mark the list as empty.
//      L->FirstItem = 0;
//      L->LastItem  = 0;
//      L->ItemCount = 0;
//  }
//    else
    {
        // Account for the item records no longer in use, which
        // will be freed by 'AppendItems'.
        CountOfItemsInUse -= L->ItemCount;
    
        // Move the items from the list to the free list.
        // This clears the L->ItemCount field on completion.
        AppendItems( TheListOfFreeItems, L );
    }
}

/*------------------------------------------------------------
| EnsureEnoughFreeItems
|-------------------------------------------------------------
|
| PURPOSE: To make sure there are at least a given number of
|          free item records.
|
| DESCRIPTION: This is used to pre-allocate item records so 
| that memory allocation calls don't have to be made in order
| to add an item to a list, such as during an interrupt.
|
| EXAMPLE:  EnsureEnoughFreeItems( 100 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.10.96
------------------------------------------------------------*/
void
EnsureEnoughFreeItems( u32 LowerLimit )
{
    // If not enough free items available, make some.
    if( TheListOfFreeItems->ItemCount < LowerLimit )
    {
        MakeFreeItems( LowerLimit );
    }
}

/*------------------------------------------------------------
| ExchangeItems
|-------------------------------------------------------------
|
| PURPOSE: To exchange any two adjacent items in a given list.
|
| DESCRIPTION:
|
| EXAMPLE:  ExchangeItems(AList, AItem, BItem);
|
| NOTE: 
|
| ASSUMES: Both items are valid item record addresses.
|          The items are next to one another.
|
| HISTORY: 01.09.89
|          07.10.89 revised to include type exchange
|          07.11.89 revised to include name and mark exchange
|          07.19.89 revised to exchange items, not just the 
|                   data (latent error).
|
------------------------------------------------------------*/
void
ExchangeItems(List* AList,
              Item* AItem,
              Item* BItem)
{
    Item*   WItem;
    Item*   XItem;
    Item*   YItem;
    Item*   ZItem;

    XItem = AItem;
    YItem = BItem;

    if( GetNextItem(XItem) != YItem )
    {
        XItem = BItem;
        YItem = AItem;
    }

    WItem = GetPriorItem(XItem);
    ZItem = GetNextItem(YItem);

    PutPriorItem(XItem,YItem);
    PutNextItem(YItem,XItem);
    PutPriorItem(YItem,WItem);
    PutNextItem(XItem,ZItem);

    if( WItem == 0 )             /* XItem was first */
    {
        PutFirstItemOfList(AList,YItem);
    }
    else
    {
        PutNextItem(WItem,YItem);
    }

    if( ZItem == 0 )             /* YItem was last */
    {
        PutLastItemOfList(AList,XItem);
    }
    else
    {
        PutPriorItem(ZItem,XItem);
    }
}

/*------------------------------------------------------------
| ExtractFirstItemFromList
|-------------------------------------------------------------
|
| PURPOSE: To extract the first item from a list. 
|
| DESCRIPTION:
|
| EXAMPLE:  AnItem = ExtractFirstItemFromList(AList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.06.88
|          07.10.89 simplified
|          01.10.97 sped up.
|          02.03.97 fixed failure to clear prior link of
|                   new first item.
------------------------------------------------------------*/
Item*
ExtractFirstItemFromList( List* L )
{
    Item* XItem;
    
    // If there is no item, return zero.
    if( L->ItemCount == 0 )
    {
        return( 0 );
    }
    else // Decrement the item counter.
    {
        L->ItemCount -= 1;
    }
    
    // Refer to the item being extracted.
    XItem = L->FirstItem; 
    
    // If there are remaining items.
    if( L->ItemCount )
    {
        // Relink the List record to the next item.
        L->FirstItem = XItem->NextItem;
        
        // Clear the back link of the new first item.
        L->FirstItem->PriorItem = 0;
    }
    else // No items left.
    {
        // Clear the references to the item being extracted.
        L->LastItem  = 0;
        L->FirstItem = 0;
    }
    
    // Return the extracted item.
    return( XItem );
}

/*------------------------------------------------------------
| ExtractItemFromList
|-------------------------------------------------------------
|
| PURPOSE: To extract an item from a list.
|
| DESCRIPTION:
|
| EXAMPLE:  AnItem = ExtractItemFromList(AList, AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.06.88
|          06.17.97 sped up.
------------------------------------------------------------*/
Item*
ExtractItemFromList( List* L, Item* AnItem)
{
    Item* PrvItem;
    Item* NxtItem;
    
    // Refer to the item before the item.
    PrvItem = AnItem->PriorItem;
    
    // Refer to the item after the item.
    NxtItem = AnItem->NextItem;

    // If the item is first.
    if( L->FirstItem == AnItem )
    {
        // Revise the first item link.
        L->FirstItem = NxtItem; // May be zero.
    }
    
    // If the item is last.
    if( L->LastItem == AnItem )
    {
        // Revise the last item link.
        L->LastItem = PrvItem;  // May be zero.
    }
    
    // Patch forward link if there is one.
    if( PrvItem )
    {
        PrvItem->NextItem = NxtItem;
    }
    
    // Patch backward link if there is one.
    if( NxtItem )
    {
        NxtItem->PriorItem = PrvItem;
    }
    
    // Account for the extracted items.
    L->ItemCount -= 1;
    
    // Clear the links of extracted item.
    AnItem->PriorItem = 0;
    AnItem->NextItem  = 0;
    
#ifdef oldway
    if( AnItem )
    {    
        PushTheListAndItem();
    
        TheList = AList;
        TheItem = AnItem;
        
        AnItem = ExtractTheItem();
    
        PullTheListAndItem();
    }
#endif

    return(AnItem);
}

/*------------------------------------------------------------
| ExtractItems
|-------------------------------------------------------------
|
| PURPOSE: To extract a series of items from a list but leave
|          them connected to one another.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Specified number of items can be extracted.
|           
| HISTORY: 06.17.97 
------------------------------------------------------------*/
void
ExtractItems( List* L, Item* FromItem, u32 ItemCount )
{
    u32   i;
    Item* LastFromItem;
    Item* PrvItem;
    Item* NxtItem;
    
    // Locate the address of the last item.
    LastFromItem = FromItem;
    for( i = 1; i < ItemCount; i++ )
    {
        LastFromItem = LastFromItem->NextItem;
    }
    
    // Refer to the item before the first item.
    PrvItem = FromItem->PriorItem;
    
    // Refer to the item after the last item.
    NxtItem = LastFromItem->NextItem;

    // If the FromItem is first.
    if( L->FirstItem == FromItem )
    {
        // Revise the first item link.
        L->FirstItem = NxtItem; // May be zero.
    }
    
    // If the LastFromItem is last.
    if( L->LastItem == LastFromItem )
    {
        // Revise the last item link.
        L->LastItem = PrvItem;  // May be zero.
    }
    
    // Patch forward link if there is one.
    if( PrvItem )
    {
        PrvItem->NextItem = NxtItem;
    }
    
    // Patch backward link if there is one.
    if( NxtItem )
    {
        NxtItem->PriorItem = PrvItem;
    }
    
    // Account for the extracted items.
    L->ItemCount -= ItemCount;
    
    // Clear the links at ends of extracted series.
    FromItem->PriorItem = 0;
    LastFromItem->NextItem = 0;
}

/*------------------------------------------------------------
| ExtractLastItemFromList
|-------------------------------------------------------------
|
| PURPOSE: To extract the last item from a list.
|
| DESCRIPTION:
|
| EXAMPLE: AnItem = ExtractLastItemFromList(AList); 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.09.88
|          07.10.89 simplified
|
------------------------------------------------------------*/
Item*
ExtractLastItemFromList(List* AList)
{
    return( 
        ExtractItemFromList(AList, GetLastItemOfList(AList)) 
    );
}

/*------------------------------------------------------------
| ExtractMarkedItems
|-------------------------------------------------------------
|
| PURPOSE: To extract all marked items from a list and return
|          a list of those items.
|
| DESCRIPTION:
|
| EXAMPLE:  MarkedList = ExtractMarkedItems(AList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.04.93
|          11.19.93 simplified logic
------------------------------------------------------------*/
List*
ExtractMarkedItems(List* AList)
{
    Item*    AnItem;
    List*    ResultList;
        
    ResultList = MakeList();

    if(!IsAnyItemsInList(AList)) return(ResultList);

    ReferToList( AList ); 
    
    do
    {
        if(IsItemMarked(TheItem))
        {
            AnItem = ExtractTheItem();
            InsertItemLastInList(ResultList, AnItem);
        }
        else
        {
            ToNextItem();
        }
    }
    while( TheItem );
    
    RevertToList();
    
    return(ResultList);
}

/*------------------------------------------------------------
| ExtractTheItem
|-------------------------------------------------------------
|
| PURPOSE: To extract the current item from the current list.
|
| DESCRIPTION:
|
| EXAMPLE:  AnItem = ExtractTheItem();
|
| NOTE: 
|
| ASSUMES: Direction through list is first-to-last.
|
| HISTORY: 01.06.88
|          09.07.89 added 0 item protection
|          10.04.91 Revised for Focus.
|          11.26.91 revised to reset TheItem
|          12.01.91 IsItemAlone TheItem reset
|          10.25.93 removed MarkItemAsNotInserted
|          10.28.93 upgrade from Focus
|
------------------------------------------------------------*/
Item*
ExtractTheItem()
{
    Item* PrvItem;
    Item* NxtItem;
    Item* XItem;
    
    XItem = TheItem; /* The item being extracted */

    if(TheItem == 0) return(XItem);
    
    PrvItem = ThePriorItem;
    NxtItem = TheNextItem;
    
    TheItemCount--;
    
    if(IsItemAlone(TheItem))
    {
        MarkListAsEmpty(TheList);
        TheItem = 0;
    }
    else
    {
        if(IsItemFirst(TheItem))
        {
            /* mark next item as first  */
            MarkItemAsFirst(NxtItem);   
            TheFirstItem = NxtItem;     
            /* list now points to next item */
            ToFirstItem(); /* Reset TheItem */
        }
        else /* not the first item */
        {
            if(IsItemLast(TheItem))
            {
                /* mark previous item as last */
                MarkItemAsLast(PrvItem); 
                TheLastItem = PrvItem;   
                /* list now points to previous item */
                ToLastItem(); /* reset TheItem */
            }
            else /* somewhere in the middle */
            {
                /* relink neighboring items together */
                PutPriorItem(NxtItem,PrvItem);
                PutNextItem(PrvItem,NxtItem);
                TheItem = PrvItem; /* reset TheItem */
            }
                
        }
    }
    return(XItem);
}

/*------------------------------------------------------------
| FindContiguousItemsInList
|-------------------------------------------------------------
|
| PURPOSE: To find the first item in a list that is followed
|          by the desired number of contiguous items.
|
| DESCRIPTION: Returns the item address or zero if not 
| successful.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 06.17.97 
------------------------------------------------------------*/
Item*
FindContiguousItemsInList( List* L, u32 ItemCount )
{
    Item* A;
    u32   CountFound;
    
    // Reject easy case where list doesn't have enough
    // items.
    if( L->ItemCount < ItemCount )
    {
        return( 0 );
    }

    // If just one item is needed, return the first.
    if( ItemCount == 1 )
    {
        return( L->FirstItem );
    }
    
    // Start looking for the sequence of contiguous items.
    ReferToList( L );
    
    CountFound = 1;
    
    while( TheItem && (CountFound < ItemCount) )
    {
        // If this item is contiguous to the next one.
        if( &TheItem[1] == TheItem->NextItem )
        {
            // If this is the start of a sequence.
            if( CountFound == 1 )
            {
                // Remember the first item in the sequence.
                A = TheItem;
            }
            
            // Account for the item found.
            CountFound++;
            
            // If the number desired has been found.
            if( CountFound >= ItemCount )
            {
                RevertToList();
                
                // Return the result.
                return( A );
            }
        }
        else // Not contiguous.
        {
            // Reset the counter.
            CountFound = 1;
        }
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Signal failure.
    return( 0 );
}

/*------------------------------------------------------------
| FindDataAddressOfNthItem
|-------------------------------------------------------------
|
| PURPOSE: To find the data address of the Nth item in a list.
|
| DESCRIPTION: Returns DataAddress of the item found, else 0.
|
| N = 0 for the first item, 1 for the second and so on.
|
| EXAMPLE:  
|
|     AnItem = FindDataAddressOfNthItem( AList );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.02.97
------------------------------------------------------------*/
u8*
FindDataAddressOfNthItem( List* L, u32 N )
{
    u8* Addr;
    
    ReferToList( L );
    
    while( TheItem )
    {
        if( N )
        {
            ToNextItem();
            
            N--;
        }
        else // At the item.
        {
            break;
        }
    }
    
    // If the item wasn't reached before the end of the list
    // return 0.
    if( N )
    {
        RevertToList();
        
        return( 0 );
    }
    else // Get the data address
    {
        Addr = TheDataAddress;
        
        RevertToList();
        
        return( Addr );
    }
}

/*------------------------------------------------------------
| FindFirstItemLinkedToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To find the first item in a list pointing to the 
|          given buffer address.
|
| DESCRIPTION: Returns address of the item found, else 0.
|
| EXAMPLE:  
|
|     AnItem = FindFirstItemLinkedToBuffer(AList,SomeBuf);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.24.98 from 'FindFirstItemLinkedToData'.
------------------------------------------------------------*/
Item*
FindFirstItemLinkedToBuffer( List* AList, u8* SomeBuf )
{
    Item*    Result;

    // Return if no items in the list.
    if( AList->ItemCount == 0 ) return( 0 );
    
    Result = 0;

    ReferToList( AList ); 

    while( TheItem )
    {
        if( TheBufferAddress == SomeBuf )
        {
            Result = TheItem;
            break;
        }

        ToNextItem();
    }

    RevertToList();

    return( Result );
}

/*------------------------------------------------------------
| FindFirstItemLinkedToData
|-------------------------------------------------------------
|
| PURPOSE: To find the first item in a list pointing to the 
| given data address.
|
| DESCRIPTION: Returns address of the item found, else 0.
|
| EXAMPLE:  
|
|     AnItem = FindFirstItemLinkedToData(AList,SomeData);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.12.91
|          10.29.93 ported from procedure in Focus named,
|                     'FindFirstNodeMatchingData'
|          11.18.93 simplified logic
|          12.23.96 simplified logic
------------------------------------------------------------*/
Item*
FindFirstItemLinkedToData( List* AList, 
                           u8* SomeData )
{
    Item*    Result;

    // Return if no items in the list.
    if( AList->ItemCount == 0 ) return( 0 );
    
    Result = 0;

    ReferToList( AList ); 

    while( TheItem )
    {
        if( TheDataAddress == SomeData )
        {
            Result = TheItem;
            break;
        }

        ToNextItem();
    }

    RevertToList();

    return( Result );
}

/*------------------------------------------------------------
| FindFirstItemOfSize
|-------------------------------------------------------------
|
| PURPOSE: To find the first item of a given size in a list.
|
| DESCRIPTION: Returns address of the item found, else 0.
|
| Looks for the first item that has a 'SizeOfData' field value
| equal to the given value.
|
| EXAMPLE:  
|
|     AnItem = FindFirstItemOfSize(AList,32);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 03.08.96 
------------------------------------------------------------*/
Item*
FindFirstItemOfSize( List* AList, u32 ASize )
{
    Item*    Result;

    Result = (Item*) 0;

    /* Return if no items in the list. */
    if( !IsAnyItemsInList(AList) ) return(Result);
    
    ReferToList( AList ); 

    while( TheItem )
    {
        if( TheDataSize == ASize )
        {
            Result = TheItem;
            break;
        }

        ToNextItem();
    }

    RevertToList();

    return( Result );
}

/*------------------------------------------------------------
| FindFirstItemOfType
|-------------------------------------------------------------
|
| PURPOSE: To find the first item of a given type in a list.
|
| DESCRIPTION: Returns address of the item found, else 0.
|
| EXAMPLE:  
|
|     AnItem = FindFirstItemOfType(AList,SomeType);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.20.94
|          08.28.97 Extended type code to 32 bits.
------------------------------------------------------------*/
Item*
FindFirstItemOfType( List*  AList, 
                     u32 AType )
{
    Item*    Result;

    Result = (Item*) 0;

    /* Return if no items in the list. */
    if( !IsAnyItemsInList(AList) ) return(Result);
    
    ReferToList( AList ); 

    while( !IsItemLast(TheItem) )
    {
        if(TheDataType == AType) break;

        ToNextItem();
    }

    if( TheDataType == AType )
    {
        Result = TheItem;
    }

    RevertToList();

    return( Result );
}

/*------------------------------------------------------------
| FindFirstMarkedItem
|-------------------------------------------------------------
|
| PURPOSE: To find the address of the first marked item in a 
| list.
|
| DESCRIPTION:  Returns address of marked item or 0 if no
|               marked item was found.
|
| EXAMPLE:  AnItem = FindFirstMarkedItem(AList);
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 12.18.91
|          02.08.93 converted from list.txt
|          11.18.93 simplified logic
------------------------------------------------------------*/
Item*
FindFirstMarkedItem(List* AList)
{
    Item*    MarkedItem;
    
    ReferToList( AList );
     
    MarkedItem = (Item*) 0;
    
    while(TheItem)
    {
        if( IsItemMarked(TheItem) )
        {
            MarkedItem = TheItem;
            break;
        }
        ToNextItem();
    }

    RevertToList();
    
    return(MarkedItem);
}

/*------------------------------------------------------------
| FindFirstMatchingItem
|-------------------------------------------------------------
|
| PURPOSE: To FindFirstMatchingItem.
|
| DESCRIPTION: Returns pointer to the item found, else 0
| Expects data field offset, width and address of value to 
| match.
|
| EXAMPLE:
|  
|  SearchValue          = (u8*) "John Galt";
|  SearchKeyFieldOffset = 0;
|  SearchFieldWidth        = CountString(SearchPattern);
|
|  MatchingItem = FindFirstMatchingItem( NameList, 
|                                         SearchKeyFieldOffset, 
|                                         SearchFieldWidth, 
|                                         SearchValue );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.23.89
|          11.18.93 simplified logic
|
------------------------------------------------------------*/
Item*
FindFirstMatchingItem( List* AList, 
                       s32   FieldOffset, 
                       u32   FieldWidth, 
                       u8*   SearchValue )
{
    Item*    Result;

    Result = (Item*) 0;

    // Return if no items in the list.
    if( !IsAnyItemsInList(AList) ) return(Result);

    ReferToList( AList ); 

    while( !IsItemLast(TheItem)  )
    {
        if( IsTheDataMatching( FieldOffset, FieldWidth, SearchValue ) )
            break;
        ToNextItem();
    }

    if( IsTheDataMatching( FieldOffset, FieldWidth, SearchValue ) )
    {
        Result = TheItem;
     }

    RevertToList();

    return( Result );
}

/*------------------------------------------------------------
| FindFirstUnMarkedItem
|-------------------------------------------------------------
|
| PURPOSE: To get the address of the first unmarked item in a 
|          list.
|
| DESCRIPTION: Returns address of unmarked item or 0 if none
|              found.
|
| EXAMPLE:  AnItem = FindFirstUnMarkedItem(AList);
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 12.11.91
|          12.14.91 error: loop termination flag not dropped
|          02.08.93 converted from FindFirstUnMarkedItem in 
|                   list.txt
|          11.19.93 simplified logic
------------------------------------------------------------*/
Item*
FindFirstUnMarkedItem(List* AList)
{
    Item*    UnMarkedItem;
    
    UnMarkedItem = (Item*) 0;

    ReferToList( AList ); 
   
    while( TheItem )
    {
        if( !IsItemMarked(TheItem) )
        {
            UnMarkedItem = TheItem;
            break;
        }
        ToNextItem();
    }

    RevertToList();
    
    return(UnMarkedItem);
}

/*------------------------------------------------------------
| FindIndexOfFirstMarkedItem
|-------------------------------------------------------------
|
| PURPOSE: To get the item index of the first marked item in 
| a list.
|
| DESCRIPTION: The first item of the list has an index of 0,
| the next one is 1 and so on.
|
| EXAMPLE:  ItemIndex = FindIndexOfFirstMarkedItem(AList);
|
| NOTE:  
|
| ASSUMES: At least one item is marked in the list.
|
| HISTORY: 10.18.91
|          02.08.93 converted from list.txt
------------------------------------------------------------*/
u32
FindIndexOfFirstMarkedItem(List* AList)
{
    u32    IndexOfMarkedItem;
    
    ReferToList( AList ); 
    
    IndexOfMarkedItem = 0;

    while(!IsItemMarked(TheItem))
    {
        IndexOfMarkedItem++;
        ToNextItem();
    }

    RevertToList();
    return(IndexOfMarkedItem);
}

/*------------------------------------------------------------
| FindIndexOfItemLinkedToData
|-------------------------------------------------------------
|
| PURPOSE: To get the item index of the first item that refers
|          to a specific piece of data.
|
| DESCRIPTION: The first item of the list has an index of 0,
| the next one is 1 and so on.
|
| EXAMPLE:  ItemIndex = 
|              FindIndexOfItemLinkedToData( AList, MyData );
|
| NOTE:  
|
| ASSUMES: The data is in the list.
|
| HISTORY: 10.20.97 from 'FindIndexOfFirstMarkedItem'.
------------------------------------------------------------*/
u32
FindIndexOfItemLinkedToData( List* AList, u8* AtData )
{
    u32    IndexOfItem;
    
    ReferToList( AList ); 
    
    IndexOfItem = 0;

    while( TheItem )
    {
        // If this item refers to the data.
        if( TheDataAddress == AtData )
        {
            RevertToList();
            
            // Return the result.
            return( IndexOfItem );
        }
        
        IndexOfItem++;
        
        ToNextItem();
    }

    RevertToList();
    
    return(IndexOfItem);
}

/*------------------------------------------------------------
| FindNextItemOfType
|-------------------------------------------------------------
|
| PURPOSE: To find the next item of a given type in a list.
|
| DESCRIPTION: Returns address of the item found, else 0.
| Expects starting item and type to search for. Starts testing 
| for a match on the item AFTER the one supplied.
|
|     To be used in conjunction with "FindFirstItemOfType".
|
| EXAMPLE:  
|
|  MatchingItem = FindFirstItemOfType( TokenList, 
|                                      NumberToken );
|
|  NextMatchItem = FindNextItemOfType( TokenList, 
|                                      MatchingItem,
|                                      NumberToken );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.20.94 from 'FindNextMatchingItem'
|          08.28.97 Extended type to 32 bits.
------------------------------------------------------------*/
Item*
FindNextItemOfType( List*   AList, 
                    Item*   AnItem, 
                    u32 AType )
{
    Item*    Result;

    Result = 0;

    /* Return if no items in the list or 
     * if already at the last item. 
     */
    if( !IsAnyItemsInList(AList) || IsItemLast(AnItem) ) 
    {
        return(Result);
    }
    
    PushTheListAndItem();

    TheList = AList;
    TheItem = AnItem;

    ToNextItem();

    while( !IsItemLast(TheItem)  )
    {
        if(TheDataType == AType)
        {
            break;
        }
        ToNextItem();
    }

    if(TheDataType == AType)
    {
        Result = TheItem;
    }

    RevertToList();

    return( Result );
}

/*------------------------------------------------------------
| FindNextMatchingItem
|-------------------------------------------------------------
|
| PURPOSE: To find the next item in a list matching the search 
|          string.
|
| DESCRIPTION: Returns pointer to the item found, else 0.
| Expects starting item, data field offset, width and address
| of value to match. Starts testing for a match on the item 
| AFTER the one supplied.
|
|     To be used in conjunction with "FindFirstMatchingItem".
|
| EXAMPLE:  
|
|  SearchValue          = (u8*) "John Galt";
|  SearchKeyFieldOffset = 0;
|  SearchFieldWidth     = CountString(SearchPattern);
|
|  MatchingItem = FindFirstMatchingItem( NameList, 
|                                         SearchKeyFieldOffset, 
|                                         SearchFieldWidth, 
|                                         SearchValue );
|
|  NextMatchItem = FindNextMatchingItem( NameList, 
|                                        MatchingItem,
|                                        SearchKeyFieldOffset, 
|                                        SearchFieldWidth, 
|                                        SearchValue );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.23.89
|          12.17.93 fixed error which occurs when the last
|                   item is given as the starting item.
|
------------------------------------------------------------*/
Item*
FindNextMatchingItem( List* AList, 
                      Item* AnItem, 
                      u16          FieldOffset, 
                      u16          FieldWidth, 
                      u8* SearchValue )
{
    Item*    Result;

    Result = 0;

    /* Return if no items in the list or 
     * if already at the last item. 
     */
    if( !IsAnyItemsInList(AList) || IsItemLast(AnItem) ) 
    {
        return(Result);
    }
    
    PushTheListAndItem();

    TheList = AList;
    TheItem = AnItem;

    ToNextItem();

    while( !IsItemLast(TheItem)  )
    {
        if(IsTheDataMatching(FieldOffset, FieldWidth, SearchValue))
            break;
        ToNextItem();
    }

    if( IsTheDataMatching(FieldOffset, FieldWidth, SearchValue) )
    {
        Result = TheItem;
     }

    RevertToList();

    return( Result );
}

/*------------------------------------------------------------
| FindNthItem
|-------------------------------------------------------------
|
| PURPOSE: To find the address of the Nth item in a list.
|
| DESCRIPTION: Returns address of the item found, else 0.
|
| N = 0 for the first item, 1 for the second and so on.
|
| EXAMPLE:  
|
|     AnItem = FindNthItem( AList );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.26.97 from 'FindDataAddressOfNthItem'.
------------------------------------------------------------*/
Item*
FindNthItem( List* L, s32 N )
{
    Item* A;
    
    ReferToList( L );
    
    while( TheItem )
    {
        if( N )
        {
            ToNextItem();
            
            N--;
        }
        else // At the item.
        {
            A = TheItem;
            
            RevertToList();
            
            // Return the item found.
            return( A );
        }
    }
    
    RevertToList();
        
    // If the item wasn't reached before the end of 
    // the list, return 0.
    return( 0 );
}

/*------------------------------------------------------------
| FindPlaceInOrderedList
|-------------------------------------------------------------
|
| PURPOSE: To find the item before which the data is to be 
|          inserted (data = or < the insertion item's data).
|
| DESCRIPTION: Returns pointer to the item found, else 0 if
| item should be appended to the end of the list.
|
| EXAMPLE: AnItem = FindPlaceInOrderedList(NameList,
|                       (u8*) "Ken Dannager", 
|                       CompareStrings); 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 09.06.89
|          11.21.93 simplified logic
|
------------------------------------------------------------*/
Item*
FindPlaceInOrderedList( List* AList, 
                        u8* SomeData, 
    CompareProc ComparisonProcedure )
{
    Item*       AnItem;
    Comparison  Result;

    AnItem = (Item*) 0;

    if(!IsAnyItemsInList(AList)) return(AnItem);
    
    ReferToList( AList ); 

    while( TheItem )
    {
        Result = (*ComparisonProcedure)( TheDataAddress, SomeData );
                    
        // If the current item is of higher order than 
        // the data supplied then exit the loop.
        if( Result > 0 ) break;
        
        ToNextItem();
    }
    
    AnItem = TheItem;
    
    RevertToList();
    
    return(AnItem);
}

/*------------------------------------------------------------
| FindPlaceInOrderedDirectAccessTable
|-------------------------------------------------------------
|
| PURPOSE: To find the entry holding the address of the item 
|          before which the data is to be inserted; data = or 
|          < the insertion item's data.
|
| DESCRIPTION: Returns address of the table entry found, 
|              else 0 if it should be appended to the end
|              of the table.
|
| EXAMPLE: AnItemEntry = 
|            FindPlaceInOrderedDirectAccessTable(
|                       NameTable,
|                       CountOfNamesInTable,
|                       (u8*) "Ken Dannager", 
|                       CompareStrings); 
|
| NOTE: Uses fast binary search algorithm.
|
| ASSUMES: 
|
| HISTORY: 09.14.89
|          11.21.93 simplified logic
|
------------------------------------------------------------*/
Item**
FindPlaceInOrderedDirectAccessTable( 
    Item**          ATable, 
    u32             ACount, 
    u8*             SomeData, 
    CompareProc     ComparisonProcedure )
{
    Item**      Result;
    s32         Hi, Lo, Mid; 
    Comparison  Cond;

    Result = 0;

    if( ACount <= 0 ) 
    {
        return( Result );
    }
    
    // binary search; ATable[] must be in ascending order.
    Lo = 0;  
    Hi = (s32) ACount - 1;

    while( Lo <= Hi )
    {
        Mid = (Hi + Lo) >> 1; // (Hi+Lo)/2 

        Cond = (*ComparisonProcedure)
               ( SomeData, ATable[Mid]->DataAddress );

        if( Cond == 0 )
        {    
            Result = &ATable[Mid];  // exact match.
            
            return( Result );
        }

        if( Cond < 0 ) 
        {
            Hi = Mid - 1;
        }
        else
        {
            Lo = Mid + 1;
        }
    }
    
    if( (u32) Lo == ACount ) 
    {
        return( Result ); // beyond table.
    }
    
    Result = &ATable[Lo];        // higher order entry.

    return(Result);
}

/*------------------------------------------------------------
| ForEachItem
|-------------------------------------------------------------
|
| PURPOSE: To execute a procedure for each item in a list.
|
| DESCRIPTION: Each item of data is passed as an argument
| to the given procedure.
|
| EXAMPLE:  ForEachItem( AList, OutputString, MyFile );
|
| NOTE: 
|
| ASSUMES: The function doesn't alter the structure of the
|          list.
|
| HISTORY: 01.16.96  
------------------------------------------------------------*/
void
ForEachItem( List* AList, 
             void (*Procedure)(s8*, u32),
             u32   SecondArg )
{
    ReferToList( AList ); 
    
    /* For each item in list. */
    while( TheItem )    
    {
        /* Apply procedure to the item of data. */
        (*Procedure)( (s8*) TheDataAddress, SecondArg); 
                          
        ToNextItem();
    }

    RevertToList();
}

/*------------------------------------------------------------
| InsertDataAfterItemInList
|-------------------------------------------------------------
|
| PURPOSE: To insert a data address into a new item that is 
| inserted after a item in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  AnItem = InsertDataAfterItemInList(AList,
|                                              ItemBefore,
|                                              DataToInsert);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE: Returns address of the created item.
|
| HISTORY:    01.09.88
|
------------------------------------------------------------*/
Item*
InsertDataAfterItemInList(List* AList,
                          Item* AnItem,
                          u8* DataAddress)
{
    Item* NewItem;
    
    NewItem = MakeItemForData(DataAddress);
    InsertItemAfterItemInList(AList,AnItem,NewItem);
    return(NewItem);
}

/*------------------------------------------------------------
| InsertDataBeforeItemInList
|-------------------------------------------------------------
|
| PURPOSE: To insert a data address into a new item that is 
| inserted before a item in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  AnItem = InsertDataBeforeItemInList(AList,
|                                              ItemAfter,
|                                              DataToInsert);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE: Returns address of the created item.
|
| HISTORY:    01.09.88
|
------------------------------------------------------------*/
Item*
InsertDataBeforeItemInList(List* AList,
                           Item* AnItem,
                           u8* DataAddress)
{
    Item* NewItem;
    
    NewItem = MakeItemForData(DataAddress);
    InsertItemBeforeItemInList(AList,AnItem,NewItem);
    return(NewItem);
}

/*------------------------------------------------------------
| InsertDataFirstInList
|-------------------------------------------------------------
|
| PURPOSE: To insert the given data address into a new item 
| that is inserted first in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  AnItem = InsertDataFirstInList(AList,
|                                          DataToInsert);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE: Returns address of the created item.
|
| HISTORY:    01.06.88
|
------------------------------------------------------------*/
Item*
InsertDataFirstInList(List* AList,
                      u8* DataToInsert)
{
    Item* AnItem;
    
    AnItem = MakeItemForData(DataToInsert);
    InsertItemFirstInList(AList,AnItem);
    return(AnItem);
}

/*------------------------------------------------------------
| InsertDataInOrderedList
|-------------------------------------------------------------
|
| PURPOSE: To insert the given data into an ordered list.
|
| DESCRIPTION: The given comparison procedure is the same
| one used to sort the list in order.
|
| EXAMPLE:  NewItem = InsertDataInOrderedList( 
|                            NameList,
|                            "Francisco d'Anconia",
|                            CompareStrings);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE: Returns address of the created item.
|
| HISTORY: 09.06.89
|          10.13.98 Fixed empty list case.
------------------------------------------------------------*/
Item*
InsertDataInOrderedList(List* AList,
                        u8* SomeData,
    CompareProc ComparisonProcedure)
{
    Item*   AnItem;
    Item*   InsertionItem;

    // If the list is empty.
    if( AList->ItemCount == 0 )
    {
        // Insert the data.
        AnItem = InsertDataFirstInList( AList, SomeData );
    }
    else // There are records in the list.
    {
        InsertionItem  = FindPlaceInOrderedList( 
                            AList, 
                            SomeData, 
                            ComparisonProcedure );

        AnItem = InsertDataBeforeItemInList( 
                            AList, 
                            InsertionItem, 
                            SomeData );
    }
    
    // Return the item that refers to the data.
    return( AnItem );
}

/*------------------------------------------------------------
| InsertDataLastInList
|-------------------------------------------------------------
|
| PURPOSE: To insert the given data address into a new item 
| that is inserted last in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  NewItem = InsertDataLasInList(AList, SomeData);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE: Returns address of the created item.
|
| HISTORY: 01.09.88
|
------------------------------------------------------------*/
Item*
InsertDataLastInList( List* AList, u8* SomeData )
{
    Item* AnItem;
    
    AnItem = MakeItemForData( SomeData );
    
    InsertItemLastInList( AList, AnItem );

    return( AnItem );
}

/*------------------------------------------------------------
| InsertItemAfterItemInList
|-------------------------------------------------------------
|
| PURPOSE: To insert an item after another item in a list.
|
| DESCRIPTION: If the item to preceed the one being inserted
| is '0', then insert the item as first in the list.
|
|
| EXAMPLE:  InsertItemAfterItemInList(AList, ItemBefore,
|                                      ItemToInsert);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.09.88
|          11.21.93 if 'ItemBefore' == 0 condition added
|
------------------------------------------------------------*/
void
InsertItemAfterItemInList(List* AList,
                          Item* ItemBefore,
                          Item* ItemToInsert)
{
    Item* NextItem;
    
    if(!ItemBefore) 
    {
        InsertItemFirstInList(AList,ItemToInsert);
        return;
    }
    
    if(IsItemLast(ItemBefore)) 
    {
        InsertItemLastInList(AList,ItemToInsert);
    }
    else
    {
        NextItem = GetNextItem(ItemBefore);
        PutPriorItem(ItemToInsert,ItemBefore);
        PutNextItem(ItemBefore,ItemToInsert);
        PutNextItem(ItemToInsert,NextItem);
        PutPriorItem(NextItem,ItemToInsert);
        AddToListItemCount(AList,1);
    }
}

/*------------------------------------------------------------
| InsertItemBeforeItemInList
|-------------------------------------------------------------
|
| PURPOSE: To insert an item before an item in a list.
|
| DESCRIPTION: If the item to follow the one being inserted
| is '0', then insert the item as last in the list.
|
| EXAMPLE:  InsertItemBeforeItemInList(AList, ItemAfter,
|                                       ItemToInsert);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.09.88
|          11.21.93 if 'ItemAfter' == 0 condition added
|
------------------------------------------------------------*/
void
InsertItemBeforeItemInList(List* AList,
                           Item* ItemAfter,
                           Item* ItemToInsert)
{
    Item* PriorItem;

    if(!ItemAfter) 
    {
        InsertItemLastInList(AList,ItemToInsert);
        return;
    }
    
    if(IsItemFirst(ItemAfter)) 
    {
        InsertItemFirstInList(AList,ItemToInsert);
    }
    else
    {
        PriorItem = GetPriorItem(ItemAfter);
        PutPriorItem(ItemToInsert,PriorItem);
        PutNextItem(PriorItem,ItemToInsert);
        PutNextItem(ItemToInsert,ItemAfter);
        PutPriorItem(ItemAfter,ItemToInsert);
        AddToListItemCount(AList,1);
    }
}

/*------------------------------------------------------------
| InsertItemFirstInList 
|-------------------------------------------------------------
|
| PURPOSE: To insert the given extracted item as the first 
|          item in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  InsertItemFirstInList(AList, ItemToInsert);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.09.88
|
------------------------------------------------------------*/
void
InsertItemFirstInList(List* AList,
                      Item* AnItem)
{
    
    Item* FirstItem;
    
    MarkItemAsFirst(AnItem);
    
    if(IsAnyItemsInList(AList)) 
    {
        FirstItem = GetFirstItemOfList(AList);
        PutNextItem(AnItem,FirstItem);
        PutPriorItem(FirstItem,AnItem);
    }
    else
    {
        MarkItemAsLast(AnItem);
        PutLastItemOfList(AList,AnItem);
    }
    AddToListItemCount(AList,1);
    PutFirstItemOfList(AList,AnItem);
}

/*------------------------------------------------------------
| InsertItemLastInList
|-------------------------------------------------------------
|
| PURPOSE: To append the given extracted item to a list.
|
| DESCRIPTION:
|
| EXAMPLE:  InsertItemLastInList(AList, ItemToInsert);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.09.88
|
------------------------------------------------------------*/
void
InsertItemLastInList(List* AList,
                     Item* AnItem)
{
    
    Item* LastItem;
    
    MarkItemAsLast(AnItem);
    
    if(IsAnyItemsInList(AList)) 
    {
        LastItem = GetLastItemOfList(AList);
        PutPriorItem(AnItem,LastItem);
        PutNextItem(LastItem,AnItem);
    }
    else
    {
        MarkItemAsFirst(AnItem);
        PutFirstItemOfList(AList,AnItem);
    }
    AddToListItemCount(AList,1);
    PutLastItemOfList(AList,AnItem);
}

/*------------------------------------------------------------
| IsAnyItemMarkedInList
|-------------------------------------------------------------
|
| PURPOSE: To tell if any item is marked in a list.
|
| DESCRIPTION:  Returns non-zero if any item is marked.
|
| EXAMPLE:  Result = IsAnyItemMarkedInList( AList );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 10.18.91
|          12.19.91 fixed to handle empty lists
|          02.08.93 converted from list.txt
|          11.19.93 simplified logic
------------------------------------------------------------*/
Truth
IsAnyItemMarkedInList(List* AList)
{
    Truth    Result;
    
    Result = False;
    
    ReferToList( AList ); 
    
    while(TheItem)
    {
        if( IsItemMarked(TheItem) )
        {
            Result = True;
            break;
        }
        ToNextItem();
    }

    RevertToList();
    
    return(Result);
}

/*------------------------------------------------------------
| IsAnyItemsInList
|-------------------------------------------------------------
|
| PURPOSE: To tell if list has existing items.
|
| DESCRIPTION:
|
| EXAMPLE:  Result = IsAnyItemsInList( AList );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.05.88
|
------------------------------------------------------------*/
Truth
IsAnyItemsInList( List* L )
{
    return( (Truth) L->ItemCount );
}

/*------------------------------------------------------------
| IsItemAlone      
|-------------------------------------------------------------
|
| PURPOSE: To tell if a item is the only one in a list.
|
| DESCRIPTION:If both next and prior are 0, and 
| therefore equal, then this is the only item.
|
| EXAMPLE:  if( IsItemAlone(AnItem) ) return(True);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.88
|          07.12.89 revised
|
------------------------------------------------------------*/
Truth
IsItemAlone(Item* AnItem)
{
    return( GetPriorItem(AnItem) == GetNextItem(AnItem)  );
}

/*------------------------------------------------------------
| IsItemFirst
|-------------------------------------------------------------
|
| PURPOSE: To tell if a item is first in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  if( IsItemFirst(AnItem) ) return(True);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE: If PriorItem is 0, then item is first
|
| HISTORY: 01.04.88
|
------------------------------------------------------------*/
Truth
IsItemFirst(Item* AnItem)
{
    return(!GetPriorItem(AnItem));
}

/*------------------------------------------------------------
| IsItemLast
|-------------------------------------------------------------
|
| PURPOSE: To tell if a item is last in a list.
|
| DESCRIPTION: If NextItem is 0 then it is the last 
|              item.
|
| EXAMPLE:  if( IsItemLast(AnItem) ) return(True);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.88
|
------------------------------------------------------------*/
Truth
IsItemLast(Item* AnItem)
{
    return(!GetNextItem(AnItem));
}

/*------------------------------------------------------------
| IsItemMarked
|-------------------------------------------------------------
|
| PURPOSE: To tell if a item is marked.
|
| DESCRIPTION:
|
| EXAMPLE:  if( IsItemMarked(AnItem) ) UnMarkItem(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.12.89
|          11.09.97 pulled out 'GetItemMark' macro which
|                   collides with a Mac function in 
|                   'InterfaceLib'.
------------------------------------------------------------*/
Truth
IsItemMarked(Item* AnItem)
{
    return( (Truth) ( AnItem->ItemMark & Marked ) );
}

/*------------------------------------------------------------
| IsListMarked
|-------------------------------------------------------------
|
| PURPOSE: To tell if list is marked.
|
| DESCRIPTION:
|
| EXAMPLE:  if( IsListMarked(AList) ) UnMarkList(AList);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 07.09.88
|
------------------------------------------------------------*/
Truth
IsListMarked(List* ListAddress)
{
    return( (Truth) ( GetListMark(ListAddress) & Marked ) );
}

/*------------------------------------------------------------
| IsListsWithDataInCommon
|-------------------------------------------------------------
|
| PURPOSE: To tell if two lists have any data elements in
|          common.
|
| DESCRIPTION: If any of the item data addresses of one list
| are contained in the second one, then this procedure returns
| non-zero, and otherwise returns 0.
|
| EXAMPLE:  IsCommon = IsListsWithDataInCommon(ListA,ListB);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 01.27.94
|
------------------------------------------------------------*/
Truth
IsListsWithDataInCommon(List* AList,
                        List* BList)
{
    u8* ADataAddress;
    Truth           IsCommon;
    
    IsCommon = False;
    
    ReferToList( AList ); 
    
    while(TheItem && !IsCommon)
    {
        ADataAddress = TheDataAddress;
        
        ReferToList( BList ); 
        
        while(TheItem && !IsCommon)
        {
            if(TheDataAddress == ADataAddress)
            {
                IsCommon = True;
            }
            ToNextItem();
        }
        
        RevertToList();
        
        ToNextItem();
    }
    
    RevertToList();

    return(IsCommon);
}

/*------------------------------------------------------------
| IsMultipleReferencesToData
|-------------------------------------------------------------
|
| PURPOSE: To test for multiple references to the same data.
|
| DESCRIPTION: If any of the item data addresses of a list
| are duplicated, this procedure returns True, else False.
|
| EXAMPLE:  t = IsMultipleReferencesToData(ListA);
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE:
|
| HISTORY: 06.06.96
|
------------------------------------------------------------*/
Truth
IsMultipleReferencesToData( List* L )
{
    u8* ADataAddress;
    
    ReferToList( L ); 
    
    while( TheItem )
    {
        ADataAddress = TheDataAddress;
        
        PushTheItem(); 
        
        ToNextItem();
        
        while( TheItem )
        {
            if( TheDataAddress == ADataAddress )
            {
                PullTheItem();
                RevertToList();
                return( True );
            }
            ToNextItem();
        }
        
        PullTheItem();
        
        ToNextItem();
    }
    
    RevertToList();

    return(False);
}

/*------------------------------------------------------------
| IsTheDataMatching
|-------------------------------------------------------------
|
| PURPOSE: To tell if a field in the data of the current 
|          item matches a given test value.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
|    TheItem = SomeNameItem;
|
|    Result =  IsTheDataMatching((u16) 0, 
|                                (u16) 4, 
|                                (u8*) "John" )
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.23.89
|
------------------------------------------------------------*/
Truth
IsTheDataMatching( s32 FieldOffset, 
                   u32 FieldWidth, 
                   u8* DataToMatch )
{
    u8*    FieldAddress;
    
    FieldAddress = TheDataAddress;
    
    return( IsMatchingBytes( (u8*) 
                             &FieldAddress[FieldOffset], 
                             DataToMatch, 
                             FieldWidth ) );
}

/*------------------------------------------------------------
| JoinLists
|-------------------------------------------------------------
|
| PURPOSE: To join two lists together to form one list.
|
| DESCRIPTION: The items of the follower list, are appended 
| to the leader list, and then the empty follower list is 
| deleted.
| 
| EXAMPLE:  
|
|     JoinLists(ListA, ListB);
|
|     will result in the items from listB being tacked onto
|     the end of ListA and then the list record for ListB 
|     will be deleted.
| 
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.11.91
|          10.29.93 ported from Focus project.
|          02.04.96 factored out 'AppendItems'.
------------------------------------------------------------*/
void
JoinLists( List* LeaderList,
           List* FollowerList)
{
    // If the FollowerList has items.
    if( FollowerList->ItemCount )
    {   
        // Move the items.
        AppendItems( LeaderList, FollowerList );
    }

    // Return the list record to the list pool for reuse.
    // 
    // Put the 'List' into the free list, treating it as an 'Item'.
    InsertItemFirstInList( TheListOfFreeLists, 
                           (Item*) FollowerList );
     
    // Account for the list record no longer in use.
    CountOfListsInUse--;
}     

/*------------------------------------------------------------
| MakeCompactItems
|-------------------------------------------------------------
|
| PURPOSE: To make a chain of contiguous items.
|
| DESCRIPTION: Doesn't clear the item data fields.
|
| Does the following:
|
| 1. Searches 'TheListOfFreeItemChains' for a large enough
|    chain and if found:
|
|    a. Uses the whole thing if it is exactly the right 
|       length.
|
|    b. Separates the excess items in the chain and puts 
|       them back.
|
| 2. Or, searches 'TheListOfFreeItems' for a large enough
|    chain and if found, extracts it.
|
| 3. Or, allocates a fresh chain of items and sorts 
|    'TheListOfFreeItems.
|
| EXAMPLE:
|
| NOTE: Could merge all chains into 'TheListOfFreeItems'
|       before sorting.
|
| ASSUMES: No lists in 'TheListOfFreeItemChains' are empty.
|          'TheListOfFreeItemChains' is zero if there are
|          no lists in it which can happen if the last
|          remaining chain of the last remaining list is 
|          extracted.
|
| NOTE: 
|
| HISTORY: 06.19.97
------------------------------------------------------------*/
Item*
MakeCompactItems( u32 ItemCount )
{
    Item*   First;
    Item*   FirstExcess;
    List*   CL;
    List*   LargestChainList;
    Item*   Last;
    u32     i, NewCount, ChainLength;
  
    // If the item count is 1, use 'MakeItem'.
    if( ItemCount == 1 )
    {
        return( MakeItem() );
    }
    
    // If there is is no 'TheListOfFreeItemChains'.
    if( ! TheListOfFreeItemChains )
    {
        // Skip forward to try the general free list.
        goto TryGeneralFreeList;
    }
    
    // Refer to the last chain list in the list of all chains.
    LargestChainList = 
        (List*) TheListOfFreeItemChains->LastItem->DataAddress;
        
    // If there is a chain large enough.
    if( LargestChainList->FirstItem->SizeOfData 
        >=
        ItemCount )
    {
        // Search for the chain that exactly matches or
        // is just larger than the chain sought.
        ReferToList( TheListOfFreeItemChains );
        
NextChainList:
        
        // Refer to the chain list.
        CL = (List*) TheDataAddress;
        
        // Get the length of chains on this list.
        ChainLength = CL->FirstItem->SizeOfData;
        
        // If this chain count is too small.
        if( ChainLength < ItemCount )
        {
            ToNextItem();
                    
            goto NextChainList;
        }
        
        RevertToList();
            
        // Refer to the chain which will be extracted.
        First = (Item*) CL->FirstItem->DataAddress;
            
        // Extract and delete the item that refers 
        // to the chain.
        DeleteItem( ExtractFirstItemFromList( CL ) );
            
        // If the chain list is empty, remove it from
        // 'TheListOfFreeItemChains' and delete it.
        if( CL->ItemCount == 0 )
        {
            DeleteFirstReferenceToData(
                TheListOfFreeItemChains,
                           (u8*) CL );
            DeleteList( CL );
           
            // If 'TheListOfFreeItemChains' is empty,
            // delete it too.
            if( TheListOfFreeItemChains->ItemCount == 0 )
            {
                DeleteList( TheListOfFreeItemChains );
                
                TheListOfFreeItemChains = 0;
            }
        }
        
        // Account for the new items now in-use: must do this
        // here because 'DeleteItems' for excess will deduct
        // the items from 'CountOfItemsInUse'.
        CountOfItemsInUse += ChainLength;
        
        // If there are excess items, cut them off and free
        // them.
        if( ChainLength > ItemCount )
        {
            // Find the first excess item.
            FirstExcess = First;
            for( i = 0; i < ItemCount; i++ )
            {
                FirstExcess = FirstExcess->NextItem;
            }
            
            // Refer to the last item of the kept section.
            Last = FirstExcess->PriorItem;
            
            // Cut the links.
            Last->NextItem = 0;
            FirstExcess->PriorItem = 0;
            
            // Free the excess.
            DeleteItems( FirstExcess );
        }
        
        // Return the result.
        return( First );
    }
    else // No chain large enough.
    {
TryGeneralFreeList:

        // Find the required number of contiguous items
        // on the free list, if any.
        First = FindContiguousItemsInList( 
                    TheListOfFreeItems,
                    ItemCount );
                
        // If the items weren't found.
        if( ! First )
        {
            // Release all chains to the general pool.
            MoveChainsToGeneralFreeList();
 
            // Sort the free list.
            SortListByItemAddress( TheListOfFreeItems );
        
            // Find the required number of contiguous items
            // on the free list, if any.
            First = FindContiguousItemsInList( 
                        TheListOfFreeItems,
                        ItemCount );
            
            // If the items still weren't found.
            if( ! First )
            {
                // Calculate the size of the smallest 
                // satisfactory block.
                NewCount = max( ItemCount, 500 );
            
                // Make a new block of free items which
                // will appear at the start of the free list.
                MakeFreeItems( NewCount );
              
                // Refer to the chain.
                First = TheListOfFreeItems->FirstItem;
            }
        }
        
        // Extract the chain from the free list.
        ExtractItems( TheListOfFreeItems, First, ItemCount );
            
        // Account for the new items now in use.
        CountOfItemsInUse += ItemCount;
        
        // Return the result.
        return( First );
    }
}

/*------------------------------------------------------------
| MakeCompactList
|-------------------------------------------------------------
|
| PURPOSE: To make a list of items which are contiguous in
|          memory.
|
| DESCRIPTION: Speeds list operations for CPUs with data 
| caches.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.15.97  
------------------------------------------------------------*/
List* 
MakeCompactList( u32 ItemCount )
{
    List* L;
    Item* A;
    
    // Make the new list.
    L = MakeList();
    
    // Mark the list as compact.
    L->IsCompact = True;
    
    // If no items to be attached now, just return.
    if( ItemCount == 0 )
    {
        return( L );
    }
    
    // Make the contiguous items.
    if( ItemCount == 1 )
    {
        A = MakeItem();
        
        L->FirstItem = A;
        L->LastItem  = A;
        L->ItemCount = 1;
//ValidateList( L, 1 );
        return( L );
    }
    else // Multiple items.
    {
        A = MakeCompactItems( ItemCount );
    }
    
    // Save the reference to the first item.
    L->FirstItem = A;
            
    // For each item.
    ReferToList( L );
    
    while( TheItem )
    {
        // Increment the list item count field.
        L->ItemCount++;
        
        // If this is the last item, update the list field.
        if( TheItem->NextItem == 0 )
        {
            L->LastItem = TheItem;
        }
        
        // Clear the item fields.
        TheItem->BufferAddress = 0;
        TheItem->SizeOfBuffer  = 0;
        TheItem->ItemMark      = 0;
        TheItem->TypeOfData    = 0;
        TheItem->SizeOfData    = 0;
        TheItem->DataAddress   = 0;
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Return the list.
//ValidateList( L, ItemCount );
    return( L );
}

/*------------------------------------------------------------
| MakeFreeItems
|-------------------------------------------------------------
|
| PURPOSE: To pre-allocate a block of item records and put 
|          them on the item free list.
|
| DESCRIPTION: 
|
| EXAMPLE:  MakeFreeItems( 100 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.10.96 pulled out of 'MakeItem'.
|          12.10.96 added '-1' to loop termination condition
|                   when linking free item records to avoid
|                   an error.
|          01.10.97 revised free list structure.
|          06.15.97 made item order on free list coorespond
|                   to ordering of address in memory.
------------------------------------------------------------*/
void
MakeFreeItems( u32 HowMany )
{
    Item*   AFreeItem;
    u32     SizeOfSegment;
    u32*    ASegment;
    s32     i;
    
    // Allocate a segment of 'HowMany' item
    // records with a leading link field for the 
    // segment list.
        
    SizeOfSegment = 
            ( sizeof(Item) * HowMany ) + 4;
            
    ASegment = (u32*) malloc( SizeOfSegment );
        
    // Attach the new segment to the segment chain so that
    // it can be deallocated on cleanup.
 
    ASegment[0]  = (u32) SegmentChain;
    SegmentChain = ASegment;
        
    // Refer to the first free item in the segment.
    AFreeItem = (Item*) &ASegment[1];
        
    // Put the items at the start of the free list in 
    // increasing memory order: compact lists depend on this.
    //
    for( i = (s32) ( HowMany - 1 ); i >= 0; i-- )
    {
        // Put the 'Item' into the free list.
        InsertItemFirstInList( TheListOfFreeItems, 
                               &AFreeItem[i] );
    }
}

/*------------------------------------------------------------
| MakeItem
|-------------------------------------------------------------
|
| PURPOSE: To make a new empty, unmarked, non-inserted item.
|
| DESCRIPTION: 
|
| EXAMPLE:  AnItem = MakeItem();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|          07.10.89 Revised for new item structure
|          11.17.93 simplified logic
|          02.12.94 initialized the mark field not just the
|                   mark bit.
|          06.01.94 increased 'ItemRecordsPerSegment' to 200 from 50
|                   to reduce fragmentation of the heap.
|          05.01.96 Simplified logic; added clearing of 
|                   data size, type and all address fields.
|          12.10.96 factored out 'MakeFreeItems', added 
|                   initialization of buffer fields.
|          01.10.97 revised free list structure.
|          06.15.97 changed minimum block size to 500 items 
|                   from 100.
|          06.19.97 added pulling from item chains when
|                   general item pool is empty.
|          06.20.97 disabled pulling from item chains to 
|                   reduce fragmentation.
------------------------------------------------------------*/
Item*
MakeItem()
{
    Item*   AnItem;
    Item*   OtherItem;

// DEFER
//ValidateList( TheListOfFreeItems, 10000 );
      
    // If no free items available, make some.
    if( TheListOfFreeItems->ItemCount == 0 )
    {
        // If there are items in the item chain lists.
//      if( TheListOfFreeItemChains && 
//          TheListOfFreeItemChains->ItemCount > 1 )
        if( 0 )
        {
            // Make the minimum-sized compact item chain.
            AnItem = MakeCompactItems( 2 );
            
            // Refer to the next item.
            OtherItem = AnItem->NextItem;
            
            // Break the items apart.
            AnItem->NextItem     = 0;
            OtherItem->PriorItem = 0;
            
            // Delete the excess item.
            DeleteItem( OtherItem );
            
            // Clear the item fields.
            AnItem->BufferAddress = 0;
            AnItem->SizeOfBuffer  = 0;
            AnItem->ItemMark      = 0;
            AnItem->TypeOfData    = 0;
            AnItem->SizeOfData    = 0;
            AnItem->DataAddress   = 0;

            // Return the result.
            return( AnItem );
        }
        else // Make some fresh items.
        {
            MakeFreeItems( ItemsRecordsPerSegment );
        }
    }
// DEFER
//ValidateList( TheListOfFreeItems, 10000 );
    
    // At this point there is at least one free item.
    
    // Reserve the first free item for use.
    AnItem = ExtractFirstItemFromList( TheListOfFreeItems );
// DEFER
//ValidateList( TheListOfFreeItems, 10000 );

    // Account for the new item now in use.
    CountOfItemsInUse++;
     
    // Clear the data address, size of data, type of data
    // and mark fields.
    AnItem->NextItem = 0;
    AnItem->PriorItem = 0;
    AnItem->BufferAddress = 0;
    AnItem->SizeOfBuffer = 0;
    AnItem->ItemMark = 0;
    AnItem->TypeOfData = 0;
    AnItem->SizeOfData = 0;
    AnItem->DataAddress = 0;
     
    // Return the item.
    return( AnItem );        
}

/*------------------------------------------------------------
| MakeItemForData
|-------------------------------------------------------------
|
| PURPOSE: To make a new item and associate it with the given
|          data.
|
| DESCRIPTION: Construction operation.
|
| EXAMPLE:  AnItem = MakeItemForData( "Existence exists." );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.07.91
|          10.29.93 ported from Focus 
|          12.10.96 added setting of the buffer address as
|                   well as the data address.
------------------------------------------------------------*/
Item*
MakeItemForData( u8* SomeData )
{
    Item* ThisItem;
    
    ThisItem = MakeItem();
    
    ThisItem->BufferAddress = SomeData;
    
    ThisItem->DataAddress = SomeData;
    
    return(ThisItem);
}

/*------------------------------------------------------------
| MakeList
|-------------------------------------------------------------
|
| PURPOSE: To make a new empty, unmarked list.
|
| DESCRIPTION: 
|
| EXAMPLE:  AList = MakeList();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|          07.10.89 new structure revision
|          11.17.93 simplified logic
|          01.21.94 added dynamic allocation of list records.
|          02.12.94 clears the entire list mark field instead
|                   of just the bit.
|          06.01.94 increased 'ListsPerSegment' to 200 from 50
|                   to reduce fragmentation of the heap.
|          12.10.96 added '-1' to loop termination condition
|                   when linking free list records to avoid
|                   an error.
|          01.10.97 Changed free list usage.
|          02.04.97 fixed failure to make the list of free 
|                   lists.  Also extra decrement of item
|                   count in free list was wrong.
------------------------------------------------------------*/
List*
MakeList()
{
    List*   FirstListInSegment;
    Item*   ListAsItem; 
    List*   L;
    s32     ListsPerSegment;
    u32     SizeOfSegment;
    u32*    ASegment;
    u16     i;
    
    // If free list available, use it. 
    if( TheListOfFreeLists && TheListOfFreeLists->ItemCount )
    {
ReUseList:
        // DEFER
//      ValidateList( TheListOfFreeLists, 10000 );

        // Pull a list record from the free list: 'List'
        // record is treated as an 'Item' record while on
        // the free list.
        L = (List*)
            ExtractFirstItemFromList( TheListOfFreeLists );
        
        // Account for the new list now in use.
        CountOfListsInUse++;
 
        // Clear the list mark field.
        L->ListMark = 0;
        
        // Mark the list as not compact.
        L->IsCompact = 0;
        
        // From 'MarkListAsEmpty':
        L->ItemCount = 0;
        L->FirstItem = 0;
        L->LastItem  = 0;
        
    // DEFER
//  ValidateList( TheListOfFreeLists, 10000 );
    
        // Return the new list record.
        return( L );
    }
    else // If no free lists available, make some.
    {
        ListsPerSegment = 200;
        // Allocate a segment of ListsPerSegment list 
        // records with a leading link field for the 
        // segment list.
        //
        SizeOfSegment = 
            sizeof(List) * ListsPerSegment + 4;
            
        ASegment = (u32*) malloc(SizeOfSegment);
        
        // Attach the new segment to the segment chain so that
        // they can be deallocated on cleanup.
        //
        ASegment[0]  = (u32) SegmentChain;
        SegmentChain = ASegment;

        // Refer to the first list record in the segment.
        FirstListInSegment = (List*) &ASegment[1];
        
        // Insert each list record in the segment into the
        // free list, treating each 'List' record as if it
        // were an 'Item' record.
        //
        for( i = 0; i < ListsPerSegment; i++ )
        {
            // Refer to the 'List' record as if it were
            // an 'Item' record.
            ListAsItem = (Item*) (&FirstListInSegment[i]);
            
            // Put the 'Item' into the free list.
            InsertItemFirstInList( TheListOfFreeLists, 
                                   ListAsItem );
        }
         
        goto ReUseList;
    }
}

/*------------------------------------------------------------
| MakeListForString
|-------------------------------------------------------------
|
| PURPOSE: To make a new list, duplicate a string and insert
|          it into the list.
|
| DESCRIPTION:  
|
| EXAMPLE:  AList = MakeListForString( "Existence exists." );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.02.97
------------------------------------------------------------*/
List*
MakeListForString( s8* AString )
{
    List*   L;
    Item*   AnItem;
    s8*     S;
    
    L = MakeList();
    
    S = DuplicateString( AString );
    
    AnItem = InsertDataLastInList( L, (u8*) S );
    
    AnItem->SizeOfData = CountString( S );
    
    AnItem->SizeOfBuffer = AnItem->SizeOfData + 1;
    
    return( L );
}

/*------------------------------------------------------------
| MakeNonCompactItems
|-------------------------------------------------------------
|
| PURPOSE: To make a chain of items that are probably not
|          compact.
|
| DESCRIPTION: Doesn't clear the item data fields.
|
| Does the following:
|
| 1. If there are not enough items on the 'TheListOfFreeItems', 
|    some new ones are created.
|
| 2. Extracts the items from the free list.
|
| EXAMPLE:
|
| NOTE:  
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 06.20.97 from 'MakeSemiCompactItems'.
------------------------------------------------------------*/
Item*
MakeNonCompactItems( u32 ItemCount )
{
    Item*   First;
    
    // If the item count is 1, use 'MakeItem'.
    if( ItemCount == 1 )
    {
        return( MakeItem() );
    }

    // If there are not enough items on the free list.
    if( TheListOfFreeItems->ItemCount < ItemCount )
    {
        // Make some new free items.
        MakeFreeItems( ItemCount );
    }
    
    // Refer to the start of the chain.
    First = TheListOfFreeItems->FirstItem;
        
    // Extract the chain from the free list.
    ExtractItems( TheListOfFreeItems, First, ItemCount );
            
    // Account for the new items now in use.
    CountOfItemsInUse += ItemCount;
        
    // Return the result.
    return( First );
}

/*------------------------------------------------------------
| MakeNonCompactList
|-------------------------------------------------------------
|
| PURPOSE: To make a list of items which are probably not
|          contiguous.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.97 from 'MakeSemiCompactList'. 
------------------------------------------------------------*/
List* 
MakeNonCompactList( u32 ItemCount )
{
    List* L;
    Item* A;
    
    // Make the new list.
    L = MakeList();
    
    // Mark the list as compact.
    L->IsCompact = False;
    
    // If no items to be attached now, just return.
    if( ItemCount == 0 )
    {
        return( L );
    }
    
    // Make the contiguous items.
    if( ItemCount == 1 )
    {
        A = MakeItem();
        
        L->FirstItem = A;
        L->LastItem  = A;
        L->ItemCount = 1;

        return( L );
    }
    else // Multiple items.
    {
        A = MakeNonCompactItems( ItemCount );
    }
    
    // Save the reference to the first item.
    L->FirstItem = A;
            
    // For each item.
    ReferToList( L );
    
    while( TheItem )
    {
        // If this is the last item, update the list field.
        if( TheItem->NextItem == 0 )
        {
            L->LastItem = TheItem;
        }
        
        // Clear the item fields.
        TheItem->BufferAddress = 0;
        TheItem->SizeOfBuffer  = 0;
        TheItem->ItemMark      = 0;
        TheItem->TypeOfData    = 0;
        TheItem->SizeOfData    = 0;
        TheItem->DataAddress   = 0;
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Set the list item count field.
    L->ItemCount = ItemCount;
        
    // Return the list.
    return( L );
}

/*------------------------------------------------------------
| MakeSemiCompactItems
|-------------------------------------------------------------
|
| PURPOSE: To make a chain of possibly contiguous items.
|
| DESCRIPTION: Doesn't clear the item data fields.
|
| Does the following:
|
| 1. Searches 'TheListOfFreeItemChains' for a large enough
|    chain and if found:
|
|    a. Uses the whole thing if it is exactly the right 
|       length.
|
|    b. Or, assembles a long enough list from smaller chains.
|
| 2. Or, searches 'TheListOfFreeItems' for a large enough
|    chain and if found, extracts it.
|
| 3. Or, allocates a non-contiguous chain of items and sorts 
|    'TheListOfFreeItems.
|
| EXAMPLE:
|
| NOTE: Could assemble lists from smaller chains before
|       freeing them.
|
| ASSUMES: No lists in 'TheListOfFreeItemChains' are empty.
|          'TheListOfFreeItemChains' is zero if there are
|          no lists in it which can happen if the last
|          remaining chain of the last remaining list is 
|          extracted.
|
| NOTE: 
|
| HISTORY: 06.20.97 from 'MakeCompactItems'.
------------------------------------------------------------*/
Item*
MakeSemiCompactItems( u32 ItemCount )
{
    Item*   First;
    List*   CL;
    List*   LargestChainList;
    Item*   Last;
    u32     i, ChainLength;
  
    // If the item count is 1, use 'MakeItem'.
    if( ItemCount == 1 )
    {
        return( MakeItem() );
    }
    
    // If there is is no 'TheListOfFreeItemChains'.
    if( ! TheListOfFreeItemChains )
    {
        // Skip forward to try the general free list.
        goto TryGeneralFreeList;
    }
    
    // Refer to the last chain list in the list of all chains.
    LargestChainList = 
        (List*) TheListOfFreeItemChains->LastItem->DataAddress;
        
    // If there may be a chain with the exact size needed.
    if( LargestChainList->FirstItem->SizeOfData 
        >=
        ItemCount )
    {
        // Search for the chain that exactly matches the
        // chain sought.
        ReferToList( TheListOfFreeItemChains );
        
        while( TheItem )
        {
            // Refer to the chain list.
            CL = (List*) TheDataAddress;
        
            // Get the length of chains on this list.
            ChainLength = CL->FirstItem->SizeOfData;
        
            // If this chain count matches.
            if( ChainLength == ItemCount )
            {
                RevertToList();
                
                goto FoundMatch;
            }
            
            ToNextItem();
        }       
        
        RevertToList();
        
        // Exact match not found.
        
        goto TryGeneralFreeList;
        
        
FoundMatch:
    
        // Refer to the chain which will be extracted.
        First = (Item*) CL->FirstItem->DataAddress;
            
        // Extract and delete the item that refers 
        // to the chain.
        DeleteItem( ExtractFirstItemFromList( CL ) );
            
        // If the chain list is empty, remove it from
        // 'TheListOfFreeItemChains' and delete it.
        if( CL->ItemCount == 0 )
        {
            DeleteFirstReferenceToData(
                TheListOfFreeItemChains,
                           (u8*) CL );
            DeleteList( CL );
           
            // If 'TheListOfFreeItemChains' is empty,
            // delete it too.
            if( TheListOfFreeItemChains->ItemCount == 0 )
            {
                DeleteList( TheListOfFreeItemChains );
                
                TheListOfFreeItemChains = 0;
            }
        }
        
        // Account for the new items now in-use.
        CountOfItemsInUse += ChainLength;
                
        // Return the result.
        return( First );
    }
    else // No chain large enough.
    {
TryGeneralFreeList:

        // Find the required number of contiguous items
        // on the free list, if any.
        First = FindContiguousItemsInList( 
                    TheListOfFreeItems,
                    ItemCount );
                    
        // If the contiguous items were found.
        if( First )
        {
            // Extract the chain from the free list.
            ExtractItems( TheListOfFreeItems, First, ItemCount );
        }
        else // If the items weren't found.
        {   
            // Release all chains to the general pool.
            MoveChainsToGeneralFreeList();
 
            // Sort the free list.
            SortListByItemAddress( TheListOfFreeItems );
        
            // Make a chain of items which aren't contiguous.
            First = MakeItem();
            Last  = First;
            
            for( i = 1; i < ItemCount; i++ )
            {
                 Last->NextItem = MakeItem();
                 
                 Last->NextItem->PriorItem = Last;
                 
                 Last = Last->NextItem;
            }
        }
            
        // Account for the new items now in use.
        CountOfItemsInUse += ItemCount;
        
        // Return the result.
        return( First );
    }
}

/*------------------------------------------------------------
| MakeSemiCompactList
|-------------------------------------------------------------
|
| PURPOSE: To make a list of items which are contiguous in
|          memory if possible.
|
| DESCRIPTION: Speeds list operations for CPUs with data 
| caches and reduces fragmentation over 'MakeCompactList'.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 06.20.97 from 'MakeCompactList'. 
------------------------------------------------------------*/
List* 
MakeSemiCompactList( u32 ItemCount )
{
    List* L;
    Item* A;
    
    // Make the new list.
    L = MakeList();
    
    // Mark the list as compact.
    L->IsCompact = True;
    
    // If no items to be attached now, just return.
    if( ItemCount == 0 )
    {
        return( L );
    }
    
    // Make the contiguous items.
    if( ItemCount == 1 )
    {
        A = MakeItem();
        
        L->FirstItem = A;
        L->LastItem  = A;
        L->ItemCount = 1;
//ValidateList( L, 1 );
        return( L );
    }
    else // Multiple items.
    {
        A = MakeSemiCompactItems( ItemCount );
    }
    
    // Save the reference to the first item.
    L->FirstItem = A;
            
    // For each item.
    ReferToList( L );
    
    while( TheItem )
    {
        // Increment the list item count field.
        L->ItemCount++;
        
        // If this is the last item, update the list field.
        if( TheItem->NextItem == 0 )
        {
            L->LastItem = TheItem;
        }
        
        // Clear the item fields.
        TheItem->BufferAddress = 0;
        TheItem->SizeOfBuffer  = 0;
        TheItem->ItemMark      = 0;
        TheItem->TypeOfData    = 0;
        TheItem->SizeOfData    = 0;
        TheItem->DataAddress   = 0;
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Return the list.
//ValidateList( L, ItemCount );
    return( L );
}

/*------------------------------------------------------------
| MarkItem
|-------------------------------------------------------------
|
| PURPOSE: To mark a item.
|
| DESCRIPTION:
|
| EXAMPLE:  MarkItem(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.18.89
|          11.09.97 pulled out 'GetItemMark' macro which
|                   collides with a Mac function in 
|                   'InterfaceLib'.
|
------------------------------------------------------------*/
void
MarkItem(Item* AnItem)
{
    AnItem->ItemMark = (u16) ( AnItem->ItemMark | Marked );
}

/*------------------------------------------------------------
| MarkItemAsFirst
|-------------------------------------------------------------
|
| PURPOSE: To mark a item as first in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  MarkItemAsFirst(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.09.88
|          07.10.89 new structure revision
|
------------------------------------------------------------*/
void
MarkItemAsFirst(Item* AnItem)
{
    PutPriorItem(AnItem,(Item*) 0);
}

/*------------------------------------------------------------
| MarkItemAsLast
|-------------------------------------------------------------
|
| PURPOSE: To mark a item as last in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  MarkItemAsLast(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.09.88
|          07.10.89 new structure revision
|
------------------------------------------------------------*/
void
MarkItemAsLast(Item* AnItem)
{
    PutNextItem(AnItem,0);
}

/*------------------------------------------------------------
| MarkList
|-------------------------------------------------------------
|
| PURPOSE: To mark a list.
|
| DESCRIPTION: 
|
| EXAMPLE:  MarkList( AList );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.19.89
|          01.21.99 Expanded macro.
------------------------------------------------------------*/
void
MarkList( List* L )
{
    L->ListMark = (u8) ( L->ListMark | Marked );
}
    
/*------------------------------------------------------------
| MarkListAsEmpty
|-------------------------------------------------------------
|
| PURPOSE: To mark a list as having no items.
|
| DESCRIPTION: 
|
| EXAMPLE:  MarkListAsEmpty( AList );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
void
MarkListAsEmpty( List* L )
{
    L->ItemCount = 0;
    L->FirstItem = 0;
    L->LastItem  = 0;
}

/*------------------------------------------------------------
| MoveChainsToGeneralFreeList
|-------------------------------------------------------------
|
| PURPOSE: To transfer all chains of contiguous items to
|          the general free list.
|
| DESCRIPTION: 
|
| EXAMPLE:   
|
| NOTE:  
|
| ASSUMES:  
|           
| HISTORY: 06.19.97
------------------------------------------------------------*/
void
MoveChainsToGeneralFreeList()
{
    Item* First;
    Item* Last;
    List* CL;
    u32   Count;
    
    if( TheListOfFreeItemChains == 0 )
    {
        return;
    }
    
    // While there are chain lists.
    while( TheListOfFreeItemChains->ItemCount )
    {
        // Refer to the data as a chain list.
        CL = (List*) 
             TheListOfFreeItemChains->
                           FirstItem->DataAddress;
                           
        // Extract and delete the item that refers 
        // to the chain list.
        DeleteItem( 
            ExtractFirstItemFromList( 
                TheListOfFreeItemChains ) );
        
        // While there are chains in this list.
        while( CL->ItemCount )
        {
            // Refer to the chain which will be extracted.
            First = (Item*) CL->FirstItem->DataAddress;
        
            // Get the item count.
            Count = CL->FirstItem->SizeOfData;
        
            // Extract and delete the item that refers 
            // to the chain.
            DeleteItem( ExtractFirstItemFromList( CL ) );
        
            // Append the items to the general free list.
            Last = First;
        
            // Find the last item in the chain.
            while( Last->NextItem )
            {
                Last = Last->NextItem;
            }
        
            // If the 'TheListOfFreeItems' list has existing 
            // items.
            if( TheListOfFreeItems->ItemCount )
            {
                // Link the next link of the 'TheListOfFreeItems' 
                // list to the beginning of the chain.
                TheListOfFreeItems->LastItem->NextItem = First;
         
                // Link the prior link of the chain
                // to the end of the TheListOfFreeItems list.
                First->PriorItem = TheListOfFreeItems->LastItem;
            }
            else // 'TheListOfFreeItems' list is empty. 
            {
                // Set the first item pointer in the
                // destination list from the source chain.
                TheListOfFreeItems->FirstItem = First;
            }
    
            // Set the last item pointer in the
            // destination list from the source chain.
            TheListOfFreeItems->LastItem = Last;
    
            // Add the chain count to the list total.
            TheListOfFreeItems->ItemCount += Count;
        }
        
        // Delete the chain list itself, now empty.
        DeleteList( CL );
    } 
    
    // Delete the list of all chain lists itself, now empty.
    DeleteList( TheListOfFreeItemChains );
                
    TheListOfFreeItemChains = 0;
}

/*------------------------------------------------------------
| MoveItems
|-------------------------------------------------------------
|
| PURPOSE: To move a series of items from one list to the end
|          a second list.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: Specified number of items can be moved.
|           
| HISTORY: 06.17.97 
------------------------------------------------------------*/
void
MoveItems( List* From, Item* FromItem, List* To, u32 ItemCount )
{
    u32   i;
    Item* LastFromItem;
    
    // Locate the address of the last from item.
    LastFromItem = FromItem;
    for( i = 1; i < ItemCount; i++ )
    {
        LastFromItem = LastFromItem->NextItem;
    }
    
    // Extract the items from the source list.
    ExtractItems( From, FromItem, ItemCount );
    
    // If the 'To' list has existing items.
    if( To->ItemCount )
    {
        // Link the next link of the 'To' list
        // to the first from item.
        To->LastItem->NextItem = FromItem;
        
        // Link the prior link of the FromItem  
        // to the end of the 'To' list.
        FromItem->PriorItem = To->LastItem;
    }
    else // 'To' list is empty. 
    {
        // Set the first item pointer in the
        // destination list from the source list
        To->FirstItem = FromItem;
    }
    
    // Set the last item pointer in the
    // destination list from the source list
    To->LastItem = LastFromItem;
    
    // Account for the new items added.
    To->ItemCount += ItemCount;
}

/*------------------------------------------------------------
| MoveItemToFirst
|-------------------------------------------------------------
|
| PURPOSE: To move an item from its current position in a list
|          to be the first item in the list.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 06.24.98
------------------------------------------------------------*/
void
MoveItemToFirst( List* L, Item* A )
{
    // If the item isn't already first.
    if( A->PriorItem )
    {
        // Extract the current item.
        ExtractItemFromList( L, A );
                
        // Make it first in the list.
        InsertItemFirstInList( L, A );
    }
}

/*------------------------------------------------------------
| OutputListOfStrings
|-------------------------------------------------------------
|
| PURPOSE: To output strings attached to a list.
|
| DESCRIPTION: Each string is placed on a separate line.
| A blank line is printed after the list.
|
| EXAMPLE:  OutputListOfStrings( MyList, OutputFile );
|
| NOTE: 
|
| ASSUMES: Each string is able to fit on a single line.
|
| HISTORY: 01.13.88
|          02.08.93 removed item count control in favor of 
|                    TheItem being non-0.
|          11.08.93 added explicit stream parameter
------------------------------------------------------------*/
void
OutputListOfStrings(List* AList, 
                    FILE *OutputStream)
{
    ReferToList( AList ); 
    
    while(TheItem)
    {
        fprintf(OutputStream,"%s\n",
            (s8*)TheDataAddress);
        ToNextItem();
    }

    fprintf(OutputStream,"\n");

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
| EXAMPLE:  OutputListSystemStatus(OutputFile);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.26.91
|          11.01.93 extended 
|          11.08.93 added 'OutputStream' parameter
|          01.12.97 revised for new free list structure.
------------------------------------------------------------*/
void
OutputListSystemStatus(FILE *OutputStream)
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
    
    fprintf(OutputStream,"\n");
    fprintf(OutputStream,"List System Status:\n");
    fprintf(OutputStream,"    TheListSystemIsSetUp...%d\n\n",
                         TheListSystemIsSetUp);

    fprintf(OutputStream,"    ListsInUse.............%ld\n",
                                  CountOfListsInUse);
    fprintf(OutputStream,"    ItemsInUse.............%ld\n\n",
                                  CountOfItemsInUse);
    fprintf(OutputStream,"    FreeLists..............%ld\n",
                                  FreeLists);
                         
    fprintf(OutputStream,"    FreeItems..............%ld\n\n",
                                  FreeItems);

    fprintf(OutputStream,"    TheList................%lx\n",TheList);
    if(TheList)
    {
          fprintf(OutputStream,"        TheFirstItem.......%lx\n",
                                            TheFirstItem);
          fprintf(OutputStream,"        TheLastItem........%lx\n",
                                            TheLastItem);
          MarkString = (s8*) "UnMarked";
          if(IsListMarked(TheList)) MarkString = (s8*) "Marked";
          fprintf(OutputStream,"        TheListMark........%s\n",
                                               MarkString);
          fprintf(OutputStream,"        TheItemCount.......%ld\n\n",
                                            TheItemCount);
    }
    
    fprintf(OutputStream,"    TheItem................%lx\n",TheItem);
    if(TheItem)
    {
        fprintf(OutputStream,"        ThePriorItem.......%lx\n",
                                            ThePriorItem);
        fprintf(OutputStream,"        TheNextItem........%lx\n",
                                            TheNextItem);
        MarkString = (s8*) "UnMarked";
        if(IsItemMarked(TheItem)) MarkString = (s8*) "Marked";
        fprintf(OutputStream,"        TheItemMark........%s\n",
                                            MarkString);
        fprintf(OutputStream,"        TheDataAddress.....%lx\n",
                                            TheDataAddress);
    }
}

/*------------------------------------------------------------
| NAME:PickRandomData
|-------------------------------------------------------------
|
| PURPOSE: To randomly pick an item from a list and return
|          it's data address. 
|
| DESCRIPTION: Returns zero if there are no items or the 
| address of a randomly chosen item.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|           
| HISTORY: 06.08.97 
------------------------------------------------------------*/
u8*
PickRandomData( List* L )
{
    u32 n;
    
    if( L->ItemCount == 0 )
    {
        return( 0 );
    }
    else
    {
        n = (u32) RandomInteger( (s32) L->ItemCount );
    
        return( FindDataAddressOfNthItem( L, n ) );
    }
}

/*------------------------------------------------------------
| NAME:PickRandomItems
|-------------------------------------------------------------
|
| PURPOSE: To randomly pick items without duplication from a
|          list to make a new list.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 'SetUpRandomNumberGenerator' called at least once.
|          There are at least 'Count' items in the list.
|           
| HISTORY: 06.02.97 
------------------------------------------------------------*/
List*
PickRandomItems( List* A, u32 Count )
{
    List*  B;
    u8*    Marks;
    u8*    Addr;
    u32    ACount, Trials, i, n;
    Item** T;
    
    // Make the new list.
    B = MakeList();
    
    // Get the count of items in the A list.
    ACount = A->ItemCount;
    
    // If the number of possibilities is zero, just return.
    if( ACount == 0 )
    {
        return( B );
    }
    
    // Make a direct access table for the source list for
    // speed.
    T = BuildDirectAccessTableForList( A );

    // Limit the count to the number present.
    if( Count > ACount )
    {
        Count = ACount;
    }
    
    // Make a buffer to hold marks for each item.
    Marks = (u8*) malloc( ACount );
    
    // Clear the marks buffer.
    FillBytes( Marks, ACount, 0 );
    
    // Until all of the requested items have been picked.
    while( Count )
    {
        Trials = 0;
TryAgain:
        // Generate a random number in the range of all
        // items.
        n = (u32) RandomInteger( (s32) ACount );
        
        // If the item is marked, seek again.
        if( Marks[n] )
        {
            Trials++;
            
            // Try up to ten random seeks, then scan.
            if( Trials < 10 )
            {
                goto TryAgain;
            }
            else // Scan from the start to locate an
                 // unmarked item.
            {
                for( i = 0; i < ACount; i++ )
                {
                    if( Marks[i] == 0 )
                    {
                        n = i;
                        break;
                    }
                }
            }
        }
        
        // Mark the item as chosen.
        Marks[n] = 1;
        
        // Locate the address of the data of the nth item.
        Addr = T[n]->DataAddress;
        
        // Put the data into the new list.
        InsertDataLastInList( B, Addr );
        
        // Account for the item being picked.
        Count--;
    }
    
    // Delete the working buffers.
    free( Marks );
    free( T );
    
    // Return the resulting list.
    return( B );
}

/*------------------------------------------------------------
| PullTheItem
|-------------------------------------------------------------
|
| PURPOSE: To pull TheItem from TheListStack.
|
| DESCRIPTION:
|
| EXAMPLE:  PullTheItem();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
void
PullTheItem()
{
    TheItem = (Item*) 
              TheListStack[TheListStackIndex--];
}

/*------------------------------------------------------------
| PullTheList
|-------------------------------------------------------------
|
| PURPOSE: To pull TheList from TheListStack.
|
| DESCRIPTION:
|
| EXAMPLE:  PullTheList();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
void
PullTheList()
{
    TheList = (List*) 
              TheListStack[TheListStackIndex--];
}

/*------------------------------------------------------------
| PullTheListAndItem
|-------------------------------------------------------------
|
| PURPOSE: To pull The Item and TheList from TheListStack.
|
| DESCRIPTION:
|
| EXAMPLE:  PullTheListAndItem();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
void
PullTheListAndItem()
{
    PullTheItem();
    PullTheList();
}

/*------------------------------------------------------------
| PushTheItem
|-------------------------------------------------------------
|
| PURPOSE: To save TheItem on TheListStack.
|
| DESCRIPTION:
|
| EXAMPLE:  PushTheItem()
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
void
PushTheItem()
{
    if( TheListStackIndex >= MaxListStackItems )
    {
        Debugger();
    }
    
    TheListStack[++TheListStackIndex] = (u32) TheItem;
}

/*------------------------------------------------------------
| PushTheList
|-------------------------------------------------------------
|
| PURPOSE: To save TheList on TheListStack.
|
| DESCRIPTION:
|
| EXAMPLE:  PushTheList()
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
void
PushTheList()
{
    if( TheListStackIndex >= MaxListStackItems )
    {
        Debugger();
    }

    TheListStack[++TheListStackIndex] = (u32) TheList;
}

/*------------------------------------------------------------
| PushTheListAndItem
|-------------------------------------------------------------
|
| PURPOSE: To save TheList and TheItem on TheListStack.
|
| DESCRIPTION:
|
| EXAMPLE:  PushTheListAndItem()
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
void
PushTheListAndItem()
{
    PushTheList();
    PushTheItem();
}

/*------------------------------------------------------------
| ReferToList
|-------------------------------------------------------------
|
| PURPOSE: To push the current list and item and make a new
|          list and item current. 
|
| DESCRIPTION: A shorter equivalent to the sequence:
| 
|           PushTheListAndItem();
|           TheList = <MyList>;
|           ToFirstItem();
|
| Use the counterpart function 'RevertToList' to restore
| the current list/item context.
|
| EXAMPLE:  ReferToList( MyList );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 05.01.96 
|          06.13.97 expanded functions for speed.
------------------------------------------------------------*/
void
ReferToList( List* L )
{
    if( L == 0 )
    {
        Debugger();
    }
    
    // PushTheListAndItem();

    TheListStack[++TheListStackIndex] = (u32) TheList;
    
    TheListStack[++TheListStackIndex] = (u32) TheItem;
     
    if( TheListStackIndex >= MaxListStackItems )
    {
        Debugger();
    }

    TheList = L;
    
    TheItem = L->FirstItem; // ToFirstItem();
}

/*------------------------------------------------------------
| ReorderListToMatchDirectAccessTable
|-------------------------------------------------------------
|
| PURPOSE: To make the order of items in a list conform to
| the items in a DirectAccessTable.
|
| DESCRIPTION: After reordering a list via a direct access
| table it may be necessary to make the original list conform
| to the new ordering: this procedure does that.
|
| EXAMPLE:  ReorderListToMatchDirectAccessTable( 
|                    NameList,
|                   AlphaNameTable);
|
| NOTE: 
|
| ASSUMES: All items are contained in both the list
|          and the direct access table.
|
| HISTORY: 09.12.89
|          10.28.93 revised for speed.
|
------------------------------------------------------------*/
void
ReorderListToMatchDirectAccessTable( List* AList,
                                     Item** Table )
{
    u32            CountOfItems;
    u32            IndexOfLastItem;
    u32            Entry;
    Item*    PriorItem;
    Item*    NextItem;
    
    CountOfItems = GetListItemCount(AList);
    
    if( CountOfItems < 2) return;

    IndexOfLastItem = CountOfItems - 1;
    
    PushTheListAndItem();
    
    TheList = AList;

    /* Adjust the list record first. */    
    TheFirstItem = Table[0];
    TheLastItem  = Table[IndexOfLastItem];
    
    /* Adjust the item pointers for all items but the last. */
    PriorItem = 0;
    
    for( Entry = 0; Entry < IndexOfLastItem; Entry++ )
    {
        TheItem  = Table[Entry];
        NextItem = Table[Entry+1];
        
        ThePriorItem = PriorItem;
        TheNextItem  = NextItem;
        
        PriorItem = TheItem;
    }
    
    /* Adjust the last item. */
    TheItem      = Table[IndexOfLastItem];
    ThePriorItem = Table[IndexOfLastItem-1];
    TheNextItem  = 0;

    PullTheListAndItem();
}

/*------------------------------------------------------------
| ReverseList
|-------------------------------------------------------------
|
| PURPOSE: To reverse the ordering of items in a list.
|
| DESCRIPTION:
|
| EXAMPLE:  ReverseList(AList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.02.93
|
------------------------------------------------------------*/
void
ReverseList(List* AList)
{
    Item*    NextItem;
    Item*    FirstItem;
    
    ReferToList( AList ); 
    
    while(TheItem)
    {
        /* Exchange the next and prior item addresses. */
        NextItem     = TheNextItem;
        TheNextItem  = ThePriorItem;
        ThePriorItem = NextItem;
        
        TheItem = NextItem;
    }
    
    /* Exchange the endpoint addresses in the list record. */
    FirstItem    = TheFirstItem;
    TheFirstItem = TheLastItem;
    TheLastItem  = FirstItem;
    
    RevertToList();
}

/*------------------------------------------------------------
| RevertToList
|-------------------------------------------------------------
|
| PURPOSE: To refer to the list and item that were current
|          before the last 'ReferToList' call.
|
| DESCRIPTION:  
|
| EXAMPLE:  RevertToList();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 05.01.96 
|          06.13.97 expanded functions for speed.
------------------------------------------------------------*/
void
RevertToList()
{
    TheItem = (Item*) // PullTheItem();
              TheListStack[TheListStackIndex--];
    
    TheList = (List*) // PullTheList();
              TheListStack[TheListStackIndex--];
}

/*------------------------------------------------------------
| SetSizeOfItemsInList
|-------------------------------------------------------------
|
| PURPOSE: To set the 'SizeOfData' field of every item in a
|          list to a given value.
|
| DESCRIPTION:   
|
| EXAMPLE:  SetSizeOfItemsInList(AList, 2);
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 03.08.96 
------------------------------------------------------------*/
void
SetSizeOfItemsInList( List* AList, u32 s )
{
    ReferToList( AList ); 
    
    while(TheItem)
    {
        TheDataSize = s;
        
        ToNextItem();
    }

    PullTheListAndItem();
}

/*------------------------------------------------------------
| SetUpTheListSystem
|-------------------------------------------------------------
|
| PURPOSE: To set up the list system for use.
|
| DESCRIPTION: 
|
| EXAMPLE:  SetUpTheListSystem();
|
| NOTE: This procedure must be executed prior to running
|       any other procedure in the list system.
|
| ASSUMES: 
|
| HISTORY: 03.09.89
|          07.09.89 Changed to pre-allocate all possible 
|                   lists and items.
|          07.19.89 added free list
|          01.21.94 removed maximum list & item limits,
|                   deleted pre-allocation of lists.
|          01.10.97 revised to make lists for free lists and
|                   items.
|          02.04.97 fixed failure to make the list of free 
|                   lists.
------------------------------------------------------------*/
void
SetUpTheListSystem()
{

    if( !TheListSystemIsSetUp )
    {
        TheListStackIndex = 0;
        
        SegmentChain = 0;
        
        // Make the list record for the list free list.
        {
            TheListOfFreeLists = 
                (List*) malloc( sizeof( List ) );
                
            // Clear the list mark field.
            TheListOfFreeLists->ListMark = 0;
        
            // From 'MarkListAsEmpty':
            TheListOfFreeLists->ItemCount = 0;
            TheListOfFreeLists->FirstItem = 0;
            TheListOfFreeLists->LastItem  = 0;
        }
        
        // Ok to use 'MakeList' here because just made
        // the free list for the lists above.
        TheListOfFreeItems = MakeList();
    }
    
    TheListSystemIsSetUp++;
}

/*------------------------------------------------------------
| SortDirectAccessTable
|-------------------------------------------------------------
|
| PURPOSE: To sort a direct access table in ascending order.
|
| DESCRIPTION: Expects the address of a direct access table,
| a count of entries in the table, and the address of the
| comparison procedure to be used. 
|
| Uses fast Heap Sort procedure.
|
| A direct access table is an array of item record addresses.
|
| EXAMPLE:  
|
| SortDirectAccessTable( ATable, 
|                        EntryCount, 
|                        CompareStrings );
|
| NOTE: Especially well suited to long tables as the run time
| is proportional to Nlog2N as a worst case, eg. a 256 element
| list would take time proportional to 256*8 = 2048 vs.
| N*N or 64K for the bubble sort.
|
| ASSUMES: 
|
| NOTE: See "Numerical Recipes, The Art of Scientific 
|        Computing", page 229, for complete explanation. 
|
| HISTORY: 09.12.89
|          12.22.91 revised to use Heap Sort algorithm.
|          11.02.93 ported from Focus.
|
------------------------------------------------------------*/
void
SortDirectAccessTable( 
    Item**          ATable, 
    u32             TableCount, 
    CompareProc ComparisonProcedure)
{
    u8*  AData;
    u8*  BData;
    Item*  EntryBeingMoved;
    Comparison       ComparisonResult;
    u32           HeapIndexL;
    u32           HeapIndexIR;
    u32           HeapIndexI;
    u32           HeapIndexJ;
    
    if(TableCount < 2) return;
    
    HeapIndexL  = (TableCount >> 1) + 1; 
    HeapIndexIR = TableCount;
    
    while(1)
    {
        if(HeapIndexL > 1)
        {
            HeapIndexL--;
            EntryBeingMoved = ATable[HeapIndexL-1];
        }
        else
        {
            EntryBeingMoved = ATable[HeapIndexIR-1];
            ATable[HeapIndexIR-1] = ATable[0];
            HeapIndexIR--;
            if( HeapIndexIR == 1 ) /* at the end */
            {               
                ATable[0] = EntryBeingMoved;
                   return;
            }
        }
        
        HeapIndexI = HeapIndexL;
        HeapIndexJ = HeapIndexL<<1;
        
        while( HeapIndexJ <= HeapIndexIR )
        {
            if( HeapIndexJ < HeapIndexIR )
            {
                AData = ATable[HeapIndexJ-1]->DataAddress;
                BData = ATable[HeapIndexJ]->DataAddress;

                  ComparisonResult  = 
                    (*ComparisonProcedure)(AData,BData);
                  
                if( ComparisonResult < 0 )
                {
                    HeapIndexJ++;
                }
            }
            
            AData = EntryBeingMoved->DataAddress;
            BData = ATable[HeapIndexJ-1]->DataAddress;

            ComparisonResult = (*ComparisonProcedure)(AData,BData);
                  
            if( ComparisonResult < 0 )
            {
              
              ATable[HeapIndexI-1] = ATable[HeapIndexJ-1];
              HeapIndexI = HeapIndexJ;
              HeapIndexJ += HeapIndexJ;
            }
            else
            {
              HeapIndexJ = HeapIndexIR+1;
            }
        }
        
        ATable[HeapIndexI - 1] = EntryBeingMoved;
    }
}

/*------------------------------------------------------------
| SortList
|-------------------------------------------------------------
|
| PURPOSE: To sort a list in ascending order using a given 
| comparison procedure.
|
| DESCRIPTION: Uses one of two algorithms depending on the
| length of the list:
|
| 1. For lists with more items than 'DirectAccessTableThreshold',
|    the list is sorted by way of a direct access table using a
|    HeapSort algorithm.
|
| 2. Shorter lists use a simple, slower bubble sort algorithm.
|
| EXAMPLE:  SortList( ListOfNames, CompareStrings );
|
| NOTE: See 'CompareStrings' for an example of a comparison
| procedure.  Use it as a template for other comparison 
| procedures.
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 11.02.93
|          07.26.97 excluded lists with less than 2 items.
------------------------------------------------------------*/
void
SortList(List* AList,
         CompareProc ComparisonProcedure)
{
  
    if( AList->ItemCount < 2 )
    {
        return;
    }
          
    if( GetListItemCount(AList) > DirectAccessTableThreshold )
    {
        SortListViaDirectAccessTable(
            AList,
            ComparisonProcedure);
    }
    else
    {
        SortShortList(AList,ComparisonProcedure);
    }
}

/*------------------------------------------------------------
| SortListAlphabetically
|-------------------------------------------------------------
|
| PURPOSE: To sort a list alphabetically.
|
| DESCRIPTION:
|
| EXAMPLE:  SortListAlphabetically( ListOfNames );
|
| NOTE: 
|
| ASSUMES: 
|
| NOTE: Case insensitive.
|
| HISTORY: 01.13.89
|          11.02.93 revised to call 'SortList'.
|
------------------------------------------------------------*/
void
SortListAlphabetically(List* AList)
{
    SortList( AList, 
              (CompareProc) CompareStrings );
}

/*------------------------------------------------------------
| SortListAsBinaryData
|-------------------------------------------------------------
|
| PURPOSE: To sort a list in ascending order of the binary
|          data stored in the data buffer of each item.
|
| DESCRIPTION:
|
| EXAMPLE:  SortListAsBinaryData( AnyList, 32 );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 05.13.97 from 'SortListByDataAddress'.
------------------------------------------------------------*/
void
SortListAsBinaryData( List* AList, u32 RecordSize )
{
    // 'TheRecordSize' is used by 'CompareRecords'.
    TheRecordSize = RecordSize;
    
    SortList( AList, 
              (CompareProc) CompareRecords );
}

/*------------------------------------------------------------
| SortListByDataAddress
|-------------------------------------------------------------
|
| PURPOSE: To sort a list in ascending item data address order.
|
| DESCRIPTION:
|
| EXAMPLE:  SortListByDataAddress( AnyList );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.16.96 from 'SortListAlphabetically'.
|
------------------------------------------------------------*/
void
SortListByDataAddress(List* AList)
{
    SortList( AList, 
              (CompareProc) CompareAddresses );
}

/*------------------------------------------------------------
| SortListByItemAddress
|-------------------------------------------------------------
|
| PURPOSE: To sort a list in ascending item address order.
|
| DESCRIPTION: Used to make item link order the same as
| order in memory.
|
| EXAMPLE:  SortListByItemAddress( AnyList );
|
| NOTE: 
|
| ASSUMES: *** Data address field can be changed. ***
|
| HISTORY: 06.17.97 from 'SortListByDataAddress'.
|
------------------------------------------------------------*/
void
SortListByItemAddress( List* L )
{
    Truth IsSorted;
    
    // Put the item address into the data field and check
    // the sorting status.
    IsSorted = True;
    
    ReferToList( L );
    
    while( TheItem )
    {
        TheDataAddress = (u8*) TheItem;
        
        // If there is a next item.
        if( TheItem->NextItem )
        {
            // If the address is lower than the current
            // item.
            if( TheItem->NextItem < TheItem )
            {
                // Sorting is needed.
                IsSorted = False;
            }
        }
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Sort the list if needed.
    if( IsSorted == False )
    {
        SortList( L, 
                  (CompareProc) CompareAddresses );
    }
}

/*------------------------------------------------------------
| SortListDescending
|-------------------------------------------------------------
|
| PURPOSE: To sort a list in descending order.
|
| DESCRIPTION: Pass the comparison function to be used.  
|        
|
| EXAMPLE:  SortListDescending( ListOfNames, CompareStrings );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.11.89
|          09.14.89 BackCount added.
|          11.02.93 revised to use 'ReverseList'.
------------------------------------------------------------*/
void
SortListDescending(List* AList,
    CompareProc ComparisonProcedure)
{
    SortList( AList, ComparisonProcedure );
    
    ReverseList( AList );
}

/*------------------------------------------------------------
| SortListViaDirectAccessTable
|-------------------------------------------------------------
|
| PURPOSE: To sort a list in ascending order by first 
| creating a direct access table.
|
| DESCRIPTION: Pass the comparison function to be used. Uses 
| fast heap sort algorithm.
| Creates a direct access table, sorts it, conforms list to
| ordering of the table, then discards the table.  
|
| Primarily for use with long lists.
|
| EXAMPLE:  
|        SortListViaDirectAccessTable( ListOfNames, 
|                                      CompareStrings );
| NOTE: 
|
| ASSUMES: Enough memory exists for direct access table 
|          built by this procedure.
|
| HISTORY: 09.12.89
|
------------------------------------------------------------*/
void
SortListViaDirectAccessTable( List* AList, 
    CompareProc ComparisonProcedure)
{
    Item**     TablePointer;
    
    TablePointer = BuildDirectAccessTableForList( AList );
    
    SortDirectAccessTable( TablePointer, 
                           GetListItemCount(AList), 
                           ComparisonProcedure );

    ReorderListToMatchDirectAccessTable( AList, 
                                         TablePointer ); 

    free( (u8*) TablePointer );
}

/*------------------------------------------------------------
| SortShortList
|-------------------------------------------------------------
|
| PURPOSE: To sort a given list in ascending order using 
| a given comparison procedure.
|
| DESCRIPTION: Uses simple but slow bubble sort function.  
| Doesn't require any additional storage.
|
| EXAMPLE:  SortShortList( ListOfNames, CompareStrings );
|
| NOTE: Use for short lists only.
|
| ASSUMES: 
|
| NOTE: 
|
| HISTORY: 01.11.89
|          09.14.89 BackCount added.
|
------------------------------------------------------------*/
void
SortShortList(List*      AList,
    CompareProc ComparisonProcedure)
{
    Truth             IsInOrder;
    u8*   AddressOfDataFromNextItem;
    Item*   NextItem;
    Comparison      ComparisonResult;
    u32            Repetitions,BackCount;
    
    if( GetListItemCount(AList) < 2 ) return;
    
    ReferToList( AList ); 
    
    IsInOrder = 0;

    BackCount = 1;
    
    while(IsInOrder == 0)
    {
        IsInOrder = 1;
        ToFirstItem();
        Repetitions = TheItemCount - BackCount++;
        
        while(Repetitions--)
        {
            NextItem         = TheNextItem;
            AddressOfDataFromNextItem = NextItem->DataAddress;
            ComparisonResult        = 
                (*ComparisonProcedure)
                (TheDataAddress,AddressOfDataFromNextItem);
                
            if(ComparisonResult > 0)
            {
                ExchangeItems(TheList,TheItem,NextItem);
                IsInOrder = 0;
            }
            else
            {
                ToNextItem();
            }
        }
    }
    
    PullTheListAndItem();
}

/*------------------------------------------------------------
| ToFirstItem
|-------------------------------------------------------------
|
| PURPOSE: To set the current item to be the first item in
|          the current list.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|          TheList = ListOfNames;
|          ToFirstItem();
|
|          while(TheItem)
|          {
|               ConvertStringToUpperCase(
|                    (s8*)TheDataAddress);
|               ToNextItem();
|          }
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
#ifndef IN_LINE_TRAVERSALS
void
ToFirstItem()
{
    TheItem = TheFirstItem;
}
#endif

/*------------------------------------------------------------
| ToLastItem
|-------------------------------------------------------------
|
| PURPOSE: To set the current item to be the last item in
|          the current list.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|          TheList = ListOfNames;
|          ToLastItem();
|
|          while(TheItem)
|          {
|               ConvertStringToUpperCase(
|                    (s8*)TheDataAddress);
|                ToPriorItem();
|           }
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
#ifndef IN_LINE_TRAVERSALS
void
ToLastItem()
{
    TheItem = TheLastItem;
}
#endif

/*------------------------------------------------------------
| ToNextItem
|-------------------------------------------------------------
|
| PURPOSE: To set the current item to be the next item in
|          the current list.
|
| DESCRIPTION: A list traversal operation.
|
| EXAMPLE:  
|          TheList = ListOfNames;
|          ToFirstItem();
|
|          while(TheItem)
|          {
|               ConvertStringToUpperCase(
|                    (s8*)TheDataAddress);
|                ToNextItem();
|          }
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
#ifndef IN_LINE_TRAVERSALS
void
ToNextItem()
{
    TheItem = TheItem->NextItem;
}
#endif

/*------------------------------------------------------------
| ToPriorItem
|-------------------------------------------------------------
|
| PURPOSE: To set a new current item via PriorItem 
| from TheItem.
|
| DESCRIPTION: A list traversal operation.
|
| EXAMPLE:  
|          TheList = ListOfNames;
|          ToLastItem();
|
|          while(TheItem)
|          {
|               ConvertStringToUpperCase(
|                    (s8*)TheDataAddress);
|                ToPriorItem();
|           }
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.04.89
|
------------------------------------------------------------*/
#ifndef IN_LINE_TRAVERSALS
void
ToPriorItem()
{
    TheItem = TheItem->PriorItem;
}
#endif

/*------------------------------------------------------------
| UnMarkAllItemsInList
|-------------------------------------------------------------
|
| PURPOSE: To clear item marks on all items in a list.
|
| DESCRIPTION:  Item marks may be used to separate some items
| from others in a list, e.g. to show which ones are selected. 
|
| EXAMPLE:  UnMarkAllItemsInList(AList);
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 10.08.91
|          02.08.93 from list.txt
------------------------------------------------------------*/
void
UnMarkAllItemsInList(List* AList )
{
    ReferToList( AList ); 
    
    while(TheItem)
    {
        UnMarkItem(TheItem);
        ToNextItem();
    }

    PullTheListAndItem();
}

/*------------------------------------------------------------
| UnMarkItem
|-------------------------------------------------------------
|
| PURPOSE: To unmark a item.
|
| DESCRIPTION:
|
| EXAMPLE:  UnMarkItem(AnItem);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.18.89
|          11.09.97 pulled out 'GetItemMark' macro which
|                   collides with a Mac function in 
|                   'InterfaceLib'.
|
------------------------------------------------------------*/
void
UnMarkItem( Item* AnItem )
{
    AnItem->ItemMark = (u16) ( AnItem->ItemMark & ~Marked );
}

/*------------------------------------------------------------
| UnMarkList
|-------------------------------------------------------------
|
| PURPOSE: To unmark a list.
|
| DESCRIPTION: 
|
| EXAMPLE:  UnMarkList(AList);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 07.19.89
|          01.20.98 Expanded macros.
------------------------------------------------------------*/
void
UnMarkList( List* L )
{
    L->ListMark = (u8) ( L->ListMark & ~Marked );
}

/*------------------------------------------------------------
| ValidateList
|-------------------------------------------------------------
|
| PURPOSE: To test the integrity of the links in a list.
|
| DESCRIPTION: Halts in the debugger if an error is found.
|
| Expects an upper bound on the number of items that is valid
| for the list.
|
| EXAMPLE:  ValidateList( AList, 10000 );
|
| NOTE: 
|
| ASSUMES: The list record address should be non-zero.
|
| HISTORY: 02.03.97
|
------------------------------------------------------------*/
void
ValidateList( List* L, u32 MaxValidItems )
{
    u32 ItemsFoundCount;
    
    // Test for invalid list address.
    if( L == 0 )
    {
        Debugger();
    }
    
    // If there are no items in the list, make sure that
    // the item links are zero.
    if( L->ItemCount == 0 && 
        ( L->FirstItem || L->LastItem ) )
    {
        Debugger();
    }
    
    // If no items, then check the item references and
    //  return.
    if( L->ItemCount == 0 )
    {
        if( L->FirstItem || L->LastItem )
        {
            Debugger();
        }
        
        return;
    }
    
    // Test the number of items against the limits.
    if( L->ItemCount > MaxValidItems ||
        L->ItemCount < 0 )
    {
        Debugger();
    }
    
    // Check each link and verify item count.
    ItemsFoundCount = 0;
    
    ReferToList( L );
    
    while( TheItem )
    {
        // Accumulate how many items are found on the chain.
        ItemsFoundCount++;
        
        // Test any forward link.
        if( TheItem->NextItem &&
            (TheItem->NextItem->PriorItem != TheItem) )
        {
            Debugger();
        }
        
        // Test any backward link.
        if( TheItem->PriorItem &&
            (TheItem->PriorItem->NextItem != TheItem) )
        {
            Debugger();
        }
        
        ToNextItem();
    }
    
    RevertToList();
    
    if( ItemsFoundCount != L->ItemCount )
    {
        Debugger();
    }
}

#endif // WORK IN PROGRESS
