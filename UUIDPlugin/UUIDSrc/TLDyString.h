/*------------------------------------------------------------
| TLDyString.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for control of dynamically 
|          allocated, zero-terminated strings.
|
| DESCRIPTION:  
|
| NOTE: See 'BString.c' for strings prefixed with a count byte.
|       See 'Parse.h' for string parsing functions.
|       See 'Strings.c' for static string functions.
| 
| HISTORY: 12.11.93 
|          01.21.94 added '#include <MemAlloc.h>'
|          08.19.97 added C++ support.
------------------------------------------------------------*/
    
#ifndef TLDYSTRING_H
#define TLDYSTRING_H

#ifdef __cplusplus
extern "C"
{
#endif
 
extern Lot* TheStringPool;
                // The allocation pool from which all data
                // in dynamic string functions is allocated.


s8* AllocateString( u32 );
s8* DuplicateString( s8* );
s8* LeftString( s8*, u32 );
s8* MidString( s8*, u32, u32 );
s8* RightString( s8*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
