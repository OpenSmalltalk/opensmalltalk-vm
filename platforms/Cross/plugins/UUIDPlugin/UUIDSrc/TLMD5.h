/*------------------------------------------------------------
| TLMD5.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to MD5 functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 
------------------------------------------------------------*/

#ifndef _TLMD5_H_
#define _TLMD5_H_


#ifdef __cplusplus
extern "C"
{
#endif

/*------------------------------------------------------------
| MD5Context
|-------------------------------------------------------------
|
| PURPOSE: To hold the state of an MD5 process.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 01.14.99
------------------------------------------------------------*/
typedef struct

{
    u32 buf[4];
    u32 bits[2];
    u8  in[64];
} MD5Context;

void    MD5Final( MD5Context*, u8* );
void    MD5Init( MD5Context* );
void    MD5Print( u8* );

void    MD5String( s8* );
void    MD5TestSuite();
void    MD5Transform( u32*, u32* );
void    MD5Update( MD5Context*, u8*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLMD5_H_
