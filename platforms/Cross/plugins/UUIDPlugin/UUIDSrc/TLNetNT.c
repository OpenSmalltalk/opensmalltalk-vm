/*------------------------------------------------------------
| TLNetNT.c
|-------------------------------------------------------------
|
| PURPOSE: To provide TCP/IP network access for Windows NT.
|
| DESCRIPTION: 
|        
| The following functions handle initialization, idle 
| time, and termination tasks.
|   
|   SetUpNetAccess - Initialize the module.
|
|   DoAsynchronousNetworkOperations - Handle idle time tasks.
| 
|   CleanUpNetAccess - Terminate the module.
|
| A "stream" is an abstraction representing a bidirectional 
| network connection to a net ASCII TCP/IP server. 
| 
| A stream is represented as a variable of type "Stream*". 
|   
| If any error occurs, the stream is aborted before returning 
| to the caller.
|
| "Aborted" means that the server connection is closed 
| abruptly without going through the usual orderly TCP stream 
| teardown process. 
|
| HISTORY: 11.22.96 from 'net.c' written by ? as part of the
|                   'NewsWatcher' source.  Pulled out MacTCP
|                   support to rely entirely on Open 
|                   Transport.
|          08.17.00 From TLNetAccess.c ported to NT.
------------------------------------------------------------*/

#include "TLTarget.h"  

#if defined( FOR_WINNT ) | defined( FOR_WIN98 ) | defined( FOR_WIN2000 ) 

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "TLTypes.h"         
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLList.h"
#include "TLLog.h"

#include "TLNetNT.h"

u8 IsNetworkActivityLogged = 0; 
// Control flag:
//
//  0 - network activity should not be logged to the 
//      application log.
//
//  1 - network activity should be logged to the 
//      application log.

u8 IsAsynchronousNetOperationsEnabled = 0; 
// Control flag:
//
//  0 - network idle functions are turned off.
//
//  1 - network idle functions are turned on.
 
u8 IsNetworkAccessSetUp = 0;        
// Status flag:
//
//  0 - the application network driver is not set up. 
//
//  1 - the application network driver is set up.
 
u8 IsNetworkConnected = 0;
// Status flag:
//
//  0 - the general link between the application program
//      and the OS network driver is not connected. 
//
//  1 - the general link between the application program
//      and the OS network driver is connected. 

List* TheStreamList = 0;  
// The list of all streams that are registered with Open 
// Transport and therefore must be unregistered when we 
// finish with them.
 
f64 TimeWhenDataWasLastReceivedOnAnyStream = 0;
// The last input time for the network connection in general.
// Units are seconds and the timebase is the CPU timestamp
// register.
//
// Used to detect a broken general network connection.
                                
f64 MaximumTimeBetweenIncomingDataOnAnyStream = 10.0; 
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
                                                                
/*------------------------------------------------------------
| AbortSocket
|-------------------------------------------------------------
| 
| PURPOSE: To close a socket returning it to the UNINITIALIZED
|          state.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 09.17.00 from CloseStreamSocket
------------------------------------------------------------*/
void
AbortSocket( ASocket* A )
{
    // Disable sending and receiving.
    ShutdownSocket( A );
    
    // Close the socket.
    CloseSocket( A );
    
    // Mark the endpoint as missing.
    A->S = 0;
    
    // Enter the unitialized state.
    A->State = UNINITIALIZED;
}

/*------------------------------------------------------------
| AbortTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To abortively close a stream connection 
|          asynchronously.
|
| DESCRIPTION:  
|
| This function returns immediately without any delay.
|   
| The state of the endpoint will change to 'T_IDLE' if there
| is no error following 'OTSndDisconnect'.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.05.96
------------------------------------------------------------*/
void 
AbortTCPConnection( Stream* s )
{
    s32 st;
    
    st = GetSocketState( s );
    
    // Make sure the stream is not already disconnected.
//  if( st != T_UNINIT &&
//      st != T_UNBND &&
//      st != T_IDLE )
//  {
        // Set the state to disconnecting.
//      s->Process = SocketIsDisconnecting;
    
        // Send an abortive disconnect.
//      OTSndDisconnect( s->DataSocket, 0 );
        
        // Notifier will handle the rest.
            
        LogNet( s, ' ', (s8*) "Async abortive disconnect started." );
//  }
}

/*------------------------------------------------------------
| AllocateOTBuffersForStream
|-------------------------------------------------------------
| 
| PURPOSE: To allocate the auxillary OT buffers for a stream.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: Sufficent memory to succeed. 
| 
| HISTORY: 12.05.96
------------------------------------------------------------*/
void
AllocateOTBuffersForStream( Stream* s )
{
//  s32 status;
    s = s;
    // Allocate structure used to make a bind request.
//  s->BindRequest = OTAlloc( s->DataSocket, T_BIND, T_ADDR, &status );
        
    // Allocate structure used to receive a reply to a
    // bind request.
//  s->BindResult = OTAlloc( s->DataSocket, T_BIND, T_ADDR, &status );
    
    // Allocate structure used to make incoming connections.
//  s->InCall = OTAlloc( s->DataSocket, T_CALL, T_ADDR, &status );

    // Allocate structure used to make outgoing connections.
//  s->OutCall = OTAlloc( s->DataSocket, T_CALL, T_ADDR, &status );
}

/*------------------------------------------------------------
| BindSocket
|-------------------------------------------------------------
| 
| PURPOSE: To bind a socket to a host address and port number.
|
| DESCRIPTION: This function is non-blocking.
| 
| From MSDN:
|
| "bind -- The Windows Sockets bind function associates a
|  local address with a socket.
|
|  The bind function is used on an unconnected socket before
|  subsequent calls to the connect() or listen() functions.
|  It is used to bind to either connection-oriented (stream)
|  or connectionless (datagram) sockets. When a socket is 
|  created with a call to the socket() function, it exists in
|  a name space (address family), but it has no name assigned
|  to it.  Use bind() to establish the local association of
|  the socket by assigning a local name to an unnamed socket.
|
|  A name consists of three parts when using the Internet
|  address family: the address family, a host address, and a
|  port number that identifies the application.  In Windows
|  Sockets 2, the name parameter is not strictly interpreted
|  as a pointer to a SOCKADDR structure.  It is cast this way
|  for Windows Sockets 1.1 compatibility.  Service Providers
|  are free to regard it as a pointer to a block of memory of
|  size 'namelen'.  The first two bytes of this block 
|  ( corresponding to the sa_family member of the SOCKADDR
|  structure ) must contain the address family that was used
|  to create the socket.  Otherwise, an error WSAEFAULT will
|  occur.
|
|  If an application does not care what local address is
|  assigned, specify the manifest constant value INADDR_ANY for
|  the sa_data field of the name parameter.  This allows the
|  underlying service provider to use any appropriate network
|  address, potentially simplifying application programming
|  in the presence of multihomed hosts (that is, hosts that
|  have more than one network interface and address).
|
|  For TCP/IP, if the port is specified as zero, the service
|  provider will assign a unique port to the application with
|  a value between 1024 and 5000. The application can use
|  getsockname() after bind to learn the address and port
|  that has been assigned to it.  If the Internet address
|  is equal to INADDR_ANY, getsockname() will not necessarily
|  be able to supply the address until the socket is 
|  connected, since several addresses can be valid if the 
|  host is multihomed.   Binding to a specific port number
|  other than port 0 is discouraged for client applications,
|  since there is a danger of conflicting with another socket
|  already using that port number."
|  
| ASSUMES: Any local host address can be used and 
|          LocalLinkAddress.PortNumber is set.
|
| HISTORY: 09.17.00 From Socket_Bind.
------------------------------------------------------------*/
void
BindSocket( ASocket* A )
{
    struct sockaddr_in addr;
    u32                IsInProgress;
    
    // If the socket is in the INITIALIZED state.
    if( A->State == INITIALIZED )
    {
        // Zero out sockaddr structure.
        memset( &addr, 0, sizeof(addr) ); 

        // Set the domain address family.
        addr.sin_family = PF_INET;   
        
        // Set the IP port number, converting port number to
        // network order.
        addr.sin_port = htons( A->LocalAddress.PortNumber );    

        // Use any lock IP host number.
        addr.sin_addr.s_addr = htonl( INADDR_ANY );  

        // Bind the link socket.
        A->LastResult = 
            bind( A->S, 
                    // An unbound socket handle.
                    //
                  (struct sockaddr*) &addr, 
                    // The address to assign the socket from
                    // a SOCKADDR structure.
                    //
                  sizeof(addr) );
                    // Size of the SOCKADDR structure.
                     
        // If there was an error.
        if( A->LastResult == SOCKET_ERROR )
        {
            // If the bind is still in-progress.
            IsInProgress = OnBindError( A );
            
            // If the bind is in-progress.
            if( IsInProgress )
            {
                // Just return.
                return;
            }
            else // A serious error occurred.
            {
                // Revert the socket to the UNINITIALIZED
                // state by closing the socket.
                AbortSocket( A );
            }
        }
        else // No error.
        {
            // Change the current socket state to BOUND.
            A->State = BOUND;
        }
    }
}

/*------------------------------------------------------------
| BindSocketsOfStream
|-------------------------------------------------------------
| 
| PURPOSE: To do some work toward binding all sockets needed 
|          for a stream.
|
| DESCRIPTION: This function is non-blocking.
| 
| ASSUMES: 
| 
| HISTORY: 09.17.00 From InitializeSocketsOfStream
------------------------------------------------------------*/
void
BindSocketsOfStream( Stream* S )
                            // The stream.
{
    ASocket* L;
    ASocket* D;
    
    // Refer to the link socket control block of the stream
    // as 'L'.
    L = &S->LinkSocket;
    
    // Refer to the data socket control block of the stream
    // as 'D'.
    D = &S->DataSocket;
    
    // If the stream is initialized.
    if( S->State == INITIALIZED )
    {
        // If the linkage socket is initialized.
        if( L->State == INITIALIZED )
        {
            // Bind the linkage socket.
            BindSocket( L );
        }
        
        // If the linkage socket will hand off to a 
        // separate data socket.
        if( S->IsLinkSocketUsedForData == 0 )
        {
            // If the data socket is initialized.
            if( D->State == INITIALIZED )
            {
                // Allow any port number to be used for
                // binding the data socket.
                D->LocalAddress.PortNumber = 0;
                
                // Bind the data socket.
                BindSocket( D ); 
            }
        }
                
        // If the linkage socket has been bound.
        if( L->State == BOUND ) 
        {
            // If the linkage socket will be used to carry 
            // the data.
            if( S->IsLinkSocketUsedForData )
            {
                // Then all of the stream sockets are 
                // bound.
                S->State = BOUND;
            }
            else // A separate data socket is used.
            {
                // If the data socket is also bound.
                if( D->State == BOUND )
                {
                    // Then all of the stream sockets are 
                    // bound.
                    S->State = BOUND;
                }
            }
        }
    }
}
 
/*------------------------------------------------------------
| CleanUpNetAccess
|-------------------------------------------------------------
| 
| PURPOSE: To clean up after making network connections.
|
| DESCRIPTION: Call this function when you quit.
|
| This functions waits up to 5 seconds to allow pending
| asychronous operations to complete.
|
| Any open streams are then aborted and all network resources
| are freed.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: All endpoints are TCP.
| 
| HISTORY: 11.19.96 reformatted.
|          12.05.96 revised.
------------------------------------------------------------*/
void 
CleanUpNetAccess()
{
    Stream* S;
    s32     WaitTil;
    
    // If net access was set up.
    if( IsNetworkAccessSetUp ) 
    {
        // If there are any streams known to Open Transport
        // that aren't already closing.
        if( TheStreamList->ItemCount )
        {
            // Begin closing any that aren't already doing
            // so.
            ReferToList( TheStreamList );
            
            while( TheItem )
            {
                S = (Stream*) TheDataAddress;
                
                ToNextItem(); 
                    // Advance here to avoid problems
                    // caused by the following statement
                    // that pulls the stream from the
                    // list.
                
                if( S->IsStreamClosing == 0 )
                {
                    CloseTCPStream( S );
                }
                else
                {
                    Debugger(); 
                    // Should be no closing streams on
                    // this list.
                }
            }
            
            RevertToList();
            
            // Wait up to five seconds or until all streams 
            // have been closed, which ever comes first.
            WaitTil = TickCount() + 300;
    
//          while( TheStreamList->ItemCount &&
//                 TickCount() < WaitTil ) 
            {
//              ProcessPendingEvent();
            }
            
            // Shutdown 'DoAsynchronousNetworkOperations' processing.
            IsAsynchronousNetOperationsEnabled = 0;
            
            // Abort any remaining connections.
//          while( TheStreamList->ItemCount )
            {
//              S = (Stream*) TheStreamList->FirstItem->DataAddress;
                
                // Remove the stream from the 'TheStreamList' list.
//              DeleteAllReferencesToData( TheStreamList, (u8*) S );

                // Close the stream endpoint in Open Transport
                // and remove it from the list of endpoints
                // registered with Open Transport.
//              CloseStreamSocket( S );
                
                // Delete the non-Open Transport part.
                DeleteStream( S );
            }
        
            DeleteList( TheStreamList );
            TheStreamList = 0;
        }
    
//          CloseOpenTransport();
    }
}

/*------------------------------------------------------------
| CloseSocket
|-------------------------------------------------------------
|
| PURPOSE: To release all OS resources tied to a socket.
|
| DESCRIPTION: 
|
| From MSDN network function reference:
|
| "The closesocket() function closes a socket.  Use it to 
|  release a socket descriptor so further references to the 
|  socket will fail with the error WSAENOTSOCK.
|
| If this is the last reference to an underlying socket, the 
| associated naming information and queued data are discarded.  
| Any pending blocking, asynchronous calls issued by any 
| thread in this process are cancelled without posting any 
| notification messages.
|
| Any pending overlapped send and receive operations
| (WSASend/WSASendTo/WSARecv/WSARecvFrom with an overlapped
| socket) issued by any thread in this process are also
| cancelled.  Any event, completion routine, or completion
| port action specified for these overlapped operations
| is performed.  The pending overlapped operations fail
| with the error status WSA_OPERATION_ABORTED.
|
| An application should always have a matching call to 
| closesocket for each successful call to socket() to 
| return any socket resources to the system.
|
| The semantics of closesocket are affected by the socket
| options SO_LINGER and SO_DONTLINGER as follows 
| (SO_DONTLINGER is enabled by default; SO_LINGER is 
| disabled):
|
|    Option        Interval   Type of close   Wait for close?
| ----------------------------------------------------------- 
|  SO_DONTLINGER  Do not care  Graceful          No
|  SO_LINGER      Zero         Hard              No
|  SO_LINGER      Nonzero      Graceful          Yes
| ----------------------------------------------------------- 
|
| If SO_LINGER is set with a zero time-out interval (that is, 
| the LINGER structure members I_onoff is not zero and I_linger 
| is zero), closesocket() is not blocked even if queued data 
| has not yet been sent or acknowledged.  This is called a 
| "hard" or "abortive" close, because the socket's virtual 
| circuit is reset immediately, and any unsent data is lost.  
| Any recv() call on the remote side of the circuit will fail
| with WSAECONNRESET.
|
| If SO_LINGER is set with a nonzero time-out interval on a 
| blocking socket, the closesocket() call blocks on a blocking 
| socket until the remaining data has been sent or until the 
| time-out expires. This is called a graceful disconnect.  If 
| the time-out expires before all data has been sent, the 
| Windows Sockets implementation terminates the connection 
| before closesocket() returns.
|
| Enabling SO_LINGER with a nonzero time-out interval on a 
| nonblocking socket is not recommended.  In this case, the 
| call to closesocket() will fail with an error of 
| WSAEWOULDBLOCK if the close operation cannot be completed 
| immediately.  If closesocket() fails with WSAEWOULDBLOCK the 
| socket handle is still valid, and a disconnect is not 
| initiated.  The application must call closesocket() again
| to close the socket.  Is SO_DONTLINGER is set on a stream 
| socket by setting the I_onoff member of the LINGER structure 
| to zero, the closesocket call will return immediately and 
| does not receive WSAWOULDBLOCK whether the socket is 
| blocking or nonblocking.
|
| However, any data queued for transmission will be sent, if 
| possible, before the underlying socket is closed.  This is 
| also called a graceful disconnect.  In this case, the 
| Windows Sockets provider cannot release the socket and other 
| resources for an arbitrary period, thus affecting applications 
| that expect to use all available sockets.  This is the default 
| behavior (SO_DONTLINGER is set by default).
|
| Note to assure that all data is sent and received on a 
| connection, an application should call shutdown() before 
| calling closesocket() (see Graceful shutdown, linger options 
| and socket closure for more information).  Also note, an 
| FD_CLOSE network event will *not* be posted after 
| closesocket() is called.
|
| Here's a summary of closesocket() behavior:
|
|   * if SO_DONTLINGER enabled (the default setting) it always 
|     returns immediately - connection is gracefully closed
|     "in the background".
|
|   * if SO_LINGER enabled with a zero time-out: it always 
|     returns immediately - connection is reset/terminated.
|
|   * if SO_LINGER enabled with nonzero time-out:
|
|     - with blocking socket it blocks until all data sent or 
|       time-out expires
|
|     - with nonblocking socket it returns immediately 
|       indicating failure.
|
| RETURN VALUES:
|
| If no error occurs, closesocket() returns zero.  Otherwise, 
| a value of SOCKET_ERROR is returned, and a specific error 
| code can be retrieved by calling WSAGetLastError.
|
| ERROR CODES:" [See below.]
|   
| EXAMPLE: 
|
| ASSUMES:  
|
| HISTORY: 09.17.00 From OnBindError
------------------------------------------------------------*/
void         
CloseSocket( ASocket* A )
{
    // Close the network socket.
    A->LastResult = closesocket( A->S ); 
    
    // If there was a closesocket error.
    if( A->LastResult == SOCKET_ERROR )
    {
        A->LastError = WSAGetLastError(); 
            
        // Depending on the result.
        switch( A->LastError )
        {
            case WSANOTINITIALISED:
            {
                // "A successful WSAStartup must occur before
                // using this function."
                Note( "closesocket(): WSANOTINITIALISED\n" );
                
                break;
            }
            
            case WSAENETDOWN:
            {
                // "The network subsystem has failed."
                Note( "closesocket(): WSAENETDOWN\n" );
                
                break;
            }
            
            case WSAENOTSOCK:
            {
                // "The descriptor is not a socket."
                Note( "closesocket(): WSAENOTSOCK\n" );
                
                break;
            }
            
            case WSAEINPROGRESS:
            {
                // "A blocking Windows Sockets 1.1 call is in
                // progress, or the service provider is still
                // processing a callback function."
                Note( "closesocket(): WSAEINPROGRESS\n" );
                
                break;
            }
            
            case WSAEINTR:
            {
                // "The (blocking) Windows Socket 1.1 call was
                // canceled through WSACancelBlockingCall()."
                Note( "closesocket(): WSAEINTR\n" );
                
                break;
            }
            
            case WSAEWOULDBLOCK:
            {
                // "The socket is not connected (connection-
                // oriented sockets only)."
                Note( "closesocket(): WSAEWOULDBLOCK\n" );
                
                break;
            }
        }
    }
}

/*------------------------------------------------------------
| CloseStreamSocket
|-------------------------------------------------------------
| 
| PURPOSE: To close an endpoint for a stream.
|
| DESCRIPTION: Use this procedure to revert from a 
| 'OpenStreamSocketAsTCP' call.  
|
| Any pending operations are canceled.
|
| Not to be confused with closing a stream which means to
| take the stream itself out of existence.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: Socket is currently open but not connected or
|          bound.
| 
| HISTORY: 12.05.96 from 'OpenStreamSocketAsTCP'.
|          08.17.00 Revised for NT.
------------------------------------------------------------*/
void
CloseStreamSocket( ASocket* A )
{
    // If there is an endpoint to close.
    if( A )
    {
        // Disable sending and receiving.
        //
        // From MSDN network function reference:
        //
        // "The shutdown() function is used on all types of
        // sockets to disable reception, transmission, or
        // both.
        //
        // If the how parameter is SD_RECEIVE, subsequent
        // calls to the recv() function on the socket will
        // be disallowed.  This has no effect on the lower
        // protocol layers. For TCP sockets, if there is
        // still data queued on the socket waiting to be
        // received, or data arrives subsequently, the
        // connection is reset, since the data cannot be
        // delivered to the user.  For UDP sockets, incoming
        // datagrams are accepted and queued.  In no case
        // will an ICMP error packet be generated.
        //
        // If the how parameter is SD_SEND, subsequent calls
        // to the send() function are disallowed.  For TCP
        // sockets, a FIN will be sent after all data is
        // sent and acknowledged by the receiver.
        //
        // Setting how to SD_BOTH disables both sends and
        // receives as described above.
        //
        // The shutdown function does not close the socket.
        // Any resources attached to the socket will not
        // be freed until closesocket().
        // 
        // To assure that all data is sent and received on
        // a connected socket before it is closed, an
        // application should use shutdown() to close the
        // connection before calling closesocket().
        //
        // For example, to initiate a graceful disconnect:
        //
        //    1. Call WSAAsyncSelect to register for FD_CLOSE
        //       notification.
        //
        //    2. Call shutdown() with how = SD_SEND.
        //
        //    3. When FD_CLOSE received, call recv until zero
        //       returned, or SOCKET_ERROR.
        //
        //    4. Call closesocket.
        //
        // [Don't follow this recommendation because it relies
        //  on Windows-specific event handling.]
        //
        // Note the shutdown() function does not block
        // regardless of the SO_LINGER setting on the socket.
        //
        // An application should not rely on being able to 
        // re-use a socket after it has been shut down.  In
        // particular, a Windows Sockets provider is not
        // required to support the use of connect() on a 
        // socket that has been shutdown().
        //
        // Return Values:
        // 
        // If no error occurs, shutdown() returns a zero.
        // Otherwise, a value of SOCKET_ERROR is returned,
        // and a specific error code can be retreived by
        // calling WSAGetLastError().
        //
        // Error Codes:" [See below.]
        A->LastResult = shutdown( A->S, SD_BOTH );
        
        // If there was a shutdown error.
        if( A->LastResult  )
        {
            A->LastError = WSAGetLastError(); 
            
            // Depending on the error.
            switch( A->LastError )
            {
                case WSANOTINITIALISED:
                {
                    // "A successful WSAStartup must occur before
                    // using this function."
                    Note( "shutdown(): WSANOTINITIALISED\n" );
                    
                    break;
                }
                
                case WSAENETDOWN:
                {
                    // "The network subsystem has failed."
                    Note( "shutdown(): WSAENETDOWN\n" );
                    
                    break;
                }
                
                case WSAEINVAL:
                {
                    // "The how parameter is not valid, or is not
                    // consistent with the socket type.  For example,
                    // SD_SEND is used with a UNI_RECV socket type."
                    Note( "shutdown(): WSAEINVAL\n" );
                    
                    break;
                }
                
                case WSAEINPROGRESS:
                {
                    // "A blocking Windows Sockets 1.1 call is in
                    // progress, or the service provider is still
                    // processing a callback function."
                    Note( "shutdown(): WSAEINPROGRESS\n" );
                    
                    break;
                }
                
                case WSAENOTCONN:
                {
                    // "The socket is not connected (connection-
                    // oriented sockets only)."
                    Note( "shutdown(): WSAENOTCONN\n" );
                    
                    break;
                }
                
                case WSAENOTSOCK:
                {
                    // "The descriptor is not a socket."
                    Note( "shutdown(): WSAENOTSOCK\n" );
                    
                    break;
                }
            }
            
            return;
        }
 
        // Close the network socket.
        //
        // From MSDN network function reference:
        //
        // "The closesocket() function closes a socket.  Use it
        // to release a socket descriptor so further references
        // to the socket will fail with the error WSAENOTSOCK.
        //
        // If this is the last reference to an underlying
        // socket, the associated naming information and queued
        // data are discarded.  Any pending blocking, asynchronous
        // calls issued by any thread in this process are
        // cancelled without posting any notification messages.
        //
        // Any pending overlapped send and receive operations
        // (WSASend/WSASendTo/WSARecv/WSARecvFrom with an overlapped
        // socket) issued by any thread in this process are also
        // cancelled.  Any event, completion routine, or completion
        // port action specified for these overlapped operations
        // is performed.  The pending overlapped operations fail
        // with the error status WSA_OPERATION_ABORTED.
        //
        // An application should always have a matching call to 
        // closesocket for each successful call to socket() to return
        // any socket resources to the system.
        //
        // The semantics of closesocket are affected by the socket
        // options SO_LINGER and SO_DONTLINGER as follows 
        // (SO_DONTLINGER is enabled by default; SO_LINGER is disabled):
        //
        //    Option        Interval      Type of close     Wait for close?
        // ----------------------------------------------------------------- 
        //  SO_DONTLINGER  Do not care       Graceful            No
        //  SO_LINGER      Zero              Hard                No
        //  SO_LINGER      Nonzero           Graceful            Yes
        // ----------------------------------------------------------------- 
        //
        // If SO_LINGER is set with a zero time-out interval (that is, the
        // LINGER structure members I_onoff is not zero and I_linger is zero),
        // closesocket() is not blocked even if queued data has not yet been
        // sent or acknowledged.  This is called a "hard" or "abortive"
        // close, because the socket's virtual circuit is reset immediately,
        // and any unsent data is lost.  Any recv() call on the remote side
        // of the circuit will fail with WSAECONNRESET.
        //
        // If SO_LINGER is set with a nonzero time-out interval on a blocking
        // socket, the closesocket() call blocks on a blocking socket until
        // the remaining data has been sent or until the time-out expires.
        // This is called a graceful disconnect.  If the time-out expires
        // before all data has been sent, the Windows Sockets implementation
        // terminates the connection before closesocket() returns.
        //
        // Enabling SO_LINGER with a nonzero time-out interval on a nonblocking
        // socket is not recommended.  In this case, the call to closesocket()
        // will fail with an error of WSAEWOULDBLOCK if the close operation
        // cannot be completed immediately.  If closesocket() fails with
        // WSAEWOULDBLOCK the socket handle is still valid, and a disconnect
        // is not initiated.  The application must call closesocket() again
        // to close the socket.  Is SO_DONTLINGER is set on a stream socket
        // by setting the I_onoff member of the LINGER structure to zero,
        // the closesocket call will return immediately and does not receive
        // WSAWOULDBLOCK whether the socket is blocking or nonblocking.
        // However, any data queued for transmission will be sent, if possible,
        // before the underlying socket is closed.  This is also called a
        // graceful disconnect.  In this case, the Windows Sockets provider
        // cannot release the socket and other resources for an arbitrary
        // period, thus affecting applications that expect to use all 
        // available sockets.  This is the default behavior (SO_DONTLINGER is
        // set by default).
        //
        // Note to assure that all data is sent and received on a connection,
        // an application should call shutdown() before calling closesocket()
        // (see Graceful shutdown, linger options and socket closure for more
        // information).  Also note, an FD_CLOSE network event will *not* be
        // posted after closesocket() is called.
        //
        // Here's a summary of closesocket() behavior:
        //
        //   * if SO_DONTLINGER enabled (the default setting) it always 
        //     returns immediately - connection is gracefully closed
        //     "in the background".
        //
        //   * if SO_LINGER enabled with a zero time-out: it always returns
        //     immediately - connection is reset/terminated.
        //
        //   * if SO_LINGER enabled with nonzero time-out:
        //
        //     - with blocking socket it blocks until all data sent or 
        //       time-out expires
        //
        //     - with nonblocking socket it returns immediately indicating
        //       failure.
        //
        // RETURN VALUES:
        //
        // If no error occurs, closesocket() returns zero.  Otherwise, a
        // value of SOCKET_ERROR is returned, and a specific error code can
        // be retrieved by calling WSAGetLastError.
        //
        // ERROR CODES:" [See below.]
        A->LastResult = closesocket( A->S ); 
        
        // If there was a shutdown error.
        if( A->LastResult == SOCKET_ERROR )
        {
            A->LastError = WSAGetLastError(); 
                
            // Depending on the result.
            switch( A->LastError )
            {
                case WSANOTINITIALISED:
                {
                    // "A successful WSAStartup must occur before
                    // using this function."
                    Note( "closesocket(): WSANOTINITIALISED\n" );
                    
                    break;
                }
                
                case WSAENETDOWN:
                {
                    // "The network subsystem has failed."
                    Note( "closesocket(): WSAENETDOWN\n" );
                    
                    break;
                }
                
                case WSAENOTSOCK:
                {
                    // "The descriptor is not a socket."
                    Note( "closesocket(): WSAENOTSOCK\n" );
                    
                    break;
                }
                
                case WSAEINPROGRESS:
                {
                    // "A blocking Windows Sockets 1.1 call is in
                    // progress, or the service provider is still
                    // processing a callback function."
                    Note( "closesocket(): WSAEINPROGRESS\n" );
                    
                    break;
                }
                
                case WSAEINTR:
                {
                    // "The (blocking) Windows Socket 1.1 call was
                    // canceled through WSACancelBlockingCall()."
                    Note( "closesocket(): WSAEINTR\n" );
                    
                    break;
                }
                
                
                case WSAEWOULDBLOCK:
                {
                    // "The socket is not connected (connection-
                    // oriented sockets only)."
                    Note( "closesocket(): WSAEWOULDBLOCK\n" );
                    
                    break;
                }
            }
        }
    
        // Mark the endpoint as missing.
        A->S = 0;
        
        // Enter the unitialized state.
        A->State = UNINITIALIZED;
        
        // Remove this stream from the stream list.
        DeleteAllReferencesToData( TheStreamList, (u8*) A );
    }
}

/*------------------------------------------------------------
| CloseTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To close a stream connection asynchronously.
|
| DESCRIPTION:  
|
| This function returns immediately without any delay.
|   
| This asynchronous stream disconnecting feature also 
| permits you to close connections in the background 
| without interfering with or delaying user actions in 
| the foreground.
|
|   Entry:  stream = stream reference.
|   
|   Exit:   function result = error code.
|   
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.04.96 revised.
------------------------------------------------------------*/
void 
CloseTCPConnection( Stream* S )
{
    // Make sure the stream is connected.
//  if( GetSocketState( S ) == T_DATAXFER )
//  {
        // Set the process to disconnecting.
//      S->Process = SocketIsDisconnecting;
    
        // Start an orderly disconnect.
//      OTSndOrderlyDisconnect( S->DataSocket );
    
        // Notifier will handle the rest.
//  }
}

/*------------------------------------------------------------
| CloseTCPStream
|-------------------------------------------------------------
| 
| PURPOSE: To close an active TCP stream.
|
| DESCRIPTION: Releases resources acquired by the call 
| 'OpenStreamSocketAsTCP'.
|
| Closes asynchronously.  Depends on the execution of 
| 'DoAsynchronousNetworkOperations' to do final deallocation.
|
| Returns 'noErr' if opened OK.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.05.96 renamed, revised.
------------------------------------------------------------*/
void 
CloseTCPStream( Stream* S )
{
    // Pull this stream from the list of registered streams
    // because it is on it's way out.
    DeleteAllReferencesToData( TheStreamList, (u8*) S );

    // Mark the stream as being in the process of closing.
    S->IsStreamClosing = 1;
    
    // Add this stream to the closing stream list.
    InsertDataLastInList( TheStreamList, (u8*) S );

    // Begin async disconnection.
    CloseTCPConnection( S );
}

/*------------------------------------------------------------
| ConnectToNetwork
|-------------------------------------------------------------
|
| PURPOSE: To make the general network connection to the OS-
|          specific network driver.
|
| DESCRIPTION: 
|
| From MSDN:
| 
| The Windows Sockets WSAStartup function initiates use 
| of WS2_32.DLL by a process.
| 
|     int WSAStartup( WORD      wVersionRequested,
|                     LPWSADATA lpWSAData );
|
| Parameters:
|
|    wVersionRequested
|       [in] The highest version of Windows Sockets support
|       that the caller can use.  The high order byte 
|       specifies the minor version (revision) number; the 
|       low-order byte specifies the major version number.
|
|    lpWSAData
|       [out] A pointer to the WSADATA data structure that 
|       is to receive details of the Windows Sockets 
|       implementation.
|
| Remarks:
|
| The WSAStartup() function must be the first Windows Sockets
| function called by an application or DLL.  It allows an
| application or DLL to specify the version of Windows Sockets
| required and to retrieve details of the specific Windows
| Sockets implementation.  The application or DLL can only
| issue further Windows Sockets functions after successfully
| calling WSAStartup().
|
| In order to support future Windows Sockets implementations
| and applications that can have functionality differences
| from the current version of Windows Sockets, a negotiation
| takes place in WSAStartup.  The caller of WSAStartup and
| the WS2_32.DLL indicate to each other the highest version
| that they can support, and each confirms that the other's
| highest version is acceptable.
|
| Upon entry to WSAStartup, the WS2_32.DLL examines the
| version requested by the application.  If this version is
| equal to or higher than the lowest version supported by
| the DLL, the call succeeds and the DLL returns in wHighVersion
| the highest version it supports and in wVersion the minimum
| of its high version and wVersionRequested.  The WS2_32.DLL
| then assumes that the application will use wVersion.  If
| the wVersion field of the WSADATA structure is unacceptable
| to the caller, it should call WSACleanup and either search
| for another WS2_32.DLL or fail to initialize.
|
| It is legal and possible for an application written to this
| version of the specification to successfully negotiate a 
| higher version number than the version of this specification.
| In such a case, the application is only guaranteed access to
| higher-version functionality that fits within the syntax
| defined in this version, such as new Ioctl codes and new
| behavior of existing functions.
|
| New functions, for example, may be inaccessible.  To be
| guaranteed full access to new syntax of a future version,
| the application must fully conform to that future version,
| such as compiling against a new header file, linking to a
| new library, or other special cases.
|
| This negotiation allows both a WS2_32.DLL and a Windows
| Socket application to support a range of Windows Sockets
| versions.  An application can use WS2_32.DLL if there is
| is any overlap in the version ranges.  The following chart
| gives examples of how WSAStartup works in conjunction with
| different application and WS2_32.DLL versions:
|
| [a big chart of numbers: the bottom line is use verion 1.1]
|
| ASSUMES:  
|
| HISTORY: 08.23.00 Factored out of SetUpNetAccess.
------------------------------------------------------------*/
            // OUT: 1 if the general network connection has
u32         //      been initialized or 0 if not.
ConnectToNetwork()
{
    s32     StartUpResult;
    WORD    vVersionRequested;
    WSADATA wsaData;
    s8*     StartUpResultString;

    // Select the version of the network interface to use,
    // 1.1.
    vVersionRequested = 0x101;
    
    StartUpResult = WSAStartup( vVersionRequested, &wsaData );

    // If there is an error.
    if( StartUpResult )
    {
        // Select the string appropriate to the error.
        switch( StartUpResult )
        {
            case WSASYSNOTREADY: 
                StartUpResultString = "WSASYSNOTREADY";
                break;
        
            case WSAVERNOTSUPPORTED: 
                StartUpResultString = "WSAVERNOTSUPPORTED";
                break;
        
            case WSAEINPROGRESS: 
                StartUpResultString = "WSAEINPROGRESS";
                break;
        
            case WSAEPROCLIM: 
                StartUpResultString = "WSAEPROCLIM";
                break;
        
            case WSAEFAULT: 
                StartUpResultString = "WSAEFAULT";
                break;
        }
        
        // Report the error.
        Note( "WSAStartup: %s\n", StartUpResultString );
        
        // Return 0 to signal failure to start up the
        // general network connection.
        return( 0 );
    }
    else // There was no error.
    {
        // Return 1 to signal that the network started
        // up OK.
        return( 1 );
    }
}

/*------------------------------------------------------------
| CountConnectionsToHost
|-------------------------------------------------------------
| 
| PURPOSE: To count the number of current connections to a
|          remote host.
|
| DESCRIPTION: Includes connections that have been initiated
| or are in the process of being broken.
|
| HISTORY: 12.23.96
------------------------------------------------------------*/
s32
CountConnectionsToHost( InternetAddress* RemoteHost )
{
    s32             Count;
    Stream*         S;
    s32             st;
    u32             RemoteIP;
    
    Count = 0;
    
    RemoteIP = RemoteHost->HostAddress;
    
    
    // If there are any streams registered with OT.
    if( TheStreamList->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( TheStreamList );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            S = (Stream*) TheDataAddress;
            
            // If the host matches.
//          if( S->RemoteLinkAddress.HostAddress == RemoteIP )
            {
                // If connected in any way.
                st = GetSocketState( S );
                
                switch( st )
                {
//                  case T_OUTCON:
//                  case T_INCON:
//                  case T_DATAXFER:
//                  case T_OUTREL:
//                  case T_INREL:
                    {
                        Count++;
                        break;
                    }
                }
            }
            
            ToNextItem();
        }
        
        RevertToList();
    }
    
    return( Count );
}

/*------------------------------------------------------------
| DeleteStream
|-------------------------------------------------------------
| 
| PURPOSE: To dispose of a stream buffer.
|
| DESCRIPTION: This releases all resources reserved by 
| 'MakeStream'.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: The stream is not part of any list and isn't
|          bound to any port, nor is any part of it registered
|          with Open Transport.
| 
| HISTORY: 11.19.96 reformatted.
|          11.29.96 pulled out free stream list.
|                   Renamed from 'DisposeStreamBuffer'.
|                   Pulled out test for '0' stream address.
|          12.05.96 moved OT specific code to 
|                   'CloseStreamSocket'.
|          12.09.96 added data buffer deletion.
|          12.17.96 added option buffer deletion.
------------------------------------------------------------*/
void 
DeleteStream( Stream* S )
{
    // Free incoming data buffers.
    if( S->IncomingData )
    {
        DeleteListOfDynamicData( S->IncomingData );
    }
    
    // Free outgoing data buffers.
    if( S->OutgoingData )
    {
        DeleteListOfDynamicData( S->OutgoingData );
    }
    
    free( S );
}

/*------------------------------------------------------------
| DisableTCPSocket
|-------------------------------------------------------------
| 
| PURPOSE: To abortively disconnect, unbind and close a 
|          stream endpoint.
|
| DESCRIPTION: Reduces a stream to the state before a call
| to 'OpenStreamSocketAsTCP'.
| 
| Any open connection is aborted if necessary.
|   
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
------------------------------------------------------------*/
s32 
DisableTCPSocket( Stream* S )
{
    s32 err;
    s32   WaitTil;
 
    // Abort a connection if necessary.
    AbortTCPConnection( S );
    
    // Wait for the completion of the disconnect or 10
    // seconds.
    WaitTil = TickCount() + 10 * 60;
    
//  while( S->Process == SocketIsDisconnecting &&
//         TickCount() < WaitTil )
    {
//      ProcessPendingEvent();
    }
    
    // Unbind the endpoint from any port it may be bound to.
    UnbindStreamSocket( S );
    
    // Wait for the completion of the unbind or 10 seconds.
    WaitTil = TickCount() + 10 * 60;
    
//  while( S->IsUnbindPending && TickCount() < WaitTil )
    {
//      ProcessPendingEvent();
    }
    
    // Remove endpoint from Open Transport. 
//  err = CloseStreamSocket( S );
    
    return( err );
}

/*------------------------------------------------------------
| EnablePassiveTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To enable a passive stream to be opened by a 
|          remote host.
|
| DESCRIPTION: The notifier for the stream will complete the
| connection when it arrives.  
|
|   Entry:  S = pointer to stream.
|   
|   Exit:   function result = error code.
|           
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.04.96 revised. Name changed from 
|                   'DoTCPPassiveOpen'.
------------------------------------------------------------*/
s32 
EnablePassiveTCPConnection( Stream* S )
{
    s32 err;
    
    // Make the stream passive.
//  S->IsMaleConnection = 1;
    
    // Bind the endpoint to any local interface and port.
//  err = BindStreamToLocalPort( S, 0, 0, 1 );
    
//  if( GetSocketState( S ) == T_IDLE )
    {
        // Set endpoint to listen for connection.
//      S->Process = SocketIsListening;
        
        return( noErr );
    }
//  else // Coudn't bind to a port.
    {
        return( err );
    }
}

/*------------------------------------------------------------
| GetSocketState
|-------------------------------------------------------------
| 
| PURPOSE: To get the state of the endpoint of a stream and
|          report any errors.
|
| DESCRIPTION: Returns the Open Transport endpoint state code
| if no error occurred or logs the error code and returns
| 'T_UNINIT'.
|
| Open Transport endpoint state codes:
|
|       T_UNINIT    0   addition to standard xti.h 
|       T_UNBND     1   unbound 
|       T_IDLE      2   idle
|       T_OUTCON    3   outgoing connection pending
|       T_INCON     4   incoming connection pending
|       T_DATAXFER  5   data transfer
|       T_OUTREL    6   outgoing orderly release
|       T_INREL     7   incoming orderly release
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 12.13.96
------------------------------------------------------------*/
s32
GetSocketState( Stream* S )
{
    s32 st;
    
//  if( S->DataSocket )
    {
//      st = OTGetSocketState( S->DataSocket );
        
        if( st >= 0 )
        {
            return( st );
        }
//      else // An error.
        {
//          Note( (s8*) "GetSocketState error(%d)\n", st );
            
//          return( T_UNINIT );
        }
    }
//  else // No endpoint assigned yet.
//  {
//      return( T_UNINIT );
//  }
}
        
/*------------------------------------------------------------
| GetIncomingDataFromStream
|-------------------------------------------------------------
| 
| PURPOSE: To get all of the data currently held in the
|          incoming data buffers of a stream.
|
| DESCRIPTION: Returns the address of a dynamically created
| 'Item' record that refers to a dynamically created 
| buffer which holds all of the data currently in the 
| incoming data buffer list.
|
| Removes the data from the incoming data buffer list.
|
| Returns a zero if nothing to read.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 12.13.96
------------------------------------------------------------*/
Item*
GetIncomingDataFromStream( Stream* S )
{
    u8*     ABuffer;
    u8*     Dest;
    Item*   AnItem;
    
    if( S->BytesToRead == 0 )
    {
        return( 0 );
    }
    
    // Allocate a new data buffer.
    ABuffer = malloc( S->BytesToRead );

    // Copy the data in the buffer list to the new buffer.
    ReferToList( S->IncomingData );
    
    Dest = ABuffer;
    
    while( TheItem )
    {
        CopyBytes( TheDataAddress, Dest, TheDataSize );
        
        Dest += TheDataSize;
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Make a new item record for the new buffer.
    AnItem = MakeItemForData( ABuffer );
    AnItem->SizeOfData   = S->BytesToRead;
    AnItem->SizeOfBuffer = S->BytesToRead;
    
    // Delete the buffer list and reset the number of bytes
    // held in the buffers.
    DeleteListOfDynamicData( S->IncomingData );
    S->IncomingData = 0;
    S->BytesToRead = 0;
    
    // Return the new item record.
    return( AnItem );
}

/*------------------------------------------------------------
| InitializeSocket
|-------------------------------------------------------------
|
| PURPOSE: To initialize a socket of a stream.
|
| DESCRIPTION: Sets the protocol and makes an OS socket 
| handle for the socket.
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 08.30.00 
|          09.09.00 Revised.
|          09.18.00 Added BlockingMode.
------------------------------------------------------------*/
void
InitializeSocket( 
    Stream* OfStream,
        // The stream of which this socket is a part.
        //
    ASocket* A,
        // Address of a socket control block.
        //
    u32 BlockingMode,
        // One of these types:
        //
        //  NONBLOCKING - Initiate a process that might take 
        //      more time to complete than the time taken by 
        //      the procedure that starts the process.  
        //                                     
        //  BLOCKING - Wait until the underlying network 
        //      function completes.
        //
    u32 Protocol )
        // Protocol to use, one of these two types.
        //
        //    UDP
        //    TCP
{
    // If no valid stream or socket address is given.
    if( ( OfStream == 0 ) || ( A == 0 ) )
    {
        return;
    }
    
    // Make the link from the socket record to the
    // stream.
    A->OfStream = OfStream;
    
    // Set the protocol, UDP or TCP, in the socket record.
    A->Protocol = Protocol;
    
    // Make an OS socket for the socket.
    switch( A->Protocol )
    {
        // Connectionless UDP datagram protocol.
        case UDP:
        {
            // Make an OS socket for UDP protocol.
            A->LastResult = 
                socket( PF_INET, (s32) SOCK_DGRAM, 0 );
                
            break;
        }
        
        // Connection-oriented TCP protocol.
        case TCP:
        {
            // Make an OS socket for TCP protocol.
            A->LastResult = 
                socket( PF_INET, (s32) SOCK_STREAM, 0 );
                
            break;
        }
        
        // No protocol is specified.
        default:
        {
            // Set the socket state to invalid.
            A->State = INVALID_STATE;
            
            // Just return.
            return;
        }
    }
    
    // If no OS socket could be made.
    if( A->LastResult == INVALID_SOCKET ) 
    {
        // Get the specific error.
        A->LastError = WSAGetLastError(); 
        
        // Set the socket state to unitialized.
        A->State = UNINITIALIZED;
    }
    else // The OS handle was created OK.
    {
        // The socket() return value is the OS socket handle:
        // save the handle in the handle field.
        A->S = A->LastResult;
        
        // Set the last error to none.
        A->LastError = 0;
        
        // Set the blocking mode of the socket.
        SetBlockingMode( A, BlockingMode );
        
        // Move the socket to the initialized state.
        A->State = INITIALIZED;
    }
}

/*------------------------------------------------------------
| InitializeSocketsOfStream
|-------------------------------------------------------------
| 
| PURPOSE: To do some work toward initializing all sockets
|          needed for the stream.
|
| DESCRIPTION: This function is non-blocking.
| 
| ASSUMES: 
| 
| HISTORY: 09.13.00
|          09.18.00 Added BlockingMode.
------------------------------------------------------------*/
void
InitializeSocketsOfStream( Stream* S )
                            // The stream.
{
    ASocket* L;
    ASocket* D;
    
    // Refer to the link socket control block of the stream
    // as 'L'.
    L = &S->LinkSocket;
    
    // Refer to the data socket control block of the stream
    // as 'D'.
    D = &S->DataSocket;
    
    // If the stream is uninitialized.
    if( S->State == UNINITIALIZED )
    {
        // If the linkage socket is uninitialized.
        if( L->State == UNINITIALIZED )
        {
            // Initialize the linkage socket: this may 
            // allocate an OS socket handle.
            InitializeSocket( 
                S,  // The stream of which this socket is a 
                    // part.
                    //
                L,  // Address of a socket control block.
                    //
                (u32) S->BlockingMode,
                    // One of these types:
                    //
                    //    BLOCKING 
                    //    NONBLOCKING
                    //
                (s32) S->Protocol );
                    // Protocol to use, one of these two 
                    // types.
                    //
                    //   UDP
                    //   TCP
        }
        
        // If the linkage socket will hand off to a 
        // separate data socket.
        if( S->IsLinkSocketUsedForData == 0 )
        {
            // If the data socket is uninitialized.
            if( D->State == UNINITIALIZED )
            {
                // Initialize the data socket: this may 
                // allocate an OS socket handle.
                InitializeSocket( 
                    S,  // The stream of which this socket 
                        // is a part.
                        //
                    D,  // Address of a socket control 
                        // block.
                        //
                    (u32) S->BlockingMode,
                        // One of these types:
                        //
                        //    BLOCKING 
                        //    NONBLOCKING
                        //
                    (s32) S->Protocol );
                        // Protocol to use, one of these 
                        // two types.
                        //
                        //   UDP
                        //   TCP
            }
        }
                
        // If the linkage socket has been initialized.
        if( L->State == INITIALIZED ) 
        {
            // If the linkage socket will be used to carry 
            // the data.
            if( S->IsLinkSocketUsedForData )
            {
                // Then all of the stream sockets are 
                // initialized.
                S->State = INITIALIZED;
            }
            else // A separate data socket is used.
            {
                // If the data socket is also initialized.
                if( D->State == INITIALIZED )
                {
                    // Then all of the stream sockets are 
                    // initialized.
                    S->State = INITIALIZED;
                }
            }
        }
    }
}

/*------------------------------------------------------------
| InitializeStream
|-------------------------------------------------------------
| 
| PURPOSE: To initialize a stream control block.
|
| DESCRIPTION: 
|
| ASSUMES: Activate stream on initialize.
| 
| HISTORY: 08.25.00
|          09.18.00 Added BlockingMode.
------------------------------------------------------------*/
void
InitializeStream( 
    Stream* S,
    // The address of the stream control record to be 
    // initialized.
    //
    u32 LocalHostAddress,
    // The IP address of the local end point to be used for 
    // the stream.  Use zero if any local IP address will do.
    //
    u32 PortNumber,
    // The IP port number of the local end point to be used
    // for the stream.  Use zero if any port address will do.
    //
    u32 ConnectionLogic,
    // There are two ways of establishing a connection
    // in the internet protocol:  
    //
    // FEMALE - listen for an incoming connection request -- 
    //      this is the logical female mode, symbolized with 
    //      the value 0.
    // 
    // MALE - initiate a connection to a remote end point 
    //      that is listening for a connection request -- 
    //      this is the logical male mode, designated with 
    //      a 1.
    //
    u32 BlockingMode,
    // One of these types:
    //
    // NONBLOCKING - Initiate a process that might take 
    //      more time to complete than the time taken by 
    //      the procedure that starts the process.  
    //                                     
    // BLOCKING - Wait until each underlying network 
    //      function completes.
    //
    u32 Protocol,
    // Protocol to use, one of these two types.
    //
    // UDP
    // TCP
    //
    u32 Direction,
    // Data flow direction, one of these three types,
    //
    // SEND - send only.
    //
    // RECEIVE - recieve only.
    //
    // SEND_AND_RECEIVE - send and recieve data.
    //      
    u32 IsLinkSocketUsedForData ) 
    // There are two ways of using the connection socket:
    //
    // 0 - Data should be sent through a different socket.
    //
    // 1 - Data should be sent via the same socket that was 
    //     used initially to make the connection.
{
    // Start by clearing the stream control record to zeros.
    memset( S, 0, sizeof( Stream ) );

    // Save the local host address in the link socket 
    // sub-record.
    S->LinkSocket.LocalAddress.HostAddress = LocalHostAddress;
    
    // Save the local port number in the link socket 
    // sub-record.
    S->LinkSocket.LocalAddress.PortNumber = PortNumber;
    
    // Save the connection logic configuration in the 
    // stream record.
    S->ConnectionLogic = ConnectionLogic;
    
    // Save the blocking mode that should be used.
    S->BlockingMode = (u8) BlockingMode;
    
    // Protocol to use, one of these two types.
    //
    //   UDP
    //   TCP
    S->Protocol = Protocol;
 
    // Data flow direction, one of these three types,
    //    SEND
    //    RECEIVE
    //    SEND_AND_RECEIVE
    //      
    S->Direction = Direction;
    
    // Save the link socket usage option in the stream
    // record.
    S->IsLinkSocketUsedForData = IsLinkSocketUsedForData;
 
    // Set the connection logic option for the link socket.     
    S->LinkSocket.ConnectionLogic = ConnectionLogic;
    
    // Set the current state of the stream to be uninitialized.
    S->State = UNINITIALIZED;
    
    // Set the goal state of the stream to be SEND_AND_RECEIVE
    // by default.
    S->GoalState = SEND_AND_RECEIVE;
    
    // Add the stream to the list of all streams.
    InsertDataLastInList( TheStreamList, (u8*) S );
    
    // Activate the stream.
    S->IsActive = 1;
}

/*------------------------------------------------------------
| IsIncomingDataLate
|-------------------------------------------------------------
| 
| PURPOSE: To test if data is late and connection is presumed
|          broken.
|
| DESCRIPTION: Returns 1 if the maximum time between incoming 
| data has been exceeded.
|    
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.07.97
|          08.23.00 Changed time basis to CPU timestamp
|                   register and seconds.
------------------------------------------------------------*/
u32  
IsIncomingDataLate()
{
    f64 CurrentTime;
    
    // Read the current CPU timestamp register in seconds.
    CurrentTime = ReadTimeStampInSeconds();

    // If no data has been received on any stream in the
    // time designated as the maximum allowable for normal
    // functioning of the network connection.
    if( CurrentTime >
        ( TimeWhenDataWasLastReceivedOnAnyStream +
          MaximumTimeBetweenIncomingDataOnAnyStream ) )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| IsOpenTransportAvailable
|-------------------------------------------------------------
| 
| PURPOSE: To determine whether we have Open Transport.
|
| DESCRIPTION: 
|
|   Exit:   function result = 1 if Open Transport and 
|           Open Transport/TCP are both installed.
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
------------------------------------------------------------*/
u32   
IsOpenTransportAvailable()
{
    static u32   IsOTAvail;
    static u32   IsKnown = 0;
    
    s32 err;
    s32   result;
    
    err = noErr;
    
    if( IsKnown == 0 ) 
    {
//      err = Gestalt( gestaltOpenTpt, &result );
        
        IsOTAvail = 1;
//          err == noErr 
//          && 
//          (result & gestaltOpenTptPresentMask ) != 0 
//          &&
//          (result & gestaltOpenTptTCPPresentMask ) != 0;
//          
        IsKnown = 1;
    }
    
    return( IsOTAvail );
}

/*------------------------------------------------------------
| LogSocketState
|-------------------------------------------------------------
| 
| PURPOSE: To log the endpoint state of a stream.
|
| DESCRIPTION: 
|
| These are the values returned by 'OTGetSocketState' and 
| 'OTSync' which represent the state of an endpoint:
|
|   T_UNINIT        0   addition to standard xti.h
|   T_UNBND         1   unbound 
|   T_IDLE          2   idle    
|   T_OUTCON        3   outgoing connection pending
|   T_INCON         4   incoming connection pending
|   T_DATAXFER      5   data transfer
|   T_OUTREL        6   outgoing orderly release
|   T_INREL         7   incoming orderly release
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
------------------------------------------------------------*/
void
LogSocketState( Stream* S )
{
    s32 State;
    
//  if( IsNetworkAccessSetUp && 
//      S && 
//      S->DataSocket && 
//      IsNetworkActivityLogged ) 
    {
//      State = OTGetSocketState( S->DataSocket );
#if 0       
        switch( State )
        {
            case T_UNINIT:   Note( (s8*) "T_UNINIT\n" );    break;
            case T_UNBND:    Note( (s8*) "T_UNBND\n" );     break;
            case T_IDLE:     Note( (s8*) "T_IDLE\n" );      break;
            case T_OUTCON:   Note( (s8*) "T_OUTCON\n" );    break;
            case T_INCON:    Note( (s8*) "T_INCON\n" );     break;
            case T_DATAXFER: Note( (s8*) "T_DATAXFER\n" );  break;
            case T_OUTREL:   Note( (s8*) "T_OUTREL\n" );    break;
            case T_INREL:    Note( (s8*) "T_INREL\n" );     break;
        }
#endif // 0
    }
}

/*------------------------------------------------------------
| LogNet
|-------------------------------------------------------------
| 
| PURPOSE: To log a message.
|
| DESCRIPTION: 
|
|   Entry:  s = pointer to stream.
|           logEntryType = 
|               'C' if command.
|               'R' if response.
|               ' ' if open/close operation.
|           str = command or response string or open/close 
|                 message string.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          02.13.00 Changed 'Note' to 'printf'.
|          08.21.00 Changed printf back to Note.
------------------------------------------------------------*/
void
LogNet( Stream* S, s8 logEntryType, s8* str )
{
    if( IsNetworkActivityLogged ) 
    {
//      Note( (s8*) "NetLog: %d %d %d %d %s\n", 
//              logEntryType, 
//              S->RemoteDataAddress.HostAddress,
//              S->RemoteDataAddress.PortNumber,
//              S->LocalDataAddress.PortNumber,
//              str );
    }
}

/*------------------------------------------------------------
| MakeStream
|-------------------------------------------------------------
| 
| PURPOSE: To allocate a stream control block.
|
| DESCRIPTION: 
|
|       Exit:   function result = error code.
|               *s = pointer to new stream buffer.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.29.96 pulled out free stream list.
|                   Renamed from 'NewStreamBuffer'.
------------------------------------------------------------*/
Stream*
MakeStream()
{
    Stream* S;
    
    S = (Stream*) malloc( sizeof( Stream ) );
        
    FillBytes( (u8*) S, (u32) sizeof( Stream ), 0 );
    
    return( S );
}

/*------------------------------------------------------------
| NoticeIncomingData
|-------------------------------------------------------------
| 
| PURPOSE: To note what time data last came in on a stream
|          connection.
|
| DESCRIPTION: Used to detect dropped connections.
|
| HISTORY: 01.07.97
|          08.22.00 Revised to be stream specific instead
|                   of general to the whole network driver
|                   and also changed clock from TickCount()
|                   to CPU timestamp in seconds.
|          08.23.00 Added monitor for general network 
|                   activity.
------------------------------------------------------------*/
void
NoticeIncomingData( Stream* S )
{
    f64 CurrentTime;
    
    // Read the current CPU timestamp register in seconds.
    CurrentTime = ReadTimeStampInSeconds();
    
    // Update the last input time for the specific stream.
    S->LastInputTime = ReadTimeStampInSeconds();
    
    // Update the last input time for the network connection
    // in general.
    TimeWhenDataWasLastReceivedOnAnyStream = CurrentTime;
}
  
/*------------------------------------------------------------
| OnAcceptError
|-------------------------------------------------------------
|
| PURPOSE: To respond to an error returned by accept().
|
| DESCRIPTION: Errors generated by accept() are distinguished
| as being a signal that work is pending or as a failure of
| some kind.
|
| The return flag is set to 1 if the work is in progress, or
| a 0 flag is returned if some kind of failure occurred.
|
| EXAMPLE: 
|
| ASSUMES: Single-threaded operation.
|
| HISTORY: 08.16.00 
------------------------------------------------------------*/
u32          // OUT: 1 if in-progress work or 0 if failure.
OnAcceptError( Stream* S )
{
    s32 AcceptError;
    u32 IsInProgress;
 
    // Default to the failure signal which can happen in more 
    // ways that the in-progress condition.
    IsInProgress = 0;

#ifdef macintosh

    AcceptError = AcceptError;
    
#else
    
    // Find out specifically what the problem is.
    AcceptError = WSAGetLastError(); 
    
    // These are all of the possible error codes that can be 
    // returned following an accept() error:
    switch( AcceptError )
    {
        case WSANOTINITIALISED:
        {
            // A successful WSAStartup must occur before
            // using this function.
            Note( "accept(): WSANOTINITIALISED\n" );
            
            break;
        }

        case WSAENETDOWN:
        {
            // The network subsystem has failed.
            Note( "accept(): WSAENETDOWN\n" );
            
            break;
        }

        case WSAEFAULT:
        {
            // The addrlen parameter is too small or addr
            // is not a valid part of the user address
            // space.
            Note( "accept(): WSAEFAULT\n" );
            
            break;
        }

        case WSAEINTR:
        {
            // A blocking Windows Socket 1.1 call was 
            // canceled through WSACancelBlockingCall.
            Note( "accept(): WSAEINTR\n" );
            
            break;
        }

        case WSAEINPROGRESS:
        {
            // A blocking Windows Sockets 1.1 call is in
            // progress, or the service provider is still
            // processing a callback function.
            Note( "accept(): WSAEINPROGRESS\n" );
            
            // Signal success.
            IsInProgress = 1;
            
            break;
        }

        case WSAEINVAL:
        {
            // The listen function was not invoked prior to
            // accept.
            Note( "accept(): WSAEINVAL\n" );
            
            break;
        }

        case WSAEMFILE:
        {
            // The queue is nonempty upon entry to accept
            // and there are no descriptors available.
            Note( "accept(): WSAEMFILE\n" );
            
            break;
        }

        case WSAENOBUFS:
        {
            // No buffer space is available.
            Note( "accept(): WSAENOBUFS\n" );
            
            break;
        }

        case WSAENOTSOCK:
        {
            // The descriptor is not a socket.
            Note( "accept(): WSAENOTSOCK\n" );
            
            break;
        }

        case WSAEOPNOTSUPP:
        {
            // The referenced socket is not a type that
            // supports connection-oriented service.
            Note( "accept(): WSAEOPNOTSUPP\n" );
            
            break;
        }

        case WSAEWOULDBLOCK:
        {
            // The socket is marked as nonblocking and
            // no connections are present to be accepted.
            
            // This is normal, just give the connection 
            // more time to compete by returning now and 
            // trying again later.
            
            // Signal success.
            IsInProgress = 1;
        }
    }
#endif
    
    // Return the result.
    return( IsInProgress );
}
  
/*------------------------------------------------------------
| OnBindError
|-------------------------------------------------------------
|
| PURPOSE: To respond to an error in bind().
|
| DESCRIPTION: 
|
| The return flag is set to 1 if the work is in progress, or
| a 0 flag is returned if some kind of failure occurred.
|
| EXAMPLE: 
|
| ASSUMES: Single-threaded operation.
|
| HISTORY: 08.16.00 
------------------------------------------------------------*/
u32          // OUT: 1 if in-progress work or 0 if failure.
OnBindError( ASocket* A )
{
    u32 IsInProgress;
 
    // Default to the failure signal which can happen in more 
    // ways that the in-progress condition.
    IsInProgress = 0;

    // Find out specifically what the problem is.
    A->LastError = WSAGetLastError(); 
    
    // These are all of the possible error codes that can be 
    // returned following an bind() error:
    switch( A->LastError )
    {
        case WSANOTINITIALISED:
        {
            // A successful WSAStartup must occur before
            // using this function.
            Note( "bind(): WSANOTINITIALISED\n" );
            
            break;
        }

        case WSAENETDOWN:
        {
            // The network subsystem has failed.
            Note( "bind(): WSAENETDOWN\n" );
            
            break;
        }

        case WSAEADDRINUSE:
        {
            // A process on the machine is already bound
            // to the same fully qualified address and the
            // socket has not been marked to allow address
            // re-use with SO_REUSEADDR. 
            Note( "bind(): WSAEADDRINUSE\n" );
            
            break;
        }
 
        case WSAEADDRNOTAVAIL:
        {
            // The specified address is not a valid address
            // for this machine. 
            Note( "bind(): WSAEADDRNOTAVAIL\n" );
            
            break;
        }
 
        case WSAEFAULT:
        {
            // The addrlen parameter is too small or addr
            // is not a valid part of the user address
            // space.
            Note( "bind(): WSAEFAULT\n" );
            
            break;
        }
 
        case WSAEINPROGRESS:
        {
            // A blocking Windows Sockets 1.1 call is in
            // progress, or the service provider is still
            // processing a callback function.
            Note( "bind(): WSAEINPROGRESS\n" );
            
            // Signal success.
            IsInProgress = 1;
            
            break;
        }

        case WSAEINVAL:
        {
            // The socket is already bound to an address.
            Note( "bind(): WSAEINVAL\n" );
            
            break;
        }
 
        case WSAENOBUFS:
        {
            // No buffer space is available.
            Note( "bind(): WSAENOBUFS\n" );
            
            break;
        }

        case WSAENOTSOCK:
        {
            // The descriptor is not a socket.
            Note( "bind(): WSAENOTSOCK\n" );
            
            break;
        }
    }
    
    // Return the result.
    return( IsInProgress );
}

/*------------------------------------------------------------
| OnListenError
|-------------------------------------------------------------
|
| PURPOSE: To respond to an error returned by listen().
|
| DESCRIPTION: Errors generated by listen() are distinguished
| as being a signal that work is pending or as a failure of
| some kind.
|
| The return flag is set to 1 if the work is in progress, or
| a 0 flag is returned if some kind of failure occurred.
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 08.16.00 
------------------------------------------------------------*/
u32         // OUT: 1 if in-progress work or 0 if failure.
OnListenError( Stream* S )
{
    u32 IsInProgress;
 
    // Default to the failure signal which can happen in more 
    // ways that the in-progress condition.
    IsInProgress = 0;
    
#ifndef macintosh
 
    // Find out specifically what the problem is.
//  S->ListenError = WSAGetLastError(); 

    // These are all of the possible error codes that can be 
    // returned following a listen() error:
    switch( 0 ) //S->ListenError )
    {
        case WSANOTINITIALISED:
        {
            // A successful WSAStartup must occur before using 
            // this function.
            Note( "listen(): WSANOTINITIALISED\n" );
            
            break;
        }
    
        case WSAENETDOWN:
        {
            // The network subsystem has failed.
            Note( "listen(): WSAENETDOWN\n" );
            
            break;
        }
    
        case WSAEADDRINUSE:
        {
            // The socket's local address is already in use 
            // and the socket was not marked to allow address 
            // reuse with SO_REUSEADDR.  This error usually 
            // occurs during the bind() function, but could 
            // be delayed until this function if the bind() 
            // was to a partially wild-card address (involving 
            // ADDR_ANY) and if a specific address needs to be
            // "committed" at the time of this function.
            Note( "listen(): WSAEADDRINUSE\n" );
            
            break;
        }
    
        case WSAEINPROGRESS:
        {
            // A blocking Windows Sockets 1.1 call is in
            // progress, or the service provider is still
            // processing a callback function.
            Note( "listen(): WSAEINPROGRESS\n" );
            
            // Signal work in progess.
            IsInProgress = 1;
            
            break;
        }
    
        case WSAEINVAL:
        {
            // The socket has not been bound with bind().
            Note( "listen(): WSAEINVAL\n" );
            
            break;
        }
    
        case WSAEISCONN:
        {
            // The socket is already connected.
            Note( "listen(): WSAEISCONN\n" );
            
            break;
        }
    
        case WSAEMFILE:
        {
            // No more socket descriptors are available.
            Note( "listen(): WSAEMFILE\n" );
            
            break;
        }
    
        case WSAENOBUFS:
        {
            // No buffer space is available.
            Note( "listen(): WSAENOBUFS\n" );
            
            break;
        }
    
        case WSAENOTSOCK:
        {
            // The descriptor is not a socket.
            Note( "listen(): WSAENOTSOCK\n" );
            
            break;
        }
    
        case WSAEOPNOTSUPP:
        {
            // The referenced socket is not of a type that
            // supports the listen() operation.
            Note( "listen(): WSAEOPNOTSUPP\n" );
            
            break;
        }
    }
#endif
    
    // Return the result.
    return( IsInProgress );
}

/*------------------------------------------------------------
| OnRecvError
|-------------------------------------------------------------
|
| PURPOSE: To respond to an error returned by recv().
|
| DESCRIPTION: Errors generated by recv() are distinguished
| as being a signal that work is pending or as a failure of
| some kind.
|
| The return flag is set to 1 if the work is in progress, or
| a 0 flag is returned if some kind of failure occurred.
|
| EXAMPLE: 
|
| ASSUMES: 
|
| HISTORY: 08.16.00 
------------------------------------------------------------*/
u32         // OUT: 1 if in-progress work or 0 if failure.
OnRecvError( Stream* S )
{
    s32 RecvError;
    u32 IsInProgress;
 
    // Default to the failure signal which can happen in more 
    // ways that the in-progress condition.
    IsInProgress = 0;
    
    // Find out specifically what the problem is.
    RecvError = WSAGetLastError(); 

    // These are all of the possible error codes that can be 
    // returned following a recv() error:
    switch( RecvError )
    {
        case WSANOTINITIALISED:
        {
            // A successful WSAStartup must occur before 
            // using this function.
            Note( "recv(): WSANOTINITIALISED\n" );
            
            break;
        }
    
        case WSAENETDOWN:
        {
            // The network subsystem has failed.
            Note( "recv(): WSAENETDOWN\n" );
            
            break;
        }
    
        case WSAEFAULT:
        {
            // The buf parameter is not completely contained 
            // in a valid part of the user address space.
            Note( "recv(): WSAEFAULT\n" );
            
            break;
        }
    
        case WSAENOTCONN:
        {
            // The socket is not connected.
            Note( "recv(): WSAENOTCONN\n" );
            
            break;
        }
    
        case WSAEINTR:
        {
            // The (blocking) call was cancelled through
            // WSACancelBlockingCall().
            Note( "recv(): WSAEINTR\n" );
            
            break;
        }
    
        case WSAEINPROGRESS:
        {
            // A blocking Windows Sockets 1.1 call is in
            // progress, or the service provider is still
            // processing a callback function.
            Note( "recv(): WSAEINPROGRESS\n" );
            
            // Signal work in progress.
            IsInProgress = 1;
            
            break;
        }
    
        case WSAENETRESET:
        {
            // The connection has been broken due to the 
            // keep-alive activity detecting a failure 
            // while the operation was in progress.
            Note( "recv(): WSAENETRESET\n" );
            
            break;
        }
    
        case WSAENOTSOCK:
        {
            // The descriptor is not a socket.
            Note( "recv(): WSAENOTSOCK\n" );
            
            break;
        }
    
        case WSAEOPNOTSUPP:
        {
            // The MSG_OOB was specified, but socket is not 
            // stream-style such as type SOCK_STREAM, 
            // out-of-band data is not supported in the 
            // communication domain associated with this 
            // socket, or the socket is unidirectional and 
            // supports  only send operations.
            Note( "recv(): WSAEOPNOTSUPP\n" );
            
            break;
        }
        
        case WSAESHUTDOWN:
        {
            // The socket has been shutdown; it is not possible 
            // to recv on a socket after shutdown has been 
            // invoked with how set to SD_RECEIVE or SD_BOTH.
            Note( "recv(): WSAESHUTDOWN\n" );
            
            break;
        }
        
        case WSAEWOULDBLOCK:
        {
            // The socket is marked as non-blocking and the
            // receive operation would block.
            Note( "recv(): WSAEWOULDBLOCK\n" );
            
            // Signal work in progress.
            IsInProgress = 1;
            
            break;
        }
        
        case WSAEMSGSIZE:
        {
            // The message was too large to fit into the 
            // specified buffer and was truncated.
            Note( "recv(): WSAEMSGSIZE\n" );
            
            break;
        }
    
        case WSAEINVAL:
        {
            // The socket has not been bound with bind, or 
            // an unknown flag was specified, or MSG_OOB was 
            // specified for a socket with SO_OOBINLINE 
            // enabled or (for byte stream sockets only) len 
            // was zero or negative.
            Note( "recv(): WSAEINVAL\n" );
            
            break;
        }
    
        case WSAECONNABORTED:
        {
            // The virtual circuit was terminated due to a 
            // time-out or other failure.  The application 
            // should close the socket as it is no longer 
            // usable.
            Note( "recv(): WSAECONNABORTED\n" );
            
            break;
        }
    
        case WSAEMFILE:
        {
            // No more socket descriptors are available.
            Note( "recv(): WSAEMFILE\n" );
            
            break;
        }
    
        case WSAENOBUFS:
        {
            // No buffer space is available.
            Note( "recv(): WSAENOBUFS\n" );
            
            break;
        }
    }
    
    // Return the result.
    return( IsInProgress );
}

/*------------------------------------------------------------
| OpenStreamSocketAsTCP
|-------------------------------------------------------------
| 
| PURPOSE: To open a TCP endpoint for the stream in Open
|          Transport synchronously.
|
| DESCRIPTION: Configures the endpoint for TCP, adds it to
| the list of registered endpoints and then allocates OT
| related buffers.
|
|   Entry:  s = pointer to stream.
|   
|   Exit:   function result = error code.
|
| EXAMPLE: 
|
| NOTE: See 'CloseStreamSocket' for the clean up routine
|       for this one.
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.28.96 renamed from 'DoTCPCreate'.
------------------------------------------------------------*/
s32 
OpenStreamSocketAsTCP( Stream* s )
{
    s32 err;
    s32 WaitTil;

    // Call Open Transport to open a new endpoint for
    // the TCP protocol.
//  s->Process = SocketIsOpening;
        
//  err = OTAsyncOpenSocket(
//          OTCreateConfiguration(kTCPName), 
//          0,
//          0, 
//          (OTNotifyProcPtr) StreamNotifier, 
//          s );
                
    if( err != noErr ) 
    {
        // Couldn't begin opening the endpoint.
        return( err );
    }
    
    // Wait for the open operation to complete: the
    // notifier will save the endpoint reference for the
    // new endpoint in 's->Socket'.  Allow 10 seconds.
    WaitTil = TickCount() + 10 * 60;

//  while( s->Process == SocketIsOpening && 
//         TickCount() < WaitTil )
    {
//      ProcessPendingEvent();
    }
    
    // Check for error.
 // if( GetSocketState( s ) != T_UNBND ) 
    {
 //     Note( (s8*) "Stream %d endpoint open failed.", s );

        return( CantOpenStream );
    }
        
    // Add this stream to the registered stream list.
    InsertDataLastInList( TheStreamList, (u8*) s );
    
    return( noErr );
}
 
/*------------------------------------------------------------
|  ReceiveDataViaTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To receive any available data from a TCP 
|          connection up to a given number of bytes.
|
| DESCRIPTION: Gets whatever data is available on the
| stream up to a given buffer size limit.
|
| Returns results in Stream structure fields RecvResult and
| RecvError.  
|
| If RecvResult is non-negative it holds the number of bytes 
| read.
|
| If RecvResult == SOCKET_ERROR (-1) then RecvError holds
| the specific error code.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.04.96 revised.
|          08.22.00 Revised to return RecvResult and RecvError
|                   in the stream structure rather than on
|                   the stack.
------------------------------------------------------------*/
void
ReceiveDataViaTCPConnection( 
    Stream* S, 
            // The stream where the incoming data will arrive.
            //
    u8*     Buffer, 
            // The place where the data should be put.
            //
    s32     BufferSize )
            // The maximum number of bytes that can be read.
{
    // If the socket is connected and able to read data.
    if( S->IsConnected )
    {
        // Receive some data from the socket returning the number 
        // of bytes actually received or SOCKET_ERROR (-1).
//      S->RecvResult = 
//          recv( S->DataSocket, 
                    // The socket where the data should come 
                    // from.
                    //
//                Buffer, 
                    // The buffer for the incoming data.
                    //
//                BufferSize,
                    // The size of the buffer in bytes.
                    //
//                0 );
                    // Special options flag:
                    // 
                    // 0 - nothing special.
                    //
                    // 1 - MSG_OOB, process out-of-band data.
                    //
                    // 2 - MSG_PEEK, peek at incoming message.
                    //
                    // 3 - MSG_DONTROUTE, send without using
                    //     routing tables.
                  
        // If a recv() error has occurred.
//      if( S->RecvResult == SOCKET_ERROR )
        {
            // Respond to the specific error.
//          S->RecvError = OnRecvError( S );
        }
//      else // No error occurred.
        {
            // Clear the recv error field.
//          S->RecvError = 0;
            
            // Keep track of how many bytes we have received.   
//          if( S->RecvResult > 0 ) 
            {
                // Note what time data last came in.
                NoticeIncomingData( S );
                
                // Account for the bytes received.
//          S->TotalBytesReceived += S->RecvResult;
            }
        }
    }
    else // Not connected.
    {
        // Then there is no data available.
//      S->RecvResult = SOCKET_ERROR;
        
        // Set the error to indicate that there is no 
        // connection.
//      S->RecvError = WSAENOTCONN; 
    }
}

/*------------------------------------------------------------
| RequestBindStreamToLocalPort
|-------------------------------------------------------------
| 
| PURPOSE: To request the linking of a stream to a local port
|          without blocking.
|
| DESCRIPTION: Expects the port number and how many
| pending connection requests are permitted at one time.
|
| If any internet interface can be used, use '0' for the
| local IP address.
|
| If any port number can be used, use '0' as the port number.
|
| DoAsynchronousNetworkOperations() will complete this.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: Any local internet interface is as good as another.
| 
| HISTORY: 11.28.96 extracted from 'DoTCPCreate'.
|          08.23.00 Revised for NT.
------------------------------------------------------------*/
void    
RequestBindStreamToLocalPort( 
    Stream* S,
    u32     IP_Address, // 0 if use default. 
    u16     PortNumber, // 0 if use any.
    u32     PendingConnectionLimit )
{   
    s32             err;
    u32             Local_IP_Addr;
    InternetAddress*    AnInetAddr;
    
    //
    // Set up the bind request.
    //
//  S->BindRequest->qlen = PendingConnectionLimit;

    // Get my default local IP address.   
    if( IP_Address == 0 ) 
    {
//      err = GetLocalHostIPAddress( &Local_IP_Addr );

        if( err != noErr )
        {
//          return( err );
        }
    }
    else // Use the given local interface address.
    {
        Local_IP_Addr = IP_Address;
    }
    
    // Put the local address in the form required:
    //
    // struct InternetAddress
    // {
    //      u16 PortNumber; // Port number 
    //      u32 HostAddress; // Host address 
    // };
    
    // Refer to the address buffer as an internet address.
//  AnInetAddr = (InternetAddress*) S->BindRequest->addr.buf;
    
    // Fill the fields that specify the address.
    AnInetAddr->PortNumber = PortNumber;
    AnInetAddr->HostAddress = Local_IP_Addr;
                       
//  S->BindRequest->addr.len = sizeof(InternetAddress);
    
     
}
    
/*------------------------------------------------------------
| RequestOpenStreamSocketAsTCP
|-------------------------------------------------------------
| 
| PURPOSE: To open a TCP endpoint for the stream in Open
|          Transport asynchronously.
|
| DESCRIPTION: Configures the endpoint for TCP, adds it to
| the list of registered endpoints and then allocates OT
| related buffers.
|
|   Entry:  s = pointer to stream.
|   
|   Exit:   function result = error code.
|
| EXAMPLE: 
|
| NOTE: See 'CloseStreamSocket' for the clean up routine
|       for this one.
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 from 
------------------------------------------------------------*/
s32 
RequestOpenStreamSocketAsTCP( Stream* s )
{
        
}

/*------------------------------------------------------------
| SetBlockingMode
|-------------------------------------------------------------
|
| PURPOSE: To set the blocking mode of a socket. 
|
| DESCRIPTION: From MSDN...
|
| "Remarks
| 
| The ioctlsocket function can be used on any socket in any 
| state. It is used to set or retrieve operating parameters 
| associated with the socket, independent of the protocol and 
| communications subsystem. Here are the supported commands 
| to use in the cmd parameter and their semantics: 
|
| FIONBIO
|
| Use with a nonzero argp parameter to enable the nonblocking 
| mode of socket s. The argp parameter is zero if nonblocking 
| is to be disabled. The argp parameter points to an unsigned 
| long value. When a socket is created, it operates in 
| blocking mode by default (nonblocking mode is disabled). 
| This is consistent with BSD sockets. 
|
| The WSAAsyncSelect and WSAEventSelect functions 
| automatically set a socket to nonblocking mode. If 
| WSAAsyncSelect or WSAEventSelect has been issued on a 
| socket, then any attempt to use ioctlsocket to set the 
| socket back to blocking mode will fail with WSAEINVAL. 
|
| To set the socket back to blocking mode, an application must 
| first disable WSAAsyncSelect by calling WSAAsyncSelect with 
| the lEvent parameter equal to zero, or disable 
| WSAEventSelect by calling WSAEventSelect with the 
| lNetworkEvents parameter equal to zero." 
|
| EXAMPLE: 
|
| ASSUMES: This routine accomplishes it's work quickly.
|
| HISTORY: 08.30.00 
|          09.24.00 Added comment and debugger call.
------------------------------------------------------------*/
void
SetBlockingMode( 
    ASocket* A,
    // The socket to have its blocking mode set.
    //
    u32 BlockingMode )
    // One of these types:
    //
    //  NONBLOCKING - Initiate a process that might take 
    //      more time to complete than the time taken by 
    //      the procedure that starts the process.  
    //                                     
    //  BLOCKING - Wait until the underlying network 
    //      function completes.
{
    u32 blocking;

    // Identify the function about to be executed.
    A->LastFunction = SET_BLOCKING_MODE;
     
    if( BlockingMode == BLOCKING )
    {
        // Set 'blocking' to zero to indicate that the 
        // socket should be blocking.
        blocking = 0;
    }
    else
    {
        // 1 means no blocking.
        blocking = 1;
    }
    
    // Call the OS routine that sets the blocking mode.
    A->LastResult = 
        ioctlsocket( 
            A->S, 
            (long) FIONBIO, 
            &blocking );

    // If there was a ioctlsocket error.
    if( A->LastResult == SOCKET_ERROR )
    {
        // Find out specifically what the problem is, one of
        // these:
        //
        // WSANOTINITIALIZED
        // WSANETDOWN
        // WSAEINPROGRESS
        // WSAENOTSOCK
        // WSAEFAULT
        //
        A->LastError = WSAGetLastError(); 
        
Debugger();
    }
    else // There was no error.
    {
        A->LastError = 0;
    }
}

/*------------------------------------------------------------
| SetUpNetAccess
|-------------------------------------------------------------
| 
| PURPOSE: To prepare for making network connections.
|
| DESCRIPTION: This function must be called before calling
| any other functions in the module.
| 
| HISTORY: 11.19.96 reformatted.
|          11.25.96 pulled out 'GiveTime' parameter in favor
|                   of using 'ProcessPendingEvent' throughout.
|          11.28.96 pulled out stream buffer pre-allocation
|                   since it isn't necessary.
|          12.17.96 added set up for additional lists.
|          01.07.96 added dropped-connection detector.
|          08.21.00 Revised for Win32.
|          08.23.00 Factored out ConnectToNetwork().
------------------------------------------------------------*/
void 
SetUpNetAccess( 
    u32     IsLogNetworkActivity,
            // Control flag set to 1 if network activity
            // should be added to the application log, or 0 
            // if not.
            // 
    f64     MaxIncomingDataGapInSeconds )
            // Assuming that if any network connection is
            // active and operating normally then at least 
            // some data should be coming in once in a while.
            //
            // MaxIncomingDataGapInSeconds defines the point 
            // beyond which the general network connection can 
            // be considered lost, possibley triggering a 
            // general network reset.
            //
            // Units are seconds and the timebase is the CPU 
            // timestamp register.
{
    // Default to not set up.
    IsNetworkAccessSetUp = 0;
     
    // Configure the network logging option.
    IsNetworkActivityLogged = IsLogNetworkActivity;
    
    // Set the time-out gap for incoming data.
    MaximumTimeBetweenIncomingDataOnAnyStream = 
        MaxIncomingDataGapInSeconds;
        
    // Make the list for all existing streams.
    TheStreamList = MakeList();
     
    // Make the general network connection to the OS network
    // driver.
    IsNetworkConnected = ConnectToNetwork();
    
    // Signal that the network driver is set up.
    IsNetworkAccessSetUp = 1;
    
    // Turn on the net idle functions.
    IsAsynchronousNetOperationsEnabled = 1;
}

/*------------------------------------------------------------
| ShutdownSocket
|-------------------------------------------------------------
|
| PURPOSE: To disable sending and receiving of a socket.
|
| DESCRIPTION: 
|
| From MSDN network function reference:
|
| "The shutdown() function is used on all types of sockets to 
| disable reception, transmission, or both.
|
| If the how parameter is SD_RECEIVE, subsequent calls to the 
| recv() function on the socket will be disallowed.  This has 
| no effect on the lower protocol layers. For TCP sockets, if 
| there is still data queued on the socket waiting to be
| received, or data arrives subsequently, the connection is 
| reset, since the data cannot be delivered to the user.  For 
| UDP sockets, incoming datagrams are accepted and queued.  
| In no case will an ICMP error packet be generated.
|
| If the how parameter is SD_SEND, subsequent calls to the 
| send() function are disallowed.  For TCP sockets, a FIN will 
| be sent after all data is sent and acknowledged by the 
| receiver.
|
| Setting how to SD_BOTH disables both sends and receives as 
| described above.
|
| The shutdown function does not close the socket. Any 
| resources attached to the socket will not be freed until 
| closesocket().
| 
| To assure that all data is sent and received on a connected 
| socket before it is closed, an application should use 
| shutdown() to close the connection before calling 
| closesocket().
|
| For example, to initiate a graceful disconnect:
|
|    1. Call WSAAsyncSelect to register for FD_CLOSE
|       notification.
|
|    2. Call shutdown() with how = SD_SEND.
|
|    3. When FD_CLOSE received, call recv until zero
|       returned, or SOCKET_ERROR.
|
|    4. Call closesocket.
|
| [Don't follow this recommendation because it relies
|  on Windows-specific event handling.]
|
| Note the shutdown() function does not block regardless of 
| the SO_LINGER setting on the socket.
|
| An application should not rely on being able to re-use a 
| socket after it has been shut down.  In particular, a 
| Windows Sockets provider is not required to support the 
| use of connect() on a socket that has been shutdown().
|
| Return Values:
| 
| If no error occurs, shutdown() returns a zero. Otherwise, 
| a value of SOCKET_ERROR is returned, and a specific error 
| code can be retreived by calling WSAGetLastError().
|   
| EXAMPLE: 
|
| ASSUMES:  
|
| HISTORY: 09.17.00 From OnBindError
------------------------------------------------------------*/
void         
ShutdownSocket( ASocket* A )
{
    // Disable sending and receiving.
    A->LastResult = shutdown( A->S, SD_BOTH );
    
    // If there was a shutdown error.
    if( A->LastResult  )
    {
        // Find out specifically what the problem is.
        A->LastError = WSAGetLastError(); 
        
        // Depending on the error.
        switch( A->LastError )
        {
            case WSANOTINITIALISED:
            {
                // "A successful WSAStartup must occur before
                // using this function."
                Note( "shutdown(): WSANOTINITIALISED\n" );
                
                break;
            }
            
            case WSAENETDOWN:
            {
                // "The network subsystem has failed."
                Note( "shutdown(): WSAENETDOWN\n" );
                
                break;
            }
            
            case WSAEINVAL:
            {
                // "The how parameter is not valid, or is not
                // consistent with the socket type.  For example,
                // SD_SEND is used with a UNI_RECV socket type."
                Note( "shutdown(): WSAEINVAL\n" );
                
                break;
            }
            
            case WSAEINPROGRESS:
            {
                // "A blocking Windows Sockets 1.1 call is in
                // progress, or the service provider is still
                // processing a callback function."
                Note( "shutdown(): WSAEINPROGRESS\n" );
                
                break;
            }
            
            case WSAENOTCONN:
            {
                // "The socket is not connected (connection-
                // oriented sockets only)."
                Note( "shutdown(): WSAENOTCONN\n" );
                
                break;
            }
            
            case WSAENOTSOCK:
            {
                // "The descriptor is not a socket."
                Note( "shutdown(): WSAENOTSOCK\n" );
                
                break;
            }
        }
    }
}

/*------------------------------------------------------------
| UnbindStreamSocket
|-------------------------------------------------------------
| 
| PURPOSE: To unbind the endpoint of a stream or register it
|          for unbinding during idle processing.
|
| DESCRIPTION: If the endpoint can be unbound and isn't 
| already then the endpoint is unbound immediately.
| 
| If the endpoint isn't in the idle state then a flag is set
| so that when the endpoint is ultimately idle, then the
| endpoint will be unbound.
|
| This function returns immediately without any delay.
|   
| The notifier will change the state of the endpoint to clear 
| the unbind request flag when it completes unbinding
| successfully.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.05.96
------------------------------------------------------------*/
void 
UnbindStreamSocket( Stream* s )
{
}

/*------------------------------------------------------------
| WaitForPassiveTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To wait for an incoming connection request on a
|          given stream.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: WARNING - could wait forever here. 
|       Add timeout as needed.
| 
| ASSUMES: s->Process has been set to 'SocketIsListening' to
|          enable incoming connections.
| 
| HISTORY: 11.26.96
|          12.04.96 revised.  Removed error return value.
------------------------------------------------------------*/
void
WaitForPassiveTCPConnection( Stream* s )
{   
//  while( s->Process == SocketIsListening ||
//         s->Process == SocketIsConnecting )
    {
//      ProcessPendingEvent();
    }
    
    // Check the resulting state.   
 // if( GetSocketState( s ) == T_DATAXFER )
    {
//      Note( (s8*) "Passive stream %d is connected.", s );
    }
//  else
    {
//      Note( (s8*) "Passive stream %d connect failed.", s );
    }       
}   

#endif // defined( FOR_WINNT ) | defined( FOR_WIN98 ) | defined( FOR_WIN2000 ) 
