/*------------------------------------------------------------
| NAME: Notifier.h
|-------------------------------------------------------------
|
| PURPOSE: To provide access to the network notifier functions.
|
| DESCRIPTION: 
|        
|
| NOTE: 
|
| HISTORY: 12.10.96
------------------------------------------------------------*/

#ifndef __NOTIFIER__
#define __NOTIFIER__

s8*     ConvertNotifierEventCodeToName( s32 );
void    On_T_ACCEPTCOMPLETE( Stream* );
void    On_T_BINDCOMPLETE( Stream* );
void    On_T_CONNECT( Stream* );
void    On_T_DATA( Stream* );
void    On_T_DISCONNECT( Stream* );
void    On_T_DISCONNECTCOMPLETE( Stream* );
void    On_T_EXDATA( Stream* );
void    On_T_GODATA( Stream* );
void    On_T_LISTEN( Stream* );
void    On_T_OPENCOMPLETE( Stream* );
void    On_T_OPTMGMTCOMPLETE( Stream* );
void    On_T_ORDREL( Stream* );
void    On_T_PASSCON( Stream* );
void    On_T_UNBINDCOMPLETE( Stream* );

pascal 
void    StreamNotifier( Stream*, OTEventCode, 
                        OTResult, void* );
 
#endif
