/*------------------------------------------------------------
| TLMemOS.h
|-------------------------------------------------------------
|
| PURPOSE: To provide an interface to OS-specific, 
|          fixed-location memory block allocation functions.
|
| DESCRIPTION:  
|
| HISTORY: 05.27.01 TL From TLMem.h.
------------------------------------------------------------*/

#ifndef TLMEMOS_H
#define TLMEMOS_H

#ifdef __cplusplus
extern "C"
{
#endif
 
void*   AllocateMemoryOS( u32 );
void    FreeMemoryOS( void* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLMEMOS_H
