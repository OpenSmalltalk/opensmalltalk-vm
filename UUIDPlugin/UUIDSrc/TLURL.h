/*------------------------------------------------------------
| FILE NAME: TLURL.h
|
| PURPOSE: To provide interface for URL parsing procedures.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 12.12.96
------------------------------------------------------------*/
    
#ifndef _URL_H_
#define _URL_H_

/* -------------------PROTOTYPES----------------------------- */

u32     IsSchemeHTTP( s8* );
s32     ParseDomainNameFromURL( s8*, s8* );
s32     ParseURL( s8*, s8*, s8*, s8*, s8*, s8*, s8* );

#endif
