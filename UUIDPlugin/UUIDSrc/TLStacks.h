/*------------------------------------------------------------
| TLStacks.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to stack system functions.
|
| DESCRIPTION: A list of extern prototypes in #include-able 
|              format.
|
| NOTE:  
|
| HISTORY: 02.03.93  from stacks.h.
|          01.03.94 revised
|          01.21.94 added '#include <MemAlloc.h>'
|          08.19.97 added C++ support.
|          06.14.01 Added static stack option.
------------------------------------------------------------*/

#ifndef TLSTACKS_H
#define TLSTACKS_H

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct StackRecord
{
    s32     StackIndex; // Ranges from 0 to MaxIndex-1.
    s32     MaxIndex;   // Overflow if reaches this index.
    u32*    ItemData;
    u32     IsStorageOwned;
                // Configuration flag set to 1 if the stack
                // storage area is dynamically allocated by
                // MakeStack or 0 if not.
} Stack;

extern Lot* TheStackPool;
                // The allocation pool from which all data
                // in stack functions is allocated.

void    DeleteStack( Stack* );
u32     GetItemOnStack( Stack*, u32 );
u32     GetStackItemCount( Stack* );
u32     GetTopItem( Stack* );
Stack*  MakeStack( u32 );
void    MakeStaticStack( Stack*, u32*, u32 );
void    ResetStack( Stack* );
u32     Pull( Stack* );
void    Push( Stack*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLSTACKS_H
