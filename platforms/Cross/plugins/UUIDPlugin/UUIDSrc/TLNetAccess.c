/*------------------------------------------------------------
| TLNetAccess.c
|-------------------------------------------------------------
|
| PURPOSE: To provide TCP/IP network access.
|
| DESCRIPTION: 
|        
| This reentrant module handles low-level communications with 
| TCP/IP network servers, using a simple "net ASCII" 
| command/response stream model. 
|
| It also exports several functions for using FTP data 
| streams, and several functions for doing domain name 
| resolver tasks. 
| 
| The module relies on Open Transport.
| 
| The module also manages many of the common protocol details 
| of communicating with net ASCII servers: 
| 
|   Handling initial server "hello" messages.
|
|   Handling final server "QUIT" commands and all the details 
|   of graceful asynchronous stream close operations.
|
|   Mapping between CR line terminators and CRLF line 
|   terminators.
|
|   Decoding numeric server response codes.
|
|   Skipping server comments (response lines with "-" 
|   following the response code).
|
|   Supplying terminating "." lines when sending blocks of 
|   text.
|
|   Recognizing and discarding terminating "." lines when 
|   reading blocks of text.
|
|   Mapping between leading "." characters and leading ".." 
|   characters on text lines. 
| 
| The module emphasizes simplicity at the expense of power. There 
| are many things you can do by calling Open Transport directly 
| which you cannot do with this module. The module is *not* a general 
| purpose interface to Open Transport.  It is only a convenient 
| interface for writing clients for typical simple net ASCII 
| servers.
|   
| The following mandatory functions handle initialization, idle 
| time, and termination tasks.
|   
|   SetUpNetAccess - Initialize the module.
|
|   NetIdle - Handle idle time tasks.
| 
|   CleanUpNetAccess - Terminate the module.
|   
| The following functions work with Net ASCII command/response 
| streams:
| 
|   OpenTCPStream - Open a stream.
|
|   CloseTCPConnection - Close a stream.
|
|   SendCommandAndReadResponse - Send a command and get the response.
|
|   NetGetExtraResponse - Get an extra command response.
|
|   NetBatchedCommands - Send several commands in a batch and
|           get and process the responses.
|
|   NetPutText - Send command text.
|
|   NetGetText - Get response text.
|       
| The following functions handle simple domain name resolver 
| and related tasks:
|   
|   GetLocalHostIPAddress - Get my IP address.
|
|   GetLocalHostIPAddressString - Get my IP address as a dotted-decimal string.
|
|   GetLocalHostDomainName - Get my domain name.
|
|   TranslateDomainNameToIPAddress - Convert a domain name to an IP address.
|
|   TranslateIPAddressToDomainName - Convert an IP address to a domain name.
|       
| Finally, the following utility functions:
|   
|   IsOpenTransportAvailable - Determine if Open Transport is 
|           available for use.
|
| A "stream" is an abstraction representing a bidirectional 
| network connection to a net ASCII TCP/IP server. 
| 
| With Open Transport, the notion of a "stream" in this module 
| is basically equivalent to a "TCP endpoint". 
|
| The "OpenTCPStream" function opens an endpoint, binds it to a TCP 
| port,  and creates a connection. The "CloseTCPConnection" function
| does an orderly disconnect and closes the endpoint.
|   
| A stream is represented as a variable of type "Stream*". 
|   
| The functions return a value of type OSErr as the function result:
|   
|       noErr                   no error occurred
|
|       netOpenDriverErr        SetUpNetAccess could not initialize the 
|                               network driver
| 
|       CantOpenStream      stream open failed
|
|       netLostConnectionErr    stream was unexpectedly closed or 
|                               aborted by server
|
|       netDNRErr               DNR failed to resolve name or 
|                               address
|
|       netTruncatedErr         incoming text was truncated
|
|       other                   any other OS or toolbox error
|   
| If any error occurs, the stream is aborted before returning to 
| the caller.
|
| "Aborted" means that the server connection is closed abruptly, 
| without going through the usual orderly TCP stream teardown 
| process. The stream is also deallocated. In this case, you must 
| not attempt to reuse the stream reference, since the stream no 
| longer exists. You must perform careful error checking.
|   
| The "expected" Open Transport error codes are translated into 
| either regular MacOS error codes (e.g., kENOMEMErr -> memFullErr) 
| or into the special "NetAccess" error codes 
| (e.g., authNameErr -> netDNRErr). 
|
| Open Transport error codes which are not translated are 
| "unexpected" errors which should not occur, and if they do, 
| indicate an error in the code in this module.
|   
| Copyright © 1994-1996, Northwestern University.
|
| NOTE: 
|
| HISTORY: 11.22.96 from 'net.c' written by ? as part of the
|                   'NewsWatcher' source.  Pulled out MacTCP
|                   support to rely entirely on Open Transport.
------------------------------------------------------------*/

#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <fp.h>
#include <Gestalt.h>
#include <OpenTransport.h>
#include <OpenTptInternet.h>

#include "TLTypes.h"         
#include "TLMacOSMem.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLList.h"
#include "TLWin.h"
#include "TLModes.h"
#include "TLDNS.h"
#include "TLNetAccess.h"
#include "TLHTTP.h"


// Global variables.

u32   OpenTransportIsAvailable = 0; 
// 1 if Open Transport is installed on the computer.
 
u32   IsOpenTransportSetUp = 0;     
// 1 if Open Transport has been set up for use.
 
u32   IsNetworkActivityLogged;  
// 1 if network activity should be sent to the application log.
 
List* StreamsRegisteredWithOT = 0;  
// The list of all streams that are registered with Open Transport 
// and therefore must be unregistered when we finish with them.
 
List* ClosingStreams = 0;       
// The list of all streams that are being closed and discarded.
 
List* OpeningStreams = 0;       
// The list of all streams that are being opened within OT as TCP
// protocol endpoints.
                               
List* BindingStreams = 0;       
// The list of all streams that are being bound to local protocol
// addresses.
                                
u32 IsNetIdleEnabled = 0; 
// This turns net idle functions on and off.
                             
s32     TickWhenDataWasLastReceived = 0;
// Used to detect a broken modem connection.
                                
s32     MaximumTicksBetweenIncomingData; 
// Used to detect a broken modem connection.                                
                                                                
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
    OTResult    st;
    
    st = GetEndpointState( s );
    
    // Make sure the stream is not already disconnected.
    if( st != T_UNINIT &&
        st != T_UNBND &&
        st != T_IDLE )
    {
        // Set the state to disconnecting.
        s->Process = EndpointIsDisconnecting;
    
        // Send an abortive disconnect.
        OTSndDisconnect( s->EndPt, 0 );
        
        // Notifier will handle the rest.
            
        LogNet( s, ' ', (s8*) "Async abortive disconnect started." );
    }
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
    s32 status;
    
    // Allocate structure used to make a bind request.
    s->BindRequest = OTAlloc( s->EndPt, T_BIND, T_ADDR, &status );
        
    // Allocate structure used to receive a reply to a
    // bind request.
    s->BindResult = OTAlloc( s->EndPt, T_BIND, T_ADDR, &status );
    
    // Allocate structure used to make incoming connections.
    s->InCall = OTAlloc( s->EndPt, T_CALL, T_ADDR, &status );

    // Allocate structure used to make outgoing connections.
    s->OutCall = OTAlloc( s->EndPt, T_CALL, T_ADDR, &status );
}

/*------------------------------------------------------------
| BindStreamToLocalPort
|-------------------------------------------------------------
| 
| PURPOSE: To link an endpoint to a local port.
|
| DESCRIPTION: Expects the port number and how many
| pending connection requests are permitted at one time.
|
| If any internet interface can be used, use '0' for the
| local IP address.
|
| If any port number can be used, use '0' as the port number.
|
| On successful return the stream will be ready to listen for
| or make connections.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: Any local internet interface is as good as another.
| 
| HISTORY: 11.28.96 extracted from 'DoTCPCreate'.
------------------------------------------------------------*/
OSErr   
BindStreamToLocalPort( 
    Stream*     s,
    u32         IP_Address, // 0 if use default. 
    u16         PortNumber, // 0 if use any.
    u32         PendingConnectionLimit )
{   
    OSErr           err;
    u32             Local_IP_Addr;
    InetAddress*    AnInetAddr;
    s32             WaitTil;
    
    //
    //              Set up the bind request.
    //
    s->BindRequest->qlen = PendingConnectionLimit;

    // Get my default local IP address.   
    if( IP_Address == 0 ) 
    {
        err = GetLocalHostIPAddress( &Local_IP_Addr );

        if( err != noErr )
        {
            return( err );
        }
    }
    else // Use the given local interface address.
    {
        Local_IP_Addr = IP_Address;
    }
    
    // Put the local address in the form required:
    //
    // struct InetAddress
    // {
    //      OTAddressType   fAddressType;   // always AF_INET
    //      InetPort        fPort;          // Port number 
    //      InetHost        fHost;          // Host address in net byte order
    //      UInt8           fUnused[8];     // Traditional unused bytes
    // };
    // typedef struct InetAddress InetAddress;
    
    // Refer to the address buffer as an internet address.
    AnInetAddr = (InetAddress*) s->BindRequest->addr.buf;
    
    OTInitInetAddress( AnInetAddr, 
                       PortNumber, 
                       Local_IP_Addr );
                       
    s->BindRequest->addr.len = sizeof(InetAddress);

    // Now bind the endpoint to the address
    s->IsBindPending = 1;
    
    // Call the asychronous binding operation.  
    err = OTBind( s->EndPt, s->BindRequest, s->BindResult );
 
    if( err != noErr ) 
    {
        // Not able to begin binding.
//      Note( (s8*) "Stream %d binding failed to begin: err(%d)\n", 
//            s, err );

        return( err );
    }
    
    // Wait up to 5 seconds for the binding to complete.
    WaitTil = TickCount() + 60 * 5;
    
    while( s->IsBindPending && TickCount() < WaitTil )
    {
        ProcessPendingEvent();
    } 
    
    // If the endpoint was successfully bound.
    if( GetEndpointState( s ) == T_IDLE ) 
    {
        // Save the local IP address and port number in 
        // the stream structure.    
        AnInetAddr = (InetAddress*) s->BindResult->addr.buf;
        
        s->LocalAddress = *AnInetAddr;
        
        // Enable the keep-alive option to conform to
        // Netscape Gold 3.01 usage.
//      err = EnableKeepAlive( s );

//      if( err ) 
        {
//          Note( (s8*) "EnableKeepAlive error (%d) \n", err );
        }
            
        return( err );
    }
    else // There was an error.
    {
//      Note( (s8*) "Stream %d binding failed.\n", s );

        return( CantBindStream );
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
    Stream*     s;
    s32         WaitTil;
    
    // If net access was set up.
    if( OpenTransportIsAvailable ) 
    {
        // If there are any streams known to Open Transport
        // that aren't already closing.
        if( StreamsRegisteredWithOT->ItemCount )
        {
            // Begin closing any that aren't already doing
            // so.
            ReferToList( StreamsRegisteredWithOT );
            
            while( TheItem )
            {
                s = (Stream*) TheDataAddress;
                
                ToNextItem(); // Advance here to avoid problems
                              // caused by the following statement
                              // that pulls the stream from the
                              // list.
                
                if( s->IsStreamClosing == 0 )
                {
                    CloseTCPStream( s );
                }
                else
                {
                    Debugger(); // should be no closing streams on
                                // this list.
                }
            }
            
            RevertToList();
            
            // Wait up to five seconds or until all 
            // streams have been closed, which ever comes 
            // first.
            WaitTil = TickCount() + 300;
    
            while( ClosingStreams->ItemCount &&
                   TickCount() < WaitTil ) 
            {
                ProcessPendingEvent();
            }
            
            // Shutdown 'NetIdle' processing.
            IsNetIdleEnabled = 0;
            
            // Abort any remaining connections.
            while( ClosingStreams->ItemCount )
            {
                s = (Stream*) ClosingStreams->FirstItem->DataAddress;
                
                // Remove the stream from the 'ClosingStreams'
                // list.
                DeleteAllReferencesToData( ClosingStreams, (u8*) s );

                // Close the stream endpoint in Open Transport
                // and remove it from the list of endpoints
                // registered with Open Transport.
                CloseStreamEndpoint( s );
                
                // Delete the non-Open Transport part.
                DeleteStreamBuffer( s );
            }
        
            DeleteList( StreamsRegisteredWithOT );
            StreamsRegisteredWithOT = 0;
            
            DeleteList( ClosingStreams );
            ClosingStreams = 0;
        }
    
        CloseOpenTransport();
    }
}

/*------------------------------------------------------------
| CloseStreamEndpoint
|-------------------------------------------------------------
| 
| PURPOSE: To close an endpoint for a stream currently 
|          registered with Open Transport.
|
| DESCRIPTION: Use this procedure to revert from a 
| 'OpenStreamEndpointAsTCP' call.  Any pending operations are
| canceled.
|
| Not to be confused with closing a stream which means to
| take the stream itself out of existence.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: Endpoint is currently open but not connected or
|          bound.
| 
| HISTORY: 12.05.96 from 'OpenStreamEndpointAsTCP'.
------------------------------------------------------------*/
OSErr 
CloseStreamEndpoint( Stream* s )
{
    OSErr err;

    // If there is an endpoint to close.
    if( s->EndPt )
    {
        // First free the secondary buffers.
        OTFree( s->InCall,      T_CALL );
        OTFree( s->OutCall,     T_CALL );
        OTFree( s->BindRequest, T_BIND );
        OTFree( s->BindResult,  T_BIND );
    
        // Close the provider: no notifier event generated because
        // the provider ceases to exist.    
        err = OTCloseProvider( s->EndPt );
        
        if( err != noErr )
        {
            // Report the error.
//          Note( (s8*) "Stream %d OTCloseProvider error(%d).\n", err );
        }
    
        // Mark the endpoint as missing.
        s->EndPt = 0;
        
        // Remove this stream from the registered stream list.
        DeleteAllReferencesToData( StreamsRegisteredWithOT, (u8*) s );
        
        return( err );
    }
    else
    {
        return( noErr );
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
CloseTCPConnection( Stream* s )
{
    // Make sure the stream is connected.
    if( GetEndpointState( s ) == T_DATAXFER )
    {
        // Set the process to disconnecting.
        s->Process = EndpointIsDisconnecting;
    
        // Start an orderly disconnect.
        OTSndOrderlyDisconnect( s->EndPt );
    
        // Notifier will handle the rest.
    }
}

/*------------------------------------------------------------
| CloseTCPStream
|-------------------------------------------------------------
| 
| PURPOSE: To close an active TCP stream.
|
| DESCRIPTION: Releases resources acquired by the call 
| 'OpenStreamEndpointAsTCP'.
|
| Closes asynchronously.  Depends on the execution of 
| 'NetIdle' to do final deallocation.
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
CloseTCPStream( Stream* s )
{
    // Pull this stream from the list of registered streams
    // because it is on it's way out.
    DeleteAllReferencesToData( StreamsRegisteredWithOT, (u8*) s );

    // Mark the stream as being in the process of closing.
    s->IsStreamClosing = 1;
    
    // Add this stream to the closing stream list.
    InsertDataLastInList( ClosingStreams, (u8*) s );

    // Begin async disconnection.
    CloseTCPConnection( s );
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
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 12.23.96
------------------------------------------------------------*/
s32
CountConnectionsToHost( InetAddress* RemoteHost )
{
    s32             Count;
    Stream*         s;
    s32             st;
    u32             RemoteIP;
    
    Count = 0;
    
    RemoteIP = RemoteHost->fHost;
    
    
    // If there are any streams registered with OT.
    if( StreamsRegisteredWithOT->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( StreamsRegisteredWithOT );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
            
            // If the host matches.
            if( s->RemoteAddressRequest.fHost == RemoteIP )
            {
                // If connected in any way.
                st = GetEndpointState( s );
                
                switch( st )
                {
                    case T_OUTCON:
                    case T_INCON:
                    case T_DATAXFER:
                    case T_OUTREL:
                    case T_INREL:
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
| DeleteStreamBuffer
|-------------------------------------------------------------
| 
| PURPOSE: To dispose of a stream buffer.
|
| DESCRIPTION: This releases all resources reserved by 
| 'MakeStreamBuffer'.
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
|                   'CloseStreamEndpoint'.
|          12.09.96 added data buffer deletion.
|          12.17.96 added option buffer deletion.
------------------------------------------------------------*/
void 
DeleteStreamBuffer( Stream* s )
{
    // Free non-OT data buffers: the OT buffers were deleted
    // by OT routines elsewhere when the endpoint was closed.
    if( s->IncomingData )
    {
        DeleteListOfDynamicData( s->IncomingData );
    }
    
    if( s->IncomingExpeditedData )
    {
        DeleteListOfDynamicData( s->IncomingExpeditedData );
    }
    
    if( s->OutgoingData )
    {
        DeleteListOfDynamicData( s->OutgoingData );
    }   
    
    // Free the list of notifer events.
//  DeleteList( s->NotifierEvents );
    
    // Delete any option request and result buffers.
    if( s->opt )
    {
        free( s->opt );
    }
    
    if( s->optret )
    {
        free( s->optret );
    }
    
    free( s );
}

/*------------------------------------------------------------
| DisableTCPEndpoint
|-------------------------------------------------------------
| 
| PURPOSE: To abortively disconnect, unbind and close a 
|          stream endpoint.
|
| DESCRIPTION: Reduces a stream to the state before a call
| to 'OpenStreamEndpointAsTCP'.
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
OSErr 
DisableTCPEndpoint( Stream* s )
{
    OSErr err;
    s32   WaitTil;
 
    // Abort a connection if necessary.
    AbortTCPConnection( s );
    
    // Wait for the completion of the disconnect or 10
    // seconds.
    WaitTil = TickCount() + 10 * 60;
    
    while( s->Process == EndpointIsDisconnecting &&
           TickCount() < WaitTil )
    {
        ProcessPendingEvent();
    }
    
    // Unbind the endpoint from any port it may be bound to.
    UnbindStreamEndpoint( s );
    
    // Wait for the completion of the unbind or 10 seconds.
    WaitTil = TickCount() + 10 * 60;
    
    while( s->IsUnbindPending && TickCount() < WaitTil )
    {
        ProcessPendingEvent();
    }
    
    // Remove endpoint from Open Transport. 
    err = CloseStreamEndpoint( s );
    
    return( err );
}

/*------------------------------------------------------------
| EnableKeepAlive
|-------------------------------------------------------------
| 
| PURPOSE: To enable the keep-alive option for a stream.
|
| DESCRIPTION: TCP defaults to having keep-alive off.  This
| procedure turns keep-alive on.  From IM-OT 8-28
|
|       If this option [keep-alive] is set on, TCP monitors
|       idle connections and sends a keep-alive packet to
|       check a connection after a preset time has expired.
|
| The endpoint must be must at least be bound before this
| option can be set (p. 8-27).
|
| Returns 'noErr' if able to set the option, else non-zero.
|       
| EXAMPLE: 
|
| NOTE: Netscape Gold enables this option.
| 
| ASSUMES: 
| 
| HISTORY: 12.14.96
------------------------------------------------------------*/
OSErr 
EnableKeepAlive( Stream* s )
{
    s32         st;
    TOptMgmt    req;
    TOptMgmt    ret;
    TOption*    opt;
    TOption*    optret;
    t_kpalive*  kp;
    s32         optlen;
    OTFlags     result;
        
    // Make sure the endpoint is in a state that can have
    // this option changed.
    st = GetEndpointState( s );
    
    if( st == T_UNBND || st == T_UNINIT )
    {
        return( 1 );
    }
    
    // Set up the option management request.
    
    // Calculate the size of this kind of option record.
    optlen = sizeof( TOptionHeader ) + sizeof( t_kpalive );
    
    // Allocate the option buffer for the request.
    opt = (TOption*) malloc( optlen );
    
    opt->len    = optlen;
    opt->level  = INET_TCP;
    opt->name   = OPT_KEEPALIVE;

    // Refer to the value field of the TOption record
    // as a 't_kpalive' structure.
    kp = (t_kpalive*) &opt->value[0];
                          
    kp->kp_onoff   = T_YES; // enable keep-alive
                            // Note: docs say this type 
                            // should be 'T_ON' but not
                            // defined anywhere.
                            //
    kp->kp_timeout = 120;   // 2 hours, the default: no idle
                            // connection is kept alive longer
                            // than this.
    
    req.opt.buf     = (u8*) opt;
    req.opt.len     = optlen;
    req.opt.maxlen  = optlen;
    req.flags       = T_NEGOTIATE;

    // Set up the option result buffer.
    optret = (TOption*) malloc( optlen );
    
    ret.opt.buf     = (u8*) optret;
    ret.opt.len     = optlen;
    ret.opt.maxlen  = optlen;
    
    // Request the option change.
    s->IsOptionRequestPending = 1;
    
    OTOptionManagement( s->EndPt, &req, &ret );
    
    // Wait for the notifier to respond to 
    // 'T_OPTMGMTCOMPLETE' event.
    while( s->IsOptionRequestPending )
    {
        ProcessPendingEvent();
    }
    
    // Preserve the result.
    result = ret.flags;
    
    // Discard the option buffers.
    free( ret.opt.buf );
    free( req.opt.buf );
    
    if( result == T_SUCCESS )
    {
        return( 0 );
    }
    else // Error: return the non-zero result code.
    {
        return( result );
    }
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
|   Entry:  s = pointer to stream.
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
OSErr 
EnablePassiveTCPConnection( Stream* s )
{
    OSErr   err;
    
    // Make the stream passive.
    s->IsPassive = 1;
    
    // Bind the endpoint to any local interface and port.
    err = BindStreamToLocalPort( s, 0, 0, 1 );
    
    if( GetEndpointState( s ) == T_IDLE )
    {
        // Set endpoint to listen for connection.
        s->Process = EndpointIsListening;
        
        return( noErr );
    }
    else // Coudn't bind to a port.
    {
        return( err );
    }
}

/*------------------------------------------------------------
| GetEndpointState
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
GetEndpointState( Stream* s )
{
    OTResult    st;
    
    if( s->EndPt )
    {
        st = OTGetEndpointState( s->EndPt );
        
        if( st >= 0 )
        {
            return( st );
        }
        else // An error.
        {
//          Note( (s8*) "GetEndpointState error(%d)\n", st );
            
            return( T_UNINIT );
        }
    }
    else // No endpoint assigned yet.
    {
        return( T_UNINIT );
    }
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
GetIncomingDataFromStream( Stream* s )
{
    u8*     ABuffer;
    u8*     Dest;
    Item*   AnItem;
    
    if( s->BytesToRead == 0 )
    {
        return( 0 );
    }
    
    // Allocate a new data buffer.
    ABuffer = malloc( s->BytesToRead );

    // Copy the data in the buffer list to the new buffer.
    ReferToList( s->IncomingData );
    
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
    AnItem->SizeOfData   = s->BytesToRead;
    AnItem->SizeOfBuffer = s->BytesToRead;
    
    // Delete the buffer list and reset the number of bytes
    // held in the buffers.
    DeleteListOfDynamicData( s->IncomingData );
    s->IncomingData = 0;
    s->BytesToRead = 0;
    
    // Return the new item record.
    return( AnItem );
}

/*------------------------------------------------------------
| IsIncomingDataLate
|-------------------------------------------------------------
| 
| PURPOSE: To test if data is late and connection is presumed
|          broken.
|
| DESCRIPTION: Returns 1 if the maximum time between 
| incoming data has been exceeded.
|    
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.07.97
------------------------------------------------------------*/
u32  
IsIncomingDataLate()
{
    if( TickCount() >
        ( TickWhenDataWasLastReceived +
          MaximumTicksBetweenIncomingData ) )
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
    
    OSErr err;
    s32   result;
    
    err = noErr;
    
    if( IsKnown == 0 ) 
    {
        err = Gestalt( gestaltOpenTpt, &result );
        
        IsOTAvail = 
            err == noErr 
            && 
            (result & gestaltOpenTptPresentMask ) != 0 
            &&
            (result & gestaltOpenTptTCPPresentMask ) != 0;
            
        IsKnown = 1;
    }
    
    return( IsOTAvail );
}

/*------------------------------------------------------------
| LogEndpointState
|-------------------------------------------------------------
| 
| PURPOSE: To log the endpoint state of a stream.
|
| DESCRIPTION: 
|
| These are the values returned by 'OTGetEndpointState' and 
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
LogEndpointState( Stream* s )
{
    OTResult    State;
    
    if( OpenTransportIsAvailable && 
        s && 
        s->EndPt && 
        IsNetworkActivityLogged ) 
    {
        State = OTGetEndpointState( s->EndPt );
#if 0       
        switch( State )
        {
            case T_UNINIT:      Note( (s8*) "T_UNINIT\n" );     break;
            case T_UNBND:       Note( (s8*) "T_UNBND\n" );  break;
            case T_IDLE:        Note( (s8*) "T_IDLE\n" );   break;
            case T_OUTCON:      Note( (s8*) "T_OUTCON\n" );     break;
            case T_INCON:       Note( (s8*) "T_INCON\n" );  break;
            case T_DATAXFER:    Note( (s8*) "T_DATAXFER\n" );   break;
            case T_OUTREL:      Note( (s8*) "T_OUTREL\n" );     break;
            case T_INREL:       Note( (s8*) "T_INREL\n" );  break;
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
------------------------------------------------------------*/
void
LogNet( Stream* s, s8 logEntryType, s8* str )
{
    if( IsNetworkActivityLogged ) 
    {
//      Note( (s8*) "NetLog: %d %d %d %d %s\n", 
        printf( "NetLog: %d %d %d %d %s\n", 
                logEntryType, 
                s->RemoteAddress.fHost,
                s->RemoteAddress.fPort,
                s->LocalAddress.fPort,
                str );
    }
}

/*------------------------------------------------------------
| MakeStreamBuffer
|-------------------------------------------------------------
| 
| PURPOSE: To allocate a stream buffer.
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
MakeStreamBuffer()
{
    Stream*     s;
    
    s = (Stream*) malloc( sizeof( Stream ) );
        
    FillBytes( (u8*) s, (u32) sizeof(Stream), 0 );
    
    // Add a list to be used for holding notifier events.
//  s->NotifierEvents = MakeList();
    
    return( s );
}

/*------------------------------------------------------------
| NoticeIncomingData
|-------------------------------------------------------------
| 
| PURPOSE: To note what time data last came in.
|
| DESCRIPTION: Used to detect dropped connections.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.07.97
------------------------------------------------------------*/
void
NoticeIncomingData()
{
    TickWhenDataWasLastReceived = TickCount();
}

/*------------------------------------------------------------
| OpenActiveTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To open an active endpoint connection to a given
|          IP address and port using the TCP protocol.
|
| DESCRIPTION: Given stream has been opened but not bound.
| Waits until the connection has been made or failed to 
| connect.
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
OSErr 
OpenActiveTCPConnection( Stream*    s, 
                         u32        Remote_IP_Address, 
                         u16        RemotePort )
{
    s32 WaitTil;
    
    // Make this an active stream.
    s->IsPassive = 0;
    
    // Use any local address.
    BindStreamToLocalPort( s, 0, 0, 1 ); 
    
    if( GetEndpointState( s ) != T_IDLE ) 
    {
        return( CantBindStream );
    }
    
    // Set up the remote address request.   
    OTInitInetAddress( &s->RemoteAddressRequest, 
                       RemotePort, 
                       Remote_IP_Address );
    
    // Enable connection during network idle processing.
    s->IsActiveConnectionPending = 1;
                        
    // Wait for connection process to complete or 30 seconds.
    WaitTil = TickCount() + 30 * 60;

    while( s->IsActiveConnectionPending && 
           TickCount() < WaitTil )
    {
        ProcessPendingEvent();
    } 
    
    // Check the resulting state.   
    if( GetEndpointState( s ) != T_DATAXFER )
    {
//      Note( (s8*) "Active stream %d connect failed.\n", s );
        
        return( CantConnectStream );
    }
    else
    {
        return( noErr );
    }       
}

/*------------------------------------------------------------
| OpenStreamEndpointAsTCP
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
| NOTE: See 'CloseStreamEndpoint' for the clean up routine
|       for this one.
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.28.96 renamed from 'DoTCPCreate'.
------------------------------------------------------------*/
OSErr 
OpenStreamEndpointAsTCP( Stream* s )
{
    OSErr       err;
    s32         WaitTil;

    // Call Open Transport to open a new endpoint for
    // the TCP protocol.
    s->Process = EndpointIsOpening;
        
    err = OTAsyncOpenEndpoint(
            OTCreateConfiguration(kTCPName), 
            0,
            0, 
            (OTNotifyProcPtr) StreamNotifier, 
            s );
                
    if( err != noErr ) 
    {
        // Couldn't begin opening the endpoint.
        return( err );
    }
    
    // Wait for the open operation to complete: the
    // notifier will save the endpoint reference for the
    // new endpoint in 's->EndPt'.  Allow 10 seconds.
    WaitTil = TickCount() + 10 * 60;

    while( s->Process == EndpointIsOpening && 
           TickCount() < WaitTil )
    {
        ProcessPendingEvent();
    }
    
    // Check for error.
    if( GetEndpointState( s ) != T_UNBND ) 
    {
 //     Note( (s8*) "Stream %d endpoint open failed.", s );

        return( CantOpenStream );
    }
        
    // Add this stream to the registered stream list.
    InsertDataLastInList( StreamsRegisteredWithOT, (u8*) s );
 
    // Allocate the auxillary buffers that will be used 
    // later.
    AllocateOTBuffersForStream( s );
    
    return( noErr );
}

/*------------------------------------------------------------
| OpenTCPStream
|-------------------------------------------------------------
| 
| PURPOSE: To make an active TCP stream connection ready for
|          data transfer.
|
| DESCRIPTION: Allocates a new stream buffer and connects to 
| the given host and port.  
|
| Use 'CloseTCPStream' when finished data transfer.
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
OSErr 
OpenTCPStream( 
    u32         Remote_IP_Address, 
    u16         RemotePort, 
    Stream**    ResultStream )
{
    Stream* s;
    OSErr   err;
    
    s = MakeStreamBuffer();
    
    err = OpenStreamEndpointAsTCP( s );
    
    if( err != noErr ) 
    {
        goto exit2;
    }
    
    err = OpenActiveTCPConnection( 
                s, 
                Remote_IP_Address, 
                RemotePort );
    
    if( err != noErr ) 
    {
        goto exit1;
    }
    
    *ResultStream = s;
    
    return( noErr );
    
exit1:
    
    DisableTCPEndpoint( s );

exit2:
    
    DeleteStreamBuffer( s );
    
    return( err );
}

/*------------------------------------------------------------
| PutOutgoingDataIntoStream
|-------------------------------------------------------------
| 
| PURPOSE: To add data to the sending buffers of a stream and
|          enable the sending of that data.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.13.96
------------------------------------------------------------*/
void
PutOutgoingDataIntoStream( 
    Stream* s, 
    u8*     Buffer, 
    s32     ByteCount )
{
    // Append the data to the outgoing data buffer list.
    AppendDataToBufferList( &s->OutgoingData,
                            SizeOfStreamDataBuffer,
                            Buffer,
                            ByteCount );

    // Add to the bytes to send counter.
    s->BytesToSend += ByteCount;
}

/*------------------------------------------------------------
|  ReceiveDataViaTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To receive any available data from a TCP 
|          connection up to a given number of bytes.
|
| DESCRIPTION: Gets what ever data is available on the
| stream up to a given buffer size limit.
|
| Return the number of bytes read or a negative value if an
| error occurred.
|
| EXAMPLE: 
|
| NOTE: **** DEFER: no distinction made between normal and
|            expedited data here: see
|            'ReceiveSomePendingDataForStream' for how to fix.
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.04.96 revised.
------------------------------------------------------------*/
s32
ReceiveDataViaTCPConnection( 
    Stream* s, 
    u8*     Buffer, 
    s32     BufferSize )
{
    OTResult    result;
    
    // Try to receive some data.
    result = OTRcv( s->EndPt, Buffer, BufferSize, 0 );
    
    // Keep track of how many bytes we have received.   
    if( result > 0 ) 
    {
        // Note what time data last came in.
        NoticeIncomingData();
        
        s->TotalBytesReceived += result;
    }
    
    // Return the number of bytes or a negative error code. 
    return( result );
}

/*------------------------------------------------------------
| RequestBindStreamToLocalPort
|-------------------------------------------------------------
| 
| PURPOSE: To link an endpoint to a local port asynchronously.
|
| DESCRIPTION: Expects the port number and how many
| pending connection requests are permitted at one time.
|
| If any internet interface can be used, use '0' for the
| local IP address.
|
| If any port number can be used, use '0' as the port number.
|
| Notifier will complete this.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: Any local internet interface is as good as another.
| 
| HISTORY: 11.28.96 extracted from 'DoTCPCreate'.
------------------------------------------------------------*/
OSErr   
RequestBindStreamToLocalPort( 
    Stream* s,
    u32     IP_Address, // 0 if use default. 
    u16     PortNumber, // 0 if use any.
    u32     PendingConnectionLimit )
{   
    OSErr           err;
    u32             Local_IP_Addr;
    InetAddress*    AnInetAddr;
    
    //
    //              Set up the bind request.
    //
    s->BindRequest->qlen = PendingConnectionLimit;

    // Get my default local IP address.   
    if( IP_Address == 0 ) 
    {
        err = GetLocalHostIPAddress( &Local_IP_Addr );

        if( err != noErr )
        {
            return( err );
        }
    }
    else // Use the given local interface address.
    {
        Local_IP_Addr = IP_Address;
    }
    
    // Put the local address in the form required:
    //
    // struct InetAddress
    // {
    //      OTAddressType   fAddressType;   // always AF_INET
    //      InetPort        fPort;          // Port number 
    //      InetHost        fHost;          // Host address in net byte order
    //      UInt8           fUnused[8];     // Traditional unused bytes
    // };
    // typedef struct InetAddress InetAddress;
    
    // Refer to the address buffer as an internet address.
    AnInetAddr = (InetAddress*) s->BindRequest->addr.buf;
    
    OTInitInetAddress( AnInetAddr, 
                       PortNumber, 
                       Local_IP_Addr );
                       
    s->BindRequest->addr.len = sizeof(InetAddress);

    // Now bind the endpoint to the address
    s->IsBindPending = 1;
    
    // Call the asychronous binding operation.  
    err = OTBind( s->EndPt, s->BindRequest, s->BindResult );
 
    // Add this stream to the list of those for which a bind op is
    // pending.
    InsertDataFirstInList( BindingStreams, (u8*) s );
    
    // The notifier will enable the idle routine to complete this.
    return( err );
}
    
/*------------------------------------------------------------
| RequestKeepAlive
|-------------------------------------------------------------
| 
| PURPOSE: To enable the keep-alive option for a stream
|          asynchronously.
|
| DESCRIPTION: TCP defaults to having keep-alive off.  This
| procedure turns keep-alive on.  From IM-OT 8-28
|
|       If this option [keep-alive] is set on, TCP monitors
|       idle connections and sends a keep-alive packet to
|       check a connection after a preset time has expired.
|
| The endpoint must be must at least be bound before this
| option can be set (p. 8-27).
|
| EXAMPLE: 
|
| NOTE: Netscape Gold enables this option.
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 from 'EnableKeepAlive'.
------------------------------------------------------------*/
void 
RequestKeepAlive( Stream* s )
{
    s32         st;
    t_kpalive*  kp;
    s32         optlen;
        
    // Make sure the endpoint is in a state that can have
    // this option changed.
    st = GetEndpointState( s );
    
    if( st == T_UNBND || st == T_UNINIT )
    {
        return;
    }
    
    // Set up the option management request.
    
    // Calculate the size of this kind of option record.
    optlen = sizeof( TOptionHeader ) + sizeof( t_kpalive );
    
    // Allocate a new option buffer for the request.
    if( s->opt ) free( s->opt );
    s->opt = (TOption*) malloc( optlen );
    
    s->opt->len     = optlen;
    s->opt->level   = INET_TCP;
    s->opt->name    = OPT_KEEPALIVE;

    // Refer to the value field of the TOption record
    // as a 't_kpalive' structure.
    kp = (t_kpalive*) &s->opt->value[0];
                          
    kp->kp_onoff   = T_YES; // enable keep-alive
                            // Note: docs say this type 
                            // should be 'T_ON' but not
                            // defined anywhere.
                            //
    kp->kp_timeout = 120;   // 2 hours, the default: no idle
                            // connection is kept alive longer
                            // than this.
    
    s->OptReq.opt.buf       = (u8*) s->opt;
    s->OptReq.opt.len       = optlen;
    s->OptReq.opt.maxlen    = optlen;
    s->OptReq.flags         = T_NEGOTIATE;

    // Set up a new option result buffer.
    if( s->optret ) free( s->optret );
    s->optret = (TOption*) malloc( optlen );
    
    s->OptRet.opt.buf       = (u8*) s->optret;
    s->OptRet.opt.len       = optlen;
    s->OptRet.opt.maxlen    = optlen;
    
    // Request the option change.
    s->IsOptionRequestPending = 1;
    
    OTOptionManagement( s->EndPt, &s->OptReq, &s->OptRet );
    
    // The notifier will to respond to 
    // 'T_OPTMGMTCOMPLETE' event by setting 's->IsOptionRequestPending'
    // to 0.
}

/*------------------------------------------------------------
| RequestOpenStreamEndpointAsTCP
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
| NOTE: See 'CloseStreamEndpoint' for the clean up routine
|       for this one.
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 from 
------------------------------------------------------------*/
OSErr 
RequestOpenStreamEndpointAsTCP( Stream* s )
{
    OSErr       err;

    // Call Open Transport to open a new endpoint for
    // the TCP protocol.
    s->Process = EndpointIsOpening;
    
    // Begin the opening: idle procedure will complete it.  
    err = OTAsyncOpenEndpoint(
            OTCreateConfiguration(kTCPName), 
            0,
            0, 
            (OTNotifyProcPtr) StreamNotifier, 
            s );
    
    // If no error then began opening OK.
    if( err == noErr )
    {
        // Add the stream to the list of opening streams.
        // Notifier will enable the idle routine to complete
        // the opening procedure.
        
        // Must insert first to allow for retry during
        // idle loop. See 'OpenPendingStreams'.
        InsertDataFirstInList( OpeningStreams, (u8*) s );
    }

    return( err );
}

/*------------------------------------------------------------
| SendDataViaTCPConnection
|-------------------------------------------------------------
| 
| PURPOSE: To send data over a TCP connection.
|
| DESCRIPTION: Sends data while processing pending events.
|
| Returns 'noErr' if OK, else the resulting error code.
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
OSErr 
SendDataViaTCPConnection( 
    Stream* s, 
    u8*     Buffer, 
    s32     ByteCount )
{
    OTResult    result;
    
    // While we have bytes to send.
    while( ByteCount > 0 ) 
    {
        // Yield to other tasks.
        ProcessPendingEvent();  
        
        // Try to send the remaining data.  
        result = OTSnd( s->EndPt, Buffer, ByteCount, 0 );
        
        // If we sent some data.
        if( result >= 0) 
        {
            // Account for bytes sent.
            ByteCount -= result;
            Buffer    += result;
                
            s->TotalBytesSent += result;
        } 
        else // An error occurred.
        {
            if( result == kOTFlowErr )
            {
                ; // Wait for the remote end.
            }
            else // Return the error code.
            {
                return( result );
            }
        }
    }
        
    return( noErr );
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
|   Entry:  log = pointer to logging function, or 0 if none.
|   
|   Exit:   function result = error code.
|   
| The logging function is called once for each server command 
| and response and stream open/close operation. It must be 
| declared as follows:
|   
|       void Log( s8 logEntryType, u32 Remote_IP_Address, 
|                 u16 RemotePort, u16 LocalPort, s8 *str )
|       
| You can use this function to log all server commands and 
| responses. On entry to the Log function, the parameters are:
|   
|       logEntryType = 
|           'C' if command.
|           'R' if response.
|           ' ' if open/close operation.
|
|       Remote_IP_Address = IP address of remote host.
|
|       RemotePort = port number on remote host.
|
|       LocalPort = local port number.
|
|       str = command or response string or open/close 
|             message string.
|       
| The logging function is responsible for filtering out any 
| passwords in the strings.
|   
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.25.96 pulled out 'GiveTime' parameter in favor
|                   of using 'ProcessPendingEvent' throughout.
|          11.28.96 pulled out stream buffer pre-allocation
|                   since it isn't necessary.
|          12.17.96 added set up for additional lists.
|          01.07.96 added dropped-connection detector.
------------------------------------------------------------*/
OSErr 
SetUpNetAccess( u32   LogNetworkActivity,
                s32   MaxTicksBetweenIncomingData )
{
    OSErr   err;

    // Default to not set up.
    IsOpenTransportSetUp = 0;
    
    IsNetworkActivityLogged = LogNetworkActivity;
    
    MaximumTicksBetweenIncomingData =
        MaxTicksBetweenIncomingData;
        
    OpenTransportIsAvailable = IsOpenTransportAvailable();
    
    if( OpenTransportIsAvailable ) 
    {
        err = InitOpenTransport();
        
        if( err != noErr ) 
        {
            return( netOpenDriverErr );
        }

        // Make the list for endpoints created by Open Transport.
        StreamsRegisteredWithOT = MakeList();
        
        // Make list for pending HTTP requests.
        PendingHTTPRequests = MakeList(); 
        
        // Make list for completed HTTP requests.
        CompletedHTTPRequests = MakeList(); 
        
        // Make the list for all known domain names found
        // using DNS.
        DomainNameCache = MakeList();  
        
        // Make list for outstanding DNS requests.                       
        PendingDNSRequests = MakeList();
        
        // Make a list for streams in the process of opening.
        OpeningStreams = MakeList();
        
        // Make a list for streams in the process of binding.
        BindingStreams = MakeList();
        
        // Make a list for streams in the process of closing.
        ClosingStreams = MakeList();
        
        // Initialize the dropped-connection detector.
        NoticeIncomingData();

        // Signal that OpenTransport is set up.
        IsOpenTransportSetUp = 1;
        
        // Turn on the net idle functions.
        IsNetIdleEnabled = 1;
    } 
    else
    {
        return( netOpenDriverErr );
    }
    
    return( noErr );
}

/*------------------------------------------------------------
| UnbindStreamEndpoint
|-------------------------------------------------------------
| 
| PURPOSE: To unbind the endpoint of a stream or register it
|          for unbinding during idle processing.
|
| DESCRIPTION: If the endpoint can be unbound and isn't already
| then the endpoint is unbound immediately.
| 
| If the endpoint isn't in the idle state then a flag is set
| so that when the endpoint is ultimately idle, then the
| endpoint will be unbound.
|
| This function returns immediately without any delay.
|   
| The notifier will change the state of the endpoint to
| clear the unbind request flag when it completes unbinding
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
UnbindStreamEndpoint( Stream* s )
{
    s32     st;
    
    // Make sure the stream is in the idle state.
    st = GetEndpointState( s );

    // If  already unbound.
    if( st == T_UNBND || st == T_UNINIT )
    {
        // Clear the unbind flag.
        s->IsUnbindPending = 0;
    }
    else // Need to unbind.
    {
        // Mark this stream as needing to be unbound.
        s->IsUnbindPending = 1;
        
        // If we can unbind it now.
        if( st == T_IDLE )
        {
            // Unbind the endpoint from the protocol address.
            OTUnbind( s->EndPt );
        
            // Notifier will handle the rest.
        }
    }
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
| ASSUMES: s->Process has been set to 'EndpointIsListening' to
|          enable incoming connections.
| 
| HISTORY: 11.26.96
|          12.04.96 revised.  Removed error return value.
------------------------------------------------------------*/
void
WaitForPassiveTCPConnection( Stream* s )
{   
    while( s->Process == EndpointIsListening ||
           s->Process == EndpointIsConnecting )
    {
        ProcessPendingEvent();
    }
    
    // Check the resulting state.   
    if( GetEndpointState( s ) == T_DATAXFER )
    {
//      Note( (s8*) "Passive stream %d is connected.", s );
    }
    else
    {
//      Note( (s8*) "Passive stream %d connect failed.", s );
    }       
}   

#endif // FOR_MACOS
