/*------------------------------------------------------------
| TLNetIdle.c
|-------------------------------------------------------------
|
| PURPOSE: To provide network idle functions for MacOS.
|
| DESCRIPTION: 
|        
| HISTORY: 12.07.96 pulled out of 'NetAccess.c'.
------------------------------------------------------------*/

#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <OpenTransport.h>
#include <OpenTptInternet.h>
#include <Sound.h>
 
#include "TLMacOSMem.h"
#include "TLTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLList.h"
#include "TLWin.h"
#include "TLModes.h"
#include "TLLog.h"
#include "TLDate.h"

#include "TLNetAccess.h"
#include "TLDNS.h"
#include "TLHTTP.h"

#include "TLNetIdle.h"

// This is where data is initially received.  It is big
// enough to hold the largest data unit that TCP can send.
#define SizeOfRecieveBuffer (64*1024)

u8 TheRcvBuffer[ SizeOfRecieveBuffer ];

u8 TheSndBuffer[ (64*1024) ];


/*------------------------------------------------------------
| AcceptPendingPassiveConnections
|-------------------------------------------------------------
| 
| PURPOSE: To accept connection requests made by remote hosts.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 
------------------------------------------------------------*/
void
AcceptPendingPassiveConnections()
{
    OTResult        result;
    Stream*         s;
    Stream*         S;
    Stream*         StreamAcceptingConnection;
    InetAddress*    InetAddr;
    InetAddress*    InetAddrB;
    
    // If there are any streams registered with OT.
    if( StreamsRegisteredWithOT->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( StreamsRegisteredWithOT );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
        
            // If connect acknowledgement is pending.
            if( s->IsPassive &&
                s->IsConnectAckPending == 1 )
            {
                // If we accept the connection on a new endpoint.
                if( s->IsHandOffIncomingConnection )
                {
                    // Make a new stream buffer.
                    S = MakeStreamBuffer();
                    
                    // Register stream with Open Transport.
                    OpenStreamEndpointAsTCP( S );
                    
                    // Mark the port as passive.
                    S->IsPassive = 1;
                    
                    // Bind to any local port.
                    BindStreamToLocalPort( S, 0, 0, 1 );
                    
                    // The new stream will accept connection.
                    StreamAcceptingConnection = S;
                }
                else
                {
                    // The current stream will accept connection.
                    StreamAcceptingConnection = s;
                }
                    
                // Note where the original request came to.
                StreamAcceptingConnection->LocalAddressRequest = 
                    s->LocalAddress;
  
                // Set the process of the connecting stream.
                StreamAcceptingConnection->Process = 
                    EndpointIsConnecting;
                
                // Record the IP address and port of the calling
                // remote host. See 'On_T_LISTEN()'.
                InetAddr = (InetAddress*) s->InCall->addr.buf;

                StreamAcceptingConnection->RemoteAddress = *InetAddr;
 
                // When we accept the connection, make the remote
                // address the same as that of the host making the
                // request.
                InetAddrB = (InetAddress*) 
                    StreamAcceptingConnection->OutCall->addr.buf;

                *InetAddrB = *InetAddr;
                 
                StreamAcceptingConnection->OutCall->addr.len = 
                    sizeof(InetAddress);
                    
                // TCP doesn't allow user data to
                // be sent during connection.
                // (p. 8-16 IM OT)
                StreamAcceptingConnection->OutCall->udata.maxlen = 0; 
    
                // Copy the sequence number to identify the 
                // connection.
                StreamAcceptingConnection->OutCall->sequence = 
                    s->InCall->sequence;
                    
                // Begin connecting asynchronously.
 
                result = OTAccept( 
                            StreamAcceptingConnection->EndPt, 
                            StreamAcceptingConnection->EndPt,
                            StreamAcceptingConnection->OutCall );
                
                if( result == kOTBadSequenceErr ) // -3156
                {
                    // Clear the acknowledgement flag.
                    s->IsConnectAckPending = 0;
                }
                                
                if( result == kOTNoError ) 
                {         
                    // Clear the acknowledgement flag.
                    s->IsConnectAckPending = 0;
                }
            }
            
            ToNextItem();
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| AcknowledgePendingDisconnectRequests
|-------------------------------------------------------------
| 
| PURPOSE: To acknowledge all disconnect requests made by 
|          remote hosts.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 
------------------------------------------------------------*/
void
AcknowledgePendingDisconnectRequests()
{
    Stream* s;

    // If there are any streams registered with OT.
    if( StreamsRegisteredWithOT->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( StreamsRegisteredWithOT );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
        
            // If disconnect acknowledgement is pending.
            if( s->IsDisconnectAckPending == 1 )
            {
                // Acknowledge the disconnection request.
                OTRcvOrderlyDisconnect( s->EndPt );
                
                // Clear the acknowledgement flag.
                s->IsDisconnectAckPending = 0;
                
                // Then tell the remote that disconnection 
                // is complete.
                OTSndOrderlyDisconnect( s->EndPt );
                
                // For some unknown reason endpoints become 
                // useless unless unbound and rebound following 
                // any kind of disconnect. 
                // So unbind the endpoint here.
                UnbindStreamEndpoint( s );
            }
            
            ToNextItem();
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| BindPendingStreams
|-------------------------------------------------------------
| 
| PURPOSE: To finish binding any streams that are in the
|          process of being assigned to a local protocol
|          address. 
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 from 'OpenPendingStreams'.
------------------------------------------------------------*/
void
BindPendingStreams()
{
    Stream*         s;
    InetAddress*    AnInetAddr;
    
    // If there are any binding streams.
    if( BindingStreams->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( BindingStreams );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
        
            // Advance to the next item before anything is
            // done because the current item may be pulled 
            // from the list below.
            ToNextItem();
            
            // If the endpoint bind completed.
            if( s->IsBindPending == 0 )
            {
                // Pull this stream from the opening stream list.
                DeleteAllReferencesToData( BindingStreams, (u8*) s );
            
                // If the endpoint was successfully bound.
                if( GetEndpointState( s ) == T_IDLE ) 
                {
                    // Save the local IP address and port number in 
                    // the stream structure.    
                    AnInetAddr = (InetAddress*) s->BindResult->addr.buf;
        
                    s->LocalAddress = *AnInetAddr;
        
                    // Request the keep-alive option to conform to
                    // Netscape Gold 3.01 usage.
                    RequestKeepAlive( s );
                }
                else // There was an error.
                {
                    Note( (s8*) "Stream %d binding failed.\n", s );
                }       
            }
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| ClosePendingStreams
|-------------------------------------------------------------
| 
| PURPOSE: To close and discard streams that are passing away.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 pulled out of 'NetIdle'.
------------------------------------------------------------*/
void
ClosePendingStreams()
{
    Stream* s;
    s32     st;
    
    // If there are any closing streams.
    if( ClosingStreams->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( ClosingStreams );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
        
            // Advance to the next item before anything is
            // done because the current item may be pulled 
            // from the list below.
            ToNextItem();
            
            // Move the process along.
            st = GetEndpointState( s );

            switch( st )
            {
                case T_IDLE:
                {
                    // Unbind the endpoint from any port it may be 
                    // bound to.  
                    UnbindStreamEndpoint( s );
            
                    break;
                }
            
                case T_UNBND:
                {
                    // Close the stream endpoint in Open Transport
                    // and remove it from the list of endpoints
                    // registered with Open Transport.
                    CloseStreamEndpoint( s );
                
                    // Remove the stream from the 'ClosingStreams'
                    // list.
                    DeleteAllReferencesToData( ClosingStreams, (u8*) s );

                    // Delete the non-Open Transport part.
                    DeleteStreamBuffer( s );
                
                    break;
                }
            
                default:; // Do nothing on this pass.
            }
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| CompletePendingActiveConnections
|-------------------------------------------------------------
| 
| PURPOSE: To complete connection requests made to remote 
|          hosts.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE: Need to handle time-out conditions.
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 
|          12.23.96 limited connections to the same host
|                   to one at a time.
------------------------------------------------------------*/
void
CompletePendingActiveConnections()
{   
    InetAddress*    AnInetAddr;
    Stream*         s;
    OSErr           err;
    
    // If there are any streams registered with OT.
    if( StreamsRegisteredWithOT->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( StreamsRegisteredWithOT );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
            
            // If initial connection request needs to be
            // made.
            if( s->IsPassive == 0 &&                 // This an active endpoint.
                                                         //
                s->IsActiveConnectionPending &&          // A connection is order is pending.
                                                         //
                GetEndpointState( s ) == T_IDLE &&       // The endpoint is in a state
                                                         // that allows connection
                                                         //
                s->IsOptionRequestPending == 0 &&    // Keep-alive option request has 
                                                         // completed
                CountConnectionsToHost( &s->RemoteAddressRequest ) == 0 // There are no other
                                                                        // connections to the
                                                                        // host.
              ) 
                                                      
            {               
                // Make a connection request.
                
                // Refer to the address buffer as an internet address.
                AnInetAddr = (InetAddress*) s->OutCall->addr.buf;
        
                // Copy the remote host address where request
                // will be made.
                *AnInetAddr = s->RemoteAddressRequest;
                
                s->OutCall->addr.len = sizeof(InetAddress);
                
                // No data allowed during connection.
                s->OutCall->udata.len = 0; 

                // Clear the connection acknowledgement flag which
                // will be set by the notifier on 'T_CONNECT'.
                s->IsConnectAckPending = 0;
                
                // Begin connecting asynchronously.
                err = OTConnect( s->EndPt, s->OutCall, 0 );
                
                // If not able to begin connecting.  This may fail
                // if remote end rejects connection by disconnecting
                // (T_DISCONNECT event) or if another incoming 
                // connection is attempted on this stream (T_LISTEN 
                // event).  
                if( err != noErr && err != kOTNoDataErr )
                { 
                    ; // Couldn't begin. Try again later.
                }
                else // Able to begin making connection.
                {
                    // Trying to make connection.   
                    ;
                }
            }
            else 
            {
                //
                // If we need to acknowledge receipt of connection.
                //
                if( s->IsPassive == 0 &&
                    s->IsActiveConnectionPending &&
                    s->IsConnectAckPending )
                {
                    // The remote passive peer has accepted the 
                    // connection as requested.
                
                    // TCP doesn't allow user data to
                    // be sent during connection.
                    // (p. 8-16 IM OT)
                    s->OutCall->udata.maxlen = 0; 
                
                    // Acknowledge receipt of connection and
                    // find out where we actually connected.                                  
                    err = OTRcvConnect( s->EndPt, s->OutCall );
                
                    // If connection not yet established.
                    if( err == kOTNoDataErr )
                    {
                        // Can't connect this time. 
                        // Try again later. 
                    }
                    else // Connected or an err that disables 
                         // connection attempt.
                    {
                        // We have acheived a connection or failed 
                        // completely so don't keep trying to connect.
                        s->IsActiveConnectionPending = 0;
                    
                        // Note that we have acknowledged or failed.
                        s->IsConnectAckPending = 0;
                    
                        // If connection received OK.
                        if( err == noErr ) 
                        {
                            // Record where we actually connected.
                        
                            // Refer to the address buffer as an 
                            // internet address.
                            AnInetAddr = (InetAddress*) 
                                         s->OutCall->addr.buf;
                        
                            // Copy the address.
                            s->RemoteAddress = *AnInetAddr;
                        }
                        else // Connect failed: revert to idle state.
                        {
                            ;
                        }
                    }
                }
            }
                        
            ToNextItem();
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| ManagePendingDNSRequests
|-------------------------------------------------------------
| 
| PURPOSE: To manage DNS requests.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.16.96 from 'HandlePendingHTTPRequests'.
------------------------------------------------------------*/
void
ManagePendingDNSRequests()
{
    DNSRequest* r;
        
    // If there are any pending requests.
    if( PendingDNSRequests->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( PendingDNSRequests );
        
        while( TheItem )
        {
            // Refer to the data as a request.
            r = (DNSRequest*) TheDataAddress;
            
            // Advance to the next item before anything is
            // done because the current item may be pulled 
            // from the list below.
            ToNextItem();

            // Handle one DNS request.
            ManagePendingDNSRequest( r );
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| ManagePendingHTTPRequests
|-------------------------------------------------------------
| 
| PURPOSE: To manage the transfer of web document requests.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.16.96 from 'ClosePendingStreams'.
------------------------------------------------------------*/
void
ManagePendingHTTPRequests()
{
    HTTPRequest*    r;
        
    // If there are any pending requests.
    if( PendingHTTPRequests->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( PendingHTTPRequests );
        
        while( TheItem )
        {
            // Refer to the data as a request.
            r = (HTTPRequest*) TheDataAddress;
            
            // Advance to the next item before anything is
            // done because the current item may be pulled 
            // from the list below.
            ToNextItem();

            // Manage one HTTP request.
            ManagePendingHTTPRequest( r );
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| NetIdle
|-------------------------------------------------------------
| 
| PURPOSE: To handle network idle time tasks.
|
| DESCRIPTION: This function is called by the event loop.
|
| Handles the asynchonous operations on streams.  In general,
| passive responses are done before initiating actions to 
| avoid deadlock conditions.
|
| EXAMPLE: 
|
| NOTE: This must be able to be called without setting up 
|       network access.
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.05.96 pulled out code for closing connections:
|                   now handled by the notifier.
|          12.07.96 added many async operations.
------------------------------------------------------------*/
void
NetIdle()
{
    static s32  TickCountAtLastBeep;
    s32         Ticks;
    
    // Just return if the net idle functions are turned off.
    if( IsNetIdleEnabled == 0 ) 
    {
        return;
    }
    
    // Get the current tick count.
    Ticks = TickCount();
    
    // Detect dropped connection and beep once every 5 seconds.
    // if it has.
    if( IsIncomingDataLate() )
    {
        if( Ticks >
            (TickCountAtLastBeep + 5 * TicksPerSecond ))
        {
            SysBeep( 10 );
            
            TickCountAtLastBeep = Ticks;
        }
    }
        
    // Make sure that list 'Item' records can be allocated
    // without calling OS alloc so that notifier events can
    // be recorded without triggering an error.
    EnsureEnoughFreeItems( 200 );
    
    ManagePendingHTTPRequests();
    
    ManagePendingDNSRequests();
    
    BindPendingStreams();
    
    OpenPendingStreams();
    
    ReceivePendingDataForAllStreams();
    
    AcknowledgePendingDisconnectRequests();
    
    AcceptPendingPassiveConnections();
    
    CompletePendingActiveConnections();
    
    ClosePendingStreams();
    
    UnbindPendingStreams();
}   

/*------------------------------------------------------------
| OpenPendingStreams
|-------------------------------------------------------------
| 
| PURPOSE: To finish opening any streams coming into existence.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 from 'ClosePendingStreams'.
------------------------------------------------------------*/
void
OpenPendingStreams()
{
    Stream* s;
    
    // If there are any opening streams.
    if( OpeningStreams->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( OpeningStreams );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
        
            // Advance to the next item before anything is
            // done because the current item may be pulled 
            // from the list below.
            ToNextItem();
            
            // If the endpoint open completed.
            if( s->Process == EndpointIsWaiting )
            {
                // Pull this stream from the opening stream list.
                DeleteAllReferencesToData( OpeningStreams, (u8*) s );
                
                // Check for success.
                if( GetEndpointState( s ) == T_UNBND ) 
                {
                    // Allocate auxillary buffers that will be used later.
                    AllocateOTBuffersForStream( s );

                    // Add this stream to the registered stream list.
                    InsertDataLastInList( StreamsRegisteredWithOT, (u8*) s );
                }
                else // Failed to open the endpoint for TCP protocol.
                {
                    Note( (s8*) "Stream %d endpoint open failed. Retrying.\n", s );
                    
                    // Retry to open the stream.  This puts the stream back
                    // on the list of opening streams as the first item.
                    RequestOpenStreamEndpointAsTCP( s );
                }
            }
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| ReceiveAllPendingDataForStream
|-------------------------------------------------------------
| 
| PURPOSE: To recieve all pending data for a stream.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 pulled out of 'NetIdle'.
------------------------------------------------------------*/
void                
ReceiveAllPendingDataForStream( Stream* s )
{
    while( s->IsIncomingData )
    {
        ReceiveSomePendingDataForStream( s );
    }
}

/*------------------------------------------------------------
| ReceivePendingDataForAllStreams
|-------------------------------------------------------------
| 
| PURPOSE: To receive some pending data on all connected 
|          streams.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| If the stream is disconnecting then all pending data is
| recieived, otherwise only some pending data is read with
| each call to this routine.  
|
| Likewise, some pending data is sent each time this is 
| called.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 pulled out of 'NetIdle'.
------------------------------------------------------------*/
void
ReceivePendingDataForAllStreams()
{
    Stream* s;
    s32     st;

    // If there are any streams registered with OT.
    if( StreamsRegisteredWithOT->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( StreamsRegisteredWithOT );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
        
            // Find out the current state of the endpoint.
            st = GetEndpointState( s );
            
            // If the stream is in process of
            // orderly disconnection, read all
            // pending data.
            if( st == T_INREL || st == T_OUTREL )
            {
                ReceiveAllPendingDataForStream( s );
            }
            
            // If the stream is able to transfer data.
            if( st == T_DATAXFER )
            {
                // Receive some data waiting to be received.
                if( s->IsIncomingData )
                {
                    ReceiveSomePendingDataForStream( s );
                }
                
                // Send some data waiting to be sent.
                if( s->BytesToSend )
                {
                    SendSomePendingDataForStream( s );
                }
            }
            
            ToNextItem();
        }
        
        RevertToList();
    }
}

/*------------------------------------------------------------
| ReceiveSomePendingDataForStream
|-------------------------------------------------------------
| 
| PURPOSE: To recieve some pending data for a stream.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 pulled out of 'NetIdle'.
|          01.16.97 fixed confusion of normal data with
|                   expedited data.
------------------------------------------------------------*/
void                
ReceiveSomePendingDataForStream( Stream* s )
{
    OTFlags     flags;
    OTResult    result;
    s32         BytesRecieved;
    
    // Try to receive some data.
    result = OTRcv( s->EndPt, 
                    TheRcvBuffer, 
                    SizeOfRecieveBuffer, 
                    &flags );
    
    // If there was data received.
    if( result > 0 ) 
    {
        // Note what time data last came in.
        NoticeIncomingData();
        
        // A positive value means bytes were received.
        BytesRecieved = result;

// Note( "OTRcv BytesRecieved(%d)\n", result );

        // Keep track of how many bytes we have received both
        // expedited and normal
        s->TotalBytesReceived += BytesRecieved;
        
        // Set the signal flag: maybe there is more where
        // this came from.
        s->IsIncomingData = 1;
                    
        // If the bytes were expedited move them to an
        // expedited data buffer.
        if( flags & T_EXPEDITED )
        {
            TheRcvBuffer[BytesRecieved] = 0;
            
            Note( (s8*) "Expedited Data Received: (%s)\n", TheRcvBuffer );
            
            // Add these bytes to the bytes that the total
            // currently in the 'IncomingExpeditedData' buffers.
            s->ExpeditedBytesToRead += BytesRecieved;

            AppendDataToBufferList( &s->IncomingExpeditedData,
                                    SizeOfStreamDataBuffer,
                                    TheRcvBuffer,
                                    BytesRecieved );
        }
        else // Normal data bytes were received.  Save them
             // in a normal data buffer.
        {
            // Add these bytes to the bytes that the total
            // currently in the 'IncomingData' buffers.
            s->BytesToRead += BytesRecieved;
        
            AppendDataToBufferList( &s->IncomingData,
                                    SizeOfStreamDataBuffer,
                                    TheRcvBuffer,
                                    BytesRecieved );
        }
        
//      TheRcvBuffer[BytesRecieved] = 0;
//      Note( "%s\n", TheRcvBuffer );
    }
    else // void to read for now.
    {
        // Clear the signal flag so that it can
        // be set again by the notifier.
        s->IsIncomingData = 0;
    }
}

/*------------------------------------------------------------
| SendSomePendingDataForStream
|-------------------------------------------------------------
| 
| PURPOSE: To send some pending data for a stream.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| The data is removed from the buffer list after it is sent.  
|
| The variable 'BytesToSend' is updated as data is sent.
|
| Each call to the procedure results in the transmission
| of at most one buffer from the 'OutgoingData' list.
|
| Data is sent only when not inhibited by the 'IsSendHalted'
| flag set by the notifier.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.10.96 from 'ReceiveSomePendingDataForStream'.
|          01.06.96 revised flow control to timeout if 
|                   no 'T_GODATA' event is received within
|                   10 seconds.
------------------------------------------------------------*/
void                
SendSomePendingDataForStream( Stream* s )
{
    OTResult    result;
    s32         BytesSent, BytesToSend;
    Item*       AnItem;
    u8*         ABuffer;
    s32         Tick;

    // Get the current tick count.
    Tick = TickCount();
    
    // If data can be sent.
    if( Tick > s->HaltSendUntil && 
        s->BytesToSend )
    {
        // Refer to the buffer.
        AnItem = s->OutgoingData->FirstItem;
        
        // Locate the data to send.
        ABuffer     = AnItem->DataAddress;
        BytesToSend = AnItem->SizeOfData;
        
        // Try to send some data.
        result = OTSnd( s->EndPt, 
                        ABuffer, 
                        BytesToSend, 
                        0 );
    
        // If there was data sent.
        if( result > 0 ) 
        {
            // A positive value means bytes were sent.
            BytesSent = result;
            
// Note( "OTSnd BytesSent(%d)\n", result );

            // Keep track of how many bytes we have sent.   
            s->TotalBytesSent += BytesSent;
        
            // Reduce the number we have yet to send.
            s->BytesToSend -= BytesSent;
        
            // Consume the bytes in the buffer.
            AnItem->DataAddress += BytesSent;
            AnItem->SizeOfData  -= BytesSent;
        
            // If the buffer is empty, delete it.
            if( AnItem->SizeOfData == 0 )
            {
                AnItem = 
                    ExtractFirstItemFromList( s->OutgoingData );
            
                // Free the buffer.
                free( AnItem->BufferAddress );
            
                // Free the item.
                DeleteItem( AnItem );
            }
        }
        else // A send error occurred.
        {
            // If the flow control exception.
            if( result == kOTFlowErr )
            {
                // Delay any further sending until 10 seconds have
                // passed or until the notifier clears the
                // field on a 'T_GODATA' event, which ever comes 
                // first.
                s->HaltSendUntil = Tick + TicksPerSecond * 10;
                
                Note( (s8*) "OTSnd error(kOTFlowErr)\n", result );
            }
            else // No other errors recognized for now.
            {
                Note( (s8*) "OTSnd error(%d)\n", result );
            }
        }
    }
}

/*------------------------------------------------------------
| UnbindPendingStreams
|-------------------------------------------------------------
| 
| PURPOSE: To unbind streams marked for unbinding.
|
| DESCRIPTION: Operates during 'NetIdle()' only.
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.13.96 from 'ClosePendingStreams'.
------------------------------------------------------------*/
void
UnbindPendingStreams()
{
    Stream* s;
 
    // If there are any streams that could be bound.
    if( StreamsRegisteredWithOT->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( StreamsRegisteredWithOT );
        
        while( TheItem )
        {
            // Refer to the data as a stream.
            s = (Stream*) TheDataAddress;
        
            // If this one needs to be unbound.
            if( s->IsUnbindPending )
            {
                UnbindStreamEndpoint( s );
            }
            
            ToNextItem();
        }
        
        RevertToList();
    }
}

#endif // FOR_MACOS
