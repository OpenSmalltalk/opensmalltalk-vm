/*------------------------------------------------------------
| TLNotifier.c
|-------------------------------------------------------------
|
| PURPOSE: To provide network notifier functions.
|
| DESCRIPTION: 
|        
|
| NOTE: 
|
| HISTORY: 12.10.96
------------------------------------------------------------*/

#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <OpenTransport.h>
#include <OpenTptInternet.h>

#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLNetAccess.h"
//#include "TLWin.h"
//#include "TLLog.h"
#include "TLNotifier.h"

/*------------------------------------------------------------
| ConvertNotifierEventCodeToName
|-------------------------------------------------------------
| 
| PURPOSE: To convert an Open Transport notifier event code
|          to the name of that event.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.17.97 
------------------------------------------------------------*/
s8*
ConvertNotifierEventCodeToName( s32 code )
{
    switch( code ) 
    {
        case T_ACCEPTCOMPLETE:  
        {
            return( (s8*) "T_ACCEPTCOMPLETE" );
        }
        
        case T_BINDCOMPLETE:
        {
            return( (s8*) "T_BINDCOMPLETE" );
        }
        
        case T_CONNECT:
        {
            return( (s8*) "T_CONNECT" );
        }
        
        case T_DATA:
        {
            return( (s8*) "T_DATA" );
        }

        case T_DISCONNECT:
        {
            return( (s8*) "T_DISCONNECT" );
        }
            
        case T_DISCONNECTCOMPLETE:  
        {
            return( (s8*) "T_DISCONNECTCOMPLETE" );
        }
            
        case T_EXDATA:      
        {
            return( (s8*) "T_EXDATA" );
        }
            
        case T_GODATA:      
        {
            return( (s8*) "T_GODATA" );
        }
            
        case T_LISTEN:                  
        {
            return( (s8*) "T_LISTEN" );
        }
            
        case T_OPENCOMPLETE:            
        {
            return( (s8*) "T_OPENCOMPLETE" );
        }
        
        case T_OPTMGMTCOMPLETE:
        {
            return( (s8*) "T_OPTMGMTCOMPLETE" );
        }
        
        case T_ORDREL:      
        {
            return( (s8*) "T_ORDREL" );
        }
            
        case T_PASSCON:                 
        {
            return( (s8*) "T_PASSCON" );
        }
                
        case T_UNBINDCOMPLETE:  
        {
            return( (s8*) "T_UNBINDCOMPLETE" );
        }
        
        default:    
        {
            return( (s8*) "T_UNKNOWN" );
        }
    }
}

/*------------------------------------------------------------
| On_T_ACCEPTCOMPLETE
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_ACCEPTCOMPLETE' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Connection as been made as the result of the 
| acceptance of a connection request made to this endpoint, 
| but that connection may have been handed off to another 
| endpoint.
|
| A 'T_PASSCON' event will be made to the endpoint that 
| makes the actual connection.
|
| Don't change the state of this stream on this event.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_ACCEPTCOMPLETE( Stream* )
{
}
        
/*------------------------------------------------------------
| On_T_BINDCOMPLETE
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_BINDCOMPLETE' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_BINDCOMPLETE( Stream* s )
{
    // The bind operation has completed.
    s->IsBindPending = 0;
}

/*------------------------------------------------------------
| On_T_CONNECT
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_CONNECT' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: The remote passive peer has accepted the 
| connection as requested.  Receipt of this connection will
| be handled during net idle function.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_CONNECT( Stream* s )
{
    // If we can connect and are connecting.
    if( s->IsPassive == 0 )
    {
        // Note that we need to receive the connection.
        s->IsConnectAckPending = 1;
    }
}

/*------------------------------------------------------------
| On_T_DATA
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_DATA' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Normal, non-expedited data has arrived. Set a 
| flag for the net idle routine.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_DATA( Stream* s )
{
    s->IsIncomingData = 1;
}   

/*------------------------------------------------------------
| On_T_DISCONNECT
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_DISCONNECT' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Other side initiated an abortive disconnect.
|
| See OT IM 3-34.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_DISCONNECT( Stream* s )
{
    OSStatus    status;
    TDiscon     discon;
    
    // Other side initiated an abortive disconnect.
    //
    // I acknowledge the disconnect.
    discon.udata.len = 0; // p. 8-18: no data can be recieved
                          // on disconnect.
                          
    status = OTRcvDisconnect( s->EndPt, &discon ); 
                    // Use a '0' because the
                    // reason for the disconnection
                    // isn't needed: could get more
                    // info here.

//  Note( "OTRcvDisconnect status(%d) reason(%d) ", 
//        status, discon.reason );
            
    // For some unknown reason endpoints become useless unless
    // unbound and rebound following the receipt of a 
    // T_DISCONNECT.  So unbind the endpoint here.
    UnbindStreamEndpoint( s );
}

/*------------------------------------------------------------
| On_T_DISCONNECTCOMPLETE
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_DISCONNECTCOMPLETE' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Local end initiated an abortive disconnect and 
| this event signals that the connection has been closed.
|
| See OT IM 3-34.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_DISCONNECTCOMPLETE( Stream* s )
{
    // For some unknown reason endpoints apparently become 
    // useless unless unbound and rebound following 
    // any kind of disconnect. 
    // So probably need to unbind the endpoint here.
    UnbindStreamEndpoint( s );
}

/*------------------------------------------------------------
| On_T_EXDATA
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_EXDATA' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Expedited data has arrived. Set a flag for
| the net idle routine.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_EXDATA( Stream* s )
{
    s->IsIncomingData = 1;
}
    
/*------------------------------------------------------------
| On_T_GODATA
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_GODATA' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Flow control restrictions have been lifted:
| OK to send more.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
|          01.06.96 revised flow control to allow timeout
|                   instead of just flag.
------------------------------------------------------------*/
void
On_T_GODATA( Stream* s )
{
    s->HaltSendUntil = 0;
}   

/*------------------------------------------------------------
| On_T_LISTEN
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_LISTEN' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Remote end is trying to make connection.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_LISTEN( Stream* s )
{
    OSErr           err;
    InetAddress*    InetAddr;
    
    // No data allowed during connection.
    s->InCall->udata.len = 0; 
    
    // Listen for a pending connection request.
    err = OTListen( s->EndPt, s->InCall );
    
    // Record the IP address and port of the calling
    // remote host. See 'On_T_LISTEN()'.
    InetAddr = (InetAddress*) s->InCall->addr.buf;
    
//  Note( (s8*) "T_LISTEN: err(%d) fHost(%d) fPort(%d) seq(%d)\n",
//        err,
//        InetAddr->fHost,
//        InetAddr->fPort,
//        s->InCall->sequence );
          
    // If we can listen and we are listening then accept 
    // the connection.
    if( s->IsPassive && s->Process == EndpointIsListening )
    {
        if( err == kOTNoDataErr )
        {
            // No pending connection: wait some more.
            ;
        }
        else // Either an error or a valid request.
        {
            if( err == noErr )
            {               
                // Let the idle routine know it has work to do.
                s->IsConnectAckPending = 1;
            }
            else // An error. Do nothing: incoming request may be corrupt.
            {
                // Debugger();
            }
        }
    }
    else // We aren't listening for a connection.
    {
        // Send back a disconnect. p 3-69, 3-129 of IM OT.
        OTSndDisconnect( s->EndPt, s->InCall );
    }
}

/*------------------------------------------------------------
| On_T_OPENCOMPLETE
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_OPENCOMPLETE' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_OPENCOMPLETE( Stream* s )
{
    // Signal that 'EndpointIsOpening' process complete.
    s->Process = EndpointIsWaiting;

    // Call to open an endpoint has completed.
    if( s->NotifierEventResult == noErr )
    {
        // Save the endpoint reference for the 
        // endpoint just created in OT.
        s->EndPt = s->NotifierEventCookie;
    }
    else // Not able to assign a protocol w/in OT.
    {
        s->EndPt = 0;
    }
}

/*------------------------------------------------------------
| On_T_OPTMGMTCOMPLETE
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_OPTMGMTCOMPLETE' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: An option management request has completed.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_OPTMGMTCOMPLETE( Stream* s )
{
    s->IsOptionRequestPending = 0;
}

/*------------------------------------------------------------
| On_T_ORDREL
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_ORDREL' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: Begin or complete an orderly disconnect.
|
| See OT IM 3-36.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_ORDREL( Stream* s )
{
    // TCP uses 'remote orderly disconnect'.
    //
    if( s->Process == EndpointIsDisconnecting )
    {
        // I initiated disconnect and am receiving notification 
        // of the completion of disconnection from the remote 
        // peer.
             
        // Acknowledge the receipt of the disconnection event.
        OTRcvOrderlyDisconnect( s->EndPt );
        
        // For some unknown reason endpoints apparently become 
        // useless unless unbound and rebound following 
        // any kind of disconnect. 
        // So probably need to unbind the endpoint here.
        UnbindStreamEndpoint( s );
    }
    else // Other side has begun an orderly disconnect.
    {
        // Change our process to disconnecting.
        s->Process = EndpointIsDisconnecting;

        // We make a note here that we have yet to acknowledge
        // this disconnect request.  This will be done in the
        // net idle loop.
        s->IsDisconnectAckPending = 1;
        
        // The net idle function will also complete the
        // disconnection, moving the endpoint state to an
        // unbound state: 
        //      see 'AcknowledgePendingDisconnectRequests'.
    }
}

/*------------------------------------------------------------
| On_T_PASSCON
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_PASSCON' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_PASSCON( Stream* s )
{
    // Passive connection has been made on 
    // this stream's local port.
    s->Process = EndpointIsWaiting;
}

/*------------------------------------------------------------
| On_T_UNBINDCOMPLETE
|-------------------------------------------------------------
| 
| PURPOSE: To respond to 'T_UNBINDCOMPLETE' events within an
|          Open Transport TCP stream notifier.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.07.96 extracted from 'StreamNotifier'.
------------------------------------------------------------*/
void
On_T_UNBINDCOMPLETE( Stream* s )
{
    // The unbind operation has completed.
    if( s->NotifierEventResult == noErr )
    {
        // Make sure we are in the unbound state.
        
        if( GetEndpointState( s ) == T_UNBND )
        {
            s->IsUnbindPending = 0;
        }
    }
}

/*------------------------------------------------------------
| StreamNotifier
|-------------------------------------------------------------
| 
| PURPOSE: To be the Open Transport notifier proc for TCP 
|          streams.
|
| DESCRIPTION: 
|
|   Entry:  s = pointer to stream.
|           code = OT event code.
|           result = OT result.
|           cookie = OT cookie.
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.25.96 renamed from 'MyOTStreamNotifyProc'.
|          12.04.96 rewritten.
------------------------------------------------------------*/
pascal void
StreamNotifier( Stream*     s, 
                OTEventCode code,
                OTResult    result, 
                void*       cookie )
{
    // Record the last event.
    s->NotifierEventCode    = code; 
    s->NotifierEventResult  = result;
    s->NotifierEventCookie  = cookie;
    
    // Respond to the event.
    switch( code ) 
    {
        case T_ACCEPTCOMPLETE:  
        {
            On_T_ACCEPTCOMPLETE( s );   
            break;
        }
        
        case T_BINDCOMPLETE:
        {
            On_T_BINDCOMPLETE( s );     
            break;
        }
        
        case T_CONNECT:
        {
            On_T_CONNECT( s );          
            break;
        }
        
        case T_DATA:
        {
            On_T_DATA( s );             
            break;
        }

        case T_DISCONNECT:
        {
            On_T_DISCONNECT( s );       
            break;
        }
            
        case T_DISCONNECTCOMPLETE:  
        {
            On_T_DISCONNECTCOMPLETE( s );       
            break;
        }
            
        case T_EXDATA:          
        {
            On_T_EXDATA( s );           
            break;
        }
        
        case T_GODATA:          
        {
            On_T_GODATA( s );           
            break;
        }
        
        case T_LISTEN:          
        {
            On_T_LISTEN( s );           
            break;
        }

        case T_OPENCOMPLETE:    
        {
            On_T_OPENCOMPLETE( s );     
            break;
        }
        
        case T_OPTMGMTCOMPLETE:
        {
            On_T_OPTMGMTCOMPLETE( s );
            break;
        }
        
        case T_ORDREL:          
        {
            On_T_ORDREL( s );           
            break;
        }
        
        case T_PASSCON:         
        {
            On_T_PASSCON( s );          
            break;
        }
                
        case T_UNBINDCOMPLETE:  
        {
            On_T_UNBINDCOMPLETE( s );   
            break;
        }
    }
}

#endif // FOR_MACOS
