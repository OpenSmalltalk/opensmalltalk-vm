/*------------------------------------------------------------
| TLStacks.c
|-------------------------------------------------------------
|
| PURPOSE: To provide dynamic stack functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 02.03.93 from stacks.c.
|          01.03.94 revised
|          02.07.01 Removed TLTarget.h.
------------------------------------------------------------*/

#include "TLTarget.h"

#ifndef FOR_DRIVER

#include <stdio.h>  // for error messages.
#include <stdlib.h>

#endif // FOR_DRIVER

#include "NumTypes.h"   
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
 
Lot*    TheStackPool = 0;
                // The allocation pool from which all data
                // in stack functions is allocated.

/*------------------------------------------------------------
| DeleteStack
|-------------------------------------------------------------
|
| PURPOSE: To deallocate a stack.
|
| DESCRIPTION:
|
| EXAMPLE:  DeleteStack( S );
|
| NOTE: 
|
| ASSUMES:
|
| HISTORY: 02.23.99
------------------------------------------------------------*/
void
DeleteStack( Stack* S )
{
    // Free the item data.
    FreeMemoryHM( S->ItemData );
    
    // Free the stack record itself.
    FreeMemoryHM( S );
}

/*------------------------------------------------------------
| GetItemOnStack
|-------------------------------------------------------------
|
| PURPOSE: To return the value of the indexed item on the 
|          given stack.
|
| DESCRIPTION: Index 0 is the top stack item.
|
| EXAMPLE:  a = GetItemOnStack(MyStack,(u32) 0);
|               returns the top stack item.
|
|           b = GetItemOnStack(MyStack,(u32) 1);
|               returns the item under the top stack item.
|
| NOTE: 
|
| ASSUMES: Indexed item is on the stack. 
|
| HISTORY: 01.03.93 
|
------------------------------------------------------------*/
u32
GetItemOnStack( Stack* AStack, u32 ItemOffset )
{
    u32 AStackItem;
    s32 Index;
    
    Index = (s32)
        ( AStack->StackIndex - ( ItemOffset + 1U ) );

    AStackItem = AStack->ItemData[Index];
        
    return( AStackItem );
}

/*------------------------------------------------------------
| GetStackItemCount
|-------------------------------------------------------------
|
| PURPOSE: To get the number of items on the given stack.
|
| DESCRIPTION:
|
| EXAMPLE:  a = GetStackItemCount(MyStack);
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 01.03.93 
|
------------------------------------------------------------*/
u32
GetStackItemCount( Stack* AStack )
{
    return( (u32) AStack->StackIndex );
}

/*------------------------------------------------------------
| GetTopItem
|-------------------------------------------------------------
|
| PURPOSE: To return the value of the the top item on the 
|          given stack.
|
| DESCRIPTION:
|
| EXAMPLE:  a = GetTopItem(MyStack);
|
| NOTE: 
|
| ASSUMES: There is an item on the stack to get.
|
| HISTORY: 01.03.93 
|
------------------------------------------------------------*/
u32
GetTopItem( Stack* AStack )
{
    u32 AStackItem;
    s32 Index;
    
    Index = AStack->StackIndex - 1;

    AStackItem = AStack->ItemData[Index];
        
    return( AStackItem );
}

/*------------------------------------------------------------
| MakeStack
|-------------------------------------------------------------
|
| PURPOSE: To dynamically allocate a new stack.
|
| DESCRIPTION:
|
| EXAMPLE:  MyStack = MakeStack((u32) 200);
|
| NOTE: 
|
| ASSUMES:  Need to write 'DeleteStack'.
|
| HISTORY: 01.03.93 
|
------------------------------------------------------------*/
Stack*
MakeStack( u32 MaxItems )
{
    Stack*  AStack;
    
    AStack = (Stack*) 
        AllocateMemoryAnyPoolHM( 
            TheStackPool, 
            sizeof( Stack ) );
     
    AStack->ItemData = (u32*)
        AllocateMemoryAnyPoolHM( 
            TheStackPool, 
            MaxItems * sizeof(u32) );
     
    AStack->MaxIndex = (s32) MaxItems;
    
    // Mark the stack as dynamically allocated.
    AStack->IsStorageOwned = 1;

    ResetStack(AStack);
    
    return(AStack);
}

/*------------------------------------------------------------
| MakeStaticStack
|-------------------------------------------------------------
|
| PURPOSE: To make a statically allocated stack.
|
| DESCRIPTION:
|
| EXAMPLE: 
|              MakeStaticStack( &S, &ABuffer, 200 );
|
| NOTE: 
|
| ASSUMES:  Need to write 'DeleteStack'.
|
| HISTORY: 06.14.01 From MakeStack.
------------------------------------------------------------*/
void
MakeStaticStack( 
    Stack*  S,
            // Pre-allocated Stack record to be used.
            //
    u32*    ItemData,
            // Pre-allocated buffer to hold stack items.
            //
    u32     MaxItems )
            // The most number of items that can be held
            // on the stack.
{
    // Save the buffer address in the Stack record.
    S->ItemData = ItemData;
    
    // Set the maximum valid limit for the stack index.
    S->MaxIndex = (s32) MaxItems;
    
    // Mark the stack as statically allocated.
    S->IsStorageOwned = 0;

    // Reset to the stack to the empty condition.
    ResetStack(S);
}

/*------------------------------------------------------------
| ResetStack
|-------------------------------------------------------------
|
| PURPOSE: To set a stack to it's initial, empty condition.
|
| DESCRIPTION:
|
| EXAMPLE:  ResetStack(MyStack);
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 01.03.93 
|
------------------------------------------------------------*/
void
ResetStack( Stack* AStack )
{
    AStack->StackIndex = 0;
}

/*------------------------------------------------------------
| Pull
|-------------------------------------------------------------
|
| PURPOSE: To pull the top item from the given stack.
|
| DESCRIPTION:
|
| EXAMPLE:  a = Pull(MyStack);
|
| NOTE: 
|
| ASSUMES: There is a number to pull. 
|
| HISTORY: 01.03.93 
|          12.23.96 Added underflow check.
|
------------------------------------------------------------*/
u32
Pull( Stack* S )
{
    u32 n;
    
    S->StackIndex--;

    // Test for underflow.
    if( S->StackIndex < 0 ) 
    {
        Debugger();
    }

    n = S->ItemData[S->StackIndex];
        
    return( n );
}

/*------------------------------------------------------------
| Push
|-------------------------------------------------------------
|
| PURPOSE: To push an item to the given stack.
|
| DESCRIPTION: 
|
| EXAMPLE:  a = Push(MyStack,(u32) 123);
|
| NOTE: 
|
| ASSUMES: Room to push the number.
|
| HISTORY: 01.03.93 
|          12.23.96 inc stack index after item pushed.
|                   Added overflow check.
------------------------------------------------------------*/
void
Push( Stack* S, u32 n )
{
    S->ItemData[S->StackIndex] = n;
    
    S->StackIndex++;
    
    if( S->StackIndex >= S->MaxIndex ) 
    {
        Debugger();
    }
}

