/*------------------------------------------------------------
| FILE NAME: NetIdle.h
|-------------------------------------------------------------
|
| PURPOSE: To provide access to the network periodic functions.
|
| DESCRIPTION: 
|
| HISTORY: 12.10.96
------------------------------------------------------------*/

#ifndef __NETIDLE__
#define __NETIDLE__

void    AcceptPendingPassiveConnections();
void    AcknowledgePendingDisconnectRequests();
void    BindPendingStreams();
void    ClosePendingStreams();
void    CompletePendingActiveConnections();
void    ManagePendingDNSRequests();
void    ManagePendingHTTPRequests();
void    NetIdle();
void    OpenPendingStreams();
void    ReceiveAllPendingDataForStream( Stream* );
void    ReceiveAndSendPendingDataForAllStreams();
void    ReceivePendingDataForAllStreams();
void    ReceiveSomePendingDataForStream( Stream* );
void    SendSomePendingDataForStream( Stream* );
void    UnbindPendingStreams();

#endif
