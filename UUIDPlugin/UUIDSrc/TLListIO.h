/*------------------------------------------------------------
| TLListIO.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for list-to/from-file 
|          procedures.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 
|          12.10.93 
------------------------------------------------------------*/
    
#ifndef _LISTIO_H_
#define _LISTIO_H_

#define MaxLineBuffer   4096

List*   ReadListOfTextLines( s8* );
void    WriteListOfTextLines( s8*, List*, s8* );

#endif
