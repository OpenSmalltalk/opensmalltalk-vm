/*------------------------------------------------------------
| TLNetAsyncNT.h
|-------------------------------------------------------------
|
| PURPOSE: To provide access to the network periodic 
|          functions.
|
| DESCRIPTION: 
|        
|
| NOTE: 
|
| HISTORY: 12.10.96
------------------------------------------------------------*/

#ifndef __NETASYNC__
#define __NETASYNC__

void    BindPendingStreams();
void    ClosePendingStreams();
void    CompletePendingActiveConnections();
void    DoPendingNetworkOperations( f64 );
void    DoSomeWorkForStream( Stream*, f64 );
void    HandleAsynchronousNetworkOperations( f64 );
void    MakePendingConnectionForStream( Stream* );
void    OpenPendingStreams();
void    OperateStream( Stream*, f64 );
void    OperateStreamUntilTimeLimit( Stream*, f64 );
void    OperateStreamWithoutBlocking( Stream* );
void    ReadSomePendingDataForStream( Stream*, f64 );
void    ReceiveAllPendingDataForStream( Stream* );
void    ReceiveAndSendPendingDataForAllStreams();
void    ReceiveSomePendingDataForStream( Stream* );
void    SendSomePendingDataForStream( Stream*, f64 );
void    UnbindPendingStreams();

#endif
