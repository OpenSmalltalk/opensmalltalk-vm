/*------------------------------------------------------------
| TLNetAccess.h
|-------------------------------------------------------------
|
| PURPOSE: To provide TCP/IP network access.
|
| DESCRIPTION: 
|        
|
| NOTE: 
|
| HISTORY: 11.22.96 from 'net.h', part of the 'NewsWatcher' 
|                   source.  Pulled out MacTCP support to rely 
|                   entirely on Open Transport.
------------------------------------------------------------*/

#ifndef _TLNETACCESS_
#define _TLNETACCESS_

#include "TLStrings.h"

// TCP/IP port identifiers: 

#define kFTPPort    21
#define kSMTPPort   25
#define HTTPPort    80
#define kNNTPPort   119

// Error codes
#define netOpenDriverErr        100
#define CantOpenStream          101
#define CantBindStream          102
#define CantConnectStream       103
#define netLostConnectionErr    104
#define netDNRErr               105
#define netTruncatedErr         106
#define WrongStreamState        107

//  Constants. 

#define SizeOfStreamDataBuffer          (4*1024)          
#define SizeOfHalfOfStreamDataBuffer    (SizeOfStreamDataBuffer/2) 

#define SizeOfChunkToTransfer           (4*1024)
                                    // The most that can be sent or received
                                    // during any pass through the net idle loop.
                                    // This keeps any one stream from hogging.
// Endpoint process codes:  
#define EndpointIsOpening       0   // Assigning a protocol in OT.
#define EndpointIsListening     1   // Passively listening for connection.
#define EndpointIsConnecting    2   // Either accepting or initiating connection.
#define EndpointIsWaiting       3   // Waiting for a new process to start.
#define EndpointIsDisconnecting 4   // Tearing down the connection.


// All information about a specific stream.
typedef struct Stream 
{                                   
    EndpointRef EndPt;              // Reference to Open Transport endpoint
                                    //
    u32         IsPassive;          // 1 if this is a passive endpoint;
                                    // 0 if this is an active endpoint.
                                    // Set this flag before listening or
                                    // connecting.
                                    //
    u32         IsHandOffIncomingConnection; // 1 if incoming connection
                                    // requests should be handed off to 
                                    // other dynamically created streams.
                                    //
    u32         IsStreamClosing;    // 1 if this stream is in the process
                                    // of closing, that is, going out of 
                                    // existence.  This is not to be confused
                                    // with just disconnecting a TCP connection: 
                                    // the stream will continue to exist in that 
                                    // case.
                                    //
    u32         IsBindPending;      // 1 if the endpoint remains to be bound.
                                    //
    u32         IsUnbindPending;    // 1 if the endpoint remains to be unbound.
                                    //
    u32         IsActiveConnectionPending; // 1 if an active connection remains 
                                    // to be made.
                                    //
    u32         IsConnectAckPending; // 1 if the remote host as requested 
                                    // a connect which we have not yet 
                                    // acknowledged.
                                    //
    u32         IsDisconnectAckPending; // 1 if the remote host as requested 
                                    // an orderly disconnect which we have not 
                                    // yet acknowledged.
                                    //
    u32         IsOptionRequestPending; // 1 if an endpoint option is being 
                                    // changed.
                                    //
    s32         Process;            // Endpoint process codes, see above.
                                    // 
    InetAddress LocalAddress;       // IP address and port on local host that is 
                                    // actually connected to the remote host. 
                                    //
    InetAddress LocalAddressRequest; // IP address and port on local host that is 
                                    // requested by remote host during connection.
                                    //
    InetAddress RemoteAddress;      // IP address and port on remote host that is 
                                    // actually connected to the local host. 
                                    //
    InetAddress RemoteAddressRequest; // IP address and port on remote host that is 
                                    // requested by local host during connection.
                                    //
    u32         IsIncomingData;     // 1 if there is incoming data pending to
                                    // be read into the data buffers.  The data may
                                    // be normal or expedited.
                                    //
                                    // This is set by the notifier and cleared by
                                    // the net idle function.
                                    //
    List*       IncomingData;       // List of incoming data buffers.  Each buffer
                                    // is the same size and the first buffer in 
                                    // list came in first, the next one next and 
                                    // so on.  These buffers are produced by the
                                    // idle function and consumed as they are
                                    // read by the application.
                                    //
    s32         BytesToRead;        // Number of bytes in the 'IncomingData' buffers 
                                    // that can be read by the application.
                                    //
    List*       IncomingExpeditedData; // List of incoming data buffers.  Each buffer
                                    // is the same size and the first buffer in 
                                    // list came in first, the next one next and 
                                    // so on.  These buffers are produced by the
                                    // idle function and consumed as they are
                                    // read by the application.
                                    //
    s32         ExpeditedBytesToRead; // Number of expedited bytes in the buffers 
                                    // that can be read by the application.
                                    //
    List*       OutgoingData;       // List of outgoing data buffers.  Each buffer
                                    // is the same size and the first buffer in 
                                    // list will be sent first, the next one next 
                                    // and so on.   These buffers are produced by 
                                    // the application and consumed as they are 
                                    // sent by the idle function.
                                    //
    s32         BytesToSend;        // Number of bytes in the buffers that remain
                                    // to be sent by the application.
                                    //
    s32         HaltSendUntil;      // Tick count after which it is OK to send
                                    // data.  This is set when attempting to send
                                    // and an 'kOTFlowErr' occurs.  It is cleared
                                    // by the notifier on 'T_GODATA'.
                                    //
    CStr255     LastCommandSent;    // Last command sent on stream
                                    //
    CStr255     LastResponseReceived; // Last response received on stream
                                    //
    s32         ResponseCode;       // Last response code received on stream 
                                    //
    s32         TotalBytesReceived; // Total number of bytes received on stream
                                    //
    s32         TotalBytesSent;     // Total number of bytes sent on stream 
                                    //
    List*       NotifierEvents;     // List of all notifier events received.
                                    // Item fields are used to hold the event
                                    // parameters:
                                    //
                                    //  NotifierEventCode in 'SizeOfData'
                                    //
                                    //  NotifierEventResult in 'SizeOfBuffer'
                                    //
                                    //  NotifierEventCookie in 'DataAddress'
                                    //
                                    //  TickCount() in 'BufferAddress'
                                    //
    OTEventCode NotifierEventCode;  // Event code of last notifier event
                                    //
    OTResult    NotifierEventResult;// Result code of last notifier event
                                    //
    void*       NotifierEventCookie;// 'Cookie' parameter of last notifier event
                                    //
    TCall*      InCall;             // Address of incoming call structure
                                    //
    TCall*      OutCall;            // Address of outgoing call structure
                                    //
    TBind*      BindRequest;        // Address of bind request structure
                                    //
    TBind*      BindResult;         // Address of bind return structure
                                    //
    TOptMgmt    OptReq;             // Option management request structure
                                    //
    TOptMgmt    OptRet;             // Option management result structure
                                    //
    TOption*    opt;                // Option request buffer created using 'malloc'.
                                    //  
    TOption*    optret;             // Option result buffer created using 'malloc'.
} Stream;

typedef struct NetServerErrInfo 
{
    CStr255 command;
    CStr255 response;
    s32     ResponseCode;
} NetServerErrInfo;

// Global variables.

extern u32      OpenTransportIsAvailable;   // 1 if Open Transport is installed
                                            // on the computer.
                                            //
extern u32      IsOpenTransportSetUp;       // 1 if Open Transport has been 
                                            // set up for use.
                                            //
extern u32      IsNetworkActivityLogged;    // 1 if network activity should be
                                            // sent to the application log.
                                            //
extern List*    StreamsRegisteredWithOT;    // The list of all streams that are
                                            // registered with Open Transport and
                                            // therefore must be unregistered
                                            // when we finish with them.
                                            //
extern List*    ClosingStreams;             // The list of all streams that are
                                            // being closed and discarded.
                                            // 
extern List*    OpeningStreams;             // The list of all streams that are
                                            // being opened within OT as TCP
                                            // protocol endpoints.
                                            //
extern List*    BindingStreams;             // The list of all streams that are
                                            // being bound to local protocol
                                            // addresses.
                                            //
extern u32      IsNetIdleEnabled ;          // This turns net idle functions on and off.
    
extern s32      TickWhenDataWasLastReceived;// The value of TickCount() when data was
                                            // last received. Used to detect a broken 
                                            // modem connection.
                                
extern s32      MaximumTicksBetweenIncomingData; // The longest period of time that is
                                            // allowed between incoming data, in ticks.
                                            // Used to detect a broken modem connection.                                
// Prototypes.

void    AbortTCPConnection( Stream* );
void    AllocateOTBuffersForStream( Stream* );
OSErr   BindStreamToLocalPort( Stream*, u32, u16, u32 );
void    CleanUpNetAccess();
OSErr   CloseStreamEndpoint( Stream* );
void    CloseTCPConnection( Stream* );
void    CloseTCPStream( Stream* );
s32     CountConnectionsToHost( InetAddress* );
void    DeleteStreamBuffer( Stream* );
OSErr   DisableTCPEndpoint( Stream* );
OSErr   EnableKeepAlive( Stream* );
OSErr   EnablePassiveTCPConnection( Stream* );
s32     GetEndpointState( Stream* );
Item*   GetIncomingDataFromStream( Stream* );
u32     IsIncomingDataLate();
u32     IsOpenTransportAvailable();
void    LogEndpointState( Stream* );
void    LogNet( Stream*, s8, s8* );
Stream* MakeStreamBuffer();
void    NoticeIncomingData();
OSErr   OpenActiveTCPConnection( Stream* , u32, u16 );
OSErr   OpenStreamEndpointAsTCP( Stream* );
OSErr   OpenTCPStream( u32, u16, Stream** );
void    PutOutgoingDataIntoStream( Stream*, u8*, s32 );
s32     ReceiveDataViaTCPConnection( Stream*, u8*, s32 );
OSErr   RequestBindStreamToLocalPort( Stream*, u32, u16, u32 );
void    RequestKeepAlive( Stream* );
OSErr   RequestOpenStreamEndpointAsTCP( Stream* );
OSErr   SendDataViaTCPConnection( Stream*, u8*, s32 );
OSErr   SetUpNetAccess( u32  , s32 );
               
pascal
void    StreamNotifier( Stream*, OTEventCode, OTResult, void* );

void    UnbindStreamEndpoint( Stream* );
void    WaitForPassiveTCPConnection( Stream* );
OSErr   WaitForStreamOperation( Stream* );

#endif // _TLNETACCESS_
