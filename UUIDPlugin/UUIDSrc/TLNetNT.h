/*------------------------------------------------------------
| TLNetNT.h
|-------------------------------------------------------------
|
| PURPOSE: To provide TCP/IP network access for NT.
|
| DESCRIPTION: 
|        
|
| NOTE: 
|
| HISTORY: 08.17.00 From TLNetAccess.h.
------------------------------------------------------------*/

#ifndef _TLNETNT_
#define _TLNETNT_

// From MacTypes.h
//
// noErr OSErr: function performed properly - no error
#define noErr       0 

// From WinSock2.h.
//
// WinSock 2 extension -- manifest constants for shutdown().
//
#define SD_RECEIVE  0x00
#define SD_SEND     0x01
#define SD_BOTH     0x02

// Error codes
#define CantOpenStream          101
#define CantBindStream          102

//  Constants. 

#define SizeOfStreamDataBuffer          (4*1024)          
#define SizeOfHalfOfStreamDataBuffer    (SizeOfStreamDataBuffer/2) 

#define SizeOfChunkToTransfer           (4*1024)
        // The most that can be sent or received
        // during any pass through the net idle 
        // loop.
        //
        // This keeps any one stream from hogging.

typedef struct ASocket          ASocket;
typedef struct Stream           Stream;
typedef struct InternetAddress  InternetAddress;
 
/*------------------------------------------------------------
| InternetAddress
|-------------------------------------------------------------
| 
| PURPOSE: To specify a fully qualified internet address.
|
| DESCRIPTION: 
|
| HISTORY: 08.21.00 From OpenTransport.h.
------------------------------------------------------------*/
struct InternetAddress
{
    u32 HostAddress;    // Host address 
    u16 PortNumber;     // Port number 
};

/*------------------------------------------------------------
| Networking Constants
|-------------------------------------------------------------
| 
| PURPOSE: To identify names of networking elements with 
|          numbers.
|
| DESCRIPTION: 
|
| HISTORY: 09.24.00 
------------------------------------------------------------*/
enum
{
    ABORT,
    ABORTING,
    ACCEPT,
    ACCEPTING,
    BIND,
    BLOCKING,
    BOUND,
    CONNECT,
    CONNECTED, 
    DISCONNECT,
    FEMALE, 
    INITIALIZE,
    INITIALIZED,  
    INVALID_STATE, 
    LISTEN,
    LISTENING,
    MALE, 
    NONBLOCKING,
    NOP,
    RECEIVE,
    SEND,
    SEND_AND_RECEIVE,
    SET_BLOCKING_MODE,
    RECEIVING, 
    DISCONNECTING,
    TCP, 
    UDP, 
    UNINITIALIZE,   
    UNINITIALIZED,  
    WAIT 
};
    
/*------------------------------------------------------------
| ASocket
|-------------------------------------------------------------
| 
| PURPOSE: To hold information about a network socket in an 
|          operating context.
|
| HISTORY: 08.26.00 From OpenTransport.h.
------------------------------------------------------------*/
struct ASocket 
{                                   
    Stream* OfStream;
    // The stream of which this socket is a part.
    //
    InternetAddress LocalAddress;                           
    // IP address and port on local host.
    //                                     
    InternetAddress RemoteAddress; 
    // IP address and port on remote host.
    //
    SOCKET S;
    // The OS handle for the socket, or zero if there is no 
    // valid OS socket.
    //
    u8 Protocol;
    // The communication protocol used for the socket, one 
    // of these values:
    // 
    //      UDP 
    //      TCP 
    //
    u8 ConnectionLogic;     
    // There are two ways of establishing a connection in 
    // the internet protocol: 
    //                                                         
    //      FEMALE 
    //      MALE 
    //
    u8 BlockingMode;
    // One of these types:
    //
    //      BLOCKING 
    //      NONBLOCKING
    //
    u8 State;
    // The current state of this socket, one of these values:
    //                                                         
    //      UNINITIALIZED   
    //      INITIALISED   
    //      BOUND 
    //      LISTENING 
    //      ACCEPTING 
    //      CONNECTED  
    //      SEND 
    //      RECEIVE 
    //      SEND_AND_RECEIVE
    //      DISCONNECTING 
    //      ABORTING 
    //      INVALID_STATE 
    //
    u8 GoalState;
    // The state to which this socket is tending, one of 
    // these values:
    //
    //      SEND 
    //      RECEIVE 
    //      SEND_AND_RECEIVE
    //
    u8 LastFunction;
    // The last function, one of these:
    //
    //      NOP 
    //      WAIT  
    //      INITIALIZE 
    //      UNINITIALIZE 
    //      BIND 
    //      LISTEN 
    //      ACCEPT 
    //      RECIEVE 
    //      DISCONNECT 
    //      ABORT 
    //
    s32 LastResult;                                          
    // The return value of the last function call or
    // SOCKET_ERROR meaning that the value in LastError
    // is valid. 
    //                                                         
    s32 LastError; 
    // If there was a function error then this field holds 
    // the specific error code. 
    //
    u32 WasDataRead;                
    // 1 if data was read from the socket on the last attempt  
    // or 0 if not.    
    //  
    s64 BytesToRead;
    // Total number of bytes that should be read from this
    // socket if blocking mode is used.
    //
    s64 BytesReadSoFar;
    // Number of bytes read so far.
    //
    s64 BytesToSend;
    // Total number of bytes that should be sent through this
    // socket. 
    //
    s64 BytesSentSoFar;
    // Number of bytes sent so far.
    //
};

/*------------------------------------------------------------
| Stream
|-------------------------------------------------------------
| 
| PURPOSE: All information about a specific stream.
|
| DESCRIPTION: A "stream" in this context is a combination of
| a network socket, state information and data structures.
| 
| ASSUMES: Only TCP data reception needs to be supported.
|
| HISTORY: 08.21.00 From OpenTransport.h.
------------------------------------------------------------*/
struct Stream 
{                                   
    ASocket LinkSocket;                                       
    // The socket to use for making the first connection. 
    //                                     
    ASocket DataSocket;                 
    // The socket to use for data transfer. 
    //                 
    u8 IsLinkSocketUsedForData;  
    // There are two ways of completing a stream connection: 
    //         
    //  0 - Data should be sent through a socket other than  
    //      the link socket.      
    //                                
    //  1 - Data should be sent through the same socket that 
    //      the initial contact is made.  
    //                
    u8 IsActive; 
    // There are two ways to operate a data stream:  
    //                            
    // 0 - Inactive - don't do anything.                   
    //                                           
    // 1 - Active - do something. 
    //  
    u8 ConnectionLogic;     
    // There are two ways of establishing a connection
    // in the internet protocol:  
    //
    //  FEMALE - listen for an incoming connection request -- 
    //      this is the logical female mode, symbolized with 
    //      the value 0.
    // 
    //  MALE - initiate a connection to a remote end point 
    //      that is listening for a connection request -- this 
    //      is the logical male mode, designated with a 1.
    //
    u8 BlockingMode;
    // One of these types:
    //      
    //  NONBLOCKING - Initiate a process that might take more 
    //      time to complete than the time taken by the 
    //      procedure that starts the process.  
    //                                     
    //  BLOCKING - Wait until the underlying network function 
    //      completes.
    //
    u8 Protocol;
    // The communication protocol used for the socket, one 
    // of these values:
    // 
    //      UDP 
    //      TCP 
    //
    u8 Direction;
    // Data flow direction, one of these values:
    //
    //      SEND
    //      RECEIVE
    //      SEND_AND_RECEIVE
    //      
    u8 State;
    // There are several stream operating states one of 
    // these:
    //                      
    //      UNINITIALIZED 
    //      INITIALISED   
    //      BOUND 
    //      LISTENING 
    //      ACCEPTING 
    //      CONNECTED 
    //      SEND 
    //      RECEIVE 
    //      SEND_AND_RECEIVE
    //      DISCONNECTING 
    //      ABORT 
    //      INVALID_STATE 
    //
    u8 GoalState;
    // The state to which this stream is tending, one of 
    // these values:
    //
    //      UNINITIALIZED 
    //      INITIALISED   
    //      BOUND 
    //      LISTENING 
    //      ACCEPTING 
    //      CONNECTED 
    //      SEND 
    //      RECEIVE 
    //      SEND_AND_RECEIVE
    //      DISCONNECTING 
    //      ABORT 
    //      INVALID_STATE 
    //
    u8 IsStreamClosing;                                       
    // 1 if this stream is in the process of closing, that 
    // is, going out of existence.  
    //
    // This is not to be confused with just disconnecting a 
    // TCP connection: the stream would continue to exist 
    // in that case.
    //           
    u8 IsConnected; 
    // True if the stream is connected to the remote host. 
    //                                                   
    u8 IsConnecting;
    // Status flag set to 1 if a connection to the host is in 
    // the process of being completed, or 0 if no connection 
    // is being made.
    //    
    s32 BytesToRead;    
    // Number of bytes in the IncomingData buffers that can  
    // be read by the application. 
    //      
    s32 BytesToSend;    
    // Number of bytes in the OutgoingData buffers that can  
    // be sent by the application. 
    //      
    f64 InputTimeOut; 
    // The maximum number of seconds to wait between 
    // incoming bytes before closing the socket. 
    //
    // This only applies once data has been received for the
    // first time. 
    //      
    f64 LastInputTime; 
    // The time in seconds when the most recent input was    
    // received  based on the ReadTimeStampInSeconds() 
    // clock. 
    //         
    s64 TotalBytesReceived; 
    // Total number of bytes received on stream. 
    //
    f64 OutputTimeOut; 
    // The maximum number of seconds to wait between 
    // outgoing bytes before closing the socket. 
    //
    // This only applies once data has been sent for the
    // first time. 
    //      
    f64 LastOutputTime; 
    // The time in seconds when the most recent output was    
    // sent based on the ReadTimeStampInSeconds() clock. 
    //
    List* IncomingData;      
    // A list of incoming data buffers.  
    //
    // Each buffer is the same size, and the first buffer 
    // in list came in first, the next one next and so on.
    //  
    // These buffers are produced by the async function and 
    // consumed as they are read by the application. 
    //                       
    List* OutgoingData;      
    // A list of outgoing data buffers.  
    //
    // Each buffer is the same size, and the first buffer 
    // in list goes out first, the next one next and so on.
    //  
    // These buffers are produced by the application and
    // are consumed as they are sent by the async function. 
    //                       
};

extern u8 IsNetworkActivityLogged;  
// Control flag:
//
//  0 - network activity should not be logged to the 
//      application log.
//
//  1 - network activity should be logged to the 
//      application log.

extern u8 IsAsynchronousNetOperationsEnabled; 
// Control flag:
//
//  0 - network idle functions are turned off.
//
//  1 - network idle functions are turned on.
 
extern u8 IsNetworkAccessSetUp;     
// Status flag:
//
//  0 - the application network driver is not set up. 
//
//  1 - the application network driver is set up.
 
extern u8 IsNetworkConnected;
// Status flag:
//
//  0 - the general link between the application program
//      and the OS network driver is not connected. 
//
//  1 - the general link between the application program
//      and the OS network driver is connected. 

extern List* TheStreamList;  
// The list of all streams that are registered with Open 
// Transport and therefore must be unregistered when we 
// finish with them.
 
extern f64 TimeWhenDataWasLastReceivedOnAnyStream;
// The last input time for the network connection in general.
// Units are seconds and the timebase is the CPU timestamp
// register.
//
// Used to detect a broken general network connection.
                                
extern f64 MaximumTimeBetweenIncomingDataOnAnyStream; 
// Assuming that if any network connection is active and 
// operating normally then at least some data should be 
// coming in once in a while.
//
// MaxIncomingDataGapInSeconds defines the point beyond 
// which the general network connection can be considered 
// lost, possibley triggering a general network reset.
//
// Units are seconds and the timebase is the CPU timestamp 
// register.

void    AbortSocket( ASocket* );
void    AbortTCPConnection( Stream* );
void    AllocateOTBuffersForStream( Stream* );
void    BindSocket( ASocket* );
void    BindSocketsOfStream( Stream* );
//s32       BindStreamToLocalPort( Stream*, u32, u16, u32 );
void    CleanUpNetAccess();
void    CloseSocket( ASocket* );
void    CloseStreamSocket( ASocket* );
void    CloseTCPConnection( Stream* );
void    CloseTCPStream( Stream* );
u32     ConnectToNetwork();
s32     CountConnectionsToHost( InternetAddress* );
void    DeleteStream( Stream* );
s32     DisableTCPSocket( Stream* );
s32     EnablePassiveTCPConnection( Stream* );
s32     GetSocketState( Stream* );
Item*   GetIncomingDataFromStream( Stream* );
void    InitializeSocket( Stream*, ASocket*, u32, u32 );
void    InitializeSocketsOfStream( Stream* );
void    InitializeStream( Stream*, u32, u32, u32, u32, u32, u32, u32 );
u32     IsIncomingDataLate();
u32     IsOpenTransportAvailable();
void    LogSocketState( Stream* );
void    LogNet( Stream*, s8, s8* );
Stream* MakeStream();
void    NoticeIncomingData();
u32     OnAcceptError( Stream* );
u32     OnBindError( ASocket* );
u32     OnListenError( Stream* );
u32     OnRecvError( Stream* );
s32     OpenActiveTCPConnection( Stream*, u32, u16 );
s32     OpenStreamSocketAsTCP( Stream* );
s32     OpenTCPStream( u32, u16, Stream** );
void    SetBlockingMode( ASocket* A, u32 );
void    PutOutgoingDataIntoStream( Stream*, u8*, s32 );
void    ReceiveDataViaTCPConnection( Stream*, u8*, s32 );
void    RequestBindStreamToLocalPort( Stream*, u32, u16, u32 );
s32     RequestOpenStreamSocketAsTCP( Stream* );
s32     SendDataViaTCPConnection( Stream*, u8*, s32 );
void    SetUpNetAccess( u32, f64 );
void    ShutdownSocket( ASocket* );
void    StreamNotifier( Stream*, u32, s32, void* );
void    UnbindStreamSocket( Stream* );
void    WaitForPassiveTCPConnection( Stream* );
s32     WaitForStreamOperation( Stream* );

#endif // _TLNETNT_
